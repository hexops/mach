pub const util = @import("util.zig");
pub const Sprite = @import("Sprite.zig");
pub const Text = @import("Text.zig");
pub const FontRenderer = @import("font.zig").FontRenderer;
pub const RGBA32 = @import("font.zig").RGBA32;
pub const Glyph = @import("font.zig").Glyph;
pub const GlyphMetrics = @import("font.zig").GlyphMetrics;

test {
    const std = @import("std");
    // TODO: refactor code so we can use this here:
    // std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(util);
    // std.testing.refAllDeclsRecursive(Sprite);
    // std.testing.refAllDeclsRecursive(Text);
    std.testing.refAllDeclsRecursive(FontRenderer);
    std.testing.refAllDeclsRecursive(RGBA32);
    std.testing.refAllDeclsRecursive(Glyph);
    std.testing.refAllDeclsRecursive(GlyphMetrics);
}
