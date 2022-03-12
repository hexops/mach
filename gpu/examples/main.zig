const std = @import("std");
const sample_utils = @import("sample_utils.zig");
const c = @import("c.zig").c;
const glfw = @import("glfw");
const gpu = @import("gpu");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const setup = try sample_utils.setup(allocator);
    const framebuffer_size = try setup.window.getFramebufferSize();

    const window_data = try allocator.create(WindowData);
    window_data.* = .{
        .surface = null,
        .swap_chain = null,
        .swap_chain_format = undefined,
        .current_desc = undefined,
        .target_desc = undefined,
    };
    setup.window.setUserPointer(window_data);

    // If targeting OpenGL, we can't use the newer WGPUSurface API. Instead, we need to use the
    // older Dawn-specific API. https://bugs.chromium.org/p/dawn/issues/detail?id=269&q=surface&can=2
    const use_legacy_api = setup.backend_type == .opengl or setup.backend_type == .opengles;
    var descriptor: gpu.SwapChain.Descriptor = undefined;
    if (!use_legacy_api) {
        window_data.swap_chain_format = .bgra8_unorm;
        descriptor = .{
            .label = "basic swap chain",
            .usage = .render_attachment,
            .format = window_data.swap_chain_format,
            .width = framebuffer_size.width,
            .height = framebuffer_size.height,
            .present_mode = .fifo,
            .implementation = 0,
        };
        window_data.surface = sample_utils.createSurfaceForWindow(
            &setup.native_instance,
            setup.window,
            comptime sample_utils.detectGLFWOptions(),
        );
    } else {
        const binding = c.machUtilsCreateBinding(@enumToInt(setup.backend_type), @ptrCast(*c.GLFWwindow, setup.window.handle), @ptrCast(c.WGPUDevice, setup.device.ptr));
        if (binding == null) {
            @panic("failed to create Dawn backend binding");
        }
        descriptor = std.mem.zeroes(gpu.SwapChain.Descriptor);
        descriptor.implementation = c.machUtilsBackendBinding_getSwapChainImplementation(binding);
        window_data.swap_chain = setup.device.nativeCreateSwapChain(null, &descriptor);

        window_data.swap_chain_format = @intToEnum(gpu.Texture.Format, @intCast(u32, c.machUtilsBackendBinding_getPreferredSwapChainTextureFormat(binding)));
        window_data.swap_chain.?.configure(
            window_data.swap_chain_format,
            .render_attachment,
            framebuffer_size.width,
            framebuffer_size.height,
        );
    }
    window_data.current_desc = descriptor;
    window_data.target_desc = descriptor;

    const vs =
        \\ @stage(vertex) fn main(
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
    const vs_module = setup.device.createShaderModule(&.{
        .label = "my vertex shader",
        .code = .{ .wgsl = vs },
    });

    const fs =
        \\ @stage(fragment) fn main() -> @location(0) vec4<f32> {
        \\     return vec4<f32>(1.0, 0.0, 0.0, 1.0);
        \\ }
    ;
    const fs_module = setup.device.createShaderModule(&.{
        .label = "my fragment shader",
        .code = .{ .wgsl = fs },
    });

    // Fragment state
    const blend = gpu.BlendState{
        .color = .{
            .operation = .add,
            .src_factor = .one,
            .dst_factor = .one,
        },
        .alpha = .{
            .operation = .add,
            .src_factor = .one,
            .dst_factor = .one,
        },
    };
    const color_target = gpu.ColorTargetState{
        .format = window_data.swap_chain_format,
        .blend = &blend,
        .write_mask = .all,
    };
    const fragment = gpu.FragmentState{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
        .constants = null,
    };
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = null,
        .depth_stencil = null,
        .vertex = .{
            .module = vs_module,
            .entry_point = "main",
            .buffers = null,
        },
        .multisample = .{
            .count = 1,
            .mask = 0xFFFFFFFF,
            .alpha_to_coverage_enabled = false,
        },
        .primitive = .{
            .front_face = .ccw,
            .cull_mode = .none,
            .topology = .triangle_list,
            .strip_index_format = .none,
        },
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
    surface: ?gpu.Surface,
    swap_chain: ?gpu.SwapChain,
    swap_chain_format: gpu.Texture.Format,
    current_desc: gpu.SwapChain.Descriptor,
    target_desc: gpu.SwapChain.Descriptor,
};

const FrameParams = struct {
    window: glfw.Window,
    device: gpu.Device,
    pipeline: gpu.RenderPipeline,
    queue: gpu.Queue,
};

fn frame(params: FrameParams) !void {
    try glfw.pollEvents();
    const pl = params.window.getUserPointer(WindowData).?;
    if (pl.swap_chain == null or !pl.current_desc.equal(&pl.target_desc)) {
        const use_legacy_api = pl.surface == null;
        if (!use_legacy_api) {
            pl.swap_chain = params.device.nativeCreateSwapChain(pl.surface, &pl.target_desc);
        } else pl.swap_chain.?.configure(
            pl.swap_chain_format,
            .render_attachment,
            pl.target_desc.width,
            pl.target_desc.height,
        );
        pl.current_desc = pl.target_desc;
    }

    const back_buffer_view = pl.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = params.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = null,
    };
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(params.pipeline);
    pass.draw(3, 1, 0, 0);
    c.wgpuRenderPassEncoderEnd(@ptrCast(c.WGPURenderPassEncoder, pass.ptr));
    pass.release();

    var commands = c.wgpuCommandEncoderFinish(@ptrCast(c.WGPUCommandEncoder, encoder.ptr), null);
    encoder.release();

    const buf = gpu.CommandBuffer{ .ptr = &commands, .vtable = undefined };
    params.queue.submit(1, &buf);
    c.wgpuCommandBufferRelease(commands);
    pl.swap_chain.?.present();
    back_buffer_view.release();
}
