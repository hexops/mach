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

// TODO: implement serialization constraints
// For now this exists just to indicate things that we expect will be required to be serializable in
// the future.
fn Serializable(comptime T: type) type {
    return T;
}

/// Manages comptime .{A, B, C} modules and runtime modules.
pub fn Modules(comptime mods: anytype, comptime Injectable: type) type {
    // Verify that each module is valid.
    inline for (mods) |M| _ = Module(M);

    return struct {
        /// Comptime modules
        pub const modules = mods;

        pub const components = NamespacedComponents(mods){};
        pub const State = NamespacedState(mods);

        // TODO: add runtime module support

        pub const ModuleID = u32;
        pub const EventID = u32;

        const Event = struct {
            module_name: ?ModuleID,
            event_name: EventID,
            args_slice: []u8,
        };
        const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);

        events_mu: std.Thread.RwLock = .{},
        args_queue: std.ArrayListUnmanaged(u8) = .{},
        events: EventQueue,

        pub fn init(m: *@This(), allocator: std.mem.Allocator) !void {
            // TODO: custom event queue allocation sizes
            m.* = .{
                .args_queue = try std.ArrayListUnmanaged(u8).initCapacity(allocator, 8 * 1024 * 1024),
                .events = EventQueue.init(allocator),
            };
            errdefer m.args_queue.deinit(allocator);
            errdefer m.events.deinit();
            try m.events.ensureTotalCapacity(1024);
        }

        pub fn deinit(m: *@This(), allocator: std.mem.Allocator) void {
            m.args_queue.deinit(allocator);
            m.events.deinit();
        }

        /// Returns an args tuple representing the standard, uninjected, arguments which the given
        /// local event handler requires.
        fn LocalArgs(module_name: ModuleName(mods), event_name: EventName(mods)) type {
            const M = @field(NamespacedModules(@This().modules){}, @tagName(module_name));
            const handler = @field(M.local, @tagName(event_name));
            switch (@typeInfo(@TypeOf(handler))) {
                .Fn => return UninjectedArgsTuple(@TypeOf(handler), Injectable),
                // Note: This means the module does have some other field by the same name, but it is not a function.
                else => @compileError("Module " ++ @tagName(M.name) ++ " has no global event handler " ++ @tagName(event_name)),
            }
        }

        /// Returns an args tuple representing the standard, uninjected, arguments which the given
        /// global event handler requires.
        ///
        /// If the returned type would differ from EventArgs, a compile-time error will occur.
        ///
        /// If no module currently has a global event handler of this name, then its argument type
        /// is currently undefined and assumed to be EventArgs.
        fn Args(comptime EventArgs: type, event_name: EventName(mods)) type {
            inline for (modules) |M| {
                if (@hasDecl(M, @tagName(event_name))) {
                    switch (@typeInfo(@TypeOf(@field(M, @tagName(event_name))))) {
                        .Fn => {
                            const handler = @field(M, @tagName(event_name));
                            // TODO: worth checking if the return type is == EventArgs here? Could
                            // that lead to better UX?
                            return UninjectedArgsTuple(@TypeOf(handler), Injectable);
                        },
                        else => {},
                    }
                }
            }
            return EventArgs;
        }

        /// Send a global event
        pub fn send(
            m: *@This(),
            // TODO: is a variant of this function where event_name is not comptime known, but asserted to be a valid enum, useful?
            comptime event_name: EventName(mods),
            comptime EventArgs: type,
            args: Args(EventArgs, event_name),
        ) void {
            // TODO: comptime safety/debugging
            m.sendInternal(null, @intFromEnum(event_name), args);
        }

        /// Send an event to a specific module
        pub fn sendToModule(
            m: *@This(),
            // TODO: is a variant of this function where module_name/event_name is not comptime known, but asserted to be a valid enum, useful?
            comptime module_name: ModuleName(mods),
            comptime event_name: EventName(mods),
            args: LocalArgs(module_name, event_name),
        ) void {
            // TODO: comptime safety/debugging
            m.sendInternal(@intFromEnum(module_name), @intFromEnum(event_name), args);
        }

        /// Send a global event, using a dynamic (not known to the compiled program) event name.
        pub fn sendDynamic(m: *@This(), event_name: EventID, args: anytype) void {
            // TODO: runtime safety/debugging
            // TODO: check args do not have obviously wrong things, like comptime values
            // TODO: if module_name and event_name are valid enums, can we type-check args at comptime?
            m.sendInternal(null, event_name, args);
        }

        /// Send an event to a specific module, using a dynamic (not known to the compiled program) module and event name.
        pub fn sendToModuleDynamic(m: *@This(), module_name: ModuleID, event_name: EventID, args: anytype) void {
            // TODO: runtime safety/debugging
            // TODO: check args do not have obviously wrong things, like comptime values
            // TODO: if module_name and event_name are valid enums, can we type-check args at comptime?
            m.sendInternal(module_name, event_name, args);
        }

        fn sendInternal(m: *@This(), module_name: ?ModuleID, event_name: EventID, args: anytype) void {
            // TODO: verify arguments are valid, e.g. not comptime types
            _ = Serializable(@TypeOf(args));

            // TODO: debugging
            m.events_mu.lock();
            defer m.events_mu.unlock();

            const args_bytes = std.mem.asBytes(&args);
            m.args_queue.appendSliceAssumeCapacity(args_bytes);

            m.events.writeItemAssumeCapacity(.{
                .module_name = module_name,
                .event_name = event_name,
                .args_slice = m.args_queue.items[m.args_queue.items.len - args_bytes.len .. args_bytes.len],
            });
        }

        /// Dispatches pending events, invoking their event handlers.
        pub fn dispatch(m: *@This(), injectable: Injectable) void {
            // TODO: verify injectable arguments are valid, e.g. not comptime types

            // TODO: optimize to reduce send contention
            // TODO: parallel / multi-threaded dispatch
            // TODO: PGO
            m.events_mu.lock();
            defer m.events_mu.unlock();

            while (m.events.readItem()) |ev| {
                if (ev.module_name) |module_name| {
                    // TODO: dispatch arguments
                    @This().callLocal(@enumFromInt(module_name), @enumFromInt(ev.event_name), ev.args_slice, injectable);
                } else {
                    // TODO: dispatch arguments
                    @This().call(@enumFromInt(ev.event_name), ev.args_slice, injectable);
                }
            }
            m.args_queue.clearRetainingCapacity();
        }

        /// Call global event handler with the specified name in all modules
        inline fn call(event_name: EventName(mods), args: []u8, injectable: anytype) void {
            switch (event_name) {
                inline else => |name| {
                    inline for (modules) |M| {
                        if (@hasDecl(M, @tagName(name))) {
                            switch (@typeInfo(@TypeOf(@field(M, @tagName(name))))) {
                                .Fn => {
                                    const handler = @field(M, @tagName(name));
                                    callHandler(handler, args, injectable);
                                },
                                else => {},
                            }
                        }
                    }
                },
            }
        }

        /// Call local event handler with the specified name in the specified module
        inline fn callLocal(module_name: ModuleName(mods), event_name: EventName(mods), args: []u8, injectable: anytype) void {
            // TODO: invert switch case for hypothetically better branch prediction
            switch (module_name) {
                inline else => |mod_name| {
                    switch (event_name) {
                        inline else => |ev_name| {
                            const M = @field(NamespacedModules(@This().modules){}, @tagName(mod_name));
                            // TODO: no need for hasDecl, assertion should be event can be sent at send() time.
                            if (@hasDecl(M.local, @tagName(ev_name))) {
                                const handler = @field(M.local, @tagName(ev_name));
                                switch (@typeInfo(@TypeOf(handler))) {
                                    .Fn => {
                                        callHandler(handler, args, injectable);
                                    },
                                    else => {},
                                }
                            }
                        },
                    }
                },
            }
        }

        /// Invokes an event handler with optionally injected arguments.
        inline fn callHandler(handler: anytype, args_data: []u8, injectable: Injectable) void {
            const StdArgs = UninjectedArgsTuple(@TypeOf(handler), Injectable);
            const std_args: *StdArgs = @alignCast(@ptrCast(args_data.ptr));
            const args = injectArgs(@TypeOf(handler), Injectable, injectable, std_args.*);
            @call(.auto, handler, args);
        }
    };
}

// Given a function, its standard arguments and injectable arguments, performs injection and
// returns the actual argument tuple which would be used to call the function.
inline fn injectArgs(
    comptime Function: type,
    comptime Injectable: type,
    injectable_args: Injectable,
    std_args: UninjectedArgsTuple(Function, Injectable),
) std.meta.ArgsTuple(Function) {
    var args: std.meta.ArgsTuple(Function) = undefined;
    comptime var std_args_index = 0;
    outer: inline for (@typeInfo(std.meta.ArgsTuple(Function)).Struct.fields) |arg| {
        // Injected arguments always go first, then standard (non-injected) arguments.
        if (std_args_index > 0) {
            @field(args, arg.name) = std_args[std_args_index];
            std_args_index += 1;
            continue;
        }

        // Is this argument matching the type of an argument we could inject?
        inline for (@typeInfo(Injectable).Struct.fields) |inject_field| {
            if (inject_field.type == arg.type and @alignOf(inject_field.type) == @alignOf(arg.type)) {
                // Inject argument
                @field(args, arg.name) = @field(injectable_args, inject_field.name);
                continue :outer;
            }
        }

        // First standard argument
        @field(args, arg.name) = std_args[std_args_index];
        std_args_index += 1;
    }
    return args;
}

// Given a function type, and an args tuple of injectable parameters, returns the set of function
// parameters which would **not** be injected.
fn UninjectedArgsTuple(comptime Function: type, comptime Injectable: type) type {
    var std_args: []const type = &[0]type{};
    inline for (@typeInfo(std.meta.ArgsTuple(Function)).Struct.fields) |arg| {
        // Injected arguments always go first, then standard (non-injected) arguments.
        if (std_args.len > 0) {
            std_args = std_args ++ [_]type{arg.type};
            continue;
        }
        // Is this argument matching the type of an argument we could inject?
        const injectable = blk: {
            inline for (@typeInfo(Injectable).Struct.fields) |inject| {
                if (inject.type == arg.type and @alignOf(inject.type) == arg.alignment) {
                    break :blk true;
                }
            }
            break :blk false;
        };
        if (injectable) continue; // legitimate injected argument, ignore it
        std_args = std_args ++ [_]type{arg.type};
    }
    return std.meta.Tuple(std_args);
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

/// enum describing every possible comptime-known module name
fn ModuleName(comptime mods: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    for (mods, 0..) |M, i| {
        enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = @tagName(M.name), .value = i }};
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

/// Struct like .{.foo = FooMod, .bar = BarMod}
fn NamespacedModules(comptime modules: anytype) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    inline for (modules) |M| {
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = @tagName(M.name),
            .type = type,
            .default_value = &M,
            .is_comptime = true,
            .alignment = @alignOf(@TypeOf(M)),
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

// TODO: reconsider components concept
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

// TODO: reconsider state concept
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

    const Injectable = struct {};
    var modules: Modules(.{
        Physics,
        Renderer,
        Sprite2D,
    }, Injectable) = undefined;
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

    const Injectable = struct {};
    const Mods = Modules(.{
        Physics,
        Renderer,
        Sprite2D,
    }, Injectable);
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

test ModuleName {
    const Physics = Module(struct {
        pub const name = .engine_physics;
    });
    const Renderer = Module(struct {
        pub const name = .engine_renderer;
    });
    const Sprite2D = Module(struct {
        pub const name = .engine_sprite2d;
    });
    const Injectable = struct {};
    const Mods = Modules(.{
        Physics,
        Renderer,
        Sprite2D,
    }, Injectable);
    const info = @typeInfo(ModuleName(Mods.modules)).Enum;

    try testing.expect(type, u2).eql(info.tag_type);
    try testing.expect(usize, 3).eql(info.fields.len);
    try testing.expect([]const u8, "engine_physics").eql(info.fields[0].name);
    try testing.expect([]const u8, "engine_renderer").eql(info.fields[1].name);
    try testing.expect([]const u8, "engine_sprite2d").eql(info.fields[2].name);
}

const TupleTester = struct {
    fn assertTypeEqual(comptime Expected: type, comptime Actual: type) void {
        if (Expected != Actual) @compileError("Expected type " ++ @typeName(Expected) ++ ", but got type " ++ @typeName(Actual));
    }

    fn assertTuple(comptime expected: anytype, comptime Actual: type) void {
        const info = @typeInfo(Actual);
        if (info != .Struct) @compileError("Expected struct type");
        if (!info.Struct.is_tuple) @compileError("Struct type must be a tuple type");

        const fields_list = std.meta.fields(Actual);
        if (expected.len != fields_list.len) @compileError("Argument count mismatch");

        inline for (fields_list, 0..) |fld, i| {
            if (expected[i] != fld.type) {
                @compileError("Field " ++ fld.name ++ " expected to be type " ++ @typeName(expected[i]) ++ ", but was type " ++ @typeName(fld.type));
            }
        }
    }
};

test injectArgs {
    // Injected arguments should generally be *struct types to avoid conflicts with any user-passed
    // parameters, though we do not require it - so we test with other types here.
    var i: i32 = 1234;
    const i32_ptr: *i32 = &i;
    var f: f32 = 0.1234;
    const f32_ptr: *f32 = &f;
    const Foo = struct { foo: f32 };
    var foo: Foo = .{ .foo = 1234 };
    const foo_ptr: *Foo = &foo;

    // No standard, no injected
    try testing.expect(struct {}, .{}).eql(injectArgs(fn () void, @TypeOf(.{}), .{}, .{}));
    const injectable = .{ i32_ptr, f32_ptr, foo_ptr };
    try testing.expect(struct {}, .{}).eql(injectArgs(fn () void, @TypeOf(injectable), injectable, .{}));

    // Standard parameters only, no injected
    try testing.expect(std.meta.Tuple(&.{i32}), .{0}).eql(injectArgs(fn (a: i32) void, @TypeOf(injectable), injectable, .{0}));
    try testing.expect(std.meta.Tuple(&.{ i32, f32 }), .{ 1, 0.5 }).eql(injectArgs(fn (a: i32, b: f32) void, @TypeOf(injectable), injectable, .{ 1, 0.5 }));

    // Injected parameters only, no standard
    try testing.expect(std.meta.Tuple(&.{*i32}), .{i32_ptr}).eql(injectArgs(fn (a: *i32) void, @TypeOf(injectable), injectable, .{}));
    try testing.expect(std.meta.Tuple(&.{*f32}), .{f32_ptr}).eql(injectArgs(fn (a: *f32) void, @TypeOf(injectable), injectable, .{}));
    try testing.expect(std.meta.Tuple(&.{*Foo}), .{foo_ptr}).eql(injectArgs(fn (a: *Foo) void, @TypeOf(injectable), injectable, .{}));
    try testing.expect(std.meta.Tuple(&.{ *i32, *f32, *Foo }), .{ i32_ptr, f32_ptr, foo_ptr }).eql(injectArgs(fn (a: *i32, b: *f32, c: *Foo) void, @TypeOf(injectable), injectable, .{}));

    // Once a standard parameter is encountered, all parameters after that are considered standard
    // and not injected.
    var my_f32: f32 = 0.1337;
    var my_i32: i32 = 1337;
    try testing.expect(std.meta.Tuple(&.{f32}), .{1234}).eql(injectArgs(fn (a: f32) void, @TypeOf(injectable), injectable, .{1234}));
    try testing.expect(std.meta.Tuple(&.{ i32, *f32 }), .{ 1234, &my_f32 }).eql(injectArgs(fn (a: i32, b: *f32) void, @TypeOf(injectable), injectable, .{ 1234, &my_f32 }));
    try testing.expect(std.meta.Tuple(&.{ i32, *i32, *f32 }), .{ 1234, &my_i32, &my_f32 }).eql(injectArgs(fn (a: i32, b: *i32, c: *f32) void, @TypeOf(injectable), injectable, .{ 1234, &my_i32, &my_f32 }));

    // First parameter (*f32) matches an injectable parameter type, so it is injected.
    try testing.expect(std.meta.Tuple(&.{ *f32, i32, *i32, *f32 }), .{ f32_ptr, 1234, &my_i32, &my_f32 }).eql(injectArgs(fn (a: *f32, b: i32, c: *i32, d: *f32) void, @TypeOf(injectable), injectable, .{ 1234, &my_i32, &my_f32 }));

    // First parameter (*f32) matches an injectable parameter type, so it is injected. 2nd
    // parameter is not injectable, so all remaining parameters are not injected.
    var my_foo = foo;
    try testing.expect(std.meta.Tuple(&.{ *f32, i32, *Foo, *i32, *f32 }), .{ f32_ptr, 1234, &my_foo, &my_i32, &my_f32 }).eql(injectArgs(fn (a: *f32, b: i32, c: *Foo, d: *i32, e: *f32) void, @TypeOf(injectable), injectable, .{ 1234, &my_foo, &my_i32, &my_f32 }));
}

test UninjectedArgsTuple {
    // Injected arguments should generally be *struct types to avoid conflicts with any user-passed
    // parameters, though we do not require it - so we test with other types here.
    const i32_ptr: *i32 = undefined;
    const f32_ptr: *f32 = undefined;
    const Foo = struct { foo: f32 };
    const foo_ptr: *Foo = undefined;

    // No standard, no injected
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn () void, @TypeOf(.{})));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn () void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));

    // Standard parameters only, no injected
    TupleTester.assertTuple(.{i32}, UninjectedArgsTuple(fn (a: i32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));
    TupleTester.assertTuple(.{ i32, f32 }, UninjectedArgsTuple(fn (a: i32, b: f32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));

    // Injected parameters only, no standard
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *i32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *f32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *Foo) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *f32, b: *Foo, c: *i32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));

    // Once a standard parameter is encountered, all parameters after that are considered standard
    // and not injected.
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(fn (a: f32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));
    TupleTester.assertTuple(.{ i32, *f32 }, UninjectedArgsTuple(fn (a: i32, b: *f32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));
    TupleTester.assertTuple(.{ i32, *i32, *f32 }, UninjectedArgsTuple(fn (a: i32, b: *i32, c: *f32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));

    // First parameter (*f32) matches an injectable parameter type, so it is injected.
    TupleTester.assertTuple(.{ i32, *i32, *f32 }, UninjectedArgsTuple(fn (a: *f32, b: i32, c: *i32, d: *f32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));

    // First parameter (*f32) matches an injectable parameter type, so it is injected. 2nd
    // parameter is not injectable, so all remaining parameters are not injected.
    TupleTester.assertTuple(.{ i32, *Foo, *i32, *f32 }, UninjectedArgsTuple(fn (a: *f32, b: i32, c: *Foo, d: *i32, e: *f32) void, @TypeOf(.{ i32_ptr, f32_ptr, foo_ptr })));
}

test "event name calling" {
    // TODO: verify that event handlers error return signatures are correct
    const global = struct {
        var ticks: usize = 0;
        var physics_updates: usize = 0;
        var physics_calc: usize = 0;
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

            pub fn calc() void {
                global.physics_calc += 1;
            }
        };
    });
    const Renderer = Module(struct {
        pub const name = .engine_renderer;
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

    const Injectable = struct {};
    var modules: Modules(.{
        Physics,
        Renderer,
    }, Injectable) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);

    @TypeOf(modules).call(.tick, &.{}, .{});
    try testing.expect(usize, 2).eql(global.ticks);

    // Check we can use .call() with a runtime-known event name.
    const alloc = try testing.allocator.create(u3);
    defer testing.allocator.destroy(alloc);
    const E = EventName(@TypeOf(modules).modules);
    alloc.* = @intFromEnum(@as(E, .tick));

    var event_name = @as(E, @enumFromInt(alloc.*));
    @TypeOf(modules).call(event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);

    // Check call() behavior with a valid event name enum, but not a valid global event handler name
    alloc.* = @intFromEnum(@as(E, .update));
    event_name = @as(E, @enumFromInt(alloc.*));
    @TypeOf(modules).call(event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);
    try testing.expect(usize, 0).eql(global.physics_updates);
    try testing.expect(usize, 0).eql(global.renderer_updates);

    // Check we can use .callLocal() with a runtime-known event and module name.
    const m_alloc = try testing.allocator.create(u3);
    defer testing.allocator.destroy(m_alloc);
    const M = ModuleName(@TypeOf(modules).modules);
    m_alloc.* = @intFromEnum(@as(M, .engine_renderer));
    alloc.* = @intFromEnum(@as(E, .update));
    var module_name = @as(M, @enumFromInt(m_alloc.*));
    @TypeOf(modules).callLocal(module_name, event_name, &.{}, .{});
    @TypeOf(modules).callLocal(module_name, event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);
    try testing.expect(usize, 0).eql(global.physics_updates);
    try testing.expect(usize, 2).eql(global.renderer_updates);

    m_alloc.* = @intFromEnum(@as(M, .engine_physics));
    alloc.* = @intFromEnum(@as(E, .update));
    module_name = @as(M, @enumFromInt(m_alloc.*));
    event_name = @as(E, @enumFromInt(alloc.*));
    @TypeOf(modules).callLocal(module_name, event_name, &.{}, .{});
    try testing.expect(usize, 1).eql(global.physics_updates);

    m_alloc.* = @intFromEnum(@as(M, .engine_physics));
    alloc.* = @intFromEnum(@as(E, .calc));
    module_name = @as(M, @enumFromInt(m_alloc.*));
    event_name = @as(E, @enumFromInt(alloc.*));
    @TypeOf(modules).callLocal(module_name, event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);
    try testing.expect(usize, 1).eql(global.physics_calc);
    try testing.expect(usize, 1).eql(global.physics_updates);
    try testing.expect(usize, 2).eql(global.renderer_updates);
}

test "dispatch" {
    const global = struct {
        var ticks: usize = 0;
        var physics_updates: usize = 0;
        var physics_calc: usize = 0;
        var renderer_updates: usize = 0;
        var basic_args_sum: usize = 0;
    };
    var foo = struct {
        injected_args_sum: usize = 0,
    }{};
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

            pub fn calc() void {
                global.physics_calc += 1;
            }
        };
    });
    const Renderer = Module(struct {
        pub const name = .engine_renderer;
        pub const components = struct {};

        pub fn tick() void {
            global.ticks += 1;
        }

        pub const local = struct {
            pub fn update() void {
                global.renderer_updates += 1;
            }

            pub fn basicArgs(a: u32, b: u32) void {
                global.basic_args_sum = a + b;
            }

            pub fn injectedArgs(foo_ptr: *@TypeOf(foo), a: u32, b: u32) void {
                foo_ptr.*.injected_args_sum = a + b;
            }
        };
    });

    const injectable = .{&foo};
    var modules: Modules(.{
        Physics,
        Renderer,
    }, @TypeOf(injectable)) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);

    const E = EventName(@TypeOf(modules).modules);
    const M = ModuleName(@TypeOf(modules).modules);

    // Global events
    modules.send(.tick, struct {}, .{});
    try testing.expect(usize, 0).eql(global.ticks);
    modules.dispatch(.{&foo});
    try testing.expect(usize, 2).eql(global.ticks);
    // TODO: make sendDynamic take an args type to avoid footguns with comptime values, etc.
    modules.sendDynamic(@intFromEnum(@as(E, .tick)), .{});
    modules.dispatch(.{&foo});
    try testing.expect(usize, 4).eql(global.ticks);

    // Local events
    modules.sendToModule(.engine_renderer, .update, .{});
    modules.dispatch(.{&foo});
    try testing.expect(usize, 1).eql(global.renderer_updates);
    modules.sendToModule(.engine_physics, .update, .{});
    modules.sendToModuleDynamic(
        @intFromEnum(@as(M, .engine_physics)),
        @intFromEnum(@as(E, .calc)),
        .{},
    );
    modules.dispatch(.{&foo});
    try testing.expect(usize, 1).eql(global.physics_updates);
    try testing.expect(usize, 1).eql(global.physics_calc);

    // Local events
    modules.sendToModule(.engine_renderer, .basicArgs, .{ @as(u32, 1), @as(u32, 2) }); // TODO: match arguments against fn ArgsTuple, for correctness and type inference
    modules.sendToModule(.engine_renderer, .injectedArgs, .{ @as(u32, 1), @as(u32, 2) });
    modules.dispatch(.{&foo});
    try testing.expect(usize, 3).eql(global.basic_args_sum);
    try testing.expect(usize, 3).eql(foo.injected_args_sum);
}
