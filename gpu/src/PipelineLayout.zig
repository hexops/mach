const BindGroup = @import("BindGroup.zig");

const PipelineLayout = @This();

/// The type erased pointer to the PipelineLayout implementation
/// Equal to c.WGPUPipelineLayout for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(qset: PipelineLayout) void {
    qset.vtable.reference(qset.ptr);
}

pub inline fn release(qset: PipelineLayout) void {
    qset.vtable.release(qset.ptr);
}

pub inline fn setLabel(qset: PipelineLayout, label: [:0]const u8) void {
    qset.vtable.setLabel(qset.ptr, label);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    bind_group_layouts: []const BindGroup.Layout,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = Descriptor;
}
