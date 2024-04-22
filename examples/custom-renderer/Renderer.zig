// TODO(important): docs
// TODO(important): review all code in this file in-depth
const std = @import("std");

const mach = @import("mach");
const gpu = mach.gpu;
const math = mach.math;

const Vec3 = math.Vec3;

const num_bind_groups = 1024 * 32;

// uniform bind group offset must be 256-byte aligned
const uniform_offset = 256;

pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,
bind_groups: [num_bind_groups]*gpu.BindGroup,
uniform_buffer: *gpu.Buffer,

pub const name = .renderer;
pub const Mod = mach.Mod(@This());

pub const components = .{
    .position = .{ .type = Vec3 },
    .rotation = .{ .type = Vec3 },
    .scale = .{ .type = f32 },
};

pub const global_events = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
};

const UniformBufferObject = extern struct {
    offset: Vec3,
    scale: f32,
};

fn init(
    core: *mach.Core.Mod,
    renderer: *Mod,
) !void {
    const device = core.state().device;
    const shader_module = device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));

    // Fragment state
    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.get(core.state().main_window, .framebuffer_format).?,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    const label = @tagName(name) ++ ".init";
    const uniform_buffer = device.createBuffer(&.{
        .label = label ++ " uniform buffer",
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject) * uniform_offset * num_bind_groups,
        .mapped_at_creation = .false,
    });
    const bind_group_layout_entry = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bind_group_layout = device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .label = label,
            .entries = &.{bind_group_layout_entry},
        }),
    );
    var bind_groups: [num_bind_groups]*gpu.BindGroup = undefined;
    for (bind_groups, 0..) |_, i| {
        bind_groups[i] = device.createBindGroup(
            &gpu.BindGroup.Descriptor.init(.{
                .label = label,
                .layout = bind_group_layout,
                .entries = &.{
                    gpu.BindGroup.Entry.buffer(0, uniform_buffer, uniform_offset * i, @sizeOf(UniformBufferObject)),
                },
            }),
        );
    }

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .label = label,
        .bind_group_layouts = &bind_group_layouts,
    }));
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };

    renderer.init(.{
        .pipeline = device.createRenderPipeline(&pipeline_descriptor),
        .queue = device.getQueue(),
        .bind_groups = bind_groups,
        .uniform_buffer = uniform_buffer,
    });
    shader_module.release();
}

fn deinit(
    renderer: *Mod,
) !void {
    renderer.state().pipeline.release();
    renderer.state().queue.release();
    for (renderer.state().bind_groups) |bind_group| bind_group.release();
    renderer.state().uniform_buffer.release();
}

fn tick(
    core: *mach.Core.Mod,
    renderer: *Mod,
) !void {
    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(name) ++ ".tick";
    const encoder = core.state().device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

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

    // Update uniform buffer
    var archetypes_iter = core.entities.query(.{ .all = &.{
        .{ .renderer = &.{ .position, .scale } },
    } });
    var num_entities: usize = 0;
    while (archetypes_iter.next()) |archetype| {
        const ids = archetype.slice(.entity, .id);
        const positions = archetype.slice(.renderer, .position);
        const scales = archetype.slice(.renderer, .scale);
        for (ids, positions, scales) |id, position, scale| {
            _ = id;

            const ubo = UniformBufferObject{
                .offset = position,
                .scale = scale,
            };
            encoder.writeBuffer(renderer.state().uniform_buffer, uniform_offset * num_entities, &[_]UniformBufferObject{ubo});
            num_entities += 1;
        }
    }

    // Draw
    for (renderer.state().bind_groups[0..num_entities]) |bind_group| {
        render_pass.setPipeline(renderer.state().pipeline);
        render_pass.setBindGroup(0, bind_group, &.{0});
        render_pass.draw(3, 1, 0, 0);
    }

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.send(.present_frame, .{});
}
