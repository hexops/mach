const std = @import("std");
const c = @import("c");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Stroker = @import("Stroker.zig");
const Face = @import("freetype.zig").Face;
const OpenArgs = @import("freetype.zig").OpenArgs;
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
    intToError(c.FT_Done_FreeType(self.handle)) catch |err| {
        std.log.err("mach/freetype: Failed to deinitialize Library: {}", .{err});
    };
}

pub fn newFace(self: Library, path: []const u8, face_index: i32) Error!Face {
    return self.openFace(.{
        .flags = .{ .path = true },
        .data = .{ .path = path },
    }, face_index);
}

pub fn newFaceMemory(self: Library, bytes: []const u8, face_index: i32) Error!Face {
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

pub fn newStroker(self: Library) Error!Stroker {
    var s: c.FT_Stroker = undefined;
    try intToError(c.FT_Stroker_New(self.handle, &s));
    return Stroker{ .handle = s };
}

pub fn setLcdFilter(self: Library, lcd_filter: LcdFilter) Error!void {
    return intToError(c.FT_Library_SetLcdFilter(self.handle, @enumToInt(lcd_filter)));
}
