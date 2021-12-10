const std = @import("std");
const Builder = std.build.Builder;
const glfw = @import("libs/mach-glfw/build.zig");
const system_sdk = @import("libs/mach-glfw/system_sdk.zig");

pub const LinuxWindowManager = enum {
    X11,
    Wayland,
};

pub const Options = struct {
    /// Defaults to X11 on Linux.
    linux_window_manager: ?LinuxWindowManager = null,

    /// Defaults to true on Windows
    d3d12: ?bool = null,

    /// Defaults to true on Darwin
    metal: ?bool = null,

    /// Defaults to true on Linux, Fuchsia
    // TODO(build-system): enable on Windows if we can cross compile Vulkan
    vulkan: ?bool = null,

    /// Defaults to true on Windows, Linux
    // TODO(build-system): not respected at all currently
    desktop_gl: ?bool = null,

    /// Defaults to true on Android, Linux, Windows, Emscripten
    // TODO(build-system): not respected at all currently
    opengl_es: ?bool = null,

    /// Whether or not minimal debug symbols should be emitted. This is -g1 in most cases, enough to
    /// produce stack traces but omitting debug symbols for locals. For spirv-tools and tint in
    /// specific, -g0 will be used (no debug symbols at all) to save an additional ~39M.
    ///
    /// When enabled, a debug build of the static library goes from ~947M to just ~53M.
    minimal_debug_symbols: bool = true,

    /// Detects the default options to use for the given target.
    pub fn detectDefaults(self: Options, target: std.Target) Options {
        const tag = target.os.tag;
        const linux_desktop_like = isLinuxDesktopLike(target);

        var options = self;
        if (options.linux_window_manager == null and linux_desktop_like) options.linux_window_manager = .X11;
        if (options.d3d12 == null) options.d3d12 = tag == .windows;
        if (options.metal == null) options.metal = tag.isDarwin();
        if (options.vulkan == null) options.vulkan = tag == .fuchsia or linux_desktop_like;

        // TODO(build-system): respect these options / defaults
        if (options.desktop_gl == null) options.desktop_gl = linux_desktop_like; // TODO(build-system): add windows
        options.opengl_es = false;
        // if (options.opengl_es == null) options.opengl_es = tag == .windows or tag == .emscripten or target.isAndroid() or linux_desktop_like;
        return options;
    }

    pub fn appendFlags(self: Options, flags: *std.ArrayList([]const u8), zero_debug_symbols: bool) !void {
        if (self.minimal_debug_symbols) {
            if (zero_debug_symbols) try flags.append("-g0") else try flags.append("-g1");
        }
    }
};

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    const opt = options.detectDefaults(target);

    const lib_mach_dawn_native = buildLibMachDawnNative(b, step, opt);
    step.linkLibrary(lib_mach_dawn_native);

    const lib_dawn_common = buildLibDawnCommon(b, step, opt);
    step.linkLibrary(lib_dawn_common);

    const lib_dawn_platform = buildLibDawnPlatform(b, step, opt);
    step.linkLibrary(lib_dawn_platform);

    // dawn-native
    const lib_abseil_cpp = buildLibAbseilCpp(b, step, opt);
    step.linkLibrary(lib_abseil_cpp);
    const lib_dawn_native = buildLibDawnNative(b, step, opt);
    step.linkLibrary(lib_dawn_native);

    const lib_dawn_wire = buildLibDawnWire(b, step, opt);
    step.linkLibrary(lib_dawn_wire);

    const lib_dawn_utils = buildLibDawnUtils(b, step, opt);
    step.linkLibrary(lib_dawn_utils);

    const lib_spirv_tools = buildLibSPIRVTools(b, step, opt);
    step.linkLibrary(lib_spirv_tools);

    const lib_tint = buildLibTint(b, step, opt);
    step.linkLibrary(lib_tint);
}

fn isLinuxDesktopLike(target: std.Target) bool {
    const tag = target.os.tag;
    return !tag.isDarwin() and tag != .windows and tag != .fuchsia and tag != .emscripten and !target.isAndroid();
}

fn buildLibMachDawnNative(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-native-mach", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    // TODO(build-system): pass system SDK options through
    glfw.link(b, lib, .{ .system_sdk = .{ .set_sysroot = false } });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    flags.appendSlice(&.{
        include("libs/mach-glfw/upstream/glfw/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/src"),
    }) catch unreachable;

    lib.addCSourceFile("src/dawn/dawn_native_mach.cpp", flags.items);
    return lib;
}

// Builds common sources; derived from src/common/BUILD.gn
fn buildLibDawnCommon(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-common", main_abs);
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.append(include("libs/dawn/src")) catch unreachable;

    for ([_][]const u8{
        "src/common/Assert.cpp",
        "src/common/DynamicLib.cpp",
        "src/common/GPUInfo.cpp",
        "src/common/Log.cpp",
        "src/common/Math.cpp",
        "src/common/RefCounted.cpp",
        "src/common/Result.cpp",
        "src/common/SlabAllocator.cpp",
        "src/common/SystemUtils.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag == .macos) {
        // TODO(build-system): pass system SDK options through
        system_sdk.include(b, lib, .{});
        lib.linkFramework("Foundation");
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn/src/common/SystemUtils_mac.mm" }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }
    return lib;
}

// Build dawn platform sources; derived from src/dawn_platform/BUILD.gn
fn buildLibDawnPlatform(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-platform", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),

        include("libs/dawn/out/Debug/gen/src/include"),
    }) catch unreachable;

    for ([_][]const u8{
        "src/dawn_platform/DawnPlatform.cpp",
        "src/dawn_platform/WorkerThread.cpp",
        "src/dawn_platform/tracing/EventTracer.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }
    return lib;
}

fn appendDawnEnableBackendTypeFlags(flags: *std.ArrayList([]const u8), options: Options) !void {
    const d3d12 = "-DDAWN_ENABLE_BACKEND_D3D12";
    const metal = "-DDAWN_ENABLE_BACKEND_METAL";
    const vulkan = "-DDAWN_ENABLE_BACKEND_VULKAN";
    const opengl = "-DDAWN_ENABLE_BACKEND_OPENGL";
    const desktop_gl = "-DDAWN_ENABLE_BACKEND_DESKTOP_GL";
    const opengl_es = "-DDAWN_ENABLE_BACKEND_OPENGLES";
    const backend_null = "-DDAWN_ENABLE_BACKEND_NULL";

    try flags.append(backend_null);
    if (options.d3d12.?) try flags.append(d3d12);
    if (options.metal.?) try flags.append(metal);
    if (options.vulkan.?) try flags.append(vulkan);
    if (options.desktop_gl.?) try flags.appendSlice(&.{ opengl, desktop_gl });
    if (options.opengl_es.?) try flags.appendSlice(&.{ opengl, opengl_es });
}

// Builds dawn native sources; derived from src/dawn_native/BUILD.gn
fn buildLibDawnNative(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-native", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();
    system_sdk.include(b, lib, .{});

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    if (options.desktop_gl.?) {
        // OpenGL requires spriv-cross until Dawn moves OpenGL shader generation to Tint.
        flags.append(include("libs/dawn/third_party/vulkan-deps/spirv-cross/src")) catch unreachable;

        const lib_spirv_cross = buildLibSPIRVCross(b, step, options);
        step.linkLibrary(lib_spirv_cross);
    }
    flags.appendSlice(&.{
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/abseil-cpp"),
        include("libs/dawn/third_party/khronos"),

        // TODO(build-system): make these optional
        "-DTINT_BUILD_SPV_READER=1",
        "-DTINT_BUILD_SPV_WRITER=1",
        "-DTINT_BUILD_WGSL_READER=1",
        "-DTINT_BUILD_WGSL_WRITER=1",
        "-DTINT_BUILD_MSL_WRITER=1",
        "-DTINT_BUILD_HLSL_WRITER=1",
        include("libs/dawn/third_party/tint"),
        include("libs/dawn/third_party/tint/include"),

        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
    }) catch unreachable;

    for ([_][]const u8{
        "out/Debug/gen/src/dawn/dawn_thread_dispatch_proc.cpp",
        "out/Debug/gen/src/dawn/dawn_proc.c",
        "out/Debug/gen/src/dawn/webgpu_cpp.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    for ([_][]const u8{
        "src/dawn_native/Adapter.cpp",
        "src/dawn_native/AsyncTask.cpp",
        "src/dawn_native/AttachmentState.cpp",
        "src/dawn_native/BackendConnection.cpp",
        "src/dawn_native/BindGroup.cpp",
        "src/dawn_native/BindGroupLayout.cpp",
        "src/dawn_native/BindingInfo.cpp",
        "src/dawn_native/BuddyAllocator.cpp",
        "src/dawn_native/BuddyMemoryAllocator.cpp",
        "src/dawn_native/Buffer.cpp",
        "src/dawn_native/CachedObject.cpp",
        "src/dawn_native/CallbackTaskManager.cpp",
        "src/dawn_native/CommandAllocator.cpp",
        "src/dawn_native/CommandBuffer.cpp",
        "src/dawn_native/CommandBufferStateTracker.cpp",
        "src/dawn_native/CommandEncoder.cpp",
        "src/dawn_native/CommandValidation.cpp",
        "src/dawn_native/Commands.cpp",
        "src/dawn_native/CompilationMessages.cpp",
        "src/dawn_native/ComputePassEncoder.cpp",
        "src/dawn_native/ComputePipeline.cpp",
        "src/dawn_native/CopyTextureForBrowserHelper.cpp",
        "src/dawn_native/CreatePipelineAsyncTask.cpp",
        "src/dawn_native/Device.cpp",
        "src/dawn_native/DynamicUploader.cpp",
        "src/dawn_native/EncodingContext.cpp",
        "src/dawn_native/Error.cpp",
        "src/dawn_native/ErrorData.cpp",
        "src/dawn_native/ErrorInjector.cpp",
        "src/dawn_native/ErrorScope.cpp",
        "src/dawn_native/ExternalTexture.cpp",
        "src/dawn_native/Features.cpp",
        "src/dawn_native/Format.cpp",
        "src/dawn_native/IndirectDrawMetadata.cpp",
        "src/dawn_native/IndirectDrawValidationEncoder.cpp",
        "src/dawn_native/Instance.cpp",
        "src/dawn_native/InternalPipelineStore.cpp",
        "src/dawn_native/Limits.cpp",
        "src/dawn_native/ObjectBase.cpp",
        "src/dawn_native/ObjectContentHasher.cpp",
        "src/dawn_native/PassResourceUsageTracker.cpp",
        "src/dawn_native/PerStage.cpp",
        "src/dawn_native/PersistentCache.cpp",
        "src/dawn_native/Pipeline.cpp",
        "src/dawn_native/PipelineLayout.cpp",
        "src/dawn_native/PooledResourceMemoryAllocator.cpp",
        "src/dawn_native/ProgrammableEncoder.cpp",
        "src/dawn_native/QueryHelper.cpp",
        "src/dawn_native/QuerySet.cpp",
        "src/dawn_native/Queue.cpp",
        "src/dawn_native/RenderBundle.cpp",
        "src/dawn_native/RenderBundleEncoder.cpp",
        "src/dawn_native/RenderEncoderBase.cpp",
        "src/dawn_native/RenderPassEncoder.cpp",
        "src/dawn_native/RenderPipeline.cpp",
        "src/dawn_native/ResourceMemoryAllocation.cpp",
        "src/dawn_native/RingBufferAllocator.cpp",
        "src/dawn_native/Sampler.cpp",
        "src/dawn_native/ScratchBuffer.cpp",
        "src/dawn_native/ShaderModule.cpp",
        "src/dawn_native/StagingBuffer.cpp",
        "src/dawn_native/Subresource.cpp",
        "src/dawn_native/Surface.cpp",
        "src/dawn_native/SwapChain.cpp",
        "src/dawn_native/Texture.cpp",
        "src/dawn_native/TintUtils.cpp",
        "src/dawn_native/Toggles.cpp",
        "src/dawn_native/VertexFormat.cpp",
        "src/dawn_native/utils/WGPUHelpers.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // dawn_native_utils_gen
    for ([_][]const u8{
        "out/Debug/gen/src/dawn_native/ChainUtils_autogen.cpp",
        "out/Debug/gen/src/dawn_native/ProcTable.cpp",
        "out/Debug/gen/src/dawn_native/wgpu_structs_autogen.cpp",
        "out/Debug/gen/src/dawn_native/ValidationUtils_autogen.cpp",
        "out/Debug/gen/src/dawn_native/webgpu_absl_format_autogen.cpp",
        "out/Debug/gen/src/dawn_native/ObjectType_autogen.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // TODO(build-system): could allow enable_vulkan_validation_layers here. See src/dawn_native/BUILD.gn
    // TODO(build-system): allow use_angle here. See src/dawn_native/BUILD.gn
    // TODO(build-system): could allow use_swiftshader here. See src/dawn_native/BUILD.gn

    if (options.d3d12.?) {
        // TODO(build-system): windows
        //     libs += [ "dxguid.lib" ]
        for ([_][]const u8{
            "src/dawn_native/d3d12/AdapterD3D12.cpp",
            "src/dawn_native/d3d12/BackendD3D12.cpp",
            "src/dawn_native/d3d12/BindGroupD3D12.cpp",
            "src/dawn_native/d3d12/BindGroupLayoutD3D12.cpp",
            "src/dawn_native/d3d12/BufferD3D12.cpp",
            "src/dawn_native/d3d12/CPUDescriptorHeapAllocationD3D12.cpp",
            "src/dawn_native/d3d12/CommandAllocatorManager.cpp",
            "src/dawn_native/d3d12/CommandBufferD3D12.cpp",
            "src/dawn_native/d3d12/CommandRecordingContext.cpp",
            "src/dawn_native/d3d12/ComputePipelineD3D12.cpp",
            "src/dawn_native/d3d12/D3D11on12Util.cpp",
            "src/dawn_native/d3d12/D3D12Error.cpp",
            "src/dawn_native/d3d12/D3D12Info.cpp",
            "src/dawn_native/d3d12/DeviceD3D12.cpp",
            "src/dawn_native/d3d12/GPUDescriptorHeapAllocationD3D12.cpp",
            "src/dawn_native/d3d12/HeapAllocatorD3D12.cpp",
            "src/dawn_native/d3d12/HeapD3D12.cpp",
            "src/dawn_native/d3d12/NativeSwapChainImplD3D12.cpp",
            "src/dawn_native/d3d12/PageableD3D12.cpp",
            "src/dawn_native/d3d12/PipelineLayoutD3D12.cpp",
            "src/dawn_native/d3d12/PlatformFunctions.cpp",
            "src/dawn_native/d3d12/QuerySetD3D12.cpp",
            "src/dawn_native/d3d12/QueueD3D12.cpp",
            "src/dawn_native/d3d12/RenderPassBuilderD3D12.cpp",
            "src/dawn_native/d3d12/RenderPipelineD3D12.cpp",
            "src/dawn_native/d3d12/ResidencyManagerD3D12.cpp",
            "src/dawn_native/d3d12/ResourceAllocatorManagerD3D12.cpp",
            "src/dawn_native/d3d12/ResourceHeapAllocationD3D12.cpp",
            "src/dawn_native/d3d12/SamplerD3D12.cpp",
            "src/dawn_native/d3d12/SamplerHeapCacheD3D12.cpp",
            "src/dawn_native/d3d12/ShaderModuleD3D12.cpp",
            "src/dawn_native/d3d12/ShaderVisibleDescriptorAllocatorD3D12.cpp",
            "src/dawn_native/d3d12/StagingBufferD3D12.cpp",
            "src/dawn_native/d3d12/StagingDescriptorAllocatorD3D12.cpp",
            "src/dawn_native/d3d12/SwapChainD3D12.cpp",
            "src/dawn_native/d3d12/TextureCopySplitter.cpp",
            "src/dawn_native/d3d12/TextureD3D12.cpp",
            "src/dawn_native/d3d12/UtilsD3D12.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }
    if (options.metal.?) {
        lib.linkFramework("Metal");
        lib.linkFramework("CoreGraphics");
        lib.linkFramework("Foundation");
        lib.linkFramework("IOKit");
        lib.linkFramework("IOSurface");
        lib.linkFramework("QuartzCore");

        for ([_][]const u8{
            "src/dawn_native/metal/MetalBackend.mm",
            "src/dawn_native/Surface_metal.mm",
            "src/dawn_native/metal/BackendMTL.mm",
            "src/dawn_native/metal/BindGroupLayoutMTL.mm",
            "src/dawn_native/metal/BindGroupMTL.mm",
            "src/dawn_native/metal/BufferMTL.mm",
            "src/dawn_native/metal/CommandBufferMTL.mm",
            "src/dawn_native/metal/CommandRecordingContext.mm",
            "src/dawn_native/metal/ComputePipelineMTL.mm",
            "src/dawn_native/metal/DeviceMTL.mm",
            "src/dawn_native/metal/PipelineLayoutMTL.mm",
            "src/dawn_native/metal/QuerySetMTL.mm",
            "src/dawn_native/metal/QueueMTL.mm",
            "src/dawn_native/metal/RenderPipelineMTL.mm",
            "src/dawn_native/metal/SamplerMTL.mm",
            "src/dawn_native/metal/ShaderModuleMTL.mm",
            "src/dawn_native/metal/StagingBufferMTL.mm",
            "src/dawn_native/metal/SwapChainMTL.mm",
            "src/dawn_native/metal/TextureMTL.mm",
            "src/dawn_native/metal/UtilsMetal.mm",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }

    if (options.linux_window_manager != null and options.linux_window_manager.? == .X11) {
        lib.linkSystemLibrary("X11");
        for ([_][]const u8{
            "src/dawn_native/XlibXcbFunctions.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }

    for ([_][]const u8{
        "src/dawn_native/null/DeviceNull.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    if (options.desktop_gl.? or options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn_native/SpirvValidation.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }

    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "out/Debug/gen/src/dawn_native/opengl/OpenGLFunctionsBase_autogen.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }

        for ([_][]const u8{
            "src/dawn_native/opengl/BackendGL.cpp",
            "src/dawn_native/opengl/BindGroupGL.cpp",
            "src/dawn_native/opengl/BindGroupLayoutGL.cpp",
            "src/dawn_native/opengl/BufferGL.cpp",
            "src/dawn_native/opengl/CommandBufferGL.cpp",
            "src/dawn_native/opengl/ComputePipelineGL.cpp",
            "src/dawn_native/opengl/DeviceGL.cpp",
            "src/dawn_native/opengl/GLFormat.cpp",
            "src/dawn_native/opengl/NativeSwapChainImplGL.cpp",
            "src/dawn_native/opengl/OpenGLFunctions.cpp",
            "src/dawn_native/opengl/OpenGLVersion.cpp",
            "src/dawn_native/opengl/PersistentPipelineStateGL.cpp",
            "src/dawn_native/opengl/PipelineGL.cpp",
            "src/dawn_native/opengl/PipelineLayoutGL.cpp",
            "src/dawn_native/opengl/QuerySetGL.cpp",
            "src/dawn_native/opengl/QueueGL.cpp",
            "src/dawn_native/opengl/RenderPipelineGL.cpp",
            "src/dawn_native/opengl/SamplerGL.cpp",
            "src/dawn_native/opengl/ShaderModuleGL.cpp",
            "src/dawn_native/opengl/SpirvUtils.cpp",
            "src/dawn_native/opengl/SwapChainGL.cpp",
            "src/dawn_native/opengl/TextureGL.cpp",
            "src/dawn_native/opengl/UtilsGL.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn_native/vulkan/AdapterVk.cpp",
            "src/dawn_native/vulkan/BackendVk.cpp",
            "src/dawn_native/vulkan/BindGroupLayoutVk.cpp",
            "src/dawn_native/vulkan/BindGroupVk.cpp",
            "src/dawn_native/vulkan/BufferVk.cpp",
            "src/dawn_native/vulkan/CommandBufferVk.cpp",
            "src/dawn_native/vulkan/ComputePipelineVk.cpp",
            "src/dawn_native/vulkan/DescriptorSetAllocator.cpp",
            "src/dawn_native/vulkan/DeviceVk.cpp",
            "src/dawn_native/vulkan/FencedDeleter.cpp",
            "src/dawn_native/vulkan/NativeSwapChainImplVk.cpp",
            "src/dawn_native/vulkan/PipelineLayoutVk.cpp",
            "src/dawn_native/vulkan/QuerySetVk.cpp",
            "src/dawn_native/vulkan/QueueVk.cpp",
            "src/dawn_native/vulkan/RenderPassCache.cpp",
            "src/dawn_native/vulkan/RenderPipelineVk.cpp",
            "src/dawn_native/vulkan/ResourceHeapVk.cpp",
            "src/dawn_native/vulkan/ResourceMemoryAllocatorVk.cpp",
            "src/dawn_native/vulkan/SamplerVk.cpp",
            "src/dawn_native/vulkan/ShaderModuleVk.cpp",
            "src/dawn_native/vulkan/StagingBufferVk.cpp",
            "src/dawn_native/vulkan/SwapChainVk.cpp",
            "src/dawn_native/vulkan/TextureVk.cpp",
            "src/dawn_native/vulkan/UtilsVulkan.cpp",
            "src/dawn_native/vulkan/VulkanError.cpp",
            "src/dawn_native/vulkan/VulkanExtensions.cpp",
            "src/dawn_native/vulkan/VulkanFunctions.cpp",
            "src/dawn_native/vulkan/VulkanInfo.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }

        if (isLinuxDesktopLike(target)) {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceOpaqueFD.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceFD.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                lib.addCSourceFile(abs_path, flags.items);
            }
        } else if (target.os.tag == .fuchsia) {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceZirconHandle.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceZirconHandle.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                lib.addCSourceFile(abs_path, flags.items);
            }
        } else {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceNull.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceNull.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                lib.addCSourceFile(abs_path, flags.items);
            }
        }
    }

    // TODO(build-system): fuchsia: add is_fuchsia here from upstream source file

    if (options.vulkan.?) {
        // TODO(build-system): vulkan
        //     if (enable_vulkan_validation_layers) {
        //       defines += [
        //         "DAWN_ENABLE_VULKAN_VALIDATION_LAYERS",
        //         "DAWN_VK_DATA_DIR=\"$vulkan_data_subdir\"",
        //       ]
        //     }
        //     if (enable_vulkan_loader) {
        //       data_deps += [ "${dawn_vulkan_loader_dir}:libvulkan" ]
        //       defines += [ "DAWN_ENABLE_VULKAN_LOADER" ]
        //     }
    }
    // TODO(build-system): swiftshader
    //     if (use_swiftshader) {
    //       data_deps += [
    //         "${dawn_swiftshader_dir}/src/Vulkan:icd_file",
    //         "${dawn_swiftshader_dir}/src/Vulkan:swiftshader_libvulkan",
    //       ]
    //       defines += [
    //         "DAWN_ENABLE_SWIFTSHADER",
    //         "DAWN_SWIFTSHADER_VK_ICD_JSON=\"${swiftshader_icd_file_name}\"",
    //       ]
    //     }
    //   }

    if (options.opengl_es.?) {
        // TODO(build-system): gles
        //   if (use_angle) {
        //     data_deps += [
        //       "${dawn_angle_dir}:libEGL",
        //       "${dawn_angle_dir}:libGLESv2",
        //     ]
        //   }
        // }
    }

    for ([_][]const u8{
        "src/dawn_native/DawnNative.cpp",
        "src/dawn_native/null/NullBackend.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    if (options.d3d12.?) {
        for ([_][]const u8{
            "src/dawn_native/d3d12/D3D12Backend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }
    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "src/dawn_native/opengl/OpenGLBackend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }
    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn_native/vulkan/VulkanBackend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
        // TODO(build-system): vulkan
        //     if (enable_vulkan_validation_layers) {
        //       data_deps =
        //           [ "${dawn_vulkan_validation_layers_dir}:vulkan_validation_layers" ]
        //       if (!is_android) {
        //         data_deps +=
        //             [ "${dawn_vulkan_validation_layers_dir}:vulkan_gen_json_files" ]
        //       }
        //     }
    }
    return lib;
}

// Builds third party tint sources; derived from third_party/tint/src/BUILD.gn
fn buildLibTint(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("tint", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, true) catch unreachable;
    flags.appendSlice(&.{
        // TODO(build-system): make these optional
        "-DTINT_BUILD_SPV_READER=1",
        "-DTINT_BUILD_SPV_WRITER=1",
        "-DTINT_BUILD_WGSL_READER=1",
        "-DTINT_BUILD_WGSL_WRITER=1",
        "-DTINT_BUILD_MSL_WRITER=1",
        "-DTINT_BUILD_HLSL_WRITER=1",
        "-DTINT_BUILD_GLSL_WRITER=1",

        // Required for TINT_BUILD_SPV_READER=1 and TINT_BUILD_SPV_WRITER=1, if specified
        include("libs/dawn/third_party/vulkan-deps"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-headers/src/include"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/tint"),
        include("libs/dawn/third_party/tint/include"),
    }) catch unreachable;

    // libtint_core_all_src
    for ([_][]const u8{
        "third_party/tint/src/ast/access.cc",
        "third_party/tint/src/ast/alias.cc",
        "third_party/tint/src/ast/array.cc",
        "third_party/tint/src/ast/assignment_statement.cc",
        "third_party/tint/src/ast/ast_type.cc",
        "third_party/tint/src/ast/atomic.cc",
        "third_party/tint/src/ast/binary_expression.cc",
        "third_party/tint/src/ast/binding_decoration.cc",
        "third_party/tint/src/ast/bitcast_expression.cc",
        "third_party/tint/src/ast/block_statement.cc",
        "third_party/tint/src/ast/bool.cc",
        "third_party/tint/src/ast/bool_literal_expression.cc",
        "third_party/tint/src/ast/break_statement.cc",
        "third_party/tint/src/ast/builtin.cc",
        "third_party/tint/src/ast/builtin_decoration.cc",
        "third_party/tint/src/ast/call_expression.cc",
        "third_party/tint/src/ast/call_statement.cc",
        "third_party/tint/src/ast/case_statement.cc",
        "third_party/tint/src/ast/continue_statement.cc",
        "third_party/tint/src/ast/decoration.cc",
        "third_party/tint/src/ast/depth_multisampled_texture.cc",
        "third_party/tint/src/ast/depth_texture.cc",
        "third_party/tint/src/ast/disable_validation_decoration.cc",
        "third_party/tint/src/ast/discard_statement.cc",
        "third_party/tint/src/ast/else_statement.cc",
        "third_party/tint/src/ast/expression.cc",
        "third_party/tint/src/ast/external_texture.cc",
        "third_party/tint/src/ast/f32.cc",
        "third_party/tint/src/ast/fallthrough_statement.cc",
        "third_party/tint/src/ast/float_literal_expression.cc",
        "third_party/tint/src/ast/for_loop_statement.cc",
        "third_party/tint/src/ast/function.cc",
        "third_party/tint/src/ast/group_decoration.cc",
        "third_party/tint/src/ast/i32.cc",
        "third_party/tint/src/ast/identifier_expression.cc",
        "third_party/tint/src/ast/if_statement.cc",
        "third_party/tint/src/ast/index_accessor_expression.cc",
        "third_party/tint/src/ast/int_literal_expression.cc",
        "third_party/tint/src/ast/internal_decoration.cc",
        "third_party/tint/src/ast/interpolate_decoration.cc",
        "third_party/tint/src/ast/invariant_decoration.cc",
        "third_party/tint/src/ast/literal_expression.cc",
        "third_party/tint/src/ast/location_decoration.cc",
        "third_party/tint/src/ast/loop_statement.cc",
        "third_party/tint/src/ast/matrix.cc",
        "third_party/tint/src/ast/member_accessor_expression.cc",
        "third_party/tint/src/ast/module.cc",
        "third_party/tint/src/ast/multisampled_texture.cc",
        "third_party/tint/src/ast/node.cc",
        "third_party/tint/src/ast/override_decoration.cc",
        "third_party/tint/src/ast/phony_expression.cc",
        "third_party/tint/src/ast/pipeline_stage.cc",
        "third_party/tint/src/ast/pointer.cc",
        "third_party/tint/src/ast/return_statement.cc",
        "third_party/tint/src/ast/sampled_texture.cc",
        "third_party/tint/src/ast/sampler.cc",
        "third_party/tint/src/ast/sint_literal_expression.cc",
        "third_party/tint/src/ast/stage_decoration.cc",
        "third_party/tint/src/ast/statement.cc",
        "third_party/tint/src/ast/storage_class.cc",
        "third_party/tint/src/ast/storage_texture.cc",
        "third_party/tint/src/ast/stride_decoration.cc",
        "third_party/tint/src/ast/struct.cc",
        "third_party/tint/src/ast/struct_block_decoration.cc",
        "third_party/tint/src/ast/struct_member.cc",
        "third_party/tint/src/ast/struct_member_align_decoration.cc",
        "third_party/tint/src/ast/struct_member_offset_decoration.cc",
        "third_party/tint/src/ast/struct_member_size_decoration.cc",
        "third_party/tint/src/ast/switch_statement.cc",
        "third_party/tint/src/ast/texture.cc",
        "third_party/tint/src/ast/type_decl.cc",
        "third_party/tint/src/ast/type_name.cc",
        "third_party/tint/src/ast/u32.cc",
        "third_party/tint/src/ast/uint_literal_expression.cc",
        "third_party/tint/src/ast/unary_op.cc",
        "third_party/tint/src/ast/unary_op_expression.cc",
        "third_party/tint/src/ast/variable.cc",
        "third_party/tint/src/ast/variable_decl_statement.cc",
        "third_party/tint/src/ast/vector.cc",
        "third_party/tint/src/ast/void.cc",
        "third_party/tint/src/ast/workgroup_decoration.cc",
        "third_party/tint/src/castable.cc",
        "third_party/tint/src/clone_context.cc",
        "third_party/tint/src/debug.cc",
        "third_party/tint/src/demangler.cc",
        "third_party/tint/src/diagnostic/diagnostic.cc",
        "third_party/tint/src/diagnostic/formatter.cc",
        "third_party/tint/src/diagnostic/printer.cc",
        "third_party/tint/src/inspector/entry_point.cc",
        "third_party/tint/src/inspector/inspector.cc",
        "third_party/tint/src/inspector/resource_binding.cc",
        "third_party/tint/src/inspector/scalar.cc",
        "third_party/tint/src/intrinsic_table.cc",
        "third_party/tint/src/program.cc",
        "third_party/tint/src/program_builder.cc",
        "third_party/tint/src/program_id.cc",
        "third_party/tint/src/reader/reader.cc",
        "third_party/tint/src/resolver/dependency_graph.cc",
        "third_party/tint/src/resolver/resolver.cc",
        "third_party/tint/src/resolver/resolver_constants.cc",
        "third_party/tint/src/resolver/resolver_validation.cc",
        "third_party/tint/src/source.cc",
        "third_party/tint/src/symbol.cc",
        "third_party/tint/src/symbol_table.cc",
        "third_party/tint/src/transform/add_empty_entry_point.cc",
        "third_party/tint/src/transform/array_length_from_uniform.cc",
        "third_party/tint/src/transform/binding_remapper.cc",
        "third_party/tint/src/transform/calculate_array_length.cc",
        "third_party/tint/src/transform/canonicalize_entry_point_io.cc",
        "third_party/tint/src/transform/decompose_memory_access.cc",
        "third_party/tint/src/transform/decompose_strided_matrix.cc",
        "third_party/tint/src/transform/external_texture_transform.cc",
        "third_party/tint/src/transform/first_index_offset.cc",
        "third_party/tint/src/transform/fold_constants.cc",
        "third_party/tint/src/transform/fold_trivial_single_use_lets.cc",
        "third_party/tint/src/transform/for_loop_to_loop.cc",
        "third_party/tint/src/transform/loop_to_for_loop.cc",
        "third_party/tint/src/transform/manager.cc",
        "third_party/tint/src/transform/module_scope_var_to_entry_point_param.cc",
        "third_party/tint/src/transform/multiplanar_external_texture.cc",
        "third_party/tint/src/transform/num_workgroups_from_uniform.cc",
        "third_party/tint/src/transform/pad_array_elements.cc",
        "third_party/tint/src/transform/promote_initializers_to_const_var.cc",
        "third_party/tint/src/transform/remove_phonies.cc",
        "third_party/tint/src/transform/renamer.cc",
        "third_party/tint/src/transform/robustness.cc",
        "third_party/tint/src/transform/simplify_pointers.cc",
        "third_party/tint/src/transform/single_entry_point.cc",
        "third_party/tint/src/transform/transform.cc",
        "third_party/tint/src/transform/unshadow.cc",
        "third_party/tint/src/transform/vectorize_scalar_matrix_constructors.cc",
        "third_party/tint/src/transform/vertex_pulling.cc",
        "third_party/tint/src/transform/wrap_arrays_in_structs.cc",
        "third_party/tint/src/transform/zero_init_workgroup_memory.cc",
        "third_party/tint/src/writer/append_vector.cc",
        "third_party/tint/src/writer/array_length_from_uniform_options.cc",
        "third_party/tint/src/writer/float_to_string.cc",
        "third_party/tint/src/writer/text.cc",
        "third_party/tint/src/writer/text_generator.cc",
        "third_party/tint/src/writer/writer.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => lib.addCSourceFile(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_windows.cc", flags.items),
        .linux => lib.addCSourceFile(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_linux.cc", flags.items),
        else => lib.addCSourceFile(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_other.cc", flags.items),
    }

    // libtint_sem_src
    for ([_][]const u8{
        "third_party/tint/src/sem/array.cc",
        "third_party/tint/src/sem/atomic_type.cc",
        "third_party/tint/src/sem/behavior.cc",
        "third_party/tint/src/sem/block_statement.cc",
        "third_party/tint/src/sem/bool_type.cc",
        "third_party/tint/src/sem/call.cc",
        "third_party/tint/src/sem/call_target.cc",
        "third_party/tint/src/sem/constant.cc",
        "third_party/tint/src/sem/depth_multisampled_texture_type.cc",
        "third_party/tint/src/sem/depth_texture_type.cc",
        "third_party/tint/src/sem/expression.cc",
        "third_party/tint/src/sem/external_texture_type.cc",
        "third_party/tint/src/sem/f32_type.cc",
        "third_party/tint/src/sem/for_loop_statement.cc",
        "third_party/tint/src/sem/function.cc",
        "third_party/tint/src/sem/i32_type.cc",
        "third_party/tint/src/sem/if_statement.cc",
        "third_party/tint/src/sem/info.cc",
        "third_party/tint/src/sem/intrinsic.cc",
        "third_party/tint/src/sem/intrinsic_type.cc",
        "third_party/tint/src/sem/loop_statement.cc",
        "third_party/tint/src/sem/matrix_type.cc",
        "third_party/tint/src/sem/member_accessor_expression.cc",
        "third_party/tint/src/sem/multisampled_texture_type.cc",
        "third_party/tint/src/sem/node.cc",
        "third_party/tint/src/sem/parameter_usage.cc",
        "third_party/tint/src/sem/pointer_type.cc",
        "third_party/tint/src/sem/reference_type.cc",
        "third_party/tint/src/sem/sampled_texture_type.cc",
        "third_party/tint/src/sem/sampler_type.cc",
        "third_party/tint/src/sem/statement.cc",
        "third_party/tint/src/sem/storage_texture_type.cc",
        "third_party/tint/src/sem/struct.cc",
        "third_party/tint/src/sem/switch_statement.cc",
        "third_party/tint/src/sem/texture_type.cc",
        "third_party/tint/src/sem/type.cc",
        "third_party/tint/src/sem/type_constructor.cc",
        "third_party/tint/src/sem/type_conversion.cc",
        "third_party/tint/src/sem/type_manager.cc",
        "third_party/tint/src/sem/u32_type.cc",
        "third_party/tint/src/sem/variable.cc",
        "third_party/tint/src/sem/vector_type.cc",
        "third_party/tint/src/sem/void_type.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // libtint_spv_reader_src
    for ([_][]const u8{
        "third_party/tint/src/reader/spirv/construct.cc",
        "third_party/tint/src/reader/spirv/entry_point_info.cc",
        "third_party/tint/src/reader/spirv/enum_converter.cc",
        "third_party/tint/src/reader/spirv/function.cc",
        "third_party/tint/src/reader/spirv/namer.cc",
        "third_party/tint/src/reader/spirv/parser.cc",
        "third_party/tint/src/reader/spirv/parser_impl.cc",
        "third_party/tint/src/reader/spirv/parser_type.cc",
        "third_party/tint/src/reader/spirv/usage.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // libtint_spv_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/spirv/binary_writer.cc",
        "third_party/tint/src/writer/spirv/builder.cc",
        "third_party/tint/src/writer/spirv/function.cc",
        "third_party/tint/src/writer/spirv/generator.cc",
        "third_party/tint/src/writer/spirv/instruction.cc",
        "third_party/tint/src/writer/spirv/operand.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // TODO(build-system): make optional
    // libtint_wgsl_reader_src
    for ([_][]const u8{
        "third_party/tint/src/reader/wgsl/lexer.cc",
        "third_party/tint/src/reader/wgsl/parser.cc",
        "third_party/tint/src/reader/wgsl/parser_impl.cc",
        "third_party/tint/src/reader/wgsl/token.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // TODO(build-system): make optional
    // libtint_wgsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/wgsl/generator.cc",
        "third_party/tint/src/writer/wgsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // TODO(build-system): make optional
    // libtint_msl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/msl/generator.cc",
        "third_party/tint/src/writer/msl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // TODO(build-system): make optional
    // libtint_hlsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/hlsl/generator.cc",
        "third_party/tint/src/writer/hlsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    // TODO(build-system): make optional
    // libtint_glsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/transform/glsl.cc",
        "third_party/tint/src/writer/glsl/generator.cc",
        "third_party/tint/src/writer/glsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }
    return lib;
}

// Builds third_party/vulkan-deps/spirv-tools sources; derived from third_party/vulkan-deps/spirv-tools/src/BUILD.gn
fn buildLibSPIRVTools(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("spirv-tools", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, true) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-headers/src/include"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src/include"),
    }) catch unreachable;

    // spvtools
    lib.addCSourceFiles(&.{
        thisDir() ++ "/src/dawn/sources/spirv_tools.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/operand.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/spirv_reducer_options.cpp",
    }, flags.items);

    // spvtools_val
    lib.addCSourceFile(thisDir() ++ "/src/dawn/sources/spirv_tools_val.cpp", flags.items);

    // spvtools_opt
    lib.addCSourceFiles(&.{
        thisDir() ++ "/src/dawn/sources/spirv_tools_opt.cpp",
        thisDir() ++ "/src/dawn/sources/spirv_tools_opt_2.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/local_single_store_elim_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/loop_unswitch_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/mem_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/ssa_rewrite_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/vector_dce.cpp",
    }, flags.items);

    // spvtools_link
    for ([_][]const u8{
        "third_party/vulkan-deps/spirv-tools/src/source/link/linker.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }
    return lib;
}

// Builds third_party/vulkan-deps/spirv-tools sources; derived from third_party/vulkan-deps/spirv-tools/src/BUILD.gn
fn buildLibSPIRVCross(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("spirv-cross", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        "-DSPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS",
        include("libs/dawn/third_party/vulkan-deps/spirv-cross/src"),
        include("libs/dawn"),
        "-Wno-extra-semi",
        "-Wno-ignored-qualifiers",
        "-Wno-implicit-fallthrough",
        "-Wno-inconsistent-missing-override",
        "-Wno-missing-field-initializers",
        "-Wno-newline-eof",
        "-Wno-sign-compare",
        "-Wno-unused-variable",
    }) catch unreachable;

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag != .windows) flags.append("-fno-exceptions") catch unreachable;

    // spvtools_link
    lib.addCSourceFile(thisDir() ++ "/src/dawn/sources/spirv_cross.cpp", flags.items);
    return lib;
}

// Builds third_party/abseil sources; derived from:
//
// ```
// $ find third_party/abseil-cpp/absl | grep '\.cc' | grep -v 'test' | grep -v 'benchmark' | grep -v gaussian_distribution_gentables | grep -v print_hash_of | grep -v chi_square
// ```
//
fn buildLibAbseilCpp(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("abseil-cpp", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();
    system_sdk.include(b, lib, .{});

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag == .macos) lib.linkFramework("CoreFoundation");

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/third_party/abseil-cpp"),
    }) catch unreachable;

    // absl
    lib.addCSourceFiles(&.{
        thisDir() ++ "/src/dawn/sources/abseil.cpp",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/strings/numbers.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/time/internal/cctz/src/time_zone_posix.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/time/format.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/random/internal/randen_hwaes.cc",
    }, flags.items);
    return lib;
}

// Buids dawn wire sources; derived from src/dawn_wire/BUILD.gn
fn buildLibDawnWire(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-wire", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
    }) catch unreachable;

    lib.addCSourceFile(thisDir() ++ "/src/dawn/sources/dawn_wire_gen.cpp", flags.items);
    return lib;
}

// Builds dawn utils sources; derived from src/utils/BUILD.gn
fn buildLibDawnUtils(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("dawn-utils", main_abs);
    lib.install();
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();

    glfw.link(b, lib, .{ .system_sdk = .{ .set_sysroot = false } });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    flags.appendSlice(&.{
        include("libs/mach-glfw/upstream/glfw/include"),
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
    }) catch unreachable;

    for ([_][]const u8{
        "src/utils/BackendBinding.cpp",
        "src/utils/NullBinding.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        lib.addCSourceFile(abs_path, flags.items);
    }

    if (options.d3d12.?) {
        for ([_][]const u8{
            "src/utils/D3D12Binding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }
    if (options.metal.?) {
        for ([_][]const u8{
            "src/utils/MetalBinding.mm",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }

    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "src/utils/OpenGLBinding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }

    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/utils/VulkanBinding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
        }
    }
    return lib;
}

fn include(comptime rel: []const u8) []const u8 {
    return "-I" ++ thisDir() ++ "/" ++ rel;
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
