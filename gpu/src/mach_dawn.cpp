#include <dawn/native/DawnNative.h>
#include "dawn_native_mach.h"

#ifdef __cplusplus
extern "C" {
#endif

MACH_EXPORT const DawnProcTable machDawnGetProcTable() {
    return dawn_native::GetProcs();
}

#ifdef __cplusplus
} // extern "C"
#endif