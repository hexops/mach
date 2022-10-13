const std = @import("std");
const app_pkg = @import("app");
const Core = @import("../Core.zig");
const structs = @import("../structs.zig");
const enums = @import("../enums.zig");
const gpu = @import("gpu");

const js = struct {
    extern "mach" fn machCanvasInit(selector_id: *u8) CanvasId;
    extern "mach" fn machCanvasDeinit(canvas: CanvasId) void;
    extern "mach" fn machCanvasSetTitle(canvas: CanvasId, title: [*]const u8, len: u32) void;
    extern "mach" fn machCanvasSetSize(canvas: CanvasId, width: u32, height: u32) void;
    extern "mach" fn machCanvasSetFullscreen(canvas: CanvasId, value: bool) void;
    extern "mach" fn machCanvasGetWindowWidth(canvas: CanvasId) u32;
    extern "mach" fn machCanvasGetWindowHeight(canvas: CanvasId) u32;
    extern "mach" fn machCanvasGetFramebufferWidth(canvas: CanvasId) u32;
    extern "mach" fn machCanvasGetFramebufferHeight(canvas: CanvasId) u32;
    extern "mach" fn machSetMouseCursor(cursor_name: [*]const u8, len: u32) void;
    extern "mach" fn machEmitCloseEvent() void;
    extern "mach" fn machSetWaitEvent(timeout: f64) void;
    extern "mach" fn machHasEvent() bool;
    extern "mach" fn machEventShift() i32;
    extern "mach" fn machEventShiftFloat() f64;
    extern "mach" fn machChangeShift() u32;
    extern "mach" fn machPerfNow() f64;

    extern "mach" fn machLog(str: [*]const u8, len: u32) void;
    extern "mach" fn machLogWrite(str: [*]const u8, len: u32) void;
    extern "mach" fn machLogFlush() void;
    extern "mach" fn machPanic(str: [*]const u8, len: u32) void;
};

const common = @import("common.zig");
comptime {
    common.checkApplication(app_pkg);
}
const App = app_pkg.App;

pub const GPUInterface = gpu.StubInterface;

pub const CanvasId = u32;

pub const Platform = struct {
    id: CanvasId,
    selector_id: []const u8,
    allocator: std.mem.Allocator,

    last_window_size: structs.Size,
    last_framebuffer_size: structs.Size,

    last_cursor_position: structs.WindowPos,
    last_key_mods: structs.KeyMods,

    pub fn init(allocator: std.mem.Allocator, eng: *Core) !Platform {
        var selector = [1]u8{0} ** 15;
        const id = js.machCanvasInit(&selector[0]);

        var platform = Platform{
            .id = id,
            .selector_id = try allocator.dupe(u8, selector[0 .. selector.len - @as(u32, if (selector[selector.len - 1] == 0) 1 else 0)]),
            .allocator = allocator,
            .last_window_size = .{
                .width = js.machCanvasGetWindowWidth(id),
                .height = js.machCanvasGetWindowHeight(id),
            },
            .last_framebuffer_size = .{
                .width = js.machCanvasGetFramebufferWidth(id),
                .height = js.machCanvasGetFramebufferHeight(id),
            },

            // TODO initialize these properly
            .last_cursor_position = .{
                .x = 0,
                .y = 0,
            },
            .last_key_mods = .{
                .shift = false,
                .control = false,
                .alt = false,
                .super = false,
                .caps_lock = false,
                .num_lock = false,
            },
        };

        try platform.setOptions(eng.options);
        return platform;
    }

    pub fn deinit(platform: *Platform) void {
        js.machCanvasDeinit(platform.id);
        platform.allocator.free(platform.selector_id);
    }

    pub fn setOptions(platform: *Platform, options: structs.Options) !void {
        // NOTE: size limits do not exists on wasm
        js.machCanvasSetSize(platform.id, options.width, options.height);

        const title = std.mem.span(options.title);
        js.machCanvasSetTitle(platform.id, title.ptr, title.len);

        js.machCanvasSetFullscreen(platform.id, options.fullscreen);
    }

    pub fn close(_: *Platform) void {
        js.machEmitCloseEvent();
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

    pub fn setCursorMode(_: *Platform, _: enums.CursorMode) !void {
        @panic("TODO: Implement setCursorMode for wasm");
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

    pub fn pollEvent(platform: *Platform) ?structs.Event {
        const event_type = js.machEventShift();

        return switch (event_type) {
            1, 2 => key_down: {
                const key = @intToEnum(enums.Key, js.machEventShift());
                switch (key) {
                    .left_shift, .right_shift => platform.last_key_mods.shift = true,
                    .left_control, .right_control => platform.last_key_mods.control = true,
                    .left_alt, .right_alt => platform.last_key_mods.alt = true,
                    .left_super, .right_super => platform.last_key_mods.super = true,
                    .caps_lock => platform.last_key_mods.caps_lock = true,
                    .num_lock => platform.last_key_mods.num_lock = true,
                    else => {},
                }
                break :key_down switch (event_type) {
                    1 => structs.Event{
                        .key_press = .{
                            .key = key,
                            .mods = platform.last_key_mods,
                        },
                    },
                    2 => structs.Event{
                        .key_repeat = .{
                            .key = key,
                            .mods = platform.last_key_mods,
                        },
                    },
                    else => unreachable,
                };
            },
            3 => key_release: {
                const key = @intToEnum(enums.Key, js.machEventShift());
                switch (key) {
                    .left_shift, .right_shift => platform.last_key_mods.shift = false,
                    .left_control, .right_control => platform.last_key_mods.control = false,
                    .left_alt, .right_alt => platform.last_key_mods.alt = false,
                    .left_super, .right_super => platform.last_key_mods.super = false,
                    .caps_lock => platform.last_key_mods.caps_lock = false,
                    .num_lock => platform.last_key_mods.num_lock = false,
                    else => {},
                }
                break :key_release structs.Event{
                    .key_release = .{
                        .key = key,
                        .mods = platform.last_key_mods,
                    },
                };
            },
            4 => mouse_motion: {
                const x = @intToFloat(f64, js.machEventShift());
                const y = @intToFloat(f64, js.machEventShift());
                platform.last_cursor_position = .{
                    .x = x,
                    .y = y,
                };
                break :mouse_motion structs.Event{
                    .mouse_motion = .{
                        .pos = .{
                            .x = x,
                            .y = y,
                        },
                    },
                };
            },
            5 => structs.Event{
                .mouse_press = .{
                    .button = toMachButton(js.machEventShift()),
                    .pos = platform.last_cursor_position,
                    .mods = platform.last_key_mods,
                },
            },
            6 => structs.Event{
                .mouse_release = .{
                    .button = toMachButton(js.machEventShift()),
                    .pos = platform.last_cursor_position,
                    .mods = platform.last_key_mods,
                },
            },
            7 => structs.Event{
                .mouse_scroll = .{
                    .xoffset = @floatCast(f32, sign(js.machEventShiftFloat())),
                    .yoffset = @floatCast(f32, sign(js.machEventShiftFloat())),
                },
            },
            8 => structs.Event.focus_gained,
            9 => structs.Event.focus_lost,
            else => null,
        };
    }

    inline fn sign(val: f64) f64 {
        return if (val == 0.0) 0.0 else -val;
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

var app: App = undefined;
var core: Core = undefined;

export fn wasmInit() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    Core.init(allocator, &core) catch unreachable;
    app.init(&core) catch {};
}

export fn wasmUpdate() void {
    // Poll internal events, like resize
    core.internal.pollChanges();

    core.delta_time_ns = core.timer.lapPrecise();
    core.delta_time = @intToFloat(f32, core.delta_time_ns) / @intToFloat(f32, std.time.ns_per_s);

    app.update(&core) catch core.close();
}

export fn wasmDeinit() void {
    app.deinit(&core);
    core.internal.deinit();
}

pub const log_level = if (@hasDecl(App, "log_level")) App.log_level else std.log.default_level;
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
