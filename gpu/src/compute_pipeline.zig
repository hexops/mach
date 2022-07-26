const ChainedStruct = @import("types.zig").ChainedStruct;
const ProgrammableStageDescriptor = @import("types.zig").ProgrammableStageDescriptor;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;

pub const ComputePipeline = *opaque {
    // TODO
    // pub inline fn computePipelineGetBindGroupLayout(compute_pipeline: gpu.ComputePipeline, group_index: u32) gpu.BindGroupLayout {

    // TODO
    // pub inline fn computePipelineSetLabel(compute_pipeline: gpu.ComputePipeline, label: [*:0]const u8) void {

    // TODO
    // pub inline fn computePipelineReference(compute_pipeline: gpu.ComputePipeline) void {

    // TODO
    // pub inline fn computePipelineRelease(compute_pipeline: gpu.ComputePipeline) void {
};

pub const ComputePipelineDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    layout: ?PipelineLayout,
    compute: ProgrammableStageDescriptor,
};
