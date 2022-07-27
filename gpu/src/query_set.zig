const ChainedStruct = @import("types.zig").ChainedStruct;
const PipelineStatisticName = @import("types.zig").PipelineStatisticName;
const QueryType = @import("types.zig").QueryType;
const impl = @import("interface.zig").impl;

pub const QuerySet = *opaque {
    pub inline fn destroy(query_set: QuerySet) void {
        impl.querySetDestroy(query_set);
    }

    pub inline fn getCount(query_set: QuerySet) u32 {
        return impl.querySetGetCount(query_set);
    }

    pub inline fn getType(query_set: QuerySet) QueryType {
        return impl.querySetGetType(query_set);
    }

    pub inline fn setLabel(query_set: QuerySet, label: [*:0]const u8) void {
        impl.querySetSetLabel(query_set, label);
    }

    pub inline fn reference(query_set: QuerySet) void {
        impl.querySetReference(query_set);
    }

    pub inline fn release(query_set: QuerySet) void {
        impl.querySetRelease(query_set);
    }
};

pub const QuerySetDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    type: QueryType,
    count: u32,
    pipeline_statistics: [*]const PipelineStatisticName,
    pipeline_statistics_count: u32,
};
