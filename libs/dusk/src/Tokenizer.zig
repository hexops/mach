const std = @import("std");
const Token = @import("Token.zig");

const Tokenizer = @This();

source: [:0]const u8,
index: u32,

const State = enum {
    start,
    invalid,
    ident,
    underscore,
    number,
    block_comment,
    ampersand,
    bang,
    equal,
    greater,
    shift_right,
    less,
    shift_left,
    minus,
    mod,
    pipe,
    plus,
    slash,
    star,
    xor,
};

pub fn dump(self: *Tokenizer, token: Token) void {
    std.debug.print("\x1b[0;33m{s} \x1b[0;90m\"{s}\"\x1b[0m\n", .{ @tagName(token.tag), token.loc.slice(self.source) });
}

pub fn init(source: [:0]const u8) Tokenizer {
    // Skip the UTF-8 BOM if present
    const src_start: u32 = if (std.mem.startsWith(u8, source, "\xEF\xBB\xBF")) 3 else 0;
    return Tokenizer{
        .source = source[src_start..],
        .index = 0,
    };
}

pub fn peek(self: *Tokenizer) Token {
    var index = self.index;
    var state = State.start;
    var result = Token{
        .tag = .eof,
        .loc = .{
            .start = index,
            .end = undefined,
        },
    };

    while (true) : (index += 1) {
        const c = self.source[index];
        switch (state) {
            .start => switch (c) {
                0 => {
                    if (index != self.source.len) {
                        result.tag = .invalid;
                        result.loc.start = index;
                        index += 1;
                        result.loc.end = index;
                        return result;
                    }
                    break;
                },
                ' ', '\n', '\t', '\r' => result.loc.start = index + 1,
                'a'...'z', 'A'...'Z' => state = .ident,
                '0'...'9' => state = .number,

                '&' => state = .ampersand,
                '!' => state = .bang,
                '=' => state = .equal,
                '>' => state = .greater,
                '<' => state = .less,
                '-' => state = .minus,
                '%' => state = .mod,
                '|' => state = .pipe,
                '+' => state = .plus,
                '/' => state = .slash,
                '*' => state = .star,
                '_' => state = .underscore,
                '^' => state = .xor,

                '@' => {
                    result.tag = .attr;
                    index += 1;
                    break;
                },
                '[' => {
                    result.tag = .bracket_left;
                    index += 1;
                    break;
                },
                ']' => {
                    result.tag = .bracket_right;
                    index += 1;
                    break;
                },
                '{' => {
                    result.tag = .brace_left;
                    index += 1;
                    break;
                },
                '}' => {
                    result.tag = .brace_right;
                    index += 1;
                    break;
                },
                ':' => {
                    result.tag = .colon;
                    index += 1;
                    break;
                },
                ',' => {
                    result.tag = .comma;
                    index += 1;
                    break;
                },
                '(' => {
                    result.tag = .paren_left;
                    index += 1;
                    break;
                },
                ')' => {
                    result.tag = .paren_right;
                    index += 1;
                    break;
                },
                '.' => {
                    result.tag = .period;
                    index += 1;
                    break;
                },
                ';' => {
                    result.tag = .semicolon;
                    index += 1;
                    break;
                },
                '~' => {
                    result.tag = .tilde;
                    index += 1;
                    break;
                },

                else => {
                    state = .invalid;
                    result.tag = .invalid;
                },
            },
            .invalid => break,

            .ident => switch (c) {
                'a'...'z', 'A'...'Z', '0'...'9', '_' => {},
                else => {
                    result.tag = .ident;
                    if (Token.keywords.get(self.source[result.loc.start..index])) |tag| {
                        result.tag = tag;
                    }
                    break;
                },
            },
            .underscore => switch (c) { // TODO: two underscore `__` https://www.w3.org/TR/WGSL/#identifiers
                'a'...'z', 'A'...'Z', '_', '0'...'9' => state = .ident,
                else => {
                    result.tag = .underscore;
                    break;
                },
            },

            .number => switch (c) {
                '0'...'9', '.', 'i', 'u', 'f', 'h', 'e', '-', '+' => {},
                else => {
                    result.tag = .number;
                    break;
                },
            },

            .block_comment => switch (c) {
                0 => break,
                '\n' => {
                    state = .start;
                    result.loc.start = index + 1;
                },
                else => {},
            },

            .ampersand => switch (c) {
                '&' => {
                    result.tag = .and_and;
                    index += 1;
                    break;
                },
                '=' => {
                    result.tag = .and_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .@"and";
                    break;
                },
            },
            .bang => switch (c) {
                '=' => {
                    result.tag = .not_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .bang;
                    break;
                },
            },
            .equal => switch (c) {
                '=' => {
                    result.tag = .equal_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .equal;
                    break;
                },
            },
            .greater => switch (c) {
                '>' => state = .shift_right,
                '=' => {
                    result.tag = .greater_than_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .greater_than;
                    break;
                },
            },
            .shift_right => switch (c) {
                '=' => {
                    result.tag = .shift_right_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .shift_right;
                    break;
                },
            },
            .less => switch (c) {
                '<' => state = .shift_left,
                '=' => {
                    result.tag = .less_than_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .less_than;
                    break;
                },
            },
            .shift_left => switch (c) {
                '=' => {
                    result.tag = .shift_left_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .shift_left;
                    break;
                },
            },
            .minus => switch (c) {
                '-' => {
                    result.tag = .minus_minus;
                    index += 1;
                    break;
                },
                '=' => {
                    result.tag = .minus_equal;
                    index += 1;
                    break;
                },
                '>' => {
                    result.tag = .arrow;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .minus;
                    break;
                },
            },
            .mod => switch (c) {
                '=' => {
                    result.tag = .modulo_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .mod;
                    break;
                },
            },
            .pipe => switch (c) {
                '|' => {
                    result.tag = .or_or;
                    index += 1;
                    break;
                },
                '=' => {
                    result.tag = .or_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .@"or";
                    break;
                },
            },
            .plus => switch (c) {
                '+' => {
                    result.tag = .plus_plus;
                    index += 1;
                    break;
                },
                '=' => {
                    result.tag = .plus_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .plus;
                    break;
                },
            },
            .slash => switch (c) {
                '/' => state = .block_comment,
                '=' => {
                    result.tag = .division_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .division;
                    break;
                },
            },
            .star => switch (c) {
                '=' => {
                    result.tag = .times_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .star;
                    break;
                },
            },
            .xor => switch (c) {
                '=' => {
                    result.tag = .xor_equal;
                    index += 1;
                    break;
                },
                else => {
                    result.tag = .xor;
                    break;
                },
            },
        }
    }

    result.loc.end = index;
    return result;
}

pub fn next(self: *Tokenizer) Token {
    const tok = self.peek();
    self.index = tok.loc.end;
    return tok;
}

test "tokenize identifier and numbers" {
    comptime var str: [:0]const u8 =
        \\_ __ _iden iden 100.8i // cc
        \\// commnet
        \\
    ;
    var tokenizer = Tokenizer.init(str);
    try std.testing.expect(tokenizer.next().tag == .underscore);
    try std.testing.expect(tokenizer.next().tag == .ident);
    try std.testing.expect(tokenizer.next().tag == .ident);
    try std.testing.expect(tokenizer.next().tag == .ident);
    try std.testing.expect(tokenizer.next().tag == .number);
    try std.testing.expect(tokenizer.next().tag == .eof);
}

test "tokenize other" {
    comptime var str: [:0]const u8 = "";
    inline for (std.meta.fields(Token.Tag), 0..) |field, i| comptime {
        if (i > 3) {
            str = str ++ " " ++ (Token.Tag.symbol(@intToEnum(Token.Tag, field.value)));
        }
    };

    var tokenizer = Tokenizer.init(str);

    comptime var i = 4; // skip identifiers and nums
    inline while (i < std.meta.fields(Token.Tag).len) : (i += 1) {
        const tag = @intToEnum(Token.Tag, i);
        try std.testing.expect(tokenizer.next().tag == tag);
    }
    try std.testing.expect(tokenizer.next().tag == .eof);
}
