//! Native access functions
const std = @import("std");

const Window = @import("Window.zig");
const Monitor = @import("Monitor.zig");

const internal_debug = @import("internal_debug.zig");

pub const BackendOptions = struct {
    win32: bool = false,
    wgl: bool = false,
    cocoa: bool = false,
    nsgl: bool = false,
    x11: bool = false,
    glx: bool = false,
    wayland: bool = false,
    egl: bool = false,
    osmesa: bool = false,
};

/// This function returns a type which allows provides an interface to access
/// the native handles based on backends selected.
///
/// The available window API options are:
/// * win32
/// * cocoa
/// * x11
/// * wayland
///
/// The available context API options are:
///
/// * wgl
/// * nsgl
/// * glx
/// * egl
/// * osmesa
///
/// The chosen backends must match those the library was compiled for. Failure to do so
/// will cause a link-time error.
pub fn Native(comptime options: BackendOptions) type {
    const native = @cImport({
        @cDefine("GLFW_INCLUDE_VULKAN", "1");
        @cDefine("GLFW_INCLUDE_NONE", "1");
        if (options.win32) @cDefine("GLFW_EXPOSE_NATIVE_WIN32", "1");
        if (options.wgl) @cDefine("GLFW_EXPOSE_NATIVE_WGL", "1");
        if (options.cocoa) @cDefine("GLFW_EXPOSE_NATIVE_COCOA", "1");
        if (options.nsgl) @cDefine("GLFW_EXPOSE_NATIVE_NGSL", "1");
        if (options.x11) @cDefine("GLFW_EXPOSE_NATIVE_X11", "1");
        if (options.glx) @cDefine("GLFW_EXPOSE_NATIVE_GLX", "1");
        if (options.wayland) @cDefine("GLFW_EXPOSE_NATIVE_WAYLAND", "1");
        if (options.egl) @cDefine("GLFW_EXPOSE_NATIVE_EGL", "1");
        if (options.osmesa) @cDefine("GLFW_EXPOSE_NATIVE_OSMESA", "1");
        @cInclude("glfw_native.h");
    });

    return struct {
        /// Returns the adapter device name of the specified monitor.
        ///
        /// return: The UTF-8 encoded adapter device name (for example `\\.\DISPLAY1`) of the
        /// specified monitor.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWin32Adapter(monitor: Monitor) [*:0]const u8 {
            internal_debug.assertInitialized();
            if (native.glfwGetWin32Adapter(@as(*native.GLFWmonitor, @ptrCast(monitor.handle)))) |adapter| return adapter;
            // `glfwGetWin32Adapter` returns `null` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the display device name of the specified monitor.
        ///
        /// return: The UTF-8 encoded display device name (for example `\\.\DISPLAY1\Monitor0`)
        /// of the specified monitor.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWin32Monitor(monitor: Monitor) [*:0]const u8 {
            internal_debug.assertInitialized();
            if (native.glfwGetWin32Monitor(@as(*native.GLFWmonitor, @ptrCast(monitor.handle)))) |mon| return mon;
            // `glfwGetWin32Monitor` returns `null` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `HWND` of the specified window.
        ///
        /// The `HDC` associated with the window can be queried with the
        /// [GetDC](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getdc)
        /// function.
        /// ```
        /// const dc = std.os.windows.user32.GetDC(native.getWin32Window(window));
        /// ```
        /// This DC is private and does not need to be released.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWin32Window(window: Window) std.os.windows.HWND {
            internal_debug.assertInitialized();
            if (native.glfwGetWin32Window(@as(*native.GLFWwindow, @ptrCast(window.handle)))) |win|
                return @as(std.os.windows.HWND, @ptrCast(win));
            // `glfwGetWin32Window` returns `null` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `HGLRC` of the specified window.
        ///
        /// The `HDC` associated with the window can be queried with the
        /// [GetDC](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getdc)
        /// function.
        /// ```
        /// const dc = std.os.windows.user32.GetDC(native.getWin32Window(window));
        /// ```
        /// This DC is private and does not need to be released.
        ///
        /// Possible errors include glfw.ErrorCode.NoWindowContext
        /// null is returned in the event of an error.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWGLContext(window: Window) ?std.os.windows.HGLRC {
            internal_debug.assertInitialized();
            if (native.glfwGetWGLContext(@as(*native.GLFWwindow, @ptrCast(window.handle)))) |context| return context;
            return null;
        }

        /// Returns the `CGDirectDisplayID` of the specified monitor.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getCocoaMonitor(monitor: Monitor) u32 {
            internal_debug.assertInitialized();
            const mon = native.glfwGetCocoaMonitor(@as(*native.GLFWmonitor, @ptrCast(monitor.handle)));
            if (mon != native.kCGNullDirectDisplay) return mon;
            // `glfwGetCocoaMonitor` returns `kCGNullDirectDisplay` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `NSWindow` of the specified window.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getCocoaWindow(window: Window) ?*anyopaque {
            internal_debug.assertInitialized();
            return native.glfwGetCocoaWindow(@as(*native.GLFWwindow, @ptrCast(window.handle)));
        }

        /// Returns the `NSWindow` of the specified window.
        ///
        /// Possible errors include glfw.ErrorCode.NoWindowContext.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getNSGLContext(window: Window) u32 {
            internal_debug.assertInitialized();
            return native.glfwGetNSGLContext(@as(*native.GLFWwindow, @ptrCast(window.handle)));
        }

        /// Returns the `Display` used by GLFW.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getX11Display() *anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetX11Display()) |display| return @as(*anyopaque, @ptrCast(display));
            // `glfwGetX11Display` returns `null` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `RRCrtc` of the specified monitor.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getX11Adapter(monitor: Monitor) u32 {
            internal_debug.assertInitialized();
            const adapter = native.glfwGetX11Adapter(@as(*native.GLFWMonitor, @ptrCast(monitor.handle)));
            if (adapter != 0) return adapter;
            // `glfwGetX11Adapter` returns `0` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `RROutput` of the specified monitor.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getX11Monitor(monitor: Monitor) u32 {
            internal_debug.assertInitialized();
            const mon = native.glfwGetX11Monitor(@as(*native.GLFWmonitor, @ptrCast(monitor.handle)));
            if (mon != 0) return mon;
            // `glfwGetX11Monitor` returns `0` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `Window` of the specified window.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getX11Window(window: Window) u32 {
            internal_debug.assertInitialized();
            const win = native.glfwGetX11Window(@as(*native.GLFWwindow, @ptrCast(window.handle)));
            if (win != 0) return @as(u32, @intCast(win));
            // `glfwGetX11Window` returns `0` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Sets the current primary selection to the specified string.
        ///
        /// Possible errors include glfw.ErrorCode.PlatformError.
        ///
        /// The specified string is copied before this function returns.
        ///
        /// thread_safety: This function must only be called from the main thread.
        pub fn setX11SelectionString(string: [*:0]const u8) void {
            internal_debug.assertInitialized();
            native.glfwSetX11SelectionString(string);
        }

        /// Returns the contents of the current primary selection as a string.
        ///
        /// Possible errors include glfw.ErrorCode.PlatformError.
        /// Returns null in the event of an error.
        ///
        /// The returned string is allocated and freed by GLFW. You should not free it
        /// yourself. It is valid until the next call to getX11SelectionString or
        /// setX11SelectionString, or until the library is terminated.
        ///
        /// thread_safety: This function must only be called from the main thread.
        pub fn getX11SelectionString() ?[*:0]const u8 {
            internal_debug.assertInitialized();
            if (native.glfwGetX11SelectionString()) |str| return str;
            return null;
        }

        /// Returns the `GLXContext` of the specified window.
        ///
        /// Possible errors include glfw.ErrorCode.NoWindowContext.
        /// Returns null in the event of an error.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getGLXContext(window: Window) ?*anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetGLXContext(@as(*native.GLFWwindow, @ptrCast(window.handle)))) |context| return @as(*anyopaque, @ptrCast(context));
            return null;
        }

        /// Returns the `GLXWindow` of the specified window.
        ///
        /// Possible errors include glfw.ErrorCode.NoWindowContext.
        /// Returns null in the event of an error.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getGLXWindow(window: Window) ?*anyopaque {
            internal_debug.assertInitialized();
            const win = native.glfwGetGLXWindow(@as(*native.GLFWwindow, @ptrCast(window.handle)));
            if (win != 0) return @as(*anyopaque, @ptrCast(win));
            return null;
        }

        /// Returns the `*wl_display` used by GLFW.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWaylandDisplay() *anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetWaylandDisplay()) |display| return @as(*anyopaque, @ptrCast(display));
            // `glfwGetWaylandDisplay` returns `null` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `*wl_output` of the specified monitor.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWaylandMonitor(monitor: Monitor) *anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetWaylandMonitor(@as(*native.GLFWmonitor, @ptrCast(monitor.handle)))) |mon| return @as(*anyopaque, @ptrCast(mon));
            // `glfwGetWaylandMonitor` returns `null` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `*wl_surface` of the specified window.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWaylandWindow(window: Window) *anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetWaylandWindow(@as(*native.GLFWwindow, @ptrCast(window.handle)))) |win| return @as(*anyopaque, @ptrCast(win));
            // `glfwGetWaylandWindow` returns `null` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `EGLDisplay` used by GLFW.
        ///
        /// remark: Because EGL is initialized on demand, this function will return `EGL_NO_DISPLAY`
        /// until the first context has been created via EGL.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getEGLDisplay() *anyopaque {
            internal_debug.assertInitialized();
            const display = native.glfwGetEGLDisplay();
            if (display != native.EGL_NO_DISPLAY) return @as(*anyopaque, @ptrCast(display));
            // `glfwGetEGLDisplay` returns `EGL_NO_DISPLAY` only for errors
            // but the only potential error is unreachable (NotInitialized)
            unreachable;
        }

        /// Returns the `EGLContext` of the specified window.
        ///
        /// Possible errors include glfw.ErrorCode.NoWindowContext.
        /// Returns null in the event of an error.
        ///
        /// thread_safety This function may be called from any thread. Access is not synchronized.
        pub fn getEGLContext(window: Window) ?*anyopaque {
            internal_debug.assertInitialized();
            const context = native.glfwGetEGLContext(@as(*native.GLFWwindow, @ptrCast(window.handle)));
            if (context != native.EGL_NO_CONTEXT) return @as(*anyopaque, @ptrCast(context));
            return null;
        }

        /// Returns the `EGLSurface` of the specified window.
        ///
        /// Possible errors include glfw.ErrorCode.NotInitalized and glfw.ErrorCode.NoWindowContext.
        ///
        /// thread_safety This function may be called from any thread. Access is not synchronized.
        pub fn getEGLSurface(window: Window) ?*anyopaque {
            internal_debug.assertInitialized();
            const surface = native.glfwGetEGLSurface(@as(*native.GLFWwindow, @ptrCast(window.handle)));
            if (surface != native.EGL_NO_SURFACE) return @as(*anyopaque, @ptrCast(surface));
            return null;
        }

        pub const OSMesaColorBuffer = struct {
            width: c_int,
            height: c_int,
            format: c_int,
            buffer: *anyopaque,
        };

        /// Retrieves the color buffer associated with the specified window.
        ///
        /// Possible errors include glfw.ErrorCode.NoWindowContext and glfw.ErrorCode.PlatformError.
        /// Returns null in the event of an error.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getOSMesaColorBuffer(window: Window) ?OSMesaColorBuffer {
            internal_debug.assertInitialized();
            var buf: OSMesaColorBuffer = undefined;
            if (native.glfwGetOSMesaColorBuffer(
                @as(*native.GLFWwindow, @ptrCast(window.handle)),
                &buf.width,
                &buf.height,
                &buf.format,
                &buf.buffer,
            ) == native.GLFW_TRUE) return buf;
            return null;
        }

        pub const OSMesaDepthBuffer = struct {
            width: c_int,
            height: c_int,
            bytes_per_value: c_int,
            buffer: *anyopaque,
        };

        /// Retrieves the depth buffer associated with the specified window.
        ///
        /// Possible errors include glfw.ErrorCode.NoWindowContext and glfw.ErrorCode.PlatformError.
        /// Returns null in the event of an error.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getOSMesaDepthBuffer(window: Window) ?OSMesaDepthBuffer {
            internal_debug.assertInitialized();
            var buf: OSMesaDepthBuffer = undefined;
            if (native.glfwGetOSMesaDepthBuffer(
                @as(*native.GLFWwindow, @ptrCast(window.handle)),
                &buf.width,
                &buf.height,
                &buf.bytes_per_value,
                &buf.buffer,
            ) == native.GLFW_TRUE) return buf;
            return null;
        }

        /// Returns the 'OSMesaContext' of the specified window.
        ///
        /// Possible errors include glfw.ErrorCode.NoWindowContext.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getOSMesaContext(window: Window) ?*anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetOSMesaContext(@as(*native.GLFWwindow, @ptrCast(window.handle)))) |context| return @as(*anyopaque, @ptrCast(context));
            return null;
        }
    };
}
