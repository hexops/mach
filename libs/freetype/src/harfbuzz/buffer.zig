const std = @import("std");
const c = @import("c.zig");
const Direction = @import("common.zig").Direction;
const Script = @import("common.zig").Script;
const Language = @import("common.zig").Language;
const Font = @import("font.zig").Font;

pub const ContentType = enum(u2) {
    invalid = c.HB_BUFFER_CONTENT_TYPE_INVALID,
    unicode = c.HB_BUFFER_CONTENT_TYPE_UNICODE,
    glyphs = c.HB_BUFFER_CONTENT_TYPE_GLYPHS,
};

pub const ClusterLevel = enum(u2) {
    monotone_graphemes = c.HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES,
    monotone_characters = c.HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS,
    characters = c.HB_BUFFER_CLUSTER_LEVEL_CHARACTERS,
};

pub const SerializeFormat = enum(u31) {
    text = c.HB_BUFFER_SERIALIZE_FORMAT_TEXT,
    json = c.HB_BUFFER_SERIALIZE_FORMAT_JSON,
    invalid = c.HB_BUFFER_SERIALIZE_FORMAT_INVALID,
};

pub const GlyphInfo = extern struct {
    codepoint: u32,
    mask: u32,
    cluster: u32,
    var1: u32,
    var2: u32,

    pub fn getFlags(self: GlyphInfo) GlyphFlags {
        return @bitCast(GlyphFlags, hb_glyph_info_get_glyph_flags(&self));
    }
};

pub const Position = extern struct {
    x_advance: i32,
    y_advance: i32,
    x_offset: i32,
    y_offset: i32,
    _padding: u32, // private
};

pub const GlyphFlags = packed struct(c_int) {
    unsafe_to_break: bool = false,
    unsafe_to_concat: bool = false,
    _padding: u30 = 0,
};

pub const SegmentProps = struct {
    direction: Direction,
    script: Script,
    language: Language,

    pub fn from(c_struct: c.hb_segment_properties_t) SegmentProps {
        return .{
            .direction = @enumFromInt(Direction, c_struct.direction),
            .script = @enumFromInt(Script, c_struct.script),
            .language = Language{ .handle = c_struct.language },
        };
    }

    pub fn cast(self: SegmentProps) c.hb_segment_properties_t {
        return .{
            .reserved1 = undefined,
            .reserved2 = undefined,
            .direction = @intFromEnum(self.direction),
            .script = @intFromEnum(self.script),
            .language = self.language.handle,
        };
    }

    pub fn compare(a: SegmentProps, b: SegmentProps) bool {
        return c.hb_segment_properties_equal(&a.cast(), &b.cast()) > 0;
    }

    pub fn hash(self: SegmentProps) u32 {
        return c.hb_segment_properties_hash(&self.cast());
    }

    pub fn overlay(self: *SegmentProps, src: SegmentProps) void {
        var seg_props = self.cast();
        c.hb_segment_properties_overlay(&seg_props, &src.cast());
        self.* = SegmentProps.from(seg_props);
    }
};

pub const SerializeFlags = packed struct(c_int) {
    no_clusters: bool = false,
    no_positions: bool = false,
    no_glyph_names: bool = false,
    glyph_extents: bool = false,
    glyph_flags: bool = false,
    no_advances: bool = false,
    _padding: u26 = 0,
};

pub const DiffFlags = packed struct(c_int) {
    content_type_mismatch: bool = false,
    length_mismatch: bool = false,
    notdef_present: bool = false,
    dotted_circle_present: bool = false,
    codepoint_mismatch: bool = false,
    cluster_mismatch: bool = false,
    glyph_flags_mismatch: bool = false,
    position_mismatch: bool = false,
    _padding: u24 = 0,
};

pub const Buffer = struct {
    pub const Flags = packed struct(c_int) {
        bot: bool = false,
        eot: bool = false,
        preserve_default_ignorables: bool = false,
        remove_default_ignorables: bool = false,
        do_not_insert_dotted_circle: bool = false,
        verify: bool = false,
        produce_unsafe_to_concat: bool = false,
        _padding: u25 = 0,
    };

    handle: *c.hb_buffer_t,

    pub fn init() ?Buffer {
        var b = c.hb_buffer_create();
        if (c.hb_buffer_allocation_successful(b) < 1)
            return null;
        return Buffer{ .handle = b.? };
    }

    pub fn initEmpty() Buffer {
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

    pub fn add(self: Buffer, codepoint: u32, cluster: u32) void {
        c.hb_buffer_add(self.handle, codepoint, cluster);
    }

    pub fn addCodepoints(self: Buffer, text: []const u32, item_offset: u32, item_length: ?u31) void {
        c.hb_buffer_add_codepoints(self.handle, &text[0], @intCast(c_int, text.len), item_offset, if (item_length) |l| l else @intCast(c_int, text.len));
    }

    pub fn addUTF32(self: Buffer, text: []const u32, item_offset: u32, item_length: ?u31) void {
        c.hb_buffer_add_utf32(self.handle, &text[0], @intCast(c_int, text.len), item_offset, if (item_length) |l| l else @intCast(c_int, text.len));
    }

    pub fn addUTF16(self: Buffer, text: []const u16, item_offset: u32, item_length: ?u31) void {
        c.hb_buffer_add_utf16(self.handle, &text[0], @intCast(c_int, text.len), item_offset, if (item_length) |l| l else @intCast(c_int, text.len));
    }

    pub fn addUTF8(self: Buffer, text: []const u8, item_offset: u32, item_length: ?u31) void {
        c.hb_buffer_add_utf8(self.handle, &text[0], @intCast(c_int, text.len), item_offset, if (item_length) |l| l else @intCast(c_int, text.len));
    }

    pub fn addLatin1(self: Buffer, text: []const u8, item_offset: u32, item_length: ?u31) void {
        c.hb_buffer_add_latin1(self.handle, &text[0], @intCast(c_int, text.len), item_offset, if (item_length) |l| l else @intCast(c_int, text.len));
    }

    pub fn append(self: Buffer, source: Buffer, start: u32, end: u32) void {
        c.hb_buffer_append(self.handle, source.handle, start, end);
    }

    pub fn getContentType(self: Buffer) ContentType {
        return @enumFromInt(ContentType, c.hb_buffer_get_content_type(self.handle));
    }

    pub fn setContentType(self: Buffer, content_type: ContentType) void {
        c.hb_buffer_set_content_type(self.handle, @intFromEnum(content_type));
    }

    pub fn getDirection(self: Buffer) Direction {
        return @enumFromInt(Direction, c.hb_buffer_get_direction(self.handle));
    }

    pub fn setDirection(self: Buffer, direction: Direction) void {
        c.hb_buffer_set_direction(self.handle, @intFromEnum(direction));
    }

    pub fn getScript(self: Buffer) Script {
        return @enumFromInt(Script, c.hb_buffer_get_script(self.handle));
    }

    pub fn setScript(self: Buffer, script: Script) void {
        c.hb_buffer_set_script(self.handle, @intFromEnum(script));
    }

    pub fn getLanguage(self: Buffer) Language {
        return Language{ .handle = c.hb_buffer_get_language(self.handle) };
    }

    pub fn setLanguage(self: Buffer, lang: Language) void {
        c.hb_buffer_set_language(self.handle, lang.handle);
    }

    pub fn getFlags(self: Buffer) Flags {
        return @bitCast(Flags, c.hb_buffer_get_flags(self.handle));
    }

    pub fn setFlags(self: Buffer, flags: Flags) void {
        c.hb_buffer_set_flags(self.handle, @bitCast(u32, flags));
    }

    pub fn getClusterLevel(self: Buffer) ClusterLevel {
        return @enumFromInt(ClusterLevel, c.hb_buffer_get_cluster_level(self.handle));
    }

    pub fn setClusterLevel(self: Buffer, level: ClusterLevel) void {
        c.hb_buffer_set_cluster_level(self.handle, @intFromEnum(level));
    }

    pub fn getLength(self: Buffer) u32 {
        return c.hb_buffer_get_length(self.handle);
    }

    pub fn setLength(self: Buffer, new_len: u32) error{OutOfMemory}!void {
        if (c.hb_buffer_set_length(self.handle, new_len) < 1)
            return error.OutOfMemory;
    }

    pub fn getSegmentProps(self: Buffer) SegmentProps {
        var props: c.hb_segment_properties_t = undefined;
        c.hb_buffer_get_segment_properties(self.handle, &props);
        return SegmentProps.from(props);
    }

    pub fn setSegmentProps(self: Buffer, props: SegmentProps) void {
        c.hb_buffer_set_segment_properties(self.handle, &props.cast());
    }

    pub fn guessSegmentProps(self: Buffer) void {
        c.hb_buffer_guess_segment_properties(self.handle);
    }

    pub fn getGlyphInfos(self: Buffer) []GlyphInfo {
        var length: u32 = 0;
        return hb_buffer_get_glyph_infos(self.handle, &length)[0..length];
    }

    pub fn getGlyphPositions(self: Buffer) ?[]Position {
        var length: u32 = 0;
        return if (hb_buffer_get_glyph_positions(self.handle, &length)) |positions|
            @ptrCast([*]Position, positions)[0..length]
        else
            null;
    }

    pub fn hasPositions(self: Buffer) bool {
        return c.hb_buffer_has_positions(self.handle) > 0;
    }

    pub fn getInvisibleGlyph(self: Buffer) u32 {
        return c.hb_buffer_get_invisible_glyph(self.handle);
    }

    pub fn setInvisibleGlyph(self: Buffer, codepoint: u32) void {
        c.hb_buffer_set_invisible_glyph(self.handle, codepoint);
    }

    pub fn getGlyphNotFound(self: Buffer) u32 {
        return c.hb_buffer_get_not_found_glyph(self.handle);
    }

    pub fn setGlyphNotFound(self: Buffer, codepoint: u32) void {
        c.hb_buffer_set_not_found_glyph(self.handle, codepoint);
    }

    pub fn getReplacementCodepoint(self: Buffer) u32 {
        return c.hb_buffer_get_replacement_codepoint(self.handle);
    }

    pub fn setReplacementCodepoint(self: Buffer, codepoint: u32) void {
        c.hb_buffer_set_replacement_codepoint(self.handle, codepoint);
    }

    pub fn normalizeGlyphs(self: Buffer) void {
        c.hb_buffer_normalize_glyphs(self.handle);
    }

    pub fn reverse(self: Buffer) void {
        c.hb_buffer_reverse(self.handle);
    }

    pub fn reverseRange(self: Buffer, start: u32, end: u32) void {
        c.hb_buffer_reverse_range(self.handle, start, end);
    }

    pub fn reverseClusters(self: Buffer) void {
        c.hb_buffer_reverse_clusters(self.handle);
    }

    pub fn diff(self: Buffer, ref: Buffer, dottedcircle_glyph: u32, position_fuzz: u32) DiffFlags {
        return @bitCast(DiffFlags, c.hb_buffer_diff(self.handle, ref.handle, dottedcircle_glyph, position_fuzz));
    }
};

pub extern fn hb_glyph_info_get_glyph_flags(info: [*c]const GlyphInfo) c.hb_glyph_flags_t;
pub extern fn hb_buffer_get_glyph_infos(buffer: ?*c.hb_buffer_t, length: [*c]c_uint) [*c]GlyphInfo;
pub extern fn hb_buffer_get_glyph_positions(buffer: ?*c.hb_buffer_t, length: [*c]c_uint) [*c]Position;
