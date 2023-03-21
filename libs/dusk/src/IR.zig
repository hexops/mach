const std = @import("std");
const AstGen = @import("AstGen.zig");
const Ast = @import("Ast.zig");
const ErrorMsg = @import("main.zig").ErrorMsg;
const IR = @This();

allocator: std.mem.Allocator,
globals_index: u32,
instructions: []const Inst,
refs: []const Inst.Ref,
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

    const globals_index = astgen.genTranslationUnit() catch |err| switch (err) {
        error.AnalysisFail => return .{ .errors = try astgen.errors.toOwnedSlice(allocator) },
        error.OutOfMemory => return error.OutOfMemory,
    };

    return .{ .ir = .{
        .allocator = allocator,
        .globals_index = globals_index,
        .instructions = try astgen.instructions.toOwnedSlice(allocator),
        .refs = try astgen.refs.toOwnedSlice(allocator),
        .strings = try astgen.strings.toOwnedSlice(allocator),
    } };
}

pub fn getStr(self: IR, index: u32) []const u8 {
    return std.mem.sliceTo(self.strings[index..], 0);
}

pub const Inst = struct {
    tag: Tag,
    data: Data,

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

        pub fn isDecl(self: Tag) bool {
            return switch (self) {
                .global_variable_decl, .struct_decl => true,
                else => false,
            };
        }
    };

    pub const Data = union {
        ref: Ref,
        global_variable_decl: GlobalVariableDecl,
        struct_decl: StructDecl,
        struct_member: StructMember,
        /// attributes with no argument.
        attr_simple: AttrSimple,
        /// attributes with an expression argument.
        attr_expr: AttrExpr,
        /// @builtin attribute which accepts a BuiltinValue argument.
        attr_builtin: Ast.BuiltinValue,
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

    pub const GlobalVariableDecl = struct {
        /// index to null-terminated string in `strings`
        name: u32,
        type: Ref,
        addr_space: Ast.AddressSpace = .none,
        access_mode: Ast.AccessMode = .none,
        /// length of attributes
        attrs: u4 = 0,
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
        type: Ast.InterpolationType,
        sample: Ast.InterpolationSample,
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
        addr_space: Ast.AddressSpace,
        access_mode: Ast.AccessMode,
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
        texel_format: Ast.TexelFormat,
        access_mode: AccessMode,

        pub const Kind = enum {
            @"1d",
            @"2d",
            @"2d_array",
            @"3d",
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
        std.debug.assert(@sizeOf(Inst) <= 24);
    }
};

pub fn print(self: IR, writer: anytype) !void {
    const globals = std.mem.sliceTo(self.refs[self.globals_index..], .none);
    for (globals) |ref| {
        try self.printInst(writer, 0, ref, false);
    }
}

pub fn printInst(self: IR, writer: anytype, indention: u16, ref: Inst.Ref, as_ref: bool) !void {
    switch (ref) {
        .none,
        .bool_type,
        .i32_type,
        .u32_type,
        .f32_type,
        .f16_type,
        .sampler_type,
        .comparison_sampler_type,
        .external_sampled_texture_type,
        .true_literal,
        .false_literal,
        => {
            try writer.print("{s}()", .{@tagName(ref)});
        },
        _ => {
            const index = ref.toIndex().?;
            const inst = self.instructions[index];

            if (as_ref and inst.tag.isDecl()) {
                try writer.print("%{d}", .{index});
                return;
            }

            try writer.print("%{d} = {s}{{", .{ index, @tagName(inst.tag) });
            switch (inst.tag) {
                .global_variable_decl => {
                    try writer.writeByte('\n');

                    try printIndent(writer, indention + 1);
                    try writer.writeAll(".type = ");
                    try self.printInst(writer, indention + 2, inst.data.global_variable_decl.type, true);
                    try writer.writeAll(",\n");

                    try printIndent(writer, indention);
                    try writer.writeAll("},\n");
                },
                .struct_decl => {
                    try writer.writeByte('\n');

                    try printIndent(writer, indention + 1);
                    try writer.print(".name = \"{s}\",\n", .{self.getStr(inst.data.struct_decl.name)});

                    const members = std.mem.sliceTo(self.refs[inst.data.struct_decl.members..], .none);
                    try printIndent(writer, indention + 1);
                    try writer.writeAll(".members = [\n");
                    for (members) |member| {
                        try printIndent(writer, indention + 2);
                        try self.printInst(writer, indention + 2, member, false);
                    }
                    try printIndent(writer, indention + 1);
                    try writer.writeAll("],\n");

                    try printIndent(writer, indention);
                    try writer.writeAll("},\n");
                },
                .struct_member => {
                    try writer.writeByte('\n');

                    try printIndent(writer, indention + 1);
                    try writer.print(".name = \"{s}\",\n", .{self.getStr(inst.data.struct_member.name)});

                    try printIndent(writer, indention + 1);
                    try writer.writeAll(".type = ");
                    try self.printInst(writer, indention + 2, inst.data.struct_member.type, true);
                    try writer.writeAll(",\n");

                    try printIndent(writer, indention);
                    try writer.writeAll("},\n");
                },
                else => {
                    try writer.print("TODO", .{});
                    try writer.writeAll("}");
                },
            }
        },
    }
}

const indention_size = 2;
pub fn printIndent(writer: anytype, indent: u16) !void {
    try writer.writeByteNTimes(' ', indent * indention_size);
}
