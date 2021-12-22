#include <dawn_native/DawnNative.h>
#include <dawn_native/wgpu_structs_autogen.h>
#include "utils/BackendBinding.h"
#if defined(DAWN_ENABLE_BACKEND_OPENGL)
#include <dawn_native/OpenGLBackend.h>
#endif
#include "dawn_native_mach.h"

#ifdef __cplusplus
extern "C" {
#endif

// wgpu::AdapterProperties wrappers
MACH_EXPORT void machDawnNativeAdapterProperties_deinit(MachDawnNativeAdapterProperties properties) {
    auto self = reinterpret_cast<wgpu::AdapterProperties*>(properties);
    delete self;
}
MACH_EXPORT uint32_t machDawnNativeAdapterProperties_getVendorID(MachDawnNativeAdapterProperties properties) {
    auto self = reinterpret_cast<wgpu::AdapterProperties*>(properties);
    return self->vendorID;
}
MACH_EXPORT uint32_t machDawnNativeAdapterProperties_getDeviceID(MachDawnNativeAdapterProperties properties) {
    auto self = reinterpret_cast<wgpu::AdapterProperties*>(properties);
    return self->deviceID;
}
MACH_EXPORT char const* machDawnNativeAdapterProperties_getName(MachDawnNativeAdapterProperties properties) {
    auto self = reinterpret_cast<wgpu::AdapterProperties*>(properties);
    return self->name;
}
MACH_EXPORT char const* machDawnNativeAdapterProperties_getDriverDescription(MachDawnNativeAdapterProperties properties) {
    auto self = reinterpret_cast<wgpu::AdapterProperties*>(properties);
    return self->driverDescription;
}
MACH_EXPORT WGPUAdapterType machDawnNativeAdapterProperties_getAdapterType(MachDawnNativeAdapterProperties properties) {
    auto self = reinterpret_cast<wgpu::AdapterProperties*>(properties);
    switch (self->adapterType) {
    case wgpu::AdapterType::DiscreteGPU: return WGPUAdapterType_DiscreteGPU;
    case wgpu::AdapterType::IntegratedGPU: return WGPUAdapterType_IntegratedGPU;
    case wgpu::AdapterType::CPU: return WGPUAdapterType_CPU;
    case wgpu::AdapterType::Unknown: return WGPUAdapterType_Unknown;
    }
}
MACH_EXPORT WGPUBackendType machDawnNativeAdapterProperties_getBackendType(MachDawnNativeAdapterProperties properties) {
    auto self = reinterpret_cast<wgpu::AdapterProperties*>(properties);
    switch (self->backendType) {
    case wgpu::BackendType::WebGPU: return WGPUBackendType_WebGPU;
    case wgpu::BackendType::D3D11: return WGPUBackendType_D3D11;
    case wgpu::BackendType::D3D12: return WGPUBackendType_D3D12;
    case wgpu::BackendType::Metal: return WGPUBackendType_Metal;
    case wgpu::BackendType::Null: return WGPUBackendType_Null;
    case wgpu::BackendType::OpenGL: return WGPUBackendType_OpenGL;
    case wgpu::BackendType::OpenGLES: return WGPUBackendType_OpenGLES;
    case wgpu::BackendType::Vulkan: return WGPUBackendType_Vulkan;
    }
}

// dawn_native::Adapter wrappers
MACH_EXPORT MachDawnNativeAdapterProperties machDawnNativeAdapter_getProperties(MachDawnNativeAdapter adapter) {
    auto self = reinterpret_cast<dawn_native::Adapter*>(adapter);
    auto cppProperties = new wgpu::AdapterProperties();
    self->GetProperties(cppProperties);
    return reinterpret_cast<MachDawnNativeAdapterProperties>(cppProperties);
}
// TODO(dawn-native-mach):
// std::vector<const char*> GetSupportedExtensions() const;
// WGPUDeviceProperties GetAdapterProperties() const;
// bool GetLimits(WGPUSupportedLimits* limits) const;
// void SetUseTieredLimits(bool useTieredLimits);
// // Check that the Adapter is able to support importing external images. This is necessary
// // to implement the swapchain and interop APIs in Chromium.
// bool SupportsExternalImages() const;
// explicit operator bool() const;

// TODO(dawn-native-mach): These API* methods correlate to the new API (which is unified between Dawn
// and wgpu-native?), e.g. dawn_native::Instance::APIRequestAdapter corresponds to wgpuInstanceRequestAdapter
// These are not implemented in Dawn yet according to austineng, but we should switch to this API once they do:
//
// "fyi, the requestAdapter/requestedDevice stuff isn't implemented right now. We just added the interface for it, but still working on the implementation. Today, it'll always fail the callback."
//
//
// bool APIGetLimits(SupportedLimits* limits) const;
// void APIGetProperties(AdapterProperties* properties) const;
// bool APIHasFeature(wgpu::FeatureName feature) const;
// uint32_t APIEnumerateFeatures(wgpu::FeatureName* features) const;
// void APIRequestDevice(const DeviceDescriptor* descriptor,
//                       WGPURequestDeviceCallback callback,
//                       void* userdata);
//
MACH_EXPORT WGPUDevice machDawnNativeAdapter_createDevice(MachDawnNativeAdapter adapter, MachDawnNativeDawnDeviceDescriptor* deviceDescriptor) {
    auto self = reinterpret_cast<dawn_native::Adapter*>(adapter);

    if (deviceDescriptor == nullptr) {
        return self->CreateDevice(nullptr);
    }

    std::vector<const char*> cppRequiredExtensions;
    for (int i = 0; i < deviceDescriptor->requiredFeaturesLength; i++)
        cppRequiredExtensions.push_back(deviceDescriptor->requiredFeatures[i]);

    std::vector<const char*> cppForceEnabledToggles;
    for (int i = 0; i < deviceDescriptor->forceEnabledTogglesLength; i++)
        cppForceEnabledToggles.push_back(deviceDescriptor->forceEnabledToggles[i]);

    std::vector<const char*> cppForceDisabledToggles;
    for (int i = 0; i < deviceDescriptor->forceDisabledTogglesLength; i++)
        cppForceDisabledToggles.push_back(deviceDescriptor->forceDisabledToggles[i]);

    auto cppDeviceDescriptor = dawn_native::DawnDeviceDescriptor{
        .requiredFeatures = cppRequiredExtensions,
        .forceEnabledToggles = cppForceEnabledToggles,
        .forceDisabledToggles = cppForceDisabledToggles,
        .requiredLimits = deviceDescriptor->requiredLimits,
    };
    return self->CreateDevice(&cppDeviceDescriptor);
}

// TODO(dawn-native-mach):
// // Create a device on this adapter, note that the interface will change to include at least
// // a device descriptor and a pointer to backend specific options.
// // On an error, nullptr is returned.
// WGPUDevice CreateDevice(const DeviceDescriptor* deviceDescriptor = nullptr);

// TODO(dawn-native-mach):
// void RequestDevice(const DeviceDescriptor* descriptor,
//                     WGPURequestDeviceCallback callback,
//                     void* userdata);

// TODO(dawn-native-mach):
// // Reset the backend device object for testing purposes.
// void ResetInternalDeviceForTesting();

// std::vector<Adapter> wrapper
typedef struct MachDawnNativeAdaptersImpl* MachDawnNativeAdapters;
MACH_EXPORT MachDawnNativeAdapter machDawnNativeAdapters_index(MachDawnNativeAdapters adapters, uintptr_t index) {
    auto self = reinterpret_cast<std::vector<dawn_native::Adapter>*>(adapters);
    return reinterpret_cast<MachDawnNativeAdapter>(&(*self)[index]);
}
MACH_EXPORT uintptr_t machDawnNativeAdapters_length(MachDawnNativeAdapters adapters) {
    auto self = reinterpret_cast<std::vector<dawn_native::Adapter>*>(adapters);
    return self->size();
};

// dawn_native::Instance wrappers
MACH_EXPORT MachDawnNativeInstance machDawnNativeInstance_init(void) {
    return reinterpret_cast<MachDawnNativeInstance>(new dawn_native::Instance());
}
MACH_EXPORT void machDawnNativeInstance_deinit(MachDawnNativeInstance instance) {
    delete reinterpret_cast<dawn_native::Instance*>(instance);
}
// TODO(dawn-native-mach): These API* methods correlate to the new API (which is unified between Dawn
// and wgpu-native?), e.g. dawn_native::Instance::APIRequestAdapter corresponds to wgpuInstanceRequestAdapter
// These are not implemented in Dawn yet according to austineng, but we should switch to this API once they do:
//
// "fyi, the requestAdapter/requestedDevice stuff isn't implemented right now. We just added the interface for it, but still working on the implementation. Today, it'll always fail the callback."
//
// void APIRequestAdapter(const RequestAdapterOptions* options,
//                        WGPURequestAdapterCallback callback,
//                        void* userdata);
MACH_EXPORT void machDawnNativeInstance_discoverDefaultAdapters(MachDawnNativeInstance instance) {
    dawn_native::Instance* self = reinterpret_cast<dawn_native::Instance*>(instance);
    self->DiscoverDefaultAdapters();
}
MACH_EXPORT bool machDawnNativeInstance_discoverAdapters(MachDawnNativeInstance instance, WGPUBackendType backendType, const void* options) {
    dawn_native::Instance* self = reinterpret_cast<dawn_native::Instance*>(instance);
    switch (backendType) {
    case WGPUBackendType_OpenGL:
    #if defined(DAWN_ENABLE_BACKEND_DESKTOP_GL)
    {
        auto opt = reinterpret_cast<const MachDawnNativeAdapterDiscoveryOptions_OpenGL*>(options);
        dawn_native::opengl::AdapterDiscoveryOptions adapterOptions = dawn_native::opengl::AdapterDiscoveryOptions();
        adapterOptions.getProc = opt->getProc;
        return self->DiscoverAdapters(&adapterOptions);
    }
    #endif
    case WGPUBackendType_OpenGLES:
    #if defined(DAWN_ENABLE_BACKEND_OPENGLES)
    {
        auto opt = reinterpret_cast<const MachDawnNativeAdapterDiscoveryOptions_OpenGLES*>(options);
        dawn_native::opengl::AdapterDiscoveryOptionsES adapterOptions;
        adapterOptions.getProc = opt->getProc;
        return self->DiscoverAdapters(&adapterOptions);
    }
    #endif
    case WGPUBackendType_WebGPU:
    case WGPUBackendType_D3D11:
    case WGPUBackendType_D3D12:
    case WGPUBackendType_Metal:
    case WGPUBackendType_Null:
    case WGPUBackendType_Vulkan:
    case WGPUBackendType_Force32:
        return false;
    }
}
MACH_EXPORT MachDawnNativeAdapters machDawnNativeInstance_getAdapters(MachDawnNativeInstance instance) {
    dawn_native::Instance* self = reinterpret_cast<dawn_native::Instance*>(instance);
    auto cppAdapters = self->GetAdapters();
    auto heapAllocated = new std::vector<dawn_native::Adapter>();
    for (int i=0; i<cppAdapters.size(); i++) heapAllocated->push_back(cppAdapters[i]);
    return reinterpret_cast<MachDawnNativeAdapters>(heapAllocated);
}

MACH_EXPORT const DawnProcTable* machDawnNativeGetProcs() {
    return &dawn_native::GetProcs();
}

// TODO(dawn-native-mach):
// const ToggleInfo* GetToggleInfo(const char* toggleName);

// TODO(dawn-native-mach):
// // Enables backend validation layers
// void EnableBackendValidation(bool enableBackendValidation);
// void SetBackendValidationLevel(BackendValidationLevel validationLevel);

// TODO(dawn-native-mach):
// // Enable debug capture on Dawn startup
// void EnableBeginCaptureOnStartup(bool beginCaptureOnStartup);

// TODO(dawn-native-mach):
// void SetPlatform(dawn_platform::Platform* platform);

// TODO(dawn-native-mach):
// // Returns the underlying WGPUInstance object.
// WGPUInstance Get() const;


// typedef struct MachUtilsBackendBindingImpl* MachUtilsBackendBinding;
MACH_EXPORT MachUtilsBackendBinding machUtilsCreateBinding(WGPUBackendType backendType, GLFWwindow* window, WGPUDevice device) {
    wgpu::BackendType cppBackendType;
    switch (backendType) {
    case WGPUBackendType_WebGPU:
        cppBackendType = wgpu::BackendType::WebGPU;
        break;
    case WGPUBackendType_D3D11:
        cppBackendType = wgpu::BackendType::D3D11;
        break;
    case WGPUBackendType_D3D12:
        cppBackendType = wgpu::BackendType::D3D12;
        break;
    case WGPUBackendType_Metal:
        cppBackendType = wgpu::BackendType::Metal;
        break;
    case WGPUBackendType_Null:
        cppBackendType = wgpu::BackendType::Null;
        break;
    case WGPUBackendType_OpenGL:
        cppBackendType = wgpu::BackendType::OpenGL;
        break;
    case WGPUBackendType_OpenGLES:
        cppBackendType = wgpu::BackendType::OpenGLES;
        break;
    case WGPUBackendType_Vulkan:
        cppBackendType = wgpu::BackendType::Vulkan;
        break;
    case WGPUBackendType_Force32:
        // Force32 is just to force the size of the C enum type to 32-bits, so this is technically
        // an illegal input.
        cppBackendType = wgpu::BackendType::Null;
        break;
    }
    return reinterpret_cast<MachUtilsBackendBinding>(utils::CreateBinding(cppBackendType, window, device));
}

MACH_EXPORT uint64_t machUtilsBackendBinding_getSwapChainImplementation(MachUtilsBackendBinding binding) {
    auto self = reinterpret_cast<utils::BackendBinding*>(binding);
    return self->GetSwapChainImplementation();
}
MACH_EXPORT WGPUTextureFormat machUtilsBackendBinding_getPreferredSwapChainTextureFormat(MachUtilsBackendBinding binding) {
    auto self = reinterpret_cast<utils::BackendBinding*>(binding);
    return self->GetPreferredSwapChainTextureFormat();
}

#ifdef __cplusplus
} // extern "C"
#endif