//! A native webgpu.h implementation of the gpu.Interface
const std = @import("std");
const c = @import("c.zig").c;

const Interface = @import("Interface.zig");
const RequestAdapterOptions = Interface.RequestAdapterOptions;
const RequestAdapterErrorCode = Interface.RequestAdapterErrorCode;
const RequestAdapterError = Interface.RequestAdapterError;
const RequestAdapterResponse = Interface.RequestAdapterResponse;

const Adapter = @import("Adapter.zig");
const RequestDeviceErrorCode = Adapter.RequestDeviceErrorCode;
const RequestDeviceError = Adapter.RequestDeviceError;
const RequestDeviceResponse = Adapter.RequestDeviceResponse;

const Device = @import("Device.zig");
const Surface = @import("Surface.zig");
const Limits = @import("Limits.zig");
const Queue = @import("Queue.zig");
const CommandBuffer = @import("CommandBuffer.zig");
const ShaderModule = @import("ShaderModule.zig");
const SwapChain = @import("SwapChain.zig");

const TextureUsage = @import("texture_usage.zig").TextureUsage;
const TextureFormat = @import("enums.zig").TextureFormat;
const PresentMode = @import("enums.zig").PresentMode;

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
        pub fn requestAdapter(ptr: *anyopaque, options: *const RequestAdapterOptions) callconv(.Async) RequestAdapterResponse {
            const native = @ptrCast(*NativeInstance, @alignCast(@alignOf(*NativeInstance), ptr));

            const opt = c.WGPURequestAdapterOptions{
                .nextInChain = null,
                .compatibleSurface = if (options.compatible_surface) |surface| @ptrCast(c.WGPUSurface, surface.ptr) else null,
                // TODO:
                //.powerPreference = power_preference,
                .powerPreference = c.WGPUPowerPreference_Undefined,
                .forceFallbackAdapter = options.force_fallback_adapter,
            };

            const callback = (struct {
                pub fn callback(status: c.WGPURequestAdapterStatus, adapter: c.WGPUAdapter, message: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
                    const _callback_response = @ptrCast(*Interface.RequestAdapterResponse, @alignCast(@alignOf(*Interface.RequestAdapterResponse), userdata));

                    // Store the response into a field on the native instance for later reading.
                    _callback_response.* = if (status == c.WGPURequestAdapterStatus_Success) .{
                        .adapter = wrapAdapter(adapter.?),
                    } else .{
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
                }
            }).callback;

            var callback_response: Interface.RequestAdapterResponse = undefined;
            c.wgpuInstanceRequestAdapter(native.instance, &opt, callback, &callback_response);
            // TODO: Once crbug.com/dawn/1122 is fixed, we should process events here otherwise our
            // callback will not be invoked.
            // c.wgpuInstanceProcessEvents(native.instance)
            suspend {} // must suspend so that async caller can resume

            // Return the response, asserting the callback has executed at this point.
            return callback_response;
        }
    }).requestAdapter,
};

/// Returns the gpu.Interface for interacting with this native instance.
pub fn interface(native: *NativeInstance) Interface {
    return .{
        .ptr = native,
        .vtable = &interface_vtable,
        .request_adapter_frame_size = @frameSize(interface_vtable.requestAdapter),
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
                .label = if (src.label) |l| @ptrCast([*c]const u8, l) else null,
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
                .label = if (src.label) |l| @ptrCast([*c]const u8, l) else null,
            });
        },
        .windows_core_window => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromWindowsCoreWindow = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromWindowsCoreWindow;
            desc.coreWindow = src.core_window;
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| @ptrCast([*c]const u8, l) else null,
            });
        },
        .windows_swap_chain_panel => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromWindowsSwapChainPanel = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromWindowsSwapChainPanel;
            desc.swapChainPanel = src.swap_chain_panel;
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| @ptrCast([*c]const u8, l) else null,
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
                .label = if (src.label) |l| @ptrCast([*c]const u8, l) else null,
            });
        },
        .canvas_html_selector => |src| blk: {
            var desc: c.WGPUSurfaceDescriptorFromCanvasHTMLSelector = undefined;
            desc.chain.next = null;
            desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromCanvasHTMLSelector;
            desc.selector = @ptrCast([*c]const u8, src.selector);
            break :blk c.wgpuInstanceCreateSurface(native.instance, &c.WGPUSurfaceDescriptor{
                .nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc),
                .label = if (src.label) |l| @ptrCast([*c]const u8, l) else null,
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

    // TODO: implement Adapter interface:
    // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeature * features);
    // WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeature feature);
    // WGPU_EXPORT bool wgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);

    return .{
        // TODO:
        .features = undefined,
        // TODO:
        .limits = undefined,
        .properties = properties,

        // TODO: why is fallback not queryable on Dawn?
        .fallback = false,

        .ptr = adapter.?,
        .vtable = &adapter_vtable,
        .request_device_frame_size = @frameSize(adapter_vtable.requestDevice),
    };
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
        pub fn requestDevice(ptr: *anyopaque, descriptor: *const Device.Descriptor) callconv(.Async) RequestDeviceResponse {
            const adapter = @ptrCast(c.WGPUAdapter, @alignCast(@alignOf(c.WGPUAdapter), ptr));

            const required_limits = if (descriptor.required_limits) |l| c.WGPURequiredLimits{
                .nextInChain = null,
                .limits = convertLimits(l),
            } else null;

            const desc = c.WGPUDeviceDescriptor{
                .nextInChain = null,
                .label = if (descriptor.label) |l| @ptrCast([*c]const u8, l) else null,
                .requiredFeaturesCount = if (descriptor.required_features) |f| @intCast(u32, f.len) else 0,
                .requiredFeatures = if (descriptor.required_features) |f| @ptrCast([*c]const c_uint, &f[0]) else null,
                .requiredLimits = if (required_limits) |*l| l else null,
            };

            const callback = (struct {
                pub fn callback(status: c.WGPURequestDeviceStatus, device: c.WGPUDevice, message: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
                    const _callback_response = @ptrCast(*Adapter.RequestDeviceResponse, @alignCast(@alignOf(*Adapter.RequestDeviceResponse), userdata));

                    // Store the response into a field on the native instance for later reading.
                    _callback_response.* = if (status == c.WGPURequestDeviceStatus_Success) .{
                        .device = wrapDevice(device.?),
                    } else .{
                        .err = Adapter.RequestDeviceError{
                            .message = std.mem.span(message),
                            .code = switch (status) {
                                c.WGPURequestDeviceStatus_Error => RequestDeviceErrorCode.Error,
                                c.WGPURequestDeviceStatus_Unknown => RequestDeviceErrorCode.Unknown,
                                else => unreachable,
                            },
                        },
                    };
                }
            }).callback;

            var callback_response: Adapter.RequestDeviceResponse = undefined;
            c.wgpuAdapterRequestDevice(adapter, &desc, callback, &callback_response);
            // TODO: Once crbug.com/dawn/1122 is fixed, we should process events here otherwise our
            // callback will not be invoked.
            // c.wgpuInstanceProcessEvents(native.instance)
            suspend {} // must suspend so that async caller can resume

            // Return the response, asserting the callback has executed at this point.
            return callback_response;
        }
    }).requestDevice,
};

fn wrapDevice(device: c.WGPUDevice) Device {
    // TODO: implement Device interface
    return .{
        .ptr = device.?,
        .vtable = &device_vtable,
    };
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
                        .label = if (descriptor.label) |l| @ptrCast([*c]const u8, l) else null,
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
                        .label = if (descriptor.label) |l| @ptrCast([*c]const u8, l) else null,
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
                .label = if (descriptor.label) |l| @ptrCast([*c]const u8, l) else null,
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
};

// TODO: maybe make Limits an extern struct that can be cast?
fn convertLimits(l: Limits) c.WGPULimits {
    return .{
        .maxTextureDimension1D = l.max_texture_dimension_1d,
        .maxTextureDimension2D = l.max_texture_dimension_2d,
        .maxTextureDimension3D = l.max_texture_dimension_3d,
        .maxTextureArrayLayers = l.max_texture_array_layers,
        .maxBindGroups = l.max_bind_groups,
        .maxDynamicUniformBuffersPerPipelineLayout = l.max_dynamic_uniform_buffers_per_pipeline_layout,
        .maxDynamicStorageBuffersPerPipelineLayout = l.max_dynamic_storage_buffers_per_pipeline_layout,
        .maxSampledTexturesPerShaderStage = l.max_sampled_textures_per_shader_stage,
        .maxSamplersPerShaderStage = l.max_samplers_per_shader_stage,
        .maxStorageBuffersPerShaderStage = l.max_storage_buffers_per_shader_stage,
        .maxStorageTexturesPerShaderStage = l.max_storage_textures_per_shader_stage,
        .maxUniformBuffersPerShaderStage = l.max_uniform_buffers_per_shader_stage,
        .maxUniformBufferBindingSize = l.max_uniform_buffer_binding_size,
        .maxStorageBufferBindingSize = l.max_storage_buffer_binding_size,
        .minUniformBufferOffsetAlignment = l.min_uniform_buffer_offset_alignment,
        .minStorageBufferOffsetAlignment = l.min_storage_buffer_offset_alignment,
        .maxVertexBuffers = l.max_vertex_buffers,
        .maxVertexAttributes = l.max_vertex_attributes,
        .maxVertexBufferArrayStride = l.max_vertex_buffer_array_stride,
        .maxInterStageShaderComponents = l.max_inter_stage_shader_components,
        .maxComputeWorkgroupStorageSize = l.max_compute_workgroup_storage_size,
        .maxComputeInvocationsPerWorkgroup = l.max_compute_invocations_per_workgroup,
        .maxComputeWorkgroupSizeX = l.max_compute_workgroup_size_x,
        .maxComputeWorkgroupSizeY = l.max_compute_workgroup_size_y,
        .maxComputeWorkgroupSizeZ = l.max_compute_workgroup_size_z,
        .maxComputeWorkgroupsPerDimension = l.max_compute_workgroups_per_dimension,
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
        pub fn submit(queue: Queue, command_count: u32, commands: *const CommandBuffer) void {
            const wgpu_queue = @ptrCast(c.WGPUQueue, queue.ptr);

            if (queue.on_submitted_work_done) |on_submitted_work_done| {
                // Note: signalValue is not available in the web API, and it's usage is undocumented
                // kainino says "It's basically reserved for future use, though it's been suggested
                // to remove it instead"
                const signal_value: u64 = 0;

                const callback = (struct {
                    pub fn callback(status: c.WGPUQueueWorkDoneStatus, userdata: ?*anyopaque) callconv(.C) void {
                        const _on_submitted_work_done = @ptrCast(*Queue.OnSubmittedWorkDone, @alignCast(@alignOf(*Queue.OnSubmittedWorkDone), userdata));
                        _on_submitted_work_done.callback(
                            @intToEnum(Queue.WorkDoneStatus, status),
                            _on_submitted_work_done.userdata,
                        );
                    }
                }).callback;

                var mut_on_submitted_work_done = on_submitted_work_done;
                c.wgpuQueueOnSubmittedWorkDone(wgpu_queue, signal_value, callback, &mut_on_submitted_work_done);
            }

            c.wgpuQueueSubmit(
                wgpu_queue,
                command_count,
                @ptrCast(*c.WGPUCommandBuffer, @alignCast(@alignOf(*c.WGPUCommandBuffer), commands.ptr)),
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
        pub fn configure(ptr: *anyopaque, format: TextureFormat, allowed_usage: TextureUsage, width: u32, height: u32) void {
            c.wgpuSwapChainConfigure(
                @ptrCast(c.WGPUSwapChain, ptr),
                @enumToInt(format),
                @enumToInt(allowed_usage),
                width,
                height,
            );
        }
    }).configure,
};

test "syntax" {
    _ = wrap;
    _ = interface_vtable;
    _ = interface;
    _ = createSurface;
    _ = surface_vtable;
    _ = adapter_vtable;
    _ = wrapDevice;
    _ = device_vtable;
    _ = convertLimits;
    _ = wrapQueue;
    _ = wrapShaderModule;
    _ = wrapSwapChain;
}
