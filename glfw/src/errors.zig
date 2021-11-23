//! Errors

const c = @import("c.zig").c;

/// Errors that GLFW can produce.
pub const Error = error{
    /// No context is current for this thread.
    ///
    /// This occurs if a GLFW function was called that needs and operates on the current OpenGL or
    /// OpenGL ES context but no context is current on the calling thread. One such function is
    /// glfw.SwapInterval.
    NoCurrentContext,

    /// One of the arguments to the function was an invalid enum value.
    ///
    /// One of the arguments to the function was an invalid enum value, for example requesting
    /// glfw.red_bits with glfw.getWindowAttrib.
    InvalidEnum,

    /// One of the arguments to the function was an invalid value.
    ///
    /// One of the arguments to the function was an invalid value, for example requesting a
    /// non-existent OpenGL or OpenGL ES version like 2.7.
    ///
    /// Requesting a valid but unavailable OpenGL or OpenGL ES version will instead result in a
    /// glfw.Error.VersionUnavailable error.
    InvalidValue,

    /// A memory allocation failed.
    OutOfMemory,

    /// GLFW could not find support for the requested API on the system.
    ///
    /// The installed graphics driver does not support the requested API, or does not support it
    /// via the chosen context creation backend. Below are a few examples.
    ///
    /// Some pre-installed Windows graphics drivers do not support OpenGL. AMD only supports
    /// OpenGL ES via EGL, while Nvidia and Intel only support it via a WGL or GLX extension. macOS
    /// does not provide OpenGL ES at all. The Mesa EGL, OpenGL and OpenGL ES libraries do not
    /// interface with the Nvidia binary driver. Older graphics drivers do not support Vulkan.
    APIUnavailable,

    /// The requested OpenGL or OpenGL ES version (including any requested context or framebuffer
    /// hints) is not available on this machine.
    ///
    /// The machine does not support your requirements. If your application is sufficiently
    /// flexible, downgrade your requirements and try again. Otherwise, inform the user that their
    /// machine does not match your requirements.
    ///
    /// Future invalid OpenGL and OpenGL ES versions, for example OpenGL 4.8 if 5.0 comes out
    /// before the 4.x series gets that far, also fail with this error and not glfw.Error.InvalidValue,
    /// because GLFW cannot know what future versions will exist.
    VersionUnavailable,

    /// A platform-specific error occurred that does not match any of the more specific categories.
    ///
    /// A bug or configuration error in GLFW, the underlying operating system or its drivers, or a
    /// lack of required resources. Report the issue to our [issue tracker](https://github.com/glfw/glfw/issues).
    PlatformError,

    /// The requested format is not supported or available.
    ///
    /// If emitted during window creation, the requested pixel format is not supported.
    ///
    /// If emitted when querying the clipboard, the contents of the clipboard could not be
    /// converted to the requested format.
    ///
    /// If emitted during window creation, one or more hard constraints did not match any of the
    /// available pixel formats. If your application is sufficiently flexible, downgrade your
    /// requirements and try again. Otherwise, inform the user that their machine does not match
    /// your requirements.
    ///
    /// If emitted when querying the clipboard, ignore the error or report it to the user, as
    /// appropriate.
    FormatUnavailable,

    /// The specified window does not have an OpenGL or OpenGL ES context.
    ///
    /// A window that does not have an OpenGL or OpenGL ES context was passed to a function that
    /// requires it to have one.
    NoWindowContext,
};

fn convertError(e: c_int) Error!void {
    return switch (e) {
        c.GLFW_NO_ERROR => {},
        c.GLFW_NOT_INITIALIZED => unreachable,
        c.GLFW_NO_CURRENT_CONTEXT => Error.NoCurrentContext,
        c.GLFW_INVALID_ENUM => Error.InvalidEnum,
        c.GLFW_INVALID_VALUE => Error.InvalidValue,
        c.GLFW_OUT_OF_MEMORY => Error.OutOfMemory,
        c.GLFW_API_UNAVAILABLE => Error.APIUnavailable,
        c.GLFW_VERSION_UNAVAILABLE => Error.VersionUnavailable,
        c.GLFW_PLATFORM_ERROR => Error.PlatformError,
        c.GLFW_FORMAT_UNAVAILABLE => Error.FormatUnavailable,
        c.GLFW_NO_WINDOW_CONTEXT => Error.NoWindowContext,
        else => unreachable,
    };
}

/// Returns and clears the last error for the calling thread.
///
/// This function returns and clears the error code of the last error that occurred on the calling
/// thread, and optionally a UTF-8 encoded human-readable description of it. If no error has
/// occurred since the last call, it returns GLFW_NO_ERROR (zero) and the description pointer is
/// set to `NULL`.
///
/// * @param[in] description Where to store the error description pointer, or `NULL`.
/// @return The last error code for the calling thread, or @ref GLFW_NO_ERROR (zero).
///
/// @pointer_lifetime The returned string is allocated and freed by GLFW. You should not free it
/// yourself. It is guaranteed to be valid only until the next error occurs or the library is
/// terminated.
///
/// @remark This function may be called before @ref glfwInit.
///
/// @thread_safety This function may be called from any thread.
pub inline fn getError() Error!void {
    return convertError(c.glfwGetError(null));
}
