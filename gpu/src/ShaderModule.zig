const ShaderModule = @This();

/// The type erased pointer to the ShaderModule implementation
/// Equal to c.WGPUShaderModule for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
};

pub inline fn reference(queue: ShaderModule) void {
    queue.vtable.reference(queue.ptr);
}

pub inline fn release(queue: ShaderModule) void {
    queue.vtable.release(queue.ptr);
}

pub const CodeTag = enum {
    spirv,
    wgsl,
};

pub const Descriptor = struct {
    label: ?[]const u8 = null,
    code: union(CodeTag) {
        wgsl: [:0]const u8,
        spirv: []const u32,
    },
};

// // Methods of ShaderModule
// WGPU_EXPORT void wgpuShaderModuleGetCompilationInfo(WGPUShaderModule shaderModule, WGPUCompilationInfoCallback callback, void * userdata);
// WGPU_EXPORT void wgpuShaderModuleSetLabel(WGPUShaderModule shaderModule, char const * label);
