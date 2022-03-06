//! A standard interface to a WebGPU implementation.
//!
//! Like std.mem.Allocator, but representing a WebGPU implementation.

// The type erased pointer to the Device implementation
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    // TODO(gpu): make these *const fn once stage2 is released.
    free: fn (ptr: *anyopaque, buf: []u8, buf_align: u29, ret_addr: usize) void,
};
