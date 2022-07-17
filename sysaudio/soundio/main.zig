pub usingnamespace @import("enums.zig");
pub const c = @import("c.zig");
pub const SoundIo = @import("SoundIo.zig");
pub const Device = @import("Device.zig");
pub const InStream = @import("InStream.zig");
pub const OutStream = @import("OutStream.zig");
pub const Error = @import("error.zig").Error;

const std = @import("std");

test {
    std.testing.refAllDeclsRecursive(@import("SoundIo.zig"));
    std.testing.refAllDeclsRecursive(@import("Device.zig"));
    std.testing.refAllDeclsRecursive(@import("OutStream.zig"));
    std.testing.refAllDeclsRecursive(@import("ChannelLayout.zig"));
}
