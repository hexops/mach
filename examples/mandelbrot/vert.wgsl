struct UBO {
    transform: mat4x4<f32>;
    time: f32;
}

@group(0) @binding(0) var<uniform> ubo : UBO;
struct VertexOut {
     @builtin(position) position_clip : vec4<f32>;
     @location(0) frag_uv : vec2<f32>;
}

@stage(vertex) fn main(
     @location(0) position : vec3<f32>,
     @location(1) uv : vec2<f32>
) -> VertexOut {
     var output : VertexOut;
     output.position_clip = vec4(position, 1.0) * ubo.transform;
     output.frag_uv = uv;
     return output;
}
