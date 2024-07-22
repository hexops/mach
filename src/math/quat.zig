const mach = @import("../main.zig");
const testing = mach.testing;
const math = mach.math;
const vec = @import("vec.zig");
const mat = @import("mat.zig");

pub fn Quat(comptime Scalar: type) type {
    return extern struct {
        v: vec.Vec4(Scalar),

        /// The scalar type of this matrix, e.g. Mat3x3.T == f32
        pub const T = Vec.T;

        /// The underlying Vec type, e.g. math.Vec4, math.Vec4h, math.Vec4d
        pub const Vec = vec.Vec4(Scalar);

        /// The Vec type used to represent axes, e.g. math.Vec3
        pub const Axis = vec.Vec3(Scalar);

        /// Creates a quaternion from the given x, y, z, and w values
        pub inline fn init(x: T, y: T, z: T, w: T) Quat(T) {
            return .{ .v = math.vec4(x, y, z, w) };
        }

        /// Returns the identity quaternion.
        pub inline fn identity() Quat(T) {
            return init(0, 0, 0, 1);
        }

        /// Returns the inverse of the quaternion.
        pub inline fn inverse(q: *const Quat(T)) Quat(T) {
            const s = 1 / q.len2();
            return init(-q.v.x() * s, -q.v.y() * s, -q.v.z() * s, q.v.w() * s);
        }

        /// Creates a Quaternion based on the given `axis` and `angle`, and returns it.
        pub inline fn fromAxisAngle(axis: Axis, angle: T) Quat(T) {
            const halfAngle = angle * 0.5;
            const s = math.sin(halfAngle);

            return init(s * axis.x(), s * axis.y(), s * axis.z(), math.cos(halfAngle));
        }

        /// Calculates the angle between two given quaternions.
        pub inline fn angleBetween(a: *const Quat(T), b: *const Quat(T)) T {
            const d = Vec.dot(&a.v, &b.v);
            return math.acos(2 * d * d - 1);
        }

        /// Multiplies two quaternions
        pub inline fn mul(a: *const Quat(T), b: *const Quat(T)) Quat(T) {
            const ax = a.v.x();
            const ay = a.v.y();
            const az = a.v.z();
            const aw = a.v.w();
            const bx = b.v.x();
            const by = b.v.y();
            const bz = b.v.z();
            const bw = b.v.w();

            const x = aw * bx + ax * bw + ay * bz - az * by;
            const y = aw * by + ay * bw + az * bx - ax * bz;
            const z = aw * bz + az * bw + ax * by - ay * bx;
            const w = aw * bw - ax * bx - ay * by - az * bz;

            return init(x, y, z, w);
        }

        /// Adds two quaternions
        pub inline fn add(a: *const Quat(T), b: *const Quat(T)) Quat(T) {
            return init(a.v.x() + b.v.x(), a.v.y() + b.v.y(), a.v.z() + b.v.z(), a.v.w() + b.v.w());
        }

        /// Subtracts two quaternions
        pub inline fn sub(a: *const Quat(T), b: *const Quat(T)) Quat(T) {
            return init(a.v.x() - b.v.x(), a.v.y() - b.v.y(), a.v.z() - b.v.z(), a.v.w() - b.v.w());
        }

        /// Multiplies a Quaternion by a scalar
        pub inline fn mulScalar(q: *const Quat(T), s: T) Quat(T) {
            return init(q.v.x() * s, q.v.y() * s, q.v.z() * s, q.v.w() * s);
        }

        /// Divides a Quaternion by a scalar
        pub inline fn divScalar(q: *const Quat(T), s: T) Quat(T) {
            return init(q.v.x() / s, q.v.y() / s, q.v.z() / s, q.v.w() / s);
        }

        /// Rotates the give quaternion by the given angle, around the x-axis.
        pub inline fn rotateX(q: *const Quat(T), angle: T) Quat(T) {
            const halfAngle = angle * 0.5;

            const qx = q.v.x();
            const qy = q.v.y();
            const qz = q.v.z();
            const qw = q.v.w();

            const bx = math.sin(halfAngle);
            const bw = math.cos(halfAngle);

            return init(qx * bw + qw * bx, qy * bw + qz * bx, qz * bw - qy * bx, qw * bw - qx * bx);
        }

        /// Rotates the give quaternion by the given angle, around the y-axis.
        pub inline fn rotateY(q: *const Quat(T), angle: T) Quat(T) {
            const halfAngle = angle * 0.5;

            const qx = q.v.x();
            const qy = q.v.y();
            const qz = q.v.z();
            const qw = q.v.w();

            const by = math.sin(halfAngle);
            const bw = math.cos(halfAngle);

            return init(qx * bw - qz * by, qy * bw + qw * by, qz * bw + qx * by, qw * bw - qy * by);
        }

        /// Rotates the give quaternion by the given angle, around the z-axis.
        pub inline fn rotateZ(q: *const Quat(T), angle: T) Quat(T) {
            const halfAngle = angle * 0.5;

            const qx = q.v.x();
            const qy = q.v.y();
            const qz = q.v.z();
            const qw = q.v.w();

            const bz = math.sin(halfAngle);
            const bw = math.cos(halfAngle);

            return init(qx * bw - qy * bz, qy * bw + qx * bz, qz * bw + qw * bz, qw * bw - qz * bz);
        }

        /// Calculates the spherical linear interpolation between two quaternions.
        pub inline fn slerp(a: *const Quat(T), b: *const Quat(T), t: T) Quat(T) {
            const ax = a.v.x();
            const ay = a.v.y();
            const az = a.v.z();
            const aw = a.v.w();

            var bx = b.v.x();
            var by = b.v.y();
            var bz = b.v.z();
            var bw = b.v.w();

            var cosOmega = ax * bx + ay * by + az * bz + aw * bw;
            if (cosOmega < 0) {
                cosOmega = -cosOmega;
                bx = -bx;
                by = -by;
                bz = -bz;
                bw = -bw;
            }

            var scale0: T = 0.0;
            var scale1: T = 0.0;

            if (1.0 - cosOmega > math.eps(T)) {
                const omega = math.acos(cosOmega);
                const sinOmega = math.sin(omega);
                scale0 = math.sin((1.0 - t) * omega) / sinOmega;
                scale1 = math.sin(t * omega) / sinOmega;
            } else {
                scale0 = 1.0 - t;
                scale1 = t;
            }

            return init(scale0 * ax + scale1 * bx, scale0 * ay + scale1 * by, scale0 * az + scale1 * bz, scale0 * aw + scale1 * bw);
        }

        /// Calculates the conjugate of the given quaternion.
        pub inline fn conjugate(q: *const Quat(T)) Quat(T) {
            return init(-q.v.x(), -q.v.y(), -q.v.z(), q.v.w());
        }

        /// Creates a quaternion from the given transformation matrix.
        pub inline fn fromMat(comptime matT: type, m: *const matT) Quat(T) {
            var dst = Quat(T).identity();
            const trace = m.v[0].v[0] + m.v[1].v[1] + m.v[2].v[2];

            if (trace > 0) {
                const root = math.sqrt(trace + 1.0);
                dst.v.v[3] = 0.5 * root;
                const rootInv = 0.5 / root;

                dst.v.v[0] = (m.v[1].v[2] - m.v[2].v[1]) * rootInv;
                dst.v.v[1] = (m.v[2].v[0] - m.v[0].v[2]) * rootInv;
                dst.v.v[2] = (m.v[0].v[1] - m.v[1].v[0]) * rootInv;
            } else {
                var i: usize = 0;

                if (m.v[1].v[1] > m.v[0].v[0]) {
                    i = 1;
                }

                if (m.v[2].v[2] > m.v[i].v[i]) {
                    i = 2;
                }

                const j = (i + 1) % 3;
                const k = (i + 2) % 3;

                const root = math.sqrt(m.v[i].v[i] - m.v[j].v[j] - m.v[k].v[k] + 1.0);
                dst.v.v[i] = 0.5 * root;

                const rootInv = 0.5 / root;

                dst.v.v[3] = (m.v[j].v[k] - m.v[k].v[j]) * rootInv;
                dst.v.v[j] = (m.v[j].v[i] - m.v[i].v[j]) * rootInv;
                dst.v.v[k] = (m.v[k].v[i] - m.v[i].v[k]) * rootInv;
            }

            return dst;
        }

        /// Creates a quaternion from the given Euler angles.
        pub inline fn fromEuler(x: T, y: T, z: T) Quat(T) {
            const xHalf = x * 0.5;
            const yHalf = y * 0.5;
            const zHalf = z * 0.5;

            const sx = math.sin(xHalf);
            const cx = math.cos(xHalf);
            const sy = math.sin(yHalf);
            const cy = math.cos(yHalf);
            const sz = math.sin(zHalf);
            const cz = math.cos(zHalf);

            const xRet = sx * cy * cz + cx * sy * sz;
            const yRet = cx * sy * cz - sx * cy * sz;
            const zRet = cx * cy * sz + sx * sy * cz;
            const wRet = cx * cy * cz - sx * sy * sz;

            return init(xRet, yRet, zRet, wRet);
        }

        /// Returns the dot product of two quaternions.
        pub inline fn dot(a: *const Quat(T), b: *const Quat(T)) T {
            return a.v.x() * b.v.x() + a.v.y() * b.v.y() + a.v.z() * b.v.z() + a.v.w() * b.v.w();
        }

        /// Linearly interpolates between two quaternions.
        pub inline fn lerp(a: *const Quat(T), b: *const Quat(T), t: T) Quat(T) {
            const xRet = a.v.x() + t * (b.v.x() - a.v.x());
            const yRet = a.v.y() + t * (b.v.y() - a.v.y());
            const zRet = a.v.z() + t * (b.v.z() - a.v.z());
            const wRet = a.v.w() + t * (b.v.w() - a.v.w());

            return init(xRet, yRet, zRet, wRet);
        }

        /// Computes the squared length of a given quaternion.
        pub inline fn len2(q: *const Quat(T)) T {
            return q.v.x() * q.v.x() + q.v.y() * q.v.y() + q.v.z() * q.v.z() + q.v.w() * q.v.w();
        }

        /// Computes the length of a given quaternion.
        pub inline fn len(q: *const Quat(T)) T {
            return math.sqrt(q.v.x() * q.v.x() + q.v.y() * q.v.y() + q.v.z() * q.v.z() + q.v.w() * q.v.w());
        }

        /// Computes the normalized version of a given quaternion.
        pub inline fn normalize(q: *const Quat(T)) Quat(T) {
            const q0 = q.v.x();
            const q1 = q.v.y();
            const q2 = q.v.z();
            const q3 = q.v.w();

            const length = math.sqrt(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);

            if (length > 0.00001) {
                return init(q0 / length, q1 / length, q2 / length, q3 / length);
            } else {
                return init(0, 0, 0, 0);
            }
        }
    };
}

test "zero_struct_overhead" {
    // Proof that using Quat is equal to @Vector(4, f32)
    try testing.expect(usize, @alignOf(@Vector(4, f32))).eql(@alignOf(math.Quat));
    try testing.expect(usize, @sizeOf(@Vector(4, f32))).eql(@sizeOf(math.Quat));
}

test "init" {
    try testing.expect(math.Quat, math.quat(1, 2, 3, 4)).eql(math.Quat{
        .v = math.vec4(1, 2, 3, 4),
    });
}

test "inverse" {
    const q = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const expected = math.Quat.init(-0.1 / 3.0, -0.1 / 3.0 * 2.0, -0.1, 1.0 / 7.5);
    const actual = q.inverse();

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "fromAxisAngle" {
    const expected = math.Quat.identity().rotateX(math.pi / 4.0);
    const actual = math.Quat.fromAxisAngle(math.vec3(1, 0, 0), math.pi / 4.0); // 45 degrees in radians (π/4) around the x-axis

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "angleBetween" {
    const a = math.Quat.fromAxisAngle(math.vec3(1, 0, 0), 1.0);
    const b = math.Quat.fromAxisAngle(math.vec3(1, 0, 0), -1.0);

    try testing.expect(f32, math.Quat.angleBetween(&a, &b)).eql(2.0);
}

test "mul" {
    const a = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const b = a.inverse();
    const expected = math.Quat.identity();
    const actual = math.Quat.mul(&a, &b);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "add" {
    const a = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const b = math.Quat.init(5.0, 6.0, 7.0, 8.0);
    const expected = math.Quat.init(6.0, 8.0, 10.0, 12.0);
    const actual = math.Quat.add(&a, &b);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "sub" {
    const a = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const b = math.Quat.init(5.0, 6.0, 7.0, 8.0);
    const expected = math.Quat.init(-4.0, -4.0, -4.0, -4.0);
    const actual = math.Quat.sub(&a, &b);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "mulScalar" {
    const q = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const expected = math.Quat.init(2.0, 4.0, 6.0, 8.0);
    const actual = math.Quat.mulScalar(&q, 2.0);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "divScalar" {
    const q = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const expected = math.Quat.init(0.5, 1.0, 1.5, 2.0);
    const actual = math.Quat.divScalar(&q, 2.0);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "rotateX" {
    const expected = math.Quat.fromAxisAngle(math.vec3(1, 0, 0), math.pi / 4.0);
    const actual = math.Quat.identity().rotateX(math.pi / 4.0);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "rotateY" {
    const expected = math.Quat.fromAxisAngle(math.vec3(0, 1, 0), math.pi / 4.0);
    const actual = math.Quat.identity().rotateY(math.pi / 4.0);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "rotateZ" {
    const expected = math.Quat.fromAxisAngle(math.vec3(0, 0, 1), math.pi / 4.0);
    const actual = math.Quat.identity().rotateZ(math.pi / 4.0);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "slerp" {
    const a = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const b = math.Quat.init(5.0, 6.0, 7.0, 8.0);
    const expected = math.Quat.init(3.0, 4.0, 5.0, 6.0);
    const actual = math.Quat.slerp(&a, &b, 0.5);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "conjugate" {
    const q = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const expected = math.Quat.init(-1.0, -2.0, -3.0, 4.0);
    const actual = math.Quat.conjugate(&q);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "fromMat4" {
    const m = math.Mat4x4.rotateX(math.pi / 4.0);
    const q = math.Quat.fromMat(math.Mat4x4, &m);
    const expected = math.Quat.identity().rotateX(math.pi / 4.0);

    try testing.expect(math.Vec4, expected.v).eql(q.v);
}

test "fromEuler" {
    const q = math.Quat.fromEuler(math.pi / 4.0, 0.0, 0.0);
    const expected = math.Quat.identity().rotateX(math.pi / 4.0);

    try testing.expect(math.Vec4, expected.v).eql(q.v);
}

test "dot" {
    const a = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const b = math.Quat.init(5.0, 6.0, 7.0, 8.0);
    const expected = 70.0;
    const actual = math.Quat.dot(&a, &b);

    try testing.expect(f32, actual).eql(expected);
}

test "lerp" {
    const a = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const b = math.Quat.init(5.0, 6.0, 7.0, 8.0);
    const expected = math.Quat.init(3.0, 4.0, 5.0, 6.0);
    const actual = math.Quat.lerp(&a, &b, 0.5);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}

test "len2" {
    const q = math.Quat.init(1.0, 2.0, 3.0, 4.0);
    const expected = 30.0;
    const actual = math.Quat.len2(&q);

    try testing.expect(f32, actual).eql(expected);
}

test "len" {
    const q = math.Quat.init(0.0, 0.0, 3.0, 4.0);
    const expected = 5.0;
    const actual = math.Quat.len(&q);

    try testing.expect(f32, actual).eql(expected);
}

test "normalize" {
    const q = math.Quat.init(0.0, 0.0, 3.0, 4.0);
    const expected = math.Quat.init(0.0, 0.0, 0.6, 0.8);
    const actual = math.Quat.normalize(&q);

    try testing.expect(math.Vec4, expected.v).eql(actual.v);
}
