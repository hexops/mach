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
