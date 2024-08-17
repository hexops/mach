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
// modifiers: KeyMods,

title: [:0]const u8,
display_mode: DisplayMode,
vsync_mode: VSyncMode,
cursor_mode: CursorMode,
cursor_shape: CursorShape,
border: bool,
headless: bool,
refresh_rate: u32,
size: Size,
surface_descriptor: gpu.Surface.Descriptor,
window: ?*objc.appkit.ns.Window,

pub fn run(comptime on_each_update: anytype, args_tuple: std.meta.ArgsTuple(@TypeOf(on_each_update))) noreturn {
    objc.avf_audio.avaudio.init();
    objc.foundation.ns.init();
    objc.metal.mtl.init();
    objc.quartz_core.ca.init();
    objc.appkit.ns.init();

    const Args = @TypeOf(args_tuple);
    const args_bytes = std.mem.toBytes(args_tuple);
    const Literal = objc.foundation.ns.BlockLiteral(@TypeOf(args_bytes));
    const Helper = struct {
        extern const _NSConcreteStackBlock: *anyopaque;
        extern "System" fn dispatch_async(queue: *anyopaque, block: *Literal) void;
        extern "System" var _dispatch_main_q: anyopaque;
        extern fn _Block_copy(*const Literal) *Literal;
        extern fn _Block_release(*const Literal) void;

        pub fn cCallback(literal: *Literal) callconv(.C) void {
            const args: *Args = @ptrCast(&literal.context);
            if (@call(.auto, on_each_update, args.*) catch false) {
                dispatch_async(&_dispatch_main_q, literal);
            } else {
                _Block_release(literal);
            }
        }
    };
    const descriptor = objc.foundation.ns.BlockDescriptor{ .reserved = 0, .size = @sizeOf(Literal) };
    const block = Literal{ .isa = Helper._NSConcreteStackBlock, .flags = 0, .reserved = 0, .invoke = @ptrCast(&Helper.cCallback), .descriptor = &descriptor, .context = args_bytes };

    // `NSApplicationMain()` and `UIApplicationMain()` never return, so there's no point in trying to add any kind of cleanup work here.
    const ns_app = objc.appkit.ns.Application.sharedApplication();
    const delegate = objc.mach.AppDelegate.allocInit();
    delegate.setRunBlock(Helper._Block_copy(&block));
    ns_app.setDelegate(@ptrCast(delegate));
    _ = objc.appkit.ns.applicationMain(0, undefined);

    unreachable;
    // TODO: support UIKit.
}

// Called on the main thread
pub fn init(darwin: *Darwin, options: InitOptions) !void {
    var surface_descriptor = gpu.Surface.Descriptor{};

    // TODO: support UIKit.
    var window: ?*objc.appkit.ns.Window = null;
    if (!options.headless) {
        const metal_descriptor = try options.allocator.create(gpu.Surface.DescriptorFromMetalLayer);
        const layer = objc.quartz_core.ca.MetalLayer.new();
        defer layer.release();
        metal_descriptor.* = .{
            .layer = layer,
        };
        surface_descriptor.next_in_chain = .{ .from_metal_layer = metal_descriptor };

        const screen = objc.appkit.ns.Screen.mainScreen();
        const rect = objc.core_graphics.cg.Rect{ // TODO: use a meaningful rect
            .origin = .{ .x = 100, .y = 100 },
            .size = .{ .width = 480, .height = 270 },
        };
        const window_style =
            (if (options.display_mode == .fullscreen) objc.appkit.ns.WindowStyleMaskFullScreen else 0) |
            (if (options.display_mode == .windowed) objc.appkit.ns.WindowStyleMaskTitled else 0) |
            (if (options.display_mode == .windowed) objc.appkit.ns.WindowStyleMaskClosable else 0) |
            (if (options.display_mode == .windowed) objc.appkit.ns.WindowStyleMaskMiniaturizable else 0) |
            (if (options.display_mode == .windowed) objc.appkit.ns.WindowStyleMaskResizable else 0);
        window = objc.appkit.ns.Window.alloc().initWithContentRect_styleMask_backing_defer_screen(rect, window_style, objc.appkit.ns.BackingStoreBuffered, true, screen);
        window.?.setReleasedWhenClosed(false);
        if (window.?.contentView()) |view| {
            view.setLayer(@ptrCast(layer));
        }
        window.?.setIsVisible(true);
        window.?.makeKeyAndOrderFront(null);
    }

    var events = EventQueue.init(options.allocator);
    try events.ensureTotalCapacity(2048);

    darwin.* = .{
        .allocator = options.allocator,
        .core = @fieldParentPtr("platform", darwin),
        .events = events,
        .input_state = .{},
        .title = options.title,
        .display_mode = options.display_mode,
        .vsync_mode = .none,
        .cursor_mode = .normal,
        .cursor_shape =  .arrow,
        .border = options.border,
        .headless = options.headless,
        .refresh_rate = 60, // TODO: set to something meaningful
        .size = options.size,
        .surface_descriptor = surface_descriptor,
        .window = window,
    };
}

pub fn deinit(darwin: *Darwin) void {
    if (darwin.window) |w| @as(*objc.foundation.ns.ObjectProtocol, @ptrCast(w)).release();
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
