import Foundation
import Darwin
import CryptoKit
import CoreFoundation

func хэшОбмена(_ данные: Data) -> String { SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined() }

func физическийПутьБиблиотеки(_ путь: String) throws -> URL {
    guard путь.hasPrefix("/"), !путь.utf8.contains(0) else { throw ОшибкаКлиента.доступЗапрещён("Нужен абсолютный физический путь библиотеки") }
    let адрес = URL(fileURLWithPath: путь)
    guard адрес.path == путь else { throw ОшибкаКлиента.доступЗапрещён("Путь библиотеки был нормализован") }
    return адрес
}

/// Свидетельство выбранных файлов на диске. Не удостоверяет загруженный image,
/// транзитивные библиотеки, отсутствие TOCTOU или исполнение производителя receipt.
public struct ПривязкаБиблиотеки: Codable, Equatable, Sendable {
    public let происхождение: String
    public let библиотекаШа256: String?
    public let размерБиблиотеки: Int?
    public let квитанцияШа256: String
    public let сыраяКвитанция: Data
    public var идентификатор: String {
        var данные = Data("\(происхождение)\0\(библиотекаШа256 ?? "")\0\(размерБиблиотеки ?? 0)\0\(квитанцияШа256)\0".utf8)
        данные.append(сыраяКвитанция)
        return хэшОбмена(данные)
    }

    static let синтетическийТранспорт = ПривязкаБиблиотеки(происхождение: "синтетический-транспорт",
        библиотекаШа256: nil, размерБиблиотеки: nil, квитанцияШа256: хэшОбмена(Data()), сыраяКвитанция: Data())

    public static func проверить(библиотека: URL, квитанция: URL, ожидаемыйШа256: String) throws -> Self {
        let сырьё = try прочитатьВыбранныйФайл(квитанция, предел: 1024 * 1024).данные!
        return try проверить(библиотека: библиотека, сыраяКвитанция: сырьё, ожидаемыйШа256: ожидаемыйШа256)
    }

    static func проверить(библиотека: URL, сыраяКвитанция: Data, ожидаемыйШа256: String) throws -> Self {
        guard корректныйХэш(ожидаемыйШа256), хэшОбмена(сыраяКвитанция) == ожидаемыйШа256 else {
            throw ОшибкаКлиента.доступЗапрещён("Не совпал независимо выбранный SHA квитанции")
        }
        var сканер = СканерКлючей(байты: Array(сыраяКвитанция))
        try сканер.проверить()
        guard let поля = try JSONSerialization.jsonObject(with: сыраяКвитанция) as? [String: Any] else {
            throw ОшибкаКлиента.требуетсяРазбор
        }
        let схема = try строка(поля, "схема")
        let выбранный = try строка(поля, "библиотекаSha256")
        guard корректныйХэш(выбранный), try строка(поля, "исход") == "успех" else { throw ОшибкаКлиента.требуетсяРазбор }
        var размер: Int
        switch схема {
        case "fum.синтетическая-c-библиотека.1":
            try ключи(поля, ["схема", "исход", "исходникSha256", "компиляторSha256", "библиотекаSha256", "библиотекаBytes", "архитектуры", "символы"])
            guard корректныйХэш(try строка(поля, "исходникSha256")), корректныйХэш(try строка(поля, "компиляторSha256")) else { throw ОшибкаКлиента.требуетсяРазбор }
            try проверитьБинарныйИнтерфейс(поля)
            размер = try целое(поля, "библиотекаBytes")
        case "fum.сборка-tdlib.1":
            try ключи(поля, ["схема", "исход", "коммит", "профиль", "повторений", "библиотекаSha256", "байтыСовпали", "проходы"])
            guard try строка(поля, "коммит") == коммитБиблиотеки, try целое(поля, "повторений") == 2,
                  let совпали = поля["байтыСовпали"] as? NSNumber, CFGetTypeID(совпали) == CFBooleanGetTypeID(), совпали.boolValue,
                  let проходы = поля["проходы"] as? [[String: Any]], проходы.count == 2,
                  let профиль = поля["профиль"] as? [String: Any] else { throw ОшибкаКлиента.требуетсяРазбор }
            try проверитьПрофиль(профиль)
            размер = try целое(проходы[0], "библиотекаBytes")
            for (номер, проход) in проходы.enumerated() {
                try ключи(проход, ["проход", "коммит", "дерево", "архивSha256", "настройкаСекунд", "сборкаСекунд", "установкаСекунд", "библиотекаSha256", "библиотекаBytes", "архитектуры", "символы", "зависимости"])
                guard try целое(проход, "проход") == номер + 1, try строка(проход, "коммит") == коммитБиблиотеки,
                      try строка(проход, "дерево") == деревоБиблиотеки, try строка(проход, "библиотекаSha256") == выбранный,
                      try целое(проход, "библиотекаBytes") == размер,
                      корректныйХэш(try строка(проход, "архивSha256")),
                      try строка(проход, "архивSha256") == строка(проходы[0], "архивSha256"),
                      let зависимости = проход["зависимости"] as? [String], зависимости == проходы[0]["зависимости"] as? [String],
                      Set(зависимости).count == зависимости.count else { throw ОшибкаКлиента.требуетсяРазбор }
                for зависимость in зависимости {
                    let части = зависимость.split(separator: "/", omittingEmptySubsequences: false)
                    guard части.count == 2, ["system", "dynamic", "openssl"].contains(String(части[0])), !части[1].isEmpty else { throw ОшибкаКлиента.требуетсяРазбор }
                }
                for поле in ["настройкаСекунд", "сборкаСекунд", "установкаСекунд"] {
                    guard let число = проход[поле] as? NSNumber, CFGetTypeID(число) != CFBooleanGetTypeID(), число.doubleValue.isFinite, число.doubleValue >= 0 else { throw ОшибкаКлиента.требуетсяРазбор }
                }
                try проверитьБинарныйИнтерфейс(проход)
            }
        default: throw ОшибкаКлиента.доступЗапрещён("Неизвестное происхождение библиотеки")
        }
        let файл = try прочитатьВыбранныйФайл(библиотека)
        guard размер > 0, файл.размер == размер, файл.хэш == выбранный else { throw ОшибкаКлиента.доступЗапрещён("Фактическая библиотека не совпала с квитанцией") }
        return Self(происхождение: схема, библиотекаШа256: выбранный, размерБиблиотеки: размер,
            квитанцияШа256: ожидаемыйШа256, сыраяКвитанция: сыраяКвитанция)
    }
}

private let коммитБиблиотеки = "d1085f9cebc5a62379991ae1652673954f229c1f"
private let деревоБиблиотеки = "fdcb62d1739c348ede23f87427a82d6e345ca805"
private func корректныйХэш(_ значение: String) -> Bool { значение.count == 64 && значение.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) } }
private func ключи(_ поля: [String: Any], _ ожидаемые: Set<String>) throws {
    guard Set(поля.keys) == ожидаемые else { throw ОшибкаКлиента.требуетсяРазбор }
}
private func строка(_ поля: [String: Any], _ имя: String) throws -> String {
    guard let значение = поля[имя] as? String, !значение.isEmpty else { throw ОшибкаКлиента.требуетсяРазбор }; return значение
}
private func целое(_ поля: [String: Any], _ имя: String) throws -> Int {
    guard let число = поля[имя] as? NSNumber, CFGetTypeID(число) != CFBooleanGetTypeID(),
          число.doubleValue.isFinite, число.doubleValue >= 0, число.doubleValue < Double(Int.max),
          число.doubleValue == Double(число.intValue) else { throw ОшибкаКлиента.требуетсяРазбор }; return число.intValue
}
private func проверитьБинарныйИнтерфейс(_ поля: [String: Any]) throws {
    guard поля["архитектуры"] as? [String] == ["arm64"], поля["символы"] as? [String] == ["td_create_client_id", "td_send", "td_receive"] else { throw ОшибкаКлиента.требуетсяРазбор }
}
private func проверитьПрофиль(_ поля: [String: Any]) throws {
    try ключи(поля, ["macOS", "архитектура", "xcode", "сборкаXcode", "sdk", "сборкаSdk", "clang", "cmake", "make", "gperf", "openssl", "sha256Инструментов"])
    let версии = ["macOS": "27.0", "архитектура": "arm64", "xcode": "Xcode 27.0", "сборкаXcode": "27A266a", "sdk": "27.0", "сборкаSdk": "26A425", "clang": "Apple clang version 21.0.0", "cmake": "cmake version 4.4.3", "make": "GNU Make 3.81", "gperf": "GNU gperf 3.0.3", "openssl": "OpenSSL 3.6.4"]
    for (имя, ожидаемое) in версии {
        let факт = try строка(поля, имя)
        guard факт == ожидаемое || факт.hasPrefix(ожидаемое + " ") || факт.hasPrefix(ожидаемое + "\n") else { throw ОшибкаКлиента.требуетсяРазбор }
    }
    let хэши = ["clang": "1590ac950a3d627817d09ade5cb60b2115f17a72182a3141e010b4bcc482a0c9", "clang++": "1590ac950a3d627817d09ade5cb60b2115f17a72182a3141e010b4bcc482a0c9", "cmake": "01bb5214684f5390e96e0d6aef7aafd7415b77ecbcfd59f6b55b018d8de0d9a2", "make": "34129c71a01a74f7f3b2443521519b2e5447553fa187f5fcafaaf8c42cc192e2", "gperf": "34129c71a01a74f7f3b2443521519b2e5447553fa187f5fcafaaf8c42cc192e2", "openssl": "67a83dd6d6d747d50c5d296dffb23e32bae9a2c588c93ae2d77e4c607b455c72", "zlibTbd": "7326dfca9e65f8d74c70ec28496074b8285cecbbfde4172701fe66980a86275f"]
    guard поля["sha256Инструментов"] as? [String: String] == хэши else { throw ОшибкаКлиента.требуетсяРазбор }
}

/// Чтение одного регулярного файла через удерживаемый fd с проверкой пути и метаданных.
/// Для dylib хранится только SHA; небольшая квитанция возвращается побайтно.
private func прочитатьВыбранныйФайл(_ путь: URL, предел: Int? = nil) throws -> (хэш: String, размер: Int, данные: Data?) {
    guard путь.isFileURL, путь.path.hasPrefix("/"), !путь.path.utf8.contains(0),
          let физический = realpath(путь.path, nil) else { throw ОшибкаКлиента.доступЗапрещён("Нужен физический путь выбранного файла") }
    defer { free(физический) }
    guard путь.path == String(cString: физический) else { throw ОшибкаКлиента.доступЗапрещён("Нужен физический путь выбранного файла") }
    let файл = Darwin.open(путь.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
    guard файл >= 0 else { throw ОшибкаКлиента.библиотекаНедоступна }
    defer { Darwin.close(файл) }
    var до = stat(), после = stat(), имя = stat()
    guard fstat(файл, &до) == 0, до.st_mode & S_IFMT == S_IFREG, до.st_size > 0,
          до.st_size <= 512 * 1024 * 1024, предел == nil || до.st_size <= предел! else { throw ОшибкаКлиента.превышенПредел }
    var хэш = SHA256(), сохранённое = Data(), смещение = 0
    var буфер = [UInt8](repeating: 0, count: 1024 * 1024)
    while смещение < до.st_size {
        let число = pread(файл, &буфер, min(буфер.count, Int(до.st_size) - смещение), off_t(смещение))
        if число < 0, errno == EINTR { continue }
        guard число > 0 else { throw ОшибкаКлиента.требуетсяРазбор }
        let часть = Data(буфер.prefix(число)); хэш.update(data: часть)
        if предел != nil { сохранённое.append(часть) }
        смещение += число
    }
    var лишний: UInt8 = 0
    guard pread(файл, &лишний, 1, off_t(смещение)) == 0, fstat(файл, &после) == 0, lstat(путь.path, &имя) == 0,
          до.st_dev == после.st_dev, до.st_ino == после.st_ino, до.st_size == после.st_size,
          до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec, до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec,
          до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec, до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec,
          имя.st_dev == после.st_dev, имя.st_ino == после.st_ino, имя.st_mode & S_IFMT == S_IFREG else { throw ОшибкаКлиента.требуетсяРазбор }
    return (хэш.finalize().map { String(format: "%02x", $0) }.joined(), смещение, предел == nil ? nil : сохранённое)
}

/// JSONSerialization проверяет грамматику; этот проход отдельно запрещает повторные ключи,
/// включая разные escaped-написания одного ключа. Глубина и размер ограничены.
private struct СканерКлючей {
    let байты: [UInt8]
    var позиция = 0
    mutating func пробелы() { while позиция < байты.count, [9, 10, 13, 32].contains(байты[позиция]) { позиция += 1 } }
    mutating func символ(_ знак: UInt8) throws { пробелы(); guard позиция < байты.count, байты[позиция] == знак else { throw ОшибкаКлиента.требуетсяРазбор }; позиция += 1 }
    mutating func текст() throws -> String {
        пробелы(); let начало = позиция; try символ(34)
        while позиция < байты.count {
            let знак = байты[позиция]; позиция += 1
            if знак == 92 { guard позиция < байты.count else { throw ОшибкаКлиента.требуетсяРазбор }; позиция += 1 }
            else if знак == 34 { return try JSONDecoder().decode(String.self, from: Data(байты[начало..<позиция])) }
        }
        throw ОшибкаКлиента.требуетсяРазбор
    }
    mutating func значение(_ глубина: Int) throws {
        guard глубина < 64 else { throw ОшибкаКлиента.превышенПредел }
        пробелы(); guard позиция < байты.count else { throw ОшибкаКлиента.требуетсяРазбор }
        if байты[позиция] == 34 { _ = try текст(); return }
        if байты[позиция] == 123 {
            позиция += 1; пробелы(); var ключи = Set<String>()
            if позиция < байты.count, байты[позиция] == 125 { позиция += 1; return }
            while true {
                guard ключи.insert(try текст()).inserted else { throw ОшибкаКлиента.требуетсяРазбор }
                try символ(58); try значение(глубина + 1); пробелы()
                if позиция < байты.count, байты[позиция] == 125 { позиция += 1; return }
                try символ(44)
            }
        }
        if байты[позиция] == 91 {
            позиция += 1; пробелы()
            if позиция < байты.count, байты[позиция] == 93 { позиция += 1; return }
            while true {
                try значение(глубина + 1); пробелы()
                if позиция < байты.count, байты[позиция] == 93 { позиция += 1; return }
                try символ(44)
            }
        }
        let начало = позиция
        while позиция < байты.count, ![9, 10, 13, 32, 44, 93, 125].contains(байты[позиция]) { позиция += 1 }
        guard позиция > начало else { throw ОшибкаКлиента.требуетсяРазбор }
    }
    mutating func проверить() throws {
        guard !байты.isEmpty, байты.count <= 1024 * 1024 else { throw ОшибкаКлиента.превышенПредел }
        try значение(0); пробелы(); guard позиция == байты.count else { throw ОшибкаКлиента.требуетсяРазбор }
    }
}
