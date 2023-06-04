const std = @import("std");

pub const Adapter = @import("adapter.zig").Adapter;
pub const BindGroup = @import("bind_group.zig").BindGroup;
pub const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
pub const Buffer = @import("buffer.zig").Buffer;
pub const CompilationInfoCallback = @import("callbacks.zig").CompilationInfoCallback;
pub const ErrorCallback = @import("callbacks.zig").ErrorCallback;
pub const LoggingCallback = @import("callbacks.zig").LoggingCallback;
pub const RequestDeviceCallback = @import("callbacks.zig").RequestDeviceCallback;
pub const RequestAdapterCallback = @import("callbacks.zig").RequestAdapterCallback;
pub const CreateComputePipelineAsyncCallback = @import("callbacks.zig").CreateComputePipelineAsyncCallback;
pub const CreateRenderPipelineAsyncCallback = @import("callbacks.zig").CreateRenderPipelineAsyncCallback;
pub const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
pub const CommandEncoder = @import("command_encoder.zig").CommandEncoder;
pub const ComputePassEncoder = @import("compute_pass_encoder.zig").ComputePassEncoder;
pub const ComputePipeline = @import("compute_pipeline.zig").ComputePipeline;
pub const Device = @import("device.zig").Device;
pub const ExternalTexture = @import("external_texture.zig").ExternalTexture;
pub const Instance = @import("instance.zig").Instance;
pub const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;
pub const QuerySet = @import("query_set.zig").QuerySet;
pub const Queue = @import("queue.zig").Queue;
pub const RenderBundle = @import("render_bundle.zig").RenderBundle;
pub const RenderBundleEncoder = @import("render_bundle_encoder.zig").RenderBundleEncoder;
pub const RenderPassEncoder = @import("render_pass_encoder.zig").RenderPassEncoder;
pub const RenderPipeline = @import("render_pipeline.zig").RenderPipeline;
pub const Sampler = @import("sampler.zig").Sampler;
pub const ShaderModule = @import("shader_module.zig").ShaderModule;
pub const Surface = @import("surface.zig").Surface;
pub const SwapChain = @import("swap_chain.zig").SwapChain;
pub const Texture = @import("texture.zig").Texture;
pub const TextureView = @import("texture_view.zig").TextureView;

pub const dawn = @import("dawn.zig");

pub const array_layer_count_undef = @import("types.zig").array_layer_count_undef;
pub const copy_stride_undef = @import("types.zig").copy_stride_undef;
pub const limit_u32_undef = @import("types.zig").limit_u32_undef;
pub const limit_u64_undef = @import("types.zig").limit_u64_undef;
pub const mip_level_count_undef = @import("types.zig").mip_level_count_undef;
pub const whole_map_size = @import("types.zig").whole_map_size;
pub const whole_size = @import("types.zig").whole_size;
pub const Proc = @import("types.zig").Proc;
pub const ComputePassTimestampWrite = @import("types.zig").ComputePassTimestampWrite;
pub const RenderPassDepthStencilAttachment = @import("types.zig").RenderPassDepthStencilAttachment;
pub const RenderPassTimestampWrite = @import("types.zig").RenderPassTimestampWrite;
pub const RequestAdapterOptions = @import("types.zig").RequestAdapterOptions;
pub const ComputePassDescriptor = @import("types.zig").ComputePassDescriptor;
pub const RenderPassDescriptor = @import("types.zig").RenderPassDescriptor;
pub const AlphaMode = @import("types.zig").AlphaMode;
pub const BackendType = @import("types.zig").BackendType;
pub const BlendFactor = @import("types.zig").BlendFactor;
pub const BlendOperation = @import("types.zig").BlendOperation;
pub const CompareFunction = @import("types.zig").CompareFunction;
pub const CompilationInfoRequestStatus = @import("types.zig").CompilationInfoRequestStatus;
pub const CompilationMessageType = @import("types.zig").CompilationMessageType;
pub const ComputePassTimestampLocation = @import("types.zig").ComputePassTimestampLocation;
pub const CreatePipelineAsyncStatus = @import("types.zig").CreatePipelineAsyncStatus;
pub const CullMode = @import("types.zig").CullMode;
pub const ErrorFilter = @import("types.zig").ErrorFilter;
pub const ErrorType = @import("types.zig").ErrorType;
pub const FeatureName = @import("types.zig").FeatureName;
pub const FilterMode = @import("types.zig").FilterMode;
pub const FrontFace = @import("types.zig").FrontFace;
pub const IndexFormat = @import("types.zig").IndexFormat;
pub const LoadOp = @import("types.zig").LoadOp;
pub const LoggingType = @import("types.zig").LoggingType;
pub const PipelineStatisticName = @import("types.zig").PipelineStatisticName;
pub const PowerPreference = @import("types.zig").PowerPreference;
pub const PresentMode = @import("types.zig").PresentMode;
pub const PrimitiveTopology = @import("types.zig").PrimitiveTopology;
pub const QueryType = @import("types.zig").QueryType;
pub const RenderPassTimestampLocation = @import("types.zig").RenderPassTimestampLocation;
pub const RequestAdapterStatus = @import("types.zig").RequestAdapterStatus;
pub const RequestDeviceStatus = @import("types.zig").RequestDeviceStatus;
pub const SType = @import("types.zig").SType;
pub const StencilOperation = @import("types.zig").StencilOperation;
pub const StorageTextureAccess = @import("types.zig").StorageTextureAccess;
pub const StoreOp = @import("types.zig").StoreOp;
pub const VertexFormat = @import("types.zig").VertexFormat;
pub const VertexStepMode = @import("types.zig").VertexStepMode;
pub const ColorWriteMaskFlags = @import("types.zig").ColorWriteMaskFlags;
pub const MapModeFlags = @import("types.zig").MapModeFlags;
pub const ShaderStageFlags = @import("types.zig").ShaderStageFlags;
pub const ChainedStruct = @import("types.zig").ChainedStruct;
pub const ChainedStructOut = @import("types.zig").ChainedStructOut;
pub const BlendComponent = @import("types.zig").BlendComponent;
pub const Color = @import("types.zig").Color;
pub const Extent2D = @import("types.zig").Extent2D;
pub const Extent3D = @import("types.zig").Extent3D;
pub const Limits = @import("types.zig").Limits;
pub const Origin2D = @import("types.zig").Origin2D;
pub const Origin3D = @import("types.zig").Origin3D;
pub const CompilationMessage = @import("types.zig").CompilationMessage;
pub const ConstantEntry = @import("types.zig").ConstantEntry;
pub const CopyTextureForBrowserOptions = @import("types.zig").CopyTextureForBrowserOptions;
pub const MultisampleState = @import("types.zig").MultisampleState;
pub const PrimitiveDepthClipControl = @import("types.zig").PrimitiveDepthClipControl;
pub const PrimitiveState = @import("types.zig").PrimitiveState;
pub const RenderPassDescriptorMaxDrawCount = @import("types.zig").RenderPassDescriptorMaxDrawCount;
pub const StencilFaceState = @import("types.zig").StencilFaceState;
pub const StorageTextureBindingLayout = @import("types.zig").StorageTextureBindingLayout;
pub const VertexAttribute = @import("types.zig").VertexAttribute;
pub const BlendState = @import("types.zig").BlendState;
pub const CompilationInfo = @import("types.zig").CompilationInfo;
pub const DepthStencilState = @import("types.zig").DepthStencilState;
pub const ImageCopyBuffer = @import("types.zig").ImageCopyBuffer;
pub const ImageCopyExternalTexture = @import("types.zig").ImageCopyExternalTexture;
pub const ImageCopyTexture = @import("types.zig").ImageCopyTexture;
pub const ProgrammableStageDescriptor = @import("types.zig").ProgrammableStageDescriptor;
pub const RenderPassColorAttachment = @import("types.zig").RenderPassColorAttachment;
pub const RequiredLimits = @import("types.zig").RequiredLimits;
pub const SupportedLimits = @import("types.zig").SupportedLimits;
pub const VertexBufferLayout = @import("types.zig").VertexBufferLayout;
pub const ColorTargetState = @import("types.zig").ColorTargetState;
pub const VertexState = @import("types.zig").VertexState;
pub const FragmentState = @import("types.zig").FragmentState;

const instance = @import("instance.zig");
const device = @import("device.zig");
const interface = @import("interface.zig");
const types = @import("types.zig");

pub const Impl = interface.Impl;
pub const StubInterface = interface.StubInterface;
pub const Export = interface.Export;
pub const Interface = interface.Interface;

pub inline fn createInstance(descriptor: ?*const instance.Instance.Descriptor) ?*instance.Instance {
    return Impl.createInstance(descriptor);
}

pub inline fn getProcAddress(_device: *device.Device, proc_name: [*:0]const u8) ?types.Proc {
    return Impl.getProcAddress(_device, proc_name);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
