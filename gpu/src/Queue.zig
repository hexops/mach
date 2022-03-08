const CommandBuffer = @import("CommandBuffer.zig");

const Queue = @This();

/// The type erased pointer to the Queue implementation
/// Equal to c.WGPUQueue for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // WGPU_EXPORT void wgpuQueueCopyTextureForBrowser(WGPUQueue queue, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize, WGPUCopyTextureForBrowserOptions const * options);
    // WGPU_EXPORT void wgpuQueueOnSubmittedWorkDone(WGPUQueue queue, uint64_t signalValue, WGPUQueueWorkDoneCallback callback, void * userdata);
    submit: fn (ptr: *anyopaque, command_count: u32, commands: *const CommandBuffer) void,
    // WGPU_EXPORT void wgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size);
    // WGPU_EXPORT void wgpuQueueWriteTexture(WGPUQueue queue, WGPUImageCopyTexture const * destination, void const * data, size_t dataSize, WGPUTextureDataLayout const * dataLayout, WGPUExtent3D const * writeSize);
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

// typedef void (*WGPUQueueWorkDoneCallback)(WGPUQueueWorkDoneStatus status, void * userdata);

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
