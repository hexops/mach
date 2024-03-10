const builtin = @import("builtin");
const std = @import("std");
const testing = @import("testing.zig");

// TODO: eliminate dependency on ECS here.
const EntityID = @import("ecs/entities.zig").EntityID;

/// Verifies that T matches the basic layout of a Mach module
pub fn Module(comptime T: type) type {
    if (@typeInfo(T) != .Struct) @compileError("Module must be a struct type. Found:" ++ @typeName(T));
    if (!@hasDecl(T, "name")) @compileError("Module must have `pub const name = .foobar;`");
    if (@typeInfo(@TypeOf(T.name)) != .EnumLiteral) @compileError("Module must have `pub const name = .foobar;`, found type:" ++ @typeName(T.name));
    if (@hasDecl(T, "components")) {
        if (@typeInfo(T.components) != .Struct) @compileError("Module.components must be `pub const components = struct { ... };`, found type:" ++ @typeName(T.components));
    }
    return T;
}

// Manages comptime .{A, B, C} modules and runtime modules.
pub fn Modules(comptime mods: anytype) type {
    // Verify that each module is valid.
    inline for (mods) |M| _ = Module(M);

    return struct {
        /// Comptime modules
        pub const modules = mods;

        pub const components = NamespacedComponents(mods){};
        pub const State = NamespacedState(mods);

        // TODO: add runtime module support

        pub fn init(m: *@This(), allocator: std.mem.Allocator) !void {
            m.* = .{};
            _ = allocator;
        }

        pub fn deinit(m: *@This(), allocator: std.mem.Allocator) void {
            _ = m;
            _ = allocator;
        }

        inline fn call(event_name: EventName(mods), args: anytype) void {
            switch (event_name) {
                inline else => |name| {
                    inline for (modules) |M| {
                        if (@hasDecl(M, @tagName(name))) {
                            switch (@typeInfo(@TypeOf(@field(M, @tagName(name))))) {
                                .Fn => {
                                    const handler = @field(M, @tagName(name));
                                    callHandler(handler, args);
                                },
                                else => {},
                            }
                        }
                    }
                },
            }
        }

        inline fn callHandler(handler: anytype, args: anytype) void {
            @call(.auto, handler, args);
        }
    };
}

/// enum describing every possible comptime-known event name
fn EventName(comptime mods: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    for (mods) |M| {
        // Global event handlers
        for (@typeInfo(M).Struct.decls) |decl| {
            switch (@typeInfo(@TypeOf(@field(M, decl.name)))) {
                .Fn => {
                    const exists_already = blk2: {
                        for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, decl.name)) break :blk2 true;
                        break :blk2 false;
                    };
                    if (!exists_already) {
                        enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = decl.name, .value = i }};
                        i += 1;
                    }
                },
                else => {},
            }
        }

        // Local event handlers
        if (@hasDecl(M, "local")) {
            for (@typeInfo(M.local).Struct.decls) |decl| {
                switch (@typeInfo(@TypeOf(@field(M.local, decl.name)))) {
                    .Fn => {
                        const exists_already = blk2: {
                            for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, decl.name)) break :blk2 true;
                            break :blk2 false;
                        };
                        if (!exists_already) {
                            enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = decl.name, .value = i }};
                            i += 1;
                        }
                    },
                    else => {},
                }
            }
        }
    }
    return @Type(.{
        .Enum = .{
            .tag_type = std.math.IntFittingRange(0, enum_fields.len - 1),
            .fields = enum_fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_exhaustive = true,
        },
    });
}

fn NamespacedComponents(comptime modules: anytype) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    inline for (modules) |M| {
        const components = if (@hasDecl(M, "components")) M.components else struct {};
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = @tagName(M.name),
            .type = type,
            .default_value = &components,
            .is_comptime = true,
            .alignment = @alignOf(@TypeOf(components)),
        }};
    }

    // Builtin components
    const entity_components = struct {
        pub const id = EntityID;
    };
    fields = fields ++ [_]std.builtin.Type.StructField{.{
        .name = "entity",
        .type = type,
        .default_value = &entity_components,
        .is_comptime = true,
        .alignment = @alignOf(@TypeOf(entity_components)),
    }};

    return @Type(.{
        .Struct = .{
            .layout = .Auto,
            .is_tuple = false,
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
        },
    });
}

fn NamespacedState(comptime modules: anytype) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    inline for (modules) |M| {
        const state_fields = std.meta.fields(M);
        const State = if (state_fields.len > 0) @Type(.{
            .Struct = .{
                .layout = .Auto,
                .is_tuple = false,
                .fields = state_fields,
                .decls = &[_]std.builtin.Type.Declaration{},
            },
        }) else struct {};
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = @tagName(M.name),
            .type = State,
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(State),
        }};
    }
    return @Type(.{
        .Struct = .{
            .layout = .Auto,
            .is_tuple = false,
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
        },
    });
}

test {
    testing.refAllDeclsRecursive(@This());
}

test Module {
    _ = Module(struct {
        // Physics module state
        pointer: usize,

        // Globally unique module name
        pub const name = .engine_physics;

        /// Physics module components
        pub const components = struct {
            /// A location component
            pub const location = @Vector(3, f32);
        };

        pub fn tick() !void {}
    });
}

test Modules {
    const Physics = Module(struct {
        // Physics module state
        pointer: usize,

        // Globally unique module name
        pub const name = .engine_physics;

        /// Physics module components
        pub const components = struct {
            /// A location component
            pub const location = @Vector(3, f32);
        };

        pub fn tick() !void {}
    });

    const Renderer = Module(struct {
        pub const name = .engine_renderer;

        /// Renderer module components
        pub const components = struct {};

        pub fn tick() !void {}
    });

    const Sprite2D = Module(struct {
        pub const name = .engine_sprite2d;
    });

    var modules: Modules(.{
        Physics,
        Renderer,
        Sprite2D,
    }) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);
    testing.refAllDeclsRecursive(Physics);
    testing.refAllDeclsRecursive(Renderer);
    testing.refAllDeclsRecursive(Sprite2D);

    // access namespaced components
    try testing.expect(type, Physics.components.location).eql(@TypeOf(modules).components.engine_physics.location);
    try testing.expect(type, Renderer.components).eql(@TypeOf(modules).components.engine_renderer);

    // implicitly generated
    _ = @TypeOf(modules).components.entity.id;
}

test EventName {
    const Physics = Module(struct {
        pub const name = .engine_physics;
        pub const components = struct {};

        pub fn foo() !void {}
        pub fn bar() !void {}

        pub const local = struct {
            pub fn baz() !void {}
            pub fn bam() !void {}
        };
    });

    const Renderer = Module(struct {
        pub const name = .engine_renderer;
        pub const components = struct {};

        pub fn tick() !void {}
        pub fn foo() !void {} // same .foo name as .engine_physics.foo
        pub fn bar() !void {} // same .bar name as .engine_physics.bar
    });

    const Sprite2D = Module(struct {
        pub const name = .engine_sprite2d;

        pub fn tick() void {} // same .tick as .engine_renderer.tick
        pub const local = struct {
            pub fn foobar() void {}
        };
    });

    const Mods = Modules(.{
        Physics,
        Renderer,
        Sprite2D,
    });
    const info = @typeInfo(EventName(Mods.modules)).Enum;

    try testing.expect(type, u3).eql(info.tag_type);
    try testing.expect(usize, 6).eql(info.fields.len);
    try testing.expect([]const u8, "foo").eql(info.fields[0].name);
    try testing.expect([]const u8, "bar").eql(info.fields[1].name);
    try testing.expect([]const u8, "baz").eql(info.fields[2].name);
    try testing.expect([]const u8, "bam").eql(info.fields[3].name);
    try testing.expect([]const u8, "tick").eql(info.fields[4].name);
    try testing.expect([]const u8, "foobar").eql(info.fields[5].name);
}

test "event name calling" {
    // TODO: verify that event handlers error return signatures are correct
    const global = struct {
        var ticks: usize = 0;
        var physics_updates: usize = 0;
        var renderer_updates: usize = 0;
    };
    const Physics = Module(struct {
        pub const name = .engine_physics;
        pub const components = struct {};

        pub fn tick() void {
            global.ticks += 1;
        }

        pub const local = struct {
            pub fn update() void {
                global.physics_updates += 1;
            }
        };
    });
    const Renderer = Module(struct {
        pub const name = .engine_physics;
        pub const components = struct {};

        pub fn tick() void {
            global.ticks += 1;
        }

        pub const local = struct {
            pub fn update() void {
                global.renderer_updates += 1;
            }
        };
    });

    var modules: Modules(.{
        Physics,
        Renderer,
    }) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);

    @TypeOf(modules).call(.tick, .{});
    try testing.expect(usize, 2).eql(global.ticks);

    // Check we can use .call() with a runtime-known value.
    const alloc = try testing.allocator.create(u3);
    defer testing.allocator.destroy(alloc);
    const E = EventName(@TypeOf(modules).modules);
    alloc.* = @intFromEnum(@as(E, .tick));

    var event_name = @as(E, @enumFromInt(alloc.*));
    @TypeOf(modules).call(event_name, .{});
    try testing.expect(usize, 4).eql(global.ticks);

    // Now check call() with a valid enum, but not a valid global event handler
    alloc.* = @intFromEnum(@as(E, .update));
    event_name = @as(E, @enumFromInt(alloc.*));
    @TypeOf(modules).call(event_name, .{});
    try testing.expect(usize, 4).eql(global.ticks);
    try testing.expect(usize, 0).eql(global.physics_updates);
    try testing.expect(usize, 0).eql(global.renderer_updates);
}
