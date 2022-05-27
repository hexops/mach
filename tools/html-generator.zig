const std = @import("std");

const source = @embedFile("../www/template.html");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: html-generator <output-name> <application-name>\n", .{});
        return;
    }

    const output_name = args[1];
    const application_name = args[2];

    const file = try std.fs.cwd().createFile(output_name, std.fs.File.CreateFlags{});
    defer file.close();

    const writer = file.writer();
    try std.fmt.format(writer, source, .{application_name});
}
