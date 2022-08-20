//! Native access functions
const std = @import("std");

const Window = @import("Window.zig");
const Monitor = @import("Monitor.zig");
const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

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
    const native = if (@import("builtin").zig_backend == .stage1)
        @cImport({
            @cDefine("GLFW_INCLUDE_VULKAN", "1");
            @cInclude("GLFW/glfw3.h");

            if (options.win32) @cDefine("GLFW_EXPOSE_NATIVE_WIN32", "1");
            if (options.wgl) @cDefine("GLFW_EXPOSE_NATIVE_WGL", "1");
            if (options.cocoa) @cDefine("GLFW_EXPOSE_NATIVE_COCOA", "1");
            if (options.nsgl) @cDefine("GLFW_EXPOSE_NATIVE_NGSL", "1");
            if (options.x11) @cDefine("GLFW_EXPOSE_NATIVE_X11", "1");
            if (options.glx) @cDefine("GLFW_EXPOSE_NATIVE_GLX", "1");
            if (options.wayland) @cDefine("GLFW_EXPOSE_NATIVE_WAYLAND", "1");
            if (options.egl) @cDefine("GLFW_EXPOSE_NATIVE_EGL", "1");
            if (options.osmesa) @cDefine("GLFW_EXPOSE_NATIVE_OSMESA", "1");
            @cInclude("GLFW/glfw3native.h");
        })
    else
        // HACK: workaround https://github.com/ziglang/zig/issues/12483
        //
        // Extracted from a build using stage1 from zig-cache/ (`cimport.zig`)
        // Then find+replace `= ?fn` -> `= ?*const fn`
        @import("cimport1.zig");

    return struct {
        /// Returns the adapter device name of the specified monitor.
        ///
        /// return: The UTF-8 encoded adapter device name (for example `\\.\DISPLAY1`) of the
        /// specified monitor.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWin32Adapter(monitor: Monitor) [*:0]const u8 {
            internal_debug.assertInitialized();
            if (native.glfwGetWin32Adapter(@ptrCast(*native.GLFWmonitor, monitor.handle))) |adapter| return adapter;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetWin32Adapter` returns `null` only for errors
            unreachable;
        }

        /// Returns the display device name of the specified monitor.
        ///
        /// return: The UTF-8 encoded display device name (for example `\\.\DISPLAY1\Monitor0`)
        /// of the specified monitor.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWin32Monitor(monitor: Monitor) [*:0]const u8 {
            internal_debug.assertInitialized();
            if (native.glfwGetWin32Monitor(@ptrCast(*native.GLFWmonitor, monitor.handle))) |mon| return mon;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetWin32Monitor` returns `null` only for errors
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
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWin32Window(window: Window) std.os.windows.HWND {
            internal_debug.assertInitialized();
            if (native.glfwGetWin32Window(@ptrCast(*native.GLFWwindow, window.handle))) |win|
                return @ptrCast(std.os.windows.HWND, win);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetWin32Window` returns `null` only for errors
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
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWGLContext(window: Window) error{NoWindowContext}!std.os.windows.HGLRC {
            internal_debug.assertInitialized();
            if (native.glfwGetWGLContext(@ptrCast(*native.GLFWwindow, window.handle))) |context| return context;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            // `glfwGetWGLContext` returns `null` only for errors
            unreachable;
        }

        /// Returns the `CGDirectDisplayID` of the specified monitor.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getCocoaMonitor(monitor: Monitor) u32 {
            internal_debug.assertInitialized();
            const mon = native.glfwGetCocoaMonitor(@ptrCast(*native.GLFWmonitor, monitor.handle));
            if (mon != native.kCGNullDirectDisplay) return mon;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetCocoaMonitor` returns `kCGNullDirectDisplay` only for errors
            unreachable;
        }

        /// Returns the `NSWindow` of the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getCocoaWindow(window: Window) ?*anyopaque {
            internal_debug.assertInitialized();
            const win = native.glfwGetCocoaWindow(@ptrCast(*native.GLFWwindow, window.handle));
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            return win;
        }

        /// Returns the `NSWindow` of the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitialized, glfw.Error.NoWindowContext.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getNSGLContext(window: Window) error{NoWindowContext}!u32 {
            internal_debug.assertInitialized();
            const context = native.glfwGetNSGLContext(@ptrCast(*native.GLFWwindow, window.handle));
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            return context;
        }

        /// Returns the `Display` used by GLFW.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getX11Display() *anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetX11Display()) |display| return @ptrCast(*anyopaque, display);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetX11Display` returns `null` only for errors
            unreachable;
        }

        /// Returns the `RRCrtc` of the specified monitor.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getX11Adapter(monitor: Monitor) u32 {
            internal_debug.assertInitialized();
            const adapter = native.glfwGetX11Adapter(@ptrCast(*native.GLFWMonitor, monitor.handle));
            if (adapter != 0) return adapter;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetX11Adapter` returns `0` only for errors
            unreachable;
        }

        /// Returns the `RROutput` of the specified monitor.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getX11Monitor(monitor: Monitor) u32 {
            internal_debug.assertInitialized();
            const mon = native.glfwGetX11Monitor(@ptrCast(*native.GLFWmonitor, monitor.handle));
            if (mon != 0) return mon;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetX11Monitor` returns `0` only for errors
            unreachable;
        }

        /// Returns the `Window` of the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getX11Window(window: Window) u32 {
            internal_debug.assertInitialized();
            const win = native.glfwGetX11Window(@ptrCast(*native.GLFWwindow, window.handle));
            if (win != 0) return @intCast(u32, win);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetX11Window` returns `0` only for errors
            unreachable;
        }

        /// Sets the current primary selection to the specified string.
        ///
        /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
        ///
        /// The specified string is copied before this function returns.
        ///
        /// thread_safety: This function must only be called from the main thread.
        pub fn setX11SelectionString(string: [*:0]const u8) error{PlatformError}!void {
            internal_debug.assertInitialized();
            native.glfwSetX11SelectionString(string);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.PlatformError => |e| e,
                else => unreachable,
            };
        }

        /// Returns the contents of the current primary selection as a string.
        ///
        /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
        ///
        /// The returned string is allocated and freed by GLFW. You should not free it
        /// yourself. It is valid until the next call to getX11SelectionString or
        /// setX11SelectionString, or until the library is terminated.
        ///
        /// thread_safety: This function must only be called from the main thread.
        pub fn getX11SelectionString() error{FormatUnavailable}![*:0]const u8 {
            internal_debug.assertInitialized();
            if (native.glfwGetX11SelectionString()) |str| return str;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.FormatUnavailable => |e| e,
                else => unreachable,
            };
            // `glfwGetX11SelectionString` returns `null` only for errors
            unreachable;
        }

        /// Returns the `GLXContext` of the specified window.
        ///
        /// Possible errors include glfw.Error.NoWindowContext and glfw.Error.NotInitialized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getGLXContext(window: Window) error{NoWindowContext}!*anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetGLXContext(@ptrCast(*native.GLFWwindow, window.handle))) |context| return @ptrCast(*anyopaque, context);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            // `glfwGetGLXContext` returns `null` only for errors
            unreachable;
        }

        /// Returns the `GLXWindow` of the specified window.
        ///
        /// Possible errors include glfw.Error.NoWindowContext and glfw.Error.NotInitialized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getGLXWindow(window: Window) error{NoWindowContext}!*anyopaque {
            internal_debug.assertInitialized();
            const win = native.glfwGetGLXWindow(@ptrCast(*native.GLFWwindow, window.handle));
            if (win != 0) return @ptrCast(*anyopaque, win);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            // `glfwGetGLXWindow` returns `0` only for errors
            unreachable;
        }

        /// Returns the `*wl_display` used by GLFW.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWaylandDisplay() *anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetWaylandDisplay()) |display| return @ptrCast(*anyopaque, display);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetWaylandDisplay` returns `null` only for errors
            unreachable;
        }

        /// Returns the `*wl_output` of the specified monitor.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWaylandMonitor(monitor: Monitor) *anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetWaylandMonitor(@ptrCast(*native.GLFWmonitor, monitor.handle))) |mon| return @ptrCast(*anyopaque, mon);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetWaylandMonitor` returns `null` only for errors
            unreachable;
        }

        /// Returns the `*wl_surface` of the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getWaylandWindow(window: Window) *anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetWaylandWindow(@ptrCast(*native.GLFWwindow, window.handle))) |win| return @ptrCast(*anyopaque, win);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetWaylandWindow` returns `null` only for errors
            unreachable;
        }

        /// Returns the `EGLDisplay` used by GLFW.
        ///
        /// Possible errors include glfw.Error.NotInitalized.
        ///
        /// remark: Because EGL is initialized on demand, this function will return `EGL_NO_DISPLAY`
        /// until the first context has been created via EGL.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getEGLDisplay() *anyopaque {
            internal_debug.assertInitialized();
            const display = native.glfwGetEGLDisplay();
            if (display != native.EGL_NO_DISPLAY) return @ptrCast(*anyopaque, display);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                else => unreachable,
            };
            // `glfwGetEGLDisplay` returns `EGL_NO_DISPLAY` only for errors
            unreachable;
        }

        /// Returns the `EGLContext` of the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitalized and glfw.Error.NoWindowContext.
        ///
        /// thread_safety This function may be called from any thread. Access is not synchronized.
        pub fn getEGLContext(window: Window) error{NoWindowContext}!*anyopaque {
            internal_debug.assertInitialized();
            const context = native.glfwGetEGLContext(@ptrCast(*native.GLFWwindow, window.handle));
            if (context != native.EGL_NO_CONTEXT) return @ptrCast(*anyopaque, context);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            // `glfwGetEGLContext` returns `EGL_NO_CONTEXT` only for errors
            unreachable;
        }

        /// Returns the `EGLSurface` of the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitalized and glfw.Error.NoWindowContext.
        ///
        /// thread_safety This function may be called from any thread. Access is not synchronized.
        pub fn getEGLSurface(window: Window) error{NoWindowContext}!*anyopaque {
            internal_debug.assertInitialized();
            const surface = native.glfwGetEGLSurface(@ptrCast(*native.GLFWwindow, window.handle));
            if (surface != native.EGL_NO_SURFACE) return @ptrCast(*anyopaque, surface);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            // `glfwGetEGLSurface` returns `EGL_NO_SURFACE` only for errors
            unreachable;
        }

        pub const OSMesaColorBuffer = struct {
            width: c_int,
            height: c_int,
            format: c_int,
            buffer: *anyopaque,
        };

        /// Retrieves the color buffer associated with the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitalized, glfw.Error.NoWindowContext
        /// and glfw.Error.PlatformError.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getOSMesaColorBuffer(window: Window) error{ PlatformError, NoWindowContext }!OSMesaColorBuffer {
            internal_debug.assertInitialized();
            var buf: OSMesaColorBuffer = undefined;
            if (native.glfwGetOSMesaColorBuffer(
                @ptrCast(*native.GLFWwindow, window.handle),
                &buf.width,
                &buf.height,
                &buf.format,
                &buf.buffer,
            ) == native.GLFW_TRUE) return buf;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.PlatformError, Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            // `glfwGetOSMesaColorBuffer` returns `GLFW_FALSE` only for errors
            unreachable;
        }

        pub const OSMesaDepthBuffer = struct {
            width: c_int,
            height: c_int,
            bytes_per_value: c_int,
            buffer: *anyopaque,
        };

        /// Retrieves the depth buffer associated with the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitalized, glfw.Error.NoWindowContext
        /// and glfw.Error.PlatformError.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getOSMesaDepthBuffer(window: Window) error{ PlatformError, NoWindowContext }!OSMesaDepthBuffer {
            internal_debug.assertInitialized();
            var buf: OSMesaDepthBuffer = undefined;
            if (native.glfwGetOSMesaDepthBuffer(
                @ptrCast(*native.GLFWwindow, window.handle),
                &buf.width,
                &buf.height,
                &buf.bytes_per_value,
                &buf.buffer,
            ) == native.GLFW_TRUE) return buf;
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.PlatformError, Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            // `glfwGetOSMesaDepthBuffer` returns `GLFW_FALSE` only for errors
            unreachable;
        }

        /// Returns the 'OSMesaContext' of the specified window.
        ///
        /// Possible errors include glfw.Error.NotInitalized and glfw.Error.NoWindowContext.
        ///
        /// thread_safety: This function may be called from any thread. Access is not synchronized.
        pub fn getOSMesaContext(window: Window) error{NoWindowContext}!*anyopaque {
            internal_debug.assertInitialized();
            if (native.glfwGetOSMesaContext(@ptrCast(*native.GLFWwindow, window.handle))) |context| return @ptrCast(*anyopaque, context);
            getError() catch |err| return switch (err) {
                Error.NotInitialized => unreachable,
                Error.NoWindowContext => |e| e,
                else => unreachable,
            };
            // `glfwGetOSMesaContext` returns `null` only for errors
            unreachable;
        }
    };
}
