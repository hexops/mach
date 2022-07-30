const ChainedStruct = @import("types.zig").ChainedStruct;
const RequestAdapterStatus = @import("types.zig").RequestAdapterStatus;
const Surface = @import("surface.zig").Surface;
const SurfaceDescriptor = @import("surface.zig").SurfaceDescriptor;
const Adapter = @import("adapter.zig").Adapter;
const RequestAdapterOptions = @import("main.zig").RequestAdapterOptions;
const Impl = @import("interface.zig").Impl;

pub const Instance = *opaque {
    pub inline fn createSurface(instance: Instance, descriptor: *const SurfaceDescriptor) Surface {
        return Impl.instanceCreateSurface(instance, descriptor);
    }

    pub inline fn requestAdapter(instance: Instance, options: *const RequestAdapterOptions, callback: RequestAdapterCallback, userdata: *anyopaque) void {
        Impl.instanceRequestAdapter(instance, options, callback, userdata);
    }

    pub inline fn reference(instance: Instance) void {
        Impl.instanceReference(instance);
    }

    pub inline fn release(instance: Instance) void {
        Impl.instanceRelease(instance);
    }
};

pub const RequestAdapterCallback = fn (
    status: RequestAdapterStatus,
    adapter: *Adapter,
    message: ?[*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const InstanceDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
};
