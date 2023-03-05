const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("Token.zig");
const ErrorMsg = @import("main.zig").ErrorMsg;
const Analyse = @This();

allocator: std.mem.Allocator,
tree: *const Ast,
errors: std.ArrayListUnmanaged(ErrorMsg),

pub fn deinit(self: *Analyse) void {
    for (self.errors.items) |*err_msg| err_msg.deinit(self.allocator);
    self.errors.deinit(self.allocator);
}

pub fn analyseRoot(self: *Analyse) !void {
    const global_items = self.tree.spanToList(0);

    for (global_items, 0..) |node_i, i| {
        try self.checkRedeclaration(global_items[i + 1 ..], node_i);
        try self.globalDecl(global_items, node_i);
    }

    if (self.errors.items.len > 0) {
        return error.Analysing;
    }
}

pub fn globalDecl(self: *Analyse, parent_scope: []const Ast.Index, node_i: Ast.Index) !void {
    switch (self.tree.nodeTag(node_i)) {
        .global_variable => {}, // TODO
        .struct_decl => try self.structDecl(parent_scope, node_i),
        else => std.debug.print("Global Decl TODO: {}\n", .{self.tree.nodeTag(node_i)}),
    }
}

pub fn structDecl(self: *Analyse, parent_scope: []const Ast.Index, node: Ast.Index) !void {
    const member_list = self.tree.spanToList(self.tree.nodeLHS(node));
    for (member_list, 0..) |member_node, i| {
        try self.checkRedeclaration(member_list[i + 1 ..], member_node);

        const member_loc = self.tree.tokenLoc(self.tree.nodeToken(member_node));
        const member_name = member_loc.slice(self.tree.source);
        const member_type_node = self.tree.nodeRHS(member_node);

        switch (self.tree.nodeTag(member_type_node)) {
            .scalar_type,
            .vector_type,
            .matrix_type,
            .atomic_type,
            => {},
            .array_type => {
                if (self.tree.nodeRHS(member_type_node) == Ast.null_index and
                    i != member_list.len - 1)
                {
                    try self.addError(
                        member_loc,
                        "struct member with runtime-sized array type, must be the last member of the structure",
                        .{},
                        null,
                    );
                }
            },
            .user_type => {
                _ = self.findDeclNode(parent_scope, member_name) orelse {
                    try self.addError(
                        member_loc, // TODO
                        "use of undeclared identifier '{s}'",
                        .{member_name},
                        null,
                    );
                    continue;
                };
            },
            else => {
                try self.addError(
                    member_loc,
                    "invalid struct member type '{s}'",
                    .{member_name},
                    null,
                );
            },
        }
    }
}

pub fn findDeclNode(self: *Analyse, scope_items: []const Ast.Index, name: []const u8) ?Ast.Index {
    for (scope_items) |node| {
        const node_token = self.declNameToken(node) orelse continue;
        if (std.mem.eql(u8, name, self.tree.tokenLoc(node_token).slice(self.tree.source))) {
            return node;
        }
    }
    return null;
}

pub fn checkRedeclaration(self: *Analyse, scope_items: []const Ast.Index, decl_node: Ast.Index) !void {
    const decl_token_loc = self.tree.tokenLoc(self.declNameToken(decl_node).?);
    const decl_name = decl_token_loc.slice(self.tree.source);
    for (scope_items) |redecl_node| {
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

pub fn declNameToken(self: *Analyse, node: Ast.Index) ?Ast.Index {
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

pub fn addError(
    self: *Analyse,
    loc: Token.Loc,
    comptime format: []const u8,
    args: anytype,
    note: ?ErrorMsg.Note,
) !void {
    const err_msg = try ErrorMsg.create(self.allocator, loc, format, args, note);
    try self.errors.append(self.allocator, err_msg);
}
