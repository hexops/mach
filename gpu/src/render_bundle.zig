const ChainedStruct = @import("types.zig").ChainedStruct;

pub const RenderBundle = *opaque {
    // TODO
    // pub inline fn renderBundleReference(render_bundle: gpu.RenderBundle) void {

    // TODO
    // pub inline fn renderBundleRelease(render_bundle: gpu.RenderBundle) void {
};

pub const RenderBundleDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
