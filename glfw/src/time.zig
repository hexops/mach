const std = @import("std");

const c = @import("c.zig").c;
const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

const internal_debug = @import("internal_debug.zig");

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
/// @thread_safety This function may be called from any thread. Reading and
/// writing of the internal base time is not atomic, so it needs to be
/// externally synchronized with calls to @ref glfwSetTime.
///
/// see also: time
pub inline fn getTime() f64 {
    internal_debug.assertInitialized();
    const time = c.glfwGetTime();
    getError() catch unreachable; // Only error 'GLFW_NOT_INITIALIZED' is impossible
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
pub inline fn setTime(time: f64) void {
    internal_debug.assertInitialized();

    std.debug.assert(!std.math.isNan(time));
    std.debug.assert(time >= 0);
    // TODO: Look into why GLFW uses this hardcoded float literal as the maximum valid value for 'time'.
    // Maybe propose upstream to name this constant. 
    std.debug.assert(time <= 18446744073.0);

    c.glfwSetTime(time);
    getError() catch |err| return switch (err) {
        Error.InvalidValue => unreachable, // we assert that 'time' is a valid value, so this should be impossible
        else => unreachable,
    };
}

/// Returns the current value of the raw timer.
///
/// This function returns the current value of the raw timer, measured in `1/frequency` seconds. To
/// get the frequency, call glfw.getTimerFrequency.
///
/// @return The value of the timer, or zero if an error occurred.
///
/// @thread_safety This function may be called from any thread.
///
/// see also: time, glfw.getTimerFrequency
pub inline fn getTimerValue() u64 {
    internal_debug.assertInitialized();
    const value = c.glfwGetTimerValue();
    getError() catch unreachable; // Only error 'GLFW_NOT_INITIALIZED' is impossible
    return value;
}

/// Returns the frequency, in Hz, of the raw timer.
///
/// This function returns the frequency, in Hz, of the raw timer.
///
/// @return The frequency of the timer, in Hz, or zero if an error occurred.
///
/// @thread_safety This function may be called from any thread.
///
/// see also: time, glfw.getTimerValue
pub inline fn getTimerFrequency() u64 {
    internal_debug.assertInitialized();
    const frequency = c.glfwGetTimerFrequency();
    getError() catch unreachable; // Only error 'GLFW_NOT_INITIALIZED' is impossible
    return frequency;
}

test "getTime" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    _ = getTime();
}

test "setTime" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    _ = glfw.setTime(1234);
}

test "getTimerValue" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    _ = glfw.getTimerValue();
}

test "getTimerFrequency" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    _ = glfw.getTimerFrequency();
}
