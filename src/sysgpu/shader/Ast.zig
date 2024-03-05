const std = @import("std");
const Parser = @import("Parser.zig");
const Token = @import("Token.zig");
const Tokenizer = @import("Tokenizer.zig");
const ErrorList = @import("ErrorList.zig");
const Extensions = @import("wgsl.zig").Extensions;

const Ast = @This();

pub const NodeList = std.MultiArrayList(Node);
pub const TokenList = std.MultiArrayList(Token);

source: []const u8,
tokens: TokenList.Slice,
nodes: NodeList.Slice,
extra: []const u32,
extensions: Extensions,

pub fn deinit(tree: *Ast, allocator: std.mem.Allocator) void {
    tree.tokens.deinit(allocator);
    tree.nodes.deinit(allocator);
    allocator.free(tree.extra);
    tree.* = undefined;
}

/// parses a TranslationUnit (WGSL Program)
pub fn parse(allocator: std.mem.Allocator, errors: *ErrorList, source: [:0]const u8) error{ OutOfMemory, Parsing }!Ast {
    var p = Parser{
        .allocator = allocator,
        .source = source,
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
        .errors = errors,
    };
    defer p.scratch.deinit(allocator);
    errdefer {
        p.tokens.deinit(allocator);
        p.nodes.deinit(allocator);
        p.extra.deinit(allocator);
    }

    const estimated_nodes = p.tokens.len / 2 + 1;
    try p.nodes.ensureTotalCapacity(allocator, estimated_nodes);

    try p.translationUnit();

    return .{
        .source = source,
        .tokens = p.tokens.toOwnedSlice(),
        .nodes = p.nodes.toOwnedSlice(),
        .extra = try p.extra.toOwnedSlice(allocator),
        .extensions = p.extensions,
    };
}

pub fn spanToList(tree: Ast, span: NodeIndex) []const NodeIndex {
    std.debug.assert(tree.nodeTag(span) == .span);
    return @ptrCast(tree.extra[@intFromEnum(tree.nodeLHS(span))..@intFromEnum(tree.nodeRHS(span))]);
}

pub fn extraData(tree: Ast, comptime T: type, index: NodeIndex) T {
    const fields = std.meta.fields(T);
    var result: T = undefined;
    inline for (fields, 0..) |field, i| {
        @field(result, field.name) = @enumFromInt(tree.extra[@intFromEnum(index) + i]);
    }
    return result;
}

pub fn tokenTag(tree: Ast, i: TokenIndex) Token.Tag {
    return tree.tokens.items(.tag)[@intFromEnum(i)];
}

pub fn tokenLoc(tree: Ast, i: TokenIndex) Token.Loc {
    return tree.tokens.items(.loc)[@intFromEnum(i)];
}

pub fn nodeTag(tree: Ast, i: NodeIndex) Node.Tag {
    return tree.nodes.items(.tag)[@intFromEnum(i)];
}

pub fn nodeToken(tree: Ast, i: NodeIndex) TokenIndex {
    return tree.nodes.items(.main_token)[@intFromEnum(i)];
}

pub fn nodeLHS(tree: Ast, i: NodeIndex) NodeIndex {
    return tree.nodes.items(.lhs)[@intFromEnum(i)];
}

pub fn nodeRHS(tree: Ast, i: NodeIndex) NodeIndex {
    return tree.nodes.items(.rhs)[@intFromEnum(i)];
}

pub fn nodeLoc(tree: Ast, i: NodeIndex) Token.Loc {
    var loc = tree.tokenLoc(tree.nodeToken(i));
    switch (tree.nodeTag(i)) {
        .deref, .addr_of => {
            const lhs_loc = tree.tokenLoc(tree.nodeToken(tree.nodeLHS(i)));
            loc.end = lhs_loc.end;
        },
        .field_access => {
            const component_loc = tree.tokenLoc(@enumFromInt(@intFromEnum(tree.nodeToken(i)) + 1));
            loc.end = component_loc.end;
        },
        else => {},
    }
    return loc;
}

pub fn declNameLoc(tree: Ast, node: NodeIndex) ?Token.Loc {
    const token: TokenIndex = switch (tree.nodeTag(node)) {
        .global_var => tree.extraData(Node.GlobalVar, tree.nodeLHS(node)).name,
        .@"var" => tree.extraData(Node.Var, tree.nodeLHS(node)).name,
        .@"struct",
        .@"fn",
        .@"const",
        .let,
        .override,
        .type_alias,
        => @enumFromInt(@intFromEnum(tree.nodeToken(node)) + 1),
        .struct_member, .fn_param => tree.nodeToken(node),
        else => return null,
    };
    return tree.tokenLoc(token);
}

pub const NodeIndex = enum(u32) {
    none = std.math.maxInt(u32),
    globals = 0,
    _,

    pub fn asTokenIndex(self: NodeIndex) TokenIndex {
        return @enumFromInt(@intFromEnum(self));
    }
};

pub const TokenIndex = enum(u32) {
    none = std.math.maxInt(u32),
    _,

    pub fn asNodeIndex(self: TokenIndex) NodeIndex {
        return @enumFromInt(@intFromEnum(self));
    }
};

pub const Node = struct {
    tag: Tag,
    main_token: TokenIndex,
    lhs: NodeIndex = .none,
    rhs: NodeIndex = .none,

    pub const Tag = enum {
        /// an slice NodeIndex in extra [LHS..RHS]
        /// TOK : undefined
        /// LHS : NodeIndex
        /// RHS : NodeIndex
        span,

        /// TOK : k_var
        /// LHS : GlobalVar
        /// RHS : Expr?
        global_var,

        /// TOK : k_override
        /// LHS : Override
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
        @"struct",
        /// TOK : ident
        /// LHS : span(Attribute)
        /// RHS : Type
        struct_member,

        /// TOK : k_fn
        /// LHS : FnProto
        /// RHS : block
        @"fn",
        /// TOK : ident
        /// LHS : ?span(Attribute)
        /// RHS : type
        fn_param,

        /// TOK : brace_left
        /// LHS : span(Statement)?
        /// RHS : --
        block,

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
        /// RHS : block
        @"if",
        /// RHS is else body
        /// TOK : k_if
        /// LHS : if
        /// RHS : block
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
        /// LHS : --
        /// RHS : block
        switch_default,
        /// switch_case with default (`case 1, 2, default {}`)
        /// TOK : k_case
        /// LHS : span(Expr)
        /// RHS : block
        switch_case_default,

        /// TOK : k_var
        /// LHS : Var
        /// RHS : Expr?
        @"var",

        /// TOK : k_const
        /// LHS : Type?
        /// RHS : Expr
        @"const",

        /// TOK : k_let
        /// LHS : Type?
        /// RHS : Expr
        let,

        /// TOK : k_while
        /// LHS : Expr
        /// RHS : block
        @"while",

        /// TOK : k_for
        /// LHS : ForHeader
        /// RHS : block
        @"for",

        /// TOK : plus_plus
        /// LHS : Expr
        increase,

        /// TOK : minus_minus
        /// LHS : Expr
        decrease,

        /// TOK : plus_equal,        minus_equal,
        ///       times_equal,       division_equal,
        ///       modulo_equal,      and_equal,
        ///       or_equal,          xor_equal,
        ///       shl_equal, shl_equal
        /// LHS : Expr
        /// RHS : Expr
        compound_assign,

        /// TOK : equal
        /// LHS : Expr
        /// RHS : --
        phony_assign,

        /// TOK : k_i32, k_u32, k_f32, k_f16, k_bool
        /// LHS : --
        /// RHS : --
        number_type,

        /// TOK : k_bool
        /// LHS : --
        /// RHS : --
        bool_type,

        /// TOK : k_sampler, k_sampler_comparison
        /// LHS : --
        /// RHS : --
        sampler_type,

        /// TOK : k_vec2, k_vec3, k_vec4
        /// LHS : Type?
        /// RHS : --
        vector_type,

        /// TOK : k_mat2x2, k_mat2x3, k_mat2x4,
        ///       k_mat3x2, k_mat3x3, k_mat3x4,
        ///       k_mat4x2, k_mat4x3, k_mat4x4
        /// LHS : Type?
        /// RHS : --
        matrix_type,

        /// TOK : k_atomic
        /// LHS : Type
        /// RHS : --
        atomic_type,

        /// TOK : k_array
        /// LHS : Type?
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

        /// TOK : k_texture_multisampled_2d, k_texture_depth_multisampled_2d
        /// LHS : Type?
        /// RHS : --
        multisampled_texture_type,

        /// TOK : k_texture_external
        /// LHS : Type
        /// RHS : --
        external_texture_type,

        /// TOK : k_texture_storage_1d, k_texture_storage_2d,
        ///       k_texture_storage_2d_array, k_texture_storage_3d
        /// LHS : Token(TexelFormat)
        /// RHS : Token(AccessMode)
        storage_texture_type,

        /// TOK : k_texture_depth_2d, k_texture_depth_2d_array
        ///       k_texture_depth_cube, k_texture_depth_cube_array
        /// LHS : --
        /// RHS : --
        depth_texture_type,

        /// TOK : attr
        attr_const,

        /// TOK : attr
        attr_invariant,

        /// TOK : attr
        attr_must_use,

        /// TOK : attr
        attr_vertex,

        /// TOK : attr
        attr_fragment,

        /// TOK : attr
        attr_compute,

        /// TOK : attr
        /// LHS : Expr
        /// RHS : --
        attr_align,

        /// TOK : attr
        /// LHS : Expr
        /// RHS : --
        attr_binding,

        /// TOK : attr
        /// LHS : Expr
        /// RHS : --
        attr_group,

        /// TOK : attr
        /// LHS : Expr
        /// RHS : --
        attr_id,

        /// TOK : attr
        /// LHS : Expr
        /// RHS : --
        attr_location,

        /// TOK : attr
        /// LHS : Expr
        /// RHS : --
        attr_size,

        /// TOK : attr
        /// LHS : Token(Builtin)
        /// RHS : --
        attr_builtin,

        /// TOK : attr
        /// LHS : WorkgroupSize
        /// RHS : --
        attr_workgroup_size,

        /// TOK : attr
        /// LHS : Token(InterpolationType)
        /// RHS : Token(InterpolationSample))
        attr_interpolate,

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
        shl,

        /// TOK : >>
        /// LHS : Expr
        /// RHS : Expr
        shr,

        /// TOK : &
        /// LHS : Expr
        /// RHS : Expr
        @"and",

        /// TOK : |
        /// LHS : Expr
        /// RHS : Expr
        @"or",

        /// TOK : ^
        /// LHS : Expr
        /// RHS : Expr
        xor,

        /// TOK : &&
        /// LHS : Expr
        /// RHS : Expr
        logical_and,

        /// TOK : ||
        /// LHS : Expr
        /// RHS : Expr
        logical_or,

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
        less_than,

        /// TOK : <=
        /// LHS : Expr
        /// RHS : Expr
        less_than_equal,

        /// TOK : >
        /// LHS : Expr
        /// RHS : Expr
        greater_than,

        /// TOK : >=
        /// LHS : Expr
        /// RHS : Expr
        greater_than_equal,

        /// for identifier, array without element type specified,
        /// vector prefix (e.g. vec2) and matrix prefix (e.g. mat2x2) RHS is null
        /// see callExpr in Parser.zig if you don't understand this
        ///
        /// TOK : ident, k_array, k_bool, 'number type keywords', 'vector keywords', 'matrix keywords'
        /// LHS : span(Arguments Expr)
        /// RHS : (number_type, bool_type, vector_type, matrix_type, array_type)?
        call,

        /// TOK : k_bitcast
        /// LHS : Type
        /// RHS : Expr
        bitcast,

        /// TOK : ident
        /// LHS : --
        /// RHS : --
        ident,

        /// LHS is prefix expression
        /// TOK : ident
        /// LHS : Expr
        /// RHS : Token(NodeIndex(ident))
        field_access,

        /// LHS is prefix expression
        /// TOK : bracket_left
        /// LHS : Expr
        /// RHS : Expr
        index_access,

        /// TOK : k_true
        /// LHS : --
        /// RHS : --
        true,
        /// TOK : k_false
        /// LHS : --
        /// RHS : --
        false,
        /// TOK : number
        /// LHS : --
        /// RHS : --
        number,
    };

    pub const GlobalVar = struct {
        /// span(Attr)?
        attrs: NodeIndex = .none,
        /// Token(ident)
        name: TokenIndex,
        /// Token(AddressSpace)?
        addr_space: TokenIndex = .none,
        /// Token(AccessMode)?
        access_mode: TokenIndex = .none,
        /// Type?
        type: NodeIndex = .none,
    };

    pub const Var = struct {
        /// Token(ident)
        name: TokenIndex,
        /// Token(AddressSpace)?
        addr_space: TokenIndex = .none,
        /// Token(AccessMode)?
        access_mode: TokenIndex = .none,
        /// Type?
        type: NodeIndex = .none,
    };

    pub const Override = struct {
        /// span(Attr)?
        attrs: NodeIndex = .none,
        /// Type?
        type: NodeIndex = .none,
    };

    pub const PtrType = struct {
        /// Token(AddressSpace)
        addr_space: TokenIndex,
        /// Token(AccessMode)
        access_mode: TokenIndex,
    };

    pub const WorkgroupSize = struct {
        /// Expr
        x: NodeIndex,
        /// Expr?
        y: NodeIndex = .none,
        /// Expr?
        z: NodeIndex = .none,
    };

    pub const FnProto = struct {
        /// span(Attr)?
        attrs: NodeIndex = .none,
        /// span(fn_param)?
        params: NodeIndex = .none,
        /// span(Attr)?
        return_attrs: NodeIndex = .none,
        /// Type?
        return_type: NodeIndex = .none,
    };

    pub const ForHeader = struct {
        /// var, const, let, phony_assign, compound_assign
        init: NodeIndex = .none,
        /// Expr
        cond: NodeIndex = .none,
        /// call, phony_assign, compound_assign
        update: NodeIndex = .none,
    };
};

pub const Builtin = enum {
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
    must_use,
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
