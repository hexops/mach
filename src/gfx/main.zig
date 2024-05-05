pub const util = @import("util.zig"); // TODO: banish 2-level deep namespaces
pub const Atlas = @import("atlas/Atlas.zig");

// ECS modules
pub const Sprite = @import("Sprite.zig");
pub const SpritePipeline = @import("SpritePipeline.zig");
pub const Text = @import("Text.zig");
pub const TextPipeline = @import("TextPipeline.zig");
pub const TextStyle = @import("TextStyle.zig");

/// All Sprite rendering modules
pub const sprite_modules = .{ Sprite, SpritePipeline };

/// All Text rendering modules
pub const text_modules = .{ Text, TextPipeline, TextStyle };

/// All graphics modules
pub const modules = .{ sprite_modules, text_modules };

// Fonts
pub const Font = @import("font/main.zig").Font;
pub const TextRun = @import("font/main.zig").TextRun;
pub const Glyph = @import("font/main.zig").Glyph;
pub const px_per_pt = @import("font/main.zig").px_per_pt;
pub const font_weight_normal = 400;
pub const font_weight_bold = 700;

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
