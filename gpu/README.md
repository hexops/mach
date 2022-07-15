# mach/gpu, cross-platform GPU API for Zig <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/master/readme.svg"></img></a>

`mach/gpu` provides a truly cross-platform graphics API (desktop, mobile, and web) with unified low-level graphics & compute backed by Vulkan, Metal, D3D12, and OpenGL (as a best-effort fallback.)

![](https://user-images.githubusercontent.com/3173176/137646296-72ba698e-c710-4daf-aa75-222f8d717d00.png)

## Features

* Desktop, (future) mobile, and web support.
* A modern graphics API similar to Metal, Vulkan, and DirectX 12. 
* Cross-platform shading language
* Compute shaders
* Cross-compilation & no fuss installation, using `zig build`, as with all Mach libraries.
* Advanced GPU features where hardware support is available, such as:
  * Depth buffer clip control
  * Special depth/stencil format with 32 bit floating point depth and 8 bits integer stencil.
  * Timestamp queries
  * Pipeline statistics queries
  * Texture compression (BC, ETC2, and ASTC)
  * Indirect first-instance
  * Depth clamping
  * Shader 16-bit float support
  * Multi planar formats

## A different approach to graphics API abstraction

Most engines today (Unreal, Unity, Godot, etc.) maintain their own GPU abstraction layer over native graphics APIs at great expense, requiring years of development and ongoing maintenance.

Many are attempting graphics abstraction layers on their own including Godot (and their custom shading language), [SDL's recently announced GPU abstraction layer](https://news.ycombinator.com/item?id=29203534), [sokol_gfx](https://github.com/floooh/sokol), and others including Blender3D which target varying native graphics APIs on their own. These are admirable efforts, but cost a great deal of effort.

Vulkan aims to be a cross-platform graphics API, but also requires abstraction layers like MoltenVK on Apple hardware and is often in practice too verbose for use by mere mortals without at least one higher level abstraction layer (often the engine's rendering layer.) With a more refined API that acts as the union of Vulkan/Metal/D3D APIs, we believe one could stay closer to the underlying API without introducing as many abstractions on top and perhaps make smarter choices as a result.

With Mach, we'd rather focus on building the interesting and innovative bits of an engine rather than burning years on yet-another-graphics-abstraction-layer, and so..

## WebGPU / Dawn for Zig

`mach/gpu` is a zero-cost idiomatic Zig interface to [the next-generation WebGPU API](https://www.w3.org/TR/webgpu/), which supersedes WebGL and exposes the common denominator between the latest low-level graphics APIs (Vulkan, Metal, D3D12) in the web.

Despite its name, [WebGPU was built with native support in mind](http://kvark.github.io/web/gpu/native/2020/05/03/point-of-webgpu-native.html) and has substantial investment from Mozilla, Google, Microsoft, Intel, and Apple.

When targeting WebAssembly, `mach/gpu` merely calls into the browser's native WebGPU implementation.

When targeting native platforms, we build Google Chrome's WebGPU implementation, [Dawn](https://dawn.googlesource.com/dawn) using Zig as the C/C++ compiler toolchain. We bypass the client-server sandboxing model, and use `zig build` (plus a lot of hand-holding) to support zero-fuss cross compilation & installation without any third-party Google tools, libraries, etc. Just `zig` and `git` needed, nothing else.

[Read more about why we believe WebGPU may be the future of graphics here](https://devlog.hexops.com/2021/mach-engine-the-future-of-graphics-with-zig#truly-cross-platform-graphics-api)

## Usage

`mach/gpu` can be used in three ways:

### "I want to do everything myself"

See `examples/main.zig` - note that this is complex, involves creating a window yourself, using Dawn's API to create a device and bind it to the window, use OS-specific APIs to get the window handle, etc.

### "I want a Window, input & the WebGPU API - nothing else."

**Mach core** provides this:

* Mach handles creating a window and giving you user input for every OS (desktop, mobile & web.)
* You give Mach an `init`, `deinit` and `update` function for your app which will be called every frame.
* You'll have access to the WebGPU API, and nothing else.

### "I want a full engine"

See https://machengine.org

### Examples & Learning aterial

Check out https://machengine.org/gpu

The following may also prove useful:

* Surma's compute article: https://surma.dev/things/webgpu/
* WebGPU Specification: https://gpuweb.github.io/gpuweb/
* WebGPU Explainer: https://gpuweb.github.io/gpuweb/explainer/

## Join the community

Join the Mach engine community [on Matrix chat](https://matrix.to/#/#hexops:matrix.org) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Agpu).

## Contributing

Contributions are very welcome. Pull requests must be sent to [the main repository](https://github.com/hexops/mach/tree/main/gpu) to avoid some complex merge conflicts we'd get by accepting contributions in both repositories. Once the changes are merged there, they'll get sync'd to this repository automatically.

## WebGPU version

Dawn's `webgpu.h` is the authoritative source for our API. You can find [the current version we use here](https://github.com/hexops/dawn/blob/generated-2022-07-10/out/Debug/gen/webgpu-headers/webgpu.h).

When updating, every single change is verified against [the WebGPU spec itself](https://github.com/gpuweb/gpuweb/tree/main/spec) to ensure our WebAssembly backend also functions effectively.

The rules for translating `webgpu.h` are as follows:

* `WGPUBuffer` -> `gpu.Buffer`:
  * Handles like these become a `pub const Buffer = enum(usize) {_}` to ensure they are still pointers compatible with the C ABI, while still allowing us to declare methods on them.
  * As a result, `null` is represented as `gpu.Buffer.none` which is defined as `pub const none: Buffer = @intToEnum(Buffer, 0);` iff the type can be nullable.g
* `WGPUBufferBindingType` -> `gpu.Buffer.BindingType` (purely because it's prefix matches an opaque pointer type, it thus goes into that file.)
* Reserved Zig keywords:
  * `undefined` -> `undef`
  * `null` -> `nul`
  * `error` -> `err`
* Constant names map using a few simple rules, but it's easiest to describe them with some concrete examples:
  * `RG11B10Ufloat -> rg11_b10_ufloat`
  * `Depth24PlusStencil8 -> depth24_plus_stencil8`
  * `BC5RGUnorm -> bc5_rg_unorm`
  * `BC6HRGBUfloat -> bc6_hrgb_ufloat`
  * `ASTC4x4UnormSrgb -> astc4x4_unorm_srgb`
* Sometimes an enum will begin with numbers, e.g. `WGPUTextureViewDimension_2DArray`. In this case, we add a prefix so instead of the enum field being `2d_array` it is `dimension_2d_array` (an enum field name must not start with a number in Zig.)
