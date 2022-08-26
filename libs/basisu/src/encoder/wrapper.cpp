#include <basisu_comp.h>
#include <basisu_enc.h>
#include <cstdbool>
#include <cstdint>

extern "C" {
void basisu_encoder_init() { basisu::basisu_encoder_init(); }

basisu::basis_compressor_params *compressor_params_init() {
  return new basisu::basis_compressor_params();
};

void compressor_params_deinit(basisu::basis_compressor_params *params) {
  delete params;
}

void compressor_params_clear(basisu::basis_compressor_params *params) {
  params->clear();
}

void compressor_params_set_status_output(
    basisu::basis_compressor_params *params, bool status_output) {
  params->m_status_output = status_output;
}

void compressor_params_set_thread_count(basisu::basis_compressor_params *params,
                                        uint32_t thread_count) {
  params->m_pJob_pool = new basisu::job_pool(thread_count);
}

void compressor_params_set_quality_level(
    basisu::basis_compressor_params *params, uint8_t quality_level) {
  params->m_quality_level = quality_level;
}

uint32_t compressor_params_get_pack_uastc_flags(
    basisu::basis_compressor_params *params) {
  return params->m_pack_uastc_flags;
}

void compressor_params_set_pack_uastc_flags(
    basisu::basis_compressor_params *params, uint32_t pack_uastc_flags) {
  params->m_pack_uastc_flags = pack_uastc_flags;
}

void compressor_params_set_uastc(basisu::basis_compressor_params *params,
                                 bool is_uastc) {
  params->m_uastc = is_uastc;
}

void compressor_params_set_perceptual(basisu::basis_compressor_params *params,
                                      bool perceptual) {
  params->m_perceptual = perceptual;
}

void compressor_params_set_mip_srgb(basisu::basis_compressor_params *params,
                                    bool mip_srgb) {
  params->m_mip_srgb = mip_srgb;
}

void compressor_params_set_no_selector_rdo(
    basisu::basis_compressor_params *params, bool no_selector_rdo) {
  params->m_no_selector_rdo = no_selector_rdo;
}

void compressor_params_set_no_endpoint_rdo(
    basisu::basis_compressor_params *params, bool no_endpoint_rdo) {
  params->m_no_endpoint_rdo = no_endpoint_rdo;
}

void compressor_params_set_rdo_uastc(basisu::basis_compressor_params *params,
                                     bool rdo_uastc) {
  params->m_rdo_uastc = rdo_uastc;
}

void compressor_params_set_generate_mipmaps(
    basisu::basis_compressor_params *params, bool generate_mipmaps) {
  params->m_mip_gen = generate_mipmaps;
}

void compressor_params_set_rdo_uastc_quality_scalar(
    basisu::basis_compressor_params *params, float rdo_uastc_quality_scalar) {
  params->m_rdo_uastc_quality_scalar = rdo_uastc_quality_scalar;
}

void compressor_params_set_mip_smallest_dimension(
    basisu::basis_compressor_params *params, int mip_smallest_dimension) {
  params->m_mip_smallest_dimension = mip_smallest_dimension;
}

basisu::image *compressor_params_get_or_create_source_image(
    basisu::basis_compressor_params *params, uint32_t index) {
  if (params->m_source_images.size() < index + 1) {
    params->m_source_images.resize(index + 1);
  }

  return &params->m_source_images[index];
}

void compressor_params_resize_source_image_list(
    basisu::basis_compressor_params *params, size_t size) {
  params->m_source_images.resize(size);
}

void compressor_params_clear_source_image_list(
    basisu::basis_compressor_params *params) {
  params->clear();
}

///

void compressor_image_fill(basisu::image *image, const uint8_t *pData,
                           uint32_t width, uint32_t height, uint32_t comps) {
  image->init(pData, width, height, comps);
}

void compressor_image_resize(basisu::image *image, uint32_t w, uint32_t h,
                             uint32_t p) {
  image->resize(w, h, p);
}

uint32_t compressor_image_get_width(basisu::image *image) {
  return image->get_width();
}

uint32_t compressor_image_get_height(basisu::image *image) {
  return image->get_height();
}

uint32_t compressor_image_get_pitch(basisu::image *image) {
  return image->get_pitch();
}

uint32_t compressor_image_get_total_pixels(basisu::image *image) {
  return image->get_total_pixels();
}

///

basisu::basis_compressor *
compressor_init(basisu::basis_compressor_params *params) {
  auto comp = new basisu::basis_compressor();
  if (comp->init(*params))
    return comp;
  else
    return nullptr;
}

void compressor_deinit(basisu::basis_compressor *compressor) {
  delete compressor;
}

basisu::basis_compressor::error_code
compressor_process(basisu::basis_compressor *compressor) {
  return compressor->process();
}

const uint8_t *compressor_get_output(basisu::basis_compressor *compressor) {
  return compressor->get_output_basis_file().data();
}

uint32_t
compressor_get_output_size(const basisu::basis_compressor *compressor) {
  return compressor->get_basis_file_size();
}

double compressor_get_output_bits_per_texel(
    const basisu::basis_compressor *compressor) {
  return compressor->get_basis_bits_per_texel();
}

bool compressor_get_any_source_image_has_alpha(
    const basisu::basis_compressor *compressor) {
  return compressor->get_any_source_image_has_alpha();
}
}