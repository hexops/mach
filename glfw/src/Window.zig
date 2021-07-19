//! Window type and related functions

const std = @import("std");
const c = @import("c.zig").c;

const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

const Window = @This();

/// Resets all window hints to their default values.
///
/// This function resets all window hints to their default values.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: window_hints, glfw.Window.hint, glfw.Window.hintString
pub fn defaultHints() Error!void {
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
pub fn hint(hint_const: usize, value: isize) Error!void {
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
pub fn hintString(hint_const: usize, value: [:0]const u8) Error!void {
    c.glfwWindowHintString(@intCast(c_int, hint_const), &value[0]);
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
