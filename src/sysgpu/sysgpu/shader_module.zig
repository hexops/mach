const ChainedStruct = @import("main.zig").ChainedStruct;
const CompilationInfoCallback = @import("main.zig").CompilationInfoCallback;
const CompilationInfoRequestStatus = @import("main.zig").CompilationInfoRequestStatus;
const CompilationInfo = @import("main.zig").CompilationInfo;
const Impl = @import("interface.zig").Impl;

pub const ShaderModule = opaque {
    pub const Descriptor = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            spirv_descriptor: ?*const SPIRVDescriptor,
            wgsl_descriptor: ?*const WGSLDescriptor,
            hlsl_descriptor: ?*const HLSLDescriptor,
            msl_descriptor: ?*const MSLDescriptor,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        label: ?[*:0]const u8 = null,
    };

    pub const SPIRVDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shader_module_spirv_descriptor },
        code_size: u32,
        code: [*]const u32,
    };

    pub const WGSLDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shader_module_wgsl_descriptor },
        code: [*:0]const u8,
    };

    pub const HLSLDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shader_module_hlsl_descriptor },
        code: [*]const u8,
        code_size: u32,
    };

    pub const MSLDescriptor = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .shader_module_msl_descriptor },
        code: [*]const u8,
        code_size: u32,
        workgroup_size: WorkgroupSize,
    };

    pub const WorkgroupSize = extern struct { x: u32 = 1, y: u32 = 1, z: u32 = 1 };

    pub inline fn getCompilationInfo(
        shader_module: *ShaderModule,
        context: anytype,
        comptime callback: fn (
            ctx: @TypeOf(context),
            status: CompilationInfoRequestStatus,
            compilation_info: *const CompilationInfo,
        ) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn cCallback(
                status: CompilationInfoRequestStatus,
                compilation_info: *const CompilationInfo,
                userdata: ?*anyopaque,
            ) callconv(.C) void {
                callback(
                    if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))),
                    status,
                    compilation_info,
                );
            }
        };
        Impl.shaderModuleGetCompilationInfo(shader_module, Helper.cCallback, if (Context == void) null else context);
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
