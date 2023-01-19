const std = @import("std");
const gpu = @import("gpu");
const App = @import("app").App;
const js = @import("js.zig");

pub const GPUInterface = gpu.StubInterface;
pub const log_level = if (@hasDecl(App, "log_level")) App.log_level else std.log.default_level;
pub const scope_levels = if (@hasDecl(App, "scope_levels")) App.scope_levels else [0]std.log.ScopeLevel{};

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
    js.machLogWrite(msg.ptr, msg.len);
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
        js.machLogFlush();
    }
};

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;
    js.machPanic(msg.ptr, msg.len);
    unreachable;
}
