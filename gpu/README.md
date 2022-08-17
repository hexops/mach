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

## Goals

* Allow comptime-defined interception of WebGPU API requests (comptime interfaces.)
* Expose a standard Dawn `webgpu.h`-compliant C ABI, which routes through comptime interfaces.
* Support Dawn and Browser (via WASM/JS) implementations of WebGPU.

## Non-goals

* Support non-Dawn (e.g. Rust WebGPU) implementations if they don't match the same `webgpu.h` as Dawn.
* Maintain backwards compatibility with deprecated `webgpu.h` methods.

## WebGPU version

Dawn's `webgpu.h` is the authoritative source for our API. You can find [the current version we use here](https://github.com/hexops/dawn/blob/generated-2022-07-10/out/Debug/gen/include/dawn/webgpu.h).

When updating, every single change is verified against [the WebGPU spec itself](https://github.com/gpuweb/gpuweb/tree/main/spec) to ensure our WebAssembly backend also functions effectively.

The rules for translating `webgpu.h` are as follows:

* `WGPUBuffer` -> `gpu.Buffer`:
  * Opaque pointers like these become a `pub const Buffer = opaque {_}` to ensure they are still pointers compatible with the C ABI, while still allowing us to declare methods on them.
  * As a result, a `null`able `Buffer` is represented simply as `?*Buffer`, and any function that would normally take `WGPUBuffer` now takes `*Buffer` as a parameter.
* `WGPUBufferBindingType` -> `gpu.Buffer.BindingType` (purely because it's prefix matches an opaque pointer type, it thus goes into the `Buffer` opaque type.)
* Reserved Zig keywords are translated as follows:
  * `undefined` -> `undef`
  * `null` -> `nul`
  * `error` -> `err`
  * `type` -> `typ`
  * `opaque` -> `opaq`
* Undefined in Zig commonly means _undefined memory_. WebGPU however uses _undefined_ as terminology to indicate something was not _specified_, as the optional _none value_, which Zig represents as _null_. Since _null_ is a reserved keyword in Zig, we rename all WebGPU _undefined_ terminology to "_unspecified_" instead.
* Constant names map using a few simple rules, but it's easiest to describe them with some concrete examples:
  * `RG11B10Ufloat -> rg11_b10_ufloat`
  * `Depth24PlusStencil8 -> depth24_plus_stencil8`
  * `BC5RGUnorm -> bc5_rg_unorm`
  * `BC6HRGBUfloat -> bc6_hrgb_ufloat`
  * `ASTC4x4UnormSrgb -> astc4x4_unorm_srgb`
  * `maxTextureDimension3D -> max_texture_dimension_3d`
* Sometimes an enum will begin with numbers, e.g. `WGPUTextureViewDimension_2DArray`. In this case, we add a prefix so instead of the enum field being `2d_array` it is `dimension_2d_array` (an enum field name must not start with a number in Zig.)
* Dawn extension types `WGPUDawnFoobar` are placed under `gpu.dawn.Foobar`
* Regarding _"undefined"_ terminology:
  * In Zig, _undefined_ usually means _undefined memory_, _undefined behavior_, etc.
  * In WebGPU, _undefined_ commonly refers to JS-style undefined: _an optional value that was not specified_
  * Zig refers to optional values not specified as _null_, but _null_ is a reserved keyword and so can't be used.
  * We could use "_none_", but "BindingType none" and "BindingType not specified" clearly have non-equal meanings.
  * As a result of all this, we translate _"undefined"_ in WebGPU to "undef" in Zig: it has no overlap with the reserved _undefined_ keyword, and distinguishes its meaning.

## Quality of life improvements

We make the following quality of life improvements.

### Flag sets

TODO: explain it

### Optionality & nullability

* Optional values default to their zero value (either `null` or a struct constructor `.{}`) when specified as `optional` in `dawn.json`. This means things like `label`, `next_in_chain`, etc. do not need to be specified.
* Fields representing a slice with a `_count` field are nullable pointers defaulting to null and 0 by default.

### Slice helpers

Some WebGPU APIs expose slices as pointers and lengths, we either wrap these to provide a slice or alter the method directly to provide a slice (if little overhead.) The original C-style API can always be accessed via the `gpu.Impl` type in any case.

The slice helpers are:

* `Adapter.enumerateFeaturesOwned`
* `Buffer.getConstMappedRange`
* `Buffer.getMappedRange`
* `CommandEncoder.writeBuffer`
* `ComputePassEncoder.setBindGroup`
* `Device.enumerateFeaturesOwned`
* `Queue.writeTexture`
* `Queue.writeBuffer`
* `RenderPassEncoder.executeBundles`
* `RenderBundleEncoder.setBindGroup`
* `RenderPassEncoder.setBindGroup`

And, to initialize data structures with slices in them, the following helpers are provided:

* `BindGroupLayout.Descriptor.init`
* `BindGroup.Descriptor.init`
* `InstanceDescriptor.init`
* `TogglesDeviceDescriptor.init`
* `Device.Descriptor.init`
* `PipelineLayout.Descriptor.init`
* `QuerySet.Descriptor.init`
* `RenderBundleEncoder.Descriptor.init`
* `Texture.Descriptor.init`
* `ComputePassDescriptor.init`
* `RenderPassDescriptor.init`
* `ProgrammableStageDescriptor.init`

### Typed callbacks

Most WebGPU callbacks provide a way to provide a `userdata: *anyopaque` pointer to the callback for context. We alter these APIs to expose a typed context pointer instead (again, the original API is always available via the `gpu.Impl` type should you want it):

* `Instance.requestAdapter`
* `Adapter.requestDevice`
* `Queue.onSubmittedWorkDone`
* `Buffer.mapAsync`
* `ShaderModule.getCompilationInfo`
* `Device.createComputePipelineAsync`
* `Device.createRenderPipelineAsync`
* `Device.popErrorScope`
* `Device.setDeviceLostCallback`
* `Device.setLoggingCallback`
* `Device.setUncapturedErrorCallback`

### next_in_chain extension type safety

WebGPU exposes struct types which are extendable arbitrarily, often by implementation-specific extensions. For example:

```zig
const extension = gpu.Surface.DescriptorFromWindowsHWND{
  .chain = gpu.ChainedStruct{.next = null, .s_type = .surface_descriptor_from_windows_hwnd},
  .hinstance = foo,
  .hwnd = bar,
}
const descriptor = gpu.Surface.Descriptor{
  .next_in_chain = @ptrCast(?*const ChainedStruct, &extension),
};
```

Here `gpu.Surface.Descriptor` is a concrete type. The `next_in_chain` field is set to an arbitrary pointer which follows the `gpu.ChainedStruct` pattern: it must begin with a `gpu.ChainedStruct` where the `s_type` identifies which fields may follow after, and `.next` could theoretically chain more extensions on too.

Complexity aside, `next_in_chain` is not type safe! It cannot be, because such an extension could be implementation-specific. To make this safer, we instead change the `next_in_chain` field type to be a union, where one option is the type-unsafe `generic` pointer, and the other options are known extensions:

```zig
pub const Extension = extern union {
    generic: ?*const ChainedStruct,
    from_windows_hwnd: *const DescriptorFromWindowsHWND,
    // ...
};
```

Additionally we initialize `.chain` with a default value, making our earlier snippet look like this in most cases:

```zig
const descriptor = gpu.Surface.Descriptor{
  .next_in_chain = .{.from_windows_hwnd = &.{
    .hinstance = foo,
    .hwnd = bar,
  }},
}
```

### Others

There may be other opportunities for helpers, to improve the existing APIs, or add utility APIs on top of the existing APIs. If you find one, please open an issue we'd love to hear it!

The following are definitive candidates for helpers we haven't implemented yet:

* Other `next_in_chain` extensions (marked with a `// TODO` already)
