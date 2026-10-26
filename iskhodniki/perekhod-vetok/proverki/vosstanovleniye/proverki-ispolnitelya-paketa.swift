import CryptoKit
import Foundation
import Testing
@testable import МатериализацияУзлов

private let корневойUUIDПакета = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
private let uuidИсполнителяПакета = "01a177a3-cb11-75d1-adc8-8aa71d0b3aeb"
private let refИсполнителяПакета =
    "refs/heads/fum-lab/fum/instrumentyi/perekhod-vetok/vosstanovleniye/master"
private let oidИсполнителяПакета = "9909c19aade5820e41798d155f9c30978b48453d"
private let областьИсполнителяПакета =
    "iskhodniki/perekhod-vetok/zhurnal/vosstanovleniye"
private let путиРесурсовDriverПакета = [
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Info.plist",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Resources/Определения/UTF-8-в-UTF-32LE.json",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Resources/Определения/нормализация.json",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Resources/Фикстуры/malformed-llm-envelope.json",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Resources/Фикстуры/scenarios.json",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/_CodeSignature/CodeDirectory",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/_CodeSignature/CodeRequirements",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/_CodeSignature/CodeResources",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/_CodeSignature/CodeSignature",
    "FUMA_ЖурналУзла.bundle/Contents/Info.plist",
    "FUMA_ЖурналУзла.bundle/Contents/Resources/opredeleniya/sformirovatj-zapisj.json",
    "FUMA_ЖурналУзла.bundle/Contents/_CodeSignature/CodeDirectory",
    "FUMA_ЖурналУзла.bundle/Contents/_CodeSignature/CodeRequirements",
    "FUMA_ЖурналУзла.bundle/Contents/_CodeSignature/CodeResources",
    "FUMA_ЖурналУзла.bundle/Contents/_CodeSignature/CodeSignature"
]

private func sha256Пакета(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}

private func sha256КаноническойКартыПакета(
    _ закрепления: [ЗакреплениеИсходникаИсполнителяПакета]
) throws -> String {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var данные = try кодировщик.encode(закрепления)
    данные.append(0x0a)
    return sha256Пакета(данные)
}

private func sha256РесурсовПакета(
    _ закрепления: [ЗакреплениеИсходникаИсполнителяПакета]
) -> String {
    let строки = закрепления.sorted { $0.путь < $1.путь }
        .map { "\($0.путь)\u{0}\($0.sha256)\n" }.joined()
    return sha256Пакета(Data(строки.utf8))
}

private func jsonПакета(_ значение: Any) throws -> Data {
    var данные = try JSONSerialization.data(
        withJSONObject: значение, options: [.sortedKeys, .withoutEscapingSlashes])
    данные.append(10)
    return данные
}

private func изменённыйJSONПакета(
    _ данные: Data,
    _ изменить: (inout [String: Any]) throws -> Void
) throws -> Data {
    var объект = try #require(
        JSONSerialization.jsonObject(with: данные) as? [String: Any])
    try изменить(&объект)
    return try jsonПакета(объект)
}

private struct ФикстураИсполнителяПакета {
    let корень: URL
    let приватныйКаталог: URL
    let driver: URL
    let driverБайты: Data
    let вход: Data
    let байтыЗаписи: Data
    let идентификаторЗаписи = String(repeating: "a", count: 64)
    let закрепленияИсточника: [ЗакреплениеИсходникаИсполнителяПакета]
    let закрепленияТекущегоCheckout: [ЗакреплениеИсходникаИсполнителяПакета]
    let своиЗакрепления: [ЗакреплениеИсходникаИсполнителяПакета]
    let ресурсыDriver: [ЗакреплениеИсходникаИсполнителяПакета]

    init(размерDriver: Int? = nil) throws {
        let основа = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
            .appendingPathComponent("fum-paket-\(UUID().uuidString)", isDirectory: true)
        let кореньURL = основа.appendingPathComponent("FUM", isDirectory: true)
        let приватныйURL = основа.appendingPathComponent("private", isDirectory: true)
        let driverURL = основа.appendingPathComponent("fuma-driver")
        let driverДанные = размерDriver.map { Data(repeating: 0x41, count: $0) }
            ?? Data("fixture-driver".utf8)
        let записьДанные = Data("{\"fixture\":true}\n".utf8)
        try FileManager.default.createDirectory(
            at: кореньURL.appendingPathComponent(областьИсполнителяПакета, isDirectory: true)
                .appendingPathComponent("zhurnal", isDirectory: true),
            withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: приватныйURL, withIntermediateDirectories: true)
        let gitКаталог = кореньURL.appendingPathComponent(".git", isDirectory: true)
        try FileManager.default.createDirectory(at: gitКаталог, withIntermediateDirectories: true)
        try Data("ref: \(refИсполнителяПакета)\n".utf8).write(
            to: gitКаталог.appendingPathComponent("HEAD"), options: [.withoutOverwriting])
        try Data(("# pack-refs with: peeled fully-peeled sorted\n"
            + "\(oidИсполнителяПакета) \(refИсполнителяПакета)\n").utf8).write(
            to: gitКаталог.appendingPathComponent("packed-refs"),
            options: [.withoutOverwriting])
        try driverДанные.write(to: driverURL, options: [.withoutOverwriting])
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700], ofItemAtPath: driverURL.path)

        var ресурсы: [ЗакреплениеИсходникаИсполнителяПакета] = []
        for (номер, путь) in путиРесурсовDriverПакета.enumerated() {
            let байты = Data("resource-\(номер)".utf8)
            let url = основа.appendingPathComponent(путь)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try байты.write(to: url, options: [.withoutOverwriting])
            ресурсы.append(ЗакреплениеИсходникаИсполнителяПакета(
                путь: путь, sha256: sha256Пакета(байты)))
        }

        var источник: [ЗакреплениеИсходникаИсполнителяПакета] = []
        var текущий: [ЗакреплениеИсходникаИсполнителяПакета] = []
        for номер in 0..<34 {
            let путь = номер == 0 ? "Package.swift" : "fixture/source-\(номер).swift"
            let байтыИсточника = Data((номер == 0 ? "source-package" : "same-\(номер)").utf8)
            let текущиеБайты = Data((номер == 0 ? "current-package" : "same-\(номер)").utf8)
            источник.append(ЗакреплениеИсходникаИсполнителяПакета(
                путь: путь, sha256: sha256Пакета(байтыИсточника)))
            текущий.append(ЗакреплениеИсходникаИсполнителяПакета(
                путь: путь, sha256: sha256Пакета(текущиеБайты)))
            let url = кореньURL.appendingPathComponent(путь)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try текущиеБайты.write(to: url, options: [.withoutOverwriting])
        }
        let путиСвоих = [
            "iskhodniki/perekhod-vetok/uzlyi/vosstanovleniye/ispolnitelj-paketa.swift",
            "iskhodniki/perekhod-vetok/proverki/vosstanovleniye/proverki-ispolnitelya-paketa.swift"
        ]
        var свои: [ЗакреплениеИсходникаИсполнителяПакета] = []
        for (номер, путь) in путиСвоих.enumerated() {
            let байты = Data("own-\(номер)".utf8)
            let url = кореньURL.appendingPathComponent(путь)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try байты.write(to: url, options: [.withoutOverwriting])
            свои.append(ЗакреплениеИсходникаИсполнителяПакета(
                путь: путь, sha256: sha256Пакета(байты)))
        }

        корень = кореньURL
        приватныйКаталог = приватныйURL
        driver = driverURL
        driverБайты = driverДанные
        байтыЗаписи = записьДанные
        закрепленияИсточника = источник
        закрепленияТекущегоCheckout = текущий
        своиЗакрепления = свои
        ресурсыDriver = ресурсы
        вход = try Self.сформироватьВход(
            корень: корневойUUIDПакета, писатель: uuidИсполнителяПакета,
            область: областьИсполнителяПакета)
    }

    static func сформироватьВход(
        корень: String,
        писатель: String,
        область: String
    ) throws -> Data {
        try jsonПакета([
            "схема": "fum.вход-локальной-записи.1",
            "экземпляр": [
                "корень": корень,
                "писатель": писатель,
                "стадия": "исполнение-локального-fuma-пакета",
                "номер": 3
            ],
            "время": "2026-10-26T19:00:00Z",
            "область": область,
            "публичная": true,
            "происхождение": ["адресное поручение 6b7c72d2 и уточнение source-pinned-driver"],
            "сообщения": [],
            "решения": ["Проверять c6af 34/34 отдельно от разрешённой дельты Package.swift"],
            "проверки": [],
            "исход": "ограниченный цикл фикстуры",
            "остаток": [],
            "доставка": []
        ])
    }

    func пакет(
        ключDriver: String = "driver",
        добавитьНеизвестноеПоле: Bool = false,
        токенКорняПлана: String = "<собственный физический W/FUM>",
        driverSHA256: String? = nil
    ) throws -> Data {
        var объект: [String: Any] = [
            "схема": "fum.пакет-локального-журнала.1",
            "назначение": "Данные воспроизводимого запуска принятого FUMA CLI",
            ключDriver: [
                "путь": driver.path,
                "sha256": driverSHA256 ?? sha256Пакета(driverБайты),
                "ресурсы": "Использовать на месте с соседними ресурсами, не копировать и не пересобирать."
            ],
            "источник": [
                "коммит": "c6af44bf1ec061675b6205b9c6ee889d98264f28",
                "закрепления": "zhurnal/384-build.nachalo.json",
                "поле_закреплений": "входные_закрепления",
                "число_закреплений": 34,
                "результат": "zhurnal/384-build.iskhod.json",
                "руководство": "iskhodniki/zhurnal/rukovodstvo.md",
                "модель": "iskhodniki/zhurnal/modelj-zapisi.swift"
            ],
            "команды_argv": [
                ["<driver>", "журнал", "помощь"],
                ["<driver>", "журнал", "план", "--корень", токенКорняПлана,
                 "--вход", "<приватный input.json>"],
                ["<driver>", "журнал", "применить", "--корень", "<тот же W>",
                 "--вход", "<те же байты input>", "--план", "<сохранённый exact stdout plan.json>"]
            ],
            "обязательная_подстановка": "Все placeholders заменяются до запуска.",
            "вход": [
                "схема": "fum.вход-локальной-записи.1",
                "экземпляр": [
                    "корень": корневойUUIDПакета,
                    "писатель": "<собственный UUID>",
                    "стадия": "<ограниченный текущий этап>",
                    "номер": 1
                ],
                "время": "<фактическое время ISO8601>",
                "область": "<собственный key без конечного slash>",
                "публичная": true,
                "происхождение": [],
                "сообщения": [],
                "решения": [],
                "проверки": [],
                "исход": "<фактический>",
                "остаток": [],
                "доставка": []
            ],
            "границы": ["Сначала строгий допуск, затем один typed argv resolver."]
        ]
        if добавитьНеизвестноеПоле { объект["неизвестное"] = true }
        return try jsonПакета(объект)
    }

    func план() throws -> Data {
        try jsonПакета([
            "схема": "fum.ответ-плана-локальной-записи.1",
            "план": [
                "схема": "fum.план-локальной-записи.1",
                "цель": [
                    "кореньSHA256": sha256Пакета(Data(корень.path.utf8)),
                    "область": областьИсполнителяПакета,
                    "узлы": ["fixture-root", "fixture-scope", "fixture-journal"]
                ],
                "идентификатор": идентификаторЗаписи,
                "путь": "\(областьИсполнителяПакета)/zhurnal/\(идентификаторЗаписи).json",
                "входSHA256": sha256Пакета(вход),
                "операторSHA256": String(repeating: "b", count: 64),
                "содержаниеSHA256": sha256Пакета(байтыЗаписи),
                "байты": байтыЗаписи.base64EncodedString()
            ]
        ])
    }

    func ответПрименения(_ вид: String = "установлена") throws -> Data {
        try jsonПакета([
            "вид": вид,
            "путь": "\(областьИсполнителяПакета)/zhurnal/\(идентификаторЗаписи).json",
            "содержаниеSHA256": sha256Пакета(байтыЗаписи)
        ])
    }

    var цель: URL {
        корень.appendingPathComponent(областьИсполнителяПакета)
            .appendingPathComponent("zhurnal")
            .appendingPathComponent("\(идентификаторЗаписи).json")
    }

    func запрос(
        пакет: Data,
        вход: Data? = nil,
        наблюдениеЗакреплений: НаблюдениеЗакрепленийИсточникаПакета? = nil,
        текущиеЗакрепления: [ЗакреплениеИсходникаИсполнителяПакета]? = nil,
        разрешённыеТекущиеОтличия: [String] = ["Package.swift"]
    ) throws -> ЗапросИсполненияПакета {
        let фактическийВход = вход ?? self.вход
        let фактическиеТекущиеЗакрепления =
            текущиеЗакрепления ?? закрепленияТекущегоCheckout
        let исходнаяКартаSHA256 = try sha256КаноническойКартыПакета(
            закрепленияИсточника)
        let текущаяКартаSHA256 = try sha256КаноническойКартыПакета(
            фактическиеТекущиеЗакрепления)
        let исходникиИсполнителяКартаSHA256 = try sha256КаноническойКартыПакета(
            своиЗакрепления)
        let ресурсыDriverSHA256 = sha256РесурсовПакета(ресурсыDriver)
        let пакетURL = приватныйКаталог.appendingPathComponent("paket.json")
        if FileManager.default.fileExists(atPath: пакетURL.path) {
            guard try Data(contentsOf: пакетURL) == пакет else {
                throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
            }
        } else {
            try пакет.write(to: пакетURL, options: [.withoutOverwriting])
        }
        let основаОперации = [
            String(ИсправленныйДопускИсполнителяПакетаV2.версия),
            ИсправленныйДопускИсполнителяПакетаV2.коммитПостановки,
            ИсправленныйДопускИсполнителяПакетаV2.деревоПостановки,
            ИсправленныйДопускИсполнителяПакетаV2.родительПостановки,
            ИсправленныйДопускИсполнителяПакетаV2.blobПостановки,
            ИсправленныйДопускИсполнителяПакетаV2.sha256Постановки,
            sha256Пакета(пакет), driver.path, sha256Пакета(driverБайты),
            ресурсыDriverSHA256,
            ИсправленныйДопускИсполнителяПакетаV2.коммитИсточника,
            ИсправленныйДопускИсполнителяПакетаV2.деревоИсточника,
            ИсправленныйДопускИсполнителяПакетаV2.blobЗакреплений,
            ИсправленныйДопускИсполнителяПакетаV2.sha256ФайлаЗакреплений,
            исходнаяКартаSHA256,
            ИсправленныйДопускИсполнителяПакетаV2.коммитТекущейКарты,
            ИсправленныйДопускИсполнителяПакетаV2.деревоТекущейКарты,
            текущаяКартаSHA256,
            sha256Пакета(Data(
                ИсправленныйДопускИсполнителяПакетаV2.основаниеТекущихОтличий.utf8)),
            исходникиИсполнителяКартаSHA256,
            корневойUUIDПакета, uuidИсполнителяПакета,
            корень.path, refИсполнителяПакета, oidИсполнителяПакета,
            областьИсполнителяПакета, sha256Пакета(фактическийВход)
        ].joined(separator: "\u{0}")
        let операция = sha256Пакета(Data(основаОперации.utf8))
        let рабочийКаталог = приватныйКаталог
            .appendingPathComponent("ispolneniye", isDirectory: true)
            .appendingPathComponent(операция, isDirectory: true)
        try FileManager.default.createDirectory(
            at: рабочийКаталог, withIntermediateDirectories: true)
        let файлы = РабочиеФайлыИсполненияПакета(
            каталог: рабочийКаталог,
            вход: рабочийКаталог.appendingPathComponent("input.json"),
            план: рабочийКаталог.appendingPathComponent("plan.json"),
            намерениеApply: рабочийКаталог.appendingPathComponent("apply-intent.json"),
            исходApply: рабочийКаталог.appendingPathComponent("apply-outcome.json"))
        let назначение = НазначениеИсполнителяПакета(
            версияКоррекцииДопуска: ИсправленныйДопускИсполнителяПакетаV2.версия,
            корневойUUID: корневойUUIDПакета,
            uuidИсполнителя: uuidИсполнителяПакета,
            физическийКорень: корень,
            ref: refИсполнителяПакета,
            базовыйOID: oidИсполнителяПакета,
            область: областьИсполнителяПакета,
            коммитПостановки: ИсправленныйДопускИсполнителяПакетаV2.коммитПостановки,
            деревоПостановки: ИсправленныйДопускИсполнителяПакетаV2.деревоПостановки,
            родительПостановки:
                ИсправленныйДопускИсполнителяПакетаV2.родительПостановки,
            путьПостановки: ИсправленныйДопускИсполнителяПакетаV2.путьПостановки,
            blobПостановки: ИсправленныйДопускИсполнителяПакетаV2.blobПостановки,
            sha256Постановки: ИсправленныйДопускИсполнителяПакетаV2.sha256Постановки,
            путьПакета: пакетURL.path,
            sha256Пакета: sha256Пакета(пакет),
            байтовПакета: пакет.count,
            путьDriver: driver.path,
            sha256Driver: sha256Пакета(driverБайты),
            байтовDriver: driverБайты.count,
            закрепленияРесурсовDriver: ресурсыDriver,
            ресурсыDriverSHA256: ресурсыDriverSHA256,
            коммитИсточника: ИсправленныйДопускИсполнителяПакетаV2.коммитИсточника,
            деревоИсточника: ИсправленныйДопускИсполнителяПакетаV2.деревоИсточника,
            путьЗакреплений: ИсправленныйДопускИсполнителяПакетаV2.путьЗакреплений,
            blobЗакреплений: ИсправленныйДопускИсполнителяПакетаV2.blobЗакреплений,
            sha256ФайлаЗакреплений:
                ИсправленныйДопускИсполнителяПакетаV2.sha256ФайлаЗакреплений,
            числоЗакреплений: 34,
            путьРезультатаСборки: "zhurnal/384-build.iskhod.json",
            закрепленияИсточника: закрепленияИсточника,
            исходнаяКартаSHA256: исходнаяКартаSHA256,
            коммитТекущейКарты:
                ИсправленныйДопускИсполнителяПакетаV2.коммитТекущейКарты,
            деревоТекущейКарты:
                ИсправленныйДопускИсполнителяПакетаV2.деревоТекущейКарты,
            закрепленияТекущегоCheckout: фактическиеТекущиеЗакрепления,
            текущаяКартаSHA256: текущаяКартаSHA256,
            разрешённыеТекущиеОтличия: разрешённыеТекущиеОтличия,
            основаниеТекущихОтличий:
                ИсправленныйДопускИсполнителяПакетаV2.основаниеТекущихОтличий,
            закрепленияИсполнителя: своиЗакрепления,
            исходникиИсполнителяКартаSHA256: исходникиИсполнителяКартаSHA256)
        let физическоеНаблюдение = НаблюдениеФизическойПривязкиПакета(
            физическийКорень: корень,
            ref: refИсполнителяПакета,
            headOID: oidИсполнителяПакета,
            чисто: true,
            единственныйПисатель: true)
        let наблюдениеПостановки = НаблюдениеПостановкиИсполнителяПакета(
            коммит: ИсправленныйДопускИсполнителяПакетаV2.коммитПостановки,
            дерево: ИсправленныйДопускИсполнителяПакетаV2.деревоПостановки,
            родитель: ИсправленныйДопускИсполнителяПакетаV2.родительПостановки,
            путь: ИсправленныйДопускИсполнителяПакетаV2.путьПостановки,
            blob: ИсправленныйДопускИсполнителяПакетаV2.blobПостановки,
            sha256: ИсправленныйДопускИсполнителяПакетаV2.sha256Постановки)
        let наблюдениеACK = НаблюдениеACKИсполнителяПакета(
            uuidИсполнителя: uuidИсполнителяПакета,
            физическийКорень: корень,
            ref: refИсполнителяПакета,
            headOID: oidИсполнителяПакета,
            модель: "gpt-5.6-sol",
            усилие: "ultra",
            подтверждён: true)
        let обычноеНаблюдение = НаблюдениеЗакрепленийИсточникаПакета(
            коммит: "c6af44bf1ec061675b6205b9c6ee889d98264f28",
            деревоИсточника: ИсправленныйДопускИсполнителяПакетаV2.деревоИсточника,
            путьЗакреплений: "zhurnal/384-build.nachalo.json",
            blobЗакреплений: ИсправленныйДопускИсполнителяПакетаV2.blobЗакреплений,
            sha256ФайлаЗакреплений:
                ИсправленныйДопускИсполнителяПакетаV2.sha256ФайлаЗакреплений,
            путьРезультатаСборки: "zhurnal/384-build.iskhod.json",
            числоЗакреплений: 34,
            совпавшихЗакреплений: 34,
            закрепленияИсточника: закрепленияИсточника,
            исходнаяКартаSHA256: исходнаяКартаSHA256,
            коммитТекущейКарты:
                ИсправленныйДопускИсполнителяПакетаV2.коммитТекущейКарты,
            деревоТекущейКарты:
                ИсправленныйДопускИсполнителяПакетаV2.деревоТекущейКарты,
            закрепленияТекущегоCheckout: фактическиеТекущиеЗакрепления,
            текущаяКартаSHA256: текущаяКартаSHA256,
            текущиеОтличия: ["Package.swift"],
            закрепленияИсполнителя: своиЗакрепления,
            исходникиИсполнителяКартаSHA256: исходникиИсполнителяКартаSHA256,
            ресурсыDriverSHA256: ресурсыDriverSHA256)
        return ЗапросИсполненияПакета(
            пакет: пакетURL,
            входныеБайты: фактическийВход,
            назначение: назначение,
            наблюдениеПостановки: наблюдениеПостановки,
            наблюдениеACK: наблюдениеACK,
            физическоеНаблюдение: физическоеНаблюдение,
            наблюдениеЗакреплений: наблюдениеЗакреплений ?? обычноеНаблюдение,
            рабочиеФайлы: файлы)
    }
}

private enum ШагПоддельногоПроцесса: Sendable {
    case ответ(РезультатПроцессаПакета, записать: URL?, байты: Data?)
    case ответСЗаменой(РезультатПроцессаПакета, заменить: URL, байты: Data)
    case запускНеНачат
    case неизвестен(записать: URL?, байты: Data?)
    case неизвестенССсылкой(путь: URL, назначение: String)
}

private actor ПоддельныйПроцессПакета: ЗапускПроцессаПакета {
    private var шаги: [ШагПоддельногоПроцесса]
    private(set) var команды: [КомандаПроцессаПакета] = []
    private(set) var входПрименения: Data?
    private(set) var планПрименения: Data?

    init(_ шаги: [ШагПоддельногоПроцесса]) { self.шаги = шаги }

    func выполнить(_ команда: КомандаПроцессаПакета) async throws -> РезультатПроцессаПакета {
        команды.append(команда)
        if команда.действие == .применить {
            входПрименения = try Data(contentsOf: команда.значениеАргумента("--вход"))
            планПрименения = try Data(contentsOf: команда.значениеАргумента("--план"))
        }
        guard !шаги.isEmpty else { throw ОшибкаПроцессаПакета.запускНеНачат }
        switch шаги.removeFirst() {
        case .ответ(let результат, let путь, let байты):
            if let путь, let байты { try байты.write(to: путь, options: [.withoutOverwriting]) }
            return результат
        case .ответСЗаменой(let результат, let путь, let байты):
            try байты.write(to: путь)
            return результат
        case .запускНеНачат:
            throw ОшибкаПроцессаПакета.запускНеНачат
        case .неизвестен(let путь, let байты):
            if let путь, let байты { try байты.write(to: путь, options: [.withoutOverwriting]) }
            throw ОшибкаПроцессаПакета.исходНеизвестен
        case .неизвестенССсылкой(let путь, let назначение):
            try FileManager.default.createSymbolicLink(
                atPath: путь.path, withDestinationPath: назначение)
            throw ОшибкаПроцессаПакета.исходНеизвестен
        }
    }

    func снимок() -> (
        команды: [КомандаПроцессаПакета],
        вход: Data?,
        план: Data?
    ) { (команды, входПрименения, планПрименения) }
}

private func успешныйРезультат(_ stdout: Data) -> РезультатПроцессаПакета {
    РезультатПроцессаПакета(
        код: 0, stdout: stdout, stderr: Data(), завершениеПодтверждено: true)
}

private func отказано(_ действие: () async throws -> Void) async -> Bool {
    do { try await действие(); return false } catch { return true }
}

@Suite(.serialized)
struct ПроверкиИсполнителяПакета {
    @Test func публичныйSystemPathНеПринимаетФикстурныйПрофиль() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        var полученаТочнаяОшибка = false

        do {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(запрос)
        } catch ОшибкаИсполнителяПакета.неверноеНазначение {
            полученаТочнаяОшибка = true
        }

        #expect(полученаТочнаяОшибка)
        #expect(!FileManager.default.fileExists(atPath: запрос.рабочиеФайлы.вход.path))
    }

    @Test func системныйRunnerОграничиваетStdoutИПродолжаетДренирование() async throws {
        let файл = FileManager.default.temporaryDirectory
            .appendingPathComponent("fum-runner-output-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: файл) }
        try Data(repeating: 0x41, count: 1_048_577).write(
            to: файл, options: [.withoutOverwriting])
        let команда = КомандаПроцессаПакета(
            действие: .помощь,
            исполняемыйФайл: URL(fileURLWithPath: "/bin/cat"),
            аргументы: [файл.path])

        #expect(await отказано {
            _ = try await СистемныйЗапускПроцессаПакета().выполнить(команда)
        })
    }

    @Test func системныйRunnerОграничиваетВремяИЗавершаетПроцесс() async throws {
        let команда = КомандаПроцессаПакета(
            действие: .помощь,
            исполняемыйФайл: URL(fileURLWithPath: "/bin/sleep"),
            аргументы: ["2"])

        #expect(await отказано {
            _ = try await СистемныйЗапускПроцессаПакета(
                таймАутНаносекунд: 20_000_000).выполнить(команда)
        })
    }

    @Test(arguments: [
        "время", "роль", "вид", "исход-проверки", "согласованность-проверки",
        "доставка", "приватный-путь", "секрет", "секрет-в-url", "userinfo",
        "процентный-секрет", "тройной-секрет", "суффикс-секрета",
        "кодированный-путь", "localhost", "приватный-ipv4", "числовой-ipv4",
        "приватный-ipv6", "mapped-ipv6"
    ])
    func неверныйДоменВходаОтвергаетсяДоПроцесса(вариант: String) async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let вход = try изменённыйJSONПакета(фикстура.вход) { объект in
            switch вариант {
            case "время":
                объект["время"] = "не-время"
            case "роль":
                объект["сообщения"] = [[
                    "роль": "наблюдатель", "вид": "буквальное", "текст": "текст",
                    "происхождение": "фикстура"
                ]]
            case "вид":
                объект["сообщения"] = [[
                    "роль": "агент", "вид": "пересказ", "текст": "текст",
                    "происхождение": "фикстура"
                ]]
            case "исход-проверки":
                объект["проверки"] = [[
                    "название": "fixture", "исход": "почти",
                    "свидетельство": "fixture"
                ]]
            case "согласованность-проверки":
                объект["проверки"] = [[
                    "название": "fixture", "исход": "успешно", "код": 1,
                    "наносекунды": 1, "свидетельство": "fixture"
                ]]
            case "доставка":
                объект["доставка"] = [[
                    "вид": "", "идентификатор": "fixture", "свидетельство": "fixture"
                ]]
            case "приватный-путь":
                объект["происхождение"] = ["/Users/private/source.json"]
            case "секрет":
                объект["решения"] = ["ghp_abcdefghijklmnopqrstuvwxyz123456"]
            case "секрет-в-url":
                объект["решения"] = [
                    "https://example.org/?token=ghp_abcdefghijklmnopqrstuvwxyz123456"
                ]
            case "userinfo":
                объект["решения"] = ["https://agent:password@example.org/source"]
            case "процентный-секрет":
                объект["решения"] = [
                    "https://example.org/?token=ghp%5Fabcdefghijklmnopqrstuvwxyz123456"
                ]
            case "тройной-секрет":
                объект["решения"] = [
                    "https://example.org/?token=ghp%25255Fabcdefghijklmnopqrstuvwxyz123456"
                ]
            case "суффикс-секрета":
                объект["решения"] = [
                    "https://example.org/?token=ghp_abcdefghijklmnopqrstuvwxyz123456_x"
                ]
            case "кодированный-путь":
                объект["решения"] = [
                    "https://example.org/?source=%2FUsers%2Ffum%2Fprivate.json"
                ]
            case "localhost":
                объект["решения"] = ["https://localhost/source"]
            case "приватный-ipv4":
                объект["решения"] = ["https://192.168.1.10/source"]
            case "числовой-ipv4":
                объект["решения"] = ["https://2130706433/source"]
            case "приватный-ipv6":
                объект["решения"] = ["https://[::1]/source"]
            case "mapped-ipv6":
                объект["решения"] = ["https://[::ffff:7f00:1]/source"]
            default:
                Issue.record("Неизвестный вариант фикстуры")
            }
        }
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(пакет: фикстура.пакет(), вход: вход)

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test func публичныйWebИсточникДоходитДоПервогоПроцесса() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let вход = try изменённыйJSONПакета(фикстура.вход) { объект in
            объект["происхождение"] = ["https://example.org/public/source?id=42"]
        }
        let процесс = ПоддельныйПроцессПакета([])

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                фикстура.запрос(пакет: фикстура.пакет(), вход: вход),
                используя: процесс)
        })
        #expect(await процесс.команды.map(\.действие) == [.помощь])
    }

    @Test(arguments: ["missing", "unknown", "wrong-type", "repeated"])
    func закрытаяСтруктураВходаОтвергаетсяДоПроцесса(вариант: String) async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let вход: Data
        if вариант == "repeated" {
            let текст = try #require(String(data: фикстура.вход, encoding: .utf8))
            let поле = "\"время\":\"2026-10-26T19:00:00Z\""
            вход = Data(текст.replacingOccurrences(
                of: поле, with: поле + "," + поле).utf8)
        } else {
            вход = try изменённыйJSONПакета(фикстура.вход) { объект in
                switch вариант {
                case "missing":
                    объект.removeValue(forKey: "время")
                case "unknown":
                    объект["неизвестное"] = true
                case "wrong-type":
                    var экземпляр = try #require(
                        объект["экземпляр"] as? [String: Any])
                    экземпляр["номер"] = true
                    объект["экземпляр"] = экземпляр
                default:
                    Issue.record("Неизвестный вариант закрытой структуры")
                }
            }
        }
        let процесс = ПоддельныйПроцессПакета([])

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                фикстура.запрос(пакет: фикстура.пакет(), вход: вход),
                используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test func дрейфРесурсаDriverОтвергаетсяДоПроцесса() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let ресурс = фикстура.driver.deletingLastPathComponent()
            .appendingPathComponent(путиРесурсовDriverПакета[0])
        try Data("resource-drift".utf8).write(to: ресурс)
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test func лишнийРесурсDriverОтвергаетсяДоПроцесса() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let ресурс = фикстура.driver.deletingLastPathComponent()
            .appendingPathComponent(
                "FUMA_ЖурналУзла.bundle/Contents/Resources/extra.json")
        try Data("extra".utf8).write(to: ресурс, options: [.withoutOverwriting])
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test(arguments: ["drvier", "driver"])
    func закрытыеКлючиПакетаОтвергаютсяДоПроцесса(ключ: String) async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let неизвестноеПоле = ключ == "driver"
        let пакет = try фикстура.пакет(
            ключDriver: ключ, добавитьНеизвестноеПоле: неизвестноеПоле)
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(пакет: пакет)

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test func неподставленныйPlaceholderОтвергаетсяДоПроцесса() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let пакет = try фикстура.пакет(токенКорняПлана: "<неразрешённый W>")
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(пакет: пакет)

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test(arguments: ["чужая-область", "ROOT-писатель"])
    func чужаяПривязкаВходаОтвергаетсяДоПроцесса(вариант: String) async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let вход: Data
        if вариант == "чужая-область" {
            вход = try ФикстураИсполнителяПакета.сформироватьВход(
                корень: корневойUUIDПакета, писатель: uuidИсполнителяПакета,
                область: "iskhodniki/perekhod-vetok/zhurnal/chuzhaya")
        } else {
            вход = try ФикстураИсполнителяПакета.сформироватьВход(
                корень: корневойUUIDПакета, писатель: корневойUUIDПакета,
                область: областьИсполнителяПакета)
        }
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(пакет: фикстура.пакет(), вход: вход)

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test func неверныйProvenanceИлиDriverОтвергаетсяДоПроцесса() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let неверныеЗакрепления = НаблюдениеЗакрепленийИсточникаПакета(
            коммит: "c6af44bf1ec061675b6205b9c6ee889d98264f28",
            деревоИсточника: ИсправленныйДопускИсполнителяПакетаV2.деревоИсточника,
            путьЗакреплений: "zhurnal/384-build.nachalo.json",
            blobЗакреплений: ИсправленныйДопускИсполнителяПакетаV2.blobЗакреплений,
            sha256ФайлаЗакреплений:
                ИсправленныйДопускИсполнителяПакетаV2.sha256ФайлаЗакреплений,
            путьРезультатаСборки: "zhurnal/384-build.iskhod.json",
            числоЗакреплений: 34,
            совпавшихЗакреплений: 33,
            закрепленияИсточника: фикстура.закрепленияИсточника,
            исходнаяКартаSHA256: try sha256КаноническойКартыПакета(
                фикстура.закрепленияИсточника),
            коммитТекущейКарты:
                ИсправленныйДопускИсполнителяПакетаV2.коммитТекущейКарты,
            деревоТекущейКарты:
                ИсправленныйДопускИсполнителяПакетаV2.деревоТекущейКарты,
            закрепленияТекущегоCheckout: фикстура.закрепленияТекущегоCheckout,
            текущаяКартаSHA256: try sha256КаноническойКартыПакета(
                фикстура.закрепленияТекущегоCheckout),
            текущиеОтличия: ["Package.swift"],
            закрепленияИсполнителя: фикстура.своиЗакрепления,
            исходникиИсполнителяКартаSHA256: try sha256КаноническойКартыПакета(
                фикстура.своиЗакрепления),
            ресурсыDriverSHA256: sha256РесурсовПакета(фикстура.ресурсыDriver))
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(
            пакет: фикстура.пакет(), наблюдениеЗакреплений: неверныеЗакрепления)

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test func неверныйХэшDriverВПакетеОтвергаетсяДоПроцесса() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(пакет: фикстура.пакет(
            driverSHA256: String(repeating: "e", count: 64)))

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test func заменаDriverПослеHelpОтвергаетсяДоPlan() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let процесс = ПоддельныйПроцессПакета([
            .ответСЗаменой(
                успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                заменить: фикстура.driver, байты: Data("changed-driver".utf8))
        ])
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.map(\.действие) == [.помощь])
    }

    @Test func дрейфHEADПослеHelpОтвергаетсяДоPlan() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let packedRefs = фикстура.корень.appendingPathComponent(".git/packed-refs")
        let процесс = ПоддельныйПроцессПакета([
            .ответСЗаменой(
                успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                заменить: packedRefs,
                байты: Data((String(repeating: "f", count: 40)
                    + " \(refИсполнителяПакета)\n").utf8))
        ])

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                фикстура.запрос(пакет: фикстура.пакет()), используя: процесс)
        })
        #expect(await процесс.команды.map(\.действие) == [.помощь])
    }

    @Test func дрейфРесурсаПослеPlanОтвергаетсяДоApply() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let ресурс = фикстура.driver.deletingLastPathComponent()
            .appendingPathComponent(путиРесурсовDriverПакета[0])
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответСЗаменой(
                успешныйРезультат(try фикстура.план()),
                заменить: ресурс,
                байты: Data("resource-drift-after-plan".utf8))
        ])

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                фикстура.запрос(пакет: фикстура.пакет()), используя: процесс)
        })
        #expect(await процесс.команды.map(\.действие) == [.помощь, .план])
    }

    @Test func незаявленноеОтличиеЗакрытойКартыH9909ОтвергаетсяДоПроцесса() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        var текущие = фикстура.закрепленияТекущегоCheckout
        текущие[1] = ЗакреплениеИсходникаИсполнителяПакета(
            путь: текущие[1].путь, sha256: String(repeating: "4", count: 64))
        let процесс = ПоддельныйПроцессПакета([])
        let запрос = try фикстура.запрос(
            пакет: фикстура.пакет(), текущиеЗакрепления: текущие)

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.isEmpty)
    }

    @Test func разрешённаяДельтаPackageНеПодменяетЗакреплённыйDriver() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let план = try фикстура.план()
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(план), записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.ответПрименения()),
                   записать: фикстура.цель, байты: фикстура.байтыЗаписи)
        ])
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())

        let итог = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            запрос, используя: процесс)
        let снимок = await процесс.снимок()

        #expect(снимок.команды.map(\.действие) == [.помощь, .план, .применить])
        #expect(снимок.вход == фикстура.вход)
        #expect(снимок.план == план)
        #expect(итог.применение == .установлена)
        #expect(итог.квитанция.resolvedJournal == .localFUMA)
        #expect(итог.квитанция.applyВызван == true)
        #expect(итог.квитанция.applyСостояние == .завершён)
        #expect(итог.квитанция.applyИсходСохранён)
        #expect(итог.квитанция.applyНамерениеSHA256 != nil)
        #expect(итог.квитанция.версияКоррекцииДопуска == 2)
        #expect(итог.квитанция.коммитПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.коммитПостановки)
        #expect(итог.квитанция.деревоПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.деревоПостановки)
        #expect(итог.квитанция.родительПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.родительПостановки)
        #expect(итог.квитанция.blobПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.blobПостановки)
        #expect(итог.квитанция.постановкаSHA256
            == ИсправленныйДопускИсполнителяПакетаV2.sha256Постановки)
        #expect(итог.квитанция.источникКоммит
            == ИсправленныйДопускИсполнителяПакетаV2.коммитИсточника)
        #expect(итог.квитанция.источникДерево
            == ИсправленныйДопускИсполнителяПакетаV2.деревоИсточника)
        #expect(итог.квитанция.закрепленияBlob
            == ИсправленныйДопускИсполнителяПакетаV2.blobЗакреплений)
        #expect(итог.квитанция.файлЗакрепленийSHA256
            == ИсправленныйДопускИсполнителяПакетаV2.sha256ФайлаЗакреплений)
        #expect(итог.квитанция.текущаяКартаКоммит
            == ИсправленныйДопускИсполнителяПакетаV2.коммитТекущейКарты)
        #expect(итог.квитанция.текущаяКартаДерево
            == ИсправленныйДопускИсполнителяПакетаV2.деревоТекущейКарты)
        #expect(итог.квитанция.исходнаяКартаSHA256
            == запрос.назначение.исходнаяКартаSHA256)
        #expect(итог.квитанция.текущаяКартаSHA256
            == запрос.назначение.текущаяКартаSHA256)
        #expect(итог.квитанция.исходникиИсполнителяSHA256
            == запрос.назначение.исходникиИсполнителяКартаSHA256)
        #expect(итог.квитанция.ресурсыDriverSHA256
            == запрос.назначение.ресурсыDriverSHA256)
        #expect(итог.квитанция.операцияSHA256
            == запрос.рабочиеФайлы.каталог.lastPathComponent)
        let квитанцияJSON = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(итог.квитанция))
                as? [String: Any])
        #expect(квитанцияJSON["resolved_journal"] as? String == "local_fuma")
        #expect(квитанцияJSON["resolvedJournal"] == nil)
        #expect(итог.квитанция.планSHA256 == sha256Пакета(план))
        #expect(итог.квитанция.readbackSHA256 == sha256Пакета(фикстура.байтыЗаписи))
    }

    @Test func размерПринятогоDriverНеОтвергаетсяОбщимЛимитомЧтения() async throws {
        let фикстура = try ФикстураИсполнителяПакета(размерDriver: 4_127_264)
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.ответПрименения()),
                   записать: фикстура.цель, байты: фикстура.байтыЗаписи)
        ])

        let итог = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            фикстура.запрос(пакет: фикстура.пакет()), используя: процесс)

        #expect(итог.применение == .установлена)
        #expect(await процесс.команды.count == 3)
    }

    @Test func точныеБайтыПланаНеПересериализуютсяПередApply() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let каноническийПлан = try фикстура.план()
        let объект = try #require(
            JSONSerialization.jsonObject(with: каноническийПлан) as? [String: Any])
        let план = Data((" \n" + String(decoding: try JSONSerialization.data(
            withJSONObject: объект, options: [.prettyPrinted, .withoutEscapingSlashes]),
            as: UTF8.self) + "  \n").utf8)
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(план), записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.ответПрименения()),
                   записать: фикстура.цель, байты: фикстура.байтыЗаписи)
        ])

        _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            фикстура.запрос(пакет: фикстура.пакет()), используя: процесс)
        let снимок = await процесс.снимок()

        #expect(снимок.план == план)
        #expect(снимок.вход == фикстура.вход)
    }

    @Test func неизвестныйЧастичныйЭффектСначалаЧитаетсяИНеОчищается() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let частичныеБайты = Data(фикстура.байтыЗаписи.prefix(7))
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .неизвестен(записать: фикстура.цель, байты: частичныеБайты)
        ])

        let итог = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            фикстура.запрос(пакет: фикстура.пакет()), используя: процесс)

        #expect(итог.применение == .конфликт)
        #expect(await процесс.команды.count == 3)
        #expect(try Data(contentsOf: фикстура.цель) == частичныеБайты)
        #expect(итог.квитанция.readbackSHA256 == sha256Пакета(частичныеБайты))
    }

    @Test func ссылкаПослеНеизвестногоApplyДаётТипизированныйКонфликт() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .неизвестенССсылкой(путь: фикстура.цель, назначение: "/dev/null")
        ])

        let итог = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            фикстура.запрос(пакет: фикстура.пакет()), используя: процесс)

        #expect(итог.применение == .конфликт)
        #expect(итог.квитанция.readbackСостояние == .ошибка)
        #expect(итог.квитанция.applyВызван == true)
        #expect(итог.квитанция.applyСостояние == .исходНеизвестен)
        #expect(итог.квитанция.applyИсходСохранён)
        #expect(await процесс.команды.count == 3)
    }

    @Test func неизвестныйИсходБезФайлаНеРазрешаетПовторApply() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        let первыйПроцесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .неизвестен(записать: nil, байты: nil)
        ])
        let первыйИтог = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            запрос, используя: первыйПроцесс)
        #expect(первыйИтог.применение == .неизвестен)

        let второйПроцесс = ПоддельныйПроцессПакета([])
        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: второйПроцесс)
        })
        #expect(await второйПроцесс.команды.isEmpty)
        let сверка = try ИсполнительПакетаЛокальногоЖурнала
            .сверитьПослеНеизвестногоИсходаДляФикстуры(запрос)
        #expect(сверка.применение == .неизвестен)
        #expect(сверка.квитанция.applyВызван == true)
        #expect(сверка.квитанция.applyСостояние == .исходНеизвестен)
        #expect(сверка.квитанция.applyИсходСохранён)
    }

    @Test func заранееСуществующееТочноеНамерениеНеРазрешаетApply() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        let первыйПроцесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .неизвестен(записать: nil, байты: nil)
        ])
        _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            запрос, используя: первыйПроцесс)
        try FileManager.default.removeItem(at: запрос.рабочиеФайлы.вход)
        try FileManager.default.removeItem(at: запрос.рабочиеФайлы.план)
        try FileManager.default.removeItem(at: запрос.рабочиеФайлы.исходApply)
        #expect(FileManager.default.fileExists(
            atPath: запрос.рабочиеФайлы.намерениеApply.path))
        let второйПроцесс = ПоддельныйПроцессПакета([])
        var полученТочныйКонфликт = false

        do {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: второйПроцесс)
        } catch ОшибкаИсполнителяПакета.конфликтРабочихБайт {
            полученТочныйКонфликт = true
        }

        #expect(полученТочныйКонфликт)
        #expect(await второйПроцесс.команды.isEmpty)
    }

    @Test func запускApplyНеНачатНеВыдаётсяЗаНеизвестныйЭффект() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .запускНеНачат
        ])

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                запрос, используя: процесс)
        })
        #expect(await процесс.команды.count == 3)
        #expect(FileManager.default.fileExists(
            atPath: запрос.рабочиеФайлы.исходApply.path))
        var recoveryОтказан = false
        do {
            _ = try ИсполнительПакетаЛокальногоЖурнала
                .сверитьПослеНеизвестногоИсходаДляФикстуры(запрос)
        } catch ОшибкаИсполнителяПакета.запускApplyНеНачат {
            recoveryОтказан = true
        }
        #expect(recoveryОтказан)
    }

    @Test func завершённыйApplyПриRecoveryНеСтановитсяНеизвестным() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        let ответApply = try фикстура.ответПрименения()
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .ответ(успешныйРезультат(ответApply),
                   записать: фикстура.цель, байты: фикстура.байтыЗаписи)
        ])
        _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            запрос, используя: процесс)

        let сверка = try ИсполнительПакетаЛокальногоЖурнала
            .сверитьПослеНеизвестногоИсходаДляФикстуры(запрос)

        #expect(сверка.применение == .наблюдена)
        #expect(сверка.квитанция.applyВызван == true)
        #expect(сверка.квитанция.applyСостояние == .завершён)
        #expect(сверка.квитанция.applyИсходСохранён)
        #expect(сверка.квитанция.applyКод == 0)
        #expect(сверка.квитанция.applyЗавершениеПодтверждено == true)
        #expect(сверка.квитанция.applySHA256 == sha256Пакета(ответApply))
        #expect(сверка.квитанция.applyStdoutБайтов == ответApply.count)
        #expect(сверка.квитанция.applyStderrБайтов == 0)
        #expect(сверка.квитанция.applyStderrSHA256 == sha256Пакета(Data()))
        #expect(сверка.квитанция.applyИсходSHA256 != nil)
        #expect(сверка.квитанция.applyНамерениеSHA256 != nil)
    }

    @Test func intentБезФазыНеУтверждаетЧтоApplyВызван() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .неизвестен(записать: nil, байты: nil)
        ])
        _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            запрос, используя: процесс)
        try FileManager.default.removeItem(at: запрос.рабочиеФайлы.исходApply)

        let сверка = try ИсполнительПакетаЛокальногоЖурнала
            .сверитьПослеНеизвестногоИсходаДляФикстуры(запрос)

        #expect(сверка.применение == .неизвестен)
        #expect(сверка.квитанция.applyВызван == nil)
        #expect(сверка.квитанция.applyСостояние == .исходНеизвестен)
        #expect(!сверка.квитанция.applyИсходСохранён)
    }

    @Test func подменённаяФазаApplyДаётКонфликтПослеReadback() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .неизвестен(записать: фикстура.цель, байты: фикстура.байтыЗаписи)
        ])
        _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            запрос, используя: процесс)
        let подмена = try изменённыйJSONПакета(
            Data(contentsOf: запрос.рабочиеФайлы.исходApply)) { объект in
                объект["операция"] = String(repeating: "f", count: 64)
            }
        try подмена.write(to: запрос.рабочиеФайлы.исходApply)

        let сверка = try ИсполнительПакетаЛокальногоЖурнала
            .сверитьПослеНеизвестногоИсходаДляФикстуры(запрос)

        #expect(сверка.применение == .конфликт)
        #expect(сверка.квитанция.readbackСостояние == .точный)
        #expect(сверка.квитанция.applyВызван == nil)
        #expect(!сверка.квитанция.applyИсходСохранён)
    }

    @Test func новыйScratchНеОбходитНамерениеНеизвестногоApply() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        let первыйПроцесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil),
            .неизвестен(записать: nil, байты: nil)
        ])
        _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            запрос, используя: первыйПроцесс)

        let новыйКаталог = фикстура.приватныйКаталог
            .appendingPathComponent("new-scratch", isDirectory: true)
        try FileManager.default.createDirectory(
            at: новыйКаталог, withIntermediateDirectories: false)
        let новыеФайлы = РабочиеФайлыИсполненияПакета(
            каталог: новыйКаталог,
            вход: новыйКаталог.appendingPathComponent("input.json"),
            план: новыйКаталог.appendingPathComponent("plan.json"),
            намерениеApply: новыйКаталог.appendingPathComponent("apply-intent.json"),
            исходApply: новыйКаталог.appendingPathComponent("apply-outcome.json"))
        let обход = ЗапросИсполненияПакета(
            пакет: запрос.пакет,
            входныеБайты: запрос.входныеБайты,
            назначение: запрос.назначение,
            наблюдениеПостановки: запрос.наблюдениеПостановки,
            наблюдениеACK: запрос.наблюдениеACK,
            физическоеНаблюдение: запрос.физическоеНаблюдение,
            наблюдениеЗакреплений: запрос.наблюдениеЗакреплений,
            рабочиеФайлы: новыеФайлы)
        let второйПроцесс = ПоддельныйПроцессПакета([])

        #expect(await отказано {
            _ = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
                обход, используя: второйПроцесс)
        })
        #expect(await второйПроцесс.команды.isEmpty)
        var recoveryОтказанТочно = false
        do {
            _ = try ИсполнительПакетаЛокальногоЖурнала
                .сверитьПослеНеизвестногоИсходаДляФикстуры(обход)
        } catch ОшибкаИсполнителяПакета.неверныеРабочиеФайлы {
            recoveryОтказанТочно = true
        }
        #expect(recoveryОтказанТочно)
    }

    @Test func существующаяТочнаяЗаписьИсключаетПовторApply() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        try фикстура.байтыЗаписи.write(to: фикстура.цель, options: [.withoutOverwriting])
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(try фикстура.план()), записать: nil, байты: nil)
        ])

        let итог = try await ИсполнительПакетаЛокальногоЖурнала.выполнить(
            фикстура.запрос(пакет: фикстура.пакет()), используя: процесс)

        #expect(итог.применение == .наблюденаДоПрименения)
        #expect(итог.квитанция.applyВызван == false)
        #expect(итог.квитанция.applyСостояние == .неВызывался)
        #expect(!итог.квитанция.applyИсходСохранён)
        #expect(await процесс.команды.map(\.действие) == [.помощь, .план])
        #expect(try Data(contentsOf: фикстура.цель) == фикстура.байтыЗаписи)
    }

    @Test func восстановлениеНеизвестногоИсходаНачинаетсяСReadbackБезПроцесса() async throws {
        let фикстура = try ФикстураИсполнителяПакета()
        let запрос = try фикстура.запрос(пакет: фикстура.пакет())
        let план = try фикстура.план()
        let процесс = ПоддельныйПроцессПакета([
            .ответ(успешныйРезультат(Data("fuma журнал план\nfuma журнал применить\n".utf8)),
                   записать: nil, байты: nil),
            .ответ(успешныйРезультат(план), записать: nil, байты: nil),
            .неизвестен(записать: nil, байты: nil)
        ])
        let неизвестныйИтог = try await ИсполнительПакетаЛокальногоЖурнала
            .выполнить(запрос, используя: процесс)
        #expect(неизвестныйИтог.применение == .неизвестен)

        try фикстура.байтыЗаписи.write(to: фикстура.цель, options: [.withoutOverwriting])
        try Data("driver-drift-after-unknown".utf8).write(to: фикстура.driver)

        let итог = try ИсполнительПакетаЛокальногоЖурнала
            .сверитьПослеНеизвестногоИсходаДляФикстуры(запрос)

        #expect(итог.применение == .наблюденаПослеНеизвестности)
        #expect(итог.квитанция.помощьSHA256 == nil)
        #expect(итог.квитанция.applySHA256 == nil)
        #expect(итог.квитанция.планSHA256 == sha256Пакета(план))
        #expect(!итог.квитанция.повторныйДопуск)
        #expect(итог.квитанция.доставкаПакета == .неПодтверждена)
        #expect(итог.квитанция.ackИсполнителя == .неПодтверждён)
    }
}
