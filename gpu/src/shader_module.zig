const ChainedStruct = @import("types.zig").ChainedStruct;
const CompilationInfoCallback = @import("callbacks.zig").CompilationInfoCallback;
const CompilationInfoRequestStatus = @import("types.zig").CompilationInfoRequestStatus;
const CompilationInfo = @import("types.zig").CompilationInfo;
const Impl = @import("interface.zig").Impl;

pub const ShaderModule = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
    };

    pub const SPIRVDescriptor = extern struct {
        chain: ChainedStruct,
        code_size: u32,
        code: [*]const u32,
    };

    pub const WGSLDescriptor = extern struct {
        chain: ChainedStruct,
        source: [*:0]const u8,
    };

    pub inline fn getCompilationInfo(
        shader_module: *ShaderModule,
        context: anytype,
        comptime callback: fn (
            status: CompilationInfoRequestStatus,
            compilation_info: *const CompilationInfo,
            ctx: @TypeOf(context),
        ) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn callback(
                status: CompilationInfoRequestStatus,
                compilation_info: *const CompilationInfo,
                userdata: ?*anyopaque,
            ) callconv(.C) void {
                callback(
                    status,
                    compilation_info,
                    if (Context == void) {} else @ptrCast(Context, userdata),
                );
            }
        };
        Impl.shaderModuleGetCompilationInfo(shader_module, Helper.callback, if (Context == void) null else context);
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
