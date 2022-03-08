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

const NativeInstance = @This();

/// The WGPUInstance that is wrapped by this native instance.
instance: c.WGPUInstance,

// TODO: use CallbackResponse approach instead of storing here
request_adapter_response: ?Interface.RequestAdapterResponse = null,

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
                    const _native = @ptrCast(*NativeInstance, @alignCast(@alignOf(*NativeInstance), userdata));

                    // Store the response into a field on the native instance for later reading.
                    _native.request_adapter_response = if (status == c.WGPURequestAdapterStatus_Success) .{
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

            c.wgpuInstanceRequestAdapter(native.instance, &opt, callback, native);
            // TODO: Once crbug.com/dawn/1122 is fixed, we should process events here otherwise our
            // callback will not be invoked.
            // c.wgpuInstanceProcessEvents(native.instance)
            suspend {} // must suspend so that async caller can resume

            // Return the response, asserting the callback has executed at this point.
            const resp = native.request_adapter_response.?;
            native.request_adapter_response = null;
            return resp;
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
        .xlib_window => |src| blk: {
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
    // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
    // WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
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
};

fn convertLimits(l: Limits) c.WGPULimits {
    // TODO: implement!
    _ = l;
    return std.mem.zeroes(c.WGPULimits);
}

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
}
