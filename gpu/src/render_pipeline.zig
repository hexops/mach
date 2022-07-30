const ChainedStruct = @import("types.zig").ChainedStruct;
const DepthStencilState = @import("types.zig").DepthStencilState;
const MultisampleState = @import("types.zig").MultisampleState;
const VertexState = @import("types.zig").VertexState;
const PrimitiveState = @import("types.zig").PrimitiveState;
const FragmentState = @import("types.zig").FragmentState;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const Impl = @import("interface.zig").Impl;

pub const RenderPipeline = opaque {
    pub inline fn getBindGroupLayout(render_pipeline: *RenderPipeline, group_index: u32) *BindGroupLayout {
        return Impl.renderPipelineGetBindGroupLayout(render_pipeline, group_index);
    }

    pub inline fn setLabel(render_pipeline: *RenderPipeline, label: [*:0]const u8) void {
        Impl.renderPipelineSetLabel(render_pipeline, label);
    }

    pub inline fn reference(render_pipeline: *RenderPipeline) void {
        Impl.renderPipelineReference(render_pipeline);
    }

    pub inline fn release(render_pipeline: *RenderPipeline) void {
        Impl.renderPipelineRelease(render_pipeline);
    }
};

pub const RenderPipelineDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: ?[*:0]const u8 = null,
    layout: ?PipelineLayout,
    vertex: VertexState,
    primitive: PrimitiveState,
    depth_stencil: ?*const DepthStencilState,
    multisample: MultisampleState,
    fragment: ?*const FragmentState,
};
