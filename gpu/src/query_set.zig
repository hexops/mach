const ChainedStruct = @import("types.zig").ChainedStruct;
const PipelineStatisticName = @import("types.zig").PipelineStatisticName;
const QueryType = @import("types.zig").QueryType;

pub const QuerySet = *opaque {
    // TODO
    // pub inline fn querySetDestroy(query_set: gpu.QuerySet) void {

    // TODO
    // pub inline fn querySetGetCount(query_set: gpu.QuerySet) u32 {

    // TODO
    // pub inline fn querySetGetType(query_set: gpu.QuerySet) gpu.QueryType {

    // TODO
    // pub inline fn querySetSetLabel(query_set: gpu.QuerySet, label: [*:0]const u8) void {

    // TODO
    // pub inline fn querySetReference(query_set: gpu.QuerySet) void {

    // TODO
    // pub inline fn querySetRelease(query_set: gpu.QuerySet) void {
};

pub const QuerySetDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    type: QueryType,
    count: u32,
    pipeline_statistics: [*]const PipelineStatisticName,
    pipeline_statistics_count: u32,
};
