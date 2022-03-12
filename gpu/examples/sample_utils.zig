const std = @import("std");
const assert = std.debug.assert;
const glfw = @import("glfw");
const gpu = @import("gpu");
const c = @import("c.zig").c;
const objc = @cImport({
    @cInclude("objc/message.h");
});

fn printDeviceError(error_type: c.WGPUErrorType, message: [*c]const u8, _: ?*anyopaque) callconv(.C) void {
    switch (error_type) {
        c.WGPUErrorType_Validation => std.debug.print("dawn: validation error: {s}\n", .{message}),
        c.WGPUErrorType_OutOfMemory => std.debug.print("dawn: out of memory: {s}\n", .{message}),
        c.WGPUErrorType_Unknown => std.debug.print("dawn: unknown error: {s}\n", .{message}),
        c.WGPUErrorType_DeviceLost => std.debug.print("dawn: device lost: {s}\n", .{message}),
        else => unreachable,
    }
}

const Setup = struct {
    native_instance: gpu.NativeInstance,
    instance: c.WGPUInstance,
    backend_type: gpu.Adapter.BackendType,
    device: gpu.Device,
    window: glfw.Window,
};

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) error{ OutOfMemory, InvalidUtf8 }!?[]u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => @as(?[]u8, null),
        else => |e| e,
    };
}

fn detectBackendType(allocator: std.mem.Allocator) !gpu.Adapter.BackendType {
    const GPU_BACKEND = try getEnvVarOwned(allocator, "GPU_BACKEND");
    if (GPU_BACKEND) |backend| {
        defer allocator.free(backend);
        if (std.ascii.eqlIgnoreCase(backend, "opengl")) return .opengl;
        if (std.ascii.eqlIgnoreCase(backend, "opengles")) return .opengles;
        if (std.ascii.eqlIgnoreCase(backend, "d3d11")) return .d3d11;
        if (std.ascii.eqlIgnoreCase(backend, "d3d12")) return .d3d12;
        if (std.ascii.eqlIgnoreCase(backend, "metal")) return .metal;
        if (std.ascii.eqlIgnoreCase(backend, "null")) return .nul;
        if (std.ascii.eqlIgnoreCase(backend, "vulkan")) return .vulkan;
        @panic("unknown BACKEND type");
    }

    const target = @import("builtin").target;
    if (target.isDarwin()) return .metal;
    if (target.os.tag == .windows) return .d3d12;
    return .vulkan;
}

pub fn setup(allocator: std.mem.Allocator) !Setup {
    const backend_type = try detectBackendType(allocator);

    try glfw.init(.{});

    // Create the test window and discover adapters using it (esp. for OpenGL)
    var hints = glfwWindowHintsForBackend(backend_type);
    hints.cocoa_retina_framebuffer = false;
    const window = try glfw.Window.create(640, 480, "Dawn window", null, null, hints);

    const instance = c.machDawnNativeInstance_init();

    const backend_procs = c.machDawnNativeGetProcs();
    c.dawnProcSetProcs(backend_procs);

    var native_instance = gpu.NativeInstance.wrap(c.machDawnNativeInstance_get(instance).?);
    const gpu_interface = native_instance.interface();

    // Discovers e.g. OpenGL adapters.
    try discoverAdapters(instance, window, backend_type);

    // Request an adapter.
    const backend_adapter = switch (nosuspend gpu_interface.requestAdapter(&.{
        .power_preference = .high_performance,
    })) {
        .adapter => |v| v,
        .err => |err| {
            std.debug.print("failed to get adapter: error={} {s}\n", .{ err.code, err.message });
            std.process.exit(1);
        },
    };

    // Print which adapter we are going to use.
    const props = backend_adapter.properties;
    std.debug.print("found {s} backend on {s} adapter: {s}, {s}\n", .{
        gpu.Adapter.backendTypeName(props.backend_type),
        gpu.Adapter.typeName(props.adapter_type),
        props.name,
        props.driver_description,
    });

    const device = switch (nosuspend backend_adapter.requestDevice(&.{})) {
        .device => |v| v,
        .err => |err| {
            std.debug.print("failed to get device: error={} {s}\n", .{ err.code, err.message });
            std.process.exit(1);
        },
    };

    // TODO: set wgpuDeviceSetUncapturedErrorCallback
    // backend_procs.*.deviceSetUncapturedErrorCallback.?(backend_device, printDeviceError, null);
    return Setup{
        .native_instance = native_instance,
        .instance = c.machDawnNativeInstance_get(instance),
        .backend_type = backend_type,
        .device = device,
        .window = window,
    };
}

fn glfwWindowHintsForBackend(backend: gpu.Adapter.BackendType) glfw.Window.Hints {
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

fn discoverAdapters(instance: c.MachDawnNativeInstance, window: glfw.Window, typ: gpu.Adapter.BackendType) !void {
    switch (typ) {
        .opengl => {
            try glfw.makeContextCurrent(window);
            const adapter_options = c.MachDawnNativeAdapterDiscoveryOptions_OpenGL{
                .getProc = @ptrCast(fn ([*c]const u8) callconv(.C) ?*anyopaque, glfw.getProcAddress),
            };
            _ = c.machDawnNativeInstance_discoverAdapters(instance, @enumToInt(typ), &adapter_options);
        },
        .opengles => {
            try glfw.makeContextCurrent(window);
            const adapter_options = c.MachDawnNativeAdapterDiscoveryOptions_OpenGLES{
                .getProc = @ptrCast(fn ([*c]const u8) callconv(.C) ?*anyopaque, glfw.getProcAddress),
            };
            _ = c.machDawnNativeInstance_discoverAdapters(instance, @enumToInt(typ), &adapter_options);
        },
        else => {
            c.machDawnNativeInstance_discoverDefaultAdapters(instance);
        },
    }
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
    native_instance: *const gpu.NativeInstance,
    window: glfw.Window,
    comptime glfw_options: glfw.BackendOptions,
) gpu.Surface {
    const glfw_native = glfw.Native(glfw_options);
    const descriptor = if (glfw_options.win32) gpu.Surface.Descriptor{
        .windows_hwnd = .{
            .label = "basic surface",
            .hinstance = std.os.windows.kernel32.GetModuleHandleW(null),
            .hwnd = glfw_native.getWin32Window(window),
        },
    } else if (glfw_options.x11) gpu.Surface.Descriptor{
        .xlib = .{
            .label = "basic surface",
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

        break :blk gpu.Surface.Descriptor{
            .metal_layer = .{
                .label = "basic surface",
                .layer = layer.?,
            },
        };
    } else if (glfw_options.wayland) {
        @panic("Dawn does not yet have Wayland support, see https://bugs.chromium.org/p/dawn/issues/detail?id=1246&q=surface&can=2");
    } else unreachable;

    return native_instance.createSurface(&descriptor);
}

// Borrowed from https://github.com/hazeycode/zig-objcrt
pub fn msgSend(obj: anytype, sel_name: [:0]const u8, args: anytype, comptime ReturnType: type) ReturnType {
    const args_meta = @typeInfo(@TypeOf(args)).Struct.fields;

    const FnType = switch (args_meta.len) {
        0 => fn (@TypeOf(obj), objc.SEL) callconv(.C) ReturnType,
        1 => fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type) callconv(.C) ReturnType,
        2 => fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type) callconv(.C) ReturnType,
        3 => fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type, args_meta[2].field_type) callconv(.C) ReturnType,
        4 => fn (@TypeOf(obj), objc.SEL, args_meta[0].field_type, args_meta[1].field_type, args_meta[2].field_type, args_meta[3].field_type) callconv(.C) ReturnType,
        else => @compileError("Unsupported number of args"),
    };

    // NOTE: func is a var because making it const causes a compile error which I believe is a compiler bug
    var func = @ptrCast(FnType, objc.objc_msgSend);
    const sel = objc.sel_getUid(sel_name);

    return @call(.{}, func, .{ obj, sel } ++ args);
}
