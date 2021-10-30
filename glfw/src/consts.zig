//! General constants

const c = @import("c.zig").c;

pub const no_api = c.GLFW_NO_API;
pub const opengl_api = c.GLFW_OPENGL_API;
pub const opengl_es_api = c.GLFW_OPENGL_ES_API;

pub const no_robustness = c.GLFW_NO_ROBUSTNESS;
pub const no_reset_notification = c.GLFW_NO_RESET_NOTIFICATION;
pub const lose_context_on_reset = c.GLFW_LOSE_CONTEXT_ON_RESET;

pub const opengl_any_profile = c.GLFW_OPENGL_ANY_PROFILE;
pub const opengl_core_profile = c.GLFW_OPENGL_CORE_PROFILE;
pub const opengl_compat_profile = c.GLFW_OPENGL_COMPAT_PROFILE;

pub const cursor = c.GLFW_CURSOR;
pub const sticky_keys = c.GLFW_STICKY_KEYS;
pub const sticky_mouse_buttons = c.GLFW_STICKY_MOUSE_BUTTONS;
pub const lock_key_mods = c.GLFW_LOCK_KEY_MODS;
pub const raw_mouse_motion = c.GLFW_RAW_MOUSE_MOTION;

pub const cursor_normal = c.GLFW_CURSOR_NORMAL;
pub const cursor_hidden = c.GLFW_CURSOR_HIDDEN;
pub const cursor_disabled = c.GLFW_CURSOR_DISABLED;

pub const any_release_behavior = c.GLFW_ANY_RELEASE_BEHAVIOR;
pub const release_behavior_flush = c.GLFW_RELEASE_BEHAVIOR_FLUSH;
pub const release_behavior_none = c.GLFW_RELEASE_BEHAVIOR_NONE;

pub const native_context_api = c.GLFW_NATIVE_CONTEXT_API;
pub const egl_context_api = c.GLFW_EGL_CONTEXT_API;
pub const osmesa_context_api = c.GLFW_OSMESA_CONTEXT_API;

pub const connected = c.GLFW_CONNECTED;
pub const disconnected = c.GLFW_DISCONNECTED;

/// Joystick hat buttons init hint.
pub const joystick_hat_buttons = c.GLFW_JOYSTICK_HAT_BUTTONS;

/// macOS specific init hint.
pub const cocoa_chdir_resources = c.GLFW_COCOA_CHDIR_RESOURCES;

/// macOS specific init hint.
pub const cocoa_menubar = c.GLFW_COCOA_MENUBAR;

pub const dont_care = c.GLFW_DONT_CARE;
