#include <assert.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static int символ;
static int библиотека;
static int открытия;
static void *получить_символ(void *область, const char *имя) {
    return область == &библиотека || strcmp(имя, "available") == 0 ? &символ : NULL;
}
static void *открыть_библиотеку(const char *имя, int режим) {
    (void)режим;
    открытия++;
    return strcmp(имя, "fixture-opengl") == 0 ? &библиотека : NULL;
}

/* Подменены только загрузчик и поиск символа; ни mpv, ни OpenGL не запускаются. */
#define dlsym получить_символ
#define dlopen открыть_библиотеку
#include "../Sources/CMpvShim/CMpvShim.c"
#undef dlsym
#undef dlopen

static unsigned long long время_нс(void) {
    struct timespec значение;
    assert(clock_gettime(CLOCK_MONOTONIC, &значение) == 0);
    return (unsigned long long)значение.tv_sec * 1000000000ULL + значение.tv_nsec;
}

int main(void) {
    unsetenv("FUM_OPENGL_LIBRARY");
    assert(fum_mpv_get_proc_address(NULL, "missing") == NULL);
    assert(открытия == 0);
    assert(fum_mpv_get_proc_address(NULL, "available") == &символ);
    assert(открытия == 0);
    assert(setenv("FUM_OPENGL_LIBRARY", "fixture-opengl", 1) == 0);
    assert(fum_mpv_get_proc_address(NULL, "missing") == &символ);
    assert(открытия == 1);
    unsigned long long начало = время_нс();
    for (int номер = 0; номер < 100000; номер++) {
        assert(fum_mpv_get_proc_address(NULL, "available") == &символ);
    }
    unsigned long long середина = время_нс();
    for (int номер = 0; номер < 100000; номер++) {
        assert(fum_mpv_get_proc_address(NULL, "missing") == &символ);
    }
    unsigned long long конец = время_нс();
    assert(открытия == 1);
    printf("{\"схема\":\"fum.профиль-C-адаптера.1\",\"повторения\":100000,\"поиск_по_умолчанию_нс\":%llu,\"явная_библиотека_нс\":%llu}\n",
           середина - начало, конец - середина);
    return 0;
}
