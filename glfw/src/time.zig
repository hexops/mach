const std = @import("std");

const c = @import("c.zig").c;
const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

/// Returns the GLFW time.
///
/// This function returns the current GLFW time, in seconds. Unless the time
/// has been set using @ref glfwSetTime it measures time elapsed since GLFW was
/// initialized.
///
/// This function and @ref glfwSetTime are helper functions on top of glfw.getTimerFrequency
/// and glfw.getTimerValue.
///
/// The resolution of the timer is system dependent, but is usually on the order
/// of a few micro- or nanoseconds. It uses the highest-resolution monotonic
/// time source on each supported platform.
///
/// @return The current time, in seconds, or zero if an
/// error occurred.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function may be called from any thread. Reading and
/// writing of the internal base time is not atomic, so it needs to be
/// externally synchronized with calls to @ref glfwSetTime.
///
/// see also: time
pub inline fn getTime() f64 {
    const time = c.glfwGetTime();

    // The only error shouldClose could return would be glfw.Error.NotInitialized, which should
    // definitely have occurred before calls to this. Returning an error here makes the API
    // awkward to use, so we discard it instead.
    getError() catch {};

    return time;
}

/// Sets the GLFW time.
///
/// This function sets the current GLFW time, in seconds. The value must be a positive finite
/// number less than or equal to 18446744073.0, which is approximately 584.5 years.
///
/// This function and @ref glfwGetTime are helper functions on top of glfw.getTimerFrequency and
/// glfw.getTimerValue.
///
/// @param[in] time The new value, in seconds.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidValue.
///
/// The upper limit of GLFW time is calculated as `floor((2^64 - 1) / 10^9)` and is due to
/// implementations storing nanoseconds in 64 bits. The limit may be increased in the future.
///
/// @thread_safety This function may be called from any thread. Reading and writing of the internal
/// base time is not atomic, so it needs to be externally synchronized with calls to glfw.getTime.
///
/// see also: time
pub inline fn setTime(time: f64) Error!void {
    c.glfwSetTime(time);
    try getError();
}

// TODO(time):
// /// Returns the current value of the raw timer.
// ///
// /// This function returns the current value of the raw timer, measured in
// /// 1&nbsp;/&nbsp;frequency seconds. To get the frequency, call @ref
// /// glfwGetTimerFrequency.
// ///
// /// @return The value of the timer, or zero if an
// /// error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function may be called from any thread.
// ///
// /// see also: time, glfwGetTimerFrequency
// ///
// ///
// /// @ingroup input
// GLFWAPI uint64_t glfwGetTimerValue(void);

// /// Returns the frequency, in Hz, of the raw timer.
// ///
// /// This function returns the frequency, in Hz, of the raw timer.
// ///
// /// @return The frequency of the timer, in Hz, or zero if an
// /// error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function may be called from any thread.
// ///
// /// see also: time, glfwGetTimerValue
// ///
// ///
// /// @ingroup input
// GLFWAPI uint64_t glfwGetTimerFrequency(void);

test "getTime" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    _ = getTime();
}

test "getTime" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    _ = getTime();
}
