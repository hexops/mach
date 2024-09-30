const std = @import("std");
const mach = @import("../main.zig");
const StringTable = @import("StringTable.zig");

/// An ID representing a mach object. This is an opaque identifier which effectively encodes:
///
/// * An array index that can be used to O(1) lookup the actual data / struct fields of the object.
/// * The generation (or 'version') of the object, enabling detecting use-after-object-delete in
///   many (but not all) cases.
/// * Which module the object came from, allowing looking up type information or the module name
///   from ID alone.
/// * Which list of objects in a module the object came from, allowing looking up type information
///   or the object type name - which enables debugging and type safety when passing opaque IDs
///   around.
///
pub const ObjectID = u64;

const ObjectTypeID = u16;

const PackedObjectTypeID = packed struct(u16) {
    // 2^10 (1024) modules in an application
    module_name_id: u10,
    // 2^6 (64) lists of objects per module
    object_name_id: u6,
};

pub fn Objects(comptime T: type) type {
    return struct {
        internal: struct {
            allocator: std.mem.Allocator,

            /// Mutex to be held when operating on these objects.
            mu: std.Thread.Mutex = .{},

            /// A registered ID indicating the type of objects being represented. This can be
            /// thought of as a hash of the module name + field name where this objects list is
            /// stored.
            type_id: ObjectTypeID,

            /// The actual object data
            data: std.MultiArrayList(T) = .{},

            /// Whether a given slot in data[i] is dead or not
            dead: std.bit_set.DynamicBitSetUnmanaged = .{},

            /// The current generation number of data[i], when data[i] becomes dead and then alive
            /// again, this number is incremented by one.
            generation: std.ArrayListUnmanaged(Generation) = .{},

            /// The recycling bin which tells which data indices are dead and can be reused.
            recycling_bin: std.ArrayListUnmanaged(Index) = .{},

            /// The number of objects that could not fit in the recycling bin and hence were thrown
            /// on the floor and forgotten about. This means there are dead items recorded by dead.set(index)
            /// which aren't in the recycling_bin, and the next call to new() may consider cleaning up.
            thrown_on_the_floor: u32 = 0,
        },

        pub const IsMachObjects = void;

        const Generation = u16;
        const Index = u32;

        const PackedID = packed struct(u64) {
            type_id: ObjectTypeID,
            generation: Generation,
            index: Index,
        };

        pub const Slice = struct {
            index: Index,
            objs: *Objects(T),

            /// Same as Objects(T).set but doesn't employ safety checks
            pub fn set(objs: *@This(), id: ObjectID, value: T) void {
                const data = &objs.internal.data;
                const unpacked: PackedID = @bitCast(id);
                data.set(unpacked.index, value);
            }

            /// Same as Objects(T).get but doesn't employ safety checks
            pub fn get(objs: *@This(), id: ObjectID) ?T {
                const data = &objs.internal.data;
                const unpacked: PackedID = @bitCast(id);
                return data.get(unpacked.index);
            }

            /// Same as Objects(T).delete but doesn't employ safety checks
            pub fn delete(objs: *@This(), id: ObjectID) void {
                const dead = &objs.internal.dead;
                const recycling_bin = &objs.internal.recycling_bin;

                const unpacked: PackedID = @bitCast(id);
                if (recycling_bin.items.len < recycling_bin.capacity) {
                    recycling_bin.appendAssumeCapacity(unpacked.index);
                } else objs.internal.thrown_on_the_floor += 1;

                dead.set(unpacked.index);
            }

            pub fn next(iter: *Slice) ?ObjectID {
                const dead = &iter.objs.internal.dead;
                const generation = &iter.objs.internal.generation;
                const num_objects = generation.items.len;

                while (true) {
                    if (iter.index == num_objects) {
                        iter.index = 0;
                        return null;
                    }
                    defer iter.index += 1;

                    if (!dead.isSet(iter.index)) return @bitCast(PackedID{
                        .generation = generation.items[iter.index],
                        .index = iter.index,
                    });
                }
            }
        };

        /// Tries to acquire the mutex without blocking the caller's thread.
        /// Returns `false` if the calling thread would have to block to acquire it.
        /// Otherwise, returns `true` and the caller should `unlock()` the Mutex to release it.
        pub fn tryLock(objs: *@This()) bool {
            return objs.internal.mu.tryLock();
        }

        /// Acquires the mutex, blocking the caller's thread until it can.
        /// It is undefined behavior if the mutex is already held by the caller's thread.
        /// Once acquired, call `unlock()` on the Mutex to release it.
        pub fn lock(objs: *@This()) void {
            objs.internal.mu.lock();
        }

        /// Releases the mutex which was previously acquired with `lock()` or `tryLock()`.
        /// It is undefined behavior if the mutex is unlocked from a different thread that it was locked from.
        pub fn unlock(objs: *@This()) void {
            objs.internal.mu.unlock();
        }

        pub inline fn new(objs: *@This(), value: T) std.mem.Allocator.Error!ObjectID {
            const allocator = objs.internal.allocator;
            const data = &objs.internal.data;
            const dead = &objs.internal.dead;
            const generation = &objs.internal.generation;
            const recycling_bin = &objs.internal.recycling_bin;

            // The recycling bin should always be big enough, but we check at this point if 10% of
            // all objects have been thrown on the floor. If they have, we find them and grow the
            // recycling bin to fit them.
            if (objs.internal.thrown_on_the_floor >= (data.len / 10)) {
                var iter = dead.iterator(.{});
                while (iter.next()) |index| try recycling_bin.append(allocator, @intCast(index));
                objs.internal.thrown_on_the_floor = 0;
            }

            if (recycling_bin.popOrNull()) |index| {
                // Reuse a free slot from the recycling bin.
                dead.unset(index);
                const gen = generation.items[index] + 1;
                generation.items[index] = gen;
                return @bitCast(PackedID{
                    .type_id = objs.internal.type_id,
                    .generation = gen,
                    .index = index,
                });
            }

            // Ensure we have space for the new object
            try data.ensureUnusedCapacity(allocator, 1);
            try dead.resize(allocator, data.capacity, true);
            try generation.ensureUnusedCapacity(allocator, 1);

            const index = data.len;
            data.appendAssumeCapacity(value);
            dead.unset(index);
            generation.appendAssumeCapacity(0);
            return @bitCast(PackedID{
                .type_id = objs.internal.type_id,
                .generation = 0,
                .index = @intCast(index),
            });
        }

        pub fn set(objs: *@This(), id: ObjectID, value: T) void {
            const data = &objs.internal.data;
            const dead = &objs.internal.dead;
            const generation = &objs.internal.generation;

            const unpacked: PackedID = @bitCast(id);
            if (unpacked.generation != generation.items[unpacked.index]) {
                @panic("mach: set() called with an object that is no longer valid");
            }
            if (dead.isSet(unpacked.index)) {
                @panic("mach: set() called on a dead object");
            }
            data.set(unpacked.index, value);
        }

        pub fn get(objs: *@This(), id: ObjectID) ?T {
            const data = &objs.internal.data;
            const dead = &objs.internal.dead;
            const generation = &objs.internal.generation;

            const unpacked: PackedID = @bitCast(id);
            if (unpacked.generation != generation.items[unpacked.index]) {
                @panic("mach: get() called with an object that is no longer valid");
            }
            if (dead.isSet(unpacked.index)) {
                @panic("mach: get() called on a dead object");
            }
            return data.get(unpacked.index);
        }

        pub fn delete(objs: *@This(), id: ObjectID) void {
            const data = &objs.internal.data;
            const dead = &objs.internal.dead;
            const generation = &objs.internal.generation;
            const recycling_bin = &objs.internal.recycling_bin;

            // TODO(object): decide whether to disable safety checks like this in some conditions,
            // e.g. in release builds
            const unpacked: PackedID = @bitCast(id);
            if (unpacked.generation != generation.items[unpacked.index]) {
                @panic("mach: delete() called with an object that is no longer valid");
            }
            if (dead.isSet(unpacked.index)) {
                @panic("mach: delete() called on a dead object");
            }

            if (recycling_bin.items.len < recycling_bin.capacity) {
                recycling_bin.appendAssumeCapacity(unpacked.index);
            } else objs.internal.thrown_on_the_floor += 1;

            dead.set(unpacked.index);
            if (mach.is_debug) data.set(unpacked.index, undefined);
        }

        pub fn slice(objs: *@This()) Slice {
            return Slice{
                .index = 0,
                .objs = objs,
            };
        }
    };
}

/// Unique identifier for every module in the program, including those only known at runtime.
pub const ModuleID = u32;

/// Unique identifier for a function within a single module, including those only known at runtime.
pub const ModuleFunctionID = u16;

/// Unique identifier for a function within a module, including those only known at runtime.
pub const FunctionID = struct { module_id: ModuleID, fn_id: ModuleFunctionID };

pub fn Mod(comptime M: type) type {
    return struct {
        pub const IsMachMod = void;

        pub const module_name = M.mach_module;
        pub const Module = M;

        id: ModFunctionIDs(M),
        _ctx: *anyopaque,
        _run: *const fn (ctx: *anyopaque, fn_id: FunctionID) void,

        pub fn run(r: *const @This(), fn_id: FunctionID) void {
            r._run(r._ctx, fn_id);
        }

        pub fn call(r: *const @This(), comptime f: ModuleFunctionName2(M)) void {
            const fn_id = @field(r.id, @tagName(f));
            r.run(fn_id);
        }
    };
}

pub fn ModFunctionIDs(comptime Module: type) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    for (Module.mach_systems) |fn_name| {
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = @tagName(fn_name),
            .type = FunctionID,
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(FunctionID),
        }};
    }
    return @Type(.{
        .Struct = .{
            .layout = .auto,
            .is_tuple = false,
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
        },
    });
}

/// Enum describing all declarations for a given comptime-known module.
// TODO: unify with ModuleFunctionName
fn ModuleFunctionName2(comptime M: type) type {
    validate(M);
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    var i: u32 = 0;
    inline for (M.mach_systems) |fn_tag| {
        // TODO: verify decls are Fn or mach.schedule() decl
        enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = @tagName(fn_tag), .value = i }};
        i += 1;
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

pub fn Modules(module_lists: anytype) type {
    inline for (moduleTuple(module_lists)) |module| {
        validate(module);
    }
    return struct {
        /// All modules
        pub const modules = moduleTuple(module_lists);

        /// Enum describing every module name compiled into the program.
        pub const ModuleName = NameEnum(modules);

        mods: ModulesByName(modules),

        module_names: StringTable = .{},
        object_names: StringTable = .{},

        /// Enum describing all declarations for a given comptime-known module.
        fn ModuleFunctionName(comptime module_name: ModuleName) type {
            const module = @field(ModuleTypesByName(modules){}, @tagName(module_name));
            validate(module);

            var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
            var i: u32 = 0;
            inline for (module.mach_systems) |fn_tag| {
                // TODO: verify decls are Fn or mach.schedule() decl
                enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = @tagName(fn_tag), .value = i }};
                i += 1;
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

        pub fn init(allocator: std.mem.Allocator) std.mem.Allocator.Error!@This() {
            var m: @This() = .{
                .mods = undefined,
            };
            inline for (@typeInfo(@TypeOf(m.mods)).Struct.fields) |field| {
                // TODO(objects): module-state-init
                const Mod2 = @TypeOf(@field(m.mods, field.name));
                var mod: Mod2 = undefined;
                const module_name_id = try m.module_names.indexOrPut(allocator, @tagName(Mod2.mach_module));
                inline for (@typeInfo(@TypeOf(mod)).Struct.fields) |mod_field| {
                    if (@typeInfo(mod_field.type) == .Struct and @hasDecl(mod_field.type, "IsMachObjects")) {
                        const object_name_id = try m.module_names.indexOrPut(allocator, mod_field.name);

                        // TODO: use packed struct(TypeID) here. Same thing, just get the type from central location
                        const object_type_id: u16 = @bitCast(PackedObjectTypeID{
                            .module_name_id = @intCast(module_name_id),
                            .object_name_id = @intCast(object_name_id),
                        });

                        @field(mod, mod_field.name).internal = .{
                            .allocator = allocator,
                            .type_id = object_type_id,
                        };
                    }
                }
                @field(m.mods, field.name) = mod;
            }
            return m;
        }

        pub fn deinit(m: *@This(), allocator: std.mem.Allocator) void {
            // TODO
            _ = m;
            _ = allocator;
        }

        pub fn Module(module_tag_or_type: anytype) type {
            const module_name: ModuleName = blk: {
                if (@typeInfo(@TypeOf(module_tag_or_type)) == .EnumLiteral or @typeInfo(@TypeOf(module_tag_or_type)) == .Enum) break :blk @as(ModuleName, module_tag_or_type);
                validate(module_tag_or_type);
                break :blk module_tag_or_type.mach_module;
            };

            const module = @field(ModuleTypesByName(modules){}, @tagName(module_name));
            validate(module);

            return struct {
                mods: *ModulesByName(modules),
                modules: *Modules(module_lists),

                pub const mod_name: ModuleName = module_name;

                pub fn getFunction(fn_name: ModuleFunctionName(mod_name)) FunctionID {
                    return .{
                        .module_id = @intFromEnum(mod_name),
                        .fn_id = @intFromEnum(fn_name),
                    };
                }

                pub fn run(
                    m: *const @This(),
                    comptime fn_name: ModuleFunctionName(module_name),
                ) void {
                    const debug_name = @tagName(module_name) ++ "." ++ @tagName(fn_name);
                    const f = @field(module, @tagName(fn_name));
                    const F = @TypeOf(f);

                    if (@typeInfo(F) == .Struct and @typeInfo(F).Struct.is_tuple) {
                        // Run a list of functions instead of a single function
                        // TODO: verify this is a mach.schedule() decl
                        if (module_name != .app) @compileLog(module_name);
                        inline for (f) |schedule_entry| {
                            // TODO: unify with Modules(modules).get(M)
                            const callMod: Module(schedule_entry.@"0") = .{ .mods = m.mods, .modules = m.modules };
                            const callFn = @as(ModuleFunctionName(@TypeOf(callMod).mod_name), schedule_entry.@"1");
                            callMod.run(callFn);
                        }
                        return;
                    }

                    // Inject arguments
                    var args: std.meta.ArgsTuple(F) = undefined;
                    outer: inline for (@typeInfo(std.meta.ArgsTuple(F)).Struct.fields) |arg| {
                        if (@typeInfo(arg.type) == .Pointer and
                            @typeInfo(std.meta.Child(arg.type)) == .Struct and
                            comptime isValid(std.meta.Child(arg.type)))
                        {
                            // *Module argument
                            // TODO: better error if @field(m.mods, ...) fails ("module not registered")
                            @field(args, arg.name) = &@field(m.mods, @tagName(std.meta.Child(arg.type).mach_module));
                            continue :outer;
                        }
                        if (@typeInfo(arg.type) == .Struct and @hasDecl(arg.type, "IsMachMod")) {
                            const M = arg.type.Module;
                            var mv: Mod(M) = .{
                                .id = undefined,
                                ._ctx = m.modules,
                                ._run = (struct {
                                    pub fn run(ctx: *anyopaque, fn_id: FunctionID) void {
                                        const modules2: *Modules(module_lists) = @ptrCast(@alignCast(ctx));
                                        modules2.callDynamic(fn_id);
                                    }
                                }).run,
                            };
                            inline for (M.mach_systems) |m_fn_name| {
                                @field(mv.id, @tagName(m_fn_name)) = Module(M).getFunction(m_fn_name);
                            }
                            @field(args, arg.name) = mv;
                            continue :outer;
                        }
                        @compileError("mach: function " ++ debug_name ++ " has an invalid argument(" ++ arg.name ++ ") type: " ++ @typeName(arg.type));
                    }

                    const Ret = @typeInfo(F).Fn.return_type orelse void;
                    switch (@typeInfo(Ret)) {
                        // TODO: define error handling of runnable functions
                        .ErrorUnion => @call(.auto, f, args) catch |err| std.debug.panic("error: {s}", .{@errorName(err)}),
                        else => @call(.auto, f, args),
                    }
                }
            };
        }

        pub fn get(m: *@This(), module_tag_or_type: anytype) Module(module_tag_or_type) {
            return .{ .mods = &m.mods, .modules = m };
        }

        pub fn callDynamic(m: *@This(), f: FunctionID) void {
            const module_name: ModuleName = @enumFromInt(f.module_id);
            switch (module_name) {
                inline else => |mod_name| {
                    const module_fn_name: ModuleFunctionName(mod_name) = @enumFromInt(f.fn_id);
                    const mod: Module(mod_name) = .{ .mods = &m.mods, .modules = m };
                    const module = @field(ModuleTypesByName(modules){}, @tagName(mod_name));
                    validate(module);

                    switch (module_fn_name) {
                        inline else => |fn_name| mod.run(fn_name),
                    }
                },
            }
        }
    };
}

/// Validates that the given struct is a Mach module.
fn validate(comptime module: anytype) void {
    if (!@hasDecl(module, "mach_module")) @compileError("mach: invalid module, missing `pub const mach_module = .foo_name;` declaration: " ++ @typeName(@TypeOf(module)));
    if (@typeInfo(@TypeOf(module.mach_module)) != .EnumLiteral) @compileError("mach: invalid module, expected `pub const mach_module = .foo_name;` declaration, found: " ++ @typeName(@TypeOf(module.mach_module)));
}

fn isValid(comptime module: anytype) bool {
    if (!@hasDecl(module, "mach_module")) return false;
    if (@typeInfo(@TypeOf(module.mach_module)) != .EnumLiteral) return false;
    return true;
}

/// Given a tuple of Mach module structs, returns an enum which has every possible comptime-known
/// module name.
fn NameEnum(comptime mods: anytype) type {
    var enum_fields: []const std.builtin.Type.EnumField = &[0]std.builtin.Type.EnumField{};
    for (mods, 0..) |module, i| {
        validate(module);
        enum_fields = enum_fields ++ [_]std.builtin.Type.EnumField{.{ .name = @tagName(module.mach_module), .value = i }};
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
/// Returns a flat tuple, deduplicated:
///
/// .{ Baz, Bar, Foo, Fam, Bar, Bam }
///
fn moduleTuple(comptime tuple: anytype) ModuleTuple(tuple) {
    return ModuleTuple(tuple){};
}

/// Type-returning variant of merge()
fn ModuleTuple(comptime tuple: anytype) type {
    if (@typeInfo(@TypeOf(tuple)) != .Struct or !@typeInfo(@TypeOf(tuple)).Struct.is_tuple) {
        @compileError("Expected to find a tuple, found: " ++ @typeName(@TypeOf(tuple)));
    }

    var tuple_fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    loop: inline for (tuple) |elem| {
        if (@typeInfo(@TypeOf(elem)) == .Type and @typeInfo(elem) == .Struct) {
            // Struct type
            validate(elem);
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
            inline for (moduleTuple(elem)) |nested| {
                validate(nested);
                for (tuple_fields) |field| if (@as(*const type, @ptrCast(field.default_value.?)).* == nested)
                    continue :loop;

                var num_buf: [128]u8 = undefined;
                tuple_fields = tuple_fields ++ [_]std.builtin.Type.StructField{.{
                    .name = std.fmt.bufPrintZ(&num_buf, "{d}", .{tuple_fields.len}) catch unreachable,
                    .type = type,
                    .default_value = &nested,
                    .is_comptime = false,
                    .alignment = if (@sizeOf(nested) > 0) @alignOf(nested) else 0,
                }};
            }
        } else {
            @compileError("Expected to find a tuple or struct type, found: " ++ @typeName(@TypeOf(elem)));
        }
    }
    return @Type(.{
        .Struct = .{
            .is_tuple = true,
            .layout = .auto,
            .decls = &.{},
            .fields = tuple_fields,
        },
    });
}

/// Given .{Foo, Bar, Baz} Mach modules, returns .{.foo = Foo, .bar = Bar, .baz = Baz} with field
/// names corresponding to each module's `pub const mach_module = .foo;` name.
fn ModuleTypesByName(comptime modules: anytype) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    for (modules) |M| {
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = @tagName(M.mach_module),
            .type = type,
            .default_value = &M,
            .is_comptime = true,
            .alignment = @alignOf(type),
        }};
    }
    return @Type(.{
        .Struct = .{
            .layout = .auto,
            .is_tuple = false,
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
        },
    });
}

/// Given .{Foo, Bar, Baz} Mach modules, returns .{.foo: Foo = undefined, .bar: Bar = undefined, .baz: Baz = undefined}
/// with field names corresponding to each module's `pub const mach_module = .foo;` name, and each Foo type.
fn ModulesByName(comptime modules: anytype) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    for (modules) |M| {
        fields = fields ++ [_]std.builtin.Type.StructField{.{
            .name = @tagName(M.mach_module),
            .type = M,
            .default_value = &@as(M, undefined),
            .is_comptime = false,
            .alignment = @alignOf(M),
        }};
    }
    return @Type(.{
        .Struct = .{
            .layout = .auto,
            .is_tuple = false,
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
        },
    });
}

// // Returns true if a and b are both functions and are equal
// fn isFnAndEqual(comptime a: anytype, comptime b: anytype) bool {
//     const A = @TypeOf(a);
//     const B = @TypeOf(b);
//     if (@typeInfo(A) != .Fn or @typeInfo(B) != .Fn) return false;
//     const x = @typeInfo(A).Fn;
//     const y = @typeInfo(B).Fn;
//     if (x.calling_convention != y.calling_convention) return false;
//     if (x.is_generic != y.is_generic) return false;
//     if (x.is_var_args != y.is_var_args) return false;
//     if ((x.return_type != null) != (y.return_type != null)) return false;
//     if (x.return_type != null) if (x.return_type.? != y.return_type.?) return false;
//     if (x.params.len != y.params.len) return false;
//     if (x.params.ptr != y.params.ptr) return false;
//     if (A != B) return false;
//     if (a != b) return false;
//     return true;
// }
