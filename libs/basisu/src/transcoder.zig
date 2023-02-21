const std = @import("std");
const b = @import("transcoder/binding.zig");
const BasisTextureFormat = @import("main.zig").BasisTextureFormat;
const testing = std.testing;

/// Must be called before a `.basis` file can be transcoded.
/// NOTE: this function *isn't* thread safe.
pub fn init_transcoder() void {
    b.basisu_transcoder_init();
}

/// Returns true if the specified format was enabled at compile time.
pub fn isFormatEnabled(self: BasisTextureFormat, transcoder_format: Transcoder.TextureFormat) bool {
    return b.transcoder_is_format_supported(@enumToInt(self), @enumToInt(transcoder_format));
}

pub const Transcoder = struct {
    handle: *b.BasisFile,

    pub fn init(src: []const u8) error{Unknown}!Transcoder {
        const h = b.transcoder_init(src.ptr, @intCast(u32, src.len));
        return if (!b.transcoder_start_transcoding(h))
            error.Unknown
        else
            .{ .handle = h };
    }

    pub fn deinit(self: Transcoder) void {
        if (!b.transcoder_stop_transcoding(self.handle))
            unreachable;
        b.transcoder_deinit(self.handle);
    }

    /// Returns the total number of images in the basis file (always 1 or more).
    /// Note that the number of mipmap levels for each image may differ, and that images may have different resolutions.
    pub fn getImageCount(self: Transcoder) u32 {
        return b.transcoder_get_images_count(self.handle);
    }

    /// Returns the number of mipmap levels in an image.
    pub fn getImageLevelCount(self: Transcoder, image_index: u32) u32 {
        return b.transcoder_get_levels_count(self.handle, image_index);
    }

    /// Returns basic information about an image.
    /// Note that orig_width/orig_height may not be a multiple of 4.
    pub fn getImageLevelDescriptor(self: Transcoder, image_index: u32, level_index: u32) error{OutOfBoundsLevelIndex}!ImageLevelDescriptor {
        var desc: ImageLevelDescriptor = undefined;
        return if (b.transcoder_get_image_level_desc(
            self.handle,
            image_index,
            level_index,
            &desc.original_width,
            &desc.original_height,
            &desc.block_count,
        ))
            desc
        else
            error.OutOfBoundsLevelIndex;
    }

    /// Returns the bytes neeeded to store output.
    pub fn calcTranscodedSize(self: Transcoder, image_index: u32, level_index: u32, format: TextureFormat) error{OutOfBoundsLevelIndex}!u32 {
        var size: u32 = undefined;
        return if (b.transcoder_get_image_transcoded_size(self.handle, image_index, level_index, @enumToInt(format), &size))
            size
        else
            error.OutOfBoundsLevelIndex;
    }

    pub const TranscodeParams = struct {
        decode_flags: DecodeFlags = .{},
        /// Output row pitch in blocks or pixels.
        /// Should be at least the image level's total_blocks (num_blocks_x * num_blocks_y),
        /// or the total number of output pixels if fmt==cTFRGBA32.
        output_row_pitch: ?u32 = null,
        /// Output rows in pixels
        /// Ignored unless fmt is uncompressed (cRGBA32, etc.).
        /// The total number of output rows in the output buffer. If 0,
        /// the transcoder assumes the slice's orig_height (NOT num_blocks_y * 4).
        output_rows: ?u32 = null,
    };

    /// Decodes a single mipmap level from the .basis file to any of the supported output texture formats.
    /// Currently, to decode to PVRTC1 the basis texture's dimensions in pixels must be a power of 2,
    /// due to PVRTC1 format requirements.
    /// NOTE:
    /// - `transcoder_init()` must have been called first to initialize
    ///   the transcoder lookup tables before calling this function.
    /// - This method assumes the output texture buffer is readable.
    ///   In some cases to handle alpha, the transcoder will write temporary data
    ///   to the output texture in a first pass, which will be read in a second pass.
    pub fn transcode(
        self: Transcoder,
        out_buf: []u8,
        image_index: u32,
        level_index: u32,
        format: TextureFormat,
        params: TranscodeParams,
    ) error{Unknown}!void {
        if (!b.transcoder_transcode(
            self.handle,
            out_buf.ptr,
            @intCast(u32, out_buf.len),
            image_index,
            level_index,
            @enumToInt(format),
            @bitCast(u32, params.decode_flags),
            params.output_row_pitch orelse 0,
            params.output_rows orelse 0,
        )) return error.Unknown;
    }

    pub const ImageLevelDescriptor = struct {
        original_width: u32,
        original_height: u32,
        block_count: u32,
    };

    pub const DecodeFlags = packed struct {
        _padding: u1 = 0,
        pvrtc_decode_to_next_pow_2: bool = false,
        transcode_alpha_data_to_opaque_formats: bool = false,
        bc1_forbid_three_color_blocks: bool = false,
        output_has_alpha_indices: bool = false,
        high_quality: bool = false,
        _padding0: u26 = 0,
    };

    pub const TextureFormat = enum(u5) {
        etc1_rgb = 0,
        etc2_rgba = 1,
        bc1_rgb = 2,
        bc3_rgba = 3,
        bc4_r = 4,
        bc5_rg = 5,
        bc7_rgba = 6,
        bc7_alt = 7,
        pvrtc1_4_rgb = 8,
        pvrtc1_4_rgba = 9,
        astc_4x4_rgba = 10,
        atc_rgb = 11,
        atc_rgba = 12,
        rgba32 = 13,
        rgb565 = 14,
        bgr565 = 15,
        rgba4444 = 16,
        fxt1_rgb = 17,
        pvrtc2_4_rgb = 18,
        pvrtc2_4_rgba = 19,
        etc2_eac_r11 = 20,
        etc2_eac_rg11 = 21,

        pub fn isEnabled(
            self: TextureFormat,
            basis_texture_format: BasisTextureFormat,
        ) bool {
            return isFormatEnabled(basis_texture_format, self);
        }

        pub fn bytesPerBlockOrPixel(self: TextureFormat) u5 {
            return switch (self) {
                .rgb565, .bgr565, .rgba4444 => return 2,
                .rgba32 => return 4,
                .etc1_rgb, .bc1_rgb, .bc4_r, .pvrtc1_4_rgb, .pvrtc1_4_rgba, .atc_rgb, .pvrtc2_4_rgb, .pvrtc2_4_rgba, .etc2_eac_r11 => 8,
                .bc7_rgba, .bc7_alt, .etc2_rgba, .bc3_rgba, .bc5_rg, .astc_4x4_rgba, .atc_rgba, .fxt1_rgb, .etc2_eac_rg11 => return 16,
            };
        }
    };

    pub const BlockFormat = enum(u5) {
        etc1 = 0,
        etc2_rgba = 1,
        bc1 = 2,
        bc3 = 3,
        bc4 = 4,
        bc5 = 5,
        pvrtc1_4_rgb = 6,
        pvrtc1_4_rgba = 7,
        bc7 = 8,
        bc7_m5_color = 9,
        bc7_m5_alpha = 10,
        etc2_eac_a8 = 11,
        astc_4x4 = 12,
        atc_rgb = 13,
        atc_rgba_interpolated_alpha = 14,
        fxt1_rgb = 15,
        pvrtc2_4_rgb = 16,
        pvrtc2_4_rgba = 17,
        etc2_eac_r11 = 18,
        etc2_eac_rg11 = 19,
        indices = 20,
        rgb32 = 21,
        rgba32 = 23,
        a32 = 24,
        rgb565 = 25,
        bgr565 = 26,
        rgba4444_color = 27,
        rgba4444_alpha = 28,
        rgba4444_color_opaque = 29,
        rgba4444 = 30,
        uastc_4x4 = 31,
    };
};
