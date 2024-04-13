#include <dawn/native/DawnNative.h>
#include "mach_dawn.h"

#if defined(__APPLE__)
    namespace dawn::native::metal {
        DAWN_NATIVE_EXPORT void WaitForCommandsToBeScheduled(WGPUDevice device);
    }  // namespace dawn::native
#endif  // defined(__APPLE__)

#ifdef __cplusplus
extern "C" {
#endif

MACH_EXPORT const DawnProcTable machDawnGetProcTable() {
    return dawn::native::GetProcs();
}

MACH_EXPORT void machDawnDeviceWaitForCommandsToBeScheduled(WGPUDevice device) {
    #if defined(__APPLE__)
        return dawn::native::metal::WaitForCommandsToBeScheduled(device);
    #else
        return;
    #endif  // defined(__APPLE__)
}

#ifdef __cplusplus
} // extern "C"
#endif