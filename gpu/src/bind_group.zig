const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const TextureView = @import("texture_view.zig").TextureView;
const ChainedStruct = @import("types.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;

pub const BindGroup = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: BindGroup = @intToEnum(BindGroup, 0);

    pub const Entry = extern struct {
        next_in_chain: *const ChainedStruct,
        binding: u32,
        buffer: Buffer = Buffer.none, // nullable
        offset: u64,
        size: u64,
        sampler: Sampler = Sampler.none, // nullable
        texture_view: TextureView = TextureView.none, // nullable
    };

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
        layout: BindGroupLayout,
        entry_count: u32,
        entries: [*]const Entry,
    };
};
