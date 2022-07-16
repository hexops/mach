const ChainedStruct = @import("types.zig").ChainedStruct;

pub const CacheDeviceDescriptor = struct {
    // TODO: file an issue on Dawn: why not named nextInChain?
    chain: ChainedStruct,
    isolation_key: [*:0]const u8,
};
