//! The 'mach' CLI and engine editor

const entrypoint = @import("editor/entrypoint.zig");

pub fn main() !void {
    try entrypoint.Main();
}
