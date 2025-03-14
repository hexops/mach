const mach = @import("mach");
const gpu = mach.gpu;
const math = mach.math;

const Vec3 = math.Vec3;

pub const mach_module = .renderer;

pub const mach_systems = .{ .init, .deinit, .renderFrame };

const Renderer = @This();

const num_bind_groups = 1024 * 32;

// uniform bind group offset must be 256-byte aligned
const uniform_offset = 256;

const UniformBufferObject = extern struct {
    offset: Vec3,
    scale: f32,
};

window: mach.ObjectID,
pipeline: *gpu.RenderPipeline,
bind_groups: [num_bind_groups]*gpu.BindGroup,
uniform_buffer: *gpu.Buffer,

objects: mach.Objects(.{}, struct {
    position: Vec3,
    scale: f32,
}),

pub fn init(
    core: *mach.Core,
    renderer: *Renderer,
) !void {
    const window = core.windows.getValue(renderer.window);
    const device = window.device;
    const shader_module = device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Fragment state
    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = window.framebuffer_format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    const label = @tagName(mach_module) ++ ".init";
    const uniform_buffer = device.createBuffer(&.{
        .label = label ++ " uniform buffer",
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject) * uniform_offset * num_bind_groups,
        .mapped_at_creation = .false,
    });

    const bind_group_layout_entry = gpu.BindGroupLayout.Entry.initBuffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bind_group_layout = device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .label = label,
            .entries = &.{bind_group_layout_entry},
        }),
    );
    defer bind_group_layout.release();

    var bind_groups: [num_bind_groups]*gpu.BindGroup = undefined;
    for (bind_groups, 0..) |_, i| {
        bind_groups[i] = device.createBindGroup(
            &gpu.BindGroup.Descriptor.init(.{
                .label = label,
                .layout = bind_group_layout,
                .entries = &.{gpu.BindGroup.Entry.initBuffer(0, uniform_buffer, uniform_offset * i, @sizeOf(UniformBufferObject), @sizeOf(UniformBufferObject))},
            }),
        );
    }

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .label = label,
        .bind_group_layouts = &bind_group_layouts,
    }));
    defer pipeline_layout.release();

    const pipeline = device.createRenderPipeline(&gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    });

    renderer.* = .{
        .window = renderer.window,
        .objects = renderer.objects,
        .pipeline = pipeline,
        .bind_groups = bind_groups,
        .uniform_buffer = uniform_buffer,
    };
}

pub fn deinit(
    renderer: *Renderer,
) !void {
    renderer.pipeline.release();
    for (renderer.bind_groups) |bind_group| bind_group.release();
    renderer.uniform_buffer.release();
}

pub fn renderFrame(
    core: *mach.Core,
    renderer: *Renderer,
) !void {
    const window = core.windows.getValue(renderer.window);

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = window.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(mach_module) ++ ".tick";
    const encoder = window.device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    // Update uniform buffer
    var num_objects: usize = 0;
    var objs = renderer.objects.slice();
    while (objs.next()) |obj_id| {
        const obj = renderer.objects.getValue(obj_id);
        const ubo = UniformBufferObject{
            .offset = obj.position,
            .scale = obj.scale,
        };
        encoder.writeBuffer(renderer.uniform_buffer, uniform_offset * num_objects, &[_]UniformBufferObject{ubo});
        num_objects += 1;
    }

    // Begin render pass
    const sky_blue_background = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue_background,
        .load_op = .clear,
        .store_op = .store,
    }};
    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));
    defer render_pass.release();

    // Draw
    for (renderer.bind_groups[0..num_objects]) |bind_group| {
        render_pass.setPipeline(renderer.pipeline);
        render_pass.setBindGroup(0, bind_group, &.{0});
        render_pass.draw(3, 1, 0, 0);
    }

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    window.queue.submit(&[_]*gpu.CommandBuffer{command});

    mach.sysgpu.Impl.deviceTick(window.device);

    window.swap_chain.present();
}
