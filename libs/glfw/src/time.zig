const std = @import("std");

const c = @import("c.zig").c;

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
/// time source on each supported operating system.
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
    if (time != 0) return time;
    // `glfwGetTime` returns `0` only for errors
    // but the only potential error is unreachable (NotInitialized)
    unreachable;
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
/// Possible errors include glfw.ErrorCode.InvalidValue.
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
    // assert time is lteq to largest number of seconds representable by u64 with nanosecond precision
    std.debug.assert(time <= max_time: {
        const @"2^64" = std.math.maxInt(u64);
        break :max_time @divTrunc(@"2^64", std.time.ns_per_s);
    });

    c.glfwSetTime(time);
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
    if (value != 0) return value;
    // `glfwGetTimerValue` returns `0` only for errors
    // but the only potential error is unreachable (NotInitialized)
    unreachable;
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
    if (frequency != 0) return frequency;
    // `glfwGetTimerFrequency` returns `0` only for errors
    // but the only potential error is unreachable (NotInitialized)
    unreachable;
}

test "getTime" {
    const glfw = @import("main.zig");
    defer glfw.clearError(); // clear any error we generate
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    _ = getTime();
}

test "setTime" {
    const glfw = @import("main.zig");
    defer glfw.clearError(); // clear any error we generate
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    _ = glfw.setTime(1234);
}

test "getTimerValue" {
    const glfw = @import("main.zig");
    defer glfw.clearError(); // clear any error we generate
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    _ = glfw.getTimerValue();
}

test "getTimerFrequency" {
    const glfw = @import("main.zig");
    defer glfw.clearError(); // clear any error we generate
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    _ = glfw.getTimerFrequency();
}
