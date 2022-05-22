const std = @import("std");
const App = @import("app");
const Engine = @import("Engine.zig");
const structs = @import("structs.zig");
const enums = @import("enums.zig");

const js = struct {
    extern fn machCanvasInit(width: u32, height: u32, selector_id: *u8) CanvasId;
    extern fn machCanvasDeinit(canvas: CanvasId) void;
    extern fn machCanvasSetTitle(canvas: CanvasId, title: [*]const u8, len: u32) void;
    extern fn machCanvasSetSize(canvas: CanvasId, width: u32, height: u32) void;
    extern fn machCanvasGetWidth(canvas: CanvasId) u32;
    extern fn machCanvasGetHeight(canvas: CanvasId) u32;

    extern fn machLog(str: [*]const u8, len: u32) void;
    extern fn machLogWrite(str: [*]const u8, len: u32) void;
    extern fn machLogFlush() void;
    extern fn machPanic(str: [*]const u8, len: u32) void;
};

pub const CanvasId = u32;

pub const CoreWasm = struct {
    id: CanvasId,
    selector_id: []const u8,

    pub fn init(allocator: std.mem.Allocator, eng: *Engine) !CoreWasm {
        const options = eng.options;
        var selector = [1]u8{0} ** 15;
        const id = js.machCanvasInit(options.width, options.height, &selector[0]);

        const title = std.mem.span(options.title);
        js.machCanvasSetTitle(id, title.ptr, title.len);

        return CoreWasm{
            .id = id,
            .selector_id = try allocator.dupe(u8, selector[0 .. selector.len - @as(u32, if (selector[selector.len - 1] == 0) 1 else 0)]),
        };
    }

    pub fn setShouldClose(_: *CoreWasm, _: bool) void {}

    pub fn getFramebufferSize(_: *CoreWasm) !structs.Size {
        return structs.Size{ .width = 0, .height = 0 };
    }

    pub fn getWindowSize(core: *CoreWasm) !structs.Size {
        return structs.Size{
            .width = js.machCanvasGetWidth(core.id),
            .height = js.machCanvasGetHeight(core.id),
        };
    }

    pub fn setSizeLimits(_: *CoreWasm, _: structs.SizeOptional, _: structs.SizeOptional) !void {}

    pub fn pollEvent(_: *CoreWasm) ?structs.Event {
        return null;
    }
};

pub const GpuDriverWeb = struct {
    pub fn init(_: std.mem.Allocator, _: *Engine) !GpuDriverWeb {
        return GpuDriverWeb{};
    }
};

var app: App = undefined;
var engine: Engine = undefined;

export fn wasmInit() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const options = if (@hasDecl(App, "options")) App.options else structs.Options{};
    engine = Engine.init(allocator, options) catch unreachable;

    app.init(&engine) catch {};
}

export fn wasmUpdate() bool {
    return app.update(&engine) catch false;
}

export fn wasmDeinit() void {
    app.deinit(&engine);
}

pub const log_level = .info;

const LogError = error{};
const LogWriter = std.io.Writer(void, LogError, writeLog);

fn writeLog(_: void, msg: []const u8) LogError!usize {
    js.machLogWrite(msg.ptr, msg.len);
    return msg.len;
}

pub fn log(
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

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    js.machPanic(msg.ptr, msg.len);
    unreachable;
}
