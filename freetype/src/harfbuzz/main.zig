pub usingnamespace @import("blob.zig");
pub usingnamespace @import("buffer.zig");
pub usingnamespace @import("common.zig");
pub usingnamespace @import("face.zig");
pub usingnamespace @import("font.zig");
pub usingnamespace @import("shape.zig");
pub usingnamespace @import("shape_plan.zig");
pub const c = @import("c.zig");

const utils = @import("utils");

test {
    utils.refAllDecls(@import("blob.zig"));
    utils.refAllDecls(@import("buffer.zig"));
    utils.refAllDecls(@import("common.zig"));
    utils.refAllDecls(@import("face.zig"));
    utils.refAllDecls(@import("font.zig"));
    utils.refAllDecls(@import("shape.zig"));
    utils.refAllDecls(@import("shape_plan.zig"));
}
