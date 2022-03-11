//! Structures which are not ABI compatible with webgpu.h
const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const TextureView = @import("TextureView.zig");

pub const BindGroupEntry = struct {
    binding: u32,
    buffer: Buffer,
    offset: u64,
    size: u64,
    sampler: Sampler,
    texture_view: TextureView,
};

test "syntax" {
    _ = BindGroupEntry;
}
