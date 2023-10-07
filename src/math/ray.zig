const std = @import("std");

const mach = @import("../main.zig");
const testing = mach.testing;
const math = mach.math;
const vec = @import("vec.zig");

// A Ray in three-dimensional space
pub fn Ray(comptime Vec3P: type) type {
    // Floating point precision, will be either f16, f32, or f64
    const P: type = Vec3P.T;

    // Adaptive scaling of the fallback precision for the ray-triangle
    // intersection implementation.
    const PP: type = switch (P) {
        f16 => f32,
        f32 => f64,
        f64 => f128,
        else => @compileError("Expected f16, f32, f64, found '" ++
            @typeName(P) ++ "'"),
    };

    return extern struct {
        origin: Vec3P,
        direction: Vec3P,

        /// A ray hit for which xyz represent the barycentric coordinates
        /// and w represents hit distance t
        pub const Hit = math.Vec4;

        pub usingnamespace switch (Vec3P) {
            math.Vec3, math.Vec3h, math.Vec3d => struct {
                // Determine the 3D vector dimension with the largest scalar
                // value
                fn maxDim(v: [3]P) u8 {
                    if (v[0] > v[1]) {
                        if (v[0] > v[2]) {
                            return 0;
                        } else {
                            return 2;
                        }
                    } else if (v[1] > v[2]) {
                        return 1;
                    } else {
                        return 0;
                    }
                }

                // Algorithm based on:
                // https://www.jcgt.org/published/0002/01/05/
                /// Check for collision of a ray and a triangle in 3D space.
                /// Triangle winding, which determines front- and backface of
                /// the given triangle, matters if backface culling is to be
                /// enabled. Without backface culling it does not matter.
                /// On hit, will return a RayHit which contains distance t
                /// and barycentric coordinates.
                pub inline fn triangleIntersect(
                    ray: *const math.Ray,
                    va: *const Vec3P,
                    vb: *const Vec3P,
                    vc: *const Vec3P,
                    backface_culling: bool,
                ) ?Hit {
                    var kz: u8 = maxDim(math.vec3(
                        @abs(ray.direction.v[0]),
                        @abs(ray.direction.v[1]),
                        @abs(ray.direction.v[2]),
                    ));
                    var kx: u8 = kz + 1;
                    if (kx == 3)
                        kx = 0;
                    var ky: u8 = kx + 1;
                    if (ky == 3)
                        ky = 0;

                    if (ray.direction.v[kz] < 0.0) {
                        const tmp = kx;
                        kx = ky;
                        ky = tmp;
                    }

                    const sx: P = ray.direction.v[kx] / ray.direction.v[kz];
                    const sy: P = ray.direction.v[ky] / ray.direction.v[kz];
                    const sz: P = 1.0 / ray.direction.v[kz];

                    const a: @Vector(3, P) = va.v - ray.origin.v;
                    const b: @Vector(3, P) = vb.v - ray.origin.v;
                    const c: @Vector(3, P) = vc.v - ray.origin.v;

                    const ax: P = a[kx] - sx * a[kz];
                    const ay: P = a[ky] - sy * a[kz];
                    const bx: P = b[kx] - sx * b[kz];
                    const by: P = b[ky] - sy * b[kz];
                    const cx: P = c[kx] - sx * c[kz];
                    const cy: P = c[ky] - sy * c[kz];

                    var u: P = cx * by - cy * bx;
                    var v: P = ax * cy - ay * cx;
                    var w: P = bx * ay - by * ax;

                    // Double precision fallback
                    if (u == 0.0 or v == 0.0 or w == 0.0) {
                        const cxby: PP = @as(PP, @floatCast(cx)) *
                            @as(PP, @floatCast(by));
                        var cybx: PP = @as(PP, @floatCast(cy)) *
                            @as(PP, @floatCast(bx));
                        u = @floatCast(cxby - cybx);

                        var axcy: PP = @as(PP, @floatCast(ax)) *
                            @as(PP, @floatCast(cy));
                        var aycx: PP = @as(PP, @floatCast(ay)) *
                            @as(PP, @floatCast(cx));
                        v = @floatCast(axcy - aycx);

                        var bxay: PP = @as(PP, @floatCast(bx)) *
                            @as(PP, @floatCast(ay));
                        var byax: PP = @as(PP, @floatCast(by)) *
                            @as(PP, @floatCast(ax));
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

                    var det: P = u + v + w;
                    if (det == 0.0)
                        return null; // no hit

                    // Calculate scaled z-coordinates of vertices and use them to calculate
                    // the hit distance
                    const az: P = sz * a[kz];
                    const bz: P = sz * b[kz];
                    const cz: P = sz * c[kz];
                    var t: P = u * az + v * bz + w * cz;

                    // hit.t counts as a previous hit for backface culling, in which
                    // case triangle behind will no longer be considered a hit
                    // Since Ray.Hit is represented by a Vec4, t is the last element
                    // of that vector
                    var hit: Hit = math.vec4(
                        undefined,
                        undefined,
                        undefined,
                        std.math.inf(f32),
                    );

                    if (backface_culling) {
                        if ((t < 0.0) or (t > hit.v[3] * det))
                            return null; // no hit
                    } else {
                        if (det < 0) {
                            t = -t;
                            det = -det;
                        }
                        if ((t < 0.0) or (t > hit.v[3] * det))
                            return null; // no hit
                    }

                    // Normalize u, v, w and t
                    const rcp_det = 1.0 / det;
                    hit.v[0] = u * rcp_det;
                    hit.v[1] = v * rcp_det;
                    hit.v[2] = w * rcp_det;
                    hit.v[3] = t * rcp_det;

                    return hit;
                }
            },
            else => @compileError("Expected Vec3, Vec3h, or Vec3d, found '" ++
                @typeName(Vec3P) ++ "'"),
        };
    };
}

test "triangleIntersect_basic_frontface_bc_hit" {
    const a: math.Vec3 = math.vec3(0, 0, 0);
    const b: math.Vec3 = math.vec3(1, 0, 0);
    const c: math.Vec3 = math.vec3(0, 1, 0);
    const ray0: math.Ray = math.Ray{
        .origin = math.vec3(0.1, 0.1, 1),
        .direction = math.vec3(0.1, 0.1, -1),
    };

    const result: math.Ray.Hit = ray0.triangleIntersect(
        &a,
        &b,
        &c,
        true,
    ).?;

    const expected_t: f32 = 1;
    const expected_u: f32 = 0.6;
    const expected_v: f32 = 0.2;
    const expected_w: f32 = 0.2;
    try testing.expect(f32, expected_u).eql(result.v[0]);
    try testing.expect(f32, expected_v).eql(result.v[1]);
    try testing.expect(f32, expected_w).eql(result.v[2]);
    try testing.expect(f32, expected_t).eql(result.v[3]);
}

test "triangleIntersect_basic_backface_no_bc_hit" {
    const a: math.Vec3 = math.vec3(0, 0, 0);
    const b: math.Vec3 = math.vec3(1, 0, 0);
    const c: math.Vec3 = math.vec3(0, 1, 0);
    const ray0: math.Ray = math.Ray{
        .origin = math.vec3(0.1, 0.1, 1),
        .direction = math.vec3(0.1, 0.1, -1),
    };

    // Reverse winding from previous test
    const result: math.Ray.Hit = ray0.triangleIntersect(
        &a,
        &c,
        &b,
        false,
    ).?;

    const expected_t: f32 = 1;
    const expected_u: f32 = -0.6;
    const expected_v: f32 = -0.2;
    const expected_w: f32 = -0.2;
    try testing.expect(f32, expected_u).eql(result.v[0]);
    try testing.expect(f32, expected_v).eql(result.v[1]);
    try testing.expect(f32, expected_w).eql(result.v[2]);
    try testing.expect(f32, expected_t).eql(result.v[3]);
}

test "triangleIntersect_basic_backface_bc_miss" {
    const a: math.Vec3 = math.vec3(0, 0, 0);
    const b: math.Vec3 = math.vec3(1, 0, 0);
    const c: math.Vec3 = math.vec3(0, 1, 0);
    const ray0: math.Ray = math.Ray{
        .origin = math.vec3(0.1, 0.1, 1),
        .direction = math.vec3(0.1, 0.1, -1),
    };

    // Reverse winding from previous test
    const result: ?math.Ray.Hit = ray0.triangleIntersect(
        &a,
        &c,
        &b,
        true,
    );

    try testing.expect(?math.Ray.Hit, null).eql(result);
}
