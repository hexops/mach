const std = @import("std");
const utils = @import("utils");
const c = @import("c.zig");
const Direction = @import("common.zig").Direction;
const Script = @import("common.zig").Script;
const Language = @import("common.zig").Language;

pub const ContentType = enum(u2) {
    invalid = c.HB_BUFFER_CONTENT_TYPE_INVALID,
    unicode = c.HB_BUFFER_CONTENT_TYPE_UNICODE,
    glyphs = c.HB_BUFFER_CONTENT_TYPE_GLYPHS,
};

pub const Buffer = struct {
    pub const Flags = packed struct {
        bot: bool = false,
        eot: bool = false,
        preserve_default_ignorables: bool = false,
        remove_default_ignorables: bool = false,
        do_not_insert_dotted_circle: bool = false,
        verify: bool = false,
        produce_unsafe_to_concat: bool = false,

        pub const Flag = enum(u21) {
            bot = c.HB_BUFFER_FLAG_BOT,
            eot = c.HB_BUFFER_FLAG_EOT,
            preserve_default_ignorables = c.HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES,
            remove_default_ignorables = c.HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES,
            do_not_insert_dotted_circle = c.HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE,
            verify = c.HB_BUFFER_FLAG_VERIFY,
            produce_unsafe_to_concat = c.HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT,
        };

        pub fn from(bits: u21) Flags {
            return utils.bitFieldsToStruct(Flags, Flag, bits);
        }

        pub fn cast(flags: Flags) u21 {
            return utils.structToBitFields(u21, Flag, flags);
        }
    };

    handle: *c.hb_buffer_t,

    pub fn init() ?Buffer {
        var b = c.hb_buffer_create();
        if (c.hb_buffer_allocation_successful(b) < 1)
            return null;
        return Buffer{ .handle = b.? };
    }

    pub fn getEmpty() Buffer {
        return .{ .handle = c.hb_buffer_get_empty().? };
    }

    pub fn initSimilar(self: Buffer) ?Buffer {
        var b = c.hb_buffer_create_similar(self.handle);
        if (c.hb_buffer_allocation_successful(b) < 1)
            return null;
        return Buffer{ .handle = b.? };
    }

    pub fn reference(self: Buffer) Buffer {
        return .{
            .handle = c.hb_buffer_reference(self.handle).?,
        };
    }

    pub fn deinit(self: Buffer) void {
        c.hb_buffer_destroy(self.handle);
    }

    pub fn reset(self: Buffer) void {
        c.hb_buffer_reset(self.handle);
    }

    pub fn clearContents(self: Buffer) void {
        c.hb_buffer_clear_contents(self.handle);
    }

    pub fn preAllocate(self: Buffer, size: u32) error{OutOfMemory}!void {
        if (c.hb_buffer_pre_allocate(self.handle, size) < 1)
            return error.OutOfMemory;
    }

    pub fn allocationSuccessful(self: Buffer) bool {
        return c.hb_buffer_allocation_successful(self.handle) > 0;
    }

    pub fn add(self: Buffer, codepoint: u32, cluster: usize) void {
        c.hb_buffer_add(self.handle, codepoint, @intCast(c_uint, cluster));
    }

    pub fn addCodepoints(self: Buffer, text: []const u32, item_offset: usize, item_length: usize) void {
        c.hb_buffer_add_codepoints(self.handle, text.ptr, @intCast(c_int, text.len), @intCast(c_uint, item_offset), @intCast(c_int, item_length));
    }

    pub fn addUTF32(self: Buffer, text: []const u32, item_offset: usize, item_length: usize) void {
        c.hb_buffer_add_utf32(self.handle, text.ptr, @intCast(c_int, text.len), @intCast(c_uint, item_offset), @intCast(c_int, item_length));
    }

    pub fn addUTF16(self: Buffer, text: []const u16, item_offset: usize, item_length: usize) void {
        c.hb_buffer_add_utf16(self.handle, text.ptr, @intCast(c_int, text.len), @intCast(c_uint, item_offset), @intCast(c_int, item_length));
    }

    pub fn addUTF8(self: Buffer, text: []const u8, item_offset: usize, item_length: usize) void {
        c.hb_buffer_add_utf8(self.handle, text.ptr, @intCast(c_int, text.len), @intCast(c_uint, item_offset), @intCast(c_int, item_length));
    }

    pub fn addLatin1(self: Buffer, text: []const u8, item_offset: usize, item_length: usize) void {
        c.hb_buffer_add_latin1(self.handle, text.ptr, @intCast(c_int, text.len), @intCast(c_uint, item_offset), @intCast(c_int, item_length));
    }

    pub fn append(self: Buffer, source: Buffer, start: usize, end: usize) void {
        c.hb_buffer_append(self.handle, source.handle, @intCast(c_uint, start), @intCast(c_uint, end));
    }

    pub fn setContentType(self: Buffer, content_type: ContentType) void {
        c.hb_buffer_set_content_type(self.handle, @enumToInt(content_type));
    }

    pub fn getContentType(self: Buffer) ContentType {
        return @intToEnum(ContentType, c.hb_buffer_get_content_type(self.handle));
    }

    pub fn setDirection(self: Buffer, direction: Direction) void {
        c.hb_buffer_set_direction(self.handle, @enumToInt(direction));
    }

    pub fn getDirection(self: Buffer) Direction {
        return @intToEnum(Direction, c.hb_buffer_get_direction(self.handle));
    }

    pub fn setScript(self: Buffer, script: Script) void {
        c.hb_buffer_set_script(self.handle, @enumToInt(script));
    }

    pub fn getScript(self: Buffer) Script {
        return @intToEnum(Script, c.hb_buffer_get_script(self.handle));
    }

    pub fn setLanguage(self: Buffer, lang: Language) void {
        c.hb_buffer_set_language(self.handle, @enumToInt(lang));
    }

    pub fn getLanguage(self: Buffer) Language {
        return @intToEnum(Language, c.hb_buffer_get_language(self.handle));
    }

    pub fn setFlags(self: Buffer, flags: Flags) void {
        c.hb_buffer_set_flags(self.handle, flags.cast());
    }

    pub fn getFlags(self: Buffer) Flags {
        return Flags.from(c.hb_buffer_get_flags(self.handle));
    }
};
