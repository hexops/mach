const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build-options");

const mach = @import("main.zig");
const gpu = mach.gpu;
const log = std.log.scoped(.mach);
const gamemode_log = std.log.scoped(.gamemode);

pub const sysgpu = @import("../main.zig").sysgpu;
pub const sysjs = @import("mach-sysjs");
pub const Timer = @import("core/Timer.zig");
const Frequency = @import("core/Frequency.zig");

const Platform = switch (build_options.core_platform) {
    .x11 => @import("core/X11.zig"),
    .wayland => @import("core/Wayland.zig"),
    .web => @panic("TODO: revive wasm backend"),
    .win32 => @import("core/win32.zig"),
};

// TODO(important): mach.core has a lot of standard Zig APIs, and some global variables, which are
// part of its old API design. We should elevate them into this module instead.

pub const name = .mach_core;

pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init, .description = 
    \\ Send this once you've configured any options you want on e.g. the core.state().main_window
    },

    .present_frame = .{ .handler = presentFrame, .description = 
    \\ Send this when rendering has finished and the swapchain should be presented.
    },

    .exit = .{ .handler = exit, .description = 
    \\ Send this when you would like to exit the application.
    \\
    \\ When the next .present_frame occurs, then .app.deinit will be sent giving your app a chance
    \\ to deinitialize itself and .app.tick will no longer be sent. Once your app is done with
    \\ deinitialization, you should send the final .mach_core.deinit event which will cause the
    \\ application to finish.
    },

    .deinit = .{ .handler = deinit, .description = 
    \\ Send this once your app is fully deinitialized and ready to exit for good.
    },
};

pub const components = .{
    .title = .{ .type = [:0]u8, .description = 
    \\ Window title slice. Can be set with a format string and arguments via:
    \\
    \\ ```
    \\ try core.state().printTitle(core_mod.state().main_window, "Hello, {s}!", .{"Mach"});
    \\ ```
    \\
    \\ If setting this component yourself, ensure the buffer is allocated using core.state().allocator
    \\ as it will be freed for you as part of the .deinit event.
    },

    .framebuffer_format = .{ .type = gpu.Texture.Format, .description = 
    \\ The texture format of the framebuffer
    },

    .framebuffer_width = .{ .type = u32, .description = 
    \\ The width of the framebuffer in texels
    },

    .framebuffer_height = .{ .type = u32, .description = 
    \\ The height of the framebuffer in texels
    },

    .width = .{ .type = u32, .description = 
    \\ The width of the window in virtual pixels
    },

    .height = .{ .type = u32, .description = 
    \\ The height of the window in virtual pixels
    },

    .fullscreen = .{ .type = bool, .description = 
    \\ Whether the window should be fullscreen (only respected at .start time)
    },
};

allocator: std.mem.Allocator,
main_window: mach.EntityID,
platform: Platform,
title: [256:0]u8 = undefined,
should_close: bool = false,
linux_gamemode: ?bool = null,
frame: Frequency,

// Might be accessed by Platform backend
input: Frequency,
swap_chain_update: std.Thread.ResetEvent = .{},

// GPU
instance: *gpu.Instance,
adapter: *gpu.Adapter,
device: *gpu.Device,
queue: *gpu.Queue,
surface: *gpu.Surface,
swap_chain: *gpu.SwapChain,
descriptor: gpu.SwapChain.Descriptor,

pub const EventIterator = struct {
    platform: Platform.EventIterator,

    pub inline fn next(iter: *EventIterator) ?Event {
        return iter.platform.next();
    }
};

pub const InitOptions = struct {
    allocator: std.mem.Allocator,
    is_app: bool = false,
    headless: bool = false,
    display_mode: DisplayMode = .windowed,
    border: bool = true,
    title: [:0]const u8 = "Mach core",
    size: Size = .{ .width = 1920 / 2, .height = 1080 / 2 },
    power_preference: gpu.PowerPreference = .undefined,
    required_features: ?[]const gpu.FeatureName = null,
    required_limits: ?gpu.Limits = null,
    swap_chain_usage: gpu.Texture.UsageFlags = .{
        .render_attachment = true,
    },
};

fn init(core: *Mod, entities: *mach.Entities.Mod, options: InitOptions) !void {
    // TODO: fix all leaks and use options.allocator
    try mach.sysgpu.Impl.init(std.heap.c_allocator, .{});

    const state = core.state();

    state.allocator = options.allocator;
    state.main_window = try entities.new();
    try core.set(state.main_window, .fullscreen, false);
    try core.set(state.main_window, .width, 1920 / 2);
    try core.set(state.main_window, .height, 1080 / 2);

    // Copy window title into owned buffer.
    if (options.title.len < state.title.len) {
        @memcpy(state.title[0..options.title.len], options.title);
        state.title[options.title.len] = 0;
    }

    try Platform.init(&state.platform, options);

    state.instance = gpu.createInstance(null) orelse {
        log.err("failed to create GPU instance", .{});
        std.process.exit(1);
    };
    state.surface = state.instance.createSurface(&state.platform.surface_descriptor);

    var response: RequestAdapterResponse = undefined;
    state.instance.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = state.surface,
        .power_preference = options.power_preference,
        .force_fallback_adapter = .false,
    }, &response, requestAdapterCallback);
    if (response.status != .success) {
        log.err("failed to create GPU adapter: {?s}", .{response.message});
        log.info("-> maybe try MACH_GPU_BACKEND=opengl ?", .{});
        std.process.exit(1);
    }

    // Print which adapter we are going to use.
    var props = std.mem.zeroes(gpu.Adapter.Properties);
    response.adapter.?.getProperties(&props);
    if (props.backend_type == .null) {
        log.err("no backend found for {s} adapter", .{props.adapter_type.name()});
        std.process.exit(1);
    }
    log.info("found {s} backend on {s} adapter: {s}, {s}\n", .{
        props.backend_type.name(),
        props.adapter_type.name(),
        props.name,
        props.driver_description,
    });

    state.adapter = response.adapter.?;

    // Create a device with default limits/features.
    state.device = response.adapter.?.createDevice(&.{
        .required_features_count = if (options.required_features) |v| @as(u32, @intCast(v.len)) else 0,
        .required_features = if (options.required_features) |v| @as(?[*]const gpu.FeatureName, v.ptr) else null,
        .required_limits = if (options.required_limits) |limits| @as(?*const gpu.RequiredLimits, &gpu.RequiredLimits{
            .limits = limits,
        }) else null,
        .device_lost_callback = &deviceLostCallback,
        .device_lost_userdata = null,
    }) orelse {
        log.err("failed to create GPU device\n", .{});
        std.process.exit(1);
    };
    state.device.setUncapturedErrorCallback({}, printUnhandledErrorCallback);
    state.queue = state.device.getQueue();

    state.descriptor = gpu.SwapChain.Descriptor{
        .label = "main swap chain",
        .usage = options.swap_chain_usage,
        .format = .bgra8_unorm,
        .width = @intCast(state.platform.size.width),
        .height = @intCast(state.platform.size.height),
        .present_mode = .mailbox,
    };
    state.swap_chain = state.device.createSwapChain(state.surface, &state.descriptor);

    // TODO(important): update this information upon framebuffer resize events
    try core.set(state.main_window, .framebuffer_format, state.descriptor.format);
    try core.set(state.main_window, .framebuffer_width, state.descriptor.width);
    try core.set(state.main_window, .framebuffer_height, state.descriptor.height);
    try core.set(state.main_window, .width, state.platform.size.width);
    try core.set(state.main_window, .height, state.platform.size.height);

    if (builtin.os.tag == .linux and !options.is_app and
        state.linux_gamemode == null and try wantGamemode(options.allocator))
        state.linux_gamemode = initLinuxGamemode();

    state.frame = .{ .target = 0 };
    state.input = .{ .target = 1 };
    try state.frame.start();
    try state.input.start();
}

pub inline fn deinit(entities: *mach.Entities.Mod, core: *Mod) !void {
    const state = core.state();

    var q = try entities.query(.{
        .titles = Mod.read(.title),
    });
    while (q.next()) |v| {
        for (v.titles) |title| {
            state.allocator.free(title);
        }
    }

    if (builtin.os.tag == .linux and
        state.linux_gamemode != null and
        state.linux_gamemode.?)
    {
        deinitLinuxGamemode();
    }
    
    state.platform.deinit();
    state.swap_chain.release();
    state.queue.release();
    state.device.release();
    state.surface.release();
    state.adapter.release();
    state.instance.release();
}

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

pub const Joystick = enum(u8) {
    zero,
};

pub inline fn pollEvents(core: *@This()) EventIterator {
    return .{ .platform = core.platform.pollEvents() };
}

/// Sets the window title. The string must be owned by Core, and will not be copied or freed. It is
/// advised to use the `core.title` buffer for this purpose, e.g.:
///
/// ```
/// const title = try std.fmt.bufPrintZ(&core.title, "Hello, world!", .{});
/// core.setTitle(title);
/// ```
pub inline fn setTitle(core: *@This(), value: [:0]const u8) void {
    return core.platform.setTitle(value);
}

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

/// Set the window mode
pub inline fn setDisplayMode(core: *@This(), mode: DisplayMode) void {
    return core.platform.setDisplayMode(mode);
}

/// Returns the window mode
pub inline fn displayMode(core: *@This()) DisplayMode {
    return core.platform.display_mode;
}

pub inline fn setBorder(core: *@This(), value: bool) void {
    return core.platform.setBorder(value);
}

pub inline fn border(core: *@This()) bool {
    return core.platform.border;
}

pub inline fn setHeadless(core: *@This(), value: bool) void {
    return core.platform.setHeadless(value);
}

pub inline fn headless(core: *@This()) bool {
    return core.platform.headless;
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
pub inline fn setVSync(core: *@This(), mode: VSyncMode) void {
    return core.platform.setVSync(mode);
}

/// Returns refresh rate synchronization mode.
pub inline fn vsync(core: *@This()) VSyncMode {
    return core.platform.vsync_mode;
}

/// Sets the frame rate limit. Default 0 (unlimited)
///
/// This is applied *in addition* to the vsync mode.
pub inline fn setFrameRateLimit(core: *@This(), limit: u32) void {
    core.frame.target = limit;
}

/// Returns the frame rate limit, or zero if unlimited.
pub inline fn frameRateLimit(core: *@This()) u32 {
    return core.frame.target;
}

pub const Size = struct {
    width: u32,
    height: u32,

    pub inline fn eql(a: Size, b: Size) bool {
        return a.width == b.width and a.height == b.height;
    }
};

/// Set the window size, in subpixel units.
pub inline fn setSize(core: *@This(), value: Size) void {
    return core.platform.setSize(value);
}

/// Returns the window size, in subpixel units.
pub inline fn size(core: *@This()) Size {
    return core.platform.size;
}

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

pub inline fn setCursorMode(core: *@This(), mode: CursorMode) void {
    return core.platform.setCursorMode(mode);
}

pub inline fn cursorMode(core: *@This()) CursorMode {
    return core.platform.cursorMode();
}

pub inline fn setCursorShape(core: *@This(), cursor: CursorShape) void {
    return core.platform.setCursorShape(cursor);
}

pub inline fn cursorShape(core: *@This()) CursorShape {
    return core.platform.cursorShape();
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

pub inline fn keyPressed(core: *@This(), key: Key) bool {
    return core.platform.keyPressed(key);
}

pub inline fn keyReleased(core: *@This(), key: Key) bool {
    return core.platform.keyReleased(key);
}

pub inline fn mousePressed(core: *@This(), button: MouseButton) bool {
    return core.platform.mousePressed(button);
}

pub inline fn mouseReleased(core: *@This(), button: MouseButton) bool {
    return core.platform.mouseReleased(button);
}

pub const Position = struct {
    x: f64,
    y: f64,
};

pub inline fn mousePosition(core: *@This()) Position {
    return core.platform.mousePosition();
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
pub inline fn setInputFrequency(core: *@This(), input_frequency: u32) void {
    core.input.target = input_frequency;
}

/// Returns the input frequency, or zero if unlimited (busy-waiting mode)
pub inline fn inputFrequency(core: *@This()) u32 {
    return core.input.target;
}

/// Returns the actual number of frames rendered (`update` calls that returned) in the last second.
///
/// This is updated once per second.
pub inline fn frameRate(core: *@This()) u32 {
    return core.frame.rate;
}

/// Returns the actual number of input thread iterations in the last second. See setInputFrequency
/// for what this means.
///
/// This is updated once per second.
pub inline fn inputRate(core: *@This()) u32 {
    return core.input.rate;
}

/// Returns the underlying native NSWindow pointer
///
/// May only be called on macOS.
pub fn nativeWindowCocoa(core: *@This()) *anyopaque {
    return core.platform.nativeWindowCocoa();
}

/// Returns the underlying native Windows' HWND pointer
///
/// May only be called on Windows.
pub fn nativeWindowWin32(core: *@This()) std.os.windows.HWND {
    return core.platform.nativeWindowWin32();
}

fn presentFrame(core: *Mod, entities: *mach.Entities.Mod) !void {
    const state: *@This() = core.state();

    // Update windows title
    var num_windows: usize = 0;
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .titles = Mod.read(.title),
    });
    while (q.next()) |v| {
        for (v.ids, v.titles) |_, title| {
            num_windows += 1;
            state.platform.setTitle(title);
        }
    }
    if (num_windows > 1) @panic("mach: Core currently only supports a single window");

    _ = try state.platform.update();
    state.swap_chain.present();

    // Update swapchain for the next frame
    if (state.swap_chain_update.isSet()) blk: {
        state.swap_chain_update.reset();

        switch (state.platform.vsync_mode) {
            .triple => state.frame.target = 2 * state.platform.refresh_rate,
            else => state.frame.target = 0,
        }

        if (state.platform.size.width == 0 or state.platform.size.height == 0) break :blk;

        state.descriptor.present_mode = switch (state.platform.vsync_mode) {
            .none => .immediate,
            .double => .fifo,
            .triple => .mailbox,
        };
        state.descriptor.width = @intCast(state.platform.size.width);
        state.descriptor.height = @intCast(state.platform.size.height);
        state.swap_chain.release();
        state.swap_chain = state.device.createSwapChain(state.surface, &state.descriptor);
    }

    // TODO(important): update this information in response to resize events rather than
    // after frame submission
    try core.set(state.main_window, .framebuffer_format, state.descriptor.format);
    try core.set(state.main_window, .framebuffer_width, state.descriptor.width);
    try core.set(state.main_window, .framebuffer_height, state.descriptor.height);
    try core.set(state.main_window, .width, state.platform.size.width);
    try core.set(state.main_window, .height, state.platform.size.height);

    state.frame.tick();
}

/// Prints into the window title buffer using a format string and arguments. e.g.
///
/// ```
/// try core.state().printTitle(core_mod, core_mod.state().main_window, "Hello, {s}!", .{"Mach"});
/// ```
pub fn printTitle(
    core: *@This(),
    window_id: mach.EntityID,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    _ = core;
    _ = window_id;
    _ = fmt;
    _ = args;
    // TODO: NO OP
    // // Free any previous window title slice
    // if (core.get(window_id, .title)) |slice| core.state().allocator.free(slice);

    // // Allocate and assign a new window title slice.
    // const slice = try std.fmt.allocPrintZ(core.state().allocator, fmt, args);
    // try core.set(window_id, .title, slice);
}

fn exit(core: *Mod) void {
    core.state().should_close = true;
}

pub const RequestAdapterResponse = struct {
    status: gpu.RequestAdapterStatus,
    adapter: ?*gpu.Adapter,
    message: ?[*:0]const u8,
};

pub inline fn requestAdapterCallback(
    context: *RequestAdapterResponse,
    status: gpu.RequestAdapterStatus,
    adapter: ?*gpu.Adapter,
    message: ?[*:0]const u8,
) void {
    context.* = RequestAdapterResponse{
        .status = status,
        .adapter = adapter,
        .message = message,
    };
}

// TODO(important): expose device loss to users, this can happen especially in the web and on mobile
// devices. Users will need to re-upload all assets to the GPU in this event.
fn deviceLostCallback(reason: gpu.Device.LostReason, msg: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    _ = reason;
    log.err("mach: device lost: {s}", .{msg});
    @panic("mach: device lost");
}

pub inline fn printUnhandledErrorCallback(_: void, ty: gpu.ErrorType, message: [*:0]const u8) void {
    switch (ty) {
        .validation => std.log.err("gpu: validation error: {s}\n", .{message}),
        .out_of_memory => std.log.err("gpu: out of memory: {s}\n", .{message}),
        .device_lost => std.log.err("gpu: device lost: {s}\n", .{message}),
        .unknown => std.log.err("gpu: unknown error: {s}\n", .{message}),
        else => unreachable,
    }
    std.process.exit(1);
}

/// Check if gamemode should be activated
pub fn wantGamemode(allocator: std.mem.Allocator) error{ OutOfMemory, InvalidWtf8 }!bool {
    const use_gamemode = std.process.getEnvVarOwned(
        allocator,
        "MACH_USE_GAMEMODE",
    ) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return true,
        else => |e| return e,
    };
    defer allocator.free(use_gamemode);

    return !(std.ascii.eqlIgnoreCase(use_gamemode, "off") or std.ascii.eqlIgnoreCase(use_gamemode, "false"));
}

pub fn initLinuxGamemode() bool {
    mach.gamemode.start();
    if (!mach.gamemode.isActive()) return false;
    gamemode_log.info("gamemode: activated", .{});
    return true;
}

pub fn deinitLinuxGamemode() void {
    mach.gamemode.stop();
    gamemode_log.info("gamemode: deactivated", .{});
}

// Verifies that a platform implementation exposes the expected function declarations.
comptime {
    // Core
    assertHasField(Platform, "surface_descriptor");

    assertHasDecl(Platform, "init");
    assertHasDecl(Platform, "deinit");
    assertHasDecl(Platform, "pollEvents");

    assertHasDecl(Platform, "setTitle");

    assertHasDecl(Platform, "setDisplayMode");
    assertHasField(Platform, "display_mode");

    assertHasDecl(Platform, "setBorder");
    assertHasField(Platform, "border");

    assertHasDecl(Platform, "setHeadless");
    assertHasField(Platform, "headless");

    assertHasDecl(Platform, "setVSync");
    assertHasField(Platform, "vsync_mode");

    assertHasDecl(Platform, "setSize");
    assertHasField(Platform, "size");

    assertHasDecl(Platform, "setCursorMode");
    assertHasField(Platform, "cursor_mode");

    assertHasDecl(Platform, "setCursorShape");
    assertHasField(Platform, "cursor_shape");

    assertHasDecl(Platform, "joystickPresent");
    assertHasDecl(Platform, "joystickName");
    assertHasDecl(Platform, "joystickButtons");
    assertHasDecl(Platform, "joystickAxes");

    assertHasDecl(Platform, "keyPressed");
    assertHasDecl(Platform, "keyReleased");
    assertHasDecl(Platform, "mousePressed");
    assertHasDecl(Platform, "mouseReleased");
    assertHasDecl(Platform, "mousePosition");

    // Timer
    assertHasDecl(@This().Timer, "start");
    assertHasDecl(@This().Timer, "read");
    assertHasDecl(@This().Timer, "reset");
    assertHasDecl(@This().Timer, "lap");
}

fn assertHasDecl(comptime T: anytype, comptime decl_name: []const u8) void {
    if (!@hasDecl(T, decl_name)) @compileError(@typeName(T) ++ " missing declaration: " ++ decl_name);
}

fn assertHasField(comptime T: anytype, comptime field_name: []const u8) void {
    if (!@hasField(T, field_name)) @compileError(@typeName(T) ++ " missing field: " ++ field_name);
}

test {
    @import("std").testing.refAllDecls(Timer);
    @import("std").testing.refAllDecls(Frequency);
    @import("std").testing.refAllDecls(Platform);

    @import("std").testing.refAllDeclsRecursive(InitOptions);
    @import("std").testing.refAllDeclsRecursive(EventIterator);
    @import("std").testing.refAllDeclsRecursive(VSyncMode);
    @import("std").testing.refAllDeclsRecursive(Size);
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
