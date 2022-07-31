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

    pub inline fn requestAdapter(
        instance: *Instance,
        options: *const RequestAdapterOptions,
        comptime Context: type,
        comptime callback: fn (
            status: RequestAdapterStatus,
            adapter: *Adapter,
            message: ?[*:0]const u8,
            ctx: Context,
        ) callconv(.Inline) void,
        context: Context,
    ) void {
        const Helper = struct {
            pub fn callback(
                status: RequestAdapterStatus,
                adapter: *Adapter,
                message: ?[*:0]const u8,
                userdata: ?*anyopaque,
            ) callconv(.C) void {
                callback(
                    status,
                    adapter,
                    message,
                    if (Context == void) {} orelse @ptrCast(Context, userdata),
                );
            }
        };
        Impl.instanceRequestAdapter(instance, options, Helper.callback, if (Context == void) null orelse context);
    }

    pub inline fn reference(instance: *Instance) void {
        Impl.instanceReference(instance);
    }

    pub inline fn release(instance: *Instance) void {
        Impl.instanceRelease(instance);
    }
};
