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
const objc = @import("objc");

const log = std.log.scoped(.mach);

pub const Darwin = @This();

// --------------------------
// Module state
// --------------------------
allocator: std.mem.Allocator,
core: *Core,

// Core platform interface
surface_descriptor: gpu.Surface.Descriptor,
title: [:0]const u8,
display_mode: DisplayMode,
vsync_mode: VSyncMode,
cursor_mode: CursorMode,
cursor_shape: CursorShape,
border: bool,
headless: bool,
refresh_rate: u32,
size: Size,

// Internals
window: ?*objc.app_kit.Window,
state: *Core,

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

pub fn init(
    darwin: *Darwin,
    core: *Core.Mod,
    options: InitOptions,
) !void {
    var surface_descriptor = gpu.Surface.Descriptor{};

    // TODO: support UIKit.
    var window_opt: ?*objc.app_kit.Window = null;
    if (!options.headless) {
        const metal_descriptor = try options.allocator.create(gpu.Surface.DescriptorFromMetalLayer);
        const layer = objc.quartz_core.MetalLayer.new();
        defer layer.release();
        metal_descriptor.* = .{
            .layer = layer,
        };
        surface_descriptor.next_in_chain = .{ .from_metal_layer = metal_descriptor };

        const screen = objc.app_kit.Screen.mainScreen();

        var rect = objc.core_graphics.Rect{
            .origin = .{ .x = 100, .y = 100 },
            .size = .{ .width = @floatFromInt(options.size.width), .height = @floatFromInt(options.size.height) },
        };

        if (screen) |s| {
            const frame = s.visibleFrame();
            rect.origin.x = frame.size.width / 2.0 - @as(@TypeOf(rect.origin.x), @floatFromInt(options.size.width)) / 2.0;
            rect.origin.y = frame.size.height / 2.0 - @as(@TypeOf(rect.origin.y), @floatFromInt(options.size.height)) / 2.0;
        }

        const window_style =
            (if (options.display_mode == .fullscreen) objc.app_kit.WindowStyleMaskFullScreen else 0) |
            (if (options.display_mode == .windowed) objc.app_kit.WindowStyleMaskTitled else 0) |
            (if (options.display_mode == .windowed) objc.app_kit.WindowStyleMaskClosable else 0) |
            (if (options.display_mode == .windowed) objc.app_kit.WindowStyleMaskMiniaturizable else 0) |
            (if (options.display_mode == .windowed) objc.app_kit.WindowStyleMaskResizable else 0);

        window_opt = objc.app_kit.Window.alloc().initWithContentRect_styleMask_backing_defer_screen(
            rect,
            window_style,
            objc.app_kit.BackingStoreBuffered,
            true,
            screen,
        );
        if (window_opt) |window| {
            window.setReleasedWhenClosed(false);
            if (window.contentView()) |view| {
                view.setLayer(@ptrCast(layer));
            }
            window.setIsVisible(true);
            window.makeKeyAndOrderFront(null);

            const delegate = objc.mach.WindowDelegate.allocInit();

            const Helper = struct {
                pub fn cCallback_windowWillResize_toSize(block: *objc.foundation.BlockLiteral(*Darwin), size: objc.app_kit.Size) callconv(.C) void {
                    const self: *Darwin = block.context;
                    const s: Size = .{ .width = @intFromFloat(size.width), .height = @intFromFloat(size.height) };

                    self.size = .{
                        .height = s.width,
                        .width = s.height,
                    };
                    self.core.swap_chain_update.set();
                    self.core.pushEvent(.{ .framebuffer_resize = .{ .width = s.width, .height = s.height } });
                }
            };

            var blockLiteral_windowWillResize_toSize = objc.foundation.stackBlockLiteral(Helper.cCallback_windowWillResize_toSize, darwin, null, null);

            delegate.setBlock_windowWillResize_toSize(blockLiteral_windowWillResize_toSize.asBlock().copy());

            window.setDelegate(@ptrCast(delegate));
        }
    }

    darwin.* = .{
        .allocator = options.allocator,
        .core = @fieldParentPtr("platform", darwin),
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
        .window = window_opt,
        .state = core.state(),
    };
}

pub fn deinit(darwin: *Darwin) void {
    if (darwin.window) |w| @as(*objc.foundation.ObjectProtocol, @ptrCast(w)).release();
    return;
}

pub fn update(self: *Darwin) !void {
    if (self.window) |window| {
        window.update();
    }
}

pub fn setTitle(self: *Darwin, title: [:0]const u8) void {
    if (self.window) |window| {
        var string = objc.app_kit.String.allocInit();
        defer string.release();
        string = string.initWithUTF8String(title.ptr);
        window.setTitle(string);
    }
}

pub fn setDisplayMode(_: *Darwin, _: DisplayMode) void {
    return;
}

pub fn setBorder(_: *Darwin, _: bool) void {
    return;
}

pub fn setHeadless(_: *Darwin, _: bool) void {
    return;
}

pub fn setVSync(_: *Darwin, _: VSyncMode) void {
    return;
}

pub fn setSize(self: *Darwin, size: Size) void {
    if (self.window) |window| {
        var frame = window.frame();
        frame.size.height = @floatFromInt(size.height);
        frame.size.width = @floatFromInt(size.width);
        window.setFrame_display_animate(frame, true, true);
    }
}

pub fn setCursorMode(_: *Darwin, _: CursorMode) void {
    return;
}

pub fn setCursorShape(_: *Darwin, _: CursorShape) void {
    return;
}
