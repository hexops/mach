const std = @import("std");
const testing = std.testing;
const Texture = @import("texture.zig").Texture;
const TextureView = @import("texture_view.zig").TextureView;
const Buffer = @import("buffer.zig").Buffer;
const ShaderModule = @import("shader_module.zig").ShaderModule;
const QuerySet = @import("query_set.zig").QuerySet;
const Surface = @import("surface.zig").Surface;

pub const array_layer_count_undef = 0xffffffff;
pub const copy_stride_undef = 0xffffffff;
pub const limit_u32_undef = 0xffffffff;
pub const limit_u64_undef = 0xffffffffffffffff;
pub const mip_level_count_undef = 0xffffffff;
pub const whole_map_size = std.math.maxInt(usize);
pub const whole_size = 0xffffffffffffffff;

/// Generic function pointer type, used for returning API function pointers. Must be
/// cast to the right `fn (...) callconv(.C) T` type before use.
pub const Proc = fn () callconv(.C) void;

pub const ComputePassTimestampWrite = extern struct {
    query_set: *QuerySet,
    query_index: u32,
    location: ComputePassTimestampLocation,
};

pub const RenderPassDepthStencilAttachment = extern struct {
    view: *TextureView,
    depth_load_op: LoadOp = .undef,
    depth_store_op: StoreOp = .undef,
    /// deprecated
    clear_depth: f32 = std.math.nan(f32),
    depth_clear_value: f32 = 0,
    depth_read_only: bool = false,
    stencil_load_op: LoadOp = .undef,
    stencil_store_op: StoreOp = .undef,
    /// deprecated
    clear_stencil: u32 = 0,
    stencil_clear_value: u32 = 0,
    stencil_read_only: bool = false,
};

pub const RenderPassTimestampWrite = extern struct {
    query_set: *QuerySet,
    query_index: u32,
    location: RenderPassTimestampLocation,
};

pub const RequestAdapterOptions = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    compatible_surface: ?*Surface = null,
    power_preference: PowerPreference = .undef,
    force_fallback_adapter: bool = false,
};

pub const ComputePassDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: ?[*:0]const u8 = null,
    timestamp_write_count: u32 = 0,
    timestamp_writes: ?[*]const ComputePassTimestampWrite = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        timestamp_writes: ?[]const ComputePassTimestampWrite = null,
    }) ComputePassDescriptor {
        return .{
            .next_in_chain = v.next_in_chain,
            .label = v.label,
            .timestamp_write_count = if (v.timestamp_writes) |e| @intCast(u32, e.len) else 0,
            .timestamp_writes = if (v.timestamp_writes) |e| e.ptr else null,
        };
    }
};

pub const RenderPassDescriptor = extern struct {
    pub const NextInChain = extern union {
        generic: ?*const ChainedStruct,
        max_draw_count: *const RenderPassDescriptorMaxDrawCount,
    };

    next_in_chain: NextInChain = .{ .generic = null },
    label: ?[*:0]const u8 = null,
    color_attachment_count: u32 = 0,
    color_attachments: ?[*]const RenderPassColorAttachment = null,
    depth_stencil_attachment: ?*const RenderPassDepthStencilAttachment = null,
    occlusion_query_set: ?*QuerySet = null,
    timestamp_write_count: u32 = 0,
    timestamp_writes: ?[*]const RenderPassTimestampWrite = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        next_in_chain: NextInChain = .{ .generic = null },
        label: ?[*:0]const u8 = null,
        color_attachments: ?[]const RenderPassColorAttachment = null,
        depth_stencil_attachment: ?*const RenderPassDepthStencilAttachment = null,
        occlusion_query_set: ?*QuerySet = null,
        timestamp_writes: ?[]const RenderPassTimestampWrite = null,
    }) RenderPassDescriptor {
        return .{
            .next_in_chain = v.next_in_chain,
            .label = v.label,
            .color_attachment_count = if (v.color_attachments) |e| @intCast(u32, e.len) else 0,
            .color_attachments = if (v.color_attachments) |e| e.ptr else null,
            .depth_stencil_attachment = v.depth_stencil_attachment,
            .occlusion_query_set = v.occlusion_query_set,
            .timestamp_write_count = if (v.timestamp_writes) |e| @intCast(u32, e.len) else 0,
            .timestamp_writes = if (v.timestamp_writes) |e| e.ptr else null,
        };
    }
};

pub const AlphaMode = enum(u32) { premultiplied = 0x00000000, unpremultiplied = 0x00000001, opaq = 0x00000002 };

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
    none = 0x00000000,
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

pub const RequestAdapterStatus = enum(u32) {
    success = 0x00000000,
    unavailable = 0x00000001,
    err = 0x00000002,
    unknown = 0x00000003,
};

pub const RequestDeviceStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    unknown = 0x00000002,
};

pub const SType = enum(u32) {
    invalid = 0x00000000,
    surface_descriptor_from_metal_layer = 0x00000001,
    surface_descriptor_from_windows_hwnd = 0x00000002,
    surface_descriptor_from_xlib_window = 0x00000003,
    surface_descriptor_from_canvas_html_selector = 0x00000004,
    shader_module_spirv_descriptor = 0x00000005,
    shader_module_wgsl_descriptor = 0x00000006,
    primitive_depth_clip_control = 0x00000007,
    surface_descriptor_from_wayland_surface = 0x00000008,
    surface_descriptor_from_android_native_window = 0x00000009,
    surface_descriptor_from_windows_core_window = 0x0000000B,
    external_texture_binding_entry = 0x0000000C,
    external_texture_binding_layout = 0x0000000D,
    surface_descriptor_from_windows_swap_chain_panel = 0x0000000E,
    render_pass_descriptor_max_draw_count = 0x0000000F,
    dawn_texture_internal_usage_descriptor = 0x000003E8,
    dawn_toggles_device_descriptor = 0x000003EA,
    dawn_encoder_internal_usage_descriptor = 0x000003EB,
    dawn_instance_descriptor = 0x000003EC,
    dawn_cache_device_descriptor = 0x000003ED,
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
    undef = 0x00000000,
    write_only = 0x00000001,
};

pub const StoreOp = enum(u32) {
    undef = 0x00000000,
    store = 0x00000001,
    discard = 0x00000002,
};

pub const VertexFormat = enum(u32) {
    undef = 0x00000000,
    uint8x2 = 0x00000001,
    uint8x4 = 0x00000002,
    sint8x2 = 0x00000003,
    sint8x4 = 0x00000004,
    unorm8x2 = 0x00000005,
    unorm8x4 = 0x00000006,
    snorm8x2 = 0x00000007,
    snorm8x4 = 0x00000008,
    uint16x2 = 0x00000009,
    uint16x4 = 0x0000000a,
    sint16x2 = 0x0000000b,
    sint16x4 = 0x0000000c,
    unorm16x2 = 0x0000000d,
    unorm16x4 = 0x0000000e,
    snorm16x2 = 0x0000000f,
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
    uint32x4 = 0x0000001a,
    sint32 = 0x0000001b,
    sint32x2 = 0x0000001c,
    sint32x3 = 0x0000001d,
    sint32x4 = 0x0000001e,
};

pub const VertexStepMode = enum(u32) {
    vertex = 0x00000000,
    instance = 0x00000001,
    vertex_buffer_not_used = 0x00000002,
};

pub const ColorWriteMaskFlags = packed struct {
    red: bool = false,
    green: bool = false,
    blue: bool = false,
    alpha: bool = false,

    _padding: u28 = 0,

    comptime {
        std.debug.assert(
            @sizeOf(@This()) == @sizeOf(u32) and
                @bitSizeOf(@This()) == @bitSizeOf(u32),
        );
    }

    pub const all = ColorWriteMaskFlags{
        .red = true,
        .green = true,
        .blue = true,
        .alpha = true,
    };

    pub fn equal(a: ColorWriteMaskFlags, b: ColorWriteMaskFlags) bool {
        return @truncate(u4, @bitCast(u32, a)) == @truncate(u4, @bitCast(u32, b));
    }
};

pub const MapModeFlags = packed struct {
    read: bool = false,
    write: bool = false,

    _padding: u30 = 0,

    comptime {
        std.debug.assert(
            @sizeOf(@This()) == @sizeOf(u32) and
                @bitSizeOf(@This()) == @bitSizeOf(u32),
        );
    }

    pub const undef = MapModeFlags{};

    pub fn equal(a: MapModeFlags, b: MapModeFlags) bool {
        return @truncate(u2, @bitCast(u32, a)) == @truncate(u2, @bitCast(u32, b));
    }
};

pub const ShaderStageFlags = packed struct {
    vertex: bool = false,
    fragment: bool = false,
    compute: bool = false,

    _padding: u29 = 0,

    comptime {
        std.debug.assert(
            @sizeOf(@This()) == @sizeOf(u32) and
                @bitSizeOf(@This()) == @bitSizeOf(u32),
        );
    }

    pub const none = ShaderStageFlags{};

    pub fn equal(a: ShaderStageFlags, b: ShaderStageFlags) bool {
        return @truncate(u3, @bitCast(u32, a)) == @truncate(u3, @bitCast(u32, b));
    }
};

pub const ChainedStruct = extern struct {
    // TODO: dawn: not marked as nullable in dawn.json but in fact is.
    next: ?*const ChainedStruct = null,
    s_type: SType,
};

pub const ChainedStructOut = extern struct {
    // TODO: dawn: not marked as nullable in dawn.json but in fact is.
    next: ?*ChainedStructOut = null,
    s_type: SType,
};

pub const BlendComponent = extern struct {
    operation: BlendOperation = .add,
    src_factor: BlendFactor = .one,
    dst_factor: BlendFactor = .zero,
};

pub const Color = extern struct {
    r: f64,
    g: f64,
    b: f64,
    a: f64,
};

pub const Extent3D = extern struct {
    width: u32,
    height: u32 = 1,
    depth_or_array_layers: u32 = 1,
};

pub const Limits = extern struct {
    max_texture_dimension_1d: u32 = limit_u32_undef,
    max_texture_dimension_2d: u32 = limit_u32_undef,
    max_texture_dimension_3d: u32 = limit_u32_undef,
    max_texture_array_layers: u32 = limit_u32_undef,
    max_bind_groups: u32 = limit_u32_undef,
    max_dynamic_uniform_buffers_per_pipeline_layout: u32 = limit_u32_undef,
    max_dynamic_storage_buffers_per_pipeline_layout: u32 = limit_u32_undef,
    max_sampled_textures_per_shader_stage: u32 = limit_u32_undef,
    max_samplers_per_shader_stage: u32 = limit_u32_undef,
    max_storage_buffers_per_shader_stage: u32 = limit_u32_undef,
    max_storage_textures_per_shader_stage: u32 = limit_u32_undef,
    max_uniform_buffers_per_shader_stage: u32 = limit_u32_undef,
    max_uniform_buffer_binding_size: u64 = limit_u64_undef,
    max_storage_buffer_binding_size: u64 = limit_u64_undef,
    min_uniform_buffer_offset_alignment: u32 = limit_u32_undef,
    min_storage_buffer_offset_alignment: u32 = limit_u32_undef,
    max_vertex_buffers: u32 = limit_u32_undef,
    max_vertex_attributes: u32 = limit_u32_undef,
    max_vertex_buffer_array_stride: u32 = limit_u32_undef,
    max_inter_stage_shader_components: u32 = limit_u32_undef,
    max_inter_stage_shader_variables: u32 = limit_u32_undef,
    max_color_attachments: u32 = limit_u32_undef,
    max_compute_workgroup_storage_size: u32 = limit_u32_undef,
    max_compute_invocations_per_workgroup: u32 = limit_u32_undef,
    max_compute_workgroup_size_x: u32 = limit_u32_undef,
    max_compute_workgroup_size_y: u32 = limit_u32_undef,
    max_compute_workgroup_size_z: u32 = limit_u32_undef,
    max_compute_workgroups_per_dimension: u32 = limit_u32_undef,
};

pub const Origin3D = extern struct {
    x: u32 = 0,
    y: u32 = 0,
    z: u32 = 0,
};

pub const CompilationMessage = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    message: ?[*:0]const u8 = null,
    type: CompilationMessageType,
    line_num: u64,
    line_pos: u64,
    offset: u64,
    length: u64,
};

pub const ConstantEntry = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    key: [*:0]const u8,
    value: f64,
};

pub const CopyTextureForBrowserOptions = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    flip_y: bool = false,
    needs_color_space_conversion: bool = false,
    src_alpha_mode: AlphaMode = .unpremultiplied,
    src_transfer_function_parameters: ?*const [7]f32 = null,
    conversion_matrix: ?*const [9]f32 = null,
    dst_transfer_function_parameters: ?*const [7]f32 = null,
    dst_alpha_mode: AlphaMode = .unpremultiplied,
    internal_usage: bool = false,
};

pub const MultisampleState = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    count: u32 = 1,
    mask: u32 = 0xFFFFFFFF,
    alpha_to_coverage_enabled: bool = false,
};

pub const PrimitiveDepthClipControl = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .primitive_depth_clip_control },
    unclipped_depth: bool = false,
};

pub const PrimitiveState = extern struct {
    pub const NextInChain = extern union {
        generic: ?*const ChainedStruct,
        primitive_depth_clip_control: *const PrimitiveDepthClipControl,
    };

    next_in_chain: NextInChain = .{ .generic = null },
    topology: PrimitiveTopology = .triangle_list,
    strip_index_format: IndexFormat = .undef,
    front_face: FrontFace = .ccw,
    cull_mode: CullMode = .none,
};

pub const RenderPassDescriptorMaxDrawCount = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .render_pass_descriptor_max_draw_count },
    max_draw_count: u64 = 50000000,
};

pub const StencilFaceState = extern struct {
    compare: CompareFunction = .always,
    fail_op: StencilOperation = .keep,
    depth_fail_op: StencilOperation = .keep,
    pass_op: StencilOperation = .keep,
};

pub const StorageTextureBindingLayout = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    access: StorageTextureAccess = .undef,
    format: Texture.Format = .undef,
    view_dimension: TextureView.Dimension = .dimension_undef,
};

pub const VertexAttribute = extern struct {
    format: VertexFormat,
    offset: u64,
    shader_location: u32,
};

pub const BlendState = extern struct {
    color: BlendComponent = .{},
    alpha: BlendComponent = .{},
};

pub const CompilationInfo = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    message_count: u32,
    messages: ?[*]const CompilationMessage = null,

    /// Helper to get messages as a slice.
    pub fn getMessages(info: CompilationInfo) ?[]const CompilationMessage {
        if (info.messages) |messages| {
            return messages[0..info.message_count];
        }
        return null;
    }
};

pub const DepthStencilState = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    format: Texture.Format,
    depth_write_enabled: bool = false,
    depth_compare: CompareFunction = .always,
    stencil_front: StencilFaceState = .{},
    stencil_back: StencilFaceState = .{},
    stencil_read_mask: u32 = 0xFFFFFFFF,
    stencil_write_mask: u32 = 0xFFFFFFFF,
    depth_bias: i32 = 0,
    depth_bias_slope_scale: f32 = 0.0,
    depth_bias_clamp: f32 = 0.0,
};

pub const ImageCopyBuffer = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    layout: Texture.DataLayout,
    buffer: *Buffer,
};

pub const ImageCopyTexture = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    texture: *Texture,
    mip_level: u32 = 0,
    origin: Origin3D = .{},
    aspect: Texture.Aspect = .all,
};

pub const ProgrammableStageDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    module: *ShaderModule,
    entry_point: [*:0]const u8,
    constant_count: u32 = 0,
    constants: ?[*]const ConstantEntry = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        next_in_chain: ?*const ChainedStruct = null,
        module: *ShaderModule,
        entry_point: [*:0]const u8,
        constants: ?[]const ConstantEntry = null,
    }) ProgrammableStageDescriptor {
        return .{
            .next_in_chain = v.next_in_chain,
            .module = v.module,
            .entry_point = v.entry_point,
            .constant_count = if (v.constants) |e| @intCast(u32, e.len) else 0,
            .constants = if (v.constants) |e| e.ptr else null,
        };
    }
};

pub const RenderPassColorAttachment = extern struct {
    view: ?*TextureView = null,
    resolve_target: ?*TextureView = null,
    load_op: LoadOp,
    store_op: StoreOp,
    /// deprecated
    clear_color: Color = .{
        .r = std.math.nan(f64),
        .g = std.math.nan(f64),
        .b = std.math.nan(f64),
        .a = std.math.nan(f64),
    },
    clear_value: Color,
};

pub const RequiredLimits = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    limits: Limits,
};

pub const SupportedLimits = extern struct {
    next_in_chain: ?*ChainedStructOut = null,
    limits: Limits,
};

pub const VertexBufferLayout = extern struct {
    array_stride: u64,
    step_mode: VertexStepMode = .vertex,
    attribute_count: u32,
    attributes: ?[*]const VertexAttribute = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        array_stride: u64,
        step_mode: VertexStepMode = .vertex,
        attributes: ?[]const VertexAttribute = null,
    }) VertexBufferLayout {
        return .{
            .array_stride = v.array_stride,
            .step_mode = v.step_mode,
            .attribute_count = if (v.attributes) |e| @intCast(u32, e.len) else 0,
            .attributes = if (v.attributes) |e| e.ptr else null,
        };
    }
};

pub const ColorTargetState = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    format: Texture.Format,
    blend: ?*const BlendState = null,
    write_mask: ColorWriteMaskFlags = ColorWriteMaskFlags.all,
};

pub const VertexState = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    module: *ShaderModule,
    entry_point: [*:0]const u8,
    constant_count: u32 = 0,
    constants: ?[*]const ConstantEntry = null,
    buffer_count: u32 = 0,
    buffers: ?[*]const VertexBufferLayout = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        next_in_chain: ?*const ChainedStruct = null,
        module: *ShaderModule,
        entry_point: [*:0]const u8,
        constants: ?[]const ConstantEntry = null,
        buffers: ?[]const VertexBufferLayout = null,
    }) VertexState {
        return .{
            .next_in_chain = v.next_in_chain,
            .module = v.module,
            .entry_point = v.entry_point,
            .constant_count = if (v.constants) |e| @intCast(u32, e.len) else 0,
            .constants = if (v.constants) |e| e.ptr else null,
            .buffer_count = if (v.buffers) |e| @intCast(u32, e.len) else 0,
            .buffers = if (v.buffers) |e| e.ptr else null,
        };
    }
};

pub const FragmentState = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    module: *ShaderModule,
    entry_point: [*:0]const u8,
    constant_count: u32 = 0,
    constants: ?[*]const ConstantEntry = null,
    target_count: u32,
    targets: ?[*]const ColorTargetState = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        next_in_chain: ?*const ChainedStruct = null,
        module: *ShaderModule,
        entry_point: [*:0]const u8,
        constants: ?[]const ConstantEntry = null,
        targets: ?[]const ColorTargetState = null,
    }) FragmentState {
        return .{
            .next_in_chain = v.next_in_chain,
            .module = v.module,
            .entry_point = v.entry_point,
            .constant_count = if (v.constants) |e| @intCast(u32, e.len) else 0,
            .constants = if (v.constants) |e| e.ptr else null,
            .target_count = if (v.targets) |e| @intCast(u32, e.len) else 0,
            .targets = if (v.targets) |e| e.ptr else null,
        };
    }
};

test "BackendType name" {
    try testing.expectEqualStrings("Vulkan", BackendType.vulkan.name());
}

test "enum name" {
    try testing.expectEqualStrings("front", @tagName(CullMode.front));
}
