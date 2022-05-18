const gpu = @import("gpu");
const enums = @import("enums.zig");

pub const Size = struct {
    width: u32,
    height: u32,
};

pub const SizeOptional = struct {
    width: ?u32,
    height: ?u32,
};

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

pub const Event = union(enum) {
    key_press: struct {
        key: enums.Key,
    },
    key_release: struct {
        key: enums.Key,
    },
};
