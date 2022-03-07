//! A native WebGPU surface

pub const DescriptorTag = enum {
    metal_layer,
    windows_hwnd,
    windows_core_window,
    windows_swap_chain_panel,
    xlib_window,
    canvas_html_selector,
};

pub const Descriptor = union(DescriptorTag) {
    metal_layer: struct {
        label: ?[]const u8,
        layer: *anyopaque,
    },
    windows_hwnd: struct {
        label: ?[]const u8,
        hinstance: *anyopaque,
        hwnd: *anyopaque,
    },
    windows_core_window: struct {
        label: ?[]const u8,
        core_window: *anyopaque,
    },
    windows_swap_chain_panel: struct {
        label: ?[]const u8,
        swap_chain_panel: *anyopaque,
    },
    xlib_window: struct {
        label: ?[]const u8,
        display: *anyopaque,
        window: u32,
    },
    canvas_html_selector: struct {
        label: ?[]const u8,
        selector: []const u8,
    },
};
