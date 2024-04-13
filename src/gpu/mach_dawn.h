#ifndef MACH_DAWN_C_H_
#define MACH_DAWN_C_H_

#ifdef __cplusplus
extern "C" {
#endif

#if defined(MACH_DAWN_C_SHARED_LIBRARY)
#    if defined(_WIN32)
#        if defined(MACH_DAWN_C_IMPLEMENTATION)
#            define MACH_EXPORT __declspec(dllexport)
#        else
#            define MACH_EXPORT __declspec(dllimport)
#        endif
#    else  // defined(_WIN32)
#        if defined(MACH_DAWN_C_IMPLEMENTATION)
#            define MACH_EXPORT __attribute__((visibility("default")))
#        else
#            define MACH_EXPORT
#        endif
#    endif  // defined(_WIN32)
#else       // defined(MACH_DAWN_C_SHARED_LIBRARY)
#    define MACH_EXPORT
#endif  // defined(MACH_DAWN_C_SHARED_LIBRARY)

#include <dawn/webgpu.h>
#include <dawn/dawn_proc_table.h>

MACH_EXPORT const DawnProcTable machDawnGetProcTable();
MACH_EXPORT void machDawnDeviceWaitForCommandsToBeScheduled(WGPUDevice device);

#ifdef __cplusplus
} // extern "C"
#endif

#endif  // MACH_DAWN_C_H_
