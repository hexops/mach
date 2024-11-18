const std = @import("std");
const testing = std.testing;

const Queue = @import("mpsc.zig").Queue;
const Pool = @import("mpsc.zig").Pool;

/// Node in the graph, represents an object that can have parent/child relations
const Node = struct {
    id: u64,
    next: ?*Node = null, // Used by Pool, otherwise stores next_sibling
    parent: ?*Node = null,
    first_child: ?*Node = null,

    /// Returns true if this node has the given node as a child
    fn hasChild(n: *Node, child_id: u64) bool {
        var current = n.first_child;
        while (current) |child| : (current = child.next) {
            if (child.id == child_id) return true;
        }
        return false;
    }

    /// Adds a child to this node's children list
    fn addChild(n: *Node, child: *Node) void {
        var last_child: ?*Node = null;
        var current = n.first_child;
        while (current) |curr| : (current = curr.next) {
            last_child = curr;
        }

        child.parent = n;
        if (last_child) |last| last.next = child else n.first_child = child;
    }

    /// Removes a child from this node's children list
    fn removeChild(n: *Node, child_id: u64) void {
        if (n.first_child) |first| {
            if (first.id == child_id) {
                n.first_child = first.next;
                if (first.parent == n) {
                    first.parent = null;
                    first.next = null; // Clear the next pointer
                }
                return;
            }

            var prev = first;
            var current = first.next;
            while (current) |curr| {
                if (curr.id == child_id) {
                    prev.next = curr.next;
                    if (curr.parent == n) {
                        curr.parent = null;
                        curr.next = null; // Clear the next pointer
                    }
                    break;
                }
                prev = curr;
                current = curr.next;
            }
        }
    }
};

/// Error set for graph operations
pub const Error = error{
    OutOfMemory,
};

/// Read/write/mutate operations to perform on the graph.
const Op = union(enum) {
    /// Add a child to a parent. no-op if already a child.
    add_child: struct { parent_id: u64, child_id: u64 },

    /// Remove a child from a parent. no-op if not a child.
    remove_child: struct { parent_id: u64, child_id: u64 },

    /// Set the parent of a child node. no-op if already has this parent.
    set_parent: struct { child_id: u64, parent_id: u64 },

    /// Remove the parent of a child node. no-op if no parent.
    remove_parent: struct { child_id: u64 },

    /// Query the children of the given node
    get_children: struct {
        node_id: u64,
        result: *std.ArrayListUnmanaged(u64),
        err: *?Error,
        done: *std.atomic.Value(bool),
    },

    /// Query the parent of a node
    get_parent: struct {
        node_id: u64,
        result: *?u64,
        done: *std.atomic.Value(bool),
    },
};

/// A graph of objects with parent/child/etc relations.
///
/// Reads/writes/mutations to the graph can be performed by any thread in parallel. This is possible
/// without a global mutex locking the entire graph because we represent all interactions with the
/// graph as /operations/ enqueued to a lock-free Multi Producer, Single Consumer (MPSC) FIFO queue.
///
/// When an operation is desired (adding a parent to a child, querying the children or parent of a
/// node, etc.) it is enqueued. Then, if the queue contains entries, that thread becomes the
/// consumer of the MPSC queue temporarily and processes all pending operations in the queue.
///
/// The graph uses lock-free pools to manage all nodes internally, eliminating runtime allocations
/// during operation processing.
pub const Graph = struct {
    /// Queue of read/write/mutation operations to the graph.
    queue: Queue(Op),

    /// Pool of nodes for allocation and recycling.
    nodes: Pool(Node),

    /// Maps node IDs to their struct, protected by a read-write lock
    id_to_node: struct {
        map: std.AutoHashMapUnmanaged(u64, *Node) = .{},
        lock: std.Thread.RwLock = .{},
    } = .{},

    /// Pool of ArrayLists for query results
    result_lists: struct {
        available: std.ArrayListUnmanaged(*std.ArrayListUnmanaged(u64)) = .{},
        lock: std.Thread.RwLock = .{},
    } = .{},

    preallocate_result_list_size: u32,

    /// Initialize the graph with the given pre-allocated space for nodes and operations.
    pub fn init(
        graph: *Graph,
        allocator: std.mem.Allocator,
        preallocate: struct {
            queue_size: u32,
            nodes_size: u32,
            num_result_lists: u32,
            result_list_size: u32,
        },
    ) !void {
        graph.* = .{
            .queue = undefined,
            .nodes = undefined,
            .preallocate_result_list_size = preallocate.result_list_size,
        };

        try graph.queue.init(allocator, preallocate.queue_size);
        errdefer graph.queue.deinit(allocator);

        try graph.id_to_node.map.ensureTotalCapacity(allocator, preallocate.nodes_size);
        errdefer graph.id_to_node.map.deinit(allocator);

        graph.nodes = try Pool(Node).init(allocator, preallocate.nodes_size);
        errdefer graph.nodes.deinit(allocator);

        // Pre-allocate result lists
        try graph.result_lists.available.ensureTotalCapacity(allocator, preallocate.num_result_lists);
        errdefer {
            for (graph.result_lists.available.items) |list| {
                list.deinit(allocator);
                allocator.destroy(list);
            }
            graph.result_lists.available.deinit(allocator);
        }

        for (0..preallocate.num_result_lists) |_| {
            var list = try allocator.create(std.ArrayListUnmanaged(u64));
            errdefer allocator.destroy(list);
            list.* = .{};
            try list.ensureTotalCapacity(allocator, preallocate.result_list_size);
            try graph.result_lists.available.append(allocator, list);
        }
    }

    pub fn deinit(graph: *Graph, allocator: std.mem.Allocator) void {
        for (graph.result_lists.available.items) |list| {
            list.deinit(allocator);
            allocator.destroy(list);
        }
        graph.result_lists.available.deinit(allocator);
        graph.id_to_node.map.deinit(allocator);
        graph.nodes.deinit(allocator);
        graph.queue.deinit(allocator);
    }

    /// Get an existing Node for the given ID, or null if not found
    fn getNode(graph: *Graph, id: u64) ?*Node {
        graph.id_to_node.lock.lockShared();
        defer graph.id_to_node.lock.unlockShared();
        return graph.id_to_node.map.get(id);
    }

    /// Tries to take all queued operations to the graph and, if successful, processes them.
    ///
    /// A different thread which calls processQueue() may beat us to acquiring all of the queued
    /// operations, in which case this function may return before they are processed.
    fn processQueue(graph: *Graph, allocator: std.mem.Allocator) void {
        if (graph.queue.takeAll()) |nodes| {
            defer graph.queue.releaseAll(nodes);

            // Process the entire chain of nodes
            var current: ?*Queue(Op).Node = nodes;
            while (current) |node| {
                graph.processOp(allocator, node.value);
                current = node.next;
            }
        }
    }

    /// Checks if a node has any relationships and if not, removes it from the graph
    inline fn cleanupIsolatedNode(graph: *Graph, node: *Node) void {
        if (node.parent != null or node.first_child != null) return;
        graph.id_to_node.lock.lock();
        defer graph.id_to_node.lock.unlock();
        _ = graph.id_to_node.map.remove(node.id);
        graph.nodes.release(node);
    }

    /// Process a single operation to the graph.
    inline fn processOp(graph: *Graph, allocator: std.mem.Allocator, op: Op) void {
        switch (op) {
            .add_child => |data| {
                const parent = graph.getNode(data.parent_id) orelse return;
                const new_child = graph.getNode(data.child_id) orelse return;

                if (!parent.hasChild(new_child.id)) parent.addChild(new_child);
            },

            .remove_child => |data| {
                const parent = graph.getNode(data.parent_id) orelse return;
                const child = graph.getNode(data.child_id) orelse return;
                parent.removeChild(data.child_id);
                graph.cleanupIsolatedNode(parent);
                graph.cleanupIsolatedNode(child);
            },

            .set_parent => |data| {
                const child = graph.getNode(data.child_id) orelse return;
                const new_parent = graph.getNode(data.parent_id) orelse return;

                if (child.parent) |old_parent| {
                    if (old_parent == new_parent) return;
                    old_parent.removeChild(child.id);
                    graph.cleanupIsolatedNode(old_parent);
                }
                new_parent.addChild(child);
            },

            .remove_parent => |data| {
                const child = graph.getNode(data.child_id) orelse return;
                if (child.parent) |parent| {
                    parent.removeChild(child.id);
                    graph.cleanupIsolatedNode(parent);
                    graph.cleanupIsolatedNode(child);
                }
            },

            .get_children => |query| {
                const node = graph.getNode(query.node_id) orelse {
                    // Instead of just storing done, we return an empty result
                    query.done.store(true, .release);
                    return;
                };

                var current = node.first_child;
                while (current) |child| : (current = child.next) {
                    query.result.append(allocator, child.id) catch |err| {
                        query.err.* = err;
                        break;
                    };
                }
                query.done.store(true, .release);
            },

            .get_parent => |query| {
                const node = graph.getNode(query.node_id) orelse {
                    query.result.* = null;
                    query.done.store(true, .release);
                    return;
                };
                query.result.* = if (node.parent) |parent| parent.id else null;
                query.done.store(true, .release);
            },
        }
    }

    /// preallocateNodes2 ensures graph.id_to_node contains an entry for the two given IDs.
    fn preallocateNodes2(graph: *Graph, allocator: std.mem.Allocator, id1: u64, id2: u64) !void {
        graph.id_to_node.lock.lock();
        defer graph.id_to_node.lock.unlock();

        // Preallocate first node
        const result1 = try graph.id_to_node.map.getOrPut(allocator, id1);
        if (!result1.found_existing) {
            const node = try graph.nodes.acquire(allocator);
            node.* = .{ .id = id1 };
            result1.value_ptr.* = node;
        }

        // Preallocate second node
        const result2 = try graph.id_to_node.map.getOrPut(allocator, id2);
        if (!result2.found_existing) {
            const node = try graph.nodes.acquire(allocator);
            node.* = .{ .id = id2 };
            result2.value_ptr.* = node;
        }
    }

    pub fn addChild(graph: *Graph, allocator: std.mem.Allocator, parent_id: u64, child_id: u64) Error!void {
        try graph.preallocateNodes2(allocator, parent_id, child_id);

        try graph.queue.push(allocator, .{ .add_child = .{
            .parent_id = parent_id,
            .child_id = child_id,
        } });
        graph.processQueue(allocator);
    }

    pub fn removeChild(graph: *Graph, allocator: std.mem.Allocator, parent_id: u64, child_id: u64) Error!void {
        try graph.preallocateNodes2(allocator, parent_id, child_id);
        try graph.queue.push(allocator, .{ .remove_child = .{
            .parent_id = parent_id,
            .child_id = child_id,
        } });
        graph.processQueue(allocator);
    }

    pub fn setParent(graph: *Graph, allocator: std.mem.Allocator, child_id: u64, parent_id: u64) Error!void {
        try graph.preallocateNodes2(allocator, child_id, parent_id);

        try graph.queue.push(allocator, .{ .set_parent = .{
            .child_id = child_id,
            .parent_id = parent_id,
        } });
        graph.processQueue(allocator);
    }

    pub fn removeParent(graph: *Graph, allocator: std.mem.Allocator, child_id: u64) Error!void {
        try graph.queue.push(allocator, .{ .remove_parent = .{
            .child_id = child_id,
        } });
        graph.processQueue(allocator);
    }

    const Results = struct {
        // The actual result items. Read-only.
        items: []const u64,

        // Internal / private fields.
        internal_list: *std.ArrayListUnmanaged(u64),
        internal_graph: *Graph,

        // Deinit returns the allocation back to the Graph memory pool for reuse in the future.
        pub fn deinit(r: Results) void {
            r.internal_graph.releaseResultList(r.internal_list);
        }
    };

    pub fn getChildren(graph: *Graph, allocator: std.mem.Allocator, id: u64) Error!Results {
        const results = try graph.acquireResultList(allocator, graph.preallocate_result_list_size);
        errdefer graph.releaseResultList(results);

        var done = std.atomic.Value(bool).init(false);
        var err: ?Error = null;

        try graph.queue.push(allocator, .{ .get_children = .{
            .node_id = id,
            .result = results,
            .err = &err,
            .done = &done,
        } });

        while (!done.load(.acquire)) {
            graph.processQueue(allocator);
            std.Thread.yield() catch {};
        }

        if (err) |e| return e;
        return Results{
            .items = results.items,
            .internal_list = results,
            .internal_graph = graph,
        };
    }

    fn acquireResultList(graph: *Graph, allocator: std.mem.Allocator, min_capacity: usize) !*std.ArrayListUnmanaged(u64) {
        // Try to get an existing list first
        graph.result_lists.lock.lock();
        const list = graph.result_lists.available.popOrNull();
        graph.result_lists.lock.unlock();

        if (list) |l| {
            errdefer {
                graph.result_lists.lock.lock();
                defer graph.result_lists.lock.unlock();
                graph.result_lists.available.appendAssumeCapacity(l);
            }
            try l.ensureTotalCapacity(allocator, min_capacity);
            return l;
        }

        // Create new result list if needed
        var new_list = try allocator.create(std.ArrayListUnmanaged(u64));
        errdefer allocator.destroy(new_list);
        new_list.* = .{};
        try new_list.ensureTotalCapacity(allocator, graph.preallocate_result_list_size);
        return new_list;
    }

    fn releaseResultList(graph: *Graph, list: *std.ArrayListUnmanaged(u64)) void {
        list.clearRetainingCapacity();

        graph.result_lists.lock.lock();
        defer graph.result_lists.lock.unlock();
        graph.result_lists.available.appendAssumeCapacity(list);
    }

    pub fn getParent(graph: *Graph, allocator: std.mem.Allocator, id: u64) Error!?u64 {
        var result: ?u64 = null;
        var done = std.atomic.Value(bool).init(false);

        try graph.queue.push(allocator, .{ .get_parent = .{
            .node_id = id,
            .result = &result,
            .done = &done,
        } });

        while (!done.load(.acquire)) {
            graph.processQueue(allocator);
            std.Thread.yield() catch {};
        }

        return result;
    }
};

test "basic child addition and querying" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{ .queue_size = 32, .nodes_size = 32, .num_result_lists = 8, .result_list_size = 8 });
    defer graph.deinit(allocator);

    try graph.addChild(allocator, 1, 2);

    const results = try graph.getChildren(allocator, 1);
    defer results.deinit();
    try testing.expectEqual(results.items.len, 1);
    try testing.expectEqual(results.items[0], 2);
}

test "basic parent querying" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{ .queue_size = 32, .nodes_size = 32, .num_result_lists = 8, .result_list_size = 8 });
    defer graph.deinit(allocator);

    try graph.addChild(allocator, 1, 2);
    const parent = try graph.getParent(allocator, 2);
    try testing.expectEqual(parent.?, 1);
}

test "child removal" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{ .queue_size = 32, .nodes_size = 32, .num_result_lists = 8, .result_list_size = 8 });
    defer graph.deinit(allocator);

    try graph.addChild(allocator, 1, 2);
    try graph.removeChild(allocator, 1, 2);

    const results = try graph.getChildren(allocator, 1);
    defer results.deinit();
    try testing.expectEqual(results.items.len, 0);
}

test "parent setting" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{ .queue_size = 32, .nodes_size = 32, .num_result_lists = 8, .result_list_size = 8 });
    defer graph.deinit(allocator);

    try graph.addChild(allocator, 1, 2);
    try graph.setParent(allocator, 2, 3); // Move child 2 from parent 1 to parent 3

    const parent = try graph.getParent(allocator, 2);
    try testing.expectEqual(parent.?, 3);
}

test "parent removal" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{ .queue_size = 32, .nodes_size = 32, .num_result_lists = 8, .result_list_size = 8 });
    defer graph.deinit(allocator);

    try graph.addChild(allocator, 1, 2);
    try graph.removeParent(allocator, 2);

    const parent = try graph.getParent(allocator, 2);
    try testing.expectEqual(parent, null);
}

test "graph - idempotent child addition" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{
        .queue_size = 256,
        .nodes_size = 64,
        .num_result_lists = 32,
        .result_list_size = 32,
    });
    defer graph.deinit(allocator);

    try graph.addChild(allocator, 1, 2);
    try graph.addChild(allocator, 1, 2); // Add same child twice

    const results = try graph.getChildren(allocator, 1);
    defer results.deinit();
    try testing.expectEqual(results.items.len, 1);
}

test "graph - deep hierarchy and chain operations" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{
        .queue_size = 256,
        .nodes_size = 64,
        .num_result_lists = 32,
        .result_list_size = 32,
    });
    defer graph.deinit(allocator);

    try graph.addChild(allocator, 1, 2);
    try graph.addChild(allocator, 2, 3);
    try graph.addChild(allocator, 3, 4);
    try graph.addChild(allocator, 4, 5);

    // Verify chain
    try testing.expectEqual((try graph.getParent(allocator, 5)).?, 4);
    try testing.expectEqual((try graph.getParent(allocator, 4)).?, 3);
    try testing.expectEqual((try graph.getParent(allocator, 3)).?, 2);
    try testing.expectEqual((try graph.getParent(allocator, 2)).?, 1);

    // Test reparenting middle of chain
    try graph.setParent(allocator, 3, 1); // Move 3 to be under 1 directly

    // Verify chain was broken correctly
    try testing.expectEqual((try graph.getParent(allocator, 3)).?, 1);
    const results = try graph.getChildren(allocator, 2);
    defer results.deinit();
    try testing.expectEqual(results.items.len, 0);
}

test "graph - cleanup of isolated nodes" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{
        .queue_size = 256,
        .nodes_size = 64,
        .num_result_lists = 32,
        .result_list_size = 32,
    });
    defer graph.deinit(allocator);

    // First verify the initial state
    try graph.addChild(allocator, 1, 2);
    try graph.addChild(allocator, 2, 3);

    // Verify initial setup
    {
        const results1 = try graph.getChildren(allocator, 1);
        defer results1.deinit();
        try testing.expectEqual(results1.items.len, 1);
        try testing.expectEqual(results1.items[0], 2);

        const results2 = try graph.getChildren(allocator, 2);
        defer results2.deinit();
        try testing.expectEqual(results2.items.len, 1);
        try testing.expectEqual(results2.items[0], 3);
    }

    // Remove the parent-child relationship
    try graph.removeChild(allocator, 1, 2);

    // Node 2 should still exist and have node 3 as its child
    const node2_children = try graph.getChildren(allocator, 2);
    defer node2_children.deinit();
    try testing.expectEqual(node2_children.items.len, 1);
    try testing.expectEqual(node2_children.items[0], 3);

    // But node 2 should no longer have a parent
    try testing.expectEqual(try graph.getParent(allocator, 2), null);

    // Node 3 should still have node 2 as its parent
    try testing.expectEqual((try graph.getParent(allocator, 3)).?, 2);
}

test "graph - edge cases with non-existent nodes" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{
        .queue_size = 256,
        .nodes_size = 64,
        .num_result_lists = 32,
        .result_list_size = 32,
    });
    defer graph.deinit(allocator);

    // Test querying non-existent nodes
    const results = try graph.getChildren(allocator, 99999);
    defer results.deinit();
    try testing.expectEqual(results.items.len, 0);
    try testing.expectEqual(try graph.getParent(allocator, 99999), null);

    // These should not crash
    try graph.removeChild(allocator, 99999, 1);
    try graph.removeChild(allocator, 1, 99999);
    try graph.removeParent(allocator, 99999);

    // Add child to non-existent parent (should create both nodes)
    try graph.addChild(allocator, 100, 101);
    const results2 = (try graph.getChildren(allocator, 100));
    defer results2.deinit();
    try testing.expectEqual(results2.items.len, 1);
    try testing.expectEqual(results2.items[0], 101);
}

test "graph - multiple operations consistency" {
    const allocator = testing.allocator;
    var graph: Graph = undefined;
    try graph.init(allocator, .{
        .queue_size = 256,
        .nodes_size = 64,
        .num_result_lists = 32,
        .result_list_size = 32,
    });
    defer graph.deinit(allocator);

    try graph.addChild(allocator, 1, 2);

    try graph.addChild(allocator, 1, 3);
    try graph.addChild(allocator, 2, 4);
    try graph.setParent(allocator, 3, 2); // Move 3 under 2
    try graph.removeParent(allocator, 4); // Remove 4's parent

    const results = try graph.getChildren(allocator, 2);
    defer results.deinit();
    try testing.expectEqual(results.items.len, 1);
    try testing.expectEqual(results.items[0], 3);

    try testing.expectEqual(try graph.getParent(allocator, 4), null);
}
