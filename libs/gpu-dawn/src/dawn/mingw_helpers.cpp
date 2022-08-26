#ifdef __MINGW32__
#include <guiddef.h>
#include <stdint.h>

#define MINGW_UUIDOF(type, spec)                                              \
    extern "C++" {                                                            \
    struct __declspec(uuid(spec)) type;                                       \
    template<> const GUID &__mingw_uuidof<type>() {                           \
        static constexpr IID __uuid_inst = guid_from_string(spec);            \
        return __uuid_inst;                                                   \
    }                                                                         \
    template<> const GUID &__mingw_uuidof<type*>() {                          \
        return __mingw_uuidof<type>();                                        \
    }                                                                         \
    }

constexpr uint8_t nybble_from_hex(char c) {
  return ((c >= '0' && c <= '9')
              ? (c - '0')
              : ((c >= 'a' && c <= 'f')
                     ? (c - 'a' + 10)
                     : ((c >= 'A' && c <= 'F') ? (c - 'A' + 10)
                                               : /* Should be an error */ -1)));
}

constexpr uint8_t byte_from_hex(char c1, char c2) {
  return nybble_from_hex(c1) << 4 | nybble_from_hex(c2);
}

constexpr uint8_t byte_from_hexstr(const char str[2]) {
  return nybble_from_hex(str[0]) << 4 | nybble_from_hex(str[1]);
}

constexpr GUID guid_from_string(const char str[37]) {
  return GUID{static_cast<uint32_t>(byte_from_hexstr(str)) << 24 |
                  static_cast<uint32_t>(byte_from_hexstr(str + 2)) << 16 |
                  static_cast<uint32_t>(byte_from_hexstr(str + 4)) << 8 |
                  byte_from_hexstr(str + 6),
              static_cast<uint16_t>(
                  static_cast<uint16_t>(byte_from_hexstr(str + 9)) << 8 |
                  byte_from_hexstr(str + 11)),
              static_cast<uint16_t>(
                  static_cast<uint16_t>(byte_from_hexstr(str + 14)) << 8 |
                  byte_from_hexstr(str + 16)),
              {byte_from_hexstr(str + 19), byte_from_hexstr(str + 21),
               byte_from_hexstr(str + 24), byte_from_hexstr(str + 26),
               byte_from_hexstr(str + 28), byte_from_hexstr(str + 30),
               byte_from_hexstr(str + 32), byte_from_hexstr(str + 34)}};
}

#endif // __MINGW32__

// The point of this helper file is to export the specializations for MINGW_UUIDOF
// below, since MinGW does not have these as part of dxguid yet (not completely up
// to date.)
MINGW_UUIDOF(IDXGraphicsAnalysis, "9f251514-9d4d-4902-9d60-18988ab7d4b5")
