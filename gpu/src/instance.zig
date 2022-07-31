const ChainedStruct = @import("types.zig").ChainedStruct;
const RequestAdapterStatus = @import("types.zig").RequestAdapterStatus;
const Surface = @import("surface.zig").Surface;
const Adapter = @import("adapter.zig").Adapter;
const RequestAdapterOptions = @import("types.zig").RequestAdapterOptions;
const RequestAdapterCallback = @import("callbacks.zig").RequestAdapterCallback;
const Impl = @import("interface.zig").Impl;

pub const Instance = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
    };

    pub inline fn createSurface(instance: *Instance, descriptor: *const Surface.Descriptor) *Surface {
        return Impl.instanceCreateSurface(instance, descriptor);
    }

    pub inline fn requestAdapter(instance: *Instance, options: *const RequestAdapterOptions, callback: RequestAdapterCallback, userdata: *anyopaque) void {
        Impl.instanceRequestAdapter(instance, options, callback, userdata);
    }

    pub inline fn reference(instance: *Instance) void {
        Impl.instanceReference(instance);
    }

    pub inline fn release(instance: *Instance) void {
        Impl.instanceRelease(instance);
    }
};
