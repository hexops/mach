const ChainedStruct = @import("main.zig").ChainedStruct;
const ProgrammableStageDescriptor = @import("main.zig").ProgrammableStageDescriptor;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const Impl = @import("interface.zig").Impl;

pub const ComputePipeline = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        layout: ?*PipelineLayout = null,
        compute: ProgrammableStageDescriptor,
    };

    pub inline fn getBindGroupLayout(compute_pipeline: *ComputePipeline, group_index: u32) *BindGroupLayout {
        return Impl.computePipelineGetBindGroupLayout(compute_pipeline, group_index);
    }

    pub inline fn setLabel(compute_pipeline: *ComputePipeline, label: [*:0]const u8) void {
        Impl.computePipelineSetLabel(compute_pipeline, label);
    }

    pub inline fn reference(compute_pipeline: *ComputePipeline) void {
        Impl.computePipelineReference(compute_pipeline);
    }

    pub inline fn release(compute_pipeline: *ComputePipeline) void {
        Impl.computePipelineRelease(compute_pipeline);
    }
};
