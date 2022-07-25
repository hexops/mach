const Instance = @import("instance.zig").Instance;
const InstanceDescriptor = @import("instance.zig").InstanceDescriptor;
const gpu = @import("main.zig");

/// The gpu.Interface implementation that is used by the entire program. Only one may exist, since
/// it is resolved fully at comptime with no vtable indirection, etc.
pub const impl = blk: {
    if (@import("builtin").is_test) {
        break :blk NullInterface{};
    } else {
        const root = @import("root");
        if (!@hasField(root, "gpu_interface")) @compileError("expected to find `pub const gpu_interface: gpu.Interface(T) = T{};` in root file");
        _ = gpu.Interface(@TypeOf(root.gpu_interface)); // verify the type
        break :blk root.gpu_interface;
    }
};

/// Verifies that a gpu.Interface implementation exposes the expected function declarations.
pub fn Interface(comptime Impl: type) type {
    assertDecl(Impl, "createInstance", fn (descriptor: *const InstanceDescriptor) callconv(.Inline) ?Instance);
    assertDecl(Impl, "getProcAddress", fn (device: gpu.Device, proc_name: [*:0]const u8) callconv(.Inline) ?gpu.Proc);
    assertDecl(Impl, "adapterCreateDevice", fn (adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor) callconv(.Inline) ?gpu.Device);
    assertDecl(Impl, "adapterEnumerateFeatures", fn (adapter: gpu.Adapter, features: ?[*]gpu.FeatureName) callconv(.Inline) usize);
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
        export fn wgpuGetProcAddress(device: gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
            return Impl.getProcAddress(device, proc_name);
        }

        // WGPU_EXPORT WGPUDevice wgpuAdapterCreateDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor /* nullable */);
        export fn wgpuAdapterCreateDevice(adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor) ?gpu.Device {
            return Impl.adapterCreateDevice(adapter, descriptor);
        }

        // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
        export fn wgpuAdapterEnumerateFeatures(adapter: gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
            return Impl.adapterEnumerateFeatures(adapter, features);
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

    pub inline fn adapterCreateDevice(adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor) ?gpu.Device {
        _ = adapter;
        _ = descriptor;
        return null;
    }

    pub inline fn adapterEnumerateFeatures(adapter: gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
        _ = adapter;
        _ = features;
        return 0;
    }
});

test "null" {
    _ = Export(NullInterface);
}
