const std = @import("std");
const Air = @import("../Air.zig");
const DebugInfo = @import("../CodeGen.zig").DebugInfo;
const Inst = Air.Inst;
const InstIndex = Air.InstIndex;
const Builtin = Air.Inst.Builtin;

const Hlsl = @This();

const Section = std.ArrayListUnmanaged(u8);

air: *const Air,
allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
emitted_decls: std.AutoArrayHashMapUnmanaged(InstIndex, []const u8) = .{},
scratch: std.ArrayListUnmanaged(u8) = .{},
output: std.ArrayListUnmanaged(u8) = .{},
indent: u32 = 0,

pub fn gen(allocator: std.mem.Allocator, air: *const Air, debug_info: DebugInfo) ![]const u8 {
    _ = debug_info;

    var hlsl = Hlsl{
        .air = air,
        .allocator = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
    };
    defer {
        hlsl.scratch.deinit(allocator);
        hlsl.emitted_decls.deinit(allocator);
        hlsl.output.deinit(allocator);
        hlsl.arena.deinit();
    }

    try hlsl.output.appendSlice(allocator, "#pragma pack_matrix( row_major )\n");

    for (air.refToList(air.globals_index)) |inst_idx| {
        switch (air.getInst(inst_idx)) {
            .@"var" => try hlsl.emitGlobalVar(inst_idx),
            .@"const" => try hlsl.emitGlobalConst(inst_idx),
            .@"fn" => try hlsl.emitFn(inst_idx),
            .@"struct" => {},
            else => unreachable,
        }
    }

    return hlsl.output.toOwnedSlice(allocator);
}

fn emitType(hlsl: *Hlsl, inst_idx: InstIndex) error{OutOfMemory}!void {
    if (inst_idx == .none) {
        try hlsl.writeAll("void");
    } else {
        switch (hlsl.air.getInst(inst_idx)) {
            .bool => |inst| try hlsl.emitBoolType(inst),
            .int => |inst| try hlsl.emitIntType(inst),
            .float => |inst| try hlsl.emitFloatType(inst),
            .vector => |inst| try hlsl.emitVectorType(inst),
            .matrix => |inst| try hlsl.emitMatrixType(inst),
            .array => |inst| try hlsl.emitType(inst.elem_type),
            .@"struct" => {
                try hlsl.emitStruct(inst_idx, .normal);
                try hlsl.writeAll(hlsl.emitted_decls.get(inst_idx).?);
            },
            else => |inst| try hlsl.print("Type: {}", .{inst}), // TODO
        }
    }
}

fn emitTypeSuffix(hlsl: *Hlsl, inst_idx: InstIndex) error{OutOfMemory}!void {
    if (inst_idx != .none) {
        switch (hlsl.air.getInst(inst_idx)) {
            .array => |inst| try hlsl.emitArrayTypeSuffix(inst),
            else => {},
        }
    }
}

fn emitArrayTypeSuffix(hlsl: *Hlsl, inst: Inst.Array) !void {
    if (inst.len != .none) {
        if (hlsl.air.resolveInt(inst.len)) |len| {
            try hlsl.print("[{}]", .{len});
        }
    } else {
        try hlsl.writeAll("[1]");
    }
    try hlsl.emitTypeSuffix(inst.elem_type);
}

fn emitBoolType(hlsl: *Hlsl, inst: Inst.Bool) !void {
    _ = inst;
    try hlsl.writeAll("bool");
}

fn emitIntType(hlsl: *Hlsl, inst: Inst.Int) !void {
    try hlsl.writeAll(switch (inst.type) {
        .u32 => "uint",
        .i32 => "int",
    });
}

fn emitFloatType(hlsl: *Hlsl, inst: Inst.Float) !void {
    try hlsl.writeAll(switch (inst.type) {
        .f32 => "float",
        .f16 => "half",
    });
}

fn emitVectorSize(hlsl: *Hlsl, size: Inst.Vector.Size) !void {
    try hlsl.writeAll(switch (size) {
        .two => "2",
        .three => "3",
        .four => "4",
    });
}

fn emitVectorType(hlsl: *Hlsl, inst: Inst.Vector) !void {
    try hlsl.emitType(inst.elem_type);
    try hlsl.emitVectorSize(inst.size);
}

fn emitMatrixType(hlsl: *Hlsl, inst: Inst.Matrix) !void {
    // TODO - verify dimension order
    try hlsl.emitType(inst.elem_type);
    try hlsl.emitVectorSize(inst.cols);
    try hlsl.writeAll("x");
    try hlsl.emitVectorSize(inst.rows);
}

fn structMemberLessThan(hlsl: *Hlsl, lhs: InstIndex, rhs: InstIndex) bool {
    const lhs_member = hlsl.air.getInst(lhs).struct_member;
    const rhs_member = hlsl.air.getInst(rhs).struct_member;

    // Location
    if (lhs_member.location != null and rhs_member.location == null) return true;
    if (lhs_member.location == null and rhs_member.location != null) return false;

    const lhs_location = lhs_member.location orelse 0;
    const rhs_location = rhs_member.location orelse 0;

    if (lhs_location < rhs_location) return true;
    if (lhs_location > rhs_location) return false;

    // Builtin
    if (lhs_member.builtin == null and rhs_member.builtin != null) return true;
    if (lhs_member.builtin != null and rhs_member.builtin == null) return false;

    const lhs_builtin = lhs_member.builtin orelse .vertex_index;
    const rhs_builtin = rhs_member.builtin orelse .vertex_index;

    return @intFromEnum(lhs_builtin) < @intFromEnum(rhs_builtin);
}

fn fnParamLessThan(hlsl: *Hlsl, lhs: InstIndex, rhs: InstIndex) bool {
    const lhs_param = hlsl.air.getInst(lhs).fn_param;
    const rhs_param = hlsl.air.getInst(rhs).fn_param;

    // Location
    if (lhs_param.location != null and rhs_param.location == null) return true;
    if (lhs_param.location == null and rhs_param.location != null) return false;

    const lhs_location = lhs_param.location orelse 0;
    const rhs_location = rhs_param.location orelse 0;

    if (lhs_location < rhs_location) return true;
    if (lhs_location > rhs_location) return false;

    // Builtin
    if (lhs_param.builtin == null and rhs_param.builtin != null) return true;
    if (lhs_param.builtin != null and rhs_param.builtin == null) return false;

    const lhs_builtin = lhs_param.builtin orelse .vertex_index;
    const rhs_builtin = rhs_param.builtin orelse .vertex_index;

    return @intFromEnum(lhs_builtin) < @intFromEnum(rhs_builtin);
}

const StructKind = enum {
    normal,
    frag_out,
    vert_out,
};

fn emitStruct(hlsl: *Hlsl, inst_idx: InstIndex, kind: StructKind) !void {
    if (hlsl.emitted_decls.get(inst_idx)) |_| return;

    const scratch_top = hlsl.scratch.items.len;
    defer hlsl.scratch.shrinkRetainingCapacity(scratch_top);

    const inst = hlsl.air.getInst(inst_idx).@"struct";
    const name = try std.fmt.allocPrint(
        hlsl.arena.allocator(),
        "{s}{d}",
        .{
            if (kind == .frag_out) "FragOut" else hlsl.air.getStr(inst.name),
            @intFromEnum(inst_idx),
        },
    );

    try hlsl.print("struct {s} {{\n", .{name});

    hlsl.enterScope();
    defer hlsl.exitScope();

    var sorted_members = std.ArrayListUnmanaged(InstIndex){};
    defer sorted_members.deinit(hlsl.allocator);

    const struct_members = hlsl.air.refToList(inst.members);
    for (struct_members) |member_index| {
        try sorted_members.append(hlsl.allocator, member_index);
    }

    std.sort.insertion(InstIndex, sorted_members.items, hlsl, structMemberLessThan);

    var padding_index: u32 = 0;
    for (sorted_members.items) |member_index| {
        const member = hlsl.air.getInst(member_index).struct_member;

        try hlsl.writeIndent();
        try hlsl.emitType(member.type);
        try hlsl.writeAll(" ");
        try hlsl.writeName(member.name);
        try hlsl.emitTypeSuffix(member.type);
        if (member.builtin) |builtin| {
            try hlsl.emitBuiltin(builtin);
        } else if (member.location) |location| {
            if (kind == .frag_out) {
                try hlsl.print(" : SV_Target{}", .{location});
            } else {
                try hlsl.print(" : ATTR{}", .{location});
            }
        }
        try hlsl.writeAll(";\n");

        if (kind == .vert_out) {
            const size = hlsl.air.typeSize(member.type) orelse continue;
            const padding_size = if (size < 4) 4 - size else size % 4;
            if (padding_size != 0) {
                try hlsl.writeIndent();
                try hlsl.print("float{} pad{} : PAD{};\n", .{ padding_size, padding_index, padding_index });
                padding_index += 1;
            }
        }
    }

    try hlsl.writeAll("};\n");

    try hlsl.output.appendSlice(hlsl.allocator, hlsl.scratch.items[scratch_top..]);
    try hlsl.emitted_decls.put(hlsl.allocator, inst_idx, name);
}

fn emitBufferElemType(hlsl: *Hlsl, inst_idx: InstIndex) !void {
    switch (hlsl.air.getInst(inst_idx)) {
        .@"struct" => |inst| {
            const struct_members = hlsl.air.refToList(inst.members);
            if (struct_members.len > 0) {
                const last_member_idx = struct_members[struct_members.len - 1];
                const last_member = hlsl.air.getInst(last_member_idx).struct_member;
                try hlsl.emitBufferElemType(last_member.type);
            } else {
                std.debug.panic("Array member expected of buffer type expected to be last", .{});
            }
        },
        else => try hlsl.emitType(inst_idx),
    }
}

fn emitBuiltin(hlsl: *Hlsl, builtin: Builtin) !void {
    try hlsl.writeAll(" : ");
    try hlsl.writeAll(switch (builtin) {
        .vertex_index => "SV_VertexID",
        .instance_index => "SV_InstanceID",
        .position => "SV_Position",
        .front_facing => "SV_IsFrontFace",
        .frag_depth => "SV_Depth",
        .local_invocation_id => "SV_GroupThreadID",
        .local_invocation_index => "SV_GroupIndex",
        .global_invocation_id => "SV_DispatchThreadID",
        .workgroup_id => "SV_GroupID",
        .num_workgroups => "TODO", // TODO - is this available?
        .sample_index => "SV_SampleIndex",
        .sample_mask => "SV_Coverage",
    });
}

fn emitWrapperStruct(hlsl: *Hlsl, inst: Inst.Var) !void {
    const type_inst = hlsl.air.getInst(inst.type);
    if (type_inst == .@"struct")
        return;

    try hlsl.print("struct Wrapper{} {{ ", .{@intFromEnum(inst.type)});
    try hlsl.emitType(inst.type);
    try hlsl.writeAll(" data");
    try hlsl.emitTypeSuffix(inst.type);
    try hlsl.writeAll("; };\n");
}

fn emitGlobalVar(hlsl: *Hlsl, inst_idx: InstIndex) !void {
    if (hlsl.emitted_decls.get(inst_idx)) |_| return;

    const scratch_top = hlsl.scratch.items.len;
    defer hlsl.scratch.shrinkRetainingCapacity(scratch_top);
    const inst = hlsl.air.getInst(inst_idx).@"var";

    if (inst.addr_space == .workgroup) {
        try hlsl.writeAll("groupshared ");
        try hlsl.emitType(inst.type);
        try hlsl.writeAll(" ");
        try hlsl.writeName(inst.name);
        try hlsl.emitTypeSuffix(inst.type);
        try hlsl.writeAll(";\n");
        return;
    }

    const type_inst = hlsl.air.getInst(inst.type);
    const binding = hlsl.air.resolveInt(inst.binding) orelse return error.ConstExpr;
    const group = hlsl.air.resolveInt(inst.group) orelse return error.ConstExpr;
    var binding_space: []const u8 = undefined;

    switch (type_inst) {
        .texture_type => |texture| {
            try hlsl.writeAll(switch (texture.kind) {
                .sampled_1d => "Texture1D",
                .sampled_2d => "Texture2D",
                .sampled_2d_array => "Texture2dArray",
                .sampled_3d => "Texture3D",
                .sampled_cube => "TextureCube",
                .sampled_cube_array => "TextureCubeArray",
                .multisampled_2d => "Texture2DMS",
                .multisampled_depth_2d => "Texture2DMS",
                .storage_1d => "RWTexture1D",
                .storage_2d => "RWTexture2D",
                .storage_2d_array => "RWTexture2DArray",
                .storage_3d => "RWTexture3D",
                .depth_2d => "Texture2D",
                .depth_2d_array => "Texture2DArray",
                .depth_cube => "TextureCube",
                .depth_cube_array => "TextureCubeArray",
            });

            switch (texture.kind) {
                .storage_1d,
                .storage_2d,
                .storage_2d_array,
                .storage_3d,
                => {
                    try hlsl.writeAll("<");
                    try hlsl.writeAll(switch (texture.texel_format) {
                        .none => unreachable,
                        .rgba8unorm,
                        .bgra8unorm,
                        .rgba8snorm,
                        .rgba16float,
                        .r32float,
                        .rg32float,
                        .rgba32float,
                        => "float4",

                        .rgba8uint,
                        .rgba16uint,
                        .r32uint,
                        .rg32uint,
                        .rgba32uint,
                        => "uint4",

                        .rgba8sint,
                        .rgba16sint,
                        .r32sint,
                        .rg32sint,
                        .rgba32sint,
                        => "int4",
                    });

                    try hlsl.writeAll(">");
                },
                else => {},
            }

            // TODO - I think access_mode may be wrong

            binding_space = switch (texture.kind) {
                .storage_1d, .storage_2d, .storage_2d_array, .storage_3d => "u",
                else => "t",
            };
        },
        .sampler_type => {
            try hlsl.writeAll("SamplerState");
            binding_space = "s";
        },
        .comparison_sampler_type => {
            try hlsl.writeAll("SamplerComparisonState");
            binding_space = "s";
        },
        else => {
            switch (inst.addr_space) {
                .uniform => {
                    try hlsl.emitWrapperStruct(inst);
                    try hlsl.writeAll("ConstantBuffer<");
                    if (type_inst != .@"struct") {
                        try hlsl.print("Wrapper{}", .{@intFromEnum(inst.type)});
                    } else {
                        try hlsl.emitType(inst.type);
                    }
                    try hlsl.writeAll(">");
                    binding_space = "b";
                },
                .storage => {
                    if (inst.access_mode == .write or inst.access_mode == .read_write) {
                        try hlsl.writeAll("RWStructuredBuffer<");
                        binding_space = "u";
                    } else {
                        try hlsl.writeAll("StructuredBuffer<");
                        binding_space = "t";
                    }
                    try hlsl.emitBufferElemType(inst.type);
                    try hlsl.writeAll(">");
                },
                else => {
                    std.debug.panic("TODO: implement workgroup variable {s}\n", .{hlsl.air.getStr(inst.name)});
                },
            }
        },
    }

    try hlsl.writeAll(" ");
    try hlsl.writeName(inst.name);
    try hlsl.print(" : register({s}{}, space{});\n", .{ binding_space, binding, group });

    try hlsl.output.appendSlice(hlsl.allocator, hlsl.scratch.items[scratch_top..]);
    try hlsl.emitted_decls.put(hlsl.allocator, inst_idx, hlsl.air.getStr(inst.name));
}

fn emitGlobalConst(hlsl: *Hlsl, inst_idx: InstIndex) !void {
    if (hlsl.emitted_decls.get(inst_idx)) |_| return;

    const scratch_top = hlsl.scratch.items.len;
    defer hlsl.scratch.shrinkRetainingCapacity(scratch_top);

    const inst = hlsl.air.getInst(inst_idx).@"const";

    const t = if (inst.type != .none) inst.type else inst.init;
    try hlsl.writeAll("static const ");
    try hlsl.emitType(t);
    try hlsl.writeAll(" ");
    try hlsl.writeName(inst.name);
    try hlsl.emitTypeSuffix(inst.type);
    try hlsl.writeAll(" = ");
    try hlsl.emitExpr(inst.init);
    try hlsl.writeAll(";\n");

    try hlsl.output.appendSlice(hlsl.allocator, hlsl.scratch.items[scratch_top..]);
    try hlsl.emitted_decls.put(hlsl.allocator, inst_idx, hlsl.air.getStr(inst.name));
}

fn emitFn(hlsl: *Hlsl, inst_idx: InstIndex) !void {
    if (hlsl.emitted_decls.get(inst_idx)) |_| return;

    const scratch_top = hlsl.scratch.items.len;
    defer hlsl.scratch.shrinkRetainingCapacity(scratch_top);

    const inst = hlsl.air.getInst(inst_idx).@"fn";

    switch (inst.stage) {
        .compute => |workgroup_size| {
            try hlsl.print("[numthreads({}, {}, {})]\n", .{
                hlsl.air.resolveInt(workgroup_size.x) orelse 1,
                hlsl.air.resolveInt(workgroup_size.y) orelse 1,
                hlsl.air.resolveInt(workgroup_size.z) orelse 1,
            });
        },
        else => {},
    }

    if (inst.return_type != .none) {
        const return_type = hlsl.air.getInst(inst.return_type);
        if (inst.stage == .fragment and return_type == .@"struct") {
            try hlsl.emitStruct(inst.return_type, .frag_out);
            try hlsl.writeAll(hlsl.emitted_decls.get(inst.return_type).?);
        } else if (inst.stage == .vertex and return_type == .@"struct") {
            try hlsl.emitStruct(inst.return_type, .vert_out);
            try hlsl.writeAll(hlsl.emitted_decls.get(inst.return_type).?);
        } else {
            try hlsl.emitType(inst.return_type);
        }
    } else {
        try hlsl.writeAll("void");
    }

    try hlsl.writeAll(" ");
    if (inst.stage != .none) {
        try hlsl.writeEntrypoint(inst.name);
    } else {
        try hlsl.writeName(inst.name);
    }
    try hlsl.writeAll("(");

    {
        hlsl.enterScope();
        defer hlsl.exitScope();

        if (inst.params != .none) {
            var fn_params = std.ArrayListUnmanaged(InstIndex){};
            defer fn_params.deinit(hlsl.allocator);
            for (hlsl.air.refToList(inst.params)) |param_index| {
                try fn_params.append(hlsl.allocator, param_index);
            }

            if (inst.stage != .none) {
                std.sort.insertion(InstIndex, fn_params.items, hlsl, fnParamLessThan);
            }

            var add_comma = false;
            for (fn_params.items) |param_inst_idx| {
                try hlsl.writeAll(if (add_comma) ",\n" else "\n");
                add_comma = true;
                try hlsl.writeIndent();
                try hlsl.emitFnParam(param_inst_idx);
            }
        }
    }

    try hlsl.writeAll(")");
    if (inst.return_attrs.builtin) |builtin| {
        try hlsl.emitBuiltin(builtin);
    } else if (inst.return_attrs.location) |location| {
        try hlsl.print(" : SV_Target{}", .{location});
    }
    try hlsl.writeAll("\n");

    const block = hlsl.air.getInst(inst.block).block;
    try hlsl.writeAll("{\n");
    {
        hlsl.enterScope();
        defer hlsl.exitScope();

        if (inst.has_array_length) {
            try hlsl.writeIndent();
            try hlsl.writeAll("uint _array_length, _array_stride;\n");
        }

        try hlsl.writeIndent();
        try hlsl.writeAll("uint _width, _height, _number_of_levels;\n");

        for (hlsl.air.refToList(block)) |statement| {
            try hlsl.emitStatement(statement);
        }
    }
    try hlsl.writeIndent();
    try hlsl.writeAll("}\n");

    try hlsl.output.appendSlice(hlsl.allocator, hlsl.scratch.items[scratch_top..]);
    try hlsl.emitted_decls.put(hlsl.allocator, inst_idx, hlsl.air.getStr(inst.name));
}

fn emitFnParam(hlsl: *Hlsl, inst_idx: InstIndex) !void {
    const inst = hlsl.air.getInst(inst_idx).fn_param;

    try hlsl.emitType(inst.type);
    try hlsl.writeAll(" ");
    try hlsl.writeName(inst.name);
    if (inst.builtin) |builtin| {
        try hlsl.emitBuiltin(builtin);
    } else if (inst.location) |location| {
        try hlsl.print(" : ATTR{}", .{location});
    }
}

fn emitStatement(hlsl: *Hlsl, inst_idx: InstIndex) error{OutOfMemory}!void {
    try hlsl.writeIndent();
    switch (hlsl.air.getInst(inst_idx)) {
        .@"var" => |inst| try hlsl.emitVar(inst),
        .@"const" => |inst| try hlsl.emitConst(inst),
        .block => |block| try hlsl.emitBlock(block),
        // .loop => |inst| try hlsl.emitLoop(inst),
        // .continuing
        .@"return" => |return_inst_idx| try hlsl.emitReturn(return_inst_idx),
        // .break_if
        .@"if" => |inst| try hlsl.emitIf(inst),
        // .@"while" => |inst| try hlsl.emitWhile(inst),
        .@"for" => |inst| try hlsl.emitFor(inst),
        // .switch
        .discard => try hlsl.emitDiscard(),
        // .@"break" => try hlsl.emitBreak(),
        .@"continue" => try hlsl.writeAll("continue;\n"),
        // .call => |inst| try hlsl.emitCall(inst),
        .assign,
        .nil_intrinsic,
        .texture_store,
        => {
            try hlsl.emitExpr(inst_idx);
            try hlsl.writeAll(";\n");
        },
        //else => |inst| std.debug.panic("TODO: implement Air tag {s}", .{@tagName(inst)}),
        else => |inst| try hlsl.print("Statement: {}\n", .{inst}), // TODO
    }
}

fn emitVar(hlsl: *Hlsl, inst: Inst.Var) !void {
    const t = if (inst.type != .none) inst.type else inst.init;
    try hlsl.emitType(t);
    try hlsl.writeAll(" ");
    try hlsl.writeName(inst.name);
    try hlsl.emitTypeSuffix(t);
    if (inst.init != .none) {
        try hlsl.writeAll(" = ");
        try hlsl.emitExpr(inst.init);
    }
    try hlsl.writeAll(";\n");
}

fn emitConst(hlsl: *Hlsl, inst: Inst.Const) !void {
    const t = if (inst.type != .none) inst.type else inst.init;
    try hlsl.writeAll("const ");
    try hlsl.emitType(t);
    try hlsl.writeAll(" ");
    try hlsl.writeName(inst.name);
    try hlsl.emitTypeSuffix(inst.type);
    try hlsl.writeAll(" = ");
    try hlsl.emitExpr(inst.init);
    try hlsl.writeAll(";\n");
}

fn emitBlock(hlsl: *Hlsl, block: Air.RefIndex) !void {
    try hlsl.writeAll("{\n");
    {
        hlsl.enterScope();
        defer hlsl.exitScope();

        for (hlsl.air.refToList(block)) |statement| {
            try hlsl.emitStatement(statement);
        }
    }
    try hlsl.writeIndent();
    try hlsl.writeAll("}\n");
}

fn emitReturn(hlsl: *Hlsl, inst_idx: InstIndex) !void {
    try hlsl.writeAll("return");
    if (inst_idx != .none) {
        try hlsl.writeAll(" ");
        try hlsl.emitExpr(inst_idx);
    }
    try hlsl.writeAll(";\n");
}

fn emitIf(hlsl: *Hlsl, inst: Inst.If) !void {
    try hlsl.writeAll("if (");
    try hlsl.emitExpr(inst.cond);
    try hlsl.writeAll(")\n");
    {
        const body_inst = hlsl.air.getInst(inst.body);
        if (body_inst != .block)
            hlsl.enterScope();
        try hlsl.emitStatement(inst.body);
        if (body_inst != .block)
            hlsl.exitScope();
    }
    if (inst.@"else" != .none) {
        try hlsl.writeIndent();
        try hlsl.writeAll("else\n");
        try hlsl.emitStatement(inst.@"else");
    }
    try hlsl.writeAll("\n");
}

fn emitFor(hlsl: *Hlsl, inst: Inst.For) !void {
    try hlsl.writeAll("for (\n");
    {
        hlsl.enterScope();
        defer hlsl.exitScope();

        try hlsl.emitStatement(inst.init);
        try hlsl.writeIndent();
        try hlsl.emitExpr(inst.cond);
        try hlsl.writeAll(";\n");
        try hlsl.writeIndent();
        try hlsl.emitExpr(inst.update);
        try hlsl.writeAll(")\n");
    }
    try hlsl.emitStatement(inst.body);
}

fn emitDiscard(hlsl: *Hlsl) !void {
    try hlsl.writeAll("discard;\n");
}

fn emitExpr(hlsl: *Hlsl, inst_idx: InstIndex) error{OutOfMemory}!void {
    switch (hlsl.air.getInst(inst_idx)) {
        .var_ref => |inst| try hlsl.emitVarRef(inst),
        .bool => |inst| try hlsl.emitBool(inst),
        .int => |inst| try hlsl.emitInt(inst),
        .float => |inst| try hlsl.emitFloat(inst),
        .vector => |inst| try hlsl.emitVector(inst),
        .matrix => |inst| try hlsl.emitMatrix(inst),
        .array => |inst| try hlsl.emitArray(inst),
        .nil_intrinsic => |inst| try hlsl.emitNilIntrinsic(inst),
        .unary => |inst| try hlsl.emitUnary(inst),
        .unary_intrinsic => |inst| try hlsl.emitUnaryIntrinsic(inst),
        .binary => |inst| try hlsl.emitBinary(inst),
        .binary_intrinsic => |inst| try hlsl.emitBinaryIntrinsic(inst),
        .triple_intrinsic => |inst| try hlsl.emitTripleIntrinsic(inst),
        .assign => |inst| try hlsl.emitAssign(inst),
        .field_access => |inst| try hlsl.emitFieldAccess(inst),
        .swizzle_access => |inst| try hlsl.emitSwizzleAccess(inst),
        .index_access => |inst| try hlsl.emitIndexAccess(inst),
        .call => |inst| try hlsl.emitCall(inst),
        //.struct_construct: StructConstruct,
        //.bitcast: Bitcast,
        .texture_sample => |inst| try hlsl.emitTextureSample(inst),
        .texture_dimension => |inst| try hlsl.emitTextureDimension(inst),
        .texture_load => |inst| try hlsl.emitTextureLoad(inst),
        .texture_store => |inst| try hlsl.emitTextureStore(inst),
        //else => |inst| std.debug.panic("TODO: implement Air tag {s}", .{@tagName(inst)}),
        else => |inst| std.debug.panic("Expr: {}", .{inst}), // TODO
    }
}

fn emitVarRef(hlsl: *Hlsl, inst_idx: InstIndex) !void {
    switch (hlsl.air.getInst(inst_idx)) {
        .@"var" => |v| {
            try hlsl.writeName(v.name);
            const v_type_inst = hlsl.air.getInst(v.type);
            if (v.addr_space == .uniform and v_type_inst != .@"struct")
                try hlsl.writeAll(".data");
        },
        .@"const" => |c| try hlsl.writeName(c.name),
        .fn_param => |p| {
            try hlsl.writeName(p.name);
        },
        else => |x| std.debug.panic("VarRef: {}", .{x}), // TODO
    }
}

fn emitBool(hlsl: *Hlsl, inst: Inst.Bool) !void {
    switch (inst.value.?) {
        .literal => |lit| try hlsl.print("{}", .{lit}),
        .cast => @panic("TODO: bool cast"),
    }
}

fn emitInt(hlsl: *Hlsl, inst: Inst.Int) !void {
    switch (hlsl.air.getValue(Inst.Int.Value, inst.value.?)) {
        .literal => |lit| try hlsl.print("{}", .{lit}),
        .cast => |cast| try hlsl.emitIntCast(inst, cast),
    }
}

fn emitIntCast(hlsl: *Hlsl, dest_type: Inst.Int, cast: Inst.ScalarCast) !void {
    try hlsl.emitIntType(dest_type);
    try hlsl.writeAll("(");
    try hlsl.emitExpr(cast.value);
    try hlsl.writeAll(")");
}

fn emitFloat(hlsl: *Hlsl, inst: Inst.Float) !void {
    switch (hlsl.air.getValue(Inst.Float.Value, inst.value.?)) {
        .literal => |lit| try hlsl.print("{}", .{lit}),
        .cast => |cast| try hlsl.emitFloatCast(inst, cast),
    }
}

fn emitFloatCast(hlsl: *Hlsl, dest_type: Inst.Float, cast: Inst.ScalarCast) !void {
    try hlsl.emitFloatType(dest_type);
    try hlsl.writeAll("(");
    try hlsl.emitExpr(cast.value);
    try hlsl.writeAll(")");
}

fn emitVector(hlsl: *Hlsl, inst: Inst.Vector) !void {
    try hlsl.emitVectorType(inst);
    try hlsl.writeAll("(");

    const value = hlsl.air.getValue(Inst.Vector.Value, inst.value.?);
    switch (value) {
        .literal => |literal| try hlsl.emitVectorElems(inst.size, literal),
        .cast => |cast| try hlsl.emitVectorElems(inst.size, cast.value),
    }

    try hlsl.writeAll(")");
}

fn emitVectorElems(hlsl: *Hlsl, size: Inst.Vector.Size, value: [4]InstIndex) !void {
    for (value[0..@intFromEnum(size)], 0..) |elem_inst, i| {
        try hlsl.writeAll(if (i == 0) "" else ", ");
        try hlsl.emitExpr(elem_inst);
    }
}

fn emitMatrix(hlsl: *Hlsl, inst: Inst.Matrix) !void {
    try hlsl.emitMatrixType(inst);
    try hlsl.writeAll("(");

    const value = hlsl.air.getValue(Inst.Matrix.Value, inst.value.?);
    for (value[0..@intFromEnum(inst.cols)], 0..) |elem_inst, i| {
        try hlsl.writeAll(if (i == 0) "" else ", ");
        try hlsl.emitExpr(elem_inst);
    }

    try hlsl.writeAll(")");
}

fn emitArray(hlsl: *Hlsl, inst: Inst.Array) !void {
    try hlsl.writeAll("{");
    {
        hlsl.enterScope();
        defer hlsl.exitScope();

        const value = hlsl.air.refToList(inst.value.?);
        for (value, 0..) |elem_inst, i| {
            try hlsl.writeAll(if (i == 0) "\n" else ",\n");
            try hlsl.writeIndent();
            try hlsl.emitExpr(elem_inst);
        }
    }
    try hlsl.writeAll("}");
}

fn emitNilIntrinsic(hlsl: *Hlsl, op: Inst.NilIntrinsic) !void {
    try hlsl.writeAll(switch (op) {
        .storage_barrier => "DeviceMemoryBarrierWithGroupSync()",
        .workgroup_barrier => "GroupMemoryBarrierWithGroupSync()",
    });
}

fn emitUnary(hlsl: *Hlsl, inst: Inst.Unary) !void {
    try hlsl.writeAll(switch (inst.op) {
        .not => "!",
        .negate => "-",
        .deref => "*",
        .addr_of => @panic("unsupported"),
    });
    try hlsl.emitExpr(inst.expr);
}

fn emitUnaryIntrinsic(hlsl: *Hlsl, inst: Inst.UnaryIntrinsic) !void {
    switch (inst.op) {
        .array_length => try hlsl.emitArrayLength(inst),
        else => {
            try hlsl.writeAll(switch (inst.op) {
                .all => "all",
                .any => "any",
                .abs => "abs",
                .acos => "acos",
                //.acosh => "acosh",
                .asin => "asin",
                //.asinh => "asinh",
                .atan => "atan",
                //.atanh => "atanh",
                .ceil => "ceil",
                .cos => "cos",
                .cosh => "cosh",
                //.count_leading_zeros => "count_leading_zeros",
                .count_one_bits => "countbits",
                //.count_trailing_zeros => "count_trailing_zeros",
                .degrees => "degrees",
                .exp => "exp",
                .exp2 => "exp2",
                //.first_leading_bit => "first_leading_bit",
                //.first_trailing_bit => "first_trailing_bit",
                .floor => "floor",
                .fract => "frac",
                .inverse_sqrt => "rsqrt",
                .length => "length",
                .log => "log",
                .log2 => "log2",
                //.quantize_to_F16 => "quantize_to_F16",
                .radians => "radians",
                .reverseBits => "reversebits",
                .round => "rint",
                .saturate => "saturate",
                .sign => "sign",
                .sin => "sin",
                .sinh => "sinh",
                .sqrt => "sqrt",
                .tan => "tan",
                .tanh => "tanh",
                .trunc => "trunc",
                .dpdx => "ddx",
                .dpdx_coarse => "ddx_coarse",
                .dpdx_fine => "ddx_fine",
                .dpdy => "ddy",
                .dpdy_coarse => "ddy_coarse",
                .dpdy_fine => "ddy_fine",
                .fwidth => "fwidth",
                .fwidth_coarse => "fwidth",
                .fwidth_fine => "fwidth",
                .normalize => "normalize",
                else => std.debug.panic("TODO: implement Air tag {s}", .{@tagName(inst.op)}),
            });
            try hlsl.writeAll("(");
            try hlsl.emitExpr(inst.expr);
            try hlsl.writeAll(")");
        },
    }
}

fn emitArrayLength(hlsl: *Hlsl, inst: Inst.UnaryIntrinsic) !void {
    switch (hlsl.air.getInst(inst.expr)) {
        .unary => |un| switch (un.op) {
            .addr_of => try hlsl.emitArrayLengthTarget(un.expr, 0),
            else => try hlsl.print("ArrayLength (unary_op): {}", .{un.op}),
        },
        else => |array_length_expr| try hlsl.print("ArrayLength (array_length_expr): {}", .{array_length_expr}),
    }
}

fn emitArrayLengthTarget(hlsl: *Hlsl, inst_idx: InstIndex, offset: usize) error{OutOfMemory}!void {
    switch (hlsl.air.getInst(inst_idx)) {
        .var_ref => |var_ref_inst_idx| try hlsl.emitArrayLengthVarRef(var_ref_inst_idx, offset),
        .field_access => |inst| try hlsl.emitArrayLengthFieldAccess(inst, offset),
        else => |inst| try hlsl.print("ArrayLengthTarget: {}", .{inst}),
    }
}

fn emitArrayLengthVarRef(hlsl: *Hlsl, inst_idx: InstIndex, offset: usize) !void {
    switch (hlsl.air.getInst(inst_idx)) {
        .@"var" => |var_inst| {
            try hlsl.writeAll("(");
            try hlsl.writeName(var_inst.name);
            try hlsl.print(
                ".GetDimensions(_array_length, _array_stride), _array_length - {})",
                .{offset},
            );
        },
        else => |var_ref_expr| try hlsl.print("arrayLength (var_ref_expr): {}", .{var_ref_expr}),
    }
}

fn emitArrayLengthFieldAccess(hlsl: *Hlsl, inst: Inst.FieldAccess, base_offset: usize) !void {
    const member_offset = 0; // TODO
    try hlsl.emitArrayLengthTarget(inst.base, base_offset + member_offset);
}

fn emitBinary(hlsl: *Hlsl, inst: Inst.Binary) !void {
    switch (inst.op) {
        .mul => {
            const lhs_type = hlsl.air.getInst(inst.lhs_type);
            const rhs_type = hlsl.air.getInst(inst.rhs_type);

            if (lhs_type == .matrix or rhs_type == .matrix) {
                // matrices are transposed
                try hlsl.writeAll("mul");
                try hlsl.writeAll("(");
                try hlsl.emitExpr(inst.rhs);
                try hlsl.writeAll(", ");
                try hlsl.emitExpr(inst.lhs);
                try hlsl.writeAll(")");
            } else {
                try hlsl.emitBinaryOp(inst);
            }
        },
        else => try hlsl.emitBinaryOp(inst),
    }
}

fn emitBinaryOp(hlsl: *Hlsl, inst: Inst.Binary) !void {
    try hlsl.writeAll("(");
    try hlsl.emitExpr(inst.lhs);
    try hlsl.print(" {s} ", .{switch (inst.op) {
        .mul => "*",
        .div => "/",
        .mod => "%",
        .add => "+",
        .sub => "-",
        .shl => "<<",
        .shr => ">>",
        .@"and" => "&",
        .@"or" => "|",
        .xor => "^",
        .logical_and => "&&",
        .logical_or => "||",
        .equal => "==",
        .not_equal => "!=",
        .less_than => "<",
        .less_than_equal => "<=",
        .greater_than => ">",
        .greater_than_equal => ">=",
    }});
    try hlsl.emitExpr(inst.rhs);
    try hlsl.writeAll(")");
}

fn emitBinaryIntrinsic(hlsl: *Hlsl, inst: Inst.BinaryIntrinsic) !void {
    try hlsl.writeAll(switch (inst.op) {
        .min => "min",
        .max => "max",
        .atan2 => "atan2",
        .distance => "distance",
        .dot => "dot",
        .pow => "pow",
        .step => "step",
    });
    try hlsl.writeAll("(");
    try hlsl.emitExpr(inst.lhs);
    try hlsl.writeAll(", ");
    try hlsl.emitExpr(inst.rhs);
    try hlsl.writeAll(")");
}

fn emitTripleIntrinsic(hlsl: *Hlsl, inst: Inst.TripleIntrinsic) !void {
    try hlsl.writeAll(switch (inst.op) {
        .smoothstep => "smoothstep",
        .clamp => "clamp",
        .mix => "lerp",
    });
    try hlsl.writeAll("(");
    try hlsl.emitExpr(inst.a1);
    try hlsl.writeAll(", ");
    try hlsl.emitExpr(inst.a2);
    try hlsl.writeAll(", ");
    try hlsl.emitExpr(inst.a3);
    try hlsl.writeAll(")");
}

fn emitAssign(hlsl: *Hlsl, inst: Inst.Assign) !void {
    try hlsl.emitExpr(inst.lhs);
    try hlsl.print(" {s}= ", .{switch (inst.mod) {
        .none => "",
        .add => "+",
        .sub => "-",
        .mul => "*",
        .div => "/",
        .mod => "%",
        .@"and" => "&",
        .@"or" => "|",
        .xor => "^",
        .shl => "<<",
        .shr => ">>",
    }});
    try hlsl.emitExpr(inst.rhs);
}

fn emitFieldAccess(hlsl: *Hlsl, inst: Inst.FieldAccess) !void {
    const base_inst = hlsl.air.getInst(inst.base);
    switch (base_inst) {
        .var_ref => |var_ref_inst_idx| {
            switch (hlsl.air.getInst(var_ref_inst_idx)) {
                .@"var" => |v| {
                    const v_type_inst = hlsl.air.getInst(v.type);
                    if (v.addr_space == .storage and v_type_inst == .@"struct") {
                        // assume 1 field that is an array
                        try hlsl.emitExpr(inst.base);
                    } else {
                        try hlsl.emitFieldAccessRegular(inst);
                    }
                },
                else => try hlsl.emitFieldAccessRegular(inst),
            }
        },
        else => try hlsl.emitFieldAccessRegular(inst),
    }
}

fn emitFieldAccessRegular(hlsl: *Hlsl, inst: Inst.FieldAccess) !void {
    try hlsl.emitExpr(inst.base);
    try hlsl.writeAll(".");
    try hlsl.writeName(inst.name);
}

fn emitSwizzleAccess(hlsl: *Hlsl, inst: Inst.SwizzleAccess) !void {
    try hlsl.emitExpr(inst.base);
    try hlsl.writeAll(".");
    for (0..@intFromEnum(inst.size)) |i| {
        switch (inst.pattern[i]) {
            .x => try hlsl.writeAll("x"),
            .y => try hlsl.writeAll("y"),
            .z => try hlsl.writeAll("z"),
            .w => try hlsl.writeAll("w"),
        }
    }
}

fn emitIndexAccess(hlsl: *Hlsl, inst: Inst.IndexAccess) !void {
    try hlsl.emitExpr(inst.base);
    try hlsl.writeAll("[");
    try hlsl.emitExpr(inst.index);
    try hlsl.writeAll("]");
}

fn emitCall(hlsl: *Hlsl, inst: Inst.FnCall) !void {
    const fn_inst = hlsl.air.getInst(inst.@"fn").@"fn";

    try hlsl.writeName(fn_inst.name);
    try hlsl.writeAll("(");

    if (inst.args != .none) {
        for (hlsl.air.refToList(inst.args), 0..) |arg_inst_idx, i| {
            try hlsl.writeAll(if (i == 0) "" else ", ");
            try hlsl.emitExpr(arg_inst_idx);
        }
    }
    try hlsl.writeAll(")");
}

fn emitTextureSample(hlsl: *Hlsl, inst: Inst.TextureSample) !void {
    try hlsl.emitExpr(inst.texture);

    switch (inst.operands) {
        .none => try hlsl.writeAll(".Sample("), // TODO
        .level => try hlsl.writeAll(".SampleLevel("),
        .grad => try hlsl.writeAll(".SampleGrad("),
    }

    try hlsl.emitExpr(inst.sampler);
    try hlsl.writeAll(", ");
    try hlsl.emitExpr(inst.coords);
    switch (inst.operands) {
        .none => {},
        .level => |level| {
            try hlsl.writeAll(", ");
            try hlsl.emitExpr(level);
        },
        .grad => |grad| {
            try hlsl.writeAll(", ");
            try hlsl.emitExpr(grad.dpdx);
            try hlsl.writeAll(", ");
            try hlsl.emitExpr(grad.dpdy);
        },
    }
    try hlsl.writeAll(")");

    switch (hlsl.air.getInst(inst.result_type)) {
        .float => try hlsl.writeAll(".x"),
        else => {},
    }
}

fn emitTextureDimension(hlsl: *Hlsl, inst: Inst.TextureDimension) !void {
    try hlsl.writeAll("(");
    try hlsl.emitExpr(inst.texture);
    try hlsl.writeAll(".GetDimensions(0, _width, _height, _number_of_levels), uint2(_width, _height)"); // TODO
    try hlsl.writeAll(")");
}

fn emitTextureLoad(hlsl: *Hlsl, inst: Inst.TextureLoad) !void {
    try hlsl.emitExpr(inst.texture);
    try hlsl.writeAll(".Load(");
    try hlsl.writeAll("int3("); // TODO
    try hlsl.emitExpr(inst.coords);
    try hlsl.writeAll(", ");
    try hlsl.emitExpr(inst.level);
    try hlsl.writeAll(")");
    try hlsl.writeAll(")");

    switch (hlsl.air.getInst(inst.result_type)) {
        .float => try hlsl.writeAll(".x"),
        else => {},
    }
}

fn emitTextureStore(hlsl: *Hlsl, inst: Inst.TextureStore) !void {
    try hlsl.emitExpr(inst.texture);
    try hlsl.writeAll("[");
    try hlsl.emitExpr(inst.coords);
    try hlsl.writeAll("]");
    try hlsl.writeAll(" = ");
    try hlsl.emitExpr(inst.value);
}

fn enterScope(hlsl: *Hlsl) void {
    hlsl.indent += 4;
}

fn exitScope(hlsl: *Hlsl) void {
    hlsl.indent -= 4;
}

fn writeIndent(hlsl: *Hlsl) !void {
    try hlsl.scratch.writer(hlsl.allocator).writeByteNTimes(' ', hlsl.indent);
}

fn writeEntrypoint(hlsl: *Hlsl, name: Air.StringIndex) !void {
    const str = hlsl.air.getStr(name);
    try hlsl.writeAll(str);
}

fn writeName(hlsl: *Hlsl, name: Air.StringIndex) !void {
    // Suffix with index as WGSL has different scoping rules and to avoid conflicts with keywords
    const str = hlsl.air.getStr(name);
    try hlsl.print("{s}_{}", .{ str, @intFromEnum(name) });
}

fn writeAll(hlsl: *Hlsl, bytes: []const u8) !void {
    try hlsl.scratch.writer(hlsl.allocator).writeAll(bytes);
}

fn print(hlsl: *Hlsl, comptime format: []const u8, args: anytype) !void {
    try hlsl.scratch.writer(hlsl.allocator).print(format, args);
}
