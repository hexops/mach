const std = @import("std");

pub const Adapter = @import("adapter.zig").Adapter;
pub const BindGroup = @import("bind_group.zig").BindGroup;
pub const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
pub const Buffer = @import("buffer.zig").Buffer;
pub usingnamespace @import("callbacks.zig");
pub const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
pub const CommandEncoder = @import("command_encoder.zig").CommandEncoder;
pub const ComputePassEncoder = @import("compute_pass_encoder.zig").ComputePassEncoder;
pub const ComputePipeline = @import("compute_pipeline.zig").ComputePipeline;
pub const Device = @import("device.zig").Device;
pub const ExternalTexture = @import("external_texture.zig").ExternalTexture;
pub const Instance = @import("instance.zig").Instance;
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

const instance = @import("instance.zig");
const device = @import("device.zig");
const interface = @import("interface.zig");
const types = @import("types.zig");

pub const Impl = interface.Impl;
pub const StubInterface = interface.StubInterface;
pub const Export = interface.Export;
pub const Interface = interface.Interface;

pub inline fn createInstance(descriptor: ?*const instance.Instance.Descriptor) ?*instance.Instance {
    return Impl.createInstance(descriptor);
}

pub inline fn getProcAddress(_device: *device.Device, proc_name: [*:0]const u8) ?types.Proc {
    return Impl.getProcAddress(_device, proc_name);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
