const std = @import("std");
const core = @import("core");
const gpu = core.gpu;
const App = @import("app").App;

pub extern "mach" fn machLogWrite(str: [*]const u8, len: u32) void;
pub extern "mach" fn machLogFlush() void;
pub extern "mach" fn machPanic(str: [*]const u8, len: u32) void;

pub const GPUInterface = gpu.StubInterface;
const app_std_options = if (@hasDecl(App, "std_options")) App.std_options else struct {};

var app: App = undefined;
export fn wasmInit() void {
    app.init() catch unreachable;
}

export fn wasmUpdate() bool {
    return app.update() catch unreachable;
}

export fn wasmDeinit() void {
    app.deinit();
}

const LogError = error{};
const LogWriter = std.io.Writer(void, LogError, writeLog);

fn writeLog(_: void, msg: []const u8) LogError!usize {
    machLogWrite(msg.ptr, msg.len);
    return msg.len;
}

pub const std_options = struct {
    pub fn logFn(
        comptime message_level: std.log.Level,
        comptime scope: @Type(.EnumLiteral),
        comptime format: []const u8,
        args: anytype,
    ) void {
        const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
        const writer = LogWriter{ .context = {} };

        writer.print(message_level.asText() ++ prefix ++ format ++ "\n", args) catch return;
        machLogFlush();
    }

    pub const log_level = if (@hasDecl(app_std_options, "log_level"))
        app_std_options.log_level
    else
        std.log.default_level;

    pub const log_scope_levels = if (@hasDecl(app_std_options, "log_scope_levels"))
        app_std_options.log_scope_levels
    else
        &[0]std.log.ScopeLevel{};
};

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;
    machPanic(msg.ptr, msg.len);
    unreachable;
}
