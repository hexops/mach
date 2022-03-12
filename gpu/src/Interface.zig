//! A standard interface to a WebGPU implementation.
//!
//! Like std.mem.Allocator, but representing a WebGPU implementation.
const std = @import("std");

const Surface = @import("Surface.zig");
const Adapter = @import("Adapter.zig");
const PowerPreference = @import("enums.zig").PowerPreference;

const Interface = @This();

/// The type erased pointer to the Interface implementation
ptr: *anyopaque,
vtable: *const VTable,

// The @frameSize(func) of the implementations requestAdapter async function
request_adapter_frame_size: usize,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    requestAdapter: fn requestAdapter(ptr: *anyopaque, options: *const RequestAdapterOptions) callconv(.Async) RequestAdapterResponse,
};

pub inline fn reference(interface: Interface) void {
    interface.vtable.reference(interface.ptr);
}

pub inline fn release(interface: Interface) void {
    interface.vtable.release(interface.ptr);
}

pub const RequestAdapterOptions = struct {
    power_preference: PowerPreference,
    force_fallback_adapter: bool = false,

    /// Only respected by native WebGPU implementations.
    compatible_surface: ?Surface = null,
};

pub const RequestAdapterErrorCode = error{
    Unavailable,
    Error,
    Unknown,
};

pub const RequestAdapterError = struct {
    message: []const u8,
    code: RequestAdapterErrorCode,
};

pub const RequestAdapterResponseTag = enum {
    adapter,
    err,
};

pub const RequestAdapterResponse = union(RequestAdapterResponseTag) {
    adapter: Adapter,
    err: RequestAdapterError,
};

pub fn requestAdapter(interface: Interface, options: *const RequestAdapterOptions) callconv(.Async) RequestAdapterResponse {
    var frame_buffer = std.heap.page_allocator.allocAdvanced(
        u8,
        16,
        interface.request_adapter_frame_size,
        std.mem.Allocator.Exact.at_least,
    ) catch {
        return .{ .err = .{
            .message = "Out of memory",
            .code = RequestAdapterErrorCode.Error,
        } };
    };
    defer std.heap.page_allocator.free(frame_buffer);

    var result: RequestAdapterResponse = undefined;
    const f = @asyncCall(frame_buffer, &result, interface.vtable.requestAdapter, .{ interface.ptr, options });
    resume f;
    return result;
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = RequestAdapterOptions;
    _ = RequestAdapterErrorCode;
    _ = RequestAdapterError;
    _ = RequestAdapterResponse;
    _ = requestAdapter;
}
