const ChainedStruct = @import("types.zig").ChainedStruct;
const FeatureName = @import("types.zig").FeatureName;
const RequiredLimits = @import("types.zig").RequiredLimits;
const Queue = @import("queue.zig").Queue;
const QueueDescriptor = @import("queue.zig").QueueDescriptor;

pub const Device = *opaque {};

pub const DeviceLostCallback = fn (
    reason: DeviceLostReason,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const DeviceLostReason = enum(u32) {
    undef = 0x00000000,
    destroyed = 0x00000001,
};

pub const DeviceDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    required_features_count: u32,
    required_features: [*]const FeatureName,
    required_limits: ?*const RequiredLimits = null, // nullable
    default_queue: QueueDescriptor,
};
