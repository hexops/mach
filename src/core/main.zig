const std = @import("std");
const builtin = @import("builtin");

pub const sysgpu = @import("../main.zig").sysgpu;
pub const sysjs = @import("mach-sysjs");
pub const Timer = @import("Timer.zig");
const Frequency = @import("Frequency.zig");
const platform = @import("platform.zig");

/// Returns the error set that the function F returns.
fn ErrorSet(comptime F: type) type {
    return @typeInfo(@typeInfo(F).Fn.return_type.?).ErrorUnion.error_set;
}

/// Comptime options that you can configure in your main file by writing e.g.:
///
/// ```
/// pub const mach_core_options = core.ComptimeOptions{
///     .use_wgpu = true,
///     .use_sysgpu = true,
/// };
/// ```
pub const ComptimeOptions = struct {
    /// Whether to use
    use_wgpu: bool = true,

    /// Whether or not to use the experimental sysgpu graphics API.
    use_sysgpu: bool = false,
};

pub const options = if (@hasDecl(@import("root"), "mach_core_options"))
    @import("root").mach_core_options
else
    ComptimeOptions{};

pub const wgpu = @import("mach-gpu");

pub const gpu = if (options.use_sysgpu) sysgpu.sysgpu else wgpu;

pub fn AppInterface(comptime app_entry: anytype) void {
    if (!@hasDecl(app_entry, "App")) {
        @compileError("expected e.g. `pub const App = mach.App(modules, init)' (App definition missing in your main Zig file)");
    }

    const App = app_entry.App;
    if (@typeInfo(App) != .Struct) {
        @compileError("App must be a struct type. Found:" ++ @typeName(App));
    }

    if (@hasDecl(App, "init")) {
        const InitFn = @TypeOf(@field(App, "init"));
        if (InitFn != fn (app: *App) ErrorSet(InitFn)!void)
            @compileError("expected 'pub fn init(app: *App) !void' found '" ++ @typeName(InitFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn init(app: *App) !void'");
    }

    if (@hasDecl(App, "update")) {
        const UpdateFn = @TypeOf(@field(App, "update"));
        if (UpdateFn != fn (app: *App) ErrorSet(UpdateFn)!bool)
            @compileError("expected 'pub fn update(app: *App) !bool' found '" ++ @typeName(UpdateFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn update(app: *App) !bool'");
    }

    if (@hasDecl(App, "updateMainThread")) {
        const UpdateMainThreadFn = @TypeOf(@field(App, "updateMainThread"));
        if (UpdateMainThreadFn != fn (app: *App) ErrorSet(UpdateMainThreadFn)!bool)
            @compileError("expected 'pub fn updateMainThread(app: *App) !bool' found '" ++ @typeName(UpdateMainThreadFn) ++ "'");
    }

    if (@hasDecl(App, "deinit")) {
        const DeinitFn = @TypeOf(@field(App, "deinit"));
        if (DeinitFn != fn (app: *App) void)
            @compileError("expected 'pub fn deinit(app: *App) void' found '" ++ @typeName(DeinitFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn deinit(app: *App) void'");
    }
}

/// wasm32: custom std.log implementation which logs to the browser console.
/// other: std.log.defaultLog
pub const defaultLog = platform.Core.defaultLog;

/// wasm32: custom @panic implementation which logs to the browser console.
/// other: std.debug.default_panic
pub const defaultPanic = platform.Core.defaultPanic;

/// The allocator used by mach-core for any allocations. Must be specified before the first call to
/// core.init()
pub var allocator: std.mem.Allocator = undefined;

/// A buffer which you may use to write the window title to. See core.setTitle() for details.
pub var title: [256:0]u8 = undefined;

/// May be read inside `App.init`, `App.update`, and `App.deinit`.
///
/// No synchronization is performed, so these fields may not be accessed in `App.updateMainThread`.
pub var adapter: *gpu.Adapter = undefined;
pub var device: *gpu.Device = undefined;
pub var queue: *gpu.Queue = undefined;
pub var swap_chain: *gpu.SwapChain = undefined;
pub var descriptor: gpu.SwapChain.Descriptor = undefined;

/// The time in seconds between the last frame and the current frame.
///
/// Higher frame rates will report higher values, for example if your application is running at
/// 60FPS this will report 0.01666666666 (1.0 / 60) seconds, and if it is running at 30FPS it will
/// report twice that, 0.03333333333 (1.0 / 30.0) seconds.
///
/// For example, instead of rotating an object 360 degrees every frame `rotation += 6.0` (one full
/// rotation every second, but only if your application is running at 60FPS) you may instead multiply
/// by this number `rotation += 360.0 * core.delta_time` which results in one full rotation every
/// second, no matter what frame rate the application is running at.
pub var delta_time: f32 = 0;
pub var delta_time_ns: u64 = 0;

var frame: Frequency = undefined;
var input: Frequency = undefined;
var internal: platform.Core = undefined;

/// All memory will be copied or returned to the caller once init() finishes.
pub const Options = struct {
    is_app: bool = false,
    headless: bool = false,
    display_mode: DisplayMode = .windowed,
    border: bool = true,
    title: [:0]const u8 = "Mach core",
    size: Size = .{ .width = 1920 / 2, .height = 1080 / 2 },
    power_preference: gpu.PowerPreference = .undefined,
    required_features: ?[]const gpu.FeatureName = null,
    required_limits: ?gpu.Limits = null,
    swap_chain_usage: gpu.Texture.UsageFlags = .{ .render_attachment = true, },
};

pub fn init(options_in: Options) !void {
    // Copy window title into owned buffer.
    var opt = options_in;
    if (opt.title.len < title.len) {
        @memcpy(title[0..opt.title.len], opt.title);
        title[opt.title.len] = 0;
        opt.title = title[0..opt.title.len :0];
    }

    frame = .{
        .target = 0,
        .delta_time = &delta_time,
        .delta_time_ns = &delta_time_ns,
    };
    input = .{ .target = 1 };

    try platform.Core.init(
        &internal,
        allocator,
        &frame,
        &input,
        opt,
    );
}

pub inline fn deinit() void {
    return internal.deinit();
}

pub inline fn update(app_ptr: anytype) !bool {
    return try internal.update(app_ptr);
}

pub const EventIterator = struct {
    internal: platform.Core.EventIterator,

    pub inline fn next(self: *EventIterator) ?Event {
        return self.internal.next();
    }
};

pub inline fn pollEvents() EventIterator {
    return .{ .internal = internal.pollEvents() };
}

/// Sets the window title. The string must be owned by Core, and will not be copied or freed. It is
/// advised to use the `core.title` buffer for this purpose, e.g.:
///
/// ```
/// const title = try std.fmt.bufPrintZ(&core.title, "Hello, world!", .{});
/// core.setTitle(title);
/// ```
pub inline fn setTitle(value: [:0]const u8) void {
    return internal.setTitle(value);
}

/// Sets the window title. Uses the `core.title` buffer.
pub inline fn printTitle(fmt: []const u8, args: anytype) !void {
    const value = try std.fmt.bufPrintZ(&title, fmt, args);
    return internal.setTitle(value);
}

/// Set the window mode
pub inline fn setDisplayMode(mode: DisplayMode) void {
    return internal.setDisplayMode(mode);
}

/// Returns the window mode
pub inline fn displayMode() DisplayMode {
    return internal.displayMode();
}

pub inline fn setBorder(value: bool) void {
    return internal.setBorder(value);
}

pub inline fn border() bool {
    return internal.border();
}

pub inline fn setHeadless(value: bool) void {
    return internal.setHeadless(value);
}

pub inline fn headless() bool {
    return internal.headless();
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

/// Set refresh rate synchronization mode. Default `.triple`
///
/// Calling this function also implicitly calls setFrameRateLimit for you:
/// ```
/// .none   => setFrameRateLimit(0) // unlimited
/// .double => setFrameRateLimit(0) // unlimited
/// .triple => setFrameRateLimit(2 * max_monitor_refresh_rate)
/// ```
pub inline fn setVSync(mode: VSyncMode) void {
    return internal.setVSync(mode);
}

/// Returns refresh rate synchronization mode.
pub inline fn vsync() VSyncMode {
    return internal.vsync();
}

/// Sets the frame rate limit. Default 0 (unlimited)
///
/// This is applied *in addition* to the vsync mode.
pub inline fn setFrameRateLimit(limit: u32) void {
    frame.target = limit;
}

/// Returns the frame rate limit, or zero if unlimited.
pub inline fn frameRateLimit() u32 {
    return frame.target;
}

/// Set the window size, in subpixel units.
pub inline fn setSize(value: Size) void {
    return internal.setSize(value);
}

/// Returns the window size, in subpixel units.
pub inline fn size() Size {
    return internal.size();
}

/// Set the minimum and maximum allowed size for the window.
pub inline fn setSizeLimit(size_limit: SizeLimit) void {
    return internal.setSizeLimit(size_limit);
}

/// Returns the minimum and maximum allowed size for the window.
pub inline fn sizeLimit() SizeLimit {
    return internal.sizeLimit();
}

pub inline fn setCursorMode(mode: CursorMode) void {
    return internal.setCursorMode(mode);
}

pub inline fn cursorMode() CursorMode {
    return internal.cursorMode();
}

pub inline fn setCursorShape(cursor: CursorShape) void {
    return internal.setCursorShape(cursor);
}

pub inline fn cursorShape() CursorShape {
    return internal.cursorShape();
}

// TODO(feature): add joystick/gamepad support https://github.com/hexops/mach/issues/884

// /// Checks if the given joystick is still connected.
// pub inline fn joystickPresent(joystick: Joystick) bool {
//     return internal.joystickPresent(joystick);
// }

// /// Retreives the name of the joystick.
// /// Returns `null` if the joystick isnt connected.
// pub inline fn joystickName(joystick: Joystick) ?[:0]const u8 {
//     return internal.joystickName(joystick);
// }

// /// Retrieves the state of the buttons of the given joystick.
// /// A value of `true` indicates the button is pressed, `false` the button is released.
// /// No remapping is done, so the order of these buttons are joystick-dependent and should be
// /// consistent across platforms.
// ///
// /// Returns `null` if the joystick isnt connected.
// ///
// /// Note: For WebAssembly, the remapping is done directly by the web browser, so on that platform
// /// the order of these buttons might be different than on others.
// pub inline fn joystickButtons(joystick: Joystick) ?[]const bool {
//     return internal.joystickButtons(joystick);
// }

// /// Retreives the state of the axes of the given joystick.
// /// The values are always from -1 to 1.
// /// No remapping is done, so the order of these axes are joytstick-dependent and should be
// /// consistent acrsoss platforms.
// ///
// /// Returns `null` if the joystick isnt connected.
// ///
// /// Note: For WebAssembly, the remapping is done directly by the web browser, so on that platform
// /// the order of these axes might be different than on others.
// pub inline fn joystickAxes(joystick: Joystick) ?[]const f32 {
//     return internal.joystickAxes(joystick);
// }

pub inline fn keyPressed(key: Key) bool {
    return internal.keyPressed(key);
}

pub inline fn keyReleased(key: Key) bool {
    return internal.keyReleased(key);
}

pub inline fn mousePressed(button: MouseButton) bool {
    return internal.mousePressed(button);
}

pub inline fn mouseReleased(button: MouseButton) bool {
    return internal.mouseReleased(button);
}

pub inline fn mousePosition() Position {
    return internal.mousePosition();
}

/// Whether mach core has run out of memory. If true, freeing memory should restore it to a
/// functional state.
///
/// Once called, future calls will return false until another OOM error occurs.
///
/// Note that if an App.update function returns any error, including errors.OutOfMemory, it will
/// exit the application.
pub inline fn outOfMemory() bool {
    return internal.outOfMemory();
}

/// Asks to wake the main thread. This e.g. allows your `pub fn update` to ask that the main thread
/// transition away from waiting for input, and execute another cycle which involves calling the
/// optional `updateMainThread` callback.
///
/// For example, instead of increasing the input thread target frequency, you may just call this
/// function to wake the main thread when your `updateMainThread` callback needs to be ran.
///
/// May be called from any thread.
pub inline fn wakeMainThread() void {
    internal.wakeMainThread();
}

/// Sets the minimum target frequency of the input handling thread.
///
/// Input handling (the main thread) runs at a variable frequency. The thread blocks until there are
/// input events available, or until it needs to unblock in order to achieve the minimum target
/// frequency which is your collaboration point of opportunity with the main thread.
///
/// For example, by default (`setInputFrequency(1)`) mach-core will aim to invoke `updateMainThread`
/// at least once per second (but potentially much more, e.g. once per every mouse movement or
/// keyboard button press.) If you were to increase the input frequency to say 60hz e.g.
/// `setInputFrequency(60)` then mach-core will aim to invoke your `updateMainThread` 60 times per
/// second.
///
/// An input frequency of zero implies unlimited, in which case the main thread will busy-wait.
///
/// # Multithreaded mach-core behavior
///
/// On some platforms, mach-core is able to handle input and rendering independently for
/// improved performance and responsiveness.
///
/// | Platform | Threading       |
/// |----------|-----------------|
/// | Desktop  | Multi threaded  |
/// | Browser  | Single threaded |
/// | Mobile   | TBD             |
///
/// On single-threaded platforms, `update` and the (optional) `updateMainThread` callback are
/// invoked in sequence, one after the other, on the same thread.
///
/// On multi-threaded platforms, `init` and `deinit` are called on the main thread, while `update`
/// is called on a separate rendering thread. The (optional) `updateMainThread` callback can be
/// used in cases where you must run a function on the main OS thread (such as to open a native
/// file dialog on macOS, since many system GUI APIs must be run on the main OS thread.) It is
/// advised you do not use this callback to run any code except when absolutely neccessary, as
/// it is in direct contention with input handling.
///
/// APIs which are not accessible from a specific thread are declared as such, otherwise can be
/// called from any thread as they are internally synchronized.
pub inline fn setInputFrequency(input_frequency: u32) void {
    input.target = input_frequency;
}

/// Returns the input frequency, or zero if unlimited (busy-waiting mode)
pub inline fn inputFrequency() u32 {
    return input.target;
}

/// Returns the actual number of frames rendered (`update` calls that returned) in the last second.
///
/// This is updated once per second.
pub inline fn frameRate() u32 {
    return frame.rate;
}

/// Returns the actual number of input thread iterations in the last second. See setInputFrequency
/// for what this means.
///
/// This is updated once per second.
pub inline fn inputRate() u32 {
    return input.rate;
}

/// Returns the underlying native NSWindow pointer
///
/// May only be called on macOS.
pub fn nativeWindowCocoa() *anyopaque {
    return internal.nativeWindowCocoa();
}

/// Returns the underlying native Windows' HWND pointer
///
/// May only be called on Windows.
pub fn nativeWindowWin32() std.os.windows.HWND {
    return internal.nativeWindowWin32();
}

pub const Size = struct {
    width: u32,
    height: u32,

    pub inline fn eql(a: Size, b: Size) bool {
        return a.width == b.width and a.height == b.height;
    }
};

pub const SizeOptional = struct {
    width: ?u32 = null,
    height: ?u32 = null,

    pub inline fn eql(a: SizeOptional, b: SizeOptional) bool {
        if ((a.width != null) != (b.width != null)) return false;
        if ((a.height != null) != (b.height != null)) return false;

        if (a.width != null and a.width.? != b.width.?) return false;
        if (a.height != null and a.height.? != b.height.?) return false;
        return true;
    }
};

pub const SizeLimit = struct {
    min: SizeOptional,
    max: SizeOptional,

    pub inline fn eql(a: SizeLimit, b: SizeLimit) bool {
        return a.min.eql(b.min) and a.max.eql(b.max);
    }
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
    joystick_connected: Joystick,
    joystick_disconnected: Joystick,
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

    pub const max = MouseButton.eight;
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

    pub const max = Key.unknown;
};

pub const KeyMods = packed struct(u8) {
    shift: bool,
    control: bool,
    alt: bool,
    super: bool,
    caps_lock: bool,
    num_lock: bool,
    _padding: u2 = 0,
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

pub const Joystick = enum(u8) {
    zero,
};

test {
    @import("std").testing.refAllDecls(Timer);
    @import("std").testing.refAllDecls(Frequency);
    @import("std").testing.refAllDecls(platform);

    @import("std").testing.refAllDeclsRecursive(Options);
    @import("std").testing.refAllDeclsRecursive(EventIterator);
    @import("std").testing.refAllDeclsRecursive(VSyncMode);
    @import("std").testing.refAllDeclsRecursive(Size);
    @import("std").testing.refAllDeclsRecursive(SizeOptional);
    @import("std").testing.refAllDeclsRecursive(SizeLimit);
    @import("std").testing.refAllDeclsRecursive(Position);
    @import("std").testing.refAllDeclsRecursive(Event);
    @import("std").testing.refAllDeclsRecursive(KeyEvent);
    @import("std").testing.refAllDeclsRecursive(MouseButtonEvent);
    @import("std").testing.refAllDeclsRecursive(MouseButton);
    @import("std").testing.refAllDeclsRecursive(Key);
    @import("std").testing.refAllDeclsRecursive(KeyMods);
    @import("std").testing.refAllDeclsRecursive(DisplayMode);
    @import("std").testing.refAllDeclsRecursive(CursorMode);
    @import("std").testing.refAllDeclsRecursive(CursorShape);
    @import("std").testing.refAllDeclsRecursive(Joystick);
}
