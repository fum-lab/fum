import Foundation

struct ИсключениеЯзыковогоДопуска: Sendable {
    let путь: String
    let вид: String
    let имя: String
    let причина: String
    let источник: String
    let строка: Int?
    let столбец: Int?

    init(путь: String, вид: String, имя: String, причина: String, источник: String,
         строка: Int? = nil, столбец: Int? = nil) {
        self.путь = путь; self.вид = вид; self.имя = имя
        self.причина = причина; self.источник = источник
        self.строка = строка; self.столбец = столбец
    }

    func разрешает(путь: String, вид: String, имя: String, строка: Int, столбец: Int) -> Bool {
        // Точные байты, без канонически эквивалентной подмены пути/имени.
        self.путь.utf8.elementsEqual(путь.utf8) && self.вид == вид
            && self.имя.utf8.elementsEqual(имя.utf8)
            && (self.строка == nil || self.строка == строка)
            && (self.столбец == nil || self.столбец == столбец)
            && !причина.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !источник.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum ИсключенияЯзыковогоДопуска {
    private struct Перечень: Decodable {
        let схема: String
        let исключения: [Запись]
    }
    private struct Запись: Decodable {
        let путь: String
        let язык: String
        let вид: String
        let имя: String
        let причина: String
        let источник: String
        let хэш_источника: String
    }

    static func изПолитики(_ политика: ЗакреплённаяПолитикаЯзыка, данные: [String: Data],
        гит: ЧитательГитЯзыка) throws -> [ИсключениеЯзыковогоДопуска] {
        guard let путь = политика.путьИсключений else { return [] }
        guard let байты = данные[путь] else { throw ОтказЧитателяЯзыка.политика }
        let перечень = try JSONDecoder().decode(Перечень.self, from: байты)
        guard перечень.схема == "fum.аббревиатуры-контекста.1", перечень.исключения.count == 8 else {
            throw ОтказЧитателяЯзыка.политика
        }
        // Исторические четыре Swift-аббревиатуры пока недостижимы из-за generic-профиля.
        // Сохраняются и проверяются байты перечня; разрешений этот срез из него не выдаёт.
        return []
    }
}
