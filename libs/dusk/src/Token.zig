const std = @import("std");

tag: Tag,
loc: Loc,

pub const Loc = struct {
    start: u32,
    end: u32,

    pub const Extra = struct {
        line: u32,
        col: u32,
        line_start: u32,
        line_end: u32,
    };

    pub fn slice(self: Loc, source: []const u8) []const u8 {
        return source[self.start..self.end];
    }

    pub fn extraInfo(self: Loc, source: []const u8) Extra {
        var result = Extra{
            .line = 1,
            .col = 1,
            .line_start = 0,
            .line_end = @intCast(u32, source.len),
        };

        for (source[0..self.start], 0..) |c, i| {
            if (c == '\n') {
                result.line += 1;
                result.line_start = @intCast(u32, i) + 1;
            }
        }

        for (source[self.end..], 0..) |c, i| {
            if (c == '\n') {
                result.line_end = self.end + @intCast(u32, i);
                break;
            }
        }

        result.col += self.start - result.line_start;
        return result;
    }
};

pub const Tag = enum {
    eof,
    invalid,

    ident,
    /// any number literal
    number,

    /// '&'
    @"and",
    /// '&&'
    and_and,
    /// '->'
    arrow,
    /// '@'
    attr,
    /// '/'
    division,
    /// '!'
    bang,
    /// '{'
    brace_left,
    /// '}'
    brace_right,
    /// '['
    bracket_left,
    /// ']'
    bracket_right,
    /// ':'
    colon,
    /// ','
    comma,
    /// '='
    equal,
    /// '=='
    equal_equal,
    /// '>'
    greater_than,
    /// '>='
    greater_than_equal,
    /// '>>'
    shift_right,
    /// '<'
    less_than,
    /// '<='
    less_than_equal,
    /// '<<'
    shift_left,
    /// '%'
    mod,
    /// '-'
    minus,
    /// '--'
    minus_minus,
    /// '!='
    not_equal,
    /// '.'
    period,
    /// '+'
    plus,
    /// '++'
    plus_plus,
    /// '|'
    @"or",
    /// '||'
    or_or,
    /// '('
    paren_left,
    /// ')'
    paren_right,
    /// ';'
    semicolon,
    /// '*'
    star,
    /// '~'
    tilde,
    /// '_'
    underscore,
    /// '^'
    xor,
    /// '+='
    plus_equal,
    /// '-='
    minus_equal,
    /// '*='
    times_equal,
    /// '/='
    division_equal,
    /// '%='
    modulo_equal,
    /// '&='
    and_equal,
    /// '|='
    or_equal,
    /// '^='
    xor_equal,
    /// '>>='
    shift_right_equal,
    /// '<<='
    shift_left_equal,

    /// 'array'
    k_array,
    /// 'atomic'
    k_atomic,
    /// 'bitcast'
    k_bitcast,
    /// 'bool'
    k_bool,
    /// 'break'
    k_break,
    /// 'case'
    k_case,
    /// 'const'
    k_const,
    /// 'continue'
    k_continue,
    /// 'continuing'
    k_continuing,
    /// 'discard'
    k_discard,
    /// 'default'
    k_default,
    /// 'else'
    k_else,
    /// 'enable'
    k_enable,
    /// 'f16'
    k_f16,
    /// 'f32'
    k_f32,
    /// 'fallthrough'
    k_fallthrough,
    /// 'false'
    k_false,
    /// 'fn'
    k_fn,
    /// 'for'
    k_for,
    /// 'i32'
    k_i32,
    /// 'if'
    k_if,
    /// 'let'
    k_let,
    /// 'loop'
    k_loop,
    /// 'mat2x2'
    k_mat2x2,
    /// 'mat2x3'
    k_mat2x3,
    /// 'mat2x4'
    k_mat2x4,
    /// 'mat3x2'
    k_mat3x2,
    /// 'mat3x3'
    k_mat3x3,
    /// 'mat3x4'
    k_mat3x4,
    /// 'mat4x2'
    k_mat4x2,
    /// 'mat4x3'
    k_mat4x3,
    /// 'mat4x4'
    k_mat4x4,
    /// 'override'
    k_override,
    /// 'ptr'
    k_ptr,
    /// 'require'
    k_require,
    /// 'return'
    k_return,
    /// 'sampler'
    k_sampler,
    /// 'sampler_comparison'
    k_comparison_sampler,
    /// 'const_assert'
    k_const_assert,
    /// 'struct'
    k_struct,
    /// 'switch'
    k_switch,
    /// 'texture_depth_2d'
    k_texture_depth_2d,
    /// 'texture_depth_2d_array'
    k_texture_depth_2d_array,
    /// 'texture_depth_cube'
    k_texture_depth_cube,
    /// 'texture_depth_cube_array'
    k_texture_depth_cube_array,
    /// 'texture_depth_multisampled_2d'
    k_texture_depth_multisampled_2d,
    /// 'texture_external'
    k_texture_external,
    /// 'texture_multisampled_2d'
    k_texture_multisampled_2d,
    /// 'texture_1d'
    k_texture_sampled_1d,
    /// 'texture_2d'
    k_texture_sampled_2d,
    /// 'texture_2d_array'
    k_texture_sampled_2d_array,
    /// 'texture_3d'
    k_texture_sampled_3d,
    /// 'texture_cube'
    k_texture_sampled_cube,
    /// 'texture_cube_array'
    k_texture_sampled_cube_array,
    /// 'texture_storage_1d'
    k_texture_storage_1d,
    /// 'texture_storage_2d'
    k_texture_storage_2d,
    /// 'texture_storage_2d_array'
    k_texture_storage_2d_array,
    /// 'texture_storage_3d'
    k_texture_storage_3d,
    /// 'true'
    k_true,
    /// 'type'
    k_type,
    /// 'u32'
    k_u32,
    /// 'var'
    k_var,
    /// 'vec2'
    k_vec2,
    /// 'vec3'
    k_vec3,
    /// 'vec4'
    k_vec4,
    /// 'while'
    k_while,

    pub fn symbol(self: Tag) []const u8 {
        return switch (self) {
            .eof => "EOF",
            .invalid => "invalid bytes",
            .ident => "an identifier",
            .number => "a number literal",
            .@"and" => "&",
            .and_and => "&&",
            .arrow => "->",
            .attr => "@",
            .division => "/",
            .bang => "!",
            .brace_left => "{",
            .brace_right => "}",
            .bracket_left => "[",
            .bracket_right => "]",
            .colon => ":",
            .comma => ",",
            .equal => "=",
            .equal_equal => "==",
            .greater_than => ">",
            .greater_than_equal => ">=",
            .shift_right => ">>",
            .less_than => "<",
            .less_than_equal => "<=",
            .shift_left => "<<",
            .mod => "%",
            .minus => "-",
            .minus_minus => "--",
            .not_equal => "!=",
            .period => ".",
            .plus => "+",
            .plus_plus => "++",
            .@"or" => "|",
            .or_or => "||",
            .paren_left => "(",
            .paren_right => ")",
            .semicolon => ";",
            .star => "*",
            .tilde => "~",
            .underscore => "_",
            .xor => "^",
            .plus_equal => "+=",
            .minus_equal => "-=",
            .times_equal => "*=",
            .division_equal => "/=",
            .modulo_equal => "%=",
            .and_equal => "&=",
            .or_equal => "|=",
            .xor_equal => "^=",
            .shift_right_equal => ">>=",
            .shift_left_equal => "<<=",
            .k_array => "array",
            .k_atomic => "atomic",
            .k_bitcast => "bitcast",
            .k_bool => "bool",
            .k_break => "break",
            .k_case => "case",
            .k_const => "const",
            .k_continue => "continue",
            .k_continuing => "continuing",
            .k_discard => "discard",
            .k_default => "default",
            .k_else => "else",
            .k_enable => "enable",
            .k_f16 => "f16",
            .k_f32 => "f32",
            .k_fallthrough => "fallthrough",
            .k_false => "false",
            .k_fn => "fn",
            .k_for => "for",
            .k_i32 => "i32",
            .k_if => "if",
            .k_let => "let",
            .k_loop => "loop",
            .k_mat2x2 => "mat2x2",
            .k_mat2x3 => "mat2x3",
            .k_mat2x4 => "mat2x4",
            .k_mat3x2 => "mat3x2",
            .k_mat3x3 => "mat3x3",
            .k_mat3x4 => "mat3x4",
            .k_mat4x2 => "mat4x2",
            .k_mat4x3 => "mat4x3",
            .k_mat4x4 => "mat4x4",
            .k_override => "override",
            .k_ptr => "ptr",
            .k_require => "require",
            .k_return => "return",
            .k_sampler => "sampler",
            .k_comparison_sampler => "sampler_comparison",
            .k_const_assert => "const_assert",
            .k_struct => "struct",
            .k_switch => "switch",
            .k_texture_depth_2d => "texture_depth_2d",
            .k_texture_depth_2d_array => "texture_depth_2d_array",
            .k_texture_depth_cube => "texture_depth_cube",
            .k_texture_depth_cube_array => "texture_depth_cube_array",
            .k_texture_depth_multisampled_2d => "texture_depth_multisampled_2d",
            .k_texture_external => "texture_external",
            .k_texture_multisampled_2d => "texture_multisampled_2d",
            .k_texture_sampled_1d => "texture_1d",
            .k_texture_sampled_2d => "texture_2d",
            .k_texture_sampled_2d_array => "texture_2d_array",
            .k_texture_sampled_3d => "texture_3d",
            .k_texture_sampled_cube => "texture_cube",
            .k_texture_sampled_cube_array => "texture_cube_array",
            .k_texture_storage_1d => "texture_storage_1d",
            .k_texture_storage_2d => "texture_storage_2d",
            .k_texture_storage_2d_array => "texture_storage_2d_array",
            .k_texture_storage_3d => "texture_storage_3d",
            .k_true => "true",
            .k_type => "type",
            .k_u32 => "u32",
            .k_var => "var",
            .k_vec2 => "vec2",
            .k_vec3 => "vec3",
            .k_vec4 => "vec4",
            .k_while => "while",
        };
    }
};

pub const keywords = std.ComptimeStringMap(Tag, .{
    .{ "array", .k_array },
    .{ "atomic", .k_atomic },
    .{ "bitcast", .k_bitcast },
    .{ "bool", .k_bool },
    .{ "break", .k_break },
    .{ "case", .k_case },
    .{ "const", .k_const },
    .{ "continue", .k_continue },
    .{ "continuing", .k_continuing },
    .{ "discard", .k_discard },
    .{ "default", .k_default },
    .{ "else", .k_else },
    .{ "enable", .k_enable },
    .{ "f16", .k_f16 },
    .{ "f32", .k_f32 },
    .{ "fallthrough", .k_fallthrough },
    .{ "false", .k_false },
    .{ "fn", .k_fn },
    .{ "for", .k_for },
    .{ "i32", .k_i32 },
    .{ "if", .k_if },
    .{ "let", .k_let },
    .{ "loop", .k_loop },
    .{ "mat2x2", .k_mat2x2 },
    .{ "mat2x3", .k_mat2x3 },
    .{ "mat2x4", .k_mat2x4 },
    .{ "mat3x2", .k_mat3x2 },
    .{ "mat3x3", .k_mat3x3 },
    .{ "mat3x4", .k_mat3x4 },
    .{ "mat4x2", .k_mat4x2 },
    .{ "mat4x3", .k_mat4x3 },
    .{ "mat4x4", .k_mat4x4 },
    .{ "override", .k_override },
    .{ "ptr", .k_ptr },
    .{ "require", .k_require },
    .{ "return", .k_return },
    .{ "sampler", .k_sampler },
    .{ "sampler_comparison", .k_comparison_sampler },
    .{ "const_assert", .k_const_assert },
    .{ "struct", .k_struct },
    .{ "switch", .k_switch },
    .{ "texture_depth_2d", .k_texture_depth_2d },
    .{ "texture_depth_2d_array", .k_texture_depth_2d_array },
    .{ "texture_depth_cube", .k_texture_depth_cube },
    .{ "texture_depth_cube_array", .k_texture_depth_cube_array },
    .{ "texture_depth_multisampled_2d", .k_texture_depth_multisampled_2d },
    .{ "texture_external", .k_texture_external },
    .{ "texture_multisampled_2d", .k_texture_multisampled_2d },
    .{ "texture_1d", .k_texture_sampled_1d },
    .{ "texture_2d", .k_texture_sampled_2d },
    .{ "texture_2d_array", .k_texture_sampled_2d_array },
    .{ "texture_3d", .k_texture_sampled_3d },
    .{ "texture_cube", .k_texture_sampled_cube },
    .{ "texture_cube_array", .k_texture_sampled_cube_array },
    .{ "texture_storage_1d", .k_texture_storage_1d },
    .{ "texture_storage_2d", .k_texture_storage_2d },
    .{ "texture_storage_2d_array", .k_texture_storage_2d_array },
    .{ "texture_storage_3d", .k_texture_storage_3d },
    .{ "true", .k_true },
    .{ "type", .k_type },
    .{ "u32", .k_u32 },
    .{ "var", .k_var },
    .{ "vec2", .k_vec2 },
    .{ "vec3", .k_vec3 },
    .{ "vec4", .k_vec4 },
    .{ "while", .k_while },
});
