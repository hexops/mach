const builtin = @import("builtin");
const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xatom.h");
    @cInclude("X11/cursorfont.h");
    @cInclude("X11/Xcursor/Xcursor.h");
    @cInclude("X11/extensions/Xrandr.h");
});
const mach = @import("../main.zig");
const Core = @import("../Core.zig");
const InputState = @import("InputState.zig");
const Frequency = @import("Frequency.zig");
const unicode = @import("unicode.zig");
const detectBackendType = @import("common.zig").detectBackendType;
const gpu = mach.gpu;
const InitOptions = Core.InitOptions;
const Event = Core.Event;
const KeyEvent = Core.KeyEvent;
const MouseButtonEvent = Core.MouseButtonEvent;
const MouseButton = Core.MouseButton;
const Size = Core.Size;
const DisplayMode = Core.DisplayMode;
const CursorShape = Core.CursorShape;
const VSyncMode = Core.VSyncMode;
const CursorMode = Core.CursorMode;
const Key = Core.Key;
const KeyMods = Core.KeyMods;
const Joystick = Core.Joystick;
const Position = Core.Position;

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
        lib.handle = std.DynLib.open("libX11.so.6") catch return error.LibraryNotFound;
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
        lib.handle = std.DynLib.open("libXcursor.so.1") catch return error.LibraryNotFound;
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
        lib.handle = std.DynLib.open("libXrandr.so.1") catch return error.LibraryNotFound;
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
        lib.handle = std.DynLib.open("libGL.so.1") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibGL).Struct.fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse return error.SymbolLookup;
        }
        return lib;
    }
};

pub const X11 = @This();

allocator: std.mem.Allocator,
core: *Core,

libx11: LibX11,
libxrr: ?LibXRR,
libgl: ?LibGL,
libxcursor: ?LibXCursor,
gl_ctx: ?*LibGL.Context,
display: *c.Display,
width: c_int,
height: c_int,
empty_event_pipe: [2]std.c.fd_t,
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
window: c.Window,
backend_type: gpu.BackendType,
refresh_rate: u32,
hidden_cursor: c.Cursor,

// Mutable fields only used by main thread
cursors: [@typeInfo(CursorShape).Enum.fields.len]?c.Cursor,

// Event queue; written from main thread; read from any
events_mu: std.Thread.RwLock = .{},
events: EventQueue,

// Input state; written from main thread; read from any
input_mu: std.Thread.RwLock = .{},
input_state: InputState = .{},

// Mutable state fields; read/write by any thread
title: [:0]const u8,
display_mode: DisplayMode = .windowed,
vsync_mode: VSyncMode = .triple,
border: bool,
headless: bool,
size: Size,
cursor_mode: CursorMode = .normal,
cursor_shape: CursorShape = .arrow,
surface_descriptor: gpu.Surface.Descriptor,

const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);

pub const EventIterator = struct {
    queue: *EventQueue,

    pub inline fn next(iterator: *EventIterator) ?Event {
        return iterator.queue.readItem();
    }
};

// Called on the main thread
pub fn init(x11: *X11, options: InitOptions) !void {
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

    const empty_event_pipe = try std.posix.pipe();
    for (0..2) |i| {
        const sf = try std.posix.fcntl(empty_event_pipe[i], std.posix.F.GETFL, 0);
        const df = try std.posix.fcntl(empty_event_pipe[i], std.posix.F.GETFD, 0);
        _ = try std.posix.fcntl(empty_event_pipe[i], std.posix.F.SETFL, sf | @as(u32, @bitCast(std.posix.O{ .NONBLOCK = true })));
        _ = try std.posix.fcntl(empty_event_pipe[i], std.posix.F.SETFD, df | std.posix.FD_CLOEXEC);
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

    const backend_type = try detectBackendType(options.allocator);

    const refresh_rate: u16 = blk: {
        if (libxrr != null) {
            const conf = libxrr.?.XRRGetScreenInfo(display, root_window);
            break :blk @intCast(libxrr.?.XRRConfigCurrentRate(conf));
        }
        break :blk 60;
    };

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

    // The initial capacity we choose for the event queue is 2x our maximum expected event rate per
    // frame. Specifically, 1000hz mouse updates are likely the maximum event rate we will encounter
    // so we anticipate 2x that. If the event rate is higher than this per frame, it will grow to
    // that maximum (we never shrink the event queue capacity in order to avoid allocations causing
    // any stutter.)
    var events = EventQueue.init(options.allocator);
    try events.ensureTotalCapacity(2048);

    const window_size = Size{
        .width = @intCast(window_attrs.width),
        .height = @intCast(window_attrs.height),
    };

    // Create hidden cursor
    const blank_pixmap = libx11.XCreatePixmap(display, window, 1, 1, 1);
    const gc = libx11.XCreateGC(display, blank_pixmap, 0, null);
    if (gc != null) {
        _ = libx11.XDrawPoint(display, blank_pixmap, gc, 0, 0);
        _ = libx11.XFreeGC(display, gc);
    }
    var color = c.XColor{};
    const hidden_cursor = libx11.XCreatePixmapCursor(display, blank_pixmap, blank_pixmap, &color, &color, 0, 0);

    // TODO: remove allocation
    const surface_descriptor = try options.allocator.create(gpu.Surface.DescriptorFromXlibWindow);
    surface_descriptor.* = .{
        .display = display,
        .window = @intCast(window),
    };

    x11.* = .{
        .core = @fieldParentPtr("platform", x11),
        .allocator = options.allocator,
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
        .window = window,
        .hidden_cursor = hidden_cursor,
        .backend_type = backend_type,
        .refresh_rate = refresh_rate,
        .events = events,
        .title = options.title,
        .display_mode = .windowed,
        .border = options.border,
        .headless = options.headless,
        .size = window_size,
        .cursors = std.mem.zeroes([@typeInfo(CursorShape).Enum.fields.len]?c.Cursor),
        .surface_descriptor = .{ .next_in_chain = .{ .from_xlib_window = surface_descriptor } },
    };
    x11.cursors[@intFromEnum(CursorShape.arrow)] = try x11.createStandardCursor(.arrow);
}

fn pushEvent(x11: *X11, event: Event) !void {
    x11.events_mu.lock();
    defer x11.events_mu.unlock();
    try x11.events.writeItem(event);
}

// Called on the main thread
pub fn deinit(x11: *X11) void {
    x11.allocator.destroy(x11.surface_descriptor.next_in_chain.from_xlib_window);

    for (x11.cursors) |cur| {
        if (cur) |_| {
            // _ = x11.libx11.XFreeCursor(x11.display, cur.?);
        }
    }
    x11.events.deinit();

    if (x11.libxcursor) |*libxcursor| {
        libxcursor.handle.close();
    }

    if (x11.libxrr) |*libxrr| {
        libxrr.handle.close();
    }

    if (x11.libgl) |*libgl| {
        if (x11.gl_ctx) |gl_ctx| {
            libgl.glXDestroyContext(x11.display, gl_ctx);
        }
        libgl.handle.close();
    }

    _ = x11.libx11.XUnmapWindow(x11.display, x11.window);
    _ = x11.libx11.XDestroyWindow(x11.display, x11.window);
    _ = x11.libx11.XCloseDisplay(x11.display);
    x11.libx11.handle.close();

    std.posix.close(x11.empty_event_pipe[0]);
    std.posix.close(x11.empty_event_pipe[1]);
}

// Called on the main thread
pub fn update(x11: *X11) !void {
    while (c.QLength(x11.display) != 0) {
        var event: c.XEvent = undefined;
        _ = x11.libx11.XNextEvent(x11.display, &event);
        try x11.processEvent(&event);
    }
    _ = x11.libx11.XFlush(x11.display);

    // const frequency_delay = @as(f32, @floatFromInt(x11.input.delay_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));
    // TODO: glfw.waitEventsTimeout(frequency_delay);

    x11.core.input.tick();
}

// May be called from any thread.
pub inline fn pollEvents(x11: *X11) EventIterator {
    return EventIterator{ .queue = &x11.events };
}

// May be called from any thread.
pub fn setTitle(x11: *X11, title: [:0]const u8) void {
    x11.title = title;
    _ = x11.libx11.XStoreName(x11.display, x11.window, x11.title.ptr);
}

// May be called from any thread.
pub fn setDisplayMode(x11: *X11, mode: DisplayMode) void {
    switch (mode) {
        .windowed => {
            var atoms = std.BoundedArray(c.Atom, 5){};

            if (x11.display_mode == .fullscreen) {
                atoms.append(x11.net_wm_state_fullscreen) catch unreachable;
            }

            atoms.append(x11.motif_wm_hints) catch unreachable;

            // TODO
            // if (x11.floating) {
            // 	atoms.append(x11.net_wm_state_above) catch unreachable;
            // }
            _ = x11.libx11.XChangeProperty(
                x11.display,
                x11.window,
                x11.net_wm_state,
                c.XA_ATOM,
                32,
                c.PropModeReplace,
                @ptrCast(atoms.slice()),
                atoms.len,
            );

            x11.setFullscreen(false);
            x11.setDecorated(x11.border);
            x11.setFloating(false);
            _ = x11.libx11.XMapWindow(x11.display, x11.window);
            _ = x11.libx11.XFlush(x11.display);
        },
        .fullscreen => {
            x11.setFullscreen(true);
            _ = x11.libx11.XFlush(x11.display);
        },
        .borderless => {
            x11.setDecorated(false);
            x11.setFloating(true);
            x11.setFullscreen(false);

            _ = x11.libx11.XResizeWindow(
                x11.display,
                x11.window,
                @intCast(c.DisplayWidth(x11.display, c.DefaultScreen(x11.display))),
                @intCast(c.DisplayHeight(x11.display, c.DefaultScreen(x11.display))),
            );
            _ = x11.libx11.XFlush(x11.display);
        },
    }
}

// May be called from any thread.
pub fn setBorder(x11: *X11, value: bool) void {
    _ = x11;
    _ = value;
    // TODO
    // if (x11.display_mode != .borderless) x11.window.setAttrib(.decorated, x11.border);
}

// May be called from any thread.
pub fn setHeadless(x11: *X11, value: bool) void {
    _ = x11;
    _ = value;
    // TODO
    // if (x11.headless) x11.window.hide() else x11.window.show();
}

// May be called from any thread.
pub fn setVSync(x11: *X11, mode: VSyncMode) void {
    x11.swap_chain_desc.present_mode = switch (mode) {
        .none => .immediate,
        .double => .fifo,
        .triple => .mailbox,
    };
    x11.vsync_mode = mode;
    x11.swap_chain_update.set();
}

// May be called from any thread.
pub fn setSize(x11: *X11, value: Size) void {
    _ = x11.libx11.XResizeWindow(x11.display, x11.window, value.width, value.height);
    _ = x11.libx11.XFlush(x11.display);
    x11.size = value;
}

// May be called from any thread.
pub fn setCursorMode(x11: *X11, mode: CursorMode) void {
    x11.updateCursor(mode, x11.cursor_shape);
}

// May be called from any thread.
pub fn setCursorShape(x11: *X11, shape: CursorShape) void {
    const cursor = x11.createStandardCursor(shape) catch |err| blk: {
        log.warn(
            "mach: setCursorShape: {}: {s} not yet supported\n",
            .{ err, @tagName(shape) },
        );
        break :blk null;
    };
    x11.cursors[@intFromEnum(shape)] = cursor;
    x11.updateCursor(x11.cursor_mode, shape);
}

// May be called from any thread.
pub fn joystickPresent(_: *X11, _: Joystick) bool {
    @panic("TODO: implement joystickPresent for X11");
}

// May be called from any thread.
pub fn joystickName(_: *X11, _: Joystick) ?[:0]const u8 {
    @panic("TODO: implement joystickName for X11");
}

// May be called from any thread.
pub fn joystickButtons(_: *X11, _: Joystick) ?[]const bool {
    @panic("TODO: implement joystickButtons for X11");
}

// May be called from any thread.
pub fn joystickAxes(_: *X11, _: Joystick) ?[]const f32 {
    @panic("TODO: implement joystickAxes for X11");
}

// May be called from any thread.
pub fn keyPressed(x11: *X11, key: Key) bool {
    x11.input_mu.lockShared();
    defer x11.input_mu.unlockShared();
    return x11.input_state.isKeyPressed(key);
}

// May be called from any thread.
pub fn keyReleased(x11: *X11, key: Key) bool {
    x11.input_mu.lockShared();
    defer x11.input_mu.unlockShared();
    return x11.input_state.isKeyReleased(key);
}

// May be called from any thread.
pub fn mousePressed(x11: *X11, button: MouseButton) bool {
    x11.input_mu.lockShared();
    defer x11.input_mu.unlockShared();
    return x11.input_state.isMouseButtonPressed(button);
}

// May be called from any thread.
pub fn mouseReleased(x11: *X11, button: MouseButton) bool {
    x11.input_mu.lockShared();
    defer x11.input_mu.unlockShared();
    return x11.input_state.isMouseButtonReleased(button);
}

// May be called from any thread.
pub fn mousePosition(x11: *X11) Position {
    x11.input_mu.lockShared();
    defer x11.input_mu.unlockShared();
    return x11.input_state.mouse_position;
}

fn processEvent(x11: *X11, event: *c.XEvent) !void {
    switch (event.type) {
        c.KeyPress, c.KeyRelease => {
            // TODO: key repeat event

            var keysym: c.KeySym = undefined;
            _ = x11.libx11.XLookupString(&event.xkey, null, 0, &keysym, null);

            const key_event = KeyEvent{ .key = toMachKey(keysym), .mods = toMachMods(event.xkey.state) };

            switch (event.type) {
                c.KeyPress => {
                    x11.input_mu.lock();
                    x11.input_state.keys.set(@intFromEnum(key_event.key));
                    x11.input_mu.unlock();
                    try x11.pushEvent(.{ .key_press = key_event });

                    if (unicode.unicodeFromKeySym(keysym)) |codepoint| {
                        try x11.pushEvent(.{ .char_input = .{ .codepoint = codepoint } });
                    }
                },
                c.KeyRelease => {
                    x11.input_mu.lock();
                    x11.input_state.keys.unset(@intFromEnum(key_event.key));
                    x11.input_mu.unlock();
                    try x11.pushEvent(.{ .key_release = key_event });
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
                try x11.pushEvent(.{ .mouse_scroll = .{ .xoffset = scroll[0], .yoffset = scroll[1] } });
                return;
            };
            const cursor_pos = x11.getCursorPos();
            const mouse_button = MouseButtonEvent{
                .button = button,
                .pos = cursor_pos,
                .mods = toMachMods(event.xbutton.state),
            };

            x11.input_mu.lock();
            x11.input_state.mouse_buttons.set(@intFromEnum(mouse_button.button));
            x11.input_mu.unlock();
            try x11.pushEvent(.{ .mouse_press = mouse_button });
        },
        c.ButtonRelease => {
            const button = toMachButton(event.xbutton.button) orelse return;
            const cursor_pos = x11.getCursorPos();
            const mouse_button = MouseButtonEvent{
                .button = button,
                .pos = cursor_pos,
                .mods = toMachMods(event.xbutton.state),
            };

            x11.input_mu.lock();
            x11.input_state.mouse_buttons.unset(@intFromEnum(mouse_button.button));
            x11.input_mu.unlock();
            try x11.pushEvent(.{ .mouse_release = mouse_button });
        },
        c.ClientMessage => {
            if (event.xclient.message_type == c.None) return;

            if (event.xclient.message_type == x11.wm_protocols) {
                const protocol = event.xclient.data.l[0];
                if (protocol == c.None) return;

                if (protocol == x11.wm_delete_window) {
                    try x11.pushEvent(.close);
                } else if (protocol == x11.net_wm_ping) {
                    // The window manager is pinging the application to ensure
                    // it's still responding to events
                    var reply = event.*;
                    reply.xclient.window = x11.root_window;
                    _ = x11.libx11.XSendEvent(
                        x11.display,
                        x11.root_window,
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
            x11.input_mu.lock();
            x11.input_state.mouse_position = .{ .x = x, .y = y };
            x11.input_mu.unlock();
            try x11.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
        },
        c.MotionNotify => {
            const x: f32 = @floatFromInt(event.xmotion.x);
            const y: f32 = @floatFromInt(event.xmotion.y);
            x11.input_mu.lock();
            x11.input_state.mouse_position = .{ .x = x, .y = y };
            x11.input_mu.unlock();
            try x11.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
        },
        c.ConfigureNotify => {
            if (event.xconfigure.width != x11.size.width or
                event.xconfigure.height != x11.size.height)
            {
                x11.size.width = @intCast(event.xconfigure.width);
                x11.size.height = @intCast(event.xconfigure.height);
                x11.core.swap_chain_update.set();
                try x11.pushEvent(.{
                    .framebuffer_resize = .{
                        .width = x11.size.width,
                        .height = x11.size.height,
                    },
                });
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

            try x11.pushEvent(.focus_gained);
        },
        c.FocusOut => {
            if (event.xfocus.mode == c.NotifyGrab or
                event.xfocus.mode == c.NotifyUngrab)
            {
                // Ignore focus events from popup indicator windows, window menu
                // key chords and window dragging
                return;
            }

            try x11.pushEvent(.focus_lost);
        },
        else => {},
    }
}

fn setDecorated(x11: *X11, enabled: bool) void {
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

    _ = x11.libx11.XChangeProperty(
        x11.display,
        x11.window,
        x11.motif_wm_hints,
        x11.motif_wm_hints,
        32,
        c.PropModeReplace,
        @ptrCast(&hints),
        5,
    );
}

fn setFullscreen(x11: *X11, enabled: bool) void {
    x11.sendEventToWM(x11.net_wm_state, &.{ @intFromBool(enabled), @intCast(x11.net_wm_state_fullscreen), 0, 1 });

    // Force composition OFF to reduce overhead
    const compositing_disable_on: c_long = @intFromBool(enabled);
    const bypass_compositor = x11.libx11.XInternAtom(x11.display, "_NET_WM_BYPASS_COMPOSITOR", c.False);

    if (bypass_compositor != c.None) {
        _ = x11.libx11.XChangeProperty(
            x11.display,
            x11.window,
            bypass_compositor,
            c.XA_CARDINAL,
            32,
            c.PropModeReplace,
            @ptrCast(&compositing_disable_on),
            1,
        );
    }
}

fn setFloating(x11: *X11, enabled: bool) void {
    const net_wm_state_remove = 0;
    const net_wm_state_add = 1;
    const action: c_long = if (enabled) net_wm_state_add else net_wm_state_remove;
    x11.sendEventToWM(x11.net_wm_state, &.{ action, @intCast(x11.net_wm_state_above), 0, 1 });
}

fn sendEventToWM(x11: *X11, message_type: c.Atom, data: []const c_long) void {
    var ev = std.mem.zeroes(c.XEvent);
    ev.type = c.ClientMessage;
    ev.xclient.window = x11.window;
    ev.xclient.message_type = message_type;
    ev.xclient.format = 32;
    @memcpy(ev.xclient.data.l[0..data.len], data);
    _ = x11.libx11.XSendEvent(
        x11.display,
        x11.root_window,
        c.False,
        c.SubstructureNotifyMask | c.SubstructureRedirectMask,
        &ev,
    );
    _ = x11.libx11.XFlush(x11.display);
}

fn getCursorPos(x11: *X11) Position {
    var root_window: c.Window = undefined;
    var child_window: c.Window = undefined;
    var root_cursor_x: c_int = 0;
    var root_cursor_y: c_int = 0;
    var cursor_x: c_int = 0;
    var cursor_y: c_int = 0;
    var mask: c_uint = 0;
    _ = x11.libx11.XQueryPointer(
        x11.display,
        x11.window,
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

fn updateCursor(x11: *X11, mode: CursorMode, shape: CursorShape) void {
    switch (mode) {
        .normal => {
            if (x11.cursors[@intFromEnum(shape)]) |current_cursor| {
                _ = x11.libx11.XDefineCursor(x11.display, x11.window, current_cursor);
            } else {
                // TODO: what's the correct behavior here? reset to parent cursor?
                _ = x11.libx11.XUndefineCursor(x11.display, x11.window);
            }

            if (x11.last_cursor_mode == .disabled) {
                _ = x11.libx11.XUngrabPointer(x11.display, c.CurrentTime);
            }
        },
        .hidden => {
            _ = x11.libx11.XDefineCursor(x11.display, x11.window, x11.hidden_cursor);
            if (x11.last_cursor_mode == .disabled) {
                _ = x11.libx11.XUngrabPointer(x11.display, c.CurrentTime);
            }
        },
        .disabled => {
            _ = x11.libx11.XDefineCursor(x11.display, x11.window, x11.hidden_cursor);
            _ = x11.libx11.XGrabPointer(
                x11.display,
                x11.window,
                c.True,
                c.ButtonPressMask | c.ButtonReleaseMask | c.PointerMotionMask,
                c.GrabModeAsync,
                c.GrabModeAsync,
                x11.window,
                c.None,
                c.CurrentTime,
            );
        },
    }
}

fn createStandardCursor(x11: *X11, shape: CursorShape) !c.Cursor {
    if (x11.libxcursor) |libxcursor| {
        const theme = libxcursor.XcursorGetTheme(x11.display);
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

            const cursor_size = libxcursor.XcursorGetDefaultSize(x11.display);
            const image = libxcursor.XcursorLibraryLoadImage(name, theme, cursor_size);
            defer libxcursor.XcursorImageDestroy(image);

            if (image != null) {
                return libxcursor.XcursorImageLoadCursor(x11.display, image);
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

    const cursor = x11.libx11.XCreateFontCursor(x11.display, xc);
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
