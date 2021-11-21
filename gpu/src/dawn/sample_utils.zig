const std = @import("std");
const assert = std.debug.assert;
const glfw = @import("glfw");
const c = @import("c.zig").c;

// #include "SampleUtils.h"

// #include "common/Assert.h"
// #include "common/Log.h"
// #include "common/Platform.h"
// #include "common/SystemUtils.h"
// #include "utils/BackendBinding.h"
// #include "utils/GLFWUtils.h"
// #include "utils/TerribleCommandBuffer.h"

// #include <dawn/dawn_proc.h>
// #include <dawn/dawn_wsi.h>
// #include <dawn_native/DawnNative.h>
// #include <dawn_wire/WireClient.h>
// #include <dawn_wire/WireServer.h>
// #include "GLFW/glfw3.h"

// #include <algorithm>
// #include <cstring>

fn printDeviceError(error_type: c.WGPUErrorType, message: [*c]const u8, _: ?*c_void) callconv(.C) void {
    switch (error_type) {
        c.WGPUErrorType_Validation => std.debug.print("dawn: validation error: {s}\n", .{message}),
        c.WGPUErrorType_OutOfMemory => std.debug.print("dawn: out of memory: {s}\n", .{message}),
        c.WGPUErrorType_Unknown => std.debug.print("dawn: unknown error: {s}\n", .{message}),
        c.WGPUErrorType_DeviceLost => std.debug.print("dawn: device lost: {s}\n", .{message}),
        else => unreachable,
    }
}

// // Default to D3D12, Metal, Vulkan, OpenGL in that order as D3D12 and Metal are the preferred on
// // their respective platforms, and Vulkan is preferred to OpenGL
// #if defined(DAWN_ENABLE_BACKEND_D3D12)
// static wgpu::BackendType backendType = wgpu::BackendType::D3D12;
// #elif defined(DAWN_ENABLE_BACKEND_METAL)
// static wgpu::BackendType backendType = wgpu::BackendType::Metal;
// #elif defined(DAWN_ENABLE_BACKEND_VULKAN)
// static wgpu::BackendType backendType = wgpu::BackendType::Vulkan;
// #elif defined(DAWN_ENABLE_BACKEND_OPENGLES)
// static wgpu::BackendType backendType = wgpu::BackendType::OpenGLES;
// #elif defined(DAWN_ENABLE_BACKEND_DESKTOP_GL)
// static wgpu::BackendType backendType = wgpu::BackendType::OpenGL;
// #else
// #    error
// #endif

const CmdBufType = enum { none, terrible };

// static std::unique_ptr<dawn_native::Instance> instance;
// static utils::BackendBinding* binding = nullptr;

// static GLFWwindow* window = nullptr;

// static dawn_wire::WireServer* wireServer = nullptr;
// static dawn_wire::WireClient* wireClient = nullptr;
// static utils::TerribleCommandBuffer* c2sBuf = nullptr;
// static utils::TerribleCommandBuffer* s2cBuf = nullptr;

const Setup = struct {
    device: c.WGPUDevice,
    binding: c.MachUtilsBackendBinding,
    window: glfw.Window,
};

pub fn setup() !Setup {
    const backend_type = c.WGPUBackendType_Metal;
    const cmd_buf_type = CmdBufType.none;

    try glfw.init(.{});

    // Create the test window and discover adapters using it (esp. for OpenGL)
    var hints = glfwWindowHintsForBackend(backend_type);
    hints.cocoa_retina_framebuffer = false;
    const window = try glfw.Window.create(640, 480, "Dawn window", null, null, hints);

    const instance = c.machDawnNativeInstance_init();
    try discoverAdapter(instance, window, backend_type);

    const adapters = c.machDawnNativeInstance_getAdapters(instance);
    var backend_adapter: ?c.MachDawnNativeAdapter = null;
    var i: usize = 0;
    while (i < c.machDawnNativeAdapters_length(adapters)) : (i += 1) {
        const adapter = c.machDawnNativeAdapters_index(adapters, i);
        const properties = c.machDawnNativeAdapter_getProperties(adapter);
        if (c.machDawnNativeAdapterProperties_getBackendType(properties) == backend_type) {
            backend_adapter = adapter;
        }
    }
    assert(backend_adapter != null);

    const backend_device = c.machDawnNativeAdapter_createDevice(backend_adapter.?, null);
    const backend_procs = c.machDawnNativeGetProcs();

    const binding = c.machUtilsCreateBinding(backend_type, @ptrCast(*c.GLFWwindow, window.handle), backend_device);
    if (binding == null) {
        @panic("failed to create binding");
    }

    // Choose whether to use the backend procs and devices directly, or set up the wire.
    var procs: ?*const c.DawnProcTable = null;
    var c_device: ?c.WGPUDevice = null;
    switch (cmd_buf_type) {
        CmdBufType.none => {
            procs = backend_procs;
            c_device = backend_device;
        },
        CmdBufType.terrible => {
            // TODO(slimsag):
            @panic("not implemented");
            // c2sBuf = new utils::TerribleCommandBuffer();
            // s2cBuf = new utils::TerribleCommandBuffer();

            // dawn_wire::WireServerDescriptor serverDesc = {};
            // serverDesc.procs = &backendProcs;
            // serverDesc.serializer = s2cBuf;

            // wireServer = new dawn_wire::WireServer(serverDesc);
            // c2sBuf->SetHandler(wireServer);

            // dawn_wire::WireClientDescriptor clientDesc = {};
            // clientDesc.serializer = c2sBuf;

            // wireClient = new dawn_wire::WireClient(clientDesc);
            // procs = dawn_wire::client::GetProcs();
            // s2cBuf->SetHandler(wireClient);

            // auto deviceReservation = wireClient->ReserveDevice();
            // wireServer->InjectDevice(backendDevice, deviceReservation.id,
            //                             deviceReservation.generation);

            // cDevice = deviceReservation.device;
        },
    }

    c.dawnProcSetProcs(procs.?);
    procs.?.deviceSetUncapturedErrorCallback.?(c_device.?, printDeviceError, null);
    return Setup{
        .device = c_device.?,
        .binding = binding,
        .window = window,
    };
}

fn glfwWindowHintsForBackend(backend: c.WGPUBackendType) glfw.Window.Hints {
    return switch (backend) {
        c.WGPUBackendType_OpenGL => .{
            // Ask for OpenGL 4.4 which is what the GL backend requires for compute shaders and
            // texture views.
            .context_version_major = 4,
            .context_version_minor = 4,
            .opengl_forward_compat = true,
            .opengl_profile = .opengl_core_profile,
        },
        c.WGPUBackendType_OpenGLES => .{
            .context_version_major = 3,
            .context_version_minor = 1,
            .client_api = .opengl_es_api,
            .context_creation_api = .egl_context_api,
        },
        else => .{
            // Without this GLFW will initialize a GL context on the window, which prevents using
            // the window with other APIs (by crashing in weird ways).
            .client_api = .no_api,
        },
    };
}

fn discoverAdapter(instance: c.MachDawnNativeInstance, window: glfw.Window, typ: c.WGPUBackendType) !void {
    if (typ == c.WGPUBackendType_OpenGL or typ == c.WGPUBackendType_OpenGLES) {
        try glfw.makeContextCurrent(window);
        // auto getProc = reinterpret_cast<void* (*)(const char*)>(glfwGetProcAddress);
        // if (type == wgpu::BackendType::OpenGL) {
        //     dawn_native::opengl::AdapterDiscoveryOptions adapterOptions;
        //     adapterOptions.getProc = getProc;
        //     instance->DiscoverAdapters(&adapterOptions);
        // } else {
        //     dawn_native::opengl::AdapterDiscoveryOptionsES adapterOptions;
        //     adapterOptions.getProc = getProc;
        //     instance->DiscoverAdapters(&adapterOptions);
        // }
    } else {
        c.machDawnNativeInstance_discoverDefaultAdapters(instance);
    }
}

// wgpu::TextureFormat GetPreferredSwapChainTextureFormat() {
//     DoFlush();
//     return static_cast<wgpu::TextureFormat>(binding->GetPreferredSwapChainTextureFormat());
// }

// wgpu::TextureView CreateDefaultDepthStencilView(const wgpu::Device& device) {
//     wgpu::TextureDescriptor descriptor;
//     descriptor.dimension = wgpu::TextureDimension::e2D;
//     descriptor.size.width = 640;
//     descriptor.size.height = 480;
//     descriptor.size.depthOrArrayLayers = 1;
//     descriptor.sampleCount = 1;
//     descriptor.format = wgpu::TextureFormat::Depth24PlusStencil8;
//     descriptor.mipLevelCount = 1;
//     descriptor.usage = wgpu::TextureUsage::RenderAttachment;
//     auto depthStencilTexture = device.CreateTexture(&descriptor);
//     return depthStencilTexture.CreateView();
// }

// bool InitSample(int argc, const char** argv) {
//     for (int i = 1; i < argc; i++) {
//         if (std::string("-b") == argv[i] || std::string("--backend") == argv[i]) {
//             i++;
//             if (i < argc && std::string("d3d12") == argv[i]) {
//                 backendType = wgpu::BackendType::D3D12;
//                 continue;
//             }
//             if (i < argc && std::string("metal") == argv[i]) {
//                 backendType = wgpu::BackendType::Metal;
//                 continue;
//             }
//             if (i < argc && std::string("null") == argv[i]) {
//                 backendType = wgpu::BackendType::Null;
//                 continue;
//             }
//             if (i < argc && std::string("opengl") == argv[i]) {
//                 backendType = wgpu::BackendType::OpenGL;
//                 continue;
//             }
//             if (i < argc && std::string("opengles") == argv[i]) {
//                 backendType = wgpu::BackendType::OpenGLES;
//                 continue;
//             }
//             if (i < argc && std::string("vulkan") == argv[i]) {
//                 backendType = wgpu::BackendType::Vulkan;
//                 continue;
//             }
//             fprintf(stderr,
//                     "--backend expects a backend name (opengl, opengles, metal, d3d12, null, "
//                     "vulkan)\n");
//             return false;
//         }
//         if (std::string("-c") == argv[i] || std::string("--command-buffer") == argv[i]) {
//             i++;
//             if (i < argc && std::string("none") == argv[i]) {
//                 cmdBufType = CmdBufType::None;
//                 continue;
//             }
//             if (i < argc && std::string("terrible") == argv[i]) {
//                 cmdBufType = CmdBufType::Terrible;
//                 continue;
//             }
//             fprintf(stderr, "--command-buffer expects a command buffer name (none, terrible)\n");
//             return false;
//         }
//         if (std::string("-h") == argv[i] || std::string("--help") == argv[i]) {
//             printf("Usage: %s [-b BACKEND] [-c COMMAND_BUFFER]\n", argv[0]);
//             printf("  BACKEND is one of: d3d12, metal, null, opengl, opengles, vulkan\n");
//             printf("  COMMAND_BUFFER is one of: none, terrible\n");
//             return false;
//         }
//     }
//     return true;
// }
