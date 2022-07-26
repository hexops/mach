const ChainedStruct = @import("types.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;

pub const PipelineLayout = *opaque {
    // TODO
    // pub inline fn pipelineLayoutSetLabel(pipeline_layout: gpu.PipelineLayout, label: [*:0]const u8) void {

    // TODO
    // pub inline fn pipelineLayoutReference(pipeline_layout: gpu.PipelineLayout) void {

    // TODO
    // pub inline fn pipelineLayoutRelease(pipeline_layout: gpu.PipelineLayout) void {
};

pub const PipelineLayoutDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    bind_group_layout_count: u32,
    bind_group_layouts: [*]const BindGroupLayout,
};
