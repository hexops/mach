const std = @import("std");
const mach = @import("../../main.zig");
const testing = mach.testing;
const math = mach.math;
const vec2 = math.vec2;
const Vec2 = math.Vec2;

pub const Font = FontInterface(if (@import("builtin").cpu.arch == .wasm32) @panic("TODO: implement wasm/Font.zig") else @import("native/Font.zig"));

pub const TextRun = TextRunInterface(if (@import("builtin").cpu.arch == .wasm32) @panic("TODO: implement wasm/TextRun.zig") else @import("native/TextRun.zig"));

fn FontInterface(comptime T: type) type {
    assertDecl(T, "initBytes", fn (font_bytes: []const u8) anyerror!T);
    assertDecl(T, "shape", fn (f: *const T, r: *TextRun) anyerror!void);
    assertDecl(T, "render", fn (f: *T, allocator: std.mem.Allocator, glyph_index: u32, opt: RenderOptions) anyerror!RenderedGlyph);
    assertDecl(T, "deinit", fn (*T, allocator: std.mem.Allocator) void);
    return T;
}

fn TextRunInterface(comptime T: type) type {
    assertField(T, "font_size_px", f32);
    assertField(T, "px_density", u8);
    assertDecl(T, "init", fn () anyerror!T);
    assertDecl(T, "addText", fn (s: *const T, []const u8) void);
    assertDecl(T, "next", fn (s: *T) ?Glyph);
    assertDecl(T, "deinit", fn (s: *const T) void);
    return T;
}

fn assertDecl(comptime T: anytype, comptime name: []const u8, comptime Decl: type) void {
    if (!@hasDecl(T, name)) @compileError("Interface missing declaration: " ++ name ++ @typeName(Decl));
    const Found = @TypeOf(@field(T, name));
    if (Found != Decl) @compileError("Interface decl '" ++ name ++ "'\n\texpected type: " ++ @typeName(Decl) ++ "\n\t   found type: " ++ @typeName(Found));
}

fn assertField(comptime T: anytype, comptime name: []const u8, comptime Field: type) void {
    if (!@hasField(T, name)) @compileError("Interface missing field: ." ++ name ++ @typeName(Field));
    const Found = @TypeOf(@field(@as(T, undefined), name));
    if (Found != Field) @compileError("Interface field '" ++ name ++ "'\n\texpected type: " ++ @typeName(Field) ++ "\n\t   found type: " ++ @typeName(Found));
}

/// The number of pixels per point, e.g. a 12pt font em box size multiplied by this number tells a
/// the em box size is 16px.
pub const px_per_pt = 4.0 / 3.0;

pub const Glyph = struct {
    glyph_index: u32,
    cluster: u32,
    advance: Vec2,
    offset: Vec2,

    // TODO: https://github.com/hexops/mach/issues/1048
    // TODO: https://github.com/hexops/mach/issues/1049
    //
    // pub fn eql(a: Glyph, b: Glyph) bool {
    //     if (a.glyph_index != b.glyph_index) return false;
    //     if (a.cluster != b.cluster) return false;
    //     // TODO: add Vec2.eql method
    //     if (a.advance.v[0] != b.advance.v[0] or a.advance.v[1] != b.advance.v[1]) return false;
    //     if (a.offset.v[0] != b.offset.v[0] or a.offset.v[1] != b.offset.v[1]) return false;
    //     return true;
    // }
};

pub const RGBA32 = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const RenderOptions = struct {
    font_size_px: f32,
};

pub const RenderedGlyph = struct {
    bitmap: ?[]const RGBA32,
    width: u32,
    height: u32,
};

test {
    std.testing.refAllDeclsRecursive(@This());

    // Load a font
    const allocator = std.testing.allocator;
    const font_bytes = @import("font-assets").fira_sans_regular_ttf;
    var font = try Font.initBytes(font_bytes);
    defer font.deinit(allocator);

    // Create a text shaper
    var run = try TextRun.init();
    run.font_size_px = 12 * px_per_pt;
    run.px_density = 1;

    defer run.deinit();

    const text = "h👩‍🚀️ello world!";
    run.addText(text);
    try font.shape(&run);

    // Test rendering the first glyph
    const rendered = try font.render(allocator, 176, .{ .font_size_px = run.font_size_px });
    _ = rendered;

    // TODO: https://github.com/hexops/mach/issues/1048
    // TODO: https://github.com/hexops/mach/issues/1049
    //
    // try testing.expect(Glyph, .{
    //     .glyph_index = 176,
    //     .cluster = 0,
    //     .advance = vec2(7.03, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 0,
    //     .cluster = 1,
    //     .advance = vec2(7.99, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 3,
    //     .cluster = 1,
    //     .advance = vec2(0.00, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 0,
    //     .cluster = 1,
    //     .advance = vec2(7.99, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 3,
    //     .cluster = 1,
    //     .advance = vec2(0.00, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 160,
    //     .cluster = 15,
    //     .advance = vec2(6.60, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 197,
    //     .cluster = 16,
    //     .advance = vec2(3.52, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 197,
    //     .cluster = 17,
    //     .advance = vec2(3.39, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 211,
    //     .cluster = 18,
    //     .advance = vec2(7.01, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 3,
    //     .cluster = 19,
    //     .advance = vec2(3.18, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 254,
    //     .cluster = 20,
    //     .advance = vec2(8.48, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 211,
    //     .cluster = 21,
    //     .advance = vec2(7.01, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 226,
    //     .cluster = 22,
    //     .advance = vec2(4.63, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 197,
    //     .cluster = 23,
    //     .advance = vec2(3.39, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 156,
    //     .cluster = 24,
    //     .advance = vec2(7.18, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);
    // try testing.expect(Glyph, .{
    //     .glyph_index = 988,
    //     .cluster = 25,
    //     .advance = vec2(2.89, 0.00),
    //     .offset = vec2(0.00, 0.00),
    // }).eql(run.next().?);

    // var cluster_start: usize = 0;
    // while (run.next()) |glyph| {
    //     if (glyph.cluster != cluster_start) {
    //         const str = text[cluster_start..glyph.cluster];
    //         cluster_start = glyph.cluster;
    //         std.debug.print("^ string: '{s}' (hex: {s})\n", .{ str, std.fmt.fmtSliceHexUpper(str) });
    //     }
    //     std.debug.print(".{{ .glyph_index={}, .cluster={}, .advance=vec2({d:.2},{d:.2}), .offset=vec2({d:.2},{d:.2}), }}\n", .{
    //         glyph.glyph_index,
    //         glyph.cluster,
    //         glyph.advance.x(),
    //         glyph.advance.y(),
    //         glyph.offset.x(),
    //         glyph.offset.y(),
    //     });
    // }
}
