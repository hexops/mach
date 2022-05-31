const std = @import("std");
const glfw = @import("glfw");
const gpu = @import("gpu");
const App = @import("app");
const Engine = @import("../Engine.zig");
const structs = @import("../structs.zig");
const enums = @import("../enums.zig");
const util = @import("util.zig");
const c = @import("c.zig").c;

pub const Platform = struct {
    window: glfw.Window,
    backend_type: gpu.Adapter.BackendType,
    allocator: std.mem.Allocator,
    events: EventQueue = .{},
    user_ptr: UserPtr = undefined,

    last_window_size: structs.Size,
    last_framebuffer_size: structs.Size,

    native_instance: gpu.NativeInstance,

    const EventQueue = std.TailQueue(structs.Event);
    const EventNode = EventQueue.Node;

    const UserPtr = struct {
        platform: *Platform,
    };

    pub fn init(allocator: std.mem.Allocator, engine: *Engine) !Platform {
        const options = engine.options;
        const backend_type = try util.detectBackendType(allocator);

        glfw.setErrorCallback(Platform.errorCallback);
        try glfw.init(.{});

        // Create the test window and discover adapters using it (esp. for OpenGL)
        var hints = util.glfwWindowHintsForBackend(backend_type);
        hints.cocoa_retina_framebuffer = true;
        const window = try glfw.Window.create(
            options.width,
            options.height,
            options.title,
            null,
            null,
            hints,
        );

        const window_size = try window.getSize();
        const framebuffer_size = try window.getFramebufferSize();

        const backend_procs = c.machDawnNativeGetProcs();
        c.dawnProcSetProcs(backend_procs);

        const instance = c.machDawnNativeInstance_init();
        var native_instance = gpu.NativeInstance.wrap(c.machDawnNativeInstance_get(instance).?);

        // Discover e.g. OpenGL adapters.
        try util.discoverAdapters(instance, window, backend_type);

        // Request an adapter.
        //
        // TODO: It would be nice if we could use gpu_interface.waitForAdapter here, however the webgpu.h
        // API does not yet have a way to specify what type of backend you want (vulkan, opengl, etc.)
        // In theory, I suppose we shouldn't need to and Dawn should just pick the best adapter - but in
        // practice if Vulkan is not supported today waitForAdapter/requestAdapter merely generates an error.
        //
        // const gpu_interface = native_instance.interface();
        // const backend_adapter = switch (gpu_interface.waitForAdapter(&.{
        //     .power_preference = .high_performance,
        // })) {
        //     .adapter => |v| v,
        //     .err => |err| {
        //         std.debug.print("mach: failed to get adapter: error={} {s}\n", .{ err.code, err.message });
        //         std.process.exit(1);
        //     },
        // };
        const adapters = c.machDawnNativeInstance_getAdapters(instance);
        var dawn_adapter: ?c.MachDawnNativeAdapter = null;
        var i: usize = 0;
        while (i < c.machDawnNativeAdapters_length(adapters)) : (i += 1) {
            const adapter = c.machDawnNativeAdapters_index(adapters, i);
            const properties = c.machDawnNativeAdapter_getProperties(adapter);
            const found_backend_type = @intToEnum(gpu.Adapter.BackendType, c.machDawnNativeAdapterProperties_getBackendType(properties));
            if (found_backend_type == backend_type) {
                dawn_adapter = adapter;
                break;
            }
        }
        if (dawn_adapter == null) {
            std.debug.print("mach: no matching adapter found for {s}", .{@tagName(backend_type)});
            std.debug.print("-> maybe try GPU_BACKEND=opengl ?\n", .{});
            std.process.exit(1);
        }
        std.debug.assert(dawn_adapter != null);
        const backend_adapter = gpu.NativeInstance.fromWGPUAdapter(c.machDawnNativeAdapter_get(dawn_adapter.?).?);

        // Print which adapter we are going to use.
        const props = backend_adapter.properties;
        std.debug.print("mach: found {s} backend on {s} adapter: {s}, {s}\n", .{
            gpu.Adapter.backendTypeName(props.backend_type),
            gpu.Adapter.typeName(props.adapter_type),
            props.name,
            props.driver_description,
        });

        const device = switch (backend_adapter.waitForDevice(&.{
            .required_features = options.required_features,
            .required_limits = options.required_limits,
        })) {
            .device => |v| v,
            .err => |err| {
                // TODO: return a proper error type
                std.debug.print("mach: failed to get device: error={} {s}\n", .{ err.code, err.message });
                std.process.exit(1);
            },
        };

        // If targeting OpenGL, we can't use the newer WGPUSurface API. Instead, we need to use the
        // older Dawn-specific API. https://bugs.chromium.org/p/dawn/issues/detail?id=269&q=surface&can=2
        const use_legacy_api = backend_type == .opengl or backend_type == .opengles;
        var descriptor: gpu.SwapChain.Descriptor = undefined;
        var swap_chain: ?gpu.SwapChain = null;
        var swap_chain_format: gpu.Texture.Format = undefined;
        var surface: ?gpu.Surface = null;
        if (!use_legacy_api) {
            swap_chain_format = .bgra8_unorm;
            descriptor = .{
                .label = "basic swap chain",
                .usage = .{ .render_attachment = true },
                .format = swap_chain_format,
                .width = framebuffer_size.width,
                .height = framebuffer_size.height,
                .present_mode = switch (options.vsync) {
                    .none => .immediate,
                    .double => .fifo,
                    .triple => .mailbox,
                },
                .implementation = 0,
            };
            surface = util.createSurfaceForWindow(
                &native_instance,
                window,
                comptime util.detectGLFWOptions(),
            );
        } else {
            const binding = c.machUtilsCreateBinding(@enumToInt(backend_type), @ptrCast(*c.GLFWwindow, window.handle), @ptrCast(c.WGPUDevice, device.ptr));
            if (binding == null) {
                @panic("failed to create Dawn backend binding");
            }
            descriptor = std.mem.zeroes(gpu.SwapChain.Descriptor);
            descriptor.implementation = c.machUtilsBackendBinding_getSwapChainImplementation(binding);
            swap_chain = device.nativeCreateSwapChain(null, &descriptor);

            swap_chain_format = @intToEnum(gpu.Texture.Format, @intCast(u32, c.machUtilsBackendBinding_getPreferredSwapChainTextureFormat(binding)));
            swap_chain.?.configure(
                swap_chain_format,
                .{ .render_attachment = true },
                framebuffer_size.width,
                framebuffer_size.height,
            );
        }

        device.setUncapturedErrorCallback(&util.printUnhandledErrorCallback);

        engine.device = device;
        engine.backend_type = backend_type;
        engine.surface = surface;
        engine.swap_chain = swap_chain;
        engine.swap_chain_format = swap_chain_format;
        engine.current_desc = descriptor;
        engine.target_desc = descriptor;

        return Platform{
            .window = window,
            .backend_type = backend_type,
            .allocator = engine.allocator,
            .last_window_size = .{ .width = window_size.width, .height = window_size.height },
            .last_framebuffer_size = .{ .width = framebuffer_size.width, .height = framebuffer_size.height },
            .native_instance = native_instance,
        };
    }

    fn pushEvent(platform: *Platform, event: structs.Event) void {
        const node = platform.allocator.create(EventNode) catch unreachable;
        node.* = .{ .data = event };
        platform.events.append(node);
    }

    fn initCallback(platform: *Platform) void {
        platform.user_ptr = UserPtr{ .platform = platform };

        platform.window.setUserPointer(&platform.user_ptr);

        const callback = struct {
            fn callback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
                const pf = (window.getUserPointer(UserPtr) orelse unreachable).platform;

                switch (action) {
                    .press => pf.pushEvent(.{
                        .key_press = .{
                            .key = toMachKey(key),
                        },
                    }),
                    .release => pf.pushEvent(.{
                        .key_release = .{
                            .key = toMachKey(key),
                        },
                    }),
                    else => {},
                }

                _ = scancode;
                _ = mods;
            }
        }.callback;
        platform.window.setKeyCallback(callback);

        const size_callback = struct {
            fn callback(window: glfw.Window, width: i32, height: i32) void {
                const pf = (window.getUserPointer(UserPtr) orelse unreachable).platform;
                pf.last_window_size.width = @intCast(u32, width);
                pf.last_window_size.height = @intCast(u32, height);
            }
        }.callback;
        platform.window.setSizeCallback(size_callback);

        const framebuffer_size_callback = struct {
            fn callback(window: glfw.Window, width: u32, height: u32) void {
                const pf = (window.getUserPointer(UserPtr) orelse unreachable).platform;
                pf.last_framebuffer_size.width = width;
                pf.last_framebuffer_size.height = height;
            }
        }.callback;
        platform.window.setFramebufferSizeCallback(framebuffer_size_callback);
    }

    pub fn setShouldClose(platform: *Platform, value: bool) void {
        platform.window.setShouldClose(value);
    }

    pub fn getFramebufferSize(platform: *Platform) structs.Size {
        return platform.last_framebuffer_size;
    }

    pub fn getWindowSize(platform: *Platform) structs.Size {
        return platform.last_window_size;
    }

    pub fn setSizeLimits(platform: *Platform, min: structs.SizeOptional, max: structs.SizeOptional) !void {
        try platform.window.setSizeLimits(
            @bitCast(glfw.Window.SizeOptional, min),
            @bitCast(glfw.Window.SizeOptional, max),
        );
    }

    pub fn pollEvent(platform: *Platform) ?structs.Event {
        if (platform.events.popFirst()) |n| {
            defer platform.allocator.destroy(n);
            return n.data;
        }
        return null;
    }

    fn toMachKey(key: glfw.Key) enums.Key {
        return switch (key) {
            .a => .a,
            .b => .b,
            .c => .c,
            .d => .d,
            .e => .e,
            .f => .f,
            .g => .g,
            .h => .h,
            .i => .i,
            .j => .j,
            .k => .k,
            .l => .l,
            .m => .m,
            .n => .n,
            .o => .o,
            .p => .p,
            .q => .q,
            .r => .r,
            .s => .s,
            .t => .t,
            .u => .u,
            .v => .v,
            .w => .w,
            .x => .x,
            .y => .y,
            .z => .z,

            .zero => .zero,
            .one => .one,
            .two => .two,
            .three => .three,
            .four => .four,
            .five => .five,
            .six => .six,
            .seven => .seven,
            .eight => .eight,
            .nine => .nine,

            .F1 => .f1,
            .F2 => .f2,
            .F3 => .f3,
            .F4 => .f4,
            .F5 => .f5,
            .F6 => .f6,
            .F7 => .f7,
            .F8 => .f8,
            .F9 => .f9,
            .F10 => .f10,
            .F11 => .f11,
            .F12 => .f12,
            .F13 => .f13,
            .F14 => .f14,
            .F15 => .f15,
            .F16 => .f16,
            .F17 => .f17,
            .F18 => .f18,
            .F19 => .f19,
            .F20 => .f20,
            .F21 => .f21,
            .F22 => .f22,
            .F23 => .f23,
            .F24 => .f24,
            .F25 => .f25,

            .kp_divide => .kp_divide,
            .kp_multiply => .kp_multiply,
            .kp_subtract => .kp_subtract,
            .kp_add => .kp_add,
            .kp_0 => .kp_0,
            .kp_1 => .kp_1,
            .kp_2 => .kp_2,
            .kp_3 => .kp_3,
            .kp_4 => .kp_4,
            .kp_5 => .kp_5,
            .kp_6 => .kp_6,
            .kp_7 => .kp_7,
            .kp_8 => .kp_8,
            .kp_9 => .kp_9,
            .kp_decimal => .kp_decimal,
            .kp_equal => .kp_equal,
            .kp_enter => .kp_enter,

            .enter => .enter,
            .escape => .escape,
            .tab => .tab,
            .left_shift => .left_shift,
            .right_shift => .right_shift,
            .left_control => .left_control,
            .right_control => .right_control,
            .left_alt => .left_alt,
            .right_alt => .right_alt,
            .left_super => .left_super,
            .right_super => .right_super,
            .menu => .menu,
            .num_lock => .num_lock,
            .caps_lock => .caps_lock,
            .print_screen => .print,
            .scroll_lock => .scroll_lock,
            .pause => .pause,
            .delete => .delete,
            .home => .home,
            .end => .end,
            .page_up => .page_up,
            .page_down => .page_down,
            .insert => .insert,
            .left => .left,
            .right => .right,
            .up => .up,
            .down => .down,
            .backspace => .backspace,
            .space => .space,
            .minus => .minus,
            .equal => .equal,
            .left_bracket => .left_bracket,
            .right_bracket => .right_bracket,
            .backslash => .backslash,
            .semicolon => .semicolon,
            .apostrophe => .apostrophe,
            .comma => .comma,
            .period => .period,
            .slash => .slash,
            .grave_accent => .grave,

            .world_1 => .unknown,
            .world_2 => .unknown,
            .unknown => .unknown,
        };
    }

    /// Default GLFW error handling callback
    fn errorCallback(error_code: glfw.Error, description: [:0]const u8) void {
        std.debug.print("glfw: {}: {s}\n", .{ error_code, description });
    }
};

pub const BackingTimer = std.time.Timer;

const common = @import("common.zig");
comptime {
    common.checkApplication(App);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const options = if (@hasDecl(App, "options")) App.options else structs.Options{};
    var engine = try Engine.init(allocator, options);
    var app: App = undefined;

    try app.init(&engine);
    defer app.deinit(&engine);

    // Glfw specific: initialize the user pointer used in callbacks
    engine.internal.initCallback();

    const window = engine.internal.window;
    while (!window.shouldClose()) {
        try glfw.pollEvents();

        engine.delta_time_ns = engine.timer.lapPrecise();
        engine.delta_time = @intToFloat(f32, engine.delta_time_ns) / @intToFloat(f32, std.time.ns_per_s);

        var framebuffer_size = engine.getFramebufferSize();
        engine.target_desc.width = framebuffer_size.width;
        engine.target_desc.height = framebuffer_size.height;

        if (engine.swap_chain == null or !engine.current_desc.equal(&engine.target_desc)) {
            const use_legacy_api = engine.surface == null;
            if (!use_legacy_api) {
                engine.swap_chain = engine.device.nativeCreateSwapChain(engine.surface, &engine.target_desc);
            } else engine.swap_chain.?.configure(
                engine.swap_chain_format,
                .{ .render_attachment = true },
                engine.target_desc.width,
                engine.target_desc.height,
            );

            if (@hasDecl(App, "resize")) {
                try app.resize(&engine, engine.target_desc.width, engine.target_desc.height);
            }
            engine.current_desc = engine.target_desc;
        }

        const success = try app.update(&engine);
        if (!success)
            break;
    }
}
