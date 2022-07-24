const Instance = @import("instance.zig").Instance;
const InstanceDescriptor = @import("instance.zig").InstanceDescriptor;

/// Verifies that a gpu.Interface implementation exposes the expected function declarations.
pub fn Interface(comptime Impl: type) type {
    assertDecl(Impl, "createInstance", fn (descriptor: *const InstanceDescriptor) callconv(.Inline) ?Instance);
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
    };
}

/// A no-operation gpu.Interface implementation.
pub const NullInterface = Interface(struct {
    pub inline fn createInstance(descriptor: *const InstanceDescriptor) ?Instance {
        _ = descriptor;
        return null;
    }
});

test "null" {
    _ = Export(NullInterface);
}
