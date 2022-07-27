const ChainedStruct = @import("types.zig").ChainedStruct;
const ProgrammableStageDescriptor = @import("types.zig").ProgrammableStageDescriptor;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const impl = @import("interface.zig").impl;

pub const ComputePipeline = *opaque {
    pub inline fn getBindGroupLayout(compute_pipeline: ComputePipeline, group_index: u32) BindGroupLayout {
        return impl.computePipelineGetBindGroupLayout(compute_pipeline, group_index);
    }

    pub inline fn setLabel(compute_pipeline: ComputePipeline, label: [*:0]const u8) void {
        impl.computePipelineSetLabel(compute_pipeline, label);
    }

    pub inline fn reference(compute_pipeline: ComputePipeline) void {
        impl.computePipelineReference(compute_pipeline);
    }

    pub inline fn release(compute_pipeline: ComputePipeline) void {
        impl.computePipelineRelease(compute_pipeline);
    }
};

pub const ComputePipelineDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    layout: ?PipelineLayout,
    compute: ProgrammableStageDescriptor,
};
