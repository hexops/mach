const mach = @import("../main.zig");
const testing = mach.testing;
const math = mach.math;
const vec = @import("vec.zig");

// A Ray in three-dimensional space
pub fn Ray3(comptime Scalar: type) type {
    const Vec3P = vec.Vec3(Scalar);

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

    const Vec4P = switch (Vec3P) {
        math.Vec3 => math.Vec4,
        math.Vec3h => math.Vec4h,
        math.Vec3d => math.Vec4d,
        else => @compileError("Expected Vec3, Vec3h, Vec3d, found '" ++
            @typeName(Vec3P) ++ "'"),
    };

    return extern struct {
        origin: Vec3P,
        direction: Vec3P,

        /// A ray hit for which xyz represent the barycentric coordinates
        /// and w represents hit distance t
        pub const Hit = Vec4P;

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
                return 2;
            }
        }

        // Algorithm based on:
        // https://www.jcgt.org/published/0002/01/05/
        /// Check for collision of a ray and a triangle in 3D space.
        /// Triangle winding, which determines front- and backface of
        /// the given triangle, matters if backface culling is to be
        /// enabled. Without backface culling it does not matter for
        /// hit detection, however the barycentric coordinates will
        /// be negative in case of a backface hit.
        /// On hit, will return a RayHit which contains distance t
        /// and barycentric coordinates.
        pub inline fn triangleIntersect(
            ray: *const Ray3(P),
            va: *const Vec3P,
            vb: *const Vec3P,
            vc: *const Vec3P,
            backface_culling: bool,
        ) ?Hit {
            const kz: u8 = maxDim([3]P{
                @abs(ray.direction.v[0]),
                @abs(ray.direction.v[1]),
                @abs(ray.direction.v[2]),
            });
            if (ray.direction.v[kz] == 0.0) {
                return null;
            }
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
            const w: P = bx * ay - by * ax;

            // Double precision fallback
            if (u == 0.0 or v == 0.0 or w == 0.0) {
                const cxby: PP = @as(PP, @floatCast(cx)) *
                    @as(PP, @floatCast(by));
                const cybx: PP = @as(PP, @floatCast(cy)) *
                    @as(PP, @floatCast(bx));
                u = @floatCast(cxby - cybx);

                const axcy: PP = @as(PP, @floatCast(ax)) *
                    @as(PP, @floatCast(cy));
                const aycx: PP = @as(PP, @floatCast(ay)) *
                    @as(PP, @floatCast(cx));
                v = @floatCast(axcy - aycx);

                const bxay: PP = @as(PP, @floatCast(bx)) *
                    @as(PP, @floatCast(ay));
                const byax: PP = @as(PP, @floatCast(by)) *
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

            // Calculate scaled z-coordinates of vertices and use them
            // to calculate the hit distance
            const az: P = sz * a[kz];
            const bz: P = sz * b[kz];
            const cz: P = sz * c[kz];
            var t: P = u * az + v * bz + w * cz;

            // hit.t counts as a previous hit for backface culling,
            // in which case triangle behind will no longer be
            // considered a hit.
            // Since Ray.Hit is represented by a Vec4, t is the last
            // element of that vector
            var hit: Hit = Vec4P.init(
                undefined,
                undefined,
                undefined,
                math.inf(f32),
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

test "triangleIntersect_precise_frontface_bc_hit_f32" {
    const a: math.Vec3 = math.vec3(
        3164.91,
        3559.55,
        3044.54,
    );
    const b: math.Vec3 = math.vec3(
        1011.92,
        3113.34,
        3674.56,
    );
    const c: math.Vec3 = math.vec3(
        503.804,
        2311.16,
        2449.58,
    );
    const ray0: math.Ray = math.Ray{
        .origin = math.vec3(
            293.293,
            264.527,
            225.465,
        ),
        .direction = math.vec3(
            0.439063,
            0.652555,
            0.617573,
        ),
    };

    const result: math.Ray.Hit = ray0.triangleIntersect(
        &a,
        &b,
        &c,
        true,
    ).?;

    const expected_t: f32 = 4606.98;
    const expected_u: f32 = 0.643925;
    const expected_v: f32 = 0.194228;
    const expected_w: f32 = 0.161846;
    try testing.expect(f32, expected_u).eqlApprox(result.v[0], 1e-5);
    try testing.expect(f32, expected_v).eqlApprox(result.v[1], 1e-5);
    try testing.expect(f32, expected_w).eqlApprox(result.v[2], 1e-5);
    try testing.expect(f32, expected_t).eqlApprox(result.v[3], 1e-2);
}

test "triangleIntersect_precise_frontface_bc_hit_f64" {
    const a: math.Vec3d = math.vec3d(
        2371.01,
        3208.12,
        1570.04,
    );
    const b: math.Vec3d = math.vec3d(
        1412.2,
        2978.36,
        1501.33,
    );
    const c: math.Vec3d = math.vec3d(
        2520.99,
        3323.93,
        1567.18,
    );
    const ray0: math.Rayd = math.Rayd{
        .origin = math.vec3d(
            246.713,
            279.646,
            180.443,
        ),
        .direction = math.vec3d(
            0.497991,
            0.782698,
            0.373349,
        ),
    };

    const result: math.Rayd.Hit = ray0.triangleIntersect(
        &a,
        &b,
        &c,
        true,
    ).?;

    const expected_t: f64 = 3660.17;
    const expected_u: f64 = 0.56102;
    const expected_v: f64 = 0.33136;
    const expected_w: f64 = 0.10761;
    try testing.expect(f64, expected_u).eqlApprox(result.v[0], 1e-4);
    try testing.expect(f64, expected_v).eqlApprox(result.v[1], 1e-4);
    try testing.expect(f64, expected_w).eqlApprox(result.v[2], 1e-4);
    try testing.expect(f64, expected_t).eqlApprox(result.v[3], 1e-2);
}

test "triangleIntersect_ray_no_direction" {
    const a: math.Vec3 = math.vec3(0, 0, 0);
    const b: math.Vec3 = math.vec3(1, 0, 0);
    const c: math.Vec3 = math.vec3(0, 1, 0);
    const ray: math.Ray = math.Ray{
        .origin = math.vec3(0.1, 0.1, 1),
        .direction = math.vec3(0.0, 0.0, 0.0),
    };

    const result = ray.triangleIntersect(
        &a,
        &b,
        &c,
        true,
    );

    try testing.expect(?math.Ray.Hit, null).eql(result);
}

test "triangleIntersect_ray_no_x_y_direction" {
    const a: math.Vec3 = math.vec3(-1, 1, 0);
    const b: math.Vec3 = math.vec3(-1, -1, 0);
    const c: math.Vec3 = math.vec3(1, -1, 0);
    const ray: math.Ray = math.Ray{
        .origin = math.vec3(0.0, 0.0, 1),
        .direction = math.vec3(0.0, 0.0, -1),
    };

    const result = ray.triangleIntersect(
        &a,
        &b,
        &c,
        true,
    ).?;

    const expected_t: f64 = 1;
    const expected_u: f64 = 0.3333;
    const expected_v: f64 = 0.3333;
    const expected_w: f64 = 0.3333;
    try testing.expect(f64, expected_u).eqlApprox(result.v[0], 1e-4);
    try testing.expect(f64, expected_v).eqlApprox(result.v[1], 1e-4);
    try testing.expect(f64, expected_w).eqlApprox(result.v[2], 1e-4);
    try testing.expect(f64, expected_t).eqlApprox(result.v[3], 1e-2);
}

test "triangleIntersect_ray_no_y_z_direction" {
    const a: math.Vec3 = math.vec3(0, -1, 1);
    const b: math.Vec3 = math.vec3(0, -1, -1);
    const c: math.Vec3 = math.vec3(0, 1, -1);
    const ray: math.Ray = math.Ray{
        .origin = math.vec3(1, 0.0, 0.0),
        .direction = math.vec3(-1, 0.0, 0.0),
    };

    const result = ray.triangleIntersect(
        &a,
        &b,
        &c,
        true,
    ).?;
    const expected_t: f64 = 1;
    const expected_u: f64 = 0.3333;
    const expected_v: f64 = 0.3333;
    const expected_w: f64 = 0.3333;
    try testing.expect(f64, expected_u).eqlApprox(result.v[0], 1e-4);
    try testing.expect(f64, expected_v).eqlApprox(result.v[1], 1e-4);
    try testing.expect(f64, expected_w).eqlApprox(result.v[2], 1e-4);
    try testing.expect(f64, expected_t).eqlApprox(result.v[3], 1e-2);
}

test "triangleIntersect_ray_no_x_z_direction" {
    const a: math.Vec3 = math.vec3(-1, 0, 1);
    const b: math.Vec3 = math.vec3(-1, 0, -1);
    const c: math.Vec3 = math.vec3(1, 0, -1);
    const ray: math.Ray = math.Ray{
        .origin = math.vec3(0.0, -1.0, 0.0),
        .direction = math.vec3(0.0, 1.0, 0.0),
    };

    const result = ray.triangleIntersect(
        &a,
        &b,
        &c,
        true,
    ).?;
    const expected_t: f64 = 1;
    const expected_u: f64 = 0.3333;
    const expected_v: f64 = 0.3333;
    const expected_w: f64 = 0.3333;
    try testing.expect(f64, expected_u).eqlApprox(result.v[0], 1e-4);
    try testing.expect(f64, expected_v).eqlApprox(result.v[1], 1e-4);
    try testing.expect(f64, expected_w).eqlApprox(result.v[2], 1e-4);
    try testing.expect(f64, expected_t).eqlApprox(result.v[3], 1e-2);
}
