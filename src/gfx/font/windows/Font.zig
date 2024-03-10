const std = @import("std");
const unicode = std.unicode;
const win32 = @import("win32.zig");

const FontManager = @import("FontManager.zig");
const Family = @import("Family.zig");

const Font = @This();

manager: *FontManager,
font: ?*win32.IDWriteFont = null,
