const CommandBuffer = @import("CommandBuffer.zig");

const Queue = @This();

on_submitted_work_done: ?WorkDoneCallback = null,

/// The type erased pointer to the Queue implementation
/// Equal to c.WGPUQueue for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO: dawn specific?
    // copyTextureForBrowser: fn (ptr: *anyopaque, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D, options: *const CopyTextureForBrowserOptions) void,
    submit: fn (queue: Queue, commands: []const CommandBuffer) void,
    // TODO:
    // writeBuffer: fn (ptr: *anyopaque, buffer: Buffer, buffer_offset: u64, data: *const anyopaque, size: usize);
    // writeTexture: fn (ptr: *anyopaque, destination: *const ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const TextureDataLayout, write_size: *const Extent3D);
};

pub inline fn reference(queue: Queue) void {
    queue.vtable.reference(queue.ptr);
}

pub inline fn release(queue: Queue) void {
    queue.vtable.release(queue.ptr);
}

pub inline fn submit(queue: Queue, commands: []const CommandBuffer) void {
    queue.vtable.submit(queue, commands);
}

pub const WorkDoneCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (ctx: *anyopaque, status: WorkDoneStatus) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: *Context,
        comptime callback: fn (ctx: *Context, status: WorkDoneStatus) void,
    ) WorkDoneCallback {
        const erased = (struct {
            pub inline fn erased(type_erased_ctx: *anyopaque, status: WorkDoneStatus) void {
                callback(@ptrCast(*Context, @alignCast(@alignOf(*Context), type_erased_ctx)), status);
            }
        }).erased;

        return .{
            .type_erased_ctx = ctx,
            .type_erased_callback = erased,
        };
    }
};

pub const WorkDoneStatus = enum(u32) {
    Success = 0x00000000,
    Error = 0x00000001,
    Unknown = 0x00000002,
    DeviceLost = 0x00000003,
    Force32 = 0x7FFFFFFF,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = submit;
    _ = WorkDoneCallback;
    _ = WorkDoneStatus;
}
