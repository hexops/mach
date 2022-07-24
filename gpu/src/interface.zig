const Instance = @import("instance.zig").Instance;
const InstanceDescriptor = @import("instance.zig").InstanceDescriptor;
const gpu = @import("main.zig");

/// Verifies that a gpu.Interface implementation exposes the expected function declarations.
pub fn Interface(comptime Impl: type) type {
    assertDecl(Impl, "createInstance", fn (descriptor: *const InstanceDescriptor) callconv(.Inline) ?Instance);
    assertDecl(Impl, "getProcAddress", fn (device: gpu.Device, proc_name: [*:0]const u8) callconv(.Inline) ?gpu.Proc);
    return Impl;
}

fn assertDecl(comptime Impl: anytype, comptime name: []const u8, comptime T: type) void {
    if (!@hasDecl(Impl, name)) @compileError("gpu.Interface missing declaration: " ++ @typeName(T));
    const Decl = @TypeOf(@field(Impl, name));
    if (Decl != T) @compileError("gpu.Interface field '" ++ name ++ "'\n\texpected type: " ++ @typeName(T) ++ "\n\t   found type: " ++ @typeName(Decl));
}

/// Exports C ABI function declarations for the given gpu.Interface implementation.
pub fn Export(comptime Impl: type) type {
    _ = Interface(Impl); // verify implementation is a valid interface
    return struct {
        // WGPU_EXPORT WGPUInstance wgpuCreateInstance(WGPUInstanceDescriptor const * descriptor);
        export fn wgpuCreateInstance(descriptor: *const InstanceDescriptor) ?Instance {
            return Impl.createInstance(descriptor);
        }

        // WGPU_EXPORT WGPUProc wgpuGetProcAddress(WGPUDevice device, char const * procName);
        export fn getProcAddress(device: gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
            return Impl.getProcAddress(device, proc_name);
        }
    };
}

/// A no-operation gpu.Interface implementation.
pub const NullInterface = Interface(struct {
    pub inline fn createInstance(descriptor: *const InstanceDescriptor) ?Instance {
        _ = descriptor;
        return null;
    }

    pub inline fn getProcAddress(device: gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
        _ = device;
        _ = proc_name;
        return null;
    }
});

test "null" {
    _ = Export(NullInterface);
}
