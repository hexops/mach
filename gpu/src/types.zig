const testing = @import("std").testing;

pub const AlphaMode = enum(u32) {
    premultiplied = 0x00000000,
    unpremultiplied = 0x00000001,
};

pub const BackendType = enum(u32) {
    nul,
    webgpu,
    d3d11,
    d3d12,
    metal,
    vulkan,
    opengl,
    opengles,

    pub fn name(t: BackendType) []const u8 {
        return switch (t) {
            .nul => "Null",
            .webgpu => "WebGPU",
            .d3d11 => "D3D11",
            .d3d12 => "D3D12",
            .metal => "Metal",
            .vulkan => "Vulkan",
            .opengl => "OpenGL",
            .opengles => "OpenGLES",
        };
    }
};

pub const BlendFactor = enum(u32) {
    zero = 0x00000000,
    one = 0x00000001,
    src = 0x00000002,
    one_minus_src = 0x00000003,
    src_alpha = 0x00000004,
    one_minus_src_alpha = 0x00000005,
    dst = 0x00000006,
    one_minus_dst = 0x00000007,
    dst_alpha = 0x00000008,
    one_minus_dst_alpha = 0x00000009,
    src_alpha_saturated = 0x0000000A,
    constant = 0x0000000B,
    one_minus_constant = 0x0000000C,
};

pub const BlendOperation = enum(u32) {
    add = 0x00000000,
    subtract = 0x00000001,
    reverse_subtract = 0x00000002,
    min = 0x00000003,
    max = 0x00000004,
};

pub const CompareFunction = enum(u32) {
    undef = 0x00000000,
    never = 0x00000001,
    less = 0x00000002,
    less_equal = 0x00000003,
    greater = 0x00000004,
    greater_equal = 0x00000005,
    equal = 0x00000006,
    not_equal = 0x00000007,
    always = 0x00000008,
};

pub const CompilationInfoRequestStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    device_lost = 0x00000002,
    unknown = 0x00000003,
};

pub const CompilationMessageType = enum(u32) {
    err = 0x00000000,
    warning = 0x00000001,
    info = 0x00000002,
};

pub const ComputePassTimestampLocation = enum(u32) {
    beginning = 0x00000000,
    end = 0x00000001,
};

pub const CreatePipelineAsyncStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    device_lost = 0x00000002,
    device_destroyed = 0x00000003,
    unknown = 0x00000004,
};

pub const CullMode = enum(u32) {
    undef = 0x00000000,
    front = 0x00000001,
    back = 0x00000002,
};

pub const ErrorFilter = enum(u32) {
    validation = 0x00000000,
    out_of_memory = 0x00000001,
};

pub const ErrorType = enum(u32) {
    no_error = 0x00000000,
    validation = 0x00000001,
    out_of_memory = 0x00000002,
    unknown = 0x00000003,
    device_lost = 0x00000004,
};

pub const FeatureName = enum(u32) {
    undef = 0x00000000,
    depth_clip_control = 0x00000001,
    depth32_float_stencil8 = 0x00000002,
    timestamp_query = 0x00000003,
    pipeline_statistics_query = 0x00000004,
    texture_compression_bc = 0x00000005,
    texture_compression_etc2 = 0x00000006,
    texture_compression_astc = 0x00000007,
    indirect_first_instance = 0x00000008,
    depth_clamping = 0x000003e8,
    dawn_shader_float16 = 0x000003e9,
    dawn_internal_usages = 0x000003ea,
    dawn_multi_planar_formats = 0x000003eb,
    dawn_native = 0x000003ec,
    chromium_experimental_dp4a = 0x000003ed,
};

pub const FilterMode = enum(u32) {
    nearest = 0x00000000,
    linear = 0x00000001,
};

pub const FrontFace = enum(u32) {
    ccw = 0x00000000,
    cw = 0x00000001,
};

pub const IndexFormat = enum(u32) {
    undef = 0x00000000,
    uint16 = 0x00000001,
    uint32 = 0x00000002,
};

pub const LoadOp = enum(u32) {
    undef = 0x00000000,
    clear = 0x00000001,
    load = 0x00000002,
};

pub const LoggingType = enum(u32) {
    verbose = 0x00000000,
    info = 0x00000001,
    warning = 0x00000002,
    err = 0x00000003,
};

pub const PipelineStatisticName = enum(u32) {
    vertex_shader_invocations = 0x00000000,
    clipper_invocations = 0x00000001,
    clipper_primitives_out = 0x00000002,
    fragment_shader_invocations = 0x00000003,
    compute_shader_invocations = 0x00000004,
};

pub const PowerPreference = enum(u32) {
    undef = 0x00000000,
    low_power = 0x00000001,
    high_performance = 0x00000002,
};

pub const PresentMode = enum(u32) {
    immediate = 0x00000000,
    mailbox = 0x00000001,
    fifo = 0x00000002,
};

pub const PrimitiveTopology = enum(u32) {
    point_list = 0x00000000,
    line_list = 0x00000001,
    line_strip = 0x00000002,
    triangle_list = 0x00000003,
    triangle_strip = 0x00000004,
};

pub const QueryType = enum(u32) {
    occlusion = 0x00000000,
    pipeline_statistics = 0x00000001,
    timestamp = 0x00000002,
};

pub const RenderPassTimestampLocation = enum(u32) {
    beginning = 0x00000000,
    end = 0x00000001,
};

test "BackendType name" {
    try testing.expectEqualStrings("Vulkan", BackendType.vulkan.name());
}

test "enum name" {
    try testing.expectEqualStrings("front", @tagName(CullMode.front));
}
