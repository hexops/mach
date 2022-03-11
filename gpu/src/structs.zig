//! Structures which are not ABI compatible with webgpu.h
const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const Texture = @import("Texture.zig");
const TextureView = @import("TextureView.zig");
const StencilFaceState = @import("data.zig").StencilFaceState;
const CompilationMessageType = @import("enums.zig").CompilationMessageType;
const PrimitiveTopology = @import("enums.zig").PrimitiveTopology;
const IndexFormat = @import("enums.zig").IndexFormat;
const FrontFace = @import("enums.zig").FrontFace;
const CullMode = @import("enums.zig").CullMode;
const StorageTextureAccess = @import("enums.zig").StorageTextureAccess;
const CompareFunction = @import("enums.zig").CompareFunction;

pub const CompilationMessage = struct {
    message: [:0]const u8,
    type: CompilationMessageType,
    line_num: u64,
    line_pos: u64,
    offset: u64,
    length: u64,
};

pub const CompilationInfo = struct {
    messages: []const CompilationMessage,
};

pub const MultisampleState = struct {
    count: u32,
    mask: u32,
    alpha_to_coverage_enabled: bool,
};

pub const PrimitiveState = struct {
    topology: PrimitiveTopology,
    strip_index_format: IndexFormat,
    front_face: FrontFace,
    cull_mode: CullMode,
};

pub const StorageTextureBindingLayout = struct {
    access: StorageTextureAccess,
    format: Texture.Format,
    view_dimension: TextureView.Dimension,
};

pub const DepthStencilState = struct {
    format: Texture.Format,
    depth_write_enabled: bool,
    depth_compare: CompareFunction,
    stencil_front: StencilFaceState,
    stencil_back: StencilFaceState,
    stencil_read_mask: u32,
    stencil_write_mask: u32,
    depth_bias: i32,
    depth_bias_slope_scale: f32,
    depth_bias_clamp: f32,
};

pub const ProgrammableStageDescriptor = struct {
    label: ?[*:0]const u8 = null,
    module: ShaderModule,
    entryPoint: [*:0]const u8,
    constants: []const ConstantEntry,
};

test "syntax" {
    _ = CompilationMessage;
    _ = CompilationInfo;
    _ = MultisampleState;
    _ = PrimitiveState;
    _ = StorageTextureBindingLayout;
    _ = DepthStencilState;
    _ = ProgrammableStageDescriptor;
}
