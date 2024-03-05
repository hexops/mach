const std = @import("std");
const ErrorList = @import("ErrorList.zig");
const Ast = @import("Ast.zig");
const Air = @import("Air.zig");
const CodeGen = @import("CodeGen.zig");
const printAir = @import("print_air.zig").printAir;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const allocator = std.testing.allocator;

test "builtins" {
    const builtins = @embedFile("test/builtins.wgsl");
    try expectCodegen(builtins, "builtins.spv", .spirv, false);
    try expectCodegen(builtins, "builtins.hlsl", .hlsl, false);
    try expectCodegen(builtins, "builtins.msl", .msl, false);
    try expectCodegen(builtins, "builtins-spirvcross.glsl", .glsl, true);
    // try expectCodegen(if_else, "if-else.glsl", .glsl, false);
}

test "if-else" {
    const if_else = @embedFile("test/if-else.wgsl");
    try expectCodegen(if_else, "if-else.spv", .spirv, false);
    try expectCodegen(if_else, "if-else.hlsl", .hlsl, false);
    try expectCodegen(if_else, "if-else.msl", .msl, false);
    try expectCodegen(if_else, "if-else-spirvcross.glsl", .glsl, true);
    // try expectCodegen(if_else, "if-else.glsl", .glsl, false);
}

test "boids-sprite" {
    const boids_sprite = @embedFile("test/boids-sprite.wgsl");
    try expectCodegen(boids_sprite, "boids-sprite.spv", .spirv, false);
    try expectCodegen(boids_sprite, "boids-sprite.hlsl", .hlsl, false);
    try expectCodegen(boids_sprite, "boids-sprite.msl", .msl, false);
    try expectCodegen(boids_sprite, "boids-sprite-spirvcross.glsl", .glsl, true);
    // try expectCodegen(boids_sprite, "boids-sprite.glsl", .glsl, false);
}

test "boids-sprite-update" {
    const boids_sprite_update = @embedFile("test/boids-sprite-update.wgsl");
    try expectCodegen(boids_sprite_update, "boids-sprite-update.spv", .spirv, false);
    try expectCodegen(boids_sprite_update, "boids-sprite-update.hlsl", .hlsl, false);
    try expectCodegen(boids_sprite_update, "boids-sprite-update.msl", .msl, false);
    try expectCodegen(boids_sprite_update, "boids-sprite-update-spirvcross.glsl", .glsl, true);
    // try expectCodegen(boids_sprite_update, "boids-sprite-update.glsl", .glsl, false);
}

test "cube-map" {
    const cube_map = @embedFile("test/cube-map.wgsl");
    try expectCodegen(cube_map, "cube-map.spv", .spirv, false);
    try expectCodegen(cube_map, "cube-map.hlsl", .hlsl, false);
    try expectCodegen(cube_map, "cube-map.msl", .msl, false);
    try expectCodegen(cube_map, "cube-map-spirvcross.glsl", .glsl, true);
    // try expectCodegen(cube_map, "cube-map.glsl", .glsl, false);
}

test "fractal-cube" {
    const fractal_cube = @embedFile("test/fractal-cube.wgsl");
    try expectCodegen(fractal_cube, "fractal-cube.spv", .spirv, false);
    try expectCodegen(fractal_cube, "fractal-cube.hlsl", .hlsl, false);
    try expectCodegen(fractal_cube, "fractal-cube.msl", .msl, false);
    try expectCodegen(fractal_cube, "fractal-cube-spirvcross.glsl", .glsl, true);
    // try expectCodegen(fractal_cube, "fractal-cube.glsl", .glsl, false);
}

test "gen-texture-light" {
    const gen_texture_light = @embedFile("test/gen-texture-light.wgsl");
    try expectCodegen(gen_texture_light, "gen-texture-light.spv", .spirv, false);
    try expectCodegen(gen_texture_light, "gen-texture-light.hlsl", .hlsl, false);
    try expectCodegen(gen_texture_light, "gen-texture-light.msl", .msl, false);
    try expectCodegen(gen_texture_light, "gen-texture-light-spirvcross.glsl", .glsl, true);
    // try expectCodegen(gen_texture_light, "gen-texture-light.glsl", .glsl, false);
}

test "gen-texture-light-cube" {
    const gen_texture_light_cube = @embedFile("test/gen-texture-light-cube.wgsl");
    try expectCodegen(gen_texture_light_cube, "gen-texture-light-cube.spv", .spirv, false);
    try expectCodegen(gen_texture_light_cube, "gen-texture-light-cube.hlsl", .hlsl, false);
    try expectCodegen(gen_texture_light_cube, "gen-texture-light-cube.msl", .msl, false);
    try expectCodegen(gen_texture_light_cube, "gen-texture-light-cube-spirvcross.glsl", .glsl, true);
    // try expectCodegen(gen_texture_light_cube, "gen-texture-light-cube.glsl", .glsl, false);
}

test "sprite2d" {
    const sprite2d = @embedFile("test/sprite2d.wgsl");
    try expectCodegen(sprite2d, "sprite2d.spv", .spirv, false);
    try expectCodegen(sprite2d, "sprite2d.hlsl", .hlsl, false);
    try expectCodegen(sprite2d, "sprite2d.msl", .msl, false);
    try expectCodegen(sprite2d, "sprite2d-spirvcross.glsl", .glsl, true);
    // try expectCodegen(sprite2d, "sprite2d.glsl", .glsl, false);
}

test "two-cubes" {
    const two_cubes = @embedFile("test/two-cubes.wgsl");
    try expectCodegen(two_cubes, "two-cubes.spv", .spirv, false);
    try expectCodegen(two_cubes, "two-cubes.hlsl", .hlsl, false);
    try expectCodegen(two_cubes, "two-cubes.msl", .msl, false);
    try expectCodegen(two_cubes, "two-cubes-spirvcross.glsl", .glsl, true);
    // try expectCodegen(two_cubes, "two-cubes.glsl", .glsl, false);
}

test "fullscreen-textured-quad" {
    const fullscreen_textured_quad = @embedFile("test/fullscreen-textured-quad.wgsl");
    try expectCodegen(fullscreen_textured_quad, "fullscreen-textured-quad.spv", .spirv, false);
    try expectCodegen(fullscreen_textured_quad, "fullscreen-textured-quad.hlsl", .hlsl, false);
    try expectCodegen(fullscreen_textured_quad, "fullscreen-textured-quad.msl", .msl, false);
    try expectCodegen(fullscreen_textured_quad, "fullscreen-textured-quad-spirvcross.glsl", .glsl, true);
    // try expectCodegen(fullscreen_textured_quad, "fullscreen-textured-quad.glsl", .glsl, false);
}

test "image-blur" {
    const image_blur = @embedFile("test/image-blur.wgsl");
    try expectCodegen(image_blur, "image-blur.spv", .spirv, false);
    try expectCodegen(image_blur, "image-blur.hlsl", .hlsl, false);
    try expectCodegen(image_blur, "image-blur.msl", .msl, false);
    try expectCodegen(image_blur, "image-blur-spirvcross.glsl", .glsl, true);
    // try expectCodegen(image_blur, "image-blur.glsl", .glsl, false);
}

test "instanced-cube" {
    const instanced_cube = @embedFile("test/instanced-cube.wgsl");
    try expectCodegen(instanced_cube, "instanced-cube.spv", .spirv, false);
    try expectCodegen(instanced_cube, "instanced-cube.hlsl", .hlsl, false);
    try expectCodegen(instanced_cube, "instanced-cube.msl", .msl, false);
    // TODO
    // try expectCodegen(instanced_cube, "instanced-cube-spirvcross.glsl", .glsl, true);
    // try expectCodegen(instanced_cube, "instanced-cube.glsl", .glsl, false);
}

test "map-async" {
    const map_async = @embedFile("test/map-async.wgsl");
    try expectCodegen(map_async, "map-async.spv", .spirv, false);
    try expectCodegen(map_async, "map-async.hlsl", .hlsl, false);
    try expectCodegen(map_async, "map-async.msl", .msl, false);
    try expectCodegen(map_async, "map-async-spirvcross.glsl", .glsl, true);
    // try expectCodegen(map_async, "map-async.glsl", .glsl, false);
}

test "pbr-basic" {
    const pbr_basic = @embedFile("test/pbr-basic.wgsl");
    try expectCodegen(pbr_basic, "pbr-basic.spv", .spirv, false);
    try expectCodegen(pbr_basic, "pbr-basic.hlsl", .hlsl, false);
    try expectCodegen(pbr_basic, "pbr-basic.msl", .msl, false);
    try expectCodegen(pbr_basic, "pbr-basic-spirvcross.glsl", .glsl, true);
    // try expectCodegen(pbr_basic, "pbr-basic.glsl", .glsl, false);
}

test "pixel-post-process-normal-frag" {
    const pixel_post_process_normal_frag = @embedFile("test/pixel-post-process-normal-frag.wgsl");
    try expectCodegen(pixel_post_process_normal_frag, "pixel-post-process-normal-frag.spv", .spirv, false);
    try expectCodegen(pixel_post_process_normal_frag, "pixel-post-process-normal-frag.hlsl", .hlsl, false);
    try expectCodegen(pixel_post_process_normal_frag, "pixel-post-process-normal-frag.msl", .msl, false);
    try expectCodegen(pixel_post_process_normal_frag, "pixel-post-process-normal-frag-spirvcross.glsl", .glsl, true);
    // try expectCodegen(pixel_post_process_normal_frag, "pixel-post-process-normal-frag.glsl", .glsl, false);
}

test "pixel-post-process-pixel-vert" {
    const pixel_post_process_pixel_vert = @embedFile("test/pixel-post-process-pixel-vert.wgsl");
    try expectCodegen(pixel_post_process_pixel_vert, "pixel-post-process-pixel-vert.spv", .spirv, false);
    try expectCodegen(pixel_post_process_pixel_vert, "pixel-post-process-pixel-vert.hlsl", .hlsl, false);
    try expectCodegen(pixel_post_process_pixel_vert, "pixel-post-process-pixel-vert.msl", .msl, false);
    try expectCodegen(pixel_post_process_pixel_vert, "pixel-post-process-pixel-vert-spirvcross.glsl", .glsl, true);
    // try expectCodegen(pixel_post_process_pixel_vert, "pixel-post-process-pixel-vert.glsl", .glsl, false);
}

test "pixel-post-process-pixel-frag" {
    const pixel_post_process_pixel_frag = @embedFile("test/pixel-post-process-pixel-frag.wgsl");
    try expectCodegen(pixel_post_process_pixel_frag, "pixel-post-process-pixel-frag.spv", .spirv, false);
    try expectCodegen(pixel_post_process_pixel_frag, "pixel-post-process-pixel-frag.hlsl", .hlsl, false);
    try expectCodegen(pixel_post_process_pixel_frag, "pixel-post-process-pixel-frag.msl", .msl, false);
    try expectCodegen(pixel_post_process_pixel_frag, "pixel-post-process-pixel-frag-spirvcross.glsl", .glsl, true);
    // try expectCodegen(pixel_post_process_pixel_frag, "pixel-post-process-pixel-frag.glsl", .glsl, false);
}

test "pixel-post-process" {
    const pixel_post_process = @embedFile("test/pixel-post-process.wgsl");
    try expectCodegen(pixel_post_process, "pixel-post-process.spv", .spirv, false);
    try expectCodegen(pixel_post_process, "pixel-post-process.hlsl", .hlsl, false);
    try expectCodegen(pixel_post_process, "pixel-post-process.msl", .msl, false);
    try expectCodegen(pixel_post_process, "pixel-post-process-spirvcross.glsl", .glsl, true);
    // try expectCodegen(pixel_post_process, "pixel-post-process.glsl", .glsl, false);
}

test "procedural-primitives" {
    const procedural_primitives = @embedFile("test/procedural-primitives.wgsl");
    try expectCodegen(procedural_primitives, "procedural-primitives.spv", .spirv, false);
    try expectCodegen(procedural_primitives, "procedural-primitives.hlsl", .hlsl, false);
    try expectCodegen(procedural_primitives, "procedural-primitives.msl", .msl, false);
    try expectCodegen(procedural_primitives, "procedural-primitives-spirvcross.glsl", .glsl, true);
    // try expectCodegen(procedural_primitives, "procedural-primitives.glsl", .glsl, false);
}

test "rotating-cube" {
    const rotating_cube = @embedFile("test/rotating-cube.wgsl");
    try expectCodegen(rotating_cube, "rotating-cube.spv", .spirv, false);
    try expectCodegen(rotating_cube, "rotating-cube.hlsl", .hlsl, false);
    try expectCodegen(rotating_cube, "rotating-cube.msl", .msl, false);
    try expectCodegen(rotating_cube, "rotating-cube-spirvcross.glsl", .glsl, true);
    // try expectCodegen(rotating_cube, "rotating-cube.glsl", .glsl, false);
}

test "triangle" {
    const triangle = @embedFile("test/triangle.wgsl");
    try expectCodegen(triangle, "triangle.spv", .spirv, false);
    try expectCodegen(triangle, "triangle.hlsl", .hlsl, false);
    try expectCodegen(triangle, "triangle.msl", .msl, false);
    try expectCodegen(triangle, "triangle-spirvcross.glsl", .glsl, true);
    // try expectCodegen(triangle, "triangle.glsl", .glsl, false);
}

test "fragmentDeferredRendering" {
    const fragmentDeferredRendering = @embedFile("test/fragmentDeferredRendering.wgsl");
    try expectCodegen(fragmentDeferredRendering, "fragmentDeferredRendering.spv", .spirv, false);
    try expectCodegen(fragmentDeferredRendering, "fragmentDeferredRendering.hlsl", .hlsl, false);
    try expectCodegen(fragmentDeferredRendering, "triangle.msl", .msl, false);
    try expectCodegen(fragmentDeferredRendering, "triangle-spirvcross.glsl", .glsl, true);
    // try expectCodegen(fragmentDeferredRendering, "triangle.glsl", .glsl, false);
}

test "fragmentGBuffersDebugView" {
    const fragmentGBuffersDebugView = @embedFile("test/fragmentGBuffersDebugView.wgsl");
    try expectCodegen(fragmentGBuffersDebugView, "fragmentGBuffersDebugView.spv", .spirv, false);
    try expectCodegen(fragmentGBuffersDebugView, "fragmentGBuffersDebugView.hlsl", .hlsl, false);
    try expectCodegen(fragmentGBuffersDebugView, "triangle.msl", .msl, false);
    try expectCodegen(fragmentGBuffersDebugView, "triangle-spirvcross.glsl", .glsl, true);
    // try expectCodegen(fragmentGBuffersDebugView, "triangle.glsl", .glsl, false);
}

test "fragmentWriteGBuffers" {
    const fragmentWriteGBuffers = @embedFile("test/fragmentWriteGBuffers.wgsl");
    try expectCodegen(fragmentWriteGBuffers, "fragmentWriteGBuffers.spv", .spirv, false);
    try expectCodegen(fragmentWriteGBuffers, "fragmentWriteGBuffers.hlsl", .hlsl, false);
    try expectCodegen(fragmentWriteGBuffers, "triangle.msl", .msl, false);
    try expectCodegen(fragmentWriteGBuffers, "triangle-spirvcross.glsl", .glsl, true);
    // try expectCodegen(fragmentWriteGBuffers, "triangle.glsl", .glsl, false);
}

test "lightUpdate" {
    const lightUpdate = @embedFile("test/lightUpdate.wgsl");
    try expectCodegen(lightUpdate, "lightUpdate.spv", .spirv, false);
    try expectCodegen(lightUpdate, "lightUpdate.hlsl", .hlsl, false);
    try expectCodegen(lightUpdate, "triangle.msl", .msl, false);
    try expectCodegen(lightUpdate, "triangle-spirvcross.glsl", .glsl, true);
    // try expectCodegen(lightUpdate, "triangle.glsl", .glsl, false);
}

test "vertexTextureQuad" {
    const vertexTextureQuad = @embedFile("test/vertexTextureQuad.wgsl");
    try expectCodegen(vertexTextureQuad, "vertexTextureQuad.spv", .spirv, false);
    try expectCodegen(vertexTextureQuad, "vertexTextureQuad.hlsl", .hlsl, false);
    try expectCodegen(vertexTextureQuad, "triangle.msl", .msl, false);
    try expectCodegen(vertexTextureQuad, "triangle-spirvcross.glsl", .glsl, true);
    // try expectCodegen(vertexTextureQuad, "triangle.glsl", .glsl, false);
}

test "vertexWriteGBuffers" {
    const vertexWriteGBuffers = @embedFile("test/vertexWriteGBuffers.wgsl");
    try expectCodegen(vertexWriteGBuffers, "vertexWriteGBuffers.spv", .spirv, false);
    try expectCodegen(vertexWriteGBuffers, "vertexWriteGBuffers.hlsl", .hlsl, false);
    try expectCodegen(vertexWriteGBuffers, "triangle.msl", .msl, false);
    try expectCodegen(vertexWriteGBuffers, "triangle-spirvcross.glsl", .glsl, true);
    // try expectCodegen(vertexWriteGBuffers, "triangle.glsl", .glsl, false);
}

fn expectCodegen(
    source: [:0]const u8,
    comptime file_name: []const u8,
    lang: CodeGen.Language,
    use_spirv_cross: bool,
) !void {
    var errors = try ErrorList.init(allocator);
    defer errors.deinit();

    var tree = Ast.parse(allocator, &errors, source) catch |err| {
        if (err == error.Parsing) {
            try errors.print(source, null);
        }
        return err;
    };
    defer tree.deinit(allocator);

    var ir = Air.generate(allocator, &tree, &errors, null) catch |err| {
        if (err == error.AnalysisFail) {
            try errors.print(source, null);
        }
        return err;
    };
    defer ir.deinit(allocator);

    const out = try CodeGen.generate(allocator, &ir, lang, use_spirv_cross, .{}, null, null, null);
    defer allocator.free(out);

    try std.fs.cwd().makePath("zig-out/shader/");
    try std.fs.cwd().writeFile("zig-out/shader/" ++ file_name, out);
}
