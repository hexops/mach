//! Analyzed Intermediate Representation.
//! This data is produced by AstGen and consumed by CodeGen.

const std = @import("std");
const AstGen = @import("AstGen.zig");
const Ast = @import("Ast.zig");
const ErrorList = @import("ErrorList.zig");
const Extensions = @import("wgsl.zig").Extensions;
const Air = @This();

tree: *const Ast,
globals_index: RefIndex,
compute_stage: InstIndex,
vertex_stage: InstIndex,
fragment_stage: InstIndex,
instructions: []const Inst,
refs: []const InstIndex,
strings: []const u8,
values: []const u8,
extensions: Extensions,

pub fn deinit(air: *Air, allocator: std.mem.Allocator) void {
    allocator.free(air.instructions);
    allocator.free(air.refs);
    allocator.free(air.strings);
    allocator.free(air.values);
    air.* = undefined;
}

pub fn generate(
    allocator: std.mem.Allocator,
    tree: *const Ast,
    errors: *ErrorList,
    entry_point: ?[]const u8,
) error{ OutOfMemory, AnalysisFail }!Air {
    var astgen = AstGen{
        .allocator = allocator,
        .tree = tree,
        .scope_pool = std.heap.MemoryPool(AstGen.Scope).init(allocator),
        .inst_arena = std.heap.ArenaAllocator.init(allocator),
        .entry_point_name = entry_point,
        .errors = errors,
    };
    defer {
        astgen.instructions.deinit(allocator);
        astgen.scratch.deinit(allocator);
        astgen.globals.deinit(allocator);
        astgen.global_var_refs.deinit(allocator);
        astgen.scope_pool.deinit();
        astgen.inst_arena.deinit();
    }
    errdefer {
        astgen.refs.deinit(allocator);
        astgen.strings.deinit(allocator);
        astgen.values.deinit(allocator);
    }

    const globals_index = try astgen.genTranslationUnit();

    return .{
        .tree = tree,
        .globals_index = globals_index,
        .compute_stage = astgen.compute_stage,
        .vertex_stage = astgen.vertex_stage,
        .fragment_stage = astgen.fragment_stage,
        .instructions = try allocator.dupe(Inst, astgen.instructions.keys()),
        .refs = try astgen.refs.toOwnedSlice(allocator),
        .strings = try astgen.strings.toOwnedSlice(allocator),
        .values = try astgen.values.toOwnedSlice(allocator),
        .extensions = tree.extensions,
    };
}

pub fn refToList(air: Air, ref: RefIndex) []const InstIndex {
    return std.mem.sliceTo(air.refs[@intFromEnum(ref)..], .none);
}

pub fn getInst(air: Air, index: InstIndex) Inst {
    return air.instructions[@intFromEnum(index)];
}

pub fn getStr(air: Air, index: StringIndex) []const u8 {
    return std.mem.sliceTo(air.strings[@intFromEnum(index)..], 0);
}

pub fn getValue(air: Air, comptime T: type, value: ValueIndex) T {
    return std.mem.bytesAsValue(T, air.values[@intFromEnum(value)..][0..@sizeOf(T)]).*;
}

pub fn typeSize(air: Air, index: InstIndex) ?u32 {
    return switch (air.getInst(index)) {
        inline .int, .float => |num| num.type.size(),
        .vector => |vec| @as(u32, @intFromEnum(vec.size)),
        .matrix => |mat| @as(u32, @intFromEnum(mat.cols)) * @as(u32, @intFromEnum(mat.rows)),
        .array => |arr| {
            if (arr.len == .none) return null;
            return @intCast(air.resolveInt(arr.len) orelse return null);
        },
        else => unreachable,
    };
}

pub const ConstExpr = union(enum) {
    guaranteed,
    bool: bool,
    int: i64,
    float: f32,

    fn negate(unary: *ConstExpr) void {
        switch (unary.*) {
            .int => unary.int = -unary.int,
            .float => unary.float = -unary.float,
            else => unreachable,
        }
    }

    fn not(unary: *ConstExpr) void {
        switch (unary.*) {
            .bool => unary.bool = !unary.bool,
            else => unreachable,
        }
    }

    fn mul(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int *= rhs.int,
            .float => lhs.float *= rhs.float,
            else => unreachable,
        }
    }

    fn div(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int = @divExact(lhs.int, rhs.int),
            .float => lhs.float /= rhs.float,
            else => unreachable,
        }
    }

    fn mod(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int = @mod(lhs.int, rhs.int),
            .float => lhs.float = @mod(lhs.float, rhs.float),
            else => unreachable,
        }
    }

    fn add(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int += rhs.int,
            .float => lhs.float += rhs.float,
            else => unreachable,
        }
    }

    fn sub(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int -= rhs.int,
            .float => lhs.float -= rhs.float,
            else => unreachable,
        }
    }

    fn shiftLeft(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int <<= @intCast(rhs.int),
            else => unreachable,
        }
    }

    fn shiftRight(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int >>= @intCast(rhs.int),
            else => unreachable,
        }
    }

    fn bitwiseAnd(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int &= rhs.int,
            else => unreachable,
        }
    }

    fn bitwiseOr(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int |= rhs.int,
            else => unreachable,
        }
    }

    fn bitwiseXor(lhs: *ConstExpr, rhs: ConstExpr) void {
        switch (lhs.*) {
            .int => lhs.int ^= rhs.int,
            else => unreachable,
        }
    }

    fn equal(lhs: ConstExpr, rhs: ConstExpr) ConstExpr {
        return switch (lhs) {
            .bool => .{ .bool = lhs.bool == rhs.bool },
            .int => .{ .bool = lhs.int == rhs.int },
            .float => .{ .bool = lhs.float == rhs.float },
            .guaranteed => unreachable,
        };
    }

    fn notEqual(lhs: ConstExpr, rhs: ConstExpr) ConstExpr {
        return switch (lhs) {
            .int => .{ .bool = lhs.int != rhs.int },
            .float => .{ .bool = lhs.float != rhs.float },
            else => unreachable,
        };
    }

    fn lessThan(lhs: ConstExpr, rhs: ConstExpr) ConstExpr {
        return switch (lhs) {
            .int => .{ .bool = lhs.int < rhs.int },
            .float => .{ .bool = lhs.float < rhs.float },
            else => unreachable,
        };
    }

    fn greaterThan(lhs: ConstExpr, rhs: ConstExpr) ConstExpr {
        return switch (lhs) {
            .int => .{ .bool = lhs.int > rhs.int },
            .float => .{ .bool = lhs.float > rhs.float },
            else => unreachable,
        };
    }

    fn lessThanEqual(lhs: ConstExpr, rhs: ConstExpr) ConstExpr {
        return switch (lhs) {
            .int => .{ .bool = lhs.int <= rhs.int },
            .float => .{ .bool = lhs.float <= rhs.float },
            else => unreachable,
        };
    }

    fn greaterThanEqual(lhs: ConstExpr, rhs: ConstExpr) ConstExpr {
        return switch (lhs) {
            .int => .{ .bool = lhs.int >= rhs.int },
            .float => .{ .bool = lhs.float >= rhs.float },
            else => unreachable,
        };
    }

    fn logicalAnd(lhs: ConstExpr, rhs: ConstExpr) ConstExpr {
        return .{ .bool = lhs.bool and rhs.bool };
    }

    fn logicalOr(lhs: ConstExpr, rhs: ConstExpr) ConstExpr {
        return .{ .bool = lhs.bool or rhs.bool };
    }
};

pub fn resolveConstExpr(air: Air, inst_idx: InstIndex) ?ConstExpr {
    const inst = air.getInst(inst_idx);
    switch (inst) {
        .bool => |data| {
            if (data.value) |value| {
                switch (value) {
                    .literal => |literal| return .{ .bool = literal },
                    .cast => return null,
                }
            } else {
                return null;
            }
        },
        .int => |data| {
            if (data.value) |value| {
                switch (air.getValue(Inst.Int.Value, value)) {
                    .literal => |literal| return .{ .int = literal },
                    .cast => return null,
                }
            } else {
                return null;
            }
        },
        .float => |data| {
            if (data.value) |value| {
                switch (air.getValue(Inst.Float.Value, value)) {
                    .literal => |literal| return .{ .float = literal },
                    .cast => return null,
                }
            } else {
                return null;
            }
        },
        .vector => |vec| {
            if (vec.value.? == .none) return .guaranteed;
            switch (air.getValue(Inst.Vector.Value, vec.value.?)) {
                .literal => |literal| for (literal[0..@intFromEnum(vec.size)]) |elem_val| {
                    if (air.resolveConstExpr(elem_val) == null) {
                        return null;
                    }
                },
                .cast => return null,
            }

            return .guaranteed;
        },
        .matrix => |mat| {
            if (mat.value.? == .none) return .guaranteed;
            for (air.getValue(Inst.Matrix.Value, mat.value.?)[0..@intFromEnum(mat.cols)]) |elem_val| {
                if (air.resolveConstExpr(elem_val) == null) {
                    return null;
                }
            }
            return .guaranteed;
        },
        .array => |arr| {
            for (air.refToList(arr.value.?)) |elem_val| {
                if (air.resolveConstExpr(elem_val) == null) {
                    return null;
                }
            }
            return .guaranteed;
        },
        .struct_construct => |sc| {
            for (air.refToList(sc.members)) |elem_val| {
                if (air.resolveConstExpr(elem_val) == null) {
                    return null;
                }
            }
            return .guaranteed;
        },
        .unary => |un| {
            var value = air.resolveConstExpr(un.expr) orelse return null;
            switch (un.op) {
                .negate => value.negate(),
                .not => value.not(),
                else => unreachable,
            }
            return value;
        },
        .binary => |bin| {
            var lhs = air.resolveConstExpr(bin.lhs) orelse return null;
            const rhs = air.resolveConstExpr(bin.rhs) orelse return null;
            switch (bin.op) {
                .mul => lhs.mul(rhs),
                .div => lhs.div(rhs),
                .mod => lhs.mod(rhs),
                .add => lhs.add(rhs),
                .sub => lhs.sub(rhs),
                .shl => lhs.shiftLeft(rhs),
                .shr => lhs.shiftRight(rhs),
                .@"and" => lhs.bitwiseAnd(rhs),
                .@"or" => lhs.bitwiseOr(rhs),
                .xor => lhs.bitwiseXor(rhs),
                .equal => return lhs.equal(rhs),
                .not_equal => return lhs.notEqual(rhs),
                .less_than => return lhs.lessThan(rhs),
                .greater_than => return lhs.greaterThan(rhs),
                .less_than_equal => return lhs.lessThanEqual(rhs),
                .greater_than_equal => return lhs.greaterThanEqual(rhs),
                .logical_and => return lhs.logicalAnd(rhs),
                .logical_or => return lhs.logicalOr(rhs),
            }
            return lhs;
        },
        .var_ref => |var_ref| return air.resolveConstExpr(var_ref),
        .@"const" => |@"const"| return air.resolveConstExpr(@"const".init).?,
        inline .index_access, .field_access, .swizzle_access => |access| return air.resolveConstExpr(access.base),
        else => return null,
    }
}

pub fn resolveInt(air: Air, inst_idx: InstIndex) ?i64 {
    if (inst_idx != .none) {
        if (air.resolveConstExpr(inst_idx)) |const_expr| {
            switch (const_expr) {
                .int => |x| return x,
                else => {},
            }
        }
    }

    return null;
}

pub fn findFunction(air: Air, name: []const u8) ?Inst.Fn {
    for (air.refToList(air.globals_index)) |global_inst_idx| {
        switch (air.getInst(global_inst_idx)) {
            .@"fn" => |inst| {
                if (std.mem.eql(u8, air.getStr(inst.name), name)) {
                    return inst;
                }
            },
            else => {},
        }
    }

    return null;
}

pub const InstIndex = enum(u32) { none = std.math.maxInt(u32), _ };
pub const RefIndex = enum(u32) { none = std.math.maxInt(u32), _ };
pub const ValueIndex = enum(u32) { none = std.math.maxInt(u32), _ };
pub const StringIndex = enum(u32) { _ };

pub const Inst = union(enum) {
    @"var": Var,
    @"const": Const,
    var_ref: InstIndex,

    @"fn": Fn,
    fn_param: FnParam,

    @"struct": Struct,
    struct_member: StructMember,

    bool: Bool,
    int: Int,
    float: Float,
    vector: Vector,
    matrix: Matrix,
    array: Array,
    atomic_type: AtomicType,
    ptr_type: PointerType,
    texture_type: TextureType,
    sampler_type,
    comparison_sampler_type,
    external_texture_type,

    nil_intrinsic: NilIntrinsic,
    unary: Unary,
    unary_intrinsic: UnaryIntrinsic,
    binary: Binary,
    binary_intrinsic: BinaryIntrinsic,
    triple_intrinsic: TripleIntrinsic,

    block: RefIndex,
    loop: InstIndex,
    continuing: InstIndex,
    @"return": InstIndex,
    break_if: InstIndex,
    @"if": If,
    @"while": While,
    @"for": For,
    @"switch": Switch,
    switch_case: SwitchCase,
    assign: Assign,
    discard,
    @"break",
    @"continue",

    field_access: FieldAccess,
    swizzle_access: SwizzleAccess,
    index_access: IndexAccess,
    call: FnCall,
    struct_construct: StructConstruct,
    bitcast: Bitcast,
    select: BuiltinSelect,
    texture_sample: TextureSample,
    texture_dimension: TextureDimension,
    texture_load: TextureLoad,
    texture_store: TextureStore,

    pub const Var = struct {
        name: StringIndex,
        type: InstIndex,
        init: InstIndex,
        addr_space: PointerType.AddressSpace,
        access_mode: PointerType.AccessMode,
        binding: InstIndex = .none,
        group: InstIndex = .none,
        id: InstIndex = .none,
    };

    pub const Const = struct {
        name: StringIndex,
        type: InstIndex,
        init: InstIndex,
    };

    pub const Fn = struct {
        name: StringIndex,
        stage: Stage,
        is_const: bool,
        params: RefIndex,
        return_type: InstIndex,
        return_attrs: ReturnAttrs,
        block: InstIndex,
        global_var_refs: RefIndex,
        has_array_length: bool,

        pub const Stage = union(enum) {
            none,
            vertex,
            fragment,
            compute: WorkgroupSize,

            pub const WorkgroupSize = struct {
                x: InstIndex,
                y: InstIndex,
                z: InstIndex,
            };
        };

        pub const ReturnAttrs = struct {
            builtin: ?Builtin,
            location: ?u16,
            interpolate: ?Interpolate,
            invariant: bool,
        };
    };

    pub const FnParam = struct {
        name: StringIndex,
        type: InstIndex,
        builtin: ?Builtin,
        location: ?u16,
        interpolate: ?Interpolate,
        invariant: bool,
    };

    pub const Builtin = Ast.Builtin;

    pub const Interpolate = struct {
        type: Type,
        sample: Sample,

        pub const Type = enum {
            perspective,
            linear,
            flat,
        };

        pub const Sample = enum {
            none,
            center,
            centroid,
            sample,
        };
    };

    pub const Struct = struct {
        name: StringIndex,
        members: RefIndex,
    };

    pub const StructMember = struct {
        name: StringIndex,
        index: u32,
        type: InstIndex,
        @"align": ?u29,
        size: ?u32,
        location: ?u16,
        builtin: ?Builtin,
        interpolate: ?Interpolate,
    };

    pub const Bool = struct {
        value: ?Value,

        pub const Value = union(enum) {
            literal: bool,
            cast: ScalarCast,
        };
    };

    pub const Int = struct {
        type: Type,
        value: ?ValueIndex,

        pub const Type = enum {
            u32,
            i32,

            pub fn size(int: Type) u8 {
                _ = int;
                return 4;
            }

            pub fn sizeBits(int: Type) u8 {
                _ = int;
                return 32;
            }

            pub fn signedness(int: Type) bool {
                return switch (int) {
                    .u32 => false,
                    .i32 => true,
                };
            }
        };

        pub const Value = union(enum) {
            literal: i33,
            cast: ScalarCast,
        };
    };

    pub const Float = struct {
        type: Type,
        value: ?ValueIndex,

        pub const Type = enum {
            f32,
            f16,

            pub fn size(float: Type) u8 {
                return switch (float) {
                    .f32 => 4,
                    .f16 => 2,
                };
            }

            pub fn sizeBits(float: Type) u8 {
                return switch (float) {
                    .f32 => 32,
                    .f16 => 16,
                };
            }
        };

        pub const Value = union(enum) {
            literal: f32,
            cast: ScalarCast,
        };
    };

    pub const ScalarCast = struct {
        type: InstIndex,
        value: InstIndex,
    };

    pub const Vector = struct {
        elem_type: InstIndex,
        size: Size,
        value: ?ValueIndex,

        pub const Size = enum(u3) { two = 2, three = 3, four = 4 };

        pub const Value = union(enum) {
            literal: [4]InstIndex,
            cast: Cast,
        };

        pub const Cast = struct {
            type: InstIndex,
            value: [4]InstIndex,
        };
    };

    pub const Matrix = struct {
        elem_type: InstIndex,
        cols: Vector.Size,
        rows: Vector.Size,
        value: ?ValueIndex,

        pub const Value = [4]InstIndex;
    };

    pub const Array = struct {
        elem_type: InstIndex,
        len: InstIndex,
        value: ?RefIndex,
    };

    pub const AtomicType = struct { elem_type: InstIndex };

    pub const PointerType = struct {
        elem_type: InstIndex,
        addr_space: AddressSpace,
        access_mode: AccessMode,

        pub const AddressSpace = enum {
            uniform_constant,
            function,
            private,
            workgroup,
            uniform,
            storage,
        };

        pub const AccessMode = enum {
            read,
            write,
            read_write,
        };
    };

    pub const TextureType = struct {
        kind: Kind,
        elem_type: InstIndex = .none,
        texel_format: TexelFormat = .none,
        access_mode: AccessMode = .write,

        pub const Kind = enum {
            sampled_1d,
            sampled_2d,
            sampled_2d_array,
            sampled_3d,
            sampled_cube,
            sampled_cube_array,
            multisampled_2d,
            multisampled_depth_2d,
            storage_1d,
            storage_2d,
            storage_2d_array,
            storage_3d,
            depth_2d,
            depth_2d_array,
            depth_cube,
            depth_cube_array,

            pub const Dimension = enum {
                @"1d",
                @"2d",
                @"3d",
                cube,
            };

            pub fn dimension(k: Kind) Dimension {
                return switch (k) {
                    .sampled_1d, .storage_1d => .@"1d",
                    .sampled_2d,
                    .sampled_2d_array,
                    .multisampled_2d,
                    .multisampled_depth_2d,
                    .storage_2d,
                    .storage_2d_array,
                    .depth_2d,
                    .depth_2d_array,
                    => .@"2d",
                    .sampled_3d, .storage_3d => .@"3d",
                    .sampled_cube, .sampled_cube_array, .depth_cube, .depth_cube_array => .cube,
                };
            }
        };

        pub const TexelFormat = enum {
            none,
            rgba8unorm,
            rgba8snorm,
            rgba8uint,
            rgba8sint,
            rgba16uint,
            rgba16sint,
            rgba16float,
            r32uint,
            r32sint,
            r32float,
            rg32uint,
            rg32sint,
            rg32float,
            rgba32uint,
            rgba32sint,
            rgba32float,
            bgra8unorm,
        };

        pub const AccessMode = enum { write };
    };

    pub const Unary = struct {
        result_type: InstIndex,
        expr: InstIndex,
        op: Op,

        pub const Op = enum {
            not,
            negate,
            deref,
            addr_of,
        };
    };

    pub const NilIntrinsic = enum {
        storage_barrier,
        workgroup_barrier,
    };

    pub const UnaryIntrinsic = struct {
        result_type: InstIndex,
        expr: InstIndex,
        op: Op,

        pub const Op = enum {
            all,
            any,
            abs,
            acos,
            acosh,
            asin,
            asinh,
            atan,
            atanh,
            ceil,
            cos,
            cosh,
            count_leading_zeros,
            count_one_bits,
            count_trailing_zeros,
            degrees,
            exp,
            exp2,
            first_leading_bit,
            first_trailing_bit,
            floor,
            fract,
            inverse_sqrt,
            length,
            log,
            log2,
            quantize_to_F16,
            radians,
            reverseBits,
            round,
            saturate,
            sign,
            sin,
            sinh,
            sqrt,
            tan,
            tanh,
            trunc,
            dpdx,
            dpdx_coarse,
            dpdx_fine,
            dpdy,
            dpdy_coarse,
            dpdy_fine,
            fwidth,
            fwidth_coarse,
            fwidth_fine,
            array_length,
            normalize,
        };
    };

    pub const Binary = struct {
        op: Op,
        result_type: InstIndex,
        lhs_type: InstIndex,
        rhs_type: InstIndex,
        lhs: InstIndex,
        rhs: InstIndex,

        pub const Op = enum {
            mul,
            div,
            mod,
            add,
            sub,
            shl,
            shr,
            @"and",
            @"or",
            xor,
            logical_and,
            logical_or,
            equal,
            not_equal,
            less_than,
            less_than_equal,
            greater_than,
            greater_than_equal,
        };
    };

    pub const BinaryIntrinsic = struct {
        op: Op,
        result_type: InstIndex,
        lhs_type: InstIndex,
        rhs_type: InstIndex,
        lhs: InstIndex,
        rhs: InstIndex,

        pub const Op = enum {
            min,
            max,
            atan2,
            distance,
            dot,
            pow,
            step,
        };
    };

    pub const TripleIntrinsic = struct {
        op: Op,
        result_type: InstIndex,
        a1_type: InstIndex,
        a2_type: InstIndex,
        a3_type: InstIndex,
        a1: InstIndex,
        a2: InstIndex,
        a3: InstIndex,

        pub const Op = enum {
            smoothstep,
            clamp,
            mix,
        };
    };

    pub const Assign = struct {
        mod: Modifier,
        type: InstIndex,
        lhs: InstIndex,
        rhs: InstIndex,

        pub const Modifier = enum {
            none,
            add,
            sub,
            mul,
            div,
            mod,
            @"and",
            @"or",
            xor,
            shl,
            shr,
        };
    };

    pub const FieldAccess = struct {
        base: InstIndex,
        field: InstIndex,
        name: StringIndex,
    };

    pub const SwizzleAccess = struct {
        base: InstIndex,
        type: InstIndex,
        size: Size,
        pattern: [4]Component,

        pub const Size = enum(u3) {
            one = 1,
            two = 2,
            three = 3,
            four = 4,
        };
        pub const Component = enum(u3) { x, y, z, w };
    };

    pub const IndexAccess = struct {
        base: InstIndex,
        type: InstIndex,
        index: InstIndex,
    };

    pub const FnCall = struct {
        @"fn": InstIndex,
        args: RefIndex,
    };

    pub const StructConstruct = struct {
        @"struct": InstIndex,
        members: RefIndex,
    };

    pub const Bitcast = struct {
        type: InstIndex,
        expr: InstIndex,
        result_type: InstIndex,
    };

    pub const BuiltinSelect = struct {
        type: InstIndex,
        true: InstIndex,
        false: InstIndex,
        cond: InstIndex,
    };

    pub const TextureSample = struct {
        kind: TextureType.Kind,
        texture_type: InstIndex,
        texture: InstIndex,
        sampler: InstIndex,
        coords: InstIndex,
        result_type: InstIndex,
        offset: InstIndex = .none,
        array_index: InstIndex = .none,
        operands: Operands = .none,

        pub const Operands = union(enum) {
            none,
            level: InstIndex,
            grad: struct { dpdx: InstIndex, dpdy: InstIndex },
        };
    };

    pub const TextureDimension = struct {
        kind: TextureType.Kind,
        texture: InstIndex,
        level: InstIndex,
        result_type: InstIndex,
    };

    pub const TextureLoad = struct {
        kind: TextureType.Kind,
        texture: InstIndex,
        coords: InstIndex,
        level: InstIndex,
        result_type: InstIndex,
    };

    pub const TextureStore = struct {
        kind: TextureType.Kind,
        texture: InstIndex,
        coords: InstIndex,
        value: InstIndex,
    };

    pub const If = struct {
        cond: InstIndex,
        body: InstIndex,
        /// `if` or `block`
        @"else": InstIndex,
    };

    pub const Switch = struct {
        switch_on: InstIndex,
        cases_list: RefIndex,
    };

    pub const SwitchCase = struct {
        cases: RefIndex,
        body: InstIndex,
        default: bool,
    };

    pub const While = struct {
        cond: InstIndex,
        body: InstIndex,
    };

    pub const For = struct {
        init: InstIndex,
        cond: InstIndex,
        update: InstIndex,
        body: InstIndex,
    };

    comptime {
        std.debug.assert(@sizeOf(Inst) <= 64);
    }
};
