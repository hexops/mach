const std = @import("std");
const AstGen = @import("AstGen.zig");
const Ast = @import("Ast.zig");
const ErrorMsg = @import("main.zig").ErrorMsg;
const IR = @This();

allocator: std.mem.Allocator,
instructions: []const Inst,
refs: []const Ref,
strings: []const u8,

pub fn deinit(self: IR) void {
    self.allocator.free(self.instructions);
    self.allocator.free(self.refs);
    self.allocator.free(self.strings);
}

pub const AstGenResult = union(enum) {
    ir: IR,
    errors: []ErrorMsg,
};

pub fn generate(allocator: std.mem.Allocator, tree: *const Ast) !AstGenResult {
    var astgen = AstGen{
        .allocator = allocator,
        .tree = tree,
        .scope_pool = std.heap.MemoryPool(AstGen.Scope).init(allocator),
    };
    defer astgen.deinit();

    if (!try astgen.translationUnit()) {
        return .{ .errors = try astgen.errors.toOwnedSlice(allocator) };
    }

    return .{ .ir = .{
        .allocator = allocator,
        .instructions = try astgen.instructions.toOwnedSlice(allocator),
        .refs = try astgen.refs.toOwnedSlice(allocator),
        .strings = try astgen.strings.toOwnedSlice(allocator),
    } };
}

pub const Ref = u32;
pub const null_ref: Ref = std.math.maxInt(Ref);

pub const Inst = packed struct {
    tag: Tag,
    data: Data,

    pub const Tag = enum(u6) {
        /// data is global_variable
        global_variable,

        /// data is struct_decl
        struct_decl,
        /// data is struct_member
        struct_member,

        /// data is attr_simple
        attr_simple,
        /// data is attr_expr
        attr_expr,
        /// data is attr_builtin
        attr_builtin,
        /// data is attr_workgroup
        attr_workgroup,
        /// data is attr_interpolate
        attr_interpolate,

        /// data is none
        bool_type,
        /// data is none
        i32_type,
        /// data is none
        u32_type,
        /// data is none
        f32_type,
        /// data is none
        f16_type,
        /// data is vector_type
        vector_type,
        /// data is matrix_type
        matrix_type,
        /// data is atomic_type
        atomic_type,
        /// data is array_type
        array_type,
        /// data is ptr_type
        ptr_type,
        /// data is none
        sampler_type,
        /// data is none
        comparison_sampler_type,
        /// data is sampled_texture_type
        sampled_texture_type,
        /// data is multisampled_texture_type
        multisampled_texture_type,
        /// data is storage_texture_type
        storage_texture_type,
        /// data is depth_texture_type
        depth_texture_type,
        /// data is none
        external_sampled_texture_type,

        /// data is integer_literal
        integer_literal,
        /// data is float_literal
        float_literal,
        /// data is none
        true_literal,
        /// data is none
        false_literal,

        /// data is ref
        not,
        /// data is ref
        negate,
        /// data is ref
        deref,
        /// data is ref
        addr_of,

        /// data is binary
        mul,
        /// data is binary
        div,
        /// data is binary
        mod,
        /// data is binary
        add,
        /// data is binary
        sub,
        /// data is binary
        shift_left,
        /// data is binary
        shift_right,
        /// data is binary
        binary_and,
        /// data is binary
        binary_or,
        /// data is binary
        binary_xor,
        /// data is binary
        circuit_and,
        /// data is binary
        circuit_or,
        /// data is binary
        equal,
        /// data is binary
        not_equal,
        /// data is binary
        less,
        /// data is binary
        less_equal,
        /// data is binary
        greater,
        /// data is binary
        greater_equal,

        /// data is binary
        index,
        /// data is member_access
        member_access,
        /// data is binary (lhs is expr, rhs is type)
        bitcast,
    };

    pub const Data = packed union {
        /// TODO: https://github.com/ziglang/zig/issues/14980
        none: u1,
        ref: Ref,
        global_variable: packed struct {
            /// index to null-terminated string in `strings`
            name: u32,
            type: Ref,
            addr_space: Ast.AddressSpace = .none,
            access_mode: Ast.AccessMode = .none,
            /// length of attributes
            attrs: u4 = 0,
        },
        struct_decl: packed struct {
            /// index to null-terminated string in `strings`
            name: u32,
            /// length of the member Ref's which comes after this
            members: u32,
        },
        struct_member: packed struct {
            /// index to null-terminated string in `strings`
            name: u32,
            type: Ref,
            @"align": u29, // 0 means null
        },
        /// attributes with no argument.
        attr_simple: enum {
            invariant,
            @"const",
            vertex,
            fragment,
            compute,
        },
        /// attributes with an expression argument.
        attr_expr: packed struct {
            kind: enum {
                @"align",
                binding,
                group,
                id,
                location,
                size,
            },
            expr: Ref,
        },
        /// @builtin attribute which accepts a BuiltinValue argument.
        attr_builtin: Ast.BuiltinValue,
        /// @workgroup attribute. accepts at laest 1 argument.
        attr_workgroup: packed struct {
            expr0: Ref,
            expr1: Ref = null_ref,
            expr2: Ref = null_ref,
        },
        /// @interpolate attribute. accepts 2 arguments.
        attr_interpolate: packed struct {
            type: Ast.InterpolationType,
            sample: Ast.InterpolationSample,
        },
        vector_type: packed struct {
            component_type: Ref,
            size: enum { two, three, four },
        },
        matrix_type: packed struct {
            component_type: Ref,
            cols: enum { two, three, four },
            rows: enum { two, three, four },
        },
        atomic_type: packed struct { component_type: Ref },
        array_type: packed struct {
            component_type: Ref,
            size: Ref = null_ref,
        },
        ptr_type: packed struct {
            component_type: Ref,
            addr_space: Ast.AddressSpace,
            access_mode: Ast.AccessMode,
        },
        sampled_texture_type: packed struct {
            kind: enum {
                @"1d",
                @"2d",
                @"2d_array",
                @"3d",
                cube,
                cube_array,
            },
            component_type: Ref,
        },
        multisampled_texture_type: packed struct {
            kind: enum { @"2d" },
            component_type: Ref,
        },
        storage_texture_type: packed struct {
            kind: enum {
                @"1d",
                @"2d",
                @"2d_array",
                @"3d",
            },
            texel_format: Ast.TexelFormat,
            access_mode: MultisampledTextureTypeKind,
        },
        depth_texture_type: enum {
            @"2d",
            @"2d_array",
            cube,
            cube_array,
            multisampled_2d,
        },
        integer_literal: i64,
        float_literal: f64,
        /// meaning of LHS and RHS depends on the corresponding Tag.
        binary: packed struct {
            lhs: Ref,
            rhs: Ref,
        },
        member_access: packed struct {
            base: Ref,
            /// index to null-terminated string in `strings`
            name: u32,
        },

        pub const MultisampledTextureTypeKind = enum { write };
    };

    comptime {
        std.debug.assert(@bitSizeOf(Inst) <= 104); // 13B
    }
};
