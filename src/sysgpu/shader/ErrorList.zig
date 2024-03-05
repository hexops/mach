const std = @import("std");
const Token = @import("Token.zig");
pub const ErrorList = @This();

pub const ErrorMsg = struct {
    loc: Token.Loc,
    msg: []const u8,
    note: ?Note = null,

    pub const Note = struct {
        loc: ?Token.Loc = null,
        msg: []const u8,
    };
};

arena: std.heap.ArenaAllocator,
list: std.ArrayListUnmanaged(ErrorMsg) = .{},

pub fn init(allocator: std.mem.Allocator) !ErrorList {
    return .{
        .arena = std.heap.ArenaAllocator.init(allocator),
    };
}

pub fn deinit(self: *ErrorList) void {
    self.arena.deinit();
    self.* = undefined;
}

pub fn add(
    self: *ErrorList,
    loc: Token.Loc,
    comptime format: []const u8,
    args: anytype,
    note: ?ErrorMsg.Note,
) !void {
    const err_msg = .{
        .loc = loc,
        .msg = try std.fmt.allocPrint(self.arena.allocator(), comptime format, args),
        .note = note,
    };
    try self.list.append(self.arena.allocator(), err_msg);
}

pub fn createNote(
    self: *ErrorList,
    loc: ?Token.Loc,
    comptime format: []const u8,
    args: anytype,
) !ErrorMsg.Note {
    return .{
        .loc = loc,
        .msg = try std.fmt.allocPrint(self.arena.allocator(), comptime format, args),
    };
}

pub fn print(self: ErrorList, source: []const u8, file_path: ?[]const u8) !void {
    const stderr = std.io.getStdErr();
    var bw = std.io.bufferedWriter(stderr.writer());
    const b = bw.writer();
    const term = std.io.tty.detectConfig(stderr);

    for (self.list.items) |*err| {
        const loc_extra = err.loc.extraInfo(source);

        // 'file:line:column error: MSG'
        try term.setColor(b, .bold);
        try b.print("{?s}:{d}:{d} ", .{ file_path, loc_extra.line, loc_extra.col });
        try term.setColor(b, .bright_red);
        try b.writeAll("error: ");
        try term.setColor(b, .reset);
        try term.setColor(b, .bold);
        try b.writeAll(err.msg);
        try b.writeByte('\n');

        try printCode(b, term, source, err.loc);

        // note
        if (err.note) |note| {
            if (note.loc) |note_loc| {
                const note_loc_extra = note_loc.extraInfo(source);

                try term.setColor(b, .reset);
                try term.setColor(b, .bold);
                try b.print("{?s}:{d}:{d} ", .{ file_path, note_loc_extra.line, note_loc_extra.col });
            }
            try term.setColor(b, .cyan);
            try b.writeAll("note: ");

            try term.setColor(b, .reset);
            try term.setColor(b, .bold);
            try b.writeAll(note.msg);
            try b.writeByte('\n');

            if (note.loc) |note_loc| {
                try printCode(b, term, source, note_loc);
            }
        }

        try term.setColor(b, .reset);
    }
    try bw.flush();
}

fn printCode(writer: anytype, term: std.io.tty.Config, source: []const u8, loc: Token.Loc) !void {
    const loc_extra = loc.extraInfo(source);
    try term.setColor(writer, .dim);
    try writer.print("{d} │ ", .{loc_extra.line});
    try term.setColor(writer, .reset);
    try writer.writeAll(source[loc_extra.line_start..loc.start]);
    try term.setColor(writer, .green);
    try writer.writeAll(source[loc.start..loc.end]);
    try term.setColor(writer, .reset);
    try writer.writeAll(source[loc.end..loc_extra.line_end]);
    try writer.writeByte('\n');

    // location pointer
    const line_number_len = (std.math.log10(loc_extra.line) + 1) + 3;
    try writer.writeByteNTimes(
        ' ',
        line_number_len + (loc_extra.col - 1),
    );
    try term.setColor(writer, .bold);
    try term.setColor(writer, .green);
    try writer.writeByte('^');
    try writer.writeByteNTimes('~', loc.end - loc.start - 1);
    try writer.writeByte('\n');
}
