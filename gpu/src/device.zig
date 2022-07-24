const ChainedStruct = @import("types.zig").ChainedStruct;
const FeatureName = @import("types.zig").FeatureName;
const RequiredLimits = @import("types.zig").RequiredLimits;
const Queue = @import("queue.zig").Queue;

pub const Device = *opaque {};

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
    default_queue: Queue.Descriptor,
};
