# mach/gpu, truly cross-platform graphics for Zig <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/master/readme.svg"></img></a>

`mach/gpu` provides a truly cross-platform graphics API (desktop, mobile, and web) with unified low-level graphics & compute backed by Vulkan, Metal, D3D12, and OpenGL (as a best-effort fallback.)

![](https://user-images.githubusercontent.com/3173176/137646296-72ba698e-c710-4daf-aa75-222f8d717d00.png)

## Warning: Under heavy development!

Not everything stated in this README is yet achieved. We're working on it! Of particular note, we are missing:

* Android support
* iOS support
* Browser support

## Features

* Desktop, mobile, and web support.
* A modern graphics API similar to Metal, Vulkan, and DirectX 12. 
* Cross-platform shading language
* Compute shaders
* Cross-compilation & no fuss installation, using `zig build`, as with all Mach libraries.
* Advanced GPU features where hardware support is available:
    * Depth buffer clipping control
    * Depth buffer format control
    * Texture compression (BC, ETC2, and ASTC)
    * Timestamp querying (for GPU profiling)
    * Indirect draw support

## Different approach to graphics API abstraction

Most engines today (Unreal, Unity, Godot, etc.) maintain their own GPU abstraction layer over native graphics APIs at great expense, requiring years of development and ongoing maintenance.

Many are attempting graphics abstraction layers on their own including Godot (and their custom shading language), [SDL's recently announced GPU abstraction layer](https://news.ycombinator.com/item?id=29203534), [sokol_gfx](https://github.com/floooh/sokol), and others including Blender3D which target varying native graphics APIs. These are admirable efforts, but come at great development costs.

Vulkan aims to be a cross-platform graphics API, but also requires abstraction layers like MoltenVK on Apple hardware and is often in practice too verbose for use by regular folks without at least one higher level abstraction layer (often the engine's rendering layer.) With a simpler API like Metal or D3D, however, one could stay closer to the underlying API without introducing as many abstraction layers on top and perhaps make smarter choices as a result.

With Mach, we'd rather focus on building the interesting and innovative bits of an engine rather than burning years on yet-another-graphics-abstraction-layer.

## Behind the scenes

`mach/gpu` is an idiomatic Zig interface to [the next-generation WebGPU API](https://www.w3.org/TR/webgpu/), which supersedes WebGL and exposes the common denominator between the latest low-level graphics APIs (Vulkan, Metal, D3D12) in the web.

Despite its name, [WebGPU was also built with native support in mind](http://kvark.github.io/web/gpu/native/2020/05/03/point-of-webgpu-native.html) and has substantial investment from Mozilla, Google, Microsoft, Intel, and, critically, Apple:

![](https://user-images.githubusercontent.com/3173176/137647342-abf2bde6-a8bb-4276-b072-95c279c5d92f.png)

When targeting WebAssembly, `mach/gpu` merely calls into the browser's native WebGPU implementation.

When targeting native platforms, we build Google Chrome's WebGPU implementation, [Dawn](https://dawn.googlesource.com/dawn), bypassing the client-server sandboxing model and use `zig build` (plus a lot of hand-holding) to support zero-fuss cross compilation & installation without any third-party Google tools, libraries, etc. Just `zig` and `git` needed, nothing else.

[Read more about why we believe WebGPU may be the future of graphics here](https://devlog.hexops.com/2021/mach-engine-the-future-of-graphics-with-zig#truly-cross-platform-graphics-api)

## WebGPU version

The interface and all documentation corresponds to the spec found at:

https://github.com/gpuweb/gpuweb/tree/main/spec

Revision: 3382f327520b4bcd5ea617fa7e7fe60e214f0d96

Tracking this enables us to diff the spec and keep our interface up to date.
