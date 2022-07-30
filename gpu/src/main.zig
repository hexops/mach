const std = @import("std");

pub const array_layer_count_undefined = 0xffffffff;
pub const copy_stride_undefined = 0xffffffff;
pub const limit_u32_undefined = 0xffffffff;
pub const limit_u64_undefined = 0xffffffffffffffff;
pub const mip_level_count_undefined = 0xffffffff;
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
const compute_pipeline = @import("compute_pipeline.zig");
const render_pipeline = @import("render_pipeline.zig");
const instance = @import("instance.zig");
const device = @import("device.zig");
const interface = @import("interface.zig");

/// Generic function pointer type, used for returning API function pointers. Must be
/// cast to a `fn (...) callconv(.C) T` before use.
pub const Proc = *anyopaque;

pub const CreateComputePipelineAsyncCallback = fn (
    status: types.CreatePipelineAsyncStatus,
    compute_pipeline: compute_pipeline.ComputePipeline,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const CreateRenderPipelineAsyncCallback = fn (
    status: types.CreatePipelineAsyncStatus,
    pipeline: render_pipeline.RenderPipeline,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const ComputePassTimestampWrite = extern struct {
    query_set: query_set.QuerySet,
    query_index: u32,
    location: types.ComputePassTimestampLocation,
};

pub const RenderPassDepthStencilAttachment = extern struct {
    view: texture_view.TextureView,
    depth_load_op: types.LoadOp = .undef,
    depth_store_op: types.StoreOp = .undef,
    /// deprecated
    clear_depth: f32 = std.math.nan(f32),
    depth_clear_value: f32 = 0,
    depth_read_only: bool = false,
    stencil_load_op: types.LoadOp = .undef,
    stencil_store_op: types.StoreOp = .undef,
    /// deprecated
    clear_stencil: u32 = 0,
    stencil_clear_value: u32 = 0,
    stencil_read_only: bool = false,
};

pub const RenderPassTimestampWrite = extern struct {
    query_set: query_set.QuerySet,
    query_index: u32,
    location: types.RenderPassTimestampLocation,
};

pub const RequestAdapterOptions = extern struct {
    next_in_chain: *const types.ChainedStruct,
    compatible_surface: ?surface.Surface,
    power_preference: types.PowerPreference = .undef,
    force_fallback_adapter: bool = false,
};

pub const ComputePassDescriptor = extern struct {
    next_in_chain: *const types.ChainedStruct,
    label: ?[*:0]const u8 = null,
    timestamp_write_count: u32 = 0,
    // TODO: file a bug on Dawn, this is not marked as nullable but in fact is.
    timestamp_writes: ?[*]const ComputePassTimestampWrite = null,
};

pub const RenderPassDescriptor = extern struct {
    next_in_chain: *const types.ChainedStruct,
    label: ?[*:0]const u8 = null,
    color_attachment_count: u32,
    // TODO: file a bug on Dawn, this is not marked as nullable but in fact is.
    color_attachments: ?[*]const types.RenderPassColorAttachment,
    depth_stencil_attachment: ?[*]const RenderPassDepthStencilAttachment,
    occlusion_query_set: ?query_set.QuerySet,
    timestamp_write_count: u32 = 0,
    // TODO: file a bug on Dawn, this is not marked as nullable but in fact is.
    timestamp_writes: ?[*]const RenderPassTimestampWrite = null,
};

pub inline fn createInstance(descriptor: ?*const instance.InstanceDescriptor) ?*instance.Instance {
    return interface.Impl.createInstance(descriptor);
}

pub inline fn getProcAddress(_device: device.Device, proc_name: [*:0]const u8) ?Proc {
    return interface.Impl.getProcAddress(_device, proc_name);
}

test {
    std.testing.refAllDeclsRecursive(@This());

    // Due to usingnamespace imports, these are not referenceable via @This()
    std.testing.refAllDeclsRecursive(@import("adapter.zig"));
    std.testing.refAllDeclsRecursive(@import("bind_group.zig"));
    std.testing.refAllDeclsRecursive(@import("bind_group_layout.zig"));
    std.testing.refAllDeclsRecursive(@import("buffer.zig"));
    std.testing.refAllDeclsRecursive(@import("command_buffer.zig"));
    std.testing.refAllDeclsRecursive(@import("command_encoder.zig"));
    std.testing.refAllDeclsRecursive(@import("compute_pass_encoder.zig"));
    std.testing.refAllDeclsRecursive(@import("compute_pipeline.zig"));
    std.testing.refAllDeclsRecursive(@import("device.zig"));
    std.testing.refAllDeclsRecursive(@import("external_texture.zig"));
    std.testing.refAllDeclsRecursive(@import("instance.zig"));
    std.testing.refAllDeclsRecursive(@import("pipeline_layout.zig"));
    std.testing.refAllDeclsRecursive(@import("query_set.zig"));
    std.testing.refAllDeclsRecursive(@import("queue.zig"));
    std.testing.refAllDeclsRecursive(@import("render_bundle.zig"));
    std.testing.refAllDeclsRecursive(@import("render_bundle_encoder.zig"));
    std.testing.refAllDeclsRecursive(@import("render_pass_encoder.zig"));
    std.testing.refAllDeclsRecursive(@import("render_pipeline.zig"));
    std.testing.refAllDeclsRecursive(@import("sampler.zig"));
    std.testing.refAllDeclsRecursive(@import("shader_module.zig"));
    std.testing.refAllDeclsRecursive(@import("surface.zig"));
    std.testing.refAllDeclsRecursive(@import("swap_chain.zig"));
    std.testing.refAllDeclsRecursive(@import("texture.zig"));
    std.testing.refAllDeclsRecursive(@import("texture_view.zig"));
    std.testing.refAllDeclsRecursive(@import("types.zig"));
    std.testing.refAllDeclsRecursive(@import("interface.zig"));
}
