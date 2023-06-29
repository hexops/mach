const std = @import("std");
const c = @import("c.zig");

pub const Direction = enum(u3) {
    invalid = c.HB_DIRECTION_INVALID,
    ltr = c.HB_DIRECTION_LTR,
    rtl = c.HB_DIRECTION_RTL,
    ttb = c.HB_DIRECTION_TTB,
    bit = c.HB_DIRECTION_BTT,

    pub fn fromString(str: []const u8) Direction {
        return @as(Direction, @enumFromInt(c.hb_direction_from_string(str.ptr, @as(c_int, @intCast(str.len)))));
    }

    pub fn toString(self: Direction) [:0]const u8 {
        return std.mem.span(@as([*:0]const u8, @ptrCast(c.hb_direction_to_string(@intFromEnum(self)))));
    }
};

pub const Script = enum(u31) {
    common = c.HB_SCRIPT_COMMON,
    inherited = c.HB_SCRIPT_INHERITED,
    unknown = c.HB_SCRIPT_UNKNOWN,
    arabic = c.HB_SCRIPT_ARABIC,
    armenian = c.HB_SCRIPT_ARMENIAN,
    bengali = c.HB_SCRIPT_BENGALI,
    cyrillic = c.HB_SCRIPT_CYRILLIC,
    devanagari = c.HB_SCRIPT_DEVANAGARI,
    georgian = c.HB_SCRIPT_GEORGIAN,
    greek = c.HB_SCRIPT_GREEK,
    gujarati = c.HB_SCRIPT_GUJARATI,
    gurmukhi = c.HB_SCRIPT_GURMUKHI,
    hangul = c.HB_SCRIPT_HANGUL,
    han = c.HB_SCRIPT_HAN,
    hebrew = c.HB_SCRIPT_HEBREW,
    hiragana = c.HB_SCRIPT_HIRAGANA,
    kannada = c.HB_SCRIPT_KANNADA,
    katakana = c.HB_SCRIPT_KATAKANA,
    lao = c.HB_SCRIPT_LAO,
    latin = c.HB_SCRIPT_LATIN,
    malayalam = c.HB_SCRIPT_MALAYALAM,
    oriya = c.HB_SCRIPT_ORIYA,
    tamil = c.HB_SCRIPT_TAMIL,
    telugu = c.HB_SCRIPT_TELUGU,
    thai = c.HB_SCRIPT_THAI,
    tibetan = c.HB_SCRIPT_TIBETAN,
    bopomofo = c.HB_SCRIPT_BOPOMOFO,
    braille = c.HB_SCRIPT_BRAILLE,
    canadian_syllabics = c.HB_SCRIPT_CANADIAN_SYLLABICS,
    cherokee = c.HB_SCRIPT_CHEROKEE,
    ethiopic = c.HB_SCRIPT_ETHIOPIC,
    khmer = c.HB_SCRIPT_KHMER,
    mongolian = c.HB_SCRIPT_MONGOLIAN,
    myanmar = c.HB_SCRIPT_MYANMAR,
    ogham = c.HB_SCRIPT_OGHAM,
    runic = c.HB_SCRIPT_RUNIC,
    sinhala = c.HB_SCRIPT_SINHALA,
    syriac = c.HB_SCRIPT_SYRIAC,
    thaana = c.HB_SCRIPT_THAANA,
    yi = c.HB_SCRIPT_YI,
    deseret = c.HB_SCRIPT_DESERET,
    gothic = c.HB_SCRIPT_GOTHIC,
    old_italic = c.HB_SCRIPT_OLD_ITALIC,
    buhid = c.HB_SCRIPT_BUHID,
    hanunoo = c.HB_SCRIPT_HANUNOO,
    tagalog = c.HB_SCRIPT_TAGALOG,
    tagbanwa = c.HB_SCRIPT_TAGBANWA,
    cypriot = c.HB_SCRIPT_CYPRIOT,
    limbu = c.HB_SCRIPT_LIMBU,
    linear_b = c.HB_SCRIPT_LINEAR_B,
    osmanya = c.HB_SCRIPT_OSMANYA,
    shavian = c.HB_SCRIPT_SHAVIAN,
    tai_le = c.HB_SCRIPT_TAI_LE,
    ugaritic = c.HB_SCRIPT_UGARITIC,
    buginese = c.HB_SCRIPT_BUGINESE,
    coptic = c.HB_SCRIPT_COPTIC,
    glagolitic = c.HB_SCRIPT_GLAGOLITIC,
    kharoshthi = c.HB_SCRIPT_KHAROSHTHI,
    new_tai_lue = c.HB_SCRIPT_NEW_TAI_LUE,
    old_persian = c.HB_SCRIPT_OLD_PERSIAN,
    syloti_nagri = c.HB_SCRIPT_SYLOTI_NAGRI,
    tifinagh = c.HB_SCRIPT_TIFINAGH,
    balinese = c.HB_SCRIPT_BALINESE,
    cuneiform = c.HB_SCRIPT_CUNEIFORM,
    nko = c.HB_SCRIPT_NKO,
    phags_pa = c.HB_SCRIPT_PHAGS_PA,
    phoenician = c.HB_SCRIPT_PHOENICIAN,
    carian = c.HB_SCRIPT_CARIAN,
    cham = c.HB_SCRIPT_CHAM,
    kayah_li = c.HB_SCRIPT_KAYAH_LI,
    lepcha = c.HB_SCRIPT_LEPCHA,
    lycian = c.HB_SCRIPT_LYCIAN,
    lydian = c.HB_SCRIPT_LYDIAN,
    ol_chiki = c.HB_SCRIPT_OL_CHIKI,
    rejang = c.HB_SCRIPT_REJANG,
    saurashtra = c.HB_SCRIPT_SAURASHTRA,
    sundanese = c.HB_SCRIPT_SUNDANESE,
    vai = c.HB_SCRIPT_VAI,
    avestan = c.HB_SCRIPT_AVESTAN,
    bamum = c.HB_SCRIPT_BAMUM,
    egyptian_hieroglyphs = c.HB_SCRIPT_EGYPTIAN_HIEROGLYPHS,
    imperial_aramaic = c.HB_SCRIPT_IMPERIAL_ARAMAIC,
    inscriptional_pahlavi = c.HB_SCRIPT_INSCRIPTIONAL_PAHLAVI,
    inscriptional_parthian = c.HB_SCRIPT_INSCRIPTIONAL_PARTHIAN,
    javanese = c.HB_SCRIPT_JAVANESE,
    kaithi = c.HB_SCRIPT_KAITHI,
    lisu = c.HB_SCRIPT_LISU,
    meetei_mayek = c.HB_SCRIPT_MEETEI_MAYEK,
    old_south_arabian = c.HB_SCRIPT_OLD_SOUTH_ARABIAN,
    old_turkic = c.HB_SCRIPT_OLD_TURKIC,
    samaritan = c.HB_SCRIPT_SAMARITAN,
    tai_tham = c.HB_SCRIPT_TAI_THAM,
    tai_viet = c.HB_SCRIPT_TAI_VIET,
    batak = c.HB_SCRIPT_BATAK,
    brahmi = c.HB_SCRIPT_BRAHMI,
    mandaic = c.HB_SCRIPT_MANDAIC,
    chakma = c.HB_SCRIPT_CHAKMA,
    meroitic_cursive = c.HB_SCRIPT_MEROITIC_CURSIVE,
    meroitic_hieroglyphs = c.HB_SCRIPT_MEROITIC_HIEROGLYPHS,
    miao = c.HB_SCRIPT_MIAO,
    sharada = c.HB_SCRIPT_SHARADA,
    sora_sompeng = c.HB_SCRIPT_SORA_SOMPENG,
    takri = c.HB_SCRIPT_TAKRI,
    bassa_vah = c.HB_SCRIPT_BASSA_VAH,
    caucasian_albanian = c.HB_SCRIPT_CAUCASIAN_ALBANIAN,
    duployan = c.HB_SCRIPT_DUPLOYAN,
    elbasan = c.HB_SCRIPT_ELBASAN,
    grantha = c.HB_SCRIPT_GRANTHA,
    khojki = c.HB_SCRIPT_KHOJKI,
    khudawadi = c.HB_SCRIPT_KHUDAWADI,
    linear_a = c.HB_SCRIPT_LINEAR_A,
    mahajani = c.HB_SCRIPT_MAHAJANI,
    manichaean = c.HB_SCRIPT_MANICHAEAN,
    mende_kikakui = c.HB_SCRIPT_MENDE_KIKAKUI,
    modi = c.HB_SCRIPT_MODI,
    mro = c.HB_SCRIPT_MRO,
    nabataean = c.HB_SCRIPT_NABATAEAN,
    old_north_arabian = c.HB_SCRIPT_OLD_NORTH_ARABIAN,
    old_permic = c.HB_SCRIPT_OLD_PERMIC,
    pahawh_hmong = c.HB_SCRIPT_PAHAWH_HMONG,
    palmyrene = c.HB_SCRIPT_PALMYRENE,
    pau_cin_hau = c.HB_SCRIPT_PAU_CIN_HAU,
    psalter_pahlavi = c.HB_SCRIPT_PSALTER_PAHLAVI,
    siddham = c.HB_SCRIPT_SIDDHAM,
    tirhuta = c.HB_SCRIPT_TIRHUTA,
    warang_citi = c.HB_SCRIPT_WARANG_CITI,
    ahom = c.HB_SCRIPT_AHOM,
    anatolian_hieroglyphs = c.HB_SCRIPT_ANATOLIAN_HIEROGLYPHS,
    hatran = c.HB_SCRIPT_HATRAN,
    multani = c.HB_SCRIPT_MULTANI,
    old_hungarian = c.HB_SCRIPT_OLD_HUNGARIAN,
    signwriting = c.HB_SCRIPT_SIGNWRITING,
    adlam = c.HB_SCRIPT_ADLAM,
    bhaiksuki = c.HB_SCRIPT_BHAIKSUKI,
    marchen = c.HB_SCRIPT_MARCHEN,
    osage = c.HB_SCRIPT_OSAGE,
    tangut = c.HB_SCRIPT_TANGUT,
    newa = c.HB_SCRIPT_NEWA,
    masaram_gondi = c.HB_SCRIPT_MASARAM_GONDI,
    nushu = c.HB_SCRIPT_NUSHU,
    soyombo = c.HB_SCRIPT_SOYOMBO,
    zanabazar_square = c.HB_SCRIPT_ZANABAZAR_SQUARE,
    dogra = c.HB_SCRIPT_DOGRA,
    gunjala_gondi = c.HB_SCRIPT_GUNJALA_GONDI,
    hanifi_rohingya = c.HB_SCRIPT_HANIFI_ROHINGYA,
    makasar = c.HB_SCRIPT_MAKASAR,
    medefaidrin = c.HB_SCRIPT_MEDEFAIDRIN,
    old_sogdian = c.HB_SCRIPT_OLD_SOGDIAN,
    sogdian = c.HB_SCRIPT_SOGDIAN,
    elymaic = c.HB_SCRIPT_ELYMAIC,
    nandinagari = c.HB_SCRIPT_NANDINAGARI,
    nyiakeng_puachue_hmong = c.HB_SCRIPT_NYIAKENG_PUACHUE_HMONG,
    wancho = c.HB_SCRIPT_WANCHO,
    chorasmian = c.HB_SCRIPT_CHORASMIAN,
    dives_akuru = c.HB_SCRIPT_DIVES_AKURU,
    khitan_small_script = c.HB_SCRIPT_KHITAN_SMALL_SCRIPT,
    yezidi = c.HB_SCRIPT_YEZIDI,
    cypro_minoan = c.HB_SCRIPT_CYPRO_MINOAN,
    old_uyghur = c.HB_SCRIPT_OLD_UYGHUR,
    tangsa = c.HB_SCRIPT_TANGSA,
    toto = c.HB_SCRIPT_TOTO,
    vithkuqi = c.HB_SCRIPT_VITHKUQI,
    math = c.HB_SCRIPT_MATH,
    invalid = c.HB_SCRIPT_INVALID,

    pub fn fromISO15924Tag(tag: Tag) Script {
        return @as(Script, @enumFromInt(c.hb_script_from_iso15924_tag(tag.handle)));
    }

    pub fn fromString(str: []const u8) Script {
        return @as(Script, @enumFromInt(c.hb_script_from_string(str.ptr, @as(c_int, @intCast(str.len)))));
    }

    pub fn toISO15924Tag(self: Script) Tag {
        return .{ .handle = c.hb_script_to_iso15924_tag(@intFromEnum(self)) };
    }

    pub fn getHorizontalDirection(self: Script) Direction {
        return @as(Direction, @enumFromInt(c.hb_script_get_horizontal_direction(@intFromEnum(self))));
    }
};

pub const Language = struct {
    handle: c.hb_language_t,

    pub fn fromString(name: []const u8) Language {
        return .{
            .handle = c.hb_language_from_string(name.ptr, @as(c_int, @intCast(name.len))),
        };
    }

    pub fn toString(self: Language) [:0]const u8 {
        return std.mem.span(@as([*:0]const u8, @ptrCast(c.hb_language_to_string(self.handle))));
    }

    pub fn getDefault() Language {
        return .{ .handle = c.hb_language_get_default() };
    }
};

pub const Feature = extern struct {
    tag: c.hb_tag_t,
    value: u32,
    start: c_uint,
    end: c_uint,

    pub fn fromString(str: []const u8) ?Feature {
        var f: Feature = undefined;
        return if (hb_feature_from_string(str.ptr, @as(c_int, @intCast(str.len)), &f) > 1)
            f
        else
            null;
    }

    pub fn toString(self: *Feature, buf: []u8) void {
        hb_feature_to_string(self, buf.ptr, @as(c_uint, @intCast(buf.len)));
    }
};

pub const Variation = extern struct {
    tag: u32,
    value: f32,

    pub fn fromString(str: []const u8) ?Variation {
        var v: Variation = undefined;
        return if (hb_variation_from_string(str.ptr, @as(c_int, @intCast(str.len)), &v) > 1)
            v
        else
            null;
    }

    pub fn toString(self: *Variation, buf: []u8) void {
        hb_variation_to_string(self, buf.ptr, @as(c_uint, @intCast(buf.len)));
    }

    pub fn tag(self: Variation) Tag {
        return .{ .handle = self.tag };
    }

    pub fn value(self: Variation) f32 {
        return self.value;
    }
};

pub const Tag = struct {
    handle: u32,

    pub fn fromString(str: []const u8) Tag {
        return .{ .handle = c.hb_tag_from_string(str.ptr, @as(c_int, @intCast(str.len))) };
    }

    pub fn toString(self: Tag) []const u8 {
        var str: [4]u8 = undefined;
        c.hb_tag_to_string(self.handle, &str[0]);
        return &str;
    }
};

pub const Shapers = ?[*:null]const ?[*:0]const u8;

pub extern fn hb_feature_from_string(str: [*c]const u8, len: c_int, feature: [*c]Feature) u8;
pub extern fn hb_feature_to_string(feature: [*c]Feature, buf: [*c]u8, size: c_uint) void;
pub extern fn hb_variation_from_string(str: [*c]const u8, len: c_int, variation: [*c]Variation) u8;
pub extern fn hb_variation_to_string(variation: [*c]Variation, buf: [*c]u8, size: c_uint) void;
