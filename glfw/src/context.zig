
pub const c = @import("c.zig").c;

const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;
const Window = @import("Window.zig");

pub inline fn makeCurrent(window: Window) Error!void {
    c.glfwMakeContextCurrent(window.handle);
    try getError();
}

pub inline fn getCurrent() Error!Window {
    const window = c.glfwGetCurrentContext();
    try getError();
    return Window {.handle = window.?};
}
