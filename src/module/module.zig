//! Module system
//!
//! ## Events
//!
//! Every piece of logic in a Mach module runs in response to an event.
//!
//! Events are used to schedule the execution order of event handlers. What we call event handlers
//! are often called 'systems' in other game engines following ECS design patterns. Typically,
//! other engines require that you express a specific order you'd like systems to execute in via
//! e.g. a sorting integer.
//!
//! Mach's module system has only events and event handlers. In order to get system/event-handler B
//! to run after A, A simply needs to send an event that module B defines an event handler for.
//! These are simple functions, with some dependency injection.
//!
//! Event handlers are also a point-of-parallelism opportunity, i.e. depending on what event
//! handlers do within their function body (whether it be adding/removing entities/components,
//! sending events, or reading/writing module state), the event scheduler can determine which event
//! handlers may be eligible for parallel execution without data races or non-deterministic behavior.
//! Mach does not yet implement this today, but will in the future.
//!
//! Events are simply a name associated with a function, as well as some (simple data type) parameters
//! that function may expect. They are however **high-level** communication between modules, i.e.
//! scheduling the execution of functions which are generally expected to do a reasonable amount of
//! work, since events are a dynamic dispatch point and not e.g. inline function calls.
//!
//! Events are also the foundation for:
//!
//! * Graphical editor integration, e.g. event names and parameters could be enumerated via an
//!   external process to your program, allowing a graphical editor to craft and send events with
//!   payloads to your program over e.g. a socket.
//! * Debugging facilities - for example the entire program can be analyzed as a sequence of named
//!   events being dispatched, showing you the execution of e.g. a frame. Or, events could be saved
//!   to disk and replayed/inspected later.
//! * Networking between modules - events could be serialized and sent over the network.
//! * Loops executing at different frequencies - a 'loop' is simply events firing in a circular loop,
//!   e.g. you could have multiple loops of events going at the same time, using an event as a
//!   synchronization point:
//!   * .render_begin -> wait for .physics_sync -> .game_tick -> .game_draw_frame -> .render_end -> .render_begin
//!   * .physics_begin -> .poll_input -> .physics_calculate -> .physics_sync -> .physics_end -> .physics_begin
//!
//! ## Event arguments
//!
//! Event arguments should only be used to convey stateless information.
//!
//! Good use-cases for event arguments are typically ones where you would want a graphical editor
//! to be able to convey to your program that something should be done, for example:
//! * `.spawn_monsters` with an argument conveying the number of monsters to spawn.
//! * `.set_entity_position` with an argument conveying what to set an entity's position to
//!
//! On the other hand, bad use-cases for event arguments tend to be stateful:
//!
//! * Anything involving pointers (which may be completely prohibited in the future)
//! * `.render_players` with an argument conveying to render specific player entities, rather than
//!   the event having no arguments and instead looking at which entities have a component/tag
//!   indicating they should be rendered.
//!
//! These examples are bad because if these events' arguments were to be e.g. serialized and saved
//! to disk, and then replayed later in a future execution of the program, you may find that the
//! arguments no longer make sense in a replay of the program.

const builtin = @import("builtin");
const std = @import("std");
const testing = @import("../testing.zig");

const Entities = @import("entities.zig").Entities;
const EntityID = @import("entities.zig").EntityID;
const is_debug = @import("Archetype.zig").is_debug;
const builtin_modules = @import("main.zig").builtin_modules;

const log = std.log.scoped(.mach);

/// Verifies that M matches the basic layout of a Mach module
fn ModuleInterface(comptime M: type) type {
    validateModule(M, true);
    return M;
}

fn validateModule(comptime M: type, comptime events: bool) void {
    if (@typeInfo(M) != .Struct) @compileError("mach: expected module struct, found: " ++ @typeName(M));
    if (!@hasDecl(M, "name")) @compileError("mach: module must have `pub const name = .foobar;`: " ++ @typeName(M));
    if (@typeInfo(@TypeOf(M.name)) != .EnumLiteral) @compileError("mach: module must have `pub const name = .foobar;`, found type:" ++ @typeName(M.name));
    if (events) {
        if (@hasDecl(M, "global_events")) validateEvents("mach: module ." ++ @tagName(M.name) ++ " global_events ", M.global_events);
        if (@hasDecl(M, "events")) validateEvents("mach: module ." ++ @tagName(M.name) ++ " events ", M.events);
        _ = ComponentTypesM(M);
    }
}

/// TODO: implement serialization constraints
/// For now this exists just to indicate things that we expect will be required to be serializable in
/// the future.
fn Serializable(comptime T: type) type {
    return T;
}

// TODO: add runtime module support
pub const ModuleID = u32;
pub const EventID = u32;

pub const AnyEvent = struct {
    module_id: ModuleID,
    event_id: EventID,
};

/// Type-returning variant of merge()
pub fn Merge(comptime tuple: anytype) type {
    if (@typeInfo(@TypeOf(tuple)) != .Struct or !@typeInfo(@TypeOf(tuple)).Struct.is_tuple) {
        @compileError("Expected to find a tuple, found: " ++ @typeName(@TypeOf(tuple)));
    }

    var tuple_fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    loop: inline for (tuple) |elem| {
        @setEvalBranchQuota(10_000);
        if (@typeInfo(@TypeOf(elem)) == .Type and @typeInfo(elem) == .Struct) {
            // Struct type
            validateModule(elem, false);
            for (tuple_fields) |field| if (@as(*const type, @ptrCast(field.default_value.?)).* == elem)
                continue :loop;

            var num_buf: [128]u8 = undefined;
            tuple_fields = tuple_fields ++ [_]std.builtin.Type.StructField{.{
                .name = std.fmt.bufPrintZ(&num_buf, "{d}", .{tuple_fields.len}) catch unreachable,
                .type = type,
                .default_value = &elem,
                .is_comptime = false,
                .alignment = if (@sizeOf(elem) > 0) @alignOf(elem) else 0,
            }};
        } else if (@typeInfo(@TypeOf(elem)) == .Struct and @typeInfo(@TypeOf(elem)).Struct.is_tuple) {
            // Nested tuple
            inline for (Merge(elem){}) |Nested| {
                validateModule(Nested, false);
                for (tuple_fields) |field| if (@as(*const type, @ptrCast(field.default_value.?)).* == Nested)
                    continue :loop;

                var num_buf: [128]u8 = undefined;
                tuple_fields = tuple_fields ++ [_]std.builtin.Type.StructField{.{
                    .name = std.fmt.bufPrintZ(&num_buf, "{d}", .{tuple_fields.len}) catch unreachable,
                    .type = type,
                    .default_value = &Nested,
                    .is_comptime = false,
                    .alignment = if (@sizeOf(Nested) > 0) @alignOf(Nested) else 0,
                }};
            }
        } else {
            @compileError("Expected to find a tuple or struct type, found: " ++ @typeName(@TypeOf(elem)));
        }
    }
    return @Type(.{
        .Struct = .{
            .is_tuple = true,
            .layout = .Auto,
            .decls = &.{},
            .fields = tuple_fields,
        },
    });
}

/// Given a tuple of module structs or module struct tuples:
///
/// ```
/// .{
///     .{ Baz, .{ Bar, Foo, .{ Fam } }, Bar },
///     Foo,
///     Bam,
///     .{ Foo, Bam },
/// }
/// ```
///
/// Returns a single tuple type with the struct types deduplicated:
///
/// .{ Baz, Bar, Foo, Fam, Bar, Bam }
///
pub fn merge(comptime tuple: anytype) Merge(tuple) {
    return Merge(tuple){};
}

/// Manages comptime .{A, B, C} modules and runtime modules.
pub fn Modules(comptime modules: anytype) type {
    // Verify that each module is valid.
    inline for (modules) |M| _ = ModuleInterface(M);

    return struct {
        pub const GlobalEvent = GlobalEventEnum(modules);
        pub const LocalEvent = LocalEventEnum(modules);

        /// Enables looking up a component type by module name and component name.
        /// e.g. @field(@field(ComponentTypesByName, "module_name"), "component_name")
        pub const component_types_by_name = ComponentTypesByName(modules){};

        const Event = struct {
            module_name: ?ModuleID,
            event_name: EventID,
            args_slice: []u8,
            args_alignment: u32,
        };
        const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);

        events_mu: std.Thread.RwLock = .{},
        args_queue: std.ArrayListUnmanaged(u8) = .{},
        events: EventQueue,
        mod: ModsByName(modules),
        // TODO: pass mods directly instead of ComponentTypesByName?
        entities: Entities(modules),
        debug_trace: bool,

        pub fn init(m: *@This(), allocator: std.mem.Allocator) !void {
            // TODO: switch Entities to stack allocation like Modules is
            var entities = try Entities(modules).init(allocator);
            errdefer entities.deinit();

            const debug_trace_str = std.process.getEnvVarOwned(
                allocator,
                "MACH_DEBUG_TRACE",
            ) catch |err| switch (err) {
                error.EnvironmentVariableNotFound => null,
                else => return err,
            };
            const debug_trace = if (debug_trace_str) |s| blk: {
                defer allocator.free(s);
                break :blk std.ascii.eqlIgnoreCase(s, "true");
            } else false;

            m.* = .{
                .entities = entities,
                // TODO(module): better default allocations
                .args_queue = try std.ArrayListUnmanaged(u8).initCapacity(allocator, 8 * 1024 * 1024),
                .events = EventQueue.init(allocator),
                .mod = undefined,
                .debug_trace = debug_trace,
            };
            errdefer m.args_queue.deinit(allocator);
            errdefer m.events.deinit();
            try m.events.ensureTotalCapacity(1024); // TODO(module): better default allocations

            // Default initialize m.mod
            inline for (@typeInfo(@TypeOf(m.mod)).Struct.fields) |field| {
                const Mod2 = @TypeOf(@field(m.mod, field.name));
                @field(m.mod, field.name) = Mod2{
                    .__is_initialized = false,
                    .__state = undefined,
                    .__entities = &m.entities,
                };
            }
        }

        pub fn deinit(m: *@This(), allocator: std.mem.Allocator) void {
            m.args_queue.deinit(allocator);
            m.events.deinit();
            m.entities.deinit();
        }

        /// Returns an args tuple representing the standard, uninjected, arguments which the given
        /// local event handler requires.
        fn LocalArgs(module_name: ModuleName(modules), event_name: LocalEvent) type {
            inline for (modules) |M| {
                _ = ModuleInterface(M); // Validate the module
                if (M.name != module_name) continue;
                return LocalArgsM(M, event_name);
            }
        }

        /// Returns an args tuple representing the standard, uninjected, arguments which the given
        /// global event handler requires.
        fn GlobalArgs(module_name: ModuleName(modules), event_name: GlobalEvent) type {
            inline for (modules) |M| {
                _ = ModuleInterface(M); // Validate the module
                if (M.name != module_name) continue;
                return GlobalArgsM(M, event_name);
            }
        }

        /// Converts an event enum for a single module, to an event enum for all modules.
        fn moduleToGlobalEvent(
            comptime M: type,
            comptime EventEnumM: anytype,
            comptime EventEnum: anytype,
            comptime event_name: EventEnumM(M),
        ) EventEnum(modules) {
            return comptime stringToEnum(EventEnum(modules), @tagName(event_name)).?;
        }

        /// Send a global event which the specified module defines
        pub fn sendGlobal(
            m: *@This(),
            // TODO: is a variant of this function where event_name is not comptime known, but asserted to be a valid enum, useful?
            comptime module_name: ModuleName(modules),
            // TODO(important): cleanup comptime
            comptime event_name: GlobalEventEnumM(@TypeOf(@field(m.mod, @tagName(module_name)).__state)),
            args: GlobalArgsM(@TypeOf(@field(m.mod, @tagName(module_name)).__state), event_name),
        ) void {
            // TODO: comptime safety/debugging
            const event_name_g: GlobalEvent = comptime moduleToGlobalEvent(
                // TODO(important): cleanup comptime
                @TypeOf(@field(m.mod, @tagName(module_name)).__state),
                GlobalEventEnumM,
                GlobalEventEnum,
                event_name,
            );
            m.sendInternal(null, @intFromEnum(event_name_g), args);
        }

        /// Send an event to a specific module
        pub fn send(
            m: *@This(),
            // TODO: is a variant of this function where module_name/event_name is not comptime known, but asserted to be a valid enum, useful?
            comptime module_name: ModuleName(modules),
            // TODO(important): cleanup comptime
            comptime event_name: LocalEventEnumM(@TypeOf(@field(m.mod, @tagName(module_name)).__state)),
            args: LocalArgsM(@TypeOf(@field(m.mod, @tagName(module_name)).__state), event_name),
        ) void {
            // TODO: comptime safety/debugging
            const event_name_g: LocalEvent = comptime moduleToGlobalEvent(
                // TODO(important): cleanup comptime
                @TypeOf(@field(m.mod, @tagName(module_name)).__state),
                LocalEventEnumM,
                LocalEventEnum,
                event_name,
            );
            m.sendInternal(@intFromEnum(module_name), @intFromEnum(event_name_g), args);
        }

        /// Send a global event, using a dynamic (not known to the compiled program) event name.
        pub fn sendGlobalDynamic(m: *@This(), event_name: EventID, args: anytype) void {
            // TODO: runtime safety/debugging
            // TODO: check args do not have obviously wrong things, like comptime values
            // TODO: if module_name and event_name are valid enums, can we type-check args at runtime?
            m.sendInternal(null, event_name, args);
        }

        /// Send an event to a specific module, using a dynamic (not known to the compiled program) module and event name.
        pub fn sendDynamic(m: *@This(), module_name: ModuleID, event_name: EventID, args: anytype) void {
            // TODO: runtime safety/debugging
            // TODO: check args do not have obviously wrong things, like comptime values
            // TODO: if module_name and event_name are valid enums, can we type-check args at runtime?
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
                .args_alignment = @alignOf(@TypeOf(args)),
            });
        }

        // TODO: docs
        pub fn moduleNameToID(m: *@This(), name: ModuleName(modules)) ModuleID {
            _ = m;
            return @intFromEnum(name);
        }

        // TODO: docs
        pub fn localEventToID(
            m: *@This(),
            comptime module_name: ModuleName(modules),
            // TODO(important): cleanup comptime
            local_event: LocalEventEnumM(@TypeOf(@field(m.mod, @tagName(module_name)).__state)),
        ) EventID {
            return @intFromEnum(local_event);
        }

        pub const DispatchOptions = struct {
            /// If specified, instructs that dispatching should occur until the specified local
            /// event has been dispatched.
            ///
            /// If null, dispatching occurs until the event queue is completely empty.
            until: ?struct {
                module_name: ModuleID,
                local_event: EventID,
            } = null,
        };

        /// Dispatches pending events, invoking their event handlers.
        ///
        /// Stack space must be large enough to fit the uninjected arguments of any event handler
        /// which may be invoked, e.g. 8MB. It may be heap-allocated.
        pub fn dispatch(
            m: *@This(),
            stack_space: []u8,
            options: DispatchOptions,
        ) !void {
            const Injectable = comptime blk: {
                var types: []const type = &[0]type{};
                for (@typeInfo(ModsByName(modules)).Struct.fields) |field| {
                    const ModPtr = @TypeOf(@as(*field.type, undefined));
                    types = types ++ [_]type{ModPtr};
                }
                break :blk std.meta.Tuple(types);
            };
            var injectable: Injectable = undefined;
            outer: inline for (@typeInfo(Injectable).Struct.fields) |field| {
                inline for (@typeInfo(ModsByName(modules)).Struct.fields) |injectable_field| {
                    if (*injectable_field.type == field.type) {
                        @field(injectable, field.name) = &@field(m.mod, injectable_field.name);
                        continue :outer;
                    }
                }
                @compileError("failed to initialize Injectable field (this is a bug): " ++ field.name ++ " " ++ @typeName(field.type));
            }
            return m.dispatchInternal(stack_space, options, injectable);
        }

        pub fn dispatchInternal(
            m: *@This(),
            stack_space: []u8,
            options: DispatchOptions,
            injectable: anytype,
        ) !void {
            @setEvalBranchQuota(10000);
            // TODO: optimize to reduce send contention
            // TODO: parallel / multi-threaded dispatch
            // TODO: PGO

            while (true) {
                // Dequeue the next event
                m.events_mu.lock();
                var ev = m.events.readItem() orelse {
                    m.events_mu.unlock();
                    return;
                };

                // Pop the arguments off the ev.args_slice stack, so we can release args_slice space.
                // Otherwise when we release m.events_mu someone may add more events' arguments
                // to the buffer which would make it tricky to find a good point-in-time to release
                // argument buffer space.
                const aligned_addr = std.mem.alignForward(usize, @intFromPtr(stack_space.ptr), ev.args_alignment);
                const align_offset = aligned_addr - @intFromPtr(stack_space.ptr);

                @memcpy(stack_space[align_offset .. align_offset + ev.args_slice.len], ev.args_slice);
                ev.args_slice = stack_space[align_offset .. align_offset + ev.args_slice.len];

                m.args_queue.shrinkRetainingCapacity(m.args_queue.items.len - ev.args_slice.len);
                m.events_mu.unlock();

                if (ev.module_name) |module_name| {
                    // Dispatch the local event
                    try m.callLocal(@enumFromInt(module_name), @enumFromInt(ev.event_name), ev.args_slice, injectable);

                    // If we only wanted to dispatch until this event, then return.
                    if (options.until) |until| {
                        if (until.module_name == module_name and until.local_event == ev.event_name) return;
                    }
                } else {
                    try m.callGlobal(@enumFromInt(ev.event_name), ev.args_slice, injectable);
                }
            }
        }

        /// Call global event handler with the specified name in all modules
        inline fn callGlobal(m: *@This(), event_name: GlobalEvent, args: []u8, injectable: anytype) !void {
            if (@typeInfo(@TypeOf(event_name)).Enum.fields.len == 0) return;
            switch (event_name) {
                inline else => |ev_name| {
                    inline for (modules) |M| {
                        // TODO(important): DRY with callLocal
                        _ = ModuleInterface(M); // Validate the module
                        if (@hasDecl(M, "global_events")) inline for (@typeInfo(@TypeOf(M.global_events)).Struct.fields) |field| {
                            comptime if (!std.mem.eql(u8, @tagName(ev_name), field.name)) continue;
                            if (m.debug_trace) log.debug("trace(global): .{s}.{s}", .{
                                @tagName(M.name),
                                @tagName(ev_name),
                            });
                            const handler = @field(M.global_events, @tagName(ev_name)).handler;
                            if (@typeInfo(@TypeOf(handler)) == .Type) continue; // Pre-declaration of what args an event has, nothing to do.
                            if (@typeInfo(@TypeOf(handler)) != .Fn) @compileError(std.fmt.comptimePrint("mach: module .{s} declares global event .{s} = .{{ .handler = T }}, expected fn but found: {s}", .{
                                @tagName(M.name),
                                @tagName(ev_name),
                                @typeName(@TypeOf(handler)),
                            }));
                            try callHandler(handler, args, injectable, "." ++ @tagName(M.name) ++ "." ++ @tagName(ev_name));
                        };
                    }
                },
            }
        }

        /// Call local event handler with the specified name in the specified module
        inline fn callLocal(m: *@This(), module_name: ModuleName(modules), event_name: LocalEvent, args: []u8, injectable: anytype) !void {
            if (@typeInfo(@TypeOf(event_name)).Enum.fields.len == 0) return;
            switch (event_name) {
                inline else => |ev_name| {
                    switch (module_name) {
                        inline else => |mod_name| {
                            // TODO(important): DRY with callGlobal
                            const M = @field(NamespacedModules(modules){}, @tagName(mod_name));
                            _ = ModuleInterface(M); // Validate the module
                            if (@hasDecl(M, "events")) inline for (@typeInfo(@TypeOf(M.events)).Struct.fields) |field| {
                                comptime if (!std.mem.eql(u8, @tagName(ev_name), field.name)) continue;
                                if (m.debug_trace) log.debug("trace: .{s}.{s}", .{
                                    @tagName(M.name),
                                    @tagName(ev_name),
                                });

                                const handler = @field(M.events, @tagName(ev_name)).handler;
                                if (@typeInfo(@TypeOf(handler)) == .Type) continue; // Pre-declaration of what args an event has, nothing to do.
                                if (@typeInfo(@TypeOf(handler)) != .Fn) @compileError(std.fmt.comptimePrint("mach: module .{s} declares local event .{s} = .{{ .handler = T }}, expected fn but found: {s}", .{
                                    @tagName(M.name),
                                    @tagName(ev_name),
                                    @typeName(@TypeOf(handler)),
                                }));
                                try callHandler(handler, args, injectable, @tagName(M.name) ++ "." ++ @tagName(ev_name));
                            };
                        },
                    }
                },
            }
        }

        /// Invokes an event handler with optionally injected arguments.
        inline fn callHandler(handler: anytype, args_data: []u8, injectable: anytype, comptime debug_name: anytype) !void {
            const Handler = @TypeOf(handler);
            const StdArgs = UninjectedArgsTuple(Handler);
            const std_args: *StdArgs = @alignCast(@ptrCast(args_data.ptr));
            const args = injectArgs(Handler, @TypeOf(injectable), injectable, std_args.*, debug_name);
            const Ret = @typeInfo(Handler).Fn.return_type orelse void;
            switch (@typeInfo(Ret)) {
                .ErrorUnion => try @call(.auto, handler, args),
                else => @call(.auto, handler, args),
            }
        }
    };
}

pub fn ModsByName(comptime modules: anytype) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    for (modules) |M| {
        const ModT = ModSet(modules).Mod(M);
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = @tagName(M.name),
            .type = ModT,
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(ModT),
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

// Note: Modules() causes analysis of event handlers' function signatures, whose parameters include
// references to ModSet(modules).Mod(). As a result, the type returned here may never invoke Modules()
// or depend on its result. However, it can analyze the global set of modules on its own, since no
// module's type should embed the result of Modules().
//
// In short, these calls are fine:
//
// Modules() -> ModSet()
// Modules() -> ModSet() -> Mod()
//
// But these are never permissible:
//
// ModSet() -> Modules()
// Mod() -> Modules()
//
pub fn ModSet(comptime modules: anytype) type {
    return struct {
        pub fn Mod(comptime M: anytype) type {
            const module_tag = M.name;
            const components = ComponentTypesM(M){};

            if (M.name == .entity) {
                // The .entity module is a special builtin module, with its own unique API.
                return struct {
                    /// Private/internal fields
                    __entities: *Entities(modules),
                    __is_initialized: bool,
                    __state: void,

                    pub const IsInjectedArgument = void;

                    pub inline fn read(comptime component_name: ComponentNameM(M)) Entities(modules).ComponentQuery {
                        return .{ .read = .{
                            .module = M.name,
                            .component = comptime stringToEnum(ComponentName(modules), @tagName(component_name)).?,
                        } };
                    }

                    /// Returns a new entity.
                    pub inline fn new(m: *@This()) !EntityID {
                        return m.__entities.new();
                    }

                    /// Removes an entity.
                    pub inline fn remove(m: *@This(), entity: EntityID) !void {
                        try m.__entities.remove(entity);
                    }
                };
            }

            return struct {
                /// Private/internal fields
                __entities: *Entities(modules),
                __is_initialized: bool,
                __state: M,

                pub const IsInjectedArgument = void;

                pub inline fn read(comptime component_name: ComponentNameM(M)) Entities(modules).ComponentQuery {
                    return .{ .read = .{
                        .module = M.name,
                        .component = comptime stringToEnum(ComponentName(modules), @tagName(component_name)).?,
                    } };
                }

                pub inline fn write(comptime component_name: ComponentNameM(M)) Entities(modules).ComponentQuery {
                    return .{ .write = .{
                        .module = M.name,
                        .component = comptime stringToEnum(ComponentName(modules), @tagName(component_name)).?,
                    } };
                }

                /// Initializes the module's state
                pub inline fn init(m: *@This(), s: M) void {
                    m.__state = s;
                    m.__is_initialized = true;
                }

                /// Returns a mutable pointer to the module's state (literally the struct type of the module.)
                ///
                /// A panic will occur if m.init(M{}) was not called previously.
                pub inline fn state(m: *@This()) *M {
                    if (is_debug) if (!m.__is_initialized) @panic("mach: module ." ++ @tagName(M.name) ++ " state is not initialized, ensure foo_mod.init(.{}) is called!");
                    return &m.__state;
                }

                /// Returns a read-only version of the module's state. If an event handler is
                /// read-only (i.e. only ever reads state/components/entities), then its events can
                /// be skipped during e.g. record-and-replay of events from disk.
                ///
                /// Only use this if the module state being serialized and deserialized after the
                /// event handler runs would accurately reproduce the state of the event handler
                /// being run.
                pub inline fn stateReadOnly(m: *@This()) *const M {
                    if (is_debug) if (!m.__is_initialized) @panic("mach: module ." ++ @tagName(M.name) ++ " state is not initialized, ensure mod.init(.{}) is called!");
                    return &m.__state;
                }

                /// Sets the named component to the specified value for the given entity,
                /// moving the entity from it's current archetype table to the new archetype
                /// table if required.
                pub inline fn set(
                    m: *@This(),
                    entity: EntityID,
                    comptime component_name: ComponentNameM(M),
                    component: @field(components, @tagName(component_name)).type,
                ) !void {
                    try m.__entities.setComponent(entity, module_tag, component_name, component);
                }

                /// gets the named component of the given type (which must be correct, otherwise undefined
                /// behavior will occur). Returns null if the component does not exist on the entity.
                pub inline fn get(
                    m: *@This(),
                    entity: EntityID,
                    comptime component_name: ComponentNameM(M),
                ) ?@field(components, @tagName(component_name)).type {
                    return m.__entities.getComponent(entity, module_tag, component_name);
                }

                /// Removes the named component from the entity, or noop if it doesn't have such a component.
                pub inline fn remove(
                    m: *@This(),
                    entity: EntityID,
                    comptime component_name: ComponentNameM(M),
                ) !void {
                    try m.__entities.removeComponent(entity, module_tag, component_name);
                }

                pub inline fn send(m: *@This(), comptime event_name: LocalEventEnumM(M), args: LocalArgsM(M, event_name)) void {
                    const ModulesT = Modules(modules);
                    const MByName = ModsByName(modules);
                    const mod_ptr: *MByName = @alignCast(@fieldParentPtr(MByName, @tagName(module_tag), m));
                    const mods = @fieldParentPtr(ModulesT, "mod", mod_ptr);
                    mods.send(module_tag, event_name, args);
                }

                pub inline fn sendGlobal(m: *@This(), comptime event_name: GlobalEventEnumM(M), args: GlobalArgsM(M, event_name)) void {
                    const ModulesT = Modules(modules);
                    const MByName = ModsByName(modules);
                    const mod_ptr: *MByName = @alignCast(@fieldParentPtr(MByName, @tagName(module_tag), m));
                    const mods = @fieldParentPtr(ModulesT, "mod", mod_ptr);
                    mods.sendGlobal(module_tag, event_name, args);
                }

                pub inline fn event(_: *@This(), comptime event_name: LocalEventEnumM(M)) AnyEvent {
                    const module_name_g: ModuleName(modules) = M.name;
                    const event_name_g: Modules(modules).LocalEvent = comptime Modules(modules).moduleToGlobalEvent(
                        M,
                        LocalEventEnumM,
                        LocalEventEnum,
                        event_name,
                    );
                    return .{
                        .module_id = @intFromEnum(module_name_g),
                        .event_id = @intFromEnum(event_name_g),
                    };
                }

                pub inline fn sendAnyEvent(m: *@This(), ev: AnyEvent) void {
                    const ModulesT = Modules(modules);
                    const MByName = ModsByName(modules);
                    const mod_ptr: *MByName = @alignCast(@fieldParentPtr(MByName, @tagName(module_tag), m));
                    const mods = @fieldParentPtr(ModulesT, "mod", mod_ptr);
                    mods.sendDynamic(ev.module_id, ev.event_id, .{});
                }
            };
        }
    };
}

// Given a function, its standard arguments and injectable arguments, performs injection and
// returns the actual argument tuple which would be used to call the function.
inline fn injectArgs(comptime Function: type, comptime Injectable: type, injectable_args: Injectable, std_args: UninjectedArgsTuple(Function), comptime debug_name: anytype) std.meta.ArgsTuple(Function) {
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
        if (@typeInfo(arg.type) == .Pointer and
            @typeInfo(std.meta.Child(arg.type)) == .Struct and
            @hasDecl(std.meta.Child(arg.type), "IsInjectedArgument"))
        {
            // Argument is declared as injectable, but we do not have a value to inject for it.
            // This can be the case if e.g. a Mod() parameter is specified, but that module is
            // not registered.
            //
            // TODO: we could make this error message less verbose, currently it reads e.g.
            //
            // src/module/module.zig:736:13: error: mach: cannot inject argument of type: *module.module.ModSet(.{Core, gfx.Sprite, gfx.SpritePipeline, App, Glyphs}).Mod(Core) - is it registered in your program's top-level `pub const modules = .{};`? used by mach_core.start
            //
            @compileError("mach: cannot inject argument of type: " ++ @typeName(arg.type) ++ " - is it registered in your program's top-level `pub const modules = .{};`? used by " ++ debug_name);
        }

        // First standard argument
        @field(args, arg.name) = std_args[std_args_index];
        std_args_index += 1;
    }
    return args;
}

// Given a function type, and an args tuple of injectable parameters, returns the set of function
// parameters which would **not** be injected.
fn UninjectedArgsTuple(comptime Function: type) type {
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
    return std.meta.Tuple(std_args);
}

// TODO: cannot use std.meta.stringToEnum for some reason; an issue with its internal comptime map and u0 values
pub fn stringToEnum(comptime T: type, str: []const u8) ?T {
    inline for (@typeInfo(T).Enum.fields) |enumField| {
        if (std.mem.eql(u8, str, enumField.name)) {
            return @field(T, enumField.name);
        }
    }
}

// TODO: tests
fn LocalArgsM(comptime M: type, event_name: anytype) type {
    return ArgsM(M, event_name, "events");
}

// TODO: tests
fn GlobalArgsM(comptime M: type, event_name: anytype) type {
    return ArgsM(M, event_name, "global_events");
}

fn ArgsM(comptime M: type, event_name: anytype, comptime which: anytype) type {
    _ = ModuleInterface(M); // Validate the module
    if (!@hasDecl(M, which)) return @TypeOf(.{});

    const m_events = @field(M, which); // M.events or M.global_events
    inline for (@typeInfo(@TypeOf(m_events)).Struct.fields) |field| {
        comptime if (!std.mem.eql(u8, field.name, @tagName(event_name))) continue;
        if (!@hasField(@TypeOf(m_events), @tagName(event_name))) @compileError(std.fmt.comptimePrint("mach: module .{s} declares no {s} event .{s}", .{
            @tagName(M.name),
            which,
            @tagName(event_name),
        }));
        const handler = @field(m_events, @tagName(event_name)).handler;
        const Handler = switch (@typeInfo(@TypeOf(handler))) {
            .Type => handler, // Pre-declaration of what args an event has
            .Fn => blk: {
                if (@typeInfo(@TypeOf(handler)) != .Fn) @compileError(std.fmt.comptimePrint("mach: module .{s} declares {s} event .{s} = .{{ .handler = T }}, expected fn but found: {s}", .{
                    @tagName(M.name),
                    which,
                    @tagName(event_name),
                    @typeName(@TypeOf(handler)),
                }));
                break :blk @TypeOf(handler);
            },
            else => unreachable,
        };
        return UninjectedArgsTuple(Handler);
    }
    @compileError("mach: module ." ++ @tagName(M.name) ++ " has no " ++ which ++ " event handler for ." ++ @tagName(event_name));
}

// TODO: important! DRY with GlobalEventEnum
/// enum describing every possible comptime-known local event name
fn LocalEventEnum(comptime modules: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    for (modules) |M| {
        _ = ModuleInterface(M); // Validate the module
        if (@hasDecl(M, "events")) inline for (@typeInfo(@TypeOf(M.events)).Struct.fields) |field| {
            const exists_already = blk: {
                for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, field.name)) break :blk true;
                break :blk false;
            };
            if (!exists_already) {
                enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = field.name, .value = i }};
                i += 1;
            }
        };
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

// TODO: important! DRY with GlobalEventEnumM
/// enum describing every possible comptime-known local event name
fn LocalEventEnumM(comptime M: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    _ = ModuleInterface(M); // Validate the module
    if (@hasDecl(M, "events")) inline for (@typeInfo(@TypeOf(M.events)).Struct.fields) |field| {
        const exists_already = blk: {
            for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, field.name)) break :blk true;
            break :blk false;
        };
        if (!exists_already) {
            enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = field.name, .value = i }};
            i += 1;
        }
    };
    return @Type(.{
        .Enum = .{
            .tag_type = if (enum_fields.len > 0) std.math.IntFittingRange(0, enum_fields.len - 1) else u0,
            .fields = enum_fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_exhaustive = true,
        },
    });
}

// TODO: important! DRY with LocalEventEnum
/// enum describing every possible comptime-known global event name
fn GlobalEventEnum(comptime modules: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    for (modules) |M| {
        _ = ModuleInterface(M); // Validate the module
        if (@hasDecl(M, "global_events")) inline for (@typeInfo(@TypeOf(M.global_events)).Struct.fields) |field| {
            const exists_already = blk: {
                for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, field.name)) break :blk true;
                break :blk false;
            };
            if (!exists_already) {
                enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = field.name, .value = i }};
                i += 1;
            }
        };
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

// TODO: important! DRY with LocalEventEnumM
/// enum describing every possible comptime-known global event name
fn GlobalEventEnumM(comptime M: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    _ = ModuleInterface(M); // Validate the module
    if (@hasDecl(M, "global_events")) inline for (@typeInfo(@TypeOf(M.global_events)).Struct.fields) |field| {
        const exists_already = blk: {
            for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, field.name)) break :blk true;
            break :blk false;
        };
        if (!exists_already) {
            enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = field.name, .value = i }};
            i += 1;
        }
    };
    return @Type(.{
        .Enum = .{
            .tag_type = if (enum_fields.len > 0) std.math.IntFittingRange(0, enum_fields.len - 1) else u0,
            .fields = enum_fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_exhaustive = true,
        },
    });
}

/// enum describing component names for the given module only
pub fn ComponentNameM(comptime M: type) type {
    const components = ComponentTypesM(M){};
    return std.meta.FieldEnum(@TypeOf(components));
}

/// enum describing component names for all of the modules
pub fn ComponentName(comptime modules: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: usize = 0;
    inline for (modules) |M| {
        search: for (@typeInfo(ComponentTypesM(M)).Struct.fields) |field| {
            for (enum_fields) |existing| if (std.mem.eql(u8, existing.name, field.name)) continue :search;
            enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{
                .name = field.name,
                .value = i,
            }};
            i += 1;
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
pub fn ModuleName(comptime modules: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    for (modules, 0..) |M, i| {
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

// TODO: tests
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

// TODO: tests
fn validateEvents(comptime error_prefix: anytype, comptime events: anytype) void {
    if (@typeInfo(@TypeOf(events)) != .Struct or @typeInfo(@TypeOf(events)).Struct.is_tuple) {
        @compileError(error_prefix ++ "expected a struct .{}, found: " ++ @typeName(@TypeOf(events)));
    }
    inline for (@typeInfo(@TypeOf(events)).Struct.fields) |field| {
        const Event = field.type;
        if (@typeInfo(Event) != .Struct) @compileError(std.fmt.comptimePrint(
            error_prefix ++ "expected .{s} = .{{}}, found type: {s}",
            .{ field.name, @typeName(Event) },
        ));
        const event = @field(events, field.name);

        // Verify .handler field
        if (!@hasField(Event, "handler")) @compileError(std.fmt.comptimePrint(
            error_prefix ++ ".{s} missing field `.handler = fn` or `.handler = @TypeOf(fn)`",
            .{field.name},
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
            error_prefix ++ ".{s} field .handler expected `.handler = fn` or `.handler = @TypeOf(fn)`, found found: {s}",
            .{ field.name, @typeName(@TypeOf(event.handler)) },
        ));

        switch (@typeInfo(@TypeOf(event.handler))) {
            .Fn => _ = UninjectedArgsTuple(@TypeOf(event.handler)),
            .Type => _ = UninjectedArgsTuple(event.handler),
            else => unreachable,
        }
    }
}

// TODO: tests
/// Returns a struct type defining all module's components by module name, e.g.:
///
/// ```
/// struct {
///     physics: struct {
///         location: @TypeOf() = .{ .type = Vec3, .description = null },
///         rotation: @TypeOf() = .{ .type = Vec2, .description = "rotation component" },
///     },
///     renderer: struct {
///         location: @TypeOf() = .{ .type = Vec2, .description = null },
///     },
/// }
/// ```
pub fn ComponentTypesByName(comptime modules: anytype) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    inline for (modules) |M| {
        const MC = ComponentTypesM(M);
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = @tagName(M.name),
            .type = MC,
            .default_value = &MC{},
            .is_comptime = true,
            .alignment = @alignOf(MC),
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

// TODO: tests
/// Returns a struct type defining the module's components, e.g.:
///
/// ```
/// struct {
///     location: @TypeOf() = .{ .type = Vec3, .description = null },
///     rotation: @TypeOf() = .{ .type = Vec2, .description = "rotation component" },
/// }
/// ```
fn ComponentTypesM(comptime M: anytype) type {
    validateModule(M, false);
    const error_prefix = "mach: module ." ++ @tagName(M.name) ++ " .components ";
    if (!@hasDecl(M, "components")) {
        return struct {};
    }
    if (@typeInfo(@TypeOf(M.components)) != .Struct or @typeInfo(@TypeOf(M.components)).Struct.is_tuple) {
        @compileError(error_prefix ++ "expected a struct .{}, found: " ++ @typeName(@TypeOf(M.components)));
    }
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    inline for (@typeInfo(@TypeOf(M.components)).Struct.fields) |field| {
        const Component = field.type;
        if (@typeInfo(Component) != .Struct) @compileError(std.fmt.comptimePrint(
            error_prefix ++ "expected .{s} = .{{}}, found type: {s}",
            .{ field.name, @typeName(Component) },
        ));
        const component = @field(M.components, field.name);

        // Verify .type = Foo, field
        if (!@hasField(Component, "type")) @compileError(std.fmt.comptimePrint(
            error_prefix ++ ".{s} missing field `.type = T`",
            .{field.name},
        ));
        if (@typeInfo(@TypeOf(component.type)) != .Type) @compileError(std.fmt.comptimePrint(
            error_prefix ++ ".{s} expected field `.type = T`, found: {s}",
            .{ field.name, @typeName(@TypeOf(component.type)) },
        ));

        const description = blk: {
            if (@hasField(Component, "description")) {
                if (!isString(@TypeOf(component.description))) @compileError(std.fmt.comptimePrint(
                    error_prefix ++ ".{s} expected (optional) field `.description = \"foo\"`, found: {s}",
                    .{ field.name, @typeName(@TypeOf(component.description)) },
                ));
                break :blk component.description;
            } else break :blk null;
        };

        const NSComponent = struct {
            type: type,
            description: ?[]const u8,
        };
        const ns_component = NSComponent{ .type = component.type, .description = description };
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = field.name,
            .type = NSComponent,
            .default_value = &ns_component,
            .is_comptime = true,
            .alignment = @alignOf(NSComponent),
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

fn isString(comptime S: type) bool {
    return switch (@typeInfo(S)) {
        .Pointer => |p| switch (p.size) {
            .Many, .Slice => p.child == u8,
            .One => switch (@typeInfo(p.child)) {
                .Array => |a| a.child == u8,
                else => false,
            },
            else => false,
        },
        else => false,
    };
}

test isString {
    const x: [*:0]const u8 = "foobar";
    const y: []const u8 = "foobar";
    const z: *const [6:0]u8 = "foobar";
    try testing.expect(bool, true).eql(isString(@TypeOf(x)));
    try testing.expect(bool, true).eql(isString(@TypeOf(y)));
    try testing.expect(bool, true).eql(isString(@TypeOf(z)));
    try testing.expect(bool, true).eql(isString(@TypeOf("baz")));

    const v0: []const u32 = undefined;
    const v1: u32 = undefined;
    const v2: *u8 = undefined;
    try testing.expect(bool, false).eql(isString(@TypeOf(v0)));
    try testing.expect(bool, false).eql(isString(@TypeOf(v1)));
    try testing.expect(bool, false).eql(isString(@TypeOf(v2)));
}

test {
    testing.refAllDeclsRecursive(@This());
}

test ModuleInterface {
    _ = ModuleInterface(struct {
        // Physics module state
        pointer: usize,

        // Globally unique module name
        pub const name = .engine_physics;

        /// Physics module components
        pub const components = .{
            .location = .{ .type = @Vector(3, f32), .description = "A location component" },
        };

        pub const global_events = .{
            .tick = .{ .handler = tick },
        };

        fn tick() !void {}
    });
}

test Modules {
    const Physics = ModuleInterface(struct {
        // Physics module state
        pointer: usize,

        // Globally unique module name
        pub const name = .engine_physics;

        /// Physics module components
        pub const components = .{
            .location = .{ .type = @Vector(3, f32), .description = "A location component" },
        };

        pub const global_events = .{
            .tick = .{ .handler = tick },
        };

        fn tick() !void {}
    });

    const Renderer = ModuleInterface(struct {
        pub const name = .engine_renderer;
        pub const global_events = .{
            .tick = .{ .handler = tick },
        };

        fn tick() !void {}
    });

    const Sprite2D = ModuleInterface(struct {
        pub const name = .engine_sprite2d;
    });

    var modules: Modules(merge(.{
        builtin_modules,
        Physics,
        Renderer,
        Sprite2D,
    })) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);
    testing.refAllDeclsRecursive(Physics);
    testing.refAllDeclsRecursive(Renderer);
    testing.refAllDeclsRecursive(Sprite2D);
}

test "event name" {
    const Physics = ModuleInterface(struct {
        pub const name = .engine_physics;
        pub const global_events = .{
            .foo = .{ .handler = foo },
            .bar = .{ .handler = bar },
        };
        pub const events = .{
            .baz = .{ .handler = baz },
            .bam = .{ .handler = bam },
        };

        fn foo() !void {}
        fn bar() !void {}
        fn baz() !void {}
        fn bam() !void {}
    });

    const Renderer = ModuleInterface(struct {
        pub const name = .engine_renderer;
        pub const global_events = .{
            .foo_unused = .{ .handler = fn (f32, i32) void },
            .bar_unused = .{ .handler = fn (i32, f32) void },
            .tick = .{ .handler = tick },
            .foo = .{ .handler = foo },
            .bar = .{ .handler = bar },
        };

        fn tick() !void {}
        fn foo() !void {} // same .foo name as .engine_physics.foo
        fn bar() !void {} // same .bar name as .engine_physics.bar
    });

    const Sprite2D = ModuleInterface(struct {
        pub const name = .engine_sprite2d;
        pub const global_events = .{
            .tick = .{ .handler = tick },
            .foobar = .{ .handler = fooBar },
        };

        fn tick() void {} // same .tick as .engine_renderer.tick
        fn fooBar() void {}
    });

    const Ms = Modules(merge(.{
        builtin_modules,
        Physics,
        Renderer,
        Sprite2D,
    }));

    const locals = @typeInfo(Ms.LocalEvent).Enum;
    try testing.expect(type, u1).eql(locals.tag_type);
    try testing.expect(usize, 2).eql(locals.fields.len);
    try testing.expect([]const u8, "baz").eql(locals.fields[0].name);
    try testing.expect([]const u8, "bam").eql(locals.fields[1].name);

    const globals = @typeInfo(Ms.GlobalEvent).Enum;
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
    const Physics = ModuleInterface(struct {
        pub const name = .engine_physics;
    });
    const Renderer = ModuleInterface(struct {
        pub const name = .engine_renderer;
    });
    const Sprite2D = ModuleInterface(struct {
        pub const name = .engine_sprite2d;
    });
    const modules = merge(.{
        builtin_modules,
        Physics,
        Renderer,
        Sprite2D,
    });
    _ = Modules(modules);
    const info = @typeInfo(ModuleName(modules)).Enum;

    try testing.expect(type, u2).eql(info.tag_type);
    try testing.expect(usize, 4).eql(info.fields.len);
    try testing.expect([]const u8, "entity").eql(info.fields[0].name);
    try testing.expect([]const u8, "engine_physics").eql(info.fields[1].name);
    try testing.expect([]const u8, "engine_renderer").eql(info.fields[2].name);
    try testing.expect([]const u8, "engine_sprite2d").eql(info.fields[3].name);
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
    try testing.expect(struct {}, .{}).eql(injectArgs(fn () void, @TypeOf(.{}), .{}, .{}, ""));
    const injectable = .{ foo_ptr, bar_ptr, baz_ptr };
    try testing.expect(struct {}, .{}).eql(injectArgs(fn () void, @TypeOf(injectable), injectable, .{}, ""));

    // Standard parameters only, no injected
    try testing.expect(std.meta.Tuple(&.{i32}), .{0}).eql(injectArgs(fn (a: i32) void, @TypeOf(injectable), injectable, .{0}, ""));
    try testing.expect(std.meta.Tuple(&.{ i32, f32 }), .{ 1, 0.5 }).eql(injectArgs(fn (a: i32, b: f32) void, @TypeOf(injectable), injectable, .{ 1, 0.5 }, ""));

    // Injected parameters only, no standard
    try testing.expect(std.meta.Tuple(&.{*Foo}), .{foo_ptr}).eql(injectArgs(fn (a: *Foo) void, @TypeOf(injectable), injectable, .{}, ""));
    try testing.expect(std.meta.Tuple(&.{ *Foo, *Bar }), .{ foo_ptr, bar_ptr }).eql(injectArgs(fn (a: *Foo, b: *Bar) void, @TypeOf(injectable), injectable, .{}, ""));
    try testing.expect(std.meta.Tuple(&.{ *Foo, *Bar, *Baz }), .{ foo_ptr, bar_ptr, baz_ptr }).eql(injectArgs(fn (a: *Foo, b: *Bar, c: *Baz) void, @TypeOf(injectable), injectable, .{}, ""));
    try testing.expect(std.meta.Tuple(&.{ *Bar, *Baz, *Foo }), .{ bar_ptr, baz_ptr, foo_ptr }).eql(injectArgs(fn (a: *Bar, b: *Baz, c: *Foo) void, @TypeOf(injectable), injectable, .{}, ""));
    try testing.expect(std.meta.Tuple(&.{ *Foo, *Foo, *Baz }), .{ foo_ptr, foo_ptr, baz_ptr }).eql(injectArgs(fn (a: *Foo, b: *Foo, c: *Baz) void, @TypeOf(injectable), injectable, .{}, ""));

    // As long as the argument is a Struct or *Struct with an IsInjectedArgument decl, it is
    // considered an injected argument.
    // try testing.expect(std.meta.Tuple(&.{*const Foo}), .{foo_ptr}).eql(injectArgs(fn (a: *const Foo) void, @TypeOf(injectable), injectable, .{}, ""));
    const injectable2 = .{ foo, foo_ptr, bar_ptr, baz_ptr };
    try testing.expect(std.meta.Tuple(&.{Foo}), .{foo_ptr.*}).eql(injectArgs(fn (a: Foo) void, @TypeOf(injectable2), injectable2, .{}, ""));

    // Order doesn't matter, injected arguments can be placed inbetween any standard arguments, etc.
    try testing.expect(std.meta.Tuple(&.{ i32, *Foo, *Foo, *Baz }), .{ 1337, foo_ptr, foo_ptr, baz_ptr }).eql(injectArgs(fn (z: i32, a: *Foo, b: *Foo, c: *Baz) void, @TypeOf(injectable), injectable, .{1337}, ""));
    try testing.expect(std.meta.Tuple(&.{ i32, *Foo, f32, *Foo, *Baz }), .{ 1337, foo_ptr, 1.337, foo_ptr, baz_ptr }).eql(injectArgs(fn (z: i32, a: *Foo, w: f32, b: *Foo, c: *Baz) void, @TypeOf(injectable), injectable, .{ 1337, 1.337 }, ""));
    try testing.expect(std.meta.Tuple(&.{ i32, f32, *Foo, *Foo, *Baz }), .{ 1337, 1.337, foo_ptr, foo_ptr, baz_ptr }).eql(injectArgs(fn (z: i32, w: f32, a: *Foo, b: *Foo, c: *Baz) void, @TypeOf(injectable), injectable, .{ 1337, 1.337 }, ""));
    try testing.expect(std.meta.Tuple(&.{ *Foo, *Foo, *Baz, i32, f32 }), .{ foo_ptr, foo_ptr, baz_ptr, 1337, 1.337 }).eql(injectArgs(fn (az: *Foo, b: *Foo, c: *Baz, z: i32, w: f32) void, @TypeOf(injectable), injectable, .{ 1337, 1.337 }, ""));
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
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn () void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn () void));

    // Standard parameters only, no injected
    TupleTester.assertTuple(.{i32}, UninjectedArgsTuple(fn (a: i32) void));
    TupleTester.assertTuple(.{ i32, f32 }, UninjectedArgsTuple(fn (a: i32, b: f32) void));

    // Injected parameters only, no standard
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *Foo) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *Bar) void));

    // As long as the argument is a Struct or *Struct with an IsInjectedArgument decl, it is
    // considered an injected argument.
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *Foo, b: *Bar, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: Foo) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: Bar) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *const Foo) void));
    TupleTester.assertTuple(.{}, UninjectedArgsTuple(fn (a: *const Bar) void));

    // Order doesn't matter, injected arguments can be placed inbetween any standard arguments, etc.
    TupleTester.assertTuple(.{ f32, bool }, UninjectedArgsTuple(fn (i: f32, a: *Foo, k: bool, b: *Bar, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(fn (i: f32, a: *Foo, b: *Bar, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(fn (a: *Foo, i: f32, b: *Bar, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(fn (a: *Foo, b: *Bar, i: f32, c: Foo, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(fn (a: *Foo, b: *Bar, c: Foo, i: f32, d: Bar) void));
    TupleTester.assertTuple(.{f32}, UninjectedArgsTuple(fn (a: *Foo, b: *Bar, c: Foo, d: Bar, i: f32) void));
}

test "event name calling" {
    const global = struct {
        var ticks: usize = 0;
        var physics_updates: usize = 0;
        var physics_calc: usize = 0;
        var renderer_updates: usize = 0;
    };
    const Physics = ModuleInterface(struct {
        pub const name = .engine_physics;
        pub const global_events = .{
            .tick = .{ .handler = tick },
        };
        pub const events = .{
            .update = .{ .handler = update },
            .calc = .{ .handler = calc },
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
    const Renderer = ModuleInterface(struct {
        pub const name = .engine_renderer;
        pub const global_events = .{
            .tick = .{ .handler = tick },
        };
        pub const events = .{
            .update = .{ .handler = update },
        };

        fn tick() void {
            global.ticks += 1;
        }

        fn update() void {
            global.renderer_updates += 1;
        }
    });

    const modules2 = merge(.{
        builtin_modules,
        Physics,
        Renderer,
    });
    var modules: Modules(modules2) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);

    try modules.callGlobal(.tick, &.{}, .{});
    try testing.expect(usize, 2).eql(global.ticks);

    // Check we can use .callGlobal() with a runtime-known event name.
    const alloc = try testing.allocator.create(u3);
    defer testing.allocator.destroy(alloc);
    const GE = @TypeOf(modules).GlobalEvent;
    const LE = @TypeOf(modules).LocalEvent;
    alloc.* = @intFromEnum(@as(GE, .tick));

    const global_event_name = @as(GE, @enumFromInt(alloc.*));
    try modules.callGlobal(global_event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);

    // Check we can use .callLocal() with a runtime-known event and module name.
    const m_alloc = try testing.allocator.create(u3);
    defer testing.allocator.destroy(m_alloc);
    const M = ModuleName(modules2);

    m_alloc.* = @intFromEnum(@as(M, .engine_renderer));
    alloc.* = @intFromEnum(@as(LE, .update));
    var module_name = @as(M, @enumFromInt(m_alloc.*));
    var local_event_name = @as(LE, @enumFromInt(alloc.*));
    try modules.callLocal(module_name, local_event_name, &.{}, .{});
    try modules.callLocal(module_name, local_event_name, &.{}, .{});
    try testing.expect(usize, 4).eql(global.ticks);
    try testing.expect(usize, 0).eql(global.physics_updates);
    try testing.expect(usize, 2).eql(global.renderer_updates);

    m_alloc.* = @intFromEnum(@as(M, .engine_physics));
    alloc.* = @intFromEnum(@as(LE, .update));
    module_name = @as(M, @enumFromInt(m_alloc.*));
    local_event_name = @as(LE, @enumFromInt(alloc.*));
    try modules.callLocal(module_name, local_event_name, &.{}, .{});
    try testing.expect(usize, 1).eql(global.physics_updates);

    m_alloc.* = @intFromEnum(@as(M, .engine_physics));
    alloc.* = @intFromEnum(@as(LE, .calc));
    module_name = @as(M, @enumFromInt(m_alloc.*));
    local_event_name = @as(LE, @enumFromInt(alloc.*));
    try modules.callLocal(module_name, local_event_name, &.{}, .{});
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
    const Minimal = ModuleInterface(struct {
        pub const name = .engine_minimal;
    });
    const Physics = ModuleInterface(struct {
        pub const name = .engine_physics;
        pub const global_events = .{
            .tick = .{ .handler = tick },
        };
        pub const events = .{
            .update = .{ .handler = update },
            .update_with_struct_arg = .{ .handler = updateWithStructArg },
            .calc = .{ .handler = calc },
        };

        fn tick() void {
            global.ticks += 1;
        }

        fn update() void {
            global.physics_updates += 1;
        }

        const MyStruct = extern struct {
            x: [4]extern struct { x: @Vector(4, f32) } = undefined,
            y: [4]extern struct { x: @Vector(4, f32) } = undefined,
        };
        fn updateWithStructArg(arg: MyStruct) void {
            _ = arg;
            global.physics_updates += 1;
        }

        fn calc() void {
            global.physics_calc += 1;
        }
    });
    const Renderer = ModuleInterface(struct {
        pub const name = .engine_renderer;
        pub const global_events = .{
            .tick = .{ .handler = tick },
            .frame_done = .{ .handler = fn (i32) void },
        };
        pub const events = .{
            .update = .{ .handler = update },
            .basic_args = .{ .handler = basicArgs },
            .injected_args = .{ .handler = injectedArgs },
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

    const modules2 = merge(.{
        builtin_modules,
        Minimal,
        Physics,
        Renderer,
    });
    var modules: Modules(modules2) = undefined;
    try modules.init(testing.allocator);
    defer modules.deinit(testing.allocator);

    const GE = @TypeOf(modules).GlobalEvent;
    const LE = @TypeOf(modules).LocalEvent;
    const M = ModuleName(modules2);

    // Global events
    //
    // The 2nd parameter (arguments to the tick event handler) is inferred based on the `pub fn tick`
    // global event handler declaration within a module. It is required that all global event handlers
    // of the same name have the same standard arguments, although they can start with different
    // injected arguments.
    modules.sendGlobal(.engine_renderer, .tick, .{});
    try testing.expect(usize, 0).eql(global.ticks);
    var stack_space: [8 * 1024 * 1024]u8 = undefined;
    try modules.dispatchInternal(&stack_space, .{}, .{&foo});
    try testing.expect(usize, 2).eql(global.ticks);
    // TODO: make sendDynamic take an args type to avoid footguns with comptime values, etc.
    modules.sendGlobalDynamic(@intFromEnum(@as(GE, .tick)), .{});
    try modules.dispatchInternal(&stack_space, .{}, .{&foo});
    try testing.expect(usize, 4).eql(global.ticks);

    // Global events which are not handled by anyone yet can be written as `pub const fooBar = fn() void;`
    // within a module, which allows pre-declaring that `fooBar` is a valid global event, and enables
    // its arguments to be inferred still like this:
    modules.sendGlobal(.engine_renderer, .frame_done, .{1337});

    // Local events
    modules.send(.engine_renderer, .update, .{});
    try modules.dispatchInternal(&stack_space, .{}, .{&foo});
    try testing.expect(usize, 1).eql(global.renderer_updates);
    modules.send(.engine_physics, .update, .{});
    modules.send(.engine_physics, .update_with_struct_arg, .{.{}});
    modules.sendDynamic(
        @intFromEnum(@as(M, .engine_physics)),
        @intFromEnum(@as(LE, .calc)),
        .{},
    );
    try modules.dispatchInternal(&stack_space, .{}, .{&foo});
    try testing.expect(usize, 2).eql(global.physics_updates);
    try testing.expect(usize, 1).eql(global.physics_calc);

    // Local events
    modules.send(.engine_renderer, .basic_args, .{ @as(u32, 1), @as(u32, 2) }); // TODO: match arguments against fn ArgsTuple, for correctness and type inference
    modules.send(.engine_renderer, .injected_args, .{ @as(u32, 1), @as(u32, 2) });
    try modules.dispatchInternal(&stack_space, .{}, .{&foo});
    try testing.expect(usize, 3).eql(global.basic_args_sum);
    try testing.expect(usize, 3).eql(foo.injected_args_sum);
}
