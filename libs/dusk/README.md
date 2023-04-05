# mach/dusk - WebGPU implementation in Zig

This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project if they like!

## Experimental

This is an _experimental_ Mach library, according to our [stability guarantees](https://machengine.org/next/docs/libs/):

> Experimental libraries may have their APIs change without much notice, and you may have to look at recent changes in order to update your code.

[Why this library is not declared stable yet](https://machengine.org/next/docs/libs/experimental/#dusk)

## Current Status

Dusk is in **very early stages** and under heavy development; there are hundreds of known bugs/missing features.

### WGSL compiler

- [x] Parser
- [ ] Ast analysis (WIP!)
- [ ] Transpilation targets
    - [ ] GLSL
    - [ ] Spir-V
    - [ ] HLSL
    - [ ] Metal

## Join the community

Join the Mach community [on Discord](https://discord.gg/XNG3NZgCqp) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Adusk).

## Contributing

Contributions are very welcome. Pull requests must be sent to [the main repository](https://github.com/hexops/mach/tree/main/libs/dusk) to avoid some complex merge conflicts we'd get by accepting contributions in both repositories. Once the changes are merged there, they'll get sync'd to this repository automatically.
