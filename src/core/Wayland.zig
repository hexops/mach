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
        lib.handle = std.DynLib.open("libxkbcommon.so.0") catch return error.LibraryNotFound;
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
        lib.handle = std.DynLib.open("libwayland-client.so.0") catch return error.LibraryNotFound;
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
    queue: *EventQueue,

    pub inline fn next(self: *EventIterator) ?Event {
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

pub const Wayland = @This();

allocator: std.mem.Allocator,
core: *Core,

// Xkb
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
display: *c.struct_wl_display,
registry: *c.struct_wl_registry,
xdg_surface: *c.xdg_surface,
toplevel: *c.xdg_toplevel,
tag: [*]c_char,
decoration: *c.zxdg_toplevel_decoration_v1,
configured: bool,
interfaces: Interfaces,
surface: ?*c.struct_wl_surface,

// Input/Event stuff
keyboard: ?*c.wl_keyboard,
pointer: ?*c.wl_pointer,
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

fn pushEvent(wl: *Wayland, event: Event) void {
    wl.events.writeItem(event) catch @panic("TODO");
}

// Called on the main thread
pub fn init(wl: *Wayland, options: InitOptions) !void {
    libwaylandclient = try LibWaylandClient.load();
    wl.allocator = options.allocator;
    wl.core = @fieldParentPtr("platform", wl);
    wl.libxkbcommon = try LibXkbCommon.load();
    wl.keymap = null;
    wl.xkb_state = null;
    wl.compose_state = null;
    wl.configured = false;
    wl.interfaces = .{};
    wl.input_state = .{};
    wl.modifiers = .{
        .alt = false,
        .caps_lock = false,
        .control = false,
        .num_lock = false,
        .shift = false,
        .super = false,
    };
    wl.events = EventQueue.init(options.allocator);
    wl.display = libwaylandclient.wl_display_connect(null) orelse return error.FailedToConnectToWaylandDisplay;
    wl.xkb_context = wl.libxkbcommon.xkb_context_new(0).?;
    wl.registry = c.wl_display_get_registry(wl.display) orelse return error.FailedToGetDisplayRegistry;

    // TODO: handle error return value here
    _ = c.wl_registry_add_listener(wl.registry, &registry_listener, wl);

    //Round trip to get all the registry objects
    _ = libwaylandclient.wl_display_roundtrip(wl.display);

    //Round trip to get all initial output events
    _ = libwaylandclient.wl_display_roundtrip(wl.display);

    wl.surface = c.wl_compositor_create_surface(wl.interfaces.wl_compositor) orelse return error.UnableToCreateSurface;

    libwaylandclient.wl_proxy_set_tag(@ptrCast(wl.surface), @ptrCast(&wl.tag));

    {
        const region = c.wl_compositor_create_region(wl.interfaces.wl_compositor) orelse return error.CouldntCreateWaylandRegtion;

        c.wl_region_add(
            region,
            0,
            0,
            @intCast(options.size.width),
            @intCast(options.size.height),
        );
        c.wl_surface_set_opaque_region(wl.surface, region);
        c.wl_region_destroy(region);
    }

    wl.xdg_surface = c.xdg_wm_base_get_xdg_surface(wl.interfaces.xdg_wm_base, wl.surface) orelse return error.UnableToCreateXdgSurface;
    wl.toplevel = c.xdg_surface_get_toplevel(wl.xdg_surface) orelse return error.UnableToGetXdgTopLevel;
    wl.title = try options.allocator.dupeZ(u8, options.title);
    wl.size = options.size;

    // TODO: handle this return value
    _ = c.xdg_surface_add_listener(wl.xdg_surface, &.{ .configure = @ptrCast(&xdgSurfaceHandleConfigure) }, wl);

    // TODO: handle this return value
    _ = c.xdg_toplevel_add_listener(wl.toplevel, &.{
        .configure = @ptrCast(&xdgToplevelHandleConfigure),
        .close = @ptrCast(&xdgToplevelHandleClose),
    }, wl);

    // Commit changes to surface
    c.wl_surface_commit(wl.surface);

    while (libwaylandclient.wl_display_dispatch(wl.display) != -1 and !wl.configured) {
        // This space intentionally left blank
    }

    c.xdg_toplevel_set_title(wl.toplevel, wl.title);

    wl.decoration = c.zxdg_decoration_manager_v1_get_toplevel_decoration(
        wl.interfaces.zxdg_decoration_manager_v1,
        wl.toplevel,
    ) orelse return error.UnableToGetToplevelDecoration;

    c.zxdg_toplevel_decoration_v1_set_mode(wl.decoration, c.ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE);

    // Commit changes to surface
    c.wl_surface_commit(wl.surface);
    // TODO: handle return value
    _ = libwaylandclient.wl_display_roundtrip(wl.display);

    // TODO: remove allocation
    const wayland_surface_descriptor = try options.allocator.create(gpu.Surface.DescriptorFromWaylandSurface);
    wayland_surface_descriptor.* = .{ .display = wl.display, .surface = wl.surface.? };
    wl.surface_descriptor = .{ .next_in_chain = .{ .from_wayland_surface = wayland_surface_descriptor } };
    wl.border = options.border;
    wl.headless = options.headless;
    wl.refresh_rate = 60; // TODO
}

pub fn deinit(wl: *Wayland) void {
    wl.allocator.free(wl.title);
    wl.allocator.destroy(wl.surface_descriptor.next_in_chain.from_wayland_surface);
}

// Called on the main thread
pub fn update(wl: *Wayland) !void {
    // while (libwaylandclient.wl_display_flush(wl.display) == -1) {
    //     // if (std.posix.errno() == std.posix.E.AGAIN) {
    //     // log.err("flush error", .{});
    //     // return true;
    //     // }

    //     var pollfd = [_]std.posix.pollfd{
    //         std.posix.pollfd{
    //             .fd = libwaylandclient.wl_display_get_fd(wl.display),
    //             .events = std.posix.POLL.OUT,
    //             .revents = 0,
    //         },
    //     };

    //     while (try std.posix.poll(&pollfd, -1) != 0) {
    //         // if (std.posix.errno() == std.posix.E.INTR or std.posix.errno() == std.posix.E.AGAIN) {
    //         // log.err("poll error", .{});
    //         // return true;
    //         // }
    //     }
    // }

    _ = libwaylandclient.wl_display_roundtrip(wl.display);

    wl.core.input.tick();
}

// May be called from any thread.
pub inline fn pollEvents(wl: *Wayland) EventIterator {
    return EventIterator{ .queue = &wl.events };
}

// May be called from any thread.
pub fn setTitle(wl: *Wayland, title: [:0]const u8) void {
    wl.title = @ptrCast(wl.allocator.realloc(wl.title, title.len + 1) catch @panic("TODO"));
    @memcpy(wl.title, title);
    c.xdg_toplevel_set_title(wl.toplevel, title);
}

// May be called from any thread.
pub fn setDisplayMode(_: *Wayland, _: DisplayMode) void {
    @panic("TODO: implement setDisplayMode for Wayland");
}

// May be called from any thread.
pub fn setBorder(_: *Wayland, _: bool) void {
    @panic("TODO: implement setBorder for Wayland");
}

// May be called from any thread.
pub fn setHeadless(_: *Wayland, _: bool) void {
    @panic("TODO: implement setHeadless for Wayland");
}

// May be called from any thread.
pub fn setVSync(_: *Wayland, _: VSyncMode) void {
    @panic("TODO: implement setVSync for Wayland");
}

// May be called from any thread.
pub fn setSize(wl: *Wayland, new_size: Size) void {
    wl.size.lock();
    defer wl.size.unlock();

    setContentAreaOpaque(&wl, new_size);
    wl.size.set(new_size) catch unreachable;
}

// May be called from any thread.
pub fn size(wl: *Wayland) Size {
    return wl.size;
}

// May be called from any thread.
pub fn setCursorMode(_: *Wayland, _: CursorMode) void {
    @panic("TODO: implement setCursorMode for Wayland");
}

// May be called from any thread.
pub fn setCursorShape(_: *Wayland, _: CursorShape) void {
    @panic("TODO: implement setCursorShape for Wayland");
}

// May be called from any thread.
pub fn joystickPresent(_: *Wayland, _: Joystick) bool {
    @panic("TODO: implement joystickPresent for Wayland");
}

// May be called from any thread.
pub fn joystickName(_: *Wayland, _: Joystick) ?[:0]const u8 {
    @panic("TODO: implement joystickName for Wayland");
}

// May be called from any thread.
pub fn joystickButtons(_: *Wayland, _: Joystick) ?[]const bool {
    @panic("TODO: implement joystickButtons for Wayland");
}

// May be called from any thread.
pub fn joystickAxes(_: *Wayland, _: Joystick) ?[]const f32 {
    @panic("TODO: implement joystickAxes for Wayland");
}

// May be called from any thread.
pub fn keyPressed(wl: *Wayland, key: Key) bool {
    wl.input_state.isKeyPressed(key);
}

// May be called from any thread.
pub fn keyReleased(wl: *Wayland, key: Key) bool {
    wl.input_state.isKeyReleased(key);
}

// May be called from any thread.
pub fn mousePressed(wl: *Wayland, button: MouseButton) bool {
    return wl.input_state.isMouseButtonPressed(button);
}

// May be called from any thread.
pub fn mouseReleased(wl: *Wayland, button: MouseButton) bool {
    return wl.input_state.isMouseButtonReleased(button);
}

// May be called from any thread.
pub fn mousePosition(wl: *Wayland) Position {
    return wl.mouse_pos;
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

fn registryHandleGlobal(wl: *Wayland, registry: ?*c.struct_wl_registry, name: u32, interface_ptr: [*:0]const u8, version: u32) callconv(.C) void {
    const interface = std.mem.span(interface_ptr);

    if (std.mem.eql(u8, "wl_compositor", interface)) {
        wl.interfaces.wl_compositor = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_compositor_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
    } else if (std.mem.eql(u8, "wl_subcompositor", interface)) {
        wl.interfaces.wl_subcompositor = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_subcompositor_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
    } else if (std.mem.eql(u8, "wl_shm", interface)) {
        wl.interfaces.wl_shm = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_shm_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
    } else if (std.mem.eql(u8, "wl_output", interface)) {
        wl.interfaces.wl_output = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_output_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
        // } else if (std.mem.eql(u8, "wl_data_device_manager", interface)) {
        //     wl.interfaces.wl_data_device_manager = @ptrCast(wl.libwaylandclient.wl_registry_bind(
        //         registry,
        //         name,
        //         wl.libwaylandclient.wl_data_device_manager_interface,
        //         @min(3, version),
        //     ) orelse @panic("uh idk how to proceed"));
    } else if (std.mem.eql(u8, "xdg_wm_base", interface)) {
        wl.interfaces.xdg_wm_base = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            &LibWaylandClient.xdg_wm_base_interface,
            // &LibWaylandClient._glfw_xdg_wm_base_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));

        // TODO: handle return value
        _ = c.xdg_wm_base_add_listener(wl.interfaces.xdg_wm_base, &.{ .ping = @ptrCast(&wmBaseHandlePing) }, wl);
    } else if (std.mem.eql(u8, "zxdg_decoration_manager_v1", interface)) {
        wl.interfaces.zxdg_decoration_manager_v1 = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            &LibWaylandClient.zxdg_decoration_manager_v1_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));
    } else if (std.mem.eql(u8, "wl_seat", interface)) {
        wl.interfaces.wl_seat = @ptrCast(c.wl_registry_bind(
            registry,
            name,
            libwaylandclient.wl_seat_interface,
            @min(3, version),
        ) orelse @panic("uh idk how to proceed"));

        // TODO: handle return value
        _ = c.wl_seat_add_listener(wl.interfaces.wl_seat, &.{
            .capabilities = @ptrCast(&seatHandleCapabilities),
            .name = @ptrCast(&seatHandleName), //ptrCast for the `[*:0]const u8`
        }, wl);
    }
}

fn seatHandleName(wl: *Wayland, seat: ?*c.struct_wl_seat, name_ptr: [*:0]const u8) callconv(.C) void {
    _ = wl;
    _ = seat;
    _ = name_ptr;
}

fn seatHandleCapabilities(wl: *Wayland, seat: ?*c.struct_wl_seat, caps: c.wl_seat_capability) callconv(.C) void {
    if ((caps & c.WL_SEAT_CAPABILITY_KEYBOARD) != 0) {
        wl.keyboard = c.wl_seat_get_keyboard(seat);

        // TODO: handle return value
        _ = c.wl_keyboard_add_listener(wl.keyboard, &.{
            .keymap = @ptrCast(&keyboardHandleKeymap),
            .enter = @ptrCast(&keyboardHandleEnter),
            .leave = @ptrCast(&keyboardHandleLeave),
            .key = @ptrCast(&keyboardHandleKey),
            .modifiers = @ptrCast(&keyboardHandleModifiers),
            .repeat_info = @ptrCast(&keyboardHandleRepeatInfo),
        }, wl);
    }

    if ((caps & c.WL_SEAT_CAPABILITY_TOUCH) != 0) {
        // TODO
    }

    if ((caps & c.WL_SEAT_CAPABILITY_POINTER) != 0) {
        wl.pointer = c.wl_seat_get_pointer(seat);

        // TODO: handle return value
        _ = c.wl_pointer_add_listener(wl.pointer, &.{
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
        }, wl);
    }

    // Delete keyboard if its no longer in the seat
    if (wl.keyboard) |keyboard| {
        if ((caps & c.WL_SEAT_CAPABILITY_KEYBOARD) == 0) {
            c.wl_keyboard_destroy(keyboard);
            wl.keyboard = null;
        }
    }

    if (wl.pointer) |pointer| {
        if ((caps & c.WL_SEAT_CAPABILITY_POINTER) == 0) {
            c.wl_pointer_destroy(pointer);
            wl.pointer = null;
        }
    }
}

fn handlePointerEnter(wl: *Wayland, pointer: ?*c.struct_wl_pointer, serial: u32, surface: ?*c.struct_wl_surface, fixed_x: c.wl_fixed_t, fixed_y: c.wl_fixed_t) callconv(.C) void {
    _ = fixed_x;
    _ = fixed_y;
    _ = wl;
    _ = pointer;
    _ = serial;
    _ = surface;
}

fn handlePointerLeave(wl: *Wayland, pointer: ?*c.struct_wl_pointer, serial: u32, surface: ?*c.struct_wl_surface) callconv(.C) void {
    _ = wl;
    _ = pointer;
    _ = serial;
    _ = surface;
}

fn handlePointerMotion(wl: *Wayland, pointer: ?*c.struct_wl_pointer, serial: u32, fixed_x: c.wl_fixed_t, fixed_y: c.wl_fixed_t) callconv(.C) void {
    _ = pointer;
    _ = serial;

    const x = c.wl_fixed_to_double(fixed_x);
    const y = c.wl_fixed_to_double(fixed_y);

    wl.pushEvent(.{ .mouse_motion = .{ .pos = .{ .x = x, .y = y } } });
    wl.input_state.mouse_position = .{ .x = x, .y = y };
}

fn handlePointerButton(wl: *Wayland, pointer: ?*c.struct_wl_pointer, serial: u32, time: u32, button: u32, state: u32) callconv(.C) void {
    _ = pointer;
    _ = serial;
    _ = time;

    const mouse_button: MouseButton = @enumFromInt(button - c.BTN_LEFT);
    const pressed = state == c.WL_POINTER_BUTTON_STATE_PRESSED;

    wl.input_state.mouse_buttons.setValue(@intFromEnum(mouse_button), pressed);

    if (pressed) {
        wl.pushEvent(Event{ .mouse_press = .{
            .button = mouse_button,
            .mods = wl.modifiers,
            .pos = wl.input_state.mouse_position,
        } });
    } else {
        wl.pushEvent(Event{ .mouse_release = .{
            .button = mouse_button,
            .mods = wl.modifiers,
            .pos = wl.input_state.mouse_position,
        } });
    }
}

fn handlePointerAxis(wl: *Wayland, pointer: ?*c.struct_wl_pointer, time: u32, axis: u32, value: c.wl_fixed_t) callconv(.C) void {
    _ = wl;
    _ = pointer;
    _ = time;
    _ = axis;
    _ = value;
}

fn handlePointerFrame(wl: *Wayland, pointer: ?*c.struct_wl_pointer) callconv(.C) void {
    _ = wl;
    _ = pointer;
}

fn handlePointerAxisSource(wl: *Wayland, pointer: ?*c.struct_wl_pointer, axis_source: u32) callconv(.C) void {
    _ = wl;
    _ = pointer;
    _ = axis_source;
}

fn handlePointerAxisStop(wl: *Wayland, pointer: ?*c.struct_wl_pointer, time: u32, axis: u32) callconv(.C) void {
    _ = wl;
    _ = pointer;
    _ = time;
    _ = axis;
}

fn handlePointerAxisDiscrete(wl: *Wayland, pointer: ?*c.struct_wl_pointer, axis: u32, discrete: i32) callconv(.C) void {
    _ = wl;
    _ = pointer;
    _ = axis;
    _ = discrete;
}

fn handlePointerAxisValue120(wl: *Wayland, pointer: ?*c.struct_wl_pointer, axis: u32, value_120: i32) callconv(.C) void {
    _ = wl;
    _ = pointer;
    _ = axis;
    _ = value_120;
}

fn handlePointerAxisRelativeDirection(wl: *Wayland, pointer: ?*c.struct_wl_pointer, axis: u32, direction: u32) callconv(.C) void {
    _ = wl;
    _ = pointer;
    _ = axis;
    _ = direction;
}

fn keyboardHandleKeymap(wl: *Wayland, keyboard: ?*c.struct_wl_keyboard, format: u32, fd: i32, keymap_size: u32) callconv(.C) void {
    _ = keyboard;

    if (format != c.WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1) {
        @panic("TODO");
    }

    const map_str = std.posix.mmap(null, keymap_size, std.posix.PROT.READ, .{ .TYPE = .SHARED }, fd, 0) catch unreachable;

    const keymap = wl.libxkbcommon.xkb_keymap_new_from_string(
        wl.xkb_context,
        @alignCast(map_str), //align cast happening here, im sure its fine? TODO: figure out if this okay
        c.XKB_KEYMAP_FORMAT_TEXT_V1,
        0,
    ).?;

    //Unmap the keymap
    std.posix.munmap(map_str);
    //Close the fd
    std.posix.close(fd);

    const state = wl.libxkbcommon.xkb_state_new(keymap).?;
    // defer wl.libxkbcommon.xkb_state_unref(state);

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

    wl.control_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Control");
    wl.alt_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod1");
    wl.shift_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Shift");
    wl.super_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod4");
    wl.caps_lock_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Lock");
    wl.num_lock_index = wl.libxkbcommon.xkb_keymap_mod_get_index(keymap, "Mod2");
}

fn keyboardHandleEnter(wl: *Wayland, keyboard: ?*c.struct_wl_keyboard, serial: u32, surface: ?*c.struct_wl_surface, keys: [*c]c.struct_wl_array) callconv(.C) void {
    _ = keyboard;
    _ = serial;
    _ = surface;
    _ = keys;

    wl.pushEvent(.focus_gained);
}

fn keyboardHandleLeave(wl: *Wayland, keyboard: ?*c.struct_wl_keyboard, serial: u32, surface: ?*c.struct_wl_surface) callconv(.C) void {
    _ = keyboard;
    _ = serial;
    _ = surface;

    wl.pushEvent(.focus_lost);
}

fn keyboardHandleKey(wl: *Wayland, keyboard: ?*c.struct_wl_keyboard, serial: u32, time: u32, scancode: u32, state: u32) callconv(.C) void {
    _ = keyboard;
    _ = serial;
    _ = time;

    const key = toMachKey(scancode);
    const pressed = state == 1;

    wl.input_state.keys.setValue(@intFromEnum(key), pressed);

    if (pressed) {
        wl.pushEvent(Event{ .key_press = .{
            .key = key,
            .mods = wl.modifiers,
        } });

        var keysyms: ?[*]c.xkb_keysym_t = undefined;
        //Get the keysym from the keycode (scancode + 8)
        if (wl.libxkbcommon.xkb_state_key_get_syms(wl.xkb_state, scancode + 8, &keysyms) == 1) {
            //Compose the keysym
            const keysym: c.xkb_keysym_t = composeSymbol(wl, keysyms.?[0]);

            //Try to convert that keysym to a unicode codepoint
            if (unicode.unicodeFromKeySym(keysym)) |codepoint| {
                wl.pushEvent(Event{ .char_input = .{ .codepoint = codepoint } });
            }
        }
    } else {
        wl.pushEvent(Event{ .key_release = .{
            .key = key,
            .mods = wl.modifiers,
        } });
    }
}

fn keyboardHandleModifiers(wl: *Wayland, keyboard: ?*c.struct_wl_keyboard, serial: u32, mods_depressed: u32, mods_latched: u32, mods_locked: u32, group: u32) callconv(.C) void {
    _ = keyboard;
    _ = serial;

    if (wl.keymap == null)
        return;

    // TODO: handle this return value
    _ = wl.libxkbcommon.xkb_state_update_mask(
        wl.xkb_state.?,
        mods_depressed,
        mods_latched,
        mods_locked,
        0,
        0,
        group,
    );

    //Iterate over all the modifiers
    inline for (.{
        .{ wl.alt_index, "alt" },
        .{ wl.shift_index, "shift" },
        .{ wl.super_index, "super" },
        .{ wl.control_index, "control" },
        .{ wl.num_lock_index, "num_lock" },
        .{ wl.caps_lock_index, "caps_lock" },
    }) |key| {
        @field(wl.modifiers, key[1]) = wl.libxkbcommon.xkb_state_mod_index_is_active(
            wl.xkb_state,
            key[0],
            c.XKB_STATE_MODS_EFFECTIVE,
        ) == 1;
    }
}

fn keyboardHandleRepeatInfo(wl: *Wayland, keyboard: ?*c.struct_wl_keyboard, rate: i32, delay: i32) callconv(.C) void {
    _ = wl;
    _ = keyboard;
    _ = rate;
    _ = delay;
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

fn wmBaseHandlePing(wl: *Wayland, wm_base: ?*c.struct_xdg_wm_base, serial: u32) callconv(.C) void {
    _ = wl;
    c.xdg_wm_base_pong(wm_base, serial);
}

fn registryHandleGlobalRemove(wl: *Wayland, registry: ?*c.struct_wl_registry, name: u32) callconv(.C) void {
    _ = wl;
    _ = registry;
    _ = name;
}

const registry_listener = c.wl_registry_listener{
    // ptrcast is for the [*:0] -> [*c] conversion, silly yes
    .global = @ptrCast(&registryHandleGlobal),
    // ptrcast is for the wl param, which is guarenteed to be our type (and if its not, it should be caught by safety checks)
    .global_remove = @ptrCast(&registryHandleGlobalRemove),
};

fn xdgSurfaceHandleConfigure(wl: *Wayland, xdg_surface: ?*c.struct_xdg_surface, serial: u32) callconv(.C) void {
    c.xdg_surface_ack_configure(xdg_surface, serial);

    if (wl.configured) {
        c.wl_surface_commit(wl.surface);
    } else {
        wl.configured = true;
    }

    setContentAreaOpaque(wl, wl.size);
}

fn xdgToplevelHandleClose(wl: *Wayland, toplevel: ?*c.struct_xdg_toplevel) callconv(.C) void {
    _ = wl;
    _ = toplevel;
}

fn xdgToplevelHandleConfigure(wl: *Wayland, toplevel: ?*c.struct_xdg_toplevel, width: i32, height: i32, states: [*c]c.struct_wl_array) callconv(.C) void {
    _ = toplevel;
    _ = states;

    if (width > 0 and height > 0) {
        wl.size = .{ .width = @intCast(width), .height = @intCast(height) };
    }
}

fn setContentAreaOpaque(wl: *Wayland, new_size: Size) void {
    const region = c.wl_compositor_create_region(wl.interfaces.wl_compositor) orelse return;

    c.wl_region_add(region, 0, 0, @intCast(new_size.width), @intCast(new_size.height));
    c.wl_surface_set_opaque_region(wl.surface, region);
    c.wl_region_destroy(region);

    wl.core.swap_chain_update.set();
}
