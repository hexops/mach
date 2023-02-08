# mach/freetype - Ziggified FreeType 2 bindings [![CI](https://github.com/hexops/mach-freetype/workflows/CI/badge.svg)](https://github.com/hexops/mach-freetype/actions) <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/main/readme.svg"></img></a>

Ziggified FreeType 2 bindings that [Mach engine](https://github.com/hexops/mach) uses, with zero-fuss installation, cross compilation, and more.

This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project / engine if they like!

## Zero fuss installation, cross compilation, and more

[Just as with Mach](https://github.com/hexops/mach#zero-fuss-installation--cross-compilation), you get zero fuss installation & cross compilation using these Freetype bindings. **only `zig` and `git` are needed to build from any OS and produce binaries for every OS.** No system dependencies at all.

## Usage

## Getting started

### Adding dependency (using Git)

In a `libs` subdirectory of the root of your project:

```sh
git clone https://github.com/hexops/mach-freetype
```

Then in your `build.zig` add:

```zig
...
const freetype = @import("libs/mach-freetype/build.zig");

pub fn build(b: *Build) void {
    ...
    exe.addModule("freetype", freetype.module(b));
    freetype.link(b, exe, .{});

    // use this option if you are including zlib separately
    //freetype.link(b, exe, .{ .freetype = .{ .use_system_zlib = true } });
}
```

and optionaly add harfbuzz:

```zig
exe.addModule("harfbuzz", freetype.harfbuzzModule(b));
freetype.link(b, exe, .{ .harfbuzz = .{} });
```

You can also optionally build brotli compression (for WOFF2 font support):

```zig
    exe.addModule("freetype", freetype.module(b));
    freetype.link(b, exe, .{ .freetype = .{ .brotli = true } });
```

<details>
<description>Optional: Using Gyro dependency manager</description>

```sh
gyro add --src github hexops/mach-freetype --root src/main.zig --alias freetype
gyro add --build-dep --src github hexops/mach-freetype --root build.zig --alias build-freetype
```

Then in your `build.zig` add:

```zig
...
const pkgs = @import("deps.zig").pkgs;
const freetype = @import("build-freetype");

pub fn build(b: *Build) void {
    ...

    exe.addModule("freetype", pkgs.freetype);
    freetype.link(b, exe, .{});
}
```

**WARNING: You should use `gyro build` instead of `zig build` now!**

</details>

Now you can import in code:

```zig
const freetype = @import("freetype");
```

## Examples

See the `examples/` directory. for running each example do:

```sh
zig build run-example-<name> # e.g run-example-single-glyph
```

## Join the community

Join the Mach engine community [on Matrix chat](https://matrix.to/#/#hexops:matrix.org) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Afreetype).

## Contributing

Contributions are very welcome. Pull requests must be sent to [the main repository](https://github.com/hexops/mach/tree/main/libs/freetype) to avoid some complex merge conflicts we'd get by accepting contributions in both repositories. Once the changes are merged there, they'll get sync'd to this repository automatically.

# Thanks

Special thanks to [@alichraghi](https://github.com/alichraghi), original author of these bindings who contributed them to Mach!
