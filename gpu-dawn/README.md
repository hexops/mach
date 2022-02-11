# mach/gpu-dawn, WebGPU/Dawn built with Zig <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/master/readme.svg"></img></a>

`mach/gpu-dawn` builds [Dawn](https://dawn.googlesource.com/dawn/) (Google's WebGPU implementation), requiring nothing more than `zig` and `git` to build and cross-compile static Dawn libraries for every OS.

* No cmake
* No ninja
* No `gn`
* No system dependencies (xcode, etc.)
* Cross compilation supported out of the box
* Builds a single static `libdawn.a` with everything you need.

This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project / engine if they like!

## Warning: Under heavy development!

This package is still under heavy development, Linux and macOS are working but Windows is not yet.

## Zig Dawn/WebGPU interface

This package implements the [the `mach/gpu` Zig interface](https://github.com/hexops/mach/tree/main/gpu) which, for Zig developers, allows swapping between WebGPU implementations seamlessly similar to the `std.mem.Allocator` interface.

## Generated code

Dawn itself relies on a fairly large amount of dependencies, generated code, etc. To avoid having any dependency on Google build tools, code generation, etc. we maintain [a minor fork of Dawn which has generated code and third-party dependencies comitted.](https://github.com/hexops/dawn/tree/main/mach)
