const ChainedStruct = @import("types.zig").ChainedStruct;
const ProgrammableStageDescriptor = @import("types.zig").ProgrammableStageDescriptor;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;

pub const ComputePipeline = *opaque {};

pub const ComputePipelineDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    layout: PipelineLayout = PipelineLayout.none, // nullable
    compute: ProgrammableStageDescriptor,
};
