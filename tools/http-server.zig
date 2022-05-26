const std = @import("std");
const http = @import("apple_pie");
const file_server = http.FileServer;

pub const io_mode = .evented;

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.debug.print("Served at http://127.0.0.1:8000/{s}.html\n", .{args[1]});

    try file_server.init(allocator, .{ .dir_path = "." });
    defer file_server.deinit();

    try http.listenAndServe(
        allocator,
        try std.net.Address.parseIp("127.0.0.1", 8000),
        {},
        file_server.serve,
    );

    return 0;
}
