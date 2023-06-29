const std = @import("std");
const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
const Buffer = @import("buffer.zig").Buffer;
const Texture = @import("texture.zig").Texture;
const ImageCopyTexture = @import("main.zig").ImageCopyTexture;
const ImageCopyExternalTexture = @import("main.zig").ImageCopyExternalTexture;
const ChainedStruct = @import("main.zig").ChainedStruct;
const Extent3D = @import("main.zig").Extent3D;
const CopyTextureForBrowserOptions = @import("main.zig").CopyTextureForBrowserOptions;
const Impl = @import("interface.zig").Impl;

pub const Queue = opaque {
    pub const WorkDoneCallback = *const fn (
        status: WorkDoneStatus,
        userdata: ?*anyopaque,
    ) callconv(.C) void;

    pub const WorkDoneStatus = enum(u32) {
        success = 0x00000000,
        err = 0x00000001,
        unknown = 0x00000002,
        device_lost = 0x00000003,
    };

    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
    };

    pub inline fn copyExternalTextureForBrowser(queue: *Queue, source: *const ImageCopyExternalTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D, options: *const CopyTextureForBrowserOptions) void {
        Impl.queueCopyExternalTextureForBrowser(queue, source, destination, copy_size, options);
    }

    pub inline fn copyTextureForBrowser(queue: *Queue, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D, options: *const CopyTextureForBrowserOptions) void {
        Impl.queueCopyTextureForBrowser(queue, source, destination, copy_size, options);
    }

    // TODO: dawn: does not allow unsetting this callback to null
    pub inline fn onSubmittedWorkDone(
        queue: *Queue,
        signal_value: u64,
        context: anytype,
        comptime callback: fn (ctx: @TypeOf(context), status: WorkDoneStatus) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn cCallback(status: WorkDoneStatus, userdata: ?*anyopaque) callconv(.C) void {
                callback(if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))), status);
            }
        };
        Impl.queueOnSubmittedWorkDone(queue, signal_value, Helper.cCallback, if (Context == void) null else context);
    }

    pub inline fn setLabel(queue: *Queue, label: [*:0]const u8) void {
        Impl.queueSetLabel(queue, label);
    }

    pub inline fn submit(queue: *Queue, commands: []const *const CommandBuffer) void {
        Impl.queueSubmit(queue, commands.len, commands.ptr);
    }

    pub inline fn writeBuffer(
        queue: *Queue,
        buffer: *Buffer,
        buffer_offset_bytes: u64,
        data_slice: anytype,
    ) void {
        Impl.queueWriteBuffer(
            queue,
            buffer,
            buffer_offset_bytes,
            @as(*const anyopaque, @ptrCast(std.mem.sliceAsBytes(data_slice).ptr)),
            data_slice.len * @sizeOf(std.meta.Elem(@TypeOf(data_slice))),
        );
    }

    pub inline fn writeTexture(
        queue: *Queue,
        destination: *const ImageCopyTexture,
        data_layout: *const Texture.DataLayout,
        write_size: *const Extent3D,
        data_slice: anytype,
    ) void {
        Impl.queueWriteTexture(
            queue,
            destination,
            @as(*const anyopaque, @ptrCast(std.mem.sliceAsBytes(data_slice).ptr)),
            @as(usize, @intCast(data_slice.len)) * @sizeOf(std.meta.Elem(@TypeOf(data_slice))),
            data_layout,
            write_size,
        );
    }

    pub inline fn reference(queue: *Queue) void {
        Impl.queueReference(queue);
    }

    pub inline fn release(queue: *Queue) void {
        Impl.queueRelease(queue);
    }
};
