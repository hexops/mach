// Check that the user's app matches the required interface.
comptime {
    if (!@import("builtin").is_test) @import("mach").core.AppInterface(@import("app"));
}

// Forward "app" declarations into our namespace, such that @import("root").foo works as expected.
pub usingnamespace @import("app");
const App = @import("app").App;

const std = @import("std");
const core = @import("mach").core;
const gpu = core.gpu;

pub const GPUInterface = gpu.StubInterface;

var app: App = undefined;
export fn wasmInit() void {
    App.init(&app) catch |err| @panic(@errorName(err));
}

export fn wasmUpdate() bool {
    if (core.update(&app) catch |err| @panic(@errorName(err))) {
        return true;
    }
    return false;
}

export fn wasmDeinit() void {
    app.deinit();
}

// Define std_options.logFn if the user did not in their "app" main.zig
pub usingnamespace if (@hasDecl(App, "std_options")) struct {} else struct {
    pub const std_options = std.Options{
        .logFn = core.defaultLog,
    };
};

// Define panic() if the user did not in their "app" main.zig
pub usingnamespace if (@hasDecl(App, "panic")) struct {} else struct {
    pub const panic = core.defaultPanic;
};
