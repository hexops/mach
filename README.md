<a href="https://hexops.com/mach"><img alt="Mach - Game engine & graphics toolkit for the future" src="https://raw.githubusercontent.com/hexops/media/main/mach/logo_tagline_semi.svg"></img></a>

<h2 align="center">Learn more at <a href="https://hexops.com/mach">hexops.com/mach</a></h2>

## Join the conversation

Our community exists [on Matrix chat](https://matrix.to/#/#hexops:matrix.org), join in and help build the future of game engines & graphics in Zig!

You can also follow [@machengine on Twitter](https://twitter.com/machengine) for updates.

## ⚠️ in-development ⚠️

Under heavy development, not ready for use currently. 

## Supported platforms

Mach is still incredibly early stages, so far we have support for building from the following OS to the following targets:

| Building for     | From macOS x86_64 | From macOS M1/aarch64 | From Linux x86_64 | From Windows x86_64 |
|------------------|-------------------|-----------------------|-------------------|---------------------|
| macOS x86_64     | ✅                | ✅                     | ✅                | ✅                  |
| macOS M1/aarch64 | ✅                | ✅                     | ✅                | ✅                  |
| Linux x86_64     | ✅                | ✅                     | ✅                | ✅                  |
| Windows x86_64   | ✅                | ✅                     | ✅                | ✅                  |
| iOS              | 🏃                | 🏃                     | 🏃                | 🏃                  |
| Android          | 🏃                | 🏃                     | 🏃                | 🏃                  |

* ✅ Tested and verified via CI.
* ✔️ Should work, not tested via CI yet.
* 🏃 Planned or in progress.
* ⚠️ Implemented, but has known issues (e.g. bugs in Zig.)

## Subrepositories / projects

Whether you're interested in using all of Mach, or just some parts of it, you get to choose.
Our libraries all aim to have the same zero-fuss installation, cross compilation, and platform
support:

* [mach-glfw](https://github.com/hexops/mach-glfw): Ziggified GLFW bindings with 100% API coverage

## Contributing

Mach is maintained as a monorepo. When changed are merged to this repository, we use some git fu to pick out the commits to subdirectories and push them ot sub-repositories. For example, commits to the `glfw/` directory also get pushed to the separate [mach-glfw](https://github.com/hexops/mach-glfw) repository after being merged here.

There are only two requirements:

1. Pull requests to sub-repositories must be sent to this monorepo, not to the sub-repository itself - to avoid some annoying merge conflicts that can arise.
2. Individual commits may not change multiple sub-repositories at the same time (e.g. a commit to `glfw/` cannot also include changes to `gpu/`, to avoid confusion.)
