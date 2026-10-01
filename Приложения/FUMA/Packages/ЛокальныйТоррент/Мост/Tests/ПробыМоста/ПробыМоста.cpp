extern "C" {
#include "include/ПробыМоста.h"
}
#include "../../Sources/МостЛибторрента/ГраницаИсключений.hpp"
#include <new>
#include <stdexcept>
#include <string>

extern "C" РезультатГраницыМоста выполнить_пробу_моста(
    int32_t случай, ОбратныйВызовПробыМоста обратный_вызов, void* контекст) {
    return выполнить_без_исключений([&] {
        switch (случай) {
            case 1: throw std::runtime_error("проверочное исключение");
            case 2: throw 17;
            case 3: throw std::bad_alloc{};
            case 4: throw ОтменаОперацииМоста{};
            case 5: throw std::runtime_error(std::string(2048, 'a'));
            default: if (обратный_вызов) обратный_вызов(контекст);
        }
    });
}
