const std = @import("std");
const builtin = @import("builtin");
const t = std.testing;
const Vec2 = @Vector(2, f32);
const zm = @import("zmath");
const RbTree = @import("data_structures/rb_tree.zig").RbTree;

inline fn cross(v1: Vec2, v2: Vec2) f32 {
    return v1[0] * v2[1] - v1[1] * v2[0];
}

pub fn dassert(pred: bool) void {
    if (builtin.mode == .Debug) {
        std.debug.assert(pred);
    }
}
const CompactSinglyLinkedListBuffer = @import("data_structures/compact.zig").CompactSinglyLinkedListBuffer;

const trace = @import("tracy.zig").trace;

const log_ = std.log.scoped(.tessellator);

const DeferredVertexNodeId = u16;
const NullId = @import("data_structures/compact.zig").CompactNull(DeferredVertexNodeId);

const EventQueue = std.PriorityQueue(u32, *std.ArrayList(Event), compareEventIdx);

const debug = false and builtin.mode == .Debug;

pub fn log(comptime format: []const u8, args: anytype) void {
    if (debug) {
        log_.debug(format, args);
    }
}

pub const Tessellator = struct {
    /// Buffers.
    verts: std.ArrayList(InternalVertex),
    events: std.ArrayList(Event),
    event_q: EventQueue,
    sweep_edges: RbTree(u16, SweepEdge, Event, compareSweepEdge),
    deferred_verts: CompactSinglyLinkedListBuffer(DeferredVertexNodeId, DeferredVertexNode),

    /// Verts to output.
    /// No duplicate verts will be outputed to reduce size footprint.
    /// Since some verts won't be discovered until during the processing of events (edge intersections),
    /// verts are added as the events are processed. As a result, the verts are also in order y-asc and x-asc.
    out_verts: std.ArrayList(Vec2),

    /// Triangles to output are triplets of indexes that point to verts. They are in ccw direction.
    out_idxes: std.ArrayList(u16),

    cur_x: f32,
    cur_y: f32,
    cur_out_vert_idx: u16,
    cur_polys: []const []const Vec2,

    const Self = @This();

    pub fn init(self: *Self, alloc: std.mem.Allocator) void {
        self.* = .{
            .verts = std.ArrayList(InternalVertex).init(alloc),
            .events = std.ArrayList(Event).init(alloc),
            .event_q = undefined,
            .sweep_edges = RbTree(u16, SweepEdge, Event, compareSweepEdge).init(alloc, undefined),
            .deferred_verts = CompactSinglyLinkedListBuffer(DeferredVertexNodeId, DeferredVertexNode).init(alloc),
            .out_verts = std.ArrayList(Vec2).init(alloc),
            .out_idxes = std.ArrayList(u16).init(alloc),
            .cur_x = undefined,
            .cur_y = undefined,
            .cur_out_vert_idx = undefined,
            .cur_polys = undefined,
        };
        self.event_q = EventQueue.init(alloc, &self.events);
    }

    pub fn deinit(self: *Self) void {
        self.verts.deinit();
        self.events.deinit();
        self.event_q.deinit();
        self.sweep_edges.deinit();
        self.deferred_verts.deinit();
        self.out_verts.deinit();
        self.out_idxes.deinit();
    }

    pub fn clearBuffers(self: *Self) void {
        self.verts.clearRetainingCapacity();
        self.events.clearRetainingCapacity();
        self.event_q.len = 0;
        self.sweep_edges.clearRetainingCapacity();
        self.deferred_verts.clearRetainingCapacity();
        self.out_verts.clearRetainingCapacity();
        self.out_idxes.clearRetainingCapacity();
    }

    pub fn triangulatePolygon(self: *Self, polygon: []const Vec2) void {
        self.triangulatePolygons(&.{polygon});
    }

    /// Perform a plane sweep to triangulate a complex polygon in one pass.
    /// The output returns ccw triangle vertices and indexes ready to be fed into the gpu.
    /// This uses Bentley-Ottmann to handle self intersecting edges.
    /// Rules are followed to partition into y-monotone polygons and triangulate them.
    /// This is ported from the JS implementation (tessellator.js) where it is easier to prototype.
    /// Since the number of verts and indexes is not known beforehand, the output is an ArrayList.
    /// TODO: See if inline callbacks would be faster to directly push data to the batcher buffer.
    pub fn triangulatePolygons(self: *Self, polygons: []const []const Vec2) void {
        // Construct the initial events by traversing the polygon.
        self.initEvents(polygons);

        self.cur_x = std.math.f32_min;
        self.cur_y = std.math.f32_min;
        self.cur_out_vert_idx = std.math.maxInt(u16);
        self.cur_polys = polygons;

        // Process events.
        while (self.event_q.removeOrNull()) |e_id| {
            self.processEvent(e_id);
        }
    }

    /// Initializes the events only.
    pub fn debugTriangulatePolygons(self: *Self, polygons: []const []const Vec2) void {
        self.initEvents(polygons);
        self.cur_x = std.math.f32_min;
        self.cur_y = std.math.f32_min;
        self.cur_out_vert_idx = std.math.maxInt(u16);
        self.cur_polys = polygons;
    }

    /// Process the next event. This can be used with debugTriangulatePolygons.
    pub fn debugProcessNext(self: *Self, alloc: std.mem.Allocator) ?DebugTriangulateStepResult {
        const e_id = self.event_q.removeOrNull() orelse return null;
        self.processEvent(e_id);

        return DebugTriangulateStepResult{
            .has_result = true,
            .event = self.events.items[e_id],
            .sweep_edges = self.sweep_edges.allocValuesInOrder(alloc),
            .out_verts = alloc.dupe(Vec2, self.out_verts.items) catch unreachable,
            .out_idxes = alloc.dupe(u16, self.out_idxes.items) catch unreachable,
            .verts = alloc.dupe(InternalVertex, self.verts.items) catch unreachable,
            .deferred_verts = alloc.dupe(CompactSinglyLinkedListBuffer(DeferredVertexNodeId, DeferredVertexNode).Node, self.deferred_verts.nodes.data.items) catch unreachable,
        };
    }

    fn processEvent(self: *Self, e_id: u32) void {
        const t_ = trace(@src());
        defer t_.end();
        const sweep_edges = &self.sweep_edges;

        const e = self.events.items[e_id];

        // If the point changed, allocate a new out vertex index.
        if (e.vert_x != self.cur_x or e.vert_y != self.cur_y) {
            self.out_verts.append(Vec2{ e.vert_x, e.vert_y }) catch unreachable;
            self.cur_out_vert_idx +%= 1;
            self.cur_x = e.vert_x;
            self.cur_y = e.vert_y;
        }

        // Set the out vertex index on the event.
        self.verts.items[e.vert_idx].out_idx = self.cur_out_vert_idx;

        if (debug) {
            const tag_str: []const u8 = if (e.tag == .Start) "Start" else "End";
            log("--process event {}, ({},{}) {s} {s}", .{ e.vert_idx, e.vert_x, e.vert_y, tag_str, edgeToString(e.edge) });
            log("sweep edges: ", .{});
            var mb_cur = sweep_edges.first();
            while (mb_cur) |cur| {
                const se = sweep_edges.get(cur).?;
                log("{} -> {}", .{ se.edge.start_idx, se.edge.end_idx });
                mb_cur = sweep_edges.getNext(cur);
            }
        }

        if (e.tag == .Start) {
            // Check to remove a previous left edge and continue it's sub-polygon vertex queue.
            sweep_edges.ctx = e;
            const new_id = sweep_edges.insert(SweepEdge.init(e, self.verts.items)) catch unreachable;
            const new = sweep_edges.getPtr(new_id).?;

            log("start new sweep edge {}", .{new_id});

            var mb_left_id = sweep_edges.getPrev(new_id);
            // Update winding based on what is to the left.
            if (mb_left_id == null) {
                new.interior_is_left = false;
            } else {
                new.interior_is_left = !sweep_edges.get(mb_left_id.?).?.interior_is_left;
            }

            if (new.interior_is_left) {
                log("initially interior to the left", .{});
                // Initially appears to be a right edge but if it connects to the previous left, it becomes a left edge.
                var left = sweep_edges.getPtrNoCheck(mb_left_id.?);
                const e_vert_out_idx = self.verts.items[e.vert_idx].out_idx;
                if (left.end_event_vert_uniq_idx == e_vert_out_idx) {
                    // Remove the previous ended edge, and takes it's place as the left edge.
                    defer sweep_edges.remove(mb_left_id.?) catch unreachable;
                    new.interior_is_left = false;
                    log("continuation from prev edge, interior to the right", .{});

                    // Previous left edge and this new edge forms a regular left angle.
                    // Check for bad up cusp.
                    if (left.bad_up_cusp_uniq_idx != NullId) {
                        // This monotone polygon (a) should already have run it's triangulate steps from the left edge's end event.
                        //   \  /
                        //  a \/ b
                        //    ^ Bad cusp.
                        // \_
                        // ^ End event from left edge happened before, currently processing start event for the new connected edge.

                        // A line is connected from this vertex to the bad cusp to ensure that polygon (a) is monotone and polygon (b) is monotone.
                        // Since polygon (a) already ran it's triangulate step, it's done from this side of the polygon.
                        // This start event will create a new sweep edge, so transfer the deferred queue from the bad cusp's right side. (it is now the queue for this new left edge).
                        const bad_right = sweep_edges.getNoCheck(left.bad_up_cusp_right_sweep_edge_id);
                        bad_right.dumpQueue(self);
                        new.deferred_queue = bad_right.deferred_queue;
                        new.deferred_queue_size = bad_right.deferred_queue_size;
                        new.cur_side = bad_right.cur_side;

                        // Also run triangulate on polygon (b) for the new vertex since the end event was already run for polygon (a).
                        self.triangulateLeftStep(new, self.verts.items[e.vert_idx]);

                        left.bad_up_cusp_uniq_idx = NullId;
                        sweep_edges.removeDetached(left.bad_up_cusp_right_sweep_edge_id);

                        log("FIX BAD UP CUSP", .{});
                        new.dumpQueue(self);
                    } else {
                        new.deferred_queue = left.deferred_queue;
                        new.deferred_queue_size = left.deferred_queue_size;
                        new.cur_side = left.cur_side;
                    }
                } else if (left.start_event_vert_uniq_idx == e_vert_out_idx) {
                    // Down cusp.
                    log("DOWN CUSP", .{});
                }
            } else {
                log("initially interior to the right", .{});
                // Initially appears to be a left edge but if it connects to a previous right, it becomes a right edge.
                if (mb_left_id != null) {
                    const vert = self.verts.items[e.vert_idx];

                    // left edge has interior to the left.
                    var left = sweep_edges.get(mb_left_id.?).?;
                    if (left.end_event_vert_uniq_idx == vert.out_idx) {
                        // Remove previous ended edge.
                        sweep_edges.remove(mb_left_id.?) catch unreachable;
                        new.interior_is_left = true;
                        log("changed to interior is left", .{});
                    } else if (left.start_event_vert_uniq_idx == vert.out_idx) {
                        // Linked to previous start event's vertex.
                        // Handle bad down cusp.
                        // \       \/
                        //  \       b
                        //   \--a
                        //    \       v Bad down cusp.
                        //     \     /\     /
                        //      \   /  \   /

                        // The bad cusp is linked to the lowest visible vertex seen from the left edge. If vertex (a) exists that would be connected to the cusp.
                        // If it didn't exist the next lowest would be (b) a bad up cusp.

                        const left_left_id = sweep_edges.getPrev(mb_left_id.?).?;
                        const left_left = sweep_edges.getPtrNoCheck(left_left_id);
                        log("handle bad down cusp {}", .{left_left.lowest_right_vert_idx});
                        if (left_left.lowest_right_vert_idx == NullId) {
                            log("expected lowest right vert", .{});
                            unreachable;
                        }

                        const low_poly_edge = sweep_edges.getPtrNoCheck(left_left.lowest_right_vert_sweep_edge_id);
                        if (left_left_id == left_left.lowest_right_vert_sweep_edge_id) {
                            // Lowest right point does NOT have a right side monotone polygon.

                            if (left_left.lowest_right_vert_idx == left_left.vert_idx) {
                                // Pass on the vertex queue.
                                new.deferred_queue = low_poly_edge.deferred_queue;
                                new.deferred_queue_size = low_poly_edge.deferred_queue_size;
                                new.cur_side = low_poly_edge.cur_side;
                                low_poly_edge.deferred_queue = NullId;
                                low_poly_edge.deferred_queue_size = 0;

                                self.triangulateLeftStep(new, vert);

                                // Cut off the existing left monotone polygon.
                                left_left.deferred_queue = NullId;
                                left_left.deferred_queue_size = 0;
                                left_left.cur_side = .Right;
                                left_left.enqueueDeferred(self.verts.items[left_left.lowest_right_vert_idx], self);
                                if (vert.out_idx != self.verts.items[left_left.lowest_right_vert_idx].out_idx) {
                                    left_left.enqueueDeferred(vert, self);
                                }
                                left_left.lowest_right_vert_idx = e.vert_idx;
                            } else {
                                // Initialize a new right side monotone polygon.
                                new.enqueueDeferred(self.verts.items[left_left.lowest_right_vert_idx], self);
                                new.enqueueDeferred(vert, self);
                                new.cur_side = .Left;

                                // Triangulate on the monotone polygon to the left of the lowest right point.
                                self.triangulateRightStep(left_left, vert);

                                left_left.lowest_right_vert_idx = e.vert_idx;
                            }
                        } else {
                            // Lowest right point does have a right side monotone polygon.

                            // Most likely a bad up cusp as well, so reset it since connecting to the lowest right fixes it.
                            left_left.bad_up_cusp_uniq_idx = NullId;

                            self.triangulateLeftStep(low_poly_edge, vert);

                            // Pass on the vertex queue.
                            new.deferred_queue = low_poly_edge.deferred_queue;
                            new.deferred_queue_size = low_poly_edge.deferred_queue_size;
                            new.cur_side = low_poly_edge.cur_side;
                            low_poly_edge.deferred_queue = NullId;
                            low_poly_edge.deferred_queue_size = 0;

                            // Triangulate on the monotone polygon to the left of the lowest right point.
                            self.triangulateRightStep(left_left, vert);

                            left_left.lowest_right_vert_idx = e.vert_idx;
                            left_left.lowest_right_vert_sweep_edge_id = left_left_id;
                        }
                    }
                }
            }

            if (!new.interior_is_left) {
                // Even-odd rule.
                // Interior is to the right.

                const vert = self.verts.items[e.vert_idx];

                // Initialize the deferred queue.
                if (new.deferred_queue == NullId) {
                    new.enqueueDeferred(vert, self);
                    new.cur_side = .Left;

                    log("initialize queue", .{});
                    new.dumpQueue(self);
                }

                // The lowest right vert is set initializes to itself.
                new.lowest_right_vert_idx = e.vert_idx;
                new.lowest_right_vert_sweep_edge_id = new_id;
            } else {
                // Interior is to the left.
            }

            // Check intersection with the left. Fetch left again since it could be removed from an up cusp.
            mb_left_id = sweep_edges.getPrev(new_id);
            if (mb_left_id != null) {
                log("check left intersect", .{});
                var left = sweep_edges.getPtrNoCheck(mb_left_id.?);
                const res = computeTwoEdgeIntersect(new.edge, left.edge);
                log("{},{}->{},{} {},{}->{},{} {} {}", .{ new.edge.start_pos[0], new.edge.start_pos[1], new.edge.end_pos[0], new.edge.end_pos[1], left.edge.start_pos[0], left.edge.start_pos[1], left.edge.end_pos[0], left.edge.end_pos[1], res.has_intersect, res.t });
                if (res.has_intersect and res.t > 0 and res.t < 1) {
                    self.handleIntersectForStartEvent(new, left, res, Vec2{ e.vert_x, e.vert_y });
                }
            }
            const mb_right_id = sweep_edges.getNext(new_id);
            if (mb_right_id != null) {
                // Check for intersection with the edge to the right.
                log("check right intersect", .{});

                // TODO: Is there a preliminary check to avoid doing the math? One idea is to check the x_slopes but it would need to know
                // if the compared edge is pointing down or up.
                const right = sweep_edges.getPtrNoCheck(mb_right_id.?);
                const res = computeTwoEdgeIntersect(new.edge, right.edge);
                if (res.has_intersect and res.t > 0 and res.t < 1) {
                    self.handleIntersectForStartEvent(new, right, res, Vec2{ e.vert_x, e.vert_y });
                }
            }
        } else {
            // End event.

            if (e.invalidated) {
                // This end event was invalidated from an intersection event.
                return;
            }

            const active_id = findSweepEdgeForEndEvent(sweep_edges, e) orelse {
                log("polygons: {any}", .{self.cur_polys});
                @panic("expected active edge");
            };
            const active = sweep_edges.getPtrNoCheck(active_id);
            log("active {} {}", .{ active.vert_idx, active.to_vert_idx });

            const vert = self.verts.items[e.vert_idx];

            if (active.interior_is_left) {
                // Interior is to the left.

                log("interior to the left {}", .{active_id});

                const left_id = sweep_edges.getPrev(active_id).?;
                const left = sweep_edges.getPtrNoCheck(left_id);

                // Check if it has closed the polygon. (up cusp)
                if (vert.out_idx == left.end_event_vert_uniq_idx) {
                    // Check for bad up cusp.
                    if (left.bad_up_cusp_uniq_idx != NullId) {
                        const bad_right = sweep_edges.getPtrNoCheck(left.bad_up_cusp_right_sweep_edge_id);
                        // Close off monotone polygon to the right of the bad up cusp.
                        self.triangulateLeftStep(bad_right, vert);
                        sweep_edges.removeDetached(left.bad_up_cusp_right_sweep_edge_id);
                        left.bad_up_cusp_uniq_idx = NullId;
                        left.lowest_right_vert_idx = e.vert_idx;
                        left.lowest_right_vert_sweep_edge_id = left_id;
                        if (bad_right.deferred_queue_size >= 3) {
                            log("{any}", .{self.out_idxes.items});
                            bad_right.dumpQueue(self);
                            @panic("did not expect left over vertices");
                        }
                    }
                    if (left.deferred_queue_size >= 3) {
                        log("{} {any}", .{ left_id, self.out_idxes.items });
                        left.dumpQueue(self);
                        @panic("did not expect left over vertices");
                    }
                    // Remove the left edge and this edge.
                    sweep_edges.remove(left_id) catch unreachable;
                    sweep_edges.remove(active_id) catch unreachable;
                } else {
                    // Regular right side vertex.

                    // Check for bad up cusp.
                    if (left.bad_up_cusp_uniq_idx != NullId) {
                        const bad_right = sweep_edges.getPtrNoCheck(left.bad_up_cusp_right_sweep_edge_id);
                        // Close off monotone polygon to the right of the bad up cusp.
                        self.triangulateRightStep(bad_right, vert);
                        left.lowest_right_vert_idx = vert.idx;
                        left.lowest_right_vert_sweep_edge_id = left_id;
                        sweep_edges.removeDetached(left.bad_up_cusp_right_sweep_edge_id);
                        left.bad_up_cusp_uniq_idx = NullId;
                        if (bad_right.deferred_queue_size >= 3) {
                            log("{any}", .{self.out_idxes.items});
                            bad_right.dumpQueue(self);
                            @panic("did not expect left over vertices");
                        }
                    }
                    // Left belongs to the same monotone polygon.
                    self.triangulateRightStep(left, vert);

                    // Edge is only removed by the next connecting edge.
                    active.end_event_vert_uniq_idx = vert.out_idx;
                }
            } else {
                // Interior is to the right.
                log("interior to the right {}", .{active_id});

                const mb_left_id = sweep_edges.getPrev(active_id);

                // Check to fix a bad up cusp to the right.
                if (active.bad_up_cusp_uniq_idx != NullId) {
                    const bad_right = sweep_edges.getPtrNoCheck(active.bad_up_cusp_right_sweep_edge_id);
                    // Close off monotone polygon in between this active edge and the bad up cusp.
                    self.triangulateLeftStep(active, vert);
                    if (active.deferred_queue_size >= 3) {
                        log("{any}", .{self.out_idxes.items});
                        active.dumpQueue(self);
                        @panic("did not expect left over vertices");
                    }
                    active.lowest_right_vert_idx = NullId;
                    active.lowest_right_vert_sweep_edge_id = NullId;
                    sweep_edges.removeDetached(active.bad_up_cusp_right_sweep_edge_id);
                    active.bad_up_cusp_uniq_idx = NullId;
                    // Extend the monotone polygon to the right of the bad up cusp to this vertex.
                    self.triangulateLeftStep(bad_right, vert);
                    active.deferred_queue = bad_right.deferred_queue;
                    active.deferred_queue_size = bad_right.deferred_queue_size;
                } else {
                    active.dumpQueue(self);
                    self.triangulateLeftStep(active, vert);
                    active.dumpQueue(self);
                }

                // Check if this forms a bad up cusp with the right edge to the left monotone polygon.
                var removed = false;
                if (mb_left_id != null) {
                    log("check to set bad up cusp", .{});
                    const left = sweep_edges.getNoCheck(mb_left_id.?);
                    // dump(edgeToString(left_right_edge.edge))
                    if (vert.out_idx == left.end_event_vert_uniq_idx) {
                        const left_left_id = sweep_edges.getPrev(mb_left_id.?).?;
                        const left_left = sweep_edges.getPtrNoCheck(left_left_id);
                        // Bad up cusp.
                        left_left.bad_up_cusp_uniq_idx = vert.out_idx;
                        left_left.bad_up_cusp_right_sweep_edge_id = active_id;
                        left_left.lowest_right_vert_idx = e.vert_idx;
                        left_left.lowest_right_vert_sweep_edge_id = active_id;

                        // Remove the left edge.
                        sweep_edges.remove(mb_left_id.?) catch unreachable;
                        // Detach this edge, remove it when the bad up cusp is fixed.
                        sweep_edges.detach(active_id) catch unreachable;
                        removed = true;
                        // Continue.
                    }
                }

                if (!removed) {
                    // Don't remove the left edge of this sub-polygon yet.
                    // Record the end event's vert so the next start event that continues from this vert can persist the deferred vertices and remove this sweep edge.
                    // It can also be removed by a End right edge.
                    active.end_event_vert_uniq_idx = vert.out_idx;
                }
            }
        }
    }

    inline fn addTriangle(self: *Self, v1_out: u16, v2_out: u16, v3_out: u16) void {
        log("triangle {} {} {}", .{ v1_out, v2_out, v3_out });
        self.out_idxes.appendSlice(&.{ v1_out, v2_out, v3_out }) catch unreachable;
    }

    /// Parses the polygon pts and adds the initial events into the priority queue.
    fn initEvents(self: *Self, polygons: []const []const Vec2) void {
        const t_ = trace(@src());
        defer t_.end();
        for (polygons) |polygon| {
            // Find the starting point that is not equal to the last vertex point.
            // Since we are adding events to a priority queue, we need to make sure each add is final.
            var start_idx: u16 = 0;
            const last_pt = polygon[polygon.len - 1];
            while (start_idx < polygon.len) : (start_idx += 1) {
                const pt = polygon[start_idx];

                // Add internal vertex even though we are skipping events for it to keep the idxes consistent with the input.
                const v = InternalVertex{
                    .pos = pt,
                    .idx = start_idx,
                };
                self.verts.append(v) catch unreachable;

                if (@fabs(last_pt[0] - pt[0]) > 1e-4 or @fabs(last_pt[1] - pt[1]) > 1e-4) {
                    break;
                } else {
                    self.verts.items[self.verts.items.len - 1].idx = NullId;
                }
            }

            var last_v = self.verts.items[start_idx];
            var last_v_idx = start_idx;

            var i: u16 = start_idx + 1;
            while (i < polygon.len) : (i += 1) {
                const v_idx = @intCast(u16, self.verts.items.len);
                const v = InternalVertex{
                    .pos = polygon[i],
                    .idx = i,
                };
                self.verts.append(v) catch unreachable;

                if (@fabs(last_v.pos[0] - v.pos[0]) < 1e-4 and @fabs(last_v.pos[1] - v.pos[1]) < 1e-4) {
                    // Don't connect two vertices that are on top of each other.
                    // Allowing this would require edge cases during event processing to make sure things don't break.
                    // Push the vertex in anyway so there is consistency with the input.
                    self.verts.items[self.verts.items.len - 1].idx = NullId;
                    continue;
                }

                const prev_edge = Edge.init(last_v_idx, last_v, v_idx, v);
                const event1_idx = @intCast(u32, self.events.items.len);
                var event1: Event = undefined;
                var event2: Event = undefined;
                if (Event.isStartEvent(last_v_idx, prev_edge, self.verts.items)) {
                    event1 = Event.init(last_v, prev_edge, .Start);
                    event2 = Event.init(v, prev_edge, .End);
                    event1.end_event_idx = event1_idx + 1;
                } else {
                    event1 = Event.init(last_v, prev_edge, .End);
                    event2 = Event.init(v, prev_edge, .Start);
                    event2.end_event_idx = event1_idx;
                }
                self.events.append(event1) catch unreachable;
                self.event_q.add(event1_idx) catch unreachable;
                self.events.append(event2) catch unreachable;
                self.event_q.add(event1_idx + 1) catch unreachable;
                last_v = v;
                last_v_idx = v_idx;
            }
            // Link last pt to start pt.
            const edge = Edge.init(last_v_idx, last_v, start_idx, self.verts.items[start_idx]);
            const event1_idx = @intCast(u32, self.events.items.len);
            var event1: Event = undefined;
            var event2: Event = undefined;
            if (Event.isStartEvent(last_v_idx, edge, self.verts.items)) {
                event1 = Event.init(last_v, edge, .Start);
                event2 = Event.init(self.verts.items[start_idx], edge, .End);
                event1.end_event_idx = event1_idx + 1;
            } else {
                event1 = Event.init(last_v, edge, .End);
                event2 = Event.init(self.verts.items[start_idx], edge, .Start);
                event2.end_event_idx = event1_idx;
            }
            self.events.append(event1) catch unreachable;
            self.event_q.add(event1_idx) catch unreachable;
            self.events.append(event2) catch unreachable;
            self.event_q.add(event1_idx + 1) catch unreachable;
        }
    }

    fn triangulateLeftStep(self: *Self, left: *SweepEdge, vert: InternalVertex) void {
        if (left.cur_side == .Left) {
            log("same left side", .{});
            left.dumpQueue(self);

            // Same side.
            if (left.deferred_queue_size >= 2) {
                var last_id = left.deferred_queue;
                var last = self.deferred_verts.getNoCheck(last_id);
                if (last.vert_out_idx == vert.out_idx) {
                    // Ignore this point since it is the same as the last.
                    return;
                }
                var cur_id = self.deferred_verts.getNextNoCheck(last_id);
                var i: u16 = 0;
                while (i < left.deferred_queue_size - 1) : (i += 1) {
                    log("check to add inward tri {} {}", .{ last_id, cur_id });
                    const cur = self.deferred_verts.getNoCheck(cur_id);
                    const cxp = cross(Vec2{ last.vert_x - cur.vert_x, last.vert_y - cur.vert_y }, Vec2{ vert.pos[0] - last.vert_x, vert.pos[1] - last.vert_y });
                    if (cxp < 0) {
                        // Bends inwards. Fill triangles until we aren't bending inward.
                        self.addTriangle(vert.out_idx, cur.vert_out_idx, last.vert_out_idx);
                        self.deferred_verts.removeAssumeNoPrev(last_id) catch unreachable;
                    } else {
                        break;
                    }
                    last_id = cur_id;
                    last = cur;
                    cur_id = self.deferred_verts.getNextNoCheck(cur_id);
                }
                if (i > 0) {
                    const d_vert = self.deferred_verts.insertBeforeHeadNoCheck(last_id, DeferredVertexNode.init(vert)) catch unreachable;
                    left.deferred_queue = d_vert;
                    left.deferred_queue_size = left.deferred_queue_size - i + 1;
                } else {
                    left.enqueueDeferred(vert, self);
                }
            } else {
                left.enqueueDeferred(vert, self);
            }
        } else {
            log("changed to left side", .{});
            // Changed to left side.
            // Automatically create queue size - 1 triangles.
            var last_id = left.deferred_queue;
            var last = self.deferred_verts.getNoCheck(last_id);
            var cur_id = self.deferred_verts.getNextNoCheck(last_id);
            var i: u32 = 0;
            while (i < left.deferred_queue_size - 1) : (i += 1) {
                const cur = self.deferred_verts.getNoCheck(cur_id);
                self.addTriangle(vert.out_idx, last.vert_out_idx, cur.vert_out_idx);
                last_id = cur_id;
                last = cur;
                cur_id = self.deferred_verts.getNextNoCheck(cur_id);
                // Delete last after it's assigned to current.
                self.deferred_verts.removeAssumeNoPrev(last_id) catch unreachable;
            }
            left.dumpQueue(self);
            self.deferred_verts.getNodePtrNoCheck(left.deferred_queue).next = NullId;
            left.deferred_queue_size = 1;
            left.enqueueDeferred(vert, self);
            left.cur_side = .Left;
            left.dumpQueue(self);
        }
    }

    fn triangulateRightStep(self: *Self, left: *SweepEdge, vert: InternalVertex) void {
        if (left.cur_side == .Right) {
            log("right side", .{});
            // Same side.
            if (left.deferred_queue_size >= 2) {
                var last_id = left.deferred_queue;
                var last = self.deferred_verts.getNoCheck(last_id);
                if (last.vert_out_idx == vert.out_idx) {
                    // Ignore this point since it is the same as the last.
                    return;
                }
                var cur_id = self.deferred_verts.getNextNoCheck(last_id);
                var i: u16 = 0;
                while (i < left.deferred_queue_size - 1) : (i += 1) {
                    const cur = self.deferred_verts.getNoCheck(cur_id);
                    const cxp = cross(Vec2{ last.vert_x - cur.vert_x, last.vert_y - cur.vert_y }, Vec2{ vert.pos[0] - last.vert_x, vert.pos[1] - last.vert_y });
                    if (cxp > 0) {
                        // Bends inwards. Fill triangles until we aren't bending inward.
                        self.addTriangle(vert.out_idx, last.vert_out_idx, cur.vert_out_idx);
                        self.deferred_verts.removeAssumeNoPrev(last_id) catch unreachable;
                    } else {
                        break;
                    }
                    last_id = cur_id;
                    last = cur;
                    cur_id = self.deferred_verts.getNextNoCheck(cur_id);
                }
                if (i > 0) {
                    const d_vert = self.deferred_verts.insertBeforeHeadNoCheck(last_id, DeferredVertexNode.init(vert)) catch unreachable;
                    left.deferred_queue = d_vert;
                    left.deferred_queue_size = left.deferred_queue_size - i + 1;
                } else {
                    left.enqueueDeferred(vert, self);
                }
            } else {
                left.enqueueDeferred(vert, self);
            }
        } else {
            log("changed to right side", .{});
            var last_id = left.deferred_queue;
            var last = self.deferred_verts.getNoCheck(last_id);
            var cur_id = self.deferred_verts.getNextNoCheck(last_id);
            var i: u32 = 0;
            while (i < left.deferred_queue_size - 1) : (i += 1) {
                const cur = self.deferred_verts.getNoCheck(cur_id);
                self.addTriangle(vert.out_idx, cur.vert_out_idx, last.vert_out_idx);
                last_id = cur_id;
                last = cur;
                cur_id = self.deferred_verts.getNextNoCheck(cur_id);
                // Delete last after it's assigned to current.
                self.deferred_verts.removeAssumeNoPrev(last_id) catch unreachable;
            }
            self.deferred_verts.getNodePtrNoCheck(left.deferred_queue).next = NullId;
            left.deferred_queue_size = 1;
            left.enqueueDeferred(vert, self);
            left.cur_side = .Right;
            left.dumpQueue(self);
        }
    }

    /// Splits two edges at an intersect point.
    /// Assumes sweep edges have not processed their end events so they can be reinserted.
    /// Does not add new events if an event already exists to the intersect point.
    fn handleIntersectForStartEvent(self: *Self, sweep_edge_a: *SweepEdge, sweep_edge_b: *SweepEdge, intersect: IntersectResult, sweep_vert: Vec2) void {
        log("split intersect {}", .{intersect});

        // The intersect point must lie after the sweep_vert.
        if (intersect.y < sweep_vert[1] or (intersect.y == sweep_vert[1] and intersect.x <= sweep_vert[0])) {
            return;
        }

        var added_events = false;

        // Create new intersect vertex.
        const intersect_idx = @intCast(u16, self.verts.items.len);
        const intersect_v = InternalVertex{
            .pos = Vec2{ intersect.x, intersect.y },
            .idx = intersect_idx,
        };
        self.verts.append(intersect_v) catch unreachable;

        // TODO: Account for floating point error.
        const a_to_vert = self.verts.items[sweep_edge_a.to_vert_idx];
        if (a_to_vert.pos[0] != intersect.x or a_to_vert.pos[1] != intersect.y) {
            // log(edgeToString(sweep_edge_a.edge))
            log("adding edge a {} to {},{}", .{ sweep_edge_a.vert_idx, intersect.x, intersect.y });
            added_events = true;

            // Invalidate sweep_edge_a's end event since the priority queue can not be modified.
            self.events.items[sweep_edge_a.end_event_idx].invalidated = true;

            // Keep original edge orientation when doing the split.
            var first_edge: Edge = undefined;
            var second_edge: Edge = undefined;
            const start = self.verts.items[sweep_edge_a.edge.start_idx];
            const end = self.verts.items[sweep_edge_a.edge.end_idx];
            if (sweep_edge_a.to_vert_idx == sweep_edge_a.edge.start_idx) {
                first_edge = Edge.init(intersect_idx, intersect_v, sweep_edge_a.edge.end_idx, end);
                second_edge = Edge.init(sweep_edge_a.edge.start_idx, start, intersect_idx, intersect_v);
            } else {
                first_edge = Edge.init(sweep_edge_a.edge.start_idx, start, intersect_idx, intersect_v);
                second_edge = Edge.init(intersect_idx, intersect_v, sweep_edge_a.edge.end_idx, end);
            }

            // Update sweep_edge_a to end at the intersect.
            sweep_edge_a.edge = first_edge;
            const a_orig_to_vert = sweep_edge_a.to_vert_idx;
            sweep_edge_a.to_vert_idx = intersect_idx;

            // Insert new sweep_edge_a end event.
            const evt_idx = @intCast(u32, self.events.items.len);
            var new_evt = Event.init(intersect_v, first_edge, .End);
            self.events.append(new_evt) catch unreachable;
            self.event_q.add(evt_idx) catch unreachable;

            // Insert start/end event from the intersect to the end of the original sweep_edge_a.
            var event1: Event = undefined;
            var event2: Event = undefined;
            if (Event.isStartEvent(intersect_idx, second_edge, self.verts.items)) {
                event1 = Event.init(intersect_v, second_edge, .Start);
                event2 = Event.init(self.verts.items[a_orig_to_vert], second_edge, .End);
                event1.end_event_idx = evt_idx + 2;
            } else {
                event1 = Event.init(intersect_v, second_edge, .End);
                event2 = Event.init(self.verts.items[a_orig_to_vert], second_edge, .Start);
                event2.end_event_idx = evt_idx + 1;
            }
            self.events.append(event1) catch unreachable;
            self.event_q.add(evt_idx + 1) catch unreachable;
            self.events.append(event2) catch unreachable;
            self.event_q.add(evt_idx + 2) catch unreachable;
        }

        const b_to_vert = self.verts.items[sweep_edge_b.to_vert_idx];
        if (b_to_vert.pos[0] != intersect.x or b_to_vert.pos[1] != intersect.y) {
            log("adding edge b {} to {},{}", .{ sweep_edge_b.vert_idx, intersect.x, intersect.y });
            added_events = true;

            // Invalidate sweep_edge_b's end event since the priority queue can not be modified.
            log("invalidate: {} {}", .{ sweep_edge_b.end_event_idx, self.events.items.len });
            self.events.items[sweep_edge_b.end_event_idx].invalidated = true;

            // Keep original edge orientation when doing the split.
            var first_edge: Edge = undefined;
            var second_edge: Edge = undefined;
            const start = self.verts.items[sweep_edge_b.edge.start_idx];
            const end = self.verts.items[sweep_edge_b.edge.end_idx];
            if (sweep_edge_b.to_vert_idx == sweep_edge_b.edge.start_idx) {
                first_edge = Edge.init(intersect_idx, intersect_v, sweep_edge_b.edge.end_idx, end);
                second_edge = Edge.init(sweep_edge_b.edge.start_idx, start, intersect_idx, intersect_v);
            } else {
                first_edge = Edge.init(sweep_edge_b.edge.start_idx, start, intersect_idx, intersect_v);
                second_edge = Edge.init(intersect_idx, intersect_v, sweep_edge_b.edge.end_idx, end);
            }

            // Update sweep_edge_b to end at the intersect.
            sweep_edge_b.edge = first_edge;
            const b_orig_to_vert = sweep_edge_b.to_vert_idx;
            sweep_edge_b.to_vert_idx = intersect_idx;

            // Insert new sweep_edge_b end event.
            const evt_idx = @intCast(u32, self.events.items.len);
            var new_evt = Event.init(intersect_v, first_edge, .End);
            self.events.append(new_evt) catch unreachable;
            self.event_q.add(evt_idx) catch unreachable;

            // Insert start/end event from the intersect to the end of the original sweep_edge_b.
            var event1: Event = undefined;
            var event2: Event = undefined;
            if (Event.isStartEvent(intersect_idx, second_edge, self.verts.items)) {
                event1 = Event.init(intersect_v, second_edge, .Start);
                event2 = Event.init(self.verts.items[b_orig_to_vert], second_edge, .End);
                event1.end_event_idx = evt_idx + 2;
            } else {
                event1 = Event.init(intersect_v, second_edge, .End);
                event2 = Event.init(self.verts.items[b_orig_to_vert], second_edge, .Start);
                event2.end_event_idx = evt_idx + 1;
            }
            self.events.append(event1) catch unreachable;
            self.event_q.add(evt_idx + 1) catch unreachable;
            self.events.append(event2) catch unreachable;
            self.event_q.add(evt_idx + 2) catch unreachable;
        }

        if (!added_events) {
            // No events were added, revert adding intersect point.
            _ = self.verts.pop();
        }
    }
};

fn edgeToString(edge: Edge) []const u8 {
    const S = struct {
        var buf: [100]u8 = undefined;
    };
    return std.fmt.bufPrint(&S.buf, "{} ({},{}) -> {} ({},{})", .{ edge.start_idx, edge.start_pos.x, edge.start_pos.y, edge.end_idx, edge.end_pos.x, edge.end_pos.y }) catch unreachable;
}

fn compareEventIdx(events: *std.ArrayList(Event), a: u32, b: u32) std.math.Order {
    return compareEvent(events.items[a], events.items[b]);
}

/// Sort verts by y asc then x asc. Resolve same position by looking at the edge's xslope and whether it is active.
fn compareEvent(a: Event, b: Event) std.math.Order {
    if (a.vert_y < b.vert_y) {
        return .lt;
    } else if (a.vert_y > b.vert_y) {
        return .gt;
    } else {
        if (a.vert_x < b.vert_x) {
            return .lt;
        } else if (a.vert_x > b.vert_x) {
            return .gt;
        } else {
            if (a.tag == .End and b.tag == .Start) {
                return .lt;
            } else if (a.tag == .Start and b.tag == .End) {
                return .gt;
            } else if (a.tag == .End and b.tag == .End) {
                if (a.edge.x_slope > b.edge.x_slope) {
                    return .lt;
                } else if (a.edge.x_slope < b.edge.x_slope) {
                    return .gt;
                } else {
                    return .eq;
                }
            } else {
                if (a.edge.x_slope < b.edge.x_slope) {
                    return .lt;
                } else if (a.edge.x_slope > b.edge.x_slope) {
                    return .gt;
                } else {
                    return .eq;
                }
            }
        }
    }
}

/// Compare SweepEdges for insertion. Each sweep edge should be unique since the rb tree doesn't support duplicate values.
/// The slopes from the current sweep edges are used to find their x-intersect along the event's y line.
/// If compared sweep edge is a horizontal line, return gt so it's inserted after it. The horizontal edge can be assumed to intersect with the target event or it wouldn't be in the sweep edges.
fn compareSweepEdge(_: SweepEdge, b: SweepEdge, evt: Event) std.math.Order {
    if (!b.edge.is_horiz) {
        const x_intersect = b.edge.x_slope * (evt.vert_y - b.edge.start_pos[1]) + b.edge.start_pos[0];
        if (@fabs(evt.vert_x - x_intersect) < SweepEdgeApproxEpsilon) {
            // Since there is a chance of having floating point error, check with an epsilon.
            // Always return .gt so the left sweep edge can be reliably checked for a joining edge.
            return .gt;
        } else {
            if (evt.vert_x < x_intersect) {
                return .lt;
            } else if (evt.vert_x > x_intersect) {
                return .gt;
            } else {
                unreachable;
            }
        }
    } else {
        return .gt;
    }
}

fn findSweepEdgeForEndEvent(sweep_edges: *RbTree(u16, SweepEdge, Event, compareSweepEdge), e: Event) ?u16 {
    const target = Vec2{ e.vert_x, e.vert_y };
    const dummy = SweepEdge{
        .edge = undefined,
        .start_event_vert_uniq_idx = undefined,
        .vert_idx = undefined,
        .to_vert_idx = undefined,
        .end_event_vert_uniq_idx = undefined,
        .deferred_queue = undefined,
        .deferred_queue_size = undefined,
        .cur_side = undefined,
        .bad_up_cusp_uniq_idx = undefined,
        .bad_up_cusp_right_sweep_edge_id = undefined,
        .lowest_right_vert_idx = undefined,
        .lowest_right_vert_sweep_edge_id = undefined,
        .interior_is_left = undefined,
        .end_event_idx = undefined,
    };
    log("find {},{}", .{ target[0], target[1] });
    var mb_parent: ?u16 = undefined;
    var is_left: bool = undefined;
    var start_id: u16 = undefined;
    if (sweep_edges.lookupCustomLoc(dummy, target, compareSweepEdgeApprox, &mb_parent, &is_left)) |id| {
        start_id = id;
    } else {
        // It's possible that we can't find the sweep edge based on x intersect due to floating point error.
        // Start linear search at the parent.
        if (mb_parent) |parent| {
            start_id = parent;
        } else {
            return null;
        }
    }

    // Given a start index where a group of verts could have approx the same x-intersect value, find the one with the exact vert and to_vert.
    // The search ends on left/right when the x-intersect suddenly becomes greater than the epsilon.
    var se = sweep_edges.getNoCheck(start_id);
    if (se.to_vert_idx == e.vert_idx and se.vert_idx == e.to_vert_idx) {
        return start_id;
    }
    log("skip edge {} -> {}", .{ se.vert_idx, se.to_vert_idx });
    // Search left.
    var mb_cur = sweep_edges.getPrev(start_id);
    while (mb_cur) |cur| {
        se = sweep_edges.getNoCheck(cur);
        const x_intersect = getXIntersect(se.edge, target);
        if (@fabs(e.vert_x - x_intersect) > SweepEdgeApproxEpsilon) {
            break;
        } else if (se.to_vert_idx == e.vert_idx and se.vert_idx == e.to_vert_idx) {
            return cur;
        }
        mb_cur = sweep_edges.getPrev(cur);
    }
    // Search right.
    mb_cur = sweep_edges.getNext(start_id);
    while (mb_cur) |cur| {
        se = sweep_edges.getNoCheck(cur);
        const x_intersect = getXIntersect(se.edge, target);
        if (@fabs(e.vert_x - x_intersect) > SweepEdgeApproxEpsilon) {
            break;
        } else if (se.to_vert_idx == e.vert_idx and se.vert_idx == e.to_vert_idx) {
            return cur;
        }
        mb_cur = sweep_edges.getNext(cur);
    }
    return null;
}

const SweepEdgeApproxEpsilon: f32 = 1e-4;

/// Finds the first edge with x-intersect that approximates the provided target vert's x.
/// This is needed since floating point error can lead to inconsistent divide and conquer for x-intersects that are close together (eg. two edges stemming from one vertex)
/// A follow up routine to find the exact edge should be run afterwards.
fn compareSweepEdgeApprox(_: SweepEdge, b: SweepEdge, target: Vec2) std.math.Order {
    const x_intersect = getXIntersect(b.edge, target);
    // Relax the epsilon since larger floating point error can happen here. In the end it's surroundings is verified by linear search.
    if (@fabs(target[0] - x_intersect) < SweepEdgeApproxEpsilon) {
        return .eq;
    } else if (target[0] < x_intersect) {
        return .lt;
    } else {
        return .gt;
    }
}

// Assumes there is an intersect.
fn getXIntersect(edge: Edge, target: Vec2) f32 {
    if (!edge.is_horiz) {
        return edge.x_slope * (target[1] - edge.start_pos[1]) + edge.start_pos[0];
    } else {
        return target[0];
    }
}

const EventTag = enum(u1) {
    Start = 0,
    End = 1,
};

/// Polygon verts and edges are reduced to events.
/// Each event is centered on a vertex and has an outgoing or incoming edge.
/// If the edge is above the vertex, it's considered a End event.
/// If the edge is below the vertex, it's considered a Start event.
/// Events are sorted by y asc and the x asc.
/// To order events on the same vertex, the event with an active edge has priority.
/// If both events have active edges (both End events), the one that has a greater x-slope comes first. This means an active edge to the left comes first.
/// This helps end processing since the left edge still exists and contains state information about that fill region.
/// If both events have non active edges (both Start events), the one that has a lesser x-slope comes first.
const Event = struct {
    const Self = @This();

    /// The idx of the internal vertex that this event fires on.
    vert_idx: u16,

    /// Duped vert pos for compare func.
    vert_x: f32,
    vert_y: f32,

    tag: EventTag,

    edge: Edge,

    to_vert_idx: u16,

    /// If this is a start event, end_event_idx will point to the corresponding end event.
    end_event_idx: u32,

    /// Since an intersection creates new events and can not modify the priority queue,
    /// this flag is used to invalid an existing end event.
    invalidated: bool,

    fn init(vert: InternalVertex, edge: Edge, tag: EventTag) Self {
        var new = Self{
            .vert_idx = vert.idx,
            .vert_x = vert.pos[0],
            .vert_y = vert.pos[1],
            .edge = edge,
            .tag = tag,
            .to_vert_idx = undefined,
            .end_event_idx = std.math.maxInt(u32),
            .invalidated = false,
        };
        if (edge.start_idx == vert.idx) {
            new.to_vert_idx = edge.end_idx;
        } else {
            new.to_vert_idx = edge.start_idx;
        }
        return new;
    }

    fn isStartEvent(vert_idx: u16, edge: Edge, verts: []const InternalVertex) bool {
        const vert = verts[vert_idx];
        // The start and end vertex of an edge is not to be confused with the EventType.
        // It is used to determine if the edge is above or below the vertex point.
        if (edge.start_idx == vert_idx) {
            const end_v = verts[edge.end_idx];
            if (end_v.pos[1] < vert.pos[1] or (end_v.pos[1] == vert.pos[1] and end_v.pos[0] < vert.pos[0])) {
                return false;
            } else {
                return true;
            }
        } else {
            const start_v = verts[edge.start_idx];
            if (start_v.pos[1] < vert.pos[1] or (start_v.pos[1] == vert.pos[1] and start_v.pos[0] < vert.pos[0])) {
                return false;
            } else {
                return true;
            }
        }
    }
};

const Side = enum(u1) {
    Left = 0,
    Right = 1,
};

pub const SweepEdge = struct {
    const Self = @This();

    edge: Edge,
    start_event_vert_uniq_idx: u16,
    vert_idx: u16,
    to_vert_idx: u16,

    end_event_idx: u32,

    /// The End event that marks this edge for removal. This is set in the End event.
    end_event_vert_uniq_idx: u16,

    /// Points to the head vertex.
    deferred_queue: DeferredVertexNodeId,

    /// Current size of the queue.
    deferred_queue_size: u16,

    /// The current side being processed for monotone triangulation.
    cur_side: Side,

    /// Last seen bad up cusp.
    bad_up_cusp_uniq_idx: u16,
    bad_up_cusp_right_sweep_edge_id: u16,
    lowest_right_vert_idx: u16,
    lowest_right_vert_sweep_edge_id: u16,

    /// Store the winding. This would be used by the fill rule to determine if the interior is to the left or right.
    interior_is_left: bool,

    /// A sweep edge is created from a Start event.
    fn init(e: Event, verts: []const InternalVertex) Self {
        const e_vert = verts[e.vert_idx];
        return .{
            .edge = e.edge,
            .start_event_vert_uniq_idx = e_vert.out_idx,
            .vert_idx = e.vert_idx,
            .to_vert_idx = e.to_vert_idx,
            .end_event_idx = e.end_event_idx,
            .end_event_vert_uniq_idx = std.math.maxInt(u16),
            .deferred_queue = NullId,
            .deferred_queue_size = 0,
            .cur_side = .Left,
            .bad_up_cusp_uniq_idx = NullId,
            .bad_up_cusp_right_sweep_edge_id = NullId,
            .lowest_right_vert_idx = NullId,
            .lowest_right_vert_sweep_edge_id = NullId,
            .interior_is_left = false,
        };
    }

    fn enqueueDeferred(self: *Self, vert: InternalVertex, tess: *Tessellator) void {
        const node = DeferredVertexNode.init(vert);
        self.deferred_queue = tess.deferred_verts.insertBeforeHeadNoCheck(self.deferred_queue, node) catch unreachable;
        self.deferred_queue_size += 1;
    }

    fn verifySize(self: Self, tess: *Tessellator) void {
        var cur = self.deferred_queue;
        var act_size: u32 = 0;
        while (cur != NullId) {
            act_size += 1;
            cur = tess.deferred_verts.getNextNoCheck(cur);
        }
        if (self.deferred_queue_size != act_size) {
            log("expected {}, actual {}", .{ self.deferred_queue_size, act_size });
            unreachable;
        }
    }

    fn dumpQueue(self: Self, tess: *Tessellator) void {
        var buf: [200]u8 = undefined;
        var buf_stream = std.io.fixedBufferStream(&buf);
        var writer = buf_stream.writer();
        var cur_id = self.deferred_queue;
        while (cur_id != NullId) {
            const cur = tess.deferred_verts.getNoCheck(cur_id);
            std.fmt.format(writer, "{},", .{cur.vert_idx}) catch unreachable;
            const last = cur_id;
            cur_id = tess.deferred_verts.getNextNoCheck(cur_id);
            if (last == cur_id) {
                std.fmt.format(writer, "repeat pt - bad state", .{}) catch unreachable;
                break;
            }
        }
        var side_str: []const u8 = if (self.cur_side == .Right) "right" else "left";
        log("size: {}, side: {s}, idxes: {s}", .{ self.deferred_queue_size, side_str, buf[0..buf_stream.pos] });
    }
};

/// This contains a vertex that still needs to be triangulated later when it can.
/// It is linked together in a singly linked list queue and is designed to behave like the monotone triangulation queue.
/// Since the triangulator does everything in one pass for complex polygons, every monotone polygon span in the sweep edges
/// needs to keep track of their deferred vertices since the edges are short lived.
pub const DeferredVertexNode = struct {
    const Self = @This();

    vert_idx: u16,

    // Duped vars.
    vert_out_idx: u16,
    vert_x: f32,
    vert_y: f32,

    fn init(vert: InternalVertex) Self {
        return .{
            .vert_idx = vert.idx,
            .vert_out_idx = vert.out_idx,
            .vert_x = vert.pos[0],
            .vert_y = vert.pos[1],
        };
    }
};

/// Contains start/end InternalVertex.
pub const Edge = struct {
    const Self = @This();

    /// Start vertex index.
    start_idx: u16,
    /// End vertex index.
    end_idx: u16,

    /// Duped start_pos for compareSweepEdge, getXIntersect.
    start_pos: Vec2,
    end_pos: Vec2,

    /// Vector from start to end pos.
    vec: Vec2,

    /// Change of x with respect to y.
    x_slope: f32,

    /// Whether the edge is horizontal.
    /// TODO: This may not be needed anymore.
    is_horiz: bool,

    fn init(start_idx: u16, start_v: InternalVertex, end_idx: u16, end_v: InternalVertex) Self {
        var new = Self{
            .start_idx = start_idx,
            .end_idx = end_idx,
            .start_pos = start_v.pos,
            .end_pos = end_v.pos,
            .vec = end_v.pos - start_v.pos,
            .x_slope = undefined,
            .is_horiz = undefined,
        };
        if (new.vec[1] != 0) {
            new.x_slope = new.vec[0] / new.vec[1];
            new.is_horiz = false;
        } else {
            new.x_slope = std.math.f32_max;
            new.is_horiz = true;
        }
        return new;
    }
};

/// Internal verts. During triangulation, these are using for event computations so there can be duplicates points.
pub const InternalVertex = struct {
    pos: Vec2,
    /// This is the index of the vertex from the given polygon.
    idx: u16,
    /// The vertex index of the resulting buffer. Set during process event.
    out_idx: u16 = undefined,
};

/// Avoids division by zero.
/// https://stackoverflow.com/questions/563198
/// For segments: p, p + r, q, q + s
/// To find t, u for p + tr, q + us
/// t = (q − p) X s / (r X s)
/// u = (q − p) X r / (r X s)
fn computeTwoEdgeIntersect(p: Edge, q: Edge) IntersectResult {
    const t__ = trace(@src());
    defer t__.end();
    const r_s = cross(p.vec, q.vec);
    if (r_s == 0) {
        return IntersectResult.initNull();
    }
    const qmp = Vec2{ q.start_pos[0] - p.start_pos[0], q.start_pos[1] - p.start_pos[1] };
    const qmp_r = cross(qmp, p.vec);
    const u = qmp_r / r_s;
    if (u >= 0 and u <= 1) {
        // Must check intersect point is also on p.
        const qmp_s = cross(qmp, q.vec);
        const t_ = qmp_s / r_s;
        if (t_ >= 0 and t_ <= 1) {
            return .{
                .x = q.start_pos[0] + q.vec[0] * u,
                .y = q.start_pos[1] + q.vec[1] * u,
                .t = t_,
                .u = u,
                .has_intersect = true,
            };
        } else {
            return IntersectResult.initNull();
        }
    } else {
        return IntersectResult.initNull();
    }
}

const IntersectResult = struct {
    x: f32,
    y: f32,
    t: f32,
    u: f32,
    has_intersect: bool,

    fn initNull() IntersectResult {
        return .{
            .x = undefined,
            .y = undefined,
            .t = undefined,
            .u = undefined,
            .has_intersect = false,
        };
    }
};

/// Just check triangle count.
/// TODO: Verify all triangles take up the entire space.
fn testLarge(polygon: []const f32, exp_tri_count: u32) !void {
    var polygon_buf = std.ArrayList(Vec2).init(t.allocator);
    defer polygon_buf.deinit();
    var i: u32 = 0;
    while (i < polygon.len) : (i += 2) {
        polygon_buf.append(Vec2{ polygon[i], polygon[i + 1] }) catch unreachable;
    }
    var tessellator: Tessellator = undefined;
    tessellator.init(t.allocator);
    defer tessellator.deinit();
    tessellator.triangulatePolygon(polygon_buf.items);
    try t.expectEqual(tessellator.out_idxes.items.len / 3, exp_tri_count);
}

fn testSimple(polygon: []const f32, exp_verts: []const f32, exp_idxes: []const u16) !void {
    var polygon_buf = std.ArrayList(Vec2).init(t.allocator);
    defer polygon_buf.deinit();
    var i: u32 = 0;
    while (i < polygon.len) : (i += 2) {
        polygon_buf.append(Vec2{ polygon[i], polygon[i + 1] }) catch unreachable;
    }
    var tessellator: Tessellator = undefined;
    tessellator.init(t.allocator);
    defer tessellator.deinit();
    tessellator.triangulatePolygon(polygon_buf.items);

    var exp_verts_buf = std.ArrayList(Vec2).init(t.allocator);
    defer exp_verts_buf.deinit();
    i = 0;
    while (i < exp_verts.len) : (i += 2) {
        exp_verts_buf.append(Vec2{ exp_verts[i], exp_verts[i + 1] }) catch unreachable;
    }
    try t.expectEqualSlices(Vec2, tessellator.out_verts.items, exp_verts_buf.items);
    // log("{any}", .{tessellator.out_idxes.items});
    try t.expectEqualSlices(u16, tessellator.out_idxes.items, exp_idxes);
}

test "One triangle ccw." {
    try testSimple(&.{
        100, 0,
        0,   0,
        0,   100,
    }, &.{
        0,   0,
        100, 0,
        0,   100,
    }, &.{ 2, 1, 0 });
}

test "One triangle cw." {
    try testSimple(&.{
        100, 0,
        0,   100,
        0,   0,
    }, &.{
        0,   0,
        100, 0,
        0,   100,
    }, &.{ 2, 1, 0 });
}

test "Square." {
    try testSimple(&.{
        0,   0,
        100, 0,
        100, 100,
        0,   100,
    }, &.{
        0,   0,
        100, 0,
        0,   100,
        100, 100,
    }, &.{
        2, 1, 0,
        3, 1, 2,
    });
}

test "Pentagon." {
    try testSimple(&.{
        100, 0,
        200, 100,
        200, 200,
        0,   200,
        0,   100,
    }, &.{
        100, 0,
        0,   100,
        200, 100,
        0,   200,
        200, 200,
    }, &.{
        2, 0, 1,
        3, 2, 1,
        4, 2, 3,
    });
}

test "Hexagon." {
    try testSimple(&.{
        100, 0,
        200, 100,
        200, 200,
        100, 300,
        0,   200,
        0,   100,
    }, &.{
        100, 0,
        0,   100,
        200, 100,
        0,   200,
        200, 200,
        100, 300,
    }, &.{
        2, 0, 1,
        3, 2, 1,
        4, 2, 3,
        5, 4, 3,
    });
}

test "Octagon." {
    try testSimple(&.{
        100, 0,
        200, 0,
        300, 100,
        300, 200,
        200, 300,
        100, 300,
        0,   200,
        0,   100,
    }, &.{
        100, 0,
        200, 0,
        0,   100,
        300, 100,
        0,   200,
        300, 200,
        100, 300,
        200, 300,
    }, &.{
        2, 1, 0,
        3, 1, 2,
        4, 3, 2,
        5, 3, 4,
        6, 5, 4,
        7, 5, 6,
    });
}

test "Rhombus." {
    try testSimple(&.{
        100, 0,
        200, 100,
        100, 200,
        0,   100,
    }, &.{
        100, 0,
        0,   100,
        200, 100,
        100, 200,
    }, &.{
        2, 0, 1,
        3, 2, 1,
    });
}

// Tests monotone partition with bad up cusp and valid right angle.
test "Square with concave top side." {
    try testSimple(&.{
        0,   0,
        100, 100,
        200, 0,
        200, 200,
        0,   200,
    }, &.{
        0,   0,
        200, 0,
        100, 100,
        0,   200,
        200, 200,
    }, &.{
        3, 2, 0,
        4, 2, 3,
        4, 1, 2,
    });
}

// Tests monotone partition with bad down cusp and valid right angle.
test "Square with concave bottom side." {
    try testSimple(&.{
        0,   0,
        200, 0,
        200, 200,
        100, 100,
        0,   200,
    }, &.{
        0,   0,
        200, 0,
        100, 100,
        0,   200,
        200, 200,
    }, &.{
        2, 1, 0,
        3, 2, 0,
        4, 1, 2,
    });
}

// Tests monotone partition with bad up cusp and valid up cusp.
test "V shape." {
    try testSimple(&.{
        0,   0,
        100, 100,
        200, 0,
        100, 200,
    }, &.{
        0,   0,
        200, 0,
        100, 100,
        100, 200,
    }, &.{
        3, 2, 0,
        3, 1, 2,
    });
}

// Tests monotone partition with bad down cusp and valid up cusp.
test "Upside down V shape." {
    try testSimple(&.{
        100, 0,
        200, 200,
        100, 100,
        0,   200,
    }, &.{
        100, 0,
        100, 100,
        0,   200,
        200, 200,
    }, &.{
        2, 1, 0,
        3, 0, 1,
    });
}

// Tests the sweep line with alternating interior/exterior sides.
test "Clockwise spiral." {
    try testSimple(&.{
        0,   0,
        500, 0,
        500, 500,
        200, 500,
        200, 200,
        300, 200,
        300, 400,
        400, 400,
        400, 100,
        100, 100,
        100, 500,
        0,   500,
    }, &.{
        0,   0,
        500, 0,
        100, 100,
        400, 100,
        200, 200,
        300, 200,
        300, 400,
        400, 400,
        0,   500,
        100, 500,
        200, 500,
        500, 500,
    }, &.{
        2,  1, 0,
        3,  1, 2,
        6,  5, 4,
        7,  1, 3,
        8,  2, 0,
        9,  2, 8,
        10, 7, 6,
        10, 6, 4,
        11, 7, 10,
        11, 1, 7,
    });
}

// Tests the sweep line with alternating interior/exterior sides.
test "CCW spiral." {
    try testSimple(&.{
        0,   0,
        500, 0,
        500, 500,
        400, 500,
        400, 100,
        100, 100,
        100, 400,
        200, 400,
        200, 200,
        300, 200,
        300, 500,
        0,   500,
    }, &.{
        0,   0,
        500, 0,
        100, 100,
        400, 100,
        200, 200,
        300, 200,
        100, 400,
        200, 400,
        0,   500,
        300, 500,
        400, 500,
        500, 500,
    }, &.{
        2,  1, 0,
        3,  1, 2,
        6,  2, 0,
        7,  5, 4,
        8,  7, 6,
        8,  6, 0,
        9,  7, 8,
        9,  5, 7,
        10, 1, 3,
        11, 1, 10,
    });
}

test "Overlapping point." {
    try testSimple(&.{
        0,   0,
        100, 100,
        200, 0,
        200, 200,
        100, 100,
        0,   200,
    }, &.{
        0,   0,
        200, 0,
        100, 100,
        0,   200,
        200, 200,
    }, &.{
        3, 2, 0,
        4, 1, 2,
    });
}

// Different windings on split polygons.
test "Self intersecting polygon." {
    try testSimple(&.{
        0,   200,
        0,   100,
        200, 100,
        200, 0,
    }, &.{
        200, 0,
        0,   100,
        100, 100,
        200, 100,
        0,   200,
    }, &.{
        3, 0, 2,
        4, 2, 1,
    });
}

// Test evenodd rule.
test "Overlapping triangles." {
    try testSimple(&.{
        0,   100,
        200, 0,
        200, 200,
        0,   100,
        250, 75,
        250, 125,
        0,   100,
    }, &.{
        200, 0,
        250, 75,
        200, 80,
        0,   100,
        200, 120,
        250, 125,
        200, 200,
    }, &.{
        3, 2, 0,
        4, 1, 2,
        5, 1, 4,
        6, 4, 3,
    });
}

// Begin mapbox test cases.

test "bad-diagonals.json" {
    try testSimple(&.{
        440, 4152,
        440, 4208,
        296, 4192,
        368, 4192,
        400, 4200,
        400, 4176,
        368, 4192,
        296, 4192,
        264, 4200,
        288, 4160,
        296, 4192,
    }, &.{
        440, 4152,
        288, 4160,
        400, 4176,
        296, 4192,
        368, 4192,
        264, 4200,
        400, 4200,
        440, 4208,
    }, &.{
        3, 2, 0,
        4, 2, 3,
        5, 3, 1,
        6, 4, 3,
        6, 0, 2,
        7, 6, 3,
        7, 0, 6,
    });
}

// TODO: dude.json

// Case by case examples.

test "Rectangle with bottom-left wedge." {
    try testSimple(&.{
        56,  22,
        111, 22,
        111, 44,
        37,  44,
        56,  32,
    }, &.{
        56,  22,
        111, 22,
        56,  32,
        37,  44,
        111, 44,
    }, &.{
        2, 1, 0,
        3, 1, 2,
        4, 1, 3,
    });
}

test "Tiger big part." {
    try testLarge(&.{
        -129.83, 103.06, -129.83, 103.06, -128.36, 113.62, -126.60, 118.80, -126.60, 118.80, -127.33, 125.99, -125.81, 135.32, -121.40, 144.40, -121.40, 144.40, -121.18, 151.03, -120.20, 154.80, -120.20, 154.80, -115.56, 161.53, -111.40, 164.00, -111.40, 164.00, -99.95, 166.93, -88.93, 169.12, -88.93, 169.12, -82.12, 176.08, -77.01, 183.74, -74.79, 190.23, -75.00, 196.00, -75.00, 196.00, -76.74, 210.10, -79.00, 214.00, -79.00, 214.00, -73.96, 210.34, -73.22, 211.25, -77.00, 219.60, -81.40, 238.40, -81.40, 238.40, -67.64, 228.08, -66.39, 228.12, -71.40, 235.20, -81.40, 261.20, -81.40, 261.20, -67.93, 249.24, -67.39, 249.03, -69.00, 251.20, -72.20, 260.00, -72.20, 260.00, -53.39, 249.64, -48.97, 248.73, -49.31, 250.85, -59.80, 262.40, -59.80, 262.40, -52.31, 260.54, -47.40, 261.60, -47.40, 261.60, -41.92, 261.27, -41.40, 262.00, -41.40, 262.00, -49.70, 267.43, -57.61, 274.87, -62.93, 282.61, -65.80, 290.80, -65.80, 290.80, -61.30, 286.73, -59.99, 287.03, -60.60, 291.60, -60.20, 303.20, -60.20, 303.20, -58.30, 297.14, -57.37, 298.26, -56.60, 319.20, -56.60, 319.20, -48.49, 312.82, -45.76, 312.03, -45.35, 313.82, -49.00, 322.00, -49.00, 338.80, -49.00, 338.80, -40.26, 330.76, -38.63, 330.61, -40.20, 335.20, -40.20, 335.20, -36.26, 332.85, -34.22, 332.98, -33.27, 335.13, -34.20, 341.60, -34.20, 341.60, -33.94, 345.73, -33.17, 345.79, -30.60, 340.80, -30.60, 340.80, -22.95, 328.26, -20.19, 325.79, -19.29, 327.04, -20.60, 336.40, -20.60, 336.40, -20.14, 345.51, -19.15, 346.31, -16.60, 340.80, -16.60, 340.80, -15.40, 346.50, -12.14, 353.01, -7.00, 358.40, -7.00, 358.40, -6.27, 339.53, -4.46, 332.02, -2.77, 330.70, -0.27, 332.77, 4.60, 343.60, 8.60, 360.00, 8.60, 360.00, 10.64, 351.18, 11.00, 345.60, 19.00, 353.60, 19.00, 353.60, 28.79, 341.06, 31.17, 340.03, 31.00, 344.00, 31.00, 344.00, 25.45, 358.75, 25.00, 364.80, 25.00, 364.80, 43.00, 328.40, 43.00, 328.40, 43.39, 345.38, 44.82, 349.24, 46.77, 347.92, 51.80, 334.80, 51.80, 334.80, 54.49, 342.22, 55.39, 347.96, 54.60, 351.20, 54.60, 351.20, 60.76, 343.58, 61.80, 340.00, 61.80, 340.00, 64.54, 337.57, 66.77, 338.71, 69.20, 345.40, 69.20, 345.40, 71.39, 352.02, 72.60, 351.60, 72.60, 351.60, 75.37, 362.09, 76.42, 362.30, 77.80, 352.80, 77.80, 352.80, 77.75, 344.98, 75.91, 335.70, 72.20, 327.60, 72.20, 327.60, 72.12, 324.56, 70.20, 320.40, 70.20, 320.40, 75.70, 327.30, 77.91, 328.09, 78.69, 325.45, 76.60, 313.20, 76.60, 313.20, 89.00, 321.20, 89.00, 321.20, 82.70, 308.82, 81.23, 303.45, 81.82, 302.23, 84.20, 302.80, 84.20, 302.80, 83.54, 299.86, 84.53, 298.67, 87.95, 299.28, 97.00, 304.40, 97.00, 304.40, 91.03, 297.34, 90.41, 295.37, 91.64, 294.95, 98.60, 298.00, 98.60, 298.00, 101.93, 300.03, 102.23, 299.50, 99.00, 294.40, 99.00, 294.40, 94.40, 288.21, 95.27, 288.03, 106.60, 296.40, 106.60, 296.40, 116.61, 311.24, 119.00, 315.60, 119.00, 315.60, 108.86, 290.10, 104.60, 283.60, 104.60, 283.60, 108.02, 275.28, 114.09, 267.22, 121.76, 261.79, 130.82, 259.23, 141.00, 259.30, 154.20, 262.80, 154.20, 262.80, 157.75, 268.68, 160.36, 270.08, 162.73, 268.60, 165.40, 261.60, 165.40, 261.60, 170.08, 261.04, 176.25, 263.49, 182.75, 270.16, 189.40, 282.80, 189.40, 282.80, 192.36, 270.67, 192.60, 266.40, 192.60, 266.40, 198.19, 266.89, 198.60, 266.40, 198.60, 266.40, 210.19, 269.77, 213.00, 270.00, 213.00, 270.00, 217.51, 273.62, 219.47, 274.23, 220.20, 273.20, 220.20, 273.20, 225.75, 274.22, 227.51, 273.79, 227.40, 272.40, 227.40, 272.40, 234.76, 286.58, 236.60, 291.60, 239.00, 277.60, 241.00, 280.40, 241.00, 280.40, 242.01, 273.69, 241.80, 271.60, 241.80, 271.60, 242.83, 271.72, 249.79, 275.48, 257.44, 282.09, 263.14, 289.99, 266.60, 299.20, 268.60, 307.60, 268.60, 307.60, 272.87, 294.06, 273.00, 288.80, 273.00, 288.80, 277.01, 290.73, 278.60, 294.00, 278.60, 294.00, 280.13, 278.97, 279.59, 269.28, 277.80, 264.80, 277.80, 264.80, 281.47, 265.30, 283.40, 267.60, 283.40, 260.40, 283.40, 260.40, 289.30, 260.14, 290.60, 258.80, 290.60, 258.80, 293.21, 257.36, 295.38, 257.54, 297.00, 259.60, 297.00, 259.60, 293.38, 246.31, 293.06, 239.85, 294.31, 238.04, 296.82, 238.39, 303.00, 243.60, 303.00, 243.60, 306.29, 246.69, 307.45, 245.38, 306.60, 235.60, 306.60, 235.60, 302.46, 219.68, 301.73, 215.52, 303.80, 214.80, 303.80, 214.80, 303.85, 211.76, 302.60, 209.60, 302.60, 209.60, 301.93, 208.90, 303.80, 209.60, 303.80, 209.60, 305.11, 209.64, 305.81, 206.07, 303.40, 191.60, 303.40, 191.60, 304.82, 190.48, 304.47, 183.66, 297.80, 164.00, 297.80, 164.00, 298.73, 160.69, 296.60, 153.20, 296.60, 153.20, 303.95, 156.14, 307.40, 156.00, 307.40, 156.00, 307.15, 155.40, 303.80, 150.40, 303.80, 150.40, 295.80, 126.68, 293.83, 115.79, 294.65, 112.78, 296.76, 112.66, 302.60, 117.60, 302.60, 117.60, 307.07, 121.27, 309.11, 121.32, 309.97, 118.48, 308.05, 108.35, 308.05, 108.35, 300.79, 86.65, 299.72, 80.04, -129.83, 103.06,
    }, 227);
}

// Test points that are close to each other with higher precision.
test "Tiger whisker." {
    try testLarge(&.{ -109.01000, 110.07000, -109.01000, 110.07000, -108.34000, 111.97000, -108.34000, 111.97000, -123.56751, 104.91863, -141.35422, 98.68091, -153.21875, 96.99554, -161.26077, 98.11440, -166.87000, 101.68000, -166.87000, 101.68000, -163.45908, 98.55489, -156.28145, 96.28941, -145.48354, 96.58372, -130.09291, 100.65533, -109.00999, 110.07000 }, 9);
}

// Tests zig zag shape.
test "Tiger part." {
    try testLarge(&.{ -54.20, 176.40, -54.20, 176.40, -51.54, 180.01, -50.04, 187.53, -51.51, 198.82, -57.40, 214.80, -51.00, 212.40, -51.00, 212.40, -52.75, 222.12, -55.00, 226.00, -47.80, 222.80, -47.80, 222.80, -45.85, 227.62, -45.49, 232.20, -47.00, 235.60, -47.00, 235.60, -37.04, 241.57, -32.01, 246.52, -31.00, 250.00, -31.00, 250.00, -28.25, 245.06, -27.27, 239.91, -28.60, 235.60, -28.60, 235.60, -32.06, 232.22, -36.59, 228.60, -38.53, 223.88, -39.00, 214.80, -47.80, 218.00, -47.80, 218.00, -43.55, 209.33, -42.20, 202.80, -50.20, 205.20, -50.20, 205.20, -43.67, 191.40, -41.68, 182.92, -42.47, 178.91, -45.40, 177.20, -45.40, 177.20, -53.55, 176.38, -54.20, 176.40 }, 29);
}

test "Tiger whisker #2." {
    try testLarge(&.{ 50.60, 84.00, 50.60, 84.00, 36.68, 72.16, 27.20, 65.81, 22.20, 64.00, 22.20, 64.00, 7.18, 63.89, -7.84, 66.44, -19.01, 71.16, -27.00, 78.00, -27.00, 78.00, -18.60, 70.90, -7.02, 64.99, 5.17, 62.33, 18.20, 63.20, 18.20, 63.20, 4.15, 61.23, -7.70, 60.89, -15.80, 62.00, -42.20, 76.00, -45.00, 80.80, -45.00, 80.80, -42.44, 75.17, -37.28, 68.75, -31.28, 64.00, -22.60, 60.00, -22.60, 60.00, -7.92, 58.05, 3.78, 58.19, 11.00, 60.00, 11.00, 60.00, -3.17, 56.40, -14.12, 54.88, -20.60, 55.20, -20.60, 55.20, -30.04, 55.69, -41.27, 58.57, -50.82, 63.73, -57.83, 70.06, -63.80, 79.20, -63.80, 79.20, -60.27, 71.59, -53.70, 63.52, -45.00, 57.60, -45.00, 57.60, -36.54, 53.82, -24.25, 51.26, -11.00, 51.60, -11.00, 51.60, 2.14, 54.95, 8.60, 57.20, 8.60, 57.20, 11.58, 58.03, 11.26, 56.98, 4.20, 52.00, 4.20, 52.00, 0.05, 47.36, -6.79, 43.57, -15.40, 42.40, -15.40, 42.40, -36.18, 45.32, -52.83, 49.44, -63.12, 53.75, -68.60, 58.00, -68.60, 58.00, -54.94, 48.57, -44.60, 44.00, -44.60, 44.00, -23.74, 37.92, -13.80, 36.80, -13.80, 36.80, 8.76, 36.15, 18.60, 33.80, 18.60, 33.80, 12.30, 37.54, 10.11, 40.15, 10.60, 42.00, 10.60, 42.00, 18.76, 51.11, 20.60, 54.00, 20.60, 54.00, 28.20, 61.89, 48.40, 81.70, 50.60, 84.00 }, 61);
}

test "Tiger big part #2." {
    try testLarge(&.{ 143.80, 259.60, 143.80, 259.60, 156.61, 257.34, 165.99, 254.14, 171.00, 250.80, 175.40, 254.40, 193.00, 216.00, 196.60, 221.20, 196.60, 221.20, 204.92, 211.13, 209.33, 203.27, 210.20, 198.40, 210.20, 198.40, 210.92, 196.01, 214.22, 196.97, 223.00, 204.40, 223.00, 204.40, 223.74, 198.82, 225.70, 197.45, 229.40, 199.60, 229.40, 199.60, 229.48, 191.67, 231.36, 189.69, 235.40, 192.00, 235.40, 192.00, 233.02, 182.21, 233.43, 178.04, 234.91, 177.19, 238.62, 178.91, 247.40, 187.60, 247.40, 187.60, 250.17, 190.36, 248.60, 187.20, 248.60, 187.20, 238.82, 166.34, 235.69, 155.55, 236.21, 151.81, 238.37, 150.90, 244.20, 153.60, 244.20, 153.60, 245.37, 133.23, 245.00, 126.40, 245.00, 126.40, 242.11, 109.37, 239.39, 98.81, 237.00, 94.40, 237.00, 94.40, 235.10, 91.16, 235.84, 89.80, 238.54, 89.93, 243.00, 92.80, 243.00, 92.80, 238.96, 81.92, 238.77, 78.05, 240.20, 77.49, 245.00, 80.80, 245.00, 80.80, 240.58, 67.71, 237.00, 62.80, 237.00, 62.80, 236.04, 56.18, 237.21, 53.39, 240.05, 52.95, 246.60, 56.40, 246.60, 56.40, 241.98, 45.41, 239.00, 40.80, 239.00, 40.80, 232.68, 22.48, 232.55, 17.75, 234.60, 18.00, 239.00, 21.60, 239.00, 21.60, 235.94, 13.32, 236.27, 11.21, 238.60, 12.00, 238.60, 12.00, 244.87, 15.98, 245.00, 16.00, 245.00, 16.00, 236.54, 0.65, 235.41, -4.10, 236.94, -4.65, 244.20, 0.40, 244.20, 0.40, 232.60, -20.40, 232.60, -20.40, 224.56, -30.47, 222.78, -34.51, 223.63, -35.63, 228.20, -34.40, 233.00, -32.80, 233.00, -32.80, 223.84, -40.87, 216.20, -44.40, 216.20, -44.40, 213.35, -45.94, 214.21, -47.98, 219.17, -50.41, 225.00, -50.40, 225.00, -50.40, 247.00, -40.80, 247.00, -40.80, 259.33, -24.93, 263.80, -21.60, 263.80, -21.60, 251.96, -24.82, 248.79, -24.16, 249.80, -21.20, 249.80, -21.20, 257.74, -11.96, 258.98, -8.44, 257.00, -7.60, 257.00, -7.60, 254.67, -3.13, 253.96, 2.58, 255.80, 8.40, 255.80, 8.40, 248.73, 2.56, 246.65, 2.15, 246.70, 4.49, 252.20, 15.60, 259.00, 32.00, 259.00, 32.00, 247.61, 21.93, 243.68, 20.11, 242.85, 21.48, 245.80, 29.20, 245.80, 29.20, 261.57, 49.78, 265.00, 53.20, 265.00, 53.20, 267.03, 55.03, 271.40, 62.40, 267.00, 60.40, 272.20, 69.20, 272.20, 69.20, 266.48, 64.35, 265.25, 64.72, 267.00, 70.40, 272.60, 84.80, 272.60, 84.80, 264.54, 77.74, 261.68, 77.09, 261.24, 79.97, 265.80, 92.40, 265.80, 92.40, 259.71, 91.77, 256.50, 93.34, 255.61, 96.92, 258.20, 104.40, 258.20, 104.40, 257.00, 125.60, 257.00, 125.60, 257.37, 146.74, 256.16, 160.73, 254.20, 167.20, 254.20, 167.20, 253.12, 172.65, 255.06, 182.19, 262.20, 198.40, 262.20, 198.40, 264.65, 206.19, 263.74, 207.59, 259.00, 204.00, 259.00, 204.00, 253.94, 199.29, 253.84, 200.28, 256.60, 209.20, 256.60, 209.20, 262.81, 231.18, 263.80, 239.20, 263.80, 239.20, 262.65, 239.33, 259.40, 236.80, 259.40, 236.80, 251.57, 226.52, 247.90, 223.71, 246.46, 224.22, 246.20, 228.40, 246.20, 228.40, 241.80, 245.20, 241.80, 245.20, 239.77, 250.25, 239.04, 250.56, 238.60, 247.20, 238.60, 247.20, 235.84, 237.79, 234.13, 236.00, 232.60, 238.00, 232.60, 238.00, 227.70, 248.46, 223.40, 254.00, 223.40, 254.00, 221.77, 253.32, 217.15, 243.71, 215.18, 241.23, 214.20, 244.00, 214.20, 244.00, 208.81, 240.31, 204.14, 239.64, 200.46, 241.80, 197.40, 248.00, 185.80, 264.40, 185.80, 264.40, 184.89, 256.37, 184.20, 258.00, 184.20, 258.00, 164.60, 260.78, 150.89, 261.06, 143.80, 259.60 }, 157);
}

pub const DebugTriangulateStepResult = struct {
    has_result: bool,
    sweep_edges: []const SweepEdge,
    event: Event,
    out_verts: []const Vec2,
    out_idxes: []const u16,
    verts: []const InternalVertex,
    deferred_verts: []const CompactSinglyLinkedListBuffer(DeferredVertexNodeId, DeferredVertexNode).Node,

    pub fn deinit(self: @This(), alloc: std.mem.Allocator) void {
        alloc.free(self.sweep_edges);
        alloc.free(self.out_verts);
        alloc.free(self.out_idxes);
        alloc.free(self.verts);
        alloc.free(self.deferred_verts);
    }
};

// test "Simple breaking shape" {
//     var polygon_buf = std.ArrayList(Vec2).init(t.allocator);
//     defer polygon_buf.deinit();
//     try polygon_buf.appendSlice(&[_]Vec2{
//         Vec2{ 0, 0 },
//         Vec2{ 10, 0 },
//         Vec2{ 10, 10 },
//         Vec2{ 0, 10 },

//         Vec2{ 0, 0 },
//         Vec2{ 0, 0 },
//         Vec2{ 2, 2 },
//         Vec2{ 8, 2 },
//         Vec2{ 8, 8 },
//         Vec2{ 2, 8 },
//     });

//     var tessellator: Tessellator = undefined;
//     tessellator.init(t.allocator);
//     defer tessellator.deinit();
//     tessellator.triangulatePolygons(&.{ polygon_buf.items[0..5], polygon_buf.items[5..] });
//     // tessellator.triangulatePolygons(&.{polygon_buf.items[0..4]});
// }
