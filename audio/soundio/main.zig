pub usingnamespace @import("enums.zig");
pub const c = @import("c.zig");
pub const SoundIo = @import("SoundIo.zig");
pub const Device = @import("Device.zig");
pub const OutStream = @import("OutStream.zig");
pub const Error = @import("error.zig").Error;

test {
    refAllDecls(@import("SoundIo.zig"));
    refAllDecls(@import("Device.zig"));
    refAllDecls(@import("OutStream.zig"));
    refAllDecls(@import("ChannelLayout.zig"));
}

fn refAllDecls(comptime T: type) void {
    @setEvalBranchQuota(10000);
    inline for (comptime @import("std").meta.declarations(T)) |decl| {
        if (decl.is_pub) {
            if (@TypeOf(@field(T, decl.name)) == type) {
                switch (@typeInfo(@field(T, decl.name))) {
                    .Struct, .Enum, .Union, .Opaque => refAllDecls(@field(T, decl.name)),
                    else => {},
                }
            }
            _ = @field(T, decl.name);
        }
    }
}
