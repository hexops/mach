//! Implements a [texture atlas](https://en.wikipedia.org/wiki/Texture_atlas).
//!
//! This implementation is based on "A Thousand Ways to Pack the Bin - A Practical Approach to
//! Two-Dimensional Rectangle Bin Packing" by Jukka Jylänki. This specific implementation originates
//! [from Mitchell Hashimoto](https://gist.github.com/mitchellh/0c023dbd381c42e145b5da8d58b1487f)
//! which is itself based heavily on Nicolas P. Rougier's freetype-gl project as well as Jukka's C++
//! [implementation](https://github.com/juj/RectangleBinPack).
//!
//! There are two known limitations:
//!
//!   * Written data must be packed, no support for custom strides.
//!   * Texture is always a square, no ability to set width != height. Note
//!     that regions written INTO the atlas do not have to be square, only
//!     the full atlas texture itself.
//!
const Atlas = @This();

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const testing = std.testing;

const log = std.log.scoped(.atlas);

/// Data is the raw texture data.
data: []u8,

/// Width and height of the atlas texture. The current implementation is
/// always square so this is both the width and the height.
size: u32 = 0,

/// The nodes (rectangles) of available space.
nodes: std.ArrayListUnmanaged(Node) = .{},

/// The format of the texture data being written into the Atlas. This must be
/// uniform for all textures in the Atlas. If you have some textures with
/// different formats, you must use multiple atlases or convert the textures.
format: Format = .greyscale,

/// This will be set to true when the atlas has data set on it. It is up
/// to the user of the atlas to set this to false when they observe the value.
/// This is a useful value to know if you need to send new data to the GPU or
/// not.
modified: bool = false,

/// This will be set to true when the atlas has been resized. It is up
/// to the user of the atlas to set this to false when they observe the value.
/// The resized value is useful for sending textures to the GPU to know if
/// a new texture needs to be allocated or if an existing one can be
/// updated in-place.
resized: bool = false,

pub const Format = enum(u8) {
    greyscale = 0,
    rgb = 1,
    rgba = 2,

    pub fn depth(self: Format) u8 {
        return switch (self) {
            .greyscale => 1,
            .rgb => 3,
            .rgba => 4,
        };
    }
};

const Node = struct {
    x: u32,
    y: u32,
    width: u32,
};

pub const Error = error{
    /// Atlas cannot fit the desired region. You must enlarge the atlas.
    AtlasFull,
};

/// A region within the texture atlas. These can be acquired using the
/// "reserve" function. A region reservation is required to write data.
pub const Region = extern struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,

    pub const UV = extern struct {
        x: f32,
        y: f32,
        width: f32,
        height: f32,
    };

    pub inline fn calculateUV(r: Region, size: u32) UV {
        var uv = UV{
            .x = @floatFromInt(r.x),
            .y = @floatFromInt(r.y),
            .width = @floatFromInt(r.width),
            .height = @floatFromInt(r.height),
        };
        uv.x /= @floatFromInt(size);
        uv.y /= @floatFromInt(size);
        uv.width /= @floatFromInt(size);
        uv.height /= @floatFromInt(size);
        return uv;
    }
};

pub fn init(alloc: Allocator, size: u32, format: Format) !Atlas {
    var result = Atlas{
        .data = try alloc.alloc(u8, size * size * format.depth()),
        .size = size,
        .nodes = .{},
        .format = format,
    };
    errdefer result.deinit(alloc);

    // TODO: figure out optimal prealloc based on real world usage
    try result.nodes.ensureUnusedCapacity(alloc, 64);

    // This sets up our initial state
    result.clear();
    result.modified = false;

    return result;
}

pub fn deinit(self: *Atlas, alloc: Allocator) void {
    self.nodes.deinit(alloc);
    alloc.free(self.data);
    self.* = undefined;
}

/// Reserve a region within the atlas with the given width and height.
///
/// May allocate to add a new rectangle into the internal list of rectangles.
/// This will not automatically enlarge the texture if it is full.
pub fn reserve(self: *Atlas, alloc: Allocator, width: u32, height: u32) !Region {
    // x, y are populated within :best_idx below
    var region: Region = .{ .x = 0, .y = 0, .width = width, .height = height };

    // If our width/height are 0, then we return the region as-is. This
    // may seem like an error case but it simplifies downstream callers who
    // might be trying to write empty data.
    if (width == 0 and height == 0) return region;

    // Find the location in our nodes list to insert the new node for this region.
    var best_idx: usize = best_idx: {
        var best_height: u32 = std.math.maxInt(u32);
        var best_width: u32 = best_height;
        var chosen: ?usize = null;

        var i: usize = 0;
        while (i < self.nodes.items.len) : (i += 1) {
            // Check if our region fits within this node.
            const y = self.fit(i, width, height) orelse continue;

            const node = self.nodes.items[i];
            if ((y + height) < best_height or
                ((y + height) == best_height and
                (node.width > 0 and node.width < best_width)))
            {
                chosen = i;
                best_width = node.width;
                best_height = y + height;
                region.x = node.x;
                region.y = y;
            }
        }

        // If we never found a chosen index, the atlas cannot fit our region.
        break :best_idx chosen orelse return Error.AtlasFull;
    };

    // Insert our new node for this rectangle at the exact best index
    try self.nodes.insert(alloc, best_idx, .{
        .x = region.x,
        .y = region.y + height,
        .width = width,
    });

    // Optimize our rectangles
    var i: usize = best_idx + 1;
    while (i < self.nodes.items.len) : (i += 1) {
        const node = &self.nodes.items[i];
        const prev = self.nodes.items[i - 1];
        if (node.x < (prev.x + prev.width)) {
            const shrink = prev.x + prev.width - node.x;
            node.x += shrink;
            node.width -|= shrink;
            if (node.width <= 0) {
                _ = self.nodes.orderedRemove(i);
                i -= 1;
                continue;
            }
        }

        break;
    }
    self.merge();

    return region;
}

/// Attempts to fit a rectangle of width x height into the node at idx.
/// The return value is the y within the texture where the rectangle can be
/// placed. The x is the same as the node.
fn fit(self: Atlas, idx: usize, width: u32, height: u32) ?u32 {
    // If the added width exceeds our texture size, it doesn't fit.
    const node = self.nodes.items[idx];
    if ((node.x + width) > (self.size - 1)) return null;

    // Go node by node looking for space that can fit our width.
    var y = node.y;
    var i = idx;
    var width_left = width;
    while (width_left > 0) : (i += 1) {
        const n = self.nodes.items[i];
        if (n.y > y) y = n.y;

        // If the added height exceeds our texture size, it doesn't fit.
        if ((y + height) > (self.size - 1)) return null;

        width_left -|= n.width;
    }

    return y;
}

/// Merge adjacent nodes with the same y value.
fn merge(self: *Atlas) void {
    var i: usize = 0;
    while (i < self.nodes.items.len - 1) {
        const node = &self.nodes.items[i];
        const next = self.nodes.items[i + 1];
        if (node.y == next.y) {
            node.width += next.width;
            _ = self.nodes.orderedRemove(i + 1);
            continue;
        }

        i += 1;
    }
}

/// Set the data associated with a reserved region. The data is expected
/// to fit exactly within the region. The data must be formatted with the
/// proper bpp configured on init.
pub fn set(self: *Atlas, reg: Region, data: []const u8) void {
    assert(reg.x < (self.size - 1));
    assert((reg.x + reg.width) <= (self.size - 1));
    assert(reg.y < (self.size - 1));
    assert((reg.y + reg.height) <= (self.size - 1));

    const depth = self.format.depth();
    var i: u32 = 0;
    while (i < reg.height) : (i += 1) {
        const tex_offset = (((reg.y + i) * self.size) + reg.x) * depth;
        const data_offset = i * reg.width * depth;
        std.mem.copy(
            u8,
            self.data[tex_offset..],
            data[data_offset .. data_offset + (reg.width * depth)],
        );
    }

    self.modified = true;
}

// Grow the texture to the new size, preserving all previously written data.
pub fn grow(self: *Atlas, alloc: Allocator, size_new: u32) Allocator.Error!void {
    assert(size_new >= self.size);
    if (size_new == self.size) return;

    // Preserve our old values so we can copy the old data
    const data_old = self.data;
    const size_old = self.size;

    // Allocate our new data
    self.data = try alloc.alloc(u8, size_new * size_new * self.format.depth());
    defer alloc.free(data_old);
    errdefer {
        alloc.free(self.data);
        self.data = data_old;
    }

    // Add our new rectangle for our added righthand space. We do this
    // right away since its the only operation that can fail and we want
    // to make error cleanup easier.
    try self.nodes.append(alloc, .{
        .x = size_old - 1,
        .y = 1,
        .width = size_new - size_old,
    });

    // If our allocation and rectangle add succeeded, we can go ahead
    // and persist our new size and copy over the old data.
    self.size = size_new;
    @memset(self.data, 0);
    self.set(.{
        .x = 0, // don't bother skipping border so we can avoid strides
        .y = 1, // skip the first border row
        .width = size_old,
        .height = size_old - 2, // skip the last border row
    }, data_old[size_old * self.format.depth() ..]);

    // We are both modified and resized
    self.modified = true;
    self.resized = true;
}

// Empty the atlas. This doesn't reclaim any previously allocated memory.
pub fn clear(self: *Atlas) void {
    self.modified = true;
    @memset(self.data, 0);
    self.nodes.clearRetainingCapacity();

    // Add our initial rectangle. This is the size of the full texture
    // and is the initial rectangle we fit our regions in. We keep a 1px border
    // to avoid artifacting when sampling the texture.
    self.nodes.appendAssumeCapacity(.{ .x = 1, .y = 1, .width = self.size - 2 });
}

test "exact fit" {
    const alloc = testing.allocator;
    var atlas = try init(alloc, 34, .greyscale); // +2 for 1px border
    defer atlas.deinit(alloc);

    _ = try atlas.reserve(alloc, 32, 32);
    try testing.expect(!atlas.modified);
    try testing.expectError(Error.AtlasFull, atlas.reserve(alloc, 1, 1));
}

test "doesnt fit" {
    const alloc = testing.allocator;
    var atlas = try init(alloc, 32, .greyscale);
    defer atlas.deinit(alloc);

    // doesn't fit due to border
    try testing.expectError(Error.AtlasFull, atlas.reserve(alloc, 32, 32));
}

test "fit multiple" {
    const alloc = testing.allocator;
    var atlas = try init(alloc, 32, .greyscale);
    defer atlas.deinit(alloc);

    _ = try atlas.reserve(alloc, 15, 30);
    _ = try atlas.reserve(alloc, 15, 30);
    try testing.expectError(Error.AtlasFull, atlas.reserve(alloc, 1, 1));
}

test "writing data" {
    const alloc = testing.allocator;
    var atlas = try init(alloc, 32, .greyscale);
    defer atlas.deinit(alloc);

    const reg = try atlas.reserve(alloc, 2, 2);
    try testing.expect(!atlas.modified);
    atlas.set(reg, &[_]u8{ 1, 2, 3, 4 });
    try testing.expect(atlas.modified);

    // 33 because of the 1px border and so on
    try testing.expectEqual(@as(u8, 1), atlas.data[33]);
    try testing.expectEqual(@as(u8, 2), atlas.data[34]);
    try testing.expectEqual(@as(u8, 3), atlas.data[65]);
    try testing.expectEqual(@as(u8, 4), atlas.data[66]);
}

test "grow" {
    const alloc = testing.allocator;
    var atlas = try init(alloc, 4, .greyscale); // +2 for 1px border
    defer atlas.deinit(alloc);

    const reg = try atlas.reserve(alloc, 2, 2);
    try testing.expectError(Error.AtlasFull, atlas.reserve(alloc, 1, 1));

    // Write some data so we can verify that growing doesn't mess it up
    atlas.set(reg, &[_]u8{ 1, 2, 3, 4 });
    try testing.expectEqual(@as(u8, 1), atlas.data[5]);
    try testing.expectEqual(@as(u8, 2), atlas.data[6]);
    try testing.expectEqual(@as(u8, 3), atlas.data[9]);
    try testing.expectEqual(@as(u8, 4), atlas.data[10]);

    // Reset our state
    atlas.modified = false;
    atlas.resized = false;

    // Expand by exactly 1 should fit our new 1x1 block.
    try atlas.grow(alloc, atlas.size + 1);
    try testing.expect(atlas.modified);
    try testing.expect(atlas.resized);
    _ = try atlas.reserve(alloc, 1, 1);

    // Ensure our data is still set. Not the offsets change due to size.
    try testing.expectEqual(@as(u8, 1), atlas.data[atlas.size + 1]);
    try testing.expectEqual(@as(u8, 2), atlas.data[atlas.size + 2]);
    try testing.expectEqual(@as(u8, 3), atlas.data[atlas.size * 2 + 1]);
    try testing.expectEqual(@as(u8, 4), atlas.data[atlas.size * 2 + 2]);
}

test "writing RGB data" {
    const alloc = testing.allocator;
    var atlas = try init(alloc, 32, .rgb);
    defer atlas.deinit(alloc);

    // This is RGB so its 3 bpp
    const reg = try atlas.reserve(alloc, 1, 2);
    atlas.set(reg, &[_]u8{
        1, 2, 3,
        4, 5, 6,
    });

    // 33 because of the 1px border and so on
    const depth = @as(usize, @intCast(atlas.format.depth()));
    try testing.expectEqual(@as(u8, 1), atlas.data[33 * depth]);
    try testing.expectEqual(@as(u8, 2), atlas.data[33 * depth + 1]);
    try testing.expectEqual(@as(u8, 3), atlas.data[33 * depth + 2]);
    try testing.expectEqual(@as(u8, 4), atlas.data[65 * depth]);
    try testing.expectEqual(@as(u8, 5), atlas.data[65 * depth + 1]);
    try testing.expectEqual(@as(u8, 6), atlas.data[65 * depth + 2]);
}

test "grow RGB" {
    const alloc = testing.allocator;

    // Atlas is 4x4 so its a 1px border meaning we only have 2x2 available
    var atlas = try init(alloc, 4, .rgb);
    defer atlas.deinit(alloc);

    // Get our 2x2, which should be ALL our usable space
    const reg = try atlas.reserve(alloc, 2, 2);
    try testing.expectError(Error.AtlasFull, atlas.reserve(alloc, 1, 1));

    // This is RGB so its 3 bpp
    atlas.set(reg, &[_]u8{
        10, 11, 12, // (0, 0) (x, y) from top-left
        13, 14, 15, // (1, 0)
        20, 21, 22, // (0, 1)
        23, 24, 25, // (1, 1)
    });

    // Our top left skips the first row (size * depth) and the first
    // column (depth) for the 1px border.
    const depth = @as(usize, @intCast(atlas.format.depth()));
    var tl = (atlas.size * depth) + depth;
    try testing.expectEqual(@as(u8, 10), atlas.data[tl]);
    try testing.expectEqual(@as(u8, 11), atlas.data[tl + 1]);
    try testing.expectEqual(@as(u8, 12), atlas.data[tl + 2]);
    try testing.expectEqual(@as(u8, 13), atlas.data[tl + 3]);
    try testing.expectEqual(@as(u8, 14), atlas.data[tl + 4]);
    try testing.expectEqual(@as(u8, 15), atlas.data[tl + 5]);
    try testing.expectEqual(@as(u8, 0), atlas.data[tl + 6]); // border

    tl += (atlas.size * depth); // next row
    try testing.expectEqual(@as(u8, 20), atlas.data[tl]);
    try testing.expectEqual(@as(u8, 21), atlas.data[tl + 1]);
    try testing.expectEqual(@as(u8, 22), atlas.data[tl + 2]);
    try testing.expectEqual(@as(u8, 23), atlas.data[tl + 3]);
    try testing.expectEqual(@as(u8, 24), atlas.data[tl + 4]);
    try testing.expectEqual(@as(u8, 25), atlas.data[tl + 5]);
    try testing.expectEqual(@as(u8, 0), atlas.data[tl + 6]); // border

    // Expand by exactly 1 should fit our new 1x1 block.
    try atlas.grow(alloc, atlas.size + 1);

    // Data should be in same place accounting for the new size
    tl = (atlas.size * depth) + depth;
    try testing.expectEqual(@as(u8, 10), atlas.data[tl]);
    try testing.expectEqual(@as(u8, 11), atlas.data[tl + 1]);
    try testing.expectEqual(@as(u8, 12), atlas.data[tl + 2]);
    try testing.expectEqual(@as(u8, 13), atlas.data[tl + 3]);
    try testing.expectEqual(@as(u8, 14), atlas.data[tl + 4]);
    try testing.expectEqual(@as(u8, 15), atlas.data[tl + 5]);
    try testing.expectEqual(@as(u8, 0), atlas.data[tl + 6]); // border

    tl += (atlas.size * depth); // next row
    try testing.expectEqual(@as(u8, 20), atlas.data[tl]);
    try testing.expectEqual(@as(u8, 21), atlas.data[tl + 1]);
    try testing.expectEqual(@as(u8, 22), atlas.data[tl + 2]);
    try testing.expectEqual(@as(u8, 23), atlas.data[tl + 3]);
    try testing.expectEqual(@as(u8, 24), atlas.data[tl + 4]);
    try testing.expectEqual(@as(u8, 25), atlas.data[tl + 5]);
    try testing.expectEqual(@as(u8, 0), atlas.data[tl + 6]); // border

    // Should fit the new blocks around the edges
    _ = try atlas.reserve(alloc, 1, 3);
    _ = try atlas.reserve(alloc, 2, 1);
    try testing.expectError(Error.AtlasFull, atlas.reserve(alloc, 1, 1));
}
