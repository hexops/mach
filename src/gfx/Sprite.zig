const std = @import("std");
const mach = @import("../main.zig");
const gpu = mach.gpu;
const gfx = mach.gfx;

const math = mach.math;
const vec2 = math.vec2;
const vec3 = math.vec3;
const vec4 = math.vec4;
const mat4x4 = math.mat4x4;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

pub const name = .mach_gfx_sprite;
pub const Mod = mach.Mod(@This());

pub const components = .{
    .transform = .{ .type = Mat4x4, .description = 
    \\ The sprite model transformation matrix. A sprite is measured in pixel units, starting from
    \\ (0, 0) at the top-left corner and extending to the size of the sprite. By default, the world
    \\ origin (0, 0) lives at the center of the window.
    \\
    \\ Example: in a 500px by 500px window, a sprite located at (0, 0) with size (250, 250) will
    \\ cover the top-right hand corner of the window.
    },

    .uv_transform = .{ .type = Mat3x3, .description = 
    \\ UV coordinate transformation matrix describing top-left corner / origin of sprite, in pixels.
    },

    .size = .{ .type = Vec2, .description = 
    \\ The size of the sprite, in pixels.
    },

    .pipeline = .{ .type = mach.EntityID, .description = 
    \\ Which render pipeline to use for rendering the sprite.
    \\
    \\ This determines which shader, textures, etc. are used for rendering the sprite.
    },
};

pub const systems = .{
    .update = .{ .handler = update },
};

fn update(
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
) !void {
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .built_pipelines = gfx.SpritePipeline.Mod.read(.built),
    });
    while (q.next()) |v| {
        for (v.ids, v.built_pipelines) |pipeline_id, built| {
            try updatePipeline(entities, core, sprite_pipeline, pipeline_id, &built);
        }
    }
}

fn updatePipeline(
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    pipeline_id: mach.EntityID,
    built: *const gfx.SpritePipeline.BuiltPipeline,
) !void {
    const device = core.state().device;
    const label = @tagName(name) ++ ".updatePipeline";
    const encoder = device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    var num_sprites: u32 = 0;
    var i: usize = 0;
    var q = try entities.query(.{
        .transforms = Mod.read(.transform),
        .uv_transforms = Mod.read(.uv_transform),
        .sizes = Mod.read(.size),
        .pipelines = Mod.read(.pipeline),
    });
    while (q.next()) |v| {
        for (v.transforms, v.uv_transforms, v.sizes, v.pipelines) |transform, uv_transform, size, sprite_pipeline_id| {
            // TODO: currently we cannot query all sprites which have a _single_ pipeline component
            // value and get back contiguous memory for all of them. This is because all sprites with
            // possibly different pipeline component values are stored as the same archetype. If we
            // introduce a new concept of tagging-by-value to our entity storage then we can enforce
            // that all entities with the same pipeline value are stored in contiguous memory, and
            // skip this copy.
            if (sprite_pipeline_id == pipeline_id) {
                const uv = uv_transform;
                gfx.SpritePipeline.cp_transforms[i] = transform;
                // TODO(d3d12): #1217
                //   changed the uv_transform to 4x4. The 3x3 causes issues with d3d12/hlsl
                gfx.SpritePipeline.cp_uv_transforms[i].v[0] = vec4(uv.v[0].x(), uv.v[0].y(), uv.v[0].z(), 0.0);
                gfx.SpritePipeline.cp_uv_transforms[i].v[1] = vec4(uv.v[1].x(), uv.v[1].y(), uv.v[1].z(), 0.0);
                gfx.SpritePipeline.cp_uv_transforms[i].v[2] = vec4(uv.v[2].x(), uv.v[2].y(), uv.v[2].z(), 0.0);
                gfx.SpritePipeline.cp_uv_transforms[i].v[3] = vec4(0.0, 0.0, 0.0, 0.0);
                gfx.SpritePipeline.cp_sizes[i] = size;
                i += 1;
                num_sprites += 1;
            }
        }
    }

    // Sort sprites back-to-front for draw order, alpha blending
    const Context = struct {
        // TODO(d3d12): #1217
        //   changed the uv_transform to 4x4. The 3x3 causes issues with d3d12/hlsl
        transforms: []Mat4x4,
        uv_transforms: []Mat4x4,
        sizes: []Vec2,

        pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
            const a_z = ctx.transforms[a].translation().z();
            const b_z = ctx.transforms[b].translation().z();
            // Greater z values are further away, and thus should render/sort before those with lesser z values.
            return a_z > b_z;
        }

        pub fn swap(ctx: @This(), a: usize, b: usize) void {
            std.mem.swap(Mat4x4, &ctx.transforms[a], &ctx.transforms[b]);
            // TODO(d3d12): #1217
            //   changed the uv_transform to 4x4. The 3x3 causes issues with d3d12/hlsl
            std.mem.swap(Mat4x4, &ctx.uv_transforms[a], &ctx.uv_transforms[b]);
            std.mem.swap(Vec2, &ctx.sizes[a], &ctx.sizes[b]);
        }
    };
    std.sort.pdqContext(0, i, Context{
        .transforms = gfx.SpritePipeline.cp_transforms[0..i],
        .uv_transforms = gfx.SpritePipeline.cp_uv_transforms[0..i],
        .sizes = gfx.SpritePipeline.cp_sizes[0..i],
    });

    // TODO: optimize by removing this component set call and instead use a .write() query
    try sprite_pipeline.set(pipeline_id, .num_sprites, num_sprites);
    if (num_sprites > 0) {
        encoder.writeBuffer(built.transforms, 0, gfx.SpritePipeline.cp_transforms[0..i]);
        encoder.writeBuffer(built.uv_transforms, 0, gfx.SpritePipeline.cp_uv_transforms[0..i]);
        encoder.writeBuffer(built.sizes, 0, gfx.SpritePipeline.cp_sizes[0..i]);

        var command = encoder.finish(&.{ .label = label });
        defer command.release();
        core.state().queue.submit(&[_]*gpu.CommandBuffer{command});
    }
}
