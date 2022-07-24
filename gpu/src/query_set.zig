const ChainedStruct = @import("types.zig").ChainedStruct;
const PipelineStatisticName = @import("types.zig").PipelineStatisticName;
const QueryType = @import("types.zig").QueryType;

pub const QuerySet = *opaque {};

pub const QuerySetDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    type: QueryType,
    count: u32,
    pipeline_statistics: [*]const PipelineStatisticName,
    pipeline_statistics_count: u32,
};
