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
        nodes: std.ArrayListUnmanaged(Node) = .{},

        pub fn deinit(processor: *@This(), allocator: Allocator) void {
            processor.triangles.deinit(allocator);

            // TODO: since nodes list is unused currently, this results in a big leak.
            processor.nodes.deinit(allocator);
        }

        pub fn process(processor: *@This(), allocator: Allocator, data: []const T, hole_indices: ?[]const u32, dim: u3) error{OutOfMemory}!void {
            processor.triangles.clearRetainingCapacity();
            processor.nodes.clearRetainingCapacity();

            var has_holes = hole_indices != null and hole_indices.?.len > 0;
            var outer_len: u32 = if (has_holes) hole_indices.?[0] * dim else @intCast(u32, data.len);
            var outer_node = try processor.linkedList(allocator, data, 0, outer_len, dim, true);

            if (outer_node == null or outer_node.?.next == outer_node.?.prev) return;

            var min_x: T = undefined;
            var min_y: T = undefined;
            var max_x: T = undefined;
            var max_y: T = undefined;
            var x: T = undefined;
            var y: T = undefined;
            var inv_size: T = 0;

            if (has_holes) outer_node = try processor.eliminateHoles(allocator, data, hole_indices.?, outer_node, dim);

            // if the shape is not too simple, we'll use z-order curve hash later; calculate polygon bbox
            if (data.len > 80 * @intCast(usize, dim)) {
                min_x = data[0];
                max_x = data[0];
                min_y = data[1];
                max_y = data[1];

                var i = dim;
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

            if (outer_node) |e| try processor.earcutLinked(allocator, e, &processor.triangles, dim, min_x, min_y, inv_size, 0);
        }

        /// create a circular doubly linked list from polygon points in the specified winding order
        fn linkedList(processor: *@This(), allocator: Allocator, data: []const T, start: u32, end: u32, dim: u3, clockwise: bool) error{OutOfMemory}!?*Node {
            var i: u32 = undefined;
            var last: ?*Node = null;

            if (clockwise == (signedArea(data, start, end, dim) > 0)) {
                i = start;
                while (i < end) : (i += dim) last = try processor.insertNode(allocator, i, data[i], data[i + 1], last);
            } else {
                i = end - dim;
                while (i >= start) : (i -= dim) {
                    last = try processor.insertNode(allocator, i, data[i], data[i + 1], last);
                    if (i == 0) break;
                }
            }

            if (last != null and equals(last.?, last.?.next.?)) {
                removeNode(last.?);
                last = last.?.next.?;
            }
            return last;
        }

        /// eliminate colinear or duplicate points
        fn filterPoints(start: ?*Node, end_in: ?*Node) ?*Node {
            if (start == null) return start;
            var end = if (end_in) |e| e else start;

            var p = start;
            var again = false;
            while (true) {
                again = false;

                if (!p.?.steiner and (equals(p.?, p.?.next.?) or area(p.?.prev.?, p.?, p.?.next.?) == 0)) {
                    removeNode(p.?);
                    p = p.?.prev;
                    end = p.?.prev;
                    if (p == p.?.next) break;
                    again = true;
                } else {
                    p = p.?.next;
                }
                if (again or p != end) break;
            }

            return end;
        }

        /// main ear slicing loop which triangulates a polygon (given as a linked list)
        fn earcutLinked(processor: *@This(), allocator: Allocator, ear_in: *Node, triangles: *std.ArrayListUnmanaged(u32), dim: u3, min_x: T, min_y: T, inv_size: T, pass: u2) error{OutOfMemory}!void {
            // interlink polygon nodes in z-order
            if (pass == 0 and inv_size != 0) indexCurve(ear_in, min_x, min_y, inv_size);

            var ear: ?*Node = ear_in;
            var stop = ear;
            var prev: ?*Node = null;
            var next: ?*Node = null;

            // iterate through ears, slicing them one by one
            while (ear.?.prev != ear.?.next) {
                prev = ear.?.prev;
                next = ear.?.next;

                if (if (inv_size != 0) isEarHashed(ear.?, min_x, min_y, inv_size) else isEar(ear.?)) {
                    // cut off the triangle
                    try triangles.append(allocator, prev.?.i / dim | 0);
                    try triangles.append(allocator, ear.?.i / dim | 0);
                    try triangles.append(allocator, next.?.i / dim | 0);

                    removeNode(ear.?);

                    // skipping the next vertex leads to less sliver triangles
                    ear = next.?.next;
                    stop = next.?.next;

                    continue;
                }

                ear = next;

                // if we looped through the whole remaining polygon and can't find any more ears
                if (ear == stop) {
                    // try filtering points and slicing again
                    if (pass == 0) {
                        if (filterPoints(ear, null)) |e| try processor.earcutLinked(allocator, e, triangles, dim, min_x, min_y, inv_size, 1);

                        // if this didn't work, try curing all small self-intersections locally
                    } else if (pass == 1) {
                        ear = try cureLocalIntersections(allocator, filterPoints(ear, null).?, triangles, dim);
                        if (ear) |e| try processor.earcutLinked(allocator, e, triangles, dim, min_x, min_y, inv_size, 2);

                        // as a last resort, try splitting the remaining polygon into two
                    } else if (pass == 2) {
                        try processor.splitEarcut(allocator, ear.?, triangles, dim, min_x, min_y, inv_size);
                    }

                    break;
                }
            }
        }

        /// check whether a polygon node forms a valid ear with adjacent nodes
        fn isEar(ear: *Node) bool {
            var a = ear.prev.?;
            var b = ear;
            var c = ear.next.?;

            if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

            // now make sure we don't have other points inside the potential ear
            var ax = a.x;
            var bx = b.x;
            var cx = c.x;
            var ay = a.y;
            var by = b.y;
            var cy = c.y;

            // triangle bbox; min & max are calculated like this for speed
            var x0 = if (ax < bx) (if (ax < cx) ax else cx) else (if (bx < cx) bx else cx);
            var y0 = if (ay < by) (if (ay < cy) ay else cy) else (if (by < cy) by else cy);
            var x1 = if (ax > bx) (if (ax > cx) ax else cx) else (if (bx > cx) bx else cx);
            var y1 = if (ay > by) (if (ay > cy) ay else cy) else (if (by > cy) by else cy);

            var p = c.next;
            while (p != a) {
                if (p.?.x >= x0 and p.?.x <= x1 and p.?.y >= y0 and p.?.y <= y1 and
                    pointInTriangle(ax, ay, bx, by, cx, cy, p.?.x, p.?.y) and
                    area(p.?.prev.?, p.?, p.?.next.?) >= 0) return false;
                p = p.?.next;
            }

            return true;
        }

        fn isEarHashed(ear: *Node, min_x: T, min_y: T, inv_size: T) bool {
            var a = ear.prev.?;
            var b = ear;
            var c = ear.next.?;

            if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

            var ax = a.x;
            var bx = b.x;
            var cx = c.x;
            var ay = a.y;
            var by = b.y;
            var cy = c.y;

            // triangle bbox; min & max are calculated like this for speed
            var x0 = if (ax < bx) (if (ax < cx) ax else cx) else (if (bx < cx) bx else cx);
            var y0 = if (ay < by) (if (ay < cy) ay else cy) else (if (by < cy) by else cy);
            var x1 = if (ax > bx) (if (ax > cx) ax else cx) else (if (bx > cx) bx else cx);
            var y1 = if (ay > by) (if (ay > cy) ay else cy) else (if (by > cy) by else cy);

            // z-order range for the current triangle bbox;
            var min_z = zOrder(x0, y0, min_x, min_y, inv_size);
            var max_z = zOrder(x1, y1, min_x, min_y, inv_size);

            var p = ear.prev_z;
            var n = ear.next_z;

            // look for points inside the triangle in both directions
            while (p != null and p.?.z >= min_z and n != null and n.?.z <= max_z) {
                if (p.?.x >= x0 and p.?.x <= x1 and p.?.y >= y0 and p.?.y <= y1 and p != a and p != c and
                    pointInTriangle(ax, ay, bx, by, cx, cy, p.?.x, p.?.y) and area(p.?.prev.?, p.?, p.?.next.?) >= 0) return false;
                p = p.?.prev_z;

                if (n.?.x >= x0 and n.?.x <= x1 and n.?.y >= y0 and n.?.y <= y1 and n != a and n != c and
                    pointInTriangle(ax, ay, bx, by, cx, cy, n.?.x, n.?.y) and area(n.?.prev.?, n.?, n.?.next.?) >= 0) return false;
                n = n.?.next_z;
            }

            // look for remaining points in decreasing z-order
            while (p != null and p.?.z >= min_z) {
                if (p.?.x >= x0 and p.?.x <= x1 and p.?.y >= y0 and p.?.y <= y1 and p != a and p != c and
                    pointInTriangle(ax, ay, bx, by, cx, cy, p.?.x, p.?.y) and area(p.?.prev.?, p.?, p.?.next.?) >= 0) return false;
                p = p.?.prev_z;
            }

            // look for remaining points in increasing z-order
            while (n != null and n.?.z <= max_z) {
                if (n.?.x >= x0 and n.?.x <= x1 and n.?.y >= y0 and n.?.y <= y1 and n != a and n != c and
                    pointInTriangle(ax, ay, bx, by, cx, cy, n.?.x, n.?.y) and area(n.?.prev.?, n.?, n.?.next.?) >= 0) return false;
                n = n.?.next_z;
            }

            return true;
        }

        /// go through all polygon nodes and cure small local self-intersections
        fn cureLocalIntersections(allocator: Allocator, start_in: *Node, triangles: *std.ArrayListUnmanaged(u32), dim: u3) error{OutOfMemory}!?*Node {
            var start = start_in;
            var p = start;
            while (true) {
                var a = p.prev.?;
                var b = p.next.?.next.?;

                if (!equals(a, b) and intersects(a, p, p.next.?, b) and locallyInside(a, b) and locallyInside(b, a)) {
                    try triangles.append(allocator, a.i / dim | 0);
                    try triangles.append(allocator, p.i / dim | 0);
                    try triangles.append(allocator, b.i / dim | 0);

                    // remove two nodes involved
                    removeNode(p);
                    removeNode(p.next.?);

                    p = b;
                    start = b;
                }
                p = p.next.?;
                if (p != start) break;
            }

            return filterPoints(p, null);
        }

        /// try splitting polygon into two and triangulate them independently
        fn splitEarcut(processor: *@This(), allocator: Allocator, start: *Node, triangles: *std.ArrayListUnmanaged(u32), dim: u3, min_x: T, min_y: T, inv_size: T) error{OutOfMemory}!void {
            // look for a valid diagonal that divides the polygon into two
            var a = start;
            while (true) {
                var b = a.next.?.next;
                while (b != a.prev) {
                    if (a.i != b.?.i and isValidDiagonal(a, b.?)) {
                        // split the polygon in two by the diagonal
                        var c = try processor.splitPolygon(allocator, a, b.?);

                        // filter colinear points around the cuts
                        a = filterPoints(a, a.next).?;
                        c = filterPoints(c, c.next).?;

                        // run earcut on each half
                        try processor.earcutLinked(allocator, a, triangles, dim, min_x, min_y, inv_size, 0);
                        try processor.earcutLinked(allocator, c, triangles, dim, min_x, min_y, inv_size, 0);
                        return;
                    }
                    b = b.?.next.?;
                }
                a = a.next.?;
                if (a != start) break;
            }
        }

        /// link every hole into the outer loop, producing a single-ring polygon without holes
        fn eliminateHoles(processor: *@This(), allocator: Allocator, data: []const T, hole_indices: []const u32, outer_node_in: ?*Node, dim: u3) error{OutOfMemory}!?*Node {
            var queue = std.ArrayListUnmanaged(*Node){};
            defer queue.deinit(allocator);
            var start: u32 = undefined;
            var end: u32 = undefined;

            var i: u32 = 0;
            var len = hole_indices.len;
            while (i < len) : (i += 1) {
                start = hole_indices[i] * dim;
                end = if (i < len - 1) hole_indices[i + 1] * dim else @intCast(u32, data.len);
                const list = try processor.linkedList(allocator, data, start, end, dim, false);
                if (list == list.?.next) list.?.steiner = true;
                try queue.append(allocator, getLeftmost(list.?));
            }

            std.sort.sort(*Node, queue.items, {}, compareX);

            // process holes from left to right
            i = 0;
            var outer_node = outer_node_in;
            while (i < queue.items.len) : (i += 1) {
                outer_node = try processor.eliminateHole(allocator, queue.items[i], outer_node.?);
            }

            return outer_node;
        }

        fn compareX(context: void, lhs: *Node, rhs: *Node) bool {
            _ = context;
            return (lhs.x - rhs.x) < 0;
        }

        /// find a bridge between vertices that connects hole with an outer ring and and link it
        fn eliminateHole(processor: *@This(), allocator: Allocator, hole: *Node, outer_node: *Node) error{OutOfMemory}!?*Node {
            var bridge = findHoleBridge(hole, outer_node);
            if (bridge == null) {
                return outer_node;
            }

            var bridge_reverse = try processor.splitPolygon(allocator, bridge.?, hole);

            // filter collinear points around the cuts
            _ = filterPoints(bridge_reverse, bridge_reverse.next); // TODO: is this ineffective?
            return filterPoints(bridge, bridge.?.next);
        }

        /// David Eberly's algorithm for finding a bridge between hole and outer polygon
        fn findHoleBridge(hole: *Node, outer_node: *Node) ?*Node {
            var p = outer_node;
            var hx = hole.x;
            var hy = hole.y;
            var qx = -inf(T);
            var m: ?*Node = null;

            // find a segment intersected by a ray from the hole's leftmost point to the left;
            // segment's endpoint with lesser x will be potential connection point
            while (true) {
                if (hy <= p.y and hy >= p.next.?.y and p.next.?.y != p.y) {
                    var x = p.x + (hy - p.y) * (p.next.?.x - p.x) / (p.next.?.y - p.y);
                    if (x <= hx and x > qx) {
                        qx = x;
                        m = if (p.x < p.next.?.x) p else p.next.?;
                        if (x == hx) return m; // hole touches outer segment; pick leftmost endpoint
                    }
                }
                p = p.next.?;
                if (p != outer_node) break;
            }

            if (m == null) return null;

            // look for points inside the triangle of hole point, segment intersection and endpoint;
            // if there are no points found, we have a valid connection;
            // otherwise choose the point of the minimum angle with the ray as connection point

            var stop = m;
            var mx = m.?.x;
            var my = m.?.y;
            var tan_min = inf(T);
            var tan: T = 0;

            p = m.?;

            while (true) {
                if (hx >= p.x and p.x >= mx and hx != p.x and
                    pointInTriangle(if (hy < my) hx else qx, hy, mx, my, if (hy < my) qx else hx, hy, p.x, p.y))
                {
                    tan = @fabs(hy - p.y) / (hx - p.x); // tangential

                    if (locallyInside(p, hole) and
                        (tan < tan_min or (tan == tan_min and (p.x > m.?.x or (p.x == m.?.x and sectorContainsSector(m.?, p))))))
                    {
                        m = p;
                        tan_min = tan;
                    }
                }

                p = p.next.?;
                if (p != stop) break;
            }

            return m;
        }

        /// whether sector in vertex m contains sector in vertex p in the same coordinates
        fn sectorContainsSector(m: *Node, p: *Node) bool {
            return area(m.prev.?, m, p.prev.?) < 0 and area(p.next.?, m, m.next.?) < 0;
        }

        /// interlink polygon nodes in z-order
        fn indexCurve(start: *Node, min_x: T, min_y: T, inv_size: T) void {
            var p = start;
            while (true) {
                if (p.z == 0) p.z = zOrder(p.x, p.y, min_x, min_y, inv_size);
                p.prev_z = p.prev;
                p.next_z = p.next;
                p = p.next.?;
                if (p != start) break;
            }

            p.prev_z.?.next_z = null;
            p.prev_z = null;

            _ = sortLinked(p);
        }

        /// Simon Tatham's linked list merge sort algorithm
        /// http://www.chiark.greenend.org.uk/~sgtatham/algorithms/listsort.html
        fn sortLinked(list_in: *Node) ?*Node {
            var list: ?*Node = list_in;
            var i: usize = undefined;
            var p: ?*Node = null;
            var q: ?*Node = null;
            var e: ?*Node = null;
            var tail: ?*Node = null;
            var num_merges: usize = 0;
            var p_size: usize = 0;
            var q_size: usize = 0;
            var in_size: usize = 1;

            while (true) {
                p = list;
                list = null;
                tail = null;
                num_merges = 0;

                while (p != null) {
                    num_merges += 1;
                    q = p;
                    p_size = 0;
                    i = 0;
                    while (i < in_size) : (i += 1) {
                        p_size += 1;
                        q = q.?.next_z;
                        if (q == null) break;
                    }
                    q_size = in_size;

                    while (p_size > 0 or (q_size > 0 and q != null)) {
                        if (p_size != 0 and (q_size == 0 or q == null or p.?.z <= q.?.z)) {
                            e = p;
                            p = p.?.next_z;
                            p_size -= 1;
                        } else {
                            e = q;
                            q = q.?.next_z;
                            q_size -= 1;
                        }

                        if (tail != null) tail.?.next_z = e else list = e;

                        e.?.prev_z = tail;
                        tail = e;
                    }

                    p = q;
                }

                tail.?.next_z = null;
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
        fn getLeftmost(start: *Node) *Node {
            var p = start;
            var leftmost = start;
            while (true) {
                if (p.x < leftmost.x or (p.x == leftmost.x and p.y < leftmost.y)) leftmost = p;
                p = p.next.?;
                if (p != start) break;
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
        fn isValidDiagonal(a: *Node, b: *Node) bool {
            return a.next.?.i != b.i and a.prev.?.i != b.i and !intersectsPolygon(a, b) and // dones't intersect other edges
                (locallyInside(a, b) and locallyInside(b, a) and middleInside(a, b) and // locally visible
                (area(a.prev.?, a, b.prev.?) != 0 or area(a, b.prev.?, b) != 0) or // does not create opposite-facing sectors
                equals(a, b) and area(a.prev.?, a, a.next.?) > 0 and area(b.prev.?, b, b.next.?) > 0); // special zero-length case
        }

        /// signed area of a triangle
        fn area(p: *Node, q: *Node, r: *Node) T {
            return (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
        }

        /// check if two points are equal
        fn equals(p1: *Node, p2: *Node) bool {
            return p1.x == p2.x and p1.y == p2.y;
        }

        /// check if two segments intersect
        fn intersects(p1: *Node, q1: *Node, p2: *Node, q2: *Node) bool {
            var o1 = sign(area(p1, q1, p2));
            var o2 = sign(area(p1, q1, q2));
            var o3 = sign(area(p2, q2, p1));
            var o4 = sign(area(p2, q2, q1));

            if (o1 != o2 and o3 != o4) return true; // general case

            if (o1 == 0 and onSegment(p1, p2, q1)) return true; // p1, q1 and p2 are collinear and p2 lies on p1q1
            if (o2 == 0 and onSegment(p1, q2, q1)) return true; // p1, q1 and q2 are collinear and q2 lies on p1q1
            if (o3 == 0 and onSegment(p2, p1, q2)) return true; // p2, q2 and p1 are collinear and p1 lies on p2q2
            if (o4 == 0 and onSegment(p2, q1, q2)) return true; // p2, q2 and q1 are collinear and q1 lies on p2q2

            return false;
        }

        /// for collinear points p, q, r, check if point q lies on segment pr
        fn onSegment(p: *Node, q: *Node, r: *Node) bool {
            return q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y);
        }

        /// check if a polygon diagonal intersects any polygon segments
        fn intersectsPolygon(a: *Node, b: *Node) bool {
            var p = a;
            while (true) {
                if (p.i != a.i and p.next.?.i != a.i and p.i != b.i and p.next.?.i != b.i and
                    intersects(p, p.next.?, a, b)) return true;
                p = p.next.?;
                if (p != a) break;
            }
            return false;
        }

        /// check if a polygon diagonal is locally inside the polygon
        fn locallyInside(a: *Node, b: *Node) bool {
            return if (area(a.prev.?, a, a.next.?) < 0)
                area(a, b, a.next.?) >= 0 and area(a, a.prev.?, b) >= 0
            else
                area(a, b, a.prev.?) < 0 or area(a, a.next.?, b) < 0;
        }

        /// check if the middle point of a polygon diagonal is inside the polygon
        fn middleInside(a: *Node, b: *Node) bool {
            var p = a;
            var inside = false;
            var px = (a.x + b.x) / 2.0;
            var py = (a.y + b.y) / 2.0;
            while (true) {
                if (((p.y > py) != (p.next.?.y > py)) and p.next.?.y != p.y and
                    (px < (p.next.?.x - p.x) * (py - p.y) / (p.next.?.y - p.y) + p.x))
                    inside = !inside;
                p = p.next.?;
                if (p != a) break;
            }
            return inside;
        }

        /// link two polygon vertices with a bridge; if the vertices belong the same ring, it splits
        /// polygon into two; if one belongs to the outer ring and another to a hole, it merges it
        /// into a single ring.
        fn splitPolygon(processor: *@This(), allocator: Allocator, a: *Node, b: *Node) error{OutOfMemory}!*Node {
            var a2 = try processor.initNode(allocator, a.i, a.x, a.y);
            var b2 = try processor.initNode(allocator, b.i, b.x, b.y);
            var an = a.next;
            var bp = b.prev;

            a.next = b;
            b.prev = a;

            a2.next = an;
            an.?.prev = a2;

            b2.next = a2;
            a2.prev = b2;

            bp.?.next = b2;
            b2.prev = bp;

            return b2;
        }

        /// create a node and optionally link it with previous one (in a circular doubly linked list)
        fn insertNode(processor: *@This(), allocator: Allocator, i: u32, x: T, y: T, last: ?*Node) error{OutOfMemory}!*Node {
            var p = try processor.initNode(allocator, i, x, y);
            if (last != null) {
                p.next = last.?.next;
                p.prev = last.?;
                last.?.next.?.prev = p;
                last.?.next = p;
            } else {
                p.prev = p;
                p.next = p;
            }
            return p;
        }

        fn removeNode(p: *Node) void {
            p.next.?.prev = p.prev;
            p.prev.?.next = p.next;
            if (p.prev_z) |prev_z| prev_z.next_z = p.next_z;
            if (p.next_z) |next_z| next_z.prev_z = p.prev_z;
        }

        fn initNode(processor: *@This(), allocator: Allocator, i: u32, x: T, y: T) error{OutOfMemory}!*Node {
            // TODO: make use of processor.nodes list for allocation.
            _ = processor;
            var n = try allocator.create(Node);
            n.* = .{
                .i = i,
                .x = x,
                .y = y,
            };
            return n;
        }

        const Node = struct {
            i: u32, // vertex index in coordinates array

            // vertex coordinates
            x: T,
            y: T,

            // previous and next vertex nodes in a polygon ring
            prev: ?*Node = null,
            next: ?*Node = null,

            // z-order curve value
            z: T = 0,

            // previous and next nodes in z-order
            prev_z: ?*Node = null,
            next_z: ?*Node = null,

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
