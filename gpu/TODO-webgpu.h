typedef struct WGPUChainedStruct {
    struct WGPUChainedStruct const * next;
    WGPUSType sType;
} WGPUChainedStruct;

typedef struct WGPUChainedStructOut {
    struct WGPUChainedStructOut * next;
    WGPUSType sType;
} WGPUChainedStructOut;

typedef struct WGPUAdapterProperties {
    WGPUChainedStructOut * nextInChain;
    uint32_t vendorID;
    char const * vendorName;
    char const * architecture;
    uint32_t deviceID;
    char const * name;
    char const * driverDescription;
    WGPUAdapterType adapterType;
    WGPUBackendType backendType;
} WGPUAdapterProperties;

typedef struct WGPUBindGroupEntry {
    WGPUChainedStruct const * nextInChain;
    uint32_t binding;
    WGPUBuffer buffer; // nullable
    uint64_t offset;
    uint64_t size;
    WGPUSampler sampler; // nullable
    WGPUTextureView textureView; // nullable
} WGPUBindGroupEntry;

typedef struct WGPUBlendComponent {
    WGPUBlendOperation operation;
    WGPUBlendFactor srcFactor;
    WGPUBlendFactor dstFactor;
} WGPUBlendComponent;

typedef struct WGPUBufferBindingLayout {
    WGPUChainedStruct const * nextInChain;
    WGPUBufferBindingType type;
    bool hasDynamicOffset;
    uint64_t minBindingSize;
} WGPUBufferBindingLayout;

typedef struct WGPUBufferDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUBufferUsageFlags usage;
    uint64_t size;
    bool mappedAtCreation;
} WGPUBufferDescriptor;

typedef struct WGPUColor {
    double r;
    double g;
    double b;
    double a;
} WGPUColor;

typedef struct WGPUCommandBufferDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
} WGPUCommandBufferDescriptor;

typedef struct WGPUCommandEncoderDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
} WGPUCommandEncoderDescriptor;

typedef struct WGPUCompilationMessage {
    WGPUChainedStruct const * nextInChain;
    char const * message; // nullable
    WGPUCompilationMessageType type;
    uint64_t lineNum;
    uint64_t linePos;
    uint64_t offset;
    uint64_t length;
} WGPUCompilationMessage;

typedef struct WGPUComputePassTimestampWrite {
    WGPUQuerySet querySet;
    uint32_t queryIndex;
    WGPUComputePassTimestampLocation location;
} WGPUComputePassTimestampWrite;

typedef struct WGPUConstantEntry {
    WGPUChainedStruct const * nextInChain;
    char const * key;
    double value;
} WGPUConstantEntry;

typedef struct WGPUCopyTextureForBrowserOptions {
    WGPUChainedStruct const * nextInChain;
    bool flipY;
    bool needsColorSpaceConversion;
    WGPUAlphaMode srcAlphaMode;
    float const * srcTransferFunctionParameters; // nullable
    float const * conversionMatrix; // nullable
    float const * dstTransferFunctionParameters; // nullable
    WGPUAlphaMode dstAlphaMode;
} WGPUCopyTextureForBrowserOptions;

typedef struct WGPUDawnCacheDeviceDescriptor {
    WGPUChainedStruct chain;
    char const * isolationKey;
} WGPUDawnCacheDeviceDescriptor;

typedef struct WGPUDawnEncoderInternalUsageDescriptor {
    WGPUChainedStruct chain;
    bool useInternalUsages;
} WGPUDawnEncoderInternalUsageDescriptor;

typedef struct WGPUDawnInstanceDescriptor {
    WGPUChainedStruct chain;
    uint32_t additionalRuntimeSearchPathsCount;
    const char* const * additionalRuntimeSearchPaths;
} WGPUDawnInstanceDescriptor;

typedef struct WGPUDawnTextureInternalUsageDescriptor {
    WGPUChainedStruct chain;
    WGPUTextureUsageFlags internalUsage;
} WGPUDawnTextureInternalUsageDescriptor;

typedef struct WGPUDawnTogglesDeviceDescriptor {
    WGPUChainedStruct chain;
    uint32_t forceEnabledTogglesCount;
    const char* const * forceEnabledToggles;
    uint32_t forceDisabledTogglesCount;
    const char* const * forceDisabledToggles;
} WGPUDawnTogglesDeviceDescriptor;

typedef struct WGPUExtent3D {
    uint32_t width;
    uint32_t height;
    uint32_t depthOrArrayLayers;
} WGPUExtent3D;

typedef struct WGPUExternalTextureBindingEntry {
    WGPUChainedStruct chain;
    WGPUExternalTexture externalTexture;
} WGPUExternalTextureBindingEntry;

typedef struct WGPUExternalTextureBindingLayout {
    WGPUChainedStruct chain;
} WGPUExternalTextureBindingLayout;

typedef struct WGPUExternalTextureDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUTextureView plane0;
    WGPUTextureView plane1; // nullable
    bool doYuvToRgbConversionOnly;
    float const * yuvToRgbConversionMatrix; // nullable
    float const * srcTransferFunctionParameters;
    float const * dstTransferFunctionParameters;
    float const * gamutConversionMatrix;
} WGPUExternalTextureDescriptor;

typedef struct WGPUInstanceDescriptor {
    WGPUChainedStruct const * nextInChain;
} WGPUInstanceDescriptor;

typedef struct WGPULimits {
    uint32_t maxTextureDimension1D;
    uint32_t maxTextureDimension2D;
    uint32_t maxTextureDimension3D;
    uint32_t maxTextureArrayLayers;
    uint32_t maxBindGroups;
    uint32_t maxDynamicUniformBuffersPerPipelineLayout;
    uint32_t maxDynamicStorageBuffersPerPipelineLayout;
    uint32_t maxSampledTexturesPerShaderStage;
    uint32_t maxSamplersPerShaderStage;
    uint32_t maxStorageBuffersPerShaderStage;
    uint32_t maxStorageTexturesPerShaderStage;
    uint32_t maxUniformBuffersPerShaderStage;
    uint64_t maxUniformBufferBindingSize;
    uint64_t maxStorageBufferBindingSize;
    uint32_t minUniformBufferOffsetAlignment;
    uint32_t minStorageBufferOffsetAlignment;
    uint32_t maxVertexBuffers;
    uint32_t maxVertexAttributes;
    uint32_t maxVertexBufferArrayStride;
    uint32_t maxInterStageShaderComponents;
    uint32_t maxInterStageShaderVariables;
    uint32_t maxColorAttachments;
    uint32_t maxComputeWorkgroupStorageSize;
    uint32_t maxComputeInvocationsPerWorkgroup;
    uint32_t maxComputeWorkgroupSizeX;
    uint32_t maxComputeWorkgroupSizeY;
    uint32_t maxComputeWorkgroupSizeZ;
    uint32_t maxComputeWorkgroupsPerDimension;
} WGPULimits;

typedef struct WGPUMultisampleState {
    WGPUChainedStruct const * nextInChain;
    uint32_t count;
    uint32_t mask;
    bool alphaToCoverageEnabled;
} WGPUMultisampleState;

typedef struct WGPUOrigin3D {
    uint32_t x;
    uint32_t y;
    uint32_t z;
} WGPUOrigin3D;

typedef struct WGPUPipelineLayoutDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    uint32_t bindGroupLayoutCount;
    WGPUBindGroupLayout const * bindGroupLayouts;
} WGPUPipelineLayoutDescriptor;

typedef struct WGPUPrimitiveDepthClampingState {
    WGPUChainedStruct chain;
    bool clampDepth;
} WGPUPrimitiveDepthClampingState;

typedef struct WGPUPrimitiveDepthClipControl {
    WGPUChainedStruct chain;
    bool unclippedDepth;
} WGPUPrimitiveDepthClipControl;

typedef struct WGPUPrimitiveState {
    WGPUChainedStruct const * nextInChain;
    WGPUPrimitiveTopology topology;
    WGPUIndexFormat stripIndexFormat;
    WGPUFrontFace frontFace;
    WGPUCullMode cullMode;
} WGPUPrimitiveState;

typedef struct WGPUQuerySetDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUQueryType type;
    uint32_t count;
    WGPUPipelineStatisticName const * pipelineStatistics;
    uint32_t pipelineStatisticsCount;
} WGPUQuerySetDescriptor;

typedef struct WGPUQueueDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
} WGPUQueueDescriptor;

typedef struct WGPURenderBundleDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
} WGPURenderBundleDescriptor;

typedef struct WGPURenderBundleEncoderDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    uint32_t colorFormatsCount;
    WGPUTextureFormat const * colorFormats;
    WGPUTextureFormat depthStencilFormat;
    uint32_t sampleCount;
    bool depthReadOnly;
    bool stencilReadOnly;
} WGPURenderBundleEncoderDescriptor;

typedef struct WGPURenderPassDepthStencilAttachment {
    WGPUTextureView view;
    WGPULoadOp depthLoadOp;
    WGPUStoreOp depthStoreOp;
    float clearDepth;
    float depthClearValue;
    bool depthReadOnly;
    WGPULoadOp stencilLoadOp;
    WGPUStoreOp stencilStoreOp;
    uint32_t clearStencil;
    uint32_t stencilClearValue;
    bool stencilReadOnly;
} WGPURenderPassDepthStencilAttachment;

typedef struct WGPURenderPassDescriptorMaxDrawCount {
    WGPUChainedStruct chain;
    uint64_t maxDrawCount;
} WGPURenderPassDescriptorMaxDrawCount;

typedef struct WGPURenderPassTimestampWrite {
    WGPUQuerySet querySet;
    uint32_t queryIndex;
    WGPURenderPassTimestampLocation location;
} WGPURenderPassTimestampWrite;

typedef struct WGPURequestAdapterOptions {
    WGPUChainedStruct const * nextInChain;
    WGPUSurface compatibleSurface; // nullable
    WGPUPowerPreference powerPreference;
    bool forceFallbackAdapter;
} WGPURequestAdapterOptions;

typedef struct WGPUSamplerBindingLayout {
    WGPUChainedStruct const * nextInChain;
    WGPUSamplerBindingType type;
} WGPUSamplerBindingLayout;

typedef struct WGPUSamplerDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUAddressMode addressModeU;
    WGPUAddressMode addressModeV;
    WGPUAddressMode addressModeW;
    WGPUFilterMode magFilter;
    WGPUFilterMode minFilter;
    WGPUFilterMode mipmapFilter;
    float lodMinClamp;
    float lodMaxClamp;
    WGPUCompareFunction compare;
    uint16_t maxAnisotropy;
} WGPUSamplerDescriptor;

typedef struct WGPUShaderModuleDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
} WGPUShaderModuleDescriptor;

typedef struct WGPUShaderModuleSPIRVDescriptor {
    WGPUChainedStruct chain;
    uint32_t codeSize;
    uint32_t const * code;
} WGPUShaderModuleSPIRVDescriptor;

typedef struct WGPUShaderModuleWGSLDescriptor {
    WGPUChainedStruct chain;
    char const * source;
} WGPUShaderModuleWGSLDescriptor;

typedef struct WGPUStencilFaceState {
    WGPUCompareFunction compare;
    WGPUStencilOperation failOp;
    WGPUStencilOperation depthFailOp;
    WGPUStencilOperation passOp;
} WGPUStencilFaceState;

typedef struct WGPUStorageTextureBindingLayout {
    WGPUChainedStruct const * nextInChain;
    WGPUStorageTextureAccess access;
    WGPUTextureFormat format;
    WGPUTextureViewDimension viewDimension;
} WGPUStorageTextureBindingLayout;

typedef struct WGPUSurfaceDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
} WGPUSurfaceDescriptor;

typedef struct WGPUSurfaceDescriptorFromAndroidNativeWindow {
    WGPUChainedStruct chain;
    void * window;
} WGPUSurfaceDescriptorFromAndroidNativeWindow;

typedef struct WGPUSurfaceDescriptorFromCanvasHTMLSelector {
    WGPUChainedStruct chain;
    char const * selector;
} WGPUSurfaceDescriptorFromCanvasHTMLSelector;

typedef struct WGPUSurfaceDescriptorFromMetalLayer {
    WGPUChainedStruct chain;
    void * layer;
} WGPUSurfaceDescriptorFromMetalLayer;

typedef struct WGPUSurfaceDescriptorFromWaylandSurface {
    WGPUChainedStruct chain;
    void * display;
    void * surface;
} WGPUSurfaceDescriptorFromWaylandSurface;

typedef struct WGPUSurfaceDescriptorFromWindowsCoreWindow {
    WGPUChainedStruct chain;
    void * coreWindow;
} WGPUSurfaceDescriptorFromWindowsCoreWindow;

typedef struct WGPUSurfaceDescriptorFromWindowsHWND {
    WGPUChainedStruct chain;
    void * hinstance;
    void * hwnd;
} WGPUSurfaceDescriptorFromWindowsHWND;

typedef struct WGPUSurfaceDescriptorFromWindowsSwapChainPanel {
    WGPUChainedStruct chain;
    void * swapChainPanel;
} WGPUSurfaceDescriptorFromWindowsSwapChainPanel;

typedef struct WGPUSurfaceDescriptorFromXlibWindow {
    WGPUChainedStruct chain;
    void * display;
    uint32_t window;
} WGPUSurfaceDescriptorFromXlibWindow;

typedef struct WGPUSwapChainDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUTextureUsageFlags usage;
    WGPUTextureFormat format;
    uint32_t width;
    uint32_t height;
    WGPUPresentMode presentMode;
    uint64_t implementation;
} WGPUSwapChainDescriptor;

typedef struct WGPUTextureBindingLayout {
    WGPUChainedStruct const * nextInChain;
    WGPUTextureSampleType sampleType;
    WGPUTextureViewDimension viewDimension;
    bool multisampled;
} WGPUTextureBindingLayout;

typedef struct WGPUTextureDataLayout {
    WGPUChainedStruct const * nextInChain;
    uint64_t offset;
    uint32_t bytesPerRow;
    uint32_t rowsPerImage;
} WGPUTextureDataLayout;

typedef struct WGPUTextureViewDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUTextureFormat format;
    WGPUTextureViewDimension dimension;
    uint32_t baseMipLevel;
    uint32_t mipLevelCount;
    uint32_t baseArrayLayer;
    uint32_t arrayLayerCount;
    WGPUTextureAspect aspect;
} WGPUTextureViewDescriptor;

typedef struct WGPUVertexAttribute {
    WGPUVertexFormat format;
    uint64_t offset;
    uint32_t shaderLocation;
} WGPUVertexAttribute;

typedef struct WGPUBindGroupDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUBindGroupLayout layout;
    uint32_t entryCount;
    WGPUBindGroupEntry const * entries;
} WGPUBindGroupDescriptor;

typedef struct WGPUBindGroupLayoutEntry {
    WGPUChainedStruct const * nextInChain;
    uint32_t binding;
    WGPUShaderStageFlags visibility;
    WGPUBufferBindingLayout buffer;
    WGPUSamplerBindingLayout sampler;
    WGPUTextureBindingLayout texture;
    WGPUStorageTextureBindingLayout storageTexture;
} WGPUBindGroupLayoutEntry;

typedef struct WGPUBlendState {
    WGPUBlendComponent color;
    WGPUBlendComponent alpha;
} WGPUBlendState;

typedef struct WGPUCompilationInfo {
    WGPUChainedStruct const * nextInChain;
    uint32_t messageCount;
    WGPUCompilationMessage const * messages;
} WGPUCompilationInfo;

typedef struct WGPUComputePassDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    uint32_t timestampWriteCount;
    WGPUComputePassTimestampWrite const * timestampWrites;
} WGPUComputePassDescriptor;

typedef struct WGPUDepthStencilState {
    WGPUChainedStruct const * nextInChain;
    WGPUTextureFormat format;
    bool depthWriteEnabled;
    WGPUCompareFunction depthCompare;
    WGPUStencilFaceState stencilFront;
    WGPUStencilFaceState stencilBack;
    uint32_t stencilReadMask;
    uint32_t stencilWriteMask;
    int32_t depthBias;
    float depthBiasSlopeScale;
    float depthBiasClamp;
} WGPUDepthStencilState;

typedef struct WGPUImageCopyBuffer {
    WGPUChainedStruct const * nextInChain;
    WGPUTextureDataLayout layout;
    WGPUBuffer buffer;
} WGPUImageCopyBuffer;

typedef struct WGPUImageCopyTexture {
    WGPUChainedStruct const * nextInChain;
    WGPUTexture texture;
    uint32_t mipLevel;
    WGPUOrigin3D origin;
    WGPUTextureAspect aspect;
} WGPUImageCopyTexture;

typedef struct WGPUProgrammableStageDescriptor {
    WGPUChainedStruct const * nextInChain;
    WGPUShaderModule module;
    char const * entryPoint;
    uint32_t constantCount;
    WGPUConstantEntry const * constants;
} WGPUProgrammableStageDescriptor;

typedef struct WGPURenderPassColorAttachment {
    WGPUTextureView view; // nullable
    WGPUTextureView resolveTarget; // nullable
    WGPULoadOp loadOp;
    WGPUStoreOp storeOp;
    WGPUColor clearColor;
    WGPUColor clearValue;
} WGPURenderPassColorAttachment;

typedef struct WGPURequiredLimits {
    WGPUChainedStruct const * nextInChain;
    WGPULimits limits;
} WGPURequiredLimits;

typedef struct WGPUSupportedLimits {
    WGPUChainedStructOut * nextInChain;
    WGPULimits limits;
} WGPUSupportedLimits;

typedef struct WGPUTextureDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUTextureUsageFlags usage;
    WGPUTextureDimension dimension;
    WGPUExtent3D size;
    WGPUTextureFormat format;
    uint32_t mipLevelCount;
    uint32_t sampleCount;
    uint32_t viewFormatCount;
    WGPUTextureFormat const * viewFormats;
} WGPUTextureDescriptor;

typedef struct WGPUVertexBufferLayout {
    uint64_t arrayStride;
    WGPUVertexStepMode stepMode;
    uint32_t attributeCount;
    WGPUVertexAttribute const * attributes;
} WGPUVertexBufferLayout;

typedef struct WGPUBindGroupLayoutDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    uint32_t entryCount;
    WGPUBindGroupLayoutEntry const * entries;
} WGPUBindGroupLayoutDescriptor;

typedef struct WGPUColorTargetState {
    WGPUChainedStruct const * nextInChain;
    WGPUTextureFormat format;
    WGPUBlendState const * blend; // nullable
    WGPUColorWriteMaskFlags writeMask;
} WGPUColorTargetState;

typedef struct WGPUComputePipelineDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUPipelineLayout layout; // nullable
    WGPUProgrammableStageDescriptor compute;
} WGPUComputePipelineDescriptor;

typedef struct WGPUDeviceDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    uint32_t requiredFeaturesCount;
    WGPUFeatureName const * requiredFeatures;
    WGPURequiredLimits const * requiredLimits; // nullable
    WGPUQueueDescriptor defaultQueue;
} WGPUDeviceDescriptor;

typedef struct WGPURenderPassDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    uint32_t colorAttachmentCount;
    WGPURenderPassColorAttachment const * colorAttachments;
    WGPURenderPassDepthStencilAttachment const * depthStencilAttachment; // nullable
    WGPUQuerySet occlusionQuerySet; // nullable
    uint32_t timestampWriteCount;
    WGPURenderPassTimestampWrite const * timestampWrites;
} WGPURenderPassDescriptor;

typedef struct WGPUVertexState {
    WGPUChainedStruct const * nextInChain;
    WGPUShaderModule module;
    char const * entryPoint;
    uint32_t constantCount;
    WGPUConstantEntry const * constants;
    uint32_t bufferCount;
    WGPUVertexBufferLayout const * buffers;
} WGPUVertexState;

typedef struct WGPUFragmentState {
    WGPUChainedStruct const * nextInChain;
    WGPUShaderModule module;
    char const * entryPoint;
    uint32_t constantCount;
    WGPUConstantEntry const * constants;
    uint32_t targetCount;
    WGPUColorTargetState const * targets;
} WGPUFragmentState;

typedef struct WGPURenderPipelineDescriptor {
    WGPUChainedStruct const * nextInChain;
    char const * label; // nullable
    WGPUPipelineLayout layout; // nullable
    WGPUVertexState vertex;
    WGPUPrimitiveState primitive;
    WGPUDepthStencilState const * depthStencil; // nullable
    WGPUMultisampleState multisample;
    WGPUFragmentState const * fragment; // nullable
} WGPURenderPipelineDescriptor;

typedef void (*WGPUBufferMapCallback)(WGPUBufferMapAsyncStatus status, void * userdata);
typedef void (*WGPUCompilationInfoCallback)(WGPUCompilationInfoRequestStatus status, WGPUCompilationInfo const * compilationInfo, void * userdata);
typedef void (*WGPUCreateComputePipelineAsyncCallback)(WGPUCreatePipelineAsyncStatus status, WGPUComputePipeline pipeline, char const * message, void * userdata);
typedef void (*WGPUCreateRenderPipelineAsyncCallback)(WGPUCreatePipelineAsyncStatus status, WGPURenderPipeline pipeline, char const * message, void * userdata);
typedef void (*WGPUDeviceLostCallback)(WGPUDeviceLostReason reason, char const * message, void * userdata);
typedef void (*WGPUErrorCallback)(WGPUErrorType type, char const * message, void * userdata);
typedef void (*WGPULoggingCallback)(WGPULoggingType type, char const * message, void * userdata);
typedef void (*WGPUProc)(void);
typedef void (*WGPUQueueWorkDoneCallback)(WGPUQueueWorkDoneStatus status, void * userdata);
typedef void (*WGPURequestAdapterCallback)(WGPURequestAdapterStatus status, WGPUAdapter adapter, char const * message, void * userdata);
typedef void (*WGPURequestDeviceCallback)(WGPURequestDeviceStatus status, WGPUDevice device, char const * message, void * userdata);

WGPU_EXPORT WGPUInstance wgpuCreateInstance(WGPUInstanceDescriptor const * descriptor);
WGPU_EXPORT WGPUProc wgpuGetProcAddress(WGPUDevice device, char const * procName);

// Methods of Adapter
WGPU_EXPORT WGPUDevice wgpuAdapterCreateDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor /* nullable */);
WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
WGPU_EXPORT bool wgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);
WGPU_EXPORT void wgpuAdapterGetProperties(WGPUAdapter adapter, WGPUAdapterProperties * properties);
WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
WGPU_EXPORT void wgpuAdapterRequestDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor, WGPURequestDeviceCallback callback, void * userdata);
WGPU_EXPORT void wgpuAdapterReference(WGPUAdapter adapter);
WGPU_EXPORT void wgpuAdapterRelease(WGPUAdapter adapter);

// Methods of BindGroup
WGPU_EXPORT void wgpuBindGroupSetLabel(WGPUBindGroup bindGroup, char const * label);
WGPU_EXPORT void wgpuBindGroupReference(WGPUBindGroup bindGroup);
WGPU_EXPORT void wgpuBindGroupRelease(WGPUBindGroup bindGroup);

// Methods of BindGroupLayout
WGPU_EXPORT void wgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, char const * label);
WGPU_EXPORT void wgpuBindGroupLayoutReference(WGPUBindGroupLayout bindGroupLayout);
WGPU_EXPORT void wgpuBindGroupLayoutRelease(WGPUBindGroupLayout bindGroupLayout);

// Methods of Buffer
WGPU_EXPORT void wgpuBufferDestroy(WGPUBuffer buffer);
WGPU_EXPORT void const * wgpuBufferGetConstMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
WGPU_EXPORT void * wgpuBufferGetMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
WGPU_EXPORT uint64_t wgpuBufferGetSize(WGPUBuffer buffer);
WGPU_EXPORT WGPUBufferUsage wgpuBufferGetUsage(WGPUBuffer buffer);
WGPU_EXPORT void wgpuBufferMapAsync(WGPUBuffer buffer, WGPUMapModeFlags mode, size_t offset, size_t size, WGPUBufferMapCallback callback, void * userdata);
WGPU_EXPORT void wgpuBufferSetLabel(WGPUBuffer buffer, char const * label);
WGPU_EXPORT void wgpuBufferUnmap(WGPUBuffer buffer);
WGPU_EXPORT void wgpuBufferReference(WGPUBuffer buffer);
WGPU_EXPORT void wgpuBufferRelease(WGPUBuffer buffer);

// Methods of CommandBuffer
WGPU_EXPORT void wgpuCommandBufferSetLabel(WGPUCommandBuffer commandBuffer, char const * label);
WGPU_EXPORT void wgpuCommandBufferReference(WGPUCommandBuffer commandBuffer);
WGPU_EXPORT void wgpuCommandBufferRelease(WGPUCommandBuffer commandBuffer);

// Methods of CommandEncoder
WGPU_EXPORT WGPUComputePassEncoder wgpuCommandEncoderBeginComputePass(WGPUCommandEncoder commandEncoder, WGPUComputePassDescriptor const * descriptor /* nullable */);
WGPU_EXPORT WGPURenderPassEncoder wgpuCommandEncoderBeginRenderPass(WGPUCommandEncoder commandEncoder, WGPURenderPassDescriptor const * descriptor);
WGPU_EXPORT void wgpuCommandEncoderClearBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t offset, uint64_t size);
WGPU_EXPORT void wgpuCommandEncoderCopyBufferToBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer source, uint64_t sourceOffset, WGPUBuffer destination, uint64_t destinationOffset, uint64_t size);
WGPU_EXPORT void wgpuCommandEncoderCopyBufferToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyBuffer const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
WGPU_EXPORT void wgpuCommandEncoderCopyTextureToBuffer(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyBuffer const * destination, WGPUExtent3D const * copySize);
WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTextureInternal(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
WGPU_EXPORT WGPUCommandBuffer wgpuCommandEncoderFinish(WGPUCommandEncoder commandEncoder, WGPUCommandBufferDescriptor const * descriptor /* nullable */);
WGPU_EXPORT void wgpuCommandEncoderInjectValidationError(WGPUCommandEncoder commandEncoder, char const * message);
WGPU_EXPORT void wgpuCommandEncoderInsertDebugMarker(WGPUCommandEncoder commandEncoder, char const * markerLabel);
WGPU_EXPORT void wgpuCommandEncoderPopDebugGroup(WGPUCommandEncoder commandEncoder);
WGPU_EXPORT void wgpuCommandEncoderPushDebugGroup(WGPUCommandEncoder commandEncoder, char const * groupLabel);
WGPU_EXPORT void wgpuCommandEncoderResolveQuerySet(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t firstQuery, uint32_t queryCount, WGPUBuffer destination, uint64_t destinationOffset);
WGPU_EXPORT void wgpuCommandEncoderSetLabel(WGPUCommandEncoder commandEncoder, char const * label);
WGPU_EXPORT void wgpuCommandEncoderWriteBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t bufferOffset, uint8_t const * data, uint64_t size);
WGPU_EXPORT void wgpuCommandEncoderWriteTimestamp(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
WGPU_EXPORT void wgpuCommandEncoderReference(WGPUCommandEncoder commandEncoder);
WGPU_EXPORT void wgpuCommandEncoderRelease(WGPUCommandEncoder commandEncoder);

// Methods of ComputePassEncoder
WGPU_EXPORT void wgpuComputePassEncoderDispatch(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
WGPU_EXPORT void wgpuComputePassEncoderDispatchIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroups(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroupsIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
WGPU_EXPORT void wgpuComputePassEncoderEnd(WGPUComputePassEncoder computePassEncoder);
WGPU_EXPORT void wgpuComputePassEncoderEndPass(WGPUComputePassEncoder computePassEncoder);
WGPU_EXPORT void wgpuComputePassEncoderInsertDebugMarker(WGPUComputePassEncoder computePassEncoder, char const * markerLabel);
WGPU_EXPORT void wgpuComputePassEncoderPopDebugGroup(WGPUComputePassEncoder computePassEncoder);
WGPU_EXPORT void wgpuComputePassEncoderPushDebugGroup(WGPUComputePassEncoder computePassEncoder, char const * groupLabel);
WGPU_EXPORT void wgpuComputePassEncoderSetBindGroup(WGPUComputePassEncoder computePassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
WGPU_EXPORT void wgpuComputePassEncoderSetLabel(WGPUComputePassEncoder computePassEncoder, char const * label);
WGPU_EXPORT void wgpuComputePassEncoderSetPipeline(WGPUComputePassEncoder computePassEncoder, WGPUComputePipeline pipeline);
WGPU_EXPORT void wgpuComputePassEncoderWriteTimestamp(WGPUComputePassEncoder computePassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
WGPU_EXPORT void wgpuComputePassEncoderReference(WGPUComputePassEncoder computePassEncoder);
WGPU_EXPORT void wgpuComputePassEncoderRelease(WGPUComputePassEncoder computePassEncoder);

// Methods of ComputePipeline
WGPU_EXPORT WGPUBindGroupLayout wgpuComputePipelineGetBindGroupLayout(WGPUComputePipeline computePipeline, uint32_t groupIndex);
WGPU_EXPORT void wgpuComputePipelineSetLabel(WGPUComputePipeline computePipeline, char const * label);
WGPU_EXPORT void wgpuComputePipelineReference(WGPUComputePipeline computePipeline);
WGPU_EXPORT void wgpuComputePipelineRelease(WGPUComputePipeline computePipeline);

// Methods of Device
WGPU_EXPORT WGPUBindGroup wgpuDeviceCreateBindGroup(WGPUDevice device, WGPUBindGroupDescriptor const * descriptor);
WGPU_EXPORT WGPUBindGroupLayout wgpuDeviceCreateBindGroupLayout(WGPUDevice device, WGPUBindGroupLayoutDescriptor const * descriptor);
WGPU_EXPORT WGPUBuffer wgpuDeviceCreateBuffer(WGPUDevice device, WGPUBufferDescriptor const * descriptor);
WGPU_EXPORT WGPUCommandEncoder wgpuDeviceCreateCommandEncoder(WGPUDevice device, WGPUCommandEncoderDescriptor const * descriptor /* nullable */);
WGPU_EXPORT WGPUComputePipeline wgpuDeviceCreateComputePipeline(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor);
WGPU_EXPORT void wgpuDeviceCreateComputePipelineAsync(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor, WGPUCreateComputePipelineAsyncCallback callback, void * userdata);
WGPU_EXPORT WGPUBuffer wgpuDeviceCreateErrorBuffer(WGPUDevice device);
WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateErrorExternalTexture(WGPUDevice device);
WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateExternalTexture(WGPUDevice device, WGPUExternalTextureDescriptor const * externalTextureDescriptor);
WGPU_EXPORT WGPUPipelineLayout wgpuDeviceCreatePipelineLayout(WGPUDevice device, WGPUPipelineLayoutDescriptor const * descriptor);
WGPU_EXPORT WGPUQuerySet wgpuDeviceCreateQuerySet(WGPUDevice device, WGPUQuerySetDescriptor const * descriptor);
WGPU_EXPORT WGPURenderBundleEncoder wgpuDeviceCreateRenderBundleEncoder(WGPUDevice device, WGPURenderBundleEncoderDescriptor const * descriptor);
WGPU_EXPORT WGPURenderPipeline wgpuDeviceCreateRenderPipeline(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor);
WGPU_EXPORT void wgpuDeviceCreateRenderPipelineAsync(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor, WGPUCreateRenderPipelineAsyncCallback callback, void * userdata);
WGPU_EXPORT WGPUSampler wgpuDeviceCreateSampler(WGPUDevice device, WGPUSamplerDescriptor const * descriptor /* nullable */);
WGPU_EXPORT WGPUShaderModule wgpuDeviceCreateShaderModule(WGPUDevice device, WGPUShaderModuleDescriptor const * descriptor);
WGPU_EXPORT WGPUSwapChain wgpuDeviceCreateSwapChain(WGPUDevice device, WGPUSurface surface /* nullable */, WGPUSwapChainDescriptor const * descriptor);
WGPU_EXPORT WGPUTexture wgpuDeviceCreateTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
WGPU_EXPORT void wgpuDeviceDestroy(WGPUDevice device);
WGPU_EXPORT size_t wgpuDeviceEnumerateFeatures(WGPUDevice device, WGPUFeatureName * features);
WGPU_EXPORT bool wgpuDeviceGetLimits(WGPUDevice device, WGPUSupportedLimits * limits);
WGPU_EXPORT WGPUQueue wgpuDeviceGetQueue(WGPUDevice device);
WGPU_EXPORT bool wgpuDeviceHasFeature(WGPUDevice device, WGPUFeatureName feature);
WGPU_EXPORT void wgpuDeviceInjectError(WGPUDevice device, WGPUErrorType type, char const * message);
WGPU_EXPORT void wgpuDeviceLoseForTesting(WGPUDevice device);
WGPU_EXPORT bool wgpuDevicePopErrorScope(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
WGPU_EXPORT void wgpuDevicePushErrorScope(WGPUDevice device, WGPUErrorFilter filter);
WGPU_EXPORT void wgpuDeviceSetDeviceLostCallback(WGPUDevice device, WGPUDeviceLostCallback callback, void * userdata);
WGPU_EXPORT void wgpuDeviceSetLabel(WGPUDevice device, char const * label);
WGPU_EXPORT void wgpuDeviceSetLoggingCallback(WGPUDevice device, WGPULoggingCallback callback, void * userdata);
WGPU_EXPORT void wgpuDeviceSetUncapturedErrorCallback(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
WGPU_EXPORT void wgpuDeviceTick(WGPUDevice device);
WGPU_EXPORT void wgpuDeviceReference(WGPUDevice device);
WGPU_EXPORT void wgpuDeviceRelease(WGPUDevice device);

// Methods of ExternalTexture
WGPU_EXPORT void wgpuExternalTextureDestroy(WGPUExternalTexture externalTexture);
WGPU_EXPORT void wgpuExternalTextureSetLabel(WGPUExternalTexture externalTexture, char const * label);
WGPU_EXPORT void wgpuExternalTextureReference(WGPUExternalTexture externalTexture);
WGPU_EXPORT void wgpuExternalTextureRelease(WGPUExternalTexture externalTexture);

// Methods of Instance
WGPU_EXPORT WGPUSurface wgpuInstanceCreateSurface(WGPUInstance instance, WGPUSurfaceDescriptor const * descriptor);
WGPU_EXPORT void wgpuInstanceRequestAdapter(WGPUInstance instance, WGPURequestAdapterOptions const * options, WGPURequestAdapterCallback callback, void * userdata);
WGPU_EXPORT void wgpuInstanceReference(WGPUInstance instance);
WGPU_EXPORT void wgpuInstanceRelease(WGPUInstance instance);

// Methods of PipelineLayout
WGPU_EXPORT void wgpuPipelineLayoutSetLabel(WGPUPipelineLayout pipelineLayout, char const * label);
WGPU_EXPORT void wgpuPipelineLayoutReference(WGPUPipelineLayout pipelineLayout);
WGPU_EXPORT void wgpuPipelineLayoutRelease(WGPUPipelineLayout pipelineLayout);

// Methods of QuerySet
WGPU_EXPORT void wgpuQuerySetDestroy(WGPUQuerySet querySet);
WGPU_EXPORT uint32_t wgpuQuerySetGetCount(WGPUQuerySet querySet);
WGPU_EXPORT WGPUQueryType wgpuQuerySetGetType(WGPUQuerySet querySet);
WGPU_EXPORT void wgpuQuerySetSetLabel(WGPUQuerySet querySet, char const * label);
WGPU_EXPORT void wgpuQuerySetReference(WGPUQuerySet querySet);
WGPU_EXPORT void wgpuQuerySetRelease(WGPUQuerySet querySet);

// Methods of Queue
WGPU_EXPORT void wgpuQueueCopyTextureForBrowser(WGPUQueue queue, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize, WGPUCopyTextureForBrowserOptions const * options);
WGPU_EXPORT void wgpuQueueOnSubmittedWorkDone(WGPUQueue queue, uint64_t signalValue, WGPUQueueWorkDoneCallback callback, void * userdata);
WGPU_EXPORT void wgpuQueueSetLabel(WGPUQueue queue, char const * label);
WGPU_EXPORT void wgpuQueueSubmit(WGPUQueue queue, uint32_t commandCount, WGPUCommandBuffer const * commands);
WGPU_EXPORT void wgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size);
WGPU_EXPORT void wgpuQueueWriteTexture(WGPUQueue queue, WGPUImageCopyTexture const * destination, void const * data, size_t dataSize, WGPUTextureDataLayout const * dataLayout, WGPUExtent3D const * writeSize);
WGPU_EXPORT void wgpuQueueReference(WGPUQueue queue);
WGPU_EXPORT void wgpuQueueRelease(WGPUQueue queue);

// Methods of RenderBundle
WGPU_EXPORT void wgpuRenderBundleReference(WGPURenderBundle renderBundle);
WGPU_EXPORT void wgpuRenderBundleRelease(WGPURenderBundle renderBundle);

// Methods of RenderBundleEncoder
WGPU_EXPORT void wgpuRenderBundleEncoderDraw(WGPURenderBundleEncoder renderBundleEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexed(WGPURenderBundleEncoder renderBundleEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexedIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
WGPU_EXPORT WGPURenderBundle wgpuRenderBundleEncoderFinish(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderBundleDescriptor const * descriptor /* nullable */);
WGPU_EXPORT void wgpuRenderBundleEncoderInsertDebugMarker(WGPURenderBundleEncoder renderBundleEncoder, char const * markerLabel);
WGPU_EXPORT void wgpuRenderBundleEncoderPopDebugGroup(WGPURenderBundleEncoder renderBundleEncoder);
WGPU_EXPORT void wgpuRenderBundleEncoderPushDebugGroup(WGPURenderBundleEncoder renderBundleEncoder, char const * groupLabel);
WGPU_EXPORT void wgpuRenderBundleEncoderSetBindGroup(WGPURenderBundleEncoder renderBundleEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
WGPU_EXPORT void wgpuRenderBundleEncoderSetIndexBuffer(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
WGPU_EXPORT void wgpuRenderBundleEncoderSetLabel(WGPURenderBundleEncoder renderBundleEncoder, char const * label);
WGPU_EXPORT void wgpuRenderBundleEncoderSetPipeline(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderPipeline pipeline);
WGPU_EXPORT void wgpuRenderBundleEncoderSetVertexBuffer(WGPURenderBundleEncoder renderBundleEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
WGPU_EXPORT void wgpuRenderBundleEncoderReference(WGPURenderBundleEncoder renderBundleEncoder);
WGPU_EXPORT void wgpuRenderBundleEncoderRelease(WGPURenderBundleEncoder renderBundleEncoder);

// Methods of RenderPassEncoder
WGPU_EXPORT void wgpuRenderPassEncoderBeginOcclusionQuery(WGPURenderPassEncoder renderPassEncoder, uint32_t queryIndex);
WGPU_EXPORT void wgpuRenderPassEncoderDraw(WGPURenderPassEncoder renderPassEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexed(WGPURenderPassEncoder renderPassEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexedIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
WGPU_EXPORT void wgpuRenderPassEncoderDrawIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
WGPU_EXPORT void wgpuRenderPassEncoderEnd(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderEndOcclusionQuery(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderEndPass(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderExecuteBundles(WGPURenderPassEncoder renderPassEncoder, uint32_t bundlesCount, WGPURenderBundle const * bundles);
WGPU_EXPORT void wgpuRenderPassEncoderInsertDebugMarker(WGPURenderPassEncoder renderPassEncoder, char const * markerLabel);
WGPU_EXPORT void wgpuRenderPassEncoderPopDebugGroup(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderPushDebugGroup(WGPURenderPassEncoder renderPassEncoder, char const * groupLabel);
WGPU_EXPORT void wgpuRenderPassEncoderSetBindGroup(WGPURenderPassEncoder renderPassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
WGPU_EXPORT void wgpuRenderPassEncoderSetBlendConstant(WGPURenderPassEncoder renderPassEncoder, WGPUColor const * color);
WGPU_EXPORT void wgpuRenderPassEncoderSetIndexBuffer(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
WGPU_EXPORT void wgpuRenderPassEncoderSetLabel(WGPURenderPassEncoder renderPassEncoder, char const * label);
WGPU_EXPORT void wgpuRenderPassEncoderSetPipeline(WGPURenderPassEncoder renderPassEncoder, WGPURenderPipeline pipeline);
WGPU_EXPORT void wgpuRenderPassEncoderSetScissorRect(WGPURenderPassEncoder renderPassEncoder, uint32_t x, uint32_t y, uint32_t width, uint32_t height);
WGPU_EXPORT void wgpuRenderPassEncoderSetStencilReference(WGPURenderPassEncoder renderPassEncoder, uint32_t reference);
WGPU_EXPORT void wgpuRenderPassEncoderSetVertexBuffer(WGPURenderPassEncoder renderPassEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
WGPU_EXPORT void wgpuRenderPassEncoderSetViewport(WGPURenderPassEncoder renderPassEncoder, float x, float y, float width, float height, float minDepth, float maxDepth);
WGPU_EXPORT void wgpuRenderPassEncoderWriteTimestamp(WGPURenderPassEncoder renderPassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
WGPU_EXPORT void wgpuRenderPassEncoderReference(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderRelease(WGPURenderPassEncoder renderPassEncoder);

// Methods of RenderPipeline
WGPU_EXPORT WGPUBindGroupLayout wgpuRenderPipelineGetBindGroupLayout(WGPURenderPipeline renderPipeline, uint32_t groupIndex);
WGPU_EXPORT void wgpuRenderPipelineSetLabel(WGPURenderPipeline renderPipeline, char const * label);
WGPU_EXPORT void wgpuRenderPipelineReference(WGPURenderPipeline renderPipeline);
WGPU_EXPORT void wgpuRenderPipelineRelease(WGPURenderPipeline renderPipeline);

// Methods of Sampler
WGPU_EXPORT void wgpuSamplerSetLabel(WGPUSampler sampler, char const * label);
WGPU_EXPORT void wgpuSamplerReference(WGPUSampler sampler);
WGPU_EXPORT void wgpuSamplerRelease(WGPUSampler sampler);

// Methods of ShaderModule
WGPU_EXPORT void wgpuShaderModuleGetCompilationInfo(WGPUShaderModule shaderModule, WGPUCompilationInfoCallback callback, void * userdata);
WGPU_EXPORT void wgpuShaderModuleSetLabel(WGPUShaderModule shaderModule, char const * label);
WGPU_EXPORT void wgpuShaderModuleReference(WGPUShaderModule shaderModule);
WGPU_EXPORT void wgpuShaderModuleRelease(WGPUShaderModule shaderModule);

// Methods of Surface
WGPU_EXPORT void wgpuSurfaceReference(WGPUSurface surface);
WGPU_EXPORT void wgpuSurfaceRelease(WGPUSurface surface);

// Methods of SwapChain
WGPU_EXPORT void wgpuSwapChainConfigure(WGPUSwapChain swapChain, WGPUTextureFormat format, WGPUTextureUsageFlags allowedUsage, uint32_t width, uint32_t height);
WGPU_EXPORT WGPUTextureView wgpuSwapChainGetCurrentTextureView(WGPUSwapChain swapChain);
WGPU_EXPORT void wgpuSwapChainPresent(WGPUSwapChain swapChain);
WGPU_EXPORT void wgpuSwapChainReference(WGPUSwapChain swapChain);
WGPU_EXPORT void wgpuSwapChainRelease(WGPUSwapChain swapChain);

// Methods of Texture
WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor /* nullable */);
WGPU_EXPORT void wgpuTextureDestroy(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetDepthOrArrayLayers(WGPUTexture texture);
WGPU_EXPORT WGPUTextureDimension wgpuTextureGetDimension(WGPUTexture texture);
WGPU_EXPORT WGPUTextureFormat wgpuTextureGetFormat(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetHeight(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetMipLevelCount(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetSampleCount(WGPUTexture texture);
WGPU_EXPORT WGPUTextureUsage wgpuTextureGetUsage(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetWidth(WGPUTexture texture);
WGPU_EXPORT void wgpuTextureSetLabel(WGPUTexture texture, char const * label);
WGPU_EXPORT void wgpuTextureReference(WGPUTexture texture);
WGPU_EXPORT void wgpuTextureRelease(WGPUTexture texture);

// Methods of TextureView
WGPU_EXPORT void wgpuTextureViewSetLabel(WGPUTextureView textureView, char const * label);
WGPU_EXPORT void wgpuTextureViewReference(WGPUTextureView textureView);
WGPU_EXPORT void wgpuTextureViewRelease(WGPUTextureView textureView);
