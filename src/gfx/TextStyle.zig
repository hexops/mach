const mach = @import("../main.zig");
const math = mach.math;

pub const name = .mach_gfx_text_style;
pub const Mod = mach.Mod(@This());

pub const components = .{
    // TODO: ship a default font
    .font_name = .{ .type = []const u8, .description = 
    \\ Desired font to render text with.
    \\ TODO(text): this is not currently implemented
    },

    // e.g. 12 * mach.gfx.px_per_pt // 12pt
    .font_size = .{ .type = f32, .description = 
    \\ Font size in pixels
    \\ TODO(text): this is not currently implemented
    },

    // e.g. mach.gfx.font_weight_normal
    .font_weight = .{ .type = u16, .description = 
    \\ Font weight
    \\ TODO(text): this is not currently implemented
    },

    // e.g. false
    .italic = .{ .type = bool, .description = 
    \\ Italic text
    \\ TODO(text): this is not currently implemented
    },

    // e.g. vec4(0, 0, 0, 1.0)
    .color = .{ .type = math.Vec4, .description = 
    \\ Fill color
    \\ TODO(text): this is not currently implemented
    },

    // TODO(text): allow user to specify projection matrix (3d-space flat text etc.)
};
