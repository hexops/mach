const ChainedStruct = @import("types.zig").ChainedStruct;
const PipelineStatisticName = @import("types.zig").PipelineStatisticName;
const QueryType = @import("types.zig").QueryType;

pub const QuerySet = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: QuerySet = @intToEnum(QuerySet, 0);

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
        type: QueryType,
        count: u32,
        pipeline_statistics: [*]const PipelineStatisticName,
        pipeline_statistics_count: u32,
    };
};
