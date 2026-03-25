const std = @import("std");
const c = @cImport({
    @cInclude("opusfile.h");
    @cInclude("opusenc.h");
});

const Opus = @This();

channels: u8,
sample_rate: u24,
samples: []align(alignment) f32,

/// The length of a @Vector(len, f32) used for SIMD audio buffers.
pub const simd_vector_length = std.simd.suggestVectorLength(f32) orelse 1;

pub const alignment = simd_vector_length * @sizeOf(f32);

pub const DecodeError = error{
    OutOfMemory,
    InvalidData,
    Internal,
    Reading,
    Seeking,
    Unknown,
};

pub fn decodeStream(
    allocator: std.mem.Allocator,
    stream: std.io.StreamSource,
) (DecodeError || std.io.StreamSource.ReadError)!Opus {
    var decoder = Decoder{ .allocator = allocator, .stream = stream };
    var err: c_int = 0;
    const opus_file = c.op_open_callbacks(
        &decoder,
        &c.OpusFileCallbacks{
            .read = Decoder.readCallback,
            .seek = Decoder.seekCallback,
            .tell = Decoder.tellCallback,
            .close = Decoder.closeCallback,
        },
        null,
        0,
        &err,
    );
    switch (err) {
        0 => {},
        // An underlying read operation failed. This may signal a truncation attack from an <https:> source.
        c.OP_EREAD => return error.Reading,
        // An internal memory allocation failed.
        c.OP_EFAULT => return error.OutOfMemory,
        // An unseekable stream encountered a new link that used a feature that is not implemented, such as an unsupported channel family.
        c.OP_EIMPL => return error.Internal,
        // The stream was only partially open.
        c.OP_EINVAL => return error.InvalidData,
        // An unseekable stream encountered a new link that did not have any logical Opus streams in it.
        c.OP_ENOTFORMAT => return error.InvalidData,
        // An unseekable stream encountered a new link with a required header packet that was not properly formatted, contained illegal values, or was missing altogether.
        c.OP_EBADHEADER => return error.InvalidData,
        // An unseekable stream encountered a new link with an ID header that contained an unrecognized version number.
        c.OP_EVERSION => return error.InvalidData,
        // We failed to find data we had seen before.
        c.OP_EBADLINK => return error.Seeking,
        // An unseekable stream encountered a new link with a starting timestamp that failed basic validity checks.
        c.OP_EBADTIMESTAMP => return error.InvalidData,
        else => return error.Unknown,
    }
    defer c.op_free(opus_file);

    const header = c.op_head(opus_file, 0);
    const channels: u8 = @intCast(header.*.channel_count);
    const sample_rate: u24 = @intCast(header.*.input_sample_rate);
    const total_samples: usize = @intCast(c.op_pcm_total(opus_file, -1));
    var samples = try allocator.alignedAlloc(f32, alignment, total_samples * channels);
    errdefer allocator.free(samples);

    var i: usize = 0;
    while (i < samples.len) {
        const read = c.op_read_float(opus_file, samples[i..].ptr, @intCast(samples.len - i), null);
        if (read == 0) break else if (read < 0) return error.InvalidData;
        i += @intCast(read * channels);
    }

    return .{
        .channels = channels,
        .sample_rate = sample_rate,
        .samples = samples,
    };
}

const Decoder = struct {
    allocator: std.mem.Allocator,
    stream: std.io.StreamSource,
    samples: []f32 = &.{},
    sample_index: usize = 0,

    fn readCallback(decoder_opaque: ?*anyopaque, ptr: [*c]u8, nbytes: c_int) callconv(.C) c_int {
        const decoder: *Decoder = @ptrCast(@alignCast(decoder_opaque));
        const read = decoder.stream.read(ptr[0..@intCast(nbytes)]) catch return -1;
        return @intCast(read);
    }

    fn seekCallback(decoder_opaque: ?*anyopaque, offset: i64, whence: c_int) callconv(.C) c_int {
        const decoder: *Decoder = @ptrCast(@alignCast(decoder_opaque));
        switch (whence) {
            c.SEEK_SET => decoder.stream.seekTo(@intCast(offset)) catch return -1,
            c.SEEK_CUR => decoder.stream.seekBy(offset) catch return -1,
            c.SEEK_END => decoder.stream.seekTo(decoder.stream.getEndPos() catch return -1) catch return -1,
            else => unreachable,
        }
        return 0;
    }

    fn tellCallback(decoder_opaque: ?*anyopaque) callconv(.C) i64 {
        const decoder: *Decoder = @ptrCast(@alignCast(decoder_opaque));
        const pos = decoder.stream.getPos() catch unreachable;
        return @intCast(pos);
    }

    fn closeCallback(decoder_opaque: ?*anyopaque) callconv(.C) c_int {
        _ = decoder_opaque;
        return 0;
    }
};

pub const Comments = struct {
    opus_comments: *c.OggOpusComments,

    pub fn init() error{OutOfMemory}!Comments {
        const comments = c.ope_comments_create() orelse return error.OutOfMemory;
        return .{ .opus_comments = comments };
    }

    pub fn deinit(comments: Comments) void {
        c.ope_comments_destroy(comments.opus_comments);
    }

    pub fn addString(comments: Comments, tag: [*:0]const u8, value: [*:0]const u8) error{OutOfMemory}!void {
        const err = c.ope_comments_add(comments.opus_comments, tag, value);
        if (err != c.OPE_OK) return error.OutOfMemory;
    }

    pub const PictureType = enum(u5) {
        other = 0,
        /// PNG Only
        icon_32x32 = 1,
        icon_other = 2,
        cover_front = 3,
        cover_back = 4,
        leaflet_page = 5,
        /// (e.g. label side of CD)
        media = 6,
        /// Lead performer/soloist
        lead_artist = 7,
        /// Artist/Performer
        artist = 8,
        conductor = 9,
        /// Band/Orchestra
        band = 10,
        composer = 11,
        lyricist = 12,
        recording_location = 13,
        during_recording = 14,
        during_performance = 15,
        video_screen_capture = 16,
        a_bright_colored_fish = 17,
        illustration = 18,
        artist_logotype = 19,
        /// Publisher/Studio logoType
        publisher_logotype = 20,
    };

    pub fn addPicture(
        comments: Comments,
        image: []const u8,
        picture_type: PictureType,
        description: [*:0]const u8,
    ) error{OutOfMemory}!void {
        const err = c.ope_comments_add_picture_from_memory(
            comments.opus_comments,
            image.ptr,
            image.len,
            @intFromEnum(picture_type),
            description,
        );
        if (err != c.OPE_OK) return error.OutOfMemory;
    }
};

pub const EncodeError = error{
    OutOfMemory,
    InvalidPicture,
    InvalidIcon,
    Writing,
    Internal,
    Unknown,
};

pub const ChannelMapping = enum(u1) {
    mono_stereo = 0,
    surround = 1,
};

pub fn encodeStream(
    stream: std.io.StreamSource,
    comments: Comments,
    sample_rate: u24,
    channels: u24,
    channel_mapping: ChannelMapping,
    samples: []const f32,
) (EncodeError || std.io.StreamSource.ReadError)!void {
    var encoder = Encoder{ .stream = stream };
    var err: c_int = 0;
    const ope_encoder = c.ope_encoder_create_callbacks(
        &c.OpusEncCallbacks{
            .write = Encoder.writeCallback,
            .close = Encoder.closeCallback,
        },
        &encoder,
        comments.opus_comments,
        sample_rate,
        channels,
        @intFromEnum(channel_mapping),
        &err,
    );
    try checkEncoderErr(err);
    defer c.ope_encoder_destroy(ope_encoder);

    try checkEncoderErr(c.ope_encoder_flush_header(ope_encoder));
    try checkEncoderErr(c.ope_encoder_write_float(ope_encoder, samples.ptr, @intCast(samples.len / channels)));
    try checkEncoderErr(c.ope_encoder_drain(ope_encoder));
}

const Encoder = struct {
    stream: std.io.StreamSource,

    fn writeCallback(encoder_opaque: ?*anyopaque, ptr: [*c]const u8, len: i32) callconv(.C) c_int {
        const encoder: *Encoder = @ptrCast(@alignCast(encoder_opaque));
        _ = encoder.stream.write(ptr[0..@intCast(len)]) catch return 1;
        return 0;
    }

    fn closeCallback(encoder_opaque: ?*anyopaque) callconv(.C) c_int {
        _ = encoder_opaque;
        return 0;
    }
};

fn checkEncoderErr(err: c_int) EncodeError!void {
    return switch (err) {
        c.OPE_OK => {},
        c.OPE_BAD_ARG => unreachable,
        c.OPE_INTERNAL_ERROR => error.Internal,
        c.OPE_UNIMPLEMENTED => error.Internal,
        c.OPE_ALLOC_FAIL => error.OutOfMemory,
        c.OPE_CANNOT_OPEN => unreachable,
        c.OPE_TOO_LATE => unreachable,
        c.OPE_INVALID_PICTURE => error.InvalidPicture,
        c.OPE_INVALID_ICON => error.InvalidIcon,
        c.OPE_WRITE_FAIL => error.Writing,
        c.OPE_CLOSE_FAIL => unreachable,
        else => error.Unknown,
    };
}
