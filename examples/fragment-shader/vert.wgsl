// The layout of the UniformBufferObject as seen by the shader
struct UniformBufferObject {
    transform: mat4x4<f32>;
    time: f32;
}

@group(0) @binding(0) var<uniform> ubo : UniformBufferObject;
struct VertexOut {
     @builtin(position) position_clip : vec4<f32>;

     // We will pass the frag_uv to the fragment shader,
     // note that when passing values this way, the
     // values passed from the vertex stage to the fragment stage
     // will be interpolated, this means that even if we send
     // values like 0 and 1 to the vertex shader, the fragment
     // shader will receive all the values in-between too
     @location(0) frag_uv : vec2<f32>;
}

@stage(vertex) fn main(
     @location(0) position : vec3<f32>,
     @location(1) uv : vec2<f32>
) -> VertexOut {
     var output : VertexOut;
     output.position_clip = ubo.transform * vec4(position, 1.0);
     output.frag_uv = uv;
     return output;
}
