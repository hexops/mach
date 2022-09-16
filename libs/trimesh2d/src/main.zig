const std = @import("std");

/// Returns a trimesh2d processor, which can reuse its internal buffers to process multiple polygons
/// (call reset between process calls.) The type T denotes e.g. f16, f32, or f64 vertices.
pub fn Processor(comptime T: type) type {
    return struct {
        const Vec2 = @Vector(2, T);

        // Doubly linked list for fast polygon inspection
        prev: std.ArrayListUnmanaged(u32) = .{},
        next: std.ArrayListUnmanaged(u32) = .{},

        // A list of the ears to be cut
        ears: std.ArrayListUnmanaged(u32) = .{},

        // Keeps track of ears (corners that were not ears at the beginning may become so later on.)
        is_ear: std.ArrayListUnmanaged(bool) = .{},

        /// Resets the processor, clearing the internal buffers and preparing it for processing a
        /// new polygon.
        pub fn reset(self: *@This()) void {
            self.prev.clearRetainingCapacity();
            self.next.clearRetainingCapacity();
            self.ears.clearRetainingCapacity();
            self.is_ear.clearRetainingCapacity();
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            self.prev.deinit(allocator);
            self.next.deinit(allocator);
            self.ears.deinit(allocator);
            self.is_ear.deinit(allocator);
        }

        /// Processes a simple polygon (no holes) into triangles in linear time, writing the
        /// triangles to out_triangles (indices into polygon vertices list.)
        ///
        /// The polygons must be sorted in counter-clockwise order.
        pub fn process(
            self: *@This(),
            allocator: std.mem.Allocator,
            // TODO(trimesh2d): make this a slice?
            polygon: std.ArrayListUnmanaged(Vec2),
            out_triangles: *std.ArrayListUnmanaged(u32),
        ) error{OutOfMemory}!void {
            if (polygon.items.len < 3) {
                return;
            }

            // Ensure our doubly linked list and ears list are large enough.
            const size = polygon.items.len;
            try self.prev.resize(allocator, size);
            try self.next.resize(allocator, size);
            try self.ears.ensureTotalCapacity(allocator, size);
            try self.is_ear.resize(allocator, size);
            for (self.is_ear.items) |*v| v.* = false;

            // Fill prev list with prior-index values, e.g.:
            // [4, 0, 1, 2, 3]
            for (self.prev.items) |_, i| self.prev.items[i] = @intCast(u32, if (i == 0) size - 1 else i - 1);

            // Fill next list with next-index values, e.g.:
            // [1, 2, 3, 4, 0]
            for (self.next.items) |_, i| self.next.items[i] = @intCast(u32, if (i == size - 1) 0 else i + 1);

            // Detect all safe ears in O(n).
            // This amounts to finding all convex vertices but the endpoints of the constrained edge
            var curr: u32 = 1;
            while (curr < size - 1) : (curr += 1) {
                // NOTE: the polygon may contain dangling edges
                if (orient2d(
                    polygon.items[self.prev.items[curr]],
                    polygon.items[curr],
                    polygon.items[self.next.items[curr]],
                ) > 0) {
                    try self.ears.append(allocator, curr);
                    self.is_ear.items[curr] = true;
                }
            }

            // Progressively delete all ears, updating the data structure
            while (self.ears.items.len > 0) {
                curr = self.ears.pop();

                // make new tri
                try out_triangles.append(allocator, self.prev.items[curr]);
                try out_triangles.append(allocator, curr);
                try out_triangles.append(allocator, self.next.items[curr]);

                // exclude curr from the polygon, connecting prev and next
                self.next.items[self.prev.items[curr]] = self.next.items[curr];
                self.prev.items[self.next.items[curr]] = self.prev.items[curr];

                // check if prev and next have become new ears
                if (!self.is_ear.items[self.prev.items[curr]] and self.prev.items[curr] != 0) {
                    if (self.prev.items[self.prev.items[curr]] != self.next.items[curr] and orient2d(
                        polygon.items[self.prev.items[self.prev.items[curr]]],
                        polygon.items[self.prev.items[curr]],
                        polygon.items[self.next.items[curr]],
                    ) > 0) {
                        try self.ears.append(allocator, self.prev.items[curr]);
                        self.is_ear.items[self.prev.items[curr]] = true;
                    }
                }
                if (!self.is_ear.items[self.next.items[curr]] and self.next.items[curr] < size - 1) {
                    if (self.next.items[self.next.items[curr]] != self.prev.items[curr] and orient2d(
                        polygon.items[self.prev.items[curr]],
                        polygon.items[self.next.items[curr]],
                        polygon.items[self.next.items[self.next.items[curr]]],
                    ) > 0) {
                        try self.ears.append(allocator, self.next.items[curr]);
                        self.is_ear.items[self.next.items[curr]] = true;
                    }
                }
            }
        }

        pub fn sort(allocator: std.mem.Allocator, polygon: std.ArrayListUnmanaged(Vec2)) !std.ArrayListUnmanaged(Vec2) {
            var max_dist: f32 = 0;
            var extrema_start: usize = undefined;
            var extrema_end: usize = undefined;
            var i: usize = 0;
            while (i < polygon.items.len) : (i += 1) {
                var next_index = (i + 1) % polygon.items.len;
                var p0 = polygon.items[i];
                var p1 = polygon.items[next_index];
                var dist = std.math.hypot(T, p1[0] - p0[0], p1[1] - p0[1]);
                if (dist > max_dist) {
                    max_dist = dist;
                    extrema_start = i;
                    extrema_end = next_index;
                }
            }

            var sorted = std.ArrayListUnmanaged(Vec2){};
            i = extrema_end;
            while (i < polygon.items.len) : (i += 1) try sorted.append(allocator, polygon.items[i]);
            i = 0;
            while (i <= extrema_start) : (i += 1) try sorted.append(allocator, polygon.items[i]);
            return sorted;
        }

        /// Inexact geometric predicate.
        /// Basically Shewchuk's orient2dfast()
        fn orient2d(
            pa: Vec2,
            pb: Vec2,
            pc: Vec2,
        ) T {
            const acx = pa[0] - pc[0];
            const bcx = pb[0] - pc[0];
            const acy = pa[1] - pc[1];
            const bcy = pb[1] - pc[1];
            return acx * bcy - acy * bcx;
        }
    };
}

test "simple" {
    const allocator = std.testing.allocator;
    const Vec2 = @Vector(2, f32);

    var polygon = std.ArrayListUnmanaged(Vec2){};
    defer polygon.deinit(allocator);
    // CCW
    try polygon.append(allocator, Vec2{ 0.0, 0.0 }); // bottom-left
    try polygon.append(allocator, Vec2{ 1.0, 0.0 }); // bottom-right
    try polygon.append(allocator, Vec2{ 1.0, 1.0 }); // top-right
    try polygon.append(allocator, Vec2{ 0.0, 1.0 }); // top-left

    var out_triangles = std.ArrayListUnmanaged(u32){};
    defer out_triangles.deinit(allocator);
    var processor = Processor(f32){};
    defer processor.deinit(allocator);

    // Process a polygon.
    try processor.process(allocator, polygon, &out_triangles);

    // out_triangles has indices into polygon.items of our triangle vertices.
    // If desired, call .reset() and call .process() again! Internal buffers will be reused.
    try std.testing.expectEqual(@as(usize, 6), out_triangles.items.len);
    try std.testing.expectEqual(@as(u32, 1), out_triangles.items[0]); // bottom-right
    try std.testing.expectEqual(@as(u32, 2), out_triangles.items[1]); // top-right
    try std.testing.expectEqual(@as(u32, 3), out_triangles.items[2]); // top-left
    try std.testing.expectEqual(@as(u32, 0), out_triangles.items[3]); // bottom-left
    try std.testing.expectEqual(@as(u32, 1), out_triangles.items[4]); // bottom-right
    try std.testing.expectEqual(@as(u32, 3), out_triangles.items[5]); // top-left
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
