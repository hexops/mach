const ChainedStruct = @import("types.zig").ChainedStruct;
const impl = @import("interface.zig").impl;

pub const Surface = *opaque {
    pub inline fn reference(surface: Surface) void {
        impl.surfaceReference(surface);
    }

    pub inline fn release(surface: Surface) void {
        impl.surfaceRelease(surface);
    }
};

pub const SurfaceDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};

pub const SurfaceDescriptorFromAndroidNativeWindow = extern struct {
    chain: ChainedStruct,
    window: *anyopaque,
};

pub const SurfaceDescriptorFromCanvasHTMLSelector = extern struct {
    chain: ChainedStruct,
    selector: [*:0]const u8,
};

pub const SurfaceDescriptorFromMetalLayer = extern struct {
    chain: ChainedStruct,
    layer: *anyopaque,
};

pub const SurfaceDescriptorFromWaylandSurface = extern struct {
    chain: ChainedStruct,
    display: *anyopaque,
    surface: *anyopaque,
};

pub const SurfaceDescriptorFromWindowsCoreWindow = extern struct {
    chain: ChainedStruct,
    core_window: *anyopaque,
};

pub const SurfaceDescriptorFromWindowsHWND = extern struct {
    chain: ChainedStruct,
    hinstance: *anyopaque,
    hwnd: *anyopaque,
};

pub const SurfaceDescriptorFromWindowsSwapChainPanel = extern struct {
    chain: ChainedStruct,
    swap_chain_panel: *anyopaque,
};

pub const SurfaceDescriptorFromXlibWindow = extern struct {
    chain: ChainedStruct,
    display: *anyopaque,
    window: u32,
};
