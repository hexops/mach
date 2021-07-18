//! Modifier key flags
//!
//! See glfw.setKeyCallback for how these are used.

const c = @import("c.zig").c;

/// If this bit is set one or more Shift keys were held down.
pub const shift = C.GLFW_MOD_SHIFT;

/// If this bit is set one or more Control keys were held down.
pub const control = C.GLFW_MOD_CONTROL;

/// If this bit is set one or more Alt keys were held down.
pub const alt = C.GLFW_MOD_ALT;

/// If this bit is set one or more Super keys were held down.
pub const super = C.GLFW_MOD_SUPER;

/// If this bit is set the Caps Lock key is enabled and the glfw.lock_key_mods input mode is set.
pub const caps_lock = C.GLFW_MOD_CAPS_LOCK;

/// If this bit is set the Num Lock key is enabled and the glfw.lock_key_mods input mode is set.
pub const num_lock = C.GLFW_MOD_NUM_LOCK;
