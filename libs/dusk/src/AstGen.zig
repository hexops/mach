const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("Token.zig");
const IR = @import("IR.zig");
const ErrorMsg = @import("main.zig").ErrorMsg;
const AstGen = @This();

allocator: std.mem.Allocator,
tree: *const Ast,
strings: std.ArrayListUnmanaged(u8) = .{},
instructions: std.ArrayListUnmanaged(IR.Inst) = .{},
refs: std.ArrayListUnmanaged(IR.Ref) = .{},
scratch: std.ArrayListUnmanaged(IR.Ref) = .{},
errors: std.ArrayListUnmanaged(ErrorMsg) = .{},
scope_pool: std.heap.MemoryPool(Scope),

pub const Scope = union(enum) {
    root: Root,
    func: Function,
    block: Block,

    pub const Root = struct {
        decls: std.StringHashMapUnmanaged(?IR.Ref) = .{},
    };

    /// parent is always Root
    pub const Function = struct {
        parent: *Scope,
        decls: std.StringHashMapUnmanaged(?IR.Ref) = .{},
    };

    pub const Block = struct {
        parent: *Scope,
        decls: std.StringHashMapUnmanaged(?IR.Ref) = .{},
    };

    pub fn parent(self: *Scope) ?*Scope {
        return switch (self.*) {
            .root => null,
            inline .func, .block => |*r| r.parent,
        };
    }

    pub fn decls(self: *Scope) *std.StringHashMapUnmanaged(?IR.Ref) {
        return switch (self.*) {
            inline else => |*r| &r.decls,
        };
    }
};

pub fn deinit(self: *AstGen) void {
    self.instructions.deinit(self.allocator);
    self.refs.deinit(self.allocator);
    self.strings.deinit(self.allocator);
    self.scratch.deinit(self.allocator);
    self.scope_pool.deinit();
    for (self.errors.items) |*err_msg| err_msg.deinit(self.allocator);
    self.errors.deinit(self.allocator);
}

pub fn translationUnit(self: *AstGen) !bool {
    const global_decls = self.tree.spanToList(0);

    const scratch_top = self.scratch.items.len;
    defer self.scratch.shrinkRetainingCapacity(scratch_top);

    var root_scope = try self.scope_pool.create();
    root_scope.* = .{ .root = .{} };
    try self.scanDecls(root_scope, global_decls);

    for (global_decls) |node| {
        const global = try self.globalDecl(root_scope, node) orelse continue;
        try self.scratch.append(self.allocator, global);
    }

    if (self.errors.items.len > 0) {
        return false;
    }

    _ = try self.addList(self.scratch.items[scratch_top..]);

    return true;
}

pub fn scanDecls(self: *AstGen, scope: *Scope, decls: []const Ast.Index) !void {
    std.debug.assert(scope.decls().count() == 0);
    for (decls) |decl| {
        const loc = self.declNameLoc(decl).?;
        const name = loc.slice(self.tree.source);

        // TODO
        // if (Token.isReserved(name)) {
        //     try self.addError(
        //         loc,
        //         "the name '{s}' has ben reserved",
        //         .{name},
        //         null,
        //     );
        // }

        const gop = try scope.decls().getOrPut(self.scope_pool.arena.allocator(), name);
        if (gop.found_existing) {
            try self.addError(
                loc,
                "redeclaration of '{s}'",
                .{name},
                null,
            );
            return; // TODO?
        }
        gop.value_ptr.* = null;
    }
}

pub fn globalDecl(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const decl = switch (self.tree.nodeTag(node)) {
        .global_variable => try self.globalVariable(scope, node),
        .type_alias => try self.typeAlias(scope, node), // TODO: this returns a type not a real decl
        .struct_decl => try self.structDecl(scope, node),
        else => return null,
    };

    const gop = scope.decls().getOrPutAssumeCapacity(self.declNameLoc(node).?.slice(self.tree.source));
    std.debug.assert(gop.found_existing);
    gop.value_ptr.* = decl orelse IR.null_ref;

    return decl;
}

pub fn typeAlias(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    return self.allTypes(scope, self.tree.nodeLHS(node));
}

pub fn globalVariable(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const gv = self.tree.extraData(Ast.Node.GlobalVarDecl, self.tree.nodeLHS(node));
    // for (self.tree.spanToList(gv.attrs), 0..) |attr_node, i| {
    // const attr = switch (self.tree.nodeTag(attr_node)) {
    //     .attr => {},
    // };
    // }
    var var_type = IR.null_ref;
    if (gv.type != Ast.null_index) {
        var_type = try self.allTypes(scope, gv.type) orelse return null;
    }

    var addr_space: Ast.AddressSpace = .none;
    if (gv.access_mode != Ast.null_index) {
        const addr_space_loc = self.tree.tokenLoc(gv.addr_space);
        addr_space = std.meta.stringToEnum(Ast.AddressSpace, addr_space_loc.slice(self.tree.source)).?;
    }

    var access_mode: Ast.AccessMode = .none;
    if (gv.access_mode != Ast.null_index) {
        const access_mode_loc = self.tree.tokenLoc(gv.access_mode);
        access_mode = std.meta.stringToEnum(Ast.AccessMode, access_mode_loc.slice(self.tree.source)).?;
    }

    const name_index = try self.addString(self.declNameLoc(node).?.slice(self.tree.source));
    return try self.addInst(.global_variable, .{
        .global_variable = .{
            .name = name_index,
            .type = var_type,
            .addr_space = addr_space,
            .access_mode = access_mode,
            .attrs = 0, // TODO
        },
    });
}

pub fn structDecl(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const scratch_top = self.scratch.items.len;
    defer self.scratch.shrinkRetainingCapacity(scratch_top);

    const member_list = self.tree.spanToList(self.tree.nodeLHS(node));
    for (member_list, 0..) |member_node, i| {
        const member_loc = self.tree.tokenLoc(self.tree.nodeToken(member_node));
        const member_type_node = self.tree.nodeRHS(member_node);
        const member_type_name = self.tree.tokenLoc(self.tree.nodeToken(member_type_node));
        const member_type_ref = try self.allTypes(scope, member_type_node) orelse continue;

        switch (self.instructions.items[member_type_ref].tag) {
            .bool_type,
            .i32_type,
            .u32_type,
            .f32_type,
            .f16_type,
            .vector_type,
            .matrix_type,
            .atomic_type,
            .struct_decl,
            => {},
            .array_type => {
                if (self.instructions.items[member_type_ref].data.array_type.size == IR.null_ref and i + 1 != member_list.len) {
                    try self.addError(
                        member_loc,
                        "struct member with runtime-sized array type, must be the last member of the structure",
                        .{},
                        null,
                    );
                    continue;
                }
            },
            .ptr_type,
            .sampler_type,
            .comparison_sampler_type,
            .sampled_texture_type,
            .multisampled_texture_type,
            .storage_texture_type,
            .depth_texture_type,
            .external_sampled_texture_type,
            => {
                try self.addError(
                    member_loc,
                    "invalid struct member type '{s}'",
                    .{member_type_name.slice(self.tree.source)},
                    null,
                );
                continue;
            },
            else => unreachable,
        }

        const name_index = try self.addString(member_loc.slice(self.tree.source));
        const member_inst = try self.addInst(.struct_member, .{
            .struct_member = .{
                .name = name_index,
                .type = member_type_ref,
                .@"align" = 0, // TODO
            },
        });
        try self.scratch.append(self.allocator, member_inst);
    }

    const name = self.declNameLoc(node).?.slice(self.tree.source);
    const name_index = try self.addString(name);
    const list = try self.addList(self.scratch.items[scratch_top..]);
    const inst = try self.addInst(.struct_decl, .{
        .struct_decl = .{
            .name = name_index,
            .members = list,
        },
    });

    return inst;
}

pub fn addString(self: *AstGen, str: []const u8) error{OutOfMemory}!u32 {
    const len = str.len + 1;
    try self.strings.ensureUnusedCapacity(self.allocator, len);
    self.strings.appendSliceAssumeCapacity(str);
    self.strings.appendAssumeCapacity('\x00');
    return @intCast(u32, self.strings.items.len - len);
}

pub fn addList(self: *AstGen, list: []const IR.Ref) error{OutOfMemory}!u32 {
    const len = list.len + 1;
    try self.refs.ensureUnusedCapacity(self.allocator, len);
    self.refs.appendAssumeCapacity(@intCast(u32, list.len));
    self.refs.appendSliceAssumeCapacity(list);
    return @intCast(u32, self.refs.items.len - list.len);
}

pub fn addInst(self: *AstGen, tag: IR.Inst.Tag, data: IR.Inst.Data) error{OutOfMemory}!IR.Ref {
    try self.instructions.append(self.allocator, .{ .tag = tag, .data = data });
    return @intCast(u32, self.instructions.items.len - 1);
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
// //                 try self.addError(
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
// //         try self.addError(
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

pub fn allTypes(self: *AstGen, scope: *Scope, node: Ast.Index) error{OutOfMemory}!?IR.Ref {
    return switch (self.tree.nodeTag(node)) {
        .bool_type => try self.boolType(node),
        .number_type => try self.numberType(node),
        .vector_type => try self.vectorType(scope, node) orelse return null,
        .matrix_type => try self.matrixType(scope, node) orelse return null,
        .atomic_type => try self.atomicType(scope, node) orelse return null,
        .array_type => try self.arrayType(scope, node) orelse return null,
        .user_type => {
            const node_loc = self.tree.tokenLoc(self.tree.nodeToken(node));
            const decl = try self.declRef(scope, node_loc) orelse return null;
            switch (self.instructions.items[decl].tag) {
                .bool_type,
                .i32_type,
                .u32_type,
                .f32_type,
                .f16_type,
                .vector_type,
                .matrix_type,
                .atomic_type,
                .array_type,
                .ptr_type,
                .sampler_type,
                .comparison_sampler_type,
                .sampled_texture_type,
                .multisampled_texture_type,
                .storage_texture_type,
                .depth_texture_type,
                .external_sampled_texture_type,
                .struct_decl,
                => return decl,
                .global_variable => {
                    try self.addError(
                        node_loc,
                        "'{s}' is not a type",
                        .{node_loc.slice(self.tree.source)},
                        null,
                    );
                    return null;
                },
                else => unreachable,
            }
        },
        .sampler_type => try self.samplerType(node),
        .sampled_texture_type => try self.sampledTextureType(scope, node) orelse return null,
        .multisampled_texture_type => try self.multisampledTextureType(scope, node) orelse return null,
        .storage_texture_type => try self.storageTextureType(node) orelse return null,
        .depth_texture_type => try self.depthTextureType(node) orelse return null,
        .external_texture_type => try self.externalTextureType(node),
        else => unreachable,
    };
}

pub fn sampledTextureType(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const component_type_node = self.tree.nodeLHS(node);
    const component_type = try self.allTypes(scope, component_type_node) orelse return null;
    switch (self.instructions.items[component_type].tag) {
        .i32_type,
        .u32_type,
        .f32_type,
        => {},
        .bool_type,
        .f16_type,
        .vector_type,
        .matrix_type,
        .atomic_type,
        .array_type,
        .ptr_type,
        .sampler_type,
        .comparison_sampler_type,
        .sampled_texture_type,
        .multisampled_texture_type,
        .storage_texture_type,
        .depth_texture_type,
        .external_sampled_texture_type,
        .struct_decl,
        => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid sampled texture component type",
                .{},
                try ErrorMsg.Note.create(
                    self.allocator,
                    null,
                    "must be 'i32', 'u32' or 'f32'",
                    .{},
                ),
            );
            return null;
        },
        else => unreachable,
    }

    const tag = self.tree.tokenTag(self.tree.nodeToken(node));
    return try self.addInst(
        .sampled_texture_type,
        .{
            .sampled_texture_type = .{
                .kind = switch (tag) {
                    .k_texture_sampled_1d => .@"1d",
                    .k_texture_sampled_2d => .@"2d",
                    .k_texture_sampled_2d_array => .@"2d_array",
                    .k_texture_sampled_3d => .@"3d",
                    .k_texture_sampled_cube => .cube,
                    .k_texture_sampled_cube_array => .cube_array,
                    else => unreachable,
                },
                .component_type = component_type,
            },
        },
    );
}

pub fn multisampledTextureType(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const component_type_node = self.tree.nodeLHS(node);
    const component_type = try self.allTypes(scope, component_type_node) orelse return null;
    switch (self.instructions.items[component_type].tag) {
        .i32_type,
        .u32_type,
        .f32_type,
        => {},
        .bool_type,
        .f16_type,
        .vector_type,
        .matrix_type,
        .atomic_type,
        .array_type,
        .ptr_type,
        .sampler_type,
        .comparison_sampler_type,
        .sampled_texture_type,
        .multisampled_texture_type,
        .storage_texture_type,
        .depth_texture_type,
        .external_sampled_texture_type,
        .struct_decl,
        => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid multisampled texture component type",
                .{},
                try ErrorMsg.Note.create(
                    self.allocator,
                    null,
                    "must be 'i32', 'u32' or 'f32'",
                    .{},
                ),
            );
            return null;
        },
        else => unreachable,
    }

    const tag = self.tree.tokenTag(self.tree.nodeToken(node));
    return try self.addInst(
        .multisampled_texture_type,
        .{
            .multisampled_texture_type = .{
                .kind = switch (tag) {
                    .k_texture_multisampled_2d => .@"2d",
                    else => unreachable,
                },
                .component_type = component_type,
            },
        },
    );
}

pub fn storageTextureType(self: *AstGen, node: Ast.Index) !?IR.Ref {
    const texel_format_loc = self.tree.tokenLoc(self.tree.nodeLHS(node));
    const texel_format = std.meta.stringToEnum(Ast.TexelFormat, texel_format_loc.slice(self.tree.source)).?;

    const access_mode_loc = self.tree.tokenLoc(self.tree.nodeRHS(node));
    const access_mode_full = std.meta.stringToEnum(Ast.AccessMode, access_mode_loc.slice(self.tree.source)).?;
    const access_mode: IR.Inst.Data.MultisampledTextureTypeKind = switch (access_mode_full) {
        .write => .write,
        else => {
            try self.addError(
                access_mode_loc,
                "invalid access mode",
                .{},
                try ErrorMsg.Note.create(self.allocator, null, "only 'write' is allowed", .{}),
            );
            return null;
        },
    };

    const tag = self.tree.tokenTag(self.tree.nodeToken(node));
    return try self.addInst(
        .storage_texture_type,
        .{
            .storage_texture_type = .{
                .kind = switch (tag) {
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
    );
}

pub fn depthTextureType(self: *AstGen, node: Ast.Index) !?IR.Ref {
    const tag = self.tree.tokenTag(self.tree.nodeToken(node));
    return try self.addInst(
        .depth_texture_type,
        .{
            .depth_texture_type = switch (tag) {
                .k_texture_depth_2d => .@"2d",
                .k_texture_depth_2d_array => .@"2d_array",
                .k_texture_depth_cube => .cube,
                .k_texture_depth_cube_array => .cube_array,
                .k_texture_depth_multisampled_2d => .multisampled_2d,
                else => unreachable,
            },
        },
    );
}

pub fn externalTextureType(self: *AstGen, node: Ast.Index) !?IR.Ref {
    std.debug.assert(self.tree.nodeTag(node) == .external_texture_type);
    return try self.addInst(.external_sampled_texture_type, .{ .none = 0 });
}

pub fn boolType(self: *AstGen, node: Ast.Index) !IR.Ref {
    const inst_tag: IR.Inst.Tag = switch (self.tree.nodeTag(node)) {
        .bool_type => .bool_type,
        else => unreachable,
    };
    return try self.addInst(inst_tag, .{ .none = 0 });
}

pub fn numberType(self: *AstGen, node: Ast.Index) !IR.Ref {
    const token = self.tree.nodeToken(node);
    const token_tag = self.tree.tokenTag(token);
    const inst_tag: IR.Inst.Tag = switch (token_tag) {
        .k_i32 => .i32_type,
        .k_u32 => .u32_type,
        .k_f32 => .f32_type,
        .k_f16 => .f16_type,
        else => unreachable,
    };
    return try self.addInst(inst_tag, .{ .none = 0 });
}

pub fn samplerType(self: *AstGen, node: Ast.Index) !IR.Ref {
    const token = self.tree.nodeToken(node);
    const token_tag = self.tree.tokenTag(token);
    const inst_tag: IR.Inst.Tag = switch (token_tag) {
        .k_sampler => .sampler_type,
        .k_comparison_sampler => .comparison_sampler_type,
        else => unreachable,
    };
    return try self.addInst(inst_tag, .{ .none = 0 });
}

pub fn vectorType(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const component_type_node = self.tree.nodeLHS(node);
    const component_type = try self.allTypes(scope, component_type_node) orelse return null;
    switch (self.instructions.items[component_type].tag) {
        .bool_type,
        .i32_type,
        .u32_type,
        .f32_type,
        .f16_type,
        => {},
        .vector_type,
        .matrix_type,
        .atomic_type,
        .array_type,
        .ptr_type,
        .sampler_type,
        .comparison_sampler_type,
        .sampled_texture_type,
        .multisampled_texture_type,
        .storage_texture_type,
        .depth_texture_type,
        .external_sampled_texture_type,
        .struct_decl,
        => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid vector component type",
                .{},
                try ErrorMsg.Note.create(
                    self.allocator,
                    null,
                    "must be 'i32', 'u32', 'f32', 'f16' or 'bool'",
                    .{},
                ),
            );
            return null;
        },
        else => unreachable,
    }

    const token_tag = self.tree.tokenTag(self.tree.nodeToken(node));
    return try self.addInst(
        .vector_type,
        .{
            .vector_type = .{
                .size = switch (token_tag) {
                    .k_vec2 => .two,
                    .k_vec3 => .three,
                    .k_vec4 => .four,
                    else => unreachable,
                },
                .component_type = component_type,
            },
        },
    );
}

pub fn matrixType(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const component_type_node = self.tree.nodeLHS(node);
    const component_type = try self.allTypes(scope, component_type_node) orelse return null;
    switch (self.instructions.items[component_type].tag) {
        .f32_type,
        .f16_type,
        => {},
        .bool_type,
        .i32_type,
        .u32_type,
        .vector_type,
        .matrix_type,
        .atomic_type,
        .array_type,
        .ptr_type,
        .sampler_type,
        .comparison_sampler_type,
        .sampled_texture_type,
        .multisampled_texture_type,
        .storage_texture_type,
        .depth_texture_type,
        .external_sampled_texture_type,
        .struct_decl,
        => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid matrix component type",
                .{},
                try ErrorMsg.Note.create(
                    self.allocator,
                    null,
                    "must be 'f32' or 'f16'",
                    .{},
                ),
            );
            return null;
        },
        else => unreachable,
    }

    const token_tag = self.tree.tokenTag(self.tree.nodeToken(node));
    return try self.addInst(
        .matrix_type,
        .{
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
                .component_type = component_type,
            },
        },
    );
}

pub fn atomicType(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const component_type_node = self.tree.nodeLHS(node);
    const component_type = try self.allTypes(scope, component_type_node) orelse return null;
    switch (self.instructions.items[component_type].tag) {
        .i32_type,
        .u32_type,
        => {},
        .bool_type,
        .f32_type,
        .f16_type,
        .vector_type,
        .matrix_type,
        .atomic_type,
        .array_type,
        .ptr_type,
        .sampler_type,
        .comparison_sampler_type,
        .sampled_texture_type,
        .multisampled_texture_type,
        .storage_texture_type,
        .depth_texture_type,
        .external_sampled_texture_type,
        .struct_decl,
        => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid atomic component type",
                .{},
                try ErrorMsg.Note.create(
                    self.allocator,
                    null,
                    "must be 'i32' or 'u32'",
                    .{},
                ),
            );
            return null;
        },
        else => unreachable,
    }

    return try self.addInst(.atomic_type, .{ .atomic_type = .{ .component_type = component_type } });
}

pub fn arrayType(self: *AstGen, scope: *Scope, node: Ast.Index) !?IR.Ref {
    const component_type_node = self.tree.nodeLHS(node);
    const component_type = try self.allTypes(scope, component_type_node) orelse return null;
    switch (self.instructions.items[component_type].tag) {
        .bool_type,
        .i32_type,
        .u32_type,
        .f32_type,
        .f16_type,
        .vector_type,
        .matrix_type,
        .atomic_type,
        .struct_decl,
        => {},
        .array_type => {
            if (self.instructions.items[component_type].data.array_type.size == IR.null_ref) {
                try self.addError(
                    self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                    "array componet type can not be a runtime-sized array",
                    .{},
                    null,
                );
                return null;
            }
        },
        .ptr_type,
        .sampler_type,
        .comparison_sampler_type,
        .sampled_texture_type,
        .multisampled_texture_type,
        .storage_texture_type,
        .depth_texture_type,
        .external_sampled_texture_type,
        => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                "invalid array component type",
                .{},
                null,
            );
            return null;
        },
        else => unreachable,
    }

    const size_node = self.tree.nodeRHS(node);
    var size_ref = IR.null_ref;
    if (size_node != Ast.null_index) {
        // TODO
    }

    return try self.addInst(
        .array_type,
        .{
            .array_type = .{
                .component_type = component_type,
                .size = size_ref,
            },
        },
    );
}

pub fn declRef(self: *AstGen, scope: *Scope, loc: Token.Loc) !?IR.Ref {
    const name = loc.slice(self.tree.source);
    var s = scope;
    while (true) {
        const decl = scope.decls().get(name) orelse {
            s = s.parent() orelse break;
            continue;
        } orelse return null;
        if (decl == IR.null_ref) {
            break;
        }
        return decl;
    }
    try self.addError(
        loc,
        "use of undeclared identifier '{s}'",
        .{name},
        null,
    );
    return null;
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

pub fn addError(
    self: *AstGen,
    loc: Token.Loc,
    comptime format: []const u8,
    args: anytype,
    note: ?ErrorMsg.Note,
) !void {
    const err_msg = try ErrorMsg.create(self.allocator, loc, format, args, note);
    try self.errors.append(self.allocator, err_msg);
}
