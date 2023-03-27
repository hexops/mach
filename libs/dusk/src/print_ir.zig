const std = @import("std");
const IR = @import("IR.zig");

const indention_size = 2;

pub fn printIR(ir: IR, writer: anytype) !void {
    var p = Printer(@TypeOf(writer)){ .ir = ir, .writer = writer };
    const globals = std.mem.sliceTo(ir.refs[ir.globals_index..], .none);
    for (globals) |ref| {
        try p.printInst(0, ref, false);
    }
}

fn Printer(comptime Writer: type) type {
    return struct {
        ir: IR,
        writer: Writer,

        fn printInst(self: @This(), indent: u16, ref: IR.Inst.Ref, decl_scope: bool) !void {
            switch (ref) {
                .none,
                .bool_type,
                .i32_type,
                .u32_type,
                .f32_type,
                .f16_type,
                .sampler_type,
                .comparison_sampler_type,
                .external_sampled_texture_type,
                .true_literal,
                .false_literal,
                => {
                    try self.writer.print("{s}()", .{@tagName(ref)});
                },
                _ => {
                    const index = ref.toIndex().?;
                    const inst = self.ir.instructions[index];

                    if (decl_scope and inst.tag.isDecl()) {
                        try self.writer.print("%{d}", .{index});
                        return;
                    }

                    switch (inst.tag) {
                        .global_variable_decl => try self.printGlobalVariable(indent, index),
                        .struct_decl => try self.printStructDecl(indent, index),
                        .struct_member => try self.printStructMember(indent, index),
                        else => {
                            try self.writer.print("%{d} = {s}{{TODO}},\n", .{ index, @tagName(inst.tag) });
                        },
                    }
                },
            }
        }

        fn printGlobalVariable(self: @This(), indent: u16, index: IR.Inst.Index) anyerror!void {
            const inst = self.ir.instructions[index];

            try self.instStart(index);
            defer self.instEnd(indent) catch unreachable;

            try self.printIndent(indent + 1);
            try self.writer.writeAll(".type = ");
            try self.printInst(indent + 2, inst.data.global_variable_decl.type, true);
            try self.writer.writeAll(",\n");
        }

        fn printStructDecl(self: @This(), indent: u16, index: IR.Inst.Index) anyerror!void {
            const inst = self.ir.instructions[index];

            try self.instStart(index);
            defer self.instEnd(indent) catch unreachable;

            try self.printIndent(indent + 1);
            try self.writer.print(".name = \"{s}\",\n", .{self.ir.getStr(inst.data.struct_decl.name)});

            const members = std.mem.sliceTo(self.ir.refs[inst.data.struct_decl.members..], .none);
            try self.printIndent(indent + 1);
            try self.writer.writeAll(".members = [\n");
            for (members) |member| {
                try self.printIndent(indent + 2);
                try self.printStructMember(indent + 2, member.toIndex().?);
            }
            try self.printIndent(indent + 1);
            try self.writer.writeAll("],\n");
        }

        fn printStructMember(self: @This(), indent: u16, index: IR.Inst.Index) anyerror!void {
            const inst = self.ir.instructions[index];

            try self.instStart(index);
            defer self.instEnd(indent) catch unreachable;

            try self.printIndent(indent + 1);
            try self.writer.print(".name = \"{s}\",\n", .{self.ir.getStr(inst.data.struct_member.name)});

            try self.printIndent(indent + 1);
            try self.writer.writeAll(".type = ");
            try self.printInst(indent + 2, inst.data.struct_member.type, true);
            try self.writer.writeAll(",\n");
        }

        fn instStart(self: @This(), index: IR.Inst.Index) !void {
            const inst = self.ir.instructions[index];
            try self.writer.print("%{d} = {s}{{\n", .{ index, @tagName(inst.tag) });
        }

        fn instEnd(self: @This(), indent: u16) !void {
            try self.printIndent(indent);
            try self.writer.writeAll("},\n");
        }

        fn printIndent(self: @This(), indent: u16) !void {
            try self.writer.writeByteNTimes(' ', indent * indention_size);
        }
    };
}
