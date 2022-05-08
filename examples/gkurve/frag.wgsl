//! Ported from https://www.shadertoy.com/view/ltXSDB

// Signed Distance to a Quadratic Bezier Curve
// - Adam Simmons (@adamjsimmons) 2015
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
//
// Inspired by http://www.pouet.net/topic.php?which=9119
// and various shaders by iq, T21, and demofox
// 
// I needed the -signed- distance to a quadratic bezier
// curve but couldn't find any examples online that
// were both fast and precise. This is my solution.
//
// v1 - Initial release
// v2 - Faster and more robust sign computation
//

struct FragUniform {
    points: array<vec4<f32>, 3>,
    type_: u32,
}
@binding(1) @group(0) var<uniform> ubos : array<FragUniform, 3>;

// Test if point p crosses line (a, b), returns sign of result
fn testCross(a:vec2<f32>, b:vec2<f32>, p:vec2<f32>) -> f32{
    return sign((b.y - a.y) * (p.x - a.x) - (b.x - a.x) * (p.y - a.y));
}

// Determine which side we're on (using barycentric parameterization)
fn signBezier(A: vec2<f32>, B: vec2<f32>, C: vec2<f32>, p:vec2<f32>) -> f32 { 
    let a = C - A;
    let b = B - A;
    let c = p - A;
    let bary = vec2(c.x * b.y - b.x * c.y, a.x * c.y - c.x * a.y) / (a.x * b.y - b.x * a.y);
    let d = vec2(bary.y * 0.5, 0.0) + 1.0 - bary.x - bary.y;
    return mix(sign(d.x * d.x - d.y), mix(-1.0, 1.0, 
        step(testCross(A, B, p) * testCross(B, C, p), 0.0)),
        step((d.x - d.y), 0.0)) * testCross(A, C, B);
}

// Solve cubic equation for roots
fn solveCubic(a: f32, b: f32, c: f32) -> vec3<f32> {
    let p = b - a * a / 3.0;
    let p3 = p * p * p;
    let q = a * (2.0 * a * a - 9.0 * b) / 27.0 + c;
    let d = q * q + 4.0 * p3 / 27.0;
    let offset = -a / 3.0;
    if(d >= 0.0) { 
        let z = sqrt(d);
        let x = (vec2(z, -z) - q) / 2.0;
        let uv = sign(x) * pow(abs(x), vec2(1.0 / 3.0));
        return vec3(offset + uv.x + uv.y);
    }
    let v = acos(-sqrt(-27.0 / p3) * q / 2.0) / 3.0;
    let m = cos(v);
    let n = sin(v) * 1.732050808;
    return vec3(m + m, -n - m, n - m) * sqrt(-p / 3.0) + offset;
}

// Find the signed distance from a point to a bezier curve
fn sdBezier(A: vec2<f32>, B_: vec2<f32>,C: vec2<f32>,p: vec2<f32>) -> f32{    
    let B = mix(B_ + vec2(1e-4), B_, abs(sign(B_ * 2.0 - A - C)));

    let a = B - A;
    let b = A - B * 2.0 + C;
    let c = a * 2.0;
    let d = A - p;
    
    let k = vec3(3.0 * dot(a,b), 2.0 * dot(a,a) + dot(d,b), dot(d,a)) / dot(b,b);      
    let t = clamp(solveCubic(k.x, k.y, k.z), vec3(0.0), vec3(1.0));
    
    var pos = A + (c + b * t.x) * t.x;
    var dis = length(pos - p);
    
    pos = A + (c + b * t.y) * t.y;
    dis = min(dis, length(pos - p));
    pos = A + (c + b * t.z) * t.z;
    dis = min(dis, length(pos - p));
    
    return dis * signBezier(A, B, C, p);
}


@stage(fragment) fn main( 
    @location(0) uv : vec2<f32>,
    @interpolate(flat) @location(1) instance_index: u32,
) -> @location(0) vec4<f32> {
    var col = vec4<f32>(0.0); 

    let p = uv;
    
    // Define the control points of our curve
    var A = ubos[instance_index].points[0].xy;
    var B = ubos[instance_index].points[1].xy;
    var C = ubos[instance_index].points[2].xy;

    if(ubos[instance_index].type_ == 2u){
        let tmp = A;
        A.x = C.x;
        A.y = B.y;
        C.y = B.y;
        B.y = tmp.y;
        C.x = tmp.x;
    }
    
    // Render the control points
    // var d = min(distance(p, A),min(distance(p, C),distance(p,B)));
    // if (d < 0.04) { 
    //   return vec4(1.0 - smoothstep(0.025, 0.034, d));
    // }
    
    // Get the signed distance to bezier curve
    let d = sdBezier(A, B, C, p);
    let tex_col = vec4(0.0,1.0,0.0,0.0);
    // Visualize the distance field using iq's orange/blue scheme
    if (ubos[instance_index].type_ == 1u){
        col = tex_col;
    }else{
        col = sign(d) * tex_col;
    }
    return col;
}
