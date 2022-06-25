const Engine = @import("../Engine.zig");

pub fn checkApplication(comptime App: type) void {
    if (@hasDecl(App, "init")) {
        const InitFn = @TypeOf(@field(App, "init"));
        if (InitFn != fn (app: *App, engine: *Engine) @typeInfo(@typeInfo(InitFn).Fn.return_type.?).ErrorUnion.error_set!void)
            @compileError("expected 'pub fn init(app: *App, engine: *mach.Engine) !void' found '" ++ @typeName(InitFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn init(app: *App, engine: *mach.Engine) !void'");
    }

    if (@hasDecl(App, "update")) {
        const UpdateFn = @TypeOf(@field(App, "update"));
        if (UpdateFn != fn (app: *App, engine: *Engine) @typeInfo(@typeInfo(UpdateFn).Fn.return_type.?).ErrorUnion.error_set!void)
            @compileError("expected 'pub fn update(app: *App, engine: *mach.Engine) !void' found '" ++ @typeName(UpdateFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn update(app: *App, engine: *mach.Engine) !void'");
    }

    if (@hasDecl(App, "deinit")) {
        const DeinitFn = @TypeOf(@field(App, "deinit"));
        if (DeinitFn != fn (app: *App, engine: *Engine) void)
            @compileError("expected 'pub fn deinit(app: *App, engine: *mach.Engine) void' found '" ++ @typeName(DeinitFn) ++ "'");
    } else {
        @compileError("App must export 'pub fn deinit(app: *App, engine: *mach.Engine) void'");
    }
}
