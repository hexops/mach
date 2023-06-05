const ChainedStruct = @import("main.zig").ChainedStruct;
const Impl = @import("interface.zig").Impl;

pub const Surface = opaque {
    pub const Descriptor = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            from_android_native_window: *const DescriptorFromAndroidNativeWindow,
            from_canvas_html_selector: *const DescriptorFromCanvasHTMLSelector,
            from_metal_layer: *const DescriptorFromMetalLayer,
            from_wayland_surface: *const DescriptorFromWaylandSurface,
            from_windows_core_window: *const DescriptorFromWindowsCoreWindow,
            from_windows_hwnd: *const DescriptorFromWindowsHWND,
            from_windows_swap_chain_panel: *const DescriptorFromWindowsSwapChainPanel,
            from_xlib_window: *const DescriptorFromXlibWindow,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        label: ?[*:0]const u8 = null,
    };

    pub const DescriptorFromAndroidNativeWindow = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .surface_descriptor_from_android_native_window },
        window: *anyopaque,
    };

    pub const DescriptorFromCanvasHTMLSelector = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .surface_descriptor_from_canvas_html_selector },
        selector: [*:0]const u8,
    };

    pub const DescriptorFromMetalLayer = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .surface_descriptor_from_metal_layer },
        layer: *anyopaque,
    };

    pub const DescriptorFromWaylandSurface = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .surface_descriptor_from_wayland_surface },
        display: *anyopaque,
        surface: *anyopaque,
    };

    pub const DescriptorFromWindowsCoreWindow = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .surface_descriptor_from_windows_core_window },
        core_window: *anyopaque,
    };

    pub const DescriptorFromWindowsHWND = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .surface_descriptor_from_windows_hwnd },
        hinstance: *anyopaque,
        hwnd: *anyopaque,
    };

    pub const DescriptorFromWindowsSwapChainPanel = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .surface_descriptor_from_windows_swap_chain_panel },
        swap_chain_panel: *anyopaque,
    };

    pub const DescriptorFromXlibWindow = extern struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .surface_descriptor_from_xlib_window },
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
