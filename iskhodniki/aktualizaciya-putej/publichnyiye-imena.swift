/// Закреплённое происхождение алгоритма; текущие Git и runtime здесь не читаются.
public struct ПроисхождениеПубличногоИмени: Codable, Equatable, Sendable {
    public struct Исходник: Codable, Equatable, Sendable {
        public let путь: String
        /// SHA-256 точных байтов исходника.
        public let хэш: String
    }

    public let алгоритм: String
    public let коммит: String
    public let исходники: [Исходник]
    public let путьЗависимости: String
    public let ревизияЗависимости: String
}

public struct ПубличноеИмя: Codable, Equatable, Sendable {
    public let значение: String
    public let происхождение: ПроисхождениеПубличногоИмени
}

/// Публичный вход существующего Names → LinguisticKit для одного логического компонента.
/// Результат сохраняет правила ASCII и lowercase-kebab, включая допустимую точку расширения.
/// Точные компоненты Package.swift и AGENTS.md закрыто отклоняются.
/// Контекстный контракт Инструменты/<каталог>/SKILL.md проверяет владелец полного пути.
public enum ПубличныйФасадИмён {
    private static let происхождение = ПроисхождениеПубличногоИмени(
        алгоритм: "fum.пути.unicode-boundary.Cyrl-Latn.ru.ascii-lower-kebab.1",
        коммит: "c6af44bf1ec061675b6205b9c6ee889d98264f28",
        исходники: [
            .init(путь: "iskhodniki/aktualizaciya-putej/proverka-imyon.swift",
                  хэш: "16ffeed76f26395270cb3f441b2b7cf3722a10cbbec9ed4d20be1affc24afc4f"),
            .init(путь: "iskhodniki/aktualizaciya-putej/chteniye-snimka.swift",
                  хэш: "92409edb351de7391c3fed46c5bfcac304c48934d26d7d50e623c83c77dfd635")
        ],
        путьЗависимости: "Зависимости/LinguisticKit",
        ревизияЗависимости: "837e2ce107b97ee7b9d3344c9fe99142281fe393")

    public static func канонизировать(_ логическийКомпонент: String) async throws -> ПубличноеИмя {
        try ИменаПутей.проверитьПуть(логическийКомпонент)
        guard !логическийКомпонент.contains("/"),
              ИменаПутей.исключение(логическийКомпонент) == nil else {
            throw ОшибкаПутей.отказ("Нужен один логический компонент без служебного фиксированного имени")
        }
        let отображения = try await ТранслитераторПутей().отобразить([
            ЗаписьСнимкаПутей(путь: логическийКомпонент, тип: "каталог")
        ])
        guard let отображение = отображения.first, отображения.count == 1 else {
            throw ОшибкаПутей.отказ("Штатный алгоритм не вернул единственное имя")
        }
        return ПубличноеИмя(значение: отображение.целевой, происхождение: происхождение)
    }
}
