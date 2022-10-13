const builtin = @import("builtin");

const Platform = if (builtin.cpu.arch == .wasm32)
    Interface(@import("platform/wasm.zig"))
else
    Interface(@import("platform/native.zig"));

pub const Type = Platform.Platform;
pub const BackingTimerType = Platform.BackingTimer;

/// Verifies that a Platform implementation exposes the expected function declarations.
fn Interface(comptime T: type) type {
    assertHasDecl(T, "Platform");
    assertHasDecl(T, "BackingTimer");
    assertHasDecl(T.Platform, "init");
    assertHasDecl(T.Platform, "deinit");
    assertHasDecl(T.Platform, "setOptions");
    assertHasDecl(T.Platform, "close");
    assertHasDecl(T.Platform, "setWaitEvent");
    assertHasDecl(T.Platform, "getFramebufferSize");
    assertHasDecl(T.Platform, "getWindowSize");
    assertHasDecl(T.Platform, "setMouseCursor");
    assertHasDecl(T.Platform, "setCursorMode");
    assertHasDecl(T.Platform, "hasEvent");
    assertHasDecl(T.Platform, "pollEvent");
    assertHasDecl(T.BackingTimer, "start");
    assertHasDecl(T.BackingTimer, "read");
    assertHasDecl(T.BackingTimer, "reset");
    assertHasDecl(T.BackingTimer, "lap");

    return T;
}

fn assertDecl(comptime T: anytype, comptime name: []const u8, comptime Decl: type) void {
    assertHasDecl(T, name);
    const FoundDecl = @TypeOf(@field(T, name));
    if (FoundDecl != Decl) @compileError("Platform field '" ++ name ++ "'\n\texpected type: " ++ @typeName(Decl) ++ "\n\t   found type: " ++ @typeName(FoundDecl));
}

fn assertHasDecl(comptime T: anytype, comptime name: []const u8) void {
    if (!@hasDecl(T, name)) @compileError("Platform missing declaration: " ++ name);
}
