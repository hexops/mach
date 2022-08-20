// in this example:
//   - comptime generated image data for texture
//   - Blinn-Phong lighting
//   - several pipelines
//
// quit with escape, q or space
// move camera with arrows or wasd

const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const glfw = @import("glfw");
const zm = @import("zmath");

const Vec = zm.Vec;
const Mat = zm.Mat;
const Quat = zm.Quat;

pub const App = @This();

queue: *gpu.Queue,
cube: Cube,
camera: Camera,
light: Light,
depth: ?Texture,
keys: u8 = 0,

const Dir = struct {
    const up: u8 = 0b0001;
    const down: u8 = 0b0010;
    const left: u8 = 0b0100;
    const right: u8 = 0b1000;
};

pub fn init(app: *App, core: *mach.Core) !void {
    try core.setOptions(.{
        .size_min = .{ .width = 20, .height = 20 },
    });

    const eye = vec3(5.0, 7.0, 5.0);
    const target = vec3(0.0, 0.0, 0.0);

    const size = core.getFramebufferSize();
    const aspect_ratio = @intToFloat(f32, size.width) / @intToFloat(f32, size.height);

    app.queue = core.device.getQueue();
    app.cube = Cube.init(core);
    app.light = Light.init(core);
    app.depth = null;
    app.camera = Camera.init(core.device, eye, target, vec3(0.0, 1.0, 0.0), aspect_ratio, 45.0, 0.1, 100.0);
}

pub fn deinit(app: *App, _: *mach.Core) void {
    app.depth.?.release();
}

pub fn update(app: *App, core: *mach.Core) !void {
    while (core.pollEvent()) |event| {
        switch (event) {
            .key_press => |ev| switch (ev.key) {
                .q, .escape, .space => core.setShouldClose(true),
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
            else => {},
        }
    }

    // move camera
    const speed = zm.f32x4s(@floatCast(f32, core.delta_time * 5));
    const fwd = zm.normalize3(app.camera.target - app.camera.eye);
    const right = zm.normalize3(zm.cross3(fwd, app.camera.up));

    if (app.keys & Dir.up != 0)
        app.camera.eye += fwd * speed;

    if (app.keys & Dir.down != 0)
        app.camera.eye -= fwd * speed;

    if (app.keys & Dir.right != 0) app.camera.eye += right * speed else if (app.keys & Dir.left != 0) app.camera.eye -= right * speed else app.camera.eye += right * (speed * @Vector(4, f32){ 0.5, 0.5, 0.5, 0.5 });

    app.camera.update(app.queue);

    // move light
    const light_speed = @floatCast(f32, core.delta_time * 2.5);
    app.light.update(app.queue, light_speed);

    const back_buffer_view = core.swap_chain.?.getCurrentTextureView();
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
            .view = app.depth.?.view,
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
    pass.setBindGroup(1, app.cube.texture.bind_group, &.{});
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

    app.queue.submit(&.{command});
    core.swap_chain.?.present();
}

pub fn resize(app: *App, core: *mach.Core, width: u32, height: u32) !void {
    // If window is resized, recreate depth buffer otherwise we cannot use it.
    if (app.depth != null) {
        app.depth.?.release();
    }
    // It also recreates the sampler, which is a waste, but for an example it's ok
    app.depth = Texture.depth(core.device, width, height);
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
            .buffer = initBuffer(device, .{ .uniform = true }, &@bitCast([20]f32, uniform)),
            .size = @sizeOf(@TypeOf(uniform)),
        };

        const bind_group = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
            .layout = Self.bindGroupLayout(device),
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, buffer.buffer, 0, buffer.size),
            },
        }));

        self.buffer = buffer;
        self.bind_group = bind_group;

        return self;
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
    buffer: *gpu.Buffer,
    size: usize,
    len: u32 = 0,
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

    fn init(core: *mach.Core) Self {
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
                        break :blk zm.quatFromAxisAngle(vec3u(0, 0, 1), 0.0);
                    } else {
                        break :blk zm.quatFromAxisAngle(zm.normalize3(pos), 45.0);
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
            .pipeline = pipeline(core),
        };
    }

    fn pipeline(core: *mach.Core) *gpu.RenderPipeline {
        const device = core.device;

        const layout_descriptor = gpu.PipelineLayout.Descriptor.init(.{
            .bind_group_layouts = &.{
                Camera.bindGroupLayout(device),
                Texture.bindGroupLayout(device),
                Light.bindGroupLayout(device),
            },
        });

        const layout = device.createPipelineLayout(&layout_descriptor);
        defer layout.release();

        const shader = device.createShaderModuleWGSL("cube.wgsl", @embedFile("cube.wgsl"));
        defer shader.release();

        const blend = gpu.BlendState{};
        const color_target = gpu.ColorTargetState{
            .format = core.swap_chain_format,
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
                .depth_write_enabled = true,
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
    comptime var len = arr.len;
    comptime var out: [len]f32 = undefined;
    comptime var i = 0;
    inline while (i < len) : (i += 1) {
        out[i] = @intToFloat(f32, arr[i]);
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
    bind_group: *gpu.BindGroup,

    const DEPTH_FORMAT = .depth32_float;
    const FORMAT = .rgba8_unorm;

    fn release(self: *Self) void {
        self.texture.release();
        self.view.release();
        self.sampler.release();
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

        device.getQueue().writeTexture(
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
            .bind_group = undefined, // not used
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

    fn init(core: *mach.Core) Self {
        const device = core.device;
        const uniform = Uniform{
            .color = vec3u(1, 1, 1),
            .position = vec3u(3, 7, 2),
        };

        const buffer = .{
            .buffer = initBuffer(device, .{ .uniform = true }, &@bitCast([8]f32, uniform)),
            .size = @sizeOf(@TypeOf(uniform)),
        };

        const bind_group = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
            .layout = Self.bindGroupLayout(device),
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, buffer.buffer, 0, buffer.size),
            },
        }));

        return Self{
            .buffer = buffer,
            .uniform = uniform,
            .bind_group = bind_group,
            .pipeline = Self.pipeline(core),
        };
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

    fn pipeline(core: *mach.Core) *gpu.RenderPipeline {
        const device = core.device;

        const layout_descriptor = gpu.PipelineLayout.Descriptor.init(.{
            .bind_group_layouts = &.{
                Camera.bindGroupLayout(device),
                Light.bindGroupLayout(device),
            },
        });

        const layout = device.createPipelineLayout(&layout_descriptor);
        defer layout.release();

        const shader = core.device.createShaderModuleWGSL("light.wgsl", @embedFile("light.wgsl"));
        defer shader.release();

        const blend = gpu.BlendState{};
        const color_target = gpu.ColorTargetState{
            .format = core.swap_chain_format,
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
                .depth_write_enabled = true,
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
        .mapped_at_creation = true,
    });

    var mapped = buffer.getMappedRange(T, 0, data.len);
    std.mem.copy(T, mapped.?, data);
    buffer.unmap();
    return buffer;
}

fn vec3i(x: isize, y: isize, z: isize) Vec {
    return zm.f32x4(@intToFloat(f32, x), @intToFloat(f32, y), @intToFloat(f32, z), 0.0);
}

fn vec3u(x: usize, y: usize, z: usize) Vec {
    return zm.f32x4(@intToFloat(f32, x), @intToFloat(f32, y), @intToFloat(f32, z), 0.0);
}

fn vec3(x: f32, y: f32, z: f32) Vec {
    return zm.f32x4(x, y, z, 0.0);
}

fn vec4(x: f32, y: f32, z: f32, w: f32) Vec {
    return zm.f32x4(x, y, z, w);
}

// todo indside Cube
const Instance = struct {
    const Self = @This();

    position: Vec,
    rotation: Quat,

    fn toMat(self: *const Self) Mat {
        return zm.mul(zm.quatToMat(self.rotation), zm.translationV(self.position));
    }
};
