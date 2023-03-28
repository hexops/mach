const std = @import("std");
const b = @import("encoder/binding.zig");
const BasisTextureFormat = @import("main.zig").BasisTextureFormat;
const testing = std.testing;

/// Must be called before encoding anything
pub fn init_encoder() void {
    b.basisu_encoder_init();
}

pub const Compressor = struct {
    pub const Error = error{
        InitializationFailed,
        ValidationFailed,
        EncodingUASTCFailed,
        CannotReadSourceImages,
        FrontendFault,
        FrontendExtractionFailed,
        BackendFault,
        CannotCreateBasisFile,
        CannotWriteOutput,
        UASTCRDOPostProcessFailed,
        CannotCreateKTX2File,
    };

    handle: *b.Compressor,

    pub fn init(params: CompressorParams) error{Unknown}!Compressor {
        return Compressor{
            .handle = if (b.compressor_init(params.handle)) |v| v else return error.Unknown,
        };
    }

    pub fn deinit(self: Compressor) void {
        b.compressor_deinit(self.handle);
    }

    pub fn process(self: Compressor) Error!void {
        return switch (b.compressor_process(self.handle)) {
            0 => {},
            1 => error.InitializationFailed,
            2 => error.CannotReadSourceImages,
            3 => error.ValidationFailed,
            4 => error.EncodingUASTCFailed,
            5 => error.FrontendFault,
            6 => error.FrontendExtractionFailed,
            7 => error.BackendFault,
            8 => error.CannotCreateBasisFile,
            9 => error.UASTCRDOPostProcessFailed,
            10 => error.CannotCreateKTX2File,
            else => unreachable,
        };
    }

    /// output will be freed with `Compressor.deinit`
    pub fn output(self: Compressor) []const u8 {
        return b.compressor_get_output(self.handle)[0..b.compressor_get_output_size(self.handle)];
    }

    pub fn outputBitsPerTexel(self: Compressor) f64 {
        return b.compressor_get_output_bits_per_texel(self.handle);
    }

    pub fn anyImageHasAlpha(self: Compressor) bool {
        return b.compressor_get_any_source_image_has_alpha(self.handle);
    }
};

pub const CompressorParams = struct {
    handle: *b.CompressorParams,

    pub fn init(threads_count: u32) CompressorParams {
        const h = CompressorParams{ .handle = b.compressor_params_init() };
        h.setStatusOutput(false);
        b.compressor_params_set_thread_count(h.handle, threads_count);
        return h;
    }

    pub fn deinit(self: CompressorParams) void {
        b.compressor_params_deinit(self.handle);
    }

    pub fn clear(self: CompressorParams) void {
        b.compressor_params_clear(self.handle);
    }

    pub fn setStatusOutput(self: CompressorParams, enable_output: bool) void {
        b.compressor_params_set_status_output(self.handle, enable_output);
    }

    /// `level` ranges from [1, 255]
    pub fn setQualityLevel(self: CompressorParams, level: u8) void {
        b.compressor_params_set_quality_level(self.handle, level);
    }

    pub fn getPackUASTCFlags(self: CompressorParams) PackUASTCFlags {
        return @bitCast(PackUASTCFlags, b.compressor_params_get_pack_uastc_flags(self.handle));
    }

    pub fn setPackUASTCFlags(self: CompressorParams, flags: PackUASTCFlags) void {
        b.compressor_params_set_pack_uastc_flags(self.handle, @bitCast(u32, flags));
    }

    pub fn setBasisFormat(self: CompressorParams, format: BasisTextureFormat) void {
        b.compressor_params_set_uastc(self.handle, switch (format) {
            .etc1s => false,
            .uastc4x4 => true,
        });
    }

    pub fn setColorSpace(self: CompressorParams, color_space: ColorSpace) void {
        b.compressor_params_set_perceptual(self.handle, switch (color_space) {
            .linear => false,
            .srgb => true,
        });
    }

    pub fn setMipColorSpace(self: CompressorParams, color_space: ColorSpace) void {
        b.compressor_params_set_mip_srgb(self.handle, switch (color_space) {
            .linear => false,
            .srgb => true,
        });
    }

    /// Disable selector RDO, for faster compression but larger files.
    /// Enabled by default
    pub fn setSelectorRDO(self: CompressorParams, enable: bool) void {
        b.compressor_params_set_no_selector_rdo(self.handle, !enable);
    }

    /// Enabled by default
    pub fn setEndpointRDO(self: CompressorParams, enable: bool) void {
        b.compressor_params_set_no_endpoint_rdo(self.handle, !enable);
    }

    pub fn setRDO_UASTC(self: CompressorParams, enable: bool) void {
        b.compressor_params_set_rdo_uastc(self.handle, enable);
    }

    pub fn setRDO_UASTCQualityScalar(self: CompressorParams, quality: f32) void {
        b.compressor_params_set_rdo_uastc_quality_scalar(self.handle, quality);
    }

    pub fn setGenerateMipMaps(self: CompressorParams, enable: bool) void {
        b.compressor_params_set_generate_mipmaps(self.handle, enable);
    }

    pub fn setMipSmallestDimension(self: CompressorParams, smallest_dimension: i32) void {
        b.compressor_params_set_mip_smallest_dimension(self.handle, smallest_dimension);
    }

    /// Resizes sources list and creates a new Image in case index is out of bounds
    pub fn getImageSource(self: CompressorParams, index: u32) Image {
        return .{ .handle = b.compressor_params_get_or_create_source_image(self.handle, index) };
    }

    pub fn resizeImageSource(self: CompressorParams, new_size: u32) void {
        b.compressor_params_resize_source_image_list(self.handle, new_size);
    }

    pub fn clearImageSource(self: CompressorParams) void {
        b.compressor_params_clear_source_image_list(self.handle);
    }
};

pub const Image = struct {
    handle: *b.Image,

    pub fn fill(self: Image, data: []const u8, w: u32, h: u32, channels: u3) void {
        b.compressor_image_fill(self.handle, data.ptr, w, h, channels);
    }

    pub fn resize(self: Image, w: u32, h: u32, p: ?u32) void {
        b.compressor_image_resize(self.handle, w, h, p orelse std.math.maxInt(u32));
    }

    pub fn width(self: Image) u32 {
        return b.compressor_image_get_width(self.handle);
    }

    pub fn height(self: Image) u32 {
        return b.compressor_image_get_height(self.handle);
    }

    pub fn pitch(self: Image) u32 {
        return b.compressor_image_get_pitch(self.handle);
    }

    pub fn totalPixels(self: Image) u32 {
        return b.compressor_image_get_total_pixels(self.handle);
    }

    pub fn blockWidth(self: Image, w: u32) u32 {
        return (self.width() + (w - 1)) / w;
    }

    pub fn blockHeight(self: Image, h: u32) u32 {
        return (self.height() + (h - 1)) / h;
    }

    pub fn totalBlocks(self: Image, w: u32, h: u32) u32 {
        return self.blockWidth(w) * self.blockHeight(h);
    }
};

pub const PackUASTCFlags = packed struct(u32) {
    fastest: bool = false,
    faster: bool = false,
    default: bool = false,
    slower: bool = false,
    verySlow: bool = false,
    favor_uastc_error: bool = false,
    favor_bc7_error: bool = false,
    _padding: u1 = 0,
    etc1_faster_hints: bool = false,
    etc1_fastest_hints: bool = false,
    etc1_disable_flip_and_individual: bool = false,
    favor_simpler_modes: bool = false,
    _padding0: u20 = 0,
};

pub const ColorSpace = enum {
    linear,
    srgb,
};
