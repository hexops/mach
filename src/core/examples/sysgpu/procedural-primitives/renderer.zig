const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;

const zm = @import("zmath");
const primitives = @import("procedural-primitives.zig");
const Primitive = primitives.Primitive;
const VertexData = primitives.VertexData;

pub const Renderer = @This();

var queue: *gpu.Queue = undefined;
var pipeline: *gpu.RenderPipeline = undefined;
var app_timer: core.Timer = undefined;
var depth_texture: *gpu.Texture = undefined;
var depth_texture_view: *gpu.TextureView = undefined;

const PrimitiveRenderData = struct {
    vertex_buffer: *gpu.Buffer,
    index_buffer: *gpu.Buffer,
    vertex_count: u32,
    index_count: u32,
};

const UniformBufferObject = struct {
    mvp_matrix: zm.Mat,
};
var uniform_buffer: *gpu.Buffer = undefined;
var bind_group: *gpu.BindGroup = undefined;

var primitives_data: [7]PrimitiveRenderData = undefined;

pub var curr_primitive_index: u4 = 0;

pub fn init(allocator: std.mem.Allocator, timer: core.Timer) !void {
    queue = core.queue;
    app_timer = timer;

    {
        const triangle_primitive = try primitives.createTrianglePrimitive(allocator, 1);
        primitives_data[0] = PrimitiveRenderData{ .vertex_buffer = createVertexBuffer(triangle_primitive), .index_buffer = createIndexBuffer(triangle_primitive), .vertex_count = triangle_primitive.vertex_count, .index_count = triangle_primitive.index_count };
        defer triangle_primitive.vertex_data.deinit();
        defer triangle_primitive.index_data.deinit();
    }

    {
        const quad_primitive = try primitives.createQuadPrimitive(allocator, 1.4);
        primitives_data[1] = PrimitiveRenderData{ .vertex_buffer = createVertexBuffer(quad_primitive), .index_buffer = createIndexBuffer(quad_primitive), .vertex_count = quad_primitive.vertex_count, .index_count = quad_primitive.index_count };
        defer quad_primitive.vertex_data.deinit();
        defer quad_primitive.index_data.deinit();
    }

    {
        const plane_primitive = try primitives.createPlanePrimitive(allocator, 1000, 1000, 1.5);
        primitives_data[2] = PrimitiveRenderData{ .vertex_buffer = createVertexBuffer(plane_primitive), .index_buffer = createIndexBuffer(plane_primitive), .vertex_count = plane_primitive.vertex_count, .index_count = plane_primitive.index_count };
        defer plane_primitive.vertex_data.deinit();
        defer plane_primitive.index_data.deinit();
    }

    {
        const circle_primitive = try primitives.createCirclePrimitive(allocator, 64, 1);
        primitives_data[3] = PrimitiveRenderData{ .vertex_buffer = createVertexBuffer(circle_primitive), .index_buffer = createIndexBuffer(circle_primitive), .vertex_count = circle_primitive.vertex_count, .index_count = circle_primitive.index_count };
        defer circle_primitive.vertex_data.deinit();
        defer circle_primitive.index_data.deinit();
    }

    {
        const cube_primitive = try primitives.createCubePrimitive(allocator, 0.5);
        primitives_data[4] = PrimitiveRenderData{ .vertex_buffer = createVertexBuffer(cube_primitive), .index_buffer = createIndexBuffer(cube_primitive), .vertex_count = cube_primitive.vertex_count, .index_count = cube_primitive.index_count };
        defer cube_primitive.vertex_data.deinit();
        defer cube_primitive.index_data.deinit();
    }

    {
        const cylinder_primitive = try primitives.createCylinderPrimitive(allocator, 1.0, 1.0, 6);
        primitives_data[5] = PrimitiveRenderData{ .vertex_buffer = createVertexBuffer(cylinder_primitive), .index_buffer = createIndexBuffer(cylinder_primitive), .vertex_count = cylinder_primitive.vertex_count, .index_count = cylinder_primitive.index_count };
        defer cylinder_primitive.vertex_data.deinit();
        defer cylinder_primitive.index_data.deinit();
    }

    {
        const cone_primitive = try primitives.createConePrimitive(allocator, 0.7, 1.0, 15);
        primitives_data[6] = PrimitiveRenderData{ .vertex_buffer = createVertexBuffer(cone_primitive), .index_buffer = createIndexBuffer(cone_primitive), .vertex_count = cone_primitive.vertex_count, .index_count = cone_primitive.index_count };
        defer cone_primitive.vertex_data.deinit();
        defer cone_primitive.index_data.deinit();
    }
    var bind_group_layout = createBindGroupLayout();
    defer bind_group_layout.release();

    createBindBuffer(bind_group_layout);

    createDepthTexture();

    var shader = core.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader.release();

    pipeline = createPipeline(shader, bind_group_layout);
}

fn createVertexBuffer(primitive: Primitive) *gpu.Buffer {
    const vertex_buffer_descriptor = gpu.Buffer.Descriptor{
        .size = primitive.vertex_count * @sizeOf(VertexData),
        .usage = .{ .vertex = true, .copy_dst = true },
        .mapped_at_creation = .false,
    };

    const vertex_buffer = core.device.createBuffer(&vertex_buffer_descriptor);
    queue.writeBuffer(vertex_buffer, 0, primitive.vertex_data.items[0..]);

    return vertex_buffer;
}

fn createIndexBuffer(primitive: Primitive) *gpu.Buffer {
    const index_buffer_descriptor = gpu.Buffer.Descriptor{
        .size = primitive.index_count * @sizeOf(u32),
        .usage = .{ .index = true, .copy_dst = true },
        .mapped_at_creation = .false,
    };
    const index_buffer = core.device.createBuffer(&index_buffer_descriptor);
    queue.writeBuffer(index_buffer, 0, primitive.index_data.items[0..]);

    return index_buffer;
}

fn createBindGroupLayout() *gpu.BindGroupLayout {
    const bgle = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true, .fragment = false }, .uniform, true, 0);
    return core.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{bgle},
        }),
    );
}

fn createBindBuffer(bind_group_layout: *gpu.BindGroupLayout) void {
    uniform_buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = .false,
    });

    bind_group = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bind_group_layout,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject), @sizeOf(UniformBufferObject)),
            },
        }),
    );
}

fn createDepthTexture() void {
    depth_texture = core.device.createTexture(&gpu.Texture.Descriptor{
        .usage = .{ .render_attachment = true },
        .size = .{ .width = core.descriptor.width, .height = core.descriptor.height },
        .format = .depth24_plus,
    });

    depth_texture_view = depth_texture.createView(&gpu.TextureView.Descriptor{
        .format = .depth24_plus,
        .dimension = .dimension_2d,
        .array_layer_count = 1,
        .mip_level_count = 1,
    });
}

fn createPipeline(shader_module: *gpu.ShaderModule, bind_group_layout: *gpu.BindGroupLayout) *gpu.RenderPipeline {
    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x3, .shader_location = 0, .offset = 0 },
        .{ .format = .float32x3, .shader_location = 1, .offset = @sizeOf(primitives.F32x3) },
    };

    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(VertexData),
        .step_mode = .vertex,
        .attributes = &vertex_attributes,
    });

    const vertex_pipeline_state = gpu.VertexState.init(.{ .module = shader_module, .entry_point = "vertex_main", .buffers = &.{vertex_buffer_layout} });

    const primitive_pipeline_state = gpu.PrimitiveState{
        .topology = .triangle_list,
        .front_face = .ccw,
        .cull_mode = .back,
    };

    // Fragment Pipeline State
    const blend = gpu.BlendState{
        .color = gpu.BlendComponent{ .operation = .add, .src_factor = .src_alpha, .dst_factor = .one_minus_src_alpha },
        .alpha = gpu.BlendComponent{ .operation = .add, .src_factor = .zero, .dst_factor = .one },
    };
    const color_target = gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment_pipeline_state = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    const depth_stencil_state = gpu.DepthStencilState{
        .format = .depth24_plus,
        .depth_write_enabled = .true,
        .depth_compare = .less,
    };

    const multi_sample_state = gpu.MultisampleState{
        .count = 1,
        .mask = 0xFFFFFFFF,
        .alpha_to_coverage_enabled = .false,
    };

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    // Pipeline Layout
    const pipeline_layout_descriptor = gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    });
    const pipeline_layout = core.device.createPipelineLayout(&pipeline_layout_descriptor);
    defer pipeline_layout.release();

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = "Main Pipeline",
        .layout = pipeline_layout,
        .vertex = vertex_pipeline_state,
        .primitive = primitive_pipeline_state,
        .depth_stencil = &depth_stencil_state,
        .multisample = multi_sample_state,
        .fragment = &fragment_pipeline_state,
    };

    return core.device.createRenderPipeline(&pipeline_descriptor);
}

pub const F32x1 = @Vector(1, f32);

pub fn update() void {
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = gpu.Color{ .r = 0.2, .g = 0.2, .b = 0.2, .a = 1.0 },
        .load_op = .clear,
        .store_op = .store,
    };

    const depth_stencil_attachment = gpu.RenderPassDepthStencilAttachment{
        .view = depth_texture_view,
        .depth_load_op = .clear,
        .depth_store_op = .store,
        .depth_clear_value = 1.0,
    };

    const encoder = core.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = &depth_stencil_attachment,
    });

    if (curr_primitive_index >= 4) {
        const time = app_timer.read() / 5;
        const model = zm.mul(zm.rotationX(time * (std.math.pi / 2.0)), zm.rotationZ(time * (std.math.pi / 2.0)));
        const view = zm.lookAtRh(
            zm.Vec{ 0, 4, 2, 1 },
            zm.Vec{ 0, 0, 0, 1 },
            zm.Vec{ 0, 0, 1, 0 },
        );
        const proj = zm.perspectiveFovRh(
            (std.math.pi / 4.0),
            @as(f32, @floatFromInt(core.descriptor.width)) / @as(f32, @floatFromInt(core.descriptor.height)),
            0.1,
            10,
        );

        const mvp = zm.mul(zm.mul(model, view), proj);

        const ubo = UniformBufferObject{
            .mvp_matrix = zm.transpose(mvp),
        };
        encoder.writeBuffer(uniform_buffer, 0, &[_]UniformBufferObject{ubo});
    } else {
        const ubo = UniformBufferObject{
            .mvp_matrix = zm.identity(),
        };
        encoder.writeBuffer(uniform_buffer, 0, &[_]UniformBufferObject{ubo});
    }

    const pass = encoder.beginRenderPass(&render_pass_info);

    pass.setPipeline(pipeline);

    const vertex_buffer = primitives_data[curr_primitive_index].vertex_buffer;
    const vertex_count = primitives_data[curr_primitive_index].vertex_count;
    pass.setVertexBuffer(0, vertex_buffer, 0, @sizeOf(VertexData) * vertex_count);

    pass.setBindGroup(0, bind_group, &.{0});

    const index_buffer = primitives_data[curr_primitive_index].index_buffer;
    const index_count = primitives_data[curr_primitive_index].index_count;
    pass.setIndexBuffer(index_buffer, .uint32, 0, @sizeOf(u32) * index_count);
    pass.drawIndexed(index_count, 1, 0, 0, 0);

    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    core.swap_chain.present();
    back_buffer_view.release();
}

pub fn deinit() void {
    var i: u4 = 0;
    while (i < 7) : (i += 1) {
        primitives_data[i].vertex_buffer.release();
        primitives_data[i].index_buffer.release();
    }

    bind_group.release();
    uniform_buffer.release();
    depth_texture.release();
    depth_texture_view.release();
    pipeline.release();
}
