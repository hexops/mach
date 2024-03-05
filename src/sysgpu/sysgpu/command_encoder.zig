const std = @import("std");
const ComputePassEncoder = @import("compute_pass_encoder.zig").ComputePassEncoder;
const RenderPassEncoder = @import("render_pass_encoder.zig").RenderPassEncoder;
const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
const Buffer = @import("buffer.zig").Buffer;
const QuerySet = @import("query_set.zig").QuerySet;
const RenderPassDescriptor = @import("main.zig").RenderPassDescriptor;
const ComputePassDescriptor = @import("main.zig").ComputePassDescriptor;
const ChainedStruct = @import("main.zig").ChainedStruct;
const ImageCopyBuffer = @import("main.zig").ImageCopyBuffer;
const ImageCopyTexture = @import("main.zig").ImageCopyTexture;
const Extent3D = @import("main.zig").Extent3D;
const Impl = @import("interface.zig").Impl;
const dawn = @import("dawn.zig");

pub const CommandEncoder = opaque {
    pub const Descriptor = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            dawn_encoder_internal_usage_descriptor: *const dawn.EncoderInternalUsageDescriptor,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        label: ?[*:0]const u8 = null,
    };

    pub inline fn beginComputePass(command_encoder: *CommandEncoder, descriptor: ?*const ComputePassDescriptor) *ComputePassEncoder {
        return Impl.commandEncoderBeginComputePass(command_encoder, descriptor);
    }

    pub inline fn beginRenderPass(command_encoder: *CommandEncoder, descriptor: *const RenderPassDescriptor) *RenderPassEncoder {
        return Impl.commandEncoderBeginRenderPass(command_encoder, descriptor);
    }

    /// Default `offset`: 0
    /// Default `size`: `gpu.whole_size`
    pub inline fn clearBuffer(command_encoder: *CommandEncoder, buffer: *Buffer, offset: u64, size: u64) void {
        Impl.commandEncoderClearBuffer(command_encoder, buffer, offset, size);
    }

    pub inline fn copyBufferToBuffer(command_encoder: *CommandEncoder, source: *Buffer, source_offset: u64, destination: *Buffer, destination_offset: u64, size: u64) void {
        Impl.commandEncoderCopyBufferToBuffer(command_encoder, source, source_offset, destination, destination_offset, size);
    }

    pub inline fn copyBufferToTexture(command_encoder: *CommandEncoder, source: *const ImageCopyBuffer, destination: *const ImageCopyTexture, copy_size: *const Extent3D) void {
        Impl.commandEncoderCopyBufferToTexture(command_encoder, source, destination, copy_size);
    }

    pub inline fn copyTextureToBuffer(command_encoder: *CommandEncoder, source: *const ImageCopyTexture, destination: *const ImageCopyBuffer, copy_size: *const Extent3D) void {
        Impl.commandEncoderCopyTextureToBuffer(command_encoder, source, destination, copy_size);
    }

    pub inline fn copyTextureToTexture(command_encoder: *CommandEncoder, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D) void {
        Impl.commandEncoderCopyTextureToTexture(command_encoder, source, destination, copy_size);
    }

    pub inline fn finish(command_encoder: *CommandEncoder, descriptor: ?*const CommandBuffer.Descriptor) *CommandBuffer {
        return Impl.commandEncoderFinish(command_encoder, descriptor);
    }

    pub inline fn injectValidationError(command_encoder: *CommandEncoder, message: [*:0]const u8) void {
        Impl.commandEncoderInjectValidationError(command_encoder, message);
    }

    pub inline fn insertDebugMarker(command_encoder: *CommandEncoder, marker_label: [*:0]const u8) void {
        Impl.commandEncoderInsertDebugMarker(command_encoder, marker_label);
    }

    pub inline fn popDebugGroup(command_encoder: *CommandEncoder) void {
        Impl.commandEncoderPopDebugGroup(command_encoder);
    }

    pub inline fn pushDebugGroup(command_encoder: *CommandEncoder, group_label: [*:0]const u8) void {
        Impl.commandEncoderPushDebugGroup(command_encoder, group_label);
    }

    pub inline fn resolveQuerySet(command_encoder: *CommandEncoder, query_set: *QuerySet, first_query: u32, query_count: u32, destination: *Buffer, destination_offset: u64) void {
        Impl.commandEncoderResolveQuerySet(command_encoder, query_set, first_query, query_count, destination, destination_offset);
    }

    pub inline fn setLabel(command_encoder: *CommandEncoder, label: [*:0]const u8) void {
        Impl.commandEncoderSetLabel(command_encoder, label);
    }

    pub inline fn writeBuffer(
        command_encoder: *CommandEncoder,
        buffer: *Buffer,
        buffer_offset_bytes: u64,
        data_slice: anytype,
    ) void {
        Impl.commandEncoderWriteBuffer(
            command_encoder,
            buffer,
            buffer_offset_bytes,
            @as([*]const u8, @ptrCast(std.mem.sliceAsBytes(data_slice).ptr)),
            @as(u64, @intCast(data_slice.len)) * @sizeOf(std.meta.Elem(@TypeOf(data_slice))),
        );
    }

    pub inline fn writeTimestamp(command_encoder: *CommandEncoder, query_set: *QuerySet, query_index: u32) void {
        Impl.commandEncoderWriteTimestamp(command_encoder, query_set, query_index);
    }

    pub inline fn reference(command_encoder: *CommandEncoder) void {
        Impl.commandEncoderReference(command_encoder);
    }

    pub inline fn release(command_encoder: *CommandEncoder) void {
        Impl.commandEncoderRelease(command_encoder);
    }
};
