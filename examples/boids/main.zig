/// A port of Austin Eng's "computeBoids" webgpu sample.
/// https://github.com/austinEng/webgpu-samples/blob/main/src/sample/computeBoids/main.ts
const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

compute_pipeline: gpu.ComputePipeline,
render_pipeline: gpu.RenderPipeline,
sprite_vertex_buffer: gpu.Buffer,
particle_buffers: [2]gpu.Buffer,
particle_bind_groups: [2]gpu.BindGroup,
sim_param_buffer: gpu.Buffer,
frame_counter: usize,

pub const App = @This();

const num_particle = 1500;

var sim_params = [_]f32{
    0.04, // .delta_T
    0.1, // .rule_1_distance
    0.025, // .rule_2_distance
    0.025, // .rule_3_distance
    0.02, // .rule_1_scale
    0.05, // .rule_2_scale
    0.005, // .rule_3_scale
};

pub fn init(app: *App, core: *mach.Core) !void {
    const sprite_shader_module = core.device.createShaderModule(&.{
        .label = "sprite shader module",
        .code = .{ .wgsl = @embedFile("sprite.wgsl") },
    });

    const update_sprite_shader_module = core.device.createShaderModule(&.{
        .label = "update sprite shader module",
        .code = .{ .wgsl = @embedFile("updateSprites.wgsl") },
    });

    const instanced_particles_attributes = [_]gpu.VertexAttribute{
        .{
            // instance position
            .shader_location = 0,
            .offset = 0,
            .format = .float32x2,
        },
        .{
            // instance velocity
            .shader_location = 1,
            .offset = 2 * 4,
            .format = .float32x2,
        },
    };

    const vertex_buffer_attributes = [_]gpu.VertexAttribute{
        .{
            // vertex positions
            .shader_location = 2,
            .offset = 0,
            .format = .float32x2,
        },
    };

    const render_pipeline = core.device.createRenderPipeline(&gpu.RenderPipeline.Descriptor{
        .vertex = .{
            .module = sprite_shader_module,
            .entry_point = "vert_main",
            .buffers = &[_]gpu.VertexBufferLayout{
                .{
                    // instanced particles buffer
                    .array_stride = 4 * 4,
                    .step_mode = .instance,
                    .attribute_count = instanced_particles_attributes.len,
                    .attributes = &instanced_particles_attributes,
                },
                .{
                    // vertex buffer
                    .array_stride = 2 * 4,
                    .step_mode = .vertex,
                    .attribute_count = vertex_buffer_attributes.len,
                    .attributes = &vertex_buffer_attributes,
                },
            },
        },
        .fragment = &gpu.FragmentState{ .module = sprite_shader_module, .entry_point = "frag_main", .targets = &[_]gpu.ColorTargetState{
            .{
                .format = core.swap_chain_format,
            },
        } },
    });

    const compute_pipeline = core.device.createComputePipeline(&gpu.ComputePipeline.Descriptor{ .compute = gpu.ProgrammableStageDescriptor{
        .module = update_sprite_shader_module,
        .entry_point = "main",
    } });

    const vert_buffer_data = [_]f32{
        -0.01, -0.02, 0.01,
        -0.02, 0.0,   0.02,
    };

    const sprite_vertex_buffer = core.device.createBuffer(&gpu.Buffer.Descriptor{
        .usage = .{ .vertex = true, .copy_dst = true },
        .size = vert_buffer_data.len * @sizeOf(f32),
    });
    core.device.getQueue().writeBuffer(sprite_vertex_buffer, 0, f32, &vert_buffer_data);

    const sim_param_buffer = core.device.createBuffer(&gpu.Buffer.Descriptor{
        .usage = .{ .uniform = true, .copy_dst = true },
        .size = sim_params.len * @sizeOf(f32),
    });
    core.device.getQueue().writeBuffer(sim_param_buffer, 0, f32, &sim_params);

    var initial_particle_data: [num_particle * 4]f32 = undefined;
    var rng = std.rand.DefaultPrng.init(0);
    const random = rng.random();
    var i: usize = 0;
    while (i < num_particle) : (i += 1) {
        initial_particle_data[4 * i + 0] = 2 * (random.float(f32) - 0.5);
        initial_particle_data[4 * i + 1] = 2 * (random.float(f32) - 0.5);
        initial_particle_data[4 * i + 2] = 2 * (random.float(f32) - 0.5) * 0.1;
        initial_particle_data[4 * i + 3] = 2 * (random.float(f32) - 0.5) * 0.1;
    }

    var particle_buffers: [2]gpu.Buffer = undefined;
    var particle_bind_groups: [2]gpu.BindGroup = undefined;
    i = 0;
    while (i < 2) : (i += 1) {
        particle_buffers[i] = core.device.createBuffer(&gpu.Buffer.Descriptor{
            .usage = .{
                .vertex = true,
                .copy_dst = true,
                .storage = true,
            },
            .size = initial_particle_data.len * @sizeOf(f32),
        });
        core.device.getQueue().writeBuffer(particle_buffers[i], 0, f32, &initial_particle_data);
    }

    i = 0;
    while (i < 2) : (i += 1) {
        particle_bind_groups[i] = core.device.createBindGroup(&gpu.BindGroup.Descriptor{ .layout = compute_pipeline.getBindGroupLayout(0), .entries = &[_]gpu.BindGroup.Entry{
            gpu.BindGroup.Entry.buffer(0, sim_param_buffer, 0, sim_params.len * @sizeOf(f32)),
            gpu.BindGroup.Entry.buffer(1, particle_buffers[i], 0, initial_particle_data.len * @sizeOf(f32)),
            gpu.BindGroup.Entry.buffer(2, particle_buffers[(i + 1) % 2], 0, initial_particle_data.len * @sizeOf(f32)),
        } });
    }

    app.compute_pipeline = compute_pipeline;
    app.render_pipeline = render_pipeline;
    app.sprite_vertex_buffer = sprite_vertex_buffer;
    app.particle_buffers = particle_buffers;
    app.particle_bind_groups = particle_bind_groups;
    app.sim_param_buffer = sim_param_buffer;
    app.frame_counter = 0;
}

pub fn deinit(_: *App, _: *mach.Core) void {}

pub fn update(app: *App, core: *mach.Core) !void {
    const back_buffer_view = core.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const render_pass_descriptor = gpu.RenderPassEncoder.Descriptor{ .color_attachments = &[_]gpu.RenderPassColorAttachment{
        color_attachment,
    } };

    sim_params[0] = @floatCast(f32, core.delta_time);
    core.device.getQueue().writeBuffer(app.sim_param_buffer, 0, f32, &sim_params);

    const command_encoder = core.device.createCommandEncoder(null);
    {
        const pass_encoder = command_encoder.beginComputePass(null);
        pass_encoder.setPipeline(app.compute_pipeline);
        pass_encoder.setBindGroup(0, app.particle_bind_groups[app.frame_counter % 2], null);
        pass_encoder.dispatch(@floatToInt(u32, @ceil(@as(f32, num_particle) / 64)), 1, 1);
        pass_encoder.end();
        pass_encoder.release();
    }
    {
        const pass_encoder = command_encoder.beginRenderPass(&render_pass_descriptor);
        pass_encoder.setPipeline(app.render_pipeline);
        pass_encoder.setVertexBuffer(0, app.particle_buffers[(app.frame_counter + 1) % 2], 0, num_particle * 4 * @sizeOf(f32));
        pass_encoder.setVertexBuffer(1, app.sprite_vertex_buffer, 0, 6 * @sizeOf(f32));
        pass_encoder.draw(3, num_particle, 0, 0);
        pass_encoder.end();
        pass_encoder.release();
    }

    app.frame_counter += 1;
    if (app.frame_counter % 60 == 0) {
        std.log.info("Frame {}", .{app.frame_counter});
    }

    var command = command_encoder.finish(null);
    command_encoder.release();
    core.device.getQueue().submit(&.{command});
    command.release();

    core.swap_chain.?.present();
    back_buffer_view.release();
}
