#include "wayland-client-protocol-code.h"
#include "wayland-xdg-shell-client-protocol-code.h"
#include "wayland-xdg-decoration-client-protocol-code.h"

// TODO(aarch64-linux): we have to write varargs code in C due to Zig on aarch64-linux not providing a varargs
// implementation, see https://github.com/ziglang/zig/issues/15389
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include "wayland-client-core.h"
#define MAX_MARSHAL_ARGS 20
typedef struct wl_proxy *(*marshal_array_flags_func_t)(
    struct wl_proxy *proxy, uint32_t opcode,
    const struct wl_interface *interface,
    uint32_t version, uint32_t flags,
    union wl_argument *args);
extern marshal_array_flags_func_t wl_proxy_marshal_array_flags_ptr;
struct wl_proxy *
wl_proxy_marshal_flags(struct wl_proxy *proxy, uint32_t opcode,
                       const struct wl_interface *interface,
                       uint32_t version, uint32_t flags, ...)
{
    union wl_argument args[MAX_MARSHAL_ARGS];
    va_list ap;
    va_start(ap, flags);
    for (int i = 0; i < MAX_MARSHAL_ARGS; i++) {
        args[i].o = va_arg(ap, void *);
        if (args[i].o == NULL)
            break;
    }
    va_end(ap);
    return wl_proxy_marshal_array_flags_ptr(
        proxy, opcode, interface, version, flags, args);
}
// TODO(aarch64-linux): remove the code above
