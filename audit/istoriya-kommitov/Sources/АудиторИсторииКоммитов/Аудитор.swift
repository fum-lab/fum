import Foundation

public enum ОшибкаАудита: Error, CustomStringConvertible, Sendable {
    case неверныйOID(String)
    case повреждённыйКоммит(String)
    case неверныйUTF8(String)
    case командаGitНеВыполнена(String, Int32)
    case превышенПределВывода(String)
    case нетПервогоРодителя(String)
    case пустаяОбласть
    case небезопаснаяОбласть(String)
    case областьНеНайдена(String)
    case нетКоммитов
    case слишкомМногоКоммитов(Int)

    public var description: String {
        switch self {
        case .неверныйOID(let значение):
            "Некорректный Git OID: \(значение)"
        case .повреждённыйКоммит(let значение):
            "Повреждённый commit object \(значение)"
        case .неверныйUTF8(let значение):
            "Объект не является UTF-8: \(значение)"
        case .командаGitНеВыполнена(let команда, let код):
            "Git завершился с кодом \(код): \(команда)"
        case .превышенПределВывода(let команда):
            "Git вывел больше 1 MiB: \(команда)"
        case .нетПервогоРодителя(let значение):
            "У коммита нет первого родителя для чтения контракта: \(значение)"
        case .пустаяОбласть:
            "Нужна явная ограниченная область проверки; корень репозитория запрещён."
        case .небезопаснаяОбласть(let значение):
            "Некорректный относительный путь области: \(значение)"
        case .областьНеНайдена(let значение):
            "Область не совпадает ни с одним путём HEAD или индекса: \(значение)"
        case .нетКоммитов:
            "Нужно явно передать хотя бы один commit OID."
        case .слишкомМногоКоммитов(let число):
            "За один проход допускается не более 64 явно заданных OID; получено \(число)."
        }
    }
}

public struct СведенияЛичности: Sendable, Equatable {
    public let имя: String
    public let почта: String
    public let времяUnix: Int64
    public let часовойПояс: String

    public var подписьМодели: ПодписьМодели? {
        Классификатор.извлечьПодписьМодели(имя)
    }
}

public struct СведенияКоммита: Sendable, Equatable {
    public let OID: String
    public let деревоOID: String
    public let родители: [String]
    public let автор: СведенияЛичности
    public let фиксатор: СведенияЛичности
    public let сообщение: String

    public var тема: String {
        сообщение.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
    }

    public var последняяСтрокаСообщения: String {
        сообщение.split(whereSeparator: \.isNewline).last.map(String.init) ?? ""
    }

    public var значениеКорневогоTrailer: String {
        let начало = "Codex-Thread-ID: "
        let строка = последняяСтрокаСообщения
        guard строка.hasPrefix(начало) else { return "" }
        return String(строка.dropFirst(начало.count))
    }
}

public enum РазборщикКоммита {
    public static func разобрать(_ данные: Data, OID: String) throws -> СведенияКоммита {
        guard Классификатор.корректныйOID(OID) else { throw ОшибкаАудита.неверныйOID(OID) }
        guard let сыройТекст = String(data: данные, encoding: .utf8) else {
            throw ОшибкаАудита.неверныйUTF8(OID)
        }
        guard let граница = сыройТекст.range(of: "\n\n") else {
            throw ОшибкаАудита.повреждённыйКоммит(OID)
        }
        let заголовки = сыройТекст[..<граница.lowerBound].split(separator: "\n")
        let сообщение = String(сыройТекст[граница.upperBound...])
        guard let строкаДерева = заголовки.first(where: { $0.hasPrefix("tree ") }) else {
            throw ОшибкаАудита.повреждённыйКоммит(OID)
        }
        let дерево = String(строкаДерева.dropFirst("tree ".count))
        guard Классификатор.корректныйOID(дерево) else {
            throw ОшибкаАудита.повреждённыйКоммит(OID)
        }
        let родители = заголовки.compactMap { строка -> String? in
            guard строка.hasPrefix("parent ") else { return nil }
            return String(строка.dropFirst("parent ".count))
        }
        guard родители.allSatisfy({ Классификатор.корректныйOID($0) }),
              let строкаАвтора = заголовки.first(where: { $0.hasPrefix("author ") }),
              let строкаФиксатора = заголовки.first(where: { $0.hasPrefix("committer ") }) else {
            throw ОшибкаАудита.повреждённыйКоммит(OID)
        }
        let автор = try разобратьЛичность(String(строкаАвтора.dropFirst("author ".count)), OID: OID)
        let фиксатор = try разобратьЛичность(String(строкаФиксатора.dropFirst("committer ".count)), OID: OID)
        return СведенияКоммита(OID: OID, деревоOID: дерево, родители: родители,
            автор: автор, фиксатор: фиксатор, сообщение: сообщение)
    }

    private static func разобратьЛичность(_ значение: String, OID: String) throws -> СведенияЛичности {
        let поля = значение.split(separator: " ", omittingEmptySubsequences: true)
        guard поля.count >= 4,
              let время = Int64(String(поля[поля.count - 2])) else {
            throw ОшибкаАудита.повреждённыйКоммит(OID)
        }
        let пояс = String(поля[поля.count - 1])
        guard пояс.utf8.count == 5,
              пояс.first == "+" || пояс.first == "-",
              пояс.dropFirst().utf8.allSatisfy({ (0x30...0x39).contains($0) }) else {
            throw ОшибкаАудита.повреждённыйКоммит(OID)
        }
        let полеПочты = String(поля[поля.count - 3])
        guard полеПочты.hasPrefix("<"), полеПочты.hasSuffix(">") else {
            throw ОшибкаАудита.повреждённыйКоммит(OID)
        }
        let имя = поля.dropLast(3).joined(separator: " ")
        guard !имя.isEmpty else { throw ОшибкаАудита.повреждённыйКоммит(OID) }
        let почта = String(полеПочты.dropFirst().dropLast())
        return СведенияЛичности(имя: имя, почта: почта, времяUnix: время, часовойПояс: пояс)
    }
}

public struct СнимокПравил: Codable, Sendable, Equatable {
    public let первыйРодительOID: String
    public let файлПравилOID: String
    public let правилоАвтораАктивно: Bool
    public let правилоСообщенияАктивно: Bool

    public init(первыйРодительOID: String, файлПравилOID: String, текст: String) {
        self.первыйРодительOID = первыйРодительOID
        self.файлПравилOID = файлПравилOID
        self.правилоАвтораАктивно = текст.contains("<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000063 -->")
        self.правилоСообщенияАктивно = текст.contains("<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000201 -->")
    }
}

public struct ЗаписьАудита: Codable, Sendable, Equatable {
    public let OID: String
    public let деревоOID: String
    public let родители: [String]
    public let авторИмя: String
    public let авторПочта: String
    public let авторВремяUnix: Int64
    public let авторПояс: String
    public let авторМодель: String
    public let авторУсилие: String
    public let совпадениеФорматаИмениАвтора: ИтогСовпаденияФорматаИмениАвтора
    public let статусНативногоПодтвержденияАвтора: СтатусНативногоПодтвержденияАвтора
    public let фиксаторИмя: String
    public let фиксаторПочта: String
    public let фиксаторВремяUnix: Int64
    public let фиксаторПояс: String
    public let тема: String
    public let сигналТемы: СигналТемы
    public let последняяСтрокаСообщения: String
    public let значениеCodexThreadID: String
    public let trailerСовпадаетСКорневымUUID: Bool
    public let контрактПервогоРодителяOID: String
    public let файлПравилOID: String
    public let правилоСообщенияАктивно: Bool
    public let числоРодителей: Int
    public let этоПринятыйROOT: Bool
    public let уROOTДваРодителя: Bool
    public let авторОтличаетсяОтROOT: Bool

    public init(коммит: СведенияКоммита, правила: СнимокПравил,
                принятыйROOT: СведенияКоммита, корневойUUID: String) {
        let подпись = коммит.автор.подписьМодели
        let этоROOT = коммит.OID == принятыйROOT.OID
        self.OID = коммит.OID
        self.деревоOID = коммит.деревоOID
        self.родители = коммит.родители
        self.авторИмя = коммит.автор.имя
        self.авторПочта = коммит.автор.почта
        self.авторВремяUnix = коммит.автор.времяUnix
        self.авторПояс = коммит.автор.часовойПояс
        self.авторМодель = подпись?.модель ?? ""
        self.авторУсилие = подпись?.усилие ?? ""
        self.совпадениеФорматаИмениАвтора = Классификатор.итогСовпаденияФорматаИмениАвтора(
            коммит.автор.имя, правилоАктивно: правила.правилоАвтораАктивно)
        self.статусНативногоПодтвержденияАвтора = .неПроверено
        self.фиксаторИмя = коммит.фиксатор.имя
        self.фиксаторПочта = коммит.фиксатор.почта
        self.фиксаторВремяUnix = коммит.фиксатор.времяUnix
        self.фиксаторПояс = коммит.фиксатор.часовойПояс
        self.тема = коммит.тема
        self.сигналТемы = Классификатор.сигналТемы(коммит.тема)
        self.последняяСтрокаСообщения = коммит.последняяСтрокаСообщения
        self.значениеCodexThreadID = коммит.значениеКорневогоTrailer
        self.trailerСовпадаетСКорневымUUID = коммит.значениеКорневогоTrailer == корневойUUID
        self.контрактПервогоРодителяOID = правила.первыйРодительOID
        self.файлПравилOID = правила.файлПравилOID
        self.правилоСообщенияАктивно = правила.правилоСообщенияАктивно
        self.числоРодителей = коммит.родители.count
        self.этоПринятыйROOT = этоROOT
        self.уROOTДваРодителя = этоROOT && коммит.родители.count == 2
        self.авторОтличаетсяОтROOT = !этоROOT && коммит.автор.имя != принятыйROOT.автор.имя
    }
}

public struct ПривязкаРабочегоДерева: Codable, Sendable, Equatable {
    public let текущийHEAD: String
    public let деревоHEAD: String
    public let область: [String]
    public let индексСовпадаетСHEADВОбласти: Bool
    public let рабочиеФайлыСовпадаютСИндексомВОбласти: Bool
    public let нетНеотслеживаемыхВОбласти: Bool
    public let деревоСвязаноСHEADВОбласти: Bool

    public init(текущийHEAD: String, деревоHEAD: String, область: [String],
                индексСовпадаетСHEADВОбласти: Bool,
                рабочиеФайлыСовпадаютСИндексомВОбласти: Bool,
                нетНеотслеживаемыхВОбласти: Bool,
                деревоСвязаноСHEADВОбласти: Bool) {
        self.текущийHEAD = текущийHEAD
        self.деревоHEAD = деревоHEAD
        self.область = область
        self.индексСовпадаетСHEADВОбласти = индексСовпадаетСHEADВОбласти
        self.рабочиеФайлыСовпадаютСИндексомВОбласти = рабочиеФайлыСовпадаютСИндексомВОбласти
        self.нетНеотслеживаемыхВОбласти = нетНеотслеживаемыхВОбласти
        self.деревоСвязаноСHEADВОбласти = деревоСвязаноСHEADВОбласти
    }
}

public struct ОтчётАудита: Codable, Sendable, Equatable {
    public let схема: String
    public let корневойUUID: String
    public let принятыйROOT: String
    public let авторROOT: String
    public let коммиты: [ЗаписьАудита]
    public let привязкаТекущейРабочейОбласти: ПривязкаРабочегоДерева

    public init(схема: String, корневойUUID: String, принятыйROOT: String,
                авторROOT: String, коммиты: [ЗаписьАудита],
                привязкаТекущейРабочейОбласти: ПривязкаРабочегоДерева) {
        self.схема = схема
        self.корневойUUID = корневойUUID
        self.принятыйROOT = принятыйROOT
        self.авторROOT = авторROOT
        self.коммиты = коммиты
        self.привязкаТекущейРабочейОбласти = привязкаТекущейРабочейОбласти
    }
}

public struct ЧитательИстории: Sendable {
    public static let путьФайлаПравил = "Правила/агентов/Git-и-рабочая-сессия.md"

    private let корень: URL
    private let пределВывода = 1_048_576

    public init(корень: URL) {
        self.корень = корень.standardizedFileURL
    }

    public func прочитатьКоммит(_ OID: String) throws -> СведенияКоммита {
        guard Классификатор.корректныйOID(OID) else { throw ОшибкаАудита.неверныйOID(OID) }
        let вывод = try выполнить(["cat-file", "commit", OID])
        return try РазборщикКоммита.разобрать(вывод.данные, OID: OID)
    }

    public func прочитатьПравила(_ коммит: СведенияКоммита) throws -> СнимокПравил {
        guard let первыйРодитель = коммит.родители.first else {
            throw ОшибкаАудита.нетПервогоРодителя(коммит.OID)
        }
        let spec = "\(первыйРодитель):\(Self.путьФайлаПравил)"
        let blobВывод = try выполнить(["rev-parse", "--verify", spec])
        let blobOID = try текст(blobВывод.данные, команда: "rev-parse <parent>:<policy-path>")
        guard Классификатор.корректныйOID(blobOID) else {
            throw ОшибкаАудита.повреждённыйКоммит(коммит.OID)
        }
        let данныеПравил = try выполнить(["cat-file", "blob", blobOID])
        let текстПравил = try текст(данныеПравил.данные, команда: "cat-file blob \(blobOID)")
        return СнимокПравил(первыйРодительOID: первыйРодитель, файлПравилOID: blobOID,
            текст: текстПравил)
    }

    public func проверитьПривязку(области: [String]) throws -> ПривязкаРабочегоДерева {
        guard !области.isEmpty else { throw ОшибкаАудита.пустаяОбласть }
        guard Set(области).count == области.count else {
            throw ОшибкаАудита.небезопаснаяОбласть("повторяющаяся область")
        }
        for путь in области {
            let части = путь.split(separator: "/", omittingEmptySubsequences: false)
            guard !путь.isEmpty, путь != ".", !путь.hasPrefix("/"),
                  !путь.hasPrefix(":("), !части.contains(".."), !части.contains(".") else {
                throw ОшибкаАудита.небезопаснаяОбласть(путь)
            }
        }
        let headВывод = try выполнить(["rev-parse", "--verify", "HEAD"])
        let деревоВывод = try выполнить(["rev-parse", "--verify", "HEAD^{tree}"])
        let head = try текст(headВывод.данные, команда: "rev-parse HEAD")
        let дерево = try текст(деревоВывод.данные, команда: "rev-parse HEAD^{tree}")
        for путь in области {
            let вHEAD = try выполнить(["ls-tree", "-r", "--name-only", "HEAD", "--", путь],
                буквальныеПути: true)
            let вИндексе = try выполнить(["ls-files", "--cached", "--", путь],
                буквальныеПути: true)
            guard !вHEAD.данные.isEmpty || !вИндексе.данные.isEmpty else {
                throw ОшибкаАудита.областьНеНайдена(путь)
            }
        }
        let индексРезультат = try выполнить(
            ["diff", "--quiet", "--cached", "HEAD", "--"] + области,
            допустимыеКоды: [0, 1], буквальныеПути: true)
        let рабочийРезультат = try выполнить(["diff", "--quiet", "--"] + области,
            допустимыеКоды: [0, 1], буквальныеПути: true)
        let неотслеживаемыеВывод = try выполнить(
            ["ls-files", "--others", "--exclude-standard", "--"] + области,
            буквальныеПути: true)
        let неотслеживаемые = try текст(неотслеживаемыеВывод.данные, команда: "ls-files --others")
            .split(whereSeparator: \.isNewline)
        let индексСовпадает = индексРезультат.код == 0
        let рабочиеФайлыСовпадают = рабочийРезультат.код == 0
        let нетНеотслеживаемых = неотслеживаемые.isEmpty
        return ПривязкаРабочегоДерева(текущийHEAD: head, деревоHEAD: дерево,
            область: области, индексСовпадаетСHEADВОбласти: индексСовпадает,
            рабочиеФайлыСовпадаютСИндексомВОбласти: рабочиеФайлыСовпадают,
            нетНеотслеживаемыхВОбласти: нетНеотслеживаемых,
            деревоСвязаноСHEADВОбласти: индексСовпадает && рабочиеФайлыСовпадают && нетНеотслеживаемых)
    }

    private func текст(_ данные: Data, команда: String) throws -> String {
        guard let строка = String(data: данные, encoding: .utf8) else {
            throw ОшибкаАудита.неверныйUTF8(команда)
        }
        return строка.trimmingCharacters(in: .newlines)
    }

    private func выполнить(
        _ аргументы: [String], допустимыеКоды: Set<Int32> = [0], буквальныеПути: Bool = false
    ) throws -> (код: Int32, данные: Data) {
        let команда = аргументы.joined(separator: " ")
        let процесс = Process()
        let выход = Pipe()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        let режимПутей = буквальныеПути ? ["--literal-pathspecs"] : []
        процесс.arguments = режимПутей + ["-C", корень.path] + аргументы
        процесс.standardOutput = выход
        процесс.standardError = FileHandle.standardError
        do {
            try процесс.run()
        } catch {
            throw ОшибкаАудита.командаGitНеВыполнена(команда, -1)
        }
        var данные = Data()
        while true {
            let часть = try выход.fileHandleForReading.read(upToCount: 4_096) ?? Data()
            if часть.isEmpty { break }
            данные.append(часть)
            if данные.count > пределВывода {
                процесс.terminate()
                процесс.waitUntilExit()
                throw ОшибкаАудита.превышенПределВывода(команда)
            }
        }
        процесс.waitUntilExit()
        guard допустимыеКоды.contains(процесс.terminationStatus) else {
            throw ОшибкаАудита.командаGitНеВыполнена(команда, процесс.terminationStatus)
        }
        return (процесс.terminationStatus, данные)
    }
}

public struct АудиторИстории: Sendable {
    private let читатель: ЧитательИстории

    public init(читатель: ЧитательИстории) {
        self.читатель = читатель
    }

    public func проверить(корневойUUID: String, принятыйROOTOID: String,
                          OIDКоммитов: [String], области: [String]) throws -> ОтчётАудита {
        guard !OIDКоммитов.isEmpty else { throw ОшибкаАудита.нетКоммитов }
        guard OIDКоммитов.count <= 64 else { throw ОшибкаАудита.слишкомМногоКоммитов(OIDКоммитов.count) }
        let root = try читатель.прочитатьКоммит(принятыйROOTOID)
        let записи = try OIDКоммитов.map { oid -> ЗаписьАудита in
            let коммит = try читатель.прочитатьКоммит(oid)
            let правила = try читатель.прочитатьПравила(коммит)
            return ЗаписьАудита(коммит: коммит, правила: правила,
                принятыйROOT: root, корневойUUID: корневойUUID)
        }
        let привязка = try читатель.проверитьПривязку(области: области)
        return ОтчётАудита(схема: "fum.git-memory-commit-audit.cli.v1",
            корневойUUID: корневойUUID, принятыйROOT: root.OID, авторROOT: root.автор.имя,
            коммиты: записи, привязкаТекущейРабочейОбласти: привязка)
    }
}

public enum КодировщикJSONАудита {
    public static func закодировать(_ отчёт: ОтчётАудита) throws -> Data {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var данные = try кодировщик.encode(отчёт)
        данные.append(0x0a)
        return данные
    }
}
