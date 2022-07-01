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

/// Application options that can be configured at init time.
pub const StartupOptions = struct {};

/// Application options that can be configured at run time.
pub const Options = struct {
    /// The title of the window.
    title: [*:0]const u8 = "Mach engine",

    /// The width of the window.
    width: u32 = 640,

    /// The height of the window.
    height: u32 = 480,

    /// The minimum allowed size for the window.
    size_min: SizeOptional = .{ .width = null, .height = null },

    /// The maximum allowed size for the window.
    size_max: SizeOptional = .{ .width = null, .height = null },

    /// Fullscreen window.
    fullscreen: bool = false,

    /// Monitor synchronization modes.
    vsync: enums.VSyncMode = .double,

    /// GPU features required by the application.
    required_features: ?[]gpu.Feature = null,

    /// GPU limits required by the application.
    required_limits: ?gpu.Limits = null,

    /// Whether the application has a preference for low power or high performance GPU.
    power_preference: gpu.PowerPreference = .none,
};

pub const Event = union(enum) {
    key_press: KeyEvent,
    key_repeat: KeyEvent,
    key_release: KeyEvent,
    char_input: struct {
        codepoint: u21,
    },
    mouse_motion: struct {
        pos: WindowPos,
    },
    mouse_press: MouseButtonEvent,
    mouse_release: MouseButtonEvent,
    mouse_scroll: struct {
        xoffset: f32,
        yoffset: f32,
    },
    focus_gained,
    focus_lost,
    closed,
};

pub const KeyEvent = struct {
    key: enums.Key,
    mods: KeyMods,
};

pub const MouseButtonEvent = struct {
    button: enums.MouseButton,
    pos: WindowPos,
    mods: KeyMods,
};

pub const KeyMods = packed struct {
    shift: bool,
    control: bool,
    alt: bool,
    super: bool,
    caps_lock: bool,
    num_lock: bool,
    _reserved: u2 = 0,
};

pub const WindowPos = struct {
    // These are in window coordinates (not framebuffer coords)
    x: f64,
    y: f64,
};
