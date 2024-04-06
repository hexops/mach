// TODO(important): docs
struct Uniform {
    pos: vec4<f32>,
	scale: f32,
};

@group(0) @binding(0) var<uniform> in : Uniform;

@vertex fn vertex_main(
    @builtin(vertex_index) VertexIndex : u32
) -> @builtin(position) vec4<f32> {
    var positions = array<vec2<f32>, 3>(
        vec2<f32>( 0.0,  0.1),
        vec2<f32>(-0.1, -0.1),
        vec2<f32>( 0.1, -0.1)
    );
    var pos = positions[VertexIndex];
    return vec4<f32>((pos*in.scale)+in.pos.xy, 0.0, 1.0);
}

@fragment fn frag_main() -> @location(0) vec4<f32> {
    return vec4<f32>(1.0, 0.0, 0.0, 0.0);
}
