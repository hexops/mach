const std = @import("std");
const mach = @import("../main.zig");
const Core = @import("../Core.zig");
const InputState = @import("InputState.zig");
const Frequency = @import("Frequency.zig");
const unicode = @import("unicode.zig");
const detectBackendType = @import("common.zig").detectBackendType;
const gpu = mach.gpu;
const InitOptions = Core.InitOptions;
const Event = Core.Event;
const KeyEvent = Core.KeyEvent;
const MouseButtonEvent = Core.MouseButtonEvent;
const MouseButton = Core.MouseButton;
const Size = Core.Size;
const DisplayMode = Core.DisplayMode;
const CursorShape = Core.CursorShape;
const VSyncMode = Core.VSyncMode;
const CursorMode = Core.CursorMode;
const Position = Core.Position;
const Key = Core.Key;
const KeyMods = Core.KeyMods;
const Joystick = Core.Joystick;
const objc = @import("objc");

const log = std.log.scoped(.mach);

const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);
pub const EventIterator = struct {
    queue: *EventQueue,

    pub inline fn next(self: *EventIterator) ?Event {
        return self.queue.readItem();
    }
};

pub const Darwin = @This();

allocator: std.mem.Allocator,
core: *Core,

events: EventQueue,
input_state: InputState,
modifiers: KeyMods,

title: [:0]u8,
display_mode: DisplayMode,
vsync_mode: VSyncMode,
cursor_mode: CursorMode,
cursor_shape: CursorShape,
border: bool,
headless: bool,
refresh_rate: u32,
size: Size,
surface_descriptor: gpu.Surface.Descriptor,

// Called on the main thread
pub fn init(_: *Darwin, _: InitOptions) !void {
    const app = objc.appkit.ns.Application.sharedApplication();
    _ = app; // autofix
    return;
}

pub fn deinit(_: *Darwin) void {
    return;
}

// Called on the main thread
pub fn update(_: *Darwin) !void {
    return;
}

// May be called from any thread.
pub inline fn pollEvents(n: *Darwin) EventIterator {
    return EventIterator{ .queue = &n.events };
}

// May be called from any thread.
pub fn setTitle(_: *Darwin, _: [:0]const u8) void {
    return;
}

// May be called from any thread.
pub fn setDisplayMode(_: *Darwin, _: DisplayMode) void {
    return;
}

// May be called from any thread.
pub fn setBorder(_: *Darwin, _: bool) void {
    return;
}

// May be called from any thread.
pub fn setHeadless(_: *Darwin, _: bool) void {
    return;
}

// May be called from any thread.
pub fn setVSync(_: *Darwin, _: VSyncMode) void {
    return;
}

// May be called from any thread.
pub fn setSize(_: *Darwin, _: Size) void {
    return;
}

// May be called from any thread.
pub fn size(_: *Darwin) Size {
    return Size{ .width = 100, .height = 100 };
}

// May be called from any thread.
pub fn setCursorMode(_: *Darwin, _: CursorMode) void {
    return;
}

// May be called from any thread.
pub fn setCursorShape(_: *Darwin, _: CursorShape) void {
    return;
}

// May be called from any thread.
pub fn joystickPresent(_: *Darwin, _: Joystick) bool {
    return false;
}

// May be called from any thread.
pub fn joystickName(_: *Darwin, _: Joystick) ?[:0]const u8 {
    return null;
}

// May be called from any thread.
pub fn joystickButtons(_: *Darwin, _: Joystick) ?[]const bool {
    return null;
}

// May be called from any thread.
pub fn joystickAxes(_: *Darwin, _: Joystick) ?[]const f32 {
    return null;
}

// May be called from any thread.
pub fn keyPressed(_: *Darwin, _: Key) bool {
    return false;
}

// May be called from any thread.
pub fn keyReleased(_: *Darwin, _: Key) bool {
    return true;
}

// May be called from any thread.
pub fn mousePressed(_: *Darwin, _: MouseButton) bool {
    return false;
}

// May be called from any thread.
pub fn mouseReleased(_: *Darwin, _: MouseButton) bool {
    return true;
}

// May be called from any thread.
pub fn mousePosition(_: *Darwin) Position {
    return Position{ .x = 0, .y = 0 };
}
