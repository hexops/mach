//! Borrowed from Zig compiler codebase with changes.
//! Licensed under LICENSE-ZIG
//!
//! Represents a section or subsection of instructions in a SPIR-V binary. Instructions can be append
//! to separate sections, which can then later be merged into the final binary.

const std = @import("std");
const spec = @import("spec.zig");
const Opcode = spec.Opcode;
const Word = spec.Word;

const DoubleWord = std.meta.Int(.unsigned, @bitSizeOf(Word) * 2);
const Log2Word = std.math.Log2Int(Word);

const Section = @This();

allocator: std.mem.Allocator,
words: std.ArrayListUnmanaged(Word) = .{},

pub fn deinit(section: *Section) void {
    section.words.deinit(section.allocator);
}

pub fn toWords(section: Section) []Word {
    return section.words.items;
}

/// Append the words from another section into this section.
pub fn append(section: *Section, other_section: Section) !void {
    try section.words.appendSlice(section.allocator, other_section.words.items);
}

/// Ensure capacity of at least `capacity` more words in this section.
pub fn ensureUnusedCapacity(section: *Section, capacity: usize) !void {
    try section.words.ensureUnusedCapacity(section.allocator, capacity);
}

/// Write an instruction and size, operands are to be inserted manually.
pub fn emitRaw(
    section: *Section,
    opcode: Opcode,
    operand_words: usize, // opcode itself not included
) !void {
    const word_count = 1 + operand_words;
    try section.words.ensureUnusedCapacity(section.allocator, word_count);
    section.writeWord(@as(Word, @intCast(word_count << 16)) | @intFromEnum(opcode));
}

pub fn emit(
    section: *Section,
    comptime opcode: spec.Opcode,
    operands: opcode.Operands(),
) !void {
    const word_count = instructionSize(opcode, operands);
    try section.ensureUnusedCapacity(word_count);
    section.writeWord(@as(Word, @intCast(word_count << 16)) | @intFromEnum(opcode));
    section.writeOperands(opcode.Operands(), operands);
}

pub fn emitSpecConstantOp(
    section: *Section,
    comptime opcode: spec.Opcode,
    operands: opcode.Operands(),
) !void {
    const word_count = operandsSize(opcode.Operands(), operands);
    try section.emitRaw(.OpSpecConstantOp, 1 + word_count);
    section.writeOperand(spec.IdRef, operands.id_result_type);
    section.writeOperand(spec.IdRef, operands.id_result);
    section.writeOperand(Opcode, opcode);

    const fields = @typeInfo(opcode.Operands()).Struct.fields;
    // First 2 fields are always id_result_type and id_result.
    inline for (fields[2..]) |field| {
        section.writeOperand(field.type, @field(operands, field.name));
    }
}

pub fn writeWord(section: *Section, word: Word) void {
    section.words.appendAssumeCapacity(word);
}

pub fn writeWords(section: *Section, words: []const Word) void {
    section.words.appendSliceAssumeCapacity(words);
}

pub fn writeDoubleWord(section: *Section, dword: DoubleWord) void {
    section.writeWords(&[_]Word{
        @truncate(dword),
        @truncate(dword >> @bitSizeOf(Word)),
    });
}

fn writeOperands(section: *Section, comptime Operands: type, operands: Operands) void {
    const fields = switch (@typeInfo(Operands)) {
        .Struct => |info| info.fields,
        .Void => return,
        else => unreachable,
    };

    inline for (fields) |field| {
        section.writeOperand(field.type, @field(operands, field.name));
    }
}

pub fn writeOperand(section: *Section, comptime Operand: type, operand: Operand) void {
    switch (Operand) {
        spec.IdResult => section.writeWord(operand.id),
        spec.LiteralInteger => section.writeWord(operand),
        spec.LiteralString => section.writeString(operand),
        spec.LiteralContextDependentNumber => section.writeContextDependentNumber(operand),
        spec.LiteralExtInstInteger => section.writeWord(operand.inst),

        // TODO: Where this type is used (OpSpecConstantOp) is currently not correct in the spec json,
        // so it most likely needs to be altered into something that can actually describe the entire
        // instruction in which it is used.
        spec.LiteralSpecConstantOpInteger => section.writeWord(@intFromEnum(operand.opcode)),

        spec.PairLiteralIntegerIdRef => section.writeWords(&.{ operand.value, operand.label.id }),
        spec.PairIdRefLiteralInteger => section.writeWords(&.{ operand.target.id, operand.member }),
        spec.PairIdRefIdRef => section.writeWords(&.{ operand[0].id, operand[1].id }),
        else => switch (@typeInfo(Operand)) {
            .Enum => section.writeWord(@intFromEnum(operand)),
            .Optional => |info| if (operand) |child| {
                section.writeOperand(info.child, child);
            },
            .Pointer => |info| {
                std.debug.assert(info.size == .Slice); // Should be no other pointer types in the spec.
                for (operand) |item| {
                    section.writeOperand(info.child, item);
                }
            },
            .Struct => |info| {
                if (info.layout == .Packed) {
                    section.writeWord(@bitCast(operand));
                } else {
                    section.writeExtendedMask(Operand, operand);
                }
            },
            .Union => section.writeExtendedUnion(Operand, operand),
            else => unreachable,
        },
    }
}

fn writeString(section: *Section, str: []const u8) void {
    // TODO: Not actually sure whether this is correct for big-endian.
    // See https://www.khronos.org/registry/spir-v/specs/unified1/SPIRV.html#Literal
    const zero_terminated_len = str.len + 1;
    var i: usize = 0;
    while (i < zero_terminated_len) : (i += @sizeOf(Word)) {
        var word: Word = 0;

        var j: usize = 0;
        while (j < @sizeOf(Word) and i + j < str.len) : (j += 1) {
            word |= @as(Word, str[i + j]) << @as(Log2Word, @intCast(j * @bitSizeOf(u8)));
        }

        section.words.appendAssumeCapacity(word);
    }
}

fn writeContextDependentNumber(section: *Section, operand: spec.LiteralContextDependentNumber) void {
    switch (operand) {
        .int32 => |int| section.writeWord(@bitCast(int)),
        .uint32 => |int| section.writeWord(@bitCast(int)),
        .int64 => |int| section.writeDoubleWord(@bitCast(int)),
        .uint64 => |int| section.writeDoubleWord(@bitCast(int)),
        .float32 => |float| section.writeWord(@bitCast(float)),
        .float64 => |float| section.writeDoubleWord(@bitCast(float)),
    }
}

fn writeExtendedMask(section: *Section, comptime Operand: type, operand: Operand) void {
    var mask: Word = 0;
    inline for (@typeInfo(Operand).Struct.fields, 0..) |field, bit| {
        switch (@typeInfo(field.type)) {
            .Optional => if (@field(operand, field.name) != null) {
                mask |= 1 << @intCast(bit);
            },
            .Bool => if (@field(operand, field.name)) {
                mask |= 1 << @intCast(bit);
            },
            else => unreachable,
        }
    }

    section.writeWord(mask);

    inline for (@typeInfo(Operand).Struct.fields) |field| {
        switch (@typeInfo(field.type)) {
            .Optional => |info| if (@field(operand, field.name)) |child| {
                section.writeOperands(info.child, child);
            },
            .Bool => {},
            else => unreachable,
        }
    }
}

fn writeExtendedUnion(section: *Section, comptime Operand: type, operand: Operand) void {
    const tag = std.meta.activeTag(operand);
    section.writeWord(@intFromEnum(tag));

    inline for (@typeInfo(Operand).Union.fields) |field| {
        if (@field(Operand, field.name) == tag) {
            section.writeOperands(field.type, @field(operand, field.name));
            return;
        }
    }
    unreachable;
}

fn instructionSize(comptime opcode: spec.Opcode, operands: opcode.Operands()) usize {
    return 1 + operandsSize(opcode.Operands(), operands);
}

fn operandsSize(comptime Operands: type, operands: Operands) usize {
    const fields = switch (@typeInfo(Operands)) {
        .Struct => |info| info.fields,
        .Void => return 0,
        else => unreachable,
    };

    var total: usize = 0;
    inline for (fields) |field| {
        total += operandSize(field.type, @field(operands, field.name));
    }

    return total;
}

fn operandSize(comptime Operand: type, operand: Operand) usize {
    return switch (Operand) {
        spec.IdResult,
        spec.LiteralInteger,
        spec.LiteralExtInstInteger,
        => 1,
        // Add one for zero-terminator
        spec.LiteralString => std.math.divCeil(usize, operand.len + 1, @sizeOf(Word)) catch unreachable,
        spec.LiteralContextDependentNumber => switch (operand) {
            .int32, .uint32, .float32 => @as(usize, 1),
            .int64, .uint64, .float64 => @as(usize, 2),
        },

        // TODO: Where this type is used (OpSpecConstantOp) is currently not correct in the spec
        // json, so it most likely needs to be altered into something that can actually
        // describe the entire insturction in which it is used.
        spec.LiteralSpecConstantOpInteger => 1,

        spec.PairLiteralIntegerIdRef,
        spec.PairIdRefLiteralInteger,
        spec.PairIdRefIdRef,
        => 2,
        else => switch (@typeInfo(Operand)) {
            .Enum => 1,
            .Optional => |info| if (operand) |child| operandSize(info.child, child) else 0,
            .Pointer => |info| blk: {
                std.debug.assert(info.size == .Slice); // Should be no other pointer types in the spec.
                var total: usize = 0;
                for (operand) |item| {
                    total += operandSize(info.child, item);
                }
                break :blk total;
            },
            .Struct => |info| if (info.layout == .Packed) 1 else extendedMaskSize(Operand, operand),
            .Union => extendedUnionSize(Operand, operand),
            else => unreachable,
        },
    };
}

fn extendedMaskSize(comptime Operand: type, operand: Operand) usize {
    var total: usize = 0;
    var any_set = false;
    inline for (@typeInfo(Operand).Struct.fields) |field| {
        switch (@typeInfo(field.type)) {
            .Optional => |info| if (@field(operand, field.name)) |child| {
                total += operandsSize(info.child, child);
                any_set = true;
            },
            .Bool => if (@field(operand, field.name)) {
                any_set = true;
            },
            else => unreachable,
        }
    }
    if (!any_set) {
        return 0;
    }
    return total + 1; // Add one for the mask itself.
}

fn extendedUnionSize(comptime Operand: type, operand: Operand) usize {
    const tag = std.meta.activeTag(operand);
    inline for (@typeInfo(Operand).Union.fields) |field| {
        if (@field(Operand, field.name) == tag) {
            // Add one for the tag itself.
            return 1 + operandsSize(field.type, @field(operand, field.name));
        }
    }
    unreachable;
}
