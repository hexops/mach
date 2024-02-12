const std = @import("std");
const math = @import("main.zig");
const testing = @import("../testing.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;

pub const Rectangle = struct {
    pos: Vec2,
    size: Vec2,

    pub fn collidesRect(a: Rectangle, b: Rectangle) bool {
        return a.pos.x() + a.size.x() >= b.pos.x() and
            a.pos.x() <= b.pos.x() + b.size.x() and
            a.pos.y() + a.size.y() >= b.pos.y() and
            a.pos.y() <= b.pos.y() + b.size.y();
    }

    test collidesRect {
        const a: Rectangle = .{ .pos = vec2(2, 3), .size = vec2(5, 5) };
        var b: Rectangle = .{ .pos = vec2(6, 3), .size = vec2(3, 2) };
        try testing.expect(bool, a.collidesRect(b)).eql(true);

        b.pos = vec2(7.1, 3);
        try testing.expect(bool, a.collidesRect(b)).eql(false);
    }

    // TODO: add test for this function
    /// Get collision rectangle for two rectangles collision
    pub fn collisionRect(a: Rectangle, b: Rectangle) ?Rectangle {
        const left = if (a.pos.x() > b.pos.x()) a.pos.x() else b.pos.x();
        const right_a = a.pos.x() + a.size.x();
        const right_b = b.pos.x() + b.size.x();
        const right = if (right_a < right_b) right_a else right_b;
        const top = if (a.pos.y() > b.pos.y()) a.pos.y() else b.pos.y();
        const bottom_a = a.pos.y() + a.size.y();
        const bottom_b = b.pos.y() + b.size.y();
        const bottom = if (bottom_a < bottom_b) bottom_a else bottom_b;

        if (left < right and top < bottom) {
            return .{
                .pos = vec2(left, top),
                .size = vec2(right - left, bottom - top),
            };
        }

        return null;
    }
};

pub const Circle = struct {
    pos: Vec2,
    radius: f32,

    pub fn collidesRect(a: Circle, b: Rectangle) bool {
        var near_x_edge = a.pos.x();
        var near_y_edge = a.pos.y();

        if (a.pos.x() < b.pos.x()) {
            near_x_edge = b.pos.x(); // left edge
        } else if (a.pos.x() > b.pos.x() + b.size.x()) {
            near_x_edge = b.pos.x() + b.size.x(); // right edge
        }

        if (a.pos.y() < b.pos.y()) {
            near_y_edge = b.pos.y(); // top edge
        } else if (a.pos.y() > b.pos.y() + b.size.y()) {
            near_y_edge = b.pos.y() + b.size.y(); // bottom edge
        }

        // get distance from closest edges
        const dist_x = a.pos.x() - near_x_edge;
        const dist_y = a.pos.y() - near_y_edge;
        const dist = @sqrt((dist_x * dist_x) + (dist_y * dist_y));

        // if the distance is less than the radius, collision!
        return dist <= a.radius;
    }

    test collidesRect {
        const a: Circle = .{ .pos = vec2(2, 3), .radius = 5 };
        var b: Rectangle = .{ .size = vec2(3, 2), .pos = vec2(6, 3) };
        try testing.expect(bool, a.collidesRect(b)).eql(true);

        b.pos = vec2(7.1, 3);
        try testing.expect(bool, a.collidesRect(b)).eql(false);
    }

    pub fn collidesCircle(a: Circle, b: Circle) bool {
        // get distance between the circle's centers
        // use the Pythagorean Theorem to compute the distance
        const dist_x = a.pos.x() - b.pos.x();
        const dist_y = a.pos.y() - b.pos.y();
        const distance = @sqrt((dist_x * dist_x) + (dist_y * dist_y));

        // if the distance is less than the sum of the circle's
        // radii, the circles are touching!
        return distance <= a.radius + b.radius;
    }

    test collidesCircle {
        const a: Circle = .{ .pos = vec2(2, 3), .radius = 3 };
        var b: Circle = .{ .pos = vec2(9, 3), .radius = 4 };
        try testing.expect(bool, a.collidesCircle(b)).eql(true);

        b.pos = vec2(9.1, 3);
        try testing.expect(bool, a.collidesCircle(b)).eql(false);
    }
};

pub const Point = struct {
    pos: Vec2,

    pub fn collidesRect(a: Point, b: Rectangle) bool {
        return a.pos.x() >= b.pos.x() and
            a.pos.x() <= b.pos.x() + b.size.x() and
            a.pos.y() >= b.pos.y() and
            a.pos.y() <= b.pos.y() + b.size.y();
    }

    test collidesRect {
        const a: Point = .{ .pos = vec2(6, 4) };
        var b: Rectangle = .{ .pos = vec2(6, 3), .size = vec2(3, 2) };
        try testing.expect(bool, a.collidesRect(b)).eql(true);

        b.pos = vec2(9.1, 4);
        try testing.expect(bool, a.collidesRect(b)).eql(false);
    }

    pub fn collidesCircle(a: Point, b: Circle) bool {
        const dist_x = a.pos.x() - b.pos.x();
        const dist_y = a.pos.y() - b.pos.y();
        const distance = @sqrt((dist_x * dist_x) + (dist_y * dist_y));
        return distance <= b.radius;
    }

    test collidesCircle {
        const a: Point = .{ .pos = vec2(6, 4) };
        var b: Circle = .{ .pos = vec2(6, 3), .radius = 3 };
        try testing.expect(bool, a.collidesCircle(b)).eql(true);

        b.pos = vec2(9.1, 4);
        try testing.expect(bool, a.collidesCircle(b)).eql(false);
    }

    // TODO: add test for this function
    pub fn collidesPoly(point: Point, vertices: []const Vec2) bool {
        std.debug.assert(vertices.len > 2);

        var collision = false;
        const px = point.pos.x();
        const py = point.pos.y();

        for (vertices, 1..) |vc, i| {
            // Get next vertex in list.
            // If we've hit the end, wrap around to first.
            const vn = if (i == vertices.len) vertices[0] else vertices[i];

            if ((vc.y() > py) != (vn.y() > py) and
                px < (vn.x() - vc.x()) * (py - vc.y()) / (vn.y() - vc.y()) + vc.x())
            {
                collision = !collision;
            }
        }

        return collision;
    }

    // TODO: add test for this function
    pub fn collidesTriangle(point: Point, vertices: []const Vec2) bool {
        std.debug.assert(vertices.len == 3);
        const p1 = vertices[0];
        const p2 = vertices[1];
        const p3 = vertices[2];

        const alpha = ((p2.y() - p3.y()) * (point.pos.x() - p3.x()) + (p3.x() - p2.x()) * (point.pos.y() - p3.y())) /
            ((p2.y() - p3.y()) * (p1.x() - p3.x()) + (p3.x() - p2.x()) * (p1.y() - p3.y()));

        const beta = ((p3.y() - p1.y()) * (point.pos.x() - p3.x()) + (p1.x() - p3.x()) * (point.pos.y() - p3.y())) /
            ((p2.y() - p3.y()) * (p1.x() - p3.x()) + (p3.x() - p2.x()) * (p1.y() - p3.y()));

        const gamma = 1 - alpha - beta;

        return (alpha > 0) and (beta > 0) and (gamma > 0);
    }

    // TODO: add test for this function
    pub fn collidesLine(point: Point, line: Line) bool {
        const dxc = point.pos.x() - line.start.x();
        const dyc = point.pos.y() - line.start.y();
        const dxl = line.end.x() - line.start.x();
        const dyl = line.end.y() - line.start.y();
        const cross = dxc * dyl - dyc * dxl;

        if (@abs(cross) < line.threshold * @max(@abs(dxl), @abs(dyl))) {
            if (@abs(dxl) >= @abs(dyl)) {
                if (dxl > 0) {
                    return (line.start.x() <= point.pos.x()) and (point.pos.x() <= line.end.x());
                } else {
                    return (line.end.x() <= point.pos.x()) and (point.pos.x() <= line.start.x());
                }
            } else {
                if (dyl > 0) {
                    return (line.start.y() <= point.pos.y()) and (point.pos.y() <= line.end.y());
                } else {
                    return (line.end.y() <= point.pos.y()) and (point.pos.y() <= line.start.y());
                }
            }
        }

        return false;
    }
};

pub const Line = struct {
    start: Vec2,
    end: Vec2,
    threshold: f32,

    // TODO: add test for this function
    pub fn collidesLine(a: Line, b: Line) bool {
        const start_dist = a.start.sub(&b.start);
        const b_end_dist = b.end.sub(&b.start);
        const a_end_dist = a.end.sub(&a.start);

        const div = b_end_dist.y() * a_end_dist.x() - b_end_dist.x() * a_end_dist.y();
        const ua = b_end_dist.x() * start_dist.y() - b_end_dist.y() * start_dist.x() / div;
        const ub = a_end_dist.x() * start_dist.y() - a_end_dist.y() * start_dist.x() / div;

        return ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1;
    }
};
