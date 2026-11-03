import Foundation

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
        guard !логическийКомпонент.utf8.contains(47),
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

public struct КомпонентПолнойСсылки: Codable, Equatable, Sendable {
    public let исходное: String
    public let имя: ПубличноеИмя
}

public struct ПолнаяСсылкаВетки: Codable, Equatable, Sendable {
    public let значение: String
    public let алгоритмСоставления: String
    /// Source pins каждого элемента относятся к прежнему алгоритму Names.
    public let компоненты: [КомпонентПолнойСсылки]
}

extension ПубличныйФасадИмён {
    /// Pure-композиция логического направления. Подтверждение области остаётся у вызывающей стороны.
    /// ASCII-ввод уже каноничен; кириллический логический ввод требуется в NFC.
    /// 1024 UTF-8 байта — граница этого контракта, а не объявленный предел Git.
    public static func составитьПолнуюСсылку(из подтверждённыеКомпоненты: [String]) async throws -> ПолнаяСсылкаВетки {
        let префикс = "refs/heads/fum-lab/fum/"
        let суффикс = "/master"
        let предел = 1024
        var длина = префикс.utf8.count + суффикс.utf8.count
        guard !подтверждённыеКомпоненты.isEmpty,
              подтверждённыеКомпоненты.count <= (предел - длина + 1) / 2 else {
            throw ОшибкаПутей.отказ("Пустой или чрезмерно длинный путь направления")
        }
        var компоненты: [КомпонентПолнойСсылки] = []
        var имена: Set<String> = []
        for исходное in подтверждённыеКомпоненты {
            try проверитьЛогическийКомпонентСсылки(исходное)
            let имя = try await канонизировать(исходное)
            guard канониченКомпонентСсылки(имя.значение),
                  !служебныеКомпонентыСсылки.contains(имя.значение) else {
                throw ОшибкаПутей.отказ("Алгоритм вернул недопустимый компонент ссылки")
            }
            if исходное.utf8.allSatisfy({ $0 < 128 }),
               !исходное.utf8.elementsEqual(имя.значение.utf8) {
                throw ОшибкаПутей.отказ("Канонический ASCII-компонент изменён алгоритмом")
            }
            guard имена.insert(имя.значение).inserted else {
                throw ОшибкаПутей.отказ("Повтор или неоднозначное отображение компонентов")
            }
            длина += имя.значение.utf8.count + (компоненты.isEmpty ? 0 : 1)
            guard длина <= предел else {
                throw ОшибкаПутей.отказ("Полная ссылка превышает 1024 UTF-8 байта")
            }
            компоненты.append(КомпонентПолнойСсылки(исходное: исходное, имя: имя))
        }
        return ПолнаяСсылкаВетки(
            значение: префикс + компоненты.map { $0.имя.значение }.joined(separator: "/") + суффикс,
            алгоритмСоставления: "fum.полная-ссылка-ветки.1", компоненты: компоненты)
    }

    private static let служебныеКомпонентыСсылки: Set<String> = ["package.swift", "agents.md", "skill.md"]

    private static func проверитьЛогическийКомпонентСсылки(_ исходное: String) throws {
        guard !исходное.isEmpty, исходное.utf8.count <= 255,
              исходное.utf8.elementsEqual(исходное.precomposedStringWithCanonicalMapping.utf8),
              !служебныеКомпонентыСсылки.contains(исходное.lowercased()),
              !исходное.lowercased().hasSuffix(".lock") else {
            throw ОшибкаПутей.отказ("Неканонический или служебный логический компонент")
        }
        if исходное.utf8.allSatisfy({ $0 < 128 }) {
            guard канониченКомпонентСсылки(исходное) else {
                throw ОшибкаПутей.отказ("ASCII-компонент должен быть уже каноническим")
            }
            return
        }
        var послеРазделителя = true
        for знак in исходное.unicodeScalars {
            let букваИлиЦифра = (65...90).contains(знак.value) || (97...122).contains(знак.value)
                || (48...57).contains(знак.value)
                || ((0x400...0x4FF).contains(знак.value) && знак.properties.isAlphabetic)
            if букваИлиЦифра {
                послеРазделителя = false
            } else if [32, 45, 46].contains(знак.value), !послеРазделителя {
                послеРазделителя = true
            } else {
                throw ОшибкаПутей.отказ("Недопустимый знак или повтор разделителя")
            }
        }
        guard !послеРазделителя else {
            throw ОшибкаПутей.отказ("Компонент оканчивается разделителем")
        }
    }

    private static func канониченКомпонентСсылки(_ имя: String) -> Bool {
        guard !имя.isEmpty, имя.utf8.count <= 255, !имя.hasSuffix(".lock") else { return false }
        var послеРазделителя = true
        for байт in имя.utf8 {
            if (97...122).contains(байт) || (48...57).contains(байт) {
                послеРазделителя = false
            } else if (байт == 45 || байт == 46), !послеРазделителя {
                послеРазделителя = true
            } else {
                return false
            }
        }
        return !послеРазделителя
    }
}
