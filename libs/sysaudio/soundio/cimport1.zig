pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub const SoundIoErrorNone: c_int = 0;
pub const SoundIoErrorNoMem: c_int = 1;
pub const SoundIoErrorInitAudioBackend: c_int = 2;
pub const SoundIoErrorSystemResources: c_int = 3;
pub const SoundIoErrorOpeningDevice: c_int = 4;
pub const SoundIoErrorNoSuchDevice: c_int = 5;
pub const SoundIoErrorInvalid: c_int = 6;
pub const SoundIoErrorBackendUnavailable: c_int = 7;
pub const SoundIoErrorStreaming: c_int = 8;
pub const SoundIoErrorIncompatibleDevice: c_int = 9;
pub const SoundIoErrorNoSuchClient: c_int = 10;
pub const SoundIoErrorIncompatibleBackend: c_int = 11;
pub const SoundIoErrorBackendDisconnected: c_int = 12;
pub const SoundIoErrorInterrupted: c_int = 13;
pub const SoundIoErrorUnderflow: c_int = 14;
pub const SoundIoErrorEncodingString: c_int = 15;
pub const enum_SoundIoError = c_uint;
pub const SoundIoChannelIdInvalid: c_int = 0;
pub const SoundIoChannelIdFrontLeft: c_int = 1;
pub const SoundIoChannelIdFrontRight: c_int = 2;
pub const SoundIoChannelIdFrontCenter: c_int = 3;
pub const SoundIoChannelIdLfe: c_int = 4;
pub const SoundIoChannelIdBackLeft: c_int = 5;
pub const SoundIoChannelIdBackRight: c_int = 6;
pub const SoundIoChannelIdFrontLeftCenter: c_int = 7;
pub const SoundIoChannelIdFrontRightCenter: c_int = 8;
pub const SoundIoChannelIdBackCenter: c_int = 9;
pub const SoundIoChannelIdSideLeft: c_int = 10;
pub const SoundIoChannelIdSideRight: c_int = 11;
pub const SoundIoChannelIdTopCenter: c_int = 12;
pub const SoundIoChannelIdTopFrontLeft: c_int = 13;
pub const SoundIoChannelIdTopFrontCenter: c_int = 14;
pub const SoundIoChannelIdTopFrontRight: c_int = 15;
pub const SoundIoChannelIdTopBackLeft: c_int = 16;
pub const SoundIoChannelIdTopBackCenter: c_int = 17;
pub const SoundIoChannelIdTopBackRight: c_int = 18;
pub const SoundIoChannelIdBackLeftCenter: c_int = 19;
pub const SoundIoChannelIdBackRightCenter: c_int = 20;
pub const SoundIoChannelIdFrontLeftWide: c_int = 21;
pub const SoundIoChannelIdFrontRightWide: c_int = 22;
pub const SoundIoChannelIdFrontLeftHigh: c_int = 23;
pub const SoundIoChannelIdFrontCenterHigh: c_int = 24;
pub const SoundIoChannelIdFrontRightHigh: c_int = 25;
pub const SoundIoChannelIdTopFrontLeftCenter: c_int = 26;
pub const SoundIoChannelIdTopFrontRightCenter: c_int = 27;
pub const SoundIoChannelIdTopSideLeft: c_int = 28;
pub const SoundIoChannelIdTopSideRight: c_int = 29;
pub const SoundIoChannelIdLeftLfe: c_int = 30;
pub const SoundIoChannelIdRightLfe: c_int = 31;
pub const SoundIoChannelIdLfe2: c_int = 32;
pub const SoundIoChannelIdBottomCenter: c_int = 33;
pub const SoundIoChannelIdBottomLeftCenter: c_int = 34;
pub const SoundIoChannelIdBottomRightCenter: c_int = 35;
pub const SoundIoChannelIdMsMid: c_int = 36;
pub const SoundIoChannelIdMsSide: c_int = 37;
pub const SoundIoChannelIdAmbisonicW: c_int = 38;
pub const SoundIoChannelIdAmbisonicX: c_int = 39;
pub const SoundIoChannelIdAmbisonicY: c_int = 40;
pub const SoundIoChannelIdAmbisonicZ: c_int = 41;
pub const SoundIoChannelIdXyX: c_int = 42;
pub const SoundIoChannelIdXyY: c_int = 43;
pub const SoundIoChannelIdHeadphonesLeft: c_int = 44;
pub const SoundIoChannelIdHeadphonesRight: c_int = 45;
pub const SoundIoChannelIdClickTrack: c_int = 46;
pub const SoundIoChannelIdForeignLanguage: c_int = 47;
pub const SoundIoChannelIdHearingImpaired: c_int = 48;
pub const SoundIoChannelIdNarration: c_int = 49;
pub const SoundIoChannelIdHaptic: c_int = 50;
pub const SoundIoChannelIdDialogCentricMix: c_int = 51;
pub const SoundIoChannelIdAux: c_int = 52;
pub const SoundIoChannelIdAux0: c_int = 53;
pub const SoundIoChannelIdAux1: c_int = 54;
pub const SoundIoChannelIdAux2: c_int = 55;
pub const SoundIoChannelIdAux3: c_int = 56;
pub const SoundIoChannelIdAux4: c_int = 57;
pub const SoundIoChannelIdAux5: c_int = 58;
pub const SoundIoChannelIdAux6: c_int = 59;
pub const SoundIoChannelIdAux7: c_int = 60;
pub const SoundIoChannelIdAux8: c_int = 61;
pub const SoundIoChannelIdAux9: c_int = 62;
pub const SoundIoChannelIdAux10: c_int = 63;
pub const SoundIoChannelIdAux11: c_int = 64;
pub const SoundIoChannelIdAux12: c_int = 65;
pub const SoundIoChannelIdAux13: c_int = 66;
pub const SoundIoChannelIdAux14: c_int = 67;
pub const SoundIoChannelIdAux15: c_int = 68;
pub const enum_SoundIoChannelId = c_uint;
pub const SoundIoChannelLayoutIdMono: c_int = 0;
pub const SoundIoChannelLayoutIdStereo: c_int = 1;
pub const SoundIoChannelLayoutId2Point1: c_int = 2;
pub const SoundIoChannelLayoutId3Point0: c_int = 3;
pub const SoundIoChannelLayoutId3Point0Back: c_int = 4;
pub const SoundIoChannelLayoutId3Point1: c_int = 5;
pub const SoundIoChannelLayoutId4Point0: c_int = 6;
pub const SoundIoChannelLayoutIdQuad: c_int = 7;
pub const SoundIoChannelLayoutIdQuadSide: c_int = 8;
pub const SoundIoChannelLayoutId4Point1: c_int = 9;
pub const SoundIoChannelLayoutId5Point0Back: c_int = 10;
pub const SoundIoChannelLayoutId5Point0Side: c_int = 11;
pub const SoundIoChannelLayoutId5Point1: c_int = 12;
pub const SoundIoChannelLayoutId5Point1Back: c_int = 13;
pub const SoundIoChannelLayoutId6Point0Side: c_int = 14;
pub const SoundIoChannelLayoutId6Point0Front: c_int = 15;
pub const SoundIoChannelLayoutIdHexagonal: c_int = 16;
pub const SoundIoChannelLayoutId6Point1: c_int = 17;
pub const SoundIoChannelLayoutId6Point1Back: c_int = 18;
pub const SoundIoChannelLayoutId6Point1Front: c_int = 19;
pub const SoundIoChannelLayoutId7Point0: c_int = 20;
pub const SoundIoChannelLayoutId7Point0Front: c_int = 21;
pub const SoundIoChannelLayoutId7Point1: c_int = 22;
pub const SoundIoChannelLayoutId7Point1Wide: c_int = 23;
pub const SoundIoChannelLayoutId7Point1WideBack: c_int = 24;
pub const SoundIoChannelLayoutIdOctagonal: c_int = 25;
pub const enum_SoundIoChannelLayoutId = c_uint;
pub const SoundIoBackendNone: c_int = 0;
pub const SoundIoBackendJack: c_int = 1;
pub const SoundIoBackendPulseAudio: c_int = 2;
pub const SoundIoBackendAlsa: c_int = 3;
pub const SoundIoBackendCoreAudio: c_int = 4;
pub const SoundIoBackendWasapi: c_int = 5;
pub const SoundIoBackendDummy: c_int = 6;
pub const enum_SoundIoBackend = c_uint;
pub const SoundIoDeviceAimInput: c_int = 0;
pub const SoundIoDeviceAimOutput: c_int = 1;
pub const enum_SoundIoDeviceAim = c_uint;
pub const SoundIoFormatInvalid: c_int = 0;
pub const SoundIoFormatS8: c_int = 1;
pub const SoundIoFormatU8: c_int = 2;
pub const SoundIoFormatS16LE: c_int = 3;
pub const SoundIoFormatS16BE: c_int = 4;
pub const SoundIoFormatU16LE: c_int = 5;
pub const SoundIoFormatU16BE: c_int = 6;
pub const SoundIoFormatS24LE: c_int = 7;
pub const SoundIoFormatS24BE: c_int = 8;
pub const SoundIoFormatU24LE: c_int = 9;
pub const SoundIoFormatU24BE: c_int = 10;
pub const SoundIoFormatS32LE: c_int = 11;
pub const SoundIoFormatS32BE: c_int = 12;
pub const SoundIoFormatU32LE: c_int = 13;
pub const SoundIoFormatU32BE: c_int = 14;
pub const SoundIoFormatFloat32LE: c_int = 15;
pub const SoundIoFormatFloat32BE: c_int = 16;
pub const SoundIoFormatFloat64LE: c_int = 17;
pub const SoundIoFormatFloat64BE: c_int = 18;
pub const enum_SoundIoFormat = c_uint;
pub const struct_SoundIoChannelLayout = extern struct {
    name: [*c]const u8,
    channel_count: c_int,
    channels: [24]enum_SoundIoChannelId,
};
pub const struct_SoundIoSampleRateRange = extern struct {
    min: c_int,
    max: c_int,
};
pub const struct_SoundIoChannelArea = extern struct {
    ptr: [*c]u8,
    step: c_int,
};
pub const struct_SoundIo = extern struct {
    userdata: ?*anyopaque,
    on_devices_change: ?*const fn ([*c]struct_SoundIo) callconv(.C) void,
    on_backend_disconnect: ?*const fn ([*c]struct_SoundIo, c_int) callconv(.C) void,
    on_events_signal: ?*const fn ([*c]struct_SoundIo) callconv(.C) void,
    current_backend: enum_SoundIoBackend,
    app_name: [*c]const u8,
    emit_rtprio_warning: ?*const fn () callconv(.C) void,
    jack_info_callback: ?*const fn ([*c]const u8) callconv(.C) void,
    jack_error_callback: ?*const fn ([*c]const u8) callconv(.C) void,
};
pub const struct_SoundIoDevice = extern struct {
    soundio: [*c]struct_SoundIo,
    id: [*c]u8,
    name: [*c]u8,
    aim: enum_SoundIoDeviceAim,
    layouts: [*c]struct_SoundIoChannelLayout,
    layout_count: c_int,
    current_layout: struct_SoundIoChannelLayout,
    formats: [*c]enum_SoundIoFormat,
    format_count: c_int,
    current_format: enum_SoundIoFormat,
    sample_rates: [*c]struct_SoundIoSampleRateRange,
    sample_rate_count: c_int,
    sample_rate_current: c_int,
    software_latency_min: f64,
    software_latency_max: f64,
    software_latency_current: f64,
    is_raw: bool,
    ref_count: c_int,
    probe_error: c_int,
};
pub const struct_SoundIoOutStream = extern struct {
    device: [*c]struct_SoundIoDevice,
    format: enum_SoundIoFormat,
    sample_rate: c_int,
    layout: struct_SoundIoChannelLayout,
    software_latency: f64,
    volume: f32,
    userdata: ?*anyopaque,
    write_callback: ?*const fn ([*c]struct_SoundIoOutStream, c_int, c_int) callconv(.C) void,
    underflow_callback: ?*const fn ([*c]struct_SoundIoOutStream) callconv(.C) void,
    error_callback: ?*const fn ([*c]struct_SoundIoOutStream, c_int) callconv(.C) void,
    name: [*c]const u8,
    non_terminal_hint: bool,
    bytes_per_frame: c_int,
    bytes_per_sample: c_int,
    layout_error: c_int,
};
pub const struct_SoundIoInStream = extern struct {
    device: [*c]struct_SoundIoDevice,
    format: enum_SoundIoFormat,
    sample_rate: c_int,
    layout: struct_SoundIoChannelLayout,
    software_latency: f64,
    userdata: ?*anyopaque,
    read_callback: ?*const fn ([*c]struct_SoundIoInStream, c_int, c_int) callconv(.C) void,
    overflow_callback: ?*const fn ([*c]struct_SoundIoInStream) callconv(.C) void,
    error_callback: ?*const fn ([*c]struct_SoundIoInStream, c_int) callconv(.C) void,
    name: [*c]const u8,
    non_terminal_hint: bool,
    bytes_per_frame: c_int,
    bytes_per_sample: c_int,
    layout_error: c_int,
};
pub extern fn soundio_version_string() [*c]const u8;
pub extern fn soundio_version_major() c_int;
pub extern fn soundio_version_minor() c_int;
pub extern fn soundio_version_patch() c_int;
pub extern fn soundio_create() [*c]struct_SoundIo;
pub extern fn soundio_destroy(soundio: [*c]struct_SoundIo) void;
pub extern fn soundio_connect(soundio: [*c]struct_SoundIo) c_int;
pub extern fn soundio_connect_backend(soundio: [*c]struct_SoundIo, backend: enum_SoundIoBackend) c_int;
pub extern fn soundio_disconnect(soundio: [*c]struct_SoundIo) void;
pub extern fn soundio_strerror(@"error": c_int) [*c]const u8;
pub extern fn soundio_backend_name(backend: enum_SoundIoBackend) [*c]const u8;
pub extern fn soundio_backend_count(soundio: [*c]struct_SoundIo) c_int;
pub extern fn soundio_get_backend(soundio: [*c]struct_SoundIo, index: c_int) enum_SoundIoBackend;
pub extern fn soundio_have_backend(backend: enum_SoundIoBackend) bool;
pub extern fn soundio_flush_events(soundio: [*c]struct_SoundIo) void;
pub extern fn soundio_wait_events(soundio: [*c]struct_SoundIo) void;
pub extern fn soundio_wakeup(soundio: [*c]struct_SoundIo) void;
pub extern fn soundio_force_device_scan(soundio: [*c]struct_SoundIo) void;
pub extern fn soundio_channel_layout_equal(a: [*c]const struct_SoundIoChannelLayout, b: [*c]const struct_SoundIoChannelLayout) bool;
pub extern fn soundio_get_channel_name(id: enum_SoundIoChannelId) [*c]const u8;
pub extern fn soundio_parse_channel_id(str: [*c]const u8, str_len: c_int) enum_SoundIoChannelId;
pub extern fn soundio_channel_layout_builtin_count() c_int;
pub extern fn soundio_channel_layout_get_builtin(index: c_int) [*c]const struct_SoundIoChannelLayout;
pub extern fn soundio_channel_layout_get_default(channel_count: c_int) [*c]const struct_SoundIoChannelLayout;
pub extern fn soundio_channel_layout_find_channel(layout: [*c]const struct_SoundIoChannelLayout, channel: enum_SoundIoChannelId) c_int;
pub extern fn soundio_channel_layout_detect_builtin(layout: [*c]struct_SoundIoChannelLayout) bool;
pub extern fn soundio_best_matching_channel_layout(preferred_layouts: [*c]const struct_SoundIoChannelLayout, preferred_layout_count: c_int, available_layouts: [*c]const struct_SoundIoChannelLayout, available_layout_count: c_int) [*c]const struct_SoundIoChannelLayout;
pub extern fn soundio_sort_channel_layouts(layouts: [*c]struct_SoundIoChannelLayout, layout_count: c_int) void;
pub extern fn soundio_get_bytes_per_sample(format: enum_SoundIoFormat) c_int;
pub fn soundio_get_bytes_per_frame(arg_format: enum_SoundIoFormat, arg_channel_count: c_int) callconv(.C) c_int {
    var format = arg_format;
    var channel_count = arg_channel_count;
    return soundio_get_bytes_per_sample(format) * channel_count;
}
pub fn soundio_get_bytes_per_second(arg_format: enum_SoundIoFormat, arg_channel_count: c_int, arg_sample_rate: c_int) callconv(.C) c_int {
    var format = arg_format;
    var channel_count = arg_channel_count;
    var sample_rate = arg_sample_rate;
    return soundio_get_bytes_per_frame(format, channel_count) * sample_rate;
}
pub extern fn soundio_format_string(format: enum_SoundIoFormat) [*c]const u8;
pub extern fn soundio_input_device_count(soundio: [*c]struct_SoundIo) c_int;
pub extern fn soundio_output_device_count(soundio: [*c]struct_SoundIo) c_int;
pub extern fn soundio_get_input_device(soundio: [*c]struct_SoundIo, index: c_int) [*c]struct_SoundIoDevice;
pub extern fn soundio_get_output_device(soundio: [*c]struct_SoundIo, index: c_int) [*c]struct_SoundIoDevice;
pub extern fn soundio_get_input_device_from_id(soundio: [*c]struct_SoundIo, id: [*c]const u8, is_raw: bool) [*c]struct_SoundIoDevice;
pub extern fn soundio_get_output_device_from_id(soundio: [*c]struct_SoundIo, id: [*c]const u8, is_raw: bool) [*c]struct_SoundIoDevice;
pub extern fn soundio_default_input_device_index(soundio: [*c]struct_SoundIo) c_int;
pub extern fn soundio_default_output_device_index(soundio: [*c]struct_SoundIo) c_int;
pub extern fn soundio_device_ref(device: [*c]struct_SoundIoDevice) void;
pub extern fn soundio_device_unref(device: [*c]struct_SoundIoDevice) void;
pub extern fn soundio_device_equal(a: [*c]const struct_SoundIoDevice, b: [*c]const struct_SoundIoDevice) bool;
pub extern fn soundio_device_sort_channel_layouts(device: [*c]struct_SoundIoDevice) void;
pub extern fn soundio_device_supports_format(device: [*c]struct_SoundIoDevice, format: enum_SoundIoFormat) bool;
pub extern fn soundio_device_supports_layout(device: [*c]struct_SoundIoDevice, layout: [*c]const struct_SoundIoChannelLayout) bool;
pub extern fn soundio_device_supports_sample_rate(device: [*c]struct_SoundIoDevice, sample_rate: c_int) bool;
pub extern fn soundio_device_nearest_sample_rate(device: [*c]struct_SoundIoDevice, sample_rate: c_int) c_int;
pub extern fn soundio_outstream_create(device: [*c]struct_SoundIoDevice) [*c]struct_SoundIoOutStream;
pub extern fn soundio_outstream_destroy(outstream: [*c]struct_SoundIoOutStream) void;
pub extern fn soundio_outstream_open(outstream: [*c]struct_SoundIoOutStream) c_int;
pub extern fn soundio_outstream_start(outstream: [*c]struct_SoundIoOutStream) c_int;
pub extern fn soundio_outstream_begin_write(outstream: [*c]struct_SoundIoOutStream, areas: [*c][*c]struct_SoundIoChannelArea, frame_count: [*c]c_int) c_int;
pub extern fn soundio_outstream_end_write(outstream: [*c]struct_SoundIoOutStream) c_int;
pub extern fn soundio_outstream_clear_buffer(outstream: [*c]struct_SoundIoOutStream) c_int;
pub extern fn soundio_outstream_pause(outstream: [*c]struct_SoundIoOutStream, pause: bool) c_int;
pub extern fn soundio_outstream_get_latency(outstream: [*c]struct_SoundIoOutStream, out_latency: [*c]f64) c_int;
pub extern fn soundio_outstream_set_volume(outstream: [*c]struct_SoundIoOutStream, volume: f64) c_int;
pub extern fn soundio_instream_create(device: [*c]struct_SoundIoDevice) [*c]struct_SoundIoInStream;
pub extern fn soundio_instream_destroy(instream: [*c]struct_SoundIoInStream) void;
pub extern fn soundio_instream_open(instream: [*c]struct_SoundIoInStream) c_int;
pub extern fn soundio_instream_start(instream: [*c]struct_SoundIoInStream) c_int;
pub extern fn soundio_instream_begin_read(instream: [*c]struct_SoundIoInStream, areas: [*c][*c]struct_SoundIoChannelArea, frame_count: [*c]c_int) c_int;
pub extern fn soundio_instream_end_read(instream: [*c]struct_SoundIoInStream) c_int;
pub extern fn soundio_instream_pause(instream: [*c]struct_SoundIoInStream, pause: bool) c_int;
pub extern fn soundio_instream_get_latency(instream: [*c]struct_SoundIoInStream, out_latency: [*c]f64) c_int;
pub const struct_SoundIoRingBuffer = opaque {};
pub extern fn soundio_ring_buffer_create(soundio: [*c]struct_SoundIo, requested_capacity: c_int) ?*struct_SoundIoRingBuffer;
pub extern fn soundio_ring_buffer_destroy(ring_buffer: ?*struct_SoundIoRingBuffer) void;
pub extern fn soundio_ring_buffer_capacity(ring_buffer: ?*struct_SoundIoRingBuffer) c_int;
pub extern fn soundio_ring_buffer_write_ptr(ring_buffer: ?*struct_SoundIoRingBuffer) [*c]u8;
pub extern fn soundio_ring_buffer_advance_write_ptr(ring_buffer: ?*struct_SoundIoRingBuffer, count: c_int) void;
pub extern fn soundio_ring_buffer_read_ptr(ring_buffer: ?*struct_SoundIoRingBuffer) [*c]u8;
pub extern fn soundio_ring_buffer_advance_read_ptr(ring_buffer: ?*struct_SoundIoRingBuffer, count: c_int) void;
pub extern fn soundio_ring_buffer_fill_count(ring_buffer: ?*struct_SoundIoRingBuffer) c_int;
pub extern fn soundio_ring_buffer_free_count(ring_buffer: ?*struct_SoundIoRingBuffer) c_int;
pub extern fn soundio_ring_buffer_clear(ring_buffer: ?*struct_SoundIoRingBuffer) void;
pub const __block = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):27:9
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`"); // (no file):82:9
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`"); // (no file):88:9
pub const __FLT16_DENORM_MIN__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):111:9
pub const __FLT16_EPSILON__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):115:9
pub const __FLT16_MAX__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):121:9
pub const __FLT16_MIN__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):124:9
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // (no file):184:9
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // (no file):206:9
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // (no file):214:9
pub const __USER_LABEL_PREFIX__ = @compileError("unable to translate macro: undefined identifier `_`"); // (no file):305:9
pub const __nonnull = @compileError("unable to translate macro: undefined identifier `_Nonnull`"); // (no file):337:9
pub const __null_unspecified = @compileError("unable to translate macro: undefined identifier `_Null_unspecified`"); // (no file):338:9
pub const __nullable = @compileError("unable to translate macro: undefined identifier `_Nullable`"); // (no file):339:9
pub const __weak = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):392:9
pub const SOUNDIO_EXPORT = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/hexops/mach/libs/sysaudio/upstream/soundio/soundio/soundio.h:31:11
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 14);
pub const __clang_minor__ = @as(c_int, 0);
pub const __clang_patchlevel__ = @as(c_int, 6);
pub const __clang_version__ = "14.0.6 (git@github.com:ziglang/zig-bootstrap.git dbc902054739800b8c1656dc1fb29571bba074b9)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 14.0.6 (git@github.com:ziglang/zig-bootstrap.git dbc902054739800b8c1656dc1fb29571bba074b9)";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 1);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __BLOCKS__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-32";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @as(c_int, 128);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_FMTd__ = "ld";
pub const __INTMAX_FMTi__ = "li";
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_FMTo__ = "lo";
pub const __UINTMAX_FMTu__ = "lu";
pub const __UINTMAX_FMTx__ = "lx";
pub const __UINTMAX_FMTX__ = "lX";
pub const __PTRDIFF_TYPE__ = c_long;
pub const __PTRDIFF_FMTd__ = "ld";
pub const __PTRDIFF_FMTi__ = "li";
pub const __INTPTR_TYPE__ = c_long;
pub const __INTPTR_FMTd__ = "ld";
pub const __INTPTR_FMTi__ = "li";
pub const __SIZE_TYPE__ = c_ulong;
pub const __SIZE_FMTo__ = "lo";
pub const __SIZE_FMTu__ = "lu";
pub const __SIZE_FMTx__ = "lx";
pub const __SIZE_FMTX__ = "lX";
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_int;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __UINTPTR_FMTo__ = "lo";
pub const __UINTPTR_FMTu__ = "lu";
pub const __UINTPTR_FMTx__ = "lx";
pub const __UINTPTR_FMTX__ = "lX";
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = 4.9406564584124654e-324;
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = 2.2204460492503131e-16;
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = 1.7976931348623157e+308;
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = 2.2250738585072014e-308;
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 4.9406564584124654e-324);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 15);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 2.2204460492503131e-16);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 53);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __LDBL_MAX_EXP__ = @as(c_int, 1024);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.7976931348623157e+308);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __LDBL_MIN__ = @as(c_longdouble, 2.2250738585072014e-308);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 8);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "lld";
pub const __INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_LEAST64_FMTo__ = "llo";
pub const __UINT_LEAST64_FMTu__ = "llu";
pub const __UINT_LEAST64_FMTx__ = "llx";
pub const __UINT_LEAST64_FMTX__ = "llX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "lld";
pub const __INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_FAST64_FMTo__ = "llo";
pub const __UINT_FAST64_FMTu__ = "llu";
pub const __UINT_FAST64_FMTx__ = "llx";
pub const __UINT_FAST64_FMTX__ = "llX";
pub const __NO_MATH_ERRNO__ = @as(c_int, 1);
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __NO_INLINE__ = @as(c_int, 1);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __SSP_STRONG__ = @as(c_int, 2);
pub const __AARCH64EL__ = @as(c_int, 1);
pub const __aarch64__ = @as(c_int, 1);
pub const __AARCH64_CMODEL_SMALL__ = @as(c_int, 1);
pub const __ARM_ACLE = @as(c_int, 200);
pub const __ARM_ARCH = @as(c_int, 8);
pub const __ARM_ARCH_PROFILE = 'A';
pub const __ARM_64BIT_STATE = @as(c_int, 1);
pub const __ARM_PCS_AAPCS64 = @as(c_int, 1);
pub const __ARM_ARCH_ISA_A64 = @as(c_int, 1);
pub const __ARM_FEATURE_CLZ = @as(c_int, 1);
pub const __ARM_FEATURE_FMA = @as(c_int, 1);
pub const __ARM_FEATURE_LDREX = @as(c_int, 0xF);
pub const __ARM_FEATURE_IDIV = @as(c_int, 1);
pub const __ARM_FEATURE_DIV = @as(c_int, 1);
pub const __ARM_FEATURE_NUMERIC_MAXMIN = @as(c_int, 1);
pub const __ARM_FEATURE_DIRECTED_ROUNDING = @as(c_int, 1);
pub const __ARM_ALIGN_MAX_STACK_PWR = @as(c_int, 4);
pub const __ARM_FP = @as(c_int, 0xE);
pub const __ARM_FP16_FORMAT_IEEE = @as(c_int, 1);
pub const __ARM_FP16_ARGS = @as(c_int, 1);
pub const __ARM_SIZEOF_WCHAR_T = @as(c_int, 4);
pub const __ARM_SIZEOF_MINIMAL_ENUM = @as(c_int, 4);
pub const __ARM_NEON = @as(c_int, 1);
pub const __ARM_NEON_FP = @as(c_int, 0xE);
pub const __ARM_FEATURE_CRC32 = @as(c_int, 1);
pub const __ARM_FEATURE_CRYPTO = @as(c_int, 1);
pub const __ARM_FEATURE_AES = @as(c_int, 1);
pub const __ARM_FEATURE_SHA2 = @as(c_int, 1);
pub const __ARM_FEATURE_SHA3 = @as(c_int, 1);
pub const __ARM_FEATURE_SHA512 = @as(c_int, 1);
pub const __ARM_FEATURE_UNALIGNED = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_VECTOR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_SCALAR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_FEATURE_DOTPROD = @as(c_int, 1);
pub const __ARM_FEATURE_ATOMICS = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_FML = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __AARCH64_SIMD__ = @as(c_int, 1);
pub const __ARM64_ARCH_8__ = @as(c_int, 1);
pub const __ARM_NEON__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __arm64 = @as(c_int, 1);
pub const __arm64__ = @as(c_int, 1);
pub const __APPLE_CC__ = @as(c_int, 6000);
pub const __APPLE__ = @as(c_int, 1);
pub const __STDC_NO_THREADS__ = @as(c_int, 1);
pub const __strong = "";
pub const __unsafe_unretained = "";
pub const __DYNAMIC__ = @as(c_int, 1);
pub const __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120100, .decimal);
pub const __MACH__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const _DEBUG = @as(c_int, 1);
pub const __GCC_HAVE_DWARF2_CFI_ASM = @as(c_int, 1);
pub const SOUNDIO_SOUNDIO_H = "";
pub const SOUNDIO_ENDIAN_H = "";
pub const SOUNDIO_OS_LITTLE_ENDIAN = "";
pub const __STDBOOL_H = "";
pub const @"bool" = bool;
pub const @"true" = @as(c_int, 1);
pub const @"false" = @as(c_int, 0);
pub const __bool_true_false_are_defined = @as(c_int, 1);
pub const SOUNDIO_EXTERN_C = "";
pub const SoundIoFormatS16NE = SoundIoFormatS16LE;
pub const SoundIoFormatU16NE = SoundIoFormatU16LE;
pub const SoundIoFormatS24NE = SoundIoFormatS24LE;
pub const SoundIoFormatU24NE = SoundIoFormatU24LE;
pub const SoundIoFormatS32NE = SoundIoFormatS32LE;
pub const SoundIoFormatU32NE = SoundIoFormatU32LE;
pub const SoundIoFormatFloat32NE = SoundIoFormatFloat32LE;
pub const SoundIoFormatFloat64NE = SoundIoFormatFloat64LE;
pub const SoundIoFormatS16FE = SoundIoFormatS16BE;
pub const SoundIoFormatU16FE = SoundIoFormatU16BE;
pub const SoundIoFormatS24FE = SoundIoFormatS24BE;
pub const SoundIoFormatU24FE = SoundIoFormatU24BE;
pub const SoundIoFormatS32FE = SoundIoFormatS32BE;
pub const SoundIoFormatU32FE = SoundIoFormatU32BE;
pub const SoundIoFormatFloat32FE = SoundIoFormatFloat32BE;
pub const SoundIoFormatFloat64FE = SoundIoFormatFloat64BE;
pub const SOUNDIO_MAX_CHANNELS = @as(c_int, 24);
pub const SoundIoError = enum_SoundIoError;
pub const SoundIoChannelId = enum_SoundIoChannelId;
pub const SoundIoChannelLayoutId = enum_SoundIoChannelLayoutId;
pub const SoundIoBackend = enum_SoundIoBackend;
pub const SoundIoDeviceAim = enum_SoundIoDeviceAim;
pub const SoundIoFormat = enum_SoundIoFormat;
pub const SoundIoChannelLayout = struct_SoundIoChannelLayout;
pub const SoundIoSampleRateRange = struct_SoundIoSampleRateRange;
pub const SoundIoChannelArea = struct_SoundIoChannelArea;
pub const SoundIo = struct_SoundIo;
pub const SoundIoDevice = struct_SoundIoDevice;
pub const SoundIoOutStream = struct_SoundIoOutStream;
pub const SoundIoInStream = struct_SoundIoInStream;
pub const SoundIoRingBuffer = struct_SoundIoRingBuffer;
