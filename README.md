<img alt="Mach - Game engine & graphics toolkit for the future" src="https://raw.githubusercontent.com/hexops/media/main/mach/logo_tagline_semi.svg"></img>

# Mach engine [![CI](https://github.com/hexops/engine/workflows/CI/badge.svg)](https://github.com/hexops/engine/actions) <a href="https://hexops.com"><img align="right" alt="Hexops logo" src="https://raw.githubusercontent.com/hexops/media/main/readme.svg"></img></a>

## ⚠️ Project status: in-development ⚠️

Under heavy development, not ready for use currently. [Follow @machengine on Twitter](https://twitter.com/machengine) for updates.

## Zero fuss installation & cross compilation

Mach is built from the ground up to support zero fuss installation & cross compilation, **only `zig` and `git` are needed to build from any OS and produce binaries for every OS.**

You do **not** need any system dependencies, C libraries, SDKs (Xcode, etc.), C compilers or anything else.

If you've ever worked with game engines in Go, Rust, or any other language you've probably run into issues at one point getting the right system dependencies installed, whether it be Xcode versions, compilers, X11/GLFW/SDL C dependencies, etc.

Mach is able to do this thanks to Zig being a C/C++ compiler, Zig's linker `zld` supporting macOS cross compilation, and us doing the heavy lifting of packaging the required [system SDK libraries](https://github.com/hexops/sdk-macos-11.3) and [C sources](glfw/upstream/) for every dependency we need so our Zig build scripts can simply `git clone` them for you as needed for the target OS you're building for, completely automagically.

## Supported platforms

Mach is still incredibly early stages, so far we have support for building from the following OS to the following targets:

| Building for     | From macOS x86_64 | From macOS M1/aarch64 | From Linux x86_64 | From Windows x86_64 |
|------------------|-------------------|-----------------------|-------------------|---------------------|
| macOS x86_64     | ✅                | ✅                     | ✅                | ⚠️ #8               |
| macOS M1/aarch64 | ✅                | ✅                     | ✅                | ⚠️ #8               |
| Linux x86_64     | 🏃                | 🏃                     | 🏃                | 🏃                  |
| Windows x86_64   | 🏃                | 🏃                     | 🏃                | ✅                  |
| iOS              | 🏃                | 🏃                     | 🏃                | 🏃                  | 
| Android          | 🏃                | 🏃                     | 🏃                | 🏃                  | 

* ✅ Tested and verified via CI.
* ✔️ Should work, not tested via CI yet.
* 🏃 Planned or in progress.
* ⚠️ Implemented, but has known issues (e.g. bugs in Zig.)
