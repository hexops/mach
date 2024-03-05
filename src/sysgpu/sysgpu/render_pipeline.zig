const ChainedStruct = @import("main.zig").ChainedStruct;
const DepthStencilState = @import("main.zig").DepthStencilState;
const MultisampleState = @import("main.zig").MultisampleState;
const VertexState = @import("main.zig").VertexState;
const PrimitiveState = @import("main.zig").PrimitiveState;
const FragmentState = @import("main.zig").FragmentState;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const Impl = @import("interface.zig").Impl;

pub const RenderPipeline = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        layout: ?*PipelineLayout = null,
        vertex: VertexState,
        primitive: PrimitiveState = .{},
        depth_stencil: ?*const DepthStencilState = null,
        multisample: MultisampleState = .{},
        fragment: ?*const FragmentState = null,
    };

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
