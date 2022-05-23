const std = @import("std");
const c = @import("c.zig");
const types = @import("types.zig");
const GlyphSlot = @import("GlyphSlot.zig");
const Library = @import("Library.zig");
const Error = @import("error.zig").Error;
const convertError = @import("error.zig").convertError;
const utils = @import("utils.zig");

const Face = @This();

pub const SizeMetrics = c.FT_Size_Metrics;
pub const KerningMode = enum(u2) {
    default = c.FT_KERNING_DEFAULT,
    unfitted = c.FT_KERNING_UNFITTED,
    unscaled = c.FT_KERNING_UNSCALED,
};
pub const LoadFlags = packed struct {
    no_scale: bool = false,
    no_hinting: bool = false,
    render: bool = false,
    no_bitmap: bool = false,
    vertical_layout: bool = false,
    force_autohint: bool = false,
    crop_bitmap: bool = false,
    pedantic: bool = false,
    ignore_global_advance_with: bool = false,
    no_recurse: bool = false,
    ignore_transform: bool = false,
    monochrome: bool = false,
    linear_design: bool = false,
    no_autohint: bool = false,
    target_normal: bool = false,
    target_light: bool = false,
    target_mono: bool = false,
    target_lcd: bool = false,
    target_lcd_v: bool = false,
    color: bool = false,

    pub const Flag = enum(u21) {
        no_scale = c.FT_LOAD_NO_SCALE,
        no_hinting = c.FT_LOAD_NO_HINTING,
        render = c.FT_LOAD_RENDER,
        no_bitmap = c.FT_LOAD_NO_BITMAP,
        vertical_layout = c.FT_LOAD_VERTICAL_LAYOUT,
        force_autohint = c.FT_LOAD_FORCE_AUTOHINT,
        crop_bitmap = c.FT_LOAD_CROP_BITMAP,
        pedantic = c.FT_LOAD_PEDANTIC,
        ignore_global_advance_with = c.FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH,
        no_recurse = c.FT_LOAD_NO_RECURSE,
        ignore_transform = c.FT_LOAD_IGNORE_TRANSFORM,
        monochrome = c.FT_LOAD_MONOCHROME,
        linear_design = c.FT_LOAD_LINEAR_DESIGN,
        no_autohint = c.FT_LOAD_NO_AUTOHINT,
        target_normal = c.FT_LOAD_TARGET_NORMAL,
        target_light = c.FT_LOAD_TARGET_LIGHT,
        target_mono = c.FT_LOAD_TARGET_MONO,
        target_lcd = c.FT_LOAD_TARGET_LCD,
        target_lcd_v = c.FT_LOAD_TARGET_LCD_V,
        color = c.FT_LOAD_COLOR,
    };

    pub fn toBitFields(flags: LoadFlags) u21 {
        return utils.structToBitFields(u21, Flag, flags);
    }
};
pub const StyleFlags = packed struct {
    bold: bool = false,
    italic: bool = false,

    pub const Flag = enum(u2) {
        bold = c.FT_STYLE_FLAG_BOLD,
        italic = c.FT_STYLE_FLAG_ITALIC,
    };

    pub fn toBitFields(flags: StyleFlags) u2 {
        return utils.structToBitFields(u2, StyleFlags, Flag, flags);
    }
};

handle: c.FT_Face,
glyph: GlyphSlot,

pub fn init(handle: c.FT_Face) Face {
    return Face{
        .handle = handle,
        .glyph = GlyphSlot.init(handle.*.glyph),
    };
}

pub fn deinit(self: Face) void {
    convertError(c.FT_Done_Face(self.handle)) catch |err| {
        std.log.err("mach/freetype: Failed to destroy Face: {}", .{err});
    };
}

pub fn attachFile(self: Face, path: []const u8) Error!void {
    return self.attachStream(.{
        .flags = .{ .path = true },
        .data = .{ .path = path },
    });
}

pub fn attachMemory(self: Face, bytes: []const u8) Error!void {
    return self.attachStream(.{
        .flags = .{ .memory = true },
        .data = .{ .memory = bytes },
    });
}

pub fn attachStream(self: Face, args: types.OpenArgs) Error!void {
    return convertError(c.FT_Attach_Stream(self.handle, &args.toCInterface()));
}

pub fn setCharSize(self: Face, pt_width: i32, pt_height: i32, horz_resolution: u16, vert_resolution: u16) Error!void {
    return convertError(c.FT_Set_Char_Size(self.handle, pt_width, pt_height, horz_resolution, vert_resolution));
}

pub fn setPixelSizes(self: Face, pixel_width: u32, pixel_height: u32) Error!void {
    return convertError(c.FT_Set_Pixel_Sizes(self.handle, pixel_width, pixel_height));
}

pub fn loadGlyph(self: Face, index: u32, flags: LoadFlags) Error!void {
    return convertError(c.FT_Load_Glyph(self.handle, index, flags.toBitFields()));
}

pub fn loadChar(self: Face, char: u32, flags: LoadFlags) Error!void {
    return convertError(c.FT_Load_Char(self.handle, char, flags.toBitFields()));
}

pub fn setTransform(self: Face, matrix: ?types.Matrix, delta: ?types.Vector) Error!void {
    var m = matrix orelse std.mem.zeroes(types.Matrix);
    var d = delta orelse std.mem.zeroes(types.Vector);
    return c.FT_Set_Transform(self.handle, &m, &d);
}

pub fn getCharIndex(self: Face, index: u32) ?u32 {
    const i = c.FT_Get_Char_Index(self.handle, index);
    return if (i == 0) null else i;
}

pub fn getKerning(self: Face, left_char_index: u32, right_char_index: u32, mode: KerningMode) Error!types.Vector {
    var vec = std.mem.zeroes(types.Vector);
    try convertError(c.FT_Get_Kerning(self.handle, left_char_index, right_char_index, @enumToInt(mode), &vec));
    return vec;
}

pub fn hasHorizontal(self: Face) bool {
    return c.FT_HAS_HORIZONTAL(self.handle);
}

pub fn hasVertical(self: Face) bool {
    return c.FT_HAS_VERTICAL(self.handle);
}

pub fn hasKerning(self: Face) bool {
    return c.FT_HAS_KERNING(self.handle);
}

pub fn hasFixedSizes(self: Face) bool {
    return c.FT_HAS_FIXED_SIZES(self.handle);
}

pub fn hasGlyphNames(self: Face) bool {
    return c.FT_HAS_GLYPH_NAMES(self.handle);
}

pub fn hasColor(self: Face) bool {
    return c.FT_HAS_COLOR(self.handle);
}

pub fn isScalable(self: Face) bool {
    return c.FT_IS_SCALABLE(self.handle);
}

pub fn isSfnt(self: Face) bool {
    return c.FT_IS_SFNT(self.handle);
}

pub fn isFixedWidth(self: Face) bool {
    return c.FT_IS_FIXED_WIDTH(self.handle);
}

pub fn isCidKeyed(self: Face) bool {
    return c.FT_IS_CID_KEYED(self.handle);
}

pub fn isTricky(self: Face) bool {
    return c.FT_IS_TRICKY(self.handle);
}

pub fn ascender(self: Face) i16 {
    return self.handle.*.ascender;
}

pub fn descender(self: Face) i16 {
    return self.handle.*.descender;
}

pub fn emSize(self: Face) u16 {
    return self.handle.*.units_per_EM;
}

pub fn height(self: Face) i16 {
    return self.handle.*.height;
}

pub fn maxAdvanceWidth(self: Face) i16 {
    return self.handle.*.max_advance_width;
}

pub fn maxAdvanceHeight(self: Face) i16 {
    return self.handle.*.max_advance_height;
}

pub fn underlinePosition(self: Face) i16 {
    return self.handle.*.underline_position;
}

pub fn underlineThickness(self: Face) i16 {
    return self.handle.*.underline_thickness;
}

pub fn numFaces(self: Face) i64 {
    return self.handle.*.num_faces;
}

pub fn numGlyphs(self: Face) i64 {
    return self.handle.*.num_glyphs;
}

pub fn familyName(self: Face) ?[:0]const u8 {
    const family = self.handle.*.family_name;
    return if (family == null)
        null
    else
        std.mem.span(family);
}

pub fn styleName(self: Face) ?[:0]const u8 {
    const style = self.handle.*.style_name;
    return if (style == null)
        null
    else
        std.mem.span(style);
}

pub fn styleFlags(self: Face) StyleFlags {
    const flags = self.handle.*.style_flags;
    return utils.bitFieldsToStruct(StyleFlags, StyleFlags.Flag, flags);
}

pub fn sizeMetrics(self: Face) ?SizeMetrics {
    const size = self.handle.*.size;
    return if (size == null)
        null
    else
        size.*.metrics;
}

pub fn postscriptName(self: Face) ?[:0]const u8 {
    const face_name = c.FT_Get_Postscript_Name(self.handle);
    return if (face_name == null)
        null
    else
        std.mem.span(face_name);
}
