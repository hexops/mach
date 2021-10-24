//! Keyboard key IDs.
//!
//! See glfw.setKeyCallback for how these are used.
//!
//! These key codes are inspired by the _USB HID Usage Tables v1.12_ (p. 53-60), but re-arranged to
//! map to 7-bit ASCII for printable keys (function keys are put in the 256+ range).
//!
//! The naming of the key codes follow these rules:
//!
//! - The US keyboard layout is used
//! - Names of printable alpha-numeric characters are used (e.g. "a", "r", "three", etc.)
//! - For non-alphanumeric characters, Unicode:ish names are used (e.g. "comma", "left_bracket",
//!   etc.). Note that some names do not correspond to the Unicode standard (usually for brevity)
//! - Keys that lack a clear US mapping are named "world_x"
//! - For non-printable keys, custom names are used (e.g. "F4", "backspace", etc.)

const std = @import("std");

const cc = @import("c.zig").c;
const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

/// The unknown key
pub const unknown = cc.GLFW_KEY_UNKNOWN;

/// Printable keys
pub const space = cc.GLFW_KEY_SPACE;
pub const apostrophe = cc.GLFW_KEY_APOSTROPHE;
pub const comma = cc.GLFW_KEY_COMMA;
pub const minus = cc.GLFW_KEY_MINUS;
pub const period = cc.GLFW_KEY_PERIOD;
pub const slash = cc.GLFW_KEY_SLASH;
pub const zero = cc.GLFW_KEY_0;
pub const one = cc.GLFW_KEY_1;
pub const two = cc.GLFW_KEY_2;
pub const three = cc.GLFW_KEY_3;
pub const four = cc.GLFW_KEY_4;
pub const five = cc.GLFW_KEY_5;
pub const six = cc.GLFW_KEY_6;
pub const seven = cc.GLFW_KEY_7;
pub const eight = cc.GLFW_KEY_8;
pub const nine = cc.GLFW_KEY_9;
pub const semicolon = cc.GLFW_KEY_SEMICOLON;
pub const equal = cc.GLFW_KEY_EQUAL;
pub const a = cc.GLFW_KEY_A;
pub const b = cc.GLFW_KEY_B;
pub const c = cc.GLFW_KEY_C;
pub const d = cc.GLFW_KEY_D;
pub const e = cc.GLFW_KEY_E;
pub const f = cc.GLFW_KEY_F;
pub const g = cc.GLFW_KEY_G;
pub const h = cc.GLFW_KEY_H;
pub const i = cc.GLFW_KEY_I;
pub const j = cc.GLFW_KEY_J;
pub const k = cc.GLFW_KEY_K;
pub const l = cc.GLFW_KEY_L;
pub const m = cc.GLFW_KEY_M;
pub const n = cc.GLFW_KEY_N;
pub const o = cc.GLFW_KEY_O;
pub const p = cc.GLFW_KEY_P;
pub const q = cc.GLFW_KEY_Q;
pub const r = cc.GLFW_KEY_R;
pub const s = cc.GLFW_KEY_S;
pub const t = cc.GLFW_KEY_T;
pub const u = cc.GLFW_KEY_U;
pub const v = cc.GLFW_KEY_V;
pub const w = cc.GLFW_KEY_W;
pub const x = cc.GLFW_KEY_X;
pub const y = cc.GLFW_KEY_Y;
pub const z = cc.GLFW_KEY_Z;
pub const left_bracket = cc.GLFW_KEY_LEFT_BRACKET;
pub const backslash = cc.GLFW_KEY_BACKSLASH;
pub const right_bracket = cc.GLFW_KEY_RIGHT_BRACKET;
pub const grave_accent = cc.GLFW_KEY_GRAVE_ACCENT;
pub const world_1 = cc.GLFW_KEY_WORLD_1; // non-US #1
pub const world_2 = cc.GLFW_KEY_WORLD_2; // non-US #2

/// Function keys
pub const escape = cc.GLFW_KEY_ESCAPE;
pub const enter = cc.GLFW_KEY_ENTER;
pub const tab = cc.GLFW_KEY_TAB;
pub const backspace = cc.GLFW_KEY_BACKSPACE;
pub const insert = cc.GLFW_KEY_INSERT;
pub const delete = cc.GLFW_KEY_DELETE;
pub const right = cc.GLFW_KEY_RIGHT;
pub const left = cc.GLFW_KEY_LEFT;
pub const down = cc.GLFW_KEY_DOWN;
pub const up = cc.GLFW_KEY_UP;
pub const page_up = cc.GLFW_KEY_PAGE_UP;
pub const page_down = cc.GLFW_KEY_PAGE_DOWN;
pub const home = cc.GLFW_KEY_HOME;
pub const end = cc.GLFW_KEY_END;
pub const caps_lock = cc.GLFW_KEY_CAPS_LOCK;
pub const scroll_lock = cc.GLFW_KEY_SCROLL_LOCK;
pub const num_lock = cc.GLFW_KEY_NUM_LOCK;
pub const print_screen = cc.GLFW_KEY_PRINT_SCREEN;
pub const pause = cc.GLFW_KEY_PAUSE;
pub const F1 = cc.GLFW_KEY_F1;
pub const F2 = cc.GLFW_KEY_F2;
pub const F3 = cc.GLFW_KEY_F3;
pub const F4 = cc.GLFW_KEY_F4;
pub const F5 = cc.GLFW_KEY_F5;
pub const F6 = cc.GLFW_KEY_F6;
pub const F7 = cc.GLFW_KEY_F7;
pub const F8 = cc.GLFW_KEY_F8;
pub const F9 = cc.GLFW_KEY_F9;
pub const F10 = cc.GLFW_KEY_F10;
pub const F11 = cc.GLFW_KEY_F11;
pub const F12 = cc.GLFW_KEY_F12;
pub const F13 = cc.GLFW_KEY_F13;
pub const F14 = cc.GLFW_KEY_F14;
pub const F15 = cc.GLFW_KEY_F15;
pub const F16 = cc.GLFW_KEY_F16;
pub const F17 = cc.GLFW_KEY_F17;
pub const F18 = cc.GLFW_KEY_F18;
pub const F19 = cc.GLFW_KEY_F19;
pub const F20 = cc.GLFW_KEY_F20;
pub const F21 = cc.GLFW_KEY_F21;
pub const F22 = cc.GLFW_KEY_F22;
pub const F23 = cc.GLFW_KEY_F23;
pub const F24 = cc.GLFW_KEY_F24;
pub const F25 = cc.GLFW_KEY_F25;
pub const kp_0 = cc.GLFW_KEY_KP_0;
pub const kp_1 = cc.GLFW_KEY_KP_1;
pub const kp_2 = cc.GLFW_KEY_KP_2;
pub const kp_3 = cc.GLFW_KEY_KP_3;
pub const kp_4 = cc.GLFW_KEY_KP_4;
pub const kp_5 = cc.GLFW_KEY_KP_5;
pub const kp_6 = cc.GLFW_KEY_KP_6;
pub const kp_7 = cc.GLFW_KEY_KP_7;
pub const kp_8 = cc.GLFW_KEY_KP_8;
pub const kp_9 = cc.GLFW_KEY_KP_9;
pub const kp_decimal = cc.GLFW_KEY_KP_DECIMAL;
pub const kp_divide = cc.GLFW_KEY_KP_DIVIDE;
pub const kp_multiply = cc.GLFW_KEY_KP_MULTIPLY;
pub const kp_subtract = cc.GLFW_KEY_KP_SUBTRACT;
pub const kp_add = cc.GLFW_KEY_KP_ADD;
pub const kp_enter = cc.GLFW_KEY_KP_ENTER;
pub const kp_equal = cc.GLFW_KEY_KP_EQUAL;
pub const left_shift = cc.GLFW_KEY_LEFT_SHIFT;
pub const left_control = cc.GLFW_KEY_LEFT_CONTROL;
pub const left_alt = cc.GLFW_KEY_LEFT_ALT;
pub const left_super = cc.GLFW_KEY_LEFT_SUPER;
pub const right_shift = cc.GLFW_KEY_RIGHT_SHIFT;
pub const right_control = cc.GLFW_KEY_RIGHT_CONTROL;
pub const right_alt = cc.GLFW_KEY_RIGHT_ALT;
pub const right_super = cc.GLFW_KEY_RIGHT_SUPER;
pub const menu = cc.GLFW_KEY_MENU;

pub const last = cc.GLFW_KEY_LAST;

/// Returns the layout-specific name of the specified printable key.
///
/// This function returns the name of the specified printable key, encoded as UTF-8. This is
/// typically the character that key would produce without any modifier keys, intended for
/// displaying key bindings to the user. For dead keys, it is typically the diacritic it would add
/// to a character.
///
/// __Do not use this function__ for text input (see input_char). You will break text input for many
/// languages even if it happens to work for yours.
///
/// If the key is `glfw.key.unknown`, the scancode is used to identify the key, otherwise the
/// scancode is ignored. If you specify a non-printable key, or `glfw.key.unknown` and a scancode
/// that maps to a non-printable key, this function returns null but does not emit an error.
///
/// This behavior allows you to always pass in the arguments in the key callback (see input_key)
/// without modification.
///
/// The printable keys are:
///
/// - `glfw.key.apostrophe`
/// - `glfw.key.comma`
/// - `glfw.key.minus`
/// - `glfw.key.period`
/// - `glfw.key.slash`
/// - `glfw.key.semicolon`
/// - `glfw.key.equal`
/// - `glfw.key.left_bracket`
/// - `glfw.key.right_bracket`
/// - `glfw.key.backslash`
/// - `glfw.key.world_1`
/// - `glfw.key.world_2`
/// - `glfw.key.0` to `glfw.key.9`
/// - `glfw.key.a` to `glfw.key.z`
/// - `glfw.key.kp_0` to `glfw.key.kp_9`
/// - `glfw.key.kp_decimal`
/// - `glfw.key.kp_divide`
/// - `glfw.key.kp_multiply`
/// - `glfw.key.kp_subtract`
/// - `glfw.key.kp_add`
/// - `glfw.key.kp_equal`
///
/// Names for printable keys depend on keyboard layout, while names for non-printable keys are the
/// same across layouts but depend on the application language and should be localized along with
/// other user interface text.
///
/// @param[in] key The key to query, or `glfw.key.unknown`.
/// @param[in] scancode The scancode of the key to query.
/// @return The UTF-8 encoded, layout-specific name of the key, or null.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// The contents of the returned string may change when a keyboard layout change event is received.
///
/// @pointer_lifetime The returned string is allocated and freed by GLFW. You should not free it
/// yourself. It is valid until the library is terminated.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: input_key_name
pub inline fn getName(key: isize, scancode: isize) Error![*c]const u8 {
    const name = cc.glfwGetKeyName(@intCast(c_int, key), @intCast(c_int, scancode));
    try getError();
    return name;
}

/// Returns the platform-specific scancode of the specified key.
///
/// This function returns the platform-specific scancode of the specified key.
///
/// If the key is `glfw.key.UNKNOWN` or does not exist on the keyboard this method will return `-1`.
///
/// @param[in] key Any named key (see keys).
/// @return The platform-specific scancode for the key.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
///
/// @thread_safety This function may be called from any thread.
pub inline fn getScancode(key: isize) Error!isize {
    const scancode = cc.glfwGetKeyScancode(@intCast(c_int, key));
    try getError();
    return scancode;
}

test "getName" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    _ = glfw.key.getName(glfw.key.a, 0) catch |err| std.debug.print("failed to get key name, not supported? error={}\n", .{err});
}

test "getScancode" {
    const glfw = @import("main.zig");
    try glfw.init();
    defer glfw.terminate();

    _ = glfw.key.getScancode(glfw.key.a) catch |err| std.debug.print("failed to get key scancode, not supported? error={}\n", .{err});
}
