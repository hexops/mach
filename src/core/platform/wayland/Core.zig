const std = @import("std");
const mach = @import("../../../main.zig");
const mach_core = @import("../../main.zig");
const gpu = mach.gpu;
const Options = @import("../../main.zig").Options;
const Event = @import("../../main.zig").Event;
const KeyEvent = @import("../../main.zig").KeyEvent;
const MouseButtonEvent = @import("../../main.zig").MouseButtonEvent;
const MouseButton = @import("../../main.zig").MouseButton;
const Size = @import("../../main.zig").Size;
const DisplayMode = @import("../../main.zig").DisplayMode;
const SizeLimit = @import("../../main.zig").SizeLimit;
const CursorShape = @import("../../main.zig").CursorShape;
const VSyncMode = @import("../../main.zig").VSyncMode;
const CursorMode = @import("../../main.zig").CursorMode;
const Key = @import("../../main.zig").Key;
const KeyMods = @import("../../main.zig").KeyMods;
const Joystick = @import("../../main.zig").Joystick;
const InputState = @import("../../InputState.zig");
const Frequency = @import("../../Frequency.zig");
const RequestAdapterResponse = @import("../common.zig").RequestAdapterResponse;
const printUnhandledErrorCallback = @import("../common.zig").printUnhandledErrorCallback;
const detectBackendType = @import("../common.zig").detectBackendType;
const wantGamemode = @import("../common.zig").wantGamemode;
const initLinuxGamemode = @import("../common.zig").initLinuxGamemode;
const deinitLinuxGamemode = @import("../common.zig").deinitLinuxGamemode;
const requestAdapterCallback = @import("../common.zig").requestAdapterCallback;
const Unicode = @import("../x11/unicode.zig");

const log = std.log.scoped(.mach);

pub const c = @cImport({
    @cInclude("wayland-client-protocol.h");
    @cInclude("wayland-xdg-shell-client-protocol.h");
    @cInclude("wayland-xdg-decoration-client-protocol.h");
    @cInclude("wayland-viewporter-client-protocol.h");
    @cInclude("wayland-relative-pointer-unstable-v1-client-protocol.h");
    @cInclude("wayland-pointer-constraints-unstable-v1-client-protocol.h");
    @cInclude("wayland-idle-inhibit-unstable-v1-client-protocol.h");
    @cInclude("xkbcommon/xkbcommon.h");
    @cInclude("xkbcommon/xkbcommon-compose.h");
    @cInclude("linux/input-event-codes.h");
});

var libwaylandclient: LibWaylandClient = undefined;

export fn wl_proxy_add_listener(proxy: ?*c.struct_wl_proxy, implementation: [*c]?*const fn () callconv(.C) void, data: ?*anyopaque) c_int {
    return @call(.always_tail, libwaylandclient.wl_proxy_add_listener, .{ proxy, implementation, data });
}

export fn wl_proxy_get_version(proxy: ?*c.struct_wl_proxy) u32 {
    return @call(.always_tail, libwaylandclient.wl_proxy_get_version, .{proxy});
}

export fn wl_proxy_marshal_flags(proxy: ?*c.struct_wl_proxy, opcode: u32, interface: [*c]const c.struct_wl_interface, version: u32, flags: u32, ...) ?*c.struct_wl_proxy {
    var arg_list: std.builtin.VaList = @cVaStart();
    defer @cVaEnd(&arg_list);

    return @call(.always_tail, libwaylandclient.wl_proxy_marshal_flags, .{ proxy, opcode, interface, version, flags, arg_list });
}

export fn wl_proxy_destroy(proxy: ?*c.struct_wl_proxy) void {
    return @call(.always_tail, libwaylandclient.wl_proxy_destroy, .{proxy});
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

    pub fn load() !LibXkbCommon {
        var lib: LibXkbCommon = undefined;
        lib.handle = std.DynLib.openZ("libxkbcommon.so.0") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibXkbCommon).Struct.fields[1..]) |field| {
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

const LibWaylandClient = struct {
    handle: std.DynLib,

    wl_display_connect: *const @TypeOf(c.wl_display_connect),
    wl_proxy_add_listener: *const @TypeOf(c.wl_proxy_add_listener),
    wl_proxy_get_version: *const @TypeOf(c.wl_proxy_get_version),
    wl_proxy_marshal_flags: *const @TypeOf(c.wl_proxy_marshal_flags),
    wl_proxy_set_tag: *const @TypeOf(c.wl_proxy_set_tag),
    wl_proxy_destroy: *const @TypeOf(c.wl_proxy_destroy),
    wl_display_roundtrip: *const @TypeOf(c.wl_display_roundtrip),
    wl_display_dispatch: *const @TypeOf(c.wl_display_dispatch),
    wl_display_flush: *const @TypeOf(c.wl_display_flush),
    wl_display_get_fd: *const @TypeOf(c.wl_display_get_fd),

    //Interfaces
    wl_compositor_interface: *@TypeOf(c.wl_compositor_interface),
    wl_subcompositor_interface: *@TypeOf(c.wl_subcompositor_interface),
    wl_shm_interface: *@TypeOf(c.wl_subcompositor_interface),
    wl_data_device_manager_interface: *@TypeOf(c.wl_data_device_manager_interface),

    wl_buffer_interface: *@TypeOf(c.wl_buffer_interface),
    wl_callback_interface: *@TypeOf(c.wl_callback_interface),
    wl_data_device_interface: *@TypeOf(c.wl_data_device_interface),
    wl_data_offer_interface: *@TypeOf(c.wl_data_offer_interface),
    wl_data_source_interface: *@TypeOf(c.wl_data_source_interface),
    wl_keyboard_interface: *@TypeOf(c.wl_keyboard_interface),
    wl_output_interface: *@TypeOf(c.wl_output_interface),
    wl_pointer_interface: *@TypeOf(c.wl_pointer_interface),
    wl_region_interface: *@TypeOf(c.wl_region_interface),
    wl_registry_interface: *@TypeOf(c.wl_registry_interface),
    wl_seat_interface: *@TypeOf(c.wl_seat_interface),
    wl_shell_surface_interface: *@TypeOf(c.wl_shell_surface_interface),
    wl_shm_pool_interface: *@TypeOf(c.wl_shm_pool_interface),
    wl_subsurface_interface: *@TypeOf(c.wl_subsurface_interface),
    wl_surface_interface: *@TypeOf(c.wl_surface_interface),
    wl_touch_interface: *@TypeOf(c.wl_touch_interface),

    pub extern const xdg_wm_base_interface: @TypeOf(c.xdg_wm_base_interface);
    pub extern const zxdg_decoration_manager_v1_interface: @TypeOf(c.zxdg_decoration_manager_v1_interface);

    pub fn load() !LibWaylandClient {
        var lib: LibWaylandClient = undefined;
        lib.handle = std.DynLib.openZ("libwayland-client.so.0") catch return error.LibraryNotFound;
        inline for (@typeInfo(LibWaylandClient).Struct.fields[1..]) |field| {
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

const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);

pub const EventIterator = struct {
    events_mu: *std.Thread.RwLock,
    queue: *EventQueue,

    pub inline fn next(self: *EventIterator) ?Event {
        self.events_mu.lockShared();
        defer self.events_mu.unlockShared();
        return self.queue.readItem();
    }
};

const Interfaces = struct {
    wl_compositor: ?*c.wl_compositor = null,
    wl_subcompositor: ?*c.wl_subcompositor = null,
    wl_shm: ?*c.wl_shm = null,
    wl_output: ?*c.wl_output = null,
    wl_seat: ?*c.wl_seat = null,
    wl_data_device_manager: ?*c.wl_data_device_manager = null,
    xdg_wm_base: ?*c.xdg_wm_base = null,
    zxdg_decoration_manager_v1: ?*c.zxdg_decoration_manager_v1 = null,
    // wp_viewporter: *c.wp_viewporter,
    // zwp_relative_pointer_manager_v1: *c.zwp_relative_pointer_manager_v1,
    // zwp_pointer_constraints_v1: *c.zwp_pointer_constraints_v1,
    // zwp_idle_inhibit_manager_v1: *c.zwp_idle_inhibit_manager_v1,
    // xdg_activation_v1: *c.xdg_activation_v1,
};

fn Changable(comptime T: type, comptime uses_allocator: bool) type {
    return struct {
        current: T,
        last: if (uses_allocator) ?T else void,
        allocator: if (uses_allocator) std.mem.Allocator else void,
        changed: bool = false,

        const Self = @This();

        ///Initialize with a default value
        pub fn init(value: T, allocator: if (uses_allocator) std.mem.Allocator else void) !Self {
            if (uses_allocator) {
                return .{
                    .allocator = allocator,
                    .last = null,
                    .current = try allocator.dupeZ(std.meta.Child(T), value),
                };
            } else {
                return .{
                    .allocator = {},
                    .last = {},
                    .current = value,
                };
            }
        }

        /// Set a new value for the changable
        pub fn set(self: *Self, value: T) !void {
            if (uses_allocator) {
                //If we have a last value, free it
                if (self.last) |last_value| {
                    self.allocator.free(last_value);

                    self.last = null;
                }

                self.last = self.current;

                self.current = try self.allocator.dupeZ(std.meta.Child(T), value);
            } else {
                self.current = value;
            }
            self.changed = true;
        }

        /// Read the current value out, resetting the changed flag
        pub fn read(self: *Self) ?T {
            if (!self.changed)
                return null;

            self.changed = false;
            return self.current;
        }

        /// Free's the last allocation and resets the `last` value
        pub fn freeLast(self: *Self) void {
            if (uses_allocator) {
                if (self.last) |last_value| {
                    self.allocator.free(last_value);
                }

                self.last = null;
            }
        }

        pub fn deinit(self: *Self) void {
            if (uses_allocator) {
                if (self.last) |last_value| {
                    self.allocator.free(last_value);
                }

                self.allocator.free(self.current);
            }

            self.* = undefined;
        }
    };
}

/// Global state passed to things as the user data parameter, anything that needs to be accessed by callbacks should be in here.
const GlobalState = struct {
    //xkb
    libxkbcommon: LibXkbCommon,
    xkb_context: ?*c.xkb_context,
    keymap: ?*c.xkb_keymap,
    xkb_state: ?*c.xkb_state,
    compose_state: ?*c.xkb_compose_state,

    control_index: c.xkb_mod_index_t,
    alt_index: c.xkb_mod_index_t,
    shift_index: c.xkb_mod_index_t,
    super_index: c.xkb_mod_index_t,
    caps_lock_index: c.xkb_mod_index_t,
    num_lock_index: c.xkb_mod_index_t,

    // Wayland objects/state
    configured: bool,
    interfaces: Interfaces,
    surface: ?*c.struct_wl_surface,

    // Input/Event stuff
    keyboard: ?*c.wl_keyboard = null,
    pointer: ?*c.wl_pointer = null,
    events_mu: std.Thread.RwLock = .{},
    events: EventQueue,

    input_state: InputState,
    modifiers: KeyMods,

    //changables
    state_mu: std.Thread.RwLock = .{},
    window_size_mu: std.Thread.RwLock = .{},
    window_size: Changable(Size, false),
    swap_chain_update: std.Thread.ResetEvent = .{},

    // Mutable fields; written by the App.update thread, read from any
    swap_chain_mu: std.Thread.RwLock = .{},

    fn pushEvent(self: *GlobalState, event: Event) void {
        self.events_mu.lock();
        defer self.events_mu.unlock();

        self.events.writeItem(event) catch @panic("TODO");
    }
};

pub const Core = @This();

gpu_device: *gpu.Device,
surface: *gpu.Surface,
swap_chain: *gpu.SwapChain,
swap_chain_desc: gpu.SwapChain.Descriptor,

// Wayland objects/state
display: *c.struct_wl_display,
registry: *c.struct_wl_registry,
xdg_surface: *c.xdg_surface,
toplevel: *c.xdg_toplevel,
tag: [*]c_char,
decoration: *c.zxdg_toplevel_decoration_v1,
global_state: GlobalState,

// internal tracking state
app_update_thread_started: bool = false,
done: std.Thread.ResetEvent = .{},

//timings
frame: *Frequency,
input: *Frequency,

// changables
title: Changable([:0]const u8, true),
min_size: Changable(Size, false),
max_size: Changable(Size, false),

fn registryHandleGlobal(user_data: *GlobalState, registry: ?*c.struct_wl_registry, name: u32, interface_ptr: [*:0]const u8, version: u32) callconv(.C) void {
    const interface = std.mem.span(interface_ptr);

    log.debug("Got interface: {s}", .{interface});

    if (std.mem.eql(u8, "wl_compositor", interface)) {
        user_data.interfaces.wl_compositor = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_compositor_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
        log.debug("Bound wl_compositor :)", .{});
    } else if (std.mem.eql(u8, "wl_subcompositor", interface)) {
        user_data.interfaces.wl_subcompositor = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_subcompositor_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
        log.debug("Bound wl_subcompositor :)", .{});
    } else if (std.mem.eql(u8, "wl_shm", interface)) {
        user_data.interfaces.wl_shm = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_shm_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
        log.debug("Bound wl_shm :)", .{});
    } else if (std.mem.eql(u8, "wl_output", interface)) {
        user_data.interfaces.wl_output = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_output_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
        log.debug("Bound wl_output :)", .{});
        // } else if (std.mem.eql(u8, "wl_data_device_manager", interface)) {
        //     user_data.interfaces.wl_data_device_manager = @ptrCast(user_data.libwaylandclient.wl_registry_bind(
        //         registry,
        //         name,
        //         user_data.libwaylandclient.wl_data_device_manager_interface,
        //         @min(3, version),
        //     ) orelse @panic("uh idk how to proceed"));
        //     log.debug("Bound wl_data_device_manager :)", .{});
    } else if (std.mem.eql(u8, "xdg_wm_base", interface)) {
        user_data.interfaces.xdg_wm_base = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            &LibWaylandClient.xdg_wm_base_interface,
            // &LibWaylandClient._glfw_xdg_wm_base_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
        log.debug("Bound xdg_wm_base :)", .{});

        //TODO: handle return value
        _ = c.xdg_wm_base_add_listener(user_data.interfaces.xdg_wm_base, &.{ .ping = @ptrCast(&wmBaseHandlePing) }, user_data);
    } else if (std.mem.eql(u8, "zxdg_decoration_manager_v1", interface)) {
        user_data.interfaces.zxdg_decoration_manager_v1 = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            &LibWaylandClient.zxdg_decoration_manager_v1_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
        log.debug("Bound zxdg_decoration_manager_v1 :)", .{});
    } else if (std.mem.eql(u8, "wl_seat", interface)) {
        user_data.interfaces.wl_seat = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_seat_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
        log.debug("Bound wl_seat :)", .{});

        //TODO: handle return value
        _ = c.wl_seat_add_listener(user_data.interfaces.wl_seat, &.{
            .capabilities = @ptrCast(&seatHandleCapabilities),
            .name = @ptrCast(&seatHandleName), //ptrCast for the `[*:0]const u8`
        }, user_data);
    }
}

fn seatHandleName(user_data: *GlobalState, seat: ?*c.struct_wl_seat, name_ptr: [*:0]const u8) callconv(.C) void {
    _ = user_data;
    const name = std.mem.span(name_ptr);

    log.info("seat {*} has name {s}", .{ seat, name });
}

fn seatHandleCapabilities(user_data: *GlobalState, seat: ?*c.struct_wl_seat, caps: c.wl_seat_capability) callconv(.C) void {
    log.info("seat {*} has caps {d}", .{ seat, caps });

    if ((caps & c.WL_SEAT_CAPABILITY_KEYBOARD) != 0) {
        user_data.keyboard = c.wl_seat_get_keyboard(seat);

        //TODO: handle return value
        _ = c.wl_keyboard_add_listener(user_data.keyboard, &.{
            .keymap = @ptrCast(&keyboardHandleKeymap),
            .enter = @ptrCast(&keyboardHandleEnter),
            .leave = @ptrCast(&keyboardHandleLeave),
            .key = @ptrCast(&keyboardHandleKey),
            .modifiers = @ptrCast(&keyboardHandleModifiers),
            .repeat_info = @ptrCast(&keyboardHandleRepeatInfo),
        }, user_data);
    }

    if ((caps & c.WL_SEAT_CAPABILITY_TOUCH) != 0) {
        //TODO
    }

    if ((caps & c.WL_SEAT_CAPABILITY_POINTER) != 0) {
        user_data.pointer = c.wl_seat_get_pointer(seat);

        //TODO: handle return value
        _ = c.wl_pointer_add_listener(user_data.pointer, &.{
            .axis = @ptrCast(&handlePointerAxis),
            .axis_discrete = @ptrCast(&handlePointerAxisDiscrete),
            .axis_relative_direction = @ptrCast(&handlePointerAxisRelativeDirection),
            .axis_source = @ptrCast(&handlePointerAxisSource),
            .axis_stop = @ptrCast(&handlePointerAxisStop),
            .axis_value120 = @ptrCast(&handlePointerAxisValue120),
            .button = @ptrCast(&handlePointerButton),
            .enter = @ptrCast(&handlePointerEnter),
            .frame = @ptrCast(&handlePointerFrame),
            .leave = @ptrCast(&handlePointerLeave),
            .motion = @ptrCast(&handlePointerMotion),
        }, user_data);
    }

    // Delete keyboard if its no longer in the seat
    if (user_data.keyboard) |keyboard| {
        if ((caps & c.WL_SEAT_CAPABILITY_KEYBOARD) == 0) {
            c.wl_keyboard_destroy(keyboard);
            user_data.keyboard = null;
        }
    }

    if (user_data.pointer) |pointer| {
        if ((caps & c.WL_SEAT_CAPABILITY_POINTER) == 0) {
            c.wl_pointer_destroy(pointer);
            user_data.pointer = null;
        }
    }
}

fn handlePointerEnter(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, serial: u32, surface: ?*c.struct_wl_surface, fixed_x: c.wl_fixed_t, fixed_y: c.wl_fixed_t) callconv(.C) void {
    _ = fixed_x; // autofix
    _ = fixed_y; // autofix
    _ = user_data; // autofix
    _ = pointer; // autofix
    _ = serial; // autofix
    _ = surface; // autofix
}
fn handlePointerLeave(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, serial: u32, surface: ?*c.struct_wl_surface) callconv(.C) void {
    _ = user_data; // autofix
    _ = pointer; // autofix
    _ = serial; // autofix
    _ = surface; // autofix
}
fn handlePointerMotion(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, serial: u32, fixed_x: c.wl_fixed_t, fixed_y: c.wl_fixed_t) callconv(.C) void {
    _ = pointer; // autofix
    _ = serial; // autofix

    const x = c.wl_fixed_to_double(fixed_x);
    const y = c.wl_fixed_to_double(fixed_y);

    user_data.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
    user_data.input_state.mouse_position = .{ .x = x, .y = y };
}
fn handlePointerButton(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, serial: u32, time: u32, button: u32, state: u32) callconv(.C) void {
    _ = pointer; // autofix
    _ = serial; // autofix
    _ = time; // autofix

    const mouse_button: MouseButton = @enumFromInt(button - c.BTN_LEFT);
    const pressed = state == c.WL_POINTER_BUTTON_STATE_PRESSED;

    user_data.input_state.mouse_buttons.setValue(@intFromEnum(mouse_button), pressed);

    if (pressed) {
        user_data.pushEvent(Event{ .mouse_press = .{
            .button = mouse_button,
            .mods = user_data.modifiers,
            .pos = user_data.input_state.mouse_position,
        } });
    } else {
        user_data.pushEvent(Event{ .mouse_release = .{
            .button = mouse_button,
            .mods = user_data.modifiers,
            .pos = user_data.input_state.mouse_position,
        } });
    }
}
fn handlePointerAxis(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, time: u32, axis: u32, value: c.wl_fixed_t) callconv(.C) void {
    _ = user_data; // autofix
    _ = pointer; // autofix
    _ = time; // autofix
    _ = axis; // autofix
    _ = value; // autofix
}
fn handlePointerFrame(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer) callconv(.C) void {
    _ = user_data; // autofix
    _ = pointer; // autofix
}
fn handlePointerAxisSource(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, axis_source: u32) callconv(.C) void {
    _ = user_data; // autofix
    _ = pointer; // autofix
    _ = axis_source; // autofix
}
fn handlePointerAxisStop(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, time: u32, axis: u32) callconv(.C) void {
    _ = user_data; // autofix
    _ = pointer; // autofix
    _ = time; // autofix
    _ = axis; // autofix
}
fn handlePointerAxisDiscrete(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, axis: u32, discrete: i32) callconv(.C) void {
    _ = user_data; // autofix
    _ = pointer; // autofix
    _ = axis; // autofix
    _ = discrete; // autofix
}
fn handlePointerAxisValue120(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, axis: u32, value_120: i32) callconv(.C) void {
    _ = user_data; // autofix
    _ = pointer; // autofix
    _ = axis; // autofix
    _ = value_120; // autofix
}
fn handlePointerAxisRelativeDirection(user_data: *GlobalState, pointer: ?*c.struct_wl_pointer, axis: u32, direction: u32) callconv(.C) void {
    _ = user_data; // autofix
    _ = pointer; // autofix
    _ = axis; // autofix
    _ = direction; // autofix
}

fn keyboardHandleKeymap(user_data: *GlobalState, keyboard: ?*c.struct_wl_keyboard, format: u32, fd: i32, keymap_size: u32) callconv(.C) void {
    _ = keyboard;

    if (format != c.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1) {
        @panic("TODO");
    }

    const map_str = std.os.mmap(null, keymap_size, std.os.PROT.READ, std.os.MAP.SHARED, fd, 0) catch unreachable;

    const keymap = user_data.libxkbcommon.xkb_keymap_new_from_string(
        user_data.xkb_context,
        @alignCast(map_str), //align cast happening here, im sure its fine? TODO: figure out if this okay
        c.XKB_KEYMAP_FORMAT_TEXT_V1,
        0,
    ).?;
    log.debug("got keymap {*}", .{keymap});

    //Unmap the keymap
    std.os.munmap(map_str);
    //Close the fd
    std.os.close(fd);

    const state = user_data.libxkbcommon.xkb_state_new(keymap).?;
    // defer user_data.libxkbcommon.xkb_state_unref(state);

    //this chain hurts me. why must C be this way.
    const locale = std.os.getenv("LC_ALL") orelse std.os.getenv("LC_CTYPE") orelse std.os.getenv("LANG") orelse "C";

    var compose_table = user_data.libxkbcommon.xkb_compose_table_new_from_locale(
        user_data.xkb_context,
        locale,
        c.XKB_COMPOSE_COMPILE_NO_FLAGS,
    );

    //If creation failed, lets try the C locale
    if (compose_table == null)
        compose_table = user_data.libxkbcommon.xkb_compose_table_new_from_locale(
            user_data.xkb_context,
            "C",
            c.XKB_COMPOSE_COMPILE_NO_FLAGS,
        ).?;

    defer user_data.libxkbcommon.xkb_compose_table_unref(compose_table);

    user_data.keymap = keymap;
    user_data.xkb_state = state;
    user_data.compose_state = user_data.libxkbcommon.xkb_compose_state_new(compose_table, c.XKB_COMPOSE_STATE_NO_FLAGS).?;

    user_data.control_index = user_data.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Control");
    user_data.alt_index = user_data.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod1");
    user_data.shift_index = user_data.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Shift");
    user_data.super_index = user_data.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod4");
    user_data.caps_lock_index = user_data.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Lock");
    user_data.num_lock_index = user_data.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod2");
}
fn keyboardHandleEnter(user_data: *GlobalState, keyboard: ?*c.struct_wl_keyboard, serial: u32, surface: ?*c.struct_wl_surface, keys: [*c]c.struct_wl_array) callconv(.C) void {
    _ = keyboard;
    _ = serial;
    _ = surface;
    _ = keys;

    user_data.pushEvent(.focus_gained);
}
fn keyboardHandleLeave(user_data: *GlobalState, keyboard: ?*c.struct_wl_keyboard, serial: u32, surface: ?*c.struct_wl_surface) callconv(.C) void {
    _ = keyboard;
    _ = serial;
    _ = surface;

    user_data.pushEvent(.focus_lost);
}
fn keyboardHandleKey(user_data: *GlobalState, keyboard: ?*c.struct_wl_keyboard, serial: u32, time: u32, scancode: u32, state: u32) callconv(.C) void {
    _ = keyboard;
    _ = serial;
    _ = time;

    const key = toMachKey(scancode);
    const pressed = state == 1;

    user_data.input_state.keys.setValue(@intFromEnum(key), pressed);

    if (pressed) {
        user_data.pushEvent(Event{ .key_press = .{
            .key = key,
            .mods = user_data.modifiers,
        } });

        var keysyms: ?[*]c.xkb_keysym_t = undefined;
        //Get the keysym from the keycode (scancode + 8)
        if (user_data.libxkbcommon.xkb_state_key_get_syms(user_data.xkb_state, scancode + 8, &keysyms) == 1) {
            //Compose the keysym
            const keysym: c.xkb_keysym_t = composeSymbol(user_data, keysyms.?[0]);

            //Try to convert that keysym to a unicode codepoint
            if (Unicode.unicodeFromKeySym(keysym)) |codepoint| {
                user_data.pushEvent(Event{ .char_input = .{ .codepoint = codepoint } });
            }
        }
    } else {
        user_data.pushEvent(Event{ .key_release = .{
            .key = key,
            .mods = user_data.modifiers,
        } });
    }
}
fn keyboardHandleModifiers(user_data: *GlobalState, keyboard: ?*c.struct_wl_keyboard, serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32) callconv(.C) void {
    _ = keyboard;
    _ = serial;

    if (user_data.keymap == null)
        return;

    //TODO: handle this return value
    _ = user_data.libxkbcommon.xkb_state_update_mask(
        user_data.xkb_state.?,
        mods_depressed,
        mods_latched,
        mods_locked,
        0,
        0,
        group,
    );

    //Iterate over all the modifiers
    inline for (.{
        .{ user_data.alt_index, "alt" },
        .{ user_data.shift_index, "shift" },
        .{ user_data.super_index, "super" },
        .{ user_data.control_index, "control" },
        .{ user_data.num_lock_index, "num_lock" },
        .{ user_data.caps_lock_index, "caps_lock" },
    }) |key| {
        @field(user_data.modifiers, key[1]) = user_data.libxkbcommon.xkb_state_mod_index_is_active(
            user_data.xkb_state,
            key[0],
            c.XKB_STATE_MODS_EFFECTIVE,
        ) == 1;
    }
}
fn keyboardHandleRepeatInfo(user_data: *GlobalState, keyboard: ?*c.struct_wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
    _ = user_data;
    _ = keyboard;
    _ = rate;
    _ = delay;
}

fn composeSymbol(user_data: *GlobalState, sym: c.xkb_keysym_t) c.xkb_keysym_t {
    if (sym == c.XKB_KEY_NoSymbol or user_data.compose_state == null)
        return sym;

    if (user_data.libxkbcommon.xkb_compose_state_feed(user_data.compose_state, sym) != c.XKB_COMPOSE_FEED_ACCEPTED)
        return sym;

    return switch (user_data.libxkbcommon.xkb_compose_state_get_status(user_data.compose_state)) {
        c.XKB_COMPOSE_COMPOSED => user_data.libxkbcommon.xkb_compose_state_get_one_sym(user_data.compose_state),
        c.XKB_COMPOSE_COMPOSING, c.XKB_COMPOSE_CANCELLED => c.XKB_KEY_NoSymbol,
        else => sym,
    };
}

fn wmBaseHandlePing(user_data: *GlobalState, wm_base: ?*c.struct_xdg_wm_base, serial: u32) callconv(.C) void {
    _ = user_data;

    log.debug("Got wm base ping {*} with serial {d}", .{ wm_base, serial });

    c.xdg_wm_base_pong(wm_base, serial);
}

fn registryHandleGlobalRemove(user_data: *GlobalState, registry: ?*c.struct_wl_registry, name: u32) callconv(.C) void {
    _ = user_data;
    _ = registry;
    _ = name;
}

const registry_listener = c.wl_registry_listener{
    // ptrcast is for the [*:0] -> [*c] conversion, silly yes
    .global = @ptrCast(&registryHandleGlobal),
    // ptrcast is for the user_data param, which is guarenteed to be our type (and if its not, it should be caught by safety checks)
    .global_remove = @ptrCast(&registryHandleGlobalRemove),
};

fn xdgSurfaceHandleConfigure(user_data: *GlobalState, xdg_surface: ?*c.struct_xdg_surface, serial: u32) callconv(.C) void {
    c.xdg_surface_ack_configure(xdg_surface, serial);

    if (user_data.configured) {
        c.wl_surface_commit(user_data.surface);
    } else {
        log.debug("xdg surface configured", .{});
        user_data.configured = true;
    }

    user_data.state_mu.lock();
    defer user_data.state_mu.unlock();

    if (user_data.window_size.read()) |new_window_size| {
        setContentAreaOpaque(user_data, new_window_size);
    }
}

fn xdgToplevelHandleClose(user_data: *GlobalState, toplevel: ?*c.struct_xdg_toplevel) callconv(.C) void {
    _ = user_data;
    _ = toplevel;
}

fn xdgToplevelHandleConfigure(user_data: *GlobalState, toplevel: ?*c.struct_xdg_toplevel, width: i32, height: i32, states: [*c]c.struct_wl_array) callconv(.C) void {
    _ = toplevel;
    _ = states;

    log.debug("{d}/{d}", .{ width, height });

    if (width > 0 and height > 0) {
        user_data.state_mu.lock();
        defer user_data.state_mu.unlock();

        try user_data.window_size.set(.{ .width = @intCast(width), .height = @intCast(height) });
    }
}

fn setContentAreaOpaque(state: *GlobalState, new_size: Size) void {
    const region = c.wl_compositor_create_region(state.interfaces.wl_compositor) orelse return;

    c.wl_region_add(region, 0, 0, @intCast(new_size.width), @intCast(new_size.height));
    c.wl_surface_set_opaque_region(state.surface, region);
    c.wl_region_destroy(region);

    state.swap_chain_update.set();
}

// Called on the main thread
pub fn init(
    core: *Core,
    allocator: std.mem.Allocator,
    frame: *Frequency,
    input: *Frequency,
    options: Options,
) !void {
    core.global_state = .{
        .interfaces = .{},
        .configured = false,
        .surface = null,
        .events = EventQueue.init(allocator),
        .libxkbcommon = try LibXkbCommon.load(),
        .xkb_context = null,
        .keymap = null,
        .xkb_state = null,
        .compose_state = null,
        .alt_index = undefined,
        .shift_index = undefined,
        .super_index = undefined,
        .control_index = undefined,
        .caps_lock_index = undefined,
        .num_lock_index = undefined,
        .input_state = .{},
        .modifiers = .{
            .alt = false,
            .caps_lock = false,
            .control = false,
            .num_lock = false,
            .shift = false,
            .super = false,
        },
        .window_size = try @TypeOf(core.global_state.window_size).init(options.size, {}),
    };

    libwaylandclient = try LibWaylandClient.load();

    core.global_state.xkb_context = core.global_state.libxkbcommon.xkb_context_new(0).?;

    core.display = libwaylandclient.wl_display_connect(null) orelse return error.FailedToConnectToWaylandDisplay;

    const registry = c.wl_display_get_registry(core.display) orelse return error.FailedToGetDisplayRegistry;
    // TODO: handle error return value here
    _ = c.wl_registry_add_listener(registry, &registry_listener, &core.global_state);

    //Round trip to get all the registry objects
    _ = libwaylandclient.wl_display_roundtrip(core.display);

    //Round trip to get all initial output events
    _ = libwaylandclient.wl_display_roundtrip(core.display);

    core.global_state.surface = c.wl_compositor_create_surface(core.global_state.interfaces.wl_compositor) orelse return error.UnableToCreateSurface;
    log.debug("Got surface {*}", .{core.global_state.surface});

    var tag: [*:0]c_char = undefined;
    libwaylandclient.wl_proxy_set_tag(@ptrCast(core.global_state.surface), @ptrCast(&tag));

    {
        const region = c.wl_compositor_create_region(core.global_state.interfaces.wl_compositor) orelse return error.CouldntCreateWaylandRegtion;

        c.wl_region_add(
            region,
            0,
            0,
            @intCast(options.size.width),
            @intCast(options.size.height),
        );
        c.wl_surface_set_opaque_region(core.global_state.surface, region);
        c.wl_region_destroy(region);
    }

    const xdg_surface = c.xdg_wm_base_get_xdg_surface(core.global_state.interfaces.xdg_wm_base, core.global_state.surface) orelse return error.UnableToCreateXdgSurface;
    log.debug("Got xdg surface {*}", .{xdg_surface});

    const toplevel = c.xdg_surface_get_toplevel(xdg_surface) orelse return error.UnableToGetXdgTopLevel;
    log.debug("Got xdg toplevel {*}", .{toplevel});

    core.min_size = try @TypeOf(core.min_size).init(.{ .width = 0, .height = 0 }, {});
    core.max_size = try @TypeOf(core.max_size).init(.{ .width = 0, .height = 0 }, {});

    //TODO: handle this return value
    _ = c.xdg_surface_add_listener(xdg_surface, &.{ .configure = @ptrCast(&xdgSurfaceHandleConfigure) }, &core.global_state);

    //TODO: handle this return value
    _ = c.xdg_toplevel_add_listener(toplevel, &.{
        .configure = @ptrCast(&xdgToplevelHandleConfigure),
        .close = @ptrCast(&xdgToplevelHandleClose),
    }, &core.global_state);

    //Commit changes to surface
    c.wl_surface_commit(core.global_state.surface);

    while (libwaylandclient.wl_display_dispatch(core.display) != -1 and !core.global_state.configured) {
        // This space intentionally left blank
    }

    core.title = try @TypeOf(core.title).init(options.title, allocator);

    c.xdg_toplevel_set_title(toplevel, core.title.current);

    const decoration = c.zxdg_decoration_manager_v1_get_toplevel_decoration(
        core.global_state.interfaces.zxdg_decoration_manager_v1,
        toplevel,
    ) orelse return error.UnableToGetToplevelDecoration;
    log.debug("Got xdg toplevel decoration {*}", .{decoration});

    c.zxdg_toplevel_decoration_v1_set_mode(
        decoration,
        c.ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE,
    );

    //Commit changes to surface
    c.wl_surface_commit(core.global_state.surface);
    //TODO: handle return value
    _ = libwaylandclient.wl_display_roundtrip(core.display);

    const instance = gpu.createInstance(null) orelse {
        log.err("failed to create GPU instance", .{});
        std.process.exit(1);
    };
    const surface = instance.createSurface(&gpu.Surface.Descriptor{
        .next_in_chain = .{
            .from_wayland_surface = &.{
                .display = core.display,
                .surface = core.global_state.surface.?,
            },
        },
    });

    var response: RequestAdapterResponse = undefined;
    instance.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = surface,
        .power_preference = options.power_preference,
        .force_fallback_adapter = .false,
    }, &response, requestAdapterCallback);
    if (response.status != .success) {
        log.err("failed to create GPU adapter: {?s}", .{response.message});
        log.info("-> maybe try MACH_GPU_BACKEND=opengl ?", .{});
        std.process.exit(1);
    }

    // Print which adapter we are going to use.
    var props = std.mem.zeroes(gpu.Adapter.Properties);
    response.adapter.?.getProperties(&props);
    if (props.backend_type == .null) {
        log.err("no backend found for {s} adapter", .{props.adapter_type.name()});
        std.process.exit(1);
    }
    log.info("found {s} backend on {s} adapter: {s}, {s}\n", .{
        props.backend_type.name(),
        props.adapter_type.name(),
        props.name,
        props.driver_description,
    });

    // Create a device with default limits/features.
    const gpu_device = response.adapter.?.createDevice(&.{
        .next_in_chain = .{
            .dawn_toggles_descriptor = &gpu.dawn.TogglesDescriptor.init(.{
                .enabled_toggles = &[_][*:0]const u8{
                    "allow_unsafe_apis",
                },
            }),
        },

        .required_features_count = if (options.required_features) |v| @as(u32, @intCast(v.len)) else 0,
        .required_features = if (options.required_features) |v| @as(?[*]const gpu.FeatureName, v.ptr) else null,
        .required_limits = if (options.required_limits) |limits| @as(?*const gpu.RequiredLimits, &gpu.RequiredLimits{
            .limits = limits,
        }) else null,
        .device_lost_callback = &deviceLostCallback,
        .device_lost_userdata = null,
    }) orelse {
        log.err("failed to create GPU device\n", .{});
        std.process.exit(1);
    };
    gpu_device.setUncapturedErrorCallback({}, printUnhandledErrorCallback);

    const swap_chain_desc = gpu.SwapChain.Descriptor{
        .label = "main swap chain",
        .usage = options.swap_chain_usage,
        .format = .bgra8_unorm,
        .width = options.size.width,
        .height = options.size.height,
        .present_mode = .mailbox,
    };
    const swap_chain = gpu_device.createSwapChain(surface, &swap_chain_desc);

    mach_core.adapter = response.adapter.?;
    mach_core.device = gpu_device;
    mach_core.queue = gpu_device.getQueue();
    mach_core.swap_chain = swap_chain;
    mach_core.descriptor = swap_chain_desc;

    log.debug("DONE", .{});

    core.* = .{
        .display = core.display,
        .registry = registry,
        .tag = tag,
        .xdg_surface = xdg_surface,
        .toplevel = toplevel,
        .decoration = decoration,
        .gpu_device = gpu_device,
        .title = core.title,
        .min_size = core.min_size,
        .max_size = core.max_size,
        .frame = frame,
        .input = input,
        .global_state = core.global_state,
        .swap_chain = swap_chain,
        .swap_chain_desc = swap_chain_desc,
        .surface = surface,
    };
}

pub fn deinit(self: *Core) void {
    self.title.deinit();
}

// Called on the main thread
pub fn update(self: *Core, app: anytype) !bool {
    if (self.done.isSet()) return true;

    if (!self.app_update_thread_started) {
        self.app_update_thread_started = true;
        const thread = try std.Thread.spawn(.{}, appUpdateThread, .{ self, app });
        thread.detach();
    }

    //State updates
    {
        self.global_state.state_mu.lock();
        defer self.global_state.state_mu.unlock();

        var need_surface_commit: bool = false;

        // Check if we have a new title
        if (self.title.read()) |new_title| {
            defer self.title.freeLast();

            c.xdg_toplevel_set_title(self.toplevel, new_title);
        }

        // Check if we have a new min size
        if (self.min_size.read()) |new_min_size| {
            c.xdg_toplevel_set_min_size(self.toplevel, @intCast(new_min_size.width), @intCast(new_min_size.height));

            need_surface_commit = true;
        }

        // Check if we have a new max size
        if (self.max_size.read()) |new_max_size| {
            c.xdg_toplevel_set_max_size(self.toplevel, @intCast(new_max_size.width), @intCast(new_max_size.height));

            need_surface_commit = true;
        }

        if (need_surface_commit)
            c.wl_surface_commit(self.global_state.surface);
    }

    // while (libwaylandclient.wl_display_flush(self.display) == -1) {
    //     // if (std.os.errno() == std.os.E.AGAIN) {
    //     // log.err("flush error", .{});
    //     // return true;
    //     // }

    //     var pollfd = [_]std.os.pollfd{
    //         std.os.pollfd{
    //             .fd = libwaylandclient.wl_display_get_fd(self.display),
    //             .events = std.os.POLL.OUT,
    //             .revents = 0,
    //         },
    //     };

    //     while (try std.os.poll(&pollfd, -1) != 0) {
    //         // if (std.os.errno() == std.os.E.INTR or std.os.errno() == std.os.E.AGAIN) {
    //         // log.err("poll error", .{});
    //         // return true;
    //         // }
    //     }
    // }

    if (@hasDecl(std.meta.Child(@TypeOf(app)), "updateMainThread")) {
        if (app.updateMainThread() catch unreachable) {
            self.done.set();
            return true;
        }
    }

    _ = libwaylandclient.wl_display_roundtrip(self.display);

    self.input.tick();
    return false;
}

// Secondary app-update thread
pub fn appUpdateThread(self: *Core, app: anytype) void {
    // @panic("TODO: implement appUpdateThread for Wayland");

    self.frame.start() catch unreachable;
    while (true) {
        if (self.global_state.swap_chain_update.isSet()) { // blk: {
            self.global_state.swap_chain_update.reset();

            //TODO
            // if (self.current_vsync_mode != self.last_vsync_mode) {
            //     self.last_vsync_mode = self.current_vsync_mode;
            //     switch (self.current_vsync_mode) {
            //         .triple => self.frame.target = 2 * self.refresh_rate,
            //         else => self.frame.target = 0,
            //     }
            // }

            //TODO
            // if (self.current_size.width == 0 or self.current_size.height == 0) break :blk;

            self.global_state.swap_chain_mu.lock();
            defer self.global_state.swap_chain_mu.unlock();
            mach_core.swap_chain.release();
            self.swap_chain_desc.width = self.global_state.window_size.current.width;
            self.swap_chain_desc.height = self.global_state.window_size.current.height;
            self.swap_chain = self.gpu_device.createSwapChain(self.surface, &self.swap_chain_desc);

            mach_core.swap_chain = self.swap_chain;
            mach_core.descriptor = self.swap_chain_desc;

            self.global_state.pushEvent(.{
                .framebuffer_resize = .{
                    .width = self.global_state.window_size.current.width,
                    .height = self.global_state.window_size.current.height,
                },
            });
        }

        if (app.update() catch unreachable) {
            self.done.set();

            // Wake the main thread from any event handling, so there is not e.g. a one second delay
            // in exiting the application.
            // self.wakeMainThread();
            return;
        }
        self.gpu_device.tick();
        self.gpu_device.machWaitForCommandsToBeScheduled();

        self.frame.tick();
        if (self.frame.delay_ns != 0) std.time.sleep(self.frame.delay_ns);
    }
}

// May be called from any thread.
pub inline fn pollEvents(self: *Core) EventIterator {
    return EventIterator{ .events_mu = &self.global_state.events_mu, .queue = &self.global_state.events };
}

// May be called from any thread.
pub fn setTitle(self: *Core, title: [:0]const u8) void {
    self.global_state.state_mu.lock();
    defer self.global_state.state_mu.unlock();

    self.title.set(title) catch unreachable;
}

// May be called from any thread.
pub fn setDisplayMode(_: *Core, _: DisplayMode) void {
    @panic("TODO: implement setDisplayMode for Wayland");
}

// May be called from any thread.
pub fn displayMode(_: *Core) DisplayMode {
    @panic("TODO: implement displayMode for Wayland");
}

// May be called from any thread.
pub fn setBorder(_: *Core, _: bool) void {
    @panic("TODO: implement setBorder for Wayland");
}

// May be called from any thread.
pub fn border(_: *Core) bool {
    @panic("TODO: implement border for Wayland");
}

// May be called from any thread.
pub fn setHeadless(_: *Core, _: bool) void {
    @panic("TODO: implement setHeadless for Wayland");
}

// May be called from any thread.
pub fn headless(_: *Core) bool {
    @panic("TODO: implement headless for Wayland");
}

// May be called from any thread.
pub fn setVSync(_: *Core, _: VSyncMode) void {
    @panic("TODO: implement setVSync for Wayland");
}

// May be called from any thread.
pub fn vsync(_: *Core) VSyncMode {
    @panic("TODO: implement vsync for Wayland");
}

// May be called from any thread.
pub fn setSize(self: *Core, new_size: Size) void {
    self.global_state.window_size_mu.lock();
    defer self.global_state.window_size_mu.unlock();

    setContentAreaOpaque(&self.global_state, new_size);
    self.global_state.window_size.set(new_size) catch unreachable;
}

// May be called from any thread.
pub fn size(self: *Core) Size {
    self.state_mu.lock();
    defer self.state_mu.unlock();

    return self.window_size.current;
}

// May be called from any thread.
pub fn setSizeLimit(self: *Core, limits: SizeLimit) void {
    self.state_mu.lock();
    defer self.state_mu.unlock();

    if (limits.max.width) |width| if (width == 0) @panic("todo: what do we do here?");
    if (limits.max.height) |height| if (height == 0) @panic("todo: what do we do here?");
    if (limits.min.width) |width| if (width == 0) @panic("todo: what do we do here?");
    if (limits.min.height) |height| if (height == 0) @panic("todo: what do we do here?");

    //TODO: only set the changed one, not both!
    self.min_size.set(.{
        .width = limits.min.width orelse 0,
        .height = limits.min.height orelse 0,
    });
    self.max_size.set(.{
        .width = limits.max.width orelse 0,
        .height = limits.max.height orelse 0,
    });
}

// May be called from any thread.
pub fn sizeLimit(self: *Core) SizeLimit {
    self.state_mu.lock();
    defer self.state_mu.unlock();

    return SizeLimit{
        .max = .{
            .width = if (self.max_size.current.width == 0) null else self.max_size.current.width,
            .height = if (self.max_size.current.height == 0) null else self.max_size.current.height,
        },
        .min = .{
            .width = if (self.min_size.current.width == 0) null else self.min_size.current.width,
            .height = if (self.min_size.current.height == 0) null else self.min_size.current.height,
        },
    };
}

// May be called from any thread.
pub fn setCursorMode(_: *Core, _: CursorMode) void {
    @panic("TODO: implement setCursorMode for Wayland");
}

// May be called from any thread.
pub fn cursorMode(_: *Core) CursorMode {
    @panic("TODO: implement cursorMode for Wayland");
}

// May be called from any thread.
pub fn setCursorShape(_: *Core, _: CursorShape) void {
    @panic("TODO: implement setCursorShape for Wayland");
}

// May be called from any thread.
pub fn cursorShape(_: *Core) CursorShape {
    @panic("TODO: implement cursorShape for Wayland");
}

// May be called from any thread.
pub fn joystickPresent(_: *Core, _: Joystick) bool {
    @panic("TODO: implement joystickPresent for Wayland");
}

// May be called from any thread.
pub fn joystickName(_: *Core, _: Joystick) ?[:0]const u8 {
    @panic("TODO: implement joystickName for Wayland");
}

// May be called from any thread.
pub fn joystickButtons(_: *Core, _: Joystick) ?[]const bool {
    @panic("TODO: implement joystickButtons for Wayland");
}

// May be called from any thread.
pub fn joystickAxes(_: *Core, _: Joystick) ?[]const f32 {
    @panic("TODO: implement joystickAxes for Wayland");
}

// May be called from any thread.
pub fn keyPressed(self: *Core, key: Key) bool {
    self.input_state.isKeyPressed(key);
}

// May be called from any thread.
pub fn keyReleased(self: *Core, key: Key) bool {
    self.input_state.isKeyReleased(key);
}

// May be called from any thread.
pub fn mousePressed(self: *Core, button: MouseButton) bool {
    return self.input_state.isMouseButtonPressed(button);
}

// May be called from any thread.
pub fn mouseReleased(self: *Core, button: MouseButton) bool {
    return self.input_state.isMouseButtonReleased(button);
}

// May be called from any thread.
pub fn mousePosition(self: *Core) mach_core.Position {
    return self.mouse_pos;
}

// May be called from any thread.
pub inline fn outOfMemory(_: *Core) bool {
    @panic("TODO: implement outOfMemory for Wayland");
}

// TODO(important): expose device loss to users, this can happen especially in the web and on mobile
// devices. Users will need to re-upload all assets to the GPU in this event.
fn deviceLostCallback(reason: gpu.Device.LostReason, msg: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    _ = reason;
    log.err("mach: device lost: {s}", .{msg});
    @panic("mach: device lost");
}

fn toMachKey(key: u32) Key {
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
