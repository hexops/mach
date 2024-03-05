const std = @import("std");
const Air = @import("../Air.zig");
const DebugInfo = @import("../CodeGen.zig").DebugInfo;
const Entrypoint = @import("../CodeGen.zig").Entrypoint;
const BindingPoint = @import("../CodeGen.zig").BindingPoint;
const BindingTable = @import("../CodeGen.zig").BindingTable;
const Inst = Air.Inst;
const InstIndex = Air.InstIndex;
const Builtin = Air.Inst.Builtin;

const Glsl = @This();

air: *const Air,
allocator: std.mem.Allocator,
storage: std.ArrayListUnmanaged(u8),
writer: std.ArrayListUnmanaged(u8).Writer,
bindings: *const BindingTable,
entrypoint_inst: ?Inst.Fn = null,
indent: u32 = 0,

pub fn gen(
    allocator: std.mem.Allocator,
    air: *const Air,
    debug_info: DebugInfo,
    entrypoint: ?Entrypoint,
    bindings: ?*const BindingTable,
) ![]const u8 {
    _ = debug_info;

    var storage = std.ArrayListUnmanaged(u8){};
    var glsl = Glsl{
        .air = air,
        .allocator = allocator,
        .storage = storage,
        .writer = storage.writer(allocator),
        .bindings = bindings orelse &.{},
    };
    defer {
        storage.deinit(allocator);
    }

    try glsl.writeAll("#version 450\n\n");

    for (air.refToList(air.globals_index)) |inst_idx| {
        switch (air.getInst(inst_idx)) {
            .@"struct" => |inst| try glsl.emitStruct(inst),
            else => {},
        }
    }

    // GLSL deosn't support multiple entrypoints so we only generate
    // when `entrypoint` is specified OR there's only one entrypoint
    var entrypoint_name: ?[]const u8 = null;

    if (entrypoint != null) {
        entrypoint_name = std.mem.span(entrypoint.?.name);
    } else {
        const has_multiple_entrypoints = @intFromBool(air.vertex_stage == .none) &
            @intFromBool(air.fragment_stage == .none) &
            @intFromBool(air.compute_stage == .none);

        if (has_multiple_entrypoints == 1) {
            return error.MultipleEntrypoints;
        }
    }

    for (air.refToList(air.globals_index)) |inst_idx| {
        switch (air.getInst(inst_idx)) {
            .@"var" => |inst| try glsl.emitGlobalVar(inst),
            .@"fn" => |inst| {
                const name = glsl.air.getStr(inst.name);
                if (entrypoint_name) |_| {
                    if (std.mem.eql(u8, entrypoint_name.?, name)) {
                        try glsl.emitFn(inst);
                    }
                } else if (inst.stage != .none) {
                    try glsl.emitFn(inst);
                }
            },
            .@"struct" => {},
            else => |inst| try glsl.print("TopLevel: {}\n", .{inst}), // TODO
        }
    }

    return storage.toOwnedSlice(allocator);
}

fn emitElemType(glsl: *Glsl, inst_idx: InstIndex) !void {
    switch (glsl.air.getInst(inst_idx)) {
        .bool => |inst| try glsl.emitBoolElemType(inst),
        .int => |inst| try glsl.emitIntElemType(inst),
        .float => |inst| try glsl.emitFloatElemType(inst),
        else => unreachable,
    }
}

fn emitBoolElemType(glsl: *Glsl, inst: Inst.Bool) !void {
    _ = inst;
    try glsl.writeAll("b");
}

fn emitIntElemType(glsl: *Glsl, inst: Inst.Int) !void {
    try glsl.writeAll(switch (inst.type) {
        .u32 => "u",
        .i32 => "i",
    });
}

fn emitFloatElemType(glsl: *Glsl, inst: Inst.Float) !void {
    try glsl.writeAll(switch (inst.type) {
        .f32 => "",
        .f16 => "", // TODO - extension for half support?
    });
}

fn emitType(glsl: *Glsl, inst_idx: InstIndex) error{OutOfMemory}!void {
    if (inst_idx == .none) {
        try glsl.writeAll("void");
    } else {
        switch (glsl.air.getInst(inst_idx)) {
            .bool => |inst| try glsl.emitBoolType(inst),
            .int => |inst| try glsl.emitIntType(inst),
            .float => |inst| try glsl.emitFloatType(inst),
            .vector => |inst| try glsl.emitVectorType(inst),
            .matrix => |inst| try glsl.emitMatrixType(inst),
            .array => |inst| try glsl.emitType(inst.elem_type),
            .@"struct" => |inst| try glsl.writeName(inst.name),
            else => |inst| try glsl.print("Type: {}", .{inst}), // TODO
        }
    }
}

fn emitTypeSuffix(glsl: *Glsl, inst_idx: InstIndex) error{OutOfMemory}!void {
    if (inst_idx != .none) {
        switch (glsl.air.getInst(inst_idx)) {
            .array => |inst| try glsl.emitArrayTypeSuffix(inst),
            else => {},
        }
    }
}

fn emitArrayTypeSuffix(glsl: *Glsl, inst: Inst.Array) !void {
    if (inst.len != .none) {
        if (glsl.air.resolveInt(inst.len)) |len| {
            try glsl.print("[{}]", .{len});
        }
    } else {
        try glsl.writeAll("[]");
    }
    try glsl.emitTypeSuffix(inst.elem_type);
}

fn emitBoolType(glsl: *Glsl, inst: Inst.Bool) !void {
    _ = inst;
    try glsl.writeAll("bool");
}

fn emitIntType(glsl: *Glsl, inst: Inst.Int) !void {
    try glsl.writeAll(switch (inst.type) {
        .u32 => "uint",
        .i32 => "int",
    });
}

fn emitFloatType(glsl: *Glsl, inst: Inst.Float) !void {
    try glsl.writeAll(switch (inst.type) {
        .f32 => "float",
        .f16 => "half",
    });
}

fn emitVectorSize(glsl: *Glsl, size: Inst.Vector.Size) !void {
    try glsl.writeAll(switch (size) {
        .two => "2",
        .three => "3",
        .four => "4",
    });
}

fn emitVectorType(glsl: *Glsl, inst: Inst.Vector) !void {
    try glsl.emitElemType(inst.elem_type);
    try glsl.writeAll("vec");
    try glsl.emitVectorSize(inst.size);
}

fn emitMatrixType(glsl: *Glsl, inst: Inst.Matrix) !void {
    // TODO - verify dimension order
    try glsl.emitElemType(inst.elem_type);
    try glsl.writeAll("mat");
    try glsl.emitVectorSize(inst.cols);
    try glsl.writeAll("x");
    try glsl.emitVectorSize(inst.rows);
}

fn emitStruct(glsl: *Glsl, inst: Inst.Struct) !void {
    // Workaround - structures with runtime arrays are not generally supported but can exist directly
    // in a block context which we inline in emitGlobalVar
    for (glsl.air.refToList(inst.members)) |member_index| {
        const member = glsl.air.getInst(member_index).struct_member;

        switch (glsl.air.getInst(member.type)) {
            .array => |array_type| {
                if (array_type.len == .none) {
                    return;
                }
            },
            else => {},
        }
    }

    try glsl.writeAll("struct ");
    try glsl.writeName(inst.name);
    try glsl.writeAll(" {\n");

    glsl.enterScope();
    defer glsl.exitScope();

    for (glsl.air.refToList(inst.members)) |member_index| {
        const member = glsl.air.getInst(member_index).struct_member;

        try glsl.writeIndent();
        try glsl.emitType(member.type);
        try glsl.writeAll(" ");
        try glsl.writeName(member.name);
        try glsl.emitTypeSuffix(member.type);
        try glsl.writeAll(";\n");
    }

    try glsl.writeAll("};\n");
}

fn emitBuiltin(glsl: *Glsl, builtin: Builtin) !void {
    const stage = glsl.entrypoint_inst.?.stage;
    try glsl.writeAll(switch (builtin) {
        .vertex_index => "gl_VertexID",
        .instance_index => "gl_InstanceID",
        .position => if (stage == .vertex) "gl_Position" else "gl_FragCoord",
        .front_facing => "gl_FrontFacing",
        .frag_depth => "gl_FragDepth",
        .local_invocation_id => "gl_LocalInvocationID",
        .local_invocation_index => "gl_LocalInvocationIndex",
        .global_invocation_id => "gl_GlobalInvocationID",
        .workgroup_id => "gl_WorkGroupID",
        .num_workgroups => "gl_NumWorkGroups",
        .sample_index => "gl_SampleID",
        .sample_mask => "gl_SampleMask", // TODO - gl_SampleMaskIn
    });
}

fn emitGlobalVar(glsl: *Glsl, inst: Inst.Var) !void {
    const group = glsl.air.resolveInt(inst.group) orelse return error.ConstExpr;
    const binding = glsl.air.resolveInt(inst.binding) orelse return error.ConstExpr;
    const key = BindingPoint{ .group = @intCast(group), .binding = @intCast(binding) };
    const slot = glsl.bindings.get(key) orelse return error.NoBinding;

    try glsl.print("layout(binding = {}, ", .{slot});
    try glsl.writeAll(if (inst.addr_space == .uniform) "std140" else "std430");
    try glsl.writeAll(") ");
    if (inst.access_mode == .read)
        try glsl.writeAll("readonly ");
    try glsl.writeAll(if (inst.addr_space == .uniform) "uniform" else "buffer");
    try glsl.print(" Block{}", .{slot});
    const var_type = glsl.air.getInst(inst.type);
    switch (var_type) {
        .@"struct" => |struct_inst| {
            // Inline struct to support runtime arrays
            try glsl.writeAll("\n");
            try glsl.writeAll("{\n");

            glsl.enterScope();
            defer glsl.exitScope();

            for (glsl.air.refToList(struct_inst.members)) |member_index| {
                const member = glsl.air.getInst(member_index).struct_member;

                try glsl.writeIndent();
                try glsl.emitType(member.type);
                try glsl.writeAll(" ");
                try glsl.writeName(member.name);
                try glsl.emitTypeSuffix(member.type);
                try glsl.writeAll(";\n");
            }
            try glsl.writeAll("} ");
            try glsl.writeName(inst.name);
            try glsl.writeAll(";\n");
        },
        else => {
            try glsl.writeAll(" { ");
            try glsl.emitType(inst.type);
            try glsl.writeAll(" ");
            try glsl.writeName(inst.name);
            try glsl.emitTypeSuffix(inst.type);
            try glsl.writeAll("; };\n");
        },
    }
}

fn emitGlobal(glsl: *Glsl, location: ?u16, in_out: []const u8, var_type: InstIndex, name: Air.StringIndex) !void {
    try glsl.print("layout(location = {}) {s} ", .{ location.?, in_out });
    try glsl.emitType(var_type);
    try glsl.writeAll(" ");
    try glsl.writeName(name);
    try glsl.emitTypeSuffix(var_type);
    try glsl.writeAll(";\n");
}

fn emitGlobalFnParam(glsl: *Glsl, inst_idx: InstIndex) !void {
    const inst = glsl.air.getInst(inst_idx).fn_param;

    if (inst.builtin == null) {
        try glsl.emitGlobal(inst.location, "in", inst.type, inst.name);
    }
}

fn emitGlobalStructOutputs(glsl: *Glsl, inst: Inst.Struct) !void {
    for (glsl.air.refToList(inst.members)) |member_index| {
        const member = glsl.air.getInst(member_index).struct_member;

        if (member.builtin == null) {
            try glsl.emitGlobal(member.location, "out", member.type, member.name);
        }
    }
}

fn emitGlobalScalarOutput(glsl: *Glsl, inst: Inst.Fn) !void {
    if (inst.return_attrs.builtin == null) {
        try glsl.print("layout(location = {}) out ", .{0});
        try glsl.emitType(inst.return_type);
        try glsl.writeAll(" ");
        try glsl.writeAll("main_output");
        try glsl.emitTypeSuffix(inst.return_type);
        try glsl.writeAll(";\n");
    }
}

fn emitFn(glsl: *Glsl, inst: Inst.Fn) !void {
    if (inst.stage != .none) {
        glsl.entrypoint_inst = inst;

        if (inst.params != .none) {
            const param_list = glsl.air.refToList(inst.params);
            for (param_list) |param_inst_idx| {
                try glsl.emitGlobalFnParam(param_inst_idx);
            }
        }

        if (inst.return_type != .none) {
            switch (glsl.air.getInst(inst.return_type)) {
                .@"struct" => |struct_inst| try glsl.emitGlobalStructOutputs(struct_inst),
                else => try glsl.emitGlobalScalarOutput(inst),
            }
        }

        switch (inst.stage) {
            .compute => |workgroup_size| {
                try glsl.print("layout(local_size_x = {}, local_size_y = {}, local_size_z = {}) in;\n", .{
                    glsl.air.resolveInt(workgroup_size.x) orelse 1,
                    glsl.air.resolveInt(workgroup_size.y) orelse 1,
                    glsl.air.resolveInt(workgroup_size.z) orelse 1,
                });
            },
            else => {},
        }

        try glsl.emitType(.none);
    } else {
        try glsl.emitType(inst.return_type);
    }

    try glsl.writeAll(" ");
    if (inst.stage != .none) {
        try glsl.writeEntrypoint();
    } else {
        try glsl.writeName(inst.name);
    }
    try glsl.writeAll("(");

    if (inst.stage == .none) {
        glsl.enterScope();
        defer glsl.exitScope();

        var add_comma = false;

        if (inst.params != .none) {
            for (glsl.air.refToList(inst.params)) |param_inst_idx| {
                try glsl.writeAll(if (add_comma) ",\n" else "\n");
                add_comma = true;
                try glsl.writeIndent();
                try glsl.emitFnParam(param_inst_idx);
            }
        }
    }

    try glsl.writeAll(")\n");

    const block = glsl.air.getInst(inst.block).block;
    try glsl.writeAll("{\n");
    {
        glsl.enterScope();
        defer glsl.exitScope();

        for (glsl.air.refToList(block)) |statement| {
            try glsl.emitStatement(statement);
        }
    }
    try glsl.writeAll("}\n");

    glsl.entrypoint_inst = null;
}

fn emitFnParam(glsl: *Glsl, inst_idx: InstIndex) !void {
    const inst = glsl.air.getInst(inst_idx).fn_param;

    try glsl.emitType(inst.type);
    try glsl.writeAll(" ");
    try glsl.writeName(inst.name);
}

fn emitStatement(glsl: *Glsl, inst_idx: InstIndex) error{OutOfMemory}!void {
    try glsl.writeIndent();
    switch (glsl.air.getInst(inst_idx)) {
        .@"var" => |inst| try glsl.emitVar(inst),
        //.@"const" => |inst| try glsl.emitConst(inst),
        .block => |block| try glsl.emitBlock(block),
        // .loop => |inst| try glsl.emitLoop(inst),
        // .continuing
        .@"return" => |return_inst_idx| try glsl.emitReturn(return_inst_idx),
        // .break_if
        .@"if" => |inst| try glsl.emitIf(inst),
        // .@"while" => |inst| try glsl.emitWhile(inst),
        .@"for" => |inst| try glsl.emitFor(inst),
        // .switch
        //.discard => try glsl.emitDiscard(),
        // .@"break" => try glsl.emitBreak(),
        .@"continue" => try glsl.writeAll("continue;\n"),
        // .call => |inst| try glsl.emitCall(inst),
        .assign,
        .nil_intrinsic,
        .texture_store,
        => {
            try glsl.emitExpr(inst_idx);
            try glsl.writeAll(";\n");
        },
        //else => |inst| std.debug.panic("TODO: implement Air tag {s}", .{@tagName(inst)}),
        else => |inst| try glsl.print("Statement: {}\n", .{inst}), // TODO
    }
}

fn emitVar(glsl: *Glsl, inst: Inst.Var) !void {
    const t = if (inst.type != .none) inst.type else inst.init;
    try glsl.emitType(t);
    try glsl.writeAll(" ");
    try glsl.writeName(inst.name);
    try glsl.emitTypeSuffix(t);
    if (inst.init != .none) {
        try glsl.writeAll(" = ");
        try glsl.emitExpr(inst.init);
    }
    try glsl.writeAll(";\n");
}

fn emitBlock(glsl: *Glsl, block: Air.RefIndex) !void {
    try glsl.writeAll("{\n");
    {
        glsl.enterScope();
        defer glsl.exitScope();

        for (glsl.air.refToList(block)) |statement| {
            try glsl.emitStatement(statement);
        }
    }
    try glsl.writeIndent();
    try glsl.writeAll("}\n");
}

fn emitReturn(glsl: *Glsl, inst_idx: InstIndex) !void {
    if (glsl.entrypoint_inst) |fn_inst| {
        if (fn_inst.return_type != .none) {
            switch (glsl.air.getInst(fn_inst.return_type)) {
                .@"struct" => |struct_inst| try glsl.emitGlobalStructReturn(struct_inst, inst_idx),
                else => try glsl.emitGlobalScalarReturn(fn_inst, inst_idx),
            }
            try glsl.writeIndent();
        }
        try glsl.writeAll("return;\n");
    } else {
        try glsl.writeAll("return");
        if (inst_idx != .none) {
            try glsl.writeAll(" ");
            try glsl.emitExpr(inst_idx);
        }
        try glsl.writeAll(";\n");
    }
}

fn emitGlobalStructReturn(glsl: *Glsl, inst: Inst.Struct, inst_idx: InstIndex) !void {
    for (glsl.air.refToList(inst.members), 0..) |member_index, i| {
        const member = glsl.air.getInst(member_index).struct_member;

        if (i > 0) try glsl.writeIndent();
        if (member.builtin) |builtin| {
            try glsl.emitBuiltin(builtin);
        } else {
            try glsl.writeName(member.name);
        }
        try glsl.writeAll(" = ");
        try glsl.emitExpr(inst_idx);
        try glsl.writeAll(".");
        try glsl.writeName(member.name);
        try glsl.writeAll(";\n");
    }
}

fn emitGlobalScalarReturn(glsl: *Glsl, inst: Inst.Fn, inst_idx: InstIndex) !void {
    if (inst.return_attrs.builtin) |builtin| {
        try glsl.emitBuiltin(builtin);
    } else {
        try glsl.writeAll("main_output");
    }
    if (inst_idx != .none) {
        try glsl.writeAll(" = ");
        try glsl.emitExpr(inst_idx);
    }
    try glsl.writeAll(";\n");
}

fn emitIf(glsl: *Glsl, inst: Inst.If) !void {
    try glsl.writeAll("if (");
    try glsl.emitExpr(inst.cond);
    try glsl.writeAll(")\n");
    {
        const body_inst = glsl.air.getInst(inst.body);
        if (body_inst != .block)
            glsl.enterScope();
        try glsl.emitStatement(inst.body);
        if (body_inst != .block)
            glsl.exitScope();
    }
    if (inst.@"else" != .none) {
        try glsl.writeIndent();
        try glsl.writeAll("else\n");
        try glsl.emitStatement(inst.@"else");
    }
    try glsl.writeAll("\n");
}

fn emitFor(glsl: *Glsl, inst: Inst.For) !void {
    try glsl.writeAll("for (\n");
    {
        glsl.enterScope();
        defer glsl.exitScope();

        try glsl.emitStatement(inst.init);
        try glsl.writeIndent();
        try glsl.emitExpr(inst.cond);
        try glsl.writeAll(";\n");
        try glsl.writeIndent();
        try glsl.emitExpr(inst.update);
        try glsl.writeAll(")\n");
    }
    try glsl.emitStatement(inst.body);
}

fn emitExpr(glsl: *Glsl, inst_idx: InstIndex) error{OutOfMemory}!void {
    switch (glsl.air.getInst(inst_idx)) {
        .var_ref => |inst| try glsl.emitVarRef(inst),
        .bool => |inst| try glsl.emitBool(inst),
        .int => |inst| try glsl.emitInt(inst),
        .float => |inst| try glsl.emitFloat(inst),
        .vector => |inst| try glsl.emitVector(inst),
        //.matrix => |inst| try glsl.emitMatrix(inst),
        .array => |inst| try glsl.emitArray(inst),
        //.nil_intrinsic => |inst| try glsl.emitNilIntrinsic(inst),
        .unary => |inst| try glsl.emitUnary(inst),
        .unary_intrinsic => |inst| try glsl.emitUnaryIntrinsic(inst),
        .binary => |inst| try glsl.emitBinary(inst),
        .binary_intrinsic => |inst| try glsl.emitBinaryIntrinsic(inst),
        .triple_intrinsic => |inst| try glsl.emitTripleIntrinsic(inst),
        .assign => |inst| try glsl.emitAssign(inst),
        .field_access => |inst| try glsl.emitFieldAccess(inst),
        .swizzle_access => |inst| try glsl.emitSwizzleAccess(inst),
        .index_access => |inst| try glsl.emitIndexAccess(inst),
        //.call => |inst| try glsl.emitCall(inst),
        //.struct_construct: StructConstruct,
        //.bitcast: Bitcast,
        //.texture_sample => |inst| try glsl.emitTextureSample(inst),
        //.texture_dimension => |inst| try glsl.emitTextureDimension(inst),
        //.texture_load => |inst| try glsl.emitTextureLoad(inst),
        //.texture_store => |inst| try glsl.emitTextureStore(inst),
        //else => |inst| std.debug.panic("TODO: implement Air tag {s}", .{@tagName(inst)}),
        else => |inst| std.debug.panic("Expr: {}", .{inst}), // TODO
    }
}

fn emitVarRef(glsl: *Glsl, inst_idx: InstIndex) !void {
    switch (glsl.air.getInst(inst_idx)) {
        .@"var" => |v| try glsl.writeName(v.name),
        .@"const" => |c| try glsl.writeName(c.name),
        .fn_param => |p| {
            if (p.builtin) |builtin| {
                try glsl.emitBuiltin(builtin);
            } else {
                try glsl.writeName(p.name);
            }
        },
        else => |x| std.debug.panic("VarRef: {}", .{x}), // TODO
    }
}

fn emitBool(glsl: *Glsl, inst: Inst.Bool) !void {
    switch (inst.value.?) {
        .literal => |lit| try glsl.print("{}", .{lit}),
        .cast => @panic("TODO"),
    }
}

fn emitInt(glsl: *Glsl, inst: Inst.Int) !void {
    switch (glsl.air.getValue(Inst.Int.Value, inst.value.?)) {
        .literal => |lit| try glsl.print("{}", .{lit}),
        .cast => |cast| try glsl.emitIntCast(inst, cast),
    }
}

fn emitIntCast(glsl: *Glsl, dest_type: Inst.Int, cast: Inst.ScalarCast) !void {
    try glsl.emitIntType(dest_type);
    try glsl.writeAll("(");
    try glsl.emitExpr(cast.value);
    try glsl.writeAll(")");
}

fn emitFloat(glsl: *Glsl, inst: Inst.Float) !void {
    switch (glsl.air.getValue(Inst.Float.Value, inst.value.?)) {
        .literal => |lit| try glsl.print("{}", .{lit}),
        .cast => |cast| try glsl.emitFloatCast(inst, cast),
    }
}

fn emitFloatCast(glsl: *Glsl, dest_type: Inst.Float, cast: Inst.ScalarCast) !void {
    try glsl.emitFloatType(dest_type);
    try glsl.writeAll("(");
    try glsl.emitExpr(cast.value);
    try glsl.writeAll(")");
}

fn emitVector(glsl: *Glsl, inst: Inst.Vector) !void {
    try glsl.emitVectorType(inst);
    try glsl.writeAll("(");

    const value = glsl.air.getValue(Inst.Vector.Value, inst.value.?);
    switch (value) {
        .literal => |literal| try glsl.emitVectorElems(inst.size, literal),
        .cast => |cast| try glsl.emitVectorElems(inst.size, cast.value),
    }

    try glsl.writeAll(")");
}

fn emitVectorElems(glsl: *Glsl, size: Inst.Vector.Size, value: [4]InstIndex) !void {
    for (value[0..@intFromEnum(size)], 0..) |elem_inst, i| {
        try glsl.writeAll(if (i == 0) "" else ", ");
        try glsl.emitExpr(elem_inst);
    }
}

fn emitArray(glsl: *Glsl, inst: Inst.Array) !void {
    try glsl.emitType(inst.elem_type);
    try glsl.writeAll("[](");
    {
        glsl.enterScope();
        defer glsl.exitScope();

        const value = glsl.air.refToList(inst.value.?);
        for (value, 0..) |elem_inst, i| {
            try glsl.writeAll(if (i == 0) "\n" else ",\n");
            try glsl.writeIndent();
            try glsl.emitExpr(elem_inst);
        }
    }
    try glsl.writeAll(")");
}

fn emitUnary(glsl: *Glsl, inst: Inst.Unary) !void {
    try glsl.writeAll(switch (inst.op) {
        .not => "!",
        .negate => "-",
        .deref => "*",
        .addr_of => @panic("unsupported"),
    });
    try glsl.emitExpr(inst.expr);
}

fn emitUnaryIntrinsic(glsl: *Glsl, inst: Inst.UnaryIntrinsic) !void {
    switch (inst.op) {
        .array_length => try glsl.emitArrayLength(inst),
        else => {
            try glsl.writeAll(switch (inst.op) {
                .array_length => unreachable,
                .degrees => "radians",
                .radians => "degrees",
                .all => "all",
                .any => "any",
                .abs => "abs",
                .acos => "acos",
                .acosh => "acosh",
                .asin => "asin",
                .asinh => "asinh",
                .atan => "atan",
                .atanh => "atanh",
                .ceil => "ceil",
                .cos => "cos",
                .cosh => "cosh",
                //.count_leading_zeros => "count_leading_zeros",
                .count_one_bits => "bitCount",
                //.count_trailing_zeros => "count_trailing_zeros",
                .exp => "exp",
                .exp2 => "exp2",
                //.first_leading_bit => "first_leading_bit",
                //.first_trailing_bit => "first_trailing_bit",
                .floor => "floor",
                .fract => "fract",
                .inverse_sqrt => "inversesqrt",
                .length => "length",
                .log => "log",
                .log2 => "log2",
                //.quantize_to_F16 => "quantize_to_F16",
                .reverseBits => "bitfieldReverse",
                .round => "round",
                //.saturate => "saturate",
                .sign => "sign",
                .sin => "sin",
                .sinh => "sinh",
                .sqrt => "sqrt",
                .tan => "tan",
                .tanh => "tanh",
                .trunc => "trunc",
                .dpdx => "dFdx",
                .dpdx_coarse => "dFdxCoarse",
                .dpdx_fine => "dFdxFine",
                .dpdy => "dFdy",
                .dpdy_coarse => "dFdyCoarse",
                .dpdy_fine => "dFdyFine",
                .fwidth => "fwidth",
                .fwidth_coarse => "fwidthCoarse",
                .fwidth_fine => "fwidthFine",
                .normalize => "normalize",
                else => std.debug.panic("TODO: implement Air tag {s}", .{@tagName(inst.op)}),
            });
            try glsl.writeAll("(");
            try glsl.emitExpr(inst.expr);
            try glsl.writeAll(")");
        },
    }
}

fn emitArrayLength(glsl: *Glsl, inst: Inst.UnaryIntrinsic) !void {
    switch (glsl.air.getInst(inst.expr)) {
        .unary => |un| switch (un.op) {
            .addr_of => try glsl.emitArrayLengthTarget(un.expr, 0),
            else => try glsl.print("ArrayLength (unary_op): {}", .{un.op}),
        },
        else => |array_length_expr| try glsl.print("ArrayLength (array_length_expr): {}", .{array_length_expr}),
    }
}

fn emitArrayLengthTarget(glsl: *Glsl, inst_idx: InstIndex, offset: usize) error{OutOfMemory}!void {
    try glsl.writeAll("(");
    try glsl.emitExpr(inst_idx);
    try glsl.print(".length() - {}", .{offset});
    try glsl.writeAll(")");
}

fn emitBinary(glsl: *Glsl, inst: Inst.Binary) !void {
    try glsl.writeAll("(");
    try glsl.emitExpr(inst.lhs);
    try glsl.print(" {s} ", .{switch (inst.op) {
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
    try glsl.emitExpr(inst.rhs);
    try glsl.writeAll(")");
}

fn emitBinaryIntrinsic(glsl: *Glsl, inst: Inst.BinaryIntrinsic) !void {
    try glsl.writeAll(switch (inst.op) {
        .min => "min",
        .max => "max",
        .atan2 => "atan",
        .distance => "distance",
        .dot => "dot",
        .pow => "pow",
        .step => "step",
    });
    try glsl.writeAll("(");
    try glsl.emitExpr(inst.lhs);
    try glsl.writeAll(", ");
    try glsl.emitExpr(inst.rhs);
    try glsl.writeAll(")");
}

fn emitTripleIntrinsic(glsl: *Glsl, inst: Inst.TripleIntrinsic) !void {
    try glsl.writeAll(switch (inst.op) {
        .smoothstep => "smoothstep",
        .clamp => "clamp",
        .mix => "mix",
    });
    try glsl.writeAll("(");
    try glsl.emitExpr(inst.a1);
    try glsl.writeAll(", ");
    try glsl.emitExpr(inst.a2);
    try glsl.writeAll(", ");
    try glsl.emitExpr(inst.a3);
    try glsl.writeAll(")");
}

fn emitAssign(glsl: *Glsl, inst: Inst.Assign) !void {
    try glsl.emitExpr(inst.lhs);
    try glsl.print(" {s}= ", .{switch (inst.mod) {
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
    try glsl.emitExpr(inst.rhs);
}

fn emitFieldAccess(glsl: *Glsl, inst: Inst.FieldAccess) !void {
    try glsl.emitExpr(inst.base);
    try glsl.writeAll(".");
    try glsl.writeName(inst.name);
}

fn emitSwizzleAccess(glsl: *Glsl, inst: Inst.SwizzleAccess) !void {
    try glsl.emitExpr(inst.base);
    try glsl.writeAll(".");
    for (0..@intFromEnum(inst.size)) |i| {
        switch (inst.pattern[i]) {
            .x => try glsl.writeAll("x"),
            .y => try glsl.writeAll("y"),
            .z => try glsl.writeAll("z"),
            .w => try glsl.writeAll("w"),
        }
    }
}

fn emitIndexAccess(glsl: *Glsl, inst: Inst.IndexAccess) !void {
    try glsl.emitExpr(inst.base);
    try glsl.writeAll("[");
    try glsl.emitExpr(inst.index);
    try glsl.writeAll("]");
}

fn enterScope(glsl: *Glsl) void {
    glsl.indent += 4;
}

fn exitScope(glsl: *Glsl) void {
    glsl.indent -= 4;
}

fn writeIndent(glsl: *Glsl) !void {
    try glsl.writer.writeByteNTimes(' ', glsl.indent);
}

fn writeEntrypoint(glsl: *Glsl) !void {
    try glsl.writeAll("main");
}

fn writeName(glsl: *Glsl, name: Air.StringIndex) !void {
    // Suffix with index as WGSL has different scoping rules and to avoid conflicts with keywords
    const str = glsl.air.getStr(name);
    try glsl.print("{s}_{}", .{ str, @intFromEnum(name) });
}

fn writeAll(glsl: *Glsl, bytes: []const u8) !void {
    try glsl.writer.writeAll(bytes);
}

fn print(glsl: *Glsl, comptime format: []const u8, args: anytype) !void {
    return std.fmt.format(glsl.writer, format, args);
}
