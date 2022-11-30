const std = @import("std");

/// Vertex writer manages the placement of vertices by tracking which are unique. If a duplicate vertex is added
/// with `put`, only it's index will be written to the index buffer.
/// `IndexType` should match the integer type used for the index buffer
pub fn VertexWriter(comptime VertexType: type, comptime IndexType: type) type {
    return struct {
        const MapEntry = struct {
            packed_index: IndexType = null_index,
            next_sparse: IndexType = null_index,
        };

        const null_index: IndexType = std.math.maxInt(IndexType);

        vertices: []VertexType,
        indices: []IndexType,
        sparse_to_packed_map: []MapEntry,

        /// Next index outside of the 1:1 mapping range for storing
        /// position -> normal collisions
        next_collision_index: IndexType,

        /// Next packed index
        next_packed_index: IndexType,
        written_indices_count: IndexType,

        /// Allocate storage and set default values
        /// `sparse_vertices_count` is the number of vertices in the source before de-duplication / remapping
        /// Put more succinctly, the largest index value in source index buffer
        /// `max_vertex_count` is largest permutation of vertices assuming that {vertex, uv, normal} never map 1:1 and always
        /// create a new mapping
        pub fn init(
            allocator: std.mem.Allocator,
            indices_count: IndexType,
            sparse_vertices_count: IndexType,
            max_vertex_count: IndexType,
        ) !@This() {
            var result: @This() = undefined;
            result.vertices = try allocator.alloc(VertexType, max_vertex_count);
            result.indices = try allocator.alloc(IndexType, indices_count);
            result.sparse_to_packed_map = try allocator.alloc(MapEntry, max_vertex_count);
            result.next_collision_index = sparse_vertices_count;
            result.next_packed_index = 0;
            result.written_indices_count = 0;
            std.mem.set(MapEntry, result.sparse_to_packed_map, .{});
            return result;
        }

        pub fn put(self: *@This(), vertex: VertexType, sparse_index: IndexType) void {
            if (self.sparse_to_packed_map[sparse_index].packed_index == null_index) {
                // New start of chain, reserve a new packed index and add entry to `index_map`
                const packed_index = self.next_packed_index;
                self.sparse_to_packed_map[sparse_index].packed_index = packed_index;
                self.vertices[packed_index] = vertex;
                self.indices[self.written_indices_count] = packed_index;
                self.written_indices_count += 1;
                self.next_packed_index += 1;
                return;
            }
            var previous_sparse_index: IndexType = undefined;
            var current_sparse_index = sparse_index;
            while (current_sparse_index != null_index) {
                const packed_index = self.sparse_to_packed_map[current_sparse_index].packed_index;
                if (std.mem.eql(u8, &std.mem.toBytes(self.vertices[packed_index]), &std.mem.toBytes(vertex))) {
                    // We already have a record for this vertex in our chain
                    self.indices[self.written_indices_count] = packed_index;
                    self.written_indices_count += 1;
                    return;
                }
                previous_sparse_index = current_sparse_index;
                current_sparse_index = self.sparse_to_packed_map[current_sparse_index].next_sparse;
            }
            // This is a new mapping for the given sparse index
            const packed_index = self.next_packed_index;
            const remapped_sparse_index = self.next_collision_index;
            self.indices[self.written_indices_count] = packed_index;
            self.vertices[packed_index] = vertex;
            self.sparse_to_packed_map[previous_sparse_index].next_sparse = remapped_sparse_index;
            self.sparse_to_packed_map[remapped_sparse_index].packed_index = packed_index;
            self.next_packed_index += 1;
            self.next_collision_index += 1;
            self.written_indices_count += 1;
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.vertices);
            allocator.free(self.indices);
            allocator.free(self.sparse_to_packed_map);
        }

        pub fn indexBuffer(self: @This()) []IndexType {
            return self.indices;
        }

        pub fn vertexBuffer(self: @This()) []VertexType {
            return self.vertices[0..self.next_packed_index];
        }
    };
}

test "VertexWriter" {
    const Vec3 = [3]f32;
    const Vertex = extern struct {
        position: Vec3,
        normal: Vec3,
    };

    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    const Face = struct {
        position: [3]u16,
        normal: [3]u16,
    };

    const vertices = [_]Vec3{
        Vec3{ 1.0, 0.0, 0.0 }, // 0: Position
        Vec3{ 2.0, 0.0, 0.0 }, // 1: Position
        Vec3{ 3.0, 0.0, 0.0 }, // 2: Position
        Vec3{ 1.0, 0.0, 0.0 }, // 3: Normal
        Vec3{ 4.0, 0.0, 0.0 }, // 4: Position
        Vec3{ 0.0, 1.0, 0.0 }, // 5: Normal
        Vec3{ 5.0, 0.0, 0.0 }, // 6: Position
        Vec3{ 0.0, 0.0, 1.0 }, // 7: Normal
        Vec3{ 1.0, 0.0, 1.0 }, // 8: Normal
        Vec3{ 6.0, 0.0, 0.0 }, // 9: Position
    };

    const faces = [_]Face{
        .{ .position = .{ 0, 4, 2 }, .normal = .{ 7, 5, 3 } },
        .{ .position = .{ 2, 3, 9 }, .normal = .{ 3, 7, 8 } },
        .{ .position = .{ 9, 2, 4 }, .normal = .{ 8, 7, 5 } },
        .{ .position = .{ 2, 6, 1 }, .normal = .{ 3, 5, 7 } },
        .{ .position = .{ 9, 6, 0 }, .normal = .{ 5, 7, 8 } },
    };

    var writer = try VertexWriter(Vertex, u32).init(
        allocator,
        faces.len * 3, // indices count
        vertices.len, // original vertices count
        faces.len * 3, // maximum vertices count
    );
    defer writer.deinit(allocator);

    for (faces) |face| {
        var x: usize = 0;
        while (x < 3) : (x += 1) {
            const position_index = face.position[x];
            const position = vertices[position_index];
            const normal = vertices[face.normal[x]];
            const vertex = Vertex{
                .position = position,
                .normal = normal,
            };
            writer.put(vertex, position_index);
        }
    }

    const indices = writer.indexBuffer();
    try expect(indices.len == faces.len * 3);

    // Face 0
    try expect(indices[0] == 0); // (0, 7) New
    try expect(indices[1] == 1); // (4, 5) New
    try expect(indices[2] == 2); // (2, 3) New

    // Face 1
    try expect(indices[3 + 0] == 2); // (2, 3) Duplicate - Reuse index
    try expect(indices[3 + 1] == 3); // (3, 7) New
    try expect(indices[3 + 2] == 4); // (9, 8) New

    // Face 2
    try expect(indices[6 + 0] == 4); // (9, 8) Duplicate - Reuse index
    try expect(indices[6 + 1] == 5); // (2, 7) New normal mapping (Don't clobber)
    try expect(indices[6 + 2] == 1); // (4, 5) Duplicate - Reuse Index

    // Face 3
    try expect(indices[9 + 0] == 2); // (2, 3) Duplicate - Reuse index
    try expect(indices[9 + 1] == 6); // (6, 5) New
    try expect(indices[9 + 2] == 7); // (1, 7) New

    // Face 4
    try expect(indices[12 + 0] == 8); // (9, 5) New normal mapping (Don't clobber)
    try expect(indices[12 + 1] == 9); // (6, 7) New normal mapping (Don't clobber)
    try expect(indices[12 + 2] == 10); // (0, 8) New normal mapping (Don't clobber)

    try expect(writer.vertexBuffer().len == 11);
}
