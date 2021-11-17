# mach/gpu, truly cross-platform graphics for Zig <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/master/readme.svg"></img></a>

`mach/gpu` is a truly cross-platform graphics API (desktop, mobile, and web) providing a unified low-level graphics API over Vulkan, Metal, D3D12, and OpenGL (as a best-effort fallback.)

![](https://user-images.githubusercontent.com/3173176/137646296-72ba698e-c710-4daf-aa75-222f8d717d00.png)

## Warning: Under heavy development!

Not everything stated in this README is yet achieved. We're working on it! Of particular note, we are missing:

* Cross compilation support
* Windows support
* Linux support
* Android support
* iOS support
* Browser support
* Idiomatic WebGPU wrapper

## Features

* Desktop, mobile, and web support.
* Cross-compilation & no fuss installation, using `zig build`, as with all Mach libraries.
* A modern graphics API similar to Metal, Vulkan, and DirectX 12. 
* Compute shaders
* Advanced GPU features where hardware support is available:
    * Depth buffer clipping control
    * Depth buffer format control
    * Texture compression (BC, ETC2, and ASTC)
    * Timestamp querying (for GPU profiling)
    * Indirect draw support

**Note:** Absolute bleeding edge features which have not truly stabilized, such as DirectX 12 Mesh Shaders (which has limited hardware support, does not work across both AMD and NVIDIA cards in Vulkan, etc.) are not supported. You can however always choose to drop down to the underlying native Vulkan/Metal/D3D12 API in conjunction with this abstraction if needed.

## A different approach to graphics API abstraction

Most engines today (Unreal, Unity) maintain their own GPU abstraction layer over native graphics APIs at great expense, requiring many years of development and ongoing maintenance.

Many are attempting graphics abstraction layers on their own including Godot (and their custom shading language), [SDL's recently announced GPU abstraction layer](https://news.ycombinator.com/item?id=29203534), [sokol_gfx](https://github.com/floooh/sokol), and others including Blender3D which target varying native graphics APIs. These are admirable efforts, but come at great development costs.

Vulkan, the alleged cross-platform graphics API, in practice requires abstraction layers like MoltenVK on Apple hardware and is often in practice too verbose for use without at least one higher level abstraction layer (often the engine's rendering layer.) With a simpler API like Metal or D3D, however, one could stay closer to the underlying API without introducing secondary and third abstraction layers on top and make smarter choices as a result.

With Mach, we'd rather focus on building great games than yet-another-abstraction-layer, and as it turns out some of the best minds in computer graphics (including the Rust community, Mozilla, Google, Microsoft, Intel, and Apple) have made serious multi-year investments with several full-time engineers into creating a solid abstraction layer for us - we're just being smart and adopting it for our own purpose!

## Behind the scenes

`mach/gpu` is an idiomatic Zig interface to [the next-generation WebGPU API](https://www.w3.org/TR/webgpu/), which supersedes WebGL and exposes the common denominator between the latest low-level graphics APIs (Vulkan, Metal, D3D12) in the web.

Despite its name, [WebGPU was also built with native support in mind](http://kvark.github.io/web/gpu/native/2020/05/03/point-of-webgpu-native.html) and has substantial investment from Mozilla, Google, Microsoft, Intel, and, critically, Apple:

![](https://user-images.githubusercontent.com/3173176/137647342-abf2bde6-a8bb-4276-b072-95c279c5d92f.png)

When targeting WebAssembly, `mach/gpu` merely calls into the browser's native WebGPU implementation.

When building native Zig binaries, it builds and directly invokes Google Chrome's native WebGPU implementation, [Dawn](https://dawn.googlesource.com/dawn), bypassing the client-server sandboxing model - and using `zig build` (plus a lot of hand-holding) to support zero-fuss cross compilation & installation without any third-party Google tools, libraries, etc. Just `zig` and `git` needed, nothing else.

[Read more about why we believe WebGPU may be the future of graphics here](https://devlog.hexops.com/2021/mach-engine-the-future-of-graphics-with-zig#truly-cross-platform-graphics-api)
