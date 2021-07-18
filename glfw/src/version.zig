//! GLFW version info

const c = @import("c.zig").c;

/// The major version number of the GLFW library.
///
/// This is incremented when the API is changed in non-compatible ways.
pub const major = c.GLFW_VERSION_MAJOR;

/// The minor version number of the GLFW library.
///
/// This is incremented when features are added to the API but it remains backward-compatible.
pub const minor = c.GLFW_VERSION_MINOR;

/// The revision number of the GLFW library.
///
/// This is incremented when a bug fix release is made that does not contain any API changes.
pub const revision = c.GLFW_VERSION_REVISION;
