const std = @import("std");
const testing = std.testing;
const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Generic = @import("types.zig").Generic;

pub const Library = @import("Library.zig");
pub const Face = @import("Face.zig");
pub const GlyphSlot = @import("GlyphSlot.zig");
pub const SizeRequest = c.FT_Size_RequestRec;
pub const BitmapSize = c.FT_Bitmap_Size;
pub const CharMap = c.FT_CharMapRec;
pub const SizeMetrics = c.FT_Size_Metrics;

pub const KerningMode = enum(u2) {
    default = c.FT_KERNING_DEFAULT,
    unfitted = c.FT_KERNING_UNFITTED,
    unscaled = c.FT_KERNING_UNSCALED,
};

pub const RenderMode = enum(u3) {
    normal = c.FT_RENDER_MODE_NORMAL,
    light = c.FT_RENDER_MODE_LIGHT,
    mono = c.FT_RENDER_MODE_MONO,
    lcd = c.FT_RENDER_MODE_LCD,
    lcd_v = c.FT_RENDER_MODE_LCD_V,
    sdf = c.FT_RENDER_MODE_SDF,
};

pub const SizeRequestType = enum(u3) {
    nominal = c.FT_SIZE_REQUEST_TYPE_NOMINAL,
    real_dim = c.FT_SIZE_REQUEST_TYPE_REAL_DIM,
    bbox = c.FT_SIZE_REQUEST_TYPE_BBOX,
    cell = c.FT_SIZE_REQUEST_TYPE_CELL,
    scales = c.FT_SIZE_REQUEST_TYPE_SCALES,
    max = c.FT_SIZE_REQUEST_TYPE_MAX,
};

pub const Encoding = enum(u31) {
    none = c.FT_ENCODING_NONE,
    ms_symbol = c.FT_ENCODING_MS_SYMBOL,
    unicode = c.FT_ENCODING_UNICODE,
    sjis = c.FT_ENCODING_SJIS,
    prc = c.FT_ENCODING_PRC,
    big5 = c.FT_ENCODING_BIG5,
    wansung = c.FT_ENCODING_WANSUNG,
    johab = c.FT_ENCODING_JOHAB,
    adobe_standard = c.FT_ENCODING_ADOBE_STANDARD,
    adobe_expert = c.FT_ENCODING_ADOBE_EXPERT,
    adobe_custom = c.FT_ENCODING_ADOBE_CUSTOM,
    adobe_latin_1 = c.FT_ENCODING_ADOBE_LATIN_1,
    old_latin_2 = c.FT_ENCODING_OLD_LATIN_2,
    apple_roman = c.FT_ENCODING_APPLE_ROMAN,
};

pub const Size = struct {
    handle: c.FT_Size,

    pub fn face(self: Size) Face {
        return Face{ .handle = self.handle.*.face };
    }

    pub fn generic(self: Size) Generic {
        return self.handle.*.generic;
    }

    pub fn metrics(self: Size) SizeMetrics {
        return self.handle.*.metrics;
    }

    pub fn activate(self: Size) Error!void {
        try intToError(c.FT_Activate_Size(self.handle));
    }

    pub fn deinit(self: Size) void {
        intToError(c.FT_Done_Size(self.handle)) catch |err| {
            std.log.err("mach/freetype: Failed to destroy Size: {}", .{err});
        };
    }
};

pub const LoadFlags = packed struct(c_int) {
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
    _padding: u1 = 0,
    target_normal: bool = false,
    target_light: bool = false,
    target_mono: bool = false,
    target_lcd: bool = false,
    target_lcd_v: bool = false,
    color: bool = false,
    compute_metrics: bool = false,
    bitmap_metrics_only: bool = false,
    _padding0: u9 = 0,
};

pub const FaceFlags = packed struct(c_long) {
    scalable: bool = false,
    fixed_sizes: bool = false,
    fixed_width: bool = false,
    sfnt: bool = false,
    horizontal: bool = false,
    vertical: bool = false,
    kerning: bool = false,
    fast_glyphs: bool = false,
    multiple_masters: bool = false,
    glyph_names: bool = false,
    external_stream: bool = false,
    hinter: bool = false,
    cid_keyed: bool = false,
    tricky: bool = false,
    color: bool = false,
    variation: bool = false,
    svg: bool = false,
    sbix: bool = false,
    sbix_overlay: bool = false,
    _padding: if (@sizeOf(c_long) == 4) u13 else u45 = 0,
};

pub const FSType = packed struct(c_ushort) {
    installable_embedding: bool = false,
    restriced_license_embedding: bool = false,
    preview_and_print_embedding: bool = false,
    editable_embedding: bool = false,
    _padding: u4 = 0,
    no_subsetting: bool = false,
    bitmap_embedding_only: bool = false,
    _padding0: u6 = 0,
};

pub const StyleFlags = packed struct(c_long) {
    italic: bool = false,
    bold: bool = false,
    _padding: if (@sizeOf(c_long) == 4) u30 else u62 = 0,
};

pub const OpenFlags = packed struct(c_int) {
    memory: bool = false,
    stream: bool = false,
    path: bool = false,
    driver: bool = false,
    params: bool = false,
    _padding: u27 = 0,
};
pub const OpenArgs = struct {
    flags: OpenFlags,
    data: union(enum) {
        memory: []const u8,
        path: [*:0]const u8,
        stream: c.FT_Stream,
        driver: c.FT_Module,
        params: []const c.FT_Parameter,
    },

    pub fn cast(self: OpenArgs) c.FT_Open_Args {
        var oa: c.FT_Open_Args = undefined;
        oa.flags = @as(u32, @bitCast(self.flags));
        switch (self.data) {
            .memory => |d| {
                oa.memory_base = d.ptr;
                oa.memory_size = @as(u31, @intCast(d.len));
            },
            // The Freetype API requires a mutable string.
            // This is an oversight, Freetype actually never writes to this string.
            .path => |d| oa.pathname = @constCast(d),
            .stream => |d| oa.stream = d,
            .driver => |d| oa.driver = d,
            .params => |*d| {
                oa.params = @as(*c.FT_Parameter, @ptrFromInt(@intFromPtr(d.ptr)));
                oa.num_params = @as(u31, @intCast(d.len));
            },
        }
        return oa;
    }
};

pub fn getCharmapIndex(self: [*c]CharMap) ?u32 {
    const i = c.FT_Get_Charmap_Index(self);
    return if (i == -1) null else @as(u32, @intCast(i));
}
