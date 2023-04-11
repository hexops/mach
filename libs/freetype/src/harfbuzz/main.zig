pub usingnamespace @import("blob.zig");
pub usingnamespace @import("buffer.zig");
pub usingnamespace @import("common.zig");
pub usingnamespace @import("face.zig");
pub usingnamespace @import("font.zig");
pub usingnamespace @import("shape.zig");
pub usingnamespace @import("shape_plan.zig");
pub const c = @import("c.zig");

const std = @import("std");
test {
    std.testing.refAllDeclsRecursive(@import("blob.zig"));
    std.testing.refAllDeclsRecursive(@import("buffer.zig"));
    std.testing.refAllDeclsRecursive(@import("common.zig"));
    std.testing.refAllDeclsRecursive(@import("face.zig"));
    std.testing.refAllDeclsRecursive(@import("font.zig"));
    std.testing.refAllDeclsRecursive(@import("shape.zig"));
    std.testing.refAllDeclsRecursive(@import("shape_plan.zig"));
}
