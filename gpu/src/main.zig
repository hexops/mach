const std = @import("std");

pub const array_layer_count_undefined = 0xffffffff;
pub const copy_stride_undefined = 0xffffffff;
pub const limit_u32_undefined = 0xffffffff;
pub const limit_u64_undefined = 0xffffffffffffffff;
pub const mip_level_count_undefined = 0xffffffff;
pub const stride_undefined = 0xffffffff;
pub const whole_map_size = std.math.maxInt(usize);
pub const whole_size = 0xffffffffffffffff;

pub const Adapter = @import("adapter.zig").Adapter;
pub const BindGroup = @import("bind_group.zig").BindGroup;
pub const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
pub const Buffer = @import("buffer.zig").Buffer;
pub const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
pub const CommandEncoder = @import("command_encoder.zig").CommandEncoder;
pub const ComputePassEncoder = @import("compute_pass_encoder.zig").ComputePassEncoder;
pub const ComputePipeline = @import("compute_pipeline.zig").ComputePipeline;
pub const Device = @import("device.zig").Device;
pub const ExternalTexture = @import("external_texture.zig").ExternalTexture;
pub usingnamespace @import("instance.zig");
pub const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;
pub const QuerySet = @import("query_set.zig").QuerySet;
pub const Queue = @import("queue.zig").Queue;
pub const RenderBundle = @import("render_bundle.zig").RenderBundle;
pub const RenderBundleEncoder = @import("render_bundle_encoder.zig").RenderBundleEncoder;
pub const RenderPassEncoder = @import("render_pass_encoder.zig").RenderPassEncoder;
pub const RenderPipeline = @import("render_pipeline.zig").RenderPipeline;
pub const Sampler = @import("sampler.zig").Sampler;
pub const ShaderModule = @import("shader_module.zig").ShaderModule;
pub const Surface = @import("surface.zig").Surface;
pub const SwapChain = @import("swap_chain.zig").SwapChain;
pub const Texture = @import("texture.zig").Texture;
pub const TextureView = @import("texture_view.zig").TextureView;

pub const dawn = @import("dawn.zig");

pub usingnamespace @import("types.zig");
pub usingnamespace @import("interface.zig");

const types = @import("types.zig");

pub const ComputePassTimestampWrite = extern struct {
    query_set: QuerySet,
    query_index: u32,
    location: types.ComputePassTimestampLocation,
};

pub const RenderPassDepthStencilAttachment = extern struct {
    view: TextureView,
    depth_load_op: types.LoadOp,
    depth_store_op: types.StoreOp,
    clear_depth: f32,
    depth_clear_value: f32,
    depth_read_only: bool,
    stencil_load_op: types.LoadOp,
    stencil_store_op: types.StoreOp,
    clear_stencil: u32,
    stencil_clear_value: u32,
    stencil_read_only: bool,
};

pub const RenderPassTimestampWrite = extern struct {
    query_set: QuerySet,
    query_index: u32,
    location: types.RenderPassTimestampLocation,
};

pub const RequestAdapterOptions = extern struct {
    next_in_chain: *const types.ChainedStruct,
    compatible_surface: Surface = Surface.none, // nullable
    power_preference: types.PowerPreference,
    force_fallback_adapter: bool,
};

pub const ComputePassDescriptor = extern struct {
    next_in_chain: *const types.ChainedStruct,
    label: ?[*:0]const u8 = null,
    timestamp_write_count: u32,
    timestamp_writes: [*]const ComputePassTimestampWrite,
};

pub const RenderPassDescriptor = extern struct {
    next_in_chain: *const types.ChainedStruct,
    label: ?[*:0]const u8 = null,
    color_attachment_count: u32,
    color_attachments: [*]const types.RenderPassColorAttachment,
    depth_stencil_attachment: ?[*]const RenderPassDepthStencilAttachment = null, // nullable
    occlusion_query_set: QuerySet = QuerySet.none, // nullable
    timestamp_write_count: u32,
    timestamp_writes: [*]const RenderPassTimestampWrite,
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
