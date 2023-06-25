const std = @import("std");
const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const GlyphSlot = @import("freetype.zig").GlyphSlot;
const LoadFlags = @import("freetype.zig").LoadFlags;
const FaceFlags = @import("freetype.zig").FaceFlags;
const StyleFlags = @import("freetype.zig").StyleFlags;
const FSType = @import("freetype.zig").FSType;
const OpenArgs = @import("freetype.zig").OpenArgs;
const KerningMode = @import("freetype.zig").KerningMode;
const Encoding = @import("freetype.zig").Encoding;
const CharMap = @import("freetype.zig").CharMap;
const Size = @import("freetype.zig").Size;
const SizeRequest = @import("freetype.zig").SizeRequest;
const BitmapSize = @import("freetype.zig").BitmapSize;
const Matrix = @import("types.zig").Matrix;
const BBox = @import("types.zig").BBox;
const Vector = @import("image.zig").Vector;
const RootTransform = @import("color.zig").RootTransform;
const PaintFormat = @import("color.zig").PaintFormat;
const Color = @import("color.zig").Color;
const ClipBox = @import("color.zig").ClipBox;
const OpaquePaint = @import("color.zig").OpaquePaint;
const Paint = @import("color.zig").Paint;
const PaletteData = @import("color.zig").PaletteData;
const GlyphLayersIterator = @import("color.zig").GlyphLayersIterator;

pub const CharmapIterator = struct {
    face: Face,
    index: u32,
    charcode: u32,

    pub fn init(face: Face) CharmapIterator {
        var i: u32 = 0;
        const cc = c.FT_Get_First_Char(face.handle, &i);
        return .{
            .face = face,
            .index = i,
            .charcode = @intCast(u32, cc),
        };
    }

    pub fn next(self: *CharmapIterator) ?u32 {
        self.charcode = @intCast(u32, c.FT_Get_Next_Char(self.face.handle, self.charcode, &self.index));
        return if (self.index != 0)
            self.charcode
        else
            null;
    }
};

const Face = @This();

handle: c.FT_Face,

pub fn deinit(self: Face) void {
    _ = c.FT_Done_Face(self.handle);
}

pub fn attachFile(self: Face, path: [*:0]const u8) Error!void {
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

pub fn attachStream(self: Face, args: OpenArgs) Error!void {
    return intToError(c.FT_Attach_Stream(self.handle, &args.cast()));
}

pub fn loadGlyph(self: Face, index: u32, flags: LoadFlags) Error!void {
    return intToError(c.FT_Load_Glyph(self.handle, index, @bitCast(i32, flags)));
}

pub fn loadChar(self: Face, char: u32, flags: LoadFlags) Error!void {
    return intToError(c.FT_Load_Char(self.handle, char, @bitCast(i32, flags)));
}

pub fn setCharSize(self: Face, pt_width: i32, pt_height: i32, horz_resolution: u16, vert_resolution: u16) Error!void {
    return intToError(c.FT_Set_Char_Size(self.handle, pt_width, pt_height, horz_resolution, vert_resolution));
}

pub fn setPixelSizes(self: Face, pixel_width: u32, pixel_height: u32) Error!void {
    return intToError(c.FT_Set_Pixel_Sizes(self.handle, pixel_width, pixel_height));
}

pub fn requestSize(self: Face, req: SizeRequest) Error!void {
    var req_mut = req;
    return intToError(c.FT_Request_Size(self.handle, &req_mut));
}

pub fn selectSize(self: Face, strike_index: i32) Error!void {
    return intToError(c.FT_Select_Size(self.handle, strike_index));
}

pub fn setTransform(self: Face, matrix: ?Matrix, delta: ?Vector) Error!void {
    var matrix_mut = matrix;
    var delta_mut = delta;
    return c.FT_Set_Transform(self.handle, if (matrix_mut) |*m| m else null, if (delta_mut) |*d| d else null);
}

pub fn getTransform(self: Face) std.meta.Tuple(&.{ Matrix, Vector }) {
    var matrix: Matrix = undefined;
    var delta: Vector = undefined;
    c.FT_Get_Transform(self.handle, &matrix, &delta);
    return .{ matrix, delta };
}

pub fn getCharIndex(self: Face, char: u32) ?u32 {
    const i = c.FT_Get_Char_Index(self.handle, char);
    return if (i == 0) null else i;
}

pub fn getNameIndex(self: Face, name: [:0]const u8) ?u32 {
    const i = c.FT_Get_Name_Index(self.handle, name.ptr);
    return if (i == 0) null else i;
}

pub fn getKerning(self: Face, left_char_index: u32, right_char_index: u32, mode: KerningMode) Error!Vector {
    var kerning: Vector = undefined;
    try intToError(c.FT_Get_Kerning(self.handle, left_char_index, right_char_index, @intFromEnum(mode), &kerning));
    return kerning;
}

pub fn getTrackKerning(self: Face, point_size: i32, degree: i32) Error!i32 {
    var kerning: c_long = 0;
    try intToError(c.FT_Get_Track_Kerning(self.handle, point_size, degree, kerning));
    return @intCast(i32, kerning);
}

pub fn getGlyphName(self: Face, index: u32, buf: []u8) Error!void {
    try intToError(c.FT_Get_Glyph_Name(self.handle, index, buf.ptr, @intCast(c_uint, buf.len)));
}

pub fn getPostscriptName(self: Face) ?[:0]const u8 {
    return if (c.FT_Get_Postscript_Name(self.handle)) |face_name|
        std.mem.span(@ptrCast([*:0]const u8, face_name))
    else
        null;
}

pub fn iterateCharmap(self: Face) CharmapIterator {
    return CharmapIterator.init(self);
}

pub fn selectCharmap(self: Face, encoding: Encoding) Error!void {
    return intToError(c.FT_Select_Charmap(self.handle, @intFromEnum(encoding)));
}

pub fn setCharmap(self: Face, char_map: *CharMap) Error!void {
    return intToError(c.FT_Set_Charmap(self.handle, char_map));
}

pub fn getFSTypeFlags(self: Face) FSType {
    return @bitCast(FSType, c.FT_Get_FSType_Flags(self.handle));
}

pub fn getCharVariantIndex(self: Face, char: u32, variant_selector: u32) ?u32 {
    return switch (c.FT_Face_GetCharVariantIndex(self.handle, char, variant_selector)) {
        0 => null,
        else => |i| i,
    };
}

pub fn getCharVariantIsDefault(self: Face, char: u32, variant_selector: u32) ?bool {
    return switch (c.FT_Face_GetCharVariantIsDefault(self.handle, char, variant_selector)) {
        -1 => null,
        0 => false,
        1 => true,
        else => unreachable,
    };
}

pub fn getVariantSelectors(self: Face) ?[]u32 {
    return if (c.FT_Face_GetVariantSelectors(self.handle)) |chars|
        @ptrCast([]u32, std.mem.sliceTo(@ptrCast([*:0]u32, chars), 0))
    else
        null;
}

pub fn getVariantsOfChar(self: Face, char: u32) ?[]u32 {
    return if (c.FT_Face_GetVariantsOfChar(self.handle, char)) |variants|
        @ptrCast([]u32, std.mem.sliceTo(@ptrCast([*:0]u32, variants), 0))
    else
        null;
}

pub fn getCharsOfVariant(self: Face, variant_selector: u32) ?[]u32 {
    return if (c.FT_Face_GetCharsOfVariant(self.handle, variant_selector)) |chars|
        @ptrCast([]u32, std.mem.sliceTo(@ptrCast([*:0]u32, chars), 0))
    else
        null;
}

pub fn getPaletteData(self: Face) Error!PaletteData {
    var p: c.FT_Palette_Data = undefined;
    try intToError(c.FT_Palette_Data_Get(self.handle, &p));
    return PaletteData{ .handle = p };
}

fn selectPalette(self: Face, index: u16) Error!?[]const Color {
    var color: [*:0]Color = undefined;
    try intToError(c.FT_Palette_Select(self.handle, index, &color));
    const pd = try getPaletteData();
    return self.color[0..pd.numPaletteEntries()];
}

pub fn setPaletteForegroundColor(self: Face, color: Color) Error!void {
    try intToError(c.FT_Palette_Set_Foreground_Color(self.handle, color));
}

pub fn getGlyphLayersIterator(self: Face, glyph_index: u32) GlyphLayersIterator {
    return GlyphLayersIterator.init(self, glyph_index);
}

pub fn getColorGlyphPaint(self: Face, base_glyph: u32, root_transform: RootTransform) ?Paint {
    var opaque_paint: OpaquePaint = undefined;
    if (c.FT_Get_Color_Glyph_Paint(self.handle, base_glyph, @intFromEnum(root_transform), &opaque_paint) == 0)
        return null;
    return self.getPaint(opaque_paint);
}

pub fn getColorGlyphClibBox(self: Face, base_glyph: u32) ?ClipBox {
    var clib_box: ClipBox = undefined;
    if (c.FT_Get_Color_Glyph_ClipBox(self.handle, base_glyph, &clib_box) == 0)
        return null;
    return clib_box;
}

pub fn getPaint(self: Face, opaque_paint: OpaquePaint) ?Paint {
    var p: c.FT_COLR_Paint = undefined;
    if (c.FT_Get_Paint(self.handle, opaque_paint, &p) == 0)
        return null;
    return switch (@enumFromInt(PaintFormat, p.format)) {
        .color_layers => Paint{ .color_layers = p.u.colr_layers },
        .glyph => Paint{ .glyph = p.u.glyph },
        .solid => Paint{ .solid = p.u.solid },
        .linear_gradient => Paint{ .linear_gradient = p.u.linear_gradient },
        .radial_gradient => Paint{ .radial_gradient = p.u.radial_gradient },
        .sweep_gradient => Paint{ .sweep_gradient = p.u.sweep_gradient },
        .transform => Paint{ .transform = p.u.transform },
        .translate => Paint{ .translate = p.u.translate },
        .scale => Paint{ .scale = p.u.scale },
        .rotate => Paint{ .rotate = p.u.rotate },
        .skew => Paint{ .skew = p.u.skew },
        .composite => Paint{ .composite = p.u.composite },
        .color_glyph => Paint{ .color_glyph = p.u.colr_glyph },
    };
}

pub fn newSize(self: Face) Error!Size {
    var s: c.FT_Size = undefined;
    try intToError(c.FT_New_Size(self.handle, &s));
    return Size{ .handle = s };
}

pub fn numFaces(self: Face) u32 {
    return @intCast(u32, self.handle.*.num_faces);
}

pub fn faceIndex(self: Face) u32 {
    return @intCast(u32, self.handle.*.face_index);
}

pub fn faceFlags(self: Face) FaceFlags {
    return @bitCast(FaceFlags, self.handle.*.face_flags);
}

pub fn styleFlags(self: Face) StyleFlags {
    return @bitCast(StyleFlags, self.handle.*.style_flags);
}

pub fn numGlyphs(self: Face) u32 {
    return @intCast(u32, self.handle.*.num_glyphs);
}

pub fn familyName(self: Face) ?[:0]const u8 {
    return if (self.handle.*.family_name) |family|
        std.mem.span(@ptrCast([*:0]const u8, family))
    else
        null;
}

pub fn styleName(self: Face) ?[:0]const u8 {
    return if (self.handle.*.style_name) |style_name|
        std.mem.span(@ptrCast([*:0]const u8, style_name))
    else
        null;
}

pub fn numFixedSizes(self: Face) u32 {
    return @intCast(u32, self.handle.*.num_fixed_sizes);
}

pub fn availableSizes(self: Face) []BitmapSize {
    return if (self.handle.*.available_sizes != null)
        self.handle.*.available_sizes[0..self.numFixedSizes()]
    else
        &.{};
}

pub fn getAdvance(self: Face, glyph_index: u32, load_flags: LoadFlags) Error!i32 {
    var a: c_long = 0;
    try intToError(c.FT_Get_Advance(self.handle, glyph_index, @bitCast(i32, load_flags), &a));
    return @intCast(i32, a);
}

pub fn getAdvances(self: Face, start: u32, advances_out: []c_long, load_flags: LoadFlags) Error!void {
    try intToError(c.FT_Get_Advances(self.handle, start, @intCast(u32, advances_out.len), @bitCast(i32, load_flags), advances_out.ptr));
}

pub fn numCharmaps(self: Face) u32 {
    return @intCast(u32, self.handle.*.num_charmaps);
}

pub fn charmaps(self: Face) []const CharMap {
    return @ptrCast([*]const CharMap, self.handle.*.charmaps)[0..self.numCharmaps()];
}

pub fn bbox(self: Face) BBox {
    return self.handle.*.bbox;
}

pub fn unitsPerEM(self: Face) u16 {
    return self.handle.*.units_per_EM;
}

pub fn ascender(self: Face) i16 {
    return self.handle.*.ascender;
}

pub fn descender(self: Face) i16 {
    return self.handle.*.descender;
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

pub fn glyph(self: Face) GlyphSlot {
    return .{ .handle = self.handle.*.glyph };
}

pub fn size(self: Face) Size {
    return Size{ .handle = self.handle.*.size };
}

pub fn charmap(self: Face) CharMap {
    return self.handle.*.charmap.*;
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
