const builtin = @import("builtin");
const options = @import("build-options");

const use_glfw = true;
const use_x11 = false;
const platform = switch (options.core_platform) {
    .glfw => @import("platform/glfw.zig"),
    .x11 => @import("platform/x11.zig"),
    .wayland => @import("platform/wayland.zig"),
    .web => @import("platform/wasm.zig"),
};

pub const Core = platform.Core;
pub const Timer = platform.Timer;

// Verifies that a platform implementation exposes the expected function declarations.
comptime {
    assertHasDecl(@This(), "Core");
    assertHasDecl(@This(), "Timer");

    // Core
    assertHasDecl(@This().Core, "init");
    assertHasDecl(@This().Core, "deinit");
    assertHasDecl(@This().Core, "pollEvents");

    assertHasDecl(@This().Core, "setTitle");

    assertHasDecl(@This().Core, "setDisplayMode");
    assertHasDecl(@This().Core, "displayMode");

    assertHasDecl(@This().Core, "setBorder");
    assertHasDecl(@This().Core, "border");

    assertHasDecl(@This().Core, "setHeadless");
    assertHasDecl(@This().Core, "headless");

    assertHasDecl(@This().Core, "setVSync");
    assertHasDecl(@This().Core, "vsync");

    assertHasDecl(@This().Core, "setSize");
    assertHasDecl(@This().Core, "size");

    assertHasDecl(@This().Core, "setSizeLimit");
    assertHasDecl(@This().Core, "sizeLimit");

    assertHasDecl(@This().Core, "setCursorMode");
    assertHasDecl(@This().Core, "cursorMode");

    assertHasDecl(@This().Core, "setCursorShape");
    assertHasDecl(@This().Core, "cursorShape");

    assertHasDecl(@This().Core, "joystickPresent");
    assertHasDecl(@This().Core, "joystickName");
    assertHasDecl(@This().Core, "joystickButtons");
    assertHasDecl(@This().Core, "joystickAxes");

    assertHasDecl(@This().Core, "keyPressed");
    assertHasDecl(@This().Core, "keyReleased");
    assertHasDecl(@This().Core, "mousePressed");
    assertHasDecl(@This().Core, "mouseReleased");
    assertHasDecl(@This().Core, "mousePosition");

    assertHasDecl(@This().Core, "outOfMemory");

    // Timer
    assertHasDecl(@This().Timer, "start");
    assertHasDecl(@This().Timer, "read");
    assertHasDecl(@This().Timer, "reset");
    assertHasDecl(@This().Timer, "lap");
}

fn assertHasDecl(comptime T: anytype, comptime name: []const u8) void {
    if (!@hasDecl(T, name)) @compileError("Core missing declaration: " ++ name);
}
