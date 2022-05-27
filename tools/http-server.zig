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

    if (args.len < 4) {
        std.debug.print("Usage: http-server <application-name> <address> <port>\n", .{});
        return 0;
    }

    const application_name = args[1];
    const address = args[2];
    const port = try std.fmt.parseUnsigned(u16, args[3], 10);

    std.debug.print("Served at http://{s}:{}/{s}.html\n", .{ address, port, application_name });

    try file_server.init(allocator, .{ .dir_path = "." });
    defer file_server.deinit();

    try http.listenAndServe(
        allocator,
        try std.net.Address.parseIp(address, port),
        {},
        file_server.serve,
    );

    return 0;
}
