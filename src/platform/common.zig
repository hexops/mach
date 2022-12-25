const Core = @import("../Core.zig");

pub fn checkApplication(comptime app_pkg: type) void {
    if (!@hasDecl(app_pkg, "App")) {
        @compileError("expected e.g. `pub const App = mach.App(modules, init)' (App definition missing in your main Zig file)");
    }
    const App = app_pkg.App;

    if (@typeInfo(App) != .Struct) {
        @compileError("App must be a struct type. Found:" ++ @typeName(App));
    }

    if (@hasDecl(App, "init")) {
        const InitFn = @TypeOf(@field(App, "init"));
        if (InitFn != fn (app: *App, core: *Core) @typeInfo(@typeInfo(InitFn).Fn.return_type.?).ErrorUnion.error_set!void)
            @compileError("expected 'pub fn init(app: *App, core: *mach.Core) !void' found '" ++ @typeName(InitFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn init(app: *App, core: *mach.Core) !void'");
    }

    if (@hasDecl(App, "update")) {
        const UpdateFn = @TypeOf(@field(App, "update"));
        if (UpdateFn != fn (app: *App, core: *Core) @typeInfo(@typeInfo(UpdateFn).Fn.return_type.?).ErrorUnion.error_set!void)
            @compileError("expected 'pub fn update(app: *App, core: *mach.Core) !void' found '" ++ @typeName(UpdateFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn update(app: *App, core: *mach.Core) !void'");
    }

    if (@hasDecl(App, "deinit")) {
        const DeinitFn = @TypeOf(@field(App, "deinit"));
        if (DeinitFn != fn (app: *App, core: *Core) void)
            @compileError("expected 'pub fn deinit(app: *App, core: *mach.Core) void' found '" ++ @typeName(DeinitFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn deinit(app: *App, core: *mach.Core) void'");
    }
}
