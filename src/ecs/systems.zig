const std = @import("std");
const mem = std.mem;
const StructField = std.builtin.Type.StructField;

const mach = @import("../main.zig");
const Entities = @import("entities.zig").Entities;
const EntityID = @import("entities.zig").EntityID;
const comp = @import("comptime.zig");
const Module = @import("../module.zig").Module;
const NamespacedComponents = @import("../module.zig").NamespacedComponents;
const MComponents = @import("../module.zig").MComponents;

pub fn World(comptime mods: anytype) type {
    const StateT = NamespacedState(mods);
    return struct {
        allocator: mem.Allocator,
        entities: Entities(NamespacedComponents(mods){}),
        modules: Modules,
        mod: Mods,

        const Modules = mach.Modules(mods);

        const WorldT = @This();
        pub fn Mod(comptime M: anytype) type {
            const module_tag = M.name;
            const State = @TypeOf(@field(@as(StateT, undefined), @tagName(module_tag)));
            const components = MComponents(M){};
            return struct {
                state: State,
                entities: *Entities(NamespacedComponents(mods){}),
                allocator: mem.Allocator,

                pub const IsInjectedArgument = void;

                /// Sets the named component to the specified value for the given entity,
                /// moving the entity from it's current archetype table to the new archetype
                /// table if required.
                pub inline fn set(
                    m: *@This(),
                    entity: EntityID,
                    // TODO: cleanup comptime
                    comptime component_name: std.meta.FieldEnum(@TypeOf(components)),
                    component: @field(components, @tagName(component_name)).type,
                ) !void {
                    const mod_ptr: *Mods = @alignCast(@fieldParentPtr(Mods, @tagName(module_tag), m));
                    const world = @fieldParentPtr(WorldT, "mod", mod_ptr);
                    try world.entities.setComponent(entity, module_tag, component_name, component);
                }

                /// gets the named component of the given type (which must be correct, otherwise undefined
                /// behavior will occur). Returns null if the component does not exist on the entity.
                pub inline fn get(
                    m: *@This(),
                    entity: EntityID,
                    // TODO: cleanup comptime
                    comptime component_name: std.meta.FieldEnum(@TypeOf(components)),
                ) ?@field(components, @tagName(component_name)).type {
                    const mod_ptr: *Mods = @alignCast(@fieldParentPtr(Mods, @tagName(module_tag), m));
                    const world = @fieldParentPtr(WorldT, "mod", mod_ptr);
                    return world.entities.getComponent(entity, module_tag, component_name);
                }

                /// Removes the named component from the entity, or noop if it doesn't have such a component.
                pub inline fn remove(
                    m: *@This(),
                    entity: EntityID,
                    // TODO: cleanup comptime
                    comptime component_name: std.meta.FieldEnum(@TypeOf(components)),
                ) !void {
                    const mod_ptr: *Mods = @alignCast(@fieldParentPtr(Mods, @tagName(module_tag), m));
                    const world = @fieldParentPtr(WorldT, "mod", mod_ptr);
                    try world.entities.removeComponent(entity, module_tag, component_name);
                }

                pub inline fn send(m: *@This(), comptime event_name: Modules.LocalEvent, args: Modules.LocalArgsM(M, event_name)) void {
                    const mod_ptr: *Mods = @alignCast(@fieldParentPtr(Mods, @tagName(module_tag), m));
                    const world = @fieldParentPtr(WorldT, "mod", mod_ptr);
                    world.modules.sendToModule(module_tag, event_name, args);
                }

                pub inline fn sendGlobal(m: *@This(), comptime event_name: Modules.GlobalEvent, args: Modules.GlobalArgsM(M, event_name)) void {
                    const mod_ptr: *Mods = @alignCast(@fieldParentPtr(Mods, @tagName(module_tag), m));
                    const world = @fieldParentPtr(WorldT, "mod", mod_ptr);
                    world.modules.sendGlobal(module_tag, event_name, args);
                }

                // TODO: eliminate this
                pub fn dispatchNoError(m: *@This()) void {
                    const mod_ptr: *Mods = @alignCast(@fieldParentPtr(Mods, @tagName(module_tag), m));
                    const world = @fieldParentPtr(WorldT, "mod", mod_ptr);
                    world.modules.dispatch(world.injectable()) catch |err| @panic(@errorName(err));
                }

                /// Returns a new entity.
                pub fn newEntity(m: *@This()) !EntityID {
                    const mod_ptr: *Mods = @alignCast(@fieldParentPtr(Mods, @tagName(module_tag), m));
                    const world = @fieldParentPtr(WorldT, "mod", mod_ptr);
                    return world.entities.new();
                }

                /// Removes an entity.
                pub fn removeEntity(m: *@This(), entity: EntityID) !void {
                    const mod_ptr: *Mods = @alignCast(@fieldParentPtr(Mods, @tagName(module_tag), m));
                    const world = @fieldParentPtr(WorldT, "mod", mod_ptr);
                    try world.entities.removeEntity(entity);
                }
            };
        }

        pub const Mods = blk: {
            var fields: []const StructField = &[0]StructField{};
            for (mods) |M| {
                fields = fields ++ [_]std.builtin.Type.StructField{.{
                    .name = @tagName(M.name),
                    .type = Mod(M),
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(Mod(M)),
                }};
            }
            break :blk @Type(.{
                .Struct = .{
                    .layout = .Auto,
                    .is_tuple = false,
                    .fields = fields,
                    .decls = &[_]std.builtin.Type.Declaration{},
                },
            });
        };

        const Injectable = blk: {
            var types: []const type = &[0]type{};
            for (@typeInfo(Mods).Struct.fields) |field| {
                const ModPtr = @TypeOf(@as(*field.type, undefined));
                types = types ++ [_]type{ModPtr};
            }
            break :blk std.meta.Tuple(types);
        };
        fn injectable(world: *@This()) Injectable {
            var v: Injectable = undefined;
            outer: inline for (@typeInfo(Injectable).Struct.fields) |field| {
                inline for (@typeInfo(Mods).Struct.fields) |injectable_field| {
                    if (*injectable_field.type == field.type) {
                        @field(v, field.name) = &@field(world.mod, injectable_field.name);

                        // TODO: better module initialization location
                        @field(v, field.name).entities = &world.entities;
                        @field(v, field.name).allocator = world.allocator;
                        continue :outer;
                    }
                }
                @compileError("failed to initialize Injectable field (this is a bug): " ++ field.name ++ " " ++ @typeName(field.type));
            }
            return v;
        }

        pub fn dispatch(world: *@This()) !void {
            try world.modules.dispatch(world.injectable());
        }

        pub fn init(world: *@This(), allocator: mem.Allocator) !void {
            // TODO: switch Entities to stack allocation like Modules and World
            var entities = try Entities(NamespacedComponents(mods){}).init(allocator);
            errdefer entities.deinit();
            world.* = @This(){
                .allocator = allocator,
                .entities = entities,
                .modules = undefined,
                .mod = undefined,
            };
            try world.modules.init(allocator);
        }

        pub fn deinit(world: *@This()) void {
            world.entities.deinit();
            world.modules.deinit(world.allocator);
        }
    };
}

// TODO: reconsider state concept
fn NamespacedState(comptime modules: anytype) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    inline for (modules) |M| {
        // TODO: can't verify module here because it would introduce a dependency loop
        // _ = Module(M);
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
