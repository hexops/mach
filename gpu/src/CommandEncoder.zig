const std = @import("std");

const ComputePassEncoder = @import("ComputePassEncoder.zig");
const RenderPassEncoder = @import("RenderPassEncoder.zig");
const CommandBuffer = @import("CommandBuffer.zig");
const QuerySet = @import("QuerySet.zig");
const Buffer = @import("Buffer.zig");
const ImageCopyBuffer = @import("structs.zig").ImageCopyBuffer;
const ImageCopyTexture = @import("structs.zig").ImageCopyTexture;
const Extent3D = @import("data.zig").Extent3D;

const CommandEncoder = @This();

/// The type erased pointer to the CommandEncoder implementation
/// Equal to c.WGPUCommandEncoder for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    beginComputePass: fn (ptr: *anyopaque, descriptor: *const ComputePassEncoder.Descriptor) ComputePassEncoder,
    beginRenderPass: fn (ptr: *anyopaque, descriptor: *const RenderPassEncoder.Descriptor) RenderPassEncoder,
    clearBuffer: fn (ptr: *anyopaque, buffer: Buffer, offset: u64, size: u64) void,
    copyBufferToBuffer: fn (ptr: *anyopaque, source: Buffer, source_offset: u64, destination: Buffer, destination_offset: u64, size: u64) void,
    copyBufferToTexture: fn (ptr: *anyopaque, source: *const ImageCopyBuffer, destination: *const ImageCopyTexture, copy_size: *const Extent3D) void,
    copyTextureToBuffer: fn (ptr: *anyopaque, source: *const ImageCopyTexture, destination: *const ImageCopyBuffer, copy_size: *const Extent3D) void,
    copyTextureToTexture: fn (ptr: *anyopaque, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D) void,
    finish: fn (ptr: *anyopaque, descriptor: ?*const CommandBuffer.Descriptor) CommandBuffer,
    injectValidationError: fn (ptr: *anyopaque, message: [*:0]const u8) void,
    insertDebugMarker: fn (ptr: *anyopaque, marker_label: [*:0]const u8) void,
    popDebugGroup: fn (ptr: *anyopaque) void,
    pushDebugGroup: fn (ptr: *anyopaque, group_label: [*:0]const u8) void,
    resolveQuerySet: fn (ptr: *anyopaque, query_set: QuerySet, first_query: u32, query_count: u32, destination: Buffer, destination_offset: u64) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    writeBuffer: fn (ptr: *anyopaque, buffer: Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void,
    writeTimestamp: fn (ptr: *anyopaque, query_set: QuerySet, query_index: u32) void,
};

pub inline fn reference(enc: CommandEncoder) void {
    enc.vtable.reference(enc.ptr);
}

pub inline fn release(enc: CommandEncoder) void {
    enc.vtable.release(enc.ptr);
}

pub inline fn beginComputePass(enc: CommandEncoder, descriptor: *const ComputePassEncoder.Descriptor) ComputePassEncoder {
    return enc.vtable.beginComputePass(enc.ptr, descriptor);
}

pub inline fn beginRenderPass(enc: CommandEncoder, descriptor: *const RenderPassEncoder.Descriptor) RenderPassEncoder {
    return enc.vtable.beginRenderPass(enc.ptr, descriptor);
}

pub inline fn clearBuffer(enc: CommandEncoder, buffer: Buffer, offset: u64, size: u64) void {
    enc.vtable.clearBuffer(enc.ptr, buffer, offset, size);
}

pub inline fn copyBufferToBuffer(
    enc: CommandEncoder,
    source: Buffer,
    source_offset: u64,
    destination: Buffer,
    destination_offset: u64,
    size: u64,
) void {
    enc.vtable.copyBufferToBuffer(enc.ptr, source, source_offset, destination, destination_offset, size);
}

pub inline fn copyBufferToTexture(
    enc: CommandEncoder,
    source: *const ImageCopyBuffer,
    destination: *const ImageCopyTexture,
    copy_size: *const Extent3D,
) void {
    enc.vtable.copyBufferToTexture(enc.ptr, source, destination, copy_size);
}

pub inline fn copyTextureToBuffer(
    enc: CommandEncoder,
    source: *const ImageCopyTexture,
    destination: *const ImageCopyBuffer,
    copy_size: *const Extent3D,
) void {
    enc.vtable.copyTextureToBuffer(enc.ptr, source, destination, copy_size);
}

pub inline fn copyTextureToTexture(
    enc: CommandEncoder,
    source: *const ImageCopyTexture,
    destination: *const ImageCopyTexture,
    copy_size: *const Extent3D,
) void {
    enc.vtable.copyTextureToTexture(enc.ptr, source, destination, copy_size);
}

pub inline fn finish(enc: CommandEncoder, descriptor: ?*const CommandBuffer.Descriptor) CommandBuffer {
    return enc.vtable.finish(enc.ptr, descriptor);
}

pub inline fn injectValidationError(enc: CommandEncoder, message: [*:0]const u8) void {
    enc.vtable.injectValidationError(enc.ptr, message);
}

pub inline fn insertDebugMarker(enc: CommandEncoder, marker_label: [*:0]const u8) void {
    enc.vtable.insertDebugMarker(enc.ptr, marker_label);
}

pub inline fn popDebugGroup(enc: CommandEncoder) void {
    enc.vtable.popDebugGroup(enc.ptr);
}

pub inline fn pushDebugGroup(enc: CommandEncoder, group_label: [*:0]const u8) void {
    enc.vtable.pushDebugGroup(enc.ptr, group_label);
}

pub inline fn resolveQuerySet(
    enc: CommandEncoder,
    query_set: QuerySet,
    first_query: u32,
    query_count: u32,
    destination: Buffer,
    destination_offset: u64,
) void {
    enc.vtable.resolveQuerySet(enc.ptr, query_set, first_query, query_count, destination, destination_offset);
}

pub inline fn setLabel(enc: CommandEncoder, label: [:0]const u8) void {
    enc.vtable.setLabel(enc.ptr, label);
}

pub inline fn writeBuffer(enc: CommandEncoder, buffer: Buffer, buffer_offset: u64, comptime T: type, data: []const T) void {
    enc.vtable.writeBuffer(
        enc.ptr,
        buffer,
        buffer_offset,
        @ptrCast([*]const u8, data.ptr),
        @intCast(u64, data.len) * @sizeOf(T),
    );
}

pub inline fn writeTimestamp(pass: RenderPassEncoder, query_set: QuerySet, query_index: u32) void {
    pass.vtable.writeTimestamp(pass.ptr, query_set, query_index);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = beginComputePass;
    _ = beginRenderPass;
    _ = clearBuffer;
    _ = copyBufferToBuffer;
    _ = copyBufferToTexture;
    _ = copyTextureToBuffer;
    _ = copyTextureToTexture;
    _ = finish;
    _ = injectValidationError;
    _ = insertDebugMarker;
    _ = popDebugGroup;
    _ = pushDebugGroup;
    _ = resolveQuerySet;
    _ = setLabel;
    _ = writeBuffer;
    _ = writeTimestamp;
    _ = Descriptor;
}
