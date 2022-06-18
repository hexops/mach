const freetype = @import("freetype");
const c = @import("c");
const Blob = @import("blob.zig").Blob;

pub const UnicodeIterator = struct {
    set: *c.hb_set_t,
    prev_codepoint: u32 = 0,

    pub fn next(self: *UnicodeIterator) ?u32 {
        var codepoint: u32 = c.HB_SET_VALUE_INVALID;
        return if (c.hb_set_next(self.set, &codepoint) > 1) b: {
            self.prev_codepoint = codepoint;
            break :b codepoint;
        } else null;
    }
};

pub const Face = struct {
    handle: *c.hb_face_t,

    pub fn init(blob: Blob, index: u16) Face {
        return .{ .handle = c.hb_face_create(blob.handle, index).? };
    }

    pub fn fromFtFace(face: freetype.Face) Face {
        return .{ .handle = c.hb_ft_face_create_referenced(face.handle).? };
    }

    pub fn initEmpty() Face {
        return .{ .handle = c.hb_face_get_empty().? };
    }

    pub fn getCount(blob: Blob) u32 {
        return c.hb_face_count(blob.handle);
    }

    pub fn deinit(self: Face) void {
        c.hb_face_destroy(self.handle);
    }

    pub fn getGlyphcount(self: Face) u32 {
        return c.hb_face_get_glyph_count(self.handle);
    }

    pub fn setGlyphcount(self: Face, count: u32) void {
        return c.hb_face_set_glyph_count(self.handle, count);
    }

    pub fn getUnitsPerEM(self: Face) u32 {
        return c.hb_face_get_upem(self.handle);
    }

    pub fn setUnitsPerEM(self: Face, upem: u32) void {
        return c.hb_face_set_upem(self.handle, upem);
    }

    pub fn setIndex(self: Face, index: u32) void {
        return c.hb_face_set_index(self.handle, index);
    }

    pub fn isImmutable(self: Face) bool {
        return c.hb_face_is_immutable(self.handle) > 0;
    }

    pub fn makeImmutable(self: Face) void {
        c.hb_face_make_immutable(self.handle);
    }

    pub fn reference(self: Face) Face {
        return .{
            .handle = c.hb_face_reference(self.handle).?,
        };
    }

    pub fn collectUnicodes(self: Face) UnicodeIterator {
        var set: *c.hb_set_t = undefined;
        c.hb_face_collect_unicodes(self.handle, set);
        return .{ .set = set };
    }
};
