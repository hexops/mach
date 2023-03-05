const std = @import("std");

pub const Ast = @import("Ast.zig");
pub const Analyse = @import("Analyse.zig");
pub const Parser = @import("Parser.zig");
pub const Token = @import("Token.zig");
pub const Tokenizer = @import("Tokenizer.zig");

pub const Extension = enum {
    f16,

    pub const Array = std.enums.EnumArray(Extension, bool);
};

pub const ErrorMsg = struct {
    loc: Token.Loc,
    msg: []const u8,
    note: ?Note,

    pub const Note = struct {
        loc: ?Token.Loc,
        msg: []const u8,

        pub fn create(
            allocator: std.mem.Allocator,
            loc: ?Token.Loc,
            comptime format: []const u8,
            args: anytype,
        ) !Note {
            return .{
                .loc = loc,
                .msg = try std.fmt.allocPrint(allocator, comptime format, args),
            };
        }

        pub fn deinit(note: *Note, allocator: std.mem.Allocator) void {
            allocator.free(note.msg);
            note.* = undefined;
        }
    };

    pub fn create(
        allocator: std.mem.Allocator,
        loc: Token.Loc,
        comptime format: []const u8,
        args: anytype,
        note: ?Note,
    ) !ErrorMsg {
        return .{
            .loc = loc,
            .msg = try std.fmt.allocPrint(allocator, comptime format, args),
            .note = note,
        };
    }

    pub fn deinit(err_msg: *ErrorMsg, allocator: std.mem.Allocator) void {
        if (err_msg.note) |*note| note.*.deinit(allocator);
        allocator.free(err_msg.msg);
        err_msg.* = undefined;
    }
};
