//! # Collision detection 
//!
//! This module provides functions to check for collision between various 2D shape. 
//! It also provides functions to determine the contact points of two objects that have collided.
//! The contact information can be used to resolve the collision. 
//!  
const std = @import("std");
const math = @import("main.zig");
const testing = @import("../testing.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;

/// An axis aligned rectangle.
/// 
/// The boundary of the rectangle is considered inside.
pub const Rectangle = struct {
    /// Bottom left of the rectangle.
    pos: Vec2,
    /// The size of the rectangle along the x and y axis. 
    size: Vec2,

    /// Returns true of the two rectangles collide.
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

    /// Get collision rectangle for two rectangles collision.
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

    test collisionRect {
        const a: Rectangle = .{ .pos = vec2(-1, -1), .size = vec2(2, 2) };
        var b: Rectangle = .{ .pos = vec2(0, 0), .size = vec2(2, 2) };

        const r1 = a.collisionRect(b);
        if (r1) |r| {
            try testing.expect(Vec2, r.pos).eql(vec2(0.0, 0.0));
            try testing.expect(Vec2, r.size).eql(vec2(1.0, 1.0));
        } else {
            try testing.expect(bool, false).eql(true);
        }

        b.pos = vec2(5.0, 5.0);
        const r2 = a.collisionRect(b);
        try testing.expect(?Rectangle, r2).eql(null);
    }   

    /// Returns vertices for the Rectangle in CCW order.
    pub fn vertices(self: Rectangle) [4]Vec2 {
        return [_]Vec2{
                    self.pos,
                    self.pos.add(&vec2(self.size.x(), 0.0)),
                    self.pos.add(&vec2(self.size.x(), self.size.y())),
                    self.pos.add(&vec2(0.0, self.size.y())),
        };
    }

    test vertices {
        const rect = Rectangle{.pos = vec2(0.0, 0.0), .size = vec2(1.0, 1.0)};
        const v = rect.vertices();
        try testing.expect(Vec2, vec2(0.0, 0.0)).eql(v[0]);
        try testing.expect(Vec2, vec2(1.0, 0.0)).eql(v[1]);
        try testing.expect(Vec2, vec2(1.0, 1.0)).eql(v[2]);
        try testing.expect(Vec2, vec2(0.0, 1.0)).eql(v[3]);
    }

};

// A circle shape defined by position and radius.
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

    // Return true if point is inside Rectangle.
    pub fn collidesRect(a: Point, b: Rectangle) bool {
        return a.pos.x() >= b.pos.x() and
            a.pos.x() <= b.pos.x() + b.size.x() and
            a.pos.y() >= b.pos.y() and
            a.pos.y() <= b.pos.y() + b.size.y();
    }

    test collidesRect {
        const a: Point = .{ .pos = vec2(6, 4) };
        const c = Point{.pos = vec2(6.0, 3.0)};
        var b: Rectangle = .{ .pos = vec2(6, 3), .size = vec2(3, 2) };
        try testing.expect(bool, a.collidesRect(b)).eql(true);        
        try testing.expect(bool, c.collidesRect(b)).eql(true);

        b.pos = vec2(9.1, 4);
        try testing.expect(bool, a.collidesRect(b)).eql(false);

        const p = Point{ .pos = vec2(0.0, 0.0) };
        const r = Rectangle{.pos = vec2(0.0, 0.0), .size = vec2(1.0, 1.0)};
        try testing.expect(bool, p.collidesRect(r)).eql(true);
    }

    // Return true if point is inside Circle.
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

    // Returns true if point is inside polygon. 
    // The boundary of the polygon is outside. 
    // A polygon is specified by a list of the polygon vertices in counter clockwise order.
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

    test collidesPoly {
        const poly = [_]Vec2 {
            vec2(-1.0, -1.0),  
            vec2(1.0, -1.0),  
            vec2(1.0, 1.0),  
            vec2(-1.0, 1.0),  
        };

        try testing.expect(bool, Point.collidesPoly(Point{.pos = vec2(0.0, 0.0)}, &poly)).eql(true);
        // TODO: decide if boundary is inside or not
        //try testing.expect(bool, Point.collidesPoly(Point{.pos = vec2(1.0, 1.0)}, &poly)).eql(true);
        try testing.expect(bool, Point.collidesPoly(Point{.pos = vec2(2.0, 2.0)}, &poly)).eql(false);
        try testing.expect(bool, Point.collidesPoly(Point{.pos = vec2(-2.0, 2.0)}, &poly)).eql(false);
    }

    /// Returns true if point is inside triangle.
    /// The boundary of the triangle is outside. 
    /// A triangle is specified by the triangle vertices in counter clockwise order.
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
    test collidesTriangle {
        const triangle = [_]Vec2 {
            vec2(-1.0, -1.0),  
            vec2(1.0, -1.0),  
            vec2(0.0, 1.0),  
        };

        try testing.expect(bool, Point.collidesPoly(Point{.pos = vec2(0.0, 0.0)}, &triangle)).eql(true);
        // TODO: decide if boundary is inside or not
        //try testing.expect(bool, Point.collidesPoly(Point{.pos = vec2(0.0, 1.0)}, &triangle)).eql(true);
        try testing.expect(bool, Point.collidesPoly(Point{.pos = vec2(2.0, 2.0)}, &triangle)).eql(false);
        try testing.expect(bool, Point.collidesPoly(Point{.pos = vec2(-2.0, 2.0)}, &triangle)).eql(false);

        // TODO: decide if boundary is inside or not
        // const t = [_]Vec2 {
        //     vec2(0.0, 0.0),  
        //     vec2(1.0, 0.0),  
        //     vec2(1.0, 1.0),  
        // };
        // const p = Point{ .pos = vec2(0.0, 0.0) };
        // try testing.expect(bool, p.collidesTriangle(&t)).eql(true);
    }

    /// Returns true if a point is within the Line's threshold.
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

    test collidesLine {
        const l = Line{
            .start = vec2(-1.0, -1.0),
            .end = vec2(1.0, 1.0),
            .threshold = 0.1,
        };
        try testing.expect(bool, Point.collidesLine(Point{.pos = vec2(0.0, 0.0)}, l)).eql(true);
        // TODO: decide if boundary is inside or not
        //try testing.expect(bool, Point.collidesLine(Point{.pos = vec2(0.0, 0.1)}, l)).eql(true);
        try testing.expect(bool, Point.collidesLine(Point{.pos = vec2(0.0, 0.09)}, l)).eql(true);
        try testing.expect(bool, Point.collidesLine(Point{.pos = vec2(0.0, 1.0)}, l)).eql(false);
    }

};

/// A line specified by a start and endpoint and a threshold for the line thickness.
pub const Line = struct {
    start: Vec2,
    end: Vec2,
    threshold: f32,

    /// Return true if line and b intersect. 
    /// This function does not take into account the line treshold.
    pub fn collidesLine(a: Line, b: Line) bool {
        const start_dist = a.start.sub(&b.start);
        const b_end_dist = b.end.sub(&b.start);
        const a_end_dist = a.end.sub(&a.start);

        const div = b_end_dist.y() * a_end_dist.x() - b_end_dist.x() * a_end_dist.y();
        const ua = (b_end_dist.x() * start_dist.y() - b_end_dist.y() * start_dist.x()) / div;
        const ub = (a_end_dist.x() * start_dist.y() - a_end_dist.y() * start_dist.x()) / div;

        return ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1;
    }

    test collidesLine {
        const l0 = Line{.start = vec2(-1.0, -1.0), .end = vec2(1.0, 1.0), .threshold = 0.0};
        try testing.expect(bool, true).eql(
            l0.collidesLine(Line{.start = vec2(-1.0, 1.0), .end = vec2(1.0, -1.0), .threshold=0.0}));
        try testing.expect(bool, true).eql(
            l0.collidesLine(Line{.start = vec2(-10.0, 0.0), .end = vec2(10.0, 0.0), .threshold=0.0}));
        try testing.expect(bool, true).eql(
            l0.collidesLine(Line{.start = vec2(-10.0, 1.0), .end = vec2(10.0, 1.0), .threshold=0.0}));
        try testing.expect(bool, true).eql(
            l0.collidesLine(Line{.start = vec2(-10.0, -1.0), .end = vec2(10.0, -1.0), .threshold=0.0}));

        // TODO: fails if same line
        //try testing.expect(bool, true).eql(
        //    l0.collidesLine(l0));

        try testing.expect(bool, false).eql(
            l0.collidesLine(Line{.start = vec2(-1.1, -1.1), .end = vec2(1.1, 1.1), .threshold=0.0}));
        try testing.expect(bool, false).eql(
            l0.collidesLine(Line{.start = vec2(-10.0, 2.0), .end = vec2(10.0, 2.0), .threshold=0.0}));

    }
};

/// Contains the contact information between two convex 2D shapes.
/// There can be up to two contacts point in case the objects collide
/// on a paralell line.
/// 
/// The normal points from A to B, so the objects can be separated by moving
/// B by the vector depth x normal
/// 
pub const Contact = struct {
    /// The contact normal from A to B
    normal: Vec2,
    /// Depth of the peneration. 
    depth: f32,
    /// Contact point 1 on obj A
    cp1: ?Vec2 = null,
    /// Contact point 2 on obj A
    cp2: ?Vec2 = null,
};

/// Compute the minimum and maximum projection of vertices in v on the line through v0 with normal n 
pub fn minmaxProjectionDistance(n: Vec2, v0: Vec2, v: []const Vec2) [2]f32 {
    var max_d = n.dot(&v[0].sub(&v0));
    var min_d = n.dot(&v[0].sub(&v0));
    for (v[1..]) |vb| {
        const d = n.dot(&vb.sub(&v0));
        if (d < min_d) {
            min_d = d;
        } else if (d > max_d) {
            max_d = d;
        }
    }
    return [2]f32{min_d, max_d};
}

test minmaxProjectionDistance {
    const n_up = vec2(0.0, 1.0);
    const n_right = vec2(1.0, 0.0);
    const v0 = vec2(0.0, 0.0);
    const v = [_]Vec2{
        vec2(2.0, 0.0), 
        vec2(1.0, 1.0),
        vec2(0.0, -2.0),
        vec2(-1.0, 2.0),
        vec2(-2.0, 1.0)        
    };

    {
        const minmax = minmaxProjectionDistance(n_up, v0, &v);
        try testing.expect(f32, -2.0).eql(minmax[0]);
        try testing.expect(f32, 2.0).eql(minmax[1]);
    }

    {
        const minmax = minmaxProjectionDistance(n_right, v0, &v);
        try testing.expect(f32, -2.0).eql(minmax[0]);
        try testing.expect(f32, 2.0).eql(minmax[1]);
    }

}

const VertexDepthResult = struct {
    v0: Vec2 = undefined,              
    v1: ?Vec2 = null,
    /// Depth of vertex. Positive in the opposite direction of the normal.
    d: f32 
};

/// Find the vertex in v that is deepest behind the line defined by the point v0 and normal n.
pub fn findDeepestVertex(n: Vec2, v0: Vec2, v: []const Vec2) VertexDepthResult {
    var min_depth = VertexDepthResult{
        .v0 = v[0],
        .d = n.dot(&v[0].sub(&v0))
    };
    for (v[1..]) |vb| {
        const d = n.dot(&vb.sub(&v0));
        if (d < min_depth.d) {
            min_depth.d = d;
            min_depth.v0 = vb;
            min_depth.v1 = null;
        } else if (d == min_depth.d) {
            min_depth.v1 = vb;
        }
    }
    min_depth.d = -min_depth.d;
    return min_depth;
}

test findDeepestVertex {
    const n_up = vec2(0.0, 1.0);

    const v0 = vec2(0.0, 0.0);
    // Test finding a single deepest vertex
    {
        const v = [_]Vec2{
            vec2(2.0, 0.0), 
            vec2(1.0, 1.0),
            vec2(0.0, -2.0), // Deepest
            vec2(-1.0, 2.0),
            vec2(-2.0, 1.0)        
        };

        const depth = findDeepestVertex(n_up, v0, &v);
        try testing.expect(Vec2, vec2(0.0, -2.0)).eql(depth.v0);
        try testing.expect(?Vec2, null).eql(depth.v1);
        try testing.expect(f32, 2.0).eql(depth.d);
    }    
    // Test finding two deepest vertices
    {
        const v = [_]Vec2{
            vec2(2.0, 0.0), 
            vec2(1.0, 1.0),
            vec2(0.0, -3.0),   // Deepest
            vec2(-1.0, -3.0),  // Deepest
            vec2(-2.0, 1.0)        
        };

        const depth = findDeepestVertex(n_up, v0, &v);
        try testing.expect(Vec2, vec2(0.0, -3.0)).eql(depth.v0);
        try testing.expect(Vec2, vec2(-1.0, -3.0)).eql(depth.v1.?);
        try testing.expect(f32, 3.0).eql(depth.d);
   }    

    // No vertex behind edge - will return closest vertex instead
    {
        const v = [_]Vec2{
            vec2(2.0, 0.5), // Closest
            vec2(1.0, 1.0),
            vec2(0.0, 3.0),
            vec2(-2.0, 1.0)        
        };

        const depth = findDeepestVertex(n_up, v0, &v);
        try testing.expect(Vec2, vec2(2.0, 0.5)).eql(depth.v0);
        try testing.expect(?Vec2, null).eql(depth.v1);
        try testing.expect(f32, -0.5).eql(depth.d);
   }    

}

/// Contains information to separate two colliding shapes.
const SeparationResult = struct {
//    i0: usize = undefined,              // Vertex idx
//    i1: ?usize = null,
    v0: Vec2 = undefined,              
    v1: ?Vec2 = null,
    e: usize = undefined,               // Edge idx
    n: Vec2 = undefined,                // Edge normal
    d: f32 = std.math.floatMax(f32),    // Depth
};

/// Find the edge and vertices for the minimum separation required to 
/// separate vertices in polygon_a from edge in polygon_b.
/// Returns null if a separting axis is found.
pub fn findMinSeparation(polygon_a: []const Vec2, polygon_b: []const Vec2) ?SeparationResult {
    var min_result = SeparationResult{};

    var v0 = polygon_b[polygon_b.len-1];
    for (polygon_b[0..], 0..) |v1, i| {
        const edge = v1.sub(&v0);
        const n = vec2(edge.y(), -edge.x()).normalize(0.0); 
        const min_depth = findDeepestVertex(n, v0, polygon_a);
        v0 = v1;
        if (min_depth.d < 0.0) {
            return null;
        }

        if (min_depth.d < min_result.d) {
            min_result.n = n;
            min_result.v0 = min_depth.v0;
            min_result.v1 = min_depth.v1;
            min_result.d = min_depth.d;
            min_result.e = i;
        } else if (min_depth.d == min_result.d) {
            // TODO: decide how to handle multiple edges with equal penetration
        }
    }
    min_result.e = (min_result.e + polygon_b.len - 1) % polygon_b.len;
    return min_result;
}

test findMinSeparation {
    const triangle_0 = [_]Vec2{
        vec2(-1.0, -1.0), 
        vec2(1.0, -1.0),
        vec2(0.0, 1.0), 
    };
    const triangle_1 = [_]Vec2{
        vec2(-1.0, -2.75), 
        vec2(1.0, -2.75),
        vec2(0.0, -0.75), 
    };
    const triangle_2 = [_]Vec2{
        vec2(-1.0, -2.75), 
        vec2(1.0, -2.75),
        vec2(0.0, -1.75), 
    };

    // Top point of triangle_1 intersects with first edge of triangle_0 at depth 0.25
    const result = findMinSeparation(&triangle_1, &triangle_0);
    try testing.expect(Vec2, vec2(0.0, -0.75)).eql(result.?.v0);
    try testing.expect(?Vec2, null).eql(result.?.v1);
    try testing.expect(usize, 0).eql(result.?.e);
    try testing.expect(Vec2, vec2(0.0, -1.0)).eql(result.?.n);
    try testing.expect(f32, 0.25).eql(result.?.d);

    // Not colliding - bottom edge of triangle_0 separates the two
    try testing.expect(?SeparationResult, null).eql(
        findMinSeparation(&triangle_2, &triangle_0)
    );

}

/// Compute a Contact report between polygon_a and polygon_b if they are colliding.
pub fn polygonPolygonContact(polygon_a: []const Vec2, polygon_b: []const Vec2) ?Contact {
    var normal = vec2(0.0, 0.0);
    var depth: f32 = 0.0;
    var cp1_a: ?Vec2 = null;
    var cp2_a: ?Vec2 = null;

    const min_separation_a = findMinSeparation(polygon_a, polygon_b) orelse return null;
    const min_separation_b = findMinSeparation(polygon_b, polygon_a) orelse return null;

    if (min_separation_a.d < min_separation_b.d) {
        // Vertex in a passes an edge in b
        depth = min_separation_a.d;
        normal = min_separation_a.n.mulScalar(-1.0);  
        cp1_a = min_separation_a.v0;
        cp2_a = min_separation_a.v1;
    } else if (min_separation_a.d > min_separation_b.d) {
        // Vertex in b passes an edge in a
        depth = min_separation_b.d;
        normal = min_separation_b.n;  
        cp1_a = min_separation_b.v0.add(&normal.mulScalar(depth));
        if (min_separation_b.v1) |v1| {
            cp2_a = v1.add(&normal.mulScalar(depth)); 
        } 
    } else { 
        // Two edges
        depth = min_separation_a.d;
        normal = min_separation_a.n.mulScalar(-1.0);  
        if (@abs(normal.dot(&min_separation_b.n)) != 1.0 or min_separation_a.v1 == null or min_separation_b.v1 == null) {
            // Edges are not paralell
            cp1_a = min_separation_b.v0;
            cp2_a = min_separation_b.v1;
        } else {
            // Paralell edges - find two contact points
            const edge = vec2(min_separation_a.n.y(), -min_separation_a.n.x());
            const vertices = [_]Vec2{
                min_separation_a.v0, 
                min_separation_a.v1.?, 
                min_separation_b.v0, 
                min_separation_b.v1.?};
            const from_a = [4]bool {true, true, false, false}; 
            var distances: [4]f32 = undefined;
            for (vertices, &distances) |v, *d| {
                d.* = edge.dot(&v);
            }
            // Sort vertices along the edge
            var idx = [_]u8{0,1,2,3};
            for (0..3) |i| {
                for (i+1..4) |j| {
                    if (distances[idx[i]] > distances[idx[j]]) {
                        const t = idx[i];
                        idx[i] = idx[j];
                        idx[j] = t;
                    }
                }
            }

            depth = min_separation_a.d;
            normal = min_separation_a.n.mulScalar(-1.0);  
            cp1_a = if (from_a[idx[1]]) vertices[idx[1]] 
                    else vertices[idx[1]].add(&normal.mulScalar(depth));
            cp2_a = if (from_a[idx[2]]) vertices[idx[2]]
                    else vertices[idx[2]].add(&normal.mulScalar(depth));
        }
    }

    return Contact{
        .normal = normal,
        .depth = depth,
        .cp1 = cp1_a,
        .cp2 = cp2_a,
    };
}

test polygonPolygonContact {
    const triangle_0 = [_]Vec2{
        vec2(-1.0, -1.0), 
        vec2(1.0, -1.0),
        vec2(0.0, 1.0), 
    };
    const triangle_1 = [_]Vec2{
        vec2(-1.0, -2.75), 
        vec2(1.0, -2.75),
        vec2(0.0, -0.75), 
    };
    const triangle_2 = [_]Vec2{
        vec2(-1.0, -2.75), 
        vec2(1.0, -2.75),
        vec2(0.0, -1.75), 
    };

    if (polygonPolygonContact(&triangle_0, &triangle_1)) |contact_0_1| {
        try testing.expect(Vec2, vec2(0.0, -1.0)).eql(contact_0_1.normal);
        try testing.expect(f32, 0.25).eql(contact_0_1.depth);
        try testing.expect(Vec2, vec2(0.0, -1.0)).eql(contact_0_1.cp1.?);
        try testing.expect(?Vec2, null).eql(contact_0_1.cp2);
    } else {
        try testing.expect(bool, true).eql(false);
    }

    if (polygonPolygonContact(&triangle_1, &triangle_0)) |contact_1_0| {
        try testing.expect(Vec2, vec2(0.0, 1.0)).eql(contact_1_0.normal);
        try testing.expect(f32, 0.25).eql(contact_1_0.depth);
        try testing.expect(Vec2, vec2(0.0, -0.75)).eql(contact_1_0.cp1.?);
        try testing.expect(?Vec2, null).eql(contact_1_0.cp2);
    } else {
        try testing.expect(bool, true).eql(false);
    }

    try testing.expect(?Contact, null).eql(polygonPolygonContact(&triangle_0, &triangle_2));
    try testing.expect(?Contact, null).eql(polygonPolygonContact(&triangle_2, &triangle_0));

    const rect1 = Rectangle{.pos = vec2(-1.0, -1.0), .size = vec2(2.0, 2.0)};
    const rect2 = Rectangle{.pos = vec2(-1.5, -2.25), .size = vec2(1.0, 1.5)};
    const rect3 = Rectangle{.pos = vec2(-0.5, -2.25), .size = vec2(1.0, 1.5)};
    const rect4 = Rectangle{.pos = vec2( 0.5, -2.25), .size = vec2(1.0, 1.5)};
    const r1 = rect1.vertices();
    const r2 = rect2.vertices();
    const r3 = rect3.vertices();
    const r4 = rect4.vertices();

    if (polygonPolygonContact(&r1, &r2)) |contact| {
        try testing.expect(Vec2, vec2(0.0, -1.0)).eql(contact.normal);
        try testing.expect(f32, 0.25).eql(contact.depth);

        try testing.expect(Vec2, vec2(-1.0, -1.0)).eql(contact.cp1.?);
        try testing.expect(Vec2, vec2(-0.5, -1.0)).eql(contact.cp2.?);
    } else {
        try testing.expect(bool, true).eql(false);
    }

    if (polygonPolygonContact(&r1, &r3)) |contact| {
        try testing.expect(Vec2, vec2(0.0, -1.0)).eql(contact.normal);
        try testing.expect(f32, 0.25).eql(contact.depth);
    } else {
        try testing.expect(bool, true).eql(false);
    }

    if (polygonPolygonContact(&r1, &r4)) |contact| {
        try testing.expect(Vec2, vec2(0.0, -1.0)).eql(contact.normal);
        try testing.expect(f32, 0.25).eql(contact.depth);
    } else {
        try testing.expect(bool, true).eql(false);
    }
}

/// Compute a Contact report between a Circle and a polygon.
pub fn circlePolygonContact(circle_a: Circle, polygon_b: []const Vec2) ?Contact {
    var normal = vec2(0.0, 0.0);
    var depth: f32 = 0.0;
    var cp1_a: ?Vec2 = null;

    var v0 = polygon_b[polygon_b.len-1];
    var min_result = struct {
        n: Vec2,
        d: f32,
        i: usize
    }{
        .n = vec2(0.0, 0.0),
        .d = std.math.floatMax(f32),
        .i = undefined
    };
    var closest_vertex = struct {
        v: Vec2 = undefined,
        d: f32 = std.math.floatMax(f32),
        i: usize = undefined,
    }{};

    for (polygon_b[0..], 0..) |v1, i| {
        const edge = v1.sub(&v0);
        const n = vec2(edge.y(), -edge.x()).normalize(0.0); 
        const vc = circle_a.pos.sub(&v0);
        const d = vc.dot(&n);
        if (vc.len() < closest_vertex.d) {
            closest_vertex.v = v0;
            closest_vertex.d = vc.len();
            closest_vertex.i = i;
        }

        v0 = v1;
        if (d > circle_a.radius) {
            // Circle does not collide with this edge
            return null;
        }

        const current_depth = circle_a.radius - d;
        if (current_depth < min_result.d) {
            min_result.d = current_depth;
            min_result.n = n;
            min_result.i = i;
        }
    }

    // Check circle to closest point axis
    {
        v0 = closest_vertex.v;
        const n = circle_a.pos.sub(&v0).normalize(0.0); 
        const minmax_b = minmaxProjectionDistance(n, v0, polygon_b);                        
        
        // Circle projects to +- radius
        const vc = circle_a.pos.sub(&v0);
        const d = vc.dot(&n);
        const minmax_a = [2]f32{d - circle_a.radius, d + circle_a.radius};

        if ((minmax_a[0] > minmax_b[1]) or (minmax_a[1] < minmax_b[0])) {
            // Circle does not intersect
            return null;
        }

        const current_depth = @min(minmax_a[1] - minmax_b[0], minmax_b[1] - minmax_a[0]);
        if (current_depth <= min_result.d) {
            min_result.d = current_depth;
            min_result.n = n;
        }
    }

    depth = -min_result.d;
    normal = min_result.n.mulScalar(-1.0);  
    cp1_a = circle_a.pos.add(&normal.mulScalar(circle_a.radius)); 

    return Contact{
        .normal = normal,
        .depth = -depth,
        .cp1 = cp1_a,
    };
}

test circlePolygonContact {
    const rect1 = Rectangle{.pos = vec2(0.75, -1.0), .size = vec2(2.0, 2.0)};
    const r1 = rect1.vertices();
    if (circlePolygonContact(Circle{.pos=vec2(0.0, 0.0), .radius = 1.0}, &r1)) |contact| {
        try testing.expect(Vec2, vec2(1.0, 0.0)).eql(contact.normal);
        try testing.expect(f32, 0.25).eql(contact.depth);
        try testing.expect(Vec2, vec2(1.0, 0.0)).eql(contact.cp1.?);
        try testing.expect(?Vec2, null).eql(contact.cp2);
    } else {
        try testing.expect(bool, true).eql(false);
    }

    try testing.expect(?Contact, null).eql(
        circlePolygonContact(Circle{.pos=vec2(-1.0, 0.0), .radius = 1.0}, &r1)
    );
}

/// Compute a Contact report between two circles.
pub fn circleCircleContact(circle_a: Circle, circle_b: Circle) ?Contact {
    const delta = circle_b.pos.sub(&circle_a.pos);
    const distance = delta.len();
    const depth = circle_a.radius + circle_b.radius - distance; 
    if (depth < 0.0) {
        return null;
    }
    // if distance is zero then all separation directions are equivalent. Pick arbitrary one. 
    const normal = if (distance > 0.0) delta.mulScalar(1.0 / distance) else vec2(1.0, 0.0);
    const cp1_a = circle_a.pos.add(&normal.mulScalar(circle_a.radius));

    return Contact{
        .normal = normal,
        .depth = depth,
        .cp1 = cp1_a,
    };
}

test circleCircleContact {
    if (circleCircleContact(Circle{.pos=vec2(0.0, 0.0), .radius = 1.0}, 
        Circle{.pos = vec2(1.75, 0.0), .radius = 1.0})) |contact| {

        try testing.expect(Vec2, vec2(1.0, 0.0)).eql(contact.normal);
        try testing.expect(f32, 0.25).eql(contact.depth);
        try testing.expect(Vec2, vec2(1.0, 0.0)).eql(contact.cp1.?);
        try testing.expect(?Vec2, null).eql(contact.cp2);
    } else {
        try testing.expect(bool, true).eql(false);
    }

    if (circleCircleContact(Circle{.pos=vec2(0.0, 0.0), .radius = 1.0}, 
        Circle{.pos = vec2(2.0, 0.0), .radius = 1.0})) |contact| {

        try testing.expect(Vec2, vec2(1.0, 0.0)).eql(contact.normal);
        try testing.expect(f32, 0.0).eql(contact.depth);
        try testing.expect(Vec2, vec2(1.0, 0.0)).eql(contact.cp1.?);
        try testing.expect(?Vec2, null).eql(contact.cp2);
    } else {
        try testing.expect(bool, true).eql(false);
    }

    try testing.expect(?Contact, null).eql(
        circleCircleContact(Circle{.pos=vec2(0.0, 0.0), .radius = 1.0}, 
        Circle{.pos = vec2(2.01, 0.0), .radius = 1.0})        
    );     
}