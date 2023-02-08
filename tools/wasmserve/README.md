# mach/wasmserve

Small web server specifically for serving Zig WASM applications in development

## Getting started

### Adding dependency

In a `libs` subdirectory of the root of your project:

```sh
git clone https://github.com/machlibs/wasmserve
```

Then in your `build.zig` add:

```zig
...
const wasmserve = @import("libs/wasmserve/wasmserve.zig");

pub fn build(b: *Build) void {
    ...
    const serve_step = try wasmserve.serve(exe, .{ .watch_paths = &.{"src/main.zig"} });
    const run_step = b.step("run", "Run development web server");
    run_step.dependOn(&serve_step.step);
}
```

## Join the community

Join the Mach community [on Discord](https://discord.gg/XNG3NZgCqp) or [Matrix](https://matrix.to/#/#hexops:matrix.org) to discuss this project, ask questions, get help, etc.
