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

    ns_app.run();
    //_ = objc.app_kit.applicationMain(0, undefined);

    unreachable;
    // TODO: support UIKit.
}

pub fn init(
    darwin: *Darwin,
    core: *Core,
    options: InitOptions,
) !void {
    var surface_descriptor = gpu.Surface.Descriptor{};

    // TODO: support UIKit.
    var window_opt: ?*objc.app_kit.Window = null;
    if (!options.headless) {
        // If the application is not headless, we need to make the application a genuine UI application
        // by setting the activation policy, this moves the process to foreground
        _ = objc.app_kit.Application.sharedApplication().setActivationPolicy(objc.app_kit.ApplicationActivationPolicyRegular);

        const metal_descriptor = try options.allocator.create(gpu.Surface.DescriptorFromMetalLayer);
        const layer = objc.quartz_core.MetalLayer.new();
        defer layer.release();
        layer.setDisplaySyncEnabled(true);
        metal_descriptor.* = .{
            .layer = layer,
        };
        surface_descriptor.next_in_chain = .{ .from_metal_layer = metal_descriptor };

        const screen = objc.app_kit.Screen.mainScreen();
        const rect = objc.core_graphics.Rect{
            .origin = .{ .x = 0, .y = 0 },
            .size = .{ .width = @floatFromInt(options.size.width), .height = @floatFromInt(options.size.height) },
        };

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
            false,
            screen,
        );
        if (window_opt) |window| {
            window.setReleasedWhenClosed(false);

            var view = objc.mach.View.allocInit();
            view.setLayer(@ptrCast(layer));

            {
                var keyDown = objc.foundation.stackBlockLiteral(ViewCallbacks.keyDown, darwin, null, null);
                view.setBlock_keyDown(keyDown.asBlock().copy());

                var keyUp = objc.foundation.stackBlockLiteral(ViewCallbacks.keyUp, darwin, null, null);
                view.setBlock_keyUp(keyUp.asBlock().copy());
            }
            window.setContentView(@ptrCast(view));
            window.center();
            window.setIsVisible(true);
            window.makeKeyAndOrderFront(null);

            const delegate = objc.mach.WindowDelegate.allocInit();
            defer window.setDelegate(@ptrCast(delegate));
            { // Set WindowDelegate blocks
                var windowWillResize_toSize = objc.foundation.stackBlockLiteral(WindowDelegateCallbacks.windowWillResize_toSize, darwin, null, null);
                delegate.setBlock_windowWillResize_toSize(windowWillResize_toSize.asBlock().copy());

                var windowShouldClose = objc.foundation.stackBlockLiteral(WindowDelegateCallbacks.windowShouldClose, darwin, null, null);
                delegate.setBlock_windowShouldClose(windowShouldClose.asBlock().copy());
            }
        } else std.debug.panic("mach: window failed to initialize", .{});
    }

    darwin.* = .{
        .allocator = options.allocator,
        .core = core,
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
    };
}

pub fn deinit(darwin: *Darwin) void {
    if (darwin.window) |w| @as(*objc.foundation.ObjectProtocol, @ptrCast(w)).release();
    return;
}

pub fn update(darwin: *Darwin) !void {
    if (darwin.window) |window| window.update();
}

pub fn setTitle(darwin: *Darwin, title: [:0]const u8) void {
    if (darwin.window) |window| {
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

pub fn setSize(darwin: *Darwin, size: Size) void {
    if (darwin.window) |window| {
        var frame = window.frame();
        frame.size.height = @floatFromInt(size.height);
        frame.size.width = @floatFromInt(size.width);
        window.setFrame_display_animate(frame, true, true);

        std.log.debug("setSize successfully called", .{});
    }
}

pub fn setCursorMode(_: *Darwin, _: CursorMode) void {
    return;
}

pub fn setCursorShape(_: *Darwin, _: CursorShape) void {
    return;
}

const WindowDelegateCallbacks = struct {
    pub fn windowWillResize_toSize(block: *objc.foundation.BlockLiteral(*Darwin), size: objc.app_kit.Size) callconv(.C) void {
        const darwin: *Darwin = block.context;
        const s: Size = .{ .width = @intFromFloat(size.width), .height = @intFromFloat(size.height) };

        darwin.size = .{
            .height = s.width,
            .width = s.height,
        };
        darwin.core.swap_chain_update.set();
        darwin.core.pushEvent(.{ .framebuffer_resize = .{ .width = s.width, .height = s.height } });
    }

    pub fn windowShouldClose(block: *objc.foundation.BlockLiteral(*Darwin)) callconv(.C) bool {
        const darwin: *Darwin = block.context;
        darwin.core.pushEvent(.close);
        return false;
    }
};

const ViewCallbacks = struct {
    pub fn keyDown(block: *objc.foundation.BlockLiteral(*Darwin), event: *objc.app_kit.Event) callconv(.C) void {
        const darwin: *Darwin = block.context;
        if (event.isARepeat()) {
            darwin.core.pushEvent(.{ .key_repeat = .{
                .key = machKeyFromKeycode(event.keyCode()),
                .mods = machModifierFromModifierFlag(event.modifierFlags()),
            } });
        } else {
            darwin.core.pushEvent(.{ .key_press = .{
                .key = machKeyFromKeycode(event.keyCode()),
                .mods = machModifierFromModifierFlag(event.modifierFlags()),
            } });
        }
    }

    pub fn keyUp(block: *objc.foundation.BlockLiteral(*Darwin), event: *objc.app_kit.Event) callconv(.C) void {
        const darwin: *Darwin = block.context;

        darwin.core.pushEvent(.{ .key_release = .{
            .key = machKeyFromKeycode(event.keyCode()),
            .mods = machModifierFromModifierFlag(event.modifierFlags()),
        } });
    }
};

fn machModifierFromModifierFlag(modifier_flag: usize) Core.KeyMods {
    var modifier: Core.KeyMods = .{
        .alt = false,
        .caps_lock = false,
        .control = false,
        .num_lock = false,
        .shift = false,
        .super = false,
    };

    if (modifier_flag & objc.app_kit.EventModifierFlagOption != 0)
        modifier.alt = true;

    if (modifier_flag & objc.app_kit.EventModifierFlagCapsLock != 0)
        modifier.caps_lock = true;

    if (modifier_flag & objc.app_kit.EventModifierFlagControl != 0)
        modifier.control = true;

    if (modifier_flag & objc.app_kit.EventModifierFlagShift != 0)
        modifier.shift = true;

    if (modifier_flag & objc.app_kit.EventModifierFlagCommand != 0)
        modifier.super = true;

    return modifier;
}

fn machKeyFromKeycode(keycode: c_ushort) Core.Key {
    comptime var table: [256]Key = undefined;
    comptime for (&table, 1..) |*ptr, i| {
        ptr.* = switch (i) {
            0x35 => .escape,
            0x12 => .one,
            0x13 => .two,
            0x14 => .three,
            0x15 => .four,
            0x17 => .five,
            0x16 => .six,
            0x1A => .seven,
            0x1C => .eight,
            0x19 => .nine,
            0x1D => .zero,
            0x1B => .minus,
            0x18 => .equal,
            0x33 => .backspace,
            0x30 => .tab,
            0x0C => .q,
            0x0D => .w,
            0x0E => .e,
            0x0F => .r,
            0x11 => .t,
            0x10 => .y,
            0x20 => .u,
            0x22 => .i,
            0x1F => .o,
            0x23 => .p,
            0x21 => .left_bracket,
            0x1E => .right_bracket,
            0x24 => .enter,
            0x3B => .left_control,
            0x00 => .a,
            0x01 => .s,
            0x02 => .d,
            0x03 => .f,
            0x05 => .g,
            0x04 => .h,
            0x26 => .j,
            0x28 => .k,
            0x25 => .l,
            0x29 => .semicolon,
            0x27 => .apostrophe,
            0x32 => .grave,
            0x38 => .left_shift,
            //0x2A => .backslash, // Iso backslash instead?
            0x06 => .z,
            0x07 => .x,
            0x08 => .c,
            0x09 => .v,
            0x0B => .b,
            0x2D => .n,
            0x2E => .m,
            0x2B => .comma,
            0x2F => .period,
            0x2C => .slash,
            0x3C => .right_shift,
            0x43 => .kp_multiply,
            0x3A => .left_alt,
            0x31 => .space,
            0x39 => .caps_lock,
            0x7A => .f1,
            0x78 => .f2,
            0x63 => .f3,
            0x76 => .f4,
            0x60 => .f5,
            0x61 => .f6,
            0x62 => .f7,
            0x64 => .f8,
            0x65 => .f9,
            0x6D => .f10,
            0x59 => .kp_7,
            0x5B => .kp_8,
            0x5C => .kp_9,
            0x4E => .kp_subtract,
            0x56 => .kp_4,
            0x57 => .kp_5,
            0x58 => .kp_6,
            0x45 => .kp_add,
            0x53 => .kp_1,
            0x54 => .kp_2,
            0x55 => .kp_3,
            0x52 => .kp_0,
            0x41 => .kp_decimal,
            0x69 => .print,
            0x2A => .iso_backslash,
            0x67 => .f11,
            0x6F => .f12,
            0x51 => .kp_equal,
            //0x64 => .f13, GLFW doesnt have a f13?
            0x6B => .f14,
            0x71 => .f15,
            0x6A => .f16,
            0x40 => .f17,
            0x4F => .f18,
            0x50 => .f19,
            0x5A => .f20,
            0x4C => .kp_enter,
            0x3E => .right_control,
            0x4B => .kp_divide,
            0x3D => .right_alt,
            0x47 => .num_lock,
            0x73 => .home,
            0x7E => .up,
            0x74 => .page_up,
            0x7B => .left,
            0x7C => .right,
            0x77 => .end,
            0x7D => .down,
            0x79 => .page_down,
            0x72 => .insert,
            0x75 => .delete,
            0x37 => .left_super,
            0x36 => .right_super,
            0x6E => .menu,
            else => .unknown,
        };
    };
    return if (keycode > 0 and keycode <= table.len) table[keycode - 1] else if (keycode == 0) .a else .unknown;
}
