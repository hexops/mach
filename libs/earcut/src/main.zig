const std = @import("std");
const testing = std.testing;
const sign = std.math.sign;
const min = std.math.min;
const max = std.math.max;
const inf = std.math.inf;
const Allocator = std.mem.Allocator;

/// Returns a polygon processor, which can reuse its internal buffers to process multiple polygons
/// (call reset between process calls.) The type T denotes e.g. f16, f32, or f64 vertices.
pub fn Processor(comptime T: type) type {
    return struct {
        /// Resulting triangle indices once process() has finished.
        triangles: std.ArrayListUnmanaged(u32) = .{},

        /// Internal node buffer.
        nodes: std.MultiArrayList(Node) = .{},
        i: []u32 = &.{}, // node index -> vertex index in coordinates array
        x: []T = &.{}, // node index -> x vertex coordinate
        y: []T = &.{}, // node index -> y vertex coordinate
        z: []T = &.{}, // node index -> z-order curve value
        prev: []NodeIndex = &.{}, // node index -> prev node index in polygon ring
        next: []NodeIndex = &.{}, // node index -> next node index in polygon ring
        prev_z: []?NodeIndex = &.{}, // node index -> prev node index in z-order
        next_z: []?NodeIndex = &.{}, // node index -> next node index in z-order
        steiner: []bool = &.{}, // node index -> is this a steiner point?

        const NodeIndex = u32;

        pub fn deinit(processor: *@This(), allocator: Allocator) void {
            processor.triangles.deinit(allocator);
            processor.nodes.deinit(allocator);
        }

        pub fn process(p: *@This(), allocator: Allocator, data: []const T, hole_indices: ?[]const u32, dim: u3) error{OutOfMemory}!void {
            p.triangles.clearRetainingCapacity();
            p.nodes.shrinkRetainingCapacity(0);

            var has_holes = hole_indices != null and hole_indices.?.len > 0;
            var outer_len: u32 = if (has_holes) hole_indices.?[0] * dim else @intCast(u32, data.len);
            var outer_node = try p.linkedList(allocator, data, 0, outer_len, dim, true);

            if (outer_node == null or p.next[outer_node.?] == p.prev[outer_node.?]) return;

            var min_x: T = undefined;
            var min_y: T = undefined;
            var max_x: T = undefined;
            var max_y: T = undefined;
            var x: T = undefined;
            var y: T = undefined;
            var inv_size: T = 0;

            if (has_holes) outer_node = try p.eliminateHoles(allocator, data, hole_indices.?, outer_node, dim);

            // if the shape is not too simple, we'll use z-order curve hash later; calculate polygon bbox
            if (data.len > 80 * @intCast(usize, dim)) {
                min_x = data[0];
                max_x = data[0];
                min_y = data[1];
                max_y = data[1];

                var i: u32 = dim;
                while (i < outer_len) : (i += dim) {
                    x = data[i];
                    y = data[i + 1];
                    if (x < min_x) min_x = x;
                    if (y < min_y) min_y = y;
                    if (x > max_x) max_x = x;
                    if (y > max_y) max_y = y;
                }

                // min_x, min_y and inv_size are later used to transform coords into integers for z-order calculation
                inv_size = max(max_x - min_x, max_y - min_y);
                inv_size = if (inv_size != 0) 32767 / inv_size else 0;
            }

            if (outer_node) |e| try p.earcutLinked(allocator, e, &p.triangles, dim, min_x, min_y, inv_size, 0);
        }

        /// create a circular doubly linked list from polygon points in the specified winding order
        fn linkedList(p: *@This(), allocator: Allocator, data: []const T, start: u32, end: u32, dim: u3, clockwise: bool) error{OutOfMemory}!?NodeIndex {
            if (data.len < dim) return null;
            var i: u32 = undefined;
            var last: ?NodeIndex = null;

            if (clockwise == (signedArea(data, start, end, dim) > 0)) {
                i = start;
                while (i < end) : (i += dim) last = try p.insertNode(allocator, i, data[i], data[i + 1], last);
            } else {
                i = end - dim;
                while (i >= start) : (i -= dim) {
                    last = try p.insertNode(allocator, i, data[i], data[i + 1], last);
                    if (i == 0) break;
                }
            }

            if (last != null and p.equals(last.?, p.next[last.?])) {
                p.removeNode(last.?);
                last = p.next[last.?];
            }
            return last;
        }

        /// eliminate colinear or duplicate points
        fn filterPoints(p: *@This(), start: ?NodeIndex, end_in: ?NodeIndex) ?NodeIndex {
            if (start == null) return start;
            var end = if (end_in) |e| e else start.?;

            var n = start.?;
            var again = false;
            while (true) {
                again = false;

                if (!p.steiner[n] and (p.equals(n, p.next[n]) or p.area(p.prev[n], n, p.next[n]) == 0)) {
                    p.removeNode(n);
                    n = p.prev[n];
                    end = p.prev[n];
                    if (n == p.next[n]) break;
                    again = true;
                } else {
                    n = p.next[n];
                }
                if (again or n != end) break;
            }

            return end;
        }

        /// main ear slicing loop which triangulates a polygon (given as a linked list)
        fn earcutLinked(p: *@This(), allocator: Allocator, ear_in: NodeIndex, triangles: *std.ArrayListUnmanaged(u32), dim: u3, min_x: T, min_y: T, inv_size: T, pass: u2) error{OutOfMemory}!void {
            // interlink polygon nodes in z-order
            if (pass == 0 and inv_size != 0) p.indexCurve(ear_in, min_x, min_y, inv_size);

            var ear = ear_in;
            var stop = ear;
            var t_prev: NodeIndex = undefined;
            var t_next: NodeIndex = undefined;

            // iterate through ears, slicing them one by one
            while (p.prev[ear] != p.next[ear]) {
                t_prev = p.prev[ear];
                t_next = p.next[ear];

                if (if (inv_size != 0) p.isEarHashed(ear, min_x, min_y, inv_size) else p.isEar(ear)) {
                    // cut off the triangle
                    try triangles.append(allocator, p.i[t_prev] / dim | 0);
                    try triangles.append(allocator, p.i[ear] / dim | 0);
                    try triangles.append(allocator, p.i[t_next] / dim | 0);

                    p.removeNode(ear);

                    // skipping the next vertex leads to less sliver triangles
                    ear = p.next[t_next];
                    stop = p.next[t_next];

                    continue;
                }

                ear = t_next;

                // if we looped through the whole remaining polygon and can't find any more ears
                if (ear == stop) {
                    // try filtering points and slicing again
                    if (pass == 0) {
                        if (p.filterPoints(ear, null)) |e| try p.earcutLinked(allocator, e, triangles, dim, min_x, min_y, inv_size, 1);

                        // if this didn't work, try curing all small self-intersections locally
                    } else if (pass == 1) {
                        const ear_maybe = try p.cureLocalIntersections(allocator, p.filterPoints(ear, null).?, triangles, dim);
                        ear = ear_maybe.?; // TODO: can it actually return null?
                        try p.earcutLinked(allocator, ear, triangles, dim, min_x, min_y, inv_size, 2);

                        // as a last resort, try splitting the remaining polygon into two
                    } else if (pass == 2) {
                        try p.splitEarcut(allocator, ear, triangles, dim, min_x, min_y, inv_size);
                    }

                    break;
                }
            }
        }

        /// check whether a polygon node forms a valid ear with adjacent nodes
        fn isEar(p: *@This(), ear: NodeIndex) bool {
            var a = p.prev[ear];
            var b = ear;
            var c = p.next[ear];

            if (p.area(a, b, c) >= 0) return false; // reflex, can't be an ear

            // now make sure we don't have other points inside the potential ear
            var ax = p.x[a];
            var bx = p.x[b];
            var cx = p.x[c];
            var ay = p.y[a];
            var by = p.y[b];
            var cy = p.y[c];

            // triangle bbox; min & max are calculated like this for speed
            var x0 = if (ax < bx) (if (ax < cx) ax else cx) else (if (bx < cx) bx else cx);
            var y0 = if (ay < by) (if (ay < cy) ay else cy) else (if (by < cy) by else cy);
            var x1 = if (ax > bx) (if (ax > cx) ax else cx) else (if (bx > cx) bx else cx);
            var y1 = if (ay > by) (if (ay > cy) ay else cy) else (if (by > cy) by else cy);

            var n = p.next[c];
            while (n != a) {
                if (p.x[n] >= x0 and p.x[n] <= x1 and p.y[n] >= y0 and p.y[n] <= y1 and
                    pointInTriangle(ax, ay, bx, by, cx, cy, p.x[n], p.y[n]) and
                    p.area(p.prev[n], n, p.next[n]) >= 0) return false;
                n = p.next[n];
            }

            return true;
        }

        fn isEarHashed(p: *@This(), ear: NodeIndex, min_x: T, min_y: T, inv_size: T) bool {
            var a = p.prev[ear];
            var b = ear;
            var c = p.next[ear];

            if (p.area(a, b, c) >= 0) return false; // reflex, can't be an ear

            var ax = p.x[a];
            var bx = p.x[b];
            var cx = p.x[c];
            var ay = p.y[a];
            var by = p.y[b];
            var cy = p.y[c];

            // triangle bbox; min & max are calculated like this for speed
            var x0 = if (ax < bx) (if (ax < cx) ax else cx) else (if (bx < cx) bx else cx);
            var y0 = if (ay < by) (if (ay < cy) ay else cy) else (if (by < cy) by else cy);
            var x1 = if (ax > bx) (if (ax > cx) ax else cx) else (if (bx > cx) bx else cx);
            var y1 = if (ay > by) (if (ay > cy) ay else cy) else (if (by > cy) by else cy);

            // z-order range for the current triangle bbox;
            var min_z = zOrder(x0, y0, min_x, min_y, inv_size);
            var max_z = zOrder(x1, y1, min_x, min_y, inv_size);

            var p2 = p.prev_z[ear];
            var n = p.next_z[ear];

            // look for points inside the triangle in both directions
            while (p2 != null and p.z[p2.?] >= min_z and n != null and p.z[n.?] <= max_z) {
                if (p.x[p2.?] >= x0 and p.x[p2.?] <= x1 and p.y[p2.?] >= y0 and p.y[p2.?] <= y1 and p2 != a and p2 != c and
                    pointInTriangle(ax, ay, bx, by, cx, cy, p.x[p2.?], p.y[p2.?]) and p.area(p.prev[p2.?], p2.?, p.next[p2.?]) >= 0) return false;
                p2 = p.prev_z[p2.?];

                if (p.x[n.?] >= x0 and p.x[n.?] <= x1 and p.y[n.?] >= y0 and p.y[n.?] <= y1 and n != a and n != c and
                    pointInTriangle(ax, ay, bx, by, cx, cy, p.x[n.?], p.y[n.?]) and p.area(p.prev[n.?], n.?, p.next[n.?]) >= 0) return false;
                n = p.next_z[n.?];
            }

            // look for remaining points in decreasing z-order
            while (p2 != null and p.z[p2.?] >= min_z) {
                if (p.x[p2.?] >= x0 and p.x[p2.?] <= x1 and p.y[p2.?] >= y0 and p.y[p2.?] <= y1 and p2 != a and p2 != c and
                    pointInTriangle(ax, ay, bx, by, cx, cy, p.x[p2.?], p.y[p2.?]) and p.area(p.prev[p2.?], p2.?, p.next[p2.?]) >= 0) return false;
                p2 = p.prev_z[p2.?];
            }

            // look for remaining points in increasing z-order
            while (n != null and p.z[n.?] <= max_z) {
                if (p.x[n.?] >= x0 and p.x[n.?] <= x1 and p.y[n.?] >= y0 and p.y[n.?] <= y1 and n != a and n != c and
                    pointInTriangle(ax, ay, bx, by, cx, cy, p.x[n.?], p.y[n.?]) and p.area(p.prev[n.?], n.?, p.next[n.?]) >= 0) return false;
                n = p.next_z[n.?];
            }

            return true;
        }

        /// go through all polygon nodes and cure small local self-intersections
        fn cureLocalIntersections(p: *@This(), allocator: Allocator, start_in: NodeIndex, triangles: *std.ArrayListUnmanaged(u32), dim: u3) error{OutOfMemory}!?NodeIndex {
            var start = start_in;
            var n = start;
            while (true) {
                var a = p.prev[n];
                var b = p.next[p.next[n]];

                if (!p.equals(a, b) and p.intersects(a, n, p.next[n], b) and p.locallyInside(a, b) and p.locallyInside(b, a)) {
                    try triangles.append(allocator, p.i[a] / dim | 0);
                    try triangles.append(allocator, p.i[n] / dim | 0);
                    try triangles.append(allocator, p.i[b] / dim | 0);

                    // remove two nodes involved
                    p.removeNode(n);
                    p.removeNode(p.next[n]);

                    n = b;
                    start = b;
                }
                n = p.next[n];
                if (n != start) break;
            }

            return p.filterPoints(n, null);
        }

        /// try splitting polygon into two and triangulate them independently
        fn splitEarcut(p: *@This(), allocator: Allocator, start: NodeIndex, triangles: *std.ArrayListUnmanaged(u32), dim: u3, min_x: T, min_y: T, inv_size: T) error{OutOfMemory}!void {
            // look for a valid diagonal that divides the polygon into two
            var a = start;
            while (true) {
                var b = p.next[p.next[a]];
                while (b != p.prev[a]) {
                    if (p.i[a] != p.i[b] and p.isValidDiagonal(a, b)) {
                        // split the polygon in two by the diagonal
                        var c = try p.splitPolygon(allocator, a, b);

                        // filter colinear points around the cuts
                        a = p.filterPoints(a, p.next[a]).?;
                        c = p.filterPoints(c, p.next[c]).?;

                        // run earcut on each half
                        try p.earcutLinked(allocator, a, triangles, dim, min_x, min_y, inv_size, 0);
                        try p.earcutLinked(allocator, c, triangles, dim, min_x, min_y, inv_size, 0);
                        return;
                    }
                    b = p.next[b];
                }
                a = p.next[a];
                if (a != start) break;
            }
        }

        /// link every hole into the outer loop, producing a single-ring polygon without holes
        fn eliminateHoles(p: *@This(), allocator: Allocator, data: []const T, hole_indices: []const u32, outer_node_in: ?NodeIndex, dim: u3) error{OutOfMemory}!?NodeIndex {
            if (hole_indices.len == 0) return null;
            // TODO: save/reuse this buffer.
            var queue = std.ArrayListUnmanaged(NodeIndex){};
            defer queue.deinit(allocator);
            var start: u32 = undefined;
            var end: u32 = undefined;

            var i: u32 = 0;
            var len = hole_indices.len;
            while (i < len) : (i += 1) {
                start = hole_indices[i] * dim;
                end = if (i < len - 1) hole_indices[i + 1] * dim else @intCast(u32, data.len);
                const list_maybe = try p.linkedList(allocator, data, start, end, dim, false);
                const list = list_maybe.?; // TODO: if returns null, assertion would fail
                if (list == p.next[list]) p.steiner[list] = true;
                try queue.append(allocator, p.getLeftmost(list));
            }

            std.sort.sort(NodeIndex, queue.items, p, compareX);

            // process holes from left to right
            i = 0;
            var outer_node = outer_node_in;
            while (i < queue.items.len) : (i += 1) {
                outer_node = try p.eliminateHole(allocator, queue.items[i], outer_node.?); // TODO: if outer_node_in == null, this assertion would fail?
            }

            return outer_node;
        }

        fn compareX(p: *@This(), lhs: NodeIndex, rhs: NodeIndex) bool {
            return (p.x[lhs] - p.x[rhs]) < 0;
        }

        /// find a bridge between vertices that connects hole with an outer ring and and link it
        fn eliminateHole(p: *@This(), allocator: Allocator, hole: NodeIndex, outer_node: NodeIndex) error{OutOfMemory}!?NodeIndex {
            var bridge = p.findHoleBridge(hole, outer_node);
            if (bridge == null) {
                return outer_node;
            }

            var bridge_reverse = try p.splitPolygon(allocator, bridge.?, hole);

            // filter collinear points around the cuts
            _ = p.filterPoints(bridge_reverse, p.next[bridge_reverse]); // TODO: is this ineffective?
            return p.filterPoints(bridge, p.next[bridge.?]);
        }

        /// David Eberly's algorithm for finding a bridge between hole and outer polygon
        fn findHoleBridge(p: *@This(), hole: NodeIndex, outer_node: NodeIndex) ?NodeIndex {
            var n = outer_node;
            var hx = p.x[hole];
            var hy = p.y[hole];
            var qx = -inf(T);
            var m: ?NodeIndex = null;

            // find a segment intersected by a ray from the hole's leftmost point to the left;
            // segment's endpoint with lesser x will be potential connection point
            while (true) {
                if (hy <= p.y[n] and hy >= p.y[p.next[n]] and p.y[p.next[n]] != p.y[n]) {
                    var x = p.x[n] + (hy - p.y[n]) * (p.x[p.next[n]] - p.x[n]) / (p.y[p.next[n]] - p.y[n]);
                    if (x <= hx and x > qx) {
                        qx = x;
                        m = if (p.x[n] < p.x[p.next[n]]) n else p.next[n];
                        if (x == hx) return m; // hole touches outer segment; pick leftmost endpoint
                    }
                }
                n = p.next[n];
                if (n != outer_node) break;
            }

            if (m == null) return null;

            // look for points inside the triangle of hole point, segment intersection and endpoint;
            // if there are no points found, we have a valid connection;
            // otherwise choose the point of the minimum angle with the ray as connection point

            var stop = m.?;
            var mx = p.x[m.?];
            var my = p.y[m.?];
            var tan_min = inf(T);
            var tan: T = 0;

            n = m.?;

            while (true) {
                if (hx >= p.x[n] and p.x[n] >= mx and hx != p.x[n] and
                    pointInTriangle(if (hy < my) hx else qx, hy, mx, my, if (hy < my) qx else hx, hy, p.x[n], p.y[n]))
                {
                    tan = @fabs(hy - p.y[n]) / (hx - p.x[n]); // tangential

                    if (p.locallyInside(n, hole) and
                        (tan < tan_min or (tan == tan_min and (p.x[n] > p.x[m.?] or (p.x[n] == p.x[m.?] and p.sectorContainsSector(m.?, n))))))
                    {
                        m = n;
                        tan_min = tan;
                    }
                }

                n = p.next[n];
                if (n != stop) break;
            }

            return m;
        }

        /// whether sector in vertex m contains sector in vertex p in the same coordinates
        fn sectorContainsSector(p: *@This(), m: NodeIndex, n: NodeIndex) bool {
            return p.area(p.prev[m], m, p.prev[n]) < 0 and p.area(p.next[n], m, p.next[m]) < 0;
        }

        /// interlink polygon nodes in z-order
        fn indexCurve(p: *@This(), start: NodeIndex, min_x: T, min_y: T, inv_size: T) void {
            var n = start;
            while (true) {
                if (p.z[n] == 0) p.z[n] = zOrder(p.x[n], p.y[n], min_x, min_y, inv_size);
                p.prev_z[n] = p.prev[n];
                p.next_z[n] = p.next[n];
                n = p.next[n];
                if (n == start) break;
            }

            p.next_z[p.prev_z[n].?] = null;
            p.prev_z[n] = null;

            _ = p.sortLinked(n);
        }

        /// Simon Tatham's linked list merge sort algorithm
        /// http://www.chiark.greenend.org.uk/~sgtatham/algorithms/listsort.html
        fn sortLinked(p: *@This(), list_in: NodeIndex) ?NodeIndex {
            var list: ?NodeIndex = list_in;
            var i: usize = undefined;
            var n: ?NodeIndex = null;
            var q: ?NodeIndex = null;
            var e: ?NodeIndex = null;
            var tail: ?NodeIndex = null;
            var num_merges: usize = 0;
            var n_size: usize = 0;
            var q_size: usize = 0;
            var in_size: usize = 1;

            while (true) {
                n = list;
                list = null;
                tail = null;
                num_merges = 0;

                while (n != null) {
                    num_merges += 1;
                    q = n;
                    n_size = 0;
                    i = 0;
                    while (i < in_size) : (i += 1) {
                        n_size += 1;
                        q = p.next_z[q.?];
                        if (q == null) break;
                    }
                    q_size = in_size;

                    while (n_size > 0 or (q_size > 0 and q != null)) {
                        if (n_size != 0 and (q_size == 0 or q == null or p.z[n.?] <= p.z[q.?])) {
                            e = n;
                            n = p.next_z[n.?];
                            n_size -= 1;
                        } else {
                            e = q;
                            q = p.next_z[q.?];
                            q_size -= 1;
                        }

                        if (tail != null) p.next_z[tail.?] = e else list = e;

                        p.prev_z[e.?] = tail;
                        tail = e;
                    }

                    n = q;
                }

                p.next_z[tail.?] = null;
                in_size *= 2;
                if (num_merges > 1) break;
            }

            return list;
        }

        /// z-order of a point given coords and inverse of the longer side of data bbox
        fn zOrder(x_in: T, y_in: T, min_x: T, min_y: T, inv_size: T) T {
            // coords are transformed into non-negative 15-bit integer range
            var x = @floatToInt(i32, (x_in - min_x) * inv_size) | 0;
            var y = @floatToInt(i32, (y_in - min_y) * inv_size) | 0;

            x = (x | (x << 8)) & 0x00FF00FF;
            x = (x | (x << 4)) & 0x0F0F0F0F;
            x = (x | (x << 2)) & 0x33333333;
            x = (x | (x << 1)) & 0x55555555;

            y = (y | (y << 8)) & 0x00FF00FF;
            y = (y | (y << 4)) & 0x0F0F0F0F;
            y = (y | (y << 2)) & 0x33333333;
            y = (y | (y << 1)) & 0x55555555;

            return @intToFloat(T, x | (y << 1));
        }

        /// find the leftmost node of a polygon ring
        fn getLeftmost(p: *@This(), start: NodeIndex) NodeIndex {
            var n = start;
            var leftmost = start;
            while (true) {
                if (p.x[n] < p.x[leftmost] or (p.x[n] == p.x[leftmost] and p.y[n] < p.y[leftmost])) {
                    leftmost = n;
                }
                n = p.next[n];
                if (n != start) break;
            }
            return leftmost;
        }

        /// check if a point lies within a convex triangle
        fn pointInTriangle(ax: T, ay: T, bx: T, by: T, cx: T, cy: T, px: T, py: T) bool {
            return (cx - px) * (ay - py) >= (ax - px) * (cy - py) and
                (ax - px) * (by - py) >= (bx - px) * (ay - py) and
                (bx - px) * (cy - py) >= (cx - px) * (by - py);
        }

        /// check if a diagonal between two polygon nodes is valid (lies in polygon interior)
        fn isValidDiagonal(p: *@This(), a: NodeIndex, b: NodeIndex) bool {
            return p.i[p.next[a]] != p.i[b] and p.i[p.prev[a]] != p.i[b] and !p.intersectsPolygon(a, b) and // dones't intersect other edges
                (p.locallyInside(a, b) and p.locallyInside(b, a) and p.middleInside(a, b) and // locally visible
                (p.area(p.prev[a], a, p.prev[b]) != 0 or p.area(a, p.prev[b], b) != 0) or // does not create opposite-facing sectors
                p.equals(a, b) and p.area(p.prev[a], a, p.next[a]) > 0 and p.area(p.prev[b], b, p.next[b]) > 0); // special zero-length case
        }

        /// signed area of a triangle
        inline fn area(p: *@This(), n: NodeIndex, q: NodeIndex, r: NodeIndex) T {
            return (p.y[q] - p.y[n]) * (p.x[r] - p.x[q]) - (p.x[q] - p.x[n]) * (p.y[r] - p.y[q]);
        }

        /// check if two points are equal
        inline fn equals(p: *@This(), p1: NodeIndex, p2: NodeIndex) bool {
            return p.x[p1] == p.x[p2] and p.y[p1] == p.y[p2];
        }

        /// check if two segments intersect
        fn intersects(p: *@This(), p1: NodeIndex, q1: NodeIndex, p2: NodeIndex, q2: NodeIndex) bool {
            var o1 = sign(p.area(p1, q1, p2));
            var o2 = sign(p.area(p1, q1, q2));
            var o3 = sign(p.area(p2, q2, p1));
            var o4 = sign(p.area(p2, q2, q1));

            if (o1 != o2 and o3 != o4) return true; // general case

            if (o1 == 0 and p.onSegment(p1, p2, q1)) return true; // p1, q1 and p2 are collinear and p2 lies on p1q1
            if (o2 == 0 and p.onSegment(p1, q2, q1)) return true; // p1, q1 and q2 are collinear and q2 lies on p1q1
            if (o3 == 0 and p.onSegment(p2, p1, q2)) return true; // p2, q2 and p1 are collinear and p1 lies on p2q2
            if (o4 == 0 and p.onSegment(p2, q1, q2)) return true; // p2, q2 and q1 are collinear and q1 lies on p2q2

            return false;
        }

        /// for collinear points p, q, r, check if point q lies on segment pr
        inline fn onSegment(p: *@This(), n: NodeIndex, q: NodeIndex, r: NodeIndex) bool {
            return p.x[q] <= max(p.x[n], p.x[r]) and p.x[q] >= min(p.x[n], p.x[r]) and p.y[q] <= max(p.y[n], p.y[r]) and p.y[q] >= min(p.y[n], p.y[r]);
        }

        /// check if a polygon diagonal intersects any polygon segments
        fn intersectsPolygon(p: *@This(), a: NodeIndex, b: NodeIndex) bool {
            var n = a;
            while (true) {
                if (p.i[n] != p.i[a] and p.i[p.next[n]] != p.i[a] and p.i[n] != p.i[b] and p.i[p.next[n]] != p.i[b] and
                    p.intersects(n, p.next[n], a, b)) return true;
                n = p.next[n];
                if (n != a) break;
            }
            return false;
        }

        /// check if a polygon diagonal is locally inside the polygon
        fn locallyInside(p: *@This(), a: NodeIndex, b: NodeIndex) bool {
            return if (p.area(p.prev[a], a, p.next[a]) < 0)
                p.area(a, b, p.next[a]) >= 0 and p.area(a, p.prev[a], b) >= 0
            else
                p.area(a, b, p.prev[a]) < 0 or p.area(a, p.next[a], b) < 0;
        }

        /// check if the middle point of a polygon diagonal is inside the polygon
        fn middleInside(p: *@This(), a: NodeIndex, b: NodeIndex) bool {
            var n = a;
            var inside = false;
            var px = (p.x[a] + p.x[b]) / 2.0;
            var py = (p.y[a] + p.y[b]) / 2.0;
            while (true) {
                if (((p.y[n] > py) != (p.y[p.next[n]] > py)) and p.y[p.next[n]] != p.y[n] and
                    (px < (p.x[p.next[n]] - p.x[n]) * (py - p.y[n]) / (p.y[p.next[n]] - p.y[n]) + p.x[n]))
                    inside = !inside;
                n = p.next[n];
                if (n != a) break;
            }
            return inside;
        }

        /// link two polygon vertices with a bridge; if the vertices belong the same ring, it splits
        /// polygon into two; if one belongs to the outer ring and another to a hole, it merges it
        /// into a single ring.
        fn splitPolygon(p: *@This(), allocator: Allocator, a: NodeIndex, b: NodeIndex) error{OutOfMemory}!NodeIndex {
            var b2 = @intCast(NodeIndex, p.nodes.len + 1);
            var a2 = try p.initNode(allocator, .{ // a2
                .i = p.i[a],
                .x = p.x[a],
                .y = p.y[a],
                .next = p.next[a],
                .prev = b2,
            });
            _ = try p.initNode(allocator, .{ // b2
                .i = p.i[b],
                .x = p.x[b],
                .y = p.y[b],
                .next = a2,
                .prev = p.prev[b],
            });
            p.next[a] = b;
            p.prev[b] = a;
            p.prev[p.next[a]] = a2;
            p.next[p.prev[b]] = b2;
            return b2;
        }

        /// create a node and optionally link it with previous one (in a circular doubly linked list)
        fn insertNode(p: *@This(), allocator: Allocator, i: u32, x: T, y: T, last: ?NodeIndex) error{OutOfMemory}!NodeIndex {
            const new_node = @intCast(NodeIndex, p.nodes.len);
            if (last) |l| {
                _ = try p.initNode(allocator, .{
                    .i = i,
                    .x = x,
                    .y = y,
                    .next = p.next[l],
                    .prev = l,
                });
                p.prev[p.next[l]] = new_node;
                p.next[l] = new_node;
            } else {
                _ = try p.initNode(allocator, .{
                    .i = i,
                    .x = x,
                    .y = y,
                    .prev = new_node,
                    .next = new_node,
                });
            }
            return new_node;
        }

        fn removeNode(p: *@This(), n: NodeIndex) void {
            p.prev[p.next[n]] = p.prev[n];
            p.next[p.prev[n]] = p.next[n];
            if (p.prev_z[n]) |prev_z| p.next_z[prev_z] = p.next_z[n];
            if (p.next_z[n]) |next_z| p.prev_z[next_z] = p.prev_z[n];
        }

        fn initNode(p: *@This(), allocator: Allocator, n: Node) error{OutOfMemory}!NodeIndex {
            try p.nodes.append(allocator, n);

            const slice = p.nodes.slice();
            p.i = slice.items(.i);
            p.x = slice.items(.x);
            p.y = slice.items(.y);
            p.z = slice.items(.z);
            p.prev = slice.items(.prev);
            p.next = slice.items(.next);
            p.prev_z = slice.items(.prev_z);
            p.next_z = slice.items(.next_z);
            p.steiner = slice.items(.steiner);
            return @intCast(NodeIndex, p.nodes.len - 1);
        }

        const Node = struct {
            i: u32, // vertex index in coordinates array

            // vertex coordinates
            x: T,
            y: T,

            // previous and next vertex nodes in a polygon ring
            prev: NodeIndex,
            next: NodeIndex,

            // previous and next nodes in z-order
            prev_z: ?NodeIndex = null,
            next_z: ?NodeIndex = null,

            // z-order curve value
            z: T = 0,

            // indicates whether this is a steiner point
            steiner: bool = false,
        };

        fn signedArea(data: []const T, start: u32, end: u32, dim: u3) T {
            var sum: T = 0;
            var j = end - dim;
            var i = start;
            while (i < end) : (i += dim) {
                sum += (data[j] - data[i]) * (data[i + 1] + data[j + 1]);
                j = i;
            }
            return sum;
        }
    };
}

test {
    std.testing.refAllDeclsRecursive(@This());
}

test "basic" {
    const allocator = testing.allocator;

    var processor = Processor(f32){};
    defer processor.deinit(allocator);

    const data = &[_]f32{
        0, 0, // left, bottom
        0, 1, // left, top
        1, 1, // right, top
        1, 0, // right, bottom
    };
    const hole_indices: ?[]u32 = null;

    const dimensions = 2;
    try processor.process(allocator, data, hole_indices, dimensions);

    const tri = processor.triangles.items;

    try testing.expectEqual(@as(usize, 6), tri.len);

    try testing.expectEqualSlices(f32, &.{ 0, 1 }, data[tri[0] * dimensions .. (tri[0] * dimensions) + 2]); // left, top
    try testing.expectEqualSlices(f32, &.{ 0, 0 }, data[tri[1] * dimensions .. (tri[1] * dimensions) + 2]); // left, bottom
    try testing.expectEqualSlices(f32, &.{ 1, 0 }, data[tri[2] * dimensions .. (tri[2] * dimensions) + 2]); // right, bottom

    try testing.expectEqualSlices(f32, &.{ 1, 0 }, data[tri[3] * dimensions .. (tri[3] * dimensions) + 2]); // right, bottom
    try testing.expectEqualSlices(f32, &.{ 1, 1 }, data[tri[4] * dimensions .. (tri[4] * dimensions) + 2]); // right, top
    try testing.expectEqualSlices(f32, &.{ 0, 1 }, data[tri[5] * dimensions .. (tri[5] * dimensions) + 2]); // left, top
}
