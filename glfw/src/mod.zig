//! Modifier key flags
//!
//! See glfw.setKeyCallback for how these are used.

const c = @import("c.zig").c;

// must be in sync with GLFW C constants in modifier group, search for "@defgroup mods Modifier key flags"
/// A bitmask of all key modifiers
pub const Mods = packed struct {
    shift: bool align(@alignOf(c_int)) = false,
    control: bool = false,
    alt: bool = false,
    super: bool = false,
    caps_lock: bool = false,
    num_lock: bool = false,

    inline fn verifyIntType(comptime IntType: type) void {
        comptime {
            switch (@typeInfo(IntType)) {
                .Int => {},
                else => @compileError("Int was not of int type"),
            }
        }
    }

    pub inline fn toInt(comptime IntType: type, self: Mods) IntType {
        verifyIntType(IntType);
        return @bitCast(IntType, self);
    }

    pub inline fn fromInt(flags: anytype) Mods {
        verifyIntType(@TypeOf(flags));
        return @bitCast(Mods, flags);
    }
};

/// Holds all GLFW mod values in their raw form.
pub const RawMods = struct {
    /// If this bit is set one or more Shift keys were held down.
    pub const shift = c.GLFW_MOD_SHIFT;

    /// If this bit is set one or more Control keys were held down.
    pub const control = c.GLFW_MOD_CONTROL;

    /// If this bit is set one or more Alt keys were held down.
    pub const alt = c.GLFW_MOD_ALT;

    /// If this bit is set one or more Super keys were held down.
    pub const super = c.GLFW_MOD_SUPER;

    /// If this bit is set the Caps Lock key is enabled and the glfw.lock_key_mods input mode is set.
    pub const caps_lock = c.GLFW_MOD_CAPS_LOCK;

    /// If this bit is set the Num Lock key is enabled and the glfw.lock_key_mods input mode is set.
    pub const num_lock = c.GLFW_MOD_NUM_LOCK;
};

test "shift int to bitmask" {
    const std = @import("std");

    const int_mod = RawMods.shift;
    const mod = Mods.fromInt(int_mod);

    std.testing.expect(mod.shift == true);
    std.testing.expect(mod.control == false);
    std.testing.expect(mod.alt == false);
    std.testing.expect(mod.super == false);
    std.testing.expect(mod.caps_lock == false);
    std.testing.expect(mod.num_lock == false);
}

test "shift int and alt to bitmask" {
    const std = @import("std");

    const int_mod = RawMods.shift | RawMods.alt;
    const mod = Mods.fromInt(int_mod);

    std.testing.expect(mod.shift == true);
    std.testing.expect(mod.control == false);
    std.testing.expect(mod.alt == true);
    std.testing.expect(mod.super == false);
    std.testing.expect(mod.caps_lock == false);
    std.testing.expect(mod.num_lock == false);
}

test "super int to bitmask" {
    const std = @import("std");

    const int_mod = RawMods.super;
    const mod = Mods.fromInt(int_mod);

    std.testing.expect(mod.shift == false);
    std.testing.expect(mod.control == false);
    std.testing.expect(mod.alt == false);
    std.testing.expect(mod.super == true);
    std.testing.expect(mod.caps_lock == false);
    std.testing.expect(mod.num_lock == false);
}

test "num lock int to bitmask" {
    const std = @import("std");

    const int_mod = RawMods.num_lock;
    const mod = Mods.fromInt(int_mod);

    std.testing.expect(mod.shift == false);
    std.testing.expect(mod.control == false);
    std.testing.expect(mod.alt == false);
    std.testing.expect(mod.super == false);
    std.testing.expect(mod.caps_lock == false);
    std.testing.expect(mod.num_lock == true);
}

test "all int to bitmask" {
    const std = @import("std");

    const int_mod = RawMods.shift | RawMods.control |
        RawMods.alt | RawMods.super |
        RawMods.caps_lock | RawMods.num_lock;
    const mod = Mods.fromInt(int_mod);

    std.testing.expect(mod.shift == true);
    std.testing.expect(mod.control == true);
    std.testing.expect(mod.alt == true);
    std.testing.expect(mod.super == true);
    std.testing.expect(mod.caps_lock == true);
    std.testing.expect(mod.num_lock == true);
}

test "shift bitmask to int" {
    const std = @import("std");

    const mod = Mods{ .shift = true };
    const int_mod = mod.toInt(c_int);

    std.testing.expectEqual(int_mod, RawMods.shift);
}

test "shift and alt bitmask to int" {
    const std = @import("std");

    const mod = Mods{ .shift = true, .alt = true };
    const int_mod = mod.toInt(c_int);

    std.testing.expectEqual(int_mod, RawMods.shift | RawMods.alt);
}

test "all bitmask to int" {
    const std = @import("std");

    const mod = Mods{
        .shift = true,
        .control = true,
        .alt = true,
        .super = true,
        .caps_lock = true,
        .num_lock = true,
    };
    const int_mod = mod.toInt(c_int);

    const expected = RawMods.shift | RawMods.control |
        RawMods.alt | RawMods.super |
        RawMods.caps_lock | RawMods.num_lock;

    std.testing.expectEqual(int_mod, expected);
}
