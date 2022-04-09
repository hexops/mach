//! Data structures that are ABI-compatible with webgpu.h

const BlendOperation = @import("enums.zig").BlendOperation;
const BlendFactor = @import("enums.zig").BlendFactor;
const CompareFunction = @import("enums.zig").CompareFunction;
const StencilOperation = @import("enums.zig").StencilOperation;
const VertexFormat = @import("enums.zig").VertexFormat;
const VertexStepMode = @import("enums.zig").VertexStepMode;

pub const Limits = extern struct {
    max_texture_dimension_1d: u32,
    max_texture_dimension_2d: u32,
    max_texture_dimension_3d: u32,
    max_texture_array_layers: u32,
    max_bind_groups: u32,
    max_dynamic_uniform_buffers_per_pipeline_layout: u32,
    max_dynamic_storage_buffers_per_pipeline_layout: u32,
    max_sampled_textures_per_shader_stage: u32,
    max_samplers_per_shader_stage: u32,
    max_storage_buffers_per_shader_stage: u32,
    max_storage_textures_per_shader_stage: u32,
    max_uniform_buffers_per_shader_stage: u32,
    max_uniform_buffer_binding_size: u64,
    max_storage_buffer_binding_size: u64,
    min_uniform_buffer_offset_alignment: u32,
    min_storage_buffer_offset_alignment: u32,
    max_vertex_buffers: u32,
    max_vertex_attributes: u32,
    max_vertex_buffer_array_stride: u32,
    max_inter_stage_shader_components: u32,
    max_compute_workgroup_storage_size: u32,
    max_compute_invocations_per_workgroup: u32,
    max_compute_workgroup_size_x: u32,
    max_compute_workgroup_size_y: u32,
    max_compute_workgroup_size_z: u32,
    max_compute_workgroups_per_dimension: u32,
};

pub const Color = extern struct {
    r: f64,
    g: f64,
    b: f64,
    a: f64,
};

pub const Extent3D = extern struct {
    width: u32,
    height: u32,
    depth_or_array_layers: u32,
};

pub const Origin3D = extern struct {
    x: u32,
    y: u32,
    z: u32,
};

pub const StencilFaceState = extern struct {
    compare: CompareFunction,
    fail_op: StencilOperation,
    depth_fail_op: StencilOperation,
    pass_op: StencilOperation,
};

pub const VertexAttribute = extern struct {
    format: VertexFormat,
    offset: u64,
    shader_location: u32,
};

pub const BlendComponent = extern struct {
    operation: BlendOperation,
    src_factor: BlendFactor,
    dst_factor: BlendFactor,
};

pub const BlendState = extern struct {
    color: BlendComponent,
    alpha: BlendComponent,
};

pub const VertexBufferLayout = extern struct {
    array_stride: u64,
    step_mode: VertexStepMode,
    attribute_count: u32,
    attributes: [*]const VertexAttribute,
};

test {
    _ = Limits;
    _ = Color;
    _ = Extent3D;
    _ = Origin3D;
    _ = StencilFaceState;
    _ = VertexAttribute;
    _ = BlendComponent;
    _ = BlendState;
    _ = VertexBufferLayout;
}
