const std = @import("std");
const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Face = @import("freetype.zig").Face;
const Stroker = @import("stroke.zig").Stroker;
const OpenArgs = @import("freetype.zig").OpenArgs;
const Bitmap = @import("image.zig").Bitmap;
const Outline = @import("image.zig").Outline;
const RasterParams = @import("image.zig").Raster.Params;
const LcdFilter = @import("lcdfilter.zig").LcdFilter;

const Library = @This();

pub const Version = struct {
    major: i32,
    minor: i32,
    patch: i32,
};

handle: c.FT_Library,

pub fn init() Error!Library {
    var lib = Library{ .handle = undefined };
    try intToError(c.FT_Init_FreeType(&lib.handle));
    return lib;
}

pub fn deinit(self: Library) void {
    _ = c.FT_Done_FreeType(self.handle);
}

pub fn createFace(self: Library, path: [*:0]const u8, face_index: i32) Error!Face {
    return self.openFace(.{
        .flags = .{ .path = true },
        .data = .{ .path = path },
    }, face_index);
}

pub fn createFaceMemory(self: Library, bytes: []const u8, face_index: i32) Error!Face {
    return self.openFace(.{
        .flags = .{ .memory = true },
        .data = .{ .memory = bytes },
    }, face_index);
}

pub fn openFace(self: Library, args: OpenArgs, face_index: i32) Error!Face {
    var f: c.FT_Face = undefined;
    try intToError(c.FT_Open_Face(self.handle, &args.cast(), face_index, &f));
    return Face{ .handle = f };
}

pub fn version(self: Library) Version {
    var v: Version = undefined;
    c.FT_Library_Version(
        self.handle,
        &v.major,
        &v.minor,
        &v.patch,
    );
    return v;
}

pub fn createStroker(self: Library) Error!Stroker {
    var s: c.FT_Stroker = undefined;
    try intToError(c.FT_Stroker_New(self.handle, &s));
    return Stroker{ .handle = s };
}

pub fn createOutlineFromBitmap(self: Library, bitmap: Bitmap) Error!Outline {
    var o: Outline = undefined;
    try intToError(c.FT_Outline_Get_Bitmap(self.handle, o.handle, &bitmap.handle));
    return o;
}

pub fn renderOutline(self: Library, outline: Outline, params: *RasterParams) Error!void {
    try intToError(FT_Outline_Render(self.handle, outline.handle, params));
}

pub fn setLcdFilter(self: Library, lcd_filter: LcdFilter) Error!void {
    return intToError(c.FT_Library_SetLcdFilter(self.handle, @enumToInt(lcd_filter)));
}

pub extern fn FT_Outline_Render(library: c.FT_Library, outline: [*c]c.FT_Outline, params: [*c]RasterParams) c_int;
