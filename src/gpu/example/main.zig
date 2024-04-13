const std = @import("std");
const util = @import("util.zig");
const glfw = @import("mach-glfw");
const gpu = @import("mach").gpu;

pub const GPUInterface = gpu.dawn.Interface;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    try gpu.Impl.init(allocator, .{});
    const setup = try setupWindow(allocator);
    const framebuffer_size = setup.window.getFramebufferSize();

    const window_data = try allocator.create(WindowData);
    window_data.* = .{
        .surface = setup.surface,
        .swap_chain = null,
        .swap_chain_format = undefined,
        .current_desc = undefined,
        .target_desc = undefined,
    };
    setup.window.setUserPointer(window_data);

    window_data.swap_chain_format = .bgra8_unorm;
    const descriptor = gpu.SwapChain.Descriptor{
        .label = "basic swap chain",
        .usage = .{ .render_attachment = true },
        .format = window_data.swap_chain_format,
        .width = framebuffer_size.width,
        .height = framebuffer_size.height,
        .present_mode = .fifo,
    };

    window_data.current_desc = descriptor;
    window_data.target_desc = descriptor;

    const vs =
        \\ @vertex fn main(
        \\     @builtin(vertex_index) VertexIndex : u32
        \\ ) -> @builtin(position) vec4<f32> {
        \\     var pos = array<vec2<f32>, 3>(
        \\         vec2<f32>( 0.0,  0.5),
        \\         vec2<f32>(-0.5, -0.5),
        \\         vec2<f32>( 0.5, -0.5)
        \\     );
        \\     return vec4<f32>(pos[VertexIndex], 0.0, 1.0);
        \\ }
    ;
    const vs_module = setup.device.createShaderModuleWGSL("my vertex shader", vs);

    const fs =
        \\ @fragment fn main() -> @location(0) vec4<f32> {
        \\     return vec4<f32>(1.0, 0.0, 0.0, 1.0);
        \\ }
    ;
    const fs_module = setup.device.createShaderModuleWGSL("my fragment shader", fs);

    // Fragment state
    const blend = gpu.BlendState{
        .color = .{
            .dst_factor = .one,
        },
        .alpha = .{
            .dst_factor = .one,
        },
    };
    const color_target = gpu.ColorTargetState{
        .format = window_data.swap_chain_format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
    });
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = null,
        .depth_stencil = null,
        .vertex = gpu.VertexState{
            .module = vs_module,
            .entry_point = "main",
        },
        .multisample = .{},
        .primitive = .{},
    };
    const pipeline = setup.device.createRenderPipeline(&pipeline_descriptor);

    vs_module.release();
    fs_module.release();

    // Reconfigure the swap chain with the new framebuffer width/height, otherwise e.g. the Vulkan
    // device would be lost after a resize.
    setup.window.setFramebufferSizeCallback((struct {
        fn callback(window: glfw.Window, width: u32, height: u32) void {
            const pl = window.getUserPointer(WindowData);
            pl.?.target_desc.width = width;
            pl.?.target_desc.height = height;
        }
    }).callback);

    const queue = setup.device.getQueue();
    while (!setup.window.shouldClose()) {
        try frame(.{
            .window = setup.window,
            .device = setup.device,
            .pipeline = pipeline,
            .queue = queue,
        });
        std.time.sleep(16 * std.time.ns_per_ms);
    }
}

const WindowData = struct {
    surface: ?*gpu.Surface,
    swap_chain: ?*gpu.SwapChain,
    swap_chain_format: gpu.Texture.Format,
    current_desc: gpu.SwapChain.Descriptor,
    target_desc: gpu.SwapChain.Descriptor,
};

const FrameParams = struct {
    window: glfw.Window,
    device: *gpu.Device,
    pipeline: *gpu.RenderPipeline,
    queue: *gpu.Queue,
};

fn frame(params: FrameParams) !void {
    glfw.pollEvents();
    params.device.tick();
    const pl = params.window.getUserPointer(WindowData).?;
    if (pl.swap_chain == null or !std.meta.eql(pl.current_desc, pl.target_desc)) {
        pl.swap_chain = params.device.createSwapChain(pl.surface, &pl.target_desc);
        pl.current_desc = pl.target_desc;
    }

    const back_buffer_view = pl.swap_chain.?.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = params.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(params.pipeline);
    pass.draw(3, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    params.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    pl.swap_chain.?.present();
    back_buffer_view.release();
}

const Setup = struct {
    instance: *gpu.Instance,
    adapter: *gpu.Adapter,
    device: *gpu.Device,
    window: glfw.Window,
    surface: *gpu.Surface,
};

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn setupWindow(allocator: std.mem.Allocator) !Setup {
    const backend_type = try util.detectBackendType(allocator);

    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }

    // Create the test window and discover adapters using it (esp. for OpenGL)
    var hints = util.glfwWindowHintsForBackend(backend_type);
    hints.cocoa_retina_framebuffer = true;
    const window = glfw.Window.create(640, 480, "mach/gpu window", null, null, hints) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };

    if (backend_type == .opengl) glfw.makeContextCurrent(window);
    if (backend_type == .opengles) glfw.makeContextCurrent(window);

    const instance = gpu.createInstance(null);
    if (instance == null) {
        std.debug.print("failed to create GPU instance\n", .{});
        std.process.exit(1);
    }
    const surface = try util.createSurfaceForWindow(instance.?, window, comptime util.detectGLFWOptions());

    var response: util.RequestAdapterResponse = undefined;
    instance.?.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = surface,
        .power_preference = .undefined,
        .force_fallback_adapter = .false,
    }, &response, util.requestAdapterCallback);
    if (response.status != .success) {
        std.debug.print("failed to create GPU adapter: {s}\n", .{response.message.?});
        std.process.exit(1);
    }

    // Print which adapter we are using.
    var props = std.mem.zeroes(gpu.Adapter.Properties);
    response.adapter.?.getProperties(&props);
    std.debug.print("found {s} backend on {s} adapter: {s}, {s}\n", .{
        props.backend_type.name(),
        props.adapter_type.name(),
        props.name,
        props.driver_description,
    });

    // Create a device with default limits/features.
    const device = response.adapter.?.createDevice(null);
    if (device == null) {
        std.debug.print("failed to create GPU device\n", .{});
        std.process.exit(1);
    }

    device.?.setUncapturedErrorCallback({}, util.printUnhandledErrorCallback);
    return Setup{
        .instance = instance.?,
        .adapter = response.adapter.?,
        .device = device.?,
        .window = window,
        .surface = surface,
    };
}
