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
pub const int_least8_t = i8;
pub const int_least16_t = i16;
pub const int_least32_t = i32;
pub const int_least64_t = i64;
pub const uint_least8_t = u8;
pub const uint_least16_t = u16;
pub const uint_least32_t = u32;
pub const uint_least64_t = u64;
pub const int_fast8_t = i8;
pub const int_fast16_t = i16;
pub const int_fast32_t = i32;
pub const int_fast64_t = i64;
pub const uint_fast8_t = u8;
pub const uint_fast16_t = u16;
pub const uint_fast32_t = u32;
pub const uint_fast64_t = u64;
pub const __int8_t = i8;
pub const __uint8_t = u8;
pub const __int16_t = c_short;
pub const __uint16_t = c_ushort;
pub const __int32_t = c_int;
pub const __uint32_t = c_uint;
pub const __int64_t = c_longlong;
pub const __uint64_t = c_ulonglong;
pub const __darwin_intptr_t = c_long;
pub const __darwin_natural_t = c_uint;
pub const __darwin_ct_rune_t = c_int;
pub const __mbstate_t = extern union {
    __mbstate8: [128]u8,
    _mbstateL: c_longlong,
};
pub const __darwin_mbstate_t = __mbstate_t;
pub const __darwin_ptrdiff_t = c_long;
pub const __darwin_size_t = c_ulong;
pub const __builtin_va_list = [*c]u8;
pub const __darwin_va_list = __builtin_va_list;
pub const __darwin_wchar_t = c_int;
pub const __darwin_rune_t = __darwin_wchar_t;
pub const __darwin_wint_t = c_int;
pub const __darwin_clock_t = c_ulong;
pub const __darwin_socklen_t = __uint32_t;
pub const __darwin_ssize_t = c_long;
pub const __darwin_time_t = c_long;
pub const __darwin_blkcnt_t = __int64_t;
pub const __darwin_blksize_t = __int32_t;
pub const __darwin_dev_t = __int32_t;
pub const __darwin_fsblkcnt_t = c_uint;
pub const __darwin_fsfilcnt_t = c_uint;
pub const __darwin_gid_t = __uint32_t;
pub const __darwin_id_t = __uint32_t;
pub const __darwin_ino64_t = __uint64_t;
pub const __darwin_ino_t = __darwin_ino64_t;
pub const __darwin_mach_port_name_t = __darwin_natural_t;
pub const __darwin_mach_port_t = __darwin_mach_port_name_t;
pub const __darwin_mode_t = __uint16_t;
pub const __darwin_off_t = __int64_t;
pub const __darwin_pid_t = __int32_t;
pub const __darwin_sigset_t = __uint32_t;
pub const __darwin_suseconds_t = __int32_t;
pub const __darwin_uid_t = __uint32_t;
pub const __darwin_useconds_t = __uint32_t;
pub const __darwin_uuid_t = [16]u8;
pub const __darwin_uuid_string_t = [37]u8;
pub const struct___darwin_pthread_handler_rec = extern struct {
    __routine: ?*const fn (?*anyopaque) callconv(.C) void,
    __arg: ?*anyopaque,
    __next: [*c]struct___darwin_pthread_handler_rec,
};
pub const struct__opaque_pthread_attr_t = extern struct {
    __sig: c_long,
    __opaque: [56]u8,
};
pub const struct__opaque_pthread_cond_t = extern struct {
    __sig: c_long,
    __opaque: [40]u8,
};
pub const struct__opaque_pthread_condattr_t = extern struct {
    __sig: c_long,
    __opaque: [8]u8,
};
pub const struct__opaque_pthread_mutex_t = extern struct {
    __sig: c_long,
    __opaque: [56]u8,
};
pub const struct__opaque_pthread_mutexattr_t = extern struct {
    __sig: c_long,
    __opaque: [8]u8,
};
pub const struct__opaque_pthread_once_t = extern struct {
    __sig: c_long,
    __opaque: [8]u8,
};
pub const struct__opaque_pthread_rwlock_t = extern struct {
    __sig: c_long,
    __opaque: [192]u8,
};
pub const struct__opaque_pthread_rwlockattr_t = extern struct {
    __sig: c_long,
    __opaque: [16]u8,
};
pub const struct__opaque_pthread_t = extern struct {
    __sig: c_long,
    __cleanup_stack: [*c]struct___darwin_pthread_handler_rec,
    __opaque: [8176]u8,
};
pub const __darwin_pthread_attr_t = struct__opaque_pthread_attr_t;
pub const __darwin_pthread_cond_t = struct__opaque_pthread_cond_t;
pub const __darwin_pthread_condattr_t = struct__opaque_pthread_condattr_t;
pub const __darwin_pthread_key_t = c_ulong;
pub const __darwin_pthread_mutex_t = struct__opaque_pthread_mutex_t;
pub const __darwin_pthread_mutexattr_t = struct__opaque_pthread_mutexattr_t;
pub const __darwin_pthread_once_t = struct__opaque_pthread_once_t;
pub const __darwin_pthread_rwlock_t = struct__opaque_pthread_rwlock_t;
pub const __darwin_pthread_rwlockattr_t = struct__opaque_pthread_rwlockattr_t;
pub const __darwin_pthread_t = [*c]struct__opaque_pthread_t;
pub const u_int8_t = u8;
pub const u_int16_t = c_ushort;
pub const u_int32_t = c_uint;
pub const u_int64_t = c_ulonglong;
pub const register_t = i64;
pub const user_addr_t = u_int64_t;
pub const user_size_t = u_int64_t;
pub const user_ssize_t = i64;
pub const user_long_t = i64;
pub const user_ulong_t = u_int64_t;
pub const user_time_t = i64;
pub const user_off_t = i64;
pub const syscall_arg_t = u_int64_t;
pub const intmax_t = c_long;
pub const uintmax_t = c_ulong;
pub const hb_bool_t = c_int;
pub const hb_codepoint_t = u32;
pub const hb_position_t = i32;
pub const hb_mask_t = u32;
pub const union__hb_var_int_t = extern union {
    u32: u32,
    i32: i32,
    u16: [2]u16,
    i16: [2]i16,
    u8: [4]u8,
    i8: [4]i8,
};
pub const hb_var_int_t = union__hb_var_int_t;
pub const union__hb_var_num_t = extern union {
    f: f32,
    u32: u32,
    i32: i32,
    u16: [2]u16,
    i16: [2]i16,
    u8: [4]u8,
    i8: [4]i8,
};
pub const hb_var_num_t = union__hb_var_num_t;
pub const hb_tag_t = u32;
pub extern fn hb_tag_from_string(str: [*c]const u8, len: c_int) hb_tag_t;
pub extern fn hb_tag_to_string(tag: hb_tag_t, buf: [*c]u8) void;
pub const HB_DIRECTION_INVALID: c_int = 0;
pub const HB_DIRECTION_LTR: c_int = 4;
pub const HB_DIRECTION_RTL: c_int = 5;
pub const HB_DIRECTION_TTB: c_int = 6;
pub const HB_DIRECTION_BTT: c_int = 7;
pub const hb_direction_t = c_uint;
pub extern fn hb_direction_from_string(str: [*c]const u8, len: c_int) hb_direction_t;
pub extern fn hb_direction_to_string(direction: hb_direction_t) [*c]const u8;
pub const struct_hb_language_impl_t = opaque {};
pub const hb_language_t = ?*const struct_hb_language_impl_t;
pub extern fn hb_language_from_string(str: [*c]const u8, len: c_int) hb_language_t;
pub extern fn hb_language_to_string(language: hb_language_t) [*c]const u8;
pub extern fn hb_language_get_default() hb_language_t;
pub const HB_SCRIPT_COMMON: c_int = 1517910393;
pub const HB_SCRIPT_INHERITED: c_int = 1516858984;
pub const HB_SCRIPT_UNKNOWN: c_int = 1517976186;
pub const HB_SCRIPT_ARABIC: c_int = 1098015074;
pub const HB_SCRIPT_ARMENIAN: c_int = 1098018158;
pub const HB_SCRIPT_BENGALI: c_int = 1113943655;
pub const HB_SCRIPT_CYRILLIC: c_int = 1132032620;
pub const HB_SCRIPT_DEVANAGARI: c_int = 1147500129;
pub const HB_SCRIPT_GEORGIAN: c_int = 1197830002;
pub const HB_SCRIPT_GREEK: c_int = 1198679403;
pub const HB_SCRIPT_GUJARATI: c_int = 1198877298;
pub const HB_SCRIPT_GURMUKHI: c_int = 1198879349;
pub const HB_SCRIPT_HANGUL: c_int = 1214344807;
pub const HB_SCRIPT_HAN: c_int = 1214344809;
pub const HB_SCRIPT_HEBREW: c_int = 1214603890;
pub const HB_SCRIPT_HIRAGANA: c_int = 1214870113;
pub const HB_SCRIPT_KANNADA: c_int = 1265525857;
pub const HB_SCRIPT_KATAKANA: c_int = 1264676449;
pub const HB_SCRIPT_LAO: c_int = 1281453935;
pub const HB_SCRIPT_LATIN: c_int = 1281455214;
pub const HB_SCRIPT_MALAYALAM: c_int = 1298954605;
pub const HB_SCRIPT_ORIYA: c_int = 1332902241;
pub const HB_SCRIPT_TAMIL: c_int = 1415671148;
pub const HB_SCRIPT_TELUGU: c_int = 1415933045;
pub const HB_SCRIPT_THAI: c_int = 1416126825;
pub const HB_SCRIPT_TIBETAN: c_int = 1416192628;
pub const HB_SCRIPT_BOPOMOFO: c_int = 1114599535;
pub const HB_SCRIPT_BRAILLE: c_int = 1114792297;
pub const HB_SCRIPT_CANADIAN_SYLLABICS: c_int = 1130458739;
pub const HB_SCRIPT_CHEROKEE: c_int = 1130915186;
pub const HB_SCRIPT_ETHIOPIC: c_int = 1165256809;
pub const HB_SCRIPT_KHMER: c_int = 1265134962;
pub const HB_SCRIPT_MONGOLIAN: c_int = 1299148391;
pub const HB_SCRIPT_MYANMAR: c_int = 1299803506;
pub const HB_SCRIPT_OGHAM: c_int = 1332175213;
pub const HB_SCRIPT_RUNIC: c_int = 1383427698;
pub const HB_SCRIPT_SINHALA: c_int = 1399418472;
pub const HB_SCRIPT_SYRIAC: c_int = 1400468067;
pub const HB_SCRIPT_THAANA: c_int = 1416126817;
pub const HB_SCRIPT_YI: c_int = 1500080489;
pub const HB_SCRIPT_DESERET: c_int = 1148416628;
pub const HB_SCRIPT_GOTHIC: c_int = 1198486632;
pub const HB_SCRIPT_OLD_ITALIC: c_int = 1232363884;
pub const HB_SCRIPT_BUHID: c_int = 1114990692;
pub const HB_SCRIPT_HANUNOO: c_int = 1214344815;
pub const HB_SCRIPT_TAGALOG: c_int = 1416064103;
pub const HB_SCRIPT_TAGBANWA: c_int = 1415669602;
pub const HB_SCRIPT_CYPRIOT: c_int = 1131442804;
pub const HB_SCRIPT_LIMBU: c_int = 1281977698;
pub const HB_SCRIPT_LINEAR_B: c_int = 1281977954;
pub const HB_SCRIPT_OSMANYA: c_int = 1332964705;
pub const HB_SCRIPT_SHAVIAN: c_int = 1399349623;
pub const HB_SCRIPT_TAI_LE: c_int = 1415670885;
pub const HB_SCRIPT_UGARITIC: c_int = 1432838514;
pub const HB_SCRIPT_BUGINESE: c_int = 1114990441;
pub const HB_SCRIPT_COPTIC: c_int = 1131376756;
pub const HB_SCRIPT_GLAGOLITIC: c_int = 1198285159;
pub const HB_SCRIPT_KHAROSHTHI: c_int = 1265131890;
pub const HB_SCRIPT_NEW_TAI_LUE: c_int = 1415670901;
pub const HB_SCRIPT_OLD_PERSIAN: c_int = 1483761007;
pub const HB_SCRIPT_SYLOTI_NAGRI: c_int = 1400466543;
pub const HB_SCRIPT_TIFINAGH: c_int = 1415999079;
pub const HB_SCRIPT_BALINESE: c_int = 1113681001;
pub const HB_SCRIPT_CUNEIFORM: c_int = 1483961720;
pub const HB_SCRIPT_NKO: c_int = 1315663727;
pub const HB_SCRIPT_PHAGS_PA: c_int = 1349017959;
pub const HB_SCRIPT_PHOENICIAN: c_int = 1349021304;
pub const HB_SCRIPT_CARIAN: c_int = 1130459753;
pub const HB_SCRIPT_CHAM: c_int = 1130914157;
pub const HB_SCRIPT_KAYAH_LI: c_int = 1264675945;
pub const HB_SCRIPT_LEPCHA: c_int = 1281716323;
pub const HB_SCRIPT_LYCIAN: c_int = 1283023721;
pub const HB_SCRIPT_LYDIAN: c_int = 1283023977;
pub const HB_SCRIPT_OL_CHIKI: c_int = 1332503403;
pub const HB_SCRIPT_REJANG: c_int = 1382706791;
pub const HB_SCRIPT_SAURASHTRA: c_int = 1398895986;
pub const HB_SCRIPT_SUNDANESE: c_int = 1400204900;
pub const HB_SCRIPT_VAI: c_int = 1449224553;
pub const HB_SCRIPT_AVESTAN: c_int = 1098281844;
pub const HB_SCRIPT_BAMUM: c_int = 1113681269;
pub const HB_SCRIPT_EGYPTIAN_HIEROGLYPHS: c_int = 1164409200;
pub const HB_SCRIPT_IMPERIAL_ARAMAIC: c_int = 1098018153;
pub const HB_SCRIPT_INSCRIPTIONAL_PAHLAVI: c_int = 1349020777;
pub const HB_SCRIPT_INSCRIPTIONAL_PARTHIAN: c_int = 1349678185;
pub const HB_SCRIPT_JAVANESE: c_int = 1247901281;
pub const HB_SCRIPT_KAITHI: c_int = 1265920105;
pub const HB_SCRIPT_LISU: c_int = 1281979253;
pub const HB_SCRIPT_MEETEI_MAYEK: c_int = 1299473769;
pub const HB_SCRIPT_OLD_SOUTH_ARABIAN: c_int = 1398895202;
pub const HB_SCRIPT_OLD_TURKIC: c_int = 1332898664;
pub const HB_SCRIPT_SAMARITAN: c_int = 1398893938;
pub const HB_SCRIPT_TAI_THAM: c_int = 1281453665;
pub const HB_SCRIPT_TAI_VIET: c_int = 1415673460;
pub const HB_SCRIPT_BATAK: c_int = 1113683051;
pub const HB_SCRIPT_BRAHMI: c_int = 1114792296;
pub const HB_SCRIPT_MANDAIC: c_int = 1298230884;
pub const HB_SCRIPT_CHAKMA: c_int = 1130457965;
pub const HB_SCRIPT_MEROITIC_CURSIVE: c_int = 1298494051;
pub const HB_SCRIPT_MEROITIC_HIEROGLYPHS: c_int = 1298494063;
pub const HB_SCRIPT_MIAO: c_int = 1349284452;
pub const HB_SCRIPT_SHARADA: c_int = 1399353956;
pub const HB_SCRIPT_SORA_SOMPENG: c_int = 1399812705;
pub const HB_SCRIPT_TAKRI: c_int = 1415670642;
pub const HB_SCRIPT_BASSA_VAH: c_int = 1113682803;
pub const HB_SCRIPT_CAUCASIAN_ALBANIAN: c_int = 1097295970;
pub const HB_SCRIPT_DUPLOYAN: c_int = 1148547180;
pub const HB_SCRIPT_ELBASAN: c_int = 1164730977;
pub const HB_SCRIPT_GRANTHA: c_int = 1198678382;
pub const HB_SCRIPT_KHOJKI: c_int = 1265135466;
pub const HB_SCRIPT_KHUDAWADI: c_int = 1399418468;
pub const HB_SCRIPT_LINEAR_A: c_int = 1281977953;
pub const HB_SCRIPT_MAHAJANI: c_int = 1298229354;
pub const HB_SCRIPT_MANICHAEAN: c_int = 1298230889;
pub const HB_SCRIPT_MENDE_KIKAKUI: c_int = 1298493028;
pub const HB_SCRIPT_MODI: c_int = 1299145833;
pub const HB_SCRIPT_MRO: c_int = 1299345263;
pub const HB_SCRIPT_NABATAEAN: c_int = 1315070324;
pub const HB_SCRIPT_OLD_NORTH_ARABIAN: c_int = 1315009122;
pub const HB_SCRIPT_OLD_PERMIC: c_int = 1348825709;
pub const HB_SCRIPT_PAHAWH_HMONG: c_int = 1215131239;
pub const HB_SCRIPT_PALMYRENE: c_int = 1348562029;
pub const HB_SCRIPT_PAU_CIN_HAU: c_int = 1348564323;
pub const HB_SCRIPT_PSALTER_PAHLAVI: c_int = 1349020784;
pub const HB_SCRIPT_SIDDHAM: c_int = 1399415908;
pub const HB_SCRIPT_TIRHUTA: c_int = 1416196712;
pub const HB_SCRIPT_WARANG_CITI: c_int = 1466004065;
pub const HB_SCRIPT_AHOM: c_int = 1097363309;
pub const HB_SCRIPT_ANATOLIAN_HIEROGLYPHS: c_int = 1215067511;
pub const HB_SCRIPT_HATRAN: c_int = 1214346354;
pub const HB_SCRIPT_MULTANI: c_int = 1299541108;
pub const HB_SCRIPT_OLD_HUNGARIAN: c_int = 1215655527;
pub const HB_SCRIPT_SIGNWRITING: c_int = 1399287415;
pub const HB_SCRIPT_ADLAM: c_int = 1097100397;
pub const HB_SCRIPT_BHAIKSUKI: c_int = 1114139507;
pub const HB_SCRIPT_MARCHEN: c_int = 1298231907;
pub const HB_SCRIPT_OSAGE: c_int = 1332963173;
pub const HB_SCRIPT_TANGUT: c_int = 1415671399;
pub const HB_SCRIPT_NEWA: c_int = 1315272545;
pub const HB_SCRIPT_MASARAM_GONDI: c_int = 1198485101;
pub const HB_SCRIPT_NUSHU: c_int = 1316186229;
pub const HB_SCRIPT_SOYOMBO: c_int = 1399814511;
pub const HB_SCRIPT_ZANABAZAR_SQUARE: c_int = 1516334690;
pub const HB_SCRIPT_DOGRA: c_int = 1148151666;
pub const HB_SCRIPT_GUNJALA_GONDI: c_int = 1198485095;
pub const HB_SCRIPT_HANIFI_ROHINGYA: c_int = 1383032935;
pub const HB_SCRIPT_MAKASAR: c_int = 1298230113;
pub const HB_SCRIPT_MEDEFAIDRIN: c_int = 1298490470;
pub const HB_SCRIPT_OLD_SOGDIAN: c_int = 1399809903;
pub const HB_SCRIPT_SOGDIAN: c_int = 1399809892;
pub const HB_SCRIPT_ELYMAIC: c_int = 1164736877;
pub const HB_SCRIPT_NANDINAGARI: c_int = 1315008100;
pub const HB_SCRIPT_NYIAKENG_PUACHUE_HMONG: c_int = 1215131248;
pub const HB_SCRIPT_WANCHO: c_int = 1466132591;
pub const HB_SCRIPT_CHORASMIAN: c_int = 1130918515;
pub const HB_SCRIPT_DIVES_AKURU: c_int = 1147756907;
pub const HB_SCRIPT_KHITAN_SMALL_SCRIPT: c_int = 1265202291;
pub const HB_SCRIPT_YEZIDI: c_int = 1499822697;
pub const HB_SCRIPT_CYPRO_MINOAN: c_int = 1131441518;
pub const HB_SCRIPT_OLD_UYGHUR: c_int = 1333094258;
pub const HB_SCRIPT_TANGSA: c_int = 1416524641;
pub const HB_SCRIPT_TOTO: c_int = 1416590447;
pub const HB_SCRIPT_VITHKUQI: c_int = 1449751656;
pub const HB_SCRIPT_MATH: c_int = 1517122664;
pub const HB_SCRIPT_INVALID: c_int = 0;
pub const _HB_SCRIPT_MAX_VALUE: c_int = 2147483647;
pub const _HB_SCRIPT_MAX_VALUE_SIGNED: c_int = 2147483647;
pub const hb_script_t = c_uint;
pub extern fn hb_script_from_iso15924_tag(tag: hb_tag_t) hb_script_t;
pub extern fn hb_script_from_string(str: [*c]const u8, len: c_int) hb_script_t;
pub extern fn hb_script_to_iso15924_tag(script: hb_script_t) hb_tag_t;
pub extern fn hb_script_get_horizontal_direction(script: hb_script_t) hb_direction_t;
pub const struct_hb_user_data_key_t = extern struct {
    unused: u8,
};
pub const hb_user_data_key_t = struct_hb_user_data_key_t;
pub const hb_destroy_func_t = ?*const fn (?*anyopaque) callconv(.C) void;
pub const struct_hb_feature_t = extern struct {
    tag: hb_tag_t,
    value: u32,
    start: c_uint,
    end: c_uint,
};
pub const hb_feature_t = struct_hb_feature_t;
pub extern fn hb_feature_from_string(str: [*c]const u8, len: c_int, feature: [*c]hb_feature_t) hb_bool_t;
pub extern fn hb_feature_to_string(feature: [*c]hb_feature_t, buf: [*c]u8, size: c_uint) void;
pub const struct_hb_variation_t = extern struct {
    tag: hb_tag_t,
    value: f32,
};
pub const hb_variation_t = struct_hb_variation_t;
pub extern fn hb_variation_from_string(str: [*c]const u8, len: c_int, variation: [*c]hb_variation_t) hb_bool_t;
pub extern fn hb_variation_to_string(variation: [*c]hb_variation_t, buf: [*c]u8, size: c_uint) void;
pub const hb_color_t = u32;
pub extern fn hb_color_get_alpha(color: hb_color_t) u8;
pub extern fn hb_color_get_red(color: hb_color_t) u8;
pub extern fn hb_color_get_green(color: hb_color_t) u8;
pub extern fn hb_color_get_blue(color: hb_color_t) u8;
pub const HB_MEMORY_MODE_DUPLICATE: c_int = 0;
pub const HB_MEMORY_MODE_READONLY: c_int = 1;
pub const HB_MEMORY_MODE_WRITABLE: c_int = 2;
pub const HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE: c_int = 3;
pub const hb_memory_mode_t = c_uint;
pub const struct_hb_blob_t = opaque {};
pub const hb_blob_t = struct_hb_blob_t;
pub extern fn hb_blob_create(data: [*c]const u8, length: c_uint, mode: hb_memory_mode_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) ?*hb_blob_t;
pub extern fn hb_blob_create_or_fail(data: [*c]const u8, length: c_uint, mode: hb_memory_mode_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) ?*hb_blob_t;
pub extern fn hb_blob_create_from_file(file_name: [*c]const u8) ?*hb_blob_t;
pub extern fn hb_blob_create_from_file_or_fail(file_name: [*c]const u8) ?*hb_blob_t;
pub extern fn hb_blob_create_sub_blob(parent: ?*hb_blob_t, offset: c_uint, length: c_uint) ?*hb_blob_t;
pub extern fn hb_blob_copy_writable_or_fail(blob: ?*hb_blob_t) ?*hb_blob_t;
pub extern fn hb_blob_get_empty() ?*hb_blob_t;
pub extern fn hb_blob_reference(blob: ?*hb_blob_t) ?*hb_blob_t;
pub extern fn hb_blob_destroy(blob: ?*hb_blob_t) void;
pub extern fn hb_blob_set_user_data(blob: ?*hb_blob_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_blob_get_user_data(blob: ?*hb_blob_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub extern fn hb_blob_make_immutable(blob: ?*hb_blob_t) void;
pub extern fn hb_blob_is_immutable(blob: ?*hb_blob_t) hb_bool_t;
pub extern fn hb_blob_get_length(blob: ?*hb_blob_t) c_uint;
pub extern fn hb_blob_get_data(blob: ?*hb_blob_t, length: [*c]c_uint) [*c]const u8;
pub extern fn hb_blob_get_data_writable(blob: ?*hb_blob_t, length: [*c]c_uint) [*c]u8;
pub const HB_UNICODE_GENERAL_CATEGORY_CONTROL: c_int = 0;
pub const HB_UNICODE_GENERAL_CATEGORY_FORMAT: c_int = 1;
pub const HB_UNICODE_GENERAL_CATEGORY_UNASSIGNED: c_int = 2;
pub const HB_UNICODE_GENERAL_CATEGORY_PRIVATE_USE: c_int = 3;
pub const HB_UNICODE_GENERAL_CATEGORY_SURROGATE: c_int = 4;
pub const HB_UNICODE_GENERAL_CATEGORY_LOWERCASE_LETTER: c_int = 5;
pub const HB_UNICODE_GENERAL_CATEGORY_MODIFIER_LETTER: c_int = 6;
pub const HB_UNICODE_GENERAL_CATEGORY_OTHER_LETTER: c_int = 7;
pub const HB_UNICODE_GENERAL_CATEGORY_TITLECASE_LETTER: c_int = 8;
pub const HB_UNICODE_GENERAL_CATEGORY_UPPERCASE_LETTER: c_int = 9;
pub const HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK: c_int = 10;
pub const HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK: c_int = 11;
pub const HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK: c_int = 12;
pub const HB_UNICODE_GENERAL_CATEGORY_DECIMAL_NUMBER: c_int = 13;
pub const HB_UNICODE_GENERAL_CATEGORY_LETTER_NUMBER: c_int = 14;
pub const HB_UNICODE_GENERAL_CATEGORY_OTHER_NUMBER: c_int = 15;
pub const HB_UNICODE_GENERAL_CATEGORY_CONNECT_PUNCTUATION: c_int = 16;
pub const HB_UNICODE_GENERAL_CATEGORY_DASH_PUNCTUATION: c_int = 17;
pub const HB_UNICODE_GENERAL_CATEGORY_CLOSE_PUNCTUATION: c_int = 18;
pub const HB_UNICODE_GENERAL_CATEGORY_FINAL_PUNCTUATION: c_int = 19;
pub const HB_UNICODE_GENERAL_CATEGORY_INITIAL_PUNCTUATION: c_int = 20;
pub const HB_UNICODE_GENERAL_CATEGORY_OTHER_PUNCTUATION: c_int = 21;
pub const HB_UNICODE_GENERAL_CATEGORY_OPEN_PUNCTUATION: c_int = 22;
pub const HB_UNICODE_GENERAL_CATEGORY_CURRENCY_SYMBOL: c_int = 23;
pub const HB_UNICODE_GENERAL_CATEGORY_MODIFIER_SYMBOL: c_int = 24;
pub const HB_UNICODE_GENERAL_CATEGORY_MATH_SYMBOL: c_int = 25;
pub const HB_UNICODE_GENERAL_CATEGORY_OTHER_SYMBOL: c_int = 26;
pub const HB_UNICODE_GENERAL_CATEGORY_LINE_SEPARATOR: c_int = 27;
pub const HB_UNICODE_GENERAL_CATEGORY_PARAGRAPH_SEPARATOR: c_int = 28;
pub const HB_UNICODE_GENERAL_CATEGORY_SPACE_SEPARATOR: c_int = 29;
pub const hb_unicode_general_category_t = c_uint;
pub const HB_UNICODE_COMBINING_CLASS_NOT_REORDERED: c_int = 0;
pub const HB_UNICODE_COMBINING_CLASS_OVERLAY: c_int = 1;
pub const HB_UNICODE_COMBINING_CLASS_NUKTA: c_int = 7;
pub const HB_UNICODE_COMBINING_CLASS_KANA_VOICING: c_int = 8;
pub const HB_UNICODE_COMBINING_CLASS_VIRAMA: c_int = 9;
pub const HB_UNICODE_COMBINING_CLASS_CCC10: c_int = 10;
pub const HB_UNICODE_COMBINING_CLASS_CCC11: c_int = 11;
pub const HB_UNICODE_COMBINING_CLASS_CCC12: c_int = 12;
pub const HB_UNICODE_COMBINING_CLASS_CCC13: c_int = 13;
pub const HB_UNICODE_COMBINING_CLASS_CCC14: c_int = 14;
pub const HB_UNICODE_COMBINING_CLASS_CCC15: c_int = 15;
pub const HB_UNICODE_COMBINING_CLASS_CCC16: c_int = 16;
pub const HB_UNICODE_COMBINING_CLASS_CCC17: c_int = 17;
pub const HB_UNICODE_COMBINING_CLASS_CCC18: c_int = 18;
pub const HB_UNICODE_COMBINING_CLASS_CCC19: c_int = 19;
pub const HB_UNICODE_COMBINING_CLASS_CCC20: c_int = 20;
pub const HB_UNICODE_COMBINING_CLASS_CCC21: c_int = 21;
pub const HB_UNICODE_COMBINING_CLASS_CCC22: c_int = 22;
pub const HB_UNICODE_COMBINING_CLASS_CCC23: c_int = 23;
pub const HB_UNICODE_COMBINING_CLASS_CCC24: c_int = 24;
pub const HB_UNICODE_COMBINING_CLASS_CCC25: c_int = 25;
pub const HB_UNICODE_COMBINING_CLASS_CCC26: c_int = 26;
pub const HB_UNICODE_COMBINING_CLASS_CCC27: c_int = 27;
pub const HB_UNICODE_COMBINING_CLASS_CCC28: c_int = 28;
pub const HB_UNICODE_COMBINING_CLASS_CCC29: c_int = 29;
pub const HB_UNICODE_COMBINING_CLASS_CCC30: c_int = 30;
pub const HB_UNICODE_COMBINING_CLASS_CCC31: c_int = 31;
pub const HB_UNICODE_COMBINING_CLASS_CCC32: c_int = 32;
pub const HB_UNICODE_COMBINING_CLASS_CCC33: c_int = 33;
pub const HB_UNICODE_COMBINING_CLASS_CCC34: c_int = 34;
pub const HB_UNICODE_COMBINING_CLASS_CCC35: c_int = 35;
pub const HB_UNICODE_COMBINING_CLASS_CCC36: c_int = 36;
pub const HB_UNICODE_COMBINING_CLASS_CCC84: c_int = 84;
pub const HB_UNICODE_COMBINING_CLASS_CCC91: c_int = 91;
pub const HB_UNICODE_COMBINING_CLASS_CCC103: c_int = 103;
pub const HB_UNICODE_COMBINING_CLASS_CCC107: c_int = 107;
pub const HB_UNICODE_COMBINING_CLASS_CCC118: c_int = 118;
pub const HB_UNICODE_COMBINING_CLASS_CCC122: c_int = 122;
pub const HB_UNICODE_COMBINING_CLASS_CCC129: c_int = 129;
pub const HB_UNICODE_COMBINING_CLASS_CCC130: c_int = 130;
pub const HB_UNICODE_COMBINING_CLASS_CCC133: c_int = 132;
pub const HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW_LEFT: c_int = 200;
pub const HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW: c_int = 202;
pub const HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE: c_int = 214;
pub const HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE_RIGHT: c_int = 216;
pub const HB_UNICODE_COMBINING_CLASS_BELOW_LEFT: c_int = 218;
pub const HB_UNICODE_COMBINING_CLASS_BELOW: c_int = 220;
pub const HB_UNICODE_COMBINING_CLASS_BELOW_RIGHT: c_int = 222;
pub const HB_UNICODE_COMBINING_CLASS_LEFT: c_int = 224;
pub const HB_UNICODE_COMBINING_CLASS_RIGHT: c_int = 226;
pub const HB_UNICODE_COMBINING_CLASS_ABOVE_LEFT: c_int = 228;
pub const HB_UNICODE_COMBINING_CLASS_ABOVE: c_int = 230;
pub const HB_UNICODE_COMBINING_CLASS_ABOVE_RIGHT: c_int = 232;
pub const HB_UNICODE_COMBINING_CLASS_DOUBLE_BELOW: c_int = 233;
pub const HB_UNICODE_COMBINING_CLASS_DOUBLE_ABOVE: c_int = 234;
pub const HB_UNICODE_COMBINING_CLASS_IOTA_SUBSCRIPT: c_int = 240;
pub const HB_UNICODE_COMBINING_CLASS_INVALID: c_int = 255;
pub const hb_unicode_combining_class_t = c_uint;
pub const struct_hb_unicode_funcs_t = opaque {};
pub const hb_unicode_funcs_t = struct_hb_unicode_funcs_t;
pub extern fn hb_unicode_funcs_get_default() ?*hb_unicode_funcs_t;
pub extern fn hb_unicode_funcs_create(parent: ?*hb_unicode_funcs_t) ?*hb_unicode_funcs_t;
pub extern fn hb_unicode_funcs_get_empty() ?*hb_unicode_funcs_t;
pub extern fn hb_unicode_funcs_reference(ufuncs: ?*hb_unicode_funcs_t) ?*hb_unicode_funcs_t;
pub extern fn hb_unicode_funcs_destroy(ufuncs: ?*hb_unicode_funcs_t) void;
pub extern fn hb_unicode_funcs_set_user_data(ufuncs: ?*hb_unicode_funcs_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_unicode_funcs_get_user_data(ufuncs: ?*hb_unicode_funcs_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub extern fn hb_unicode_funcs_make_immutable(ufuncs: ?*hb_unicode_funcs_t) void;
pub extern fn hb_unicode_funcs_is_immutable(ufuncs: ?*hb_unicode_funcs_t) hb_bool_t;
pub extern fn hb_unicode_funcs_get_parent(ufuncs: ?*hb_unicode_funcs_t) ?*hb_unicode_funcs_t;
pub const hb_unicode_combining_class_func_t = ?*const fn (?*hb_unicode_funcs_t, hb_codepoint_t, ?*anyopaque) callconv(.C) hb_unicode_combining_class_t;
pub const hb_unicode_general_category_func_t = ?*const fn (?*hb_unicode_funcs_t, hb_codepoint_t, ?*anyopaque) callconv(.C) hb_unicode_general_category_t;
pub const hb_unicode_mirroring_func_t = ?*const fn (?*hb_unicode_funcs_t, hb_codepoint_t, ?*anyopaque) callconv(.C) hb_codepoint_t;
pub const hb_unicode_script_func_t = ?*const fn (?*hb_unicode_funcs_t, hb_codepoint_t, ?*anyopaque) callconv(.C) hb_script_t;
pub const hb_unicode_compose_func_t = ?*const fn (?*hb_unicode_funcs_t, hb_codepoint_t, hb_codepoint_t, [*c]hb_codepoint_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_unicode_decompose_func_t = ?*const fn (?*hb_unicode_funcs_t, hb_codepoint_t, [*c]hb_codepoint_t, [*c]hb_codepoint_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub extern fn hb_unicode_funcs_set_combining_class_func(ufuncs: ?*hb_unicode_funcs_t, func: hb_unicode_combining_class_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_unicode_funcs_set_general_category_func(ufuncs: ?*hb_unicode_funcs_t, func: hb_unicode_general_category_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_unicode_funcs_set_mirroring_func(ufuncs: ?*hb_unicode_funcs_t, func: hb_unicode_mirroring_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_unicode_funcs_set_script_func(ufuncs: ?*hb_unicode_funcs_t, func: hb_unicode_script_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_unicode_funcs_set_compose_func(ufuncs: ?*hb_unicode_funcs_t, func: hb_unicode_compose_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_unicode_funcs_set_decompose_func(ufuncs: ?*hb_unicode_funcs_t, func: hb_unicode_decompose_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_unicode_combining_class(ufuncs: ?*hb_unicode_funcs_t, unicode: hb_codepoint_t) hb_unicode_combining_class_t;
pub extern fn hb_unicode_general_category(ufuncs: ?*hb_unicode_funcs_t, unicode: hb_codepoint_t) hb_unicode_general_category_t;
pub extern fn hb_unicode_mirroring(ufuncs: ?*hb_unicode_funcs_t, unicode: hb_codepoint_t) hb_codepoint_t;
pub extern fn hb_unicode_script(ufuncs: ?*hb_unicode_funcs_t, unicode: hb_codepoint_t) hb_script_t;
pub extern fn hb_unicode_compose(ufuncs: ?*hb_unicode_funcs_t, a: hb_codepoint_t, b: hb_codepoint_t, ab: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_unicode_decompose(ufuncs: ?*hb_unicode_funcs_t, ab: hb_codepoint_t, a: [*c]hb_codepoint_t, b: [*c]hb_codepoint_t) hb_bool_t;
pub const struct_hb_set_t = opaque {};
pub const hb_set_t = struct_hb_set_t;
pub extern fn hb_set_create() ?*hb_set_t;
pub extern fn hb_set_get_empty() ?*hb_set_t;
pub extern fn hb_set_reference(set: ?*hb_set_t) ?*hb_set_t;
pub extern fn hb_set_destroy(set: ?*hb_set_t) void;
pub extern fn hb_set_set_user_data(set: ?*hb_set_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_set_get_user_data(set: ?*hb_set_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub extern fn hb_set_allocation_successful(set: ?*const hb_set_t) hb_bool_t;
pub extern fn hb_set_copy(set: ?*const hb_set_t) ?*hb_set_t;
pub extern fn hb_set_clear(set: ?*hb_set_t) void;
pub extern fn hb_set_is_empty(set: ?*const hb_set_t) hb_bool_t;
pub extern fn hb_set_invert(set: ?*hb_set_t) void;
pub extern fn hb_set_has(set: ?*const hb_set_t, codepoint: hb_codepoint_t) hb_bool_t;
pub extern fn hb_set_add(set: ?*hb_set_t, codepoint: hb_codepoint_t) void;
pub extern fn hb_set_add_range(set: ?*hb_set_t, first: hb_codepoint_t, last: hb_codepoint_t) void;
pub extern fn hb_set_add_sorted_array(set: ?*hb_set_t, sorted_codepoints: [*c]const hb_codepoint_t, num_codepoints: c_uint) void;
pub extern fn hb_set_del(set: ?*hb_set_t, codepoint: hb_codepoint_t) void;
pub extern fn hb_set_del_range(set: ?*hb_set_t, first: hb_codepoint_t, last: hb_codepoint_t) void;
pub extern fn hb_set_is_equal(set: ?*const hb_set_t, other: ?*const hb_set_t) hb_bool_t;
pub extern fn hb_set_is_subset(set: ?*const hb_set_t, larger_set: ?*const hb_set_t) hb_bool_t;
pub extern fn hb_set_set(set: ?*hb_set_t, other: ?*const hb_set_t) void;
pub extern fn hb_set_union(set: ?*hb_set_t, other: ?*const hb_set_t) void;
pub extern fn hb_set_intersect(set: ?*hb_set_t, other: ?*const hb_set_t) void;
pub extern fn hb_set_subtract(set: ?*hb_set_t, other: ?*const hb_set_t) void;
pub extern fn hb_set_symmetric_difference(set: ?*hb_set_t, other: ?*const hb_set_t) void;
pub extern fn hb_set_get_population(set: ?*const hb_set_t) c_uint;
pub extern fn hb_set_get_min(set: ?*const hb_set_t) hb_codepoint_t;
pub extern fn hb_set_get_max(set: ?*const hb_set_t) hb_codepoint_t;
pub extern fn hb_set_next(set: ?*const hb_set_t, codepoint: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_set_previous(set: ?*const hb_set_t, codepoint: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_set_next_range(set: ?*const hb_set_t, first: [*c]hb_codepoint_t, last: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_set_previous_range(set: ?*const hb_set_t, first: [*c]hb_codepoint_t, last: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_set_next_many(set: ?*const hb_set_t, codepoint: hb_codepoint_t, out: [*c]hb_codepoint_t, size: c_uint) c_uint;
pub extern fn hb_face_count(blob: ?*hb_blob_t) c_uint;
pub const struct_hb_face_t = opaque {};
pub const hb_face_t = struct_hb_face_t;
pub extern fn hb_face_create(blob: ?*hb_blob_t, index: c_uint) ?*hb_face_t;
pub const hb_reference_table_func_t = ?*const fn (?*hb_face_t, hb_tag_t, ?*anyopaque) callconv(.C) ?*hb_blob_t;
pub extern fn hb_face_create_for_tables(reference_table_func: hb_reference_table_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) ?*hb_face_t;
pub extern fn hb_face_get_empty() ?*hb_face_t;
pub extern fn hb_face_reference(face: ?*hb_face_t) ?*hb_face_t;
pub extern fn hb_face_destroy(face: ?*hb_face_t) void;
pub extern fn hb_face_set_user_data(face: ?*hb_face_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_face_get_user_data(face: ?*const hb_face_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub extern fn hb_face_make_immutable(face: ?*hb_face_t) void;
pub extern fn hb_face_is_immutable(face: ?*const hb_face_t) hb_bool_t;
pub extern fn hb_face_reference_table(face: ?*const hb_face_t, tag: hb_tag_t) ?*hb_blob_t;
pub extern fn hb_face_reference_blob(face: ?*hb_face_t) ?*hb_blob_t;
pub extern fn hb_face_set_index(face: ?*hb_face_t, index: c_uint) void;
pub extern fn hb_face_get_index(face: ?*const hb_face_t) c_uint;
pub extern fn hb_face_set_upem(face: ?*hb_face_t, upem: c_uint) void;
pub extern fn hb_face_get_upem(face: ?*const hb_face_t) c_uint;
pub extern fn hb_face_set_glyph_count(face: ?*hb_face_t, glyph_count: c_uint) void;
pub extern fn hb_face_get_glyph_count(face: ?*const hb_face_t) c_uint;
pub extern fn hb_face_get_table_tags(face: ?*const hb_face_t, start_offset: c_uint, table_count: [*c]c_uint, table_tags: [*c]hb_tag_t) c_uint;
pub extern fn hb_face_collect_unicodes(face: ?*hb_face_t, out: ?*hb_set_t) void;
pub extern fn hb_face_collect_variation_selectors(face: ?*hb_face_t, out: ?*hb_set_t) void;
pub extern fn hb_face_collect_variation_unicodes(face: ?*hb_face_t, variation_selector: hb_codepoint_t, out: ?*hb_set_t) void;
pub extern fn hb_face_builder_create() ?*hb_face_t;
pub extern fn hb_face_builder_add_table(face: ?*hb_face_t, tag: hb_tag_t, blob: ?*hb_blob_t) hb_bool_t;
pub const struct_hb_draw_state_t = extern struct {
    path_open: hb_bool_t,
    path_start_x: f32,
    path_start_y: f32,
    current_x: f32,
    current_y: f32,
    reserved1: hb_var_num_t,
    reserved2: hb_var_num_t,
    reserved3: hb_var_num_t,
    reserved4: hb_var_num_t,
    reserved5: hb_var_num_t,
    reserved6: hb_var_num_t,
    reserved7: hb_var_num_t,
};
pub const hb_draw_state_t = struct_hb_draw_state_t;
pub const struct_hb_draw_funcs_t = opaque {};
pub const hb_draw_funcs_t = struct_hb_draw_funcs_t;
pub const hb_draw_move_to_func_t = ?*const fn (?*hb_draw_funcs_t, ?*anyopaque, [*c]hb_draw_state_t, f32, f32, ?*anyopaque) callconv(.C) void;
pub const hb_draw_line_to_func_t = ?*const fn (?*hb_draw_funcs_t, ?*anyopaque, [*c]hb_draw_state_t, f32, f32, ?*anyopaque) callconv(.C) void;
pub const hb_draw_quadratic_to_func_t = ?*const fn (?*hb_draw_funcs_t, ?*anyopaque, [*c]hb_draw_state_t, f32, f32, f32, f32, ?*anyopaque) callconv(.C) void;
pub const hb_draw_cubic_to_func_t = ?*const fn (?*hb_draw_funcs_t, ?*anyopaque, [*c]hb_draw_state_t, f32, f32, f32, f32, f32, f32, ?*anyopaque) callconv(.C) void;
pub const hb_draw_close_path_func_t = ?*const fn (?*hb_draw_funcs_t, ?*anyopaque, [*c]hb_draw_state_t, ?*anyopaque) callconv(.C) void;
pub extern fn hb_draw_funcs_set_move_to_func(dfuncs: ?*hb_draw_funcs_t, func: hb_draw_move_to_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_draw_funcs_set_line_to_func(dfuncs: ?*hb_draw_funcs_t, func: hb_draw_line_to_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_draw_funcs_set_quadratic_to_func(dfuncs: ?*hb_draw_funcs_t, func: hb_draw_quadratic_to_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_draw_funcs_set_cubic_to_func(dfuncs: ?*hb_draw_funcs_t, func: hb_draw_cubic_to_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_draw_funcs_set_close_path_func(dfuncs: ?*hb_draw_funcs_t, func: hb_draw_close_path_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_draw_funcs_create() ?*hb_draw_funcs_t;
pub extern fn hb_draw_funcs_reference(dfuncs: ?*hb_draw_funcs_t) ?*hb_draw_funcs_t;
pub extern fn hb_draw_funcs_destroy(dfuncs: ?*hb_draw_funcs_t) void;
pub extern fn hb_draw_funcs_make_immutable(dfuncs: ?*hb_draw_funcs_t) void;
pub extern fn hb_draw_funcs_is_immutable(dfuncs: ?*hb_draw_funcs_t) hb_bool_t;
pub extern fn hb_draw_move_to(dfuncs: ?*hb_draw_funcs_t, draw_data: ?*anyopaque, st: [*c]hb_draw_state_t, to_x: f32, to_y: f32) void;
pub extern fn hb_draw_line_to(dfuncs: ?*hb_draw_funcs_t, draw_data: ?*anyopaque, st: [*c]hb_draw_state_t, to_x: f32, to_y: f32) void;
pub extern fn hb_draw_quadratic_to(dfuncs: ?*hb_draw_funcs_t, draw_data: ?*anyopaque, st: [*c]hb_draw_state_t, control_x: f32, control_y: f32, to_x: f32, to_y: f32) void;
pub extern fn hb_draw_cubic_to(dfuncs: ?*hb_draw_funcs_t, draw_data: ?*anyopaque, st: [*c]hb_draw_state_t, control1_x: f32, control1_y: f32, control2_x: f32, control2_y: f32, to_x: f32, to_y: f32) void;
pub extern fn hb_draw_close_path(dfuncs: ?*hb_draw_funcs_t, draw_data: ?*anyopaque, st: [*c]hb_draw_state_t) void;
pub const struct_hb_font_t = opaque {};
pub const hb_font_t = struct_hb_font_t;
pub const struct_hb_font_funcs_t = opaque {};
pub const hb_font_funcs_t = struct_hb_font_funcs_t;
pub extern fn hb_font_funcs_create() ?*hb_font_funcs_t;
pub extern fn hb_font_funcs_get_empty() ?*hb_font_funcs_t;
pub extern fn hb_font_funcs_reference(ffuncs: ?*hb_font_funcs_t) ?*hb_font_funcs_t;
pub extern fn hb_font_funcs_destroy(ffuncs: ?*hb_font_funcs_t) void;
pub extern fn hb_font_funcs_set_user_data(ffuncs: ?*hb_font_funcs_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_font_funcs_get_user_data(ffuncs: ?*hb_font_funcs_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub extern fn hb_font_funcs_make_immutable(ffuncs: ?*hb_font_funcs_t) void;
pub extern fn hb_font_funcs_is_immutable(ffuncs: ?*hb_font_funcs_t) hb_bool_t;
pub const struct_hb_font_extents_t = extern struct {
    ascender: hb_position_t,
    descender: hb_position_t,
    line_gap: hb_position_t,
    reserved9: hb_position_t,
    reserved8: hb_position_t,
    reserved7: hb_position_t,
    reserved6: hb_position_t,
    reserved5: hb_position_t,
    reserved4: hb_position_t,
    reserved3: hb_position_t,
    reserved2: hb_position_t,
    reserved1: hb_position_t,
};
pub const hb_font_extents_t = struct_hb_font_extents_t;
pub const struct_hb_glyph_extents_t = extern struct {
    x_bearing: hb_position_t,
    y_bearing: hb_position_t,
    width: hb_position_t,
    height: hb_position_t,
};
pub const hb_glyph_extents_t = struct_hb_glyph_extents_t;
pub const hb_font_get_font_extents_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, [*c]hb_font_extents_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_font_get_font_h_extents_func_t = hb_font_get_font_extents_func_t;
pub const hb_font_get_font_v_extents_func_t = hb_font_get_font_extents_func_t;
pub const hb_font_get_nominal_glyph_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, [*c]hb_codepoint_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_font_get_variation_glyph_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, hb_codepoint_t, [*c]hb_codepoint_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_font_get_nominal_glyphs_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, c_uint, [*c]const hb_codepoint_t, c_uint, [*c]hb_codepoint_t, c_uint, ?*anyopaque) callconv(.C) c_uint;
pub const hb_font_get_glyph_advance_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, ?*anyopaque) callconv(.C) hb_position_t;
pub const hb_font_get_glyph_h_advance_func_t = hb_font_get_glyph_advance_func_t;
pub const hb_font_get_glyph_v_advance_func_t = hb_font_get_glyph_advance_func_t;
pub const hb_font_get_glyph_advances_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, c_uint, [*c]const hb_codepoint_t, c_uint, [*c]hb_position_t, c_uint, ?*anyopaque) callconv(.C) void;
pub const hb_font_get_glyph_h_advances_func_t = hb_font_get_glyph_advances_func_t;
pub const hb_font_get_glyph_v_advances_func_t = hb_font_get_glyph_advances_func_t;
pub const hb_font_get_glyph_origin_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, [*c]hb_position_t, [*c]hb_position_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_font_get_glyph_h_origin_func_t = hb_font_get_glyph_origin_func_t;
pub const hb_font_get_glyph_v_origin_func_t = hb_font_get_glyph_origin_func_t;
pub const hb_font_get_glyph_kerning_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, hb_codepoint_t, ?*anyopaque) callconv(.C) hb_position_t;
pub const hb_font_get_glyph_h_kerning_func_t = hb_font_get_glyph_kerning_func_t;
pub const hb_font_get_glyph_extents_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, [*c]hb_glyph_extents_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_font_get_glyph_contour_point_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, c_uint, [*c]hb_position_t, [*c]hb_position_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_font_get_glyph_name_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, [*c]u8, c_uint, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_font_get_glyph_from_name_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, [*c]const u8, c_int, [*c]hb_codepoint_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub const hb_font_get_glyph_shape_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, ?*hb_draw_funcs_t, ?*anyopaque, ?*anyopaque) callconv(.C) void;
pub extern fn hb_font_funcs_set_font_h_extents_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_font_h_extents_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_font_v_extents_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_font_v_extents_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_nominal_glyph_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_nominal_glyph_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_nominal_glyphs_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_nominal_glyphs_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_variation_glyph_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_variation_glyph_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_h_advance_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_h_advance_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_v_advance_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_v_advance_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_h_advances_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_h_advances_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_v_advances_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_v_advances_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_h_origin_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_h_origin_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_v_origin_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_v_origin_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_h_kerning_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_h_kerning_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_extents_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_extents_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_contour_point_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_contour_point_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_name_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_name_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_from_name_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_from_name_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_funcs_set_glyph_shape_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_shape_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_get_h_extents(font: ?*hb_font_t, extents: [*c]hb_font_extents_t) hb_bool_t;
pub extern fn hb_font_get_v_extents(font: ?*hb_font_t, extents: [*c]hb_font_extents_t) hb_bool_t;
pub extern fn hb_font_get_nominal_glyph(font: ?*hb_font_t, unicode: hb_codepoint_t, glyph: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_font_get_variation_glyph(font: ?*hb_font_t, unicode: hb_codepoint_t, variation_selector: hb_codepoint_t, glyph: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_font_get_nominal_glyphs(font: ?*hb_font_t, count: c_uint, first_unicode: [*c]const hb_codepoint_t, unicode_stride: c_uint, first_glyph: [*c]hb_codepoint_t, glyph_stride: c_uint) c_uint;
pub extern fn hb_font_get_glyph_h_advance(font: ?*hb_font_t, glyph: hb_codepoint_t) hb_position_t;
pub extern fn hb_font_get_glyph_v_advance(font: ?*hb_font_t, glyph: hb_codepoint_t) hb_position_t;
pub extern fn hb_font_get_glyph_h_advances(font: ?*hb_font_t, count: c_uint, first_glyph: [*c]const hb_codepoint_t, glyph_stride: c_uint, first_advance: [*c]hb_position_t, advance_stride: c_uint) void;
pub extern fn hb_font_get_glyph_v_advances(font: ?*hb_font_t, count: c_uint, first_glyph: [*c]const hb_codepoint_t, glyph_stride: c_uint, first_advance: [*c]hb_position_t, advance_stride: c_uint) void;
pub extern fn hb_font_get_glyph_h_origin(font: ?*hb_font_t, glyph: hb_codepoint_t, x: [*c]hb_position_t, y: [*c]hb_position_t) hb_bool_t;
pub extern fn hb_font_get_glyph_v_origin(font: ?*hb_font_t, glyph: hb_codepoint_t, x: [*c]hb_position_t, y: [*c]hb_position_t) hb_bool_t;
pub extern fn hb_font_get_glyph_h_kerning(font: ?*hb_font_t, left_glyph: hb_codepoint_t, right_glyph: hb_codepoint_t) hb_position_t;
pub extern fn hb_font_get_glyph_extents(font: ?*hb_font_t, glyph: hb_codepoint_t, extents: [*c]hb_glyph_extents_t) hb_bool_t;
pub extern fn hb_font_get_glyph_contour_point(font: ?*hb_font_t, glyph: hb_codepoint_t, point_index: c_uint, x: [*c]hb_position_t, y: [*c]hb_position_t) hb_bool_t;
pub extern fn hb_font_get_glyph_name(font: ?*hb_font_t, glyph: hb_codepoint_t, name: [*c]u8, size: c_uint) hb_bool_t;
pub extern fn hb_font_get_glyph_from_name(font: ?*hb_font_t, name: [*c]const u8, len: c_int, glyph: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_font_get_glyph_shape(font: ?*hb_font_t, glyph: hb_codepoint_t, dfuncs: ?*hb_draw_funcs_t, draw_data: ?*anyopaque) void;
pub extern fn hb_font_get_glyph(font: ?*hb_font_t, unicode: hb_codepoint_t, variation_selector: hb_codepoint_t, glyph: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_font_get_extents_for_direction(font: ?*hb_font_t, direction: hb_direction_t, extents: [*c]hb_font_extents_t) void;
pub extern fn hb_font_get_glyph_advance_for_direction(font: ?*hb_font_t, glyph: hb_codepoint_t, direction: hb_direction_t, x: [*c]hb_position_t, y: [*c]hb_position_t) void;
pub extern fn hb_font_get_glyph_advances_for_direction(font: ?*hb_font_t, direction: hb_direction_t, count: c_uint, first_glyph: [*c]const hb_codepoint_t, glyph_stride: c_uint, first_advance: [*c]hb_position_t, advance_stride: c_uint) void;
pub extern fn hb_font_get_glyph_origin_for_direction(font: ?*hb_font_t, glyph: hb_codepoint_t, direction: hb_direction_t, x: [*c]hb_position_t, y: [*c]hb_position_t) void;
pub extern fn hb_font_add_glyph_origin_for_direction(font: ?*hb_font_t, glyph: hb_codepoint_t, direction: hb_direction_t, x: [*c]hb_position_t, y: [*c]hb_position_t) void;
pub extern fn hb_font_subtract_glyph_origin_for_direction(font: ?*hb_font_t, glyph: hb_codepoint_t, direction: hb_direction_t, x: [*c]hb_position_t, y: [*c]hb_position_t) void;
pub extern fn hb_font_get_glyph_kerning_for_direction(font: ?*hb_font_t, first_glyph: hb_codepoint_t, second_glyph: hb_codepoint_t, direction: hb_direction_t, x: [*c]hb_position_t, y: [*c]hb_position_t) void;
pub extern fn hb_font_get_glyph_extents_for_origin(font: ?*hb_font_t, glyph: hb_codepoint_t, direction: hb_direction_t, extents: [*c]hb_glyph_extents_t) hb_bool_t;
pub extern fn hb_font_get_glyph_contour_point_for_origin(font: ?*hb_font_t, glyph: hb_codepoint_t, point_index: c_uint, direction: hb_direction_t, x: [*c]hb_position_t, y: [*c]hb_position_t) hb_bool_t;
pub extern fn hb_font_glyph_to_string(font: ?*hb_font_t, glyph: hb_codepoint_t, s: [*c]u8, size: c_uint) void;
pub extern fn hb_font_glyph_from_string(font: ?*hb_font_t, s: [*c]const u8, len: c_int, glyph: [*c]hb_codepoint_t) hb_bool_t;
pub extern fn hb_font_create(face: ?*hb_face_t) ?*hb_font_t;
pub extern fn hb_font_create_sub_font(parent: ?*hb_font_t) ?*hb_font_t;
pub extern fn hb_font_get_empty() ?*hb_font_t;
pub extern fn hb_font_reference(font: ?*hb_font_t) ?*hb_font_t;
pub extern fn hb_font_destroy(font: ?*hb_font_t) void;
pub extern fn hb_font_set_user_data(font: ?*hb_font_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_font_get_user_data(font: ?*hb_font_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub extern fn hb_font_make_immutable(font: ?*hb_font_t) void;
pub extern fn hb_font_is_immutable(font: ?*hb_font_t) hb_bool_t;
pub extern fn hb_font_set_parent(font: ?*hb_font_t, parent: ?*hb_font_t) void;
pub extern fn hb_font_get_parent(font: ?*hb_font_t) ?*hb_font_t;
pub extern fn hb_font_set_face(font: ?*hb_font_t, face: ?*hb_face_t) void;
pub extern fn hb_font_get_face(font: ?*hb_font_t) ?*hb_face_t;
pub extern fn hb_font_set_funcs(font: ?*hb_font_t, klass: ?*hb_font_funcs_t, font_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_set_funcs_data(font: ?*hb_font_t, font_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_set_scale(font: ?*hb_font_t, x_scale: c_int, y_scale: c_int) void;
pub extern fn hb_font_get_scale(font: ?*hb_font_t, x_scale: [*c]c_int, y_scale: [*c]c_int) void;
pub extern fn hb_font_set_ppem(font: ?*hb_font_t, x_ppem: c_uint, y_ppem: c_uint) void;
pub extern fn hb_font_get_ppem(font: ?*hb_font_t, x_ppem: [*c]c_uint, y_ppem: [*c]c_uint) void;
pub extern fn hb_font_set_ptem(font: ?*hb_font_t, ptem: f32) void;
pub extern fn hb_font_get_ptem(font: ?*hb_font_t) f32;
pub extern fn hb_font_set_synthetic_slant(font: ?*hb_font_t, slant: f32) void;
pub extern fn hb_font_get_synthetic_slant(font: ?*hb_font_t) f32;
pub extern fn hb_font_set_variations(font: ?*hb_font_t, variations: [*c]const hb_variation_t, variations_length: c_uint) void;
pub extern fn hb_font_set_var_coords_design(font: ?*hb_font_t, coords: [*c]const f32, coords_length: c_uint) void;
pub extern fn hb_font_get_var_coords_design(font: ?*hb_font_t, length: [*c]c_uint) [*c]const f32;
pub extern fn hb_font_set_var_coords_normalized(font: ?*hb_font_t, coords: [*c]const c_int, coords_length: c_uint) void;
pub extern fn hb_font_get_var_coords_normalized(font: ?*hb_font_t, length: [*c]c_uint) [*c]const c_int;
pub extern fn hb_font_set_var_named_instance(font: ?*hb_font_t, instance_index: c_uint) void;
pub const struct_hb_glyph_info_t = extern struct {
    codepoint: hb_codepoint_t,
    mask: hb_mask_t,
    cluster: u32,
    var1: hb_var_int_t,
    var2: hb_var_int_t,
};
pub const hb_glyph_info_t = struct_hb_glyph_info_t;
pub const HB_GLYPH_FLAG_UNSAFE_TO_BREAK: c_int = 1;
pub const HB_GLYPH_FLAG_UNSAFE_TO_CONCAT: c_int = 2;
pub const HB_GLYPH_FLAG_DEFINED: c_int = 3;
pub const hb_glyph_flags_t = c_uint;
pub extern fn hb_glyph_info_get_glyph_flags(info: [*c]const hb_glyph_info_t) hb_glyph_flags_t;
pub const struct_hb_glyph_position_t = extern struct {
    x_advance: hb_position_t,
    y_advance: hb_position_t,
    x_offset: hb_position_t,
    y_offset: hb_position_t,
    @"var": hb_var_int_t,
};
pub const hb_glyph_position_t = struct_hb_glyph_position_t;
pub const struct_hb_segment_properties_t = extern struct {
    direction: hb_direction_t,
    script: hb_script_t,
    language: hb_language_t,
    reserved1: ?*anyopaque,
    reserved2: ?*anyopaque,
};
pub const hb_segment_properties_t = struct_hb_segment_properties_t;
pub extern fn hb_segment_properties_equal(a: [*c]const hb_segment_properties_t, b: [*c]const hb_segment_properties_t) hb_bool_t;
pub extern fn hb_segment_properties_hash(p: [*c]const hb_segment_properties_t) c_uint;
pub extern fn hb_segment_properties_overlay(p: [*c]hb_segment_properties_t, src: [*c]const hb_segment_properties_t) void;
pub const struct_hb_buffer_t = opaque {};
pub const hb_buffer_t = struct_hb_buffer_t;
pub extern fn hb_buffer_create() ?*hb_buffer_t;
pub extern fn hb_buffer_create_similar(src: ?*const hb_buffer_t) ?*hb_buffer_t;
pub extern fn hb_buffer_reset(buffer: ?*hb_buffer_t) void;
pub extern fn hb_buffer_get_empty() ?*hb_buffer_t;
pub extern fn hb_buffer_reference(buffer: ?*hb_buffer_t) ?*hb_buffer_t;
pub extern fn hb_buffer_destroy(buffer: ?*hb_buffer_t) void;
pub extern fn hb_buffer_set_user_data(buffer: ?*hb_buffer_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_buffer_get_user_data(buffer: ?*hb_buffer_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub const HB_BUFFER_CONTENT_TYPE_INVALID: c_int = 0;
pub const HB_BUFFER_CONTENT_TYPE_UNICODE: c_int = 1;
pub const HB_BUFFER_CONTENT_TYPE_GLYPHS: c_int = 2;
pub const hb_buffer_content_type_t = c_uint;
pub extern fn hb_buffer_set_content_type(buffer: ?*hb_buffer_t, content_type: hb_buffer_content_type_t) void;
pub extern fn hb_buffer_get_content_type(buffer: ?*hb_buffer_t) hb_buffer_content_type_t;
pub extern fn hb_buffer_set_unicode_funcs(buffer: ?*hb_buffer_t, unicode_funcs: ?*hb_unicode_funcs_t) void;
pub extern fn hb_buffer_get_unicode_funcs(buffer: ?*hb_buffer_t) ?*hb_unicode_funcs_t;
pub extern fn hb_buffer_set_direction(buffer: ?*hb_buffer_t, direction: hb_direction_t) void;
pub extern fn hb_buffer_get_direction(buffer: ?*hb_buffer_t) hb_direction_t;
pub extern fn hb_buffer_set_script(buffer: ?*hb_buffer_t, script: hb_script_t) void;
pub extern fn hb_buffer_get_script(buffer: ?*hb_buffer_t) hb_script_t;
pub extern fn hb_buffer_set_language(buffer: ?*hb_buffer_t, language: hb_language_t) void;
pub extern fn hb_buffer_get_language(buffer: ?*hb_buffer_t) hb_language_t;
pub extern fn hb_buffer_set_segment_properties(buffer: ?*hb_buffer_t, props: [*c]const hb_segment_properties_t) void;
pub extern fn hb_buffer_get_segment_properties(buffer: ?*hb_buffer_t, props: [*c]hb_segment_properties_t) void;
pub extern fn hb_buffer_guess_segment_properties(buffer: ?*hb_buffer_t) void;
pub const HB_BUFFER_FLAG_DEFAULT: c_int = 0;
pub const HB_BUFFER_FLAG_BOT: c_int = 1;
pub const HB_BUFFER_FLAG_EOT: c_int = 2;
pub const HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES: c_int = 4;
pub const HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES: c_int = 8;
pub const HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE: c_int = 16;
pub const HB_BUFFER_FLAG_VERIFY: c_int = 32;
pub const HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT: c_int = 64;
pub const hb_buffer_flags_t = c_uint;
pub extern fn hb_buffer_set_flags(buffer: ?*hb_buffer_t, flags: hb_buffer_flags_t) void;
pub extern fn hb_buffer_get_flags(buffer: ?*hb_buffer_t) hb_buffer_flags_t;
pub const HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES: c_int = 0;
pub const HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS: c_int = 1;
pub const HB_BUFFER_CLUSTER_LEVEL_CHARACTERS: c_int = 2;
pub const HB_BUFFER_CLUSTER_LEVEL_DEFAULT: c_int = 0;
pub const hb_buffer_cluster_level_t = c_uint;
pub extern fn hb_buffer_set_cluster_level(buffer: ?*hb_buffer_t, cluster_level: hb_buffer_cluster_level_t) void;
pub extern fn hb_buffer_get_cluster_level(buffer: ?*hb_buffer_t) hb_buffer_cluster_level_t;
pub extern fn hb_buffer_set_replacement_codepoint(buffer: ?*hb_buffer_t, replacement: hb_codepoint_t) void;
pub extern fn hb_buffer_get_replacement_codepoint(buffer: ?*hb_buffer_t) hb_codepoint_t;
pub extern fn hb_buffer_set_invisible_glyph(buffer: ?*hb_buffer_t, invisible: hb_codepoint_t) void;
pub extern fn hb_buffer_get_invisible_glyph(buffer: ?*hb_buffer_t) hb_codepoint_t;
pub extern fn hb_buffer_set_not_found_glyph(buffer: ?*hb_buffer_t, not_found: hb_codepoint_t) void;
pub extern fn hb_buffer_get_not_found_glyph(buffer: ?*hb_buffer_t) hb_codepoint_t;
pub extern fn hb_buffer_clear_contents(buffer: ?*hb_buffer_t) void;
pub extern fn hb_buffer_pre_allocate(buffer: ?*hb_buffer_t, size: c_uint) hb_bool_t;
pub extern fn hb_buffer_allocation_successful(buffer: ?*hb_buffer_t) hb_bool_t;
pub extern fn hb_buffer_reverse(buffer: ?*hb_buffer_t) void;
pub extern fn hb_buffer_reverse_range(buffer: ?*hb_buffer_t, start: c_uint, end: c_uint) void;
pub extern fn hb_buffer_reverse_clusters(buffer: ?*hb_buffer_t) void;
pub extern fn hb_buffer_add(buffer: ?*hb_buffer_t, codepoint: hb_codepoint_t, cluster: c_uint) void;
pub extern fn hb_buffer_add_utf8(buffer: ?*hb_buffer_t, text: [*c]const u8, text_length: c_int, item_offset: c_uint, item_length: c_int) void;
pub extern fn hb_buffer_add_utf16(buffer: ?*hb_buffer_t, text: [*c]const u16, text_length: c_int, item_offset: c_uint, item_length: c_int) void;
pub extern fn hb_buffer_add_utf32(buffer: ?*hb_buffer_t, text: [*c]const u32, text_length: c_int, item_offset: c_uint, item_length: c_int) void;
pub extern fn hb_buffer_add_latin1(buffer: ?*hb_buffer_t, text: [*c]const u8, text_length: c_int, item_offset: c_uint, item_length: c_int) void;
pub extern fn hb_buffer_add_codepoints(buffer: ?*hb_buffer_t, text: [*c]const hb_codepoint_t, text_length: c_int, item_offset: c_uint, item_length: c_int) void;
pub extern fn hb_buffer_append(buffer: ?*hb_buffer_t, source: ?*const hb_buffer_t, start: c_uint, end: c_uint) void;
pub extern fn hb_buffer_set_length(buffer: ?*hb_buffer_t, length: c_uint) hb_bool_t;
pub extern fn hb_buffer_get_length(buffer: ?*hb_buffer_t) c_uint;
pub extern fn hb_buffer_get_glyph_infos(buffer: ?*hb_buffer_t, length: [*c]c_uint) [*c]hb_glyph_info_t;
pub extern fn hb_buffer_get_glyph_positions(buffer: ?*hb_buffer_t, length: [*c]c_uint) [*c]hb_glyph_position_t;
pub extern fn hb_buffer_has_positions(buffer: ?*hb_buffer_t) hb_bool_t;
pub extern fn hb_buffer_normalize_glyphs(buffer: ?*hb_buffer_t) void;
pub const HB_BUFFER_SERIALIZE_FLAG_DEFAULT: c_int = 0;
pub const HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS: c_int = 1;
pub const HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS: c_int = 2;
pub const HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES: c_int = 4;
pub const HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS: c_int = 8;
pub const HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS: c_int = 16;
pub const HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES: c_int = 32;
pub const hb_buffer_serialize_flags_t = c_uint;
pub const HB_BUFFER_SERIALIZE_FORMAT_TEXT: c_int = 1413830740;
pub const HB_BUFFER_SERIALIZE_FORMAT_JSON: c_int = 1246973774;
pub const HB_BUFFER_SERIALIZE_FORMAT_INVALID: c_int = 0;
pub const hb_buffer_serialize_format_t = c_uint;
pub extern fn hb_buffer_serialize_format_from_string(str: [*c]const u8, len: c_int) hb_buffer_serialize_format_t;
pub extern fn hb_buffer_serialize_format_to_string(format: hb_buffer_serialize_format_t) [*c]const u8;
pub extern fn hb_buffer_serialize_list_formats() [*c][*c]const u8;
pub extern fn hb_buffer_serialize_glyphs(buffer: ?*hb_buffer_t, start: c_uint, end: c_uint, buf: [*c]u8, buf_size: c_uint, buf_consumed: [*c]c_uint, font: ?*hb_font_t, format: hb_buffer_serialize_format_t, flags: hb_buffer_serialize_flags_t) c_uint;
pub extern fn hb_buffer_serialize_unicode(buffer: ?*hb_buffer_t, start: c_uint, end: c_uint, buf: [*c]u8, buf_size: c_uint, buf_consumed: [*c]c_uint, format: hb_buffer_serialize_format_t, flags: hb_buffer_serialize_flags_t) c_uint;
pub extern fn hb_buffer_serialize(buffer: ?*hb_buffer_t, start: c_uint, end: c_uint, buf: [*c]u8, buf_size: c_uint, buf_consumed: [*c]c_uint, font: ?*hb_font_t, format: hb_buffer_serialize_format_t, flags: hb_buffer_serialize_flags_t) c_uint;
pub extern fn hb_buffer_deserialize_glyphs(buffer: ?*hb_buffer_t, buf: [*c]const u8, buf_len: c_int, end_ptr: [*c][*c]const u8, font: ?*hb_font_t, format: hb_buffer_serialize_format_t) hb_bool_t;
pub extern fn hb_buffer_deserialize_unicode(buffer: ?*hb_buffer_t, buf: [*c]const u8, buf_len: c_int, end_ptr: [*c][*c]const u8, format: hb_buffer_serialize_format_t) hb_bool_t;
pub const HB_BUFFER_DIFF_FLAG_EQUAL: c_int = 0;
pub const HB_BUFFER_DIFF_FLAG_CONTENT_TYPE_MISMATCH: c_int = 1;
pub const HB_BUFFER_DIFF_FLAG_LENGTH_MISMATCH: c_int = 2;
pub const HB_BUFFER_DIFF_FLAG_NOTDEF_PRESENT: c_int = 4;
pub const HB_BUFFER_DIFF_FLAG_DOTTED_CIRCLE_PRESENT: c_int = 8;
pub const HB_BUFFER_DIFF_FLAG_CODEPOINT_MISMATCH: c_int = 16;
pub const HB_BUFFER_DIFF_FLAG_CLUSTER_MISMATCH: c_int = 32;
pub const HB_BUFFER_DIFF_FLAG_GLYPH_FLAGS_MISMATCH: c_int = 64;
pub const HB_BUFFER_DIFF_FLAG_POSITION_MISMATCH: c_int = 128;
pub const hb_buffer_diff_flags_t = c_uint;
pub extern fn hb_buffer_diff(buffer: ?*hb_buffer_t, reference: ?*hb_buffer_t, dottedcircle_glyph: hb_codepoint_t, position_fuzz: c_uint) hb_buffer_diff_flags_t;
pub const hb_buffer_message_func_t = ?*const fn (?*hb_buffer_t, ?*hb_font_t, [*c]const u8, ?*anyopaque) callconv(.C) hb_bool_t;
pub extern fn hb_buffer_set_message_func(buffer: ?*hb_buffer_t, func: hb_buffer_message_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub const hb_font_get_glyph_func_t = ?*const fn (?*hb_font_t, ?*anyopaque, hb_codepoint_t, hb_codepoint_t, [*c]hb_codepoint_t, ?*anyopaque) callconv(.C) hb_bool_t;
pub extern fn hb_font_funcs_set_glyph_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub const hb_unicode_eastasian_width_func_t = ?*const fn (?*hb_unicode_funcs_t, hb_codepoint_t, ?*anyopaque) callconv(.C) c_uint;
pub extern fn hb_unicode_funcs_set_eastasian_width_func(ufuncs: ?*hb_unicode_funcs_t, func: hb_unicode_eastasian_width_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_unicode_eastasian_width(ufuncs: ?*hb_unicode_funcs_t, unicode: hb_codepoint_t) c_uint;
pub const hb_unicode_decompose_compatibility_func_t = ?*const fn (?*hb_unicode_funcs_t, hb_codepoint_t, [*c]hb_codepoint_t, ?*anyopaque) callconv(.C) c_uint;
pub extern fn hb_unicode_funcs_set_decompose_compatibility_func(ufuncs: ?*hb_unicode_funcs_t, func: hb_unicode_decompose_compatibility_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_unicode_decompose_compatibility(ufuncs: ?*hb_unicode_funcs_t, u: hb_codepoint_t, decomposed: [*c]hb_codepoint_t) c_uint;
pub const hb_font_get_glyph_v_kerning_func_t = hb_font_get_glyph_kerning_func_t;
pub extern fn hb_font_funcs_set_glyph_v_kerning_func(ffuncs: ?*hb_font_funcs_t, func: hb_font_get_glyph_v_kerning_func_t, user_data: ?*anyopaque, destroy: hb_destroy_func_t) void;
pub extern fn hb_font_get_glyph_v_kerning(font: ?*hb_font_t, top_glyph: hb_codepoint_t, bottom_glyph: hb_codepoint_t) hb_position_t;
pub const struct_hb_map_t = opaque {};
pub const hb_map_t = struct_hb_map_t;
pub extern fn hb_map_create() ?*hb_map_t;
pub extern fn hb_map_get_empty() ?*hb_map_t;
pub extern fn hb_map_reference(map: ?*hb_map_t) ?*hb_map_t;
pub extern fn hb_map_destroy(map: ?*hb_map_t) void;
pub extern fn hb_map_set_user_data(map: ?*hb_map_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_map_get_user_data(map: ?*hb_map_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub extern fn hb_map_allocation_successful(map: ?*const hb_map_t) hb_bool_t;
pub extern fn hb_map_clear(map: ?*hb_map_t) void;
pub extern fn hb_map_is_empty(map: ?*const hb_map_t) hb_bool_t;
pub extern fn hb_map_get_population(map: ?*const hb_map_t) c_uint;
pub extern fn hb_map_is_equal(map: ?*const hb_map_t, other: ?*const hb_map_t) hb_bool_t;
pub extern fn hb_map_set(map: ?*hb_map_t, key: hb_codepoint_t, value: hb_codepoint_t) void;
pub extern fn hb_map_get(map: ?*const hb_map_t, key: hb_codepoint_t) hb_codepoint_t;
pub extern fn hb_map_del(map: ?*hb_map_t, key: hb_codepoint_t) void;
pub extern fn hb_map_has(map: ?*const hb_map_t, key: hb_codepoint_t) hb_bool_t;
pub extern fn hb_shape(font: ?*hb_font_t, buffer: ?*hb_buffer_t, features: [*c]const hb_feature_t, num_features: c_uint) void;
pub extern fn hb_shape_full(font: ?*hb_font_t, buffer: ?*hb_buffer_t, features: [*c]const hb_feature_t, num_features: c_uint, shaper_list: [*c]const [*c]const u8) hb_bool_t;
pub extern fn hb_shape_list_shapers() [*c][*c]const u8;
pub const struct_hb_shape_plan_t = opaque {};
pub const hb_shape_plan_t = struct_hb_shape_plan_t;
pub extern fn hb_shape_plan_create(face: ?*hb_face_t, props: [*c]const hb_segment_properties_t, user_features: [*c]const hb_feature_t, num_user_features: c_uint, shaper_list: [*c]const [*c]const u8) ?*hb_shape_plan_t;
pub extern fn hb_shape_plan_create_cached(face: ?*hb_face_t, props: [*c]const hb_segment_properties_t, user_features: [*c]const hb_feature_t, num_user_features: c_uint, shaper_list: [*c]const [*c]const u8) ?*hb_shape_plan_t;
pub extern fn hb_shape_plan_create2(face: ?*hb_face_t, props: [*c]const hb_segment_properties_t, user_features: [*c]const hb_feature_t, num_user_features: c_uint, coords: [*c]const c_int, num_coords: c_uint, shaper_list: [*c]const [*c]const u8) ?*hb_shape_plan_t;
pub extern fn hb_shape_plan_create_cached2(face: ?*hb_face_t, props: [*c]const hb_segment_properties_t, user_features: [*c]const hb_feature_t, num_user_features: c_uint, coords: [*c]const c_int, num_coords: c_uint, shaper_list: [*c]const [*c]const u8) ?*hb_shape_plan_t;
pub extern fn hb_shape_plan_get_empty() ?*hb_shape_plan_t;
pub extern fn hb_shape_plan_reference(shape_plan: ?*hb_shape_plan_t) ?*hb_shape_plan_t;
pub extern fn hb_shape_plan_destroy(shape_plan: ?*hb_shape_plan_t) void;
pub extern fn hb_shape_plan_set_user_data(shape_plan: ?*hb_shape_plan_t, key: [*c]hb_user_data_key_t, data: ?*anyopaque, destroy: hb_destroy_func_t, replace: hb_bool_t) hb_bool_t;
pub extern fn hb_shape_plan_get_user_data(shape_plan: ?*hb_shape_plan_t, key: [*c]hb_user_data_key_t) ?*anyopaque;
pub extern fn hb_shape_plan_execute(shape_plan: ?*hb_shape_plan_t, font: ?*hb_font_t, buffer: ?*hb_buffer_t, features: [*c]const hb_feature_t, num_features: c_uint) hb_bool_t;
pub extern fn hb_shape_plan_get_shaper(shape_plan: ?*hb_shape_plan_t) [*c]const u8;
pub const HB_STYLE_TAG_ITALIC: c_int = 1769234796;
pub const HB_STYLE_TAG_OPTICAL_SIZE: c_int = 1869640570;
pub const HB_STYLE_TAG_SLANT_ANGLE: c_int = 1936486004;
pub const HB_STYLE_TAG_SLANT_RATIO: c_int = 1399615092;
pub const HB_STYLE_TAG_WIDTH: c_int = 2003072104;
pub const HB_STYLE_TAG_WEIGHT: c_int = 2003265652;
pub const _HB_STYLE_TAG_MAX_VALUE: c_int = 2147483647;
pub const hb_style_tag_t = c_uint;
pub extern fn hb_style_get_value(font: ?*hb_font_t, style_tag: hb_style_tag_t) f32;
pub extern fn hb_version(major: [*c]c_uint, minor: [*c]c_uint, micro: [*c]c_uint) void;
pub extern fn hb_version_string() [*c]const u8;
pub extern fn hb_version_atleast(major: c_uint, minor: c_uint, micro: c_uint) hb_bool_t;
pub const ptrdiff_t = c_long;
pub const rsize_t = c_ulong;
pub const wchar_t = c_int;
pub const max_align_t = c_longdouble;
pub const __darwin_nl_item = c_int;
pub const __darwin_wctrans_t = c_int;
pub const __darwin_wctype_t = __uint32_t;
pub extern fn memchr(__s: ?*const anyopaque, __c: c_int, __n: c_ulong) ?*anyopaque;
pub extern fn memcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: c_ulong) c_int;
pub extern fn memcpy(__dst: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
pub extern fn memmove(__dst: ?*anyopaque, __src: ?*const anyopaque, __len: c_ulong) ?*anyopaque;
pub extern fn memset(__b: ?*anyopaque, __c: c_int, __len: c_ulong) ?*anyopaque;
pub extern fn strcat(__s1: [*c]u8, __s2: [*c]const u8) [*c]u8;
pub extern fn strchr(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strcmp(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strcoll(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strcpy(__dst: [*c]u8, __src: [*c]const u8) [*c]u8;
pub extern fn strcspn(__s: [*c]const u8, __charset: [*c]const u8) c_ulong;
pub extern fn strerror(__errnum: c_int) [*c]u8;
pub extern fn strlen(__s: [*c]const u8) c_ulong;
pub extern fn strncat(__s1: [*c]u8, __s2: [*c]const u8, __n: c_ulong) [*c]u8;
pub extern fn strncmp(__s1: [*c]const u8, __s2: [*c]const u8, __n: c_ulong) c_int;
pub extern fn strncpy(__dst: [*c]u8, __src: [*c]const u8, __n: c_ulong) [*c]u8;
pub extern fn strpbrk(__s: [*c]const u8, __charset: [*c]const u8) [*c]u8;
pub extern fn strrchr(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strspn(__s: [*c]const u8, __charset: [*c]const u8) c_ulong;
pub extern fn strstr(__big: [*c]const u8, __little: [*c]const u8) [*c]u8;
pub extern fn strtok(__str: [*c]u8, __sep: [*c]const u8) [*c]u8;
pub extern fn strxfrm(__s1: [*c]u8, __s2: [*c]const u8, __n: c_ulong) c_ulong;
pub extern fn strtok_r(__str: [*c]u8, __sep: [*c]const u8, __lasts: [*c][*c]u8) [*c]u8;
pub extern fn strerror_r(__errnum: c_int, __strerrbuf: [*c]u8, __buflen: usize) c_int;
pub extern fn strdup(__s1: [*c]const u8) [*c]u8;
pub extern fn memccpy(__dst: ?*anyopaque, __src: ?*const anyopaque, __c: c_int, __n: c_ulong) ?*anyopaque;
pub extern fn stpcpy(__dst: [*c]u8, __src: [*c]const u8) [*c]u8;
pub extern fn stpncpy(__dst: [*c]u8, __src: [*c]const u8, __n: c_ulong) [*c]u8;
pub extern fn strndup(__s1: [*c]const u8, __n: c_ulong) [*c]u8;
pub extern fn strnlen(__s1: [*c]const u8, __n: usize) usize;
pub extern fn strsignal(__sig: c_int) [*c]u8;
pub const errno_t = c_int;
pub extern fn memset_s(__s: ?*anyopaque, __smax: rsize_t, __c: c_int, __n: rsize_t) errno_t;
pub extern fn memmem(__big: ?*const anyopaque, __big_len: usize, __little: ?*const anyopaque, __little_len: usize) ?*anyopaque;
pub extern fn memset_pattern4(__b: ?*anyopaque, __pattern4: ?*const anyopaque, __len: usize) void;
pub extern fn memset_pattern8(__b: ?*anyopaque, __pattern8: ?*const anyopaque, __len: usize) void;
pub extern fn memset_pattern16(__b: ?*anyopaque, __pattern16: ?*const anyopaque, __len: usize) void;
pub extern fn strcasestr(__big: [*c]const u8, __little: [*c]const u8) [*c]u8;
pub extern fn strnstr(__big: [*c]const u8, __little: [*c]const u8, __len: usize) [*c]u8;
pub extern fn strlcat(__dst: [*c]u8, __source: [*c]const u8, __size: c_ulong) c_ulong;
pub extern fn strlcpy(__dst: [*c]u8, __source: [*c]const u8, __size: c_ulong) c_ulong;
pub extern fn strmode(__mode: c_int, __bp: [*c]u8) void;
pub extern fn strsep(__stringp: [*c][*c]u8, __delim: [*c]const u8) [*c]u8;
pub extern fn swab(noalias ?*const anyopaque, noalias ?*anyopaque, isize) void;
pub extern fn timingsafe_bcmp(__b1: ?*const anyopaque, __b2: ?*const anyopaque, __len: usize) c_int;
pub extern fn strsignal_r(__sig: c_int, __strsignalbuf: [*c]u8, __buflen: usize) c_int;
pub extern fn bcmp(?*const anyopaque, ?*const anyopaque, c_ulong) c_int;
pub extern fn bcopy(?*const anyopaque, ?*anyopaque, usize) void;
pub extern fn bzero(?*anyopaque, c_ulong) void;
pub extern fn index([*c]const u8, c_int) [*c]u8;
pub extern fn rindex([*c]const u8, c_int) [*c]u8;
pub extern fn ffs(c_int) c_int;
pub extern fn strcasecmp([*c]const u8, [*c]const u8) c_int;
pub extern fn strncasecmp([*c]const u8, [*c]const u8, c_ulong) c_int;
pub extern fn ffsl(c_long) c_int;
pub extern fn ffsll(c_longlong) c_int;
pub extern fn fls(c_int) c_int;
pub extern fn flsl(c_long) c_int;
pub extern fn flsll(c_longlong) c_int;
pub const va_list = __darwin_va_list;
pub extern fn renameat(c_int, [*c]const u8, c_int, [*c]const u8) c_int;
pub extern fn renamex_np([*c]const u8, [*c]const u8, c_uint) c_int;
pub extern fn renameatx_np(c_int, [*c]const u8, c_int, [*c]const u8, c_uint) c_int;
pub const fpos_t = __darwin_off_t;
pub const struct___sbuf = extern struct {
    _base: [*c]u8,
    _size: c_int,
};
pub const struct___sFILEX = opaque {};
pub const struct___sFILE = extern struct {
    _p: [*c]u8,
    _r: c_int,
    _w: c_int,
    _flags: c_short,
    _file: c_short,
    _bf: struct___sbuf,
    _lbfsize: c_int,
    _cookie: ?*anyopaque,
    _close: ?*const fn (?*anyopaque) callconv(.C) c_int,
    _read: ?*const fn (?*anyopaque, [*c]u8, c_int) callconv(.C) c_int,
    _seek: ?*const fn (?*anyopaque, fpos_t, c_int) callconv(.C) fpos_t,
    _write: ?*const fn (?*anyopaque, [*c]const u8, c_int) callconv(.C) c_int,
    _ub: struct___sbuf,
    _extra: ?*struct___sFILEX,
    _ur: c_int,
    _ubuf: [3]u8,
    _nbuf: [1]u8,
    _lb: struct___sbuf,
    _blksize: c_int,
    _offset: fpos_t,
};
pub const FILE = struct___sFILE;
pub extern var __stdinp: [*c]FILE;
pub extern var __stdoutp: [*c]FILE;
pub extern var __stderrp: [*c]FILE;
pub extern fn clearerr([*c]FILE) void;
pub extern fn fclose([*c]FILE) c_int;
pub extern fn feof([*c]FILE) c_int;
pub extern fn ferror([*c]FILE) c_int;
pub extern fn fflush([*c]FILE) c_int;
pub extern fn fgetc([*c]FILE) c_int;
pub extern fn fgetpos(noalias [*c]FILE, [*c]fpos_t) c_int;
pub extern fn fgets(noalias [*c]u8, c_int, [*c]FILE) [*c]u8;
pub extern fn fopen(__filename: [*c]const u8, __mode: [*c]const u8) [*c]FILE;
pub extern fn fprintf([*c]FILE, [*c]const u8, ...) c_int;
pub extern fn fputc(c_int, [*c]FILE) c_int;
pub extern fn fputs(noalias [*c]const u8, noalias [*c]FILE) c_int;
pub extern fn fread(__ptr: ?*anyopaque, __size: c_ulong, __nitems: c_ulong, __stream: [*c]FILE) c_ulong;
pub extern fn freopen(noalias [*c]const u8, noalias [*c]const u8, noalias [*c]FILE) [*c]FILE;
pub extern fn fscanf(noalias [*c]FILE, noalias [*c]const u8, ...) c_int;
pub extern fn fseek([*c]FILE, c_long, c_int) c_int;
pub extern fn fsetpos([*c]FILE, [*c]const fpos_t) c_int;
pub extern fn ftell([*c]FILE) c_long;
pub extern fn fwrite(__ptr: ?*const anyopaque, __size: c_ulong, __nitems: c_ulong, __stream: [*c]FILE) c_ulong;
pub extern fn getc([*c]FILE) c_int;
pub extern fn getchar() c_int;
pub extern fn gets([*c]u8) [*c]u8;
pub extern fn perror([*c]const u8) void;
pub extern fn printf([*c]const u8, ...) c_int;
pub extern fn putc(c_int, [*c]FILE) c_int;
pub extern fn putchar(c_int) c_int;
pub extern fn puts([*c]const u8) c_int;
pub extern fn remove([*c]const u8) c_int;
pub extern fn rename(__old: [*c]const u8, __new: [*c]const u8) c_int;
pub extern fn rewind([*c]FILE) void;
pub extern fn scanf(noalias [*c]const u8, ...) c_int;
pub extern fn setbuf(noalias [*c]FILE, noalias [*c]u8) void;
pub extern fn setvbuf(noalias [*c]FILE, noalias [*c]u8, c_int, usize) c_int;
pub extern fn sprintf([*c]u8, [*c]const u8, ...) c_int;
pub extern fn sscanf(noalias [*c]const u8, noalias [*c]const u8, ...) c_int;
pub extern fn tmpfile() [*c]FILE;
pub extern fn tmpnam([*c]u8) [*c]u8;
pub extern fn ungetc(c_int, [*c]FILE) c_int;
pub extern fn vfprintf([*c]FILE, [*c]const u8, __builtin_va_list) c_int;
pub extern fn vprintf([*c]const u8, __builtin_va_list) c_int;
pub extern fn vsprintf([*c]u8, [*c]const u8, __builtin_va_list) c_int;
pub extern fn ctermid([*c]u8) [*c]u8;
pub extern fn fdopen(c_int, [*c]const u8) [*c]FILE;
pub extern fn fileno([*c]FILE) c_int;
pub extern fn pclose([*c]FILE) c_int;
pub extern fn popen([*c]const u8, [*c]const u8) [*c]FILE;
pub extern fn __srget([*c]FILE) c_int;
pub extern fn __svfscanf([*c]FILE, [*c]const u8, va_list) c_int;
pub extern fn __swbuf(c_int, [*c]FILE) c_int;
pub inline fn __sputc(arg__c: c_int, arg__p: [*c]FILE) c_int {
    var _c = arg__c;
    var _p = arg__p;
    if (((blk: {
        const ref = &_p.*._w;
        ref.* -= 1;
        break :blk ref.*;
    }) >= @as(c_int, 0)) or ((_p.*._w >= _p.*._lbfsize) and (@bitCast(c_int, @as(c_uint, @bitCast(u8, @truncate(i8, _c)))) != @as(c_int, '\n')))) return @bitCast(c_int, @as(c_uint, blk: {
        const tmp = @bitCast(u8, @truncate(i8, _c));
        (blk_1: {
            const ref = &_p.*._p;
            const tmp_2 = ref.*;
            ref.* += 1;
            break :blk_1 tmp_2;
        }).* = tmp;
        break :blk tmp;
    })) else return __swbuf(_c, _p);
    return 0;
}
pub extern fn flockfile([*c]FILE) void;
pub extern fn ftrylockfile([*c]FILE) c_int;
pub extern fn funlockfile([*c]FILE) void;
pub extern fn getc_unlocked([*c]FILE) c_int;
pub extern fn getchar_unlocked() c_int;
pub extern fn putc_unlocked(c_int, [*c]FILE) c_int;
pub extern fn putchar_unlocked(c_int) c_int;
pub extern fn getw([*c]FILE) c_int;
pub extern fn putw(c_int, [*c]FILE) c_int;
pub extern fn tempnam(__dir: [*c]const u8, __prefix: [*c]const u8) [*c]u8;
pub const off_t = __darwin_off_t;
pub extern fn fseeko(__stream: [*c]FILE, __offset: off_t, __whence: c_int) c_int;
pub extern fn ftello(__stream: [*c]FILE) off_t;
pub extern fn snprintf(__str: [*c]u8, __size: c_ulong, __format: [*c]const u8, ...) c_int;
pub extern fn vfscanf(noalias __stream: [*c]FILE, noalias __format: [*c]const u8, __builtin_va_list) c_int;
pub extern fn vscanf(noalias __format: [*c]const u8, __builtin_va_list) c_int;
pub extern fn vsnprintf(__str: [*c]u8, __size: c_ulong, __format: [*c]const u8, __builtin_va_list) c_int;
pub extern fn vsscanf(noalias __str: [*c]const u8, noalias __format: [*c]const u8, __builtin_va_list) c_int;
pub extern fn dprintf(c_int, noalias [*c]const u8, ...) c_int;
pub extern fn vdprintf(c_int, noalias [*c]const u8, va_list) c_int;
pub extern fn getdelim(noalias __linep: [*c][*c]u8, noalias __linecapp: [*c]usize, __delimiter: c_int, noalias __stream: [*c]FILE) isize;
pub extern fn getline(noalias __linep: [*c][*c]u8, noalias __linecapp: [*c]usize, noalias __stream: [*c]FILE) isize;
pub extern fn fmemopen(noalias __buf: ?*anyopaque, __size: usize, noalias __mode: [*c]const u8) [*c]FILE;
pub extern fn open_memstream(__bufp: [*c][*c]u8, __sizep: [*c]usize) [*c]FILE;
pub extern const sys_nerr: c_int;
pub extern const sys_errlist: [*c]const [*c]const u8;
pub extern fn asprintf(noalias [*c][*c]u8, noalias [*c]const u8, ...) c_int;
pub extern fn ctermid_r([*c]u8) [*c]u8;
pub extern fn fgetln([*c]FILE, [*c]usize) [*c]u8;
pub extern fn fmtcheck([*c]const u8, [*c]const u8) [*c]const u8;
pub extern fn fpurge([*c]FILE) c_int;
pub extern fn setbuffer([*c]FILE, [*c]u8, c_int) void;
pub extern fn setlinebuf([*c]FILE) c_int;
pub extern fn vasprintf(noalias [*c][*c]u8, noalias [*c]const u8, va_list) c_int;
pub extern fn funopen(?*const anyopaque, ?fn (?*anyopaque, [*c]u8, c_int) callconv(.C) c_int, ?fn (?*anyopaque, [*c]const u8, c_int) callconv(.C) c_int, ?fn (?*anyopaque, fpos_t, c_int) callconv(.C) fpos_t, ?fn (?*anyopaque) callconv(.C) c_int) [*c]FILE;
pub extern fn __sprintf_chk(noalias [*c]u8, c_int, usize, noalias [*c]const u8, ...) c_int;
pub extern fn __snprintf_chk(noalias [*c]u8, usize, c_int, usize, noalias [*c]const u8, ...) c_int;
pub extern fn __vsprintf_chk(noalias [*c]u8, c_int, usize, noalias [*c]const u8, va_list) c_int;
pub extern fn __vsnprintf_chk(noalias [*c]u8, usize, c_int, usize, noalias [*c]const u8, va_list) c_int;
pub const P_ALL: c_int = 0;
pub const P_PID: c_int = 1;
pub const P_PGID: c_int = 2;
pub const idtype_t = c_uint;
pub const pid_t = __darwin_pid_t;
pub const id_t = __darwin_id_t;
pub const sig_atomic_t = c_int;
pub const struct___darwin_arm_exception_state = extern struct {
    __exception: __uint32_t,
    __fsr: __uint32_t,
    __far: __uint32_t,
};
pub const struct___darwin_arm_exception_state64 = extern struct {
    __far: __uint64_t,
    __esr: __uint32_t,
    __exception: __uint32_t,
};
pub const struct___darwin_arm_thread_state = extern struct {
    __r: [13]__uint32_t,
    __sp: __uint32_t,
    __lr: __uint32_t,
    __pc: __uint32_t,
    __cpsr: __uint32_t,
};
pub const struct___darwin_arm_thread_state64 = extern struct {
    __x: [29]__uint64_t,
    __fp: __uint64_t,
    __lr: __uint64_t,
    __sp: __uint64_t,
    __pc: __uint64_t,
    __cpsr: __uint32_t,
    __pad: __uint32_t,
};
pub const struct___darwin_arm_vfp_state = extern struct {
    __r: [64]__uint32_t,
    __fpscr: __uint32_t,
};
pub const __uint128_t = u128;
pub const struct___darwin_arm_neon_state64 = extern struct {
    __v: [32]__uint128_t,
    __fpsr: __uint32_t,
    __fpcr: __uint32_t,
};
pub const struct___darwin_arm_neon_state = extern struct {
    __v: [16]__uint128_t,
    __fpsr: __uint32_t,
    __fpcr: __uint32_t,
};
pub const struct___arm_pagein_state = extern struct {
    __pagein_error: c_int,
};
pub const struct___arm_legacy_debug_state = extern struct {
    __bvr: [16]__uint32_t,
    __bcr: [16]__uint32_t,
    __wvr: [16]__uint32_t,
    __wcr: [16]__uint32_t,
};
pub const struct___darwin_arm_debug_state32 = extern struct {
    __bvr: [16]__uint32_t,
    __bcr: [16]__uint32_t,
    __wvr: [16]__uint32_t,
    __wcr: [16]__uint32_t,
    __mdscr_el1: __uint64_t,
};
pub const struct___darwin_arm_debug_state64 = extern struct {
    __bvr: [16]__uint64_t,
    __bcr: [16]__uint64_t,
    __wvr: [16]__uint64_t,
    __wcr: [16]__uint64_t,
    __mdscr_el1: __uint64_t,
};
pub const struct___darwin_arm_cpmu_state64 = extern struct {
    __ctrs: [16]__uint64_t,
};
pub const struct___darwin_mcontext32 = extern struct {
    __es: struct___darwin_arm_exception_state,
    __ss: struct___darwin_arm_thread_state,
    __fs: struct___darwin_arm_vfp_state,
};
pub const struct___darwin_mcontext64 = extern struct {
    __es: struct___darwin_arm_exception_state64,
    __ss: struct___darwin_arm_thread_state64,
    __ns: struct___darwin_arm_neon_state64,
};
pub const mcontext_t = [*c]struct___darwin_mcontext64;
pub const pthread_attr_t = __darwin_pthread_attr_t;
pub const struct___darwin_sigaltstack = extern struct {
    ss_sp: ?*anyopaque,
    ss_size: __darwin_size_t,
    ss_flags: c_int,
};
pub const stack_t = struct___darwin_sigaltstack;
pub const struct___darwin_ucontext = extern struct {
    uc_onstack: c_int,
    uc_sigmask: __darwin_sigset_t,
    uc_stack: struct___darwin_sigaltstack,
    uc_link: [*c]struct___darwin_ucontext,
    uc_mcsize: __darwin_size_t,
    uc_mcontext: [*c]struct___darwin_mcontext64,
};
pub const ucontext_t = struct___darwin_ucontext;
pub const sigset_t = __darwin_sigset_t;
pub const uid_t = __darwin_uid_t;
pub const union_sigval = extern union {
    sival_int: c_int,
    sival_ptr: ?*anyopaque,
};
pub const struct_sigevent = extern struct {
    sigev_notify: c_int,
    sigev_signo: c_int,
    sigev_value: union_sigval,
    sigev_notify_function: ?*const fn (union_sigval) callconv(.C) void,
    sigev_notify_attributes: [*c]pthread_attr_t,
};
pub const struct___siginfo = extern struct {
    si_signo: c_int,
    si_errno: c_int,
    si_code: c_int,
    si_pid: pid_t,
    si_uid: uid_t,
    si_status: c_int,
    si_addr: ?*anyopaque,
    si_value: union_sigval,
    si_band: c_long,
    __pad: [7]c_ulong,
};
pub const siginfo_t = struct___siginfo;
pub const union___sigaction_u = extern union {
    __sa_handler: ?*const fn (c_int) callconv(.C) void,
    __sa_sigaction: ?*const fn (c_int, [*c]struct___siginfo, ?*anyopaque) callconv(.C) void,
};
pub const struct___sigaction = extern struct {
    __sigaction_u: union___sigaction_u,
    sa_tramp: ?*const fn (?*anyopaque, c_int, c_int, [*c]siginfo_t, ?*anyopaque) callconv(.C) void,
    sa_mask: sigset_t,
    sa_flags: c_int,
};
pub const struct_sigaction = extern struct {
    __sigaction_u: union___sigaction_u,
    sa_mask: sigset_t,
    sa_flags: c_int,
};
pub const sig_t = ?*const fn (c_int) callconv(.C) void;
pub const struct_sigvec = extern struct {
    sv_handler: ?*const fn (c_int) callconv(.C) void,
    sv_mask: c_int,
    sv_flags: c_int,
};
pub const struct_sigstack = extern struct {
    ss_sp: [*c]u8,
    ss_onstack: c_int,
};
pub extern fn signal(c_int, ?fn (c_int) callconv(.C) void) ?fn (c_int) callconv(.C) void;
pub const struct_timeval = extern struct {
    tv_sec: __darwin_time_t,
    tv_usec: __darwin_suseconds_t,
};
pub const rlim_t = __uint64_t;
pub const struct_rusage = extern struct {
    ru_utime: struct_timeval,
    ru_stime: struct_timeval,
    ru_maxrss: c_long,
    ru_ixrss: c_long,
    ru_idrss: c_long,
    ru_isrss: c_long,
    ru_minflt: c_long,
    ru_majflt: c_long,
    ru_nswap: c_long,
    ru_inblock: c_long,
    ru_oublock: c_long,
    ru_msgsnd: c_long,
    ru_msgrcv: c_long,
    ru_nsignals: c_long,
    ru_nvcsw: c_long,
    ru_nivcsw: c_long,
};
pub const rusage_info_t = ?*anyopaque;
pub const struct_rusage_info_v0 = extern struct {
    ri_uuid: [16]u8,
    ri_user_time: u64,
    ri_system_time: u64,
    ri_pkg_idle_wkups: u64,
    ri_interrupt_wkups: u64,
    ri_pageins: u64,
    ri_wired_size: u64,
    ri_resident_size: u64,
    ri_phys_footprint: u64,
    ri_proc_start_abstime: u64,
    ri_proc_exit_abstime: u64,
};
pub const struct_rusage_info_v1 = extern struct {
    ri_uuid: [16]u8,
    ri_user_time: u64,
    ri_system_time: u64,
    ri_pkg_idle_wkups: u64,
    ri_interrupt_wkups: u64,
    ri_pageins: u64,
    ri_wired_size: u64,
    ri_resident_size: u64,
    ri_phys_footprint: u64,
    ri_proc_start_abstime: u64,
    ri_proc_exit_abstime: u64,
    ri_child_user_time: u64,
    ri_child_system_time: u64,
    ri_child_pkg_idle_wkups: u64,
    ri_child_interrupt_wkups: u64,
    ri_child_pageins: u64,
    ri_child_elapsed_abstime: u64,
};
pub const struct_rusage_info_v2 = extern struct {
    ri_uuid: [16]u8,
    ri_user_time: u64,
    ri_system_time: u64,
    ri_pkg_idle_wkups: u64,
    ri_interrupt_wkups: u64,
    ri_pageins: u64,
    ri_wired_size: u64,
    ri_resident_size: u64,
    ri_phys_footprint: u64,
    ri_proc_start_abstime: u64,
    ri_proc_exit_abstime: u64,
    ri_child_user_time: u64,
    ri_child_system_time: u64,
    ri_child_pkg_idle_wkups: u64,
    ri_child_interrupt_wkups: u64,
    ri_child_pageins: u64,
    ri_child_elapsed_abstime: u64,
    ri_diskio_bytesread: u64,
    ri_diskio_byteswritten: u64,
};
pub const struct_rusage_info_v3 = extern struct {
    ri_uuid: [16]u8,
    ri_user_time: u64,
    ri_system_time: u64,
    ri_pkg_idle_wkups: u64,
    ri_interrupt_wkups: u64,
    ri_pageins: u64,
    ri_wired_size: u64,
    ri_resident_size: u64,
    ri_phys_footprint: u64,
    ri_proc_start_abstime: u64,
    ri_proc_exit_abstime: u64,
    ri_child_user_time: u64,
    ri_child_system_time: u64,
    ri_child_pkg_idle_wkups: u64,
    ri_child_interrupt_wkups: u64,
    ri_child_pageins: u64,
    ri_child_elapsed_abstime: u64,
    ri_diskio_bytesread: u64,
    ri_diskio_byteswritten: u64,
    ri_cpu_time_qos_default: u64,
    ri_cpu_time_qos_maintenance: u64,
    ri_cpu_time_qos_background: u64,
    ri_cpu_time_qos_utility: u64,
    ri_cpu_time_qos_legacy: u64,
    ri_cpu_time_qos_user_initiated: u64,
    ri_cpu_time_qos_user_interactive: u64,
    ri_billed_system_time: u64,
    ri_serviced_system_time: u64,
};
pub const struct_rusage_info_v4 = extern struct {
    ri_uuid: [16]u8,
    ri_user_time: u64,
    ri_system_time: u64,
    ri_pkg_idle_wkups: u64,
    ri_interrupt_wkups: u64,
    ri_pageins: u64,
    ri_wired_size: u64,
    ri_resident_size: u64,
    ri_phys_footprint: u64,
    ri_proc_start_abstime: u64,
    ri_proc_exit_abstime: u64,
    ri_child_user_time: u64,
    ri_child_system_time: u64,
    ri_child_pkg_idle_wkups: u64,
    ri_child_interrupt_wkups: u64,
    ri_child_pageins: u64,
    ri_child_elapsed_abstime: u64,
    ri_diskio_bytesread: u64,
    ri_diskio_byteswritten: u64,
    ri_cpu_time_qos_default: u64,
    ri_cpu_time_qos_maintenance: u64,
    ri_cpu_time_qos_background: u64,
    ri_cpu_time_qos_utility: u64,
    ri_cpu_time_qos_legacy: u64,
    ri_cpu_time_qos_user_initiated: u64,
    ri_cpu_time_qos_user_interactive: u64,
    ri_billed_system_time: u64,
    ri_serviced_system_time: u64,
    ri_logical_writes: u64,
    ri_lifetime_max_phys_footprint: u64,
    ri_instructions: u64,
    ri_cycles: u64,
    ri_billed_energy: u64,
    ri_serviced_energy: u64,
    ri_interval_max_phys_footprint: u64,
    ri_runnable_time: u64,
};
pub const struct_rusage_info_v5 = extern struct {
    ri_uuid: [16]u8,
    ri_user_time: u64,
    ri_system_time: u64,
    ri_pkg_idle_wkups: u64,
    ri_interrupt_wkups: u64,
    ri_pageins: u64,
    ri_wired_size: u64,
    ri_resident_size: u64,
    ri_phys_footprint: u64,
    ri_proc_start_abstime: u64,
    ri_proc_exit_abstime: u64,
    ri_child_user_time: u64,
    ri_child_system_time: u64,
    ri_child_pkg_idle_wkups: u64,
    ri_child_interrupt_wkups: u64,
    ri_child_pageins: u64,
    ri_child_elapsed_abstime: u64,
    ri_diskio_bytesread: u64,
    ri_diskio_byteswritten: u64,
    ri_cpu_time_qos_default: u64,
    ri_cpu_time_qos_maintenance: u64,
    ri_cpu_time_qos_background: u64,
    ri_cpu_time_qos_utility: u64,
    ri_cpu_time_qos_legacy: u64,
    ri_cpu_time_qos_user_initiated: u64,
    ri_cpu_time_qos_user_interactive: u64,
    ri_billed_system_time: u64,
    ri_serviced_system_time: u64,
    ri_logical_writes: u64,
    ri_lifetime_max_phys_footprint: u64,
    ri_instructions: u64,
    ri_cycles: u64,
    ri_billed_energy: u64,
    ri_serviced_energy: u64,
    ri_interval_max_phys_footprint: u64,
    ri_runnable_time: u64,
    ri_flags: u64,
};
pub const rusage_info_current = struct_rusage_info_v5;
pub const struct_rlimit = extern struct {
    rlim_cur: rlim_t,
    rlim_max: rlim_t,
};
pub const struct_proc_rlimit_control_wakeupmon = extern struct {
    wm_flags: u32,
    wm_rate: i32,
};
pub extern fn getpriority(c_int, id_t) c_int;
pub extern fn getiopolicy_np(c_int, c_int) c_int;
pub extern fn getrlimit(c_int, [*c]struct_rlimit) c_int;
pub extern fn getrusage(c_int, [*c]struct_rusage) c_int;
pub extern fn setpriority(c_int, id_t, c_int) c_int;
pub extern fn setiopolicy_np(c_int, c_int, c_int) c_int;
pub extern fn setrlimit(c_int, [*c]const struct_rlimit) c_int;
pub fn _OSSwapInt16(arg__data: u16) callconv(.C) u16 {
    var _data = arg__data;
    return @bitCast(u16, @truncate(c_short, (@bitCast(c_int, @as(c_uint, _data)) << @intCast(@import("std").math.Log2Int(c_int), 8)) | (@bitCast(c_int, @as(c_uint, _data)) >> @intCast(@import("std").math.Log2Int(c_int), 8))));
}
pub fn _OSSwapInt32(arg__data: u32) callconv(.C) u32 {
    var _data = arg__data;
    _data = __builtin_bswap32(_data);
    return _data;
}
pub fn _OSSwapInt64(arg__data: u64) callconv(.C) u64 {
    var _data = arg__data;
    return __builtin_bswap64(_data);
}
pub const struct__OSUnalignedU16 = packed struct {
    __val: u16,
};
pub const struct__OSUnalignedU32 = packed struct {
    __val: u32,
};
pub const struct__OSUnalignedU64 = packed struct {
    __val: u64,
};
pub fn OSReadSwapInt16(arg__base: ?*const volatile anyopaque, arg__offset: usize) callconv(.C) u16 {
    var _base = arg__base;
    var _offset = arg__offset;
    return _OSSwapInt16(@intToPtr([*c]struct__OSUnalignedU16, @intCast(usize, @ptrToInt(_base)) +% _offset).*.__val);
}
pub fn OSReadSwapInt32(arg__base: ?*const volatile anyopaque, arg__offset: usize) callconv(.C) u32 {
    var _base = arg__base;
    var _offset = arg__offset;
    return _OSSwapInt32(@intToPtr([*c]struct__OSUnalignedU32, @intCast(usize, @ptrToInt(_base)) +% _offset).*.__val);
}
pub fn OSReadSwapInt64(arg__base: ?*const volatile anyopaque, arg__offset: usize) callconv(.C) u64 {
    var _base = arg__base;
    var _offset = arg__offset;
    return _OSSwapInt64(@intToPtr([*c]struct__OSUnalignedU64, @intCast(usize, @ptrToInt(_base)) +% _offset).*.__val);
}
pub fn OSWriteSwapInt16(arg__base: ?*volatile anyopaque, arg__offset: usize, arg__data: u16) callconv(.C) void {
    var _base = arg__base;
    var _offset = arg__offset;
    var _data = arg__data;
    @intToPtr([*c]struct__OSUnalignedU16, @intCast(usize, @ptrToInt(_base)) +% _offset).*.__val = _OSSwapInt16(_data);
}
pub fn OSWriteSwapInt32(arg__base: ?*volatile anyopaque, arg__offset: usize, arg__data: u32) callconv(.C) void {
    var _base = arg__base;
    var _offset = arg__offset;
    var _data = arg__data;
    @intToPtr([*c]struct__OSUnalignedU32, @intCast(usize, @ptrToInt(_base)) +% _offset).*.__val = _OSSwapInt32(_data);
}
pub fn OSWriteSwapInt64(arg__base: ?*volatile anyopaque, arg__offset: usize, arg__data: u64) callconv(.C) void {
    var _base = arg__base;
    var _offset = arg__offset;
    var _data = arg__data;
    @intToPtr([*c]struct__OSUnalignedU64, @intCast(usize, @ptrToInt(_base)) +% _offset).*.__val = _OSSwapInt64(_data);
} // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/wait.h:201:19: warning: struct demoted to opaque type - has bitfield
const struct_unnamed_1 = opaque {}; // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/wait.h:220:19: warning: struct demoted to opaque type - has bitfield
const struct_unnamed_2 = opaque {};
pub const union_wait = extern union {
    w_status: c_int,
    w_T: struct_unnamed_1,
    w_S: struct_unnamed_2,
};
pub extern fn wait([*c]c_int) pid_t;
pub extern fn waitpid(pid_t, [*c]c_int, c_int) pid_t;
pub extern fn waitid(idtype_t, id_t, [*c]siginfo_t, c_int) c_int;
pub extern fn wait3([*c]c_int, c_int, [*c]struct_rusage) pid_t;
pub extern fn wait4(pid_t, [*c]c_int, c_int, [*c]struct_rusage) pid_t;
pub extern fn alloca(c_ulong) ?*anyopaque;
pub const ct_rune_t = __darwin_ct_rune_t;
pub const rune_t = __darwin_rune_t;
pub const div_t = extern struct {
    quot: c_int,
    rem: c_int,
};
pub const ldiv_t = extern struct {
    quot: c_long,
    rem: c_long,
};
pub const lldiv_t = extern struct {
    quot: c_longlong,
    rem: c_longlong,
};
pub extern var __mb_cur_max: c_int;
pub extern fn malloc(__size: c_ulong) ?*anyopaque;
pub extern fn calloc(__count: c_ulong, __size: c_ulong) ?*anyopaque;
pub extern fn free(?*anyopaque) void;
pub extern fn realloc(__ptr: ?*anyopaque, __size: c_ulong) ?*anyopaque;
pub extern fn valloc(usize) ?*anyopaque;
pub extern fn aligned_alloc(__alignment: c_ulong, __size: c_ulong) ?*anyopaque;
pub extern fn posix_memalign(__memptr: [*c]?*anyopaque, __alignment: usize, __size: usize) c_int;
pub extern fn abort() noreturn;
pub extern fn abs(c_int) c_int;
pub extern fn atexit(?fn () callconv(.C) void) c_int;
pub extern fn atof([*c]const u8) f64;
pub extern fn atoi([*c]const u8) c_int;
pub extern fn atol([*c]const u8) c_long;
pub extern fn atoll([*c]const u8) c_longlong;
pub extern fn bsearch(__key: ?*const anyopaque, __base: ?*const anyopaque, __nel: usize, __width: usize, __compar: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) ?*anyopaque;
pub extern fn div(c_int, c_int) div_t;
pub extern fn exit(c_int) noreturn;
pub extern fn getenv([*c]const u8) [*c]u8;
pub extern fn labs(c_long) c_long;
pub extern fn ldiv(c_long, c_long) ldiv_t;
pub extern fn llabs(c_longlong) c_longlong;
pub extern fn lldiv(c_longlong, c_longlong) lldiv_t;
pub extern fn mblen(__s: [*c]const u8, __n: usize) c_int;
pub extern fn mbstowcs(noalias [*c]wchar_t, noalias [*c]const u8, usize) usize;
pub extern fn mbtowc(noalias [*c]wchar_t, noalias [*c]const u8, usize) c_int;
pub extern fn qsort(__base: ?*anyopaque, __nel: usize, __width: usize, __compar: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) void;
pub extern fn rand() c_int;
pub extern fn srand(c_uint) void;
pub extern fn strtod([*c]const u8, [*c][*c]u8) f64;
pub extern fn strtof([*c]const u8, [*c][*c]u8) f32;
pub extern fn strtol(__str: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_long;
pub extern fn strtold([*c]const u8, [*c][*c]u8) c_longdouble;
pub extern fn strtoll(__str: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_longlong;
pub extern fn strtoul(__str: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_ulong;
pub extern fn strtoull(__str: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_ulonglong;
pub extern fn system([*c]const u8) c_int;
pub extern fn wcstombs(noalias [*c]u8, noalias [*c]const wchar_t, usize) usize;
pub extern fn wctomb([*c]u8, wchar_t) c_int;
pub extern fn _Exit(c_int) noreturn;
pub extern fn a64l([*c]const u8) c_long;
pub extern fn drand48() f64;
pub extern fn ecvt(f64, c_int, noalias [*c]c_int, noalias [*c]c_int) [*c]u8;
pub extern fn erand48([*c]c_ushort) f64;
pub extern fn fcvt(f64, c_int, noalias [*c]c_int, noalias [*c]c_int) [*c]u8;
pub extern fn gcvt(f64, c_int, [*c]u8) [*c]u8;
pub extern fn getsubopt([*c][*c]u8, [*c]const [*c]u8, [*c][*c]u8) c_int;
pub extern fn grantpt(c_int) c_int;
pub extern fn initstate(c_uint, [*c]u8, usize) [*c]u8;
pub extern fn jrand48([*c]c_ushort) c_long;
pub extern fn l64a(c_long) [*c]u8;
pub extern fn lcong48([*c]c_ushort) void;
pub extern fn lrand48() c_long;
pub extern fn mktemp([*c]u8) [*c]u8;
pub extern fn mkstemp([*c]u8) c_int;
pub extern fn mrand48() c_long;
pub extern fn nrand48([*c]c_ushort) c_long;
pub extern fn posix_openpt(c_int) c_int;
pub extern fn ptsname(c_int) [*c]u8;
pub extern fn ptsname_r(fildes: c_int, buffer: [*c]u8, buflen: usize) c_int;
pub extern fn putenv([*c]u8) c_int;
pub extern fn random() c_long;
pub extern fn rand_r([*c]c_uint) c_int;
pub extern fn realpath(noalias [*c]const u8, noalias [*c]u8) [*c]u8;
pub extern fn seed48([*c]c_ushort) [*c]c_ushort;
pub extern fn setenv(__name: [*c]const u8, __value: [*c]const u8, __overwrite: c_int) c_int;
pub extern fn setkey([*c]const u8) void;
pub extern fn setstate([*c]const u8) [*c]u8;
pub extern fn srand48(c_long) void;
pub extern fn srandom(c_uint) void;
pub extern fn unlockpt(c_int) c_int;
pub extern fn unsetenv([*c]const u8) c_int;
pub const dev_t = __darwin_dev_t;
pub const mode_t = __darwin_mode_t;
pub extern fn arc4random() u32;
pub extern fn arc4random_addrandom([*c]u8, c_int) void;
pub extern fn arc4random_buf(__buf: ?*anyopaque, __nbytes: usize) void;
pub extern fn arc4random_stir() void;
pub extern fn arc4random_uniform(__upper_bound: u32) u32; // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:268:6: warning: unsupported type: 'BlockPointer'
pub const atexit_b = @compileError("unable to resolve prototype of function"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:268:6
// /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:277:7: warning: unsupported type: 'BlockPointer'
pub const bsearch_b = @compileError("unable to resolve prototype of function"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:277:7
pub extern fn cgetcap([*c]u8, [*c]const u8, c_int) [*c]u8;
pub extern fn cgetclose() c_int;
pub extern fn cgetent([*c][*c]u8, [*c][*c]u8, [*c]const u8) c_int;
pub extern fn cgetfirst([*c][*c]u8, [*c][*c]u8) c_int;
pub extern fn cgetmatch([*c]const u8, [*c]const u8) c_int;
pub extern fn cgetnext([*c][*c]u8, [*c][*c]u8) c_int;
pub extern fn cgetnum([*c]u8, [*c]const u8, [*c]c_long) c_int;
pub extern fn cgetset([*c]const u8) c_int;
pub extern fn cgetstr([*c]u8, [*c]const u8, [*c][*c]u8) c_int;
pub extern fn cgetustr([*c]u8, [*c]const u8, [*c][*c]u8) c_int;
pub extern fn daemon(c_int, c_int) c_int;
pub extern fn devname(dev_t, mode_t) [*c]u8;
pub extern fn devname_r(dev_t, mode_t, buf: [*c]u8, len: c_int) [*c]u8;
pub extern fn getbsize([*c]c_int, [*c]c_long) [*c]u8;
pub extern fn getloadavg([*c]f64, c_int) c_int;
pub extern fn getprogname() [*c]const u8;
pub extern fn setprogname([*c]const u8) void;
pub extern fn heapsort(__base: ?*anyopaque, __nel: usize, __width: usize, __compar: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) c_int; // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:314:6: warning: unsupported type: 'BlockPointer'
pub const heapsort_b = @compileError("unable to resolve prototype of function"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:314:6
pub extern fn mergesort(__base: ?*anyopaque, __nel: usize, __width: usize, __compar: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) c_int; // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:321:6: warning: unsupported type: 'BlockPointer'
pub const mergesort_b = @compileError("unable to resolve prototype of function"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:321:6
pub extern fn psort(__base: ?*anyopaque, __nel: usize, __width: usize, __compar: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) void; // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:329:7: warning: unsupported type: 'BlockPointer'
pub const psort_b = @compileError("unable to resolve prototype of function"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:329:7
pub extern fn psort_r(__base: ?*anyopaque, __nel: usize, __width: usize, ?*anyopaque, __compar: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) void; // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:337:7: warning: unsupported type: 'BlockPointer'
pub const qsort_b = @compileError("unable to resolve prototype of function"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:337:7
pub extern fn qsort_r(__base: ?*anyopaque, __nel: usize, __width: usize, ?*anyopaque, __compar: ?*const fn (?*anyopaque, ?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) void;
pub extern fn radixsort(__base: [*c][*c]const u8, __nel: c_int, __table: [*c]const u8, __endbyte: c_uint) c_int;
pub extern fn rpmatch([*c]const u8) c_int;
pub extern fn sradixsort(__base: [*c][*c]const u8, __nel: c_int, __table: [*c]const u8, __endbyte: c_uint) c_int;
pub extern fn sranddev() void;
pub extern fn srandomdev() void;
pub extern fn reallocf(__ptr: ?*anyopaque, __size: usize) ?*anyopaque;
pub extern fn strtonum(__numstr: [*c]const u8, __minval: c_longlong, __maxval: c_longlong, __errstrp: [*c][*c]const u8) c_longlong;
pub extern fn strtoq(__str: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_longlong;
pub extern fn strtouq(__str: [*c]const u8, __endptr: [*c][*c]u8, __base: c_int) c_ulonglong;
pub extern var suboptarg: [*c]u8;
pub const jmp_buf = [48]c_int;
pub const sigjmp_buf = [49]c_int;
pub extern fn setjmp([*c]c_int) c_int;
pub extern fn longjmp([*c]c_int, c_int) noreturn;
pub extern fn _setjmp([*c]c_int) c_int;
pub extern fn _longjmp([*c]c_int, c_int) noreturn;
pub extern fn sigsetjmp([*c]c_int, c_int) c_int;
pub extern fn siglongjmp([*c]c_int, c_int) noreturn;
pub extern fn longjmperror() void;
pub const __gnuc_va_list = __builtin_va_list;
pub const FT_Int16 = c_short;
pub const FT_UInt16 = c_ushort;
pub const FT_Int32 = c_int;
pub const FT_UInt32 = c_uint;
pub const FT_Fast = c_int;
pub const FT_UFast = c_uint;
pub const FT_Int64 = c_long;
pub const FT_UInt64 = c_ulong;
pub extern fn __error() [*c]c_int;
pub const FT_Memory = [*c]struct_FT_MemoryRec_;
pub const FT_Alloc_Func = ?*const fn (FT_Memory, c_long) callconv(.C) ?*anyopaque;
pub const FT_Free_Func = ?*const fn (FT_Memory, ?*anyopaque) callconv(.C) void;
pub const FT_Realloc_Func = ?*const fn (FT_Memory, c_long, c_long, ?*anyopaque) callconv(.C) ?*anyopaque;
pub const struct_FT_MemoryRec_ = extern struct {
    user: ?*anyopaque,
    alloc: FT_Alloc_Func,
    free: FT_Free_Func,
    realloc: FT_Realloc_Func,
};
pub const union_FT_StreamDesc_ = extern union {
    value: c_long,
    pointer: ?*anyopaque,
};
pub const FT_StreamDesc = union_FT_StreamDesc_;
pub const FT_Stream = [*c]struct_FT_StreamRec_;
pub const FT_Stream_IoFunc = ?*const fn (FT_Stream, c_ulong, [*c]u8, c_ulong) callconv(.C) c_ulong;
pub const FT_Stream_CloseFunc = ?*const fn (FT_Stream) callconv(.C) void;
pub const struct_FT_StreamRec_ = extern struct {
    base: [*c]u8,
    size: c_ulong,
    pos: c_ulong,
    descriptor: FT_StreamDesc,
    pathname: FT_StreamDesc,
    read: FT_Stream_IoFunc,
    close: FT_Stream_CloseFunc,
    memory: FT_Memory,
    cursor: [*c]u8,
    limit: [*c]u8,
};
pub const FT_StreamRec = struct_FT_StreamRec_;
pub const FT_Pos = c_long;
pub const struct_FT_Vector_ = extern struct {
    x: FT_Pos,
    y: FT_Pos,
};
pub const FT_Vector = struct_FT_Vector_;
pub const struct_FT_BBox_ = extern struct {
    xMin: FT_Pos,
    yMin: FT_Pos,
    xMax: FT_Pos,
    yMax: FT_Pos,
};
pub const FT_BBox = struct_FT_BBox_;
pub const FT_PIXEL_MODE_NONE: c_int = 0;
pub const FT_PIXEL_MODE_MONO: c_int = 1;
pub const FT_PIXEL_MODE_GRAY: c_int = 2;
pub const FT_PIXEL_MODE_GRAY2: c_int = 3;
pub const FT_PIXEL_MODE_GRAY4: c_int = 4;
pub const FT_PIXEL_MODE_LCD: c_int = 5;
pub const FT_PIXEL_MODE_LCD_V: c_int = 6;
pub const FT_PIXEL_MODE_BGRA: c_int = 7;
pub const FT_PIXEL_MODE_MAX: c_int = 8;
pub const enum_FT_Pixel_Mode_ = c_uint;
pub const FT_Pixel_Mode = enum_FT_Pixel_Mode_;
pub const struct_FT_Bitmap_ = extern struct {
    rows: c_uint,
    width: c_uint,
    pitch: c_int,
    buffer: [*c]u8,
    num_grays: c_ushort,
    pixel_mode: u8,
    palette_mode: u8,
    palette: ?*anyopaque,
};
pub const FT_Bitmap = struct_FT_Bitmap_;
pub const struct_FT_Outline_ = extern struct {
    n_contours: c_short,
    n_points: c_short,
    points: [*c]FT_Vector,
    tags: [*c]u8,
    contours: [*c]c_short,
    flags: c_int,
};
pub const FT_Outline = struct_FT_Outline_;
pub const FT_Outline_MoveToFunc = ?*const fn ([*c]const FT_Vector, ?*anyopaque) callconv(.C) c_int;
pub const FT_Outline_LineToFunc = ?*const fn ([*c]const FT_Vector, ?*anyopaque) callconv(.C) c_int;
pub const FT_Outline_ConicToFunc = ?*const fn ([*c]const FT_Vector, [*c]const FT_Vector, ?*anyopaque) callconv(.C) c_int;
pub const FT_Outline_CubicToFunc = ?*const fn ([*c]const FT_Vector, [*c]const FT_Vector, [*c]const FT_Vector, ?*anyopaque) callconv(.C) c_int;
pub const struct_FT_Outline_Funcs_ = extern struct {
    move_to: FT_Outline_MoveToFunc,
    line_to: FT_Outline_LineToFunc,
    conic_to: FT_Outline_ConicToFunc,
    cubic_to: FT_Outline_CubicToFunc,
    shift: c_int,
    delta: FT_Pos,
};
pub const FT_Outline_Funcs = struct_FT_Outline_Funcs_;
pub const FT_GLYPH_FORMAT_NONE: c_int = 0;
pub const FT_GLYPH_FORMAT_COMPOSITE: c_int = 1668246896;
pub const FT_GLYPH_FORMAT_BITMAP: c_int = 1651078259;
pub const FT_GLYPH_FORMAT_OUTLINE: c_int = 1869968492;
pub const FT_GLYPH_FORMAT_PLOTTER: c_int = 1886154612;
pub const FT_GLYPH_FORMAT_SVG: c_int = 1398163232;
pub const enum_FT_Glyph_Format_ = c_uint;
pub const FT_Glyph_Format = enum_FT_Glyph_Format_;
pub const struct_FT_Span_ = extern struct {
    x: c_short,
    len: c_ushort,
    coverage: u8,
};
pub const FT_Span = struct_FT_Span_;
pub const FT_SpanFunc = ?*const fn (c_int, c_int, [*c]const FT_Span, ?*anyopaque) callconv(.C) void;
pub const FT_Raster_BitTest_Func = ?*const fn (c_int, c_int, ?*anyopaque) callconv(.C) c_int;
pub const FT_Raster_BitSet_Func = ?*const fn (c_int, c_int, ?*anyopaque) callconv(.C) void;
pub const struct_FT_Raster_Params_ = extern struct {
    target: [*c]const FT_Bitmap,
    source: ?*const anyopaque,
    flags: c_int,
    gray_spans: FT_SpanFunc,
    black_spans: FT_SpanFunc,
    bit_test: FT_Raster_BitTest_Func,
    bit_set: FT_Raster_BitSet_Func,
    user: ?*anyopaque,
    clip_box: FT_BBox,
};
pub const FT_Raster_Params = struct_FT_Raster_Params_;
pub const struct_FT_RasterRec_ = opaque {};
pub const FT_Raster = ?*struct_FT_RasterRec_;
pub const FT_Raster_NewFunc = ?*const fn (?*anyopaque, [*c]FT_Raster) callconv(.C) c_int;
pub const FT_Raster_DoneFunc = ?*const fn (FT_Raster) callconv(.C) void;
pub const FT_Raster_ResetFunc = ?*const fn (FT_Raster, [*c]u8, c_ulong) callconv(.C) void;
pub const FT_Raster_SetModeFunc = ?*const fn (FT_Raster, c_ulong, ?*anyopaque) callconv(.C) c_int;
pub const FT_Raster_RenderFunc = ?*const fn (FT_Raster, [*c]const FT_Raster_Params) callconv(.C) c_int;
pub const struct_FT_Raster_Funcs_ = extern struct {
    glyph_format: FT_Glyph_Format,
    raster_new: FT_Raster_NewFunc,
    raster_reset: FT_Raster_ResetFunc,
    raster_set_mode: FT_Raster_SetModeFunc,
    raster_render: FT_Raster_RenderFunc,
    raster_done: FT_Raster_DoneFunc,
};
pub const FT_Raster_Funcs = struct_FT_Raster_Funcs_;
pub const FT_Bool = u8;
pub const FT_FWord = c_short;
pub const FT_UFWord = c_ushort;
pub const FT_Char = i8;
pub const FT_Byte = u8;
pub const FT_Bytes = [*c]const FT_Byte;
pub const FT_Tag = FT_UInt32;
pub const FT_String = u8;
pub const FT_Short = c_short;
pub const FT_UShort = c_ushort;
pub const FT_Int = c_int;
pub const FT_UInt = c_uint;
pub const FT_Long = c_long;
pub const FT_ULong = c_ulong;
pub const FT_F2Dot14 = c_short;
pub const FT_F26Dot6 = c_long;
pub const FT_Fixed = c_long;
pub const FT_Error = c_int;
pub const FT_Pointer = ?*anyopaque;
pub const FT_Offset = usize;
pub const FT_PtrDist = ptrdiff_t;
pub const struct_FT_UnitVector_ = extern struct {
    x: FT_F2Dot14,
    y: FT_F2Dot14,
};
pub const FT_UnitVector = struct_FT_UnitVector_;
pub const struct_FT_Matrix_ = extern struct {
    xx: FT_Fixed,
    xy: FT_Fixed,
    yx: FT_Fixed,
    yy: FT_Fixed,
};
pub const FT_Matrix = struct_FT_Matrix_;
pub const struct_FT_Data_ = extern struct {
    pointer: [*c]const FT_Byte,
    length: FT_UInt,
};
pub const FT_Data = struct_FT_Data_;
pub const FT_Generic_Finalizer = ?*const fn (?*anyopaque) callconv(.C) void;
pub const struct_FT_Generic_ = extern struct {
    data: ?*anyopaque,
    finalizer: FT_Generic_Finalizer,
};
pub const FT_Generic = struct_FT_Generic_;
pub const FT_ListNode = [*c]struct_FT_ListNodeRec_;
pub const struct_FT_ListNodeRec_ = extern struct {
    prev: FT_ListNode,
    next: FT_ListNode,
    data: ?*anyopaque,
};
pub const struct_FT_ListRec_ = extern struct {
    head: FT_ListNode,
    tail: FT_ListNode,
};
pub const FT_List = [*c]struct_FT_ListRec_;
pub const FT_ListNodeRec = struct_FT_ListNodeRec_;
pub const FT_ListRec = struct_FT_ListRec_;
pub const FT_Mod_Err_Base: c_int = 0;
pub const FT_Mod_Err_Autofit: c_int = 0;
pub const FT_Mod_Err_BDF: c_int = 0;
pub const FT_Mod_Err_Bzip2: c_int = 0;
pub const FT_Mod_Err_Cache: c_int = 0;
pub const FT_Mod_Err_CFF: c_int = 0;
pub const FT_Mod_Err_CID: c_int = 0;
pub const FT_Mod_Err_Gzip: c_int = 0;
pub const FT_Mod_Err_LZW: c_int = 0;
pub const FT_Mod_Err_OTvalid: c_int = 0;
pub const FT_Mod_Err_PCF: c_int = 0;
pub const FT_Mod_Err_PFR: c_int = 0;
pub const FT_Mod_Err_PSaux: c_int = 0;
pub const FT_Mod_Err_PShinter: c_int = 0;
pub const FT_Mod_Err_PSnames: c_int = 0;
pub const FT_Mod_Err_Raster: c_int = 0;
pub const FT_Mod_Err_SFNT: c_int = 0;
pub const FT_Mod_Err_Smooth: c_int = 0;
pub const FT_Mod_Err_TrueType: c_int = 0;
pub const FT_Mod_Err_Type1: c_int = 0;
pub const FT_Mod_Err_Type42: c_int = 0;
pub const FT_Mod_Err_Winfonts: c_int = 0;
pub const FT_Mod_Err_GXvalid: c_int = 0;
pub const FT_Mod_Err_Sdf: c_int = 0;
pub const FT_Mod_Err_Max: c_int = 1;
const enum_unnamed_3 = c_uint;
pub const FT_Err_Ok: c_int = 0;
pub const FT_Err_Cannot_Open_Resource: c_int = 1;
pub const FT_Err_Unknown_File_Format: c_int = 2;
pub const FT_Err_Invalid_File_Format: c_int = 3;
pub const FT_Err_Invalid_Version: c_int = 4;
pub const FT_Err_Lower_Module_Version: c_int = 5;
pub const FT_Err_Invalid_Argument: c_int = 6;
pub const FT_Err_Unimplemented_Feature: c_int = 7;
pub const FT_Err_Invalid_Table: c_int = 8;
pub const FT_Err_Invalid_Offset: c_int = 9;
pub const FT_Err_Array_Too_Large: c_int = 10;
pub const FT_Err_Missing_Module: c_int = 11;
pub const FT_Err_Missing_Property: c_int = 12;
pub const FT_Err_Invalid_Glyph_Index: c_int = 16;
pub const FT_Err_Invalid_Character_Code: c_int = 17;
pub const FT_Err_Invalid_Glyph_Format: c_int = 18;
pub const FT_Err_Cannot_Render_Glyph: c_int = 19;
pub const FT_Err_Invalid_Outline: c_int = 20;
pub const FT_Err_Invalid_Composite: c_int = 21;
pub const FT_Err_Too_Many_Hints: c_int = 22;
pub const FT_Err_Invalid_Pixel_Size: c_int = 23;
pub const FT_Err_Invalid_SVG_Document: c_int = 24;
pub const FT_Err_Invalid_Handle: c_int = 32;
pub const FT_Err_Invalid_Library_Handle: c_int = 33;
pub const FT_Err_Invalid_Driver_Handle: c_int = 34;
pub const FT_Err_Invalid_Face_Handle: c_int = 35;
pub const FT_Err_Invalid_Size_Handle: c_int = 36;
pub const FT_Err_Invalid_Slot_Handle: c_int = 37;
pub const FT_Err_Invalid_CharMap_Handle: c_int = 38;
pub const FT_Err_Invalid_Cache_Handle: c_int = 39;
pub const FT_Err_Invalid_Stream_Handle: c_int = 40;
pub const FT_Err_Too_Many_Drivers: c_int = 48;
pub const FT_Err_Too_Many_Extensions: c_int = 49;
pub const FT_Err_Out_Of_Memory: c_int = 64;
pub const FT_Err_Unlisted_Object: c_int = 65;
pub const FT_Err_Cannot_Open_Stream: c_int = 81;
pub const FT_Err_Invalid_Stream_Seek: c_int = 82;
pub const FT_Err_Invalid_Stream_Skip: c_int = 83;
pub const FT_Err_Invalid_Stream_Read: c_int = 84;
pub const FT_Err_Invalid_Stream_Operation: c_int = 85;
pub const FT_Err_Invalid_Frame_Operation: c_int = 86;
pub const FT_Err_Nested_Frame_Access: c_int = 87;
pub const FT_Err_Invalid_Frame_Read: c_int = 88;
pub const FT_Err_Raster_Uninitialized: c_int = 96;
pub const FT_Err_Raster_Corrupted: c_int = 97;
pub const FT_Err_Raster_Overflow: c_int = 98;
pub const FT_Err_Raster_Negative_Height: c_int = 99;
pub const FT_Err_Too_Many_Caches: c_int = 112;
pub const FT_Err_Invalid_Opcode: c_int = 128;
pub const FT_Err_Too_Few_Arguments: c_int = 129;
pub const FT_Err_Stack_Overflow: c_int = 130;
pub const FT_Err_Code_Overflow: c_int = 131;
pub const FT_Err_Bad_Argument: c_int = 132;
pub const FT_Err_Divide_By_Zero: c_int = 133;
pub const FT_Err_Invalid_Reference: c_int = 134;
pub const FT_Err_Debug_OpCode: c_int = 135;
pub const FT_Err_ENDF_In_Exec_Stream: c_int = 136;
pub const FT_Err_Nested_DEFS: c_int = 137;
pub const FT_Err_Invalid_CodeRange: c_int = 138;
pub const FT_Err_Execution_Too_Long: c_int = 139;
pub const FT_Err_Too_Many_Function_Defs: c_int = 140;
pub const FT_Err_Too_Many_Instruction_Defs: c_int = 141;
pub const FT_Err_Table_Missing: c_int = 142;
pub const FT_Err_Horiz_Header_Missing: c_int = 143;
pub const FT_Err_Locations_Missing: c_int = 144;
pub const FT_Err_Name_Table_Missing: c_int = 145;
pub const FT_Err_CMap_Table_Missing: c_int = 146;
pub const FT_Err_Hmtx_Table_Missing: c_int = 147;
pub const FT_Err_Post_Table_Missing: c_int = 148;
pub const FT_Err_Invalid_Horiz_Metrics: c_int = 149;
pub const FT_Err_Invalid_CharMap_Format: c_int = 150;
pub const FT_Err_Invalid_PPem: c_int = 151;
pub const FT_Err_Invalid_Vert_Metrics: c_int = 152;
pub const FT_Err_Could_Not_Find_Context: c_int = 153;
pub const FT_Err_Invalid_Post_Table_Format: c_int = 154;
pub const FT_Err_Invalid_Post_Table: c_int = 155;
pub const FT_Err_DEF_In_Glyf_Bytecode: c_int = 156;
pub const FT_Err_Missing_Bitmap: c_int = 157;
pub const FT_Err_Missing_SVG_Hooks: c_int = 158;
pub const FT_Err_Syntax_Error: c_int = 160;
pub const FT_Err_Stack_Underflow: c_int = 161;
pub const FT_Err_Ignore: c_int = 162;
pub const FT_Err_No_Unicode_Glyph_Name: c_int = 163;
pub const FT_Err_Glyph_Too_Big: c_int = 164;
pub const FT_Err_Missing_Startfont_Field: c_int = 176;
pub const FT_Err_Missing_Font_Field: c_int = 177;
pub const FT_Err_Missing_Size_Field: c_int = 178;
pub const FT_Err_Missing_Fontboundingbox_Field: c_int = 179;
pub const FT_Err_Missing_Chars_Field: c_int = 180;
pub const FT_Err_Missing_Startchar_Field: c_int = 181;
pub const FT_Err_Missing_Encoding_Field: c_int = 182;
pub const FT_Err_Missing_Bbx_Field: c_int = 183;
pub const FT_Err_Bbx_Too_Big: c_int = 184;
pub const FT_Err_Corrupted_Font_Header: c_int = 185;
pub const FT_Err_Corrupted_Font_Glyphs: c_int = 186;
pub const FT_Err_Max: c_int = 187;
const enum_unnamed_4 = c_uint;
pub extern fn FT_Error_String(error_code: FT_Error) [*c]const u8;
pub const struct_FT_Glyph_Metrics_ = extern struct {
    width: FT_Pos,
    height: FT_Pos,
    horiBearingX: FT_Pos,
    horiBearingY: FT_Pos,
    horiAdvance: FT_Pos,
    vertBearingX: FT_Pos,
    vertBearingY: FT_Pos,
    vertAdvance: FT_Pos,
};
pub const FT_Glyph_Metrics = struct_FT_Glyph_Metrics_;
pub const struct_FT_Bitmap_Size_ = extern struct {
    height: FT_Short,
    width: FT_Short,
    size: FT_Pos,
    x_ppem: FT_Pos,
    y_ppem: FT_Pos,
};
pub const FT_Bitmap_Size = struct_FT_Bitmap_Size_;
pub const struct_FT_LibraryRec_ = opaque {};
pub const FT_Library = ?*struct_FT_LibraryRec_;
pub const struct_FT_ModuleRec_ = opaque {};
pub const FT_Module = ?*struct_FT_ModuleRec_;
pub const struct_FT_DriverRec_ = opaque {};
pub const FT_Driver = ?*struct_FT_DriverRec_;
pub const struct_FT_RendererRec_ = opaque {};
pub const FT_Renderer = ?*struct_FT_RendererRec_;
pub const FT_Face = [*c]struct_FT_FaceRec_;
pub const FT_ENCODING_NONE: c_int = 0;
pub const FT_ENCODING_MS_SYMBOL: c_int = 1937337698;
pub const FT_ENCODING_UNICODE: c_int = 1970170211;
pub const FT_ENCODING_SJIS: c_int = 1936353651;
pub const FT_ENCODING_PRC: c_int = 1734484000;
pub const FT_ENCODING_BIG5: c_int = 1651074869;
pub const FT_ENCODING_WANSUNG: c_int = 2002873971;
pub const FT_ENCODING_JOHAB: c_int = 1785686113;
pub const FT_ENCODING_GB2312: c_int = 1734484000;
pub const FT_ENCODING_MS_SJIS: c_int = 1936353651;
pub const FT_ENCODING_MS_GB2312: c_int = 1734484000;
pub const FT_ENCODING_MS_BIG5: c_int = 1651074869;
pub const FT_ENCODING_MS_WANSUNG: c_int = 2002873971;
pub const FT_ENCODING_MS_JOHAB: c_int = 1785686113;
pub const FT_ENCODING_ADOBE_STANDARD: c_int = 1094995778;
pub const FT_ENCODING_ADOBE_EXPERT: c_int = 1094992453;
pub const FT_ENCODING_ADOBE_CUSTOM: c_int = 1094992451;
pub const FT_ENCODING_ADOBE_LATIN_1: c_int = 1818326065;
pub const FT_ENCODING_OLD_LATIN_2: c_int = 1818326066;
pub const FT_ENCODING_APPLE_ROMAN: c_int = 1634889070;
pub const enum_FT_Encoding_ = c_uint;
pub const FT_Encoding = enum_FT_Encoding_;
pub const struct_FT_CharMapRec_ = extern struct {
    face: FT_Face,
    encoding: FT_Encoding,
    platform_id: FT_UShort,
    encoding_id: FT_UShort,
};
pub const FT_CharMap = [*c]struct_FT_CharMapRec_;
pub const struct_FT_SubGlyphRec_ = opaque {};
pub const FT_SubGlyph = ?*struct_FT_SubGlyphRec_;
pub const struct_FT_Slot_InternalRec_ = opaque {};
pub const FT_Slot_Internal = ?*struct_FT_Slot_InternalRec_;
pub const struct_FT_GlyphSlotRec_ = extern struct {
    library: FT_Library,
    face: FT_Face,
    next: FT_GlyphSlot,
    glyph_index: FT_UInt,
    generic: FT_Generic,
    metrics: FT_Glyph_Metrics,
    linearHoriAdvance: FT_Fixed,
    linearVertAdvance: FT_Fixed,
    advance: FT_Vector,
    format: FT_Glyph_Format,
    bitmap: FT_Bitmap,
    bitmap_left: FT_Int,
    bitmap_top: FT_Int,
    outline: FT_Outline,
    num_subglyphs: FT_UInt,
    subglyphs: FT_SubGlyph,
    control_data: ?*anyopaque,
    control_len: c_long,
    lsb_delta: FT_Pos,
    rsb_delta: FT_Pos,
    other: ?*anyopaque,
    internal: FT_Slot_Internal,
};
pub const FT_GlyphSlot = [*c]struct_FT_GlyphSlotRec_;
pub const struct_FT_Size_Metrics_ = extern struct {
    x_ppem: FT_UShort,
    y_ppem: FT_UShort,
    x_scale: FT_Fixed,
    y_scale: FT_Fixed,
    ascender: FT_Pos,
    descender: FT_Pos,
    height: FT_Pos,
    max_advance: FT_Pos,
};
pub const FT_Size_Metrics = struct_FT_Size_Metrics_;
pub const struct_FT_Size_InternalRec_ = opaque {};
pub const FT_Size_Internal = ?*struct_FT_Size_InternalRec_;
pub const struct_FT_SizeRec_ = extern struct {
    face: FT_Face,
    generic: FT_Generic,
    metrics: FT_Size_Metrics,
    internal: FT_Size_Internal,
};
pub const FT_Size = [*c]struct_FT_SizeRec_;
pub const struct_FT_Face_InternalRec_ = opaque {};
pub const FT_Face_Internal = ?*struct_FT_Face_InternalRec_;
pub const struct_FT_FaceRec_ = extern struct {
    num_faces: FT_Long,
    face_index: FT_Long,
    face_flags: FT_Long,
    style_flags: FT_Long,
    num_glyphs: FT_Long,
    family_name: [*c]FT_String,
    style_name: [*c]FT_String,
    num_fixed_sizes: FT_Int,
    available_sizes: [*c]FT_Bitmap_Size,
    num_charmaps: FT_Int,
    charmaps: [*c]FT_CharMap,
    generic: FT_Generic,
    bbox: FT_BBox,
    units_per_EM: FT_UShort,
    ascender: FT_Short,
    descender: FT_Short,
    height: FT_Short,
    max_advance_width: FT_Short,
    max_advance_height: FT_Short,
    underline_position: FT_Short,
    underline_thickness: FT_Short,
    glyph: FT_GlyphSlot,
    size: FT_Size,
    charmap: FT_CharMap,
    driver: FT_Driver,
    memory: FT_Memory,
    stream: FT_Stream,
    sizes_list: FT_ListRec,
    autohint: FT_Generic,
    extensions: ?*anyopaque,
    internal: FT_Face_Internal,
};
pub const FT_CharMapRec = struct_FT_CharMapRec_;
pub const FT_FaceRec = struct_FT_FaceRec_;
pub const FT_SizeRec = struct_FT_SizeRec_;
pub const FT_GlyphSlotRec = struct_FT_GlyphSlotRec_;
pub extern fn FT_Init_FreeType(alibrary: [*c]FT_Library) FT_Error;
pub extern fn FT_Done_FreeType(library: FT_Library) FT_Error;
pub const struct_FT_Parameter_ = extern struct {
    tag: FT_ULong,
    data: FT_Pointer,
};
pub const FT_Parameter = struct_FT_Parameter_;
pub const struct_FT_Open_Args_ = extern struct {
    flags: FT_UInt,
    memory_base: [*c]const FT_Byte,
    memory_size: FT_Long,
    pathname: [*c]FT_String,
    stream: FT_Stream,
    driver: FT_Module,
    num_params: FT_Int,
    params: [*c]FT_Parameter,
};
pub const FT_Open_Args = struct_FT_Open_Args_;
pub extern fn FT_New_Face(library: FT_Library, filepathname: [*c]const u8, face_index: FT_Long, aface: [*c]FT_Face) FT_Error;
pub extern fn FT_New_Memory_Face(library: FT_Library, file_base: [*c]const FT_Byte, file_size: FT_Long, face_index: FT_Long, aface: [*c]FT_Face) FT_Error;
pub extern fn FT_Open_Face(library: FT_Library, args: [*c]const FT_Open_Args, face_index: FT_Long, aface: [*c]FT_Face) FT_Error;
pub extern fn FT_Attach_File(face: FT_Face, filepathname: [*c]const u8) FT_Error;
pub extern fn FT_Attach_Stream(face: FT_Face, parameters: [*c]FT_Open_Args) FT_Error;
pub extern fn FT_Reference_Face(face: FT_Face) FT_Error;
pub extern fn FT_Done_Face(face: FT_Face) FT_Error;
pub extern fn FT_Select_Size(face: FT_Face, strike_index: FT_Int) FT_Error;
pub const FT_SIZE_REQUEST_TYPE_NOMINAL: c_int = 0;
pub const FT_SIZE_REQUEST_TYPE_REAL_DIM: c_int = 1;
pub const FT_SIZE_REQUEST_TYPE_BBOX: c_int = 2;
pub const FT_SIZE_REQUEST_TYPE_CELL: c_int = 3;
pub const FT_SIZE_REQUEST_TYPE_SCALES: c_int = 4;
pub const FT_SIZE_REQUEST_TYPE_MAX: c_int = 5;
pub const enum_FT_Size_Request_Type_ = c_uint;
pub const FT_Size_Request_Type = enum_FT_Size_Request_Type_;
pub const struct_FT_Size_RequestRec_ = extern struct {
    type: FT_Size_Request_Type,
    width: FT_Long,
    height: FT_Long,
    horiResolution: FT_UInt,
    vertResolution: FT_UInt,
};
pub const FT_Size_RequestRec = struct_FT_Size_RequestRec_;
pub const FT_Size_Request = [*c]struct_FT_Size_RequestRec_;
pub extern fn FT_Request_Size(face: FT_Face, req: FT_Size_Request) FT_Error;
pub extern fn FT_Set_Char_Size(face: FT_Face, char_width: FT_F26Dot6, char_height: FT_F26Dot6, horz_resolution: FT_UInt, vert_resolution: FT_UInt) FT_Error;
pub extern fn FT_Set_Pixel_Sizes(face: FT_Face, pixel_width: FT_UInt, pixel_height: FT_UInt) FT_Error;
pub extern fn FT_Load_Glyph(face: FT_Face, glyph_index: FT_UInt, load_flags: FT_Int32) FT_Error;
pub extern fn FT_Load_Char(face: FT_Face, char_code: FT_ULong, load_flags: FT_Int32) FT_Error;
pub extern fn FT_Set_Transform(face: FT_Face, matrix: [*c]FT_Matrix, delta: [*c]FT_Vector) void;
pub extern fn FT_Get_Transform(face: FT_Face, matrix: [*c]FT_Matrix, delta: [*c]FT_Vector) void;
pub const FT_RENDER_MODE_NORMAL: c_int = 0;
pub const FT_RENDER_MODE_LIGHT: c_int = 1;
pub const FT_RENDER_MODE_MONO: c_int = 2;
pub const FT_RENDER_MODE_LCD: c_int = 3;
pub const FT_RENDER_MODE_LCD_V: c_int = 4;
pub const FT_RENDER_MODE_SDF: c_int = 5;
pub const FT_RENDER_MODE_MAX: c_int = 6;
pub const enum_FT_Render_Mode_ = c_uint;
pub const FT_Render_Mode = enum_FT_Render_Mode_;
pub extern fn FT_Render_Glyph(slot: FT_GlyphSlot, render_mode: FT_Render_Mode) FT_Error;
pub const FT_KERNING_DEFAULT: c_int = 0;
pub const FT_KERNING_UNFITTED: c_int = 1;
pub const FT_KERNING_UNSCALED: c_int = 2;
pub const enum_FT_Kerning_Mode_ = c_uint;
pub const FT_Kerning_Mode = enum_FT_Kerning_Mode_;
pub extern fn FT_Get_Kerning(face: FT_Face, left_glyph: FT_UInt, right_glyph: FT_UInt, kern_mode: FT_UInt, akerning: [*c]FT_Vector) FT_Error;
pub extern fn FT_Get_Track_Kerning(face: FT_Face, point_size: FT_Fixed, degree: FT_Int, akerning: [*c]FT_Fixed) FT_Error;
pub extern fn FT_Get_Glyph_Name(face: FT_Face, glyph_index: FT_UInt, buffer: FT_Pointer, buffer_max: FT_UInt) FT_Error;
pub extern fn FT_Get_Postscript_Name(face: FT_Face) [*c]const u8;
pub extern fn FT_Select_Charmap(face: FT_Face, encoding: FT_Encoding) FT_Error;
pub extern fn FT_Set_Charmap(face: FT_Face, charmap: FT_CharMap) FT_Error;
pub extern fn FT_Get_Charmap_Index(charmap: FT_CharMap) FT_Int;
pub extern fn FT_Get_Char_Index(face: FT_Face, charcode: FT_ULong) FT_UInt;
pub extern fn FT_Get_First_Char(face: FT_Face, agindex: [*c]FT_UInt) FT_ULong;
pub extern fn FT_Get_Next_Char(face: FT_Face, char_code: FT_ULong, agindex: [*c]FT_UInt) FT_ULong;
pub extern fn FT_Face_Properties(face: FT_Face, num_properties: FT_UInt, properties: [*c]FT_Parameter) FT_Error;
pub extern fn FT_Get_Name_Index(face: FT_Face, glyph_name: [*c]const FT_String) FT_UInt;
pub extern fn FT_Get_SubGlyph_Info(glyph: FT_GlyphSlot, sub_index: FT_UInt, p_index: [*c]FT_Int, p_flags: [*c]FT_UInt, p_arg1: [*c]FT_Int, p_arg2: [*c]FT_Int, p_transform: [*c]FT_Matrix) FT_Error;
pub extern fn FT_Get_FSType_Flags(face: FT_Face) FT_UShort;
pub extern fn FT_Face_GetCharVariantIndex(face: FT_Face, charcode: FT_ULong, variantSelector: FT_ULong) FT_UInt;
pub extern fn FT_Face_GetCharVariantIsDefault(face: FT_Face, charcode: FT_ULong, variantSelector: FT_ULong) FT_Int;
pub extern fn FT_Face_GetVariantSelectors(face: FT_Face) [*c]FT_UInt32;
pub extern fn FT_Face_GetVariantsOfChar(face: FT_Face, charcode: FT_ULong) [*c]FT_UInt32;
pub extern fn FT_Face_GetCharsOfVariant(face: FT_Face, variantSelector: FT_ULong) [*c]FT_UInt32;
pub extern fn FT_MulDiv(a: FT_Long, b: FT_Long, c: FT_Long) FT_Long;
pub extern fn FT_MulFix(a: FT_Long, b: FT_Long) FT_Long;
pub extern fn FT_DivFix(a: FT_Long, b: FT_Long) FT_Long;
pub extern fn FT_RoundFix(a: FT_Fixed) FT_Fixed;
pub extern fn FT_CeilFix(a: FT_Fixed) FT_Fixed;
pub extern fn FT_FloorFix(a: FT_Fixed) FT_Fixed;
pub extern fn FT_Vector_Transform(vector: [*c]FT_Vector, matrix: [*c]const FT_Matrix) void;
pub extern fn FT_Library_Version(library: FT_Library, amajor: [*c]FT_Int, aminor: [*c]FT_Int, apatch: [*c]FT_Int) void;
pub extern fn FT_Face_CheckTrueTypePatents(face: FT_Face) FT_Bool;
pub extern fn FT_Face_SetUnpatentedHinting(face: FT_Face, value: FT_Bool) FT_Bool;
pub extern fn hb_ft_face_create(ft_face: FT_Face, destroy: hb_destroy_func_t) ?*hb_face_t;
pub extern fn hb_ft_face_create_cached(ft_face: FT_Face) ?*hb_face_t;
pub extern fn hb_ft_face_create_referenced(ft_face: FT_Face) ?*hb_face_t;
pub extern fn hb_ft_font_create(ft_face: FT_Face, destroy: hb_destroy_func_t) ?*hb_font_t;
pub extern fn hb_ft_font_create_referenced(ft_face: FT_Face) ?*hb_font_t;
pub extern fn hb_ft_font_get_face(font: ?*hb_font_t) FT_Face;
pub extern fn hb_ft_font_lock_face(font: ?*hb_font_t) FT_Face;
pub extern fn hb_ft_font_unlock_face(font: ?*hb_font_t) void;
pub extern fn hb_ft_font_set_load_flags(font: ?*hb_font_t, load_flags: c_int) void;
pub extern fn hb_ft_font_get_load_flags(font: ?*hb_font_t) c_int;
pub extern fn hb_ft_font_changed(font: ?*hb_font_t) void;
pub extern fn hb_ft_font_set_funcs(font: ?*hb_font_t) void;
pub extern fn FT_Get_Advance(face: FT_Face, gindex: FT_UInt, load_flags: FT_Int32, padvance: [*c]FT_Fixed) FT_Error;
pub extern fn FT_Get_Advances(face: FT_Face, start: FT_UInt, count: FT_UInt, load_flags: FT_Int32, padvances: [*c]FT_Fixed) FT_Error;
pub extern fn FT_Outline_Get_BBox(outline: [*c]FT_Outline, abbox: [*c]FT_BBox) FT_Error;
pub const struct_FT_Color_ = extern struct {
    blue: FT_Byte,
    green: FT_Byte,
    red: FT_Byte,
    alpha: FT_Byte,
};
pub const FT_Color = struct_FT_Color_;
pub const struct_FT_Palette_Data_ = extern struct {
    num_palettes: FT_UShort,
    palette_name_ids: [*c]const FT_UShort,
    palette_flags: [*c]const FT_UShort,
    num_palette_entries: FT_UShort,
    palette_entry_name_ids: [*c]const FT_UShort,
};
pub const FT_Palette_Data = struct_FT_Palette_Data_;
pub extern fn FT_Palette_Data_Get(face: FT_Face, apalette: [*c]FT_Palette_Data) FT_Error;
pub extern fn FT_Palette_Select(face: FT_Face, palette_index: FT_UShort, apalette: [*c][*c]FT_Color) FT_Error;
pub extern fn FT_Palette_Set_Foreground_Color(face: FT_Face, foreground_color: FT_Color) FT_Error;
pub const struct_FT_LayerIterator_ = extern struct {
    num_layers: FT_UInt,
    layer: FT_UInt,
    p: [*c]FT_Byte,
};
pub const FT_LayerIterator = struct_FT_LayerIterator_;
pub extern fn FT_Get_Color_Glyph_Layer(face: FT_Face, base_glyph: FT_UInt, aglyph_index: [*c]FT_UInt, acolor_index: [*c]FT_UInt, iterator: [*c]FT_LayerIterator) FT_Bool;
pub const FT_COLR_PAINTFORMAT_COLR_LAYERS: c_int = 1;
pub const FT_COLR_PAINTFORMAT_SOLID: c_int = 2;
pub const FT_COLR_PAINTFORMAT_LINEAR_GRADIENT: c_int = 4;
pub const FT_COLR_PAINTFORMAT_RADIAL_GRADIENT: c_int = 6;
pub const FT_COLR_PAINTFORMAT_SWEEP_GRADIENT: c_int = 8;
pub const FT_COLR_PAINTFORMAT_GLYPH: c_int = 10;
pub const FT_COLR_PAINTFORMAT_COLR_GLYPH: c_int = 11;
pub const FT_COLR_PAINTFORMAT_TRANSFORM: c_int = 12;
pub const FT_COLR_PAINTFORMAT_TRANSLATE: c_int = 14;
pub const FT_COLR_PAINTFORMAT_SCALE: c_int = 16;
pub const FT_COLR_PAINTFORMAT_ROTATE: c_int = 24;
pub const FT_COLR_PAINTFORMAT_SKEW: c_int = 28;
pub const FT_COLR_PAINTFORMAT_COMPOSITE: c_int = 32;
pub const FT_COLR_PAINT_FORMAT_MAX: c_int = 33;
pub const FT_COLR_PAINTFORMAT_UNSUPPORTED: c_int = 255;
pub const enum_FT_PaintFormat_ = c_uint;
pub const FT_PaintFormat = enum_FT_PaintFormat_;
pub const struct_FT_ColorStopIterator_ = extern struct {
    num_color_stops: FT_UInt,
    current_color_stop: FT_UInt,
    p: [*c]FT_Byte,
};
pub const FT_ColorStopIterator = struct_FT_ColorStopIterator_;
pub const struct_FT_ColorIndex_ = extern struct {
    palette_index: FT_UInt16,
    alpha: FT_F2Dot14,
};
pub const FT_ColorIndex = struct_FT_ColorIndex_;
pub const struct_FT_ColorStop_ = extern struct {
    stop_offset: FT_F2Dot14,
    color: FT_ColorIndex,
};
pub const FT_ColorStop = struct_FT_ColorStop_;
pub const FT_COLR_PAINT_EXTEND_PAD: c_int = 0;
pub const FT_COLR_PAINT_EXTEND_REPEAT: c_int = 1;
pub const FT_COLR_PAINT_EXTEND_REFLECT: c_int = 2;
pub const enum_FT_PaintExtend_ = c_uint;
pub const FT_PaintExtend = enum_FT_PaintExtend_;
pub const struct_FT_ColorLine_ = extern struct {
    extend: FT_PaintExtend,
    color_stop_iterator: FT_ColorStopIterator,
};
pub const FT_ColorLine = struct_FT_ColorLine_;
pub const struct_FT_Affine_23_ = extern struct {
    xx: FT_Fixed,
    xy: FT_Fixed,
    dx: FT_Fixed,
    yx: FT_Fixed,
    yy: FT_Fixed,
    dy: FT_Fixed,
};
pub const FT_Affine23 = struct_FT_Affine_23_;
pub const FT_COLR_COMPOSITE_CLEAR: c_int = 0;
pub const FT_COLR_COMPOSITE_SRC: c_int = 1;
pub const FT_COLR_COMPOSITE_DEST: c_int = 2;
pub const FT_COLR_COMPOSITE_SRC_OVER: c_int = 3;
pub const FT_COLR_COMPOSITE_DEST_OVER: c_int = 4;
pub const FT_COLR_COMPOSITE_SRC_IN: c_int = 5;
pub const FT_COLR_COMPOSITE_DEST_IN: c_int = 6;
pub const FT_COLR_COMPOSITE_SRC_OUT: c_int = 7;
pub const FT_COLR_COMPOSITE_DEST_OUT: c_int = 8;
pub const FT_COLR_COMPOSITE_SRC_ATOP: c_int = 9;
pub const FT_COLR_COMPOSITE_DEST_ATOP: c_int = 10;
pub const FT_COLR_COMPOSITE_XOR: c_int = 11;
pub const FT_COLR_COMPOSITE_PLUS: c_int = 12;
pub const FT_COLR_COMPOSITE_SCREEN: c_int = 13;
pub const FT_COLR_COMPOSITE_OVERLAY: c_int = 14;
pub const FT_COLR_COMPOSITE_DARKEN: c_int = 15;
pub const FT_COLR_COMPOSITE_LIGHTEN: c_int = 16;
pub const FT_COLR_COMPOSITE_COLOR_DODGE: c_int = 17;
pub const FT_COLR_COMPOSITE_COLOR_BURN: c_int = 18;
pub const FT_COLR_COMPOSITE_HARD_LIGHT: c_int = 19;
pub const FT_COLR_COMPOSITE_SOFT_LIGHT: c_int = 20;
pub const FT_COLR_COMPOSITE_DIFFERENCE: c_int = 21;
pub const FT_COLR_COMPOSITE_EXCLUSION: c_int = 22;
pub const FT_COLR_COMPOSITE_MULTIPLY: c_int = 23;
pub const FT_COLR_COMPOSITE_HSL_HUE: c_int = 24;
pub const FT_COLR_COMPOSITE_HSL_SATURATION: c_int = 25;
pub const FT_COLR_COMPOSITE_HSL_COLOR: c_int = 26;
pub const FT_COLR_COMPOSITE_HSL_LUMINOSITY: c_int = 27;
pub const FT_COLR_COMPOSITE_MAX: c_int = 28;
pub const enum_FT_Composite_Mode_ = c_uint;
pub const FT_Composite_Mode = enum_FT_Composite_Mode_;
pub const struct_FT_Opaque_Paint_ = extern struct {
    p: [*c]FT_Byte,
    insert_root_transform: FT_Bool,
};
pub const FT_OpaquePaint = struct_FT_Opaque_Paint_;
pub const struct_FT_PaintColrLayers_ = extern struct {
    layer_iterator: FT_LayerIterator,
};
pub const FT_PaintColrLayers = struct_FT_PaintColrLayers_;
pub const struct_FT_PaintSolid_ = extern struct {
    color: FT_ColorIndex,
};
pub const FT_PaintSolid = struct_FT_PaintSolid_;
pub const struct_FT_PaintLinearGradient_ = extern struct {
    colorline: FT_ColorLine,
    p0: FT_Vector,
    p1: FT_Vector,
    p2: FT_Vector,
};
pub const FT_PaintLinearGradient = struct_FT_PaintLinearGradient_;
pub const struct_FT_PaintRadialGradient_ = extern struct {
    colorline: FT_ColorLine,
    c0: FT_Vector,
    r0: FT_Pos,
    c1: FT_Vector,
    r1: FT_Pos,
};
pub const FT_PaintRadialGradient = struct_FT_PaintRadialGradient_;
pub const struct_FT_PaintSweepGradient_ = extern struct {
    colorline: FT_ColorLine,
    center: FT_Vector,
    start_angle: FT_Fixed,
    end_angle: FT_Fixed,
};
pub const FT_PaintSweepGradient = struct_FT_PaintSweepGradient_;
pub const struct_FT_PaintGlyph_ = extern struct {
    paint: FT_OpaquePaint,
    glyphID: FT_UInt,
};
pub const FT_PaintGlyph = struct_FT_PaintGlyph_;
pub const struct_FT_PaintColrGlyph_ = extern struct {
    glyphID: FT_UInt,
};
pub const FT_PaintColrGlyph = struct_FT_PaintColrGlyph_;
pub const struct_FT_PaintTransform_ = extern struct {
    paint: FT_OpaquePaint,
    affine: FT_Affine23,
};
pub const FT_PaintTransform = struct_FT_PaintTransform_;
pub const struct_FT_PaintTranslate_ = extern struct {
    paint: FT_OpaquePaint,
    dx: FT_Fixed,
    dy: FT_Fixed,
};
pub const FT_PaintTranslate = struct_FT_PaintTranslate_;
pub const struct_FT_PaintScale_ = extern struct {
    paint: FT_OpaquePaint,
    scale_x: FT_Fixed,
    scale_y: FT_Fixed,
    center_x: FT_Fixed,
    center_y: FT_Fixed,
};
pub const FT_PaintScale = struct_FT_PaintScale_;
pub const struct_FT_PaintRotate_ = extern struct {
    paint: FT_OpaquePaint,
    angle: FT_Fixed,
    center_x: FT_Fixed,
    center_y: FT_Fixed,
};
pub const FT_PaintRotate = struct_FT_PaintRotate_;
pub const struct_FT_PaintSkew_ = extern struct {
    paint: FT_OpaquePaint,
    x_skew_angle: FT_Fixed,
    y_skew_angle: FT_Fixed,
    center_x: FT_Fixed,
    center_y: FT_Fixed,
};
pub const FT_PaintSkew = struct_FT_PaintSkew_;
pub const struct_FT_PaintComposite_ = extern struct {
    source_paint: FT_OpaquePaint,
    composite_mode: FT_Composite_Mode,
    backdrop_paint: FT_OpaquePaint,
};
pub const FT_PaintComposite = struct_FT_PaintComposite_;
const union_unnamed_5 = extern union {
    colr_layers: FT_PaintColrLayers,
    glyph: FT_PaintGlyph,
    solid: FT_PaintSolid,
    linear_gradient: FT_PaintLinearGradient,
    radial_gradient: FT_PaintRadialGradient,
    sweep_gradient: FT_PaintSweepGradient,
    transform: FT_PaintTransform,
    translate: FT_PaintTranslate,
    scale: FT_PaintScale,
    rotate: FT_PaintRotate,
    skew: FT_PaintSkew,
    composite: FT_PaintComposite,
    colr_glyph: FT_PaintColrGlyph,
};
pub const struct_FT_COLR_Paint_ = extern struct {
    format: FT_PaintFormat,
    u: union_unnamed_5,
};
pub const FT_COLR_Paint = struct_FT_COLR_Paint_;
pub const FT_COLOR_INCLUDE_ROOT_TRANSFORM: c_int = 0;
pub const FT_COLOR_NO_ROOT_TRANSFORM: c_int = 1;
pub const FT_COLOR_ROOT_TRANSFORM_MAX: c_int = 2;
pub const enum_FT_Color_Root_Transform_ = c_uint;
pub const FT_Color_Root_Transform = enum_FT_Color_Root_Transform_;
pub const struct_FT_ClipBox_ = extern struct {
    bottom_left: FT_Vector,
    top_left: FT_Vector,
    top_right: FT_Vector,
    bottom_right: FT_Vector,
};
pub const FT_ClipBox = struct_FT_ClipBox_;
pub extern fn FT_Get_Color_Glyph_Paint(face: FT_Face, base_glyph: FT_UInt, root_transform: FT_Color_Root_Transform, paint: [*c]FT_OpaquePaint) FT_Bool;
pub extern fn FT_Get_Color_Glyph_ClipBox(face: FT_Face, base_glyph: FT_UInt, clip_box: [*c]FT_ClipBox) FT_Bool;
pub extern fn FT_Get_Paint_Layers(face: FT_Face, iterator: [*c]FT_LayerIterator, paint: [*c]FT_OpaquePaint) FT_Bool;
pub extern fn FT_Get_Colorline_Stops(face: FT_Face, color_stop: [*c]FT_ColorStop, iterator: [*c]FT_ColorStopIterator) FT_Bool;
pub extern fn FT_Get_Paint(face: FT_Face, opaque_paint: FT_OpaquePaint, paint: [*c]FT_COLR_Paint) FT_Bool;
pub extern fn FT_Bitmap_Init(abitmap: [*c]FT_Bitmap) void;
pub extern fn FT_Bitmap_New(abitmap: [*c]FT_Bitmap) void;
pub extern fn FT_Bitmap_Copy(library: FT_Library, source: [*c]const FT_Bitmap, target: [*c]FT_Bitmap) FT_Error;
pub extern fn FT_Bitmap_Embolden(library: FT_Library, bitmap: [*c]FT_Bitmap, xStrength: FT_Pos, yStrength: FT_Pos) FT_Error;
pub extern fn FT_Bitmap_Convert(library: FT_Library, source: [*c]const FT_Bitmap, target: [*c]FT_Bitmap, alignment: FT_Int) FT_Error;
pub extern fn FT_Bitmap_Blend(library: FT_Library, source: [*c]const FT_Bitmap, source_offset: FT_Vector, target: [*c]FT_Bitmap, atarget_offset: [*c]FT_Vector, color: FT_Color) FT_Error;
pub extern fn FT_GlyphSlot_Own_Bitmap(slot: FT_GlyphSlot) FT_Error;
pub extern fn FT_Bitmap_Done(library: FT_Library, bitmap: [*c]FT_Bitmap) FT_Error;
pub const FT_LCD_FILTER_NONE: c_int = 0;
pub const FT_LCD_FILTER_DEFAULT: c_int = 1;
pub const FT_LCD_FILTER_LIGHT: c_int = 2;
pub const FT_LCD_FILTER_LEGACY1: c_int = 3;
pub const FT_LCD_FILTER_LEGACY: c_int = 16;
pub const FT_LCD_FILTER_MAX: c_int = 17;
pub const enum_FT_LcdFilter_ = c_uint;
pub const FT_LcdFilter = enum_FT_LcdFilter_;
pub extern fn FT_Library_SetLcdFilter(library: FT_Library, filter: FT_LcdFilter) FT_Error;
pub extern fn FT_Library_SetLcdFilterWeights(library: FT_Library, weights: [*c]u8) FT_Error;
pub const FT_LcdFiveTapFilter = [5]FT_Byte;
pub extern fn FT_Library_SetLcdGeometry(library: FT_Library, sub: [*c]FT_Vector) FT_Error;
pub extern fn FT_New_Size(face: FT_Face, size: [*c]FT_Size) FT_Error;
pub extern fn FT_Done_Size(size: FT_Size) FT_Error;
pub extern fn FT_Activate_Size(size: FT_Size) FT_Error;
pub extern fn FT_Outline_Decompose(outline: [*c]FT_Outline, func_interface: [*c]const FT_Outline_Funcs, user: ?*anyopaque) FT_Error;
pub extern fn FT_Outline_New(library: FT_Library, numPoints: FT_UInt, numContours: FT_Int, anoutline: [*c]FT_Outline) FT_Error;
pub extern fn FT_Outline_Done(library: FT_Library, outline: [*c]FT_Outline) FT_Error;
pub extern fn FT_Outline_Check(outline: [*c]FT_Outline) FT_Error;
pub extern fn FT_Outline_Get_CBox(outline: [*c]const FT_Outline, acbox: [*c]FT_BBox) void;
pub extern fn FT_Outline_Translate(outline: [*c]const FT_Outline, xOffset: FT_Pos, yOffset: FT_Pos) void;
pub extern fn FT_Outline_Copy(source: [*c]const FT_Outline, target: [*c]FT_Outline) FT_Error;
pub extern fn FT_Outline_Transform(outline: [*c]const FT_Outline, matrix: [*c]const FT_Matrix) void;
pub extern fn FT_Outline_Embolden(outline: [*c]FT_Outline, strength: FT_Pos) FT_Error;
pub extern fn FT_Outline_EmboldenXY(outline: [*c]FT_Outline, xstrength: FT_Pos, ystrength: FT_Pos) FT_Error;
pub extern fn FT_Outline_Reverse(outline: [*c]FT_Outline) void;
pub extern fn FT_Outline_Get_Bitmap(library: FT_Library, outline: [*c]FT_Outline, abitmap: [*c]const FT_Bitmap) FT_Error;
pub extern fn FT_Outline_Render(library: FT_Library, outline: [*c]FT_Outline, params: [*c]FT_Raster_Params) FT_Error;
pub const FT_ORIENTATION_TRUETYPE: c_int = 0;
pub const FT_ORIENTATION_POSTSCRIPT: c_int = 1;
pub const FT_ORIENTATION_FILL_RIGHT: c_int = 0;
pub const FT_ORIENTATION_FILL_LEFT: c_int = 1;
pub const FT_ORIENTATION_NONE: c_int = 2;
pub const enum_FT_Orientation_ = c_uint;
pub const FT_Orientation = enum_FT_Orientation_;
pub extern fn FT_Outline_Get_Orientation(outline: [*c]FT_Outline) FT_Orientation;
pub const struct_FT_Glyph_Class_ = opaque {};
pub const FT_Glyph_Class = struct_FT_Glyph_Class_;
pub const struct_FT_GlyphRec_ = extern struct {
    library: FT_Library,
    clazz: ?*const FT_Glyph_Class,
    format: FT_Glyph_Format,
    advance: FT_Vector,
};
pub const FT_Glyph = [*c]struct_FT_GlyphRec_;
pub const FT_GlyphRec = struct_FT_GlyphRec_;
pub const struct_FT_BitmapGlyphRec_ = extern struct {
    root: FT_GlyphRec,
    left: FT_Int,
    top: FT_Int,
    bitmap: FT_Bitmap,
};
pub const FT_BitmapGlyph = [*c]struct_FT_BitmapGlyphRec_;
pub const FT_BitmapGlyphRec = struct_FT_BitmapGlyphRec_;
pub const struct_FT_OutlineGlyphRec_ = extern struct {
    root: FT_GlyphRec,
    outline: FT_Outline,
};
pub const FT_OutlineGlyph = [*c]struct_FT_OutlineGlyphRec_;
pub const FT_OutlineGlyphRec = struct_FT_OutlineGlyphRec_;
pub const struct_FT_SvgGlyphRec_ = extern struct {
    root: FT_GlyphRec,
    svg_document: [*c]FT_Byte,
    svg_document_length: FT_ULong,
    glyph_index: FT_UInt,
    metrics: FT_Size_Metrics,
    units_per_EM: FT_UShort,
    start_glyph_id: FT_UShort,
    end_glyph_id: FT_UShort,
    transform: FT_Matrix,
    delta: FT_Vector,
};
pub const FT_SvgGlyph = [*c]struct_FT_SvgGlyphRec_;
pub const FT_SvgGlyphRec = struct_FT_SvgGlyphRec_;
pub extern fn FT_New_Glyph(library: FT_Library, format: FT_Glyph_Format, aglyph: [*c]FT_Glyph) FT_Error;
pub extern fn FT_Get_Glyph(slot: FT_GlyphSlot, aglyph: [*c]FT_Glyph) FT_Error;
pub extern fn FT_Glyph_Copy(source: FT_Glyph, target: [*c]FT_Glyph) FT_Error;
pub extern fn FT_Glyph_Transform(glyph: FT_Glyph, matrix: [*c]const FT_Matrix, delta: [*c]const FT_Vector) FT_Error;
pub const FT_GLYPH_BBOX_UNSCALED: c_int = 0;
pub const FT_GLYPH_BBOX_SUBPIXELS: c_int = 0;
pub const FT_GLYPH_BBOX_GRIDFIT: c_int = 1;
pub const FT_GLYPH_BBOX_TRUNCATE: c_int = 2;
pub const FT_GLYPH_BBOX_PIXELS: c_int = 3;
pub const enum_FT_Glyph_BBox_Mode_ = c_uint;
pub const FT_Glyph_BBox_Mode = enum_FT_Glyph_BBox_Mode_;
pub extern fn FT_Glyph_Get_CBox(glyph: FT_Glyph, bbox_mode: FT_UInt, acbox: [*c]FT_BBox) void;
pub extern fn FT_Glyph_To_Bitmap(the_glyph: [*c]FT_Glyph, render_mode: FT_Render_Mode, origin: [*c]const FT_Vector, destroy: FT_Bool) FT_Error;
pub extern fn FT_Done_Glyph(glyph: FT_Glyph) void;
pub extern fn FT_Matrix_Multiply(a: [*c]const FT_Matrix, b: [*c]FT_Matrix) void;
pub extern fn FT_Matrix_Invert(matrix: [*c]FT_Matrix) FT_Error;
pub const struct_FT_StrokerRec_ = opaque {};
pub const FT_Stroker = ?*struct_FT_StrokerRec_;
pub const FT_STROKER_LINEJOIN_ROUND: c_int = 0;
pub const FT_STROKER_LINEJOIN_BEVEL: c_int = 1;
pub const FT_STROKER_LINEJOIN_MITER_VARIABLE: c_int = 2;
pub const FT_STROKER_LINEJOIN_MITER: c_int = 2;
pub const FT_STROKER_LINEJOIN_MITER_FIXED: c_int = 3;
pub const enum_FT_Stroker_LineJoin_ = c_uint;
pub const FT_Stroker_LineJoin = enum_FT_Stroker_LineJoin_;
pub const FT_STROKER_LINECAP_BUTT: c_int = 0;
pub const FT_STROKER_LINECAP_ROUND: c_int = 1;
pub const FT_STROKER_LINECAP_SQUARE: c_int = 2;
pub const enum_FT_Stroker_LineCap_ = c_uint;
pub const FT_Stroker_LineCap = enum_FT_Stroker_LineCap_;
pub const FT_STROKER_BORDER_LEFT: c_int = 0;
pub const FT_STROKER_BORDER_RIGHT: c_int = 1;
pub const enum_FT_StrokerBorder_ = c_uint;
pub const FT_StrokerBorder = enum_FT_StrokerBorder_;
pub extern fn FT_Outline_GetInsideBorder(outline: [*c]FT_Outline) FT_StrokerBorder;
pub extern fn FT_Outline_GetOutsideBorder(outline: [*c]FT_Outline) FT_StrokerBorder;
pub extern fn FT_Stroker_New(library: FT_Library, astroker: [*c]FT_Stroker) FT_Error;
pub extern fn FT_Stroker_Set(stroker: FT_Stroker, radius: FT_Fixed, line_cap: FT_Stroker_LineCap, line_join: FT_Stroker_LineJoin, miter_limit: FT_Fixed) void;
pub extern fn FT_Stroker_Rewind(stroker: FT_Stroker) void;
pub extern fn FT_Stroker_ParseOutline(stroker: FT_Stroker, outline: [*c]FT_Outline, opened: FT_Bool) FT_Error;
pub extern fn FT_Stroker_BeginSubPath(stroker: FT_Stroker, to: [*c]FT_Vector, open: FT_Bool) FT_Error;
pub extern fn FT_Stroker_EndSubPath(stroker: FT_Stroker) FT_Error;
pub extern fn FT_Stroker_LineTo(stroker: FT_Stroker, to: [*c]FT_Vector) FT_Error;
pub extern fn FT_Stroker_ConicTo(stroker: FT_Stroker, control: [*c]FT_Vector, to: [*c]FT_Vector) FT_Error;
pub extern fn FT_Stroker_CubicTo(stroker: FT_Stroker, control1: [*c]FT_Vector, control2: [*c]FT_Vector, to: [*c]FT_Vector) FT_Error;
pub extern fn FT_Stroker_GetBorderCounts(stroker: FT_Stroker, border: FT_StrokerBorder, anum_points: [*c]FT_UInt, anum_contours: [*c]FT_UInt) FT_Error;
pub extern fn FT_Stroker_ExportBorder(stroker: FT_Stroker, border: FT_StrokerBorder, outline: [*c]FT_Outline) void;
pub extern fn FT_Stroker_GetCounts(stroker: FT_Stroker, anum_points: [*c]FT_UInt, anum_contours: [*c]FT_UInt) FT_Error;
pub extern fn FT_Stroker_Export(stroker: FT_Stroker, outline: [*c]FT_Outline) void;
pub extern fn FT_Stroker_Done(stroker: FT_Stroker) void;
pub extern fn FT_Glyph_Stroke(pglyph: [*c]FT_Glyph, stroker: FT_Stroker, destroy: FT_Bool) FT_Error;
pub extern fn FT_Glyph_StrokeBorder(pglyph: [*c]FT_Glyph, stroker: FT_Stroker, inside: FT_Bool, destroy: FT_Bool) FT_Error;
pub const FT_Angle = FT_Fixed;
pub extern fn FT_Sin(angle: FT_Angle) FT_Fixed;
pub extern fn FT_Cos(angle: FT_Angle) FT_Fixed;
pub extern fn FT_Tan(angle: FT_Angle) FT_Fixed;
pub extern fn FT_Atan2(x: FT_Fixed, y: FT_Fixed) FT_Angle;
pub extern fn FT_Angle_Diff(angle1: FT_Angle, angle2: FT_Angle) FT_Angle;
pub extern fn FT_Vector_Unit(vec: [*c]FT_Vector, angle: FT_Angle) void;
pub extern fn FT_Vector_Rotate(vec: [*c]FT_Vector, angle: FT_Angle) void;
pub extern fn FT_Vector_Length(vec: [*c]FT_Vector) FT_Fixed;
pub extern fn FT_Vector_Polarize(vec: [*c]FT_Vector, length: [*c]FT_Fixed, angle: [*c]FT_Angle) void;
pub extern fn FT_Vector_From_Polar(vec: [*c]FT_Vector, length: FT_Fixed, angle: FT_Angle) void;
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
pub const HB_EXTERN = @compileError("unable to translate C expr: unexpected token 'extern'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/harfbuzz/src/hb-common.h:37:9
pub const __CONCAT = @compileError("unable to translate C expr: unexpected token '##'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:113:9
pub const __STRING = @compileError("unable to translate C expr: unexpected token '#'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:114:9
pub const __const = @compileError("unable to translate C expr: unexpected token 'const'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:116:9
pub const __volatile = @compileError("unable to translate C expr: unexpected token 'volatile'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:118:9
pub const __dead2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:162:9
pub const __pure2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:163:9
pub const __stateful_pure = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:164:9
pub const __unused = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:169:9
pub const __used = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:174:9
pub const __cold = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:180:9
pub const __exported = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:190:9
pub const __exported_push = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:191:9
pub const __exported_pop = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:192:9
pub const __deprecated = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:204:9
pub const __deprecated_msg = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:208:10
pub const __kpi_deprecated = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:219:9
pub const __unavailable = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:225:9
pub const __restrict = @compileError("unable to translate C expr: unexpected token 'restrict'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:247:9
pub const __disable_tail_calls = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:280:9
pub const __not_tail_called = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:292:9
pub const __result_use_check = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:303:9
pub const __swift_unavailable = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:313:9
pub const __header_inline = @compileError("unable to translate C expr: unexpected token 'inline'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:347:10
pub const __header_always_inline = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:360:10
pub const __unreachable_ok_push = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:373:10
pub const __unreachable_ok_pop = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:376:10
pub const __printflike = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:397:9
pub const __printf0like = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:399:9
pub const __scanflike = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:401:9
pub const __osloglike = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:403:9
pub const __IDSTRING = @compileError("unable to translate C expr: unexpected token 'static'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:406:9
pub const __COPYRIGHT = @compileError("unable to translate macro: undefined identifier `copyright`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:409:9
pub const __RCSID = @compileError("unable to translate macro: undefined identifier `rcsid`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:413:9
pub const __SCCSID = @compileError("unable to translate macro: undefined identifier `sccsid`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:417:9
pub const __PROJECT_VERSION = @compileError("unable to translate macro: undefined identifier `project_version`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:421:9
pub const __FBSDID = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:426:9
pub const __DECONST = @compileError("unable to translate C expr: unexpected token 'const'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:430:9
pub const __DEVOLATILE = @compileError("unable to translate C expr: unexpected token 'volatile'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:434:9
pub const __DEQUALIFY = @compileError("unable to translate C expr: unexpected token 'const'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:438:9
pub const __alloc_size = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:456:9
pub const __DARWIN_ALIAS = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:641:9
pub const __DARWIN_ALIAS_C = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:642:9
pub const __DARWIN_ALIAS_I = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:643:9
pub const __DARWIN_NOCANCEL = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:644:9
pub const __DARWIN_INODE64 = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:645:9
pub const __DARWIN_1050 = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:647:9
pub const __DARWIN_1050ALIAS = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:648:9
pub const __DARWIN_1050ALIAS_C = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:649:9
pub const __DARWIN_1050ALIAS_I = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:650:9
pub const __DARWIN_1050INODE64 = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:651:9
pub const __DARWIN_EXTSN = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:653:9
pub const __DARWIN_EXTSN_C = @compileError("unable to translate macro: undefined identifier `__asm`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:654:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:35:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:41:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_2_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:47:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:53:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:59:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_3_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:65:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:71:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:77:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:83:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_4_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:89:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_5_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:95:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_5_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:101:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_6_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:107:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_6_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:113:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_7_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:119:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_7_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:125:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:131:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:137:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:143:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:149:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_8_4 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:155:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:161:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:167:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:173:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_9_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:179:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:185:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:191:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:197:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_10_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:203:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:209:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:215:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:221:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:227:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_11_4 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:233:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:239:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:245:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:251:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:257:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_12_4 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:263:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:269:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:275:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:281:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:287:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_4 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:293:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_5 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:299:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_6 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:305:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_13_7 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:311:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:317:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:323:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:329:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:335:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_14_5 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:341:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_0 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:347:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_1 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:353:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:359:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:365:9
pub const __DARWIN_ALIAS_STARTING_IPHONE___IPHONE_15_4 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:371:9
pub const __DARWIN_ALIAS_STARTING_MAC___MAC_12_2 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:605:9
pub const __DARWIN_ALIAS_STARTING_MAC___MAC_12_3 = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/_symbol_aliasing.h:611:9
pub const __DARWIN_ALIAS_STARTING = @compileError("unable to translate macro: undefined identifier `__DARWIN_ALIAS_STARTING_MAC_`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:664:9
pub const __POSIX_C_DEPRECATED = @compileError("unable to translate macro: undefined identifier `___POSIX_C_DEPRECATED_STARTING_`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:727:9
pub const __XNU_PRIVATE_EXTERN = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:827:9
pub const __counted_by = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:841:9
pub const __sized_by = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:842:9
pub const __ended_by = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:843:9
pub const __ptrcheck_abi_assume_single = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:852:9
pub const __ptrcheck_abi_assume_unsafe_indexable = @compileError("unable to translate C expr: unexpected token 'Eof'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:853:9
pub const __compiler_barrier = @compileError("unable to translate macro: undefined identifier `__asm__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:887:9
pub const __enum_open = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:890:9
pub const __enum_closed = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:891:9
pub const __enum_options = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:898:9
pub const __enum_decl = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:911:9
pub const __enum_closed_decl = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:913:9
pub const __options_decl = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:915:9
pub const __options_closed_decl = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/sys/cdefs.h:917:9
pub const __offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/_types.h:83:9
pub const HB_DEPRECATED = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/harfbuzz/src/hb-common.h:73:9
pub const HB_DRAW_STATE_DEFAULT = @compileError("unable to translate C expr: unexpected token '{'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/harfbuzz/src/hb-draw.h:73:9
pub const HB_SEGMENT_PROPERTIES_DEFAULT = @compileError("unable to translate C expr: unexpected token '{'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/harfbuzz/src/hb-buffer.h:215:9
pub const FT_CONFIG_CONFIG_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:117:9
pub const FT_CONFIG_STANDARD_LIBRARY_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:132:9
pub const FT_CONFIG_OPTIONS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:147:9
pub const FT_CONFIG_MODULES_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:163:9
pub const FT_FREETYPE_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:180:9
pub const FT_ERRORS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:195:9
pub const FT_MODULE_ERRORS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:208:9
pub const FT_SYSTEM_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:224:9
pub const FT_IMAGE_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:240:9
pub const FT_TYPES_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:255:9
pub const FT_LIST_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:270:9
pub const FT_OUTLINE_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:283:9
pub const FT_SIZES_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:296:9
pub const FT_MODULE_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:309:9
pub const FT_RENDER_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:322:9
pub const FT_DRIVER_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:335:9
pub const FT_TYPE1_TABLES_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:408:9
pub const FT_TRUETYPE_IDS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:423:9
pub const FT_TRUETYPE_TABLES_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:436:9
pub const FT_TRUETYPE_TAGS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:450:9
pub const FT_BDF_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:463:9
pub const FT_CID_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:476:9
pub const FT_GZIP_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:489:9
pub const FT_LZW_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:502:9
pub const FT_BZIP2_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:515:9
pub const FT_WINFONTS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:528:9
pub const FT_GLYPH_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:541:9
pub const FT_BITMAP_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:554:9
pub const FT_BBOX_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:567:9
pub const FT_CACHE_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:580:9
pub const FT_MAC_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:597:9
pub const FT_MULTIPLE_MASTERS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:610:9
pub const FT_SFNT_NAMES_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:624:9
pub const FT_OPENTYPE_VALIDATE_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:638:9
pub const FT_GX_VALIDATE_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:652:9
pub const FT_PFR_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:665:9
pub const FT_STROKER_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:677:9
pub const FT_SYNTHESIS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:689:9
pub const FT_FONT_FORMATS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:701:9
pub const FT_TRIGONOMETRY_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:717:9
pub const FT_LCD_FILTER_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:729:9
pub const FT_INCREMENTAL_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:741:9
pub const FT_GASP_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:753:9
pub const FT_ADVANCES_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:765:9
pub const FT_COLOR_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:777:9
pub const FT_OTSVG_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:789:9
pub const FT_ERROR_DEFINITIONS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:795:9
pub const FT_PARAMETER_TAGS_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:796:9
pub const FT_UNPATENTED_HINTING_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:799:9
pub const FT_TRUETYPE_UNPATENTED_H = @compileError("unable to translate macro: undefined identifier `freetype`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftheader.h:800:9
pub const offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/include/stddef.h:104:9
pub const __strfmonlike = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/_types.h:31:9
pub const __strftimelike = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/_types.h:33:9
pub const __AVAILABILITY_INTERNAL_DEPRECATED = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:109:9
pub const __AVAILABILITY_INTERNAL_DEPRECATED_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:112:17
pub const __AVAILABILITY_INTERNAL_UNAVAILABLE = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:121:9
pub const __AVAILABILITY_INTERNAL_WEAK_IMPORT = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:122:9
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2922:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2923:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2924:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2926:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2930:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2932:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2937:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2941:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2942:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2944:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2948:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2950:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2954:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2956:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2961:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2965:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2966:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2968:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2972:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2974:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2978:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2980:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2985:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2990:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2994:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:2996:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3000:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3002:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3006:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3008:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_5 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3012:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_5_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3014:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_6 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3018:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_6_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3020:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3024:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_7_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3026:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3030:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3032:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3036:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3038:25
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3042:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3043:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3044:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3045:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3046:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3047:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3049:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3053:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3055:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3060:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3064:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3065:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3067:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3071:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3073:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3077:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3079:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3084:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3088:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3089:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3091:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3095:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3097:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3101:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3103:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3108:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3112:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3113:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3115:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3119:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3121:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3125:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3127:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_5 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3131:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_5_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3133:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_6 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3137:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_6_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3139:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3143:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_7_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3145:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3149:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3151:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3155:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3157:25
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3161:21
pub const __AVAILABILITY_INTERNAL__MAC_10_2_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3162:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3163:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3164:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3165:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3166:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3168:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3172:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3174:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3179:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3183:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3184:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3186:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3190:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3192:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3196:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3198:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3203:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3207:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3208:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3210:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3214:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3216:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3220:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3222:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3227:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3231:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3232:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3234:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3238:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3240:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_5 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3244:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_5_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3246:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_6 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3250:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_6_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3252:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3256:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_7_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3258:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3262:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3264:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3268:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3270:25
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3274:21
pub const __AVAILABILITY_INTERNAL__MAC_10_3_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3275:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3276:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3277:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3278:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3279:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3281:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3285:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3287:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3292:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3296:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3297:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3299:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3303:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3305:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3309:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3311:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3316:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3320:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3321:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3323:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3327:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3329:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3333:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3335:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3340:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3344:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3345:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3347:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_5 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3351:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_5_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3353:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_6 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3357:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_6_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3359:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3363:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_7_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3365:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3369:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3371:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3375:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3377:25
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3381:21
pub const __AVAILABILITY_INTERNAL__MAC_10_4_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3382:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3383:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEPRECATED__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3384:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3385:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3386:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3387:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3389:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3393:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3395:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3400:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3404:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3405:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3407:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3411:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3413:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3417:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3419:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3424:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3428:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3429:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3431:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3435:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3437:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3441:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3443:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3448:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_5 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3452:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_5_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3454:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_6 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3458:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_6_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3460:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3464:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_7_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3466:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3470:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3472:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3476:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3478:25
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3482:21
pub const __AVAILABILITY_INTERNAL__MAC_10_5_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3483:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3484:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3485:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3486:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3487:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3489:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3493:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3495:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3500:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3504:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3505:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3507:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3511:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3513:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3517:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3519:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3524:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3528:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3529:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3531:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3535:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3537:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3541:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3543:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3548:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3552:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_6 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3553:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_6_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3555:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3559:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_7_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3561:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3565:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3567:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3571:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3573:25
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3577:21
pub const __AVAILABILITY_INTERNAL__MAC_10_6_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3578:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3579:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3580:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3581:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3582:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3584:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3588:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3590:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3595:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3599:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3600:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3602:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3606:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3608:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3612:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3614:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3619:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3623:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3624:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3626:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3630:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3632:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3636:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3638:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3643:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_13_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3647:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3648:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_7_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3650:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3654:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3656:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3660:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3662:25
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3666:21
pub const __AVAILABILITY_INTERNAL__MAC_10_7_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3667:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3668:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3669:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3670:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3671:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3673:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3677:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3679:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3684:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3688:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3689:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3691:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3695:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3697:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3701:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3703:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3708:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3712:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3713:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3715:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3719:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3721:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3725:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3727:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3732:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3736:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3737:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3739:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3743:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3745:25
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3749:21
pub const __AVAILABILITY_INTERNAL__MAC_10_8_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3750:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3751:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3752:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3753:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3754:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3756:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3760:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3762:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3767:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3771:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3772:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3774:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3778:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3780:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3784:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3786:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3791:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3795:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3796:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3798:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3802:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3804:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3808:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3810:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3815:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3819:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_14 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3820:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3821:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3823:25
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3827:21
pub const __AVAILABILITY_INTERNAL__MAC_10_9_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3828:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3829:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_0 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3830:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_0_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3832:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3836:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3837:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3838:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3840:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3844:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3846:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3851:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3855:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3856:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3858:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3862:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3864:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3868:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3870:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3875:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3879:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3880:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3882:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3886:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3888:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3892:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3894:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3899:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3903:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3905:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3909:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3911:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3915:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3917:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3921:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3923:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_5 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3927:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_5_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3929:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_6 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3933:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_6_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3935:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_7 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3939:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_7_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3941:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_8 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3945:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_8_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3947:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_9 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3951:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_9_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3953:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_10_13_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3958:25
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3962:21
pub const __AVAILABILITY_INTERNAL__MAC_10_0_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3963:21
pub const __AVAILABILITY_INTERNAL__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3964:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3965:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3966:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3967:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3969:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3973:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3975:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3979:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3980:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3982:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3986:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3988:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3992:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3994:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:3999:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4003:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4004:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4006:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4010:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4012:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4016:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4018:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4023:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4027:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_2_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4028:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4029:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4030:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4032:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4036:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4037:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4039:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4043:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4045:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4049:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4051:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4056:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4060:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4061:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4063:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4067:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4069:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4073:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4075:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4080:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4084:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_3_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4085:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4086:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_10 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4087:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_10_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4088:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_10_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4090:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_10_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4094:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_10_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4096:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_10_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4101:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4105:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4106:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4108:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4112:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4114:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4118:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4120:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4125:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4129:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4130:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4132:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4136:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4138:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4142:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4144:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4149:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4153:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_13_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4155:25
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_10_13_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4159:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4160:21
pub const __AVAILABILITY_INTERNAL__MAC_10_10_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4161:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4162:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4163:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4164:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4166:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4170:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4172:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4176:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4178:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4182:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4183:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4185:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4189:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4191:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4195:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4197:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4202:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4206:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_2_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4207:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4208:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4209:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4211:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4215:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4217:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4221:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4222:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4224:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4228:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4230:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4234:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4236:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4241:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4245:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_3_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4246:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4247:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4248:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4250:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4254:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4255:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4257:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4261:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4263:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4267:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4269:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4274:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4278:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_4_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4279:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4280:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_11 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4281:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_11_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4282:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_11_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4284:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_11_3 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4288:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_11_3_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4290:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_11_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4294:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_11_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4296:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_11_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4301:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4305:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4306:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4308:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4312:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4314:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4318:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4320:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4325:25
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4329:21
pub const __AVAILABILITY_INTERNAL__MAC_10_11_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4330:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4331:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4332:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4333:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4335:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4339:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4341:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4345:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4347:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4351:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_1_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4352:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4353:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_2_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4354:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_2_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4356:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_2_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4360:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_2_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4362:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_2_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4366:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_2_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4367:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4368:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_4_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4369:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_4_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4371:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_4_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4375:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_4_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4376:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_12 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4377:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_12_1 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4378:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_12_1_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4380:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_12_2 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4384:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_12_2_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4386:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_12_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4390:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_12_4_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4392:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_12_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4397:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4401:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_13_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4403:25
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_13_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4407:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_10_14 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4408:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4409:21
pub const __AVAILABILITY_INTERNAL__MAC_10_12_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4410:21
pub const __AVAILABILITY_INTERNAL__MAC_10_13 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4411:21
pub const __AVAILABILITY_INTERNAL__MAC_10_13_4 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4412:21
pub const __AVAILABILITY_INTERNAL__MAC_10_14 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4413:21
pub const __AVAILABILITY_INTERNAL__MAC_10_14_DEP__MAC_10_14 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4414:21
pub const __AVAILABILITY_INTERNAL__MAC_10_15 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4415:21
pub const __AVAILABILITY_INTERNAL__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4417:21
pub const __AVAILABILITY_INTERNAL__MAC_NA_DEP__MAC_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4418:21
pub const __AVAILABILITY_INTERNAL__MAC_NA_DEP__MAC_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4419:21
pub const __AVAILABILITY_INTERNAL__IPHONE_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4421:21
pub const __AVAILABILITY_INTERNAL__IPHONE_NA__IPHONE_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4422:21
pub const __AVAILABILITY_INTERNAL__IPHONE_NA_DEP__IPHONE_NA = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4423:21
pub const __AVAILABILITY_INTERNAL__IPHONE_NA_DEP__IPHONE_NA_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4424:21
pub const __AVAILABILITY_INTERNAL__IPHONE_COMPAT_VERSION = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4427:22
pub const __AVAILABILITY_INTERNAL__IPHONE_COMPAT_VERSION_DEP__IPHONE_COMPAT_VERSION = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4428:22
pub const __AVAILABILITY_INTERNAL__IPHONE_COMPAT_VERSION_DEP__IPHONE_COMPAT_VERSION_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4429:22
pub const __API_AVAILABLE_PLATFORM_macos = @compileError("unable to translate macro: undefined identifier `macos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4445:13
pub const __API_AVAILABLE_PLATFORM_macosx = @compileError("unable to translate macro: undefined identifier `macosx`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4446:13
pub const __API_AVAILABLE_PLATFORM_ios = @compileError("unable to translate macro: undefined identifier `ios`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4447:13
pub const __API_AVAILABLE_PLATFORM_watchos = @compileError("unable to translate macro: undefined identifier `watchos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4448:13
pub const __API_AVAILABLE_PLATFORM_tvos = @compileError("unable to translate macro: undefined identifier `tvos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4449:13
pub const __API_AVAILABLE_PLATFORM_macCatalyst = @compileError("unable to translate macro: undefined identifier `macCatalyst`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4451:13
pub const __API_AVAILABLE_PLATFORM_uikitformac = @compileError("unable to translate macro: undefined identifier `uikitformac`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4454:14
pub const __API_AVAILABLE_PLATFORM_driverkit = @compileError("unable to translate macro: undefined identifier `driverkit`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4456:13
pub const __API_A = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4460:17
pub const __API_AVAILABLE2 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4469:13
pub const __API_AVAILABLE3 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4470:13
pub const __API_AVAILABLE4 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4471:13
pub const __API_AVAILABLE5 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4472:13
pub const __API_AVAILABLE6 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4473:13
pub const __API_AVAILABLE7 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4474:13
pub const __API_AVAILABLE_GET_MACRO = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4475:13
pub const __API_APPLY_TO = @compileError("unable to translate macro: undefined identifier `any`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4477:13
pub const __API_RANGE_STRINGIFY2 = @compileError("unable to translate C expr: unexpected token '#'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4479:13
pub const __API_A_BEGIN = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4481:13
pub const __API_AVAILABLE_BEGIN2 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4484:13
pub const __API_AVAILABLE_BEGIN3 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4485:13
pub const __API_AVAILABLE_BEGIN4 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4486:13
pub const __API_AVAILABLE_BEGIN5 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4487:13
pub const __API_AVAILABLE_BEGIN6 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4488:13
pub const __API_AVAILABLE_BEGIN7 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4489:13
pub const __API_AVAILABLE_BEGIN_GET_MACRO = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4490:13
pub const __API_DEPRECATED_PLATFORM_macos = @compileError("unable to translate macro: undefined identifier `macos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4493:13
pub const __API_DEPRECATED_PLATFORM_macosx = @compileError("unable to translate macro: undefined identifier `macosx`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4494:13
pub const __API_DEPRECATED_PLATFORM_ios = @compileError("unable to translate macro: undefined identifier `ios`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4495:13
pub const __API_DEPRECATED_PLATFORM_watchos = @compileError("unable to translate macro: undefined identifier `watchos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4496:13
pub const __API_DEPRECATED_PLATFORM_tvos = @compileError("unable to translate macro: undefined identifier `tvos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4497:13
pub const __API_DEPRECATED_PLATFORM_macCatalyst = @compileError("unable to translate macro: undefined identifier `macCatalyst`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4499:13
pub const __API_DEPRECATED_PLATFORM_uikitformac = @compileError("unable to translate macro: undefined identifier `uikitformac`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4502:14
pub const __API_DEPRECATED_PLATFORM_driverkit = @compileError("unable to translate macro: undefined identifier `driverkit`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4504:13
pub const __API_D = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4508:17
pub const __API_DEPRECATED_MSG3 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4517:13
pub const __API_DEPRECATED_MSG4 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4518:13
pub const __API_DEPRECATED_MSG5 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4519:13
pub const __API_DEPRECATED_MSG6 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4520:13
pub const __API_DEPRECATED_MSG7 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4521:13
pub const __API_DEPRECATED_MSG8 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4522:13
pub const __API_DEPRECATED_MSG_GET_MACRO = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4523:13
pub const __API_D_BEGIN = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4525:13
pub const __API_DEPRECATED_BEGIN_MSG3 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4528:13
pub const __API_DEPRECATED_BEGIN_MSG4 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4529:13
pub const __API_DEPRECATED_BEGIN_MSG5 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4530:13
pub const __API_DEPRECATED_BEGIN_MSG6 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4531:13
pub const __API_DEPRECATED_BEGIN_MSG7 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4532:13
pub const __API_DEPRECATED_BEGIN_MSG8 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4533:13
pub const __API_DEPRECATED_BEGIN_MSG_GET_MACRO = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4534:13
pub const __API_R = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4537:17
pub const __API_DEPRECATED_REP3 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4543:13
pub const __API_DEPRECATED_REP4 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4544:13
pub const __API_DEPRECATED_REP5 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4545:13
pub const __API_DEPRECATED_REP6 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4546:13
pub const __API_DEPRECATED_REP7 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4547:13
pub const __API_DEPRECATED_REP8 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4548:13
pub const __API_DEPRECATED_REP_GET_MACRO = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4549:13
pub const __API_R_BEGIN = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4552:17
pub const __API_DEPRECATED_BEGIN_REP3 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4558:13
pub const __API_DEPRECATED_BEGIN_REP4 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4559:13
pub const __API_DEPRECATED_BEGIN_REP5 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4560:13
pub const __API_DEPRECATED_BEGIN_REP6 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4561:13
pub const __API_DEPRECATED_BEGIN_REP7 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4562:13
pub const __API_DEPRECATED_BEGIN_REP8 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4563:13
pub const __API_DEPRECATED_BEGIN_REP_GET_MACRO = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4564:13
pub const __API_UNAVAILABLE_PLATFORM_macos = @compileError("unable to translate macro: undefined identifier `macos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4574:13
pub const __API_UNAVAILABLE_PLATFORM_macosx = @compileError("unable to translate macro: undefined identifier `macosx`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4575:13
pub const __API_UNAVAILABLE_PLATFORM_ios = @compileError("unable to translate macro: undefined identifier `ios`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4576:13
pub const __API_UNAVAILABLE_PLATFORM_watchos = @compileError("unable to translate macro: undefined identifier `watchos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4577:13
pub const __API_UNAVAILABLE_PLATFORM_tvos = @compileError("unable to translate macro: undefined identifier `tvos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4578:13
pub const __API_UNAVAILABLE_PLATFORM_macCatalyst = @compileError("unable to translate macro: undefined identifier `macCatalyst`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4580:13
pub const __API_UNAVAILABLE_PLATFORM_uikitformac = @compileError("unable to translate macro: undefined identifier `uikitformac`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4583:14
pub const __API_UNAVAILABLE_PLATFORM_driverkit = @compileError("unable to translate macro: undefined identifier `driverkit`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4585:13
pub const __API_U = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4589:17
pub const __API_UNAVAILABLE2 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4598:13
pub const __API_UNAVAILABLE3 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4599:13
pub const __API_UNAVAILABLE4 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4600:13
pub const __API_UNAVAILABLE5 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4601:13
pub const __API_UNAVAILABLE6 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4602:13
pub const __API_UNAVAILABLE7 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4603:13
pub const __API_UNAVAILABLE_GET_MACRO = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4604:13
pub const __API_U_BEGIN = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4606:13
pub const __API_UNAVAILABLE_BEGIN2 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4609:13
pub const __API_UNAVAILABLE_BEGIN3 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4610:13
pub const __API_UNAVAILABLE_BEGIN4 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4611:13
pub const __API_UNAVAILABLE_BEGIN5 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4612:13
pub const __API_UNAVAILABLE_BEGIN6 = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4613:13
pub const __API_UNAVAILABLE_BEGIN7 = @compileError("unable to translate macro: undefined identifier `g`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4614:13
pub const __API_UNAVAILABLE_BEGIN_GET_MACRO = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4615:13
pub const __swift_compiler_version_at_least = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4664:13
pub const __SPI_AVAILABLE = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos.12-any/AvailabilityInternal.h:4672:11
pub const __OSX_AVAILABLE_STARTING = @compileError("unable to translate macro: undefined identifier `__AVAILABILITY_INTERNAL`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:172:17
pub const __OSX_AVAILABLE_BUT_DEPRECATED = @compileError("unable to translate macro: undefined identifier `__AVAILABILITY_INTERNAL`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:173:17
pub const __OSX_AVAILABLE_BUT_DEPRECATED_MSG = @compileError("unable to translate macro: undefined identifier `__AVAILABILITY_INTERNAL`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:175:17
pub const __OS_AVAILABILITY = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:198:13
pub const __OS_AVAILABILITY_MSG = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:199:13
pub const __OSX_EXTENSION_UNAVAILABLE = @compileError("unable to translate macro: undefined identifier `macosx_app_extension`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:216:13
pub const __IOS_EXTENSION_UNAVAILABLE = @compileError("unable to translate macro: undefined identifier `ios_app_extension`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:217:13
pub const __OS_EXTENSION_UNAVAILABLE = @compileError("unable to translate C expr: unexpected token 'Identifier'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:227:9
pub const __OSX_UNAVAILABLE = @compileError("unable to translate macro: undefined identifier `macosx`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:234:13
pub const __OSX_AVAILABLE = @compileError("unable to translate macro: undefined identifier `macosx`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:235:13
pub const __OSX_DEPRECATED = @compileError("unable to translate macro: undefined identifier `macosx`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:236:13
pub const __IOS_UNAVAILABLE = @compileError("unable to translate macro: undefined identifier `ios`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:256:13
pub const __IOS_PROHIBITED = @compileError("unable to translate macro: undefined identifier `ios`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:257:13
pub const __IOS_AVAILABLE = @compileError("unable to translate macro: undefined identifier `ios`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:258:13
pub const __IOS_DEPRECATED = @compileError("unable to translate macro: undefined identifier `ios`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:259:13
pub const __TVOS_UNAVAILABLE = @compileError("unable to translate macro: undefined identifier `tvos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:283:13
pub const __TVOS_PROHIBITED = @compileError("unable to translate macro: undefined identifier `tvos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:284:13
pub const __TVOS_AVAILABLE = @compileError("unable to translate macro: undefined identifier `tvos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:285:13
pub const __TVOS_DEPRECATED = @compileError("unable to translate macro: undefined identifier `tvos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:286:13
pub const __WATCHOS_UNAVAILABLE = @compileError("unable to translate macro: undefined identifier `watchos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:310:13
pub const __WATCHOS_PROHIBITED = @compileError("unable to translate macro: undefined identifier `watchos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:311:13
pub const __WATCHOS_AVAILABLE = @compileError("unable to translate macro: undefined identifier `watchos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:312:13
pub const __WATCHOS_DEPRECATED = @compileError("unable to translate macro: undefined identifier `watchos`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:313:13
pub const __SWIFT_UNAVAILABLE = @compileError("unable to translate macro: undefined identifier `swift`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:337:13
pub const __SWIFT_UNAVAILABLE_MSG = @compileError("unable to translate macro: undefined identifier `swift`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:338:13
pub const __API_AVAILABLE = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:381:13
pub const __API_AVAILABLE_BEGIN = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:383:13
pub const __API_AVAILABLE_END = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:384:13
pub const __API_DEPRECATED = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:402:13
pub const __API_DEPRECATED_WITH_REPLACEMENT = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:403:13
pub const __API_DEPRECATED_BEGIN = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:405:13
pub const __API_DEPRECATED_END = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:406:13
pub const __API_DEPRECATED_WITH_REPLACEMENT_BEGIN = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:408:13
pub const __API_DEPRECATED_WITH_REPLACEMENT_END = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:409:13
pub const __API_UNAVAILABLE = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:419:13
pub const __API_UNAVAILABLE_BEGIN = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:421:13
pub const __API_UNAVAILABLE_END = @compileError("unable to translate macro: undefined identifier `_Pragma`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:422:13
pub const __SPI_DEPRECATED = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:475:11
pub const __SPI_DEPRECATED_WITH_REPLACEMENT = @compileError("unable to translate C expr: expected ')' instead got '...'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/Availability.h:479:11
pub const __sgetc = @compileError("TODO unary inc/dec expr"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdio.h:251:9
pub const __sclearerr = @compileError("unable to translate C expr: expected ')' instead got '&='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdio.h:275:9
pub const SIG_DFL = @compileError("unable to translate C expr: expected ')' instead got '('"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/signal.h:131:9
pub const SIG_IGN = @compileError("unable to translate C expr: expected ')' instead got '('"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/signal.h:132:9
pub const SIG_HOLD = @compileError("unable to translate C expr: expected ')' instead got '('"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/signal.h:133:9
pub const SIG_ERR = @compileError("unable to translate C expr: expected ')' instead got '('"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/signal.h:134:9
pub const __darwin_arm_thread_state64_set_pc_fptr = @compileError("unable to translate C expr: expected ')' instead got '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/aarch64-macos.12-none/mach/arm/_structs.h:362:9
pub const __darwin_arm_thread_state64_set_lr_fptr = @compileError("unable to translate C expr: expected ')' instead got '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/aarch64-macos.12-none/mach/arm/_structs.h:371:9
pub const __darwin_arm_thread_state64_set_sp = @compileError("unable to translate C expr: expected ')' instead got '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/aarch64-macos.12-none/mach/arm/_structs.h:377:9
pub const __darwin_arm_thread_state64_set_fp = @compileError("unable to translate C expr: expected ')' instead got '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/aarch64-macos.12-none/mach/arm/_structs.h:383:9
pub const sv_onstack = @compileError("unable to translate macro: undefined identifier `sv_flags`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/signal.h:361:9
pub const ru_first = @compileError("unable to translate macro: undefined identifier `ru_ixrss`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/resource.h:164:9
pub const ru_last = @compileError("unable to translate macro: undefined identifier `ru_nivcsw`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/resource.h:178:9
pub const __DARWIN_OS_INLINE = @compileError("unable to translate C expr: unexpected token 'static'"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/libkern/_OSByteOrder.h:67:17
pub const NTOHL = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/_endian.h:143:9
pub const NTOHS = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/_endian.h:144:9
pub const NTOHLL = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/_endian.h:145:9
pub const HTONL = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/_endian.h:146:9
pub const HTONS = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/_endian.h:147:9
pub const HTONLL = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/_endian.h:148:9
pub const w_termsig = @compileError("unable to translate macro: undefined identifier `w_T`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/wait.h:231:9
pub const w_coredump = @compileError("unable to translate macro: undefined identifier `w_T`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/wait.h:232:9
pub const w_retcode = @compileError("unable to translate macro: undefined identifier `w_T`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/wait.h:233:9
pub const w_stopval = @compileError("unable to translate macro: undefined identifier `w_S`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/wait.h:234:9
pub const w_stopsig = @compileError("unable to translate macro: undefined identifier `w_S`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/sys/wait.h:235:9
pub const __alloca = @compileError("unable to translate macro: undefined identifier `__builtin_alloca`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/alloca.h:40:9
pub const __bsearch_noescape = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:272:9
pub const __sort_noescape = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/stdlib.h:305:9
pub const ft_setjmp = @compileError("unable to translate C expr: unexpected token ')'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/ftstdlib.h:173:9
pub const va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/include/stdarg.h:17:9
pub const va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/include/stdarg.h:18:9
pub const va_arg = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/include/stdarg.h:19:9
pub const __va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/include/stdarg.h:24:9
pub const va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/include/stdarg.h:27:9
pub const FT_PUBLIC_FUNCTION_ATTRIBUTE = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/public-macros.h:76:9
pub const FT_EXPORT = @compileError("unable to translate C expr: unexpected token 'extern'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/public-macros.h:104:9
pub const FT_UNUSED = @compileError("unable to translate C expr: expected ')' instead got '='"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/config/public-macros.h:115:9
pub const WEAK_IMPORT_ATTRIBUTE = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/AvailabilityMacros.h:171:13
pub const DEPRECATED_ATTRIBUTE = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/AvailabilityMacros.h:183:17
pub const DEPRECATED_MSG_ATTRIBUTE = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/AvailabilityMacros.h:185:21
pub const UNAVAILABLE_ATTRIBUTE = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /Users/slimsag/Desktop/zig-macos-aarch64-0.10.0-dev.3551+92568a009/lib/zig/libc/include/any-macos-any/AvailabilityMacros.h:209:13
pub const FT_IMAGE_TAG = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/ftimage.h:699:9
pub const FT_ERR_XCAT = @compileError("unable to translate C expr: unexpected token '##'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/fttypes.h:593:9
pub const FT_MODERRDEF = @compileError("unable to translate macro: undefined identifier `FT_Mod_Err_`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/ftmoderr.h:123:9
pub const FT_MODERR_START_LIST = @compileError("unable to translate C expr: expected 'Identifier' instead got '{'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/ftmoderr.h:126:9
pub const FT_MODERR_END_LIST = @compileError("unable to translate C expr: unexpected token '}'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/ftmoderr.h:127:9
pub const FT_ERR_PREFIX = @compileError("unable to translate macro: undefined identifier `FT_Err_`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/fterrors.h:146:9
pub const FT_ERRORDEF = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/fterrors.h:173:9
pub const FT_ERROR_START_LIST = @compileError("unable to translate C expr: expected 'Identifier' instead got '{'"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/fterrors.h:174:9
pub const FT_ERROR_END_LIST = @compileError("unable to translate macro: undefined identifier `Max`"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/fterrors.h:175:9
pub const FT_ENC_TAG = @compileError("unable to translate C expr: unexpected token '='"); // /Users/slimsag/Desktop/hexops/mach/libs/freetype/upstream/freetype/include/freetype/freetype.h:629:9
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
pub const _LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS = @as(c_int, 1);
pub const _LIBCXXABI_DISABLE_VISIBILITY_ANNOTATIONS = @as(c_int, 1);
pub const _LIBCPP_HAS_NO_VENDOR_AVAILABILITY_ANNOTATIONS = @as(c_int, 1);
pub const _DEBUG = @as(c_int, 1);
pub const __GCC_HAVE_DWARF2_CFI_ASM = @as(c_int, 1);
pub const HB_FT_H = "";
pub const HB_H = "";
pub const HB_H_IN = "";
pub const HB_BLOB_H = "";
pub const HB_COMMON_H = "";
pub const HB_BEGIN_DECLS = "";
pub const HB_END_DECLS = "";
pub const _LIBCPP_STDINT_H = "";
pub const _LIBCPP_CONFIG = "";
pub const __CLANG_STDINT_H = "";
pub const _STDINT_H_ = "";
pub const __WORDSIZE = @as(c_int, 64);
pub const _INT8_T = "";
pub const _INT16_T = "";
pub const _INT32_T = "";
pub const _INT64_T = "";
pub const _UINT8_T = "";
pub const _UINT16_T = "";
pub const _UINT32_T = "";
pub const _UINT64_T = "";
pub const _SYS__TYPES_H_ = "";
pub const _CDEFS_H_ = "";
pub const __BEGIN_DECLS = "";
pub const __END_DECLS = "";
pub inline fn __P(protos: anytype) @TypeOf(protos) {
    return protos;
}
pub const __signed = c_int;
pub inline fn __deprecated_enum_msg(_msg: anytype) @TypeOf(__deprecated_msg(_msg)) {
    return __deprecated_msg(_msg);
}
pub const __kpi_unavailable = "";
pub const __kpi_deprecated_arm64_macos_unavailable = "";
pub const __dead = "";
pub const __pure = "";
pub const __abortlike = __dead2 ++ __cold ++ __not_tail_called;
pub const __DARWIN_ONLY_64_BIT_INO_T = @as(c_int, 1);
pub const __DARWIN_ONLY_UNIX_CONFORMANCE = @as(c_int, 1);
pub const __DARWIN_ONLY_VERS_1050 = @as(c_int, 1);
pub const __DARWIN_UNIX03 = @as(c_int, 1);
pub const __DARWIN_64_BIT_INO_T = @as(c_int, 1);
pub const __DARWIN_VERS_1050 = @as(c_int, 1);
pub const __DARWIN_NON_CANCELABLE = @as(c_int, 0);
pub const __DARWIN_SUF_UNIX03 = "";
pub const __DARWIN_SUF_64_BIT_INO_T = "";
pub const __DARWIN_SUF_1050 = "";
pub const __DARWIN_SUF_NON_CANCELABLE = "";
pub const __DARWIN_SUF_EXTSN = "$DARWIN_EXTSN";
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_0(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_1(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_2(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_3(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_4(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_5(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_6(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_7(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_8(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_9(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_10(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_2(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_10_3(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_11(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_2(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_3(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_11_4(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_12(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_1(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_2(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_12_4(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_13(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_1(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_2(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_13_4(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_1(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_4(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_5(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_14_6(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_15(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_15_1(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_10_16(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_0(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_1(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_11_3(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_0(x: anytype) @TypeOf(x) {
    return x;
}
pub inline fn __DARWIN_ALIAS_STARTING_MAC___MAC_12_1(x: anytype) @TypeOf(x) {
    return x;
}
pub const ___POSIX_C_DEPRECATED_STARTING_198808L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_199009L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_199209L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_199309L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_199506L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_200112L = "";
pub const ___POSIX_C_DEPRECATED_STARTING_200809L = "";
pub const __DARWIN_C_ANSI = @as(c_long, 0o10000);
pub const __DARWIN_C_FULL = @as(c_long, 900000);
pub const __DARWIN_C_LEVEL = __DARWIN_C_FULL;
pub const __STDC_WANT_LIB_EXT1__ = @as(c_int, 1);
pub const __DARWIN_NO_LONG_LONG = @as(c_int, 0);
pub const _DARWIN_FEATURE_64_BIT_INODE = @as(c_int, 1);
pub const _DARWIN_FEATURE_ONLY_64_BIT_INODE = @as(c_int, 1);
pub const _DARWIN_FEATURE_ONLY_VERS_1050 = @as(c_int, 1);
pub const _DARWIN_FEATURE_ONLY_UNIX_CONFORMANCE = @as(c_int, 1);
pub const _DARWIN_FEATURE_UNIX_CONFORMANCE = @as(c_int, 3);
pub inline fn __CAST_AWAY_QUALIFIER(variable: anytype, qualifier: anytype, @"type": anytype) @TypeOf(@"type"(c_long)(variable)) {
    _ = qualifier;
    return @"type"(c_long)(variable);
}
pub const __has_ptrcheck = @as(c_int, 0);
pub const __single = "";
pub const __unsafe_indexable = "";
pub inline fn __unsafe_forge_bidi_indexable(T: anytype, P: anytype, S: anytype) @TypeOf(T(P)) {
    _ = S;
    return T(P);
}
pub const __unsafe_forge_single = @import("std").zig.c_translation.Macros.CAST_OR_CALL;
pub const __array_decay_dicards_count_in_parameters = "";
pub const __ASSUME_PTR_ABI_SINGLE_BEGIN = __ptrcheck_abi_assume_single();
pub const __ASSUME_PTR_ABI_SINGLE_END = __ptrcheck_abi_assume_unsafe_indexable();
pub const __header_indexable = "";
pub const __header_bidi_indexable = "";
pub const __kernel_ptr_semantics = "";
pub const __kernel_data_semantics = "";
pub const __kernel_dual_semantics = "";
pub const _BSD_MACHINE__TYPES_H_ = "";
pub const _BSD_ARM__TYPES_H_ = "";
pub const __DARWIN_NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const _SYS__PTHREAD_TYPES_H_ = "";
pub const __PTHREAD_SIZE__ = @as(c_int, 8176);
pub const __PTHREAD_ATTR_SIZE__ = @as(c_int, 56);
pub const __PTHREAD_MUTEXATTR_SIZE__ = @as(c_int, 8);
pub const __PTHREAD_MUTEX_SIZE__ = @as(c_int, 56);
pub const __PTHREAD_CONDATTR_SIZE__ = @as(c_int, 8);
pub const __PTHREAD_COND_SIZE__ = @as(c_int, 40);
pub const __PTHREAD_ONCE_SIZE__ = @as(c_int, 8);
pub const __PTHREAD_RWLOCK_SIZE__ = @as(c_int, 192);
pub const __PTHREAD_RWLOCKATTR_SIZE__ = @as(c_int, 16);
pub const _INTPTR_T = "";
pub const _BSD_MACHINE_TYPES_H_ = "";
pub const _ARM_MACHTYPES_H_ = "";
pub const _MACHTYPES_H_ = "";
pub const _U_INT8_T = "";
pub const _U_INT16_T = "";
pub const _U_INT32_T = "";
pub const _U_INT64_T = "";
pub const _UINTPTR_T = "";
pub const USER_ADDR_NULL = @import("std").zig.c_translation.cast(user_addr_t, @as(c_int, 0));
pub inline fn CAST_USER_ADDR_T(a_ptr: anytype) user_addr_t {
    return @import("std").zig.c_translation.cast(user_addr_t, @import("std").zig.c_translation.cast(usize, a_ptr));
}
pub const _INTMAX_T = "";
pub const _UINTMAX_T = "";
pub inline fn INT8_C(v: anytype) @TypeOf(v) {
    return v;
}
pub inline fn INT16_C(v: anytype) @TypeOf(v) {
    return v;
}
pub inline fn INT32_C(v: anytype) @TypeOf(v) {
    return v;
}
pub const INT64_C = @import("std").zig.c_translation.Macros.LL_SUFFIX;
pub inline fn UINT8_C(v: anytype) @TypeOf(v) {
    return v;
}
pub inline fn UINT16_C(v: anytype) @TypeOf(v) {
    return v;
}
pub const UINT32_C = @import("std").zig.c_translation.Macros.U_SUFFIX;
pub const UINT64_C = @import("std").zig.c_translation.Macros.ULL_SUFFIX;
pub const INTMAX_C = @import("std").zig.c_translation.Macros.L_SUFFIX;
pub const UINTMAX_C = @import("std").zig.c_translation.Macros.UL_SUFFIX;
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = @as(c_longlong, 9223372036854775807);
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 32768, .decimal);
pub const INT32_MIN = -INT32_MAX - @as(c_int, 1);
pub const INT64_MIN = -INT64_MAX - @as(c_int, 1);
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT64_MAX = @as(c_ulonglong, 18446744073709551615);
pub const INT_LEAST8_MIN = INT8_MIN;
pub const INT_LEAST16_MIN = INT16_MIN;
pub const INT_LEAST32_MIN = INT32_MIN;
pub const INT_LEAST64_MIN = INT64_MIN;
pub const INT_LEAST8_MAX = INT8_MAX;
pub const INT_LEAST16_MAX = INT16_MAX;
pub const INT_LEAST32_MAX = INT32_MAX;
pub const INT_LEAST64_MAX = INT64_MAX;
pub const UINT_LEAST8_MAX = UINT8_MAX;
pub const UINT_LEAST16_MAX = UINT16_MAX;
pub const UINT_LEAST32_MAX = UINT32_MAX;
pub const UINT_LEAST64_MAX = UINT64_MAX;
pub const INT_FAST8_MIN = INT8_MIN;
pub const INT_FAST16_MIN = INT16_MIN;
pub const INT_FAST32_MIN = INT32_MIN;
pub const INT_FAST64_MIN = INT64_MIN;
pub const INT_FAST8_MAX = INT8_MAX;
pub const INT_FAST16_MAX = INT16_MAX;
pub const INT_FAST32_MAX = INT32_MAX;
pub const INT_FAST64_MAX = INT64_MAX;
pub const UINT_FAST8_MAX = UINT8_MAX;
pub const UINT_FAST16_MAX = UINT16_MAX;
pub const UINT_FAST32_MAX = UINT32_MAX;
pub const UINT_FAST64_MAX = UINT64_MAX;
pub const INTPTR_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INTPTR_MIN = -INTPTR_MAX - @as(c_int, 1);
pub const UINTPTR_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const INTMAX_MAX = INTMAX_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINTMAX_MAX = UINTMAX_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INTMAX_MIN = -INTMAX_MAX - @as(c_int, 1);
pub const PTRDIFF_MIN = INTMAX_MIN;
pub const PTRDIFF_MAX = INTMAX_MAX;
pub const SIZE_MAX = UINTPTR_MAX;
pub const RSIZE_MAX = SIZE_MAX >> @as(c_int, 1);
pub const WCHAR_MAX = __WCHAR_MAX__;
pub const WCHAR_MIN = -WCHAR_MAX - @as(c_int, 1);
pub const WINT_MIN = INT32_MIN;
pub const WINT_MAX = INT32_MAX;
pub const SIG_ATOMIC_MIN = INT32_MIN;
pub const SIG_ATOMIC_MAX = INT32_MAX;
pub inline fn HB_DEPRECATED_FOR(f: anytype) @TypeOf(HB_DEPRECATED) {
    _ = f;
    return HB_DEPRECATED;
}
pub inline fn HB_TAG(c1: anytype, c2: anytype, c3: anytype, c4: anytype) hb_tag_t {
    return @import("std").zig.c_translation.cast(hb_tag_t, ((((@import("std").zig.c_translation.cast(u32, c1) & @as(c_int, 0xFF)) << @as(c_int, 24)) | ((@import("std").zig.c_translation.cast(u32, c2) & @as(c_int, 0xFF)) << @as(c_int, 16))) | ((@import("std").zig.c_translation.cast(u32, c3) & @as(c_int, 0xFF)) << @as(c_int, 8))) | (@import("std").zig.c_translation.cast(u32, c4) & @as(c_int, 0xFF)));
}
pub inline fn HB_UNTAG(tag: anytype) u8 {
    return blk: {
        _ = @import("std").zig.c_translation.cast(u8, (tag >> @as(c_int, 24)) & @as(c_int, 0xFF));
        _ = @import("std").zig.c_translation.cast(u8, (tag >> @as(c_int, 16)) & @as(c_int, 0xFF));
        _ = @import("std").zig.c_translation.cast(u8, (tag >> @as(c_int, 8)) & @as(c_int, 0xFF));
        break :blk @import("std").zig.c_translation.cast(u8, tag & @as(c_int, 0xFF));
    };
}
pub const HB_TAG_NONE = HB_TAG(@as(c_int, 0), @as(c_int, 0), @as(c_int, 0), @as(c_int, 0));
pub const HB_TAG_MAX = HB_TAG(@as(c_int, 0xff), @as(c_int, 0xff), @as(c_int, 0xff), @as(c_int, 0xff));
pub const HB_TAG_MAX_SIGNED = HB_TAG(@as(c_int, 0x7f), @as(c_int, 0xff), @as(c_int, 0xff), @as(c_int, 0xff));
pub inline fn HB_DIRECTION_IS_VALID(dir: anytype) @TypeOf((@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 3)) == @as(c_int, 4)) {
    return (@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 3)) == @as(c_int, 4);
}
pub inline fn HB_DIRECTION_IS_HORIZONTAL(dir: anytype) @TypeOf((@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 1)) == @as(c_int, 4)) {
    return (@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 1)) == @as(c_int, 4);
}
pub inline fn HB_DIRECTION_IS_VERTICAL(dir: anytype) @TypeOf((@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 1)) == @as(c_int, 6)) {
    return (@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 1)) == @as(c_int, 6);
}
pub inline fn HB_DIRECTION_IS_FORWARD(dir: anytype) @TypeOf((@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 2)) == @as(c_int, 4)) {
    return (@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 2)) == @as(c_int, 4);
}
pub inline fn HB_DIRECTION_IS_BACKWARD(dir: anytype) @TypeOf((@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 2)) == @as(c_int, 5)) {
    return (@import("std").zig.c_translation.cast(c_uint, dir) & ~@as(c_uint, 2)) == @as(c_int, 5);
}
pub inline fn HB_DIRECTION_REVERSE(dir: anytype) hb_direction_t {
    return @import("std").zig.c_translation.cast(hb_direction_t, @import("std").zig.c_translation.cast(c_uint, dir) ^ @as(c_int, 1));
}
pub const HB_LANGUAGE_INVALID = @import("std").zig.c_translation.cast(hb_language_t, @as(c_int, 0));
pub const HB_FEATURE_GLOBAL_START = @as(c_int, 0);
pub const HB_FEATURE_GLOBAL_END = @import("std").zig.c_translation.cast(c_uint, -@as(c_int, 1));
pub inline fn HB_COLOR(b: anytype, g: anytype, r: anytype, a: anytype) hb_color_t {
    return @import("std").zig.c_translation.cast(hb_color_t, HB_TAG(b, g, r, a));
}
pub const HB_BUFFER_H = "";
pub const HB_UNICODE_H = "";
pub const HB_UNICODE_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0x10FFFF, .hexadecimal);
pub const HB_FONT_H = "";
pub const HB_FACE_H = "";
pub const HB_SET_H = "";
pub const HB_SET_VALUE_INVALID = @import("std").zig.c_translation.cast(hb_codepoint_t, -@as(c_int, 1));
pub const HB_DRAW_H = "";
pub const HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT = @as(c_uint, 0xFFFD);
pub const HB_DEPRECATED_H = "";
pub const HB_SCRIPT_CANADIAN_ABORIGINAL = HB_SCRIPT_CANADIAN_SYLLABICS;
pub const HB_BUFFER_FLAGS_DEFAULT = HB_BUFFER_FLAG_DEFAULT;
pub const HB_BUFFER_SERIALIZE_FLAGS_DEFAULT = HB_BUFFER_SERIALIZE_FLAG_DEFAULT;
pub const HB_UNICODE_MAX_DECOMPOSITION_LEN = @as(c_int, 18) + @as(c_int, 1);
pub const HB_MAP_H = "";
pub const HB_MAP_VALUE_INVALID = @import("std").zig.c_translation.cast(hb_codepoint_t, -@as(c_int, 1));
pub const HB_SHAPE_H = "";
pub const HB_SHAPE_PLAN_H = "";
pub const HB_STYLE_H = "";
pub const HB_VERSION_H = "";
pub const HB_VERSION_MAJOR = @as(c_int, 4);
pub const HB_VERSION_MINOR = @as(c_int, 3);
pub const HB_VERSION_MICRO = @as(c_int, 0);
pub const HB_VERSION_STRING = "4.3.0";
pub inline fn HB_VERSION_ATLEAST(major: anytype, minor: anytype, micro: anytype) @TypeOf((((major * @as(c_int, 10000)) + (minor * @as(c_int, 100))) + micro) <= (((HB_VERSION_MAJOR * @as(c_int, 10000)) + (HB_VERSION_MINOR * @as(c_int, 100))) + HB_VERSION_MICRO)) {
    return (((major * @as(c_int, 10000)) + (minor * @as(c_int, 100))) + micro) <= (((HB_VERSION_MAJOR * @as(c_int, 10000)) + (HB_VERSION_MINOR * @as(c_int, 100))) + HB_VERSION_MICRO);
}
pub const FT2BUILD_H_ = "";
pub const FTHEADER_H_ = "";
pub const FT_BEGIN_HEADER = "";
pub const FT_END_HEADER = "";
pub const FT_AUTOHINTER_H = FT_DRIVER_H;
pub const FT_CFF_DRIVER_H = FT_DRIVER_H;
pub const FT_TRUETYPE_DRIVER_H = FT_DRIVER_H;
pub const FT_PCF_DRIVER_H = FT_DRIVER_H;
pub const FT_XFREE86_H = FT_FONT_FORMATS_H;
pub const FT_CACHE_IMAGE_H = FT_CACHE_H;
pub const FT_CACHE_SMALL_BITMAPS_H = FT_CACHE_H;
pub const FT_CACHE_CHARMAP_H = FT_CACHE_H;
pub const FT_CACHE_MANAGER_H = FT_CACHE_H;
pub const FT_CACHE_INTERNAL_MRU_H = FT_CACHE_H;
pub const FT_CACHE_INTERNAL_MANAGER_H = FT_CACHE_H;
pub const FT_CACHE_INTERNAL_CACHE_H = FT_CACHE_H;
pub const FT_CACHE_INTERNAL_GLYPH_H = FT_CACHE_H;
pub const FT_CACHE_INTERNAL_IMAGE_H = FT_CACHE_H;
pub const FT_CACHE_INTERNAL_SBITS_H = FT_CACHE_H;
pub const FREETYPE_H_ = "";
pub const FTCONFIG_H_ = "";
pub const FTOPTION_H_ = "";
pub const FT_CONFIG_OPTION_ENVIRONMENT_PROPERTIES = "";
pub const FT_CONFIG_OPTION_INLINE_MULFIX = "";
pub const FT_CONFIG_OPTION_USE_LZW = "";
pub const FT_CONFIG_OPTION_USE_ZLIB = "";
pub const FT_CONFIG_OPTION_POSTSCRIPT_NAMES = "";
pub const FT_CONFIG_OPTION_ADOBE_GLYPH_LIST = "";
pub const FT_CONFIG_OPTION_MAC_FONTS = "";
pub const FT_CONFIG_OPTION_GUESSING_EMBEDDED_RFORK = "";
pub const FT_CONFIG_OPTION_INCREMENTAL = "";
pub const FT_RENDER_POOL_SIZE = @as(c_long, 16384);
pub const FT_MAX_MODULES = @as(c_int, 32);
pub const FT_CONFIG_OPTION_SVG = "";
pub const TT_CONFIG_OPTION_EMBEDDED_BITMAPS = "";
pub const TT_CONFIG_OPTION_COLOR_LAYERS = "";
pub const TT_CONFIG_OPTION_POSTSCRIPT_NAMES = "";
pub const TT_CONFIG_OPTION_SFNT_NAMES = "";
pub const TT_CONFIG_CMAP_FORMAT_0 = "";
pub const TT_CONFIG_CMAP_FORMAT_2 = "";
pub const TT_CONFIG_CMAP_FORMAT_4 = "";
pub const TT_CONFIG_CMAP_FORMAT_6 = "";
pub const TT_CONFIG_CMAP_FORMAT_8 = "";
pub const TT_CONFIG_CMAP_FORMAT_10 = "";
pub const TT_CONFIG_CMAP_FORMAT_12 = "";
pub const TT_CONFIG_CMAP_FORMAT_13 = "";
pub const TT_CONFIG_CMAP_FORMAT_14 = "";
pub const TT_CONFIG_OPTION_BYTECODE_INTERPRETER = "";
pub const TT_CONFIG_OPTION_SUBPIXEL_HINTING = @as(c_int, 2);
pub const TT_CONFIG_OPTION_GX_VAR_SUPPORT = "";
pub const TT_CONFIG_OPTION_BDF = "";
pub const TT_CONFIG_OPTION_MAX_RUNNABLE_OPCODES = @as(c_long, 1000000);
pub const T1_MAX_DICT_DEPTH = @as(c_int, 5);
pub const T1_MAX_SUBRS_CALLS = @as(c_int, 16);
pub const T1_MAX_CHARSTRINGS_OPERANDS = @as(c_int, 256);
pub const CFF_CONFIG_OPTION_DARKENING_PARAMETER_X1 = @as(c_int, 500);
pub const CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y1 = @as(c_int, 400);
pub const CFF_CONFIG_OPTION_DARKENING_PARAMETER_X2 = @as(c_int, 1000);
pub const CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y2 = @as(c_int, 275);
pub const CFF_CONFIG_OPTION_DARKENING_PARAMETER_X3 = @as(c_int, 1667);
pub const CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y3 = @as(c_int, 275);
pub const CFF_CONFIG_OPTION_DARKENING_PARAMETER_X4 = @as(c_int, 2333);
pub const CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y4 = @as(c_int, 0);
pub const AF_CONFIG_OPTION_CJK = "";
pub const AF_CONFIG_OPTION_INDIC = "";
pub const TT_USE_BYTECODE_INTERPRETER = "";
pub const TT_SUPPORT_SUBPIXEL_HINTING_MINIMAL = "";
pub const TT_SUPPORT_COLRV1 = "";
pub const FTSTDLIB_H_ = "";
pub const _LIBCPP_STDDEF_H = "";
pub const __STDDEF_H = "";
pub const __need_ptrdiff_t = "";
pub const __need_size_t = "";
pub const __need_wchar_t = "";
pub const __need_NULL = "";
pub const __need_STDDEF_H_misc = "";
pub const _PTRDIFF_T = "";
pub const _SIZE_T = "";
pub const _RSIZE_T = "";
pub const _WCHAR_T = "";
pub const NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const __CLANG_MAX_ALIGN_T_DEFINED = "";
pub const ft_ptrdiff_t = ptrdiff_t;
pub const _LIBCPP_LIMITS_H = "";
pub const _GCC_LIMITS_H_ = "";
pub const _GCC_NEXT_LIMITS_H = "";
pub const __CLANG_LIMITS_H = "";
pub const _LIMITS_H_ = "";
pub const _BSD_MACHINE_LIMITS_H_ = "";
pub const _ARM_LIMITS_H_ = "";
pub const _ARM__LIMITS_H_ = "";
pub const __DARWIN_CLK_TCK = @as(c_int, 100);
pub const CHAR_BIT = @as(c_int, 8);
pub const MB_LEN_MAX = @as(c_int, 6);
pub const CLK_TCK = __DARWIN_CLK_TCK;
pub const SCHAR_MAX = @as(c_int, 127);
pub const SCHAR_MIN = -@as(c_int, 128);
pub const UCHAR_MAX = @as(c_int, 255);
pub const CHAR_MAX = @as(c_int, 127);
pub const CHAR_MIN = -@as(c_int, 128);
pub const USHRT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const SHRT_MAX = @as(c_int, 32767);
pub const SHRT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 32768, .decimal);
pub const UINT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffffffff, .hexadecimal);
pub const INT_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const ULONG_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 0xffffffffffffffff, .hexadecimal);
pub const LONG_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_long, 0x7fffffffffffffff, .hexadecimal);
pub const LONG_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_long, 0x7fffffffffffffff, .hexadecimal) - @as(c_int, 1);
pub const ULLONG_MAX = @as(c_ulonglong, 0xffffffffffffffff);
pub const LLONG_MAX = @as(c_longlong, 0x7fffffffffffffff);
pub const LLONG_MIN = -@as(c_longlong, 0x7fffffffffffffff) - @as(c_int, 1);
pub const LONG_BIT = @as(c_int, 64);
pub const SSIZE_MAX = LONG_MAX;
pub const WORD_BIT = @as(c_int, 32);
pub const SIZE_T_MAX = ULONG_MAX;
pub const UQUAD_MAX = ULLONG_MAX;
pub const QUAD_MAX = LLONG_MAX;
pub const QUAD_MIN = LLONG_MIN;
pub const _SYS_SYSLIMITS_H_ = "";
pub const ARG_MAX = @as(c_int, 1024) * @as(c_int, 1024);
pub const CHILD_MAX = @as(c_int, 266);
pub const GID_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 2147483647, .decimal);
pub const LINK_MAX = @as(c_int, 32767);
pub const MAX_CANON = @as(c_int, 1024);
pub const MAX_INPUT = @as(c_int, 1024);
pub const NAME_MAX = @as(c_int, 255);
pub const NGROUPS_MAX = @as(c_int, 16);
pub const UID_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 2147483647, .decimal);
pub const OPEN_MAX = @as(c_int, 10240);
pub const PATH_MAX = @as(c_int, 1024);
pub const PIPE_BUF = @as(c_int, 512);
pub const BC_BASE_MAX = @as(c_int, 99);
pub const BC_DIM_MAX = @as(c_int, 2048);
pub const BC_SCALE_MAX = @as(c_int, 99);
pub const BC_STRING_MAX = @as(c_int, 1000);
pub const CHARCLASS_NAME_MAX = @as(c_int, 14);
pub const COLL_WEIGHTS_MAX = @as(c_int, 2);
pub const EQUIV_CLASS_MAX = @as(c_int, 2);
pub const EXPR_NEST_MAX = @as(c_int, 32);
pub const LINE_MAX = @as(c_int, 2048);
pub const RE_DUP_MAX = @as(c_int, 255);
pub const NZERO = @as(c_int, 20);
pub const _POSIX_ARG_MAX = @as(c_int, 4096);
pub const _POSIX_CHILD_MAX = @as(c_int, 25);
pub const _POSIX_LINK_MAX = @as(c_int, 8);
pub const _POSIX_MAX_CANON = @as(c_int, 255);
pub const _POSIX_MAX_INPUT = @as(c_int, 255);
pub const _POSIX_NAME_MAX = @as(c_int, 14);
pub const _POSIX_NGROUPS_MAX = @as(c_int, 8);
pub const _POSIX_OPEN_MAX = @as(c_int, 20);
pub const _POSIX_PATH_MAX = @as(c_int, 256);
pub const _POSIX_PIPE_BUF = @as(c_int, 512);
pub const _POSIX_SSIZE_MAX = @as(c_int, 32767);
pub const _POSIX_STREAM_MAX = @as(c_int, 8);
pub const _POSIX_TZNAME_MAX = @as(c_int, 6);
pub const _POSIX2_BC_BASE_MAX = @as(c_int, 99);
pub const _POSIX2_BC_DIM_MAX = @as(c_int, 2048);
pub const _POSIX2_BC_SCALE_MAX = @as(c_int, 99);
pub const _POSIX2_BC_STRING_MAX = @as(c_int, 1000);
pub const _POSIX2_EQUIV_CLASS_MAX = @as(c_int, 2);
pub const _POSIX2_EXPR_NEST_MAX = @as(c_int, 32);
pub const _POSIX2_LINE_MAX = @as(c_int, 2048);
pub const _POSIX2_RE_DUP_MAX = @as(c_int, 255);
pub const _POSIX_AIO_LISTIO_MAX = @as(c_int, 2);
pub const _POSIX_AIO_MAX = @as(c_int, 1);
pub const _POSIX_DELAYTIMER_MAX = @as(c_int, 32);
pub const _POSIX_MQ_OPEN_MAX = @as(c_int, 8);
pub const _POSIX_MQ_PRIO_MAX = @as(c_int, 32);
pub const _POSIX_RTSIG_MAX = @as(c_int, 8);
pub const _POSIX_SEM_NSEMS_MAX = @as(c_int, 256);
pub const _POSIX_SEM_VALUE_MAX = @as(c_int, 32767);
pub const _POSIX_SIGQUEUE_MAX = @as(c_int, 32);
pub const _POSIX_TIMER_MAX = @as(c_int, 32);
pub const _POSIX_CLOCKRES_MIN = @import("std").zig.c_translation.promoteIntLiteral(c_int, 20000000, .decimal);
pub const _POSIX_THREAD_DESTRUCTOR_ITERATIONS = @as(c_int, 4);
pub const _POSIX_THREAD_KEYS_MAX = @as(c_int, 128);
pub const _POSIX_THREAD_THREADS_MAX = @as(c_int, 64);
pub const PTHREAD_DESTRUCTOR_ITERATIONS = @as(c_int, 4);
pub const PTHREAD_KEYS_MAX = @as(c_int, 512);
pub const PTHREAD_STACK_MIN = @as(c_int, 16384);
pub const _POSIX_HOST_NAME_MAX = @as(c_int, 255);
pub const _POSIX_LOGIN_NAME_MAX = @as(c_int, 9);
pub const _POSIX_SS_REPL_MAX = @as(c_int, 4);
pub const _POSIX_SYMLINK_MAX = @as(c_int, 255);
pub const _POSIX_SYMLOOP_MAX = @as(c_int, 8);
pub const _POSIX_TRACE_EVENT_NAME_MAX = @as(c_int, 30);
pub const _POSIX_TRACE_NAME_MAX = @as(c_int, 8);
pub const _POSIX_TRACE_SYS_MAX = @as(c_int, 8);
pub const _POSIX_TRACE_USER_EVENT_MAX = @as(c_int, 32);
pub const _POSIX_TTY_NAME_MAX = @as(c_int, 9);
pub const _POSIX2_CHARCLASS_NAME_MAX = @as(c_int, 14);
pub const _POSIX2_COLL_WEIGHTS_MAX = @as(c_int, 2);
pub const _POSIX_RE_DUP_MAX = _POSIX2_RE_DUP_MAX;
pub const OFF_MIN = LLONG_MIN;
pub const OFF_MAX = LLONG_MAX;
pub const PASS_MAX = @as(c_int, 128);
pub const NL_ARGMAX = @as(c_int, 9);
pub const NL_LANGMAX = @as(c_int, 14);
pub const NL_MSGMAX = @as(c_int, 32767);
pub const NL_NMAX = @as(c_int, 1);
pub const NL_SETMAX = @as(c_int, 255);
pub const NL_TEXTMAX = @as(c_int, 2048);
pub const _XOPEN_IOV_MAX = @as(c_int, 16);
pub const IOV_MAX = @as(c_int, 1024);
pub const _XOPEN_NAME_MAX = @as(c_int, 255);
pub const _XOPEN_PATH_MAX = @as(c_int, 1024);
pub const LONG_LONG_MAX = __LONG_LONG_MAX__;
pub const LONG_LONG_MIN = -__LONG_LONG_MAX__ - @as(c_longlong, 1);
pub const ULONG_LONG_MAX = (__LONG_LONG_MAX__ * @as(c_ulonglong, 2)) + @as(c_ulonglong, 1);
pub const FT_CHAR_BIT = CHAR_BIT;
pub const FT_USHORT_MAX = USHRT_MAX;
pub const FT_INT_MAX = INT_MAX;
pub const FT_INT_MIN = INT_MIN;
pub const FT_UINT_MAX = UINT_MAX;
pub const FT_LONG_MIN = LONG_MIN;
pub const FT_LONG_MAX = LONG_MAX;
pub const FT_ULONG_MAX = ULONG_MAX;
pub const FT_LLONG_MAX = LLONG_MAX;
pub const FT_LLONG_MIN = LLONG_MIN;
pub const FT_ULLONG_MAX = ULLONG_MAX;
pub const _LIBCPP_STRING_H = "";
pub const _STRING_H_ = "";
pub const __TYPES_H_ = "";
pub const __DARWIN_WCHAR_MAX = __WCHAR_MAX__;
pub const __DARWIN_WCHAR_MIN = -@import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hexadecimal) - @as(c_int, 1);
pub const __DARWIN_WEOF = @import("std").zig.c_translation.cast(__darwin_wint_t, -@as(c_int, 1));
pub const _FORTIFY_SOURCE = @as(c_int, 2);
pub const __AVAILABILITY__ = "";
pub const __API_TO_BE_DEPRECATED = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100000, .decimal);
pub const __AVAILABILITY_VERSIONS__ = "";
pub const __MAC_10_0 = @as(c_int, 1000);
pub const __MAC_10_1 = @as(c_int, 1010);
pub const __MAC_10_2 = @as(c_int, 1020);
pub const __MAC_10_3 = @as(c_int, 1030);
pub const __MAC_10_4 = @as(c_int, 1040);
pub const __MAC_10_5 = @as(c_int, 1050);
pub const __MAC_10_6 = @as(c_int, 1060);
pub const __MAC_10_7 = @as(c_int, 1070);
pub const __MAC_10_8 = @as(c_int, 1080);
pub const __MAC_10_9 = @as(c_int, 1090);
pub const __MAC_10_10 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101000, .decimal);
pub const __MAC_10_10_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101002, .decimal);
pub const __MAC_10_10_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101003, .decimal);
pub const __MAC_10_11 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101100, .decimal);
pub const __MAC_10_11_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101102, .decimal);
pub const __MAC_10_11_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101103, .decimal);
pub const __MAC_10_11_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101104, .decimal);
pub const __MAC_10_12 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101200, .decimal);
pub const __MAC_10_12_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101201, .decimal);
pub const __MAC_10_12_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101202, .decimal);
pub const __MAC_10_12_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101204, .decimal);
pub const __MAC_10_13 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101300, .decimal);
pub const __MAC_10_13_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101301, .decimal);
pub const __MAC_10_13_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101302, .decimal);
pub const __MAC_10_13_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101304, .decimal);
pub const __MAC_10_14 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101400, .decimal);
pub const __MAC_10_14_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101401, .decimal);
pub const __MAC_10_14_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101404, .decimal);
pub const __MAC_10_14_6 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101406, .decimal);
pub const __MAC_10_15 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101500, .decimal);
pub const __MAC_10_15_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101501, .decimal);
pub const __MAC_10_15_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101504, .decimal);
pub const __MAC_10_16 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101600, .decimal);
pub const __MAC_11_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110000, .decimal);
pub const __MAC_11_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110100, .decimal);
pub const __MAC_11_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110300, .decimal);
pub const __MAC_11_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110400, .decimal);
pub const __MAC_11_5 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110500, .decimal);
pub const __MAC_11_6 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110600, .decimal);
pub const __MAC_12_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120000, .decimal);
pub const __MAC_12_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120100, .decimal);
pub const __MAC_12_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120200, .decimal);
pub const __MAC_12_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120300, .decimal);
pub const __IPHONE_2_0 = @as(c_int, 20000);
pub const __IPHONE_2_1 = @as(c_int, 20100);
pub const __IPHONE_2_2 = @as(c_int, 20200);
pub const __IPHONE_3_0 = @as(c_int, 30000);
pub const __IPHONE_3_1 = @as(c_int, 30100);
pub const __IPHONE_3_2 = @as(c_int, 30200);
pub const __IPHONE_4_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 40000, .decimal);
pub const __IPHONE_4_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 40100, .decimal);
pub const __IPHONE_4_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 40200, .decimal);
pub const __IPHONE_4_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 40300, .decimal);
pub const __IPHONE_5_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 50000, .decimal);
pub const __IPHONE_5_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 50100, .decimal);
pub const __IPHONE_6_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 60000, .decimal);
pub const __IPHONE_6_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 60100, .decimal);
pub const __IPHONE_7_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70000, .decimal);
pub const __IPHONE_7_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70100, .decimal);
pub const __IPHONE_8_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80000, .decimal);
pub const __IPHONE_8_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80100, .decimal);
pub const __IPHONE_8_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80200, .decimal);
pub const __IPHONE_8_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80300, .decimal);
pub const __IPHONE_8_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80400, .decimal);
pub const __IPHONE_9_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 90000, .decimal);
pub const __IPHONE_9_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 90100, .decimal);
pub const __IPHONE_9_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 90200, .decimal);
pub const __IPHONE_9_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 90300, .decimal);
pub const __IPHONE_10_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100000, .decimal);
pub const __IPHONE_10_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100100, .decimal);
pub const __IPHONE_10_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100200, .decimal);
pub const __IPHONE_10_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100300, .decimal);
pub const __IPHONE_11_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110000, .decimal);
pub const __IPHONE_11_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110100, .decimal);
pub const __IPHONE_11_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110200, .decimal);
pub const __IPHONE_11_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110300, .decimal);
pub const __IPHONE_11_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110400, .decimal);
pub const __IPHONE_12_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120000, .decimal);
pub const __IPHONE_12_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120100, .decimal);
pub const __IPHONE_12_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120200, .decimal);
pub const __IPHONE_12_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120300, .decimal);
pub const __IPHONE_12_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120400, .decimal);
pub const __IPHONE_13_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130000, .decimal);
pub const __IPHONE_13_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130100, .decimal);
pub const __IPHONE_13_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130200, .decimal);
pub const __IPHONE_13_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130300, .decimal);
pub const __IPHONE_13_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130400, .decimal);
pub const __IPHONE_13_5 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130500, .decimal);
pub const __IPHONE_13_6 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130600, .decimal);
pub const __IPHONE_13_7 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130700, .decimal);
pub const __IPHONE_14_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140000, .decimal);
pub const __IPHONE_14_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140100, .decimal);
pub const __IPHONE_14_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140200, .decimal);
pub const __IPHONE_14_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140300, .decimal);
pub const __IPHONE_14_5 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140500, .decimal);
pub const __IPHONE_14_6 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140600, .decimal);
pub const __IPHONE_14_7 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140700, .decimal);
pub const __IPHONE_14_8 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140800, .decimal);
pub const __IPHONE_15_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150000, .decimal);
pub const __IPHONE_15_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150100, .decimal);
pub const __IPHONE_15_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150200, .decimal);
pub const __IPHONE_15_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150300, .decimal);
pub const __IPHONE_15_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150400, .decimal);
pub const __TVOS_9_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 90000, .decimal);
pub const __TVOS_9_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 90100, .decimal);
pub const __TVOS_9_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 90200, .decimal);
pub const __TVOS_10_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100000, .decimal);
pub const __TVOS_10_0_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100001, .decimal);
pub const __TVOS_10_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100100, .decimal);
pub const __TVOS_10_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 100200, .decimal);
pub const __TVOS_11_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110000, .decimal);
pub const __TVOS_11_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110100, .decimal);
pub const __TVOS_11_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110200, .decimal);
pub const __TVOS_11_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110300, .decimal);
pub const __TVOS_11_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110400, .decimal);
pub const __TVOS_12_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120000, .decimal);
pub const __TVOS_12_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120100, .decimal);
pub const __TVOS_12_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120200, .decimal);
pub const __TVOS_12_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120300, .decimal);
pub const __TVOS_12_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120400, .decimal);
pub const __TVOS_13_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130000, .decimal);
pub const __TVOS_13_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130200, .decimal);
pub const __TVOS_13_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130300, .decimal);
pub const __TVOS_13_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 130400, .decimal);
pub const __TVOS_14_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140000, .decimal);
pub const __TVOS_14_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140100, .decimal);
pub const __TVOS_14_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140200, .decimal);
pub const __TVOS_14_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140300, .decimal);
pub const __TVOS_14_5 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140500, .decimal);
pub const __TVOS_14_6 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140600, .decimal);
pub const __TVOS_14_7 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 140700, .decimal);
pub const __TVOS_15_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150000, .decimal);
pub const __TVOS_15_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150100, .decimal);
pub const __TVOS_15_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150200, .decimal);
pub const __TVOS_15_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150300, .decimal);
pub const __TVOS_15_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 150400, .decimal);
pub const __WATCHOS_1_0 = @as(c_int, 10000);
pub const __WATCHOS_2_0 = @as(c_int, 20000);
pub const __WATCHOS_2_1 = @as(c_int, 20100);
pub const __WATCHOS_2_2 = @as(c_int, 20200);
pub const __WATCHOS_3_0 = @as(c_int, 30000);
pub const __WATCHOS_3_1 = @as(c_int, 30100);
pub const __WATCHOS_3_1_1 = @as(c_int, 30101);
pub const __WATCHOS_3_2 = @as(c_int, 30200);
pub const __WATCHOS_4_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 40000, .decimal);
pub const __WATCHOS_4_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 40100, .decimal);
pub const __WATCHOS_4_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 40200, .decimal);
pub const __WATCHOS_4_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 40300, .decimal);
pub const __WATCHOS_5_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 50000, .decimal);
pub const __WATCHOS_5_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 50100, .decimal);
pub const __WATCHOS_5_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 50200, .decimal);
pub const __WATCHOS_5_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 50300, .decimal);
pub const __WATCHOS_6_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 60000, .decimal);
pub const __WATCHOS_6_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 60100, .decimal);
pub const __WATCHOS_6_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 60200, .decimal);
pub const __WATCHOS_7_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70000, .decimal);
pub const __WATCHOS_7_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70100, .decimal);
pub const __WATCHOS_7_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70200, .decimal);
pub const __WATCHOS_7_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70300, .decimal);
pub const __WATCHOS_7_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70400, .decimal);
pub const __WATCHOS_7_5 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70500, .decimal);
pub const __WATCHOS_7_6 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 70600, .decimal);
pub const __WATCHOS_8_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80000, .decimal);
pub const __WATCHOS_8_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80100, .decimal);
pub const __WATCHOS_8_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80300, .decimal);
pub const __WATCHOS_8_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80400, .decimal);
pub const __WATCHOS_8_5 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 80500, .decimal);
pub const MAC_OS_X_VERSION_10_0 = @as(c_int, 1000);
pub const MAC_OS_X_VERSION_10_1 = @as(c_int, 1010);
pub const MAC_OS_X_VERSION_10_2 = @as(c_int, 1020);
pub const MAC_OS_X_VERSION_10_3 = @as(c_int, 1030);
pub const MAC_OS_X_VERSION_10_4 = @as(c_int, 1040);
pub const MAC_OS_X_VERSION_10_5 = @as(c_int, 1050);
pub const MAC_OS_X_VERSION_10_6 = @as(c_int, 1060);
pub const MAC_OS_X_VERSION_10_7 = @as(c_int, 1070);
pub const MAC_OS_X_VERSION_10_8 = @as(c_int, 1080);
pub const MAC_OS_X_VERSION_10_9 = @as(c_int, 1090);
pub const MAC_OS_X_VERSION_10_10 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101000, .decimal);
pub const MAC_OS_X_VERSION_10_10_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101002, .decimal);
pub const MAC_OS_X_VERSION_10_10_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101003, .decimal);
pub const MAC_OS_X_VERSION_10_11 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101100, .decimal);
pub const MAC_OS_X_VERSION_10_11_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101102, .decimal);
pub const MAC_OS_X_VERSION_10_11_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101103, .decimal);
pub const MAC_OS_X_VERSION_10_11_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101104, .decimal);
pub const MAC_OS_X_VERSION_10_12 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101200, .decimal);
pub const MAC_OS_X_VERSION_10_12_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101201, .decimal);
pub const MAC_OS_X_VERSION_10_12_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101202, .decimal);
pub const MAC_OS_X_VERSION_10_12_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101204, .decimal);
pub const MAC_OS_X_VERSION_10_13 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101300, .decimal);
pub const MAC_OS_X_VERSION_10_13_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101301, .decimal);
pub const MAC_OS_X_VERSION_10_13_2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101302, .decimal);
pub const MAC_OS_X_VERSION_10_13_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101304, .decimal);
pub const MAC_OS_X_VERSION_10_14 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101400, .decimal);
pub const MAC_OS_X_VERSION_10_14_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101401, .decimal);
pub const MAC_OS_X_VERSION_10_14_4 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101404, .decimal);
pub const MAC_OS_X_VERSION_10_14_6 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101406, .decimal);
pub const MAC_OS_X_VERSION_10_15 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101500, .decimal);
pub const MAC_OS_X_VERSION_10_15_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101501, .decimal);
pub const MAC_OS_X_VERSION_10_16 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 101600, .decimal);
pub const MAC_OS_VERSION_11_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110000, .decimal);
pub const MAC_OS_VERSION_12_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 120000, .decimal);
pub const __DRIVERKIT_19_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 190000, .decimal);
pub const __DRIVERKIT_20_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 200000, .decimal);
pub const __DRIVERKIT_21_0 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 210000, .decimal);
pub const __AVAILABILITY_INTERNAL__ = "";
pub const __MAC_OS_X_VERSION_MIN_REQUIRED = __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__;
pub const __MAC_OS_X_VERSION_MAX_ALLOWED = __MAC_12_3;
pub const __AVAILABILITY_INTERNAL_REGULAR = "";
pub const __ENABLE_LEGACY_MAC_AVAILABILITY = @as(c_int, 1);
pub inline fn __API_AVAILABLE1(x: anytype) @TypeOf(__API_A(x)) {
    return __API_A(x);
}
pub inline fn __API_RANGE_STRINGIFY(x: anytype) @TypeOf(__API_RANGE_STRINGIFY2(x)) {
    return __API_RANGE_STRINGIFY2(x);
}
pub inline fn __API_AVAILABLE_BEGIN1(a: anytype) @TypeOf(__API_A_BEGIN(a)) {
    return __API_A_BEGIN(a);
}
pub inline fn __API_DEPRECATED_MSG2(msg: anytype, x: anytype) @TypeOf(__API_D(msg, x)) {
    return __API_D(msg, x);
}
pub inline fn __API_DEPRECATED_BEGIN_MSG2(msg: anytype, a: anytype) @TypeOf(__API_D_BEGIN(msg, a)) {
    return __API_D_BEGIN(msg, a);
}
pub inline fn __API_DEPRECATED_REP2(rep: anytype, x: anytype) @TypeOf(__API_R(rep, x)) {
    return __API_R(rep, x);
}
pub inline fn __API_DEPRECATED_BEGIN_REP2(rep: anytype, a: anytype) @TypeOf(__API_R_BEGIN(rep, a)) {
    return __API_R_BEGIN(rep, a);
}
pub inline fn __API_UNAVAILABLE1(x: anytype) @TypeOf(__API_U(x)) {
    return __API_U(x);
}
pub inline fn __API_UNAVAILABLE_BEGIN1(a: anytype) @TypeOf(__API_U_BEGIN(a)) {
    return __API_U_BEGIN(a);
}
pub const _ERRNO_T = "";
pub const _SSIZE_T = "";
pub const _STRINGS_H_ = "";
pub const _SECURE__STRINGS_H_ = "";
pub const _SECURE__COMMON_H_ = "";
pub const _USE_FORTIFY_LEVEL = @as(c_int, 2);
pub inline fn __darwin_obsz0(object: anytype) @TypeOf(__builtin_object_size(object, @as(c_int, 0))) {
    return __builtin_object_size(object, @as(c_int, 0));
}
pub inline fn __darwin_obsz(object: anytype) @TypeOf(__builtin_object_size(object, if (_USE_FORTIFY_LEVEL > @as(c_int, 1)) @as(c_int, 1) else @as(c_int, 0))) {
    return __builtin_object_size(object, if (_USE_FORTIFY_LEVEL > @as(c_int, 1)) @as(c_int, 1) else @as(c_int, 0));
}
pub const _SECURE__STRING_H_ = "";
pub const __HAS_FIXED_CHK_PROTOTYPES = @as(c_int, 1);
pub const ft_memchr = memchr;
pub const ft_memcmp = memcmp;
pub const ft_memcpy = memcpy;
pub const ft_memmove = memmove;
pub const ft_memset = memset;
pub const ft_strcat = strcat;
pub const ft_strcmp = strcmp;
pub const ft_strcpy = strcpy;
pub const ft_strlen = strlen;
pub const ft_strncmp = strncmp;
pub const ft_strncpy = strncpy;
pub const ft_strrchr = strrchr;
pub const ft_strstr = strstr;
pub const _LIBCPP_STDIO_H = "";
pub const _STDIO_H_ = "";
pub const __STDIO_H_ = "";
pub const _VA_LIST_T = "";
pub const _SYS_STDIO_H_ = "";
pub const RENAME_SECLUDE = @as(c_int, 0x00000001);
pub const RENAME_SWAP = @as(c_int, 0x00000002);
pub const RENAME_EXCL = @as(c_int, 0x00000004);
pub const RENAME_RESERVED1 = @as(c_int, 0x00000008);
pub const RENAME_NOFOLLOW_ANY = @as(c_int, 0x00000010);
pub const _FSTDIO = "";
pub const __SLBF = @as(c_int, 0x0001);
pub const __SNBF = @as(c_int, 0x0002);
pub const __SRD = @as(c_int, 0x0004);
pub const __SWR = @as(c_int, 0x0008);
pub const __SRW = @as(c_int, 0x0010);
pub const __SEOF = @as(c_int, 0x0020);
pub const __SERR = @as(c_int, 0x0040);
pub const __SMBF = @as(c_int, 0x0080);
pub const __SAPP = @as(c_int, 0x0100);
pub const __SSTR = @as(c_int, 0x0200);
pub const __SOPT = @as(c_int, 0x0400);
pub const __SNPT = @as(c_int, 0x0800);
pub const __SOFF = @as(c_int, 0x1000);
pub const __SMOD = @as(c_int, 0x2000);
pub const __SALC = @as(c_int, 0x4000);
pub const __SIGN = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000, .hexadecimal);
pub const _IOFBF = @as(c_int, 0);
pub const _IOLBF = @as(c_int, 1);
pub const _IONBF = @as(c_int, 2);
pub const BUFSIZ = @as(c_int, 1024);
pub const EOF = -@as(c_int, 1);
pub const FOPEN_MAX = @as(c_int, 20);
pub const FILENAME_MAX = @as(c_int, 1024);
pub const P_tmpdir = "/var/tmp/";
pub const L_tmpnam = @as(c_int, 1024);
pub const TMP_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 308915776, .decimal);
pub const SEEK_SET = @as(c_int, 0);
pub const SEEK_CUR = @as(c_int, 1);
pub const SEEK_END = @as(c_int, 2);
pub const stdin = __stdinp;
pub const stdout = __stdoutp;
pub const stderr = __stderrp;
pub const L_ctermid = @as(c_int, 1024);
pub const _CTERMID_H_ = "";
pub inline fn __sfeof(p: anytype) @TypeOf((p.*._flags & __SEOF) != @as(c_int, 0)) {
    return (p.*._flags & __SEOF) != @as(c_int, 0);
}
pub inline fn __sferror(p: anytype) @TypeOf((p.*._flags & __SERR) != @as(c_int, 0)) {
    return (p.*._flags & __SERR) != @as(c_int, 0);
}
pub inline fn __sfileno(p: anytype) @TypeOf(p.*._file) {
    return p.*._file;
}
pub const _OFF_T = "";
pub inline fn fropen(cookie: anytype, @"fn": anytype) @TypeOf(funopen(cookie, @"fn", @as(c_int, 0), @as(c_int, 0), @as(c_int, 0))) {
    return funopen(cookie, @"fn", @as(c_int, 0), @as(c_int, 0), @as(c_int, 0));
}
pub inline fn fwopen(cookie: anytype, @"fn": anytype) @TypeOf(funopen(cookie, @as(c_int, 0), @"fn", @as(c_int, 0), @as(c_int, 0))) {
    return funopen(cookie, @as(c_int, 0), @"fn", @as(c_int, 0), @as(c_int, 0));
}
pub inline fn feof_unlocked(p: anytype) @TypeOf(__sfeof(p)) {
    return __sfeof(p);
}
pub inline fn ferror_unlocked(p: anytype) @TypeOf(__sferror(p)) {
    return __sferror(p);
}
pub inline fn clearerr_unlocked(p: anytype) @TypeOf(__sclearerr(p)) {
    return __sclearerr(p);
}
pub inline fn fileno_unlocked(p: anytype) @TypeOf(__sfileno(p)) {
    return __sfileno(p);
}
pub const _SECURE__STDIO_H_ = "";
pub const FT_FILE = FILE;
pub const ft_fclose = fclose;
pub const ft_fopen = fopen;
pub const ft_fread = fread;
pub const ft_fseek = fseek;
pub const ft_ftell = ftell;
pub const ft_sprintf = sprintf;
pub const _LIBCPP_STDLIB_H = "";
pub const _STDLIB_H_ = "";
pub const _SYS_WAIT_H_ = "";
pub const _PID_T = "";
pub const _ID_T = "";
pub const _SYS_SIGNAL_H_ = "";
pub const __SYS_APPLEAPIOPTS_H__ = "";
pub const __APPLE_API_STANDARD = "";
pub const __APPLE_API_STABLE = "";
pub const __APPLE_API_EVOLVING = "";
pub const __APPLE_API_UNSTABLE = "";
pub const __APPLE_API_PRIVATE = "";
pub const __APPLE_API_OBSOLETE = "";
pub const __DARWIN_NSIG = @as(c_int, 32);
pub const NSIG = __DARWIN_NSIG;
pub const _BSD_MACHINE_SIGNAL_H_ = "";
pub const _ARM_SIGNAL_ = @as(c_int, 1);
pub const SIGHUP = @as(c_int, 1);
pub const SIGINT = @as(c_int, 2);
pub const SIGQUIT = @as(c_int, 3);
pub const SIGILL = @as(c_int, 4);
pub const SIGTRAP = @as(c_int, 5);
pub const SIGABRT = @as(c_int, 6);
pub const SIGIOT = SIGABRT;
pub const SIGEMT = @as(c_int, 7);
pub const SIGFPE = @as(c_int, 8);
pub const SIGKILL = @as(c_int, 9);
pub const SIGBUS = @as(c_int, 10);
pub const SIGSEGV = @as(c_int, 11);
pub const SIGSYS = @as(c_int, 12);
pub const SIGPIPE = @as(c_int, 13);
pub const SIGALRM = @as(c_int, 14);
pub const SIGTERM = @as(c_int, 15);
pub const SIGURG = @as(c_int, 16);
pub const SIGSTOP = @as(c_int, 17);
pub const SIGTSTP = @as(c_int, 18);
pub const SIGCONT = @as(c_int, 19);
pub const SIGCHLD = @as(c_int, 20);
pub const SIGTTIN = @as(c_int, 21);
pub const SIGTTOU = @as(c_int, 22);
pub const SIGIO = @as(c_int, 23);
pub const SIGXCPU = @as(c_int, 24);
pub const SIGXFSZ = @as(c_int, 25);
pub const SIGVTALRM = @as(c_int, 26);
pub const SIGPROF = @as(c_int, 27);
pub const SIGWINCH = @as(c_int, 28);
pub const SIGINFO = @as(c_int, 29);
pub const SIGUSR1 = @as(c_int, 30);
pub const SIGUSR2 = @as(c_int, 31);
pub const _BSD_MACHINE__MCONTEXT_H_ = "";
pub const __ARM_MCONTEXT_H_ = "";
pub const _MACH_MACHINE__STRUCTS_H_ = "";
pub const _MACH_ARM__STRUCTS_H_ = "";
pub const _STRUCT_ARM_EXCEPTION_STATE = struct___darwin_arm_exception_state;
pub const _STRUCT_ARM_EXCEPTION_STATE64 = struct___darwin_arm_exception_state64;
pub const _STRUCT_ARM_THREAD_STATE = struct___darwin_arm_thread_state;
pub const __DARWIN_OPAQUE_ARM_THREAD_STATE64 = @as(c_int, 0);
pub const _STRUCT_ARM_THREAD_STATE64 = struct___darwin_arm_thread_state64;
pub inline fn __darwin_arm_thread_state64_get_pc(ts: anytype) @TypeOf(ts.__pc) {
    return ts.__pc;
}
pub inline fn __darwin_arm_thread_state64_get_pc_fptr(ts: anytype) ?*anyopaque {
    return @import("std").zig.c_translation.cast(?*anyopaque, @import("std").zig.c_translation.cast(usize, ts.__pc));
}
pub inline fn __darwin_arm_thread_state64_get_lr(ts: anytype) @TypeOf(ts.__lr) {
    return ts.__lr;
}
pub inline fn __darwin_arm_thread_state64_get_lr_fptr(ts: anytype) ?*anyopaque {
    return @import("std").zig.c_translation.cast(?*anyopaque, @import("std").zig.c_translation.cast(usize, ts.__lr));
}
pub inline fn __darwin_arm_thread_state64_get_sp(ts: anytype) @TypeOf(ts.__sp) {
    return ts.__sp;
}
pub inline fn __darwin_arm_thread_state64_get_fp(ts: anytype) @TypeOf(ts.__fp) {
    return ts.__fp;
}
pub const __darwin_arm_thread_state64_ptrauth_strip = @import("std").zig.c_translation.Macros.DISCARD;
pub const _STRUCT_ARM_VFP_STATE = struct___darwin_arm_vfp_state;
pub const _STRUCT_ARM_NEON_STATE64 = struct___darwin_arm_neon_state64;
pub const _STRUCT_ARM_NEON_STATE = struct___darwin_arm_neon_state;
pub const _STRUCT_ARM_PAGEIN_STATE = struct___arm_pagein_state;
pub const _STRUCT_ARM_LEGACY_DEBUG_STATE = struct___arm_legacy_debug_state;
pub const _STRUCT_ARM_DEBUG_STATE32 = struct___darwin_arm_debug_state32;
pub const _STRUCT_ARM_DEBUG_STATE64 = struct___darwin_arm_debug_state64;
pub const _STRUCT_ARM_CPMU_STATE64 = struct___darwin_arm_cpmu_state64;
pub const _STRUCT_MCONTEXT32 = struct___darwin_mcontext32;
pub const _STRUCT_MCONTEXT64 = struct___darwin_mcontext64;
pub const _MCONTEXT_T = "";
pub const _STRUCT_MCONTEXT = _STRUCT_MCONTEXT64;
pub const _PTHREAD_ATTR_T = "";
pub const _STRUCT_SIGALTSTACK = struct___darwin_sigaltstack;
pub const _STRUCT_UCONTEXT = struct___darwin_ucontext;
pub const _SIGSET_T = "";
pub const _UID_T = "";
pub const SIGEV_NONE = @as(c_int, 0);
pub const SIGEV_SIGNAL = @as(c_int, 1);
pub const SIGEV_THREAD = @as(c_int, 3);
pub const ILL_NOOP = @as(c_int, 0);
pub const ILL_ILLOPC = @as(c_int, 1);
pub const ILL_ILLTRP = @as(c_int, 2);
pub const ILL_PRVOPC = @as(c_int, 3);
pub const ILL_ILLOPN = @as(c_int, 4);
pub const ILL_ILLADR = @as(c_int, 5);
pub const ILL_PRVREG = @as(c_int, 6);
pub const ILL_COPROC = @as(c_int, 7);
pub const ILL_BADSTK = @as(c_int, 8);
pub const FPE_NOOP = @as(c_int, 0);
pub const FPE_FLTDIV = @as(c_int, 1);
pub const FPE_FLTOVF = @as(c_int, 2);
pub const FPE_FLTUND = @as(c_int, 3);
pub const FPE_FLTRES = @as(c_int, 4);
pub const FPE_FLTINV = @as(c_int, 5);
pub const FPE_FLTSUB = @as(c_int, 6);
pub const FPE_INTDIV = @as(c_int, 7);
pub const FPE_INTOVF = @as(c_int, 8);
pub const SEGV_NOOP = @as(c_int, 0);
pub const SEGV_MAPERR = @as(c_int, 1);
pub const SEGV_ACCERR = @as(c_int, 2);
pub const BUS_NOOP = @as(c_int, 0);
pub const BUS_ADRALN = @as(c_int, 1);
pub const BUS_ADRERR = @as(c_int, 2);
pub const BUS_OBJERR = @as(c_int, 3);
pub const TRAP_BRKPT = @as(c_int, 1);
pub const TRAP_TRACE = @as(c_int, 2);
pub const CLD_NOOP = @as(c_int, 0);
pub const CLD_EXITED = @as(c_int, 1);
pub const CLD_KILLED = @as(c_int, 2);
pub const CLD_DUMPED = @as(c_int, 3);
pub const CLD_TRAPPED = @as(c_int, 4);
pub const CLD_STOPPED = @as(c_int, 5);
pub const CLD_CONTINUED = @as(c_int, 6);
pub const POLL_IN = @as(c_int, 1);
pub const POLL_OUT = @as(c_int, 2);
pub const POLL_MSG = @as(c_int, 3);
pub const POLL_ERR = @as(c_int, 4);
pub const POLL_PRI = @as(c_int, 5);
pub const POLL_HUP = @as(c_int, 6);
pub const sa_handler = __sigaction_u.__sa_handler;
pub const sa_sigaction = __sigaction_u.__sa_sigaction;
pub const SA_ONSTACK = @as(c_int, 0x0001);
pub const SA_RESTART = @as(c_int, 0x0002);
pub const SA_RESETHAND = @as(c_int, 0x0004);
pub const SA_NOCLDSTOP = @as(c_int, 0x0008);
pub const SA_NODEFER = @as(c_int, 0x0010);
pub const SA_NOCLDWAIT = @as(c_int, 0x0020);
pub const SA_SIGINFO = @as(c_int, 0x0040);
pub const SA_USERTRAMP = @as(c_int, 0x0100);
pub const SA_64REGSET = @as(c_int, 0x0200);
pub const SA_USERSPACE_MASK = (((((SA_ONSTACK | SA_RESTART) | SA_RESETHAND) | SA_NOCLDSTOP) | SA_NODEFER) | SA_NOCLDWAIT) | SA_SIGINFO;
pub const SIG_BLOCK = @as(c_int, 1);
pub const SIG_UNBLOCK = @as(c_int, 2);
pub const SIG_SETMASK = @as(c_int, 3);
pub const SI_USER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x10001, .hexadecimal);
pub const SI_QUEUE = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x10002, .hexadecimal);
pub const SI_TIMER = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x10003, .hexadecimal);
pub const SI_ASYNCIO = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x10004, .hexadecimal);
pub const SI_MESGQ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x10005, .hexadecimal);
pub const SS_ONSTACK = @as(c_int, 0x0001);
pub const SS_DISABLE = @as(c_int, 0x0004);
pub const MINSIGSTKSZ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 32768, .decimal);
pub const SIGSTKSZ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 131072, .decimal);
pub const SV_ONSTACK = SA_ONSTACK;
pub const SV_INTERRUPT = SA_RESTART;
pub const SV_RESETHAND = SA_RESETHAND;
pub const SV_NODEFER = SA_NODEFER;
pub const SV_NOCLDSTOP = SA_NOCLDSTOP;
pub const SV_SIGINFO = SA_SIGINFO;
pub inline fn sigmask(m: anytype) @TypeOf(@as(c_int, 1) << (m - @as(c_int, 1))) {
    return @as(c_int, 1) << (m - @as(c_int, 1));
}
pub const BADSIG = SIG_ERR;
pub const _SYS_RESOURCE_H_ = "";
pub const _STRUCT_TIMEVAL = struct_timeval;
pub const PRIO_PROCESS = @as(c_int, 0);
pub const PRIO_PGRP = @as(c_int, 1);
pub const PRIO_USER = @as(c_int, 2);
pub const PRIO_DARWIN_THREAD = @as(c_int, 3);
pub const PRIO_DARWIN_PROCESS = @as(c_int, 4);
pub const PRIO_MIN = -@as(c_int, 20);
pub const PRIO_MAX = @as(c_int, 20);
pub const PRIO_DARWIN_BG = @as(c_int, 0x1000);
pub const PRIO_DARWIN_NONUI = @as(c_int, 0x1001);
pub const RUSAGE_SELF = @as(c_int, 0);
pub const RUSAGE_CHILDREN = -@as(c_int, 1);
pub const RUSAGE_INFO_V0 = @as(c_int, 0);
pub const RUSAGE_INFO_V1 = @as(c_int, 1);
pub const RUSAGE_INFO_V2 = @as(c_int, 2);
pub const RUSAGE_INFO_V3 = @as(c_int, 3);
pub const RUSAGE_INFO_V4 = @as(c_int, 4);
pub const RUSAGE_INFO_V5 = @as(c_int, 5);
pub const RUSAGE_INFO_CURRENT = RUSAGE_INFO_V5;
pub const RU_PROC_RUNS_RESLIDE = @as(c_int, 0x00000001);
pub const RLIM_INFINITY = (@import("std").zig.c_translation.cast(__uint64_t, @as(c_int, 1)) << @as(c_int, 63)) - @as(c_int, 1);
pub const RLIM_SAVED_MAX = RLIM_INFINITY;
pub const RLIM_SAVED_CUR = RLIM_INFINITY;
pub const RLIMIT_CPU = @as(c_int, 0);
pub const RLIMIT_FSIZE = @as(c_int, 1);
pub const RLIMIT_DATA = @as(c_int, 2);
pub const RLIMIT_STACK = @as(c_int, 3);
pub const RLIMIT_CORE = @as(c_int, 4);
pub const RLIMIT_AS = @as(c_int, 5);
pub const RLIMIT_RSS = RLIMIT_AS;
pub const RLIMIT_MEMLOCK = @as(c_int, 6);
pub const RLIMIT_NPROC = @as(c_int, 7);
pub const RLIMIT_NOFILE = @as(c_int, 8);
pub const RLIM_NLIMITS = @as(c_int, 9);
pub const _RLIMIT_POSIX_FLAG = @as(c_int, 0x1000);
pub const RLIMIT_WAKEUPS_MONITOR = @as(c_int, 0x1);
pub const RLIMIT_CPU_USAGE_MONITOR = @as(c_int, 0x2);
pub const RLIMIT_THREAD_CPULIMITS = @as(c_int, 0x3);
pub const RLIMIT_FOOTPRINT_INTERVAL = @as(c_int, 0x4);
pub const WAKEMON_ENABLE = @as(c_int, 0x01);
pub const WAKEMON_DISABLE = @as(c_int, 0x02);
pub const WAKEMON_GET_PARAMS = @as(c_int, 0x04);
pub const WAKEMON_SET_DEFAULTS = @as(c_int, 0x08);
pub const WAKEMON_MAKE_FATAL = @as(c_int, 0x10);
pub const CPUMON_MAKE_FATAL = @as(c_int, 0x1000);
pub const FOOTPRINT_INTERVAL_RESET = @as(c_int, 0x1);
pub const IOPOL_TYPE_DISK = @as(c_int, 0);
pub const IOPOL_TYPE_VFS_ATIME_UPDATES = @as(c_int, 2);
pub const IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES = @as(c_int, 3);
pub const IOPOL_TYPE_VFS_STATFS_NO_DATA_VOLUME = @as(c_int, 4);
pub const IOPOL_TYPE_VFS_TRIGGER_RESOLVE = @as(c_int, 5);
pub const IOPOL_TYPE_VFS_IGNORE_CONTENT_PROTECTION = @as(c_int, 6);
pub const IOPOL_TYPE_VFS_IGNORE_PERMISSIONS = @as(c_int, 7);
pub const IOPOL_TYPE_VFS_SKIP_MTIME_UPDATE = @as(c_int, 8);
pub const IOPOL_TYPE_VFS_ALLOW_LOW_SPACE_WRITES = @as(c_int, 9);
pub const IOPOL_SCOPE_PROCESS = @as(c_int, 0);
pub const IOPOL_SCOPE_THREAD = @as(c_int, 1);
pub const IOPOL_SCOPE_DARWIN_BG = @as(c_int, 2);
pub const IOPOL_DEFAULT = @as(c_int, 0);
pub const IOPOL_IMPORTANT = @as(c_int, 1);
pub const IOPOL_PASSIVE = @as(c_int, 2);
pub const IOPOL_THROTTLE = @as(c_int, 3);
pub const IOPOL_UTILITY = @as(c_int, 4);
pub const IOPOL_STANDARD = @as(c_int, 5);
pub const IOPOL_APPLICATION = IOPOL_STANDARD;
pub const IOPOL_NORMAL = IOPOL_IMPORTANT;
pub const IOPOL_ATIME_UPDATES_DEFAULT = @as(c_int, 0);
pub const IOPOL_ATIME_UPDATES_OFF = @as(c_int, 1);
pub const IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT = @as(c_int, 0);
pub const IOPOL_MATERIALIZE_DATALESS_FILES_OFF = @as(c_int, 1);
pub const IOPOL_MATERIALIZE_DATALESS_FILES_ON = @as(c_int, 2);
pub const IOPOL_VFS_STATFS_NO_DATA_VOLUME_DEFAULT = @as(c_int, 0);
pub const IOPOL_VFS_STATFS_FORCE_NO_DATA_VOLUME = @as(c_int, 1);
pub const IOPOL_VFS_TRIGGER_RESOLVE_DEFAULT = @as(c_int, 0);
pub const IOPOL_VFS_TRIGGER_RESOLVE_OFF = @as(c_int, 1);
pub const IOPOL_VFS_CONTENT_PROTECTION_DEFAULT = @as(c_int, 0);
pub const IOPOL_VFS_CONTENT_PROTECTION_IGNORE = @as(c_int, 1);
pub const IOPOL_VFS_IGNORE_PERMISSIONS_OFF = @as(c_int, 0);
pub const IOPOL_VFS_IGNORE_PERMISSIONS_ON = @as(c_int, 1);
pub const IOPOL_VFS_SKIP_MTIME_UPDATE_OFF = @as(c_int, 0);
pub const IOPOL_VFS_SKIP_MTIME_UPDATE_ON = @as(c_int, 1);
pub const IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_OFF = @as(c_int, 0);
pub const IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_ON = @as(c_int, 1);
pub const WNOHANG = @as(c_int, 0x00000001);
pub const WUNTRACED = @as(c_int, 0x00000002);
pub inline fn _W_INT(w: anytype) @TypeOf(@import("std").zig.c_translation.cast([*c]c_int, &w).*) {
    return @import("std").zig.c_translation.cast([*c]c_int, &w).*;
}
pub const WCOREFLAG = @as(c_int, 0o200);
pub inline fn _WSTATUS(x: anytype) @TypeOf(_W_INT(x) & @as(c_int, 0o177)) {
    return _W_INT(x) & @as(c_int, 0o177);
}
pub const _WSTOPPED = @as(c_int, 0o177);
pub inline fn WEXITSTATUS(x: anytype) @TypeOf((_W_INT(x) >> @as(c_int, 8)) & @as(c_int, 0x000000ff)) {
    return (_W_INT(x) >> @as(c_int, 8)) & @as(c_int, 0x000000ff);
}
pub inline fn WSTOPSIG(x: anytype) @TypeOf(_W_INT(x) >> @as(c_int, 8)) {
    return _W_INT(x) >> @as(c_int, 8);
}
pub inline fn WIFCONTINUED(x: anytype) @TypeOf((_WSTATUS(x) == _WSTOPPED) and (WSTOPSIG(x) == @as(c_int, 0x13))) {
    return (_WSTATUS(x) == _WSTOPPED) and (WSTOPSIG(x) == @as(c_int, 0x13));
}
pub inline fn WIFSTOPPED(x: anytype) @TypeOf((_WSTATUS(x) == _WSTOPPED) and (WSTOPSIG(x) != @as(c_int, 0x13))) {
    return (_WSTATUS(x) == _WSTOPPED) and (WSTOPSIG(x) != @as(c_int, 0x13));
}
pub inline fn WIFEXITED(x: anytype) @TypeOf(_WSTATUS(x) == @as(c_int, 0)) {
    return _WSTATUS(x) == @as(c_int, 0);
}
pub inline fn WIFSIGNALED(x: anytype) @TypeOf((_WSTATUS(x) != _WSTOPPED) and (_WSTATUS(x) != @as(c_int, 0))) {
    return (_WSTATUS(x) != _WSTOPPED) and (_WSTATUS(x) != @as(c_int, 0));
}
pub inline fn WTERMSIG(x: anytype) @TypeOf(_WSTATUS(x)) {
    return _WSTATUS(x);
}
pub inline fn WCOREDUMP(x: anytype) @TypeOf(_W_INT(x) & WCOREFLAG) {
    return _W_INT(x) & WCOREFLAG;
}
pub inline fn W_EXITCODE(ret: anytype, sig: anytype) @TypeOf((ret << @as(c_int, 8)) | sig) {
    return (ret << @as(c_int, 8)) | sig;
}
pub inline fn W_STOPCODE(sig: anytype) @TypeOf((sig << @as(c_int, 8)) | _WSTOPPED) {
    return (sig << @as(c_int, 8)) | _WSTOPPED;
}
pub const WEXITED = @as(c_int, 0x00000004);
pub const WSTOPPED = @as(c_int, 0x00000008);
pub const WCONTINUED = @as(c_int, 0x00000010);
pub const WNOWAIT = @as(c_int, 0x00000020);
pub const WAIT_ANY = -@as(c_int, 1);
pub const WAIT_MYPGRP = @as(c_int, 0);
pub const _BSD_MACHINE_ENDIAN_H_ = "";
pub const _ARM__ENDIAN_H_ = "";
pub const _QUAD_HIGHWORD = @as(c_int, 1);
pub const _QUAD_LOWWORD = @as(c_int, 0);
pub const __DARWIN_LITTLE_ENDIAN = @as(c_int, 1234);
pub const __DARWIN_BIG_ENDIAN = @as(c_int, 4321);
pub const __DARWIN_PDP_ENDIAN = @as(c_int, 3412);
pub const __DARWIN_BYTE_ORDER = __DARWIN_LITTLE_ENDIAN;
pub const LITTLE_ENDIAN = __DARWIN_LITTLE_ENDIAN;
pub const BIG_ENDIAN = __DARWIN_BIG_ENDIAN;
pub const PDP_ENDIAN = __DARWIN_PDP_ENDIAN;
pub const BYTE_ORDER = __DARWIN_BYTE_ORDER;
pub const _SYS__ENDIAN_H_ = "";
pub const _OS__OSBYTEORDER_H = "";
pub inline fn __DARWIN_OSSwapConstInt16(x: anytype) __uint16_t {
    return @import("std").zig.c_translation.cast(__uint16_t, ((@import("std").zig.c_translation.cast(__uint16_t, x) & @as(c_uint, 0xff00)) >> @as(c_int, 8)) | ((@import("std").zig.c_translation.cast(__uint16_t, x) & @as(c_uint, 0x00ff)) << @as(c_int, 8)));
}
pub inline fn __DARWIN_OSSwapConstInt32(x: anytype) __uint32_t {
    return @import("std").zig.c_translation.cast(__uint32_t, ((((@import("std").zig.c_translation.cast(__uint32_t, x) & @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0xff000000, .hexadecimal)) >> @as(c_int, 24)) | ((@import("std").zig.c_translation.cast(__uint32_t, x) & @import("std").zig.c_translation.promoteIntLiteral(c_uint, 0x00ff0000, .hexadecimal)) >> @as(c_int, 8))) | ((@import("std").zig.c_translation.cast(__uint32_t, x) & @as(c_uint, 0x0000ff00)) << @as(c_int, 8))) | ((@import("std").zig.c_translation.cast(__uint32_t, x) & @as(c_uint, 0x000000ff)) << @as(c_int, 24)));
}
pub inline fn __DARWIN_OSSwapConstInt64(x: anytype) __uint64_t {
    return @import("std").zig.c_translation.cast(__uint64_t, ((((((((@import("std").zig.c_translation.cast(__uint64_t, x) & @as(c_ulonglong, 0xff00000000000000)) >> @as(c_int, 56)) | ((@import("std").zig.c_translation.cast(__uint64_t, x) & @as(c_ulonglong, 0x00ff000000000000)) >> @as(c_int, 40))) | ((@import("std").zig.c_translation.cast(__uint64_t, x) & @as(c_ulonglong, 0x0000ff0000000000)) >> @as(c_int, 24))) | ((@import("std").zig.c_translation.cast(__uint64_t, x) & @as(c_ulonglong, 0x000000ff00000000)) >> @as(c_int, 8))) | ((@import("std").zig.c_translation.cast(__uint64_t, x) & @as(c_ulonglong, 0x00000000ff000000)) << @as(c_int, 8))) | ((@import("std").zig.c_translation.cast(__uint64_t, x) & @as(c_ulonglong, 0x0000000000ff0000)) << @as(c_int, 24))) | ((@import("std").zig.c_translation.cast(__uint64_t, x) & @as(c_ulonglong, 0x000000000000ff00)) << @as(c_int, 40))) | ((@import("std").zig.c_translation.cast(__uint64_t, x) & @as(c_ulonglong, 0x00000000000000ff)) << @as(c_int, 56)));
}
pub const _OS_OSBYTEORDERARM_H = "";
pub const _ARM_ARCH_H = "";
pub inline fn __DARWIN_OSSwapInt16(x: anytype) __uint16_t {
    return @import("std").zig.c_translation.cast(__uint16_t, if (__builtin_constant_p(x)) __DARWIN_OSSwapConstInt16(x) else _OSSwapInt16(x));
}
pub inline fn __DARWIN_OSSwapInt32(x: anytype) @TypeOf(if (__builtin_constant_p(x)) __DARWIN_OSSwapConstInt32(x) else _OSSwapInt32(x)) {
    return if (__builtin_constant_p(x)) __DARWIN_OSSwapConstInt32(x) else _OSSwapInt32(x);
}
pub inline fn __DARWIN_OSSwapInt64(x: anytype) @TypeOf(if (__builtin_constant_p(x)) __DARWIN_OSSwapConstInt64(x) else _OSSwapInt64(x)) {
    return if (__builtin_constant_p(x)) __DARWIN_OSSwapConstInt64(x) else _OSSwapInt64(x);
}
pub inline fn ntohs(x: anytype) @TypeOf(__DARWIN_OSSwapInt16(x)) {
    return __DARWIN_OSSwapInt16(x);
}
pub inline fn htons(x: anytype) @TypeOf(__DARWIN_OSSwapInt16(x)) {
    return __DARWIN_OSSwapInt16(x);
}
pub inline fn ntohl(x: anytype) @TypeOf(__DARWIN_OSSwapInt32(x)) {
    return __DARWIN_OSSwapInt32(x);
}
pub inline fn htonl(x: anytype) @TypeOf(__DARWIN_OSSwapInt32(x)) {
    return __DARWIN_OSSwapInt32(x);
}
pub inline fn ntohll(x: anytype) @TypeOf(__DARWIN_OSSwapInt64(x)) {
    return __DARWIN_OSSwapInt64(x);
}
pub inline fn htonll(x: anytype) @TypeOf(__DARWIN_OSSwapInt64(x)) {
    return __DARWIN_OSSwapInt64(x);
}
pub const _ALLOCA_H_ = "";
pub const _CT_RUNE_T = "";
pub const _RUNE_T = "";
pub const EXIT_FAILURE = @as(c_int, 1);
pub const EXIT_SUCCESS = @as(c_int, 0);
pub const RAND_MAX = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x7fffffff, .hexadecimal);
pub const MB_CUR_MAX = __mb_cur_max;
pub const _MALLOC_UNDERSCORE_MALLOC_H_ = "";
pub const _DEV_T = "";
pub const _MODE_T = "";
pub const ft_qsort = qsort;
pub const ft_scalloc = calloc;
pub const ft_sfree = free;
pub const ft_smalloc = malloc;
pub const ft_srealloc = realloc;
pub const ft_strtol = strtol;
pub const ft_getenv = getenv;
pub const _LIBCPP_SETJMP_H = "";
pub const _BSD_SETJMP_H = "";
pub const _JBLEN = ((@as(c_int, 14) + @as(c_int, 8)) + @as(c_int, 2)) * @as(c_int, 2);
pub const ft_jmp_buf = jmp_buf;
pub const ft_longjmp = longjmp;
pub const __STDARG_H = "";
pub const _VA_LIST = "";
pub const __GNUC_VA_LIST = @as(c_int, 1);
pub const FREETYPE_CONFIG_INTEGER_TYPES_H_ = "";
pub const FT_SIZEOF_INT = @as(c_int, 32) / FT_CHAR_BIT;
pub const FT_SIZEOF_LONG = @as(c_int, 64) / FT_CHAR_BIT;
pub const FT_SIZEOF_LONG_LONG = @as(c_int, 64) / FT_CHAR_BIT;
pub const FT_INT64 = c_long;
pub const FT_UINT64 = c_ulong;
pub const FREETYPE_CONFIG_PUBLIC_MACROS_H_ = "";
pub const FT_STATIC_CAST = @import("std").zig.c_translation.Macros.CAST_OR_CALL;
pub const FT_REINTERPRET_CAST = @import("std").zig.c_translation.Macros.CAST_OR_CALL;
pub inline fn FT_STATIC_BYTE_CAST(@"type": anytype, @"var": anytype) @TypeOf(@"type"(u8)(@"var")) {
    return @"type"(u8)(@"var");
}
pub const FREETYPE_CONFIG_MAC_SUPPORT_H_ = "";
pub const _LIBCPP_ERRNO_H = "";
pub const _SYS_ERRNO_H_ = "";
pub const errno = __error().*;
pub const EPERM = @as(c_int, 1);
pub const ENOENT = @as(c_int, 2);
pub const ESRCH = @as(c_int, 3);
pub const EINTR = @as(c_int, 4);
pub const EIO = @as(c_int, 5);
pub const ENXIO = @as(c_int, 6);
pub const E2BIG = @as(c_int, 7);
pub const ENOEXEC = @as(c_int, 8);
pub const EBADF = @as(c_int, 9);
pub const ECHILD = @as(c_int, 10);
pub const EDEADLK = @as(c_int, 11);
pub const ENOMEM = @as(c_int, 12);
pub const EACCES = @as(c_int, 13);
pub const EFAULT = @as(c_int, 14);
pub const ENOTBLK = @as(c_int, 15);
pub const EBUSY = @as(c_int, 16);
pub const EEXIST = @as(c_int, 17);
pub const EXDEV = @as(c_int, 18);
pub const ENODEV = @as(c_int, 19);
pub const ENOTDIR = @as(c_int, 20);
pub const EISDIR = @as(c_int, 21);
pub const EINVAL = @as(c_int, 22);
pub const ENFILE = @as(c_int, 23);
pub const EMFILE = @as(c_int, 24);
pub const ENOTTY = @as(c_int, 25);
pub const ETXTBSY = @as(c_int, 26);
pub const EFBIG = @as(c_int, 27);
pub const ENOSPC = @as(c_int, 28);
pub const ESPIPE = @as(c_int, 29);
pub const EROFS = @as(c_int, 30);
pub const EMLINK = @as(c_int, 31);
pub const EPIPE = @as(c_int, 32);
pub const EDOM = @as(c_int, 33);
pub const ERANGE = @as(c_int, 34);
pub const EAGAIN = @as(c_int, 35);
pub const EWOULDBLOCK = EAGAIN;
pub const EINPROGRESS = @as(c_int, 36);
pub const EALREADY = @as(c_int, 37);
pub const ENOTSOCK = @as(c_int, 38);
pub const EDESTADDRREQ = @as(c_int, 39);
pub const EMSGSIZE = @as(c_int, 40);
pub const EPROTOTYPE = @as(c_int, 41);
pub const ENOPROTOOPT = @as(c_int, 42);
pub const EPROTONOSUPPORT = @as(c_int, 43);
pub const ESOCKTNOSUPPORT = @as(c_int, 44);
pub const ENOTSUP = @as(c_int, 45);
pub const EPFNOSUPPORT = @as(c_int, 46);
pub const EAFNOSUPPORT = @as(c_int, 47);
pub const EADDRINUSE = @as(c_int, 48);
pub const EADDRNOTAVAIL = @as(c_int, 49);
pub const ENETDOWN = @as(c_int, 50);
pub const ENETUNREACH = @as(c_int, 51);
pub const ENETRESET = @as(c_int, 52);
pub const ECONNABORTED = @as(c_int, 53);
pub const ECONNRESET = @as(c_int, 54);
pub const ENOBUFS = @as(c_int, 55);
pub const EISCONN = @as(c_int, 56);
pub const ENOTCONN = @as(c_int, 57);
pub const ESHUTDOWN = @as(c_int, 58);
pub const ETOOMANYREFS = @as(c_int, 59);
pub const ETIMEDOUT = @as(c_int, 60);
pub const ECONNREFUSED = @as(c_int, 61);
pub const ELOOP = @as(c_int, 62);
pub const ENAMETOOLONG = @as(c_int, 63);
pub const EHOSTDOWN = @as(c_int, 64);
pub const EHOSTUNREACH = @as(c_int, 65);
pub const ENOTEMPTY = @as(c_int, 66);
pub const EPROCLIM = @as(c_int, 67);
pub const EUSERS = @as(c_int, 68);
pub const EDQUOT = @as(c_int, 69);
pub const ESTALE = @as(c_int, 70);
pub const EREMOTE = @as(c_int, 71);
pub const EBADRPC = @as(c_int, 72);
pub const ERPCMISMATCH = @as(c_int, 73);
pub const EPROGUNAVAIL = @as(c_int, 74);
pub const EPROGMISMATCH = @as(c_int, 75);
pub const EPROCUNAVAIL = @as(c_int, 76);
pub const ENOLCK = @as(c_int, 77);
pub const ENOSYS = @as(c_int, 78);
pub const EFTYPE = @as(c_int, 79);
pub const EAUTH = @as(c_int, 80);
pub const ENEEDAUTH = @as(c_int, 81);
pub const EPWROFF = @as(c_int, 82);
pub const EDEVERR = @as(c_int, 83);
pub const EOVERFLOW = @as(c_int, 84);
pub const EBADEXEC = @as(c_int, 85);
pub const EBADARCH = @as(c_int, 86);
pub const ESHLIBVERS = @as(c_int, 87);
pub const EBADMACHO = @as(c_int, 88);
pub const ECANCELED = @as(c_int, 89);
pub const EIDRM = @as(c_int, 90);
pub const ENOMSG = @as(c_int, 91);
pub const EILSEQ = @as(c_int, 92);
pub const ENOATTR = @as(c_int, 93);
pub const EBADMSG = @as(c_int, 94);
pub const EMULTIHOP = @as(c_int, 95);
pub const ENODATA = @as(c_int, 96);
pub const ENOLINK = @as(c_int, 97);
pub const ENOSR = @as(c_int, 98);
pub const ENOSTR = @as(c_int, 99);
pub const EPROTO = @as(c_int, 100);
pub const ETIME = @as(c_int, 101);
pub const EOPNOTSUPP = @as(c_int, 102);
pub const ENOPOLICY = @as(c_int, 103);
pub const ENOTRECOVERABLE = @as(c_int, 104);
pub const EOWNERDEAD = @as(c_int, 105);
pub const EQFULL = @as(c_int, 106);
pub const ELAST = @as(c_int, 106);
pub const __AVAILABILITYMACROS__ = "";
pub const MAC_OS_VERSION_11_1 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110100, .decimal);
pub const MAC_OS_VERSION_11_3 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 110300, .decimal);
pub const MAC_OS_X_VERSION_MIN_REQUIRED = __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__;
pub const MAC_OS_X_VERSION_MAX_ALLOWED = MAC_OS_X_VERSION_MIN_REQUIRED;
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER = "";
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED = DEPRECATED_ATTRIBUTE;
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_0_AND_LATER = DEPRECATED_ATTRIBUTE;
pub const __AVAILABILITY_MACROS_USES_AVAILABILITY = @as(c_int, 1);
pub const __IPHONE_COMPAT_VERSION = __IPHONE_4_0;
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_1, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_2, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_3, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_5, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_5 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_5, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_5 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_5, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_5 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_5, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_5 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_5, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_5 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_5, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_6, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_6, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_6, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_6, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_6, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_6, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_6, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_7 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_7 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_7 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_7 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_7 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_7 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_7 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_13 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_13, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_8, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_8 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_8 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_8 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_8 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_8 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_8 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_8 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_8 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_9 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_10, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_10_2, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_10_3, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_10_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_11, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_2_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_11_2, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_2_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_2, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11, __MAC_10_11_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_3_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_11_3, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_3_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_3, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_3 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_2, __MAC_10_11_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_4_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_11_4, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_4_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_4, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_2, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_11_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_3, __MAC_10_11_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_12, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_2, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_3, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_4, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_1_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_12_1, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_1_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12_1, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_2, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_3, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_4, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_1 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12, __MAC_10_12_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_2_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_12_2, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_2_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12_2, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_2, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_3, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_4, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_2 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12_1, __MAC_10_12_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_4_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_12_4, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_4_AND_LATER_BUT_DEPRECATED = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12_4, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_1, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_2, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_3, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_4, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_5, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_7, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_8, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_9, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_2, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_10_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_10_3, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_2, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_3_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_3, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_11_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_11_4, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_1_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12_1, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_12_2_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_12_4 = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_12_2, __MAC_10_12_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_13_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_13, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_14_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_14, __IPHONE_COMPAT_VERSION);
pub const AVAILABLE_MAC_OS_X_VERSION_10_15_AND_LATER = __OSX_AVAILABLE_STARTING(__MAC_10_15, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_1_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_1, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_2_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_2, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_3_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_3, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_4_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_5, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_6, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_7_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_7, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_8_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_8, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_9_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_9, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_10_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_10, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_11_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_11, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_12_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_12, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_13_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_13, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const DEPRECATED_IN_MAC_OS_X_VERSION_10_14_4_AND_LATER = __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_0, __MAC_10_14_4, __IPHONE_COMPAT_VERSION, __IPHONE_COMPAT_VERSION);
pub const FTTYPES_H_ = "";
pub const FTSYSTEM_H_ = "";
pub const FTIMAGE_H_ = "";
pub const ft_pixel_mode_none = FT_PIXEL_MODE_NONE;
pub const ft_pixel_mode_mono = FT_PIXEL_MODE_MONO;
pub const ft_pixel_mode_grays = FT_PIXEL_MODE_GRAY;
pub const ft_pixel_mode_pal2 = FT_PIXEL_MODE_GRAY2;
pub const ft_pixel_mode_pal4 = FT_PIXEL_MODE_GRAY4;
pub const FT_OUTLINE_CONTOURS_MAX = SHRT_MAX;
pub const FT_OUTLINE_POINTS_MAX = SHRT_MAX;
pub const FT_OUTLINE_NONE = @as(c_int, 0x0);
pub const FT_OUTLINE_OWNER = @as(c_int, 0x1);
pub const FT_OUTLINE_EVEN_ODD_FILL = @as(c_int, 0x2);
pub const FT_OUTLINE_REVERSE_FILL = @as(c_int, 0x4);
pub const FT_OUTLINE_IGNORE_DROPOUTS = @as(c_int, 0x8);
pub const FT_OUTLINE_SMART_DROPOUTS = @as(c_int, 0x10);
pub const FT_OUTLINE_INCLUDE_STUBS = @as(c_int, 0x20);
pub const FT_OUTLINE_OVERLAP = @as(c_int, 0x40);
pub const FT_OUTLINE_HIGH_PRECISION = @as(c_int, 0x100);
pub const FT_OUTLINE_SINGLE_PASS = @as(c_int, 0x200);
pub const ft_outline_none = FT_OUTLINE_NONE;
pub const ft_outline_owner = FT_OUTLINE_OWNER;
pub const ft_outline_even_odd_fill = FT_OUTLINE_EVEN_ODD_FILL;
pub const ft_outline_reverse_fill = FT_OUTLINE_REVERSE_FILL;
pub const ft_outline_ignore_dropouts = FT_OUTLINE_IGNORE_DROPOUTS;
pub const ft_outline_high_precision = FT_OUTLINE_HIGH_PRECISION;
pub const ft_outline_single_pass = FT_OUTLINE_SINGLE_PASS;
pub inline fn FT_CURVE_TAG(flag: anytype) @TypeOf(flag & @as(c_int, 0x03)) {
    return flag & @as(c_int, 0x03);
}
pub const FT_CURVE_TAG_ON = @as(c_int, 0x01);
pub const FT_CURVE_TAG_CONIC = @as(c_int, 0x00);
pub const FT_CURVE_TAG_CUBIC = @as(c_int, 0x02);
pub const FT_CURVE_TAG_HAS_SCANMODE = @as(c_int, 0x04);
pub const FT_CURVE_TAG_TOUCH_X = @as(c_int, 0x08);
pub const FT_CURVE_TAG_TOUCH_Y = @as(c_int, 0x10);
pub const FT_CURVE_TAG_TOUCH_BOTH = FT_CURVE_TAG_TOUCH_X | FT_CURVE_TAG_TOUCH_Y;
pub const FT_Curve_Tag_On = FT_CURVE_TAG_ON;
pub const FT_Curve_Tag_Conic = FT_CURVE_TAG_CONIC;
pub const FT_Curve_Tag_Cubic = FT_CURVE_TAG_CUBIC;
pub const FT_Curve_Tag_Touch_X = FT_CURVE_TAG_TOUCH_X;
pub const FT_Curve_Tag_Touch_Y = FT_CURVE_TAG_TOUCH_Y;
pub const FT_Outline_MoveTo_Func = FT_Outline_MoveToFunc;
pub const FT_Outline_LineTo_Func = FT_Outline_LineToFunc;
pub const FT_Outline_ConicTo_Func = FT_Outline_ConicToFunc;
pub const FT_Outline_CubicTo_Func = FT_Outline_CubicToFunc;
pub const ft_glyph_format_none = FT_GLYPH_FORMAT_NONE;
pub const ft_glyph_format_composite = FT_GLYPH_FORMAT_COMPOSITE;
pub const ft_glyph_format_bitmap = FT_GLYPH_FORMAT_BITMAP;
pub const ft_glyph_format_outline = FT_GLYPH_FORMAT_OUTLINE;
pub const ft_glyph_format_plotter = FT_GLYPH_FORMAT_PLOTTER;
pub const FT_Raster_Span_Func = FT_SpanFunc;
pub const FT_RASTER_FLAG_DEFAULT = @as(c_int, 0x0);
pub const FT_RASTER_FLAG_AA = @as(c_int, 0x1);
pub const FT_RASTER_FLAG_DIRECT = @as(c_int, 0x2);
pub const FT_RASTER_FLAG_CLIP = @as(c_int, 0x4);
pub const FT_RASTER_FLAG_SDF = @as(c_int, 0x8);
pub const ft_raster_flag_default = FT_RASTER_FLAG_DEFAULT;
pub const ft_raster_flag_aa = FT_RASTER_FLAG_AA;
pub const ft_raster_flag_direct = FT_RASTER_FLAG_DIRECT;
pub const ft_raster_flag_clip = FT_RASTER_FLAG_CLIP;
pub const FT_Raster_New_Func = FT_Raster_NewFunc;
pub const FT_Raster_Done_Func = FT_Raster_DoneFunc;
pub const FT_Raster_Reset_Func = FT_Raster_ResetFunc;
pub const FT_Raster_Set_Mode_Func = FT_Raster_SetModeFunc;
pub const FT_Raster_Render_Func = FT_Raster_RenderFunc;
pub inline fn FT_MAKE_TAG(_x1: anytype, _x2: anytype, _x3: anytype, _x4: anytype) @TypeOf((((FT_STATIC_BYTE_CAST(FT_Tag, _x1) << @as(c_int, 24)) | (FT_STATIC_BYTE_CAST(FT_Tag, _x2) << @as(c_int, 16))) | (FT_STATIC_BYTE_CAST(FT_Tag, _x3) << @as(c_int, 8))) | FT_STATIC_BYTE_CAST(FT_Tag, _x4)) {
    return (((FT_STATIC_BYTE_CAST(FT_Tag, _x1) << @as(c_int, 24)) | (FT_STATIC_BYTE_CAST(FT_Tag, _x2) << @as(c_int, 16))) | (FT_STATIC_BYTE_CAST(FT_Tag, _x3) << @as(c_int, 8))) | FT_STATIC_BYTE_CAST(FT_Tag, _x4);
}
pub inline fn FT_IS_EMPTY(list: anytype) @TypeOf(list.head == @as(c_int, 0)) {
    return list.head == @as(c_int, 0);
}
pub inline fn FT_BOOL(x: anytype) @TypeOf(FT_STATIC_CAST(FT_Bool, x != @as(c_int, 0))) {
    return FT_STATIC_CAST(FT_Bool, x != @as(c_int, 0));
}
pub inline fn FT_ERR_CAT(x: anytype, y: anytype) @TypeOf(FT_ERR_XCAT(x, y)) {
    return FT_ERR_XCAT(x, y);
}
pub inline fn FT_ERR(e: anytype) @TypeOf(FT_ERR_CAT(FT_ERR_PREFIX, e)) {
    return FT_ERR_CAT(FT_ERR_PREFIX, e);
}
pub inline fn FT_ERROR_BASE(x: anytype) @TypeOf(x & @as(c_int, 0xFF)) {
    return x & @as(c_int, 0xFF);
}
pub inline fn FT_ERROR_MODULE(x: anytype) @TypeOf(x & @as(c_uint, 0xFF00)) {
    return x & @as(c_uint, 0xFF00);
}
pub inline fn FT_ERR_EQ(x: anytype, e: anytype) @TypeOf(FT_ERROR_BASE(x) == FT_ERROR_BASE(FT_ERR(e))) {
    return FT_ERROR_BASE(x) == FT_ERROR_BASE(FT_ERR(e));
}
pub inline fn FT_ERR_NEQ(x: anytype, e: anytype) @TypeOf(FT_ERROR_BASE(x) != FT_ERROR_BASE(FT_ERR(e))) {
    return FT_ERROR_BASE(x) != FT_ERROR_BASE(FT_ERR(e));
}
pub const FTERRORS_H_ = "";
pub const __FTERRORS_H__ = "";
pub const FTMODERR_H_ = "";
pub const FT_ERR_BASE = @as(c_int, 0);
pub const FT_INCLUDE_ERR_PROTOS = "";
pub inline fn FT_ERRORDEF_(e: anytype, v: anytype, s: anytype) @TypeOf(FT_ERRORDEF(FT_ERR_CAT(FT_ERR_PREFIX, e), v + FT_ERR_BASE, s)) {
    return FT_ERRORDEF(FT_ERR_CAT(FT_ERR_PREFIX, e), v + FT_ERR_BASE, s);
}
pub inline fn FT_NOERRORDEF_(e: anytype, v: anytype, s: anytype) @TypeOf(FT_ERRORDEF(FT_ERR_CAT(FT_ERR_PREFIX, e), v, s)) {
    return FT_ERRORDEF(FT_ERR_CAT(FT_ERR_PREFIX, e), v, s);
}
pub const FT_ERR_PROTOS_DEFINED = "";
pub const ft_encoding_none = FT_ENCODING_NONE;
pub const ft_encoding_unicode = FT_ENCODING_UNICODE;
pub const ft_encoding_symbol = FT_ENCODING_MS_SYMBOL;
pub const ft_encoding_latin_1 = FT_ENCODING_ADOBE_LATIN_1;
pub const ft_encoding_latin_2 = FT_ENCODING_OLD_LATIN_2;
pub const ft_encoding_sjis = FT_ENCODING_SJIS;
pub const ft_encoding_gb2312 = FT_ENCODING_PRC;
pub const ft_encoding_big5 = FT_ENCODING_BIG5;
pub const ft_encoding_wansung = FT_ENCODING_WANSUNG;
pub const ft_encoding_johab = FT_ENCODING_JOHAB;
pub const ft_encoding_adobe_standard = FT_ENCODING_ADOBE_STANDARD;
pub const ft_encoding_adobe_expert = FT_ENCODING_ADOBE_EXPERT;
pub const ft_encoding_adobe_custom = FT_ENCODING_ADOBE_CUSTOM;
pub const ft_encoding_apple_roman = FT_ENCODING_APPLE_ROMAN;
pub const FT_FACE_FLAG_SCALABLE = @as(c_long, 1) << @as(c_int, 0);
pub const FT_FACE_FLAG_FIXED_SIZES = @as(c_long, 1) << @as(c_int, 1);
pub const FT_FACE_FLAG_FIXED_WIDTH = @as(c_long, 1) << @as(c_int, 2);
pub const FT_FACE_FLAG_SFNT = @as(c_long, 1) << @as(c_int, 3);
pub const FT_FACE_FLAG_HORIZONTAL = @as(c_long, 1) << @as(c_int, 4);
pub const FT_FACE_FLAG_VERTICAL = @as(c_long, 1) << @as(c_int, 5);
pub const FT_FACE_FLAG_KERNING = @as(c_long, 1) << @as(c_int, 6);
pub const FT_FACE_FLAG_FAST_GLYPHS = @as(c_long, 1) << @as(c_int, 7);
pub const FT_FACE_FLAG_MULTIPLE_MASTERS = @as(c_long, 1) << @as(c_int, 8);
pub const FT_FACE_FLAG_GLYPH_NAMES = @as(c_long, 1) << @as(c_int, 9);
pub const FT_FACE_FLAG_EXTERNAL_STREAM = @as(c_long, 1) << @as(c_int, 10);
pub const FT_FACE_FLAG_HINTER = @as(c_long, 1) << @as(c_int, 11);
pub const FT_FACE_FLAG_CID_KEYED = @as(c_long, 1) << @as(c_int, 12);
pub const FT_FACE_FLAG_TRICKY = @as(c_long, 1) << @as(c_int, 13);
pub const FT_FACE_FLAG_COLOR = @as(c_long, 1) << @as(c_int, 14);
pub const FT_FACE_FLAG_VARIATION = @as(c_long, 1) << @as(c_int, 15);
pub const FT_FACE_FLAG_SVG = @as(c_long, 1) << @as(c_int, 16);
pub const FT_FACE_FLAG_SBIX = @as(c_long, 1) << @as(c_int, 17);
pub const FT_FACE_FLAG_SBIX_OVERLAY = @as(c_long, 1) << @as(c_int, 18);
pub inline fn FT_HAS_HORIZONTAL(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_HORIZONTAL) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_HORIZONTAL) != 0);
}
pub inline fn FT_HAS_VERTICAL(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_VERTICAL) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_VERTICAL) != 0);
}
pub inline fn FT_HAS_KERNING(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_KERNING) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_KERNING) != 0);
}
pub inline fn FT_IS_SCALABLE(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_SCALABLE) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_SCALABLE) != 0);
}
pub inline fn FT_IS_SFNT(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_SFNT) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_SFNT) != 0);
}
pub inline fn FT_IS_FIXED_WIDTH(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_FIXED_WIDTH) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_FIXED_WIDTH) != 0);
}
pub inline fn FT_HAS_FIXED_SIZES(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_FIXED_SIZES) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_FIXED_SIZES) != 0);
}
pub inline fn FT_HAS_FAST_GLYPHS(face: anytype) @TypeOf(@as(c_int, 0)) {
    _ = face;
    return @as(c_int, 0);
}
pub inline fn FT_HAS_GLYPH_NAMES(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_GLYPH_NAMES) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_GLYPH_NAMES) != 0);
}
pub inline fn FT_HAS_MULTIPLE_MASTERS(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_MULTIPLE_MASTERS) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_MULTIPLE_MASTERS) != 0);
}
pub inline fn FT_IS_NAMED_INSTANCE(face: anytype) @TypeOf(!!((face.*.face_index & @as(c_long, 0x7FFF0000)) != 0)) {
    return !!((face.*.face_index & @as(c_long, 0x7FFF0000)) != 0);
}
pub inline fn FT_IS_VARIATION(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_VARIATION) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_VARIATION) != 0);
}
pub inline fn FT_IS_CID_KEYED(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_CID_KEYED) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_CID_KEYED) != 0);
}
pub inline fn FT_IS_TRICKY(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_TRICKY) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_TRICKY) != 0);
}
pub inline fn FT_HAS_COLOR(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_COLOR) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_COLOR) != 0);
}
pub inline fn FT_HAS_SVG(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_SVG) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_SVG) != 0);
}
pub inline fn FT_HAS_SBIX(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_SBIX) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_SBIX) != 0);
}
pub inline fn FT_HAS_SBIX_OVERLAY(face: anytype) @TypeOf(!!((face.*.face_flags & FT_FACE_FLAG_SBIX_OVERLAY) != 0)) {
    return !!((face.*.face_flags & FT_FACE_FLAG_SBIX_OVERLAY) != 0);
}
pub const FT_STYLE_FLAG_ITALIC = @as(c_int, 1) << @as(c_int, 0);
pub const FT_STYLE_FLAG_BOLD = @as(c_int, 1) << @as(c_int, 1);
pub const FT_OPEN_MEMORY = @as(c_int, 0x1);
pub const FT_OPEN_STREAM = @as(c_int, 0x2);
pub const FT_OPEN_PATHNAME = @as(c_int, 0x4);
pub const FT_OPEN_DRIVER = @as(c_int, 0x8);
pub const FT_OPEN_PARAMS = @as(c_int, 0x10);
pub const ft_open_memory = FT_OPEN_MEMORY;
pub const ft_open_stream = FT_OPEN_STREAM;
pub const ft_open_pathname = FT_OPEN_PATHNAME;
pub const ft_open_driver = FT_OPEN_DRIVER;
pub const ft_open_params = FT_OPEN_PARAMS;
pub const FT_LOAD_DEFAULT = @as(c_int, 0x0);
pub const FT_LOAD_NO_SCALE = @as(c_long, 1) << @as(c_int, 0);
pub const FT_LOAD_NO_HINTING = @as(c_long, 1) << @as(c_int, 1);
pub const FT_LOAD_RENDER = @as(c_long, 1) << @as(c_int, 2);
pub const FT_LOAD_NO_BITMAP = @as(c_long, 1) << @as(c_int, 3);
pub const FT_LOAD_VERTICAL_LAYOUT = @as(c_long, 1) << @as(c_int, 4);
pub const FT_LOAD_FORCE_AUTOHINT = @as(c_long, 1) << @as(c_int, 5);
pub const FT_LOAD_CROP_BITMAP = @as(c_long, 1) << @as(c_int, 6);
pub const FT_LOAD_PEDANTIC = @as(c_long, 1) << @as(c_int, 7);
pub const FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH = @as(c_long, 1) << @as(c_int, 9);
pub const FT_LOAD_NO_RECURSE = @as(c_long, 1) << @as(c_int, 10);
pub const FT_LOAD_IGNORE_TRANSFORM = @as(c_long, 1) << @as(c_int, 11);
pub const FT_LOAD_MONOCHROME = @as(c_long, 1) << @as(c_int, 12);
pub const FT_LOAD_LINEAR_DESIGN = @as(c_long, 1) << @as(c_int, 13);
pub const FT_LOAD_SBITS_ONLY = @as(c_long, 1) << @as(c_int, 14);
pub const FT_LOAD_NO_AUTOHINT = @as(c_long, 1) << @as(c_int, 15);
pub const FT_LOAD_COLOR = @as(c_long, 1) << @as(c_int, 20);
pub const FT_LOAD_COMPUTE_METRICS = @as(c_long, 1) << @as(c_int, 21);
pub const FT_LOAD_BITMAP_METRICS_ONLY = @as(c_long, 1) << @as(c_int, 22);
pub const FT_LOAD_ADVANCE_ONLY = @as(c_long, 1) << @as(c_int, 8);
pub const FT_LOAD_SVG_ONLY = @as(c_long, 1) << @as(c_int, 23);
pub inline fn FT_LOAD_TARGET_(x: anytype) @TypeOf(FT_STATIC_CAST(FT_Int32, x & @as(c_int, 15)) << @as(c_int, 16)) {
    return FT_STATIC_CAST(FT_Int32, x & @as(c_int, 15)) << @as(c_int, 16);
}
pub const FT_LOAD_TARGET_NORMAL = FT_LOAD_TARGET_(FT_RENDER_MODE_NORMAL);
pub const FT_LOAD_TARGET_LIGHT = FT_LOAD_TARGET_(FT_RENDER_MODE_LIGHT);
pub const FT_LOAD_TARGET_MONO = FT_LOAD_TARGET_(FT_RENDER_MODE_MONO);
pub const FT_LOAD_TARGET_LCD = FT_LOAD_TARGET_(FT_RENDER_MODE_LCD);
pub const FT_LOAD_TARGET_LCD_V = FT_LOAD_TARGET_(FT_RENDER_MODE_LCD_V);
pub inline fn FT_LOAD_TARGET_MODE(x: anytype) @TypeOf(FT_STATIC_CAST(FT_Render_Mode, (x >> @as(c_int, 16)) & @as(c_int, 15))) {
    return FT_STATIC_CAST(FT_Render_Mode, (x >> @as(c_int, 16)) & @as(c_int, 15));
}
pub const ft_render_mode_normal = FT_RENDER_MODE_NORMAL;
pub const ft_render_mode_mono = FT_RENDER_MODE_MONO;
pub const ft_kerning_default = FT_KERNING_DEFAULT;
pub const ft_kerning_unfitted = FT_KERNING_UNFITTED;
pub const ft_kerning_unscaled = FT_KERNING_UNSCALED;
pub const FT_SUBGLYPH_FLAG_ARGS_ARE_WORDS = @as(c_int, 1);
pub const FT_SUBGLYPH_FLAG_ARGS_ARE_XY_VALUES = @as(c_int, 2);
pub const FT_SUBGLYPH_FLAG_ROUND_XY_TO_GRID = @as(c_int, 4);
pub const FT_SUBGLYPH_FLAG_SCALE = @as(c_int, 8);
pub const FT_SUBGLYPH_FLAG_XY_SCALE = @as(c_int, 0x40);
pub const FT_SUBGLYPH_FLAG_2X2 = @as(c_int, 0x80);
pub const FT_SUBGLYPH_FLAG_USE_MY_METRICS = @as(c_int, 0x200);
pub const FT_FSTYPE_INSTALLABLE_EMBEDDING = @as(c_int, 0x0000);
pub const FT_FSTYPE_RESTRICTED_LICENSE_EMBEDDING = @as(c_int, 0x0002);
pub const FT_FSTYPE_PREVIEW_AND_PRINT_EMBEDDING = @as(c_int, 0x0004);
pub const FT_FSTYPE_EDITABLE_EMBEDDING = @as(c_int, 0x0008);
pub const FT_FSTYPE_NO_SUBSETTING = @as(c_int, 0x0100);
pub const FT_FSTYPE_BITMAP_EMBEDDING_ONLY = @as(c_int, 0x0200);
pub const FREETYPE_MAJOR = @as(c_int, 2);
pub const FREETYPE_MINOR = @as(c_int, 12);
pub const FREETYPE_PATCH = @as(c_int, 1);
pub const FTADVANC_H_ = "";
pub const FT_ADVANCE_FLAG_FAST_ONLY = @as(c_long, 0x20000000);
pub const FTBBOX_H_ = "";
pub const FTBITMAP_H_ = "";
pub const FTCOLOR_H_ = "";
pub const FT_PALETTE_FOR_LIGHT_BACKGROUND = @as(c_int, 0x01);
pub const FT_PALETTE_FOR_DARK_BACKGROUND = @as(c_int, 0x02);
pub const FTLCDFIL_H_ = "";
pub const FTPARAMS_H_ = "";
pub const FT_PARAM_TAG_IGNORE_TYPOGRAPHIC_FAMILY = FT_MAKE_TAG('i', 'g', 'p', 'f');
pub const FT_PARAM_TAG_IGNORE_PREFERRED_FAMILY = FT_PARAM_TAG_IGNORE_TYPOGRAPHIC_FAMILY;
pub const FT_PARAM_TAG_IGNORE_TYPOGRAPHIC_SUBFAMILY = FT_MAKE_TAG('i', 'g', 'p', 's');
pub const FT_PARAM_TAG_IGNORE_PREFERRED_SUBFAMILY = FT_PARAM_TAG_IGNORE_TYPOGRAPHIC_SUBFAMILY;
pub const FT_PARAM_TAG_INCREMENTAL = FT_MAKE_TAG('i', 'n', 'c', 'r');
pub const FT_PARAM_TAG_IGNORE_SBIX = FT_MAKE_TAG('i', 's', 'b', 'x');
pub const FT_PARAM_TAG_LCD_FILTER_WEIGHTS = FT_MAKE_TAG('l', 'c', 'd', 'f');
pub const FT_PARAM_TAG_RANDOM_SEED = FT_MAKE_TAG('s', 'e', 'e', 'd');
pub const FT_PARAM_TAG_STEM_DARKENING = FT_MAKE_TAG('d', 'a', 'r', 'k');
pub const FT_PARAM_TAG_UNPATENTED_HINTING = FT_MAKE_TAG('u', 'n', 'p', 'a');
pub const FT_LCD_FILTER_FIVE_TAPS = @as(c_int, 5);
pub const FTSIZES_H_ = "";
pub const FTSTROKE_H_ = "";
pub const FTOUTLN_H_ = "";
pub const FTGLYPH_H_ = "";
pub const ft_glyph_bbox_unscaled = FT_GLYPH_BBOX_UNSCALED;
pub const ft_glyph_bbox_subpixels = FT_GLYPH_BBOX_SUBPIXELS;
pub const ft_glyph_bbox_gridfit = FT_GLYPH_BBOX_GRIDFIT;
pub const ft_glyph_bbox_truncate = FT_GLYPH_BBOX_TRUNCATE;
pub const ft_glyph_bbox_pixels = FT_GLYPH_BBOX_PIXELS;
pub const FTTRIGON_H_ = "";
pub const FT_ANGLE_PI = @as(c_long, 180) << @as(c_int, 16);
pub const FT_ANGLE_2PI = FT_ANGLE_PI * @as(c_int, 2);
pub const FT_ANGLE_PI2 = FT_ANGLE_PI / @as(c_int, 2);
pub const FT_ANGLE_PI4 = FT_ANGLE_PI / @as(c_int, 4);
pub const __darwin_pthread_handler_rec = struct___darwin_pthread_handler_rec;
pub const _opaque_pthread_attr_t = struct__opaque_pthread_attr_t;
pub const _opaque_pthread_cond_t = struct__opaque_pthread_cond_t;
pub const _opaque_pthread_condattr_t = struct__opaque_pthread_condattr_t;
pub const _opaque_pthread_mutex_t = struct__opaque_pthread_mutex_t;
pub const _opaque_pthread_mutexattr_t = struct__opaque_pthread_mutexattr_t;
pub const _opaque_pthread_once_t = struct__opaque_pthread_once_t;
pub const _opaque_pthread_rwlock_t = struct__opaque_pthread_rwlock_t;
pub const _opaque_pthread_rwlockattr_t = struct__opaque_pthread_rwlockattr_t;
pub const _opaque_pthread_t = struct__opaque_pthread_t;
pub const _hb_var_int_t = union__hb_var_int_t;
pub const _hb_var_num_t = union__hb_var_num_t;
pub const hb_language_impl_t = struct_hb_language_impl_t;
pub const __sbuf = struct___sbuf;
pub const __sFILEX = struct___sFILEX;
pub const __sFILE = struct___sFILE;
pub const __darwin_arm_exception_state = struct___darwin_arm_exception_state;
pub const __darwin_arm_exception_state64 = struct___darwin_arm_exception_state64;
pub const __darwin_arm_thread_state = struct___darwin_arm_thread_state;
pub const __darwin_arm_thread_state64 = struct___darwin_arm_thread_state64;
pub const __darwin_arm_vfp_state = struct___darwin_arm_vfp_state;
pub const __darwin_arm_neon_state64 = struct___darwin_arm_neon_state64;
pub const __darwin_arm_neon_state = struct___darwin_arm_neon_state;
pub const __arm_pagein_state = struct___arm_pagein_state;
pub const __arm_legacy_debug_state = struct___arm_legacy_debug_state;
pub const __darwin_arm_debug_state32 = struct___darwin_arm_debug_state32;
pub const __darwin_arm_debug_state64 = struct___darwin_arm_debug_state64;
pub const __darwin_arm_cpmu_state64 = struct___darwin_arm_cpmu_state64;
pub const __darwin_mcontext32 = struct___darwin_mcontext32;
pub const __darwin_mcontext64 = struct___darwin_mcontext64;
pub const __darwin_sigaltstack = struct___darwin_sigaltstack;
pub const __darwin_ucontext = struct___darwin_ucontext;
pub const sigval = union_sigval;
pub const sigevent = struct_sigevent;
pub const __siginfo = struct___siginfo;
pub const __sigaction_u = union___sigaction_u;
pub const __sigaction = struct___sigaction;
pub const sigaction = struct_sigaction;
pub const sigvec = struct_sigvec;
pub const sigstack = struct_sigstack;
pub const timeval = struct_timeval;
pub const rusage = struct_rusage;
pub const rusage_info_v0 = struct_rusage_info_v0;
pub const rusage_info_v1 = struct_rusage_info_v1;
pub const rusage_info_v2 = struct_rusage_info_v2;
pub const rusage_info_v3 = struct_rusage_info_v3;
pub const rusage_info_v4 = struct_rusage_info_v4;
pub const rusage_info_v5 = struct_rusage_info_v5;
pub const rlimit = struct_rlimit;
pub const proc_rlimit_control_wakeupmon = struct_proc_rlimit_control_wakeupmon;
pub const _OSUnalignedU16 = struct__OSUnalignedU16;
pub const _OSUnalignedU32 = struct__OSUnalignedU32;
pub const _OSUnalignedU64 = struct__OSUnalignedU64;
pub const FT_MemoryRec_ = struct_FT_MemoryRec_;
pub const FT_StreamDesc_ = union_FT_StreamDesc_;
pub const FT_StreamRec_ = struct_FT_StreamRec_;
pub const FT_Vector_ = struct_FT_Vector_;
pub const FT_BBox_ = struct_FT_BBox_;
pub const FT_Pixel_Mode_ = enum_FT_Pixel_Mode_;
pub const FT_Bitmap_ = struct_FT_Bitmap_;
pub const FT_Outline_ = struct_FT_Outline_;
pub const FT_Outline_Funcs_ = struct_FT_Outline_Funcs_;
pub const FT_Glyph_Format_ = enum_FT_Glyph_Format_;
pub const FT_Span_ = struct_FT_Span_;
pub const FT_Raster_Params_ = struct_FT_Raster_Params_;
pub const FT_RasterRec_ = struct_FT_RasterRec_;
pub const FT_Raster_Funcs_ = struct_FT_Raster_Funcs_;
pub const FT_UnitVector_ = struct_FT_UnitVector_;
pub const FT_Matrix_ = struct_FT_Matrix_;
pub const FT_Data_ = struct_FT_Data_;
pub const FT_Generic_ = struct_FT_Generic_;
pub const FT_ListNodeRec_ = struct_FT_ListNodeRec_;
pub const FT_ListRec_ = struct_FT_ListRec_;
pub const FT_Glyph_Metrics_ = struct_FT_Glyph_Metrics_;
pub const FT_Bitmap_Size_ = struct_FT_Bitmap_Size_;
pub const FT_LibraryRec_ = struct_FT_LibraryRec_;
pub const FT_ModuleRec_ = struct_FT_ModuleRec_;
pub const FT_DriverRec_ = struct_FT_DriverRec_;
pub const FT_RendererRec_ = struct_FT_RendererRec_;
pub const FT_Encoding_ = enum_FT_Encoding_;
pub const FT_CharMapRec_ = struct_FT_CharMapRec_;
pub const FT_SubGlyphRec_ = struct_FT_SubGlyphRec_;
pub const FT_Slot_InternalRec_ = struct_FT_Slot_InternalRec_;
pub const FT_GlyphSlotRec_ = struct_FT_GlyphSlotRec_;
pub const FT_Size_Metrics_ = struct_FT_Size_Metrics_;
pub const FT_Size_InternalRec_ = struct_FT_Size_InternalRec_;
pub const FT_SizeRec_ = struct_FT_SizeRec_;
pub const FT_Face_InternalRec_ = struct_FT_Face_InternalRec_;
pub const FT_FaceRec_ = struct_FT_FaceRec_;
pub const FT_Parameter_ = struct_FT_Parameter_;
pub const FT_Open_Args_ = struct_FT_Open_Args_;
pub const FT_Size_Request_Type_ = enum_FT_Size_Request_Type_;
pub const FT_Size_RequestRec_ = struct_FT_Size_RequestRec_;
pub const FT_Render_Mode_ = enum_FT_Render_Mode_;
pub const FT_Kerning_Mode_ = enum_FT_Kerning_Mode_;
pub const FT_Color_ = struct_FT_Color_;
pub const FT_Palette_Data_ = struct_FT_Palette_Data_;
pub const FT_LayerIterator_ = struct_FT_LayerIterator_;
pub const FT_PaintFormat_ = enum_FT_PaintFormat_;
pub const FT_ColorStopIterator_ = struct_FT_ColorStopIterator_;
pub const FT_ColorIndex_ = struct_FT_ColorIndex_;
pub const FT_ColorStop_ = struct_FT_ColorStop_;
pub const FT_PaintExtend_ = enum_FT_PaintExtend_;
pub const FT_ColorLine_ = struct_FT_ColorLine_;
pub const FT_Affine_23_ = struct_FT_Affine_23_;
pub const FT_Composite_Mode_ = enum_FT_Composite_Mode_;
pub const FT_Opaque_Paint_ = struct_FT_Opaque_Paint_;
pub const FT_PaintColrLayers_ = struct_FT_PaintColrLayers_;
pub const FT_PaintSolid_ = struct_FT_PaintSolid_;
pub const FT_PaintLinearGradient_ = struct_FT_PaintLinearGradient_;
pub const FT_PaintRadialGradient_ = struct_FT_PaintRadialGradient_;
pub const FT_PaintSweepGradient_ = struct_FT_PaintSweepGradient_;
pub const FT_PaintGlyph_ = struct_FT_PaintGlyph_;
pub const FT_PaintColrGlyph_ = struct_FT_PaintColrGlyph_;
pub const FT_PaintTransform_ = struct_FT_PaintTransform_;
pub const FT_PaintTranslate_ = struct_FT_PaintTranslate_;
pub const FT_PaintScale_ = struct_FT_PaintScale_;
pub const FT_PaintRotate_ = struct_FT_PaintRotate_;
pub const FT_PaintSkew_ = struct_FT_PaintSkew_;
pub const FT_PaintComposite_ = struct_FT_PaintComposite_;
pub const FT_COLR_Paint_ = struct_FT_COLR_Paint_;
pub const FT_Color_Root_Transform_ = enum_FT_Color_Root_Transform_;
pub const FT_ClipBox_ = struct_FT_ClipBox_;
pub const FT_LcdFilter_ = enum_FT_LcdFilter_;
pub const FT_Orientation_ = enum_FT_Orientation_;
pub const FT_Glyph_Class_ = struct_FT_Glyph_Class_;
pub const FT_GlyphRec_ = struct_FT_GlyphRec_;
pub const FT_BitmapGlyphRec_ = struct_FT_BitmapGlyphRec_;
pub const FT_OutlineGlyphRec_ = struct_FT_OutlineGlyphRec_;
pub const FT_SvgGlyphRec_ = struct_FT_SvgGlyphRec_;
pub const FT_Glyph_BBox_Mode_ = enum_FT_Glyph_BBox_Mode_;
pub const FT_StrokerRec_ = struct_FT_StrokerRec_;
pub const FT_Stroker_LineJoin_ = enum_FT_Stroker_LineJoin_;
pub const FT_Stroker_LineCap_ = enum_FT_Stroker_LineCap_;
pub const FT_StrokerBorder_ = enum_FT_StrokerBorder_;
