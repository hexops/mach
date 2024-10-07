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
});
const mach = @import("../../main.zig");
const gpu = mach.gpu;
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

// Input state; written from main thread; read from any
input_mu: std.Thread.RwLock = .{},

// Mutable state fields; read/write by any thread
title: [:0]const u8,
display_mode: DisplayMode = .windowed,
vsync_mode: VSyncMode = .triple,
border: bool,
headless: bool,
size: Size,
cursor_mode: CursorMode = .normal,
cursor_shape: CursorShape = .arrow,
surface_descriptor: *gpu.Surface.DescriptorFromXlibWindow,

pub fn init(
    linux: *Linux,
    core: *Core.Mod,
    options: InitOptions,
) !X11 {
    _ = core;

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
    const window_size = Size{
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
