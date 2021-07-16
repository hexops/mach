//! Keyboard key IDs.
//!
//! See glfw.setKeyCallback for how these are used.
//!
//! These key codes are inspired by the _USB HID Usage Tables v1.12_ (p. 53-60), but re-arranged to
//! map to 7-bit ASCII for printable keys (function keys are put in the 256+ range).
//!
//! The naming of the key codes follow these rules:
//!
//! - The US keyboard layout is used
//! - Names of printable alpha-numeric characters are used (e.g. "A", "R", "3", etc.)
//! - For non-alphanumeric characters, Unicode:ish names are used (e.g. "COMMA",
//!   "LEFT_SQUARE_BRACKET", etc.). Note that some names do not correspond to the Unicode standard
//!   (usually for brevity)
//! - Keys that lack a clear US mapping are named "WORLD_x"
//! - For non-printable keys, custom names are used (e.g. "F4", "BACKSPACE", etc.)

const c = @cImport(@cInclude("GLFW/glfw3.h"));

/// The unknown key
pub const unknown = C.GLFW_KEY_UNKNOWN;

/// Printable keys
pub const space = C.GLFW_KEY_SPACE;
pub const apostrophe = C.GLFW_KEY_APOSTROPHE;
pub const comma = C.GLFW_KEY_COMMA;
pub const minus = C.GLFW_KEY_MINUS;
pub const period = C.GLFW_KEY_PERIOD;
pub const slash = C.GLFW_KEY_SLASH;
pub const zero = C.GLFW_KEY_0;
pub const one = C.GLFW_KEY_1;
pub const two = C.GLFW_KEY_2;
pub const three = C.GLFW_KEY_3;
pub const four = C.GLFW_KEY_4;
pub const five = C.GLFW_KEY_5;
pub const six = C.GLFW_KEY_6;
pub const seven = C.GLFW_KEY_7;
pub const eight = C.GLFW_KEY_8;
pub const nine = C.GLFW_KEY_9;
pub const semicolon = C.GLFW_KEY_SEMICOLON;
pub const equal = C.GLFW_KEY_EQUAL;
pub const a = C.GLFW_KEY_A;
pub const b = C.GLFW_KEY_B;
pub const c = C.GLFW_KEY_C;
pub const d = C.GLFW_KEY_D;
pub const e = C.GLFW_KEY_E;
pub const f = C.GLFW_KEY_F;
pub const g = C.GLFW_KEY_G;
pub const h = C.GLFW_KEY_H;
pub const i = C.GLFW_KEY_I;
pub const j = C.GLFW_KEY_J;
pub const k = C.GLFW_KEY_K;
pub const l = C.GLFW_KEY_L;
pub const m = C.GLFW_KEY_M;
pub const n = C.GLFW_KEY_N;
pub const o = C.GLFW_KEY_O;
pub const p = C.GLFW_KEY_P;
pub const q = C.GLFW_KEY_Q;
pub const r = C.GLFW_KEY_R;
pub const s = C.GLFW_KEY_S;
pub const t = C.GLFW_KEY_T;
pub const u = C.GLFW_KEY_U;
pub const v = C.GLFW_KEY_V;
pub const w = C.GLFW_KEY_W;
pub const x = C.GLFW_KEY_X;
pub const y = C.GLFW_KEY_Y;
pub const z = C.GLFW_KEY_Z;
pub const left_bracket = C.GLFW_KEY_LEFT_BRACKET;
pub const backslash = C.GLFW_KEY_BACKSLASH;
pub const right_bracket = C.GLFW_KEY_RIGHT_BRACKET;
pub const grave_accent = C.GLFW_KEY_GRAVE_ACCENT;
pub const world_1 = C.GLFW_KEY_WORLD_1; // non-US #1
pub const world_2 = C.GLFW_KEY_WORLD_2; // non-US #2

/// Function keys
pub const escape = C.GLFW_KEY_ESCAPE;
pub const enter = C.GLFW_KEY_ENTER;
pub const tab = C.GLFW_KEY_TAB;
pub const backspace = C.GLFW_KEY_BACKSPACE;
pub const insert = C.GLFW_KEY_INSERT;
pub const delete = C.GLFW_KEY_DELETE;
pub const right = C.GLFW_KEY_RIGHT;
pub const left = C.GLFW_KEY_LEFT;
pub const down = C.GLFW_KEY_DOWN;
pub const up = C.GLFW_KEY_UP;
pub const page_up = C.GLFW_KEY_PAGE_UP;
pub const page_down = C.GLFW_KEY_PAGE_DOWN;
pub const home = C.GLFW_KEY_HOME;
pub const end = C.GLFW_KEY_END;
pub const caps_lock = C.GLFW_KEY_CAPS_LOCK;
pub const scroll_lock = C.GLFW_KEY_SCROLL_LOCK;
pub const num_lock = C.GLFW_KEY_NUM_LOCK;
pub const print_screen = C.GLFW_KEY_PRINT_SCREEN;
pub const pause = C.GLFW_KEY_PAUSE;
pub const F1 = C.GLFW_KEY_F1;
pub const F2 = C.GLFW_KEY_F2;
pub const F3 = C.GLFW_KEY_F3;
pub const F4 = C.GLFW_KEY_F4;
pub const F5 = C.GLFW_KEY_F5;
pub const F6 = C.GLFW_KEY_F6;
pub const F7 = C.GLFW_KEY_F7;
pub const F8 = C.GLFW_KEY_F8;
pub const F9 = C.GLFW_KEY_F9;
pub const F10 = C.GLFW_KEY_F10;
pub const F11 = C.GLFW_KEY_F11;
pub const F12 = C.GLFW_KEY_F12;
pub const F13 = C.GLFW_KEY_F13;
pub const F14 = C.GLFW_KEY_F14;
pub const F15 = C.GLFW_KEY_F15;
pub const F16 = C.GLFW_KEY_F16;
pub const F17 = C.GLFW_KEY_F17;
pub const F18 = C.GLFW_KEY_F18;
pub const F19 = C.GLFW_KEY_F19;
pub const F20 = C.GLFW_KEY_F20;
pub const F21 = C.GLFW_KEY_F21;
pub const F22 = C.GLFW_KEY_F22;
pub const F23 = C.GLFW_KEY_F23;
pub const F24 = C.GLFW_KEY_F24;
pub const F25 = C.GLFW_KEY_F25;
pub const kp_0 = C.GLFW_KEY_KP_0;
pub const kp_1 = C.GLFW_KEY_KP_1;
pub const kp_2 = C.GLFW_KEY_KP_2;
pub const kp_3 = C.GLFW_KEY_KP_3;
pub const kp_4 = C.GLFW_KEY_KP_4;
pub const kp_5 = C.GLFW_KEY_KP_5;
pub const kp_6 = C.GLFW_KEY_KP_6;
pub const kp_7 = C.GLFW_KEY_KP_7;
pub const kp_8 = C.GLFW_KEY_KP_8;
pub const kp_9 = C.GLFW_KEY_KP_9;
pub const kp_decimal = C.GLFW_KEY_KP_DECIMAL;
pub const kp_divide = C.GLFW_KEY_KP_DIVIDE;
pub const kp_multiply = C.GLFW_KEY_KP_MULTIPLY;
pub const kp_subtract = C.GLFW_KEY_KP_SUBTRACT;
pub const kp_add = C.GLFW_KEY_KP_ADD;
pub const kp_enter = C.GLFW_KEY_KP_ENTER;
pub const kp_equal = C.GLFW_KEY_KP_EQUAL;
pub const left_shift = C.GLFW_KEY_LEFT_SHIFT;
pub const left_control = C.GLFW_KEY_LEFT_CONTROL;
pub const left_alt = C.GLFW_KEY_LEFT_ALT;
pub const left_super = C.GLFW_KEY_LEFT_SUPER;
pub const right_shift = C.GLFW_KEY_RIGHT_SHIFT;
pub const right_control = C.GLFW_KEY_RIGHT_CONTROL;
pub const right_alt = C.GLFW_KEY_RIGHT_ALT;
pub const right_super = C.GLFW_KEY_RIGHT_SUPER;
pub const menu = C.GLFW_KEY_MENU;

pub const last = C.GLFW_KEY_LAST;
