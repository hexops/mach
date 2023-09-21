const math = @import("../main.zig").math;
const harfbuzz = @import("mach-harfbuzz");
const std = @import("std");

/// An interface that can render Unicode codepoints into glyphs.
pub const FontRenderer = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        render: *const fn (ctx: *anyopaque, codepoint: u21, size: f32) error{RenderError}!Glyph,
        measure: *const fn (ctx: *anyopaque, codepoint: u21, size: f32) error{MeasureError}!GlyphMetrics,
    };

    pub fn render(r: FontRenderer, codepoint: u21, size: f32) error{RenderError}!Glyph {
        return r.vtable.render(r.ptr, codepoint, size);
    }

    pub fn measure(r: FontRenderer, codepoint: u21, size: f32) error{MeasureError}!GlyphMetrics {
        return r.vtable.measure(r.ptr, codepoint, size);
    }
};

pub const RGBA32 = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Glyph = struct {
    bitmap: ?[]const RGBA32,
    width: u32,
    height: u32,
};

pub const GlyphMetrics = struct {
    size: math.Vec2,
    advance: math.Vec2,
    bearing_horizontal: math.Vec2,
    bearing_vertical: math.Vec2,
};
