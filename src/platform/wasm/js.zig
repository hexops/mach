pub const CanvasId = u32;

pub extern "mach" fn machLogWrite(str: [*]const u8, len: u32) void;
pub extern "mach" fn machLogFlush() void;
pub extern "mach" fn machPanic(str: [*]const u8, len: u32) void;

pub extern "mach" fn machCanvasInit(selector_id: *u8) CanvasId;
pub extern "mach" fn machCanvasDeinit(canvas: CanvasId) void;
pub extern "mach" fn machCanvasFramebufferWidth(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasFramebufferHeight(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasSetTitle(canvas: CanvasId, title: [*]const u8, len: u32) void;
pub extern "mach" fn machCanvasSetDisplayMode(canvas: CanvasId, mode: u32) void;
pub extern "mach" fn machCanvasDisplayMode(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasSetBorder(canvas: CanvasId, value: bool) void;
pub extern "mach" fn machCanvasBorder(canvas: CanvasId) bool;
pub extern "mach" fn machCanvasSetHeadless(canvas: CanvasId, value: bool) void;
pub extern "mach" fn machCanvasHeadless(canvas: CanvasId) bool;
pub extern "mach" fn machCanvasSetVsync(canvas: CanvasId, mode: u32) void;
pub extern "mach" fn machCanvasVsync(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasSetSize(canvas: CanvasId, width: u32, height: u32) void;
pub extern "mach" fn machCanvasWidth(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasHeight(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasSetSizeLimit(canvas: CanvasId, min_width: i32, min_height: i32, max_width: i32, max_height: i32) void;
pub extern "mach" fn machCanvasMinWidth(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasMinHeight(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasMaxWidth(canvas: CanvasId) u32;
pub extern "mach" fn machCanvasMaxHeight(canvas: CanvasId) u32;
pub extern "mach" fn machSetCursorMode(canvas: CanvasId, mode: u32) void;
pub extern "mach" fn machCursorMode(canvas: CanvasId) u32;
pub extern "mach" fn machSetCursorShape(canvas: CanvasId, shape: u32) void;
pub extern "mach" fn machCursorShape(canvas: CanvasId) u32;

pub extern "mach" fn machShouldClose() bool;
pub extern "mach" fn machHasEvent() bool;
pub extern "mach" fn machSetWaitTimeout(timeout: f64) void;
pub extern "mach" fn machEventShift() i32;
pub extern "mach" fn machEventShiftFloat() f64;
pub extern "mach" fn machChangeShift() u32;

pub extern "mach" fn machPerfNow() f64;
