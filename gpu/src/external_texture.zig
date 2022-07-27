const ChainedStruct = @import("types.zig").ChainedStruct;
const TextureView = @import("texture_view.zig").TextureView;
const Impl = @import("interface.zig").Impl;

pub const ExternalTexture = *opaque {
    pub inline fn destroy(external_texture: ExternalTexture) void {
        Impl.externalTextureDestroy(external_texture);
    }

    pub inline fn setLabel(external_texture: ExternalTexture, label: [*:0]const u8) void {
        Impl.externalTextureSetLabel(external_texture, label);
    }

    pub inline fn reference(external_texture: ExternalTexture) void {
        Impl.externalTextureReference(external_texture);
    }

    pub inline fn release(external_texture: ExternalTexture) void {
        Impl.externalTextureRelease(external_texture);
    }
};

pub const ExternalTextureBindingEntry = extern struct {
    chain: ChainedStruct,
    external_texture: ExternalTexture,
};

pub const ExternalTextureBindingLayout = extern struct {
    chain: ChainedStruct,
};

pub const ExternalTextureDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    plane0: TextureView,
    plane1: ?TextureView,
    do_yuv_to_rgb_conversion_only: bool,
    yuv_to_rgb_conversion_matrix: ?[*]const f32 = null,
    src_transform_function_parameters: [*]const f32,
    dst_transform_function_parameters: [*]const f32,
    gamut_conversion_matrix: [*]const f32,
};
