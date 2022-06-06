pub usingnamespace @import("freetype.zig");
pub usingnamespace @import("types.zig");
pub usingnamespace @import("image.zig");
pub usingnamespace @import("color.zig");
pub usingnamespace @import("lcdfilter.zig");
pub const c = @import("c.zig");
pub const Glyph = @import("Glyph.zig");
pub const Stroker = @import("Stroker.zig");
pub const Error = @import("error.zig").Error;

const std = @import("std");

fn refLiterallyAllDecls(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Struct, .Union, .Opaque, .Enum => {
            inline for (comptime std.meta.declarations(T)) |decl| {
                if (decl.is_pub) {
                    refLiterallyAllDecls(@TypeOf(@field(T, decl.name)));
                    std.testing.refAllDecls(T);
                }
            }
        },
        else => {},
    }
}

test {
    refLiterallyAllDecls(@This());
    refLiterallyAllDecls(@import("color.zig"));
    refLiterallyAllDecls(@import("error.zig"));
    refLiterallyAllDecls(@import("utils.zig"));
    refLiterallyAllDecls(@import("Face.zig"));
    refLiterallyAllDecls(@import("GlyphSlot.zig"));
    refLiterallyAllDecls(@import("Library.zig"));
    refLiterallyAllDecls(@import("Outline.zig"));
    refLiterallyAllDecls(Glyph);
    refLiterallyAllDecls(Stroker);
}
