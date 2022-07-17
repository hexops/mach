pub usingnamespace @import("freetype.zig");
pub usingnamespace @import("types.zig");
pub usingnamespace @import("image.zig");
pub usingnamespace @import("color.zig");
pub usingnamespace @import("lcdfilter.zig");
pub const c = @import("c");
pub const Glyph = @import("Glyph.zig");
pub const Stroker = @import("Stroker.zig");
pub const Error = @import("error.zig").Error;

const std = @import("std");

test {
    std.testing.refAllDeclsRecursive(@import("freetype.zig"));
    std.testing.refAllDeclsRecursive(@import("types.zig"));
    std.testing.refAllDeclsRecursive(@import("image.zig"));
    std.testing.refAllDeclsRecursive(@import("color.zig"));
    std.testing.refAllDeclsRecursive(@import("lcdfilter.zig"));
    std.testing.refAllDeclsRecursive(@import("error.zig"));
    std.testing.refAllDeclsRecursive(Glyph);
    std.testing.refAllDeclsRecursive(Stroker);
}
