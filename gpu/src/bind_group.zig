const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const TextureView = @import("texture_view.zig").TextureView;
const ChainedStruct = @import("types.zig").ChainedStruct;

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
};
