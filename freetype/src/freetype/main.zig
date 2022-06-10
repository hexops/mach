pub usingnamespace @import("freetype.zig");
pub usingnamespace @import("types.zig");
pub usingnamespace @import("image.zig");
pub usingnamespace @import("color.zig");
pub usingnamespace @import("lcdfilter.zig");
pub const c = @import("c.zig");
pub const Glyph = @import("Glyph.zig");
pub const Stroker = @import("Stroker.zig");
pub const Error = @import("error.zig").Error;

const utils = @import("utils");

test {
    utils.refAllDecls(@import("freetype.zig"));
    utils.refAllDecls(@import("types.zig"));
    utils.refAllDecls(@import("image.zig"));
    utils.refAllDecls(@import("color.zig"));
    utils.refAllDecls(@import("lcdfilter.zig"));
    utils.refAllDecls(@import("error.zig"));
    utils.refAllDecls(Glyph);
    utils.refAllDecls(Stroker);
}
