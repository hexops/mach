const builtin = @import("builtin");
const std = @import("std");
const testing = @import("testing.zig");

/// Verifies that M matches the basic layout of a Mach module
pub fn Module(comptime M: type) type {
    if (@typeInfo(M) != .Struct) @compileError("mach: expected module struct, found: " ++ @typeName(M));
    if (!@hasDecl(M, "name")) @compileError("mach: module must have `pub const name = .foobar;`");
    if (@typeInfo(@TypeOf(M.name)) != .EnumLiteral) @compileError("mach: module must have `pub const name = .foobar;`, found type:" ++ @typeName(M.name));

    const prefix = "mach: module ." ++ @tagName(M.name) ++ " ";
    if (!@hasDecl(M, "events")) @compileError(prefix ++ "must have `pub const events = .{};`");
    validateEvents("mach: module ." ++ @tagName(M.name) ++ " ", M.events);

    // TODO: move this to ecs
    if (@hasDecl(M, "components")) {
        if (@typeInfo(M.components) != .Struct) @compileError("Module.components must be `pub const components = struct { ... };`, found type:" ++ @typeName(M.components));
    }
    return M;
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

        pub const GlobalEvent = GlobalEventEnum(mods);
        pub const LocalEvent = LocalEventEnum(mods);

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
        fn LocalArgs(module_name: ModuleName(mods), event_name: LocalEvent) type {
            inline for (modules) |M| {
                _ = Module(M); // Validate the module
                if (M.name != module_name) continue;
                return LocalArgsM(M, event_name);
            }
        }

        pub fn LocalArgsM(comptime M: type, event_name: LocalEvent) type {
            _ = Module(M); // Validate the module
            inline for (M.events) |event| {
                const Ev = @TypeOf(event);
                const name_tag = if (@hasField(Ev, "local")) event.local else continue;
                if (name_tag != event_name) continue;

                const Handler = switch (@typeInfo(@TypeOf(event.handler))) {
                    .Fn => @TypeOf(event.handler),
                    .Type => switch (@typeInfo(event.handler)) {
                        .Fn => event.handler,
                        else => unreachable,
                    },
                    else => unreachable,
                };

                // TODO: passing std.meta.Tuple here instead of TupleHACK results in a compiler
                // segfault. The only difference is that TupleHACk does not produce a real tuple,
                // `@Type(.{.Struct = .{ .is_tuple = false }})` instead of `.is_tuple = true`.
                return UninjectedArgsTuple(TupleHACK, Handler);
            }
            @compileError("mach: module ." ++ @tagName(M.name) ++ " has no .local event handler for ." ++ @tagName(event_name));
        }

        /// Returns an args tuple representing the standard, uninjected, arguments which the given
        /// global event handler requires.
        fn GlobalArgs(module_name: ModuleName(mods), event_name: GlobalEvent) type {
            inline for (modules) |M| {
                _ = Module(M); // Validate the module
                if (M.name != module_name) continue;
                return GlobalArgsM(M, event_name);
            }
        }

        pub fn GlobalArgsM(comptime M: type, event_name: GlobalEvent) type {
            _ = Module(M); // Validate the module
            inline for (M.events) |event| {
                const Ev = @TypeOf(event);
                const name_tag = if (@hasField(Ev, "global")) event.global else continue;
                if (name_tag != event_name) continue;

                const Handler = switch (@typeInfo(@TypeOf(event.handler))) {
                    .Fn => @TypeOf(event.handler),
                    .Type => switch (@typeInfo(event.handler)) {
                        .Fn => event.handler,
                        else => unreachable,
                    },
                    else => unreachable,
                };

                // TODO: passing std.meta.Tuple here instead of TupleHACK results in a compiler
                // segfault. The only difference is that TupleHACk does not produce a real tuple,
                // `@Type(.{.Struct = .{ .is_tuple = false }})` instead of `.is_tuple = true`.
                return UninjectedArgsTuple(TupleHACK, Handler);
            }
            @compileError("mach: module ." ++ @tagName(M.name) ++ " has no .global event handler for ." ++ @tagName(event_name));
        }

        /// Send a global event which the specified module defines
        pub fn sendGlobal(
            m: *@This(),
            // TODO: is a variant of this function where event_name is not comptime known, but asserted to be a valid enum, useful?
            comptime module_name: ModuleName(mods),
            comptime event_name: GlobalEvent,
            args: GlobalArgs(module_name, event_name),
        ) void {
            // TODO: comptime safety/debugging
            m.sendInternal(null, @intFromEnum(event_name), args);
        }

        /// Send an event to a specific module
        pub fn sendToModule(
            m: *@This(),
            // TODO: is a variant of this function where module_name/event_name is not comptime known, but asserted to be a valid enum, useful?
            comptime module_name: ModuleName(mods),
            comptime event_name: LocalEvent,
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
                    try @This().callGlobal(@enumFromInt(ev.event_name), ev.args_slice, injectable);
                }
            }
        }

        /// Call global event handler with the specified name in all modules
        inline fn callGlobal(event_name: GlobalEvent, args: []u8, injectable: anytype) !void {
            if (@typeInfo(@TypeOf(event_name)).Enum.fields.len == 0) return;
            switch (event_name) {
                inline else => |ev_name| {
                    inline for (modules) |M| {
                        _ = Module(M); // Validate the module
                        inline for (M.events) |event| {
                            const Ev = @TypeOf(event);
                            const name_tag = if (@hasField(Ev, "global")) event.global else continue;
                            if (name_tag != ev_name) continue;
                            switch (@typeInfo(@TypeOf(event.handler))) {
                                .Fn => try callHandler(event.handler, args, injectable),
                                .Type => switch (@typeInfo(event.handler)) {
                                    .Fn => {}, // Pre-declaration of what args an event has, nothing to run.
                                    else => unreachable,
                                },
                                else => unreachable,
                            }
                        }
                    }
                },
            }
        }

        /// Call local event handler with the specified name in the specified module
        inline fn callLocal(module_name: ModuleName(mods), event_name: LocalEvent, args: []u8, injectable: anytype) !void {
            if (@typeInfo(@TypeOf(event_name)).Enum.fields.len == 0) return;
            // TODO: invert switch case for hypothetically better branch prediction
            switch (module_name) {
                inline else => |mod_name| {
                    switch (event_name) {
                        inline else => |ev_name| {
                            const M = @field(NamespacedModules(@This().modules){}, @tagName(mod_name));
                            _ = Module(M); // Validate the module

                            inline for (M.events) |event| {
                                const Ev = @TypeOf(event);
                                const name_tag = if (@hasField(Ev, "local")) event.local else continue;
                                if (name_tag != ev_name) continue;
                                switch (@typeInfo(@TypeOf(event.handler))) {
                                    .Fn => try callHandler(event.handler, args, injectable),
                                    .Type => switch (@typeInfo(event.handler)) {
                                        .Fn => {}, // Pre-declaration of what args an event has, nothing to run.
                                        else => unreachable,
                                    },
                                    else => unreachable,
                                }
                                break;
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
        // Is this a Struct or *Struct, with a `pub const IsInjectedArgument = void;` decl? If so,
        // it is considered an injected argument.
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
        // Is this a Struct or *Struct, with a `pub const IsInjectedArgument = void;` decl? If so,
        // it is considered an injected argument.
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

/// enum describing every possible comptime-known local event name
fn LocalEventEnum(comptime mods: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    for (mods) |M| {
        _ = Module(M); // Validate the module
        inline for (M.events) |event| {
            const Event = @TypeOf(event);
            const name_tag = if (@hasField(Event, "local")) event.local else continue;

            const exists_already = blk: {
                for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, @tagName(name_tag))) break :blk true;
                break :blk false;
            };
            if (!exists_already) {
                enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = @tagName(name_tag), .value = i }};
                i += 1;
            }
        }
    }
    return @Type(.{
        .Enum = .{
            .tag_type = if (enum_fields.len > 0) std.math.IntFittingRange(0, enum_fields.len - 1) else u0,
            .fields = enum_fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_exhaustive = true,
        },
    });
}

/// enum describing every possible comptime-known global event name
fn GlobalEventEnum(comptime mods: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    for (mods) |M| {
        _ = Module(M); // Validate the module
        inline for (M.events) |event| {
            const Event = @TypeOf(event);
            const name_tag = if (@hasField(Event, "global")) event.global else continue;

            const exists_already = blk: {
                for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, @tagName(name_tag))) break :blk true;
                break :blk false;
            };
            if (!exists_already) {
                enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = @tagName(name_tag), .value = i }};
                i += 1;
            }
        }
    }
    return @Type(.{
        .Enum = .{
            .tag_type = if (enum_fields.len > 0) std.math.IntFittingRange(0, enum_fields.len - 1) else u0,
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

fn validateEvents(comptime error_prefix: anytype, comptime events: anytype) void {
    if (@typeInfo(@TypeOf(events)) != .Struct or !@typeInfo(@TypeOf(events)).Struct.is_tuple) {
        @compileError(error_prefix ++ "expected a tuple of structs, found: " ++ @typeName(@TypeOf(events)));
    }
    inline for (events, 0..) |event, i| {
        const Event = @TypeOf(event);
        if (@typeInfo(Event) != .Struct) @compileError(std.fmt.comptimePrint(
            error_prefix ++ "expected a tuple of structs, found tuple element ({}): {s}",
            .{ i, @typeName(Event) },
        ));

        // Verify .global = .foo, or .local = .foo, event handler name field
        const name_tag = if (@hasField(Event, "global")) event.global else if (@hasField(Event, "local")) event.local else @compileError(std.fmt.comptimePrint(
            error_prefix ++ "tuple element ({}) missing field `.global = .foo` or `.local = .foo` (event handler kind / name)",
            .{i},
        ));
        const is_global = if (@hasField(Event, "global")) true else false;
        if (@typeInfo(@TypeOf(name_tag)) != .EnumLiteral) @compileError(std.fmt.comptimePrint(
            error_prefix ++ "tuple element ({}) expected field `.{s} = .foo`, found: {s}",
            .{ i, if (is_global) "global" else "local", @typeName(@TypeOf(name_tag)) },
        ));

        // Verify .handler = fn, field
        if (!@hasField(Event, "handler")) @compileError(std.fmt.comptimePrint(
            error_prefix ++ "tuple element ({}) missing field `.handler = fn`",
            .{i},
        ));
        const valid_handler_type = switch (@typeInfo(@TypeOf(event.handler))) {
            .Fn => true,
            .Type => switch (@typeInfo(event.handler)) {
                .Fn => true,
                else => false,
            },
            else => false,
        };
        if (!valid_handler_type) @compileError(std.fmt.comptimePrint(
            error_prefix ++ "tuple element ({}) expected field `.handler = fn`, found: {s}",
            .{ i, @typeName(@TypeOf(event.handler)) },
        ));
    }
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

        pub const events = .{
            .{ .global = .tick, .handler = tick },
        };

        fn tick() !void {}
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

        pub const events = .{
            .{ .global = .tick, .handler = tick },
        };

        fn tick() !void {}
    });

    const Renderer = Module(struct {
        pub const name = .engine_renderer;
        pub const events = .{
            .{ .global = .tick, .handler = tick },
        };

        /// Renderer module components
        pub const components = struct {};

        fn tick() !void {}
    });

    const Sprite2D = Module(struct {
        pub const name = .engine_sprite2d;
        pub const events = .{};
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
}

test "event name" {
    const Physics = Module(struct {
        pub const name = .engine_physics;
        pub const components = struct {};
        pub const events = .{
            .{ .global = .foo, .handler = foo },
            .{ .global = .bar, .handler = bar },
            .{ .local = .baz, .handler = baz },
            .{ .local = .bam, .handler = bam },
        };

        fn foo() !void {}
        fn bar() !void {}
        fn baz() !void {}
        fn bam() !void {}
    });

    const Renderer = Module(struct {
        pub const name = .engine_renderer;
        pub const components = struct {};
        pub const events = .{
            .{ .global = .foo_unused, .handler = fn (f32, i32) void },
            .{ .global = .bar_unused, .handler = fn (i32, f32) void },
            .{ .global = .tick, .handler = tick },
            .{ .global = .foo, .handler = foo },
            .{ .global = .bar, .handler = bar },
        };

        fn tick() !void {}
        fn foo() !void {} // same .foo name as .engine_physics.foo
        fn bar() !void {} // same .bar name as .engine_physics.bar
    });

    const Sprite2D = Module(struct {
        pub const name = .engine_sprite2d;
        pub const events = .{
            .{ .global = .tick, .handler = tick },
            .{ .global = .foobar, .handler = foobar },
        };

        fn tick() void {} // same .tick as .engine_renderer.tick
        fn foobar() void {}
    });

    const Mods = Modules(.{
        Physics,
        Renderer,
        Sprite2D,
    });

    const locals = @typeInfo(Mods.LocalEvent).Enum;
    try testing.expect(type, u1).eql(locals.tag_type);
    try testing.expect(usize, 2).eql(locals.fields.len);
    try testing.expect([]const u8, "baz").eql(locals.fields[0].name);
    try testing.expect([]const u8, "bam").eql(locals.fields[1].name);

    const globals = @typeInfo(Mods.GlobalEvent).Enum;
    try testing.expect(type, u3).eql(globals.tag_type);
    try testing.expect(usize, 6).eql(globals.fields.len);
    try testing.expect([]const u8, "foo").eql(globals.fields[0].name);
    try testing.expect([]const u8, "bar").eql(globals.fields[1].name);
    try testing.expect([]const u8, "foo_unused").eql(globals.fields[2].name);
    try testing.expect([]const u8, "bar_unused").eql(globals.fields[3].name);
    try testing.expect([]const u8, "tick").eql(globals.fields[4].name);
    try testing.expect([]const u8, "foobar").eql(globals.fields[5].name);
}

test ModuleName {
    const Physics = Module(struct {
        pub const name = .engine_physics;
        pub const events = .{};
    });
    const Renderer = Module(struct {
        pub const name = .engine_renderer;
        pub const events = .{};
    });
    const Sprite2D = Module(struct {
        pub const name = .engine_sprite2d;
        pub const events = .{};
    });
    const Mods = Modules(.{
        Physics,
        Renderer,
        Sprite2D,
    });
    const info = @typeInfo(ModuleName(Mods.modules)).Enum;

    try testing.expect(type, u2).eql(info.tag_type);
    try testing.expect(usize, 3).eql(info.fields.len);
    try testing.expect([]const u8, "engine_physics").eql(info.fields[0].name);
    try testing.expect([]const u8, "engine_renderer").eql(info.fields[1].name);
    try testing.expect([]const u8, "engine_sprite2d").eql(info.fields[2].name);
}

// TODO: remove this in favor of testing.expect
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
    const Foo = struct {
        foo: f32,
        pub const IsInjectedArgument = void;
    };
    const Bar = struct {
        bar: i32,
        pub const IsInjectedArgument = void;
    };
    const Baz = struct {
        baz: bool,
        pub const IsInjectedArgument = void;
    };
    var foo = Foo{ .foo = 0.1234 };
    var bar = Bar{ .bar = 1234 };
    var baz = Baz{ .baz = true };
    const foo_ptr = &foo;
    const bar_ptr = &bar;
    const baz_ptr = &baz;

    // No standard, no injected
    try testing.expect(struct {}, .{}).eql(injectArgs(fn () void, @TypeOf(.{}), .{}, .{}));
    const injectable = .{ foo_ptr, bar_ptr, baz_ptr };
    try testing.expect(struct {}, .{}).eql(injectArgs(fn () void, @TypeOf(injectable), injectable, .{}));

    // Standard parameters only, no injected
    try testing.expect(std.meta.Tuple(&.{i32}), .{0}).eql(injectArgs(fn (a: i32) void, @TypeOf(injectable), injectable, .{0}));
    try testing.expect(std.meta.Tuple(&.{ i32, f32 }), .{ 1, 0.5 }).eql(injectArgs(fn (a: i32, b: f32) void, @TypeOf(injectable), injectable, .{ 1, 0.5 }));

    // Injected parameters only, no standard
    try testing.expect(std.meta.Tuple(&.{*Foo}), .{foo_ptr}).eql(injectArgs(fn (a: *Foo) void, @TypeOf(injectable), injectable, .{}));
    try testing.expect(std.meta.Tuple(&.{ *Foo, *Bar }), .{ foo_ptr, bar_ptr }).eql(injectArgs(fn (a: *Foo, b: *Bar) void, @TypeOf(injectable), injectable, .{}));
    try testing.expect(std.meta.Tuple(&.{ *Foo, *Bar, *Baz }), .{ foo_ptr, bar_ptr, baz_ptr }).eql(injectArgs(fn (a: *Foo, b: *Bar, c: *Baz) void, @TypeOf(injectable), injectable, .{}));
    try testing.expect(std.meta.Tuple(&.{ *Bar, *Baz, *Foo }), .{ bar_ptr, baz_ptr, foo_ptr }).eql(injectArgs(fn (a: *Bar, b: *Baz, c: *Foo) void, @TypeOf(injectable), injectable, .{}));
    try testing.expect(std.meta.Tuple(&.{ *Foo, *Foo, *Baz }), .{ foo_ptr, foo_ptr, baz_ptr }).eql(injectArgs(fn (a: *Foo, b: *Foo, c: *Baz) void, @TypeOf(injectable), injectable, .{}));

    // As long as the argument is a Struct or *Struct with an IsInjectedArgument decl, it is
    // considered an injected argument.
    // try testing.expect(std.meta.Tuple(&.{*const Foo}), .{foo_ptr}).eql(injectArgs(fn (a: *const Foo) void, @TypeOf(injectable), injectable, .{}));
    const injectable2 = .{ foo, foo_ptr, bar_ptr, baz_ptr };
    try testing.expect(std.meta.Tuple(&.{Foo}), .{foo_ptr.*}).eql(injectArgs(fn (a: Foo) void, @TypeOf(injectable2), injectable2, .{}));

    // Order doesn't matter, injected arguments can be placed inbetween any standard arguments, etc.
    try testing.expect(std.meta.Tuple(&.{ i32, *Foo, *Foo, *Baz }), .{ 1337, foo_ptr, foo_ptr, baz_ptr }).eql(injectArgs(fn (z: i32, a: *Foo, b: *Foo, c: *Baz) void, @TypeOf(injectable), injectable, .{1337}));
    try testing.expect(std.meta.Tuple(&.{ i32, *Foo, f32, *Foo, *Baz }), .{ 1337, foo_ptr, 1.337, foo_ptr, baz_ptr }).eql(injectArgs(fn (z: i32, a: *Foo, w: f32, b: *Foo, c: *Baz) void, @TypeOf(injectable), injectable, .{ 1337, 1.337 }));
    try testing.expect(std.meta.Tuple(&.{ i32, f32, *Foo, *Foo, *Baz }), .{ 1337, 1.337, foo_ptr, foo_ptr, baz_ptr }).eql(injectArgs(fn (z: i32, w: f32, a: *Foo, b: *Foo, c: *Baz) void, @TypeOf(injectable), injectable, .{ 1337, 1.337 }));
    try testing.expect(std.meta.Tuple(&.{ *Foo, *Foo, *Baz, i32, f32 }), .{ foo_ptr, foo_ptr, baz_ptr, 1337, 1.337 }).eql(injectArgs(fn (az: *Foo, b: *Foo, c: *Baz, z: i32, w: f32) void, @TypeOf(injectable), injectable, .{ 1337, 1.337 }));
}

test UninjectedArgsTuple {
    const Foo = struct {
        foo: f32,
        pub const IsInjectedArgument = void;
    };
    const Bar = struct {
        bar: bool,
        pub const IsInjectedArgument = void;
    };

    // No standard, no injected
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn () void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn () void));

    // Standard parameters only, no injected
    TupleTester.assertTuple(.{i32}, UninjectedArgsTuple(std.meta.Tuple, fn (a: i32) void));
    TupleTester.assertTuple(.{ i32, f32 }, UninjectedArgsTuple(std.meta.Tuple, fn (a: i32, b: f32) void));

    // Injected parameters only, no standard
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *Foo) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *Bar) void));

    // As long as the argument is a Struct or *Struct with an IsInjectedArgument decl, it is
    // considered an injected argument.
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *Foo, b: *Bar, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: Foo) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: Bar) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *const Foo) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *const Bar) void));

    // Order doesn't matter, injected arguments can be placed inbetween any standard arguments, etc.
    TupleTester.assertTuple(.{ f32, bool }, UninjectedArgsTuple(std.meta.Tuple, fn (i: f32, a: *Foo, k: bool, b: *Bar, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(std.meta.Tuple, fn (i: f32, a: *Foo, b: *Bar, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *Foo, i: f32, b: *Bar, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *Foo, b: *Bar, i: f32, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *Foo, b: *Bar, c: Foo, i: f32, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(std.meta.Tuple, fn (a: *Foo, b: *Bar, c: Foo, d: Bar, i: f32) void));
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
        pub const events = .{
            .{ .global = .tick, .handler = tick },
            .{ .local = .update, .handler = update },
            .{ .local = .calc, .handler = calc },
        };

        fn tick() void {
            global.ticks += 1;
        }

        fn update() void {
            global.physics_updates += 1;
        }

        fn calc() void {
            global.physics_calc += 1;
        }
    });
    const Renderer = Module(struct {
        pub const name = .engine_renderer;
        pub const components = struct {};
        pub const events = .{
            .{ .global = .tick, .handler = tick },
            .{ .local = .update, .handler = update },
        };

        fn tick() void {
            global.ticks += 1;
        }

        fn update() void {
            global.renderer_updates += 1;
        }
    });

    var modules: Modules(.{
        Physics,
        Renderer,
    }) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);

    try @TypeOf(modules).callGlobal(.tick, &.{}, .{});
    try testing.expect(usize, 2).eql(global.ticks);

    // Check we can use .callGlobal() with a runtime-known event name.
    const alloc = try testing.allocator.create(u3);
    defer testing.allocator.destroy(alloc);
    const GE = @TypeOf(modules).GlobalEvent;
    const LE = @TypeOf(modules).LocalEvent;
    alloc.* = @intFromEnum(@as(GE, .tick));

    const global_event_name = @as(GE, @enumFromInt(alloc.*));
    try @TypeOf(modules).callGlobal(global_event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);

    // Check we can use .callLocal() with a runtime-known event and module name.
    const m_alloc = try testing.allocator.create(u3);
    defer testing.allocator.destroy(m_alloc);
    const M = ModuleName(@TypeOf(modules).modules);
    m_alloc.* = @intFromEnum(@as(M, .engine_renderer));
    alloc.* = @intFromEnum(@as(LE, .update));
    var module_name = @as(M, @enumFromInt(m_alloc.*));
    var local_event_name = @as(LE, @enumFromInt(alloc.*));
    try @TypeOf(modules).callLocal(module_name, local_event_name, &.{}, .{});
    try @TypeOf(modules).callLocal(module_name, local_event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);
    try testing.expect(usize, 0).eql(global.physics_updates);
    try testing.expect(usize, 2).eql(global.renderer_updates);

    m_alloc.* = @intFromEnum(@as(M, .engine_physics));
    alloc.* = @intFromEnum(@as(LE, .update));
    module_name = @as(M, @enumFromInt(m_alloc.*));
    local_event_name = @as(LE, @enumFromInt(alloc.*));
    try @TypeOf(modules).callLocal(module_name, local_event_name, &.{}, .{});
    try testing.expect(usize, 1).eql(global.physics_updates);

    m_alloc.* = @intFromEnum(@as(M, .engine_physics));
    alloc.* = @intFromEnum(@as(LE, .calc));
    module_name = @as(M, @enumFromInt(m_alloc.*));
    local_event_name = @as(LE, @enumFromInt(alloc.*));
    try @TypeOf(modules).callLocal(module_name, local_event_name, &.{}, .{});
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

        pub const IsInjectedArgument = void;
    }{};
    const Minimal = Module(struct {
        pub const name = .engine_minimal;
        pub const events = .{};
    });
    const Physics = Module(struct {
        pub const name = .engine_physics;
        pub const components = struct {};
        pub const events = .{
            .{ .global = .tick, .handler = tick },
            .{ .local = .update, .handler = update },
            .{ .local = .calc, .handler = calc },
        };

        fn tick() void {
            global.ticks += 1;
        }

        fn update() void {
            global.physics_updates += 1;
        }

        fn calc() void {
            global.physics_calc += 1;
        }
    });
    const Renderer = Module(struct {
        pub const name = .engine_renderer;
        pub const components = struct {};
        pub const events = .{
            .{ .global = .tick, .handler = tick },
            .{ .global = .frame_done, .handler = fn (i32) void },
            .{ .local = .update, .handler = update },
            .{ .local = .basic_args, .handler = basicArgs },
            .{ .local = .injected_args, .handler = injectedArgs },
        };

        pub const frameDone = fn (i32) void;

        fn tick() void {
            global.ticks += 1;
        }

        fn update() void {
            global.renderer_updates += 1;
        }

        fn basicArgs(a: u32, b: u32) void {
            global.basic_args_sum = a + b;
        }

        fn injectedArgs(foo_ptr: *@TypeOf(foo), a: u32, b: u32) void {
            foo_ptr.*.injected_args_sum = a + b;
        }
    });

    var modules: Modules(.{
        Minimal,
        Physics,
        Renderer,
    }) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);

    const GE = @TypeOf(modules).GlobalEvent;
    const LE = @TypeOf(modules).LocalEvent;
    const M = ModuleName(@TypeOf(modules).modules);

    // Global events
    //
    // The 2nd parameter (arguments to the tick event handler) is inferred based on the `pub fn tick`
    // global event handler declaration within a module. It is required that all global event handlers
    // of the same name have the same standard arguments, although they can start with different
    // injected arguments.
    modules.sendGlobal(.engine_renderer, .tick, .{});
    try testing.expect(usize, 0).eql(global.ticks);
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 2).eql(global.ticks);
    // TODO: make sendDynamic take an args type to avoid footguns with comptime values, etc.
    modules.sendDynamic(@intFromEnum(@as(GE, .tick)), .{});
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 4).eql(global.ticks);

    // Global events which are not handled by anyone yet can be written as `pub const fooBar = fn() void;`
    // within a module, which allows pre-declaring that `fooBar` is a valid global event, and enables
    // its arguments to be inferred still like this:
    modules.sendGlobal(.engine_renderer, .frame_done, .{ .@"0" = 1337 });

    // Local events
    modules.sendToModule(.engine_renderer, .update, .{});
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 1).eql(global.renderer_updates);
    modules.sendToModule(.engine_physics, .update, .{});
    modules.sendToModuleDynamic(
        @intFromEnum(@as(M, .engine_physics)),
        @intFromEnum(@as(LE, .calc)),
        .{},
    );
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 1).eql(global.physics_updates);
    try testing.expect(usize, 1).eql(global.physics_calc);

    // Local events
    modules.sendToModule(.engine_renderer, .basic_args, .{ .@"0" = @as(u32, 1), .@"1" = @as(u32, 2) }); // TODO: match arguments against fn ArgsTuple, for correctness and type inference
    modules.sendToModule(.engine_renderer, .injected_args, .{ .@"0" = @as(u32, 1), .@"1" = @as(u32, 2) });
    try modules.dispatch(.{&foo});
    try testing.expect(usize, 3).eql(global.basic_args_sum);
    try testing.expect(usize, 3).eql(foo.injected_args_sum);
}
