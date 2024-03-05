const std = @import("std");
const Air = @import("Air.zig");

const indention_size = 2;

pub fn printAir(ir: Air, writer: anytype) !void {
    var p = Printer(@TypeOf(writer)){
        .ir = ir,
        .writer = writer,
        .tty = std.io.tty.Config{ .escape_codes = {} },
    };
    const globals = ir.refToList(ir.globals_index);
    for (globals) |ref| {
        try p.printInst(0, ref);
    }
}

fn Printer(comptime Writer: type) type {
    return struct {
        ir: Air,
        writer: Writer,
        tty: std.io.tty.Config,

        fn printInst(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index);
            switch (inst) {
                .@"const" => {
                    try self.printConst(indent, index);
                    if (indent == 0) {
                        try self.printFieldEnd();
                    }
                },
                .@"struct" => {
                    try self.printStruct(0, index);
                    try self.printFieldEnd();
                },
                .@"fn" => {
                    std.debug.assert(indent == 0);
                    try self.printFn(indent, index);
                    try self.printFieldEnd();
                },
                .@"var" => try self.printVar(indent, index),
                .bool => try self.printBool(indent, index),
                .int, .float => try self.printNumber(indent, index),
                .vector => try self.printVector(indent, index),
                .matrix => try self.printMatrix(indent, index),
                .sampler_type,
                .comparison_sampler_type,
                .external_texture_type,
                => {
                    try self.tty.setColor(self.writer, .bright_magenta);
                    try self.writer.print(".{s}", .{@tagName(inst)});
                    try self.tty.setColor(self.writer, .reset);
                },
                .binary => |bin| {
                    try self.instBlockStart(index);
                    try self.printFieldInst(indent + 1, "lhs", bin.lhs);
                    try self.printFieldInst(indent + 1, "rhs", bin.rhs);
                    try self.instBlockEnd(indent);
                },
                .unary_intrinsic => |un| {
                    try self.instBlockStart(index);
                    try self.printFieldInst(indent + 1, "expr", un.expr);
                    try self.printFieldInst(indent + 1, "res_ty", un.result_type);
                    try self.printFieldEnum(indent + 1, "op", un.op);
                    try self.instBlockEnd(indent);
                },
                .increase,
                .decrease,
                .loop,
                .continuing,
                .@"return",
                .break_if,
                => |un| {
                    try self.instStart(index);
                    if (un != .none) {
                        try self.printInst(indent, un);
                    }
                    try self.instEnd();
                },
                .block => try self.printBlock(indent, index),
                .@"if" => try self.printIf(indent, index),
                .@"while" => try self.printWhile(indent, index),
                .field_access => try self.printFieldAccess(indent, index),
                .index_access => try self.printIndexAccess(indent, index),
                .var_ref => |ref| {
                    try self.instStart(index);
                    try self.tty.setColor(self.writer, .yellow);
                    try self.writer.print("{d}", .{@intFromEnum(ref)});
                    try self.tty.setColor(self.writer, .reset);
                    try self.instEnd();
                },
                else => {
                    try self.instStart(index);
                    try self.writer.writeAll("TODO");
                    try self.instEnd();
                },
            }
        }

        fn printGlobalVar(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index).global_var;
            try self.instBlockStart(index);
            try self.printFieldString(indent + 1, "name", inst.name);
            if (inst.addr_space) |addr_space| {
                try self.printFieldEnum(indent + 1, "addr_space", addr_space);
            }
            if (inst.access_mode) |access_mode| {
                try self.printFieldEnum(indent + 1, "access_mode", access_mode);
            }
            if (inst.type != .none) {
                try self.printFieldInst(indent + 1, "type", inst.type);
            }
            if (inst.expr != .none) {
                try self.printFieldInst(indent + 1, "value", inst.expr);
            }
            try self.instBlockEnd(indent);
        }

        fn printVar(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index).@"var";
            try self.instBlockStart(index);
            try self.printFieldString(indent + 1, "name", inst.name);
            try self.printFieldEnum(indent + 1, "addr_space", inst.addr_space);
            try self.printFieldEnum(indent + 1, "access_mode", inst.access_mode);
            if (inst.type != .none) {
                try self.printFieldInst(indent + 1, "type", inst.type);
            }
            if (inst.expr != .none) {
                try self.printFieldInst(indent + 1, "value", inst.expr);
            }
            try self.instBlockEnd(indent);
        }

        fn printConst(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index).@"const";
            try self.instBlockStart(index);
            try self.printFieldString(indent + 1, "name", inst.name);
            if (inst.type != .none) {
                try self.printFieldInst(indent + 1, "type", inst.type);
            }
            try self.printFieldInst(indent + 1, "value", inst.expr);
            try self.instBlockEnd(indent);
        }

        fn printLet(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index).let;
            try self.instBlockStart(index);
            try self.printFieldString(indent + 1, "name", inst.name);
            if (inst.type != .none) {
                try self.printFieldInst(indent + 1, "type", inst.type);
            }
            try self.printFieldInst(indent + 1, "value", inst.expr);
            try self.instBlockEnd(indent);
        }

        fn printStruct(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index);
            try self.instBlockStart(index);
            try self.printFieldString(indent + 1, "name", inst.@"struct".name);
            try self.printFieldName(indent + 1, "members");
            try self.listStart();
            const members = self.ir.refToList(inst.@"struct".members);
            for (members) |member| {
                const member_index = member;
                const member_inst = self.ir.getInst(member_index);
                try self.printIndent(indent + 2);
                try self.instBlockStart(member_index);
                try self.printFieldString(indent + 3, "name", member_inst.struct_member.name);
                try self.printFieldInst(indent + 3, "type", member_inst.struct_member.type);
                if (member_inst.struct_member.@"align") |@"align"| {
                    try self.printFieldAny(indent + 3, "align", @"align");
                }
                if (member_inst.struct_member.size) |size| {
                    try self.printFieldAny(indent + 3, "size", size);
                }
                if (member_inst.struct_member.builtin) |builtin| {
                    try self.printFieldAny(indent + 3, "builtin", builtin);
                }
                if (member_inst.struct_member.location) |location| {
                    try self.printFieldAny(indent + 3, "location", location);
                }
                try self.instBlockEnd(indent + 2);
                try self.printFieldEnd();
            }
            try self.listEnd(indent + 1);
            try self.printFieldEnd();
            try self.instBlockEnd(indent);
        }

        fn printFn(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index);
            try self.instBlockStart(index);
            try self.printFieldString(indent + 1, "name", inst.@"fn".name);

            if (inst.@"fn".params != .none) {
                try self.printFieldName(indent + 1, "params");
                try self.listStart();
                const params = self.ir.refToList(inst.@"fn".params);
                for (params) |arg| {
                    const arg_index = arg;
                    const arg_inst = self.ir.getInst(arg_index);
                    try self.printIndent(indent + 2);
                    try self.instBlockStart(arg_index);
                    try self.printFieldString(indent + 3, "name", arg_inst.fn_param.name);
                    try self.printFieldInst(indent + 3, "type", arg_inst.fn_param.type);
                    if (arg_inst.fn_param.builtin) |builtin| {
                        try self.printFieldEnum(indent + 3, "builtin", builtin);
                    }
                    if (arg_inst.fn_param.interpolate) |interpolate| {
                        try self.printFieldName(indent + 3, "interpolate");
                        try self.instBlockStart(index);
                        try self.printFieldEnum(indent + 4, "type", interpolate.type);
                        if (interpolate.sample != .none) {
                            try self.printFieldEnum(indent + 4, "sample", interpolate.sample);
                        }
                        try self.instBlockEnd(indent + 4);
                        try self.printFieldEnd();
                    }
                    if (arg_inst.fn_param.location) |location| {
                        try self.printFieldAny(indent + 3, "location", location);
                    }
                    if (arg_inst.fn_param.invariant) {
                        try self.printFieldAny(indent + 3, "invariant", arg_inst.fn_param.invariant);
                    }
                    try self.instBlockEnd(indent + 2);
                    try self.printFieldEnd();
                }
                try self.listEnd(indent + 1);
                try self.printFieldEnd();
            }

            if (inst.@"fn".block != .none) {
                try self.printFieldName(indent + 1, "block");
                try self.printBlock(indent + 1, inst.@"fn".block);
                try self.printFieldEnd();
            }

            try self.instBlockEnd(indent);
        }

        fn printBlock(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index).block;
            const statements = self.ir.refToList(inst);
            try self.listStart();
            for (statements) |statement| {
                try self.printIndent(indent + 1);
                try self.printInst(indent + 1, statement);
                try self.printFieldEnd();
            }
            try self.listEnd(indent);
        }

        fn printIf(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index).@"if";
            try self.instBlockStart(index);
            try self.printFieldInst(indent + 1, "cond", inst.cond);
            if (inst.body != .none) {
                try self.printFieldInst(indent + 1, "body", inst.body);
            }
            if (inst.@"else" != .none) {
                try self.printFieldInst(indent + 1, "else", inst.@"else");
            }
            try self.instBlockEnd(indent);
        }

        fn printWhile(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index).@"while";
            try self.instBlockStart(index);
            try self.printFieldInst(indent + 1, "cond", inst.cond);
            if (inst.body != .none) {
                try self.printFieldInst(indent + 1, "body", inst.body);
            }
            try self.instBlockEnd(indent);
        }

        fn printBool(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index);
            if (inst.bool.value) |value| {
                switch (value) {
                    .literal => |lit| {
                        try self.instStart(index);
                        try self.tty.setColor(self.writer, .cyan);
                        try self.writer.print("{}", .{lit});
                        try self.tty.setColor(self.writer, .reset);
                        try self.instEnd();
                    },
                    .cast => |cast| {
                        try self.instBlockStart(index);
                        try self.printFieldInst(indent + 1, "type", cast.type);
                        try self.printFieldInst(indent + 1, "value", cast.type);
                        try self.instBlockEnd(indent);
                    },
                }
            } else {
                try self.instStart(index);
                try self.instEnd();
            }
        }

        fn printNumber(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index);
            try self.instBlockStart(index);
            switch (inst) {
                .int => |int| {
                    try self.printFieldEnum(indent + 1, "type", int.type);
                    if (int.value) |value| {
                        switch (self.ir.getValue(Air.Inst.Int.Value, value)) {
                            .literal => |lit| try self.printFieldAny(indent + 1, "value", lit),
                            .cast => |cast| {
                                try self.printFieldName(indent + 1, "cast");
                                try self.instBlockStart(index);
                                try self.printFieldInst(indent + 2, "type", cast.type);
                                try self.printFieldInst(indent + 2, "value", cast.value);
                                try self.instBlockEnd(indent);
                                try self.printFieldEnd();
                            },
                        }
                    }
                },
                .float => |float| {
                    try self.printFieldEnum(indent + 1, "type", float.type);
                    if (float.value) |value| {
                        switch (self.ir.getValue(Air.Inst.Float.Value, value)) {
                            .literal => |lit| try self.printFieldAny(indent + 1, "value", lit),
                            .cast => |cast| {
                                try self.printFieldName(indent + 1, "cast");
                                try self.instBlockStart(index);
                                try self.printFieldInst(indent + 2, "type", cast.type);
                                try self.printFieldInst(indent + 2, "value", cast.value);
                                try self.instBlockEnd(indent);
                                try self.printFieldEnd();
                            },
                        }
                    }
                },
                else => unreachable,
            }
            try self.instBlockEnd(indent);
        }

        fn printVector(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const vec = self.ir.getInst(index).vector;
            try self.instBlockStart(index);
            try self.printFieldInst(indent + 1, "type", vec.elem_type);
            if (vec.value) |value_idx| {
                if (value_idx == .none) {
                    try self.printFieldAny(indent + 1, "value", "null");
                } else {
                    const value = self.ir.getValue(Air.Inst.Vector.Value, value_idx);
                    switch (value) {
                        .literal => |lit| {
                            try self.printFieldName(indent + 1, "literal");
                            try self.listStart();
                            for (0..@intFromEnum(vec.size)) |i| {
                                try self.printIndent(indent + 2);
                                try self.printInst(indent + 2, lit[i]);
                                try self.printFieldEnd();
                            }
                            try self.listEnd(indent + 1);
                            try self.printFieldEnd();
                        },
                        .cast => |cast| {
                            try self.printFieldName(indent + 1, "cast");
                            try self.listStart();
                            for (0..@intFromEnum(vec.size)) |i| {
                                try self.printIndent(indent + 2);
                                try self.printInst(indent + 2, cast.value[i]);
                                try self.printFieldEnd();
                            }
                            try self.listEnd(indent + 1);
                            try self.printFieldEnd();
                        },
                    }
                }
            }
            try self.instBlockEnd(indent);
        }

        fn printMatrix(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const mat = self.ir.getInst(index).matrix;
            try self.instBlockStart(index);
            try self.printFieldInst(indent + 1, "type", mat.elem_type);
            if (mat.value) |value_idx| {
                const value = self.ir.getValue(Air.Inst.Matrix.Value, value_idx);
                try self.printFieldName(indent + 1, "value");
                try self.listStart();
                for (0..@intFromEnum(mat.cols) * @intFromEnum(mat.rows)) |i| {
                    try self.printIndent(indent + 2);
                    try self.printInst(indent + 2, value[i]);
                    try self.printFieldEnd();
                }
                try self.listEnd(indent + 1);
                try self.printFieldEnd();
            }
            try self.instBlockEnd(indent);
        }

        fn printFieldAccess(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index);
            try self.instBlockStart(index);
            try self.printFieldInst(indent + 1, "base", inst.field_access.base);
            try self.printFieldString(indent + 1, "name", inst.field_access.name);
            try self.instBlockEnd(indent);
        }

        fn printIndexAccess(self: @This(), indent: u16, index: Air.InstIndex) Writer.Error!void {
            const inst = self.ir.getInst(index);
            try self.instBlockStart(index);
            try self.printFieldInst(indent + 1, "base", inst.index_access.base);
            try self.printFieldInst(indent + 1, "type", inst.index_access.type);
            try self.printFieldInst(indent + 1, "index", inst.index_access.index);
            try self.instBlockEnd(indent);
        }

        fn instStart(self: @This(), index: Air.InstIndex) !void {
            const inst = self.ir.getInst(index);
            try self.tty.setColor(self.writer, .bold);
            try self.writer.print("{s}", .{@tagName(inst)});
            try self.tty.setColor(self.writer, .reset);
            try self.tty.setColor(self.writer, .dim);
            try self.writer.writeAll("<");
            try self.tty.setColor(self.writer, .reset);
            try self.tty.setColor(self.writer, .blue);
            try self.writer.print("{d}", .{@intFromEnum(index)});
            try self.tty.setColor(self.writer, .reset);
            try self.tty.setColor(self.writer, .dim);
            try self.writer.writeAll(">");
            try self.writer.writeAll("(");
            try self.tty.setColor(self.writer, .reset);
        }

        fn instEnd(self: @This()) !void {
            try self.tty.setColor(self.writer, .dim);
            try self.writer.writeAll(")");
            try self.tty.setColor(self.writer, .reset);
        }

        fn instBlockStart(self: @This(), index: Air.InstIndex) !void {
            const inst = self.ir.getInst(index);
            try self.tty.setColor(self.writer, .bold);
            try self.writer.print("{s}", .{@tagName(inst)});
            try self.tty.setColor(self.writer, .reset);
            try self.tty.setColor(self.writer, .dim);
            try self.writer.writeAll("<");
            try self.tty.setColor(self.writer, .reset);
            try self.tty.setColor(self.writer, .blue);
            try self.writer.print("{d}", .{@intFromEnum(index)});
            try self.tty.setColor(self.writer, .reset);
            try self.tty.setColor(self.writer, .dim);
            try self.writer.writeAll(">");
            try self.writer.writeAll("{\n");
            try self.tty.setColor(self.writer, .reset);
        }

        fn instBlockEnd(self: @This(), indent: u16) !void {
            try self.printIndent(indent);
            try self.tty.setColor(self.writer, .dim);
            try self.writer.writeAll("}");
            try self.tty.setColor(self.writer, .reset);
        }

        fn listStart(self: @This()) !void {
            try self.tty.setColor(self.writer, .dim);
            try self.writer.writeAll("[\n");
            try self.tty.setColor(self.writer, .reset);
        }

        fn listEnd(self: @This(), indent: u16) !void {
            try self.printIndent(indent);
            try self.tty.setColor(self.writer, .dim);
            try self.writer.writeAll("]");
            try self.tty.setColor(self.writer, .reset);
        }

        fn printFieldName(self: @This(), indent: u16, name: []const u8) !void {
            try self.printIndent(indent);
            try self.tty.setColor(self.writer, .reset);
            try self.writer.print("{s}", .{name});
            try self.tty.setColor(self.writer, .dim);
            try self.writer.print(": ", .{});
            try self.tty.setColor(self.writer, .reset);
        }

        fn printFieldString(self: @This(), indent: u16, name: []const u8, value: Air.StringIndex) !void {
            try self.printFieldName(indent, name);
            try self.tty.setColor(self.writer, .green);
            try self.writer.print("'{s}'", .{self.ir.getStr(value)});
            try self.tty.setColor(self.writer, .reset);
            try self.printFieldEnd();
        }

        fn printFieldInst(self: @This(), indent: u16, name: []const u8, value: Air.InstIndex) !void {
            try self.printFieldName(indent, name);
            try self.printInst(indent, value);
            try self.printFieldEnd();
        }

        fn printFieldEnum(self: @This(), indent: u16, name: []const u8, value: anytype) !void {
            try self.printFieldName(indent, name);
            try self.tty.setColor(self.writer, .magenta);
            try self.writer.print(".{s}", .{@tagName(value)});
            try self.tty.setColor(self.writer, .reset);
            try self.printFieldEnd();
        }

        fn printFieldAny(self: @This(), indent: u16, name: []const u8, value: anytype) !void {
            try self.printFieldName(indent, name);
            try self.tty.setColor(self.writer, .cyan);
            if (@typeInfo(@TypeOf(value)) == .Pointer) {
                // assume string
                try self.writer.print("{s}", .{value});
            } else {
                try self.writer.print("{}", .{value});
            }
            try self.tty.setColor(self.writer, .reset);
            try self.printFieldEnd();
        }

        fn printFieldEnd(self: @This()) !void {
            try self.writer.writeAll(",\n");
        }

        fn printIndent(self: @This(), indent: u16) !void {
            try self.writer.writeByteNTimes(' ', indent * indention_size);
        }
    };
}
