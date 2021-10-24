# mach/glfw - Ziggified GLFW bindings [![CI](https://github.com/hexops/engine/workflows/CI/badge.svg)](https://github.com/hexops/engine/actions) <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/main/readme.svg"></img></a>

Ziggified GLFW bindings that [Mach engine](https://github.com/hexops/mach) uses, with 100% API coverage, zero-fuss installation, cross compilation, and more.

The [main Mach repository](https://github.com/hexops/mach) includes [this one](https://github.com/hexops/mach-glfw) as a `git subtree`. This is a separate repo so that anyone can use this library in their own project / engine if they like!

## Zero fuss installation, cross compilation, and more

[Just as with Mach](https://github.com/hexops/mach#zero-fuss-installation--cross-compilation), you get zero fuss installation & cross compilation using these GLFW bindings. **only `zig` and `git` are needed to build from any OS and produce binaries for every OS.** No system dependencies at all.

See also: [platform support table](https://github.com/hexops/mach#supported-platforms)

## 100% API coverage

These bindings recently achieved 100% API coverage of GLFW v3.3.4. Every function, type, etc. has been wrapped in a ziggified API.

## What does a ziggified GLFW API offer?

You could just `@cImport` GLFW with Zig - the main reasons to use a ziggified wrapper though are because you get:

* `true` and `false` booleans instead of `c.GLFW_TRUE` and `c.GLFW_FALSE` integers
* Methods, so you can write e.g. `window.hint` instead of `glfwWindowHint`
* Generics, so you can just use `window.hint` instead of `glfwWindowHint`, `glfwWindowHintString`, etc.
* Enums, so you can write `window.getKey(.escape)` instead of `c.glfwGetKey(window, c.GLFW_KEY_ESCAPE)`
* Slices instead of C pointers and lengths.
* [`packed struct`](https://ziglang.org/documentation/master/#packed-struct) to represent bit masks, so you can interact with each bit the same way you'd interact with a `bool` if you like, instead of remembering the `&` `|` `^` incantation (although you're free to do that too.)

## How do I use OpenGL, Vulkan, WebGPU, etc. with this?

You'll need to bring your own library for this. Some are:

* (Vulkan) https://github.com/Snektron/vulkan-zig (also see https://github.com/Avokadoen/zig_vulkan)
* (OpenGL) https://github.com/ziglibs/zgl

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Aglfw).

## Contributing

Contributions are very welcome. Just send a PR to this repository.

We track the latest stable release of GLFW, if you need a newer version we can start a development branch / figure that out - just open an issue.

Once your PR is merged, if you're using Mach engine and wanting the changes there, it will be sync'd to the main repo via `git subtree`.
