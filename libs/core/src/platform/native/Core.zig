const builtin = @import("builtin");
const std = @import("std");
const gpu = @import("gpu");
const glfw = @import("glfw");
const util = @import("util.zig");
const Options = @import("../../Core.zig").Options;
const Event = @import("../../Core.zig").Event;
const KeyEvent = @import("../../Core.zig").KeyEvent;
const MouseButtonEvent = @import("../../Core.zig").MouseButtonEvent;
const MouseButton = @import("../../Core.zig").MouseButton;
const Size = @import("../../Core.zig").Size;
const DisplayMode = @import("../../Core.zig").DisplayMode;
const SizeLimit = @import("../../Core.zig").SizeLimit;
const CursorShape = @import("../../Core.zig").CursorShape;
const VSyncMode = @import("../../Core.zig").VSyncMode;
const CursorMode = @import("../../Core.zig").CursorMode;
const Key = @import("../../Core.zig").Key;
const KeyMods = @import("../../Core.zig").KeyMods;

pub const Core = @This();

allocator: std.mem.Allocator,
window: glfw.Window,
backend_type: gpu.BackendType,
user_ptr: UserPtr,

instance: *gpu.Instance,
surface: *gpu.Surface,
gpu_adapter: *gpu.Adapter,
gpu_device: *gpu.Device,
swap_chain: *gpu.SwapChain,
swap_chain_desc: gpu.SwapChain.Descriptor,

events: EventQueue,
wait_timeout: f64,

last_size: glfw.Window.Size,
last_pos: glfw.Window.Pos,
size_limit: SizeLimit,
frame_buffer_resized: bool,
display_mode: DisplayMode,
border: bool,

current_cursor: CursorShape,
cursors: [@typeInfo(CursorShape).Enum.fields.len]?glfw.Cursor,
cursors_tried: [@typeInfo(CursorShape).Enum.fields.len]bool,

linux_gamemode: ?bool,

const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);

pub const EventIterator = struct {
    queue: *EventQueue,

    pub inline fn next(self: *EventIterator) ?Event {
        return self.queue.readItem();
    }
};

const UserPtr = struct {
    self: *Core,
};

pub fn init(core: *Core, allocator: std.mem.Allocator, options: Options) !void {
    const backend_type = try util.detectBackendType(allocator);

    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{}))
        glfw.getErrorCode() catch |err| switch (err) {
            error.PlatformError,
            error.PlatformUnavailable,
            => return err,
            else => unreachable,
        };

    // Create the test window and discover adapters using it (esp. for OpenGL)
    var hints = util.glfwWindowHintsForBackend(backend_type);
    hints.cocoa_retina_framebuffer = true;
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
        std.log.err("mach: failed to create GPU instance", .{});
        std.process.exit(1);
    };
    const surface = util.createSurfaceForWindow(instance, window, comptime util.detectGLFWOptions());

    var response: util.RequestAdapterResponse = undefined;
    instance.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = surface,
        .power_preference = options.power_preference,
        .force_fallback_adapter = false,
    }, &response, util.requestAdapterCallback);
    if (response.status != .success) {
        std.log.err("mach: failed to create GPU adapter: {?s}", .{response.message});
        std.log.info("-> maybe try MACH_GPU_BACKEND=opengl ?", .{});
        std.process.exit(1);
    }

    // Print which adapter we are going to use.
    var props = std.mem.zeroes(gpu.Adapter.Properties);
    response.adapter.getProperties(&props);
    if (props.backend_type == .null) {
        std.log.err("no backend found for {s} adapter", .{props.adapter_type.name()});
        std.process.exit(1);
    }
    std.log.info("mach: found {s} backend on {s} adapter: {s}, {s}\n", .{
        props.backend_type.name(),
        props.adapter_type.name(),
        props.name,
        props.driver_description,
    });

    // Create a device with default limits/features.
    const gpu_device = response.adapter.createDevice(&.{
        .required_features_count = if (options.required_features) |v| @intCast(u32, v.len) else 0,
        .required_features = if (options.required_features) |v| @as(?[*]const gpu.FeatureName, v.ptr) else null,
        .required_limits = if (options.required_limits) |limits| @as(?*gpu.RequiredLimits, &gpu.RequiredLimits{
            .limits = limits,
        }) else null,
    }) orelse {
        std.log.err("mach: failed to create GPU device\n", .{});
        std.process.exit(1);
    };
    gpu_device.setUncapturedErrorCallback({}, util.printUnhandledErrorCallback);

    const framebuffer_size = window.getFramebufferSize();
    const swap_chain_desc = gpu.SwapChain.Descriptor{
        .label = "main swap chain",
        .usage = .{ .render_attachment = true },
        .format = .bgra8_unorm,
        .width = framebuffer_size.width,
        .height = framebuffer_size.height,
        .present_mode = .fifo,
    };
    const swap_chain = gpu_device.createSwapChain(surface, &swap_chain_desc);

    // The initial capacity we choose for the event queue is 2x our maximum expected event rate per
    // frame. Specifically, 1000hz mouse updates are likely the maximum event rate we will encounter
    // so we anticipate 2x that. If the event rate is higher than this per frame, it will grow to
    // that maximum (we never shrink the event queue capacity in order to avoid allocations causing
    // any stutter.)
    var events = EventQueue.init(allocator);
    try events.ensureTotalCapacity(2048);

    core.* = .{
        .allocator = allocator,
        .window = window,
        .backend_type = backend_type,
        .user_ptr = undefined,

        .instance = instance,
        .surface = surface,
        .gpu_adapter = response.adapter,
        .gpu_device = gpu_device,
        .swap_chain = swap_chain,
        .swap_chain_desc = swap_chain_desc,

        .events = events,
        .wait_timeout = 0.0,

        .last_size = window.getSize(),
        .last_pos = window.getPos(),
        .size_limit = .{
            .min = .{ .width = 350, .height = 350 },
            .max = .{ .width = null, .height = null },
        },
        .frame_buffer_resized = false,
        .display_mode = .windowed,
        .border = true,

        .current_cursor = .arrow,
        .cursors = std.mem.zeroes([@typeInfo(CursorShape).Enum.fields.len]?glfw.Cursor),
        .cursors_tried = std.mem.zeroes([@typeInfo(CursorShape).Enum.fields.len]bool),

        .linux_gamemode = null,
    };

    core.setSizeLimit(core.size_limit);

    core.initCallbacks();
    if (builtin.os.tag == .linux and !options.is_app and
        core.linux_gamemode == null and try activateGamemode(core.allocator))
        core.linux_gamemode = initLinuxGamemode();
}

fn initCallbacks(self: *Core) void {
    self.user_ptr = UserPtr{ .self = self };

    self.window.setUserPointer(&self.user_ptr);

    const key_callback = struct {
        fn callback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
            const pf = (window.getUserPointer(UserPtr) orelse unreachable).self;
            const key_event = KeyEvent{
                .key = toMachKey(key),
                .mods = toMachMods(mods),
            };
            switch (action) {
                .press => pf.pushEvent(.{ .key_press = key_event }),
                .repeat => pf.pushEvent(.{ .key_repeat = key_event }),
                .release => pf.pushEvent(.{ .key_release = key_event }),
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
            switch (action) {
                .press => pf.pushEvent(.{ .mouse_press = mouse_button_event }),
                .release => pf.pushEvent(.{
                    .mouse_release = mouse_button_event,
                }),
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
                    .xoffset = @floatCast(f32, xoffset),
                    .yoffset = @floatCast(f32, yoffset),
                },
            });
        }
    }.callback;
    self.window.setScrollCallback(scroll_callback);

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
            pf.frame_buffer_resized = true;
        }
    }.callback;
    self.window.setFramebufferSizeCallback(framebuffer_size_callback);
}

fn pushEvent(self: *Core, event: Event) void {
    // TODO(core): handle OOM via error flag
    self.events.writeItem(event) catch unreachable;
}

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
}

pub inline fn pollEvents(self: *Core) EventIterator {
    if (self.wait_timeout > 0.0) {
        if (self.wait_timeout == std.math.inf(f64)) {
            // Wait for an event
            glfw.waitEvents();
        } else {
            // Wait for an event with a timeout
            glfw.waitEventsTimeout(self.wait_timeout);
        }
    } else {
        // Don't wait for events
        glfw.pollEvents();
    }

    glfw.getErrorCode() catch |err| switch (err) {
        error.PlatformError => std.log.err("glfw: failed to poll events", .{}),
        error.InvalidValue => unreachable,
        else => unreachable,
    };

    if (self.frame_buffer_resized) blk: {
        self.frame_buffer_resized = false;

        const framebuffer_size = self.window.getFramebufferSize();
        glfw.getErrorCode() catch break :blk;

        if (framebuffer_size.width != 0 and framebuffer_size.height != 0) {
            self.swap_chain_desc.width = framebuffer_size.width;
            self.swap_chain_desc.height = framebuffer_size.height;
            self.swap_chain = self.gpu_device.createSwapChain(self.surface, &self.swap_chain_desc);
            self.pushEvent(.{
                .framebuffer_resize = .{
                    .width = framebuffer_size.width,
                    .height = framebuffer_size.height,
                },
            });
        }
    }

    if (self.window.shouldClose()) {
        self.pushEvent(.close);
    }

    return EventIterator{ .queue = &self.events };
}

pub fn shouldClose(self: *Core) bool {
    return self.window.shouldClose();
}

pub fn framebufferSize(self: *Core) Size {
    const framebuffer_size = self.window.getFramebufferSize();
    return .{
        .width = framebuffer_size.width,
        .height = framebuffer_size.height,
    };
}

pub fn setWaitTimeout(self: *Core, timeout: f64) void {
    self.wait_timeout = timeout;
}

pub fn setTitle(self: *Core, title: [:0]const u8) void {
    self.window.setTitle(title);
}

pub fn setDisplayMode(self: *Core, mode: DisplayMode, monitor_index: ?usize) void {
    switch (mode) {
        .windowed => {
            self.window.setAttrib(.decorated, self.border);
            self.window.setAttrib(.floating, false);
            self.window.setMonitor(
                null,
                @intCast(i32, self.last_pos.x),
                @intCast(i32, self.last_pos.y),
                self.last_size.width,
                self.last_size.height,
                null,
            );
        },
        .fullscreen => {
            if (self.display_mode == .windowed) {
                self.last_size = self.window.getSize();
                self.last_pos = self.window.getPos();
            }

            const monitor = blk: {
                if (monitor_index) |i| {
                    // TODO(core): handle OOM via error flag
                    const monitor_list = glfw.Monitor.getAll(self.allocator) catch unreachable;
                    defer self.allocator.free(monitor_list);
                    break :blk monitor_list[i];
                }
                break :blk glfw.Monitor.getPrimary();
            };
            if (monitor) |m| {
                const video_mode = m.getVideoMode();
                if (video_mode) |v| {
                    self.window.setMonitor(m, 0, 0, v.getWidth(), v.getHeight(), null);
                }
            }
        },
        .borderless => {
            if (self.display_mode == .windowed) {
                self.last_size = self.window.getSize();
                self.last_pos = self.window.getPos();
            }

            const monitor = blk: {
                if (monitor_index) |i| {
                    // TODO(core): handle OOM via error flag
                    const monitor_list = glfw.Monitor.getAll(self.allocator) catch unreachable;
                    defer self.allocator.free(monitor_list);
                    break :blk monitor_list[i];
                }
                break :blk glfw.Monitor.getPrimary();
            };
            if (monitor) |m| {
                const video_mode = m.getVideoMode();
                if (video_mode) |v| {
                    self.window.setAttrib(.decorated, false);
                    self.window.setAttrib(.floating, true);
                    self.window.setMonitor(null, 0, 0, v.getWidth(), v.getHeight(), null);
                }
            }
        },
    }
    self.display_mode = mode;
}

pub fn displayMode(self: *Core) DisplayMode {
    return self.display_mode;
}

pub fn setBorder(self: *Core, value: bool) void {
    if (self.border != value) {
        self.border = value;
        if (self.display_mode != .borderless) self.window.setAttrib(.decorated, value);
    }
}

pub fn border(self: *Core) bool {
    return self.border;
}

pub fn setHeadless(self: *Core, value: bool) void {
    if (value) {
        self.window.hide();
    } else {
        self.window.show();
    }
}

pub fn headless(self: *Core) bool {
    const visible = self.window.getAttrib(.visible);
    return visible == 0;
}

pub fn setVSync(self: *Core, mode: VSyncMode) void {
    const framebuffer_size = self.framebufferSize();
    self.swap_chain_desc.present_mode = switch (mode) {
        .none => .immediate,
        .double => .fifo,
        .triple => .mailbox,
    };
    self.swap_chain_desc.width = framebuffer_size.width;
    self.swap_chain_desc.height = framebuffer_size.height;
    self.swap_chain = self.gpu_device.createSwapChain(self.surface, &self.swap_chain_desc);
}

pub fn vsync(self: *Core) VSyncMode {
    return switch (self.swap_chain_desc.present_mode) {
        .immediate => .none,
        .fifo => .double,
        .mailbox => .triple,
    };
}

pub fn setSize(self: *Core, value: Size) void {
    self.window.setSize(.{
        .width = value.width,
        .height = value.height,
    });
}

pub fn size(self: *Core) Size {
    const window_size = self.window.getSize();
    return .{ .width = window_size.width, .height = window_size.height };
}

pub fn setSizeLimit(self: *Core, limit: SizeLimit) void {
    self.window.setSizeLimits(
        .{ .width = limit.min.width, .height = limit.min.height },
        .{ .width = limit.max.width, .height = limit.max.height },
    );
    self.size_limit = limit;
}

pub fn sizeLimit(self: *Core) SizeLimit {
    return self.size_limit;
}

pub fn setCursorMode(self: *Core, mode: CursorMode) void {
    const glfw_mode: glfw.Window.InputModeCursor = switch (mode) {
        .normal => .normal,
        .hidden => .hidden,
        .disabled => .disabled,
    };
    self.window.setInputModeCursor(glfw_mode);
}

pub fn cursorMode(self: *Core) CursorMode {
    const glfw_mode = self.window.getInputModeCursor();
    return switch (glfw_mode) {
        .normal => .normal,
        .hidden => .hidden,
        .disabled => .disabled,
    };
}

pub fn setCursorShape(self: *Core, cursor: CursorShape) void {
    // Try to create glfw standard cursor, but could fail.  In the future
    // we hope to provide custom backup images for these.
    // See https://github.com/hexops/mach/pull/352 for more info

    const enum_int = @enumToInt(cursor);
    const tried = self.cursors_tried[enum_int];
    if (!tried) {
        self.cursors_tried[enum_int] = true;
        self.cursors[enum_int] = switch (cursor) {
            .arrow => glfw.Cursor.createStandard(.arrow) catch null,
            .ibeam => glfw.Cursor.createStandard(.ibeam) catch null,
            .crosshair => glfw.Cursor.createStandard(.crosshair) catch null,
            .pointing_hand => glfw.Cursor.createStandard(.pointing_hand) catch null,
            .resize_ew => glfw.Cursor.createStandard(.resize_ew) catch null,
            .resize_ns => glfw.Cursor.createStandard(.resize_ns) catch null,
            .resize_nwse => glfw.Cursor.createStandard(.resize_nwse) catch null,
            .resize_nesw => glfw.Cursor.createStandard(.resize_nesw) catch null,
            .resize_all => glfw.Cursor.createStandard(.resize_all) catch null,
            .not_allowed => glfw.Cursor.createStandard(.not_allowed) catch null,
        };
    }

    if (self.cursors[enum_int]) |cur| {
        self.window.setCursor(cur);
    } else {
        // TODO: In the future we shouldn't hit this because we'll provide backup
        // custom cursors.
        // See https://github.com/hexops/mach/pull/352 for more info
        std.log.warn("mach: setCursorShape: {s} not yet supported\n", .{@tagName(cursor)});
    }

    self.current_cursor = cursor;
}

pub fn cursorShape(self: *Core) CursorShape {
    return self.current_cursor;
}

pub fn adapter(self: *Core) *gpu.Adapter {
    return self.gpu_adapter;
}

pub fn device(self: *Core) *gpu.Device {
    return self.gpu_device;
}

pub fn swapChain(self: *Core) *gpu.SwapChain {
    return self.swap_chain;
}

pub fn descriptor(self: *Core) gpu.SwapChain.Descriptor {
    return self.swap_chain_desc;
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

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) error{ OutOfMemory, InvalidUtf8 }!?[]u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => @as(?[]u8, null),
        else => |e| e,
    };
}

/// Check if gamemode should be activated
fn activateGamemode(allocator: std.mem.Allocator) error{ OutOfMemory, InvalidUtf8 }!bool {
    if (try getEnvVarOwned(allocator, "MACH_USE_GAMEMODE")) |env| {
        defer allocator.free(env);
        return !(std.ascii.eqlIgnoreCase(env, "off") or std.ascii.eqlIgnoreCase(env, "false"));
    }
    return true;
}

fn initLinuxGamemode() bool {
    const gamemode = @import("gamemode");
    gamemode.requestStart() catch |err| {
        if (!std.mem.containsAtLeast(u8, gamemode.errorString(), 1, "dlopen failed"))
            std.log.err("Gamemode error {} -> {s}", .{ err, gamemode.errorString() });
        return false;
    };
    std.log.info("Gamemode activated", .{});
    return true;
}

fn deinitLinuxGamemode() void {
    const gamemode = @import("gamemode");
    gamemode.requestEnd() catch |err| {
        std.log.err("Gamemode error {} -> {s}", .{ err, gamemode.errorString() });
    };
}
