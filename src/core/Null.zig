// The Null backend serves no purpose other than to show what the barebones structure of a Mach
// platform backend looks like.

const std = @import("std");
const mach = @import("../main.zig");
const Core = @import("../Core.zig");
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

const log = std.log.scoped(.mach);

pub const Null = @This();

allocator: std.mem.Allocator,
core: *Core,
input_state: Core.InputState,
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
pub fn init(
    nul: *Null,
    core: *Core.Mod,
    options: InitOptions,
) !void {
    _ = nul;
    _ = options;
    _ = core;
    return;
}

pub fn deinit(_: *Null) void {
    return;
}

// Called on the main thread
pub fn update(_: *Null) !void {
    return;
}

// May be called from any thread.
pub fn setTitle(_: *Null, _: [:0]const u8) void {
    return;
}

// May be called from any thread.
pub fn setDisplayMode(_: *Null, _: DisplayMode) void {
    return;
}

// May be called from any thread.
pub fn setBorder(_: *Null, _: bool) void {
    return;
}

// May be called from any thread.
pub fn setHeadless(_: *Null, _: bool) void {
    return;
}

// May be called from any thread.
pub fn setVSync(_: *Null, _: VSyncMode) void {
    return;
}

// May be called from any thread.
pub fn setSize(_: *Null, _: Size) void {
    return;
}

// May be called from any thread.
pub fn size(_: *Null) Size {
    return Size{ .width = 100, .height = 100 };
}

// May be called from any thread.
pub fn setCursorMode(_: *Null, _: CursorMode) void {
    return;
}

// May be called from any thread.
pub fn setCursorShape(_: *Null, _: CursorShape) void {
    return;
}

// May be called from any thread.
pub fn keyPressed(_: *Null, _: Key) bool {
    return false;
}

// May be called from any thread.
pub fn keyReleased(_: *Null, _: Key) bool {
    return true;
}

// May be called from any thread.
pub fn mousePressed(_: *Null, _: MouseButton) bool {
    return false;
}

// May be called from any thread.
pub fn mouseReleased(_: *Null, _: MouseButton) bool {
    return true;
}

// May be called from any thread.
pub fn mousePosition(_: *Null) Position {
    return Position{ .x = 0, .y = 0 };
}
