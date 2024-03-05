const std = @import("std");
const core = @import("mach").core;
const gpu = core.gpu;
const m3d = @import("model3d");
const zm = @import("zmath");
const assets = @import("assets");
const VertexWriter = @import("vertex_writer.zig").VertexWriter;

pub const App = @This();

const Vec4 = [4]f32;
const Vec3 = [3]f32;
const Vec2 = [2]f32;
const Mat4 = [4]Vec4;

fn Dimensions2D(comptime T: type) type {
    return struct {
        width: T,
        height: T,
    };
}

const Vertex = extern struct {
    position: Vec3,
    normal: Vec3,
};

const Model = struct {
    vertex_count: u32,
    index_count: u32,
    vertex_buffer: *gpu.Buffer,
    index_buffer: *gpu.Buffer,
};

const Material = struct {
    const Params = extern struct {
        roughness: f32,
        metallic: f32,
        color: Vec3,
    };

    name: []const u8,
    params: Params,
};

const PressedKeys = packed struct(u16) {
    right: bool = false,
    left: bool = false,
    up: bool = false,
    down: bool = false,
    padding: u12 = undefined,

    pub inline fn areKeysPressed(self: @This()) bool {
        return (self.up or self.down or self.left or self.right);
    }

    pub inline fn clear(self: *@This()) void {
        self.right = false;
        self.left = false;
        self.up = false;
        self.down = false;
    }
};

const Camera = struct {
    const Matrices = struct {
        perspective: Mat4 = [1]Vec4{[1]f32{0.0} ** 4} ** 4,
        view: Mat4 = [1]Vec4{[1]f32{0.0} ** 4} ** 4,
    };

    rotation: Vec3 = .{ 0.0, 0.0, 0.0 },
    position: Vec3 = .{ 0.0, 0.0, 0.0 },
    view_position: Vec4 = .{ 0.0, 0.0, 0.0, 0.0 },
    fov: f32 = 0.0,
    znear: f32 = 0.0,
    zfar: f32 = 0.0,
    rotation_speed: f32 = 0.0,
    movement_speed: f32 = 0.0,
    updated: bool = false,
    matrices: Matrices = .{},

    pub fn calculateMovement(self: *@This(), pressed_keys: PressedKeys) void {
        std.debug.assert(pressed_keys.areKeysPressed());
        const rotation_radians = Vec3{
            toRadians(self.rotation[0]),
            toRadians(self.rotation[1]),
            toRadians(self.rotation[2]),
        };
        var camera_front = zm.Vec{ -zm.cos(rotation_radians[0]) * zm.sin(rotation_radians[1]), zm.sin(rotation_radians[0]), zm.cos(rotation_radians[0]) * zm.cos(rotation_radians[1]), 0 };
        camera_front = zm.normalize3(camera_front);
        if (pressed_keys.up) {
            camera_front[0] *= self.movement_speed;
            camera_front[1] *= self.movement_speed;
            camera_front[2] *= self.movement_speed;
            self.position = Vec3{
                self.position[0] + camera_front[0],
                self.position[1] + camera_front[1],
                self.position[2] + camera_front[2],
            };
        }
        if (pressed_keys.down) {
            camera_front[0] *= self.movement_speed;
            camera_front[1] *= self.movement_speed;
            camera_front[2] *= self.movement_speed;
            self.position = Vec3{
                self.position[0] - camera_front[0],
                self.position[1] - camera_front[1],
                self.position[2] - camera_front[2],
            };
        }
        if (pressed_keys.right) {
            camera_front = zm.cross3(.{ 0.0, 1.0, 0.0, 0.0 }, camera_front);
            camera_front = zm.normalize3(camera_front);
            camera_front[0] *= self.movement_speed;
            camera_front[1] *= self.movement_speed;
            camera_front[2] *= self.movement_speed;
            self.position = Vec3{
                self.position[0] - camera_front[0],
                self.position[1] - camera_front[1],
                self.position[2] - camera_front[2],
            };
        }
        if (pressed_keys.left) {
            camera_front = zm.cross3(.{ 0.0, 1.0, 0.0, 0.0 }, camera_front);
            camera_front = zm.normalize3(camera_front);
            camera_front[0] *= self.movement_speed;
            camera_front[1] *= self.movement_speed;
            camera_front[2] *= self.movement_speed;
            self.position = Vec3{
                self.position[0] + camera_front[0],
                self.position[1] + camera_front[1],
                self.position[2] + camera_front[2],
            };
        }
        self.updateViewMatrix();
    }

    fn updateViewMatrix(self: *@This()) void {
        const rotation_x = zm.rotationX(toRadians(self.rotation[2]));
        const rotation_y = zm.rotationY(toRadians(self.rotation[1]));
        const rotation_z = zm.rotationZ(toRadians(self.rotation[0]));
        const rotation_matrix = zm.mul(rotation_z, zm.mul(rotation_x, rotation_y));

        const translation_matrix: zm.Mat = zm.translationV(.{
            self.position[0],
            self.position[1],
            self.position[2],
            0,
        });
        const view = zm.mul(translation_matrix, rotation_matrix);
        self.matrices.view[0] = view[0];
        self.matrices.view[1] = view[1];
        self.matrices.view[2] = view[2];
        self.matrices.view[3] = view[3];
        self.view_position = .{
            -self.position[0],
            self.position[1],
            -self.position[2],
            0.0,
        };
        self.updated = true;
    }

    pub fn setMovementSpeed(self: *@This(), speed: f32) void {
        self.movement_speed = speed;
    }

    pub fn setPerspective(self: *@This(), fov: f32, aspect: f32, znear: f32, zfar: f32) void {
        self.fov = fov;
        self.znear = znear;
        self.zfar = zfar;
        const perspective = zm.perspectiveFovRhGl(toRadians(fov), aspect, znear, zfar);
        self.matrices.perspective[0] = perspective[0];
        self.matrices.perspective[1] = perspective[1];
        self.matrices.perspective[2] = perspective[2];
        self.matrices.perspective[3] = perspective[3];
    }

    pub fn setRotationSpeed(self: *@This(), speed: f32) void {
        self.rotation_speed = speed;
    }

    pub fn setRotation(self: *@This(), rotation: Vec3) void {
        self.rotation = rotation;
        self.updateViewMatrix();
    }

    pub fn rotate(self: *@This(), delta: Vec2) void {
        self.rotation[0] -= delta[1];
        self.rotation[1] -= delta[0];
        self.updateViewMatrix();
    }

    pub fn setPosition(self: *@This(), position: Vec3) void {
        self.position = .{
            position[0],
            -position[1],
            position[2],
        };
        self.updateViewMatrix();
    }
};

const UniformBuffers = struct {
    const Params = struct {
        buffer: *gpu.Buffer,
        buffer_size: u64,
        model_size: u64,
    };
    const Buffer = struct {
        buffer: *gpu.Buffer,
        size: u32,
    };
    ubo_matrices: Buffer,
    ubo_params: Buffer,
    material_params: Params,
    object_params: Params,
};

const UboParams = struct {
    lights: [4]Vec4,
};

const UboMatrices = extern struct {
    projection: Mat4,
    model: Mat4,
    view: Mat4,
    camera_position: Vec3,
};

const grid_element_count = grid_dimensions * grid_dimensions;

const MaterialParamsDynamic = extern struct {
    roughness: f32 = 0,
    metallic: f32 = 0,
    color: Vec3 = .{ 0, 0, 0 },
    padding: [236]u8 = [1]u8{0} ** 236,
};
const MaterialParamsDynamicGrid = [grid_element_count]MaterialParamsDynamic;

const ObjectParamsDynamic = extern struct {
    position: Vec3 = .{ 0, 0, 0 },
    padding: [244]u8 = [1]u8{0} ** 244,
};
const ObjectParamsDynamicGrid = [grid_element_count]ObjectParamsDynamic;

//
// Globals
//

const material_names = [11][:0]const u8{
    "Gold",  "Copper", "Chromium", "Nickel", "Titanium", "Cobalt", "Platinum",
    // Testing materials
    "White", "Red",    "Blue",     "Black",
};

const object_names = [5][:0]const u8{ "Sphere", "Teapot", "Torusknot", "Venus", "Stanford Dragon" };

const materials = [_]Material{
    .{ .name = "Gold", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 1.0, 0.765557, 0.336057 } } },
    .{ .name = "Copper", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 0.955008, 0.637427, 0.538163 } } },
    .{ .name = "Chromium", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 0.549585, 0.556114, 0.554256 } } },
    .{ .name = "Nickel", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 1.0, 0.608679, 0.525649 } } },
    .{ .name = "Titanium", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 0.541931, 0.496791, 0.449419 } } },
    .{ .name = "Cobalt", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 0.662124, 0.654864, 0.633732 } } },
    .{ .name = "Platinum", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 0.672411, 0.637331, 0.585456 } } },
    // Testing colors
    .{ .name = "White", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 1.0, 1.0, 1.0 } } },
    .{ .name = "Red", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 1.0, 0.0, 0.0 } } },
    .{ .name = "Blue", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 0.0, 0.0, 1.0 } } },
    .{ .name = "Black", .params = .{ .roughness = 0.1, .metallic = 1.0, .color = .{ 0.0, 0.0, 0.0 } } },
};

const grid_dimensions = 7;
const model_embeds = [_][:0]const u8{
    assets.sphere_m3d,
    assets.teapot_m3d,
    assets.torusknot_m3d,
    assets.venus_m3d,
    assets.stanford_dragon_m3d,
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

//
// Member variables
//

title_timer: core.Timer,
timer: core.Timer,
camera: Camera,
render_pipeline: *gpu.RenderPipeline,
render_pass_descriptor: gpu.RenderPassDescriptor,
bind_group: *gpu.BindGroup,
color_attachment: gpu.RenderPassColorAttachment,
depth_stencil_attachment_description: gpu.RenderPassDepthStencilAttachment,
depth_texture: *gpu.Texture,
depth_texture_view: *gpu.TextureView,
pressed_keys: PressedKeys,
models: [5]Model,
ubo_params: UboParams,
ubo_matrices: UboMatrices,
uniform_buffers: UniformBuffers,
material_params_dynamic: MaterialParamsDynamicGrid = [1]MaterialParamsDynamic{.{}} ** grid_element_count,
object_params_dynamic: ObjectParamsDynamicGrid = [1]ObjectParamsDynamic{.{}} ** grid_element_count,
uniform_buffers_dirty: bool,
buffers_bound: bool,
is_paused: bool,
current_material_index: usize,
current_object_index: usize,
mouse_position: core.Position,
is_rotating: bool,

//
// Functions
//

pub fn init(app: *App) !void {
    try core.init(.{});
    app.timer = try core.Timer.start();
    app.title_timer = try core.Timer.start();

    app.pressed_keys = .{};
    app.buffers_bound = false;
    app.is_paused = false;
    app.uniform_buffers_dirty = false;
    app.current_material_index = 0;
    app.current_object_index = 0;
    app.mouse_position = .{ .x = 0, .y = 0 };
    app.is_rotating = false;

    setupCamera(app);
    try loadModels(std.heap.c_allocator, app);
    prepareUniformBuffers(app);
    setupPipeline(app);
    setupRenderPass(app);
    app.printControls();
}

pub fn deinit(app: *App) void {
    defer _ = gpa.deinit();
    defer core.deinit();

    app.bind_group.release();
    app.render_pipeline.release();
    app.depth_texture_view.release();
    app.depth_texture.release();
    app.uniform_buffers.ubo_matrices.buffer.release();
    app.uniform_buffers.ubo_params.buffer.release();
    app.uniform_buffers.material_params.buffer.release();
    app.uniform_buffers.object_params.buffer.release();
}

pub fn update(app: *App) !bool {
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        app.updateUI(event);
        switch (event) {
            .mouse_motion => |ev| {
                if (app.is_rotating) {
                    const delta = Vec2{
                        @as(f32, @floatCast((app.mouse_position.x - ev.pos.x) * app.camera.rotation_speed)),
                        @as(f32, @floatCast((app.mouse_position.y - ev.pos.y) * app.camera.rotation_speed)),
                    };
                    app.mouse_position = ev.pos;
                    app.camera.rotate(delta);
                    app.uniform_buffers_dirty = true;
                }
            },
            .mouse_press => |ev| {
                if (ev.button == .left) {
                    app.is_rotating = true;
                    app.mouse_position = ev.pos;
                }
            },
            .mouse_release => |ev| {
                if (ev.button == .left) {
                    app.is_rotating = false;
                }
            },
            .key_press, .key_repeat => |ev| {
                const key = ev.key;
                if (key == .up or key == .w) app.pressed_keys.up = true;
                if (key == .down or key == .s) app.pressed_keys.down = true;
                if (key == .left or key == .a) app.pressed_keys.left = true;
                if (key == .right or key == .d) app.pressed_keys.right = true;
            },
            .framebuffer_resize => |ev| {
                app.depth_texture_view.release();
                app.depth_texture.release();
                app.depth_texture = core.device.createTexture(&gpu.Texture.Descriptor{
                    .usage = .{ .render_attachment = true },
                    .format = .depth24_plus_stencil8,
                    .sample_count = 1,
                    .size = .{
                        .width = ev.width,
                        .height = ev.height,
                        .depth_or_array_layers = 1,
                    },
                });
                app.depth_texture_view = app.depth_texture.createView(&gpu.TextureView.Descriptor{
                    .format = .depth24_plus_stencil8,
                    .dimension = .dimension_2d,
                    .array_layer_count = 1,
                    .aspect = .all,
                });
                app.depth_stencil_attachment_description = gpu.RenderPassDepthStencilAttachment{
                    .view = app.depth_texture_view,
                    .depth_load_op = .clear,
                    .depth_store_op = .store,
                    .depth_clear_value = 1.0,
                    .stencil_clear_value = 0,
                    .stencil_load_op = .clear,
                    .stencil_store_op = .store,
                };

                const aspect_ratio = @as(f32, @floatFromInt(ev.width)) / @as(f32, @floatFromInt(ev.height));
                app.camera.setPerspective(60.0, aspect_ratio, 0.1, 256.0);
                app.uniform_buffers_dirty = true;
            },
            .close => return true,
            else => {},
        }
    }
    if (app.pressed_keys.areKeysPressed()) {
        app.camera.calculateMovement(app.pressed_keys);
        app.pressed_keys.clear();
        app.uniform_buffers_dirty = true;
    }

    if (app.uniform_buffers_dirty) {
        updateUniformBuffers(app);
        app.uniform_buffers_dirty = false;
    }

    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    app.color_attachment.view = back_buffer_view;
    app.render_pass_descriptor = gpu.RenderPassDescriptor{
        .color_attachment_count = 1,
        .color_attachments = &[_]gpu.RenderPassColorAttachment{app.color_attachment},
        .depth_stencil_attachment = &app.depth_stencil_attachment_description,
    };
    const encoder = core.device.createCommandEncoder(null);
    const current_model = app.models[app.current_object_index];

    const pass = encoder.beginRenderPass(&app.render_pass_descriptor);

    const dimensions = Dimensions2D(f32){
        .width = @as(f32, @floatFromInt(core.descriptor.width)),
        .height = @as(f32, @floatFromInt(core.descriptor.height)),
    };
    pass.setViewport(
        0,
        0,
        dimensions.width,
        dimensions.height,
        0.0,
        1.0,
    );
    pass.setScissorRect(0, 0, core.descriptor.width, core.descriptor.height);
    pass.setPipeline(app.render_pipeline);

    if (!app.is_paused) {
        app.updateLights();
    }

    var i: usize = 0;
    while (i < (grid_dimensions * grid_dimensions)) : (i += 1) {
        const alignment = 256;
        const dynamic_offset: u32 = @as(u32, @intCast(i)) * alignment;
        const dynamic_offsets = [2]u32{ dynamic_offset, dynamic_offset };
        pass.setBindGroup(0, app.bind_group, &dynamic_offsets);
        if (!app.buffers_bound) {
            pass.setVertexBuffer(0, current_model.vertex_buffer, 0, @sizeOf(Vertex) * current_model.vertex_count);
            pass.setIndexBuffer(current_model.index_buffer, .uint32, 0, gpu.whole_size);
            app.buffers_bound = true;
        }
        pass.drawIndexed(
            current_model.index_count, // index_count
            1, // instance_count
            0, // first_index
            0, // base_vertex
            0, // first_instance
        );
    }

    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    const queue = core.queue;
    queue.submit(&[_]*gpu.CommandBuffer{command});

    command.release();
    core.swap_chain.present();
    back_buffer_view.release();
    app.buffers_bound = false;

    // update the window title every second
    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        try core.printTitle("PBR Basic [ {d}fps ] [ Input {d}hz ]", .{
            core.frameRate(),
            core.inputRate(),
        });
    }

    return false;
}

fn prepareUniformBuffers(app: *App) void {
    comptime {
        std.debug.assert(@sizeOf(ObjectParamsDynamic) == 256);
        std.debug.assert(@sizeOf(MaterialParamsDynamic) == 256);
    }

    app.uniform_buffers.ubo_matrices.size = roundToMultipleOf4(u32, @as(u32, @intCast(@sizeOf(UboMatrices)))) + 4;
    app.uniform_buffers.ubo_matrices.buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = app.uniform_buffers.ubo_matrices.size,
        .mapped_at_creation = .false,
    });

    app.uniform_buffers.ubo_params.size = roundToMultipleOf4(u32, @as(u32, @intCast(@sizeOf(UboParams)))) + 4;
    app.uniform_buffers.ubo_params.buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = app.uniform_buffers.ubo_params.size,
        .mapped_at_creation = .false,
    });

    //
    // Material parameter uniform buffer
    //
    app.uniform_buffers.material_params.model_size = @sizeOf(Vec2) + @sizeOf(Vec3);
    app.uniform_buffers.material_params.buffer_size = calculateConstantBufferByteSize(@sizeOf(MaterialParamsDynamicGrid));
    std.debug.assert(app.uniform_buffers.material_params.buffer_size >= app.uniform_buffers.material_params.model_size);
    app.uniform_buffers.material_params.buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = app.uniform_buffers.material_params.buffer_size,
        .mapped_at_creation = .false,
    });

    //
    // Object parameter uniform buffer
    //
    app.uniform_buffers.object_params.model_size = @sizeOf(Vec3) + 4;
    app.uniform_buffers.object_params.buffer_size = calculateConstantBufferByteSize(@sizeOf(MaterialParamsDynamicGrid)) + 4;
    std.debug.assert(app.uniform_buffers.object_params.buffer_size >= app.uniform_buffers.object_params.model_size);
    app.uniform_buffers.object_params.buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = app.uniform_buffers.object_params.buffer_size,
        .mapped_at_creation = .false,
    });

    app.updateUniformBuffers();
    app.updateDynamicUniformBuffer();
    app.updateLights();
}

fn updateDynamicUniformBuffer(app: *App) void {
    var index: u32 = 0;
    var y: usize = 0;
    while (y < grid_dimensions) : (y += 1) {
        var x: usize = 0;
        while (x < grid_dimensions) : (x += 1) {
            const grid_dimensions_float = @as(f32, @floatFromInt(grid_dimensions));
            app.object_params_dynamic[index].position[0] = (@as(f32, @floatFromInt(x)) - (grid_dimensions_float / 2) * 2.5);
            app.object_params_dynamic[index].position[1] = 0;
            app.object_params_dynamic[index].position[2] = (@as(f32, @floatFromInt(y)) - (grid_dimensions_float / 2) * 2.5);
            app.material_params_dynamic[index].metallic = zm.clamp(@as(f32, @floatFromInt(x)) / (grid_dimensions_float - 1), 0.1, 1.0);
            app.material_params_dynamic[index].roughness = zm.clamp(@as(f32, @floatFromInt(y)) / (grid_dimensions_float - 1), 0.05, 1.0);
            app.material_params_dynamic[index].color = materials[app.current_material_index].params.color;
            index += 1;
        }
    }
    const queue = core.queue;
    queue.writeBuffer(
        app.uniform_buffers.object_params.buffer,
        0,
        &app.object_params_dynamic,
    );
    queue.writeBuffer(
        app.uniform_buffers.material_params.buffer,
        0,
        &app.material_params_dynamic,
    );
}

fn updateUniformBuffers(app: *App) void {
    app.ubo_matrices.projection = app.camera.matrices.perspective;
    app.ubo_matrices.view = app.camera.matrices.view;
    const rotation_degrees = if (app.current_object_index == 1) @as(f32, -45.0) else @as(f32, -90.0);
    const model = zm.rotationY(rotation_degrees);
    app.ubo_matrices.model[0] = model[0];
    app.ubo_matrices.model[1] = model[1];
    app.ubo_matrices.model[2] = model[2];
    app.ubo_matrices.model[3] = model[3];
    app.ubo_matrices.camera_position = .{
        -app.camera.position[0],
        -app.camera.position[1],
        -app.camera.position[2],
    };
    const queue = core.queue;
    queue.writeBuffer(app.uniform_buffers.ubo_matrices.buffer, 0, &[_]UboMatrices{app.ubo_matrices});
}

fn updateLights(app: *App) void {
    const p: f32 = 15.0;
    app.ubo_params.lights[0] = Vec4{ -p, -p * 0.5, -p, 1.0 };
    app.ubo_params.lights[1] = Vec4{ -p, -p * 0.5, p, 1.0 };
    app.ubo_params.lights[2] = Vec4{ p, -p * 0.5, p, 1.0 };
    app.ubo_params.lights[3] = Vec4{ p, -p * 0.5, -p, 1.0 };
    const base_value = toRadians(@mod(app.timer.read() * 0.1, 1.0) * 360.0);
    app.ubo_params.lights[0][0] = @sin(base_value) * 20.0;
    app.ubo_params.lights[0][2] = @cos(base_value) * 20.0;
    app.ubo_params.lights[1][0] = @cos(base_value) * 20.0;
    app.ubo_params.lights[1][1] = @sin(base_value) * 20.0;
    const queue = core.queue;
    queue.writeBuffer(
        app.uniform_buffers.ubo_params.buffer,
        0,
        &[_]UboParams{app.ubo_params},
    );
}

fn setupPipeline(app: *App) void {
    comptime {
        std.debug.assert(@sizeOf(Vertex) == @sizeOf(f32) * 6);
    }

    const bind_group_layout_entries = [_]gpu.BindGroupLayout.Entry{
        .{
            .binding = 0,
            .visibility = .{ .vertex = true, .fragment = true },
            .buffer = .{
                .type = .uniform,
                .has_dynamic_offset = .false,
                .min_binding_size = app.uniform_buffers.ubo_matrices.size,
            },
        },
        .{
            .binding = 1,
            .visibility = .{ .fragment = true },
            .buffer = .{
                .type = .uniform,
                .has_dynamic_offset = .false,
                .min_binding_size = app.uniform_buffers.ubo_params.size,
            },
        },
        .{
            .binding = 2,
            .visibility = .{ .fragment = true },
            .buffer = .{
                .type = .uniform,
                .has_dynamic_offset = .true,
                .min_binding_size = app.uniform_buffers.material_params.model_size,
            },
        },
        .{
            .binding = 3,
            .visibility = .{ .vertex = true },
            .buffer = .{
                .type = .uniform,
                .has_dynamic_offset = .true,
                .min_binding_size = app.uniform_buffers.object_params.model_size,
            },
        },
    };

    const bind_group_layout = core.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = bind_group_layout_entries[0..],
        }),
    );

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = core.device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    }));

    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(Vertex),
        .step_mode = .vertex,
        .attributes = &.{
            .{ .format = .float32x3, .offset = @offsetOf(Vertex, "position"), .shader_location = 0 },
            .{ .format = .float32x3, .offset = @offsetOf(Vertex, "normal"), .shader_location = 1 },
        },
    });

    const blend_component_descriptor = gpu.BlendComponent{
        .operation = .add,
        .src_factor = .one,
        .dst_factor = .zero,
    };

    const color_target_state = gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &.{
            .color = blend_component_descriptor,
            .alpha = blend_component_descriptor,
        },
    };

    const shader_module = core.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .layout = pipeline_layout,
        .primitive = .{
            .cull_mode = .back,
        },
        .depth_stencil = &.{
            .format = .depth24_plus_stencil8,
            .depth_write_enabled = .true,
            .depth_compare = .less,
        },
        .fragment = &gpu.FragmentState.init(.{
            .module = shader_module,
            .entry_point = "frag_main",
            .targets = &.{color_target_state},
        }),
        .vertex = gpu.VertexState.init(.{
            .module = shader_module,
            .entry_point = "vertex_main",
            .buffers = &.{vertex_buffer_layout},
        }),
    };
    app.render_pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
    shader_module.release();

    {
        const bind_group_entries = [_]gpu.BindGroup.Entry{
            .{
                .binding = 0,
                .buffer = app.uniform_buffers.ubo_matrices.buffer,
                .size = app.uniform_buffers.ubo_matrices.size,
            },
            .{
                .binding = 1,
                .buffer = app.uniform_buffers.ubo_params.buffer,
                .size = app.uniform_buffers.ubo_params.size,
            },
            .{
                .binding = 2,
                .buffer = app.uniform_buffers.material_params.buffer,
                .size = app.uniform_buffers.material_params.model_size,
            },
            .{
                .binding = 3,
                .buffer = app.uniform_buffers.object_params.buffer,
                .size = app.uniform_buffers.object_params.model_size,
            },
        };
        app.bind_group = core.device.createBindGroup(
            &gpu.BindGroup.Descriptor.init(.{
                .layout = bind_group_layout,
                .entries = &bind_group_entries,
            }),
        );
    }
}

fn setupRenderPass(app: *App) void {
    app.color_attachment = gpu.RenderPassColorAttachment{
        .clear_value = .{
            .r = 0.0,
            .g = 0.0,
            .b = 0.0,
            .a = 0.0,
        },
        .load_op = .clear,
        .store_op = .store,
    };

    app.depth_texture = core.device.createTexture(&.{
        .usage = .{ .render_attachment = true, .copy_src = true },
        .format = .depth24_plus_stencil8,
        .sample_count = 1,
        .size = .{
            .width = core.descriptor.width,
            .height = core.descriptor.height,
            .depth_or_array_layers = 1,
        },
    });

    app.depth_texture_view = app.depth_texture.createView(&.{
        .format = .depth24_plus_stencil8,
        .dimension = .dimension_2d,
        .array_layer_count = 1,
        .aspect = .all,
    });

    app.depth_stencil_attachment_description = gpu.RenderPassDepthStencilAttachment{
        .view = app.depth_texture_view,
        .depth_load_op = .clear,
        .depth_store_op = .store,
        .depth_clear_value = 1.0,
        .stencil_clear_value = 0,
        .stencil_load_op = .clear,
        .stencil_store_op = .store,
    };
}

fn loadModels(allocator: std.mem.Allocator, app: *App) !void {
    for (model_embeds, 0..) |model_data, model_data_i| {
        const m3d_model = m3d.load(model_data, null, null, null) orelse return error.LoadModelFailed;

        const vertex_count = m3d_model.handle.numvertex;
        const face_count = m3d_model.handle.numface;

        var model: *Model = &app.models[model_data_i];

        model.index_count = face_count * 3;

        var vertex_writer = try VertexWriter(Vertex, u32).init(allocator, face_count * 3, vertex_count, face_count * 3);
        defer vertex_writer.deinit(allocator);

        const scale: f32 = 0.45;
        const vertices = m3d_model.handle.vertex[0..vertex_count];
        var i: usize = 0;
        while (i < face_count) : (i += 1) {
            const face = m3d_model.handle.face[i];
            var x: usize = 0;
            while (x < 3) : (x += 1) {
                const vertex_index = face.vertex[x];
                const normal_index = face.normal[x];
                const vertex = Vertex{
                    .position = .{
                        vertices[vertex_index].x * scale,
                        vertices[vertex_index].y * scale,
                        vertices[vertex_index].z * scale,
                    },
                    .normal = .{
                        vertices[normal_index].x,
                        vertices[normal_index].y,
                        vertices[normal_index].z,
                    },
                };
                vertex_writer.put(vertex, vertex_index);
            }
        }

        const vertex_buffer = vertex_writer.vertexBuffer();
        const index_buffer = vertex_writer.indexBuffer();

        model.vertex_count = @as(u32, @intCast(vertex_buffer.len));

        model.vertex_buffer = core.device.createBuffer(&.{
            .usage = .{ .copy_dst = true, .vertex = true },
            .size = @sizeOf(Vertex) * model.vertex_count,
            .mapped_at_creation = .false,
        });
        const queue = core.queue;
        queue.writeBuffer(model.vertex_buffer, 0, vertex_buffer);

        model.index_buffer = core.device.createBuffer(&.{
            .usage = .{ .copy_dst = true, .index = true },
            .size = @sizeOf(u32) * model.index_count,
            .mapped_at_creation = .false,
        });
        queue.writeBuffer(model.index_buffer, 0, index_buffer);
    }
}

fn printControls(app: *App) void {
    std.debug.print("[controls]\n", .{});
    std.debug.print("[p] paused: {}\n", .{app.is_paused});
    std.debug.print("[m] material: {s}\n", .{material_names[app.current_material_index]});
    std.debug.print("[o] object: {s}\n", .{object_names[app.current_object_index]});
}

fn updateUI(app: *App, event: core.Event) void {
    switch (event) {
        .key_press => |ev| {
            var update_uniform_buffers: bool = false;
            switch (ev.key) {
                .p => app.is_paused = !app.is_paused,
                .m => {
                    app.current_material_index = (app.current_material_index + 1) % material_names.len;
                    update_uniform_buffers = true;
                },
                .o => {
                    app.current_object_index = (app.current_object_index + 1) % object_names.len;
                    update_uniform_buffers = true;
                },
                else => return,
            }
            app.printControls();
            if (update_uniform_buffers) {
                updateDynamicUniformBuffer(app);
            }
        },
        else => {},
    }
}

fn setupCamera(app: *App) void {
    app.camera = Camera{
        .rotation_speed = 1.0,
        .movement_speed = 1.0,
    };
    const aspect_ratio: f32 = @as(f32, @floatFromInt(core.descriptor.width)) / @as(f32, @floatFromInt(core.descriptor.height));
    app.camera.setPosition(.{ 10.0, 6.0, 6.0 });
    app.camera.setRotation(.{ 62.5, 90.0, 0.0 });
    app.camera.setMovementSpeed(0.5);
    app.camera.setPerspective(60.0, aspect_ratio, 0.1, 256.0);
    app.camera.setRotationSpeed(0.25);
}

inline fn roundToMultipleOf4(comptime T: type, value: T) T {
    return (value + 3) & ~@as(T, 3);
}

inline fn calculateConstantBufferByteSize(byte_size: usize) usize {
    return (byte_size + 255) & ~@as(usize, 255);
}

inline fn toRadians(degrees: f32) f32 {
    return degrees * (std.math.pi / 180.0);
}
