const std = @import("std");

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

        pub fn init(allocator: std.mem.Allocator) @This() {
            var m: @This() = .{
                .mods = undefined,
            };
            inline for (@typeInfo(@TypeOf(m.mods)).Struct.fields) |field| {
                // TODO(objects): module-state-init
                var mod: @TypeOf(@field(m.mods, field.name)) = undefined;
                inline for (@typeInfo(@TypeOf(mod)).Struct.fields) |mod_field| {
                    if (@typeInfo(mod_field.type) == .Struct and @hasDecl(mod_field.type, "IsMachObjects")) {
                        @field(mod, mod_field.name).internal = .{
                            .allocator = allocator,
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
