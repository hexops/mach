pub usingnamespace @import("blob.zig");
pub usingnamespace @import("buffer.zig");
pub usingnamespace @import("common.zig");
pub const c = @import("c.zig");

const utils = @import("utils");

test {
    utils.refAllDecls(@import("blob.zig"));
    utils.refAllDecls(@import("buffer.zig"));
    utils.refAllDecls(@import("common.zig"));
}
