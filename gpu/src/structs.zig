//! Structures which are not ABI compatible with webgpu.h
const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const TextureView = @import("TextureView.zig");
const BufferBindingType = @import("enums.zig").BufferBindingType;
const CompilationMessageType = @import("enums.zig").CompilationMessageType;

pub const BindGroupEntry = struct {
    binding: u32,
    buffer: Buffer,
    offset: u64,
    size: u64,
    sampler: Sampler,
    texture_view: TextureView,
};

pub const BufferBindingLayout = struct {
    type: BufferBindingType,
    has_dynamic_offset: bool,
    min_binding_size: u64,
};

pub const CompilationMessage = struct {
    message: [:0]const u8,
    type: CompilationMessageType,
    line_num: u64,
    line_pos: u64,
    offset: u64,
    length: u64,
};

pub const MultisampleState = struct {
    count: u32,
    mask: u32,
    alpha_to_coverage_enabled: bool,
};

test "syntax" {
    _ = BindGroupEntry;
    _ = BufferBindingLayout;
    _ = CompilationMessage;
}
