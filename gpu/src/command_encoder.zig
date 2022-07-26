const ChainedStruct = @import("types.zig").ChainedStruct;

pub const CommandEncoder = *opaque {
    // TODO
    // pub inline fn commandEncoderBeginComputePass(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) gpu.ComputePassEncoder {

    // TODO
    // pub inline fn commandEncoderBeginRenderPass(command_encoder: gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) gpu.RenderPassEncoder {

    // TODO
    // pub inline fn commandEncoderClearBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, offset: u64, size: u64) void {

    // TODO
    // pub inline fn commandEncoderCopyBufferToBuffer(command_encoder: gpu.CommandEncoder, source: gpu.Buffer, source_offset: u64, destination: gpu.Buffer, destination_offset: u64, size: u64) void {

    // TODO
    // pub inline fn commandEncoderCopyBufferToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {

    // TODO
    // pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {

    // TODO
    // pub inline fn commandEncoderCopyTextureToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {

    // Note: the only difference between this and the non-internal variant is that this one checks
    // internal usage.
    // TODO
    // pub inline fn commandEncoderCopyTextureToTextureInternal(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {

    // TODO
    // pub inline fn commandEncoderFinish(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.CommandBufferDescriptor) gpu.CommandBuffer {

    // TODO
    // pub inline fn commandEncoderInjectValidationError(command_encoder: gpu.CommandEncoder, message: [*:0]const u8) void {

    // TODO
    // pub inline fn commandEncoderInsertDebugMarker(command_encoder: gpu.CommandEncoder, marker_label: [*:0]const u8) void {

    // TODO
    // pub inline fn commandEncoderPopDebugGroup(command_encoder: gpu.CommandEncoder) void {

    // TODO
    // pub inline fn commandEncoderPushDebugGroup(command_encoder: gpu.CommandEncoder, group_label: [*:0]const u8) void {

    // TODO
    // pub inline fn commandEncoderResolveQuerySet(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, first_query: u32, query_count: u32, destination: gpu.Buffer, destination_offset: u64) void {

    // TODO
    // pub inline fn commandEncoderSetLabel(command_encoder: gpu.CommandEncoder, label: [*:0]const u8) void {

    // TODO
    // pub inline fn commandEncoderWriteBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {

    // TODO
    // pub inline fn commandEncoderWriteTimestamp(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, query_index: u32) void {

    // TODO
    // pub inline fn commandEncoderReference(command_encoder: gpu.CommandEncoder) void {

    // TODO
    // pub inline fn commandEncoderRelease(command_encoder: gpu.CommandEncoder) void {
};

pub const CommandEncoderDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
