const builtin = @import("builtin");

const Platform = if (builtin.cpu.arch == .wasm32) @import("platform/wasm.zig") else @import("platform/native.zig");

// TODO: verify declarations and its signatures
pub const Type = Platform.Platform;
pub const BackingTimerType = Platform.BackingTimer;
