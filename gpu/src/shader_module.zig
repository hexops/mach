const ChainedStruct = @import("types.zig").ChainedStruct;

pub const ShaderModule = *opaque {};

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
