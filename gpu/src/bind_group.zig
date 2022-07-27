const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const TextureView = @import("texture_view.zig").TextureView;
const ChainedStruct = @import("types.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const Impl = @import("interface.zig").Impl;

pub const BindGroup = *opaque {
    pub inline fn setLabel(bind_group: BindGroup, label: [*:0]const u8) void {
        Impl.bindGroupSetLabel(bind_group, label);
    }

    pub inline fn reference(bind_group: BindGroup) void {
        Impl.bindGroupReference(bind_group);
    }

    pub inline fn release(bind_group: BindGroup) void {
        Impl.bindGroupRelease(bind_group);
    }
};

pub const BindGroupEntry = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    binding: u32,
    buffer: ?Buffer,
    offset: u64 = 0,
    size: u64,
    sampler: ?Sampler,
    texture_view: ?TextureView,
};

pub const BindGroupDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: ?[*:0]const u8 = null,
    layout: BindGroupLayout,
    entry_count: u32,
    // TODO: file a bug on Dawn, this is not marked as nullable but in fact is.
    entries: ?[*]const BindGroupEntry,
};
