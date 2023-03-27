const std = @import("std");
const dusk = @import("dusk");
const expect = std.testing.expect;
const allocator = std.testing.allocator;

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

fn expectIR(source: [:0]const u8) !dusk.IR {
    var tree = try dusk.Ast.parse(allocator, source);
    defer tree.deinit(allocator);

    if (tree.errors.list.items.len > 0) {
        try tree.errors.print(source, null);
        return error.Parsing;
    }

    var ir = try dusk.IR.generate(allocator, &tree);
    errdefer ir.deinit();

    if (ir.errors.list.items.len > 0) {
        try ir.errors.print(source, null);
        return error.ExpectedIR;
    }

    return ir;
}

fn expectError(source: [:0]const u8, err: dusk.ErrorList.ErrorMsg) !void {
    var tree = try dusk.Ast.parse(allocator, source);
    defer tree.deinit(allocator);
    var err_list = tree.errors;

    var ir: ?dusk.IR = null;
    defer if (ir != null) ir.?.deinit();

    if (err_list.list.items.len == 0) {
        ir = try dusk.IR.generate(allocator, &tree);

        err_list = ir.?.errors;
        if (err_list.list.items.len == 0) {
            return error.ExpectedError;
        }
    }

    const first_error = err_list.list.items[0];
    {
        errdefer {
            std.debug.print(
                "\n\x1b[31mexpected error({d}..{d}):\n{s}\n\x1b[32mactual error({d}..{d}):\n{s}\n\x1b[0m",
                .{
                    err.loc.start,         err.loc.end,         err.msg,
                    first_error.loc.start, first_error.loc.end, first_error.msg,
                },
            );
        }
        try expect(std.mem.eql(u8, err.msg, first_error.msg));
        try expect(first_error.loc.start == err.loc.start);
        try expect(first_error.loc.end == err.loc.end);
    }
    if (first_error.note) |_| {
        errdefer {
            std.debug.print(
                "\n\x1b[31mexpected note msg:\n{s}\n\x1b[32mactual note msg:\n{s}\n\x1b[0m",
                .{ err.note.?.msg, first_error.note.?.msg },
            );
        }
        if (err.note == null) {
            std.debug.print("\x1b[31mnote missed: {s}\x1b[0m\n", .{first_error.note.?.msg});
            return error.NoteMissed;
        }
        try expect(std.mem.eql(u8, err.note.?.msg, first_error.note.?.msg));
        if (first_error.note.?.loc) |_| {
            errdefer {
                std.debug.print(
                    "\n\x1b[31mexpected note loc: {d}..{d}\n\x1b[32mactual note loc: {d}..{d}\n\x1b[0m",
                    .{
                        err.note.?.loc.?.start,         err.note.?.loc.?.end,
                        first_error.note.?.loc.?.start, first_error.note.?.loc.?.end,
                    },
                );
            }
            try expect(first_error.note.?.loc.?.start == err.note.?.loc.?.start);
            try expect(first_error.note.?.loc.?.end == err.note.?.loc.?.end);
        }
    }
}

test "empty" {
    const source = "";
    var ir = try expectIR(source);
    defer ir.deinit();
}

test "boids" {
    const source = @embedFile("boids.wgsl");
    var ir = try expectIR(source);
    defer ir.deinit();
    // try ir.print(std.io.getStdOut().writer());
}

test "gkurve" {
    if (true) return error.SkipZigTest;

    const source = @embedFile("gkurve.wgsl");
    var ir = try expectIR(source);
    defer ir.deinit();
}

test "variable & expressions" {
    // const source = "var expr = 1 + 5 + 2 * 3 > 6 >> 7;";

    // var ir = try expectIR(source);
    // defer ir.deinit();

    // const root_node = 0;
    // try expect(ir.nodeLHS(root_node) + 1 == ir.nodeRHS(root_node));

    // const variable = ir.spanToList(root_node)[0];
    // const variable_name = ir.tokenLoc(ir.extraData(dusk.Ast.Node.GlobalVarDecl, ir.nodeLHS(variable)).name);
    // try expect(std.mem.eql(u8, "expr", variable_name.slice(source)));
    // try expect(ir.nodeTag(variable) == .global_variable);
    // try expect(ir.tokenTag(ir.nodeToken(variable)) == .k_var);

    // const expr = ir.nodeRHS(variable);
    // try expect(ir.nodeTag(expr) == .greater);

    // const @"1 + 5 + 2 * 3" = ir.nodeLHS(expr);
    // try expect(ir.nodeTag(@"1 + 5 + 2 * 3") == .add);

    // const @"1 + 5" = ir.nodeLHS(@"1 + 5 + 2 * 3");
    // try expect(ir.nodeTag(@"1 + 5") == .add);

    // const @"1" = ir.nodeLHS(@"1 + 5");
    // try expect(ir.nodeTag(@"1") == .number_literal);

    // const @"5" = ir.nodeRHS(@"1 + 5");
    // try expect(ir.nodeTag(@"5") == .number_literal);

    // const @"2 * 3" = ir.nodeRHS(@"1 + 5 + 2 * 3");
    // try expect(ir.nodeTag(@"2 * 3") == .mul);

    // const @"6 >> 7" = ir.nodeRHS(expr);
    // try expect(ir.nodeTag(@"6 >> 7") == .shift_right);

    // const @"6" = ir.nodeLHS(@"6 >> 7");
    // try expect(ir.nodeTag(@"6") == .number_literal);

    // const @"7" = ir.nodeRHS(@"6 >> 7");
    // try expect(ir.nodeTag(@"7") == .number_literal);
}

test "simple analyse's result" {
    // {
    //     const source =
    //         \\type T0 = f32;
    //         \\type T1 = T0;
    //         \\type T2 = T1;
    //         \\type T3 = T2;
    //         \\struct S0 { m0: T3 }
    //     ;
    //     var ir = try expectIR(source);
    //     // try std.testing.expect(ir.root[0].@"struct".members[0].type.number == .f32);
    //     ir.deinit();
    // }
}

test "must error" {
    {
        const source = "^";
        try expectError(source, .{
            .msg = "expected global declaration, found '^'",
            .loc = .{ .start = 0, .end = 1 },
        });
    }
    {
        const source = "struct S { m0: array<f32>, m1: f32 }";
        try expectError(source, .{
            .msg = "struct member with runtime-sized array type, must be the last member of the structure",
            .loc = .{ .start = 11, .end = 13 },
        });
    }
    {
        const source = "struct S0 { m: S1 }";
        try expectError(source, .{
            .msg = "use of undeclared identifier 'S1'",
            .loc = .{ .start = 15, .end = 17 },
        });
    }
    {
        const source =
            \\var S1 = 0;
            \\struct S0 { m: S1 }
        ;
        try expectError(source, .{
            .msg = "'S1' is not a type",
            .loc = .{ .start = 27, .end = 29 },
        });
    }
    {
        const source =
            \\struct S0 { m: sampler }
        ;
        try expectError(source, .{
            .msg = "invalid struct member type 'sampler'",
            .loc = .{ .start = 12, .end = 13 },
        });
    }
    {
        const source =
            \\var d1 = 0;
            \\var d1 = 0;
        ;
        try expectError(source, .{
            .msg = "redeclaration of 'd1'",
            .loc = .{ .start = 16, .end = 18 },
            .note = .{ .msg = "other declaration here", .loc = .{ .start = 4, .end = 6 } },
        });
    }
    {
        const source = "struct S { m0: vec2<sampler> }";
        try expectError(source, .{
            .msg = "invalid vector component type",
            .loc = .{ .start = 20, .end = 27 },
            .note = .{ .msg = "must be 'i32', 'u32', 'f32', 'f16' or 'bool'" },
        });
    }
    {
        const source =
            \\type T0 = sampler;
            \\type T1 = texture_1d<T0>;
        ;
        try expectError(source, .{
            .msg = "invalid sampled texture component type",
            .loc = .{ .start = 40, .end = 42 },
            .note = .{ .msg = "must be 'i32', 'u32' or 'f32'" },
        });
    }
}
