const ChainedStruct = @import("types.zig").ChainedStruct;
const DepthStencilState = @import("types.zig").DepthStencilState;
const MultisampleState = @import("types.zig").MultisampleState;
const VertexState = @import("types.zig").VertexState;
const PrimitiveState = @import("types.zig").PrimitiveState;
const FragmentState = @import("types.zig").FragmentState;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;

pub const RenderPipeline = *opaque {
    // TODO
    // pub inline fn renderPipelineGetBindGroupLayout(render_pipeline: gpu.RenderPipeline, group_index: u32) gpu.BindGroupLayout {

    // TODO
    // pub inline fn renderPipelineSetLabel(render_pipeline: gpu.RenderPipeline, label: [*:0]const u8) void {

    // TODO
    // pub inline fn renderPipelineReference(render_pipeline: gpu.RenderPipeline) void {

    // TODO
    // pub inline fn renderPipelineRelease(render_pipeline: gpu.RenderPipeline) void {
};

pub const RenderPipelineDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    layout: ?PipelineLayout,
    vertex: VertexState,
    primitive: PrimitiveState,
    depth_stencil: ?*const DepthStencilState = null, // nullable
    multisample: MultisampleState,
    fragment: ?*const FragmentState = null, // nullable
};
