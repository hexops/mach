pub usingnamespace @import("entry.zig");
pub const Core = @import("Core.zig");
pub const Timer = @import("Timer.zig");
pub const gpu = @import("gpu");
pub const sysjs = @import("sysjs");

test {
    _ = @import("platform/libmachcore.zig");
    _ = @import("platform/libmachcore_app.zig");
}
