//! Structures which are not ABI compatible with webgpu.h
const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const Texture = @import("Texture.zig");
const TextureView = @import("TextureView.zig");
const ShaderModule = @import("ShaderModule.zig");
const QuerySet = @import("QuerySet.zig");
const StencilFaceState = @import("data.zig").StencilFaceState;
const Color = @import("data.zig").Color;
const VertexBufferLayout = @import("data.zig").VertexBufferLayout;
const BlendState = @import("data.zig").BlendState;
const Origin3D = @import("data.zig").Origin3D;
const PrimitiveTopology = @import("enums.zig").PrimitiveTopology;
const IndexFormat = @import("enums.zig").IndexFormat;
const FrontFace = @import("enums.zig").FrontFace;
const CullMode = @import("enums.zig").CullMode;
const StorageTextureAccess = @import("enums.zig").StorageTextureAccess;
const CompareFunction = @import("enums.zig").CompareFunction;
const ComputePassTimestampLocation = @import("enums.zig").ComputePassTimestampLocation;
const RenderPassTimestampLocation = @import("enums.zig").RenderPassTimestampLocation;
const LoadOp = @import("enums.zig").LoadOp;
const StoreOp = @import("enums.zig").StoreOp;
const ColorWriteMask = @import("enums.zig").ColorWriteMask;
const ErrorType = @import("enums.zig").ErrorType;
const LoggingType = @import("enums.zig").LoggingType;

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

pub const StorageTextureBindingLayout = extern struct {
    reserved: ?*anyopaque = null,
    access: StorageTextureAccess = .write_only,
    format: Texture.Format,
    view_dimension: TextureView.Dimension = .dimension_2d,
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

// TODO: how does this map to browser API?
pub const ConstantEntry = extern struct {
    reserved: ?*anyopaque = null,
    key: [*:0]const u8,
    value: f64,
};

pub const ProgrammableStageDescriptor = struct {
    label: ?[*:0]const u8 = null,
    module: ShaderModule,
    entry_point: [*:0]const u8,
    constants: ?[]const ConstantEntry,
};

pub const ComputePassTimestampWrite = struct {
    query_set: QuerySet,
    query_index: u32,
    location: ComputePassTimestampLocation,
};

pub const RenderPassTimestampWrite = struct {
    query_set: QuerySet,
    query_index: u32,
    location: RenderPassTimestampLocation,
};

pub const RenderPassDepthStencilAttachment = struct {
    view: TextureView,
    depth_load_op: LoadOp,
    depth_store_op: StoreOp,
    clear_depth: f32,
    depth_clear_value: f32,
    depth_read_only: bool,
    stencil_load_op: LoadOp,
    stencil_store_op: StoreOp,
    clear_stencil: u32,
    stencil_clear_value: u32,
    stencil_read_only: bool,
};

pub const RenderPassColorAttachment = struct {
    view: TextureView,
    resolve_target: ?TextureView,
    load_op: LoadOp,
    store_op: StoreOp,
    clear_value: Color,
};

pub const VertexState = struct {
    module: ShaderModule,
    entry_point: [*:0]const u8,
    constants: ?[]const ConstantEntry = null,
    buffers: ?[]const VertexBufferLayout = null,
};

pub const FragmentState = struct {
    module: ShaderModule,
    entry_point: [*:0]const u8,
    constants: ?[]const ConstantEntry = null,
    targets: ?[]const ColorTargetState = null,
};

pub const ColorTargetState = extern struct {
    reserved: ?*anyopaque = null,
    format: Texture.Format,
    blend: *const BlendState,
    write_mask: ColorWriteMask,
};

pub const ImageCopyBuffer = struct {
    layout: Texture.DataLayout,
    buffer: Buffer,
};

pub const ImageCopyTexture = struct {
    texture: Texture,
    mip_level: u32,
    origin: Origin3D,
    aspect: Texture.Aspect,
};

pub const ErrorCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (ctx: *anyopaque, typ: ErrorType, message: [*:0]const u8) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: Context,
        comptime callback: fn (ctx: Context, typ: ErrorType, message: [*:0]const u8) void,
    ) ErrorCallback {
        const erased = (struct {
            pub inline fn erased(type_erased_ctx: *anyopaque, typ: ErrorType, message: [*:0]const u8) void {
                callback(if (Context == void) {} else @ptrCast(Context, @alignCast(@alignOf(Context), type_erased_ctx)), typ, message);
            }
        }).erased;

        return .{
            .type_erased_ctx = if (Context == void) undefined else ctx,
            .type_erased_callback = erased,
        };
    }
};

pub const LoggingCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (ctx: *anyopaque, typ: LoggingType, message: [*:0]const u8) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: Context,
        comptime callback: fn (ctx: Context, typ: LoggingType, message: [*:0]const u8) void,
    ) LoggingCallback {
        const erased = (struct {
            pub inline fn erased(type_erased_ctx: *anyopaque, typ: LoggingType, message: [*:0]const u8) void {
                callback(if (Context == void) {} else @ptrCast(Context, @alignCast(@alignOf(Context), type_erased_ctx)), typ, message);
            }
        }).erased;

        return .{
            .type_erased_ctx = if (Context == void) undefined else ctx,
            .type_erased_callback = erased,
        };
    }
};

test {
    _ = MultisampleState;
    _ = PrimitiveState;
    _ = StorageTextureBindingLayout;
    _ = DepthStencilState;
    _ = ConstantEntry;
    _ = ProgrammableStageDescriptor;
    _ = ComputePassTimestampWrite;
    _ = RenderPassTimestampWrite;
    _ = RenderPassDepthStencilAttachment;
    _ = RenderPassColorAttachment;
    _ = VertexState;
    _ = FragmentState;
    _ = ImageCopyBuffer;
    _ = ImageCopyTexture;
    _ = ErrorCallback;
    _ = LoggingCallback;
}
