const builtin = @import("builtin");

pub usingnamespace @import("platform.zig").entry;

comptime {
    if (!builtin.is_test) {
        if (!@hasDecl(@import("app"), "App")) {
            @compileError("expected e.g. `pub const App = mach.App(modules, init)' (App definition missing in your main Zig file)");
        }

        const App = @import("app").App;
        if (@typeInfo(App) != .Struct) {
            @compileError("App must be a struct type. Found:" ++ @typeName(App));
        }

        if (@hasDecl(App, "init")) {
            const InitFn = @TypeOf(@field(App, "init"));
            if (InitFn != fn (*App) @typeInfo(@typeInfo(InitFn).Fn.return_type.?).ErrorUnion.error_set!void)
                @compileError("expected 'pub fn init(app: *App) !void' found '" ++ @typeName(InitFn) ++ "'");
        } else {
            @compileError("App must export 'pub fn init(app: *App) !void'");
        }

        if (@hasDecl(App, "update")) {
            const UpdateFn = @TypeOf(@field(App, "update"));
            if (UpdateFn != fn (app: *App) @typeInfo(@typeInfo(UpdateFn).Fn.return_type.?).ErrorUnion.error_set!bool)
                @compileError("expected 'pub fn update(app: *App) !bool' found '" ++ @typeName(UpdateFn) ++ "'");
        } else {
            @compileError("App must export 'pub fn update(app: *App) !bool'");
        }

        if (@hasDecl(App, "deinit")) {
            const DeinitFn = @TypeOf(@field(App, "deinit"));
            if (DeinitFn != fn (app: *App) void)
                @compileError("expected 'pub fn deinit(app: *App) void' found '" ++ @typeName(DeinitFn) ++ "'");
        } else {
            @compileError("App must export 'pub fn deinit(app: *App) void'");
        }
    }
}
