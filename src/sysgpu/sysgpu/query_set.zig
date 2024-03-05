const ChainedStruct = @import("main.zig").ChainedStruct;
const PipelineStatisticName = @import("main.zig").PipelineStatisticName;
const QueryType = @import("main.zig").QueryType;
const Impl = @import("interface.zig").Impl;

pub const QuerySet = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        type: QueryType,
        count: u32,
        pipeline_statistics: ?[*]const PipelineStatisticName = null,
        pipeline_statistics_count: usize = 0,

        /// Provides a slightly friendlier Zig API to initialize this structure.
        pub inline fn init(v: struct {
            next_in_chain: ?*const ChainedStruct = null,
            label: ?[*:0]const u8 = null,
            type: QueryType,
            count: u32,
            pipeline_statistics: ?[]const PipelineStatisticName = null,
        }) Descriptor {
            return .{
                .next_in_chain = v.next_in_chain,
                .label = v.label,
                .type = v.type,
                .count = v.count,
                .pipeline_statistics_count = if (v.pipeline_statistics) |e| e.len else 0,
                .pipeline_statistics = if (v.pipeline_statistics) |e| e.ptr else null,
            };
        }
    };

    pub inline fn destroy(query_set: *QuerySet) void {
        Impl.querySetDestroy(query_set);
    }

    pub inline fn getCount(query_set: *QuerySet) u32 {
        return Impl.querySetGetCount(query_set);
    }

    pub inline fn getType(query_set: *QuerySet) QueryType {
        return Impl.querySetGetType(query_set);
    }

    pub inline fn setLabel(query_set: *QuerySet, label: [*:0]const u8) void {
        Impl.querySetSetLabel(query_set, label);
    }

    pub inline fn reference(query_set: *QuerySet) void {
        Impl.querySetReference(query_set);
    }

    pub inline fn release(query_set: *QuerySet) void {
        Impl.querySetRelease(query_set);
    }
};
