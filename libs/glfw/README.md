# mach/glfw - Ziggified GLFW bindings [![CI](https://github.com/hexops/mach-glfw/workflows/CI/badge.svg)](https://github.com/hexops/mach-glfw/actions) <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/main/readme.svg"></img></a>

Ziggified GLFW bindings that [Mach engine](https://github.com/hexops/mach) uses, with 100% API coverage, zero-fuss installation, cross compilation, and more.

This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project / engine if they like!

## Zero fuss installation, cross compilation, and more

[Just as with Mach](https://github.com/hexops/mach#zero-fuss-installation--cross-compilation), you get zero fuss installation & cross compilation using these GLFW bindings. **only `zig` and `git` are needed to build from any OS and produce binaries for every OS.** No system dependencies at all.

## 100% API coverage, 130+ tests, etc.

These bindings have 100% API coverage of GLFW v3.3.4. Every function, type, constant, etc. has been wrapped in a ziggified API.

There are 130+ tests, and CI tests on all major platforms as well as cross-compilation between platforms:

[platform support table](https://github.com/hexops/mach#supported-platforms)

## What does a ziggified GLFW API offer?

Why create a ziggified GLFW wrapper, instead of just using `@cImport` and interfacing with GLFW directly? You get:

- `true` and `false` instead of `c.GLFW_TRUE` and `c.GLFW_FALSE` constants.
- Generics, so you can just use `window.hint` instead of `glfwWindowHint`, `glfwWindowHintString`, etc.
- **Enums**, always know what value a GLFW function can accept as everything is strictly typed. And use the nice Zig syntax to access enums, like `window.getKey(.escape)` instead of `c.glfwGetKey(window, c.GLFW_KEY_ESCAPE)`
- Slices instead of C pointers and lengths.
- [packed structs](https://ziglang.org/documentation/master/#packed-struct) represent bit masks, so you can use `if (joystick.down and joystick.right)` instead of `if (joystick & c.GLFW_HAT_DOWN and joystick & c.GLFW_HAT_RIGHT)`, etc.
- Methods, e.g. `my_window.hint(...)` instead of `glfwWindowHint(my_window, ...)`

## How do I use OpenGL, Vulkan, WebGPU, etc. with this?

You'll need to bring your own library for this. Some are:

- (Vulkan) https://github.com/Snektron/vulkan-zig (also see https://github.com/Avokadoen/zig_vulkan)
- (OpenGL) https://github.com/ziglibs/zgl

## Examples

A minimal Vulkan example can be found in the [mach-glfw-vulkan-example](https://github.com/hexops/mach-glfw-vulkan-example) repository:

<img width="912" alt="image" src="https://user-images.githubusercontent.com/3173176/139573985-d862f35a-e78e-40c2-bc0c-9c4fb68d6ecd.png">

## Getting started

### Adding dependency (using Git)

In a `libs` subdirectory of the root of your project:

```sh
git clone https://github.com/hexops/mach-glfw
```

Then in your `build.zig` add:

```zig
...
const glfw = @import("libs/mach-glfw/build.zig").Sdk(.{
    // TODO(build-system): This cannot be imported with the Zig package manager
    // error: TarUnsupportedFileType
    .xcode_frameworks = @import("libs/mach-glfw/libs/xcode-frameworks/build.zig"),
});

pub fn build(b: *Build) !void {
    ...
    exe.addModule("glfw", glfw.module(b));
    try glfw.link(b, exe, .{});
}
```

<details>
<summary>

### (optional) Adding dependency using Gyro

</summary>

```sh
gyro add --src github hexops/mach-glfw --root src/main.zig --alias glfw
gyro add --build_dep --src github hexops/mach-glfw --root build.zig --alias build-glfw
```

Then in your `build.zig` add:

```zig
...
const pkgs = @import("deps.zig").pkgs;
const glfw = @import("build-glfw");

pub fn build(b: *Build) !void {
    ...

    exe.addModule("glfw", pkgs.glfw);
    try glfw.link(b, exe, .{});
}
```

**Note: You should use `gyro build` instead of `zig build` to use gyro**

</details>

# Next steps

Now in your code you may import and use GLFW:

```zig
const glfw = @import("glfw");

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(640, 480, "Hello, mach-glfw!", null, null, .{}) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        glfw.pollEvents();
    }
}
```

## A warning about error handling

Unless the action you're performing is truly critical to your application continuing further, you should avoid terminating on error.

This is because GLFW unfortunately must return errors for _a large portion_ of its functionality on some platforms, but especially for Wayland - so ideally your application is resiliant to such errors and merely e.g. logs failures that are not critical.

Here is a rough list of functionality Wayland does not support:

- `Window.setIcon`
- `Window.setPos`, `Window.getPos`
- `Window.iconify`, `Window.focus`
- `Monitor.setGamma`
- `Monitor.getGammaRamp`, `Monitor.setGammaRamp`

For example, `window.getPos()` will always return x=0, y=0 on Wayland due to lack of platform support.
Ignoring this error is a reasonable choice for most applications.
However, errors like this can still be caught and handled:

```zig
const pos = window.getPos();

// Option 1: convert a GLFW error into a Zig error.
glfw.getErrorCode() catch |err| {
    std.log.err("failed to get window position: error={}", .{err});
    return err; // Or fall back to an alternative implementation.
};

// Option 2: log a human-readable description of the error.
if (glfw.getErrorString()) |description| {
    std.log.err("failed to get window position: {s}", .{description});
    // ...
}

// Option 3: use a combination of the above approaches.
if (glfw.getError()) |err| {
    const error_code = err.error_code; // Zig error
    const description = err.description; // Human-readable description
    std.log.err("failed to get window position: error={}: {s}", .{error_code, description});
    // ...
}
```

Note that the above example relies on GLFW's saved error being empty; otherwise, previously emitted errors may be mistaken for an error caused by `window.getPos()`.
If your application frequently ignores errors, it may be necessary to call `glfw.clearError()` or `defer glfw.clearError()` to ensure a clean slate for future error handling.

## Join the community

Join the Mach engine community [on Discord](https://discord.gg/XNG3NZgCqp) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Aglfw).

## Contributing

Contributions are very welcome. Pull requests must be sent to [the main repository](https://github.com/hexops/mach/tree/main/libs/glfw) to avoid some complex merge conflicts we'd get by accepting contributions in both repositories. Once the changes are merged there, they'll get sync'd to this repository automatically.

For now mach/glfw tracks the latest `master` revision of GLFW, as recorded [in this file](https://github.com/hexops-graveyard/glfw/blob/main/VERSION), as this version has critical undefined behavior fixes required for GLFW to work with Zig. We will switch to stable releases of GLFW once GLFW 3.4 is tagged.
