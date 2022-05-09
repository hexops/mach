const std = @import("std");
const Allocator = std.mem.Allocator;
const glfw = @import("glfw");
const gpu = @import("gpu");
const App = @import("app");
const enums = @import("enums.zig");

pub const VSyncMode = enum {
    /// Potential screen tearing.
    /// No synchronization with monitor, render frames as fast as possible.
    none,

    /// No tearing, synchronizes rendering with monitor refresh rate, rendering frames when ready.
    ///
    /// Tries to stay one frame ahead of the monitor, so when it's ready for the next frame it is
    /// already prepared.
    double,

    /// No tearing, synchronizes rendering with monitor refresh rate, rendering frames when ready.
    ///
    /// Tries to stay two frames ahead of the monitor, so when it's ready for the next frame it is
    /// already prepared.
    triple,
};

/// Application options that can be configured at init time.
pub const Options = struct {
    /// The title of the window.
    title: [*:0]const u8 = "Mach engine",

    /// The width of the window.
    width: u32 = 640,

    /// The height of the window.
    height: u32 = 480,

    /// Monitor synchronization modes.
    vsync: VSyncMode = .double,

    /// GPU features required by the application.
    required_features: ?[]gpu.Feature = null,

    /// GPU limits required by the application.
    required_limits: ?gpu.Limits = null,

    /// Whether the application has a preference for low power or high performance GPU.
    power_preference: gpu.PowerPreference = .none,
};

const Engine = @This();

/// Window, events, inputs etc.
core: Core,

/// WebGPU driver - stores device, swap chains, targets and more
gpu_driver: GpuDriver,

allocator: Allocator,

options: Options,

/// The amount of time (in seconds) that has passed since the last frame was rendered.
///
/// For example, if you are animating a cube which should rotate 360 degrees every second,
/// instead of writing (360.0 / 60.0) and assuming the frame rate is 60hz, write
/// (360.0 * engine.delta_time)
delta_time: f64 = 0,
delta_time_ns: u64 = 0,
timer: std.time.Timer,

pub const Core = struct {
    internal: GetCoreInternalType(),

    pub fn setKeyCallback(core: *Core, comptime cb: fn (app: *App, engine: *Engine, key: enums.Key, action: enums.Action) void) void {
        core.internal.setKeyCallback(cb);
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

pub fn init(allocator: std.mem.Allocator, options: Options) !Engine {
    var engine = Engine{
        .allocator = allocator,
        .options = options,
        .timer = try std.time.Timer.start(),
        .core = undefined,
        .gpu_driver = undefined,
    };

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
