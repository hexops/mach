const std = @import("std");
const ArrayList = std.ArrayList;
const gpu = @import("gpu");
const App = @import("main.zig").App;
const zm = @import("zmath");

pub const Vertex = struct {
    pos: @Vector(4, f32),
    uv: @Vector(2, f32),
};
const VERTEX_ATTRIBUTES = [_]gpu.VertexAttribute{
    .{ .format = .float32x4, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 },
    .{ .format = .float32x2, .offset = @offsetOf(Vertex, "uv"), .shader_location = 1 },
};
pub const VERTEX_BUFFER_LAYOUT = gpu.VertexBufferLayout{
    .array_stride = @sizeOf(Vertex),
    .step_mode = .vertex,
    .attribute_count = VERTEX_ATTRIBUTES.len,
    .attributes = &VERTEX_ATTRIBUTES,
};
pub const VertexUniform = struct {
    mat: zm.Mat,
};

const GkurveType = enum(u32) {
    concave = 0,
    convex = 1,
    filled = 2,
};

pub const FragUniform = struct {
    type: GkurveType = .filled,
    texture_index: i32 = 0,
    // Padding for struct alignment to 16 bytes (minimum in WebGPU uniform).
    padding: @Vector(2, f32) = undefined,
    blend_color: @Vector(4, f32) = @Vector(4, f32){ 1, 1, 1, 1 },
};

pub fn equilateralTriangle(app: *App, position: @Vector(2, f32), scale: f32, uniform: FragUniform) !void {
    const triangle_height = scale * @sqrt(0.75);

    try app.vertices.appendSlice(&[3]Vertex{
        .{ .pos = .{ position[0] + scale / 2, position[1] + triangle_height, 0, 1 }, .uv = .{ 0.5, 1 } },
        .{ .pos = .{ position[0], position[1], 0, 1 }, .uv = .{ 0, 0 } },
        .{ .pos = .{ position[0] + scale, position[1], 0, 1 }, .uv = .{ 1, 0 } },
    });

    try app.fragment_uniform_list.append(uniform);

    app.update_vertex_buffer = true;
    app.update_frag_uniform_buffer = true;
}

pub fn quad(app: *App, position: @Vector(2, f32), scale: @Vector(2, f32), uniform: FragUniform) !void {
    try app.vertices.appendSlice(&[6]Vertex{
        .{ .pos = .{ position[0], position[1] + scale[1], 0, 1 }, .uv = .{ 0, 1 } },
        .{ .pos = .{ position[0], position[1], 0, 1 }, .uv = .{ 0, 0 } },
        .{ .pos = .{ position[0] + scale[0], position[1], 0, 1 }, .uv = .{ 1, 0 } },

        .{ .pos = .{ position[0], position[1] + scale[1], 0, 1 }, .uv = .{ 0, 1 } },
        .{ .pos = .{ position[0] + scale[0], position[1] + scale[1], 0, 1 }, .uv = .{ 1, 1 } },
        .{ .pos = .{ position[0] + scale[0], position[1], 0, 1 }, .uv = .{ 1, 0 } },
    });

    try app.fragment_uniform_list.appendSlice(&.{ uniform, uniform });

    app.update_vertex_buffer = true;
    app.update_frag_uniform_buffer = true;
}

pub fn circle(app: *App, position: @Vector(2, f32), radius: f32, blend_color: @Vector(4, f32)) !void {
    const Vec4 = @Vector(4, f32);
    const low_mid = Vec4{ position[0], position[1] - radius, 0, 1 };
    const high_mid = Vec4{ position[0], position[1] + radius, 0, 1 };

    const mid_left = Vec4{ position[0] - radius, position[1], 0, 1 };
    const mid_right = Vec4{ position[0] + radius, position[1], 0, 1 };

    const p = 0.95 * radius;

    const high_right = Vec4{ position[0] + p, position[1] + p, 0, 1 };
    const high_left = Vec4{ position[0] - p, position[1] + p, 0, 1 };
    const low_right = Vec4{ position[0] + p, position[1] - p, 0, 1 };
    const low_left = Vec4{ position[0] - p, position[1] - p, 0, 1 };

    // TODO: Fix UVs
    try app.vertices.appendSlice(&[_]Vertex{
        .{ .pos = low_mid, .uv = .{ 0.5, 0 } },
        .{ .pos = mid_right, .uv = .{ 0.5, 0 } },
        .{ .pos = high_mid, .uv = .{ 0.5, 0 } },

        .{ .pos = high_mid, .uv = .{ 0.5, 0 } },
        .{ .pos = mid_left, .uv = .{ 0.5, 0 } },
        .{ .pos = low_mid, .uv = .{ 0.5, 0 } },

        .{ .pos = low_right, .uv = .{ 0.5, 0 } },
        .{ .pos = mid_right, .uv = .{ 0.5, 0 } },
        .{ .pos = low_mid, .uv = .{ 0.5, 0 } },

        .{ .pos = high_right, .uv = .{ 0.5, 0 } },
        .{ .pos = high_mid, .uv = .{ 0.5, 0 } },
        .{ .pos = mid_right, .uv = .{ 0.5, 0 } },

        .{ .pos = high_left, .uv = .{ 0.5, 0 } },
        .{ .pos = mid_left, .uv = .{ 0.5, 0 } },
        .{ .pos = high_mid, .uv = .{ 0.5, 0 } },

        .{ .pos = low_left, .uv = .{ 0.5, 0 } },
        .{ .pos = low_mid, .uv = .{ 0.5, 0 } },
        .{ .pos = mid_left, .uv = .{ 0.5, 0 } },
    });

    try app.fragment_uniform_list.appendSlice(&[_]FragUniform{
        .{
            .type = .filled,
            .blend_color = blend_color,
        },
        .{
            .type = .filled,
            .blend_color = blend_color,
        },
        .{
            .type = .convex,
            .blend_color = blend_color,
        },
        .{
            .type = .convex,
            .blend_color = blend_color,
        },
        .{
            .type = .convex,
            .blend_color = blend_color,
        },
        .{
            .type = .convex,
            .blend_color = blend_color,
        },
    });

    app.update_vertex_buffer = true;
    app.update_frag_uniform_buffer = true;
}
