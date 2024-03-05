//! Based on cb76461a088a2b554f0248e7cf94d5a12b77e28e
const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("Token.zig");
const Extensions = @import("wgsl.zig").Extensions;
const ErrorList = @import("ErrorList.zig");
const Node = Ast.Node;
const NodeIndex = Ast.NodeIndex;
const TokenIndex = Ast.TokenIndex;
const fieldNames = std.meta.fieldNames;
const Parser = @This();

allocator: std.mem.Allocator,
source: []const u8,
tok_i: TokenIndex = @enumFromInt(0),
tokens: std.MultiArrayList(Token),
nodes: std.MultiArrayList(Node) = .{},
extra: std.ArrayListUnmanaged(u32) = .{},
scratch: std.ArrayListUnmanaged(NodeIndex) = .{},
extensions: Extensions = .{},
errors: *ErrorList,

pub fn translationUnit(p: *Parser) !void {
    p.parameterizeTemplates() catch |err| switch (err) {
        error.Parsing => return,
        error.OutOfMemory => return error.OutOfMemory,
    };

    const root = try p.addNode(.{ .tag = .span, .main_token = undefined });

    while (try p.globalDirectiveRecoverable()) {}

    while (p.peekToken(.tag, 0) != .eof) {
        const decl = try p.expectGlobalDeclRecoverable() orelse continue;
        try p.scratch.append(p.allocator, decl);
    }

    if (p.errors.list.items.len > 0) return error.Parsing;

    try p.extra.appendSlice(p.allocator, @ptrCast(p.scratch.items));
    p.nodes.items(.lhs)[@intFromEnum(root)] = @enumFromInt(p.extra.items.len - p.scratch.items.len);
    p.nodes.items(.rhs)[@intFromEnum(root)] = @enumFromInt(p.extra.items.len);
}

// Based on https://gpuweb.github.io/gpuweb/wgsl/#template-lists-sec
fn parameterizeTemplates(p: *Parser) !void {
    const UnclosedCandidate = struct {
        token_tag: *Token.Tag,
        depth: u32,
    };
    var discovered_tmpls = std.BoundedArray(UnclosedCandidate, 16).init(0) catch unreachable;
    var depth: u32 = 0;

    var i: u32 = 0;
    while (i < p.tokens.len) : (i += 1) {
        switch (p.tokens.items(.tag)[i]) {
            .ident,
            .k_var,
            .k_bitcast,
            .k_array,
            .k_atomic,
            .k_ptr,
            .k_vec2,
            .k_vec3,
            .k_vec4,
            .k_mat2x2,
            .k_mat2x3,
            .k_mat2x4,
            .k_mat3x2,
            .k_mat3x3,
            .k_mat3x4,
            .k_mat4x2,
            .k_mat4x3,
            .k_mat4x4,
            .k_texture_1d,
            .k_texture_2d,
            .k_texture_2d_array,
            .k_texture_3d,
            .k_texture_cube,
            .k_texture_cube_array,
            .k_texture_storage_1d,
            .k_texture_storage_2d,
            .k_texture_storage_2d_array,
            .k_texture_storage_3d,
            => if (p.tokens.items(.tag)[i + 1] == .angle_bracket_left) {
                discovered_tmpls.append(.{
                    .token_tag = &p.tokens.items(.tag)[i + 1],
                    .depth = depth,
                }) catch {
                    try p.errors.add(p.tokens.items(.loc)[i + 1], "too deep template", .{}, null);
                    return error.Parsing;
                };
                i += 1;
            },
            .angle_bracket_right => {
                if (discovered_tmpls.len > 0 and discovered_tmpls.get(discovered_tmpls.len - 1).depth == depth) {
                    discovered_tmpls.pop().token_tag.* = .template_left;
                    p.tokens.items(.tag)[i] = .template_right;
                }
            },
            .angle_bracket_angle_bracket_right => {
                if (discovered_tmpls.len > 0 and discovered_tmpls.get(discovered_tmpls.len - 1).depth == depth) {
                    discovered_tmpls.pop().token_tag.* = .template_left;
                    discovered_tmpls.pop().token_tag.* = .template_left;

                    p.tokens.items(.tag)[i] = .template_right;
                    try p.tokens.insert(p.allocator, i, Token{
                        .tag = .template_right,
                        .loc = .{
                            .start = p.tokens.items(.loc)[i].start + 1,
                            .end = p.tokens.items(.loc)[i].end + 1,
                        },
                    });
                }
            },
            .paren_left, .bracket_left => {
                depth += 1;
            },
            .paren_right, .bracket_right => {
                while (discovered_tmpls.len > 0 and discovered_tmpls.get(discovered_tmpls.len - 1).depth == depth) {
                    _ = discovered_tmpls.pop();
                }

                if (depth > 0) {
                    depth -= 1;
                }
            },
            .semicolon, .colon, .brace_left => {
                depth = 0;
                discovered_tmpls.resize(0) catch unreachable;
            },
            .pipe_pipe, .ampersand_ampersand => {
                while (discovered_tmpls.len > 0 and discovered_tmpls.get(discovered_tmpls.len - 1).depth == depth) {
                    _ = discovered_tmpls.pop();
                }
            },
            else => {},
        }
    }
}

fn globalDirectiveRecoverable(p: *Parser) !bool {
    return p.globalDirective() catch |err| switch (err) {
        error.Parsing => {
            p.findNextGlobalDirective();
            return false;
        },
        error.OutOfMemory => error.OutOfMemory,
    };
}

fn globalDirective(p: *Parser) !bool {
    _ = p.eatToken(.k_enable) orelse return false;
    const ext_token = try p.expectToken(.ident);
    const directive = p.getToken(.loc, ext_token).slice(p.source);
    if (std.mem.eql(u8, directive, "f16")) {
        p.extensions.f16 = true;
    } else {
        try p.errors.add(p.getToken(.loc, ext_token), "invalid extension", .{}, null);
        return error.Parsing;
    }
    return true;
}

fn expectGlobalDeclRecoverable(p: *Parser) !?NodeIndex {
    return p.expectGlobalDecl() catch |err| switch (err) {
        error.Parsing => {
            p.findNextGlobalDecl();
            return null;
        },
        error.OutOfMemory => error.OutOfMemory,
    };
}

fn expectGlobalDecl(p: *Parser) !NodeIndex {
    while (p.eatToken(.semicolon)) |_| {}

    const attrs = try p.attributeList();

    if (try p.structDecl() orelse
        try p.fnDecl(attrs)) |node|
    {
        return node;
    }

    if (try p.constDecl() orelse
        try p.typeAliasDecl() orelse
        try p.constAssert() orelse
        try p.globalVar(attrs) orelse
        try p.globalOverrideDecl(attrs)) |node|
    {
        _ = try p.expectToken(.semicolon);
        return node;
    }

    try p.errors.add(
        p.peekToken(.loc, 0),
        "expected global declaration, found '{s}'",
        .{p.peekToken(.tag, 0).symbol()},
        null,
    );
    return error.Parsing;
}

fn attributeList(p: *Parser) !?NodeIndex {
    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);
    while (true) {
        const attr = try p.attribute() orelse break;
        try p.scratch.append(p.allocator, attr);
    }
    const attrs = p.scratch.items[scratch_top..];
    if (attrs.len == 0) return null;
    return try p.listToSpan(attrs);
}

fn attribute(p: *Parser) !?NodeIndex {
    const attr_token = p.eatToken(.attr) orelse return null;
    const ident_token = try p.expectToken(.ident);
    const str = p.getToken(.loc, ident_token).slice(p.source);
    const tag = std.meta.stringToEnum(Ast.Attribute, str) orelse {
        try p.errors.add(
            p.getToken(.loc, ident_token),
            "unknown attribute '{s}'",
            .{p.getToken(.loc, ident_token).slice(p.source)},
            null,
        );
        return error.Parsing;
    };

    var node = Node{
        .tag = undefined,
        .main_token = attr_token,
    };

    switch (tag) {
        .invariant => node.tag = .attr_invariant,
        .@"const" => node.tag = .attr_const,
        .must_use => node.tag = .attr_must_use,
        .vertex => node.tag = .attr_vertex,
        .fragment => node.tag = .attr_fragment,
        .compute => node.tag = .attr_compute,
        .@"align" => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_align;
            node.lhs = try p.expression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected expression, but found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            };
            _ = p.eatToken(.comma);
            _ = try p.expectToken(.paren_right);
        },
        .binding => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_binding;
            node.lhs = try p.expression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected expression, but found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            };
            _ = p.eatToken(.comma);
            _ = try p.expectToken(.paren_right);
        },
        .group => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_group;
            node.lhs = try p.expression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected expression, but found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            };
            _ = p.eatToken(.comma);
            _ = try p.expectToken(.paren_right);
        },
        .id => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_id;
            node.lhs = try p.expression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected expression, but found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            };
            _ = p.eatToken(.comma);
            _ = try p.expectToken(.paren_right);
        },
        .location => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_location;
            node.lhs = try p.expression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected expression, but found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            };
            _ = p.eatToken(.comma);
            _ = try p.expectToken(.paren_right);
        },
        .size => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_size;
            node.lhs = try p.expression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected expression, but found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            };
            _ = p.eatToken(.comma);
            _ = try p.expectToken(.paren_right);
        },
        .builtin => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_builtin;
            node.lhs = (try p.expectBuiltin()).asNodeIndex();
            _ = p.eatToken(.comma);
            _ = try p.expectToken(.paren_right);
        },
        .workgroup_size => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_workgroup_size;
            var workgroup_size = Node.WorkgroupSize{
                .x = try p.expression() orelse {
                    try p.errors.add(p.peekToken(.loc, 0), "expected workgroup_size x parameter", .{}, null);
                    return error.Parsing;
                },
            };
            if (p.eatToken(.comma) != null and p.peekToken(.tag, 0) != .paren_right) {
                workgroup_size.y = try p.expression() orelse {
                    try p.errors.add(p.peekToken(.loc, 0), "expected workgroup_size y parameter", .{}, null);
                    return error.Parsing;
                };

                if (p.eatToken(.comma) != null and p.peekToken(.tag, 0) != .paren_right) {
                    workgroup_size.z = try p.expression() orelse {
                        try p.errors.add(p.peekToken(.loc, 0), "expected workgroup_size z parameter", .{}, null);
                        return error.Parsing;
                    };

                    _ = p.eatToken(.comma);
                }
            }
            _ = try p.expectToken(.paren_right);
            node.lhs = try p.addExtra(workgroup_size);
        },
        .interpolate => {
            _ = try p.expectToken(.paren_left);
            node.tag = .attr_interpolate;
            node.lhs = (try p.expectInterpolationType()).asNodeIndex();
            if (p.eatToken(.comma) != null and p.peekToken(.tag, 0) != .paren_right) {
                node.rhs = (try p.expectInterpolationSample()).asNodeIndex();
                _ = p.eatToken(.comma);
            }
            _ = try p.expectToken(.paren_right);
        },
    }

    return try p.addNode(node);
}

fn expectBuiltin(p: *Parser) !TokenIndex {
    const token = p.advanceToken();
    if (p.getToken(.tag, token) == .ident) {
        const str = p.getToken(.loc, token).slice(p.source);
        if (std.meta.stringToEnum(Ast.Builtin, str)) |_| return token;
    }

    try p.errors.add(
        p.getToken(.loc, token),
        "unknown builtin value name '{s}'",
        .{p.getToken(.loc, token).slice(p.source)},
        null,
    );
    return error.Parsing;
}

fn expectInterpolationType(p: *Parser) !TokenIndex {
    const token = p.advanceToken();
    if (p.getToken(.tag, token) == .ident) {
        const str = p.getToken(.loc, token).slice(p.source);
        if (std.meta.stringToEnum(Ast.InterpolationType, str)) |_| return token;
    }

    try p.errors.add(
        p.getToken(.loc, token),
        "unknown interpolation type name '{s}'",
        .{p.getToken(.loc, token).slice(p.source)},
        null,
    );
    return error.Parsing;
}

fn expectInterpolationSample(p: *Parser) !TokenIndex {
    const token = p.advanceToken();
    if (p.getToken(.tag, token) == .ident) {
        const str = p.getToken(.loc, token).slice(p.source);
        if (std.meta.stringToEnum(Ast.InterpolationSample, str)) |_| return token;
    }

    try p.errors.add(
        p.getToken(.loc, token),
        "unknown interpolation sample name '{s}'",
        .{p.getToken(.loc, token).slice(p.source)},
        null,
    );
    return error.Parsing;
}

fn globalVar(p: *Parser, attrs: ?NodeIndex) !?NodeIndex {
    const var_token = p.eatToken(.k_var) orelse return null;

    // qualifier
    var addr_space = TokenIndex.none;
    var access_mode = TokenIndex.none;
    if (p.eatToken(.template_left)) |_| {
        addr_space = try p.expectAddressSpace();
        if (p.eatToken(.comma)) |_| access_mode = try p.expectAccessMode();
        _ = try p.expectToken(.template_right);
    }

    // name, type
    const name_token = try p.expectToken(.ident);
    var var_type = NodeIndex.none;
    if (p.eatToken(.colon)) |_| {
        var_type = try p.expectTypeSpecifier();
    }

    var initializer = NodeIndex.none;
    if (p.eatToken(.equal)) |_| {
        initializer = try p.expression() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "expected initializer expression, found '{s}'",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };
    }

    if (initializer == .none and var_type == .none) {
        try p.errors.add(
            p.getToken(.loc, var_token),
            "initializer expression is required while type is unknown",
            .{},
            null,
        );
        return error.Parsing;
    }

    const extra = try p.addExtra(Node.GlobalVar{
        .attrs = attrs orelse .none,
        .name = name_token,
        .addr_space = addr_space,
        .access_mode = access_mode,
        .type = var_type,
    });
    return try p.addNode(.{
        .tag = .global_var,
        .main_token = var_token,
        .lhs = extra,
        .rhs = initializer,
    });
}

fn globalOverrideDecl(p: *Parser, attrs: ?NodeIndex) !?NodeIndex {
    const override_token = p.eatToken(.k_override) orelse return null;

    // name, type
    _ = try p.expectToken(.ident);
    var override_type = NodeIndex.none;
    if (p.eatToken(.colon)) |_| {
        override_type = try p.expectTypeSpecifier();
    }

    var initializer = NodeIndex.none;
    if (p.eatToken(.equal)) |_| {
        initializer = try p.expression() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "expected initializer expression, found '{s}'",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };
    }

    const extra = try p.addExtra(Node.Override{
        .attrs = attrs orelse .none,
        .type = override_type,
    });
    return try p.addNode(.{
        .tag = .override,
        .main_token = override_token,
        .lhs = extra,
        .rhs = initializer,
    });
}

fn typeAliasDecl(p: *Parser) !?NodeIndex {
    const type_token = p.eatToken(.k_type) orelse return null;
    _ = try p.expectToken(.ident);
    _ = try p.expectToken(.equal);
    const value = try p.expectTypeSpecifier();
    return try p.addNode(.{
        .tag = .type_alias,
        .main_token = type_token,
        .lhs = value,
    });
}

fn structDecl(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_struct) orelse return null;
    const name_token = try p.expectToken(.ident);
    _ = try p.expectToken(.brace_left);

    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);
    while (true) {
        const attrs = try p.attributeList();
        const member = try p.structMember(attrs) orelse {
            if (attrs != null) {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected struct member, found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            }
            break;
        };
        try p.scratch.append(p.allocator, member);
        _ = p.eatToken(.comma);
    }

    _ = try p.expectToken(.brace_right);

    const members = p.scratch.items[scratch_top..];
    if (members.len == 0) {
        try p.errors.add(
            p.getToken(.loc, name_token),
            "struct '{s}' has no member",
            .{p.getToken(.loc, name_token).slice(p.source)},
            null,
        );
        return error.Parsing;
    }

    return try p.addNode(.{
        .tag = .@"struct",
        .main_token = main_token,
        .lhs = try p.listToSpan(members),
    });
}

fn structMember(p: *Parser, attrs: ?NodeIndex) !?NodeIndex {
    const name_token = p.eatToken(.ident) orelse return null;
    _ = try p.expectToken(.colon);
    const member_type = try p.expectTypeSpecifier();
    return try p.addNode(.{
        .tag = .struct_member,
        .main_token = name_token,
        .lhs = attrs orelse .none,
        .rhs = member_type,
    });
}

fn constAssert(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_const_assert) orelse return null;
    const expr = try p.expression() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected expression, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };
    return try p.addNode(.{
        .tag = .const_assert,
        .main_token = main_token,
        .lhs = expr,
    });
}

fn fnDecl(p: *Parser, attrs: ?NodeIndex) !?NodeIndex {
    const fn_token = p.eatToken(.k_fn) orelse return null;
    _ = try p.expectToken(.ident);

    _ = try p.expectToken(.paren_left);
    const params = try p.parameterList() orelse .none;
    _ = try p.expectToken(.paren_right);

    var return_attrs = NodeIndex.none;
    var return_type = NodeIndex.none;
    if (p.eatToken(.arrow)) |_| {
        return_attrs = try p.attributeList() orelse .none;
        return_type = try p.expectTypeSpecifier();
    }

    const body = try p.block() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected function body, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };

    const fn_proto = try p.addExtra(Node.FnProto{
        .attrs = attrs orelse .none,
        .params = params,
        .return_attrs = return_attrs,
        .return_type = return_type,
    });
    return try p.addNode(.{
        .tag = .@"fn",
        .main_token = fn_token,
        .lhs = fn_proto,
        .rhs = body,
    });
}

fn parameterList(p: *Parser) !?NodeIndex {
    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);
    while (true) {
        const attrs = try p.attributeList();
        const param = try p.parameter(attrs) orelse {
            if (attrs != null) {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected function parameter, found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            }
            break;
        };
        try p.scratch.append(p.allocator, param);
        if (p.eatToken(.comma) == null) break;
    }
    const list = p.scratch.items[scratch_top..];
    if (list.len == 0) return null;
    return try p.listToSpan(list);
}

fn parameter(p: *Parser, attrs: ?NodeIndex) !?NodeIndex {
    const main_token = p.eatToken(.ident) orelse return null;
    _ = try p.expectToken(.colon);
    const param_type = try p.expectTypeSpecifier();
    return try p.addNode(.{
        .tag = .fn_param,
        .main_token = main_token,
        .lhs = attrs orelse .none,
        .rhs = param_type,
    });
}

fn statementRecoverable(p: *Parser) !?NodeIndex {
    while (true) {
        return p.statement() catch |err| switch (err) {
            error.Parsing => {
                p.findNextStmt();
                switch (p.peekToken(.tag, 0)) {
                    .brace_right => return null,
                    .eof => return error.Parsing,
                    else => continue,
                }
            },
            error.OutOfMemory => error.OutOfMemory,
        };
    }
}

fn statement(p: *Parser) !?NodeIndex {
    while (p.eatToken(.semicolon)) |_| {}

    if (try p.breakStatement() orelse
        try p.breakIfStatement() orelse
        try p.callExpr() orelse
        try p.constAssert() orelse
        try p.continueStatement() orelse
        try p.discardStatement() orelse
        try p.returnStatement() orelse
        try p.varDecl() orelse
        try p.constDecl() orelse
        try p.letDecl() orelse
        try p.varUpdateStatement()) |node|
    {
        _ = try p.expectToken(.semicolon);
        return node;
    }

    if (try p.block() orelse
        try p.continuingStatement() orelse
        try p.forStatement() orelse
        try p.ifStatement() orelse
        try p.loopStatement() orelse
        try p.switchStatement() orelse
        try p.whileStatement()) |node|
    {
        return node;
    }

    return null;
}

fn expectBlock(p: *Parser) error{ OutOfMemory, Parsing }!NodeIndex {
    return try p.block() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected block statement, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };
}

fn block(p: *Parser) error{ OutOfMemory, Parsing }!?NodeIndex {
    const main_token = p.eatToken(.brace_left) orelse return null;
    const statements = try p.statementList() orelse .none;
    _ = try p.expectToken(.brace_right);
    return try p.addNode(.{
        .tag = .block,
        .main_token = main_token,
        .lhs = statements,
    });
}

fn statementList(p: *Parser) error{ OutOfMemory, Parsing }!?NodeIndex {
    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);

    while (true) {
        const stmt = try p.statement() orelse {
            if (p.peekToken(.tag, 0) == .brace_right) break;
            try p.errors.add(
                p.peekToken(.loc, 0),
                "expected statement, found '{s}'",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };
        try p.scratch.append(p.allocator, stmt);
    }

    const statements = p.scratch.items[scratch_top..];
    if (statements.len == 0) return null;
    return try p.listToSpan(statements);
}

fn breakStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_break) orelse return null;
    return try p.addNode(.{ .tag = .@"break", .main_token = main_token });
}

fn breakIfStatement(p: *Parser) !?NodeIndex {
    if (p.peekToken(.tag, 0) == .k_break and
        p.peekToken(.tag, 1) == .k_if)
    {
        const main_token = p.advanceToken();
        _ = p.advanceToken();
        const cond = try p.expression() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "expected condition expression, found '{s}'",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };
        return try p.addNode(.{
            .tag = .break_if,
            .main_token = main_token,
            .lhs = cond,
        });
    }
    return null;
}

fn continueStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_continue) orelse return null;
    return try p.addNode(.{ .tag = .@"continue", .main_token = main_token });
}

fn continuingStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_continuing) orelse return null;
    const body = try p.expectBlock();
    return try p.addNode(.{
        .tag = .continuing,
        .main_token = main_token,
        .lhs = body,
    });
}

fn discardStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_discard) orelse return null;
    return try p.addNode(.{ .tag = .discard, .main_token = main_token });
}

fn forStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_for) orelse return null;
    _ = try p.expectToken(.paren_left);

    // for init
    const for_init = try p.callExpr() orelse
        try p.varDecl() orelse
        try p.constDecl() orelse
        try p.letDecl() orelse
        try p.varUpdateStatement() orelse
        .none;
    _ = try p.expectToken(.semicolon);

    const for_cond = try p.expression() orelse .none;
    _ = try p.expectToken(.semicolon);

    // for update
    const for_update = try p.callExpr() orelse
        try p.varUpdateStatement() orelse
        .none;

    _ = try p.expectToken(.paren_right);
    const body = try p.expectBlock();

    const extra = try p.addExtra(Node.ForHeader{
        .init = for_init,
        .cond = for_cond,
        .update = for_update,
    });
    return try p.addNode(.{
        .tag = .@"for",
        .main_token = main_token,
        .lhs = extra,
        .rhs = body,
    });
}

fn ifStatement(p: *Parser) !?NodeIndex {
    const if_token = p.eatToken(.k_if) orelse return null;

    const cond = try p.expression() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected condition expression, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };
    const body = try p.block() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected if body block, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };

    if (p.eatToken(.k_else)) |else_token| {
        const if_node = try p.addNode(.{
            .tag = .@"if",
            .main_token = if_token,
            .lhs = cond,
            .rhs = body,
        });

        if (p.peekToken(.tag, 0) == .k_if) {
            const else_if = try p.ifStatement() orelse unreachable;
            return try p.addNode(.{
                .tag = .if_else_if,
                .main_token = else_token,
                .lhs = if_node,
                .rhs = else_if,
            });
        }

        const else_body = try p.block() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "expected else body block, found '{s}'",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };

        return try p.addNode(.{
            .tag = .if_else,
            .main_token = else_token,
            .lhs = if_node,
            .rhs = else_body,
        });
    }

    return try p.addNode(.{
        .tag = .@"if",
        .main_token = if_token,
        .lhs = cond,
        .rhs = body,
    });
}

fn loopStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_loop) orelse return null;
    const body = try p.expectBlock();
    return try p.addNode(.{
        .tag = .loop,
        .main_token = main_token,
        .lhs = body,
    });
}

fn returnStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_return) orelse return null;
    const expr = try p.expression() orelse .none;
    return try p.addNode(.{
        .tag = .@"return",
        .main_token = main_token,
        .lhs = expr,
    });
}

fn switchStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_switch) orelse return null;

    const expr = try p.expression() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected condition expression, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };

    _ = try p.expectToken(.brace_left);

    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);
    while (true) {
        if (p.eatToken(.k_default)) |default_token| {
            _ = p.eatToken(.colon);
            const default_body = try p.expectBlock();
            try p.scratch.append(p.allocator, try p.addNode(.{
                .tag = .switch_default,
                .main_token = default_token,
                .rhs = default_body,
            }));
        } else if (p.eatToken(.k_case)) |case_token| {
            const cases_scratch_top = p.scratch.items.len;

            const has_default = false;
            while (true) {
                const case_expr = try p.expression() orelse {
                    if (p.eatToken(.k_default)) |_| continue;
                    break;
                };
                _ = p.eatToken(.comma);
                try p.scratch.append(p.allocator, case_expr);
            }
            const case_expr_list = p.scratch.items[cases_scratch_top..];

            _ = p.eatToken(.colon);
            const default_body = try p.expectBlock();

            try p.scratch.append(p.allocator, try p.addNode(.{
                .tag = if (has_default) .switch_case_default else .switch_case,
                .main_token = case_token,
                .lhs = if (case_expr_list.len == 0) .none else try p.listToSpan(case_expr_list),
                .rhs = default_body,
            }));
            p.scratch.shrinkRetainingCapacity(cases_scratch_top);
        } else {
            break;
        }
    }

    _ = try p.expectToken(.brace_right);

    const case_list = p.scratch.items[scratch_top..];
    return try p.addNode(.{
        .tag = .@"switch",
        .main_token = main_token,
        .lhs = expr,
        .rhs = if (case_list.len == 0) .none else try p.listToSpan(case_list),
    });
}

fn varDecl(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_var) orelse return null;

    var addr_space = TokenIndex.none;
    var access_mode = TokenIndex.none;
    if (p.eatToken(.template_left)) |_| {
        addr_space = try p.expectAddressSpace();
        if (p.eatToken(.comma)) |_| access_mode = try p.expectAccessMode();
        _ = try p.expectToken(.template_right);
    }

    const name_token = try p.expectToken(.ident);
    var var_type = NodeIndex.none;
    if (p.eatToken(.colon)) |_| {
        var_type = try p.expectTypeSpecifier();
    }

    var initializer = NodeIndex.none;
    if (p.eatToken(.equal)) |_| {
        initializer = try p.expression() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "expected initializer expression, found '{s}'",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };
    }

    const extra = try p.addExtra(Node.Var{
        .name = name_token,
        .addr_space = addr_space,
        .access_mode = access_mode,
        .type = var_type,
    });
    return try p.addNode(.{
        .tag = .@"var",
        .main_token = main_token,
        .lhs = extra,
        .rhs = initializer,
    });
}

fn constDecl(p: *Parser) !?NodeIndex {
    const const_token = p.eatToken(.k_const) orelse return null;

    _ = try p.expectToken(.ident);
    var const_type = NodeIndex.none;
    if (p.eatToken(.colon)) |_| {
        const_type = try p.expectTypeSpecifier();
    }

    _ = try p.expectToken(.equal);
    const initializer = try p.expression() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected initializer expression, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };

    return try p.addNode(.{
        .tag = .@"const",
        .main_token = const_token,
        .lhs = const_type,
        .rhs = initializer,
    });
}

fn letDecl(p: *Parser) !?NodeIndex {
    const const_token = p.eatToken(.k_let) orelse return null;

    _ = try p.expectToken(.ident);
    var const_type = NodeIndex.none;
    if (p.eatToken(.colon)) |_| {
        const_type = try p.expectTypeSpecifier();
    }

    _ = try p.expectToken(.equal);
    const initializer = try p.expression() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected initializer expression, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };

    return try p.addNode(.{
        .tag = .let,
        .main_token = const_token,
        .lhs = const_type,
        .rhs = initializer,
    });
}

fn varUpdateStatement(p: *Parser) !?NodeIndex {
    if (p.eatToken(.underscore)) |_| {
        const equal_token = try p.expectToken(.equal);
        const expr = try p.expression() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "expected expression, found '{s}'",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };
        return try p.addNode(.{
            .tag = .phony_assign,
            .main_token = equal_token,
            .lhs = expr,
        });
    } else if (try p.lhsExpression()) |lhs| {
        const op_token = p.advanceToken();
        switch (p.getToken(.tag, op_token)) {
            .plus_plus => {
                return try p.addNode(.{
                    .tag = .increase,
                    .main_token = op_token,
                    .lhs = lhs,
                });
            },
            .minus_minus => {
                return try p.addNode(.{
                    .tag = .decrease,
                    .main_token = op_token,
                    .lhs = lhs,
                });
            },
            .equal,
            .plus_equal,
            .minus_equal,
            .asterisk_equal,
            .slash_equal,
            .percent_equal,
            .ampersand_equal,
            .pipe_equal,
            .xor_equal,
            .angle_bracket_angle_bracket_left_equal,
            .angle_bracket_angle_bracket_right_equal,
            => {
                const expr = try p.expression() orelse {
                    try p.errors.add(
                        p.peekToken(.loc, 0),
                        "expected expression, found '{s}'",
                        .{p.peekToken(.tag, 0).symbol()},
                        null,
                    );
                    return error.Parsing;
                };
                return try p.addNode(.{
                    .tag = .compound_assign,
                    .main_token = op_token,
                    .lhs = lhs,
                    .rhs = expr,
                });
            },
            else => {
                try p.errors.add(
                    p.getToken(.loc, op_token),
                    "invalid assignment operator '{s}'",
                    .{p.getToken(.tag, op_token).symbol()},
                    null,
                );
                return error.Parsing;
            },
        }
    }

    return null;
}

fn whileStatement(p: *Parser) !?NodeIndex {
    const main_token = p.eatToken(.k_while) orelse return null;
    const cond = try p.expression() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected condition expression, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };
    const body = try p.expectBlock();
    return try p.addNode(.{
        .tag = .@"while",
        .main_token = main_token,
        .lhs = cond,
        .rhs = body,
    });
}

fn expectTypeSpecifier(p: *Parser) error{ OutOfMemory, Parsing }!NodeIndex {
    return try p.typeSpecifier() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "expected type specifier, found '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };
}

fn typeSpecifier(p: *Parser) !?NodeIndex {
    if (p.peekToken(.tag, 0) == .ident) {
        const main_token = p.advanceToken();
        return try p.addNode(.{ .tag = .ident, .main_token = main_token });
    }
    return p.typeSpecifierWithoutIdent();
}

fn typeSpecifierWithoutIdent(p: *Parser) !?NodeIndex {
    const main_token = p.advanceToken();
    switch (p.getToken(.tag, main_token)) {
        .k_bool => return try p.addNode(.{ .tag = .bool_type, .main_token = main_token }),
        .k_i32,
        .k_u32,
        .k_f32,
        => return try p.addNode(.{ .tag = .number_type, .main_token = main_token }),
        .k_f16 => {
            if (p.extensions.f16) {
                return try p.addNode(.{ .tag = .number_type, .main_token = main_token });
            }

            try p.errors.add(p.getToken(.loc, main_token), "f16 extension required", .{}, null);
            return error.Parsing;
        },
        .k_vec2, .k_vec3, .k_vec4 => {
            var elem_type = NodeIndex.none;

            if (p.eatToken(.template_left)) |_| {
                elem_type = try p.expectTypeSpecifier();
                _ = try p.expectToken(.template_right);
            }

            return try p.addNode(.{
                .tag = .vector_type,
                .main_token = main_token,
                .lhs = elem_type,
            });
        },
        .k_mat2x2,
        .k_mat2x3,
        .k_mat2x4,
        .k_mat3x2,
        .k_mat3x3,
        .k_mat3x4,
        .k_mat4x2,
        .k_mat4x3,
        .k_mat4x4,
        => {
            var elem_type = NodeIndex.none;

            if (p.eatToken(.template_left)) |_| {
                elem_type = try p.expectTypeSpecifier();
                _ = try p.expectToken(.template_right);
            }

            return try p.addNode(.{
                .tag = .matrix_type,
                .main_token = main_token,
                .lhs = elem_type,
            });
        },
        .k_sampler, .k_sampler_comparison => {
            return try p.addNode(.{ .tag = .sampler_type, .main_token = main_token });
        },
        .k_atomic => {
            _ = try p.expectToken(.template_left);
            const elem_type = try p.expectTypeSpecifier();
            _ = try p.expectToken(.template_right);
            return try p.addNode(.{
                .tag = .atomic_type,
                .main_token = main_token,
                .lhs = elem_type,
            });
        },
        .k_array => {
            var elem_type = NodeIndex.none;
            var size = NodeIndex.none;

            if (p.eatToken(.template_left)) |_| {
                elem_type = try p.expectTypeSpecifier();
                if (p.eatToken(.comma)) |_| {
                    size = try p.elementCountExpr() orelse {
                        try p.errors.add(
                            p.peekToken(.loc, 0),
                            "expected array size expression, found '{s}'",
                            .{p.peekToken(.tag, 0).symbol()},
                            null,
                        );
                        return error.Parsing;
                    };
                }
                _ = try p.expectToken(.template_right);
            }

            return try p.addNode(.{
                .tag = .array_type,
                .main_token = main_token,
                .lhs = elem_type,
                .rhs = size,
            });
        },
        .k_ptr => {
            _ = try p.expectToken(.template_left);

            const addr_space = try p.expectAddressSpace();
            _ = try p.expectToken(.comma);
            const elem_type = try p.expectTypeSpecifier();
            _ = try p.expectToken(.comma);
            const access_mode = try p.expectAccessMode();
            _ = try p.expectToken(.template_right);

            const extra = try p.addExtra(Node.PtrType{
                .addr_space = addr_space,
                .access_mode = access_mode,
            });
            return try p.addNode(.{
                .tag = .ptr_type,
                .main_token = main_token,
                .lhs = elem_type,
                .rhs = extra,
            });
        },
        .k_texture_1d,
        .k_texture_2d,
        .k_texture_2d_array,
        .k_texture_3d,
        .k_texture_cube,
        .k_texture_cube_array,
        => {
            _ = try p.expectToken(.template_left);
            const elem_type = try p.expectTypeSpecifier();
            _ = try p.expectToken(.template_right);
            return try p.addNode(.{
                .tag = .sampled_texture_type,
                .main_token = main_token,
                .lhs = elem_type,
            });
        },
        .k_texture_multisampled_2d => {
            _ = try p.expectToken(.template_left);
            const elem_type = try p.expectTypeSpecifier();
            _ = try p.expectToken(.template_right);
            return try p.addNode(.{
                .tag = .multisampled_texture_type,
                .main_token = main_token,
                .lhs = elem_type,
            });
        },
        .k_texture_depth_multisampled_2d => {
            return try p.addNode(.{
                .tag = .multisampled_texture_type,
                .main_token = main_token,
            });
        },
        .k_texture_external => {
            return try p.addNode(.{
                .tag = .external_texture_type,
                .main_token = main_token,
            });
        },
        .k_texture_depth_2d,
        .k_texture_depth_2d_array,
        .k_texture_depth_cube,
        .k_texture_depth_cube_array,
        => {
            return try p.addNode(.{
                .tag = .depth_texture_type,
                .main_token = main_token,
            });
        },
        .k_texture_storage_1d,
        .k_texture_storage_2d,
        .k_texture_storage_2d_array,
        .k_texture_storage_3d,
        => {
            _ = try p.expectToken(.template_left);
            const texel_format = try p.expectTexelFormat();
            _ = try p.expectToken(.comma);
            const access_mode = try p.expectAccessMode();
            _ = try p.expectToken(.template_right);
            return try p.addNode(.{
                .tag = .storage_texture_type,
                .main_token = main_token,
                .lhs = texel_format.asNodeIndex(),
                .rhs = access_mode.asNodeIndex(),
            });
        },
        else => return null,
    }
}

fn expectAddressSpace(p: *Parser) !TokenIndex {
    const token = p.advanceToken();
    if (p.getToken(.tag, token) == .ident) {
        const str = p.getToken(.loc, token).slice(p.source);
        if (std.meta.stringToEnum(Ast.AddressSpace, str)) |_| {
            return token;
        }
    }

    try p.errors.add(
        p.getToken(.loc, token),
        "unknown address space '{s}'",
        .{p.getToken(.loc, token).slice(p.source)},
        null,
    );
    return error.Parsing;
}

fn expectAccessMode(p: *Parser) !TokenIndex {
    const token = p.advanceToken();
    if (p.getToken(.tag, token) == .ident) {
        const str = p.getToken(.loc, token).slice(p.source);
        if (std.meta.stringToEnum(Ast.AccessMode, str)) |_| {
            return token;
        }
    }

    try p.errors.add(
        p.getToken(.loc, token),
        "unknown access mode '{s}'",
        .{p.getToken(.loc, token).slice(p.source)},
        null,
    );
    return error.Parsing;
}

fn expectTexelFormat(p: *Parser) !TokenIndex {
    const token = p.advanceToken();
    if (p.getToken(.tag, token) == .ident) {
        const str = p.getToken(.loc, token).slice(p.source);
        if (std.meta.stringToEnum(Ast.TexelFormat, str)) |_| {
            return token;
        }
    }

    try p.errors.add(
        p.getToken(.loc, token),
        "unknown address space '{s}'",
        .{p.getToken(.loc, token).slice(p.source)},
        null,
    );
    return error.Parsing;
}

fn expectParenExpr(p: *Parser) !NodeIndex {
    _ = try p.expectToken(.paren_left);
    const expr = try p.expression() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "unable to parse expression '{s}'",
            .{p.peekToken(.tag, 0).symbol()},
            null,
        );
        return error.Parsing;
    };
    _ = try p.expectToken(.paren_right);
    return expr;
}

fn callExpr(p: *Parser) !?NodeIndex {
    const main_token = p.tok_i;
    var rhs = NodeIndex.none;

    switch (p.peekToken(.tag, 0)) {
        // fn call or struct construct
        .ident => {
            if (p.peekToken(.tag, 1) == .paren_left) {
                _ = p.advanceToken();
            } else {
                return null;
            }
        },
        // construct
        .k_bool,
        .k_u32,
        .k_i32,
        .k_f32,
        .k_f16,
        .k_vec2,
        .k_vec3,
        .k_vec4,
        .k_mat2x2,
        .k_mat2x3,
        .k_mat2x4,
        .k_mat3x2,
        .k_mat3x3,
        .k_mat3x4,
        .k_mat4x2,
        .k_mat4x3,
        .k_mat4x4,
        .k_array,
        => {
            rhs = try p.typeSpecifierWithoutIdent() orelse return null;
        },
        else => return null,
    }

    _ = try p.expectToken(.paren_left);
    const scratch_top = p.scratch.items.len;
    defer p.scratch.shrinkRetainingCapacity(scratch_top);
    while (true) {
        const expr = try p.expression() orelse break;
        try p.scratch.append(p.allocator, expr);
        if (p.eatToken(.comma) == null) break;
    }
    _ = try p.expectToken(.paren_right);
    const args = p.scratch.items[scratch_top..];

    return try p.addNode(.{
        .tag = .call,
        .main_token = main_token,
        .lhs = if (args.len == 0) .none else try p.listToSpan(args),
        .rhs = rhs,
    });
}

fn expression(p: *Parser) !?NodeIndex {
    const lhs_unary = try p.unaryExpr() orelse return null;
    if (try p.bitwiseExpr(lhs_unary)) |bitwise| return bitwise;
    const lhs = try p.expectRelationalExpr(lhs_unary);
    return try p.expectShortCircuitExpr(lhs);
}

fn lhsExpression(p: *Parser) !?NodeIndex {
    if (p.eatToken(.ident)) |ident_token| {
        return try p.componentOrSwizzleSpecifier(
            try p.addNode(.{ .tag = .ident, .main_token = ident_token }),
        );
    }

    if (p.eatToken(.paren_left)) |_| {
        const expr = try p.lhsExpression() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "expected lhs expression, found '{s}'",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };
        _ = try p.expectToken(.paren_right);
        return try p.componentOrSwizzleSpecifier(expr);
    }

    if (p.eatToken(.asterisk)) |star_token| {
        return try p.addNode(.{
            .tag = .deref,
            .main_token = star_token,
            .lhs = try p.lhsExpression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected lhs expression, found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            },
        });
    }

    if (p.eatToken(.ampersand)) |addr_of_token| {
        return try p.addNode(.{
            .tag = .addr_of,
            .main_token = addr_of_token,
            .lhs = try p.lhsExpression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected lhs expression, found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            },
        });
    }

    return null;
}

fn singularExpr(p: *Parser) !?NodeIndex {
    const prefix = try p.primaryExpr() orelse return null;
    return try p.componentOrSwizzleSpecifier(prefix);
}

fn primaryExpr(p: *Parser) !?NodeIndex {
    const main_token = p.tok_i;
    if (try p.callExpr()) |call| return call;
    switch (p.getToken(.tag, main_token)) {
        .k_true => {
            _ = p.advanceToken();
            return try p.addNode(.{ .tag = .true, .main_token = main_token });
        },
        .k_false => {
            _ = p.advanceToken();
            return try p.addNode(.{ .tag = .false, .main_token = main_token });
        },
        .number => {
            _ = p.advanceToken();
            return try p.addNode(.{ .tag = .number, .main_token = main_token });
        },
        .k_bitcast => {
            _ = p.advanceToken();
            _ = try p.expectToken(.template_left);
            const dest_type = try p.expectTypeSpecifier();
            _ = try p.expectToken(.template_right);
            const expr = try p.expectParenExpr();
            return try p.addNode(.{
                .tag = .bitcast,
                .main_token = main_token,
                .lhs = dest_type,
                .rhs = expr,
            });
        },
        .paren_left => return try p.expectParenExpr(),
        .ident => {
            _ = p.advanceToken();
            return try p.addNode(.{ .tag = .ident, .main_token = main_token });
        },
        else => {
            return null;
        },
    }
}

fn elementCountExpr(p: *Parser) !?NodeIndex {
    const left = try p.unaryExpr() orelse return null;
    if (try p.bitwiseExpr(left)) |right| return right;
    return try p.expectMathExpr(left);
}

fn unaryExpr(p: *Parser) error{ OutOfMemory, Parsing }!?NodeIndex {
    const op_token = p.tok_i;
    const op: Node.Tag = switch (p.getToken(.tag, op_token)) {
        .bang, .tilde => .not,
        .minus => .negate,
        .asterisk => .deref,
        .ampersand => .addr_of,
        else => return p.singularExpr(),
    };
    _ = p.advanceToken();

    const expr = try p.unaryExpr() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "unable to parse right side of '{s}' expression",
            .{p.getToken(.tag, op_token).symbol()},
            null,
        );
        return error.Parsing;
    };

    return try p.addNode(.{
        .tag = op,
        .main_token = op_token,
        .lhs = expr,
    });
}

fn expectRelationalExpr(p: *Parser, lhs_unary: NodeIndex) !NodeIndex {
    const lhs = try p.expectShiftExpr(lhs_unary);
    const op_token = p.tok_i;
    const op: Node.Tag = switch (p.getToken(.tag, op_token)) {
        .equal_equal => .equal,
        .bang_equal => .not_equal,
        .angle_bracket_right => .greater_than,
        .angle_bracket_right_equal => .greater_than_equal,
        .angle_bracket_left => .less_than,
        .angle_bracket_left_equal => .less_than_equal,
        else => return lhs,
    };
    _ = p.advanceToken();

    const rhs_unary = try p.unaryExpr() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "unable to parse right side of '{s}' expression",
            .{p.getToken(.tag, op_token).symbol()},
            null,
        );
        return error.Parsing;
    };
    const rhs = try p.expectShiftExpr(rhs_unary);
    return try p.addNode(.{
        .tag = op,
        .main_token = op_token,
        .lhs = lhs,
        .rhs = rhs,
    });
}

fn expectShortCircuitExpr(p: *Parser, lhs_relational: NodeIndex) !NodeIndex {
    var lhs = lhs_relational;

    const op_token = p.tok_i;
    const op: Node.Tag = switch (p.getToken(.tag, op_token)) {
        .ampersand_ampersand => .logical_and,
        .pipe_pipe => .logical_or,
        else => return lhs,
    };

    while (p.peekToken(.tag, 0) == p.getToken(.tag, op_token)) {
        _ = p.advanceToken();

        const rhs_unary = try p.unaryExpr() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "unable to parse right side of '{s}' expression",
                .{p.getToken(.tag, op_token).symbol()},
                null,
            );
            return error.Parsing;
        };
        const rhs = try p.expectRelationalExpr(rhs_unary);

        lhs = try p.addNode(.{
            .tag = op,
            .main_token = op_token,
            .lhs = lhs,
            .rhs = rhs,
        });
    }

    return lhs;
}

fn bitwiseExpr(p: *Parser, lhs: NodeIndex) !?NodeIndex {
    const op_token = p.tok_i;
    const op: Node.Tag = switch (p.getToken(.tag, op_token)) {
        .ampersand => .@"and",
        .pipe => .@"or",
        .xor => .xor,
        else => return null,
    };
    _ = p.advanceToken();

    var lhs_result = lhs;
    while (true) {
        const rhs = try p.unaryExpr() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "unable to parse right side of '{s}' expression",
                .{p.getToken(.tag, op_token).symbol()},
                null,
            );
            return error.Parsing;
        };

        lhs_result = try p.addNode(.{
            .tag = op,
            .main_token = op_token,
            .lhs = lhs_result,
            .rhs = rhs,
        });

        if (p.peekToken(.tag, 0) != p.getToken(.tag, op_token)) return lhs_result;
    }
}

fn expectShiftExpr(p: *Parser, lhs: NodeIndex) !NodeIndex {
    const op_token = p.tok_i;
    const op: Node.Tag = switch (p.getToken(.tag, op_token)) {
        .angle_bracket_angle_bracket_left => .shl,
        .angle_bracket_angle_bracket_right => .shl,
        else => return try p.expectMathExpr(lhs),
    };
    _ = p.advanceToken();

    const rhs = try p.unaryExpr() orelse {
        try p.errors.add(
            p.peekToken(.loc, 0),
            "unable to parse right side of '{s}' expression",
            .{p.getToken(.tag, op_token).symbol()},
            null,
        );
        return error.Parsing;
    };

    return try p.addNode(.{
        .tag = op,
        .main_token = op_token,
        .lhs = lhs,
        .rhs = rhs,
    });
}

fn expectMathExpr(p: *Parser, left: NodeIndex) !NodeIndex {
    const right = try p.expectMultiplicativeExpr(left);
    return p.expectAdditiveExpr(right);
}

fn expectAdditiveExpr(p: *Parser, lhs_mul: NodeIndex) !NodeIndex {
    var lhs = lhs_mul;
    while (true) {
        const op_token = p.tok_i;
        const op: Node.Tag = switch (p.getToken(.tag, op_token)) {
            .plus => .add,
            .minus => .sub,
            else => return lhs,
        };
        _ = p.advanceToken();
        const unary = try p.unaryExpr() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "unable to parse right side of '{s}' expression",
                .{p.getToken(.tag, op_token).symbol()},
                null,
            );
            return error.Parsing;
        };
        const rhs = try p.expectMultiplicativeExpr(unary);
        lhs = try p.addNode(.{
            .tag = op,
            .main_token = op_token,
            .lhs = lhs,
            .rhs = rhs,
        });
    }
}

fn expectMultiplicativeExpr(p: *Parser, lhs_unary: NodeIndex) !NodeIndex {
    var lhs = lhs_unary;
    while (true) {
        const op_token = p.tok_i;
        const node_tag: Node.Tag = switch (p.peekToken(.tag, 0)) {
            .asterisk => .mul,
            .slash => .div,
            .percent => .mod,
            else => return lhs,
        };
        _ = p.advanceToken();
        const rhs = try p.unaryExpr() orelse {
            try p.errors.add(
                p.peekToken(.loc, 0),
                "unable to parse right side of '{s}' expression",
                .{p.peekToken(.tag, 0).symbol()},
                null,
            );
            return error.Parsing;
        };
        lhs = try p.addNode(.{
            .tag = node_tag,
            .main_token = op_token,
            .lhs = lhs,
            .rhs = rhs,
        });
    }
}

fn componentOrSwizzleSpecifier(p: *Parser, prefix: NodeIndex) !NodeIndex {
    var prefix_result = prefix;
    while (true) {
        if (p.eatToken(.dot)) |dot_token| {
            const member_token = try p.expectToken(.ident);
            prefix_result = try p.addNode(.{
                .tag = .field_access,
                .main_token = dot_token,
                .lhs = prefix_result,
                .rhs = member_token.asNodeIndex(),
            });
        } else if (p.eatToken(.bracket_left)) |bracket_left_token| {
            const index_expr = try p.expression() orelse {
                try p.errors.add(
                    p.peekToken(.loc, 0),
                    "expected expression, but found '{s}'",
                    .{p.peekToken(.tag, 0).symbol()},
                    null,
                );
                return error.Parsing;
            };
            _ = try p.expectToken(.bracket_right);
            prefix_result = try p.addNode(.{
                .tag = .index_access,
                .main_token = bracket_left_token,
                .lhs = prefix_result,
                .rhs = index_expr,
            });
        } else return prefix_result;
    }
}

fn findNextGlobalDirective(p: *Parser) void {
    while (true) {
        switch (p.peekToken(.tag, 0)) {
            .k_enable, .k_requires, .eof => return,
            .semicolon => {
                _ = p.advanceToken();
                return;
            },
            else => _ = p.advanceToken(),
        }
    }
}

fn findNextGlobalDecl(p: *Parser) void {
    var level: u32 = 0;
    while (true) {
        switch (p.peekToken(.tag, 0)) {
            .k_fn,
            .k_var,
            .k_const,
            .k_override,
            .k_struct,
            .attr,
            => {
                if (level == 0) return;
            },
            .semicolon => {
                if (level == 0) {
                    _ = p.advanceToken();
                    return;
                }
            },
            .brace_left,
            .bracket_left,
            .paren_left,
            => {
                level += 1;
            },
            .brace_right => {
                if (level == 0) {
                    _ = p.advanceToken();
                    return;
                }
                level -= 1;
            },
            .bracket_right, .paren_right => {
                if (level != 0) level -= 1;
            },
            .eof => return,
            else => {},
        }
        _ = p.advanceToken();
    }
}

fn findNextStmt(p: *Parser) void {
    var level: NodeIndex = 0;
    while (true) {
        switch (p.peekToken(.tag, 0)) {
            .semicolon => {
                if (level == 0) {
                    _ = p.advanceToken();
                    return;
                }
            },
            .brace_left => {
                level += 1;
            },
            .brace_right => {
                if (level == 0) {
                    _ = p.advanceToken();
                    return;
                }
                level -= 1;
            },
            .eof => return,
            else => {},
        }
        _ = p.advanceToken();
    }
}

fn listToSpan(p: *Parser, list: []const NodeIndex) !NodeIndex {
    try p.extra.appendSlice(p.allocator, @ptrCast(list));
    return p.addNode(.{
        .tag = .span,
        .main_token = undefined,
        .lhs = @enumFromInt(p.extra.items.len - list.len),
        .rhs = @enumFromInt(p.extra.items.len),
    });
}

fn addNode(p: *Parser, node: Node) error{OutOfMemory}!NodeIndex {
    const i: NodeIndex = @enumFromInt(p.nodes.len);
    try p.nodes.append(p.allocator, node);
    return i;
}

fn addExtra(p: *Parser, extra: anytype) error{OutOfMemory}!NodeIndex {
    const fields = std.meta.fields(@TypeOf(extra));
    try p.extra.ensureUnusedCapacity(p.allocator, fields.len);
    const result: NodeIndex = @enumFromInt(p.extra.items.len);
    inline for (fields) |field| {
        comptime std.debug.assert(field.type == NodeIndex or field.type == TokenIndex);
        p.extra.appendAssumeCapacity(@intFromEnum(@field(extra, field.name)));
    }
    return result;
}

fn getToken(
    p: Parser,
    comptime field: Ast.TokenList.Field,
    index: TokenIndex,
) std.meta.fieldInfo(Token, field).type {
    return p.tokens.items(field)[@intFromEnum(index)];
}

fn peekToken(
    p: Parser,
    comptime field: Ast.TokenList.Field,
    offset: isize,
) std.meta.fieldInfo(Token, field).type {
    return p.tokens.items(field)[@intCast(@as(isize, @intCast(@intFromEnum(p.tok_i))) + offset)];
}

fn advanceToken(p: *Parser) TokenIndex {
    const prev = p.tok_i;
    p.tok_i = @enumFromInt(@min(@intFromEnum(prev) + 1, p.tokens.len));
    return prev;
}

fn eatToken(p: *Parser, tag: Token.Tag) ?TokenIndex {
    return if (p.peekToken(.tag, 0) == tag) p.advanceToken() else null;
}

fn expectToken(p: *Parser, tag: Token.Tag) !TokenIndex {
    const token = p.advanceToken();
    if (p.getToken(.tag, token) == tag) return token;

    try p.errors.add(
        p.getToken(.loc, token),
        "expected '{s}', but found '{s}'",
        .{ tag.symbol(), p.getToken(.tag, token).symbol() },
        null,
    );
    return error.Parsing;
}
