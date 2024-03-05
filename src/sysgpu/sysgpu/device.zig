const std = @import("std");
const Adapter = @import("adapter.zig").Adapter;
const Queue = @import("queue.zig").Queue;
const BindGroup = @import("bind_group.zig").BindGroup;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const Buffer = @import("buffer.zig").Buffer;
const CommandEncoder = @import("command_encoder.zig").CommandEncoder;
const ComputePipeline = @import("compute_pipeline.zig").ComputePipeline;
const ExternalTexture = @import("external_texture.zig").ExternalTexture;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;
const QuerySet = @import("query_set.zig").QuerySet;
const RenderBundleEncoder = @import("render_bundle_encoder.zig").RenderBundleEncoder;
const RenderPipeline = @import("render_pipeline.zig").RenderPipeline;
const Sampler = @import("sampler.zig").Sampler;
const ShaderModule = @import("shader_module.zig").ShaderModule;
const Surface = @import("surface.zig").Surface;
const SwapChain = @import("swap_chain.zig").SwapChain;
const Texture = @import("texture.zig").Texture;
const ChainedStruct = @import("main.zig").ChainedStruct;
const FeatureName = @import("main.zig").FeatureName;
const RequiredLimits = @import("main.zig").RequiredLimits;
const SupportedLimits = @import("main.zig").SupportedLimits;
const ErrorType = @import("main.zig").ErrorType;
const ErrorFilter = @import("main.zig").ErrorFilter;
const LoggingType = @import("main.zig").LoggingType;
const CreatePipelineAsyncStatus = @import("main.zig").CreatePipelineAsyncStatus;
const LoggingCallback = @import("main.zig").LoggingCallback;
const ErrorCallback = @import("main.zig").ErrorCallback;
const CreateComputePipelineAsyncCallback = @import("main.zig").CreateComputePipelineAsyncCallback;
const CreateRenderPipelineAsyncCallback = @import("main.zig").CreateRenderPipelineAsyncCallback;
const Impl = @import("interface.zig").Impl;
const dawn = @import("dawn.zig");

pub const Device = opaque {
    pub const LostCallback = *const fn (
        reason: LostReason,
        message: [*:0]const u8,
        userdata: ?*anyopaque,
    ) callconv(.C) void;

    pub const LostReason = enum(u32) {
        undefined = 0x00000000,
        destroyed = 0x00000001,
    };

    pub const Descriptor = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            dawn_toggles_descriptor: *const dawn.TogglesDescriptor,
            dawn_cache_device_descriptor: *const dawn.CacheDeviceDescriptor,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        label: ?[*:0]const u8 = null,
        required_features_count: usize = 0,
        required_features: ?[*]const FeatureName = null,
        required_limits: ?*const RequiredLimits = null,
        default_queue: Queue.Descriptor = Queue.Descriptor{},
        device_lost_callback: LostCallback,
        device_lost_userdata: ?*anyopaque,

        /// Provides a slightly friendlier Zig API to initialize this structure.
        pub inline fn init(v: struct {
            next_in_chain: NextInChain = .{ .generic = null },
            label: ?[*:0]const u8 = null,
            required_features: ?[]const FeatureName = null,
            required_limits: ?*const RequiredLimits = null,
            default_queue: Queue.Descriptor = Queue.Descriptor{},
        }) Descriptor {
            return .{
                .next_in_chain = v.next_in_chain,
                .label = v.label,
                .required_features_count = if (v.required_features) |e| e.len else 0,
                .required_features = if (v.required_features) |e| e.ptr else null,
                .default_queue = v.default_queue,
            };
        }
    };

    pub inline fn createBindGroup(device: *Device, descriptor: *const BindGroup.Descriptor) *BindGroup {
        return Impl.deviceCreateBindGroup(device, descriptor);
    }

    pub inline fn createBindGroupLayout(device: *Device, descriptor: *const BindGroupLayout.Descriptor) *BindGroupLayout {
        return Impl.deviceCreateBindGroupLayout(device, descriptor);
    }

    pub inline fn createBuffer(device: *Device, descriptor: *const Buffer.Descriptor) *Buffer {
        return Impl.deviceCreateBuffer(device, descriptor);
    }

    pub inline fn createCommandEncoder(device: *Device, descriptor: ?*const CommandEncoder.Descriptor) *CommandEncoder {
        return Impl.deviceCreateCommandEncoder(device, descriptor);
    }

    pub inline fn createComputePipeline(device: *Device, descriptor: *const ComputePipeline.Descriptor) *ComputePipeline {
        return Impl.deviceCreateComputePipeline(device, descriptor);
    }

    pub inline fn createComputePipelineAsync(
        device: *Device,
        descriptor: *const ComputePipeline.Descriptor,
        context: anytype,
        comptime callback: fn (
            status: CreatePipelineAsyncStatus,
            compute_pipeline: *ComputePipeline,
            message: [*:0]const u8,
            ctx: @TypeOf(context),
        ) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn cCallback(
                status: CreatePipelineAsyncStatus,
                compute_pipeline: *ComputePipeline,
                message: [*:0]const u8,
                userdata: ?*anyopaque,
            ) callconv(.C) void {
                callback(
                    status,
                    compute_pipeline,
                    message,
                    if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))),
                );
            }
        };
        Impl.deviceCreateComputePipelineAsync(device, descriptor, Helper.cCallback, if (Context == void) null else context);
    }

    pub inline fn createErrorBuffer(device: *Device, descriptor: *const Buffer.Descriptor) *Buffer {
        return Impl.deviceCreateErrorBuffer(device, descriptor);
    }

    pub inline fn createErrorExternalTexture(device: *Device) *ExternalTexture {
        return Impl.deviceCreateErrorExternalTexture(device);
    }

    pub inline fn createErrorTexture(device: *Device, descriptor: *const Texture.Descriptor) *Texture {
        return Impl.deviceCreateErrorTexture(device, descriptor);
    }

    pub inline fn createExternalTexture(device: *Device, external_texture_descriptor: *const ExternalTexture.Descriptor) *ExternalTexture {
        return Impl.deviceCreateExternalTexture(device, external_texture_descriptor);
    }

    pub inline fn createPipelineLayout(device: *Device, pipeline_layout_descriptor: *const PipelineLayout.Descriptor) *PipelineLayout {
        return Impl.deviceCreatePipelineLayout(device, pipeline_layout_descriptor);
    }

    pub inline fn createQuerySet(device: *Device, descriptor: *const QuerySet.Descriptor) *QuerySet {
        return Impl.deviceCreateQuerySet(device, descriptor);
    }

    pub inline fn createRenderBundleEncoder(device: *Device, descriptor: *const RenderBundleEncoder.Descriptor) *RenderBundleEncoder {
        return Impl.deviceCreateRenderBundleEncoder(device, descriptor);
    }

    pub inline fn createRenderPipeline(device: *Device, descriptor: *const RenderPipeline.Descriptor) *RenderPipeline {
        return Impl.deviceCreateRenderPipeline(device, descriptor);
    }

    pub inline fn createRenderPipelineAsync(
        device: *Device,
        descriptor: *const RenderPipeline.Descriptor,
        context: anytype,
        comptime callback: fn (
            ctx: @TypeOf(context),
            status: CreatePipelineAsyncStatus,
            pipeline: *RenderPipeline,
            message: [*:0]const u8,
        ) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn cCallback(
                status: CreatePipelineAsyncStatus,
                pipeline: *RenderPipeline,
                message: [*:0]const u8,
                userdata: ?*anyopaque,
            ) callconv(.C) void {
                callback(
                    if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))),
                    status,
                    pipeline,
                    message,
                );
            }
        };
        Impl.deviceCreateRenderPipelineAsync(device, descriptor, Helper.cCallback, if (Context == void) null else context);
    }

    pub inline fn createSampler(device: *Device, descriptor: ?*const Sampler.Descriptor) *Sampler {
        return Impl.deviceCreateSampler(device, descriptor);
    }

    pub inline fn createShaderModule(device: *Device, descriptor: *const ShaderModule.Descriptor) *ShaderModule {
        return Impl.deviceCreateShaderModule(device, descriptor);
    }

    /// Helper to make createShaderModule invocations slightly nicer.
    pub inline fn createShaderModuleWGSL(
        device: *Device,
        label: ?[*:0]const u8,
        code: [*:0]const u8,
    ) *ShaderModule {
        return device.createShaderModule(&ShaderModule.Descriptor{
            .next_in_chain = .{ .wgsl_descriptor = &.{ .code = code } },
            .label = label,
        });
    }

    /// Helper to make createShaderModule invocations slightly nicer.
    pub inline fn createShaderModuleSpirV(
        device: *Device,
        label: ?[*:0]const u8,
        code: [*]const u32,
        code_size: u32,
    ) *ShaderModule {
        return device.createShaderModule(&ShaderModule.Descriptor{
            .next_in_chain = .{ .spirv_descriptor = &.{
                .code_size = code_size,
                .code = code,
            } },
            .label = label,
        });
    }

    /// Helper to make createShaderModule invocations slightly nicer.
    pub inline fn createShaderModuleHLSL(
        device: *Device,
        label: ?[*:0]const u8,
        code: []const u8,
    ) *ShaderModule {
        return device.createShaderModule(&ShaderModule.Descriptor{
            .next_in_chain = .{ .hlsl_descriptor = &.{
                .code = code.ptr,
                .code_size = code.len,
            } },
            .label = label,
        });
    }

    /// Helper to make createShaderModule invocations slightly nicer.
    pub inline fn createShaderModuleMSL(
        device: *Device,
        label: ?[*:0]const u8,
        code: []const u8,
    ) *ShaderModule {
        return device.createShaderModule(&ShaderModule.Descriptor{
            .next_in_chain = .{ .msl_descriptor = &.{
                .code = code.ptr,
                .code_size = code.len,
            } },
            .label = label,
        });
    }

    pub inline fn createSwapChain(device: *Device, surface: ?*Surface, descriptor: *const SwapChain.Descriptor) *SwapChain {
        return Impl.deviceCreateSwapChain(device, surface, descriptor);
    }

    pub inline fn createTexture(device: *Device, descriptor: *const Texture.Descriptor) *Texture {
        return Impl.deviceCreateTexture(device, descriptor);
    }

    pub inline fn destroy(device: *Device) void {
        Impl.deviceDestroy(device);
    }

    /// Call once with null to determine the array length, and again to fetch the feature list.
    ///
    /// Consider using the enumerateFeaturesOwned helper.
    pub inline fn enumerateFeatures(device: *Device, features: ?[*]FeatureName) usize {
        return Impl.deviceEnumerateFeatures(device, features);
    }

    /// Enumerates the adapter features, storing the result in an allocated slice which is owned by
    /// the caller.
    pub inline fn enumerateFeaturesOwned(device: *Device, allocator: std.mem.Allocator) ![]FeatureName {
        const count = device.enumerateFeatures(null);
        const data = try allocator.alloc(FeatureName, count);
        _ = device.enumerateFeatures(data.ptr);
        return data;
    }

    pub inline fn forceLoss(device: *Device, reason: LostReason, message: [*:0]const u8) void {
        return Impl.deviceForceLoss(device, reason, message);
    }

    pub inline fn getAdapter(device: *Device) *Adapter {
        return Impl.deviceGetAdapter(device);
    }

    pub inline fn getLimits(device: *Device, limits: *SupportedLimits) bool {
        return Impl.deviceGetLimits(device, limits);
    }

    pub inline fn getQueue(device: *Device) *Queue {
        return Impl.deviceGetQueue(device);
    }

    pub inline fn hasFeature(device: *Device, feature: FeatureName) bool {
        return Impl.deviceHasFeature(device, feature);
    }

    pub inline fn injectError(device: *Device, typ: ErrorType, message: [*:0]const u8) void {
        Impl.deviceInjectError(device, typ, message);
    }

    pub inline fn popErrorScope(
        device: *Device,
        context: anytype,
        comptime callback: fn (ctx: @TypeOf(context), typ: ErrorType, message: [*:0]const u8) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn cCallback(typ: ErrorType, message: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
                callback(if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))), typ, message);
            }
        };
        Impl.devicePopErrorScope(device, Helper.cCallback, if (Context == void) null else context);
    }

    pub inline fn pushErrorScope(device: *Device, filter: ErrorFilter) void {
        Impl.devicePushErrorScope(device, filter);
    }

    pub inline fn setDeviceLostCallback(
        device: *Device,
        context: anytype,
        comptime callback: ?fn (ctx: @TypeOf(context), reason: LostReason, message: [*:0]const u8) callconv(.Inline) void,
    ) void {
        if (callback) |cb| {
            const Context = @TypeOf(context);
            const Helper = struct {
                pub fn cCallback(reason: LostReason, message: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
                    cb(if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))), reason, message);
                }
            };
            Impl.deviceSetDeviceLostCallback(device, Helper.cCallback, if (Context == void) null else context);
        } else {
            Impl.deviceSetDeviceLostCallback(device, null, null);
        }
    }

    pub inline fn setLabel(device: *Device, label: [*:0]const u8) void {
        Impl.deviceSetLabel(device, label);
    }

    pub inline fn setLoggingCallback(
        device: *Device,
        context: anytype,
        comptime callback: ?fn (ctx: @TypeOf(context), typ: LoggingType, message: [*:0]const u8) callconv(.Inline) void,
    ) void {
        if (callback) |cb| {
            const Context = @TypeOf(context);
            const Helper = struct {
                pub fn cCallback(typ: LoggingType, message: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
                    cb(if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))), typ, message);
                }
            };
            Impl.deviceSetLoggingCallback(device, Helper.cCallback, if (Context == void) null else context);
        } else {
            Impl.deviceSetLoggingCallback(device, null, null);
        }
    }

    pub inline fn setUncapturedErrorCallback(
        device: *Device,
        context: anytype,
        comptime callback: ?fn (ctx: @TypeOf(context), typ: ErrorType, message: [*:0]const u8) callconv(.Inline) void,
    ) void {
        if (callback) |cb| {
            const Context = @TypeOf(context);
            const Helper = struct {
                pub fn cCallback(typ: ErrorType, message: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
                    cb(if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))), typ, message);
                }
            };
            Impl.deviceSetUncapturedErrorCallback(device, Helper.cCallback, if (Context == void) null else context);
        } else {
            Impl.deviceSetUncapturedErrorCallback(device, null, null);
        }
    }

    pub inline fn tick(device: *Device) void {
        Impl.deviceTick(device);
    }

    // Mach WebGPU extension. Supported with mach-gpu-dawn.
    //
    // When making Metal interop with other APIs, we need to be careful that QueueSubmit doesn't
    // mean that the operations will be visible to other APIs/Metal devices right away. macOS
    // does have a global queue of graphics operations, but the command buffers are inserted there
    // when they are "scheduled". Submitting other operations before the command buffer is
    // scheduled could lead to races in who gets scheduled first and incorrect rendering.
    pub inline fn machWaitForCommandsToBeScheduled(device: *Device) void {
        Impl.machDeviceWaitForCommandsToBeScheduled(device);
    }

    pub inline fn validateTextureDescriptor(device: *Device, descriptor: *const Texture.Descriptor) void {
        Impl.deviceVlidateTextureDescriptor(device, descriptor);
    }

    pub inline fn reference(device: *Device) void {
        Impl.deviceReference(device);
    }

    pub inline fn release(device: *Device) void {
        Impl.deviceRelease(device);
    }
};
