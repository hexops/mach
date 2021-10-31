//! General constants

const c = @import("c.zig").c;

/// Possible values for glfw.Window.Hint.client_api hint
pub const no_api = c.GLFW_NO_API;
pub const opengl_api = c.GLFW_OPENGL_API;
pub const opengl_es_api = c.GLFW_OPENGL_ES_API;

/// Possible values for glfw.Window.Hint.context_robustness hint
pub const no_robustness = c.GLFW_NO_ROBUSTNESS;
pub const no_reset_notification = c.GLFW_NO_RESET_NOTIFICATION;
pub const lose_context_on_reset = c.GLFW_LOSE_CONTEXT_ON_RESET;

/// Possible values for glfw.Window.Hint.opengl_profile hint
pub const opengl_any_profile = c.GLFW_OPENGL_ANY_PROFILE;
pub const opengl_core_profile = c.GLFW_OPENGL_CORE_PROFILE;
pub const opengl_compat_profile = c.GLFW_OPENGL_COMPAT_PROFILE;

/// Possible values for glfw.Window.Hint.context_release_behavior hint
pub const any_release_behavior = c.GLFW_ANY_RELEASE_BEHAVIOR;
pub const release_behavior_flush = c.GLFW_RELEASE_BEHAVIOR_FLUSH;
pub const release_behavior_none = c.GLFW_RELEASE_BEHAVIOR_NONE;

/// Possible values for glfw.Window.Hint.context_creation_api hint
pub const native_context_api = c.GLFW_NATIVE_CONTEXT_API;
pub const egl_context_api = c.GLFW_EGL_CONTEXT_API;
pub const osmesa_context_api = c.GLFW_OSMESA_CONTEXT_API;

/// Possible value for various window hints, etc.
pub const dont_care = c.GLFW_DONT_CARE;
