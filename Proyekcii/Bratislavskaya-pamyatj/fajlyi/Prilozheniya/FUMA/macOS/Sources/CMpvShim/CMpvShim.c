#include "CMpvShim.h"

#include <OpenGL/gl3.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <mpv/render_gl.h>

static void *fum_mpv_get_proc_address(void *context, const char *name) {
    (void)context;
    static void *opengl = NULL;
    void *symbol = dlsym(RTLD_DEFAULT, name);
    if (!symbol) {
        if (!opengl) {
            const char *путь = getenv("FUM_OPENGL_LIBRARY");
            if (путь && путь[0]) {
                opengl = dlopen(путь, RTLD_LAZY | RTLD_LOCAL);
            }
        }
        if (opengl) {
            symbol = dlsym(opengl, name);
        }
    }
    return symbol;
}

int fum_mpv_create_opengl_renderer(mpv_render_context **context, mpv_handle *player) {
    mpv_opengl_init_params gl_init = {
        .get_proc_address = fum_mpv_get_proc_address,
        .get_proc_address_ctx = NULL
    };
    mpv_render_param params[] = {
        { MPV_RENDER_PARAM_API_TYPE, (void *)MPV_RENDER_API_TYPE_OPENGL },
        { MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init },
        { MPV_RENDER_PARAM_INVALID, NULL }
    };
    return mpv_render_context_create(context, player, params);
}

void fum_mpv_free_renderer(mpv_render_context *context) {
    if (context) {
        mpv_render_context_free(context);
    }
}

void fum_mpv_set_update_callback(mpv_render_context *context, fum_mpv_update_callback callback, void *callback_context) {
    if (context) {
        mpv_render_context_set_update_callback(context, callback, callback_context);
    }
}

int fum_mpv_render_opengl(mpv_render_context *context, int width, int height, int flip_y) {
    if (!context || width <= 0 || height <= 0) {
        return MPV_ERROR_INVALID_PARAMETER;
    }

    mpv_render_context_update(context);

    mpv_opengl_fbo fbo = {
        .fbo = 0,
        .w = width,
        .h = height,
        .internal_format = GL_RGBA8
    };
    int flip = flip_y;
    mpv_render_param params[] = {
        { MPV_RENDER_PARAM_OPENGL_FBO, &fbo },
        { MPV_RENDER_PARAM_FLIP_Y, &flip },
        { MPV_RENDER_PARAM_INVALID, NULL }
    };
    return mpv_render_context_render(context, params);
}

int fum_mpv_set_flag_property(mpv_handle *player, const char *name, int value) {
    return mpv_set_property(player, name, MPV_FORMAT_FLAG, &value);
}

int fum_mpv_set_double_property(mpv_handle *player, const char *name, double value) {
    return mpv_set_property(player, name, MPV_FORMAT_DOUBLE, &value);
}

int fum_mpv_set_string_property(mpv_handle *player, const char *name, const char *value) {
    return mpv_set_property_string(player, name, value);
}

int fum_mpv_get_flag_property(mpv_handle *player, const char *name, int *value) {
    return mpv_get_property(player, name, MPV_FORMAT_FLAG, value);
}

int fum_mpv_get_double_property(mpv_handle *player, const char *name, double *value) {
    return mpv_get_property(player, name, MPV_FORMAT_DOUBLE, value);
}

char *fum_mpv_get_string_property(mpv_handle *player, const char *name) {
    return mpv_get_property_string(player, name);
}

void fum_mpv_free(void *data) {
    mpv_free(data);
}

int fum_mpv_load_file(mpv_handle *player, const char *path) {
    const char *args[] = { "loadfile", path, "replace", NULL };
    return mpv_command(player, args);
}

int fum_mpv_add_audio_file(mpv_handle *player, const char *path) {
    const char *args[] = { "audio-add", path, "select", NULL };
    return mpv_command(player, args);
}

int fum_mpv_add_subtitle_file(mpv_handle *player, const char *path) {
    const char *args[] = { "sub-add", path, "select", NULL };
    return mpv_command(player, args);
}

int fum_mpv_load_file_async(mpv_handle *player, const char *path) {
    const char *args[] = { "loadfile", path, "replace", NULL };
    return mpv_command_async(player, 0, args);
}

int fum_mpv_add_audio_file_async(mpv_handle *player, const char *path) {
    const char *args[] = { "audio-add", path, "select", NULL };
    return mpv_command_async(player, 0, args);
}

int fum_mpv_add_subtitle_file_async(mpv_handle *player, const char *path) {
    const char *args[] = { "sub-add", path, "select", NULL };
    return mpv_command_async(player, 0, args);
}

int fum_mpv_seek_absolute(mpv_handle *player, double seconds) {
    char buffer[64];
    snprintf(buffer, sizeof(buffer), "%.3f", seconds);
    const char *args[] = { "seek", buffer, "absolute", "exact", NULL };
    return mpv_command(player, args);
}

int fum_mpv_seek_relative(mpv_handle *player, double seconds) {
    char buffer[64];
    snprintf(buffer, sizeof(buffer), "%.3f", seconds);
    const char *args[] = { "seek", buffer, "relative", "exact", NULL };
    return mpv_command(player, args);
}

int fum_mpv_stop(mpv_handle *player) {
    const char *args[] = { "stop", NULL };
    return mpv_command(player, args);
}

int fum_mpv_poll_event(mpv_handle *player, int *event_id, int *error, uint64_t *reply_userdata) {
    if (!player || !event_id || !error || !reply_userdata) {
        return MPV_ERROR_INVALID_PARAMETER;
    }

    mpv_event *event = mpv_wait_event(player, 0);
    if (!event) {
        return MPV_ERROR_INVALID_PARAMETER;
    }

    *event_id = (int)event->event_id;
    *error = event->error;
    *reply_userdata = event->reply_userdata;
    return 0;
}

int fum_mpv_event_is_none(int event_id) {
    return event_id == MPV_EVENT_NONE;
}

int fum_mpv_event_is_file_loaded(int event_id) {
    return event_id == MPV_EVENT_FILE_LOADED;
}

const char *fum_mpv_error_string(int error) {
    return mpv_error_string(error);
}
