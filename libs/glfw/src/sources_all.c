// MacOS: this must be defined for macOS 13.3 and older.
#define __kernel_ptr_semantics

// General sources
#include "monitor.c"
#include "init.c"
#include "vulkan.c"
#include "input.c"
#include "osmesa_context.c"
#include "egl_context.c"
#include "context.c"
#include "window.c"
#include "platform.c"
#include "null_init.c"
#include "null_monitor.c"
#include "null_window.c"
#include "null_joystick.c"
