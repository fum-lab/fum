#include "СнимокФайла.hpp"
#include <CommonCrypto/CommonDigest.h>
#include <algorithm>
#include <cerrno>
#include <cstring>
#include <cstdlib>
#include <fcntl.h>
#include <limits>
#include <stdexcept>
#include <system_error>
#include <sys/stat.h>
#include <unistd.h>

namespace {
void ошибка_носителя() { throw std::system_error(errno, std::generic_category()); }
void закрыть(int& дескриптор) noexcept {
    if (дескриптор >= 0) { ::close(дескриптор); дескриптор = -1; }
}
bool одинаковы(struct stat const& до, struct stat const& после) {
    return до.st_dev == после.st_dev && до.st_ino == после.st_ino
        && до.st_mode == после.st_mode && до.st_size == после.st_size
        && до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec
        && до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec
        && до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec
        && до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec;
}
void проверить_отмену(ОперацияТоррента const* операция, ПримитивыСнимка const& примитивы) {
    if (запрошена_отмена_торрента(операция)
        || (примитивы.отменено && примитивы.отменено(примитивы.контекст))) throw ОтменаОперацииМоста{};
}
}

СнимокФайла::~СнимокФайла() noexcept {
    очистить_по_идентичности();
}

int СнимокФайла::очистить_по_идентичности() noexcept {
    int отказ = 0;
    if (создан_файл) {
        struct stat именованный{};
        auto исход = ::fstatat(каталог, имя_файла.c_str(), &именованный, AT_SYMLINK_NOFOLLOW);
        if (исход == 0 && метка_файла.st_ino != 0 && именованный.st_dev == метка_файла.st_dev
            && именованный.st_ino == метка_файла.st_ino) {
            if (::unlinkat(каталог, имя_файла.c_str(), 0) != 0) отказ = 1;
        } else if (исход == 0 || errno != ENOENT) отказ = 1;
        создан_файл = false;
    }
    закрыть(файл); закрыть(писатель);
    закрыть(каталог);
    if (создан_каталог) {
        struct stat именованный{};
        auto исход = ::fstatat(родитель, имя_каталога.c_str(), &именованный, AT_SYMLINK_NOFOLLOW);
        if (исход == 0 && метка_каталога.st_ino != 0 && именованный.st_dev == метка_каталога.st_dev
            && именованный.st_ino == метка_каталога.st_ino) {
            if (::unlinkat(родитель, имя_каталога.c_str(), AT_REMOVEDIR) != 0) отказ = 1;
        } else if (исход == 0 || errno != ENOENT) отказ = 1;
        создан_каталог = false;
    }
    закрыть(родитель);
    return отказ;
}

void СнимокФайла::удалить_с_проверкой() {
    if (очистить_по_идентичности() != 0) throw std::runtime_error("не подтверждена очистка собственных объектов снимка");
}

std::unique_ptr<СнимокФайла> создать_снимок_файла(
    int исходник, int родитель, char const* имя, size_t длина_имени,
    uint64_t размер, uint64_t максимум, std::array<uint8_t, 32> const& хэш,
    ОперацияТоррента const* операция, ПримитивыСнимка примитивы) {
    if (!операция || !имя || длина_имени == 0 || длина_имени > 255
        || размер == 0 || размер > максимум || размер > static_cast<uint64_t>(std::numeric_limits<off_t>::max()))
        throw std::invalid_argument("неверный вход снимка");
    std::string имя_файла(имя, длина_имени);
    if (имя_файла == "." || имя_файла == ".." || имя_файла.find('/') != std::string::npos
        || имя_файла.find('\0') != std::string::npos) throw std::invalid_argument("неверное имя снимка");
    struct stat до{}, папка{};
    if (::fstat(исходник, &до) != 0 || ::fstat(родитель, &папка) != 0) ошибка_носителя();
    int флаги = ::fcntl(исходник, F_GETFL);
    if (!S_ISREG(до.st_mode) || !S_ISDIR(папка.st_mode) || до.st_size < 0
        || static_cast<uint64_t>(до.st_size) != размер || флаги < 0 || (флаги & O_ACCMODE) != O_RDONLY)
        throw std::invalid_argument("неверные дескрипторы или размер снимка");
    проверить_отмену(операция, примитивы);
    auto снимок = std::make_unique<СнимокФайла>();
    снимок->имя_файла = имя_файла;
    снимок->родитель = ::fcntl(родитель, F_DUPFD_CLOEXEC, 0);
    if (снимок->родитель < 0) ошибка_носителя();
    for (unsigned попытка = 0; попытка < 128; ++попытка) {
        std::array<uint8_t, 16> случайные{};
        ::arc4random_buf(случайные.data(), случайные.size());
        std::string имя_каталога = "снимок-";
        char const* цифры = "0123456789abcdef";
        for (auto байт : случайные) { имя_каталога += цифры[байт >> 4]; имя_каталога += цифры[байт & 15]; }
        снимок->имя_каталога = имя_каталога;
        if (::mkdirat(снимок->родитель, имя_каталога.c_str(), 0700) == 0) { снимок->создан_каталог = true; break; }
        if (errno != EEXIST) ошибка_носителя();
    }
    if (!снимок->создан_каталог) throw std::runtime_error("не удалось выбрать имя каталога");
    снимок->каталог = ::openat(снимок->родитель, снимок->имя_каталога.c_str(), O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW);
    if (снимок->каталог < 0) ошибка_носителя();
    if (::fstat(снимок->каталог, &снимок->метка_каталога) != 0) ошибка_носителя();
    if (::fchmod(снимок->каталог, 0700) != 0) ошибка_носителя();
    снимок->писатель = ::openat(снимок->каталог, имя_файла.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (снимок->писатель < 0) ошибка_носителя();
    снимок->создан_файл = true;
    if (::fstat(снимок->писатель, &снимок->метка_файла) != 0) ошибка_носителя();
    CC_SHA256_CTX вычислитель{};
    if (CC_SHA256_Init(&вычислитель) != 1) throw std::runtime_error("отказ SHA-256");
    std::array<uint8_t, 65536> буфер{};
    uint64_t позиция = 0;
    while (позиция < размер) {
        проверить_отмену(операция, примитивы);
        auto длина = static_cast<size_t>(std::min<uint64_t>(буфер.size(), размер - позиция));
        auto прочитано = примитивы.прочитать ? примитивы.прочитать(примитивы.контекст, исходник, буфер.data(), длина, static_cast<off_t>(позиция))
            : ::pread(исходник, буфер.data(), длина, static_cast<off_t>(позиция));
        if (прочитано < 0 && errno == EINTR) continue;
        if (прочитано < 0) ошибка_носителя();
        if (прочитано == 0 || static_cast<size_t>(прочитано) > длина) throw std::runtime_error("неполный источник");
        size_t записано = 0;
        while (записано < static_cast<size_t>(прочитано)) {
            проверить_отмену(операция, примитивы);
            auto остаток = static_cast<size_t>(прочитано) - записано;
            auto принято = примитивы.записать ? примитивы.записать(примитивы.контекст, снимок->писатель, буфер.data() + записано, остаток, static_cast<off_t>(позиция + записано))
                : ::pwrite(снимок->писатель, буфер.data() + записано, остаток, static_cast<off_t>(позиция + записано));
            if (принято < 0 && errno == EINTR) continue;
            if (принято < 0) ошибка_носителя();
            if (принято == 0 || static_cast<size_t>(принято) > остаток) throw std::runtime_error("неполная запись снимка");
            записано += static_cast<size_t>(принято);
        }
        if (CC_SHA256_Update(&вычислитель, буфер.data(), static_cast<CC_LONG>(прочитано)) != 1) throw std::runtime_error("отказ SHA-256");
        позиция += static_cast<uint64_t>(прочитано);
    }
    uint8_t лишний{};
    ssize_t хвост;
    do {
        проверить_отмену(операция, примитивы);
        хвост = примитивы.прочитать ? примитивы.прочитать(примитивы.контекст, исходник, &лишний, 1, static_cast<off_t>(размер))
            : ::pread(исходник, &лишний, 1, static_cast<off_t>(размер));
    } while (хвост < 0 && errno == EINTR);
    if (хвост < 0) ошибка_носителя();
    struct stat после{};
    if (::fstat(исходник, &после) != 0) ошибка_носителя();
    std::array<uint8_t, 32> фактический{};
    if (CC_SHA256_Final(фактический.data(), &вычислитель) != 1) throw std::runtime_error("отказ SHA-256");
    if (хвост != 0 || !одинаковы(до, после) || фактический != хэш) throw std::runtime_error("источник или хэш изменился");
    проверить_отмену(операция, примитивы);
    if (::fsync(снимок->писатель) != 0 || ::fchmod(снимок->писатель, 0400) != 0) ошибка_носителя();
    снимок->файл = ::openat(снимок->каталог, имя_файла.c_str(), O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK);
    if (снимок->файл < 0) ошибка_носителя();
    struct stat запись{}, чтение{}, именованный{};
    if (::fstat(снимок->писатель, &запись) != 0 || ::fstat(снимок->файл, &чтение) != 0
        || ::fstatat(снимок->каталог, имя_файла.c_str(), &именованный, AT_SYMLINK_NOFOLLOW) != 0) ошибка_носителя();
    if (!одинаковы(запись, чтение) || !одинаковы(чтение, именованный)
        || !S_ISREG(чтение.st_mode) || (чтение.st_mode & 07777) != 0400
        || static_cast<uint64_t>(чтение.st_size) != размер
        || (чтение.st_dev == до.st_dev && чтение.st_ino == до.st_ino)) throw std::runtime_error("снимок подменён");
    закрыть(снимок->писатель);
    // Проверяем настоящие байты готового readonly FD независимо от write seam.
    if (CC_SHA256_Init(&вычислитель) != 1) throw std::runtime_error("отказ SHA-256");
    позиция = 0;
    while (позиция < размер) {
        проверить_отмену(операция, примитивы);
        auto длина = static_cast<size_t>(std::min<uint64_t>(буфер.size(), размер - позиция));
        auto прочитано = ::pread(снимок->файл, буфер.data(), длина, static_cast<off_t>(позиция));
        if (прочитано < 0 && errno == EINTR) continue;
        if (прочитано < 0) ошибка_носителя();
        if (прочитано == 0) throw std::runtime_error("готовый снимок неполон");
        if (CC_SHA256_Update(&вычислитель, буфер.data(), static_cast<CC_LONG>(прочитано)) != 1) throw std::runtime_error("отказ SHA-256");
        позиция += static_cast<uint64_t>(прочитано);
    }
    if (CC_SHA256_Final(фактический.data(), &вычислитель) != 1) throw std::runtime_error("отказ SHA-256");
    if (::fstat(снимок->файл, &после) != 0) ошибка_носителя();
    if (!одинаковы(чтение, после) || фактический != хэш) throw std::runtime_error("готовый снимок изменился");
    проверить_отмену(операция, примитивы);
    return снимок;
}
