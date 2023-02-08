#ifndef MACHCORE_H_
#define MACHCORE_H_

#if defined(MACHCORE_SHARED_LIBRARY)
#    if defined(_WIN32)
#        if defined(MACHCORE_IMPLEMENTATION)
#            define MACHCORE_EXPORT __declspec(dllexport)
#        else
#            define MACHCORE_EXPORT __declspec(dllimport)
#        endif
#    else  // defined(_WIN32)
#        if defined(MACHCORE_IMPLEMENTATION)
#            define MACHCORE_EXPORT __attribute__((visibility("default")))
#        else
#            define MACHCORE_EXPORT
#        endif
#    endif  // defined(_WIN32)
#else       // defined(MACHCORE_SHARED_LIBRARY)
#    define MACHCORE_EXPORT
#endif  // defined(MACHCORE_SHARED_LIBRARY)

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

typedef struct MachCoreInstanceImpl MachCoreInstance;

typedef struct MachCoreEventIteratorImpl {
    unsigned char _data[8];
} MachCoreEventIterator;

MachCoreInstance* mach_core_init();
void mach_core_deinit(MachCoreInstance* core);
MachCoreEventIterator mach_core_poll_events(MachCoreInstance* core);


#endif // MACHCORE_H_