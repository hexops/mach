const PipelineLayout = @import("PipelineLayout.zig");
const VertexState = @import("structs.zig").VertexState;
const PrimitiveState = @import("structs.zig").PrimitiveState;
const DepthStencilState = @import("structs.zig").DepthStencilState;
const MultisampleState = @import("structs.zig").MultisampleState;
const FragmentState = @import("structs.zig").FragmentState;

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
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(pipeline: RenderPipeline) void {
    pipeline.vtable.reference(pipeline.ptr);
}

pub inline fn release(pipeline: RenderPipeline) void {
    pipeline.vtable.release(pipeline.ptr);
}

pub inline fn setLabel(pipeline: RenderPipeline, label: [:0]const u8) void {
    pipeline.vtable.setLabel(pipeline.ptr, label);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    layout: PipelineLayout,
    vertex: VertexState,
    primitive: PrimitiveState,
    depth_stencil: *const DepthStencilState,
    multisample: MultisampleState,
    fragment: *const FragmentState,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = Descriptor;
}
