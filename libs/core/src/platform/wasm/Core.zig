const std = @import("std");
const gpu = @import("gpu");
const js = @import("js.zig");
const Timer = @import("Timer.zig");
const Options = @import("../../Core.zig").Options;
const Event = @import("../../Core.zig").Event;
const KeyEvent = @import("../../Core.zig").KeyEvent;
const MouseButtonEvent = @import("../../Core.zig").MouseButtonEvent;
const MouseButton = @import("../../Core.zig").MouseButton;
const Size = @import("../../Core.zig").Size;
const Position = @import("../../Core.zig").Position;
const DisplayMode = @import("../../Core.zig").DisplayMode;
const SizeLimit = @import("../../Core.zig").SizeLimit;
const CursorShape = @import("../../Core.zig").CursorShape;
const VSyncMode = @import("../../Core.zig").VSyncMode;
const CursorMode = @import("../../Core.zig").CursorMode;
const Key = @import("../../Core.zig").Key;
const KeyMods = @import("../../Core.zig").KeyMods;

pub const Core = @This();

allocator: std.mem.Allocator,
id: js.CanvasId,

last_cursor_position: Position,
last_key_mods: KeyMods,

pub const EventIterator = struct {
    core: *Core,

    pub inline fn next(self: *EventIterator) ?Event {
        const event_int = js.machEventShift();
        if (event_int == -1) return null;

        const event_type = @intToEnum(std.meta.Tag(Event), event_int);
        return switch (event_type) {
            .key_press, .key_repeat => blk: {
                const key = @intToEnum(Key, js.machEventShift());
                switch (key) {
                    .left_shift, .right_shift => self.last_key_mods.shift = true,
                    .left_control, .right_control => self.last_key_mods.control = true,
                    .left_alt, .right_alt => self.last_key_mods.alt = true,
                    .left_super, .right_super => self.last_key_mods.super = true,
                    .caps_lock => self.last_key_mods.caps_lock = true,
                    .num_lock => self.last_key_mods.num_lock = true,
                    else => {},
                }
                break :blk switch (event_type) {
                    .key_press => Event{
                        .key_press = .{
                            .key = key,
                            .mods = self.last_key_mods,
                        },
                    },
                    .key_repeat => Event{
                        .key_repeat = .{
                            .key = key,
                            .mods = self.last_key_mods,
                        },
                    },
                    else => unreachable,
                };
            },
            .key_release => blk: {
                const key = @intToEnum(Key, js.machEventShift());
                switch (key) {
                    .left_shift, .right_shift => self.last_key_mods.shift = false,
                    .left_control, .right_control => self.last_key_mods.control = false,
                    .left_alt, .right_alt => self.last_key_mods.alt = false,
                    .left_super, .right_super => self.last_key_mods.super = false,
                    .caps_lock => self.last_key_mods.caps_lock = false,
                    .num_lock => self.last_key_mods.num_lock = false,
                    else => {},
                }
                break :blk Event{
                    .key_release = .{
                        .key = key,
                        .mods = self.last_key_mods,
                    },
                };
            },
            .mouse_motion => blk: {
                const x = @intToFloat(f64, js.machEventShift());
                const y = @intToFloat(f64, js.machEventShift());
                self.last_cursor_position = .{
                    .x = x,
                    .y = y,
                };
                break :blk Event{
                    .mouse_motion = .{
                        .pos = .{
                            .x = x,
                            .y = y,
                        },
                    },
                };
            },
            .mouse_press => Event{
                .mouse_press = .{
                    .button = toMachButton(js.machEventShift()),
                    .pos = self.last_cursor_position,
                    .mods = self.last_key_mods,
                },
            },
            .mouse_release => Event{
                .mouse_release = .{
                    .button = toMachButton(js.machEventShift()),
                    .pos = self.last_cursor_position,
                    .mods = self.last_key_mods,
                },
            },
            .mouse_scroll => Event{
                .mouse_scroll = .{
                    .xoffset = @floatCast(f32, std.math.sign(js.machEventShiftFloat())),
                    .yoffset = @floatCast(f32, std.math.sign(js.machEventShiftFloat())),
                },
            },
            .framebuffer_resize => blk: {
                const width = @intCast(u32, js.machEventShift());
                const height = @intCast(u32, js.machEventShift());
                const pixel_ratio = @intCast(u32, js.machEventShift());
                break :blk Event{
                    .framebuffer_resize = .{
                        .width = width * pixel_ratio,
                        .height = height * pixel_ratio,
                    },
                };
            },
            .focus_gained => Event.focus_gained,
            .focus_lost => Event.focus_lost,
            else => null,
        };
    }
};

pub fn init(core: *Core, allocator: std.mem.Allocator, options: Options) !void {
    _ = options;
    var selector = [1]u8{0} ** 15;
    const id = js.machCanvasInit(&selector[0]);

    core.* = Core{
        .allocator = allocator,
        .id = id,

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
}

pub fn deinit(self: *Core) void {
    js.machCanvasDeinit(self.id);
}

pub inline fn pollEvents(self: *Core) EventIterator {
    return EventIterator{ .core = self };
}

pub fn framebufferSize(self: *Core) Size {
    return .{
        .width = js.machCanvasFramebufferWidth(self.id),
        .height = js.machCanvasFramebufferHeight(self.id),
    };
}

pub fn setWaitTimeout(_: *Core, timeout: f64) void {
    js.machSetWaitTimeout(timeout);
}

pub fn setTitle(self: *Core, title: [:0]const u8) void {
    js.machCanvasSetTitle(self.id, title.ptr, title.len);
}

pub fn setDisplayMode(self: *Core, mode: DisplayMode, monitor: ?usize) void {
    _ = monitor;
    if (mode == .borderless) {
        // borderless fullscreen window has no meaning in web
        mode = .fullscreen;
    }
    js.machCanvasSetDisplayMode(self.id, @enumToInt(mode));
}

pub fn displayMode(self: *Core) DisplayMode {
    return @intToEnum(DisplayMode, js.machDisplayMode(self.id));
}

pub fn setBorder(self: *Core, value: bool) void {
    _ = self;
    _ = value;
}

pub fn border(self: *Core) bool {
    _ = self;
    return false;
}

pub fn setHeadless(self: *Core, value: bool) void {
    _ = self;
    _ = value;
}

pub fn headless(self: *Core) bool {
    _ = self;
    return false;
}

pub fn setVSync(self: *Core, mode: VSyncMode) void {
    _ = self;
    _ = mode;
}

// TODO: https://github.com/gpuweb/gpuweb/issues/1224
pub fn vsync(self: *Core) VSyncMode {
    _ = self;
    return .double;
}

pub fn setSize(self: *Core, value: Size) void {
    js.machCanvasSetSize(self.id, value.width, value.height);
}

pub fn size(self: *Core) Size {
    return .{
        .width = js.machCanvasWidth(self.id),
        .height = js.machCanvasHeight(self.id),
    };
}

pub fn setSizeLimit(self: *Core, limit: SizeLimit) void {
    js.machCanvasSetSizeLimit(
        self.id,
        if (limit.min.width) |val| @intCast(i32, val) else -1,
        if (limit.min.height) |val| @intCast(i32, val) else -1,
        if (limit.max.width) |val| @intCast(i32, val) else -1,
        if (limit.max.height) |val| @intCast(i32, val) else -1,
    );
}

pub fn sizeLimit(self: *Core) SizeLimit {
    return .{
        .min = .{
            .width = js.machCanvasMinWidth(self.id),
            .height = js.machCanvasMinHeight(self.id),
        },
        .max = .{
            .width = js.machCanvasMaxWidth(self.id),
            .height = js.machCanvasMaxHeight(self.id),
        },
    };
}

pub fn setCursorMode(self: *Core, mode: CursorMode) void {
    js.machSetCursorMode(self.id, @enumToInt(mode));
}

pub fn cursorMode(self: *Core) CursorMode {
    return @intToEnum(CursorMode, js.machCursorMode(self.id));
}

pub fn setCursorShape(self: *Core, shape: CursorShape) void {
    js.machSetCursorShape(self.id, @enumToInt(shape));
}

pub fn cursorShape(self: *Core) CursorShape {
    return @intToEnum(CursorShape, js.machCursorShape(self.id));
}

pub fn adapter(_: *Core) *gpu.Adapter {
    unreachable;
}

pub fn device(_: *Core) *gpu.Device {
    unreachable;
}

pub fn swapChain(_: *Core) *gpu.SwapChain {
    unreachable;
}

pub fn descriptor(_: *Core) gpu.SwapChain.Descriptor {
    unreachable;
}

fn toMachButton(button: i32) MouseButton {
    return switch (button) {
        0 => .left,
        1 => .middle,
        2 => .right,
        3 => .four,
        4 => .five,
        else => unreachable,
    };
}
