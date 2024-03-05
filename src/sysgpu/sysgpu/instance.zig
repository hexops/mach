const ChainedStruct = @import("main.zig").ChainedStruct;
const RequestAdapterStatus = @import("main.zig").RequestAdapterStatus;
const Surface = @import("surface.zig").Surface;
const Adapter = @import("adapter.zig").Adapter;
const RequestAdapterOptions = @import("main.zig").RequestAdapterOptions;
const RequestAdapterCallback = @import("main.zig").RequestAdapterCallback;
const Impl = @import("interface.zig").Impl;
const dawn = @import("dawn.zig");

pub const Instance = opaque {
    pub const Descriptor = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            dawn_toggles_descriptor: *const dawn.TogglesDescriptor,
        };

        next_in_chain: NextInChain = .{ .generic = null },
    };

    pub inline fn createSurface(instance: *Instance, descriptor: *const Surface.Descriptor) *Surface {
        return Impl.instanceCreateSurface(instance, descriptor);
    }

    pub inline fn processEvents(instance: *Instance) void {
        Impl.instanceProcessEvents(instance);
    }

    pub inline fn requestAdapter(
        instance: *Instance,
        options: ?*const RequestAdapterOptions,
        context: anytype,
        comptime callback: fn (
            ctx: @TypeOf(context),
            status: RequestAdapterStatus,
            adapter: ?*Adapter,
            message: ?[*:0]const u8,
        ) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn cCallback(
                status: RequestAdapterStatus,
                adapter: ?*Adapter,
                message: ?[*:0]const u8,
                userdata: ?*anyopaque,
            ) callconv(.C) void {
                callback(
                    if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))),
                    status,
                    adapter,
                    message,
                );
            }
        };
        Impl.instanceRequestAdapter(instance, options, Helper.cCallback, if (Context == void) null else context);
    }

    pub inline fn reference(instance: *Instance) void {
        Impl.instanceReference(instance);
    }

    pub inline fn release(instance: *Instance) void {
        Impl.instanceRelease(instance);
    }
};
