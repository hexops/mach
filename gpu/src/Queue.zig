const CommandBuffer = @import("CommandBuffer.zig");

const Queue = @This();

on_submitted_work_done: ?OnSubmittedWorkDone = null,

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

pub const OnSubmittedWorkDone = struct {
    userdata: *anyopaque,
    callback: fn (status: WorkDoneStatus, userdata: *anyopaque) void,

    fn init(comptime Context: type, userdata: *Context, comptime callback: fn (status: WorkDoneStatus, userdata: *Context) void) OnSubmittedWorkDone {
        return .{
            .userdata = userdata,
            .callback = (struct {
                pub inline fn untyped(status: WorkDoneStatus, _userdata: *anyopaque) void {
                    callback(status, @ptrCast(*Context, @alignCast(@alignOf(*Context), _userdata)));
                }
            }).untyped,
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

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = submit;
    _ = OnSubmittedWorkDone;
    _ = WorkDoneStatus;
}
