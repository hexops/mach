const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
const Buffer = @import("buffer.zig").Buffer;
const Texture = @import("texture.zig").Texture;
const ImageCopyTexture = @import("types.zig").ImageCopyTexture;
const ChainedStruct = @import("types.zig").ChainedStruct;
const Extent3D = @import("types.zig").Extent3D;
const CopyTextureForBrowserOptions = @import("types.zig").CopyTextureForBrowserOptions;
const Impl = @import("interface.zig").Impl;

pub const Queue = opaque {
    pub const WorkDoneCallback = fn (
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

    pub inline fn copyTextureForBrowser(queue: *Queue, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: *const Extent3D, options: *const CopyTextureForBrowserOptions) void {
        Impl.queueCopyTextureForBrowser(queue, source, destination, copy_size, options);
    }

    // TODO: is it not possible to *unset* this callback? Presumably it should be nullable?
    pub inline fn onSubmittedWorkDone(
        queue: *Queue,
        signal_value: u64,
        context: anytype,
        comptime callback: fn (status: WorkDoneStatus, ctx: @TypeOf(context)) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn callback(status: WorkDoneStatus, userdata: ?*anyopaque) callconv(.C) void {
                callback(status, if (Context == void) {} else @ptrCast(Context, @alignCast(@alignOf(Context), userdata)));
            }
        };
        Impl.queueOnSubmittedWorkDone(queue, signal_value, Helper.callback, if (Context == void) null else context);
    }

    pub inline fn setLabel(queue: *Queue, label: [*:0]const u8) void {
        Impl.queueSetLabel(queue, label);
    }

    pub inline fn submit(queue: *Queue, commands: []*const CommandBuffer) void {
        Impl.queueSubmit(queue, @intCast(u32, commands.len), commands.ptr);
    }

    pub inline fn writeBuffer(queue: *Queue, buffer: *Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {
        Impl.queueWriteBuffer(queue, buffer, buffer_offset, data, size);
    }

    pub inline fn writeTexture(
        queue: *Queue,
        destination: *const ImageCopyTexture,
        data_layout: *const Texture.DataLayout,
        write_size: *const Extent3D,
        comptime T: type,
        data: []const T,
    ) void {
        Impl.queueWriteTexture(
            queue,
            destination,
            @ptrCast(*const anyopaque, data.ptr),
            @intCast(usize, data.len) * @sizeOf(std.meta.Elem(@TypeOf(data))),
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
