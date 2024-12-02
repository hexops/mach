const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build-options");

const mach = @import("main.zig");
const gpu = mach.gpu;
const log = std.log.scoped(.mach);

const Core = @This();

// Whether or not you can drive the main loop in a non-blocking fashion, or if the underlying
// platform must take control and drive the main loop itself.
pub const supports_non_blocking = switch (build_options.core_platform) {
    // Platforms that support non-blocking mode.
    .linux => true,
    .windows => true,
    .null => true,

    // Platforms which take control of the main loop.
    .wasm => false,
    .darwin => false,
};

const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);

/// Set this to true if you intend to drive the main loop yourself.
///
/// A panic will occur if `supports_non_blocking == false` for the platform.
pub var non_blocking = false;

pub const mach_module = .mach_core;

pub const mach_systems = .{ .main, .init, .tick, .presentFrame, .deinit };

// Set track_fields to true so that when these field values change, we know about it
// and can update the platform windows.
windows: mach.Objects(
    .{ .track_fields = true },
    struct {
        /// Window title string
        // TODO: document how to set this using a format string
        // TODO: allocation/free strategy
        title: []const u8 = "Mach Window",

        /// Texture format of the framebuffer (read-only)
        framebuffer_format: gpu.Texture.Format = .bgra8_unorm,

        /// Width of the framebuffer in texels (read-only)
        /// Will be updated to reflect the actual framebuffer dimensions after window creation.
        framebuffer_width: u32 = 1920 / 2,

        /// Height of the framebuffer in texels (read-only)
        /// Will be updated to reflect the actual framebuffer dimensions after window creation.
        framebuffer_height: u32 = 1080 / 2,

        /// Vertical sync mode, prevents screen tearing.
        vsync_mode: VSyncMode = .none,

        display_mode: DisplayMode = .windowed,

        /// Cursor
        cursor_mode: CursorMode = .normal,
        cursor_shape: CursorShape = .arrow,

        /// Outer border
        border: bool = true,

        /// Width of the window in virtual pixels (read-only)
        width: u32 = 1920 / 2,

        /// Height of the window in virtual pixels (read-only)
        height: u32 = 1080 / 2,

        /// Target frames per second
        refresh_rate: u32 = 0,

        // GPU
        // When device is not null, the rest of the fields have been
        // initialized.
        device: *gpu.Device = undefined,
        instance: *gpu.Instance = undefined,
        adapter: *gpu.Adapter = undefined,
        queue: *gpu.Queue = undefined,
        swap_chain: *gpu.SwapChain = undefined,
        swap_chain_descriptor: gpu.SwapChain.Descriptor = undefined,
        swap_chain_update: std.Thread.ResetEvent = .{},
        surface: *gpu.Surface = undefined,
        surface_descriptor: gpu.Surface.Descriptor = undefined,

        // After window initialization, (when device is not null)
        // changing these will have no effect
        power_preference: gpu.PowerPreference = .undefined,
        required_features: ?[]const gpu.FeatureName = null,
        required_limits: ?gpu.Limits = null,
        swap_chain_usage: gpu.Texture.UsageFlags = .{
            .render_attachment = true,
        },

        native: ?Platform.Native = null,
    },
),

/// Callback system invoked per tick (e.g. per-frame)
on_tick: ?mach.FunctionID = null,

/// Callback system invoked when application is exiting
on_exit: ?mach.FunctionID = null,

/// Current state of the application
state: enum {
    running,
    exiting,
    deinitializing,
    exited,
} = .running,

frame: mach.time.Frequency,
input: mach.time.Frequency,

// Internal module state
allocator: std.mem.Allocator,
events: EventQueue,
input_state: InputState,
oom: std.Thread.ResetEvent = .{},

pub fn init(core: *Core) !void {
    const allocator = std.heap.c_allocator;

    // TODO: fix all leaks and use options.allocator
    try mach.sysgpu.Impl.init(allocator, .{});

    var events = EventQueue.init(allocator);
    try events.ensureTotalCapacity(8192);

    core.* = .{
        // Note: since core.windows is initialized for us already, we just copy the pointer.
        .windows = core.windows,

        .allocator = allocator,
        .events = events,
        .input_state = .{},

        .input = .{ .target = 0 },
        .frame = .{ .target = 1 },
    };

    try core.frame.start();
    try core.input.start();
}

pub fn initWindow(core: *Core, window_id: mach.ObjectID) !void {
    var core_window = core.windows.getValue(window_id);
    defer core.windows.setValueRaw(window_id, core_window);

    core_window.instance = gpu.createInstance(null) orelse {
        log.err("failed to create GPU instance", .{});
        std.process.exit(1);
    };
    core_window.surface = core_window.instance.createSurface(&core_window.surface_descriptor);

    var response: RequestAdapterResponse = undefined;
    core_window.instance.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = core_window.surface,
        .power_preference = core_window.power_preference,
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

    core_window.adapter = response.adapter.?;

    // Create a device with default limits/features.
    core_window.device = response.adapter.?.createDevice(&.{
        .required_features_count = if (core_window.required_features) |v| @as(u32, @intCast(v.len)) else 0,
        .required_features = if (core_window.required_features) |v| @as(?[*]const gpu.FeatureName, v.ptr) else null,
        .required_limits = if (core_window.required_limits) |limits| @as(?*const gpu.RequiredLimits, &gpu.RequiredLimits{
            .limits = limits,
        }) else null,
        .device_lost_callback = &deviceLostCallback,
        .device_lost_userdata = null,
    }) orelse {
        log.err("failed to create GPU device\n", .{});
        std.process.exit(1);
    };
    core_window.device.setUncapturedErrorCallback({}, printUnhandledErrorCallback);
    core_window.queue = core_window.device.getQueue();

    core_window.swap_chain_descriptor = gpu.SwapChain.Descriptor{
        .label = "main swap chain",
        .usage = core_window.swap_chain_usage,
        .format = .bgra8_unorm,
        .width = core_window.width,
        .height = core_window.height,
        .present_mode = switch (core_window.vsync_mode) {
            .none => .immediate,
            .double => .fifo,
            .triple => .mailbox,
        },
    };
    core_window.swap_chain = core_window.device.createSwapChain(core_window.surface, &core_window.swap_chain_descriptor);
    core_window.framebuffer_format = core_window.swap_chain_descriptor.format;
    core_window.framebuffer_width = core_window.swap_chain_descriptor.width;
    core_window.framebuffer_height = core_window.swap_chain_descriptor.height;

    core.pushEvent(.{ .window_open = .{ .window_id = window_id } });
}

pub fn tick(core: *Core, core_mod: mach.Mod(Core)) !void {
    // TODO(core)(slimsag): consider execution order of mach.Core (e.g. creating a new window
    // during application execution, rendering to multiple windows, etc.) and how
    // that relates to Platform.tick being responsible for both handling window updates
    // (like title/size changes) and window creation, plus multi-threaded rendering.
    try Platform.tick(core);

    core_mod.run(core.on_tick.?);
    core_mod.call(.presentFrame);
}

pub fn main(core: *Core, core_mod: mach.Mod(Core)) !void {
    if (core.on_tick == null) @panic("core.on_tick callback must be set");
    if (core.on_exit == null) @panic("core.on_exit callback must be set");

    try Platform.tick(core);
    core_mod.run(core.on_tick.?);
    core_mod.call(.presentFrame);

    // If the user doesn't want mach.Core to take control of the main loop, we bail out - the next
    // app tick is already scheduled to run in the future and they'll .present_frame to return
    // control to us later.
    if (non_blocking) {
        if (!supports_non_blocking) std.debug.panic(
            "mach.Core: platform {s} does not support non_blocking=true mode.",
            .{@tagName(build_options.core_platform)},
        );
        return;
    }

    // The user wants mach.Core to take control of the main loop.
    if (supports_non_blocking) {
        while (core.state != .exited) {
            try Platform.tick(core);
            core_mod.run(core.on_tick.?);
            core_mod.call(.presentFrame);
        }

        // Don't return, because Platform.run wouldn't either (marked noreturn due to underlying
        // platform APIs never returning.)
        std.process.exit(0);
    } else {
        // Platform drives the main loop.
        Platform.run(platform_update_callback, .{ core, core_mod });

        // Platform.run should be marked noreturn, so this shouldn't ever run. But just in case we
        // accidentally introduce a different Platform.run in the future, we put an exit here for
        // good measure.
        std.process.exit(0);
    }
}

fn platform_update_callback(core: *Core, core_mod: mach.Mod(Core)) !bool {
    // TODO(core)(slimsag): consider execution order of mach.Core (e.g. creating a new window
    // during application execution, rendering to multiple windows, etc.) and how
    // that relates to Platform.tick being responsible for both handling window updates
    // (like title/size changes) and window creation, plus multi-threaded rendering.
    try Platform.tick(core);

    core_mod.run(core.on_tick.?);
    core_mod.call(.presentFrame);
    //core_mod.call(.processWindowUpdates);

    return core.state != .exited;
}

pub fn deinit(core: *Core) !void {
    core.state = .exited;

    var windows = core.windows.slice();
    while (windows.next()) |window_id| {
        var core_window = core.windows.getValue(window_id);
        core_window.swap_chain.release();
        core_window.queue.release();
        core_window.device.release();
        core_window.surface.release();
        core_window.adapter.release();
        core_window.instance.release();
    }

    core.events.deinit();
}

/// Returns the next event until there are no more available. You should check for events during
/// every on_tick()
pub inline fn nextEvent(core: *@This()) ?Event {
    return core.events.readItem();
}

/// Push an event onto the event queue, or set OOM if no space is available.
///
/// Updates the input_state tracker.
pub inline fn pushEvent(core: *@This(), event: Event) void {
    // Write event
    core.events.writeItem(event) catch {
        core.oom.set();
        return;
    };

    // Update input state
    switch (event) {
        .key_press => |ev| core.input_state.keys.setValue(@intFromEnum(ev.key), true),
        .key_release => |ev| core.input_state.keys.setValue(@intFromEnum(ev.key), false),
        .mouse_press => |ev| core.input_state.mouse_buttons.setValue(@intFromEnum(ev.button), true),
        .mouse_release => |ev| core.input_state.mouse_buttons.setValue(@intFromEnum(ev.button), false),
        .mouse_motion => |ev| core.input_state.mouse_position = ev.pos,
        .focus_lost => {
            // Clear input state that may be 'stuck' when focus is regained.
            core.input_state.keys = InputState.KeyBitSet.initEmpty();
            core.input_state.mouse_buttons = InputState.MouseButtonSet.initEmpty();
        },
        else => {},
    }
}

/// Reports whether mach.Core ran out of memory, indicating events may have been dropped.
///
/// Once called, the OOM flag is reset and mach.Core will continue operating normally.
pub fn outOfMemory(core: *@This()) bool {
    if (!core.oom.isSet()) return false;
    core.oom.reset();
    return true;
}

pub fn keyPressed(core: *@This(), key: Key) bool {
    return core.input_state.isKeyPressed(key);
}

pub fn keyReleased(core: *@This(), key: Key) bool {
    return core.input_state.isKeyReleased(key);
}

pub fn mousePressed(core: *@This(), button: MouseButton) bool {
    return core.input_state.isMouseButtonPressed(button);
}

pub fn mouseReleased(core: *@This(), button: MouseButton) bool {
    return core.input_state.isMouseButtonReleased(button);
}

pub fn mousePosition(core: *@This()) Position {
    return core.input_state.mouse_position;
}

// TODO(object)
// /// Set refresh rate synchronization mode. Default `.triple`
// ///
// /// Calling this function also implicitly calls setFrameRateLimit for you:
// /// ```
// /// .none   => setFrameRateLimit(0) // unlimited
// /// .double => setFrameRateLimit(0) // unlimited
// /// .triple => setFrameRateLimit(2 * max_monitor_refresh_rate)
// /// ```
// pub inline fn setVSync(core: *@This(), mode: VSyncMode) void {
//     return core.platform.setVSync(mode);
// }

// TODO(object)
// /// Returns refresh rate synchronization mode.
// pub inline fn vsync(core: *@This()) VSyncMode {
//     return core.platform.vsync_mode;
// }

// TODO(object)
// /// Sets the frame rate limit. Default 0 (unlimited)
// ///
// /// This is applied *in addition* to the vsync mode.
// pub inline fn setFrameRateLimit(core: *@This(), limit: u32) void {
//     core.frame.target = limit;
// }

// TODO(object)
// /// Returns the frame rate limit, or zero if unlimited.
// pub inline fn frameRateLimit(core: *@This()) u32 {
//     return core.frame.target;
// }

// TODO(object)
// /// Set the window size, in subpixel units.
// pub inline fn setSize(core: *@This(), value: Size) void {
//     return core.platform.setSize(value);
// }

// TODO(object)
// /// Returns the window size, in subpixel units.
// pub inline fn size(core: *@This()) Size {
//     return core.platform.size;
// }

// TODO(object)
// pub inline fn setCursorMode(core: *@This(), mode: CursorMode) void {
//     return core.platform.setCursorMode(mode);
// }

// TODO(object)
// pub inline fn cursorMode(core: *@This()) CursorMode {
//     return core.platform.cursorMode();
// }

// TODO(object)
// pub inline fn setCursorShape(core: *@This(), cursor: CursorShape) void {
//     return core.platform.setCursorShape(cursor);
// }

// TODO(object)
// pub inline fn cursorShape(core: *@This()) CursorShape {
//     return core.platform.cursorShape();
// }

// TODO(object)
// /// Sets the minimum target frequency of the input handling thread.
// ///
// /// Input handling (the main thread) runs at a variable frequency. The thread blocks until there are
// /// input events available, or until it needs to unblock in order to achieve the minimum target
// /// frequency which is your collaboration point of opportunity with the main thread.
// ///
// /// For example, by default (`setInputFrequency(1)`) mach-core will aim to invoke `updateMainThread`
// /// at least once per second (but potentially much more, e.g. once per every mouse movement or
// /// keyboard button press.) If you were to increase the input frequency to say 60hz e.g.
// /// `setInputFrequency(60)` then mach-core will aim to invoke your `updateMainThread` 60 times per
// /// second.
// ///
// /// An input frequency of zero implies unlimited, in which case the main thread will busy-wait.
// ///
// /// # Multithreaded mach-core behavior
// ///
// /// On some platforms, mach-core is able to handle input and rendering independently for
// /// improved performance and responsiveness.
// ///
// /// | Platform | Threading       |
// /// |----------|-----------------|
// /// | Desktop  | Multi threaded  |
// /// | Browser  | Single threaded |
// /// | Mobile   | TBD             |
// ///
// /// On single-threaded platforms, `update` and the (optional) `updateMainThread` callback are
// /// invoked in sequence, one after the other, on the same thread.
// ///
// /// On multi-threaded platforms, `init` and `deinit` are called on the main thread, while `update`
// /// is called on a separate rendering thread. The (optional) `updateMainThread` callback can be
// /// used in cases where you must run a function on the main OS thread (such as to open a native
// /// file dialog on macOS, since many system GUI APIs must be run on the main OS thread.) It is
// /// advised you do not use this callback to run any code except when absolutely neccessary, as
// /// it is in direct contention with input handling.
// ///
// /// APIs which are not accessible from a specific thread are declared as such, otherwise can be
// /// called from any thread as they are internally synchronized.
// pub inline fn setInputFrequency(core: *@This(), input_frequency: u32) void {
//     core.input.target = input_frequency;
// }

// TODO(object)
// /// Returns the input frequency, or zero if unlimited (busy-waiting mode)
// pub inline fn inputFrequency(core: *@This()) u32 {
//     return core.input.target;
// }

// TODO(object)
// /// Returns the actual number of frames rendered (`update` calls that returned) in the last second.
// ///
// /// This is updated once per second.
// pub inline fn frameRate(core: *@This()) u32 {
//     return core.frame.rate;
// }

// TODO(object)
// /// Returns the actual number of input thread iterations in the last second. See setInputFrequency
// /// for what this means.
// ///
// /// This is updated once per second.
// pub inline fn inputRate(core: *@This()) u32 {
//     return core.input.rate;
// }

// TODO(object)
// /// Returns the underlying native NSWindow pointer
// ///
// /// May only be called on macOS.
// pub fn nativeWindowCocoa(core: *@This()) *anyopaque {
//     return core.platform.nativeWindowCocoa();
// }

// TODO(object)
// /// Returns the underlying native Windows' HWND pointer
// ///
// /// May only be called on Windows.
// pub fn nativeWindowWin32(core: *@This()) std.os.windows.HWND {
//     return core.platform.nativeWindowWin32();
// }

pub fn presentFrame(core: *Core, core_mod: mach.Mod(Core)) !void {
    var windows = core.windows.slice();
    while (windows.next()) |window_id| {
        var core_window = core.windows.getValue(window_id);
        defer core.windows.setValueRaw(window_id, core_window);

        mach.sysgpu.Impl.deviceTick(core_window.device);

        core_window.swap_chain.present();

        // Update swapchain for the next frame
        if (core_window.swap_chain_update.isSet()) blk: {
            core_window.swap_chain_update.reset();

            switch (core_window.vsync_mode) {
                .triple => core.frame.target = 2 * core_window.refresh_rate,
                else => core.frame.target = 0,
            }

            if (core_window.width == 0 or core_window.height == 0) break :blk;

            core_window.swap_chain_descriptor.present_mode = switch (core_window.vsync_mode) {
                .none => .immediate,
                .double => .fifo,
                .triple => .mailbox,
            };

            core_window.swap_chain_descriptor.width = core_window.width;
            core_window.swap_chain_descriptor.height = core_window.height;
            core_window.swap_chain.release();

            core_window.swap_chain = core_window.device.createSwapChain(core_window.surface, &core_window.swap_chain_descriptor);
        }
    }

    // Record to frame rate frequency monitor that a frame was finished.
    core.frame.tick();

    switch (core.state) {
        .running => {},
        .exiting => {
            core.state = .deinitializing;
            core_mod.run(core.on_exit.?);
            core_mod.call(.deinit);
        },
        .deinitializing => {},
        .exited => @panic("application not running"),
    }
}

pub fn exit(core: *Core) void {
    core.state = .exiting;
}

inline fn requestAdapterCallback(
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

pub fn detectBackendType(allocator: std.mem.Allocator) !gpu.BackendType {
    const backend = std.process.getEnvVarOwned(
        allocator,
        "MACH_GPU_BACKEND",
    ) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => {
            if (builtin.target.isDarwin()) return .metal;
            if (builtin.target.os.tag == .windows) return .d3d12;
            return .vulkan;
        },
        else => return err,
    };
    defer allocator.free(backend);

    if (std.ascii.eqlIgnoreCase(backend, "null")) return .null;
    if (std.ascii.eqlIgnoreCase(backend, "d3d11")) return .d3d11;
    if (std.ascii.eqlIgnoreCase(backend, "d3d12")) return .d3d12;
    if (std.ascii.eqlIgnoreCase(backend, "metal")) return .metal;
    if (std.ascii.eqlIgnoreCase(backend, "vulkan")) return .vulkan;
    if (std.ascii.eqlIgnoreCase(backend, "opengl")) return .opengl;
    if (std.ascii.eqlIgnoreCase(backend, "opengles")) return .opengles;

    @panic("unknown MACH_GPU_BACKEND type");
}

const Platform = switch (build_options.core_platform) {
    .wasm => @panic("TODO: support mach.Core WASM platform"),
    .windows => @import("core/Windows.zig"),
    .linux => @import("core/Linux.zig"),
    .darwin => @import("core/Darwin.zig"),
    .null => @import("core/Null.zig"),
};

pub const InputState = struct {
    const KeyBitSet = std.StaticBitSet(@as(u8, @intFromEnum(Key.max)) + 1);
    const MouseButtonSet = std.StaticBitSet(@as(u4, @intFromEnum(MouseButton.max)) + 1);

    keys: KeyBitSet = KeyBitSet.initEmpty(),
    mouse_buttons: MouseButtonSet = MouseButtonSet.initEmpty(),
    mouse_position: Position = .{ .x = 0, .y = 0 },

    pub inline fn isKeyPressed(input: InputState, key: Key) bool {
        return input.keys.isSet(@intFromEnum(key));
    }

    pub inline fn isKeyReleased(input: InputState, key: Key) bool {
        return !input.isKeyPressed(key);
    }

    pub inline fn isMouseButtonPressed(input: InputState, button: MouseButton) bool {
        return input.mouse_buttons.isSet(@intFromEnum(button));
    }

    pub inline fn isMouseButtonReleased(input: InputState, button: MouseButton) bool {
        return !input.isMouseButtonPressed(button);
    }
};

pub const Event = union(enum) {
    key_press: KeyEvent,
    key_repeat: KeyEvent,
    key_release: KeyEvent,
    char_input: struct {
        window_id: mach.ObjectID,
        codepoint: u21,
    },
    mouse_motion: struct {
        window_id: mach.ObjectID,
        pos: Position,
    },
    mouse_press: MouseButtonEvent,
    mouse_release: MouseButtonEvent,
    mouse_scroll: struct {
        window_id: mach.ObjectID,
        xoffset: f32,
        yoffset: f32,
    },
    window_resize: ResizeEvent,
    window_open: struct {
        window_id: mach.ObjectID,
    },
    focus_gained: struct {
        window_id: mach.ObjectID,
    },
    focus_lost: struct {
        window_id: mach.ObjectID,
    },
    close: struct {
        window_id: mach.ObjectID,
    },
};

pub const KeyEvent = struct {
    window_id: mach.ObjectID,
    key: Key,
    mods: KeyMods,
};

pub const MouseButtonEvent = struct {
    window_id: mach.ObjectID,
    button: MouseButton,
    pos: Position,
    mods: KeyMods,
};

pub const ResizeEvent = struct {
    window_id: mach.ObjectID,
    size: Size,
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
    kp_comma,
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

    iso_backslash,
    international1,
    international2,
    international3,
    international4,
    international5,
    lang1,
    lang2,

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

pub const Size = struct {
    width: u32,
    height: u32,

    pub inline fn eql(a: Size, b: Size) bool {
        return a.width == b.width and a.height == b.height;
    }
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

pub const Position = struct {
    x: f64,
    y: f64,
};

const RequestAdapterResponse = struct {
    status: gpu.RequestAdapterStatus,
    adapter: ?*gpu.Adapter,
    message: ?[*:0]const u8,
};

// Verifies that a platform implementation exposes the expected function declarations.
// comptime {
//     // Core
//     assertHasField(Platform, "surface_descriptor");
//     assertHasField(Platform, "refresh_rate");

//     assertHasDecl(Platform, "init");
//     assertHasDecl(Platform, "deinit");

//     assertHasDecl(Platform, "setTitle");

//     assertHasDecl(Platform, "setDisplayMode");
//     assertHasField(Platform, "display_mode");

//     assertHasDecl(Platform, "setBorder");
//     assertHasField(Platform, "border");

//     assertHasDecl(Platform, "setHeadless");
//     assertHasField(Platform, "headless");

//     assertHasDecl(Platform, "setVSync");
//     assertHasField(Platform, "vsync_mode");

//     assertHasDecl(Platform, "setSize");
//     assertHasField(Platform, "size");

//     assertHasDecl(Platform, "setCursorMode");
//     assertHasField(Platform, "cursor_mode");

//     assertHasDecl(Platform, "setCursorShape");
//     assertHasField(Platform, "cursor_shape");
// }

fn assertHasDecl(comptime T: anytype, comptime decl_name: []const u8) void {
    if (!@hasDecl(T, decl_name)) @compileError(@typeName(T) ++ " missing declaration: " ++ decl_name);
}

fn assertHasField(comptime T: anytype, comptime field_name: []const u8) void {
    if (!@hasField(T, field_name)) @compileError(@typeName(T) ++ " missing field: " ++ field_name);
}

test {
    _ = Platform;
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
}
