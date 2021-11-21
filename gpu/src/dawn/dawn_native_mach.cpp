#include <dawn_native/DawnNative.h>
#include <dawn_native/wgpu_structs_autogen.h>
#include "utils/BackendBinding.h"

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
MACH_EXPORT WGPUDevice machDawnNativeAdapter_createDevice(MachDawnNativeAdapter adapter, MachDawnNativeDeviceDescriptor* deviceDescriptor) {
    auto self = reinterpret_cast<dawn_native::Adapter*>(adapter);

    if (deviceDescriptor == nullptr) {
        return self->CreateDevice(nullptr);
    }

    std::vector<const char*> cppRequiredExtensions;
    for (int i = 0; i < deviceDescriptor->requiredExtensionsLength; i++)
        cppRequiredExtensions.push_back(deviceDescriptor->requiredExtensions[i]);

    std::vector<const char*> cppForceEnabledToggles;
    for (int i = 0; i < deviceDescriptor->forceEnabledTogglesLength; i++)
        cppForceEnabledToggles.push_back(deviceDescriptor->forceEnabledToggles[i]);

    std::vector<const char*> cppForceDisabledToggles;
    for (int i = 0; i < deviceDescriptor->forceDisabledTogglesLength; i++)
        cppForceDisabledToggles.push_back(deviceDescriptor->forceDisabledToggles[i]);

    auto cppDeviceDescriptor = dawn_native::DeviceDescriptor{
        .requiredExtensions = cppRequiredExtensions,
        .forceEnabledToggles = cppForceEnabledToggles,
        .forceDisabledToggles = cppForceDisabledToggles,
        .requiredLimits = deviceDescriptor->requiredLimits,
    };
    return self->CreateDevice(&cppDeviceDescriptor);
}

// TODO(dawn-native-mach):
//     // An optional parameter of Adapter::CreateDevice() to send additional information when creating
//     // a Device. For example, we can use it to enable a workaround, optimization or feature.
//     struct DAWN_NATIVE_EXPORT DeviceDescriptor {
//         std::vector<const char*> requiredExtensions;
//         std::vector<const char*> forceEnabledToggles;
//         std::vector<const char*> forceDisabledToggles;

//         const WGPURequiredLimits* requiredLimits = nullptr;
//     };


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
MACH_EXPORT void machDawnNativeInstance_discoverDefaultAdapters(MachDawnNativeInstance instance) {
    dawn_native::Instance* self = reinterpret_cast<dawn_native::Instance*>(instance);
    self->DiscoverDefaultAdapters();
}
// TODO(dawn-native-mach):
// // Adds adapters that can be discovered with the options provided (like a getProcAddress).
// // The backend is chosen based on the type of the options used. Returns true on success.
// bool DiscoverAdapters(const AdapterDiscoveryOptionsBase* options);
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

// TODO(dawn-native-mach): everything below here is not wrapped

// #ifndef DAWNNATIVE_DAWNNATIVE_H_
// #define DAWNNATIVE_DAWNNATIVE_H_

// #include <dawn/dawn_proc_table.h>
// #include <dawn/webgpu.h>
// #include <dawn_native/dawn_native_export.h>

// #include <string>
// #include <vector>

// namespace dawn_platform {
//     class Platform;
// }  // namespace dawn_platform

// namespace wgpu {
//     struct AdapterProperties;
// }

// namespace dawn_native {

//     // DEPRECATED: use WGPUAdapterProperties instead.
//     struct PCIInfo {
//         uint32_t deviceId = 0;
//         uint32_t vendorId = 0;
//         std::string name;
//     };

//     // DEPRECATED: use WGPUBackendType instead.
//     enum class BackendType {
//         D3D12,
//         Metal,
//         Null,
//         OpenGL,
//         OpenGLES,
//         Vulkan,
//     };

//     // DEPRECATED: use WGPUAdapterType instead.
//     enum class DeviceType {
//         DiscreteGPU,
//         IntegratedGPU,
//         CPU,
//         Unknown,
//     };

//     class InstanceBase;
//     class AdapterBase;

//     // A struct to record the information of a toggle. A toggle is a code path in Dawn device that
//     // can be manually configured to run or not outside Dawn, including workarounds, special
//     // features and optimizations.
//     struct ToggleInfo {
//         const char* name;
//         const char* description;
//         const char* url;
//     };

//     // A struct to record the information of an extension. An extension is a GPU feature that is not
//     // required to be supported by all Dawn backends and can only be used when it is enabled on the
//     // creation of device.
//     using ExtensionInfo = ToggleInfo;

//     // Base class for options passed to Instance::DiscoverAdapters.
//     struct DAWN_NATIVE_EXPORT AdapterDiscoveryOptionsBase {
//       public:
//         const WGPUBackendType backendType;

//       protected:
//         AdapterDiscoveryOptionsBase(WGPUBackendType type);
//     };

//     enum BackendValidationLevel { Full, Partial, Disabled };

//     class DAWN_NATIVE_EXPORT Instance {
//     };

//     // Query the names of all the toggles that are enabled in device
//     DAWN_NATIVE_EXPORT std::vector<const char*> GetTogglesUsed(WGPUDevice device);

//     // Backdoor to get the number of lazy clears for testing
//     DAWN_NATIVE_EXPORT size_t GetLazyClearCountForTesting(WGPUDevice device);

//     // Backdoor to get the number of deprecation warnings for testing
//     DAWN_NATIVE_EXPORT size_t GetDeprecationWarningCountForTesting(WGPUDevice device);

//     //  Query if texture has been initialized
//     DAWN_NATIVE_EXPORT bool IsTextureSubresourceInitialized(
//         WGPUTexture texture,
//         uint32_t baseMipLevel,
//         uint32_t levelCount,
//         uint32_t baseArrayLayer,
//         uint32_t layerCount,
//         WGPUTextureAspect aspect = WGPUTextureAspect_All);

//     // Backdoor to get the order of the ProcMap for testing
//     DAWN_NATIVE_EXPORT std::vector<const char*> GetProcMapNamesForTesting();

//     DAWN_NATIVE_EXPORT bool DeviceTick(WGPUDevice device);

//     // ErrorInjector functions used for testing only. Defined in dawn_native/ErrorInjector.cpp
//     DAWN_NATIVE_EXPORT void EnableErrorInjector();
//     DAWN_NATIVE_EXPORT void DisableErrorInjector();
//     DAWN_NATIVE_EXPORT void ClearErrorInjector();
//     DAWN_NATIVE_EXPORT uint64_t AcquireErrorInjectorCallCount();
//     DAWN_NATIVE_EXPORT void InjectErrorAt(uint64_t index);

//     // The different types of external images
//     enum ExternalImageType {
//         OpaqueFD,
//         DmaBuf,
//         IOSurface,
//         DXGISharedHandle,
//         EGLImage,
//     };

//     // Common properties of external images
//     struct DAWN_NATIVE_EXPORT ExternalImageDescriptor {
//       public:
//         const ExternalImageType type;
//         const WGPUTextureDescriptor* cTextureDescriptor;  // Must match image creation params
//         bool isInitialized;  // Whether the texture is initialized on import

//       protected:
//         ExternalImageDescriptor(ExternalImageType type);
//     };

//     struct DAWN_NATIVE_EXPORT ExternalImageAccessDescriptor {
//       public:
//         bool isInitialized;  // Whether the texture is initialized on import
//         WGPUTextureUsageFlags usage;
//     };

//     struct DAWN_NATIVE_EXPORT ExternalImageExportInfo {
//       public:
//         const ExternalImageType type;
//         bool isInitialized;  // Whether the texture is initialized after export

//       protected:
//         ExternalImageExportInfo(ExternalImageType type);
//     };

//     DAWN_NATIVE_EXPORT const char* GetObjectLabelForTesting(void* objectHandle);

//     DAWN_NATIVE_EXPORT uint64_t GetAllocatedSizeForTesting(WGPUBuffer buffer);

//     DAWN_NATIVE_EXPORT bool BindGroupLayoutBindingsEqualForTesting(WGPUBindGroupLayout a,
//                                                                    WGPUBindGroupLayout b);

// }  // namespace dawn_native

// #endif  // DAWNNATIVE_DAWNNATIVE_H_
