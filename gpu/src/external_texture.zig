pub const ChainedStruct = @import("types.zig").ChainedStruct;
pub const TextureView = @import("texture_view.zig").TextureView;

pub const ExternalTexture = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: ExternalTexture = @intToEnum(ExternalTexture, 0);

    pub const BindingEntry = extern struct {
        chain: ChainedStruct,
        external_texture: ExternalTexture,
    };

    pub const BindingLayout = extern struct {
        chain: ChainedStruct,
    };

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
        plane0: TextureView,
        plane1: TextureView = TextureView.none, // nullable
        do_yuv_to_rgb_conversion_only: bool,
        yuv_to_rgb_conversion_matrix: ?[*]const f32 = null, // nullable
        src_transform_function_parameters: [*]const f32,
        dst_transform_function_parameters: [*]const f32,
        gamut_conversion_matrix: [*]const f32,
    };
};
