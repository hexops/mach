pub const BasisFile = opaque {};

pub extern fn basisu_transcoder_init() void;

pub extern fn transcoder_is_format_supported(tex_type: u32, fmt: u32) bool;

pub extern fn transcoder_init([*]const u8, u32) *BasisFile;
pub extern fn transcoder_deinit(*BasisFile) void;
pub extern fn transcoder_get_images_count(*BasisFile) u32;
pub extern fn transcoder_get_levels_count(*BasisFile, image_index: u32) u32;
pub extern fn transcoder_get_image_level_desc(
    *BasisFile,
    image_index: u32,
    level_index: u32,
    orig_width: *u32,
    orig_height: *u32,
    total_block: *u32,
) bool;
pub extern fn transcoder_get_image_transcoded_size(
    *BasisFile,
    image_index: u32,
    level_index: u32,
    format: u32,
    size: *u32,
) bool;
pub extern fn transcoder_start_transcoding(*BasisFile) bool;
pub extern fn transcoder_stop_transcoding(*BasisFile) bool;
pub extern fn transcoder_transcode(
    *BasisFile,
    out: [*]const u8,
    out_size: u32,
    image_index: u32,
    level_index: u32,
    format: u32,
    decode_flags: u32,
    output_row_pitch_in_blocks_or_pixels: u32,
    output_rows_in_pixels: u32,
) bool;
