const std = @import("std");

const mach = @import("../main.zig");
const testing = mach.testing;
const math = mach.math;
const vec = @import("vec.zig");

fn maxDim(v: math.Vec3) u32 {
    if (v.v[0] > v.v[1]) {
        if (v.v[0] > v.v[2]) {
            return 0;
        } else {
            return 2;
        }
    } else if (v.v[1] > v.v[2]) {
        return 1;
    } else {
        return 0;
    }
}

pub const RayHit = packed struct { u: f32, v: f32, w: f32, t: f32 };

pub const Ray = struct {
    origin: math.Vec3,
    direction: math.Vec3,

    // Algorithm based on:
    // https://www.jcgt.org/published/0002/01/05/
    /// Check for collision of a ray and a triangle in 3D space.
    /// Triangle winding, which determines front- and backface of
    /// the given triangle, matters if backface culling is to be
    /// enabled. Without backface culling it does not matter.
    /// On hit, will return a RayHit which contains distance t
    /// and barycentric coordinates.
    pub fn triangleIntersect(
        ray: *const Ray,
        va: *const math.Vec3,
        vb: *const math.Vec3,
        vc: *const math.Vec3,
        backface_culling: bool,
    ) ?RayHit {
        var kz: u32 = maxDim(math.vec3(
            @abs(ray.direction.v[0]),
            @abs(ray.direction.v[1]),
            @abs(ray.direction.v[2]),
        ));
        var kx: u32 = kz + 1;
        if (kx == 3)
            kx = 0;
        var ky: u32 = kx + 1;
        if (ky == 3)
            ky = 0;

        if (ray.direction.v[kz] < 0.0) {
            const tmp = kx;
            kx = ky;
            ky = tmp;
        }

        const sx: f32 = ray.direction.v[kx] / ray.direction.v[kz];
        const sy: f32 = ray.direction.v[ky] / ray.direction.v[kz];
        const sz: f32 = 1.0 / ray.direction.v[kz];

        const a: @Vector(3, f32) = va.v - ray.origin.v;
        const b: @Vector(3, f32) = vb.v - ray.origin.v;
        const c: @Vector(3, f32) = vc.v - ray.origin.v;

        const ax: f32 = a[kx] - sx * a[kz];
        const ay: f32 = a[ky] - sy * a[kz];
        const bx: f32 = b[kx] - sx * b[kz];
        const by: f32 = b[ky] - sy * b[kz];
        const cx: f32 = c[kx] - sx * c[kz];
        const cy: f32 = c[ky] - sy * c[kz];

        var u: f32 = cx * by - cy * bx;
        var v: f32 = ax * cy - ay * cx;
        var w: f32 = bx * ay - by * ax;

        // Double precision fallback
        if (u == 0.0 or v == 0.0 or w == 0.0) {
            var cxby: f64 = @as(f64, @floatCast(cx)) * @as(f64, @floatCast(by));
            var cybx: f64 = @as(f64, @floatCast(cy)) * @as(f64, @floatCast(bx));
            u = @floatCast(cxby - cybx);

            var axcy: f64 = @as(f64, @floatCast(ax)) * @as(f64, @floatCast(cy));
            var aycx: f64 = @as(f64, @floatCast(ay)) * @as(f64, @floatCast(cx));
            v = @floatCast(axcy - aycx);

            var bxay: f64 = @as(f64, @floatCast(bx)) * @as(f64, @floatCast(ay));
            var byax: f64 = @as(f64, @floatCast(by)) * @as(f64, @floatCast(ax));
            v = @floatCast(bxay - byax);
        }

        if (backface_culling) {
            if (u < 0.0 or v < 0.0 or w < 0.0)
                return null; // no hit
        } else {
            if ((u < 0.0 or v < 0.0 or w < 0.0) and
                (u > 0.0 or v > 0.0 or w > 0.0))
                return null; // no hit
        }

        var det: f32 = u + v + w;
        if (det == 0.0)
            return null; // no hit

        // Calculate scaled z-coordinates of vertices and use them to calculate
        // the hit distance
        const az: f32 = sz * a[kz];
        const bz: f32 = sz * b[kz];
        const cz: f32 = sz * c[kz];
        var t: f32 = u * az + v * bz + w * cz;

        // hit.t counts as a previous hit for backface culling, in which
        // case triangle behind will no longer be considered a hit
        var hit: RayHit = RayHit{
            .u = undefined,
            .v = undefined,
            .w = undefined,
            .t = std.math.inf(f32),
        };

        if (backface_culling) {
            if ((t < 0.0) or (t > hit.t * det))
                return null; // no hit
        } else {
            if (det < 0) {
                t = -t;
                det = -det;
            }
            if ((t < 0.0) or (t > hit.t * det))
                return null; // no hit
        }

        // Normalize u, v, w and t
        const rcp_det = 1.0 / det;
        hit.u = u * rcp_det;
        hit.v = v * rcp_det;
        hit.w = w * rcp_det;
        hit.t = t * rcp_det;

        return hit;
    }
};

test "triIntersect_basic_frontface_bc_hit" {
    const a: math.Vec3 = math.vec3(0, 0, 0);
    const b: math.Vec3 = math.vec3(1, 0, 0);
    const c: math.Vec3 = math.vec3(0, 1, 0);
    const ray0: Ray = Ray{
        .origin = math.vec3(0.1, 0.1, 1),
        .direction = math.vec3(0.1, 0.1, -1),
    };

    const result: RayHit = ray0.triangleIntersect(
        &a,
        &b,
        &c,
        true,
    ).?;

    const expected_t: f32 = 1;
    const expected_u: f32 = 0.6;
    const expected_v: f32 = 0.2;
    const expected_w: f32 = 0.2;
    try testing.expect(f32, expected_t).eql(result.t);
    try testing.expect(f32, expected_u).eql(result.u);
    try testing.expect(f32, expected_v).eql(result.v);
    try testing.expect(f32, expected_w).eql(result.w);
}

test "triIntersect_basic_backface_no_bc_hit" {
    const a: math.Vec3 = math.vec3(0, 0, 0);
    const b: math.Vec3 = math.vec3(1, 0, 0);
    const c: math.Vec3 = math.vec3(0, 1, 0);
    const ray0: Ray = Ray{
        .origin = math.vec3(0.1, 0.1, 1),
        .direction = math.vec3(0.1, 0.1, -1),
    };

    // Reverse winding from previous test
    const result: RayHit = ray0.triangleIntersect(
        &a,
        &c,
        &b,
        false,
    ).?;

    const expected_t: f32 = 1;
    const expected_u: f32 = -0.6;
    const expected_v: f32 = -0.2;
    const expected_w: f32 = -0.2;
    try testing.expect(f32, expected_t).eql(result.t);
    try testing.expect(f32, expected_u).eql(result.u);
    try testing.expect(f32, expected_v).eql(result.v);
    try testing.expect(f32, expected_w).eql(result.w);
}

test "triIntersect_basic_backface_bc_miss" {
    const a: math.Vec3 = math.vec3(0, 0, 0);
    const b: math.Vec3 = math.vec3(1, 0, 0);
    const c: math.Vec3 = math.vec3(0, 1, 0);
    const ray0: Ray = Ray{
        .origin = math.vec3(0.1, 0.1, 1),
        .direction = math.vec3(0.1, 0.1, -1),
    };

    // Reverse winding from previous test
    const result: ?RayHit = ray0.triangleIntersect(
        &a,
        &c,
        &b,
        true,
    );

    try testing.expect(?RayHit, null).eql(result);
}
