const std = @import("std");
const uri_parser = @import("uri_parser.zig");

const ResourceManager = @This();

allocator: std.mem.Allocator,
paths: []const []const u8,
resource_types: []const ResourceType,
resources: std.ArrayListUnmanaged(Resource) = .{},
cwd: std.fs.Dir,

pub fn init(allocator: std.mem.Allocator, paths: []const []const u8, resource_types: []const ResourceType) !ResourceManager {
    var cwd = try std.fs.openDirAbsolute(try std.fs.selfExeDirPathAlloc(allocator), .{});
    errdefer cwd.close();

    return ResourceManager{
        .allocator = allocator,
        .paths = paths,
        .resource_types = resource_types,
        .cwd = cwd,
    };
}

pub const ResourceType = struct {
    name: []const u8,
    load: fn (context: *anyopaque, mem: []const u8) error{ InvalidResource, CorruptData }!*anyopaque,
    unload: fn (context: *anyopaque, resource: *anyopaque) void,
};

pub fn getResource(self: *ResourceManager, uri: []const u8) !Resource {
    var file: ?std.fs.File = null;
    const uri_data = try uri_parser.parseUri(uri);

    for (self.paths) |path| {
        var dir = try self.cwd.openDir(path, .{});
        defer dir.close();

        file = dir.openFile(uri_data.path, .{}) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        errdefer file.deinit();
    }

    if (file) |f| {
        var data = try f.reader().readAllAlloc(self.allocator, std.math.maxInt(usize));
        errdefer data.deinit();

        return Resource{ .resource = @ptrCast(*anyopaque, &data.ptr), .size = data.len };
    }

    return error.ResourceNotFound;
}

pub const Resource = struct {
    resource: *anyopaque,
    size: u64,

    // Returns the raw data, which you can use in any ways. Internally it is stored
    // as an *anyopaque
    pub fn getData(res: *const Resource, comptime T: type) *T {
        return @ptrCast(*T, @alignCast(std.meta.alignment(*T), res.resource));
    }
};
