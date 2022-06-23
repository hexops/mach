const std = @import("std");
const App = @import("app");
const Engine = @import("../Engine.zig");
const structs = @import("../structs.zig");
const enums = @import("../enums.zig");

const js = struct {
    extern fn machCanvasInit(selector_id: *u8) CanvasId;
    extern fn machCanvasDeinit(canvas: CanvasId) void;
    extern fn machCanvasSetTitle(canvas: CanvasId, title: [*]const u8, len: u32) void;
    extern fn machCanvasSetSize(canvas: CanvasId, width: u32, height: u32) void;
    extern fn machCanvasSetFullscreen(canvas: CanvasId, value: bool) void;
    extern fn machCanvasGetWindowWidth(canvas: CanvasId) u32;
    extern fn machCanvasGetWindowHeight(canvas: CanvasId) u32;
    extern fn machCanvasGetFramebufferWidth(canvas: CanvasId) u32;
    extern fn machCanvasGetFramebufferHeight(canvas: CanvasId) u32;
    extern fn machSetMouseCursor(cursor_name: [*]const u8, len: u32) void;
    extern fn machEmitCloseEvent() void;
    extern fn machSetWaitEvent(timeout: f64) void;
    extern fn machHasEvent() bool;
    extern fn machEventShift() i32;
    extern fn machEventShiftFloat() f64;
    extern fn machChangeShift() u32;
    extern fn machPerfNow() f64;

    extern fn machLog(str: [*]const u8, len: u32) void;
    extern fn machLogWrite(str: [*]const u8, len: u32) void;
    extern fn machLogFlush() void;
    extern fn machPanic(str: [*]const u8, len: u32) void;
};

pub const CanvasId = u32;

pub const Platform = struct {
    id: CanvasId,
    selector_id: []const u8,

    last_window_size: structs.Size,
    last_framebuffer_size: structs.Size,

    pub fn init(allocator: std.mem.Allocator, eng: *Engine) !Platform {
        var selector = [1]u8{0} ** 15;
        const id = js.machCanvasInit(&selector[0]);

        var platform = Platform{
            .id = id,
            .selector_id = try allocator.dupe(u8, selector[0 .. selector.len - @as(u32, if (selector[selector.len - 1] == 0) 1 else 0)]),
            .last_window_size = .{
                .width = js.machCanvasGetWindowWidth(id),
                .height = js.machCanvasGetWindowHeight(id),
            },
            .last_framebuffer_size = .{
                .width = js.machCanvasGetFramebufferWidth(id),
                .height = js.machCanvasGetFramebufferHeight(id),
            },
        };

        try platform.setOptions(eng.options);
        return platform;
    }

    pub fn setOptions(platform: *Platform, options: structs.Options) !void {
        // NOTE: size limits do not exists on wasm
        js.machCanvasSetSize(platform.id, options.width, options.height);

        const title = std.mem.span(options.title);
        js.machCanvasSetTitle(platform.id, title.ptr, title.len);

        js.machCanvasSetFullscreen(platform.id, options.fullscreen);
    }

    pub fn setShouldClose(_: *Platform, value: bool) void {
        if (value) js.machEmitCloseEvent();
    }

    pub fn setWaitEvent(_: *Platform, timeout: f64) void {
        js.machSetWaitEvent(timeout);
    }

    pub fn getFramebufferSize(platform: *Platform) structs.Size {
        return platform.last_framebuffer_size;
    }

    pub fn getWindowSize(platform: *Platform) structs.Size {
        return platform.last_window_size;
    }

    pub fn setMouseCursor(_: *Platform, cursor: enums.MouseCursor) !void {
        const cursor_name = @tagName(cursor);
        js.machSetMouseCursor(cursor_name.ptr, cursor_name.len);
    }

    fn pollChanges(platform: *Platform) void {
        const change_type = js.machChangeShift();

        switch (change_type) {
            1 => {
                const width = js.machChangeShift();
                const height = js.machChangeShift();
                const device_pixel_ratio = js.machChangeShift();

                platform.last_window_size = .{
                    .width = @divFloor(width, device_pixel_ratio),
                    .height = @divFloor(height, device_pixel_ratio),
                };

                platform.last_framebuffer_size = .{
                    .width = width,
                    .height = height,
                };
            },
            else => {},
        }
    }

    pub fn hasEvent(_: *Platform) bool {
        return js.machHasEvent();
    }

    pub fn pollEvent(_: *Platform) ?structs.Event {
        const event_type = js.machEventShift();

        return switch (event_type) {
            1 => structs.Event{
                .key_press = .{ .key = @intToEnum(enums.Key, js.machEventShift()) },
            },
            2 => structs.Event{
                .key_release = .{ .key = @intToEnum(enums.Key, js.machEventShift()) },
            },
            3 => structs.Event{
                .mouse_motion = .{
                    .x = @intToFloat(f64, js.machEventShift()),
                    .y = @intToFloat(f64, js.machEventShift()),
                },
            },
            4 => structs.Event{
                .mouse_press = .{
                    .button = toMachButton(js.machEventShift()),
                },
            },
            5 => structs.Event{
                .mouse_release = .{
                    .button = toMachButton(js.machEventShift()),
                },
            },
            6 => structs.Event{
                .mouse_scroll = .{
                    .xoffset = @floatCast(f32, sign(js.machEventShiftFloat())),
                    .yoffset = @floatCast(f32, sign(js.machEventShiftFloat())),
                },
            },
            else => null,
        };
    }

    inline fn sign(val: f64) f64 {
        return switch (val) {
            0.0 => 0.0,
            else => -val,
        };
    }

    fn toMachButton(button: i32) enums.MouseButton {
        return switch (button) {
            0 => .left,
            1 => .middle,
            2 => .right,
            3 => .four,
            4 => .five,
            else => unreachable,
        };
    }
};

pub const BackingTimer = struct {
    initial: f64 = undefined,

    const WasmTimer = @This();

    pub fn start() !WasmTimer {
        return WasmTimer{ .initial = js.machPerfNow() };
    }

    pub fn read(timer: *WasmTimer) u64 {
        return timeToNs(js.machPerfNow() - timer.initial);
    }

    pub fn reset(timer: *WasmTimer) void {
        timer.initial = js.machPerfNow();
    }

    pub fn lap(timer: *WasmTimer) u64 {
        const now = js.machPerfNow();
        const initial = timer.initial;
        timer.initial = now;
        return timeToNs(now - initial);
    }

    fn timeToNs(t: f64) u64 {
        return @floatToInt(u64, t) * 1000000;
    }
};

const common = @import("common.zig");
comptime {
    common.checkApplication(App);
}

var app: App = undefined;
var engine: Engine = undefined;

export fn wasmInit() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    engine = Engine.init(allocator) catch unreachable;
    app.init(&engine) catch {};
}

export fn wasmUpdate() void {
    // Poll internal events, like resize
    engine.internal.pollChanges();

    engine.delta_time_ns = engine.timer.lapPrecise();
    engine.delta_time = @intToFloat(f32, engine.delta_time_ns) / @intToFloat(f32, std.time.ns_per_s);

    app.update(&engine) catch engine.setShouldClose(true);
}

export fn wasmDeinit() void {
    app.deinit(&engine);
}

pub const log_level = if (@hasDecl(App, "log_level")) App.log_level else .info;
pub const scope_levels = if (@hasDecl(App, "scope_levels")) App.scope_levels else [0]std.log.ScopeLevel{};

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
