const c = @import("c");
const Face = @import("face.zig").Face;
const Buffer = @import("buffer.zig").Buffer;
const Feature = @import("common.zig").Feature;
const SegmentProps = @import("buffer.zig").SegmentProps;

pub const Font = struct {
    handle: *c.hb_font_t,

    pub fn init(face: Face) Font {
        return .{ .handle = c.hb_font_create(face.handle).? };
    }

    pub fn createSubFont(self: Font) Font {
        return .{
            .handle = c.hb_font_create_sub_font(self.handle).?,
        };
    }

    pub fn deinit(self: Font) void {
        c.hb_font_destroy(self.handle);
    }

    pub fn getFace(self: Font) Face {
        return .{ .handle = c.hb_font_get_face(self.handle).? };
    }

    pub fn getGlyph(self: Font, unicode: u32, variation_selector: u32) ?u32 {
        var g: u32 = 0;
        return if (c.hb_font_get_glyph(self.handle, unicode, variation_selector, &g) > 0)
            g
        else
            null;
    }

    pub fn getParent(self: Font) ?Font {
        return Font{ .handle = c.hb_font_get_parent(self.handle) orelse return null };
    }

    pub fn getPPEM(self: Font) @Vector(2, u32) {
        var x: u32 = 0;
        var y: u32 = 0;
        c.hb_font_get_ppem(self.handle, &@intCast(c_uint, x), &@intCast(c_uint, y));
        return @Vector(2, u32){ x, y };
    }

    pub fn getPTEM(self: Font) f32 {
        return c.hb_font_get_ptem(self.handle);
    }

    pub fn getScale(self: Font) @Vector(2, u32) {
        var x: u32 = 0;
        var y: u32 = 0;
        c.hb_font_get_scale(self.handle, &@intCast(c_int, x), &@intCast(c_int, y));
        return @Vector(2, u32){ x, y };
    }

    pub fn setFace(self: Font, face: Face) void {
        return c.hb_font_set_face(self.handle, face.handle);
    }

    pub fn shape(self: Font, buf: Buffer, features: ?[]const Feature) void {
        hb_shape(
            self.handle,
            buf.handle,
            if (features) |f| f.ptr else null,
            if (features) |f| @intCast(c_uint, f.len) else 0,
        );
    }

    pub fn shapeFull(self: Font, buf: Buffer, features: ?[]const Feature, shapers: []const []const u8) error{ShapingFailed}!void {
        if (hb_shape_full(
            self.handle,
            buf.handle,
            if (features) |f| f.ptr else null,
            if (features) |f| @intCast(c_uint, f.len) else 0,
            @ptrCast([*c]const [*c]const u8, shapers),
        ) < 1) return error.ShapingFailed;
    }
};

pub extern fn hb_shape(font: ?*c.hb_font_t, buffer: ?*c.hb_buffer_t, features: [*c]const Feature, num_features: c_uint) void;
pub extern fn hb_shape_full(font: ?*c.hb_font_t, buffer: ?*c.hb_buffer_t, features: [*c]const Feature, num_features: c_uint, shaper_list: [*c]const [*c]const u8) u8;
