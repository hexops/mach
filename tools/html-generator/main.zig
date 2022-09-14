const std = @import("std");

const source = @embedFile("template.html");
const app_name_needle = "{ app_name }";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: html-generator <output-name> <app-name>\n", .{});
        return;
    }

    const output_name = args[1];
    const app_name = args[2];

    const file = try std.fs.cwd().createFile(output_name, .{});
    defer file.close();
    var buf = try allocator.alloc(u8, std.mem.replacementSize(u8, source, app_name_needle, app_name));
    defer allocator.free(buf);

    _ = std.mem.replace(u8, source, app_name_needle, app_name, buf);
    _ = try file.write(buf);
}
