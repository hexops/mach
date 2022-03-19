# mach/gpu-dawn, WebGPU/Dawn built with Zig <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/master/readme.svg"></img></a>

`mach/gpu-dawn` builds [Dawn](https://dawn.googlesource.com/dawn/), Google Chrome's WebGPU implementation, requiring nothing more than `zig` and `git` to build and cross-compile a static Dawn library for every OS:

* No cmake
* No ninja
* No `gn`
* No system dependencies (xcode, etc.)
* Automagic cross compilation out of the box with nothing more than `zig` and `git`!
* Builds a single static `libdawn.a` with everything you need.

This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project / engine if they like!

## Building from source

Building Dawn from source using this method is as simple as:

```sh
git clone https://github.com/hexops/mach-gpu-dawn
cd mach-gpu-dawn
zig build -Ddawn-from-source=true
```

This will take ~10 minutes to finish (see the 'binary releases' section below.) You can add the following options:

| Option                        | Description                                                |
|-------------------------------|------------------------------------------------------------|
| `-Drelease-fast=true`         | Build a release binary instead of a debug binary (default) |
| `-Dtarget=x86_64-macos.12`    | Cross compile to macOS (Intel chipsets)                    |
| `-Dtarget=aarch64-macos.12`   | Cross compile to macOS (Apple Silicon)                     |
| `-Dtarget=x86_64-linux-gnu`   | Cross compile to x86_64 Linux (glibc)                      |
| `-Dtarget=x86_64-linux-musl`  | Cross compile to x86_64 Linux (musl libc)                  |
| `-Dtarget=x86_64-windows-gnu` | Cross compile to x86_64 Windows                            |

The following platforms are not yet supported, but we hope to support soon:

* iOS (Dawn does not officially support it yet)
* Android (Dawn does not officially support it yet)
* ARM Linux (aarch64)

## Binary releases

Dawn (specifically all the shader compilers, and the DirectXShaderCompiler) is a large C++ codebase and takes 5-10 minutes to build on a modern laptop, you just need to specify `-Ddawn-from-source=true` and wait. Since waiting is no fun, we also have binary releases produced by our GitHub actions:

**[View binary releases](https://github.com/hexops/mach-gpu-dawn/releases/latest)**

Here's how to read the downloads provided:

* `_debug.tar.gz` and `_release-fast.tar.gz` are tarballs of the static library + headers for each OS and debug/release mode, respectively.
* `headers.json.gz` is a JSON archive of all the Dawn/WebGPU headers.
* Files ending in `.a.gz` and `.lib.gz` are the individual static `libdawn.a` and `dawn.lib` (Windows) gzippped and distributed. These are provided as individual downloads so there is no need to extract a tarball.

## A warning about API stability

You should be aware:

* WebGPU's API is not formalized yet.
* Dawn's API is still changing.
* The `webgpu.h` API is still changing
* Dawn and gfx-rs/wgpu, although both try to implement `webgpu.h`, do not exactly implement the same interface. There are subtle differences in device discovery & creation for example.

Some of Dawn's API is not available as a C API today. For example, OpenGL device discovery. You may find the following C shims we build for Mach engine useful for interfacing with Dawn from other languages (copy these into your own project, they are not built into the static dawn library):

* [dawn_native_mach.h](https://github.com/hexops/mach/blob/main/gpu-dawn/src/dawn/dawn_native_mach.h)
* [dawn_native-mach.cpp](https://github.com/hexops/mach/blob/main/gpu-dawn/src/dawn/dawn_native_mach.cpp)

## Generated code

Dawn itself relies on a fairly large amount of dependencies, generated code, etc. To avoid having any dependency on Google build tools, code generation, etc. we maintain [a minor fork of Dawn which has generated code and third-party dependencies comitted in "generated" branches.](https://github.com/hexops/dawn/tree/main/mach) We are usually up-to-date with the upstream within a few weeks on average.

It also provides a [few small patches to enable building Dawn with the Zig compiler](https://github.com/hexops/mach/issues/168) which we plan to upstream soon, as well as some [patches to build the DirectXShaderCompiler with Zig](https://github.com/hexops/mach/issues/151).

## Join the community

Join the Mach engine community [on Matrix chat](https://matrix.to/#/#hexops:matrix.org) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Agpu-dawn).
