const std = @import("std");
const pow = std.math.pow;
const sqrt = std.math.sqrt;

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

            // var length: usize = size;
            var begin: usize = 0;
            while (true) {
                // length -= 1;
                // if (length < 3) return; // last triangle

                // Find the convex ear in the polygon that has the shortest distance between two
                // vertices we would need to connect in order to clip the ear.
                var ear: u32 = undefined;
                var min_dist = std.math.floatMax(T);
                var i: u32 = @intCast(u32, begin);
                var found: bool = false;
                while (true) {
                    const prev = self.prev.items[i];
                    const next = self.next.items[i];
                    if (orient2d(polygon.items[prev], polygon.items[i], polygon.items[next]) > 0) {
                        // Convex
                        // const d = dist(polygon.items[prev], polygon.items[next]);
                        const d = triangleArea(polygon.items[prev], polygon.items[i], polygon.items[next]);
                        if (d < min_dist) {
                            // Smaller distance.
                            min_dist = d;
                            ear = i;
                            found = true;
                        }
                    }
                    if (next == begin) break;
                    i = next;
                }
                if (!found) return;
                if (begin == ear) begin = self.next.items[ear];

                // Clip this ear.

                // Create the triangle.
                try out_triangles.append(allocator, self.prev.items[ear]);
                try out_triangles.append(allocator, ear);
                try out_triangles.append(allocator, self.next.items[ear]);

                // Exclude the ear vertex from the polygon, connecting prev and next.
                self.next.items[self.prev.items[ear]] = self.next.items[ear];
                self.prev.items[self.next.items[ear]] = self.prev.items[ear];
            }
        }

        fn dist(p0: Vec2, p1: Vec2) T {
            return std.math.hypot(T, p1[0] - p0[0], p1[1] - p0[1]);
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

        fn triangleArea(a: Vec2, b: Vec2, c: Vec2) T {
            const l1 = sqrt(pow(T, a[0] - b[0], 2) + pow(T, a[1] - b[1], 2));
            const l2 = sqrt(pow(T, b[0] - c[0], 2) + pow(T, b[1] - c[1], 2));
            const l3 = sqrt(pow(T, c[0] - a[0], 2) + pow(T, c[1] - a[1], 2));
            const p = (l1 + l2 + l3) / 2;
            return sqrt(p * (p - l1) * (p - l2) * (p - l3));
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
    try std.testing.expectEqual(@as(u32, 3), out_triangles.items[0]); // top-left
    try std.testing.expectEqual(@as(u32, 0), out_triangles.items[1]); // bottom-left
    try std.testing.expectEqual(@as(u32, 1), out_triangles.items[2]); // bottom-right
    try std.testing.expectEqual(@as(u32, 3), out_triangles.items[3]); // top-left
    try std.testing.expectEqual(@as(u32, 1), out_triangles.items[4]); // bottom-right
    try std.testing.expectEqual(@as(u32, 2), out_triangles.items[5]); // top-right
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
