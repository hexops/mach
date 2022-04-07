const std = @import("std");
const Texture = @import("Texture.zig");
const TextureView = @import("TextureView.zig");
const PresentMode = @import("enums.zig").PresentMode;

const SwapChain = @This();

/// The type erased pointer to the SwapChain implementation
/// Equal to c.WGPUSwapChain for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    configure: fn (ptr: *anyopaque, format: Texture.Format, allowed_usage: Texture.Usage, width: u32, height: u32) void,
    getCurrentTextureView: fn (ptr: *anyopaque) TextureView,
    present: fn (ptr: *anyopaque) void,
};

pub inline fn reference(swap_chain: SwapChain) void {
    swap_chain.vtable.reference(swap_chain.ptr);
}

pub inline fn release(swap_chain: SwapChain) void {
    swap_chain.vtable.release(swap_chain.ptr);
}

// TODO: remove this and/or prefix with dawn? Seems to be deprecated / not in upstream webgpu.h
pub inline fn configure(
    swap_chain: SwapChain,
    format: Texture.Format,
    allowed_usage: Texture.Usage,
    width: u32,
    height: u32,
) void {
    swap_chain.vtable.configure(swap_chain.ptr, format, allowed_usage, width, height);
}

pub inline fn getCurrentTextureView(swap_chain: SwapChain) TextureView {
    return swap_chain.vtable.getCurrentTextureView(swap_chain.ptr);
}

pub inline fn present(swap_chain: SwapChain) void {
    swap_chain.vtable.present(swap_chain.ptr);
}

pub const Descriptor = struct {
    label: ?[:0]const u8 = null,
    usage: Texture.Usage,
    format: Texture.Format,
    width: u32,
    height: u32,
    present_mode: PresentMode,
    implementation: u64,

    pub fn equal(a: *const Descriptor, b: *const Descriptor) bool {
        if ((a.label == null) != (b.label == null)) return false;
        if (a.label != null and !std.mem.eql(u8, a.label.?, b.label.?)) return false;
        if (!a.usage.equal(b.usage)) return false;
        if (a.format != b.format) return false;
        if (a.width != b.width) return false;
        if (a.height != b.height) return false;
        if (a.present_mode != b.present_mode) return false;
        if (a.implementation != b.implementation) return false;
        return true;
    }
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = configure;
    _ = getCurrentTextureView;
    _ = present;
    _ = Descriptor;
}
