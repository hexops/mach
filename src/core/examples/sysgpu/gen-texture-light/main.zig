// in this example:
//   - comptime generated image data for texture
//   - Blinn-Phong lighting
//   - several pipelines
//
// quit with escape, q or space
// move camera with arrows or wasd

const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;

const zm = @import("zmath");
const Vec = zm.Vec;
const Mat = zm.Mat;
const Quat = zm.Quat;

pub const App = @This();

// Use experimental sysgpu graphics API
pub const use_sysgpu = true;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

title_timer: core.Timer,
timer: core.Timer,
cube: Cube,
camera: Camera,
light: Light,
depth: Texture,
keys: u8,

const Dir = struct {
    const up: u8 = 0b0001;
    const down: u8 = 0b0010;
    const left: u8 = 0b0100;
    const right: u8 = 0b1000;
};

pub fn init(app: *App) !void {
    try core.init(.{});

    app.title_timer = try core.Timer.start();
    app.timer = try core.Timer.start();

    const eye = Vec{ 5.0, 7.0, 5.0, 0.0 };
    const target = Vec{ 0.0, 0.0, 0.0, 0.0 };

    const framebuffer = core.descriptor;
    const aspect_ratio = @as(f32, @floatFromInt(framebuffer.width)) / @as(f32, @floatFromInt(framebuffer.height));

    app.cube = Cube.init();
    app.light = Light.init();
    app.depth = Texture.depth(core.device, framebuffer.width, framebuffer.height);
    app.camera = Camera.init(core.device, eye, target, zm.Vec{ 0.0, 1.0, 0.0, 0.0 }, aspect_ratio, 45.0, 0.1, 100.0);
    app.keys = 0;
}

pub fn deinit(app: *App) void {
    defer _ = gpa.deinit();
    defer core.deinit();

    app.cube.deinit();
    app.camera.deinit();
    app.light.deinit();
    app.depth.release();
}

pub fn update(app: *App) !bool {
    const delta_time = app.timer.lap();

    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| switch (ev.key) {
                .q, .escape, .space => return true,
                .w, .up => {
                    app.keys |= Dir.up;
                },
                .s, .down => {
                    app.keys |= Dir.down;
                },
                .a, .left => {
                    app.keys |= Dir.left;
                },
                .d, .right => {
                    app.keys |= Dir.right;
                },
                .one => core.setDisplayMode(.windowed),
                .two => core.setDisplayMode(.fullscreen),
                .three => core.setDisplayMode(.borderless),
                else => {},
            },
            .key_release => |ev| switch (ev.key) {
                .w, .up => {
                    app.keys &= ~Dir.up;
                },
                .s, .down => {
                    app.keys &= ~Dir.down;
                },
                .a, .left => {
                    app.keys &= ~Dir.left;
                },
                .d, .right => {
                    app.keys &= ~Dir.right;
                },
                else => {},
            },
            .framebuffer_resize => |ev| {
                // recreates the sampler, which is a waste, but for an example it's ok
                app.depth.release();
                app.depth = Texture.depth(core.device, ev.width, ev.height);
            },
            .close => return true,
            else => {},
        }
    }

    // move camera
    const speed = zm.Vec{ delta_time * 5, delta_time * 5, delta_time * 5, delta_time * 5 };
    const fwd = zm.normalize3(app.camera.target - app.camera.eye);
    const right = zm.normalize3(zm.cross3(fwd, app.camera.up));

    if (app.keys & Dir.up != 0)
        app.camera.eye += fwd * speed;

    if (app.keys & Dir.down != 0)
        app.camera.eye -= fwd * speed;

    if (app.keys & Dir.right != 0)
        app.camera.eye += right * speed
    else if (app.keys & Dir.left != 0)
        app.camera.eye -= right * speed
    else
        app.camera.eye += right * (speed * @Vector(4, f32){ 0.5, 0.5, 0.5, 0.5 });

    const queue = core.queue;
    app.camera.update(queue);

    // move light
    const light_speed = delta_time * 2.5;
    app.light.update(queue, light_speed);

    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    const encoder = core.device.createCommandEncoder(null);
    defer encoder.release();

    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = gpu.Color{ .r = 0.0, .g = 0.0, .b = 0.4, .a = 1.0 },
        .load_op = .clear,
        .store_op = .store,
    };

    const render_pass_descriptor = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = &.{
            .view = app.depth.view,
            .depth_load_op = .clear,
            .depth_store_op = .store,
            .depth_clear_value = 1.0,
        },
    });

    const pass = encoder.beginRenderPass(&render_pass_descriptor);
    defer pass.release();

    // brick cubes
    pass.setPipeline(app.cube.pipeline);
    pass.setBindGroup(0, app.camera.bind_group, &.{});
    pass.setBindGroup(1, app.cube.texture.bind_group.?, &.{});
    pass.setBindGroup(2, app.light.bind_group, &.{});
    pass.setVertexBuffer(0, app.cube.mesh.buffer, 0, app.cube.mesh.size);
    pass.setVertexBuffer(1, app.cube.instance.buffer, 0, app.cube.instance.size);
    pass.draw(4, app.cube.instance.len, 0, 0);
    pass.draw(4, app.cube.instance.len, 4, 0);
    pass.draw(4, app.cube.instance.len, 8, 0);
    pass.draw(4, app.cube.instance.len, 12, 0);
    pass.draw(4, app.cube.instance.len, 16, 0);
    pass.draw(4, app.cube.instance.len, 20, 0);

    // light source
    pass.setPipeline(app.light.pipeline);
    pass.setBindGroup(0, app.camera.bind_group, &.{});
    pass.setBindGroup(1, app.light.bind_group, &.{});
    pass.setVertexBuffer(0, app.cube.mesh.buffer, 0, app.cube.mesh.size);
    pass.draw(4, 1, 0, 0);
    pass.draw(4, 1, 4, 0);
    pass.draw(4, 1, 8, 0);
    pass.draw(4, 1, 12, 0);
    pass.draw(4, 1, 16, 0);
    pass.draw(4, 1, 20, 0);

    pass.end();

    var command = encoder.finish(null);
    defer command.release();

    queue.submit(&[_]*gpu.CommandBuffer{command});
    core.swap_chain.present();

    // update the window title every second
    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        try core.printTitle("Gen Texture Light [ {d}fps ] [ Input {d}hz ]", .{
            core.frameRate(),
            core.inputRate(),
        });
    }

    return false;
}

const Camera = struct {
    const Self = @This();

    eye: Vec,
    target: Vec,
    up: Vec,
    aspect: f32,
    fovy: f32,
    near: f32,
    far: f32,
    bind_group: *gpu.BindGroup,
    buffer: Buffer,

    const Uniform = extern struct {
        pos: Vec,
        mat: Mat,
    };

    fn init(device: *gpu.Device, eye: Vec, target: Vec, up: Vec, aspect: f32, fovy: f32, near: f32, far: f32) Self {
        var self: Self = .{
            .eye = eye,
            .target = target,
            .up = up,
            .aspect = aspect,
            .near = near,
            .far = far,
            .fovy = fovy,
            .buffer = undefined,
            .bind_group = undefined,
        };

        const view = self.buildViewProjMatrix();

        const uniform = Uniform{
            .pos = self.eye,
            .mat = view,
        };

        const buffer = .{
            .buffer = initBuffer(device, .{ .uniform = true }, &@as([20]f32, @bitCast(uniform))),
            .size = @sizeOf(@TypeOf(uniform)),
        };

        const layout = Self.bindGroupLayout(device);
        const bind_group = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
            .layout = layout,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, buffer.buffer, 0, buffer.size, buffer.size),
            },
        }));
        layout.release();

        self.buffer = buffer;
        self.bind_group = bind_group;

        return self;
    }

    fn deinit(self: *Self) void {
        self.bind_group.release();
        self.buffer.release();
    }

    fn update(self: *Self, queue: *gpu.Queue) void {
        const mat = self.buildViewProjMatrix();
        const uniform = .{
            .pos = self.eye,
            .mat = mat,
        };

        queue.writeBuffer(self.buffer.buffer, 0, &[_]Uniform{uniform});
    }

    inline fn buildViewProjMatrix(s: *const Camera) Mat {
        const view = zm.lookAtRh(s.eye, s.target, s.up);
        const proj = zm.perspectiveFovRh(s.fovy, s.aspect, s.near, s.far);
        return zm.mul(view, proj);
    }

    inline fn bindGroupLayout(device: *gpu.Device) *gpu.BindGroupLayout {
        const visibility = .{ .vertex = true, .fragment = true };
        return device.createBindGroupLayout(&gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{
                gpu.BindGroupLayout.Entry.buffer(0, visibility, .uniform, false, 0),
            },
        }));
    }
};

const Buffer = struct {
    const Self = @This();

    buffer: *gpu.Buffer,
    size: usize,
    len: u32 = 0,

    fn release(self: *Self) void {
        self.buffer.release();
    }
};

const Cube = struct {
    const Self = @This();

    pipeline: *gpu.RenderPipeline,
    mesh: Buffer,
    instance: Buffer,
    texture: Texture,

    const IPR = 20; // instances per row
    const SPACING = 2; // spacing between cubes
    const DISPLACEMENT = vec3u(IPR * SPACING / 2, 0, IPR * SPACING / 2);

    fn init() Self {
        const device = core.device;

        const texture = Brick.texture(device);

        // instance buffer
        var ibuf: [IPR * IPR * 16]f32 = undefined;

        var z: usize = 0;
        while (z < IPR) : (z += 1) {
            var x: usize = 0;
            while (x < IPR) : (x += 1) {
                const pos = vec3u(x * SPACING, 0, z * SPACING) - DISPLACEMENT;
                const rot = blk: {
                    if (pos[0] == 0 and pos[2] == 0) {
                        break :blk zm.rotationZ(0.0);
                    } else {
                        break :blk zm.mul(zm.rotationX(zm.clamp(zm.abs(pos[0]), 0, 45.0)), zm.rotationZ(zm.clamp(zm.abs(pos[2]), 0, 45.0)));
                    }
                };
                const index = z * IPR + x;
                const inst = Instance{
                    .position = pos,
                    .rotation = rot,
                };
                zm.storeMat(ibuf[index * 16 ..], inst.toMat());
            }
        }

        const instance = Buffer{
            .buffer = initBuffer(device, .{ .vertex = true }, &ibuf),
            .len = IPR * IPR,
            .size = @sizeOf(@TypeOf(ibuf)),
        };

        return Self{
            .mesh = mesh(device),
            .texture = texture,
            .instance = instance,
            .pipeline = pipeline(),
        };
    }

    fn deinit(self: *Self) void {
        self.pipeline.release();
        self.mesh.release();
        self.instance.release();
        self.texture.release();
    }

    fn pipeline() *gpu.RenderPipeline {
        const device = core.device;

        const camera_layout = Camera.bindGroupLayout(device);
        const texture_layout = Texture.bindGroupLayout(device);
        const light_layout = Light.bindGroupLayout(device);
        const layout_descriptor = gpu.PipelineLayout.Descriptor.init(.{
            .bind_group_layouts = &.{
                camera_layout,
                texture_layout,
                light_layout,
            },
        });
        defer camera_layout.release();
        defer texture_layout.release();
        defer light_layout.release();

        const layout = device.createPipelineLayout(&layout_descriptor);
        defer layout.release();

        const shader = device.createShaderModuleWGSL("cube.wgsl", @embedFile("cube.wgsl"));
        defer shader.release();

        const blend = gpu.BlendState{};
        const color_target = gpu.ColorTargetState{
            .format = core.descriptor.format,
            .blend = &blend,
        };

        const fragment = gpu.FragmentState.init(.{
            .module = shader,
            .entry_point = "fs_main",
            .targets = &.{color_target},
        });

        const descriptor = gpu.RenderPipeline.Descriptor{
            .layout = layout,
            .fragment = &fragment,
            .vertex = gpu.VertexState.init(.{
                .module = shader,
                .entry_point = "vs_main",
                .buffers = &.{
                    Self.vertexBufferLayout(),
                    Self.instanceLayout(),
                },
            }),
            .depth_stencil = &.{
                .format = Texture.DEPTH_FORMAT,
                .depth_write_enabled = .true,
                .depth_compare = .less,
            },
            .primitive = .{
                .cull_mode = .back,
                .topology = .triangle_strip,
            },
        };

        return device.createRenderPipeline(&descriptor);
    }

    fn mesh(device: *gpu.Device) Buffer {
        // generated texture has aspect ratio of 1:2
        // `h` reflects that ratio
        // `v` sets how many times texture repeats across surface
        const v = 2;
        const h = v * 2;
        const buf = asFloats(.{
            // z+ face
            0, 0, 1, 0,  0,  1,  0, h,
            1, 0, 1, 0,  0,  1,  v, h,
            0, 1, 1, 0,  0,  1,  0, 0,
            1, 1, 1, 0,  0,  1,  v, 0,
            // z- face
            1, 0, 0, 0,  0,  -1, 0, h,
            0, 0, 0, 0,  0,  -1, v, h,
            1, 1, 0, 0,  0,  -1, 0, 0,
            0, 1, 0, 0,  0,  -1, v, 0,
            // x+ face
            1, 0, 1, 1,  0,  0,  0, h,
            1, 0, 0, 1,  0,  0,  v, h,
            1, 1, 1, 1,  0,  0,  0, 0,
            1, 1, 0, 1,  0,  0,  v, 0,
            // x- face
            0, 0, 0, -1, 0,  0,  0, h,
            0, 0, 1, -1, 0,  0,  v, h,
            0, 1, 0, -1, 0,  0,  0, 0,
            0, 1, 1, -1, 0,  0,  v, 0,
            // y+ face
            1, 1, 0, 0,  1,  0,  0, h,
            0, 1, 0, 0,  1,  0,  v, h,
            1, 1, 1, 0,  1,  0,  0, 0,
            0, 1, 1, 0,  1,  0,  v, 0,
            // y- face
            0, 0, 0, 0,  -1, 0,  0, h,
            1, 0, 0, 0,  -1, 0,  v, h,
            0, 0, 1, 0,  -1, 0,  0, 0,
            1, 0, 1, 0,  -1, 0,  v, 0,
        });

        return Buffer{
            .buffer = initBuffer(device, .{ .vertex = true }, &buf),
            .size = @sizeOf(@TypeOf(buf)),
        };
    }

    fn vertexBufferLayout() gpu.VertexBufferLayout {
        const attributes = [_]gpu.VertexAttribute{
            .{
                .format = .float32x3,
                .offset = 0,
                .shader_location = 0,
            },
            .{
                .format = .float32x3,
                .offset = @sizeOf([3]f32),
                .shader_location = 1,
            },
            .{
                .format = .float32x2,
                .offset = @sizeOf([6]f32),
                .shader_location = 2,
            },
        };
        return gpu.VertexBufferLayout.init(.{
            .array_stride = @sizeOf([8]f32),
            .attributes = &attributes,
        });
    }

    fn instanceLayout() gpu.VertexBufferLayout {
        const attributes = [_]gpu.VertexAttribute{
            .{
                .format = .float32x4,
                .offset = 0,
                .shader_location = 3,
            },
            .{
                .format = .float32x4,
                .offset = @sizeOf([4]f32),
                .shader_location = 4,
            },
            .{
                .format = .float32x4,
                .offset = @sizeOf([8]f32),
                .shader_location = 5,
            },
            .{
                .format = .float32x4,
                .offset = @sizeOf([12]f32),
                .shader_location = 6,
            },
        };

        return gpu.VertexBufferLayout.init(.{
            .array_stride = @sizeOf([16]f32),
            .step_mode = .instance,
            .attributes = &attributes,
        });
    }
};

fn asFloats(comptime arr: anytype) [arr.len]f32 {
    const len = arr.len;
    comptime var out: [len]f32 = undefined;
    comptime var i = 0;
    inline while (i < len) : (i += 1) {
        out[i] = @as(f32, @floatFromInt(arr[i]));
    }
    return out;
}

const Brick = struct {
    const W = 12;
    const H = 6;

    fn texture(device: *gpu.Device) Texture {
        const slice: []const u8 = &data();
        return Texture.fromData(device, W, H, u8, slice);
    }

    fn data() [W * H * 4]u8 {
        comptime var out: [W * H * 4]u8 = undefined;

        // fill all the texture with brick color
        comptime var i = 0;
        inline while (i < H) : (i += 1) {
            comptime var j = 0;
            inline while (j < W * 4) : (j += 4) {
                out[i * W * 4 + j + 0] = 210;
                out[i * W * 4 + j + 1] = 30;
                out[i * W * 4 + j + 2] = 30;
                out[i * W * 4 + j + 3] = 0;
            }
        }

        const f = 10;

        // fill the cement lines
        inline for ([_]comptime_int{ 0, 1 }) |k| {
            inline for ([_]comptime_int{ 5 * 4, 11 * 4 }) |m| {
                out[k * W * 4 + m + 0] = f;
                out[k * W * 4 + m + 1] = f;
                out[k * W * 4 + m + 2] = f;
                out[k * W * 4 + m + 3] = 0;
            }
        }

        inline for ([_]comptime_int{ 3, 4 }) |k| {
            inline for ([_]comptime_int{ 2 * 4, 8 * 4 }) |m| {
                out[k * W * 4 + m + 0] = f;
                out[k * W * 4 + m + 1] = f;
                out[k * W * 4 + m + 2] = f;
                out[k * W * 4 + m + 3] = 0;
            }
        }

        inline for ([_]comptime_int{ 2, 5 }) |k| {
            comptime var m = 0;
            inline while (m < W * 4) : (m += 4) {
                out[k * W * 4 + m + 0] = f;
                out[k * W * 4 + m + 1] = f;
                out[k * W * 4 + m + 2] = f;
                out[k * W * 4 + m + 3] = 0;
            }
        }

        return out;
    }
};

// don't confuse with gpu.Texture
const Texture = struct {
    const Self = @This();

    texture: *gpu.Texture,
    view: *gpu.TextureView,
    sampler: *gpu.Sampler,
    bind_group: ?*gpu.BindGroup,

    const DEPTH_FORMAT = .depth32_float;
    const FORMAT = .rgba8_unorm;

    fn release(self: *Self) void {
        self.texture.release();
        self.view.release();
        self.sampler.release();
        if (self.bind_group) |bind_group| bind_group.release();
    }

    fn fromData(device: *gpu.Device, width: u32, height: u32, comptime T: type, data: []const T) Self {
        const extent = gpu.Extent3D{
            .width = width,
            .height = height,
        };

        const texture = device.createTexture(&gpu.Texture.Descriptor{
            .size = extent,
            .format = FORMAT,
            .usage = .{ .copy_dst = true, .texture_binding = true },
        });

        const view = texture.createView(&gpu.TextureView.Descriptor{
            .format = FORMAT,
            .dimension = .dimension_2d,
            .array_layer_count = 1,
            .mip_level_count = 1,
        });

        const sampler = device.createSampler(&gpu.Sampler.Descriptor{
            .address_mode_u = .repeat,
            .address_mode_v = .repeat,
            .address_mode_w = .repeat,
            .mag_filter = .linear,
            .min_filter = .linear,
            .mipmap_filter = .linear,
            .max_anisotropy = 1, // 1,2,4,8,16
        });

        core.queue.writeTexture(
            &gpu.ImageCopyTexture{
                .texture = texture,
            },
            &gpu.Texture.DataLayout{
                .bytes_per_row = 4 * width,
                .rows_per_image = height,
            },
            &extent,
            data,
        );

        const bind_group_layout = Self.bindGroupLayout(device);
        const bind_group = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
            .layout = bind_group_layout,
            .entries = &.{
                gpu.BindGroup.Entry.textureView(0, view),
                gpu.BindGroup.Entry.sampler(1, sampler),
            },
        }));
        bind_group_layout.release();

        return Self{
            .view = view,
            .texture = texture,
            .sampler = sampler,
            .bind_group = bind_group,
        };
    }

    fn depth(device: *gpu.Device, width: u32, height: u32) Self {
        const extent = gpu.Extent3D{
            .width = width,
            .height = height,
        };

        const texture = device.createTexture(&gpu.Texture.Descriptor{
            .size = extent,
            .format = DEPTH_FORMAT,
            .usage = .{
                .render_attachment = true,
                .texture_binding = true,
            },
        });

        const view = texture.createView(&gpu.TextureView.Descriptor{
            .dimension = .dimension_2d,
            .array_layer_count = 1,
            .mip_level_count = 1,
        });

        const sampler = device.createSampler(&gpu.Sampler.Descriptor{
            .mag_filter = .linear,
            .compare = .less_equal,
        });

        return Self{
            .texture = texture,
            .view = view,
            .sampler = sampler,
            .bind_group = null, // not used
        };
    }

    inline fn bindGroupLayout(device: *gpu.Device) *gpu.BindGroupLayout {
        const visibility = .{ .fragment = true };
        const Entry = gpu.BindGroupLayout.Entry;
        return device.createBindGroupLayout(&gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{
                Entry.texture(0, visibility, .float, .dimension_2d, false),
                Entry.sampler(1, visibility, .filtering),
            },
        }));
    }
};

const Light = struct {
    const Self = @This();

    uniform: Uniform,
    buffer: Buffer,
    bind_group: *gpu.BindGroup,
    pipeline: *gpu.RenderPipeline,

    const Uniform = extern struct {
        position: Vec,
        color: Vec,
    };

    fn init() Self {
        const device = core.device;
        const uniform = Uniform{
            .color = vec3u(1, 1, 1),
            .position = vec3u(3, 7, 2),
        };

        const buffer = .{
            .buffer = initBuffer(device, .{ .uniform = true }, &@as([8]f32, @bitCast(uniform))),
            .size = @sizeOf(@TypeOf(uniform)),
        };

        const layout = Self.bindGroupLayout(device);
        const bind_group = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
            .layout = layout,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, buffer.buffer, 0, buffer.size, buffer.size),
            },
        }));
        layout.release();

        return Self{
            .buffer = buffer,
            .uniform = uniform,
            .bind_group = bind_group,
            .pipeline = Self.pipeline(),
        };
    }

    fn deinit(self: *Self) void {
        self.buffer.release();
        self.bind_group.release();
        self.pipeline.release();
    }

    fn update(self: *Self, queue: *gpu.Queue, delta: f32) void {
        const old = self.uniform;
        const new = Light.Uniform{
            .position = zm.qmul(zm.quatFromAxisAngle(vec3u(0, 1, 0), delta), old.position),
            .color = old.color,
        };
        queue.writeBuffer(self.buffer.buffer, 0, &[_]Light.Uniform{new});
        self.uniform = new;
    }

    inline fn bindGroupLayout(device: *gpu.Device) *gpu.BindGroupLayout {
        const visibility = .{ .vertex = true, .fragment = true };
        const Entry = gpu.BindGroupLayout.Entry;
        return device.createBindGroupLayout(&gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{
                Entry.buffer(0, visibility, .uniform, false, 0),
            },
        }));
    }

    fn pipeline() *gpu.RenderPipeline {
        const device = core.device;

        const camera_layout = Camera.bindGroupLayout(device);
        const light_layout = Light.bindGroupLayout(device);
        const layout_descriptor = gpu.PipelineLayout.Descriptor.init(.{
            .bind_group_layouts = &.{
                camera_layout,
                light_layout,
            },
        });
        defer camera_layout.release();
        defer light_layout.release();

        const layout = device.createPipelineLayout(&layout_descriptor);
        defer layout.release();

        const shader = core.device.createShaderModuleWGSL("light.wgsl", @embedFile("light.wgsl"));
        defer shader.release();

        const blend = gpu.BlendState{};
        const color_target = gpu.ColorTargetState{
            .format = core.descriptor.format,
            .blend = &blend,
        };

        const fragment = gpu.FragmentState.init(.{
            .module = shader,
            .entry_point = "fs_main",
            .targets = &.{color_target},
        });

        const descriptor = gpu.RenderPipeline.Descriptor{
            .layout = layout,
            .fragment = &fragment,
            .vertex = gpu.VertexState.init(.{
                .module = shader,
                .entry_point = "vs_main",
                .buffers = &.{
                    Cube.vertexBufferLayout(),
                },
            }),
            .depth_stencil = &.{
                .format = Texture.DEPTH_FORMAT,
                .depth_write_enabled = .true,
                .depth_compare = .less,
            },
            .primitive = .{
                .cull_mode = .back,
                .topology = .triangle_strip,
            },
        };

        return device.createRenderPipeline(&descriptor);
    }
};

inline fn initBuffer(device: *gpu.Device, usage: gpu.Buffer.UsageFlags, data: anytype) *gpu.Buffer {
    std.debug.assert(@typeInfo(@TypeOf(data)) == .Pointer);
    const T = std.meta.Elem(@TypeOf(data));

    var u = usage;
    u.copy_dst = true;
    const buffer = device.createBuffer(&.{
        .size = @sizeOf(T) * data.len,
        .usage = u,
        .mapped_at_creation = .true,
    });

    const mapped = buffer.getMappedRange(T, 0, data.len);
    @memcpy(mapped.?, data);
    buffer.unmap();
    return buffer;
}

fn vec3i(x: isize, y: isize, z: isize) Vec {
    return Vec{ @floatFromInt(x), @floatFromInt(y), @floatFromInt(z), 0.0 };
}

fn vec3u(x: usize, y: usize, z: usize) Vec {
    return zm.Vec{ @floatFromInt(x), @floatFromInt(y), @floatFromInt(z), 0.0 };
}

// todo indside Cube
const Instance = struct {
    const Self = @This();

    position: Vec,
    rotation: Mat,

    fn toMat(self: *const Self) Mat {
        return zm.mul(self.rotation, zm.translationV(self.position));
    }
};
