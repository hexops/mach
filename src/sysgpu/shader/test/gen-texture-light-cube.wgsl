struct CameraUniform {
    pos: vec4<f32>,
	view_proj: mat4x4<f32>,
};

struct InstanceInput {
    @location(3) model_matrix_0: vec4<f32>,
    @location(4) model_matrix_1: vec4<f32>,
    @location(5) model_matrix_2: vec4<f32>,
    @location(6) model_matrix_3: vec4<f32>,
};

struct VertexInput {
	@location(0) position: vec3<f32>,
	@location(1) normal: vec3<f32>,
	@location(2) tex_coords: vec2<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) position: vec3<f32>,
};

struct Light {
	position: vec4<f32>,
	color: vec4<f32>,
};

@group(0) @binding(0) var<uniform> camera: CameraUniform;
@group(1) @binding(0) var t_diffuse: texture_2d<f32>;
@group(1) @binding(1) var s_diffuse: sampler;
@group(2) @binding(0) var<uniform> light: Light;

@vertex
fn vs_main(model: VertexInput, instance: InstanceInput) -> VertexOutput {
	let model_matrix = mat4x4<f32>(
    	instance.model_matrix_0,
    	instance.model_matrix_1,
    	instance.model_matrix_2,
    	instance.model_matrix_3,
	);
    var out: VertexOutput;
    let world_pos = model_matrix * vec4<f32>(model.position, 1.0);
    out.position = world_pos.xyz;
    out.normal = (model_matrix * vec4<f32>(model.normal, 0.0)).xyz;
    out.clip_position = camera.view_proj * world_pos;
    out.tex_coords = model.tex_coords;
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let object_color = textureSample(t_diffuse, s_diffuse, in.tex_coords);

	let ambient = 0.1;
	let ambient_color = light.color.rbg * ambient;

	let light_dir = normalize(light.position.xyz - in.position);
	let diffuse = max(dot(in.normal, light_dir), 0.0);
	let diffuse_color = light.color.rgb * diffuse;

	let view_dir = normalize(camera.pos.xyz - in.position);
	let half_dir = normalize(view_dir + light_dir);
	let specular = pow(max(dot(in.normal, half_dir), 0.0), 32.0);
	let specular_color = light.color.rbg * specular;

	let all = ambient_color + diffuse_color + specular_color;

	let result = all * object_color.rgb;

	return vec4<f32>(result, object_color.a);

}
