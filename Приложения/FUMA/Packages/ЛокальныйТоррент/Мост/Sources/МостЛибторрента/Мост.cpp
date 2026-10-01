#include "ГраницаИсключений.hpp"
#include <atomic>
#include <stdexcept>

struct ОперацияТоррента {
    std::atomic<bool> отменена{false};
};

extern "C" {

int32_t версия_границы_моста(void) {
    return 1;
}

РезультатГраницыМоста создать_операцию_торрента(ОперацияТоррента** адрес) {
    return выполнить_без_исключений([&] {
        if (адрес == nullptr) throw std::invalid_argument("отсутствует адрес операции");
        if (*адрес != nullptr) throw std::invalid_argument("адрес уже содержит операцию");
        *адрес = new ОперацияТоррента{};
    });
}

void отменить_операцию_торрента(ОперацияТоррента* операция) {
    if (операция != nullptr) операция->отменена.store(true, std::memory_order_relaxed);
}

int32_t запрошена_отмена_торрента(ОперацияТоррента const* операция) {
    return операция == nullptr || операция->отменена.load(std::memory_order_relaxed) ? 1 : 0;
}

void уничтожить_операцию_торрента(ОперацияТоррента* операция) {
    delete операция;
}
}
