const Linux = @import("../Linux.zig");
const Core = @import("../../Core.zig");
const InitOptions = Core.InitOptions;

const builtin = @import("builtin");
const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xatom.h");
    @cInclude("X11/cursorfont.h");
    @cInclude("X11/Xcursor/Xcursor.h");
    @cInclude("X11/extensions/Xrandr.h");
    @cInclude("xkbcommon/xkbcommon.h");
});
const mach = @import("../../main.zig");
const gpu = mach.gpu;
const Event = Core.Event;
const KeyEvent = Core.KeyEvent;
const MouseButtonEvent = Core.MouseButtonEvent;
const MouseButton = Core.MouseButton;
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

pub const X11 = @This();

allocator: std.mem.Allocator,
core: *Core,
state: *Core,

libx11: LibX11,
libxrr: ?LibXRR,
libgl: ?LibGL,
libxcursor: ?LibXCursor,
libxkbcommon: LibXkbCommon,
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

// Input state; written from main thread; read from any
input_mu: std.Thread.RwLock = .{},

// Mutable state fields; read/write by any thread
title: [:0]const u8,
display_mode: DisplayMode = .windowed,
vsync_mode: VSyncMode = .triple,
border: bool,
headless: bool,
size: Core.Size,
cursor_mode: CursorMode = .normal,
cursor_shape: CursorShape = .arrow,
surface_descriptor: *gpu.Surface.DescriptorFromXlibWindow,

pub fn init(
    linux: *Linux,
    core: *Core.Mod,
    options: InitOptions,
) !X11 {
    // TODO(core): return errors.NotSupported if not supported
    const libx11 = try LibX11.load();
    const libgl: ?LibGL = LibGL.load() catch |err| switch (err) {
        error.LibraryNotFound => null,
        else => return err,
    };
    const libxcursor: ?LibXCursor = LibXCursor.load() catch |err| switch (err) {
        error.LibraryNotFound => null,
        else => return err,
    };
    const libxrr: ?LibXRR = LibXRR.load() catch |err| switch (err) {
        error.LibraryNotFound => null,
        else => return err,
    };
    const display = libx11.XOpenDisplay(null) orelse {
        std.log.err("X11: Cannot open display", .{});
        return error.CannotOpenDisplay;
    };
    const screen = c.DefaultScreen(display);
    const visual = c.DefaultVisual(display, screen);
    const root_window = c.RootWindow(display, screen);
    const colormap = libx11.XCreateColormap(display, root_window, visual, c.AllocNone);
    var set_window_attrs = c.XSetWindowAttributes{
        .colormap = colormap,
        // TODO: reduce
        .event_mask = c.StructureNotifyMask | c.KeyPressMask | c.KeyReleaseMask |
            c.PointerMotionMask | c.ButtonPressMask | c.ButtonReleaseMask |
            c.ExposureMask | c.FocusChangeMask | c.VisibilityChangeMask |
            c.EnterWindowMask | c.LeaveWindowMask | c.PropertyChangeMask,
    };
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
    var window_attrs: c.XWindowAttributes = undefined;
    _ = libx11.XGetWindowAttributes(display, window, &window_attrs);
    const window_size = Core.Size{
        .width = @intCast(window_attrs.width),
        .height = @intCast(window_attrs.height),
    };
    const blank_pixmap = libx11.XCreatePixmap(display, window, 1, 1, 1);
    var color = c.XColor{};
    const refresh_rate: u16 = blk: {
        if (libxrr != null) {
            const conf = libxrr.?.XRRGetScreenInfo(display, root_window);
            break :blk @intCast(libxrr.?.XRRConfigCurrentRate(conf));
        }
        break :blk 60;
    };
    const surface_descriptor = try options.allocator.create(gpu.Surface.DescriptorFromXlibWindow);
    surface_descriptor.* = .{
        .display = display,
        .window = @intCast(window),
    };
    var x11 = X11{
        .core = @fieldParentPtr("platform", linux),
        .state = core.state(),
        .allocator = options.allocator,
        .display = display,
        .libx11 = libx11,
        .libgl = libgl,
        .libxcursor = libxcursor,
        .libxrr = libxrr,
        .empty_event_pipe = try std.posix.pipe(),
        .gl_ctx = null,
        .width = window_attrs.width,
        .height = window_attrs.height,
        .wm_protocols = libx11.XInternAtom(display, "WM_PROTOCOLS", c.False),
        .wm_delete_window = libx11.XInternAtom(display, "WM_DELETE_WINDOW", c.False),
        .net_wm_ping = libx11.XInternAtom(display, "NET_WM_PING", c.False),
        .net_wm_state_fullscreen = libx11.XInternAtom(display, "_NET_WM_STATE_FULLSCREEN", c.False),
        .net_wm_state = libx11.XInternAtom(display, "_NET_WM_STATE", c.False),
        .net_wm_state_above = libx11.XInternAtom(display, "_NET_WM_STATE_ABOVE", c.False),
        .net_wm_window_type = libx11.XInternAtom(display, "_NET_WM_WINDOW_TYPE", c.False),
        .net_wm_window_type_dock = libx11.XInternAtom(display, "_NET_WM_WINDOW_TYPE_DOCK", c.False),
        .net_wm_bypass_compositor = libx11.XInternAtom(display, "_NET_WM_BYPASS_COMPOSITOR", c.False),
        .motif_wm_hints = libx11.XInternAtom(display, "_MOTIF_WM_HINTS", c.False),
        .root_window = root_window,
        .window = window,
        .hidden_cursor = libx11.XCreatePixmapCursor(display, blank_pixmap, blank_pixmap, &color, &color, 0, 0),
        .backend_type = try Core.detectBackendType(options.allocator),
        .refresh_rate = refresh_rate,
        .title = options.title,
        .display_mode = .windowed,
        .border = options.border,
        .headless = options.headless,
        .size = window_size,
        .cursors = std.mem.zeroes([@typeInfo(CursorShape).Enum.fields.len]?c.Cursor),
        .surface_descriptor = surface_descriptor,
        .libxkbcommon = try LibXkbCommon.load(),
    };
    _ = libx11.XSetErrorHandler(errorHandler);
    _ = libx11.XInitThreads();
    _ = libx11.XrmInitialize();
    defer _ = libx11.XFreeColormap(display, colormap);
    for (0..2) |i| {
        const sf = try std.posix.fcntl(x11.empty_event_pipe[i], std.posix.F.GETFL, 0);
        const df = try std.posix.fcntl(x11.empty_event_pipe[i], std.posix.F.GETFD, 0);
        _ = try std.posix.fcntl(x11.empty_event_pipe[i], std.posix.F.SETFL, sf | @as(u32, @bitCast(std.posix.O{ .NONBLOCK = true })));
        _ = try std.posix.fcntl(x11.empty_event_pipe[i], std.posix.F.SETFD, df | std.posix.FD_CLOEXEC);
    }
    var protocols = [_]c.Atom{ x11.wm_delete_window, x11.net_wm_ping };
    _ = libx11.XSetWMProtocols(x11.display, x11.window, &protocols, protocols.len);
    _ = libx11.XStoreName(x11.display, x11.window, options.title.ptr);
    _ = libx11.XSelectInput(x11.display, x11.window, set_window_attrs.event_mask);
    _ = libx11.XMapWindow(x11.display, x11.window);
    _ = libx11.XGetWindowAttributes(x11.display, x11.window, &window_attrs);
    const backend_type = try Core.detectBackendType(options.allocator);
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
                const visual_info = libgl.?.glXChooseVisual(x11.display, screen, attrs.ptr);
                defer _ = libx11.XFree(visual_info);
                x11.gl_ctx = libgl.?.glXCreateContext(x11.display, visual_info, null, true);
                _ = libgl.?.glXMakeCurrent(x11.display, x11.window, x11.gl_ctx);
            } else {
                return error.LibGLNotFound;
            }
        },
        else => {},
    }
    // Create hidden cursor
    const gc = libx11.XCreateGC(x11.display, blank_pixmap, 0, null);
    if (gc != null) {
        _ = libx11.XDrawPoint(x11.display, blank_pixmap, gc, 0, 0);
        _ = libx11.XFreeGC(x11.display, gc);
    }
    // TODO: remove allocation
    x11.cursors[@intFromEnum(CursorShape.arrow)] = try x11.createStandardCursor(.arrow);
    return x11;
}

pub fn deinit(
    x11: *X11,
    linux: *Linux,
) void {
    x11.allocator.destroy(x11.surface_descriptor);
    linux.allocator.destroy(x11.surface_descriptor);
    for (x11.cursors) |cur| {
        if (cur) |_| {
            // _ = x11.libx11.XFreeCursor(x11.display, cur.?);
        }
    }
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
        x11.processEvent(&event);
    }
    _ = x11.libx11.XFlush(x11.display);

    // const frequency_delay = @as(f32, @floatFromInt(x11.input.delay_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));
    // TODO: glfw.waitEventsTimeout(frequency_delay);

    x11.core.input.tick();
}

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

const LibXkbCommon = struct {
    handle: std.DynLib,

    // xkb_context_new: *const @TypeOf(c.xkb_context_new),
    // xkb_keymap_new_from_string: *const @TypeOf(c.xkb_keymap_new_from_string),
    // xkb_state_new: *const @TypeOf(c.xkb_state_new),
    // xkb_keymap_unref: *const @TypeOf(c.xkb_keymap_unref),
    // xkb_state_unref: *const @TypeOf(c.xkb_state_unref),
    // xkb_compose_table_new_from_locale: *const @TypeOf(c.xkb_compose_table_new_from_locale),
    // xkb_compose_state_new: *const @TypeOf(c.xkb_compose_state_new),
    // xkb_compose_table_unref: *const @TypeOf(c.xkb_compose_table_unref),
    // xkb_keymap_mod_get_index: *const @TypeOf(c.xkb_keymap_mod_get_index),
    // xkb_state_update_mask: *const @TypeOf(c.xkb_state_update_mask),
    // xkb_state_mod_index_is_active: *const @TypeOf(c.xkb_state_mod_index_is_active),
    // xkb_state_key_get_syms: *const @TypeOf(c.xkb_state_key_get_syms),
    // xkb_compose_state_feed: *const @TypeOf(c.xkb_compose_state_feed),
    // xkb_compose_state_get_status: *const @TypeOf(c.xkb_compose_state_get_status),
    // xkb_compose_state_get_one_sym: *const @TypeOf(c.xkb_compose_state_get_one_sym),
    xkb_keysym_to_utf32: *const @TypeOf(c.xkb_keysym_to_utf32),

    pub fn load() !LibXkbCommon {
        var lib: LibXkbCommon = undefined;
        lib.handle = std.DynLib.open("libxkbcommon.so.0") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibXkbCommon).Struct.fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse {
                log.err("Symbol lookup failed for {s}", .{name});
                return error.SymbolLookup;
            };
        }
        return lib;
    }
};

fn errorHandler(display: ?*c.Display, event: [*c]c.XErrorEvent) callconv(.C) c_int {
    _ = display;
    log.err("X11: error code {d}\n", .{event.*.error_code});
    return 0;
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

fn processEvent(x11: *X11, event: *c.XEvent) void {
    switch (event.type) {
        c.KeyPress, c.KeyRelease => {
            // TODO: key repeat event

            var keysym: c.KeySym = undefined;
            _ = x11.libx11.XLookupString(&event.xkey, null, 0, &keysym, null);

            const key_event = KeyEvent{ .key = toMachKey(keysym), .mods = toMachMods(event.xkey.state) };

            switch (event.type) {
                c.KeyPress => {
                    x11.input_mu.lock();
                    x11.state.input_state.keys.set(@intFromEnum(key_event.key));
                    x11.input_mu.unlock();
                    x11.state.pushEvent(.{ .key_press = key_event });

                    const codepoint = x11.libxkbcommon.xkb_keysym_to_utf32(@truncate(keysym));
                    if (codepoint != 0) {
                        x11.state.pushEvent(.{ .char_input = .{ .codepoint = @truncate(codepoint) } });
                    }
                },
                c.KeyRelease => {
                    x11.input_mu.lock();
                    x11.state.input_state.keys.unset(@intFromEnum(key_event.key));
                    x11.input_mu.unlock();
                    x11.state.pushEvent(.{ .key_release = key_event });
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
                x11.state.pushEvent(.{ .mouse_scroll = .{ .xoffset = scroll[0], .yoffset = scroll[1] } });
                return;
            };
            const cursor_pos = x11.getCursorPos();
            const mouse_button = MouseButtonEvent{
                .button = button,
                .pos = cursor_pos,
                .mods = toMachMods(event.xbutton.state),
            };

            x11.input_mu.lock();
            x11.state.input_state.mouse_buttons.set(@intFromEnum(mouse_button.button));
            x11.input_mu.unlock();
            x11.state.pushEvent(.{ .mouse_press = mouse_button });
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
            x11.state.input_state.mouse_buttons.unset(@intFromEnum(mouse_button.button));
            x11.input_mu.unlock();
            x11.state.pushEvent(.{ .mouse_release = mouse_button });
        },
        c.ClientMessage => {
            if (event.xclient.message_type == c.None) return;

            if (event.xclient.message_type == x11.wm_protocols) {
                const protocol = event.xclient.data.l[0];
                if (protocol == c.None) return;

                if (protocol == x11.wm_delete_window) {
                    x11.state.pushEvent(.close);
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
            x11.state.input_state.mouse_position = .{ .x = x, .y = y };
            x11.input_mu.unlock();
            x11.state.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
        },
        c.MotionNotify => {
            const x: f32 = @floatFromInt(event.xmotion.x);
            const y: f32 = @floatFromInt(event.xmotion.y);
            x11.input_mu.lock();
            x11.state.input_state.mouse_position = .{ .x = x, .y = y };
            x11.input_mu.unlock();
            x11.state.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
        },
        c.ConfigureNotify => {
            if (event.xconfigure.width != x11.size.width or
                event.xconfigure.height != x11.size.height)
            {
                x11.size.width = @intCast(event.xconfigure.width);
                x11.size.height = @intCast(event.xconfigure.height);
                x11.core.swap_chain_update.set();
                x11.state.pushEvent(.{
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

            x11.state.pushEvent(.focus_gained);
        },
        c.FocusOut => {
            if (event.xfocus.mode == c.NotifyGrab or
                event.xfocus.mode == c.NotifyUngrab)
            {
                // Ignore focus events from popup indicator windows, window menu
                // key chords and window dragging
                return;
            }

            x11.state.pushEvent(.focus_lost);
        },
        else => {},
    }
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
