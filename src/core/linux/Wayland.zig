const std = @import("std");
const mach = @import("../../main.zig");
const gpu = mach.gpu;
const Linux = @import("../Linux.zig");
const Core = @import("../../Core.zig");
const InitOptions = Core.InitOptions;
const log = std.log.scoped(.mach);
const shimizu = @import("shimizu");
const wayland_protocols = @import("wayland-protocols");
const xdg_shell = wayland_protocols.xdg_shell;
const xdg_decoration_v1 = wayland_protocols.xdg_decoration_unstable_v1;

pub const Wayland = @This();

pub const c = @cImport({
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("xkbcommon/xkbcommon-compose.h");
    @cInclude("linux/input-event-codes.h");
});

state: *Core,
core: *Core,
title: [:0]const u8,
size: *Core.Size,
surface_descriptor: *gpu.Surface.DescriptorFromWaylandSurface,
configured: bool = false,

connection: shimizu.Connection,
surface: shimizu.Proxy(shimizu.core.wl_surface),
interfaces: Interfaces,

// input stuff
keyboard: ?shimizu.Proxy(shimizu.core.wl_keyboard) = null,
pointer: ?shimizu.Proxy(shimizu.core.wl_pointer) = null,
input_state: Core.InputState,

// keyboard stuff
xkb_context: ?*c.xkb_context = null,
xkb_state: ?*c.xkb_state = null,
compose_state: ?*c.xkb_compose_state = null,
keymap: ?*c.xkb_keymap = null,
libxkbcommon: LibXkbCommon,
modifiers: Core.KeyMods,
modifier_indices: KeyModInd,

xdg_wm_base_listener: shimizu.Listener,
wl_seat_listener: shimizu.Listener,
keyboard_listener: shimizu.Listener,
pointer_listener: shimizu.Listener,
xdg_surface_listener: shimizu.Listener,
xdg_toplevel_listener: shimizu.Listener,

pub fn init(
    linux: *Linux,
    core: *Core.Mod,
    options: InitOptions,
) !Wayland {
    const connection = shimizu.openConnection(options.allocator, .{}) catch return error.FailedToConnectToDisplay;

    var wl = Wayland{
        .core = @fieldParentPtr("platform", linux),
        .state = core.state(),
        .libxkbcommon = try LibXkbCommon.load(),
        .interfaces = Interfaces{},
        .connection = connection,
        .title = try options.allocator.dupeZ(u8, options.title),
        .size = &linux.size,
        .modifiers = .{
            .alt = false,
            .caps_lock = false,
            .control = false,
            .num_lock = false,
            .shift = false,
            .super = false,
        },
        .input_state = .{},
        .modifier_indices = .{ // TODO: make sure these are always getting initialized, we don't want undefined behavior
            .control_index = undefined,
            .alt_index = undefined,
            .shift_index = undefined,
            .super_index = undefined,
            .caps_lock_index = undefined,
            .num_lock_index = undefined,
        },
        .surface_descriptor = undefined,
        .surface = undefined,

        .xdg_wm_base_listener = undefined,
        .wl_seat_listener = undefined,
        .keyboard_listener = undefined,
        .pointer_listener = undefined,
        .xdg_surface_listener = undefined,
        .xdg_toplevel_listener = undefined,
    };
    wl.xkb_context = wl.libxkbcommon.xkb_context_new(0) orelse return error.FailedToGetXkbContext;
    const registry = try wl.connection.getDisplayProxy().sendRequest(.get_registry, .{});

    // TODO: handle error return value here
    var registry_event_listener: shimizu.Listener = undefined;
    registry.setEventListener(&registry_event_listener, registry_listener.onRegistryEvent, &wl);

    //Round trip to get all the registry objects
    var roundtrip_done: bool = false;
    var roundtrip_listener: shimizu.Listener = undefined;

    var sync_callback = try wl.connection.getDisplayProxy().sendRequest(.sync, .{});
    sync_callback.setEventListener(&roundtrip_listener, onWlCallbackSetTrue, &roundtrip_done);

    while (!roundtrip_done) {
        try wl.connection.recv();
    }

    //Round trip to get all initial output events
    roundtrip_done = false;
    sync_callback = try wl.connection.getDisplayProxy().sendRequest(.sync, .{});
    sync_callback.setEventListener(&roundtrip_listener, onWlCallbackSetTrue, &roundtrip_done);

    while (!roundtrip_done) {
        try wl.connection.recv();
    }

    if (wl.interfaces.wl_compositor == null) {
        return error.NoWlCompositor;
    }
    if (wl.interfaces.zxdg_decoration_manager_v1 == null) {
        return error.NoServerSideDecorationSupport;
    }

    //Setup surface
    wl.surface = try wl.interfaces.wl_compositor.?.sendRequest(.create_surface, .{});
    wl.surface_descriptor = try options.allocator.create(gpu.Surface.DescriptorFromWaylandSurface);

    // TODO: libwayland shim?
    @memset(std.mem.asBytes(wl.surface_descriptor), 0);
    // wl.surface_descriptor.* = .{ .display = @ptrCast(@as(?*anyopaque, null)), .surface = @ptrCast(@as(?*anyopaque, null)) };

    {
        const region = try wl.interfaces.wl_compositor.?.sendRequest(.create_region, .{});

        try region.sendRequest(.add, .{
            .x = 0,
            .y = 0,
            .width = @intCast(wl.size.width),
            .height = @intCast(wl.size.height),
        });
        try wl.surface.sendRequest(.set_opaque_region, .{
            .region = region.id,
        });
        try region.sendRequest(.destroy, .{});
    }

    const xdg_surface = try wl.interfaces.xdg_wm_base.?.sendRequest(.get_xdg_surface, .{ .surface = wl.surface.id });
    const toplevel = try xdg_surface.sendRequest(.get_toplevel, .{});

    // TODO: handle this return value
    xdg_surface.setEventListener(&wl.xdg_surface_listener, onXdgSurfaceEvent, null);

    // TODO: handle this return value
    toplevel.setEventListener(&wl.xdg_toplevel_listener, onXdgToplevelEvent, null);

    // Commit changes to surface
    try wl.surface.sendRequest(.commit, .{});

    while (!wl.configured) {
        // This space intentionally left blank
        try wl.connection.recv();
    }

    try toplevel.sendRequest(.set_title, .{ .title = wl.title });

    const decoration = try wl.interfaces.zxdg_decoration_manager_v1.?.sendRequest(.get_toplevel_decoration, .{ .toplevel = toplevel.id });

    try decoration.sendRequest(.set_mode, .{ .mode = .server_side });

    // Commit changes to surface
    try wl.surface.sendRequest(.commit, .{});

    // TODO: handle return value
    roundtrip_done = false;
    sync_callback = try wl.connection.getDisplayProxy().sendRequest(.sync, .{});
    sync_callback.setEventListener(&roundtrip_listener, onWlCallbackSetTrue, &roundtrip_done);

    while (!roundtrip_done) {
        try wl.connection.recv();
    }

    return wl;
}

pub fn deinit(
    wl: *Wayland,
    linux: *Linux,
) void {
    linux.allocator.destroy(wl.surface_descriptor);
}

pub fn update(wl: *Wayland) !void {
    _ = wl.libwaylandclient.wl_display_roundtrip(wl.display);

    wl.core.input.tick();
}

const LibXkbCommon = struct {
    handle: std.DynLib,

    xkb_context_new: *const @TypeOf(c.xkb_context_new),
    xkb_keymap_new_from_string: *const @TypeOf(c.xkb_keymap_new_from_string),
    xkb_state_new: *const @TypeOf(c.xkb_state_new),
    xkb_keymap_unref: *const @TypeOf(c.xkb_keymap_unref),
    xkb_state_unref: *const @TypeOf(c.xkb_state_unref),
    xkb_compose_table_new_from_locale: *const @TypeOf(c.xkb_compose_table_new_from_locale),
    xkb_compose_state_new: *const @TypeOf(c.xkb_compose_state_new),
    xkb_compose_table_unref: *const @TypeOf(c.xkb_compose_table_unref),
    xkb_keymap_mod_get_index: *const @TypeOf(c.xkb_keymap_mod_get_index),
    xkb_state_update_mask: *const @TypeOf(c.xkb_state_update_mask),
    xkb_state_mod_index_is_active: *const @TypeOf(c.xkb_state_mod_index_is_active),
    xkb_state_key_get_syms: *const @TypeOf(c.xkb_state_key_get_syms),
    xkb_compose_state_feed: *const @TypeOf(c.xkb_compose_state_feed),
    xkb_compose_state_get_status: *const @TypeOf(c.xkb_compose_state_get_status),
    xkb_compose_state_get_one_sym: *const @TypeOf(c.xkb_compose_state_get_one_sym),
    xkb_keysym_to_utf32: *const @TypeOf(c.xkb_keysym_to_utf32),

    pub fn load() !LibXkbCommon {
        var lib: LibXkbCommon = undefined;
        lib.handle = std.DynLib.open("libxkbcommon.so.0") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibXkbCommon).@"struct".fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse {
                log.err("Symbol lookup failed for {s}", .{name});
                return error.SymbolLookup;
            };
        }
        return lib;
    }
};

const Interfaces = struct {
    wl_compositor: ?shimizu.Proxy(shimizu.core.wl_compositor) = null,
    wl_subcompositor: ?shimizu.Proxy(shimizu.core.wl_subcompositor) = null,
    wl_shm: ?shimizu.Proxy(shimizu.core.wl_shm) = null,
    wl_output: ?shimizu.Proxy(shimizu.core.wl_output) = null,
    wl_seat: ?shimizu.Proxy(shimizu.core.wl_seat) = null,
    wl_data_device_manager: ?shimizu.Proxy(shimizu.core.wl_data_device_manager) = null,
    xdg_wm_base: ?shimizu.Proxy(xdg_shell.xdg_wm_base) = null,
    zxdg_decoration_manager_v1: ?shimizu.Proxy(xdg_decoration_v1.zxdg_decoration_manager_v1) = null,
};

const KeyModInd = struct {
    control_index: c.xkb_mod_index_t,
    alt_index: c.xkb_mod_index_t,
    shift_index: c.xkb_mod_index_t,
    super_index: c.xkb_mod_index_t,
    caps_lock_index: c.xkb_mod_index_t,
    num_lock_index: c.xkb_mod_index_t,
};

const registry_listener = struct {
    fn onRegistryEvent(listener: *shimizu.Listener, registry: shimizu.Proxy(shimizu.core.wl_registry), event: shimizu.core.wl_registry.Event) shimizu.Listener.Error!void {
        const wl: *Wayland = @ptrCast(@alignCast(listener.userdata));

        switch (event) {
            .global => |global| {
                if (shimizu.globalMatchesInterface(global, shimizu.core.wl_compositor)) {
                    const wl_compositor = try registry.connection.createObject(shimizu.core.wl_compositor);
                    try registry.sendRequest(.bind, .{ .name = global.name, .id = wl_compositor.id.asGenericNewId() });
                    wl.interfaces.wl_compositor = wl_compositor;
                } else if (shimizu.globalMatchesInterface(global, shimizu.core.wl_subcompositor)) {
                    const wl_subcompositor = try registry.connection.createObject(shimizu.core.wl_subcompositor);
                    try registry.sendRequest(.bind, .{ .name = global.name, .id = wl_subcompositor.id.asGenericNewId() });
                    wl.interfaces.wl_subcompositor = wl_subcompositor;
                } else if (shimizu.globalMatchesInterface(global, shimizu.core.wl_shm)) {
                    const wl_shm = try registry.connection.createObject(shimizu.core.wl_shm);
                    try registry.sendRequest(.bind, .{ .name = global.name, .id = wl_shm.id.asGenericNewId() });
                    wl.interfaces.wl_shm = wl_shm;
                } else if (shimizu.globalMatchesInterface(global, shimizu.core.wl_output)) {
                    const wl_output = try registry.connection.createObject(shimizu.core.wl_output);
                    try registry.sendRequest(.bind, .{ .name = global.name, .id = wl_output.id.asGenericNewId() });
                    wl.interfaces.wl_output = wl_output;
                } else if (shimizu.globalMatchesInterface(global, shimizu.core.wl_data_device_manager)) {
                    const wl_data_device_manager = try registry.connection.createObject(shimizu.core.wl_data_device_manager);
                    try registry.sendRequest(.bind, .{ .name = global.name, .id = wl_data_device_manager.id.asGenericNewId() });
                    wl.interfaces.wl_data_device_manager = wl_data_device_manager;
                } else if (shimizu.globalMatchesInterface(global, xdg_shell.xdg_wm_base)) {
                    const xdg_wm_base = try registry.connection.createObject(xdg_shell.xdg_wm_base);
                    try registry.sendRequest(.bind, .{ .name = global.name, .id = xdg_wm_base.id.asGenericNewId() });
                    wl.interfaces.xdg_wm_base = xdg_wm_base;

                    xdg_wm_base.setEventListener(&wl.xdg_wm_base_listener, onXdgWmBaseEvent, null);
                } else if (shimizu.globalMatchesInterface(global, xdg_decoration_v1.zxdg_decoration_manager_v1)) {
                    const zxdg_decorations_manager = try registry.connection.createObject(xdg_decoration_v1.zxdg_decoration_manager_v1);
                    try registry.sendRequest(.bind, .{ .name = global.name, .id = zxdg_decorations_manager.id.asGenericNewId() });
                    wl.interfaces.zxdg_decoration_manager_v1 = zxdg_decorations_manager;
                } else if (shimizu.globalMatchesInterface(global, shimizu.core.wl_seat)) {
                    const wl_seat = try registry.connection.createObject(shimizu.core.wl_seat);
                    try registry.sendRequest(.bind, .{ .name = global.name, .id = wl_seat.id.asGenericNewId() });
                    wl.interfaces.wl_seat = wl_seat;
                    wl_seat.setEventListener(&wl.wl_seat_listener, onWlSeatEvent, wl);
                }
            },

            .global_remove => {},
        }
    }
};

fn onWlKeyboardEvent(keyboard_listener: *shimizu.Listener, wl_keyboard: shimizu.Proxy(shimizu.core.wl_keyboard), event: shimizu.core.wl_keyboard.Event) !void {
    const wl: *Wayland = @fieldParentPtr("keyboard_listener", keyboard_listener);
    _ = wl_keyboard;
    switch (event) {
        .keymap => |ev| {
            if (ev.format != .xkb_v1) {
                @panic("TODO");
            }

            const map_str = std.posix.mmap(null, ev.size, std.posix.PROT.READ, .{ .TYPE = .SHARED }, @intFromEnum(ev.fd), 0) catch unreachable;

            const keymap = wl.libxkbcommon.xkb_keymap_new_from_string(
                wl.xkb_context,
                @alignCast(map_str), //align cast happening here, im sure its fine? TODO: figure out if this okay
                c.XKB_KEYMAP_FORMAT_TEXT_V1,
                0,
            ).?;

            //Unmap the keymap
            std.posix.munmap(map_str);
            //Close the fd
            std.posix.close(@intFromEnum(ev.fd));

            const state = wl.libxkbcommon.xkb_state_new(keymap).?;
            defer wl.libxkbcommon.xkb_state_unref(state);

            //this chain hurts me. why must C be this way.
            const locale = std.posix.getenv("LC_ALL") orelse std.posix.getenv("LC_CTYPE") orelse std.posix.getenv("LANG") orelse "C";

            var compose_table = wl.libxkbcommon.xkb_compose_table_new_from_locale(
                wl.xkb_context,
                locale,
                c.XKB_COMPOSE_COMPILE_NO_FLAGS,
            );

            //If creation failed, lets try the C locale
            if (compose_table == null)
                compose_table = wl.libxkbcommon.xkb_compose_table_new_from_locale(
                    wl.xkb_context,
                    "C",
                    c.XKB_COMPOSE_COMPILE_NO_FLAGS,
                ).?;

            defer wl.libxkbcommon.xkb_compose_table_unref(compose_table);

            wl.keymap = keymap;
            wl.xkb_state = state;
            wl.compose_state = wl.libxkbcommon.xkb_compose_state_new(compose_table, c.XKB_COMPOSE_STATE_NO_FLAGS).?;

            wl.modifier_indices.control_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Control");
            wl.modifier_indices.alt_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod1");
            wl.modifier_indices.shift_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Shift");
            wl.modifier_indices.super_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod4");
            wl.modifier_indices.caps_lock_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Lock");
            wl.modifier_indices.num_lock_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod2");
        },
        .enter => wl.state.pushEvent(.focus_gained),
        .leave => wl.state.pushEvent(.focus_lost),
        .key => |key_ev| {
            const key = toMachKey(key_ev.key);
            const pressed = key_ev.state == .pressed;

            wl.input_state.keys.setValue(@intFromEnum(key), pressed);

            if (key_ev.state == .pressed) {
                wl.state.pushEvent(Core.Event{ .key_press = .{
                    .key = key,
                    .mods = wl.modifiers,
                } });

                var keysyms: ?[*]c.xkb_keysym_t = undefined;
                //Get the keysym from the keycode (scancode + 8)
                if (wl.libxkbcommon.xkb_state_key_get_syms(wl.xkb_state, key_ev.key + 8, &keysyms) == 1) {
                    //Compose the keysym
                    const keysym: c.xkb_keysym_t = composeSymbol(wl, keysyms.?[0]);

                    //Try to convert that keysym to a unicode codepoint
                    const codepoint = wl.libxkbcommon.xkb_keysym_to_utf32(keysym);
                    if (codepoint != 0) {
                        wl.state.pushEvent(Core.Event{ .char_input = .{ .codepoint = @truncate(codepoint) } });
                    }
                }
            } else {
                wl.state.pushEvent(Core.Event{ .key_release = .{
                    .key = key,
                    .mods = wl.modifiers,
                } });
            }
        },

        .modifiers => |mods| {
            if (wl.keymap == null)
                return;

            // TODO: handle this return value
            _ = wl.libxkbcommon.xkb_state_update_mask(
                wl.xkb_state.?,
                mods.mods_depressed,
                mods.mods_latched,
                mods.mods_locked,
                0,
                0,
                mods.group,
            );

            //Iterate over all the modifiers
            inline for (.{
                .{ wl.modifier_indices.alt_index, "alt" },
                .{ wl.modifier_indices.shift_index, "shift" },
                .{ wl.modifier_indices.super_index, "super" },
                .{ wl.modifier_indices.control_index, "control" },
                .{ wl.modifier_indices.num_lock_index, "num_lock" },
                .{ wl.modifier_indices.caps_lock_index, "caps_lock" },
            }) |key| {
                @field(wl.modifiers, key[1]) = wl.libxkbcommon.xkb_state_mod_index_is_active(
                    wl.xkb_state,
                    key[0],
                    c.XKB_STATE_MODS_EFFECTIVE,
                ) == 1;
            }
        },

        .repeat_info => {},
    }
}

fn onWlPointerEvent(pointer_listener: *shimizu.Listener, pointer: shimizu.Proxy(shimizu.core.wl_pointer), event: shimizu.core.wl_pointer.Event) !void {
    const wl: *Wayland = @fieldParentPtr("pointer_listener", pointer_listener);
    _ = pointer;
    switch (event) {
        .axis => {},
        .frame => {},
        .axis_source => {},
        .axis_stop => {},
        .axis_discrete => {},
        .axis_value120 => {},
        .axis_relative_direction => {},
        .enter => {},
        .leave => {},
        .motion => |motion| {
            const x = motion.surface_x.toFloat(f32);
            const y = motion.surface_y.toFloat(f32);

            wl.state.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
            wl.input_state.mouse_position = .{ .x = x, .y = y };
        },
        .button => |btn| {
            const mouse_button: Core.MouseButton = @enumFromInt(btn.button - c.BTN_LEFT);
            const pressed = btn.state == .pressed;

            wl.input_state.mouse_buttons.setValue(@intFromEnum(mouse_button), pressed);

            if (pressed) {
                wl.state.pushEvent(Core.Event{ .mouse_press = .{
                    .button = mouse_button,
                    .mods = wl.modifiers,
                    .pos = wl.input_state.mouse_position,
                } });
            } else {
                wl.state.pushEvent(Core.Event{ .mouse_release = .{
                    .button = mouse_button,
                    .mods = wl.modifiers,
                    .pos = wl.input_state.mouse_position,
                } });
            }
        },
    }
}

fn onWlSeatEvent(wl_seat_listener: *shimizu.Listener, wl_seat: shimizu.Proxy(shimizu.core.wl_seat), event: shimizu.core.wl_seat.Event) !void {
    const wl: *Wayland = @fieldParentPtr("wl_seat_listener", wl_seat_listener);
    switch (event) {
        .name => {},
        .capabilities => |capabilities| {
            const caps = capabilities.capabilities;

            // Delete keyboard if its no longer in the seat
            if (wl.keyboard) |keyboard| {
                if (!caps.keyboard) {
                    try keyboard.sendRequest(.release, .{});
                    wl.keyboard = null;
                }
            }

            if (wl.pointer) |pointer| {
                if (!caps.pointer) {
                    try pointer.sendRequest(.release, .{});
                    wl.pointer = null;
                }
            }

            // check if there are any new capabilities
            if (caps.keyboard) {
                wl.keyboard = try wl_seat.sendRequest(.get_keyboard, .{});
                wl.keyboard.?.setEventListener(&wl.keyboard_listener, onWlKeyboardEvent, null);
            }

            if (caps.touch) {
                // TODO
            }

            if (caps.pointer) {
                wl.pointer = try wl_seat.sendRequest(.get_pointer, .{});
                wl.pointer.?.setEventListener(&wl.keyboard_listener, onWlPointerEvent, null);
            }
        },
    }
}

fn onXdgWmBaseEvent(listener: *shimizu.Listener, xdg_wm_base: shimizu.Proxy(xdg_shell.xdg_wm_base), event: xdg_shell.xdg_wm_base.Event) shimizu.Listener.Error!void {
    _ = listener;
    switch (event) {
        .ping => |ping| {
            try xdg_wm_base.sendRequest(.pong, .{ .serial = ping.serial });
        },
    }
}

fn onXdgSurfaceEvent(xdg_surface_listener: *shimizu.Listener, xdg_surface: shimizu.Proxy(xdg_shell.xdg_surface), event: xdg_shell.xdg_surface.Event) shimizu.Listener.Error!void {
    const wl: *Wayland = @fieldParentPtr("xdg_surface_listener", xdg_surface_listener);
    switch (event) {
        .configure => |configure| {
            try xdg_surface.sendRequest(.ack_configure, .{ .serial = configure.serial });
            if (wl.configured) {
                try wl.surface.sendRequest(.commit, .{});
            } else {
                wl.configured = true;
            }
            setContentAreaOpaque(wl, wl.size.*);
        },
    }
}

fn onXdgToplevelEvent(xdg_toplevel_listener: *shimizu.Listener, xdg_toplevel: shimizu.Proxy(xdg_shell.xdg_toplevel), event: xdg_shell.xdg_toplevel.Event) shimizu.Listener.Error!void {
    const wl: *Wayland = @fieldParentPtr("xdg_toplevel_listener", xdg_toplevel_listener);
    _ = xdg_toplevel;
    switch (event) {
        .close => {},
        .configure => |configure| {
            if (configure.width > 0 and configure.height > 0) {
                wl.size.* = .{ .width = @intCast(configure.width), .height = @intCast(configure.height) };
            }
        },
        .configure_bounds => {},
        .wm_capabilities => {},
    }
}

fn composeSymbol(wl: *Wayland, sym: c.xkb_keysym_t) c.xkb_keysym_t {
    if (sym == c.XKB_KEY_NoSymbol or wl.compose_state == null)
        return sym;

    if (wl.libxkbcommon.xkb_compose_state_feed(wl.compose_state, sym) != c.XKB_COMPOSE_FEED_ACCEPTED)
        return sym;

    return switch (wl.libxkbcommon.xkb_compose_state_get_status(wl.compose_state)) {
        c.XKB_COMPOSE_COMPOSED => wl.libxkbcommon.xkb_compose_state_get_one_sym(wl.compose_state),
        c.XKB_COMPOSE_COMPOSING, c.XKB_COMPOSE_CANCELLED => c.XKB_KEY_NoSymbol,
        else => sym,
    };
}

fn toMachKey(key: u32) Core.Key {
    return switch (key) {
        c.KEY_GRAVE => .grave,
        c.KEY_1 => .one,
        c.KEY_2 => .two,
        c.KEY_3 => .three,
        c.KEY_4 => .four,
        c.KEY_5 => .five,
        c.KEY_6 => .six,
        c.KEY_7 => .seven,
        c.KEY_8 => .eight,
        c.KEY_9 => .nine,
        c.KEY_0 => .zero,
        c.KEY_SPACE => .space,
        c.KEY_MINUS => .minus,
        c.KEY_EQUAL => .equal,
        c.KEY_Q => .q,
        c.KEY_W => .w,
        c.KEY_E => .e,
        c.KEY_R => .r,
        c.KEY_T => .t,
        c.KEY_Y => .y,
        c.KEY_U => .u,
        c.KEY_I => .i,
        c.KEY_O => .o,
        c.KEY_P => .p,
        c.KEY_LEFTBRACE => .left_bracket,
        c.KEY_RIGHTBRACE => .right_bracket,
        c.KEY_A => .a,
        c.KEY_S => .s,
        c.KEY_D => .d,
        c.KEY_F => .f,
        c.KEY_G => .g,
        c.KEY_H => .h,
        c.KEY_J => .j,
        c.KEY_K => .k,
        c.KEY_L => .l,
        c.KEY_SEMICOLON => .semicolon,
        c.KEY_APOSTROPHE => .apostrophe,
        c.KEY_Z => .z,
        c.KEY_X => .x,
        c.KEY_C => .c,
        c.KEY_V => .v,
        c.KEY_B => .b,
        c.KEY_N => .n,
        c.KEY_M => .m,
        c.KEY_COMMA => .comma,
        c.KEY_DOT => .period,
        c.KEY_SLASH => .slash,
        c.KEY_BACKSLASH => .backslash,
        c.KEY_ESC => .escape,
        c.KEY_TAB => .tab,
        c.KEY_LEFTSHIFT => .left_shift,
        c.KEY_RIGHTSHIFT => .right_shift,
        c.KEY_LEFTCTRL => .left_control,
        c.KEY_RIGHTCTRL => .right_control,
        c.KEY_LEFTALT => .left_alt,
        c.KEY_RIGHTALT => .right_alt,
        c.KEY_LEFTMETA => .left_super,
        c.KEY_RIGHTMETA => .right_super,
        c.KEY_NUMLOCK => .num_lock,
        c.KEY_CAPSLOCK => .caps_lock,
        c.KEY_PRINT => .print,
        c.KEY_SCROLLLOCK => .scroll_lock,
        c.KEY_PAUSE => .pause,
        c.KEY_DELETE => .delete,
        c.KEY_BACKSPACE => .backspace,
        c.KEY_ENTER => .enter,
        c.KEY_HOME => .home,
        c.KEY_END => .end,
        c.KEY_PAGEUP => .page_up,
        c.KEY_PAGEDOWN => .page_down,
        c.KEY_INSERT => .insert,
        c.KEY_LEFT => .left,
        c.KEY_RIGHT => .right,
        c.KEY_DOWN => .down,
        c.KEY_UP => .up,
        c.KEY_F1 => .f1,
        c.KEY_F2 => .f2,
        c.KEY_F3 => .f3,
        c.KEY_F4 => .f4,
        c.KEY_F5 => .f5,
        c.KEY_F6 => .f6,
        c.KEY_F7 => .f7,
        c.KEY_F8 => .f8,
        c.KEY_F9 => .f9,
        c.KEY_F10 => .f10,
        c.KEY_F11 => .f11,
        c.KEY_F12 => .f12,
        c.KEY_F13 => .f13,
        c.KEY_F14 => .f14,
        c.KEY_F15 => .f15,
        c.KEY_F16 => .f16,
        c.KEY_F17 => .f17,
        c.KEY_F18 => .f18,
        c.KEY_F19 => .f19,
        c.KEY_F20 => .f20,
        c.KEY_F21 => .f21,
        c.KEY_F22 => .f22,
        c.KEY_F23 => .f23,
        c.KEY_F24 => .f24,
        c.KEY_KPSLASH => .kp_divide,
        c.KEY_KPASTERISK => .kp_multiply,
        c.KEY_KPMINUS => .kp_subtract,
        c.KEY_KPPLUS => .kp_add,
        c.KEY_KP0 => .kp_0,
        c.KEY_KP1 => .kp_1,
        c.KEY_KP2 => .kp_2,
        c.KEY_KP3 => .kp_3,
        c.KEY_KP4 => .kp_4,
        c.KEY_KP5 => .kp_5,
        c.KEY_KP6 => .kp_6,
        c.KEY_KP7 => .kp_7,
        c.KEY_KP8 => .kp_8,
        c.KEY_KP9 => .kp_9,
        c.KEY_KPDOT => .kp_decimal,
        c.KEY_KPEQUAL => .kp_equal,
        c.KEY_KPENTER => .kp_enter,
        else => .unknown,
    };
}

fn setContentAreaOpaque(wl: *Wayland, new_size: Core.Size) void {
    const region = wl.interfaces.wl_compositor.?.sendRequest(.create_region, .{}) catch return;

    region.sendRequest(.add, .{ .x = 0, .y = 0, .width = @intCast(new_size.width), .height = @intCast(new_size.height) }) catch return;
    wl.surface.sendRequest(.set_opaque_region, .{ .region = region.id }) catch return;
    region.sendRequest(.destroy, .{}) catch return;

    wl.core.swap_chain_update.set();
}

fn onWlCallbackSetTrue(listener: *shimizu.Listener, wl_callback: shimizu.Proxy(shimizu.core.wl_callback), event: shimizu.core.wl_callback.Event) shimizu.Listener.Error!void {
    _ = wl_callback;
    _ = event;

    const bool_ptr: *bool = @ptrCast((listener.userdata.?));
    bool_ptr.* = true;
}
