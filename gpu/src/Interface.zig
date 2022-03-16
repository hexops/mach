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

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    requestAdapter: fn requestAdapter(
        ptr: *anyopaque,
        options: *const RequestAdapterOptions,
        callback: *RequestAdapterCallback,
    ) void,
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

pub fn requestAdapter(
    interface: Interface,
    options: *const RequestAdapterOptions,
    callback: *RequestAdapterCallback,
) void {
    interface.vtable.requestAdapter(interface.ptr, options, callback);
}

pub const RequestAdapterCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (ctx: *anyopaque, response: RequestAdapterResponse) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: *Context,
        comptime callback: fn (ctx: *Context, response: RequestAdapterResponse) void,
    ) RequestAdapterCallback {
        const erased = (struct {
            pub inline fn erased(type_erased_ctx: *anyopaque, response: RequestAdapterResponse) void {
                callback(@ptrCast(*Context, @alignCast(@alignOf(*Context), type_erased_ctx)), response);
            }
        }).erased;

        return .{
            .type_erased_ctx = ctx,
            .type_erased_callback = erased,
        };
    }
};

/// A helper which invokes requestAdapter and blocks until the adapter is recieved.
pub fn waitForAdapter(interface: Interface, options: *const RequestAdapterOptions) RequestAdapterResponse {
    const Context = RequestAdapterResponse;
    var response: Context = undefined;
    var callback = RequestAdapterCallback.init(Context, &response, (struct {
        pub fn callback(ctx: *Context, callback_response: RequestAdapterResponse) void {
            ctx.* = callback_response;
        }
    }).callback);

    interface.requestAdapter(options, &callback);

    // TODO: FUTURE: Once crbug.com/dawn/1122 is fixed, we should process events here otherwise our
    // callback would not be invoked:
    //c.wgpuInstanceProcessEvents(interface.instance)

    return response;
}

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = RequestAdapterOptions;
    _ = RequestAdapterErrorCode;
    _ = RequestAdapterError;
    _ = RequestAdapterResponse;
    _ = requestAdapter;
    _ = waitForAdapter;
}
