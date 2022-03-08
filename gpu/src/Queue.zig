const CommandBuffer = @import("CommandBuffer.zig");

const Queue = @This();

/// The type erased pointer to the Queue implementation
/// Equal to c.WGPUQueue for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // copyTextureForBrowser: fn (ptr: *anyopaque, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D, options: *const CopyTextureForBrowserOptions) void,
    // WGPU_EXPORT void wgpuQueueOnSubmittedWorkDone(WGPUQueue queue, uint64_t signalValue, WGPUQueueWorkDoneCallback callback, void * userdata);
    submit: fn (ptr: *anyopaque, command_count: u32, commands: *const CommandBuffer) void,
    // TODO:
    // queueWriteBuffer: fn (ptr: *anyopaque, buffer: Buffer, buffer_offset: u64, data: *const anyopaque, size: usize);
    // queueWriteTexture: fn (ptr: *anyopaque, destination: *const ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const TextureDataLayout, write_size: *const Extent3D);
};

pub inline fn reference(queue: Queue) void {
    queue.vtable.reference(queue.ptr);
}

pub inline fn release(queue: Queue) void {
    queue.vtable.release(queue.ptr);
}

pub inline fn submit(queue: Queue, command_count: u32, commands: *const CommandBuffer) void {
    queue.vtable.submit(queue.ptr, command_count, commands);
}

// TODO:
// typedef void (*WGPUQueueWorkDoneCallback)(WGPUQueueWorkDoneStatus status, void * userdata);

// TODO:
// typedef enum WGPUQueueWorkDoneStatus {
//     WGPUQueueWorkDoneStatus_Success = 0x00000000,
//     WGPUQueueWorkDoneStatus_Error = 0x00000001,
//     WGPUQueueWorkDoneStatus_Unknown = 0x00000002,
//     WGPUQueueWorkDoneStatus_DeviceLost = 0x00000003,
//     WGPUQueueWorkDoneStatus_Force32 = 0x7FFFFFFF
// } WGPUQueueWorkDoneStatus;

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = submit;
}
