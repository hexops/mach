const std = @import("std");

pub const array_layer_count_undef = 0xffffffff;
pub const copy_stride_undef = 0xffffffff;
pub const limit_u32_undef = 0xffffffff;
pub const limit_u64_undef = 0xffffffffffffffff;
pub const mip_level_count_undef = 0xffffffff;
pub const whole_map_size = std.math.maxInt(usize);
pub const whole_size = 0xffffffffffffffff;

pub usingnamespace @import("adapter.zig");
pub usingnamespace @import("bind_group.zig");
pub usingnamespace @import("bind_group_layout.zig");
pub usingnamespace @import("buffer.zig");
pub usingnamespace @import("callbacks.zig");
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

const instance = @import("instance.zig");
const device = @import("device.zig");
const interface = @import("interface.zig");
const types = @import("types.zig");

pub inline fn createInstance(descriptor: ?*const instance.Instance.Descriptor) ?*instance.Instance {
    return interface.Impl.createInstance(descriptor);
}

pub inline fn getProcAddress(_device: *device.Device, proc_name: [*:0]const u8) ?types.Proc {
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
