#ifndef MACH_DAWNNATIVE_C_H_
#define MACH_DAWNNATIVE_C_H_

#ifdef __cplusplus
extern "C" {
#endif

#if defined(MACH_DAWNNATIVE_C_SHARED_LIBRARY)
#    if defined(_WIN32)
#        if defined(MACH_DAWNNATIVE_C_IMPLEMENTATION)
#            define MACH_EXPORT __declspec(dllexport)
#        else
#            define MACH_EXPORT __declspec(dllimport)
#        endif
#    else  // defined(_WIN32)
#        if defined(MACH_DAWNNATIVE_C_IMPLEMENTATION)
#            define MACH_EXPORT __attribute__((visibility("default")))
#        else
#            define MACH_EXPORT
#        endif
#    endif  // defined(_WIN32)
#else       // defined(MACH_DAWNNATIVE_C_SHARED_LIBRARY)
#    define MACH_EXPORT
#endif  // defined(MACH_DAWNNATIVE_C_SHARED_LIBRARY)

#include <dawn/webgpu.h>
#include <dawn/dawn_proc_table.h>

// TODO(slimsag): future: Dawn authors want dawn_native::AdapterProperties to eventually be in webgpu.h,
// and there is a corresponding WGPUAdapterProperties struct today, but there aren't corresponding methods
// to actually use / work with it today.
typedef struct MachDawnNativeAdapterPropertiesImpl* MachDawnNativeAdapterProperties;

MACH_EXPORT void machDawnNativeAdapterProperties_deinit(MachDawnNativeAdapterProperties properties);
MACH_EXPORT uint32_t machDawnNativeAdapterProperties_getVendorID(MachDawnNativeAdapterProperties properties);
MACH_EXPORT uint32_t machDawnNativeAdapterProperties_getDeviceID(MachDawnNativeAdapterProperties properties);
MACH_EXPORT char const* machDawnNativeAdapterProperties_getName(MachDawnNativeAdapterProperties properties);
MACH_EXPORT char const* machDawnNativeAdapterProperties_getDriverDescription(MachDawnNativeAdapterProperties properties);
MACH_EXPORT WGPUAdapterType machDawnNativeAdapterProperties_getAdapterType(MachDawnNativeAdapterProperties properties);
MACH_EXPORT WGPUBackendType machDawnNativeAdapterProperties_getBackendType(MachDawnNativeAdapterProperties properties);

// An adapter is an object that represent on possibility of creating devices in the system.
// Most of the time it will represent a combination of a physical GPU and an API. Not that the
// same GPU can be represented by multiple adapters but on different APIs.
//
// The underlying Dawn adapter is owned by the Dawn instance so this is just a reference to an
// underlying adapter.
typedef struct MachDawnNativeAdapterImpl* MachDawnNativeAdapter;

MACH_EXPORT MachDawnNativeAdapterProperties machDawnNativeAdapter_getProperties(MachDawnNativeAdapter adapter);

// An optional parameter of Adapter::CreateDevice() to send additional information when creating
// a Device. For example, we can use it to enable a workaround, optimization or feature.
typedef struct MachDawnNativeDawnDeviceDescriptor {
    char** requiredFeatures;
    uintptr_t requiredFeaturesLength;

    char** forceEnabledToggles;
    uintptr_t forceEnabledTogglesLength;

    char** forceDisabledToggles;
    uintptr_t forceDisabledTogglesLength;

    // default null
    WGPURequiredLimits* requiredLimits;
} MachDawnNativeDawnDeviceDescriptor;
MACH_EXPORT WGPUDevice machDawnNativeAdapter_createDevice(MachDawnNativeAdapter adapter, MachDawnNativeDawnDeviceDescriptor* deviceDescriptor);

typedef struct MachDawnNativeAdaptersImpl* MachDawnNativeAdapters;
MACH_EXPORT MachDawnNativeAdapter machDawnNativeAdapters_index(MachDawnNativeAdapters adapters, uintptr_t index);
MACH_EXPORT uintptr_t machDawnNativeAdapters_length(MachDawnNativeAdapters adapters);

// Represents a connection to dawn_native and is used for dependency injection, discovering
// system adapters and injecting custom adapters (like a Swiftshader Vulkan adapter).
//
// This can be initialized via machDawnNativeInstanceInit and destroyed via
// machDawnNativeInstanceDeinit. The instance controls the lifetime of all adapters for the
// instance.
typedef struct MachDawnNativeInstanceImpl* MachDawnNativeInstance;

MACH_EXPORT MachDawnNativeInstance machDawnNativeInstance_init(void);
MACH_EXPORT void machDawnNativeInstance_deinit(MachDawnNativeInstance);
MACH_EXPORT void machDawnNativeInstance_discoverDefaultAdapters(MachDawnNativeInstance);

// Adds adapters that can be discovered with the options provided (like a getProcAddress).
// You must specify a valid backend type corresponding to the type of MachDawnNativeAdapterDiscoveryOptions_
// struct pointer you pass as options.
// Returns true on success.
MACH_EXPORT bool machDawnNativeInstance_discoverAdapters(MachDawnNativeInstance instance, WGPUBackendType backendType, const void* options);

MACH_EXPORT MachDawnNativeAdapters machDawnNativeInstance_getAdapters(MachDawnNativeInstance instance);

// Backend-agnostic API for dawn_native
MACH_EXPORT const DawnProcTable* machDawnNativeGetProcs();

// Backend-specific options which can be passed to discoverAdapters
typedef struct MachDawnNativeAdapterDiscoveryOptions_OpenGL {
    void* (*getProc)(const char*);
} MachDawnNativeAdapterDiscoveryOptions_OpenGL;
typedef struct MachDawnNativeAdapterDiscoveryOptions_OpenGLES {
    void* (*getProc)(const char*);
} MachDawnNativeAdapterDiscoveryOptions_OpenGLES;

// utils
#include <GLFW/glfw3.h>

typedef struct MachUtilsBackendBindingImpl* MachUtilsBackendBinding;
MACH_EXPORT MachUtilsBackendBinding machUtilsCreateBinding(WGPUBackendType backendType, GLFWwindow* window, WGPUDevice device);
MACH_EXPORT uint64_t machUtilsBackendBinding_getSwapChainImplementation(MachUtilsBackendBinding binding);
MACH_EXPORT WGPUTextureFormat machUtilsBackendBinding_getPreferredSwapChainTextureFormat(MachUtilsBackendBinding binding);

#ifdef __cplusplus
} // extern "C"
#endif

#endif  // MACH_DAWNNATIVE_C_H_
