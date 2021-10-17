//! Window type and related functions

const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const c = @import("c.zig").c;

const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;
const Image = @import("Image.zig");
const Monitor = @import("Monitor.zig");

const Window = @This();

handle: *c.GLFWwindow,

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
/// Only integer value hints can be set with this function. String value hints are set with
/// glfw.Window.hintString.
///
/// This function does not check whether the specified hint values are valid. If you set hints to
/// invalid values this will instead be reported by the next call to glfw.createWindow.
///
/// Some hints are platform specific. These may be set on any platform but they will only affect
/// their specific platform. Other platforms will ignore them.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_hints, glfw.Window.hintString, glfw.Window.defaultHints
pub inline fn hint(hint_const: usize, value: isize) Error!void {
    c.glfwWindowHint(@intCast(c_int, hint_const), @intCast(c_int, value));
    try getError();
}

/// Sets the specified window hint to the desired value.
///
/// This function sets hints for the next call to glfw.Window.create. The hints, once set, retain
/// their values until changed by a call to this function or glfw.Window.defaultHints, or until the
/// library is terminated.
///
/// Only string type hints can be set with this function. Integer value hints are set with
/// glfw.Window.hint.
///
/// This function does not check whether the specified hint values are valid. If you set hints to
/// invalid values this will instead be reported by the next call to glfw.window.create.
///
/// Some hints are platform specific. These may be set on any platform but they will only affect
/// their specific platform. Other platforms will ignore them. Setting these hints requires no
/// platform specific headers or functions.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
///
/// @pointer_lifetime The specified string is copied before this function returns.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_hints, glfw.Window.hint, glfw.Window.defaultHints
pub inline fn hintString(hint_const: usize, value: [:0]const u8) Error!void {
    c.glfwWindowHintString(@intCast(c_int, hint_const), &value[0]);
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
    return Window{ .handle = handle.? };
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
    c.glfwDestroyWindow(self.handle);

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

// TODO(window):

// /// The function pointer type for window position callbacks.
// ///
// /// This is the function pointer type for window position callbacks. A window
// /// position callback function has the following signature:
// /// @code
// /// void callback_name(GLFWwindow* window, int xpos, int ypos)
// /// @endcode
// ///
// /// @param[in] window The window that was moved.
// /// @param[in] xpos The new x-coordinate, in screen coordinates, of the
// /// upper-left corner of the content area of the window.
// /// @param[in] ypos The new y-coordinate, in screen coordinates, of the
// /// upper-left corner of the content area of the window.
// ///
// /// see also: window_pos, glfwSetWindowPosCallback
// ///
// typedef void (* GLFWwindowposfun)(GLFWwindow*,int,int);

// /// The function pointer type for window size callbacks.
// ///
// /// This is the function pointer type for window size callbacks. A window size
// /// callback function has the following signature:
// /// @code
// /// void callback_name(GLFWwindow* window, int width, int height)
// /// @endcode
// ///
// /// @param[in] window The window that was resized.
// /// @param[in] width The new width, in screen coordinates, of the window.
// /// @param[in] height The new height, in screen coordinates, of the window.
// ///
// /// see also: window_size, glfw.Window.setSizeCallback
// ///
// /// @glfw3 Added window handle parameter.
// typedef void (* GLFWwindowsizefun)(GLFWwindow*,int,int);

// /// The function pointer type for window close callbacks.
// ///
// /// This is the function pointer type for window close callbacks. A window
// /// close callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window)
// /// @endcode
// ///
// /// @param[in] window The window that the user attempted to close.
// ///
// /// see also: window_close, glfw.Window.setCloseCallback
// ///
// /// @glfw3 Added window handle parameter.
// typedef void (* GLFWwindowclosefun)(GLFWwindow*);

// /// The function pointer type for window content refresh callbacks.
// ///
// /// This is the function pointer type for window content refresh callbacks.
// /// A window content refresh callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window);
// /// @endcode
// ///
// /// @param[in] window The window whose content needs to be refreshed.
// ///
// /// see also: window_refresh, glfw.Window.setRefreshCallback
// ///
// /// @glfw3 Added window handle parameter.
// typedef void (* GLFWwindowrefreshfun)(GLFWwindow*);

// /// The function pointer type for window focus callbacks.
// ///
// /// This is the function pointer type for window focus callbacks. A window
// /// focus callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, int focused)
// /// @endcode
// ///
// /// @param[in] window The window that gained or lost input focus.
// /// @param[in] focused `GLFW_TRUE` if the window was given input focus, or
// /// `GLFW_FALSE` if it lost it.
// ///
// /// see also: window_focus, glfw.Window.setFocusCallback
// ///
// typedef void (* GLFWwindowfocusfun)(GLFWwindow*,int);

// /// The function pointer type for window iconify callbacks.
// ///
// /// This is the function pointer type for window iconify callbacks. A window
// /// iconify callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, int iconified)
// /// @endcode
// ///
// /// @param[in] window The window that was iconified or restored.
// /// @param[in] iconified `GLFW_TRUE` if the window was iconified, or
// /// `GLFW_FALSE` if it was restored.
// ///
// /// see also: window_iconify, glfw.Window.setIconifyCallback
// ///
// typedef void (* GLFWwindowiconifyfun)(GLFWwindow*,int);

// /// The function pointer type for window maximize callbacks.
// ///
// /// This is the function pointer type for window maximize callbacks. A window
// /// maximize callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, int maximized)
// /// @endcode
// ///
// /// @param[in] window The window that was maximized or restored.
// /// @param[in] maximized `GLFW_TRUE` if the window was maximized, or
// /// `GLFW_FALSE` if it was restored.
// ///
// /// see also: window_maximize, /// see also: glfw.Window.setMaximizeCallback
// ///
// typedef void (* GLFWwindowmaximizefun)(GLFWwindow*,int);

// /// The function pointer type for framebuffer size callbacks.
// ///
// /// This is the function pointer type for framebuffer size callbacks.
// /// A framebuffer size callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, int width, int height)
// /// @endcode
// ///
// /// @param[in] window The window whose framebuffer was resized.
// /// @param[in] width The new width, in pixels, of the framebuffer.
// /// @param[in] height The new height, in pixels, of the framebuffer.
// ///
// /// see also: window_fbsize, glfw.Window.setFramebufferSizeCallback
// ///
// typedef void (* GLFWframebuffersizefun)(GLFWwindow*,int,int);

// /// The function pointer type for window content scale callbacks.
// ///
// /// This is the function pointer type for window content scale callbacks.
// /// A window content scale callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, float xscale, float yscale)
// /// @endcode
// ///
// /// @param[in] window The window whose content scale changed.
// /// @param[in] xscale The new x-axis content scale of the window.
// /// @param[in] yscale The new y-axis content scale of the window.
// ///
// /// see also: window_scale, glfwSetWindowContentScaleCallback
// ///
// typedef void (* GLFWwindowcontentscalefun)(GLFWwindow*,float,float);

// /// Returns the monitor that the window uses for full screen mode.
// ///
// /// This function returns the handle of the monitor that the specified window is
// /// in full screen on.
// ///
// /// @param[in] window The window to query.
// /// @return The monitor, or null if the window is in windowed mode or an
// /// error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_monitor, glfw.Window.setMonitor
// ///
// GLFWAPI GLFWmonitor* glfwGetWindowMonitor(GLFWwindow* window);

// /// Sets the mode, monitor, video mode and placement of a window.
// ///
// /// This function sets the monitor that the window uses for full screen mode or,
// /// if the monitor is null, makes it windowed mode.
// ///
// /// When setting a monitor, this function updates the width, height and refresh
// /// rate of the desired video mode and switches to the video mode closest to it.
// /// The window position is ignored when setting a monitor.
// ///
// /// When the monitor is null, the position, width and height are used to
// /// place the window content area. The refresh rate is ignored when no monitor
// /// is specified.
// ///
// /// If you only wish to update the resolution of a full screen window or the
// /// size of a windowed mode window, see @ref glfwSetWindowSize.
// ///
// /// When a window transitions from full screen to windowed mode, this function
// /// restores any previous window settings such as whether it is decorated,
// /// floating, resizable, has size or aspect ratio limits, etc.
// ///
// /// @param[in] window The window whose monitor, size or video mode to set.
// /// @param[in] monitor The desired monitor, or null to set windowed mode.
// /// @param[in] xpos The desired x-coordinate of the upper-left corner of the
// /// content area.
// /// @param[in] ypos The desired y-coordinate of the upper-left corner of the
// /// content area.
// /// @param[in] width The desired with, in screen coordinates, of the content
// /// area or video mode.
// /// @param[in] height The desired height, in screen coordinates, of the content
// /// area or video mode.
// /// @param[in] refreshRate The desired refresh rate, in Hz, of the video mode,
// /// or `GLFW_DONT_CARE`.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// The OpenGL or OpenGL ES context will not be destroyed or otherwise
// /// affected by any resizing or mode switching, although you may need to update
// /// your viewport if the framebuffer size has changed.
// ///
// /// wayland: The desired window position is ignored, as there is no way
// /// for an application to set this property.
// ///
// /// wayland: Setting the window to full screen will not attempt to
// /// change the mode, no matter what the requested size or refresh rate.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_monitor, window_full_screen, glfw.Window.getMonitor, glfw.Window.setSize
// ///
// GLFWAPI void glfwSetWindowMonitor(GLFWwindow* window, GLFWmonitor* monitor, int xpos, int ypos, int width, int height, int refreshRate);

// /// Returns an attribute of the specified window.
// ///
// /// This function returns the value of an attribute of the specified window or
// /// its OpenGL or OpenGL ES context.
// ///
// /// @param[in] window The window to query.
// /// @param[in] attrib The [window attribute](@ref window_attribs) whose value to
// /// return.
// /// @return The value of the attribute, or zero if an
// /// error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// Framebuffer related hints are not window attributes. See @ref
// /// window_attribs_fb for more information.
// ///
// /// Zero is a valid value for many window and context related
// /// attributes so you cannot use a return value of zero as an indication of
// /// errors. However, this function should not fail as long as it is passed
// /// valid arguments and the library has been [initialized](@ref intro_init).
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_attribs, glfw.Window.setAttrib
// GLFWAPI int glfwGetWindowAttrib(GLFWwindow* window, int attrib);

// /// Sets an attribute of the specified window.
// ///
// /// This function sets the value of an attribute of the specified window.
// ///
// /// The supported attributes are [GLFW_DECORATED](@ref GLFW_DECORATED_attrib),
// /// [GLFW_RESIZABLE](@ref GLFW_RESIZABLE_attrib),
// /// [GLFW_FLOATING](@ref GLFW_FLOATING_attrib),
// /// [GLFW_AUTO_ICONIFY](@ref GLFW_AUTO_ICONIFY_attrib) and
// /// [GLFW_FOCUS_ON_SHOW](@ref GLFW_FOCUS_ON_SHOW_attrib).
// ///
// /// Some of these attributes are ignored for full screen windows. The new
// /// value will take effect if the window is later made windowed.
// ///
// /// Some of these attributes are ignored for windowed mode windows. The new
// /// value will take effect if the window is later made full screen.
// ///
// /// @param[in] window The window to set the attribute for.
// /// @param[in] attrib A supported window attribute.
// /// @param[in] value `GLFW_TRUE` or `GLFW_FALSE`.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum, glfw.Error.InvalidValue and glfw.Error.PlatformError.
// ///
// /// Calling glfw.Window.getAttrib will always return the latest
// /// value, even if that value is ignored by the current mode of the window.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_attribs, glfw.Window.getAttrib
// ///
// GLFWAPI void glfwSetWindowAttrib(GLFWwindow* window, int attrib, int value);

// /// Sets the user pointer of the specified window.
// ///
// /// This function sets the user-defined pointer of the specified window. The
// /// current value is retained until the window is destroyed. The initial value
// /// is null.
// ///
// /// @param[in] window The window whose pointer to set.
// /// @param[in] pointer The new value.
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function may be called from any thread. Access is not
// /// synchronized.
// ///
// /// see also: window_userptr, glfwGetWindowUserPointer
// ///
// GLFWAPI void glfwSetWindowUserPointer(GLFWwindow* window, void* pointer);

// /// Returns the user pointer of the specified window.
// ///
// /// This function returns the current value of the user-defined pointer of the
// /// specified window. The initial value is null.
// ///
// /// @param[in] window The window whose pointer to return.
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function may be called from any thread. Access is not
// /// synchronized.
// ///
// /// see also: window_userptr, glfwSetWindowUserPointer
// ///
// GLFWAPI void* glfwGetWindowUserPointer(GLFWwindow* window);

// /// Sets the position callback for the specified window.
// ///
// /// This function sets the position callback of the specified window, which is
// /// called when the window is moved. The callback is provided with the
// /// position, in screen coordinates, of the upper-left corner of the content
// /// area of the window.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int xpos, int ypos)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWwindowposfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// wayland: This callback will never be called, as there is no way for
// /// an application to know its global position.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_pos
// ///
// GLFWAPI GLFWwindowposfun glfwSetWindowPosCallback(GLFWwindow* window, GLFWwindowposfun callback);

// /// Sets the size callback for the specified window.
// ///
// /// This function sets the size callback of the specified window, which is
// /// called when the window is resized. The callback is provided with the size,
// /// in screen coordinates, of the content area of the window.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int width, int height)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWwindowsizefun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_size
// ///
// /// @glfw3 Added window handle parameter and return value.
// GLFWAPI GLFWwindowsizefun glfwSetWindowSizeCallback(GLFWwindow* window, GLFWwindowsizefun callback);

// /// Sets the close callback for the specified window.
// ///
// /// This function sets the close callback of the specified window, which is
// /// called when the user attempts to close the window, for example by clicking
// /// the close widget in the title bar.
// ///
// /// The close flag is set before this callback is called, but you can modify it
// /// at any time with @ref glfwSetWindowShouldClose.
// ///
// /// The close callback is not triggered by @ref glfwDestroyWindow.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWwindowclosefun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// macos: Selecting Quit from the application menu will trigger the
// /// close callback for all windows.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_close
// ///
// /// @glfw3 Added window handle parameter and return value.
// GLFWAPI GLFWwindowclosefun glfwSetWindowCloseCallback(GLFWwindow* window, GLFWwindowclosefun callback);

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
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window);
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWwindowrefreshfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_refresh
// ///
// /// @glfw3 Added window handle parameter and return value.
// GLFWAPI GLFWwindowrefreshfun glfwSetWindowRefreshCallback(GLFWwindow* window, GLFWwindowrefreshfun callback);

// /// Sets the focus callback for the specified window.
// ///
// /// This function sets the focus callback of the specified window, which is
// /// called when the window gains or loses input focus.
// ///
// /// After the focus callback is called for a window that lost input focus,
// /// synthetic key and mouse button release events will be generated for all such
// /// that had been pressed. For more information, see @ref glfwSetKeyCallback
// /// and @ref glfwSetMouseButtonCallback.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int focused)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWwindowfocusfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_focus
// ///
// GLFWAPI GLFWwindowfocusfun glfwSetWindowFocusCallback(GLFWwindow* window, GLFWwindowfocusfun callback);

// /// Sets the iconify callback for the specified window.
// ///
// /// This function sets the iconification callback of the specified window, which
// /// is called when the window is iconified or restored.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int iconified)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWwindowiconifyfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// wayland: The wl_shell protocol has no concept of iconification,
// /// this callback will never be called when using this deprecated protocol.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_iconify
// ///
// GLFWAPI GLFWwindowiconifyfun glfwSetWindowIconifyCallback(GLFWwindow* window, GLFWwindowiconifyfun callback);

// /// Sets the maximize callback for the specified window.
// ///
// /// This function sets the maximization callback of the specified window, which
// /// is called when the window is maximized or restored.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int maximized)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWwindowmaximizefun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_maximize
// ///
// GLFWAPI GLFWwindowmaximizefun glfwSetWindowMaximizeCallback(GLFWwindow* window, GLFWwindowmaximizefun callback);

// /// Sets the framebuffer resize callback for the specified window.
// ///
// /// This function sets the framebuffer resize callback of the specified window,
// /// which is called when the framebuffer of the specified window is resized.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int width, int height)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWframebuffersizefun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_fbsize
// ///
// GLFWAPI GLFWframebuffersizefun glfwSetFramebufferSizeCallback(GLFWwindow* window, GLFWframebuffersizefun callback);

// /// Sets the window content scale callback for the specified window.
// ///
// /// This function sets the window content scale callback of the specified window,
// /// which is called when the content scale of the specified window changes.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, float xscale, float yscale)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWwindowcontentscalefun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: window_scale, glfw.Window.getContentScale
// ///
// GLFWAPI GLFWwindowcontentscalefun glfwSetWindowContentScaleCallback(GLFWwindow* window, GLFWwindowcontentscalefun callback);

test "defaultHints" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    try defaultHints();
}

test "hint" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    try hint(glfw.focused, 1);
    try defaultHints();
}

test "hintString" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    try hintString(glfw.x11_class_name, "myclass");
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

// TODO(slimsag): test appears to fail on at least Linux, image size is potentially wrong.
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
