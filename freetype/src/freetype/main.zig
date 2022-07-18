pub usingnamespace @import("color.zig");
pub usingnamespace @import("freetype.zig");
pub usingnamespace @import("glyph.zig");
pub usingnamespace @import("image.zig");
pub usingnamespace @import("lcdfilter.zig");
pub usingnamespace @import("stroke.zig");
pub usingnamespace @import("types.zig");
pub const c = @import("c");
pub const Error = @import("error.zig").Error;

const std = @import("std");

test {
    std.testing.refAllDeclsRecursive(@import("color.zig"));
    std.testing.refAllDeclsRecursive(@import("error.zig"));
    std.testing.refAllDeclsRecursive(@import("freetype.zig"));
    std.testing.refAllDeclsRecursive(@import("glyph.zig"));
    std.testing.refAllDeclsRecursive(@import("image.zig"));
    std.testing.refAllDeclsRecursive(@import("lcdfilter.zig"));
    std.testing.refAllDeclsRecursive(@import("stroke.zig"));
    std.testing.refAllDeclsRecursive(@import("types.zig"));
}
