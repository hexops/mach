const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
const Buffer = @import("buffer.zig").Buffer;
const TextureDataLayout = @import("texture.zig").TextureDataLayout;
const ImageCopyTexture = @import("types.zig").ImageCopyTexture;
const ChainedStruct = @import("types.zig").ChainedStruct;
const Extent3D = @import("types.zig").Extent3D;
const CopyTextureForBrowserOptions = @import("types.zig").CopyTextureForBrowserOptions;
const impl = @import("interface.zig").impl;

pub const Queue = *opaque {
    pub inline fn copyTextureForBrowser(queue: Queue, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D, options: *const CopyTextureForBrowserOptions) void {
        impl.queueCopyTextureForBrowser(queue, source, destination, copy_size, options);
    }

    pub inline fn onSubmittedWorkDone(queue: Queue, signal_value: u64, callback: QueueWorkDoneCallback, userdata: *anyopaque) void {
        impl.queueOnSubmittedWorkDone(queue, signal_value, callback, userdata);
    }

    pub inline fn setLabel(queue: Queue, label: [*:0]const u8) void {
        impl.queueSetLabel(queue, label);
    }

    pub inline fn submit(queue: Queue, command_count: u32, commands: [*]CommandBuffer) void {
        impl.queueSubmit(queue, command_count, commands);
    }

    pub inline fn writeBuffer(queue: Queue, buffer: Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {
        impl.queueWriteBuffer(queue, buffer, buffer_offset, data, size);
    }

    pub inline fn writeTexture(queue: Queue, data: *anyopaque, data_size: usize, data_layout: *const TextureDataLayout, write_size: *const Extent3D) void {
        impl.queueWriteTexture(queue, data, data_size, data_layout, write_size);
    }

    pub inline fn reference(queue: Queue) void {
        impl.queueReference(queue);
    }

    pub inline fn release(queue: Queue) void {
        impl.queueRelease(queue);
    }
};

pub const QueueWorkDoneCallback = fn (
    status: QueueWorkDoneStatus,
    userdata: *anyopaque,
) callconv(.C) void;

pub const QueueWorkDoneStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    unknown = 0x00000002,
    device_lost = 0x00000003,
};

pub const QueueDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
