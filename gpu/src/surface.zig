const ChainedStruct = @import("types.zig").ChainedStruct;
const Impl = @import("interface.zig").Impl;

pub const Surface = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
    };

    pub const DescriptorFromAndroidNativeWindow = extern struct {
        chain: ChainedStruct,
        window: *anyopaque,
    };

    pub const DescriptorFromCanvasHTMLSelector = extern struct {
        chain: ChainedStruct,
        selector: [*:0]const u8,
    };

    pub const DescriptorFromMetalLayer = extern struct {
        chain: ChainedStruct,
        layer: *anyopaque,
    };

    pub const DescriptorFromWaylandSurface = extern struct {
        chain: ChainedStruct,
        display: *anyopaque,
        surface: *anyopaque,
    };

    pub const DescriptorFromWindowsCoreWindow = extern struct {
        chain: ChainedStruct,
        core_window: *anyopaque,
    };

    pub const DescriptorFromWindowsHWND = extern struct {
        chain: ChainedStruct,
        hinstance: *anyopaque,
        hwnd: *anyopaque,
    };

    pub const DescriptorFromWindowsSwapChainPanel = extern struct {
        chain: ChainedStruct,
        swap_chain_panel: *anyopaque,
    };

    pub const DescriptorFromXlibWindow = extern struct {
        chain: ChainedStruct,
        display: *anyopaque,
        window: u32,
    };

    pub inline fn reference(surface: *Surface) void {
        Impl.surfaceReference(surface);
    }

    pub inline fn release(surface: *Surface) void {
        Impl.surfaceRelease(surface);
    }
};
