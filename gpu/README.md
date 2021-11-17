# WebGPU for Zig <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/master/readme.svg"></img></a>

Idiomatic [Zig](https://ziglang.org) bindings to [WebGPU](https://gpuweb.github.io/gpuweb), the up-and-coming API which allows for unified access to low-level graphics APIs like Vulkan, Metal, and D3D12 across web, desktop, and mobile devices.

This library is _truly cross platform_, allowing you to use the same graphics API **in the web** or **natively** (desktop & mobile):

- **WebAssembly targets**: Uses the browser's provided WebGPU API.
- **Native targets:** supports multiple WebGPU backend implementations:
    - [Dawn](https://dawn.googlesource.com/dawn), Chrome's C++ implementation of WebGPU.
    - [gfx-rs/wgpu-native](https://github.com/gfx-rs/wgpu-native), the Rust implementation of WebGPU.

## webgpu.h version

Both [Dawn](https://dawn.googlesource.com/dawn) and [gfx-rs/wgpu-native](https://github.com/gfx-rs/wgpu-native) implement a shared common C header, [webgpu.h](https://github.com/webgpu-native/webgpu-headers) which maps 1:1 with the WebGPU IDL specification.

You can find the version of `webgpu.h` currently targeted by this library [here](https://github.com/webgpu-native/webgpu-headers/tree/c8e0b39f6f6f1edded5c4adf7d46aa4d2a95befe).
