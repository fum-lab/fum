import Foundation
import CryptoKit

enum ПротоколОбъектовКорпуса {
    static func прочитать(повторы: [String: Int], занято: Int, записать: (Data) throws -> Void,
        прочитать: (Int) throws -> Data?, закончить: () throws -> Void) throws -> [String: (хэш: String, размер: Int)] {
        guard занято >= 0, занято <= 134_217_728, повторы.count <= 8192, повторы.values.allSatisfy({ $0 > 0 && $0 <= 8192 }), повторы.values.reduce(0, +) <= 8192,
              повторы.keys.allSatisfy({ $0.range(of: #"\A[0-9a-f]{40}\z"#, options: .regularExpression) != nil }) else { throw ОтказКорпусаСсылок.условие("неверный-вход-Git-протокола") }
        var итог: [String: (String, Int)] = [:], сумма = занято
        for объект in повторы.keys.sorted() {
            try записать(Data((объект + "\n").utf8))
            var заголовок = Data()
            while заголовок.last != 10 {
                guard заголовок.count < 128, let байт = try прочитать(1), байт.count == 1 else { throw ОтказКорпусаСсылок.условие("неполный-заголовок-Git-объекта") }
                заголовок.append(байт)
            }
            guard let строка = String(data: заголовок.dropLast(), encoding: .utf8) else { throw ОтказКорпусаСсылок.условие("неверный-заголовок-Git-объекта") }
            let поля = строка.split(separator: " ", omittingEmptySubsequences: false)
            guard поля.count == 3, поля[0] == объект, поля[1] == "blob", let размер = Int(поля[2]), размер >= 0, размер <= 33_554_432,
                  String(размер) == поля[2], let кратность = повторы[объект], кратность > 0,
                  размер <= (134_217_728 - сумма) / кратность else { throw ОтказКорпусаСсылок.условие("неверный-тип-размер-или-предел-Git-объекта") }
            сумма += размер * кратность
            var хэш = SHA256(), гитХэш = Insecure.SHA1(), прочитано = 0
            гитХэш.update(data: Data("blob \(размер)\0".utf8))
            while прочитано < размер {
                guard let часть = try прочитать(min(1_048_576, размер - прочитано)), !часть.isEmpty,
                      часть.count <= min(1_048_576, размер - прочитано) else { throw ОтказКорпусаСсылок.условие("оборвано-тело-Git-объекта") }
                хэш.update(data: часть); гитХэш.update(data: часть); прочитано += часть.count
            }
            guard try прочитать(1) == Data([10]),
                  гитХэш.finalize().map({ String(format: "%02x", $0) }).joined() == объект else { throw ОтказКорпусаСсылок.условие("не-совпало-обрамление-или-SHA1-Git-объекта") }
            итог[объект] = (хэш.finalize().map { String(format: "%02x", $0) }.joined(), размер)
        }
        try закончить()
        guard try прочитать(1)?.isEmpty != false else { throw ОтказКорпусаСсылок.условие("лишний-хвост-Git-batch") }
        return итог
    }
}

#if ФУМ_ОЖИДАНИЕ_КОРПУСА_КОМАНДА
@main struct ЗапускСоставителяОжидания {
    static func main() {
        do {
            guard CommandLine.arguments.count == 4 else { throw ОтказКорпусаСсылок.условие("нужны-корень-источник-и-его-закреплённый-SHA256") }
            let вход = try ограниченно(FileHandle.standardInput)
            _ = try ТокеныJSONМиграции.разобрать(вход)
            let основа = try JSONDecoder().decode(ОсноваОбщейМиграции.self, from: вход)
            let ручка = try FileHandle(forReadingFrom: URL(fileURLWithPath: CommandLine.arguments[2])); defer { try? ручка.close() }
            let источник = try ограниченно(ручка), начало = DispatchTime.now().uptimeNanoseconds
            let результат = try СоставительОжиданияКорпуса.составить(корень: URL(fileURLWithPath: CommandLine.arguments[1]), основа: основа,
                собственныйИсточник: источник, ожидаемыйХэшИсточника: CommandLine.arguments[3])
            try FileHandle.standardOutput.write(contentsOf: байтыПлана(результат))
            try FileHandle.standardError.write(contentsOf: Data("ожидание: \(результат.документы.count) документов; \(DispatchTime.now().uptimeNanoseconds - начало) нс; роли и ссылки не проверены\n".utf8))
        } catch { try? FileHandle.standardError.write(contentsOf: Data("ожидание: отказ \(error)\n".utf8)); exit(2) }
    }
    private static func ограниченно(_ ручка: FileHandle) throws -> Data {
        var данные = Data()
        while let часть = try ручка.read(upToCount: 1_048_576), !часть.isEmpty {
            guard часть.count <= 4_194_304 - данные.count else { throw ОтказКорпусаСсылок.условие("предел-входа-составителя") }
            данные.append(часть)
        }
        return данные
    }
}
#endif

enum СоставительОжиданияКорпуса {
    static func составить(корень: URL, основа: ОсноваОбщейМиграции, собственныйИсточник: Data, ожидаемыйХэшИсточника: String,
        передФинальнойСверкойДляПроверки: (() throws -> Void)? = nil) throws -> ОжиданиеСнимкаКорпуса {
        guard Data(корень.path.utf8) == Data(корень.resolvingSymlinksInPath().path.utf8),
              ожидаемыйХэшИсточника.range(of: #"\A[0-9a-f]{64}\z"#, options: .regularExpression) != nil,
              хэшПутей(собственныйИсточник) == ожидаемыйХэшИсточника else { throw ОтказКорпусаСсылок.условие("не-закреплён-отдельный-источник") }
        _ = try ОбщийПланировщикПутей.построить(основа: основа, ожидаемаяОснова: основа, узлы: [], корни: [])
        _ = try ТокеныJSONМиграции.разобрать(собственныйИсточник)
        let свой = try JSONDecoder().decode(ИсточникСобственныхДокументов.self, from: собственныйИсточник)
        guard свой.схема == "fum.private-source-checkpoint.1", Data(свой.корень.utf8) == Data(корень.path.utf8),
              свой.коммит == основа.коммит, Data(свой.ветка.utf8) == Data(основа.ветка.utf8) else { throw ОтказКорпусаСсылок.условие("иная-опора-собственных-документов") }
        var собственные: [Data: ЗаписьСобственногоДокумента] = [:]
        for запись in свой.файлы + свой.открытыйЖурнал where (запись.путь as NSString).pathExtension == "md" {
            try ИменаПутей.проверитьПуть(запись.путь)
            guard запись.размер >= 0, запись.размер <= 33_554_432, ["100644", "100755"].contains(запись.режим ?? "100644"),
                  запись.хэш.range(of: #"\A[0-9a-f]{64}\z"#, options: .regularExpression) != nil,
                  собственные.updateValue(запись, forKey: Data(запись.путь.utf8)) == nil else { throw ОтказКорпусаСсылок.условие("неверная-собственная-опора") }
        }
        try проверитьОснову(корень, основа)
        let индексДо = try гит(корень, ["ls-files", "--stage", "-z"])
        let индекс = try ЧитательДокументовКорпуса.разобратьИндекс(индексДо)
        let полныеДо = try гит(корень, ["ls-files", "--cached", "--others", "-z"])
        let политика = try ПолитикаГраницПутей.принятая()
        let состав = try ЧитательДокументовКорпуса.состав(полныеДо, индекс: индекс, политика: политика, собственные: собственные)
        guard (1...8192).contains(состав.документы.count),
              Set(состав.документы.filter { $0.value == "собственный-неотслеживаемый" }.keys) == Set(собственные.keys) else { throw ОтказКорпусаСсылок.условие("предел-или-неполный-собственный-состав-ожидания") }
        let группы = Dictionary(grouping: состав.документы.keys, by: { Data(String(decoding: $0, as: UTF8.self).precomposedStringWithCanonicalMapping.utf8) })
        guard группы.values.allSatisfy({ $0.count == 1 }) else { throw ОтказКорпусаСсылок.условие("алиасы-источников-ожидания") }
        let дерево = try гит(корень, ["ls-tree", "--full-tree", "-rz", основа.дерево])
        guard дерево.last == 0 else { throw ОтказКорпусаСсылок.условие("незамкнутое-Git-дерево") }
        var листья: [Data: (режим: String, объект: String)] = [:]
        for сырая in дерево.split(separator: 0) {
            guard let строка = String(data: сырая, encoding: .utf8), let табуляция = строка.firstIndex(of: "\t") else { throw ОтказКорпусаСсылок.условие("не-UTF8-Git-дерево") }
            let поля = строка[..<табуляция].split(separator: " "), путь = String(строка[строка.index(after: табуляция)...])
            guard поля.count == 3, поля[2].range(of: #"\A[0-9a-f]{40}\z"#, options: .regularExpression) != nil,
                  листья.updateValue((String(поля[0]), String(поля[2])), forKey: Data(путь.utf8)) == nil else { throw ОтказКорпусаСсылок.условие("неверная-строка-Git-дерева") }
        }
        guard индекс.count == листья.count, индекс.allSatisfy({ ключ, запись in
            листья[ключ]?.режим == запись.режим && листья[ключ]?.объект == запись.объект
        }) else { throw ОтказКорпусаСсылок.условие("полный-индекс-не-равен-дереву-HEAD") }
        let отслеживаемые = состав.документы.filter { $0.value == "отслеживаемый" }.keys.sorted { $0.lexicographicallyPrecedes($1) }
        for ключ in отслеживаемые {
            guard let лист = листья[ключ], ["100644", "100755"].contains(лист.режим), индекс[ключ]?.режим == лист.режим,
                  индекс[ключ]?.объект == лист.объект else { throw ОтказКорпусаСсылок.условие("индекс-не-равен-независимому-дереву") }
        }
        let повторы = Dictionary(grouping: отслеживаемые, by: { листья[$0]!.объект }).mapValues(\.count)
        var сумма = 0
        for ключ in состав.документы.keys where состав.документы[ключ] == "собственный-неотслеживаемый" {
            guard let запись = собственные[ключ], запись.размер <= 134_217_728 - сумма else { throw ОтказКорпусаСсылок.условие("предел-собственных-байтов") }
            сумма += запись.размер
        }
        let объекты = try прочитатьОбъекты(корень, повторы: повторы, занято: сумма)
        var документы: [ФайлОжиданияКорпуса] = []
        for ключ in состав.документы.keys.sorted(by: { $0.lexicographicallyPrecedes($1) }) {
            let путь = String(decoding: ключ, as: UTF8.self)
            if состав.документы[ключ] == "отслеживаемый", let лист = листья[ключ], let байты = объекты[лист.объект] {
                документы.append(.init(путь: путь, хэш: байты.хэш, режим: лист.режим, размер: байты.размер, объект: лист.объект,
                    происхождение: "git:\(основа.коммит):\(путь)", класс: "отслеживаемый"))
            } else if let свой = собственные[ключ] {
                документы.append(.init(путь: путь, хэш: свой.хэш, режим: свой.режим ?? "100644", размер: свой.размер, объект: nil,
                    происхождение: "закреплённый-собственный-источник:\(ожидаемыйХэшИсточника)", класс: "собственный-неотслеживаемый"))
            } else { throw ОтказКорпусаСсылок.условие("потерян-участник-ожидания") }
        }
        try передФинальнойСверкойДляПроверки?()
        guard try гит(корень, ["ls-files", "--cached", "--others", "-z"]) == полныеДо,
              try гит(корень, ["ls-files", "--stage", "-z"]) == индексДо else { throw ОтказКорпусаСсылок.условие("поздний-дрейф-метаданных-ожидания") }
        try проверитьОснову(корень, основа)
        let результат = ОжиданиеСнимкаКорпуса(основа: основа, политикаГраницХэш: "5a52f1134876854e29db243cbfc6eebc86cc916a4d354ba73a0fc7516109bcd4",
            источникСобственныхХэш: ожидаемыйХэшИсточника, всеМетаданныеХэш: хэшПутей(полныеДо), документы: документы)
        guard try байтыПлана(результат).count <= 4_194_304 else { throw ОтказКорпусаСсылок.условие("предел-JSON-ожидания") }
        return результат
    }

    private static func проверитьОснову(_ корень: URL, _ основа: ОсноваОбщейМиграции) throws {
        let ответ = try гит(корень, ["rev-parse", "--show-toplevel"])
        guard ответ.last == 10, let путь = String(data: ответ.dropLast(), encoding: .utf8),
              Data(URL(fileURLWithPath: путь).resolvingSymlinksInPath().standardizedFileURL.path.utf8) == Data(корень.standardizedFileURL.path.utf8) else { throw ОтказКорпусаСсылок.условие("иной-физический-Git-корень") }
        for (аргументы, значение) in [(["rev-parse", "HEAD"], основа.коммит),
            (["rev-parse", "HEAD^{tree}"], основа.дерево), (["symbolic-ref", "HEAD"], основа.ветка)] {
            guard try гит(корень, аргументы) == Data((значение + "\n").utf8) else { throw ОтказКорпусаСсылок.условие("дрейф-основы-ожидания-" + аргументы.joined(separator: ".")) }
        }
        guard try хэшПутей(гит(корень, ["ls-files", "--stage", "-z"])) == основа.индексSHA256 else { throw ОтказКорпусаСсылок.условие("дрейф-индекса-ожидания") }
    }

    private static func процесс(_ корень: URL, _ аргументы: [String]) -> Process {
        // Ограничения окружения соответствуют ЧитательПакета.гит; потоковый
        // протокол здесь отдельный и не использует readDataToEndOfFile.
        let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["--no-optional-locks", "--no-replace-objects", "--literal-pathspecs", "-c", "core.fsmonitor=false", "-C", корень.path] + аргументы
        var среда = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        среда["GIT_OPTIONAL_LOCKS"] = "0"; среда["GIT_CONFIG_NOSYSTEM"] = "1"; среда["GIT_CONFIG_GLOBAL"] = "/dev/null"; среда["GIT_NO_LAZY_FETCH"] = "1"
        процесс.environment = среда; процесс.standardError = FileHandle.nullDevice
        return процесс
    }

    private static func гит(_ корень: URL, _ аргументы: [String]) throws -> Data {
        let задача = процесс(корень, аргументы), канал = Pipe(); задача.standardOutput = канал
        try задача.run()
        defer { try? канал.fileHandleForReading.close(); if задача.isRunning { задача.terminate() }; задача.waitUntilExit() }
        var данные = Data()
        while let часть = try канал.fileHandleForReading.read(upToCount: 1_048_576), !часть.isEmpty {
            guard часть.count <= 16_777_216 - данные.count else { throw ОтказКорпусаСсылок.условие("предел-Git-метаданных-ожидания") }
            данные.append(часть)
        }
        задача.waitUntilExit()
        guard задача.terminationStatus == 0 else { throw ОтказКорпусаСсылок.условие("Git-отказ-составителя") }
        return данные
    }

    private static func прочитатьОбъекты(_ корень: URL, повторы: [String: Int], занято: Int) throws -> [String: (хэш: String, размер: Int)] {
        guard !повторы.isEmpty else { return [:] }
        let задача = процесс(корень, ["cat-file", "--batch"]), вход = Pipe(), выход = Pipe()
        задача.standardInput = вход; задача.standardOutput = выход
        try задача.run()
        defer {
            try? вход.fileHandleForWriting.close(); try? выход.fileHandleForReading.close()
            if задача.isRunning { задача.terminate() }; задача.waitUntilExit()
        }
        let итог = try ПротоколОбъектовКорпуса.прочитать(повторы: повторы, занято: занято,
            записать: { try вход.fileHandleForWriting.write(contentsOf: $0) }, прочитать: { try выход.fileHandleForReading.read(upToCount: $0) },
            закончить: { try вход.fileHandleForWriting.close() })
        задача.waitUntilExit()
        guard задача.terminationStatus == 0 else { throw ОтказКорпусаСсылок.условие("Git-batch-отказ") }
        return итог
    }
}
