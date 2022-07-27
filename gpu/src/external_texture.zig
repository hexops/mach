const ChainedStruct = @import("types.zig").ChainedStruct;
const TextureView = @import("texture_view.zig").TextureView;
const impl = @import("interface.zig").impl;

pub const ExternalTexture = *opaque {
    pub inline fn destroy(external_texture: ExternalTexture) void {
        impl.externalTextureDestroy(external_texture);
    }

    pub inline fn setLabel(external_texture: ExternalTexture, label: [*:0]const u8) void {
        impl.externalTextureSetLabel(external_texture, label);
    }

    pub inline fn reference(external_texture: ExternalTexture) void {
        impl.externalTextureReference(external_texture);
    }

    pub inline fn release(external_texture: ExternalTexture) void {
        impl.externalTextureRelease(external_texture);
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
    yuv_to_rgb_conversion_matrix: ?[*]const f32 = null, // nullable
    src_transform_function_parameters: [*]const f32,
    dst_transform_function_parameters: [*]const f32,
    gamut_conversion_matrix: [*]const f32,
};
