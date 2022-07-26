const ChainedStruct = @import("types.zig").ChainedStruct;
const PresentMode = @import("types.zig").PresentMode;
const Texture = @import("texture.zig").Texture;
const TextureUsageFlags = @import("texture.zig").TextureUsageFlags;
const TextureFormat = @import("texture.zig").TextureFormat;

pub const SwapChain = *opaque {
    // TODO
    // pub inline fn swapChainConfigure(swap_chain: gpu.SwapChain, format: gpu.TextureFormat, allowed_usage: gpu.TextureUsageFlags, width: u32, height: u32) void {

    // TODO
    // pub inline fn swapChainGetCurrentTextureView(swap_chain: gpu.SwapChain) gpu.TextureView {

    // TODO
    // pub inline fn swapChainPresent(swap_chain: gpu.SwapChain) void {

    // TODO
    // pub inline fn swapChainReference(swap_chain: gpu.SwapChain) void {

    // TODO
    // pub inline fn swapChainRelease(swap_chain: gpu.SwapChain) void {
};

pub const SwapChainDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    usage: TextureUsageFlags,
    format: TextureFormat,
    width: u32,
    height: u32,
    present_mode: PresentMode,
    implementation: u64,
};
