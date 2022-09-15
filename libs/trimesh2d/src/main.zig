const std = @import("std");

/// Returns a trimesh2d processor, which can reuse its internal buffers to process multiple polygons
/// (call reset between process calls.) The type T denotes e.g. f16, f32, or f64 vertices.
pub fn Processor(comptime T: type) type {
    return struct {
        // Doubly linked list for fast polygon inspection
        prev: std.ArrayListUnmanaged(u32) = .{},
        next: std.ArrayListUnmanaged(u32) = .{},

        // A list of the ears to be cut
        ears: std.ArrayListUnmanaged(u32) = .{},

        // Keeps track of ears (corners that were not ears at the beginning may become so later on.)
        is_ear: std.ArrayListUnmanaged(bool) = .{},

        /// Resets the processor, clearing the internal buffers and preparing it for processing a
        /// new polygon.
        pub fn reset(self: *Processor) void {
            self.prev.clearRetainingCapacity();
            self.next.clearRetainingCapacity();
            self.ears.clearRetainingCapacity();
            self.is_ear.clearRetainingCapacity();
        }

        pub fn deinit(self: *Processor, allocator: std.mem.Allocator) void {
            self.prev.deinit(allocator);
            self.next.deinit(allocator);
            self.ears.deinit(allocator);
            self.is_ear.deinit(allocator);
        }

        /// Processes a simple polygon (no holes) into triangles in linear time, writing the
        /// triangles to out_triangles (indices into polygon vertices list.)
        pub fn process(
            self: *Processor,
            allocator: std.mem.Allocator,
            polygon: std.ArrayListUnmanaged(T),
            out_triangles: *std.ArrayListUnmanaged(u32),
        ) error{OutOfMemory}!void {
            if (polygon.len < 3) {
                return;
            }

            // Ensure our doubly linked list and ears list are large enough.
            const size = polygon.len;
            try self.prev.ensureTotalCapacity(allocator, size);
            try self.next.ensureTotalCapacity(allocator, size);
            try self.ears.ensureTotalCapacity(allocator, size);
            try self.is_ear.resize(allocator, size);

            // Fill prev list with prior-index values, e.g.:
            // [4, 0, 1, 2, 3]
            for (self.prev.items) |_, i| self.prev.items[i] = if (i == 0) size - 1 else i - 1;

            // Fill next list with next-index values, e.g.:
            // [1, 2, 3, 4, 0]
            for (self.prev.items) |_, i| self.prev.items[i] = if (i == self.prev.items.len - 1) size - 1 else i + 1;

            // Detect all safe ears in O(n).
            // This amounts to finding all convex vertices but the endpoints of the constrained edge
            var curr: u32 = 1;
            while (cur < size - 1) : (curr += 1) {
                // NOTE: the polygon may contain dangling edges, so !arrayListElementsEqual(prev, next)
                // avoids need to even do the more expensive ear test for them below.
                if (!arrayListElementsEqual(prev, next) and orient2d(
                    // TODO(trimesh2d): all this code would be simpler if we had a poly index helper
                    // which returned a @Vector2(2, T)
                    @Vector(2, T){ poly[self.prev.items[curr]], poly[self.prev.items[curr] + 1] },
                    @Vector(2, T){ poly[curr], poly[curr + 1] },
                    @Vector(2, T){ poly[self.next.items[curr]], poly[self.next.items[curr] + 1] },
                )) {
                    try self.ears.append(curr);
                    self.is_ear.items[curr] = true;
                }
            }

            // Progressively delete all ears, updating the data structure
            const length = size;
            while (true) {
                const curr = self.ears.pop();

                // make new tri
                try out_triangles.append(self.prev.items[curr]);
                try out_triangles.append(curr);
                try out_triangles.append(self.next.items[curr]);

                // exclude curr from the polygon, connecting prev and next
                self.next.items[self.prev.items[curr]] = self.next.items[curr];
                self.prev.items[self.next.items[curr]] = self.prev.items[curr];

                length -= 1;
                if (length < 3) return; // last triangle

                // check if prev and next have become new ears
                if (!self.is_ear.items[self.prev.items[curr]] and self.prev.items[curr] != 0) {
                    if (self.prev.items[self.prev.items[curr]] != self.next.items[curr] and orient2d(
                        @Vector(2, T){ poly[self.prev.items[self.prev.items[curr]]], poly[(self.prev.items[self.prev.items[curr]]) + 1] },
                        @Vector(2, T){ poly[self.prev.items[curr]], poly[self.prev.items[curr] + 1] },
                        @Vector(2, T){ poly[self.next.items[curr]], poly[self.next.items[curr] + 1] },
                    ) > 0) {
                        try self.ears.append(self.prev.items[curr]);
                        self.is_ear.items[self.prev.items[curr]] = true;
                    }
                }
                if (!self.is_ear.items[self.next.items[curr]] and self.next.items[curr] < size - 1) {
                    if (self.next.items[self.next.items[curr]] != self.prev.items[curr] and orient2d(
                        @Vector(2, T){ poly[self.prev.items[curr]], poly[(self.prev.items[curr]) + 1] },
                        @Vector(2, T){ poly[self.next.items[curr]], poly[self.next.items[curr] + 1] },
                        @Vector(2, T){ poly[self.next.items[self.next.items[curr]]], poly[self.next.items[self.next.items[curr]] + 1] },
                    ) > 0) {
                        try self.ears.append(self.next.items[curr]);
                        self.is_ear.items[self.next.items[curr]] = true;
                    }
                }
            }
        }

        /// Inexact geometric predicate.
        /// Basically Shewchuk's orient2dfast()
        fn orient2d(
            pa: @Vector(2, T),
            pb: @Vector(2, T),
            pc: @Vector(2, T),
        ) T {
            const acx = pa[0] - pc[0];
            const bcx = pb[0] - pc[0];
            const acy = pa[1] - pc[1];
            const bcy = pb[1] - pc[1];
            return acx * bcy - acy * bcx;
        }

        fn arrayListElementsEqual(
            a: std.ArrayListUnmanaged(u32),
            b: std.ArrayListUnmanaged(u32),
        ) bool {
            if (a.len != b.len) return false;
            for (a.items) |aa, i| {
                if (b.items[i] != aa) return false;
            }
            return true;
        }
    };
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
