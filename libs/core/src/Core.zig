const builtin = @import("builtin");
const std = @import("std");
const gpu = @import("gpu");
const platform = @import("platform.zig");

pub const Core = @This();

internal: platform.Core,

pub const Options = struct {
    is_app: bool = false,
    title: [*:0]const u8 = "Mach Engine",
    size: Size = .{ .width = 640, .height = 640 },
    power_preference: gpu.PowerPreference = .undefined,
    required_features: ?[]const gpu.FeatureName = null,
    required_limits: ?gpu.Limits = null,
};

pub fn init(core: *Core, allocator: std.mem.Allocator, options: Options) !void {
    try platform.Core.init(&core.internal, allocator, options);
}

pub fn deinit(core: *Core) void {
    return core.internal.deinit();
}

pub const EventIterator = struct {
    internal: platform.Core.EventIterator,

    pub inline fn next(self: *EventIterator) ?Event {
        return self.internal.next();
    }
};

pub inline fn pollEvents(core: *Core) EventIterator {
    return .{ .internal = core.internal.pollEvents() };
}

/// Returns the framebuffer size, in subpixel units.
pub fn framebufferSize(core: *Core) Size {
    return core.internal.framebufferSize();
}

/// Sets seconds to wait for an event with timeout when calling `Core.update()`
/// again.
///
/// timeout is in seconds (<= `0.0` disables waiting)
/// - pass `std.math.inf(f64)` to wait with no timeout
///
/// `Core.update()` will return earlier than timeout if an event happens (key press,
/// mouse motion, etc.)
///
/// `Core.update()` can return a bit later than timeout due to timer precision and
/// process scheduling.
pub fn setWaitTimeout(core: *Core, timeout: f64) void {
    return core.internal.setWaitTimeout(timeout);
}

/// Set the window title
pub fn setTitle(core: *Core, title: [:0]const u8) void {
    return core.internal.setTitle(title);
}

/// Set the window mode
pub fn setDisplayMode(core: *Core, mode: DisplayMode, monitor: ?usize) void {
    return core.internal.setDisplayMode(mode, monitor);
}

/// Returns the window mode
pub fn displayMode(core: *Core) DisplayMode {
    return core.internal.displayMode();
}

pub fn setBorder(core: *Core, value: bool) void {
    return core.internal.setBorder(value);
}

pub fn border(core: *Core) bool {
    return core.internal.border();
}

pub fn setHeadless(core: *Core, value: bool) void {
    return core.internal.setHeadless(value);
}

pub fn headless(core: *Core) bool {
    return core.internal.headless();
}

pub const VSyncMode = enum {
    /// Potential screen tearing.
    /// No synchronization with monitor, render frames as fast as possible.
    ///
    /// Not available on WASM, fallback to double
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
    ///
    /// Not available on WASM, fallback to double
    triple,
};

/// Set monitor synchronization mode.
pub fn setVSync(core: *Core, mode: VSyncMode) void {
    return core.internal.setVSync(mode);
}

/// Returns monitor synchronization mode.
pub fn vsync(core: *Core) VSyncMode {
    return core.internal.vsync();
}

/// Set the window size, in subpixel units.
pub fn setSize(core: *Core, value: Size) void {
    return core.internal.setSize(value);
}

/// Returns the window size, in subpixel units.
pub fn size(core: *Core) Size {
    return core.internal.size();
}

/// Set the minimum and maximum allowed size for the window.
pub fn setSizeLimit(core: *Core, size_limit: SizeLimit) void {
    return core.internal.setSizeLimit(size_limit);
}

/// Returns the minimum and maximum allowed size for the window.
pub fn sizeLimit(core: *Core) SizeLimit {
    return core.internal.sizeLimit();
}

pub fn setCursorMode(core: *Core, mode: CursorMode) void {
    return core.internal.setCursorMode(mode);
}

pub fn cursorMode(core: *Core) CursorMode {
    return core.internal.cursorMode();
}

pub fn setCursorShape(core: *Core, cursor: CursorShape) void {
    return core.internal.setCursorShape(cursor);
}

pub fn cursorShape(core: *Core) CursorShape {
    return core.internal.cursorShape();
}

pub fn adapter(core: *Core) *gpu.Adapter {
    return core.internal.adapter();
}

pub fn device(core: *Core) *gpu.Device {
    return core.internal.device();
}

pub fn swapChain(core: *Core) *gpu.SwapChain {
    return core.internal.swapChain();
}

pub fn descriptor(core: *Core) gpu.SwapChain.Descriptor {
    return core.internal.descriptor();
}

pub const Size = struct {
    width: u32,
    height: u32,
};

pub const SizeOptional = struct {
    width: ?u32,
    height: ?u32,
};

pub const SizeLimit = struct {
    min: SizeOptional,
    max: SizeOptional,
};

pub const Position = struct {
    x: f64,
    y: f64,
};

pub const Event = union(enum) {
    key_press: KeyEvent,
    key_repeat: KeyEvent,
    key_release: KeyEvent,
    char_input: struct {
        codepoint: u21,
    },
    mouse_motion: struct {
        pos: Position,
    },
    mouse_press: MouseButtonEvent,
    mouse_release: MouseButtonEvent,
    mouse_scroll: struct {
        xoffset: f32,
        yoffset: f32,
    },
    framebuffer_resize: Size,
    focus_gained,
    focus_lost,
    close,
};

pub const KeyEvent = struct {
    key: Key,
    mods: KeyMods,
};

pub const MouseButtonEvent = struct {
    button: MouseButton,
    pos: Position,
    mods: KeyMods,
};

pub const MouseButton = enum {
    left,
    right,
    middle,
    four,
    five,
    six,
    seven,
    eight,
};

pub const Key = enum {
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,

    zero,
    one,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,

    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
    f13,
    f14,
    f15,
    f16,
    f17,
    f18,
    f19,
    f20,
    f21,
    f22,
    f23,
    f24,
    f25,

    kp_divide,
    kp_multiply,
    kp_subtract,
    kp_add,
    kp_0,
    kp_1,
    kp_2,
    kp_3,
    kp_4,
    kp_5,
    kp_6,
    kp_7,
    kp_8,
    kp_9,
    kp_decimal,
    kp_equal,
    kp_enter,

    enter,
    escape,
    tab,
    left_shift,
    right_shift,
    left_control,
    right_control,
    left_alt,
    right_alt,
    left_super,
    right_super,
    menu,
    num_lock,
    caps_lock,
    print,
    scroll_lock,
    pause,
    delete,
    home,
    end,
    page_up,
    page_down,
    insert,
    left,
    right,
    up,
    down,
    backspace,
    space,
    minus,
    equal,
    left_bracket,
    right_bracket,
    backslash,
    semicolon,
    apostrophe,
    comma,
    period,
    slash,
    grave,

    unknown,
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

pub const DisplayMode = enum {
    /// Windowed mode.
    windowed,

    /// Fullscreen mode, using this option may change the display's video mode.
    fullscreen,

    /// Borderless fullscreen window.
    ///
    /// Beware that true .fullscreen is also a hint to the OS that is used in various contexts, e.g.
    ///
    /// * macOS: Moving to a virtual space dedicated to fullscreen windows as the user expects
    /// * macOS: .borderless windows cannot prevent the system menu bar from being displayed
    ///
    /// Always allow users to choose their preferred display mode.
    borderless,
};

pub const CursorMode = enum {
    /// Makes the cursor visible and behaving normally.
    normal,

    /// Makes the cursor invisible when it is over the content area of the window but does not
    /// restrict it from leaving.
    hidden,

    /// Hides and grabs the cursor, providing virtual and unlimited cursor movement. This is useful
    /// for implementing for example 3D camera controls.
    disabled,
};

pub const CursorShape = enum {
    arrow,
    ibeam,
    crosshair,
    pointing_hand,
    resize_ew,
    resize_ns,
    resize_nwse,
    resize_nesw,
    resize_all,
    not_allowed,
};
