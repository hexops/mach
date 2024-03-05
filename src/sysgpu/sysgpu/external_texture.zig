const Bool32 = @import("main.zig").Bool32;
const ChainedStruct = @import("main.zig").ChainedStruct;
const TextureView = @import("texture_view.zig").TextureView;
const Origin2D = @import("main.zig").Origin2D;
const Extent2D = @import("main.zig").Extent2D;
const Impl = @import("interface.zig").Impl;

pub const ExternalTexture = opaque {
    pub const BindingEntry = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .external_texture_binding_entry },
        external_texture: *ExternalTexture,
    };

    pub const BindingLayout = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .external_texture_binding_layout },
    };

    const Rotation = enum(u32) {
        rotate_0_degrees = 0x00000000,
        rotate_90_degrees = 0x00000001,
        rotate_180_degrees = 0x00000002,
        rotate_270_degrees = 0x00000003,
    };

    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        plane0: *TextureView,
        plane1: ?*TextureView = null,
        visible_origin: Origin2D,
        visible_size: Extent2D,
        do_yuv_to_rgb_conversion_only: Bool32 = .false,
        yuv_to_rgb_conversion_matrix: ?*const [12]f32 = null,
        src_transform_function_parameters: *const [7]f32,
        dst_transform_function_parameters: *const [7]f32,
        gamut_conversion_matrix: *const [9]f32,
        flip_y: Bool32,
        rotation: Rotation,
    };

    pub inline fn destroy(external_texture: *ExternalTexture) void {
        Impl.externalTextureDestroy(external_texture);
    }

    pub inline fn setLabel(external_texture: *ExternalTexture, label: [*:0]const u8) void {
        Impl.externalTextureSetLabel(external_texture, label);
    }

    pub inline fn reference(external_texture: *ExternalTexture) void {
        Impl.externalTextureReference(external_texture);
    }

    pub inline fn release(external_texture: *ExternalTexture) void {
        Impl.externalTextureRelease(external_texture);
    }
};
