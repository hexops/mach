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
//! # Releasing resources
//!
//! WebGPU objects such as textures provide two APIs to release resources:
//!
//! * Reference counting: `reference` / `release`
//! * Manual destruction: `destroy`
//!
//! Where possible, using `destroy` is preferred as it more explicitly communicates the intent to
//! the implementation.
//!
//! When an object is `destroy`d, it is merely marked as destroyed. If the object is used past that
//! point, it is not unsafe nor does it access undefined memory. Instead, you will merely recieve
//! errors. The actual memory is released at the discretion of the implementation, possibly after a
//! few frames but it should be relatively soon (e.g. if the GPU is still using the resource, then
//! the implementation has to wait until it's safe to free.)
//!
//! Native implementations generally implement reference/release via referencing counting and invoke
//! destroy when zero is reached, but a browser implementation may choose to utilize these as
//! signals into an imprecise GC that may not even be aware of GPU-allocated memory (and so a 2MB
//! texture may appear as just a ~40b texture handle which is not important to free.)
//!
//! Implementations keep track of which objects are dead (so that errors, not undefined memory
//! accesses, occur) without truly keeping memory reserved for them by e.g. using a unique ID/handle
//! to represent a texture, and e.g. a hashmap from that handle to the memory. Thus, if the handle
//! doesn't exist in the map then it is dead.
//!
const std = @import("std");

// Root interface/implementations
pub const Interface = @import("Interface.zig");
pub const RequestAdapterOptions = Interface.RequestAdapterOptions;
pub const RequestAdapterErrorCode = Interface.RequestAdapterErrorCode;
pub const RequestAdapterError = Interface.RequestAdapterError;
pub const RequestAdapterResponse = Interface.RequestAdapterResponse;

pub const NativeInstance = @import("NativeInstance.zig");

// Interfaces
pub const Adapter = @import("Adapter.zig");
pub const Device = @import("Device.zig");
pub const Surface = @import("Surface.zig");
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
pub const CommandEncoder = @import("CommandEncoder.zig");
pub const ComputePassEncoder = @import("ComputePassEncoder.zig");
pub const ComputePipeline = @import("ComputePipeline.zig");

// Data structures ABI-compatible with webgpu.h
pub const Limits = @import("data.zig").Limits;
pub const Color = @import("data.zig").Color;
pub const Extent3D = @import("data.zig").Extent3D;
pub const Origin3D = @import("data.zig").Origin3D;
pub const StencilFaceState = @import("data.zig").StencilFaceState;
pub const VertexAttribute = @import("data.zig").VertexAttribute;
pub const BlendComponent = @import("data.zig").BlendComponent;
pub const BlendState = @import("data.zig").BlendState;
pub const VertexBufferLayout = @import("data.zig").VertexBufferLayout;

// Data structures not ABI-compatible with webgpu.h
pub const CompilationMessage = @import("structs.zig").CompilationMessage;
pub const CompilationInfo = @import("structs.zig").CompilationInfo;
pub const MultisampleState = @import("structs.zig").MultisampleState;
pub const PrimitiveState = @import("structs.zig").PrimitiveState;
pub const StorageTextureBindingLayout = @import("structs.zig").StorageTextureBindingLayout;
pub const DepthStencilState = @import("structs.zig").DepthStencilState;
pub const ConstantEntry = @import("structs.zig").ConstantEntry;
pub const ProgrammableStageDescriptor = @import("structs.zig").ProgrammableStageDescriptor;
pub const ComputePassTimestampWrite = @import("structs.zig").ComputePassTimestampWrite;

// Enumerations
pub const Feature = @import("enums.zig").Feature;
pub const PresentMode = @import("enums.zig").PresentMode;
pub const AddressMode = @import("enums.zig").AddressMode;
pub const AlphaMode = @import("enums.zig").AlphaMode;
pub const BlendFactor = @import("enums.zig").BlendFactor;
pub const BlendOperation = @import("enums.zig").BlendOperation;
pub const CompareFunction = @import("enums.zig").CompareFunction;
pub const CompilationInfoRequestStatus = @import("enums.zig").CompilationInfoRequestStatus;
pub const CompilationMessageType = @import("enums.zig").CompilationMessageType;
pub const ComputePassTimestampLocation = @import("enums.zig").ComputePassTimestampLocation;
pub const CreatePipelineAsyncStatus = @import("enums.zig").CreatePipelineAsyncStatus;
pub const CullMode = @import("enums.zig").CullMode;
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
pub const StencilOperation = @import("enums.zig").StencilOperation;
pub const StorageTextureAccess = @import("enums.zig").StorageTextureAccess;
pub const StoreOp = @import("enums.zig").StoreOp;
pub const VertexFormat = @import("enums.zig").VertexFormat;
pub const VertexStepMode = @import("enums.zig").VertexStepMode;
pub const BufferUsage = @import("enums.zig").BufferUsage;
pub const ColorWriteMask = @import("enums.zig").ColorWriteMask;
pub const MapMode = @import("enums.zig").MapMode;
pub const ShaderStage = @import("enums.zig").ShaderStage;

test "syntax" {
    // Root interface/implementations
    _ = Interface;
    _ = NativeInstance;

    // Interfaces
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
    _ = CommandEncoder;
    _ = ComputePassEncoder;
    _ = ComputePipeline;

    // Data structures ABI-compatible with webgpu.h
    _ = Limits;

    // Data structures not ABI-compatible with webgpu.h
    _ = CompilationMessage;

    // Enumerations
    _ = Feature;
}
