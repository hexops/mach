#include <pipewire-0.3/pipewire/core.h>
#include <spa-0.2/spa/param/audio/format-utils.h>

struct spa_pod *sysaudio_spa_format_audio_raw_build(struct spa_pod_builder *builder, uint32_t id, struct spa_audio_info_raw *info)
{
	return spa_format_audio_raw_build(builder, id, info);
}

void sysaudio_pw_registry_add_listener(struct pw_registry *reg, struct spa_hook *reg_listener, struct pw_registry_events *events) {
	pw_registry_add_listener(reg, reg_listener, events, NULL);
}