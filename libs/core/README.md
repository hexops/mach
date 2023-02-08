# mach/core: a modern alternative to SDL/etc

This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project if they like!

## Window+Input+GPU, nothing else.

mach/core provides the power of Vulkan, DirectX, Metal, and modern OpenGL in a single concise graphics API - by compiling Google Chrome's WebGPU implementation natively via Zig (no cmake/ninja/gn/etc) into a single static library.

Supports Windows, Linux, and macOS today. WebAssembly and Mobile will also be supported under the same API in the near future.

Learn more: https://machengine.org/docs/core

## Getting started

### Adding dependency

In a `libs` subdirectory of the root of your project:

```sh
git clone https://github.com/hexops/mach-core
```

Then in your `build.zig` add:

```zig
...
const core = @import("libs/mach-core/build.zig");

pub fn build(b: *Build) void {
    ...
    exe.addModule("core", core.module(b));
    core.link(b, exe, .{});
}
```

## Join the community

Join the Mach community [on Discord](https://discord.gg/XNG3NZgCqp) or [Matrix](https://matrix.to/#/#hexops:matrix.org) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Acore).

## Contributing

Contributions are very welcome. Pull requests must be sent to [the main repository](https://github.com/hexops/mach/tree/main/libs/core) to avoid some complex merge conflicts we'd get by accepting contributions in both repositories. Once the changes are merged there, they'll get sync'd to this repository automatically.
