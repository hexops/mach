struct Uniforms {
  mvp_matrix : mat4x4<f32>,
};

@binding(0) @group(0) var<uniform> ubo : Uniforms;

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
};

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) normal: vec3<f32>,
};

@vertex fn vertex_main(in : VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.position = vec4<f32>(in.position, 1.0) * ubo.mvp_matrix;
    out.normal = in.normal;
    return out;
}

struct FragmentOutput {
    @location(0) pixel_color: vec4<f32>
};

@fragment fn frag_main(in: VertexOutput) -> FragmentOutput {
    var out : FragmentOutput;

    out.pixel_color = vec4<f32>((in.normal + 1) / 2, 1.0);
    return out;
}