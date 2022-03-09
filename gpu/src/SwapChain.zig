const TextureUsage = @import("texture_usage.zig").TextureUsage;
const TextureFormat = @import("texture_format.zig").TextureFormat;
const PresentMode = @import("present_mode.zig").PresentMode;

const SwapChain = @This();

/// The type erased pointer to the SwapChain implementation
/// Equal to c.WGPUSwapChain for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuSwapChainConfigure(WGPUSwapChain swapChain, WGPUTextureFormat format, WGPUTextureUsageFlags allowedUsage, uint32_t width, uint32_t height);
    // WGPU_EXPORT WGPUTextureView wgpuSwapChainGetCurrentTextureView(WGPUSwapChain swapChain);
    // WGPU_EXPORT void wgpuSwapChainPresent(WGPUSwapChain swapChain);
};

pub inline fn reference(swap_chain: SwapChain) void {
    swap_chain.vtable.reference(swap_chain.ptr);
}

pub inline fn release(swap_chain: SwapChain) void {
    swap_chain.vtable.release(swap_chain.ptr);
}

pub const Descriptor = struct {
    label: ?[]const u8 = null,
    usage: TextureUsage,
    format: TextureFormat,
    width: u32,
    height: u32,
    present_mode: PresentMode,
    implementation: u64,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = Descriptor;
}
