const std = @import("std");
const sample_utils = @import("sample_utils.zig");
const c = @import("c.zig").c;
const glfw = @import("glfw");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const setup = try sample_utils.setup(allocator);
    const queue = c.wgpuDeviceGetQueue(setup.device);
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

    // If targetting OpenGL, we can't use the newer WGPUSurface API. Instead, we need to use the
    // older Dawn-specific API. https://bugs.chromium.org/p/dawn/issues/detail?id=269&q=surface&can=2
    const use_legacy_api = setup.backend_type == c.WGPUBackendType_OpenGL or setup.backend_type == c.WGPUBackendType_OpenGLES;
    var descriptor: c.WGPUSwapChainDescriptor = undefined;
    if (!use_legacy_api) {
        window_data.swap_chain_format = c.WGPUTextureFormat_BGRA8Unorm;
        descriptor = c.WGPUSwapChainDescriptor{
            .nextInChain = null,
            .label = "basic swap chain",
            .usage = c.WGPUTextureUsage_RenderAttachment,
            .format = window_data.swap_chain_format,
            .width = framebuffer_size.width,
            .height = framebuffer_size.height,
            .presentMode = c.WGPUPresentMode_Fifo,
            .implementation = 0,
        };
        window_data.surface = sample_utils.createSurfaceForWindow(
            setup.instance,
            setup.window,
            comptime sample_utils.detectGLFWOptions(),
        );
    } else {
        const binding = c.machUtilsCreateBinding(setup.backend_type, @ptrCast(*c.GLFWwindow, setup.window.handle), setup.device);
        if (binding == null) {
            @panic("failed to create Dawn backend binding");
        }
        descriptor = std.mem.zeroes(c.WGPUSwapChainDescriptor);
        descriptor.implementation = c.machUtilsBackendBinding_getSwapChainImplementation(binding);
        window_data.swap_chain = c.wgpuDeviceCreateSwapChain(setup.device, null, &descriptor);

        window_data.swap_chain_format = c.machUtilsBackendBinding_getPreferredSwapChainTextureFormat(binding);
        c.wgpuSwapChainConfigure(
            window_data.swap_chain.?,
            window_data.swap_chain_format,
            c.WGPUTextureUsage_RenderAttachment,
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
    var vs_wgsl_descriptor = try allocator.create(c.WGPUShaderModuleWGSLDescriptor);
    vs_wgsl_descriptor.chain.next = null;
    vs_wgsl_descriptor.chain.sType = c.WGPUSType_ShaderModuleWGSLDescriptor;
    vs_wgsl_descriptor.source = vs;
    const vs_shader_descriptor = c.WGPUShaderModuleDescriptor{
        .nextInChain = @ptrCast(*const c.WGPUChainedStruct, vs_wgsl_descriptor),
        .label = "my vertex shader",
    };
    const vs_module = c.wgpuDeviceCreateShaderModule(setup.device, &vs_shader_descriptor);

    const fs =
        \\ @stage(fragment) fn main() -> @location(0) vec4<f32> {
        \\     return vec4<f32>(1.0, 0.0, 0.0, 1.0);
        \\ }
    ;
    var fs_wgsl_descriptor = try allocator.create(c.WGPUShaderModuleWGSLDescriptor);
    fs_wgsl_descriptor.chain.next = null;
    fs_wgsl_descriptor.chain.sType = c.WGPUSType_ShaderModuleWGSLDescriptor;
    fs_wgsl_descriptor.source = fs;
    const fs_shader_descriptor = c.WGPUShaderModuleDescriptor{
        .nextInChain = @ptrCast(*const c.WGPUChainedStruct, fs_wgsl_descriptor),
        .label = "my fragment shader",
    };
    const fs_module = c.wgpuDeviceCreateShaderModule(setup.device, &fs_shader_descriptor);

    // Fragment state
    var blend = std.mem.zeroes(c.WGPUBlendState);
    blend.color.operation = c.WGPUBlendOperation_Add;
    blend.color.srcFactor = c.WGPUBlendFactor_One;
    blend.color.dstFactor = c.WGPUBlendFactor_One;
    blend.alpha.operation = c.WGPUBlendOperation_Add;
    blend.alpha.srcFactor = c.WGPUBlendFactor_One;
    blend.alpha.dstFactor = c.WGPUBlendFactor_One;

    var color_target = std.mem.zeroes(c.WGPUColorTargetState);
    color_target.format = window_data.swap_chain_format;
    color_target.blend = &blend;
    color_target.writeMask = c.WGPUColorWriteMask_All;

    var fragment = std.mem.zeroes(c.WGPUFragmentState);
    fragment.module = fs_module;
    fragment.entryPoint = "main";
    fragment.targetCount = 1;
    fragment.targets = &color_target;

    var pipeline_descriptor = std.mem.zeroes(c.WGPURenderPipelineDescriptor);
    pipeline_descriptor.fragment = &fragment;

    // Other state
    pipeline_descriptor.layout = null;
    pipeline_descriptor.depthStencil = null;

    pipeline_descriptor.vertex.module = vs_module;
    pipeline_descriptor.vertex.entryPoint = "main";
    pipeline_descriptor.vertex.bufferCount = 0;
    pipeline_descriptor.vertex.buffers = null;

    pipeline_descriptor.multisample.count = 1;
    pipeline_descriptor.multisample.mask = 0xFFFFFFFF;
    pipeline_descriptor.multisample.alphaToCoverageEnabled = false;

    pipeline_descriptor.primitive.frontFace = c.WGPUFrontFace_CCW;
    pipeline_descriptor.primitive.cullMode = c.WGPUCullMode_None;
    pipeline_descriptor.primitive.topology = c.WGPUPrimitiveTopology_TriangleList;
    pipeline_descriptor.primitive.stripIndexFormat = c.WGPUIndexFormat_Undefined;

    const pipeline = c.wgpuDeviceCreateRenderPipeline(setup.device, &pipeline_descriptor);

    c.wgpuShaderModuleRelease(vs_module);
    c.wgpuShaderModuleRelease(fs_module);

    // Reconfigure the swap chain with the new framebuffer width/height, otherwise e.g. the Vulkan
    // device would be lost after a resize.
    setup.window.setFramebufferSizeCallback((struct {
        fn callback(window: glfw.Window, width: u32, height: u32) void {
            const pl = window.getUserPointer(WindowData);
            pl.?.target_desc.width = width;
            pl.?.target_desc.height = height;
        }
    }).callback);

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
    surface: ?c.WGPUSurface,
    swap_chain: ?c.WGPUSwapChain,
    swap_chain_format: c.WGPUTextureFormat,
    current_desc: c.WGPUSwapChainDescriptor,
    target_desc: c.WGPUSwapChainDescriptor,
};

const FrameParams = struct {
    window: glfw.Window,
    device: c.WGPUDevice,
    pipeline: c.WGPURenderPipeline,
    queue: c.WGPUQueue,
};

fn isDescriptorEqual(a: c.WGPUSwapChainDescriptor, b: c.WGPUSwapChainDescriptor) bool {
    return a.usage == b.usage and a.format == b.format and a.width == b.width and a.height == b.height and a.presentMode == b.presentMode;
}

fn frame(params: FrameParams) !void {
    try glfw.pollEvents();
    const pl = params.window.getUserPointer(WindowData).?;
    if (pl.swap_chain == null or !isDescriptorEqual(pl.current_desc, pl.target_desc)) {
        const use_legacy_api = pl.surface == null;
        if (!use_legacy_api) {
            pl.swap_chain = c.wgpuDeviceCreateSwapChain(params.device, pl.surface.?, &pl.target_desc);
        } else {
            c.wgpuSwapChainConfigure(
                pl.swap_chain.?,
                pl.swap_chain_format,
                c.WGPUTextureUsage_RenderAttachment,
                @intCast(u32, pl.target_desc.width),
                @intCast(u32, pl.target_desc.height),
            );
        }
        pl.current_desc = pl.target_desc;
    }

    const back_buffer_view = c.wgpuSwapChainGetCurrentTextureView(pl.swap_chain.?);
    var render_pass_info = std.mem.zeroes(c.WGPURenderPassDescriptor);
    var color_attachment = std.mem.zeroes(c.WGPURenderPassColorAttachment);
    color_attachment.view = back_buffer_view;
    color_attachment.resolveTarget = null;
    color_attachment.clearValue = c.WGPUColor{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 };
    color_attachment.loadOp = c.WGPULoadOp_Clear;
    color_attachment.storeOp = c.WGPUStoreOp_Store;
    render_pass_info.colorAttachmentCount = 1;
    render_pass_info.colorAttachments = &color_attachment;
    render_pass_info.depthStencilAttachment = null;

    const encoder = c.wgpuDeviceCreateCommandEncoder(params.device, null);
    const pass = c.wgpuCommandEncoderBeginRenderPass(encoder, &render_pass_info);
    c.wgpuRenderPassEncoderSetPipeline(pass, params.pipeline);
    c.wgpuRenderPassEncoderDraw(pass, 3, 1, 0, 0);
    c.wgpuRenderPassEncoderEnd(pass);
    c.wgpuRenderPassEncoderRelease(pass);

    const commands = c.wgpuCommandEncoderFinish(encoder, null);
    c.wgpuCommandEncoderRelease(encoder);

    c.wgpuQueueSubmit(params.queue, 1, &commands);
    c.wgpuCommandBufferRelease(commands);
    c.wgpuSwapChainPresent(pl.swap_chain.?);
    c.wgpuTextureViewRelease(back_buffer_view);
}
