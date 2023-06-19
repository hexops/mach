const ChainedStruct = @import("main.zig").ChainedStruct;
const Impl = @import("interface.zig").Impl;

pub const RenderBundle = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
    };

    pub inline fn setLabel(render_bundle: *RenderBundle, label: [*:0]const u8) void {
        Impl.renderBundleSetLabel(render_bundle, label);
    }

    pub inline fn reference(render_bundle: *RenderBundle) void {
        Impl.renderBundleReference(render_bundle);
    }

    pub inline fn release(render_bundle: *RenderBundle) void {
        Impl.renderBundleRelease(render_bundle);
    }
};
