// Extracted from `zig translate-c tmp.c` with `#include <objc/message.h>` in the file.
pub const SEL = opaque {};
pub const Class = opaque {};

pub extern fn sel_getUid(str: [*c]const u8) ?*SEL;
pub extern fn objc_getClass(name: [*c]const u8) ?*Class;
pub extern fn objc_msgSend() void;
