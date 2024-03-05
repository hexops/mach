const std = @import("std");
const core = @import("main.zig");
const KeyBitSet = std.StaticBitSet(@intFromEnum(core.Key.max) + 1);
const MouseButtonSet = std.StaticBitSet(@as(u4, @intFromEnum(core.MouseButton.max)) + 1);
const InputState = @This();

keys: KeyBitSet = KeyBitSet.initEmpty(),
mouse_buttons: MouseButtonSet = MouseButtonSet.initEmpty(),
mouse_position: core.Position = .{ .x = 0, .y = 0 },

pub inline fn isKeyPressed(self: InputState, key: core.Key) bool {
    return self.keys.isSet(@intFromEnum(key));
}

pub inline fn isKeyReleased(self: InputState, key: core.Key) bool {
    return !self.isKeyPressed(key);
}

pub inline fn isMouseButtonPressed(self: InputState, button: core.MouseButton) bool {
    return self.mouse_buttons.isSet(@intFromEnum(button));
}

pub inline fn isMouseButtonReleased(self: InputState, button: core.MouseButton) bool {
    return !self.isMouseButtonPressed(button);
}
