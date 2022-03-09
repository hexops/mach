const RenderPipeline = @This();

/// The type erased pointer to the RenderPipeline implementation
/// Equal to c.WGPURenderPipeline for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT WGPUBindGroupLayout wgpuRenderPipelineGetBindGroupLayout(WGPURenderPipeline renderPipeline, uint32_t groupIndex);
    // WGPU_EXPORT void wgpuRenderPipelineSetLabel(WGPURenderPipeline renderPipeline, char const * label);
};

pub inline fn reference(pipeline: RenderPipeline) void {
    pipeline.vtable.reference(pipeline.ptr);
}

pub inline fn release(pipeline: RenderPipeline) void {
    pipeline.vtable.release(pipeline.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
