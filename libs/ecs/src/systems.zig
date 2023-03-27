const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const testing = std.testing;
const math = std.math;
const StructField = std.builtin.Type.StructField;
const EnumField = std.builtin.Type.EnumField;
const UnionField = std.builtin.Type.UnionField;

const Entities = @import("entities.zig").Entities;

/// Validates that a module matches the expected type layout.
///
/// An ECS module has components, systems, state & more.
pub fn Module(comptime M: anytype) type {
    if (@hasDecl(M, "name")) {
        _ = @tagName(M.name);
    } else @compileError("Module missing `pub const name = .foobar;`");
    if (@hasDecl(M, "Message")) _ = Messages(M.Message);

    // TODO(ecs): validate M.components decl signature, if present.
    // TODO(ecs): validate M.update method signature, if present.
    return M;
}

/// Validates that a list of module matches the expected type layout.
///
/// ECS modules have components, systems, state & more.
pub fn Modules(comptime modules: anytype) @TypeOf(modules) {
    inline for (modules) |m| _ = Module(m);
    return modules;
}

/// Returns a tagged union representing the messages, turning this:
///
/// ```
/// .{ .tick = void, .foo = i32 }
/// ```
///
/// Into `T`:
///
/// ```
/// const T = union(MessagesTag(messages)) {
///     .tick = void,
///     .foo = i32,
/// };
/// ```
pub fn Messages(comptime messages: anytype) type {
    var fields: []const UnionField = &[0]UnionField{};
    const message_fields = std.meta.fields(@TypeOf(messages));
    inline for (message_fields) |message_field| {
        const message_type = @field(messages, message_field.name);
        fields = fields ++ [_]std.builtin.Type.UnionField{.{
            .name = message_field.name,
            .type = message_type,
            .alignment = if (message_type == void) 0 else @alignOf(message_type),
        }};
    }

    return @Type(.{
        .Union = .{
            .layout = .Auto,
            .tag_type = MessagesTag(messages),
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
        },
    });
}

/// Returns the tag enum for a tagged union representing the messages, turning this:
///
/// ```
/// .{ .tick = void, .foo = i32 }
/// ```
///
/// Into this:
///
/// ```
/// enum { .tick, .foo };
/// ```
pub fn MessagesTag(comptime messages: anytype) type {
    var fields: []const EnumField = &[0]EnumField{};
    const message_fields = std.meta.fields(@TypeOf(messages));
    inline for (message_fields, 0..) |message_field, index| {
        fields = fields ++ [_]std.builtin.Type.EnumField{.{
            .name = message_field.name,
            .value = index,
        }};
    }

    return @Type(.{
        .Enum = .{
            .tag_type = std.meta.Int(.unsigned, @floatToInt(u16, math.ceil(math.log2(@intToFloat(f64, message_fields.len))))),
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_exhaustive = true,
        },
    });
}

const NoComponents = @TypeOf(.{});
const NoState = @TypeOf(.{});

/// Returns the namespaced components struct **type**.
//
/// Consult `namespacedComponents` for how a value of this type looks.
fn NamespacedComponents(comptime modules: anytype) type {
    var fields: []const StructField = &[0]StructField{};
    inline for (std.meta.fields(@TypeOf(modules))) |module_field| {
        const module = @field(modules, module_field.name);
        const module_name = @tagName(@field(module, "name"));
        if (@hasDecl(module, "components")) {
            fields = fields ++ [_]std.builtin.Type.StructField{.{
                .name = module_name,
                .type = @TypeOf(module.components),
                .default_value = null,
                .is_comptime = false,
                .alignment = @alignOf(@TypeOf(module.components)),
            }};
        } else {
            fields = fields ++ [_]std.builtin.Type.StructField{.{
                .name = module_name,
                .type = NoComponents,
                .default_value = null,
                .is_comptime = false,
                .alignment = @alignOf(NoComponents),
            }};
        }
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

/// Extracts namespaces components from modules like this. A module is said to have components if
/// the struct has a `pub const components`. This function returns a namespaced components value
/// like e.g.:
///
/// ```
/// .{
///     .renderer = .{
///         .location = Vec3,
///         .rotation = Vec3,
///     },
///     .physics2d = .{
///         .location = Vec2
///         .velocity = Vec2,
///     },
/// }
/// ```
///
fn namespacedComponents(comptime modules: anytype) NamespacedComponents(modules) {
    var x: NamespacedComponents(modules) = undefined;
    inline for (std.meta.fields(@TypeOf(modules))) |module_field| {
        const module = @field(modules, module_field.name);
        const module_name = @tagName(@field(module, "name"));
        if (@hasDecl(module, "components")) {
            @field(x, module_name) = module.components;
        } else {
            @field(x, module_name) = .{};
        }
    }
    return x;
}

/// Extracts namespaced state from modules (a module is said to have state if the struct has
/// any fields), returning a type like e.g.:
///
/// ```
/// struct{
///     renderer: struct{
///         foo: *Bar,
///         baz: Bam,
///     },
///     physics2d: struct{
///         foo: *Instance,
///     },
/// }
/// ```
///
fn NamespacedState(comptime modules: anytype) type {
    var fields: []const StructField = &[0]StructField{};
    inline for (std.meta.fields(@TypeOf(modules))) |module_field| {
        const module = @field(modules, module_field.name);
        const module_name = @tagName(@field(module, "name"));
        const state_fields = std.meta.fields(module);
        const State = if (state_fields.len > 0) @Type(.{
            .Struct = .{
                .layout = .Auto,
                .is_tuple = false,
                .fields = state_fields,
                .decls = &[_]std.builtin.Type.Declaration{},
            },
        }) else NoState;
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = module_name,
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

pub fn World(comptime modules: anytype) type {
    const all_components = namespacedComponents(modules);
    return struct {
        allocator: Allocator,
        entities: Entities(all_components),
        state: NamespacedState(modules),

        const Self = @This();

        pub fn init(allocator: Allocator) !Self {
            return Self{
                .allocator = allocator,
                .entities = try Entities(all_components).init(allocator),
                .state = undefined,
            };
        }

        pub fn deinit(world: *Self) void {
            world.entities.deinit();
        }

        /// Gets a state value called `.state_tag` from the module named `.module_tag`
        pub fn get(world: *Self, comptime module_tag: anytype, comptime state_tag: anytype) @TypeOf(@field(
            @field(world.state, @tagName(module_tag)),
            @tagName(state_tag),
        )) {
            return comptime @field(
                @field(world.state, @tagName(module_tag)),
                @tagName(state_tag),
            );
        }

        /// Sets a state value called `.state_tag` in the module named `.module_tag`
        pub fn set(
            world: *Self,
            comptime module_tag: anytype,
            comptime state_tag: anytype,
            value: @TypeOf(@field(
                @field(world.state, @tagName(module_tag)),
                @tagName(state_tag),
            )),
        ) void {
            comptime @field(
                @field(world.state, @tagName(module_tag)),
                @tagName(state_tag),
            ) = value;
        }

        /// Broadcasts a state message to all modules that are subscribed to it.
        pub fn send(world: *Self, comptime msg_tag: anytype) !void {
            inline for (std.meta.fields(@TypeOf(modules))) |module_field| {
                const module = @field(modules, module_field.name);
                if (@hasDecl(module, @tagName(msg_tag))) {
                    const handler = @field(module, @tagName(msg_tag));
                    try handler(world);
                }
            }
        }
    };
}
