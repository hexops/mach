pub const FeatureName = enum(u32) {
    Undefined = 0x00000000,
    Depth24UnormStencil8 = 0x00000002,
    Depth32FloatStencil8 = 0x00000003,
    TimestampQuery = 0x00000004,
    PipelineStatisticsQuery = 0x00000005,
    TextureCompressionBC = 0x00000006,
    TextureCompressionETC2 = 0x00000007,
    TextureCompressionASTC = 0x00000008,
    IndirectFirstInstance = 0x00000009,
    DepthClamping = 0x000003E8,
    DawnShaderFloat16 = 0x000003E9,
    DawnInternalUsages = 0x000003EA,
    DawnMultiPlanarFormats = 0x000003EB,
    DawnNative = 0x000003EC,
};

test "syntax" {
    _ = FeatureName;
}
