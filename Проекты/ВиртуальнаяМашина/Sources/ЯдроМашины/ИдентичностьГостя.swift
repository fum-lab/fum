import Foundation

struct ПровереннаяИдентичностьГостя {
    let машина: String
    let конфигурация: String
}

enum ИдентичностьГостя {
    static func известныйХост(машина: String, публичныйКлюч: String) throws -> String {
        throw ОшибкаМашины("Конструктор известного хоста ожидает первого RED.")
    }
    static func настройка(машина: String, путь: String) throws -> String {
        throw ОшибкаМашины("Конструктор SSH-настройки ожидает первого RED.")
    }
    static func проверить(каталог: Int32, путь: String, машина: String,
                          получитьКлюч: (Data) throws -> Data) throws -> ПровереннаяИдентичностьГостя {
        throw ОшибкаМашины("Содержательная проверка идентичности ожидает первого RED.")
    }
}
