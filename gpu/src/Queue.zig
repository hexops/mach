const std = @import("std");

const ImageCopyTexture = @import("structs.zig").ImageCopyTexture;
const Extent3D = @import("data.zig").Extent3D;
const CommandBuffer = @import("CommandBuffer.zig");
const Buffer = @import("Buffer.zig");
const Texture = @import("Texture.zig");

const Queue = @This();

/// Callback to executed when all work has been done
/// This field must be set before calling `submit()` on the commands the callback waits for.
/// Note that the address stored must be valid when the callback is executed.
on_submitted_work_done: ?*WorkDoneCallback = null,

/// The type erased pointer to the Queue implementation
/// Equal to c.WGPUQueue for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO: dawn specific?
    // copyTextureForBrowser: fn (ptr: *anyopaque, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D, options: *const CopyTextureForBrowserOptions) void,
    submit: fn (queue: *Queue, commands: []const CommandBuffer) void,
    writeBuffer: fn (
        ptr: *anyopaque,
        buffer: Buffer,
        buffer_offset: u64,
        data: *const anyopaque,
        size: u64,
    ) void,
    writeTexture: fn (
        ptr: *anyopaque,
        destination: *const ImageCopyTexture,
        data: *const anyopaque,
        data_size: usize,
        data_layout: *const Texture.DataLayout,
        write_size: *const Extent3D,
    ) void,
};

pub inline fn reference(queue: Queue) void {
    queue.vtable.reference(queue.ptr);
}

pub inline fn release(queue: Queue) void {
    queue.vtable.release(queue.ptr);
}

pub inline fn submit(queue: *Queue, commands: []const CommandBuffer) void {
    queue.vtable.submit(queue, commands);
}

pub inline fn writeBuffer(queue: Queue, buffer: Buffer, buffer_offset: u64, comptime T: type, data: []const T) void {
    queue.vtable.writeBuffer(
        queue.ptr,
        buffer,
        buffer_offset,
        @ptrCast(*const anyopaque, data.ptr),
        @intCast(u64, data.len) * @sizeOf(T),
    );
}

pub inline fn writeTexture(
    queue: Queue,
    destination: *const ImageCopyTexture,
    data_layout: *const Texture.DataLayout,
    write_size: *const Extent3D,
    comptime T: type,
    data: []const T,
) void {
    queue.vtable.writeTexture(
        queue.ptr,
        destination,
        @ptrCast(*const anyopaque, data.ptr),
        @intCast(usize, data.len) * @sizeOf(std.meta.Elem(@TypeOf(data))),
        data_layout,
        write_size,
    );
}

pub const WorkDoneCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (ctx: *anyopaque, status: WorkDoneStatus) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: Context,
        comptime callback: fn (ctx: Context, status: WorkDoneStatus) void,
    ) WorkDoneCallback {
        const erased = (struct {
            pub inline fn erased(type_erased_ctx: *anyopaque, status: WorkDoneStatus) void {
                callback(if (Context == void) {} else @ptrCast(Context, @alignCast(std.meta.alignment(Context), type_erased_ctx)), status);
            }
        }).erased;

        return .{
            .type_erased_ctx = if (Context == void) undefined else ctx,
            .type_erased_callback = erased,
        };
    }
};

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
};

pub const WorkDoneStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    unknown = 0x00000002,
    device_lost = 0x00000003,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = submit;
    _ = writeBuffer;
    _ = writeTexture;
    _ = WorkDoneCallback;
    _ = WorkDoneStatus;
}
