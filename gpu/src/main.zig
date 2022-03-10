//! WebGPU interface for Zig
//!
//! # Coordinate Systems
//!
//! * Y-axis is up in normalized device coordinate (NDC): point(-1.0, -1.0) in NDC is located at
//!   the bottom-left corner of NDC. In addition, x and y in NDC should be between -1.0 and 1.0
//!   inclusive, while z in NDC should be between 0.0 and 1.0 inclusive. Vertices out of this range
//!   in NDC will not introduce any errors, but they will be clipped.
//! * Y-axis is down in framebuffer coordinate, viewport coordinate and fragment/pixel coordinate:
//!   origin(0, 0) is located at the top-left corner in these coordinate systems.
//! * Window/present coordinate matches framebuffer coordinate.
//! * UV of origin(0, 0) in texture coordinate represents the first texel (the lowest byte) in
//!   texture memory.
//!
//! Note: WebGPU’s coordinate systems match DirectX’s coordinate systems in a graphics pipeline.
//!
//! # Reference counting
//!
//! TODO: docs
//!
const std = @import("std");
pub const Interface = @import("Interface.zig");
pub const RequestAdapterOptions = Interface.RequestAdapterOptions;
pub const RequestAdapterErrorCode = Interface.RequestAdapterErrorCode;
pub const RequestAdapterError = Interface.RequestAdapterError;
pub const RequestAdapterResponse = Interface.RequestAdapterResponse;

pub const NativeInstance = @import("NativeInstance.zig");

pub const Adapter = @import("Adapter.zig");
pub const Device = @import("Device.zig");
pub const Surface = @import("Surface.zig");
pub const Limits = @import("Limits.zig");
pub const Queue = @import("Queue.zig");
pub const CommandBuffer = @import("CommandBuffer.zig");
pub const ShaderModule = @import("ShaderModule.zig");
pub const SwapChain = @import("SwapChain.zig");
pub const TextureView = @import("TextureView.zig");
pub const Texture = @import("Texture.zig");
pub const Sampler = @import("Sampler.zig");
pub const RenderPipeline = @import("RenderPipeline.zig");
pub const RenderPassEncoder = @import("RenderPassEncoder.zig");
pub const RenderBundleEncoder = @import("RenderBundleEncoder.zig");
pub const RenderBundle = @import("RenderBundle.zig");
pub const QuerySet = @import("QuerySet.zig");
pub const PipelineLayout = @import("PipelineLayout.zig");
pub const ExternalTexture = @import("ExternalTexture.zig");
pub const BindGroup = @import("BindGroup.zig");
pub const BindGroupLayout = @import("BindGroupLayout.zig");
pub const Buffer = @import("Buffer.zig");

pub const Feature = @import("enums.zig").Feature;
pub const TextureUsage = @import("enums.zig").TextureUsage;
pub const TextureFormat = @import("enums.zig").TextureFormat;
pub const PresentMode = @import("enums.zig").PresentMode;
pub const AddressMode = @import("enums.zig").AddressMode;
pub const AlphaMode = @import("enums.zig").AlphaMode;
pub const BlendFactor = @import("enums.zig").BlendFactor;
pub const BlendOperation = @import("enums.zig").BlendOperation;
pub const BufferBindingType = @import("enums.zig").BufferBindingType;
pub const BufferMapAsyncStatus = @import("enums.zig").BufferMapAsyncStatus;
pub const CompareFunction = @import("enums.zig").CompareFunction;
pub const CompilationInfoRequestStatus = @import("enums.zig").CompilationInfoRequestStatus;
pub const CompilationMessageType = @import("enums.zig").CompilationMessageType;
pub const ComputePassTimestampLocation = @import("enums.zig").ComputePassTimestampLocation;
pub const CreatePipelineAsyncStatus = @import("enums.zig").CreatePipelineAsyncStatus;
pub const CullMode = @import("enums.zig").CullMode;
pub const DeviceLostReason = @import("enums.zig").DeviceLostReason;
pub const ErrorFilter = @import("enums.zig").ErrorFilter;
pub const ErrorType = @import("enums.zig").ErrorType;
pub const FilterMode = @import("enums.zig").FilterMode;
pub const FrontFace = @import("enums.zig").FrontFace;
pub const IndexFormat = @import("enums.zig").IndexFormat;
pub const LoadOp = @import("enums.zig").LoadOp;
pub const LoggingType = @import("enums.zig").LoggingType;
pub const PipelineStatistic = @import("enums.zig").PipelineStatistic;
pub const PowerPreference = @import("enums.zig").PowerPreference;
pub const PredefinedColorSpace = @import("enums.zig").PredefinedColorSpace;
pub const PrimitiveTopology = @import("enums.zig").PrimitiveTopology;
pub const QueryType = @import("enums.zig").QueryType;
pub const RenderPassTimestampLocation = @import("enums.zig").RenderPassTimestampLocation;
pub const SamplerBindingType = @import("enums.zig").SamplerBindingType;
pub const StencilOperation = @import("enums.zig").StencilOperation;
pub const StorageTextureAccess = @import("enums.zig").StorageTextureAccess;
pub const StoreOp = @import("enums.zig").StoreOp;
pub const TextureAspect = @import("enums.zig").TextureAspect;
pub const TextureComponentType = @import("enums.zig").TextureComponentType;
pub const TextureDimension = @import("enums.zig").TextureDimension;
pub const TextureSampleType = @import("enums.zig").TextureSampleType;
pub const TextureViewDimension = @import("enums.zig").TextureViewDimension;
pub const VertexFormat = @import("enums.zig").VertexFormat;
pub const VertexStepMode = @import("enums.zig").VertexStepMode;
pub const BufferUsage = @import("enums.zig").BufferUsage;
pub const ColorWriteMask = @import("enums.zig").ColorWriteMask;
pub const MapMode = @import("enums.zig").MapMode;
pub const ShaderStage = @import("enums.zig").ShaderStage;

test "syntax" {
    _ = Interface;
    _ = NativeInstance;

    _ = Adapter;
    _ = Device;
    _ = Surface;
    _ = Limits;
    _ = Queue;
    _ = CommandBuffer;
    _ = ShaderModule;
    _ = SwapChain;
    _ = TextureView;
    _ = Texture;
    _ = Sampler;
    _ = RenderPipeline;
    _ = RenderPassEncoder;
    _ = RenderBundleEncoder;
    _ = RenderBundle;
    _ = QuerySet;
    _ = PipelineLayout;
    _ = ExternalTexture;
    _ = BindGroup;
    _ = BindGroupLayout;
    _ = Buffer;

    _ = Feature;
}
