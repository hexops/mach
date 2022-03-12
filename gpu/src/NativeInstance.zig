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
const Limits = @import("data.zig").Limits;
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
                .powerPreference = @enumToInt(options.power_preference),
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
                .label = if (descriptor.label) |l| l else null,
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
    .destroy = (struct {
        pub fn destroy(ptr: *anyopaque) void {
            c.wgpuDeviceDestroy(@ptrCast(c.WGPUDevice, ptr));
        }
    }).destroy,
    .createCommandEncoder = (struct {
        pub fn createCommandEncoder(ptr: *anyopaque, descriptor: ?*const CommandEncoder.Descriptor) CommandEncoder {
            const desc: ?*c.WGPUCommandEncoderDescriptor = if (descriptor) |d| &.{
                .nextInChain = null,
                .label = if (d.label) |l| l else "",
            } else null;
            return wrapCommandEncoder(c.wgpuDeviceCreateCommandEncoder(@ptrCast(c.WGPUDevice, ptr), desc));
        }
    }).createCommandEncoder,
    .createRenderPipeline = (struct {
        pub fn createRenderPipeline(ptr: *anyopaque, descriptor: *const RenderPipeline.Descriptor) RenderPipeline {
            var tmp_depth_stencil: c.WGPUDepthStencilState = undefined;
            var tmp_fragment_state: c.WGPUFragmentState = undefined;
            const desc = convertRenderPipelineDescriptor(descriptor, &tmp_depth_stencil, &tmp_fragment_state);
            return wrapRenderPipeline(c.wgpuDeviceCreateRenderPipeline(@ptrCast(c.WGPUDevice, ptr), &desc));
        }
    }).createRenderPipeline,
};

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
        pub fn submit(queue: Queue, cmds: []const CommandBuffer) void {
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

            var few_commands: [16]c.WGPUCommandBuffer = undefined;
            const commands = if (cmds.len <= 8) blk: {
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
            defer if (cmds.len > 8) std.heap.page_allocator.free(cmds);

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
    .end = (struct {
        pub fn end(ptr: *anyopaque) void {
            c.wgpuRenderPassEncoderEnd(@ptrCast(c.WGPURenderPassEncoder, ptr));
        }
    }).end,
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
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuCommandEncoderSetLabel(@ptrCast(c.WGPUCommandEncoder, ptr), label);
        }
    }).setLabel,
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
                .timestampWriteCount = 0, // TODO
                .timestampWrites = null, // TODO
            };
            return wrapRenderPassEncoder(c.wgpuCommandEncoderBeginRenderPass(@ptrCast(c.WGPUCommandEncoder, ptr), &desc));
        }
    }).beginRenderPass,
};

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
    .setLabel = (struct {
        pub fn setLabel(ptr: *anyopaque, label: [:0]const u8) void {
            c.wgpuComputePassEncoderSetLabel(@ptrCast(c.WGPUComputePassEncoder, ptr), label);
        }
    }).setLabel,
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
