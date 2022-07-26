const ChainedStruct = @import("types.zig").ChainedStruct;

pub const Queue = *opaque {
    // TODO
    // pub inline fn queueCopyTextureForBrowser(queue: gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {

    // TODO
    // pub inline fn queueOnSubmittedWorkDone(queue: gpu.Queue, signal_value: u64, callback: gpu.QueueWorkDoneCallback, userdata: *anyopaque) void {

    // TODO
    // pub inline fn queueSetLabel(queue: gpu.Queue, label: [*:0]const u8) void {

    // TODO
    // pub inline fn queueSubmit(queue: gpu.Queue, command_count: u32, commands: [*]gpu.CommandBuffer) void {

    // TODO
    // pub inline fn queueWriteBuffer(queue: gpu.Queue, buffer: gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {

    // TODO
    // pub inline fn queueWriteTexture(queue: gpu.Queue, data: *anyopaque, data_size: usize, data_layout: *const gpu.TextureDataLayout, write_size: *const gpu.Extent3D) void {

    // TODO
    // pub inline fn queueReference(queue: gpu.Queue) void {

    // TODO
    // pub inline fn queueRelease(queue: gpu.Queue) void {
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
