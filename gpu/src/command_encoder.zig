const ComputePassEncoder = @import("compute_pass_encoder.zig").ComputePassEncoder;
const RenderPassEncoder = @import("render_pass_encoder.zig").RenderPassEncoder;
const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
const CommandBufferDescriptor = @import("command_buffer.zig").CommandBufferDescriptor;
const Buffer = @import("buffer.zig").Buffer;
const QuerySet = @import("query_set.zig").QuerySet;
const RenderPassDescriptor = @import("main.zig").RenderPassDescriptor;
const ComputePassDescriptor = @import("main.zig").ComputePassDescriptor;
const ChainedStruct = @import("types.zig").ChainedStruct;
const ImageCopyBuffer = @import("types.zig").ImageCopyBuffer;
const ImageCopyTexture = @import("types.zig").ImageCopyTexture;
const Extent3D = @import("types.zig").Extent3D;
const impl = @import("interface.zig").impl;

pub const CommandEncoder = *opaque {
    pub inline fn beginComputePass(command_encoder: CommandEncoder, descriptor: ?*const ComputePassDescriptor) ComputePassEncoder {
        return impl.commandEncoderBeginComputePass(command_encoder, descriptor);
    }

    pub inline fn beginRenderPass(command_encoder: CommandEncoder, descriptor: *const RenderPassDescriptor) RenderPassEncoder {
        return impl.commandEncoderBeginRenderPass(command_encoder, descriptor);
    }

    pub inline fn clearBuffer(command_encoder: CommandEncoder, buffer: Buffer, offset: u64, size: u64) void {
        impl.commandEncoderClearBuffer(command_encoder, buffer, offset, size);
    }

    pub inline fn copyBufferToBuffer(command_encoder: CommandEncoder, source: Buffer, source_offset: u64, destination: Buffer, destination_offset: u64, size: u64) void {
        impl.commandEncoderCopyBufferToBuffer(command_encoder, source, source_offset, destination, destination_offset, size);
    }

    pub inline fn copyBufferToTexture(command_encoder: CommandEncoder, source: *const ImageCopyBuffer, destination: *const ImageCopyTexture, copy_size: *const Extent3D) void {
        impl.commandEncoderCopyBufferToTexture(command_encoder, source, destination, copy_size);
    }

    pub inline fn copyTextureToBuffer(command_encoder: CommandEncoder, source: *const ImageCopyTexture, destination: *const ImageCopyBuffer, copy_size: *const Extent3D) void {
        impl.commandEncoderCopyTextureToBuffer(command_encoder, source, destination, copy_size);
    }

    pub inline fn copyTextureToTexture(command_encoder: CommandEncoder, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D) void {
        impl.commandEncoderCopyTextureToTexture(command_encoder, source, destination, copy_size);
    }

    // Note: the only difference between this and the non-internal variant is that this one checks
    // internal usage.
    pub inline fn copyTextureToTextureInternal(command_encoder: CommandEncoder, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D) void {
        impl.commandEncoderCopyTextureToTextureInternal(command_encoder, source, destination, copy_size);
    }

    pub inline fn finish(command_encoder: CommandEncoder, descriptor: ?*const CommandBufferDescriptor) CommandBuffer {
        return impl.commandEncoderFinish(command_encoder, descriptor);
    }

    pub inline fn injectValidationError(command_encoder: CommandEncoder, message: [*:0]const u8) void {
        impl.commandEncoderInjectValidationError(command_encoder, message);
    }

    pub inline fn insertDebugMarker(command_encoder: CommandEncoder, marker_label: [*:0]const u8) void {
        impl.commandEncoderInsertDebugMarker(command_encoder, marker_label);
    }

    pub inline fn popDebugGroup(command_encoder: CommandEncoder) void {
        impl.commandEncoderPopDebugGroup(command_encoder);
    }

    pub inline fn pushDebugGroup(command_encoder: CommandEncoder, group_label: [*:0]const u8) void {
        impl.commandEncoderPushDebugGroup(command_encoder, group_label);
    }

    pub inline fn resolveQuerySet(command_encoder: CommandEncoder, query_set: QuerySet, first_query: u32, query_count: u32, destination: Buffer, destination_offset: u64) void {
        impl.commandEncoderResolveQuerySet(command_encoder, query_set, first_query, query_count, destination, destination_offset);
    }

    pub inline fn setLabel(command_encoder: CommandEncoder, label: [*:0]const u8) void {
        impl.commandEncoderSetLabel(command_encoder, label);
    }

    pub inline fn writeBuffer(command_encoder: CommandEncoder, buffer: Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
        impl.commandEncoderWriteBuffer(command_encoder, buffer, buffer_offset, data, size);
    }

    pub inline fn writeTimestamp(command_encoder: CommandEncoder, query_set: QuerySet, query_index: u32) void {
        impl.commandEncoderWriteTimestamp(command_encoder, query_set, query_index);
    }

    pub inline fn reference(command_encoder: CommandEncoder) void {
        impl.commandEncoderReference(command_encoder);
    }

    pub inline fn release(command_encoder: CommandEncoder) void {
        impl.commandEncoderRelease(command_encoder);
    }
};

pub const CommandEncoderDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
