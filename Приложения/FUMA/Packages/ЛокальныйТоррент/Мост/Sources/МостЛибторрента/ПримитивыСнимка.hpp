#pragma once
#include <sys/types.h>
#include <cstddef>

// Заимствованный контекст и функции действуют только до возврата фабрики.
struct ПримитивыСнимка {
    void* контекст = nullptr;
    ssize_t (*прочитать)(void*, int, void*, size_t, off_t) = nullptr;
    ssize_t (*записать)(void*, int, void const*, size_t, off_t) = nullptr;
    int (*отменено)(void*) = nullptr;
};
