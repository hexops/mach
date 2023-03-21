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

// TODO: move this to cli/main.zig
pub fn printErrors(errors: []dusk.ErrorMsg, source: []const u8, file_path: ?[]const u8) !void {
    var bw = std.io.bufferedWriter(std.io.getStdErr().writer());
    const b = bw.writer();
    const term = std.debug.TTY.Config{ .escape_codes = {} };

    for (errors) |*err| {
        defer err.deinit(allocator);

        const loc_extra = err.loc.extraInfo(source);

        // 'file:line:column error: <MSG>'
        try term.setColor(b, .Bold);
        try b.print("{?s}:{d}:{d} ", .{ file_path, loc_extra.line, loc_extra.col });
        try term.setColor(b, .Red);
        try b.writeAll("error: ");
        try term.setColor(b, .Reset);
        try term.setColor(b, .Bold);
        try b.writeAll(err.msg);
        try b.writeByte('\n');

        try printCode(b, term, source, err.loc);

        // note
        if (err.note) |note| {
            if (note.loc) |note_loc| {
                const note_loc_extra = note_loc.extraInfo(source);

                try term.setColor(b, .Reset);
                try term.setColor(b, .Bold);
                try b.print("{?s}:{d}:{d} ", .{ file_path, note_loc_extra.line, note_loc_extra.col });
            }
            try term.setColor(b, .Cyan);
            try b.writeAll("note: ");

            try term.setColor(b, .Reset);
            try term.setColor(b, .Bold);
            try b.writeAll(note.msg);
            try b.writeByte('\n');

            if (note.loc) |note_loc| {
                try printCode(b, term, source, note_loc);
            }
        }

        try term.setColor(b, .Reset);
    }
    try bw.flush();
}

fn printCode(writer: anytype, term: std.debug.TTY.Config, source: []const u8, loc: dusk.Token.Loc) !void {
    const loc_extra = loc.extraInfo(source);
    try term.setColor(writer, .Dim);
    try writer.print("{d} │ ", .{loc_extra.line});
    try term.setColor(writer, .Reset);
    try writer.writeAll(source[loc_extra.line_start..loc.start]);
    try term.setColor(writer, .Green);
    try writer.writeAll(source[loc.start..loc.end]);
    try term.setColor(writer, .Reset);
    try writer.writeAll(source[loc.end..loc_extra.line_end]);
    try writer.writeByte('\n');

    // location pointer
    const line_number_len = (std.math.log10(loc_extra.line) + 1) + 3;
    try writer.writeByteNTimes(
        ' ',
        line_number_len + (loc_extra.col - 1),
    );
    try term.setColor(writer, .Bold);
    try term.setColor(writer, .Green);
    try writer.writeByte('^');
    try writer.writeByteNTimes('~', loc.end - loc.start - 1);
    try writer.writeByte('\n');
}

fn expectIR(source: [:0]const u8) !dusk.IR {
    var res = try dusk.Ast.parse(allocator, source);
    switch (res) {
        .tree => |*tree| {
            defer tree.deinit(allocator);
            switch (try dusk.IR.generate(allocator, tree)) {
                .ir => |ir| return ir,
                .errors => |err_msgs| {
                    try printErrors(err_msgs, source, null);
                    allocator.free(err_msgs);
                    return error.ExpectedIR;
                },
            }
        },
        .errors => |err_msgs| {
            try printErrors(err_msgs, source, null);
            allocator.free(err_msgs);
            return error.Parsing;
        },
    }
}

fn expectError(source: [:0]const u8, err: dusk.ErrorMsg) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 12 }){};
    const all = gpa.allocator();
    defer _ = gpa.deinit();
    var res = try dusk.Ast.parse(all, source);
    const err_list = switch (res) {
        .tree => |*tree| blk: {
            defer tree.deinit(all);
            switch (try dusk.IR.generate(all, tree)) {
                .ir => |*ir| {
                    ir.deinit();
                    return error.ExpectedError;
                },
                .errors => |err_msgs| break :blk err_msgs,
            }
            return error.ExpectedError;
        },
        .errors => |err_msgs| err_msgs,
    };
    defer {
        for (err_list) |*err_msg| err_msg.deinit(all);
        all.free(err_list);
    }
    {
        errdefer {
            std.debug.print(
                "\n\x1b[31mexpected error({d}..{d}):\n{s}\n\x1b[32mactual error({d}..{d}):\n{s}\n\x1b[0m",
                .{
                    err.loc.start,         err.loc.end,         err.msg,
                    err_list[0].loc.start, err_list[0].loc.end, err_list[0].msg,
                },
            );
        }
        try expect(std.mem.eql(u8, err.msg, err_list[0].msg));
        try expect(err_list[0].loc.start == err.loc.start);
        try expect(err_list[0].loc.end == err.loc.end);
    }
    if (err_list[0].note) |_| {
        errdefer {
            std.debug.print(
                "\n\x1b[31mexpected note msg:\n{s}\n\x1b[32mactual note msg:\n{s}\n\x1b[0m",
                .{ err.note.?.msg, err_list[0].note.?.msg },
            );
        }
        if (err.note == null) {
            std.debug.print("\x1b[31mnote missed: {s}\x1b[0m\n", .{err_list[0].note.?.msg});
            return error.NoteMissed;
        }
        try expect(std.mem.eql(u8, err.note.?.msg, err_list[0].note.?.msg));
        if (err_list[0].note.?.loc) |_| {
            errdefer {
                std.debug.print(
                    "\n\x1b[31mexpected note loc: {d}..{d}\n\x1b[32mactual note loc: {d}..{d}\n\x1b[0m",
                    .{
                        err.note.?.loc.?.start,         err.note.?.loc.?.end,
                        err_list[0].note.?.loc.?.start, err_list[0].note.?.loc.?.end,
                    },
                );
            }
            try expect(err_list[0].note.?.loc.?.start == err.note.?.loc.?.start);
            try expect(err_list[0].note.?.loc.?.end == err.note.?.loc.?.end);
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
