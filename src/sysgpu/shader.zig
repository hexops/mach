const std = @import("std");

pub const CodeGen = @import("shader/CodeGen.zig");
pub const Air = @import("shader/Air.zig");
pub const Ast = @import("shader/Ast.zig");
pub const Parser = @import("shader/Parser.zig");
pub const Token = @import("shader/Token.zig");
pub const Tokenizer = @import("shader/Tokenizer.zig");
pub const ErrorList = @import("shader/ErrorList.zig");
pub const printAir = @import("shader/print_air.zig").printAir;

test "reference declarations" {
    std.testing.refAllDecls(CodeGen);
    std.testing.refAllDecls(Air);
    std.testing.refAllDecls(Ast);
    std.testing.refAllDecls(Parser);
    std.testing.refAllDecls(Token);
    std.testing.refAllDecls(Tokenizer);
    std.testing.refAllDecls(ErrorList);
    _ = printAir;
    _ = @import("shader/test.zig");
}
