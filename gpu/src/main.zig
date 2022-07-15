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
pub const Texture = @import("Texture.zig");
pub const TextureView = @import("TextureView.zig");

pub const AlphaMode = @import("types.zig").AlphaMode;

test {
    refAllDecls(@import("adapter.zig"));
    refAllDecls(@import("bind_group.zig"));
    refAllDecls(@import("bind_group_layout.zig"));
    refAllDecls(@import("buffer.zig"));
    refAllDecls(@import("command_buffer.zig"));
    refAllDecls(@import("command_encoder.zig"));
    refAllDecls(@import("compute_pass_encoder.zig"));
    refAllDecls(@import("compute_pipeline.zig"));
    refAllDecls(@import("device.zig"));
    refAllDecls(@import("external_texture.zig"));
    refAllDecls(@import("instance.zig"));
    refAllDecls(@import("pipeline_layout.zig"));
    refAllDecls(@import("query_set.zig"));
    refAllDecls(@import("queue.zig"));
    refAllDecls(@import("render_bundle.zig"));
    refAllDecls(@import("render_bundle_encoder.zig"));
    refAllDecls(@import("render_pass_encoder.zig"));
    refAllDecls(@import("render_pipeline.zig"));
    refAllDecls(@import("sampler.zig"));
    refAllDecls(@import("shader_module.zig"));
    refAllDecls(@import("surface.zig"));
    refAllDecls(@import("swap_chain.zig"));
    refAllDecls(@import("Texture.zig"));
    refAllDecls(@import("TextureView.zig"));
    refAllDecls(@import("types.zig"));
}

fn refAllDecls(comptime T: type) void {
    @setEvalBranchQuota(10000);
    inline for (comptime @import("std").meta.declarations(T)) |decl| {
        if (decl.is_pub) {
            if (@TypeOf(@field(T, decl.name)) == type) {
                switch (@typeInfo(@field(T, decl.name))) {
                    .Struct, .Enum, .Union, .Opaque => refAllDecls(@field(T, decl.name)),
                    else => {},
                }
            }
            _ = @field(T, decl.name);
        }
    }
}
