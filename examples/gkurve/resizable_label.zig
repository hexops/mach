//! TODO: Refactor the API, maybe use a handle that contains the lib and other things and controls init and deinit of ft.Lib and other things

const std = @import("std");
const mach = @import("mach");
const ft = @import("freetype");
const App = @import("main.zig").App;
const Vertex = @import("draw.zig").Vertex;
const math = mach.math;
const earcut = mach.earcut;
const Atlas = mach.gfx.Atlas;
const AtlasErr = Atlas.Error;
const AtlasUV = Atlas.Region.UV;

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

    fn deinit(self: CharVertices) void {
        self.filled_vertices.deinit();
        self.filled_vertices_indices.deinit();
        self.concave_vertices.deinit();
        self.convex_vertices.deinit();
        self.convex_vertices_indices.deinit();
    }
};

face: ft.Face,
char_map: std.AutoHashMap(u21, CharVertices),
allocator: std.mem.Allocator,
tessellator: earcut.Processor(f32),
white_texture: AtlasUV,

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

pub fn init(self: *ResizableLabel, lib: ft.Library, font_path: [*:0]const u8, face_index: i32, allocator: std.mem.Allocator, white_texture: AtlasUV) !void {
    self.* = ResizableLabel{
        .face = try lib.createFace(font_path, face_index),
        .char_map = std.AutoHashMap(u21, CharVertices).init(allocator),
        .allocator = allocator,
        .tessellator = earcut.Processor(f32){},
        .white_texture = white_texture,
    };
}

pub fn deinit(label: *ResizableLabel) void {
    label.face.deinit();
    label.tessellator.deinit(label.allocator);

    var iter = label.char_map.valueIterator();
    while (iter.next()) |ptr| {
        ptr.deinit();
    }

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
                offset[1] -= @as(f32, @floatFromInt(ctx.label.face.glyph().metrics().vertAdvance)) * (@as(f32, @floatFromInt(ctx.text_size)) / 1024);
            },
            ' ' => {
                @panic("TODO: Space character not implemented yet");
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
                    const glyph = ctx.label.face.glyph();

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
                        for (outline_ctx.outline_verts.items) |*item| item.deinit();
                    }
                    defer outline_ctx.inside_verts.deinit();
                    defer outline_ctx.concave_vertices.deinit();
                    defer outline_ctx.convex_vertices.deinit();

                    const callbacks = ft.Outline.Funcs(*OutlineContext){
                        .move_to = moveToFunction,
                        .line_to = lineToFunction,
                        .conic_to = conicToFunction,
                        .cubic_to = cubicToFunction,
                        .shift = 0,
                        .delta = 0,
                    };
                    try ctx.label.face.glyph().outline().?.decompose(&outline_ctx, callbacks);
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
                        if (item.items.len == 0) continue;
                        // TODO(gkurve): don't discard this, make tessellator use Vec2 / avoid copy?
                        var polygon = std.ArrayListUnmanaged(f32){};
                        defer polygon.deinit(ctx.label.allocator);
                        if (ctx.label.face.glyph().outline().?.orientation() == .truetype) {
                            // TrueType orientation has clockwise contours, so reverse the list
                            // since we need CCW.
                            var i = item.items.len - 1;
                            while (i > 0) : (i -= 1) {
                                try polygon.append(ctx.label.allocator, item.items[i][0]);
                                try polygon.append(ctx.label.allocator, item.items[i][1]);
                            }
                        } else {
                            for (item.items) |vert| {
                                try polygon.append(ctx.label.allocator, vert[0]);
                                try polygon.append(ctx.label.allocator, vert[1]);
                            }
                        }

                        try ctx.label.tessellator.process(ctx.label.allocator, polygon.items, null, 2);

                        for (ctx.label.tessellator.triangles.items) |idx| {
                            try all_outlines.append(Vec2{ polygon.items[idx * 2], polygon.items[(idx * 2) + 1] });
                            try all_indices.append(@as(u16, @intCast((idx * 2) + idx_offset)));
                        }
                        idx_offset += @as(u16, @intCast(ctx.label.tessellator.triangles.items.len));
                    }

                    for (all_outlines.items) |item| {
                        // FIXME: The uv_data is wrong, should be pushed up by the lowest a character can be
                        const vertex_uv = item / math.vec.splat(@Vector(2, f32), 1024 << 6);
                        const vertex_pos = Vec4{ item[0], item[1], 0, 1 };
                        try v.value_ptr.filled_vertices.append(Vertex{ .pos = vertex_pos, .uv = vertex_uv });
                    }
                    try v.value_ptr.filled_vertices_indices.appendSlice(all_indices.items);

                    // TODO(gkurve): could more optimally find index (e.g. already know it from
                    // data structure, instead of finding equal point.)
                    for (outline_ctx.concave_vertices.items) |concave_control| {
                        for (all_outlines.items, 0..) |item, j| {
                            if (vec2Equal(item, concave_control)) {
                                try v.value_ptr.concave_vertices.append(@as(u16, @truncate(j)));
                                break;
                            }
                        }
                    }

                    std.debug.assert((outline_ctx.convex_vertices.items.len % 3) == 0);
                    var i: usize = 0;
                    while (i < outline_ctx.convex_vertices.items.len) : (i += 3) {
                        const vert = outline_ctx.convex_vertices.items[i];
                        const vertex_uv = vert / math.vec.splat(@Vector(2, f32), 1024 << 6);
                        const vertex_pos = Vec4{ vert[0], vert[1], 0, 1 };
                        try v.value_ptr.convex_vertices.append(Vertex{ .pos = vertex_pos, .uv = vertex_uv });

                        var found: usize = 0;
                        for (all_outlines.items, 0..) |item, j| {
                            if (vec2Equal(item, outline_ctx.convex_vertices.items[i + 1])) {
                                try v.value_ptr.convex_vertices_indices.append(@as(u16, @truncate(j)));
                                found += 1;
                            }
                            if (vec2Equal(item, outline_ctx.convex_vertices.items[i + 2])) {
                                try v.value_ptr.convex_vertices_indices.append(@as(u16, @truncate(j)));
                                found += 1;
                            }
                            if (found == 2) break;
                        }
                        std.debug.assert(found == 2);
                    }
                    std.debug.assert(((v.value_ptr.convex_vertices.items.len + v.value_ptr.convex_vertices_indices.items.len) % 3) == 0);
                }

                // Read the data and apply resizing of pos and uv
                const filled_vertices_after_offset = try ctx.label.allocator.alloc(Vertex, v.value_ptr.filled_vertices.items.len);
                defer ctx.label.allocator.free(filled_vertices_after_offset);
                for (filled_vertices_after_offset, 0..) |*vert, i| {
                    vert.* = v.value_ptr.filled_vertices.items[i];
                    vert.pos *= Vec4{ @as(f32, @floatFromInt(ctx.text_size)) / 1024, @as(f32, @floatFromInt(ctx.text_size)) / 1024, 0, 1 };
                    vert.pos += ctx.position + offset;
                    vert.uv = .{
                        vert.uv[0] * ctx.label.white_texture.width + ctx.label.white_texture.x,
                        vert.uv[1] * ctx.label.white_texture.height + ctx.label.white_texture.y,
                    };
                }
                try ctx.app.vertices.appendSlice(filled_vertices_after_offset);

                if (debug_colors) {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .blend_color = .{ 0, 1, 0, 1 } }, filled_vertices_after_offset.len / 3);
                } else {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .blend_color = ctx.text_color }, filled_vertices_after_offset.len / 3);
                }

                var convex_vertices_after_offset = try ctx.label.allocator.alloc(Vertex, v.value_ptr.convex_vertices.items.len + v.value_ptr.convex_vertices_indices.items.len);
                defer ctx.label.allocator.free(convex_vertices_after_offset);
                var j: u16 = 0;
                var k: u16 = 0;
                var convex_vertices_consumed: usize = 0;
                while (j < convex_vertices_after_offset.len) : (j += 3) {
                    convex_vertices_after_offset[j] = v.value_ptr.convex_vertices.items[j / 3];
                    convex_vertices_consumed += 1;

                    convex_vertices_after_offset[j].pos *= Vec4{ @as(f32, @floatFromInt(ctx.text_size)) / 1024, @as(f32, @floatFromInt(ctx.text_size)) / 1024, 0, 1 };
                    convex_vertices_after_offset[j].pos += ctx.position + offset;
                    convex_vertices_after_offset[j].uv = .{
                        convex_vertices_after_offset[j].uv[0] * ctx.label.white_texture.width + ctx.label.white_texture.x,
                        convex_vertices_after_offset[j].uv[1] * ctx.label.white_texture.height + ctx.label.white_texture.y,
                    };

                    convex_vertices_after_offset[j + 1] = filled_vertices_after_offset[v.value_ptr.convex_vertices_indices.items[k]];
                    convex_vertices_after_offset[j + 2] = filled_vertices_after_offset[v.value_ptr.convex_vertices_indices.items[k + 1]];
                    k += 2;
                }
                std.debug.assert(convex_vertices_consumed == v.value_ptr.convex_vertices.items.len);
                try ctx.app.vertices.appendSlice(convex_vertices_after_offset);

                if (debug_colors) {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .type = .quadratic_convex, .blend_color = .{ 1, 0, 0, 1 } }, convex_vertices_after_offset.len / 3);
                } else {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .type = .quadratic_convex, .blend_color = ctx.text_color }, convex_vertices_after_offset.len / 3);
                }

                const concave_vertices_after_offset = try ctx.label.allocator.alloc(Vertex, v.value_ptr.concave_vertices.items.len);
                defer ctx.label.allocator.free(concave_vertices_after_offset);
                for (concave_vertices_after_offset, 0..) |*vert, i| {
                    vert.* = filled_vertices_after_offset[v.value_ptr.concave_vertices.items[i]];
                }
                try ctx.app.vertices.appendSlice(concave_vertices_after_offset);

                if (debug_colors) {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .type = .quadratic_concave, .blend_color = .{ 0, 0, 1, 1 } }, concave_vertices_after_offset.len / 3);
                } else {
                    try ctx.app.fragment_uniform_list.appendNTimes(.{ .type = .quadratic_concave, .blend_color = ctx.text_color }, concave_vertices_after_offset.len / 3);
                }

                ctx.app.update_vertex_buffer = true;
                ctx.app.update_frag_uniform_buffer = true;

                offset[0] += @as(f32, @floatFromInt(ctx.label.face.glyph().metrics().horiAdvance)) * (@as(f32, @floatFromInt(ctx.text_size)) / 1024);
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
    /// There may be more than one polygon (for example with 'i' we have the polygon of the base and
    /// another for the circle)
    outline_verts: std.ArrayList(std.ArrayList(Vec2)),

    /// The internal outline, used for carving the shape. For example in 'a', we would first get the
    /// outline of the entire 'a', but if we stopped there, the center hole would be filled, so we
    /// need another outline for carving the filled polygon.
    inside_verts: std.ArrayList(Vec2),

    /// For the concave (inner 'o') and convex (outer 'o') beziers
    concave_vertices: std.ArrayList(Vec2),
    convex_vertices: std.ArrayList(Vec2),
};

/// If there are elements in inside_verts, unite them with the outline_verts, effectively carving
/// the shape
fn uniteOutsideAndInsideVertices(ctx: *OutlineContext) void {
    if (ctx.inside_verts.items.len != 0) {
        // Check which point of outline is closer to the first of inside
        var last_outline = &ctx.outline_verts.items[ctx.outline_verts.items.len - 1];
        if (last_outline.items.len == 0 and ctx.outline_verts.items.len >= 2) {
            last_outline = &ctx.outline_verts.items[ctx.outline_verts.items.len - 2];
        }
        std.debug.assert(last_outline.items.len != 0);
        const closest_to_inside: usize = blk: {
            const first_point_inside = ctx.inside_verts.items[0];
            var min = math.floatMax(f32);
            var closest_index: usize = undefined;

            for (last_outline.items, 0..) |item, i| {
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
    uniteOutsideAndInsideVertices(ctx);

    const to = Vec2{ @as(f32, @floatFromInt(_to.x)), @as(f32, @floatFromInt(_to.y)) };

    // To check wether a point is carving a polygon, use the point-in-polygon test to determine if
    // we're inside or outside of the polygon.
    const new_point_is_inside = pointInPolygon(to, ctx.outline_verts.items);

    if (ctx.outline_verts.items.len == 0 or ctx.outline_verts.items[ctx.outline_verts.items.len - 1].items.len > 0) {
        // The last polygon we were building is now finished.
        const new_outline_list = std.ArrayList(Vec2).init(ctx.outline_verts.allocator);
        ctx.outline_verts.append(new_outline_list) catch unreachable;
    }

    if (new_point_is_inside) {
        ctx.inside_verts.append(to) catch unreachable;
    } else {
        ctx.outline_verts.items[ctx.outline_verts.items.len - 1].append(to) catch unreachable;
    }
}

fn lineToFunction(ctx: *OutlineContext, to: ft.Vector) ft.Error!void {
    // std.log.info("L {} {}", .{ to.x, to.y });

    // If inside_verts is not empty, we need to fill it
    if (ctx.inside_verts.items.len != 0) {
        ctx.inside_verts.append(.{ @as(f32, @floatFromInt(to.x)), @as(f32, @floatFromInt(to.y)) }) catch unreachable;
    } else {
        // Otherwise append the new point to the last polygon
        ctx.outline_verts.items[ctx.outline_verts.items.len - 1].append(.{ @as(f32, @floatFromInt(to.x)), @as(f32, @floatFromInt(to.y)) }) catch unreachable;
    }
}

/// Called to indicate that a quadratic bezier curve occured between the previous point on the glyph
/// outline to the `_to` point on the path, with the specified `_control` quadratic bezier control
/// point.
fn conicToFunction(ctx: *OutlineContext, _control: ft.Vector, _to: ft.Vector) ft.Error!void {
    // std.log.info("C {} {} {} {}", .{ control.x, control.y, to.x, to.y });
    const control = Vec2{ @as(f32, @floatFromInt(_control.x)), @as(f32, @floatFromInt(_control.y)) };
    const to = Vec2{ @as(f32, @floatFromInt(_to.x)), @as(f32, @floatFromInt(_to.y)) };

    // If our last point was inside the glyph (e.g. the hole in the letter 'o') then this is a
    // continuation of that path, and we should write this vertex to inside_verts. Otherwise we're
    // on the outside and the vertex should go in outline_verts.
    //
    // We derive if we're on the inside or outside based on whether inside_verts has items in it,
    // because only a lineTo callback can move us from the inside to the outside or vice-versa. A
    // quadratic bezier would *always* be the continuation of an inside or outside path.
    var verts_to_write = if (ctx.inside_verts.items.len != 0) &ctx.inside_verts else &ctx.outline_verts.items[ctx.outline_verts.items.len - 1];
    const previous_point = verts_to_write.items[verts_to_write.items.len - 1];

    var vertices = [_]Vec2{ control, to, previous_point };

    const vec1 = control - previous_point;
    const vec2 = to - control;

    // CCW (convex) or CW (concave)?
    if ((vec1[0] * vec2[1] - vec1[1] * vec2[0]) <= 0) {
        // Convex
        ctx.convex_vertices.appendSlice(&vertices) catch unreachable;
        verts_to_write.append(to) catch unreachable;
        return;
    }

    // Concave
    //
    // In this case, we need to write a vertex (for the filled triangle) to the quadratic
    // control point. However, since this is the concave case the control point could be outside
    // the shape itself. We need to ensure it is not, otherwise the triangle would end up filling
    // space outside the shape.
    //
    // Diagram: https://user-images.githubusercontent.com/3173176/189944586-bc1b109a-62c4-4ef5-a605-4c6a7e4a1abd.png
    //
    // To fix this, we must determine if the control point intersects with any of our outline
    // segments. If it does, we use that intersection point as the vertex. Otherwise, it doesn't go
    // past an outline segment and we can use the control point just fine.
    var intersection: ?Vec2 = null;
    for (ctx.outline_verts.items) |polygon| {
        var i: usize = 1;
        while (i < polygon.items.len) : (i += 1) {
            const v1 = polygon.items[i - 1];
            const v2 = polygon.items[i];
            if (vec2Equal(v1, previous_point) or vec2Equal(v1, control) or vec2Equal(v1, to) or vec2Equal(v2, previous_point) or vec2Equal(v2, control) or vec2Equal(v2, to)) continue;

            intersection = intersectLineSegments(v1, v2, previous_point, control);
            if (intersection != null) break;
        }
        if (intersection != null) break;
    }

    if (intersection) |intersect| {
        // TODO: properly scale control/intersection point a little bit towards the previous_point,
        // so our tessellator doesn't get confused about it being exactly on the path.
        //
        // TODO(gkurve): Moving this control point changes the bezier shape (obviously) which means
        // it is no longer true to the original shape. Need to fix this with some type of negative
        // border on the gkurve primitive.
        vertices[0] = Vec2{ intersect[0] * 0.99, intersect[1] * 0.99 };
    }
    ctx.concave_vertices.appendSlice(&vertices) catch unreachable;
    verts_to_write.append(vertices[0]) catch unreachable;
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

/// Intersects the line segments [p0, p1] and [p2, p3], returning the intersection point if any.
fn intersectLineSegments(p0: Vec2, p1: Vec2, p2: Vec2, p3: Vec2) ?Vec2 {
    const s1 = Vec2{ p1[0] - p0[0], p1[1] - p0[1] };
    const s2 = Vec2{ p3[0] - p2[0], p3[1] - p2[1] };
    const s = (-s1[1] * (p0[0] - p2[0]) + s1[0] * (p0[1] - p2[1])) / (-s2[0] * s1[1] + s1[0] * s2[1]);
    const t = (s2[0] * (p0[1] - p2[1]) - s2[1] * (p0[0] - p2[0])) / (-s2[0] * s1[1] + s1[0] * s2[1]);

    if (s >= 0 and s <= 1 and t >= 0 and t <= 1) {
        // Collision
        return Vec2{ p0[0] + (t * s1[0]), p0[1] + (t * s1[1]) };
    }
    return null; // No collision
}

fn intersectRayToLineSegment(ray_origin: Vec2, ray_direction: Vec2, p1: Vec2, p2: Vec2) ?Vec2 {
    return intersectLineSegments(ray_origin, ray_origin * (ray_direction * Vec2{ 10000000.0, 10000000.0 }), p1, p2);
}

fn vec2Equal(a: Vec2, b: Vec2) bool {
    return a[0] == b[0] and a[1] == b[1];
}

fn vec2CrossProduct(a: Vec2, b: Vec2) f32 {
    return (a[0] * b[1]) - (a[1] * b[0]);
}

fn pointInPolygon(p: Vec2, polygon: []std.ArrayList(Vec2)) bool {
    // Cast a ray to the right of the point and check
    // when this ray intersects the edges of the polygons,
    // if the number of intersections is odd -> inside,
    // if it's even -> outside
    var is_inside = false;
    for (polygon) |contour| {
        var i: usize = 1;
        while (i < contour.items.len) : (i += 1) {
            const v1 = contour.items[i - 1];
            const v2 = contour.items[i];

            if (intersectRayToLineSegment(p, Vec2{ 1, p[1] }, v1, v2)) |_| {
                is_inside = !is_inside;
            }
        }
    }
    return is_inside;
}
