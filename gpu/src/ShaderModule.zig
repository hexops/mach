const ShaderModule = @This();

/// The type erased pointer to the ShaderModule implementation
/// Equal to c.WGPUShaderModule for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuShaderModuleGetCompilationInfo(WGPUShaderModule shaderModule, WGPUCompilationInfoCallback callback, void * userdata);
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(queue: ShaderModule) void {
    queue.vtable.reference(queue.ptr);
}

pub inline fn release(queue: ShaderModule) void {
    queue.vtable.release(queue.ptr);
}

pub inline fn setLabel(queue: ShaderModule, label: [:0]const u8) void {
    queue.vtable.setLabel(queue.ptr, label);
}

pub const CodeTag = enum {
    spirv,
    wgsl,
};

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    code: union(CodeTag) {
        wgsl: [*:0]const u8,
        spirv: []const u32,
    },
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = CodeTag;
    _ = Descriptor;
}
