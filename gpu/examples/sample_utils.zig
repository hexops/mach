const std = @import("std");
const assert = std.debug.assert;
const glfw = @import("glfw");
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
    instance: c.WGPUInstance,
    backend_type: c.WGPUBackendType,
    device: c.WGPUDevice,
    window: glfw.Window,
};

fn getEnvVarOwned(allocator: std.mem.Allocator, key: []const u8) error{ OutOfMemory, InvalidUtf8 }!?[]u8 {
    return std.process.getEnvVarOwned(allocator, key) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => @as(?[]u8, null),
        else => |e| e,
    };
}

fn detectBackendType(allocator: std.mem.Allocator) !c.WGPUBackendType {
    const WGPU_BACKEND = try getEnvVarOwned(allocator, "WGPU_BACKEND");
    if (WGPU_BACKEND) |backend| {
        defer allocator.free(backend);
        if (std.ascii.eqlIgnoreCase(backend, "opengl")) return c.WGPUBackendType_OpenGL;
        if (std.ascii.eqlIgnoreCase(backend, "opengles")) return c.WGPUBackendType_OpenGLES;
        if (std.ascii.eqlIgnoreCase(backend, "d3d11")) return c.WGPUBackendType_D3D11;
        if (std.ascii.eqlIgnoreCase(backend, "d3d12")) return c.WGPUBackendType_D3D12;
        if (std.ascii.eqlIgnoreCase(backend, "metal")) return c.WGPUBackendType_Metal;
        if (std.ascii.eqlIgnoreCase(backend, "null")) return c.WGPUBackendType_Null;
        if (std.ascii.eqlIgnoreCase(backend, "vulkan")) return c.WGPUBackendType_Vulkan;
        @panic("unknown BACKEND type");
    }

    const target = @import("builtin").target;
    if (target.isDarwin()) return c.WGPUBackendType_Metal;
    if (target.os.tag == .windows) return c.WGPUBackendType_D3D12;
    return c.WGPUBackendType_Vulkan;
}

fn backendTypeString(t: c.WGPUBackendType) []const u8 {
    return switch (t) {
        c.WGPUBackendType_OpenGL => "OpenGL",
        c.WGPUBackendType_OpenGLES => "OpenGLES",
        c.WGPUBackendType_D3D11 => "D3D11",
        c.WGPUBackendType_D3D12 => "D3D12",
        c.WGPUBackendType_Metal => "Metal",
        c.WGPUBackendType_Null => "Null",
        c.WGPUBackendType_Vulkan => "Vulkan",
        else => unreachable,
    };
}

pub fn setup(allocator: std.mem.Allocator) !Setup {
    const backend_type = try detectBackendType(allocator);

    try glfw.init(.{});

    // Create the test window and discover adapters using it (esp. for OpenGL)
    var hints = glfwWindowHintsForBackend(backend_type);
    hints.cocoa_retina_framebuffer = false;
    const window = try glfw.Window.create(640, 480, "Dawn window", null, null, hints);

    const instance = c.machDawnNativeInstance_init();
    try discoverAdapter(instance, window, backend_type);

    const adapters = c.machDawnNativeInstance_getAdapters(instance);
    var backend_adapter: ?c.MachDawnNativeAdapter = null;
    var i: usize = 0;
    while (i < c.machDawnNativeAdapters_length(adapters)) : (i += 1) {
        const adapter = c.machDawnNativeAdapters_index(adapters, i);
        const properties = c.machDawnNativeAdapter_getProperties(adapter);
        if (c.machDawnNativeAdapterProperties_getBackendType(properties) == backend_type) {
            const name = c.machDawnNativeAdapterProperties_getName(properties);
            const driver_description = c.machDawnNativeAdapterProperties_getDriverDescription(properties);
            std.debug.print("found {s} adapter: {s}, {s}\n", .{ backendTypeString(backend_type), name, driver_description });
            backend_adapter = adapter;
        }
    }
    assert(backend_adapter != null);

    const backend_device = c.machDawnNativeAdapter_createDevice(backend_adapter.?, null);
    const backend_procs = c.machDawnNativeGetProcs();

    c.dawnProcSetProcs(backend_procs);
    backend_procs.*.deviceSetUncapturedErrorCallback.?(backend_device, printDeviceError, null);
    return Setup{
        .instance = c.machDawnNativeInstance_get(instance),
        .backend_type = backend_type,
        .device = backend_device,
        .window = window,
    };
}

fn glfwWindowHintsForBackend(backend: c.WGPUBackendType) glfw.Window.Hints {
    return switch (backend) {
        c.WGPUBackendType_OpenGL => .{
            // Ask for OpenGL 4.4 which is what the GL backend requires for compute shaders and
            // texture views.
            .context_version_major = 4,
            .context_version_minor = 4,
            .opengl_forward_compat = true,
            .opengl_profile = .opengl_core_profile,
        },
        c.WGPUBackendType_OpenGLES => .{
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

fn discoverAdapter(instance: c.MachDawnNativeInstance, window: glfw.Window, typ: c.WGPUBackendType) !void {
    if (typ == c.WGPUBackendType_OpenGL) {
        try glfw.makeContextCurrent(window);
        const adapter_options = c.MachDawnNativeAdapterDiscoveryOptions_OpenGL{
            .getProc = @ptrCast(fn ([*c]const u8) callconv(.C) ?*anyopaque, glfw.getProcAddress),
        };
        _ = c.machDawnNativeInstance_discoverAdapters(instance, typ, &adapter_options);
    } else if (typ == c.WGPUBackendType_OpenGLES) {
        try glfw.makeContextCurrent(window);
        const adapter_options = c.MachDawnNativeAdapterDiscoveryOptions_OpenGLES{
            .getProc = @ptrCast(fn ([*c]const u8) callconv(.C) ?*anyopaque, glfw.getProcAddress),
        };
        _ = c.machDawnNativeInstance_discoverAdapters(instance, typ, &adapter_options);
    } else {
        c.machDawnNativeInstance_discoverDefaultAdapters(instance);
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
    instance: c.WGPUInstance,
    window: glfw.Window,
    comptime glfw_options: glfw.BackendOptions,
) c.WGPUSurface {
    const glfw_native = glfw.Native(glfw_options);
    if (glfw_options.win32) {
        var desc: c.WGPUSurfaceDescriptorFromWindowsHWND = undefined;
        desc.chain.next = null;
        desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromWindowsHWND;

        desc.hinstance = std.os.windows.kernel32.GetModuleHandleW(null);
        desc.hwnd = glfw_native.getWin32Window(window);

        var descriptor: c.WGPUSurfaceDescriptor = undefined;
        descriptor.nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc);
        descriptor.label = "basic surface";
        return c.wgpuInstanceCreateSurface(instance, &descriptor);
    } else if (glfw_options.x11) {
        var desc: c.WGPUSurfaceDescriptorFromXlibWindow = undefined;
        desc.chain.next = null;
        desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromXlibWindow;

        desc.display = glfw_native.getX11Display();
        desc.window = glfw_native.getX11Window(window);

        var descriptor: c.WGPUSurfaceDescriptor = undefined;
        descriptor.nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc);
        descriptor.label = "basic surface";
        return c.wgpuInstanceCreateSurface(instance, &descriptor);
    } else if (glfw_options.cocoa) {
        var desc: c.WGPUSurfaceDescriptorFromMetalLayer = undefined;
        desc.chain.next = null;
        desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromMetalLayer;

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

        desc.layer = layer.?;

        var descriptor: c.WGPUSurfaceDescriptor = undefined;
        descriptor.nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc);
        descriptor.label = "basic surface";
        return c.wgpuInstanceCreateSurface(instance, &descriptor);
    } else if (glfw_options.wayland) {
        @panic("Dawn does not yet have Wayland support, see https://bugs.chromium.org/p/dawn/issues/detail?id=1246&q=surface&can=2");
    } else unreachable;
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
