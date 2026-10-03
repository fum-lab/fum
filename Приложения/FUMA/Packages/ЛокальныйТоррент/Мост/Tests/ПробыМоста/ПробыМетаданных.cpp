extern "C" {
#include "include/ПробыМетаданных.h"
}
#include "../../Sources/МостЛибторрента/СнимокФайла.hpp"
#include <stdexcept>
#include <CommonCrypto/CommonDigest.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/param.h>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/bencode.hpp>
#include <libtorrent/create_torrent.hpp>
#include <libtorrent/file_storage.hpp>
#include <libtorrent/load_torrent.hpp>
#include <libtorrent/posix_disk_io.hpp>
#include <libtorrent/settings_pack.hpp>
#include <libtorrent/torrent_info.hpp>
#include <libtorrent/span.hpp>

#include <limits>

extern "C" int32_t прочитать_путь_каталога_фикстуры(int32_t каталог, char* путь, size_t ёмкость) {
    if (!путь || ёмкость < MAXPATHLEN) return -1;
    return ::fcntl(каталог, F_GETPATH, путь);
}

extern "C" РезультатГраницыМоста создать_полную_фикстуру_метаданных(
    ВходМостаТоррента const* вход, МетаданныеМостаТоррента** адрес) {
    return выполнить_создание_метаданных(вход, адрес, [](void* контекст, СнимокФайла const& снимок) {
        if (static_cast<ВходМостаТоррента const*>(контекст)->длина_части != 16384)
            throw std::invalid_argument("полная фикстура поддерживает длину части 16384");
        char содержимое[4]{};
        if (pread(снимок.дескриптор_файла(), содержимое, 4, 0) != 3
            || std::string(содержимое, 3) != "abc" || снимок.имя_файла != "a")
            throw std::runtime_error("полная фикстура поддерживает только файл a с байтами abc");
        uint8_t хэш_содержимого_первый[20]{}, корень[32]{};
        if (!CC_SHA1("abc", 3, хэш_содержимого_первый) || !CC_SHA256("abc", 3, корень)) throw std::runtime_error("отказ SHA фикстуры");
        std::string информация = "d9:file treed1:ad0:d6:lengthi3e11:pieces root32:";
        информация.append(reinterpret_cast<char const*>(корень), 32);
        информация += "eee6:lengthi3e12:meta versioni2e4:name1:a12:piece lengthi16384e6:pieces20:";
        информация.append(reinterpret_cast<char const*>(хэш_содержимого_первый), 20); информация += "e";
        uint8_t первый[20]{}, второй[32]{};
        if (!CC_SHA1(информация.data(), static_cast<CC_LONG>(информация.size()), первый)
            || !CC_SHA256(информация.data(), static_cast<CC_LONG>(информация.size()), второй)) throw std::runtime_error("отказ infohash фикстуры");
        auto шестнадцатеричный = [](uint8_t const* хэш, size_t длина) {
            std::string результат; char const* цифры = "0123456789abcdef";
            for (size_t номер = 0; номер < длина; ++номер) { результат += цифры[хэш[номер] >> 4]; результат += цифры[хэш[номер] & 15]; }
            return результат;
        };
        auto данные = "d4:info" + информация + "12:piece layersdee";
        return БайтыМетаданных{std::vector<uint8_t>(данные.begin(), данные.end()),
            шестнадцатеричный(первый, 20), шестнадцатеричный(второй, 32)};
    }, const_cast<ВходМостаТоррента*>(вход));
}

struct КонтекстФикстурыМетаданных { ВходМостаТоррента const* вход; int32_t случай; };

extern "C" РезультатГраницыМоста создать_фикстуру_метаданных(
    ВходМостаТоррента const* вход, МетаданныеМостаТоррента** адрес) {
    return создать_фикстуру_метаданных_с_отказом(вход, адрес, 0);
}
extern "C" РезультатГраницыМоста создать_фикстуру_метаданных_с_отказом(
    ВходМостаТоррента const* вход, МетаданныеМостаТоррента** адрес, int32_t случай) {
    КонтекстФикстурыМетаданных контекст{вход, случай};
    return выполнить_создание_метаданных(вход, адрес, [](void* указатель, СнимокФайла const& снимок) {
        auto const& контекст = *static_cast<КонтекстФикстурыМетаданных const*>(указатель);
        auto случай = контекст.случай;
        if (снимок.дескриптор_файла() < 0) throw std::runtime_error("провайдер не получил настоящий снимок");
        if (случай == 1) throw std::runtime_error("отказ провайдера");
        if (случай == 2) throw std::bad_alloc{};
        if (случай == 3) отменить_операцию_торрента(контекст.вход->операция);
        if (случай == 8) throw 42;
        БайтыМетаданных результат{{100, 101}, std::string(40, 'a'), std::string(64, 'b')};
        if (случай == 4) результат.хэш_первой_версии = "не hex";
        if (случай == 5) результат.данные.clear();
        return результат;
    }, &контекст);
}

struct ПрямыеМетаданныеЛибторрента {
    std::vector<uint8_t> данные;
    std::string первый;
    std::string второй;
};

namespace {
std::string прямое_представление_хэша(std::string const& байты) {
    std::string результат;
    char const* цифры = "0123456789abcdef";
    for (unsigned char байт : байты) {
        результат.push_back(цифры[байт / 16]);
        результат.push_back(цифры[байт % 16]);
    }
    return результат;
}

bool неизменная_прямая_метка(
    struct stat const& раньше, struct stat const& сейчас) {
    return раньше.st_dev == сейчас.st_dev
        && раньше.st_ino == сейчас.st_ino
        && раньше.st_mode == сейчас.st_mode
        && раньше.st_nlink == сейчас.st_nlink
        && раньше.st_size == сейчас.st_size
        && раньше.st_mtimespec.tv_sec == сейчас.st_mtimespec.tv_sec
        && раньше.st_mtimespec.tv_nsec == сейчас.st_mtimespec.tv_nsec
        && раньше.st_ctimespec.tv_sec == сейчас.st_ctimespec.tv_sec
        && раньше.st_ctimespec.tv_nsec == сейчас.st_ctimespec.tv_nsec;
}
}

extern "C" РезультатГраницыМоста прямо_создать_метаданные_либторрента(
    char const* путь_каталога, size_t длина_пути,
    char const* имя, size_t длина_имени,
    uint64_t размер, uint64_t длина_части, uint64_t максимум_метаданных,
    ПрямыеМетаданныеЛибторрента** адрес) {
    return выполнить_без_исключений([&] {
        if (!адрес || *адрес || !путь_каталога || !имя
            || длина_пути == 0 || длина_пути >= MAXPATHLEN
            || длина_имени == 0 || длина_имени > 255
            || размер == 0
            || размер > static_cast<uint64_t>(libtorrent::file_storage::max_file_size)
            || длина_части < 16384 || длина_части > 128 * 1024 * 1024
            || (длина_части & (длина_части - 1)) != 0
            || размер > static_cast<uint64_t>(std::numeric_limits<int64_t>::max())
                             - (длина_части - 1))
            throw std::invalid_argument("неверный вход прямой пробы");

        std::string каталог(путь_каталога, длина_пути);
        std::string название(имя, длина_имени);
        if (каталог.front() != '/' || каталог.find('\0') != std::string::npos
            || название == "." || название == ".."
            || название.find('/') != std::string::npos
            || название.find('\0') != std::string::npos)
            throw std::invalid_argument("неверные пути прямой пробы");

        uint64_t число_частей = (размер - 1) / длина_части + 1;
        if (число_частей > static_cast<uint64_t>(std::numeric_limits<int>::max())
            || число_частей > максимум_метаданных / 20
            || (число_частей > 1 && число_частей > максимум_метаданных / 52))
            throw std::invalid_argument("бюджет прямой пробы превышен");

        std::string полный_путь = каталог + "/" + название;
        struct stat каталог_до{}, файл_до{};
        if (::lstat(каталог.c_str(), &каталог_до) != 0
            || ::lstat(полный_путь.c_str(), &файл_до) != 0
            || !S_ISDIR(каталог_до.st_mode)
            || !S_ISREG(файл_до.st_mode)
            || файл_до.st_size < 0
            || static_cast<uint64_t>(файл_до.st_size) != размер)
            throw std::runtime_error("неверный корпус прямой пробы");

        std::vector<libtorrent::create_file_entry> перечень;
        перечень.emplace_back(название, static_cast<int64_t>(размер));
        libtorrent::create_torrent создание(
            std::move(перечень), static_cast<int>(длина_части), {});
        создание.set_creation_date(0);

        libtorrent::settings_pack настройки;
        настройки.set_int(libtorrent::settings_pack::aio_threads, 0);
        настройки.set_int(libtorrent::settings_pack::hashing_threads, 1);
        libtorrent::error_code ошибка;
        libtorrent::set_piece_hashes(
            создание, каталог, настройки,
            libtorrent::posix_disk_io_constructor,
            [](libtorrent::piece_index_t номер) {
                static_cast<void>(номер);
            }, ошибка);
        if (ошибка)
            throw std::runtime_error(
                "прямая библиотечная проба: " + ошибка.message());

        auto дерево = создание.generate();
        auto буфер = libtorrent::bencode(дерево);
        if (буфер.empty() || буфер.size() > максимум_метаданных
            || буфер.size() > static_cast<size_t>(std::numeric_limits<int>::max()))
            throw std::runtime_error("неверный размер прямых метаданных");

        libtorrent::load_torrent_limits пределы;
        пределы.max_buffer_size = static_cast<int>(буфер.size());
        пределы.max_pieces = static_cast<int>(число_частей);
        пределы.max_decode_depth = 32;
        пределы.max_decode_tokens = static_cast<int>(буфер.size());
        пределы.max_duplicate_filenames = 1;
        пределы.max_directory_depth = 2;
        libtorrent::error_code ошибка_загрузки;
        auto загруженное = libtorrent::load_torrent_buffer(
            libtorrent::span<char const>(
                буфер.data(), static_cast<ptrdiff_t>(буфер.size())),
            ошибка_загрузки, пределы);
        if (ошибка_загрузки || !загруженное.ti)
            throw std::runtime_error("не удалось загрузить прямые метаданные");

        auto const& хэши = загруженное.ti->info_hashes();
        if (!хэши.has_v1() || !хэши.has_v2())
            throw std::runtime_error("прямая проба не получила hybrid");

        struct stat каталог_после{}, файл_после{};
        if (::lstat(каталог.c_str(), &каталог_после) != 0
            || ::lstat(полный_путь.c_str(), &файл_после) != 0
            || !неизменная_прямая_метка(каталог_до, каталог_после)
            || !неизменная_прямая_метка(файл_до, файл_после))
            throw std::runtime_error("корпус прямой пробы изменился");

        auto результат = std::make_unique<ПрямыеМетаданныеЛибторрента>();
        результат->данные.assign(буфер.begin(), буфер.end());
        результат->первый = прямое_представление_хэша(хэши.v1.to_string());
        результат->второй = прямое_представление_хэша(хэши.v2.to_string());
        *адрес = результат.release();
    });
}

extern "C" uint8_t const* прямые_байты_либторрента(
    ПрямыеМетаданныеЛибторрента const* метаданные, size_t* длина) {
    if (длина) *длина = метаданные ? метаданные->данные.size() : 0;
    return метаданные ? метаданные->данные.data() : nullptr;
}

extern "C" char const* прямой_хэш_первой_версии(
    ПрямыеМетаданныеЛибторрента const* метаданные) {
    return метаданные ? метаданные->первый.c_str() : nullptr;
}

extern "C" char const* прямой_хэш_второй_версии(
    ПрямыеМетаданныеЛибторрента const* метаданные) {
    return метаданные ? метаданные->второй.c_str() : nullptr;
}

extern "C" void уничтожить_прямые_метаданные(
    ПрямыеМетаданныеЛибторрента* метаданные) {
    delete метаданные;
}
