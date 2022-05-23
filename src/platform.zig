const builtin = @import("builtin");

const Platform = if (builtin.cpu.arch == .wasm32) @import("wasm.zig") else @import("native.zig");

// TODO: verify declarations and its signatures
pub const CoreType = Platform.Core;
pub const GpuDriverType = Platform.GpuDriver;
pub const BackingTimerType = Platform.BackingTimer;
