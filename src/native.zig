const std = @import("std");
const glfw = @import("glfw");
const gpu = @import("gpu");
const Engine = @import("Engine.zig");
const util = @import("util.zig");
const c = @import("c.zig").c;

pub const CoreGlfw = struct {
    window: glfw.Window,
    backend_type: gpu.Adapter.BackendType,

    pub fn init(allocator: std.mem.Allocator, engine: *Engine) !CoreGlfw {
        const options = engine.options;
        const backend_type = try util.detectBackendType(allocator);

        glfw.setErrorCallback(CoreGlfw.errorCallback);
        try glfw.init(.{});

        // Create the test window and discover adapters using it (esp. for OpenGL)
        var hints = util.glfwWindowHintsForBackend(backend_type);
        hints.cocoa_retina_framebuffer = true;
        const window = try glfw.Window.create(
            options.width,
            options.height,
            options.title,
            null,
            null,
            hints,
        );

        return CoreGlfw{
            .window = window,
            .backend_type = backend_type,
        };
    }

    /// Default GLFW error handling callback
    fn errorCallback(error_code: glfw.Error, description: [:0]const u8) void {
        std.debug.print("glfw: {}: {s}\n", .{ error_code, description });
    }
};

pub const GpuDriverNative = struct {
    native_instance: gpu.NativeInstance,

    pub fn init(_: std.mem.Allocator, engine: *Engine) !GpuDriverNative {
        const options = engine.options;
        const window = engine.core.internal.window;
        const backend_type = engine.core.internal.backend_type;

        const backend_procs = c.machDawnNativeGetProcs();
        c.dawnProcSetProcs(backend_procs);

        const instance = c.machDawnNativeInstance_init();
        var native_instance = gpu.NativeInstance.wrap(c.machDawnNativeInstance_get(instance).?);

        // Discover e.g. OpenGL adapters.
        try util.discoverAdapters(instance, window, backend_type);

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
        //         std.debug.print("mach: failed to get adapter: error={} {s}\n", .{ err.code, err.message });
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
                break;
            }
        }
        if (dawn_adapter == null) {
            std.debug.print("mach: no matching adapter found for {s}", .{@tagName(backend_type)});
            std.debug.print("-> maybe try GPU_BACKEND=opengl ?\n", .{});
            std.process.exit(1);
        }
        std.debug.assert(dawn_adapter != null);
        const backend_adapter = gpu.NativeInstance.fromWGPUAdapter(c.machDawnNativeAdapter_get(dawn_adapter.?).?);

        // Print which adapter we are going to use.
        const props = backend_adapter.properties;
        std.debug.print("mach: found {s} backend on {s} adapter: {s}, {s}\n", .{
            gpu.Adapter.backendTypeName(props.backend_type),
            gpu.Adapter.typeName(props.adapter_type),
            props.name,
            props.driver_description,
        });

        const device = switch (backend_adapter.waitForDevice(&.{
            .required_features = options.required_features,
            .required_limits = options.required_limits,
        })) {
            .device => |v| v,
            .err => |err| {
                // TODO: return a proper error type
                std.debug.print("mach: failed to get device: error={} {s}\n", .{ err.code, err.message });
                std.process.exit(1);
            },
        };

        var framebuffer_size = try window.getFramebufferSize();

        // If targeting OpenGL, we can't use the newer WGPUSurface API. Instead, we need to use the
        // older Dawn-specific API. https://bugs.chromium.org/p/dawn/issues/detail?id=269&q=surface&can=2
        const use_legacy_api = backend_type == .opengl or backend_type == .opengles;
        var descriptor: gpu.SwapChain.Descriptor = undefined;
        var swap_chain: ?gpu.SwapChain = null;
        var swap_chain_format: gpu.Texture.Format = undefined;
        var surface: ?gpu.Surface = null;
        if (!use_legacy_api) {
            swap_chain_format = .bgra8_unorm;
            descriptor = .{
                .label = "basic swap chain",
                .usage = .{ .render_attachment = true },
                .format = swap_chain_format,
                .width = framebuffer_size.width,
                .height = framebuffer_size.height,
                .present_mode = switch (options.vsync) {
                    .none => .immediate,
                    .double => .fifo,
                    .triple => .mailbox,
                },
                .implementation = 0,
            };
            surface = util.createSurfaceForWindow(
                &native_instance,
                window,
                comptime util.detectGLFWOptions(),
            );
        } else {
            const binding = c.machUtilsCreateBinding(@enumToInt(backend_type), @ptrCast(*c.GLFWwindow, window.handle), @ptrCast(c.WGPUDevice, device.ptr));
            if (binding == null) {
                @panic("failed to create Dawn backend binding");
            }
            descriptor = std.mem.zeroes(gpu.SwapChain.Descriptor);
            descriptor.implementation = c.machUtilsBackendBinding_getSwapChainImplementation(binding);
            swap_chain = device.nativeCreateSwapChain(null, &descriptor);

            swap_chain_format = @intToEnum(gpu.Texture.Format, @intCast(u32, c.machUtilsBackendBinding_getPreferredSwapChainTextureFormat(binding)));
            swap_chain.?.configure(
                swap_chain_format,
                .{ .render_attachment = true },
                framebuffer_size.width,
                framebuffer_size.height,
            );
        }

        device.setUncapturedErrorCallback(&util.printUnhandledErrorCallback);

        engine.gpu_driver.device = device;
        engine.gpu_driver.backend_type = backend_type;
        engine.gpu_driver.surface = surface;
        engine.gpu_driver.swap_chain = swap_chain;
        engine.gpu_driver.swap_chain_format = swap_chain_format;
        engine.gpu_driver.current_desc = descriptor;
        engine.gpu_driver.target_desc = descriptor;

        return GpuDriverNative{
            .native_instance = native_instance,
        };
    }
};
