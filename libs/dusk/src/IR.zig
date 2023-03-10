const std = @import("std");
const AstGen = @import("AstGen.zig");
const Ast = @import("Ast.zig");
const ErrorMsg = @import("main.zig").ErrorMsg;
const IR = @This();

arena: std.heap.ArenaAllocator,
root: TranslationUnit,

pub fn deinit(self: IR) void {
    self.arena.deinit();
}

pub const AstGenResult = union(enum) {
    ir: IR,
    errors: []ErrorMsg,
};

pub fn generate(allocator: std.mem.Allocator, tree: *const Ast) !AstGenResult {
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    var astgen = AstGen{
        .arena = arena.allocator(),
        .allocator = allocator,
        .tree = tree,
        .errors = .{},
    };
    defer astgen.deinit();

    const root = try astgen.translationUnit() orelse {
        arena.deinit();
        return .{
            .errors = try astgen.errors.toOwnedSlice(allocator),
        };
    };

    return .{ .ir = .{ .arena = arena, .root = root } };
}

pub const TranslationUnit = []const GlobalDecl;

pub const GlobalDecl = union(enum) {
    variable: GlobalVariable,
    @"struct": StructDecl,
};

pub const GlobalVariable = struct {
    name: []const u8,
    type: union(enum) {},
    expr: Expression,
};

pub const StructDecl = struct {
    name: []const u8,
    members: []const StructMember,
};

pub const StructMember = struct {
    name: []const u8,
    type: Type,

    pub const Type = union(enum) {
        bool,
        @"struct": []const u8,
        number: NumberType,
        vector: VectorType,
        matrix: MatrixType,
        atomic: AtomicType,
        array: ArrayType,
    };
};

pub const Expression = union(enum) {
    literal: Literal,
    ident: []const u8,
    unary: struct {
        op: UnaryOperator,
        expr: *const Expression,
    },
    binary: struct {
        op: BinaryOperator,
        lhs: *const Expression,
        rhs: *const Expression,
    },
    index: struct {
        base: *const Expression,
        index: *const Expression,
    },
    member: struct {
        base: *const Expression,
        field: []const u8,
    },
    bitcast: struct {
        expr: *const Expression,
        to: union(enum) {
            number: NumberType,
            vector: VectorType,
        },
    },
};

pub const Literal = union(enum) {
    number: NumberLiteral,
    bool: bool,
};

pub const NumberLiteral = union(enum) {
    int: i64,
    float: f64,
};

pub const UnaryOperator = enum {
    not,
    negate,
    addr_of,
    deref,
};

pub const BinaryOperator = enum {
    mul,
    div,
    mod,
    add,
    sub,
    shift_left,
    shift_right,
    binary_and,
    binary_or,
    binary_xor,
    circuit_and,
    circuit_or,
    equal,
    not_equal,
    less,
    less_equal,
    greater,
    greater_equal,
};

pub const NumberType = enum {
    i32,
    u32,
    f32,
    f16,
};

pub const VectorType = struct {
    size: Size,
    component_type: Type,

    pub const Type = union(enum) {
        bool,
        number: NumberType,
    };

    pub const Size = enum {
        vec2,
        vec3,
        vec4,
    };
};

pub const MatrixType = struct {
    size: Size,
    component_type: Type,

    pub const Type = enum {
        f32,
        f16,
        abstract_float,
    };

    pub const Size = enum {
        mat2x2,
        mat2x3,
        mat2x4,
        mat3x2,
        mat3x3,
        mat3x4,
        mat4x2,
        mat4x3,
        mat4x4,
    };
};

pub const AtomicType = struct {
    component_type: Type,

    pub const Type = enum {
        u32,
        i32,
    };
};

pub const ArrayType = struct {
    component_type: Type,
    size: ?NumberLiteral = null,

    pub const Type = union(enum) {
        bool,
        number: NumberType,
        @"struct": []const u8,
        vector: VectorType,
        matrix: MatrixType,
        atomic: AtomicType,
        array: *Type,
    };
};
