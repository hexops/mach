const std = @import("std");
const utils = @import("utils");
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

    pub fn from(bits: u24) LoadFlags {
        return utils.bitFieldsToStruct(LoadFlags, Flag, bits);
    }

    pub fn cast(self: LoadFlags) u24 {
        return utils.structToBitFields(u24, Flag, self);
    }
};

pub const FaceFlags = packed struct {
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

    pub const Flag = enum(u19) {
        scalable = c.FT_FACE_FLAG_SCALABLE,
        fixed_sizes = c.FT_FACE_FLAG_FIXED_SIZES,
        fixed_width = c.FT_FACE_FLAG_FIXED_WIDTH,
        sfnt = c.FT_FACE_FLAG_SFNT,
        horizontal = c.FT_FACE_FLAG_HORIZONTAL,
        vertical = c.FT_FACE_FLAG_VERTICAL,
        kerning = c.FT_FACE_FLAG_KERNING,
        fast_glyphs = c.FT_FACE_FLAG_FAST_GLYPHS,
        multiple_masters = c.FT_FACE_FLAG_MULTIPLE_MASTERS,
        glyph_names = c.FT_FACE_FLAG_GLYPH_NAMES,
        external_stream = c.FT_FACE_FLAG_EXTERNAL_STREAM,
        hinter = c.FT_FACE_FLAG_HINTER,
        cid_keyed = c.FT_FACE_FLAG_CID_KEYED,
        tricky = c.FT_FACE_FLAG_TRICKY,
        color = c.FT_FACE_FLAG_COLOR,
        variation = c.FT_FACE_FLAG_VARIATION,
        svg = c.FT_FACE_FLAG_SVG,
        sbix = c.FT_FACE_FLAG_SBIX,
        sbix_overlay = c.FT_FACE_FLAG_SBIX_OVERLAY,
    };

    pub fn from(bits: u19) FaceFlags {
        return utils.bitFieldsToStruct(FaceFlags, Flag, bits);
    }

    pub fn cast(self: FaceFlags) u19 {
        return utils.structToBitFields(u19, Flag, self);
    }
};

pub const FSType = packed struct {
    installable_embedding: bool = false,
    restriced_license_embedding: bool = false,
    preview_and_print_embedding: bool = false,
    editable_embedding: bool = false,
    no_subsetting: bool = false,
    bitmap_embedding_only: bool = false,

    pub const Flag = enum(u10) {
        installable_embedding = c.FT_FSTYPE_INSTALLABLE_EMBEDDING,
        restriced_license_embedding = c.FT_FSTYPE_RESTRICTED_LICENSE_EMBEDDING,
        preview_and_print_embedding = c.FT_FSTYPE_PREVIEW_AND_PRINT_EMBEDDING,
        editable_embedding = c.FT_FSTYPE_EDITABLE_EMBEDDING,
        no_subsetting = c.FT_FSTYPE_NO_SUBSETTING,
        bitmap_embedding_only = c.FT_FSTYPE_BITMAP_EMBEDDING_ONLY,
    };

    pub fn from(bits: u10) FSType {
        return utils.bitFieldsToStruct(FSType, Flag, bits);
    }

    pub fn cast(self: FSType) u10 {
        return utils.structToBitFields(u10, Flag, self);
    }
};

pub const StyleFlags = packed struct {
    italic: bool = false,
    bold: bool = false,

    pub const Flag = enum(u2) {
        italic = c.FT_STYLE_FLAG_ITALIC,
        bold = c.FT_STYLE_FLAG_BOLD,
    };

    pub fn from(bits: u2) StyleFlags {
        return utils.bitFieldsToStruct(StyleFlags, Flag, bits);
    }

    pub fn cast(self: StyleFlags) u2 {
        return utils.structToBitFields(u2, Flag, self);
    }
};

pub const OpenFlags = packed struct {
    memory: bool = false,
    stream: bool = false,
    path: bool = false,
    driver: bool = false,
    params: bool = false,

    pub const Flag = enum(u5) {
        memory = c.FT_OPEN_MEMORY,
        stream = c.FT_OPEN_STREAM,
        path = c.FT_OPEN_PATHNAME,
        driver = c.FT_OPEN_DRIVER,
        params = c.FT_OPEN_PARAMS,
    };

    pub fn from(bits: u5) OpenFlags {
        return utils.bitFieldsToStruct(OpenFlags, Flag, bits);
    }

    pub fn cast(flags: OpenFlags) u5 {
        return utils.structToBitFields(u5, Flag, flags);
    }
};
pub const OpenArgs = struct {
    flags: OpenFlags,
    data: union(enum) {
        memory: []const u8,
        path: []const u8,
        stream: c.FT_Stream,
        driver: c.FT_Module,
        params: []const c.FT_Parameter,
    },

    pub fn cast(self: OpenArgs) c.FT_Open_Args {
        var oa: c.FT_Open_Args = undefined;
        oa.flags = self.flags.cast();
        switch (self.data) {
            .memory => |d| {
                oa.memory_base = d.ptr;
                oa.memory_size = @intCast(u31, d.len);
            },
            .path => |*d| oa.pathname = @intToPtr(*u8, @ptrToInt(d.ptr)),
            .stream => |d| oa.stream = d,
            .driver => |d| oa.driver = d,
            .params => |*d| {
                oa.params = @intToPtr(*c.FT_Parameter, @ptrToInt(d.ptr));
                oa.num_params = @intCast(u31, d.len);
            },
        }
        return oa;
    }
};

pub fn getCharmapIndex(self: [*c]CharMap) ?u32 {
    const i = c.FT_Get_Charmap_Index(self);
    return if (i == -1) null else @intCast(u32, i);
}
