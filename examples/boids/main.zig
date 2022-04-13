/// A port of Austin Eng's "computeBoids" webgpu sample.
/// https://github.com/austinEng/webgpu-samples/blob/main/src/sample/computeBoids/main.ts

const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

const FrameParams = struct {
    compute_pipeline: gpu.ComputePipeline,
    render_pipeline: gpu.RenderPipeline,
    sprite_vertex_buffer: gpu.Buffer,
    particle_buffers: [2]gpu.Buffer,
    particle_bind_groups: [2]gpu.BindGroup,
    frame_counter: usize,
};
const App = mach.App(*FrameParams, .{});

const num_particle = 1500;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const ctx = try allocator.create(FrameParams);
    var app = try App.init(allocator, ctx, .{});

    const sprite_shader_module = app.device.createShaderModule(&.{
        .label = "sprite shader module",
        .code = .{ .wgsl = @embedFile("sprite.wgsl") },
    });

    const update_sprite_shader_module = app.device.createShaderModule(&.{
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

    const render_pipeline = app.device.createRenderPipeline(&gpu.RenderPipeline.Descriptor{
        .vertex = .{
            .module = sprite_shader_module,
            .entry_point = "vert_main",
            .buffers = &[_]gpu.VertexBufferLayout{
                .{
                    // instanced particles buffer
                    .array_stride = 4*4,
                    .step_mode = .instance,
                    .attribute_count = instanced_particles_attributes.len,
                    .attributes = &instanced_particles_attributes,
                },
                .{
                    // vertex buffer
                    .array_stride = 2*4,
                    .step_mode = .vertex,
                    .attribute_count = vertex_buffer_attributes.len,
                    .attributes = &vertex_buffer_attributes,
                },
            },
        },
        .fragment = &gpu.FragmentState{
            .module = sprite_shader_module,
            .entry_point = "frag_main",
            .targets = &[_]gpu.ColorTargetState{
                .{
                    .format = app.swap_chain_format,
                },
            }
        },
    });

    const compute_pipeline = app.device.createComputePipeline(&gpu.ComputePipeline.Descriptor{
            .compute = gpu.ProgrammableStageDescriptor{
                .module = update_sprite_shader_module,
                .entry_point = "main",
            }
    });

    const vert_buffer_data = [_]f32{
        -0.01, -0.02, 0.01,
        -0.02, 0.0, 0.02,
    };

    const sprite_vertex_buffer = app.device.createBuffer(&gpu.Buffer.Descriptor{
        .usage = .{.vertex = true, .copy_dst = true},
        .size = vert_buffer_data.len * @sizeOf(f32),
    });
    app.device.getQueue().writeBuffer(sprite_vertex_buffer, 0, f32, &vert_buffer_data);

    const sim_params = [_]f32 {
        0.04,  // .delta_T
        0.1,   // .rule_1_distance
        0.025, // .rule_2_distance
        0.025, // .rule_3_distance
        0.02,  // .rule_1_scale
        0.05,  // .rule_2_scale
        0.005, // .rule_3_scale
    };

    const sim_param_buffer = app.device.createBuffer(&gpu.Buffer.Descriptor{
        .usage = .{.uniform = true, .copy_dst = true},
        .size = sim_params.len * @sizeOf(f32),
    });
    app.device.getQueue().writeBuffer(sim_param_buffer, 0, f32, &sim_params);
    
    var initial_particle_data: [num_particle*4]f32 = undefined;
    var rng = std.rand.DefaultPrng.init(0);
    const random = rng.random();
    var i:usize = 0;
    while(i < num_particle): (i += 1) {
        initial_particle_data[4 * i + 0] = 2 * (random.float(f32) - 0.5);
        initial_particle_data[4 * i + 1] = 2 * (random.float(f32) - 0.5);
        initial_particle_data[4 * i + 2] = 2 * (random.float(f32) - 0.5) * 0.1;
        initial_particle_data[4 * i + 3] = 2 * (random.float(f32) - 0.5) * 0.1;
    }

    var particle_buffers: [2]gpu.Buffer = undefined;
    var particle_bind_groups: [2]gpu.BindGroup = undefined;
    i = 0;
    while(i < 2): (i+=1) {
        particle_buffers[i] = app.device.createBuffer(&gpu.Buffer.Descriptor{
            .usage = .{.vertex = true, .copy_dst = true, .storage = true, },
            .size = initial_particle_data.len * @sizeOf(f32),
        });
        app.device.getQueue().writeBuffer(particle_buffers[i], 0, f32, &initial_particle_data);
    }

    i = 0;
    while(i < 2): (i+=1) {
        particle_bind_groups[i] = app.device.createBindGroup(&gpu.BindGroup.Descriptor{
            .layout = compute_pipeline.getBindGroupLayout(0),
            .entries = &[_]gpu.BindGroup.Entry {
                gpu.BindGroup.Entry.buffer(0, sim_param_buffer,          0, sim_params.len * @sizeOf(f32)),
                gpu.BindGroup.Entry.buffer(1, particle_buffers[i],       0, initial_particle_data.len * @sizeOf(f32)),
                gpu.BindGroup.Entry.buffer(2, particle_buffers[(i+1)%2], 0, initial_particle_data.len * @sizeOf(f32)),
            }
        });
    }

    ctx.* = FrameParams{
        .compute_pipeline = compute_pipeline,
        .render_pipeline = render_pipeline,
        .sprite_vertex_buffer = sprite_vertex_buffer,
        .particle_buffers = particle_buffers,
        .particle_bind_groups = particle_bind_groups,
        .frame_counter = 0,
    };

    try app.run(.{ .frame = frame });
}

fn frame(app: *App, params: *FrameParams) !void {
    const back_buffer_view = app.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const render_pass_descriptor = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &[_]gpu.RenderPassColorAttachment {
            color_attachment,
        }
    };

    const command_encoder = app.device.createCommandEncoder(null);
    {
        const pass_encoder = command_encoder.beginComputePass(null);
        pass_encoder.setPipeline(params.compute_pipeline);
        pass_encoder.setBindGroup(0, params.particle_bind_groups[params.frame_counter % 2], null);
        pass_encoder.dispatch(@floatToInt(u32, std.math.ceil(@as(f32, num_particle) / 64)), 1, 1);
        pass_encoder.end();
        pass_encoder.release();
    }
    {
        const pass_encoder = command_encoder.beginRenderPass(&render_pass_descriptor);
        pass_encoder.setPipeline(params.render_pipeline);
        pass_encoder.setVertexBuffer(0, params.particle_buffers[(params.frame_counter + 1) % 2], 0, num_particle*4*@sizeOf(f32));
        pass_encoder.setVertexBuffer(1, params.sprite_vertex_buffer, 0, 6*@sizeOf(f32));
        pass_encoder.draw(3, num_particle, 0, 0);
        pass_encoder.end();
        pass_encoder.release();
    }

    params.frame_counter += 1;
    if(params.frame_counter % 60 == 0) {
        std.debug.print("Frame {}\n", .{params.frame_counter});
    }

    var command = command_encoder.finish(null);
    command_encoder.release();
    app.device.getQueue().submit(&.{command});
    command.release();

    app.swap_chain.?.present();
    back_buffer_view.release();
}