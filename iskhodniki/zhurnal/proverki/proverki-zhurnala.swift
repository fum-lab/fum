import Foundation
import Testing
import Darwin
@testable import ЖурналУзла
import ОсноваЗапуска

func примерВхода() -> ВходЗаписи {
    ВходЗаписи(экземпляр: ЭкземплярЗаписи(корень: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb",
        писатель: "01a175db-2729-7e32-bef8-e6d5ee3f9cd0", стадия: "реализация", номер: 1),
        время: "2026-10-26T05:00:00Z", область: "iskhodniki/zhurnal", публичная: true,
        происхождение: ["Поручение ROOT, Issue381"],
        сообщения: [СообщениеЗаписи(роль: .агент, вид: .буквальное,
            текст: "Сохранить ёмкую запись", происхождение: "Нативное поручение", оригинал: nil)],
        решения: ["Сохранить", "Сохранить"], проверки: [], исход: "План", остаток: ["Применить"], доставка: [])
}

@Test func одинаковыйПланИПовторы() throws {
    var вход = примерВхода()
    вход.сообщения.append(вход.сообщения[0])
    let данные = try ПредставлениеЗапуска.байты(вход, читаемо: true)
    let цель = СнимокЦели(хэшКорня: "тест", область: вход.область, узлы: ["1"])
    let оператор = try ПланировщикЗаписи.оператор()
    let первый = try ПланировщикЗаписи.построить(данные, оператор: оператор, цель: цель)
    let повтор = try ПланировщикЗаписи.построить(данные, оператор: оператор, цель: цель)
    #expect(первый == повтор)
    #expect(первый.байты.last == 10)
    #expect(первый.путь == вход.область + "/zhurnal/" + первый.идентификатор + ".json")
    #expect(String(decoding: первый.байты, as: UTF8.self).contains("Сохранить ёмкую запись"))
    let первое = вход.сообщения[0]
    var второеСообщение = первое
    второеСообщение.текст = "Второе сообщение"
    второеСообщение.происхождение = "Второй источник"
    var третьеСообщение = первое
    третьеСообщение.текст = "Третье сообщение с ё"
    третьеСообщение.происхождение = "Третий источник"
    let ожидаемые = [первое, второеСообщение, первое, третьеСообщение, второеСообщение]
    вход.сообщения = ожидаемые
    let упорядоченный = try ПланировщикЗаписи.построить(ПредставлениеЗапуска.байты(вход, читаемо: true), оператор: оператор, цель: цель)
    let тело = try JSONDecoder().decode(ТелоЗаписи.self, from: упорядоченный.байты)
    #expect(тело.данные.сообщения.count == 5)
    #expect(тело.данные.сообщения == ожидаемые)
    #expect(тело.данные.сообщения.map { Data($0.текст.utf8) } == [
        "Сохранить ёмкую запись", "Второе сообщение", "Сохранить ёмкую запись", "Третье сообщение с ё", "Второе сообщение"
    ].map { Data($0.utf8) })
    #expect(тело.данные.сообщения.map(\.происхождение) == [
        "Нативное поручение", "Второй источник", "Нативное поручение", "Третий источник", "Второй источник"
    ])
    #expect(тело.данные.решения == ["Сохранить", "Сохранить"])
    // Независимая fixture: SHA256 точных UTF-8-байтов канонического экземпляра,
    // отдельно полученный стандартным shasum; helper планировщика здесь не вызывается.
    #expect(упорядоченный.идентификатор == "6ff2f86e5fa074793336c9b62c980f16bb47d696110946b77b490c01f900e7c4")
    #expect(упорядоченный.путь == "iskhodniki/zhurnal/zhurnal/6ff2f86e5fa074793336c9b62c980f16bb47d696110946b77b490c01f900e7c4.json")
    вход.время = "2026-10-26T05:01:00Z"
    let второй = try ПланировщикЗаписи.построить(ПредставлениеЗапуска.байты(вход, читаемо: true), оператор: оператор, цель: цель)
    #expect(второй.путь == первый.путь)
    #expect(второй.байты != первый.байты)
}

@Test func закрытыйВходИПубликационнаяГраница() throws {
    var вход = примерВхода()
    // Конструируем машинную форму из компонентов: фактическое имя среды не раскрывается.
    let машинный = String(UnicodeScalar(47)) + ["Users", "fixture", "repo"].joined(separator: "/")
    вход.сообщения[0].текст = "<область>/zhurnal " + машинный
    #expect(throws: ОтказЖурнала.публикация) { try вход.проверить() }
    let оригинал = Data(вход.сообщения[0].текст.utf8)
    вход.сообщения[0] = try ПубличноеПредставление.представить(оригинал, источник: "Нативный агентский вход",
        точноеВхождение: машинный, замена: "〈приватный checkout〉")
    try вход.проверить()
    #expect(вход.сообщения[0].оригинал?.байтов == оригинал.count)
    #expect(вход.сообщения[0].оригинал?.хэш == хэш(оригинал))
    #expect(throws: ОтказЖурнала.вход) {
        try ПубличноеПредставление.представить(Data("нет поля".utf8), источник: "Тест", точноеВхождение: машинный, замена: "нет")
    }
    #expect(throws: ОтказЖурнала.вход) {
        try ПубличноеПредставление.представить(Data((машинный + машинный).utf8), источник: "Тест", точноеВхождение: машинный, замена: "нет")
    }
}

@Test func запускБезАргументовСохранился() throws {
    guard case .запуск = try ВходКоманды.разобрать([]) else { Issue.record("Прежний запуск изменён"); return }
}

func временнаяЦель() throws -> URL {
    guard let физический = realpath(FileManager.default.temporaryDirectory.path, nil) else { throw ОтказЖурнала.путь }
    defer { free(физический) }
    let корень = URL(fileURLWithPath: String(cString: физический), isDirectory: true).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: корень.appendingPathComponent("iskhodniki/zhurnal/zhurnal"), withIntermediateDirectories: true)
    return корень
}

func планВ(_ корень: URL, вход: ВходЗаписи = примерВхода()) throws -> (ПланЗаписи, Data, Data) {
    let данные = try ПредставлениеЗапуска.байты(вход, читаемо: true)
    let оператор = try ПланировщикЗаписи.оператор()
    let цель = try ГраницаЦели.наблюдать(корень: корень.path, область: вход.область)
    return (try ПланировщикЗаписи.построить(данные, оператор: оператор, цель: цель), данные, оператор)
}

@Test func планБезЭффектаОднаУстановкаИКонфликт() throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let (план, вход, оператор) = try планВ(корень)
    let каталог = корень.appendingPathComponent("iskhodniki/zhurnal/zhurnal")
    #expect(try FileManager.default.contentsOfDirectory(atPath: каталог.path).isEmpty)
    let первый = try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path)
    #expect(первый.вид == .установлена)
    let повтор = try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path)
    #expect(повтор.вид == .наблюдена)
    #expect(try FileManager.default.contentsOfDirectory(atPath: каталог.path).count == 1)
    #expect(try Data(contentsOf: корень.appendingPathComponent(план.путь)) == план.байты)
    var изменённый = примерВхода()
    изменённый.исход = "Изменённый исход"
    let (конфликт, новыеДанные, _) = try планВ(корень, вход: изменённый)
    #expect(конфликт.путь == план.путь)
    #expect(throws: ОтказЖурнала.конфликт) {
        try ФайловыйАдаптер.применить(конфликт, вход: новыеДанные, оператор: оператор, корень: корень.path)
    }
}

@Test func дрейфВсехПривязок() throws {
    let корень = try временнаяЦель()
    let другой = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень); try? FileManager.default.removeItem(at: другой) }
    let (план, вход, оператор) = try планВ(корень)
    #expect(throws: ОтказЖурнала.дрейф) {
        try ФайловыйАдаптер.применить(план, вход: вход + Data([10]), оператор: оператор, корень: корень.path)
    }
    #expect(throws: ОтказЖурнала.дрейф) {
        try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор + Data([10]), корень: корень.path)
    }
    #expect(throws: ОтказЖурнала.дрейф) {
        try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: другой.path)
    }
    var подмена = план
    подмена.путь = "../escape.json"
    #expect(throws: ОтказЖурнала.дрейф) {
        try ФайловыйАдаптер.применить(подмена, вход: вход, оператор: оператор, корень: корень.path)
    }
    let каталог = корень.appendingPathComponent("iskhodniki/zhurnal/zhurnal")
    try FileManager.default.moveItem(at: каталог, to: корень.appendingPathComponent("бывший"))
    try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
    #expect(throws: ОтказЖурнала.дрейф) {
        try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path)
    }
}

@Test(arguments: ИнъекцияЗаписи.allCases) func границыФайловогоЭффекта(_ инъекция: ИнъекцияЗаписи) throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let (план, вход, оператор) = try планВ(корень)
    let цель = корень.appendingPathComponent(план.путь)
    if [.нет, .короткиеЗаписи].contains(инъекция) {
        #expect(try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path, инъекция: инъекция).вид == .установлена)
    } else {
        #expect(throws: ОтказЖурнала.файловыйЭффект) {
            try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path, инъекция: инъекция)
        }
    }
    if инъекция == .передСозданием {
        #expect(!FileManager.default.fileExists(atPath: цель.path))
        #expect(try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path).вид == .установлена)
    } else if [.послеСоздания, .послеЧасти].contains(инъекция) {
        let остаток = try Data(contentsOf: цель)
        #expect(остаток.count < план.байты.count)
        #expect(throws: ОтказЖурнала.конфликт) {
            try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path)
        }
        #expect(try Data(contentsOf: цель) == остаток)
    } else {
        let атрибуты = try FileManager.default.attributesOfItem(atPath: цель.path)
        #expect(try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path).вид == .наблюдена)
        let после = try FileManager.default.attributesOfItem(atPath: цель.path)
        #expect(атрибуты[.systemFileNumber] as? UInt64 == после[.systemFileNumber] as? UInt64)
        #expect(атрибуты[.modificationDate] as? Date == после[.modificationDate] as? Date)
        #expect(try Data(contentsOf: цель) == план.байты)
    }
}

@Test(arguments: ["../escape", "a//b", "/escape", "a/./b", "a/../b", "a\\b"])
func отказНебезопаснойОбласти(_ область: String) throws {
    #expect(throws: ОтказЖурнала.путь) { try ГраницаЦели.проверитьОбласть(область) }
}

@Test func ссылкиИКоллизииИмен() throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let (план, вход, оператор) = try планВ(корень)
    let цель = корень.appendingPathComponent(план.путь)
    try FileManager.default.createSymbolicLink(atPath: цель.path, withDestinationPath: "отсутствует")
    #expect(throws: ОтказЖурнала.путь) {
        try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path)
    }
    try FileManager.default.removeItem(at: цель)
    try Data().write(to: цель.deletingLastPathComponent().appendingPathComponent(цель.lastPathComponent.uppercased()))
    #expect(throws: ОтказЖурнала.коллизия) {
        try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path)
    }
}

@Test(arguments: ["<", "путь:", " "])
func соседнийМашинныйПутьНеСкрываетсяШаблоном(_ префикс: String) throws {
    let машинный = String(UnicodeScalar(47)) + ["Users", "fixture", "repo"].joined(separator: "/")
    var вход = примерВхода()
    вход.сообщения[0].текст = "<область>/zhurnal " + префикс + машинный
    #expect(throws: ОтказЖурнала.публикация) { try вход.проверить() }
}

@Test func закрытыйСоставДубликатыИЭкранирование() throws {
    let цель = СнимокЦели(хэшКорня: "тест", область: "iskhodniki/zhurnal", узлы: ["1"])
    let оператор = try ПланировщикЗаписи.оператор()
    let данные = try ПредставлениеЗапуска.байты(примерВхода(), читаемо: true)
    let текст = String(decoding: данные, as: UTF8.self)
    for лишнее in [#""report.historical": true,"#, #""время":"дубликат","#] {
        let подмена = Data(("{" + лишнее + String(текст.dropFirst())).utf8)
        #expect(throws: (any Error).self) { try ПланировщикЗаписи.построить(подмена, оператор: оператор, цель: цель) }
    }
    let экранированный = Data(текст.replacingOccurrences(of: "/", with: #"\u002f"#).utf8)
    let план = try ПланировщикЗаписи.построить(экранированный, оператор: оператор, цель: цель)
    #expect(план.байты.last == 10)
}

@Test(arguments: 0..<10) func машинныйПутьВоВсехСмысловыхПолях(_ номер: Int) throws {
    var вход = примерВхода()
    let путь = String(UnicodeScalar(47)) + ["Users", "fixture", "repo"].joined(separator: "/")
    switch номер {
    case 0: вход.сообщения[0].текст = "report.historical " + путь
    case 1: вход.сообщения[0].происхождение = путь
    case 2: вход.сообщения[0].вид = .производное
        вход.сообщения[0].оригинал = ОригиналСообщения(хэш: String(repeating: "a", count: 64), байтов: 1, источник: путь)
    case 3: вход.решения = [путь]
    case 4: вход.проверки = [ПроверкаЗаписи(название: путь, исход: .неПроверено, код: nil, наносекунды: nil, свидетельство: "Не запущена")]
    case 5: вход.проверки = [ПроверкаЗаписи(название: "Проверка", исход: .неПроверено, код: nil, наносекунды: nil, свидетельство: путь)]
    case 6: вход.исход = путь
    case 7: вход.остаток = [путь]
    case 8: вход.доставка = [ДоставкаЗаписи(вид: "Ссылка", идентификатор: путь, свидетельство: "Нет")]
    default: вход.происхождение = [путь]
    }
    #expect(throws: ОтказЖурнала.публикация) { try вход.проверить() }
    вход.публичная = false
    #expect(throws: ОтказЖурнала.публикация) { try вход.проверить() }
}

@Test func видыМашинныхФормИИсточники() throws {
    let косая = String(UnicodeScalar(47))
    let обратная = String(UnicodeScalar(92))
    for путь in [косая + "etc" + косая + "file", "C:" + обратная + "fixture", обратная + обратная + "host" + обратная + "share",
        "file:" + косая + косая + "fixture", "~" + косая + "fixture"] {
        #expect(throws: ОтказЖурнала.публикация) { try ПубличноеПредставление.проверить(Data(путь.utf8)) }
    }
    try ПубличноеПредставление.проверить(Data("https://github.com/fum-lab/fum/issues/381 <область>/zhurnal".utf8))
}

func отдельныйПроцесс(_ аргументы: [String]) throws -> (Int32, Data) {
    guard let команда = ProcessInfo.processInfo.environment["FUM_КОМАНДА_ЖУРНАЛА"] else {
        Issue.record("Нужен явный путь к собранному единственному product fuma через FUM_КОМАНДА_ЖУРНАЛА")
        throw ОтказЖурнала.вход
    }
    let процесс = Process()
    процесс.executableURL = URL(fileURLWithPath: команда)
    процесс.arguments = ["журнал"] + аргументы
    let канал = Pipe()
    процесс.standardOutput = канал
    процесс.standardError = канал
    try процесс.run()
    let данные = канал.fileHandleForReading.readDataToEndOfFile()
    процесс.waitUntilExit()
    return (процесс.terminationStatus, данные)
}

@Test func повторИКонфликтВОтдельномПроцессе() throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let (_, данные, _) = try планВ(корень)
    let вход = корень.appendingPathComponent("vkhod.json")
    let файлПлана = корень.appendingPathComponent("plan.json")
    try данные.write(to: вход)
    let общие = ["--корень", корень.path, "--вход", вход.path]
    let (кодПлана, байтыПлана) = try отдельныйПроцесс(["план"] + общие)
    #expect(кодПлана == 0)
    try байтыПлана.write(to: файлПлана)
    let аргументы = ["применить"] + общие + ["--план", файлПлана.path]
    let (первыйКод, первый) = try отдельныйПроцесс(аргументы)
    #expect(первыйКод == 0)
    #expect(try JSONDecoder().decode(РезультатЗаписи.self, from: первый).вид == .установлена)
    let (кодПовтора, повтор) = try отдельныйПроцесс(аргументы)
    #expect(кодПовтора == 0)
    #expect(try JSONDecoder().decode(РезультатЗаписи.self, from: повтор).вид == .наблюдена)
    var изменённый = примерВхода()
    изменённый.исход = "Конфликт той же идентичности"
    try ПредставлениеЗапуска.байты(изменённый, читаемо: true).write(to: вход)
    let (кодНовогоПлана, новыйПлан) = try отдельныйПроцесс(["план"] + общие)
    #expect(кодНовогоПлана == 0)
    try новыйПлан.write(to: файлПлана)
    let (кодКонфликта, _) = try отдельныйПроцесс(аргументы)
    #expect(кодКонфликта == 2)
    let ответ = try JSONDecoder().decode(ОтветПланаЗаписи.self, from: байтыПлана)
    #expect(try Data(contentsOf: корень.appendingPathComponent(ответ.план.путь)) == ответ.план.байты)
}

@Test func частичныйОстатокВНовомПроцессеНеПовторяется() throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let (план, данные, оператор) = try планВ(корень)
    #expect(throws: ОтказЖурнала.файловыйЭффект) {
        try ФайловыйАдаптер.применить(план, вход: данные, оператор: оператор, корень: корень.path, инъекция: .послеЧасти)
    }
    let путь = корень.appendingPathComponent(план.путь)
    let остаток = try Data(contentsOf: путь)
    let вход = корень.appendingPathComponent("vkhod.json")
    let файлПлана = корень.appendingPathComponent("plan.json")
    try данные.write(to: вход)
    try ПредставлениеЗапуска.байты(ОтветПланаЗаписи(план: план), читаемо: true).write(to: файлПлана)
    let (код, _) = try отдельныйПроцесс(["применить", "--корень", корень.path, "--вход", вход.path, "--план", файлПлана.path])
    #expect(код == 2)
    #expect(try Data(contentsOf: путь) == остаток)
}

@Test(arguments: 0..<4) func символическиеПредкиИНормализация(_ номер: Int) throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let путь = ["iskhodniki", "iskhodniki/zhurnal", "iskhodniki/zhurnal/zhurnal", "iskhodniki/zhurnal/zhurnal"][номер]
    let прежний = корень.appendingPathComponent(путь)
    let сохранённый = корень.appendingPathComponent("старый")
    try FileManager.default.moveItem(at: прежний, to: сохранённый)
    if номер == 3 {
        // Фактическое NFC/NFD-имя читается как raw UTF-8, включая APFS-нормализацию.
        let имя = "\u{0435}\u{0308}"
        let новый = корень.appendingPathComponent(имя)
        try FileManager.default.moveItem(at: сохранённый, to: новый)
        let область = "\u{0451}"
        try FileManager.default.createDirectory(at: новый.appendingPathComponent("zhurnal"), withIntermediateDirectories: true)
        #expect(throws: ОтказЖурнала.коллизия) { try ГраницаЦели.наблюдать(корень: корень.path, область: область) }
    } else {
        try FileManager.default.createSymbolicLink(atPath: прежний.path, withDestinationPath: сохранённый.path)
        #expect(throws: ОтказЖурнала.путь) { try ГраницаЦели.наблюдать(корень: корень.path, область: "iskhodniki/zhurnal") }
    }
}

@Test func замокОтдельногоДескриптораОтказывает() throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let (план, вход, оператор) = try планВ(корень)
    let (каталог, _) = try ГраницаЦели.открыть(корень: корень.path, область: "iskhodniki/zhurnal")
    defer { _ = Darwin.close(каталог) }
    #expect(flock(каталог, LOCK_EX | LOCK_NB) == 0)
    #expect(throws: ОтказЖурнала.занято) { try ФайловыйАдаптер.применить(план, вход: вход, оператор: оператор, корень: корень.path) }
    #expect(flock(каталог, LOCK_UN) == 0)
}

@Test func дрейфПланаНеСкрываетсяНормализацией() throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    var вход = примерВхода()
    вход.область = "e\u{0301}"
    try FileManager.default.createDirectory(at: корень.appendingPathComponent(вход.область + "/zhurnal"), withIntermediateDirectories: true)
    let (план, данные, оператор) = try планВ(корень, вход: вход)
    var подмена = план
    подмена.путь = подмена.путь.precomposedStringWithCanonicalMapping
    #expect(подмена.путь == план.путь)
    #expect(Data(подмена.путь.utf8) != Data(план.путь.utf8))
    #expect(throws: ОтказЖурнала.дрейф) {
        try ФайловыйАдаптер.применить(подмена, вход: данные, оператор: оператор, корень: корень.path)
    }
}

func операторИсправленияТипа(_ вариант: Int) throws -> Data {
    let вход = примерВхода()
    let объект = try JSONSerialization.jsonObject(with: ПредставлениеЗапуска.байты(вход)) as! [String: Any]
    var результат: [String: Any] = [:]
    for ключ in объект.keys { результат[ключ] = ["путь", ["переменная", "вход"], ключ] }
    if вариант == 0 {
        результат["публичная"] = ["истина"]
    } else {
        результат["экземпляр"] = [
            "корень": ["путь", ["переменная", "вход"], "экземпляр", "корень"],
            "писатель": ["путь", ["переменная", "вход"], "экземпляр", "писатель"],
            "стадия": ["путь", ["переменная", "вход"], "экземпляр", "стадия"],
            "номер": 1
        ]
    }
    let определение: [String: Any] = [
        "схема": "fum.определение-оператора.1", "идентификатор": "fum.сформировать-локальную-запись", "версия": 1,
        "правила": [], "шаги": [["идентификатор": "исправить-тип", "оператор": "вычислить-JSON", "аргументы": [
            "граф": ["схема": "fuma.граф-JSON.1", "числа": "целые64-без-дробей", "переменные": [], "результат": результат]
        ]]]
    ]
    var данные = try JSONSerialization.data(withJSONObject: определение, options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes])
    данные.append(10)
    return данные
}

func входСПодменённымТипом(_ вариант: Int) throws -> Data {
    var объект = try JSONSerialization.jsonObject(with: ПредставлениеЗапуска.байты(примерВхода())) as! [String: Any]
    if вариант == 0 { объект["публичная"] = 1 }
    else {
        var экземпляр = объект["экземпляр"] as! [String: Any]
        экземпляр["номер"] = true
        объект["экземпляр"] = экземпляр
    }
    var данные = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes])
    данные.append(10)
    return данные
}

@Test(arguments: [0, 1]) func исходныйТипНеИсправляетсяОператоромПриПлане(_ вариант: Int) throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let цель = try ГраницаЦели.наблюдать(корень: корень.path, область: "iskhodniki/zhurnal")
    let оператор = try операторИсправленияТипа(вариант)
    let вход = try входСПодменённымТипом(вариант)
    #expect(throws: (any Error).self) { try ПланировщикЗаписи.построить(вход, оператор: оператор, цель: цель) }
    #expect(try FileManager.default.contentsOfDirectory(atPath: корень.appendingPathComponent("iskhodniki/zhurnal/zhurnal").path).isEmpty)
}

@Test(arguments: [0, 1]) func исходныйТипНеИсправляетсяОператоромПриПрименении(_ вариант: Int) throws {
    let корень = try временнаяЦель()
    defer { try? FileManager.default.removeItem(at: корень) }
    let цель = try ГраницаЦели.наблюдать(корень: корень.path, область: "iskhodniki/zhurnal")
    let оператор = try операторИсправленияТипа(вариант)
    let данные = try ПредставлениеЗапуска.байты(примерВхода(), читаемо: true)
    var прежнийПлан = try ПланировщикЗаписи.построить(данные, оператор: оператор, цель: цель)
    let неверныйВход = try входСПодменённымТипом(вариант)
    // Воспроизводим прежний уязвимый план без вызова планировщика на невалидном входе.
    // Оператор выдаёт тот же валидный результат; меняются хэш исходного входа и связанный хэш тела.
    прежнийПлан.хэшВхода = хэш(неверныйВход)
    var тело = try JSONDecoder().decode(ТелоЗаписи.self, from: прежнийПлан.байты)
    тело.хэшВхода = прежнийПлан.хэшВхода
    прежнийПлан.байты = try ПредставлениеЗапуска.байты(тело, читаемо: true)
    прежнийПлан.хэшСодержания = хэш(прежнийПлан.байты)
    #expect(throws: (any Error).self) {
        try ФайловыйАдаптер.применить(прежнийПлан, вход: неверныйВход, оператор: оператор, корень: корень.path)
    }
    #expect(!FileManager.default.fileExists(atPath: корень.appendingPathComponent(прежнийПлан.путь).path))
}
