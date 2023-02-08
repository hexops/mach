# mach/basisu - basis universal (supercompressed textures) for Zig

This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project if they like!

## Getting started

### Adding dependency

In a `libs` subdirectory of the root of your project:

```sh
git clone https://github.com/hexops/mach-basisu
```

Then in your `build.zig` add:

```zig
...
const basisu = @import("libs/mach-basisu/build.zig");

pub fn build(b: *Build) void {
    ...
    exe.addModule("basisu", basisu.module(b));
    basisu.link(b, exe, .{});
}
```

## Join the community

Join the Mach community [on Discord](https://discord.gg/XNG3NZgCqp) or [Matrix](https://matrix.to/#/#hexops:matrix.org) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Abasisu).

## Contributing

Contributions are very welcome. Pull requests must be sent to [the main repository](https://github.com/hexops/mach/tree/main/libs/basisu) to avoid some complex merge conflicts we'd get by accepting contributions in both repositories. Once the changes are merged there, they'll get sync'd to this repository automatically.
