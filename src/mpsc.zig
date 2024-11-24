//! MPSC (Multi Producer, Single Consumer) lock-free FIFO queue with atomic batch-take support
//!
//! The queue offers two ways to consume items:
//! 1. As a traditional MPSC queue using pop() - only one consumer thread may call pop()
//! 2. As a multi-consumer queue using takeAll() - multiple threads may compete to take all items
//!
//! Internally, the queue maintains a lock-free atomic pool of batch-allocated nodes for reuse.
//! Nodes are acquired and owned exclusively by individual threads, then given to the queue and
//! released back to the pool when no longer needed. This ensures that once the queue grows to fit
//! its maximal size, it has no continual allocations in the future.
//!
//! The queue is composed of a linked list of nodes pointing to eachother, and uses atomic pointer
//! operations to ensure:
//!
//! 1. FIFO ordering is maintained
//! 2. Multiple threads can always push() items in parallel
//! 3. No locks/mutexes are needed
//! 4. Multiple consumer threads can safely compete to takeAll() (only one succeeds), or a single
//!    consumer thread may pop().
//!
//! Note: takeAll() is parallel-safe, but pop() is never parallel-safe with itself or takeAll().
const std = @import("std");

/// Lock-free atomic pool of nodes for memory allocation
pub fn Pool(comptime Node: type) type {
    return struct {
        /// Head of the pool's free list. Nodes in the pool are linked together through their
        /// 'next' pointers, forming a list of available nodes. New nodes are pushed and popped
        /// from this head pointer atomically.
        head: ?*Node = null,

        // Tracks chunks of allocated nodes, used for freeing them at deinit() time.
        cleanup: std.ArrayListUnmanaged([*]Node) = .{},

        // How many nodes to allocate at once for each chunk in the pool.
        // Must not be modified past init()
        chunk_size: usize,

        /// Initialize the pool with a pre-allocated chunk of the given size
        pub fn init(allocator: std.mem.Allocator, chunk_size: usize) !@This() {
            std.debug.assert(chunk_size >= 2); // Need at least 2 for the linking strategy

            var pool = @This(){ .chunk_size = chunk_size };
            errdefer pool.cleanup.deinit(allocator);

            // Allocate initial chunk of nodes
            const new_nodes = try allocator.alloc(Node, chunk_size);
            errdefer allocator.free(new_nodes);
            try pool.cleanup.append(allocator, @ptrCast(new_nodes.ptr));

            // Link all nodes together
            var i: usize = 0;
            while (i < chunk_size - 1) : (i += 1) new_nodes[i].next = &new_nodes[i + 1];
            new_nodes[chunk_size - 1].next = null;
            pool.head = &new_nodes[0];

            return pool;
        }

        /// Atomically acquire a node from the pool, allocating a new chunk_size amount of nodes to
        /// add to the pool if needed.
        pub fn acquire(pool: *@This(), allocator: std.mem.Allocator) !*Node {
            // Try to get a node from the pool using atomic operations to ensure thread safety.
            // We keep trying until we either successfully acquire a node or find the pool is empty.
            while (true) {
                // Atomically load the current head of the pool
                const head = @atomicLoad(?*Node, &pool.head, .acquire);
                if (head) |head_node| {
                    // We'll take the head node for ourselves, so we try to atomically set
                    // pool.head = pool.head.next; if this operation fails then another thread beat
                    // us to it and we just retry.
                    if (@cmpxchgStrong(?*Node, &pool.head, head, head_node.next, .acq_rel, .acquire)) |_| continue;

                    // Successfully acquired, clear its next pointer and return it
                    head_node.next = null;
                    return head_node;
                }
                break; // Pool is empty
            }

            // Pool is empty, allocate new chunk of nodes, and track the pointer for later cleanup
            const new_nodes = try allocator.alloc(Node, pool.chunk_size);
            errdefer allocator.free(new_nodes);
            try pool.cleanup.append(allocator, @ptrCast(new_nodes.ptr));

            // Link all our new nodes (except the first one acquired by the caller) into a chain
            // with eachother.
            var i: usize = 2;
            while (i < pool.chunk_size) : (i += 1) new_nodes[i - 1].next = &new_nodes[i];

            // Atomically add our new chain to the pool, effectively setting:
            //
            // new_nodes[last_index] = pool.head;
            // pool.head = new_nodes[1];
            //
            while (true) {
                const head = @atomicLoad(?*Node, &pool.head, .acquire);
                new_nodes[pool.chunk_size - 1].next = head;

                // Atomically set pool.head = new_nodes[1], iff the head hasn't changed, otherwise we retry
                if (@cmpxchgStrong(?*Node, &pool.head, head, &new_nodes[1], .acq_rel, .acquire)) |_| continue;
                break;
            }
            new_nodes[0].next = null;
            return &new_nodes[0];
        }

        /// Atomically release a node back into the pool. This will never fail as it simply pushes
        /// the node onto the front of the pool's free list.
        pub fn release(pool: *@This(), node: *Node) void {
            // Effectively we'll atomically set:
            //
            // node.next = pool.head;
            // pool.head = node
            //
            while (true) {
                const head = @atomicLoad(?*Node, &pool.head, .acquire);
                node.next = head;

                // Try to atomically make our node the new head
                // If this fails, another thread modified the head before us, so retry
                if (@cmpxchgStrong(?*Node, &pool.head, head, node, .acq_rel, .acquire)) |_| continue;

                break;
            }
        }

        /// Returns stats about the number of nodes in the pool, and number of chunk allocations.
        pub fn stats(pool: *@This()) struct { nodes: usize, chunks: usize } {
            var count: usize = 0;
            var current = @atomicLoad(?*Node, &pool.head, .acquire);
            while (current) |curr| {
                count += 1;
                current = curr.next;
            }
            return .{
                .nodes = count,
                .chunks = pool.cleanup.items.len,
            };
        }

        /// Deinit all memory held by the pool
        pub fn deinit(pool: *@This(), allocator: std.mem.Allocator) void {
            for (pool.cleanup.items) |chunk| {
                const slice = @as([*]Node, chunk)[0..pool.chunk_size];
                allocator.free(slice);
            }
            pool.cleanup.deinit(allocator);
        }
    };
}

/// Multi Producer, Single Consumer lock-free FIFO queue
pub fn Queue(comptime Value: type) type {
    return struct {
        /// Head of queue to be pushed onto by producers
        /// order: A -> B -> C -> D
        head: *Node = undefined,

        /// Tail of queue; a cursor that points to the current node to be dequeued and maintained by
        /// the single consumer
        /// order: D -> C -> B -> A
        tail: *Node = undefined,

        /// Empty node / sentinel value for when the queue is empty
        empty: Node,

        // Memory pool for node management
        pool: Pool(Node),

        pub const Node = struct {
            next: ?*@This() = null,
            value: Value,
        };

        /// Initialize the queue with space preallocated for the given number of elements.
        ///
        /// If the queue runs out of space and needs to allocate, another chunk of elements of the
        /// given size will be allocated.
        pub fn init(q: *@This(), allocator: std.mem.Allocator, size: usize) !void {
            q.empty = Node{ .next = null, .value = undefined };
            q.head = &q.empty;
            q.tail = &q.empty;
            q.pool = try Pool(Node).init(allocator, size);
        }

        /// Push node to head of queue.
        pub fn push(q: *@This(), allocator: std.mem.Allocator, value: Value) !void {
            const node = try q.pool.acquire(allocator);
            node.value = value;
            q.pushRaw(node);
        }

        fn pushRaw(q: *@This(), node: *Node) void {
            // node.next should already be null, but if this is an empty node push it may not be.
            node.next = null;

            // Atomically exchange current head with new node
            const prev = @atomicRmw(*Node, &q.head, .Xchg, node, .acq_rel);

            // Link previous node to new node
            @atomicStore(?*Node, &prev.next, node, .release);
        }

        /// Pop value from tail of queue
        pub fn pop(q: *@This()) ?Value {
            while (true) {
                var tail = q.tail;
                var next = @atomicLoad(?*Node, &tail.next, .acquire);

                // Handle empty case
                if (tail == &q.empty) {
                    if (next) |tail_next| {
                        // Before: tail -> [empty] -> [A] <- head
                        // After:  tail -> [A] <- head
                        if (@cmpxchgStrong(*Node, &q.tail, tail, tail_next, .acq_rel, .acquire)) |_| {
                            // Lost race, retry from start
                            continue;
                        }
                        tail = tail_next;
                        next = @atomicLoad(?*Node, &tail.next, .acquire);
                    } else return null; // State: tail -> [empty] <- head
                }

                // Fast path - if we have a next node
                if (next) |tail_next| {
                    // Before: tail -> [B] -> [A] <- head
                    // After:  tail -----> [A] <- head
                    // Return: [B]
                    if (@cmpxchgStrong(*Node, &q.tail, tail, tail_next, .acq_rel, .acquire)) |_| {
                        // Lost race, retry from start
                        continue;
                    }
                    std.debug.assert(tail != &q.empty);
                    const value = tail.value;
                    q.pool.release(tail);
                    return value;
                }

                // Check if queue is empty (race condition)
                const head = @atomicLoad(*Node, &q.head, .acquire);
                if (tail != head) {
                    // We saw tail.next == null (there is no next item); but head points to a different
                    // node than tail. This can only happen when a producer has done the XCHG to update
                    // head, but hasn't yet set the next pointer.
                    //
                    // State: tail -> [A]    [B] <- head
                    // Return: null (no next item yet)
                    //
                    // We don't return the `tail` node here, because it might still be getting linked. i.e.
                    // we must wait until tail.next != null to maintain proper ordering.
                    return null;
                }

                // tail.next == null (there is no next item) and tail == head (queue might be
                // empty OR in a concurrent push operation); we push the empty node to handle one of two
                // cases:
                //
                // (Case 1) Queue was truly empty, so pushing empty node completes the queue:
                //
                //   Before: tail -> [empty] <- head
                //   After:  tail -> [empty] -> [empty] <- head
                //   Return: null (because tail is empty node)
                //
                // (Case 2a) Race with concurrent push, concurrent push wins:
                //
                //   Before: tail -> [A] <- head     [B] being pushed concurrently
                //   After:  tail -> [A] -> [B] <- head
                //           [empty].next == [A] (lost race)
                //   Return: [A]
                //
                // (Case 2b) Race with concurrent push, our empty push wins:
                //
                //   Before: tail -> [A] <- head     [B] being pushed concurrently
                //   After:  tail -> [A] -> [empty] <- head
                //           [B].next == [A] (lost race)
                //   Return: [A]
                //
                q.pushRaw(&q.empty);
                next = @atomicLoad(?*Node, &tail.next, .acquire);
                if (next) |tail_next| {
                    if (@cmpxchgStrong(*Node, &q.tail, tail, tail_next, .acq_rel, .acquire)) |_| {
                        // Lost race, retry from start
                        continue;
                    }
                    if (tail == &q.empty) return null;
                    const value = tail.value;
                    q.pool.release(tail);
                    return value;
                }

                return null;
            }
        }

        /// Attempts to atomically take all nodes from the queue, returning the chain of all nodes
        /// currently in the queue, or null if (a) the queue is empty or (b) another takeAll()
        /// consumer beat us to taking it all.
        ///
        /// This operation is safe to call from multiple threads in parallel - only one will succeed
        /// in taking the nodes. Although takeAll() is safe to call in parallel, pop() may not be
        /// called in parallel with itself or takeAll().
        ///
        /// Caller takes ownership of all nodes up to the head at time of operation, and must free
        /// the entire chain by calling releaseAll(returned_node.?) later.
        ///
        /// The returned node is the first node in FIFO order, i.e. node is 1st, node.next is 2nd,
        /// node.next.next is 3rd, and so on in FIFO order.
        pub fn takeAll(q: *@This()) ?*Node {
            outer: while (true) {
                var tail = q.tail;
                const next = @atomicLoad(?*Node, &tail.next, .acquire);

                // First reset head to empty node atomically to ensure new pushes will link to [empty]
                // rather than our taken chain. This also acts as our point of taking ownership and
                // competing against other parallel takeAll() invocations.
                //
                // Before: head -> [A]
                // After:  head -> [empty]
                while (true) {
                    const current_head = @atomicLoad(*Node, &q.head, .acquire);
                    if (current_head == &q.empty) {
                        // Another takeAll won
                        return null;
                    }
                    if (@cmpxchgStrong(*Node, &q.head, current_head, &q.empty, .acq_rel, .acquire)) |_| {
                        continue;
                    }
                    break;
                }

                // Handle empty node advancement if needed
                if (tail == &q.empty) {
                    if (next) |tail_next| {
                        // Before: tail -> [empty] -> [A] <- head
                        // After:  tail -> [A] <- head
                        if (@cmpxchgStrong(*Node, &q.tail, tail, tail_next, .acq_rel, .acquire)) |_| {
                            continue :outer;
                        }
                        tail = tail_next;
                    } else return null; // State: tail -> [empty] <- head
                }

                // Try to take ownership of the chain
                //
                // Before: tail -> [B] -> [A] <- head=[empty]
                // After:  tail=[empty]
                // Return: [B] -> [A]
                if (@cmpxchgStrong(*Node, &q.tail, tail, &q.empty, .acq_rel, .acquire)) |_| {
                    // Lost race (with another takeAll() or pop()), retry from start
                    continue :outer;
                }
                return tail;
            }
        }

        /// Release a chain of nodes back to the pool starting from the given node.
        /// Used to return nodes acquired via takeAll() back to the pool.
        ///
        /// State: start -> [B] -> [A] -> null
        /// After: (all nodes returned to pool)
        pub fn releaseAll(q: *@This(), start: *Node) void {
            var current = start;
            while (true) {
                const next = current.next;
                current.next = null;
                q.pool.release(current);
                if (next == null) break;
                current = next.?;
            }
        }

        pub fn deinit(q: *@This(), allocator: std.mem.Allocator) void {
            q.pool.deinit(allocator);
        }
    };
}

test "basic" {
    const allocator = std.testing.allocator;

    var queue: Queue(u32) = undefined;
    try queue.init(allocator, 32);
    defer queue.deinit(allocator);

    // Push values
    try queue.push(allocator, 1);
    try queue.push(allocator, 2);
    try queue.push(allocator, 3);

    // Pop and verify
    try std.testing.expectEqual(queue.pop(), 1);
    try std.testing.expectEqual(queue.pop(), 2);
    try std.testing.expectEqual(queue.pop(), 3);
    try std.testing.expectEqual(queue.pop(), null);
}

test "takeAll" {
    const allocator = std.testing.allocator;

    var queue: Queue(u32) = undefined;
    try queue.init(allocator, 32);
    defer queue.deinit(allocator);

    // Take empty queue
    try std.testing.expectEqual(queue.takeAll(), null);
    try std.testing.expect(queue.head == &queue.empty);
    try std.testing.expect(queue.tail == &queue.empty);

    // Take single-element queue
    try queue.push(allocator, 1);
    if (queue.takeAll()) |nodes| {
        defer queue.releaseAll(nodes);
        try std.testing.expectEqual(nodes.value, 1);
        try std.testing.expectEqual(nodes.next, null);
        try std.testing.expect(queue.head == &queue.empty);
        try std.testing.expect(queue.tail == &queue.empty);
    } else {
        return error.TestUnexpectedNull;
    }

    // Take empty queue again
    try std.testing.expectEqual(queue.takeAll(), null);
    try std.testing.expect(queue.head == &queue.empty);
    try std.testing.expect(queue.tail == &queue.empty);

    // Multiple elements with push after takeAll
    try queue.push(allocator, 1);
    try queue.push(allocator, 2);
    try queue.push(allocator, 3);
    if (queue.takeAll()) |nodes| {
        try std.testing.expectEqual(nodes.value, 1);
        try std.testing.expectEqual(nodes.next.?.value, 2);
        try std.testing.expectEqual(nodes.next.?.next.?.value, 3);
        try std.testing.expectEqual(nodes.next.?.next.?.next, null);
        try std.testing.expect(queue.head == &queue.empty);
        try std.testing.expect(queue.tail == &queue.empty);

        // Push while holding taken nodes
        try queue.push(allocator, 42);
        try std.testing.expect(queue.head != &queue.empty);
        try std.testing.expect(queue.tail == &queue.empty);

        // Then release held nodes
        queue.releaseAll(nodes);
    } else return error.TestUnexpectedNull;

    // Verify queue state after all operations
    try std.testing.expectEqual(queue.pop(), 42);
    try std.testing.expectEqual(queue.pop(), null);
    try std.testing.expect(queue.head == &queue.empty);
    try std.testing.expect(queue.tail == &queue.empty);
}

test "single takeAll" {
    const allocator = std.testing.allocator;

    var queue: Queue(u32) = undefined;
    try queue.init(allocator, 32);
    defer queue.deinit(allocator);

    try queue.push(allocator, 1);

    if (queue.takeAll()) |nodes| {
        try std.testing.expectEqual(nodes.value, 1);
        try std.testing.expectEqual(nodes.next, null);
        try std.testing.expect(queue.head == &queue.empty);
        try std.testing.expect(queue.tail == &queue.empty);

        // Then release held nodes
        queue.releaseAll(nodes);
    } else return error.TestUnexpectedNull;
}
