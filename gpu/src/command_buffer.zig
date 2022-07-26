const ChainedStruct = @import("types.zig").ChainedStruct;

pub const CommandBuffer = *opaque {
    // TODO
    // pub inline fn commandBufferSetLabel(command_buffer: gpu.CommandBuffer, label: [*:0]const u8) void {

    // TODO
    // pub inline fn commandBufferReference(command_buffer: gpu.CommandBuffer) void {

    // TODO
    // pub inline fn commandBufferRelease(command_buffer: gpu.CommandBuffer) void {
};

pub const CommandBufferDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
