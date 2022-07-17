const ChainedStruct = @import("types.zig").ChainedStruct;
const ProgrammableStageDescriptor = @import("types.zig").ProgrammableStageDescriptor;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;

pub const ComputePipeline = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: ComputePipeline = @intToEnum(ComputePipeline, 0);

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
        layout: PipelineLayout = PipelineLayout.none, // nullable
        compute: ProgrammableStageDescriptor,
    };
};
