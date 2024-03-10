const std = @import("std");
const unicode = std.unicode;
const win32 = @import("win32.zig");

const FontManager = @import("FontManager.zig");
const Font = @import("Font.zig");

const Family = @This();

manager: *FontManager,
handler: ?*win32.IDWriteFontFamily = null,
