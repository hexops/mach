const std = @import("std");

const glfw = @import("glfw");
const gpu = @import("gpu");
const objc = @import("objc_message.zig");

pub inline fn printUnhandledErrorCallback(_: void, typ: gpu.ErrorType, message: [*:0]const u8) void {
    switch (typ) {
        .validation => std.log.err("gpu: validation error: {s}\n", .{message}),
        .out_of_memory => std.log.err("gpu: out of memory: {s}\n", .{message}),
        .device_lost => std.log.err("gpu: device lost: {s}\n", .{message}),
        .unknown => std.log.err("gpu: unknown error: {s}\n", .{message}),
        else => unreachable,
    }
    std.os.exit(1);
}

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) error{ OutOfMemory, InvalidUtf8 }!?[]u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => @as(?[]u8, null),
        else => |e| e,
    };
}

pub fn detectBackendType(allocator: std.mem.Allocator) !gpu.BackendType {
    const MACH_GPU_BACKEND = try getEnvVarOwned(allocator, "MACH_GPU_BACKEND");
    if (MACH_GPU_BACKEND) |backend| {
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

    const target = @import("builtin").target;
    if (target.isDarwin()) return .metal;
    if (target.os.tag == .windows) return .d3d12;
    return .vulkan;
}

pub const RequestAdapterResponse = struct {
    status: gpu.RequestAdapterStatus,
    adapter: *gpu.Adapter,
    message: ?[*:0]const u8,
};

pub inline fn requestAdapterCallback(
    context: *?RequestAdapterResponse,
    status: gpu.RequestAdapterStatus,
    adapter: *gpu.Adapter,
    message: ?[*:0]const u8,
) void {
    context.* = RequestAdapterResponse{
        .status = status,
        .adapter = adapter,
        .message = message,
    };
}

pub fn glfwWindowHintsForBackend(backend: gpu.BackendType) glfw.Window.Hints {
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

pub fn detectGLFWOptions() glfw.BackendOptions {
    const target = @import("builtin").target;
    if (target.isDarwin()) return .{ .cocoa = true };
    return switch (target.os.tag) {
        .windows => .{ .win32 = true },
        .linux => .{ .x11 = true },
        else => .{},
    };
}

pub fn createSurfaceForWindow(
    instance: *gpu.Instance,
    window: glfw.Window,
    comptime glfw_options: glfw.BackendOptions,
) *gpu.Surface {
    const glfw_native = glfw.Native(glfw_options);
    const extension = if (glfw_options.win32) gpu.Surface.Descriptor.NextInChain{
        .from_windows_hwnd = &.{
            .hinstance = std.os.windows.kernel32.GetModuleHandleW(null).?,
            .hwnd = glfw_native.getWin32Window(window),
        },
    } else if (glfw_options.x11) gpu.Surface.Descriptor.NextInChain{
        .from_xlib_window = &.{
            .display = glfw_native.getX11Display(),
            .window = glfw_native.getX11Window(window),
        },
    } else if (glfw_options.cocoa) blk: {
        const ns_window = glfw_native.getCocoaWindow(window);
        const ns_view = msgSend(ns_window, "contentView", .{}, *anyopaque); // [nsWindow contentView]

        // Create a CAMetalLayer that covers the whole window that will be passed to CreateSurface.
        msgSend(ns_view, "setWantsLayer:", .{true}, void); // [view setWantsLayer:YES]
        const layer = msgSend(objc.objc_getClass("CAMetalLayer"), "layer", .{}, ?*anyopaque); // [CAMetalLayer layer]
        if (layer == null) @panic("failed to create Metal layer");
        msgSend(ns_view, "setLayer:", .{layer.?}, void); // [view setLayer:layer]

        // Use retina if the window was created with retina support.
        const scale_factor = msgSend(ns_window, "backingScaleFactor", .{}, f64); // [ns_window backingScaleFactor]
        msgSend(layer.?, "setContentsScale:", .{scale_factor}, void); // [layer setContentsScale:scale_factor]

        break :blk gpu.Surface.Descriptor.NextInChain{ .from_metal_layer = &.{ .layer = layer.? } };
    } else if (glfw_options.wayland) {
        @panic("TODO: this example does not support Wayland");
    } else unreachable;

    return instance.createSurface(&gpu.Surface.Descriptor{
        .next_in_chain = extension,
    });
}

pub const AutoReleasePool = if (!@import("builtin").target.isDarwin()) opaque {
    pub fn init() error{OutOfMemory}!?*AutoReleasePool {
        return null;
    }

    pub fn release(pool: ?*AutoReleasePool) void {
        _ = pool;
        return;
    }
} else opaque {
    pub fn init() error{OutOfMemory}!?*AutoReleasePool {
        // pool = [NSAutoreleasePool alloc];
        var pool = msgSend(objc.objc_getClass("NSAutoreleasePool"), "alloc", .{}, ?*AutoReleasePool);
        if (pool == null) return error.OutOfMemory;

        // pool = [pool init];
        pool = msgSend(pool, "init", .{}, ?*AutoReleasePool);
        if (pool == null) unreachable;

        return pool;
    }

    pub fn release(pool: ?*AutoReleasePool) void {
        // [pool release];
        msgSend(pool, "release", .{}, void);
    }
};

// Borrowed from https://github.com/hazeycode/zig-objcrt
pub fn msgSend(obj: anytype, sel_name: [:0]const u8, args: anytype, comptime ReturnType: type) ReturnType {
    const args_meta = @typeInfo(@TypeOf(args)).Struct.fields;

    const FnType = switch (args_meta.len) {
        0 => *const fn (@TypeOf(obj), objc.SEL) callconv(.C) ReturnType,
        1 => *const fn (@TypeOf(obj), objc.SEL, args_meta[0].type) callconv(.C) ReturnType,
        2 => *const fn (@TypeOf(obj), objc.SEL, args_meta[0].type, args_meta[1].type) callconv(.C) ReturnType,
        3 => *const fn (@TypeOf(obj), objc.SEL, args_meta[0].type, args_meta[1].type, args_meta[2].type) callconv(.C) ReturnType,
        4 => *const fn (@TypeOf(obj), objc.SEL, args_meta[0].type, args_meta[1].type, args_meta[2].type, args_meta[3].type) callconv(.C) ReturnType,
        else => @compileError("Unsupported number of args"),
    };

    // NOTE: func is a var because making it const causes a compile error which I believe is a compiler bug
    var func = @ptrCast(FnType, &objc.objc_msgSend);
    const sel = objc.sel_getUid(@ptrCast([*c]const u8, sel_name));

    return @call(.auto, func, .{ obj, sel } ++ args);
}
