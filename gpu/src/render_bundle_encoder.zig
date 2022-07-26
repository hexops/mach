const ChainedStruct = @import("types.zig").ChainedStruct;
const Texture = @import("texture.zig").Texture;
const TextureFormat = @import("texture.zig").TextureFormat;

pub const RenderBundleEncoder = *opaque {
    // TODO
    // pub inline fn renderBundleEncoderDraw(render_bundle_encoder: gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {

    // TODO
    // pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) void {

    // TODO
    // pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {

    // TODO
    // pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {

    // TODO
    // pub inline fn renderBundleEncoderFinish(render_bundle_encoder: gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundleDescriptor) void {

    // TODO
    // pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {

    // TODO
    // pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder) void {

    // TODO
    // pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {

    // TODO
    // pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {

    // TODO
    // pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {

    // TODO
    // pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: gpu.RenderBundleEncoder, label: [*:0]const u8) void {

    // TODO
    // pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: gpu.RenderBundleEncoder, pipeline: gpu.RenderPipeline) void {

    // TODO
    // pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) void {

    // TODO
    // pub inline fn renderBundleEncoderReference(render_bundle_encoder: gpu.RenderBundleEncoder) void {

    // TODO
    // pub inline fn renderBundleEncoderRelease(render_bundle_encoder: gpu.RenderBundleEncoder) void {
};

pub const RenderBundleEncoderDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    color_formats_count: u32,
    color_formats: [*]const TextureFormat,
    depth_stencil_format: TextureFormat,
    sample_count: u32,
    depth_read_only: bool,
    stencil_read_only: bool,
};
