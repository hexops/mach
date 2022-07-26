const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const TextureView = @import("texture_view.zig").TextureView;
const ChainedStruct = @import("types.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;

pub const BindGroup = *opaque {
    // TODO
    // pub inline fn bindGroupSetLabel(bind_group: gpu.BindGroup, label: [*:0]const u8) void {

    // TODO
    // pub inline fn bindGroupReference(bind_group: gpu.BindGroup) void {

    // TODO
    // pub inline fn bindGroupRelease(bind_group: gpu.BindGroup) void {
};

pub const BindGroupEntry = extern struct {
    next_in_chain: *const ChainedStruct,
    binding: u32,
    buffer: ?Buffer,
    offset: u64,
    size: u64,
    sampler: ?Sampler,
    texture_view: ?TextureView,
};

pub const BindGroupDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    layout: BindGroupLayout,
    entry_count: u32,
    entries: [*]const BindGroupEntry,
};
