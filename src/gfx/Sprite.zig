const std = @import("std");
const mach = @import("../main.zig");
const core = mach.core;
const gpu = mach.core.gpu;
const gfx = mach.gfx;
const Engine = mach.Engine;

const math = mach.math;
const vec2 = math.vec2;
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

pub const local_events = .{
    .update = .{ .handler = update },
};

fn update(engine: *Engine.Mod, sprite: *Mod, sprite_pipeline: *gfx.SpritePipeline.Mod) !void {
    var archetypes_iter = sprite_pipeline.entities.query(.{ .all = &.{
        .{ .mach_gfx_sprite_pipeline = &.{
            .built,
        } },
    } });
    while (archetypes_iter.next()) |archetype| {
        const ids = archetype.slice(.entity, .id);
        const built_pipelines = archetype.slice(.mach_gfx_sprite_pipeline, .built);
        for (ids, built_pipelines) |pipeline_id, *built| {
            try updatePipeline(engine, sprite, sprite_pipeline, pipeline_id, built);
        }
    }
}

fn updatePipeline(
    engine: *Engine.Mod,
    sprite: *Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    pipeline_id: mach.EntityID,
    built: *gfx.SpritePipeline.BuiltPipeline,
) !void {
    const device = engine.state().device;
    const encoder = device.createCommandEncoder(null);
    defer encoder.release();

    var archetypes_iter = sprite.entities.query(.{ .all = &.{
        .{ .mach_gfx_sprite = &.{
            .uv_transform,
            .transform,
            .size,
            .pipeline,
        } },
    } });
    var num_sprites: u32 = 0;
    var i: usize = 0;
    while (archetypes_iter.next()) |archetype| {
        const transforms = archetype.slice(.mach_gfx_sprite, .transform);
        const uv_transforms = archetype.slice(.mach_gfx_sprite, .uv_transform);
        const sizes = archetype.slice(.mach_gfx_sprite, .size);
        const pipelines = archetype.slice(.mach_gfx_sprite, .pipeline);

        // TODO: currently we cannot query all sprites which have a _single_ pipeline component
        // value and get back contiguous memory for all of them. This is because all sprites with
        // possibly different pipeline component values are stored as the same archetype. If we
        // introduce a new concept of tagging-by-value to our entity storage then we can enforce
        // that all entities with the same pipeline value are stored in contiguous memory, and
        // skip this copy.
        for (transforms, uv_transforms, sizes, pipelines) |transform, uv_transform, size, sprite_pipeline_id| {
            if (sprite_pipeline_id == pipeline_id) {
                gfx.SpritePipeline.cp_transforms[i] = transform;
                gfx.SpritePipeline.cp_uv_transforms[i] = uv_transform;
                gfx.SpritePipeline.cp_sizes[i] = size;
                i += 1;
                num_sprites += 1;
            }
        }
    }

    try sprite_pipeline.set(pipeline_id, .num_sprites, num_sprites);
    if (num_sprites > 0) {
        encoder.writeBuffer(built.transforms, 0, gfx.SpritePipeline.cp_transforms[0..i]);
        encoder.writeBuffer(built.uv_transforms, 0, gfx.SpritePipeline.cp_uv_transforms[0..i]);
        encoder.writeBuffer(built.sizes, 0, gfx.SpritePipeline.cp_sizes[0..i]);
        var command = encoder.finish(null);
        defer command.release();
        engine.state().queue.submit(&[_]*gpu.CommandBuffer{command});
    }
}
