#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef void resize_callback(void*, uint32_t, uint32_t);

typedef enum MachStatus {
    MachStatus_Success = 0x00000000,
    MachStatus_Error = 0x00000001,
    MachStatus_Force32 = 0x7FFFFFFF
} MachStatus;

// `libmach` exported API bindings
void* mach_core_init(void);
void mach_core_deinit(void*);
void mach_core_set_should_close(void*);
bool mach_core_window_should_close(void*);
MachStatus mach_core_update(void*, resize_callback);
float mach_core_delta_time(void*);

void resize_fn(void* core, uint32_t width, uint32_t height) {
  printf("Resize callback: %u %u\n", width, height);
}

static float elapsed = 0;

int main() {
  void* core = mach_core_init();

  if (core == 0) {
    printf("Error instantiating mach core\n");
    return 0;
  }

  while (!mach_core_window_should_close(core)) {
    if (mach_core_update(core, resize_fn) == MachStatus_Error) {
      printf("Error updating Mach\n");
      break;
    };

    elapsed += mach_core_delta_time(core);
    if (elapsed > 5.0) {
      mach_core_set_should_close(core);
    }

    // printf("Elapsed: %f\n", elapsed);
  }

  mach_core_deinit(core);

  return 0;
}
