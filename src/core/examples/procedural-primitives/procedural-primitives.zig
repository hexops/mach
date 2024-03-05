const std = @import("std");
const zmath = @import("zmath");

const PI = 3.1415927410125732421875;

pub const F32x3 = @Vector(3, f32);
pub const F32x4 = @Vector(4, f32);
pub const VertexData = struct {
    position: F32x3,
    normal: F32x3,
};

pub const PrimitiveType = enum(u4) { none, triangle, quad, plane, circle, uv_sphere, ico_sphere, cylinder, cone, torus };

pub const Primitive = struct {
    vertex_data: std.ArrayList(VertexData),
    vertex_count: u32,
    index_data: std.ArrayList(u32),
    index_count: u32,
    type: PrimitiveType = .none,
};

// 2D Primitives
pub fn createTrianglePrimitive(allocator: std.mem.Allocator, size: f32) !Primitive {
    const vertex_count = 3;
    const index_count = 3;
    var vertex_data = try std.ArrayList(VertexData).initCapacity(allocator, vertex_count);

    const edge = size / 2.0;

    vertex_data.appendSliceAssumeCapacity(&[vertex_count]VertexData{
        VertexData{ .position = F32x3{ -edge, -edge, 0.0 }, .normal = F32x3{ -edge, -edge, 0.0 } },
        VertexData{ .position = F32x3{ edge, -edge, 0.0 }, .normal = F32x3{ edge, -edge, 0.0 } },
        VertexData{ .position = F32x3{ 0.0, edge, 0.0 }, .normal = F32x3{ 0.0, edge, 0.0 } },
    });

    var index_data = try std.ArrayList(u32).initCapacity(allocator, index_count);
    index_data.appendSliceAssumeCapacity(&[index_count]u32{ 0, 1, 2 });

    return Primitive{ .vertex_data = vertex_data, .vertex_count = 3, .index_data = index_data, .index_count = 3, .type = .triangle };
}

pub fn createQuadPrimitive(allocator: std.mem.Allocator, size: f32) !Primitive {
    const vertex_count = 4;
    const index_count = 6;
    var vertex_data = try std.ArrayList(VertexData).initCapacity(allocator, vertex_count);

    const edge = size / 2.0;

    vertex_data.appendSliceAssumeCapacity(&[vertex_count]VertexData{
        VertexData{ .position = F32x3{ -edge, -edge, 0.0 }, .normal = F32x3{ -edge, -edge, 0.0 } },
        VertexData{ .position = F32x3{ edge, -edge, 0.0 }, .normal = F32x3{ edge, -edge, 0.0 } },
        VertexData{ .position = F32x3{ -edge, edge, 0.0 }, .normal = F32x3{ -edge, edge, 0.0 } },
        VertexData{ .position = F32x3{ edge, edge, 0.0 }, .normal = F32x3{ edge, edge, 0.0 } },
    });

    var index_data = try std.ArrayList(u32).initCapacity(allocator, index_count);
    index_data.appendSliceAssumeCapacity(&[index_count]u32{
        0, 1, 2,
        1, 3, 2,
    });

    return Primitive{ .vertex_data = vertex_data, .vertex_count = 4, .index_data = index_data, .index_count = 6, .type = .quad };
}

pub fn createPlanePrimitive(allocator: std.mem.Allocator, x_subdivision: u32, y_subdivision: u32, size: f32) !Primitive {
    const x_num_vertices = x_subdivision + 1;
    const y_num_vertices = y_subdivision + 1;
    const vertex_count = x_num_vertices * y_num_vertices;
    var vertex_data = try std.ArrayList(VertexData).initCapacity(allocator, vertex_count);

    const vertices_distance_y = (size / @as(f32, @floatFromInt(y_subdivision)));
    const vertices_distance_x = (size / @as(f32, @floatFromInt(x_subdivision)));
    var y: u32 = 0;
    while (y < y_num_vertices) : (y += 1) {
        var x: u32 = 0;
        const pos_y = (-size / 2.0) + @as(f32, @floatFromInt(y)) * vertices_distance_y;
        while (x < x_num_vertices) : (x += 1) {
            const pos_x = (-size / 2.0) + @as(f32, @floatFromInt(x)) * vertices_distance_x;
            vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ pos_x, pos_y, 0.0 }, .normal = F32x3{ pos_x, pos_y, 0.0 } });
        }
    }

    const index_count = x_subdivision * y_subdivision * 2 * 3;
    var index_data = try std.ArrayList(u32).initCapacity(allocator, index_count);

    y = 0;
    while (y < y_subdivision) : (y += 1) {
        var x: u32 = 0;
        while (x < x_subdivision) : (x += 1) {
            // First Triangle of Quad
            index_data.appendAssumeCapacity(x + y * y_num_vertices);
            index_data.appendAssumeCapacity(x + 1 + y * y_num_vertices);
            index_data.appendAssumeCapacity(x + (y + 1) * y_num_vertices);

            // Second Triangle of Quad
            index_data.appendAssumeCapacity(x + 1 + y * y_num_vertices);
            index_data.appendAssumeCapacity(x + (y + 1) * y_num_vertices + 1);
            index_data.appendAssumeCapacity(x + (y + 1) * y_num_vertices);
        }
    }

    return Primitive{ .vertex_data = vertex_data, .vertex_count = vertex_count, .index_data = index_data, .index_count = index_count, .type = .plane };
}

pub fn createCirclePrimitive(allocator: std.mem.Allocator, vertices: u32, radius: f32) !Primitive {
    const vertex_count = vertices + 1;
    var vertex_data = try std.ArrayList(VertexData).initCapacity(allocator, vertex_count);

    // Mid point of circle
    vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ 0, 0, 0.0 }, .normal = F32x3{ 0, 0, 0.0 } });

    var x: u32 = 0;
    const angle = 2 * PI / @as(f32, @floatFromInt(vertices));
    while (x < vertices) : (x += 1) {
        const x_f = @as(f32, @floatFromInt(x));
        const pos_x = radius * zmath.cos(angle * x_f);
        const pos_y = radius * zmath.sin(angle * x_f);

        vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ pos_x, pos_y, 0.0 }, .normal = F32x3{ pos_x, pos_y, 0.0 } });
    }

    const index_count = (vertices + 1) * 3;
    var index_data = try std.ArrayList(u32).initCapacity(allocator, index_count);

    x = 1;
    while (x <= vertices) : (x += 1) {
        index_data.appendAssumeCapacity(0);
        index_data.appendAssumeCapacity(x);
        index_data.appendAssumeCapacity(x + 1);
    }

    index_data.appendAssumeCapacity(0);
    index_data.appendAssumeCapacity(vertices);
    index_data.appendAssumeCapacity(1);

    return Primitive{ .vertex_data = vertex_data, .vertex_count = vertex_count, .index_data = index_data, .index_count = index_count, .type = .plane };
}

// 3D Primitives
pub fn createCubePrimitive(allocator: std.mem.Allocator, size: f32) !Primitive {
    const vertex_count = 8;
    const index_count = 36;
    var vertex_data = try std.ArrayList(VertexData).initCapacity(allocator, vertex_count);

    const edge = size / 2.0;

    vertex_data.appendSliceAssumeCapacity(&[vertex_count]VertexData{
        // Front positions
        VertexData{ .position = F32x3{ -edge, -edge, edge }, .normal = F32x3{ -edge, -edge, edge } },
        VertexData{ .position = F32x3{ edge, -edge, edge }, .normal = F32x3{ edge, -edge, edge } },
        VertexData{ .position = F32x3{ edge, edge, edge }, .normal = F32x3{ edge, edge, edge } },
        VertexData{ .position = F32x3{ -edge, edge, edge }, .normal = F32x3{ -edge, edge, edge } },
        // Back positions
        VertexData{ .position = F32x3{ -edge, -edge, -edge }, .normal = F32x3{ -edge, -edge, -edge } },
        VertexData{ .position = F32x3{ edge, -edge, -edge }, .normal = F32x3{ edge, -edge, -edge } },
        VertexData{ .position = F32x3{ edge, edge, -edge }, .normal = F32x3{ edge, edge, -edge } },
        VertexData{ .position = F32x3{ -edge, edge, -edge }, .normal = F32x3{ -edge, edge, -edge } },
    });

    var index_data = try std.ArrayList(u32).initCapacity(allocator, index_count);

    index_data.appendSliceAssumeCapacity(&[index_count]u32{
        // front quad
        0, 1, 2,
        2, 3, 0,
        // right quad
        1, 5, 6,
        6, 2, 1,
        // back quad
        7, 6, 5,
        5, 4, 7,
        // left quad
        4, 0, 3,
        3, 7, 4,
        // bottom quad
        4, 5, 1,
        1, 0, 4,
        // top quad
        3, 2, 6,
        6, 7, 3,
    });

    return Primitive{ .vertex_data = vertex_data, .vertex_count = vertex_count, .index_data = index_data, .index_count = index_count, .type = .quad };
}

const VertexDataMAL = std.MultiArrayList(VertexData);

pub fn createCylinderPrimitive(allocator: std.mem.Allocator, radius: f32, height: f32, num_sides: u32) !Primitive {
    const alloc_amt_vert: u32 = num_sides * 2 + 2;
    const alloc_amt_idx: u32 = num_sides * 12;

    var vertex_data = VertexDataMAL{};
    try vertex_data.ensureTotalCapacity(allocator, alloc_amt_vert);
    defer vertex_data.deinit(allocator);

    var out_vertex_data = try std.ArrayList(VertexData).initCapacity(allocator, alloc_amt_vert);
    var index_data = try std.ArrayList(u32).initCapacity(allocator, alloc_amt_idx);

    vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ 0.0, (height / 2.0), 0.0 }, .normal = undefined });
    vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ 0.0, -(height / 2.0), 0.0 }, .normal = undefined });

    const angle = 2.0 * PI / @as(f32, @floatFromInt(num_sides));

    for (1..num_sides + 1) |i| {
        const float_i = @as(f32, @floatFromInt(i));

        const x: f32 = radius * zmath.sin(angle * float_i);
        const y: f32 = radius * zmath.cos(angle * float_i);

        vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ x, (height / 2.0), y }, .normal = undefined });
        vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ x, -(height / 2.0), y }, .normal = undefined });
    }

    var group1: u32 = 1;
    var group2: u32 = 3;

    for (0..num_sides) |_| {
        if (group2 >= num_sides * 2) group2 = 1;
        index_data.appendSliceAssumeCapacity(&[_]u32{
            0,          group1 + 1, group2 + 1,
            group1 + 1, group1 + 2, group2 + 1,
            group1 + 2, group2 + 2, group2 + 1,
            group2 + 2, group1 + 2, 1,
        });
        group1 += 2;
        group2 += 2;
    }

    {
        var i: u32 = 0;
        while (i < alloc_amt_idx) : (i += 3) {
            const indexA: u32 = index_data.items[i];
            const indexB: u32 = index_data.items[i + 1];
            const indexC: u32 = index_data.items[i + 2];

            const vert1: F32x4 = F32x4{ vertex_data.get(indexA).position[0], vertex_data.get(indexA).position[1], vertex_data.get(indexA).position[2], 1.0 };
            const vert2: F32x4 = F32x4{ vertex_data.get(indexB).position[0], vertex_data.get(indexB).position[1], vertex_data.get(indexB).position[2], 1.0 };
            const vert3: F32x4 = F32x4{ vertex_data.get(indexC).position[0], vertex_data.get(indexC).position[1], vertex_data.get(indexC).position[2], 1.0 };

            const edgeAB: F32x4 = vert2 - vert1;
            const edgeAC: F32x4 = vert3 - vert1;

            const cross = zmath.cross3(edgeAB, edgeAC);

            vertex_data.items(.normal)[indexA][0] += cross[0];
            vertex_data.items(.normal)[indexA][1] += cross[1];
            vertex_data.items(.normal)[indexA][2] += cross[2];
            vertex_data.items(.normal)[indexB][0] += cross[0];
            vertex_data.items(.normal)[indexB][1] += cross[1];
            vertex_data.items(.normal)[indexB][2] += cross[2];
            vertex_data.items(.normal)[indexC][0] += cross[0];
            vertex_data.items(.normal)[indexC][1] += cross[1];
            vertex_data.items(.normal)[indexC][2] += cross[2];
        }
    }

    for (vertex_data.items(.position), vertex_data.items(.normal)) |pos, nor| {
        out_vertex_data.appendAssumeCapacity(VertexData{ .position = pos, .normal = nor });
    }

    return Primitive{ .vertex_data = out_vertex_data, .vertex_count = alloc_amt_vert, .index_data = index_data, .index_count = alloc_amt_idx, .type = .cylinder };
}

pub fn createConePrimitive(allocator: std.mem.Allocator, radius: f32, height: f32, num_sides: u32) !Primitive {
    const alloc_amt_vert: u32 = num_sides + 2;
    const alloc_amt_idx: u32 = num_sides * 6;

    var vertex_data = VertexDataMAL{};
    try vertex_data.ensureTotalCapacity(allocator, alloc_amt_vert);
    defer vertex_data.deinit(allocator);

    var out_vertex_data = try std.ArrayList(VertexData).initCapacity(allocator, alloc_amt_vert);
    var index_data = try std.ArrayList(u32).initCapacity(allocator, alloc_amt_idx);

    vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ 0.0, (height / 2.0), 0.0 }, .normal = undefined });
    vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ 0.0, -(height / 2.0), 0.0 }, .normal = undefined });

    const angle = 2.0 * PI / @as(f32, @floatFromInt(num_sides));

    for (1..num_sides + 1) |i| {
        const float_i = @as(f32, @floatFromInt(i));

        const x: f32 = radius * zmath.sin(angle * float_i);
        const y: f32 = radius * zmath.cos(angle * float_i);

        vertex_data.appendAssumeCapacity(VertexData{ .position = F32x3{ x, -(height / 2.0), y }, .normal = undefined });
    }

    var group1: u32 = 1;
    var group2: u32 = 2;

    for (0..num_sides) |_| {
        if (group2 >= num_sides + 1) group2 = 1;
        index_data.appendSliceAssumeCapacity(&[_]u32{
            0,          group1 + 1, group2 + 1,
            group2 + 1, group1 + 1, 1,
        });
        group1 += 1;
        group2 += 1;
    }

    {
        var i: u32 = 0;
        while (i < alloc_amt_idx) : (i += 3) {
            const indexA: u32 = index_data.items[i];
            const indexB: u32 = index_data.items[i + 1];
            const indexC: u32 = index_data.items[i + 2];

            const vert1: F32x4 = F32x4{ vertex_data.get(indexA).position[0], vertex_data.get(indexA).position[1], vertex_data.get(indexA).position[2], 1.0 };
            const vert2: F32x4 = F32x4{ vertex_data.get(indexB).position[0], vertex_data.get(indexB).position[1], vertex_data.get(indexB).position[2], 1.0 };
            const vert3: F32x4 = F32x4{ vertex_data.get(indexC).position[0], vertex_data.get(indexC).position[1], vertex_data.get(indexC).position[2], 1.0 };

            const edgeAB: F32x4 = vert2 - vert1;
            const edgeAC: F32x4 = vert3 - vert1;

            const cross = zmath.cross3(edgeAB, edgeAC);

            vertex_data.items(.normal)[indexA][0] += cross[0];
            vertex_data.items(.normal)[indexA][1] += cross[1];
            vertex_data.items(.normal)[indexA][2] += cross[2];
            vertex_data.items(.normal)[indexB][0] += cross[0];
            vertex_data.items(.normal)[indexB][1] += cross[1];
            vertex_data.items(.normal)[indexB][2] += cross[2];
            vertex_data.items(.normal)[indexC][0] += cross[0];
            vertex_data.items(.normal)[indexC][1] += cross[1];
            vertex_data.items(.normal)[indexC][2] += cross[2];
        }
    }

    for (vertex_data.items(.position), vertex_data.items(.normal)) |pos, nor| {
        out_vertex_data.appendAssumeCapacity(VertexData{ .position = pos, .normal = nor });
    }

    return Primitive{ .vertex_data = out_vertex_data, .vertex_count = alloc_amt_vert, .index_data = index_data, .index_count = alloc_amt_idx, .type = .cone };
}
