const std = @import("std");

pub const IR = @import("IR.zig");
pub const printIR = @import("print_ir.zig").printIR;
pub const Ast = @import("Ast.zig");
pub const Parser = @import("Parser.zig");
pub const Token = @import("Token.zig");
pub const Tokenizer = @import("Tokenizer.zig");
pub const ErrorList = @import("ErrorList.zig");

pub const Extension = enum {
    f16,

    pub const Array = std.enums.EnumArray(Extension, bool);
};

test {
    std.testing.refAllDecls(IR);
    std.testing.refAllDecls(@import("print_ir.zig"));
    std.testing.refAllDecls(Ast);
    std.testing.refAllDecls(Parser);
    std.testing.refAllDecls(Token);
    std.testing.refAllDecls(Tokenizer);
    std.testing.refAllDecls(ErrorList);
}
