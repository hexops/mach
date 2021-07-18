//! The GLFW C import
//!
//! This is declared centrally in this module and imported in all usage locations, as otherwise
//! the underlying C import would be generated multiple times and e.g. struct types would be
//! incompatible, e.g.:
//!
//! ```
//! ./src/Monitor.zig:207:46: error: expected type '.cimport:8:11.struct_GLFWvidmode', found '.cimport:6:11.struct_GLFWvidmode'
//!         slice[i] = VideoMode{ .handle = modes[i] };
//!                                              ^
//! ./zig-cache/o/07cfe6253b7dceb60e4bf24e3426d444/cimport.zig:783:32: note: .cimport:8:11.struct_GLFWvidmode declared here
//! pub const struct_GLFWvidmode = extern struct {
//!                                ^
//! ./zig-cache/o/07cfe6253b7dceb60e4bf24e3426d444/cimport.zig:783:32: note: .cimport:6:11.struct_GLFWvidmode declared here
//! pub const struct_GLFWvidmode = extern struct {
//!                                ^
//! ```
pub const c = @cImport(@cInclude("GLFW/glfw3.h"));