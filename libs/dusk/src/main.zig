const std = @import("std");

pub const Ast = @import("Ast.zig");
pub const IR = @import("IR.zig");
pub const Parser = @import("Parser.zig");
pub const Token = @import("Token.zig");
pub const Tokenizer = @import("Tokenizer.zig");
pub const ErrorList = @import("ErrorList.zig");

pub const Extension = enum {
    f16,

    pub const Array = std.enums.EnumArray(Extension, bool);
};
