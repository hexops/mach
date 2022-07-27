const ChainedStruct = @import("types.zig").ChainedStruct;
const impl = @import("interface.zig").impl;

pub const CommandBuffer = *opaque {
    pub inline fn setLabel(command_buffer: CommandBuffer, label: [*:0]const u8) void {
        impl.commandBufferSetLabel(command_buffer, label);
    }

    pub inline fn reference(command_buffer: CommandBuffer) void {
        impl.commandBufferReference(command_buffer);
    }

    pub inline fn release(command_buffer: CommandBuffer) void {
        impl.commandBufferRelease(command_buffer);
    }
};

pub const CommandBufferDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
