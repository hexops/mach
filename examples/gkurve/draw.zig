const std = @import("std");
const ArrayList = std.ArrayList;
const gpu = @import("gpu");
const App = @import("main.zig").App;
const zm = @import("zmath");
const UVData = @import("atlas.zig").UVData;

const Vec2 = @Vector(2, f32);

pub const Vertex = struct {
    pos: @Vector(4, f32),
    uv: Vec2,
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
    // Padding for struct alignment to 16 bytes (minimum in WebGPU uniform).
    padding: @Vector(3, f32) = undefined,
    blend_color: @Vector(4, f32) = @Vector(4, f32){ 1, 1, 1, 1 },
};

pub fn equilateralTriangle(app: *App, position: Vec2, scale: f32, uniform: FragUniform, uv_data: UVData) !void {
    const triangle_height = scale * @sqrt(0.75);

    try app.vertices.appendSlice(&[3]Vertex{
        .{ .pos = .{ position[0] + scale / 2, position[1] + triangle_height, 0, 1 }, .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 0.5, 1 } },
        .{ .pos = .{ position[0], position[1], 0, 1 }, .uv = uv_data.bottom_left },
        .{ .pos = .{ position[0] + scale, position[1], 0, 1 }, .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 1, 0 } },
    });

    try app.fragment_uniform_list.append(uniform);

    app.update_vertex_buffer = true;
    app.update_frag_uniform_buffer = true;
}

pub fn quad(app: *App, position: Vec2, scale: Vec2, uniform: FragUniform, uv_data: UVData) !void {
    const bottom_right_uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 1, 0 };
    const up_left_uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 0, 1 };
    const up_right_uv = uv_data.bottom_left + uv_data.width_and_height;

    try app.vertices.appendSlice(&[6]Vertex{
        .{ .pos = .{ position[0], position[1] + scale[1], 0, 1 }, .uv = up_left_uv },
        .{ .pos = .{ position[0], position[1], 0, 1 }, .uv = uv_data.bottom_left },
        .{ .pos = .{ position[0] + scale[0], position[1], 0, 1 }, .uv = bottom_right_uv },

        .{ .pos = .{ position[0] + scale[0], position[1] + scale[1], 0, 1 }, .uv = up_right_uv },
        .{ .pos = .{ position[0], position[1] + scale[1], 0, 1 }, .uv = up_left_uv },
        .{ .pos = .{ position[0] + scale[0], position[1], 0, 1 }, .uv = bottom_right_uv },
    });

    try app.fragment_uniform_list.appendSlice(&.{ uniform, uniform });

    app.update_vertex_buffer = true;
    app.update_frag_uniform_buffer = true;
}

pub fn circle(app: *App, position: Vec2, radius: f32, blend_color: @Vector(4, f32), uv_data: UVData) !void {
    const low_mid = Vertex{
        .pos = .{ position[0], position[1] - radius, 0, 1 },
        .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 0.5, 0 },
    };
    const high_mid = Vertex{
        .pos = .{ position[0], position[1] + radius, 0, 1 },
        .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 0.5, 1 },
    };

    const mid_left = Vertex{
        .pos = .{ position[0] - radius, position[1], 0, 1 },
        .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 0, 0.5 },
    };
    const mid_right = Vertex{
        .pos = .{ position[0] + radius, position[1], 0, 1 },
        .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 1, 0.5 },
    };

    const p = 0.95 * radius;

    const high_right = Vertex{
        .pos = .{ position[0] + p, position[1] + p, 0, 1 },
        .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 1, 0.75 },
    };
    const high_left = Vertex{
        .pos = .{ position[0] - p, position[1] + p, 0, 1 },
        .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 0, 0.75 },
    };
    const low_right = Vertex{
        .pos = .{ position[0] + p, position[1] - p, 0, 1 },
        .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 1, 0.25 },
    };
    const low_left = Vertex{
        .pos = .{ position[0] - p, position[1] - p, 0, 1 },
        .uv = uv_data.bottom_left + uv_data.width_and_height * Vec2{ 0, 0.25 },
    };

    try app.vertices.appendSlice(&[_]Vertex{
        low_mid,
        mid_right,
        high_mid,

        high_mid,
        mid_left,
        low_mid,

        low_right,
        mid_right,
        low_mid,

        high_right,
        high_mid,
        mid_right,

        high_left,
        mid_left,
        high_mid,

        low_left,
        low_mid,
        mid_left,
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
