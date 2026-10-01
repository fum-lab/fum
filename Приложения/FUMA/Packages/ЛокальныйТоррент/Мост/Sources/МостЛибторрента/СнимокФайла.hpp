#pragma once
#include "ГраницаИсключений.hpp"
#include "ПримитивыСнимка.hpp"
#include <array>
#include <memory>
#include <string>
#include <sys/stat.h>
#include <vector>

struct СнимокФайла {
    int родитель = -1;
    int каталог = -1;
    int файл = -1;
    int писатель = -1;
    std::string имя_каталога;
    std::string имя_файла;
    bool создан_каталог = false;
    bool создан_файл = false;
    struct stat метка_файла{};
    struct stat метка_каталога{};
    СнимокФайла() = default;
    СнимокФайла(СнимокФайла const&) = delete;
    СнимокФайла& operator=(СнимокФайла const&) = delete;
    ~СнимокФайла() noexcept;
    int дескриптор_файла() const noexcept { return файл; }
    int дескриптор_каталога() const noexcept { return каталог; }
    void удалить_с_проверкой();
    int очистить_по_идентичности() noexcept;
};

std::unique_ptr<СнимокФайла> создать_снимок_файла(
    int исходник, int родитель, char const* имя, size_t длина_имени,
    uint64_t размер, uint64_t максимум, std::array<uint8_t, 32> const& хэш,
    ОперацияТоррента const* операция, ПримитивыСнимка примитивы = {});

struct БайтыМетаданных {
    std::vector<uint8_t> данные;
    std::string хэш_первой_версии;
    std::string хэш_второй_версии;
};
using ПроизводительМетаданных = БайтыМетаданных (*)(void*, СнимокФайла const&);
РезультатГраницыМоста выполнить_создание_метаданных(
    ВходМостаТоррента const* вход, МетаданныеМостаТоррента** адрес, ПроизводительМетаданных производитель,
    void* контекст_производителя = nullptr) noexcept;
