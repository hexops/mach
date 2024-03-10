// TODO: See what else is unneccesary.

const std = @import("std");
const builtin = @import("builtin");

pub const DWRITE_ALPHA_MAX = @as(u32, 255);
pub const FACILITY_DWRITE = @as(u32, 2200);
pub const DWRITE_ERR_BASE = @as(u32, 20480);
pub const DWRITE_E_REMOTEFONT = @as(HRESULT, -2003283955);
pub const DWRITE_E_DOWNLOADCANCELLED = @as(HRESULT, -2003283954);
pub const DWRITE_E_DOWNLOADFAILED = @as(HRESULT, -2003283953);
pub const DWRITE_E_TOOMANYDOWNLOADS = @as(HRESULT, -2003283952);
pub const DWRITE_FONT_AXIS_TAG = enum(u32) {
    WEIGHT = 1952999287,
    WIDTH = 1752458359,
    SLANT = 1953393779,
    OPTICAL_SIZE = 2054385775,
    ITALIC = 1818326121,
};
pub const DWRITE_FONT_AXIS_TAG_WEIGHT = DWRITE_FONT_AXIS_TAG.WEIGHT;
pub const DWRITE_FONT_AXIS_TAG_WIDTH = DWRITE_FONT_AXIS_TAG.WIDTH;
pub const DWRITE_FONT_AXIS_TAG_SLANT = DWRITE_FONT_AXIS_TAG.SLANT;
pub const DWRITE_FONT_AXIS_TAG_OPTICAL_SIZE = DWRITE_FONT_AXIS_TAG.OPTICAL_SIZE;
pub const DWRITE_FONT_AXIS_TAG_ITALIC = DWRITE_FONT_AXIS_TAG.ITALIC;

pub const DWRITE_COLOR_F = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

pub const DWRITE_MEASURING_MODE = enum(i32) {
    NATURAL = 0,
    GDI_CLASSIC = 1,
    GDI_NATURAL = 2,
};
pub const DWRITE_MEASURING_MODE_NATURAL = DWRITE_MEASURING_MODE.NATURAL;
pub const DWRITE_MEASURING_MODE_GDI_CLASSIC = DWRITE_MEASURING_MODE.GDI_CLASSIC;
pub const DWRITE_MEASURING_MODE_GDI_NATURAL = DWRITE_MEASURING_MODE.GDI_NATURAL;

pub const DWRITE_GLYPH_IMAGE_FORMATS = enum(u32) {
    NONE = 0,
    TRUETYPE = 1,
    CFF = 2,
    COLR = 4,
    SVG = 8,
    PNG = 16,
    JPEG = 32,
    TIFF = 64,
    PREMULTIPLIED_B8G8R8A8 = 128,
    _,
    pub fn initFlags(o: struct {
        NONE: u1 = 0,
        TRUETYPE: u1 = 0,
        CFF: u1 = 0,
        COLR: u1 = 0,
        SVG: u1 = 0,
        PNG: u1 = 0,
        JPEG: u1 = 0,
        TIFF: u1 = 0,
        PREMULTIPLIED_B8G8R8A8: u1 = 0,
    }) DWRITE_GLYPH_IMAGE_FORMATS {
        return @as(DWRITE_GLYPH_IMAGE_FORMATS, @enumFromInt((if (o.NONE == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.NONE) else 0) | (if (o.TRUETYPE == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.TRUETYPE) else 0) | (if (o.CFF == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.CFF) else 0) | (if (o.COLR == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.COLR) else 0) | (if (o.SVG == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.SVG) else 0) | (if (o.PNG == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.PNG) else 0) | (if (o.JPEG == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.JPEG) else 0) | (if (o.TIFF == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.TIFF) else 0) | (if (o.PREMULTIPLIED_B8G8R8A8 == 1) @intFromEnum(DWRITE_GLYPH_IMAGE_FORMATS.PREMULTIPLIED_B8G8R8A8) else 0)));
    }
};
pub const DWRITE_GLYPH_IMAGE_FORMATS_NONE = DWRITE_GLYPH_IMAGE_FORMATS.NONE;
pub const DWRITE_GLYPH_IMAGE_FORMATS_TRUETYPE = DWRITE_GLYPH_IMAGE_FORMATS.TRUETYPE;
pub const DWRITE_GLYPH_IMAGE_FORMATS_CFF = DWRITE_GLYPH_IMAGE_FORMATS.CFF;
pub const DWRITE_GLYPH_IMAGE_FORMATS_COLR = DWRITE_GLYPH_IMAGE_FORMATS.COLR;
pub const DWRITE_GLYPH_IMAGE_FORMATS_SVG = DWRITE_GLYPH_IMAGE_FORMATS.SVG;
pub const DWRITE_GLYPH_IMAGE_FORMATS_PNG = DWRITE_GLYPH_IMAGE_FORMATS.PNG;
pub const DWRITE_GLYPH_IMAGE_FORMATS_JPEG = DWRITE_GLYPH_IMAGE_FORMATS.JPEG;
pub const DWRITE_GLYPH_IMAGE_FORMATS_TIFF = DWRITE_GLYPH_IMAGE_FORMATS.TIFF;
pub const DWRITE_GLYPH_IMAGE_FORMATS_PREMULTIPLIED_B8G8R8A8 = DWRITE_GLYPH_IMAGE_FORMATS.PREMULTIPLIED_B8G8R8A8;

pub const DWRITE_FONT_FILE_TYPE = enum(i32) {
    UNKNOWN = 0,
    CFF = 1,
    TRUETYPE = 2,
    OPENTYPE_COLLECTION = 3,
    TYPE1_PFM = 4,
    TYPE1_PFB = 5,
    VECTOR = 6,
    BITMAP = 7,
    // TRUETYPE_COLLECTION = 3, this enum value conflicts with OPENTYPE_COLLECTION
};
pub const DWRITE_FONT_FILE_TYPE_UNKNOWN = DWRITE_FONT_FILE_TYPE.UNKNOWN;
pub const DWRITE_FONT_FILE_TYPE_CFF = DWRITE_FONT_FILE_TYPE.CFF;
pub const DWRITE_FONT_FILE_TYPE_TRUETYPE = DWRITE_FONT_FILE_TYPE.TRUETYPE;
pub const DWRITE_FONT_FILE_TYPE_OPENTYPE_COLLECTION = DWRITE_FONT_FILE_TYPE.OPENTYPE_COLLECTION;
pub const DWRITE_FONT_FILE_TYPE_TYPE1_PFM = DWRITE_FONT_FILE_TYPE.TYPE1_PFM;
pub const DWRITE_FONT_FILE_TYPE_TYPE1_PFB = DWRITE_FONT_FILE_TYPE.TYPE1_PFB;
pub const DWRITE_FONT_FILE_TYPE_VECTOR = DWRITE_FONT_FILE_TYPE.VECTOR;
pub const DWRITE_FONT_FILE_TYPE_BITMAP = DWRITE_FONT_FILE_TYPE.BITMAP;
pub const DWRITE_FONT_FILE_TYPE_TRUETYPE_COLLECTION = DWRITE_FONT_FILE_TYPE.OPENTYPE_COLLECTION;

pub const DWRITE_FONT_FACE_TYPE = enum(i32) {
    CFF = 0,
    TRUETYPE = 1,
    OPENTYPE_COLLECTION = 2,
    TYPE1 = 3,
    VECTOR = 4,
    BITMAP = 5,
    UNKNOWN = 6,
    RAW_CFF = 7,
    // TRUETYPE_COLLECTION = 2, this enum value conflicts with OPENTYPE_COLLECTION
};
pub const DWRITE_FONT_FACE_TYPE_CFF = DWRITE_FONT_FACE_TYPE.CFF;
pub const DWRITE_FONT_FACE_TYPE_TRUETYPE = DWRITE_FONT_FACE_TYPE.TRUETYPE;
pub const DWRITE_FONT_FACE_TYPE_OPENTYPE_COLLECTION = DWRITE_FONT_FACE_TYPE.OPENTYPE_COLLECTION;
pub const DWRITE_FONT_FACE_TYPE_TYPE1 = DWRITE_FONT_FACE_TYPE.TYPE1;
pub const DWRITE_FONT_FACE_TYPE_VECTOR = DWRITE_FONT_FACE_TYPE.VECTOR;
pub const DWRITE_FONT_FACE_TYPE_BITMAP = DWRITE_FONT_FACE_TYPE.BITMAP;
pub const DWRITE_FONT_FACE_TYPE_UNKNOWN = DWRITE_FONT_FACE_TYPE.UNKNOWN;
pub const DWRITE_FONT_FACE_TYPE_RAW_CFF = DWRITE_FONT_FACE_TYPE.RAW_CFF;
pub const DWRITE_FONT_FACE_TYPE_TRUETYPE_COLLECTION = DWRITE_FONT_FACE_TYPE.OPENTYPE_COLLECTION;

pub const DWRITE_FONT_SIMULATIONS = enum(u32) {
    NONE = 0,
    BOLD = 1,
    OBLIQUE = 2,
    _,
    pub fn initFlags(o: struct {
        NONE: u1 = 0,
        BOLD: u1 = 0,
        OBLIQUE: u1 = 0,
    }) DWRITE_FONT_SIMULATIONS {
        return @as(DWRITE_FONT_SIMULATIONS, @enumFromInt((if (o.NONE == 1) @intFromEnum(DWRITE_FONT_SIMULATIONS.NONE) else 0) | (if (o.BOLD == 1) @intFromEnum(DWRITE_FONT_SIMULATIONS.BOLD) else 0) | (if (o.OBLIQUE == 1) @intFromEnum(DWRITE_FONT_SIMULATIONS.OBLIQUE) else 0)));
    }
};
pub const DWRITE_FONT_SIMULATIONS_NONE = DWRITE_FONT_SIMULATIONS.NONE;
pub const DWRITE_FONT_SIMULATIONS_BOLD = DWRITE_FONT_SIMULATIONS.BOLD;
pub const DWRITE_FONT_SIMULATIONS_OBLIQUE = DWRITE_FONT_SIMULATIONS.OBLIQUE;

pub const DWRITE_FONT_WEIGHT = enum(i32) {
    THIN = 100,
    EXTRA_LIGHT = 200,
    // ULTRA_LIGHT = 200, this enum value conflicts with EXTRA_LIGHT
    LIGHT = 300,
    SEMI_LIGHT = 350,
    NORMAL = 400,
    // REGULAR = 400, this enum value conflicts with NORMAL
    MEDIUM = 500,
    DEMI_BOLD = 600,
    // SEMI_BOLD = 600, this enum value conflicts with DEMI_BOLD
    BOLD = 700,
    EXTRA_BOLD = 800,
    // ULTRA_BOLD = 800, this enum value conflicts with EXTRA_BOLD
    BLACK = 900,
    // HEAVY = 900, this enum value conflicts with BLACK
    EXTRA_BLACK = 950,
    // ULTRA_BLACK = 950, this enum value conflicts with EXTRA_BLACK
};
pub const DWRITE_FONT_WEIGHT_THIN = DWRITE_FONT_WEIGHT.THIN;
pub const DWRITE_FONT_WEIGHT_EXTRA_LIGHT = DWRITE_FONT_WEIGHT.EXTRA_LIGHT;
pub const DWRITE_FONT_WEIGHT_ULTRA_LIGHT = DWRITE_FONT_WEIGHT.EXTRA_LIGHT;
pub const DWRITE_FONT_WEIGHT_LIGHT = DWRITE_FONT_WEIGHT.LIGHT;
pub const DWRITE_FONT_WEIGHT_SEMI_LIGHT = DWRITE_FONT_WEIGHT.SEMI_LIGHT;
pub const DWRITE_FONT_WEIGHT_NORMAL = DWRITE_FONT_WEIGHT.NORMAL;
pub const DWRITE_FONT_WEIGHT_REGULAR = DWRITE_FONT_WEIGHT.NORMAL;
pub const DWRITE_FONT_WEIGHT_MEDIUM = DWRITE_FONT_WEIGHT.MEDIUM;
pub const DWRITE_FONT_WEIGHT_DEMI_BOLD = DWRITE_FONT_WEIGHT.DEMI_BOLD;
pub const DWRITE_FONT_WEIGHT_SEMI_BOLD = DWRITE_FONT_WEIGHT.DEMI_BOLD;
pub const DWRITE_FONT_WEIGHT_BOLD = DWRITE_FONT_WEIGHT.BOLD;
pub const DWRITE_FONT_WEIGHT_EXTRA_BOLD = DWRITE_FONT_WEIGHT.EXTRA_BOLD;
pub const DWRITE_FONT_WEIGHT_ULTRA_BOLD = DWRITE_FONT_WEIGHT.EXTRA_BOLD;
pub const DWRITE_FONT_WEIGHT_BLACK = DWRITE_FONT_WEIGHT.BLACK;
pub const DWRITE_FONT_WEIGHT_HEAVY = DWRITE_FONT_WEIGHT.BLACK;
pub const DWRITE_FONT_WEIGHT_EXTRA_BLACK = DWRITE_FONT_WEIGHT.EXTRA_BLACK;
pub const DWRITE_FONT_WEIGHT_ULTRA_BLACK = DWRITE_FONT_WEIGHT.EXTRA_BLACK;

pub const DWRITE_FONT_STRETCH = enum(i32) {
    UNDEFINED = 0,
    ULTRA_CONDENSED = 1,
    EXTRA_CONDENSED = 2,
    CONDENSED = 3,
    SEMI_CONDENSED = 4,
    NORMAL = 5,
    // MEDIUM = 5, this enum value conflicts with NORMAL
    SEMI_EXPANDED = 6,
    EXPANDED = 7,
    EXTRA_EXPANDED = 8,
    ULTRA_EXPANDED = 9,
};
pub const DWRITE_FONT_STRETCH_UNDEFINED = DWRITE_FONT_STRETCH.UNDEFINED;
pub const DWRITE_FONT_STRETCH_ULTRA_CONDENSED = DWRITE_FONT_STRETCH.ULTRA_CONDENSED;
pub const DWRITE_FONT_STRETCH_EXTRA_CONDENSED = DWRITE_FONT_STRETCH.EXTRA_CONDENSED;
pub const DWRITE_FONT_STRETCH_CONDENSED = DWRITE_FONT_STRETCH.CONDENSED;
pub const DWRITE_FONT_STRETCH_SEMI_CONDENSED = DWRITE_FONT_STRETCH.SEMI_CONDENSED;
pub const DWRITE_FONT_STRETCH_NORMAL = DWRITE_FONT_STRETCH.NORMAL;
pub const DWRITE_FONT_STRETCH_MEDIUM = DWRITE_FONT_STRETCH.NORMAL;
pub const DWRITE_FONT_STRETCH_SEMI_EXPANDED = DWRITE_FONT_STRETCH.SEMI_EXPANDED;
pub const DWRITE_FONT_STRETCH_EXPANDED = DWRITE_FONT_STRETCH.EXPANDED;
pub const DWRITE_FONT_STRETCH_EXTRA_EXPANDED = DWRITE_FONT_STRETCH.EXTRA_EXPANDED;
pub const DWRITE_FONT_STRETCH_ULTRA_EXPANDED = DWRITE_FONT_STRETCH.ULTRA_EXPANDED;

pub const DWRITE_FONT_STYLE = enum(i32) {
    NORMAL = 0,
    OBLIQUE = 1,
    ITALIC = 2,
};
pub const DWRITE_FONT_STYLE_NORMAL = DWRITE_FONT_STYLE.NORMAL;
pub const DWRITE_FONT_STYLE_OBLIQUE = DWRITE_FONT_STYLE.OBLIQUE;
pub const DWRITE_FONT_STYLE_ITALIC = DWRITE_FONT_STYLE.ITALIC;

pub const DWRITE_INFORMATIONAL_STRING_ID = enum(i32) {
    NONE = 0,
    COPYRIGHT_NOTICE = 1,
    VERSION_STRINGS = 2,
    TRADEMARK = 3,
    MANUFACTURER = 4,
    DESIGNER = 5,
    DESIGNER_URL = 6,
    DESCRIPTION = 7,
    FONT_VENDOR_URL = 8,
    LICENSE_DESCRIPTION = 9,
    LICENSE_INFO_URL = 10,
    WIN32_FAMILY_NAMES = 11,
    WIN32_SUBFAMILY_NAMES = 12,
    TYPOGRAPHIC_FAMILY_NAMES = 13,
    TYPOGRAPHIC_SUBFAMILY_NAMES = 14,
    SAMPLE_TEXT = 15,
    FULL_NAME = 16,
    POSTSCRIPT_NAME = 17,
    POSTSCRIPT_CID_NAME = 18,
    WEIGHT_STRETCH_STYLE_FAMILY_NAME = 19,
    DESIGN_SCRIPT_LANGUAGE_TAG = 20,
    SUPPORTED_SCRIPT_LANGUAGE_TAG = 21,
    // PREFERRED_FAMILY_NAMES = 13, this enum value conflicts with TYPOGRAPHIC_FAMILY_NAMES
    // PREFERRED_SUBFAMILY_NAMES = 14, this enum value conflicts with TYPOGRAPHIC_SUBFAMILY_NAMES
    // WWS_FAMILY_NAME = 19, this enum value conflicts with WEIGHT_STRETCH_STYLE_FAMILY_NAME
};
pub const DWRITE_INFORMATIONAL_STRING_NONE = DWRITE_INFORMATIONAL_STRING_ID.NONE;
pub const DWRITE_INFORMATIONAL_STRING_COPYRIGHT_NOTICE = DWRITE_INFORMATIONAL_STRING_ID.COPYRIGHT_NOTICE;
pub const DWRITE_INFORMATIONAL_STRING_VERSION_STRINGS = DWRITE_INFORMATIONAL_STRING_ID.VERSION_STRINGS;
pub const DWRITE_INFORMATIONAL_STRING_TRADEMARK = DWRITE_INFORMATIONAL_STRING_ID.TRADEMARK;
pub const DWRITE_INFORMATIONAL_STRING_MANUFACTURER = DWRITE_INFORMATIONAL_STRING_ID.MANUFACTURER;
pub const DWRITE_INFORMATIONAL_STRING_DESIGNER = DWRITE_INFORMATIONAL_STRING_ID.DESIGNER;
pub const DWRITE_INFORMATIONAL_STRING_DESIGNER_URL = DWRITE_INFORMATIONAL_STRING_ID.DESIGNER_URL;
pub const DWRITE_INFORMATIONAL_STRING_DESCRIPTION = DWRITE_INFORMATIONAL_STRING_ID.DESCRIPTION;
pub const DWRITE_INFORMATIONAL_STRING_FONT_VENDOR_URL = DWRITE_INFORMATIONAL_STRING_ID.FONT_VENDOR_URL;
pub const DWRITE_INFORMATIONAL_STRING_LICENSE_DESCRIPTION = DWRITE_INFORMATIONAL_STRING_ID.LICENSE_DESCRIPTION;
pub const DWRITE_INFORMATIONAL_STRING_LICENSE_INFO_URL = DWRITE_INFORMATIONAL_STRING_ID.LICENSE_INFO_URL;
pub const DWRITE_INFORMATIONAL_STRING_WIN32_FAMILY_NAMES = DWRITE_INFORMATIONAL_STRING_ID.WIN32_FAMILY_NAMES;
pub const DWRITE_INFORMATIONAL_STRING_WIN32_SUBFAMILY_NAMES = DWRITE_INFORMATIONAL_STRING_ID.WIN32_SUBFAMILY_NAMES;
pub const DWRITE_INFORMATIONAL_STRING_TYPOGRAPHIC_FAMILY_NAMES = DWRITE_INFORMATIONAL_STRING_ID.TYPOGRAPHIC_FAMILY_NAMES;
pub const DWRITE_INFORMATIONAL_STRING_TYPOGRAPHIC_SUBFAMILY_NAMES = DWRITE_INFORMATIONAL_STRING_ID.TYPOGRAPHIC_SUBFAMILY_NAMES;
pub const DWRITE_INFORMATIONAL_STRING_SAMPLE_TEXT = DWRITE_INFORMATIONAL_STRING_ID.SAMPLE_TEXT;
pub const DWRITE_INFORMATIONAL_STRING_FULL_NAME = DWRITE_INFORMATIONAL_STRING_ID.FULL_NAME;
pub const DWRITE_INFORMATIONAL_STRING_POSTSCRIPT_NAME = DWRITE_INFORMATIONAL_STRING_ID.POSTSCRIPT_NAME;
pub const DWRITE_INFORMATIONAL_STRING_POSTSCRIPT_CID_NAME = DWRITE_INFORMATIONAL_STRING_ID.POSTSCRIPT_CID_NAME;
pub const DWRITE_INFORMATIONAL_STRING_WEIGHT_STRETCH_STYLE_FAMILY_NAME = DWRITE_INFORMATIONAL_STRING_ID.WEIGHT_STRETCH_STYLE_FAMILY_NAME;
pub const DWRITE_INFORMATIONAL_STRING_DESIGN_SCRIPT_LANGUAGE_TAG = DWRITE_INFORMATIONAL_STRING_ID.DESIGN_SCRIPT_LANGUAGE_TAG;
pub const DWRITE_INFORMATIONAL_STRING_SUPPORTED_SCRIPT_LANGUAGE_TAG = DWRITE_INFORMATIONAL_STRING_ID.SUPPORTED_SCRIPT_LANGUAGE_TAG;
pub const DWRITE_INFORMATIONAL_STRING_PREFERRED_FAMILY_NAMES = DWRITE_INFORMATIONAL_STRING_ID.TYPOGRAPHIC_FAMILY_NAMES;
pub const DWRITE_INFORMATIONAL_STRING_PREFERRED_SUBFAMILY_NAMES = DWRITE_INFORMATIONAL_STRING_ID.TYPOGRAPHIC_SUBFAMILY_NAMES;
pub const DWRITE_INFORMATIONAL_STRING_WWS_FAMILY_NAME = DWRITE_INFORMATIONAL_STRING_ID.WEIGHT_STRETCH_STYLE_FAMILY_NAME;

pub const DWRITE_FONT_METRICS = extern struct {
    designUnitsPerEm: u16,
    ascent: u16,
    descent: u16,
    lineGap: i16,
    capHeight: u16,
    xHeight: u16,
    underlinePosition: i16,
    underlineThickness: u16,
    strikethroughPosition: i16,
    strikethroughThickness: u16,
};

pub const DWRITE_GLYPH_METRICS = extern struct {
    leftSideBearing: i32,
    advanceWidth: u32,
    rightSideBearing: i32,
    topSideBearing: i32,
    advanceHeight: u32,
    bottomSideBearing: i32,
    verticalOriginY: i32,
};

pub const DWRITE_GLYPH_OFFSET = extern struct {
    advanceOffset: f32,
    ascenderOffset: f32,
};

pub const DWRITE_FACTORY_TYPE = enum(i32) {
    SHARED = 0,
    ISOLATED = 1,
};
pub const DWRITE_FACTORY_TYPE_SHARED = DWRITE_FACTORY_TYPE.SHARED;
pub const DWRITE_FACTORY_TYPE_ISOLATED = DWRITE_FACTORY_TYPE.ISOLATED;

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontFileLoader_Value = Guid.initString("727cad4e-d6af-4c9e-8a08-d695b11caa49");
pub const IID_IDWriteFontFileLoader = &IID_IDWriteFontFileLoader_Value;
pub const IDWriteFontFileLoader = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        CreateStreamFromKey: *const fn (
            self: *const IDWriteFontFileLoader,
            // TODO: what to do with BytesParamIndex 1?
            fontFileReferenceKey: ?*const anyopaque,
            fontFileReferenceKeySize: u32,
            fontFileStream: ?*?*IDWriteFontFileStream,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn CreateStreamFromKey(self: *const T, fontFileReferenceKey: ?*const anyopaque, fontFileReferenceKeySize: u32, fontFileStream: ?*?*IDWriteFontFileStream) HRESULT {
                return @as(*const IDWriteFontFileLoader.VTable, @ptrCast(self.vtable)).CreateStreamFromKey(@as(*const IDWriteFontFileLoader, @ptrCast(self)), fontFileReferenceKey, fontFileReferenceKeySize, fontFileStream);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteLocalFontFileLoader_Value = Guid.initString("b2d9f3ec-c9fe-4a11-a2ec-d86208f7c0a2");
pub const IID_IDWriteLocalFontFileLoader = &IID_IDWriteLocalFontFileLoader_Value;
pub const IDWriteLocalFontFileLoader = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFileLoader.VTable,
        GetFilePathLengthFromKey: *const fn (
            self: *const IDWriteLocalFontFileLoader,
            // TODO: what to do with BytesParamIndex 1?
            fontFileReferenceKey: ?*const anyopaque,
            fontFileReferenceKeySize: u32,
            filePathLength: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFilePathFromKey: *const fn (
            self: *const IDWriteLocalFontFileLoader,
            // TODO: what to do with BytesParamIndex 1?
            fontFileReferenceKey: ?*const anyopaque,
            fontFileReferenceKeySize: u32,
            filePath: [*:0]u16,
            filePathSize: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLastWriteTimeFromKey: *const fn (
            self: *const IDWriteLocalFontFileLoader,
            // TODO: what to do with BytesParamIndex 1?
            fontFileReferenceKey: ?*const anyopaque,
            fontFileReferenceKeySize: u32,
            lastWriteTime: ?*FILETIME,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFileLoader.MethodMixin(T);
            pub inline fn GetFilePathLengthFromKey(self: *const T, fontFileReferenceKey: ?*const anyopaque, fontFileReferenceKeySize: u32, filePathLength: ?*u32) HRESULT {
                return @as(*const IDWriteLocalFontFileLoader.VTable, @ptrCast(self.vtable)).GetFilePathLengthFromKey(@as(*const IDWriteLocalFontFileLoader, @ptrCast(self)), fontFileReferenceKey, fontFileReferenceKeySize, filePathLength);
            }
            pub inline fn GetFilePathFromKey(self: *const T, fontFileReferenceKey: ?*const anyopaque, fontFileReferenceKeySize: u32, filePath: [*:0]u16, filePathSize: u32) HRESULT {
                return @as(*const IDWriteLocalFontFileLoader.VTable, @ptrCast(self.vtable)).GetFilePathFromKey(@as(*const IDWriteLocalFontFileLoader, @ptrCast(self)), fontFileReferenceKey, fontFileReferenceKeySize, filePath, filePathSize);
            }
            pub inline fn GetLastWriteTimeFromKey(self: *const T, fontFileReferenceKey: ?*const anyopaque, fontFileReferenceKeySize: u32, lastWriteTime: ?*FILETIME) HRESULT {
                return @as(*const IDWriteLocalFontFileLoader.VTable, @ptrCast(self.vtable)).GetLastWriteTimeFromKey(@as(*const IDWriteLocalFontFileLoader, @ptrCast(self)), fontFileReferenceKey, fontFileReferenceKeySize, lastWriteTime);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontFileStream_Value = Guid.initString("6d4865fe-0ab8-4d91-8f62-5dd6be34a3e0");
pub const IID_IDWriteFontFileStream = &IID_IDWriteFontFileStream_Value;
pub const IDWriteFontFileStream = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        ReadFileFragment: *const fn (
            self: *const IDWriteFontFileStream,
            fragmentStart: ?*const ?*anyopaque,
            fileOffset: u64,
            fragmentSize: u64,
            fragmentContext: ?*?*anyopaque,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        ReleaseFileFragment: *const fn (
            self: *const IDWriteFontFileStream,
            fragmentContext: ?*anyopaque,
        ) callconv(std.os.windows.WINAPI) void,

        GetFileSize: *const fn (
            self: *const IDWriteFontFileStream,
            fileSize: ?*u64,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLastWriteTime: *const fn (
            self: *const IDWriteFontFileStream,
            lastWriteTime: ?*u64,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn ReadFileFragment(self: *const T, fragmentStart: ?*const ?*anyopaque, fileOffset: u64, fragmentSize: u64, fragmentContext: ?*?*anyopaque) HRESULT {
                return @as(*const IDWriteFontFileStream.VTable, @ptrCast(self.vtable)).ReadFileFragment(@as(*const IDWriteFontFileStream, @ptrCast(self)), fragmentStart, fileOffset, fragmentSize, fragmentContext);
            }
            pub inline fn ReleaseFileFragment(self: *const T, fragmentContext: ?*anyopaque) void {
                return @as(*const IDWriteFontFileStream.VTable, @ptrCast(self.vtable)).ReleaseFileFragment(@as(*const IDWriteFontFileStream, @ptrCast(self)), fragmentContext);
            }
            pub inline fn GetFileSize(self: *const T, fileSize: ?*u64) HRESULT {
                return @as(*const IDWriteFontFileStream.VTable, @ptrCast(self.vtable)).GetFileSize(@as(*const IDWriteFontFileStream, @ptrCast(self)), fileSize);
            }
            pub inline fn GetLastWriteTime(self: *const T, lastWriteTime: ?*u64) HRESULT {
                return @as(*const IDWriteFontFileStream.VTable, @ptrCast(self.vtable)).GetLastWriteTime(@as(*const IDWriteFontFileStream, @ptrCast(self)), lastWriteTime);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontFile_Value = Guid.initString("739d886a-cef5-47dc-8769-1a8b41bebbb0");
pub const IID_IDWriteFontFile = &IID_IDWriteFontFile_Value;
pub const IDWriteFontFile = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetReferenceKey: *const fn (
            self: *const IDWriteFontFile,
            fontFileReferenceKey: ?*const ?*anyopaque,
            fontFileReferenceKeySize: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLoader: *const fn (
            self: *const IDWriteFontFile,
            fontFileLoader: ?*?*IDWriteFontFileLoader,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        Analyze: *const fn (
            self: *const IDWriteFontFile,
            isSupportedFontType: ?*BOOL,
            fontFileType: ?*DWRITE_FONT_FILE_TYPE,
            fontFaceType: ?*DWRITE_FONT_FACE_TYPE,
            numberOfFaces: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetReferenceKey(self: *const T, fontFileReferenceKey: ?*const ?*anyopaque, fontFileReferenceKeySize: ?*u32) HRESULT {
                return @as(*const IDWriteFontFile.VTable, @ptrCast(self.vtable)).GetReferenceKey(@as(*const IDWriteFontFile, @ptrCast(self)), fontFileReferenceKey, fontFileReferenceKeySize);
            }
            pub inline fn GetLoader(self: *const T, fontFileLoader: ?*?*IDWriteFontFileLoader) HRESULT {
                return @as(*const IDWriteFontFile.VTable, @ptrCast(self.vtable)).GetLoader(@as(*const IDWriteFontFile, @ptrCast(self)), fontFileLoader);
            }
            pub inline fn Analyze(self: *const T, isSupportedFontType: ?*BOOL, fontFileType: ?*DWRITE_FONT_FILE_TYPE, fontFaceType: ?*DWRITE_FONT_FACE_TYPE, numberOfFaces: ?*u32) HRESULT {
                return @as(*const IDWriteFontFile.VTable, @ptrCast(self.vtable)).Analyze(@as(*const IDWriteFontFile, @ptrCast(self)), isSupportedFontType, fontFileType, fontFaceType, numberOfFaces);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_PIXEL_GEOMETRY = enum(i32) {
    FLAT = 0,
    RGB = 1,
    BGR = 2,
};
pub const DWRITE_PIXEL_GEOMETRY_FLAT = DWRITE_PIXEL_GEOMETRY.FLAT;
pub const DWRITE_PIXEL_GEOMETRY_RGB = DWRITE_PIXEL_GEOMETRY.RGB;
pub const DWRITE_PIXEL_GEOMETRY_BGR = DWRITE_PIXEL_GEOMETRY.BGR;

pub const DWRITE_RENDERING_MODE = enum(i32) {
    DEFAULT = 0,
    ALIASED = 1,
    GDI_CLASSIC = 2,
    GDI_NATURAL = 3,
    NATURAL = 4,
    NATURAL_SYMMETRIC = 5,
    OUTLINE = 6,
    // CLEARTYPE_GDI_CLASSIC = 2, this enum value conflicts with GDI_CLASSIC
    // CLEARTYPE_GDI_NATURAL = 3, this enum value conflicts with GDI_NATURAL
    // CLEARTYPE_NATURAL = 4, this enum value conflicts with NATURAL
    // CLEARTYPE_NATURAL_SYMMETRIC = 5, this enum value conflicts with NATURAL_SYMMETRIC
};
pub const DWRITE_RENDERING_MODE_DEFAULT = DWRITE_RENDERING_MODE.DEFAULT;
pub const DWRITE_RENDERING_MODE_ALIASED = DWRITE_RENDERING_MODE.ALIASED;
pub const DWRITE_RENDERING_MODE_GDI_CLASSIC = DWRITE_RENDERING_MODE.GDI_CLASSIC;
pub const DWRITE_RENDERING_MODE_GDI_NATURAL = DWRITE_RENDERING_MODE.GDI_NATURAL;
pub const DWRITE_RENDERING_MODE_NATURAL = DWRITE_RENDERING_MODE.NATURAL;
pub const DWRITE_RENDERING_MODE_NATURAL_SYMMETRIC = DWRITE_RENDERING_MODE.NATURAL_SYMMETRIC;
pub const DWRITE_RENDERING_MODE_OUTLINE = DWRITE_RENDERING_MODE.OUTLINE;
pub const DWRITE_RENDERING_MODE_CLEARTYPE_GDI_CLASSIC = DWRITE_RENDERING_MODE.GDI_CLASSIC;
pub const DWRITE_RENDERING_MODE_CLEARTYPE_GDI_NATURAL = DWRITE_RENDERING_MODE.GDI_NATURAL;
pub const DWRITE_RENDERING_MODE_CLEARTYPE_NATURAL = DWRITE_RENDERING_MODE.NATURAL;
pub const DWRITE_RENDERING_MODE_CLEARTYPE_NATURAL_SYMMETRIC = DWRITE_RENDERING_MODE.NATURAL_SYMMETRIC;

pub const DWRITE_MATRIX = extern struct {
    m11: f32,
    m12: f32,
    m21: f32,
    m22: f32,
    dx: f32,
    dy: f32,
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteRenderingParams_Value = Guid.initString("2f0da53a-2add-47cd-82ee-d9ec34688e75");
pub const IID_IDWriteRenderingParams = &IID_IDWriteRenderingParams_Value;
pub const IDWriteRenderingParams = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetGamma: *const fn (
            self: *const IDWriteRenderingParams,
        ) callconv(std.os.windows.WINAPI) f32,

        GetEnhancedContrast: *const fn (
            self: *const IDWriteRenderingParams,
        ) callconv(std.os.windows.WINAPI) f32,

        GetClearTypeLevel: *const fn (
            self: *const IDWriteRenderingParams,
        ) callconv(std.os.windows.WINAPI) f32,

        GetPixelGeometry: *const fn (
            self: *const IDWriteRenderingParams,
        ) callconv(std.os.windows.WINAPI) DWRITE_PIXEL_GEOMETRY,

        GetRenderingMode: *const fn (
            self: *const IDWriteRenderingParams,
        ) callconv(std.os.windows.WINAPI) DWRITE_RENDERING_MODE,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetGamma(self: *const T) f32 {
                return @as(*const IDWriteRenderingParams.VTable, @ptrCast(self.vtable)).GetGamma(@as(*const IDWriteRenderingParams, @ptrCast(self)));
            }
            pub inline fn GetEnhancedContrast(self: *const T) f32 {
                return @as(*const IDWriteRenderingParams.VTable, @ptrCast(self.vtable)).GetEnhancedContrast(@as(*const IDWriteRenderingParams, @ptrCast(self)));
            }
            pub inline fn GetClearTypeLevel(self: *const T) f32 {
                return @as(*const IDWriteRenderingParams.VTable, @ptrCast(self.vtable)).GetClearTypeLevel(@as(*const IDWriteRenderingParams, @ptrCast(self)));
            }
            pub inline fn GetPixelGeometry(self: *const T) DWRITE_PIXEL_GEOMETRY {
                return @as(*const IDWriteRenderingParams.VTable, @ptrCast(self.vtable)).GetPixelGeometry(@as(*const IDWriteRenderingParams, @ptrCast(self)));
            }
            pub inline fn GetRenderingMode(self: *const T) DWRITE_RENDERING_MODE {
                return @as(*const IDWriteRenderingParams.VTable, @ptrCast(self.vtable)).GetRenderingMode(@as(*const IDWriteRenderingParams, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontFace_Value = Guid.initString("5f49804d-7024-4d43-bfa9-d25984f53849");
pub const IID_IDWriteFontFace = &IID_IDWriteFontFace_Value;
pub const IDWriteFontFace = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetType: *const fn (
            self: *const IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_FACE_TYPE,

        GetFiles: *const fn (
            self: *const IDWriteFontFace,
            numberOfFiles: ?*u32,
            fontFiles: ?[*]?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetIndex: *const fn (
            self: *const IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) u32,

        GetSimulations: *const fn (
            self: *const IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_SIMULATIONS,

        IsSymbolFont: *const fn (
            self: *const IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetMetrics: *const fn (
            self: *const IDWriteFontFace,
            fontFaceMetrics: ?*DWRITE_FONT_METRICS,
        ) callconv(std.os.windows.WINAPI) void,

        GetGlyphCount: *const fn (
            self: *const IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) u16,

        GetDesignGlyphMetrics: *const fn (
            self: *const IDWriteFontFace,
            glyphIndices: [*:0]const u16,
            glyphCount: u32,
            glyphMetrics: [*]DWRITE_GLYPH_METRICS,
            isSideways: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGlyphIndices: *const fn (
            self: *const IDWriteFontFace,
            codePoints: [*]const u32,
            codePointCount: u32,
            glyphIndices: [*:0]u16,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        TryGetFontTable: *const fn (
            self: *const IDWriteFontFace,
            openTypeTableTag: u32,
            tableData: ?*const ?*anyopaque,
            tableSize: ?*u32,
            tableContext: ?*?*anyopaque,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        ReleaseFontTable: *const fn (
            self: *const IDWriteFontFace,
            tableContext: ?*anyopaque,
        ) callconv(std.os.windows.WINAPI) void,

        GetGlyphRunOutline: *const fn (
            self: *const IDWriteFontFace,
            emSize: f32,
            glyphIndices: [*:0]const u16,
            glyphAdvances: ?[*]const f32,
            glyphOffsets: ?[*]const DWRITE_GLYPH_OFFSET,
            glyphCount: u32,
            isSideways: BOOL,
            isRightToLeft: BOOL,
            /// ID2D1SimplifiedGeometrySink isn't used in this API;
            geometrySink: ?*anyopaque,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetRecommendedRenderingMode: *const fn (
            self: *const IDWriteFontFace,
            emSize: f32,
            pixelsPerDip: f32,
            measuringMode: DWRITE_MEASURING_MODE,
            renderingParams: ?*IDWriteRenderingParams,
            renderingMode: ?*DWRITE_RENDERING_MODE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGdiCompatibleMetrics: *const fn (
            self: *const IDWriteFontFace,
            emSize: f32,
            pixelsPerDip: f32,
            transform: ?*const DWRITE_MATRIX,
            fontFaceMetrics: ?*DWRITE_FONT_METRICS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGdiCompatibleGlyphMetrics: *const fn (
            self: *const IDWriteFontFace,
            emSize: f32,
            pixelsPerDip: f32,
            transform: ?*const DWRITE_MATRIX,
            useGdiNatural: BOOL,
            glyphIndices: [*:0]const u16,
            glyphCount: u32,
            glyphMetrics: [*]DWRITE_GLYPH_METRICS,
            isSideways: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetType(self: *const T) DWRITE_FONT_FACE_TYPE {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetType(@as(*const IDWriteFontFace, @ptrCast(self)));
            }
            pub inline fn GetFiles(self: *const T, numberOfFiles: ?*u32, fontFiles: ?[*]?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetFiles(@as(*const IDWriteFontFace, @ptrCast(self)), numberOfFiles, fontFiles);
            }
            pub inline fn GetIndex(self: *const T) u32 {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetIndex(@as(*const IDWriteFontFace, @ptrCast(self)));
            }
            pub inline fn GetSimulations(self: *const T) DWRITE_FONT_SIMULATIONS {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetSimulations(@as(*const IDWriteFontFace, @ptrCast(self)));
            }
            pub inline fn IsSymbolFont(self: *const T) BOOL {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).IsSymbolFont(@as(*const IDWriteFontFace, @ptrCast(self)));
            }
            pub inline fn GetMetrics(self: *const T, fontFaceMetrics: ?*DWRITE_FONT_METRICS) void {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetMetrics(@as(*const IDWriteFontFace, @ptrCast(self)), fontFaceMetrics);
            }
            pub inline fn GetGlyphCount(self: *const T) u16 {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetGlyphCount(@as(*const IDWriteFontFace, @ptrCast(self)));
            }
            pub inline fn GetDesignGlyphMetrics(self: *const T, glyphIndices: [*:0]const u16, glyphCount: u32, glyphMetrics: [*]DWRITE_GLYPH_METRICS, isSideways: BOOL) HRESULT {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetDesignGlyphMetrics(@as(*const IDWriteFontFace, @ptrCast(self)), glyphIndices, glyphCount, glyphMetrics, isSideways);
            }
            pub inline fn GetGlyphIndices(self: *const T, codePoints: [*]const u32, codePointCount: u32, glyphIndices: [*:0]u16) HRESULT {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetGlyphIndices(@as(*const IDWriteFontFace, @ptrCast(self)), codePoints, codePointCount, glyphIndices);
            }
            pub inline fn TryGetFontTable(self: *const T, openTypeTableTag: u32, tableData: ?*const ?*anyopaque, tableSize: ?*u32, tableContext: ?*?*anyopaque, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).TryGetFontTable(@as(*const IDWriteFontFace, @ptrCast(self)), openTypeTableTag, tableData, tableSize, tableContext, exists);
            }
            pub inline fn ReleaseFontTable(self: *const T, tableContext: ?*anyopaque) void {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).ReleaseFontTable(@as(*const IDWriteFontFace, @ptrCast(self)), tableContext);
            }
            pub inline fn GetRecommendedRenderingMode(self: *const T, emSize: f32, pixelsPerDip: f32, measuringMode: DWRITE_MEASURING_MODE, renderingParams: ?*IDWriteRenderingParams, renderingMode: ?*DWRITE_RENDERING_MODE) HRESULT {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetRecommendedRenderingMode(@as(*const IDWriteFontFace, @ptrCast(self)), emSize, pixelsPerDip, measuringMode, renderingParams, renderingMode);
            }
            pub inline fn GetGdiCompatibleMetrics(self: *const T, emSize: f32, pixelsPerDip: f32, transform: ?*const DWRITE_MATRIX, fontFaceMetrics: ?*DWRITE_FONT_METRICS) HRESULT {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetGdiCompatibleMetrics(@as(*const IDWriteFontFace, @ptrCast(self)), emSize, pixelsPerDip, transform, fontFaceMetrics);
            }
            pub inline fn GetGdiCompatibleGlyphMetrics(self: *const T, emSize: f32, pixelsPerDip: f32, transform: ?*const DWRITE_MATRIX, useGdiNatural: BOOL, glyphIndices: [*:0]const u16, glyphCount: u32, glyphMetrics: [*]DWRITE_GLYPH_METRICS, isSideways: BOOL) HRESULT {
                return @as(*const IDWriteFontFace.VTable, @ptrCast(self.vtable)).GetGdiCompatibleGlyphMetrics(@as(*const IDWriteFontFace, @ptrCast(self)), emSize, pixelsPerDip, transform, useGdiNatural, glyphIndices, glyphCount, glyphMetrics, isSideways);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontCollectionLoader_Value = Guid.initString("cca920e4-52f0-492b-bfa8-29c72ee0a468");
pub const IID_IDWriteFontCollectionLoader = &IID_IDWriteFontCollectionLoader_Value;
pub const IDWriteFontCollectionLoader = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        CreateEnumeratorFromKey: *const fn (
            self: *const IDWriteFontCollectionLoader,
            factory: ?*IDWriteFactory,
            // TODO: what to do with BytesParamIndex 2?
            collectionKey: ?*const anyopaque,
            collectionKeySize: u32,
            fontFileEnumerator: ?*?*IDWriteFontFileEnumerator,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn CreateEnumeratorFromKey(self: *const T, factory: ?*IDWriteFactory, collectionKey: ?*const anyopaque, collectionKeySize: u32, fontFileEnumerator: ?*?*IDWriteFontFileEnumerator) HRESULT {
                return @as(*const IDWriteFontCollectionLoader.VTable, @ptrCast(self.vtable)).CreateEnumeratorFromKey(@as(*const IDWriteFontCollectionLoader, @ptrCast(self)), factory, collectionKey, collectionKeySize, fontFileEnumerator);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontFileEnumerator_Value = Guid.initString("72755049-5ff7-435d-8348-4be97cfa6c7c");
pub const IID_IDWriteFontFileEnumerator = &IID_IDWriteFontFileEnumerator_Value;
pub const IDWriteFontFileEnumerator = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        MoveNext: *const fn (
            self: *const IDWriteFontFileEnumerator,
            hasCurrentFile: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetCurrentFontFile: *const fn (
            self: *const IDWriteFontFileEnumerator,
            fontFile: ?*?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn MoveNext(self: *const T, hasCurrentFile: ?*BOOL) HRESULT {
                return @as(*const IDWriteFontFileEnumerator.VTable, @ptrCast(self.vtable)).MoveNext(@as(*const IDWriteFontFileEnumerator, @ptrCast(self)), hasCurrentFile);
            }
            pub inline fn GetCurrentFontFile(self: *const T, fontFile: ?*?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteFontFileEnumerator.VTable, @ptrCast(self.vtable)).GetCurrentFontFile(@as(*const IDWriteFontFileEnumerator, @ptrCast(self)), fontFile);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteLocalizedStrings_Value = Guid.initString("08256209-099a-4b34-b86d-c22b110e7771");
pub const IID_IDWriteLocalizedStrings = &IID_IDWriteLocalizedStrings_Value;
pub const IDWriteLocalizedStrings = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetCount: *const fn (
            self: *const IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) u32,

        FindLocaleName: *const fn (
            self: *const IDWriteLocalizedStrings,
            localeName: ?[*:0]const u16,
            index: ?*u32,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocaleNameLength: *const fn (
            self: *const IDWriteLocalizedStrings,
            index: u32,
            length: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocaleName: *const fn (
            self: *const IDWriteLocalizedStrings,
            index: u32,
            localeName: [*:0]u16,
            size: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetStringLength: *const fn (
            self: *const IDWriteLocalizedStrings,
            index: u32,
            length: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetString: *const fn (
            self: *const IDWriteLocalizedStrings,
            index: u32,
            stringBuffer: [*:0]u16,
            size: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetCount(self: *const T) u32 {
                return @as(*const IDWriteLocalizedStrings.VTable, @ptrCast(self.vtable)).GetCount(@as(*const IDWriteLocalizedStrings, @ptrCast(self)));
            }
            pub inline fn FindLocaleName(self: *const T, localeName: ?[*:0]const u16, index: ?*u32, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteLocalizedStrings.VTable, @ptrCast(self.vtable)).FindLocaleName(@as(*const IDWriteLocalizedStrings, @ptrCast(self)), localeName, index, exists);
            }
            pub inline fn GetLocaleNameLength(self: *const T, index: u32, length: ?*u32) HRESULT {
                return @as(*const IDWriteLocalizedStrings.VTable, @ptrCast(self.vtable)).GetLocaleNameLength(@as(*const IDWriteLocalizedStrings, @ptrCast(self)), index, length);
            }
            pub inline fn GetLocaleName(self: *const T, index: u32, localeName: [*:0]u16, size: u32) HRESULT {
                return @as(*const IDWriteLocalizedStrings.VTable, @ptrCast(self.vtable)).GetLocaleName(@as(*const IDWriteLocalizedStrings, @ptrCast(self)), index, localeName, size);
            }
            pub inline fn GetStringLength(self: *const T, index: u32, length: ?*u32) HRESULT {
                return @as(*const IDWriteLocalizedStrings.VTable, @ptrCast(self.vtable)).GetStringLength(@as(*const IDWriteLocalizedStrings, @ptrCast(self)), index, length);
            }
            pub inline fn GetString(self: *const T, index: u32, stringBuffer: [*:0]u16, size: u32) HRESULT {
                return @as(*const IDWriteLocalizedStrings.VTable, @ptrCast(self.vtable)).GetString(@as(*const IDWriteLocalizedStrings, @ptrCast(self)), index, stringBuffer, size);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontCollection_Value = Guid.initString("a84cee02-3eea-4eee-a827-87c1a02a0fcc");
pub const IID_IDWriteFontCollection = &IID_IDWriteFontCollection_Value;
pub const IDWriteFontCollection = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetFontFamilyCount: *const fn (
            self: *const IDWriteFontCollection,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontFamily: *const fn (
            self: *const IDWriteFontCollection,
            index: u32,
            fontFamily: ?*?*IDWriteFontFamily,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        FindFamilyName: *const fn (
            self: *const IDWriteFontCollection,
            familyName: ?[*:0]const u16,
            index: ?*u32,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFromFontFace: *const fn (
            self: *const IDWriteFontCollection,
            fontFace: ?*IDWriteFontFace,
            font: ?*?*IDWriteFont,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetFontFamilyCount(self: *const T) u32 {
                return @as(*const IDWriteFontCollection.VTable, @ptrCast(self.vtable)).GetFontFamilyCount(@as(*const IDWriteFontCollection, @ptrCast(self)));
            }
            pub inline fn GetFontFamily(self: *const T, index: u32, fontFamily: ?*?*IDWriteFontFamily) HRESULT {
                return @as(*const IDWriteFontCollection.VTable, @ptrCast(self.vtable)).GetFontFamily(@as(*const IDWriteFontCollection, @ptrCast(self)), index, fontFamily);
            }
            pub inline fn FindFamilyName(self: *const T, familyName: ?[*:0]const u16, index: ?*u32, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteFontCollection.VTable, @ptrCast(self.vtable)).FindFamilyName(@as(*const IDWriteFontCollection, @ptrCast(self)), familyName, index, exists);
            }
            pub inline fn GetFontFromFontFace(self: *const T, fontFace: ?*IDWriteFontFace, font: ?*?*IDWriteFont) HRESULT {
                return @as(*const IDWriteFontCollection.VTable, @ptrCast(self.vtable)).GetFontFromFontFace(@as(*const IDWriteFontCollection, @ptrCast(self)), fontFace, font);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontList_Value = Guid.initString("1a0d8438-1d97-4ec1-aef9-a2fb86ed6acb");
pub const IID_IDWriteFontList = &IID_IDWriteFontList_Value;
pub const IDWriteFontList = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetFontCollection: *const fn (
            self: *const IDWriteFontList,
            fontCollection: ?*?*IDWriteFontCollection,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontCount: *const fn (
            self: *const IDWriteFontList,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFont: *const fn (
            self: *const IDWriteFontList,
            index: u32,
            font: ?*?*IDWriteFont,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetFontCollection(self: *const T, fontCollection: ?*?*IDWriteFontCollection) HRESULT {
                return @as(*const IDWriteFontList.VTable, @ptrCast(self.vtable)).GetFontCollection(@as(*const IDWriteFontList, @ptrCast(self)), fontCollection);
            }
            pub inline fn GetFontCount(self: *const T) u32 {
                return @as(*const IDWriteFontList.VTable, @ptrCast(self.vtable)).GetFontCount(@as(*const IDWriteFontList, @ptrCast(self)));
            }
            pub inline fn GetFont(self: *const T, index: u32, font: ?*?*IDWriteFont) HRESULT {
                return @as(*const IDWriteFontList.VTable, @ptrCast(self.vtable)).GetFont(@as(*const IDWriteFontList, @ptrCast(self)), index, font);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontFamily_Value = Guid.initString("da20d8ef-812a-4c43-9802-62ec4abd7add");
pub const IID_IDWriteFontFamily = &IID_IDWriteFontFamily_Value;
pub const IDWriteFontFamily = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontList.VTable,
        GetFamilyNames: *const fn (
            self: *const IDWriteFontFamily,
            names: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFirstMatchingFont: *const fn (
            self: *const IDWriteFontFamily,
            weight: DWRITE_FONT_WEIGHT,
            stretch: DWRITE_FONT_STRETCH,
            style: DWRITE_FONT_STYLE,
            matchingFont: ?*?*IDWriteFont,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMatchingFonts: *const fn (
            self: *const IDWriteFontFamily,
            weight: DWRITE_FONT_WEIGHT,
            stretch: DWRITE_FONT_STRETCH,
            style: DWRITE_FONT_STYLE,
            matchingFonts: ?*?*IDWriteFontList,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontList.MethodMixin(T);
            pub inline fn GetFamilyNames(self: *const T, names: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFontFamily.VTable, @ptrCast(self.vtable)).GetFamilyNames(@as(*const IDWriteFontFamily, @ptrCast(self)), names);
            }
            pub inline fn GetFirstMatchingFont(self: *const T, weight: DWRITE_FONT_WEIGHT, stretch: DWRITE_FONT_STRETCH, style: DWRITE_FONT_STYLE, matchingFont: ?*?*IDWriteFont) HRESULT {
                return @as(*const IDWriteFontFamily.VTable, @ptrCast(self.vtable)).GetFirstMatchingFont(@as(*const IDWriteFontFamily, @ptrCast(self)), weight, stretch, style, matchingFont);
            }
            pub inline fn GetMatchingFonts(self: *const T, weight: DWRITE_FONT_WEIGHT, stretch: DWRITE_FONT_STRETCH, style: DWRITE_FONT_STYLE, matchingFonts: ?*?*IDWriteFontList) HRESULT {
                return @as(*const IDWriteFontFamily.VTable, @ptrCast(self.vtable)).GetMatchingFonts(@as(*const IDWriteFontFamily, @ptrCast(self)), weight, stretch, style, matchingFonts);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFont_Value = Guid.initString("acd16696-8c14-4f5d-877e-fe3fc1d32737");
pub const IID_IDWriteFont = &IID_IDWriteFont_Value;
pub const IDWriteFont = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetFontFamily: *const fn (
            self: *const IDWriteFont,
            fontFamily: ?*?*IDWriteFontFamily,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetWeight: *const fn (
            self: *const IDWriteFont,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_WEIGHT,

        GetStretch: *const fn (
            self: *const IDWriteFont,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_STRETCH,

        GetStyle: *const fn (
            self: *const IDWriteFont,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_STYLE,

        IsSymbolFont: *const fn (
            self: *const IDWriteFont,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetFaceNames: *const fn (
            self: *const IDWriteFont,
            names: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetInformationalStrings: *const fn (
            self: *const IDWriteFont,
            informationalStringID: DWRITE_INFORMATIONAL_STRING_ID,
            informationalStrings: ?*?*IDWriteLocalizedStrings,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetSimulations: *const fn (
            self: *const IDWriteFont,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_SIMULATIONS,

        GetMetrics: *const fn (
            self: *const IDWriteFont,
            fontMetrics: ?*DWRITE_FONT_METRICS,
        ) callconv(std.os.windows.WINAPI) void,

        HasCharacter: *const fn (
            self: *const IDWriteFont,
            unicodeValue: u32,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFace: *const fn (
            self: *const IDWriteFont,
            fontFace: ?*?*IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetFontFamily(self: *const T, fontFamily: ?*?*IDWriteFontFamily) HRESULT {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).GetFontFamily(@as(*const IDWriteFont, @ptrCast(self)), fontFamily);
            }
            pub inline fn GetWeight(self: *const T) DWRITE_FONT_WEIGHT {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).GetWeight(@as(*const IDWriteFont, @ptrCast(self)));
            }
            pub inline fn GetStretch(self: *const T) DWRITE_FONT_STRETCH {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).GetStretch(@as(*const IDWriteFont, @ptrCast(self)));
            }
            pub inline fn GetStyle(self: *const T) DWRITE_FONT_STYLE {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).GetStyle(@as(*const IDWriteFont, @ptrCast(self)));
            }
            pub inline fn IsSymbolFont(self: *const T) BOOL {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).IsSymbolFont(@as(*const IDWriteFont, @ptrCast(self)));
            }
            pub inline fn GetFaceNames(self: *const T, names: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).GetFaceNames(@as(*const IDWriteFont, @ptrCast(self)), names);
            }
            pub inline fn GetInformationalStrings(self: *const T, informationalStringID: DWRITE_INFORMATIONAL_STRING_ID, informationalStrings: ?*?*IDWriteLocalizedStrings, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).GetInformationalStrings(@as(*const IDWriteFont, @ptrCast(self)), informationalStringID, informationalStrings, exists);
            }
            pub inline fn GetSimulations(self: *const T) DWRITE_FONT_SIMULATIONS {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).GetSimulations(@as(*const IDWriteFont, @ptrCast(self)));
            }
            pub inline fn GetMetrics(self: *const T, fontMetrics: ?*DWRITE_FONT_METRICS) void {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).GetMetrics(@as(*const IDWriteFont, @ptrCast(self)), fontMetrics);
            }
            pub inline fn HasCharacter(self: *const T, unicodeValue: u32, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).HasCharacter(@as(*const IDWriteFont, @ptrCast(self)), unicodeValue, exists);
            }
            pub inline fn CreateFontFace(self: *const T, fontFace: ?*?*IDWriteFontFace) HRESULT {
                return @as(*const IDWriteFont.VTable, @ptrCast(self.vtable)).CreateFontFace(@as(*const IDWriteFont, @ptrCast(self)), fontFace);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_READING_DIRECTION = enum(i32) {
    LEFT_TO_RIGHT = 0,
    RIGHT_TO_LEFT = 1,
    TOP_TO_BOTTOM = 2,
    BOTTOM_TO_TOP = 3,
};
pub const DWRITE_READING_DIRECTION_LEFT_TO_RIGHT = DWRITE_READING_DIRECTION.LEFT_TO_RIGHT;
pub const DWRITE_READING_DIRECTION_RIGHT_TO_LEFT = DWRITE_READING_DIRECTION.RIGHT_TO_LEFT;
pub const DWRITE_READING_DIRECTION_TOP_TO_BOTTOM = DWRITE_READING_DIRECTION.TOP_TO_BOTTOM;
pub const DWRITE_READING_DIRECTION_BOTTOM_TO_TOP = DWRITE_READING_DIRECTION.BOTTOM_TO_TOP;

pub const DWRITE_FLOW_DIRECTION = enum(i32) {
    TOP_TO_BOTTOM = 0,
    BOTTOM_TO_TOP = 1,
    LEFT_TO_RIGHT = 2,
    RIGHT_TO_LEFT = 3,
};
pub const DWRITE_FLOW_DIRECTION_TOP_TO_BOTTOM = DWRITE_FLOW_DIRECTION.TOP_TO_BOTTOM;
pub const DWRITE_FLOW_DIRECTION_BOTTOM_TO_TOP = DWRITE_FLOW_DIRECTION.BOTTOM_TO_TOP;
pub const DWRITE_FLOW_DIRECTION_LEFT_TO_RIGHT = DWRITE_FLOW_DIRECTION.LEFT_TO_RIGHT;
pub const DWRITE_FLOW_DIRECTION_RIGHT_TO_LEFT = DWRITE_FLOW_DIRECTION.RIGHT_TO_LEFT;

pub const DWRITE_TEXT_ALIGNMENT = enum(i32) {
    LEADING = 0,
    TRAILING = 1,
    CENTER = 2,
    JUSTIFIED = 3,
};
pub const DWRITE_TEXT_ALIGNMENT_LEADING = DWRITE_TEXT_ALIGNMENT.LEADING;
pub const DWRITE_TEXT_ALIGNMENT_TRAILING = DWRITE_TEXT_ALIGNMENT.TRAILING;
pub const DWRITE_TEXT_ALIGNMENT_CENTER = DWRITE_TEXT_ALIGNMENT.CENTER;
pub const DWRITE_TEXT_ALIGNMENT_JUSTIFIED = DWRITE_TEXT_ALIGNMENT.JUSTIFIED;

pub const DWRITE_PARAGRAPH_ALIGNMENT = enum(i32) {
    NEAR = 0,
    FAR = 1,
    CENTER = 2,
};
pub const DWRITE_PARAGRAPH_ALIGNMENT_NEAR = DWRITE_PARAGRAPH_ALIGNMENT.NEAR;
pub const DWRITE_PARAGRAPH_ALIGNMENT_FAR = DWRITE_PARAGRAPH_ALIGNMENT.FAR;
pub const DWRITE_PARAGRAPH_ALIGNMENT_CENTER = DWRITE_PARAGRAPH_ALIGNMENT.CENTER;

pub const DWRITE_WORD_WRAPPING = enum(i32) {
    WRAP = 0,
    NO_WRAP = 1,
    EMERGENCY_BREAK = 2,
    WHOLE_WORD = 3,
    CHARACTER = 4,
};
pub const DWRITE_WORD_WRAPPING_WRAP = DWRITE_WORD_WRAPPING.WRAP;
pub const DWRITE_WORD_WRAPPING_NO_WRAP = DWRITE_WORD_WRAPPING.NO_WRAP;
pub const DWRITE_WORD_WRAPPING_EMERGENCY_BREAK = DWRITE_WORD_WRAPPING.EMERGENCY_BREAK;
pub const DWRITE_WORD_WRAPPING_WHOLE_WORD = DWRITE_WORD_WRAPPING.WHOLE_WORD;
pub const DWRITE_WORD_WRAPPING_CHARACTER = DWRITE_WORD_WRAPPING.CHARACTER;

pub const DWRITE_LINE_SPACING_METHOD = enum(i32) {
    DEFAULT = 0,
    UNIFORM = 1,
    PROPORTIONAL = 2,
};
pub const DWRITE_LINE_SPACING_METHOD_DEFAULT = DWRITE_LINE_SPACING_METHOD.DEFAULT;
pub const DWRITE_LINE_SPACING_METHOD_UNIFORM = DWRITE_LINE_SPACING_METHOD.UNIFORM;
pub const DWRITE_LINE_SPACING_METHOD_PROPORTIONAL = DWRITE_LINE_SPACING_METHOD.PROPORTIONAL;

pub const DWRITE_TRIMMING_GRANULARITY = enum(i32) {
    NONE = 0,
    CHARACTER = 1,
    WORD = 2,
};
pub const DWRITE_TRIMMING_GRANULARITY_NONE = DWRITE_TRIMMING_GRANULARITY.NONE;
pub const DWRITE_TRIMMING_GRANULARITY_CHARACTER = DWRITE_TRIMMING_GRANULARITY.CHARACTER;
pub const DWRITE_TRIMMING_GRANULARITY_WORD = DWRITE_TRIMMING_GRANULARITY.WORD;

pub const DWRITE_FONT_FEATURE_TAG = enum(u32) {
    ALTERNATIVE_FRACTIONS = 1668441697,
    PETITE_CAPITALS_FROM_CAPITALS = 1668297315,
    SMALL_CAPITALS_FROM_CAPITALS = 1668493923,
    CONTEXTUAL_ALTERNATES = 1953259875,
    CASE_SENSITIVE_FORMS = 1702060387,
    GLYPH_COMPOSITION_DECOMPOSITION = 1886217059,
    CONTEXTUAL_LIGATURES = 1734962275,
    CAPITAL_SPACING = 1886613603,
    CONTEXTUAL_SWASH = 1752658787,
    CURSIVE_POSITIONING = 1936880995,
    DEFAULT = 1953261156,
    DISCRETIONARY_LIGATURES = 1734962276,
    EXPERT_FORMS = 1953527909,
    FRACTIONS = 1667330662,
    FULL_WIDTH = 1684633446,
    HALF_FORMS = 1718378856,
    HALANT_FORMS = 1852596584,
    ALTERNATE_HALF_WIDTH = 1953259880,
    HISTORICAL_FORMS = 1953720680,
    HORIZONTAL_KANA_ALTERNATES = 1634626408,
    HISTORICAL_LIGATURES = 1734962280,
    HALF_WIDTH = 1684633448,
    HOJO_KANJI_FORMS = 1869246312,
    JIS04_FORMS = 875589738,
    JIS78_FORMS = 943157354,
    JIS83_FORMS = 859336810,
    JIS90_FORMS = 809070698,
    KERNING = 1852990827,
    STANDARD_LIGATURES = 1634167148,
    LINING_FIGURES = 1836412524,
    LOCALIZED_FORMS = 1818455916,
    MARK_POSITIONING = 1802658157,
    MATHEMATICAL_GREEK = 1802659693,
    MARK_TO_MARK_POSITIONING = 1802333037,
    ALTERNATE_ANNOTATION_FORMS = 1953259886,
    NLC_KANJI_FORMS = 1801677934,
    OLD_STYLE_FIGURES = 1836412527,
    ORDINALS = 1852076655,
    PROPORTIONAL_ALTERNATE_WIDTH = 1953259888,
    PETITE_CAPITALS = 1885430640,
    PROPORTIONAL_FIGURES = 1836412528,
    PROPORTIONAL_WIDTHS = 1684633456,
    QUARTER_WIDTHS = 1684633457,
    REQUIRED_LIGATURES = 1734962290,
    RUBY_NOTATION_FORMS = 2036495730,
    STYLISTIC_ALTERNATES = 1953259891,
    SCIENTIFIC_INFERIORS = 1718511987,
    SMALL_CAPITALS = 1885564275,
    SIMPLIFIED_FORMS = 1819307379,
    STYLISTIC_SET_1 = 825258867,
    STYLISTIC_SET_2 = 842036083,
    STYLISTIC_SET_3 = 858813299,
    STYLISTIC_SET_4 = 875590515,
    STYLISTIC_SET_5 = 892367731,
    STYLISTIC_SET_6 = 909144947,
    STYLISTIC_SET_7 = 925922163,
    STYLISTIC_SET_8 = 942699379,
    STYLISTIC_SET_9 = 959476595,
    STYLISTIC_SET_10 = 808547187,
    STYLISTIC_SET_11 = 825324403,
    STYLISTIC_SET_12 = 842101619,
    STYLISTIC_SET_13 = 858878835,
    STYLISTIC_SET_14 = 875656051,
    STYLISTIC_SET_15 = 892433267,
    STYLISTIC_SET_16 = 909210483,
    STYLISTIC_SET_17 = 925987699,
    STYLISTIC_SET_18 = 942764915,
    STYLISTIC_SET_19 = 959542131,
    STYLISTIC_SET_20 = 808612723,
    SUBSCRIPT = 1935832435,
    SUPERSCRIPT = 1936749939,
    SWASH = 1752397683,
    TITLING = 1819568500,
    TRADITIONAL_NAME_FORMS = 1835101812,
    TABULAR_FIGURES = 1836412532,
    TRADITIONAL_FORMS = 1684107892,
    THIRD_WIDTHS = 1684633460,
    UNICASE = 1667853941,
    VERTICAL_WRITING = 1953654134,
    VERTICAL_ALTERNATES_AND_ROTATION = 846492278,
    SLASHED_ZERO = 1869768058,
};
pub const DWRITE_FONT_FEATURE_TAG_ALTERNATIVE_FRACTIONS = DWRITE_FONT_FEATURE_TAG.ALTERNATIVE_FRACTIONS;
pub const DWRITE_FONT_FEATURE_TAG_PETITE_CAPITALS_FROM_CAPITALS = DWRITE_FONT_FEATURE_TAG.PETITE_CAPITALS_FROM_CAPITALS;
pub const DWRITE_FONT_FEATURE_TAG_SMALL_CAPITALS_FROM_CAPITALS = DWRITE_FONT_FEATURE_TAG.SMALL_CAPITALS_FROM_CAPITALS;
pub const DWRITE_FONT_FEATURE_TAG_CONTEXTUAL_ALTERNATES = DWRITE_FONT_FEATURE_TAG.CONTEXTUAL_ALTERNATES;
pub const DWRITE_FONT_FEATURE_TAG_CASE_SENSITIVE_FORMS = DWRITE_FONT_FEATURE_TAG.CASE_SENSITIVE_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_GLYPH_COMPOSITION_DECOMPOSITION = DWRITE_FONT_FEATURE_TAG.GLYPH_COMPOSITION_DECOMPOSITION;
pub const DWRITE_FONT_FEATURE_TAG_CONTEXTUAL_LIGATURES = DWRITE_FONT_FEATURE_TAG.CONTEXTUAL_LIGATURES;
pub const DWRITE_FONT_FEATURE_TAG_CAPITAL_SPACING = DWRITE_FONT_FEATURE_TAG.CAPITAL_SPACING;
pub const DWRITE_FONT_FEATURE_TAG_CONTEXTUAL_SWASH = DWRITE_FONT_FEATURE_TAG.CONTEXTUAL_SWASH;
pub const DWRITE_FONT_FEATURE_TAG_CURSIVE_POSITIONING = DWRITE_FONT_FEATURE_TAG.CURSIVE_POSITIONING;
pub const DWRITE_FONT_FEATURE_TAG_DEFAULT = DWRITE_FONT_FEATURE_TAG.DEFAULT;
pub const DWRITE_FONT_FEATURE_TAG_DISCRETIONARY_LIGATURES = DWRITE_FONT_FEATURE_TAG.DISCRETIONARY_LIGATURES;
pub const DWRITE_FONT_FEATURE_TAG_EXPERT_FORMS = DWRITE_FONT_FEATURE_TAG.EXPERT_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_FRACTIONS = DWRITE_FONT_FEATURE_TAG.FRACTIONS;
pub const DWRITE_FONT_FEATURE_TAG_FULL_WIDTH = DWRITE_FONT_FEATURE_TAG.FULL_WIDTH;
pub const DWRITE_FONT_FEATURE_TAG_HALF_FORMS = DWRITE_FONT_FEATURE_TAG.HALF_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_HALANT_FORMS = DWRITE_FONT_FEATURE_TAG.HALANT_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_ALTERNATE_HALF_WIDTH = DWRITE_FONT_FEATURE_TAG.ALTERNATE_HALF_WIDTH;
pub const DWRITE_FONT_FEATURE_TAG_HISTORICAL_FORMS = DWRITE_FONT_FEATURE_TAG.HISTORICAL_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_HORIZONTAL_KANA_ALTERNATES = DWRITE_FONT_FEATURE_TAG.HORIZONTAL_KANA_ALTERNATES;
pub const DWRITE_FONT_FEATURE_TAG_HISTORICAL_LIGATURES = DWRITE_FONT_FEATURE_TAG.HISTORICAL_LIGATURES;
pub const DWRITE_FONT_FEATURE_TAG_HALF_WIDTH = DWRITE_FONT_FEATURE_TAG.HALF_WIDTH;
pub const DWRITE_FONT_FEATURE_TAG_HOJO_KANJI_FORMS = DWRITE_FONT_FEATURE_TAG.HOJO_KANJI_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_JIS04_FORMS = DWRITE_FONT_FEATURE_TAG.JIS04_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_JIS78_FORMS = DWRITE_FONT_FEATURE_TAG.JIS78_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_JIS83_FORMS = DWRITE_FONT_FEATURE_TAG.JIS83_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_JIS90_FORMS = DWRITE_FONT_FEATURE_TAG.JIS90_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_KERNING = DWRITE_FONT_FEATURE_TAG.KERNING;
pub const DWRITE_FONT_FEATURE_TAG_STANDARD_LIGATURES = DWRITE_FONT_FEATURE_TAG.STANDARD_LIGATURES;
pub const DWRITE_FONT_FEATURE_TAG_LINING_FIGURES = DWRITE_FONT_FEATURE_TAG.LINING_FIGURES;
pub const DWRITE_FONT_FEATURE_TAG_LOCALIZED_FORMS = DWRITE_FONT_FEATURE_TAG.LOCALIZED_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_MARK_POSITIONING = DWRITE_FONT_FEATURE_TAG.MARK_POSITIONING;
pub const DWRITE_FONT_FEATURE_TAG_MATHEMATICAL_GREEK = DWRITE_FONT_FEATURE_TAG.MATHEMATICAL_GREEK;
pub const DWRITE_FONT_FEATURE_TAG_MARK_TO_MARK_POSITIONING = DWRITE_FONT_FEATURE_TAG.MARK_TO_MARK_POSITIONING;
pub const DWRITE_FONT_FEATURE_TAG_ALTERNATE_ANNOTATION_FORMS = DWRITE_FONT_FEATURE_TAG.ALTERNATE_ANNOTATION_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_NLC_KANJI_FORMS = DWRITE_FONT_FEATURE_TAG.NLC_KANJI_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_OLD_STYLE_FIGURES = DWRITE_FONT_FEATURE_TAG.OLD_STYLE_FIGURES;
pub const DWRITE_FONT_FEATURE_TAG_ORDINALS = DWRITE_FONT_FEATURE_TAG.ORDINALS;
pub const DWRITE_FONT_FEATURE_TAG_PROPORTIONAL_ALTERNATE_WIDTH = DWRITE_FONT_FEATURE_TAG.PROPORTIONAL_ALTERNATE_WIDTH;
pub const DWRITE_FONT_FEATURE_TAG_PETITE_CAPITALS = DWRITE_FONT_FEATURE_TAG.PETITE_CAPITALS;
pub const DWRITE_FONT_FEATURE_TAG_PROPORTIONAL_FIGURES = DWRITE_FONT_FEATURE_TAG.PROPORTIONAL_FIGURES;
pub const DWRITE_FONT_FEATURE_TAG_PROPORTIONAL_WIDTHS = DWRITE_FONT_FEATURE_TAG.PROPORTIONAL_WIDTHS;
pub const DWRITE_FONT_FEATURE_TAG_QUARTER_WIDTHS = DWRITE_FONT_FEATURE_TAG.QUARTER_WIDTHS;
pub const DWRITE_FONT_FEATURE_TAG_REQUIRED_LIGATURES = DWRITE_FONT_FEATURE_TAG.REQUIRED_LIGATURES;
pub const DWRITE_FONT_FEATURE_TAG_RUBY_NOTATION_FORMS = DWRITE_FONT_FEATURE_TAG.RUBY_NOTATION_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_ALTERNATES = DWRITE_FONT_FEATURE_TAG.STYLISTIC_ALTERNATES;
pub const DWRITE_FONT_FEATURE_TAG_SCIENTIFIC_INFERIORS = DWRITE_FONT_FEATURE_TAG.SCIENTIFIC_INFERIORS;
pub const DWRITE_FONT_FEATURE_TAG_SMALL_CAPITALS = DWRITE_FONT_FEATURE_TAG.SMALL_CAPITALS;
pub const DWRITE_FONT_FEATURE_TAG_SIMPLIFIED_FORMS = DWRITE_FONT_FEATURE_TAG.SIMPLIFIED_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_1 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_1;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_2 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_2;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_3 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_3;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_4 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_4;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_5 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_5;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_6 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_6;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_7 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_7;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_8 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_8;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_9 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_9;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_10 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_10;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_11 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_11;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_12 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_12;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_13 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_13;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_14 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_14;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_15 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_15;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_16 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_16;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_17 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_17;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_18 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_18;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_19 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_19;
pub const DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_20 = DWRITE_FONT_FEATURE_TAG.STYLISTIC_SET_20;
pub const DWRITE_FONT_FEATURE_TAG_SUBSCRIPT = DWRITE_FONT_FEATURE_TAG.SUBSCRIPT;
pub const DWRITE_FONT_FEATURE_TAG_SUPERSCRIPT = DWRITE_FONT_FEATURE_TAG.SUPERSCRIPT;
pub const DWRITE_FONT_FEATURE_TAG_SWASH = DWRITE_FONT_FEATURE_TAG.SWASH;
pub const DWRITE_FONT_FEATURE_TAG_TITLING = DWRITE_FONT_FEATURE_TAG.TITLING;
pub const DWRITE_FONT_FEATURE_TAG_TRADITIONAL_NAME_FORMS = DWRITE_FONT_FEATURE_TAG.TRADITIONAL_NAME_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_TABULAR_FIGURES = DWRITE_FONT_FEATURE_TAG.TABULAR_FIGURES;
pub const DWRITE_FONT_FEATURE_TAG_TRADITIONAL_FORMS = DWRITE_FONT_FEATURE_TAG.TRADITIONAL_FORMS;
pub const DWRITE_FONT_FEATURE_TAG_THIRD_WIDTHS = DWRITE_FONT_FEATURE_TAG.THIRD_WIDTHS;
pub const DWRITE_FONT_FEATURE_TAG_UNICASE = DWRITE_FONT_FEATURE_TAG.UNICASE;
pub const DWRITE_FONT_FEATURE_TAG_VERTICAL_WRITING = DWRITE_FONT_FEATURE_TAG.VERTICAL_WRITING;
pub const DWRITE_FONT_FEATURE_TAG_VERTICAL_ALTERNATES_AND_ROTATION = DWRITE_FONT_FEATURE_TAG.VERTICAL_ALTERNATES_AND_ROTATION;
pub const DWRITE_FONT_FEATURE_TAG_SLASHED_ZERO = DWRITE_FONT_FEATURE_TAG.SLASHED_ZERO;

pub const DWRITE_TEXT_RANGE = extern struct {
    startPosition: u32,
    length: u32,
};

pub const DWRITE_FONT_FEATURE = extern struct {
    nameTag: DWRITE_FONT_FEATURE_TAG,
    parameter: u32,
};

pub const DWRITE_TYPOGRAPHIC_FEATURES = extern struct {
    features: ?*DWRITE_FONT_FEATURE,
    featureCount: u32,
};

pub const DWRITE_TRIMMING = extern struct {
    granularity: DWRITE_TRIMMING_GRANULARITY,
    delimiter: u32,
    delimiterCount: u32,
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteTextFormat_Value = Guid.initString("9c906818-31d7-4fd3-a151-7c5e225db55a");
pub const IID_IDWriteTextFormat = &IID_IDWriteTextFormat_Value;
pub const IDWriteTextFormat = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        SetTextAlignment: *const fn (
            self: *const IDWriteTextFormat,
            textAlignment: DWRITE_TEXT_ALIGNMENT,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetParagraphAlignment: *const fn (
            self: *const IDWriteTextFormat,
            paragraphAlignment: DWRITE_PARAGRAPH_ALIGNMENT,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetWordWrapping: *const fn (
            self: *const IDWriteTextFormat,
            wordWrapping: DWRITE_WORD_WRAPPING,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetReadingDirection: *const fn (
            self: *const IDWriteTextFormat,
            readingDirection: DWRITE_READING_DIRECTION,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetFlowDirection: *const fn (
            self: *const IDWriteTextFormat,
            flowDirection: DWRITE_FLOW_DIRECTION,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetIncrementalTabStop: *const fn (
            self: *const IDWriteTextFormat,
            incrementalTabStop: f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetTrimming: *const fn (
            self: *const IDWriteTextFormat,
            trimmingOptions: ?*const DWRITE_TRIMMING,
            trimmingSign: ?*IDWriteInlineObject,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetLineSpacing: *const fn (
            self: *const IDWriteTextFormat,
            lineSpacingMethod: DWRITE_LINE_SPACING_METHOD,
            lineSpacing: f32,
            baseline: f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetTextAlignment: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) DWRITE_TEXT_ALIGNMENT,

        GetParagraphAlignment: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) DWRITE_PARAGRAPH_ALIGNMENT,

        GetWordWrapping: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) DWRITE_WORD_WRAPPING,

        GetReadingDirection: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) DWRITE_READING_DIRECTION,

        GetFlowDirection: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) DWRITE_FLOW_DIRECTION,

        GetIncrementalTabStop: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) f32,

        GetTrimming: *const fn (
            self: *const IDWriteTextFormat,
            trimmingOptions: ?*DWRITE_TRIMMING,
            trimmingSign: ?*?*IDWriteInlineObject,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLineSpacing: *const fn (
            self: *const IDWriteTextFormat,
            lineSpacingMethod: ?*DWRITE_LINE_SPACING_METHOD,
            lineSpacing: ?*f32,
            baseline: ?*f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontCollection: *const fn (
            self: *const IDWriteTextFormat,
            fontCollection: ?*?*IDWriteFontCollection,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFamilyNameLength: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontFamilyName: *const fn (
            self: *const IDWriteTextFormat,
            fontFamilyName: [*:0]u16,
            nameSize: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontWeight: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_WEIGHT,

        GetFontStyle: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_STYLE,

        GetFontStretch: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_STRETCH,

        GetFontSize: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) f32,

        GetLocaleNameLength: *const fn (
            self: *const IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) u32,

        GetLocaleName: *const fn (
            self: *const IDWriteTextFormat,
            localeName: [*:0]u16,
            nameSize: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn SetTextAlignment(self: *const T, textAlignment: DWRITE_TEXT_ALIGNMENT) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).SetTextAlignment(@as(*const IDWriteTextFormat, @ptrCast(self)), textAlignment);
            }
            pub inline fn SetParagraphAlignment(self: *const T, paragraphAlignment: DWRITE_PARAGRAPH_ALIGNMENT) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).SetParagraphAlignment(@as(*const IDWriteTextFormat, @ptrCast(self)), paragraphAlignment);
            }
            pub inline fn SetWordWrapping(self: *const T, wordWrapping: DWRITE_WORD_WRAPPING) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).SetWordWrapping(@as(*const IDWriteTextFormat, @ptrCast(self)), wordWrapping);
            }
            pub inline fn SetReadingDirection(self: *const T, readingDirection: DWRITE_READING_DIRECTION) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).SetReadingDirection(@as(*const IDWriteTextFormat, @ptrCast(self)), readingDirection);
            }
            pub inline fn SetFlowDirection(self: *const T, flowDirection: DWRITE_FLOW_DIRECTION) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).SetFlowDirection(@as(*const IDWriteTextFormat, @ptrCast(self)), flowDirection);
            }
            pub inline fn SetIncrementalTabStop(self: *const T, incrementalTabStop: f32) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).SetIncrementalTabStop(@as(*const IDWriteTextFormat, @ptrCast(self)), incrementalTabStop);
            }
            pub inline fn SetTrimming(self: *const T, trimmingOptions: ?*const DWRITE_TRIMMING, trimmingSign: ?*IDWriteInlineObject) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).SetTrimming(@as(*const IDWriteTextFormat, @ptrCast(self)), trimmingOptions, trimmingSign);
            }
            pub inline fn SetLineSpacing(self: *const T, lineSpacingMethod: DWRITE_LINE_SPACING_METHOD, lineSpacing: f32, baseline: f32) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).SetLineSpacing(@as(*const IDWriteTextFormat, @ptrCast(self)), lineSpacingMethod, lineSpacing, baseline);
            }
            pub inline fn GetTextAlignment(self: *const T) DWRITE_TEXT_ALIGNMENT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetTextAlignment(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetParagraphAlignment(self: *const T) DWRITE_PARAGRAPH_ALIGNMENT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetParagraphAlignment(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetWordWrapping(self: *const T) DWRITE_WORD_WRAPPING {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetWordWrapping(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetReadingDirection(self: *const T) DWRITE_READING_DIRECTION {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetReadingDirection(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetFlowDirection(self: *const T) DWRITE_FLOW_DIRECTION {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetFlowDirection(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetIncrementalTabStop(self: *const T) f32 {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetIncrementalTabStop(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetTrimming(self: *const T, trimmingOptions: ?*DWRITE_TRIMMING, trimmingSign: ?*?*IDWriteInlineObject) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetTrimming(@as(*const IDWriteTextFormat, @ptrCast(self)), trimmingOptions, trimmingSign);
            }
            pub inline fn GetLineSpacing(self: *const T, lineSpacingMethod: ?*DWRITE_LINE_SPACING_METHOD, lineSpacing: ?*f32, baseline: ?*f32) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetLineSpacing(@as(*const IDWriteTextFormat, @ptrCast(self)), lineSpacingMethod, lineSpacing, baseline);
            }
            pub inline fn GetFontCollection(self: *const T, fontCollection: ?*?*IDWriteFontCollection) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetFontCollection(@as(*const IDWriteTextFormat, @ptrCast(self)), fontCollection);
            }
            pub inline fn GetFontFamilyNameLength(self: *const T) u32 {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetFontFamilyNameLength(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetFontFamilyName(self: *const T, fontFamilyName: [*:0]u16, nameSize: u32) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetFontFamilyName(@as(*const IDWriteTextFormat, @ptrCast(self)), fontFamilyName, nameSize);
            }
            pub inline fn GetFontWeight(self: *const T) DWRITE_FONT_WEIGHT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetFontWeight(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetFontStyle(self: *const T) DWRITE_FONT_STYLE {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetFontStyle(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetFontStretch(self: *const T) DWRITE_FONT_STRETCH {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetFontStretch(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetFontSize(self: *const T) f32 {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetFontSize(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetLocaleNameLength(self: *const T) u32 {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetLocaleNameLength(@as(*const IDWriteTextFormat, @ptrCast(self)));
            }
            pub inline fn GetLocaleName(self: *const T, localeName: [*:0]u16, nameSize: u32) HRESULT {
                return @as(*const IDWriteTextFormat.VTable, @ptrCast(self.vtable)).GetLocaleName(@as(*const IDWriteTextFormat, @ptrCast(self)), localeName, nameSize);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteTypography_Value = Guid.initString("55f1112b-1dc2-4b3c-9541-f46894ed85b6");
pub const IID_IDWriteTypography = &IID_IDWriteTypography_Value;
pub const IDWriteTypography = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        AddFontFeature: *const fn (
            self: *const IDWriteTypography,
            fontFeature: DWRITE_FONT_FEATURE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFeatureCount: *const fn (
            self: *const IDWriteTypography,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontFeature: *const fn (
            self: *const IDWriteTypography,
            fontFeatureIndex: u32,
            fontFeature: ?*DWRITE_FONT_FEATURE,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn AddFontFeature(self: *const T, fontFeature: DWRITE_FONT_FEATURE) HRESULT {
                return @as(*const IDWriteTypography.VTable, @ptrCast(self.vtable)).AddFontFeature(@as(*const IDWriteTypography, @ptrCast(self)), fontFeature);
            }
            pub inline fn GetFontFeatureCount(self: *const T) u32 {
                return @as(*const IDWriteTypography.VTable, @ptrCast(self.vtable)).GetFontFeatureCount(@as(*const IDWriteTypography, @ptrCast(self)));
            }
            pub inline fn GetFontFeature(self: *const T, fontFeatureIndex: u32, fontFeature: ?*DWRITE_FONT_FEATURE) HRESULT {
                return @as(*const IDWriteTypography.VTable, @ptrCast(self.vtable)).GetFontFeature(@as(*const IDWriteTypography, @ptrCast(self)), fontFeatureIndex, fontFeature);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_SCRIPT_SHAPES = enum(u32) {
    DEFAULT = 0,
    NO_VISUAL = 1,
    _,
    pub fn initFlags(o: struct {
        DEFAULT: u1 = 0,
        NO_VISUAL: u1 = 0,
    }) DWRITE_SCRIPT_SHAPES {
        return @as(DWRITE_SCRIPT_SHAPES, @enumFromInt((if (o.DEFAULT == 1) @intFromEnum(DWRITE_SCRIPT_SHAPES.DEFAULT) else 0) | (if (o.NO_VISUAL == 1) @intFromEnum(DWRITE_SCRIPT_SHAPES.NO_VISUAL) else 0)));
    }
};
pub const DWRITE_SCRIPT_SHAPES_DEFAULT = DWRITE_SCRIPT_SHAPES.DEFAULT;
pub const DWRITE_SCRIPT_SHAPES_NO_VISUAL = DWRITE_SCRIPT_SHAPES.NO_VISUAL;

pub const DWRITE_SCRIPT_ANALYSIS = extern struct {
    script: u16,
    shapes: DWRITE_SCRIPT_SHAPES,
};

pub const DWRITE_BREAK_CONDITION = enum(i32) {
    NEUTRAL = 0,
    CAN_BREAK = 1,
    MAY_NOT_BREAK = 2,
    MUST_BREAK = 3,
};
pub const DWRITE_BREAK_CONDITION_NEUTRAL = DWRITE_BREAK_CONDITION.NEUTRAL;
pub const DWRITE_BREAK_CONDITION_CAN_BREAK = DWRITE_BREAK_CONDITION.CAN_BREAK;
pub const DWRITE_BREAK_CONDITION_MAY_NOT_BREAK = DWRITE_BREAK_CONDITION.MAY_NOT_BREAK;
pub const DWRITE_BREAK_CONDITION_MUST_BREAK = DWRITE_BREAK_CONDITION.MUST_BREAK;

pub const DWRITE_LINE_BREAKPOINT = extern struct {
    _bitfield: u8,
};

pub const DWRITE_NUMBER_SUBSTITUTION_METHOD = enum(i32) {
    FROM_CULTURE = 0,
    CONTEXTUAL = 1,
    NONE = 2,
    NATIONAL = 3,
    TRADITIONAL = 4,
};
pub const DWRITE_NUMBER_SUBSTITUTION_METHOD_FROM_CULTURE = DWRITE_NUMBER_SUBSTITUTION_METHOD.FROM_CULTURE;
pub const DWRITE_NUMBER_SUBSTITUTION_METHOD_CONTEXTUAL = DWRITE_NUMBER_SUBSTITUTION_METHOD.CONTEXTUAL;
pub const DWRITE_NUMBER_SUBSTITUTION_METHOD_NONE = DWRITE_NUMBER_SUBSTITUTION_METHOD.NONE;
pub const DWRITE_NUMBER_SUBSTITUTION_METHOD_NATIONAL = DWRITE_NUMBER_SUBSTITUTION_METHOD.NATIONAL;
pub const DWRITE_NUMBER_SUBSTITUTION_METHOD_TRADITIONAL = DWRITE_NUMBER_SUBSTITUTION_METHOD.TRADITIONAL;

const IID_IDWriteNumberSubstitution_Value = Guid.initString("14885cc9-bab0-4f90-b6ed-5c366a2cd03d");
pub const IID_IDWriteNumberSubstitution = &IID_IDWriteNumberSubstitution_Value;
pub const IDWriteNumberSubstitution = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_SHAPING_TEXT_PROPERTIES = extern struct {
    _bitfield: u16,
};

pub const DWRITE_SHAPING_GLYPH_PROPERTIES = extern struct {
    _bitfield: u16,
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteTextAnalysisSource_Value = Guid.initString("688e1a58-5094-47c8-adc8-fbcea60ae92b");
pub const IID_IDWriteTextAnalysisSource = &IID_IDWriteTextAnalysisSource_Value;
pub const IDWriteTextAnalysisSource = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetTextAtPosition: *const fn (
            self: *const IDWriteTextAnalysisSource,
            textPosition: u32,
            textString: ?*const ?*u16,
            textLength: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetTextBeforePosition: *const fn (
            self: *const IDWriteTextAnalysisSource,
            textPosition: u32,
            textString: ?*const ?*u16,
            textLength: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetParagraphReadingDirection: *const fn (
            self: *const IDWriteTextAnalysisSource,
        ) callconv(std.os.windows.WINAPI) DWRITE_READING_DIRECTION,

        GetLocaleName: *const fn (
            self: *const IDWriteTextAnalysisSource,
            textPosition: u32,
            textLength: ?*u32,
            localeName: ?*const ?*u16,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetNumberSubstitution: *const fn (
            self: *const IDWriteTextAnalysisSource,
            textPosition: u32,
            textLength: ?*u32,
            numberSubstitution: ?*?*IDWriteNumberSubstitution,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetTextAtPosition(self: *const T, textPosition: u32, textString: ?*const ?*u16, textLength: ?*u32) HRESULT {
                return @as(*const IDWriteTextAnalysisSource.VTable, @ptrCast(self.vtable)).GetTextAtPosition(@as(*const IDWriteTextAnalysisSource, @ptrCast(self)), textPosition, textString, textLength);
            }
            pub inline fn GetTextBeforePosition(self: *const T, textPosition: u32, textString: ?*const ?*u16, textLength: ?*u32) HRESULT {
                return @as(*const IDWriteTextAnalysisSource.VTable, @ptrCast(self.vtable)).GetTextBeforePosition(@as(*const IDWriteTextAnalysisSource, @ptrCast(self)), textPosition, textString, textLength);
            }
            pub inline fn GetParagraphReadingDirection(self: *const T) DWRITE_READING_DIRECTION {
                return @as(*const IDWriteTextAnalysisSource.VTable, @ptrCast(self.vtable)).GetParagraphReadingDirection(@as(*const IDWriteTextAnalysisSource, @ptrCast(self)));
            }
            pub inline fn GetLocaleName(self: *const T, textPosition: u32, textLength: ?*u32, localeName: ?*const ?*u16) HRESULT {
                return @as(*const IDWriteTextAnalysisSource.VTable, @ptrCast(self.vtable)).GetLocaleName(@as(*const IDWriteTextAnalysisSource, @ptrCast(self)), textPosition, textLength, localeName);
            }
            pub inline fn GetNumberSubstitution(self: *const T, textPosition: u32, textLength: ?*u32, numberSubstitution: ?*?*IDWriteNumberSubstitution) HRESULT {
                return @as(*const IDWriteTextAnalysisSource.VTable, @ptrCast(self.vtable)).GetNumberSubstitution(@as(*const IDWriteTextAnalysisSource, @ptrCast(self)), textPosition, textLength, numberSubstitution);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteTextAnalysisSink_Value = Guid.initString("5810cd44-0ca0-4701-b3fa-bec5182ae4f6");
pub const IID_IDWriteTextAnalysisSink = &IID_IDWriteTextAnalysisSink_Value;
pub const IDWriteTextAnalysisSink = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        SetScriptAnalysis: *const fn (
            self: *const IDWriteTextAnalysisSink,
            textPosition: u32,
            textLength: u32,
            scriptAnalysis: ?*const DWRITE_SCRIPT_ANALYSIS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetLineBreakpoints: *const fn (
            self: *const IDWriteTextAnalysisSink,
            textPosition: u32,
            textLength: u32,
            lineBreakpoints: [*]const DWRITE_LINE_BREAKPOINT,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetBidiLevel: *const fn (
            self: *const IDWriteTextAnalysisSink,
            textPosition: u32,
            textLength: u32,
            explicitLevel: u8,
            resolvedLevel: u8,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetNumberSubstitution: *const fn (
            self: *const IDWriteTextAnalysisSink,
            textPosition: u32,
            textLength: u32,
            numberSubstitution: ?*IDWriteNumberSubstitution,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn SetScriptAnalysis(self: *const T, textPosition: u32, textLength: u32, scriptAnalysis: ?*const DWRITE_SCRIPT_ANALYSIS) HRESULT {
                return @as(*const IDWriteTextAnalysisSink.VTable, @ptrCast(self.vtable)).SetScriptAnalysis(@as(*const IDWriteTextAnalysisSink, @ptrCast(self)), textPosition, textLength, scriptAnalysis);
            }
            pub inline fn SetLineBreakpoints(self: *const T, textPosition: u32, textLength: u32, lineBreakpoints: [*]const DWRITE_LINE_BREAKPOINT) HRESULT {
                return @as(*const IDWriteTextAnalysisSink.VTable, @ptrCast(self.vtable)).SetLineBreakpoints(@as(*const IDWriteTextAnalysisSink, @ptrCast(self)), textPosition, textLength, lineBreakpoints);
            }
            pub inline fn SetBidiLevel(self: *const T, textPosition: u32, textLength: u32, explicitLevel: u8, resolvedLevel: u8) HRESULT {
                return @as(*const IDWriteTextAnalysisSink.VTable, @ptrCast(self.vtable)).SetBidiLevel(@as(*const IDWriteTextAnalysisSink, @ptrCast(self)), textPosition, textLength, explicitLevel, resolvedLevel);
            }
            pub inline fn SetNumberSubstitution(self: *const T, textPosition: u32, textLength: u32, numberSubstitution: ?*IDWriteNumberSubstitution) HRESULT {
                return @as(*const IDWriteTextAnalysisSink.VTable, @ptrCast(self.vtable)).SetNumberSubstitution(@as(*const IDWriteTextAnalysisSink, @ptrCast(self)), textPosition, textLength, numberSubstitution);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteTextAnalyzer_Value = Guid.initString("b7e6163e-7f46-43b4-84b3-e4e6249c365d");
pub const IID_IDWriteTextAnalyzer = &IID_IDWriteTextAnalyzer_Value;
pub const IDWriteTextAnalyzer = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        AnalyzeScript: *const fn (
            self: *const IDWriteTextAnalyzer,
            analysisSource: ?*IDWriteTextAnalysisSource,
            textPosition: u32,
            textLength: u32,
            analysisSink: ?*IDWriteTextAnalysisSink,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AnalyzeBidi: *const fn (
            self: *const IDWriteTextAnalyzer,
            analysisSource: ?*IDWriteTextAnalysisSource,
            textPosition: u32,
            textLength: u32,
            analysisSink: ?*IDWriteTextAnalysisSink,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AnalyzeNumberSubstitution: *const fn (
            self: *const IDWriteTextAnalyzer,
            analysisSource: ?*IDWriteTextAnalysisSource,
            textPosition: u32,
            textLength: u32,
            analysisSink: ?*IDWriteTextAnalysisSink,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AnalyzeLineBreakpoints: *const fn (
            self: *const IDWriteTextAnalyzer,
            analysisSource: ?*IDWriteTextAnalysisSource,
            textPosition: u32,
            textLength: u32,
            analysisSink: ?*IDWriteTextAnalysisSink,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGlyphs: *const fn (
            self: *const IDWriteTextAnalyzer,
            textString: [*:0]const u16,
            textLength: u32,
            fontFace: ?*IDWriteFontFace,
            isSideways: BOOL,
            isRightToLeft: BOOL,
            scriptAnalysis: ?*const DWRITE_SCRIPT_ANALYSIS,
            localeName: ?[*:0]const u16,
            numberSubstitution: ?*IDWriteNumberSubstitution,
            features: ?[*]const ?*const DWRITE_TYPOGRAPHIC_FEATURES,
            featureRangeLengths: ?[*]const u32,
            featureRanges: u32,
            maxGlyphCount: u32,
            clusterMap: [*:0]u16,
            textProps: [*]DWRITE_SHAPING_TEXT_PROPERTIES,
            glyphIndices: [*:0]u16,
            glyphProps: [*]DWRITE_SHAPING_GLYPH_PROPERTIES,
            actualGlyphCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGlyphPlacements: *const fn (
            self: *const IDWriteTextAnalyzer,
            textString: [*:0]const u16,
            clusterMap: [*:0]const u16,
            textProps: [*]DWRITE_SHAPING_TEXT_PROPERTIES,
            textLength: u32,
            glyphIndices: [*:0]const u16,
            glyphProps: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES,
            glyphCount: u32,
            fontFace: ?*IDWriteFontFace,
            fontEmSize: f32,
            isSideways: BOOL,
            isRightToLeft: BOOL,
            scriptAnalysis: ?*const DWRITE_SCRIPT_ANALYSIS,
            localeName: ?[*:0]const u16,
            features: ?[*]const ?*const DWRITE_TYPOGRAPHIC_FEATURES,
            featureRangeLengths: ?[*]const u32,
            featureRanges: u32,
            glyphAdvances: [*]f32,
            glyphOffsets: [*]DWRITE_GLYPH_OFFSET,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGdiCompatibleGlyphPlacements: *const fn (
            self: *const IDWriteTextAnalyzer,
            textString: [*:0]const u16,
            clusterMap: [*:0]const u16,
            textProps: [*]DWRITE_SHAPING_TEXT_PROPERTIES,
            textLength: u32,
            glyphIndices: [*:0]const u16,
            glyphProps: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES,
            glyphCount: u32,
            fontFace: ?*IDWriteFontFace,
            fontEmSize: f32,
            pixelsPerDip: f32,
            transform: ?*const DWRITE_MATRIX,
            useGdiNatural: BOOL,
            isSideways: BOOL,
            isRightToLeft: BOOL,
            scriptAnalysis: ?*const DWRITE_SCRIPT_ANALYSIS,
            localeName: ?[*:0]const u16,
            features: ?[*]const ?*const DWRITE_TYPOGRAPHIC_FEATURES,
            featureRangeLengths: ?[*]const u32,
            featureRanges: u32,
            glyphAdvances: [*]f32,
            glyphOffsets: [*]DWRITE_GLYPH_OFFSET,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn AnalyzeScript(self: *const T, analysisSource: ?*IDWriteTextAnalysisSource, textPosition: u32, textLength: u32, analysisSink: ?*IDWriteTextAnalysisSink) HRESULT {
                return @as(*const IDWriteTextAnalyzer.VTable, @ptrCast(self.vtable)).AnalyzeScript(@as(*const IDWriteTextAnalyzer, @ptrCast(self)), analysisSource, textPosition, textLength, analysisSink);
            }
            pub inline fn AnalyzeBidi(self: *const T, analysisSource: ?*IDWriteTextAnalysisSource, textPosition: u32, textLength: u32, analysisSink: ?*IDWriteTextAnalysisSink) HRESULT {
                return @as(*const IDWriteTextAnalyzer.VTable, @ptrCast(self.vtable)).AnalyzeBidi(@as(*const IDWriteTextAnalyzer, @ptrCast(self)), analysisSource, textPosition, textLength, analysisSink);
            }
            pub inline fn AnalyzeNumberSubstitution(self: *const T, analysisSource: ?*IDWriteTextAnalysisSource, textPosition: u32, textLength: u32, analysisSink: ?*IDWriteTextAnalysisSink) HRESULT {
                return @as(*const IDWriteTextAnalyzer.VTable, @ptrCast(self.vtable)).AnalyzeNumberSubstitution(@as(*const IDWriteTextAnalyzer, @ptrCast(self)), analysisSource, textPosition, textLength, analysisSink);
            }
            pub inline fn AnalyzeLineBreakpoints(self: *const T, analysisSource: ?*IDWriteTextAnalysisSource, textPosition: u32, textLength: u32, analysisSink: ?*IDWriteTextAnalysisSink) HRESULT {
                return @as(*const IDWriteTextAnalyzer.VTable, @ptrCast(self.vtable)).AnalyzeLineBreakpoints(@as(*const IDWriteTextAnalyzer, @ptrCast(self)), analysisSource, textPosition, textLength, analysisSink);
            }
            pub inline fn GetGlyphs(self: *const T, textString: [*:0]const u16, textLength: u32, fontFace: ?*IDWriteFontFace, isSideways: BOOL, isRightToLeft: BOOL, scriptAnalysis: ?*const DWRITE_SCRIPT_ANALYSIS, localeName: ?[*:0]const u16, numberSubstitution: ?*IDWriteNumberSubstitution, features: ?[*]const ?*const DWRITE_TYPOGRAPHIC_FEATURES, featureRangeLengths: ?[*]const u32, featureRanges: u32, maxGlyphCount: u32, clusterMap: [*:0]u16, textProps: [*]DWRITE_SHAPING_TEXT_PROPERTIES, glyphIndices: [*:0]u16, glyphProps: [*]DWRITE_SHAPING_GLYPH_PROPERTIES, actualGlyphCount: ?*u32) HRESULT {
                return @as(*const IDWriteTextAnalyzer.VTable, @ptrCast(self.vtable)).GetGlyphs(@as(*const IDWriteTextAnalyzer, @ptrCast(self)), textString, textLength, fontFace, isSideways, isRightToLeft, scriptAnalysis, localeName, numberSubstitution, features, featureRangeLengths, featureRanges, maxGlyphCount, clusterMap, textProps, glyphIndices, glyphProps, actualGlyphCount);
            }
            pub inline fn GetGlyphPlacements(self: *const T, textString: [*:0]const u16, clusterMap: [*:0]const u16, textProps: [*]DWRITE_SHAPING_TEXT_PROPERTIES, textLength: u32, glyphIndices: [*:0]const u16, glyphProps: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES, glyphCount: u32, fontFace: ?*IDWriteFontFace, fontEmSize: f32, isSideways: BOOL, isRightToLeft: BOOL, scriptAnalysis: ?*const DWRITE_SCRIPT_ANALYSIS, localeName: ?[*:0]const u16, features: ?[*]const ?*const DWRITE_TYPOGRAPHIC_FEATURES, featureRangeLengths: ?[*]const u32, featureRanges: u32, glyphAdvances: [*]f32, glyphOffsets: [*]DWRITE_GLYPH_OFFSET) HRESULT {
                return @as(*const IDWriteTextAnalyzer.VTable, @ptrCast(self.vtable)).GetGlyphPlacements(@as(*const IDWriteTextAnalyzer, @ptrCast(self)), textString, clusterMap, textProps, textLength, glyphIndices, glyphProps, glyphCount, fontFace, fontEmSize, isSideways, isRightToLeft, scriptAnalysis, localeName, features, featureRangeLengths, featureRanges, glyphAdvances, glyphOffsets);
            }
            pub inline fn GetGdiCompatibleGlyphPlacements(self: *const T, textString: [*:0]const u16, clusterMap: [*:0]const u16, textProps: [*]DWRITE_SHAPING_TEXT_PROPERTIES, textLength: u32, glyphIndices: [*:0]const u16, glyphProps: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES, glyphCount: u32, fontFace: ?*IDWriteFontFace, fontEmSize: f32, pixelsPerDip: f32, transform: ?*const DWRITE_MATRIX, useGdiNatural: BOOL, isSideways: BOOL, isRightToLeft: BOOL, scriptAnalysis: ?*const DWRITE_SCRIPT_ANALYSIS, localeName: ?[*:0]const u16, features: ?[*]const ?*const DWRITE_TYPOGRAPHIC_FEATURES, featureRangeLengths: ?[*]const u32, featureRanges: u32, glyphAdvances: [*]f32, glyphOffsets: [*]DWRITE_GLYPH_OFFSET) HRESULT {
                return @as(*const IDWriteTextAnalyzer.VTable, @ptrCast(self.vtable)).GetGdiCompatibleGlyphPlacements(@as(*const IDWriteTextAnalyzer, @ptrCast(self)), textString, clusterMap, textProps, textLength, glyphIndices, glyphProps, glyphCount, fontFace, fontEmSize, pixelsPerDip, transform, useGdiNatural, isSideways, isRightToLeft, scriptAnalysis, localeName, features, featureRangeLengths, featureRanges, glyphAdvances, glyphOffsets);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_GLYPH_RUN = extern struct {
    fontFace: ?*IDWriteFontFace,
    fontEmSize: f32,
    glyphCount: u32,
    glyphIndices: ?*const u16,
    glyphAdvances: ?*const f32,
    glyphOffsets: ?*const DWRITE_GLYPH_OFFSET,
    isSideways: BOOL,
    bidiLevel: u32,
};

pub const DWRITE_GLYPH_RUN_DESCRIPTION = extern struct {
    localeName: ?[*:0]const u16,
    string: ?[*:0]const u16,
    stringLength: u32,
    clusterMap: ?*const u16,
    textPosition: u32,
};

pub const DWRITE_UNDERLINE = extern struct {
    width: f32,
    thickness: f32,
    offset: f32,
    runHeight: f32,
    readingDirection: DWRITE_READING_DIRECTION,
    flowDirection: DWRITE_FLOW_DIRECTION,
    localeName: ?[*:0]const u16,
    measuringMode: DWRITE_MEASURING_MODE,
};

pub const DWRITE_STRIKETHROUGH = extern struct {
    width: f32,
    thickness: f32,
    offset: f32,
    readingDirection: DWRITE_READING_DIRECTION,
    flowDirection: DWRITE_FLOW_DIRECTION,
    localeName: ?[*:0]const u16,
    measuringMode: DWRITE_MEASURING_MODE,
};

pub const DWRITE_LINE_METRICS = extern struct {
    length: u32,
    trailingWhitespaceLength: u32,
    newlineLength: u32,
    height: f32,
    baseline: f32,
    isTrimmed: BOOL,
};

pub const DWRITE_CLUSTER_METRICS = extern struct {
    width: f32,
    length: u16,
    _bitfield: u16,
};

pub const DWRITE_TEXT_METRICS = extern struct {
    left: f32,
    top: f32,
    width: f32,
    widthIncludingTrailingWhitespace: f32,
    height: f32,
    layoutWidth: f32,
    layoutHeight: f32,
    maxBidiReorderingDepth: u32,
    lineCount: u32,
};

pub const DWRITE_INLINE_OBJECT_METRICS = extern struct {
    width: f32,
    height: f32,
    baseline: f32,
    supportsSideways: BOOL,
};

pub const DWRITE_OVERHANG_METRICS = extern struct {
    left: f32,
    top: f32,
    right: f32,
    bottom: f32,
};

pub const DWRITE_HIT_TEST_METRICS = extern struct {
    textPosition: u32,
    length: u32,
    left: f32,
    top: f32,
    width: f32,
    height: f32,
    bidiLevel: u32,
    isText: BOOL,
    isTrimmed: BOOL,
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteInlineObject_Value = Guid.initString("8339fde3-106f-47ab-8373-1c6295eb10b3");
pub const IID_IDWriteInlineObject = &IID_IDWriteInlineObject_Value;
pub const IDWriteInlineObject = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        Draw: *const fn (
            self: *const IDWriteInlineObject,
            clientDrawingContext: ?*anyopaque,
            renderer: ?*IDWriteTextRenderer,
            originX: f32,
            originY: f32,
            isSideways: BOOL,
            isRightToLeft: BOOL,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMetrics: *const fn (
            self: *const IDWriteInlineObject,
            metrics: ?*DWRITE_INLINE_OBJECT_METRICS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetOverhangMetrics: *const fn (
            self: *const IDWriteInlineObject,
            overhangs: ?*DWRITE_OVERHANG_METRICS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetBreakConditions: *const fn (
            self: *const IDWriteInlineObject,
            breakConditionBefore: ?*DWRITE_BREAK_CONDITION,
            breakConditionAfter: ?*DWRITE_BREAK_CONDITION,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn Draw(self: *const T, clientDrawingContext: ?*anyopaque, renderer: ?*IDWriteTextRenderer, originX: f32, originY: f32, isSideways: BOOL, isRightToLeft: BOOL, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteInlineObject.VTable, @ptrCast(self.vtable)).Draw(@as(*const IDWriteInlineObject, @ptrCast(self)), clientDrawingContext, renderer, originX, originY, isSideways, isRightToLeft, clientDrawingEffect);
            }
            pub inline fn GetMetrics(self: *const T, metrics: ?*DWRITE_INLINE_OBJECT_METRICS) HRESULT {
                return @as(*const IDWriteInlineObject.VTable, @ptrCast(self.vtable)).GetMetrics(@as(*const IDWriteInlineObject, @ptrCast(self)), metrics);
            }
            pub inline fn GetOverhangMetrics(self: *const T, overhangs: ?*DWRITE_OVERHANG_METRICS) HRESULT {
                return @as(*const IDWriteInlineObject.VTable, @ptrCast(self.vtable)).GetOverhangMetrics(@as(*const IDWriteInlineObject, @ptrCast(self)), overhangs);
            }
            pub inline fn GetBreakConditions(self: *const T, breakConditionBefore: ?*DWRITE_BREAK_CONDITION, breakConditionAfter: ?*DWRITE_BREAK_CONDITION) HRESULT {
                return @as(*const IDWriteInlineObject.VTable, @ptrCast(self.vtable)).GetBreakConditions(@as(*const IDWriteInlineObject, @ptrCast(self)), breakConditionBefore, breakConditionAfter);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWritePixelSnapping_Value = Guid.initString("eaf3a2da-ecf4-4d24-b644-b34f6842024b");
pub const IID_IDWritePixelSnapping = &IID_IDWritePixelSnapping_Value;
pub const IDWritePixelSnapping = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        IsPixelSnappingDisabled: *const fn (
            self: *const IDWritePixelSnapping,
            clientDrawingContext: ?*anyopaque,
            isDisabled: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetCurrentTransform: *const fn (
            self: *const IDWritePixelSnapping,
            clientDrawingContext: ?*anyopaque,
            transform: ?*DWRITE_MATRIX,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetPixelsPerDip: *const fn (
            self: *const IDWritePixelSnapping,
            clientDrawingContext: ?*anyopaque,
            pixelsPerDip: ?*f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn IsPixelSnappingDisabled(self: *const T, clientDrawingContext: ?*anyopaque, isDisabled: ?*BOOL) HRESULT {
                return @as(*const IDWritePixelSnapping.VTable, @ptrCast(self.vtable)).IsPixelSnappingDisabled(@as(*const IDWritePixelSnapping, @ptrCast(self)), clientDrawingContext, isDisabled);
            }
            pub inline fn GetCurrentTransform(self: *const T, clientDrawingContext: ?*anyopaque, transform: ?*DWRITE_MATRIX) HRESULT {
                return @as(*const IDWritePixelSnapping.VTable, @ptrCast(self.vtable)).GetCurrentTransform(@as(*const IDWritePixelSnapping, @ptrCast(self)), clientDrawingContext, transform);
            }
            pub inline fn GetPixelsPerDip(self: *const T, clientDrawingContext: ?*anyopaque, pixelsPerDip: ?*f32) HRESULT {
                return @as(*const IDWritePixelSnapping.VTable, @ptrCast(self.vtable)).GetPixelsPerDip(@as(*const IDWritePixelSnapping, @ptrCast(self)), clientDrawingContext, pixelsPerDip);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteTextRenderer_Value = Guid.initString("ef8a8135-5cc6-45fe-8825-c5a0724eb819");
pub const IID_IDWriteTextRenderer = &IID_IDWriteTextRenderer_Value;
pub const IDWriteTextRenderer = extern struct {
    pub const VTable = extern struct {
        base: IDWritePixelSnapping.VTable,
        DrawGlyphRun: *const fn (
            self: *const IDWriteTextRenderer,
            clientDrawingContext: ?*anyopaque,
            baselineOriginX: f32,
            baselineOriginY: f32,
            measuringMode: DWRITE_MEASURING_MODE,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            glyphRunDescription: ?*const DWRITE_GLYPH_RUN_DESCRIPTION,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        DrawUnderline: *const fn (
            self: *const IDWriteTextRenderer,
            clientDrawingContext: ?*anyopaque,
            baselineOriginX: f32,
            baselineOriginY: f32,
            underline: ?*const DWRITE_UNDERLINE,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        DrawStrikethrough: *const fn (
            self: *const IDWriteTextRenderer,
            clientDrawingContext: ?*anyopaque,
            baselineOriginX: f32,
            baselineOriginY: f32,
            strikethrough: ?*const DWRITE_STRIKETHROUGH,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        DrawInlineObject: *const fn (
            self: *const IDWriteTextRenderer,
            clientDrawingContext: ?*anyopaque,
            originX: f32,
            originY: f32,
            inlineObject: ?*IDWriteInlineObject,
            isSideways: BOOL,
            isRightToLeft: BOOL,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWritePixelSnapping.MethodMixin(T);
            pub inline fn DrawGlyphRun(self: *const T, clientDrawingContext: ?*anyopaque, baselineOriginX: f32, baselineOriginY: f32, measuringMode: DWRITE_MEASURING_MODE, glyphRun: ?*const DWRITE_GLYPH_RUN, glyphRunDescription: ?*const DWRITE_GLYPH_RUN_DESCRIPTION, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteTextRenderer.VTable, @ptrCast(self.vtable)).DrawGlyphRun(@as(*const IDWriteTextRenderer, @ptrCast(self)), clientDrawingContext, baselineOriginX, baselineOriginY, measuringMode, glyphRun, glyphRunDescription, clientDrawingEffect);
            }
            pub inline fn DrawUnderline(self: *const T, clientDrawingContext: ?*anyopaque, baselineOriginX: f32, baselineOriginY: f32, underline: ?*const DWRITE_UNDERLINE, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteTextRenderer.VTable, @ptrCast(self.vtable)).DrawUnderline(@as(*const IDWriteTextRenderer, @ptrCast(self)), clientDrawingContext, baselineOriginX, baselineOriginY, underline, clientDrawingEffect);
            }
            pub inline fn DrawStrikethrough(self: *const T, clientDrawingContext: ?*anyopaque, baselineOriginX: f32, baselineOriginY: f32, strikethrough: ?*const DWRITE_STRIKETHROUGH, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteTextRenderer.VTable, @ptrCast(self.vtable)).DrawStrikethrough(@as(*const IDWriteTextRenderer, @ptrCast(self)), clientDrawingContext, baselineOriginX, baselineOriginY, strikethrough, clientDrawingEffect);
            }
            pub inline fn DrawInlineObject(self: *const T, clientDrawingContext: ?*anyopaque, originX: f32, originY: f32, inlineObject: ?*IDWriteInlineObject, isSideways: BOOL, isRightToLeft: BOOL, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteTextRenderer.VTable, @ptrCast(self.vtable)).DrawInlineObject(@as(*const IDWriteTextRenderer, @ptrCast(self)), clientDrawingContext, originX, originY, inlineObject, isSideways, isRightToLeft, clientDrawingEffect);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteTextLayout_Value = Guid.initString("53737037-6d14-410b-9bfe-0b182bb70961");
pub const IID_IDWriteTextLayout = &IID_IDWriteTextLayout_Value;
pub const IDWriteTextLayout = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextFormat.VTable,
        SetMaxWidth: *const fn (
            self: *const IDWriteTextLayout,
            maxWidth: f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetMaxHeight: *const fn (
            self: *const IDWriteTextLayout,
            maxHeight: f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetFontCollection: *const fn (
            self: *const IDWriteTextLayout,
            fontCollection: ?*IDWriteFontCollection,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetFontFamilyName: *const fn (
            self: *const IDWriteTextLayout,
            fontFamilyName: ?[*:0]const u16,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetFontWeight: *const fn (
            self: *const IDWriteTextLayout,
            fontWeight: DWRITE_FONT_WEIGHT,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetFontStyle: *const fn (
            self: *const IDWriteTextLayout,
            fontStyle: DWRITE_FONT_STYLE,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetFontStretch: *const fn (
            self: *const IDWriteTextLayout,
            fontStretch: DWRITE_FONT_STRETCH,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetFontSize: *const fn (
            self: *const IDWriteTextLayout,
            fontSize: f32,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetUnderline: *const fn (
            self: *const IDWriteTextLayout,
            hasUnderline: BOOL,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetStrikethrough: *const fn (
            self: *const IDWriteTextLayout,
            hasStrikethrough: BOOL,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetDrawingEffect: *const fn (
            self: *const IDWriteTextLayout,
            drawingEffect: ?*IUnknown,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetInlineObject: *const fn (
            self: *const IDWriteTextLayout,
            inlineObject: ?*IDWriteInlineObject,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetTypography: *const fn (
            self: *const IDWriteTextLayout,
            typography: ?*IDWriteTypography,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetLocaleName: *const fn (
            self: *const IDWriteTextLayout,
            localeName: ?[*:0]const u16,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMaxWidth: *const fn (
            self: *const IDWriteTextLayout,
        ) callconv(std.os.windows.WINAPI) f32,

        GetMaxHeight: *const fn (
            self: *const IDWriteTextLayout,
        ) callconv(std.os.windows.WINAPI) f32,

        GetFontCollection: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            fontCollection: ?*?*IDWriteFontCollection,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFamilyNameLength: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            nameLength: ?*u32,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFamilyName: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            fontFamilyName: [*:0]u16,
            nameSize: u32,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontWeight: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            fontWeight: ?*DWRITE_FONT_WEIGHT,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontStyle: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            fontStyle: ?*DWRITE_FONT_STYLE,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontStretch: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            fontStretch: ?*DWRITE_FONT_STRETCH,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontSize: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            fontSize: ?*f32,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetUnderline: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            hasUnderline: ?*BOOL,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetStrikethrough: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            hasStrikethrough: ?*BOOL,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetDrawingEffect: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            drawingEffect: ?*?*IUnknown,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetInlineObject: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            inlineObject: ?*?*IDWriteInlineObject,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetTypography: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            typography: ?*?*IDWriteTypography,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocaleNameLength: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            nameLength: ?*u32,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocaleName: *const fn (
            self: *const IDWriteTextLayout,
            currentPosition: u32,
            localeName: [*:0]u16,
            nameSize: u32,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        Draw: *const fn (
            self: *const IDWriteTextLayout,
            clientDrawingContext: ?*anyopaque,
            renderer: ?*IDWriteTextRenderer,
            originX: f32,
            originY: f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLineMetrics: *const fn (
            self: *const IDWriteTextLayout,
            lineMetrics: ?[*]DWRITE_LINE_METRICS,
            maxLineCount: u32,
            actualLineCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMetrics: *const fn (
            self: *const IDWriteTextLayout,
            textMetrics: ?*DWRITE_TEXT_METRICS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetOverhangMetrics: *const fn (
            self: *const IDWriteTextLayout,
            overhangs: ?*DWRITE_OVERHANG_METRICS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetClusterMetrics: *const fn (
            self: *const IDWriteTextLayout,
            clusterMetrics: ?[*]DWRITE_CLUSTER_METRICS,
            maxClusterCount: u32,
            actualClusterCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        DetermineMinWidth: *const fn (
            self: *const IDWriteTextLayout,
            minWidth: ?*f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HitTestPoint: *const fn (
            self: *const IDWriteTextLayout,
            pointX: f32,
            pointY: f32,
            isTrailingHit: ?*BOOL,
            isInside: ?*BOOL,
            hitTestMetrics: ?*DWRITE_HIT_TEST_METRICS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HitTestTextPosition: *const fn (
            self: *const IDWriteTextLayout,
            textPosition: u32,
            isTrailingHit: BOOL,
            pointX: ?*f32,
            pointY: ?*f32,
            hitTestMetrics: ?*DWRITE_HIT_TEST_METRICS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HitTestTextRange: *const fn (
            self: *const IDWriteTextLayout,
            textPosition: u32,
            textLength: u32,
            originX: f32,
            originY: f32,
            hitTestMetrics: ?[*]DWRITE_HIT_TEST_METRICS,
            maxHitTestMetricsCount: u32,
            actualHitTestMetricsCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextFormat.MethodMixin(T);
            pub inline fn SetMaxWidth(self: *const T, maxWidth: f32) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetMaxWidth(@as(*const IDWriteTextLayout, @ptrCast(self)), maxWidth);
            }
            pub inline fn SetMaxHeight(self: *const T, maxHeight: f32) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetMaxHeight(@as(*const IDWriteTextLayout, @ptrCast(self)), maxHeight);
            }
            pub inline fn SetFontCollection(self: *const T, fontCollection: ?*IDWriteFontCollection, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetFontCollection(@as(*const IDWriteTextLayout, @ptrCast(self)), fontCollection, textRange);
            }
            pub inline fn SetFontFamilyName(self: *const T, fontFamilyName: ?[*:0]const u16, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetFontFamilyName(@as(*const IDWriteTextLayout, @ptrCast(self)), fontFamilyName, textRange);
            }
            pub inline fn SetFontWeight(self: *const T, fontWeight: DWRITE_FONT_WEIGHT, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetFontWeight(@as(*const IDWriteTextLayout, @ptrCast(self)), fontWeight, textRange);
            }
            pub inline fn SetFontStyle(self: *const T, fontStyle: DWRITE_FONT_STYLE, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetFontStyle(@as(*const IDWriteTextLayout, @ptrCast(self)), fontStyle, textRange);
            }
            pub inline fn SetFontStretch(self: *const T, fontStretch: DWRITE_FONT_STRETCH, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetFontStretch(@as(*const IDWriteTextLayout, @ptrCast(self)), fontStretch, textRange);
            }
            pub inline fn SetFontSize(self: *const T, fontSize: f32, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetFontSize(@as(*const IDWriteTextLayout, @ptrCast(self)), fontSize, textRange);
            }
            pub inline fn SetUnderline(self: *const T, hasUnderline: BOOL, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetUnderline(@as(*const IDWriteTextLayout, @ptrCast(self)), hasUnderline, textRange);
            }
            pub inline fn SetStrikethrough(self: *const T, hasStrikethrough: BOOL, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetStrikethrough(@as(*const IDWriteTextLayout, @ptrCast(self)), hasStrikethrough, textRange);
            }
            pub inline fn SetDrawingEffect(self: *const T, drawingEffect: ?*IUnknown, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetDrawingEffect(@as(*const IDWriteTextLayout, @ptrCast(self)), drawingEffect, textRange);
            }
            pub inline fn SetInlineObject(self: *const T, inlineObject: ?*IDWriteInlineObject, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetInlineObject(@as(*const IDWriteTextLayout, @ptrCast(self)), inlineObject, textRange);
            }
            pub inline fn SetTypography(self: *const T, typography: ?*IDWriteTypography, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetTypography(@as(*const IDWriteTextLayout, @ptrCast(self)), typography, textRange);
            }
            pub inline fn SetLocaleName(self: *const T, localeName: ?[*:0]const u16, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).SetLocaleName(@as(*const IDWriteTextLayout, @ptrCast(self)), localeName, textRange);
            }
            pub inline fn GetMaxWidth(self: *const T) f32 {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetMaxWidth(@as(*const IDWriteTextLayout, @ptrCast(self)));
            }
            pub inline fn GetMaxHeight(self: *const T) f32 {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetMaxHeight(@as(*const IDWriteTextLayout, @ptrCast(self)));
            }
            pub inline fn GetFontCollection(self: *const T, currentPosition: u32, fontCollection: ?*?*IDWriteFontCollection, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetFontCollection(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, fontCollection, textRange);
            }
            pub inline fn GetFontFamilyNameLength(self: *const T, currentPosition: u32, nameLength: ?*u32, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetFontFamilyNameLength(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, nameLength, textRange);
            }
            pub inline fn GetFontFamilyName(self: *const T, currentPosition: u32, fontFamilyName: [*:0]u16, nameSize: u32, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetFontFamilyName(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, fontFamilyName, nameSize, textRange);
            }
            pub inline fn GetFontWeight(self: *const T, currentPosition: u32, fontWeight: ?*DWRITE_FONT_WEIGHT, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetFontWeight(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, fontWeight, textRange);
            }
            pub inline fn GetFontStyle(self: *const T, currentPosition: u32, fontStyle: ?*DWRITE_FONT_STYLE, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetFontStyle(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, fontStyle, textRange);
            }
            pub inline fn GetFontStretch(self: *const T, currentPosition: u32, fontStretch: ?*DWRITE_FONT_STRETCH, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetFontStretch(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, fontStretch, textRange);
            }
            pub inline fn GetFontSize(self: *const T, currentPosition: u32, fontSize: ?*f32, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetFontSize(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, fontSize, textRange);
            }
            pub inline fn GetUnderline(self: *const T, currentPosition: u32, hasUnderline: ?*BOOL, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetUnderline(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, hasUnderline, textRange);
            }
            pub inline fn GetStrikethrough(self: *const T, currentPosition: u32, hasStrikethrough: ?*BOOL, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetStrikethrough(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, hasStrikethrough, textRange);
            }
            pub inline fn GetDrawingEffect(self: *const T, currentPosition: u32, drawingEffect: ?*?*IUnknown, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetDrawingEffect(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, drawingEffect, textRange);
            }
            pub inline fn GetInlineObject(self: *const T, currentPosition: u32, inlineObject: ?*?*IDWriteInlineObject, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetInlineObject(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, inlineObject, textRange);
            }
            pub inline fn GetTypography(self: *const T, currentPosition: u32, typography: ?*?*IDWriteTypography, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetTypography(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, typography, textRange);
            }
            pub inline fn GetLocaleNameLength(self: *const T, currentPosition: u32, nameLength: ?*u32, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetLocaleNameLength(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, nameLength, textRange);
            }
            pub inline fn GetLocaleName(self: *const T, currentPosition: u32, localeName: [*:0]u16, nameSize: u32, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetLocaleName(@as(*const IDWriteTextLayout, @ptrCast(self)), currentPosition, localeName, nameSize, textRange);
            }
            pub inline fn Draw(self: *const T, clientDrawingContext: ?*anyopaque, renderer: ?*IDWriteTextRenderer, originX: f32, originY: f32) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).Draw(@as(*const IDWriteTextLayout, @ptrCast(self)), clientDrawingContext, renderer, originX, originY);
            }
            pub inline fn GetLineMetrics(self: *const T, lineMetrics: ?[*]DWRITE_LINE_METRICS, maxLineCount: u32, actualLineCount: ?*u32) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetLineMetrics(@as(*const IDWriteTextLayout, @ptrCast(self)), lineMetrics, maxLineCount, actualLineCount);
            }
            pub inline fn GetMetrics(self: *const T, textMetrics: ?*DWRITE_TEXT_METRICS) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetMetrics(@as(*const IDWriteTextLayout, @ptrCast(self)), textMetrics);
            }
            pub inline fn GetOverhangMetrics(self: *const T, overhangs: ?*DWRITE_OVERHANG_METRICS) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetOverhangMetrics(@as(*const IDWriteTextLayout, @ptrCast(self)), overhangs);
            }
            pub inline fn GetClusterMetrics(self: *const T, clusterMetrics: ?[*]DWRITE_CLUSTER_METRICS, maxClusterCount: u32, actualClusterCount: ?*u32) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).GetClusterMetrics(@as(*const IDWriteTextLayout, @ptrCast(self)), clusterMetrics, maxClusterCount, actualClusterCount);
            }
            pub inline fn DetermineMinWidth(self: *const T, minWidth: ?*f32) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).DetermineMinWidth(@as(*const IDWriteTextLayout, @ptrCast(self)), minWidth);
            }
            pub inline fn HitTestPoint(self: *const T, pointX: f32, pointY: f32, isTrailingHit: ?*BOOL, isInside: ?*BOOL, hitTestMetrics: ?*DWRITE_HIT_TEST_METRICS) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).HitTestPoint(@as(*const IDWriteTextLayout, @ptrCast(self)), pointX, pointY, isTrailingHit, isInside, hitTestMetrics);
            }
            pub inline fn HitTestTextPosition(self: *const T, textPosition: u32, isTrailingHit: BOOL, pointX: ?*f32, pointY: ?*f32, hitTestMetrics: ?*DWRITE_HIT_TEST_METRICS) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).HitTestTextPosition(@as(*const IDWriteTextLayout, @ptrCast(self)), textPosition, isTrailingHit, pointX, pointY, hitTestMetrics);
            }
            pub inline fn HitTestTextRange(self: *const T, textPosition: u32, textLength: u32, originX: f32, originY: f32, hitTestMetrics: ?[*]DWRITE_HIT_TEST_METRICS, maxHitTestMetricsCount: u32, actualHitTestMetricsCount: ?*u32) HRESULT {
                return @as(*const IDWriteTextLayout.VTable, @ptrCast(self.vtable)).HitTestTextRange(@as(*const IDWriteTextLayout, @ptrCast(self)), textPosition, textLength, originX, originY, hitTestMetrics, maxHitTestMetricsCount, actualHitTestMetricsCount);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteBitmapRenderTarget_Value = Guid.initString("5e5a32a3-8dff-4773-9ff6-0696eab77267");
pub const IID_IDWriteBitmapRenderTarget = &IID_IDWriteBitmapRenderTarget_Value;
pub const IDWriteBitmapRenderTarget = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        DrawGlyphRun: *const fn (
            self: *const IDWriteBitmapRenderTarget,
            baselineOriginX: f32,
            baselineOriginY: f32,
            measuringMode: DWRITE_MEASURING_MODE,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            renderingParams: ?*IDWriteRenderingParams,
            textColor: u32,
            blackBoxRect: ?*RECT,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMemoryDC: *const fn (
            self: *const IDWriteBitmapRenderTarget,
        ) callconv(std.os.windows.WINAPI) ?HDC,

        GetPixelsPerDip: *const fn (
            self: *const IDWriteBitmapRenderTarget,
        ) callconv(std.os.windows.WINAPI) f32,

        SetPixelsPerDip: *const fn (
            self: *const IDWriteBitmapRenderTarget,
            pixelsPerDip: f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetCurrentTransform: *const fn (
            self: *const IDWriteBitmapRenderTarget,
            transform: ?*DWRITE_MATRIX,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetCurrentTransform: *const fn (
            self: *const IDWriteBitmapRenderTarget,
            transform: ?*const DWRITE_MATRIX,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetSize: *const fn (
            self: *const IDWriteBitmapRenderTarget,
            size: ?*SIZE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        Resize: *const fn (
            self: *const IDWriteBitmapRenderTarget,
            width: u32,
            height: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn DrawGlyphRun(self: *const T, baselineOriginX: f32, baselineOriginY: f32, measuringMode: DWRITE_MEASURING_MODE, glyphRun: ?*const DWRITE_GLYPH_RUN, renderingParams: ?*IDWriteRenderingParams, textColor: u32, blackBoxRect: ?*RECT) HRESULT {
                return @as(*const IDWriteBitmapRenderTarget.VTable, @ptrCast(self.vtable)).DrawGlyphRun(@as(*const IDWriteBitmapRenderTarget, @ptrCast(self)), baselineOriginX, baselineOriginY, measuringMode, glyphRun, renderingParams, textColor, blackBoxRect);
            }
            pub inline fn GetMemoryDC(self: *const T) ?HDC {
                return @as(*const IDWriteBitmapRenderTarget.VTable, @ptrCast(self.vtable)).GetMemoryDC(@as(*const IDWriteBitmapRenderTarget, @ptrCast(self)));
            }
            pub inline fn GetPixelsPerDip(self: *const T) f32 {
                return @as(*const IDWriteBitmapRenderTarget.VTable, @ptrCast(self.vtable)).GetPixelsPerDip(@as(*const IDWriteBitmapRenderTarget, @ptrCast(self)));
            }
            pub inline fn SetPixelsPerDip(self: *const T, pixelsPerDip: f32) HRESULT {
                return @as(*const IDWriteBitmapRenderTarget.VTable, @ptrCast(self.vtable)).SetPixelsPerDip(@as(*const IDWriteBitmapRenderTarget, @ptrCast(self)), pixelsPerDip);
            }
            pub inline fn GetCurrentTransform(self: *const T, transform: ?*DWRITE_MATRIX) HRESULT {
                return @as(*const IDWriteBitmapRenderTarget.VTable, @ptrCast(self.vtable)).GetCurrentTransform(@as(*const IDWriteBitmapRenderTarget, @ptrCast(self)), transform);
            }
            pub inline fn SetCurrentTransform(self: *const T, transform: ?*const DWRITE_MATRIX) HRESULT {
                return @as(*const IDWriteBitmapRenderTarget.VTable, @ptrCast(self.vtable)).SetCurrentTransform(@as(*const IDWriteBitmapRenderTarget, @ptrCast(self)), transform);
            }
            pub inline fn GetSize(self: *const T, size: ?*SIZE) HRESULT {
                return @as(*const IDWriteBitmapRenderTarget.VTable, @ptrCast(self.vtable)).GetSize(@as(*const IDWriteBitmapRenderTarget, @ptrCast(self)), size);
            }
            pub inline fn Resize(self: *const T, width: u32, height: u32) HRESULT {
                return @as(*const IDWriteBitmapRenderTarget.VTable, @ptrCast(self.vtable)).Resize(@as(*const IDWriteBitmapRenderTarget, @ptrCast(self)), width, height);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteGdiInterop_Value = Guid.initString("1edd9491-9853-4299-898f-6432983b6f3a");
pub const IID_IDWriteGdiInterop = &IID_IDWriteGdiInterop_Value;
pub const IDWriteGdiInterop = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        CreateFontFromLOGFONT: *const fn (
            self: *const IDWriteGdiInterop,
            logFont: ?*const LOGFONTW,
            font: ?*?*IDWriteFont,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        ConvertFontToLOGFONT: *const fn (
            self: *const IDWriteGdiInterop,
            font: ?*IDWriteFont,
            logFont: ?*LOGFONTW,
            isSystemFont: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        ConvertFontFaceToLOGFONT: *const fn (
            self: *const IDWriteGdiInterop,
            font: ?*IDWriteFontFace,
            logFont: ?*LOGFONTW,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFaceFromHdc: *const fn (
            self: *const IDWriteGdiInterop,
            hdc: ?HDC,
            fontFace: ?*?*IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateBitmapRenderTarget: *const fn (
            self: *const IDWriteGdiInterop,
            hdc: ?HDC,
            width: u32,
            height: u32,
            renderTarget: ?*?*IDWriteBitmapRenderTarget,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn CreateFontFromLOGFONT(self: *const T, logFont: ?*const LOGFONTW, font: ?*?*IDWriteFont) HRESULT {
                return @as(*const IDWriteGdiInterop.VTable, @ptrCast(self.vtable)).CreateFontFromLOGFONT(@as(*const IDWriteGdiInterop, @ptrCast(self)), logFont, font);
            }
            pub inline fn ConvertFontToLOGFONT(self: *const T, font: ?*IDWriteFont, logFont: ?*LOGFONTW, isSystemFont: ?*BOOL) HRESULT {
                return @as(*const IDWriteGdiInterop.VTable, @ptrCast(self.vtable)).ConvertFontToLOGFONT(@as(*const IDWriteGdiInterop, @ptrCast(self)), font, logFont, isSystemFont);
            }
            pub inline fn ConvertFontFaceToLOGFONT(self: *const T, font: ?*IDWriteFontFace, logFont: ?*LOGFONTW) HRESULT {
                return @as(*const IDWriteGdiInterop.VTable, @ptrCast(self.vtable)).ConvertFontFaceToLOGFONT(@as(*const IDWriteGdiInterop, @ptrCast(self)), font, logFont);
            }
            pub inline fn CreateFontFaceFromHdc(self: *const T, hdc: ?HDC, fontFace: ?*?*IDWriteFontFace) HRESULT {
                return @as(*const IDWriteGdiInterop.VTable, @ptrCast(self.vtable)).CreateFontFaceFromHdc(@as(*const IDWriteGdiInterop, @ptrCast(self)), hdc, fontFace);
            }
            pub inline fn CreateBitmapRenderTarget(self: *const T, hdc: ?HDC, width: u32, height: u32, renderTarget: ?*?*IDWriteBitmapRenderTarget) HRESULT {
                return @as(*const IDWriteGdiInterop.VTable, @ptrCast(self.vtable)).CreateBitmapRenderTarget(@as(*const IDWriteGdiInterop, @ptrCast(self)), hdc, width, height, renderTarget);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_TEXTURE_TYPE = enum(i32) {
    ALIASED_1x1 = 0,
    CLEARTYPE_3x1 = 1,
};
pub const DWRITE_TEXTURE_ALIASED_1x1 = DWRITE_TEXTURE_TYPE.ALIASED_1x1;
pub const DWRITE_TEXTURE_CLEARTYPE_3x1 = DWRITE_TEXTURE_TYPE.CLEARTYPE_3x1;

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteGlyphRunAnalysis_Value = Guid.initString("7d97dbf7-e085-42d4-81e3-6a883bded118");
pub const IID_IDWriteGlyphRunAnalysis = &IID_IDWriteGlyphRunAnalysis_Value;
pub const IDWriteGlyphRunAnalysis = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetAlphaTextureBounds: *const fn (
            self: *const IDWriteGlyphRunAnalysis,
            textureType: DWRITE_TEXTURE_TYPE,
            textureBounds: ?*RECT,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateAlphaTexture: *const fn (
            self: *const IDWriteGlyphRunAnalysis,
            textureType: DWRITE_TEXTURE_TYPE,
            textureBounds: ?*const RECT,
            // TODO: what to do with BytesParamIndex 3?
            alphaValues: ?*u8,
            bufferSize: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetAlphaBlendParams: *const fn (
            self: *const IDWriteGlyphRunAnalysis,
            renderingParams: ?*IDWriteRenderingParams,
            blendGamma: ?*f32,
            blendEnhancedContrast: ?*f32,
            blendClearTypeLevel: ?*f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetAlphaTextureBounds(self: *const T, textureType: DWRITE_TEXTURE_TYPE, textureBounds: ?*RECT) HRESULT {
                return @as(*const IDWriteGlyphRunAnalysis.VTable, @ptrCast(self.vtable)).GetAlphaTextureBounds(@as(*const IDWriteGlyphRunAnalysis, @ptrCast(self)), textureType, textureBounds);
            }
            pub inline fn CreateAlphaTexture(self: *const T, textureType: DWRITE_TEXTURE_TYPE, textureBounds: ?*const RECT, alphaValues: ?*u8, bufferSize: u32) HRESULT {
                return @as(*const IDWriteGlyphRunAnalysis.VTable, @ptrCast(self.vtable)).CreateAlphaTexture(@as(*const IDWriteGlyphRunAnalysis, @ptrCast(self)), textureType, textureBounds, alphaValues, bufferSize);
            }
            pub inline fn GetAlphaBlendParams(self: *const T, renderingParams: ?*IDWriteRenderingParams, blendGamma: ?*f32, blendEnhancedContrast: ?*f32, blendClearTypeLevel: ?*f32) HRESULT {
                return @as(*const IDWriteGlyphRunAnalysis.VTable, @ptrCast(self.vtable)).GetAlphaBlendParams(@as(*const IDWriteGlyphRunAnalysis, @ptrCast(self)), renderingParams, blendGamma, blendEnhancedContrast, blendClearTypeLevel);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFactory_Value = Guid.initString("b859ee5a-d838-4b5b-a2e8-1adc7d93db48");
pub const IID_IDWriteFactory = &IID_IDWriteFactory_Value;
pub const IDWriteFactory = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetSystemFontCollection: *const fn (
            self: *const IDWriteFactory,
            fontCollection: ?*?*IDWriteFontCollection,
            checkForUpdates: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateCustomFontCollection: *const fn (
            self: *const IDWriteFactory,
            collectionLoader: ?*IDWriteFontCollectionLoader,
            // TODO: what to do with BytesParamIndex 2?
            collectionKey: ?*const anyopaque,
            collectionKeySize: u32,
            fontCollection: ?*?*IDWriteFontCollection,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        RegisterFontCollectionLoader: *const fn (
            self: *const IDWriteFactory,
            fontCollectionLoader: ?*IDWriteFontCollectionLoader,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        UnregisterFontCollectionLoader: *const fn (
            self: *const IDWriteFactory,
            fontCollectionLoader: ?*IDWriteFontCollectionLoader,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFileReference: *const fn (
            self: *const IDWriteFactory,
            filePath: ?[*:0]const u16,
            lastWriteTime: ?*const FILETIME,
            fontFile: ?*?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateCustomFontFileReference: *const fn (
            self: *const IDWriteFactory,
            // TODO: what to do with BytesParamIndex 1?
            fontFileReferenceKey: ?*const anyopaque,
            fontFileReferenceKeySize: u32,
            fontFileLoader: ?*IDWriteFontFileLoader,
            fontFile: ?*?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFace: *const fn (
            self: *const IDWriteFactory,
            fontFaceType: DWRITE_FONT_FACE_TYPE,
            numberOfFiles: u32,
            fontFiles: [*]?*IDWriteFontFile,
            faceIndex: u32,
            fontFaceSimulationFlags: DWRITE_FONT_SIMULATIONS,
            fontFace: ?*?*IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateRenderingParams: *const fn (
            self: *const IDWriteFactory,
            renderingParams: ?*?*IDWriteRenderingParams,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateMonitorRenderingParams: *const fn (
            self: *const IDWriteFactory,
            monitor: ?HMONITOR,
            renderingParams: ?*?*IDWriteRenderingParams,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateCustomRenderingParams: *const fn (
            self: *const IDWriteFactory,
            gamma: f32,
            enhancedContrast: f32,
            clearTypeLevel: f32,
            pixelGeometry: DWRITE_PIXEL_GEOMETRY,
            renderingMode: DWRITE_RENDERING_MODE,
            renderingParams: ?*?*IDWriteRenderingParams,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        RegisterFontFileLoader: *const fn (
            self: *const IDWriteFactory,
            fontFileLoader: ?*IDWriteFontFileLoader,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        UnregisterFontFileLoader: *const fn (
            self: *const IDWriteFactory,
            fontFileLoader: ?*IDWriteFontFileLoader,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateTextFormat: *const fn (
            self: *const IDWriteFactory,
            fontFamilyName: ?[*:0]const u16,
            fontCollection: ?*IDWriteFontCollection,
            fontWeight: DWRITE_FONT_WEIGHT,
            fontStyle: DWRITE_FONT_STYLE,
            fontStretch: DWRITE_FONT_STRETCH,
            fontSize: f32,
            localeName: ?[*:0]const u16,
            textFormat: ?*?*IDWriteTextFormat,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateTypography: *const fn (
            self: *const IDWriteFactory,
            typography: ?*?*IDWriteTypography,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGdiInterop: *const fn (
            self: *const IDWriteFactory,
            gdiInterop: ?*?*IDWriteGdiInterop,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateTextLayout: *const fn (
            self: *const IDWriteFactory,
            string: [*:0]const u16,
            stringLength: u32,
            textFormat: ?*IDWriteTextFormat,
            maxWidth: f32,
            maxHeight: f32,
            textLayout: ?*?*IDWriteTextLayout,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateGdiCompatibleTextLayout: *const fn (
            self: *const IDWriteFactory,
            string: [*:0]const u16,
            stringLength: u32,
            textFormat: ?*IDWriteTextFormat,
            layoutWidth: f32,
            layoutHeight: f32,
            pixelsPerDip: f32,
            transform: ?*const DWRITE_MATRIX,
            useGdiNatural: BOOL,
            textLayout: ?*?*IDWriteTextLayout,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateEllipsisTrimmingSign: *const fn (
            self: *const IDWriteFactory,
            textFormat: ?*IDWriteTextFormat,
            trimmingSign: ?*?*IDWriteInlineObject,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateTextAnalyzer: *const fn (
            self: *const IDWriteFactory,
            textAnalyzer: ?*?*IDWriteTextAnalyzer,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateNumberSubstitution: *const fn (
            self: *const IDWriteFactory,
            substitutionMethod: DWRITE_NUMBER_SUBSTITUTION_METHOD,
            localeName: ?[*:0]const u16,
            ignoreUserOverride: BOOL,
            numberSubstitution: ?*?*IDWriteNumberSubstitution,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateGlyphRunAnalysis: *const fn (
            self: *const IDWriteFactory,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            pixelsPerDip: f32,
            transform: ?*const DWRITE_MATRIX,
            renderingMode: DWRITE_RENDERING_MODE,
            measuringMode: DWRITE_MEASURING_MODE,
            baselineOriginX: f32,
            baselineOriginY: f32,
            glyphRunAnalysis: ?*?*IDWriteGlyphRunAnalysis,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetSystemFontCollection(self: *const T, fontCollection: ?*?*IDWriteFontCollection, checkForUpdates: BOOL) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).GetSystemFontCollection(@as(*const IDWriteFactory, @ptrCast(self)), fontCollection, checkForUpdates);
            }
            pub inline fn CreateCustomFontCollection(self: *const T, collectionLoader: ?*IDWriteFontCollectionLoader, collectionKey: ?*const anyopaque, collectionKeySize: u32, fontCollection: ?*?*IDWriteFontCollection) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateCustomFontCollection(@as(*const IDWriteFactory, @ptrCast(self)), collectionLoader, collectionKey, collectionKeySize, fontCollection);
            }
            pub inline fn RegisterFontCollectionLoader(self: *const T, fontCollectionLoader: ?*IDWriteFontCollectionLoader) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).RegisterFontCollectionLoader(@as(*const IDWriteFactory, @ptrCast(self)), fontCollectionLoader);
            }
            pub inline fn UnregisterFontCollectionLoader(self: *const T, fontCollectionLoader: ?*IDWriteFontCollectionLoader) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).UnregisterFontCollectionLoader(@as(*const IDWriteFactory, @ptrCast(self)), fontCollectionLoader);
            }
            pub inline fn CreateFontFileReference(self: *const T, filePath: ?[*:0]const u16, lastWriteTime: ?*const FILETIME, fontFile: ?*?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateFontFileReference(@as(*const IDWriteFactory, @ptrCast(self)), filePath, lastWriteTime, fontFile);
            }
            pub inline fn CreateCustomFontFileReference(self: *const T, fontFileReferenceKey: ?*const anyopaque, fontFileReferenceKeySize: u32, fontFileLoader: ?*IDWriteFontFileLoader, fontFile: ?*?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateCustomFontFileReference(@as(*const IDWriteFactory, @ptrCast(self)), fontFileReferenceKey, fontFileReferenceKeySize, fontFileLoader, fontFile);
            }
            pub inline fn CreateFontFace(self: *const T, fontFaceType: DWRITE_FONT_FACE_TYPE, numberOfFiles: u32, fontFiles: [*]?*IDWriteFontFile, faceIndex: u32, fontFaceSimulationFlags: DWRITE_FONT_SIMULATIONS, fontFace: ?*?*IDWriteFontFace) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateFontFace(@as(*const IDWriteFactory, @ptrCast(self)), fontFaceType, numberOfFiles, fontFiles, faceIndex, fontFaceSimulationFlags, fontFace);
            }
            pub inline fn CreateRenderingParams(self: *const T, renderingParams: ?*?*IDWriteRenderingParams) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateRenderingParams(@as(*const IDWriteFactory, @ptrCast(self)), renderingParams);
            }
            pub inline fn CreateMonitorRenderingParams(self: *const T, monitor: ?HMONITOR, renderingParams: ?*?*IDWriteRenderingParams) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateMonitorRenderingParams(@as(*const IDWriteFactory, @ptrCast(self)), monitor, renderingParams);
            }
            pub inline fn CreateCustomRenderingParams(self: *const T, gamma: f32, enhancedContrast: f32, clearTypeLevel: f32, pixelGeometry: DWRITE_PIXEL_GEOMETRY, renderingMode: DWRITE_RENDERING_MODE, renderingParams: ?*?*IDWriteRenderingParams) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateCustomRenderingParams(@as(*const IDWriteFactory, @ptrCast(self)), gamma, enhancedContrast, clearTypeLevel, pixelGeometry, renderingMode, renderingParams);
            }
            pub inline fn RegisterFontFileLoader(self: *const T, fontFileLoader: ?*IDWriteFontFileLoader) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).RegisterFontFileLoader(@as(*const IDWriteFactory, @ptrCast(self)), fontFileLoader);
            }
            pub inline fn UnregisterFontFileLoader(self: *const T, fontFileLoader: ?*IDWriteFontFileLoader) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).UnregisterFontFileLoader(@as(*const IDWriteFactory, @ptrCast(self)), fontFileLoader);
            }
            pub inline fn CreateTextFormat(self: *const T, fontFamilyName: ?[*:0]const u16, fontCollection: ?*IDWriteFontCollection, fontWeight: DWRITE_FONT_WEIGHT, fontStyle: DWRITE_FONT_STYLE, fontStretch: DWRITE_FONT_STRETCH, fontSize: f32, localeName: ?[*:0]const u16, textFormat: ?*?*IDWriteTextFormat) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateTextFormat(@as(*const IDWriteFactory, @ptrCast(self)), fontFamilyName, fontCollection, fontWeight, fontStyle, fontStretch, fontSize, localeName, textFormat);
            }
            pub inline fn CreateTypography(self: *const T, typography: ?*?*IDWriteTypography) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateTypography(@as(*const IDWriteFactory, @ptrCast(self)), typography);
            }
            pub inline fn GetGdiInterop(self: *const T, gdiInterop: ?*?*IDWriteGdiInterop) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).GetGdiInterop(@as(*const IDWriteFactory, @ptrCast(self)), gdiInterop);
            }
            pub inline fn CreateTextLayout(self: *const T, string: [*:0]const u16, stringLength: u32, textFormat: ?*IDWriteTextFormat, maxWidth: f32, maxHeight: f32, textLayout: ?*?*IDWriteTextLayout) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateTextLayout(@as(*const IDWriteFactory, @ptrCast(self)), string, stringLength, textFormat, maxWidth, maxHeight, textLayout);
            }
            pub inline fn CreateGdiCompatibleTextLayout(self: *const T, string: [*:0]const u16, stringLength: u32, textFormat: ?*IDWriteTextFormat, layoutWidth: f32, layoutHeight: f32, pixelsPerDip: f32, transform: ?*const DWRITE_MATRIX, useGdiNatural: BOOL, textLayout: ?*?*IDWriteTextLayout) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateGdiCompatibleTextLayout(@as(*const IDWriteFactory, @ptrCast(self)), string, stringLength, textFormat, layoutWidth, layoutHeight, pixelsPerDip, transform, useGdiNatural, textLayout);
            }
            pub inline fn CreateEllipsisTrimmingSign(self: *const T, textFormat: ?*IDWriteTextFormat, trimmingSign: ?*?*IDWriteInlineObject) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateEllipsisTrimmingSign(@as(*const IDWriteFactory, @ptrCast(self)), textFormat, trimmingSign);
            }
            pub inline fn CreateTextAnalyzer(self: *const T, textAnalyzer: ?*?*IDWriteTextAnalyzer) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateTextAnalyzer(@as(*const IDWriteFactory, @ptrCast(self)), textAnalyzer);
            }
            pub inline fn CreateNumberSubstitution(self: *const T, substitutionMethod: DWRITE_NUMBER_SUBSTITUTION_METHOD, localeName: ?[*:0]const u16, ignoreUserOverride: BOOL, numberSubstitution: ?*?*IDWriteNumberSubstitution) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateNumberSubstitution(@as(*const IDWriteFactory, @ptrCast(self)), substitutionMethod, localeName, ignoreUserOverride, numberSubstitution);
            }
            pub inline fn CreateGlyphRunAnalysis(self: *const T, glyphRun: ?*const DWRITE_GLYPH_RUN, pixelsPerDip: f32, transform: ?*const DWRITE_MATRIX, renderingMode: DWRITE_RENDERING_MODE, measuringMode: DWRITE_MEASURING_MODE, baselineOriginX: f32, baselineOriginY: f32, glyphRunAnalysis: ?*?*IDWriteGlyphRunAnalysis) HRESULT {
                return @as(*const IDWriteFactory.VTable, @ptrCast(self.vtable)).CreateGlyphRunAnalysis(@as(*const IDWriteFactory, @ptrCast(self)), glyphRun, pixelsPerDip, transform, renderingMode, measuringMode, baselineOriginX, baselineOriginY, glyphRunAnalysis);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_PANOSE_FAMILY = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    TEXT_DISPLAY = 2,
    SCRIPT = 3,
    DECORATIVE = 4,
    SYMBOL = 5,
    // PICTORIAL = 5, this enum value conflicts with SYMBOL
};
pub const DWRITE_PANOSE_FAMILY_ANY = DWRITE_PANOSE_FAMILY.ANY;
pub const DWRITE_PANOSE_FAMILY_NO_FIT = DWRITE_PANOSE_FAMILY.NO_FIT;
pub const DWRITE_PANOSE_FAMILY_TEXT_DISPLAY = DWRITE_PANOSE_FAMILY.TEXT_DISPLAY;
pub const DWRITE_PANOSE_FAMILY_SCRIPT = DWRITE_PANOSE_FAMILY.SCRIPT;
pub const DWRITE_PANOSE_FAMILY_DECORATIVE = DWRITE_PANOSE_FAMILY.DECORATIVE;
pub const DWRITE_PANOSE_FAMILY_SYMBOL = DWRITE_PANOSE_FAMILY.SYMBOL;
pub const DWRITE_PANOSE_FAMILY_PICTORIAL = DWRITE_PANOSE_FAMILY.SYMBOL;

pub const DWRITE_PANOSE_SERIF_STYLE = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    COVE = 2,
    OBTUSE_COVE = 3,
    SQUARE_COVE = 4,
    OBTUSE_SQUARE_COVE = 5,
    SQUARE = 6,
    THIN = 7,
    OVAL = 8,
    EXAGGERATED = 9,
    TRIANGLE = 10,
    NORMAL_SANS = 11,
    OBTUSE_SANS = 12,
    PERPENDICULAR_SANS = 13,
    FLARED = 14,
    ROUNDED = 15,
    SCRIPT = 16,
    // PERP_SANS = 13, this enum value conflicts with PERPENDICULAR_SANS
    // BONE = 8, this enum value conflicts with OVAL
};
pub const DWRITE_PANOSE_SERIF_STYLE_ANY = DWRITE_PANOSE_SERIF_STYLE.ANY;
pub const DWRITE_PANOSE_SERIF_STYLE_NO_FIT = DWRITE_PANOSE_SERIF_STYLE.NO_FIT;
pub const DWRITE_PANOSE_SERIF_STYLE_COVE = DWRITE_PANOSE_SERIF_STYLE.COVE;
pub const DWRITE_PANOSE_SERIF_STYLE_OBTUSE_COVE = DWRITE_PANOSE_SERIF_STYLE.OBTUSE_COVE;
pub const DWRITE_PANOSE_SERIF_STYLE_SQUARE_COVE = DWRITE_PANOSE_SERIF_STYLE.SQUARE_COVE;
pub const DWRITE_PANOSE_SERIF_STYLE_OBTUSE_SQUARE_COVE = DWRITE_PANOSE_SERIF_STYLE.OBTUSE_SQUARE_COVE;
pub const DWRITE_PANOSE_SERIF_STYLE_SQUARE = DWRITE_PANOSE_SERIF_STYLE.SQUARE;
pub const DWRITE_PANOSE_SERIF_STYLE_THIN = DWRITE_PANOSE_SERIF_STYLE.THIN;
pub const DWRITE_PANOSE_SERIF_STYLE_OVAL = DWRITE_PANOSE_SERIF_STYLE.OVAL;
pub const DWRITE_PANOSE_SERIF_STYLE_EXAGGERATED = DWRITE_PANOSE_SERIF_STYLE.EXAGGERATED;
pub const DWRITE_PANOSE_SERIF_STYLE_TRIANGLE = DWRITE_PANOSE_SERIF_STYLE.TRIANGLE;
pub const DWRITE_PANOSE_SERIF_STYLE_NORMAL_SANS = DWRITE_PANOSE_SERIF_STYLE.NORMAL_SANS;
pub const DWRITE_PANOSE_SERIF_STYLE_OBTUSE_SANS = DWRITE_PANOSE_SERIF_STYLE.OBTUSE_SANS;
pub const DWRITE_PANOSE_SERIF_STYLE_PERPENDICULAR_SANS = DWRITE_PANOSE_SERIF_STYLE.PERPENDICULAR_SANS;
pub const DWRITE_PANOSE_SERIF_STYLE_FLARED = DWRITE_PANOSE_SERIF_STYLE.FLARED;
pub const DWRITE_PANOSE_SERIF_STYLE_ROUNDED = DWRITE_PANOSE_SERIF_STYLE.ROUNDED;
pub const DWRITE_PANOSE_SERIF_STYLE_SCRIPT = DWRITE_PANOSE_SERIF_STYLE.SCRIPT;
pub const DWRITE_PANOSE_SERIF_STYLE_PERP_SANS = DWRITE_PANOSE_SERIF_STYLE.PERPENDICULAR_SANS;
pub const DWRITE_PANOSE_SERIF_STYLE_BONE = DWRITE_PANOSE_SERIF_STYLE.OVAL;

pub const DWRITE_PANOSE_WEIGHT = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    VERY_LIGHT = 2,
    LIGHT = 3,
    THIN = 4,
    BOOK = 5,
    MEDIUM = 6,
    DEMI = 7,
    BOLD = 8,
    HEAVY = 9,
    BLACK = 10,
    EXTRA_BLACK = 11,
    // NORD = 11, this enum value conflicts with EXTRA_BLACK
};
pub const DWRITE_PANOSE_WEIGHT_ANY = DWRITE_PANOSE_WEIGHT.ANY;
pub const DWRITE_PANOSE_WEIGHT_NO_FIT = DWRITE_PANOSE_WEIGHT.NO_FIT;
pub const DWRITE_PANOSE_WEIGHT_VERY_LIGHT = DWRITE_PANOSE_WEIGHT.VERY_LIGHT;
pub const DWRITE_PANOSE_WEIGHT_LIGHT = DWRITE_PANOSE_WEIGHT.LIGHT;
pub const DWRITE_PANOSE_WEIGHT_THIN = DWRITE_PANOSE_WEIGHT.THIN;
pub const DWRITE_PANOSE_WEIGHT_BOOK = DWRITE_PANOSE_WEIGHT.BOOK;
pub const DWRITE_PANOSE_WEIGHT_MEDIUM = DWRITE_PANOSE_WEIGHT.MEDIUM;
pub const DWRITE_PANOSE_WEIGHT_DEMI = DWRITE_PANOSE_WEIGHT.DEMI;
pub const DWRITE_PANOSE_WEIGHT_BOLD = DWRITE_PANOSE_WEIGHT.BOLD;
pub const DWRITE_PANOSE_WEIGHT_HEAVY = DWRITE_PANOSE_WEIGHT.HEAVY;
pub const DWRITE_PANOSE_WEIGHT_BLACK = DWRITE_PANOSE_WEIGHT.BLACK;
pub const DWRITE_PANOSE_WEIGHT_EXTRA_BLACK = DWRITE_PANOSE_WEIGHT.EXTRA_BLACK;
pub const DWRITE_PANOSE_WEIGHT_NORD = DWRITE_PANOSE_WEIGHT.EXTRA_BLACK;

pub const DWRITE_PANOSE_PROPORTION = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    OLD_STYLE = 2,
    MODERN = 3,
    EVEN_WIDTH = 4,
    EXPANDED = 5,
    CONDENSED = 6,
    VERY_EXPANDED = 7,
    VERY_CONDENSED = 8,
    MONOSPACED = 9,
};
pub const DWRITE_PANOSE_PROPORTION_ANY = DWRITE_PANOSE_PROPORTION.ANY;
pub const DWRITE_PANOSE_PROPORTION_NO_FIT = DWRITE_PANOSE_PROPORTION.NO_FIT;
pub const DWRITE_PANOSE_PROPORTION_OLD_STYLE = DWRITE_PANOSE_PROPORTION.OLD_STYLE;
pub const DWRITE_PANOSE_PROPORTION_MODERN = DWRITE_PANOSE_PROPORTION.MODERN;
pub const DWRITE_PANOSE_PROPORTION_EVEN_WIDTH = DWRITE_PANOSE_PROPORTION.EVEN_WIDTH;
pub const DWRITE_PANOSE_PROPORTION_EXPANDED = DWRITE_PANOSE_PROPORTION.EXPANDED;
pub const DWRITE_PANOSE_PROPORTION_CONDENSED = DWRITE_PANOSE_PROPORTION.CONDENSED;
pub const DWRITE_PANOSE_PROPORTION_VERY_EXPANDED = DWRITE_PANOSE_PROPORTION.VERY_EXPANDED;
pub const DWRITE_PANOSE_PROPORTION_VERY_CONDENSED = DWRITE_PANOSE_PROPORTION.VERY_CONDENSED;
pub const DWRITE_PANOSE_PROPORTION_MONOSPACED = DWRITE_PANOSE_PROPORTION.MONOSPACED;

pub const DWRITE_PANOSE_CONTRAST = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    NONE = 2,
    VERY_LOW = 3,
    LOW = 4,
    MEDIUM_LOW = 5,
    MEDIUM = 6,
    MEDIUM_HIGH = 7,
    HIGH = 8,
    VERY_HIGH = 9,
    HORIZONTAL_LOW = 10,
    HORIZONTAL_MEDIUM = 11,
    HORIZONTAL_HIGH = 12,
    BROKEN = 13,
};
pub const DWRITE_PANOSE_CONTRAST_ANY = DWRITE_PANOSE_CONTRAST.ANY;
pub const DWRITE_PANOSE_CONTRAST_NO_FIT = DWRITE_PANOSE_CONTRAST.NO_FIT;
pub const DWRITE_PANOSE_CONTRAST_NONE = DWRITE_PANOSE_CONTRAST.NONE;
pub const DWRITE_PANOSE_CONTRAST_VERY_LOW = DWRITE_PANOSE_CONTRAST.VERY_LOW;
pub const DWRITE_PANOSE_CONTRAST_LOW = DWRITE_PANOSE_CONTRAST.LOW;
pub const DWRITE_PANOSE_CONTRAST_MEDIUM_LOW = DWRITE_PANOSE_CONTRAST.MEDIUM_LOW;
pub const DWRITE_PANOSE_CONTRAST_MEDIUM = DWRITE_PANOSE_CONTRAST.MEDIUM;
pub const DWRITE_PANOSE_CONTRAST_MEDIUM_HIGH = DWRITE_PANOSE_CONTRAST.MEDIUM_HIGH;
pub const DWRITE_PANOSE_CONTRAST_HIGH = DWRITE_PANOSE_CONTRAST.HIGH;
pub const DWRITE_PANOSE_CONTRAST_VERY_HIGH = DWRITE_PANOSE_CONTRAST.VERY_HIGH;
pub const DWRITE_PANOSE_CONTRAST_HORIZONTAL_LOW = DWRITE_PANOSE_CONTRAST.HORIZONTAL_LOW;
pub const DWRITE_PANOSE_CONTRAST_HORIZONTAL_MEDIUM = DWRITE_PANOSE_CONTRAST.HORIZONTAL_MEDIUM;
pub const DWRITE_PANOSE_CONTRAST_HORIZONTAL_HIGH = DWRITE_PANOSE_CONTRAST.HORIZONTAL_HIGH;
pub const DWRITE_PANOSE_CONTRAST_BROKEN = DWRITE_PANOSE_CONTRAST.BROKEN;

pub const DWRITE_PANOSE_STROKE_VARIATION = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    NO_VARIATION = 2,
    GRADUAL_DIAGONAL = 3,
    GRADUAL_TRANSITIONAL = 4,
    GRADUAL_VERTICAL = 5,
    GRADUAL_HORIZONTAL = 6,
    RAPID_VERTICAL = 7,
    RAPID_HORIZONTAL = 8,
    INSTANT_VERTICAL = 9,
    INSTANT_HORIZONTAL = 10,
};
pub const DWRITE_PANOSE_STROKE_VARIATION_ANY = DWRITE_PANOSE_STROKE_VARIATION.ANY;
pub const DWRITE_PANOSE_STROKE_VARIATION_NO_FIT = DWRITE_PANOSE_STROKE_VARIATION.NO_FIT;
pub const DWRITE_PANOSE_STROKE_VARIATION_NO_VARIATION = DWRITE_PANOSE_STROKE_VARIATION.NO_VARIATION;
pub const DWRITE_PANOSE_STROKE_VARIATION_GRADUAL_DIAGONAL = DWRITE_PANOSE_STROKE_VARIATION.GRADUAL_DIAGONAL;
pub const DWRITE_PANOSE_STROKE_VARIATION_GRADUAL_TRANSITIONAL = DWRITE_PANOSE_STROKE_VARIATION.GRADUAL_TRANSITIONAL;
pub const DWRITE_PANOSE_STROKE_VARIATION_GRADUAL_VERTICAL = DWRITE_PANOSE_STROKE_VARIATION.GRADUAL_VERTICAL;
pub const DWRITE_PANOSE_STROKE_VARIATION_GRADUAL_HORIZONTAL = DWRITE_PANOSE_STROKE_VARIATION.GRADUAL_HORIZONTAL;
pub const DWRITE_PANOSE_STROKE_VARIATION_RAPID_VERTICAL = DWRITE_PANOSE_STROKE_VARIATION.RAPID_VERTICAL;
pub const DWRITE_PANOSE_STROKE_VARIATION_RAPID_HORIZONTAL = DWRITE_PANOSE_STROKE_VARIATION.RAPID_HORIZONTAL;
pub const DWRITE_PANOSE_STROKE_VARIATION_INSTANT_VERTICAL = DWRITE_PANOSE_STROKE_VARIATION.INSTANT_VERTICAL;
pub const DWRITE_PANOSE_STROKE_VARIATION_INSTANT_HORIZONTAL = DWRITE_PANOSE_STROKE_VARIATION.INSTANT_HORIZONTAL;

pub const DWRITE_PANOSE_ARM_STYLE = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    STRAIGHT_ARMS_HORIZONTAL = 2,
    STRAIGHT_ARMS_WEDGE = 3,
    STRAIGHT_ARMS_VERTICAL = 4,
    STRAIGHT_ARMS_SINGLE_SERIF = 5,
    STRAIGHT_ARMS_DOUBLE_SERIF = 6,
    NONSTRAIGHT_ARMS_HORIZONTAL = 7,
    NONSTRAIGHT_ARMS_WEDGE = 8,
    NONSTRAIGHT_ARMS_VERTICAL = 9,
    NONSTRAIGHT_ARMS_SINGLE_SERIF = 10,
    NONSTRAIGHT_ARMS_DOUBLE_SERIF = 11,
    // STRAIGHT_ARMS_HORZ = 2, this enum value conflicts with STRAIGHT_ARMS_HORIZONTAL
    // STRAIGHT_ARMS_VERT = 4, this enum value conflicts with STRAIGHT_ARMS_VERTICAL
    // BENT_ARMS_HORZ = 7, this enum value conflicts with NONSTRAIGHT_ARMS_HORIZONTAL
    // BENT_ARMS_WEDGE = 8, this enum value conflicts with NONSTRAIGHT_ARMS_WEDGE
    // BENT_ARMS_VERT = 9, this enum value conflicts with NONSTRAIGHT_ARMS_VERTICAL
    // BENT_ARMS_SINGLE_SERIF = 10, this enum value conflicts with NONSTRAIGHT_ARMS_SINGLE_SERIF
    // BENT_ARMS_DOUBLE_SERIF = 11, this enum value conflicts with NONSTRAIGHT_ARMS_DOUBLE_SERIF
};
pub const DWRITE_PANOSE_ARM_STYLE_ANY = DWRITE_PANOSE_ARM_STYLE.ANY;
pub const DWRITE_PANOSE_ARM_STYLE_NO_FIT = DWRITE_PANOSE_ARM_STYLE.NO_FIT;
pub const DWRITE_PANOSE_ARM_STYLE_STRAIGHT_ARMS_HORIZONTAL = DWRITE_PANOSE_ARM_STYLE.STRAIGHT_ARMS_HORIZONTAL;
pub const DWRITE_PANOSE_ARM_STYLE_STRAIGHT_ARMS_WEDGE = DWRITE_PANOSE_ARM_STYLE.STRAIGHT_ARMS_WEDGE;
pub const DWRITE_PANOSE_ARM_STYLE_STRAIGHT_ARMS_VERTICAL = DWRITE_PANOSE_ARM_STYLE.STRAIGHT_ARMS_VERTICAL;
pub const DWRITE_PANOSE_ARM_STYLE_STRAIGHT_ARMS_SINGLE_SERIF = DWRITE_PANOSE_ARM_STYLE.STRAIGHT_ARMS_SINGLE_SERIF;
pub const DWRITE_PANOSE_ARM_STYLE_STRAIGHT_ARMS_DOUBLE_SERIF = DWRITE_PANOSE_ARM_STYLE.STRAIGHT_ARMS_DOUBLE_SERIF;
pub const DWRITE_PANOSE_ARM_STYLE_NONSTRAIGHT_ARMS_HORIZONTAL = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_HORIZONTAL;
pub const DWRITE_PANOSE_ARM_STYLE_NONSTRAIGHT_ARMS_WEDGE = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_WEDGE;
pub const DWRITE_PANOSE_ARM_STYLE_NONSTRAIGHT_ARMS_VERTICAL = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_VERTICAL;
pub const DWRITE_PANOSE_ARM_STYLE_NONSTRAIGHT_ARMS_SINGLE_SERIF = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_SINGLE_SERIF;
pub const DWRITE_PANOSE_ARM_STYLE_NONSTRAIGHT_ARMS_DOUBLE_SERIF = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_DOUBLE_SERIF;
pub const DWRITE_PANOSE_ARM_STYLE_STRAIGHT_ARMS_HORZ = DWRITE_PANOSE_ARM_STYLE.STRAIGHT_ARMS_HORIZONTAL;
pub const DWRITE_PANOSE_ARM_STYLE_STRAIGHT_ARMS_VERT = DWRITE_PANOSE_ARM_STYLE.STRAIGHT_ARMS_VERTICAL;
pub const DWRITE_PANOSE_ARM_STYLE_BENT_ARMS_HORZ = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_HORIZONTAL;
pub const DWRITE_PANOSE_ARM_STYLE_BENT_ARMS_WEDGE = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_WEDGE;
pub const DWRITE_PANOSE_ARM_STYLE_BENT_ARMS_VERT = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_VERTICAL;
pub const DWRITE_PANOSE_ARM_STYLE_BENT_ARMS_SINGLE_SERIF = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_SINGLE_SERIF;
pub const DWRITE_PANOSE_ARM_STYLE_BENT_ARMS_DOUBLE_SERIF = DWRITE_PANOSE_ARM_STYLE.NONSTRAIGHT_ARMS_DOUBLE_SERIF;

pub const DWRITE_PANOSE_LETTERFORM = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    NORMAL_CONTACT = 2,
    NORMAL_WEIGHTED = 3,
    NORMAL_BOXED = 4,
    NORMAL_FLATTENED = 5,
    NORMAL_ROUNDED = 6,
    NORMAL_OFF_CENTER = 7,
    NORMAL_SQUARE = 8,
    OBLIQUE_CONTACT = 9,
    OBLIQUE_WEIGHTED = 10,
    OBLIQUE_BOXED = 11,
    OBLIQUE_FLATTENED = 12,
    OBLIQUE_ROUNDED = 13,
    OBLIQUE_OFF_CENTER = 14,
    OBLIQUE_SQUARE = 15,
};
pub const DWRITE_PANOSE_LETTERFORM_ANY = DWRITE_PANOSE_LETTERFORM.ANY;
pub const DWRITE_PANOSE_LETTERFORM_NO_FIT = DWRITE_PANOSE_LETTERFORM.NO_FIT;
pub const DWRITE_PANOSE_LETTERFORM_NORMAL_CONTACT = DWRITE_PANOSE_LETTERFORM.NORMAL_CONTACT;
pub const DWRITE_PANOSE_LETTERFORM_NORMAL_WEIGHTED = DWRITE_PANOSE_LETTERFORM.NORMAL_WEIGHTED;
pub const DWRITE_PANOSE_LETTERFORM_NORMAL_BOXED = DWRITE_PANOSE_LETTERFORM.NORMAL_BOXED;
pub const DWRITE_PANOSE_LETTERFORM_NORMAL_FLATTENED = DWRITE_PANOSE_LETTERFORM.NORMAL_FLATTENED;
pub const DWRITE_PANOSE_LETTERFORM_NORMAL_ROUNDED = DWRITE_PANOSE_LETTERFORM.NORMAL_ROUNDED;
pub const DWRITE_PANOSE_LETTERFORM_NORMAL_OFF_CENTER = DWRITE_PANOSE_LETTERFORM.NORMAL_OFF_CENTER;
pub const DWRITE_PANOSE_LETTERFORM_NORMAL_SQUARE = DWRITE_PANOSE_LETTERFORM.NORMAL_SQUARE;
pub const DWRITE_PANOSE_LETTERFORM_OBLIQUE_CONTACT = DWRITE_PANOSE_LETTERFORM.OBLIQUE_CONTACT;
pub const DWRITE_PANOSE_LETTERFORM_OBLIQUE_WEIGHTED = DWRITE_PANOSE_LETTERFORM.OBLIQUE_WEIGHTED;
pub const DWRITE_PANOSE_LETTERFORM_OBLIQUE_BOXED = DWRITE_PANOSE_LETTERFORM.OBLIQUE_BOXED;
pub const DWRITE_PANOSE_LETTERFORM_OBLIQUE_FLATTENED = DWRITE_PANOSE_LETTERFORM.OBLIQUE_FLATTENED;
pub const DWRITE_PANOSE_LETTERFORM_OBLIQUE_ROUNDED = DWRITE_PANOSE_LETTERFORM.OBLIQUE_ROUNDED;
pub const DWRITE_PANOSE_LETTERFORM_OBLIQUE_OFF_CENTER = DWRITE_PANOSE_LETTERFORM.OBLIQUE_OFF_CENTER;
pub const DWRITE_PANOSE_LETTERFORM_OBLIQUE_SQUARE = DWRITE_PANOSE_LETTERFORM.OBLIQUE_SQUARE;

pub const DWRITE_PANOSE_MIDLINE = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    STANDARD_TRIMMED = 2,
    STANDARD_POINTED = 3,
    STANDARD_SERIFED = 4,
    HIGH_TRIMMED = 5,
    HIGH_POINTED = 6,
    HIGH_SERIFED = 7,
    CONSTANT_TRIMMED = 8,
    CONSTANT_POINTED = 9,
    CONSTANT_SERIFED = 10,
    LOW_TRIMMED = 11,
    LOW_POINTED = 12,
    LOW_SERIFED = 13,
};
pub const DWRITE_PANOSE_MIDLINE_ANY = DWRITE_PANOSE_MIDLINE.ANY;
pub const DWRITE_PANOSE_MIDLINE_NO_FIT = DWRITE_PANOSE_MIDLINE.NO_FIT;
pub const DWRITE_PANOSE_MIDLINE_STANDARD_TRIMMED = DWRITE_PANOSE_MIDLINE.STANDARD_TRIMMED;
pub const DWRITE_PANOSE_MIDLINE_STANDARD_POINTED = DWRITE_PANOSE_MIDLINE.STANDARD_POINTED;
pub const DWRITE_PANOSE_MIDLINE_STANDARD_SERIFED = DWRITE_PANOSE_MIDLINE.STANDARD_SERIFED;
pub const DWRITE_PANOSE_MIDLINE_HIGH_TRIMMED = DWRITE_PANOSE_MIDLINE.HIGH_TRIMMED;
pub const DWRITE_PANOSE_MIDLINE_HIGH_POINTED = DWRITE_PANOSE_MIDLINE.HIGH_POINTED;
pub const DWRITE_PANOSE_MIDLINE_HIGH_SERIFED = DWRITE_PANOSE_MIDLINE.HIGH_SERIFED;
pub const DWRITE_PANOSE_MIDLINE_CONSTANT_TRIMMED = DWRITE_PANOSE_MIDLINE.CONSTANT_TRIMMED;
pub const DWRITE_PANOSE_MIDLINE_CONSTANT_POINTED = DWRITE_PANOSE_MIDLINE.CONSTANT_POINTED;
pub const DWRITE_PANOSE_MIDLINE_CONSTANT_SERIFED = DWRITE_PANOSE_MIDLINE.CONSTANT_SERIFED;
pub const DWRITE_PANOSE_MIDLINE_LOW_TRIMMED = DWRITE_PANOSE_MIDLINE.LOW_TRIMMED;
pub const DWRITE_PANOSE_MIDLINE_LOW_POINTED = DWRITE_PANOSE_MIDLINE.LOW_POINTED;
pub const DWRITE_PANOSE_MIDLINE_LOW_SERIFED = DWRITE_PANOSE_MIDLINE.LOW_SERIFED;

pub const DWRITE_PANOSE_XHEIGHT = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    CONSTANT_SMALL = 2,
    CONSTANT_STANDARD = 3,
    CONSTANT_LARGE = 4,
    DUCKING_SMALL = 5,
    DUCKING_STANDARD = 6,
    DUCKING_LARGE = 7,
    // CONSTANT_STD = 3, this enum value conflicts with CONSTANT_STANDARD
    // DUCKING_STD = 6, this enum value conflicts with DUCKING_STANDARD
};
pub const DWRITE_PANOSE_XHEIGHT_ANY = DWRITE_PANOSE_XHEIGHT.ANY;
pub const DWRITE_PANOSE_XHEIGHT_NO_FIT = DWRITE_PANOSE_XHEIGHT.NO_FIT;
pub const DWRITE_PANOSE_XHEIGHT_CONSTANT_SMALL = DWRITE_PANOSE_XHEIGHT.CONSTANT_SMALL;
pub const DWRITE_PANOSE_XHEIGHT_CONSTANT_STANDARD = DWRITE_PANOSE_XHEIGHT.CONSTANT_STANDARD;
pub const DWRITE_PANOSE_XHEIGHT_CONSTANT_LARGE = DWRITE_PANOSE_XHEIGHT.CONSTANT_LARGE;
pub const DWRITE_PANOSE_XHEIGHT_DUCKING_SMALL = DWRITE_PANOSE_XHEIGHT.DUCKING_SMALL;
pub const DWRITE_PANOSE_XHEIGHT_DUCKING_STANDARD = DWRITE_PANOSE_XHEIGHT.DUCKING_STANDARD;
pub const DWRITE_PANOSE_XHEIGHT_DUCKING_LARGE = DWRITE_PANOSE_XHEIGHT.DUCKING_LARGE;
pub const DWRITE_PANOSE_XHEIGHT_CONSTANT_STD = DWRITE_PANOSE_XHEIGHT.CONSTANT_STANDARD;
pub const DWRITE_PANOSE_XHEIGHT_DUCKING_STD = DWRITE_PANOSE_XHEIGHT.DUCKING_STANDARD;

pub const DWRITE_PANOSE_TOOL_KIND = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    FLAT_NIB = 2,
    PRESSURE_POINT = 3,
    ENGRAVED = 4,
    BALL = 5,
    BRUSH = 6,
    ROUGH = 7,
    FELT_PEN_BRUSH_TIP = 8,
    WILD_BRUSH = 9,
};
pub const DWRITE_PANOSE_TOOL_KIND_ANY = DWRITE_PANOSE_TOOL_KIND.ANY;
pub const DWRITE_PANOSE_TOOL_KIND_NO_FIT = DWRITE_PANOSE_TOOL_KIND.NO_FIT;
pub const DWRITE_PANOSE_TOOL_KIND_FLAT_NIB = DWRITE_PANOSE_TOOL_KIND.FLAT_NIB;
pub const DWRITE_PANOSE_TOOL_KIND_PRESSURE_POINT = DWRITE_PANOSE_TOOL_KIND.PRESSURE_POINT;
pub const DWRITE_PANOSE_TOOL_KIND_ENGRAVED = DWRITE_PANOSE_TOOL_KIND.ENGRAVED;
pub const DWRITE_PANOSE_TOOL_KIND_BALL = DWRITE_PANOSE_TOOL_KIND.BALL;
pub const DWRITE_PANOSE_TOOL_KIND_BRUSH = DWRITE_PANOSE_TOOL_KIND.BRUSH;
pub const DWRITE_PANOSE_TOOL_KIND_ROUGH = DWRITE_PANOSE_TOOL_KIND.ROUGH;
pub const DWRITE_PANOSE_TOOL_KIND_FELT_PEN_BRUSH_TIP = DWRITE_PANOSE_TOOL_KIND.FELT_PEN_BRUSH_TIP;
pub const DWRITE_PANOSE_TOOL_KIND_WILD_BRUSH = DWRITE_PANOSE_TOOL_KIND.WILD_BRUSH;

pub const DWRITE_PANOSE_SPACING = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    PROPORTIONAL_SPACED = 2,
    MONOSPACED = 3,
};
pub const DWRITE_PANOSE_SPACING_ANY = DWRITE_PANOSE_SPACING.ANY;
pub const DWRITE_PANOSE_SPACING_NO_FIT = DWRITE_PANOSE_SPACING.NO_FIT;
pub const DWRITE_PANOSE_SPACING_PROPORTIONAL_SPACED = DWRITE_PANOSE_SPACING.PROPORTIONAL_SPACED;
pub const DWRITE_PANOSE_SPACING_MONOSPACED = DWRITE_PANOSE_SPACING.MONOSPACED;

pub const DWRITE_PANOSE_ASPECT_RATIO = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    VERY_CONDENSED = 2,
    CONDENSED = 3,
    NORMAL = 4,
    EXPANDED = 5,
    VERY_EXPANDED = 6,
};
pub const DWRITE_PANOSE_ASPECT_RATIO_ANY = DWRITE_PANOSE_ASPECT_RATIO.ANY;
pub const DWRITE_PANOSE_ASPECT_RATIO_NO_FIT = DWRITE_PANOSE_ASPECT_RATIO.NO_FIT;
pub const DWRITE_PANOSE_ASPECT_RATIO_VERY_CONDENSED = DWRITE_PANOSE_ASPECT_RATIO.VERY_CONDENSED;
pub const DWRITE_PANOSE_ASPECT_RATIO_CONDENSED = DWRITE_PANOSE_ASPECT_RATIO.CONDENSED;
pub const DWRITE_PANOSE_ASPECT_RATIO_NORMAL = DWRITE_PANOSE_ASPECT_RATIO.NORMAL;
pub const DWRITE_PANOSE_ASPECT_RATIO_EXPANDED = DWRITE_PANOSE_ASPECT_RATIO.EXPANDED;
pub const DWRITE_PANOSE_ASPECT_RATIO_VERY_EXPANDED = DWRITE_PANOSE_ASPECT_RATIO.VERY_EXPANDED;

pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    ROMAN_DISCONNECTED = 2,
    ROMAN_TRAILING = 3,
    ROMAN_CONNECTED = 4,
    CURSIVE_DISCONNECTED = 5,
    CURSIVE_TRAILING = 6,
    CURSIVE_CONNECTED = 7,
    BLACKLETTER_DISCONNECTED = 8,
    BLACKLETTER_TRAILING = 9,
    BLACKLETTER_CONNECTED = 10,
};
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_ANY = DWRITE_PANOSE_SCRIPT_TOPOLOGY.ANY;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_NO_FIT = DWRITE_PANOSE_SCRIPT_TOPOLOGY.NO_FIT;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_ROMAN_DISCONNECTED = DWRITE_PANOSE_SCRIPT_TOPOLOGY.ROMAN_DISCONNECTED;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_ROMAN_TRAILING = DWRITE_PANOSE_SCRIPT_TOPOLOGY.ROMAN_TRAILING;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_ROMAN_CONNECTED = DWRITE_PANOSE_SCRIPT_TOPOLOGY.ROMAN_CONNECTED;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_CURSIVE_DISCONNECTED = DWRITE_PANOSE_SCRIPT_TOPOLOGY.CURSIVE_DISCONNECTED;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_CURSIVE_TRAILING = DWRITE_PANOSE_SCRIPT_TOPOLOGY.CURSIVE_TRAILING;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_CURSIVE_CONNECTED = DWRITE_PANOSE_SCRIPT_TOPOLOGY.CURSIVE_CONNECTED;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_BLACKLETTER_DISCONNECTED = DWRITE_PANOSE_SCRIPT_TOPOLOGY.BLACKLETTER_DISCONNECTED;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_BLACKLETTER_TRAILING = DWRITE_PANOSE_SCRIPT_TOPOLOGY.BLACKLETTER_TRAILING;
pub const DWRITE_PANOSE_SCRIPT_TOPOLOGY_BLACKLETTER_CONNECTED = DWRITE_PANOSE_SCRIPT_TOPOLOGY.BLACKLETTER_CONNECTED;

pub const DWRITE_PANOSE_SCRIPT_FORM = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    UPRIGHT_NO_WRAPPING = 2,
    UPRIGHT_SOME_WRAPPING = 3,
    UPRIGHT_MORE_WRAPPING = 4,
    UPRIGHT_EXTREME_WRAPPING = 5,
    OBLIQUE_NO_WRAPPING = 6,
    OBLIQUE_SOME_WRAPPING = 7,
    OBLIQUE_MORE_WRAPPING = 8,
    OBLIQUE_EXTREME_WRAPPING = 9,
    EXAGGERATED_NO_WRAPPING = 10,
    EXAGGERATED_SOME_WRAPPING = 11,
    EXAGGERATED_MORE_WRAPPING = 12,
    EXAGGERATED_EXTREME_WRAPPING = 13,
};
pub const DWRITE_PANOSE_SCRIPT_FORM_ANY = DWRITE_PANOSE_SCRIPT_FORM.ANY;
pub const DWRITE_PANOSE_SCRIPT_FORM_NO_FIT = DWRITE_PANOSE_SCRIPT_FORM.NO_FIT;
pub const DWRITE_PANOSE_SCRIPT_FORM_UPRIGHT_NO_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.UPRIGHT_NO_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_UPRIGHT_SOME_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.UPRIGHT_SOME_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_UPRIGHT_MORE_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.UPRIGHT_MORE_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_UPRIGHT_EXTREME_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.UPRIGHT_EXTREME_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_OBLIQUE_NO_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.OBLIQUE_NO_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_OBLIQUE_SOME_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.OBLIQUE_SOME_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_OBLIQUE_MORE_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.OBLIQUE_MORE_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_OBLIQUE_EXTREME_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.OBLIQUE_EXTREME_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_EXAGGERATED_NO_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.EXAGGERATED_NO_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_EXAGGERATED_SOME_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.EXAGGERATED_SOME_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_EXAGGERATED_MORE_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.EXAGGERATED_MORE_WRAPPING;
pub const DWRITE_PANOSE_SCRIPT_FORM_EXAGGERATED_EXTREME_WRAPPING = DWRITE_PANOSE_SCRIPT_FORM.EXAGGERATED_EXTREME_WRAPPING;

pub const DWRITE_PANOSE_FINIALS = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    NONE_NO_LOOPS = 2,
    NONE_CLOSED_LOOPS = 3,
    NONE_OPEN_LOOPS = 4,
    SHARP_NO_LOOPS = 5,
    SHARP_CLOSED_LOOPS = 6,
    SHARP_OPEN_LOOPS = 7,
    TAPERED_NO_LOOPS = 8,
    TAPERED_CLOSED_LOOPS = 9,
    TAPERED_OPEN_LOOPS = 10,
    ROUND_NO_LOOPS = 11,
    ROUND_CLOSED_LOOPS = 12,
    ROUND_OPEN_LOOPS = 13,
};
pub const DWRITE_PANOSE_FINIALS_ANY = DWRITE_PANOSE_FINIALS.ANY;
pub const DWRITE_PANOSE_FINIALS_NO_FIT = DWRITE_PANOSE_FINIALS.NO_FIT;
pub const DWRITE_PANOSE_FINIALS_NONE_NO_LOOPS = DWRITE_PANOSE_FINIALS.NONE_NO_LOOPS;
pub const DWRITE_PANOSE_FINIALS_NONE_CLOSED_LOOPS = DWRITE_PANOSE_FINIALS.NONE_CLOSED_LOOPS;
pub const DWRITE_PANOSE_FINIALS_NONE_OPEN_LOOPS = DWRITE_PANOSE_FINIALS.NONE_OPEN_LOOPS;
pub const DWRITE_PANOSE_FINIALS_SHARP_NO_LOOPS = DWRITE_PANOSE_FINIALS.SHARP_NO_LOOPS;
pub const DWRITE_PANOSE_FINIALS_SHARP_CLOSED_LOOPS = DWRITE_PANOSE_FINIALS.SHARP_CLOSED_LOOPS;
pub const DWRITE_PANOSE_FINIALS_SHARP_OPEN_LOOPS = DWRITE_PANOSE_FINIALS.SHARP_OPEN_LOOPS;
pub const DWRITE_PANOSE_FINIALS_TAPERED_NO_LOOPS = DWRITE_PANOSE_FINIALS.TAPERED_NO_LOOPS;
pub const DWRITE_PANOSE_FINIALS_TAPERED_CLOSED_LOOPS = DWRITE_PANOSE_FINIALS.TAPERED_CLOSED_LOOPS;
pub const DWRITE_PANOSE_FINIALS_TAPERED_OPEN_LOOPS = DWRITE_PANOSE_FINIALS.TAPERED_OPEN_LOOPS;
pub const DWRITE_PANOSE_FINIALS_ROUND_NO_LOOPS = DWRITE_PANOSE_FINIALS.ROUND_NO_LOOPS;
pub const DWRITE_PANOSE_FINIALS_ROUND_CLOSED_LOOPS = DWRITE_PANOSE_FINIALS.ROUND_CLOSED_LOOPS;
pub const DWRITE_PANOSE_FINIALS_ROUND_OPEN_LOOPS = DWRITE_PANOSE_FINIALS.ROUND_OPEN_LOOPS;

pub const DWRITE_PANOSE_XASCENT = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    VERY_LOW = 2,
    LOW = 3,
    MEDIUM = 4,
    HIGH = 5,
    VERY_HIGH = 6,
};
pub const DWRITE_PANOSE_XASCENT_ANY = DWRITE_PANOSE_XASCENT.ANY;
pub const DWRITE_PANOSE_XASCENT_NO_FIT = DWRITE_PANOSE_XASCENT.NO_FIT;
pub const DWRITE_PANOSE_XASCENT_VERY_LOW = DWRITE_PANOSE_XASCENT.VERY_LOW;
pub const DWRITE_PANOSE_XASCENT_LOW = DWRITE_PANOSE_XASCENT.LOW;
pub const DWRITE_PANOSE_XASCENT_MEDIUM = DWRITE_PANOSE_XASCENT.MEDIUM;
pub const DWRITE_PANOSE_XASCENT_HIGH = DWRITE_PANOSE_XASCENT.HIGH;
pub const DWRITE_PANOSE_XASCENT_VERY_HIGH = DWRITE_PANOSE_XASCENT.VERY_HIGH;

pub const DWRITE_PANOSE_DECORATIVE_CLASS = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    DERIVATIVE = 2,
    NONSTANDARD_TOPOLOGY = 3,
    NONSTANDARD_ELEMENTS = 4,
    NONSTANDARD_ASPECT = 5,
    INITIALS = 6,
    CARTOON = 7,
    PICTURE_STEMS = 8,
    ORNAMENTED = 9,
    TEXT_AND_BACKGROUND = 10,
    COLLAGE = 11,
    MONTAGE = 12,
};
pub const DWRITE_PANOSE_DECORATIVE_CLASS_ANY = DWRITE_PANOSE_DECORATIVE_CLASS.ANY;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_NO_FIT = DWRITE_PANOSE_DECORATIVE_CLASS.NO_FIT;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_DERIVATIVE = DWRITE_PANOSE_DECORATIVE_CLASS.DERIVATIVE;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_NONSTANDARD_TOPOLOGY = DWRITE_PANOSE_DECORATIVE_CLASS.NONSTANDARD_TOPOLOGY;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_NONSTANDARD_ELEMENTS = DWRITE_PANOSE_DECORATIVE_CLASS.NONSTANDARD_ELEMENTS;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_NONSTANDARD_ASPECT = DWRITE_PANOSE_DECORATIVE_CLASS.NONSTANDARD_ASPECT;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_INITIALS = DWRITE_PANOSE_DECORATIVE_CLASS.INITIALS;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_CARTOON = DWRITE_PANOSE_DECORATIVE_CLASS.CARTOON;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_PICTURE_STEMS = DWRITE_PANOSE_DECORATIVE_CLASS.PICTURE_STEMS;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_ORNAMENTED = DWRITE_PANOSE_DECORATIVE_CLASS.ORNAMENTED;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_TEXT_AND_BACKGROUND = DWRITE_PANOSE_DECORATIVE_CLASS.TEXT_AND_BACKGROUND;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_COLLAGE = DWRITE_PANOSE_DECORATIVE_CLASS.COLLAGE;
pub const DWRITE_PANOSE_DECORATIVE_CLASS_MONTAGE = DWRITE_PANOSE_DECORATIVE_CLASS.MONTAGE;

pub const DWRITE_PANOSE_ASPECT = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    SUPER_CONDENSED = 2,
    VERY_CONDENSED = 3,
    CONDENSED = 4,
    NORMAL = 5,
    EXTENDED = 6,
    VERY_EXTENDED = 7,
    SUPER_EXTENDED = 8,
    MONOSPACED = 9,
};
pub const DWRITE_PANOSE_ASPECT_ANY = DWRITE_PANOSE_ASPECT.ANY;
pub const DWRITE_PANOSE_ASPECT_NO_FIT = DWRITE_PANOSE_ASPECT.NO_FIT;
pub const DWRITE_PANOSE_ASPECT_SUPER_CONDENSED = DWRITE_PANOSE_ASPECT.SUPER_CONDENSED;
pub const DWRITE_PANOSE_ASPECT_VERY_CONDENSED = DWRITE_PANOSE_ASPECT.VERY_CONDENSED;
pub const DWRITE_PANOSE_ASPECT_CONDENSED = DWRITE_PANOSE_ASPECT.CONDENSED;
pub const DWRITE_PANOSE_ASPECT_NORMAL = DWRITE_PANOSE_ASPECT.NORMAL;
pub const DWRITE_PANOSE_ASPECT_EXTENDED = DWRITE_PANOSE_ASPECT.EXTENDED;
pub const DWRITE_PANOSE_ASPECT_VERY_EXTENDED = DWRITE_PANOSE_ASPECT.VERY_EXTENDED;
pub const DWRITE_PANOSE_ASPECT_SUPER_EXTENDED = DWRITE_PANOSE_ASPECT.SUPER_EXTENDED;
pub const DWRITE_PANOSE_ASPECT_MONOSPACED = DWRITE_PANOSE_ASPECT.MONOSPACED;

pub const DWRITE_PANOSE_FILL = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    STANDARD_SOLID_FILL = 2,
    NO_FILL = 3,
    PATTERNED_FILL = 4,
    COMPLEX_FILL = 5,
    SHAPED_FILL = 6,
    DRAWN_DISTRESSED = 7,
};
pub const DWRITE_PANOSE_FILL_ANY = DWRITE_PANOSE_FILL.ANY;
pub const DWRITE_PANOSE_FILL_NO_FIT = DWRITE_PANOSE_FILL.NO_FIT;
pub const DWRITE_PANOSE_FILL_STANDARD_SOLID_FILL = DWRITE_PANOSE_FILL.STANDARD_SOLID_FILL;
pub const DWRITE_PANOSE_FILL_NO_FILL = DWRITE_PANOSE_FILL.NO_FILL;
pub const DWRITE_PANOSE_FILL_PATTERNED_FILL = DWRITE_PANOSE_FILL.PATTERNED_FILL;
pub const DWRITE_PANOSE_FILL_COMPLEX_FILL = DWRITE_PANOSE_FILL.COMPLEX_FILL;
pub const DWRITE_PANOSE_FILL_SHAPED_FILL = DWRITE_PANOSE_FILL.SHAPED_FILL;
pub const DWRITE_PANOSE_FILL_DRAWN_DISTRESSED = DWRITE_PANOSE_FILL.DRAWN_DISTRESSED;

pub const DWRITE_PANOSE_LINING = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    NONE = 2,
    INLINE = 3,
    OUTLINE = 4,
    ENGRAVED = 5,
    SHADOW = 6,
    RELIEF = 7,
    BACKDROP = 8,
};
pub const DWRITE_PANOSE_LINING_ANY = DWRITE_PANOSE_LINING.ANY;
pub const DWRITE_PANOSE_LINING_NO_FIT = DWRITE_PANOSE_LINING.NO_FIT;
pub const DWRITE_PANOSE_LINING_NONE = DWRITE_PANOSE_LINING.NONE;
pub const DWRITE_PANOSE_LINING_INLINE = DWRITE_PANOSE_LINING.INLINE;
pub const DWRITE_PANOSE_LINING_OUTLINE = DWRITE_PANOSE_LINING.OUTLINE;
pub const DWRITE_PANOSE_LINING_ENGRAVED = DWRITE_PANOSE_LINING.ENGRAVED;
pub const DWRITE_PANOSE_LINING_SHADOW = DWRITE_PANOSE_LINING.SHADOW;
pub const DWRITE_PANOSE_LINING_RELIEF = DWRITE_PANOSE_LINING.RELIEF;
pub const DWRITE_PANOSE_LINING_BACKDROP = DWRITE_PANOSE_LINING.BACKDROP;

pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    STANDARD = 2,
    SQUARE = 3,
    MULTIPLE_SEGMENT = 4,
    ART_DECO = 5,
    UNEVEN_WEIGHTING = 6,
    DIVERSE_ARMS = 7,
    DIVERSE_FORMS = 8,
    LOMBARDIC_FORMS = 9,
    UPPER_CASE_IN_LOWER_CASE = 10,
    IMPLIED_TOPOLOGY = 11,
    HORSESHOE_E_AND_A = 12,
    CURSIVE = 13,
    BLACKLETTER = 14,
    SWASH_VARIANCE = 15,
};
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_ANY = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.ANY;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_NO_FIT = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.NO_FIT;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_STANDARD = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.STANDARD;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_SQUARE = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.SQUARE;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_MULTIPLE_SEGMENT = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.MULTIPLE_SEGMENT;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_ART_DECO = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.ART_DECO;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_UNEVEN_WEIGHTING = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.UNEVEN_WEIGHTING;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_DIVERSE_ARMS = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.DIVERSE_ARMS;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_DIVERSE_FORMS = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.DIVERSE_FORMS;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_LOMBARDIC_FORMS = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.LOMBARDIC_FORMS;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_UPPER_CASE_IN_LOWER_CASE = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.UPPER_CASE_IN_LOWER_CASE;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_IMPLIED_TOPOLOGY = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.IMPLIED_TOPOLOGY;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_HORSESHOE_E_AND_A = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.HORSESHOE_E_AND_A;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_CURSIVE = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.CURSIVE;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_BLACKLETTER = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.BLACKLETTER;
pub const DWRITE_PANOSE_DECORATIVE_TOPOLOGY_SWASH_VARIANCE = DWRITE_PANOSE_DECORATIVE_TOPOLOGY.SWASH_VARIANCE;

pub const DWRITE_PANOSE_CHARACTER_RANGES = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    EXTENDED_COLLECTION = 2,
    LITERALS = 3,
    NO_LOWER_CASE = 4,
    SMALL_CAPS = 5,
};
pub const DWRITE_PANOSE_CHARACTER_RANGES_ANY = DWRITE_PANOSE_CHARACTER_RANGES.ANY;
pub const DWRITE_PANOSE_CHARACTER_RANGES_NO_FIT = DWRITE_PANOSE_CHARACTER_RANGES.NO_FIT;
pub const DWRITE_PANOSE_CHARACTER_RANGES_EXTENDED_COLLECTION = DWRITE_PANOSE_CHARACTER_RANGES.EXTENDED_COLLECTION;
pub const DWRITE_PANOSE_CHARACTER_RANGES_LITERALS = DWRITE_PANOSE_CHARACTER_RANGES.LITERALS;
pub const DWRITE_PANOSE_CHARACTER_RANGES_NO_LOWER_CASE = DWRITE_PANOSE_CHARACTER_RANGES.NO_LOWER_CASE;
pub const DWRITE_PANOSE_CHARACTER_RANGES_SMALL_CAPS = DWRITE_PANOSE_CHARACTER_RANGES.SMALL_CAPS;

pub const DWRITE_PANOSE_SYMBOL_KIND = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    MONTAGES = 2,
    PICTURES = 3,
    SHAPES = 4,
    SCIENTIFIC = 5,
    MUSIC = 6,
    EXPERT = 7,
    PATTERNS = 8,
    BOARDERS = 9,
    ICONS = 10,
    LOGOS = 11,
    INDUSTRY_SPECIFIC = 12,
};
pub const DWRITE_PANOSE_SYMBOL_KIND_ANY = DWRITE_PANOSE_SYMBOL_KIND.ANY;
pub const DWRITE_PANOSE_SYMBOL_KIND_NO_FIT = DWRITE_PANOSE_SYMBOL_KIND.NO_FIT;
pub const DWRITE_PANOSE_SYMBOL_KIND_MONTAGES = DWRITE_PANOSE_SYMBOL_KIND.MONTAGES;
pub const DWRITE_PANOSE_SYMBOL_KIND_PICTURES = DWRITE_PANOSE_SYMBOL_KIND.PICTURES;
pub const DWRITE_PANOSE_SYMBOL_KIND_SHAPES = DWRITE_PANOSE_SYMBOL_KIND.SHAPES;
pub const DWRITE_PANOSE_SYMBOL_KIND_SCIENTIFIC = DWRITE_PANOSE_SYMBOL_KIND.SCIENTIFIC;
pub const DWRITE_PANOSE_SYMBOL_KIND_MUSIC = DWRITE_PANOSE_SYMBOL_KIND.MUSIC;
pub const DWRITE_PANOSE_SYMBOL_KIND_EXPERT = DWRITE_PANOSE_SYMBOL_KIND.EXPERT;
pub const DWRITE_PANOSE_SYMBOL_KIND_PATTERNS = DWRITE_PANOSE_SYMBOL_KIND.PATTERNS;
pub const DWRITE_PANOSE_SYMBOL_KIND_BOARDERS = DWRITE_PANOSE_SYMBOL_KIND.BOARDERS;
pub const DWRITE_PANOSE_SYMBOL_KIND_ICONS = DWRITE_PANOSE_SYMBOL_KIND.ICONS;
pub const DWRITE_PANOSE_SYMBOL_KIND_LOGOS = DWRITE_PANOSE_SYMBOL_KIND.LOGOS;
pub const DWRITE_PANOSE_SYMBOL_KIND_INDUSTRY_SPECIFIC = DWRITE_PANOSE_SYMBOL_KIND.INDUSTRY_SPECIFIC;

pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO = enum(i32) {
    ANY = 0,
    NO_FIT = 1,
    NO_WIDTH = 2,
    EXCEPTIONALLY_WIDE = 3,
    SUPER_WIDE = 4,
    VERY_WIDE = 5,
    WIDE = 6,
    NORMAL = 7,
    NARROW = 8,
    VERY_NARROW = 9,
};
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_ANY = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.ANY;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_NO_FIT = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.NO_FIT;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_NO_WIDTH = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.NO_WIDTH;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_EXCEPTIONALLY_WIDE = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.EXCEPTIONALLY_WIDE;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_SUPER_WIDE = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.SUPER_WIDE;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_VERY_WIDE = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.VERY_WIDE;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_WIDE = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.WIDE;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_NORMAL = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.NORMAL;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_NARROW = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.NARROW;
pub const DWRITE_PANOSE_SYMBOL_ASPECT_RATIO_VERY_NARROW = DWRITE_PANOSE_SYMBOL_ASPECT_RATIO.VERY_NARROW;

pub const DWRITE_OUTLINE_THRESHOLD = enum(i32) {
    NTIALIASED = 0,
    LIASED = 1,
};
pub const DWRITE_OUTLINE_THRESHOLD_ANTIALIASED = DWRITE_OUTLINE_THRESHOLD.NTIALIASED;
pub const DWRITE_OUTLINE_THRESHOLD_ALIASED = DWRITE_OUTLINE_THRESHOLD.LIASED;

pub const DWRITE_BASELINE = enum(i32) {
    DEFAULT = 0,
    ROMAN = 1,
    CENTRAL = 2,
    MATH = 3,
    HANGING = 4,
    IDEOGRAPHIC_BOTTOM = 5,
    IDEOGRAPHIC_TOP = 6,
    MINIMUM = 7,
    MAXIMUM = 8,
};
pub const DWRITE_BASELINE_DEFAULT = DWRITE_BASELINE.DEFAULT;
pub const DWRITE_BASELINE_ROMAN = DWRITE_BASELINE.ROMAN;
pub const DWRITE_BASELINE_CENTRAL = DWRITE_BASELINE.CENTRAL;
pub const DWRITE_BASELINE_MATH = DWRITE_BASELINE.MATH;
pub const DWRITE_BASELINE_HANGING = DWRITE_BASELINE.HANGING;
pub const DWRITE_BASELINE_IDEOGRAPHIC_BOTTOM = DWRITE_BASELINE.IDEOGRAPHIC_BOTTOM;
pub const DWRITE_BASELINE_IDEOGRAPHIC_TOP = DWRITE_BASELINE.IDEOGRAPHIC_TOP;
pub const DWRITE_BASELINE_MINIMUM = DWRITE_BASELINE.MINIMUM;
pub const DWRITE_BASELINE_MAXIMUM = DWRITE_BASELINE.MAXIMUM;

pub const DWRITE_VERTICAL_GLYPH_ORIENTATION = enum(i32) {
    DEFAULT = 0,
    STACKED = 1,
};
pub const DWRITE_VERTICAL_GLYPH_ORIENTATION_DEFAULT = DWRITE_VERTICAL_GLYPH_ORIENTATION.DEFAULT;
pub const DWRITE_VERTICAL_GLYPH_ORIENTATION_STACKED = DWRITE_VERTICAL_GLYPH_ORIENTATION.STACKED;

pub const DWRITE_GLYPH_ORIENTATION_ANGLE = enum(i32) {
    @"0_DEGREES" = 0,
    @"90_DEGREES" = 1,
    @"180_DEGREES" = 2,
    @"270_DEGREES" = 3,
};
pub const DWRITE_GLYPH_ORIENTATION_ANGLE_0_DEGREES = DWRITE_GLYPH_ORIENTATION_ANGLE.@"0_DEGREES";
pub const DWRITE_GLYPH_ORIENTATION_ANGLE_90_DEGREES = DWRITE_GLYPH_ORIENTATION_ANGLE.@"90_DEGREES";
pub const DWRITE_GLYPH_ORIENTATION_ANGLE_180_DEGREES = DWRITE_GLYPH_ORIENTATION_ANGLE.@"180_DEGREES";
pub const DWRITE_GLYPH_ORIENTATION_ANGLE_270_DEGREES = DWRITE_GLYPH_ORIENTATION_ANGLE.@"270_DEGREES";

pub const DWRITE_FONT_METRICS1 = extern struct {
    __AnonymousBase_DWrite_1_L627_C38: DWRITE_FONT_METRICS,
    glyphBoxLeft: i16,
    glyphBoxTop: i16,
    glyphBoxRight: i16,
    glyphBoxBottom: i16,
    subscriptPositionX: i16,
    subscriptPositionY: i16,
    subscriptSizeX: i16,
    subscriptSizeY: i16,
    superscriptPositionX: i16,
    superscriptPositionY: i16,
    superscriptSizeX: i16,
    superscriptSizeY: i16,
    hasTypographicMetrics: BOOL,
};

pub const DWRITE_CARET_METRICS = extern struct {
    slopeRise: i16,
    slopeRun: i16,
    offset: i16,
};

pub const DWRITE_PANOSE = extern union {
    values: [10]u8,
    familyKind: u8,
    text: extern struct {
        familyKind: u8,
        serifStyle: u8,
        weight: u8,
        proportion: u8,
        contrast: u8,
        strokeVariation: u8,
        armStyle: u8,
        letterform: u8,
        midline: u8,
        xHeight: u8,
    },
    script: extern struct {
        familyKind: u8,
        toolKind: u8,
        weight: u8,
        spacing: u8,
        aspectRatio: u8,
        contrast: u8,
        scriptTopology: u8,
        scriptForm: u8,
        finials: u8,
        xAscent: u8,
    },
    decorative: extern struct {
        familyKind: u8,
        decorativeClass: u8,
        weight: u8,
        aspect: u8,
        contrast: u8,
        serifVariant: u8,
        fill: u8,
        lining: u8,
        decorativeTopology: u8,
        characterRange: u8,
    },
    symbol: extern struct {
        familyKind: u8,
        symbolKind: u8,
        weight: u8,
        spacing: u8,
        aspectRatioAndContrast: u8,
        aspectRatio94: u8,
        aspectRatio119: u8,
        aspectRatio157: u8,
        aspectRatio163: u8,
        aspectRatio211: u8,
    },
};

pub const DWRITE_UNICODE_RANGE = extern struct {
    first: u32,
    last: u32,
};

pub const DWRITE_SCRIPT_PROPERTIES = extern struct {
    isoScriptCode: u32,
    isoScriptNumber: u32,
    clusterLookahead: u32,
    justificationCharacter: u32,
    _bitfield: u32,
};

pub const DWRITE_JUSTIFICATION_OPPORTUNITY = extern struct {
    expansionMinimum: f32,
    expansionMaximum: f32,
    compressionMaximum: f32,
    _bitfield: u32,
};

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteFactory1_Value = Guid.initString("30572f99-dac6-41db-a16e-0486307e606a");
pub const IID_IDWriteFactory1 = &IID_IDWriteFactory1_Value;
pub const IDWriteFactory1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFactory.VTable,
        GetEudcFontCollection: *const fn (
            self: *const IDWriteFactory1,
            fontCollection: ?*?*IDWriteFontCollection,
            checkForUpdates: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateCustomRenderingParams: *const fn (
            self: *const IDWriteFactory1,
            gamma: f32,
            enhancedContrast: f32,
            enhancedContrastGrayscale: f32,
            clearTypeLevel: f32,
            pixelGeometry: DWRITE_PIXEL_GEOMETRY,
            renderingMode: DWRITE_RENDERING_MODE,
            renderingParams: ?*?*IDWriteRenderingParams1,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFactory.MethodMixin(T);
            pub inline fn GetEudcFontCollection(self: *const T, fontCollection: ?*?*IDWriteFontCollection, checkForUpdates: BOOL) HRESULT {
                return @as(*const IDWriteFactory1.VTable, @ptrCast(self.vtable)).GetEudcFontCollection(@as(*const IDWriteFactory1, @ptrCast(self)), fontCollection, checkForUpdates);
            }
            pub inline fn CreateCustomRenderingParams(self: *const T, gamma: f32, enhancedContrast: f32, enhancedContrastGrayscale: f32, clearTypeLevel: f32, pixelGeometry: DWRITE_PIXEL_GEOMETRY, renderingMode: DWRITE_RENDERING_MODE, renderingParams: ?*?*IDWriteRenderingParams1) HRESULT {
                return @as(*const IDWriteFactory1.VTable, @ptrCast(self.vtable)).CreateCustomRenderingParams(@as(*const IDWriteFactory1, @ptrCast(self)), gamma, enhancedContrast, enhancedContrastGrayscale, clearTypeLevel, pixelGeometry, renderingMode, renderingParams);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteFontFace1_Value = Guid.initString("a71efdb4-9fdb-4838-ad90-cfc3be8c3daf");
pub const IID_IDWriteFontFace1 = &IID_IDWriteFontFace1_Value;
pub const IDWriteFontFace1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFace.VTable,
        GetMetrics: *const fn (
            self: *const IDWriteFontFace1,
            fontMetrics: ?*DWRITE_FONT_METRICS1,
        ) callconv(std.os.windows.WINAPI) void,

        GetGdiCompatibleMetrics: *const fn (
            self: *const IDWriteFontFace1,
            emSize: f32,
            pixelsPerDip: f32,
            transform: ?*const DWRITE_MATRIX,
            fontMetrics: ?*DWRITE_FONT_METRICS1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetCaretMetrics: *const fn (
            self: *const IDWriteFontFace1,
            caretMetrics: ?*DWRITE_CARET_METRICS,
        ) callconv(std.os.windows.WINAPI) void,

        GetUnicodeRanges: *const fn (
            self: *const IDWriteFontFace1,
            maxRangeCount: u32,
            unicodeRanges: ?[*]DWRITE_UNICODE_RANGE,
            actualRangeCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        IsMonospacedFont: *const fn (
            self: *const IDWriteFontFace1,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetDesignGlyphAdvances: *const fn (
            self: *const IDWriteFontFace1,
            glyphCount: u32,
            glyphIndices: [*:0]const u16,
            glyphAdvances: [*]i32,
            isSideways: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGdiCompatibleGlyphAdvances: *const fn (
            self: *const IDWriteFontFace1,
            emSize: f32,
            pixelsPerDip: f32,
            transform: ?*const DWRITE_MATRIX,
            useGdiNatural: BOOL,
            isSideways: BOOL,
            glyphCount: u32,
            glyphIndices: [*:0]const u16,
            glyphAdvances: [*]i32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetKerningPairAdjustments: *const fn (
            self: *const IDWriteFontFace1,
            glyphCount: u32,
            glyphIndices: [*:0]const u16,
            glyphAdvanceAdjustments: [*]i32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HasKerningPairs: *const fn (
            self: *const IDWriteFontFace1,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetRecommendedRenderingMode: *const fn (
            self: *const IDWriteFontFace1,
            fontEmSize: f32,
            dpiX: f32,
            dpiY: f32,
            transform: ?*const DWRITE_MATRIX,
            isSideways: BOOL,
            outlineThreshold: DWRITE_OUTLINE_THRESHOLD,
            measuringMode: DWRITE_MEASURING_MODE,
            renderingMode: ?*DWRITE_RENDERING_MODE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetVerticalGlyphVariants: *const fn (
            self: *const IDWriteFontFace1,
            glyphCount: u32,
            nominalGlyphIndices: [*:0]const u16,
            verticalGlyphIndices: [*:0]u16,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HasVerticalGlyphVariants: *const fn (
            self: *const IDWriteFontFace1,
        ) callconv(std.os.windows.WINAPI) BOOL,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFace.MethodMixin(T);
            pub inline fn GetMetrics(self: *const T, fontMetrics: ?*DWRITE_FONT_METRICS1) void {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetMetrics(@as(*const IDWriteFontFace1, @ptrCast(self)), fontMetrics);
            }
            pub inline fn GetGdiCompatibleMetrics(self: *const T, emSize: f32, pixelsPerDip: f32, transform: ?*const DWRITE_MATRIX, fontMetrics: ?*DWRITE_FONT_METRICS1) HRESULT {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetGdiCompatibleMetrics(@as(*const IDWriteFontFace1, @ptrCast(self)), emSize, pixelsPerDip, transform, fontMetrics);
            }
            pub inline fn GetCaretMetrics(self: *const T, caretMetrics: ?*DWRITE_CARET_METRICS) void {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetCaretMetrics(@as(*const IDWriteFontFace1, @ptrCast(self)), caretMetrics);
            }
            pub inline fn GetUnicodeRanges(self: *const T, maxRangeCount: u32, unicodeRanges: ?[*]DWRITE_UNICODE_RANGE, actualRangeCount: ?*u32) HRESULT {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetUnicodeRanges(@as(*const IDWriteFontFace1, @ptrCast(self)), maxRangeCount, unicodeRanges, actualRangeCount);
            }
            pub inline fn IsMonospacedFont(self: *const T) BOOL {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).IsMonospacedFont(@as(*const IDWriteFontFace1, @ptrCast(self)));
            }
            pub inline fn GetDesignGlyphAdvances(self: *const T, glyphCount: u32, glyphIndices: [*:0]const u16, glyphAdvances: [*]i32, isSideways: BOOL) HRESULT {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetDesignGlyphAdvances(@as(*const IDWriteFontFace1, @ptrCast(self)), glyphCount, glyphIndices, glyphAdvances, isSideways);
            }
            pub inline fn GetGdiCompatibleGlyphAdvances(self: *const T, emSize: f32, pixelsPerDip: f32, transform: ?*const DWRITE_MATRIX, useGdiNatural: BOOL, isSideways: BOOL, glyphCount: u32, glyphIndices: [*:0]const u16, glyphAdvances: [*]i32) HRESULT {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetGdiCompatibleGlyphAdvances(@as(*const IDWriteFontFace1, @ptrCast(self)), emSize, pixelsPerDip, transform, useGdiNatural, isSideways, glyphCount, glyphIndices, glyphAdvances);
            }
            pub inline fn GetKerningPairAdjustments(self: *const T, glyphCount: u32, glyphIndices: [*:0]const u16, glyphAdvanceAdjustments: [*]i32) HRESULT {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetKerningPairAdjustments(@as(*const IDWriteFontFace1, @ptrCast(self)), glyphCount, glyphIndices, glyphAdvanceAdjustments);
            }
            pub inline fn HasKerningPairs(self: *const T) BOOL {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).HasKerningPairs(@as(*const IDWriteFontFace1, @ptrCast(self)));
            }
            pub inline fn GetRecommendedRenderingMode(self: *const T, fontEmSize: f32, dpiX: f32, dpiY: f32, transform: ?*const DWRITE_MATRIX, isSideways: BOOL, outlineThreshold: DWRITE_OUTLINE_THRESHOLD, measuringMode: DWRITE_MEASURING_MODE, renderingMode: ?*DWRITE_RENDERING_MODE) HRESULT {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetRecommendedRenderingMode(@as(*const IDWriteFontFace1, @ptrCast(self)), fontEmSize, dpiX, dpiY, transform, isSideways, outlineThreshold, measuringMode, renderingMode);
            }
            pub inline fn GetVerticalGlyphVariants(self: *const T, glyphCount: u32, nominalGlyphIndices: [*:0]const u16, verticalGlyphIndices: [*:0]u16) HRESULT {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).GetVerticalGlyphVariants(@as(*const IDWriteFontFace1, @ptrCast(self)), glyphCount, nominalGlyphIndices, verticalGlyphIndices);
            }
            pub inline fn HasVerticalGlyphVariants(self: *const T) BOOL {
                return @as(*const IDWriteFontFace1.VTable, @ptrCast(self.vtable)).HasVerticalGlyphVariants(@as(*const IDWriteFontFace1, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteFont1_Value = Guid.initString("acd16696-8c14-4f5d-877e-fe3fc1d32738");
pub const IID_IDWriteFont1 = &IID_IDWriteFont1_Value;
pub const IDWriteFont1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFont.VTable,
        GetMetrics: *const fn (
            self: *const IDWriteFont1,
            fontMetrics: ?*DWRITE_FONT_METRICS1,
        ) callconv(std.os.windows.WINAPI) void,

        GetPanose: *const fn (
            self: *const IDWriteFont1,
            panose: ?*DWRITE_PANOSE,
        ) callconv(std.os.windows.WINAPI) void,

        GetUnicodeRanges: *const fn (
            self: *const IDWriteFont1,
            maxRangeCount: u32,
            unicodeRanges: ?[*]DWRITE_UNICODE_RANGE,
            actualRangeCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        IsMonospacedFont: *const fn (
            self: *const IDWriteFont1,
        ) callconv(std.os.windows.WINAPI) BOOL,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFont.MethodMixin(T);
            pub inline fn GetMetrics(self: *const T, fontMetrics: ?*DWRITE_FONT_METRICS1) void {
                return @as(*const IDWriteFont1.VTable, @ptrCast(self.vtable)).GetMetrics(@as(*const IDWriteFont1, @ptrCast(self)), fontMetrics);
            }
            pub inline fn GetPanose(self: *const T, panose: ?*DWRITE_PANOSE) void {
                return @as(*const IDWriteFont1.VTable, @ptrCast(self.vtable)).GetPanose(@as(*const IDWriteFont1, @ptrCast(self)), panose);
            }
            pub inline fn GetUnicodeRanges(self: *const T, maxRangeCount: u32, unicodeRanges: ?[*]DWRITE_UNICODE_RANGE, actualRangeCount: ?*u32) HRESULT {
                return @as(*const IDWriteFont1.VTable, @ptrCast(self.vtable)).GetUnicodeRanges(@as(*const IDWriteFont1, @ptrCast(self)), maxRangeCount, unicodeRanges, actualRangeCount);
            }
            pub inline fn IsMonospacedFont(self: *const T) BOOL {
                return @as(*const IDWriteFont1.VTable, @ptrCast(self.vtable)).IsMonospacedFont(@as(*const IDWriteFont1, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteRenderingParams1_Value = Guid.initString("94413cf4-a6fc-4248-8b50-6674348fcad3");
pub const IID_IDWriteRenderingParams1 = &IID_IDWriteRenderingParams1_Value;
pub const IDWriteRenderingParams1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteRenderingParams.VTable,
        GetGrayscaleEnhancedContrast: *const fn (
            self: *const IDWriteRenderingParams1,
        ) callconv(std.os.windows.WINAPI) f32,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteRenderingParams.MethodMixin(T);
            pub inline fn GetGrayscaleEnhancedContrast(self: *const T) f32 {
                return @as(*const IDWriteRenderingParams1.VTable, @ptrCast(self.vtable)).GetGrayscaleEnhancedContrast(@as(*const IDWriteRenderingParams1, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteTextAnalyzer1_Value = Guid.initString("80dad800-e21f-4e83-96ce-bfcce500db7c");
pub const IID_IDWriteTextAnalyzer1 = &IID_IDWriteTextAnalyzer1_Value;
pub const IDWriteTextAnalyzer1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextAnalyzer.VTable,
        ApplyCharacterSpacing: *const fn (
            self: *const IDWriteTextAnalyzer1,
            leadingSpacing: f32,
            trailingSpacing: f32,
            minimumAdvanceWidth: f32,
            textLength: u32,
            glyphCount: u32,
            clusterMap: [*:0]const u16,
            glyphAdvances: [*]const f32,
            glyphOffsets: [*]const DWRITE_GLYPH_OFFSET,
            glyphProperties: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES,
            modifiedGlyphAdvances: [*]f32,
            modifiedGlyphOffsets: [*]DWRITE_GLYPH_OFFSET,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetBaseline: *const fn (
            self: *const IDWriteTextAnalyzer1,
            fontFace: ?*IDWriteFontFace,
            baseline: DWRITE_BASELINE,
            isVertical: BOOL,
            isSimulationAllowed: BOOL,
            scriptAnalysis: DWRITE_SCRIPT_ANALYSIS,
            localeName: ?[*:0]const u16,
            baselineCoordinate: ?*i32,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AnalyzeVerticalGlyphOrientation: *const fn (
            self: *const IDWriteTextAnalyzer1,
            analysisSource: ?*IDWriteTextAnalysisSource1,
            textPosition: u32,
            textLength: u32,
            analysisSink: ?*IDWriteTextAnalysisSink1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGlyphOrientationTransform: *const fn (
            self: *const IDWriteTextAnalyzer1,
            glyphOrientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE,
            isSideways: BOOL,
            transform: ?*DWRITE_MATRIX,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetScriptProperties: *const fn (
            self: *const IDWriteTextAnalyzer1,
            scriptAnalysis: DWRITE_SCRIPT_ANALYSIS,
            scriptProperties: ?*DWRITE_SCRIPT_PROPERTIES,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetTextComplexity: *const fn (
            self: *const IDWriteTextAnalyzer1,
            textString: [*:0]const u16,
            textLength: u32,
            fontFace: ?*IDWriteFontFace,
            isTextSimple: ?*BOOL,
            textLengthRead: ?*u32,
            glyphIndices: ?[*:0]u16,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetJustificationOpportunities: *const fn (
            self: *const IDWriteTextAnalyzer1,
            fontFace: ?*IDWriteFontFace,
            fontEmSize: f32,
            scriptAnalysis: DWRITE_SCRIPT_ANALYSIS,
            textLength: u32,
            glyphCount: u32,
            textString: [*:0]const u16,
            clusterMap: [*:0]const u16,
            glyphProperties: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES,
            justificationOpportunities: [*]DWRITE_JUSTIFICATION_OPPORTUNITY,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        JustifyGlyphAdvances: *const fn (
            self: *const IDWriteTextAnalyzer1,
            lineWidth: f32,
            glyphCount: u32,
            justificationOpportunities: [*]const DWRITE_JUSTIFICATION_OPPORTUNITY,
            glyphAdvances: [*]const f32,
            glyphOffsets: [*]const DWRITE_GLYPH_OFFSET,
            justifiedGlyphAdvances: [*]f32,
            justifiedGlyphOffsets: ?[*]DWRITE_GLYPH_OFFSET,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetJustifiedGlyphs: *const fn (
            self: *const IDWriteTextAnalyzer1,
            fontFace: ?*IDWriteFontFace,
            fontEmSize: f32,
            scriptAnalysis: DWRITE_SCRIPT_ANALYSIS,
            textLength: u32,
            glyphCount: u32,
            maxGlyphCount: u32,
            clusterMap: ?[*:0]const u16,
            glyphIndices: [*:0]const u16,
            glyphAdvances: [*]const f32,
            justifiedGlyphAdvances: [*]const f32,
            justifiedGlyphOffsets: [*]const DWRITE_GLYPH_OFFSET,
            glyphProperties: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES,
            actualGlyphCount: ?*u32,
            modifiedClusterMap: ?[*:0]u16,
            modifiedGlyphIndices: [*:0]u16,
            modifiedGlyphAdvances: [*]f32,
            modifiedGlyphOffsets: [*]DWRITE_GLYPH_OFFSET,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextAnalyzer.MethodMixin(T);
            pub inline fn ApplyCharacterSpacing(self: *const T, leadingSpacing: f32, trailingSpacing: f32, minimumAdvanceWidth: f32, textLength: u32, glyphCount: u32, clusterMap: [*:0]const u16, glyphAdvances: [*]const f32, glyphOffsets: [*]const DWRITE_GLYPH_OFFSET, glyphProperties: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES, modifiedGlyphAdvances: [*]f32, modifiedGlyphOffsets: [*]DWRITE_GLYPH_OFFSET) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).ApplyCharacterSpacing(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), leadingSpacing, trailingSpacing, minimumAdvanceWidth, textLength, glyphCount, clusterMap, glyphAdvances, glyphOffsets, glyphProperties, modifiedGlyphAdvances, modifiedGlyphOffsets);
            }
            pub inline fn GetBaseline(self: *const T, fontFace: ?*IDWriteFontFace, baseline: DWRITE_BASELINE, isVertical: BOOL, isSimulationAllowed: BOOL, scriptAnalysis: DWRITE_SCRIPT_ANALYSIS, localeName: ?[*:0]const u16, baselineCoordinate: ?*i32, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).GetBaseline(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), fontFace, baseline, isVertical, isSimulationAllowed, scriptAnalysis, localeName, baselineCoordinate, exists);
            }
            pub inline fn AnalyzeVerticalGlyphOrientation(self: *const T, analysisSource: ?*IDWriteTextAnalysisSource1, textPosition: u32, textLength: u32, analysisSink: ?*IDWriteTextAnalysisSink1) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).AnalyzeVerticalGlyphOrientation(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), analysisSource, textPosition, textLength, analysisSink);
            }
            pub inline fn GetGlyphOrientationTransform(self: *const T, glyphOrientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE, isSideways: BOOL, transform: ?*DWRITE_MATRIX) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).GetGlyphOrientationTransform(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), glyphOrientationAngle, isSideways, transform);
            }
            pub inline fn GetScriptProperties(self: *const T, scriptAnalysis: DWRITE_SCRIPT_ANALYSIS, scriptProperties: ?*DWRITE_SCRIPT_PROPERTIES) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).GetScriptProperties(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), scriptAnalysis, scriptProperties);
            }
            pub inline fn GetTextComplexity(self: *const T, textString: [*:0]const u16, textLength: u32, fontFace: ?*IDWriteFontFace, isTextSimple: ?*BOOL, textLengthRead: ?*u32, glyphIndices: ?[*:0]u16) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).GetTextComplexity(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), textString, textLength, fontFace, isTextSimple, textLengthRead, glyphIndices);
            }
            pub inline fn GetJustificationOpportunities(self: *const T, fontFace: ?*IDWriteFontFace, fontEmSize: f32, scriptAnalysis: DWRITE_SCRIPT_ANALYSIS, textLength: u32, glyphCount: u32, textString: [*:0]const u16, clusterMap: [*:0]const u16, glyphProperties: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES, justificationOpportunities: [*]DWRITE_JUSTIFICATION_OPPORTUNITY) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).GetJustificationOpportunities(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), fontFace, fontEmSize, scriptAnalysis, textLength, glyphCount, textString, clusterMap, glyphProperties, justificationOpportunities);
            }
            pub inline fn JustifyGlyphAdvances(self: *const T, lineWidth: f32, glyphCount: u32, justificationOpportunities: [*]const DWRITE_JUSTIFICATION_OPPORTUNITY, glyphAdvances: [*]const f32, glyphOffsets: [*]const DWRITE_GLYPH_OFFSET, justifiedGlyphAdvances: [*]f32, justifiedGlyphOffsets: ?[*]DWRITE_GLYPH_OFFSET) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).JustifyGlyphAdvances(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), lineWidth, glyphCount, justificationOpportunities, glyphAdvances, glyphOffsets, justifiedGlyphAdvances, justifiedGlyphOffsets);
            }
            pub inline fn GetJustifiedGlyphs(self: *const T, fontFace: ?*IDWriteFontFace, fontEmSize: f32, scriptAnalysis: DWRITE_SCRIPT_ANALYSIS, textLength: u32, glyphCount: u32, maxGlyphCount: u32, clusterMap: ?[*:0]const u16, glyphIndices: [*:0]const u16, glyphAdvances: [*]const f32, justifiedGlyphAdvances: [*]const f32, justifiedGlyphOffsets: [*]const DWRITE_GLYPH_OFFSET, glyphProperties: [*]const DWRITE_SHAPING_GLYPH_PROPERTIES, actualGlyphCount: ?*u32, modifiedClusterMap: ?[*:0]u16, modifiedGlyphIndices: [*:0]u16, modifiedGlyphAdvances: [*]f32, modifiedGlyphOffsets: [*]DWRITE_GLYPH_OFFSET) HRESULT {
                return @as(*const IDWriteTextAnalyzer1.VTable, @ptrCast(self.vtable)).GetJustifiedGlyphs(@as(*const IDWriteTextAnalyzer1, @ptrCast(self)), fontFace, fontEmSize, scriptAnalysis, textLength, glyphCount, maxGlyphCount, clusterMap, glyphIndices, glyphAdvances, justifiedGlyphAdvances, justifiedGlyphOffsets, glyphProperties, actualGlyphCount, modifiedClusterMap, modifiedGlyphIndices, modifiedGlyphAdvances, modifiedGlyphOffsets);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteTextAnalysisSource1_Value = Guid.initString("639cfad8-0fb4-4b21-a58a-067920120009");
pub const IID_IDWriteTextAnalysisSource1 = &IID_IDWriteTextAnalysisSource1_Value;
pub const IDWriteTextAnalysisSource1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextAnalysisSource.VTable,
        GetVerticalGlyphOrientation: *const fn (
            self: *const IDWriteTextAnalysisSource1,
            textPosition: u32,
            textLength: ?*u32,
            glyphOrientation: ?*DWRITE_VERTICAL_GLYPH_ORIENTATION,
            bidiLevel: ?*u8,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextAnalysisSource.MethodMixin(T);
            pub inline fn GetVerticalGlyphOrientation(self: *const T, textPosition: u32, textLength: ?*u32, glyphOrientation: ?*DWRITE_VERTICAL_GLYPH_ORIENTATION, bidiLevel: ?*u8) HRESULT {
                return @as(*const IDWriteTextAnalysisSource1.VTable, @ptrCast(self.vtable)).GetVerticalGlyphOrientation(@as(*const IDWriteTextAnalysisSource1, @ptrCast(self)), textPosition, textLength, glyphOrientation, bidiLevel);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteTextAnalysisSink1_Value = Guid.initString("b0d941a0-85e7-4d8b-9fd3-5ced9934482a");
pub const IID_IDWriteTextAnalysisSink1 = &IID_IDWriteTextAnalysisSink1_Value;
pub const IDWriteTextAnalysisSink1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextAnalysisSink.VTable,
        SetGlyphOrientation: *const fn (
            self: *const IDWriteTextAnalysisSink1,
            textPosition: u32,
            textLength: u32,
            glyphOrientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE,
            adjustedBidiLevel: u8,
            isSideways: BOOL,
            isRightToLeft: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextAnalysisSink.MethodMixin(T);
            pub inline fn SetGlyphOrientation(self: *const T, textPosition: u32, textLength: u32, glyphOrientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE, adjustedBidiLevel: u8, isSideways: BOOL, isRightToLeft: BOOL) HRESULT {
                return @as(*const IDWriteTextAnalysisSink1.VTable, @ptrCast(self.vtable)).SetGlyphOrientation(@as(*const IDWriteTextAnalysisSink1, @ptrCast(self)), textPosition, textLength, glyphOrientationAngle, adjustedBidiLevel, isSideways, isRightToLeft);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteTextLayout1_Value = Guid.initString("9064d822-80a7-465c-a986-df65f78b8feb");
pub const IID_IDWriteTextLayout1 = &IID_IDWriteTextLayout1_Value;
pub const IDWriteTextLayout1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextLayout.VTable,
        SetPairKerning: *const fn (
            self: *const IDWriteTextLayout1,
            isPairKerningEnabled: BOOL,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetPairKerning: *const fn (
            self: *const IDWriteTextLayout1,
            currentPosition: u32,
            isPairKerningEnabled: ?*BOOL,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetCharacterSpacing: *const fn (
            self: *const IDWriteTextLayout1,
            leadingSpacing: f32,
            trailingSpacing: f32,
            minimumAdvanceWidth: f32,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetCharacterSpacing: *const fn (
            self: *const IDWriteTextLayout1,
            currentPosition: u32,
            leadingSpacing: ?*f32,
            trailingSpacing: ?*f32,
            minimumAdvanceWidth: ?*f32,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextLayout.MethodMixin(T);
            pub inline fn SetPairKerning(self: *const T, isPairKerningEnabled: BOOL, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout1.VTable, @ptrCast(self.vtable)).SetPairKerning(@as(*const IDWriteTextLayout1, @ptrCast(self)), isPairKerningEnabled, textRange);
            }
            pub inline fn GetPairKerning(self: *const T, currentPosition: u32, isPairKerningEnabled: ?*BOOL, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout1.VTable, @ptrCast(self.vtable)).GetPairKerning(@as(*const IDWriteTextLayout1, @ptrCast(self)), currentPosition, isPairKerningEnabled, textRange);
            }
            pub inline fn SetCharacterSpacing(self: *const T, leadingSpacing: f32, trailingSpacing: f32, minimumAdvanceWidth: f32, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout1.VTable, @ptrCast(self.vtable)).SetCharacterSpacing(@as(*const IDWriteTextLayout1, @ptrCast(self)), leadingSpacing, trailingSpacing, minimumAdvanceWidth, textRange);
            }
            pub inline fn GetCharacterSpacing(self: *const T, currentPosition: u32, leadingSpacing: ?*f32, trailingSpacing: ?*f32, minimumAdvanceWidth: ?*f32, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout1.VTable, @ptrCast(self.vtable)).GetCharacterSpacing(@as(*const IDWriteTextLayout1, @ptrCast(self)), currentPosition, leadingSpacing, trailingSpacing, minimumAdvanceWidth, textRange);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_TEXT_ANTIALIAS_MODE = enum(i32) {
    CLEARTYPE = 0,
    GRAYSCALE = 1,
};
pub const DWRITE_TEXT_ANTIALIAS_MODE_CLEARTYPE = DWRITE_TEXT_ANTIALIAS_MODE.CLEARTYPE;
pub const DWRITE_TEXT_ANTIALIAS_MODE_GRAYSCALE = DWRITE_TEXT_ANTIALIAS_MODE.GRAYSCALE;

// TODO: this type is limited to platform 'windows8.0'
const IID_IDWriteBitmapRenderTarget1_Value = Guid.initString("791e8298-3ef3-4230-9880-c9bdecc42064");
pub const IID_IDWriteBitmapRenderTarget1 = &IID_IDWriteBitmapRenderTarget1_Value;
pub const IDWriteBitmapRenderTarget1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteBitmapRenderTarget.VTable,
        GetTextAntialiasMode: *const fn (
            self: *const IDWriteBitmapRenderTarget1,
        ) callconv(std.os.windows.WINAPI) DWRITE_TEXT_ANTIALIAS_MODE,

        SetTextAntialiasMode: *const fn (
            self: *const IDWriteBitmapRenderTarget1,
            antialiasMode: DWRITE_TEXT_ANTIALIAS_MODE,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteBitmapRenderTarget.MethodMixin(T);
            pub inline fn GetTextAntialiasMode(self: *const T) DWRITE_TEXT_ANTIALIAS_MODE {
                return @as(*const IDWriteBitmapRenderTarget1.VTable, @ptrCast(self.vtable)).GetTextAntialiasMode(@as(*const IDWriteBitmapRenderTarget1, @ptrCast(self)));
            }
            pub inline fn SetTextAntialiasMode(self: *const T, antialiasMode: DWRITE_TEXT_ANTIALIAS_MODE) HRESULT {
                return @as(*const IDWriteBitmapRenderTarget1.VTable, @ptrCast(self.vtable)).SetTextAntialiasMode(@as(*const IDWriteBitmapRenderTarget1, @ptrCast(self)), antialiasMode);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_OPTICAL_ALIGNMENT = enum(i32) {
    NE = 0,
    _SIDE_BEARINGS = 1,
};
pub const DWRITE_OPTICAL_ALIGNMENT_NONE = DWRITE_OPTICAL_ALIGNMENT.NE;
pub const DWRITE_OPTICAL_ALIGNMENT_NO_SIDE_BEARINGS = DWRITE_OPTICAL_ALIGNMENT._SIDE_BEARINGS;

pub const DWRITE_GRID_FIT_MODE = enum(i32) {
    DEFAULT = 0,
    DISABLED = 1,
    ENABLED = 2,
};
pub const DWRITE_GRID_FIT_MODE_DEFAULT = DWRITE_GRID_FIT_MODE.DEFAULT;
pub const DWRITE_GRID_FIT_MODE_DISABLED = DWRITE_GRID_FIT_MODE.DISABLED;
pub const DWRITE_GRID_FIT_MODE_ENABLED = DWRITE_GRID_FIT_MODE.ENABLED;

pub const DWRITE_TEXT_METRICS1 = extern struct {
    Base: DWRITE_TEXT_METRICS,
    heightIncludingTrailingWhitespace: f32,
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteTextRenderer1_Value = Guid.initString("d3e0e934-22a0-427e-aae4-7d9574b59db1");
pub const IID_IDWriteTextRenderer1 = &IID_IDWriteTextRenderer1_Value;
pub const IDWriteTextRenderer1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextRenderer.VTable,
        DrawGlyphRun: *const fn (
            self: *const IDWriteTextRenderer1,
            clientDrawingContext: ?*anyopaque,
            baselineOriginX: f32,
            baselineOriginY: f32,
            orientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE,
            measuringMode: DWRITE_MEASURING_MODE,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            glyphRunDescription: ?*const DWRITE_GLYPH_RUN_DESCRIPTION,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        DrawUnderline: *const fn (
            self: *const IDWriteTextRenderer1,
            clientDrawingContext: ?*anyopaque,
            baselineOriginX: f32,
            baselineOriginY: f32,
            orientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE,
            underline: ?*const DWRITE_UNDERLINE,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        DrawStrikethrough: *const fn (
            self: *const IDWriteTextRenderer1,
            clientDrawingContext: ?*anyopaque,
            baselineOriginX: f32,
            baselineOriginY: f32,
            orientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE,
            strikethrough: ?*const DWRITE_STRIKETHROUGH,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        DrawInlineObject: *const fn (
            self: *const IDWriteTextRenderer1,
            clientDrawingContext: ?*anyopaque,
            originX: f32,
            originY: f32,
            orientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE,
            inlineObject: ?*IDWriteInlineObject,
            isSideways: BOOL,
            isRightToLeft: BOOL,
            clientDrawingEffect: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextRenderer.MethodMixin(T);
            pub inline fn DrawGlyphRun(self: *const T, clientDrawingContext: ?*anyopaque, baselineOriginX: f32, baselineOriginY: f32, orientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE, measuringMode: DWRITE_MEASURING_MODE, glyphRun: ?*const DWRITE_GLYPH_RUN, glyphRunDescription: ?*const DWRITE_GLYPH_RUN_DESCRIPTION, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteTextRenderer1.VTable, @ptrCast(self.vtable)).DrawGlyphRun(@as(*const IDWriteTextRenderer1, @ptrCast(self)), clientDrawingContext, baselineOriginX, baselineOriginY, orientationAngle, measuringMode, glyphRun, glyphRunDescription, clientDrawingEffect);
            }
            pub inline fn DrawUnderline(self: *const T, clientDrawingContext: ?*anyopaque, baselineOriginX: f32, baselineOriginY: f32, orientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE, underline: ?*const DWRITE_UNDERLINE, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteTextRenderer1.VTable, @ptrCast(self.vtable)).DrawUnderline(@as(*const IDWriteTextRenderer1, @ptrCast(self)), clientDrawingContext, baselineOriginX, baselineOriginY, orientationAngle, underline, clientDrawingEffect);
            }
            pub inline fn DrawStrikethrough(self: *const T, clientDrawingContext: ?*anyopaque, baselineOriginX: f32, baselineOriginY: f32, orientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE, strikethrough: ?*const DWRITE_STRIKETHROUGH, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteTextRenderer1.VTable, @ptrCast(self.vtable)).DrawStrikethrough(@as(*const IDWriteTextRenderer1, @ptrCast(self)), clientDrawingContext, baselineOriginX, baselineOriginY, orientationAngle, strikethrough, clientDrawingEffect);
            }
            pub inline fn DrawInlineObject(self: *const T, clientDrawingContext: ?*anyopaque, originX: f32, originY: f32, orientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE, inlineObject: ?*IDWriteInlineObject, isSideways: BOOL, isRightToLeft: BOOL, clientDrawingEffect: ?*IUnknown) HRESULT {
                return @as(*const IDWriteTextRenderer1.VTable, @ptrCast(self.vtable)).DrawInlineObject(@as(*const IDWriteTextRenderer1, @ptrCast(self)), clientDrawingContext, originX, originY, orientationAngle, inlineObject, isSideways, isRightToLeft, clientDrawingEffect);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteTextFormat1_Value = Guid.initString("5f174b49-0d8b-4cfb-8bca-f1cce9d06c67");
pub const IID_IDWriteTextFormat1 = &IID_IDWriteTextFormat1_Value;
pub const IDWriteTextFormat1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextFormat.VTable,
        SetVerticalGlyphOrientation: *const fn (
            self: *const IDWriteTextFormat1,
            glyphOrientation: DWRITE_VERTICAL_GLYPH_ORIENTATION,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetVerticalGlyphOrientation: *const fn (
            self: *const IDWriteTextFormat1,
        ) callconv(std.os.windows.WINAPI) DWRITE_VERTICAL_GLYPH_ORIENTATION,

        SetLastLineWrapping: *const fn (
            self: *const IDWriteTextFormat1,
            isLastLineWrappingEnabled: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLastLineWrapping: *const fn (
            self: *const IDWriteTextFormat1,
        ) callconv(std.os.windows.WINAPI) BOOL,

        SetOpticalAlignment: *const fn (
            self: *const IDWriteTextFormat1,
            opticalAlignment: DWRITE_OPTICAL_ALIGNMENT,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetOpticalAlignment: *const fn (
            self: *const IDWriteTextFormat1,
        ) callconv(std.os.windows.WINAPI) DWRITE_OPTICAL_ALIGNMENT,

        SetFontFallback: *const fn (
            self: *const IDWriteTextFormat1,
            fontFallback: ?*IDWriteFontFallback,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFallback: *const fn (
            self: *const IDWriteTextFormat1,
            fontFallback: ?*?*IDWriteFontFallback,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextFormat.MethodMixin(T);
            pub inline fn SetVerticalGlyphOrientation(self: *const T, glyphOrientation: DWRITE_VERTICAL_GLYPH_ORIENTATION) HRESULT {
                return @as(*const IDWriteTextFormat1.VTable, @ptrCast(self.vtable)).SetVerticalGlyphOrientation(@as(*const IDWriteTextFormat1, @ptrCast(self)), glyphOrientation);
            }
            pub inline fn GetVerticalGlyphOrientation(self: *const T) DWRITE_VERTICAL_GLYPH_ORIENTATION {
                return @as(*const IDWriteTextFormat1.VTable, @ptrCast(self.vtable)).GetVerticalGlyphOrientation(@as(*const IDWriteTextFormat1, @ptrCast(self)));
            }
            pub inline fn SetLastLineWrapping(self: *const T, isLastLineWrappingEnabled: BOOL) HRESULT {
                return @as(*const IDWriteTextFormat1.VTable, @ptrCast(self.vtable)).SetLastLineWrapping(@as(*const IDWriteTextFormat1, @ptrCast(self)), isLastLineWrappingEnabled);
            }
            pub inline fn GetLastLineWrapping(self: *const T) BOOL {
                return @as(*const IDWriteTextFormat1.VTable, @ptrCast(self.vtable)).GetLastLineWrapping(@as(*const IDWriteTextFormat1, @ptrCast(self)));
            }
            pub inline fn SetOpticalAlignment(self: *const T, opticalAlignment: DWRITE_OPTICAL_ALIGNMENT) HRESULT {
                return @as(*const IDWriteTextFormat1.VTable, @ptrCast(self.vtable)).SetOpticalAlignment(@as(*const IDWriteTextFormat1, @ptrCast(self)), opticalAlignment);
            }
            pub inline fn GetOpticalAlignment(self: *const T) DWRITE_OPTICAL_ALIGNMENT {
                return @as(*const IDWriteTextFormat1.VTable, @ptrCast(self.vtable)).GetOpticalAlignment(@as(*const IDWriteTextFormat1, @ptrCast(self)));
            }
            pub inline fn SetFontFallback(self: *const T, fontFallback: ?*IDWriteFontFallback) HRESULT {
                return @as(*const IDWriteTextFormat1.VTable, @ptrCast(self.vtable)).SetFontFallback(@as(*const IDWriteTextFormat1, @ptrCast(self)), fontFallback);
            }
            pub inline fn GetFontFallback(self: *const T, fontFallback: ?*?*IDWriteFontFallback) HRESULT {
                return @as(*const IDWriteTextFormat1.VTable, @ptrCast(self.vtable)).GetFontFallback(@as(*const IDWriteTextFormat1, @ptrCast(self)), fontFallback);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteTextLayout2_Value = Guid.initString("1093c18f-8d5e-43f0-b064-0917311b525e");
pub const IID_IDWriteTextLayout2 = &IID_IDWriteTextLayout2_Value;
pub const IDWriteTextLayout2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextLayout1.VTable,
        GetMetrics: *const fn (
            self: *const IDWriteTextLayout2,
            textMetrics: ?*DWRITE_TEXT_METRICS1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetVerticalGlyphOrientation: *const fn (
            self: *const IDWriteTextLayout2,
            glyphOrientation: DWRITE_VERTICAL_GLYPH_ORIENTATION,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetVerticalGlyphOrientation: *const fn (
            self: *const IDWriteTextLayout2,
        ) callconv(std.os.windows.WINAPI) DWRITE_VERTICAL_GLYPH_ORIENTATION,

        SetLastLineWrapping: *const fn (
            self: *const IDWriteTextLayout2,
            isLastLineWrappingEnabled: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLastLineWrapping: *const fn (
            self: *const IDWriteTextLayout2,
        ) callconv(std.os.windows.WINAPI) BOOL,

        SetOpticalAlignment: *const fn (
            self: *const IDWriteTextLayout2,
            opticalAlignment: DWRITE_OPTICAL_ALIGNMENT,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetOpticalAlignment: *const fn (
            self: *const IDWriteTextLayout2,
        ) callconv(std.os.windows.WINAPI) DWRITE_OPTICAL_ALIGNMENT,

        SetFontFallback: *const fn (
            self: *const IDWriteTextLayout2,
            fontFallback: ?*IDWriteFontFallback,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFallback: *const fn (
            self: *const IDWriteTextLayout2,
            fontFallback: ?*?*IDWriteFontFallback,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextLayout1.MethodMixin(T);
            pub inline fn GetMetrics(self: *const T, textMetrics: ?*DWRITE_TEXT_METRICS1) HRESULT {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).GetMetrics(@as(*const IDWriteTextLayout2, @ptrCast(self)), textMetrics);
            }
            pub inline fn SetVerticalGlyphOrientation(self: *const T, glyphOrientation: DWRITE_VERTICAL_GLYPH_ORIENTATION) HRESULT {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).SetVerticalGlyphOrientation(@as(*const IDWriteTextLayout2, @ptrCast(self)), glyphOrientation);
            }
            pub inline fn GetVerticalGlyphOrientation(self: *const T) DWRITE_VERTICAL_GLYPH_ORIENTATION {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).GetVerticalGlyphOrientation(@as(*const IDWriteTextLayout2, @ptrCast(self)));
            }
            pub inline fn SetLastLineWrapping(self: *const T, isLastLineWrappingEnabled: BOOL) HRESULT {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).SetLastLineWrapping(@as(*const IDWriteTextLayout2, @ptrCast(self)), isLastLineWrappingEnabled);
            }
            pub inline fn GetLastLineWrapping(self: *const T) BOOL {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).GetLastLineWrapping(@as(*const IDWriteTextLayout2, @ptrCast(self)));
            }
            pub inline fn SetOpticalAlignment(self: *const T, opticalAlignment: DWRITE_OPTICAL_ALIGNMENT) HRESULT {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).SetOpticalAlignment(@as(*const IDWriteTextLayout2, @ptrCast(self)), opticalAlignment);
            }
            pub inline fn GetOpticalAlignment(self: *const T) DWRITE_OPTICAL_ALIGNMENT {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).GetOpticalAlignment(@as(*const IDWriteTextLayout2, @ptrCast(self)));
            }
            pub inline fn SetFontFallback(self: *const T, fontFallback: ?*IDWriteFontFallback) HRESULT {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).SetFontFallback(@as(*const IDWriteTextLayout2, @ptrCast(self)), fontFallback);
            }
            pub inline fn GetFontFallback(self: *const T, fontFallback: ?*?*IDWriteFontFallback) HRESULT {
                return @as(*const IDWriteTextLayout2.VTable, @ptrCast(self.vtable)).GetFontFallback(@as(*const IDWriteTextLayout2, @ptrCast(self)), fontFallback);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteTextAnalyzer2_Value = Guid.initString("553a9ff3-5693-4df7-b52b-74806f7f2eb9");
pub const IID_IDWriteTextAnalyzer2 = &IID_IDWriteTextAnalyzer2_Value;
pub const IDWriteTextAnalyzer2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextAnalyzer1.VTable,
        GetGlyphOrientationTransform: *const fn (
            self: *const IDWriteTextAnalyzer2,
            glyphOrientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE,
            isSideways: BOOL,
            originX: f32,
            originY: f32,
            transform: ?*DWRITE_MATRIX,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetTypographicFeatures: *const fn (
            self: *const IDWriteTextAnalyzer2,
            fontFace: ?*IDWriteFontFace,
            scriptAnalysis: DWRITE_SCRIPT_ANALYSIS,
            localeName: ?[*:0]const u16,
            maxTagCount: u32,
            actualTagCount: ?*u32,
            tags: [*]DWRITE_FONT_FEATURE_TAG,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CheckTypographicFeature: *const fn (
            self: *const IDWriteTextAnalyzer2,
            fontFace: ?*IDWriteFontFace,
            scriptAnalysis: DWRITE_SCRIPT_ANALYSIS,
            localeName: ?[*:0]const u16,
            featureTag: DWRITE_FONT_FEATURE_TAG,
            glyphCount: u32,
            glyphIndices: [*:0]const u16,
            featureApplies: [*:0]u8,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextAnalyzer1.MethodMixin(T);
            pub inline fn GetGlyphOrientationTransform(self: *const T, glyphOrientationAngle: DWRITE_GLYPH_ORIENTATION_ANGLE, isSideways: BOOL, originX: f32, originY: f32, transform: ?*DWRITE_MATRIX) HRESULT {
                return @as(*const IDWriteTextAnalyzer2.VTable, @ptrCast(self.vtable)).GetGlyphOrientationTransform(@as(*const IDWriteTextAnalyzer2, @ptrCast(self)), glyphOrientationAngle, isSideways, originX, originY, transform);
            }
            pub inline fn GetTypographicFeatures(self: *const T, fontFace: ?*IDWriteFontFace, scriptAnalysis: DWRITE_SCRIPT_ANALYSIS, localeName: ?[*:0]const u16, maxTagCount: u32, actualTagCount: ?*u32, tags: [*]DWRITE_FONT_FEATURE_TAG) HRESULT {
                return @as(*const IDWriteTextAnalyzer2.VTable, @ptrCast(self.vtable)).GetTypographicFeatures(@as(*const IDWriteTextAnalyzer2, @ptrCast(self)), fontFace, scriptAnalysis, localeName, maxTagCount, actualTagCount, tags);
            }
            pub inline fn CheckTypographicFeature(self: *const T, fontFace: ?*IDWriteFontFace, scriptAnalysis: DWRITE_SCRIPT_ANALYSIS, localeName: ?[*:0]const u16, featureTag: DWRITE_FONT_FEATURE_TAG, glyphCount: u32, glyphIndices: [*:0]const u16, featureApplies: [*:0]u8) HRESULT {
                return @as(*const IDWriteTextAnalyzer2.VTable, @ptrCast(self.vtable)).CheckTypographicFeature(@as(*const IDWriteTextAnalyzer2, @ptrCast(self)), fontFace, scriptAnalysis, localeName, featureTag, glyphCount, glyphIndices, featureApplies);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteFontFallback_Value = Guid.initString("efa008f9-f7a1-48bf-b05c-f224713cc0ff");
pub const IID_IDWriteFontFallback = &IID_IDWriteFontFallback_Value;
pub const IDWriteFontFallback = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        MapCharacters: *const fn (
            self: *const IDWriteFontFallback,
            analysisSource: ?*IDWriteTextAnalysisSource,
            textPosition: u32,
            textLength: u32,
            baseFontCollection: ?*IDWriteFontCollection,
            baseFamilyName: ?[*:0]const u16,
            baseWeight: DWRITE_FONT_WEIGHT,
            baseStyle: DWRITE_FONT_STYLE,
            baseStretch: DWRITE_FONT_STRETCH,
            mappedLength: ?*u32,
            mappedFont: ?*?*IDWriteFont,
            scale: ?*f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn MapCharacters(self: *const T, analysisSource: ?*IDWriteTextAnalysisSource, textPosition: u32, textLength: u32, baseFontCollection: ?*IDWriteFontCollection, baseFamilyName: ?[*:0]const u16, baseWeight: DWRITE_FONT_WEIGHT, baseStyle: DWRITE_FONT_STYLE, baseStretch: DWRITE_FONT_STRETCH, mappedLength: ?*u32, mappedFont: ?*?*IDWriteFont, scale: ?*f32) HRESULT {
                return @as(*const IDWriteFontFallback.VTable, @ptrCast(self.vtable)).MapCharacters(@as(*const IDWriteFontFallback, @ptrCast(self)), analysisSource, textPosition, textLength, baseFontCollection, baseFamilyName, baseWeight, baseStyle, baseStretch, mappedLength, mappedFont, scale);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteFontFallbackBuilder_Value = Guid.initString("fd882d06-8aba-4fb8-b849-8be8b73e14de");
pub const IID_IDWriteFontFallbackBuilder = &IID_IDWriteFontFallbackBuilder_Value;
pub const IDWriteFontFallbackBuilder = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        AddMapping: *const fn (
            self: *const IDWriteFontFallbackBuilder,
            ranges: [*]const DWRITE_UNICODE_RANGE,
            rangesCount: u32,
            targetFamilyNames: [*]const ?*const u16,
            targetFamilyNamesCount: u32,
            fontCollection: ?*IDWriteFontCollection,
            localeName: ?[*:0]const u16,
            baseFamilyName: ?[*:0]const u16,
            scale: f32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AddMappings: *const fn (
            self: *const IDWriteFontFallbackBuilder,
            fontFallback: ?*IDWriteFontFallback,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFallback: *const fn (
            self: *const IDWriteFontFallbackBuilder,
            fontFallback: ?*?*IDWriteFontFallback,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn AddMapping(self: *const T, ranges: [*]const DWRITE_UNICODE_RANGE, rangesCount: u32, targetFamilyNames: [*]const ?*const u16, targetFamilyNamesCount: u32, fontCollection: ?*IDWriteFontCollection, localeName: ?[*:0]const u16, baseFamilyName: ?[*:0]const u16, scale: f32) HRESULT {
                return @as(*const IDWriteFontFallbackBuilder.VTable, @ptrCast(self.vtable)).AddMapping(@as(*const IDWriteFontFallbackBuilder, @ptrCast(self)), ranges, rangesCount, targetFamilyNames, targetFamilyNamesCount, fontCollection, localeName, baseFamilyName, scale);
            }
            pub inline fn AddMappings(self: *const T, fontFallback: ?*IDWriteFontFallback) HRESULT {
                return @as(*const IDWriteFontFallbackBuilder.VTable, @ptrCast(self.vtable)).AddMappings(@as(*const IDWriteFontFallbackBuilder, @ptrCast(self)), fontFallback);
            }
            pub inline fn CreateFontFallback(self: *const T, fontFallback: ?*?*IDWriteFontFallback) HRESULT {
                return @as(*const IDWriteFontFallbackBuilder.VTable, @ptrCast(self.vtable)).CreateFontFallback(@as(*const IDWriteFontFallbackBuilder, @ptrCast(self)), fontFallback);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteFont2_Value = Guid.initString("29748ed6-8c9c-4a6a-be0b-d912e8538944");
pub const IID_IDWriteFont2 = &IID_IDWriteFont2_Value;
pub const IDWriteFont2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFont1.VTable,
        IsColorFont: *const fn (
            self: *const IDWriteFont2,
        ) callconv(std.os.windows.WINAPI) BOOL,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFont1.MethodMixin(T);
            pub inline fn IsColorFont(self: *const T) BOOL {
                return @as(*const IDWriteFont2.VTable, @ptrCast(self.vtable)).IsColorFont(@as(*const IDWriteFont2, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteFontFace2_Value = Guid.initString("d8b768ff-64bc-4e66-982b-ec8e87f693f7");
pub const IID_IDWriteFontFace2 = &IID_IDWriteFontFace2_Value;
pub const IDWriteFontFace2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFace1.VTable,
        IsColorFont: *const fn (
            self: *const IDWriteFontFace2,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetColorPaletteCount: *const fn (
            self: *const IDWriteFontFace2,
        ) callconv(std.os.windows.WINAPI) u32,

        GetPaletteEntryCount: *const fn (
            self: *const IDWriteFontFace2,
        ) callconv(std.os.windows.WINAPI) u32,

        GetPaletteEntries: *const fn (
            self: *const IDWriteFontFace2,
            colorPaletteIndex: u32,
            firstEntryIndex: u32,
            entryCount: u32,
            paletteEntries: [*]DWRITE_COLOR_F,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetRecommendedRenderingMode: *const fn (
            self: *const IDWriteFontFace2,
            fontEmSize: f32,
            dpiX: f32,
            dpiY: f32,
            transform: ?*const DWRITE_MATRIX,
            isSideways: BOOL,
            outlineThreshold: DWRITE_OUTLINE_THRESHOLD,
            measuringMode: DWRITE_MEASURING_MODE,
            renderingParams: ?*IDWriteRenderingParams,
            renderingMode: ?*DWRITE_RENDERING_MODE,
            gridFitMode: ?*DWRITE_GRID_FIT_MODE,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFace1.MethodMixin(T);
            pub inline fn IsColorFont(self: *const T) BOOL {
                return @as(*const IDWriteFontFace2.VTable, @ptrCast(self.vtable)).IsColorFont(@as(*const IDWriteFontFace2, @ptrCast(self)));
            }
            pub inline fn GetColorPaletteCount(self: *const T) u32 {
                return @as(*const IDWriteFontFace2.VTable, @ptrCast(self.vtable)).GetColorPaletteCount(@as(*const IDWriteFontFace2, @ptrCast(self)));
            }
            pub inline fn GetPaletteEntryCount(self: *const T) u32 {
                return @as(*const IDWriteFontFace2.VTable, @ptrCast(self.vtable)).GetPaletteEntryCount(@as(*const IDWriteFontFace2, @ptrCast(self)));
            }
            pub inline fn GetPaletteEntries(self: *const T, colorPaletteIndex: u32, firstEntryIndex: u32, entryCount: u32, paletteEntries: [*]DWRITE_COLOR_F) HRESULT {
                return @as(*const IDWriteFontFace2.VTable, @ptrCast(self.vtable)).GetPaletteEntries(@as(*const IDWriteFontFace2, @ptrCast(self)), colorPaletteIndex, firstEntryIndex, entryCount, paletteEntries);
            }
            pub inline fn GetRecommendedRenderingMode(self: *const T, fontEmSize: f32, dpiX: f32, dpiY: f32, transform: ?*const DWRITE_MATRIX, isSideways: BOOL, outlineThreshold: DWRITE_OUTLINE_THRESHOLD, measuringMode: DWRITE_MEASURING_MODE, renderingParams: ?*IDWriteRenderingParams, renderingMode: ?*DWRITE_RENDERING_MODE, gridFitMode: ?*DWRITE_GRID_FIT_MODE) HRESULT {
                return @as(*const IDWriteFontFace2.VTable, @ptrCast(self.vtable)).GetRecommendedRenderingMode(@as(*const IDWriteFontFace2, @ptrCast(self)), fontEmSize, dpiX, dpiY, transform, isSideways, outlineThreshold, measuringMode, renderingParams, renderingMode, gridFitMode);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_COLOR_GLYPH_RUN = extern struct {
    glyphRun: DWRITE_GLYPH_RUN,
    glyphRunDescription: ?*DWRITE_GLYPH_RUN_DESCRIPTION,
    baselineOriginX: f32,
    baselineOriginY: f32,
    runColor: DWRITE_COLOR_F,
    paletteIndex: u16,
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteColorGlyphRunEnumerator_Value = Guid.initString("d31fbe17-f157-41a2-8d24-cb779e0560e8");
pub const IID_IDWriteColorGlyphRunEnumerator = &IID_IDWriteColorGlyphRunEnumerator_Value;
pub const IDWriteColorGlyphRunEnumerator = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        MoveNext: *const fn (
            self: *const IDWriteColorGlyphRunEnumerator,
            hasRun: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetCurrentRun: *const fn (
            self: *const IDWriteColorGlyphRunEnumerator,
            colorGlyphRun: ?*const ?*DWRITE_COLOR_GLYPH_RUN,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn MoveNext(self: *const T, hasRun: ?*BOOL) HRESULT {
                return @as(*const IDWriteColorGlyphRunEnumerator.VTable, @ptrCast(self.vtable)).MoveNext(@as(*const IDWriteColorGlyphRunEnumerator, @ptrCast(self)), hasRun);
            }
            pub inline fn GetCurrentRun(self: *const T, colorGlyphRun: ?*const ?*DWRITE_COLOR_GLYPH_RUN) HRESULT {
                return @as(*const IDWriteColorGlyphRunEnumerator.VTable, @ptrCast(self.vtable)).GetCurrentRun(@as(*const IDWriteColorGlyphRunEnumerator, @ptrCast(self)), colorGlyphRun);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteRenderingParams2_Value = Guid.initString("f9d711c3-9777-40ae-87e8-3e5af9bf0948");
pub const IID_IDWriteRenderingParams2 = &IID_IDWriteRenderingParams2_Value;
pub const IDWriteRenderingParams2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteRenderingParams1.VTable,
        GetGridFitMode: *const fn (
            self: *const IDWriteRenderingParams2,
        ) callconv(std.os.windows.WINAPI) DWRITE_GRID_FIT_MODE,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteRenderingParams1.MethodMixin(T);
            pub inline fn GetGridFitMode(self: *const T) DWRITE_GRID_FIT_MODE {
                return @as(*const IDWriteRenderingParams2.VTable, @ptrCast(self.vtable)).GetGridFitMode(@as(*const IDWriteRenderingParams2, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteFactory2_Value = Guid.initString("0439fc60-ca44-4994-8dee-3a9af7b732ec");
pub const IID_IDWriteFactory2 = &IID_IDWriteFactory2_Value;
pub const IDWriteFactory2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFactory1.VTable,
        GetSystemFontFallback: *const fn (
            self: *const IDWriteFactory2,
            fontFallback: ?*?*IDWriteFontFallback,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFallbackBuilder: *const fn (
            self: *const IDWriteFactory2,
            fontFallbackBuilder: ?*?*IDWriteFontFallbackBuilder,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        TranslateColorGlyphRun: *const fn (
            self: *const IDWriteFactory2,
            baselineOriginX: f32,
            baselineOriginY: f32,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            glyphRunDescription: ?*const DWRITE_GLYPH_RUN_DESCRIPTION,
            measuringMode: DWRITE_MEASURING_MODE,
            worldToDeviceTransform: ?*const DWRITE_MATRIX,
            colorPaletteIndex: u32,
            colorLayers: ?*?*IDWriteColorGlyphRunEnumerator,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateCustomRenderingParams: *const fn (
            self: *const IDWriteFactory2,
            gamma: f32,
            enhancedContrast: f32,
            grayscaleEnhancedContrast: f32,
            clearTypeLevel: f32,
            pixelGeometry: DWRITE_PIXEL_GEOMETRY,
            renderingMode: DWRITE_RENDERING_MODE,
            gridFitMode: DWRITE_GRID_FIT_MODE,
            renderingParams: ?*?*IDWriteRenderingParams2,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateGlyphRunAnalysis: *const fn (
            self: *const IDWriteFactory2,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            transform: ?*const DWRITE_MATRIX,
            renderingMode: DWRITE_RENDERING_MODE,
            measuringMode: DWRITE_MEASURING_MODE,
            gridFitMode: DWRITE_GRID_FIT_MODE,
            antialiasMode: DWRITE_TEXT_ANTIALIAS_MODE,
            baselineOriginX: f32,
            baselineOriginY: f32,
            glyphRunAnalysis: ?*?*IDWriteGlyphRunAnalysis,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFactory1.MethodMixin(T);
            pub inline fn GetSystemFontFallback(self: *const T, fontFallback: ?*?*IDWriteFontFallback) HRESULT {
                return @as(*const IDWriteFactory2.VTable, @ptrCast(self.vtable)).GetSystemFontFallback(@as(*const IDWriteFactory2, @ptrCast(self)), fontFallback);
            }
            pub inline fn CreateFontFallbackBuilder(self: *const T, fontFallbackBuilder: ?*?*IDWriteFontFallbackBuilder) HRESULT {
                return @as(*const IDWriteFactory2.VTable, @ptrCast(self.vtable)).CreateFontFallbackBuilder(@as(*const IDWriteFactory2, @ptrCast(self)), fontFallbackBuilder);
            }
            pub inline fn TranslateColorGlyphRun(self: *const T, baselineOriginX: f32, baselineOriginY: f32, glyphRun: ?*const DWRITE_GLYPH_RUN, glyphRunDescription: ?*const DWRITE_GLYPH_RUN_DESCRIPTION, measuringMode: DWRITE_MEASURING_MODE, worldToDeviceTransform: ?*const DWRITE_MATRIX, colorPaletteIndex: u32, colorLayers: ?*?*IDWriteColorGlyphRunEnumerator) HRESULT {
                return @as(*const IDWriteFactory2.VTable, @ptrCast(self.vtable)).TranslateColorGlyphRun(@as(*const IDWriteFactory2, @ptrCast(self)), baselineOriginX, baselineOriginY, glyphRun, glyphRunDescription, measuringMode, worldToDeviceTransform, colorPaletteIndex, colorLayers);
            }
            pub inline fn CreateCustomRenderingParams(self: *const T, gamma: f32, enhancedContrast: f32, grayscaleEnhancedContrast: f32, clearTypeLevel: f32, pixelGeometry: DWRITE_PIXEL_GEOMETRY, renderingMode: DWRITE_RENDERING_MODE, gridFitMode: DWRITE_GRID_FIT_MODE, renderingParams: ?*?*IDWriteRenderingParams2) HRESULT {
                return @as(*const IDWriteFactory2.VTable, @ptrCast(self.vtable)).CreateCustomRenderingParams(@as(*const IDWriteFactory2, @ptrCast(self)), gamma, enhancedContrast, grayscaleEnhancedContrast, clearTypeLevel, pixelGeometry, renderingMode, gridFitMode, renderingParams);
            }
            pub inline fn CreateGlyphRunAnalysis(self: *const T, glyphRun: ?*const DWRITE_GLYPH_RUN, transform: ?*const DWRITE_MATRIX, renderingMode: DWRITE_RENDERING_MODE, measuringMode: DWRITE_MEASURING_MODE, gridFitMode: DWRITE_GRID_FIT_MODE, antialiasMode: DWRITE_TEXT_ANTIALIAS_MODE, baselineOriginX: f32, baselineOriginY: f32, glyphRunAnalysis: ?*?*IDWriteGlyphRunAnalysis) HRESULT {
                return @as(*const IDWriteFactory2.VTable, @ptrCast(self.vtable)).CreateGlyphRunAnalysis(@as(*const IDWriteFactory2, @ptrCast(self)), glyphRun, transform, renderingMode, measuringMode, gridFitMode, antialiasMode, baselineOriginX, baselineOriginY, glyphRunAnalysis);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_FONT_PROPERTY_ID = enum(i32) {
    NONE = 0,
    WEIGHT_STRETCH_STYLE_FAMILY_NAME = 1,
    TYPOGRAPHIC_FAMILY_NAME = 2,
    WEIGHT_STRETCH_STYLE_FACE_NAME = 3,
    FULL_NAME = 4,
    WIN32_FAMILY_NAME = 5,
    POSTSCRIPT_NAME = 6,
    DESIGN_SCRIPT_LANGUAGE_TAG = 7,
    SUPPORTED_SCRIPT_LANGUAGE_TAG = 8,
    SEMANTIC_TAG = 9,
    WEIGHT = 10,
    STRETCH = 11,
    STYLE = 12,
    TYPOGRAPHIC_FACE_NAME = 13,
    // TOTAL = 13, this enum value conflicts with TYPOGRAPHIC_FACE_NAME
    TOTAL_RS3 = 14,
    // PREFERRED_FAMILY_NAME = 2, this enum value conflicts with TYPOGRAPHIC_FAMILY_NAME
    // FAMILY_NAME = 1, this enum value conflicts with WEIGHT_STRETCH_STYLE_FAMILY_NAME
    // FACE_NAME = 3, this enum value conflicts with WEIGHT_STRETCH_STYLE_FACE_NAME
};
pub const DWRITE_FONT_PROPERTY_ID_NONE = DWRITE_FONT_PROPERTY_ID.NONE;
pub const DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FAMILY_NAME = DWRITE_FONT_PROPERTY_ID.WEIGHT_STRETCH_STYLE_FAMILY_NAME;
pub const DWRITE_FONT_PROPERTY_ID_TYPOGRAPHIC_FAMILY_NAME = DWRITE_FONT_PROPERTY_ID.TYPOGRAPHIC_FAMILY_NAME;
pub const DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FACE_NAME = DWRITE_FONT_PROPERTY_ID.WEIGHT_STRETCH_STYLE_FACE_NAME;
pub const DWRITE_FONT_PROPERTY_ID_FULL_NAME = DWRITE_FONT_PROPERTY_ID.FULL_NAME;
pub const DWRITE_FONT_PROPERTY_ID_WIN32_FAMILY_NAME = DWRITE_FONT_PROPERTY_ID.WIN32_FAMILY_NAME;
pub const DWRITE_FONT_PROPERTY_ID_POSTSCRIPT_NAME = DWRITE_FONT_PROPERTY_ID.POSTSCRIPT_NAME;
pub const DWRITE_FONT_PROPERTY_ID_DESIGN_SCRIPT_LANGUAGE_TAG = DWRITE_FONT_PROPERTY_ID.DESIGN_SCRIPT_LANGUAGE_TAG;
pub const DWRITE_FONT_PROPERTY_ID_SUPPORTED_SCRIPT_LANGUAGE_TAG = DWRITE_FONT_PROPERTY_ID.SUPPORTED_SCRIPT_LANGUAGE_TAG;
pub const DWRITE_FONT_PROPERTY_ID_SEMANTIC_TAG = DWRITE_FONT_PROPERTY_ID.SEMANTIC_TAG;
pub const DWRITE_FONT_PROPERTY_ID_WEIGHT = DWRITE_FONT_PROPERTY_ID.WEIGHT;
pub const DWRITE_FONT_PROPERTY_ID_STRETCH = DWRITE_FONT_PROPERTY_ID.STRETCH;
pub const DWRITE_FONT_PROPERTY_ID_STYLE = DWRITE_FONT_PROPERTY_ID.STYLE;
pub const DWRITE_FONT_PROPERTY_ID_TYPOGRAPHIC_FACE_NAME = DWRITE_FONT_PROPERTY_ID.TYPOGRAPHIC_FACE_NAME;
pub const DWRITE_FONT_PROPERTY_ID_TOTAL = DWRITE_FONT_PROPERTY_ID.TYPOGRAPHIC_FACE_NAME;
pub const DWRITE_FONT_PROPERTY_ID_TOTAL_RS3 = DWRITE_FONT_PROPERTY_ID.TOTAL_RS3;
pub const DWRITE_FONT_PROPERTY_ID_PREFERRED_FAMILY_NAME = DWRITE_FONT_PROPERTY_ID.TYPOGRAPHIC_FAMILY_NAME;
pub const DWRITE_FONT_PROPERTY_ID_FAMILY_NAME = DWRITE_FONT_PROPERTY_ID.WEIGHT_STRETCH_STYLE_FAMILY_NAME;
pub const DWRITE_FONT_PROPERTY_ID_FACE_NAME = DWRITE_FONT_PROPERTY_ID.WEIGHT_STRETCH_STYLE_FACE_NAME;

pub const DWRITE_FONT_PROPERTY = extern struct {
    propertyId: DWRITE_FONT_PROPERTY_ID,
    propertyValue: ?[*:0]const u16,
    localeName: ?[*:0]const u16,
};

pub const DWRITE_LOCALITY = enum(i32) {
    REMOTE = 0,
    PARTIAL = 1,
    LOCAL = 2,
};
pub const DWRITE_LOCALITY_REMOTE = DWRITE_LOCALITY.REMOTE;
pub const DWRITE_LOCALITY_PARTIAL = DWRITE_LOCALITY.PARTIAL;
pub const DWRITE_LOCALITY_LOCAL = DWRITE_LOCALITY.LOCAL;

pub const DWRITE_RENDERING_MODE1 = enum(i32) {
    DEFAULT = 0,
    ALIASED = 1,
    GDI_CLASSIC = 2,
    GDI_NATURAL = 3,
    NATURAL = 4,
    NATURAL_SYMMETRIC = 5,
    OUTLINE = 6,
    NATURAL_SYMMETRIC_DOWNSAMPLED = 7,
};
pub const DWRITE_RENDERING_MODE1_DEFAULT = DWRITE_RENDERING_MODE1.DEFAULT;
pub const DWRITE_RENDERING_MODE1_ALIASED = DWRITE_RENDERING_MODE1.ALIASED;
pub const DWRITE_RENDERING_MODE1_GDI_CLASSIC = DWRITE_RENDERING_MODE1.GDI_CLASSIC;
pub const DWRITE_RENDERING_MODE1_GDI_NATURAL = DWRITE_RENDERING_MODE1.GDI_NATURAL;
pub const DWRITE_RENDERING_MODE1_NATURAL = DWRITE_RENDERING_MODE1.NATURAL;
pub const DWRITE_RENDERING_MODE1_NATURAL_SYMMETRIC = DWRITE_RENDERING_MODE1.NATURAL_SYMMETRIC;
pub const DWRITE_RENDERING_MODE1_OUTLINE = DWRITE_RENDERING_MODE1.OUTLINE;
pub const DWRITE_RENDERING_MODE1_NATURAL_SYMMETRIC_DOWNSAMPLED = DWRITE_RENDERING_MODE1.NATURAL_SYMMETRIC_DOWNSAMPLED;

// TODO: this type is limited to platform 'windows10.0.10240'
const IID_IDWriteRenderingParams3_Value = Guid.initString("b7924baa-391b-412a-8c5c-e44cc2d867dc");
pub const IID_IDWriteRenderingParams3 = &IID_IDWriteRenderingParams3_Value;
pub const IDWriteRenderingParams3 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteRenderingParams2.VTable,
        GetRenderingMode1: *const fn (
            self: *const IDWriteRenderingParams3,
        ) callconv(std.os.windows.WINAPI) DWRITE_RENDERING_MODE1,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteRenderingParams2.MethodMixin(T);
            pub inline fn GetRenderingMode1(self: *const T) DWRITE_RENDERING_MODE1 {
                return @as(*const IDWriteRenderingParams3.VTable, @ptrCast(self.vtable)).GetRenderingMode1(@as(*const IDWriteRenderingParams3, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows10.0.10240'
const IID_IDWriteFactory3_Value = Guid.initString("9a1b41c3-d3bb-466a-87fc-fe67556a3b65");
pub const IID_IDWriteFactory3 = &IID_IDWriteFactory3_Value;
pub const IDWriteFactory3 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFactory2.VTable,
        CreateGlyphRunAnalysis: *const fn (
            self: *const IDWriteFactory3,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            transform: ?*const DWRITE_MATRIX,
            renderingMode: DWRITE_RENDERING_MODE1,
            measuringMode: DWRITE_MEASURING_MODE,
            gridFitMode: DWRITE_GRID_FIT_MODE,
            antialiasMode: DWRITE_TEXT_ANTIALIAS_MODE,
            baselineOriginX: f32,
            baselineOriginY: f32,
            glyphRunAnalysis: ?*?*IDWriteGlyphRunAnalysis,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateCustomRenderingParams: *const fn (
            self: *const IDWriteFactory3,
            gamma: f32,
            enhancedContrast: f32,
            grayscaleEnhancedContrast: f32,
            clearTypeLevel: f32,
            pixelGeometry: DWRITE_PIXEL_GEOMETRY,
            renderingMode: DWRITE_RENDERING_MODE1,
            gridFitMode: DWRITE_GRID_FIT_MODE,
            renderingParams: ?*?*IDWriteRenderingParams3,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFaceReference: *const fn (
            self: *const IDWriteFactory3,
            fontFile: ?*IDWriteFontFile,
            faceIndex: u32,
            fontSimulations: DWRITE_FONT_SIMULATIONS,
            fontFaceReference: ?*?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFaceReference1: *const fn (
            self: *const IDWriteFactory3,
            filePath: ?[*:0]const u16,
            lastWriteTime: ?*const FILETIME,
            faceIndex: u32,
            fontSimulations: DWRITE_FONT_SIMULATIONS,
            fontFaceReference: ?*?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetSystemFontSet: *const fn (
            self: *const IDWriteFactory3,
            fontSet: ?*?*IDWriteFontSet,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontSetBuilder: *const fn (
            self: *const IDWriteFactory3,
            fontSetBuilder: ?*?*IDWriteFontSetBuilder,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontCollectionFromFontSet: *const fn (
            self: *const IDWriteFactory3,
            fontSet: ?*IDWriteFontSet,
            fontCollection: ?*?*IDWriteFontCollection1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetSystemFontCollection: *const fn (
            self: *const IDWriteFactory3,
            includeDownloadableFonts: BOOL,
            fontCollection: ?*?*IDWriteFontCollection1,
            checkForUpdates: BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontDownloadQueue: *const fn (
            self: *const IDWriteFactory3,
            fontDownloadQueue: ?*?*IDWriteFontDownloadQueue,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFactory2.MethodMixin(T);
            pub inline fn CreateGlyphRunAnalysis(self: *const T, glyphRun: ?*const DWRITE_GLYPH_RUN, transform: ?*const DWRITE_MATRIX, renderingMode: DWRITE_RENDERING_MODE1, measuringMode: DWRITE_MEASURING_MODE, gridFitMode: DWRITE_GRID_FIT_MODE, antialiasMode: DWRITE_TEXT_ANTIALIAS_MODE, baselineOriginX: f32, baselineOriginY: f32, glyphRunAnalysis: ?*?*IDWriteGlyphRunAnalysis) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).CreateGlyphRunAnalysis(@as(*const IDWriteFactory3, @ptrCast(self)), glyphRun, transform, renderingMode, measuringMode, gridFitMode, antialiasMode, baselineOriginX, baselineOriginY, glyphRunAnalysis);
            }
            pub inline fn CreateCustomRenderingParams(self: *const T, gamma: f32, enhancedContrast: f32, grayscaleEnhancedContrast: f32, clearTypeLevel: f32, pixelGeometry: DWRITE_PIXEL_GEOMETRY, renderingMode: DWRITE_RENDERING_MODE1, gridFitMode: DWRITE_GRID_FIT_MODE, renderingParams: ?*?*IDWriteRenderingParams3) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).CreateCustomRenderingParams(@as(*const IDWriteFactory3, @ptrCast(self)), gamma, enhancedContrast, grayscaleEnhancedContrast, clearTypeLevel, pixelGeometry, renderingMode, gridFitMode, renderingParams);
            }
            pub inline fn CreateFontFaceReference(self: *const T, fontFile: ?*IDWriteFontFile, faceIndex: u32, fontSimulations: DWRITE_FONT_SIMULATIONS, fontFaceReference: ?*?*IDWriteFontFaceReference) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).CreateFontFaceReference(@as(*const IDWriteFactory3, @ptrCast(self)), fontFile, faceIndex, fontSimulations, fontFaceReference);
            }
            pub inline fn CreateFontFaceReference1(self: *const T, filePath: ?[*:0]const u16, lastWriteTime: ?*const FILETIME, faceIndex: u32, fontSimulations: DWRITE_FONT_SIMULATIONS, fontFaceReference: ?*?*IDWriteFontFaceReference) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).CreateFontFaceReference(@as(*const IDWriteFactory3, @ptrCast(self)), filePath, lastWriteTime, faceIndex, fontSimulations, fontFaceReference);
            }
            pub inline fn GetSystemFontSet(self: *const T, fontSet: ?*?*IDWriteFontSet) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).GetSystemFontSet(@as(*const IDWriteFactory3, @ptrCast(self)), fontSet);
            }
            pub inline fn CreateFontSetBuilder(self: *const T, fontSetBuilder: ?*?*IDWriteFontSetBuilder) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).CreateFontSetBuilder(@as(*const IDWriteFactory3, @ptrCast(self)), fontSetBuilder);
            }
            pub inline fn CreateFontCollectionFromFontSet(self: *const T, fontSet: ?*IDWriteFontSet, fontCollection: ?*?*IDWriteFontCollection1) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).CreateFontCollectionFromFontSet(@as(*const IDWriteFactory3, @ptrCast(self)), fontSet, fontCollection);
            }
            pub inline fn GetSystemFontCollection(self: *const T, includeDownloadableFonts: BOOL, fontCollection: ?*?*IDWriteFontCollection1, checkForUpdates: BOOL) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).GetSystemFontCollection(@as(*const IDWriteFactory3, @ptrCast(self)), includeDownloadableFonts, fontCollection, checkForUpdates);
            }
            pub inline fn GetFontDownloadQueue(self: *const T, fontDownloadQueue: ?*?*IDWriteFontDownloadQueue) HRESULT {
                return @as(*const IDWriteFactory3.VTable, @ptrCast(self.vtable)).GetFontDownloadQueue(@as(*const IDWriteFactory3, @ptrCast(self)), fontDownloadQueue);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows10.0.10240'
const IID_IDWriteFontSet_Value = Guid.initString("53585141-d9f8-4095-8321-d73cf6bd116b");
pub const IID_IDWriteFontSet = &IID_IDWriteFontSet_Value;
pub const IDWriteFontSet = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetFontCount: *const fn (
            self: *const IDWriteFontSet,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontFaceReference: *const fn (
            self: *const IDWriteFontSet,
            listIndex: u32,
            fontFaceReference: ?*?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        FindFontFaceReference: *const fn (
            self: *const IDWriteFontSet,
            fontFaceReference: ?*IDWriteFontFaceReference,
            listIndex: ?*u32,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        FindFontFace: *const fn (
            self: *const IDWriteFontSet,
            fontFace: ?*IDWriteFontFace,
            listIndex: ?*u32,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetPropertyValues: *const fn (
            self: *const IDWriteFontSet,
            propertyID: DWRITE_FONT_PROPERTY_ID,
            values: ?*?*IDWriteStringList,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetPropertyValues1: *const fn (
            self: *const IDWriteFontSet,
            propertyID: DWRITE_FONT_PROPERTY_ID,
            preferredLocaleNames: ?[*:0]const u16,
            values: ?*?*IDWriteStringList,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetPropertyValues2: *const fn (
            self: *const IDWriteFontSet,
            listIndex: u32,
            propertyId: DWRITE_FONT_PROPERTY_ID,
            exists: ?*BOOL,
            values: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetPropertyOccurrenceCount: *const fn (
            self: *const IDWriteFontSet,
            property: ?*const DWRITE_FONT_PROPERTY,
            propertyOccurrenceCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMatchingFonts: *const fn (
            self: *const IDWriteFontSet,
            familyName: ?[*:0]const u16,
            fontWeight: DWRITE_FONT_WEIGHT,
            fontStretch: DWRITE_FONT_STRETCH,
            fontStyle: DWRITE_FONT_STYLE,
            filteredSet: ?*?*IDWriteFontSet,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMatchingFonts1: *const fn (
            self: *const IDWriteFontSet,
            properties: [*]const DWRITE_FONT_PROPERTY,
            propertyCount: u32,
            filteredSet: ?*?*IDWriteFontSet,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetFontCount(self: *const T) u32 {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).GetFontCount(@as(*const IDWriteFontSet, @ptrCast(self)));
            }
            pub inline fn GetFontFaceReference(self: *const T, listIndex: u32, fontFaceReference: ?*?*IDWriteFontFaceReference) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).GetFontFaceReference(@as(*const IDWriteFontSet, @ptrCast(self)), listIndex, fontFaceReference);
            }
            pub inline fn FindFontFaceReference(self: *const T, fontFaceReference: ?*IDWriteFontFaceReference, listIndex: ?*u32, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).FindFontFaceReference(@as(*const IDWriteFontSet, @ptrCast(self)), fontFaceReference, listIndex, exists);
            }
            pub inline fn FindFontFace(self: *const T, fontFace: ?*IDWriteFontFace, listIndex: ?*u32, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).FindFontFace(@as(*const IDWriteFontSet, @ptrCast(self)), fontFace, listIndex, exists);
            }
            pub inline fn GetPropertyValues(self: *const T, propertyID: DWRITE_FONT_PROPERTY_ID, values: ?*?*IDWriteStringList) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).GetPropertyValues(@as(*const IDWriteFontSet, @ptrCast(self)), propertyID, values);
            }
            pub inline fn GetPropertyValues1(self: *const T, propertyID: DWRITE_FONT_PROPERTY_ID, preferredLocaleNames: ?[*:0]const u16, values: ?*?*IDWriteStringList) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).GetPropertyValues(@as(*const IDWriteFontSet, @ptrCast(self)), propertyID, preferredLocaleNames, values);
            }
            pub inline fn GetPropertyValues2(self: *const T, listIndex: u32, propertyId: DWRITE_FONT_PROPERTY_ID, exists: ?*BOOL, values: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).GetPropertyValues(@as(*const IDWriteFontSet, @ptrCast(self)), listIndex, propertyId, exists, values);
            }
            pub inline fn GetPropertyOccurrenceCount(self: *const T, property: ?*const DWRITE_FONT_PROPERTY, propertyOccurrenceCount: ?*u32) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).GetPropertyOccurrenceCount(@as(*const IDWriteFontSet, @ptrCast(self)), property, propertyOccurrenceCount);
            }
            pub inline fn GetMatchingFonts(self: *const T, familyName: ?[*:0]const u16, fontWeight: DWRITE_FONT_WEIGHT, fontStretch: DWRITE_FONT_STRETCH, fontStyle: DWRITE_FONT_STYLE, filteredSet: ?*?*IDWriteFontSet) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).GetMatchingFonts(@as(*const IDWriteFontSet, @ptrCast(self)), familyName, fontWeight, fontStretch, fontStyle, filteredSet);
            }
            pub inline fn GetMatchingFonts1(self: *const T, properties: [*]const DWRITE_FONT_PROPERTY, propertyCount: u32, filteredSet: ?*?*IDWriteFontSet) HRESULT {
                return @as(*const IDWriteFontSet.VTable, @ptrCast(self.vtable)).GetMatchingFonts(@as(*const IDWriteFontSet, @ptrCast(self)), properties, propertyCount, filteredSet);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontSetBuilder_Value = Guid.initString("2f642afe-9c68-4f40-b8be-457401afcb3d");
pub const IID_IDWriteFontSetBuilder = &IID_IDWriteFontSetBuilder_Value;
pub const IDWriteFontSetBuilder = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        AddFontFaceReference: *const fn (
            self: *const IDWriteFontSetBuilder,
            fontFaceReference: ?*IDWriteFontFaceReference,
            properties: [*]const DWRITE_FONT_PROPERTY,
            propertyCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AddFontFaceReference1: *const fn (
            self: *const IDWriteFontSetBuilder,
            fontFaceReference: ?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AddFontSet: *const fn (
            self: *const IDWriteFontSetBuilder,
            fontSet: ?*IDWriteFontSet,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontSet: *const fn (
            self: *const IDWriteFontSetBuilder,
            fontSet: ?*?*IDWriteFontSet,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn AddFontFaceReference(self: *const T, fontFaceReference: ?*IDWriteFontFaceReference, properties: [*]const DWRITE_FONT_PROPERTY, propertyCount: u32) HRESULT {
                return @as(*const IDWriteFontSetBuilder.VTable, @ptrCast(self.vtable)).AddFontFaceReference(@as(*const IDWriteFontSetBuilder, @ptrCast(self)), fontFaceReference, properties, propertyCount);
            }
            pub inline fn AddFontFaceReference1(self: *const T, fontFaceReference: ?*IDWriteFontFaceReference) HRESULT {
                return @as(*const IDWriteFontSetBuilder.VTable, @ptrCast(self.vtable)).AddFontFaceReference(@as(*const IDWriteFontSetBuilder, @ptrCast(self)), fontFaceReference);
            }
            pub inline fn AddFontSet(self: *const T, fontSet: ?*IDWriteFontSet) HRESULT {
                return @as(*const IDWriteFontSetBuilder.VTable, @ptrCast(self.vtable)).AddFontSet(@as(*const IDWriteFontSetBuilder, @ptrCast(self)), fontSet);
            }
            pub inline fn CreateFontSet(self: *const T, fontSet: ?*?*IDWriteFontSet) HRESULT {
                return @as(*const IDWriteFontSetBuilder.VTable, @ptrCast(self.vtable)).CreateFontSet(@as(*const IDWriteFontSetBuilder, @ptrCast(self)), fontSet);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows6.1'
const IID_IDWriteFontCollection1_Value = Guid.initString("53585141-d9f8-4095-8321-d73cf6bd116c");
pub const IID_IDWriteFontCollection1 = &IID_IDWriteFontCollection1_Value;
pub const IDWriteFontCollection1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontCollection.VTable,
        GetFontSet: *const fn (
            self: *const IDWriteFontCollection1,
            fontSet: ?*?*IDWriteFontSet,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFamily: *const fn (
            self: *const IDWriteFontCollection1,
            index: u32,
            fontFamily: ?*?*IDWriteFontFamily1,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontCollection.MethodMixin(T);
            pub inline fn GetFontSet(self: *const T, fontSet: ?*?*IDWriteFontSet) HRESULT {
                return @as(*const IDWriteFontCollection1.VTable, @ptrCast(self.vtable)).GetFontSet(@as(*const IDWriteFontCollection1, @ptrCast(self)), fontSet);
            }
            pub inline fn GetFontFamily(self: *const T, index: u32, fontFamily: ?*?*IDWriteFontFamily1) HRESULT {
                return @as(*const IDWriteFontCollection1.VTable, @ptrCast(self.vtable)).GetFontFamily(@as(*const IDWriteFontCollection1, @ptrCast(self)), index, fontFamily);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows10.0.10240'
const IID_IDWriteFontFamily1_Value = Guid.initString("da20d8ef-812a-4c43-9802-62ec4abd7adf");
pub const IID_IDWriteFontFamily1 = &IID_IDWriteFontFamily1_Value;
pub const IDWriteFontFamily1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFamily.VTable,
        GetFontLocality: *const fn (
            self: *const IDWriteFontFamily1,
            listIndex: u32,
        ) callconv(std.os.windows.WINAPI) DWRITE_LOCALITY,

        GetFont: *const fn (
            self: *const IDWriteFontFamily1,
            listIndex: u32,
            font: ?*?*IDWriteFont3,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFaceReference: *const fn (
            self: *const IDWriteFontFamily1,
            listIndex: u32,
            fontFaceReference: ?*?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFamily.MethodMixin(T);
            pub inline fn GetFontLocality(self: *const T, listIndex: u32) DWRITE_LOCALITY {
                return @as(*const IDWriteFontFamily1.VTable, @ptrCast(self.vtable)).GetFontLocality(@as(*const IDWriteFontFamily1, @ptrCast(self)), listIndex);
            }
            pub inline fn GetFont(self: *const T, listIndex: u32, font: ?*?*IDWriteFont3) HRESULT {
                return @as(*const IDWriteFontFamily1.VTable, @ptrCast(self.vtable)).GetFont(@as(*const IDWriteFontFamily1, @ptrCast(self)), listIndex, font);
            }
            pub inline fn GetFontFaceReference(self: *const T, listIndex: u32, fontFaceReference: ?*?*IDWriteFontFaceReference) HRESULT {
                return @as(*const IDWriteFontFamily1.VTable, @ptrCast(self.vtable)).GetFontFaceReference(@as(*const IDWriteFontFamily1, @ptrCast(self)), listIndex, fontFaceReference);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows10.0.10240'
const IID_IDWriteFontList1_Value = Guid.initString("da20d8ef-812a-4c43-9802-62ec4abd7ade");
pub const IID_IDWriteFontList1 = &IID_IDWriteFontList1_Value;
pub const IDWriteFontList1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontList.VTable,
        GetFontLocality: *const fn (
            self: *const IDWriteFontList1,
            listIndex: u32,
        ) callconv(std.os.windows.WINAPI) DWRITE_LOCALITY,

        GetFont: *const fn (
            self: *const IDWriteFontList1,
            listIndex: u32,
            font: ?*?*IDWriteFont3,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFaceReference: *const fn (
            self: *const IDWriteFontList1,
            listIndex: u32,
            fontFaceReference: ?*?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontList.MethodMixin(T);
            pub inline fn GetFontLocality(self: *const T, listIndex: u32) DWRITE_LOCALITY {
                return @as(*const IDWriteFontList1.VTable, @ptrCast(self.vtable)).GetFontLocality(@as(*const IDWriteFontList1, @ptrCast(self)), listIndex);
            }
            pub inline fn GetFont(self: *const T, listIndex: u32, font: ?*?*IDWriteFont3) HRESULT {
                return @as(*const IDWriteFontList1.VTable, @ptrCast(self.vtable)).GetFont(@as(*const IDWriteFontList1, @ptrCast(self)), listIndex, font);
            }
            pub inline fn GetFontFaceReference(self: *const T, listIndex: u32, fontFaceReference: ?*?*IDWriteFontFaceReference) HRESULT {
                return @as(*const IDWriteFontList1.VTable, @ptrCast(self.vtable)).GetFontFaceReference(@as(*const IDWriteFontList1, @ptrCast(self)), listIndex, fontFaceReference);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows10.0.10240'
const IID_IDWriteFontFaceReference_Value = Guid.initString("5e7fa7ca-dde3-424c-89f0-9fcd6fed58cd");
pub const IID_IDWriteFontFaceReference = &IID_IDWriteFontFaceReference_Value;
pub const IDWriteFontFaceReference = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        CreateFontFace: *const fn (
            self: *const IDWriteFontFaceReference,
            fontFace: ?*?*IDWriteFontFace3,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFaceWithSimulations: *const fn (
            self: *const IDWriteFontFaceReference,
            fontFaceSimulationFlags: DWRITE_FONT_SIMULATIONS,
            fontFace: ?*?*IDWriteFontFace3,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        Equals: *const fn (
            self: *const IDWriteFontFaceReference,
            fontFaceReference: ?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetFontFaceIndex: *const fn (
            self: *const IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) u32,

        GetSimulations: *const fn (
            self: *const IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_SIMULATIONS,

        GetFontFile: *const fn (
            self: *const IDWriteFontFaceReference,
            fontFile: ?*?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocalFileSize: *const fn (
            self: *const IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) u64,

        GetFileSize: *const fn (
            self: *const IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) u64,

        GetFileTime: *const fn (
            self: *const IDWriteFontFaceReference,
            lastWriteTime: ?*FILETIME,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocality: *const fn (
            self: *const IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) DWRITE_LOCALITY,

        EnqueueFontDownloadRequest: *const fn (
            self: *const IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        EnqueueCharacterDownloadRequest: *const fn (
            self: *const IDWriteFontFaceReference,
            characters: [*:0]const u16,
            characterCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        EnqueueGlyphDownloadRequest: *const fn (
            self: *const IDWriteFontFaceReference,
            glyphIndices: [*:0]const u16,
            glyphCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        EnqueueFileFragmentDownloadRequest: *const fn (
            self: *const IDWriteFontFaceReference,
            fileOffset: u64,
            fragmentSize: u64,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn CreateFontFace(self: *const T, fontFace: ?*?*IDWriteFontFace3) HRESULT {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).CreateFontFace(@as(*const IDWriteFontFaceReference, @ptrCast(self)), fontFace);
            }
            pub inline fn CreateFontFaceWithSimulations(self: *const T, fontFaceSimulationFlags: DWRITE_FONT_SIMULATIONS, fontFace: ?*?*IDWriteFontFace3) HRESULT {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).CreateFontFaceWithSimulations(@as(*const IDWriteFontFaceReference, @ptrCast(self)), fontFaceSimulationFlags, fontFace);
            }
            pub inline fn Equals(self: *const T, fontFaceReference: ?*IDWriteFontFaceReference) BOOL {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).Equals(@as(*const IDWriteFontFaceReference, @ptrCast(self)), fontFaceReference);
            }
            pub inline fn GetFontFaceIndex(self: *const T) u32 {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).GetFontFaceIndex(@as(*const IDWriteFontFaceReference, @ptrCast(self)));
            }
            pub inline fn GetSimulations(self: *const T) DWRITE_FONT_SIMULATIONS {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).GetSimulations(@as(*const IDWriteFontFaceReference, @ptrCast(self)));
            }
            pub inline fn GetFontFile(self: *const T, fontFile: ?*?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).GetFontFile(@as(*const IDWriteFontFaceReference, @ptrCast(self)), fontFile);
            }
            pub inline fn GetLocalFileSize(self: *const T) u64 {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).GetLocalFileSize(@as(*const IDWriteFontFaceReference, @ptrCast(self)));
            }
            pub inline fn GetFileSize(self: *const T) u64 {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).GetFileSize(@as(*const IDWriteFontFaceReference, @ptrCast(self)));
            }
            pub inline fn GetFileTime(self: *const T, lastWriteTime: ?*FILETIME) HRESULT {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).GetFileTime(@as(*const IDWriteFontFaceReference, @ptrCast(self)), lastWriteTime);
            }
            pub inline fn GetLocality(self: *const T) DWRITE_LOCALITY {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).GetLocality(@as(*const IDWriteFontFaceReference, @ptrCast(self)));
            }
            pub inline fn EnqueueFontDownloadRequest(self: *const T) HRESULT {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).EnqueueFontDownloadRequest(@as(*const IDWriteFontFaceReference, @ptrCast(self)));
            }
            pub inline fn EnqueueCharacterDownloadRequest(self: *const T, characters: [*:0]const u16, characterCount: u32) HRESULT {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).EnqueueCharacterDownloadRequest(@as(*const IDWriteFontFaceReference, @ptrCast(self)), characters, characterCount);
            }
            pub inline fn EnqueueGlyphDownloadRequest(self: *const T, glyphIndices: [*:0]const u16, glyphCount: u32) HRESULT {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).EnqueueGlyphDownloadRequest(@as(*const IDWriteFontFaceReference, @ptrCast(self)), glyphIndices, glyphCount);
            }
            pub inline fn EnqueueFileFragmentDownloadRequest(self: *const T, fileOffset: u64, fragmentSize: u64) HRESULT {
                return @as(*const IDWriteFontFaceReference.VTable, @ptrCast(self.vtable)).EnqueueFileFragmentDownloadRequest(@as(*const IDWriteFontFaceReference, @ptrCast(self)), fileOffset, fragmentSize);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows10.0.10240'
const IID_IDWriteFont3_Value = Guid.initString("29748ed6-8c9c-4a6a-be0b-d912e8538944");
pub const IID_IDWriteFont3 = &IID_IDWriteFont3_Value;
pub const IDWriteFont3 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFont2.VTable,
        CreateFontFace: *const fn (
            self: *const IDWriteFont3,
            fontFace: ?*?*IDWriteFontFace3,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        Equals: *const fn (
            self: *const IDWriteFont3,
            font: ?*IDWriteFont,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetFontFaceReference: *const fn (
            self: *const IDWriteFont3,
            fontFaceReference: ?*?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HasCharacter: *const fn (
            self: *const IDWriteFont3,
            unicodeValue: u32,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetLocality: *const fn (
            self: *const IDWriteFont3,
        ) callconv(std.os.windows.WINAPI) DWRITE_LOCALITY,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFont2.MethodMixin(T);
            pub inline fn CreateFontFace(self: *const T, fontFace: ?*?*IDWriteFontFace3) HRESULT {
                return @as(*const IDWriteFont3.VTable, @ptrCast(self.vtable)).CreateFontFace(@as(*const IDWriteFont3, @ptrCast(self)), fontFace);
            }
            pub inline fn Equals(self: *const T, font: ?*IDWriteFont) BOOL {
                return @as(*const IDWriteFont3.VTable, @ptrCast(self.vtable)).Equals(@as(*const IDWriteFont3, @ptrCast(self)), font);
            }
            pub inline fn GetFontFaceReference(self: *const T, fontFaceReference: ?*?*IDWriteFontFaceReference) HRESULT {
                return @as(*const IDWriteFont3.VTable, @ptrCast(self.vtable)).GetFontFaceReference(@as(*const IDWriteFont3, @ptrCast(self)), fontFaceReference);
            }
            pub inline fn HasCharacter(self: *const T, unicodeValue: u32) BOOL {
                return @as(*const IDWriteFont3.VTable, @ptrCast(self.vtable)).HasCharacter(@as(*const IDWriteFont3, @ptrCast(self)), unicodeValue);
            }
            pub inline fn GetLocality(self: *const T) DWRITE_LOCALITY {
                return @as(*const IDWriteFont3.VTable, @ptrCast(self.vtable)).GetLocality(@as(*const IDWriteFont3, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows10.0.10240'
const IID_IDWriteFontFace3_Value = Guid.initString("d37d7598-09be-4222-a236-2081341cc1f2");
pub const IID_IDWriteFontFace3 = &IID_IDWriteFontFace3_Value;
pub const IDWriteFontFace3 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFace2.VTable,
        GetFontFaceReference: *const fn (
            self: *const IDWriteFontFace3,
            fontFaceReference: ?*?*IDWriteFontFaceReference,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetPanose: *const fn (
            self: *const IDWriteFontFace3,
            panose: ?*DWRITE_PANOSE,
        ) callconv(std.os.windows.WINAPI) void,

        GetWeight: *const fn (
            self: *const IDWriteFontFace3,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_WEIGHT,

        GetStretch: *const fn (
            self: *const IDWriteFontFace3,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_STRETCH,

        GetStyle: *const fn (
            self: *const IDWriteFontFace3,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_STYLE,

        GetFamilyNames: *const fn (
            self: *const IDWriteFontFace3,
            names: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFaceNames: *const fn (
            self: *const IDWriteFontFace3,
            names: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetInformationalStrings: *const fn (
            self: *const IDWriteFontFace3,
            informationalStringID: DWRITE_INFORMATIONAL_STRING_ID,
            informationalStrings: ?*?*IDWriteLocalizedStrings,
            exists: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HasCharacter: *const fn (
            self: *const IDWriteFontFace3,
            unicodeValue: u32,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetRecommendedRenderingMode: *const fn (
            self: *const IDWriteFontFace3,
            fontEmSize: f32,
            dpiX: f32,
            dpiY: f32,
            transform: ?*const DWRITE_MATRIX,
            isSideways: BOOL,
            outlineThreshold: DWRITE_OUTLINE_THRESHOLD,
            measuringMode: DWRITE_MEASURING_MODE,
            renderingParams: ?*IDWriteRenderingParams,
            renderingMode: ?*DWRITE_RENDERING_MODE1,
            gridFitMode: ?*DWRITE_GRID_FIT_MODE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        IsCharacterLocal: *const fn (
            self: *const IDWriteFontFace3,
            unicodeValue: u32,
        ) callconv(std.os.windows.WINAPI) BOOL,

        IsGlyphLocal: *const fn (
            self: *const IDWriteFontFace3,
            glyphId: u16,
        ) callconv(std.os.windows.WINAPI) BOOL,

        AreCharactersLocal: *const fn (
            self: *const IDWriteFontFace3,
            characters: [*:0]const u16,
            characterCount: u32,
            enqueueIfNotLocal: BOOL,
            isLocal: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AreGlyphsLocal: *const fn (
            self: *const IDWriteFontFace3,
            glyphIndices: [*:0]const u16,
            glyphCount: u32,
            enqueueIfNotLocal: BOOL,
            isLocal: ?*BOOL,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFace2.MethodMixin(T);
            pub inline fn GetFontFaceReference(self: *const T, fontFaceReference: ?*?*IDWriteFontFaceReference) HRESULT {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetFontFaceReference(@as(*const IDWriteFontFace3, @ptrCast(self)), fontFaceReference);
            }
            pub inline fn GetPanose(self: *const T, panose: ?*DWRITE_PANOSE) void {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetPanose(@as(*const IDWriteFontFace3, @ptrCast(self)), panose);
            }
            pub inline fn GetWeight(self: *const T) DWRITE_FONT_WEIGHT {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetWeight(@as(*const IDWriteFontFace3, @ptrCast(self)));
            }
            pub inline fn GetStretch(self: *const T) DWRITE_FONT_STRETCH {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetStretch(@as(*const IDWriteFontFace3, @ptrCast(self)));
            }
            pub inline fn GetStyle(self: *const T) DWRITE_FONT_STYLE {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetStyle(@as(*const IDWriteFontFace3, @ptrCast(self)));
            }
            pub inline fn GetFamilyNames(self: *const T, names: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetFamilyNames(@as(*const IDWriteFontFace3, @ptrCast(self)), names);
            }
            pub inline fn GetFaceNames(self: *const T, names: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetFaceNames(@as(*const IDWriteFontFace3, @ptrCast(self)), names);
            }
            pub inline fn GetInformationalStrings(self: *const T, informationalStringID: DWRITE_INFORMATIONAL_STRING_ID, informationalStrings: ?*?*IDWriteLocalizedStrings, exists: ?*BOOL) HRESULT {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetInformationalStrings(@as(*const IDWriteFontFace3, @ptrCast(self)), informationalStringID, informationalStrings, exists);
            }
            pub inline fn HasCharacter(self: *const T, unicodeValue: u32) BOOL {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).HasCharacter(@as(*const IDWriteFontFace3, @ptrCast(self)), unicodeValue);
            }
            pub inline fn GetRecommendedRenderingMode(self: *const T, fontEmSize: f32, dpiX: f32, dpiY: f32, transform: ?*const DWRITE_MATRIX, isSideways: BOOL, outlineThreshold: DWRITE_OUTLINE_THRESHOLD, measuringMode: DWRITE_MEASURING_MODE, renderingParams: ?*IDWriteRenderingParams, renderingMode: ?*DWRITE_RENDERING_MODE1, gridFitMode: ?*DWRITE_GRID_FIT_MODE) HRESULT {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).GetRecommendedRenderingMode(@as(*const IDWriteFontFace3, @ptrCast(self)), fontEmSize, dpiX, dpiY, transform, isSideways, outlineThreshold, measuringMode, renderingParams, renderingMode, gridFitMode);
            }
            pub inline fn IsCharacterLocal(self: *const T, unicodeValue: u32) BOOL {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).IsCharacterLocal(@as(*const IDWriteFontFace3, @ptrCast(self)), unicodeValue);
            }
            pub inline fn IsGlyphLocal(self: *const T, glyphId: u16) BOOL {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).IsGlyphLocal(@as(*const IDWriteFontFace3, @ptrCast(self)), glyphId);
            }
            pub inline fn AreCharactersLocal(self: *const T, characters: [*:0]const u16, characterCount: u32, enqueueIfNotLocal: BOOL, isLocal: ?*BOOL) HRESULT {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).AreCharactersLocal(@as(*const IDWriteFontFace3, @ptrCast(self)), characters, characterCount, enqueueIfNotLocal, isLocal);
            }
            pub inline fn AreGlyphsLocal(self: *const T, glyphIndices: [*:0]const u16, glyphCount: u32, enqueueIfNotLocal: BOOL, isLocal: ?*BOOL) HRESULT {
                return @as(*const IDWriteFontFace3.VTable, @ptrCast(self.vtable)).AreGlyphsLocal(@as(*const IDWriteFontFace3, @ptrCast(self)), glyphIndices, glyphCount, enqueueIfNotLocal, isLocal);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteStringList_Value = Guid.initString("cfee3140-1157-47ca-8b85-31bfcf3f2d0e");
pub const IID_IDWriteStringList = &IID_IDWriteStringList_Value;
pub const IDWriteStringList = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetCount: *const fn (
            self: *const IDWriteStringList,
        ) callconv(std.os.windows.WINAPI) u32,

        GetLocaleNameLength: *const fn (
            self: *const IDWriteStringList,
            listIndex: u32,
            length: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocaleName: *const fn (
            self: *const IDWriteStringList,
            listIndex: u32,
            localeName: [*:0]u16,
            size: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetStringLength: *const fn (
            self: *const IDWriteStringList,
            listIndex: u32,
            length: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetString: *const fn (
            self: *const IDWriteStringList,
            listIndex: u32,
            stringBuffer: [*:0]u16,
            stringBufferSize: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetCount(self: *const T) u32 {
                return @as(*const IDWriteStringList.VTable, @ptrCast(self.vtable)).GetCount(@as(*const IDWriteStringList, @ptrCast(self)));
            }
            pub inline fn GetLocaleNameLength(self: *const T, listIndex: u32, length: ?*u32) HRESULT {
                return @as(*const IDWriteStringList.VTable, @ptrCast(self.vtable)).GetLocaleNameLength(@as(*const IDWriteStringList, @ptrCast(self)), listIndex, length);
            }
            pub inline fn GetLocaleName(self: *const T, listIndex: u32, localeName: [*:0]u16, size: u32) HRESULT {
                return @as(*const IDWriteStringList.VTable, @ptrCast(self.vtable)).GetLocaleName(@as(*const IDWriteStringList, @ptrCast(self)), listIndex, localeName, size);
            }
            pub inline fn GetStringLength(self: *const T, listIndex: u32, length: ?*u32) HRESULT {
                return @as(*const IDWriteStringList.VTable, @ptrCast(self.vtable)).GetStringLength(@as(*const IDWriteStringList, @ptrCast(self)), listIndex, length);
            }
            pub inline fn GetString(self: *const T, listIndex: u32, stringBuffer: [*:0]u16, stringBufferSize: u32) HRESULT {
                return @as(*const IDWriteStringList.VTable, @ptrCast(self.vtable)).GetString(@as(*const IDWriteStringList, @ptrCast(self)), listIndex, stringBuffer, stringBufferSize);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteFontDownloadListener_Value = Guid.initString("b06fe5b9-43ec-4393-881b-dbe4dc72fda7");
pub const IID_IDWriteFontDownloadListener = &IID_IDWriteFontDownloadListener_Value;
pub const IDWriteFontDownloadListener = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        DownloadCompleted: *const fn (
            self: *const IDWriteFontDownloadListener,
            downloadQueue: ?*IDWriteFontDownloadQueue,
            context: ?*IUnknown,
            downloadResult: HRESULT,
        ) callconv(std.os.windows.WINAPI) void,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn DownloadCompleted(self: *const T, downloadQueue: ?*IDWriteFontDownloadQueue, context: ?*IUnknown, downloadResult: HRESULT) void {
                return @as(*const IDWriteFontDownloadListener.VTable, @ptrCast(self.vtable)).DownloadCompleted(@as(*const IDWriteFontDownloadListener, @ptrCast(self)), downloadQueue, context, downloadResult);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteFontDownloadQueue_Value = Guid.initString("b71e6052-5aea-4fa3-832e-f60d431f7e91");
pub const IID_IDWriteFontDownloadQueue = &IID_IDWriteFontDownloadQueue_Value;
pub const IDWriteFontDownloadQueue = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        AddListener: *const fn (
            self: *const IDWriteFontDownloadQueue,
            listener: ?*IDWriteFontDownloadListener,
            token: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        RemoveListener: *const fn (
            self: *const IDWriteFontDownloadQueue,
            token: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        IsEmpty: *const fn (
            self: *const IDWriteFontDownloadQueue,
        ) callconv(std.os.windows.WINAPI) BOOL,

        BeginDownload: *const fn (
            self: *const IDWriteFontDownloadQueue,
            context: ?*IUnknown,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CancelDownload: *const fn (
            self: *const IDWriteFontDownloadQueue,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGenerationCount: *const fn (
            self: *const IDWriteFontDownloadQueue,
        ) callconv(std.os.windows.WINAPI) u64,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn AddListener(self: *const T, listener: ?*IDWriteFontDownloadListener, token: ?*u32) HRESULT {
                return @as(*const IDWriteFontDownloadQueue.VTable, @ptrCast(self.vtable)).AddListener(@as(*const IDWriteFontDownloadQueue, @ptrCast(self)), listener, token);
            }
            pub inline fn RemoveListener(self: *const T, token: u32) HRESULT {
                return @as(*const IDWriteFontDownloadQueue.VTable, @ptrCast(self.vtable)).RemoveListener(@as(*const IDWriteFontDownloadQueue, @ptrCast(self)), token);
            }
            pub inline fn IsEmpty(self: *const T) BOOL {
                return @as(*const IDWriteFontDownloadQueue.VTable, @ptrCast(self.vtable)).IsEmpty(@as(*const IDWriteFontDownloadQueue, @ptrCast(self)));
            }
            pub inline fn BeginDownload(self: *const T, context: ?*IUnknown) HRESULT {
                return @as(*const IDWriteFontDownloadQueue.VTable, @ptrCast(self.vtable)).BeginDownload(@as(*const IDWriteFontDownloadQueue, @ptrCast(self)), context);
            }
            pub inline fn CancelDownload(self: *const T) HRESULT {
                return @as(*const IDWriteFontDownloadQueue.VTable, @ptrCast(self.vtable)).CancelDownload(@as(*const IDWriteFontDownloadQueue, @ptrCast(self)));
            }
            pub inline fn GetGenerationCount(self: *const T) u64 {
                return @as(*const IDWriteFontDownloadQueue.VTable, @ptrCast(self.vtable)).GetGenerationCount(@as(*const IDWriteFontDownloadQueue, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteGdiInterop1_Value = Guid.initString("4556be70-3abd-4f70-90be-421780a6f515");
pub const IID_IDWriteGdiInterop1 = &IID_IDWriteGdiInterop1_Value;
pub const IDWriteGdiInterop1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteGdiInterop.VTable,
        CreateFontFromLOGFONT: *const fn (
            self: *const IDWriteGdiInterop1,
            logFont: ?*const LOGFONTW,
            fontCollection: ?*IDWriteFontCollection,
            font: ?*?*IDWriteFont,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontSignature: *const fn (
            self: *const IDWriteGdiInterop1,
            fontFace: ?*IDWriteFontFace,
            fontSignature: ?*FONTSIGNATURE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontSignature1: *const fn (
            self: *const IDWriteGdiInterop1,
            font: ?*IDWriteFont,
            fontSignature: ?*FONTSIGNATURE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMatchingFontsByLOGFONT: *const fn (
            self: *const IDWriteGdiInterop1,
            logFont: ?*const LOGFONTA,
            fontSet: ?*IDWriteFontSet,
            filteredSet: ?*?*IDWriteFontSet,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteGdiInterop.MethodMixin(T);
            pub inline fn CreateFontFromLOGFONT(self: *const T, logFont: ?*const LOGFONTW, fontCollection: ?*IDWriteFontCollection, font: ?*?*IDWriteFont) HRESULT {
                return @as(*const IDWriteGdiInterop1.VTable, @ptrCast(self.vtable)).CreateFontFromLOGFONT(@as(*const IDWriteGdiInterop1, @ptrCast(self)), logFont, fontCollection, font);
            }
            pub inline fn GetFontSignature(self: *const T, fontFace: ?*IDWriteFontFace, fontSignature: ?*FONTSIGNATURE) HRESULT {
                return @as(*const IDWriteGdiInterop1.VTable, @ptrCast(self.vtable)).GetFontSignature(@as(*const IDWriteGdiInterop1, @ptrCast(self)), fontFace, fontSignature);
            }
            pub inline fn GetFontSignature1(self: *const T, font: ?*IDWriteFont, fontSignature: ?*FONTSIGNATURE) HRESULT {
                return @as(*const IDWriteGdiInterop1.VTable, @ptrCast(self.vtable)).GetFontSignature(@as(*const IDWriteGdiInterop1, @ptrCast(self)), font, fontSignature);
            }
            pub inline fn GetMatchingFontsByLOGFONT(self: *const T, logFont: ?*const LOGFONTA, fontSet: ?*IDWriteFontSet, filteredSet: ?*?*IDWriteFontSet) HRESULT {
                return @as(*const IDWriteGdiInterop1.VTable, @ptrCast(self.vtable)).GetMatchingFontsByLOGFONT(@as(*const IDWriteGdiInterop1, @ptrCast(self)), logFont, fontSet, filteredSet);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_LINE_METRICS1 = extern struct {
    Base: DWRITE_LINE_METRICS,
    leadingBefore: f32,
    leadingAfter: f32,
};

pub const DWRITE_FONT_LINE_GAP_USAGE = enum(i32) {
    DEFAULT = 0,
    DISABLED = 1,
    ENABLED = 2,
};
pub const DWRITE_FONT_LINE_GAP_USAGE_DEFAULT = DWRITE_FONT_LINE_GAP_USAGE.DEFAULT;
pub const DWRITE_FONT_LINE_GAP_USAGE_DISABLED = DWRITE_FONT_LINE_GAP_USAGE.DISABLED;
pub const DWRITE_FONT_LINE_GAP_USAGE_ENABLED = DWRITE_FONT_LINE_GAP_USAGE.ENABLED;

pub const DWRITE_LINE_SPACING = extern struct {
    method: DWRITE_LINE_SPACING_METHOD,
    height: f32,
    baseline: f32,
    leadingBefore: f32,
    fontLineGapUsage: DWRITE_FONT_LINE_GAP_USAGE,
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteTextFormat2_Value = Guid.initString("f67e0edd-9e3d-4ecc-8c32-4183253dfe70");
pub const IID_IDWriteTextFormat2 = &IID_IDWriteTextFormat2_Value;
pub const IDWriteTextFormat2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextFormat1.VTable,
        SetLineSpacing: *const fn (
            self: *const IDWriteTextFormat2,
            lineSpacingOptions: ?*const DWRITE_LINE_SPACING,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLineSpacing: *const fn (
            self: *const IDWriteTextFormat2,
            lineSpacingOptions: ?*DWRITE_LINE_SPACING,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextFormat1.MethodMixin(T);
            pub inline fn SetLineSpacing(self: *const T, lineSpacingOptions: ?*const DWRITE_LINE_SPACING) HRESULT {
                return @as(*const IDWriteTextFormat2.VTable, @ptrCast(self.vtable)).SetLineSpacing(@as(*const IDWriteTextFormat2, @ptrCast(self)), lineSpacingOptions);
            }
            pub inline fn GetLineSpacing(self: *const T, lineSpacingOptions: ?*DWRITE_LINE_SPACING) HRESULT {
                return @as(*const IDWriteTextFormat2.VTable, @ptrCast(self.vtable)).GetLineSpacing(@as(*const IDWriteTextFormat2, @ptrCast(self)), lineSpacingOptions);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

// TODO: this type is limited to platform 'windows8.1'
const IID_IDWriteTextLayout3_Value = Guid.initString("07ddcd52-020e-4de8-ac33-6c953d83f92d");
pub const IID_IDWriteTextLayout3 = &IID_IDWriteTextLayout3_Value;
pub const IDWriteTextLayout3 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextLayout2.VTable,
        InvalidateLayout: *const fn (
            self: *const IDWriteTextLayout3,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        SetLineSpacing: *const fn (
            self: *const IDWriteTextLayout3,
            lineSpacingOptions: ?*const DWRITE_LINE_SPACING,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLineSpacing: *const fn (
            self: *const IDWriteTextLayout3,
            lineSpacingOptions: ?*DWRITE_LINE_SPACING,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLineMetrics: *const fn (
            self: *const IDWriteTextLayout3,
            lineMetrics: ?[*]DWRITE_LINE_METRICS1,
            maxLineCount: u32,
            actualLineCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextLayout2.MethodMixin(T);
            pub inline fn InvalidateLayout(self: *const T) HRESULT {
                return @as(*const IDWriteTextLayout3.VTable, @ptrCast(self.vtable)).InvalidateLayout(@as(*const IDWriteTextLayout3, @ptrCast(self)));
            }
            pub inline fn SetLineSpacing(self: *const T, lineSpacingOptions: ?*const DWRITE_LINE_SPACING) HRESULT {
                return @as(*const IDWriteTextLayout3.VTable, @ptrCast(self.vtable)).SetLineSpacing(@as(*const IDWriteTextLayout3, @ptrCast(self)), lineSpacingOptions);
            }
            pub inline fn GetLineSpacing(self: *const T, lineSpacingOptions: ?*DWRITE_LINE_SPACING) HRESULT {
                return @as(*const IDWriteTextLayout3.VTable, @ptrCast(self.vtable)).GetLineSpacing(@as(*const IDWriteTextLayout3, @ptrCast(self)), lineSpacingOptions);
            }
            pub inline fn GetLineMetrics(self: *const T, lineMetrics: ?[*]DWRITE_LINE_METRICS1, maxLineCount: u32, actualLineCount: ?*u32) HRESULT {
                return @as(*const IDWriteTextLayout3.VTable, @ptrCast(self.vtable)).GetLineMetrics(@as(*const IDWriteTextLayout3, @ptrCast(self)), lineMetrics, maxLineCount, actualLineCount);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_COLOR_GLYPH_RUN1 = extern struct {
    Base: DWRITE_COLOR_GLYPH_RUN,
    glyphImageFormat: DWRITE_GLYPH_IMAGE_FORMATS,
    measuringMode: DWRITE_MEASURING_MODE,
};

pub const DWRITE_GLYPH_IMAGE_DATA = extern struct {
    imageData: ?*const anyopaque,
    imageDataSize: u32,
    uniqueDataId: u32,
    pixelsPerEm: u32,
    pixelSize: D2D_SIZE_U,
    horizontalLeftOrigin: POINT,
    horizontalRightOrigin: POINT,
    verticalTopOrigin: POINT,
    verticalBottomOrigin: POINT,
};

const IID_IDWriteColorGlyphRunEnumerator1_Value = Guid.initString("7c5f86da-c7a1-4f05-b8e1-55a179fe5a35");
pub const IID_IDWriteColorGlyphRunEnumerator1 = &IID_IDWriteColorGlyphRunEnumerator1_Value;
pub const IDWriteColorGlyphRunEnumerator1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteColorGlyphRunEnumerator.VTable,
        GetCurrentRun: *const fn (
            self: *const IDWriteColorGlyphRunEnumerator1,
            colorGlyphRun: ?*const ?*DWRITE_COLOR_GLYPH_RUN1,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteColorGlyphRunEnumerator.MethodMixin(T);
            pub inline fn GetCurrentRun(self: *const T, colorGlyphRun: ?*const ?*DWRITE_COLOR_GLYPH_RUN1) HRESULT {
                return @as(*const IDWriteColorGlyphRunEnumerator1.VTable, @ptrCast(self.vtable)).GetCurrentRun(@as(*const IDWriteColorGlyphRunEnumerator1, @ptrCast(self)), colorGlyphRun);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontFace4_Value = Guid.initString("27f2a904-4eb8-441d-9678-0563f53e3e2f");
pub const IID_IDWriteFontFace4 = &IID_IDWriteFontFace4_Value;
pub const IDWriteFontFace4 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFace3.VTable,
        GetGlyphImageFormats: *const fn (
            self: *const IDWriteFontFace4,
            glyphId: u16,
            pixelsPerEmFirst: u32,
            pixelsPerEmLast: u32,
            glyphImageFormats: ?*DWRITE_GLYPH_IMAGE_FORMATS,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetGlyphImageFormats1: *const fn (
            self: *const IDWriteFontFace4,
        ) callconv(std.os.windows.WINAPI) DWRITE_GLYPH_IMAGE_FORMATS,

        GetGlyphImageData: *const fn (
            self: *const IDWriteFontFace4,
            glyphId: u16,
            pixelsPerEm: u32,
            glyphImageFormat: DWRITE_GLYPH_IMAGE_FORMATS,
            glyphData: ?*DWRITE_GLYPH_IMAGE_DATA,
            glyphDataContext: ?*?*anyopaque,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        ReleaseGlyphImageData: *const fn (
            self: *const IDWriteFontFace4,
            glyphDataContext: ?*anyopaque,
        ) callconv(std.os.windows.WINAPI) void,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFace3.MethodMixin(T);
            pub inline fn GetGlyphImageFormats(self: *const T, glyphId: u16, pixelsPerEmFirst: u32, pixelsPerEmLast: u32, glyphImageFormats: ?*DWRITE_GLYPH_IMAGE_FORMATS) HRESULT {
                return @as(*const IDWriteFontFace4.VTable, @ptrCast(self.vtable)).GetGlyphImageFormats(@as(*const IDWriteFontFace4, @ptrCast(self)), glyphId, pixelsPerEmFirst, pixelsPerEmLast, glyphImageFormats);
            }
            pub inline fn GetGlyphImageFormats1(self: *const T) DWRITE_GLYPH_IMAGE_FORMATS {
                return @as(*const IDWriteFontFace4.VTable, @ptrCast(self.vtable)).GetGlyphImageFormats(@as(*const IDWriteFontFace4, @ptrCast(self)));
            }
            pub inline fn GetGlyphImageData(self: *const T, glyphId: u16, pixelsPerEm: u32, glyphImageFormat: DWRITE_GLYPH_IMAGE_FORMATS, glyphData: ?*DWRITE_GLYPH_IMAGE_DATA, glyphDataContext: ?*?*anyopaque) HRESULT {
                return @as(*const IDWriteFontFace4.VTable, @ptrCast(self.vtable)).GetGlyphImageData(@as(*const IDWriteFontFace4, @ptrCast(self)), glyphId, pixelsPerEm, glyphImageFormat, glyphData, glyphDataContext);
            }
            pub inline fn ReleaseGlyphImageData(self: *const T, glyphDataContext: ?*anyopaque) void {
                return @as(*const IDWriteFontFace4.VTable, @ptrCast(self.vtable)).ReleaseGlyphImageData(@as(*const IDWriteFontFace4, @ptrCast(self)), glyphDataContext);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFactory4_Value = Guid.initString("4b0b5bd3-0797-4549-8ac5-fe915cc53856");
pub const IID_IDWriteFactory4 = &IID_IDWriteFactory4_Value;
pub const IDWriteFactory4 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFactory3.VTable,
        TranslateColorGlyphRun: *const fn (
            self: *const IDWriteFactory4,
            baselineOrigin: D2D_POINT_2F,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            glyphRunDescription: ?*const DWRITE_GLYPH_RUN_DESCRIPTION,
            desiredGlyphImageFormats: DWRITE_GLYPH_IMAGE_FORMATS,
            measuringMode: DWRITE_MEASURING_MODE,
            worldAndDpiTransform: ?*const DWRITE_MATRIX,
            colorPaletteIndex: u32,
            colorLayers: ?*?*IDWriteColorGlyphRunEnumerator1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        ComputeGlyphOrigins: *const fn (
            self: *const IDWriteFactory4,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            baselineOrigin: D2D_POINT_2F,
            glyphOrigins: ?*D2D_POINT_2F,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        ComputeGlyphOrigins1: *const fn (
            self: *const IDWriteFactory4,
            glyphRun: ?*const DWRITE_GLYPH_RUN,
            measuringMode: DWRITE_MEASURING_MODE,
            baselineOrigin: D2D_POINT_2F,
            worldAndDpiTransform: ?*const DWRITE_MATRIX,
            glyphOrigins: ?*D2D_POINT_2F,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFactory3.MethodMixin(T);
            pub inline fn TranslateColorGlyphRun(self: *const T, baselineOrigin: D2D_POINT_2F, glyphRun: ?*const DWRITE_GLYPH_RUN, glyphRunDescription: ?*const DWRITE_GLYPH_RUN_DESCRIPTION, desiredGlyphImageFormats: DWRITE_GLYPH_IMAGE_FORMATS, measuringMode: DWRITE_MEASURING_MODE, worldAndDpiTransform: ?*const DWRITE_MATRIX, colorPaletteIndex: u32, colorLayers: ?*?*IDWriteColorGlyphRunEnumerator1) HRESULT {
                return @as(*const IDWriteFactory4.VTable, @ptrCast(self.vtable)).TranslateColorGlyphRun(@as(*const IDWriteFactory4, @ptrCast(self)), baselineOrigin, glyphRun, glyphRunDescription, desiredGlyphImageFormats, measuringMode, worldAndDpiTransform, colorPaletteIndex, colorLayers);
            }
            pub inline fn ComputeGlyphOrigins(self: *const T, glyphRun: ?*const DWRITE_GLYPH_RUN, baselineOrigin: D2D_POINT_2F, glyphOrigins: ?*D2D_POINT_2F) HRESULT {
                return @as(*const IDWriteFactory4.VTable, @ptrCast(self.vtable)).ComputeGlyphOrigins(@as(*const IDWriteFactory4, @ptrCast(self)), glyphRun, baselineOrigin, glyphOrigins);
            }
            pub inline fn ComputeGlyphOrigins1(self: *const T, glyphRun: ?*const DWRITE_GLYPH_RUN, measuringMode: DWRITE_MEASURING_MODE, baselineOrigin: D2D_POINT_2F, worldAndDpiTransform: ?*const DWRITE_MATRIX, glyphOrigins: ?*D2D_POINT_2F) HRESULT {
                return @as(*const IDWriteFactory4.VTable, @ptrCast(self.vtable)).ComputeGlyphOrigins(@as(*const IDWriteFactory4, @ptrCast(self)), glyphRun, measuringMode, baselineOrigin, worldAndDpiTransform, glyphOrigins);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontSetBuilder1_Value = Guid.initString("3ff7715f-3cdc-4dc6-9b72-ec5621dccafd");
pub const IID_IDWriteFontSetBuilder1 = &IID_IDWriteFontSetBuilder1_Value;
pub const IDWriteFontSetBuilder1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontSetBuilder.VTable,
        AddFontFile: *const fn (
            self: *const IDWriteFontSetBuilder1,
            fontFile: ?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontSetBuilder.MethodMixin(T);
            pub inline fn AddFontFile(self: *const T, fontFile: ?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteFontSetBuilder1.VTable, @ptrCast(self.vtable)).AddFontFile(@as(*const IDWriteFontSetBuilder1, @ptrCast(self)), fontFile);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteAsyncResult_Value = Guid.initString("ce25f8fd-863b-4d13-9651-c1f88dc73fe2");
pub const IID_IDWriteAsyncResult = &IID_IDWriteAsyncResult_Value;
pub const IDWriteAsyncResult = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetWaitHandle: *const fn (
            self: *const IDWriteAsyncResult,
        ) callconv(std.os.windows.WINAPI) ?HANDLE,

        GetResult: *const fn (
            self: *const IDWriteAsyncResult,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetWaitHandle(self: *const T) ?HANDLE {
                return @as(*const IDWriteAsyncResult.VTable, @ptrCast(self.vtable)).GetWaitHandle(@as(*const IDWriteAsyncResult, @ptrCast(self)));
            }
            pub inline fn GetResult(self: *const T) HRESULT {
                return @as(*const IDWriteAsyncResult.VTable, @ptrCast(self.vtable)).GetResult(@as(*const IDWriteAsyncResult, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_FILE_FRAGMENT = extern struct {
    fileOffset: u64,
    fragmentSize: u64,
};

const IID_IDWriteRemoteFontFileStream_Value = Guid.initString("4db3757a-2c72-4ed9-b2b6-1ababe1aff9c");
pub const IID_IDWriteRemoteFontFileStream = &IID_IDWriteRemoteFontFileStream_Value;
pub const IDWriteRemoteFontFileStream = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFileStream.VTable,
        GetLocalFileSize: *const fn (
            self: *const IDWriteRemoteFontFileStream,
            localFileSize: ?*u64,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFileFragmentLocality: *const fn (
            self: *const IDWriteRemoteFontFileStream,
            fileOffset: u64,
            fragmentSize: u64,
            isLocal: ?*BOOL,
            partialSize: ?*u64,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocality: *const fn (
            self: *const IDWriteRemoteFontFileStream,
        ) callconv(std.os.windows.WINAPI) DWRITE_LOCALITY,

        BeginDownload: *const fn (
            self: *const IDWriteRemoteFontFileStream,
            downloadOperationID: ?*const Guid,
            fileFragments: [*]const DWRITE_FILE_FRAGMENT,
            fragmentCount: u32,
            asyncResult: ?*?*IDWriteAsyncResult,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFileStream.MethodMixin(T);
            pub inline fn GetLocalFileSize(self: *const T, localFileSize: ?*u64) HRESULT {
                return @as(*const IDWriteRemoteFontFileStream.VTable, @ptrCast(self.vtable)).GetLocalFileSize(@as(*const IDWriteRemoteFontFileStream, @ptrCast(self)), localFileSize);
            }
            pub inline fn GetFileFragmentLocality(self: *const T, fileOffset: u64, fragmentSize: u64, isLocal: ?*BOOL, partialSize: ?*u64) HRESULT {
                return @as(*const IDWriteRemoteFontFileStream.VTable, @ptrCast(self.vtable)).GetFileFragmentLocality(@as(*const IDWriteRemoteFontFileStream, @ptrCast(self)), fileOffset, fragmentSize, isLocal, partialSize);
            }
            pub inline fn GetLocality(self: *const T) DWRITE_LOCALITY {
                return @as(*const IDWriteRemoteFontFileStream.VTable, @ptrCast(self.vtable)).GetLocality(@as(*const IDWriteRemoteFontFileStream, @ptrCast(self)));
            }
            pub inline fn BeginDownload(self: *const T, downloadOperationID: ?*const Guid, fileFragments: [*]const DWRITE_FILE_FRAGMENT, fragmentCount: u32, asyncResult: ?*?*IDWriteAsyncResult) HRESULT {
                return @as(*const IDWriteRemoteFontFileStream.VTable, @ptrCast(self.vtable)).BeginDownload(@as(*const IDWriteRemoteFontFileStream, @ptrCast(self)), downloadOperationID, fileFragments, fragmentCount, asyncResult);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_CONTAINER_TYPE = enum(i32) {
    UNKNOWN = 0,
    WOFF = 1,
    WOFF2 = 2,
};
pub const DWRITE_CONTAINER_TYPE_UNKNOWN = DWRITE_CONTAINER_TYPE.UNKNOWN;
pub const DWRITE_CONTAINER_TYPE_WOFF = DWRITE_CONTAINER_TYPE.WOFF;
pub const DWRITE_CONTAINER_TYPE_WOFF2 = DWRITE_CONTAINER_TYPE.WOFF2;

const IID_IDWriteRemoteFontFileLoader_Value = Guid.initString("68648c83-6ede-46c0-ab46-20083a887fde");
pub const IID_IDWriteRemoteFontFileLoader = &IID_IDWriteRemoteFontFileLoader_Value;
pub const IDWriteRemoteFontFileLoader = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFileLoader.VTable,
        CreateRemoteStreamFromKey: *const fn (
            self: *const IDWriteRemoteFontFileLoader,
            // TODO: what to do with BytesParamIndex 1?
            fontFileReferenceKey: ?*const anyopaque,
            fontFileReferenceKeySize: u32,
            fontFileStream: ?*?*IDWriteRemoteFontFileStream,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetLocalityFromKey: *const fn (
            self: *const IDWriteRemoteFontFileLoader,
            // TODO: what to do with BytesParamIndex 1?
            fontFileReferenceKey: ?*const anyopaque,
            fontFileReferenceKeySize: u32,
            locality: ?*DWRITE_LOCALITY,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFileReferenceFromUrl: *const fn (
            self: *const IDWriteRemoteFontFileLoader,
            factory: ?*IDWriteFactory,
            baseUrl: ?[*:0]const u16,
            fontFileUrl: ?[*:0]const u16,
            fontFile: ?*?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFileLoader.MethodMixin(T);
            pub inline fn CreateRemoteStreamFromKey(self: *const T, fontFileReferenceKey: ?*const anyopaque, fontFileReferenceKeySize: u32, fontFileStream: ?*?*IDWriteRemoteFontFileStream) HRESULT {
                return @as(*const IDWriteRemoteFontFileLoader.VTable, @ptrCast(self.vtable)).CreateRemoteStreamFromKey(@as(*const IDWriteRemoteFontFileLoader, @ptrCast(self)), fontFileReferenceKey, fontFileReferenceKeySize, fontFileStream);
            }
            pub inline fn GetLocalityFromKey(self: *const T, fontFileReferenceKey: ?*const anyopaque, fontFileReferenceKeySize: u32, locality: ?*DWRITE_LOCALITY) HRESULT {
                return @as(*const IDWriteRemoteFontFileLoader.VTable, @ptrCast(self.vtable)).GetLocalityFromKey(@as(*const IDWriteRemoteFontFileLoader, @ptrCast(self)), fontFileReferenceKey, fontFileReferenceKeySize, locality);
            }
            pub inline fn CreateFontFileReferenceFromUrl(self: *const T, factory: ?*IDWriteFactory, baseUrl: ?[*:0]const u16, fontFileUrl: ?[*:0]const u16, fontFile: ?*?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteRemoteFontFileLoader.VTable, @ptrCast(self.vtable)).CreateFontFileReferenceFromUrl(@as(*const IDWriteRemoteFontFileLoader, @ptrCast(self)), factory, baseUrl, fontFileUrl, fontFile);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteInMemoryFontFileLoader_Value = Guid.initString("dc102f47-a12d-4b1c-822d-9e117e33043f");
pub const IID_IDWriteInMemoryFontFileLoader = &IID_IDWriteInMemoryFontFileLoader_Value;
pub const IDWriteInMemoryFontFileLoader = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFileLoader.VTable,
        CreateInMemoryFontFileReference: *const fn (
            self: *const IDWriteInMemoryFontFileLoader,
            factory: ?*IDWriteFactory,
            // TODO: what to do with BytesParamIndex 2?
            fontData: ?*const anyopaque,
            fontDataSize: u32,
            ownerObject: ?*IUnknown,
            fontFile: ?*?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFileCount: *const fn (
            self: *const IDWriteInMemoryFontFileLoader,
        ) callconv(std.os.windows.WINAPI) u32,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFileLoader.MethodMixin(T);
            pub inline fn CreateInMemoryFontFileReference(self: *const T, factory: ?*IDWriteFactory, fontData: ?*const anyopaque, fontDataSize: u32, ownerObject: ?*IUnknown, fontFile: ?*?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteInMemoryFontFileLoader.VTable, @ptrCast(self.vtable)).CreateInMemoryFontFileReference(@as(*const IDWriteInMemoryFontFileLoader, @ptrCast(self)), factory, fontData, fontDataSize, ownerObject, fontFile);
            }
            pub inline fn GetFileCount(self: *const T) u32 {
                return @as(*const IDWriteInMemoryFontFileLoader.VTable, @ptrCast(self.vtable)).GetFileCount(@as(*const IDWriteInMemoryFontFileLoader, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFactory5_Value = Guid.initString("958db99a-be2a-4f09-af7d-65189803d1d3");
pub const IID_IDWriteFactory5 = &IID_IDWriteFactory5_Value;
pub const IDWriteFactory5 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFactory4.VTable,
        CreateFontSetBuilder: *const fn (
            self: *const IDWriteFactory5,
            fontSetBuilder: ?*?*IDWriteFontSetBuilder1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateInMemoryFontFileLoader: *const fn (
            self: *const IDWriteFactory5,
            newLoader: ?*?*IDWriteInMemoryFontFileLoader,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateHttpFontFileLoader: *const fn (
            self: *const IDWriteFactory5,
            referrerUrl: ?[*:0]const u16,
            extraHeaders: ?[*:0]const u16,
            newLoader: ?*?*IDWriteRemoteFontFileLoader,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AnalyzeContainerType: *const fn (
            self: *const IDWriteFactory5,
            // TODO: what to do with BytesParamIndex 1?
            fileData: ?*const anyopaque,
            fileDataSize: u32,
        ) callconv(std.os.windows.WINAPI) DWRITE_CONTAINER_TYPE,

        UnpackFontFile: *const fn (
            self: *const IDWriteFactory5,
            containerType: DWRITE_CONTAINER_TYPE,
            // TODO: what to do with BytesParamIndex 2?
            fileData: ?*const anyopaque,
            fileDataSize: u32,
            unpackedFontStream: ?*?*IDWriteFontFileStream,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFactory4.MethodMixin(T);
            pub inline fn CreateFontSetBuilder(self: *const T, fontSetBuilder: ?*?*IDWriteFontSetBuilder1) HRESULT {
                return @as(*const IDWriteFactory5.VTable, @ptrCast(self.vtable)).CreateFontSetBuilder(@as(*const IDWriteFactory5, @ptrCast(self)), fontSetBuilder);
            }
            pub inline fn CreateInMemoryFontFileLoader(self: *const T, newLoader: ?*?*IDWriteInMemoryFontFileLoader) HRESULT {
                return @as(*const IDWriteFactory5.VTable, @ptrCast(self.vtable)).CreateInMemoryFontFileLoader(@as(*const IDWriteFactory5, @ptrCast(self)), newLoader);
            }
            pub inline fn CreateHttpFontFileLoader(self: *const T, referrerUrl: ?[*:0]const u16, extraHeaders: ?[*:0]const u16, newLoader: ?*?*IDWriteRemoteFontFileLoader) HRESULT {
                return @as(*const IDWriteFactory5.VTable, @ptrCast(self.vtable)).CreateHttpFontFileLoader(@as(*const IDWriteFactory5, @ptrCast(self)), referrerUrl, extraHeaders, newLoader);
            }
            pub inline fn AnalyzeContainerType(self: *const T, fileData: ?*const anyopaque, fileDataSize: u32) DWRITE_CONTAINER_TYPE {
                return @as(*const IDWriteFactory5.VTable, @ptrCast(self.vtable)).AnalyzeContainerType(@as(*const IDWriteFactory5, @ptrCast(self)), fileData, fileDataSize);
            }
            pub inline fn UnpackFontFile(self: *const T, containerType: DWRITE_CONTAINER_TYPE, fileData: ?*const anyopaque, fileDataSize: u32, unpackedFontStream: ?*?*IDWriteFontFileStream) HRESULT {
                return @as(*const IDWriteFactory5.VTable, @ptrCast(self.vtable)).UnpackFontFile(@as(*const IDWriteFactory5, @ptrCast(self)), containerType, fileData, fileDataSize, unpackedFontStream);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_FONT_AXIS_VALUE = extern struct {
    axisTag: DWRITE_FONT_AXIS_TAG,
    value: f32,
};

pub const DWRITE_FONT_AXIS_RANGE = extern struct {
    axisTag: DWRITE_FONT_AXIS_TAG,
    minValue: f32,
    maxValue: f32,
};

pub const DWRITE_FONT_FAMILY_MODEL = enum(i32) {
    TYPOGRAPHIC = 0,
    WEIGHT_STRETCH_STYLE = 1,
};
pub const DWRITE_FONT_FAMILY_MODEL_TYPOGRAPHIC = DWRITE_FONT_FAMILY_MODEL.TYPOGRAPHIC;
pub const DWRITE_FONT_FAMILY_MODEL_WEIGHT_STRETCH_STYLE = DWRITE_FONT_FAMILY_MODEL.WEIGHT_STRETCH_STYLE;

pub const DWRITE_AUTOMATIC_FONT_AXES = enum(u32) {
    NONE = 0,
    OPTICAL_SIZE = 1,
    _,
    pub fn initFlags(o: struct {
        NONE: u1 = 0,
        OPTICAL_SIZE: u1 = 0,
    }) DWRITE_AUTOMATIC_FONT_AXES {
        return @as(DWRITE_AUTOMATIC_FONT_AXES, @enumFromInt((if (o.NONE == 1) @intFromEnum(DWRITE_AUTOMATIC_FONT_AXES.NONE) else 0) | (if (o.OPTICAL_SIZE == 1) @intFromEnum(DWRITE_AUTOMATIC_FONT_AXES.OPTICAL_SIZE) else 0)));
    }
};
pub const DWRITE_AUTOMATIC_FONT_AXES_NONE = DWRITE_AUTOMATIC_FONT_AXES.NONE;
pub const DWRITE_AUTOMATIC_FONT_AXES_OPTICAL_SIZE = DWRITE_AUTOMATIC_FONT_AXES.OPTICAL_SIZE;

pub const DWRITE_FONT_AXIS_ATTRIBUTES = enum(u32) {
    NONE = 0,
    VARIABLE = 1,
    HIDDEN = 2,
    _,
    pub fn initFlags(o: struct {
        NONE: u1 = 0,
        VARIABLE: u1 = 0,
        HIDDEN: u1 = 0,
    }) DWRITE_FONT_AXIS_ATTRIBUTES {
        return @as(DWRITE_FONT_AXIS_ATTRIBUTES, @enumFromInt((if (o.NONE == 1) @intFromEnum(DWRITE_FONT_AXIS_ATTRIBUTES.NONE) else 0) | (if (o.VARIABLE == 1) @intFromEnum(DWRITE_FONT_AXIS_ATTRIBUTES.VARIABLE) else 0) | (if (o.HIDDEN == 1) @intFromEnum(DWRITE_FONT_AXIS_ATTRIBUTES.HIDDEN) else 0)));
    }
};
pub const DWRITE_FONT_AXIS_ATTRIBUTES_NONE = DWRITE_FONT_AXIS_ATTRIBUTES.NONE;
pub const DWRITE_FONT_AXIS_ATTRIBUTES_VARIABLE = DWRITE_FONT_AXIS_ATTRIBUTES.VARIABLE;
pub const DWRITE_FONT_AXIS_ATTRIBUTES_HIDDEN = DWRITE_FONT_AXIS_ATTRIBUTES.HIDDEN;

const IID_IDWriteFactory6_Value = Guid.initString("f3744d80-21f7-42eb-b35d-995bc72fc223");
pub const IID_IDWriteFactory6 = &IID_IDWriteFactory6_Value;
pub const IDWriteFactory6 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFactory5.VTable,
        CreateFontFaceReference: *const fn (
            self: *const IDWriteFactory6,
            fontFile: ?*IDWriteFontFile,
            faceIndex: u32,
            fontSimulations: DWRITE_FONT_SIMULATIONS,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            fontFaceReference: ?*?*IDWriteFontFaceReference1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontResource: *const fn (
            self: *const IDWriteFactory6,
            fontFile: ?*IDWriteFontFile,
            faceIndex: u32,
            fontResource: ?*?*IDWriteFontResource,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetSystemFontSet: *const fn (
            self: *const IDWriteFactory6,
            includeDownloadableFonts: BOOL,
            fontSet: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetSystemFontCollection: *const fn (
            self: *const IDWriteFactory6,
            includeDownloadableFonts: BOOL,
            fontFamilyModel: DWRITE_FONT_FAMILY_MODEL,
            fontCollection: ?*?*IDWriteFontCollection2,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontCollectionFromFontSet: *const fn (
            self: *const IDWriteFactory6,
            fontSet: ?*IDWriteFontSet,
            fontFamilyModel: DWRITE_FONT_FAMILY_MODEL,
            fontCollection: ?*?*IDWriteFontCollection2,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontSetBuilder: *const fn (
            self: *const IDWriteFactory6,
            fontSetBuilder: ?*?*IDWriteFontSetBuilder2,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateTextFormat: *const fn (
            self: *const IDWriteFactory6,
            fontFamilyName: ?[*:0]const u16,
            fontCollection: ?*IDWriteFontCollection,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            fontSize: f32,
            localeName: ?[*:0]const u16,
            textFormat: ?*?*IDWriteTextFormat3,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFactory5.MethodMixin(T);
            pub inline fn CreateFontFaceReference(self: *const T, fontFile: ?*IDWriteFontFile, faceIndex: u32, fontSimulations: DWRITE_FONT_SIMULATIONS, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, fontFaceReference: ?*?*IDWriteFontFaceReference1) HRESULT {
                return @as(*const IDWriteFactory6.VTable, @ptrCast(self.vtable)).CreateFontFaceReference(@as(*const IDWriteFactory6, @ptrCast(self)), fontFile, faceIndex, fontSimulations, fontAxisValues, fontAxisValueCount, fontFaceReference);
            }
            pub inline fn CreateFontResource(self: *const T, fontFile: ?*IDWriteFontFile, faceIndex: u32, fontResource: ?*?*IDWriteFontResource) HRESULT {
                return @as(*const IDWriteFactory6.VTable, @ptrCast(self.vtable)).CreateFontResource(@as(*const IDWriteFactory6, @ptrCast(self)), fontFile, faceIndex, fontResource);
            }
            pub inline fn GetSystemFontSet(self: *const T, includeDownloadableFonts: BOOL, fontSet: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFactory6.VTable, @ptrCast(self.vtable)).GetSystemFontSet(@as(*const IDWriteFactory6, @ptrCast(self)), includeDownloadableFonts, fontSet);
            }
            pub inline fn GetSystemFontCollection(self: *const T, includeDownloadableFonts: BOOL, fontFamilyModel: DWRITE_FONT_FAMILY_MODEL, fontCollection: ?*?*IDWriteFontCollection2) HRESULT {
                return @as(*const IDWriteFactory6.VTable, @ptrCast(self.vtable)).GetSystemFontCollection(@as(*const IDWriteFactory6, @ptrCast(self)), includeDownloadableFonts, fontFamilyModel, fontCollection);
            }
            pub inline fn CreateFontCollectionFromFontSet(self: *const T, fontSet: ?*IDWriteFontSet, fontFamilyModel: DWRITE_FONT_FAMILY_MODEL, fontCollection: ?*?*IDWriteFontCollection2) HRESULT {
                return @as(*const IDWriteFactory6.VTable, @ptrCast(self.vtable)).CreateFontCollectionFromFontSet(@as(*const IDWriteFactory6, @ptrCast(self)), fontSet, fontFamilyModel, fontCollection);
            }
            pub inline fn CreateFontSetBuilder(self: *const T, fontSetBuilder: ?*?*IDWriteFontSetBuilder2) HRESULT {
                return @as(*const IDWriteFactory6.VTable, @ptrCast(self.vtable)).CreateFontSetBuilder(@as(*const IDWriteFactory6, @ptrCast(self)), fontSetBuilder);
            }
            pub inline fn CreateTextFormat(self: *const T, fontFamilyName: ?[*:0]const u16, fontCollection: ?*IDWriteFontCollection, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, fontSize: f32, localeName: ?[*:0]const u16, textFormat: ?*?*IDWriteTextFormat3) HRESULT {
                return @as(*const IDWriteFactory6.VTable, @ptrCast(self.vtable)).CreateTextFormat(@as(*const IDWriteFactory6, @ptrCast(self)), fontFamilyName, fontCollection, fontAxisValues, fontAxisValueCount, fontSize, localeName, textFormat);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontFace5_Value = Guid.initString("98eff3a5-b667-479a-b145-e2fa5b9fdc29");
pub const IID_IDWriteFontFace5 = &IID_IDWriteFontFace5_Value;
pub const IDWriteFontFace5 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFace4.VTable,
        GetFontAxisValueCount: *const fn (
            self: *const IDWriteFontFace5,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontAxisValues: *const fn (
            self: *const IDWriteFontFace5,
            fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HasVariations: *const fn (
            self: *const IDWriteFontFace5,
        ) callconv(std.os.windows.WINAPI) BOOL,

        GetFontResource: *const fn (
            self: *const IDWriteFontFace5,
            fontResource: ?*?*IDWriteFontResource,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        Equals: *const fn (
            self: *const IDWriteFontFace5,
            fontFace: ?*IDWriteFontFace,
        ) callconv(std.os.windows.WINAPI) BOOL,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFace4.MethodMixin(T);
            pub inline fn GetFontAxisValueCount(self: *const T) u32 {
                return @as(*const IDWriteFontFace5.VTable, @ptrCast(self.vtable)).GetFontAxisValueCount(@as(*const IDWriteFontFace5, @ptrCast(self)));
            }
            pub inline fn GetFontAxisValues(self: *const T, fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32) HRESULT {
                return @as(*const IDWriteFontFace5.VTable, @ptrCast(self.vtable)).GetFontAxisValues(@as(*const IDWriteFontFace5, @ptrCast(self)), fontAxisValues, fontAxisValueCount);
            }
            pub inline fn HasVariations(self: *const T) BOOL {
                return @as(*const IDWriteFontFace5.VTable, @ptrCast(self.vtable)).HasVariations(@as(*const IDWriteFontFace5, @ptrCast(self)));
            }
            pub inline fn GetFontResource(self: *const T, fontResource: ?*?*IDWriteFontResource) HRESULT {
                return @as(*const IDWriteFontFace5.VTable, @ptrCast(self.vtable)).GetFontResource(@as(*const IDWriteFontFace5, @ptrCast(self)), fontResource);
            }
            pub inline fn Equals(self: *const T, fontFace: ?*IDWriteFontFace) BOOL {
                return @as(*const IDWriteFontFace5.VTable, @ptrCast(self.vtable)).Equals(@as(*const IDWriteFontFace5, @ptrCast(self)), fontFace);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontResource_Value = Guid.initString("1f803a76-6871-48e8-987f-b975551c50f2");
pub const IID_IDWriteFontResource = &IID_IDWriteFontResource_Value;
pub const IDWriteFontResource = extern struct {
    pub const VTable = extern struct {
        base: IUnknown.VTable,
        GetFontFile: *const fn (
            self: *const IDWriteFontResource,
            fontFile: ?*?*IDWriteFontFile,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFaceIndex: *const fn (
            self: *const IDWriteFontResource,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontAxisCount: *const fn (
            self: *const IDWriteFontResource,
        ) callconv(std.os.windows.WINAPI) u32,

        GetDefaultFontAxisValues: *const fn (
            self: *const IDWriteFontResource,
            fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontAxisRanges: *const fn (
            self: *const IDWriteFontResource,
            fontAxisRanges: [*]DWRITE_FONT_AXIS_RANGE,
            fontAxisRangeCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontAxisAttributes: *const fn (
            self: *const IDWriteFontResource,
            axisIndex: u32,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_AXIS_ATTRIBUTES,

        GetAxisNames: *const fn (
            self: *const IDWriteFontResource,
            axisIndex: u32,
            names: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetAxisValueNameCount: *const fn (
            self: *const IDWriteFontResource,
            axisIndex: u32,
        ) callconv(std.os.windows.WINAPI) u32,

        GetAxisValueNames: *const fn (
            self: *const IDWriteFontResource,
            axisIndex: u32,
            axisValueIndex: u32,
            fontAxisRange: ?*DWRITE_FONT_AXIS_RANGE,
            names: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        HasVariations: *const fn (
            self: *const IDWriteFontResource,
        ) callconv(std.os.windows.WINAPI) BOOL,

        CreateFontFace: *const fn (
            self: *const IDWriteFontResource,
            fontSimulations: DWRITE_FONT_SIMULATIONS,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            fontFace: ?*?*IDWriteFontFace5,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFaceReference: *const fn (
            self: *const IDWriteFontResource,
            fontSimulations: DWRITE_FONT_SIMULATIONS,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            fontFaceReference: ?*?*IDWriteFontFaceReference1,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IUnknown.MethodMixin(T);
            pub inline fn GetFontFile(self: *const T, fontFile: ?*?*IDWriteFontFile) HRESULT {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetFontFile(@as(*const IDWriteFontResource, @ptrCast(self)), fontFile);
            }
            pub inline fn GetFontFaceIndex(self: *const T) u32 {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetFontFaceIndex(@as(*const IDWriteFontResource, @ptrCast(self)));
            }
            pub inline fn GetFontAxisCount(self: *const T) u32 {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetFontAxisCount(@as(*const IDWriteFontResource, @ptrCast(self)));
            }
            pub inline fn GetDefaultFontAxisValues(self: *const T, fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32) HRESULT {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetDefaultFontAxisValues(@as(*const IDWriteFontResource, @ptrCast(self)), fontAxisValues, fontAxisValueCount);
            }
            pub inline fn GetFontAxisRanges(self: *const T, fontAxisRanges: [*]DWRITE_FONT_AXIS_RANGE, fontAxisRangeCount: u32) HRESULT {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetFontAxisRanges(@as(*const IDWriteFontResource, @ptrCast(self)), fontAxisRanges, fontAxisRangeCount);
            }
            pub inline fn GetFontAxisAttributes(self: *const T, axisIndex: u32) DWRITE_FONT_AXIS_ATTRIBUTES {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetFontAxisAttributes(@as(*const IDWriteFontResource, @ptrCast(self)), axisIndex);
            }
            pub inline fn GetAxisNames(self: *const T, axisIndex: u32, names: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetAxisNames(@as(*const IDWriteFontResource, @ptrCast(self)), axisIndex, names);
            }
            pub inline fn GetAxisValueNameCount(self: *const T, axisIndex: u32) u32 {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetAxisValueNameCount(@as(*const IDWriteFontResource, @ptrCast(self)), axisIndex);
            }
            pub inline fn GetAxisValueNames(self: *const T, axisIndex: u32, axisValueIndex: u32, fontAxisRange: ?*DWRITE_FONT_AXIS_RANGE, names: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).GetAxisValueNames(@as(*const IDWriteFontResource, @ptrCast(self)), axisIndex, axisValueIndex, fontAxisRange, names);
            }
            pub inline fn HasVariations(self: *const T) BOOL {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).HasVariations(@as(*const IDWriteFontResource, @ptrCast(self)));
            }
            pub inline fn CreateFontFace(self: *const T, fontSimulations: DWRITE_FONT_SIMULATIONS, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, fontFace: ?*?*IDWriteFontFace5) HRESULT {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).CreateFontFace(@as(*const IDWriteFontResource, @ptrCast(self)), fontSimulations, fontAxisValues, fontAxisValueCount, fontFace);
            }
            pub inline fn CreateFontFaceReference(self: *const T, fontSimulations: DWRITE_FONT_SIMULATIONS, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, fontFaceReference: ?*?*IDWriteFontFaceReference1) HRESULT {
                return @as(*const IDWriteFontResource.VTable, @ptrCast(self.vtable)).CreateFontFaceReference(@as(*const IDWriteFontResource, @ptrCast(self)), fontSimulations, fontAxisValues, fontAxisValueCount, fontFaceReference);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontFaceReference1_Value = Guid.initString("c081fe77-2fd1-41ac-a5a3-34983c4ba61a");
pub const IID_IDWriteFontFaceReference1 = &IID_IDWriteFontFaceReference1_Value;
pub const IDWriteFontFaceReference1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFaceReference.VTable,
        CreateFontFace: *const fn (
            self: *const IDWriteFontFaceReference1,
            fontFace: ?*?*IDWriteFontFace5,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontAxisValueCount: *const fn (
            self: *const IDWriteFontFaceReference1,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontAxisValues: *const fn (
            self: *const IDWriteFontFaceReference1,
            fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFaceReference.MethodMixin(T);
            pub inline fn CreateFontFace(self: *const T, fontFace: ?*?*IDWriteFontFace5) HRESULT {
                return @as(*const IDWriteFontFaceReference1.VTable, @ptrCast(self.vtable)).CreateFontFace(@as(*const IDWriteFontFaceReference1, @ptrCast(self)), fontFace);
            }
            pub inline fn GetFontAxisValueCount(self: *const T) u32 {
                return @as(*const IDWriteFontFaceReference1.VTable, @ptrCast(self.vtable)).GetFontAxisValueCount(@as(*const IDWriteFontFaceReference1, @ptrCast(self)));
            }
            pub inline fn GetFontAxisValues(self: *const T, fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32) HRESULT {
                return @as(*const IDWriteFontFaceReference1.VTable, @ptrCast(self.vtable)).GetFontAxisValues(@as(*const IDWriteFontFaceReference1, @ptrCast(self)), fontAxisValues, fontAxisValueCount);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontSetBuilder2_Value = Guid.initString("ee5ba612-b131-463c-8f4f-3189b9401e45");
pub const IID_IDWriteFontSetBuilder2 = &IID_IDWriteFontSetBuilder2_Value;
pub const IDWriteFontSetBuilder2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontSetBuilder1.VTable,
        AddFont: *const fn (
            self: *const IDWriteFontSetBuilder2,
            fontFile: ?*IDWriteFontFile,
            fontFaceIndex: u32,
            fontSimulations: DWRITE_FONT_SIMULATIONS,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            fontAxisRanges: [*]const DWRITE_FONT_AXIS_RANGE,
            fontAxisRangeCount: u32,
            properties: [*]const DWRITE_FONT_PROPERTY,
            propertyCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        AddFontFile: *const fn (
            self: *const IDWriteFontSetBuilder2,
            filePath: ?[*:0]const u16,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontSetBuilder1.MethodMixin(T);
            pub inline fn AddFont(self: *const T, fontFile: ?*IDWriteFontFile, fontFaceIndex: u32, fontSimulations: DWRITE_FONT_SIMULATIONS, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, fontAxisRanges: [*]const DWRITE_FONT_AXIS_RANGE, fontAxisRangeCount: u32, properties: [*]const DWRITE_FONT_PROPERTY, propertyCount: u32) HRESULT {
                return @as(*const IDWriteFontSetBuilder2.VTable, @ptrCast(self.vtable)).AddFont(@as(*const IDWriteFontSetBuilder2, @ptrCast(self)), fontFile, fontFaceIndex, fontSimulations, fontAxisValues, fontAxisValueCount, fontAxisRanges, fontAxisRangeCount, properties, propertyCount);
            }
            pub inline fn AddFontFile(self: *const T, filePath: ?[*:0]const u16) HRESULT {
                return @as(*const IDWriteFontSetBuilder2.VTable, @ptrCast(self.vtable)).AddFontFile(@as(*const IDWriteFontSetBuilder2, @ptrCast(self)), filePath);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontSet1_Value = Guid.initString("7e9fda85-6c92-4053-bc47-7ae3530db4d3");
pub const IID_IDWriteFontSet1 = &IID_IDWriteFontSet1_Value;
pub const IDWriteFontSet1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontSet.VTable,
        GetMatchingFonts: *const fn (
            self: *const IDWriteFontSet1,
            fontProperty: ?*const DWRITE_FONT_PROPERTY,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            matchingFonts: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFirstFontResources: *const fn (
            self: *const IDWriteFontSet1,
            filteredFontSet: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFilteredFonts: *const fn (
            self: *const IDWriteFontSet1,
            indices: [*]const u32,
            indexCount: u32,
            filteredFontSet: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFilteredFonts1: *const fn (
            self: *const IDWriteFontSet1,
            fontAxisRanges: [*]const DWRITE_FONT_AXIS_RANGE,
            fontAxisRangeCount: u32,
            selectAnyRange: BOOL,
            filteredFontSet: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFilteredFonts2: *const fn (
            self: *const IDWriteFontSet1,
            properties: ?[*]const DWRITE_FONT_PROPERTY,
            propertyCount: u32,
            selectAnyProperty: BOOL,
            filteredFontSet: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFilteredFontIndices: *const fn (
            self: *const IDWriteFontSet1,
            fontAxisRanges: [*]const DWRITE_FONT_AXIS_RANGE,
            fontAxisRangeCount: u32,
            selectAnyRange: BOOL,
            indices: [*]u32,
            maxIndexCount: u32,
            actualIndexCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFilteredFontIndices1: *const fn (
            self: *const IDWriteFontSet1,
            properties: [*]const DWRITE_FONT_PROPERTY,
            propertyCount: u32,
            selectAnyProperty: BOOL,
            indices: [*]u32,
            maxIndexCount: u32,
            actualIndexCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontAxisRanges: *const fn (
            self: *const IDWriteFontSet1,
            listIndex: u32,
            fontAxisRanges: [*]DWRITE_FONT_AXIS_RANGE,
            maxFontAxisRangeCount: u32,
            actualFontAxisRangeCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontAxisRanges1: *const fn (
            self: *const IDWriteFontSet1,
            fontAxisRanges: [*]DWRITE_FONT_AXIS_RANGE,
            maxFontAxisRangeCount: u32,
            actualFontAxisRangeCount: ?*u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFaceReference: *const fn (
            self: *const IDWriteFontSet1,
            listIndex: u32,
            fontFaceReference: ?*?*IDWriteFontFaceReference1,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontResource: *const fn (
            self: *const IDWriteFontSet1,
            listIndex: u32,
            fontResource: ?*?*IDWriteFontResource,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        CreateFontFace: *const fn (
            self: *const IDWriteFontSet1,
            listIndex: u32,
            fontFace: ?*?*IDWriteFontFace5,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontLocality: *const fn (
            self: *const IDWriteFontSet1,
            listIndex: u32,
        ) callconv(std.os.windows.WINAPI) DWRITE_LOCALITY,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontSet.MethodMixin(T);
            pub inline fn GetMatchingFonts(self: *const T, fontProperty: ?*const DWRITE_FONT_PROPERTY, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, matchingFonts: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetMatchingFonts(@as(*const IDWriteFontSet1, @ptrCast(self)), fontProperty, fontAxisValues, fontAxisValueCount, matchingFonts);
            }
            pub inline fn GetFirstFontResources(self: *const T, filteredFontSet: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFirstFontResources(@as(*const IDWriteFontSet1, @ptrCast(self)), filteredFontSet);
            }
            pub inline fn GetFilteredFonts(self: *const T, indices: [*]const u32, indexCount: u32, filteredFontSet: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFilteredFonts(@as(*const IDWriteFontSet1, @ptrCast(self)), indices, indexCount, filteredFontSet);
            }
            pub inline fn GetFilteredFonts1(self: *const T, fontAxisRanges: [*]const DWRITE_FONT_AXIS_RANGE, fontAxisRangeCount: u32, selectAnyRange: BOOL, filteredFontSet: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFilteredFonts(@as(*const IDWriteFontSet1, @ptrCast(self)), fontAxisRanges, fontAxisRangeCount, selectAnyRange, filteredFontSet);
            }
            pub inline fn GetFilteredFonts2(self: *const T, properties: ?[*]const DWRITE_FONT_PROPERTY, propertyCount: u32, selectAnyProperty: BOOL, filteredFontSet: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFilteredFonts(@as(*const IDWriteFontSet1, @ptrCast(self)), properties, propertyCount, selectAnyProperty, filteredFontSet);
            }
            pub inline fn GetFilteredFontIndices(self: *const T, fontAxisRanges: [*]const DWRITE_FONT_AXIS_RANGE, fontAxisRangeCount: u32, selectAnyRange: BOOL, indices: [*]u32, maxIndexCount: u32, actualIndexCount: ?*u32) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFilteredFontIndices(@as(*const IDWriteFontSet1, @ptrCast(self)), fontAxisRanges, fontAxisRangeCount, selectAnyRange, indices, maxIndexCount, actualIndexCount);
            }
            pub inline fn GetFilteredFontIndices1(self: *const T, properties: [*]const DWRITE_FONT_PROPERTY, propertyCount: u32, selectAnyProperty: BOOL, indices: [*]u32, maxIndexCount: u32, actualIndexCount: ?*u32) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFilteredFontIndices(@as(*const IDWriteFontSet1, @ptrCast(self)), properties, propertyCount, selectAnyProperty, indices, maxIndexCount, actualIndexCount);
            }
            pub inline fn GetFontAxisRanges(self: *const T, listIndex: u32, fontAxisRanges: [*]DWRITE_FONT_AXIS_RANGE, maxFontAxisRangeCount: u32, actualFontAxisRangeCount: ?*u32) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFontAxisRanges(@as(*const IDWriteFontSet1, @ptrCast(self)), listIndex, fontAxisRanges, maxFontAxisRangeCount, actualFontAxisRangeCount);
            }
            pub inline fn GetFontAxisRanges1(self: *const T, fontAxisRanges: [*]DWRITE_FONT_AXIS_RANGE, maxFontAxisRangeCount: u32, actualFontAxisRangeCount: ?*u32) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFontAxisRanges(@as(*const IDWriteFontSet1, @ptrCast(self)), fontAxisRanges, maxFontAxisRangeCount, actualFontAxisRangeCount);
            }
            pub inline fn GetFontFaceReference(self: *const T, listIndex: u32, fontFaceReference: ?*?*IDWriteFontFaceReference1) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFontFaceReference(@as(*const IDWriteFontSet1, @ptrCast(self)), listIndex, fontFaceReference);
            }
            pub inline fn CreateFontResource(self: *const T, listIndex: u32, fontResource: ?*?*IDWriteFontResource) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).CreateFontResource(@as(*const IDWriteFontSet1, @ptrCast(self)), listIndex, fontResource);
            }
            pub inline fn CreateFontFace(self: *const T, listIndex: u32, fontFace: ?*?*IDWriteFontFace5) HRESULT {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).CreateFontFace(@as(*const IDWriteFontSet1, @ptrCast(self)), listIndex, fontFace);
            }
            pub inline fn GetFontLocality(self: *const T, listIndex: u32) DWRITE_LOCALITY {
                return @as(*const IDWriteFontSet1.VTable, @ptrCast(self.vtable)).GetFontLocality(@as(*const IDWriteFontSet1, @ptrCast(self)), listIndex);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontList2_Value = Guid.initString("c0763a34-77af-445a-b735-08c37b0a5bf5");
pub const IID_IDWriteFontList2 = &IID_IDWriteFontList2_Value;
pub const IDWriteFontList2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontList1.VTable,
        GetFontSet: *const fn (
            self: *const IDWriteFontList2,
            fontSet: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontList1.MethodMixin(T);
            pub inline fn GetFontSet(self: *const T, fontSet: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFontList2.VTable, @ptrCast(self.vtable)).GetFontSet(@as(*const IDWriteFontList2, @ptrCast(self)), fontSet);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontFamily2_Value = Guid.initString("3ed49e77-a398-4261-b9cf-c126c2131ef3");
pub const IID_IDWriteFontFamily2 = &IID_IDWriteFontFamily2_Value;
pub const IDWriteFontFamily2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFamily1.VTable,
        GetMatchingFonts: *const fn (
            self: *const IDWriteFontFamily2,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            matchingFonts: ?*?*IDWriteFontList2,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontSet: *const fn (
            self: *const IDWriteFontFamily2,
            fontSet: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFamily1.MethodMixin(T);
            pub inline fn GetMatchingFonts(self: *const T, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, matchingFonts: ?*?*IDWriteFontList2) HRESULT {
                return @as(*const IDWriteFontFamily2.VTable, @ptrCast(self.vtable)).GetMatchingFonts(@as(*const IDWriteFontFamily2, @ptrCast(self)), fontAxisValues, fontAxisValueCount, matchingFonts);
            }
            pub inline fn GetFontSet(self: *const T, fontSet: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFontFamily2.VTable, @ptrCast(self.vtable)).GetFontSet(@as(*const IDWriteFontFamily2, @ptrCast(self)), fontSet);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontCollection2_Value = Guid.initString("514039c6-4617-4064-bf8b-92ea83e506e0");
pub const IID_IDWriteFontCollection2 = &IID_IDWriteFontCollection2_Value;
pub const IDWriteFontCollection2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontCollection1.VTable,
        GetFontFamily: *const fn (
            self: *const IDWriteFontCollection2,
            index: u32,
            fontFamily: ?*?*IDWriteFontFamily2,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetMatchingFonts: *const fn (
            self: *const IDWriteFontCollection2,
            familyName: ?[*:0]const u16,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            fontList: ?*?*IDWriteFontList2,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontFamilyModel: *const fn (
            self: *const IDWriteFontCollection2,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_FAMILY_MODEL,

        GetFontSet: *const fn (
            self: *const IDWriteFontCollection2,
            fontSet: ?*?*IDWriteFontSet1,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontCollection1.MethodMixin(T);
            pub inline fn GetFontFamily(self: *const T, index: u32, fontFamily: ?*?*IDWriteFontFamily2) HRESULT {
                return @as(*const IDWriteFontCollection2.VTable, @ptrCast(self.vtable)).GetFontFamily(@as(*const IDWriteFontCollection2, @ptrCast(self)), index, fontFamily);
            }
            pub inline fn GetMatchingFonts(self: *const T, familyName: ?[*:0]const u16, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, fontList: ?*?*IDWriteFontList2) HRESULT {
                return @as(*const IDWriteFontCollection2.VTable, @ptrCast(self.vtable)).GetMatchingFonts(@as(*const IDWriteFontCollection2, @ptrCast(self)), familyName, fontAxisValues, fontAxisValueCount, fontList);
            }
            pub inline fn GetFontFamilyModel(self: *const T) DWRITE_FONT_FAMILY_MODEL {
                return @as(*const IDWriteFontCollection2.VTable, @ptrCast(self.vtable)).GetFontFamilyModel(@as(*const IDWriteFontCollection2, @ptrCast(self)));
            }
            pub inline fn GetFontSet(self: *const T, fontSet: ?*?*IDWriteFontSet1) HRESULT {
                return @as(*const IDWriteFontCollection2.VTable, @ptrCast(self.vtable)).GetFontSet(@as(*const IDWriteFontCollection2, @ptrCast(self)), fontSet);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteTextLayout4_Value = Guid.initString("05a9bf42-223f-4441-b5fb-8263685f55e9");
pub const IID_IDWriteTextLayout4 = &IID_IDWriteTextLayout4_Value;
pub const IDWriteTextLayout4 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextLayout3.VTable,
        SetFontAxisValues: *const fn (
            self: *const IDWriteTextLayout4,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            textRange: DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontAxisValueCount: *const fn (
            self: *const IDWriteTextLayout4,
            currentPosition: u32,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontAxisValues: *const fn (
            self: *const IDWriteTextLayout4,
            currentPosition: u32,
            fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            textRange: ?*DWRITE_TEXT_RANGE,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetAutomaticFontAxes: *const fn (
            self: *const IDWriteTextLayout4,
        ) callconv(std.os.windows.WINAPI) DWRITE_AUTOMATIC_FONT_AXES,

        SetAutomaticFontAxes: *const fn (
            self: *const IDWriteTextLayout4,
            automaticFontAxes: DWRITE_AUTOMATIC_FONT_AXES,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextLayout3.MethodMixin(T);
            pub inline fn SetFontAxisValues(self: *const T, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, textRange: DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout4.VTable, @ptrCast(self.vtable)).SetFontAxisValues(@as(*const IDWriteTextLayout4, @ptrCast(self)), fontAxisValues, fontAxisValueCount, textRange);
            }
            pub inline fn GetFontAxisValueCount(self: *const T, currentPosition: u32) u32 {
                return @as(*const IDWriteTextLayout4.VTable, @ptrCast(self.vtable)).GetFontAxisValueCount(@as(*const IDWriteTextLayout4, @ptrCast(self)), currentPosition);
            }
            pub inline fn GetFontAxisValues(self: *const T, currentPosition: u32, fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, textRange: ?*DWRITE_TEXT_RANGE) HRESULT {
                return @as(*const IDWriteTextLayout4.VTable, @ptrCast(self.vtable)).GetFontAxisValues(@as(*const IDWriteTextLayout4, @ptrCast(self)), currentPosition, fontAxisValues, fontAxisValueCount, textRange);
            }
            pub inline fn GetAutomaticFontAxes(self: *const T) DWRITE_AUTOMATIC_FONT_AXES {
                return @as(*const IDWriteTextLayout4.VTable, @ptrCast(self.vtable)).GetAutomaticFontAxes(@as(*const IDWriteTextLayout4, @ptrCast(self)));
            }
            pub inline fn SetAutomaticFontAxes(self: *const T, automaticFontAxes: DWRITE_AUTOMATIC_FONT_AXES) HRESULT {
                return @as(*const IDWriteTextLayout4.VTable, @ptrCast(self.vtable)).SetAutomaticFontAxes(@as(*const IDWriteTextLayout4, @ptrCast(self)), automaticFontAxes);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteTextFormat3_Value = Guid.initString("6d3b5641-e550-430d-a85b-b7bf48a93427");
pub const IID_IDWriteTextFormat3 = &IID_IDWriteTextFormat3_Value;
pub const IDWriteTextFormat3 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteTextFormat2.VTable,
        SetFontAxisValues: *const fn (
            self: *const IDWriteTextFormat3,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFontAxisValueCount: *const fn (
            self: *const IDWriteTextFormat3,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontAxisValues: *const fn (
            self: *const IDWriteTextFormat3,
            fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetAutomaticFontAxes: *const fn (
            self: *const IDWriteTextFormat3,
        ) callconv(std.os.windows.WINAPI) DWRITE_AUTOMATIC_FONT_AXES,

        SetAutomaticFontAxes: *const fn (
            self: *const IDWriteTextFormat3,
            automaticFontAxes: DWRITE_AUTOMATIC_FONT_AXES,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteTextFormat2.MethodMixin(T);
            pub inline fn SetFontAxisValues(self: *const T, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32) HRESULT {
                return @as(*const IDWriteTextFormat3.VTable, @ptrCast(self.vtable)).SetFontAxisValues(@as(*const IDWriteTextFormat3, @ptrCast(self)), fontAxisValues, fontAxisValueCount);
            }
            pub inline fn GetFontAxisValueCount(self: *const T) u32 {
                return @as(*const IDWriteTextFormat3.VTable, @ptrCast(self.vtable)).GetFontAxisValueCount(@as(*const IDWriteTextFormat3, @ptrCast(self)));
            }
            pub inline fn GetFontAxisValues(self: *const T, fontAxisValues: [*]DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32) HRESULT {
                return @as(*const IDWriteTextFormat3.VTable, @ptrCast(self.vtable)).GetFontAxisValues(@as(*const IDWriteTextFormat3, @ptrCast(self)), fontAxisValues, fontAxisValueCount);
            }
            pub inline fn GetAutomaticFontAxes(self: *const T) DWRITE_AUTOMATIC_FONT_AXES {
                return @as(*const IDWriteTextFormat3.VTable, @ptrCast(self.vtable)).GetAutomaticFontAxes(@as(*const IDWriteTextFormat3, @ptrCast(self)));
            }
            pub inline fn SetAutomaticFontAxes(self: *const T, automaticFontAxes: DWRITE_AUTOMATIC_FONT_AXES) HRESULT {
                return @as(*const IDWriteTextFormat3.VTable, @ptrCast(self.vtable)).SetAutomaticFontAxes(@as(*const IDWriteTextFormat3, @ptrCast(self)), automaticFontAxes);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontFallback1_Value = Guid.initString("2397599d-dd0d-4681-bd6a-f4f31eaade77");
pub const IID_IDWriteFontFallback1 = &IID_IDWriteFontFallback1_Value;
pub const IDWriteFontFallback1 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFallback.VTable,
        MapCharacters: *const fn (
            self: *const IDWriteFontFallback1,
            analysisSource: ?*IDWriteTextAnalysisSource,
            textPosition: u32,
            textLength: u32,
            baseFontCollection: ?*IDWriteFontCollection,
            baseFamilyName: ?[*:0]const u16,
            fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE,
            fontAxisValueCount: u32,
            mappedLength: ?*u32,
            scale: ?*f32,
            mappedFontFace: ?*?*IDWriteFontFace5,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFallback.MethodMixin(T);
            pub inline fn MapCharacters(self: *const T, analysisSource: ?*IDWriteTextAnalysisSource, textPosition: u32, textLength: u32, baseFontCollection: ?*IDWriteFontCollection, baseFamilyName: ?[*:0]const u16, fontAxisValues: [*]const DWRITE_FONT_AXIS_VALUE, fontAxisValueCount: u32, mappedLength: ?*u32, scale: ?*f32, mappedFontFace: ?*?*IDWriteFontFace5) HRESULT {
                return @as(*const IDWriteFontFallback1.VTable, @ptrCast(self.vtable)).MapCharacters(@as(*const IDWriteFontFallback1, @ptrCast(self)), analysisSource, textPosition, textLength, baseFontCollection, baseFamilyName, fontAxisValues, fontAxisValueCount, mappedLength, scale, mappedFontFace);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontSet2_Value = Guid.initString("dc7ead19-e54c-43af-b2da-4e2b79ba3f7f");
pub const IID_IDWriteFontSet2 = &IID_IDWriteFontSet2_Value;
pub const IDWriteFontSet2 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontSet1.VTable,
        GetExpirationEvent: *const fn (
            self: *const IDWriteFontSet2,
        ) callconv(std.os.windows.WINAPI) ?HANDLE,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontSet1.MethodMixin(T);
            pub inline fn GetExpirationEvent(self: *const T) ?HANDLE {
                return @as(*const IDWriteFontSet2.VTable, @ptrCast(self.vtable)).GetExpirationEvent(@as(*const IDWriteFontSet2, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontCollection3_Value = Guid.initString("a4d055a6-f9e3-4e25-93b7-9e309f3af8e9");
pub const IID_IDWriteFontCollection3 = &IID_IDWriteFontCollection3_Value;
pub const IDWriteFontCollection3 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontCollection2.VTable,
        GetExpirationEvent: *const fn (
            self: *const IDWriteFontCollection3,
        ) callconv(std.os.windows.WINAPI) ?HANDLE,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontCollection2.MethodMixin(T);
            pub inline fn GetExpirationEvent(self: *const T) ?HANDLE {
                return @as(*const IDWriteFontCollection3.VTable, @ptrCast(self.vtable)).GetExpirationEvent(@as(*const IDWriteFontCollection3, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFactory7_Value = Guid.initString("35d0e0b3-9076-4d2e-a016-a91b568a06b4");
pub const IID_IDWriteFactory7 = &IID_IDWriteFactory7_Value;
pub const IDWriteFactory7 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFactory6.VTable,
        GetSystemFontSet: *const fn (
            self: *const IDWriteFactory7,
            includeDownloadableFonts: BOOL,
            fontSet: ?*?*IDWriteFontSet2,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetSystemFontCollection: *const fn (
            self: *const IDWriteFactory7,
            includeDownloadableFonts: BOOL,
            fontFamilyModel: DWRITE_FONT_FAMILY_MODEL,
            fontCollection: ?*?*IDWriteFontCollection3,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFactory6.MethodMixin(T);
            pub inline fn GetSystemFontSet(self: *const T, includeDownloadableFonts: BOOL, fontSet: ?*?*IDWriteFontSet2) HRESULT {
                return @as(*const IDWriteFactory7.VTable, @ptrCast(self.vtable)).GetSystemFontSet(@as(*const IDWriteFactory7, @ptrCast(self)), includeDownloadableFonts, fontSet);
            }
            pub inline fn GetSystemFontCollection(self: *const T, includeDownloadableFonts: BOOL, fontFamilyModel: DWRITE_FONT_FAMILY_MODEL, fontCollection: ?*?*IDWriteFontCollection3) HRESULT {
                return @as(*const IDWriteFactory7.VTable, @ptrCast(self.vtable)).GetSystemFontCollection(@as(*const IDWriteFactory7, @ptrCast(self)), includeDownloadableFonts, fontFamilyModel, fontCollection);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

pub const DWRITE_FONT_SOURCE_TYPE = enum(i32) {
    UNKNOWN = 0,
    PER_MACHINE = 1,
    PER_USER = 2,
    APPX_PACKAGE = 3,
    REMOTE_FONT_PROVIDER = 4,
};
pub const DWRITE_FONT_SOURCE_TYPE_UNKNOWN = DWRITE_FONT_SOURCE_TYPE.UNKNOWN;
pub const DWRITE_FONT_SOURCE_TYPE_PER_MACHINE = DWRITE_FONT_SOURCE_TYPE.PER_MACHINE;
pub const DWRITE_FONT_SOURCE_TYPE_PER_USER = DWRITE_FONT_SOURCE_TYPE.PER_USER;
pub const DWRITE_FONT_SOURCE_TYPE_APPX_PACKAGE = DWRITE_FONT_SOURCE_TYPE.APPX_PACKAGE;
pub const DWRITE_FONT_SOURCE_TYPE_REMOTE_FONT_PROVIDER = DWRITE_FONT_SOURCE_TYPE.REMOTE_FONT_PROVIDER;

const IID_IDWriteFontSet3_Value = Guid.initString("7c073ef2-a7f4-4045-8c32-8ab8ae640f90");
pub const IID_IDWriteFontSet3 = &IID_IDWriteFontSet3_Value;
pub const IDWriteFontSet3 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontSet2.VTable,
        GetFontSourceType: *const fn (
            self: *const IDWriteFontSet3,
            fontIndex: u32,
        ) callconv(std.os.windows.WINAPI) DWRITE_FONT_SOURCE_TYPE,

        GetFontSourceNameLength: *const fn (
            self: *const IDWriteFontSet3,
            listIndex: u32,
        ) callconv(std.os.windows.WINAPI) u32,

        GetFontSourceName: *const fn (
            self: *const IDWriteFontSet3,
            listIndex: u32,
            stringBuffer: [*:0]u16,
            stringBufferSize: u32,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontSet2.MethodMixin(T);
            pub inline fn GetFontSourceType(self: *const T, fontIndex: u32) DWRITE_FONT_SOURCE_TYPE {
                return @as(*const IDWriteFontSet3.VTable, @ptrCast(self.vtable)).GetFontSourceType(@as(*const IDWriteFontSet3, @ptrCast(self)), fontIndex);
            }
            pub inline fn GetFontSourceNameLength(self: *const T, listIndex: u32) u32 {
                return @as(*const IDWriteFontSet3.VTable, @ptrCast(self.vtable)).GetFontSourceNameLength(@as(*const IDWriteFontSet3, @ptrCast(self)), listIndex);
            }
            pub inline fn GetFontSourceName(self: *const T, listIndex: u32, stringBuffer: [*:0]u16, stringBufferSize: u32) HRESULT {
                return @as(*const IDWriteFontSet3.VTable, @ptrCast(self.vtable)).GetFontSourceName(@as(*const IDWriteFontSet3, @ptrCast(self)), listIndex, stringBuffer, stringBufferSize);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

const IID_IDWriteFontFace6_Value = Guid.initString("c4b1fe1b-6e84-47d5-b54c-a597981b06ad");
pub const IID_IDWriteFontFace6 = &IID_IDWriteFontFace6_Value;
pub const IDWriteFontFace6 = extern struct {
    pub const VTable = extern struct {
        base: IDWriteFontFace5.VTable,
        GetFamilyNames: *const fn (
            self: *const IDWriteFontFace6,
            fontFamilyModel: DWRITE_FONT_FAMILY_MODEL,
            names: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,

        GetFaceNames: *const fn (
            self: *const IDWriteFontFace6,
            fontFamilyModel: DWRITE_FONT_FAMILY_MODEL,
            names: ?*?*IDWriteLocalizedStrings,
        ) callconv(std.os.windows.WINAPI) HRESULT,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub usingnamespace IDWriteFontFace5.MethodMixin(T);
            pub inline fn GetFamilyNames(self: *const T, fontFamilyModel: DWRITE_FONT_FAMILY_MODEL, names: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFontFace6.VTable, @ptrCast(self.vtable)).GetFamilyNames(@as(*const IDWriteFontFace6, @ptrCast(self)), fontFamilyModel, names);
            }
            pub inline fn GetFaceNames(self: *const T, fontFamilyModel: DWRITE_FONT_FAMILY_MODEL, names: ?*?*IDWriteLocalizedStrings) HRESULT {
                return @as(*const IDWriteFontFace6.VTable, @ptrCast(self.vtable)).GetFaceNames(@as(*const IDWriteFontFace6, @ptrCast(self)), fontFamilyModel, names);
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};

//--------------------------------------------------------------------------------
// Section: Functions (1)
//--------------------------------------------------------------------------------
// TODO: this type is limited to platform 'windows6.1'
pub extern "dwrite" fn DWriteCreateFactory(
    factoryType: DWRITE_FACTORY_TYPE,
    iid: ?*const Guid,
    factory: ?*?*IUnknown,
) callconv(std.os.windows.WINAPI) HRESULT;

//--------------------------------------------------------------------------------
// Section: Imports (18)
//--------------------------------------------------------------------------------
pub const Guid = extern union {
    Ints: extern struct {
        a: u32,
        b: u16,
        c: u16,
        d: [8]u8,
    },
    Bytes: [16]u8,

    const big_endian_hex_offsets = [16]u6{ 0, 2, 4, 6, 9, 11, 14, 16, 19, 21, 24, 26, 28, 30, 32, 34 };
    const little_endian_hex_offsets = [16]u6{ 6, 4, 2, 0, 11, 9, 16, 14, 19, 21, 24, 26, 28, 30, 32, 34 };
    const hex_offsets = switch (builtin.target.cpu.arch.endian()) {
        .big => big_endian_hex_offsets,
        .little => little_endian_hex_offsets,
    };

    pub fn initString(s: []const u8) Guid {
        var guid = Guid{ .Bytes = undefined };
        for (hex_offsets, 0..) |hex_offset, i| {
            //guid.Bytes[i] = decodeHexByte(s[offset..offset+2]);
            guid.Bytes[i] = decodeHexByte([2]u8{ s[hex_offset], s[hex_offset + 1] });
        }
        return guid;
    }
    fn decodeHexByte(hex: [2]u8) u8 {
        return @as(u8, @intCast(hexVal(hex[0]))) << 4 | hexVal(hex[1]);
    }
    fn hexVal(c: u8) u4 {
        if (c <= '9') return @as(u4, @intCast(c - '0'));
        if (c >= 'a') return @as(u4, @intCast(c + 10 - 'a'));
        return @as(u4, @intCast(c + 10 - 'A'));
    }
};
const BOOL = std.os.windows.BOOL;
const D2D_POINT_2F = extern struct {
    x: f32,
    y: f32,
};
const D2D_SIZE_U = extern struct {
    width: u32,
    height: u32,
};
const FILETIME = extern struct {
    dwLowDateTime: u32,
    dwHighDateTime: u32,
};
const FONTSIGNATURE = extern struct {
    fsUsb: [4]u32,
    fsCsb: [2]u32,
};
const HANDLE = *anyopaque;
const HDC = *opaque {};
const HMONITOR = *opaque {};
const HRESULT = i32;
const IID_IUnknown_Value = Guid.initString("00000000-0000-0000-c000-000000000046");
pub const IID_IUnknown = &IID_IUnknown_Value;
pub const IUnknown = extern struct {
    pub const VTable = extern struct {
        QueryInterface: *const fn (
            self: *const IUnknown,
            riid: ?*const Guid,
            ppvObject: ?*?*anyopaque,
        ) callconv(std.os.windows.WINAPI) HRESULT,
        AddRef: *const fn (self: *const IUnknown) callconv(std.os.windows.WINAPI) u32,
        Release: *const fn (self: *const IUnknown) callconv(std.os.windows.WINAPI) u32,
    };
    vtable: *const VTable,
    pub fn MethodMixin(comptime T: type) type {
        return struct {
            pub inline fn QueryInterface(self: *const T, riid: ?*const Guid, ppvObject: ?*?*anyopaque) HRESULT {
                return @as(*const IUnknown.VTable, @ptrCast(self.vtable)).QueryInterface(@as(*const IUnknown, @ptrCast(self)), riid, ppvObject);
            }
            pub inline fn AddRef(self: *const T) u32 {
                return @as(*const IUnknown.VTable, @ptrCast(self.vtable)).AddRef(@as(*const IUnknown, @ptrCast(self)));
            }
            pub inline fn Release(self: *const T) u32 {
                return @as(*const IUnknown.VTable, @ptrCast(self.vtable)).Release(@as(*const IUnknown, @ptrCast(self)));
            }
        };
    }
    pub usingnamespace MethodMixin(@This());
};
const LOGFONTA = extern struct {
    lfHeight: i32,
    lfWidth: i32,
    lfEscapement: i32,
    lfOrientation: i32,
    lfWeight: i32,
    lfItalic: u8,
    lfUnderline: u8,
    lfStrikeOut: u8,
    lfCharSet: u8,
    lfOutPrecision: u8,
    lfClipPrecision: u8,
    lfQuality: u8,
    lfPitchAndFamily: u8,
    lfFaceName: [32]CHAR,
};
pub const LOGFONTW = extern struct {
    lfHeight: i32,
    lfWidth: i32,
    lfEscapement: i32,
    lfOrientation: i32,
    lfWeight: i32,
    lfItalic: u8,
    lfUnderline: u8,
    lfStrikeOut: u8,
    lfCharSet: u8,
    lfOutPrecision: u8,
    lfClipPrecision: u8,
    lfQuality: u8,
    lfPitchAndFamily: u8,
    lfFaceName: [32]u16,
};
const CHAR = u8;
const POINT = extern struct {
    x: i32,
    y: i32,
};
const PWSTR = [*:0]u16;
const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};
const SIZE = extern struct {
    cx: i32,
    cy: i32,
};
pub fn FAILED(hr: HRESULT) bool {
    return hr < 0;
}
pub fn SUCCEEDED(hr: HRESULT) bool {
    return hr >= 0;
}

test {
    @setEvalBranchQuota(comptime std.meta.declarations(@This()).len * 3);

    // reference all the pub declarations
    if (!@import("builtin").is_test) return;
    inline for (comptime std.meta.declarations(@This())) |decl| {
        _ = @field(@This(), decl.name);
    }
}
