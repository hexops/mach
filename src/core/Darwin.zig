const std = @import("std");
const mach = @import("../main.zig");
const Core = @import("../Core.zig");
const gpu = mach.gpu;
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

pub const Native = struct {
    window: *objc.app_kit.Window = undefined,
    view: *objc.mach.View = undefined,
};

pub const Context = struct {
    core: *Core,
    core_mod: mach.Mod(Core),
    window_id: mach.ObjectID,
};

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

    unreachable;
    // TODO: support UIKit.
}

pub fn tick(core: *Core, core_mod: mach.Mod(Core)) !void {
    var windows = core.windows.slice();
    while (windows.next()) |window_id| {
        const core_window = core.windows.getValue(window_id);

        if (core_window.native) |native| {
            const native_window: *objc.app_kit.Window = native.window;

            if (core.windows.updated(window_id, .decoration_color)) {
                if (core_window.decoration_color) |decoration_color| {
                    const color = objc.app_kit.Color.colorWithRed_green_blue_alpha(
                        decoration_color.r,
                        decoration_color.g,
                        decoration_color.b,
                        decoration_color.a,
                    );
                    native_window.setBackgroundColor(color);
                    native_window.setTitlebarAppearsTransparent(true);
                } else {
                    native_window.setTitlebarAppearsTransparent(false);
                }
            }

            if (core.windows.updated(window_id, .title)) {
                const string = objc.foundation.String.allocInit();
                defer string.release();
                native.window.setTitle(string.initWithUTF8String(core_window.title));
            }

            if (core.windows.updated(window_id, .width) or core.windows.updated(window_id, .height)) {
                var frame = native_window.frame();
                frame.size.width = @floatFromInt(core.windows.get(window_id, .width));
                frame.size.height = @floatFromInt(core.windows.get(window_id, .height));
                native_window.setFrame_display_animate(native_window.frameRectForContentRect(frame), true, true);
            }

            if (core.windows.updated(window_id, .cursor_mode)) {
                switch (core_window.cursor_mode) {
                    .normal => objc.app_kit.Cursor.unhide(),
                    .disabled, .hidden => objc.app_kit.Cursor.hide(),
                }
            }

            if (core.windows.updated(window_id, .cursor_shape)) {
                const Cursor = objc.app_kit.Cursor;

                Cursor.T_pop();

                switch (core_window.cursor_shape) {
                    .arrow => Cursor.arrowCursor().push(),
                    .ibeam => Cursor.IBeamCursor().push(),
                    .crosshair => Cursor.crosshairCursor().push(),
                    .pointing_hand => Cursor.pointingHandCursor().push(),
                    .not_allowed => Cursor.operationNotAllowedCursor().push(),
                    .resize_ns => Cursor.resizeUpDownCursor().push(),
                    .resize_ew => Cursor.resizeLeftRightCursor().push(),
                    .resize_all => Cursor.closedHandCursor().push(),
                    else => std.log.warn("Unsupported cursor", .{}),
                }
            }
        } else {
            try initWindow(core, core_mod, window_id);
        }
    }
}

fn initWindow(
    core: *Core,
    core_mod: mach.Mod(Core),
    window_id: mach.ObjectID,
) !void {
    var core_window = core.windows.getValue(window_id);

    const context = try core.allocator.create(Context);
    context.* = .{ .core = core, .core_mod = core_mod, .window_id = window_id };

    // If the application is not headless, we need to make the application a genuine UI application
    // by setting the activation policy, this moves the process to foreground
    // TODO: Only call this on the first window creation
    _ = objc.app_kit.Application.sharedApplication().setActivationPolicy(objc.app_kit.ApplicationActivationPolicyRegular);

    {
        // On macos, the command key in particular seems to be handled a bit differently and tends to block the `keyUp` event
        // from firing. To remedy this, we borrow the same fix GLFW uses and add a monitor.
        const commandFn = struct {
            pub fn commandFn(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) ?*objc.app_kit.Event {
                const core_: *Core = block.context.core;
                const window_id_ = block.context.window_id;

                if (core_.windows.get(window_id_, .native)) |native| {
                    const native_window: *objc.app_kit.Window = native.window;

                    if (event.modifierFlags() & objc.app_kit.EventModifierFlagCommand != 0)
                        native_window.sendEvent(event);
                }
                return event;
            }
        }.commandFn;

        var commandBlock = objc.foundation.stackBlockLiteral(
            commandFn,
            context,
            null,
            null,
        );

        _ = objc.app_kit.Event.addLocalMonitorForEventsMatchingMask_handler(objc.app_kit.EventMaskKeyUp, commandBlock.asBlock().copy());
    }

    const metal_descriptor = try core.allocator.create(gpu.Surface.DescriptorFromMetalLayer);
    const layer = objc.quartz_core.MetalLayer.new();
    defer layer.release();

    if (core_window.transparent) layer.setOpaque(false);

    metal_descriptor.* = .{
        .layer = layer,
    };
    core_window.surface_descriptor = .{};
    core_window.surface_descriptor.next_in_chain = .{ .from_metal_layer = metal_descriptor };

    const screen = objc.app_kit.Screen.mainScreen();
    const rect = objc.core_graphics.Rect{
        .origin = .{ .x = 0, .y = 0 },
        .size = .{ .width = @floatFromInt(core_window.width), .height = @floatFromInt(core_window.height) },
    };

    const window_style =
        (if (core_window.display_mode == .fullscreen) objc.app_kit.WindowStyleMaskFullScreen else 0) |
        (if (core_window.decorated) objc.app_kit.WindowStyleMaskTitled else 0) |
        (if (core_window.decorated) objc.app_kit.WindowStyleMaskClosable else 0) |
        (if (core_window.decorated) objc.app_kit.WindowStyleMaskMiniaturizable else 0) |
        (if (core_window.decorated) objc.app_kit.WindowStyleMaskResizable else 0) |
        (if (!core_window.decorated) objc.app_kit.WindowStyleMaskFullSizeContentView else 0);

    const native_window_opt: ?*objc.app_kit.Window = objc.app_kit.Window.alloc().initWithContentRect_styleMask_backing_defer_screen(
        rect,
        window_style,
        objc.app_kit.BackingStoreBuffered,
        false,
        screen,
    );
    if (native_window_opt) |native_window| {
        const framebuffer_scale: f32 = @floatCast(native_window.backingScaleFactor());
        const window_width: f32 = @floatFromInt(core_window.width);
        const window_height: f32 = @floatFromInt(core_window.height);

        core_window.framebuffer_width = @intFromFloat(window_width * framebuffer_scale);
        core_window.framebuffer_height = @intFromFloat(window_height * framebuffer_scale);

        native_window.setReleasedWhenClosed(false);

        var view = objc.mach.View.allocInit();

        // initWithFrame is overridden in our MACHView, which creates a tracking area for mouse tracking
        view = view.initWithFrame(rect);
        view.setLayer(@ptrCast(layer));

        // TODO(core): free this allocation

        {
            var render = objc.foundation.stackBlockLiteral(
                ViewCallbacks.render,
                context,
                null,
                null,
            );
            view.setBlock_render(render.asBlock().copy());

            var keyDown = objc.foundation.stackBlockLiteral(
                ViewCallbacks.keyDown,
                context,
                null,
                null,
            );
            view.setBlock_keyDown(keyDown.asBlock().copy());

            var insertText = objc.foundation.stackBlockLiteral(
                ViewCallbacks.insertText,
                context,
                null,
                null,
            );
            view.setBlock_insertText(insertText.asBlock().copy());

            var keyUp = objc.foundation.stackBlockLiteral(
                ViewCallbacks.keyUp,
                context,
                null,
                null,
            );
            view.setBlock_keyUp(keyUp.asBlock().copy());

            var flagsChanged = objc.foundation.stackBlockLiteral(
                ViewCallbacks.flagsChanged,
                context,
                null,
                null,
            );
            view.setBlock_flagsChanged(flagsChanged.asBlock().copy());

            var magnify = objc.foundation.stackBlockLiteral(
                ViewCallbacks.magnify,
                context,
                null,
                null,
            );
            view.setBlock_magnify(magnify.asBlock().copy());

            var mouseMoved = objc.foundation.stackBlockLiteral(
                ViewCallbacks.mouseMoved,
                context,
                null,
                null,
            );
            view.setBlock_mouseMoved(mouseMoved.asBlock().copy());

            var mouseDown = objc.foundation.stackBlockLiteral(
                ViewCallbacks.mouseDown,
                context,
                null,
                null,
            );
            view.setBlock_mouseDown(mouseDown.asBlock().copy());

            var mouseUp = objc.foundation.stackBlockLiteral(
                ViewCallbacks.mouseUp,
                context,
                null,
                null,
            );
            view.setBlock_mouseUp(mouseUp.asBlock().copy());

            var scrollWheel = objc.foundation.stackBlockLiteral(
                ViewCallbacks.scrollWheel,
                context,
                null,
                null,
            );
            view.setBlock_scrollWheel(scrollWheel.asBlock().copy());
        }
        native_window.setContentView(@ptrCast(view));
        native_window.center();
        native_window.setIsVisible(true);
        native_window.makeKeyAndOrderFront(null);

        if (core_window.decoration_color) |decoration_color| {
            const color = objc.app_kit.Color.colorWithRed_green_blue_alpha(
                decoration_color.r,
                decoration_color.g,
                decoration_color.b,
                decoration_color.a,
            );
            native_window.setBackgroundColor(color);
            native_window.setTitlebarAppearsTransparent(true);
        }

        const string = objc.foundation.String.allocInit();
        defer string.release();
        native_window.setTitle(string.initWithUTF8String(core_window.title));

        const delegate = objc.mach.WindowDelegate.allocInit();
        defer native_window.setDelegate(@ptrCast(delegate));
        {
            var windowDidResize = objc.foundation.stackBlockLiteral(
                WindowDelegateCallbacks.windowDidResize,
                context,
                null,
                null,
            );
            delegate.setBlock_windowDidResize(windowDidResize.asBlock().copy());

            var windowShouldClose = objc.foundation.stackBlockLiteral(
                WindowDelegateCallbacks.windowShouldClose,
                context,
                null,
                null,
            );
            delegate.setBlock_windowShouldClose(windowShouldClose.asBlock().copy());
        }

        // Set core_window.native, which we use to check if a window is initialized
        // Then call core.initWindow to finish initializing the window
        core_window.native = .{ .window = native_window, .view = view };
        core.windows.setValueRaw(window_id, core_window);
        try core.initWindow(window_id);
    } else std.debug.panic("mach: window failed to initialize", .{});
}

pub fn waitEventTimeout(seconds: f64) !void {
    if (seconds > 0.0) {
        const ns_app = objc.app_kit.Application.sharedApplication();

        const expiration_date = objc.app_kit.Date.dateWithTimeIntervalSinceNow(seconds);

        // For some reason, no matter what I seem to do no events are ever fired here
        // and it never returns before the expiration date. It also seems to interfere with the DVDisplayLink
        // callback (render).

        if (ns_app.nextEventMatchingMask_untilDate_inMode_dequeue(
            objc.app_kit.EventMaskAny,
            expiration_date,
            objc.app_kit.NSDefaultRunLoopMode,
            true,
        )) |_| {
            std.log.debug("event!", .{});
        }
    }
}

const WindowDelegateCallbacks = struct {
    pub fn windowDidResize(block: *objc.foundation.BlockLiteral(*Context)) callconv(.C) void {
        const core: *Core = block.context.core;

        var core_window = core.windows.getValue(block.context.window_id);

        if (core_window.native) |native| {
            const native_window: *objc.app_kit.Window = native.window;

            const frame = native_window.frame();
            const content_rect = native_window.contentRectForFrameRect(frame);

            if (core_window.width != @as(u32, @intFromFloat(content_rect.size.width)) or core_window.height != @as(u32, @intFromFloat(content_rect.size.height))) {
                core_window.width = @intFromFloat(content_rect.size.width);
                core_window.height = @intFromFloat(content_rect.size.height);

                const framebuffer_scale: f32 = @floatCast(native_window.backingScaleFactor());
                const window_width: f32 = @floatFromInt(core_window.width);
                const window_height: f32 = @floatFromInt(core_window.height);

                core_window.framebuffer_width = @intFromFloat(window_width * framebuffer_scale);
                core_window.framebuffer_height = @intFromFloat(window_height * framebuffer_scale);

                core_window.swap_chain_descriptor.width = core_window.framebuffer_width;
                core_window.swap_chain_descriptor.height = core_window.framebuffer_height;
                core_window.swap_chain.release();

                core_window.swap_chain = core_window.device.createSwapChain(core_window.surface, &core_window.swap_chain_descriptor);

                core.windows.setValueRaw(block.context.window_id, core_window);

                core.pushEvent(.{ .window_resize = .{
                    .window_id = block.context.window_id,
                    .size = .{ .width = core_window.width, .height = core_window.height },
                } });
            }
        }
    }

    pub fn windowShouldClose(block: *objc.foundation.BlockLiteral(*Context)) callconv(.C) bool {
        const core: *Core = block.context.core;
        core.pushEvent(.{ .close = .{ .window_id = block.context.window_id } });

        // TODO: This should just attempt to close the window, not the entire program, unless
        // this is the only window.
        return false;
    }
};

const ViewCallbacks = struct {
    pub fn render(block: *objc.foundation.BlockLiteral(*Context)) callconv(.C) void {
        const core: *Core = block.context.core;
        const core_mod = block.context.core_mod;
        const window_id = block.context.window_id;

        const window = core.windows.getValue(window_id);

        if (window.on_tick) |function_id| {
            core_mod.run(function_id);
        }
    }

    pub fn mouseMoved(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) void {
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;

        const mouse_location = event.locationInWindow();

        const window_height: f32 = @floatFromInt(core.windows.get(window_id, .height));

        core.pushEvent(.{ .mouse_motion = .{
            .window_id = window_id,
            .pos = .{ .x = mouse_location.x, .y = window_height - mouse_location.y },
        } });
    }

    pub fn mouseDown(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) void {
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;

        core.pushEvent(.{ .mouse_press = .{
            .window_id = window_id,
            .button = @enumFromInt(event.buttonNumber()),
            .pos = .{ .x = event.locationInWindow().x, .y = event.locationInWindow().y },
            .mods = machModifierFromModifierFlag(event.modifierFlags()),
        } });
    }
    pub fn mouseUp(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) void {
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;

        core.pushEvent(.{ .mouse_release = .{
            .window_id = window_id,
            .button = @enumFromInt(event.buttonNumber()),
            .pos = .{ .x = event.locationInWindow().x, .y = event.locationInWindow().y },
            .mods = machModifierFromModifierFlag(event.modifierFlags()),
        } });
    }

    pub fn scrollWheel(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) void {
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;

        var scroll_delta_x = event.scrollingDeltaX();
        var scroll_delta_y = event.scrollingDeltaY();

        if (event.hasPreciseScrollingDeltas()) {
            scroll_delta_x *= 0.1;
            scroll_delta_y *= 0.1;
        }

        core.pushEvent(.{ .mouse_scroll = .{
            .window_id = window_id,
            .xoffset = @floatCast(scroll_delta_x),
            .yoffset = @floatCast(scroll_delta_y),
        } });
    }

    // This is currently only supported on macOS using a trackpad
    pub fn magnify(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) void {
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;

        core.pushEvent(.{ .zoom_gesture = .{
            .window_id = window_id,
            .zoom = @floatCast(event.magnification()),
            .phase = machPhaseFromPhase(event.phase()),
        } });
    }

    pub fn keyDown(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) void {
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;
        if (event.isARepeat()) {
            core.pushEvent(.{ .key_repeat = .{
                .window_id = window_id,
                .key = machKeyFromKeycode(event.keyCode()),
                .mods = machModifierFromModifierFlag(event.modifierFlags()),
            } });
        } else {
            core.pushEvent(.{ .key_press = .{
                .window_id = window_id,
                .key = machKeyFromKeycode(event.keyCode()),
                .mods = machModifierFromModifierFlag(event.modifierFlags()),
            } });
        }
    }

    pub fn insertText(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event, codepoint: u32) callconv(.C) void {
        _ = event; // autofix
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;
        core.pushEvent(.{ .char_input = .{
            .codepoint = @intCast(codepoint),
            .window_id = window_id,
        } });
    }

    pub fn keyUp(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) void {
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;

        core.pushEvent(.{ .key_release = .{
            .window_id = window_id,
            .key = machKeyFromKeycode(event.keyCode()),
            .mods = machModifierFromModifierFlag(event.modifierFlags()),
        } });
    }

    pub fn flagsChanged(block: *objc.foundation.BlockLiteral(*Context), event: *objc.app_kit.Event) callconv(.C) void {
        const core: *Core = block.context.core;
        const window_id = block.context.window_id;

        const key = machKeyFromKeycode(event.keyCode());
        const mods = machModifierFromModifierFlag(event.modifierFlags());

        const key_flag = switch (key) {
            .left_shift, .right_shift => objc.app_kit.EventModifierFlagShift,
            .left_control, .right_control => objc.app_kit.EventModifierFlagControl,
            .left_alt, .right_alt => objc.app_kit.EventModifierFlagOption,
            .left_super, .right_super => objc.app_kit.EventModifierFlagCommand,
            .caps_lock => objc.app_kit.EventModifierFlagCapsLock,
            else => 0,
        };

        if (event.modifierFlags() & key_flag != 0) {
            if (core.input_state.isKeyPressed(key)) {
                core.pushEvent(.{ .key_release = .{ .window_id = window_id, .key = key, .mods = mods } });
            } else {
                core.pushEvent(.{ .key_press = .{ .window_id = window_id, .key = key, .mods = mods } });
            }
        } else {
            core.pushEvent(.{ .key_release = .{ .window_id = window_id, .key = key, .mods = mods } });
        }
    }
};

fn machPhaseFromPhase(phase: objc.app_kit.EventPhase) Core.GesturePhase {
    return switch (phase) {
        objc.app_kit.EventPhaseBegan => .began,
        objc.app_kit.EventPhaseEnded => .ended,
        else => .began,
    };
}

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
