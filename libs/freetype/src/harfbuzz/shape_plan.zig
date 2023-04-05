const std = @import("std");
const c = @import("c.zig");
const Buffer = @import("buffer.zig").Buffer;
const Font = @import("font.zig").Font;
const Face = @import("face.zig").Face;
const SegmentProps = @import("buffer.zig").SegmentProps;
const Feature = @import("common.zig").Feature;
const Shapers = @import("common.zig").Shapers;

pub const ShapePlan = struct {
    handle: *c.hb_shape_plan_t,

    pub fn init(face: Face, props: SegmentProps, features: ?[]const Feature, shapers: Shapers) ShapePlan {
        return .{ .handle = hb_shape_plan_create(
            face.handle,
            &props.cast(),
            if (features) |f| f.ptr else null,
            if (features) |f| @intCast(c_uint, f.len) else 0,
            shapers,
        ).? };
    }

    pub fn initCached(face: Face, props: SegmentProps, features: ?[]const Feature, shapers: Shapers) ShapePlan {
        return .{ .handle = hb_shape_plan_create_cached(
            face.handle,
            &props.cast(),
            if (features) |f| f.ptr else null,
            if (features) |f| @intCast(c_uint, f.len) else 0,
            shapers,
        ).? };
    }

    pub fn init2(face: Face, props: SegmentProps, features: ?[]const Feature, cords: []const i32, shapers: Shapers) ShapePlan {
        return .{ .handle = hb_shape_plan_create2(
            face.handle,
            &props.cast(),
            if (features) |f| f.ptr else null,
            if (features) |f| @intCast(c_uint, f.len) else 0,
            cords.ptr,
            @intCast(c_uint, cords.len),
            shapers,
        ).? };
    }

    pub fn initCached2(face: Face, props: SegmentProps, features: ?[]const Feature, cords: []const i32, shapers: Shapers) ShapePlan {
        return .{ .handle = hb_shape_plan_create_cached2(
            face.handle,
            &props.cast(),
            if (features) |f| f.ptr else null,
            if (features) |f| @intCast(c_uint, f.len) else 0,
            cords.ptr,
            @intCast(c_uint, cords.len),
            shapers,
        ).? };
    }

    pub fn deinit(self: ShapePlan) void {
        c.hb_shape_plan_destroy(self.handle);
    }

    pub fn execute(self: ShapePlan, font: Font, buffer: Buffer, features: ?[]Feature) error{ShapingFailed}!void {
        if (hb_shape_plan_execute(
            self.handle,
            font.handle,
            buffer.handle,
            if (features) |f| f.ptr else null,
            if (features) |f| @intCast(c_uint, f.len) else 0,
        ) < 1) return error.ShapingFailed;
    }

    pub fn getShaper(self: ShapePlan) [:0]const u8 {
        return std.mem.span(@ptrCast([*:0]const u8, c.hb_shape_plan_get_shaper(self.handle)));
    }
};

pub extern fn hb_shape_plan_create(face: ?*c.hb_face_t, props: [*c]const c.hb_segment_properties_t, user_features: [*c]const Feature, num_user_features: c_uint, shaper_list: [*c]const [*c]const u8) ?*c.hb_shape_plan_t;
pub extern fn hb_shape_plan_create_cached(face: ?*c.hb_face_t, props: [*c]const c.hb_segment_properties_t, user_features: [*c]const Feature, num_user_features: c_uint, shaper_list: [*c]const [*c]const u8) ?*c.hb_shape_plan_t;
pub extern fn hb_shape_plan_create2(face: ?*c.hb_face_t, props: [*c]const c.hb_segment_properties_t, user_features: [*c]const Feature, num_user_features: c_uint, coords: [*c]const c_int, num_coords: c_uint, shaper_list: [*c]const [*c]const u8) ?*c.hb_shape_plan_t;
pub extern fn hb_shape_plan_create_cached2(face: ?*c.hb_face_t, props: [*c]const c.hb_segment_properties_t, user_features: [*c]const Feature, num_user_features: c_uint, coords: [*c]const c_int, num_coords: c_uint, shaper_list: [*c]const [*c]const u8) ?*c.hb_shape_plan_t;
pub extern fn hb_shape_plan_execute(shape_plan: ?*c.hb_shape_plan_t, font: ?*c.hb_font_t, buffer: ?*c.hb_buffer_t, features: [*c]const Feature, num_features: c_uint) u8;
