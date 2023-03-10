const std = @import("std");
const Parser = @import("Parser.zig");
const Token = @import("Token.zig");
const Tokenizer = @import("Tokenizer.zig");
const ErrorMsg = @import("main.zig").ErrorMsg;
const Extension = @import("main.zig").Extension;

const Ast = @This();

pub const NodeList = std.MultiArrayList(Node);
pub const TokenList = std.MultiArrayList(Token);

source: [:0]const u8,
tokens: TokenList.Slice,
nodes: NodeList.Slice,
extra: []const Index,

pub fn deinit(tree: *Ast, allocator: std.mem.Allocator) void {
    tree.tokens.deinit(allocator);
    tree.nodes.deinit(allocator);
    allocator.free(tree.extra);
    tree.* = undefined;
}

pub const ParseResult = union(enum) {
    errors: []ErrorMsg,
    tree: Ast,
};

/// parses a TranslationUnit (WGSL Program)
pub fn parse(allocator: std.mem.Allocator, source: [:0]const u8) !ParseResult {
    var p = Parser{
        .allocator = allocator,
        .source = source,
        .tok_i = 0,
        .tokens = blk: {
            const estimated_tokens = source.len / 8;

            var tokens = std.MultiArrayList(Token){};
            errdefer tokens.deinit(allocator);

            try tokens.ensureTotalCapacity(allocator, estimated_tokens);

            var tokenizer = Tokenizer.init(source);
            while (true) {
                const tok = tokenizer.next();
                try tokens.append(allocator, tok);
                if (tok.tag == .eof) break;
            }

            break :blk tokens;
        },
        .nodes = .{},
        .extra = .{},
        .scratch = .{},
        .errors = .{},
        .extensions = Extension.Array.initFill(false),
    };
    defer p.deinit();

    // TODO: make sure tokens:nodes ratio is right
    const estimated_node_count = (p.tokens.len + 2) / 2;
    try p.nodes.ensureTotalCapacity(allocator, estimated_node_count);

    _ = try p.translationUnit() orelse {
        return .{ .errors = try p.errors.toOwnedSlice(allocator) };
    };

    return .{
        .tree = .{
            .source = source,
            .tokens = p.tokens.toOwnedSlice(),
            .nodes = p.nodes.toOwnedSlice(),
            .extra = try p.extra.toOwnedSlice(allocator),
        },
    };
}

pub fn spanToList(tree: Ast, span: Ast.Index) []const Ast.Index {
    std.debug.assert(tree.nodeTag(span) == .span);
    return tree.extra[tree.nodeLHS(span)..tree.nodeRHS(span)];
}

pub fn extraData(tree: Ast, comptime T: type, index: Ast.Index) T {
    const fields = std.meta.fields(T);
    var result: T = undefined;
    inline for (fields, 0..) |field, i| {
        comptime std.debug.assert(field.type == Ast.Index);
        @field(result, field.name) = tree.extra[index + i];
    }
    return result;
}

pub fn tokenTag(tree: Ast, i: Index) Token.Tag {
    return tree.tokens.items(.tag)[i];
}

pub fn tokenLoc(tree: Ast, i: Index) Token.Loc {
    return tree.tokens.items(.loc)[i];
}

pub fn nodeTag(tree: Ast, i: Index) Node.Tag {
    return tree.nodes.items(.tag)[i];
}

pub fn nodeToken(tree: Ast, i: Index) Index {
    return tree.nodes.items(.main_token)[i];
}

pub fn nodeLHS(tree: Ast, i: Index) Index {
    return tree.nodes.items(.lhs)[i];
}

pub fn nodeRHS(tree: Ast, i: Index) Index {
    return tree.nodes.items(.rhs)[i];
}

pub const Index = u32;
pub const null_index: Index = 0;
pub const Node = struct {
    tag: Tag,
    main_token: Index,
    lhs: Index = null_index,
    rhs: Index = null_index,

    pub const Tag = enum {
        /// an slice to extra field [LHS..RHS]
        /// TOK : undefined
        /// LHS : Index
        /// RHS : Index
        span,

        // ####### GlobalDecl #######

        /// TOK : k_var
        /// LHS : GlobalVarDecl
        /// RHS : Expr?
        global_variable,

        /// TOK : k_const
        /// LHS : Type
        /// RHS : Expr
        global_constant,

        /// TOK : k_override
        /// LHS : OverrideDecl
        /// RHS : Expr
        override,

        /// TOK : k_type
        /// LHS : Type
        /// RHS : --
        type_alias,

        /// TOK : k_const_assert
        /// LHS : Expr
        /// RHS : --
        const_assert,

        /// TOK : k_struct
        /// LHS : span(struct_member)
        /// RHS : --
        struct_decl,
        /// TOK : ident
        /// LHS : span(Attribute)
        /// RHS : Type
        struct_member,

        /// TOK : k_fn
        /// LHS : FnProto
        /// RHS : block
        fn_decl,
        /// TOK : ident
        /// LHS : ? Attributes
        /// RHS : type
        fn_param,

        // ####### Statement #######

        // block = span(Statement)

        /// TOK : k_return
        /// LHS : Expr?
        /// RHS : --
        @"return",

        /// TOK : k_discard
        /// LHS : --
        /// RHS : --
        discard,

        /// TOK : k_loop
        /// LHS : block
        /// RHS : --
        loop,

        /// TOK : k_continuing
        /// LHS : block
        /// RHS : --
        continuing,

        /// TOK : k_break
        /// LHS : Expr
        /// RHS : --
        break_if,

        /// TOK : k_break
        /// LHS : --
        /// RHS : --
        @"break",

        /// TOK : k_continue
        /// LHS : --
        /// RHS : --
        @"continue",

        /// TOK : k_if
        /// LHS : Expr
        /// RHS : blcok
        @"if",
        /// RHS is else body
        /// TOK : k_if
        /// LHS : if
        /// RHS : blcok
        if_else,
        /// TOK : k_if
        /// LHS : if
        /// RHS : if, if_else, if_else_if
        if_else_if,

        /// TOK : k_switch
        /// LHS : Expr
        /// RHS : span(switch_case, switch_default, switch_case_default)
        @"switch",
        /// TOK : k_case
        /// LHS : span(Expr)
        /// RHS : block
        switch_case,
        /// TOK : k_default
        /// LHS : block
        /// RHS : --
        switch_default,
        /// switch_case with default (`case 1, 2, default {}`)
        /// TOK : k_case
        /// LHS : span(Expr)
        /// RHS : block
        switch_case_default,

        /// TOK : k_var
        /// LHS : VarDecl
        /// RHS : Expr?
        var_decl,

        /// TOK : k_const
        /// LHS : Type?
        /// RHS : Expr
        const_decl,

        /// TOK : k_let
        /// LHS : Type?
        /// RHS : Expr
        let_decl,

        /// TOK : k_while
        /// LHS : Expr
        /// RHS : block
        @"while",

        /// TOK : k_for
        /// LHS : ForHeader
        /// RHS : block
        @"for",

        /// TOK : plus_plus, minus_minus
        /// LHS : Expr
        increase_decrement,

        /// TOK : plus_equal,        minus_equal,
        ///       times_equal,       division_equal,
        ///       modulo_equal,      and_equal,
        ///       or_equal,          xor_equal,
        ///       shift_right_equal, shift_left_equal
        /// LHS : Expr
        /// RHS : Expr
        compound_assign,

        /// TOK : equal
        /// LHS : Expr
        /// RHS : --
        phony_assign,

        // ####### Type #######

        /// TOK : k_i32, k_u32, k_f32, k_f16, k_bool
        /// LHS : --
        /// RHS : --
        number_type,

        /// TOK : k_bool
        /// LHS : --
        /// RHS : --
        bool_type,

        /// TOK : k_sampler, k_comparison_sampler
        /// LHS : --
        /// RHS : --
        sampler_type,

        /// TOK : k_vec2, k_vec3, k_vec4
        /// LHS : Type
        /// RHS : --
        vector_type,

        /// TOK : k_mat2x2, k_mat2x3, k_mat2x4,
        ///       k_mat3x2, k_mat3x3, k_mat3x4,
        ///       k_mat4x2, k_mat4x3, k_mat4x4
        /// LHS : Type
        /// RHS : --
        matrix_type,

        /// TOK : k_atomic
        /// LHS : Type
        /// RHS : --
        atomic_type,

        /// TOK : k_array
        /// LHS : Type
        /// RHS : Expr?
        array_type,

        /// TOK : k_ptr
        /// LHS : Type
        /// RHS : PtrType
        ptr_type,

        /// TOK : k_texture_1d, k_texture_2d, k_texture_2d_array,
        ///       k_texture_3d, k_texture_cube, k_texture_cube_array
        /// LHS : Type
        /// RHS : --
        sampled_texture_type,

        /// TOK : k_texture_multisampled_2d
        /// LHS : Type
        /// RHS : --
        multisampled_texture_type,

        /// TOK : k_texture_external
        /// LHS : Type
        /// RHS : --
        external_texture_type,

        /// TOK : k_texture_storage_1d, k_texture_storage_2d,
        ///       k_texture_storage_2d_array, k_texture_storage_3d
        /// LHS : Index(Token(TexelFormat))
        /// RHS : Index(Token(AccessMode))
        storage_texture_type,

        /// TOK : k_texture_depth_2d, k_texture_depth_2d_array
        ///       k_texture_depth_cube, k_texture_depth_cube_array
        ///       k_texture_depth_multisampled_2d
        /// LHS : --
        /// RHS : --
        depth_texture_type,

        /// TOK : ident
        /// LHS : --
        /// RHS : --
        user_type,

        // ####### Attr #######

        // TOK : attr
        attr,

        /// TOK : attr
        /// LHS : Expr
        /// RHS : --
        attr_one_arg,

        /// TOK : attr
        /// LHS : Index(Token(BuiltinValue))
        /// RHS : --
        attr_builtin,

        /// TOK : attr
        /// LHS : WorkgroupSize
        /// RHS : --
        attr_workgroup_size,

        /// TOK : attr
        /// LHS : Index(Token(InterpolationType))
        /// RHS : Index(Token(InterpolationSample))
        attr_interpolate,

        // ####### Expr #######
        // see both Parser.zig and https://gpuweb.github.io/gpuweb/wgsl/#expression-grammar

        /// TOK : *
        /// LHS : Expr
        /// RHS : Expr
        mul,

        /// TOK : /
        /// LHS : Expr
        /// RHS : Expr
        div,

        /// TOK : %
        /// LHS : Expr
        /// RHS : Expr
        mod,

        /// TOK : +
        /// LHS : Expr
        /// RHS : Expr
        add,

        /// TOK : -
        /// LHS : Expr
        /// RHS : Expr
        sub,

        /// TOK : <<
        /// LHS : Expr
        /// RHS : Expr
        shift_left,

        /// TOK : >>
        /// LHS : Expr
        /// RHS : Expr
        shift_right,

        /// TOK : &
        /// LHS : Expr
        /// RHS : Expr
        binary_and,

        /// TOK : |
        /// LHS : Expr
        /// RHS : Expr
        binary_or,

        /// TOK : ^
        /// LHS : Expr
        /// RHS : Expr
        binary_xor,

        /// TOK : &&
        /// LHS : Expr
        /// RHS : Expr
        circuit_and,

        /// TOK : ||
        /// LHS : Expr
        /// RHS : Expr
        circuit_or,

        /// TOK : !
        /// LHS : Expr
        /// RHS : --
        not,

        /// TOK : -
        /// LHS : Expr
        /// RHS : --
        negate,

        /// TOK : *
        /// LHS : Expr
        /// RHS : --
        deref,

        /// TOK : &
        /// LHS : Expr
        /// RHS : --
        addr_of,

        /// TOK : ==
        /// LHS : Expr
        /// RHS : Expr
        equal,

        /// TOK : !=
        /// LHS : Expr
        /// RHS : Expr
        not_equal,

        /// TOK : <
        /// LHS : Expr
        /// RHS : Expr
        less,

        /// TOK : <=
        /// LHS : Expr
        /// RHS : Expr
        less_equal,

        /// TOK : >
        /// LHS : Expr
        /// RHS : Expr
        greater,

        /// TOK : >=
        /// LHS : Expr
        /// RHS : Expr
        greater_equal,

        /// for identifier, array without element type specified,
        /// vector prefix (e.g. vec2) and matrix prefix (e.g. mat2x2) LHS is null
        /// see callExpr in Parser.zig if you don't understand this
        ///
        /// TOK : ident, k_array, k_bool, 'number type keywords', 'vector keywords', 'matrix keywords'
        /// LHS : (number_type, bool_type, vector_type, matrix_type, array_type)?
        /// RHS : arguments (Expr span)
        call,

        /// TOK : k_bitcast
        /// LHS : Type
        /// RHS : Expr
        bitcast,

        /// TOK : ident
        /// LHS : --
        /// RHS : --
        ident_expr,

        /// LHS is prefix expression
        /// TOK : ident
        /// LHS : Expr
        component_access,

        /// LHS is prefix expression
        /// TOK : bracket_left
        /// LHS : Expr
        /// RHS : Expr
        index_access,

        // ####### Literals #######

        /// TOK : k_true, k_false
        /// LHS : --
        /// RHS : --
        bool_literal,
        /// TOK : number
        /// LHS : --
        /// RHS : --
        number_literal,
    };

    pub const GlobalVarDecl = struct {
        /// span(Attr)?
        attrs: Index = null_index,
        /// Token(ident)
        name: Index,
        /// Token(AddrSpace)?
        addr_space: Index = null_index,
        /// Token(AccessMode)?
        access_mode: Index = null_index,
        /// Type?
        type: Index = null_index,
    };

    pub const VarDecl = struct {
        /// Token(ident)
        name: Index,
        /// Token(AddrSpace)?
        addr_space: Index = null_index,
        /// Token(AccessMode)?
        access_mode: Index = null_index,
        /// Type?
        type: Index = null_index,
    };

    pub const OverrideDecl = struct {
        /// span(Attr)?
        attrs: Index = null_index,
        /// Type?
        type: Index = null_index,
    };

    pub const PtrType = struct {
        /// Token(AddrSpace)
        addr_space: Index,
        /// Token(AccessMode)?
        access_mode: Index = null_index,
    };

    pub const WorkgroupSize = struct {
        /// Expr
        x: Index,
        /// Expr?
        y: Index = null_index,
        /// Expr?
        z: Index = null_index,
    };

    pub const FnProto = struct {
        /// span(Attr)?
        attrs: Index = null_index,
        /// span(fn_param)?
        params: Index = null_index,
        /// span(Attr)?
        result_attrs: Index = null_index,
        /// Type?
        result_type: Index = null_index,
    };

    pub const IfStatement = struct {
        /// Expr
        cond: Index,
        /// block
        body: Index,
    };

    pub const ForHeader = struct {
        /// var_decl, const_decl, let_decl, phony_assign, compound_assign
        init: Index = null_index,
        /// Expr
        cond: Index = null_index,
        /// call, phony_assign, compound_assign
        update: Index = null_index,
    };
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

pub const Attribute = enum {
    invariant,
    @"const",
    vertex,
    fragment,
    compute,
    @"align",
    binding,
    group,
    id,
    location,
    size,
    builtin,
    workgroup_size,
    interpolate,
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
