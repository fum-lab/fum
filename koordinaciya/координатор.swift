import CryptoKit
import Foundation

struct СостояниеКоординации: Codable {
    let схема: String
    let корневойUUID: String
    let принятаяОснова: String
    let собственныйСтарт: СтартКоординации
    let модельУзла: МодельУзлаКоординации
    let корневойWorktree: СостояниеКорневогоWorktree
    let задачи: [ЗадачаКоординации]
    let переходыСостояния: [ПереходСостояния]
    let поставки: [ПакетПоставки]
    let переходыАвтоматизации: [ПереходАвтоматизации]
    let снимокБалансировки: СнимокБалансировки?
    let пакетыПоручений: [СнимокПоручений]?
    let точныеГрязныеПути: [String]?
    let точныеГрязныеПутиПолноеПокрытие: Bool?
    let планСамообновления: ПланСамообновления?
}

enum СостояниеПути: String, Equatable {
    case найден
    case отсутствует
    case неизвестно
}

struct СвидетельствоПокрытияПути {
    let путьНайден: Bool
    let полноеПокрытие: Bool
    let выводУсечён: Bool
}

enum КлассификаторПокрытияПути {
    static func оценить(_ свидетельство: СвидетельствоПокрытияПути) -> СостояниеПути {
        if свидетельство.путьНайден {
            return .найден
        }
        guard свидетельство.полноеПокрытие, !свидетельство.выводУсечён else {
            return .неизвестно
        }
        return .отсутствует
    }
}

struct ЗаписьНаблюденияПоручения: Codable {
    let имя: String
    let статусХода: String
    let времяСтарта: Int64?
    let новыйСтарт: Bool
    let поручениеПодхвачено: Bool
}

struct СнимокПоручений: Codable {
    let группа: String
    let числоНазначено: Int
    let числоНаблюдено: Int
    let выводУсечён: Bool
    let записи: [ЗаписьНаблюденияПоручения]
}

struct ИтогНаблюденияПоручений: Codable {
    let группа: String
    let покрытиеПолное: Bool
    let назначено: Int
    let наблюдено: Int
    let доказаноИсполняется: Int
    let фактическиНачато: Int?
    let новыеХоды: Int
    let продолжённыеХоды: Int
    let неНачато: Int?
    let ошибки: [String]
}

struct БалансУзлов: Codable {
    let активные: Int
    let бездействующие: Int
    let неЗагруженные: Int
    let видимые: Int
}

struct СнимокБалансировки: Codable {
    let до: БалансУзлов
    let после: БалансУзлов
    let источникСхема: String
    let источникSHA256: String
}

struct ИтогБалансировки: Codable {
    let до: БалансУзлов
    let после: БалансУзлов
    let изменениеАктивных: Int
    let изменениеБездействующих: Int
    let изменениеНезагруженных: Int
    let сбалансирован: Bool
    let источникSHA256: String
    let ошибки: [String]
}

struct РезультатПересеченияПутей: Codable {
    let идентификатор: String
    let числоПутейПакета: Int
    let числоГрязныхПутей: Int
    let манифестПолный: Bool
    let пересечения: [String]
}

struct СтартКоординации: Codable {
    let реф: String
    let oid: String
    let чистоеДерево: Bool
}

struct МодельУзлаКоординации: Codable {
    let веткаЯвляетсяУзлом: Bool
    let собственнаяПамять: String
    let дочерниеУзлы: [String]
    let деревоСодержит: [String]
    let общаяПамять: String
    let процесс: String
    let полноеДеревоПовтореноВJSON: Bool
    let последнийКоммитВосстановления: String?
}

struct СостояниеКорневогоWorktree: Codable {
    let реф: String
    let oid: String
    let родители: [String]
    let автор: String
    let коммитер: String
    let датаАвтора: String
    let корневойUUIDВКоммите: String
    let изменённыеПути: [String]
    let новыеПути: [String]
    let атрибуцияИсполнителя: String
    let авторСтарогоИзменённогоПути: String
    let поручениеИПолномочия: String
    let диагноз: String
    let текущаяЗаписьВЭтойОбластиЗапрещена: Bool
}

struct ЗадачаКоординации: Codable {
    let ключ: String
    let статус: String
    let ход: String
    let последняяРабота: String
    let ожидание: String
    let граница: String?
}

struct ПереходСостояния: Codable {
    let идентификатор: String
    let область: String
    let планПодготовлен: Bool?
    let отправлено: Bool?
    let выполнениеНачато: Bool?
    let применениеЗаявлено: Bool?
    let независимыйВывод: String?
    let свидетельствоНезависимогоНаблюдения: String?
}

struct ПакетПоставки: Codable {
    let идентификатор: String
    let вид: String
    let номер: Int?
    let состояние: String
    let слито: Bool
    let черновик: Bool?
    let сходимость: Bool?
    let основание: String
    let голова: String
    let дерево: String
    let родители: [String]
    let пути: [String]
    let файловИзменено: Int
    let ожидаетсяФайлов: Int
    let обзор: String
    let принятоКорнем: Bool
    let коммитПриёмки: String?
    let грязныйИсточникИспользован: Bool
    let установкаГотова: Bool
    let препятствия: [String]
    let непроверенныеЗаявления: [String]
}

struct СобственныйACK: Codable {
    let версия: String
    let область: String
    let источникРеф: String
    let источникOID: String
    let применённыйOID: String
    let корневойUUID: String
}

struct ОбзорИсточникаСамообновления: Codable {
    let источникРеф: String
    let источникOID: String
    let решение: String
    let свидетельство: String
}

struct ПринятиеИсточникаСамообновления: Codable {
    let источникРеф: String
    let источникOID: String
    let принял: String
    let свидетельство: String
}

struct СвидетельствоОбратногоСлияния: Codable {
    let коммитOID: String
    let родители: [String]
}

struct ПроверкаОбластиСамообновления: Codable {
    let коммитOID: String
    let пути: [String]
    let полноеПокрытие: Bool
    let свидетельство: String
}

struct ПереходСамообновления: Codable {
    let источникРеф: String
    let источникOID: String
    let источникДерево: String
    let область: String
    let назначение: String
    let получено: Bool
    let обзор: ОбзорИсточникаСамообновления?
    let принятие: ПринятиеИсточникаСамообновления?
    let обратноеСлияние: СвидетельствоОбратногоСлияния?
    let проверкаОбласти: ПроверкаОбластиСамообновления?
    let собственныйACK: СобственныйACK?
    let удержание: String?
}

struct ПланСамообновления: Codable {
    let собственныйКонтрольныйКоммит: String
    let собственныйРеф: String
    let собственнаяОбласть: String
    let текущаяВерсия: String
    let источники: [ПереходСамообновления]
    let требуетHEADРавныйROOT: Bool
    let требуетЧтениеROOTJSONL: Bool
    let старыйГлобальныйПорогДискаДляИсточникаГиБ: Int?
    let идентичностьСледующегоКоммита: ОжидаемаяИдентичностьGit
    let сообщениеСледующегоКоммита: ПланСообщенияКоммита
}

enum ОшибкаПотребителяБайтСообщенияFUMA: Error, Equatable {
    case сообщениеНеЯвляетсяUTF8
    case подготовленныеБайтыНеСовпадают
}

enum ПотребительБайтСообщенияFUMA {
    static func подготовить(
        фактическиеБайтыFUMA: Data,
        вФайл файл: URL
    ) throws -> Data {
        guard String(data: фактическиеБайтыFUMA, encoding: .utf8) != nil else {
            throw ОшибкаПотребителяБайтСообщенияFUMA.сообщениеНеЯвляетсяUTF8
        }
        try фактическиеБайтыFUMA.write(to: файл, options: .atomic)
        let подготовленныеБайты = try Data(contentsOf: файл)
        guard подготовленныеБайты == фактическиеБайтыFUMA else {
            throw ОшибкаПотребителяБайтСообщенияFUMA.подготовленныеБайтыНеСовпадают
        }
        return подготовленныеБайты
    }

    static func выполнитьПередGitЭффектом<T>(
        исходныеБайтыFUMA: Data,
        подготовленныеБайты: Data,
        выполнитьGitЭффект: () throws -> T
    ) throws -> T {
        guard String(data: исходныеБайтыFUMA, encoding: .utf8) != nil else {
            throw ОшибкаПотребителяБайтСообщенияFUMA.сообщениеНеЯвляетсяUTF8
        }
        guard подготовленныеБайты == исходныеБайтыFUMA else {
            throw ОшибкаПотребителяБайтСообщенияFUMA.подготовленныеБайтыНеСовпадают
        }
        return try выполнитьGitЭффект()
    }
}

struct РезультатСамообновления: Codable {
    let контрольныйКоммит: String
    let независимаяРаботаРазрешена: Bool
    let требуетHEADРавныйROOT: Bool
    let требуетЧтениеROOTJSONL: Bool
    let решенияИсточников: [РешениеСамообновления]
    let ошибкиПлана: [String]
}

struct РешениеСамообновления: Codable {
    let источникРеф: String
    let источникOID: String
    let решение: ФазаСамообновления
    let ошибки: [String]
}

enum ФазаСамообновления: String, Codable {
    case полученоЖдётОбзора = "получено-ждёт-обзора"
    case обзорЖдётПринятия = "обзор-ждёт-принятия"
    case принятоЖдётОбратногоСлияния = "принято-ждёт-обратного-слияния"
    case примененоЖдётПроверки = "применено-ждёт-проверки"
    case провереноЖдётСобственногоACK = "проверено-ждёт-собственного-ack"
    case подтверждено = "подтверждено"
    case удержано = "удержано-в-своей-области"
    case некорректно = "некорректная-последовательность"
}

private struct FUMAОбёрткаОтвета: Decodable {
    struct Наблюдение: Decodable {
        struct Значение: Decodable {
            let тип: String
            let значение: String
        }
        let результат: Значение
    }
    let наблюдение: Наблюдение
}

struct РезультатЗапускаFUMA {
    let пакет: ПакетВыходаГенератораFUMA
    let canonicalOutput: Data
    let response: Data
    let evidenceDirectory: String
}

private struct СвидетельствоЗапускаFUMA: Encodable {
    let схема: String
    let граф: String
    let времяЗапуска: String
    let хэшОпределения: String
    let хэшОператора: String
    let хэшВхода: String
    let хэшСырогоОтвета: String
    let хэшРезультата: String
    let хэшиВыходовСценариев: [String: String]
}

enum ИсполнительГенератораFUMA {
    static func выполнить(
        input: ПакетВходаГенератораFUMA,
        definitionPath: String,
        operatorPath: String,
        privateRunRoot: String
    ) throws -> РезультатЗапускаFUMA {
        guard let definition = физическийПуть(definitionPath),
              let executable = физическийПуть(operatorPath),
              let runRoot = физическийПуть(privateRunRoot),
              FileManager.default.isExecutableFile(atPath: executable),
              FileManager.default.fileExists(atPath: definition) else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        guard let rootPermissions = try FileManager.default.attributesOfItem(atPath: runRoot)[.posixPermissions] as? NSNumber,
              rootPermissions.intValue & 0o077 == 0,
              !внутриGit(runRoot) else {
            throw CocoaError(.fileWriteNoPermission)
        }

        let runDirectory = URL(fileURLWithPath: runRoot, isDirectory: true)
            .appendingPathComponent("fuma-" + UUID().uuidString.lowercased(), isDirectory: true)
        try FileManager.default.createDirectory(at: runDirectory, withIntermediateDirectories: false,
                                                 attributes: [.posixPermissions: 0o700])
        let inputURL = runDirectory.appendingPathComponent("вход.json")
        let journalURL = runDirectory.appendingPathComponent("журнал", isDirectory: true)
        let outputURL = runDirectory.appendingPathComponent("stdout.json")
        let errorURL = runDirectory.appendingPathComponent("stderr.txt")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let inputBytes = try encoder.encode(input)
        try inputBytes.write(to: inputURL, options: .atomic)
        try FileManager.default.createDirectory(at: journalURL, withIntermediateDirectories: false,
                                                 attributes: [.posixPermissions: 0o700])
        guard FileManager.default.createFile(atPath: outputURL.path, contents: Data()),
              FileManager.default.createFile(atPath: errorURL.path, contents: Data()),
              let outputHandle = FileHandle(forWritingAtPath: outputURL.path),
              let errorHandle = FileHandle(forWritingAtPath: errorURL.path) else {
            throw CocoaError(.fileWriteUnknown)
        }
        defer {
            try? outputHandle.close()
            try? errorHandle.close()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = [
            "--выполнить-оператор",
            "--определение", definition,
            "--вход", inputURL.path,
            "--тип-входа", "текст",
            "--журнал", journalURL.path,
        ]
        process.environment = ProcessInfo.processInfo.environment
        process.standardOutput = outputHandle
        process.standardError = errorHandle
        try process.run()
        process.waitUntilExit()
        try outputHandle.synchronize()
        try errorHandle.synchronize()
        let response = try Data(contentsOf: outputURL)
        guard process.terminationStatus == 0,
              let envelope = try? JSONDecoder().decode(FUMAОбёрткаОтвета.self, from: response),
              envelope.наблюдение.результат.тип == "текст" else {
            let errorText = String(decoding: (try? Data(contentsOf: errorURL)) ?? Data(), as: UTF8.self)
            throw NSError(domain: "FUMAOperator", code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "FUMA operator failed; evidence retained at \(runDirectory.path): \(errorText)"])
        }
        let canonicalOutput = Data(envelope.наблюдение.результат.значение.utf8)
        guard let пакет = try? JSONDecoder().decode(ПакетВыходаГенератораFUMA.self, from: canonicalOutput) else {
            throw NSError(domain: "FUMAOperator", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "FUMA output did not match the typed output contract; evidence retained at \(runDirectory.path)"])
        }
        let canonicalOutputURL = runDirectory.appendingPathComponent("результат-fuma.json")
        try canonicalOutput.write(to: canonicalOutputURL, options: .atomic)
        let scenarioDirectory = runDirectory.appendingPathComponent("выходы-сценариев", isDirectory: true)
        try FileManager.default.createDirectory(at: scenarioDirectory, withIntermediateDirectories: false,
                                                 attributes: [.posixPermissions: 0o700])
        var scenarioHashes: [String: String] = [:]
        for item in пакет.cases {
            let data = try encoder.encode(item)
            let safeID = item.id.unicodeScalars.allSatisfy {
                CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_"
            } ? item.id : sha256(Data(item.id.utf8))
            try data.write(to: scenarioDirectory.appendingPathComponent(safeID + ".json"), options: .atomic)
            scenarioHashes[item.id] = sha256(data)
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let свидетельство = СвидетельствоЗапускаFUMA(
            схема: "fum.координация.fuma-execution-evidence.1",
            граф: "fuma.граф-JSON.1",
            времяЗапуска: formatter.string(from: Date()),
            хэшОпределения: sha256(try Data(contentsOf: URL(fileURLWithPath: definition))),
            хэшОператора: sha256(try Data(contentsOf: URL(fileURLWithPath: executable))),
            хэшВхода: sha256(inputBytes),
            хэшСырогоОтвета: sha256(response),
            хэшРезультата: sha256(canonicalOutput),
            хэшиВыходовСценариев: scenarioHashes
        )
        let evidenceEncoder = JSONEncoder()
        evidenceEncoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try evidenceEncoder.encode(свидетельство).write(
            to: runDirectory.appendingPathComponent("свидетельство.json"), options: .atomic
        )
        return РезультатЗапускаFUMA(
            пакет: пакет,
            canonicalOutput: canonicalOutput,
            response: response,
            evidenceDirectory: runDirectory.path
        )
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func физическийПуть(_ path: String) -> String? {
        guard path.hasPrefix("/") else { return nil }
        guard let pointer = realpath(path, nil) else { return nil }
        defer { free(pointer) }
        return String(cString: pointer)
    }

    static func внутриGit(_ path: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["rev-parse", "--show-toplevel"]
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return true
        }
        guard process.terminationStatus == 0 else { return true }
        let root = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return path == root || path.hasPrefix(root + "/")
    }
}

enum ОценщикИдентичностиGit {
    static func проверитьДоЭффекта(
        ожидаемая: ОжидаемаяИдентичностьGit,
        метаданные: РезультатГенерацииМетаданныхКоммита,
        текущийHEAD: String,
        текущийРеф: String,
        ожидаемыйРеф: String,
        expectedRootUUID: String
    ) -> [String] {
        var ошибки = метаданные.ошибки
        ошибки.append(contentsOf: ГенераторМетаданныхКоммита.проверитьReceipt(
            ожидаемая.квитанцияВыбораМодели,
            ожидаемый: ожидаемая.ожидаемаяКвитанцияВыбораМодели,
            expectedRootUUID: expectedRootUUID
        ))
        if метаданные.выборМодели != ожидаемая.квитанцияВыбораМодели?.свидетельство {
            ошибки.append("сгенерированные-метаданные-не-связаны-с-model-selection-receipt")
        }
        if let selection = ожидаемая.квитанцияВыбораМодели?.свидетельство.selectedValue {
            let expectedAuthor = "FUM Codex [\(selection.model); effort=\(selection.reasoningEffort)]"
            if метаданные.автор.имя != expectedAuthor {
                ошибки.append("author-не-совпадает-с-selected-model-value")
            }
            if метаданные.окружение != ["GIT_AUTHOR_NAME": expectedAuthor] {
                ошибки.append("environment-не-совпадает-с-selected-model-value")
            }
        }
        let expectedTrailer = "Codex-Thread-ID: \(expectedRootUUID)"
        if !метаданные.сообщение.hasSuffix("\n")
            || метаданные.сообщение.split(separator: "\n").last.map(String.init) != expectedTrailer {
            ошибки.append("message-не-содержит-конечный-root-trailer")
        }
        if текущийHEAD != ожидаемая.родитель {
            ошибки.append("head-не-равен-ожидаемому-родителю")
        }
        if текущийРеф != ожидаемыйРеф {
            ошибки.append("реф-не-совпадает-с-разрешённым")
        }
        if !верныйOID(ожидаемая.родитель) {
            ошибки.append("неверный-ожидаемый-родитель")
        }
        return ошибки
    }

    static func проверитьСыройОбъект(
        _ сыройКоммит: Data,
        метаданные: РезультатГенерацииМетаданныхКоммита,
        ожидаемыйParent: String,
        ожидаемоеДерево: String
    ) -> [String] {
        var ошибки = проверитьСыройКоммит(
            сыройКоммит,
            метаданные: метаданные,
            ожидаемыеРодители: [ожидаемыйParent],
            ожидаемоеДерево: ожидаемоеДерево,
            ошибкаНабораРодителей: "сырой-parent-не-совпадает"
        )
        if !верныйOID(ожидаемыйParent) { ошибки.append("неверный-ожидаемый-parent") }
        return ошибки
    }

    static func проверитьСыройMergeОбъект(
        _ сыройКоммит: Data,
        метаданные: РезультатГенерацииМетаданныхКоммита,
        ожидаемыеРодители: [String],
        ожидаемоеДерево: String
    ) -> [String] {
        var ошибки: [String] = []
        if ожидаемыеРодители.count != 2 {
            ошибки.append("неверное-число-ожидаемых-merge-родителей")
        }
        if ожидаемыеРодители.contains(where: { !верныйOID($0) }) {
            ошибки.append("неверный-ожидаемый-merge-parent")
        }
        if Set(ожидаемыеРодители).count != ожидаемыеРодители.count {
            ошибки.append("повторный-ожидаемый-merge-parent")
        }
        ошибки.append(contentsOf: проверитьСыройКоммит(
            сыройКоммит,
            метаданные: метаданные,
            ожидаемыеРодители: ожидаемыеРодители,
            ожидаемоеДерево: ожидаемоеДерево,
            ошибкаНабораРодителей: "сырой-merge-parent-набор-не-совпадает"
        ))
        return ошибки
    }

    static func проверитьСвязьПервогоРодителяСлиянияСПланом(
        ожидаемыеРодители: [String],
        родительПлана: String
    ) -> [String] {
        guard let первыйОжидаемыйРодитель = ожидаемыеРодители.first else {
            return ["нет-первого-ожидаемого-родителя-слияния"]
        }
        var ошибки: [String] = []
        if !верныйOID(родительПлана) {
            ошибки.append("неверный-родитель-плана")
        }
        if первыйОжидаемыйРодитель != родительПлана {
            ошибки.append("первый-ожидаемый-родитель-не-совпадает-с-планом")
        }
        return ошибки
    }

    private static func проверитьСыройКоммит(
        _ сыройКоммит: Data,
        метаданные: РезультатГенерацииМетаданныхКоммита,
        ожидаемыеРодители: [String],
        ожидаемоеДерево: String,
        ошибкаНабораРодителей: String
    ) -> [String] {
        guard let разделитель = сыройКоммит.range(of: Data([0x0a, 0x0a])) else {
            return ["нет-границы-заголовка-и-сообщения"]
        }
        let заголовкиБайтами = сыройКоммит[..<разделитель.lowerBound]
        let сообщениеБайтами = сыройКоммит[разделитель.upperBound...]
        guard let текстЗаголовков = String(data: заголовкиБайтами, encoding: .utf8),
              let сообщение = String(data: сообщениеБайтами, encoding: .utf8) else {
            return ["сырой-коммит-содержит-некорректный-utf8"]
        }
        let заголовки = текстЗаголовков.split(separator: "\n").map(String.init)
        let родители = заголовки.filter { $0.hasPrefix("parent ") }.map { String($0.dropFirst("parent ".count)) }
        let авторы = заголовки.filter { $0.hasPrefix("author ") }
        let коммитеры = заголовки.filter { $0.hasPrefix("committer ") }
        let деревья = заголовки.filter { $0.hasPrefix("tree ") }.map { String($0.dropFirst("tree ".count)) }
        var ошибки = метаданные.ошибки

        if родители != ожидаемыеРодители { ошибки.append(ошибкаНабораРодителей) }
        let author = ГенераторМетаданныхКоммита.разобратьGitIdent(авторы.first.map { String($0.dropFirst("author ".count)) } ?? "")
        if авторы.count != 1 || author != метаданные.автор { ошибки.append("сырой-author-не-совпадает") }
        let committer = ГенераторМетаданныхКоммита.разобратьGitIdent(коммитеры.first.map { String($0.dropFirst("committer ".count)) } ?? "")
        if коммитеры.count != 1 || committer != метаданные.коммитер { ошибки.append("сырой-committer-не-совпадает") }
        if !верныйOID(ожидаемоеДерево) { ошибки.append("неверное-ожидаемое-дерево") }
        if деревья != [ожидаемоеДерево] { ошибки.append("сырой-tree-не-совпадает-с-ожидаемым") }
        if сообщениеБайтами != Data(метаданные.сообщение.utf8) { ошибки.append("сырой-message-не-совпадает-с-генератором") }

        let последняяНепустаяСтрока = сообщение.split(separator: "\n").last.map(String.init)
        let точныйTrailer = "Codex-Thread-ID: \(метаданные.выборМодели.rootUUID)"
        if !сообщение.hasSuffix("\n") || последняяНепустаяСтрока != точныйTrailer {
            ошибки.append("сырой-корневой-trailer-не-совпадает")
        }
        return ошибки
    }

    private static func верныйOID(_ строка: String) -> Bool {
        строка.utf8.count == 40 && строка.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }
}

struct НаблюдениеПостЭффектаGit {
    let текущийHEAD: String
    let реф: String
    let адресаOrigin: [String]
    let типОбъекта: String
    let сыройКоммит: Data
    let вычисленныйOID: String
    let удалённыйOID: String?
}

struct ИтогПостЭффектнойПроверкиGit: Codable {
    let проверено: Bool
    let ошибки: [String]
    let текущийHEAD: String
    let реф: String
    let адресаOrigin: [String]
    let типОбъекта: String
    let вычисленныйOID: String
    let удалённыйOID: String?
}

enum АдаптерПостЭффектаGit {
    static func прочитать(ожидание: ОжидаемоеПостЭффектноеСостояниеGit) throws -> НаблюдениеПостЭффектаGit {
        let head = try строкаGit(["rev-parse", "--verify", "HEAD"])
        let ref = try строкаGit(["symbolic-ref", "--quiet", "HEAD"])
        let urls = try строкаGit(["remote", "get-url", "--all", "origin"])
            .split(whereSeparator: \.isNewline)
            .map(String.init)
        let тип = try строкаGit(["cat-file", "-t", ожидание.oidКоммита])
        let сыройКоммит = try выполнитьGit(["cat-file", "commit", ожидание.oidКоммита])
        let вычисленныйOID = try строкаGit(["hash-object", "-t", "commit", "--stdin"], stdin: сыройКоммит)
        let удалённыеСтроки = try строкаGit(["ls-remote", "--heads", "origin", ожидание.реф])
            .split(whereSeparator: \.isNewline)
        let удалённыеЗаписи = удалённыеСтроки.compactMap { line -> (String, String)? in
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { return nil }
            return (String(parts[0]), String(parts[1]))
        }
        let удалённыйOID: String?
        if удалённыеСтроки.isEmpty {
            удалённыйOID = nil
        } else if удалённыеЗаписи.count == 1 && удалённыеЗаписи[0].1 == ожидание.реф {
            удалённыйOID = удалённыеЗаписи[0].0
        } else {
            удалённыйOID = "<несколько-или-некорректные-записи>"
        }
        return НаблюдениеПостЭффектаGit(
            текущийHEAD: head,
            реф: ref,
            адресаOrigin: urls,
            типОбъекта: тип,
            сыройКоммит: сыройКоммит,
            вычисленныйOID: вычисленныйOID,
            удалённыйOID: удалённыйOID
        )
    }

    static func проверить(
        ожидание: ОжидаемоеПостЭффектноеСостояниеGit,
        наблюдение: НаблюдениеПостЭффектаGit,
        метаданные: РезультатГенерацииМетаданныхКоммита
    ) -> ИтогПостЭффектнойПроверкиGit {
        var ошибки: [String] = []
        if ожидание.схема != "fum.git-post-effect-expectation.1" { ошибки.append("неподдерживаемая-схема-post-effect") }
        if !верныйOID(ожидание.oidКоммита) { ошибки.append("неверный-ожидаемый-commit-oid") }
        if !верныйOID(ожидание.oidДерева) { ошибки.append("неверный-ожидаемый-tree-oid") }
        if !верныйOID(ожидание.oidРодителя) { ошибки.append("неверный-ожидаемый-parent-oid") }
        if let remoteOID = ожидание.удалённыйOID, !верныйOID(remoteOID) { ошибки.append("неверный-ожидаемый-remote-oid") }
        if !ожидание.реф.hasPrefix("refs/heads/") { ошибки.append("ожидается-полный-local-branch-ref") }
        if наблюдение.текущийHEAD != ожидание.oidКоммита { ошибки.append("head-oid-не-совпадает-с-независимым-ожиданием") }
        if наблюдение.вычисленныйOID != ожидание.oidКоммита { ошибки.append("raw-object-hash-не-совпадает-с-независимым-oid") }
        if наблюдение.реф != ожидание.реф { ошибки.append("symbolic-ref-не-совпадает-с-независимым-ожиданием") }
        if наблюдение.адресаOrigin != [ожидание.адресOrigin] { ошибки.append("origin-url-не-совпадает-с-независимым-ожиданием") }
        if наблюдение.типОбъекта != "commit" { ошибки.append("выбранный-git-объект-не-commit") }
        if наблюдение.удалённыйOID != ожидание.удалённыйOID { ошибки.append("origin-ref-не-совпадает-с-независимым-ожиданием") }
        ошибки.append(contentsOf: ОценщикИдентичностиGit.проверитьСыройОбъект(
            наблюдение.сыройКоммит,
            метаданные: метаданные,
            ожидаемыйParent: ожидание.oidРодителя,
            ожидаемоеДерево: ожидание.oidДерева
        ))
        return ИтогПостЭффектнойПроверкиGit(
            проверено: ошибки.isEmpty,
            ошибки: ошибки,
            текущийHEAD: наблюдение.текущийHEAD,
            реф: наблюдение.реф,
            адресаOrigin: наблюдение.адресаOrigin,
            типОбъекта: наблюдение.типОбъекта,
            вычисленныйOID: наблюдение.вычисленныйOID,
            удалённыйOID: наблюдение.удалённыйOID
        )
    }

    private static func строкаGit(_ аргументы: [String], stdin: Data? = nil) throws -> String {
        let data = try выполнитьGit(аргументы, stdin: stdin)
        guard let value = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return value.trimmingCharacters(in: .newlines)
    }

    private static func выполнитьGit(_ аргументы: [String], stdin: Data? = nil) throws -> Data {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = аргументы
        процесс.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        var environment = ProcessInfo.processInfo.environment
        environment["GIT_TERMINAL_PROMPT"] = "0"
        процесс.environment = environment
        let вывод = Pipe()
        let ввод = Pipe()
        процесс.standardOutput = вывод
        процесс.standardInput = ввод
        процесс.standardError = FileHandle.nullDevice
        do {
            try процесс.run()
            if let stdin {
                try ввод.fileHandleForWriting.write(contentsOf: stdin)
            }
            try ввод.fileHandleForWriting.close()
            let bytes = вывод.fileHandleForReading.readDataToEndOfFile()
            процесс.waitUntilExit()
            guard процесс.terminationStatus == 0 else {
                throw CocoaError(.fileReadUnknown)
            }
            return bytes
        } catch {
            if процесс.isRunning { процесс.terminate() }
            throw error
        }
    }

    private static func верныйOID(_ строка: String) -> Bool {
        строка.utf8.count == 40 && строка.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }
}

enum ОценщикСамообновления {
    static func оценить(_ план: ПланСамообновления, ожидаемыйКорневойUUID: String? = nil) -> РезультатСамообновления {
        var ошибкиПлана: [String] = []
        if !верныйOID(план.собственныйКонтрольныйКоммит) { ошибкиПлана.append("неверный-собственный-checkpoint") }
        if !план.собственныйРеф.hasPrefix("refs/heads/fum-lab/fum/") { ошибкиПлана.append("неверный-собственный-реф") }
        if план.собственнаяОбласть != "koordinaciya/**" { ошибкиПлана.append("область-самообновления-расширена") }
        if план.требуетHEADРавныйROOT { ошибкиПлана.append("запрещённое-глобальное-равенство-head") }
        if план.требуетЧтениеROOTJSONL { ошибкиПлана.append("запрещённый-root-jsonl-reader") }
        if план.старыйГлобальныйПорогДискаДляИсточникаГиБ != nil {
            ошибкиПлана.append("старый-глобальный-порог-диска-для-источника")
        }
        ошибкиПлана.append(contentsOf: ГенераторМетаданныхКоммита.проверитьReceipt(
            план.идентичностьСледующегоКоммита.квитанцияВыбораМодели,
            ожидаемый: план.идентичностьСледующегоКоммита.ожидаемаяКвитанцияВыбораМодели,
            expectedRootUUID: ожидаемыйКорневойUUID
        ))
        ошибкиПлана.append(contentsOf: ГенераторМетаданныхКоммита.проверитьЗаголовок(план.сообщениеСледующегоКоммита.заголовок))
        if план.сообщениеСледующегоКоммита.описание.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ошибкиПлана.append("пустое-описание-сообщения-коммита")
        }
        if план.сообщениеСледующегоКоммита.исходныйЗапрос.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ошибкиПлана.append("пустой-исходный-запрос-сообщения-коммита")
        }
        let корневойUUID = план.идентичностьСледующегоКоммита.квитанцияВыбораМодели?.свидетельство.rootUUID ?? ""
        if Set(план.источники.map(\.источникРеф)).count != план.источники.count {
            ошибкиПлана.append("повторный-источник-самообновления")
        }

        let решения = план.источники.map { переход in оценить(переход, версия: план.текущаяВерсия, корневойUUID: корневойUUID) }
        return РезультатСамообновления(
            контрольныйКоммит: план.собственныйКонтрольныйКоммит,
            независимаяРаботаРазрешена: true,
            требуетHEADРавныйROOT: план.требуетHEADРавныйROOT,
            требуетЧтениеROOTJSONL: план.требуетЧтениеROOTJSONL,
            решенияИсточников: решения,
            ошибкиПлана: ошибкиПлана
        )
    }

    static func оценитьРесурсныйДопуск(свободноГиБ: Int?, минимальныйРезервДляТяжёлойПроверкиГиБ: Int?, тяжёлаяПроверка: Bool) -> Bool {
        guard let свободноГиБ, свободноГиБ >= 0 else { return false }
        guard тяжёлаяПроверка else { return true }
        guard let минимальныйРезервДляТяжёлойПроверкиГиБ, минимальныйРезервДляТяжёлойПроверкиГиБ >= 0 else { return false }
        return свободноГиБ >= минимальныйРезервДляТяжёлойПроверкиГиБ
    }

    private static func оценить(_ источник: ПереходСамообновления, версия: String, корневойUUID: String) -> РешениеСамообновления {
        var ошибки: [String] = []
        if !источник.получено { ошибки.append("не-подтверждено-получение") }
        if !источник.источникРеф.hasPrefix("refs/heads/fum-lab/fum/") || !верныйOID(источник.источникOID) || !верныйOID(источник.источникДерево) {
            ошибки.append("некорректный-источник-самообновления")
        }
        if источник.область.isEmpty || источник.назначение.isEmpty { ошибки.append("пустая-область-или-назначение") }
        if источник.принятие != nil && источник.обзор == nil {
            ошибки.append("принято-до-обзора")
        }
        if let обзор = источник.обзор,
           обзор.источникРеф != источник.источникРеф || обзор.источникOID != источник.источникOID ||
            обзор.решение.isEmpty || обзор.свидетельство.isEmpty {
            ошибки.append("обзор-не-связан-с-источником")
        }
        if let принятие = источник.принятие {
            if источник.обзор == nil { ошибки.append("принято-до-обзора") }
            if принятие.источникРеф != источник.источникРеф || принятие.источникOID != источник.источникOID ||
                принятие.принял.isEmpty || принятие.свидетельство.isEmpty {
                ошибки.append("принятие-не-связано-с-точным-источником")
            }
        }
        if источник.обратноеСлияние != nil && источник.принятие == nil {
            ошибки.append("применено-до-принятия")
        }
        if let слияние = источник.обратноеСлияние {
            if !верныйOID(слияние.коммитOID) { ошибки.append("неверный-oid-обратного-слияния") }
            if слияние.родители.count < 2 || Set(слияние.родители).count != слияние.родители.count ||
                !слияние.родители.allSatisfy(верныйOID) || !слияние.родители.contains(источник.источникOID) {
                ошибки.append("обратное-слияние-не-содержит-точный-источник-в-родителях")
            }
        }
        if источник.проверкаОбласти != nil && источник.обратноеСлияние == nil {
            ошибки.append("проверено-до-применения")
        }
        if let проверка = источник.проверкаОбласти {
            if проверка.коммитOID != источник.обратноеСлияние?.коммитOID { ошибки.append("проверен-не-тот-коммит") }
            let префиксОбласти = источник.область.hasSuffix("/**")
                ? String(источник.область.dropLast(2))
                : источник.область
            if проверка.пути.isEmpty || проверка.пути.contains(where: { !безопасныйПуть($0) || !$0.hasPrefix(префиксОбласти) }) {
                ошибки.append("путь-проверки-вне-назначенной-области")
            }
            if !проверка.полноеПокрытие || проверка.свидетельство.isEmpty { ошибки.append("проверка-области-неполная") }
        }
        if источник.собственныйACK != nil && источник.проверкаОбласти == nil {
            ошибки.append("ack-до-проверки-области")
        }
        if let ack = источник.собственныйACK {
            if ack.версия != версия || ack.область != источник.область || ack.источникРеф != источник.источникРеф ||
                ack.источникOID != источник.источникOID || ack.применённыйOID != источник.проверкаОбласти?.коммитOID || ack.корневойUUID != корневойUUID {
                ошибки.append("собственный-ack-не-связывает-версию-область-и-источник")
            }
        }

        let фаза: ФазаСамообновления
        if !ошибки.isEmpty {
            фаза = .некорректно
        } else if источник.удержание != nil {
            фаза = .удержано
        } else if источник.собственныйACK != nil {
            фаза = .подтверждено
        } else if источник.проверкаОбласти != nil {
            фаза = .провереноЖдётСобственногоACK
        } else if источник.обратноеСлияние != nil {
            фаза = .примененоЖдётПроверки
        } else if источник.принятие != nil {
            фаза = .принятоЖдётОбратногоСлияния
        } else if источник.обзор != nil {
            фаза = .обзорЖдётПринятия
        } else {
            фаза = .полученоЖдётОбзора
        }
        return РешениеСамообновления(источникРеф: источник.источникРеф, источникOID: источник.источникOID, решение: фаза, ошибки: ошибки)
    }

    private static func верныйOID(_ строка: String) -> Bool {
        строка.utf8.count == 40 && строка.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private static func безопасныйПуть(_ строка: String) -> Bool {
        guard !строка.isEmpty, !строка.hasPrefix("/"), !строка.hasSuffix("/") else { return false }
        return строка.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
            !$0.isEmpty && $0 != "." && $0 != ".."
        }
    }
}

struct ПереходАвтоматизации: Codable {
    let вход: String
    let автоматизируемаяРабота: String
    let остаётсяРучным: String
}

struct СобытиеКоординации: Codable {
    let порядок: Int
    let идентификатор: String
    let корневойUUID: String
    let время: String
    let вид: String
    let свидетельство: String
    let исход: String?
}

enum РешениеПакета: String, Codable {
    case готовКПриёмкеКорнем = "готов-к-приёмке-корнем"
    case нуженАктуальныйКандидат = "нужен-кандидат-от-текущей-основы"
    case нуженОбзор = "нужен-обзор"
    case ожидаетПисателя = "ожидает-писателя"
    case заблокирован = "заблокирован"
    case принятоБезУстановки = "принято-контрольной-точкой-установка-не-готова"
    case принято = "принято-контрольной-точкой"
    case некорректен = "некорректен"
    case неГотов = "не-готов"
}

struct РезультатПакета: Codable {
    let идентификатор: String
    let решение: РешениеПакета
    let причины: [String]
    let голова: String
    let дерево: String
    let основание: String
    let пути: [String]
}

struct ИтогКоординации: Codable {
    let схема: String
    let действителен: Bool
    let корневойUUID: String
    let принятаяОснова: String
    let числоАктивныхЗадач: Int
    let ошибки: [String]
    let переходыСостояния: [РезультатПерехода]
    let пакеты: [РезультатПакета]
    let балансировка: ИтогБалансировки?
    let наблюденияПоручений: [ИтогНаблюденияПоручений]
    let пересеченияГрязныхПутей: [РезультатПересеченияПутей]
    let порученийИсполняется: Int
    let новыхХодов: Int
    let продолжённыхХодов: Int
    let фактическиНачатоПоручений: Int?
    let покрытиеПорученийПолное: Bool
    let самообновление: РезультатСамообновления?
}

enum ОценщикПоручений {
    static func оценить(_ снимок: СнимокПоручений) -> ИтогНаблюденияПоручений {
        var ошибки: [String] = []
        if снимок.группа.isEmpty {
            ошибки.append("пустая-группа-поручений")
        }
        if снимок.числоНазначено < 0 || снимок.числоНаблюдено < 0 || снимок.числоНаблюдено > снимок.числоНазначено {
            ошибки.append("неверный-счётчик-поручений")
        }
        if снимок.числоНаблюдено != снимок.записи.count {
            ошибки.append("счётчик-наблюдений-не-совпадает-с-записями")
        }
        if Set(снимок.записи.map(\.имя)).count != снимок.записи.count {
            ошибки.append("повторная-запись-поручения")
        }

        for запись in снимок.записи {
            if запись.имя.isEmpty || запись.статусХода.isEmpty {
                ошибки.append("пустое-поле-записи-поручения")
            }
            if запись.поручениеПодхвачено &&
                (запись.времяСтарта == nil || (запись.статусХода != "inProgress" && запись.статусХода != "completed")) {
                ошибки.append("заявленный-старт-без-свидетельства-хода")
            }
            if запись.новыйСтарт && (!запись.поручениеПодхвачено || запись.времяСтарта == nil) {
                ошибки.append("новый-старт-без-свидетельства")
            }
        }

        let начатые = снимок.записи.filter {
            $0.поручениеПодхвачено && $0.времяСтарта != nil &&
                ($0.статусХода == "inProgress" || $0.статусХода == "completed")
        }
        let исполняемые = начатые.filter { $0.статусХода == "inProgress" }
        let покрытиеПолное = ошибки.isEmpty && !снимок.выводУсечён &&
            снимок.числоНаблюдено == снимок.числоНазначено &&
            снимок.записи.count == снимок.числоНазначено

        return ИтогНаблюденияПоручений(
            группа: снимок.группа,
            покрытиеПолное: покрытиеПолное,
            назначено: снимок.числоНазначено,
            наблюдено: снимок.числоНаблюдено,
            доказаноИсполняется: исполняемые.count,
            фактическиНачато: покрытиеПолное ? начатые.count : nil,
            новыеХоды: начатые.filter(\.новыйСтарт).count,
            продолжённыеХоды: начатые.filter { !$0.новыйСтарт }.count,
            неНачато: покрытиеПолное ? снимок.числоНазначено - начатые.count : nil,
            ошибки: ошибки
        )
    }
}

enum ОценщикБалансировки {
    static func оценить(_ снимок: СнимокБалансировки) -> ИтогБалансировки {
        var ошибки: [String] = []

        func проверить(_ баланс: БалансУзлов, имя: String) {
            if баланс.активные < 0 || баланс.бездействующие < 0 || баланс.неЗагруженные < 0 || баланс.видимые < 0 {
                ошибки.append("отрицательный-счётчик-узлов-\(имя)")
            }
            if баланс.активные + баланс.бездействующие + баланс.неЗагруженные != баланс.видимые {
                ошибки.append("сумма-узлов-не-совпадает-\(имя)")
            }
        }

        проверить(снимок.до, имя: "до")
        проверить(снимок.после, имя: "после")
        let хэшКорректен = снимок.источникSHA256.utf8.count == 64 &&
            снимок.источникSHA256.utf8.allSatisfy {
                (48...57).contains($0) || (97...102).contains($0)
            }
        if !хэшКорректен {
            ошибки.append("неверный-sha256-источника-баланса")
        }

        return ИтогБалансировки(
            до: снимок.до,
            после: снимок.после,
            изменениеАктивных: снимок.после.активные - снимок.до.активные,
            изменениеБездействующих: снимок.после.бездействующие - снимок.до.бездействующие,
            изменениеНезагруженных: снимок.после.неЗагруженные - снимок.до.неЗагруженные,
            сбалансирован: ошибки.isEmpty,
            источникSHA256: снимок.источникSHA256,
            ошибки: ошибки
        )
    }
}

enum СверкаГрязныхПутей {
    static func пересечения(путиПакета: [String], точныеГрязныеПути: [String]) -> [String] {
        Array(Set(путиПакета).intersection(Set(точныеГрязныеПути))).sorted()
    }

    static func оценить(
        пакеты: [ПакетПоставки],
        точныеГрязныеПути: [String]?,
        полноеПокрытие: Bool
    ) -> [РезультатПересеченияПутей] {
        пакеты.map { пакет in
            РезультатПересеченияПутей(
                идентификатор: пакет.идентификатор,
                числоПутейПакета: пакет.пути.count,
                числоГрязныхПутей: точныеГрязныеПути?.count ?? 0,
                манифестПолный: полноеПокрытие && точныеГрязныеПути != nil,
                пересечения: точныеГрязныеПути.map {
                    пересечения(путиПакета: пакет.пути, точныеГрязныеПути: $0)
                } ?? []
            )
        }
    }
}

enum РешениеПерехода: String, Codable {
    case планЕщёНеОтправлен = "план-ещё-не-отправлен"
    case отправленоОжидаетСтарта = "отправлено-ожидает-старта"
    case начатоОжидаетПрименения = "начато-ожидает-применения"
    case применениеОжидаетНаблюдения = "заявлено-применение-ожидает-независимого-наблюдения"
    case применениеПодтверждено = "применение-подтверждено-независимым-наблюдением"
    case наблюдениеОпровергаетПрименение = "наблюдение-опровергает-заявленное-применение"
    case отсутствиеПримененияПодтверждено = "отсутствие-применения-подтверждено"
    case наблюдениеБезЗаявки = "наблюдение-без-заявки-о-применении"
    case неУстановлено = "не-установлено"
    case некорректен = "некорректная-последовательность"
}

struct РезультатПерехода: Codable {
    let идентификатор: String
    let решение: РешениеПерехода
    let ошибки: [String]
}

enum ЖурналКоординации {
    static func проверить(строки: String, корневойUUID: String) -> [String] {
        var ошибки: [String] = []

        guard строки.hasSuffix("\n") else {
            ошибки.append("неполный-JSONL-хвост")
            return ошибки
        }
        guard !строки.contains("\0"), !строки.contains("\r") else {
            ошибки.append("недопустимый-разделитель-JSONL")
            return ошибки
        }

        let записи = Array(строки.components(separatedBy: "\n").dropLast())
        var идентификаторы: Set<String> = []
        let декодер = JSONDecoder()

        for (индекс, строка) in записи.enumerated() {
            guard !строка.isEmpty,
                  let событие = try? декодер.decode(
                    СобытиеКоординации.self,
                    from: Data(строка.utf8)
                  ) else {
                ошибки.append("некорректная-запись-\(индекс + 1)")
                continue
            }

            if событие.порядок != индекс + 1 {
                ошибки.append("нарушен-порядок-\(индекс + 1)")
            }
            if событие.корневойUUID != корневойUUID {
                ошибки.append("неверный-корневой-uuid-\(индекс + 1)")
            }
            if !идентификаторы.insert(событие.идентификатор).inserted {
                ошибки.append("повторный-идентификатор-события")
            }
            if событие.идентификатор.isEmpty || событие.вид.isEmpty || событие.свидетельство.isEmpty || событие.время.isEmpty {
                ошибки.append("пустое-поле-события-\(индекс + 1)")
            }
        }

        return ошибки
    }
}

enum ОценщикПерехода {
    static func оценить(_ переход: ПереходСостояния) -> РезультатПерехода {
        var ошибки: [String] = []
        if переход.идентификатор.isEmpty || переход.область.isEmpty {
            ошибки.append("пустой-id-или-область-перехода")
        }
        if переход.отправлено == true && переход.планПодготовлен == false {
            ошибки.append("отправлено-без-плана")
        }
        if переход.выполнениеНачато == true && переход.отправлено == false {
            ошибки.append("начато-без-отправки")
        }
        if переход.применениеЗаявлено == true && переход.выполнениеНачато == false {
            ошибки.append("применение-без-старта")
        }
        if переход.независимыйВывод != nil && переход.свидетельствоНезависимогоНаблюдения == nil {
            ошибки.append("вывод-без-свидетельства-наблюдения")
        }
        if let вывод = переход.независимыйВывод, вывод != "подтверждено" && вывод != "опровергнуто" {
            ошибки.append("неизвестный-независимый-вывод")
        }
        if переход.независимыйВывод == "подтверждено" && переход.применениеЗаявлено == false {
            ошибки.append("подтверждено-не-заявленное-применение")
        }

        let решение: РешениеПерехода
        if !ошибки.isEmpty {
            решение = .некорректен
        } else if переход.применениеЗаявлено == true {
            switch переход.независимыйВывод {
            case "подтверждено": решение = .применениеПодтверждено
            case "опровергнуто": решение = .наблюдениеОпровергаетПрименение
            default: решение = .применениеОжидаетНаблюдения
            }
        } else if переход.применениеЗаявлено == false && переход.независимыйВывод == "опровергнуто" {
            решение = .отсутствиеПримененияПодтверждено
        } else if переход.применениеЗаявлено == nil && переход.независимыйВывод != nil {
            решение = .наблюдениеБезЗаявки
        } else if переход.выполнениеНачато == true {
            решение = .начатоОжидаетПрименения
        } else if переход.отправлено == true {
            решение = .отправленоОжидаетСтарта
        } else if переход.планПодготовлен == true {
            решение = .планЕщёНеОтправлен
        } else {
            решение = .неУстановлено
        }

        return РезультатПерехода(идентификатор: переход.идентификатор, решение: решение, ошибки: ошибки)
    }
}

enum Оценщик {
    static func оценить(пакет: ПакетПоставки, текущаяОснова: String) -> РезультатПакета {
        var ошибкиСостава: [String] = []

        if !верныйOID(пакет.голова) || !верныйOID(пакет.дерево) || !верныйOID(пакет.основание) {
            ошибкиСостава.append("неверный-oid")
        }
        if пакет.родители.isEmpty || !пакет.родители.allSatisfy(верныйOID) {
            ошибкиСостава.append("неверные-родители")
        }
        if пакет.грязныйИсточникИспользован {
            ошибкиСостава.append("использована-грязная-копия")
        }
        if пакет.ожидаетсяФайлов < 0 || пакет.файловИзменено != пакет.ожидаетсяФайлов {
            ошибкиСостава.append("несовпадает-состав-путей")
        }
        if пакет.пути.count != пакет.ожидаетсяФайлов ||
            Set(пакет.пути).count != пакет.пути.count ||
            пакет.пути.contains(where: { !безопасныйОтносительныйПуть($0) }) {
            ошибкиСостава.append("нет-точного-безопасного-манифеста-путей")
        }
        if пакет.вид != "запрос-на-слияние" && пакет.вид != "контрольная-точка" {
            ошибкиСостава.append("неизвестный-вид-поставки")
        }
        if пакет.номер != nil && пакет.номер! <= 0 {
            ошибкиСостава.append("неверный-номер-pr")
        }
        if пакет.вид == "запрос-на-слияние" &&
            (пакет.номер == nil || пакет.черновик == nil || пакет.сходимость == nil) {
            ошибкиСостава.append("неполные-метаданные-pr")
        }
        if пакет.вид == "контрольная-точка" && (пакет.черновик != nil || пакет.сходимость != nil) {
            ошибкиСостава.append("контрольная-точка-содержит-метаданные-pr")
        }

        if !ошибкиСостава.isEmpty {
            return результат(пакет, .некорректен, ошибкиСостава)
        }

        if пакет.принятоКорнем {
            guard пакет.слито,
                  пакет.состояние == "closed",
                  пакет.коммитПриёмки == текущаяОснова else {
                return результат(пакет, .некорректен, ["неподтверждённая-root-приёмка"])
            }
            return результат(
                пакет,
                пакет.установкаГотова ? .принято : .принятоБезУстановки,
                пакет.установкаГотова ? [] : пакет.препятствия + ["установка-не-доказана"]
            )
        }

        if пакет.слито {
            return результат(пакет, .некорректен, ["слияние-заявлено-без-root-приёмки"])
        }

        if пакет.вид == "контрольная-точка" {
            let причины = пакет.препятствия.isEmpty
                ? ["ROOT-приёмка-не-доказана"]
                : пакет.препятствия.map { "препятствие:" + $0 }
            return результат(пакет, пакет.препятствия.isEmpty ? .неГотов : .заблокирован, причины)
        }

        var причины: [String] = []
        if пакет.обзор != "пройден" {
            причины.append("нужен-обзор")
        }
        if пакет.состояние != "open" {
            причины.append("pr-не-открыт")
        }
        if пакет.сходимость != true {
            причины.append("сходимость-не-доказана")
        }
        if пакет.черновик == true {
            причины.append("pr-остаётся-черновиком")
        }
        if пакет.основание != текущаяОснова {
            причины.append("основа-отличается-от-текущей")
        }
        причины.append(contentsOf: пакет.препятствия.map { "препятствие:" + $0 })

        let решение: РешениеПакета
        if !пакет.препятствия.isEmpty || пакет.обзор == "нужны-исправления" {
            решение = .заблокирован
        } else if пакет.черновик == true {
            решение = .ожидаетПисателя
        } else if пакет.обзор != "пройден" {
            решение = .нуженОбзор
        } else if пакет.состояние != "open" || пакет.сходимость != true {
            решение = .неГотов
        } else if пакет.основание != текущаяОснова {
            решение = .нуженАктуальныйКандидат
        } else {
            решение = .готовКПриёмкеКорнем
        }

        return результат(пакет, решение, причины)
    }

    static func оценить(состояние: СостояниеКоординации, журнал: String) -> ИтогКоординации {
        var ошибки: [String] = []

        if состояние.схема != "fum.координация.состояние.1" && состояние.схема != "fum.координация.состояние.2" && состояние.схема != "fum.координация.состояние.3" && состояние.схема != "fum.координация.состояние.4" {
            ошибки.append("неподдерживаемая-схема")
        }
        if UUID(uuidString: состояние.корневойUUID) == nil {
            ошибки.append("неверный-корневой-uuid")
        }
        if !верныйOID(состояние.принятаяОснова) || !верныйOID(состояние.собственныйСтарт.oid) {
            ошибки.append("неверный-oid-основы")
        }
        if состояние.собственныйСтарт.oid != состояние.принятаяОснова || !состояние.собственныйСтарт.чистоеДерево {
            ошибки.append("собственный-старт-не-совпадает-с-основой")
        }
        if !состояние.собственныйСтарт.реф.hasPrefix("refs/heads/fum-lab/fum/") {
            ошибки.append("неразрешённый-префикс-собственного-рефа")
        }

        ошибки.append(contentsOf: проверитьМодельУзла(состояние.модельУзла))

        let корень = состояние.корневойWorktree
        if !верныйOID(корень.oid) || !корень.родители.allSatisfy(верныйOID) {
            ошибки.append("неверный-oid-корневого-дерева")
        }
        if !корень.родители.contains(состояние.принятаяОснова) {
            ошибки.append("принятая-основа-не-родитель-корневого-коммита")
        }
        if корень.корневойUUIDВКоммите != состояние.корневойUUID {
            ошибки.append("не-сходится-корневой-uuid-коммита")
        }
        if корень.атрибуцияИсполнителя.isEmpty || корень.авторСтарогоИзменённогоПути.isEmpty || корень.поручениеИПолномочия.isEmpty {
            ошибки.append("неполная-сверка-авторства-и-поручения")
        }
        if !корень.текущаяЗаписьВЭтойОбластиЗапрещена {
            ошибки.append("не-установлена-граница-root-worktree")
        }
        let пути = корень.изменённыеПути + корень.новыеПути
        if пути.contains(where: { !безопасныйОтносительныйПуть($0) }) {
            ошибки.append("не-публикационно-чистый-путь")
        }
        if Set(состояние.задачи.map(\.ключ)).count != состояние.задачи.count {
            ошибки.append("повторная-задача")
        }
        if состояние.задачи.contains(where: { $0.статус != "active" && $0.статус != "idle" }) {
            ошибки.append("неизвестный-статус-задачи")
        }
        if Set(состояние.поставки.map(\.идентификатор)).count != состояние.поставки.count {
            ошибки.append("повторный-пакет")
        }
        if Set(состояние.переходыСостояния.map(\.идентификатор)).count != состояние.переходыСостояния.count {
            ошибки.append("повторный-переход-состояния")
        }

        ошибки.append(contentsOf: ЖурналКоординации.проверить(строки: журнал, корневойUUID: состояние.корневойUUID))

        let переходы = состояние.переходыСостояния.map(ОценщикПерехода.оценить)
        for переход in переходы where !переход.ошибки.isEmpty {
            ошибки.append(contentsOf: переход.ошибки.map { "\(переход.идентификатор):\($0)" })
        }
        let пакеты = состояние.поставки.map {
            оценить(пакет: $0, текущаяОснова: состояние.принятаяОснова)
        }
        let активных = состояние.задачи.filter { $0.статус == "active" }.count
        let балансировка = состояние.снимокБалансировки.map(ОценщикБалансировки.оценить)
        if let балансировка {
            ошибки.append(contentsOf: балансировка.ошибки.map { "балансировка:\($0)" })
        }
        let наблюденияПоручений = (состояние.пакетыПоручений ?? []).map(ОценщикПоручений.оценить)
        for наблюдение in наблюденияПоручений {
            ошибки.append(contentsOf: наблюдение.ошибки.map { "\(наблюдение.группа):\($0)" })
        }
        if let грязныеПути = состояние.точныеГрязныеПути,
           грязныеПути.contains(where: { !безопасныйОтносительныйПуть($0) }) {
            ошибки.append("небезопасный-точный-грязный-путь")
        }
        let пересечения = СверкаГрязныхПутей.оценить(
            пакеты: состояние.поставки,
            точныеГрязныеПути: состояние.точныеГрязныеПути,
            полноеПокрытие: состояние.точныеГрязныеПутиПолноеПокрытие == true
        )
        let покрытиеПорученийПолное = !наблюденияПоручений.isEmpty &&
            наблюденияПоручений.allSatisfy(\.покрытиеПолное)
        let фактическиНачато = покрытиеПорученийПолное
            ? наблюденияПоручений.compactMap(\.фактическиНачато).reduce(0, +)
            : nil
        let самообновление = состояние.планСамообновления.map {
            ОценщикСамообновления.оценить($0, ожидаемыйКорневойUUID: состояние.корневойUUID)
        }

        return ИтогКоординации(
            схема: "fum.координация.предприёмочная-сверка.1",
            действителен: ошибки.isEmpty,
            корневойUUID: состояние.корневойUUID,
            принятаяОснова: состояние.принятаяОснова,
            числоАктивныхЗадач: активных,
            ошибки: ошибки,
            переходыСостояния: переходы,
            пакеты: пакеты,
            балансировка: балансировка,
            наблюденияПоручений: наблюденияПоручений,
            пересеченияГрязныхПутей: пересечения,
            порученийИсполняется: наблюденияПоручений.map(\.доказаноИсполняется).reduce(0, +),
            новыхХодов: наблюденияПоручений.map(\.новыеХоды).reduce(0, +),
            продолжённыхХодов: наблюденияПоручений.map(\.продолжённыеХоды).reduce(0, +),
            фактическиНачатоПоручений: фактическиНачато,
            покрытиеПорученийПолное: покрытиеПорученийПолное,
            самообновление: самообновление
        )
    }

    private static func результат(
        _ пакет: ПакетПоставки,
        _ решение: РешениеПакета,
        _ причины: [String]
    ) -> РезультатПакета {
        РезультатПакета(
            идентификатор: пакет.идентификатор,
            решение: решение,
            причины: причины,
            голова: пакет.голова,
            дерево: пакет.дерево,
            основание: пакет.основание,
            пути: пакет.пути
        )
    }

    static func проверитьМодельУзла(_ узел: МодельУзлаКоординации) -> [String] {
        var ошибки: [String] = []
        if !узел.веткаЯвляетсяУзлом || !безопасныйОтносительныйПуть(узел.собственнаяПамять) {
            ошибки.append("неверная-собственная-область-узла")
        }
        if узел.дочерниеУзлы.contains(where: \.isEmpty) ||
            Set(узел.дочерниеУзлы).count != узел.дочерниеУзлы.count ||
            Set(узел.деревоСодержит) != Set(["собственная-память", "дочерние-узлы"]) ||
            узел.деревоСодержит.count != 2 {
            ошибки.append("неверное-описание-дерева-узла")
        }
        if узел.общаяПамять != "только-чтение" || узел.процесс != "инкарнация" {
            ошибки.append("нарушена-граница-общей-памяти-или-процесса")
        }
        if узел.полноеДеревоПовтореноВJSON {
            ошибки.append("полное-дерево-повторено-в-json")
        }
        if let восстановление = узел.последнийКоммитВосстановления, !верныйOID(восстановление) {
            ошибки.append("неверный-коммит-восстановления")
        }
        return ошибки
    }

    private static func верныйOID(_ строка: String) -> Bool {
        guard строка.utf8.count == 40 else { return false }
        return строка.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private static func безопасныйОтносительныйПуть(_ строка: String) -> Bool {
        guard !строка.isEmpty, !строка.hasPrefix("/"), !строка.hasSuffix("/") else { return false }
        let компоненты = строка.split(separator: "/", omittingEmptySubsequences: false)
        return компоненты.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }
}

public struct ПутьФизическогоРабочегоДереваGit: Equatable, Sendable {
    public let путь: String

    public init?(путь: String) {
        guard путь.hasPrefix("/"), !путь.utf8.contains(0) else { return nil }
        let url = URL(fileURLWithPath: путь, isDirectory: true)
        guard url.standardizedFileURL.path == путь else { return nil }
        var каталог: ObjCBool = false
        guard FileManager.default.fileExists(atPath: путь, isDirectory: &каталог), каталог.boolValue else {
            return nil
        }
        guard url.resolvingSymlinksInPath().path == путь else { return nil }
        self.путь = путь
    }
}

public struct ПолныйРефGit: Equatable, Sendable {
    public let реф: String

    public init?(реф: String) {
        guard реф.hasPrefix("refs/heads/"), реф != "refs/heads/", !реф.contains("@{") else { return nil }
        let компоненты = реф.split(separator: "/", omittingEmptySubsequences: false)
        guard компоненты.count >= 3 else { return nil }
        let запрещённые: Set<UInt8> = [0x20, 0x7f, 0x7e, 0x5e, 0x3a, 0x3f, 0x2a, 0x5b, 0x5c]
        guard реф.utf8.allSatisfy({ !($0 <= 0x1f || $0 == 0x7f) && !запрещённые.contains($0) }) else { return nil }
        guard компоненты.dropFirst(2).allSatisfy({
            !$0.isEmpty && $0 != "." && $0 != ".." &&
                !$0.hasPrefix(".") && !$0.hasSuffix(".") && !$0.hasSuffix(".lock")
        }) else { return nil }
        guard !реф.contains("//"), !реф.contains("..") else { return nil }
        self.реф = реф
    }
}

public struct OIDКоммитаGit: Equatable, Sendable {
    public let oid: String

    public init?(oid: String) {
        guard oid.utf8.count == 40,
              oid.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else {
            return nil
        }
        self.oid = oid
    }
}

public struct АдресУдалённогоGit: Equatable, Sendable {
    public let адрес: String

    public init?(адрес: String) {
        guard let компоненты = URLComponents(string: адрес),
              компоненты.scheme == "https",
              компоненты.host == "github.com",
              компоненты.user == nil,
              компоненты.password == nil,
              компоненты.port == nil,
              компоненты.query == nil,
              компоненты.fragment == nil,
              компоненты.path.hasSuffix(".git") else { return nil }
        self.адрес = адрес
    }
}

/// Фактический URL назначения push после применения remote.pushurl и URL rewrite.
/// Для production его значение сверяется с отдельным принятым origin, но тип также
/// допускает file:// только для локальных bare-репозиториев в регрессионных тестах.
public struct АдресНазначенияPushGit: Equatable, Sendable {
    public let адрес: String

    public init?(адрес: String) {
        guard let компоненты = URLComponents(string: адрес),
              ["https", "ssh", "git", "file"].contains(компоненты.scheme ?? ""),
              компоненты.user == nil,
              компоненты.password == nil,
              компоненты.query == nil,
              компоненты.fragment == nil,
              (компоненты.path.hasSuffix(".git") || (компоненты.scheme == "file" && компоненты.path.hasSuffix(".git/"))) else { return nil }
        if компоненты.scheme == "file" {
            guard компоненты.host == nil || компоненты.host == "" || компоненты.host == "localhost",
                  компоненты.port == nil else { return nil }
        } else {
            guard компоненты.host != nil,
                  компоненты.port == nil else { return nil }
        }
        self.адрес = адрес
    }
}

public struct UUIDКорневойЗадачи: Equatable, Sendable {
    public let uuid: String

    public init?(uuid: String) {
        guard let значение = UUID(uuidString: uuid), значение.uuidString.lowercased() == uuid else { return nil }
        self.uuid = uuid
    }
}

public struct UUIDНативногоПисателя: Equatable, Sendable {
    public let uuid: String

    public init?(uuid: String) {
        guard let значение = UUID(uuidString: uuid), значение.uuidString.lowercased() == uuid else { return nil }
        self.uuid = uuid
    }
}

public struct НастройкиЭффектовPushGit: Equatable, Sendable {
    public let фактическиеАдресаPush: [String]
    public let mirrorЗначения: [Bool]
    public let followTagsЗначения: [Bool]
    public let recurseSubmodulesЗначения: [String]
    public let настроенныеPushRefspecs: [String]
    public let pushOptions: [String]
    public let receivePackКоманды: [String]
    public let autoSetupRemoteЗначения: [Bool]
    public let активныйPrePushHook: Bool

    public init(
        фактическиеАдресаPush: [String] = [],
        mirrorЗначения: [Bool] = [],
        followTagsЗначения: [Bool] = [],
        recurseSubmodulesЗначения: [String] = [],
        настроенныеPushRefspecs: [String] = [],
        pushOptions: [String] = [],
        receivePackКоманды: [String] = [],
        autoSetupRemoteЗначения: [Bool] = [],
        активныйPrePushHook: Bool = false
    ) {
        self.фактическиеАдресаPush = фактическиеАдресаPush
        self.mirrorЗначения = mirrorЗначения
        self.followTagsЗначения = followTagsЗначения
        self.recurseSubmodulesЗначения = recurseSubmodulesЗначения
        self.настроенныеPushRefspecs = настроенныеPushRefspecs
        self.pushOptions = pushOptions
        self.receivePackКоманды = receivePackКоманды
        self.autoSetupRemoteЗначения = autoSetupRemoteЗначения
        self.активныйPrePushHook = активныйPrePushHook
    }
}

public struct СнимокСостоянияGit: Equatable, Sendable {
    public let физическийКорень: ПутьФизическогоРабочегоДереваGit
    public let реф: ПолныйРефGit
    public let oidHEAD: OIDКоммитаGit
    public let адресOrigin: АдресУдалённогоGit
    public let настройкиPush: НастройкиЭффектовPushGit

    public init(
        физическийКорень: ПутьФизическогоРабочегоДереваGit,
        реф: ПолныйРефGit,
        oidHEAD: OIDКоммитаGit,
        адресOrigin: АдресУдалённогоGit,
        настройкиPush: НастройкиЭффектовPushGit = НастройкиЭффектовPushGit()
    ) {
        self.физическийКорень = физическийКорень
        self.реф = реф
        self.oidHEAD = oidHEAD
        self.адресOrigin = адресOrigin
        self.настройкиPush = настройкиPush
    }
}

public struct ОжидаемаяПривязкаИсполненияGit: Equatable, Sendable {
    public let физическоеРабочееДерево: ПутьФизическогоРабочегоДереваGit
    public let полныйРеф: ПолныйРефGit
    public let ожидаемыйOID: OIDКоммитаGit
    public let ожидаемыйАдресOrigin: АдресУдалённогоGit
    public let общийUUIDКорневойЗадачи: UUIDКорневойЗадачи
    public let ожидаемыйUUIDНативногоПисателя: UUIDНативногоПисателя
    public let ожидаемыйПутьУзла: String
    public let квитанцияВыбораМодели: СвидетельствоВыбораМодели
    public let квитанцияВыбораМоделиСХэшем: КвитанцияВыбораМодели
    public let независимоеОжиданиеВыбораМодели: ОжидаемаяКвитанцияВыбораМодели

    public init?(
        физическоеРабочееДерево: ПутьФизическогоРабочегоДереваGit,
        полныйРеф: ПолныйРефGit,
        ожидаемыйOID: OIDКоммитаGit,
        ожидаемыйАдресOrigin: АдресУдалённогоGit,
        общийUUIDКорневойЗадачи: UUIDКорневойЗадачи,
        ожидаемыйUUIDНативногоПисателя: UUIDНативногоПисателя,
        ожидаемыйПутьУзла: String,
        квитанцияВыбораМодели: КвитанцияВыбораМодели,
        независимоеОжиданиеВыбораМодели: ОжидаемаяКвитанцияВыбораМодели
    ) {
        guard полныйРеф.реф.hasPrefix("refs/heads/fum-lab/fum/koordinaciya/"),
              ожидаемыйАдресOrigin.адрес == "https://github.com/fum-lab/fum.git",
              ожидаемыйПутьУзла == "/root/koordinaciya" else { return nil }
        self.физическоеРабочееДерево = физическоеРабочееДерево
        self.полныйРеф = полныйРеф
        self.ожидаемыйOID = ожидаемыйOID
        self.ожидаемыйАдресOrigin = ожидаемыйАдресOrigin
        self.общийUUIDКорневойЗадачи = общийUUIDКорневойЗадачи
        self.ожидаемыйUUIDНативногоПисателя = ожидаемыйUUIDНативногоПисателя
        self.ожидаемыйПутьУзла = ожидаемыйПутьУзла
        self.квитанцияВыбораМодели = квитанцияВыбораМодели.свидетельство
        self.квитанцияВыбораМоделиСХэшем = квитанцияВыбораМодели
        self.независимоеОжиданиеВыбораМодели = независимоеОжиданиеВыбораМодели
    }
}

public struct НаблюдаемаяПривязкаИсполненияGit: Sendable {
    public let снимокGit: СнимокСостоянияGit
    public let общийUUIDКорневойЗадачи: UUIDКорневойЗадачи
    public let фактическийUUIDНативногоПисателя: UUIDНативногоПисателя
    public let путьУзла: String

    public init(
        снимокGit: СнимокСостоянияGit,
        общийUUIDКорневойЗадачи: UUIDКорневойЗадачи,
        фактическийUUIDНативногоПисателя: UUIDНативногоПисателя,
        путьУзла: String
    ) {
        self.снимокGit = снимокGit
        self.общийUUIDКорневойЗадачи = общийUUIDКорневойЗадачи
        self.фактическийUUIDНативногоПисателя = фактическийUUIDНативногоПисателя
        self.путьУзла = путьУзла
    }
}

public enum ОшибкаПривязкиИсполненияGit: Equatable, Sendable {
    case физическоеРабочееДеревоНеСовпадает
    case рефНеСовпадает
    case oidНеСовпадает
    case адресOriginНеСовпадает
    case количествоАдресовPushНеСовпадает
    case адресPushНеСовпадает
    case mirrorPushВключён
    case pushRefspecsНастроены
    case pushOptionsНастроены
    case receivePackПереопределён
    case prePushHookАктивен
    case autoSetupRemoteВключён
    case recurseSubmodulesНеПоддержан
    case корневойUUIDНеСовпадает
    case UUIDНативногоПисателяНеСовпадает
    case путьУзлаНеСовпадает
    case корневойUUIDКвитанцииНеСовпадает
    case UUIDНативногоПисателяВКвитанцииНеСовпадает
    case путьУзлаКвитанцииНеСовпадает
    case выбранныеПоляНеСовпадают
    case квитанцияНативногоПисателяНеполна
    case квитанцияВыбораМоделиНеСовпадает
    case командаНеПостроена
}

public enum ПроверкаНастроекPushGit {
    public static func ошибки(
        настройки: НастройкиЭффектовPushGit,
        ожидаемыйАдресPush: АдресНазначенияPushGit
    ) -> [ОшибкаПривязкиИсполненияGit] {
        var ошибки: [ОшибкаПривязкиИсполненияGit] = []
        if настройки.фактическиеАдресаPush.count != 1 {
            ошибки.append(.количествоАдресовPushНеСовпадает)
        }
        if настройки.фактическиеАдресаPush != [ожидаемыйАдресPush.адрес] {
            ошибки.append(.адресPushНеСовпадает)
        }
        if настройки.mirrorЗначения.contains(true) {
            ошибки.append(.mirrorPushВключён)
        }
        if !настройки.настроенныеPushRefspecs.isEmpty {
            ошибки.append(.pushRefspecsНастроены)
        }
        if !настройки.pushOptions.isEmpty {
            ошибки.append(.pushOptionsНастроены)
        }
        if !настройки.receivePackКоманды.isEmpty {
            ошибки.append(.receivePackПереопределён)
        }
        if настройки.активныйPrePushHook {
            ошибки.append(.prePushHookАктивен)
        }
        if настройки.autoSetupRemoteЗначения.contains(true) {
            ошибки.append(.autoSetupRemoteВключён)
        }
        if настройки.recurseSubmodulesЗначения.contains(where: { !["no", "check", "on-demand", "only"].contains($0) }) {
            ошибки.append(.recurseSubmodulesНеПоддержан)
        }
        return ошибки
    }

    public static func ошибки(
        настройки: НастройкиЭффектовPushGit,
        ожидаемыйАдресPush: АдресУдалённогоGit
    ) -> [ОшибкаПривязкиИсполненияGit] {
        guard let адрес = АдресНазначенияPushGit(адрес: ожидаемыйАдресPush.адрес) else {
            return [.адресPushНеСовпадает]
        }
        return ошибки(настройки: настройки, ожидаемыйАдресPush: адрес)
    }
}

public struct ДовереннаяПривязкаИсполненияGit: Sendable {
    public let рабочееДерево: ПутьФизическогоРабочегоДереваGit
    public let реф: ПолныйРефGit
    public let oid: OIDКоммитаGit
    public let origin: АдресУдалённогоGit
    public let адресPush: АдресНазначенияPushGit
    public let общийUUIDКорневойЗадачи: UUIDКорневойЗадачи
    public let uuidНативногоПисателя: UUIDНативногоПисателя
    public let путьУзла: String

    fileprivate init(ожидаемая: ОжидаемаяПривязкаИсполненияGit) {
        рабочееДерево = ожидаемая.физическоеРабочееДерево
        реф = ожидаемая.полныйРеф
        oid = ожидаемая.ожидаемыйOID
        origin = ожидаемая.ожидаемыйАдресOrigin
        адресPush = АдресНазначенияPushGit(адрес: ожидаемая.ожидаемыйАдресOrigin.адрес)!
        общийUUIDКорневойЗадачи = ожидаемая.общийUUIDКорневойЗадачи
        uuidНативногоПисателя = ожидаемая.ожидаемыйUUIDНативногоПисателя
        путьУзла = ожидаемая.ожидаемыйПутьУзла
    }

    #if TESTING
    init(
        дляЛокальнойФикстуры рабочееДерево: ПутьФизическогоРабочегоДереваGit,
        реф: ПолныйРефGit,
        oid: OIDКоммитаGit,
        origin: АдресУдалённогоGit,
        адресPush: АдресНазначенияPushGit
    ) {
        self.рабочееДерево = рабочееДерево
        self.реф = реф
        self.oid = oid
        self.origin = origin
        self.адресPush = адресPush
        self.общийUUIDКорневойЗадачи = UUIDКорневойЗадачи(uuid: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb")!
        self.uuidНативногоПисателя = UUIDНативногоПисателя(uuid: "01a18294-b6ff-7352-92e1-6b576d412172")!
        self.путьУзла = "/root/koordinaciya"
    }
    #endif
}

public struct РезультатПроверкиПривязкиGit: Sendable {
    public let ошибки: [ОшибкаПривязкиИсполненияGit]
    public let довереннаяПривязка: ДовереннаяПривязкаИсполненияGit?
}

public enum ПроверкаПривязкиИсполненияGit {
    public static func проверить(
        ожидаемая: ОжидаемаяПривязкаИсполненияGit,
        наблюдаемая: НаблюдаемаяПривязкаИсполненияGit
    ) -> РезультатПроверкиПривязкиGit {
        var ошибки: [ОшибкаПривязкиИсполненияGit] = []
        if ожидаемая.физическоеРабочееДерево != наблюдаемая.снимокGit.физическийКорень {
            ошибки.append(.физическоеРабочееДеревоНеСовпадает)
        }
        if ожидаемая.полныйРеф != наблюдаемая.снимокGit.реф {
            ошибки.append(.рефНеСовпадает)
        }
        if ожидаемая.ожидаемыйOID != наблюдаемая.снимокGit.oidHEAD {
            ошибки.append(.oidНеСовпадает)
        }
        if ожидаемая.ожидаемыйАдресOrigin != наблюдаемая.снимокGit.адресOrigin {
            ошибки.append(.адресOriginНеСовпадает)
        }
        ошибки.append(contentsOf: ПроверкаНастроекPushGit.ошибки(
            настройки: наблюдаемая.снимокGit.настройкиPush,
            ожидаемыйАдресPush: ожидаемая.ожидаемыйАдресOrigin
        ))
        if ожидаемая.общийUUIDКорневойЗадачи != наблюдаемая.общийUUIDКорневойЗадачи {
            ошибки.append(.корневойUUIDНеСовпадает)
        }
        if ожидаемая.ожидаемыйUUIDНативногоПисателя != наблюдаемая.фактическийUUIDНативногоПисателя {
            ошибки.append(.UUIDНативногоПисателяНеСовпадает)
        }
        if ожидаемая.ожидаемыйПутьУзла != наблюдаемая.путьУзла {
            ошибки.append(.путьУзлаНеСовпадает)
        }

        let ошибкиКвитанции = ГенераторМетаданныхКоммита.проверитьReceipt(
            ожидаемая.квитанцияВыбораМоделиСХэшем,
            ожидаемый: ожидаемая.независимоеОжиданиеВыбораМодели,
            expectedRootUUID: ожидаемая.общийUUIDКорневойЗадачи.uuid
        )
        if !ошибкиКвитанции.isEmpty {
            ошибки.append(.квитанцияВыбораМоделиНеСовпадает)
        }
        let receipt = ожидаемая.квитанцияВыбораМодели
        if receipt.rootUUID != ожидаемая.общийUUIDКорневойЗадачи.uuid {
            ошибки.append(.корневойUUIDКвитанцииНеСовпадает)
        }
        guard let native = receipt.nativeThread else {
            ошибки.append(.квитанцияНативногоПисателяНеполна)
            return РезультатПроверкиПривязкиGit(ошибки: ошибки, довереннаяПривязка: nil)
        }
        if receipt.sessionIdentity.статус != .доступен ||
            receipt.sessionIdentity.вид != .идентификаторNativeThreadMetadata ||
            receipt.sessionIdentity.значение != ожидаемая.ожидаемыйUUIDНативногоПисателя.uuid ||
            native.threadUUID != ожидаемая.ожидаемыйUUIDНативногоПисателя.uuid {
            ошибки.append(.UUIDНативногоПисателяВКвитанцииНеСовпадает)
        }
        if native.agentPath != ожидаемая.ожидаемыйПутьУзла {
            ошибки.append(.путьУзлаКвитанцииНеСовпадает)
        }
        if native.модель != receipt.selectedValue.model || native.усилие != receipt.selectedValue.reasoningEffort {
            ошибки.append(.выбранныеПоляНеСовпадают)
        }
        let доверенная = ошибки.isEmpty ? ДовереннаяПривязкаИсполненияGit(ожидаемая: ожидаемая) : nil
        return РезультатПроверкиПривязкиGit(ошибки: ошибки, довереннаяПривязка: доверенная)
    }
}

public struct СпецификацияОтправкиGit: Equatable, Sendable {
    public let значение: String

    public init?(значение: String) {
        let части = значение.split(separator: ":", omittingEmptySubsequences: false)
        guard части.count == 2,
              let oid = OIDКоммитаGit(oid: String(части[0])),
              let реф = ПолныйРефGit(реф: String(части[1])),
              реф.реф.hasPrefix("refs/heads/fum-lab/fum/koordinaciya/") else { return nil }
        self.значение = "\(oid.oid):\(реф.реф)"
    }

    fileprivate init?(oid: OIDКоммитаGit, реф: ПолныйРефGit) {
        self.init(значение: "\(oid.oid):\(реф.реф)")
    }
}

public struct КомандаGit: Sendable {
    public let исполняемыйПуть: String
    public let аргументы: [String]
    public let рабочийКаталог: String
    public let целевойРеф: String
    public let целевойOID: String
    public let ожидаемыйOrigin: String
    public let ожидаемыйАдресPush: String

    fileprivate init(для привязки: ДовереннаяПривязкаИсполненияGit, спецификация: СпецификацияОтправкиGit) {
        исполняемыйПуть = "/usr/bin/git"
        аргументы = [
            "-c", "remote.origin.mirror=false",
            "-c", "push.followTags=false",
            "-c", "push.recurseSubmodules=no",
            "-c", "push.gpgSign=false",
            "push", "--no-mirror", "--no-follow-tags", "--recurse-submodules=no",
            "--no-set-upstream", "--no-signed", "origin", спецификация.значение
        ]
        рабочийКаталог = привязки.рабочееДерево.путь
        целевойРеф = привязки.реф.реф
        целевойOID = привязки.oid.oid
        ожидаемыйOrigin = привязки.origin.адрес
        ожидаемыйАдресPush = привязки.адресPush.адрес
    }
}

public enum ПостроительКомандыGit {
    public static func отправитьВУдалённыйРепозиторий(для привязки: ДовереннаяПривязкаИсполненияGit) -> КомандаGit? {
        guard let спецификация = СпецификацияОтправкиGit(oid: привязки.oid, реф: привязки.реф) else { return nil }
        return КомандаGit(для: привязки, спецификация: спецификация)
    }
}

public struct КвитанцияЗапускаGit: Sendable {
    public let аргументы: [String]
    public let рабочийКаталог: String
    public let кодЗавершения: Int32
    public let требуетсяУдалённоеЧтениеОбратно: Bool
}

public enum АдаптерВыполненияКомандGit {
    static func выполнить(_ команда: КомандаGit) throws -> КвитанцияЗапускаGit {
        let спецификацияОжидания = команда.целевойOID + ":" + команда.целевойРеф
        let аргументыОжидания = [
            "-c", "remote.origin.mirror=false",
            "-c", "push.followTags=false",
            "-c", "push.recurseSubmodules=no",
            "-c", "push.gpgSign=false",
            "push", "--no-mirror", "--no-follow-tags", "--recurse-submodules=no",
            "--no-set-upstream", "--no-signed", "origin", спецификацияОжидания
        ]
        guard команда.исполняемыйПуть == "/usr/bin/git",
              команда.аргументы == аргументыОжидания,
              let спецификация = СпецификацияОтправкиGit(значение: спецификацияОжидания),
              спецификация.значение.split(separator: ":").last.map(String.init) == команда.целевойРеф,
              let путь = ПутьФизическогоРабочегоДереваGit(путь: команда.рабочийКаталог),
              let ожидаемыйАдресPush = АдресНазначенияPushGit(адрес: команда.ожидаемыйАдресPush),
              let ожидаемыйOrigin = АдресУдалённогоGit(адрес: команда.ожидаемыйOrigin) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let свежийСнимок = try НаблюдательРабочегоДереваGit.прочитать(рабочееДерево: путь)
        guard свежийСнимок.физическийКорень == путь,
              свежийСнимок.реф.реф == команда.целевойРеф,
              свежийСнимок.oidHEAD.oid == команда.целевойOID,
              свежийСнимок.адресOrigin == ожидаемыйOrigin,
              ПроверкаНастроекPushGit.ошибки(
                настройки: свежийСнимок.настройкиPush,
                ожидаемыйАдресPush: ожидаемыйАдресPush
              ).isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: команда.исполняемыйПуть)
        процесс.arguments = команда.аргументы
        процесс.currentDirectoryURL = URL(fileURLWithPath: путь.путь, isDirectory: true)
        процесс.environment = Self.окружениеИзолированногоGit()
        процесс.standardOutput = FileHandle.nullDevice
        процесс.standardError = FileHandle.nullDevice
        try процесс.run()
        процесс.waitUntilExit()
        return КвитанцияЗапускаGit(
            аргументы: команда.аргументы,
            рабочийКаталог: путь.путь,
            кодЗавершения: процесс.terminationStatus,
            требуетсяУдалённоеЧтениеОбратно: true
        )
    }

    static func окружениеИзолированногоGit() -> [String: String] {
        var окружение = ProcessInfo.processInfo.environment
        for ключ in Array(окружение.keys) where ключ.hasPrefix("GIT_CONFIG_KEY_") || ключ.hasPrefix("GIT_CONFIG_VALUE_") {
            окружение.removeValue(forKey: ключ)
        }
        for ключ in [
            "GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR", "GIT_INDEX_FILE",
            "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES",
            "GIT_CONFIG", "GIT_CONFIG_PARAMETERS", "GIT_CONFIG_SYSTEM", "GIT_CONFIG_COUNT",
            "GIT_CEILING_DIRECTORIES", "GIT_DISCOVERY_ACROSS_FILESYSTEM", "GIT_NAMESPACE",
            "GIT_SHALLOW_FILE", "GIT_QUARANTINE_PATH", "GIT_PREFIX", "GIT_EXEC_PATH",
            "GIT_PUSH_OPTION_COUNT"
        ] {
            окружение.removeValue(forKey: ключ)
        }
        for ключ in Array(окружение.keys) where ключ.hasPrefix("GIT_PUSH_OPTION_") {
            окружение.removeValue(forKey: ключ)
        }
        окружение["GIT_CONFIG_NOSYSTEM"] = "1"
        окружение["GIT_CONFIG_GLOBAL"] = "/dev/null"
        окружение["GIT_OPTIONAL_LOCKS"] = "0"
        окружение["GIT_TERMINAL_PROMPT"] = "0"
        return окружение
    }
}

public enum ИтогПроверенногоPushGit: Sendable {
    case удержан([ОшибкаПривязкиИсполненияGit])
    case запущен(КвитанцияЗапускаGit)
}

public enum АдаптерПроверенногоPushGit {
    /// Сначала повторно читает W/ref/HEAD/origin, затем сверяет отдельную native-идентичность и один раз вызывает executor.
    /// Если executor выбросил ошибку, исход эффекта неизвестен; повтор запрещён до отдельного readback.
    public static func выполнитьПроверенныйPush(
        ожидаемая: ОжидаемаяПривязкаИсполненияGit,
        наблюдаемыйUUIDКорневойЗадачи: UUIDКорневойЗадачи,
        наблюдаемыйUUIDНативногоПисателя: UUIDНативногоПисателя,
        наблюдаемыйПутьУзла: String,
        исполнитель: ((КомандаGit) throws -> КвитанцияЗапускаGit)? = nil
    ) throws -> ИтогПроверенногоPushGit {
        let свежийGit = try НаблюдательРабочегоДереваGit.прочитать(
            рабочееДерево: ожидаемая.физическоеРабочееДерево
        )
        let наблюдаемая = НаблюдаемаяПривязкаИсполненияGit(
            снимокGit: свежийGit,
            общийUUIDКорневойЗадачи: наблюдаемыйUUIDКорневойЗадачи,
            фактическийUUIDНативногоПисателя: наблюдаемыйUUIDНативногоПисателя,
            путьУзла: наблюдаемыйПутьУзла
        )
        let проверка = ПроверкаПривязкиИсполненияGit.проверить(
            ожидаемая: ожидаемая,
            наблюдаемая: наблюдаемая
        )
        guard let доверенная = проверка.довереннаяПривязка else {
            return .удержан(проверка.ошибки)
        }
        guard let команда = ПостроительКомандыGit.отправитьВУдалённыйРепозиторий(для: доверенная) else {
            return .удержан([.командаНеПостроена])
        }
        let квитанция: КвитанцияЗапускаGit
        if let исполнитель {
            квитанция = try исполнитель(команда)
        } else {
            квитанция = try АдаптерВыполненияКомандGit.выполнить(команда)
        }
        return .запущен(квитанция)
    }
}

public enum НаблюдательРабочегоДереваGit {
    public static func прочитать(рабочееДерево: ПутьФизическогоРабочегоДереваGit) throws -> СнимокСостоянияGit {
        let rootАргументы = ["rev-parse", "--show-toplevel"]
        let rootText = try выполнитьGit(rootАргументы, в: рабочееДерево)
        let найденныйКорень = URL(fileURLWithPath: rootText, isDirectory: true)
            .standardizedFileURL.resolvingSymlinksInPath().path
        guard найденныйКорень == рабочееДерево.путь else {
            throw ОшибкаСнимкаGit.кореньGitНеСовпадаетСПереданнымРабочимДеревом
        }
        let refАргументы = ["symbolic-ref", "--quiet", "HEAD"]
        let refText = try выполнитьGit(refАргументы, в: рабочееДерево)
        guard let ref = ПолныйРефGit(реф: refText) else { throw ОшибкаСнимкаGit.некорректныйВывод(refАргументы) }
        let oidАргументы = ["rev-parse", "--verify", "HEAD^{commit}"]
        let oidText = try выполнитьGit(oidАргументы, в: рабочееДерево)
        guard let oid = OIDКоммитаGit(oid: oidText) else { throw ОшибкаСнимкаGit.некорректныйВывод(oidАргументы) }
        let originАргументы = ["remote", "get-url", "origin"]
        let originText = try выполнитьGit(originАргументы, в: рабочееДерево)
        guard let origin = АдресУдалённогоGit(адрес: originText) else {
            throw ОшибкаСнимкаGit.некорректныйВывод(originАргументы)
        }
        let pushАргументы = ["remote", "get-url", "--push", "--all", "origin"]
        let pushOutput = try выполнитьGitСырые(pushАргументы, в: рабочееДерево)
        guard pushOutput.status == 0,
              let pushText = String(data: pushOutput.stdout, encoding: .utf8),
              pushText.hasSuffix("\n") else {
            throw ОшибкаСнимкаGit.некорректныйВывод(pushАргументы)
        }
        let фактическиеАдресаPush = String(pushText.dropLast()).components(separatedBy: "\n")
        let mirror = try значенияBoolКонфига("remote.origin.mirror", в: рабочееДерево)
        let followTags = try значенияBoolКонфига("push.followTags", в: рабочееДерево)
        let autoSetupRemote = try значенияBoolКонфига("push.autoSetupRemote", в: рабочееДерево)
        let recurseSubmodules = try значенияСтроковогоКонфига("push.recurseSubmodules", в: рабочееДерево)
        let pushRefspecs = try значенияСтроковогоКонфига("remote.origin.push", в: рабочееДерево)
        let pushOptions = try значенияСтроковогоКонфига("push.pushOption", в: рабочееДерево)
        let receivePack = try значенияСтроковогоКонфига("remote.origin.receivepack", в: рабочееДерево)
        let hookPathText = try выполнитьGit(["rev-parse", "--git-path", "hooks/pre-push"], в: рабочееДерево)
        let hookURL = hookPathText.hasPrefix("/")
            ? URL(fileURLWithPath: hookPathText)
            : URL(fileURLWithPath: hookPathText, relativeTo: URL(fileURLWithPath: рабочееДерево.путь, isDirectory: true)).standardizedFileURL
        let настройкиPush = НастройкиЭффектовPushGit(
            фактическиеАдресаPush: фактическиеАдресаPush,
            mirrorЗначения: mirror,
            followTagsЗначения: followTags,
            recurseSubmodulesЗначения: recurseSubmodules,
            настроенныеPushRefspecs: pushRefspecs,
            pushOptions: pushOptions,
            receivePackКоманды: receivePack,
            autoSetupRemoteЗначения: autoSetupRemote,
            активныйPrePushHook: FileManager.default.isExecutableFile(atPath: hookURL.path)
        )
        return СнимокСостоянияGit(
            физическийКорень: рабочееДерево,
            реф: ref,
            oidHEAD: oid,
            адресOrigin: origin,
            настройкиPush: настройкиPush
        )
    }

    private static func значенияBoolКонфига(
        _ ключ: String,
        в рабочееДерево: ПутьФизическогоРабочегоДереваGit
    ) throws -> [Bool] {
        let данные = try значенияКонфига(ключ, тип: "bool", в: рабочееДерево)
        return try данные.map { значение in
            switch значение {
            case "true": return true
            case "false": return false
            default: throw ОшибкаСнимкаGit.некорректныйВывод(["config", ключ])
            }
        }
    }

    private static func значенияСтроковогоКонфига(
        _ ключ: String,
        в рабочееДерево: ПутьФизическогоРабочегоДереваGit
    ) throws -> [String] {
        try значенияКонфига(ключ, тип: nil, в: рабочееДерево)
    }

    private static func значенияКонфига(
        _ ключ: String,
        тип: String?,
        в рабочееДерево: ПутьФизическогоРабочегоДереваGit
    ) throws -> [String] {
        // The isolated environment disables system/global config, while effective config also
        // includes per-worktree values when extensions.worktreeConfig is enabled.
        var аргументы = ["config", "--includes", "--null"]
        if let тип { аргументы.append(contentsOf: ["--type=" + тип]) }
        аргументы.append(contentsOf: ["--get-all", ключ])
        let результат = try выполнитьGitСырые(аргументы, в: рабочееДерево)
        if результат.status == 1 && результат.stdout.isEmpty { return [] }
        guard результат.status == 0,
              let текст = String(data: результат.stdout, encoding: .utf8),
              текст.hasSuffix("\0") else {
            throw ОшибкаСнимкаGit.некорректныйВывод(аргументы)
        }
        return текст.split(separator: "\0", omittingEmptySubsequences: false)
            .dropLast()
            .map(String.init)
    }

    private static func выполнитьGitСырые(
        _ аргументы: [String],
        в рабочееДерево: ПутьФизическогоРабочегоДереваGit
    ) throws -> (stdout: Data, status: Int32) {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = аргументы
        процесс.currentDirectoryURL = URL(fileURLWithPath: рабочееДерево.путь, isDirectory: true)
        процесс.environment = АдаптерВыполненияКомандGit.окружениеИзолированногоGit()
        let вывод = Pipe()
        процесс.standardOutput = вывод
        процесс.standardError = FileHandle.nullDevice
        try процесс.run()
        процесс.waitUntilExit()
        return (вывод.fileHandleForReading.readDataToEndOfFile(), процесс.terminationStatus)
    }

    private static func выполнитьGit(_ аргументы: [String], в рабочееДерево: ПутьФизическогоРабочегоДереваGit) throws -> String {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = аргументы
        процесс.currentDirectoryURL = URL(fileURLWithPath: рабочееДерево.путь, isDirectory: true)
        процесс.environment = АдаптерВыполненияКомандGit.окружениеИзолированногоGit()
        let вывод = Pipe()
        процесс.standardOutput = вывод
        процесс.standardError = FileHandle.nullDevice
        try процесс.run()
        процесс.waitUntilExit()
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        guard процесс.terminationStatus == 0 else {
            throw ОшибкаСнимкаGit.командаНеУспешна(аргументы, процесс.terminationStatus)
        }
        guard let строка = String(data: данные, encoding: .utf8) else {
            throw ОшибкаСнимкаGit.некорректныйВывод(аргументы)
        }
        return строка.trimmingCharacters(in: .newlines)
    }
}

public enum ОшибкаСнимкаGit: Error, Equatable, Sendable, CustomStringConvertible {
    case командаНеУспешна([String], Int32)
    case некорректныйВывод([String])
    case кореньGitНеСовпадаетСПереданнымРабочимДеревом

    public var description: String {
        switch self {
        case let .командаНеУспешна(аргументы, код):
            return "git \(аргументы.joined(separator: " ")) завершился с кодом \(код)"
        case let .некорректныйВывод(аргументы):
            return "git \(аргументы.joined(separator: " ")) вернул неприемлемый результат"
        case .кореньGitНеСовпадаетСПереданнымРабочимДеревом:
            return "git обнаружил другой физический корень репозитория"
        }
    }
}

#if !TESTING
private struct ОжиданиеСырогоMergeКоммита: Decodable {
    let schema: String
    let expectedParents: [String]
    let expectedTree: String
}

@main
struct ГлавнаяКоординатора {
    static func main() {
        let аргументы = Array(CommandLine.arguments.dropFirst())
        if аргументы.first == "--сохранить-квитанцию-root-native-client" {
            guard аргументы.count == 7 else {
                fputs("Ожидаются source, independent expected, current selection JSON, root UUID, private receipt path и собственный public projection path.\n", stderr)
                exit(EXIT_FAILURE)
            }
            do {
                let source = try Data(contentsOf: URL(fileURLWithPath: аргументы[1]))
                let expected = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                let current = try Data(contentsOf: URL(fileURLWithPath: аргументы[3]))
                let pair = try АдаптерRootNativeClientMetadata.построитьКвитанции(
                    источникJSON: source,
                    независимоеОжиданиеJSON: expected,
                    expectedRootUUID: аргументы[4]
                )
                try АдаптерRootNativeClientMetadata.проверитьДрейф(
                    текущееJSON: current,
                    ожидаемая: pair.фактическая.свидетельство
                )
                let ошибки = ГенераторМетаданныхКоммита.проверитьReceipt(
                    pair.фактическая,
                    ожидаемый: pair.ожидаемая,
                    expectedRootUUID: аргументы[4]
                )
                guard ошибки.isEmpty else {
                    throw NSError(domain: "NativeClientReceipt", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: ошибки.joined(separator: ", ")])
                }

                let privateReceiptURL = URL(fileURLWithPath: аргументы[5])
                let privateParent = privateReceiptURL.deletingLastPathComponent().path
                guard let resolvedPrivateParent = ИсполнительГенератораFUMA.физическийПуть(privateParent),
                      !ИсполнительГенератораFUMA.внутриGit(resolvedPrivateParent),
                      let privatePermissions = try FileManager.default.attributesOfItem(atPath: resolvedPrivateParent)[.posixPermissions] as? NSNumber,
                      privatePermissions.intValue & 0o077 == 0 else {
                    throw CocoaError(.fileWriteNoPermission)
                }
                let root = try выполнитьGit(["rev-parse", "--show-toplevel"], окружение: ProcessInfo.processInfo.environment)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let publicURL = URL(fileURLWithPath: аргументы[6]).standardizedFileURL
                let publicParentPath = publicURL.deletingLastPathComponent().path
                guard let resolvedPublicParent = ИсполнительГенератораFUMA.физическийПуть(publicParentPath),
                      resolvedPublicParent == root + "/koordinaciya" else {
                    throw CocoaError(.fileWriteNoPermission)
                }
                let receiptEncoder = JSONEncoder()
                receiptEncoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                try receiptEncoder.encode(pair).write(to: privateReceiptURL, options: .atomic)
                let projection = ПубличнаяПроекцияRootNativeClient(пара: pair)
                try receiptEncoder.encode(projection).write(to: publicURL, options: .atomic)
                FileHandle.standardOutput.write(try receiptEncoder.encode(projection))
                FileHandle.standardOutput.write(Data([0x0a]))
            } catch {
                fputs("Не удалось проверить и сохранить root native-client receipt: \(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
            return
        }
        if аргументы.first == "--проверить-fuma-генератор" {
            guard аргументы.count == 5 else {
                fputs("Ожидаются пути к определению, фикстуре, fum-оператору и приватному каталогу запуска.\n", stderr)
                exit(EXIT_FAILURE)
            }
            do {
                let fixtureData = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                let fixture = try JSONDecoder().decode(ПакетВходаГенератораFUMA.self, from: fixtureData)
                let run = try ИсполнительГенератораFUMA.выполнить(
                    input: fixture,
                    definitionPath: аргументы[1],
                    operatorPath: аргументы[3],
                    privateRunRoot: аргументы[4]
                )
                let expected = try ГенераторМетаданныхКоммита.bytesForOutput(
                    ГенераторМетаданныхКоммита.referenceOutput(for: fixture)
                )
                let actual = run.canonicalOutput
                let report: [String: Any] = [
                    "passed": actual == expected,
                    "fixtureCases": fixture.cases.map(\.id),
                    "actualOutputSHA256": sha256(actual),
                    "expectedOutputSHA256": sha256(expected),
                    "fumaResponseSHA256": sha256(run.response),
                    "executionEvidenceSHA256": sha256(try Data(contentsOf: URL(fileURLWithPath: run.evidenceDirectory).appendingPathComponent("свидетельство.json"))),
                    "byteCount": actual.count,
                    "byteEqual": actual == expected
                ]
                let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
                FileHandle.standardOutput.write(data)
                FileHandle.standardOutput.write(Data([0x0a]))
                if actual != expected { exit(EXIT_FAILURE) }
            } catch {
                fputs("Не удалось исполнить или сверить FUMA-генератор: \(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
            return
        }
        if аргументы.first == "--проверить-fuma-root-native-client" {
            guard аргументы.count == 10 else {
                fputs("Ожидаются пути к определению, дочерней фикстуре, оператору, приватному корню, source/expected/current metadata, root UUID и приватной квитанции.\n", stderr)
                exit(EXIT_FAILURE)
            }
            do {
                let source = try Data(contentsOf: URL(fileURLWithPath: аргументы[5]))
                let independent = try Data(contentsOf: URL(fileURLWithPath: аргументы[6]))
                let current = try Data(contentsOf: URL(fileURLWithPath: аргументы[7]))
                let pair = try АдаптерRootNativeClientMetadata.построитьКвитанции(
                    источникJSON: source,
                    независимоеОжиданиеJSON: independent,
                    expectedRootUUID: аргументы[8]
                )
                try АдаптерRootNativeClientMetadata.проверитьДрейф(
                    текущееJSON: current,
                    ожидаемая: pair.фактическая.свидетельство
                )
                let receiptErrors = ГенераторМетаданныхКоммита.проверитьReceipt(
                    pair.фактическая,
                    ожидаемый: pair.ожидаемая,
                    expectedRootUUID: аргументы[8]
                )
                guard receiptErrors.isEmpty else {
                    throw NSError(domain: "NativeClientReceipt", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: receiptErrors.joined(separator: ", ")])
                }
                let receiptURL = URL(fileURLWithPath: аргументы[9])
                let receiptParent = receiptURL.deletingLastPathComponent().path
                guard let privateParent = ИсполнительГенератораFUMA.физическийПуть(receiptParent),
                      !ИсполнительГенератораFUMA.внутриGit(privateParent),
                      let permissions = try FileManager.default.attributesOfItem(atPath: privateParent)[.posixPermissions] as? NSNumber,
                      permissions.intValue & 0o077 == 0 else {
                    throw CocoaError(.fileWriteNoPermission)
                }
                let receiptEncoder = JSONEncoder()
                receiptEncoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                try receiptEncoder.encode(pair).write(to: receiptURL, options: .atomic)

                let fixtureData = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                let baseFixture = try JSONDecoder().decode(ПакетВходаГенератораFUMA.self, from: fixtureData)
                let rootCase = ВходСлучаяГенератораFUMA(
                    id: "root-native-client-selection",
                    acceptedSelection: pair.фактическая.свидетельство.selectedValue,
                    rootUUID: pair.фактическая.свидетельство.rootUUID,
                    title: "Использовать выбранную модель клиента",
                    description: "Root author берёт последнее подтверждённое значение выбранного клиента; модель backend остаётся неизвестной.",
                    rawRequest: " Сохранить exact raw request bytes.\r\n"
                )
                let fixture = ПакетВходаГенератораFUMA(cases: baseFixture.cases + [rootCase])
                let run = try ИсполнительГенератораFUMA.выполнить(
                    input: fixture,
                    definitionPath: аргументы[1],
                    operatorPath: аргументы[3],
                    privateRunRoot: аргументы[4]
                )
                let expected = try ГенераторМетаданныхКоммита.bytesForOutput(
                    ГенераторМетаданныхКоммита.referenceOutput(for: fixture)
                )
                let actual = run.canonicalOutput
                let evidenceURL = URL(fileURLWithPath: run.evidenceDirectory).appendingPathComponent("свидетельство.json")
                let report: [String: Any] = [
                    "passed": actual == expected,
                    "fixtureCases": fixture.cases.map(\.id),
                    "rootSelection": [
                        "source": pair.фактическая.свидетельство.источник.rawValue,
                        "rootUUID": pair.фактическая.свидетельство.rootUUID,
                        "model": pair.фактическая.свидетельство.selectedValue.model,
                        "reasoningEffort": pair.фактическая.свидетельство.selectedValue.reasoningEffort,
                        "sourceProjectionSHA256": pair.фактическая.свидетельство.nativeSelectionSourceSHA256 ?? ""
                    ],
                    "receiptSHA256": pair.фактическая.sha256,
                    "independentExpectedSHA256": pair.ожидаемая.sha256,
                    "actualOutputSHA256": sha256(actual),
                    "expectedOutputSHA256": sha256(expected),
                    "fumaResponseSHA256": sha256(run.response),
                    "executionEvidenceSHA256": sha256(try Data(contentsOf: evidenceURL)),
                    "byteCount": actual.count,
                    "byteEqual": actual == expected
                ]
                let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
                FileHandle.standardOutput.write(data)
                FileHandle.standardOutput.write(Data([0x0a]))
                if actual != expected { exit(EXIT_FAILURE) }
            } catch {
                fputs("Не удалось проверить root native-client selection через общий FUMA composer: \(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
            return
        }
        if аргументы.first == "--проверить-перед-коммитом" || аргументы.first == "--сгенерировать-метаданные-коммита" {
            guard аргументы.count == 2 else {
                fputs("Ожидается путь к состояние.json.\n", stderr)
                exit(EXIT_FAILURE)
            }
            do {
                let данные = try Data(contentsOf: URL(fileURLWithPath: аргументы[1]))
                let состояние = try JSONDecoder().decode(СостояниеКоординации.self, from: данные)
                guard let план = состояние.планСамообновления else {
                    throw CocoaError(.coderValueNotFound)
                }
                let метаданные = try сгенерироватьМетаданные(план, expectedRootUUID: состояние.корневойUUID)
                let head = try выполнитьGit(["rev-parse", "HEAD"], окружение: ProcessInfo.processInfo.environment)
                let реф = try выполнитьGit(["symbolic-ref", "HEAD"], окружение: ProcessInfo.processInfo.environment)
                var ошибки = ОценщикИдентичностиGit.проверитьДоЭффекта(
                    ожидаемая: план.идентичностьСледующегоКоммита,
                    метаданные: метаданные,
                    текущийHEAD: head,
                    текущийРеф: реф,
                    ожидаемыйРеф: план.собственныйРеф,
                    expectedRootUUID: состояние.корневойUUID
                )
                if метаданные.выборМодели.rootUUID != состояние.корневойUUID {
                    ошибки.append("model-selection-receipt-не-связан-с-корневым-uuid-состояния")
                }
                let metadataData = try JSONEncoder().encode(метаданные)
                let metadataObject = try JSONSerialization.jsonObject(with: metadataData)
                let результат = try JSONSerialization.data(withJSONObject: [
                    "готово": ошибки.isEmpty,
                    "переменныеОкруженияКИзменению": метаданные.окружение,
                    "метаданные": metadataObject,
                    "ошибки": ошибки
                ], options: [.sortedKeys])
                FileHandle.standardOutput.write(результат)
                FileHandle.standardOutput.write(Data([0x0a]))
                if !ошибки.isEmpty { exit(EXIT_FAILURE) }
            } catch {
                fputs("Не удалось проверить identity до коммита: \(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
            return
        }
        if аргументы.first == "--проверить-сырой-merge-коммит" {
            guard аргументы.count == 3 else {
                fputs("Ожидаются путь к состояние.json и путь к независимому ожиданию merge (schema, ordered expectedParents, expectedTree); сырой объект читается из stdin.\n", stderr)
                exit(EXIT_FAILURE)
            }
            do {
                let данные = try Data(contentsOf: URL(fileURLWithPath: аргументы[1]))
                let состояние = try JSONDecoder().decode(СостояниеКоординации.self, from: данные)
                guard let план = состояние.планСамообновления else {
                    throw CocoaError(.coderValueNotFound)
                }
                let ожидание = try JSONDecoder().decode(
                    ОжиданиеСырогоMergeКоммита.self,
                    from: Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                )
                guard ожидание.schema == "fum.raw-merge-commit-expectation.1" else {
                    throw NSError(domain: "RawMergeExpectation", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Unsupported merge expectation schema"])
                }
                let родительПлана = план.идентичностьСледующегоКоммита.родитель
                let ошибкиСвязиРодителя = ОценщикИдентичностиGit.проверитьСвязьПервогоРодителяСлиянияСПланом(
                    ожидаемыеРодители: ожидание.expectedParents,
                    родительПлана: родительПлана
                )
                if !ошибкиСвязиРодителя.isEmpty {
                    let вывод: [String: Any] = [
                        "schema": ожидание.schema,
                        "expectedParents": ожидание.expectedParents,
                        "родительПлана": родительПлана,
                        "expectedTree": ожидание.expectedTree,
                        "проверено": false,
                        "ошибки": ошибкиСвязиРодителя
                    ]
                    let результат = try JSONSerialization.data(withJSONObject: вывод, options: [.sortedKeys])
                    FileHandle.standardOutput.write(результат)
                    FileHandle.standardOutput.write(Data([0x0a]))
                    exit(EXIT_FAILURE)
                }
                let сыройОбъект = FileHandle.standardInput.readDataToEndOfFile()
                let метаданные = try сгенерироватьМетаданные(план, expectedRootUUID: состояние.корневойUUID)
                var ошибки = ОценщикИдентичностиGit.проверитьСыройMergeОбъект(
                    сыройОбъект,
                    метаданные: метаданные,
                    ожидаемыеРодители: ожидание.expectedParents,
                    ожидаемоеДерево: ожидание.expectedTree
                )
                if метаданные.выборМодели.rootUUID != состояние.корневойUUID {
                    ошибки.append("model-selection-receipt-не-связан-с-корневым-uuid-состояния")
                }
                let вывод: [String: Any] = [
                    "schema": ожидание.schema,
                    "expectedParents": ожидание.expectedParents,
                    "родительПлана": родительПлана,
                    "expectedTree": ожидание.expectedTree,
                    "проверено": ошибки.isEmpty,
                    "ошибки": ошибки
                ]
                let результат = try JSONSerialization.data(withJSONObject: вывод, options: [.sortedKeys])
                FileHandle.standardOutput.write(результат)
                FileHandle.standardOutput.write(Data([0x0a]))
                if !ошибки.isEmpty { exit(EXIT_FAILURE) }
            } catch {
                fputs("Не удалось проверить сырой merge Git-объект: \(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
            return
        }
        if аргументы.first == "--проверить-сырой-коммит" {
            guard аргументы.count == 3 else {
                fputs("Ожидаются путь к состояние.json и ожидаемый tree OID; сырой объект коммита читается из stdin.\n", stderr)
                exit(EXIT_FAILURE)
            }
            do {
                let данные = try Data(contentsOf: URL(fileURLWithPath: аргументы[1]))
                let состояние = try JSONDecoder().decode(СостояниеКоординации.self, from: данные)
                guard let план = состояние.планСамообновления else {
                    throw CocoaError(.coderValueNotFound)
                }
                let сыройОбъект = FileHandle.standardInput.readDataToEndOfFile()
                let метаданные = try сгенерироватьМетаданные(план, expectedRootUUID: состояние.корневойUUID)
                var ошибкиСырогоОбъекта = ОценщикИдентичностиGit.проверитьСыройОбъект(
                    сыройОбъект,
                    метаданные: метаданные,
                    ожидаемыйParent: план.идентичностьСледующегоКоммита.родитель,
                    ожидаемоеДерево: аргументы[2]
                )
                if метаданные.выборМодели.rootUUID != состояние.корневойUUID {
                    ошибкиСырогоОбъекта.append("model-selection-receipt-не-связан-с-корневым-uuid-состояния")
                }
                let финальныйВывод = ["проверено": ошибкиСырогоОбъекта.isEmpty, "ошибки": ошибкиСырогоОбъекта] as [String: Any]
                let результат = try JSONSerialization.data(withJSONObject: финальныйВывод, options: [.sortedKeys])
                FileHandle.standardOutput.write(результат)
                FileHandle.standardOutput.write(Data([0x0a]))
                if !ошибкиСырогоОбъекта.isEmpty { exit(EXIT_FAILURE) }
            } catch {
                fputs("Не удалось проверить сырой Git-объект: \(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
            return
        }
        if аргументы.first == "--проверить-пост-эффектный-git" {
            guard аргументы.count == 3 else {
                fputs("Ожидаются пути к состояние.json и независимому ожиданию пост-эффекта; Git читается из текущего worktree и origin.\n", stderr)
                exit(EXIT_FAILURE)
            }
            do {
                let состояниеДанные = try Data(contentsOf: URL(fileURLWithPath: аргументы[1]))
                let ожиданиеДанные = try Data(contentsOf: URL(fileURLWithPath: аргументы[2]))
                let состояние = try JSONDecoder().decode(СостояниеКоординации.self, from: состояниеДанные)
                let ожидание = try JSONDecoder().decode(ОжидаемоеПостЭффектноеСостояниеGit.self, from: ожиданиеДанные)
                guard let план = состояние.планСамообновления,
                      ожидание.oidРодителя == план.идентичностьСледующегоКоммита.родитель else {
                    throw CocoaError(.coderValueNotFound)
                }
                let метаданные = try сгенерироватьМетаданные(план, expectedRootUUID: состояние.корневойUUID)
                let наблюдение = try АдаптерПостЭффектаGit.прочитать(ожидание: ожидание)
                let итог = АдаптерПостЭффектаGit.проверить(
                    ожидание: ожидание,
                    наблюдение: наблюдение,
                    метаданные: метаданные
                )
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
                FileHandle.standardOutput.write(try encoder.encode(итог))
                FileHandle.standardOutput.write(Data([0x0a]))
                if !итог.проверено { exit(EXIT_FAILURE) }
            } catch {
                fputs("Не удалось проверить выбранный Git post-effect: \(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
            return
        }
        guard аргументы.count == 2 else {
            fputs("Ожидаются пути к состояние.json и журнал.jsonl.\n", stderr)
            exit(EXIT_FAILURE)
        }

        do {
            let состояниеДанные = try Data(contentsOf: URL(fileURLWithPath: аргументы[0]))
            let журналДанные = try Data(contentsOf: URL(fileURLWithPath: аргументы[1]))
            guard let журнал = String(data: журналДанные, encoding: .utf8) else {
                fputs("Журнал должен быть UTF-8.\n", stderr)
                exit(EXIT_FAILURE)
            }
            let состояние = try JSONDecoder().decode(СостояниеКоординации.self, from: состояниеДанные)
            let итог = Оценщик.оценить(состояние: состояние, журнал: журнал)
            let кодировщик = JSONEncoder()
            кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let результат = try кодировщик.encode(итог)
            FileHandle.standardOutput.write(результат)
            FileHandle.standardOutput.write(Data([0x0a]))
            if let самообновление = итог.самообновление, !самообновление.ошибкиПлана.isEmpty || самообновление.решенияИсточников.contains(where: { !$0.ошибки.isEmpty }) {
                exit(EXIT_FAILURE)
            }
            if !итог.действителен {
                exit(EXIT_FAILURE)
            }
        } catch {
            fputs("Не удалось прочитать снимок: \(error.localizedDescription)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }

    private static func сгенерироватьМетаданные(
        _ план: ПланСамообновления,
        expectedRootUUID: String
    ) throws -> РезультатГенерацииМетаданныхКоммита {
        guard let receipt = план.идентичностьСледующегоКоммита.квитанцияВыбораМодели else {
            throw CocoaError(.coderValueNotFound)
        }
        let witness = receipt.свидетельство
        let input = ПакетВходаГенератораFUMA(cases: [
            ВходСлучаяГенератораFUMA(
                id: "commit-metadata",
                acceptedSelection: witness.selectedValue,
                rootUUID: witness.rootUUID,
                title: план.сообщениеСледующегоКоммита.заголовок,
                description: план.сообщениеСледующегоКоммита.описание,
                rawRequest: план.сообщениеСледующегоКоммита.исходныйЗапрос
            )
        ])
        let environment = ProcessInfo.processInfo.environment
        guard let definition = environment["KOORDINACIYA_FUMA_DEFINITION"],
              let executable = environment["KOORDINACIYA_FUMA_OPERATOR"],
              let runRoot = environment["KOORDINACIYA_FUMA_RUN_ROOT"] else {
            throw NSError(domain: "FUMAOperator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Set KOORDINACIYA_FUMA_DEFINITION, KOORDINACIYA_FUMA_OPERATOR and KOORDINACIYA_FUMA_RUN_ROOT."])
        }
        let run = try ИсполнительГенератораFUMA.выполнить(
            input: input,
            definitionPath: definition,
            operatorPath: executable,
            privateRunRoot: runRoot
        )
        guard let outputCase = run.пакет.cases.first,
              run.пакет.cases.count == 1,
              outputCase.id == "commit-metadata" else {
            throw NSError(domain: "FUMAOperator", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "FUMA returned an unexpected case set."])
        }
        let output = ВыходГенератораGitMetadata(environment: outputCase.environment, message: outputCase.message)
        let prepared = ГенераторМетаданныхКоммита.подготовитьОкружение(
            ожидаемаяИдентичность: план.идентичностьСледующегоКоммита,
            expectedRootUUID: expectedRootUUID,
            выходFUMA: output
        )
        guard prepared.ошибки.isEmpty, let checkedOutput = prepared.выходFUMA else {
            throw NSError(domain: "FUMAOperator", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "FUMA output or API selection receipt failed pre-effect validation: \(prepared.ошибки.joined(separator: ", "))"])
        }
        var authorEnvironment = environment
        for (key, value) in checkedOutput.environment { authorEnvironment[key] = value }
        let authorGitVar = try выполнитьGit(["var", "GIT_AUTHOR_IDENT"], окружение: authorEnvironment)
        let committerGitVar = try выполнитьGit(["var", "GIT_COMMITTER_IDENT"], окружение: environment)
        return ГенераторМетаданныхКоммита.сгенерироватьЭталон(
            ожидаемаяИдентичность: план.идентичностьСледующегоКоммита,
            expectedRootUUID: expectedRootUUID,
            authorGitVar: authorGitVar,
            committerGitVar: committerGitVar,
            план: план.сообщениеСледующегоКоммита,
            выходFUMA: checkedOutput
        )
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func выполнитьGit(_ аргументы: [String], окружение: [String: String]) throws -> String {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = аргументы
        процесс.environment = окружение
        let вывод = Pipe()
        let ошибки = Pipe()
        процесс.standardOutput = вывод
        процесс.standardError = ошибки
        try процесс.run()
        процесс.waitUntilExit()
        guard процесс.terminationStatus == 0 else {
            let текстОшибки = String(decoding: ошибки.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw NSError(domain: "Координатор.Гит", code: Int(процесс.terminationStatus), userInfo: [NSLocalizedDescriptionKey: текстОшибки])
        }
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        guard let строка = String(data: данные, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return строка.trimmingCharacters(in: .newlines)
    }
}
#endif
