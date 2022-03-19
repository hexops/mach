//! A native webgpu.h implementation of the gpu.Interface
const std = @import("std");
const c = @import("c.zig").c;

const Interface = @import("Interface.zig");
const RequestAdapterOptions = Interface.RequestAdapterOptions;
const RequestAdapterErrorCode = Interface.RequestAdapterErrorCode;
const RequestAdapterError = Interface.RequestAdapterError;
const RequestAdapterCallback = Interface.RequestAdapterCallback;
const RequestAdapterResponse = Interface.RequestAdapterResponse;

const Adapter = @import("Adapter.zig");
const RequestDeviceErrorCode = Adapter.RequestDeviceErrorCode;
const RequestDeviceError = Adapter.RequestDeviceError;
const RequestDeviceCallback = Adapter.RequestDeviceCallback;
const RequestDeviceResponse = Adapter.RequestDeviceResponse;

const Limits = @import("data.zig").Limits;
const Color = @import("data.zig").Color;
const Extent3D = @import("data.zig").Extent3D;

const Device = @import("Device.zig");
const Surface = @import("Surface.zig");
const Queue = @import("Queue.zig");
const CommandBuffer = @import("CommandBuffer.zig");
const ShaderModule = @import("ShaderModule.zig");
const SwapChain = @import("SwapChain.zig");
const TextureView = @import("TextureView.zig");
const Texture = @import("Texture.zig");
const Sampler = @import("Sampler.zig");
const RenderPipeline = @import("RenderPipeline.zig");
const RenderPassEncoder = @import("RenderPassEncoder.zig");
const RenderBundleEncoder = @import("RenderBundleEncoder.zig");
const RenderBundle = @import("RenderBundle.zig");
const QuerySet = @import("QuerySet.zig");
const PipelineLayout = @import("PipelineLayout.zig");
const ExternalTexture = @import("ExternalTexture.zig");
const BindGroup = @import("BindGroup.zig");
const BindGroupLayout = @import("BindGroupLayout.zig");
const Buffer = @import("Buffer.zig");
const CommandEncoder = @import("CommandEncoder.zig");
const ComputePassEncoder = @import("ComputePassEncoder.zig");
const ComputePipeline = @import("ComputePipeline.zig");

const PresentMode = @import("enums.zig").PresentMode;
const IndexFormat = @import("enums.zig").IndexFormat;
const ErrorType = @import("enums.zig").ErrorType;
const ErrorFilter = @import("enums.zig").ErrorFilter;
const LoggingType = @import("enums.zig").LoggingType;
const Feature = @import("enums.zig").Feature;

const ImageCopyBuffer = @import("structs.zig").ImageCopyBuffer;
const ImageCopyTexture = @import("structs.zig").ImageCopyTexture;
const ErrorCallback = @import("structs.zig").ErrorCallback;
const LoggingCallback = @import("structs.zig").LoggingCallback;

const NativeInstance = @This();

/// The WGPUInstance that is wrapped by this native instance.
instance: c.WGPUInstance,

/// Wraps a native WGPUInstance to provide an implementation of the gpu.Interface.
pub fn wrap(instance: *anyopaque) NativeInstance {
    return .{ .instance = @ptrCast(c.WGPUInstance, instance) };
}

const interface_vtable = Interface.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            const native = @ptrCast(*NativeInstance, @alignCast(@alignOf(*NativeInstance), ptr));
            c.wgpuInstanceReference(native.instance);
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            const native = @ptrCast(*NativeInstance, @alignCast(@alignOf(*NativeInstance), ptr));
            c.wgpuInstanceRelease(native.instance);
        }
    }).release,
    .requestAdapter = (struct {
        pub fn requestAdapter(
            ptr: *anyopaque,
            options: *const RequestAdapterOptions,
            callback: *RequestAdapterCallback,
        ) void {
            const native = @ptrCast(*NativeInstance, @alignCast(@alignOf(*NativeInstance), ptr));

            const opt = c.WGPURequestAdapterOptions{
                .nextInChain = null,
                .compatibleSurface = if (options.compatible_surface) |surface| @ptrCast(c.WGPUSurface, surface.ptr) else null,
                .powerPreference = @enumToInt(options.power_preference),
                .forceFallbackAdapter = options.force_fallback_adapter,
            };

            const cCallback = (struct {
                pub fn cCallback(status: c.WGPURequestAdapterStatus, adapter: c.WGPUAdapter, message: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
                    const callback_info = @ptrCast(*RequestAdapterCallback, @alignCast(@alignOf(*RequestAdapterCallback), userdata.?));

                    // Store the response into a field on the native instance for later reading.
                    const response = if (status == c.WGPURequestAdapterStatus_Success) RequestAdapterResponse{
                        .adapter = wrapAdapter(adapter.?),
                    } else RequestAdapterResponse{
                        .err = Interface.RequestAdapterError{
                            .message = std.mem.span(message),
                            .code = switch (status) {
                                c.WGPURequestAdapterStatus_Unavailable => RequestAdapterErrorCode.Unavailable,
                                c.WGPURequestAdapterStatus_Error => RequestAdapterErrorCode.Error,
                                c.WGPURequestAdapterStatus_Unknown => RequestAdapterErrorCode.Unknown,
                                else => unreachable,
                            },
                        },
                    };

                    callback_info.type_erased_callback(callback_info.type_erased_ctx, response);
                }
            }).cCallback;

            c.wgpuInstanceRequestAdapter(native.instance, &opt, cCallback, callback);
        }
    }).requestAdapter,
};

/// Returns the gpu.Interface for interacting with this native instance.
pub fn interface(native: *NativeInstance) Interface {
    return .{
        .ptr = native,
        .vtable = &interface_vtable,
    };
}

pub fn createSurface(native: *const NativeInstance, descriptor: *const Surface.Descriptor) Surface {
    const surface = switch (descriptor.*) {
        .metal_layer => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromMetalLayer = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromMetalLayer;
            desc.layer = src.layer;
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| l else null,
            });
        },
        .windows_hwnd => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromWindowsHWND = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromWindowsHWND;
            desc.hinstance = src.hinstance;
            desc.hwnd = src.hwnd;
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| l else null,
            });
        },
        .windows_core_window => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromWindowsCoreWindow = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromWindowsCoreWindow;
            desc.coreWindow = src.core_window;
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| l else null,
            });
        },
        .windows_swap_chain_panel => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromWindowsSwapChainPanel = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromWindowsSwapChainPanel;
            desc.swapChainPanel = src.swap_chain_panel;
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| l else null,
            });
        },
        .xlib => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromXlibWindow = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromXlibWindow;
            desc.display = src.display;
            desc.window = src.window;
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| l else null,
            });
        },
        .canvas_html_selector => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromCanvasHTMLSelector = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromCanvasHTMLSelector;
            desc.selector = src.selector;
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| l else null,
            });
        },
    };

    return Surface{
        .ptr = surface.?,
        .vtable = &surface_vtable,
    };
}

const surface_vtable = Surface.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuSurfaceReference(@ptrCast(c.WGPUSurface, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuSurfaceRelease(@ptrCast(c.WGPUSurface, ptr));
        }
    }).release,
};

fn wrapAdapter(adapter: c.WGPUAdapter) Adapter {
    var c_props: c.WGPUAdapterProperties = undefined;
    c.wgpuAdapterGetProperties(adapter, &c_props);
    const properties = Adapter.Properties{
        .vendor_id = c_props.vendorID,
        .device_id = c_props.deviceID,
        .name = std.mem.span(c_props.name),
        .driver_description = std.mem.span(c_props.driverDescription),
        .adapter_type = @intToEnum(Adapter.Type, c_props.adapterType),
        .backend_type = @intToEnum(Adapter.BackendType, c_props.backendType),
    };

    var supported_limits: c.WGPUSupportedLimits = undefined;
    if (!c.wgpuAdapterGetLimits(adapter.?, &supported_limits)) @panic("failed to get adapter limits (this is a bug in mach/gpu)");

    var wrapped = Adapter{
        .features = undefined,
        .limits = @bitCast(Limits, supported_limits.limits),
        .properties = properties,

        // TODO: why is fallback not queryable on Dawn?
        .fallback = false,

        .ptr = adapter.?,
        .vtable = &adapter_vtable,
    };

    const features_len = c.wgpuAdapterEnumerateFeatures(adapter.?, @ptrCast(*c.WGPUFeatureName, &wrapped._features[0]));
    wrapped.features = wrapped._features[0..features_len];
    return wrapped;
}

const adapter_vtable = Adapter.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuAdapterReference(@ptrCast(c.WGPUAdapter, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuAdapterRelease(@ptrCast(c.WGPUAdapter, ptr));
        }
    }).release,
    .requestDevice = (struct {
        pub fn requestDevice(
            ptr: *anyopaque,
            descriptor: *const Device.Descriptor,
            callback: *RequestDeviceCallback,
        ) void {
            const adapter = @ptrCast(c.WGPUAdapter, @alignCast(@alignOf(c.WGPUAdapter), ptr));

            const required_limits = if (descriptor.required_limits) |l| c.WGPURequiredLimits{
                .nextInChain = null,
                .limits = @bitCast(c.WGPULimits, l),
            } else null;

            const desc = c.WGPUDeviceDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
                .requiredFeaturesCount = if (descriptor.required_features) |f| @intCast(u32, f.len) else 0,
                .requiredFeatures = if (descriptor.required_features) |f| @ptrCast([*c]const c_uint, &f[0]) else null,
                .requiredLimits = if (required_limits) |*l| l else null,
            };

            const cCallback = (struct {
                pub fn cCallback(status: c.WGPURequestDeviceStatus, device: c.WGPUDevice, message: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
                    const callback_info = @ptrCast(*RequestDeviceCallback, @alignCast(@alignOf(*RequestDeviceCallback), userdata.?));

                    const response = if (status == c.WGPURequestDeviceStatus_Success) RequestDeviceResponse{
                        .device = wrapDevice(device.?),
                    } else RequestDeviceResponse{
                        .err = Adapter.RequestDeviceError{
                            .message = std.mem.span(message),
                            .code = switch (status) {
                                c.WGPURequestDeviceStatus_Error => RequestDeviceErrorCode.Error,
                                c.WGPURequestDeviceStatus_Unknown => RequestDeviceErrorCode.Unknown,
                                else => unreachable,
                            },
                        },
                    };

                    callback_info.type_erased_callback(callback_info.type_erased_ctx, response);
                }
            }).cCallback;

            c.wgpuAdapterRequestDevice(adapter, &desc, cCallback, callback);
        }
    }).requestDevice,
};

fn wrapDevice(device: c.WGPUDevice) Device {
    var supported_limits: c.WGPUSupportedLimits = undefined;
    if (!c.wgpuDeviceGetLimits(device.?, &supported_limits)) @panic("failed to get device limits (this is a bug in mach/gpu)");

    var wrapped = Device{
        .features = undefined,
        .limits = @bitCast(Limits, supported_limits.limits),
        .ptr = device.?,
        .vtable = &device_vtable,
    };

    const features_len = c.wgpuDeviceEnumerateFeatures(device.?, @ptrCast(*c.WGPUFeatureName, &wrapped._features[0]));
    wrapped.features = wrapped._features[0..features_len];
    return wrapped;
}

const device_vtable = Device.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuDeviceReference(@ptrCast(c.WGPUDevice, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuDeviceRelease(@ptrCast(c.WGPUDevice, ptr));
        }
    }).release,
    .getQueue = (struct {
        pub fn getQueue(ptr: *anyopaque) Queue {
            return wrapQueue(c.wgpuDeviceGetQueue(@ptrCast(c.WGPUDevice, ptr)));
        }
    }).getQueue,
    .injectError = (struct {
        pub fn injectError(ptr: *anyopaque, typ: ErrorType, message: [*:0]const u8) void {
            c.wgpuDeviceInjectError(@ptrCast(c.WGPUDevice, ptr), @enumToInt(typ), message);
        }
    }).injectError,
    .loseForTesting = (struct {
        pub fn loseForTesting(ptr: *anyopaque) void {
            c.wgpuDeviceLoseForTesting(@ptrCast(c.WGPUDevice, ptr));
        }
    }).loseForTesting,
    .popErrorScope = (struct {
        pub fn popErrorScope(ptr: *anyopaque, callback: *ErrorCallback) bool {
            const cCallback = (struct {
                pub fn cCallback(
                    typ: c.WGPUErrorType,
                    message: [*c]const u8,
                    userdata: ?*anyopaque,
                ) callconv(.C) void {
                    const callback_info = @ptrCast(*ErrorCallback, @alignCast(@alignOf(*ErrorCallback), userdata));
                    callback_info.type_erased_callback(
                        callback_info.type_erased_ctx,
                        @intToEnum(ErrorType, typ),
                        std.mem.span(message),
                    );
                }
            }).cCallback;

            return c.wgpuDevicePopErrorScope(
                @ptrCast(c.WGPUDevice, ptr),
                cCallback,
                callback,
            );
        }
    }).popErrorScope,
    .createBindGroup = (struct {
        pub fn createBindGroup(ptr: *anyopaque, descriptor: *const BindGroup.Descriptor) BindGroup {
            var few_entries: [16]c.WGPUBindGroupEntry = undefined;
            const entries = if (descriptor.entries.len <= 8) blk: {
                for (descriptor.entries) |entry, i| {
                    few_entries[i] = c.WGPUBindGroupEntry{
                        .nextInChain = null,
                        .binding = entry.binding,
                        .buffer = @ptrCast(c.WGPUBuffer, entry.buffer.ptr),
                        .offset = entry.offset,
                        .size = entry.size,
                        .sampler = @ptrCast(c.WGPUSampler, entry.sampler.ptr),
                        .textureView = @ptrCast(c.WGPUTextureView, entry.texture_view.ptr),
                    };
                }
                break :blk few_entries[0..descriptor.entries.len];
            } else blk: {
                const mem = std.heap.page_allocator.alloc(c.WGPUBindGroupEntry, descriptor.entries.len) catch unreachable;
                for (descriptor.entries) |entry, i| {
                    mem[i] = c.WGPUBindGroupEntry{
                        .nextInChain = null,
                        .binding = entry.binding,
                        .buffer = @ptrCast(c.WGPUBuffer, entry.buffer.ptr),
                        .offset = entry.offset,
                        .size = entry.size,
                        .sampler = @ptrCast(c.WGPUSampler, entry.sampler.ptr),
                        .textureView = @ptrCast(c.WGPUTextureView, entry.texture_view.ptr),
                    };
                }
                break :blk mem;
            };
            defer if (entries.len > 8) std.heap.page_allocator.free(entries);

            const desc = c.WGPUBindGroupDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
                .layout = @ptrCast(c.WGPUBindGroupLayout, descriptor.layout.ptr),
                .entryCount = @intCast(u32, entries.len),
                .entries = &entries[0],
            };

            return wrapBindGroup(c.wgpuDeviceCreateBindGroup(@ptrCast(c.WGPUDevice, ptr), &desc));
        }
    }).createBindGroup,
    .pushErrorScope = (struct {
        pub fn pushErrorScope(ptr: *anyopaque, filter: ErrorFilter) void {
            c.wgpuDevicePushErrorScope(@ptrCast(c.WGPUDevice, ptr), @enumToInt(filter));
        }
    }).pushErrorScope,
    .setLostCallback = (struct {
        pub fn setLostCallback(ptr: *anyopaque, callback: *Device.LostCallback) void {
            const cCallback = (struct {
                pub fn cCallback(
                    reason: c.WGPUDeviceLostReason,
                    message: [*c]const u8,
                    userdata: ?*anyopaque,
                ) callconv(.C) void {
                    const callback_info = @ptrCast(*Device.LostCallback, @alignCast(@alignOf(*Device.LostCallback), userdata));
                    callback_info.type_erased_callback(
                        callback_info.type_erased_ctx,
                        @intToEnum(Device.LostReason, reason),
                        std.mem.span(message),
                    );
                }
            }).cCallback;

            c.wgpuDeviceSetDeviceLostCallback(
                @ptrCast(c.WGPUDevice, ptr),
                cCallback,
                callback,
            );
        }
    }).setLostCallback,
    .createBindGroupLayout = (struct {
        pub fn createBindGroupLayout(ptr: *anyopaque, descriptor: *const BindGroupLayout.Descriptor) BindGroupLayout {
            const desc = c.WGPUBindGroupLayoutDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
                .entryCount = @intCast(u32, descriptor.entries.len),
                .entries = @ptrCast(*const c.WGPUBindGroupLayoutEntry, &descriptor.entries[0]),
            };
            return wrapBindGroupLayout(c.wgpuDeviceCreateBindGroupLayout(@ptrCast(c.WGPUDevice, ptr), &desc));
        }
    }).createBindGroupLayout,
    .createSampler = (struct {
        pub fn createSampler(ptr: *anyopaque, descriptor: *const Sampler.Descriptor) Sampler {
            return wrapSampler(c.wgpuDeviceCreateSampler(
                @ptrCast(c.WGPUDevice, ptr),
                @ptrCast(*const c.WGPUSamplerDescriptor, descriptor),
            ));
        }
    }).createSampler,
    .createShaderModule = (struct {
        pub fn createShaderModule(ptr: *anyopaque, descriptor: *const ShaderModule.Descriptor) ShaderModule {
            switch (descriptor.code) {
                .wgsl => |wgsl| {
                    const wgsl_desc = c.WGPUShaderModuleWGSLDescriptor{
                        .chain = c.WGPUChainedStruct{
                            .next = null,
                            .sType = c.WGPUSType_ShaderModuleWGSLDescriptor,
                        },
                        .source = wgsl,
                    };
                    const desc = c.WGPUShaderModuleDescriptor{
                        .nextInChain = @ptrCast(*const c.WGPUChainedStruct, &wgsl_desc),
                        .label = if (descriptor.label) |l| l else null,
                    };
                    return wrapShaderModule(c.wgpuDeviceCreateShaderModule(@ptrCast(c.WGPUDevice, ptr), &desc));
                },
                .spirv => |spirv| {
                    const spirv_desc = c.WGPUShaderModuleSPIRVDescriptor{
                        .chain = c.WGPUChainedStruct{
                            .next = null,
                            .sType = c.WGPUSType_ShaderModuleSPIRVDescriptor,
                        },
                        .code = @ptrCast([*c]const u32, &spirv[0]),
                        .codeSize = @intCast(u32, spirv.len),
                    };
                    const desc = c.WGPUShaderModuleDescriptor{
                        .nextInChain = @ptrCast(*const c.WGPUChainedStruct, &spirv_desc),
                        .label = if (descriptor.label) |l| l else null,
                    };
                    return wrapShaderModule(c.wgpuDeviceCreateShaderModule(@ptrCast(c.WGPUDevice, ptr), &desc));
                },
            }
        }
    }).createShaderModule,
    .nativeCreateSwapChain = (struct {
        pub fn nativeCreateSwapChain(ptr: *anyopaque, surface: ?Surface, descriptor: *const SwapChain.Descriptor) SwapChain {
            const desc = c.WGPUSwapChainDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
                .usage = @enumToInt(descriptor.usage),
                .format = @enumToInt(descriptor.format),
                .width = descriptor.width,
                .height = descriptor.height,
                .presentMode = @enumToInt(descriptor.present_mode),
                .implementation = descriptor.implementation,
            };
            return wrapSwapChain(c.wgpuDeviceCreateSwapChain(
                @ptrCast(c.WGPUDevice, ptr),
                if (surface) |surf| @ptrCast(c.WGPUSurface, surf.ptr) else null,
                &desc,
            ));
        }
    }).nativeCreateSwapChain,
    .createTexture = (struct {
        pub fn createTexture(ptr: *anyopaque, descriptor: *const Texture.Descriptor) Texture {
            return wrapTexture(c.wgpuDeviceCreateTexture(
                @ptrCast(c.WGPUDevice, ptr),
                @ptrCast(*const c.WGPUTextureDescriptor, descriptor),
            ));
        }
    }).createTexture,
    .destroy = (struct {
        pub fn destroy(ptr: *anyopaque) void {
            c.wgpuDeviceDestroy(@ptrCast(c.WGPUDevice, ptr));
        }
    }).destroy,
    .createBuffer = (struct {
        pub fn createBuffer(ptr: *anyopaque, descriptor: *const Buffer.Descriptor) Buffer {
            return wrapBuffer(c.wgpuDeviceCreateBuffer(
                @ptrCast(c.WGPUDevice, ptr),
                @ptrCast(*const c.WGPUBufferDescriptor, descriptor),
            ));
        }
    }).createBuffer,
    .createCommandEncoder = (struct {
        pub fn createCommandEncoder(ptr: *anyopaque, descriptor: ?*const CommandEncoder.Descriptor) CommandEncoder {
            const desc: ?*c.WGPUCommandEncoderDescriptor = if (descriptor) |d| &.{
                .nextInChain = null,
                .label = if (d.label) |l| l else "",
            } else null;
            return wrapCommandEncoder(c.wgpuDeviceCreateCommandEncoder(@ptrCast(c.WGPUDevice, ptr), desc));
        }
    }).createCommandEncoder,
    .createComputePipeline = (struct {
        pub fn createComputePipeline(
            ptr: *anyopaque,
            descriptor: *const ComputePipeline.Descriptor,
        ) ComputePipeline {
            const desc = convertComputePipelineDescriptor(descriptor);

            return wrapComputePipeline(c.wgpuDeviceCreateComputePipeline(
                @ptrCast(c.WGPUDevice, ptr),
                &desc,
            ));
        }
    }).createComputePipeline,
    .createComputePipelineAsync = (struct {
        pub fn createComputePipelineAsync(
            ptr: *anyopaque,
            descriptor: *const ComputePipeline.Descriptor,
            callback: *ComputePipeline.CreateCallback,
        ) void {
            const desc = convertComputePipelineDescriptor(descriptor);

            const cCallback = (struct {
                pub fn cCallback(
                    status: c.WGPUCreatePipelineAsyncStatus,
                    pipeline: c.WGPUComputePipeline,
                    message: [*c]const u8,
                    userdata: ?*anyopaque,
                ) callconv(.C) void {
                    const callback_info = @ptrCast(*ComputePipeline.CreateCallback, @alignCast(@alignOf(*ComputePipeline.CreateCallback), userdata));
                    callback_info.type_erased_callback(
                        callback_info.type_erased_ctx,
                        @intToEnum(ComputePipeline.CreateStatus, status),
                        wrapComputePipeline(pipeline),
                        std.mem.span(message),
                    );
                }
            }).cCallback;

            c.wgpuDeviceCreateComputePipelineAsync(
                @ptrCast(c.WGPUDevice, ptr),
                &desc,
                cCallback,
                callback,
            );
        }
    }).createComputePipelineAsync,
    .createErrorBuffer = (struct {
        pub fn createErrorBuffer(ptr: *anyopaque) Buffer {
            return wrapBuffer(c.wgpuDeviceCreateErrorBuffer(
                @ptrCast(c.WGPUDevice, ptr),
            ));
        }
    }).createErrorBuffer,
    .createExternalTexture = (struct {
        pub fn createExternalTexture(ptr: *anyopaque, descriptor: *const ExternalTexture.Descriptor) ExternalTexture {
            const desc = c.WGPUExternalTextureDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
                .plane0 = @ptrCast(c.WGPUTextureView, descriptor.plane0.ptr),
                .plane1 = @ptrCast(c.WGPUTextureView, descriptor.plane1.ptr),
                .colorSpace = @enumToInt(descriptor.color_space),
            };
            return wrapExternalTexture(c.wgpuDeviceCreateExternalTexture(@ptrCast(c.WGPUDevice, ptr), &desc));
        }
    }).createExternalTexture,
    .createPipelineLayout = (struct {
        pub fn createPipelineLayout(ptr: *anyopaque, descriptor: *const PipelineLayout.Descriptor) PipelineLayout {
            var few_bind_group_layouts: [16]c.WGPUBindGroupLayout = undefined;
            const bind_group_layouts = if (descriptor.bind_group_layouts.len <= 16) blk: {
                for (descriptor.bind_group_layouts) |layout, i| {
                    few_bind_group_layouts[i] = @ptrCast(c.WGPUBindGroupLayout, layout.ptr);
                }
                break :blk few_bind_group_layouts[0..descriptor.bind_group_layouts.len];
            } else blk: {
                const mem = std.heap.page_allocator.alloc(c.WGPUBindGroupLayout, descriptor.bind_group_layouts.len) catch unreachable;
                for (descriptor.bind_group_layouts) |layout, i| {
                    mem[i] = @ptrCast(c.WGPUBindGroupLayout, layout.ptr);
                }
                break :blk mem;
            };
            defer if (descriptor.bind_group_layouts.len > 16) std.heap.page_allocator.free(descriptor.bind_group_layouts);

            const desc = c.WGPUPipelineLayoutDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
                .bindGroupLayoutCount = @intCast(u32, bind_group_layouts.len),
                .bindGroupLayouts = &bind_group_layouts[0],
            };
            return wrapPipelineLayout(c.wgpuDeviceCreatePipelineLayout(@ptrCast(c.WGPUDevice, ptr), &desc));
        }
    }).createPipelineLayout,
    .createQuerySet = (struct {
        pub fn createQuerySet(ptr: *anyopaque, descriptor: *const QuerySet.Descriptor) QuerySet {
            const desc = c.WGPUQuerySetDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
                .type = @enumToInt(descriptor.type),
                .count = descriptor.count,
                .pipelineStatistics = @ptrCast(*const c.WGPUPipelineStatisticName, &descriptor.pipeline_statistics[0]),
                .pipelineStatisticsCount = @intCast(u32, descriptor.pipeline_statistics.len),
            };
            return wrapQuerySet(c.wgpuDeviceCreateQuerySet(@ptrCast(c.WGPUDevice, ptr), &desc));
        }
    }).createQuerySet,
    .createRenderBundleEncoder = (struct {
        pub fn createRenderBundleEncoder(ptr: *anyopaque, descriptor: *const RenderBundleEncoder.Descriptor) RenderBundleEncoder {
            const desc = c.WGPURenderBundleEncoderDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
                .colorFormatsCount = @intCast(u32, descriptor.color_formats.len),
                .colorFormats = @ptrCast(*const c.WGPUTextureFormat, &descriptor.color_formats[0]),
                .depthStencilFormat = @enumToInt(descriptor.depth_stencil_format),
                .sampleCount = descriptor.sample_count,
                .depthReadOnly = descriptor.depth_read_only,
                .stencilReadOnly = descriptor.stencil_read_only,
            };
            return wrapRenderBundleEncoder(c.wgpuDeviceCreateRenderBundleEncoder(@ptrCast(c.WGPUDevice, ptr), &desc));
        }
    }).createRenderBundleEncoder,
    .createRenderPipeline = (struct {
        pub fn createRenderPipeline(ptr: *anyopaque, descriptor: *const RenderPipeline.Descriptor) RenderPipeline {
            var tmp_depth_stencil: c.WGPUDepthStencilState = undefined;
            var tmp_fragment_state: c.WGPUFragmentState = undefined;
            const desc = convertRenderPipelineDescriptor(descriptor, &tmp_depth_stencil, &tmp_fragment_state);
            return wrapRenderPipeline(c.wgpuDeviceCreateRenderPipeline(@ptrCast(c.WGPUDevice, ptr), &desc));
        }
    }).createRenderPipeline,
    .createRenderPipelineAsync = (struct {
        pub fn createRenderPipelineAsync(
            ptr: *anyopaque,
            descriptor: *const RenderPipeline.Descriptor,
            callback: *RenderPipeline.CreateCallback,
        ) void {
            var tmp_depth_stencil: c.WGPUDepthStencilState = undefined;
            var tmp_fragment_state: c.WGPUFragmentState = undefined;
            const desc = convertRenderPipelineDescriptor(descriptor, &tmp_depth_stencil, &tmp_fragment_state);

            const cCallback = (struct {
                pub fn cCallback(
                    status: c.WGPUCreatePipelineAsyncStatus,
                    pipeline: c.WGPURenderPipeline,
                    message: [*c]const u8,
                    userdata: ?*anyopaque,
                ) callconv(.C) void {
                    const callback_info = @ptrCast(*RenderPipeline.CreateCallback, @alignCast(@alignOf(*RenderPipeline.CreateCallback), userdata));
                    callback_info.type_erased_callback(
                        callback_info.type_erased_ctx,
                        @intToEnum(RenderPipeline.CreateStatus, status),
                        wrapRenderPipeline(pipeline),
                        std.mem.span(message),
                    );
                }
            }).cCallback;

            c.wgpuDeviceCreateRenderPipelineAsync(
                @ptrCast(c.WGPUDevice, ptr),
                &desc,
                cCallback,
                callback,
            );
        }
    }).createRenderPipelineAsync,
    .setUncapturedErrorCallback = (struct {
        pub fn setUncapturedErrorCallback(
            ptr: *anyopaque,
            callback: *ErrorCallback,
        ) void {
            const cCallback = (struct {
                pub fn cCallback(
                    typ: c.WGPUErrorType,
                    message: [*c]const u8,
                    userdata: ?*anyopaque,
                ) callconv(.C) void {
                    const callback_info = @ptrCast(*ErrorCallback, @alignCast(@alignOf(*ErrorCallback), userdata));
                    callback_info.type_erased_callback(
                        callback_info.type_erased_ctx,
                        @intToEnum(ErrorType, typ),
                        std.mem.span(message),
                    );
                }
            }).cCallback;

            return c.wgpuDeviceSetUncapturedErrorCallback(
                @ptrCast(c.WGPUDevice, ptr),
                cCallback,
                callback,
            );
        }
    }).setUncapturedErrorCallback,
    .setLoggingCallback = (struct {
        pub fn setLoggingCallback(
            ptr: *anyopaque,
            callback: *LoggingCallback,
        ) void {
            const cCallback = (struct {
                pub fn cCallback(
                    typ: c.WGPULoggingType,
                    message: [*c]const u8,
                    userdata: ?*anyopaque,
                ) callconv(.C) void {
                    const callback_info = @ptrCast(*LoggingCallback, @alignCast(@alignOf(*LoggingCallback), userdata));
                    callback_info.type_erased_callback(
                        callback_info.type_erased_ctx,
                        @intToEnum(LoggingType, typ),
                        std.mem.span(message),
                    );
                }
            }).cCallback;

            return c.wgpuDeviceSetLoggingCallback(
                @ptrCast(c.WGPUDevice, ptr),
                cCallback,
                callback,
            );
        }
    }).setLoggingCallback,
    .tick = (struct {
        pub fn tick(ptr: *anyopaque) void {
            c.wgpuDeviceTick(@ptrCast(c.WGPUDevice, ptr));
        }
    }.tick),
};

inline fn convertComputePipelineDescriptor(descriptor: *const ComputePipeline.Descriptor) c.WGPUComputePipelineDescriptor {
    return .{
        .nextInChain = null,
        .label = if (descriptor.label) |l| l else null,
        .layout = @ptrCast(c.WGPUPipelineLayout, descriptor.layout.ptr),
        .compute = c.WGPUProgrammableStageDescriptor{
            .nextInChain = null,
            .module = @ptrCast(c.WGPUShaderModule, descriptor.compute.module.ptr),
            .entryPoint = descriptor.compute.entry_point,
            .constantCount = if (descriptor.compute.constants) |v| @intCast(u32, v.len) else 0,
            .constants = if (descriptor.compute.constants) |v| @ptrCast(*const c.WGPUConstantEntry, &v[0]) else null,
        },
    };
}

inline fn convertRenderPipelineDescriptor(
    d: *const RenderPipeline.Descriptor,
    tmp_depth_stencil: *c.WGPUDepthStencilState,
    tmp_fragment_state: *c.WGPUFragmentState,
) c.WGPURenderPipelineDescriptor {
    if (d.depth_stencil) |ds| {
        tmp_depth_stencil.* = c.WGPUDepthStencilState{
            .nextInChain = null,
            .format = @enumToInt(ds.format),
            .depthWriteEnabled = ds.depth_write_enabled,
            .depthCompare = @enumToInt(ds.depth_compare),
            .stencilFront = @bitCast(c.WGPUStencilFaceState, ds.stencil_front),
            .stencilBack = @bitCast(c.WGPUStencilFaceState, ds.stencil_back),
            .stencilReadMask = ds.stencil_read_mask,
            .stencilWriteMask = ds.stencil_write_mask,
            .depthBias = ds.depth_bias,
            .depthBiasSlopeScale = ds.depth_bias_slope_scale,
            .depthBiasClamp = ds.depth_bias_clamp,
        };
    }

    tmp_fragment_state.* = c.WGPUFragmentState{
        .nextInChain = null,
        .module = @ptrCast(c.WGPUShaderModule, d.fragment.module.ptr),
        .entryPoint = d.vertex.entry_point,
        .constantCount = if (d.fragment.constants) |v| @intCast(u32, v.len) else 0,
        .constants = if (d.fragment.constants) |v| @ptrCast(*const c.WGPUConstantEntry, &v[0]) else null,
        .targetCount = if (d.fragment.targets) |v| @intCast(u32, v.len) else 0,
        .targets = if (d.fragment.targets) |v| @ptrCast(*const c.WGPUColorTargetState, &v[0]) else null,
    };

    return c.WGPURenderPipelineDescriptor{
        .nextInChain = null,
        .label = if (d.label) |l| l else null,
        .layout = if (d.layout) |v| @ptrCast(c.WGPUPipelineLayout, v.ptr) else null,
        .vertex = c.WGPUVertexState{
            .nextInChain = null,
            .module = @ptrCast(c.WGPUShaderModule, d.vertex.module.ptr),
            .entryPoint = d.vertex.entry_point,
            .constantCount = if (d.vertex.constants) |v| @intCast(u32, v.len) else 0,
            .constants = if (d.vertex.constants) |v| @ptrCast(*const c.WGPUConstantEntry, &v[0]) else null,
            .bufferCount = if (d.vertex.buffers) |v| @intCast(u32, v.len) else 0,
            .buffers = if (d.vertex.buffers) |v| @ptrCast(*const c.WGPUVertexBufferLayout, &v[0]) else null,
        },
        .primitive = c.WGPUPrimitiveState{
            .nextInChain = null,
            .topology = @enumToInt(d.primitive.topology),
            .stripIndexFormat = @enumToInt(d.primitive.strip_index_format),
            .frontFace = @enumToInt(d.primitive.front_face),
            .cullMode = @enumToInt(d.primitive.cull_mode),
        },
        .depthStencil = if (d.depth_stencil != null) tmp_depth_stencil else null,
        .multisample = c.WGPUMultisampleState{
            .nextInChain = null,
            .count = d.multisample.count,
            .mask = d.multisample.mask,
            .alphaToCoverageEnabled = d.multisample.alpha_to_coverage_enabled,
        },
        .fragment = tmp_fragment_state,
    };
}

fn wrapQueue(queue: c.WGPUQueue) Queue {
    return .{
        .ptr = queue.?,
        .vtable = &queue_vtable,
    };
}

const queue_vtable = Queue.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuQueueReference(@ptrCast(c.WGPUQueue, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuQueueRelease(@ptrCast(c.WGPUQueue, ptr));
        }
    }).release,
    .submit = (struct {
        pub fn submit(queue: Queue, cmds: []const CommandBuffer) void {
            const wgpu_queue = @ptrCast(c.WGPUQueue, queue.ptr);

            if (queue.on_submitted_work_done) |on_submitted_work_done| {
                // Note: signalValue is not available in the web API, and it's usage is undocumented
                // kainino says "It's basically reserved for future use, though it's been suggested
                // to remove it instead"
                const signal_value: u64 = 0;

                const cCallback = (struct {
                    pub fn cCallback(status: c.WGPUQueueWorkDoneStatus, userdata: ?*anyopaque) callconv(.C) void {
                        const callback_info = @ptrCast(*Queue.WorkDoneCallback, @alignCast(@alignOf(*Queue.WorkDoneCallback), userdata));
                        callback_info.type_erased_callback(
                            callback_info.type_erased_ctx,
                            @intToEnum(Queue.WorkDoneStatus, status),
                        );
                    }
                }).cCallback;

                var mut_on_submitted_work_done = on_submitted_work_done;
                c.wgpuQueueOnSubmittedWorkDone(wgpu_queue, signal_value, cCallback, &mut_on_submitted_work_done);
            }

            var few_commands: [16]c.WGPUCommandBuffer = undefined;
            const commands = if (cmds.len <= 16) blk: {
                for (cmds) |cmd, i| {
                    few_commands[i] = @ptrCast(c.WGPUCommandBuffer, cmd.ptr);
                }
                break :blk few_commands[0..cmds.len];
            } else blk: {
                const mem = std.heap.page_allocator.alloc(c.WGPUCommandBuffer, cmds.len) catch unreachable;
                for (cmds) |cmd, i| {
                    mem[i] = @ptrCast(c.WGPUCommandBuffer, cmd.ptr);
                }
                break :blk mem;
            };
            defer if (cmds.len > 16) std.heap.page_allocator.free(cmds);

            c.wgpuQueueSubmit(
                wgpu_queue,
                @intCast(u32, commands.len),
                @ptrCast(*c.WGPUCommandBuffer, &commands[0]),
            );
        }
    }).submit,
};

fn wrapShaderModule(shader_module: c.WGPUShaderModule) ShaderModule {
    return .{
        .ptr = shader_module.?,
        .vtable = &shader_module_vtable,
    };
}

const shader_module_vtable = ShaderModule.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuShaderModuleReference(@ptrCast(c.WGPUShaderModule, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuShaderModuleRelease(@ptrCast(c.WGPUShaderModule, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuShaderModuleSetLabel(@ptrCast(c.WGPUShaderModule, ptr), label);
        }
    }).setLabel,
    .getCompilationInfo = (struct {
        pub fn getCompilationInfo(ptr: *anyopaque, callback: *ShaderModule.CompilationInfoCallback) void {
            const cCallback = (struct {
                pub fn cCallback(status: c.WGPUCompilationInfoRequestStatus, info: [*c]const c.WGPUCompilationInfo, userdata: ?*anyopaque) callconv(.C) void {
                    const callback_info = @ptrCast(*ShaderModule.CompilationInfoCallback, @alignCast(@alignOf(*ShaderModule.CompilationInfoCallback), userdata.?));

                    callback_info.type_erased_callback(
                        callback_info.type_erased_ctx,
                        @intToEnum(ShaderModule.CompilationInfoRequestStatus, status),
                        &ShaderModule.CompilationInfo{
                            .messages = @bitCast([]const ShaderModule.CompilationMessage, info[0].messages[0..info[0].messageCount]),
                        },
                    );
                }
            }).cCallback;

            c.wgpuShaderModuleGetCompilationInfo(@ptrCast(c.WGPUShaderModule, ptr), cCallback, callback);
        }
    }).getCompilationInfo,
};

fn wrapSwapChain(swap_chain: c.WGPUSwapChain) SwapChain {
    return .{
        .ptr = swap_chain.?,
        .vtable = &swap_chain_vtable,
    };
}

const swap_chain_vtable = SwapChain.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuSwapChainReference(@ptrCast(c.WGPUSwapChain, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuSwapChainRelease(@ptrCast(c.WGPUSwapChain, ptr));
        }
    }).release,
    .configure = (struct {
        pub fn configure(ptr: *anyopaque, format: Texture.Format, allowed_usage: Texture.Usage, width: u32, height: u32) void {
            c.wgpuSwapChainConfigure(
                @ptrCast(c.WGPUSwapChain, ptr),
                @enumToInt(format),
                @enumToInt(allowed_usage),
                width,
                height,
            );
        }
    }).configure,
    .getCurrentTextureView = (struct {
        pub fn getCurrentTextureView(ptr: *anyopaque) TextureView {
            return wrapTextureView(c.wgpuSwapChainGetCurrentTextureView(@ptrCast(c.WGPUSwapChain, ptr)));
        }
    }).getCurrentTextureView,
    .present = (struct {
        pub fn present(ptr: *anyopaque) void {
            c.wgpuSwapChainPresent(@ptrCast(c.WGPUSwapChain, ptr));
        }
    }).present,
};

fn wrapTextureView(texture_view: c.WGPUTextureView) TextureView {
    return .{
        .ptr = texture_view.?,
        .vtable = &texture_view_vtable,
    };
}

const texture_view_vtable = TextureView.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuTextureViewReference(@ptrCast(c.WGPUTextureView, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuTextureViewRelease(@ptrCast(c.WGPUTextureView, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuTextureViewSetLabel(@ptrCast(c.WGPUTextureView, ptr), label);
        }
    }).setLabel,
};

fn wrapTexture(texture: c.WGPUTexture) Texture {
    return .{
        .ptr = texture.?,
        .vtable = &texture_vtable,
    };
}

const texture_vtable = Texture.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuTextureReference(@ptrCast(c.WGPUTexture, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuTextureRelease(@ptrCast(c.WGPUTexture, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuTextureSetLabel(@ptrCast(c.WGPUTexture, ptr), label);
        }
    }).setLabel,
    .destroy = (struct {
        pub fn destroy(ptr: *anyopaque) void {
            c.wgpuTextureDestroy(@ptrCast(c.WGPUTexture, ptr));
        }
    }).destroy,
    .createView = (struct {
        pub fn createView(ptr: *anyopaque, descriptor: *const TextureView.Descriptor) TextureView {
            const desc = c.WGPUTextureViewDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else "",
                .format = @enumToInt(descriptor.format),
                .dimension = @enumToInt(descriptor.dimension),
                .baseMipLevel = descriptor.base_mip_level,
                .mipLevelCount = descriptor.mip_level_count,
                .baseArrayLayer = descriptor.base_array_layer,
                .arrayLayerCount = descriptor.array_layer_count,
                .aspect = @enumToInt(descriptor.aspect),
            };
            return wrapTextureView(c.wgpuTextureCreateView(
                @ptrCast(c.WGPUTexture, ptr),
                &desc,
            ));
        }
    }).createView,
};

fn wrapSampler(sampler: c.WGPUSampler) Sampler {
    return .{
        .ptr = sampler.?,
        .vtable = &sampler_vtable,
    };
}

const sampler_vtable = Sampler.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuSamplerReference(@ptrCast(c.WGPUSampler, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuSamplerRelease(@ptrCast(c.WGPUSampler, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuSamplerSetLabel(@ptrCast(c.WGPUSampler, ptr), label);
        }
    }).setLabel,
};

fn wrapRenderPipeline(pipeline: c.WGPURenderPipeline) RenderPipeline {
    return .{
        .ptr = pipeline.?,
        .vtable = &render_pipeline_vtable,
    };
}

const render_pipeline_vtable = RenderPipeline.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuRenderPipelineReference(@ptrCast(c.WGPURenderPipeline, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuRenderPipelineRelease(@ptrCast(c.WGPURenderPipeline, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuRenderPipelineSetLabel(@ptrCast(c.WGPURenderPipeline, ptr), label);
        }
    }).setLabel,
    .getBindGroupLayout = (struct {
        pub fn getBindGroupLayout(ptr: *anyopaque, group_index: u32) BindGroupLayout {
            return wrapBindGroupLayout(c.wgpuRenderPipelineGetBindGroupLayout(
                @ptrCast(c.WGPURenderPipeline, ptr),
                group_index,
            ));
        }
    }).getBindGroupLayout,
};

fn wrapRenderPassEncoder(pass: c.WGPURenderPassEncoder) RenderPassEncoder {
    return .{
        .ptr = pass.?,
        .vtable = &render_pass_encoder_vtable,
    };
}

const render_pass_encoder_vtable = RenderPassEncoder.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuRenderPassEncoderReference(@ptrCast(c.WGPURenderPassEncoder, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuRenderPassEncoderRelease(@ptrCast(c.WGPURenderPassEncoder, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuRenderPassEncoderSetLabel(@ptrCast(c.WGPURenderPassEncoder, ptr), label);
        }
    }).setLabel,
    .setPipeline = (struct {
        pub fn setPipeline(ptr: *anyopaque, pipeline: RenderPipeline) void {
            c.wgpuRenderPassEncoderSetPipeline(@ptrCast(c.WGPURenderPassEncoder, ptr), @ptrCast(c.WGPURenderPipeline, pipeline.ptr));
        }
    }).setPipeline,
    .draw = (struct {
        pub fn draw(ptr: *anyopaque, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
            c.wgpuRenderPassEncoderDraw(@ptrCast(c.WGPURenderPassEncoder, ptr), vertex_count, instance_count, first_vertex, first_instance);
        }
    }).draw,
    .drawIndexed = (struct {
        pub fn drawIndexed(
            ptr: *anyopaque,
            index_count: u32,
            instance_count: u32,
            first_index: u32,
            base_vertex: i32,
            first_instance: u32,
        ) void {
            c.wgpuRenderPassEncoderDrawIndexed(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                index_count,
                instance_count,
                first_index,
                base_vertex,
                first_instance,
            );
        }
    }).drawIndexed,
    .drawIndexedIndirect = (struct {
        pub fn drawIndexedIndirect(ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void {
            c.wgpuRenderPassEncoderDrawIndexedIndirect(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                @ptrCast(c.WGPUBuffer, indirect_buffer.ptr),
                indirect_offset,
            );
        }
    }).drawIndexedIndirect,
    .drawIndirect = (struct {
        pub fn drawIndirect(ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void {
            c.wgpuRenderPassEncoderDrawIndexedIndirect(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                @ptrCast(c.WGPUBuffer, indirect_buffer.ptr),
                indirect_offset,
            );
        }
    }).drawIndirect,
    .beginOcclusionQuery = (struct {
        pub fn beginOcclusionQuery(ptr: *anyopaque, query_index: u32) void {
            c.wgpuRenderPassEncoderBeginOcclusionQuery(@ptrCast(c.WGPURenderPassEncoder, ptr), query_index);
        }
    }).beginOcclusionQuery,
    .endOcclusionQuery = (struct {
        pub fn endOcclusionQuery(ptr: *anyopaque) void {
            c.wgpuRenderPassEncoderEndOcclusionQuery(@ptrCast(c.WGPURenderPassEncoder, ptr));
        }
    }).endOcclusionQuery,
    .end = (struct {
        pub fn end(ptr: *anyopaque) void {
            c.wgpuRenderPassEncoderEnd(@ptrCast(c.WGPURenderPassEncoder, ptr));
        }
    }).end,
    .executeBundles = (struct {
        pub fn executeBundles(ptr: *anyopaque, bundles: []RenderBundle) void {
            var few_bundles: [16]c.WGPURenderBundle = undefined;
            const c_bundles = if (bundles.len <= 8) blk: {
                for (bundles) |bundle, i| {
                    few_bundles[i] = @ptrCast(c.WGPURenderBundle, bundle.ptr);
                }
                break :blk few_bundles[0..bundles.len];
            } else blk: {
                const mem = std.heap.page_allocator.alloc(c.WGPURenderBundle, bundles.len) catch unreachable;
                for (bundles) |bundle, i| {
                    mem[i] = @ptrCast(c.WGPURenderBundle, bundle.ptr);
                }
                break :blk mem;
            };
            defer if (bundles.len > 8) std.heap.page_allocator.free(c_bundles);

            c.wgpuRenderPassEncoderExecuteBundles(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                @intCast(u32, c_bundles.len),
                &c_bundles[0],
            );
        }
    }).executeBundles,
    .insertDebugMarker = (struct {
        pub fn insertDebugMarker(ptr: *anyopaque, marker_label: [*:0]const u8) void {
            c.wgpuRenderPassEncoderInsertDebugMarker(@ptrCast(c.WGPURenderPassEncoder, ptr), marker_label);
        }
    }).insertDebugMarker,
    .popDebugGroup = (struct {
        pub fn popDebugGroup(ptr: *anyopaque) void {
            c.wgpuRenderPassEncoderPopDebugGroup(@ptrCast(c.WGPURenderPassEncoder, ptr));
        }
    }).popDebugGroup,
    .pushDebugGroup = (struct {
        pub fn pushDebugGroup(ptr: *anyopaque, group_label: [*:0]const u8) void {
            c.wgpuRenderPassEncoderPushDebugGroup(@ptrCast(c.WGPURenderPassEncoder, ptr), group_label);
        }
    }).pushDebugGroup,
    .setBindGroup = (struct {
        pub fn setBindGroup(
            ptr: *anyopaque,
            group_index: u32,
            group: BindGroup,
            dynamic_offsets: []u32,
        ) void {
            c.wgpuRenderPassEncoderSetBindGroup(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                group_index,
                @ptrCast(c.WGPUBindGroup, group.ptr),
                @intCast(u32, dynamic_offsets.len),
                &dynamic_offsets[0],
            );
        }
    }).setBindGroup,
    .setBlendConstant = (struct {
        pub fn setBlendConstant(ptr: *anyopaque, color: *const Color) void {
            c.wgpuRenderPassEncoderSetBlendConstant(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                @ptrCast(*const c.WGPUColor, color),
            );
        }
    }).setBlendConstant,
    .setIndexBuffer = (struct {
        pub fn setIndexBuffer(
            ptr: *anyopaque,
            buffer: Buffer,
            format: IndexFormat,
            offset: u64,
            size: u64,
        ) void {
            c.wgpuRenderPassEncoderSetIndexBuffer(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                @ptrCast(c.WGPUBuffer, buffer.ptr),
                @enumToInt(format),
                offset,
                size,
            );
        }
    }).setIndexBuffer,
    .setScissorRect = (struct {
        pub fn setScissorRect(ptr: *anyopaque, x: u32, y: u32, width: u32, height: u32) void {
            c.wgpuRenderPassEncoderSetScissorRect(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                x,
                y,
                width,
                height,
            );
        }
    }).setScissorRect,
    .setStencilReference = (struct {
        pub fn setStencilReference(ptr: *anyopaque, reference: u32) void {
            c.wgpuRenderPassEncoderSetStencilReference(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                reference,
            );
        }
    }).setStencilReference,
    .setVertexBuffer = (struct {
        pub fn setVertexBuffer(ptr: *anyopaque, slot: u32, buffer: Buffer, offset: u64, size: u64) void {
            c.wgpuRenderPassEncoderSetVertexBuffer(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                slot,
                @ptrCast(c.WGPUBuffer, buffer.ptr),
                offset,
                size,
            );
        }
    }).setVertexBuffer,
    .setViewport = (struct {
        pub fn setViewport(
            ptr: *anyopaque,
            x: f32,
            y: f32,
            width: f32,
            height: f32,
            min_depth: f32,
            max_depth: f32,
        ) void {
            c.wgpuRenderPassEncoderSetViewport(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                x,
                y,
                width,
                height,
                min_depth,
                max_depth,
            );
        }
    }).setViewport,
    .writeTimestamp = (struct {
        pub fn writeTimestamp(ptr: *anyopaque, query_set: QuerySet, query_index: u32) void {
            c.wgpuRenderPassEncoderWriteTimestamp(
                @ptrCast(c.WGPURenderPassEncoder, ptr),
                @ptrCast(c.WGPUQuerySet, query_set.ptr),
                query_index,
            );
        }
    }).writeTimestamp,
};

fn wrapRenderBundleEncoder(enc: c.WGPURenderBundleEncoder) RenderBundleEncoder {
    return .{
        .ptr = enc.?,
        .vtable = &render_bundle_encoder_vtable,
    };
}

const render_bundle_encoder_vtable = RenderBundleEncoder.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuRenderBundleEncoderReference(@ptrCast(c.WGPURenderBundleEncoder, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuRenderBundleEncoderRelease(@ptrCast(c.WGPURenderBundleEncoder, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuRenderBundleEncoderSetLabel(@ptrCast(c.WGPURenderBundleEncoder, ptr), label);
        }
    }).setLabel,
    .setPipeline = (struct {
        pub fn setPipeline(ptr: *anyopaque, pipeline: RenderPipeline) void {
            c.wgpuRenderBundleEncoderSetPipeline(@ptrCast(c.WGPURenderBundleEncoder, ptr), @ptrCast(c.WGPURenderPipeline, pipeline.ptr));
        }
    }).setPipeline,
    .draw = (struct {
        pub fn draw(ptr: *anyopaque, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
            c.wgpuRenderBundleEncoderDraw(@ptrCast(c.WGPURenderBundleEncoder, ptr), vertex_count, instance_count, first_vertex, first_instance);
        }
    }).draw,
    .drawIndexed = (struct {
        pub fn drawIndexed(
            ptr: *anyopaque,
            index_count: u32,
            instance_count: u32,
            first_index: u32,
            base_vertex: i32,
            first_instance: u32,
        ) void {
            c.wgpuRenderBundleEncoderDrawIndexed(
                @ptrCast(c.WGPURenderBundleEncoder, ptr),
                index_count,
                instance_count,
                first_index,
                base_vertex,
                first_instance,
            );
        }
    }).drawIndexed,
    .drawIndexedIndirect = (struct {
        pub fn drawIndexedIndirect(ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void {
            c.wgpuRenderBundleEncoderDrawIndexedIndirect(
                @ptrCast(c.WGPURenderBundleEncoder, ptr),
                @ptrCast(c.WGPUBuffer, indirect_buffer.ptr),
                indirect_offset,
            );
        }
    }).drawIndexedIndirect,
    .drawIndirect = (struct {
        pub fn drawIndirect(ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void {
            c.wgpuRenderBundleEncoderDrawIndexedIndirect(
                @ptrCast(c.WGPURenderBundleEncoder, ptr),
                @ptrCast(c.WGPUBuffer, indirect_buffer.ptr),
                indirect_offset,
            );
        }
    }).drawIndirect,
    .finish = (struct {
        pub fn finish(ptr: *anyopaque, descriptor: *const RenderBundle.Descriptor) RenderBundle {
            const desc = c.WGPURenderBundleDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| l else null,
            };
            return wrapRenderBundle(c.wgpuRenderBundleEncoderFinish(@ptrCast(c.WGPURenderBundleEncoder, ptr), &desc));
        }
    }).finish,
    .insertDebugMarker = (struct {
        pub fn insertDebugMarker(ptr: *anyopaque, marker_label: [*:0]const u8) void {
            c.wgpuRenderBundleEncoderInsertDebugMarker(@ptrCast(c.WGPURenderBundleEncoder, ptr), marker_label);
        }
    }).insertDebugMarker,
    .popDebugGroup = (struct {
        pub fn popDebugGroup(ptr: *anyopaque) void {
            c.wgpuRenderBundleEncoderPopDebugGroup(@ptrCast(c.WGPURenderBundleEncoder, ptr));
        }
    }).popDebugGroup,
    .pushDebugGroup = (struct {
        pub fn pushDebugGroup(ptr: *anyopaque, group_label: [*:0]const u8) void {
            c.wgpuRenderBundleEncoderPushDebugGroup(@ptrCast(c.WGPURenderBundleEncoder, ptr), group_label);
        }
    }).pushDebugGroup,
    .setBindGroup = (struct {
        pub fn setBindGroup(
            ptr: *anyopaque,
            group_index: u32,
            group: BindGroup,
            dynamic_offsets: []u32,
        ) void {
            c.wgpuRenderBundleEncoderSetBindGroup(
                @ptrCast(c.WGPURenderBundleEncoder, ptr),
                group_index,
                @ptrCast(c.WGPUBindGroup, group.ptr),
                @intCast(u32, dynamic_offsets.len),
                &dynamic_offsets[0],
            );
        }
    }).setBindGroup,
    .setIndexBuffer = (struct {
        pub fn setIndexBuffer(
            ptr: *anyopaque,
            buffer: Buffer,
            format: IndexFormat,
            offset: u64,
            size: u64,
        ) void {
            c.wgpuRenderBundleEncoderSetIndexBuffer(
                @ptrCast(c.WGPURenderBundleEncoder, ptr),
                @ptrCast(c.WGPUBuffer, buffer.ptr),
                @enumToInt(format),
                offset,
                size,
            );
        }
    }).setIndexBuffer,
    .setVertexBuffer = (struct {
        pub fn setVertexBuffer(ptr: *anyopaque, slot: u32, buffer: Buffer, offset: u64, size: u64) void {
            c.wgpuRenderBundleEncoderSetVertexBuffer(
                @ptrCast(c.WGPURenderBundleEncoder, ptr),
                slot,
                @ptrCast(c.WGPUBuffer, buffer.ptr),
                offset,
                size,
            );
        }
    }).setVertexBuffer,
};

fn wrapRenderBundle(bundle: c.WGPURenderBundle) RenderBundle {
    return .{
        .ptr = bundle.?,
        .vtable = &render_bundle_vtable,
    };
}

const render_bundle_vtable = RenderBundle.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuRenderBundleReference(@ptrCast(c.WGPURenderBundle, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuRenderBundleRelease(@ptrCast(c.WGPURenderBundle, ptr));
        }
    }).release,
};

fn wrapQuerySet(qset: c.WGPUQuerySet) QuerySet {
    return .{
        .ptr = qset.?,
        .vtable = &query_set_vtable,
    };
}

const query_set_vtable = QuerySet.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuQuerySetReference(@ptrCast(c.WGPUQuerySet, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuQuerySetRelease(@ptrCast(c.WGPUQuerySet, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuQuerySetSetLabel(@ptrCast(c.WGPUQuerySet, ptr), label);
        }
    }).setLabel,
    .destroy = (struct {
        pub fn destroy(ptr: *anyopaque) void {
            c.wgpuQuerySetDestroy(@ptrCast(c.WGPUQuerySet, ptr));
        }
    }).destroy,
};

fn wrapPipelineLayout(layout: c.WGPUPipelineLayout) PipelineLayout {
    return .{
        .ptr = layout.?,
        .vtable = &pipeline_layout_vtable,
    };
}

const pipeline_layout_vtable = PipelineLayout.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuPipelineLayoutReference(@ptrCast(c.WGPUPipelineLayout, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuPipelineLayoutRelease(@ptrCast(c.WGPUPipelineLayout, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuPipelineLayoutSetLabel(@ptrCast(c.WGPUPipelineLayout, ptr), label);
        }
    }).setLabel,
};

fn wrapExternalTexture(texture: c.WGPUExternalTexture) ExternalTexture {
    return .{
        .ptr = texture.?,
        .vtable = &external_texture_vtable,
    };
}

const external_texture_vtable = ExternalTexture.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuExternalTextureReference(@ptrCast(c.WGPUExternalTexture, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuExternalTextureRelease(@ptrCast(c.WGPUExternalTexture, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuExternalTextureSetLabel(@ptrCast(c.WGPUExternalTexture, ptr), label);
        }
    }).setLabel,
    .destroy = (struct {
        pub fn destroy(ptr: *anyopaque) void {
            c.wgpuExternalTextureDestroy(@ptrCast(c.WGPUExternalTexture, ptr));
        }
    }).destroy,
};

fn wrapBindGroup(group: c.WGPUBindGroup) BindGroup {
    return .{
        .ptr = group.?,
        .vtable = &bind_group_vtable,
    };
}

const bind_group_vtable = BindGroup.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuBindGroupReference(@ptrCast(c.WGPUBindGroup, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuBindGroupRelease(@ptrCast(c.WGPUBindGroup, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuBindGroupSetLabel(@ptrCast(c.WGPUBindGroup, ptr), label);
        }
    }).setLabel,
};

fn wrapBindGroupLayout(layout: c.WGPUBindGroupLayout) BindGroupLayout {
    return .{
        .ptr = layout.?,
        .vtable = &bind_group_layout_vtable,
    };
}

const bind_group_layout_vtable = BindGroupLayout.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuBindGroupLayoutReference(@ptrCast(c.WGPUBindGroupLayout, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuBindGroupLayoutRelease(@ptrCast(c.WGPUBindGroupLayout, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuBindGroupLayoutSetLabel(@ptrCast(c.WGPUBindGroupLayout, ptr), label);
        }
    }).setLabel,
};

fn wrapBuffer(buffer: c.WGPUBuffer) Buffer {
    return .{
        .ptr = buffer.?,
        .vtable = &buffer_vtable,
    };
}

const buffer_vtable = Buffer.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuBufferReference(@ptrCast(c.WGPUBuffer, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuBufferRelease(@ptrCast(c.WGPUBuffer, ptr));
        }
    }).release,
    .getConstMappedRange = (struct {
        pub fn getConstMappedRange(ptr: *anyopaque, offset: usize, size: usize) []const u8 {
            const range = c.wgpuBufferGetConstMappedRange(@ptrCast(c.WGPUBuffer, ptr), offset, size);
            return @ptrCast([*c]const u8, range.?)[0..size];
        }
    }).getConstMappedRange,
    .getMappedRange = (struct {
        pub fn getMappedRange(ptr: *anyopaque, offset: usize, size: usize) []u8 {
            const range = c.wgpuBufferGetMappedRange(@ptrCast(c.WGPUBuffer, ptr), offset, size);
            return @ptrCast([*c]u8, range.?)[0..size];
        }
    }).getMappedRange,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuBufferSetLabel(@ptrCast(c.WGPUBuffer, ptr), label);
        }
    }).setLabel,
    .destroy = (struct {
        pub fn destroy(ptr: *anyopaque) void {
            c.wgpuBufferDestroy(@ptrCast(c.WGPUBuffer, ptr));
        }
    }).destroy,
    .mapAsync = (struct {
        pub fn mapAsync(
            ptr: *anyopaque,
            mode: Buffer.MapMode,
            offset: usize,
            size: usize,
            callback: *Buffer.MapCallback,
        ) void {
            const cCallback = (struct {
                pub fn cCallback(status: c.WGPUBufferMapAsyncStatus, userdata: ?*anyopaque) callconv(.C) void {
                    const callback_info = @ptrCast(*Buffer.MapCallback, @alignCast(@alignOf(*Buffer.MapCallback), userdata.?));
                    callback_info.type_erased_callback(callback_info.type_erased_ctx, @intToEnum(Buffer.MapAsyncStatus, status));
                }
            }).cCallback;
            c.wgpuBufferMapAsync(@ptrCast(c.WGPUBuffer, ptr), @enumToInt(mode), offset, size, cCallback, callback);
        }
    }).mapAsync,
    .unmap = (struct {
        pub fn unmap(ptr: *anyopaque) void {
            c.wgpuBufferUnmap(@ptrCast(c.WGPUBuffer, ptr));
        }
    }).unmap,
};

fn wrapCommandBuffer(buffer: c.WGPUCommandBuffer) CommandBuffer {
    return .{
        .ptr = buffer.?,
        .vtable = &command_buffer_vtable,
    };
}

const command_buffer_vtable = CommandBuffer.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuCommandBufferReference(@ptrCast(c.WGPUCommandBuffer, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuCommandBufferRelease(@ptrCast(c.WGPUCommandBuffer, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuCommandBufferSetLabel(@ptrCast(c.WGPUCommandBuffer, ptr), label);
        }
    }).setLabel,
};

fn wrapCommandEncoder(enc: c.WGPUCommandEncoder) CommandEncoder {
    return .{
        .ptr = enc.?,
        .vtable = &command_encoder_vtable,
    };
}

const command_encoder_vtable = CommandEncoder.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuCommandEncoderReference(@ptrCast(c.WGPUCommandEncoder, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuCommandEncoderRelease(@ptrCast(c.WGPUCommandEncoder, ptr));
        }
    }).release,
    .finish = (struct {
        pub fn finish(ptr: *anyopaque, descriptor: ?*const CommandBuffer.Descriptor) CommandBuffer {
            const desc: ?*c.WGPUCommandBufferDescriptor = if (descriptor) |d| &.{
                .nextInChain = null,
                .label = if (d.label) |l| l else "",
            } else null;
            return wrapCommandBuffer(c.wgpuCommandEncoderFinish(@ptrCast(c.WGPUCommandEncoder, ptr), desc));
        }
    }).finish,
    .injectValidationError = (struct {
        pub fn injectValidationError(ptr: *anyopaque, message: [*:0]const u8) void {
            c.wgpuCommandEncoderInjectValidationError(@ptrCast(c.WGPUCommandEncoder, ptr), message);
        }
    }).injectValidationError,
    .insertDebugMarker = (struct {
        pub fn insertDebugMarker(ptr: *anyopaque, marker_label: [*:0]const u8) void {
            c.wgpuCommandEncoderInsertDebugMarker(@ptrCast(c.WGPUCommandEncoder, ptr), marker_label);
        }
    }).insertDebugMarker,
    .resolveQuerySet = (struct {
        pub fn resolveQuerySet(
            ptr: *anyopaque,
            query_set: QuerySet,
            first_query: u32,
            query_count: u32,
            destination: Buffer,
            destination_offset: u64,
        ) void {
            c.wgpuCommandEncoderResolveQuerySet(
                @ptrCast(c.WGPUCommandEncoder, ptr),
                @ptrCast(c.WGPUQuerySet, query_set.ptr),
                first_query,
                query_count,
                @ptrCast(c.WGPUBuffer, destination.ptr),
                destination_offset,
            );
        }
    }).resolveQuerySet,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuCommandEncoderSetLabel(@ptrCast(c.WGPUCommandEncoder, ptr), label);
        }
    }).setLabel,
    .beginComputePass = (struct {
        pub fn beginComputePass(ptr: *anyopaque, d: *const ComputePassEncoder.Descriptor) ComputePassEncoder {
            var few_timestamp_writes: [8]c.WGPUComputePassTimestampWrite = undefined;
            const timestamp_writes = if (d.timestamp_writes.len <= 8) blk: {
                for (d.timestamp_writes) |v, i| {
                    few_timestamp_writes[i] = c.WGPUComputePassTimestampWrite{
                        .querySet = @ptrCast(c.WGPUQuerySet, v.query_set.ptr),
                        .queryIndex = v.query_index,
                        .location = @enumToInt(v.location),
                    };
                }
                break :blk few_timestamp_writes[0..d.timestamp_writes.len];
            } else blk: {
                const mem = std.heap.page_allocator.alloc(c.WGPUComputePassTimestampWrite, d.timestamp_writes.len) catch unreachable;
                for (d.timestamp_writes) |v, i| {
                    mem[i] = c.WGPUComputePassTimestampWrite{
                        .querySet = @ptrCast(c.WGPUQuerySet, v.query_set.ptr),
                        .queryIndex = v.query_index,
                        .location = @enumToInt(v.location),
                    };
                }
                break :blk mem;
            };
            defer if (d.timestamp_writes.len > 8) std.heap.page_allocator.free(timestamp_writes);

            const desc = c.WGPUComputePassDescriptor{
                .nextInChain = null,
                .label = if (d.label) |l| l else null,
                .timestampWriteCount = @intCast(u32, timestamp_writes.len),
                .timestampWrites = @ptrCast(*const c.WGPUComputePassTimestampWrite, &timestamp_writes[0]),
            };
            return wrapComputePassEncoder(c.wgpuCommandEncoderBeginComputePass(@ptrCast(c.WGPUCommandEncoder, ptr), &desc));
        }
    }).beginComputePass,
    .beginRenderPass = (struct {
        pub fn beginRenderPass(ptr: *anyopaque, d: *const RenderPassEncoder.Descriptor) RenderPassEncoder {
            var few_color_attachments: [8]c.WGPURenderPassColorAttachment = undefined;
            const color_attachments = if (d.color_attachments.len <= 8) blk: {
                for (d.color_attachments) |v, i| {
                    few_color_attachments[i] = c.WGPURenderPassColorAttachment{
                        .view = @ptrCast(c.WGPUTextureView, v.view.ptr),
                        .resolveTarget = if (v.resolve_target) |t| @ptrCast(c.WGPUTextureView, t.ptr) else null,
                        .loadOp = @enumToInt(v.load_op),
                        .storeOp = @enumToInt(v.load_op),
                        .clearValue = @bitCast(c.WGPUColor, v.clear_value),
                        // deprecated:
                        .clearColor = c.WGPUColor{
                            .r = std.math.nan(f32),
                            .g = std.math.nan(f32),
                            .b = std.math.nan(f32),
                            .a = std.math.nan(f32),
                        },
                    };
                }
                break :blk few_color_attachments[0..d.color_attachments.len];
            } else blk: {
                const mem = std.heap.page_allocator.alloc(c.WGPURenderPassColorAttachment, d.color_attachments.len) catch unreachable;
                for (d.color_attachments) |v, i| {
                    mem[i] = c.WGPURenderPassColorAttachment{
                        .view = @ptrCast(c.WGPUTextureView, v.view.ptr),
                        .resolveTarget = if (v.resolve_target) |t| @ptrCast(c.WGPUTextureView, t.ptr) else null,
                        .loadOp = @enumToInt(v.load_op),
                        .storeOp = @enumToInt(v.load_op),
                        .clearValue = @bitCast(c.WGPUColor, v.clear_value),
                        // deprecated:
                        .clearColor = c.WGPUColor{
                            .r = std.math.nan(f32),
                            .g = std.math.nan(f32),
                            .b = std.math.nan(f32),
                            .a = std.math.nan(f32),
                        },
                    };
                }
                break :blk mem;
            };
            defer if (d.color_attachments.len > 8) std.heap.page_allocator.free(color_attachments);

            var few_timestamp_writes: [8]c.WGPURenderPassTimestampWrite = undefined;
            const timestamp_writes = if (d.timestamp_writes) |writes| blk: {
                if (writes.len <= 8) {
                    for (writes) |v, i| {
                        few_timestamp_writes[i] = c.WGPURenderPassTimestampWrite{
                            .querySet = @ptrCast(c.WGPUQuerySet, v.query_set.ptr),
                            .queryIndex = v.query_index,
                            .location = @enumToInt(v.location),
                        };
                    }
                    break :blk few_timestamp_writes[0..writes.len];
                } else {
                    const mem = std.heap.page_allocator.alloc(c.WGPURenderPassTimestampWrite, writes.len) catch unreachable;
                    for (writes) |v, i| {
                        mem[i] = c.WGPURenderPassTimestampWrite{
                            .querySet = @ptrCast(c.WGPUQuerySet, v.query_set.ptr),
                            .queryIndex = v.query_index,
                            .location = @enumToInt(v.location),
                        };
                    }
                    break :blk mem;
                }
            } else null;
            defer if (timestamp_writes != null and timestamp_writes.?.len > 8) std.heap.page_allocator.free(timestamp_writes.?);

            const desc = c.WGPURenderPassDescriptor{
                .nextInChain = null,
                .label = if (d.label) |l| l else null,
                .colorAttachmentCount = @intCast(u32, color_attachments.len),
                .colorAttachments = &color_attachments[0],
                .depthStencilAttachment = if (d.depth_stencil_attachment) |v| &c.WGPURenderPassDepthStencilAttachment{
                    .view = @ptrCast(c.WGPUTextureView, v.view.ptr),
                    .depthLoadOp = @enumToInt(v.depth_load_op),
                    .depthStoreOp = @enumToInt(v.depth_store_op),
                    .clearDepth = v.clear_depth,
                    .depthClearValue = v.depth_clear_value,
                    .depthReadOnly = v.depth_read_only,
                    .stencilLoadOp = @enumToInt(v.stencil_load_op),
                    .stencilStoreOp = @enumToInt(v.stencil_store_op),
                    .clearStencil = v.clear_stencil,
                    .stencilClearValue = v.stencil_clear_value,
                    .stencilReadOnly = v.stencil_read_only,
                } else null,
                .occlusionQuerySet = if (d.occlusion_query_set) |v| @ptrCast(c.WGPUQuerySet, v.ptr) else null,
                .timestampWriteCount = if (timestamp_writes) |v| @intCast(u32, v.len) else 0,
                .timestampWrites = if (timestamp_writes) |v| @ptrCast(*const c.WGPURenderPassTimestampWrite, &v[0]) else null,
            };
            return wrapRenderPassEncoder(c.wgpuCommandEncoderBeginRenderPass(@ptrCast(c.WGPUCommandEncoder, ptr), &desc));
        }
    }).beginRenderPass,
    .clearBuffer = (struct {
        pub fn clearBuffer(ptr: *anyopaque, buffer: Buffer, offset: u64, size: u64) void {
            c.wgpuCommandEncoderClearBuffer(
                @ptrCast(c.WGPUCommandEncoder, ptr),
                @ptrCast(c.WGPUBuffer, buffer.ptr),
                offset,
                size,
            );
        }
    }).clearBuffer,
    .copyBufferToBuffer = (struct {
        pub fn copyBufferToBuffer(
            ptr: *anyopaque,
            source: Buffer,
            source_offset: u64,
            destination: Buffer,
            destination_offset: u64,
            size: u64,
        ) void {
            c.wgpuCommandEncoderCopyBufferToBuffer(
                @ptrCast(c.WGPUCommandEncoder, ptr),
                @ptrCast(c.WGPUBuffer, source.ptr),
                source_offset,
                @ptrCast(c.WGPUBuffer, destination.ptr),
                destination_offset,
                size,
            );
        }
    }).copyBufferToBuffer,
    .copyBufferToTexture = (struct {
        pub fn copyBufferToTexture(
            ptr: *anyopaque,
            source: *const ImageCopyBuffer,
            destination: *const ImageCopyTexture,
            copy_size: *const Extent3D,
        ) void {
            c.wgpuCommandEncoderCopyBufferToTexture(
                @ptrCast(c.WGPUCommandEncoder, ptr),
                &convertImageCopyBuffer(source),
                &convertImageCopyTexture(destination),
                @ptrCast(*const c.WGPUExtent3D, copy_size),
            );
        }
    }).copyBufferToTexture,
    .copyTextureToBuffer = (struct {
        pub fn copyTextureToBuffer(
            ptr: *anyopaque,
            source: *const ImageCopyTexture,
            destination: *const ImageCopyBuffer,
            copy_size: *const Extent3D,
        ) void {
            c.wgpuCommandEncoderCopyTextureToBuffer(
                @ptrCast(c.WGPUCommandEncoder, ptr),
                &convertImageCopyTexture(source),
                &convertImageCopyBuffer(destination),
                @ptrCast(*const c.WGPUExtent3D, copy_size),
            );
        }
    }).copyTextureToBuffer,
    .copyTextureToTexture = (struct {
        pub fn copyTextureToTexture(
            ptr: *anyopaque,
            source: *const ImageCopyTexture,
            destination: *const ImageCopyTexture,
            copy_size: *const Extent3D,
        ) void {
            c.wgpuCommandEncoderCopyTextureToTexture(
                @ptrCast(c.WGPUCommandEncoder, ptr),
                &convertImageCopyTexture(source),
                &convertImageCopyTexture(destination),
                @ptrCast(*const c.WGPUExtent3D, copy_size),
            );
        }
    }).copyTextureToTexture,
    .popDebugGroup = (struct {
        pub fn popDebugGroup(ptr: *anyopaque) void {
            c.wgpuCommandEncoderPopDebugGroup(@ptrCast(c.WGPUCommandEncoder, ptr));
        }
    }).popDebugGroup,
    .pushDebugGroup = (struct {
        pub fn pushDebugGroup(ptr: *anyopaque, group_label: [*:0]const u8) void {
            c.wgpuCommandEncoderPushDebugGroup(@ptrCast(c.WGPUCommandEncoder, ptr), group_label);
        }
    }).pushDebugGroup,
    .writeBuffer = (struct {
        pub fn writeBuffer(ptr: *anyopaque, buffer: Buffer, buffer_offset: u64, data: *const u8, size: u64) void {
            c.wgpuCommandEncoderWriteBuffer(
                @ptrCast(c.WGPUCommandEncoder, ptr),
                @ptrCast(c.WGPUBuffer, buffer.ptr),
                buffer_offset,
                data,
                size,
            );
        }
    }).writeBuffer,
    .writeTimestamp = (struct {
        pub fn writeTimestamp(ptr: *anyopaque, query_set: QuerySet, query_index: u32) void {
            c.wgpuCommandEncoderWriteTimestamp(
                @ptrCast(c.WGPUCommandEncoder, ptr),
                @ptrCast(c.WGPUQuerySet, query_set.ptr),
                query_index,
            );
        }
    }).writeTimestamp,
};

inline fn convertImageCopyBuffer(v: *const ImageCopyBuffer) c.WGPUImageCopyBuffer {
    return .{
        .nextInChain = null,
        .layout = convertTextureDataLayout(v.layout),
        .buffer = @ptrCast(c.WGPUBuffer, v.buffer.ptr),
    };
}

inline fn convertImageCopyTexture(v: *const ImageCopyTexture) c.WGPUImageCopyTexture {
    return .{
        .nextInChain = null,
        .texture = @ptrCast(c.WGPUTexture, v.texture.ptr),
        .mipLevel = v.mip_level,
        .origin = @bitCast(c.WGPUOrigin3D, v.origin),
        .aspect = @enumToInt(v.aspect),
    };
}

inline fn convertTextureDataLayout(v: Texture.DataLayout) c.WGPUTextureDataLayout {
    return .{
        .nextInChain = null,
        .offset = v.offset,
        .bytesPerRow = v.bytes_per_row,
        .rowsPerImage = v.rows_per_image,
    };
}

fn wrapComputePassEncoder(enc: c.WGPUComputePassEncoder) ComputePassEncoder {
    return .{
        .ptr = enc.?,
        .vtable = &compute_pass_encoder_vtable,
    };
}

const compute_pass_encoder_vtable = ComputePassEncoder.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuComputePassEncoderReference(@ptrCast(c.WGPUComputePassEncoder, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuComputePassEncoderRelease(@ptrCast(c.WGPUComputePassEncoder, ptr));
        }
    }).release,
    .dispatch = (struct {
        pub fn dispatch(
            ptr: *anyopaque,
            workgroup_count_x: u32,
            workgroup_count_y: u32,
            workgroup_count_z: u32,
        ) void {
            c.wgpuComputePassEncoderDispatch(
                @ptrCast(c.WGPUComputePassEncoder, ptr),
                workgroup_count_x,
                workgroup_count_y,
                workgroup_count_z,
            );
        }
    }).dispatch,
    .dispatchIndirect = (struct {
        pub fn dispatchIndirect(
            ptr: *anyopaque,
            indirect_buffer: Buffer,
            indirect_offset: u64,
        ) void {
            c.wgpuComputePassEncoderDispatchIndirect(
                @ptrCast(c.WGPUComputePassEncoder, ptr),
                @ptrCast(c.WGPUBuffer, indirect_buffer.ptr),
                indirect_offset,
            );
        }
    }).dispatchIndirect,
    .end = (struct {
        pub fn end(ptr: *anyopaque) void {
            c.wgpuComputePassEncoderEnd(@ptrCast(c.WGPUComputePassEncoder, ptr));
        }
    }).end,
    .setBindGroup = (struct {
        pub fn setBindGroup(
            ptr: *anyopaque,
            group_index: u32,
            group: BindGroup,
            dynamic_offsets: []u32,
        ) void {
            c.wgpuComputePassEncoderSetBindGroup(
                @ptrCast(c.WGPUComputePassEncoder, ptr),
                group_index,
                @ptrCast(c.WGPUBindGroup, group.ptr),
                @intCast(u32, dynamic_offsets.len),
                &dynamic_offsets[0],
            );
        }
    }).setBindGroup,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuComputePassEncoderSetLabel(@ptrCast(c.WGPUComputePassEncoder, ptr), label);
        }
    }).setLabel,
    .insertDebugMarker = (struct {
        pub fn insertDebugMarker(ptr: *anyopaque, marker_label: [*:0]const u8) void {
            c.wgpuComputePassEncoderInsertDebugMarker(@ptrCast(c.WGPUComputePassEncoder, ptr), marker_label);
        }
    }).insertDebugMarker,
    .popDebugGroup = (struct {
        pub fn popDebugGroup(ptr: *anyopaque) void {
            c.wgpuComputePassEncoderPopDebugGroup(@ptrCast(c.WGPUComputePassEncoder, ptr));
        }
    }).popDebugGroup,
    .pushDebugGroup = (struct {
        pub fn pushDebugGroup(ptr: *anyopaque, group_label: [*:0]const u8) void {
            c.wgpuComputePassEncoderPushDebugGroup(@ptrCast(c.WGPUComputePassEncoder, ptr), group_label);
        }
    }).pushDebugGroup,
    .setPipeline = (struct {
        pub fn setPipeline(ptr: *anyopaque, pipeline: ComputePipeline) void {
            c.wgpuComputePassEncoderSetPipeline(@ptrCast(c.WGPUComputePassEncoder, ptr), @ptrCast(c.WGPUComputePipeline, pipeline.ptr));
        }
    }).setPipeline,
    .writeTimestamp = (struct {
        pub fn writeTimestamp(ptr: *anyopaque, query_set: QuerySet, query_index: u32) void {
            c.wgpuComputePassEncoderWriteTimestamp(
                @ptrCast(c.WGPUComputePassEncoder, ptr),
                @ptrCast(c.WGPUQuerySet, query_set.ptr),
                query_index,
            );
        }
    }).writeTimestamp,
};

fn wrapComputePipeline(pipeline: c.WGPUComputePipeline) ComputePipeline {
    return .{
        .ptr = pipeline.?,
        .vtable = &compute_pipeline_vtable,
    };
}

const compute_pipeline_vtable = ComputePipeline.VTable{
    .reference = (struct {
        pub fn reference(ptr: *anyopaque) void {
            c.wgpuComputePipelineReference(@ptrCast(c.WGPUComputePipeline, ptr));
        }
    }).reference,
    .release = (struct {
        pub fn release(ptr: *anyopaque) void {
            c.wgpuComputePipelineRelease(@ptrCast(c.WGPUComputePipeline, ptr));
        }
    }).release,
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuComputePipelineSetLabel(@ptrCast(c.WGPUComputePipeline, ptr), label);
        }
    }).setLabel,
    .getBindGroupLayout = (struct {
        pub fn getBindGroupLayout(ptr: *anyopaque, group_index: u32) BindGroupLayout {
            return wrapBindGroupLayout(c.wgpuComputePipelineGetBindGroupLayout(
                @ptrCast(c.WGPUComputePipeline, ptr),
                group_index,
            ));
        }
    }).getBindGroupLayout,
};

test {
    _ = wrap;
    _ = interface_vtable;
    _ = interface;
    _ = createSurface;
    _ = surface_vtable;
    _ = adapter_vtable;
    _ = wrapDevice;
    _ = device_vtable;
    _ = wrapQueue;
    _ = wrapShaderModule;
    _ = wrapSwapChain;
    _ = wrapTextureView;
    _ = wrapTexture;
    _ = wrapSampler;
    _ = wrapRenderPipeline;
    _ = wrapRenderPassEncoder;
    _ = wrapRenderBundleEncoder;
    _ = wrapRenderBundle;
    _ = wrapQuerySet;
    _ = wrapPipelineLayout;
    _ = wrapExternalTexture;
    _ = wrapBindGroup;
    _ = wrapBindGroupLayout;
    _ = wrapBuffer;
    _ = wrapCommandBuffer;
    _ = wrapCommandEncoder;
    _ = wrapComputePassEncoder;
    _ = wrapComputePipeline;
}
