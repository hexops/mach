const std = @import("std");
const unicode = std.unicode;
const win32 = @import("win32.zig");
const Family = @import("Family.zig");

const TRUE: BOOL = 1;
const FALSE: BOOL = 0;
const BOOL = win32.BOOL;
const FAILED = win32.FAILED;
const SUCCEED = win32.SUCCEED;

/// Convert UTF-8 string literal to UTF-16LE
const L = unicode.utf8ToUtf16LeStringLiteral;

const FontManager = @This();

alloc: std.mem.Allocator,
factory: ?*win32.IDWriteFactory,
collection: ?*win32.IDWriteFontCollection,

/// Initializes the Font Manager for use.
pub fn init(allocator: std.mem.Allocator) !FontManager {
    // Initialize font factory.
    var wfactory: ?*win32.IDWriteFactory = null;
    var hr = win32.DWriteCreateFactory(
        .SHARED,
        win32.IID_IDWriteFactory,
        @as(?*?*win32.IUnknown, @ptrCast(&wfactory)),
    );
    if (FAILED(hr)) return error.FailedManagerInit;

    // Retreieve system font collection.
    var fcollection: ?*win32.IDWriteFontCollection = null;
    hr = wfactory.?.GetSystemFontCollection(&fcollection, TRUE);
    if (FAILED(hr)) return error.FailedLoadingSystemFonts;

    return .{
        .alloc = allocator,
        .factory = wfactory,
        .collection = fcollection,
    };
}

/// Frees up all of the font manager's resources.
pub fn deinit(self: *FontManager) void {
    if (self.collection) |c| _ = c.Release();
    if (self.factory) |f| _ = f.Release();
    self.collection = null;
    self.factory = null;
}

/// Returns the number of font families the FontManager knows about.
pub fn familyCount(self: *FontManager) u32 {
    return if (self.collection) |c| c.GetFontFamilyCount() else 0;
}

/// Finds the font family with the specified name.
pub fn findFamily(self: *FontManager, name: []const u8) ?Family {
    // TODO: Store allocated strings, so we don't need to keep allocating and
    //       freeing just to convert to utf16 and back.
    const name_l = unicode.utf8ToUtf16LeWithNull(self.alloc, name) catch return null;
    defer self.alloc.free(name_l);

    var index: u32 = 0;
    var exists: BOOL = FALSE;
    var hr = if (self.collection) |c| c.FindFamilyName(name_l, &index, &exists) else return null;
    if (FAILED(hr) or exists == FALSE) return null;

    var fontfamily: Family = .{ .manager = self };
    hr = self.collection.?.GetFontFamily(index, &fontfamily.handler);
    if (FAILED(hr)) return null;

    return fontfamily;
}
