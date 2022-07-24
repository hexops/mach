const std = @import("std");

pub const array_layer_count_undefined = 0xffffffff;
pub const copy_stride_undefined = 0xffffffff;
pub const limit_u32_undefined = 0xffffffff;
pub const limit_u64_undefined = 0xffffffffffffffff;
pub const mip_level_count_undefined = 0xffffffff;
pub const stride_undefined = 0xffffffff;
pub const whole_map_size = std.math.maxInt(usize);
pub const whole_size = 0xffffffffffffffff;

pub usingnamespace @import("adapter.zig");
pub usingnamespace @import("bind_group.zig");
pub usingnamespace @import("bind_group_layout.zig");
pub usingnamespace @import("buffer.zig");
pub usingnamespace @import("command_buffer.zig");
pub usingnamespace @import("command_encoder.zig");
pub usingnamespace @import("compute_pass_encoder.zig");
pub usingnamespace @import("compute_pipeline.zig");
pub usingnamespace @import("device.zig");
pub usingnamespace @import("external_texture.zig");
pub usingnamespace @import("instance.zig");
pub usingnamespace @import("pipeline_layout.zig");
pub usingnamespace @import("query_set.zig");
pub usingnamespace @import("queue.zig");
pub usingnamespace @import("render_bundle.zig");
pub usingnamespace @import("render_bundle_encoder.zig");
pub usingnamespace @import("render_pass_encoder.zig");
pub usingnamespace @import("render_pipeline.zig");
pub usingnamespace @import("sampler.zig");
pub usingnamespace @import("shader_module.zig");
pub usingnamespace @import("surface.zig");
pub usingnamespace @import("swap_chain.zig");
pub usingnamespace @import("texture.zig");
pub usingnamespace @import("texture_view.zig");

pub const dawn = @import("dawn.zig");

pub usingnamespace @import("types.zig");
pub usingnamespace @import("interface.zig");

const types = @import("types.zig");
const query_set = @import("query_set.zig");
const texture_view = @import("texture_view.zig");
const surface = @import("surface.zig");

pub const ComputePassTimestampWrite = extern struct {
    query_set: query_set.QuerySet,
    query_index: u32,
    location: types.ComputePassTimestampLocation,
};

pub const RenderPassDepthStencilAttachment = extern struct {
    view: texture_view.TextureView,
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
    query_set: query_set.QuerySet,
    query_index: u32,
    location: types.RenderPassTimestampLocation,
};

pub const RequestAdapterOptions = extern struct {
    next_in_chain: *const types.ChainedStruct,
    compatible_surface: surface.Surface = surface.Surface.none, // nullable
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
    occlusion_query_set: query_set.QuerySet = query_set.QuerySet.none, // nullable
    timestamp_write_count: u32,
    timestamp_writes: [*]const RenderPassTimestampWrite,
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
