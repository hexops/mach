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

fn expectTree(source: [:0]const u8) !dusk.Ast {
    var res = try dusk.Ast.parse(allocator, source);
    switch (res) {
        .tree => |*tree| {
            errdefer tree.deinit(allocator);
            if (try tree.analyse(allocator)) |errors| {
                try printErrors(errors, source, null);
                allocator.free(errors);
                return error.Analysing;
            }
            return tree.*;
        },
        .errors => |err_msgs| {
            try printErrors(err_msgs, source, null);
            allocator.free(err_msgs);
            return error.Parsing;
        },
    }
}

test "empty" {
    const source = "";
    var tree = try expectTree(source);
    defer tree.deinit(allocator);
}

test "boids" {
    const source = @embedFile("boids.wgsl");
    var tree = try expectTree(source);
    defer tree.deinit(allocator);
}

test "gkurve" {
    if (true) return error.SkipZigTest;

    const source = @embedFile("gkurve.wgsl");
    var tree = try expectTree(source);
    defer tree.deinit(allocator);
}

test "variable & expressions" {
    const source = "var expr = 1 + 5 + 2 * 3 > 6 >> 7;";

    var tree = try expectTree(source);
    defer tree.deinit(allocator);

    const root_node = 0;
    try expect(tree.nodeLHS(root_node) + 1 == tree.nodeRHS(root_node));

    const variable = tree.spanToList(root_node)[0];
    const variable_name = tree.tokenLoc(tree.extraData(dusk.Ast.Node.GlobalVarDecl, tree.nodeLHS(variable)).name);
    try expect(std.mem.eql(u8, "expr", variable_name.slice(source)));
    try expect(tree.nodeTag(variable) == .global_variable);
    try expect(tree.tokenTag(tree.nodeToken(variable)) == .k_var);

    const expr = tree.nodeRHS(variable);
    try expect(tree.nodeTag(expr) == .greater);

    const @"1 + 5 + 2 * 3" = tree.nodeLHS(expr);
    try expect(tree.nodeTag(@"1 + 5 + 2 * 3") == .add);

    const @"1 + 5" = tree.nodeLHS(@"1 + 5 + 2 * 3");
    try expect(tree.nodeTag(@"1 + 5") == .add);

    const @"1" = tree.nodeLHS(@"1 + 5");
    try expect(tree.nodeTag(@"1") == .number_literal);

    const @"5" = tree.nodeRHS(@"1 + 5");
    try expect(tree.nodeTag(@"5") == .number_literal);

    const @"2 * 3" = tree.nodeRHS(@"1 + 5 + 2 * 3");
    try expect(tree.nodeTag(@"2 * 3") == .mul);

    const @"6 >> 7" = tree.nodeRHS(expr);
    try expect(tree.nodeTag(@"6 >> 7") == .shift_right);

    const @"6" = tree.nodeLHS(@"6 >> 7");
    try expect(tree.nodeTag(@"6") == .number_literal);

    const @"7" = tree.nodeRHS(@"6 >> 7");
    try expect(tree.nodeTag(@"7") == .number_literal);
}
