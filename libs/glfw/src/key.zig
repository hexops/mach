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
//! - Names of printable alphanumeric characters are used (e.g. "a", "r", "three", etc.)
//! - For non-alphanumeric characters, Unicode:ish names are used (e.g. "comma", "left_bracket",
//!   etc.). Note that some names do not correspond to the Unicode standard (usually for brevity)
//! - Keys that lack a clear US mapping are named "world_x"
//! - For non-printable keys, custom names are used (e.g. "F4", "backspace", etc.)

const std = @import("std");

const cc = @import("c.zig").c;

const internal_debug = @import("internal_debug.zig");

/// enum containing all glfw keys
pub const Key = enum(c_int) {
    /// The unknown key
    unknown = cc.GLFW_KEY_UNKNOWN,

    /// Printable keys
    space = cc.GLFW_KEY_SPACE,
    apostrophe = cc.GLFW_KEY_APOSTROPHE,
    comma = cc.GLFW_KEY_COMMA,
    minus = cc.GLFW_KEY_MINUS,
    period = cc.GLFW_KEY_PERIOD,
    slash = cc.GLFW_KEY_SLASH,
    zero = cc.GLFW_KEY_0,
    one = cc.GLFW_KEY_1,
    two = cc.GLFW_KEY_2,
    three = cc.GLFW_KEY_3,
    four = cc.GLFW_KEY_4,
    five = cc.GLFW_KEY_5,
    six = cc.GLFW_KEY_6,
    seven = cc.GLFW_KEY_7,
    eight = cc.GLFW_KEY_8,
    nine = cc.GLFW_KEY_9,
    semicolon = cc.GLFW_KEY_SEMICOLON,
    equal = cc.GLFW_KEY_EQUAL,
    a = cc.GLFW_KEY_A,
    b = cc.GLFW_KEY_B,
    c = cc.GLFW_KEY_C,
    d = cc.GLFW_KEY_D,
    e = cc.GLFW_KEY_E,
    f = cc.GLFW_KEY_F,
    g = cc.GLFW_KEY_G,
    h = cc.GLFW_KEY_H,
    i = cc.GLFW_KEY_I,
    j = cc.GLFW_KEY_J,
    k = cc.GLFW_KEY_K,
    l = cc.GLFW_KEY_L,
    m = cc.GLFW_KEY_M,
    n = cc.GLFW_KEY_N,
    o = cc.GLFW_KEY_O,
    p = cc.GLFW_KEY_P,
    q = cc.GLFW_KEY_Q,
    r = cc.GLFW_KEY_R,
    s = cc.GLFW_KEY_S,
    t = cc.GLFW_KEY_T,
    u = cc.GLFW_KEY_U,
    v = cc.GLFW_KEY_V,
    w = cc.GLFW_KEY_W,
    x = cc.GLFW_KEY_X,
    y = cc.GLFW_KEY_Y,
    z = cc.GLFW_KEY_Z,
    left_bracket = cc.GLFW_KEY_LEFT_BRACKET,
    backslash = cc.GLFW_KEY_BACKSLASH,
    right_bracket = cc.GLFW_KEY_RIGHT_BRACKET,
    grave_accent = cc.GLFW_KEY_GRAVE_ACCENT,
    world_1 = cc.GLFW_KEY_WORLD_1, // non-US #1
    world_2 = cc.GLFW_KEY_WORLD_2, // non-US #2

    // Function keys
    escape = cc.GLFW_KEY_ESCAPE,
    enter = cc.GLFW_KEY_ENTER,
    tab = cc.GLFW_KEY_TAB,
    backspace = cc.GLFW_KEY_BACKSPACE,
    insert = cc.GLFW_KEY_INSERT,
    delete = cc.GLFW_KEY_DELETE,
    right = cc.GLFW_KEY_RIGHT,
    left = cc.GLFW_KEY_LEFT,
    down = cc.GLFW_KEY_DOWN,
    up = cc.GLFW_KEY_UP,
    page_up = cc.GLFW_KEY_PAGE_UP,
    page_down = cc.GLFW_KEY_PAGE_DOWN,
    home = cc.GLFW_KEY_HOME,
    end = cc.GLFW_KEY_END,
    caps_lock = cc.GLFW_KEY_CAPS_LOCK,
    scroll_lock = cc.GLFW_KEY_SCROLL_LOCK,
    num_lock = cc.GLFW_KEY_NUM_LOCK,
    print_screen = cc.GLFW_KEY_PRINT_SCREEN,
    pause = cc.GLFW_KEY_PAUSE,
    F1 = cc.GLFW_KEY_F1,
    F2 = cc.GLFW_KEY_F2,
    F3 = cc.GLFW_KEY_F3,
    F4 = cc.GLFW_KEY_F4,
    F5 = cc.GLFW_KEY_F5,
    F6 = cc.GLFW_KEY_F6,
    F7 = cc.GLFW_KEY_F7,
    F8 = cc.GLFW_KEY_F8,
    F9 = cc.GLFW_KEY_F9,
    F10 = cc.GLFW_KEY_F10,
    F11 = cc.GLFW_KEY_F11,
    F12 = cc.GLFW_KEY_F12,
    F13 = cc.GLFW_KEY_F13,
    F14 = cc.GLFW_KEY_F14,
    F15 = cc.GLFW_KEY_F15,
    F16 = cc.GLFW_KEY_F16,
    F17 = cc.GLFW_KEY_F17,
    F18 = cc.GLFW_KEY_F18,
    F19 = cc.GLFW_KEY_F19,
    F20 = cc.GLFW_KEY_F20,
    F21 = cc.GLFW_KEY_F21,
    F22 = cc.GLFW_KEY_F22,
    F23 = cc.GLFW_KEY_F23,
    F24 = cc.GLFW_KEY_F24,
    F25 = cc.GLFW_KEY_F25,
    kp_0 = cc.GLFW_KEY_KP_0,
    kp_1 = cc.GLFW_KEY_KP_1,
    kp_2 = cc.GLFW_KEY_KP_2,
    kp_3 = cc.GLFW_KEY_KP_3,
    kp_4 = cc.GLFW_KEY_KP_4,
    kp_5 = cc.GLFW_KEY_KP_5,
    kp_6 = cc.GLFW_KEY_KP_6,
    kp_7 = cc.GLFW_KEY_KP_7,
    kp_8 = cc.GLFW_KEY_KP_8,
    kp_9 = cc.GLFW_KEY_KP_9,
    kp_decimal = cc.GLFW_KEY_KP_DECIMAL,
    kp_divide = cc.GLFW_KEY_KP_DIVIDE,
    kp_multiply = cc.GLFW_KEY_KP_MULTIPLY,
    kp_subtract = cc.GLFW_KEY_KP_SUBTRACT,
    kp_add = cc.GLFW_KEY_KP_ADD,
    kp_enter = cc.GLFW_KEY_KP_ENTER,
    kp_equal = cc.GLFW_KEY_KP_EQUAL,
    left_shift = cc.GLFW_KEY_LEFT_SHIFT,
    left_control = cc.GLFW_KEY_LEFT_CONTROL,
    left_alt = cc.GLFW_KEY_LEFT_ALT,
    left_super = cc.GLFW_KEY_LEFT_SUPER,
    right_shift = cc.GLFW_KEY_RIGHT_SHIFT,
    right_control = cc.GLFW_KEY_RIGHT_CONTROL,
    right_alt = cc.GLFW_KEY_RIGHT_ALT,
    right_super = cc.GLFW_KEY_RIGHT_SUPER,
    menu = cc.GLFW_KEY_MENU,

    pub inline fn last() Key {
        return @as(Key, @enumFromInt(cc.GLFW_KEY_LAST));
    }

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
    /// - `glfw.Key.apostrophe`
    /// - `glfw.Key.comma`
    /// - `glfw.Key.minus`
    /// - `glfw.Key.period`
    /// - `glfw.Key.slash`
    /// - `glfw.Key.semicolon`
    /// - `glfw.Key.equal`
    /// - `glfw.Key.left_bracket`
    /// - `glfw.Key.right_bracket`
    /// - `glfw.Key.backslash`
    /// - `glfw.Key.world_1`
    /// - `glfw.Key.world_2`
    /// - `glfw.Key.0` to `glfw.key.9`
    /// - `glfw.Key.a` to `glfw.key.z`
    /// - `glfw.Key.kp_0` to `glfw.key.kp_9`
    /// - `glfw.Key.kp_decimal`
    /// - `glfw.Key.kp_divide`
    /// - `glfw.Key.kp_multiply`
    /// - `glfw.Key.kp_subtract`
    /// - `glfw.Key.kp_add`
    /// - `glfw.Key.kp_equal`
    ///
    /// Names for printable keys depend on keyboard layout, while names for non-printable keys are the
    /// same across layouts but depend on the application language and should be localized along with
    /// other user interface text.
    ///
    /// @param[in] key The key to query, or `glfw.key.unknown`.
    /// @param[in] scancode The scancode of the key to query.
    /// @return The UTF-8 encoded, layout-specific name of the key, or null.
    ///
    /// Possible errors include glfw.ErrorCode.PlatformError.
    /// Also returns null in the event of an error.
    ///
    /// The contents of the returned string may change when a keyboard layout change event is received.
    ///
    /// @pointer_lifetime The returned string is allocated and freed by GLFW. You should not free it
    /// yourself. It is valid until the library is terminated.
    ///
    /// @thread_safety This function must only be called from the main thread.
    ///
    /// see also: input_key_name
    pub inline fn getName(self: Key, scancode: i32) ?[:0]const u8 {
        internal_debug.assertInitialized();
        const name_opt = cc.glfwGetKeyName(@intFromEnum(self), @as(c_int, @intCast(scancode)));
        return if (name_opt) |name|
            std.mem.span(@as([*:0]const u8, @ptrCast(name)))
        else
            null;
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
    /// Possible errors include glfw.ErrorCode.InvalidEnum and glfw.ErrorCode.PlatformError.
    /// Additionally returns -1 in the event of an error.
    ///
    /// @thread_safety This function may be called from any thread.
    pub inline fn getScancode(self: Key) i32 {
        internal_debug.assertInitialized();
        return cc.glfwGetKeyScancode(@intFromEnum(self));
    }
};

test "getName" {
    const glfw = @import("main.zig");
    defer glfw.clearError(); // clear any error we generate
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    _ = glfw.Key.a.getName(0);
}

test "getScancode" {
    const glfw = @import("main.zig");
    defer glfw.clearError(); // clear any error we generate
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    _ = glfw.Key.a.getScancode();
}
