const builtin = @import("builtin");
const std = @import("std");
const glfw = @import("mach-glfw");
const mach = @import("../../../main.zig");
const mach_core = @import("../../main.zig");
const gpu = mach.gpu;
const unicode = @import("unicode.zig");
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
const RequestAdapterResponse = @import("../common.zig").RequestAdapterResponse;
const printUnhandledErrorCallback = @import("../common.zig").printUnhandledErrorCallback;
const detectBackendType = @import("../common.zig").detectBackendType;
const wantGamemode = @import("../common.zig").wantGamemode;
const initLinuxGamemode = @import("../common.zig").initLinuxGamemode;
const deinitLinuxGamemode = @import("../common.zig").deinitLinuxGamemode;
const requestAdapterCallback = @import("../common.zig").requestAdapterCallback;

pub const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xatom.h");
    @cInclude("X11/cursorfont.h");
    @cInclude("X11/Xcursor/Xcursor.h");
    @cInclude("X11/extensions/Xrandr.h");
});

const log = std.log.scoped(.mach);

pub const defaultLog = std.log.defaultLog;
pub const defaultPanic = std.debug.panicImpl;

const LibX11 = struct {
    handle: std.DynLib,

    XInitThreads: *const @TypeOf(c.XInitThreads),
    XrmInitialize: *const @TypeOf(c.XrmInitialize),
    XOpenDisplay: *const @TypeOf(c.XOpenDisplay),
    XCloseDisplay: *const @TypeOf(c.XCloseDisplay),
    XCreateWindow: *const @TypeOf(c.XCreateWindow),
    XSelectInput: *const @TypeOf(c.XSelectInput),
    XMapWindow: *const @TypeOf(c.XMapWindow),
    XNextEvent: *const @TypeOf(c.XNextEvent),
    XDisplayWidth: *const @TypeOf(c.XDisplayWidth),
    XDisplayHeight: *const @TypeOf(c.XDisplayHeight),
    XCreateColormap: *const @TypeOf(c.XCreateColormap),
    XSetErrorHandler: *const @TypeOf(c.XSetErrorHandler),
    XGetWindowAttributes: *const @TypeOf(c.XGetWindowAttributes),
    XStoreName: *const @TypeOf(c.XStoreName),
    XFreeColormap: *const @TypeOf(c.XFreeColormap),
    XUnmapWindow: *const @TypeOf(c.XUnmapWindow),
    XDestroyWindow: *const @TypeOf(c.XDestroyWindow),
    XFlush: *const @TypeOf(c.XFlush),
    XLookupString: *const @TypeOf(c.XLookupString),
    XQueryPointer: *const @TypeOf(c.XQueryPointer),
    XInternAtom: *const @TypeOf(c.XInternAtom),
    XSendEvent: *const @TypeOf(c.XSendEvent),
    XSetWMProtocols: *const @TypeOf(c.XSetWMProtocols),
    XDefineCursor: *const @TypeOf(c.XDefineCursor),
    XUndefineCursor: *const @TypeOf(c.XUndefineCursor),
    XCreatePixmap: *const @TypeOf(c.XCreatePixmap),
    XCreateGC: *const @TypeOf(c.XCreateGC),
    XDrawPoint: *const @TypeOf(c.XDrawPoint),
    XFreeGC: *const @TypeOf(c.XFreeGC),
    XCreatePixmapCursor: *const @TypeOf(c.XCreatePixmapCursor),
    XGrabPointer: *const @TypeOf(c.XGrabPointer),
    XUngrabPointer: *const @TypeOf(c.XUngrabPointer),
    XCreateFontCursor: *const @TypeOf(c.XCreateFontCursor),
    XFreeCursor: *const @TypeOf(c.XFreeCursor),
    XChangeProperty: *const @TypeOf(c.XChangeProperty),
    XResizeWindow: *const @TypeOf(c.XResizeWindow),
    XConfigureWindow: *const @TypeOf(c.XConfigureWindow),
    XSetWMHints: *const @TypeOf(c.XSetWMHints),
    XDeleteProperty: *const @TypeOf(c.XDeleteProperty),
    XAllocSizeHints: *const @TypeOf(c.XAllocSizeHints),
    XSetWMNormalHints: *const @TypeOf(c.XSetWMNormalHints),
    XFree: *const @TypeOf(c.XFree),

    pub fn load() !LibX11 {
        var lib: LibX11 = undefined;
        lib.handle = std.DynLib.openZ("libX11.so.6") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibX11).Struct.fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse return error.SymbolLookup;
        }
        return lib;
    }
};

const LibXCursor = struct {
    handle: std.DynLib,

    XcursorImageCreate: *const @TypeOf(c.XcursorImageCreate),
    XcursorImageDestroy: *const @TypeOf(c.XcursorImageDestroy),
    XcursorImageLoadCursor: *const @TypeOf(c.XcursorImageLoadCursor),
    XcursorGetTheme: *const @TypeOf(c.XcursorGetTheme),
    XcursorGetDefaultSize: *const @TypeOf(c.XcursorGetDefaultSize),
    XcursorLibraryLoadImage: *const @TypeOf(c.XcursorLibraryLoadImage),

    pub fn load() !LibXCursor {
        var lib: LibXCursor = undefined;
        lib.handle = std.DynLib.openZ("libXcursor.so.1") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibXCursor).Struct.fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse return error.SymbolLookup;
        }
        return lib;
    }
};

const LibXRR = struct {
    handle: std.DynLib,

    XRRGetScreenInfo: *const @TypeOf(c.XRRGetScreenInfo),
    XRRConfigCurrentRate: *const @TypeOf(c.XRRConfigCurrentRate),

    pub fn load() !LibXRR {
        var lib: LibXRR = undefined;
        lib.handle = std.DynLib.openZ("libXrandr.so.1") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibXRR).Struct.fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse return error.SymbolLookup;
        }
        return lib;
    }
};

const LibGL = struct {
    const Drawable = c.XID;
    const Context = opaque {};
    const FBConfig = opaque {};

    const rgba = 4;
    const doublebuffer = 5;
    const red_size = 8;
    const green_size = 9;
    const blue_size = 10;
    const depth_size = 12;
    const stencil_size = 13;
    const sample_buffers = 0x186a0;
    const samples = 0x186a1;

    handle: std.DynLib,

    glXCreateContext: *const fn (*c.Display, *c.XVisualInfo, ?*Context, bool) callconv(.C) ?*Context,
    glXDestroyContext: *const fn (*c.Display, ?*Context) callconv(.C) void,
    glXMakeCurrent: *const fn (*c.Display, Drawable, ?*Context) callconv(.C) bool,
    glXChooseVisual: *const fn (*c.Display, c_int, [*]const c_int) callconv(.C) *c.XVisualInfo,
    glXSwapBuffers: *const fn (*c.Display, Drawable) callconv(.C) bool,

    pub fn load() !LibGL {
        var lib: LibGL = undefined;
        lib.handle = std.DynLib.openZ("libGL.so.1") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibGL).Struct.fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse return error.SymbolLookup;
        }
        return lib;
    }
};

pub const Core = @This();

// There are two threads:
//
// 1. Main thread (App.init, App.deinit) which may interact with GLFW and handles events
// 2. App.update thread.

// Read-only fields
allocator: std.mem.Allocator,
display: *c.Display,
libx11: LibX11,
libxrr: ?LibXRR,
libgl: ?LibGL,
libxcursor: ?LibXCursor,
width: c_int,
height: c_int,
empty_event_pipe: [2]std.os.fd_t,
gl_ctx: ?*LibGL.Context,
wm_protocols: c.Atom,
wm_delete_window: c.Atom,
net_wm_ping: c.Atom,
net_wm_state_fullscreen: c.Atom,
net_wm_state: c.Atom,
net_wm_state_above: c.Atom,
net_wm_bypass_compositor: c.Atom,
motif_wm_hints: c.Atom,
net_wm_window_type: c.Atom,
net_wm_window_type_dock: c.Atom,
root_window: c.Window,
frame: *Frequency,
input: *Frequency,
window: c.Window,
backend_type: gpu.BackendType,
user_ptr: UserPtr,
instance: *gpu.Instance,
surface: *gpu.Surface,
gpu_adapter: *gpu.Adapter,
gpu_device: *gpu.Device,
refresh_rate: u32,
hidden_cursor: c.Cursor,

// Mutable fields only used by main thread
app_update_thread_started: bool = false,
linux_gamemode: ?bool = null,
cursors: [@typeInfo(CursorShape).Enum.fields.len]?c.Cursor,
last_windowed_size: mach_core.Size,

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
    if (!@import("builtin").is_test and !mach.use_sysgpu) _ = mach.wgpu.Export(mach.wgpu.Impl);
    if (!@import("builtin").is_test and mach.use_sysgpu) _ = mach.sysgpu.sysgpu.Export(mach.sysgpu.Impl);

    const libx11 = try LibX11.load();
    const libxcursor: ?LibXCursor = LibXCursor.load() catch |err| switch (err) {
        error.LibraryNotFound => null,
        else => return err,
    };
    const libxrr: ?LibXRR = LibXRR.load() catch |err| switch (err) {
        error.LibraryNotFound => null,
        else => return err,
    };
    const libgl: ?LibGL = LibGL.load() catch |err| switch (err) {
        error.LibraryNotFound => null,
        else => return err,
    };

    _ = libx11.XSetErrorHandler(errorHandler);
    _ = libx11.XInitThreads();
    _ = libx11.XrmInitialize();

    const display = libx11.XOpenDisplay(null) orelse {
        std.log.err("X11: Cannot open display", .{});
        return error.CannotOpenDisplay;
    };

    const screen = c.DefaultScreen(display);
    const root_window = c.RootWindow(display, screen);
    const visual = c.DefaultVisual(display, screen);
    const colormap = libx11.XCreateColormap(display, root_window, visual, c.AllocNone);
    var set_window_attrs = c.XSetWindowAttributes{
        .colormap = colormap,
        // TODO: reduce
        .event_mask = c.StructureNotifyMask | c.KeyPressMask | c.KeyReleaseMask |
            c.PointerMotionMask | c.ButtonPressMask | c.ButtonReleaseMask |
            c.ExposureMask | c.FocusChangeMask | c.VisibilityChangeMask |
            c.EnterWindowMask | c.LeaveWindowMask | c.PropertyChangeMask,
    };
    defer _ = libx11.XFreeColormap(display, colormap);

    const empty_event_pipe = try std.os.pipe();
    for (0..2) |i| {
        const sf = try std.os.fcntl(empty_event_pipe[i], std.os.F.GETFL, 0);
        const df = try std.os.fcntl(empty_event_pipe[i], std.os.F.GETFD, 0);
        _ = try std.os.fcntl(empty_event_pipe[i], std.os.F.SETFL, sf | std.os.O.NONBLOCK);
        _ = try std.os.fcntl(empty_event_pipe[i], std.os.F.SETFD, df | std.os.FD_CLOEXEC);
    }

    const window = libx11.XCreateWindow(
        display,
        root_window,
        @divFloor(libx11.XDisplayWidth(display, screen), 2), // TODO: add window width?
        @divFloor(libx11.XDisplayHeight(display, screen), 2), // TODO: add window height?
        options.size.width,
        options.size.height,
        0,
        c.DefaultDepth(display, screen),
        c.InputOutput,
        visual,
        c.CWColormap | c.CWEventMask,
        &set_window_attrs,
    );

    const wm_protocols = libx11.XInternAtom(display, "WM_PROTOCOLS", c.False);
    const wm_delete_window = libx11.XInternAtom(display, "WM_DELETE_WINDOW", c.False);
    const net_wm_ping = libx11.XInternAtom(display, "NET_WM_PING", c.False);
    const net_wm_state_fullscreen = libx11.XInternAtom(display, "_NET_WM_STATE_FULLSCREEN", c.False);
    const net_wm_state = libx11.XInternAtom(display, "_NET_WM_STATE", c.False);
    const net_wm_state_above = libx11.XInternAtom(display, "_NET_WM_STATE_ABOVE", c.False);
    const motif_wm_hints = libx11.XInternAtom(display, "_MOTIF_WM_HINTS", c.False);
    const net_wm_window_type = libx11.XInternAtom(display, "_NET_WM_WINDOW_TYPE", c.False);
    const net_wm_window_type_dock = libx11.XInternAtom(display, "_NET_WM_WINDOW_TYPE_DOCK", c.False);
    const net_wm_bypass_compositor = libx11.XInternAtom(display, "_NET_WM_BYPASS_COMPOSITOR", c.False);

    var protocols = [_]c.Atom{ wm_delete_window, net_wm_ping };
    _ = libx11.XSetWMProtocols(display, window, &protocols, protocols.len);

    _ = libx11.XStoreName(display, window, options.title.ptr);
    _ = libx11.XSelectInput(display, window, set_window_attrs.event_mask);
    _ = libx11.XMapWindow(display, window);

    var window_attrs: c.XWindowAttributes = undefined;
    _ = libx11.XGetWindowAttributes(display, window, &window_attrs);

    const backend_type = try detectBackendType(allocator);

    const refresh_rate: u16 = blk: {
        if (libxrr != null) {
            const conf = libxrr.?.XRRGetScreenInfo(display, root_window);
            break :blk @intCast(libxrr.?.XRRConfigCurrentRate(conf));
        }
        break :blk 60;
    };
    frame.target = 2 * refresh_rate;

    var gl_ctx: ?*LibGL.Context = null;
    switch (backend_type) {
        .opengl, .opengles => {
            if (libgl != null) {
                // zig fmt: off
                const attrs = &[_]c_int{
                    LibGL.rgba,
                    LibGL.doublebuffer,
                    LibGL.depth_size,     24,
                    LibGL.stencil_size,   8,
                    LibGL.red_size,       8,
                    LibGL.green_size,     8,
                    LibGL.blue_size,      8,
                    LibGL.sample_buffers, 0,
                    LibGL.samples,        0,
                    c.None,
                };
                // zig fmt: on

                const visual_info = libgl.?.glXChooseVisual(display, screen, attrs.ptr);
                defer _ = libx11.XFree(visual_info);
                gl_ctx = libgl.?.glXCreateContext(display, visual_info, null, true);
                _ = libgl.?.glXMakeCurrent(display, window, gl_ctx);
            } else {
                return error.LibGLNotFound;
            }
        },
        else => {},
    }

    const instance = gpu.createInstance(null) orelse {
        log.err("failed to create GPU instance", .{});
        std.process.exit(1);
    };
    const surface = instance.createSurface(&gpu.Surface.Descriptor{
        .next_in_chain = .{
            .from_xlib_window = &.{
                .display = display,
                .window = @intCast(window),
            },
        },
    });

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

    const swap_chain_desc = gpu.SwapChain.Descriptor{
        .label = "main swap chain",
        .usage = options.swap_chain_usage,
        .format = .bgra8_unorm,
        .width = @intCast(window_attrs.width),
        .height = @intCast(window_attrs.height),
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

    const window_size = mach_core.Size{ .width = @intCast(window_attrs.width), .height = @intCast(window_attrs.height) };

    // Create hidden cursor
    const blank_pixmap = libx11.XCreatePixmap(display, window, 1, 1, 1);
    const gc = libx11.XCreateGC(display, blank_pixmap, 0, null);
    if (gc != null) {
        _ = libx11.XDrawPoint(display, blank_pixmap, gc, 0, 0);
        _ = libx11.XFreeGC(display, gc);
    }
    var color = c.XColor{};
    const hidden_cursor = libx11.XCreatePixmapCursor(display, blank_pixmap, blank_pixmap, &color, &color, 0, 0);

    core.* = .{
        .allocator = allocator,
        .display = display,
        .libx11 = libx11,
        .libgl = libgl,
        .libxcursor = libxcursor,
        .libxrr = libxrr,
        .empty_event_pipe = empty_event_pipe,
        .gl_ctx = gl_ctx,
        .width = window_attrs.width,
        .height = window_attrs.height,
        .wm_protocols = wm_protocols,
        .wm_delete_window = wm_delete_window,
        .net_wm_ping = net_wm_ping,
        .net_wm_state_fullscreen = net_wm_state_fullscreen,
        .net_wm_state = net_wm_state,
        .net_wm_state_above = net_wm_state_above,
        .net_wm_window_type = net_wm_window_type,
        .net_wm_window_type_dock = net_wm_window_type_dock,
        .net_wm_bypass_compositor = net_wm_bypass_compositor,
        .motif_wm_hints = motif_wm_hints,
        .root_window = root_window,
        .frame = frame,
        .input = input,
        .window = window,
        .hidden_cursor = hidden_cursor,
        .backend_type = backend_type,
        .user_ptr = .{ .self = core },
        .instance = instance,
        .surface = surface,
        .gpu_adapter = response.adapter.?,
        .gpu_device = gpu_device,
        .refresh_rate = refresh_rate,
        .swap_chain = swap_chain,
        .swap_chain_desc = swap_chain_desc,
        .events = events,
        .current_title = options.title,
        .current_display_mode = options.display_mode,
        .last_display_mode = .windowed,
        .current_border = options.border,
        .last_border = true,
        .current_headless = options.headless,
        .last_headless = options.headless,
        .current_size = window_size,
        .last_size = window_size,
        .last_windowed_size = window_size,
        .cursors = std.mem.zeroes([@typeInfo(CursorShape).Enum.fields.len]?c.Cursor),
        .present_joysticks = std.StaticBitSet(@typeInfo(glfw.Joystick.Id).Enum.fields.len).initEmpty(),
    };
    core.cursors[@intFromEnum(CursorShape.arrow)] = try core.createStandardCursor(.arrow);

    core.state_update.set();
    try core.input.start();

    if (builtin.os.tag == .linux and !options.is_app and
        core.linux_gamemode == null and try wantGamemode(core.allocator))
        core.linux_gamemode = initLinuxGamemode();
}

// const joystick_callback = struct {
//     fn callback(joystick: glfw.Joystick, event: glfw.Joystick.Event) void {
//         const idx: u8 = @intCast(@intFromEnum(joystick.jid));

//         switch (event) {
//             .connected => {
//                 pf.input_mu.lock();
//                 pf.present_joysticks.set(idx);
//                 pf.input_mu.unlock();
//                 pf.pushEvent(.{
//                     .joystick_connected = @enumFromInt(idx),
//                 });
//             },
//             .disconnected => {
//                 pf.input_mu.lock();
//                 pf.present_joysticks.unset(idx);
//                 pf.input_mu.unlock();
//                 pf.pushEvent(.{
//                     .joystick_disconnected = @enumFromInt(idx),
//                 });
//             },
//         }
//     }
// }.callback;
// glfw.Joystick.setCallback(joystick_callback);

fn pushEvent(self: *Core, event: Event) void {
    self.events_mu.lock();
    defer self.events_mu.unlock();
    self.events.writeItem(event) catch self.oom.set();
}

// Called on the main thread
pub fn deinit(self: *Core) void {
    for (self.cursors) |cur| {
        if (cur) |_| {
            // _ = self.libx11.XFreeCursor(self.display, cur.?);
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

    if (self.libxcursor) |*libxcursor| {
        libxcursor.handle.close();
    }

    if (self.libxrr) |*libxrr| {
        libxrr.handle.close();
    }

    if (self.libgl) |*libgl| {
        if (self.gl_ctx) |gl_ctx| {
            libgl.glXDestroyContext(self.display, gl_ctx);
        }
        libgl.handle.close();
    }

    _ = self.libx11.XUnmapWindow(self.display, self.window);
    _ = self.libx11.XDestroyWindow(self.display, self.window);
    _ = self.libx11.XCloseDisplay(self.display);
    self.libx11.handle.close();

    std.os.close(self.empty_event_pipe[0]);
    std.os.close(self.empty_event_pipe[1]);
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
                    .triple => self.frame.target = 2 * self.refresh_rate,
                    else => self.frame.target = 0,
                }
            }

            if (self.current_size.width == 0 or self.current_size.height == 0) break :blk;

            self.swap_chain_mu.lock();
            defer self.swap_chain_mu.unlock();
            mach_core.swap_chain.release();
            self.swap_chain_desc.width = self.current_size.width;
            self.swap_chain_desc.height = self.current_size.height;
            self.swap_chain = self.gpu_device.createSwapChain(self.surface, &self.swap_chain_desc);

            mach_core.swap_chain = self.swap_chain;
            mach_core.descriptor = self.swap_chain_desc;

            self.pushEvent(.{
                .framebuffer_resize = .{
                    .width = self.current_size.width,
                    .height = self.current_size.height,
                },
            });
        }

        if (app.update() catch unreachable) {
            self.done.set();

            // Wake the main thread from any event handling, so there is not e.g. a one second delay
            // in exiting the application.
            self.wakeMainThread();
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

    while (c.QLength(self.display) != 0) {
        var event: c.XEvent = undefined;
        _ = self.libx11.XNextEvent(self.display, &event);
        self.processEvent(&event);
    }
    _ = self.libx11.XFlush(self.display);

    if (self.state_update.isSet()) {
        self.state_update.reset();

        // Title changes
        if (self.current_title_changed) {
            self.current_title_changed = false;
            _ = self.libx11.XStoreName(self.display, self.window, self.current_title.ptr);
        }

        // Display mode changes
        if (self.current_display_mode != self.last_display_mode) {
            switch (self.current_display_mode) {
                .windowed => {
                    var atoms = std.BoundedArray(c.Atom, 5){};

                    if (self.last_display_mode == .fullscreen) {
                        atoms.append(self.net_wm_state_fullscreen) catch unreachable;
                    }

                    atoms.append(self.motif_wm_hints) catch unreachable;

                    // TODO
                    // if (self.floating) {
                    // 	atoms.append(self.net_wm_state_above) catch unreachable;
                    // }
                    _ = self.libx11.XChangeProperty(
                        self.display,
                        self.window,
                        self.net_wm_state,
                        c.XA_ATOM,
                        32,
                        c.PropModeReplace,
                        @ptrCast(atoms.slice()),
                        atoms.len,
                    );

                    self.setFullscreen(false);
                    self.setDecorated(self.current_border);
                    self.setFloating(false);
                    _ = self.libx11.XMapWindow(self.display, self.window);
                    _ = self.libx11.XFlush(self.display);
                },
                .fullscreen => {
                    if (self.last_display_mode == .windowed) {
                        self.last_windowed_size = self.current_size;
                    }

                    self.setFullscreen(true);
                    _ = self.libx11.XFlush(self.display);
                },
                .borderless => {
                    if (self.last_display_mode == .windowed) {
                        self.last_windowed_size = self.current_size;
                    }

                    self.setDecorated(false);
                    self.setFloating(true);
                    self.setFullscreen(false);

                    _ = self.libx11.XResizeWindow(
                        self.display,
                        self.window,
                        @intCast(c.DisplayWidth(self.display, c.DefaultScreen(self.display))),
                        @intCast(c.DisplayHeight(self.display, c.DefaultScreen(self.display))),
                    );
                    _ = self.libx11.XFlush(self.display);
                },
            }

            self.last_display_mode = self.current_display_mode;
        }

        // Border changes
        if (self.current_border != self.last_border) {
            self.last_border = self.current_border;
            // if (self.current_display_mode != .borderless) self.window.setAttrib(.decorated, self.current_border);
        }

        // Headless changes
        if (self.current_headless != self.last_headless) {
            self.current_headless = self.last_headless;
            // if (self.current_headless) self.window.hide() else self.window.show();
        }

        // Size changes
        if (!self.current_size.eql(self.last_size)) {
            self.last_size = self.current_size;
            _ = self.libx11.XResizeWindow(self.display, self.window, self.current_size.width, self.current_size.height);
            _ = self.libx11.XFlush(self.display);
        }

        // Size limit changes
        if (!self.current_size_limit.eql(self.last_size_limit)) {
            self.last_size_limit = self.current_size_limit;
            // self.window.setSizeLimits(
            //     .{ .width = self.current_size_limit.min.width, .height = self.current_size_limit.min.height },
            //     .{ .width = self.current_size_limit.max.width, .height = self.current_size_limit.max.height },
            // );
        }

        // Cursor mode changes
        if (self.current_cursor_mode != self.last_cursor_mode) {
            self.updateCursor();
            self.last_cursor_mode = self.current_cursor_mode;
        }

        // Cursor shape changes
        if (self.current_cursor_shape != self.last_cursor_shape) {
            self.last_cursor_shape = self.current_cursor_shape;
            const cursor = self.createStandardCursor(self.current_cursor_shape) catch |err| blk: {
                log.warn("mach: setCursorShape: {}: {s} not yet supported\n", .{
                    err,
                    @tagName(self.current_cursor_shape),
                });
                break :blk null;
            };
            self.cursors[@intFromEnum(self.current_cursor_shape)] = cursor;
            self.updateCursor();
        }
    }

    // const frequency_delay = @as(f32, @floatFromInt(self.input.delay_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));
    // glfw.waitEventsTimeout(frequency_delay);

    if (@hasDecl(std.meta.Child(@TypeOf(app)), "updateMainThread")) {
        if (app.updateMainThread() catch unreachable) {
            self.done.set();
            return true;
        }
    }

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
    @panic("TODO: implement joystickPresent for X11");
}

// May be called from any thread.
pub fn joystickName(_: *Core, _: Joystick) ?[:0]const u8 {
    @panic("TODO: implement joystickName for X11");
}

// May be called from any thread.
pub fn joystickButtons(_: *Core, _: Joystick) ?[]const bool {
    @panic("TODO: implement joystickButtons for X11");
}

// May be called from any thread.
pub fn joystickAxes(_: *Core, _: Joystick) ?[]const f32 {
    @panic("TODO: implement joystickAxes for X11");
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
    while (true) {
        const result = std.os.write(self.empty_event_pipe[1], &.{0}) catch break;
        if (result == 1) break;
    }
}

fn processEvent(self: *Core, event: *c.XEvent) void {
    switch (event.type) {
        c.KeyPress, c.KeyRelease => {
            // TODO: key repeat event

            var keysym: c.KeySym = undefined;
            _ = self.libx11.XLookupString(&event.xkey, null, 0, &keysym, null);

            const key_event = KeyEvent{ .key = toMachKey(keysym), .mods = toMachMods(event.xkey.state) };

            switch (event.type) {
                c.KeyPress => {
                    self.input_mu.lock();
                    self.input_state.keys.set(@intFromEnum(key_event.key));
                    self.input_mu.unlock();
                    self.pushEvent(.{ .key_press = key_event });

                    if (unicode.unicodeFromKeySym(keysym)) |codepoint| {
                        self.pushEvent(.{ .char_input = .{ .codepoint = codepoint } });
                    }
                },
                c.KeyRelease => {
                    self.input_mu.lock();
                    self.input_state.keys.unset(@intFromEnum(key_event.key));
                    self.input_mu.unlock();
                    self.pushEvent(.{ .key_release = key_event });
                },
                else => unreachable,
            }
        },
        c.ButtonPress => {
            const button = toMachButton(event.xbutton.button) orelse {
                // Modern X provides scroll events as mouse button presses
                const scroll: struct { f32, f32 } = switch (event.xbutton.button) {
                    c.Button4 => .{ 0.0, 1.0 },
                    c.Button5 => .{ 0.0, -1.0 },
                    6 => .{ 1.0, 0.0 },
                    7 => .{ -1.0, 0.0 },
                    else => unreachable,
                };
                self.pushEvent(.{ .mouse_scroll = .{ .xoffset = scroll[0], .yoffset = scroll[1] } });
                return;
            };
            const cursor_pos = self.getCursorPos();
            const mouse_button = MouseButtonEvent{
                .button = button,
                .pos = cursor_pos,
                .mods = toMachMods(event.xbutton.state),
            };

            self.input_mu.lock();
            self.input_state.mouse_buttons.set(@intFromEnum(mouse_button.button));
            self.input_mu.unlock();
            self.pushEvent(.{ .mouse_press = mouse_button });
        },
        c.ButtonRelease => {
            const button = toMachButton(event.xbutton.button) orelse return;
            const cursor_pos = self.getCursorPos();
            const mouse_button = MouseButtonEvent{
                .button = button,
                .pos = cursor_pos,
                .mods = toMachMods(event.xbutton.state),
            };

            self.input_mu.lock();
            self.input_state.mouse_buttons.unset(@intFromEnum(mouse_button.button));
            self.input_mu.unlock();
            self.pushEvent(.{ .mouse_release = mouse_button });
        },
        c.ClientMessage => {
            if (event.xclient.message_type == c.None) return;

            if (event.xclient.message_type == self.wm_protocols) {
                const protocol = event.xclient.data.l[0];
                if (protocol == c.None) return;

                if (protocol == self.wm_delete_window) {
                    self.pushEvent(.close);
                } else if (protocol == self.net_wm_ping) {
                    // The window manager is pinging the application to ensure
                    // it's still responding to events
                    var reply = event.*;
                    reply.xclient.window = self.root_window;
                    _ = self.libx11.XSendEvent(
                        self.display,
                        self.root_window,
                        c.False,
                        c.SubstructureNotifyMask | c.SubstructureRedirectMask,
                        &reply,
                    );
                }
            }
        },
        c.EnterNotify => {
            const x: f32 = @floatFromInt(event.xcrossing.x);
            const y: f32 = @floatFromInt(event.xcrossing.y);
            self.input_mu.lock();
            self.input_state.mouse_position = .{ .x = x, .y = y };
            self.input_mu.unlock();
            self.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
        },
        c.MotionNotify => {
            const x: f32 = @floatFromInt(event.xmotion.x);
            const y: f32 = @floatFromInt(event.xmotion.y);
            self.input_mu.lock();
            self.input_state.mouse_position = .{ .x = x, .y = y };
            self.input_mu.unlock();
            self.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
        },
        c.ConfigureNotify => {
            if (event.xconfigure.width != self.last_size.width or
                event.xconfigure.height != self.last_size.height)
            {
                self.state_mu.lock();
                defer self.state_mu.unlock();
                self.current_size.width = @intCast(event.xconfigure.width);
                self.current_size.height = @intCast(event.xconfigure.height);
                self.swap_chain_update.set();
            }
        },
        c.FocusIn => {
            if (event.xfocus.mode == c.NotifyGrab or
                event.xfocus.mode == c.NotifyUngrab)
            {
                // Ignore focus events from popup indicator windows, window menu
                // key chords and window dragging
                return;
            }

            self.pushEvent(.focus_gained);
        },
        c.FocusOut => {
            if (event.xfocus.mode == c.NotifyGrab or
                event.xfocus.mode == c.NotifyUngrab)
            {
                // Ignore focus events from popup indicator windows, window menu
                // key chords and window dragging
                return;
            }

            self.pushEvent(.focus_lost);
        },
        else => {},
    }
}

fn setDecorated(self: *Core, enabled: bool) void {
    const MWMHints = struct {
        flags: u32,
        functions: u32,
        decorations: u32,
        input_mode: i32,
        status: u32,
    };

    const hints = MWMHints{
        .functions = 0,
        .flags = 2,
        .decorations = if (enabled) 1 else 0,
        .input_mode = 0,
        .status = 0,
    };

    _ = self.libx11.XChangeProperty(
        self.display,
        self.window,
        self.motif_wm_hints,
        self.motif_wm_hints,
        32,
        c.PropModeReplace,
        @ptrCast(&hints),
        5,
    );
}

fn setFullscreen(self: *Core, enabled: bool) void {
    self.sendEventToWM(self.net_wm_state, &.{ @intFromBool(enabled), @intCast(self.net_wm_state_fullscreen), 0, 1 });

    // Force composition OFF to reduce overhead
    const compositing_disable_on: c_long = @intFromBool(enabled);
    const bypass_compositor = self.libx11.XInternAtom(self.display, "_NET_WM_BYPASS_COMPOSITOR", c.False);

    if (bypass_compositor != c.None) {
        _ = self.libx11.XChangeProperty(
            self.display,
            self.window,
            bypass_compositor,
            c.XA_CARDINAL,
            32,
            c.PropModeReplace,
            @ptrCast(&compositing_disable_on),
            1,
        );
    }
}

fn setFloating(self: *Core, enabled: bool) void {
    const net_wm_state_remove = 0;
    const net_wm_state_add = 1;
    const action: c_long = if (enabled) net_wm_state_add else net_wm_state_remove;
    self.sendEventToWM(self.net_wm_state, &.{ action, @intCast(self.net_wm_state_above), 0, 1 });
}

fn sendEventToWM(self: *Core, message_type: c.Atom, data: []const c_long) void {
    var ev = std.mem.zeroes(c.XEvent);
    ev.type = c.ClientMessage;
    ev.xclient.window = self.window;
    ev.xclient.message_type = message_type;
    ev.xclient.format = 32;
    @memcpy(ev.xclient.data.l[0..data.len], data);
    _ = self.libx11.XSendEvent(
        self.display,
        self.root_window,
        c.False,
        c.SubstructureNotifyMask | c.SubstructureRedirectMask,
        &ev,
    );
    _ = self.libx11.XFlush(self.display);
}

fn getCursorPos(self: *Core) mach_core.Position {
    var root_window: c.Window = undefined;
    var child_window: c.Window = undefined;
    var root_cursor_x: c_int = 0;
    var root_cursor_y: c_int = 0;
    var cursor_x: c_int = 0;
    var cursor_y: c_int = 0;
    var mask: c_uint = 0;
    _ = self.libx11.XQueryPointer(
        self.display,
        self.window,
        &root_window,
        &child_window,
        &root_cursor_x,
        &root_cursor_y,
        &cursor_x,
        &cursor_y,
        &mask,
    );

    return .{ .x = @floatFromInt(cursor_x), .y = @floatFromInt(cursor_y) };
}

// fn createImageCursor(display: *c.Display, pixels: []const u8, width: u32, height: u32) c.Cursor {
//     const image = libxcursor.XcursorImageCreate(@intCast(width), @intCast(height)) orelse return c.None;
//     defer libxcursor.XcursorImageDestroy(image);

//     for (image.*.pixels[0 .. width * height], 0..) |*target, i| {
//         const r = pixels[i * 4 + 0];
//         const g = pixels[i * 4 + 1];
//         const b = pixels[i * 4 + 2];
//         const a: u32 = pixels[i * 4 + 3];
//         target.* = (a << 24) |
//             ((r * a / 255) << 16) |
//             ((g * a / 255) << 8) |
//             ((b * a / 255) << 0);
//     }

//     return libxcursor.XcursorImageLoadCursor(display, image);
// }

fn updateCursor(self: *Core) void {
    switch (self.current_cursor_mode) {
        .normal => {
            if (self.cursors[@intFromEnum(self.current_cursor_shape)]) |current_cursor| {
                _ = self.libx11.XDefineCursor(self.display, self.window, current_cursor);
            } else {
                // TODO: what's the correct behavior here? reset to parent cursor?
                _ = self.libx11.XUndefineCursor(self.display, self.window);
            }

            if (self.last_cursor_mode == .disabled) {
                _ = self.libx11.XUngrabPointer(self.display, c.CurrentTime);
            }
        },
        .hidden => {
            _ = self.libx11.XDefineCursor(self.display, self.window, self.hidden_cursor);
            if (self.last_cursor_mode == .disabled) {
                _ = self.libx11.XUngrabPointer(self.display, c.CurrentTime);
            }
        },
        .disabled => {
            _ = self.libx11.XDefineCursor(self.display, self.window, self.hidden_cursor);
            _ = self.libx11.XGrabPointer(
                self.display,
                self.window,
                c.True,
                c.ButtonPressMask | c.ButtonReleaseMask | c.PointerMotionMask,
                c.GrabModeAsync,
                c.GrabModeAsync,
                self.window,
                c.None,
                c.CurrentTime,
            );
        },
    }
}

fn createStandardCursor(self: *Core, shape: CursorShape) !c.Cursor {
    if (self.libxcursor) |libxcursor| {
        const theme = libxcursor.XcursorGetTheme(self.display);
        if (theme != null) {
            const name = switch (shape) {
                .arrow => "default",
                .ibeam => "text",
                .crosshair => "crosshair",
                .pointing_hand => "pointer",
                .resize_ew => "ew-resize",
                .resize_ns => "ns-resize",
                .resize_nwse => "nwse-resize",
                .resize_nesw => "nesw-resize",
                .resize_all => "all-scroll",
                .not_allowed => "not-allowed",
            };

            const cursor_size = libxcursor.XcursorGetDefaultSize(self.display);
            const image = libxcursor.XcursorLibraryLoadImage(name, theme, cursor_size);
            defer libxcursor.XcursorImageDestroy(image);

            if (image != null) {
                return libxcursor.XcursorImageLoadCursor(self.display, image);
            }
        }
    }

    const xc: c_uint = switch (shape) {
        .arrow => c.XC_left_ptr,
        .ibeam => c.XC_xterm,
        .crosshair => c.XC_crosshair,
        .pointing_hand => c.XC_hand2,
        .resize_ew => c.XC_sb_h_double_arrow,
        .resize_ns => c.XC_sb_v_double_arrow,
        .resize_nwse => c.XC_sb_h_double_arrow,
        .resize_nesw => c.XC_sb_h_double_arrow,
        .resize_all => c.XC_fleur,
        .not_allowed => c.XC_X_cursor,
    };

    const cursor = self.libx11.XCreateFontCursor(self.display, xc);
    if (cursor == 0) return error.FailedToCreateCursor;

    return cursor;
}

fn toMachButton(button: c_uint) ?MouseButton {
    return switch (button) {
        c.Button1 => .left,
        c.Button2 => .middle,
        c.Button3 => .right,
        // Scroll events are handled by caller
        c.Button4, c.Button5, 6, 7 => null,
        // Additional buttons after 7 are treated as regular buttons
        8 => .four,
        9 => .five,
        10 => .six,
        11 => .seven,
        12 => .eight,
        // Unknown button
        else => null,
    };
}

fn toMachKey(key: c.KeySym) Key {
    return switch (key) {
        c.XK_a, c.XK_A => .a,
        c.XK_b, c.XK_B => .b,
        c.XK_c, c.XK_C => .c,
        c.XK_d, c.XK_D => .d,
        c.XK_e, c.XK_E => .e,
        c.XK_f, c.XK_F => .f,
        c.XK_g, c.XK_G => .g,
        c.XK_h, c.XK_H => .h,
        c.XK_i, c.XK_I => .i,
        c.XK_j, c.XK_J => .j,
        c.XK_k, c.XK_K => .k,
        c.XK_l, c.XK_L => .l,
        c.XK_m, c.XK_M => .m,
        c.XK_n, c.XK_N => .n,
        c.XK_o, c.XK_O => .o,
        c.XK_p, c.XK_P => .p,
        c.XK_q, c.XK_Q => .q,
        c.XK_r, c.XK_R => .r,
        c.XK_s, c.XK_S => .s,
        c.XK_t, c.XK_T => .t,
        c.XK_u, c.XK_U => .u,
        c.XK_v, c.XK_V => .v,
        c.XK_w, c.XK_W => .w,
        c.XK_x, c.XK_X => .x,
        c.XK_y, c.XK_Y => .y,
        c.XK_z, c.XK_Z => .z,

        c.XK_0 => .zero,
        c.XK_1 => .one,
        c.XK_2 => .two,
        c.XK_3 => .three,
        c.XK_4 => .four,
        c.XK_5 => .five,
        c.XK_6 => .six,
        c.XK_7 => .seven,
        c.XK_8 => .eight,
        c.XK_9 => .nine,

        c.XK_F1 => .f1,
        c.XK_F2 => .f2,
        c.XK_F3 => .f3,
        c.XK_F4 => .f4,
        c.XK_F5 => .f5,
        c.XK_F6 => .f6,
        c.XK_F7 => .f7,
        c.XK_F8 => .f8,
        c.XK_F9 => .f9,
        c.XK_F10 => .f10,
        c.XK_F11 => .f11,
        c.XK_F12 => .f12,
        c.XK_F13 => .f13,
        c.XK_F14 => .f14,
        c.XK_F15 => .f15,
        c.XK_F16 => .f16,
        c.XK_F17 => .f17,
        c.XK_F18 => .f18,
        c.XK_F19 => .f19,
        c.XK_F20 => .f20,
        c.XK_F21 => .f21,
        c.XK_F22 => .f22,
        c.XK_F23 => .f23,
        c.XK_F24 => .f24,
        c.XK_F25 => .f25,

        c.XK_KP_Divide => .kp_divide,
        c.XK_KP_Multiply => .kp_multiply,
        c.XK_KP_Subtract => .kp_subtract,
        c.XK_KP_Add => .kp_add,
        c.XK_KP_0 => .kp_0,
        c.XK_KP_1 => .kp_1,
        c.XK_KP_2 => .kp_2,
        c.XK_KP_3 => .kp_3,
        c.XK_KP_4 => .kp_4,
        c.XK_KP_5 => .kp_5,
        c.XK_KP_6 => .kp_6,
        c.XK_KP_7 => .kp_7,
        c.XK_KP_8 => .kp_8,
        c.XK_KP_9 => .kp_9,
        c.XK_KP_Decimal => .kp_decimal,
        c.XK_KP_Equal => .kp_equal,
        c.XK_KP_Enter => .kp_enter,

        c.XK_Return => .enter,
        c.XK_Escape => .escape,
        c.XK_Tab => .tab,
        c.XK_Shift_L => .left_shift,
        c.XK_Shift_R => .right_shift,
        c.XK_Control_L => .left_control,
        c.XK_Control_R => .right_control,
        c.XK_Alt_L => .left_alt,
        c.XK_Alt_R => .right_alt,
        c.XK_Super_L => .left_super,
        c.XK_Super_R => .right_super,
        c.XK_Menu => .menu,
        c.XK_Num_Lock => .num_lock,
        c.XK_Caps_Lock => .caps_lock,
        c.XK_Print => .print,
        c.XK_Scroll_Lock => .scroll_lock,
        c.XK_Pause => .pause,
        c.XK_Delete => .delete,
        c.XK_Home => .home,
        c.XK_End => .end,
        c.XK_Page_Up => .page_up,
        c.XK_Page_Down => .page_down,
        c.XK_Insert => .insert,
        c.XK_Left => .left,
        c.XK_Right => .right,
        c.XK_Up => .up,
        c.XK_Down => .down,
        c.XK_BackSpace => .backspace,
        c.XK_space => .space,
        c.XK_minus => .minus,
        c.XK_equal => .equal,
        c.XK_braceleft => .left_bracket,
        c.XK_braceright => .right_bracket,
        c.XK_backslash => .backslash,
        c.XK_semicolon => .semicolon,
        c.XK_apostrophe => .apostrophe,
        c.XK_comma => .comma,
        c.XK_period => .period,
        c.XK_slash => .slash,
        c.XK_grave => .grave,

        else => .unknown,
    };
}

fn toMachMods(mods: c_uint) KeyMods {
    return .{
        .shift = mods & c.ShiftMask != 0,
        .control = mods & c.ControlMask != 0,
        .alt = mods & c.Mod1Mask != 0,
        .super = mods & c.Mod4Mask != 0,
        .caps_lock = mods & c.LockMask != 0,
        .num_lock = mods & c.Mod2Mask != 0,
    };
}

fn errorHandler(display: ?*c.Display, event: [*c]c.XErrorEvent) callconv(.C) c_int {
    _ = display;
    log.err("X11: error code {d}\n", .{event.*.error_code});
    return 0;
}
