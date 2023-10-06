pub const util = @import("util.zig"); // TODO: banish 2-level deep namespaces
pub const Atlas = @import("atlas/Atlas.zig");

// ECS modules
pub const Sprite = @import("Sprite.zig");
pub const Text = @import("Text.zig");

// Fonts
pub const Font = @import("font/main.zig").Font;
pub const TextRun = @import("font/main.zig").TextRun;
pub const Glyph = @import("font/main.zig").Glyph;

test {
    const std = @import("std");
    // TODO: refactor code so we can use this here:
    // std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(util);
    // std.testing.refAllDeclsRecursive(Sprite);
    std.testing.refAllDeclsRecursive(Atlas);
    // std.testing.refAllDeclsRecursive(Text);
    std.testing.refAllDeclsRecursive(Font);
    std.testing.refAllDeclsRecursive(TextRun);
    std.testing.refAllDeclsRecursive(Glyph);
}
