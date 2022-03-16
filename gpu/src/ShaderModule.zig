const ShaderModule = @This();

/// The type erased pointer to the ShaderModule implementation
/// Equal to c.WGPUShaderModule for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    getCompilationInfo: fn (ptr: *anyopaque, callback: *CompilationInfoCallback) void,
};

pub inline fn reference(shader: ShaderModule) void {
    shader.vtable.reference(shader.ptr);
}

pub inline fn release(shader: ShaderModule) void {
    shader.vtable.release(shader.ptr);
}

pub inline fn setLabel(shader: ShaderModule, label: [:0]const u8) void {
    shader.vtable.setLabel(shader.ptr, label);
}

pub inline fn getCompilationInfo(shader: ShaderModule, callback: *CompilationInfoCallback) void {
    shader.vtable.getCompilationInfo(shader.ptr, callback);
}

pub const CompilationInfoCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (ctx: *anyopaque, status: CompilationInfoRequestStatus, info: *const CompilationInfo) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: *Context,
        comptime callback: fn (ctx: *Context, status: CompilationInfoRequestStatus, info: *const CompilationInfo) void,
    ) CompilationInfoCallback {
        const erased = (struct {
            pub inline fn erased(type_erased_ctx: *anyopaque, status: CompilationInfoRequestStatus) void {
                callback(@ptrCast(*Context, @alignCast(@alignOf(*Context), type_erased_ctx)), status);
            }
        }).erased;

        return .{
            .type_erased_ctx = ctx,
            .type_erased_callback = erased,
        };
    }
};

pub const CompilationInfoRequestStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    device_lost = 0x00000002,
    unknown = 0x00000003,
};

pub const CompilationInfo = struct {
    messages: []const CompilationMessage,
};

pub const CompilationMessageType = enum(u32) {
    err = 0x00000000,
    warning = 0x00000001,
    info = 0x00000002,
};

pub const CompilationMessage = extern struct {
    reserved: ?*anyopaque = null,
    message: [*:0]const u8,
    type: CompilationMessageType,
    line_num: u64,
    line_pos: u64,
    offset: u64,
    length: u64,
};

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
    _ = CompilationInfoRequestStatus;
    _ = CompilationInfo;
    _ = CompilationMessageType;
    _ = CompilationMessage;
    _ = CodeTag;
    _ = Descriptor;
}
