const mtl = @import("objc").metal.mtl;
const sysgpu = @import("../sysgpu/main.zig");

pub fn metalBlendFactor(factor: sysgpu.BlendFactor, color: bool) mtl.BlendFactor {
    return switch (factor) {
        .zero => mtl.BlendFactorZero,
        .one => mtl.BlendFactorOne,
        .src => mtl.BlendFactorSourceColor,
        .one_minus_src => mtl.BlendFactorOneMinusSourceColor,
        .src_alpha => mtl.BlendFactorSourceAlpha,
        .one_minus_src_alpha => mtl.BlendFactorOneMinusSourceAlpha,
        .dst => mtl.BlendFactorDestinationColor,
        .one_minus_dst => mtl.BlendFactorOneMinusDestinationColor,
        .dst_alpha => mtl.BlendFactorDestinationAlpha,
        .one_minus_dst_alpha => mtl.BlendFactorOneMinusDestinationAlpha,
        .src_alpha_saturated => mtl.BlendFactorSourceAlphaSaturated,
        .constant => if (color) mtl.BlendFactorBlendColor else mtl.BlendFactorBlendAlpha,
        .one_minus_constant => if (color) mtl.BlendFactorOneMinusBlendColor else mtl.BlendFactorOneMinusBlendAlpha,
        .src1 => mtl.BlendFactorSource1Color,
        .one_minus_src1 => mtl.BlendFactorOneMinusSource1Color,
        .src1_alpha => mtl.BlendFactorSource1Alpha,
        .one_minus_src1_alpha => mtl.BlendFactorOneMinusSource1Alpha,
    };
}

pub fn metalBlendOperation(op: sysgpu.BlendOperation) mtl.BlendOperation {
    return switch (op) {
        .add => mtl.BlendOperationAdd,
        .subtract => mtl.BlendOperationSubtract,
        .reverse_subtract => mtl.BlendOperationReverseSubtract,
        .min => mtl.BlendOperationMin,
        .max => mtl.BlendOperationMax,
    };
}

pub fn metalColorWriteMask(mask: sysgpu.ColorWriteMaskFlags) mtl.ColorWriteMask {
    var writeMask = mtl.ColorWriteMaskNone;
    if (mask.red)
        writeMask |= mtl.ColorWriteMaskRed;
    if (mask.green)
        writeMask |= mtl.ColorWriteMaskGreen;
    if (mask.blue)
        writeMask |= mtl.ColorWriteMaskBlue;
    if (mask.alpha)
        writeMask |= mtl.ColorWriteMaskAlpha;
    return writeMask;
}

pub fn metalCommonCounter(name: sysgpu.PipelineStatisticName) mtl.CommonCounter {
    return switch (name) {
        .vertex_shader_invocations => mtl.CommonCounterVertexInvocations,
        .cliiper_invocations => mtl.CommonCounterClipperInvocations,
        .clipper_primitives_out => mtl.CommonCounterClipperPrimitivesOut,
        .fragment_shader_invocations => mtl.CommonCounterFragmentInvocations,
        .compute_shader_invocations => mtl.CommonCounterComputeKernelInvocations,
    };
}

pub fn metalCompareFunction(func: sysgpu.CompareFunction) mtl.CompareFunction {
    return switch (func) {
        .undefined => unreachable,
        .never => mtl.CompareFunctionNever,
        .less => mtl.CompareFunctionLess,
        .less_equal => mtl.CompareFunctionLessEqual,
        .greater => mtl.CompareFunctionGreater,
        .greater_equal => mtl.CompareFunctionGreaterEqual,
        .equal => mtl.CompareFunctionEqual,
        .not_equal => mtl.CompareFunctionNotEqual,
        .always => mtl.CompareFunctionAlways,
    };
}

pub fn metalCullMode(mode: sysgpu.CullMode) mtl.CullMode {
    return switch (mode) {
        .none => mtl.CullModeNone,
        .front => mtl.CullModeFront,
        .back => mtl.CullModeBack,
    };
}

pub fn metalIndexType(format: sysgpu.IndexFormat) mtl.IndexType {
    return switch (format) {
        .undefined => unreachable,
        .uint16 => mtl.IndexTypeUInt16,
        .uint32 => mtl.IndexTypeUInt32,
    };
}

pub fn metalIndexElementSize(format: sysgpu.IndexFormat) usize {
    return switch (format) {
        .undefined => unreachable,
        .uint16 => 2,
        .uint32 => 4,
    };
}

pub fn metalLoadAction(op: sysgpu.LoadOp) mtl.LoadAction {
    return switch (op) {
        .undefined => unreachable,
        .load => mtl.LoadActionLoad,
        .clear => mtl.LoadActionClear,
    };
}

pub fn metalPixelFormat(format: sysgpu.Texture.Format) mtl.PixelFormat {
    return switch (format) {
        .undefined => mtl.PixelFormatInvalid,
        .r8_unorm => mtl.PixelFormatR8Unorm,
        .r8_snorm => mtl.PixelFormatR8Snorm,
        .r8_uint => mtl.PixelFormatR8Uint,
        .r8_sint => mtl.PixelFormatR8Sint,
        .r16_uint => mtl.PixelFormatR16Uint,
        .r16_sint => mtl.PixelFormatR16Sint,
        .r16_float => mtl.PixelFormatR16Float,
        .rg8_unorm => mtl.PixelFormatRG8Unorm,
        .rg8_snorm => mtl.PixelFormatRG8Snorm,
        .rg8_uint => mtl.PixelFormatRG8Uint,
        .rg8_sint => mtl.PixelFormatRG8Sint,
        .r32_float => mtl.PixelFormatR32Float,
        .r32_uint => mtl.PixelFormatR32Uint,
        .r32_sint => mtl.PixelFormatR32Sint,
        .rg16_uint => mtl.PixelFormatRG16Uint,
        .rg16_sint => mtl.PixelFormatRG16Sint,
        .rg16_float => mtl.PixelFormatRG16Float,
        .rgba8_unorm => mtl.PixelFormatRGBA8Unorm,
        .rgba8_unorm_srgb => mtl.PixelFormatRGBA8Unorm_sRGB,
        .rgba8_snorm => mtl.PixelFormatRGBA8Snorm,
        .rgba8_uint => mtl.PixelFormatRGBA8Uint,
        .rgba8_sint => mtl.PixelFormatRGBA8Sint,
        .bgra8_unorm => mtl.PixelFormatBGRA8Unorm,
        .bgra8_unorm_srgb => mtl.PixelFormatBGRA8Unorm_sRGB,
        .rgb10_a2_unorm => mtl.PixelFormatRGB10A2Unorm,
        .rg11_b10_ufloat => mtl.PixelFormatRG11B10Float,
        .rgb9_e5_ufloat => mtl.PixelFormatRGB9E5Float,
        .rg32_float => mtl.PixelFormatRG32Float,
        .rg32_uint => mtl.PixelFormatRG32Uint,
        .rg32_sint => mtl.PixelFormatRG32Sint,
        .rgba16_uint => mtl.PixelFormatRGBA16Uint,
        .rgba16_sint => mtl.PixelFormatRGBA16Sint,
        .rgba16_float => mtl.PixelFormatRGBA16Float,
        .rgba32_float => mtl.PixelFormatRGBA32Float,
        .rgba32_uint => mtl.PixelFormatRGBA32Uint,
        .rgba32_sint => mtl.PixelFormatRGBA32Sint,
        .stencil8 => mtl.PixelFormatStencil8,
        .depth16_unorm => mtl.PixelFormatDepth16Unorm,
        .depth24_plus => mtl.PixelFormatDepth32Float, // mtl.PixelFormatDepth24Unorm_Stencil8 only for non-Apple Silicon
        .depth24_plus_stencil8 => mtl.PixelFormatDepth32Float_Stencil8, // mtl.PixelFormatDepth24Unorm_Stencil8 only for non-Apple Silicon
        .depth32_float => mtl.PixelFormatDepth32Float,
        .depth32_float_stencil8 => mtl.PixelFormatDepth32Float_Stencil8,
        .bc1_rgba_unorm => mtl.PixelFormatBC1_RGBA,
        .bc1_rgba_unorm_srgb => mtl.PixelFormatBC1_RGBA_sRGB,
        .bc2_rgba_unorm => mtl.PixelFormatBC2_RGBA,
        .bc2_rgba_unorm_srgb => mtl.PixelFormatBC2_RGBA_sRGB,
        .bc3_rgba_unorm => mtl.PixelFormatBC3_RGBA,
        .bc3_rgba_unorm_srgb => mtl.PixelFormatBC3_RGBA_sRGB,
        .bc4_runorm => mtl.PixelFormatBC4_RUnorm,
        .bc4_rsnorm => mtl.PixelFormatBC4_RSnorm,
        .bc5_rg_unorm => mtl.PixelFormatBC5_RGUnorm,
        .bc5_rg_snorm => mtl.PixelFormatBC5_RGSnorm,
        .bc6_hrgb_ufloat => mtl.PixelFormatBC6H_RGBUfloat,
        .bc6_hrgb_float => mtl.PixelFormatBC6H_RGBFloat,
        .bc7_rgba_unorm => mtl.PixelFormatBC7_RGBAUnorm,
        .bc7_rgba_unorm_srgb => mtl.PixelFormatBC7_RGBAUnorm_sRGB,
        .etc2_rgb8_unorm => mtl.PixelFormatETC2_RGB8,
        .etc2_rgb8_unorm_srgb => mtl.PixelFormatETC2_RGB8_sRGB,
        .etc2_rgb8_a1_unorm => mtl.PixelFormatETC2_RGB8A1,
        .etc2_rgb8_a1_unorm_srgb => mtl.PixelFormatETC2_RGB8A1_sRGB,
        .etc2_rgba8_unorm => mtl.PixelFormatEAC_RGBA8,
        .etc2_rgba8_unorm_srgb => mtl.PixelFormatEAC_RGBA8_sRGB,
        .eacr11_unorm => mtl.PixelFormatEAC_R11Unorm,
        .eacr11_snorm => mtl.PixelFormatEAC_R11Snorm,
        .eacrg11_unorm => mtl.PixelFormatEAC_RG11Unorm,
        .eacrg11_snorm => mtl.PixelFormatEAC_RG11Snorm,
        .astc4x4_unorm => mtl.PixelFormatASTC_4x4_LDR,
        .astc4x4_unorm_srgb => mtl.PixelFormatASTC_4x4_sRGB,
        .astc5x4_unorm => mtl.PixelFormatASTC_5x4_LDR,
        .astc5x4_unorm_srgb => mtl.PixelFormatASTC_5x4_sRGB,
        .astc5x5_unorm => mtl.PixelFormatASTC_5x5_LDR,
        .astc5x5_unorm_srgb => mtl.PixelFormatASTC_5x5_sRGB,
        .astc6x5_unorm => mtl.PixelFormatASTC_6x5_LDR,
        .astc6x5_unorm_srgb => mtl.PixelFormatASTC_6x5_sRGB,
        .astc6x6_unorm => mtl.PixelFormatASTC_6x6_LDR,
        .astc6x6_unorm_srgb => mtl.PixelFormatASTC_6x6_sRGB,
        .astc8x5_unorm => mtl.PixelFormatASTC_8x5_LDR,
        .astc8x5_unorm_srgb => mtl.PixelFormatASTC_8x5_sRGB,
        .astc8x6_unorm => mtl.PixelFormatASTC_8x6_LDR,
        .astc8x6_unorm_srgb => mtl.PixelFormatASTC_8x6_sRGB,
        .astc8x8_unorm => mtl.PixelFormatASTC_8x8_LDR,
        .astc8x8_unorm_srgb => mtl.PixelFormatASTC_8x8_sRGB,
        .astc10x5_unorm => mtl.PixelFormatASTC_10x5_LDR,
        .astc10x5_unorm_srgb => mtl.PixelFormatASTC_10x5_sRGB,
        .astc10x6_unorm => mtl.PixelFormatASTC_10x6_LDR,
        .astc10x6_unorm_srgb => mtl.PixelFormatASTC_10x6_sRGB,
        .astc10x8_unorm => mtl.PixelFormatASTC_10x8_LDR,
        .astc10x8_unorm_srgb => mtl.PixelFormatASTC_10x8_sRGB,
        .astc10x10_unorm => mtl.PixelFormatASTC_10x10_LDR,
        .astc10x10_unorm_srgb => mtl.PixelFormatASTC_10x10_sRGB,
        .astc12x10_unorm => mtl.PixelFormatASTC_12x10_LDR,
        .astc12x10_unorm_srgb => mtl.PixelFormatASTC_12x10_sRGB,
        .astc12x12_unorm => mtl.PixelFormatASTC_12x12_LDR,
        .astc12x12_unorm_srgb => mtl.PixelFormatASTC_12x12_sRGB,
        .r8_bg8_biplanar420_unorm => unreachable,
    };
}

pub fn metalPixelFormatForView(viewFormat: sysgpu.Texture.Format, textureFormat: mtl.PixelFormat, aspect: sysgpu.Texture.Aspect) mtl.PixelFormat {
    // TODO - depth/stencil only views
    _ = aspect;
    _ = textureFormat;

    return metalPixelFormat(viewFormat);
}

pub fn metalPrimitiveTopologyClass(topology: sysgpu.PrimitiveTopology) mtl.PrimitiveTopologyClass {
    return switch (topology) {
        .point_list => mtl.PrimitiveTopologyClassPoint,
        .line_list => mtl.PrimitiveTopologyClassLine,
        .line_strip => mtl.PrimitiveTopologyClassLine,
        .triangle_list => mtl.PrimitiveTopologyClassTriangle,
        .triangle_strip => mtl.PrimitiveTopologyClassTriangle,
    };
}

pub fn metalPrimitiveType(topology: sysgpu.PrimitiveTopology) mtl.PrimitiveType {
    return switch (topology) {
        .point_list => mtl.PrimitiveTypePoint,
        .line_list => mtl.PrimitiveTypeLine,
        .line_strip => mtl.PrimitiveTypeLineStrip,
        .triangle_list => mtl.PrimitiveTypeTriangle,
        .triangle_strip => mtl.PrimitiveTypeTriangleStrip,
    };
}

pub fn metalResourceOptionsForBuffer(usage: sysgpu.Buffer.UsageFlags) mtl.ResourceOptions {
    const cpu_cache_mode = if (usage.map_write and !usage.map_read) mtl.ResourceCPUCacheModeWriteCombined else mtl.ResourceCPUCacheModeDefaultCache;
    const storage_mode = mtl.ResourceStorageModeShared; // optimizing for UMA only
    const hazard_tracking_mode = mtl.ResourceHazardTrackingModeDefault;
    return cpu_cache_mode | storage_mode | hazard_tracking_mode;
}

pub fn metalSamplerAddressMode(mode: sysgpu.Sampler.AddressMode) mtl.SamplerAddressMode {
    return switch (mode) {
        .repeat => mtl.SamplerAddressModeRepeat,
        .mirror_repeat => mtl.SamplerAddressModeMirrorRepeat,
        .clamp_to_edge => mtl.SamplerAddressModeClampToEdge,
    };
}

pub fn metalSamplerMinMagFilter(mode: sysgpu.FilterMode) mtl.SamplerMinMagFilter {
    return switch (mode) {
        .nearest => mtl.SamplerMinMagFilterNearest,
        .linear => mtl.SamplerMinMagFilterLinear,
    };
}

pub fn metalSamplerMipFilter(mode: sysgpu.MipmapFilterMode) mtl.SamplerMipFilter {
    return switch (mode) {
        .nearest => mtl.SamplerMipFilterNearest,
        .linear => mtl.SamplerMipFilterLinear,
    };
}

pub fn metalStencilOperation(op: sysgpu.StencilOperation) mtl.StencilOperation {
    return switch (op) {
        .keep => mtl.StencilOperationKeep,
        .zero => mtl.StencilOperationZero,
        .replace => mtl.StencilOperationReplace,
        .invert => mtl.StencilOperationInvert,
        .increment_clamp => mtl.StencilOperationIncrementClamp,
        .decrement_clamp => mtl.StencilOperationDecrementClamp,
        .increment_wrap => mtl.StencilOperationIncrementWrap,
        .decrement_wrap => mtl.StencilOperationDecrementWrap,
    };
}

pub fn metalStorageModeForTexture(usage: sysgpu.Texture.UsageFlags) mtl.StorageMode {
    if (usage.transient_attachment) {
        return mtl.StorageModeMemoryless;
    } else {
        return mtl.StorageModePrivate;
    }
}

pub fn metalStoreAction(op: sysgpu.StoreOp, has_resolve_target: bool) mtl.StoreAction {
    return switch (op) {
        .undefined => unreachable,
        .store => if (has_resolve_target) mtl.StoreActionStoreAndMultisampleResolve else mtl.StoreActionStore,
        .discard => if (has_resolve_target) mtl.StoreActionMultisampleResolve else mtl.StoreActionDontCare,
    };
}

pub fn metalTextureType(dimension: sysgpu.Texture.Dimension, size: sysgpu.Extent3D, sample_count: u32) mtl.TextureType {
    return switch (dimension) {
        .dimension_1d => if (size.depth_or_array_layers > 1) mtl.TextureType1DArray else mtl.TextureType1D,
        .dimension_2d => if (sample_count > 1)
            if (size.depth_or_array_layers > 1)
                mtl.TextureType2DMultisampleArray
            else
                mtl.TextureType2DMultisample
        else if (size.depth_or_array_layers > 1)
            mtl.TextureType2DArray
        else
            mtl.TextureType2D,
        .dimension_3d => mtl.TextureType3D,
    };
}

pub fn metalTextureTypeForView(dimension: sysgpu.TextureView.Dimension) mtl.TextureType {
    return switch (dimension) {
        .dimension_undefined => unreachable,
        .dimension_1d => mtl.TextureType1D,
        .dimension_2d => mtl.TextureType2D,
        .dimension_2d_array => mtl.TextureType2DArray,
        .dimension_cube => mtl.TextureTypeCube,
        .dimension_cube_array => mtl.TextureTypeCubeArray,
        .dimension_3d => mtl.TextureType3D,
    };
}

pub fn metalTextureUsage(usage: sysgpu.Texture.UsageFlags, view_format_count: usize) mtl.TextureUsage {
    var mtl_usage = mtl.TextureUsageUnknown;
    if (usage.texture_binding)
        mtl_usage |= mtl.TextureUsageShaderRead;
    if (usage.storage_binding)
        mtl_usage |= mtl.TextureUsageShaderWrite;
    if (usage.render_attachment)
        mtl_usage |= mtl.TextureUsageRenderTarget;
    if (view_format_count > 0)
        mtl_usage |= mtl.TextureUsagePixelFormatView;
    return mtl_usage;
}

pub fn metalVertexFormat(format: sysgpu.VertexFormat) mtl.VertexFormat {
    return switch (format) {
        .undefined => mtl.VertexFormatInvalid,
        .uint8x2 => mtl.VertexFormatUChar2,
        .uint8x4 => mtl.VertexFormatUChar4,
        .sint8x2 => mtl.VertexFormatChar2,
        .sint8x4 => mtl.VertexFormatChar4,
        .unorm8x2 => mtl.VertexFormatUChar2Normalized,
        .unorm8x4 => mtl.VertexFormatUChar4Normalized,
        .snorm8x2 => mtl.VertexFormatChar2Normalized,
        .snorm8x4 => mtl.VertexFormatChar4Normalized,
        .uint16x2 => mtl.VertexFormatUShort2,
        .uint16x4 => mtl.VertexFormatUShort4,
        .sint16x2 => mtl.VertexFormatShort2,
        .sint16x4 => mtl.VertexFormatShort4,
        .unorm16x2 => mtl.VertexFormatUShort2Normalized,
        .unorm16x4 => mtl.VertexFormatUShort4Normalized,
        .snorm16x2 => mtl.VertexFormatShort2Normalized,
        .snorm16x4 => mtl.VertexFormatShort4Normalized,
        .float16x2 => mtl.VertexFormatHalf2,
        .float16x4 => mtl.VertexFormatHalf4,
        .float32 => mtl.VertexFormatFloat,
        .float32x2 => mtl.VertexFormatFloat2,
        .float32x3 => mtl.VertexFormatFloat3,
        .float32x4 => mtl.VertexFormatFloat4,
        .uint32 => mtl.VertexFormatUInt,
        .uint32x2 => mtl.VertexFormatUInt2,
        .uint32x3 => mtl.VertexFormatUInt3,
        .uint32x4 => mtl.VertexFormatUInt4,
        .sint32 => mtl.VertexFormatInt,
        .sint32x2 => mtl.VertexFormatInt2,
        .sint32x3 => mtl.VertexFormatInt3,
        .sint32x4 => mtl.VertexFormatInt4,
    };
}

pub fn metalVertexStepFunction(mode: sysgpu.VertexStepMode) mtl.VertexStepFunction {
    return switch (mode) {
        .vertex => mtl.VertexStepFunctionPerVertex,
        .instance => mtl.VertexStepFunctionPerInstance,
        .vertex_buffer_not_used => undefined,
    };
}

pub fn metalWinding(face: sysgpu.FrontFace) mtl.Winding {
    return switch (face) {
        .ccw => mtl.WindingCounterClockwise,
        .cw => mtl.WindingClockwise,
    };
}
