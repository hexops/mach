const std = @import("std");
const testing = std.testing;

const c = @import("c.zig").c;

pub usingnamespace @import("consts.zig");
pub const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

pub const action = @import("action.zig");
pub const gamepad_axis = @import("gamepad_axis.zig");
pub const gamepad_button = @import("gamepad_button.zig");
pub const GammaRamp = @import("GammaRamp.zig");
pub const hat = @import("hat.zig");
pub const Image = @import("Image.zig");
pub const joystick = @import("joystick.zig");
pub const key = @import("key.zig");
pub const mod = @import("mod.zig");
pub const Monitor = @import("Monitor.zig");
pub const mouse_button = @import("mouse_button.zig");
pub const version = @import("version.zig");
pub const VideoMode = @import("VideoMode.zig");
pub const Window = @import("Window.zig");

pub usingnamespace @import("clipboard.zig");
pub usingnamespace @import("input.zig");
pub usingnamespace @import("opengl.zig");
pub usingnamespace @import("vulkan.zig");
pub usingnamespace @import("time.zig");

/// Initializes the GLFW library.
///
/// This function initializes the GLFW library. Before most GLFW functions can be used, GLFW must
/// be initialized, and before an application terminates GLFW should be terminated in order to free
/// any resources allocated during or after initialization.
///
/// If this function fails, it calls glfw.Terminate before returning. If it succeeds, you should
/// call glfw.Terminate before the application exits.
///
/// Additional calls to this function after successful initialization but before termination will
/// return immediately with no error.
///
/// macos: This function will change the current directory of the application to the
/// `Contents/Resources` subdirectory of the application's bundle, if present. This can be disabled
/// with the glfw.COCOA_CHDIR_RESOURCES init hint.
///
/// x11: This function will set the `LC_CTYPE` category of the application locale according to the
/// current environment if that category is still "C".  This is because the "C" locale breaks
/// Unicode text input.
///
/// @thread_safety This function must only be called from the main thread.
pub inline fn init() Error!void {
    _ = c.glfwInit();
    return try getError();
}

/// Terminates the GLFW library.
///
/// This function destroys all remaining windows and cursors, restores any modified gamma ramps
/// and frees any other allocated resources. Once this function is called, you must again call
/// glfw.init successfully before you will be able to use most GLFW functions.
///
/// If GLFW has been successfully initialized, this function should be called before the
/// application exits. If initialization fails, there is no need to call this function, as it is
/// called by glfw.init before it returns failure.
///
/// This function has no effect if GLFW is not initialized.
///
/// Possible errors include glfw.Error.PlatformError.
///
/// remark: This function may be called before glfw.init.
///
/// warning: The contexts of any remaining windows must not be current on any other thread when
/// this function is called.
///
/// reentrancy: This function must not be called from a callback.
///
/// thread_safety: This function must only be called from the main thread.
pub inline fn terminate() void {
    c.glfwTerminate();
}

/// Sets the specified init hint to the desired value.
///
/// This function sets hints for the next initialization of GLFW.
///
/// The values you set hints to are never reset by GLFW, but they only take effect during
/// initialization. Once GLFW has been initialized, any values you set will be ignored until the
/// library is terminated and initialized again.
///
/// Some hints are platform specific.  These may be set on any platform but they will only affect
/// their specific platform.  Other platforms will ignore them. Setting these hints requires no
/// platform specific headers or functions.
///
/// @param hint: The init hint to set.
/// @param value: The new value of the init hint.
///
/// Possible errors include glfw.Error.InvalidEnum and glfw.Error.InvalidValue.
///
/// @remarks This function may be called before glfw.init.
///
/// @thread_safety This function must only be called from the main thread.
pub inline fn initHint(hint: c_int, value: c_int) Error!void {
    c.glfwInitHint(hint, value);
    try getError();
}

/// Returns a string describing the compile-time configuration.
///
/// This function returns the compile-time generated version string of the GLFW library binary. It
/// describes the version, platform, compiler and any platform-specific compile-time options. It
/// should not be confused with the OpenGL or OpenGL ES version string, queried with `glGetString`.
///
/// __Do not use the version string__ to parse the GLFW library version. Use the glfw.version
/// constants instead.
///
/// @return The ASCII encoded GLFW version string.
///
/// @errors None.
///
/// @remark This function may be called before @ref glfwInit.
///
/// @pointer_lifetime The returned string is static and compile-time generated.
///
/// @thread_safety This function may be called from any thread.
pub inline fn getVersionString() [*c]const u8 {
    return c.glfwGetVersionString();
}

/// Processes all pending events.
///
/// This function processes only those events that are already in the event queue and then returns
/// immediately. Processing events will cause the window and input callbacks associated with those
/// events to be called.
///
/// On some platforms, a window move, resize or menu operation will cause event processing to
/// block. This is due to how event processing is designed on those platforms. You can use the
/// window refresh callback (see window_refresh) to redraw the contents of your window when
/// necessary during such operations.
///
/// Do not assume that callbacks you set will _only_ be called in response to event processing
/// functions like this one. While it is necessary to poll for events, window systems that require
/// GLFW to register callbacks of its own can pass events to GLFW in response to many window system
/// function calls. GLFW will pass those events on to the application callbacks before returning.
///
/// Event processing is not required for joystick input to work.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @reentrancy This function must not be called from a callback.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: events, glfw.waitEvents, glfw.waitEventsTimeout
pub inline fn pollEvents() Error!void {
    c.glfwPollEvents();
    try getError();
}

// /// Waits until events are queued and processes them.
// ///
// /// This function puts the calling thread to sleep until at least one event is
// /// available in the event queue. Once one or more events are available,
// /// it behaves exactly like @ref glfwPollEvents, i.e. the events in the queue
// /// are processed and the function then returns immediately. Processing events
// /// will cause the window and input callbacks associated with those events to be
// /// called.
// ///
// /// Since not all events are associated with callbacks, this function may return
// /// without a callback having been called even if you are monitoring all
// /// callbacks.
// ///
// /// On some platforms, a window move, resize or menu operation will cause event
// /// processing to block. This is due to how event processing is designed on
// /// those platforms. You can use the
// /// [window refresh callback](@ref window_refresh) to redraw the contents of
// /// your window when necessary during such operations.
// ///
// /// Do not assume that callbacks you set will _only_ be called in response to
// /// event processing functions like this one. While it is necessary to poll for
// /// events, window systems that require GLFW to register callbacks of its own
// /// can pass events to GLFW in response to many window system function calls.
// /// GLFW will pass those events on to the application callbacks before
// /// returning.
// ///
// /// Event processing is not required for joystick input to work.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// @reentrancy This function must not be called from a callback.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: events, glfw.pollEvents, glfw.waitEventsTimeout
// ///
// GLFWAPI void glfwWaitEvents(void);

// /// Waits with timeout until events are queued and processes them.
// ///
// /// This function puts the calling thread to sleep until at least one event is
// /// available in the event queue, or until the specified timeout is reached. If
// /// one or more events are available, it behaves exactly like @ref
// /// glfwPollEvents, i.e. the events in the queue are processed and the function
// /// then returns immediately. Processing events will cause the window and input
// /// callbacks associated with those events to be called.
// ///
// /// The timeout value must be a positive finite number.
// ///
// /// Since not all events are associated with callbacks, this function may return
// /// without a callback having been called even if you are monitoring all
// /// callbacks.
// ///
// /// On some platforms, a window move, resize or menu operation will cause event
// /// processing to block. This is due to how event processing is designed on
// /// those platforms. You can use the
// /// [window refresh callback](@ref window_refresh) to redraw the contents of
// /// your window when necessary during such operations.
// ///
// /// Do not assume that callbacks you set will _only_ be called in response to
// /// event processing functions like this one. While it is necessary to poll for
// /// events, window systems that require GLFW to register callbacks of its own
// /// can pass events to GLFW in response to many window system function calls.
// /// GLFW will pass those events on to the application callbacks before
// /// returning.
// ///
// /// Event processing is not required for joystick input to work.
// ///
// /// @param[in] timeout The maximum amount of time, in seconds, to wait.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidValue and glfw.Error.PlatformError.
// ///
// /// @reentrancy This function must not be called from a callback.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: events, glfw.pollEvents, glfw.waitEvents
// ///
// GLFWAPI void glfwWaitEventsTimeout(double timeout);

// /// Posts an empty event to the event queue.
// ///
// /// This function posts an empty event from the current thread to the event
// /// queue, causing @ref glfwWaitEvents or @ref glfwWaitEventsTimeout to return.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// @thread_safety This function may be called from any thread.
// ///
// /// see also: events, glfw.waitEvents, glfw.waitEventsTimeout
// ///
// GLFWAPI void glfwPostEmptyEvent(void);

pub fn basicTest() !void {
    try init();
    defer terminate();

    const window = Window.create(640, 480, "GLFW example", null, null) catch |err| {
        // return without fail, because most of our CI environments are headless / we cannot open
        // windows on them.
        std.debug.print("note: failed to create window: {}\n", .{err});
        return;
    };
    defer window.destroy();

    var start = std.time.milliTimestamp();
    while (std.time.milliTimestamp() < start + 1000 and !window.shouldClose()) {
        c.glfwPollEvents();
    }
}

test "getVersionString" {
    // Reference these so the tests in these files get pulled in / ran.
    _ = Monitor;
    _ = GammaRamp;
    _ = Image;
    _ = VideoMode;
    _ = Window;

    std.debug.print("\nGLFW version v{}.{}.{}\n", .{ version.major, version.minor, version.revision });
    std.debug.print("\nstring: {s}\n", .{getVersionString()});
}

test "pollEvents" {
    try init();
    defer terminate();

    try pollEvents();
}

test "basic" {
    try basicTest();
}
