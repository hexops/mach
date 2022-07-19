#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef void resize_callback(void*, uint32_t, uint32_t);

// `libmach` exported API bindings
void* mach_init_core(void);
void mach_deinit(void*);
void mach_set_should_close(void*);
bool mach_window_should_close(void*);
int mach_update(void*, resize_callback);
float mach_delta_time(void*);

void resize_fn(void* core, uint32_t width, uint32_t height) {
  printf("Resize callback: %u %u\n", width, height);
}

static float elapsed = 0;

int main() {
  void* core = mach_init_core();

  if (core == 0) {
    printf("Error instantiating mach core\n");
    return 0;
  }

  while (!mach_window_should_close(core)) {
    if (mach_update(core, resize_fn) == 0) {
      printf("Error updating Mach\n");
      break;
    };

    elapsed += mach_delta_time(core);
    if (elapsed > 5.0) {
      mach_set_should_close(core);
    }

    // printf("Elapsed: %f\n", elapsed);
  }

  mach_deinit(core);

  return 0;
}
