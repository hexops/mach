const ChainedStruct = @import("types.zig").ChainedStruct;
const impl = @import("interface.zig").impl;

pub const RenderBundle = *opaque {
    pub inline fn reference(render_bundle: RenderBundle) void {
        impl.renderBundleReference(render_bundle);
    }

    pub inline fn release(render_bundle: RenderBundle) void {
        impl.renderBundleRelease(render_bundle);
    }
};

pub const RenderBundleDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
