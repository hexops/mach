const Sampler = @This();

/// The type erased pointer to the Sampler implementation
/// Equal to c.WGPUSampler for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(sampler: Sampler) void {
    sampler.vtable.reference(sampler.ptr);
}

pub inline fn release(sampler: Sampler) void {
    sampler.vtable.release(sampler.ptr);
}

pub inline fn setLabel(sampler: Sampler, label: [:0]const u8) void {
    sampler.vtable.setLabel(sampler.ptr, label);
}

pub const BindingType = enum(u32) {
    none = 0x00000000,
    filtering = 0x00000001,
    non_filtering = 0x00000002,
    comparison = 0x00000003,
};

pub const BindingLayout = struct {
    type: BindingType,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = BindingType;
    _ = BindingLayout;
}
