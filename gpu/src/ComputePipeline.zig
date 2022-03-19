const PipelineLayout = @import("PipelineLayout.zig");
const ProgrammableStageDescriptor = @import("structs.zig").ProgrammableStageDescriptor;
const BindGroupLayout = @import("BindGroupLayout.zig");

const ComputePipeline = @This();

/// The type erased pointer to the ComputePipeline implementation
/// Equal to c.WGPUComputePipeline for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    getBindGroupLayout: fn (ptr: *anyopaque, group_index: u32) BindGroupLayout,
};

pub inline fn reference(pipeline: ComputePipeline) void {
    pipeline.vtable.reference(pipeline.ptr);
}

pub inline fn release(pipeline: ComputePipeline) void {
    pipeline.vtable.release(pipeline.ptr);
}

pub inline fn setLabel(pipeline: ComputePipeline, label: [:0]const u8) void {
    pipeline.vtable.setLabel(pipeline.ptr, label);
}

pub inline fn getBindGroupLayout(pipeline: ComputePipeline, group_index: u32) BindGroupLayout {
    return pipeline.vtable.getBindGroupLayout(pipeline.ptr, group_index);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    layout: PipelineLayout,
    compute: ProgrammableStageDescriptor,
};

pub const CreateStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    device_lost = 0x00000002,
    device_destroyed = 0x00000003,
    unknown = 0x00000004,
};

pub const CreateCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (
        ctx: *anyopaque,
        status: CreateStatus,
        pipeline: ComputePipeline,
        message: [:0]const u8,
    ) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: Context,
        comptime callback: fn (
            ctx: Context,
            status: CreateStatus,
            pipeline: ComputePipeline,
            message: [:0]const u8,
        ) void,
    ) CreateCallback {
        const erased = (struct {
            pub inline fn erased(
                type_erased_ctx: *anyopaque,
                status: CreateStatus,
                pipeline: ComputePipeline,
                message: [:0]const u8,
            ) void {
                callback(
                    @ptrCast(Context, @alignCast(@alignOf(Context), type_erased_ctx)),
                    status,
                    pipeline,
                    message,
                );
            }
        }).erased;

        return .{
            .type_erased_ctx = if (Context == void) undefined else ctx,
            .type_erased_callback = erased,
        };
    }
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = setLabel;
    _ = getBindGroupLayout;
    _ = Descriptor;
    _ = CreateStatus;
    _ = CreateCallback;
}
