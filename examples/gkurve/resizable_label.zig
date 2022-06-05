//! TODO: Refactor the API, maybe use a handle that contains the lib and other things and controls init and deinit of ft.Lib and other things

const std = @import("std");
const ft = @import("freetype");
const zigimg = @import("zigimg");
const Atlas = @import("atlas.zig").Atlas;
const AtlasErr = @import("atlas.zig").Error;
const UVData = @import("atlas.zig").UVData;
const App = @import("main.zig").App;
const draw = @import("draw.zig");
const Vertex = draw.Vertex;
const Tessellator = @import("tessellator.zig").Tessellator;

// If true, show the filled triangles green, the concave beziers blue and the convex ones red
const debug_colors = false;

pub const ResizableLabel = @This();

const Vec2 = @Vector(2, f32);
const Vec4 = @Vector(4, f32);
const VertexList = std.ArrayList(Vertex);

// All the data that a single character needs to be rendered
// TODO: hori/vert advance, write file format
const CharVertices = struct {
    filled_vertices: VertexList,
    filled_vertices_indices: std.ArrayList(u16),
    // Concave vertices belong to the filled_vertices list, so just index them
    concave_vertices: std.ArrayList(u16),
    // The point outside of the convex bezier, doesn't belong to the filled vertices,
    // But the other two points do, so put those in the indices
    convex_vertices: VertexList,
    convex_vertices_indices: std.ArrayList(u16),
};

face: ft.Face,
char_map: std.AutoHashMap(u21, CharVertices),
allocator: std.mem.Allocator,
tessellator: Tessellator,
white_texture: UVData,

// The data that the write function needs
// TODO: move twxture here, don't limit to just white_texture
const WriterContext = struct {
    label: *ResizableLabel,
    app: *App,
    position: Vec4,
    text_color: Vec4,
    text_size: u32,
};
const WriterError = ft.Error || std.mem.Allocator.Error || AtlasErr;
const Writer = std.io.Writer(WriterContext, WriterError, write);

pub fn writer(label: *ResizableLabel, app: *App, position: Vec4, text_color: Vec4, text_size: u32) Writer {
    return Writer{
        .context = .{
            .label = label,
            .app = app,
            .position = position,
            .text_color = text_color,
            .text_size = text_size,
        },
    };
}

pub fn init(self: *ResizableLabel, lib: ft.Library, font_path: []const u8, face_index: i32, allocator: std.mem.Allocator, white_texture: UVData) !void {
    self.* = ResizableLabel{
        .face = try lib.newFace(font_path, face_index),
        .char_map = std.AutoHashMap(u21, CharVertices).init(allocator),
        .allocator = allocator,
        .tessellator = undefined,
        .white_texture = white_texture,
    };
    self.tessellator.init(self.allocator);
}

pub fn deinit(label: *ResizableLabel) void {
    label.face.deinit();
    label.tessellator.deinit();
    // FIXME:
    // std.debug.todo("valueIterator() doesn't stop? How do we deallocate the values?");
    // while (label.char_map.valueIterator().next()) |value| {
    //     _ = value;
    // value.filled_vertices.deinit();
    // value.filled_vertices_indices.deinit();
    // value.convex_vertices.deinit();
    // value.convex_vertices_indices.deinit();
    // value.concave_vertices.deinit();
    // }
    label.char_map.deinit();
}

// TODO: handle offsets
// FIXME: many useless allocations for the arraylists
fn write(ctx: WriterContext, bytes: []const u8) WriterError!usize {
    var offset = Vec4{ 0, 0, 0, 0 };
    var c: usize = 0;
    while (c < bytes.len) {
        const len = std.unicode.utf8ByteSequenceLength(bytes[c]) catch unreachable;
        const char = std.unicode.utf8Decode(bytes[c..(c + len)]) catch unreachable;
        c += len;
        switch (char) {
            '\n' => {
                offset[0] = 0;
                offset[1] -= @intToFloat(f32, ctx.label.face.sizeMetrics().?.height >> 6);
                std.debug.todo("New line not implemented yet");
            },
            ' ' => {
                std.debug.todo("Space character not implemented yet");
                // const v = try ctx.label.char_map.getOrPut(char);
                // if (!v.found_existing) {
                //     try ctx.label.face.setCharSize(ctx.label.size * 64, 0, 50, 0);
                //     try ctx.label.face.loadChar(char, .{ .render = true });
                //     const glyph = ctx.label.face.glyph;
                //     v.value_ptr.* = GlyphInfo{
                //         .uv_data = undefined,
                //         .metrics = glyph.metrics(),
                //     };
                // }
                // offset[0] += @intToFloat(f32, v.value_ptr.metrics.horiAdvance >> 6);
            },
            else => {
                const v = try ctx.label.char_map.getOrPut(char);
                if (!v.found_existing) {
                    try ctx.label.face.loadChar(char, .{ .no_scale = true, .no_bitmap = true });
                    const glyph = ctx.label.face.glyph;

                    // Use a big scale and then scale to the actual text size
                    const multiplier = 1024 << 6;
                    const matrix = ft.Matrix{
                        .xx = 1 * multiplier,
                        .xy = 0 * multiplier,
                        .yx = 0 * multiplier,
                        .yy = 1 * multiplier,
                    };
                    glyph.outline().?.transform(matrix);

                    v.value_ptr.* = CharVertices{
                        .filled_vertices = VertexList.init(ctx.label.allocator),
                        .filled_vertices_indices = std.ArrayList(u16).init(ctx.label.allocator),
                        .concave_vertices = std.ArrayList(u16).init(ctx.label.allocator),
                        .convex_vertices = VertexList.init(ctx.label.allocator),
                        .convex_vertices_indices = std.ArrayList(u16).init(ctx.label.allocator),
                    };

                    var outline_ctx = OutlineContext{
                        .outline_verts = std.ArrayList(std.ArrayList(Vec2)).init(ctx.label.allocator),
                        .inside_verts = std.ArrayList(Vec2).init(ctx.label.allocator),
                        .concave_vertices = std.ArrayList(Vec2).init(ctx.label.allocator),
                        .convex_vertices = std.ArrayList(Vec2).init(ctx.label.allocator),
                    };
                    defer outline_ctx.outline_verts.deinit();
                    defer {
                        for (outline_ctx.outline_verts.items) |*item| {
                            item.deinit();
                        }
                    }
                    defer outline_ctx.inside_verts.deinit();
                    defer outline_ctx.concave_vertices.deinit();
                    defer outline_ctx.convex_vertices.deinit();

                    const callbacks = ft.Outline.OutlineFuncs(*OutlineContext){
                        .move_to = moveToFunction,
                        .line_to = lineToFunction,
                        .conic_to = conicToFunction,
                        .cubic_to = cubicToFunction,
                        .shift = 0,
                        .delta = 0,
                    };
                    try ctx.label.face.glyph.outline().?.decompose(&outline_ctx, callbacks);

                    uniteOutsideAndInsideVertices(&outline_ctx);

                    // Tessellator.triangulatePolygons() doesn't seem to work, so just
                    // call triangulatePolygon() for each polygon, and put the results all
                    // in all_outlines and all_indices
                    var all_outlines = std.ArrayList(Vec2).init(ctx.label.allocator);
                    defer all_outlines.deinit();
                    var all_indices = std.ArrayList(u16).init(ctx.label.allocator);
                    defer all_indices.deinit();
                    var idx_offset: u16 = 0;
                    for (outline_ctx.outline_verts.items) |item| {
                        ctx.label.tessellator.triangulatePolygon(item.items);
                        defer ctx.label.tessellator.clearBuffers();
                        try all_outlines.appendSlice(ctx.label.tessellator.out_verts.items);
                        for (ctx.label.tessellator.out_idxes.items) |idx| {
                            try all_indices.append(idx + idx_offset);
                        }
                        idx_offset += @intCast(u16, ctx.label.tessellator.out_verts.items.len);
                    }

                    for (all_outlines.items) |item| {
                        // FIXME: The uv_data is wrong, should be pushed up by the lowest a character can be
                        const vertex_uv = item / @splat(2, @as(f32, 1024 << 6));
                        const vertex_pos = Vec4{ item[0], item[1], 0, 1 };
                        try v.value_ptr.filled_vertices.append(Vertex{ .pos = vertex_pos, .uv = vertex_uv });
                    }
                    try v.value_ptr.filled_vertices_indices.appendSlice(all_indices.items);

                    // FIXME: instead of finding the closest vertex and use its index maybe use indices directly in the moveTo,... functions
                    var i: usize = 0;
                    while (i < outline_ctx.concave_vertices.items.len) : (i += 1) {
                        for (all_outlines.items) |item, j| {
                            const dist = @reduce(.Add, (item - outline_ctx.concave_vertices.items[i]) * (item - outline_ctx.concave_vertices.items[i]));
                            if (dist < 0.1) {
                                try v.value_ptr.concave_vertices.append(@truncate(u16, j));
                                break;
                            }
                        }
                    }

                    i = 0;
                    while (i < outline_ctx.convex_vertices.items.len) : (i += 3) {
                        const vert = outline_ctx.convex_vertices.items[i];
                        const vertex_uv = vert / @splat(2, @as(f32, 1024 << 6));
                        const vertex_pos = Vec4{ vert[0], vert[1], 0, 1 };
                        try v.value_ptr.convex_vertices.append(Vertex{ .pos = vertex_pos, .uv = vertex_uv });

                        for (all_outlines.items) |item, j| {
                            const dist1 = @reduce(.Add, (item - outline_ctx.convex_vertices.items[i + 1]) * (item - outline_ctx.convex_vertices.items[i + 1]));
                            if (dist1 < 0.1) {
                                try v.value_ptr.convex_vertices_indices.append(@truncate(u16, j));
                            }

                            const dist2 = @reduce(.Add, (item - outline_ctx.convex_vertices.items[i + 2]) * (item - outline_ctx.convex_vertices.items[i + 2]));
                            if (dist2 < 0.1) {
                                try v.value_ptr.convex_vertices_indices.append(@truncate(u16, j));
                            }
                        }
                    }

                    ctx.label.tessellator.clearBuffers();
                }

                // Read the data and apply resizing of pos and uv
                var filled_vertices_after_offset = try ctx.label.allocator.alloc(Vertex, v.value_ptr.filled_vertices.items.len);
                defer ctx.label.allocator.free(filled_vertices_after_offset);
                for (filled_vertices_after_offset) |*vert, i| {
                    vert.* = v.value_ptr.filled_vertices.items[i];
                    vert.pos *= Vec4{ @intToFloat(f32, ctx.text_size) / 1024, @intToFloat(f32, ctx.text_size) / 1024, 0, 1 };
                    vert.pos += ctx.position + offset;
                    vert.uv = vert.uv * ctx.label.white_texture.width_and_height + ctx.label.white_texture.bottom_left;
                }

                var actual_filled_vertices_to_use = try ctx.label.allocator.alloc(Vertex, v.value_ptr.filled_vertices_indices.items.len);
                defer ctx.label.allocator.free(actual_filled_vertices_to_use);
                for (actual_filled_vertices_to_use) |*vert, i| {
                    vert.* = filled_vertices_after_offset[v.value_ptr.filled_vertices_indices.items[i]];
                }
                try ctx.app.vertices.appendSlice(actual_filled_vertices_to_use);

                if (debug_colors) {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .blend_color = .{ 0, 1, 0, 1 } }, actual_filled_vertices_to_use.len / 3);
                } else {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .blend_color = ctx.text_color }, actual_filled_vertices_to_use.len / 3);
                }

                var convex_vertices_after_offset = try ctx.label.allocator.alloc(Vertex, v.value_ptr.convex_vertices.items.len + v.value_ptr.convex_vertices_indices.items.len);
                defer ctx.label.allocator.free(convex_vertices_after_offset);
                var j: u16 = 0;
                var k: u16 = 0;
                while (j < convex_vertices_after_offset.len) : (j += 3) {
                    convex_vertices_after_offset[j] = v.value_ptr.convex_vertices.items[j / 3];
                    convex_vertices_after_offset[j].pos *= Vec4{ @intToFloat(f32, ctx.text_size) / 1024, @intToFloat(f32, ctx.text_size) / 1024, 0, 1 };
                    convex_vertices_after_offset[j].pos += ctx.position + offset;
                    convex_vertices_after_offset[j].uv = convex_vertices_after_offset[j].uv * ctx.label.white_texture.width_and_height + ctx.label.white_texture.bottom_left;

                    convex_vertices_after_offset[j + 1] = filled_vertices_after_offset[v.value_ptr.convex_vertices_indices.items[k]];
                    convex_vertices_after_offset[j + 2] = filled_vertices_after_offset[v.value_ptr.convex_vertices_indices.items[k + 1]];
                    k += 2;
                }
                try ctx.app.vertices.appendSlice(convex_vertices_after_offset);

                if (debug_colors) {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .type = .convex, .blend_color = .{ 1, 0, 0, 1 } }, convex_vertices_after_offset.len / 3);
                } else {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .type = .convex, .blend_color = ctx.text_color }, convex_vertices_after_offset.len / 3);
                }

                var concave_vertices_after_offset = try ctx.label.allocator.alloc(Vertex, v.value_ptr.concave_vertices.items.len);
                defer ctx.label.allocator.free(concave_vertices_after_offset);
                for (concave_vertices_after_offset) |*vert, i| {
                    vert.* = filled_vertices_after_offset[v.value_ptr.concave_vertices.items[i]];
                }
                try ctx.app.vertices.appendSlice(concave_vertices_after_offset);

                if (debug_colors) {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .type = .concave, .blend_color = .{ 0, 0, 1, 1 } }, concave_vertices_after_offset.len / 3);
                } else {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .type = .concave, .blend_color = ctx.text_color }, concave_vertices_after_offset.len / 3);
                }

                ctx.app.update_vertex_buffer = true;
                ctx.app.update_frag_uniform_buffer = true;

                // offset[0] += @intToFloat(f32, v.value_ptr.metrics.horiAdvance >> 6);
            },
        }
    }
    return bytes.len;
}

// First move to initialize the outline, (first point),
// After many Q L or C, we will come back to the first point and then call M again if we need to hollow
// On the second M, we instead use an L to connect the first point to the start of the hollow path.
// We then follow like normal and at the end of the hollow path we use another L to close the path.

// This is basically how an o would be drawn, each ┌... character is a Vertex
// ┌--------┐
// |        |
// |        |
// |        |
// | ┌----┐ |
// └-┘    | |           Consider the vertices here and below to be at the same height, they are coincident
// ┌-┐    | |
// | └----┘ |
// |        |
// |        |
// |        |
// └--------┘

const OutlineContext = struct {
    // There may be more than one polygon (for example with 'i' we have the polygon of the base and another for the circle)
    outline_verts: std.ArrayList(std.ArrayList(Vec2)),

    // The internal outline, used for carving the shape (for example in a, we would first get the outline of the a, but if we stopped there, it woul
    // be filled, so we need another outline for carving the filled polygon)
    inside_verts: std.ArrayList(Vec2),

    // For the concave and convex beziers
    concave_vertices: std.ArrayList(Vec2),
    convex_vertices: std.ArrayList(Vec2),
};

// If there are elements in inside_verts, unite them with the outline_verts, effectively carving the shape
fn uniteOutsideAndInsideVertices(ctx: *OutlineContext) void {
    if (ctx.inside_verts.items.len != 0) {
        // Check which point of outline is closer to the first of inside
        var last_outline = &ctx.outline_verts.items[ctx.outline_verts.items.len - 1];
        const closest_to_inside: usize = blk: {
            const first_point_inside = ctx.inside_verts.items[0];
            var min: f32 = std.math.f32_max;
            var closest_index: usize = undefined;

            for (last_outline.items) |item, i| {
                const dist = @reduce(.Add, (item - first_point_inside) * (item - first_point_inside));
                if (dist < min) {
                    min = dist;
                    closest_index = i;
                }
            }
            break :blk closest_index;
        };

        ctx.inside_verts.append(last_outline.items[closest_to_inside]) catch unreachable;
        last_outline.insertSlice(closest_to_inside + 1, ctx.inside_verts.items) catch unreachable;
        ctx.inside_verts.clearRetainingCapacity();
    }
}
// TODO: Return also allocation error
fn moveToFunction(ctx: *OutlineContext, _to: ft.Vector) ft.Error!void {
    // std.log.info("M {} {}", .{ to.x, to.y });
    uniteOutsideAndInsideVertices(ctx);

    const to = Vec2{ @intToFloat(f32, _to.x), @intToFloat(f32, _to.y) };

    // TODO: Use raycasting of the edges for better accuracy on wether a point is inside the outline or not
    const new_point_is_inside = blk: {
        if (ctx.outline_verts.items.len == 0) {
            break :blk false;
        }

        var minx: f32 = std.math.f32_max;
        var maxx: f32 = std.math.f32_min;
        var miny: f32 = std.math.f32_max;
        var maxy: f32 = std.math.f32_min;
        for (ctx.outline_verts.items[ctx.outline_verts.items.len - 1].items) |item| {
            minx = @minimum(item[0], minx);
            maxx = @maximum(item[0], maxx);
            miny = @minimum(item[1], miny);
            maxy = @maximum(item[1], maxy);
        }

        break :blk (to[0] >= minx) and (to[0] <= maxx) and (to[1] >= miny) and (to[1] <= maxy);
    };

    // If the point is inside, put it in the inside verts
    if (new_point_is_inside) {
        ctx.inside_verts.append(to) catch unreachable;
    } else {
        // Otherwise create a new polygon
        var new_outline_list = std.ArrayList(Vec2).init(ctx.outline_verts.allocator);
        new_outline_list.append(to) catch unreachable;
        ctx.outline_verts.append(new_outline_list) catch unreachable;
    }
}

fn lineToFunction(ctx: *OutlineContext, to: ft.Vector) ft.Error!void {
    // std.log.info("L {} {}", .{ to.x, to.y });

    // If inside_verts is not empty, we need to fill it
    if (ctx.inside_verts.items.len != 0) {
        ctx.inside_verts.append(.{ @intToFloat(f32, to.x), @intToFloat(f32, to.y) }) catch unreachable;
    } else {
        // Otherwise append the new point to the last polygon
        ctx.outline_verts.items[ctx.outline_verts.items.len - 1].append(.{ @intToFloat(f32, to.x), @intToFloat(f32, to.y) }) catch unreachable;
    }
}

fn conicToFunction(ctx: *OutlineContext, _control: ft.Vector, _to: ft.Vector) ft.Error!void {
    // std.log.info("C {} {} {} {}", .{ control.x, control.y, to.x, to.y });
    const control = Vec2{ @intToFloat(f32, _control.x), @intToFloat(f32, _control.y) };
    const to = Vec2{ @intToFloat(f32, _to.x), @intToFloat(f32, _to.y) };

    // Either the inside verts or the outine ones
    var verts_to_write = if (ctx.inside_verts.items.len != 0) &ctx.inside_verts else &ctx.outline_verts.items[ctx.outline_verts.items.len - 1];
    const previous_point = verts_to_write.items[verts_to_write.items.len - 1];

    const vertices = [_]Vec2{ control, to, previous_point };

    const vec1 = control - previous_point;
    const vec2 = to - control;

    // if ccw, it's concave, else it's convex
    if ((vec1[0] * vec2[1] - vec1[1] * vec2[0]) > 0) {
        ctx.concave_vertices.appendSlice(&vertices) catch unreachable;
        verts_to_write.append(control) catch unreachable;
    } else {
        ctx.convex_vertices.appendSlice(&vertices) catch unreachable;
    }
    verts_to_write.append(to) catch unreachable;
}

// Doesn't seem to be used much
fn cubicToFunction(ctx: *OutlineContext, control_0: ft.Vector, control_1: ft.Vector, to: ft.Vector) ft.Error!void {
    _ = ctx;
    _ = control_0;
    _ = control_1;
    _ = to;
    @panic("TODO: search how to approximate cubic bezier with quadratic ones");
}

pub fn print(label: *ResizableLabel, app: *App, comptime fmt: []const u8, args: anytype, position: Vec4, text_color: Vec4, text_size: u32) !void {
    const w = writer(label, app, position, text_color, text_size);
    try w.print(fmt, args);
}
