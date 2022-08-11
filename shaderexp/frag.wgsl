struct UniformBufferObject {
    resolution: vec2<f32>,
    time: f32,
}
@group(0) @binding(0) var<uniform> ubo : UniformBufferObject;

fn getDist(p:vec3<f32>) -> f32{
    let dist_from_center:f32 = 2.*sin(ubo.time * 3.);
    let rotation_speed:f32 = 6.;
    
    let sphere1 = vec4<f32>(dist_from_center*cos(rotation_speed*ubo.time + 3.14159 * 0. * 2. / 3.),1.1, dist_from_center*sin(rotation_speed*ubo.time + 3.14159 + 3.14159 * 0. * 2. / 3.),1.);
    let sphere2 = vec4<f32>(dist_from_center*cos(rotation_speed*ubo.time + 3.14159 * 1. * 2. / 3.),1.1, dist_from_center*sin(rotation_speed*ubo.time + 3.14159 + 3.14159 * 1. * 2. / 3.),1.);
    let sphere3 = vec4<f32>(dist_from_center*cos(rotation_speed*ubo.time + 3.14159 * 2. * 2. / 3.),1.1, dist_from_center*sin(rotation_speed*ubo.time + 3.14159 + 3.14159 * 2. * 2. / 3.),1.);

    let sphere1_dist:f32 = length(p - sphere1.xyz) - sphere1.w;
    let sphere2_dist:f32 = length(p - sphere2.xyz) - sphere2.w;
    let sphere3_dist:f32 = length(p - sphere3.xyz) - sphere3.w;
    let plane_dist = p.y;
    
    return min(min(min(sphere1_dist,sphere2_dist),sphere3_dist),plane_dist);
}

fn rayMarch(ro:vec3<f32>, rd:vec3<f32>) -> f32{
    let MAX_STEPS:i32 = 100;
    let MAX_DIST:f32 = 100.0;
    let SURF_DIST:f32 = 0.01;
    var d:f32 = 0.0;
    
    var i: i32 = 0;
    loop {
      if(i >= MAX_STEPS){
        break;
      }

      let p = ro + rd * d;
      let ds = getDist(p);
      d = d + ds;
      if(d > MAX_DIST || ds <= SURF_DIST){
        break;
      } 

      i = i + 1;
    }
    return d;
}

fn getNormal(p:vec3<f32>) -> vec3<f32>{
    let d = getDist(p);
    let e = vec2<f32>(0.1,0.0);
    
    // We can find the normal using the points around the hit point
    let n = d - vec3<f32>(
        getDist(p-e.xyy),
        getDist(p-e.yxy),
        getDist(p-e.yyx)
      );
        
    return normalize(n);
}

fn getLight(p:vec3<f32>) -> f32{
    let SURF_DIST:f32 = .01;

    let light_pos = vec3<f32>(0.,5.,0.);
    let l = normalize(light_pos - p) * 1.;
    let n = getNormal(p);
    
    var dif = clamp(dot(n,l),.0,1.);
    
    let d = rayMarch(p + n * SURF_DIST * 2.,l);
    if(d<length(light_pos - p)){
        dif = dif * .1;
    }
    
    return dif;
}

@fragment fn main(
    @location(0) uv : vec2<f32>
) -> @location(0) vec4<f32> {
    let aspect = ubo.resolution / min(ubo.resolution.x,ubo.resolution.y);
    let tmp_uv = (uv - vec2(0.5,0.5)) * aspect * 2.0;
    var col = vec3<f32>(0.0);
    
    let r_origin = vec3<f32>(4.0,3.,.0);
    let r_dir = normalize(vec3<f32>(-1.0,tmp_uv.y,tmp_uv.x));
    let d = rayMarch(r_origin,r_dir);
    col = vec3<f32>(d / 8.);
    let p = r_origin + r_dir * d;
    let diff = getLight(p);
    
    col = vec3<f32>(0.0, diff, 0.0);
    return vec4<f32>(col,0.0);
}
