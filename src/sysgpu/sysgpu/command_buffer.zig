const ChainedStruct = @import("main.zig").ChainedStruct;
const Impl = @import("interface.zig").Impl;

pub const CommandBuffer = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
    };

    pub inline fn setLabel(command_buffer: *CommandBuffer, label: [*:0]const u8) void {
        Impl.commandBufferSetLabel(command_buffer, label);
    }

    pub inline fn reference(command_buffer: *CommandBuffer) void {
        Impl.commandBufferReference(command_buffer);
    }

    pub inline fn release(command_buffer: *CommandBuffer) void {
        Impl.commandBufferRelease(command_buffer);
    }
};
