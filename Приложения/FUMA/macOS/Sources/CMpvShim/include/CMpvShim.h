#ifndef FUM_CMPV_SHIM_H
#define FUM_CMPV_SHIM_H

#include <stdint.h>
#include <mpv/client.h>
#include <mpv/render.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*fum_mpv_update_callback)(void *);

int fum_mpv_create_opengl_renderer(mpv_render_context **context, mpv_handle *player);
void fum_mpv_free_renderer(mpv_render_context *context);
void fum_mpv_set_update_callback(mpv_render_context *context, fum_mpv_update_callback callback, void *callback_context);
int fum_mpv_render_opengl(mpv_render_context *context, int width, int height, int flip_y);

int fum_mpv_set_flag_property(mpv_handle *player, const char *name, int value);
int fum_mpv_set_double_property(mpv_handle *player, const char *name, double value);
int fum_mpv_set_string_property(mpv_handle *player, const char *name, const char *value);
int fum_mpv_get_flag_property(mpv_handle *player, const char *name, int *value);
int fum_mpv_get_double_property(mpv_handle *player, const char *name, double *value);
char *fum_mpv_get_string_property(mpv_handle *player, const char *name);
void fum_mpv_free(void *data);

int fum_mpv_load_file(mpv_handle *player, const char *path);
int fum_mpv_add_audio_file(mpv_handle *player, const char *path);
int fum_mpv_add_subtitle_file(mpv_handle *player, const char *path);
int fum_mpv_load_file_async(mpv_handle *player, const char *path);
int fum_mpv_add_audio_file_async(mpv_handle *player, const char *path);
int fum_mpv_add_subtitle_file_async(mpv_handle *player, const char *path);
int fum_mpv_seek_absolute(mpv_handle *player, double seconds);
int fum_mpv_seek_relative(mpv_handle *player, double seconds);
int fum_mpv_stop(mpv_handle *player);
int fum_mpv_poll_event(mpv_handle *player, int *event_id, int *error, uint64_t *reply_userdata);
int fum_mpv_event_is_none(int event_id);
int fum_mpv_event_is_file_loaded(int event_id);

const char *fum_mpv_error_string(int error);

#ifdef __cplusplus
}
#endif

#endif
