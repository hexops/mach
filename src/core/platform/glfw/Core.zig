const builtin = @import("builtin");
const std = @import("std");
const glfw = @import("mach-glfw");
const mach_core = @import("../../main.zig");
const gpu = mach_core.gpu;
const objc = @import("objc.zig");
const Options = @import("../../main.zig").Options;
const Event = @import("../../main.zig").Event;
const KeyEvent = @import("../../main.zig").KeyEvent;
const MouseButtonEvent = @import("../../main.zig").MouseButtonEvent;
const MouseButton = @import("../../main.zig").MouseButton;
const Size = @import("../../main.zig").Size;
const DisplayMode = @import("../../main.zig").DisplayMode;
const SizeLimit = @import("../../main.zig").SizeLimit;
const CursorShape = @import("../../main.zig").CursorShape;
const VSyncMode = @import("../../main.zig").VSyncMode;
const CursorMode = @import("../../main.zig").CursorMode;
const Key = @import("../../main.zig").Key;
const KeyMods = @import("../../main.zig").KeyMods;
const Joystick = @import("../../main.zig").Joystick;
const InputState = @import("../../InputState.zig");
const Frequency = @import("../../Frequency.zig");

const log = std.log.scoped(.mach);

pub const defaultLog = std.log.defaultLog;
pub const defaultPanic = std.debug.panicImpl;

pub const Core = @This();

// needed for the glfw joystick callback
var core_instance: ?*Core = null;

// There are two threads:
//
// 1. Main thread (App.init, App.deinit) which may interact with GLFW and handles events
// 2. App.update thread.

// Read-only fields
allocator: std.mem.Allocator,
frame: *Frequency,
input: *Frequency,
window: glfw.Window,
backend_type: gpu.BackendType,
user_ptr: UserPtr,
instance: *gpu.Instance,
surface: *gpu.Surface,
gpu_adapter: *gpu.Adapter,
gpu_device: *gpu.Device,
max_refresh_rate: u32,

// Mutable fields only used by main thread
app_update_thread_started: bool = false,
linux_gamemode: ?bool = null,
cursors: [@typeInfo(CursorShape).Enum.fields.len]?glfw.Cursor,
cursors_tried: [@typeInfo(CursorShape).Enum.fields.len]bool,
last_windowed_size: glfw.Window.Size,
last_windowed_pos: glfw.Window.Pos,

// Event queue; written from main thread; read from any
events_mu: std.Thread.RwLock = .{},
events: EventQueue,

// Input state; written from main thread; read from any
input_mu: std.Thread.RwLock = .{},
input_state: InputState = .{},
present_joysticks: std.StaticBitSet(@typeInfo(glfw.Joystick.Id).Enum.fields.len),

// Signals to the App.update thread to do something
swap_chain_update: std.Thread.ResetEvent = .{},
state_update: std.Thread.ResetEvent = .{},
done: std.Thread.ResetEvent = .{},
oom: std.Thread.ResetEvent = .{},

// Mutable fields; written by the App.update thread, read from any
swap_chain_mu: std.Thread.RwLock = .{},
swap_chain_desc: gpu.SwapChain.Descriptor,
swap_chain: *gpu.SwapChain,

// Mutable state fields; read/write by any thread
state_mu: std.Thread.Mutex = .{},
current_title: [:0]const u8,
current_title_changed: bool = false,
current_display_mode: DisplayMode = .windowed,
current_vsync_mode: VSyncMode = .triple,
last_display_mode: DisplayMode = .windowed,
last_vsync_mode: VSyncMode = .triple,
current_border: bool,
last_border: bool,
current_headless: bool,
last_headless: bool,
current_size: Size,
last_size: Size,
current_size_limit: SizeLimit = .{
    .min = .{ .width = 350, .height = 350 },
    .max = .{ .width = null, .height = null },
},
last_size_limit: SizeLimit = .{ .min = .{}, .max = .{} },
current_cursor_mode: CursorMode = .normal,
last_cursor_mode: CursorMode = .normal,
current_cursor_shape: CursorShape = .arrow,
last_cursor_shape: CursorShape = .arrow,

const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);

pub const EventIterator = struct {
    events_mu: *std.Thread.RwLock,
    queue: *EventQueue,

    pub inline fn next(self: *EventIterator) ?Event {
        self.events_mu.lockShared();
        defer self.events_mu.unlockShared();
        return self.queue.readItem();
    }
};

const UserPtr = struct {
    self: *Core,
};

// TODO(important): expose device loss to users, this can happen especially in the web and on mobile
// devices. Users will need to re-upload all assets to the GPU in this event.
fn deviceLostCallback(reason: gpu.Device.LostReason, msg: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    _ = reason;
    log.err("mach: device lost: {s}", .{msg});
    @panic("mach: device lost");
}

// Called on the main thread
pub fn init(
    core: *Core,
    allocator: std.mem.Allocator,
    frame: *Frequency,
    input: *Frequency,
    options: Options,
) !void {
    if (!@import("builtin").is_test and mach_core.options.use_wgpu) _ = mach_core.wgpu.Export(@import("root").GPUInterface);
    if (!@import("builtin").is_test and mach_core.options.use_sysgpu) _ = mach_core.sysgpu.sysgpu.Export(@import("root").SYSGPUInterface);

    const backend_type = try detectBackendType(allocator);

    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        glfw.getErrorCode() catch |err| switch (err) {
            error.PlatformError,
            error.PlatformUnavailable,
            => return err,
            else => unreachable,
        };
    }

    // Create the test window and discover adapters using it (esp. for OpenGL)
    var hints = glfwWindowHintsForBackend(backend_type);
    hints.cocoa_retina_framebuffer = true;
    if (options.headless) {
        hints.visible = false; // Hiding window before creation otherwise you get the window showing up for a little bit then hiding.
    }

    const monitors = try glfw.Monitor.getAll(allocator);
    defer allocator.free(monitors);
    var max_refresh_rate: u32 = 0;
    for (monitors) |monitor| {
        const video_mode = monitor.getVideoMode() orelse continue;
        const refresh_rate = video_mode.getRefreshRate();
        max_refresh_rate = @max(max_refresh_rate, refresh_rate);
    }
    if (max_refresh_rate == 0) max_refresh_rate = 60;
    frame.target = 2 * max_refresh_rate;

    const window = glfw.Window.create(
        options.size.width,
        options.size.height,
        options.title,
        null,
        null,
        hints,
    ) orelse switch (glfw.mustGetErrorCode()) {
        error.InvalidEnum,
        error.InvalidValue,
        error.FormatUnavailable,
        => unreachable,
        error.APIUnavailable,
        error.VersionUnavailable,
        error.PlatformError,
        => |err| return err,
        else => unreachable,
    };

    switch (backend_type) {
        .opengl, .opengles => {
            glfw.makeContextCurrent(window);
            glfw.getErrorCode() catch |err| switch (err) {
                error.PlatformError => return err,
                else => unreachable,
            };
        },
        else => {},
    }

    const instance = gpu.createInstance(null) orelse {
        log.err("failed to create GPU instance", .{});
        std.process.exit(1);
    };
    const surface = try createSurfaceForWindow(instance, window, comptime detectGLFWOptions());

    var response: RequestAdapterResponse = undefined;
    instance.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = surface,
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

    // Create a device with default limits/features.
    const gpu_device = response.adapter.?.createDevice(&.{
        .next_in_chain = .{
            .dawn_toggles_descriptor = &gpu.dawn.TogglesDescriptor.init(.{
                .enabled_toggles = &[_][*:0]const u8{
                    "allow_unsafe_apis",
                },
            }),
        },

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
    gpu_device.setUncapturedErrorCallback({}, printUnhandledErrorCallback);

    const framebuffer_size = window.getFramebufferSize();
    const swap_chain_desc = gpu.SwapChain.Descriptor{
        .label = "main swap chain",
        .usage = options.swap_chain_usage,
        .format = .bgra8_unorm,
        .width = framebuffer_size.width,
        .height = framebuffer_size.height,
        .present_mode = .mailbox,
    };
    const swap_chain = gpu_device.createSwapChain(surface, &swap_chain_desc);

    mach_core.adapter = response.adapter.?;
    mach_core.device = gpu_device;
    mach_core.queue = gpu_device.getQueue();
    mach_core.swap_chain = swap_chain;
    mach_core.descriptor = swap_chain_desc;

    // The initial capacity we choose for the event queue is 2x our maximum expected event rate per
    // frame. Specifically, 1000hz mouse updates are likely the maximum event rate we will encounter
    // so we anticipate 2x that. If the event rate is higher than this per frame, it will grow to
    // that maximum (we never shrink the event queue capacity in order to avoid allocations causing
    // any stutter.)
    var events = EventQueue.init(allocator);
    try events.ensureTotalCapacity(2048);

    core.* = .{
        .allocator = allocator,
        .frame = frame,
        .input = input,
        .window = window,
        .backend_type = backend_type,
        .user_ptr = undefined,
        .instance = instance,
        .surface = surface,
        .gpu_adapter = response.adapter.?,
        .gpu_device = gpu_device,
        .max_refresh_rate = max_refresh_rate,
        .swap_chain = swap_chain,
        .swap_chain_desc = swap_chain_desc,
        .events = events,
        .current_title = undefined,
        .current_border = undefined,
        .last_border = undefined,
        .current_headless = undefined,
        .last_headless = undefined,
        .current_size = undefined,
        .last_size = undefined,
        .last_windowed_size = window.getSize(),
        .last_windowed_pos = window.getPos(),
        .cursors = std.mem.zeroes([@typeInfo(CursorShape).Enum.fields.len]?glfw.Cursor),
        .cursors_tried = std.mem.zeroes([@typeInfo(CursorShape).Enum.fields.len]bool),
        .present_joysticks = std.StaticBitSet(@typeInfo(glfw.Joystick.Id).Enum.fields.len).initEmpty(),
    };

    core.current_title = options.title;

    core.current_display_mode = options.display_mode;
    core.last_display_mode = .windowed;

    core.current_border = options.border;
    core.last_border = true;

    core.current_headless = options.headless;
    core.last_headless = core.current_headless;

    const actual_size = core.window.getSize();
    core.current_size = .{ .width = actual_size.width, .height = actual_size.height };
    core.last_size = core.current_size;
    core.state_update.set();

    core_instance = core;
    core.user_ptr = .{ .self = core };

    core.initCallbacks();

    try core.input.start();

    if (builtin.os.tag == .linux and !options.is_app and
        core.linux_gamemode == null and try wantGamemode(core.allocator))
        core.linux_gamemode = initLinuxGamemode();
}

// Called on the main thread
fn initCallbacks(self: *Core) void {
    self.window.setUserPointer(&self.user_ptr);

    const key_callback = struct {
        fn callback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            const key_event = KeyEvent{
                .key = toMachKey(key),
                .mods = toMachMods(mods),
            };
            switch (action) {
                .press => {
                    pf.input_mu.lock();
                    pf.input_state.keys.set(@intFromEnum(key_event.key));
                    pf.input_mu.unlock();
                    pf.pushEvent(.{ .key_press = key_event });
                },
                .repeat => pf.pushEvent(.{ .key_repeat = key_event }),
                .release => {
                    pf.input_mu.lock();
                    pf.input_state.keys.unset(@intFromEnum(key_event.key));
                    pf.input_mu.unlock();
                    pf.pushEvent(.{ .key_release = key_event });
                },
            }
            _ = scancode;
        }
    }.callback;
    self.window.setKeyCallback(key_callback);

    const char_callback = struct {
        fn callback(window: glfw.Window, codepoint: u21) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            pf.pushEvent(.{
                .char_input = .{
                    .codepoint = codepoint,
                },
            });
        }
    }.callback;
    self.window.setCharCallback(char_callback);

    const mouse_motion_callback = struct {
        fn callback(window: glfw.Window, xpos: f64, ypos: f64) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;

            pf.input_mu.lock();
            pf.input_state.mouse_position = .{ .x = xpos, .y = ypos };
            pf.input_mu.unlock();

            pf.pushEvent(.{
                .mouse_motion = .{
                    .pos = .{
                        .x = xpos,
                        .y = ypos,
                    },
                },
            });
        }
    }.callback;
    self.window.setCursorPosCallback(mouse_motion_callback);

    const mouse_button_callback = struct {
        fn callback(window: glfw.Window, button: glfw.mouse_button.MouseButton, action: glfw.Action, mods: glfw.Mods) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            const cursor_pos = pf.window.getCursorPos();
            const mouse_button_event = MouseButtonEvent{
                .button = toMachButton(button),
                .pos = .{ .x = cursor_pos.xpos, .y = cursor_pos.ypos },
                .mods = toMachMods(mods),
            };

            pf.input_mu.lock();
            pf.input_state.mouse_position = mouse_button_event.pos;
            pf.input_mu.unlock();

            switch (action) {
                .press => {
                    pf.input_mu.lock();
                    pf.input_state.mouse_buttons.set(@intFromEnum(mouse_button_event.button));
                    pf.input_mu.unlock();
                    pf.pushEvent(.{ .mouse_press = mouse_button_event });
                },
                .release => {
                    pf.input_mu.lock();
                    pf.input_state.mouse_buttons.unset(@intFromEnum(mouse_button_event.button));
                    pf.input_mu.unlock();
                    pf.pushEvent(.{ .mouse_release = mouse_button_event });
                },
                else => {},
            }
        }
    }.callback;
    self.window.setMouseButtonCallback(mouse_button_callback);

    const scroll_callback = struct {
        fn callback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            pf.pushEvent(.{
                .mouse_scroll = .{
                    .xoffset = @as(f32, @floatCast(xoffset)),
                    .yoffset = @as(f32, @floatCast(yoffset)),
                },
            });
        }
    }.callback;
    self.window.setScrollCallback(scroll_callback);

    const joystick_callback = struct {
        fn callback(joystick: glfw.Joystick, event: glfw.Joystick.Event) void {
            const pf = core_instance.?;
            const idx: u8 = @intCast(@intFromEnum(joystick.jid));

            switch (event) {
                .connected => {
                    pf.input_mu.lock();
                    pf.present_joysticks.set(idx);
                    pf.input_mu.unlock();
                    pf.pushEvent(.{
                        .joystick_connected = @enumFromInt(idx),
                    });
                },
                .disconnected => {
                    pf.input_mu.lock();
                    pf.present_joysticks.unset(idx);
                    pf.input_mu.unlock();
                    pf.pushEvent(.{
                        .joystick_disconnected = @enumFromInt(idx),
                    });
                },
            }
        }
    }.callback;
    glfw.Joystick.setCallback(joystick_callback);

    const close_callback = struct {
        fn callback(window: glfw.Window) void {
            window.setShouldClose(false);
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            pf.pushEvent(.close);
        }
    }.callback;
    self.window.setCloseCallback(close_callback);

    const focus_callback = struct {
        fn callback(window: glfw.Window, focused: bool) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            pf.pushEvent(if (focused) .focus_gained else .focus_lost);
        }
    }.callback;
    self.window.setFocusCallback(focus_callback);

    const framebuffer_size_callback = struct {
        fn callback(window: glfw.Window, _: u32, _: u32) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            pf.swap_chain_update.set();
        }
    }.callback;
    self.window.setFramebufferSizeCallback(framebuffer_size_callback);

    const window_size_callback = struct {
        fn callback(window: glfw.Window, width: i32, height: i32) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            pf.state_mu.lock();
            defer pf.state_mu.unlock();
            pf.current_size.width = @intCast(width);
            pf.current_size.height = @intCast(height);
            pf.last_size.width = @intCast(width);
            pf.last_size.height = @intCast(height);
        }
    }.callback;
    self.window.setSizeCallback(window_size_callback);
}

fn pushEvent(self: *Core, event: Event) void {
    self.events_mu.lock();
    defer self.events_mu.unlock();
    self.events.writeItem(event) catch self.oom.set();
}

// Called on the main thread
pub fn deinit(self: *Core) void {
    for (self.cursors) |glfw_cursor| {
        if (glfw_cursor) |cur| {
            cur.destroy();
        }
    }
    self.events.deinit();

    if (builtin.os.tag == .linux and
        self.linux_gamemode != null and
        self.linux_gamemode.?)
        deinitLinuxGamemode();

    self.gpu_device.setDeviceLostCallback(null, null);

    self.swap_chain.release();
    self.surface.release();
    mach_core.queue.release();
    self.gpu_device.release();
    self.gpu_adapter.release();
    self.instance.release();
}

// Secondary app-update thread
pub fn appUpdateThread(self: *Core, app: anytype) void {
    self.frame.start() catch unreachable;
    while (true) {
        if (self.swap_chain_update.isSet()) blk: {
            self.swap_chain_update.reset();

            if (self.current_vsync_mode != self.last_vsync_mode) {
                self.last_vsync_mode = self.current_vsync_mode;
                switch (self.current_vsync_mode) {
                    .triple => self.frame.target = 2 * self.max_refresh_rate,
                    else => self.frame.target = 0,
                }
            }

            const framebuffer_size = self.window.getFramebufferSize();
            glfw.getErrorCode() catch break :blk;
            if (framebuffer_size.width == 0 or framebuffer_size.height == 0) break :blk;

            {
                self.swap_chain_mu.lock();
                defer self.swap_chain_mu.unlock();
                mach_core.swap_chain.release();
                self.swap_chain_desc.width = framebuffer_size.width;
                self.swap_chain_desc.height = framebuffer_size.height;
                self.swap_chain = self.gpu_device.createSwapChain(self.surface, &self.swap_chain_desc);

                mach_core.swap_chain = self.swap_chain;
                mach_core.descriptor = self.swap_chain_desc;
            }

            self.pushEvent(.{
                .framebuffer_resize = .{
                    .width = framebuffer_size.width,
                    .height = framebuffer_size.height,
                },
            });
        }

        if (app.update() catch unreachable) {
            self.done.set();

            // Wake the main thread from any event handling, so there is not e.g. a one second delay
            // in exiting the application.
            glfw.postEmptyEvent();
            return;
        }
        self.gpu_device.tick();
        self.gpu_device.machWaitForCommandsToBeScheduled();

        self.frame.tick();
        if (self.frame.delay_ns != 0) std.time.sleep(self.frame.delay_ns);
    }
}

// Called on the main thread
pub fn update(self: *Core, app: anytype) !bool {
    if (self.done.isSet()) return true;
    if (!self.app_update_thread_started) {
        self.app_update_thread_started = true;
        const thread = try std.Thread.spawn(.{}, appUpdateThread, .{ self, app });
        thread.detach();
    }

    if (self.state_update.isSet()) {
        self.state_update.reset();

        // Title changes
        if (self.current_title_changed) {
            self.current_title_changed = false;
            self.window.setTitle(self.current_title);
        }

        // Display mode changes
        if (self.current_display_mode != self.last_display_mode) {
            const current_border = self.current_border;
            switch (self.current_display_mode) {
                .windowed => {
                    self.window.setAttrib(.decorated, current_border);
                    self.window.setAttrib(.floating, false);
                    self.window.setMonitor(
                        null,
                        @intCast(self.last_windowed_pos.x),
                        @intCast(self.last_windowed_pos.y),
                        self.last_size.width,
                        self.last_size.height,
                        null,
                    );
                },
                .fullscreen => {
                    if (self.last_display_mode == .windowed) {
                        self.last_windowed_size = self.window.getSize();
                        self.last_windowed_pos = self.window.getPos();
                    }

                    if (glfw.Monitor.getPrimary()) |monitor| {
                        if (monitor.getVideoMode()) |video_mode| {
                            self.window.setAttrib(.decorated, false);
                            self.window.setAttrib(.floating, true);
                            self.window.setMonitor(null, 0, 0, video_mode.getWidth(), video_mode.getHeight(), null);
                        }
                    }
                },
                .borderless => {
                    if (self.last_display_mode == .windowed) {
                        self.last_windowed_size = self.window.getSize();
                        self.last_windowed_pos = self.window.getPos();
                    }

                    self.window.setAttrib(.decorated, false);
                    self.window.setAttrib(.floating, true);

                    if (glfw.Monitor.getPrimary()) |monitor| {
                        if (monitor.getVideoMode()) |video_mode| {
                            self.window.setAttrib(.decorated, false);
                            self.window.setAttrib(.floating, true);
                            self.window.setMonitor(null, 0, 0, video_mode.getWidth(), video_mode.getHeight(), null);
                        }
                    }
                },
            }
            self.last_display_mode = self.current_display_mode;
        }

        // Border changes
        if (self.current_border != self.last_border) {
            self.last_border = self.current_border;
            if (self.current_display_mode != .borderless) self.window.setAttrib(.decorated, self.current_border);
        }

        // Headless changes
        if (self.current_headless != self.last_headless) {
            self.current_headless = self.last_headless;
            if (self.current_headless) self.window.hide() else self.window.show();
        }

        // Size changes
        if (!self.current_size.eql(self.last_size)) {
            self.last_size = self.current_size;
            self.window.setSize(.{
                .width = self.current_size.width,
                .height = self.current_size.height,
            });
        }

        // Size limit changes
        if (!self.current_size_limit.eql(self.last_size_limit)) {
            self.last_size_limit = self.current_size_limit;
            self.window.setSizeLimits(
                .{ .width = self.current_size_limit.min.width, .height = self.current_size_limit.min.height },
                .{ .width = self.current_size_limit.max.width, .height = self.current_size_limit.max.height },
            );
        }

        // Cursor mode changes
        if (self.current_cursor_mode != self.last_cursor_mode) {
            self.last_cursor_mode = self.current_cursor_mode;
            self.window.setInputModeCursor(switch (self.current_cursor_mode) {
                .normal => .normal,
                .hidden => .hidden,
                .disabled => .disabled,
            });
            // on e.g. macOS raw mouse motion is not supported. If an error occurs here, there is
            // nothing meaningful we can do anyway so just silence the warning.
            glfw.getErrorCode() catch {};
        }

        // Cursor shape changes
        if (self.current_cursor_shape != self.last_cursor_shape) {
            self.last_cursor_shape = self.current_cursor_shape;
            // TODO(feature): creating a GLFW standard cursor could fail, we should provide custom backup
            // images for these. https://github.com/hexops/mach/pull/352
            const enum_int = @intFromEnum(self.current_cursor_shape);
            const tried = self.cursors_tried[enum_int];
            if (!tried) {
                self.cursors_tried[enum_int] = true;
                self.cursors[enum_int] = switch (self.current_cursor_shape) {
                    .arrow => glfw.Cursor.createStandard(.arrow),
                    .ibeam => glfw.Cursor.createStandard(.ibeam),
                    .crosshair => glfw.Cursor.createStandard(.crosshair),
                    .pointing_hand => glfw.Cursor.createStandard(.pointing_hand),
                    .resize_ew => glfw.Cursor.createStandard(.resize_ew),
                    .resize_ns => glfw.Cursor.createStandard(.resize_ns),
                    .resize_nwse => glfw.Cursor.createStandard(.resize_nwse),
                    .resize_nesw => glfw.Cursor.createStandard(.resize_nesw),
                    .resize_all => glfw.Cursor.createStandard(.resize_all),
                    .not_allowed => glfw.Cursor.createStandard(.not_allowed),
                };
            }

            if (self.cursors[enum_int]) |cur| {
                self.window.setCursor(cur);
            } else {
                glfw.getErrorCode() catch {}; // discard error
                // TODO(feature): creating a GLFW standard cursor could fail, we should provide custom backup
                // images for these. https://github.com/hexops/mach/pull/352
                log.warn("mach: setCursorShape: {s} not yet supported\n", .{@tagName(self.current_cursor_shape)});
            }
        }
    }

    const frequency_delay = @as(f32, @floatFromInt(self.input.delay_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));
    glfw.waitEventsTimeout(frequency_delay);

    if (@hasDecl(std.meta.Child(@TypeOf(app)), "updateMainThread")) {
        if (app.updateMainThread() catch unreachable) {
            self.done.set();
            return true;
        }
    }

    glfw.getErrorCode() catch |err| switch (err) {
        error.PlatformError => log.err("glfw: failed to poll events", .{}),
        error.InvalidValue => unreachable,
        else => unreachable,
    };
    self.input.tick();
    return false;
}

// May be called from any thread.
pub inline fn pollEvents(self: *Core) EventIterator {
    return EventIterator{ .events_mu = &self.events_mu, .queue = &self.events };
}

// May be called from any thread.
pub fn setTitle(self: *Core, title: [:0]const u8) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    self.current_title = title;
    self.current_title_changed = true;
    self.state_update.set();
    self.wakeMainThread();
}

// May be called from any thread.
pub fn setDisplayMode(self: *Core, mode: DisplayMode) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    self.current_display_mode = mode;
    if (self.current_display_mode != self.last_display_mode) {
        self.state_update.set();
        self.wakeMainThread();
    }
}

// May be called from any thread.
pub fn displayMode(self: *Core) DisplayMode {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    return self.current_display_mode;
}

// May be called from any thread.
pub fn setBorder(self: *Core, value: bool) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    self.current_border = value;
    if (self.current_border != self.last_border) {
        self.state_update.set();
        self.wakeMainThread();
    }
}

// May be called from any thread.
pub fn border(self: *Core) bool {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    return self.current_border;
}

// May be called from any thread.
pub fn setHeadless(self: *Core, value: bool) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    self.current_headless = value;
    if (self.current_headless != self.last_headless) {
        self.state_update.set();
        self.wakeMainThread();
    }
}

// May be called from any thread.
pub fn headless(self: *Core) bool {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    return self.current_headless;
}

// May be called from any thread.
pub fn setVSync(self: *Core, mode: VSyncMode) void {
    self.swap_chain_mu.lock();
    self.swap_chain_desc.present_mode = switch (mode) {
        .none => .immediate,
        .double => .fifo,
        .triple => .mailbox,
    };
    self.current_vsync_mode = mode;
    self.swap_chain_mu.unlock();
    self.swap_chain_update.set();
    self.wakeMainThread();
}

// May be called from any thread.
pub fn vsync(self: *Core) VSyncMode {
    self.swap_chain_mu.lockShared();
    defer self.swap_chain_mu.unlockShared();
    return switch (self.swap_chain_desc.present_mode) {
        .immediate => .none,
        .fifo => .double,
        .mailbox => .triple,
    };
}

// May be called from any thread.
pub fn setSize(self: *Core, value: Size) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    self.current_size = value;
    if (!self.current_size.eql(self.last_size)) {
        self.state_update.set();
        self.wakeMainThread();
    }
}

// May be called from any thread.
pub fn size(self: *Core) Size {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    return self.current_size;
}

// May be called from any thread.
pub fn setSizeLimit(self: *Core, limit: SizeLimit) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    self.current_size_limit = limit;
    if (!self.current_size_limit.eql(self.last_size_limit)) {
        self.state_update.set();
        self.wakeMainThread();
    }
}

// May be called from any thread.
pub fn sizeLimit(self: *Core) SizeLimit {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    return self.current_size_limit;
}

// May be called from any thread.
pub fn setCursorMode(self: *Core, mode: CursorMode) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    self.current_cursor_mode = mode;
    if (self.current_cursor_mode != self.last_cursor_mode) {
        self.state_update.set();
        self.wakeMainThread();
    }
}

// May be called from any thread.
pub fn cursorMode(self: *Core) CursorMode {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    return self.current_cursor_mode;
}

// May be called from any thread.
pub fn setCursorShape(self: *Core, shape: CursorShape) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    self.current_cursor_shape = shape;
    if (self.current_cursor_shape != self.last_cursor_shape) {
        self.state_update.set();
        self.wakeMainThread();
    }
}

// May be called from any thread.
pub fn cursorShape(self: *Core) CursorShape {
    self.state_mu.lock();
    defer self.state_mu.unlock();
    return self.current_cursor_shape;
}

// May be called from any thread.
pub fn joystickPresent(_: *Core, _: Joystick) bool {
    @panic("TODO: thread safe API");
    // const idx: u8 = @intFromEnum(joystick);
    // if (idx >= @typeInfo(glfw.Joystick.Id).Enum.len) return false;

    // self.input_mu.lockShared();
    // defer self.input_mu.unlockShared();
    // return self.present_joysticks.isSet(idx);
}

// May be called from any thread.
pub fn joystickName(_: *Core, _: Joystick) ?[:0]const u8 {
    @panic("TODO: thread safe API");
    // const idx: u8 = @intFromEnum(joystick);
    // if (idx >= @typeInfo(glfw.Joystick.Id).Enum.len) return null;

    // const glfw_joystick = glfw.Joystick{ .jid = @intCast(idx) };
    // return glfw_joystick.getName();
}

// May be called from any thread.
pub fn joystickButtons(_: *Core, _: Joystick) ?[]const bool {
    @panic("TODO: thread safe API");
    // const idx: u8 = @intFromEnum(joystick);
    // if (idx >= @typeInfo(glfw.Joystick.Id).Enum.len) return null;

    // const glfw_joystick = glfw.Joystick{ .jid = @intCast(idx) };
    // return @ptrCast(glfw_joystick.getButtons());
}

// May be called from any thread.
pub fn joystickAxes(_: *Core, _: Joystick) ?[]const f32 {
    @panic("TODO: thread safe API");
    // const idx: u8 = @intFromEnum(joystick);
    // if (idx >= @typeInfo(glfw.Joystick.Id).Enum.len) return null;

    // const glfw_joystick = glfw.Joystick{ .jid = @intCast(idx) };
    // return glfw_joystick.getAxes();
}

// May be called from any thread.
pub fn keyPressed(self: *Core, key: Key) bool {
    self.input_mu.lockShared();
    defer self.input_mu.unlockShared();
    return self.input_state.isKeyPressed(key);
}

// May be called from any thread.
pub fn keyReleased(self: *Core, key: Key) bool {
    self.input_mu.lockShared();
    defer self.input_mu.unlockShared();
    return self.input_state.isKeyReleased(key);
}

// May be called from any thread.
pub fn mousePressed(self: *Core, button: MouseButton) bool {
    self.input_mu.lockShared();
    defer self.input_mu.unlockShared();
    return self.input_state.isMouseButtonPressed(button);
}

// May be called from any thread.
pub fn mouseReleased(self: *Core, button: MouseButton) bool {
    self.input_mu.lockShared();
    defer self.input_mu.unlockShared();
    return self.input_state.isMouseButtonReleased(button);
}

// May be called from any thread.
pub fn mousePosition(self: *Core) mach_core.Position {
    self.input_mu.lockShared();
    defer self.input_mu.unlockShared();
    return self.input_state.mouse_position;
}

// May be called from any thread.
pub inline fn outOfMemory(self: *Core) bool {
    if (self.oom.isSet()) {
        self.oom.reset();
        return true;
    }
    return false;
}

// May be called from any thread.
pub inline fn wakeMainThread(self: *Core) void {
    _ = self;
    glfw.postEmptyEvent();
}

// May be called from any thread.
pub fn nativeWindowCocoa(self: *Core) *anyopaque {
    const glfw_native = glfw.Native(comptime detectGLFWOptions());
    return glfw_native.getCocoaWindow(self.window).?;
}

// May be called from any thread.
pub fn nativeWindowWin32(self: *Core) std.os.windows.HWND {
    const glfw_native = glfw.Native(comptime detectGLFWOptions());
    return glfw_native.getWin32Window(self.window);
}

fn toMachButton(button: glfw.mouse_button.MouseButton) MouseButton {
    return switch (button) {
        .left => .left,
        .right => .right,
        .middle => .middle,
        .four => .four,
        .five => .five,
        .six => .six,
        .seven => .seven,
        .eight => .eight,
    };
}

fn toMachKey(key: glfw.Key) Key {
    return switch (key) {
        .a => .a,
        .b => .b,
        .c => .c,
        .d => .d,
        .e => .e,
        .f => .f,
        .g => .g,
        .h => .h,
        .i => .i,
        .j => .j,
        .k => .k,
        .l => .l,
        .m => .m,
        .n => .n,
        .o => .o,
        .p => .p,
        .q => .q,
        .r => .r,
        .s => .s,
        .t => .t,
        .u => .u,
        .v => .v,
        .w => .w,
        .x => .x,
        .y => .y,
        .z => .z,

        .zero => .zero,
        .one => .one,
        .two => .two,
        .three => .three,
        .four => .four,
        .five => .five,
        .six => .six,
        .seven => .seven,
        .eight => .eight,
        .nine => .nine,

        .F1 => .f1,
        .F2 => .f2,
        .F3 => .f3,
        .F4 => .f4,
        .F5 => .f5,
        .F6 => .f6,
        .F7 => .f7,
        .F8 => .f8,
        .F9 => .f9,
        .F10 => .f10,
        .F11 => .f11,
        .F12 => .f12,
        .F13 => .f13,
        .F14 => .f14,
        .F15 => .f15,
        .F16 => .f16,
        .F17 => .f17,
        .F18 => .f18,
        .F19 => .f19,
        .F20 => .f20,
        .F21 => .f21,
        .F22 => .f22,
        .F23 => .f23,
        .F24 => .f24,
        .F25 => .f25,

        .kp_divide => .kp_divide,
        .kp_multiply => .kp_multiply,
        .kp_subtract => .kp_subtract,
        .kp_add => .kp_add,
        .kp_0 => .kp_0,
        .kp_1 => .kp_1,
        .kp_2 => .kp_2,
        .kp_3 => .kp_3,
        .kp_4 => .kp_4,
        .kp_5 => .kp_5,
        .kp_6 => .kp_6,
        .kp_7 => .kp_7,
        .kp_8 => .kp_8,
        .kp_9 => .kp_9,
        .kp_decimal => .kp_decimal,
        .kp_equal => .kp_equal,
        .kp_enter => .kp_enter,

        .enter => .enter,
        .escape => .escape,
        .tab => .tab,
        .left_shift => .left_shift,
        .right_shift => .right_shift,
        .left_control => .left_control,
        .right_control => .right_control,
        .left_alt => .left_alt,
        .right_alt => .right_alt,
        .left_super => .left_super,
        .right_super => .right_super,
        .menu => .menu,
        .num_lock => .num_lock,
        .caps_lock => .caps_lock,
        .print_screen => .print,
        .scroll_lock => .scroll_lock,
        .pause => .pause,
        .delete => .delete,
        .home => .home,
        .end => .end,
        .page_up => .page_up,
        .page_down => .page_down,
        .insert => .insert,
        .left => .left,
        .right => .right,
        .up => .up,
        .down => .down,
        .backspace => .backspace,
        .space => .space,
        .minus => .minus,
        .equal => .equal,
        .left_bracket => .left_bracket,
        .right_bracket => .right_bracket,
        .backslash => .backslash,
        .semicolon => .semicolon,
        .apostrophe => .apostrophe,
        .comma => .comma,
        .period => .period,
        .slash => .slash,
        .grave_accent => .grave,

        .world_1 => .unknown,
        .world_2 => .unknown,
        .unknown => .unknown,
    };
}

fn toMachMods(mods: glfw.Mods) KeyMods {
    return .{
        .shift = mods.shift,
        .control = mods.control,
        .alt = mods.alt,
        .super = mods.super,
        .caps_lock = mods.caps_lock,
        .num_lock = mods.num_lock,
    };
}

/// GLFW error handling callback
///
/// This only logs errors, and doesn't e.g. exit the application, because many simple operations of
/// GLFW can result in an error on the stack when running under different Wayland Linux systems.
/// Doing anything else here would result in a good chance of applications not working on Wayland,
/// so the best thing to do really is to just log the error. See the mach-glfw README for more info.
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    if (std.mem.eql(u8, description, "Raw mouse motion is not supported on this system")) return;
    log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn glfwWindowHintsForBackend(backend: gpu.BackendType) glfw.Window.Hints {
    return switch (backend) {
        .opengl => .{
            // Ask for OpenGL 4.4 which is what the GL backend requires for compute shaders and
            // texture views.
            .context_version_major = 4,
            .context_version_minor = 4,
            .opengl_forward_compat = true,
            .opengl_profile = .opengl_core_profile,
        },
        .opengles => .{
            .context_version_major = 3,
            .context_version_minor = 1,
            .client_api = .opengl_es_api,
            .context_creation_api = .egl_context_api,
        },
        else => .{
            // Without this GLFW will initialize a GL context on the window, which prevents using
            // the window with other APIs (by crashing in weird ways).
            .client_api = .no_api,
        },
    };
}

fn detectGLFWOptions() glfw.BackendOptions {
    if (builtin.target.isDarwin()) return .{ .cocoa = true };
    return switch (builtin.target.os.tag) {
        .windows => .{ .win32 = true },
        .linux => .{ .x11 = true, .wayland = true },
        else => .{},
    };
}

fn createSurfaceForWindow(
    instance: *gpu.Instance,
    window: glfw.Window,
    comptime glfw_options: glfw.BackendOptions,
) !*gpu.Surface {
    const glfw_native = glfw.Native(glfw_options);
    const extension = if (glfw_options.win32) gpu.Surface.Descriptor.NextInChain{
        .from_windows_hwnd = &.{
            .hinstance = std.os.windows.kernel32.GetModuleHandleW(null).?,
            .hwnd = glfw_native.getWin32Window(window),
        },
    } else if (glfw_options.x11 or glfw_options.wayland) blk: {
        break :blk switch (glfw.getPlatform()) {
            .wayland => gpu.Surface.Descriptor.NextInChain{
                .from_wayland_surface = &.{
                    .display = glfw_native.getWaylandDisplay(),
                    .surface = glfw_native.getWaylandWindow(window),
                },
            },
            .x11 => gpu.Surface.Descriptor.NextInChain{
                .from_xlib_window = &.{
                    .display = glfw_native.getX11Display(),
                    .window = glfw_native.getX11Window(window),
                },
            },
            else => unreachable,
        };
    } else if (glfw_options.cocoa) blk: {
        const pool = try objc.AutoReleasePool.init();
        defer objc.AutoReleasePool.release(pool);

        const ns_window = glfw_native.getCocoaWindow(window);
        const ns_view = objc.msgSend(ns_window, "contentView", .{}, *anyopaque); // [nsWindow contentView]

        // Create a CAMetalLayer that covers the whole window that will be passed to CreateSurface.
        objc.msgSend(ns_view, "setWantsLayer:", .{true}, void); // [view setWantsLayer:YES]
        const layer = objc.msgSend(objc.objc_getClass("CAMetalLayer"), "layer", .{}, ?*anyopaque); // [CAMetalLayer layer]
        if (layer == null) @panic("failed to create Metal layer");
        objc.msgSend(ns_view, "setLayer:", .{layer.?}, void); // [view setLayer:layer]

        // Use retina if the window was created with retina support.
        const scale_factor = objc.msgSend(ns_window, "backingScaleFactor", .{}, f64); // [ns_window backingScaleFactor]
        objc.msgSend(layer.?, "setContentsScale:", .{scale_factor}, void); // [layer setContentsScale:scale_factor]

        break :blk gpu.Surface.Descriptor.NextInChain{ .from_metal_layer = &.{ .layer = layer.? } };
    } else unreachable;

    return instance.createSurface(&gpu.Surface.Descriptor{
        .next_in_chain = extension,
    });
}

inline fn printUnhandledErrorCallback(_: void, ty: gpu.ErrorType, message: [*:0]const u8) void {
    switch (ty) {
        .validation => std.log.err("gpu: validation error: {s}\n", .{message}),
        .out_of_memory => std.log.err("gpu: out of memory: {s}\n", .{message}),
        .device_lost => std.log.err("gpu: device lost: {s}\n", .{message}),
        .unknown => std.log.err("gpu: unknown error: {s}\n", .{message}),
        else => unreachable,
    }
    std.os.exit(1);
}

fn detectBackendType(allocator: std.mem.Allocator) !gpu.BackendType {
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

/// Check if gamemode should be activated
fn wantGamemode(allocator: std.mem.Allocator) error{ OutOfMemory, InvalidUtf8, InvalidWtf8 }!bool {
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

fn initLinuxGamemode() bool {
    const gamemode = @import("../../../main.zig").gamemode;
    gamemode.start();
    if (!gamemode.isActive()) return false;
    log.info("gamemode: activated", .{});
    return true;
}

fn deinitLinuxGamemode() void {
    const gamemode = @import("../../../main.zig").gamemode;
    gamemode.stop();
}

const RequestAdapterResponse = struct {
    status: gpu.RequestAdapterStatus,
    adapter: ?*gpu.Adapter,
    message: ?[*:0]const u8,
};

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
