const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const TextureView = @import("texture_view.zig").TextureView;
const ChainedStruct = @import("types.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const Impl = @import("interface.zig").Impl;

pub const BindGroup = opaque {
    pub const Entry = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        binding: u32,
        buffer: ?*Buffer = null,
        offset: u64 = 0,
        size: u64,
        sampler: ?*Sampler = null,
        texture_view: ?*TextureView = null,
    };

    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        layout: *BindGroupLayout,
        entry_count: u32 = 0,
        entries: ?[*]const Entry = null,
    };

    pub inline fn setLabel(bind_group: *BindGroup, label: [*:0]const u8) void {
        Impl.bindGroupSetLabel(bind_group, label);
    }

    pub inline fn reference(bind_group: *BindGroup) void {
        Impl.bindGroupReference(bind_group);
    }

    pub inline fn release(bind_group: *BindGroup) void {
        Impl.bindGroupRelease(bind_group);
    }
};
