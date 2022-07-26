const ChainedStruct = @import("types.zig").ChainedStruct;
const RequestAdapterStatus = @import("types.zig").RequestAdapterStatus;
const Adapter = @import("adapter.zig").Adapter;

pub const Instance = *opaque {
    // TODO
    // pub inline fn instanceCreateSurface(instance: gpu.Instance, descriptor: *const gpu.SurfaceDescriptor) gpu.Surface {

    // TODO
    // pub inline fn instanceRequestAdapter(instance: gpu.Instance, options: *const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: *anyopaque) void {

    // TODO
    // pub inline fn instanceReference(instance: gpu.Instance) void {

    // TODO
    // pub inline fn instanceRelease(instance: gpu.Instance) void {
};

pub const RequestAdapterCallback = fn (
    status: RequestAdapterStatus,
    adapter: Adapter,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const InstanceDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
};
