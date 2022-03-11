const PipelineLayout = @import("PipelineLayout.zig");
const ProgrammableStageDescriptor = @import("structs.zig").ProgrammableStageDescriptor;

const ComputePipeline = @This();

/// The type erased pointer to the ComputePipeline implementation
/// Equal to c.WGPUComputePipeline for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT WGPUBindGroupLayout wgpuComputePipelineGetBindGroupLayout(WGPUComputePipeline computePipeline, uint32_t groupIndex);
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(pipeline: ComputePipeline) void {
    pipeline.vtable.reference(pipeline.ptr);
}

pub inline fn release(pipeline: ComputePipeline) void {
    pipeline.vtable.release(pipeline.ptr);
}

pub inline fn setLabel(pipeline: ComputePipeline, label: [:0]const u8) void {
    pipeline.vtable.setLabel(pipeline.ptr, label);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    layout: PipelineLayout,
    compute: ProgrammableStageDescriptor,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = Descriptor;
}
