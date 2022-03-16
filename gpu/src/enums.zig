const std = @import("std");

pub const Feature = enum(u32) {
    depth24_unorm_stencil8 = 0x00000002,
    depth32_float_stencil8 = 0x00000003,
    timestamp_query = 0x00000004,
    pipeline_statistics_query = 0x00000005,
    texture_compression_bc = 0x00000006,
    texture_compression_etc2 = 0x00000007,
    texture_compression_astc = 0x00000008,
    indirect_first_instance = 0x00000009,
    depth_clamping = 0x000003e8,
    dawn_shader_float16 = 0x000003e9,
    dawn_internal_usages = 0x000003ea,
    dawn_multi_planar_formats = 0x000003eb,
    dawn_native = 0x000003ec,
};

pub const AddressMode = enum(u32) {
    repeat = 0x00000000,
    mirror_repeat = 0x00000001,
    clamp_to_edge = 0x00000002,
};

pub const PresentMode = enum(u32) {
    immediate = 0x00000000,
    mailbox = 0x00000001,
    fifo = 0x00000002,
};

pub const AlphaMode = enum(u32) {
    premultiplied = 0x00000000,
    unpremultiplied = 0x00000001,
};

pub const BlendFactor = enum(u32) {
    zero = 0x00000000,
    one = 0x00000001,
    src = 0x00000002,
    one_minus_src = 0x00000003,
    src_alpha = 0x00000004,
    oneMinusSrcAlpha = 0x00000005,
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
    none = 0x00000000,
    never = 0x00000001,
    less = 0x00000002,
    less_equal = 0x00000003,
    greater = 0x00000004,
    greater_equal = 0x00000005,
    equal = 0x00000006,
    not_equal = 0x00000007,
    always = 0x00000008,
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
    none = 0x00000000,
    front = 0x00000001,
    back = 0x00000002,
};

pub const ErrorFilter = enum(u32) {
    validation = 0x00000000,
    out_of_memory = 0x00000001,
};

pub const ErrorType = enum(u32) {
    noError = 0x00000000,
    validation = 0x00000001,
    out_of_memory = 0x00000002,
    unknown = 0x00000003,
    device_lost = 0x00000004,
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
    none = 0x00000000,
    uint16 = 0x00000001,
    uint32 = 0x00000002,
};

pub const LoadOp = enum(u32) {
    none = 0x00000000,
    clear = 0x00000001,
    load = 0x00000002,
};

pub const LoggingType = enum(u32) {
    verbose = 0x00000000,
    info = 0x00000001,
    warning = 0x00000002,
    err = 0x00000003,
};

pub const PipelineStatistic = enum(u32) {
    vertex_shader_invocations = 0x00000000,
    clipper_invocations = 0x00000001,
    clipper_primitives_out = 0x00000002,
    fragment_shader_invocations = 0x00000003,
    compute_shader_invocations = 0x00000004,
};

pub const PowerPreference = enum(u32) {
    none = 0x00000000,
    low_power = 0x00000001,
    high_performance = 0x00000002,
};

pub const PredefinedColorSpace = enum(u32) {
    none = 0x00000000,
    srgb = 0x00000001,
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

pub const StencilOperation = enum(u32) {
    keep = 0x00000000,
    zero = 0x00000001,
    replace = 0x00000002,
    invert = 0x00000003,
    increment_clamp = 0x00000004,
    decrement_clamp = 0x00000005,
    increment_wrap = 0x00000006,
    decrement_wrap = 0x00000007,
};

pub const StorageTextureAccess = enum(u32) {
    none = 0x00000000,
    write_only = 0x00000001,
};

pub const StoreOp = enum(u32) {
    none = 0x00000000,
    store = 0x00000001,
    discard = 0x00000002,
};

pub const VertexFormat = enum(u32) {
    none = 0x00000000,
    uint8x2 = 0x00000001,
    uint8x4 = 0x00000002,
    sint8x2 = 0x00000003,
    sint8x4 = 0x00000004,
    unorm8x2 = 0x00000005,
    unorm8x4 = 0x00000006,
    snorm8x2 = 0x00000007,
    snorm8x4 = 0x00000008,
    uint16x2 = 0x00000009,
    uint16x4 = 0x0000000A,
    sint16x2 = 0x0000000B,
    sint16x4 = 0x0000000C,
    unorm16x2 = 0x0000000D,
    unorm16x4 = 0x0000000E,
    snorm16x2 = 0x0000000F,
    snorm16x4 = 0x00000010,
    float16x2 = 0x00000011,
    float16x4 = 0x00000012,
    float32 = 0x00000013,
    float32x2 = 0x00000014,
    float32x3 = 0x00000015,
    float32x4 = 0x00000016,
    uint32 = 0x00000017,
    uint32x2 = 0x00000018,
    uint32x3 = 0x00000019,
    uint32x4 = 0x0000001A,
    sint32 = 0x0000001B,
    sint32x2 = 0x0000001C,
    sint32x3 = 0x0000001D,
    sint32x4 = 0x0000001E,
};

pub const VertexStepMode = enum(u32) {
    vertex = 0x00000000,
    instance = 0x00000001,
};

pub const BufferUsage = enum(u32) {
    none = 0x00000000,
    map_read = 0x00000001,
    map_write = 0x00000002,
    copy_src = 0x00000004,
    copy_dst = 0x00000008,
    index = 0x00000010,
    vertex = 0x00000020,
    uniform = 0x00000040,
    storage = 0x00000080,
    indirect = 0x00000100,
    query_resolve = 0x00000200,
};

pub const ColorWriteMask = enum(u32) {
    none = 0x00000000,
    red = 0x00000001,
    green = 0x00000002,
    blue = 0x00000004,
    alpha = 0x00000008,
    all = 0x0000000F,
};

pub const ShaderStage = enum(u32) {
    none = 0x00000000,
    vertex = 0x00000001,
    fragment = 0x00000002,
    compute = 0x00000004,
};

test "name" {
    try std.testing.expect(std.mem.eql(u8, @tagName(Feature.timestamp_query), "timestamp_query"));
}

test "syntax" {
    _ = Feature;
    _ = AddressMode;
    _ = PresentMode;
    _ = AlphaMode;
    _ = BlendFactor;
    _ = BlendOperation;
    _ = CompareFunction;
    _ = ComputePassTimestampLocation;
    _ = CreatePipelineAsyncStatus;
    _ = CullMode;
    _ = ErrorFilter;
    _ = ErrorType;
    _ = FilterMode;
    _ = FrontFace;
    _ = IndexFormat;
    _ = LoadOp;
    _ = LoggingType;
    _ = PipelineStatistic;
    _ = PowerPreference;
    _ = PredefinedColorSpace;
    _ = PrimitiveTopology;
    _ = QueryType;
    _ = RenderPassTimestampLocation;
    _ = StencilOperation;
    _ = StorageTextureAccess;
    _ = StoreOp;
    _ = VertexFormat;
    _ = VertexStepMode;
    _ = BufferUsage;
    _ = ColorWriteMask;
    _ = ShaderStage;
}
