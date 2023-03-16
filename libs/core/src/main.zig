pub const Core = @import("Core.zig");
pub const Timer = @import("Timer.zig");
pub const gpu = @import("gpu");
pub const sysjs = @import("sysjs");
const builtin = @import("builtin");
pub const platform_util = if (builtin.cpu.arch == .wasm32) {} else @import("platform/native/util.zig");

test {
    _ = @import("platform/libmachcore.zig");
    _ = @import("platform/libmachcore_app.zig");
}
