//! Window type and related functions

const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const c = @import("c.zig").c;

const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;
const Image = @import("Image.zig");
const Monitor = @import("Monitor.zig");
const Cursor = @import("Cursor.zig");

const Window = @This();

handle: *c.GLFWwindow,

/// Returns a Zig GLFW window from an underlying C GLFW window handle.
///
/// Note that the Zig GLFW library stores a custom user pointer in order to make callbacks nicer,
/// see glfw.Window.InternalUserPointer.
pub inline fn from(handle: *c.GLFWwindow) Error!Window {
    const ptr = c.glfwGetWindowUserPointer(handle);
    if (ptr == null) {
        const internal = try std.heap.c_allocator.create(InternalUserPointer);
        c.glfwSetWindowUserPointer(handle, @ptrCast(*c_void, internal));
        try getError();
    }
    return Window{ .handle = handle };
}

/// The actual type which is stored by the Zig GLFW library in glfwSetWindowUserPointer.
///
/// This is used to internally carry function callbacks with nicer Zig interfaces.
pub const InternalUserPointer = struct {
    /// The actual user pointer that the user of the library wished to set via setUserPointer.
    user_pointer: ?*c_void,

    // Callbacks to be invoked by wrapper functions.
    setPosCallback: ?fn (window: Window, xpos: isize, ypos: isize) void,
    setSizeCallback: ?fn (window: Window, width: isize, height: isize) void,
    setCloseCallback: ?fn (window: Window) void,
    setRefreshCallback: ?fn (window: Window) void,
    setFocusCallback: ?fn (window: Window, focused: bool) void,
    setIconifyCallback: ?fn (window: Window, iconified: bool) void,
    setMaximizeCallback: ?fn (window: Window, maximized: bool) void,
    setFramebufferSizeCallback: ?fn (window: Window, width: isize, height: isize) void,
    setContentScaleCallback: ?fn (window: Window, xscale: f32, yscale: f32) void,
    setKeyCallback: ?fn (window: Window, key: isize, scancode: isize, action: isize, mods: isize) void,
    setCharCallback: ?fn (window: Window, codepoint: u21) void,
    setMouseButtonCallback: ?fn (window: Window, button: isize, action: isize, mods: isize) void,
    setCursorPosCallback: ?fn (window: Window, xpos: f64, ypos: f64) void,
    setCursorEnterCallback: ?fn (window: Window, entered: bool) void,
    setScrollCallback: ?fn (window: Window, xoffset: f64, yoffset: f64) void,
    setDropCallback: ?fn (window: Window, paths: [][*c]const u8) void,
};

/// Resets all window hints to their default values.
///
/// This function resets all window hints to their default values.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_hints, glfw.Window.hint, glfw.Window.hintString
pub inline fn defaultHints() Error!void {
    c.glfwDefaultWindowHints();
    try getError();
}

/// Sets the specified window hint to the desired value.
///
/// This function sets hints for the next call to glfw.Window.create. The hints, once set, retain
/// their values until changed by a call to this function or glfw.window.defaultHints, or until the
/// library is terminated.
///
/// This function does not check whether the specified hint values are valid. If you set hints to
/// invalid values this will instead be reported by the next call to glfw.createWindow.
///
/// Some hints are platform specific. These may be set on any platform but they will only affect
/// their specific platform. Other platforms will ignore them.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
///
/// @pointer_lifetime in the event that value is of a str type, the specified string is copied before this function returns.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_hints, glfw.Window.defaultHints
pub inline fn hint(hint_const: usize, value: anytype) Error!void {
    const value_type = @TypeOf(value);
    const value_type_info: std.builtin.TypeInfo = @typeInfo(value_type);

    switch (value_type_info) {
        .Int, .ComptimeInt => {
            c.glfwWindowHint(@intCast(c_int, hint_const), @intCast(c_int, value));
        },
        .Bool => {
            const int_value = @boolToInt(value);
            c.glfwWindowHint(@intCast(c_int, hint_const), @intCast(c_int, int_value));
        },
        .Enum => {
            const int_value = @enumToInt(value);
            c.glfwWindowHint(@intCast(c_int, hint_const), @intCast(c_int, int_value));
        },
        .Array => |arr_type| {
            if (arr_type.child != u8) {
                @compileError("expected array of u8, got " ++ @typeName(arr_type));
            }
            c.glfwWindowHintString(@intCast(c_int, hint_const), &value[0]);
        },
        .Pointer => |pointer_info| {
            const pointed_type = @typeInfo(pointer_info.child);
            switch (pointed_type) {
                .Array => |arr_type| {
                    if (arr_type.child != u8) {
                        @compileError("expected pointer to array of u8, got " ++ @typeName(arr_type));
                    }
                },
                else => @compileError("expected pointer to array, got " ++ @typeName(pointed_type)),
            }
            c.glfwWindowHintString(@intCast(c_int, hint_const), &value[0]);
        },
        else => {
            @compileError("expected a int, bool, enum, array, or pointer, got " ++ @typeName(value_type));
        },
    }
    try getError();
}

/// Creates a window and its associated context.
///
/// This function creates a window and its associated OpenGL or OpenGL ES context. Most of the
/// options controlling how the window and its context should be created are specified with window
/// hints using `glfw.Window.hint`.
///
/// Successful creation does not change which context is current. Before you can use the newly
/// created context, you need to make it current using `glfw.Window.makeContextCurrent`. For
/// information about the `share` parameter, see context_sharing.
///
/// The created window, framebuffer and context may differ from what you requested, as not all
/// parameters and hints are hard constraints. This includes the size of the window, especially for
/// full screen windows. To query the actual attributes of the created window, framebuffer and
/// context, see glfw.Window.getAttrib, glfw.Window.getSize and glfw.window.getFramebufferSize.
///
/// To create a full screen window, you need to specify the monitor the window will cover. If no
/// monitor is specified, the window will be windowed mode. Unless you have a way for the user to
/// choose a specific monitor, it is recommended that you pick the primary monitor. For more
/// information on how to query connected monitors, see @ref monitor_monitors.
///
/// For full screen windows, the specified size becomes the resolution of the window's _desired
/// video mode_. As long as a full screen window is not iconified, the supported video mode most
/// closely matching the desired video mode is set for the specified monitor. For more information
/// about full screen windows, including the creation of so called _windowed full screen_ or
/// _borderless full screen_ windows, see window_windowed_full_screen.
///
/// Once you have created the window, you can switch it between windowed and full screen mode with
/// glfw.Window.setMonitor. This will not affect its OpenGL or OpenGL ES context.
///
/// By default, newly created windows use the placement recommended by the window system. To create
/// the window at a specific position, make it initially invisible using the glfw.version window
/// hint, set its position and then show it.
///
/// As long as at least one full screen window is not iconified, the screensaver is prohibited from
/// starting.
///
/// Window systems put limits on window sizes. Very large or very small window dimensions may be
/// overridden by the window system on creation. Check the actual size after creation.
///
/// The swap interval is not set during window creation and the initial value may vary depending on
/// driver settings and defaults.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum, glfw.Error.InvalidValue,
/// glfw.Error.APIUnavailable, glfw.Error.VersionUnavailable, glfw.Error.FormatUnavailable and
/// glfw.Error.PlatformError.
///
/// Parameters are as follows:
///
/// * `width` The desired width, in screen coordinates, of the window.
/// * `height` The desired height, in screen coordinates, of the window.
/// * `title` The initial, UTF-8 encoded window title.
/// * `monitor` The monitor to use for full screen mode, or `null` for windowed mode.
/// * `share` The window whose context to share resources with, or `null` to not share resources.
///
/// win32: Window creation will fail if the Microsoft GDI software OpenGL implementation is the
/// only one available.
///
/// win32: If the executable has an icon resource named `GLFW_ICON`, it will be set as the initial
/// icon for the window. If no such icon is present, the `IDI_APPLICATION` icon will be used
/// instead. To set a different icon, see glfw.Window.setIcon.
///
/// win32: The context to share resources with must not be current on any other thread.
///
/// macos: The OS only supports forward-compatible core profile contexts for OpenGL versions 3.2
/// and later. Before creating an OpenGL context of version 3.2 or later you must set the
/// `glfw.opengl_forward_compat` and `glfw.opengl_profile` hints accordingly. OpenGL 3.0 and 3.1
/// contexts are not supported at all on macOS.
///
/// macos: The GLFW window has no icon, as it is not a document window, but the dock icon will be
/// the same as the application bundle's icon. For more information on bundles, see the
/// [Bundle Programming Guide](https://developer.apple.com/library/mac/documentation/CoreFoundation/Conceptual/CFBundles/)
/// in the Mac Developer Library.
///
/// macos: The first time a window is created the menu bar is created. If GLFW finds a `MainMenu.nib`
/// it is loaded and assumed to contain a menu bar. Otherwise a minimal menu bar is created
/// manually with common commands like Hide, Quit and About. The About entry opens a minimal about
/// dialog with information from the application's bundle. Menu bar creation can be disabled
/// entirely with the glfw.cocoa_menubar init hint.
///
/// macos: On OS X 10.10 and later the window frame will not be rendered at full resolution on
/// Retina displays unless the glfw.cocoa_retina_framebuffer hint is true (1) and the `NSHighResolutionCapable`
/// key is enabled in the application bundle's `Info.plist`. For more information, see
/// [High Resolution Guidelines for OS X](https://developer.apple.com/library/mac/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Explained/Explained.html)
/// in the Mac Developer Library. The GLFW test and example programs use a custom `Info.plist`
/// template for this, which can be found as `CMake/MacOSXBundleInfo.plist.in` in the source tree.
///
/// macos: When activating frame autosaving with glfw.cocoa_frame_name, the specified window size
/// and position may be overridden by previously saved values.
///
/// x11: Some window managers will not respect the placement of initially hidden windows.
///
/// x11: Due to the asynchronous nature of X11, it may take a moment for a window to reach its
/// requested state. This means you may not be able to query the final size, position or other
/// attributes directly after window creation.
///
/// x11: The class part of the `WM_CLASS` window property will by default be set to the window title
/// passed to this function. The instance part will use the contents of the `RESOURCE_NAME`
/// environment variable, if present and not empty, or fall back to the window title. Set the glfw.x11_class_name
/// and glfw.x11_instance_name window hints to override this.
///
/// wayland: Compositors should implement the xdg-decoration protocol for GLFW to decorate the
/// window properly. If this protocol isn't supported, or if the compositor prefers client-side
/// decorations, a very simple fallback frame will be drawn using the wp_viewporter protocol. A
/// compositor can still emit close, maximize or fullscreen events, using for instance a keybind
/// mechanism. If neither of these protocols is supported, the window won't be decorated.
///
/// wayland: A full screen window will not attempt to change the mode, no matter what the
/// requested size or refresh rate.
///
/// wayland: Screensaver inhibition requires the idle-inhibit protocol to be implemented in the
/// user's compositor.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_creation, glfw.Window.destroy
pub inline fn create(width: usize, height: usize, title: [*c]const u8, monitor: ?Monitor, share: ?Window) Error!Window {
    const handle = c.glfwCreateWindow(
        @intCast(c_int, width),
        @intCast(c_int, height),
        &title[0],
        if (monitor) |m| m.handle else null,
        if (share) |w| w.handle else null,
    );
    try getError();
    return from(handle.?);
}

/// Destroys the specified window and its context.
///
/// This function destroys the specified window and its context. On calling this function, no
/// further callbacks will be called for that window.
///
/// If the context of the specified window is current on the main thread, it is detached before
/// being destroyed.
///
/// note: The context of the specified window must not be current on any other thread when this
/// function is called.
///
/// @reentrancy This function must not be called from a callback.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_creation, glfw.Window.create
pub inline fn destroy(self: Window) void {
    const internal = self.getInternal();
    c.glfwDestroyWindow(self.handle);
    std.heap.c_allocator.destroy(internal);

    // Technically, glfwDestroyWindow could produce errors including glfw.Error.NotInitialized and
    // glfw.Error.PlatformError. But how would anybody handle them? By creating a new window to
    // warn the user? That seems user-hostile. Also, `defer try window.destroy()` isn't possible in
    // Zig, so by returning an error we'd make it harder to destroy the window properly. So we differ
    // from GLFW here: we discard any potential error from this operation.
    getError() catch {};
}

/// Checks the close flag of the specified window.
///
/// This function returns the value of the close flag of the specified window.
///
/// @thread_safety This function may be called from any thread. Access is not synchronized.
///
/// see also: window_close
pub inline fn shouldClose(self: Window) bool {
    const flag = c.glfwWindowShouldClose(self.handle);

    // The only error shouldClose could return would be glfw.Error.NotInitialized, which would
    // definitely have occurred before calls to shouldClose. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};

    return flag == c.GLFW_TRUE;
}

/// Sets the close flag of the specified window.
///
/// This function sets the value of the close flag of the specified window. This can be used to
/// override the user's attempt to close the window, or to signal that it should be closed.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function may be called from any thread. Access is not
/// synchronized.
///
/// see also: window_close
pub inline fn setShouldClose(self: Window, value: bool) Error!void {
    const boolean = if (value) c.GLFW_TRUE else c.GLFW_FALSE;
    c.glfwSetWindowShouldClose(self.handle, boolean);
    try getError();
}

/// Sets the UTF-8 encoded title of the specified window.
///
/// This function sets the window title, encoded as UTF-8, of the specified window.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// macos: The window title will not be updated until the next time you process events.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_title
pub inline fn setTitle(self: Window, title: [*c]const u8) Error!void {
    c.glfwSetWindowTitle(self.handle, title);
}

/// Sets the icon for the specified window.
///
/// This function sets the icon of the specified window. If passed an array of candidate images,
/// those of or closest to the sizes desired by the system are selected. If no images are
/// specified, the window reverts to its default icon.
///
/// The pixels are 32-bit, little-endian, non-premultiplied RGBA, i.e. eight bits per channel with
/// the red channel first. They are arranged canonically as packed sequential rows, starting from
/// the top-left corner.
///
/// The desired image sizes varies depending on platform and system settings. The selected images
/// will be rescaled as needed. Good sizes include 16x16, 32x32 and 48x48.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @pointer_lifetime The specified image data is copied before this function returns.
///
/// macos: The GLFW window has no icon, as it is not a document window, so this function does
/// nothing. The dock icon will be the same as the application bundle's icon. For more information
/// on bundles, see the [Bundle Programming Guide](https://developer.apple.com/library/mac/documentation/CoreFoundation/Conceptual/CFBundles/)
/// in the Mac Developer Library.
///
/// wayland: There is no existing protocol to change an icon, the window will thus inherit the one
/// defined in the application's desktop file. This function always emits glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_icon
pub inline fn setIcon(self: Window, allocator: *mem.Allocator, images: ?[]Image) Error!void {
    if (images) |im| {
        const tmp = try allocator.alloc(c.GLFWimage, im.len);
        defer allocator.free(tmp);
        for (im) |img, index| tmp[index] = img.toC();
        c.glfwSetWindowIcon(self.handle, @intCast(c_int, im.len), &tmp[0]);
    } else c.glfwSetWindowIcon(self.handle, 0, null);
    try getError();
}

const Pos = struct {
    x: usize,
    y: usize,
};

/// Retrieves the position of the content area of the specified window.
///
/// This function retrieves the position, in screen coordinates, of the upper-left corner of the
// content area of the specified window.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// wayland: There is no way for an application to retrieve the global position of its windows,
/// this function will always emit glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_pos glfw.Window.setPos
pub inline fn getPos(self: Window) Error!Pos {
    var x: c_int = 0;
    var y: c_int = 0;
    c.glfwGetWindowPos(self.handle, &x, &y);
    try getError();
    return Pos{ .x = @intCast(usize, x), .y = @intCast(usize, y) };
}

/// Sets the position of the content area of the specified window.
///
/// This function sets the position, in screen coordinates, of the upper-left corner of the content
/// area of the specified windowed mode window. If the window is a full screen window, this
/// function does nothing.
///
/// __Do not use this function__ to move an already visible window unless you have very good
/// reasons for doing so, as it will confuse and annoy the user.
///
/// The window manager may put limits on what positions are allowed. GLFW cannot and should not
/// override these limits.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// wayland: There is no way for an application to set the global position of its windows, this
/// function will always emit glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_pos, glfw.Window.getPos
pub inline fn setPos(self: Window, pos: Pos) Error!void {
    c.glfwSetWindowPos(self.handle, @intCast(c_int, pos.x), @intCast(c_int, pos.y));
    try getError();
}

const Size = struct {
    width: usize,
    height: usize,
};

/// Retrieves the size of the content area of the specified window.
///
/// This function retrieves the size, in screen coordinates, of the content area of the specified
/// window. If you wish to retrieve the size of the framebuffer of the window in pixels, see
/// glfw.Window.getFramebufferSize.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_size, glfw.Window.setSize
pub inline fn getSize(self: Window) Error!Size {
    var width: c_int = 0;
    var height: c_int = 0;
    c.glfwGetWindowSize(self.handle, &width, &height);
    try getError();
    return Size{ .width = @intCast(usize, width), .height = @intCast(usize, height) };
}

/// Sets the size of the content area of the specified window.
///
/// This function sets the size, in screen coordinates, of the content area of the specified window.
///
/// For full screen windows, this function updates the resolution of its desired video mode and
/// switches to the video mode closest to it, without affecting the window's context. As the
/// context is unaffected, the bit depths of the framebuffer remain unchanged.
///
/// If you wish to update the refresh rate of the desired video mode in addition to its resolution,
/// see glfw.Window.setMonitor.
///
/// The window manager may put limits on what sizes are allowed. GLFW cannot and should not
/// override these limits.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// wayland: A full screen window will not attempt to change the mode, no matter what the requested
/// size.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_size, glfw.Window.getSize, glfw.Window.SetMonitor
pub inline fn setSize(self: Window, size: Size) Error!void {
    c.glfwSetWindowSize(self.handle, @intCast(c_int, size.width), @intCast(c_int, size.height));
    try getError();
}

/// Sets the size limits of the specified window's content area.
///
/// This function sets the size limits of the content area of the specified window. If the window
/// is full screen, the size limits only take effect/ once it is made windowed. If the window is not
/// resizable, this function does nothing.
///
/// The size limits are applied immediately to a windowed mode window and may cause it to be resized.
///
/// The maximum dimensions must be greater than or equal to the minimum dimensions. glfw.dont_care
/// may be used for any width/height parameter.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidValue and glfw.Error.PlatformError.
///
/// If you set size limits and an aspect ratio that conflict, the results are undefined.
///
/// wayland: The size limits will not be applied until the window is actually resized, either by
/// the user or by the compositor.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_sizelimits, glfw.Window.setAspectRatio
pub inline fn setSizeLimits(self: Window, min: Size, max: Size) Error!void {
    c.glfwSetWindowSizeLimits(
        self.handle,
        @intCast(c_int, min.width),
        @intCast(c_int, min.height),
        @intCast(c_int, max.width),
        @intCast(c_int, max.height),
    );
    try getError();
}

/// Sets the aspect ratio of the specified window.
///
/// This function sets the required aspect ratio of the content area of the specified window. If
/// the window is full screen, the aspect ratio only takes effect once it is made windowed. If the
/// window is not resizable, this function does nothing.
///
/// The aspect ratio is specified as a numerator and a denominator and both values must be greater
/// than zero. For example, the common 16:9 aspect ratio is specified as 16 and 9, respectively.
///
/// If the numerator AND denominator is set to `glfw.dont_care` then the aspect ratio limit is
/// disabled.
///
/// The aspect ratio is applied immediately to a windowed mode window and may cause it to be
/// resized.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidValue and
/// glfw.Error.PlatformError.
///
/// If you set size limits and an aspect ratio that conflict, the results are undefined.
///
/// wayland: The aspect ratio will not be applied until the window is actually resized, either by
/// the user or by the compositor.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_sizelimits, glfw.Window.setSizeLimits
pub inline fn setAspectRatio(self: Window, numerator: usize, denominator: usize) Error!void {
    c.glfwSetWindowAspectRatio(self.handle, @intCast(c_int, numerator), @intCast(c_int, denominator));
    try getError();
}

/// Retrieves the size of the framebuffer of the specified window.
///
/// This function retrieves the size, in pixels, of the framebuffer of the specified window. If you
/// wish to retrieve the size of the window in screen coordinates, see @ref glfwGetWindowSize.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_fbsize, glfwWindow.setFramebufferSizeCallback
pub inline fn getFramebufferSize(self: Window) Error!Size {
    var width: c_int = 0;
    var height: c_int = 0;
    c.glfwGetFramebufferSize(self.handle, &width, &height);
    try getError();
    return Size{ .width = @intCast(usize, width), .height = @intCast(usize, height) };
}

const FrameSize = struct {
    left: usize,
    top: usize,
    right: usize,
    bottom: usize,
};

/// Retrieves the size of the frame of the window.
///
/// This function retrieves the size, in screen coordinates, of each edge of the frame of the
/// specified window. This size includes the title bar, if the window has one. The size of the
/// frame may vary depending on the window-related hints used to create it.
///
/// Because this function retrieves the size of each window frame edge and not the offset along a
/// particular coordinate axis, the retrieved values will always be zero or positive.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_size
pub inline fn getFrameSize(self: Window) Error!FrameSize {
    var left: c_int = 0;
    var top: c_int = 0;
    var right: c_int = 0;
    var bottom: c_int = 0;
    c.glfwGetWindowFrameSize(self.handle, &left, &top, &right, &bottom);
    try getError();
    return FrameSize{
        .left = @intCast(usize, left),
        .top = @intCast(usize, top),
        .right = @intCast(usize, right),
        .bottom = @intCast(usize, bottom),
    };
}

pub const ContentScale = struct {
    x_scale: f32,
    y_scale: f32,
};

/// Retrieves the content scale for the specified window.
///
/// This function retrieves the content scale for the specified window. The content scale is the
/// ratio between the current DPI and the platform's default DPI. This is especially important for
/// text and any UI elements. If the pixel dimensions of your UI scaled by this look appropriate on
/// your machine then it should appear at a reasonable size on other machines regardless of their
/// DPI and scaling settings. This relies on the system DPI and scaling settings being somewhat
/// correct.
///
/// On systems where each monitors can have its own content scale, the window content scale will
/// depend on which monitor the system considers the window to be on.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_scale, glfwSetWindowContentScaleCallback, glfwGetMonitorContentScale
pub inline fn getContentScale(self: Window) Error!ContentScale {
    var x_scale: f32 = 0;
    var y_scale: f32 = 0;
    c.glfwGetWindowContentScale(self.handle, &x_scale, &y_scale);
    try getError();
    return ContentScale{ .x_scale = x_scale, .y_scale = y_scale };
}

/// Returns the opacity of the whole window.
///
/// This function returns the opacity of the window, including any decorations.
///
/// The opacity (or alpha) value is a positive finite number between zero and one, where zero is
/// fully transparent and one is fully opaque. If the system does not support whole window
/// transparency, this function always returns one.
///
/// The initial opacity value for newly created windows is one.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_transparency, glfw.Window.setOpacity
pub inline fn getOpacity(self: Window) Error!f32 {
    const opacity = c.glfwGetWindowOpacity(self.handle);
    try getError();
    return opacity;
}

/// Sets the opacity of the whole window.
///
/// This function sets the opacity of the window, including any decorations.
///
/// The opacity (or alpha) value is a positive finite number between zero and one, where zero is
/// fully transparent and one is fully opaque.
///
/// The initial opacity value for newly created windows is one.
///
/// A window created with framebuffer transparency may not use whole window transparency. The
/// results of doing this are undefined.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_transparency, glfw.Window.getOpacity
pub inline fn setOpacity(self: Window, opacity: f32) Error!void {
    c.glfwSetWindowOpacity(self.handle, opacity);
    try getError();
}

/// Iconifies the specified window.
///
/// This function iconifies (minimizes) the specified window if it was previously restored. If the
/// window is already iconified, this function does nothing.
///
/// If the specified window is a full screen window, the original monitor resolution is restored
/// until the window is restored.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// wayland: There is no concept of iconification in wl_shell, this function will emit
/// glfw.Error.PlatformError when using this deprecated protocol.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_iconify, glfw.Window.restore, glfw.Window.maximize
pub inline fn iconify(self: Window) Error!void {
    c.glfwIconifyWindow(self.handle);
    try getError();
}

/// Restores the specified window.
///
/// This function restores the specified window if it was previously iconified (minimized) or
/// maximized. If the window is already restored, this function does nothing.
///
/// If the specified window is a full screen window, the resolution chosen for the window is
/// restored on the selected monitor.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_iconify, glfw.Window.iconify, glfw.Window.maximize
pub inline fn restore(self: Window) Error!void {
    c.glfwRestoreWindow(self.handle);
    try getError();
}

/// Maximizes the specified window.
///
/// This function maximizes the specified window if it was previously not maximized. If the window
/// is already maximized, this function does nothing.
///
/// If the specified window is a full screen window, this function does nothing.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_iconify, glfw.Window.iconify, glfw.Window.restore
pub inline fn maximize(self: Window) Error!void {
    c.glfwMaximizeWindow(self.handle);
    try getError();
}

/// Makes the specified window visible.
///
/// This function makes the specified window visible if it was previously hidden. If the window is
/// already visible or is in full screen mode, this function does nothing.
///
/// By default, windowed mode windows are focused when shown Set the glfw.focus_on_show window hint
/// to change this behavior for all newly created windows, or change the
/// behavior for an existing window with glfw.Window.setAttrib.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_hide, glfw.Window.hide
pub inline fn show(self: Window) Error!void {
    c.glfwShowWindow(self.handle);
    try getError();
}

/// Hides the specified window.
///
/// This function hides the specified window if it was previously visible. If the window is already
/// hidden or is in full screen mode, this function does nothing.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_hide, glfw.Window.show
pub inline fn hide(self: Window) Error!void {
    c.glfwHideWindow(self.handle);
    try getError();
}

/// Brings the specified window to front and sets input focus.
///
/// This function brings the specified window to front and sets input focus. The window should
/// already be visible and not iconified.
///
/// By default, both windowed and full screen mode windows are focused when initially created. Set
/// the glfw.focused to disable this behavior.
///
/// Also by default, windowed mode windows are focused when shown with glfw.Window.show. Set the
/// glfw.focus_on_show to disable this behavior.
///
/// __Do not use this function__ to steal focus from other applications unless you are certain that
/// is what the user wants. Focus stealing can be extremely disruptive.
///
/// For a less disruptive way of getting the user's attention, see [attention requests (window_attention).
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// wayland: It is not possible for an application to bring its windows
/// to front, this function will always emit glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_focus, window_attention
pub inline fn focus(self: Window) Error!void {
    c.glfwFocusWindow(self.handle);
    try getError();
}

/// Requests user attention to the specified window.
///
/// This function requests user attention to the specified window. On platforms where this is not
/// supported, attention is requested to the application as a whole.
///
/// Once the user has given attention, usually by focusing the window or application, the system will end the request automatically.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// macos: Attention is requested to the application as a whole, not the
/// specific window.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_attention
pub inline fn requestAttention(self: Window) Error!void {
    c.glfwRequestWindowAttention(self.handle);
    try getError();
}

/// Swaps the front and back buffers of the specified window.
///
/// This function swaps the front and back buffers of the specified window when rendering with
/// OpenGL or OpenGL ES. If the swap interval is greater than zero, the GPU driver waits the
/// specified number of screen updates before swapping the buffers.
///
/// The specified window must have an OpenGL or OpenGL ES context. Specifying a window without a
/// context will generate Error.NoWindowContext.
///
/// This function does not apply to Vulkan. If you are rendering with Vulkan, see `vkQueuePresentKHR`
/// instead.
///
/// @param[in] window The window whose buffers to swap.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.NoWindowContext and glfw.Error.PlatformError.
///
/// __EGL:__ The context of the specified window must be current on the calling thread.
///
/// @thread_safety This function may be called from any thread.
///
/// see also: buffer_swap, glfwSwapInterval
pub inline fn swapBuffers(self: Window) Error!void {
    c.glfwSwapBuffers(self.handle);
    try getError();
}

/// Returns the monitor that the window uses for full screen mode.
///
/// This function returns the handle of the monitor that the specified window is in full screen on.
///
/// @return The monitor, or null if the window is in windowed mode.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_monitor, glfw.Window.setMonitor
pub inline fn getMonitor(self: Window) Error!?Monitor {
    const monitor = c.glfwGetWindowMonitor(self.handle);
    try getError();
    if (monitor) |m| return Monitor{ .handle = m };
    return null;
}

/// Sets the mode, monitor, video mode and placement of a window.
///
/// This function sets the monitor that the window uses for full screen mode or, if the monitor is
/// null, makes it windowed mode.
///
/// When setting a monitor, this function updates the width, height and refresh rate of the desired
/// video mode and switches to the video mode closest to it. The window position is ignored when
/// setting a monitor.
///
/// When the monitor is null, the position, width and height are used to place the window content
/// area. The refresh rate is ignored when no monitor is specified.
///
/// If you only wish to update the resolution of a full screen window or the size of a windowed
/// mode window, see @ref glfwSetWindowSize.
///
/// When a window transitions from full screen to windowed mode, this function restores any
/// previous window settings such as whether it is decorated, floating, resizable, has size or
/// aspect ratio limits, etc.
///
/// @param[in] window The window whose monitor, size or video mode to set.
/// @param[in] monitor The desired monitor, or null to set windowed mode.
/// @param[in] xpos The desired x-coordinate of the upper-left corner of the content area.
/// @param[in] ypos The desired y-coordinate of the upper-left corner of the content area.
/// @param[in] width The desired with, in screen coordinates, of the content area or video mode.
/// @param[in] height The desired height, in screen coordinates, of the content area or video mode.
/// @param[in] refreshRate The desired refresh rate, in Hz, of the video mode, or `glfw.dont_care`.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// The OpenGL or OpenGL ES context will not be destroyed or otherwise affected by any resizing or
/// mode switching, although you may need to update your viewport if the framebuffer size has
/// changed.
///
/// wayland: The desired window position is ignored, as there is no way for an application to set
/// this property.
///
/// wayland: Setting the window to full screen will not attempt to change the mode, no matter what
/// the requested size or refresh rate.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_monitor, window_full_screen, glfw.Window.getMonitor, glfw.Window.setSize
pub inline fn setMonitor(self: Window, monitor: ?Monitor, xpos: isize, ypos: isize, width: isize, height: isize, refresh_rate: isize) Error!void {
    c.glfwSetWindowMonitor(
        self.handle,
        if (monitor) |m| m.handle else null,
        @intCast(c_int, xpos),
        @intCast(c_int, ypos),
        @intCast(c_int, width),
        @intCast(c_int, height),
        @intCast(c_int, refresh_rate),
    );
    try getError();
}

/// Returns an attribute of the specified window.
///
/// This function returns the value of an attribute of the specified window or its OpenGL or OpenGL
/// ES context.
///
/// @param[in] attrib The window attribute (see window_attribs) whose value to return.
/// @return The value of the attribute, or zero if an error occurred.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
///
/// Framebuffer related hints are not window attributes. See window_attribs_fb for more information.
///
/// Zero is a valid value for many window and context related attributes so you cannot use a return
/// value of zero as an indication of errors. However, this function should not fail as long as it
/// is passed valid arguments and the library has been initialized.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_attribs, glfw.Window.setAttrib
pub inline fn getAttrib(self: Window, attrib: isize) Error!isize {
    const v = c.glfwGetWindowAttrib(self.handle, @intCast(c_int, attrib));
    try getError();
    return v;
}

/// Sets an attribute of the specified window.
///
/// This function sets the value of an attribute of the specified window.
///
/// The supported attributes are glfw.decorated, glfw.resizable, glfw.floating, glfw.auto_iconify,
/// glfw.focus_on_show.
///
/// Some of these attributes are ignored for full screen windows. The new value will take effect
/// if the window is later made windowed.
///
/// Some of these attributes are ignored for windowed mode windows. The new value will take effect
/// if the window is later made full screen.
///
/// @param[in] attrib A supported window attribute.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum, glfw.Error.InvalidValue and glfw.Error.PlatformError.
///
/// Calling glfw.Window.getAttrib will always return the latest
/// value, even if that value is ignored by the current mode of the window.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_attribs, glfw.Window.getAttrib
///
pub inline fn setAttrib(self: Window, attrib: isize, value: bool) Error!void {
    c.glfwSetWindowAttrib(self.handle, @intCast(c_int, attrib), if (value) c.GLFW_TRUE else c.GLFW_FALSE);
    try getError();
}

pub inline fn getInternal(self: Window) *InternalUserPointer {
    const ptr = c.glfwGetWindowUserPointer(self.handle);
    if (ptr) |p| return @ptrCast(*InternalUserPointer, @alignCast(@alignOf(*InternalUserPointer), p));
    @panic("expected GLFW window user pointer to be *glfw.Window.InternalUserPointer, found null");
}

/// Sets the user pointer of the specified window.
///
/// This function sets the user-defined pointer of the specified window. The current value is
/// retained until the window is destroyed. The initial value is null.
///
/// @thread_safety This function may be called from any thread. Access is not synchronized.
///
/// see also: window_userptr, glfw.Window.getUserPointer
pub inline fn setUserPointer(self: Window, Type: anytype, pointer: Type) void {
    var internal = self.getInternal();
    internal.user_pointer = @ptrCast(*c_void, pointer);
}

/// Returns the user pointer of the specified window.
///
/// This function returns the current value of the user-defined pointer of the specified window.
/// The initial value is null.
///
/// @thread_safety This function may be called from any thread. Access is not synchronized.
///
/// see also: window_userptr, glfw.Window.setUserPointer
pub inline fn getUserPointer(self: Window, Type: anytype) ?Type {
    var internal = self.getInternal();
    if (internal.user_pointer) |p| return @ptrCast(Type, @alignCast(@alignOf(Type), p));
    return null;
}

fn setPosCallbackWrapper(handle: ?*c.GLFWwindow, xpos: c_int, ypos: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setPosCallback.?(window, @intCast(isize, xpos), @intCast(isize, ypos));
}

/// Sets the position callback for the specified window.
///
/// This function sets the position callback of the specified window, which is called when the
/// window is moved. The callback is provided with the position, in screen coordinates, of the
/// upper-left corner of the content area of the window.
///
/// @param[in] callback The new callback, or null to remove the currently set callback.
///
/// @callback_param `window` the window that moved.
/// @callback_param `xpos` the new x-coordinate, in screen coordinates, of the upper-left corner of
/// the content area of the window. 
/// @callback_param `ypos` the new y-coordinate, in screen coordinates, of the upper-left corner of
/// the content area of the window. 
///
/// wayland: This callback will never be called, as there is no way for an application to know its
/// global position.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_pos
pub inline fn setPosCallback(self: Window, callback: ?fn (window: Window, xpos: isize, ypos: isize) void) void {
    var internal = self.getInternal();
    internal.setPosCallback = callback;
    _ = c.glfwSetWindowPosCallback(self.handle, if (callback != null) setPosCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setSizeCallbackWrapper(handle: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setSizeCallback.?(window, @intCast(isize, width), @intCast(isize, height));
}

/// Sets the size callback for the specified window.
///
/// This function sets the size callback of the specified window, which is called when the window
/// is resized. The callback is provided with the size, in screen coordinates, of the content area
/// of the window.
///
/// @callback_param `window` the window that was resized.
/// @callback_param `width` the new width, in screen coordinates, of the window.
/// @callback_param `height` the new height, in screen coordinates, of the window.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_size
pub inline fn setSizeCallback(self: Window, callback: ?fn (window: Window, width: isize, height: isize) void) void {
    var internal = self.getInternal();
    internal.setSizeCallback = callback;
    _ = c.glfwSetWindowSizeCallback(self.handle, if (callback != null) setSizeCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setCloseCallbackWrapper(handle: ?*c.GLFWwindow) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setCloseCallback.?(window);
}

/// Sets the close callback for the specified window.
///
/// This function sets the close callback of the specified window, which is called when the user
/// attempts to close the window, for example by clicking the close widget in the title bar.
///
/// The close flag is set before this callback is called, but you can modify it at any time with
/// glfw.Window.setShouldClose.
///
/// The close callback is not triggered by glfw.Window.destroy.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new callback, or null to remove the currently set callback.
///
/// @callback_param `window` the window that the user attempted to close.
///
/// macos: Selecting Quit from the application menu will trigger the close callback for all
/// windows.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_close
pub inline fn setCloseCallback(self: Window, callback: ?fn (window: Window) void) void {
    var internal = self.getInternal();
    internal.setCloseCallback = callback;
    _ = c.glfwSetWindowCloseCallback(self.handle, if (callback != null) setCloseCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setRefreshCallbackWrapper(handle: ?*c.GLFWwindow) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setRefreshCallback.?(window);
}

// /// Sets the refresh callback for the specified window.
// ///
// /// This function sets the refresh callback of the specified window, which is
// /// called when the content area of the window needs to be redrawn, for example
// /// if the window has been exposed after having been covered by another window.
// ///
// /// On compositing window systems such as Aero, Compiz, Aqua or Wayland, where
// /// the window contents are saved off-screen, this callback may be called only
// /// very infrequently or never at all.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// ///
// /// @callback_param `window` the window whose content needs to be refreshed.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_refresh
// GLFWAPI GLFWwindowrefreshfun glfwSetWindowRefreshCallback(GLFWwindow* window, GLFWwindowrefreshfun callback);
pub inline fn setRefreshCallback(self: Window, callback: ?fn (window: Window) void) void {
    var internal = self.getInternal();
    internal.setRefreshCallback = callback;
    _ = c.glfwSetWindowRefreshCallback(self.handle, if (callback != null) setRefreshCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setFocusCallbackWrapper(handle: ?*c.GLFWwindow, focused: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setFocusCallback.?(window, if (focused == c.GLFW_TRUE) true else false);
}

/// Sets the focus callback for the specified window.
///
/// This function sets the focus callback of the specified window, which is
/// called when the window gains or loses input focus.
///
/// After the focus callback is called for a window that lost input focus,
/// synthetic key and mouse button release events will be generated for all such
/// that had been pressed. For more information, see @ref glfwSetKeyCallback
/// and @ref glfwSetMouseButtonCallback.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new callback, or null to remove the currently set
/// callback.
///
/// @callback_param `window` the window whose input focus has changed.
/// @callback_param `focused` `true` if the window was given input focus, or `false` if it lost it.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_focus
pub inline fn setFocusCallback(self: Window, callback: ?fn (window: Window, focused: bool) void) void {
    var internal = self.getInternal();
    internal.setFocusCallback = callback;
    _ = c.glfwSetWindowFocusCallback(self.handle, if (callback != null) setFocusCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setIconifyCallbackWrapper(handle: ?*c.GLFWwindow, iconified: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setIconifyCallback.?(window, if (iconified == c.GLFW_TRUE) true else false);
}

/// Sets the iconify callback for the specified window.
///
/// This function sets the iconification callback of the specified window, which
/// is called when the window is iconified or restored.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new callback, or null to remove the currently set
/// callback.
///
/// @callback_param `window` the window which was iconified or restored.
/// @callback_param `iconified` `true` if the window was iconified, or `false` if it was restored.
///
/// wayland: The wl_shell protocol has no concept of iconification,
/// this callback will never be called when using this deprecated protocol.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_iconify
pub inline fn setIconifyCallback(self: Window, callback: ?fn (window: Window, iconified: bool) void) void {
    var internal = self.getInternal();
    internal.setIconifyCallback = callback;
    _ = c.glfwSetWindowIconifyCallback(self.handle, if (callback != null) setIconifyCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setMaximizeCallbackWrapper(handle: ?*c.GLFWwindow, maximized: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setMaximizeCallback.?(window, if (maximized == c.GLFW_TRUE) true else false);
}

/// Sets the maximize callback for the specified window.
///
/// This function sets the maximization callback of the specified window, which
/// is called when the window is maximized or restored.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new callback, or null to remove the currently set
/// callback.
///
/// @callback_param `window` the window which was maximized or restored.
/// @callback_param `maximized` `true` if the window was maximized, or `false` if it was restored.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_maximize
// GLFWAPI GLFWwindowmaximizefun glfwSetWindowMaximizeCallback(GLFWwindow* window, GLFWwindowmaximizefun callback);
pub inline fn setMaximizeCallback(self: Window, callback: ?fn (window: Window, maximized: bool) void) void {
    var internal = self.getInternal();
    internal.setMaximizeCallback = callback;
    _ = c.glfwSetWindowMaximizeCallback(self.handle, if (callback != null) setMaximizeCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setFramebufferSizeCallbackWrapper(handle: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setFramebufferSizeCallback.?(window, @intCast(isize, width), @intCast(isize, height));
}

/// Sets the framebuffer resize callback for the specified window.
///
/// This function sets the framebuffer resize callback of the specified window,
/// which is called when the framebuffer of the specified window is resized.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new callback, or null to remove the currently set
/// callback.
///
/// @callback_param `window` the window whose framebuffer was resized.
/// @callback_param `width` the new width, in pixels, of the framebuffer.
/// @callback_param `height` the new height, in pixels, of the framebuffer.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_fbsize
pub inline fn setFramebufferSizeCallback(self: Window, callback: ?fn (window: Window, width: isize, height: isize) void) void {
    var internal = self.getInternal();
    internal.setFramebufferSizeCallback = callback;
    _ = c.glfwSetFramebufferSizeCallback(self.handle, if (callback != null) setFramebufferSizeCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setContentScaleCallbackWrapper(handle: ?*c.GLFWwindow, xscale: f32, yscale: f32) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setContentScaleCallback.?(window, xscale, yscale);
}

/// Sets the window content scale callback for the specified window.
///
/// This function sets the window content scale callback of the specified window,
/// which is called when the content scale of the specified window changes.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new callback, or null to remove the currently set
/// callback.
///
/// @callback_param `window` the window whose content scale changed.
/// @callback_param `xscale` the new x-axis content scale of the window.
/// @callback_param `yscale` the new y-axis content scale of the window.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_scale, glfw.Window.getContentScale
pub inline fn setContentScaleCallback(self: Window, callback: ?fn (window: Window, xscale: f32, yscale: f32) void) void {
    var internal = self.getInternal();
    internal.setContentScaleCallback = callback;
    _ = c.glfwSetWindowContentScaleCallback(self.handle, if (callback != null) setContentScaleCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

// TODO(mouinput options)
// /// Returns the value of an input option for the specified window.
// ///
// /// This function returns the value of an input option for the specified window.
// /// The mode must be one of @ref GLFW_CURSOR, @ref GLFW_STICKY_KEYS,
// /// @ref GLFW_STICKY_MOUSE_BUTTONS, @ref GLFW_LOCK_KEY_MODS or
// /// @ref GLFW_RAW_MOUSE_MOTION.
// ///
// /// @param[in] window The window to query.
// /// @param[in] mode One of `GLFW_CURSOR`, `GLFW_STICKY_KEYS`,
// /// `GLFW_STICKY_MOUSE_BUTTONS`, `GLFW_LOCK_KEY_MODS` or
// /// `GLFW_RAW_MOUSE_MOTION`.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: glfw.setInputMode
// GLFWAPI int glfwGetInputMode(GLFWwindow* window, int mode);

/// Sets an input option for the specified window.
///
/// This function sets an input mode option for the specified window. The mode must be one of
/// `glfw.cursor`, `glfw.sticky_keys`, `glfw.sticky_mouse_buttons`, `glfw.lock_key_mods`, or
/// `glfw.raw_mouse_motion`.
///
/// If the mode is `glfw.cursor`, the value must be one of the following cursor
/// modes:
/// - `glfw.cursor_normal` makes the cursor visible and behaving normally.
/// - `glfw.cursor_hidden` makes the cursor invisible when it is over the content area of the window
///   but does not restrict the cursor from leaving.
/// - `glfw.cursor_disabled` hides and grabs the cursor, providing virtual and unlimited cursor
///   movement. This is useful for implementing for example 3D camera controls.
///
/// If the mode is `glfw.sticky_keys`, the value must be either `true` to enable sticky keys, or
/// `false` to disable it. If sticky keys are enabled, a key press will ensure that `glfw.Window.getKey`
/// `true` (pressed) the next time it is called even if the key had been released before the call.
/// This is useful when you are only interested in whether keys have been pressed but not when or in
/// which order.
///
/// If the mode is `glfw.sticky_mouse_buttons`, the value must be either `true` to enable sticky
/// mouse buttons, or `false` to disable it. If sticky mouse buttons are enabled, a mouse button
/// press will ensure that glfw.Window.getMouseButton returns `glfw.press` the next time it is
/// called even if the mouse button had been released before the call. This is useful when you are
/// only interested in whether mouse buttons have been pressed but not when or in which order.
///
/// If the mode is `glfw.lock_key_mods`, the value must be either `true` to enable lock key modifier
/// bits, or `false` to disable them. If enabled, callbacks that receive modifier bits will also
/// have the glfw.mod.caps_lock bit set when the event was generated with Caps Lock on, and the
/// glfw.mod.num_lock bit when Num Lock was on.
///
/// If the mode is `glfw.raw_mouse_motion`, the value must be either `true` to enable raw (unscaled
/// and unaccelerated) mouse motion when the cursor is disabled, or `false` to disable it. If raw
/// motion is not supported, attempting to set this will emit glfw.Error.PlatformError. Call
/// glfw.rawMouseMotionSupported to check for support.
///
/// @param[in] mode One of `glfw.cursor`, `glfw.sticky_keys`, `glfw.sticky_mouse_buttons`,
/// `glfw.lock_key_mods` or `glfw.raw_mouse_motion`.
/// @param[in] value The new value of the specified input mode.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: glfw.getInputMode
pub inline fn setInputMode(self: Window, mode: isize, value: anytype) Error!void {
    switch (@typeInfo(@TypeOf(value))) {
        .Int, .ComptimeInt => c.glfwSetInputMode(self.handle, @intCast(c_int, mode), @intCast(c_int, value)),
        .Bool => c.glfwSetInputMode(self.handle, @intCast(c_int, mode), @intCast(c_int, @boolToInt(value))),
        else => @compileError("expected a int or bool, got " ++ @typeName(@TypeOf(value))),
    }
    try getError();
}

/// Returns the last reported press state of a keyboard key for the specified window.
///
/// This function returns the last press state reported for the specified key to the specified
/// window. The returned state is one of `true` (pressed) or `false` (released). The higher-level
/// action `glfw.repeat` is only reported to the key callback.
///
/// If the `glfw.sticky_keys` input mode is enabled, this function returns `glfw.press` the first
/// time you call it for a key that was pressed, even if that key has already been released.
///
/// The key functions deal with physical keys, with key tokens (see keys) named after their use on
/// the standard US keyboard layout. If you want to input text, use the Unicode character callback
/// instead.
///
/// The modifier key bit masks (see mods) are not key tokens and cannot be used with this function.
///
/// __Do not use this function__ to implement text input, use glfw.Window.setCharCallback instead.
///
/// @param[in] window The desired window.
/// @param[in] key The desired keyboard key (see keys). `glfw.key.unknown` is not a valid key for
/// this function.
/// @return `true` (pressed) or `false` (released)
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: input_key
pub inline fn getKey(self: Window, key: isize) Error!bool {
    const state = c.glfwGetKey(self.handle, @intCast(c_int, key));
    try getError();
    return state == c.GLFW_PRESS;
}

/// Returns the last reported state of a mouse button for the specified window.
///
/// This function returns whether the specified mouse button is pressed or not.
///
/// If the glfw.sticky_mouse_buttons input mode is enabled, this function returns `true` the first
/// time you call it for a mouse button that was pressed, even if that mouse button has already been
/// released.
///
/// @param[in] button The desired mouse button.
/// @return One of `true` (if pressed) or `false` (if released)
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: input_mouse_button
pub inline fn getMouseButton(self: Window, button: isize) Error!bool {
    const state = c.glfwGetMouseButton(self.handle, @intCast(c_int, button));
    try getError();
    return state == c.GLFW_PRESS;
}

const CursorPos = struct {
    xpos: f64,
    ypos: f64,
};

/// Retrieves the position of the cursor relative to the content area of the window.
///
/// This function returns the position of the cursor, in screen coordinates, relative to the
/// upper-left corner of the content area of the specified window.
///
/// If the cursor is disabled (with `glfw.cursor_disabled`) then the cursor position is unbounded
/// and limited only by the minimum and maximum values of a `f64`.
///
/// The coordinate can be converted to their integer equivalents with the `floor` function. Casting
/// directly to an integer type works for positive coordinates, but fails for negative ones.
///
/// Any or all of the position arguments may be null. If an error occurs, all non-null position
/// arguments will be set to zero.
///
/// @param[in] window The desired window.
/// @param[out] xpos Where to store the cursor x-coordinate, relative to the left edge of the
/// content area, or null.
/// @param[out] ypos Where to store the cursor y-coordinate, relative to the to top edge of the
/// content area, or null.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: cursor_pos, glfw.Window.setCursorPos
pub inline fn getCursorPos(self: Window) Error!CursorPos {
    var pos: CursorPos = undefined;
    c.glfwGetCursorPos(self.handle, &pos.xpos, &pos.ypos);
    try getError();
    return pos;
}

/// Sets the position of the cursor, relative to the content area of the window.
///
/// This function sets the position, in screen coordinates, of the cursor relative to the upper-left
/// corner of the content area of the specified window. The window must have input focus. If the
/// window does not have input focus when this function is called, it fails silently.
///
/// __Do not use this function__ to implement things like camera controls. GLFW already provides the
/// `glfw.cursor_disabled` cursor mode that hides the cursor, transparently re-centers it and
/// provides unconstrained cursor motion. See glfw.Window.setInputMode for more information.
///
/// If the cursor mode is `glfw.cursor_disabled` then the cursor position is unconstrained and
/// limited only by the minimum and maximum values of a `double`.
///
/// @param[in] window The desired window.
/// @param[in] xpos The desired x-coordinate, relative to the left edge of the content area.
/// @param[in] ypos The desired y-coordinate, relative to the top edge of the content area.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// wayland: This function will only work when the cursor mode is `glfw.cursor_disabled`, otherwise
/// it will do nothing.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: cursor_pos, glfw.Window.getCursorPos
pub inline fn setCursorPos(self: Window, xpos: f64, ypos: f64) Error!void {
    c.glfwSetCursorPos(self.handle, xpos, ypos);
    try getError();
}

/// Sets the cursor for the window.
///
/// This function sets the cursor image to be used when the cursor is over the content area of the
/// specified window. The set cursor will only be visible when the cursor mode (see cursor_mode) of
/// the window is `glfw.Cursor.normal`.
///
/// On some platforms, the set cursor may not be visible unless the window also has input focus.
///
/// @param[in] cursor The cursor to set, or null to switch back to the default arrow cursor.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: cursor_object
pub inline fn setCursor(self: Window, cursor: Cursor) Error!void {
    c.glfwSetCursor(self.handle, cursor.ptr);
    try getError();
}

fn setKeyCallbackWrapper(handle: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setKeyCallback.?(window, @intCast(isize, key), @intCast(isize, scancode), @intCast(isize, action), @intCast(isize, mods));
}

/// Sets the key callback.
///
/// This function sets the key callback of the specified window, which is called when a key is
/// pressed, repeated or released.
///
/// The key functions deal with physical keys, with layout independent key tokens (see keys) named
/// after their values in the standard US keyboard layout. If you want to input text, use the
/// character callback (see glfw.Window.setCharCallback) instead.
///
/// When a window loses input focus, it will generate synthetic key release events for all pressed
/// keys. You can tell these events from user-generated events by the fact that the synthetic ones
/// are generated after the focus loss event has been processed, i.e. after the window focus
/// callback (see glfw.Window.setFocusCallback) has been called.
///
/// The scancode of a key is specific to that platform or sometimes even to that machine. Scancodes
/// are intended to allow users to bind keys that don't have a GLFW key token. Such keys have `key`
/// set to `glfw.key.unknown`, their state is not saved and so it cannot be queried with
/// glfw.Window.getKey.
///
/// Sometimes GLFW needs to generate synthetic key events, in which case the scancode may be zero.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new key callback, or null to remove the currently set callback.
///
/// @callback_param[in] window The window that received the event.
/// @callback_param[in] key The keyboard key (see keys) that was pressed or released.
/// @callback_param[in] scancode The system-specific scancode of the key.
/// @callback_param[in] action `glfw.press`, `glfw.release` or `glfw.repeat`. Future releases may
/// add more actions.
/// @callback_param[in] mods Bit field describing which modifier keys (see mods) were held down.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: input_key
pub inline fn setKeyCallback(self: Window, callback: ?fn (window: Window, key: isize, scancode: isize, action: isize, mods: isize) void) void {
    var internal = self.getInternal();
    internal.setKeyCallback = callback;
    _ = c.glfwSetKeyCallback(self.handle, if (callback != null) setKeyCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setCharCallbackWrapper(handle: ?*c.GLFWwindow, codepoint: c_uint) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setCharCallback.?(window, @intCast(u21, codepoint));
}

/// Sets the Unicode character callback.
///
/// This function sets the character callback of the specified window, which is called when a
/// Unicode character is input.
///
/// The character callback is intended for Unicode text input. As it deals with characters, it is
/// keyboard layout dependent, whereas the key callback (see glfw.Window.setKeyCallback) is not.
/// Characters do not map 1:1 to physical keys, as a key may produce zero, one or more characters.
/// If you want to know whether a specific physical key was pressed or released, see the key
/// callback instead.
///
/// The character callback behaves as system text input normally does and will not be called if
/// modifier keys are held down that would prevent normal text input on that platform, for example a
/// Super (Command) key on macOS or Alt key on Windows.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new callback, or null to remove the currently set callback.
///
/// @callback_param[in] window The window that received the event.
/// @callback_param[in] codepoint The Unicode code point of the character.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: input_char
pub inline fn setCharCallback(self: Window, callback: ?fn (window: Window, codepoint: u21) void) void {
    var internal = self.getInternal();
    internal.setCharCallback = callback;
    _ = c.glfwSetCharCallback(self.handle, if (callback != null) setCharCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setMouseButtonCallbackWrapper(handle: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setMouseButtonCallback.?(window, @intCast(isize, button), @intCast(isize, action), @intCast(isize, mods));
}

/// Sets the mouse button callback.
///
/// This function sets the mouse button callback of the specified window, which is called when a
/// mouse button is pressed or released.
///
/// When a window loses input focus, it will generate synthetic mouse button release events for all
/// pressed mouse buttons. You can tell these events from user-generated events by the fact that the
/// synthetic ones are generated after the focus loss event has been processed, i.e. after the
/// window focus callback (see glfw.Window.setFocusCallback) has been called.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new callback, or null to remove the currently set callback.
///
/// @callback_param[in] window The window that received the event.
/// @callback_param[in] button The mouse button that was pressed or released.
/// @callback_param[in] action One of `glfw.press` or `glfw.release`. Future releases may add more
/// actions.
/// @callback_param[in] mods Bit field describing which modifier keys (see mods) were held down.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: input_mouse_button
pub inline fn setMouseButtonCallback(self: Window, callback: ?fn (window: Window, button: isize, action: isize, mods: isize) void) void {
    var internal = self.getInternal();
    internal.setMouseButtonCallback = callback;
    _ = c.glfwSetMouseButtonCallback(self.handle, if (callback != null) setMouseButtonCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setCursorPosCallbackWrapper(handle: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setCursorPosCallback.?(window, xpos, ypos);
}

/// Sets the cursor position callback.
///
/// This function sets the cursor position callback of the specified window, which is called when
/// the cursor is moved. The callback is provided with the position, in screen coordinates, relative
/// to the upper-left corner of the content area of the window.
///
/// @param[in] callback The new callback, or null to remove the currently set callback.
///
/// @callback_param[in] window The window that received the event.
/// @callback_param[in] xpos The new cursor x-coordinate, relative to the left edge of the content
/// area.
/// callback_@param[in] ypos The new cursor y-coordinate, relative to the top edge of the content
/// area.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: cursor_pos
pub inline fn setCursorPosCallback(self: Window, callback: ?fn (window: Window, xpos: f64, ypos: f64) void) void {
    var internal = self.getInternal();
    internal.setCursorPosCallback = callback;
    _ = c.glfwSetCursorPosCallback(self.handle, if (callback != null) setCursorPosCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setCursorEnterCallbackWrapper(handle: ?*c.GLFWwindow, entered: c_int) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setCursorEnterCallback.?(window, entered == c.GLFW_TRUE);
}

/// Sets the cursor enter/leave callback.
///
/// This function sets the cursor boundary crossing callback of the specified window, which is
/// called when the cursor enters or leaves the content area of the window.
///
/// @param[in] callback The new callback, or null to remove the currently set callback.
///
/// @callback_param[in] window The window that received the event.
/// @callback_param[in] entered `true` if the cursor entered the window's content area, or `false`
/// if it left it.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: cursor_enter
pub inline fn setCursorEnterCallback(self: Window, callback: ?fn (window: Window, entered: bool) void) void {
    var internal = self.getInternal();
    internal.setCursorEnterCallback = callback;
    _ = c.glfwSetCursorEnterCallback(self.handle, if (callback != null) setCursorEnterCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setScrollCallbackWrapper(handle: ?*c.GLFWwindow, xoffset: f64, yoffset: f64) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setScrollCallback.?(window, xoffset, yoffset);
}

/// Sets the scroll callback.
///
/// This function sets the scroll callback of the specified window, which is called when a scrolling
/// device is used, such as a mouse wheel or scrolling area of a touchpad.
///
/// The scroll callback receives all scrolling input, like that from a mouse wheel or a touchpad
/// scrolling area.
///
/// @param[in] window The window whose callback to set.
/// @param[in] callback The new scroll callback, or null to remove the currently set callback.
///
/// @callback_param[in] window The window that received the event.
/// @callback_param[in] xoffset The scroll offset along the x-axis.
/// @callback_param[in] yoffset The scroll offset along the y-axis.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: scrolling
pub inline fn setScrollCallback(self: Window, callback: ?fn (window: Window, xoffset: f64, yoffset: f64) void) void {
    var internal = self.getInternal();
    internal.setScrollCallback = callback;
    _ = c.glfwSetScrollCallback(self.handle, if (callback != null) setScrollCallbackWrapper else null);

    // The only error this could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};
}

fn setDropCallbackWrapper(handle: ?*c.GLFWwindow, path_count: c_int, paths: [*c][*c]const u8) callconv(.C) void {
    const window = from(handle.?) catch unreachable;
    const internal = window.getInternal();
    internal.setDropCallback.?(window, paths[0..@intCast(usize, path_count)]);
}

/// Sets the path drop callback.
///
/// This function sets the path drop callback of the specified window, which is called when one or
/// more dragged paths are dropped on the window.
///
/// Because the path array and its strings may have been generated specifically for that event, they
/// are not guaranteed to be valid after the callback has returned. If you wish to use them after
/// the callback returns, you need to make a deep copy.
///
/// @param[in] callback The new file drop callback, or null to remove the currently set callback.
///
/// @callback_param[in] window The window that received the event.
/// @callback_param[in] path_count The number of dropped paths.
/// @callback_param[in] paths The UTF-8 encoded file and/or directory path names.
///
/// @callback_pointer_lifetime The path array and its strings are valid until the callback function
/// returns.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// wayland: File drop is currently unimplemented.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: path_drop
pub inline fn setDropCallback(self: Window, callback: ?fn (window: Window, paths: [][*c]const u8) void) Error!void {
    var internal = self.getInternal();
    internal.setDropCallback = callback;
    _ = c.glfwSetDropCallback(self.handle, if (callback != null) setDropCallbackWrapper else null);
    try getError();
}

test "defaultHints" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    try defaultHints();
}

test "hint comptime int" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    try hint(glfw.focused, 1);
    try defaultHints();
}

test "hint int" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    var focused: i32 = 1;

    try hint(glfw.focused, focused);
    try defaultHints();
}

test "hint bool" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    try hint(glfw.focused, true);
    try defaultHints();
}

test "hint enum(u1)" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const MyEnum = enum(u1) {
        @"true" = 1,
        @"false" = 0,
    };

    try hint(glfw.focused, MyEnum.@"true");
    try defaultHints();
}

test "hint enum(i32)" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const MyEnum = enum(i32) {
        @"true" = 1,
        @"false" = 0,
    };

    try hint(glfw.focused, MyEnum.@"true");
    try defaultHints();
}

test "hint array str" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const str_arr = [_]u8{ 'm', 'y', 'c', 'l', 'a', 's', 's' };

    try hint(glfw.x11_class_name, str_arr);
    try defaultHints();
}

test "hint pointer str" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    try hint(glfw.x11_class_name, "myclass");
}

test "createWindow" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();
}

test "setShouldClose" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    try window.setShouldClose(true);
    defer window.destroy();
}

test "setTitle" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    try window.setTitle("Updated title!");
}

// TODO(window): test appears to fail on at least Linux, image size is potentially wrong.
// test "setIcon" {
//     const allocator = testing.allocator;
//     const glfw = @import("main.zig");
//     try glfw.init();
//     defer glfw.terminate();

//     const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
//         // return without fail, because most of our CI environments are headless / we cannot open
//         // windows on them.
//         std.debug.print("note: failed to create window: {}\n", .{err});
//         return;
//     };
//     defer window.destroy();

//     // Create an all-red icon image.
//     var width: usize = 48;
//     var height: usize = 48;
//     const icon = try Image.init(allocator, width, height, width * height * 4);
//     var x: usize = 0;
//     var y: usize = 0;
//     while (y <= height) : (y += 1) {
//         while (x <= width) : (x += 1) {
//             icon.pixels[(x * y * 4) + 0] = 255; // red
//             icon.pixels[(x * y * 4) + 1] = 0; // green
//             icon.pixels[(x * y * 4) + 2] = 0; // blue
//             icon.pixels[(x * y * 4) + 3] = 255; // alpha
//         }
//     }
//     window.setIcon(allocator, &[_]Image{icon}) catch |err| std.debug.print("can't set window icon, wayland maybe? error={}\n", .{err});

//     icon.deinit(allocator); // glfw copies it.
// }

test "getPos" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.getPos() catch |err| std.debug.print("can't get window position, wayland maybe? error={}\n", .{err});
}

test "setPos" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.setPos(.{ .x = 0, .y = 0 }) catch |err| std.debug.print("can't set window position, wayland maybe? error={}\n", .{err});
}

test "getSize" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.getSize();
}

test "setSize" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.setSize(.{ .width = 640, .height = 480 });
}

test "setSizeLimits" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    try window.setSizeLimits(
        .{ .width = 720, .height = 480 },
        .{ .width = 1080, .height = 1920 },
    );
}

test "setAspectRatio" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    try window.setAspectRatio(4, 3);
}

test "getFramebufferSize" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.getFramebufferSize();
}

test "getFrameSize" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.getFrameSize();
}

test "getContentScale" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.getContentScale();
}

test "getOpacity" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.getOpacity();
}

test "iconify" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.iconify() catch |err| std.debug.print("can't iconify window, wayland maybe? error={}\n", .{err});
}

test "restore" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.restore() catch |err| std.debug.print("can't restore window, not supported by OS maybe? error={}\n", .{err});
}

test "maximize" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.maximize() catch |err| std.debug.print("can't maximize window, not supported by OS maybe? error={}\n", .{err});
}

test "show" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.show() catch |err| std.debug.print("can't show window, not supported by OS maybe? error={}\n", .{err});
}

test "hide" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.hide() catch |err| std.debug.print("can't hide window, not supported by OS maybe? error={}\n", .{err});
}

test "focus" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.focus() catch |err| std.debug.print("can't focus window, wayland maybe? error={}\n", .{err});
}

test "requestAttention" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.requestAttention() catch |err| std.debug.print("can't request attention for window, not supported by OS maybe? error={}\n", .{err});
}

test "swapBuffers" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.swapBuffers();
}

test "getMonitor" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.getMonitor() catch |err| std.debug.print("can't get monitor, not supported by OS maybe? error={}\n", .{err});
}

test "setMonitor" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setMonitor(null, 10, 10, 640, 480, 60) catch |err| std.debug.print("can't set monitor, not supported by OS maybe? error={}\n", .{err});
}

test "getAttrib" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.getAttrib(glfw.focused) catch |err| std.debug.print("can't check if window is focused, not supported by OS maybe? error={}\n", .{err});
}

test "setAttrib" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setAttrib(glfw.decorated, false) catch |err| std.debug.print("can't remove window decorations, not supported by OS maybe? error={}\n", .{err});
}

test "setUserPointer" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    const T = struct { name: []const u8 };
    var my_value = T{ .name = "my window!" };

    window.setUserPointer(*T, &my_value);
}

test "getUserPointer" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    const T = struct { name: []const u8 };
    var my_value = T{ .name = "my window!" };

    window.setUserPointer(*T, &my_value);
    const got = window.getUserPointer(*T);
    std.debug.assert(&my_value == got);
}

test "setPosCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setPosCallback((struct {
        fn callback(_window: Window, xpos: isize, ypos: isize) void {
            _ = _window;
            _ = xpos;
            _ = ypos;
        }
    }).callback);
}

test "setSizeCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setSizeCallback((struct {
        fn callback(_window: Window, width: isize, height: isize) void {
            _ = _window;
            _ = width;
            _ = height;
        }
    }).callback);
}

test "setCloseCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setCloseCallback((struct {
        fn callback(_window: Window) void {
            _ = _window;
        }
    }).callback);
}

test "setRefreshCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setRefreshCallback((struct {
        fn callback(_window: Window) void {
            _ = _window;
        }
    }).callback);
}

test "setFocusCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setFocusCallback((struct {
        fn callback(_window: Window, focused: bool) void {
            _ = _window;
            _ = focused;
        }
    }).callback);
}

test "setIconifyCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setIconifyCallback((struct {
        fn callback(_window: Window, iconified: bool) void {
            _ = _window;
            _ = iconified;
        }
    }).callback);
}

test "setMaximizeCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setMaximizeCallback((struct {
        fn callback(_window: Window, maximized: bool) void {
            _ = _window;
            _ = maximized;
        }
    }).callback);
}

test "setFramebufferSizeCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setFramebufferSizeCallback((struct {
        fn callback(_window: Window, width: isize, height: isize) void {
            _ = _window;
            _ = width;
            _ = height;
        }
    }).callback);
}

test "setContentScaleCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setContentScaleCallback((struct {
        fn callback(_window: Window, xscale: f32, yscale: f32) void {
            _ = _window;
            _ = xscale;
            _ = yscale;
        }
    }).callback);
}

test "setDropCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setDropCallback((struct {
        fn callback(_window: Window, paths: [][*c]const u8) void {
            _ = _window;
            _ = paths;
        }
    }).callback) catch |err| std.debug.print("can't set window drop callback, not supported by OS maybe? error={}\n", .{err});
}

test "setInputMode" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    // Boolean values.
    window.setInputMode(glfw.raw_mouse_motion, true) catch |err| std.debug.print("failed to set input mode, not supported? error={}\n", .{err});

    // Integer values.
    window.setInputMode(glfw.cursor, glfw.cursor_hidden) catch |err| std.debug.print("failed to set input mode, not supported? error={}\n", .{err});
}

test "getKey" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.getKey(glfw.key.escape);
}

test "getMouseButton" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = try window.getMouseButton(glfw.mouse_button.left);
}

test "getCursorPos" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    _ = window.getCursorPos() catch |err| std.debug.print("failed to get cursor pos, not supported? error={}\n", .{err});
}

test "setCursorPos" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setCursorPos(0, 0) catch |err| std.debug.print("failed to set cursor pos, not supported? error={}\n", .{err});
}

test "setCursor" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    const cursor = glfw.Cursor.createStandard(.ibeam) catch |err| {
        std.debug.print("failed to create cursor, custom cursors not supported? error={}\n", .{err});
        return;
    };
    defer cursor.destroy();

    window.setCursor(cursor) catch |err| std.debug.print("failed to set cursor, custom cursors not supported? error={}\n", .{err});
}

test "setKeyCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setKeyCallback((struct {
        fn callback(_window: Window, key: isize, scancode: isize, action: isize, mods: isize) void {
            _ = _window;
            _ = key;
            _ = scancode;
            _ = action;
            _ = mods;
        }
    }).callback);
}

test "setCharCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setCharCallback((struct {
        fn callback(_window: Window, codepoint: u21) void {
            _ = _window;
            _ = codepoint;
        }
    }).callback);
}

test "setMouseButtonCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setMouseButtonCallback((struct {
        fn callback(_window: Window, button: isize, action: isize, mods: isize) void {
            _ = _window;
            _ = button;
            _ = action;
            _ = mods;
        }
    }).callback);
}

test "setCursorPosCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setCursorPosCallback((struct {
        fn callback(_window: Window, xpos: f64, ypos: f64) void {
            _ = _window;
            _ = xpos;
            _ = ypos;
        }
    }).callback);
}

test "setCursorEnterCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setCursorEnterCallback((struct {
        fn callback(_window: Window, entered: bool) void {
            _ = _window;
            _ = entered;
        }
    }).callback);
}

test "setScrollCallback" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    const window = glfw.Window.create(640, 480, "Hello, Zig!", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    window.setScrollCallback((struct {
        fn callback(_window: Window, xoffset: f64, yoffset: f64) void {
            _ = _window;
            _ = xoffset;
            _ = yoffset;
        }
    }).callback);
}
