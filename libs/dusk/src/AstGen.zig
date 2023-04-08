const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("Token.zig");
const IR = @import("IR.zig");
const ErrorList = @import("ErrorList.zig");
const AstGen = @This();

allocator: std.mem.Allocator,
tree: *const Ast,
instructions: std.ArrayListUnmanaged(IR.Inst) = .{},
refs: std.ArrayListUnmanaged(IR.Inst.Ref) = .{},
strings: std.ArrayListUnmanaged(u8) = .{},
scratch: std.ArrayListUnmanaged(IR.Inst.Ref) = .{},
errors: ErrorList,
scope_pool: std.heap.MemoryPool(Scope),

pub const Scope = struct {
    tag: Tag,
    /// only null if tag == .root
    parent: ?*Scope,
    decls: std.AutoHashMapUnmanaged(Ast.Index, IR.Inst.Ref) = .{},

    pub const Tag = enum {
        root,
        func,
        block,
    };
};

pub fn genTranslationUnit(self: *AstGen) !u32 {
    const global_decls = self.tree.spanToList(0);

    const scratch_top = self.scratch.items.len;
    defer self.scratch.shrinkRetainingCapacity(scratch_top);

    var root_scope = try self.scope_pool.create();
    root_scope.* = .{ .tag = .root, .parent = null };

    self.scanDecls(root_scope, global_decls) catch |err| switch (err) {
        error.AnalysisFail => return try self.addRefList(self.scratch.items[scratch_top..]),
        error.OutOfMemory => return error.OutOfMemory,
    };

    for (global_decls) |node| {
        const global = self.genDecl(root_scope, node) catch |err| switch (err) {
            error.AnalysisFail => continue,
            error.OutOfMemory => return error.OutOfMemory,
        };
        try self.scratch.append(self.allocator, global);
    }

    return try self.addRefList(self.scratch.items[scratch_top..]);
}

pub fn scanDecls(self: *AstGen, scope: *Scope, decls: []const Ast.Index) !void {
    std.debug.assert(scope.decls.count() == 0);

    for (decls) |decl| {
        const loc = self.declNameLoc(decl).?;
        const name = loc.slice(self.tree.source);

        // TODO
        // if (Token.isReserved(name)) {
        //     try self.errors.add(
        //         loc,
        //         "the name '{s}' has ben reserved",
        //         .{name},
        //         null,
        //     );
        // }

        var name_iter = scope.decls.keyIterator();
        while (name_iter.next()) |node| {
            if (std.mem.eql(u8, self.declNameLoc(node.*).?.slice(self.tree.source), name)) {
                try self.errors.add(
                    loc,
                    "redeclaration of '{s}'",
                    .{name},
                    try self.errors.createNote(
                        self.declNameLoc(node.*).?,
                        "other declaration here",
                        .{},
                    ),
                );
                return error.AnalysisFail;
            }
        }

        try scope.decls.putNoClobber(self.scope_pool.arena.allocator(), decl, .none);
    }
}

pub fn genDecl(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    const ref = scope.decls.get(node).?;
    if (ref != .none) return ref;

    const decl = switch (self.tree.nodeTag(node)) {
        .global_variable => try self.genGlobalVariable(scope, node),
        .type_alias => try self.genTypeAlias(scope, node),
        .struct_decl => try self.genStruct(scope, node),
        else => return error.AnalysisFail, // TODO: else prong should not ever be trigerred
    };
    scope.decls.putAssumeCapacity(node, decl);
    return decl;
}

pub fn declRef(self: *AstGen, scope: *Scope, loc: Token.Loc) !IR.Inst.Ref {
    const name = loc.slice(self.tree.source);

    var s = scope;
    while (true) {
        var name_iter = s.decls.keyIterator();
        while (name_iter.next()) |node| {
            if (std.mem.eql(u8, self.declNameLoc(node.*).?.slice(self.tree.source), name)) {
                return self.genDecl(scope, node.*);
            }
        }
        s = scope.parent orelse break;
    }

    try self.errors.add(
        loc,
        "use of undeclared identifier '{s}'",
        .{name},
        null,
    );
    return error.AnalysisFail;
}

pub fn genTypeAlias(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    return self.genType(scope, self.tree.nodeLHS(node));
}

pub fn genGlobalVariable(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .global_variable);

    const inst = try self.reserveInst();
    const rhs = self.tree.nodeRHS(node);
    const gv = self.tree.extraData(Ast.Node.GlobalVarDecl, self.tree.nodeLHS(node));
    // for (self.tree.spanToList(gv.attrs), 0..) |attr_node, i| {
    // const attr = switch (self.tree.nodeTag(attr_node)) {
    //     .attr => {},
    // };
    // }
    var var_type = IR.Inst.Ref.none;
    if (gv.type != Ast.null_index) {
        var_type = try self.genType(scope, gv.type);
    }

    var addr_space: IR.Inst.GlobalVariableDecl.AddressSpace = .none;
    if (gv.access_mode != Ast.null_index) {
        const addr_space_loc = self.tree.tokenLoc(gv.addr_space);
        const ast_addr_space = std.meta.stringToEnum(Ast.AddressSpace, addr_space_loc.slice(self.tree.source)).?;
        addr_space = switch (ast_addr_space) {
            .function => .function,
            .private => .private,
            .workgroup => .workgroup,
            .uniform => .uniform,
            .storage => .storage,
        };
    }

    var access_mode: IR.Inst.GlobalVariableDecl.AccessMode = .none;
    if (gv.access_mode != Ast.null_index) {
        const access_mode_loc = self.tree.tokenLoc(gv.access_mode);
        const ast_access_mode = std.meta.stringToEnum(Ast.AccessMode, access_mode_loc.slice(self.tree.source)).?;
        access_mode = switch (ast_access_mode) {
            .read => .read,
            .write => .write,
            .read_write => .read_write,
        };
    }

    var expr = IR.Inst.Ref.none;
    if (rhs != Ast.null_index) {
        expr = try self.genExpr(scope, rhs);
    }

    const name_index = try self.addString(self.declNameLoc(node).?.slice(self.tree.source));
    self.instructions.items[inst] = .{
        .tag = .global_variable_decl,
        .data = .{
            .global_variable_decl = .{
                .name = name_index,
                .type = var_type,
                .addr_space = addr_space,
                .access_mode = access_mode,
                .attrs = 0, // TODO
                .expr = expr,
            },
        },
    };
    return IR.Inst.toRef(inst);
}

pub fn genStruct(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .struct_decl);

    const inst = try self.reserveInst();

    const scratch_top = self.scratch.items.len;
    defer self.scratch.shrinkRetainingCapacity(scratch_top);

    const member_list = self.tree.spanToList(self.tree.nodeLHS(node));
    for (member_list, 0..) |member_node, i| {
        const member_inst = try self.reserveInst();
        const member_loc = self.tree.tokenLoc(self.tree.nodeToken(member_node));
        const member_type_node = self.tree.nodeRHS(member_node);
        const member_type_name = self.tree.tokenLoc(self.tree.nodeToken(member_type_node));
        const member_type_ref = self.genType(scope, member_type_node) catch |err| switch (err) {
            error.AnalysisFail => continue,
            error.OutOfMemory => return error.OutOfMemory,
        };

        switch (member_type_ref) {
            .bool_type, .i32_type, .u32_type, .f32_type, .f16_type => {},
            .sampler_type, .comparison_sampler_type, .external_sampled_texture_type => {
                try self.errors.add(
                    member_loc,
                    "invalid struct member type '{s}'",
                    .{member_type_name.slice(self.tree.source)},
                    null,
                );
                continue;
            },
            .none, .true_literal, .false_literal => unreachable,
            _ => switch (self.instructions.items[member_type_ref.toIndex().?].tag) {
                .vector_type, .matrix_type, .atomic_type, .struct_decl => {},
                .array_type => {
                    if (self.instructions.items[member_type_ref.toIndex().?].data.array_type.size == .none and i + 1 != member_list.len) {
                        try self.errors.add(
                            member_loc,
                            "struct member with runtime-sized array type, must be the last member of the structure",
                            .{},
                            null,
                        );
                        continue;
                    }
                },
                .ptr_type,
                .sampled_texture_type,
                .multisampled_texture_type,
                .storage_texture_type,
                .depth_texture_type,
                => {
                    try self.errors.add(
                        member_loc,
                        "invalid struct member type '{s}'",
                        .{member_type_name.slice(self.tree.source)},
                        null,
                    );
                    continue;
                },
                else => unreachable,
            },
        }

        const name_index = try self.addString(member_loc.slice(self.tree.source));
        self.instructions.items[member_inst] = .{
            .tag = .struct_member,
            .data = .{
                .struct_member = .{
                    .name = name_index,
                    .type = member_type_ref,
                    .@"align" = 0, // TODO
                },
            },
        };
        try self.scratch.append(self.allocator, IR.Inst.toRef(member_inst));
    }

    const name = self.declNameLoc(node).?.slice(self.tree.source);
    const name_index = try self.addString(name);
    const list = try self.addRefList(self.scratch.items[scratch_top..]);

    self.instructions.items[inst] = .{
        .tag = .struct_decl,
        .data = .{
            .struct_decl = .{
                .name = name_index,
                .members = list,
            },
        },
    };
    return IR.Inst.toRef(inst);
}

pub fn genExpr(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    const tag = self.tree.nodeTag(node);
    const lhs = self.tree.nodeLHS(node);
    const rhs = self.tree.nodeRHS(node);

    switch (tag) {
        .bool_true => return .true_literal,
        .bool_false => return .true_literal,
        else => {},
    }

    const inst_index = try self.reserveInst();
    const inst: IR.Inst = switch (tag) {
        .number_literal => .{ .tag = .integer_literal, .data = .{ .integer_literal = 1 } },
        .not => .{ .tag = .not, .data = .{ .ref = try self.genExpr(scope, lhs) } },
        .negate => .{ .tag = .negate, .data = .{ .ref = try self.genExpr(scope, lhs) } },
        .deref => .{ .tag = .deref, .data = .{ .ref = try self.genExpr(scope, lhs) } },
        .addr_of => .{ .tag = .addr_of, .data = .{ .ref = try self.genExpr(scope, lhs) } },
        .mul => .{ .tag = .mul, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .div => .{ .tag = .div, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .mod => .{ .tag = .mod, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .add => .{ .tag = .add, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .sub => .{ .tag = .sub, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .shift_left => .{ .tag = .shift_left, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .shift_right => .{ .tag = .shift_right, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .binary_and => .{ .tag = .binary_and, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .binary_or => .{ .tag = .binary_or, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .binary_xor => .{ .tag = .binary_xor, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .circuit_and => .{ .tag = .circuit_and, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .circuit_or => .{ .tag = .circuit_or, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .equal => .{ .tag = .equal, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .not_equal => .{ .tag = .not_equal, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .less => .{ .tag = .less, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .less_equal => .{ .tag = .less_equal, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .greater => .{ .tag = .greater, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .greater_equal => .{ .tag = .greater_equal, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .index_access => .{ .tag = .index, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .component_access => .{ .tag = .member_access, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genExpr(scope, rhs) } } },
        .bitcast => .{ .tag = .bitcast, .data = .{ .binary = .{ .lhs = try self.genExpr(scope, lhs), .rhs = try self.genType(scope, rhs) } } },
        .ident_expr => .{
            .tag = .ident,
            .data = .{ .name = try self.addString(self.tree.tokenLoc(self.tree.nodeToken(node)).slice(self.tree.source)) },
        },
        else => {
            std.debug.print("WTF REALLY\n", .{});
            unreachable;
        },
    };

    self.instructions.items[inst_index] = inst;
    return IR.Inst.toRef(inst_index);
}

pub fn addString(self: *AstGen, str: []const u8) error{OutOfMemory}!u32 {
    const len = str.len + 1;
    try self.strings.ensureUnusedCapacity(self.allocator, len);
    self.strings.appendSliceAssumeCapacity(str);
    self.strings.appendAssumeCapacity('\x00');
    return @intCast(u32, self.strings.items.len - len);
}

pub fn addRefList(self: *AstGen, list: []const IR.Inst.Ref) error{OutOfMemory}!u32 {
    const len = list.len + 1;
    try self.refs.ensureUnusedCapacity(self.allocator, len);
    self.refs.appendSliceAssumeCapacity(list);
    self.refs.appendAssumeCapacity(.none);
    return @intCast(u32, self.refs.items.len - len);
}

pub fn reserveInst(self: *AstGen) error{OutOfMemory}!IR.Inst.Index {
    try self.instructions.append(self.allocator, undefined);
    return @intCast(IR.Inst.Index, self.instructions.items.len - 1);
}

pub fn addInst(self: *AstGen, inst: IR.Inst) error{OutOfMemory}!IR.Inst.Index {
    try self.instructions.append(self.allocator, inst);
    return @intCast(IR.Inst.Index, self.instructions.items.len - 1);
}

// // pub fn expression(self: *AstGen, node: Ast.Index) !?IR.Expression {
// //     const lhs = self.tree.nodeLHS(node);
// //     const rhs = self.tree.nodeRHS(node);
// //     const loc = self.tree.tokenLoc(self.tree.nodeToken(node));
// //     return switch (self.tree.nodeTag(node)) {
// //         .mul => {
// //             const lir = try self.expression(lhs) orelse return null;
// //             const rir = try self.expression(rhs) orelse return null;

// //             const is_valid_op =
// //                 (lir == .number and rir == .number) or
// //                 ((lir == .construct and lir.construct == .vector) and rir == .number) or
// //                 (lir == .number and (rir == .construct and rir.construct == .vector)) or
// //                 ((lir == .construct and lir.construct == .vector) and (rir == .construct and rir.construct == .vector)) or
// //                 ((lir == .construct and lir.construct == .matrix) and (rir == .construct and rir.construct == .matrix));
// //             if (!is_valid_op) {
// //                 try self.errors.add(
// //                     loc,
// //                     "invalid operation with '{s}' and '{s}'",
// //                     .{ @tagName(std.meta.activeTag(lir)), @tagName(std.meta.activeTag(rir)) },
// //                     null,
// //                 );
// //                 return null;
// //             }
// //         },
// //         // .div,
// //         // .mod,
// //         // .add,
// //         // .sub,
// //         // .shift_left,
// //         // .shift_right,
// //         // .binary_and,
// //         // .binary_or,
// //         // .binary_xor,
// //         // .circuit_and,
// //         // .circuit_or,
// //         .number_literal => .{ .literal = try self.create(.{ .number = try self.create(try self.numberLiteral(node) orelse return null) }) },
// //         .bool_literal => .{ .literal = try self.create(.{ .bool = self.boolLiteral(node) }) },
// //         else => return null, // TODO
// //     };
// // }

// // pub fn numberLiteral(self: *AstGen, node: Ast.Index) !?IR.NumberLiteral {
// //     const loc = self.tree.tokenLoc(self.tree.nodeToken(node));
// //     const str = loc.slice(self.tree.source);

// //     if (std.mem.startsWith(u8, str, "0") and
// //         !std.mem.endsWith(u8, str, "i") and
// //         !std.mem.endsWith(u8, str, "u") and
// //         !std.mem.endsWith(u8, str, "f") and
// //         !std.mem.endsWith(u8, str, "h"))
// //     {
// //         try self.errors.add(
// //             loc,
// //             "number literal cannot have leading 0",
// //             .{str},
// //             null,
// //         );
// //         return null;
// //     }

// //     return null;
// // }

// // pub fn boolLiteral(self: *AstGen, node: Ast.Index) bool {
// //     const loc = self.tree.tokenLoc(self.tree.nodeToken(node));
// //     const str = loc.slice(self.tree.source);
// //     return str[0] == 't';
// // }

pub fn genType(self: *AstGen, scope: *Scope, node: Ast.Index) error{ AnalysisFail, OutOfMemory }!IR.Inst.Ref {
    return switch (self.tree.nodeTag(node)) {
        .bool_type => try self.genBoolType(node),
        .number_type => try self.genNumberType(node),
        .vector_type => try self.genVectorType(scope, node),
        .matrix_type => try self.genMatrixType(scope, node),
        .atomic_type => try self.genAtomicType(scope, node),
        .array_type => try self.genArrayType(scope, node),
        .user_type => {
            const node_loc = self.tree.tokenLoc(self.tree.nodeToken(node));
            const decl_ref = try self.declRef(scope, node_loc);
            switch (decl_ref) {
                .bool_type,
                .i32_type,
                .u32_type,
                .f32_type,
                .f16_type,
                .sampler_type,
                .comparison_sampler_type,
                .external_sampled_texture_type,
                => return decl_ref,
                .none, .true_literal, .false_literal => unreachable,
                _ => switch (self.instructions.items[decl_ref.toIndex().?].tag) {
                    .vector_type,
                    .matrix_type,
                    .atomic_type,
                    .array_type,
                    .ptr_type,
                    .sampled_texture_type,
                    .multisampled_texture_type,
                    .storage_texture_type,
                    .depth_texture_type,
                    .struct_decl,
                    => return decl_ref,
                    .global_variable_decl => {
                        try self.errors.add(
                            node_loc,
                            "'{s}' is not a type",
                            .{node_loc.slice(self.tree.source)},
                            null,
                        );
                        return error.AnalysisFail;
                    },
                    else => unreachable,
                },
            }
        },
        .sampler_type => try self.genSamplerType(node),
        .sampled_texture_type => try self.genSampledTextureType(scope, node),
        .multisampled_texture_type => try self.genMultigenSampledTextureType(scope, node),
        .storage_texture_type => try self.genStorageTextureType(node),
        .depth_texture_type => try self.genDepthTextureType(node),
        .external_texture_type => try self.genExternalTextureType(node),
        else => unreachable,
    };
}

pub fn genSampledTextureType(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .sampled_texture_type);

    const inst = try self.reserveInst();
    const component_type_node = self.tree.nodeLHS(node);
    const component_type_ref = try self.genType(scope, component_type_node);

    switch (component_type_ref) {
        .i32_type,
        .u32_type,
        .f32_type,
        => {},
        .bool_type,
        .f16_type,
        .sampler_type,
        .comparison_sampler_type,
        .external_sampled_texture_type,
        => {
            try self.errors.add(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid sampled texture component type",
                .{},
                try self.errors.createNote(
                    null,
                    "must be 'i32', 'u32' or 'f32'",
                    .{},
                ),
            );
            return error.AnalysisFail;
        },
        .none, .true_literal, .false_literal => unreachable,
        _ => switch (self.instructions.items[component_type_ref.toIndex().?].tag) {
            .vector_type,
            .matrix_type,
            .atomic_type,
            .array_type,
            .ptr_type,
            .sampled_texture_type,
            .multisampled_texture_type,
            .storage_texture_type,
            .depth_texture_type,
            .struct_decl,
            => {
                try self.errors.add(
                    self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                    "invalid sampled texture component type",
                    .{},
                    try self.errors.createNote(
                        null,
                        "must be 'i32', 'u32' or 'f32'",
                        .{},
                    ),
                );
                return error.AnalysisFail;
            },
            else => unreachable,
        },
    }

    const token_tag = self.tree.tokenTag(self.tree.nodeToken(node));
    self.instructions.items[inst] = .{
        .tag = .sampled_texture_type,
        .data = .{
            .sampled_texture_type = .{
                .kind = switch (token_tag) {
                    .k_texture_sampled_1d => .@"1d",
                    .k_texture_sampled_2d => .@"2d",
                    .k_texture_sampled_2d_array => .@"2d_array",
                    .k_texture_sampled_3d => .@"3d",
                    .k_texture_sampled_cube => .cube,
                    .k_texture_sampled_cube_array => .cube_array,
                    else => unreachable,
                },
                .component_type = component_type_ref,
            },
        },
    };
    return IR.Inst.toRef(inst);
}

pub fn genMultigenSampledTextureType(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .multisampled_texture_type);

    const inst = try self.reserveInst();
    const component_type_node = self.tree.nodeLHS(node);
    const component_type_ref = try self.genType(scope, component_type_node);

    switch (component_type_ref) {
        .i32_type,
        .u32_type,
        .f32_type,
        => {},
        .bool_type,
        .f16_type,
        .sampler_type,
        .comparison_sampler_type,
        .external_sampled_texture_type,
        => {
            try self.errors.add(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid multisampled texture component type",
                .{},
                try self.errors.createNote(
                    null,
                    "must be 'i32', 'u32' or 'f32'",
                    .{},
                ),
            );
            return error.AnalysisFail;
        },
        .none, .true_literal, .false_literal => unreachable,
        _ => switch (self.instructions.items[component_type_ref.toIndex().?].tag) {
            .vector_type,
            .matrix_type,
            .atomic_type,
            .array_type,
            .ptr_type,
            .sampled_texture_type,
            .multisampled_texture_type,
            .storage_texture_type,
            .depth_texture_type,
            .struct_decl,
            => {
                try self.errors.add(
                    self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                    "invalid multisampled texture component type",
                    .{},
                    try self.errors.createNote(
                        null,
                        "must be 'i32', 'u32' or 'f32'",
                        .{},
                    ),
                );
                return error.AnalysisFail;
            },
            else => unreachable,
        },
    }

    const token_tag = self.tree.tokenTag(self.tree.nodeToken(node));
    self.instructions.items[inst] = .{
        .tag = .multisampled_texture_type,
        .data = .{
            .multisampled_texture_type = .{
                .kind = switch (token_tag) {
                    .k_texture_multisampled_2d => .@"2d",
                    else => unreachable,
                },
                .component_type = component_type_ref,
            },
        },
    };

    return IR.Inst.toRef(inst);
}

pub fn genStorageTextureType(self: *AstGen, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .storage_texture_type);

    const texel_format_loc = self.tree.tokenLoc(self.tree.nodeLHS(node));
    const ast_texel_format = std.meta.stringToEnum(Ast.TexelFormat, texel_format_loc.slice(self.tree.source)).?;
    const texel_format: IR.Inst.StorageTextureType.TexelFormat = switch (ast_texel_format) {
        .rgba8unorm => .rgba8unorm,
        .rgba8snorm => .rgba8snorm,
        .rgba8uint => .rgba8uint,
        .rgba8sint => .rgba8sint,
        .rgba16uint => .rgba16uint,
        .rgba16sint => .rgba16sint,
        .rgba16float => .rgba16float,
        .r32uint => .r32uint,
        .r32sint => .r32sint,
        .r32float => .r32float,
        .rg32uint => .rg32uint,
        .rg32sint => .rg32sint,
        .rg32float => .rg32float,
        .rgba32uint => .rgba32uint,
        .rgba32sint => .rgba32sint,
        .rgba32float => .rgba32float,
        .bgra8unorm => .bgra8unorm,
    };

    const access_mode_loc = self.tree.tokenLoc(self.tree.nodeRHS(node));
    const access_mode_full = std.meta.stringToEnum(Ast.AccessMode, access_mode_loc.slice(self.tree.source)).?;
    const access_mode = switch (access_mode_full) {
        .write => IR.Inst.StorageTextureType.AccessMode.write,
        else => {
            try self.errors.add(
                access_mode_loc,
                "invalid access mode",
                .{},
                try self.errors.createNote(
                    null,
                    "only 'write' is allowed",
                    .{},
                ),
            );
            return error.AnalysisFail;
        },
    };

    const token_tag = self.tree.tokenTag(self.tree.nodeToken(node));
    const inst = try self.addInst(.{
        .tag = .storage_texture_type,
        .data = .{
            .storage_texture_type = .{
                .kind = switch (token_tag) {
                    .k_texture_storage_1d => .@"1d",
                    .k_texture_storage_2d => .@"2d",
                    .k_texture_storage_2d_array => .@"2d_array",
                    .k_texture_storage_3d => .@"3d",
                    else => unreachable,
                },
                .texel_format = texel_format,
                .access_mode = access_mode,
            },
        },
    });

    return IR.Inst.toRef(inst);
}

pub fn genDepthTextureType(self: *AstGen, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .depth_texture_type);

    const token_tag = self.tree.tokenTag(self.tree.nodeToken(node));
    const inst = try self.addInst(.{
        .tag = .depth_texture_type,
        .data = .{
            .depth_texture_type = switch (token_tag) {
                .k_texture_depth_2d => .@"2d",
                .k_texture_depth_2d_array => .@"2d_array",
                .k_texture_depth_cube => .cube,
                .k_texture_depth_cube_array => .cube_array,
                .k_texture_depth_multisampled_2d => .multisampled_2d,
                else => unreachable,
            },
        },
    });
    return IR.Inst.toRef(inst);
}

pub fn genExternalTextureType(self: *AstGen, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .external_texture_type);
    return .external_sampled_texture_type;
}

pub fn genBoolType(self: *AstGen, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .bool_type);
    return .bool_type;
}

pub fn genNumberType(self: *AstGen, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .number_type);

    const token = self.tree.nodeToken(node);
    const token_tag = self.tree.tokenTag(token);
    return switch (token_tag) {
        .k_i32 => .i32_type,
        .k_u32 => .u32_type,
        .k_f32 => .f32_type,
        .k_f16 => .f16_type,
        else => unreachable,
    };
}

pub fn genSamplerType(self: *AstGen, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .sampler_type);

    const token = self.tree.nodeToken(node);
    const token_tag = self.tree.tokenTag(token);
    return switch (token_tag) {
        .k_sampler => .sampler_type,
        .k_comparison_sampler => .comparison_sampler_type,
        else => unreachable,
    };
}

pub fn genVectorType(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .vector_type);

    const inst = try self.reserveInst();
    const component_type_node = self.tree.nodeLHS(node);
    const component_type_ref = try self.genType(scope, component_type_node);

    switch (component_type_ref) {
        .bool_type, .i32_type, .u32_type, .f32_type, .f16_type => {},
        .sampler_type, .comparison_sampler_type, .external_sampled_texture_type => {
            try self.errors.add(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid vector component type",
                .{},
                try self.errors.createNote(
                    null,
                    "must be 'i32', 'u32', 'f32', 'f16' or 'bool'",
                    .{},
                ),
            );
            return error.AnalysisFail;
        },
        .none, .true_literal, .false_literal => unreachable,
        _ => switch (self.instructions.items[component_type_ref.toIndex().?].tag) {
            .vector_type,
            .matrix_type,
            .atomic_type,
            .array_type,
            .ptr_type,
            .sampled_texture_type,
            .multisampled_texture_type,
            .storage_texture_type,
            .depth_texture_type,
            .struct_decl,
            => {
                try self.errors.add(
                    self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                    "invalid vector component type",
                    .{},
                    try self.errors.createNote(
                        null,
                        "must be 'i32', 'u32', 'f32', 'f16' or 'bool'",
                        .{},
                    ),
                );
                return error.AnalysisFail;
            },
            else => unreachable,
        },
    }

    const token_tag = self.tree.tokenTag(self.tree.nodeToken(node));
    self.instructions.items[inst] = .{
        .tag = .vector_type,
        .data = .{
            .vector_type = .{
                .size = switch (token_tag) {
                    .k_vec2 => .two,
                    .k_vec3 => .three,
                    .k_vec4 => .four,
                    else => unreachable,
                },
                .component_type = component_type_ref,
            },
        },
    };

    return IR.Inst.toRef(inst);
}

pub fn genMatrixType(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .matrix_type);

    const inst = try self.reserveInst();
    const component_type_node = self.tree.nodeLHS(node);
    const component_type_ref = try self.genType(scope, component_type_node);

    switch (component_type_ref) {
        .f32_type,
        .f16_type,
        => {},
        .bool_type,
        .i32_type,
        .u32_type,
        .sampler_type,
        .comparison_sampler_type,
        .external_sampled_texture_type,
        => {
            try self.errors.add(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid matrix component type",
                .{},
                try self.errors.createNote(
                    null,
                    "must be 'f32' or 'f16'",
                    .{},
                ),
            );
            return error.AnalysisFail;
        },
        .none, .true_literal, .false_literal => unreachable,
        _ => switch (self.instructions.items[component_type_ref.toIndex().?].tag) {
            .vector_type,
            .matrix_type,
            .atomic_type,
            .array_type,
            .ptr_type,
            .sampled_texture_type,
            .multisampled_texture_type,
            .storage_texture_type,
            .depth_texture_type,
            .struct_decl,
            => {
                try self.errors.add(
                    self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                    "invalid matrix component type",
                    .{},
                    try self.errors.createNote(
                        null,
                        "must be 'f32' or 'f16'",
                        .{},
                    ),
                );
                return error.AnalysisFail;
            },
            else => unreachable,
        },
    }

    const token_tag = self.tree.tokenTag(self.tree.nodeToken(node));
    self.instructions.items[inst] = .{
        .tag = .matrix_type,
        .data = .{
            .matrix_type = .{
                .cols = switch (token_tag) {
                    .k_mat2x2, .k_mat2x3, .k_mat2x4 => .two,
                    .k_mat3x2, .k_mat3x3, .k_mat3x4 => .three,
                    .k_mat4x2, .k_mat4x3, .k_mat4x4 => .four,
                    else => unreachable,
                },
                .rows = switch (token_tag) {
                    .k_mat2x2, .k_mat3x2, .k_mat4x2 => .two,
                    .k_mat2x3, .k_mat3x3, .k_mat4x3 => .three,
                    .k_mat2x4, .k_mat3x4, .k_mat4x4 => .four,
                    else => unreachable,
                },
                .component_type = component_type_ref,
            },
        },
    };

    return IR.Inst.toRef(inst);
}

pub fn genAtomicType(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .atomic_type);

    const inst = try self.reserveInst();
    const component_type_node = self.tree.nodeLHS(node);
    const component_type_ref = try self.genType(scope, component_type_node);

    switch (component_type_ref) {
        .i32_type,
        .u32_type,
        => {},
        .bool_type,
        .f32_type,
        .f16_type,
        .sampler_type,
        .comparison_sampler_type,
        .external_sampled_texture_type,
        => {
            try self.errors.add(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid atomic component type",
                .{},
                try self.errors.createNote(
                    null,
                    "must be 'i32' or 'u32'",
                    .{},
                ),
            );
            return error.AnalysisFail;
        },
        .none, .true_literal, .false_literal => unreachable,
        _ => switch (self.instructions.items[component_type_ref.toIndex().?].tag) {
            .vector_type,
            .matrix_type,
            .atomic_type,
            .array_type,
            .ptr_type,
            .sampled_texture_type,
            .multisampled_texture_type,
            .storage_texture_type,
            .depth_texture_type,
            .struct_decl,
            => {
                try self.errors.add(
                    self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                    "invalid atomic component type",
                    .{},
                    try self.errors.createNote(
                        null,
                        "must be 'i32' or 'u32'",
                        .{},
                    ),
                );
                return error.AnalysisFail;
            },
            else => unreachable,
        },
    }

    self.instructions.items[inst] = .{
        .tag = .atomic_type,
        .data = .{ .atomic_type = .{ .component_type = component_type_ref } },
    };

    return IR.Inst.toRef(inst);
}

pub fn genArrayType(self: *AstGen, scope: *Scope, node: Ast.Index) !IR.Inst.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .array_type);

    const inst = try self.reserveInst();
    const component_type_node = self.tree.nodeLHS(node);
    const component_type_ref = try self.genType(scope, component_type_node);

    switch (component_type_ref) {
        .bool_type,
        .i32_type,
        .u32_type,
        .f32_type,
        .f16_type,
        => {},
        .sampler_type,
        .comparison_sampler_type,
        .external_sampled_texture_type,
        => {
            try self.errors.add(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid array component type",
                .{},
                null,
            );
            return error.AnalysisFail;
        },
        .none, .true_literal, .false_literal => unreachable,
        _ => switch (self.instructions.items[component_type_ref.toIndex().?].tag) {
            .vector_type,
            .matrix_type,
            .atomic_type,
            .struct_decl,
            => {},
            .array_type => {
                if (self.instructions.items[component_type_ref.toIndex().?].data.array_type.size == .none) {
                    try self.errors.add(
                        self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                        "array componet type can not be a runtime-sized array",
                        .{},
                        null,
                    );
                    return error.AnalysisFail;
                }
            },
            .ptr_type,
            .sampled_texture_type,
            .multisampled_texture_type,
            .storage_texture_type,
            .depth_texture_type,
            => {
                try self.errors.add(
                    self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                    "invalid array component type",
                    .{},
                    null,
                );
                return error.AnalysisFail;
            },
            else => unreachable,
        },
    }

    const size_node = self.tree.nodeRHS(node);
    var size_ref = IR.Inst.Ref.none;
    if (size_node != Ast.null_index) {
        // TODO
    }

    self.instructions.items[inst] = .{
        .tag = .array_type,
        .data = .{
            .array_type = .{
                .component_type = component_type_ref,
                .size = size_ref,
            },
        },
    };

    return IR.Inst.toRef(inst);
}

pub fn declNameLoc(self: *AstGen, node: Ast.Index) ?Token.Loc {
    const token = switch (self.tree.nodeTag(node)) {
        .global_variable => self.tree.extraData(Ast.Node.GlobalVarDecl, self.tree.nodeLHS(node)).name,
        .struct_decl,
        .fn_decl,
        .global_constant,
        .override,
        .type_alias,
        => self.tree.nodeToken(node) + 1,
        .struct_member => self.tree.nodeToken(node),
        else => return null,
    };
    return self.tree.tokenLoc(token);
}
