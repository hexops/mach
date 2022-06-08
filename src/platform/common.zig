pub fn checkApplication(comptime App: type) void {
    // TODO: check signature
    if (!@hasDecl(App, "init")) @compileError("App must export 'pub fn init(app: *App, engine: *mach.Engine) !void'");
    if (!@hasDecl(App, "deinit")) @compileError("App must export 'pub fn deinit(app: *App, engine: *mach.Engine) void'");
    if (!@hasDecl(App, "update")) @compileError("App must export 'pub fn update(app: *App, engine: *mach.Engine) !void'");
}
