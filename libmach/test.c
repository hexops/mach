#include <stdio.h>
#include <stdlib.h>

typedef void mach_core_callback(void*);

// `libmach` exported API bindings
void mach_core_set_init(mach_core_callback);
void mach_core_set_update(mach_core_callback);
void mach_core_set_deinit(mach_core_callback);
void mach_run(void);
void core_set_should_close(void*);
float core_delta_time(void*);

static float elapsed = 0;

void my_init(void* core) {
  printf("My init!\n");
}

void my_update(void* core) {
  float dt = core_delta_time(core);
  if (elapsed < 1.0) {
    elapsed += dt;
  } else {
    core_set_should_close(core);
  }
  printf("My update! total time = %f\n", elapsed);
}

void my_deinit(void* core) {
  printf("My deinit!\n");
}

int main() {
  mach_core_set_init(my_init);
  mach_core_set_update(my_update);
  mach_core_set_deinit(my_deinit);
  mach_run();
  return 0;
}
