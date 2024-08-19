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
window: ?*objc.app_kit.Window,

pub fn run(comptime on_each_update_fn: anytype, args_tuple: std.meta.ArgsTuple(@TypeOf(on_each_update_fn))) noreturn {
    const Args = @TypeOf(args_tuple);
    const args_bytes = std.mem.asBytes(&args_tuple);
    const ArgsBytes = @TypeOf(args_bytes.*);
    const Helper = struct {
        // TODO: port libdispatch and use it instead of doing this directly.
        extern "System" fn dispatch_async(queue: *anyopaque, block: *objc.foundation.Block(fn () void)) void;
        extern "System" var _dispatch_main_q: anyopaque;
        pub fn cCallback(block: *objc.foundation.BlockLiteral(ArgsBytes)) callconv(.C) void {
            const args: *Args = @ptrCast(&block.context);
            if (@call(.auto, on_each_update_fn, args.*) catch false) {
                dispatch_async(&_dispatch_main_q, block.asBlockWithSignature(fn () void));
            } else {
                // We copied the block when we called `setRunBlock()`, so we release it here when the looping will end.
                block.release();
            }
        }
    };
    var block_literal = objc.foundation.stackBlockLiteral(Helper.cCallback, args_bytes.*, null, null);

    // `NSApplicationMain()` and `UIApplicationMain()` never return, so there's no point in trying to add any kind of cleanup work here.
    const ns_app = objc.app_kit.Application.sharedApplication();
    const delegate = objc.mach.AppDelegate.allocInit();
    delegate.setRunBlock(block_literal.asBlock().copy());
    ns_app.setDelegate(@ptrCast(delegate));
    _ = objc.app_kit.applicationMain(0, undefined);

    unreachable;
    // TODO: support UIKit.
}

// Called on the main thread
pub fn init(darwin: *Darwin, options: InitOptions) !void {
    var surface_descriptor = gpu.Surface.Descriptor{};

    // TODO: support UIKit.
    var window: ?*objc.app_kit.Window = null;
    if (!options.headless) {
        const metal_descriptor = try options.allocator.create(gpu.Surface.DescriptorFromMetalLayer);
        const layer = objc.quartz_core.MetalLayer.new();
        defer layer.release();
        metal_descriptor.* = .{
            .layer = layer,
        };
        surface_descriptor.next_in_chain = .{ .from_metal_layer = metal_descriptor };

        const screen = objc.app_kit.Screen.mainScreen();
        const rect = objc.core_graphics.Rect{ // TODO: use a meaningful rect
            .origin = .{ .x = 100, .y = 100 },
            .size = .{ .width = 480, .height = 270 },
        };
        const window_style =
            (if (options.display_mode == .fullscreen) objc.app_kit.WindowStyleMaskFullScreen else 0) |
            (if (options.display_mode == .windowed) objc.app_kit.WindowStyleMaskTitled else 0) |
            (if (options.display_mode == .windowed) objc.app_kit.WindowStyleMaskClosable else 0) |
            (if (options.display_mode == .windowed) objc.app_kit.WindowStyleMaskMiniaturizable else 0) |
            (if (options.display_mode == .windowed) objc.app_kit.WindowStyleMaskResizable else 0);
        window = objc.app_kit.Window.alloc().initWithContentRect_styleMask_backing_defer_screen(rect, window_style, objc.app_kit.BackingStoreBuffered, true, screen);
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
        .cursor_shape = .arrow,
        .border = options.border,
        .headless = options.headless,
        .refresh_rate = 60, // TODO: set to something meaningful
        .size = options.size,
        .surface_descriptor = surface_descriptor,
        .window = window,
    };
}

pub fn deinit(darwin: *Darwin) void {
    if (darwin.window) |w| @as(*objc.foundation.ObjectProtocol, @ptrCast(w)).release();
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
