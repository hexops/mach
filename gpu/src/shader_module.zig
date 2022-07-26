const ChainedStruct = @import("types.zig").ChainedStruct;

pub const ShaderModule = *opaque {
    // TODO
    // pub inline fn shaderModuleGetCompilationInfo(shader_module: gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: *anyopaque) void {

    // TODO
    // pub inline fn shaderModuleSetLabel(shader_module: gpu.ShaderModule, label: [*:0]const u8) void {

    // TODO
    // pub inline fn shaderModuleReference(shader_module: gpu.ShaderModule) void {

    // TODO
    // pub inline fn shaderModuleRelease(shader_module: gpu.ShaderModule) void {
};

pub const ShaderModuleDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
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
