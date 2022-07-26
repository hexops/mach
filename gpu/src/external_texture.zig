const ChainedStruct = @import("types.zig").ChainedStruct;
const TextureView = @import("texture_view.zig").TextureView;

pub const ExternalTexture = *opaque {
    // TODO
    // pub inline fn externalTextureDestroy(external_texture: gpu.ExternalTexture) void {

    // TODO
    // pub inline fn externalTextureSetLabel(external_texture: gpu.ExternalTexture, label: [*:0]const u8) void {

    // TODO
    // pub inline fn externalTextureReference(external_texture: gpu.ExternalTexture) void {

    // TODO
    // pub inline fn externalTextureRelease(external_texture: gpu.ExternalTexture) void {
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
