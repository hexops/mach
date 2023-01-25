const builtin = @import("builtin");

pub usingnamespace if (builtin.cpu.arch == .wasm32)
    @import("platform/wasm.zig")
else
    @import("platform/native.zig");

// Verifies that a platform implementation exposes the expected function declarations.
comptime {
    assertHasDecl(@This(), "entry");
    assertHasDecl(@This(), "Core");
    assertHasDecl(@This(), "Timer");

    // Core
    assertHasDecl(@This().Core, "init");
    assertHasDecl(@This().Core, "deinit");
    assertHasDecl(@This().Core, "pollEvents");
    assertHasDecl(@This().Core, "framebufferSize");

    assertHasDecl(@This().Core, "setWaitTimeout");
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

    assertHasDecl(@This().Core, "adapter");
    assertHasDecl(@This().Core, "device");
    assertHasDecl(@This().Core, "swapChain");
    assertHasDecl(@This().Core, "descriptor");

    // Timer
    assertHasDecl(@This().Timer, "start");
    assertHasDecl(@This().Timer, "read");
    assertHasDecl(@This().Timer, "reset");
    assertHasDecl(@This().Timer, "lap");
}

fn assertHasDecl(comptime T: anytype, comptime name: []const u8) void {
    if (!@hasDecl(T, name)) @compileError("Core missing declaration: " ++ name);
}
