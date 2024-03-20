const builtin = @import("builtin");
const std = @import("std");
const testing = @import("testing.zig");

/// Verifies that T matches the basic layout of a Mach module
pub fn Module(comptime T: type) type {
    if (@typeInfo(T) != .Struct) @compileError("Module must be a struct type. Found:" ++ @typeName(T));
    if (!@hasDecl(T, "name")) @compileError("Module must have `pub const name = .foobar;`");
    if (@typeInfo(@TypeOf(T.name)) != .EnumLiteral) @compileError("Module must have `pub const name = .foobar;`, found type:" ++ @typeName(T.name));

    // TODO: move this to ecs
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
pub fn Modules(comptime mods: anytype) type {
    // Verify that each module is valid.
    inline for (mods) |M| _ = Module(M);

    return struct {
        /// Comptime modules
        pub const modules = mods;

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
            inline for (modules) |M| {
                if (M.name != module_name) continue;
                if (!@hasDecl(M, "local")) @compileError("Module " ++ @tagName(module_name) ++ " has no `pub const local = struct { ... };` event handlers");
                if (!@hasDecl(M.local, @tagName(event_name))) @compileError("Module " ++ @tagName(module_name) ++ ".local has no event handler named: " ++ @tagName(event_name));
                const handler = @field(M.local, @tagName(event_name));
                switch (@typeInfo(@TypeOf(handler))) {
                    // TODO: passing std.meta.Tuple here instead of TupleHACK results in a compiler
                    // segfault. The only difference is that TupleHACk does not produce a real tuple,
                    // `@Type(.{.Struct = .{ .is_tuple = false }})` instead of `.is_tuple = true`.
                    .Fn => return UninjectedArgsTuple(TupleHACK, @TypeOf(handler)),
                    // Note: This means the module does have some other field by the same name, but it is not a function.
                    // TODO: allow pre-declarations
                    else => @compileError("Module " ++ @tagName(module_name) ++ ".local." ++ @tagName(event_name) ++ " is not a function"),
                }
            }
        }

        /// Returns an args tuple representing the standard, uninjected, arguments which the given
        /// global event handler requires.
        fn Args(event_name: EventName(mods)) type {
            inline for (modules) |M| {
                // TODO: enforce any defined event handlers of the same name have the same argument types
                if (@hasDecl(M, @tagName(event_name))) {
                    const Handler = switch (@typeInfo(@TypeOf(@field(M, @tagName(event_name))))) {
                        .Fn => @TypeOf(@field(M, @tagName(event_name))),
                        .Type => switch (@typeInfo(@field(M, @tagName(event_name)))) {
                            .Fn => @field(M, @tagName(event_name)),
                            else => continue,
                        },
                        else => continue,
                    };
                    return UninjectedArgsTuple(std.meta.Tuple, Handler);
                }
            }
            @compileError("No global event handler " ++ @tagName(event_name) ++ " is defined in any module.");
        }

        /// Send a global event
        pub fn send(
            m: *@This(),
            // TODO: is a variant of this function where event_name is not comptime known, but asserted to be a valid enum, useful?
            comptime event_name: EventName(mods),
            args: Args(event_name),
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
                .args_slice = m.args_queue.items[m.args_queue.items.len - args_bytes.len .. m.args_queue.items.len],
            });
        }

        /// Dispatches pending events, invoking their event handlers.
        pub fn dispatch(m: *@This(), injectable: anytype) !void {
            // TODO: verify injectable arguments are valid, e.g. not comptime types

            // TODO: optimize to reduce send contention
            // TODO: parallel / multi-threaded dispatch
            // TODO: PGO

            // TODO: this is wrong
            defer {
                m.events_mu.lock();
                m.args_queue.clearRetainingCapacity();
                m.events_mu.unlock();
            }

            while (true) {
                m.events_mu.lock();
                const ev = m.events.readItem() orelse {
                    m.events_mu.unlock();
                    break;
                };
                m.events_mu.unlock();

                if (ev.module_name) |module_name| {
                    // TODO: dispatch arguments
                    try @This().callLocal(@enumFromInt(module_name), @enumFromInt(ev.event_name), ev.args_slice, injectable);
                } else {
                    // TODO: dispatch arguments
                    try @This().call(@enumFromInt(ev.event_name), ev.args_slice, injectable);
                }
            }
        }

        /// Call global event handler with the specified name in all modules
        inline fn call(event_name: EventName(mods), args: []u8, injectable: anytype) !void {
            switch (event_name) {
                inline else => |name| {
                    inline for (modules) |M| {
                        if (@hasDecl(M, @tagName(name))) {
                            switch (@typeInfo(@TypeOf(@field(M, @tagName(name))))) {
                                .Fn => {
                                    const handler = @field(M, @tagName(name));
                                    try callHandler(handler, args, injectable);
                                },
                                else => {},
                            }
                        }
                    }
                },
            }
        }

        /// Call local event handler with the specified name in the specified module
        inline fn callLocal(module_name: ModuleName(mods), event_name: EventName(mods), args: []u8, injectable: anytype) !void {
            // TODO: invert switch case for hypothetically better branch prediction
            switch (module_name) {
                inline else => |mod_name| {
                    switch (event_name) {
                        inline else => |ev_name| {
                            const M = @field(NamespacedModules(@This().modules){}, @tagName(mod_name));
                            // TODO: no need for hasDecl, assertion should be event can be sent at send() time.
                            if (@hasDecl(M, "local") and @hasDecl(M.local, @tagName(ev_name))) {
                                const handler = @field(M.local, @tagName(ev_name));
                                switch (@typeInfo(@TypeOf(handler))) {
                                    .Fn => {
                                        try callHandler(handler, args, injectable);
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
        inline fn callHandler(handler: anytype, args_data: []u8, injectable: anytype) !void {
            const Handler = @TypeOf(handler);
            const StdArgs = UninjectedArgsTuple(std.meta.Tuple, Handler);
            const std_args: *StdArgs = @alignCast(@ptrCast(args_data.ptr));
            const args = injectArgs(Handler, @TypeOf(injectable), injectable, std_args.*);
            const Ret = @typeInfo(Handler).Fn.return_type orelse void;
            switch (@typeInfo(Ret)) {
                .ErrorUnion => try @call(.auto, handler, args),
                else => @call(.auto, handler, args),
            }
        }
    };
}

// TODO: see usage location
fn TupleHACK(comptime types: []const type) type {
    return CreateUniqueTupleHACK(types.len, types[0..types.len].*);
}

fn CreateUniqueTupleHACK(comptime N: comptime_int, comptime types: [N]type) type {
    var tuple_fields: [types.len]std.builtin.Type.StructField = undefined;
    inline for (types, 0..) |T, i| {
        @setEvalBranchQuota(10_000);
        var num_buf: [128]u8 = undefined;
        tuple_fields[i] = .{
            .name = std.fmt.bufPrintZ(&num_buf, "{d}", .{i}) catch unreachable,
            .type = T,
            .default_value = null,
            .is_comptime = false,
            .alignment = if (@sizeOf(T) > 0) @alignOf(T) else 0,
        };
    }

    return @Type(.{
        .Struct = .{
            // .is_tuple = true,
            .is_tuple = false,
            .layout = .Auto,
            .decls = &.{},
            .fields = &tuple_fields,
        },
    });
}

// Given a function, its standard arguments and injectable arguments, performs injection and
// returns the actual argument tuple which would be used to call the function.
inline fn injectArgs(
    comptime Function: type,
    comptime Injectable: type,
    injectable_args: Injectable,
    std_args: UninjectedArgsTuple(std.meta.Tuple, Function),
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
fn UninjectedArgsTuple(
    comptime Tuple: fn (comptime types: []const type) type,
    comptime Function: type,
) type {
    var std_args: []const type = &[0]type{};
    inline for (@typeInfo(std.meta.ArgsTuple(Function)).Struct.fields) |arg| {
        // Injected arguments always go first, then standard (non-injected) arguments.
        if (std_args.len > 0) {
            std_args = std_args ++ [_]type{arg.type};
            continue;
        }
        const is_injected = blk: {
            switch (@typeInfo(arg.type)) {
                .Struct => break :blk @hasDecl(arg.type, "IsInjectedArgument"),
                .Pointer => {
                    switch (@typeInfo(std.meta.Child(arg.type))) {
                        .Struct => break :blk @hasDecl(std.meta.Child(arg.type), "IsInjectedArgument"),
                        else => break :blk false,
                    }
                },
                else => break :blk false,
            }
        };
        if (is_injected) continue; // legitimate injected argument, ignore it
        std_args = std_args ++ [_]type{arg.type};
    }
    return Tuple(std_args);
}

/// enum describing every possible comptime-known global event name.
fn GlobalEvent(comptime mods: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    for (mods) |M| {
        // Global event handlers
        for (@typeInfo(M).Struct.decls) |decl| {
            const is_event_handler = switch (@typeInfo(@TypeOf(@field(M, decl.name)))) {
                .Fn => true,
                .Type => switch (@typeInfo(@field(M, decl.name))) {
                    .Fn => true,
                    else => false,
                },
                else => false,
            };
            if (is_event_handler) {
                const exists_already = blk2: {
                    for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, decl.name)) break :blk2 true;
                    break :blk2 false;
                };
                if (!exists_already) {
                    enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = decl.name, .value = i }};
                    i += 1;
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

/// enum describing every possible comptime-known event name
fn EventName(comptime mods: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    for (mods) |M| {
        // Global event handlers
        for (@typeInfo(M).Struct.decls) |decl| {
            const is_event_handler = switch (@typeInfo(@TypeOf(@field(M, decl.name)))) {
                .Fn => true,
                .Type => switch (@typeInfo(@field(M, decl.name))) {
                    .Fn => true,
                    else => false,
                },
                else => false,
            };
            if (is_event_handler) {
                const exists_already = blk2: {
                    for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, decl.name)) break :blk2 true;
                    break :blk2 false;
                };
                if (!exists_already) {
                    enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = decl.name, .value = i }};
                    i += 1;
                }
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

        pub const fooUnused = fn (f32, i32) void;
        pub const barUnused = fn (i32, f32) void;

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
    try testing.expect(usize, 8).eql(info.fields.len);
    try testing.expect([]const u8, "foo").eql(info.fields[0].name);
    try testing.expect([]const u8, "bar").eql(info.fields[1].name);
    try testing.expect([]const u8, "baz").eql(info.fields[2].name);
    try testing.expect([]const u8, "bam").eql(info.fields[3].name);
    try testing.expect([]const u8, "fooUnused").eql(info.fields[4].name);
    try testing.expect([]const u8, "barUnused").eql(info.fields[5].name);
    try testing.expect([]const u8, "tick").eql(info.fields[6].name);
    try testing.expect([]const u8, "foobar").eql(info.fields[7].name);

    const global_info = @typeInfo(GlobalEvent(Mods.modules)).Enum;
    try testing.expect(type, u3).eql(global_info.tag_type);
    try testing.expect(usize, 5).eql(global_info.fields.len);
    try testing.expect([]const u8, "foo").eql(global_info.fields[0].name);
    try testing.expect([]const u8, "bar").eql(global_info.fields[1].name);
    try testing.expect([]const u8, "fooUnused").eql(global_info.fields[2].name);
    try testing.expect([]const u8, "barUnused").eql(global_info.fields[3].name);
    try testing.expect([]const u8, "tick").eql(global_info.fields[4].name);
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
    const Foo = struct {
        foo: f32,
        pub const IsInjectedArgument = void;
    };

    // No standard, no injected
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn () void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn () void));

    // Standard parameters only, no injected
    TupleTester.assertTuple(.{i32}, UninjectedArgsTuple(std.meta.Tuple, fn (a: i32) void));
    TupleTester.assertTuple(.{ i32, f32 }, UninjectedArgsTuple(std.meta.Tuple, fn (a: i32, b: f32) void));

    // Injected parameters only, no standard
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *i32) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *f32) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *Foo) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *f32, b: *Foo, c: *i32) void));

    // Once a standard parameter is encountered, all parameters after that are considered standard
    // and not injected.
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(std.meta.Tuple, fn (a: f32) void));
    TupleTester.assertTuple(.{ i32, *f32 }, UninjectedArgsTuple(std.meta.Tuple, fn (a: i32, b: *f32) void));
    TupleTester.assertTuple(.{ i32, *i32, *f32 }, UninjectedArgsTuple(std.meta.Tuple, fn (a: i32, b: *i32, c: *f32) void));

    // First parameter (*f32) matches an injectable parameter type, so it is injected.
    TupleTester.assertTuple(.{ i32, *i32, *f32 }, UninjectedArgsTuple(std.meta.Tuple, fn (a: *f32, b: i32, c: *i32, d: *f32) void));

    // First parameter (*f32) matches an injectable parameter type, so it is injected. 2nd
    // parameter is not injectable, so all remaining parameters are not injected.
    TupleTester.assertTuple(.{ i32, *Foo, *i32, *f32 }, UninjectedArgsTuple(std.meta.Tuple, fn (a: *f32, b: i32, c: *Foo, d: *i32, e: *f32) void));
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

    try @TypeOf(modules).call(.tick, &.{}, .{});
    try testing.expect(usize, 2).eql(global.ticks);

    // Check we can use .call() with a runtime-known event name.
    const alloc = try testing.allocator.create(u3);
    defer testing.allocator.destroy(alloc);
    const E = EventName(@TypeOf(modules).modules);
    alloc.* = @intFromEnum(@as(E, .tick));

    var event_name = @as(E, @enumFromInt(alloc.*));
    try @TypeOf(modules).call(event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);

    // Check call() behavior with a valid event name enum, but not a valid global event handler name
    alloc.* = @intFromEnum(@as(E, .update));
    event_name = @as(E, @enumFromInt(alloc.*));
    try @TypeOf(modules).call(event_name, &.{}, .{});
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
    try @TypeOf(modules).callLocal(module_name, event_name, &.{}, .{});
    try @TypeOf(modules).callLocal(module_name, event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);
    try testing.expect(usize, 0).eql(global.physics_updates);
    try testing.expect(usize, 2).eql(global.renderer_updates);

    m_alloc.* = @intFromEnum(@as(M, .engine_physics));
    alloc.* = @intFromEnum(@as(E, .update));
    module_name = @as(M, @enumFromInt(m_alloc.*));
    event_name = @as(E, @enumFromInt(alloc.*));
    try @TypeOf(modules).callLocal(module_name, event_name, &.{}, .{});
    try testing.expect(usize, 1).eql(global.physics_updates);

    m_alloc.* = @intFromEnum(@as(M, .engine_physics));
    alloc.* = @intFromEnum(@as(E, .calc));
    module_name = @as(M, @enumFromInt(m_alloc.*));
    event_name = @as(E, @enumFromInt(alloc.*));
    try @TypeOf(modules).callLocal(module_name, event_name, &.{}, .{});
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
    const Minimal = Module(struct {
        pub const name = .engine_minimal;
    });
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

        pub const frameDone = fn (i32) void;

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
        Minimal,
        Physics,
        Renderer,
    }, @TypeOf(injectable)) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);

    const E = EventName(@TypeOf(modules).modules);
    const M = ModuleName(@TypeOf(modules).modules);

    // Global events
    //
    // The 2nd parameter (arguments to the tick event handler) is inferred based on the `pub fn tick`
    // global event handler declaration within a module. It is required that all global event handlers
    // of the same name have the same standard arguments, although they can start with different
    // injected arguments.
    modules.send(.tick, .{});
    try testing.expect(usize, 0).eql(global.ticks);
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 2).eql(global.ticks);
    // TODO: make sendDynamic take an args type to avoid footguns with comptime values, etc.
    modules.sendDynamic(@intFromEnum(@as(E, .tick)), .{});
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 4).eql(global.ticks);

    // Global events which are not handled by anyone yet can be written as `pub const fooBar = fn() void;`
    // within a module, which allows pre-declaring that `fooBar` is a valid global event, and enables
    // its arguments to be inferred still like this:
    modules.send(.frameDone, .{1337});

    // Local events
    modules.sendToModule(.engine_renderer, .update, .{});
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 1).eql(global.renderer_updates);
    modules.sendToModule(.engine_physics, .update, .{});
    modules.sendToModuleDynamic(
        @intFromEnum(@as(M, .engine_physics)),
        @intFromEnum(@as(E, .calc)),
        .{},
    );
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 1).eql(global.physics_updates);
    try testing.expect(usize, 1).eql(global.physics_calc);

    // Local events
    modules.sendToModule(.engine_renderer, .basicArgs, .{ @as(u32, 1), @as(u32, 2) }); // TODO: match arguments against fn ArgsTuple, for correctness and type inference
    modules.sendToModule(.engine_renderer, .injectedArgs, .{ @as(u32, 1), @as(u32, 2) });
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 3).eql(global.basic_args_sum);
    try testing.expect(usize, 3).eql(foo.injected_args_sum);
}
