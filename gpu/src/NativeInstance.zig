//! A native webgpu.h implementation of the gpu.Interface
const c = @import("c.zig").c;
const Interface = @import("Interface.zig");
const Surface = @import("Surface.zig");

const NativeInstance = @This();

/// The WGPUInstance that is wrapped by this native instance.
instance: c.WGPUInstance,

vtable: Interface.VTable,

/// Wraps a native WGPUInstance to provide an implementation of the gpu.Interface.
pub fn wrap(instance: c.WGPUInstance) NativeInstance {
    return .{ .instance = instance };
}

/// Returns the gpu.Interface for interacting with this native instance.
pub fn interface(native: *const NativeInstance) Interface {
    return .{
        .ptr = native,
        .vtable = native.vtable,
    };
    // TODO: implement Interface
    // WGPU_EXPORT void wgpuInstanceReference(WGPUInstance instance);
    // WGPU_EXPORT void wgpuInstanceRelease(WGPUInstance instance);

    // TODO: implement Device interface

    // TODO: implement Adapter interface:
    // typedef struct WGPUAdapterImpl* WGPUAdapter;
    // // Methods of Adapter
    // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
    // WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
    // WGPU_EXPORT bool wgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);
    // WGPU_EXPORT void wgpuAdapterGetProperties(WGPUAdapter adapter, WGPUAdapterProperties * properties);
}

pub fn createSurface(native: *const NativeInstance, descriptor: *const Surface.Descriptor) Surface {
    // typedef enum WGPUSType {
    //     WGPUSType_Invalid = 0x00000000,
    //     WGPUSType_SurfaceDescriptorFromMetalLayer = 0x00000001,
    //     WGPUSType_SurfaceDescriptorFromWindowsHWND = 0x00000002,
    //     WGPUSType_SurfaceDescriptorFromXlibWindow = 0x00000003,
    //     WGPUSType_SurfaceDescriptorFromCanvasHTMLSelector = 0x00000004,
    //     WGPUSType_SurfaceDescriptorFromWindowsCoreWindow = 0x00000008,
    //     WGPUSType_SurfaceDescriptorFromWindowsSwapChainPanel = 0x0000000B,

    // typedef struct WGPUSurfaceDescriptor {
    //     WGPUChainedStruct const * nextInChain;
    //     char const * label;
    // } WGPUSurfaceDescriptor;

    // typedef struct WGPUSurfaceDescriptorFromCanvasHTMLSelector {
    //     WGPUChainedStruct chain;
    //     char const * selector;
    // } WGPUSurfaceDescriptorFromCanvasHTMLSelector;

    // typedef struct WGPUSurfaceDescriptorFromMetalLayer {
    //     WGPUChainedStruct chain;
    //     void * layer;
    // } WGPUSurfaceDescriptorFromMetalLayer;

    // typedef struct WGPUSurfaceDescriptorFromWindowsCoreWindow {
    //     WGPUChainedStruct chain;
    //     void * coreWindow;
    // } WGPUSurfaceDescriptorFromWindowsCoreWindow;

    // typedef struct WGPUSurfaceDescriptorFromWindowsHWND {
    //     WGPUChainedStruct chain;
    //     void * hinstance;
    //     void * hwnd;
    // } WGPUSurfaceDescriptorFromWindowsHWND;

    // typedef struct WGPUSurfaceDescriptorFromWindowsSwapChainPanel {
    //     WGPUChainedStruct chain;
    //     void * swapChainPanel;
    // } WGPUSurfaceDescriptorFromWindowsSwapChainPanel;

    // typedef struct WGPUSurfaceDescriptorFromXlibWindow {
    //     WGPUChainedStruct chain;
    //     void * display;
    //     uint32_t window;
    // } WGPUSurfaceDescriptorFromXlibWindow;

    //c.wgpuInstanceCreateSurface(native.instance, )
    _ = native;
    _ = descriptor;
    // TODO:
    // WGPU_EXPORT WGPUSurface wgpuInstanceCreateSurface(WGPUInstance instance, WGPUSurfaceDescriptor const * descriptor);
}

// var desc: c.WGPUSurfaceDescriptorFromWindowsHWND = undefined;
// desc.chain.next = null;
// desc.chain.sType = c.WGPUSType_SurfaceDescriptorFromWindowsHWND;

// desc.hinstance = std.os.windows.kernel32.GetModuleHandleW(null);
// desc.hwnd = glfw_native.getWin32Window(window);

// var descriptor: c.WGPUSurfaceDescriptor = undefined;
// descriptor.nextInChain = @ptrCast(*c.WGPUChainedStruct, &desc);
// descriptor.label = "basic surface";
// return c.wgpuInstanceCreateSurface(instance, &descriptor);
