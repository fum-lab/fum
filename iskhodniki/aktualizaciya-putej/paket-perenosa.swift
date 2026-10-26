import Foundation
import CryptoKit
import Darwin
import FUMStructuringOperatorMemory
import КонтейнерНаблюдений

enum ОтказПакета: Error, Equatable, CustomStringConvertible {
    case условие(String)
    var description: String { switch self { case .условие(let причина): причина } }
}

struct ПоручениеПакета: Codable, Equatable, Sendable {
    var схема = "fum.запрос-пакета-девяти-путей.1"
    var корневая_задача: String
    var владелец: String
    var коммит: String
    var дерево: String
    var ветка: String
    var время_свежести: String
}

struct ПереносПакета: Codable, Equatable, Sendable {
    var исходный: String
    var целевой: String
    var режим: String
    var объект: String
    var sha256: String
}

struct ПравкаПакета: Codable, Equatable, Sendable {
    var путь: String
    var прежде: Data
    var после: Data
    var режим: UInt32
}

struct ФайлПакета: Codable, Equatable, Sendable {
    var путь: String
    var sha256: String
    var режим: UInt32
    var устройство: UInt64
    var инод: UInt64
    var размер: Int64
    var изменение_секунды: Int64
    var изменение_наносекунды: Int64
    var метаданные_секунды: Int64
    var метаданные_наносекунды: Int64
}

struct КаталогПакета: Codable, Equatable, Sendable {
    var путь: String
    var устройство: UInt64
    var инод: UInt64
    var режим: UInt32
    var имена: [Data]
}

struct ПланПакета: Codable, Equatable, Sendable {
    var схема = "fum.план-пакета-девяти-путей.1"
    var поручение: ПоручениеПакета
    var пространство: String
    var индекс: Data
    var переносы: [ПереносПакета]
    var правки: [ПравкаПакета]
    var документы: [ФайлПакета]
    var исходники: [ФайлПакета]
    var каталоги: [КаталогПакета]
    var определение_sha256 = ПравилаПакета.хэшОпределения
    var основа_кода = "ca3e59f528bfd9ab2f11e984a8bbd8f0f11c9ef0"
    var применение_разрешено = true
    var исполнитель_sha256: String
}

struct КвитанцияПакета: Codable, Equatable, Sendable {
    var схема = "fum.квитанция-пакета-девяти-путей.1"
    var план_sha256: String
    var исход: String
    var подтверждённый_префикс: Int
    var наблюдённый_префикс: Int?
    var причина: String?
}

// Публичная граница для единственного продукта fuma. Внутренняя модель, injection
// и выбор тестового хранилища через неё недоступны. Историческую квитанцию caller
// не должен выдавать за повторную проверку текущего рабочего дерева.
public enum ПакетноеПрименениеПутей {
    public static func построить(корень: URL, поручение: Data) async throws -> Data {
        let вход = try JSONDecoder().decode(ПоручениеПакета.self, from: поручение)
        return try await байтыПлана(ПакетПутей.построить(корень: корень, вход: вход))
    }

    public static func сверить(корень: URL, план: Data, sha256: String) async throws {
        let вход = try JSONDecoder().decode(ПланПакета.self, from: план).поручение
        let текущий = try await ПакетПутей.построить(корень: корень, вход: вход)
        try ПакетПутей.сверить(сохранённые: план, ожидаемыйХэш: sha256, текущий: текущий)
    }

    public static func применить(корень: URL, план: Data, sha256: String) async throws -> Data {
        try await байтыПлана(ПакетПутей.применить(корень: корень, план: план, ожидаемыйХэш: sha256))
    }
}

enum ПакетПутей {
    static func построить(корень: URL, вход: ПоручениеПакета, профиль: ПрофильПакета? = nil) async throws -> ПланПакета {
        let начало = DispatchTime.now().uptimeNanoseconds
        defer { профиль?.добавить("план-полностью", от: начало) }
        try проверитьПоручение(корень, вход)
        let началоИмён = DispatchTime.now().uptimeNanoseconds
        let карта = try await картаИмён()
        профиль?.добавить("вычисление-девяти-имён", от: началоИмён)
        let началоСнимка = DispatchTime.now().uptimeNanoseconds
        let читатель = try ЧитательПакета(корень)
        let индекс = try ЧитательПакета.гит(корень, ["ls-files", "--stage", "-z"])
        let записи = try ЭлементИндексаПакета.разобрать(индекс)
        guard ЭлементИндексаПакета.байты(записи) == индекс else { throw ОтказПакета.условие("неканонический-stage0") }
        do { _ = try ЧитательПакета.гит(корень, ["diff-index", "--cached", "--quiet", "HEAD", "--"]) }
        catch { throw ОтказПакета.условие("индекс-не-чист") }
        let документы = try ЧитательПакета.инвентарь(корень)
        let выбранные = Set((документы + карта.map(\.исходный) + ["Package.swift"]).map { Data($0.utf8) })
        var свойства: [Data: ФайлПакета] = [:]
        var тексты: [Data: Data] = [:]
        var объём = 0
        for ключ in выбранные.sorted(by: { $0.lexicographicallyPrecedes($1) }) {
            let путь = String(decoding: ключ, as: UTF8.self)
            let (свойство, данные) = try читатель.прочитать(путь)
            объём += данные.count
            guard объём <= 268_435_456 else { throw ОтказПакета.условие("предел-полного-снимка") }
            свойства[ключ] = свойство; тексты[ключ] = данные
        }
        var переносы: [ПереносПакета] = []
        for пара in карта {
            let ключ = Data(пара.исходный.utf8)
            guard let запись = записи.first(where: { $0.путь == ключ }), запись.режим == "100644",
                  let данные = тексты[ключ], ЧитательПакета.объект(данные) == запись.объект else {
                throw ОтказПакета.условие("грязный-или-неверный-исходник")
            }
            let родитель = (пара.целевой as NSString).deletingLastPathComponent
            let имя = (пара.целевой as NSString).lastPathComponent
            let (_, каталог) = try читатель.каталог(родитель)
            guard !каталог.имена.contains(where: { ИменаПутей.ключКоллизии(String(decoding: $0, as: UTF8.self)) == ИменаПутей.ключКоллизии(имя) }),
                  !записи.contains(where: { ИменаПутей.ключКоллизии(String(decoding: $0.путь, as: UTF8.self)) == ИменаПутей.ключКоллизии(пара.целевой) }) else {
                throw ОтказПакета.условие("назначение-занято")
            }
            переносы.append(ПереносПакета(исходный: пара.исходный, целевой: пара.целевой,
                режим: запись.режим, объект: запись.объект, sha256: свойства[ключ]!.sha256))
        }
        let исходныеДокументы = документы.map { ДокументСсылокПакета(путь: $0,
            байты: тексты[Data($0.utf8)]!, sha256: свойства[Data($0.utf8)]!.sha256) }
        профиль?.добавить("инвентарь-и-чтение-снимка", от: началоСнимка)
        let началоСсылок = DispatchTime.now().uptimeNanoseconds
        let ссылочные = try РешательСсылокПакета.разрешить(документы: исходныеДокументы,
            ожидаемыеПути: документы, пары: карта, разрешённыеДокументы: разрешённыеДокументы,
            проверитьАдрес: читатель.проверитьАдрес)
        профиль?.добавить("разрешение-всего-Markdown", от: началоСсылок)
        var правки: [ПравкаПакета] = []
        let пакет = тексты[Data("Package.swift".utf8)]!
        правки.append(ПравкаПакета(путь: "Package.swift", прежде: пакет,
            после: try адаптироватьМанифест(пакет), режим: свойства[Data("Package.swift".utf8)]!.режим))
        for изменение in ссылочные {
            let прежние = тексты[Data(изменение.путь.utf8)]!
            правки.append(ПравкаПакета(путь: изменение.путь, прежде: прежние,
                после: try обновитьСвежесть(изменение.будущиеБайты, путь: изменение.путь, время: вход.время_свежести),
                режим: свойства[Data(изменение.путь.utf8)]!.режим))
        }
        guard правки.count == 5,
              Set(правки.dropFirst().map { Data($0.путь.utf8) }) == Set(разрешённыеДокументы.map { Data($0.utf8) }) else {
            throw ОтказПакета.условие("не-четыре-разрешённые-ссылочные-правки")
        }
        for правка in правки {
            guard let запись = записи.first(where: { $0.путь == Data(правка.путь.utf8) }),
                  запись.режим == "100644", ЧитательПакета.объект(правка.прежде) == запись.объект,
                  правка.прежде != правка.после else { throw ОтказПакета.условие("грязная-или-пустая-правка") }
        }
        let началоОград = DispatchTime.now().uptimeNanoseconds
        for свойство in свойства.values {
            guard try читатель.метаданные(свойство.путь, хэш: свойство.sha256) == свойство else {
                throw ОтказПакета.условие("дрейф-снимка")
            }
        }
        guard try ЧитательПакета.инвентарь(корень).map({ Data($0.utf8) }) == документы.map({ Data($0.utf8) }),
              try ЧитательПакета.гит(корень, ["ls-files", "--stage", "-z"]) == индекс else {
            throw ОтказПакета.условие("дрейф-снимка")
        }
        try проверитьПоручение(корень, вход)
        профиль?.добавить("поздние-ограды-плана", от: началоОград)
        return try ПланПакета(поручение: вход, пространство: пространство(корень), индекс: индекс,
            переносы: переносы, правки: правки, документы: документы.map { свойства[Data($0.utf8)]! },
            исходники: (карта.map(\.исходный) + ["Package.swift"]).map { свойства[Data($0.utf8)]! },
            каталоги: читатель.снимокКаталогов(), исполнитель_sha256: хэшИсполнителя())
    }

    static func применить(корень: URL, план: Data, ожидаемыйХэш: String,
        хранилищеДляПроверки: URL? = nil,
        неисправность: ((String, Int) throws -> Void)? = nil,
        профиль: ПрофильПакета? = nil,
        операцииЖурнала: ФайловыеОперации = .системные) async throws -> КвитанцияПакета {
        let начало = DispatchTime.now().uptimeNanoseconds
        defer { профиль?.добавить("применение-с-повторной-сверкой", от: начало) }
        let разобранный = try разобратьДляПрименения(корень, план, ожидаемыйХэш)
        if let квитанция = try прочитатьЗавершённый(корень, разобранный, план, хранилищеДляПроверки, операцииЖурнала) {
            return квитанция
        }
        let текущий = try await построить(корень: корень, вход: разобранный.поручение, профиль: профиль)
        try сверить(сохранённые: план, ожидаемыйХэш: ожидаемыйХэш, текущий: текущий)
        return try ПрименениеПакета(корень: корень, план: разобранный, байты: план,
            основаХранилища: хранилищеДляПроверки, неисправность: неисправность, профиль: профиль,
            операцииЖурнала: операцииЖурнала).выполнить()
    }

    private static func разобратьДляПрименения(_ корень: URL, _ данные: Data, _ хэш: String) throws -> ПланПакета {
        guard данные.count <= 67_108_864, хэшПутей(данные) == хэш else {
            throw ОтказПакета.условие("SHA-плана-не-совпал")
        }
        let план = try JSONDecoder().decode(ПланПакета.self, from: данные)
        guard try байтыПлана(план) == данные,
              Data(план.схема.utf8) == Data("fum.план-пакета-девяти-путей.1".utf8),
              план.применение_разрешено, план.переносы.count == 9, план.правки.count == 5,
              план.поручение.владелец == ProcessInfo.processInfo.environment["CODEX_THREAD_ID"],
              план.определение_sha256 == ПравилаПакета.хэшОпределения,
              try план.исполнитель_sha256 == хэшИсполнителя(),
              try план.пространство == пространство(корень) else {
            throw ОтказПакета.условие("неверный-план-применения")
        }
        return план
    }

    private static func прочитатьЗавершённый(_ корень: URL, _ план: ПланПакета, _ байты: Data,
        _ основа: URL?, _ операции: ФайловыеОперации) throws -> КвитанцияПакета? {
        guard let журнал = try ЖурналПакета.открыть(корень: корень, план: план, байты: байты,
            основаДляПроверки: основа, создать: false, операции: операции) else { return nil }
        guard let квитанция = try журнал.квитанция() else {
            throw ОтказПакета.условие("существует-незавершённое-намерение-эффект-не-повторён")
        }
        return квитанция
    }

    static func сверить(сохранённые: Data, ожидаемыйХэш: String, текущий: ПланПакета) throws {
        guard хэшПутей(сохранённые) == ожидаемыйХэш else { throw ОтказПакета.условие("SHA-плана-не-совпал") }
        let разобранный = try JSONDecoder().decode(ПланПакета.self, from: сохранённые)
        guard try байтыПлана(разобранный) == сохранённые, try байтыПлана(текущий) == сохранённые else {
            throw ОтказПакета.условие("дрейф-снимка")
        }
    }

    static let разрешённыеДокументы: Set<String> = [
        "iskhodniki/zapusk/README.md",
        "Журнал/2026-10-26_00-11-30_MSK_сохранить-многосегментный-raw-codex/отчёт.md",
        "Журнал/2026-10-26_01-48-08_MSK_включить-принятую-основу-в-архив-codex/запрос.md",
        "Сбои/FUM-СБОЙ-0241-декомпозиция-имени-профиля.md"
    ]

    static func проверитьПоручение(_ корень: URL, _ вход: ПоручениеПакета) throws {
        guard Data(вход.схема.utf8) == Data("fum.запрос-пакета-девяти-путей.1".utf8),
              UUID(uuidString: вход.корневая_задача)?.uuidString.lowercased() == вход.корневая_задача,
              UUID(uuidString: вход.владелец)?.uuidString.lowercased() == вход.владелец,
              вход.владелец == ProcessInfo.processInfo.environment["CODEX_THREAD_ID"],
              вход.ветка.hasPrefix("refs/heads/") else { throw ОтказПакета.условие("чужой-владелец-или-неверный-вход") }
        let формат = DateFormatter()
        формат.locale = Locale(identifier: "en_US_POSIX"); формат.timeZone = TimeZone(identifier: "Europe/Moscow")
        формат.dateFormat = "yyyy-MM-dd HH:mm:ss 'MSK'"; формат.isLenient = false
        guard let время = формат.date(from: вход.время_свежести), формат.string(from: время) == вход.время_свежести else {
            throw ОтказПакета.условие("неверное-время-свежести")
        }
        guard try ЧитательПакета.строкаГит(корень, ["rev-parse", "--show-object-format"]) == "sha1",
              try Data(ЧитательПакета.физический(URL(fileURLWithPath:
                ЧитательПакета.строкаГит(корень, ["rev-parse", "--show-toplevel"]))).path.utf8) == Data(корень.path.utf8),
              try Data(ЧитательПакета.строкаГит(корень, ["symbolic-ref", "HEAD"]).utf8) == Data(вход.ветка.utf8),
              try ЧитательПакета.строкаГит(корень, ["rev-parse", "HEAD"]) == вход.коммит,
              try ЧитательПакета.строкаГит(корень, ["rev-parse", "HEAD^{tree}"]) == вход.дерево,
              try Data(ЧитательПакета.строкаГит(корень, ["symbolic-ref", "HEAD"]).utf8) == Data(вход.ветка.utf8) else {
            throw ОтказПакета.условие("дрейф-адреса")
        }
    }

    static func пространство(_ корень: URL) throws -> String {
        let читатель = try ЧитательПакета(корень)
        let (_, корневой) = try читатель.каталог("")
        let сообщённый = try ЧитательПакета.строкаГит(корень, ["rev-parse", "--absolute-git-dir"])
        let служебный = try ЧитательПакета.физический(URL(fileURLWithPath: сообщённый)).path
        return хэшПутей(Data("\(корень.path)\0\(корневой.устройство):\(корневой.инод)\0\(служебный)".utf8))
    }

    static func хэшИсполнителя() throws -> String {
        guard let адрес = Bundle(for: МеткаОбразаПакета.self).executableURL else {
            throw ОтказПакета.условие("не-найден-исполнитель")
        }
        return try хэшПутей(Data(contentsOf: адрес))
    }

    static func адаптироватьМанифест(_ данные: Data) throws -> Data {
        guard let текст = String(data: данные, encoding: .utf8) else { throw ОтказПакета.условие("не-UTF8-манифест") }
        let образец = ".target(name: \"АрхивКодекса\","
        let места = try кодовыеДиапазоны(данные, образец: образец)
        guard места.count == 1 else { throw ОтказПакета.условие("не-один-фиксированный-target") }
        let байты = Array(данные)
        var курсор = места[0].upperBound
        var глубина = 1
        while курсор < байты.count && глубина > 0 {
            if let следующий = try пропуститьЛитерал(байты, курсор) { курсор = следующий; continue }
            if байты[курсор] == 40 { глубина += 1 }
            if байты[курсор] == 41 { глубина -= 1 }
            курсор += 1
        }
        guard глубина == 0 else { throw ОтказПакета.условие("незамкнутый-target") }
        let блок = данные.subdata(in: места[0].lowerBound..<курсор)
        let старое = "exclude: [\"README.md\", \"zhurnal\"]"
        let новое = "exclude: [\"rukovodstvo.md\", \"zhurnal\"]"
        let исключения = try кодовыеДиапазоны(блок, образец: старое)
        guard исключения.count == 1,
              try кодовыеДиапазоны(блок, образец: "path: \"iskhodniki/arkhiv-codex\"").count == 1,
              try кодовыеДиапазоны(блок, образец: "exclude:").count == 1 else {
            throw ОтказПакета.условие("неизвестная-форма-Package-adapter")
        }
        let диапазон = (места[0].lowerBound + исключения[0].lowerBound)..<(места[0].lowerBound + исключения[0].upperBound)
        var итог = данные
        итог.replaceSubrange(диапазон, with: Data(новое.utf8))
        guard String(data: итог, encoding: .utf8) != текст else { throw ОтказПакета.условие("пустой-Package-adapter") }
        return итог
    }

    private static func пропуститьЛитерал(_ байты: [UInt8], _ начало: Int) throws -> Int? {
        if байты[начало] == 34 {
            guard начало + 2 >= байты.count || байты[(начало + 1)...(начало + 2)] != [34, 34] else {
                throw ОтказПакета.условие("неподдержанный-Swift-литерал")
            }
            var номер = начало + 1
            while номер < байты.count {
                if байты[номер] == 92 { номер += 2; continue }
                if байты[номер] == 34 { return номер + 1 }
                if байты[номер] == 10 { break }
                номер += 1
            }
            throw ОтказПакета.условие("незамкнутый-Swift-литерал")
        }
        if начало + 1 < байты.count && байты[начало] == 47 {
            if байты[начало + 1] == 47 {
                return байты[начало...].firstIndex(of: 10).map { $0 + 1 } ?? байты.count
            }
            if байты[начало + 1] == 42 {
                var глубина = 1; var номер = начало + 2
                while номер + 1 < байты.count {
                    if байты[номер] == 47 && байты[номер + 1] == 42 { глубина += 1; номер += 2; continue }
                    if байты[номер] == 42 && байты[номер + 1] == 47 {
                        глубина -= 1; номер += 2
                        if глубина == 0 { return номер }
                        continue
                    }
                    номер += 1
                }
                throw ОтказПакета.условие("незамкнутый-Swift-комментарий")
            }
        }
        return nil
    }

    private static func кодовыеДиапазоны(_ данные: Data, образец: String) throws -> [Range<Int>] {
        let байты = Array(данные), искомое = Array(образец.utf8)
        var итог: [Range<Int>] = []; var номер = 0
        while номер < байты.count {
            if номер + искомое.count <= байты.count && байты[номер..<(номер + искомое.count)].elementsEqual(искомое) {
                итог.append(номер..<(номер + искомое.count)); номер += искомое.count; continue
            }
            if let следующий = try пропуститьЛитерал(байты, номер) { номер = следующий; continue }
            номер += 1
        }
        return итог
    }

    static func обновитьСвежесть(_ данные: Data, путь: String, время: String) throws -> Data {
        try РешательСсылокПакета.обновитьСвежесть(данные, путь: путь, время: время)
    }

    static func картаИмён() async throws -> [ОтображениеПути] {
        struct СтрокаКарты: Decodable {
            var исходный: String; var целевой: String; var имя: String
            enum CodingKeys: String, CodingKey { case исходный = "source", целевой = "destination", имя = "имяДляАлгоритма" }
        }
        struct Карта: Decodable {
            var файлы: [СтрокаКарты]
            enum CodingKeys: String, CodingKey { case файлы = "files" }
        }
        guard let адрес = Bundle.module.url(forResource: "snimok-devyati", withExtension: "json") else {
            throw ОтказПакета.условие("нет-карты-происхождения")
        }
        let данные = try Data(contentsOf: адрес)
        guard хэшПутей(данные) == "611e56ebf1305f5cc0133c36c242169bfba2950854aee3d6d6d89418f8d191d0" else {
            throw ОтказПакета.условие("дрейф-карты-происхождения")
        }
        let карта = try JSONDecoder().decode(Карта.self, from: данные)
        guard карта.файлы.count == 9 else { throw ОтказПакета.условие("не-девять-переносов") }
        let имена = try await ТранслитераторПутей().отобразить(карта.файлы.map {
            ЗаписьСнимкаПутей(путь: ($0.имя as NSString).lastPathComponent)
        })
        var занято: Set<Data> = []
        return try карта.файлы.enumerated().map { номер, запись in
            try ИменаПутей.проверитьПуть(запись.исходный); try ИменаПутей.проверитьПуть(запись.целевой)
            guard (запись.исходный as NSString).deletingLastPathComponent == (запись.целевой as NSString).deletingLastPathComponent,
                  Data((запись.целевой as NSString).lastPathComponent.utf8) == Data(имена[номер].целевой.utf8),
                  Data(запись.исходный.utf8) != Data(запись.целевой.utf8),
                  занято.insert(ИменаПутей.ключКоллизии(запись.целевой)).inserted else {
                throw ОтказПакета.условие("неверное-конечное-отображение")
            }
            return ОтображениеПути(исходный: запись.исходный, целевой: запись.целевой)
        }
    }
}

private final class МеткаОбразаПакета: NSObject {}

struct ЗамерПакета: Codable, Sendable {
    var этап: String
    var наносекунды: UInt64
}

enum СистемныеАдресаПакета {
    static var пустаяКонфигурация: String { _PATH_DEVNULL }

    static func исполнительGit() throws -> String {
        // Это compile-time стандарт Darwin SDK, а не PATH процесса. Проверенная
        // текущая SDK выбирает тот же системный Git; поиска/fallback по PATH нет.
        guard let первый = _PATH_STDPATH.split(separator: ":", omittingEmptySubsequences: false).first else {
            throw ОтказПакета.условие("неверный-стандартный-путь-SDK")
        }
        let каталог = String(первый)
        let части = каталог.split(separator: "/", omittingEmptySubsequences: false)
        guard части.count > 1, части.first == "",
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
              !каталог.contains("\\"), каталог.utf8.allSatisfy({ (33...126).contains($0) }) else {
            throw ОтказПакета.условие("неверный-стандартный-путь-SDK")
        }
        return URL(fileURLWithPath: каталог, isDirectory: true).appendingPathComponent("git", isDirectory: false).path
    }
}

// Только ограниченная диагностика. Изменяемый буфер всегда под одним NSLock;
// он не участвует в решении и не добавляет FS/Git-проходов.
final class ПрофильПакета: @unchecked Sendable {
    private let замок = NSLock()
    private var записи: [ЗамерПакета] = []
    func добавить(_ этап: String, от начало: UInt64) {
        let длительность = DispatchTime.now().uptimeNanoseconds - начало
        замок.withLock {
            if записи.count < 256 { записи.append(ЗамерПакета(этап: этап, наносекунды: длительность)) }
        }
    }
    func снимок() -> [ЗамерПакета] { замок.withLock { записи } }
}

struct ЭлементИндексаПакета: Equatable, Sendable {
    var путь: Data
    var режим: String
    var объект: String

    static func разобрать(_ данные: Data) throws -> [ЭлементИндексаПакета] {
        var итог: [ЭлементИндексаПакета] = []
        var занято: Set<Data> = []
        for строка in данные.split(separator: 0) {
            guard let табуляция = строка.firstIndex(of: 9),
                  let заголовок = String(data: строка[..<табуляция], encoding: .utf8) else {
                throw ОтказПакета.условие("повреждённый-индекс")
            }
            let поля = заголовок.split(separator: " ")
            let путь = Data(строка[строка.index(after: табуляция)...])
            guard поля.count == 3, поля[2] == "0", String(data: путь, encoding: .utf8) != nil,
                  занято.insert(путь).inserted else { throw ОтказПакета.условие("неполный-stage0") }
            итог.append(ЭлементИндексаПакета(путь: путь, режим: String(поля[0]), объект: String(поля[1])))
        }
        return итог.sorted { $0.путь.lexicographicallyPrecedes($1.путь) }
    }

    static func байты(_ записи: [ЭлементИндексаПакета]) -> Data {
        записи.sorted { $0.путь.lexicographicallyPrecedes($1.путь) }.reduce(into: Data()) { итог, запись in
            итог.append(Data("\(запись.режим) \(запись.объект) 0\t".utf8))
            итог.append(запись.путь); итог.append(0)
        }
    }
}

// Дескрипторы остаются внутри одного синхронного прохода. Объект не передаётся между actor.
final class ЧитательПакета {
    let корень: URL
    private var открытые: [Data: (Int32, КаталогПакета)] = [:]

    init(_ корень: URL) throws {
        guard try Data(корень.path.utf8) == Data(Self.физический(корень).path.utf8) else {
            throw ОтказПакета.условие("нефизический-корень")
        }
        self.корень = корень
        let дескриптор = open(корень.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard дескриптор >= 0 else { throw ОтказПакета.условие("корень-не-открыт") }
        do { открытые[Data()] = (дескриптор, try Self.описатьКаталог("", дескриптор)) }
        catch { close(дескриптор); throw error }
    }

    deinit { for (дескриптор, _) in открытые.values { close(дескриптор) } }

    static func физический(_ адрес: URL) throws -> URL {
        guard адрес.isFileURL, адрес.path.hasPrefix("/"), !адрес.path.utf8.contains(0) else {
            throw ОтказПакета.условие("не-файловый-адрес")
        }
        var остаток: [String] = []
        var путь = адрес.path
        for _ in 0...(путь.utf8.count + 1) {
            if let указатель = realpath(путь, nil) {
                let основа = String(cString: указатель); free(указатель)
                let суффикс = остаток.reversed().joined(separator: "/")
                return URL(fileURLWithPath: основа + (суффикс.isEmpty ? "" : (основа == "/" ? "" : "/") + суффикс))
            }
            guard errno == ENOENT else { throw ОтказПакета.условие("физический-адрес-не-разрешён") }
            var сведения = stat()
            if lstat(путь, &сведения) == 0 { throw ОтказПакета.условие("неразрешённый-символический-адрес") }
            let родитель = (путь as NSString).deletingLastPathComponent
            guard !родитель.isEmpty, родитель.utf8.count < путь.utf8.count else {
                throw ОтказПакета.условие("физический-предок-не-сокращается")
            }
            остаток.append((путь as NSString).lastPathComponent); путь = родитель
        }
        throw ОтказПакета.условие("предел-физических-предков")
    }

    static func гит(_ корень: URL, _ аргументы: [String], коды: Set<Int32> = [0],
        средаДляПроверки: [String: String]? = nil) throws -> Data {
        // C argv строится из исходных UTF-8, без промежуточного NSString пути.
        let команда = ["git", "--no-optional-locks", "--no-replace-objects", "--literal-pathspecs",
            "-c", "core.fsmonitor=false", "-C", корень.path] + аргументы
        var среда = (средаДляПроверки ?? ProcessInfo.processInfo.environment).filter { !$0.key.hasPrefix("GIT_") }
        среда["GIT_OPTIONAL_LOCKS"] = "0"; среда["GIT_CONFIG_NOSYSTEM"] = "1"
        среда["GIT_CONFIG_GLOBAL"] = СистемныеАдресаПакета.пустаяКонфигурация; среда["GIT_NO_LAZY_FETCH"] = "1"
        let исполнитель = try СистемныеАдресаПакета.исполнительGit()
        var строки = команда.map { $0.withCString { strdup($0) } } + [nil]
        var окружение = среда.keys.sorted().map { ключ in (ключ + "=" + среда[ключ]!).withCString { strdup($0) } } + [nil]
        defer { for строка in строки { free(строка) }; for строка in окружение { free(строка) } }
        guard строки.dropLast().allSatisfy({ $0 != nil }), окружение.dropLast().allSatisfy({ $0 != nil }) else {
            throw ОтказПакета.условие("не-создан-argv")
        }
        var канал: [Int32] = [0, 0]
        guard pipe(&канал) == 0 else { throw ОтказПакета.условие("не-создан-канал-Git") }
        guard канал.allSatisfy({ $0 > STDERR_FILENO && fcntl($0, F_SETFD, FD_CLOEXEC) == 0 }) else {
            close(канал[0]); close(канал[1]); throw ОтказПакета.условие("не-защищён-канал-Git")
        }
        var действия: posix_spawn_file_actions_t?
        guard posix_spawn_file_actions_init(&действия) == 0 else {
            close(канал[0]); close(канал[1]); throw ОтказПакета.условие("не-созданы-действия-Git")
        }
        defer { posix_spawn_file_actions_destroy(&действия) }
        let подготовка = [posix_spawn_file_actions_adddup2(&действия, канал[1], STDOUT_FILENO),
            posix_spawn_file_actions_addclose(&действия, канал[0]), posix_spawn_file_actions_addclose(&действия, канал[1])]
        guard подготовка.allSatisfy({ $0 == 0 }) else {
            close(канал[0]); close(канал[1]); throw ОтказПакета.условие("не-подготовлены-FD-Git")
        }
        var процесс: pid_t = 0
        let запуск = строки.withUnsafeMutableBufferPointer { аргументы in
            окружение.withUnsafeMutableBufferPointer { переменные in
                исполнитель.withCString { путь in
                    posix_spawn(&процесс, путь, &действия, nil, аргументы.baseAddress!, переменные.baseAddress!)
                }
            }
        }
        close(канал[1])
        guard запуск == 0 else { close(канал[0]); throw ОтказПакета.условие("Git-не-запущен") }
        let файл = FileHandle(fileDescriptor: канал[0], closeOnDealloc: true)
        let данные = файл.readDataToEndOfFile()
        var статус: Int32 = 0
        while waitpid(процесс, &статус, 0) < 0 {
            if errno == EINTR { continue }
            throw ОтказПакета.условие("исход-Git-неизвестен")
        }
        let код = статус & 0x7f == 0 ? (статус >> 8) & 0xff : 128 + (статус & 0x7f)
        guard коды.contains(код) else { throw ОтказПакета.условие("Git-отказ-" + (аргументы.first ?? "без-команды")) }
        return данные
    }

    static func строкаГит(_ корень: URL, _ аргументы: [String]) throws -> String {
        guard let строка = String(data: try гит(корень, аргументы), encoding: .utf8) else {
            throw ОтказПакета.условие("не-UTF8-Git")
        }
        return строка.trimmingCharacters(in: .newlines)
    }

    static func инвентарь(_ корень: URL) throws -> [String] {
        let данные = try гит(корень, ["ls-files", "--cached", "--others", "--exclude-standard", "-z"])
        var результат: [Data: String] = [:]
        let исключённые = Set([".git", ".build", ".swiftpm", ".cache", "cache", "caches", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache"])
        for байты in данные.split(separator: 0) {
            guard let путь = String(data: байты, encoding: .utf8) else { throw ОтказПакета.условие("не-UTF8-инвентарь") }
            guard (путь as NSString).pathExtension == "md" else { continue }
            try ИменаПутей.проверитьПуть(путь)
            let части = путь.split(separator: "/").dropLast().map(String.init)
            if части.first == "Proyekcii" { continue }
            let нижние = части.map { $0.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX")) }
            if нижние.contains(where: { исключённые.contains($0) || ["-cache", "_cache", ".cache"].contains(where: $0.hasSuffix) }) { continue }
            if нижние.count >= 2, нижние[0] == ".obsidian", ["plugins", "themes"].contains(нижние[1]) { continue }
            результат[Data(путь.utf8)] = путь
        }
        return результат.keys.sorted { $0.lexicographicallyPrecedes($1) }.map { результат[$0]! }
    }

    private static func состояние(_ дескриптор: Int32) throws -> stat {
        var состояние = stat()
        guard fstat(дескриптор, &состояние) == 0, состояние.st_uid == getuid() else {
            throw ОтказПакета.условие("inode-или-владелец-не-подтверждён")
        }
        return состояние
    }

    private static func имена(_ дескриптор: Int32) throws -> [Data] {
        let копия = dup(дескриптор)
        guard копия >= 0, let поток = fdopendir(копия) else {
            if копия >= 0 { close(копия) }
            throw ОтказПакета.условие("каталог-не-перечислен")
        }
        defer { closedir(поток) }
        rewinddir(поток)
        var итог: [Data] = []
        errno = 0
        while let запись = readdir(поток) {
            var имя = запись.pointee.d_name
            let данные = withUnsafeBytes(of: &имя) { Data($0.prefix { $0 != 0 }) }
            guard let строка = String(data: данные, encoding: .utf8) else { throw ОтказПакета.условие("не-UTF8-имя") }
            if строка != ".", строка != ".." { итог.append(данные) }
            errno = 0
        }
        guard errno == 0 else { throw ОтказПакета.условие("неполное-перечисление") }
        let группы = Dictionary(grouping: итог, by: { Data(String(decoding: $0, as: UTF8.self).precomposedStringWithCanonicalMapping.utf8) })
        guard группы.values.allSatisfy({ $0.count == 1 }) else { throw ОтказПакета.условие("NFC-коллизия") }
        return итог.sorted { $0.lexicographicallyPrecedes($1) }
    }

    private static func описатьКаталог(_ путь: String, _ дескриптор: Int32) throws -> КаталогПакета {
        let атрибуты = try состояние(дескриптор)
        guard атрибуты.st_mode & S_IFMT == S_IFDIR else { throw ОтказПакета.условие("не-каталог") }
        return КаталогПакета(путь: путь, устройство: UInt64(атрибуты.st_dev), инод: атрибуты.st_ino,
            режим: UInt32(атрибуты.st_mode & 0o7777), имена: try имена(дескриптор))
    }

    private func имя(_ часть: String, в каталоге: КаталогПакета) throws -> String {
        let ключ = Data(часть.precomposedStringWithCanonicalMapping.utf8)
        let кандидаты = каталоге.имена.filter { Data(String(decoding: $0, as: UTF8.self).precomposedStringWithCanonicalMapping.utf8) == ключ }
        guard кандидаты.count == 1 else { throw ОтказПакета.условие("нет-точного-NFC-пути") }
        return String(decoding: кандидаты[0], as: UTF8.self)
    }

    func каталог(_ путь: String) throws -> (Int32, КаталогПакета) {
        let ключ = Data(путь.utf8)
        if let найден = открытые[ключ] { return найден }
        try ИменаПутей.проверитьПуть(путь)
        let родитель = (путь as NSString).deletingLastPathComponent
        let (дескриптор, описание) = try каталог(родитель)
        let физическое = try имя((путь as NSString).lastPathComponent, в: описание)
        let следующий = openat(дескриптор, физическое, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard следующий >= 0 else { throw ОтказПакета.условие("symlink-или-специальный-родитель") }
        do {
            let итог = (следующий, try Self.описатьКаталог(путь, следующий))
            открытые[ключ] = итог
            return итог
        } catch { close(следующий); throw error }
    }

    private func открыть(_ путь: String) throws -> Int32 {
        try ИменаПутей.проверитьПуть(путь)
        let (родитель, описание) = try каталог((путь as NSString).deletingLastPathComponent)
        let физическое = try имя((путь as NSString).lastPathComponent, в: описание)
        let дескриптор = openat(родитель, физическое, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard дескриптор >= 0 else { throw ОтказПакета.условие("symlink-или-нет-файла") }
        return дескриптор
    }

    private func атрибуты(_ путь: String, _ состояние: stat, _ хэш: String) throws -> ФайлПакета {
        guard состояние.st_mode & S_IFMT == S_IFREG, состояние.st_nlink == 1 else {
            throw ОтказПакета.условие("необычный-файл-или-hardlink")
        }
        return ФайлПакета(путь: путь, sha256: хэш, режим: UInt32(состояние.st_mode & 0o7777),
            устройство: UInt64(состояние.st_dev), инод: состояние.st_ino, размер: состояние.st_size,
            изменение_секунды: Int64(состояние.st_mtimespec.tv_sec), изменение_наносекунды: Int64(состояние.st_mtimespec.tv_nsec),
            метаданные_секунды: Int64(состояние.st_ctimespec.tv_sec), метаданные_наносекунды: Int64(состояние.st_ctimespec.tv_nsec))
    }

    func метаданные(_ путь: String, хэш: String) throws -> ФайлПакета {
        let дескриптор = try открыть(путь); defer { close(дескриптор) }
        return try атрибуты(путь, Self.состояние(дескриптор), хэш)
    }

    func прочитать(_ путь: String) throws -> (ФайлПакета, Data) {
        let дескриптор = try открыть(путь); defer { close(дескриптор) }
        let до = try Self.состояние(дескриптор)
        let ранние = try атрибуты(путь, до, "")
        guard до.st_size >= 0, до.st_size <= 67_108_864 else { throw ОтказПакета.условие("предел-файла") }
        let данные = try FileHandle(fileDescriptor: дескриптор, closeOnDealloc: false).readToEnd() ?? Data()
        let после = try атрибуты(путь, Self.состояние(дескриптор), "")
        guard ранние == после, данные.count == до.st_size else { throw ОтказПакета.условие("дрейф-чтения") }
        var итог = после; итог.sha256 = хэшПутей(данные)
        return (итог, данные)
    }

    func снимокКаталогов() throws -> [КаталогПакета] {
        for (дескриптор, прежний) in открытые.values {
            guard try Self.описатьКаталог(прежний.путь, дескриптор) == прежний else { throw ОтказПакета.условие("дрейф-каталога") }
            var именованный = stat()
            if прежний.путь.isEmpty {
                guard lstat(корень.path, &именованный) == 0 else { throw ОтказПакета.условие("корень-исчез") }
            } else {
                let родитель = (прежний.путь as NSString).deletingLastPathComponent
                guard let (родительский, описание) = открытые[Data(родитель.utf8)] else {
                    throw ОтказПакета.условие("нет-привязки-родителя")
                }
                let физическое = try имя((прежний.путь as NSString).lastPathComponent, в: описание)
                guard fstatat(родительский, физическое, &именованный, AT_SYMLINK_NOFOLLOW) == 0 else {
                    throw ОтказПакета.условие("имя-каталога-исчезло")
                }
            }
            guard именованный.st_mode & S_IFMT == S_IFDIR, UInt64(именованный.st_dev) == прежний.устройство,
                  именованный.st_ino == прежний.инод, UInt32(именованный.st_mode & 0o7777) == прежний.режим else {
                throw ОтказПакета.условие("дрейф-именной-привязки-каталога")
            }
        }
        return открытые.values.map { $0.1 }.sorted { порядокПутей($0.путь, $1.путь) }
    }

    func проверитьАдрес(_ путь: String) throws {
        if путь.isEmpty { return }
        try ИменаПутей.проверитьПуть(путь)
        var текущий = dup(try каталог("").0)
        guard текущий >= 0 else { throw ОтказПакета.условие("граф-не-открыт") }
        defer { close(текущий) }
        let части = путь.split(separator: "/").map(String.init)
        for (номер, часть) in части.enumerated() {
            var атрибуты = stat()
            if fstatat(текущий, часть, &атрибуты, AT_SYMLINK_NOFOLLOW) != 0 {
                if errno == ENOENT || errno == ENOTDIR { return }
                throw ОтказПакета.условие("граф-не-подтверждён")
            }
            let вид = атрибуты.st_mode & S_IFMT
            guard вид == S_IFDIR || вид == S_IFREG else { throw ОтказПакета.условие("symlink-или-специальная-цель-графа") }
            if номер + 1 < части.count {
                if вид != S_IFDIR { return }
                let следующий = openat(текущий, часть, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                guard следующий >= 0 else { throw ОтказПакета.условие("дрейф-родителя-графа") }
                close(текущий); текущий = следующий
            }
        }
    }

    static func объект(_ данные: Data) -> String {
        let полные = Data("blob \(данные.count)\0".utf8) + данные
        return Insecure.SHA1.hash(data: полные).map { String(format: "%02x", $0) }.joined()
    }
}

struct ОградыПакета: Codable, Equatable, Sendable {
    var план_совпадает: Bool
    var снимок_совпадает: Bool
    var индекс_совпадает: Bool
    var пути_разрешены: Bool
}

struct ВходРешенияПакета: Codable, Equatable, Sendable {
    var схема = "fum.нормализованный-допуск-пакета-девяти-путей.1"
    var ограды: ОградыПакета
    var число_переносов: Int
    var состояние_намерения: String
}

struct РешениеПакета: Codable, Equatable, Sendable {
    var допустить_применение: Bool
    var применение: String
    var причина: String?
}

struct РезультатРешенияПакета: Sendable {
    var решение: РешениеПакета
    var наблюдение: Data
}

enum ПравилаПакета {
    static let хэшОпределения = "72cc8b8793ccfda05abc79e660b30887897f08b8ede1110b0a1b2ed52636b8d8"

    static func выполнить(_ вход: ВходРешенияПакета) throws -> РезультатРешенияПакета {
        guard let адрес = Bundle.module.url(forResource: "paket-perenosa", withExtension: "json") else {
            throw ОшибкаПутей.отказ("Нет закреплённого определения пакета")
        }
        let данные = try Data(contentsOf: адрес)
        guard хэшПутей(данные) == хэшОпределения else {
            throw ОшибкаПутей.отказ("Дрейф структурирующего определения")
        }
        let определение = try ОпределениеОператора.разобрать(данные)
        let наблюдение = try AutomationExecutor.выполнить(определение,
            вход: .текст(String(decoding: байтыПлана(вход), as: UTF8.self)),
            пределы: ПределыИсполнения(байтовВхода: 4096, байтовРезультата: 4096,
                операций: 100_000, записейТрассы: 16))
        guard case .текст(let результат) = наблюдение.результат else {
            throw ОшибкаПутей.отказ("Решение пакета не является JSON")
        }
        return РезультатРешенияПакета(
            решение: try JSONDecoder().decode(РешениеПакета.self, from: Data(результат.utf8)),
            наблюдение: try байтыПлана(наблюдение))
    }
}
