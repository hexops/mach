const std = @import("std");
const assert = std.debug.assert;
const glfw = @import("glfw");
const gpu = @import("gpu");
const c = @import("c.zig").c;
const objc = @cImport({
    @cInclude("objc/message.h");
});

fn printUnhandledError(_: void, typ: gpu.ErrorType, message: [*:0]const u8) void {
    switch (typ) {
        .validation => std.debug.print("gpu: validation error: {s}\n", .{message}),
        .out_of_memory => std.debug.print("gpu: out of memory: {s}\n", .{message}),
        .device_lost => std.debug.print("gpu: device lost: {s}\n", .{message}),
        .unknown => std.debug.print("gpu: unknown error: {s}\n", .{message}),
        else => unreachable,
    }
}
var printUnhandledErrorCallback = gpu.ErrorCallback.init(void, {}, printUnhandledError);

const Setup = struct {
    native_instance: gpu.NativeInstance,
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
    hints.cocoa_retina_framebuffer = true;
    const window = try glfw.Window.create(640, 480, "mach/gpu window", null, null, hints);

    const backend_procs = c.machDawnNativeGetProcs();
    c.dawnProcSetProcs(backend_procs);

    const instance = c.machDawnNativeInstance_init();
    var native_instance = gpu.NativeInstance.wrap(c.machDawnNativeInstance_get(instance).?);

    // Discovers e.g. OpenGL adapters.
    try discoverAdapters(instance, window, backend_type);

    // Request an adapter.
    //
    // TODO: It would be nice if we could use gpu_interface.waitForAdapter here, however the webgpu.h
    // API does not yet have a way to specify what type of backend you want (vulkan, opengl, etc.)
    // In theory, I suppose we shouldn't need to and Dawn should just pick the best adapter - but in
    // practice if Vulkan is not supported today waitForAdapter/requestAdapter merely generates an error.
    //
    // const gpu_interface = native_instance.interface();
    // const backend_adapter = switch (gpu_interface.waitForAdapter(&.{
    //     .power_preference = .high_performance,
    // })) {
    //     .adapter => |v| v,
    //     .err => |err| {
    //         std.debug.print("failed to get adapter: error={} {s}\n", .{ err.code, err.message });
    //         std.process.exit(1);
    //     },
    // };
    const adapters = c.machDawnNativeInstance_getAdapters(instance);
    var dawn_adapter: ?c.MachDawnNativeAdapter = null;
    var i: usize = 0;
    while (i < c.machDawnNativeAdapters_length(adapters)) : (i += 1) {
        const adapter = c.machDawnNativeAdapters_index(adapters, i);
        const properties = c.machDawnNativeAdapter_getProperties(adapter);
        const found_backend_type = @intToEnum(gpu.Adapter.BackendType, c.machDawnNativeAdapterProperties_getBackendType(properties));
        if (found_backend_type == backend_type) {
            dawn_adapter = adapter;
        }
    }
    if (dawn_adapter == null) {
        std.debug.print("no matching adapter found for {s}", .{@tagName(backend_type)});
        std.debug.print("-> maybe try GPU_BACKEND=opengl ?\n", .{});
        std.process.exit(1);
    }
    assert(dawn_adapter != null);
    const backend_adapter = gpu.NativeInstance.fromWGPUAdapter(c.machDawnNativeAdapter_get(dawn_adapter.?).?);

    // Print which adapter we are going to use.
    const props = backend_adapter.properties;
    std.debug.print("found {s} backend on {s} adapter: {s}, {s}\n", .{
        gpu.Adapter.backendTypeName(props.backend_type),
        gpu.Adapter.typeName(props.adapter_type),
        props.name,
        props.driver_description,
    });

    const device = switch (backend_adapter.waitForDevice(&.{})) {
        .device => |v| v,
        .err => |err| {
            std.debug.print("failed to get device: error={} {s}\n", .{ err.code, err.message });
            std.process.exit(1);
        },
    };

    device.setUncapturedErrorCallback(&printUnhandledErrorCallback);
    return Setup{
        .native_instance = native_instance,
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
            .hinstance = std.os.windows.kernel32.GetModuleHandleW(null).?,
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
