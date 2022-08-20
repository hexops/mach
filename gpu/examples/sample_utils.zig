const std = @import("std");
const assert = std.debug.assert;
const glfw = @import("glfw");
const gpu = @import("gpu");
const c = @import("c.zig").c;
const objc = @cImport({
    @cInclude("objc/message.h");
});

inline fn printUnhandledErrorCallback(_: void, typ: gpu.ErrorType, message: [*:0]const u8) void {
    switch (typ) {
        .validation => std.debug.print("gpu: validation error: {s}\n", .{message}),
        .out_of_memory => std.debug.print("gpu: out of memory: {s}\n", .{message}),
        .device_lost => std.debug.print("gpu: device lost: {s}\n", .{message}),
        .unknown => std.debug.print("gpu: unknown error: {s}\n", .{message}),
        else => unreachable,
    }
    std.process.exit(1);
}

const Setup = struct {
    instance: *gpu.Instance,
    adapter: *gpu.Adapter,
    device: *gpu.Device,
    window: glfw.Window,
    surface: *gpu.Surface,
};

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) error{ OutOfMemory, InvalidUtf8 }!?[]u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => @as(?[]u8, null),
        else => |e| e,
    };
}

fn detectBackendType(allocator: std.mem.Allocator) !gpu.BackendType {
    const MACH_GPU_BACKEND = try getEnvVarOwned(allocator, "MACH_GPU_BACKEND");
    if (MACH_GPU_BACKEND) |backend| {
        defer allocator.free(backend);
        if (std.ascii.eqlIgnoreCase(backend, "null")) return .nul;
        if (std.ascii.eqlIgnoreCase(backend, "webgpu")) return .nul;
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

const RequestAdapterResponse = struct {
    status: gpu.RequestAdapterStatus,
    adapter: *gpu.Adapter,
    message: ?[*:0]const u8,
};

inline fn requestAdapterCallback(
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

pub fn setup(allocator: std.mem.Allocator) !Setup {
    const backend_type = try detectBackendType(allocator);

    try glfw.init(.{});

    // Create the test window and discover adapters using it (esp. for OpenGL)
    var hints = glfwWindowHintsForBackend(backend_type);
    hints.cocoa_retina_framebuffer = true;
    const window = try glfw.Window.create(640, 480, "mach/gpu window", null, null, hints);
    if (backend_type == .opengl) try glfw.makeContextCurrent(window);
    if (backend_type == .opengles) try glfw.makeContextCurrent(window);

    const instance = gpu.createInstance(null);
    if (instance == null) {
        std.debug.print("failed to create GPU instance\n", .{});
        std.process.exit(1);
    }
    const surface = createSurfaceForWindow(instance.?, window, comptime detectGLFWOptions());

    var response: ?RequestAdapterResponse = null;
    instance.?.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = surface,
        .power_preference = .undef,
        .force_fallback_adapter = false,
    }, &response, requestAdapterCallback);
    if (response.?.status != .success) {
        std.debug.print("failed to create GPU adapter: {s}\n", .{response.?.message.?});
        std.process.exit(1);
    }

    // Print which adapter we are using.
    var props: gpu.Adapter.Properties = undefined;
    response.?.adapter.getProperties(&props);
    std.debug.print("found {s} backend on {s} adapter: {s}, {s}\n", .{
        props.backend_type.name(),
        props.adapter_type.name(),
        props.name,
        props.driver_description,
    });

    // Create a device with default limits/features.
    const device = response.?.adapter.createDevice(null);
    if (device == null) {
        std.debug.print("failed to create GPU device\n", .{});
        std.process.exit(1);
    }

    device.?.setUncapturedErrorCallback({}, printUnhandledErrorCallback);
    return Setup{
        .instance = instance.?,
        .adapter = response.?.adapter,
        .device = device.?,
        .window = window,
        .surface = surface,
    };
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

    const FnType = if (@import("builtin").zig_backend == .stage1)
        switch (args_meta.len) {
            0 => fn (@TypeOf(obj), objc.SEL) callconv(.C) ReturnType,
            1 => fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type) callconv(.C) ReturnType,
            2 => fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type) callconv(.C) ReturnType,
            3 => fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type, args_meta[2].field_type) callconv(.C) ReturnType,
            4 => fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type, args_meta[2].field_type, args_meta[3].field_type) callconv(.C) ReturnType,
            else => @compileError("Unsupported number of args"),
        }
    else
        switch (args_meta.len) {
            0 => *const fn (@TypeOf(obj), objc.SEL) callconv(.C) ReturnType,
            1 => *const fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type) callconv(.C) ReturnType,
            2 => *const fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type) callconv(.C) ReturnType,
            3 => *const fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type, args_meta[2].field_type) callconv(.C) ReturnType,
            4 => *const fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type, args_meta[2].field_type, args_meta[3].field_type) callconv(.C) ReturnType,
            else => @compileError("Unsupported number of args"),
        };

    // NOTE: func is a var because making it const causes a compile error which I believe is a compiler bug
    var func = if (@import("builtin").zig_backend == .stage1)
        @ptrCast(FnType, objc.objc_msgSend)
    else
        @ptrCast(FnType, &objc.objc_msgSend);
    const sel = objc.sel_getUid(@ptrCast([*c]const u8, sel_name));

    return @call(.{}, func, .{ obj, sel } ++ args);
}
