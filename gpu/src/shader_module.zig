const ChainedStruct = @import("types.zig").ChainedStruct;
const CompilationInfoCallback = @import("callbacks.zig").CompilationInfoCallback;
const Impl = @import("interface.zig").Impl;

pub const ShaderModule = opaque {
    pub inline fn getCompilationInfo(shader_module: *ShaderModule, callback: CompilationInfoCallback, userdata: *anyopaque) void {
        Impl.shaderModuleGetCompilationInfo(shader_module, callback, userdata);
    }

    pub inline fn setLabel(shader_module: *ShaderModule, label: [*:0]const u8) void {
        Impl.shaderModuleSetLabel(shader_module, label);
    }

    pub inline fn reference(shader_module: *ShaderModule) void {
        Impl.shaderModuleReference(shader_module);
    }

    pub inline fn release(shader_module: *ShaderModule) void {
        Impl.shaderModuleRelease(shader_module);
    }
};

pub const ShaderModuleDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: ?[*:0]const u8 = null,
};

pub const ShaderModuleSPIRVDescriptor = extern struct {
    chain: ChainedStruct,
    code_size: u32,
    code: [*]const u32,
};

pub const ShaderModuleWGSLDescriptor = extern struct {
    chain: ChainedStruct,
    source: [*:0]const u8,
};
