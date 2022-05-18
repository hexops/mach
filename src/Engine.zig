const std = @import("std");
const Allocator = std.mem.Allocator;
const glfw = @import("glfw");
const gpu = @import("gpu");
const structs = @import("structs.zig");
const enums = @import("enums.zig");
const Timer = @import("Timer.zig");

const Engine = @This();

/// Window, events, inputs etc.
core: Core,

/// WebGPU driver - stores device, swap chains, targets and more
gpu_driver: GpuDriver,

allocator: Allocator,

options: structs.Options,

/// The amount of time (in seconds) that has passed since the last frame was rendered.
///
/// For example, if you are animating a cube which should rotate 360 degrees every second,
/// instead of writing (360.0 / 60.0) and assuming the frame rate is 60hz, write
/// (360.0 * engine.delta_time)
delta_time: f32 = 0,
delta_time_ns: u64 = 0,
timer: Timer,

pub const Core = struct {
    internal: GetCoreInternalType(),

    pub fn setShouldClose(core: *Core, value: bool) void {
        core.internal.setShouldClose(value);
    }

    pub fn getFramebufferSize(core: *Core) !structs.Size {
        return core.internal.getFramebufferSize();
    }

    pub fn setSizeLimits(core: *Core, min: structs.SizeOptional, max: structs.SizeOptional) !void {
        return core.internal.setSizeLimits(min, max);
    }

    pub fn pollEvent(core: *Core) ?structs.Event {
        return core.internal.pollEvent();
    }
};

pub const GpuDriver = struct {
    internal: GetGpuDriverInternalType(),

    device: gpu.Device,
    backend_type: gpu.Adapter.BackendType,
    swap_chain: ?gpu.SwapChain,
    swap_chain_format: gpu.Texture.Format,

    surface: ?gpu.Surface,
    current_desc: gpu.SwapChain.Descriptor,
    target_desc: gpu.SwapChain.Descriptor,
};

pub fn init(allocator: std.mem.Allocator, options: structs.Options) !Engine {
    var engine = Engine{
        .allocator = allocator,
        .options = options,
        .timer = try Timer.start(),
        .core = undefined,
        .gpu_driver = undefined,
    };

    // Note: if in future, there is a conflict in init() signature of different backends,
    // move these calls to the entry point file, which is native.zig for Glfw, for example
    engine.core.internal = try GetCoreInternalType().init(allocator, &engine);
    engine.gpu_driver.internal = try GetGpuDriverInternalType().init(allocator, &engine);

    return engine;
}

fn GetCoreInternalType() type {
    return @import("native.zig").CoreGlfw;
}

fn GetGpuDriverInternalType() type {
    return @import("native.zig").GpuDriverNative;
}
