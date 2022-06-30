const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;

const ChannelLayout = @This();

handle: c.SoundIoChannelLayout,

pub fn channelCount(self: ChannelLayout) i32 {
    return self.handle.channel_count;
}
