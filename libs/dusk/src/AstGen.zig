const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("Token.zig");
const IR = @import("IR.zig");
const ErrorMsg = @import("main.zig").ErrorMsg;
const AstGen = @This();

arena: std.mem.Allocator,
allocator: std.mem.Allocator,
tree: *const Ast,
errors: std.ArrayListUnmanaged(ErrorMsg),
scope: Scope = .top,

pub const Scope = union(enum) {
    top,
    range: []const Ast.Index,
};

pub fn deinit(self: *AstGen) void {
    for (self.errors.items) |*err_msg| err_msg.deinit(self.allocator);
    self.errors.deinit(self.allocator);
}

pub fn translationUnit(self: *AstGen) !?IR.TranslationUnit {
    const global_decls = self.tree.spanToList(0);

    var list = std.ArrayList(IR.GlobalDecl).init(self.arena);
    defer list.deinit();

    for (global_decls, 0..) |node, i| {
        self.scope = .top;
        try self.checkRedeclaration(global_decls[i + 1 ..], node);
        const global = try self.globalDecl(node) orelse continue;
        try list.append(global);
    }

    if (self.errors.items.len > 0) {
        return null;
    }

    return try list.toOwnedSlice();
}

pub fn globalDecl(self: *AstGen, node: Ast.Index) !?IR.GlobalDecl {
    switch (self.tree.nodeTag(node)) {
        .global_variable => {}, // TODO
        .struct_decl => return .{ .@"struct" = try self.structDecl(node) orelse return null },
        else => std.debug.print("Global Decl TODO: {}\n", .{self.tree.nodeTag(node)}),
    }

    return null;
}

pub fn structDecl(self: *AstGen, node: Ast.Index) !?IR.StructDecl {
    var members_arr = std.ArrayList(IR.StructMember).init(self.arena);
    defer members_arr.deinit();

    const member_list = self.tree.spanToList(self.tree.nodeLHS(node));
    for (member_list, 0..) |member_node, i| {
        try self.checkRedeclaration(member_list[i + 1 ..], member_node);
        const member_loc = self.tree.tokenLoc(self.tree.nodeToken(member_node));
        const member_type_node = self.tree.nodeRHS(member_node);
        const member_type_token = self.tree.nodeToken(member_type_node);
        const member_type_loc = self.tree.tokenLoc(member_type_token);
        const member_type_name = member_type_loc.slice(self.tree.source);

        var inner_type = member_type_node;
        while (true) {
            switch (self.tree.nodeTag(inner_type)) {
                .bool_type => {
                    try members_arr.append(.{
                        .name = member_loc.slice(self.tree.source),
                        .type = .bool,
                    });
                },
                .number_type => {
                    try members_arr.append(.{
                        .name = member_loc.slice(self.tree.source),
                        .type = .{ .number = self.numberType(inner_type) },
                    });
                },
                .vector_type => {
                    try members_arr.append(.{
                        .name = member_loc.slice(self.tree.source),
                        .type = .{ .vector = try self.vectorType(inner_type) orelse break },
                    });
                },
                .matrix_type => {
                    try members_arr.append(.{
                        .name = member_loc.slice(self.tree.source),
                        .type = .{ .matrix = try self.matrixType(inner_type) orelse break },
                    });
                },
                .atomic_type => {
                    try members_arr.append(.{
                        .name = member_loc.slice(self.tree.source),
                        .type = .{ .atomic = try self.atomicType(inner_type) orelse break },
                    });
                },
                .array_type => {
                    const array_type = try self.arrayType(inner_type) orelse return null;

                    try members_arr.append(.{
                        .name = member_loc.slice(self.tree.source),
                        .type = .{ .array = array_type },
                    });

                    if (array_type.size == null and i + 1 != member_list.len) {
                        try self.addError(
                            member_loc,
                            "struct member with runtime-sized array type, must be the last member of the structure",
                            .{},
                            null,
                        );
                        return null;
                    }
                },
                .user_type => {
                    const decl_node = try self.expectFindDeclNode(member_type_loc, member_type_name) orelse break;
                    switch (self.tree.nodeTag(decl_node)) {
                        .type_alias => {
                            inner_type = self.tree.nodeLHS(decl_node);
                            continue;
                        },
                        .struct_decl => try members_arr.append(.{
                            .name = member_loc.slice(self.tree.source),
                            .type = .{ .@"struct" = try self.structType(member_type_node) orelse return null },
                        }),
                        else => {
                            try self.addError(
                                member_type_loc,
                                "'{s}' is neither an struct or type alias",
                                .{member_type_name},
                                null,
                            );
                        },
                    }
                },
                else => {
                    try self.addError(
                        member_loc,
                        "invalid struct member type '{s}'",
                        .{member_type_name},
                        null,
                    );
                },
            }

            break;
        }
    }

    const struct_name = self.declNameToken(node) orelse unreachable;
    return .{
        .name = self.tree.tokenLoc(struct_name).slice(self.tree.source),
        .members = try members_arr.toOwnedSlice(),
    };
}

pub fn numberType(self: *AstGen, node: Ast.Index) IR.NumberType {
    const token = self.tree.nodeToken(node);
    const token_tag = self.tree.tokenTag(token);
    return switch (token_tag) {
        .k_i32 => .i32,
        .k_u32 => .u32,
        .k_f32 => .f32,
        .k_f16 => .f16,
        else => unreachable,
    };
}

pub fn vectorType(self: *AstGen, node: Ast.Index) !?IR.VectorType {
    const token = self.tree.nodeToken(node);
    const token_tag = self.tree.tokenTag(token);
    const size: IR.VectorType.Size = switch (token_tag) {
        .k_vec2 => .vec2,
        .k_vec3 => .vec3,
        .k_vec4 => .vec4,
        else => unreachable,
    };
    const type_node = self.tree.nodeLHS(node);
    const component_type: IR.VectorType.Type = switch (self.tree.nodeTag(type_node)) {
        .bool_type => .bool,
        .number_type => .{ .number = self.numberType(type_node) },
        else => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(type_node)),
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
    };
    return .{ .size = size, .component_type = component_type };
}

pub fn matrixType(self: *AstGen, node: Ast.Index) !?IR.MatrixType {
    const token = self.tree.nodeToken(node);
    const token_tag = self.tree.tokenTag(token);
    const size: IR.MatrixType.Size = switch (token_tag) {
        .k_mat2x2 => .mat2x2,
        .k_mat2x3 => .mat2x3,
        .k_mat2x4 => .mat2x4,
        .k_mat3x2 => .mat3x2,
        .k_mat3x3 => .mat3x3,
        .k_mat3x4 => .mat3x4,
        .k_mat4x2 => .mat4x2,
        .k_mat4x3 => .mat4x3,
        .k_mat4x4 => .mat4x4,
        else => unreachable,
    };
    const type_node = self.tree.nodeLHS(node);
    const type_token = self.tree.nodeToken(type_node);
    const type_token_tag = self.tree.tokenTag(type_token);
    const component_type: IR.MatrixType.Type = switch (type_token_tag) {
        .k_f32 => .f32,
        .k_f16 => .f16,
        else => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(type_node)),
                "invalid matrix element type",
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
    };
    return .{ .size = size, .component_type = component_type };
}

pub fn atomicType(self: *AstGen, node: Ast.Index) !?IR.AtomicType {
    const type_node = self.tree.nodeLHS(node);
    const type_token = self.tree.nodeToken(type_node);
    const type_token_tag = self.tree.tokenTag(type_token);
    const component_type: IR.AtomicType.Type = switch (type_token_tag) {
        .k_i32 => .i32,
        .k_u32 => .u32,
        else => {
            try self.addError(
                self.tree.tokenLoc(self.tree.nodeToken(type_node)),
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
    };
    return .{ .component_type = component_type };
}

pub fn arrayType(self: *AstGen, node: Ast.Index) !?IR.ArrayType {
    var component_type_node = self.tree.nodeLHS(node);
    var component_type: IR.ArrayType.Type = undefined;
    while (true) {
        switch (self.tree.nodeTag(component_type_node)) {
            .bool_type => component_type = .bool,
            .number_type => component_type = .{ .number = self.numberType(component_type_node) },
            .vector_type => component_type = .{ .vector = try self.vectorType(component_type_node) orelse return null },
            .matrix_type => component_type = .{ .matrix = try self.matrixType(component_type_node) orelse return null },
            .atomic_type => component_type = .{ .atomic = try self.atomicType(component_type_node) orelse return null },
            .array_type => {
                var array_type = try self.arena.create(IR.ArrayType.Type);

                if (try self.arrayType(component_type_node)) |ty| {
                    if (ty.size != null) {
                        array_type.* = ty.component_type;
                        component_type = .{ .array = array_type };
                        break;
                    } else {
                        try self.addError(
                            self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                            "array componet type can not be a runtime-sized array",
                            .{},
                            null,
                        );
                    }
                }

                return null;
            },
            .user_type => {
                const component_type_loc = self.tree.tokenLoc(self.tree.nodeToken(component_type_node));
                const component_type_name = component_type_loc.slice(self.tree.source);
                const decl_node = try self.expectFindDeclNode(component_type_loc, component_type_name) orelse break;
                switch (self.tree.nodeTag(decl_node)) {
                    .type_alias => {
                        component_type_node = self.tree.nodeLHS(decl_node);
                        continue;
                    },
                    .struct_decl => component_type = .{ .@"struct" = try self.structType(component_type_node) orelse return null },
                    else => {
                        try self.addError(
                            component_type_loc,
                            "'{s}' is neither an struct or type alias",
                            .{component_type_name},
                            null,
                        );
                        return null;
                    },
                }
            },
            else => {
                try self.addError(
                    self.tree.tokenLoc(self.tree.nodeToken(component_type_node)),
                    "invalid array component type",
                    .{},
                    null,
                );
                return null;
            },
        }
        break;
    }

    const size_node = self.tree.nodeRHS(node);
    if (size_node == Ast.null_index) {
        return .{ .component_type = component_type };
    }

    return .{ .component_type = component_type, .size = undefined }; // TODO
}

pub fn structType(self: *AstGen, node: Ast.Index) !?[]const u8 {
    const ref_loc = self.tree.tokenLoc(self.tree.nodeToken(node));
    return ref_loc.slice(self.tree.source);
}

/// UNUSED
/// returns the actual type of a type alias
pub fn fetchTypeAliasType(self: *AstGen, node: Ast.Index) void {
    std.debug.assert(self.tree.nodeTag(node) == .type_alias);
    if (self.tree.nodeTag(node) == .type_alias) {
        return self.fetchTypeAliasType(self.tree.nodeLHS(node));
    }
    return self.tree.nodeLHS(node);
}

pub fn expectFindDeclNode(self: *AstGen, ref_loc: Token.Loc, name: []const u8) !?Ast.Index {
    return self.findDeclNode(name) orelse {
        try self.addError(
            ref_loc,
            "use of undeclared identifier '{s}'",
            .{name},
            null,
        );
        return null;
    };
}

pub fn findDeclNode(self: *AstGen, name: []const u8) ?Ast.Index {
    for (self.scopeToRange()) |node| {
        const node_token = self.declNameToken(node) orelse continue;
        if (std.mem.eql(u8, name, self.tree.tokenLoc(node_token).slice(self.tree.source))) {
            return node;
        }
    }
    return null;
}

pub fn checkRedeclaration(self: *AstGen, range: []const Ast.Index, decl_node: Ast.Index) !void {
    const decl_token_loc = self.tree.tokenLoc(self.declNameToken(decl_node).?);
    const decl_name = decl_token_loc.slice(self.tree.source);
    for (range) |redecl_node| {
        std.debug.assert(decl_node != redecl_node);
        const redecl_token_loc = self.tree.tokenLoc(self.declNameToken(redecl_node).?);
        const redecl_name = redecl_token_loc.slice(self.tree.source);
        if (std.mem.eql(u8, decl_name, redecl_name)) {
            try self.addError(
                redecl_token_loc,
                "redeclaration of '{s}'",
                .{decl_name},
                try ErrorMsg.Note.create(
                    self.allocator,
                    decl_token_loc,
                    "other declaration here",
                    .{},
                ),
            );
        }
    }
}

pub fn declNameToken(self: *AstGen, node: Ast.Index) ?Ast.Index {
    return switch (self.tree.nodeTag(node)) {
        .global_variable => self.tree.extraData(Ast.Node.GlobalVarDecl, self.tree.nodeLHS(node)).name,
        .struct_decl,
        .fn_decl,
        .global_constant,
        .override,
        .type_alias,
        => self.tree.nodeToken(node) + 1,
        .struct_member => self.tree.nodeToken(node),
        else => null,
    };
}

pub fn scopeToRange(self: AstGen) []const Ast.Index {
    return switch (self.scope) {
        .top => self.tree.spanToList(0),
        .range => |r| r,
    };
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
