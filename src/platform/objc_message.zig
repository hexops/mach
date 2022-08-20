// Extracted from `zig translate-c tmp.c` with `#include <objc/message.h>` in the file.
pub const struct_objc_selector = opaque {};
pub const SEL = ?*struct_objc_selector;
pub const Class = ?*struct_objc_class;
pub const struct_objc_class = opaque {};

pub extern fn sel_getUid(str: [*c]const u8) SEL;
pub extern fn objc_getClass(name: [*c]const u8) Class;
pub extern fn objc_msgSend() void;
