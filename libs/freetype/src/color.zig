const std = @import("std");
const testing = std.testing;
const c = @import("c.zig");
const Face = @import("freetype.zig").Face;

pub const Color = c.FT_Color;
pub const LayerIterator = c.FT_LayerIterator;
pub const ColorStopIterator = c.FT_ColorStopIterator;
pub const ColorIndex = c.FT_ColorIndex;
pub const ColorStop = c.FT_ColorStop;
pub const ColorLine = c.FT_ColorLine;
pub const Affine23 = c.FT_Affine23;
pub const OpaquePaint = c.FT_OpaquePaint;
pub const PaintColrLayers = c.FT_PaintColrLayers;
pub const PaintSolid = c.FT_PaintSolid;
pub const PaintLinearGradient = c.FT_PaintLinearGradient;
pub const PaintRadialGradient = c.FT_PaintRadialGradient;
pub const PaintSweepGradient = c.FT_PaintSweepGradient;
pub const PaintGlyph = c.FT_PaintGlyph;
pub const PaintColrGlyph = c.FT_PaintColrGlyph;
pub const PaintTransform = c.FT_PaintTransform;
pub const PaintTranslate = c.FT_PaintTranslate;
pub const PaintScale = c.FT_PaintScale;
pub const PaintRotate = c.FT_PaintRotate;
pub const PaintSkew = c.FT_PaintSkew;
pub const PaintComposite = c.FT_PaintComposite;
pub const ClipBox = c.FT_ClipBox;

pub const RootTransform = enum(u1) {
    include_root_transform = c.FT_COLOR_INCLUDE_ROOT_TRANSFORM,
    no_root_transform = c.FT_COLOR_NO_ROOT_TRANSFORM,
};

pub const PaintExtend = enum(u2) {
    pad = c.FT_COLR_PAINT_EXTEND_PAD,
    repeat = c.FT_COLR_PAINT_EXTEND_REPEAT,
    reflect = c.FT_COLR_PAINT_EXTEND_REFLECT,
};

pub const PaintFormat = enum(u8) {
    color_layers = c.FT_COLR_PAINTFORMAT_COLR_LAYERS,
    solid = c.FT_COLR_PAINTFORMAT_SOLID,
    linear_gradient = c.FT_COLR_PAINTFORMAT_LINEAR_GRADIENT,
    radial_gradient = c.FT_COLR_PAINTFORMAT_RADIAL_GRADIENT,
    sweep_gradient = c.FT_COLR_PAINTFORMAT_SWEEP_GRADIENT,
    glyph = c.FT_COLR_PAINTFORMAT_GLYPH,
    color_glyph = c.FT_COLR_PAINTFORMAT_COLR_GLYPH,
    transform = c.FT_COLR_PAINTFORMAT_TRANSFORM,
    translate = c.FT_COLR_PAINTFORMAT_TRANSLATE,
    scale = c.FT_COLR_PAINTFORMAT_SCALE,
    rotate = c.FT_COLR_PAINTFORMAT_ROTATE,
    skew = c.FT_COLR_PAINTFORMAT_SKEW,
    composite = c.FT_COLR_PAINTFORMAT_COMPOSITE,
};

pub const CompositeMode = enum(u5) {
    clear = c.FT_COLR_COMPOSITE_CLEAR,
    src = c.FT_COLR_COMPOSITE_SRC,
    dest = c.FT_COLR_COMPOSITE_DEST,
    src_over = c.FT_COLR_COMPOSITE_SRC_OVER,
    dest_over = c.FT_COLR_COMPOSITE_DEST_OVER,
    src_in = c.FT_COLR_COMPOSITE_SRC_IN,
    dest_in = c.FT_COLR_COMPOSITE_DEST_IN,
    src_out = c.FT_COLR_COMPOSITE_SRC_OUT,
    dest_out = c.FT_COLR_COMPOSITE_DEST_OUT,
    src_atop = c.FT_COLR_COMPOSITE_SRC_ATOP,
    dest_atop = c.FT_COLR_COMPOSITE_DEST_ATOP,
    xor = c.FT_COLR_COMPOSITE_XOR,
    plus = c.FT_COLR_COMPOSITE_PLUS,
    screen = c.FT_COLR_COMPOSITE_SCREEN,
    overlay = c.FT_COLR_COMPOSITE_OVERLAY,
    darken = c.FT_COLR_COMPOSITE_DARKEN,
    lighten = c.FT_COLR_COMPOSITE_LIGHTEN,
    color_dodge = c.FT_COLR_COMPOSITE_COLOR_DODGE,
    color_burn = c.FT_COLR_COMPOSITE_COLOR_BURN,
    hard_light = c.FT_COLR_COMPOSITE_HARD_LIGHT,
    soft_light = c.FT_COLR_COMPOSITE_SOFT_LIGHT,
    difference = c.FT_COLR_COMPOSITE_DIFFERENCE,
    exclusion = c.FT_COLR_COMPOSITE_EXCLUSION,
    multiply = c.FT_COLR_COMPOSITE_MULTIPLY,
    hsl_hue = c.FT_COLR_COMPOSITE_HSL_HUE,
    hsl_saturation = c.FT_COLR_COMPOSITE_HSL_SATURATION,
    hsl_color = c.FT_COLR_COMPOSITE_HSL_COLOR,
    hsl_luminosity = c.FT_COLR_COMPOSITE_HSL_LUMINOSITY,
};

pub const Paint = union(PaintFormat) {
    color_layers: PaintColrLayers,
    glyph: PaintGlyph,
    solid: PaintSolid,
    linear_gradient: PaintLinearGradient,
    radial_gradient: PaintRadialGradient,
    sweep_gradient: PaintSweepGradient,
    transform: PaintTransform,
    translate: PaintTranslate,
    scale: PaintScale,
    rotate: PaintRotate,
    skew: PaintSkew,
    composite: PaintComposite,
    color_glyph: PaintColrGlyph,
};

pub const PaletteData = struct {
    handle: c.FT_Palette_Data,

    pub fn numPalettes(self: PaletteData) u16 {
        return self.handle.num_palettes;
    }

    pub fn paletteNameIDs(self: PaletteData) ?[]const u16 {
        return self.handle.palette_name_ids[0..self.numPalettes()];
    }

    pub fn paletteFlags(self: PaletteData) ?[]const u16 {
        return self.handle.palette_flags[0..self.numPalettes()];
    }

    pub fn paletteFlag(self: PaletteData, index: u32) PaletteFlags {
        return @as(PaletteFlags, @bitCast(self.handle.palette_flags[index]));
    }

    pub fn numPaletteEntries(self: PaletteData) u16 {
        return self.handle.num_palette_entries;
    }

    pub fn paletteEntryNameIDs(self: PaletteData) ?[]const u16 {
        return self.handle.palette_entry_name_ids[0..self.numPaletteEntries()];
    }
};

pub const PaletteFlags = packed struct(c_ushort) {
    for_light_background: bool = false,
    for_dark_background: bool = false,
    _padding: u14 = 0,
};

pub const GlyphLayersIterator = struct {
    face: Face,
    glyph_index: u32,
    layer_glyph_index: u32,
    layer_color_index: u32,
    iterator: LayerIterator,

    pub fn init(face: Face, glyph_index: u32) GlyphLayersIterator {
        var iterator: LayerIterator = undefined;
        iterator.p = null;
        return .{
            .face = face,
            .glyph_index = glyph_index,
            .layer_glyph_index = 0,
            .layer_color_index = 0,
            .iterator = iterator,
        };
    }

    pub fn next(self: *GlyphLayersIterator) bool {
        return if (c.FT_Get_Color_Glyph_Layer(
            self.face.handle,
            self.glyph_index,
            &self.layer_glyph_index,
            &self.layer_color_index,
            &self.iterator,
        ) == 0) false else true;
    }
};
