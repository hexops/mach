const ChainedStruct = @import("types.zig").ChainedStruct;
const RequestAdapterStatus = @import("types.zig").RequestAdapterStatus;
const Adapter = @import("adapter.zig").Adapter;

pub const Instance = *opaque {};

pub const RequestAdapterCallback = fn (
    status: RequestAdapterStatus,
    adapter: Adapter,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const InstanceDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
};
