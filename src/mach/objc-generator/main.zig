const std = @import("std");
const reg = @import("registry.zig");

const Container = reg.Container;
const Enum = reg.Enum;
const EnumValue = reg.EnumValue;
const Method = reg.Method;
const Param = reg.Param;
const Property = reg.Property;
const Registry = reg.Registry;
const Type = reg.Type;
const TypeParam = reg.TypeParam;

var registry: Registry = undefined;

// ------------------------------------------------------------------------------------------------
pub const ParseError = error{ UnexpectedCharacter, UnexpectedToken };

pub const Token = struct {
    kind: Kind,
    text: []const u8,

    const Kind = enum {
        int,
        id,
        dot,
        comma,
        lparen,
        rparen,
        lbracket,
        rbracket,
        less,
        greater,
        caret,
        star,
        quote,
        kw_bool,
        kw_char,
        kw_class,
        kw_const,
        kw_double,
        kw_float,
        kw_id,
        kw_imp,
        kw_instancetype,
        kw_int,
        kw_int8_t,
        kw_int16_t,
        kw_int32_t,
        kw_int64_t,
        kw_kindof,
        kw_long,
        kw_nonnull,
        kw_nullable,
        kw_null_unspecified,
        kw_nullable_result,
        kw_short,
        kw_sel,
        kw_struct,
        kw_unsigned,
        kw_uint,
        kw_uint8_t,
        kw_uint16_t,
        kw_uint32_t,
        kw_uint64_t,
        kw_void,
        eof,
    };
};

fn isdigit(c: u8) bool {
    switch (c) {
        '0'...'9' => return true,
        else => return false,
    }
}

fn isalnum(c: u8) bool {
    switch (c) {
        'a'...'z', 'A'...'Z', '0'...'9' => return true,
        else => return false,
    }
}

pub const Lexer = struct {
    const Self = @This();

    source: []const u8,
    offset: usize = 0,

    pub fn next(self: *Self) !Token {
        while (true) {
            const start = self.offset;
            var c = self.peek();
            switch (c) {
                ' ', '\t', '\n', '\r' => {
                    self.skip();
                },
                '0'...'9' => {
                    self.skip();
                    c = self.peek();
                    while (isdigit(c)) {
                        self.skip();
                        c = self.peek();
                    }

                    return self.token(Token.Kind.int, start);
                },
                'a'...'z', 'A'...'Z', '_' => {
                    self.skip();
                    c = self.peek();
                    while (isalnum(c) or c == '_') {
                        self.skip();
                        c = self.peek();
                    }

                    const text = self.source[start..self.offset];
                    const kind = if (std.mem.eql(u8, text, "BOOL"))
                        Token.Kind.kw_bool
                    else if (std.mem.eql(u8, text, "char"))
                        Token.Kind.kw_char
                    else if (std.mem.eql(u8, text, "Class"))
                        Token.Kind.kw_class
                    else if (std.mem.eql(u8, text, "const"))
                        Token.Kind.kw_const
                    else if (std.mem.eql(u8, text, "double"))
                        Token.Kind.kw_double
                    else if (std.mem.eql(u8, text, "float"))
                        Token.Kind.kw_float
                    else if (std.mem.eql(u8, text, "id"))
                        Token.Kind.kw_id
                    else if (std.mem.eql(u8, text, "IMP"))
                        Token.Kind.kw_imp
                    else if (std.mem.eql(u8, text, "instancetype"))
                        Token.Kind.kw_instancetype
                    else if (std.mem.eql(u8, text, "int"))
                        Token.Kind.kw_int
                    else if (std.mem.eql(u8, text, "int8_t"))
                        Token.Kind.kw_int8_t
                    else if (std.mem.eql(u8, text, "int16_t"))
                        Token.Kind.kw_int16_t
                    else if (std.mem.eql(u8, text, "int32_t"))
                        Token.Kind.kw_int32_t
                    else if (std.mem.eql(u8, text, "int64_t"))
                        Token.Kind.kw_int64_t
                    else if (std.mem.eql(u8, text, "__kindof"))
                        Token.Kind.kw_kindof
                    else if (std.mem.eql(u8, text, "long"))
                        Token.Kind.kw_long
                    else if (std.mem.eql(u8, text, "_Nonnull"))
                        Token.Kind.kw_nonnull
                    else if (std.mem.eql(u8, text, "_Nullable"))
                        Token.Kind.kw_nullable
                    else if (std.mem.eql(u8, text, "_Null_unspecified"))
                        Token.Kind.kw_null_unspecified
                    else if (std.mem.eql(u8, text, "_Nullable_result"))
                        Token.Kind.kw_nullable_result
                    else if (std.mem.eql(u8, text, "SEL"))
                        Token.Kind.kw_sel
                    else if (std.mem.eql(u8, text, "short"))
                        Token.Kind.kw_short
                    else if (std.mem.eql(u8, text, "struct"))
                        Token.Kind.kw_struct
                    else if (std.mem.eql(u8, text, "uint8_t"))
                        Token.Kind.kw_uint8_t
                    else if (std.mem.eql(u8, text, "uint16_t"))
                        Token.Kind.kw_uint16_t
                    else if (std.mem.eql(u8, text, "uint32_t"))
                        Token.Kind.kw_uint32_t
                    else if (std.mem.eql(u8, text, "uint64_t"))
                        Token.Kind.kw_uint64_t
                    else if (std.mem.eql(u8, text, "unsigned"))
                        Token.Kind.kw_unsigned
                    else if (std.mem.eql(u8, text, "void"))
                        Token.Kind.kw_void
                    else
                        Token.Kind.id;

                    return self.token(kind, start);
                },
                '(' => {
                    self.skip();
                    return self.token(Token.Kind.lparen, start);
                },
                ')' => {
                    self.skip();
                    return self.token(Token.Kind.rparen, start);
                },
                '[' => {
                    self.skip();
                    return self.token(Token.Kind.lbracket, start);
                },
                ']' => {
                    self.skip();
                    return self.token(Token.Kind.rbracket, start);
                },
                '<' => {
                    self.skip();
                    return self.token(Token.Kind.less, start);
                },
                '>' => {
                    self.skip();
                    return self.token(Token.Kind.greater, start);
                },
                '^' => {
                    self.skip();
                    return self.token(Token.Kind.caret, start);
                },
                '*' => {
                    self.skip();
                    return self.token(Token.Kind.star, start);
                },
                '"' => {
                    self.skip();
                    return self.token(Token.Kind.quote, start);
                },
                ',' => {
                    self.skip();
                    return self.token(Token.Kind.comma, start);
                },
                '.' => {
                    self.skip();
                    return self.token(Token.Kind.dot, start);
                },
                0 => {
                    return self.token(Token.Kind.eof, start);
                },
                else => {
                    std.debug.print("Unexpected character {c} {}\n", .{ c, c });
                    std.debug.print("Parsing {s}\n", .{self.source});
                    return error.UnexpectedCharacter;
                },
            }
        }
    }

    fn skip(self: *Self) void {
        self.offset += 1;
    }

    fn peek(self: *Self) u8 {
        if (self.offset < self.source.len) {
            return self.source[self.offset];
        } else {
            return 0;
        }
    }

    fn token(self: *Self, kind: Token.Kind, start: usize) Token {
        return Token{ .kind = kind, .text = self.source[start..self.offset] };
    }
};

pub const Parser = struct {
    const Self = @This();
    const PointerProps = struct { is_const: bool, is_optional: bool };

    allocator: std.mem.Allocator,
    lookahead: Token,
    lexer: *Lexer,

    pub fn init(allocator: std.mem.Allocator, lexer: *Lexer) !Parser {
        return Parser{ .allocator = allocator, .lookahead = try lexer.next(), .lexer = lexer };
    }

    pub fn parseType(self: *Self) !Type {
        if (self.lookahead.kind == .id) {
            const text = self.lookahead.text;
            if (std.mem.eql(u8, text, "API_AVAILABLE")) {
                try self.match(.id);
                try self.skipParenContent();
            } else if (std.mem.eql(u8, text, "API_UNAVAILABLE")) {
                try self.match(.id);
                try self.skipParenContent();
            } else if (std.mem.eql(u8, text, "API_DEPRECATED_WITH_REPLACEMENT")) {
                try self.match(.id);
                try self.skipParenContent();
            } else if (std.mem.eql(u8, text, "NS_SWIFT_UNAVAILABLE")) {
                try self.match(.id);
                try self.skipParenContent();
            } else if (std.mem.eql(u8, text, "NS_SWIFT_UNAVAILABLE_FROM_ASYNC")) {
                try self.match(.id);
                try self.skipParenContent();
            }
        }
        const is_const = self.lookahead.kind == .kw_const;
        if (is_const)
            try self.match(.kw_const);

        // TODO - what does this mean?
        if (self.lookahead.kind == .kw_kindof)
            try self.match(.kw_kindof);

        switch (self.lookahead.kind) {
            .kw_void => {
                try self.match(.kw_void);
                return self.parseTypeSuffix(.{ .void = {} }, is_const, false);
            },
            .kw_bool => {
                try self.match(.kw_bool);
                return self.parseTypeSuffix(.{ .bool = {} }, is_const, false);
            },
            .kw_char => {
                try self.match(.kw_char);
                return self.parseTypeSuffix(.{ .uint = 8 }, is_const, false);
            },
            .kw_short => {
                try self.match(.kw_short);
                return self.parseTypeSuffix(.{ .c_short = {} }, is_const, false);
            },
            .kw_int => {
                try self.match(.kw_int);
                return self.parseTypeSuffix(.{ .c_int = {} }, is_const, false);
            },
            .kw_long => {
                try self.match(.kw_long);
                if (self.lookahead.kind == .kw_long) {
                    try self.match(.kw_long);
                    return self.parseTypeSuffix(.{ .c_longlong = {} }, is_const, false);
                } else {
                    return self.parseTypeSuffix(.{ .c_long = {} }, is_const, false);
                }
            },
            .kw_unsigned => {
                try self.match(.kw_unsigned);
                switch (self.lookahead.kind) {
                    .kw_char => {
                        try self.match(.kw_char);
                        return self.parseTypeSuffix(.{ .uint = 8 }, is_const, false);
                    },
                    .kw_short => {
                        try self.match(.kw_short);
                        return self.parseTypeSuffix(.{ .c_ushort = {} }, is_const, false);
                    },
                    .kw_int => {
                        try self.match(.kw_int);
                        return self.parseTypeSuffix(.{ .c_uint = {} }, is_const, false);
                    },
                    .kw_long => {
                        try self.match(.kw_long);
                        if (self.lookahead.kind == .kw_long) {
                            try self.match(.kw_long);
                            return self.parseTypeSuffix(.{ .c_ulonglong = {} }, is_const, false);
                        } else {
                            return self.parseTypeSuffix(.{ .c_ulong = {} }, is_const, false);
                        }
                    },
                    else => {
                        return self.parseTypeSuffix(.{ .c_uint = {} }, is_const, false);
                    },
                }
            },
            .kw_int8_t => {
                try self.match(.kw_int8_t);
                return self.parseTypeSuffix(.{ .int = 8 }, is_const, false);
            },
            .kw_int16_t => {
                try self.match(.kw_int16_t);
                return self.parseTypeSuffix(.{ .int = 16 }, is_const, false);
            },
            .kw_int32_t => {
                try self.match(.kw_int32_t);
                return self.parseTypeSuffix(.{ .int = 32 }, is_const, false);
            },
            .kw_int64_t => {
                try self.match(.kw_int64_t);
                return self.parseTypeSuffix(.{ .int = 64 }, is_const, false);
            },
            .kw_uint => {
                try self.match(.kw_uint);
                return self.parseTypeSuffix(.{ .uint = 32 }, is_const, false);
            },
            .kw_uint8_t => {
                try self.match(.kw_uint8_t);
                return self.parseTypeSuffix(.{ .uint = 8 }, is_const, false);
            },
            .kw_uint16_t => {
                try self.match(.kw_uint16_t);
                return self.parseTypeSuffix(.{ .uint = 16 }, is_const, false);
            },
            .kw_uint32_t => {
                try self.match(.kw_uint32_t);
                return self.parseTypeSuffix(.{ .uint = 32 }, is_const, false);
            },
            .kw_uint64_t => {
                try self.match(.kw_uint64_t);
                return self.parseTypeSuffix(.{ .uint = 64 }, is_const, false);
            },
            .kw_float => {
                try self.match(.kw_float);
                return self.parseTypeSuffix(.{ .float = 32 }, is_const, false);
            },
            .kw_double => {
                try self.match(.kw_double);
                return self.parseTypeSuffix(.{ .float = 64 }, is_const, false);
            },
            .kw_class => {
                try self.match(.kw_class);
                const props = try self.parsePointerProps(is_const);

                const t = Type{ .name = "c.objc_class" };

                const child = try self.allocator.create(Type);
                child.* = t;

                return Type{ .pointer = .{
                    .is_single = true,
                    .is_const = props.is_const,
                    .is_optional = props.is_optional,
                    .child = child,
                } };
            },
            .kw_sel => {
                try self.match(.kw_sel);
                const t = Type{ .name = "c.objc_selector" };
                const child = try self.allocator.create(Type);
                child.* = t;

                return Type{ .pointer = .{ .is_single = true, .is_const = is_const, .is_optional = false, .child = child } };
            },
            .kw_id => {
                try self.match(.kw_id);

                if (self.lookahead.kind == .less) {
                    try self.match(.less);
                    const types = try self.parseTypeList();
                    try self.match(.greater);

                    // TODO - how should handle multiple types?

                    return self.parsePointerSuffix(types.items[0], is_const, true);
                } else {
                    const t = Type{ .name = "c.objc_object" };
                    return self.parsePointerSuffix(t, is_const, true);
                }
            },
            .kw_imp => {
                try self.match(.kw_imp);

                //void (*)(void)
                const return_type = try self.allocator.create(Type);
                return_type.* = .{ .void = {} };

                const ty = .{
                    .function = .{
                        .return_type = return_type,
                        .params = std.ArrayList(Type).init(self.allocator),
                    },
                };

                return self.parseTypeSuffix(ty, is_const, true);
            },
            .kw_instancetype => {
                try self.match(.kw_instancetype);

                const child = try self.allocator.create(Type);
                child.* = .{ .instance_type = {} };

                return Type{ .pointer = .{ .is_single = true, .is_const = is_const, .is_optional = false, .child = child } };
            },
            .kw_struct => {
                try self.match(.kw_struct);
                const name = self.lookahead.text;
                try self.match(.id);
                return self.parseTypeSuffix(.{ .name = name }, is_const, false);
            },
            else => {
                const text = self.lookahead.text;
                try self.match(.id);
                return self.parseTypeSuffix(.{ .name = text }, is_const, false);
            },
        }
    }

    fn parseTypeList(self: *Self) (ParseError || error{OutOfMemory})!std.ArrayList(Type) {
        var types = std.ArrayList(Type).init(self.allocator);

        try types.append(try self.parseType());
        while (self.lookahead.kind == .comma) {
            try self.match(.comma);
            try types.append(try self.parseType());
        }

        return types;
    }

    fn parseTypeSuffix(self: *Self, base_type: Type, is_const: bool, is_single: bool) !Type {
        if (self.lookahead.kind == .star) {
            try self.match(.star);

            return self.parsePointerSuffix(base_type, is_const, is_single);
        } else if (self.lookahead.kind == .lbracket) {
            // TODO - handle arrays
            try self.match(.lbracket);
            if (self.lookahead.kind == .int)
                try self.match(.int);
            try self.match(.rbracket);

            return self.parsePointerSuffix(base_type, is_const, is_single);
        } else if (self.lookahead.kind == .lparen) {
            try self.match(.lparen);

            if (self.lookahead.kind == .star) {
                try self.match(.star);

                const props = try self.parsePointerProps(is_const);
                _ = props;

                try self.match(.rparen);
                try self.match(.lparen);
                _ = try self.parseTypeList();
                try self.match(.rparen);
            } else if (self.lookahead.kind == .caret) {
                try self.match(.caret);

                const props = try self.parsePointerProps(is_const);
                _ = props;

                try self.match(.rparen);
                try self.match(.lparen);
                const params = try self.parseTypeList();
                try self.match(.rparen);

                const return_type = try self.allocator.create(Type);
                return_type.* = base_type;

                return .{
                    .function = .{
                        .return_type = return_type,
                        .params = params,
                    },
                };
            } else {
                _ = try self.parseTypeList();
                try self.match(.rparen);
            }

            return base_type;
        } else if (self.lookahead.kind == .less) {
            try self.match(.less);
            const types = try self.parseTypeList();
            try self.match(.greater);

            const child = try self.allocator.create(Type);
            child.* = base_type;

            return self.parseTypeSuffix(.{ .generic = .{ .base_type = child, .args = types } }, is_const, true);
        } else {
            const props = try self.parsePointerProps(false);
            _ = props;

            return base_type;
        }
    }

    fn parsePointerProps(self: *Self, elem_is_const: bool) !PointerProps {
        var is_const = elem_is_const;
        var is_optional = false;
        while (true) {
            if (self.lookahead.kind == .kw_const) {
                try self.match(.kw_const);
                is_const = true;
            } else if (self.lookahead.kind == .kw_nullable) {
                try self.match(.kw_nullable);
                is_optional = true;
            } else if (self.lookahead.kind == .kw_nonnull) {
                try self.match(.kw_nonnull);
            } else if (self.lookahead.kind == .kw_null_unspecified) {
                try self.match(.kw_null_unspecified);
            } else if (self.lookahead.kind == .kw_nullable_result) {
                try self.match(.kw_nullable_result);
            } else break;
        }

        return .{ .is_const = is_const, .is_optional = is_optional };
    }

    fn parsePointerSuffix(self: *Self, base_type: Type, is_const: bool, is_single: bool) error{
        OutOfMemory,
        UnexpectedToken,
        UnexpectedCharacter,
    }!Type {
        const props = try self.parsePointerProps(is_const);
        const child = try self.allocator.create(Type);
        child.* = base_type;

        const t = Type{ .pointer = .{
            .is_single = is_single,
            .is_const = props.is_const,
            .is_optional = props.is_optional,
            .child = child,
        } };
        return self.parseTypeSuffix(t, false, is_single);
    }

    fn skipParenContent(self: *Self) !void {
        var nestLevel: u32 = 0;
        while (true) {
            if (self.lookahead.kind == .lparen) {
                try self.match(.lparen);
                nestLevel = nestLevel + 1;
            } else if (self.lookahead.kind == .rparen) {
                try self.match(.rparen);
                nestLevel = nestLevel - 1;
            } else {
                self.lookahead = try self.lexer.next();
            }
            if (nestLevel == 0)
                break;
        }
    }

    fn match(self: *Self, k: Token.Kind) !void {
        if (self.lookahead.kind == k) {
            self.lookahead = try self.lexer.next();
        } else {
            std.debug.print("Expected {any} but found {any}\n", .{ k, self.lookahead.kind });
            return error.UnexpectedToken;
        }
    }
};

// ------------------------------------------------------------------------------------------------

pub fn getObject(x: std.json.Value, key: []const u8) ?std.json.Value {
    switch (x) {
        .object => |o| {
            if (o.get(key)) |v| {
                switch (v) {
                    .object => return v,
                    else => return null,
                }
            } else {
                return null;
            }
        },
        else => return null,
    }
}

pub fn getArray(x: std.json.Value, key: []const u8) []std.json.Value {
    switch (x) {
        .object => |o| {
            if (o.get(key)) |v| {
                switch (v) {
                    .array => |a| {
                        return a.items;
                    },
                    else => return &[_]std.json.Value{},
                }
            } else {
                return &[_]std.json.Value{};
            }
        },
        else => return &[_]std.json.Value{},
    }
}

pub fn getString(x: std.json.Value, key: []const u8) []const u8 {
    switch (x) {
        .object => |o| {
            if (o.get(key)) |v| {
                switch (v) {
                    .string => |s| {
                        return s;
                    },
                    else => return "",
                }
            } else {
                return "";
            }
        },
        else => return "",
    }
}

pub fn getBool(x: std.json.Value, key: []const u8) bool {
    switch (x) {
        .object => |o| {
            if (o.get(key)) |v| {
                switch (v) {
                    .bool => |b| {
                        return b;
                    },
                    else => return false,
                }
            } else {
                return false;
            }
        },
        else => return false,
    }
}

pub const Converter = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: std.mem.Allocator) Converter {
        return Converter{ .allocator = allocator, .arena = std.heap.ArenaAllocator.init(allocator) };
    }

    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    pub fn convert(self: *Self, n: std.json.Value) !void {
        const kind = getString(n, "kind");
        if (std.mem.eql(u8, kind, "TranslationUnitDecl")) {
            try self.convertTranslationUnitDecl(n);
        }
    }

    fn convertTranslationUnitDecl(self: *Self, n: std.json.Value) !void {
        for (getArray(n, "inner")) |child| {
            const childKind = getString(child, "kind");
            if (std.mem.eql(u8, childKind, "EnumDecl")) {
                try self.convertEnumDecl(child);
            } else if (std.mem.eql(u8, childKind, "FunctionDecl")) {
                self.convertFunctionDecl(child);
            } else if (std.mem.eql(u8, childKind, "ObjCCategoryDecl")) {
                try self.convertObjCCategoryDecl(child);
            } else if (std.mem.eql(u8, childKind, "ObjCInterfaceDecl")) {
                try self.convertObjCInterfaceDecl(child);
            } else if (std.mem.eql(u8, childKind, "ObjCProtocolDecl")) {
                try self.convertObjcProtocolDecl(child);
            } else if (std.mem.eql(u8, childKind, "RecordDecl")) {
                self.convertRecordDecl(child);
            } else if (std.mem.eql(u8, childKind, "TypedefDecl")) {
                try self.convertTypedefDecl(child);
            } else if (std.mem.eql(u8, childKind, "VarDecl")) {
                self.convertVarDecl(child);
            }
        }
    }

    fn convertEnumDecl(self: *Self, n: std.json.Value) !void {
        var name = getString(n, "name");
        if (name.len == 0) {
            return;
        }

        var e = try registry.getEnum(name);
        if (getObject(n, "fixedUnderlyingType")) |ty| {
            e.ty = try self.convertType(ty);
        } else {
            e.ty = .{ .int = 32 };
        }

        for (getArray(n, "inner")) |child| {
            const childKind = getString(child, "kind");
            if (std.mem.eql(u8, childKind, "EnumConstantDecl")) {
                var v = try self.convertEnumConstantDecl(child);
                try e.values.append(v);
            }
        }
    }

    fn convertEnumConstantDecl(self: *Self, n: std.json.Value) !EnumValue {
        var value: i64 = 0;
        for (getArray(n, "inner")) |child| {
            const childKind = getString(child, "kind");
            if (std.mem.eql(u8, childKind, "ConstantExpr")) {
                value = self.convertConstantExpr(child);
            } else if (std.mem.eql(u8, childKind, "ImplicitCastExpr")) {
                value = self.convertImplicitCastExpr(child);
            }
        }

        return .{ .name = getString(n, "name"), .value = value };
    }

    fn convertConstantExpr(_: *Self, n: std.json.Value) i64 {
        var value = getString(n, "value");
        return std.fmt.parseInt(i64, value, 10) catch 0;
    }

    fn convertImplicitCastExpr(self: *Self, n: std.json.Value) i64 {
        for (getArray(n, "inner")) |child| {
            const childKind = getString(child, "kind");
            if (std.mem.eql(u8, childKind, "ConstantExpr")) {
                return self.convertConstantExpr(child);
            }
        }

        return 0;
    }

    fn convertFunctionDecl(self: *Self, n: std.json.Value) void {
        _ = self;
        _ = n;
    }

    fn convertObjCCategoryDecl(self: *Self, n: std.json.Value) !void {
        var interfaceDecl = getObject(n, "interface").?;
        var container = try registry.getInterface(getString(interfaceDecl, "name"));
        try self.convertContainer(container, n);
    }

    fn convertObjCInterfaceDecl(self: *Self, n: std.json.Value) !void {
        var container = try registry.getInterface(getString(n, "name"));
        if (getObject(n, "super")) |super| {
            const superName = getString(super, "name");
            if (superName.len > 0) {
                container.super = try registry.getInterface(superName);
            }
        }

        try self.convertContainer(container, n);
    }

    fn convertObjcProtocolDecl(self: *Self, n: std.json.Value) !void {
        var container = try registry.getProtocol(getString(n, "name"));
        if (getObject(n, "super")) |super| {
            const superName = getString(super, "name");
            if (superName.len > 0) {
                container.super = try registry.getProtocol(superName);
            }
        }

        try self.convertContainer(container, n);
    }

    fn convertRecordDecl(self: *Self, n: std.json.Value) void {
        _ = self;
        _ = n;
    }

    fn convertTypedefDecl(self: *Self, n: std.json.Value) !void {
        const name = getString(n, "name");
        const ty = try self.convertType(getObject(n, "type").?);
        try registry.typedefs.put(name, ty);
    }

    fn convertVarDecl(self: *Self, n: std.json.Value) void {
        _ = self;
        _ = n;
    }

    fn convertContainer(self: *Self, container: *Container, n: std.json.Value) !void {
        // TODO - better solution for this?
        container.type_params.clearAndFree();
        container.protocols.clearAndFree();

        for (getArray(n, "protocols")) |protocolJson| {
            const protocolName = getString(protocolJson, "name");
            var protocol = try registry.getProtocol(protocolName);
            try container.protocols.append(protocol);
        }

        for (getArray(n, "inner")) |child| {
            const childKind = getString(child, "kind");
            if (std.mem.eql(u8, childKind, "ObjCTypeParamDecl")) {
                var type_param = try self.convertTypeParam(child);
                try container.type_params.append(type_param);
            } else if (std.mem.eql(u8, childKind, "ObjCPropertyDecl")) {
                var property = try self.convertProperty(child);
                try container.properties.append(property);
            } else if (std.mem.eql(u8, childKind, "ObjCMethodDecl")) {
                var method = try self.convertMethod(child);
                try container.methods.append(method);
            }
        }
    }

    fn convertTypeParam(self: *Self, n: std.json.Value) !TypeParam {
        _ = self;
        return TypeParam.init(getString(n, "name"));
    }

    fn convertProperty(self: *Self, n: std.json.Value) !Property {
        var ty = try self.convertType(getObject(n, "type").?);
        return Property.init(getString(n, "name"), ty);
    }

    fn convertMethod(self: *Self, n: std.json.Value) !Method {
        var return_type = try self.convertType(getObject(n, "returnType").?);
        var params = std.ArrayList(Param).init(registry.allocator);

        for (getArray(n, "inner")) |child| {
            const childKind = getString(child, "kind");
            if (std.mem.eql(u8, childKind, "ParmVarDecl")) {
                var param = try self.convertParam(child);
                try params.append(param);
            }
        }

        return Method.init(getString(n, "name"), getBool(n, "instance"), return_type, params);
    }

    fn convertParam(self: *Self, n: std.json.Value) !Param {
        const ty = try self.convertType(getObject(n, "type").?);
        return Param.init(getString(n, "name"), ty);
    }

    fn convertType(self: *Self, t: std.json.Value) !Type {
        //std.debug.print("convertType: {s}\n", .{t.qualType});
        var lexer = Lexer{ .source = getString(t, "qualType") };
        var parser = try Parser.init(self.arena.allocator(), &lexer);
        return parser.parseType();
    }
};

// ------------------------------------------------------------------------------------------------

const prefixes = [_][]const u8{ "CA", "CF", "CG", "MTK", "MTL", "NS" };

pub fn getNamespace(id: []const u8) []const u8 {
    for (prefixes) |prefix| {
        if (std.mem.startsWith(u8, id, prefix)) {
            return prefix;
        }
    }

    return &[_]u8{};
}

pub fn trimNamespace(id: []const u8) []const u8 {
    for (prefixes) |prefix| {
        if (std.mem.startsWith(u8, id, prefix)) {
            return id[prefix.len..];
        }
    }

    return id;
}

pub fn trimTrailingColon(id: []const u8) []const u8 {
    if (id.len == 0) {
        return id;
    } else if (id[id.len - 1] == ':') {
        return id[0 .. id.len - 1];
    } else {
        return id;
    }
}

fn isKeyword(id: []const u8) bool {
    if (std.mem.eql(u8, id, "error")) {
        return true;
    } else if (std.mem.eql(u8, id, "opaque")) {
        return true;
    } else if (std.mem.eql(u8, id, "type")) {
        return true;
    } else {
        return false;
    }
}

fn Generator(comptime WriterType: type) type {
    return struct {
        const Self = @This();
        const WriteError = WriterType.Error;
        const EnumList = std.ArrayList(*reg.Enum);
        const ContainerList = std.ArrayList(*reg.Container);
        const SelectorHashSet = std.StringHashMap(void);

        allocator: std.mem.Allocator,
        writer: WriterType,
        enums: EnumList,
        containers: ContainerList,
        selectors: SelectorHashSet,

        fn init(allocator: std.mem.Allocator, writer: WriterType) Self {
            return Self{
                .allocator = allocator,
                .writer = writer,
                .enums = EnumList.init(allocator),
                .containers = ContainerList.init(allocator),
                .selectors = SelectorHashSet.init(allocator),
            };
        }

        fn deinit(self: *Self) void {
            self.enums.deinit();
            self.containers.deinit();
            self.selectors.deinit();
        }

        pub fn addProtocol(self: *Self, name: []const u8) !void {
            var container = registry.protocols.get(name) orelse {
                std.debug.print("Protocol {s} not found\n", .{name});
                return;
            };

            try self.addContainer(container);
        }

        pub fn addInterface(self: *Self, name: []const u8) !void {
            var container = registry.interfaces.get(name) orelse {
                std.debug.print("Interface {s} not found\n", .{name});
                return;
            };

            try self.addContainer(container);
        }

        pub fn addEnum(self: *Self, name: []const u8) !void {
            var e = registry.enums.get(name) orelse {
                std.debug.print("Enum {s} not found\n", .{name});
                return;
            };

            try self.enums.append(e);
        }

        fn addContainer(self: *Self, container: *Container) !void {
            try self.containers.append(container);

            for (container.methods.items) |method| {
                try self.selectors.put(method.name, {});
            }
        }

        pub fn generate(self: *Self) !void {
            try self.generateEnumerations();
            try self.generateContainers();
            try self.generateClasses();
            try self.generateSelectors();
            try self.generateInit();
        }

        fn generateClasses(self: *Self) !void {
            for (self.containers.items) |container| {
                if (container.is_interface) {
                    try self.writer.print("var class_", .{});
                    try self.generateContainerName(container);
                    try self.writer.print(": *c.objc_class = undefined;\n", .{});
                }
            }
        }

        fn generateSelectors(self: *Self) !void {
            var it = self.selectors.iterator();
            while (it.next()) |entry| {
                const method_name = entry.key_ptr.*;
                try self.writer.print("var sel_", .{});
                try self.generateSelectorName(method_name);
                try self.writer.print(": *c.objc_selector = undefined;\n", .{});
            }
            try self.writer.print("\n", .{});
        }

        fn generateInit(self: *Self) !void {
            try self.writer.print("pub fn init() void {{\n", .{});
            try self.generateInitClasses();
            try self.writer.print("\n", .{});
            try self.generateInitSelectors();
            try self.writer.print("}}\n", .{});
        }

        fn generateInitClasses(self: *Self) !void {
            for (self.containers.items) |container| {
                if (container.is_interface) {
                    try self.writer.print("    class_", .{});
                    try self.generateContainerName(container);
                    try self.writer.print(" = c.objc_getClass(\"{s}\").?;\n", .{container.name});
                }
            }
        }

        fn generateInitSelectors(self: *Self) !void {
            var it = self.selectors.iterator();
            while (it.next()) |entry| {
                const method_name = entry.key_ptr.*;
                try self.writer.print("    sel_", .{});
                try self.generateSelectorName(method_name);
                try self.writer.print(" = c.sel_registerName(\"{s}\").?;\n", .{method_name});
            }
        }

        fn generateEnumerations(self: *Self) !void {
            for (self.enums.items) |e| {
                try self.writer.writeAll("\n");
                try self.writer.print("pub const ", .{});
                try self.generateTypeName(e.name);
                try self.writer.print(" = ", .{});
                try self.generateType(e.ty);
                try self.writer.print(";\n", .{});

                for (e.values.items) |v| {
                    try self.writer.print("pub const ", .{});
                    try self.generateTypeName(v.name);
                    try self.writer.print(": ", .{});
                    try self.generateTypeName(e.name);
                    try self.writer.print(" = {d};\n", .{v.value});
                }
            }
        }

        fn generateContainers(self: *Self) !void {
            for (self.containers.items) |container| {
                try self.generateContainer(container);
            }
        }

        fn generateContainer(self: *Self, container: *Container) !void {
            try self.writer.writeAll("\n");
            if (container.type_params.items.len > 0) {
                try self.writer.print("pub fn ", .{});
                try self.generateContainerName(container);
                try self.writer.print("(", .{});
                var first = true;
                for (container.type_params.items) |type_param| {
                    if (!first)
                        try self.writer.writeAll(", ");
                    first = false;
                    try self.writer.print("comptime {s}: type", .{type_param.name});
                }
                try self.writer.print(") type {{ return opaque {{\n", .{});
            } else {
                try self.writer.print("pub const ", .{});
                try self.generateContainerName(container);
                try self.writer.print(" = opaque {{\n", .{});
            }
            if (container.super) |super| {
                _ = super;
                // try self.writer.print("    pub const Super = ", .{});
                // try self.generateContainerName(super);
                // try self.writer.print(";\n", .{});
            }
            if (container.protocols.items.len > 0) {
                // try self.writer.print("    pub const ConformsTo = &[_]type{{ ", .{});
                // var first = true;
                // for (container.protocols.items) |protocol| {
                //     if (!first)
                //         try self.writer.writeAll(", ");
                //     first = false;
                //     try self.generateContainerName(protocol);
                // }
                // try self.writer.print(" }};\n", .{});
            }
            if (container.is_interface) {
                try self.writer.print("    pub fn class() *c.objc_class {{ return class_", .{});
                try self.generateContainerName(container);
                try self.writer.print("; }}\n", .{});
            }
            try self.writer.print("    pub usingnamespace Methods(", .{});
            try self.generateContainerName(container);
            try self.writer.print(");\n", .{});
            try self.writer.print("\n", .{});
            try self.writer.print("    pub fn Methods(comptime T: type) type {{\n", .{});
            try self.writer.print("        return struct {{\n", .{});

            var hasParent = false;
            if (container.super) |super| {
                try self.writer.print("            pub usingnamespace ", .{});
                try self.generateContainerName(super);
                try self.writer.print(".Methods(T);\n", .{});
                hasParent = true;
            }

            for (container.protocols.items) |protocol| {
                try self.writer.print("            pub usingnamespace ", .{});
                try self.generateContainerName(protocol);
                try self.writer.print(".Methods(T);\n", .{});
                hasParent = true;
            }

            if (hasParent) {
                try self.writer.print("\n", .{});
            }

            for (container.methods.items) |method| {
                try self.generateMethod(container, method);
            }

            try self.writer.print("        }};\n", .{});
            try self.writer.print("    }}\n", .{});
            try self.writer.print("}};\n", .{});
            if (container.type_params.items.len > 0) {
                try self.writer.print("}}\n", .{});
            }
        }

        fn generateMethod(self: *Self, container: *Container, method: Method) !void {
            if (container.super) |super| {
                if (self.doesParentHaveMethod(super, method.name))
                    return;
            }

            try self.writer.writeAll("            pub fn ");
            try self.generateMethodName(method.name);
            try self.writer.print("(", .{});
            try self.generateMethodParams(method);
            try self.writer.print(") ", .{});
            try self.generateType(method.return_type);
            try self.writer.print(" {{\n", .{});
            try self.generateBlockHelpers(method);
            try self.writer.writeAll("                return @as(");
            try self.generateObjcSignature(method);
            try self.writer.writeAll(", @ptrCast(&c.objc_msgSend))(");
            try self.generateMethodArgs(method);
            try self.writer.print(");\n", .{});
            try self.writer.print("            }}\n", .{});
        }

        fn doesParentHaveMethod(self: *Self, container: *Container, name: []const u8) bool {
            if (container.super) |super| {
                if (self.doesParentHaveMethod(super, name))
                    return true;
            }

            for (container.methods.items) |method| {
                if (std.mem.eql(u8, method.name, name))
                    return true;
            }

            return false;
        }

        fn generateMethodName(self: *Self, name: []const u8) !void {
            if (isKeyword(name)) {
                try self.writer.print("@\"{s}\"", .{name});
            } else {
                try self.generateSelectorName(trimTrailingColon(name));
            }
        }

        fn generateMethodParams(self: *Self, method: Method) !void {
            var first = true;
            if (method.instance) {
                try self.writer.print("self_: *T", .{});
                first = false;
            }
            for (method.params.items) |param| {
                if (!first)
                    try self.writer.writeAll(", ");
                first = false;
                try self.generateMethodParam(param);
            }
        }

        fn generateMethodParam(self: *Self, param: Param) !void {
            if (getBlockType(param)) |f| {
                try self.writer.writeAll("context: anytype, comptime ");
                try self.writer.print("{s}_: ", .{param.name});
                try self.writer.writeAll("fn (ctx: @TypeOf(context)");
                for (f.params.items) |param_ty| {
                    try self.writer.writeAll(", _: ");
                    try self.generateType(param_ty);
                }
                try self.writer.writeAll(") ");
                try self.generateType(f.return_type.*);
            } else {
                try self.writer.print("{s}_: ", .{param.name});
                try self.generateType(param.ty);
            }
        }

        fn generateBlockHelpers(self: *Self, method: Method) !void {
            for (method.params.items) |param| {
                if (getBlockType(param)) |f| {
                    try self.writer.writeAll("                const Literal = ns.BlockLiteral(@TypeOf(context));\n");
                    try self.writer.writeAll("                const Helper = struct {\n");
                    try self.writer.writeAll("                    pub fn cCallback(literal: *Literal");
                    for (f.params.items, 0..) |param_ty, i| {
                        try self.writer.print(", a{d}: ", .{i});
                        try self.generateType(param_ty);
                    }
                    try self.writer.writeAll(") callconv(.C) void {\n");
                    try self.writer.print("                        {s}_(literal.context", .{param.name});
                    for (0..f.params.items.len) |i| {
                        try self.writer.print(", a{d}", .{i});
                    }
                    try self.writer.writeAll(");\n");
                    try self.writer.writeAll("                    }\n");
                    try self.writer.writeAll("                };\n");
                    try self.writer.writeAll("                const descriptor = ns.BlockDescriptor{ .reserved = 0, .size = @sizeOf(Literal) };\n");
                    try self.writer.writeAll("                const block = Literal{ .isa = _NSConcreteStackBlock, .flags = 0, .reserved = 0, .invoke = @ptrCast(&Helper.cCallback), .descriptor = &descriptor, .context = context };\n");
                }
            }
        }

        fn generateObjcSignature(self: *Self, method: Method) !void {
            try self.writer.writeAll("*const fn (");
            if (method.instance) {
                try self.writer.writeAll("*T");
            } else {
                try self.writer.writeAll("*c.objc_class");
            }
            try self.writer.writeAll(", *c.objc_selector");
            for (method.params.items) |param| {
                try self.writer.writeAll(", ");
                if (getBlockType(param)) |_| {
                    try self.writer.writeAll("*const anyopaque");
                } else {
                    try self.generateType(param.ty);
                }
            }
            try self.writer.writeAll(") callconv(.C) ");
            try self.generateType(method.return_type);
        }

        fn generateMethodArgs(self: *Self, method: Method) !void {
            if (method.instance) {
                try self.writer.print("self_", .{});
            } else {
                try self.writer.print("T.class()", .{});
            }
            try self.writer.print(", sel_", .{});
            try self.generateSelectorName(method.name);

            for (method.params.items) |param| {
                try self.writer.writeAll(", ");
                if (getBlockType(param)) |_| {
                    try self.writer.writeAll("@ptrCast(&block)");
                } else {
                    try self.writer.print("{s}_", .{param.name});
                }
            }
        }

        fn getBlockType(param: Param) ?Type.Function {
            switch (param.ty) {
                .name => |s| {
                    if (registry.typedefs.get(s)) |t| {
                        return switch (t) {
                            .function => |f| f,
                            else => null,
                        };
                    }
                },
                .function => |f| return f,
                else => return null,
            }
            return null;
        }

        fn generateSelectorName(self: *Self, name: []const u8) !void {
            for (name) |ch| {
                if (ch == ':') {
                    try self.writer.writeByte('_');
                } else {
                    try self.writer.writeByte(ch);
                }
            }
        }

        fn generateType(self: *Self, ty: Type) WriteError!void {
            switch (ty) {
                .void => {
                    try self.writer.writeAll("void");
                },
                .bool => {
                    try self.writer.writeAll("bool");
                },
                .int => |bits| {
                    try self.writer.print("i{d}", .{bits});
                },
                .uint => |bits| {
                    try self.writer.print("u{d}", .{bits});
                },
                .float => |bits| {
                    try self.writer.print("f{d}", .{bits});
                },
                .c_short => {
                    try self.writer.writeAll("c_short");
                },
                .c_ushort => {
                    try self.writer.writeAll("c_ushort");
                },
                .c_int => {
                    try self.writer.writeAll("c_int");
                },
                .c_uint => {
                    try self.writer.writeAll("c_uint");
                },
                .c_long => {
                    try self.writer.writeAll("c_long");
                },
                .c_ulong => {
                    try self.writer.writeAll("c_ulong");
                },
                .c_longlong => {
                    try self.writer.writeAll("c_longlong");
                },
                .c_ulonglong => {
                    try self.writer.writeAll("c_ulonglong");
                },
                .name => |n| {
                    try self.generateTypeName(n);
                },
                .instance_type => {
                    try self.writer.writeAll("T");
                },
                .pointer => |p| {
                    if (p.is_optional)
                        try self.writer.writeAll("?");
                    if (p.is_single or p.is_optional) {
                        try self.writer.writeAll("*");
                    } else {
                        //try self.writer.writeAll("[*c]");
                        try self.writer.writeAll("*");
                    }
                    if (p.is_const)
                        try self.writer.writeAll("const ");
                    if (p.child.* == .void) {
                        try self.writer.writeAll("anyopaque");
                    } else {
                        try self.generateType(p.child.*);
                    }
                },
                .function => |f| {
                    try self.writer.writeAll("fn (");
                    for (f.params.items, 0..) |param_ty, i| {
                        if (i > 0)
                            try self.writer.writeAll(", ");
                        try self.generateType(param_ty);
                    }
                    try self.writer.writeAll(") callconv(.C) ");
                    try self.generateType(f.return_type.*);
                },
                .generic => |g| {
                    try self.generateType(g.base_type.*);
                    try self.writer.writeAll("(");
                    for (g.args.items, 0..) |arg, i| {
                        if (i > 0)
                            try self.writer.writeAll(", ");
                        try self.generateType(arg);
                    }
                    try self.writer.writeAll(")");
                },
            }
        }

        fn generateTypePrefix(self: *Self, name: []const u8) !void {
            const namespace = getNamespace(name);
            if (namespace.len > 0 and !std.mem.eql(u8, namespace, "MTL")) {
                try self.generateLower(namespace);
                try self.writer.writeAll(".");
            }
        }

        fn generateContainerSuffix(self: *Self, container: *Container) !void {
            if (container.ambiguous) {
                if (container.is_interface) {
                    try self.writer.writeAll("Interface");
                } else {
                    try self.writer.writeAll("Protocol");
                }
            }
        }

        fn generateTypeName(self: *Self, name: []const u8) !void {
            try self.generateTypePrefix(name);
            try self.writer.writeAll(trimNamespace(name));
            if (registry.protocols.get(name)) |container| {
                try self.generateContainerSuffix(container);
            } else if (registry.interfaces.get(name)) |container| {
                try self.generateContainerSuffix(container);
            }
        }

        fn generateContainerName(self: *Self, container: *Container) !void {
            try self.generateTypePrefix(container.name);
            try self.writer.writeAll(trimNamespace(container.name));
            try self.generateContainerSuffix(container);
        }

        fn generateLower(self: *Self, str: []const u8) !void {
            for (str) |ch| {
                try self.writer.writeByte(std.ascii.toLower(ch));
            }
        }
    };
}

// ------------------------------------------------------------------------------------------------

fn generateMetal(generator: anytype) !void {
    // MTLAccelerationStructure.hpp
    try generator.addEnum("MTLAccelerationStructureUsage");
    try generator.addEnum("MTLAccelerationStructureInstanceOptions");
    try generator.addInterface("MTLAccelerationStructureDescriptor");
    try generator.addInterface("MTLAccelerationStructureGeometryDescriptor");
    try generator.addEnum("MTLMotionBorderMode");
    try generator.addInterface("MTLPrimitiveAccelerationStructureDescriptor");
    try generator.addInterface("MTLAccelerationStructureTriangleGeometryDescriptor");
    try generator.addInterface("MTLAccelerationStructureBoundingBoxGeometryDescriptor");
    try generator.addInterface("MTLMotionKeyframeData");
    try generator.addInterface("MTLAccelerationStructureMotionTriangleGeometryDescriptor");
    try generator.addInterface("MTLAccelerationStructureMotionBoundingBoxGeometryDescriptor");
    //try generator.addStruct("MTLAccelerationStructureInstanceDescriptor");
    //try generator.addStruct("MTLAccelerationStructureUserIDInstanceDescriptor");
    try generator.addEnum("MTLAccelerationStructureInstanceDescriptorType");
    //try generator.addStruct("MTLAccelerationStructureMotionInstanceDescriptor");
    try generator.addInterface("MTLInstanceAccelerationStructureDescriptor");
    try generator.addProtocol("MTLAccelerationStructure");

    // MTLAccelerationStructureCommandEncoder.hpp
    try generator.addEnum("MTLAccelerationStructureRefitOptions");
    try generator.addProtocol("MTLAccelerationStructureCommandEncoder");
    try generator.addInterface("MTLAccelerationStructurePassSampleBufferAttachmentDescriptor");
    try generator.addInterface("MTLAccelerationStructurePassSampleBufferAttachmentDescriptorArray");
    try generator.addInterface("MTLAccelerationStructurePassDescriptor");

    // MTLAccelerationStructureTypes.hpp
    //try generator.addStruct("MTLPackedFloat3");
    //try generator.addStruct("MTLPackedFloat4x3");
    //try generator.addStruct("MTLAxisAlignedBoundingBox");

    // MTLArgument.hpp
    try generator.addEnum("MTLDataType");
    try generator.addEnum("MTLBindingType");
    try generator.addEnum("MTLArgumentType");
    try generator.addEnum("MTLArgumentAccess");
    try generator.addInterface("MTLType");
    try generator.addInterface("MTLStructMember");
    try generator.addInterface("MTLStructType");
    try generator.addInterface("MTLArrayType");
    try generator.addInterface("MTLPointerType");
    try generator.addInterface("MTLTextureReferenceType");
    try generator.addInterface("MTLArgument");
    try generator.addProtocol("MTLBinding");
    try generator.addProtocol("MTLBufferBinding");
    try generator.addProtocol("MTLThreadgroupBinding");
    try generator.addProtocol("MTLTextureBinding");
    try generator.addProtocol("MTLObjectPayloadBinding");

    // MTLArgumentEncoder.hpp
    try generator.addProtocol("MTLArgumentEncoder");

    // MTLBinaryArchive.hpp
    try generator.addEnum("MTLBinaryArchiveError");
    try generator.addInterface("MTLBinaryArchiveDescriptor");
    try generator.addProtocol("MTLBinaryArchive");

    // MTLBlitCommandEncoder.hpp
    try generator.addEnum("MTLBlitOption");
    try generator.addProtocol("MTLBlitCommandEncoder");

    // MTLBlitPass.hpp
    try generator.addInterface("MTLBlitPassSampleBufferAttachmentDescriptor");
    try generator.addInterface("MTLBlitPassSampleBufferAttachmentDescriptorArray");
    try generator.addInterface("MTLBlitPassDescriptor");

    // MTLBuffer.hpp
    try generator.addProtocol("MTLBuffer");

    // MTLCaptureManager.hpp
    try generator.addEnum("MTLCaptureError");
    try generator.addEnum("MTLCaptureDestination");
    try generator.addInterface("MTLCaptureDescriptor");
    try generator.addInterface("MTLCaptureManager");

    // MTLCaptureScope.hpp
    try generator.addProtocol("MTLCaptureScope");

    // MTLCommandBuffer.hpp
    try generator.addEnum("MTLCommandBufferStatus");
    try generator.addEnum("MTLCommandBufferError");
    try generator.addEnum("MTLCommandBufferErrorOption");
    try generator.addEnum("MTLCommandEncoderErrorState");
    try generator.addInterface("MTLCommandBufferDescriptor");
    try generator.addProtocol("MTLCommandBufferEncoderInfo");
    try generator.addEnum("MTLDispatchType");
    //try generator.addType("MTLCommandBufferHandler");
    try generator.addProtocol("MTLCommandBuffer");

    // MTLCommandEncoder.hpp
    try generator.addEnum("MTLResourceUsage");
    try generator.addEnum("MTLBarrierScope");
    try generator.addProtocol("MTLCommandEncoder");

    // MTLCommandQueue.hpp
    try generator.addProtocol("MTLCommandQueue");

    // MTLComputeCommandEncoder.hpp
    //try generator.addStruct("MTLDispatchThreadgroupsIndirectArguments");
    //try generator.addStruct("MTLStageInRegionIndirectArguments");
    try generator.addProtocol("MTLComputeCommandEncoder");

    // MTLComputePass.hpp
    try generator.addInterface("MTLComputePassSampleBufferAttachmentDescriptor");
    try generator.addInterface("MTLComputePassSampleBufferAttachmentDescriptorArray");
    try generator.addInterface("MTLComputePassDescriptor");

    // MTLComputePipeline.hpp
    try generator.addInterface("MTLComputePipelineReflection");
    try generator.addInterface("MTLComputePipelineDescriptor");
    try generator.addProtocol("MTLComputePipelineState");

    // MTLCounters.hpp
    //try generator.addConst("MTLCounterErrorDomain");
    //try generator.addType("MTLCommonCounter");
    //try generator.addConst("MTLCommonCounterTimestamp");
    //try generator.addConst("MTLCommonCounterTessellationInputPatches");
    //try generator.addConst("MTLCommonCounterVertexInvocations");
    //try generator.addConst("MTLCommonCounterPostTessellationVertexInvocations");
    //try generator.addConst("MTLCommonCounterClipperInvocations");
    //try generator.addConst("MTLCommonCounterClipperPrimitivesOut");
    //try generator.addConst("MTLCommonCounterFragmentInvocations");
    //try generator.addConst("MTLCommonCounterFragmentsPassed");
    //try generator.addConst("MTLCommonCounterComputeKernelInvocations");
    //try generator.addConst("MTLCommonCounterTotalCycles");
    //try generator.addConst("MTLCommonCounterVertexCycles");
    //try generator.addConst("MTLCommonCounterTessellationCycles");
    //try generator.addConst("MTLCommonCounterPostTessellationVertexCycles");
    //try generator.addConst("MTLCommonCounterFragmentCycles");
    //try generator.addConst("MTLCommonCounterRenderTargetWriteCycles");
    //try generator.addType("MTLCommonCounterSet");
    //try generator.addConst("MTLCommonCounterSetTimestamp");
    //try generator.addConst("MTLCommonCounterSetStageUtilization");
    //try generator.addConst("MTLCommonCounterSetStatistic");
    //try generator.addStruct("MTLCounterResultTimestamp");
    //try generator.addStruct("MTLCounterResultStageUtilization");
    //try generator.addStruct("MTLCounterResultStatistic");
    try generator.addProtocol("MTLCounter");
    try generator.addProtocol("MTLCounterSet");
    try generator.addInterface("MTLCounterSampleBufferDescriptor");
    try generator.addProtocol("MTLCounterSampleBuffer");
    try generator.addEnum("MTLCounterSampleBufferError");

    // MTLDepthStencil.hpp
    try generator.addEnum("MTLCompareFunction");
    try generator.addEnum("MTLStencilOperation");
    try generator.addInterface("MTLStencilDescriptor");
    try generator.addInterface("MTLDepthStencilDescriptor");
    try generator.addProtocol("MTLDepthStencilState");

    // MTLDevice.hpp
    try generator.addEnum("MTLIOCompressionMethod");
    try generator.addEnum("MTLFeatureSet");
    try generator.addEnum("MTLGPUFamily");
    try generator.addEnum("MTLDeviceLocation");
    try generator.addEnum("MTLPipelineOption");
    try generator.addEnum("MTLReadWriteTextureTier");
    try generator.addEnum("MTLArgumentBuffersTier");
    try generator.addEnum("MTLSparseTextureRegionAlignmentMode");
    try generator.addEnum("MTLSparsePageSize");
    // try generator.addStruct("MTLAccelerationStructureSizes");
    try generator.addEnum("MTLCounterSamplingPoint");
    // try generator.addStruct("MTLSizeAndAlign");
    try generator.addInterface("MTLArgumentDescriptor");
    //try generator.addType("MTLDeviceNotificationName");
    //try generator.addConst("MTLDeviceWasAddedNotification");
    //try generator.addConst("MTLDeviceRemovalRequestedNotification));
    //try generator.addConst("MTLDeviceWasRemovedNotification));
    //try generator.addType("MTLDeviceNotificationHandlerBlock");
    //try generator.addType("MTLAutoreleasedComputePipelineReflection");
    //try generator.addType("MTLAutoreleasedRenderPipelineReflection");
    //try generator.addType("MTLNewLibraryCompletionHandler");
    //try generator.addType("MTLNewRenderPipelineStateCompletionHandler");
    //try generator.addType("MTLNewRenderPipelineStateWithReflectionCompletionHandler");
    //try generator.addType("MTLNewComputePipelineStateCompletionHandler");
    //try generator.addType("MTLNewComputePipelineStateWithReflectionCompletionHandler");
    //try generator.addType("MTLTimestamp");
    //try generator.addFunction("MTLCreateSystemDefaultDevice");
    //try generator.addFunction("MTLCopyAllDevices");
    //try generator.addFunction("MTLCopyAllDevicesWithObserver");
    //try generator.addFunction("MTLRemoveDeviceObserver");
    try generator.addProtocol("MTLDevice");

    // MTLDrawable.hpp
    //try generator.addType("MTLDrawablePresentedHandler");
    try generator.addProtocol("MTLDrawable");

    // MTLDynamicLibrary.hpp
    try generator.addEnum("MTLDynamicLibraryError");
    try generator.addProtocol("MTLDynamicLibrary");

    // MTLEvent.hpp
    try generator.addProtocol("MTLEvent");
    try generator.addInterface("MTLSharedEventListener");
    // try generator.addType("MTLSharedEventNotificationBlock");
    try generator.addProtocol("MTLSharedEvent");
    try generator.addInterface("MTLSharedEventHandle");
    // try generator.addStruct("MTLSharedEventHandlePrivate");

    // MTLFence.hpp
    try generator.addProtocol("MTLFence");

    // MTLFunctionConstantValues.hpp
    try generator.addInterface("MTLFunctionConstantValues");

    // MTLFunctionDescriptor.hpp
    try generator.addEnum("MTLFunctionOptions");
    try generator.addInterface("MTLFunctionDescriptor");
    try generator.addInterface("MTLIntersectionFunctionDescriptor");

    // MTLFunctionHandle.hpp
    try generator.addProtocol("MTLFunctionHandle");

    // MTLFunctionLog.hpp
    try generator.addEnum("MTLFunctionLogType");
    try generator.addProtocol("MTLLogContainer");
    try generator.addProtocol("MTLFunctionLogDebugLocation");
    try generator.addProtocol("MTLFunctionLog");

    // MTLFunctionStitching.hpp
    try generator.addProtocol("MTLFunctionStitchingAttribute");
    try generator.addInterface("MTLFunctionStitchingAttributeAlwaysInline");
    try generator.addProtocol("MTLFunctionStitchingNode");
    try generator.addInterface("MTLFunctionStitchingInputNode");
    try generator.addInterface("MTLFunctionStitchingFunctionNode");
    try generator.addInterface("MTLFunctionStitchingGraph");
    try generator.addInterface("MTLStitchedLibraryDescriptor");

    // MTLHeap.hpp
    try generator.addEnum("MTLHeapType");
    try generator.addInterface("MTLHeapDescriptor");
    try generator.addProtocol("MTLHeap");

    // MTLIndirectCommandBuffer.hpp
    try generator.addEnum("MTLIndirectCommandType");
    // try generator.addStruct("MTLIndirectCommandBufferExecutionRange");
    try generator.addInterface("MTLIndirectCommandBufferDescriptor");
    try generator.addProtocol("MTLIndirectCommandBuffer");

    // MTLIndirectCommandEncoder.hpp
    try generator.addProtocol("MTLIndirectRenderCommand");
    try generator.addProtocol("MTLIndirectComputeCommand");

    // MTLIntersectionFunctionTable.hpp
    try generator.addEnum("MTLIntersectionFunctionSignature");
    try generator.addInterface("MTLIntersectionFunctionTableDescriptor");
    try generator.addProtocol("MTLIntersectionFunctionTable");

    // MTLIOCommandBuffer.hpp
    try generator.addEnum("MTLIOStatus");
    //try generator.addType("MTLIOCommandBufferHandler");
    try generator.addProtocol("MTLIOCommandBuffer");

    // MTLIOCommandQueue.hpp
    try generator.addEnum("MTLIOPriority");
    try generator.addEnum("MTLIOCommandQueueType");
    //try generator.addConst("MTLIOErrorDomain");
    try generator.addEnum("MTLIOError");
    try generator.addProtocol("MTLIOCommandQueue");
    try generator.addProtocol("MTLIOScratchBuffer");
    try generator.addProtocol("MTLIOScratchBufferAllocator");
    try generator.addInterface("MTLIOCommandQueueDescriptor");
    try generator.addProtocol("MTLIOFileHandle");

    // MTLLibrary.hpp
    try generator.addEnum("MTLPatchType");
    try generator.addInterface("MTLVertexAttribute");
    try generator.addInterface("MTLAttribute");
    try generator.addEnum("MTLFunctionType");
    try generator.addInterface("MTLFunctionConstant");
    // try generator.addType("MTLAutoreleasedArgument");
    try generator.addProtocol("MTLFunction");
    try generator.addEnum("MTLLanguageVersion");
    try generator.addEnum("MTLLibraryType");
    try generator.addEnum("MTLLibraryOptimizationLevel");
    try generator.addEnum("MTLCompileSymbolVisibility");

    try generator.addInterface("MTLCompileOptions");
    try generator.addEnum("MTLLibraryError");
    try generator.addProtocol("MTLLibrary");

    // MTLLinkedFunctions.hpp
    try generator.addInterface("MTLLinkedFunctions");

    // MTLParallelRenderCommandEncoder.hpp
    try generator.addProtocol("MTLParallelRenderCommandEncoder");

    // MTLPipeline.hpp
    try generator.addEnum("MTLMutability");
    try generator.addInterface("MTLPipelineBufferDescriptor");
    try generator.addInterface("MTLPipelineBufferDescriptorArray");

    // MTLPixelFormat.hpp
    try generator.addEnum("MTLPixelFormat");

    // MTLRasterizationRate.hpp
    try generator.addInterface("MTLRasterizationRateSampleArray");
    try generator.addInterface("MTLRasterizationRateLayerDescriptor");
    try generator.addInterface("MTLRasterizationRateLayerArray");
    try generator.addInterface("MTLRasterizationRateMapDescriptor");
    try generator.addProtocol("MTLRasterizationRateMap");

    // MTLRenderCommandEncoder.hpp
    try generator.addEnum("MTLPrimitiveType");
    try generator.addEnum("MTLVisibilityResultMode");
    // try generator.addStruct("MTLScissorRect");
    // try generator.addStruct("MTLViewport");
    try generator.addEnum("MTLCullMode");
    try generator.addEnum("MTLWinding");
    try generator.addEnum("MTLDepthClipMode");
    try generator.addEnum("MTLTriangleFillMode");
    // try generator.addStruct("MTLDrawPrimitivesIndirectArguments");
    // try generator.addStruct("MTLDrawIndexedPrimitivesIndirectArguments");
    // try generator.addStruct("MTLVertexAmplificationViewMapping");
    // try generator.addStruct("MTLDrawPatchIndirectArguments");
    // try generator.addStruct("MTLQuadTessellationFactorsHalf");
    // try generator.addStruct("MTLTriangleTessellationFactorsHalf");
    try generator.addEnum("MTLRenderStages");
    try generator.addProtocol("MTLRenderCommandEncoder");

    // MTLRenderPass.hpp
    try generator.addEnum("MTLLoadAction");
    try generator.addEnum("MTLStoreAction");
    try generator.addEnum("MTLStoreActionOptions");
    // try generator.addStruct("MTLClearColor");
    try generator.addInterface("MTLRenderPassAttachmentDescriptor");
    try generator.addInterface("MTLRenderPassColorAttachmentDescriptor");
    try generator.addEnum("MTLMultisampleDepthResolveFilter");
    try generator.addInterface("MTLRenderPassDepthAttachmentDescriptor");
    try generator.addEnum("MTLMultisampleStencilResolveFilter");
    try generator.addInterface("MTLRenderPassStencilAttachmentDescriptor");
    try generator.addInterface("MTLRenderPassColorAttachmentDescriptorArray");
    try generator.addInterface("MTLRenderPassSampleBufferAttachmentDescriptor");
    try generator.addInterface("MTLRenderPassSampleBufferAttachmentDescriptorArray");
    try generator.addInterface("MTLRenderPassDescriptor");

    // MTLRenderPipeline.hpp
    try generator.addEnum("MTLBlendFactor");
    try generator.addEnum("MTLBlendOperation");
    try generator.addEnum("MTLColorWriteMask");
    try generator.addEnum("MTLPrimitiveTopologyClass");
    try generator.addEnum("MTLTessellationPartitionMode");
    try generator.addEnum("MTLTessellationFactorStepFunction");
    try generator.addEnum("MTLTessellationFactorFormat");
    try generator.addEnum("MTLTessellationControlPointIndexType");
    try generator.addInterface("MTLRenderPipelineColorAttachmentDescriptor");
    try generator.addInterface("MTLRenderPipelineReflection");
    try generator.addInterface("MTLRenderPipelineDescriptor");
    try generator.addInterface("MTLRenderPipelineFunctionsDescriptor");
    try generator.addProtocol("MTLRenderPipelineState");
    try generator.addInterface("MTLRenderPipelineColorAttachmentDescriptorArray");
    try generator.addInterface("MTLTileRenderPipelineColorAttachmentDescriptor");
    try generator.addInterface("MTLTileRenderPipelineColorAttachmentDescriptorArray");
    try generator.addInterface("MTLTileRenderPipelineDescriptor");
    try generator.addInterface("MTLMeshRenderPipelineDescriptor");

    // MTLResource.hpp
    try generator.addEnum("MTLPurgeableState");
    try generator.addEnum("MTLCPUCacheMode");
    try generator.addEnum("MTLStorageMode");
    try generator.addEnum("MTLHazardTrackingMode");
    try generator.addEnum("MTLResourceOptions");
    try generator.addProtocol("MTLResource");

    // MTLResourceStateCommandEncoder.hpp
    try generator.addEnum("MTLSparseTextureMappingMode");
    // try generator.addStruct("MTLMapIndirectArguments");
    try generator.addProtocol("MTLResourceStateCommandEncoder");

    // MTLResourceStatePass.hpp
    try generator.addInterface("MTLResourceStatePassSampleBufferAttachmentDescriptor");
    try generator.addInterface("MTLResourceStatePassSampleBufferAttachmentDescriptorArray");
    try generator.addInterface("MTLResourceStatePassDescriptor");

    // MTLSampler.hpp
    try generator.addEnum("MTLSamplerMinMagFilter");
    try generator.addEnum("MTLSamplerMipFilter");
    try generator.addEnum("MTLSamplerAddressMode");
    try generator.addEnum("MTLSamplerBorderColor");
    try generator.addInterface("MTLSamplerDescriptor");
    try generator.addProtocol("MTLSamplerState");

    // MTLStageInputOutputDescriptor.hpp
    try generator.addEnum("MTLAttributeFormat");
    try generator.addEnum("MTLIndexType");
    try generator.addEnum("MTLStepFunction");
    try generator.addInterface("MTLBufferLayoutDescriptor");
    try generator.addInterface("MTLBufferLayoutDescriptorArray");
    try generator.addInterface("MTLAttributeDescriptor");
    try generator.addInterface("MTLAttributeDescriptorArray");
    try generator.addInterface("MTLStageInputOutputDescriptor");

    // MTLTexture.hpp
    try generator.addEnum("MTLTextureType");
    try generator.addEnum("MTLTextureSwizzle");
    // try generator.addStruct("MTLTextureSwizzleChannels");
    try generator.addInterface("MTLSharedTextureHandle");
    // try generator.addStruct("MTLSharedTextureHandlePrivate");
    try generator.addEnum("MTLTextureUsage");
    try generator.addEnum("MTLTextureCompressionType");
    try generator.addInterface("MTLTextureDescriptor");
    try generator.addProtocol("MTLTexture");

    // MTLTypes.hpp
    // try generator.addStruct("MTLOrigin");
    // try generator.addStruct("MTLSize");
    // try generator.addStruct("MTLRegion");
    // try generator.addType("MTLCoordinate2D");
    // try generator.addStruct("MTLSamplePosition");

    // MTLVertexDescriptor.hpp
    try generator.addEnum("MTLVertexFormat");
    try generator.addEnum("MTLVertexStepFunction");
    try generator.addInterface("MTLVertexBufferLayoutDescriptor");
    try generator.addInterface("MTLVertexBufferLayoutDescriptorArray");
    try generator.addInterface("MTLVertexAttributeDescriptor");
    try generator.addInterface("MTLVertexAttributeDescriptorArray");
    try generator.addInterface("MTLVertexDescriptor");

    // MTLVisibleFunctionTable.hpp
    try generator.addInterface("MTLVisibleFunctionTableDescriptor");
    try generator.addProtocol("MTLVisibleFunctionTable");
}

pub fn main() anyerror!void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 8 }){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const allocator = general_purpose_allocator.allocator();

    var file = try std.fs.cwd().openFile("headers.json", .{});
    defer file.close();

    const file_data = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_data);

    var valueTree = try std.json.parseFromSlice(std.json.Value, allocator, file_data, .{});
    defer valueTree.deinit();

    registry = Registry.init(allocator);
    defer registry.deinit();

    var converter = Converter.init(allocator);
    defer converter.deinit();

    try converter.convert(valueTree.value);

    const stdout = std.io.getStdOut().writer();
    var generator = Generator(@TypeOf(stdout)).init(allocator, stdout);
    defer generator.deinit();

    try generateMetal(&generator);

    try generator.generate();
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
