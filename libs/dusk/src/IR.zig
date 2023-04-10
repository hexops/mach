const std = @import("std");
const AstGen = @import("AstGen.zig");
const Ast = @import("Ast.zig");
const ErrorList = @import("ErrorList.zig");
const IR = @This();

allocator: std.mem.Allocator,
globals_index: u32,
instructions: []const Inst,
refs: []const Inst.Ref,
strings: []const u8,
errors: ErrorList,

pub fn deinit(self: *IR) void {
    self.allocator.free(self.instructions);
    self.allocator.free(self.refs);
    self.allocator.free(self.strings);
    self.errors.deinit();
    self.* = undefined;
}

pub fn generate(allocator: std.mem.Allocator, tree: *const Ast) error{OutOfMemory}!IR {
    var astgen = AstGen{
        .allocator = allocator,
        .tree = tree,
        .errors = try ErrorList.init(allocator),
        .scope_pool = std.heap.MemoryPool(AstGen.Scope).init(allocator),
    };
    defer {
        astgen.scope_pool.deinit();
        astgen.scratch.deinit(allocator);
    }
    errdefer {
        astgen.instructions.deinit(allocator);
        astgen.refs.deinit(allocator);
        astgen.strings.deinit(allocator);
    }

    const globals_index = try astgen.genTranslationUnit();

    return .{
        .allocator = allocator,
        .globals_index = globals_index,
        .instructions = try astgen.instructions.toOwnedSlice(allocator),
        .refs = try astgen.refs.toOwnedSlice(allocator),
        .strings = try astgen.strings.toOwnedSlice(allocator),
        .errors = astgen.errors,
    };
}

pub fn getStr(self: IR, index: u32) []const u8 {
    return std.mem.sliceTo(self.strings[index..], 0);
}

pub const Inst = struct {
    tag: Tag,
    data: Data,

    pub const List = std.ArrayListUnmanaged(Inst);
    pub const Index = u32;

    const ref_start_index = @typeInfo(Ref).Enum.fields.len;
    pub fn toRef(index: Inst.Index) Ref {
        return @intToEnum(Ref, ref_start_index + index);
    }

    pub const Ref = enum(u32) {
        none,

        bool_type,
        i32_type,
        u32_type,
        f32_type,
        f16_type,
        sampler_type,
        comparison_sampler_type,
        external_sampled_texture_type,

        true_literal,
        false_literal,

        _,

        pub fn toIndex(inst: Ref) ?Inst.Index {
            const ref_int = @enumToInt(inst);
            if (ref_int >= ref_start_index) {
                return @intCast(Inst.Index, ref_int - ref_start_index);
            } else {
                return null;
            }
        }

        pub fn is(self: Ref, list: List, comptime expected: []const Inst.Tag) bool {
            inline for (expected) |e| {
                if (list.items[self.toIndex().?].tag == e) return true;
            }
            return false;
        }

        pub fn isType(self: Ref, list: List) bool {
            return switch (self) {
                .none,
                .true_literal,
                .false_literal,
                => false,
                .bool_type,
                .i32_type,
                .u32_type,
                .f32_type,
                .f16_type,
                .sampler_type,
                .comparison_sampler_type,
                .external_sampled_texture_type,
                => true,
                _ => switch (list.items[self.toIndex().?].tag) {
                    .struct_decl,
                    .vector_type,
                    .matrix_type,
                    .atomic_type,
                    .array_type,
                    .ptr_type,
                    .sampled_texture_type,
                    .multisampled_texture_type,
                    .storage_texture_type,
                    .depth_texture_type,
                    => true,
                    else => false,
                },
            };
        }

        pub fn isNumberType(self: Ref) bool {
            return switch (self) {
                .i32_type,
                .u32_type,
                .f32_type,
                .f16_type,
                => true,
                else => false,
            };
        }

        pub fn isLiteral(self: Ref, list: List) bool {
            return switch (self) {
                .true_literal,
                .false_literal,
                => true,
                .none,
                .bool_type,
                .i32_type,
                .u32_type,
                .f32_type,
                .f16_type,
                .sampler_type,
                .comparison_sampler_type,
                .external_sampled_texture_type,
                => false,
                _ => switch (list.items[self.toIndex().?].tag) {
                    .integer_literal,
                    .float_literal,
                    => true,
                    else => false,
                },
            };
        }

        pub fn isBoolLiteral(self: Ref) bool {
            return switch (self) {
                .true_literal,
                .false_literal,
                => true,
                else => false,
            };
        }

        pub fn isNumberLiteral(self: Ref, list: List) bool {
            const i = self.toIndex() orelse return false;
            return switch (list.items[i].tag) {
                .integer_literal,
                .float_literal,
                => true,
                else => false,
            };
        }

        pub fn isExpr(self: Ref, list: List) bool {
            const i = self.toIndex() orelse return false;
            return switch (list.items[i].tag) {
                .index,
                .member_access,
                .bitcast,
                .ident,
                => true,
                else => self.isBinaryExpr() or self.isUnaryExpr(),
            };
        }

        pub fn isBinaryExpr(self: Ref, list: List) bool {
            const i = self.toIndex() orelse return false;
            return switch (list.items[i].tag) {
                .mul,
                .div,
                .mod,
                .add,
                .sub,
                .shift_left,
                .shift_right,
                .binary_and,
                .binary_or,
                .binary_xor,
                .circuit_and,
                .circuit_or,
                .equal,
                .not_equal,
                .less,
                .less_equal,
                .greater,
                .greater_equal,
                => true,
                else => false,
            };
        }

        pub fn isUnaryExpr(self: Ref, list: List) bool {
            const i = self.toIndex() orelse return false;
            return switch (list.items[i].tag) {
                .not,
                .negate,
                .deref,
                .addr_of,
                => true,
                else => false,
            };
        }
    };

    pub const Tag = enum(u6) {
        /// data is global_variable_decl
        global_variable_decl,

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
        /// data is sampled_texture_type
        sampled_texture_type,
        /// data is multisampled_texture_type
        multisampled_texture_type,
        /// data is storage_texture_type
        storage_texture_type,
        /// data is depth_texture_type
        depth_texture_type,

        /// data is integer_literal
        integer_literal,
        /// data is float_literal
        float_literal,

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

        /// data is var_ref
        var_ref,

        pub fn isDecl(self: Tag) bool {
            return switch (self) {
                .global_variable_decl, .struct_decl => true,
                else => false,
            };
        }
    };

    pub const Data = union {
        ref: Ref,
        var_ref: VarRef,
        global_variable_decl: GlobalVariableDecl,
        struct_decl: StructDecl,
        struct_member: StructMember,
        /// attributes with no argument.
        attr_simple: AttrSimple,
        /// attributes with an expression argument.
        attr_expr: AttrExpr,
        /// @builtin attribute which accepts a BuiltinValue argument.
        attr_builtin: BuiltinValue,
        /// @workgroup attribute. accepts at laest 1 argument.
        attr_workgroup: AttrWorkgroup,
        /// @interpolate attribute. accepts 2 arguments.
        attr_interpolate: AttrInterpolate,
        vector_type: VectorType,
        matrix_type: MatrixType,
        atomic_type: AtomicType,
        array_type: ArrayType,
        ptr_type: PointerType,
        sampled_texture_type: SampledTextureType,
        multisampled_texture_type: MultisampledTextureType,
        storage_texture_type: StorageTextureType,
        depth_texture_type: DepthTextureType,
        integer_literal: i64,
        float_literal: f64,
        /// meaning of LHS and RHS depends on the corresponding Tag.
        binary: BinaryExpr,
        member_access: MemberAccess,
    };

    pub const VarRef = struct {
        /// index to null-terminated string in `strings`
        name: u32,
        variable: Ref,
    };

    pub const GlobalVariableDecl = struct {
        /// index to null-terminated string in `strings`
        name: u32,
        type: Ref = .none,
        addr_space: AddressSpace,
        access_mode: AccessMode,
        /// length of attributes
        attrs: u4 = 0,
        expr: Ref = .none,

        pub const AddressSpace = enum {
            none,
            function,
            private,
            workgroup,
            uniform,
            storage,
        };

        pub const AccessMode = enum {
            none,
            read,
            write,
            read_write,
        };
    };

    pub const StructDecl = struct {
        /// index to null-terminated string in `strings`
        name: u32,
        /// length of the member Ref's which comes after this
        members: u32,
    };

    pub const StructMember = struct {
        /// index to null-terminated string in `strings`
        name: u32,
        type: Ref,
        @"align": u29, // 0 means null
    };

    pub const BuiltinValue = enum {
        vertex_index,
        instance_index,
        position,
        front_facing,
        frag_depth,
        local_invocation_id,
        local_invocation_index,
        global_invocation_id,
        workgroup_id,
        num_workgroups,
        sample_index,
        sample_mask,
    };

    pub const AttrSimple = enum {
        invariant,
        @"const",
        vertex,
        fragment,
        compute,
    };

    pub const AttrExpr = struct {
        kind: Kind,
        expr: Ref,

        pub const Kind = enum {
            @"align",
            binding,
            group,
            id,
            location,
            size,
        };
    };

    pub const AttrWorkgroup = struct {
        expr0: Ref,
        expr1: Ref = .none,
        expr2: Ref = .none,
    };

    pub const AttrInterpolate = struct {
        type: InterpolationType,
        sample: InterpolationSample,

        pub const InterpolationType = enum {
            perspective,
            linear,
            flat,
        };

        pub const InterpolationSample = enum {
            center,
            centroid,
            sample,
        };
    };

    pub const VectorType = struct {
        component_type: Ref,
        size: Size,

        pub const Size = enum { two, three, four };
    };

    pub const MatrixType = struct {
        component_type: Ref,
        cols: VectorType.Size,
        rows: VectorType.Size,
    };

    pub const AtomicType = struct { component_type: Ref };

    pub const ArrayType = struct {
        component_type: Ref,
        size: Ref = .none,
    };

    pub const PointerType = struct {
        component_type: Ref,
        addr_space: AddressSpace,
        access_mode: AccessMode,

        pub const AddressSpace = enum {
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

    pub const SampledTextureType = struct {
        kind: Kind,
        component_type: Ref,

        pub const Kind = enum {
            @"1d",
            @"2d",
            @"2d_array",
            @"3d",
            cube,
            cube_array,
        };
    };

    pub const MultisampledTextureType = struct {
        kind: Kind,
        component_type: Ref,

        pub const Kind = enum { @"2d" };
    };

    pub const StorageTextureType = struct {
        kind: Kind,
        texel_format: TexelFormat,
        access_mode: AccessMode,

        pub const Kind = enum {
            @"1d",
            @"2d",
            @"2d_array",
            @"3d",
        };

        pub const TexelFormat = enum {
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

    pub const DepthTextureType = enum {
        @"2d",
        @"2d_array",
        cube,
        cube_array,
        multisampled_2d,
    };

    pub const BinaryExpr = struct {
        lhs: Ref,
        rhs: Ref,
    };

    pub const MemberAccess = struct {
        base: Ref,
        /// index to null-terminated string in `strings`
        name: u32,
    };

    comptime {
        std.debug.assert(@sizeOf(Inst) <= 32);
    }
};
