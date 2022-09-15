# mach/trimesh2d - simple polygon triangulation in linear time

Converts 'simple' polygons (i.e. no holes) into triangle meshes in linear time using a modern earcut algorithm that works in linear time and has proven correctness.

This is a Zig implementation of the paper:

> "_[Deterministic Linear Time Constrained Triangulation using Simplified Earcut](https://arxiv.org/abs/2009.04294)_" - Marco Livesu, Gianmarco Cherchi, Riccardo Scateni, Marco Attene, 2020.
> IEEE Transactions on Visualization and Computer Graphics, 2021. [arXiv:2009.04294](https://arxiv.org/abs/2009.04294)

(This repository is a separate copy of the same library in the [main Mach repository](https://github.com/hexops/mach), and is automatically kept in sync, so that anyone can use this library in their own project if they like!)

## Getting started

### Adding dependency

In a `libs` subdirectory of the root of your project:

```sh
git clone https://github.com/hexops/mach-trimesh2d
```

Then in your `build.zig` add:

```zig
...
const trimesh2d = @import("libs/mach-trimesh2d/build.zig");

pub fn build(b: *Builder) void {
    ...
    exe.addPackage(trimesh2d.pkg);
}
```

### Usage

```zig
const trimesh2d = @import("trimesh2d");

pub fn main() {
    const allocator = std.heap.page_allocator;

    var polygon = std.ArrayListUnmanaged(f32){};
    // append your polygon vertices:
    // try polygon.append(1.0);

    var out_triangles = std.ArrayListUnmanaged(u32){};
    var processor = trimesh2d.Processor(f32){};
    defer processor.deinit(allocator);

    // Process a polygon.
    try processor.process(allocator, polygon, &out_triangles);

    // out_triangles has indices into polygon.items of our triangle vertices.
    // If desired, call .reset() and call .process() again! Internal buffers will be reused.
}
```

## Join the community

Join the Mach community [on Discord](https://discord.gg/XNG3NZgCqp) or [Matrix](https://matrix.to/#/#hexops:matrix.org) to discuss this project, ask questions, get help, etc.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Atrimesh2d).

## Contributing

Contributions are very welcome. Pull requests must be sent to [the main repository](https://github.com/hexops/mach/tree/main/trimesh2d) to avoid some complex merge conflicts we'd get by accepting contributions in both repositories. Once the changes are merged there, they'll get sync'd to this repository automatically.
