const std = @import("std");
const mem = std.mem;
const StructField = std.builtin.Type.StructField;

const mach = @import("../main.zig");
const Entities = @import("entities.zig").Entities;
const EntityID = @import("entities.zig").EntityID;
const comp = @import("comptime.zig");

pub fn World(comptime mods: anytype) type {
    const Injectable = struct {}; // TODO
    const modules = mach.Modules(mods, Injectable);

    return struct {
        allocator: mem.Allocator,
        entities: Entities(NamespacedComponents(mods){}),
        mod: Mods(),

        const Self = @This();

        pub fn Mod(comptime Module: anytype) type {
            const module_tag = Module.name;
            const State = @TypeOf(@field(@as(NamespacedState(mods), undefined), @tagName(module_tag)));
            const components = @field(NamespacedComponents(mods){}, @tagName(module_tag));
            return struct {
                state: State,
                entities: *Entities(NamespacedComponents(mods){}),
                allocator: mem.Allocator,

                /// Sets the named component to the specified value for the given entity,
                /// moving the entity from it's current archetype table to the new archetype
                /// table if required.
                pub inline fn set(
                    m: *@This(),
                    entity: EntityID,
                    comptime component_name: std.meta.DeclEnum(components),
                    component: @field(components, @tagName(component_name)),
                ) !void {
                    const mod_ptr: *Self.Mods() = @alignCast(@fieldParentPtr(Mods(), @tagName(module_tag), m));
                    const world = @fieldParentPtr(Self, "mod", mod_ptr);
                    try world.entities.setComponent(entity, module_tag, component_name, component);
                }

                /// gets the named component of the given type (which must be correct, otherwise undefined
                /// behavior will occur). Returns null if the component does not exist on the entity.
                pub inline fn get(
                    m: *@This(),
                    entity: EntityID,
                    comptime component_name: std.meta.DeclEnum(components),
                ) ?@field(components, @tagName(component_name)) {
                    const mod_ptr: *Self.Mods() = @alignCast(@fieldParentPtr(Mods(), @tagName(module_tag), m));
                    const world = @fieldParentPtr(Self, "mod", mod_ptr);
                    return world.entities.getComponent(entity, module_tag, component_name);
                }

                /// Removes the named component from the entity, or noop if it doesn't have such a component.
                pub inline fn remove(
                    m: *@This(),
                    entity: EntityID,
                    comptime component_name: std.meta.DeclEnum(components),
                ) !void {
                    const mod_ptr: *Self.Mods() = @alignCast(@fieldParentPtr(Mods(), @tagName(module_tag), m));
                    const world = @fieldParentPtr(Self, "mod", mod_ptr);
                    try world.entities.removeComponent(entity, module_tag, component_name);
                }

                pub fn send(m: *@This(), comptime msg_tag: anytype, args: anytype) !void {
                    const mod_ptr: *Self.Mods() = @alignCast(@fieldParentPtr(Mods(), @tagName(module_tag), m));
                    const world = @fieldParentPtr(Self, "mod", mod_ptr);
                    return world.sendStr(module_tag, @tagName(msg_tag), args);
                }

                /// Returns a new entity.
                pub fn newEntity(m: *@This()) !EntityID {
                    const mod_ptr: *Self.Mods() = @alignCast(@fieldParentPtr(Mods(), @tagName(module_tag), m));
                    const world = @fieldParentPtr(Self, "mod", mod_ptr);
                    return world.entities.new();
                }

                /// Removes an entity.
                pub fn removeEntity(m: *@This(), entity: EntityID) !void {
                    const mod_ptr: *Self.Mods() = @alignCast(@fieldParentPtr(Mods(), @tagName(module_tag), m));
                    const world = @fieldParentPtr(Self, "mod", mod_ptr);
                    try world.entities.removeEntity(entity);
                }
            };
        }

        fn Mods() type {
            var fields: []const StructField = &[0]StructField{};
            inline for (modules.modules) |M| {
                fields = fields ++ [_]std.builtin.Type.StructField{.{
                    .name = @tagName(M.name),
                    .type = Mod(M),
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(Mod(M)),
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

        pub fn init(allocator: mem.Allocator) !Self {
            return Self{
                .allocator = allocator,
                .entities = try Entities(NamespacedComponents(mods){}).init(allocator),
                .mod = undefined,
            };
        }

        pub fn deinit(world: *Self) void {
            world.entities.deinit();
        }

        /// Broadcasts an event to all modules that are subscribed to it.
        ///
        /// The message tag corresponds with the handler method name to be invoked. For example,
        /// if `send(.tick)` is invoked, all modules which declare a `pub fn tick` will be invoked.
        ///
        /// Events sent by Mach itself, or the application itself, may be single words. To prevent
        /// name conflicts, events sent by modules provided by a library should prefix their events
        /// with their module name. For example, a module named `.ziglibs_imgui` should use event
        /// names like `.ziglibsImguiClick`, `.ziglibsImguiFoobar`.
        pub fn send(world: *Self, comptime optional_module_tag: anytype, comptime msg_tag: anytype, args: anytype) !void {
            return world.sendStr(optional_module_tag, @tagName(msg_tag), args);
        }

        pub fn sendStr(world: *Self, comptime optional_module_tag: anytype, comptime msg: anytype, args: anytype) !void {
            // Check for any module that has a handler function named msg (e.g. `fn init` would match "init")
            inline for (modules.modules) |M| {
                const EventHandlers = blk: {
                    switch (@typeInfo(@TypeOf(optional_module_tag))) {
                        .Null => break :blk M,
                        .EnumLiteral => {
                            // Send this message only to the specified module
                            if (M.name != optional_module_tag) continue;
                            if (!@hasDecl(M, "local")) @compileError("Module ." ++ @tagName(M.name) ++ " does not have a `pub const local` event handler for message ." ++ msg);
                            if (!@hasDecl(M.local, msg)) @compileError("Module ." ++ @tagName(M.name) ++ " does not have a `pub const local` event handler for message ." ++ msg);
                            break :blk M.local;
                        },
                        .Optional => if (optional_module_tag) |v| {
                            // Send this message only to the specified module
                            if (M.name != v) continue;
                            if (!@hasDecl(M, "local")) @compileError("Module ." ++ @tagName(M.name) ++ " does not have a `pub const local` event handler for message ." ++ msg);
                            if (!@hasDecl(M.local, msg)) @compileError("Module ." ++ @tagName(M.name) ++ " does not have a `pub const local` event handler for message ." ++ msg);
                            break :blk M.local;
                        },
                        else => @panic("unexpected optional_module_tag type: " ++ @typeName(@TypeOf(optional_module_tag))),
                    }
                };
                if (!@hasDecl(EventHandlers, msg)) continue;

                // Determine which parameters the handler function wants. e.g.:
                //
                // pub fn init(eng: *mach.Engine) !void
                // pub fn init(eng: *mach.Engine, mach: *mach.Engine.Mod) !void
                //
                const handler = @field(EventHandlers, msg);

                // Build a tuple of parameters that we can pass to the function, based on what
                // *mach.Mod(T) types it expects as arguments.
                var params: std.meta.ArgsTuple(@TypeOf(handler)) = undefined;
                comptime var argIndex = 0;
                inline for (@typeInfo(@TypeOf(params)).Struct.fields) |param| {
                    comptime var found = false;
                    inline for (@typeInfo(Mods()).Struct.fields) |f| {
                        if (param.type == *f.type) {
                            // TODO: better initialization place for modules
                            @field(@field(world.mod, f.name), "entities") = &world.entities;
                            @field(@field(world.mod, f.name), "allocator") = world.allocator;

                            @field(params, param.name) = &@field(world.mod, f.name);
                            found = true;
                            break;
                        } else if (param.type == *Self) {
                            @field(params, param.name) = world;
                            found = true;
                            break;
                        } else if (param.type == f.type) {
                            @compileError("Module handler " ++ @tagName(M.name) ++ "." ++ msg ++ " should be *T not T: " ++ @typeName(param.type));
                        }
                    }
                    if (!found) {
                        @field(params, param.name) = args[argIndex];
                        argIndex += 1;
                    }
                }

                // Invoke the handler
                try @call(.auto, handler, params);
            }
        }
    };
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
