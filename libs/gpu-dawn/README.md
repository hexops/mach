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

Building Dawn from source using this method is simple:

```sh
git clone https://github.com/hexops/mach-gpu-dawn
cd mach-gpu-dawn

rm -rf libs/mach-glfw
git clone https://github.com/hexops/mach-glfw libs/mach-glfw

zig build
```

(Please make sure to use Zig nightly, e.g. v0.10, not v0.9, which you can get a binary release of at the very top of this page: https://ziglang.org/download/)

This will take ~10 minutes to finish (see the 'binary releases' section below.) You can add the following options:

| Option                        | Description                                                |
|-------------------------------|------------------------------------------------------------|
| `-Doptimize=ReleaseFast`      | Build a release binary instead of a debug binary (default) |
| `-Dtarget=x86_64-macos.12`    | Cross compile to macOS (Intel chipsets)                    |
| `-Dtarget=aarch64-macos.12`   | Cross compile to macOS (Apple Silicon)                     |
| `-Dtarget=x86_64-linux-gnu`   | Cross compile to x86_64 Linux (glibc)                      |
| `-Dtarget=x86_64-linux-musl`  | Cross compile to x86_64 Linux (musl libc)                  |
| `-Dtarget=x86_64-windows-gnu` | Cross compile to x86_64 Windows                            |

The following platforms are not yet supported, but we hope to support soon:

* iOS (Dawn does not officially support it yet)
* Android (Dawn does not officially support it yet)
* ARM Linux (aarch64)
* Windows msvc target (Zig targets MinGW libc on Windows currently, msvc support should not be hard to add.)

## Binary releases

Dawn (specifically all the shader compilers, and the DirectXShaderCompiler) is a large C++ codebase and takes 5-10 minutes to build on a modern laptop. Since waiting is no fun, we also have binary releases produced by our GitHub actions:

**[View binary releases](https://github.com/hexops/mach-gpu-dawn/releases/latest)**

Here's how to read the downloads provided:

* `_debug.tar.gz` and `_release-fast.tar.gz` are tarballs of the static library + headers for each OS and debug/release mode, respectively.
* `headers.json.gz` is a JSON archive of all the Dawn/WebGPU headers.
* Files ending in `.a.gz` and `.lib.gz` are the individual static `libdawn.a` and `dawn.lib` (Windows) gzippped and distributed. These are provided as individual downloads so there is no need to extract a tarball.

## Important: Building WebGPU API symbols

Dawn and other WebGPU implementations (like the Rust one) do not agree on a standard `webgpu.h` API. Aspirationally, they aim to target the same https://github.com/webgpu-native/webgpu-headers header, but in practice they expose different APIs which are not ABI compatible.

When you call a Dawn `webgpu.h` function, Dawn internally diverts this call through a vtable which must be initialized using a call to `dawnProcSetProcs`.

`mach/gpu-dawn` builds since Oct 17th 2022 no longer include the `webgpu.h` symbols by default. If you intend to actually call the WebGPU API, you should build these two source files as part of your application:

1. [`dawn_proc.c`](https://raw.githubusercontent.com/hexops/dawn/generated-2023-01-28.1674950134/out/Debug/gen/src/dawn/dawn_proc.c)
2. [`webgpu_dawn_native_proc.cpp`](https://raw.githubusercontent.com/hexops/dawn/generated-2023-01-28.1674950134/out/Debug/gen/src/dawn/native/webgpu_dawn_native_proc.cpp)

And call `dawnProcSetProcs` to set up the proc table.

## A warning about API stability

You should be aware:

* WebGPU's API is not formalized yet.
* Dawn's API is still changing.
* The `webgpu.h` API is still changing
* Dawn and gfx-rs/wgpu, although both try to implement `webgpu.h`, do not exactly implement the same interface. There are subtle differences in device discovery & creation for example.

## Generated code

Dawn itself relies on a fairly large amount of dependencies, generated code, etc. To avoid having any dependency on Google build tools, code generation, etc. we maintain [a minor fork of Dawn which has generated code and third-party dependencies comitted in "generated" branches.](https://github.com/hexops/dawn/tree/main/mach) We are usually up-to-date with the upstream within a few weeks on average.

It also provides a [few small patches to enable building Dawn with the Zig compiler](https://github.com/hexops/mach/issues/168) which we plan to upstream soon, as well as some [patches to build the DirectXShaderCompiler with Zig](https://github.com/hexops/mach/issues/151).

## Join the community

Join the Mach engine community [on Discord](https://discord.gg/XNG3NZgCqp) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Agpu-dawn).

## License

All Mach code (this repository) is under the Apache and MIT license at your choosing described in the `LICENSE` file. Dawn itself is [similarly permissively licensed](https://github.com/hexops/dawn/blob/main/LICENSE).
