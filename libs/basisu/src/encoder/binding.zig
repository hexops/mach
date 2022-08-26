pub const Compressor = opaque {};
pub const CompressorParams = opaque {};
pub const Image = opaque {};

pub extern fn basisu_encoder_init() void;

pub extern fn compressor_params_init() *CompressorParams;
pub extern fn compressor_params_deinit(*CompressorParams) void;
pub extern fn compressor_params_clear(*CompressorParams) void;
pub extern fn compressor_params_set_status_output(*CompressorParams, bool) void;
pub extern fn compressor_params_set_thread_count(*CompressorParams, u32) void;
pub extern fn compressor_params_set_quality_level(*CompressorParams, c_int) void;
pub extern fn compressor_params_get_pack_uastc_flags(*CompressorParams) u32;
pub extern fn compressor_params_set_pack_uastc_flags(*CompressorParams, u32) void;
pub extern fn compressor_params_set_uastc(*CompressorParams, bool) void;
pub extern fn compressor_params_set_perceptual(*CompressorParams, bool) void;
pub extern fn compressor_params_set_mip_srgb(*CompressorParams, bool) void;
pub extern fn compressor_params_set_no_selector_rdo(*CompressorParams, bool) void;
pub extern fn compressor_params_set_no_endpoint_rdo(*CompressorParams, bool) void;
pub extern fn compressor_params_set_rdo_uastc(*CompressorParams, bool) void;
pub extern fn compressor_params_set_rdo_uastc_quality_scalar(*CompressorParams, f32) void;
pub extern fn compressor_params_set_generate_mipmaps(*CompressorParams, bool) void;
pub extern fn compressor_params_set_mip_smallest_dimension(*CompressorParams, c_int) void;
pub extern fn compressor_params_get_or_create_source_image(*CompressorParams, u32) *Image;
pub extern fn compressor_params_resize_source_image_list(*CompressorParams, usize) void;
pub extern fn compressor_params_clear_source_image_list(*CompressorParams) void;

pub extern fn compressor_image_fill(*Image, [*]const u8, u32, u32, u32) void;
pub extern fn compressor_image_resize(*Image, u32, u32, u32) void;
pub extern fn compressor_image_get_width(*Image) u32;
pub extern fn compressor_image_get_height(*Image) u32;
pub extern fn compressor_image_get_pitch(*Image) u32;
pub extern fn compressor_image_get_total_pixels(*Image) u32;

pub extern fn compressor_init(*CompressorParams) ?*Compressor;
pub extern fn compressor_deinit(*Compressor) void;
pub extern fn compressor_process(*Compressor) u32;

pub extern fn compressor_get_output(*Compressor) [*]const u8;
pub extern fn compressor_get_output_size(*Compressor) u32;
pub extern fn compressor_get_output_bits_per_texel(*Compressor) f64;
pub extern fn compressor_get_any_source_image_has_alpha(*Compressor) bool;
