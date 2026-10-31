import Foundation
import CryptoKit
import Darwin

/// Статическое распознавание пары не является допуском записи или полного профиля.
public enum ОшибкаПарыНорм: Error, Equatable, Sendable {
    case отказ(String)
}

public struct РезультатПарыНорм: Encodable, Equatable, Sendable {
    public let версия: String
    public let хэшОснования: String
    public let хэшПравила: String
    public let полныйПрофиль: String
    public let правоНаЭффект: String
}

private let основание = "FUM-ПРАВИЛО-000058"
private let правило = "FUM-ПРАВИЛО-НОВОЕ-000023"
private let тема = "Правила/агентов/Git-и-рабочая-сессия.md"
private let первыйP0 = "6c5e9441d390b2137958f2489f64af2744eea1f1fea5ddda2ef2952fcdf443cc"
private let первыйP1 = "2e03034b8fff2c9dee0964ee6767b63475780c598f911d4d61c50d94eced961c"
private let повторныйP1 = "b6207079e68c8ae57e866310a90ffcf77c168c7ef9a7c11ff122eb1154824418"
private let новыйP0 = "c853f07db29c96be3b2427bb9b771dbf90e094a85be52eb391e11fc07624cf23"
private let новыйP1 = "65483b03ee877a3b8710278731b9067b9e69ea9e47162551f2a12d83d51bbf83"

private let первичнаяДекларация: [String: String] = [
    "правило": правило,
    "корневое_основание": основание,
    "ветка": "refs/heads/fum-lab/fum",
    "ветка_ROOT": "refs/heads/fuma",
    "схема_полномочий": "fum.полномочия-ветки-состояния-узла.1",
    "схема_ACT": "fum.поручение-дочерней-контрольной-точки.2",
    "схема_входа": "fum.обновление-ожиданий-узла.2",
    "схема_назначения": "fum.назначение-писателя-ожиданий.3",
    "схема_параметров": "fum.создание-коммита.8",
    "схема_подготовки": "fum.подготовленный-коммит.10",
    "проверить_полномочия": "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/полномочия_ветки_состояния_узла.py",
    "проверить_ACT": "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обычное_поручение.py",
    "обновить_ожидания": "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/обновление_ожиданий_узла.py",
    "создать_коммит": "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/создание_коммита.py"
]
private let повторнаяДекларация: [String: String] = {
    var d = первичнаяДекларация
    d["схема_плана"] = "fum.план-журнала-писателя-состояния.2"
    d["схема_полномочий"] = "fum.полномочия-ветки-состояния-узла.3"
    d["схема_ACT"] = "fum.поручение-дочерней-контрольной-точки.3"
    d["схема_входа"] = "fum.обновление-ожиданий-узла.3"
    d["схема_назначения"] = "fum.назначение-писателя-ожиданий.4"
    d["схема_параметров"] = "fum.создание-коммита.11"
    d["схема_подготовки"] = "fum.подготовленный-коммит.13"
    d["проверить_полномочия"] = "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/полномочия_повторного_состояния_узла.py"
    d["проверить_план"] = "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверенный_повторный_план_состояния.py"
    d["проверить_повторный_эффект"] = "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/эффект_повторного_состояния_узла.py"
    d["установить_журнал"] = "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/журнал_повторного_состояния_узла.py"
    return d
}()
private let сценарии = ["проверить_полномочия", "проверить_ACT", "обновить_ожидания",
                        "создать_коммит", "проверить_план", "проверить_повторный_эффект", "установить_журнал"]

private func отказ(_ причина: String) -> ОшибкаПарыНорм { .отказ(причина) }
private func байтово(_ a: String, _ b: String) -> Bool { Data(a.utf8) == Data(b.utf8) }
private func точноеПоле(_ object: [String: Any], _ key: String) -> Any? {
    object.first { байтово($0.key, key) }?.value
}
private func sha(_ s: String) -> String {
    SHA256.hash(data: Data(s.utf8)).map { String(format: "%02x", $0) }.joined()
}

// Проверка полного JSON до Foundation-разбора: дубли сравниваются после
// декодирования escapes, включая канонически эквивалентные имена.
private struct ЗакрытыйJSON {
    let bytes: [UInt8]
    var pos = 0
    var nodes = 0

    init(_ data: Data) throws {
        guard data.count <= 4_194_304, String(data: data, encoding: .utf8) != nil else {
            throw отказ("JSON: размер или UTF-8")
        }
        bytes = Array(data)
    }
    mutating func ws() {
        while pos < bytes.count && [9, 10, 13, 32].contains(bytes[pos]) { pos += 1 }
    }
    mutating func accept(_ c: UInt8) -> Bool {
        guard pos < bytes.count, bytes[pos] == c else { return false }
        pos += 1; return true
    }
    mutating func require(_ c: UInt8) throws {
        guard accept(c) else { throw отказ("JSON: синтаксис") }
    }
    mutating func string() throws -> String {
        let start = pos
        try require(34)
        while pos < bytes.count {
            let c = bytes[pos]; pos += 1
            if c == 34 {
                guard let s = try? JSONDecoder().decode(String.self, from: Data(bytes[start..<pos])) else {
                    throw отказ("JSON: строка")
                }
                return s
            }
            guard c >= 32 else { throw отказ("JSON: управляющий байт") }
            if c == 92 {
                guard pos < bytes.count else { throw отказ("JSON: escape") }
                pos += 1
            }
        }
        throw отказ("JSON: незакрытая строка")
    }
    mutating func value(_ depth: Int) throws {
        guard depth <= 64, nodes < 100_000 else { throw отказ("JSON: предел структуры") }
        nodes += 1; ws()
        guard pos < bytes.count else { throw отказ("JSON: конец") }
        switch bytes[pos] {
        case 123:
            pos += 1; ws()
            var exact: Set<Data> = []
            var canonical: Set<String> = []
            if accept(125) { return }
            while true {
                ws(); let key = try string()
                guard exact.insert(Data(key.utf8)).inserted, canonical.insert(key).inserted else {
                    throw отказ("JSON: повтор или неоднозначная нормализация ключа")
                }
                ws(); try require(58); try value(depth + 1); ws()
                if accept(125) { break }
                try require(44)
            }
        case 91:
            pos += 1; ws()
            if accept(93) { return }
            while true {
                try value(depth + 1); ws()
                if accept(93) { break }
                try require(44)
            }
        case 34:
            _ = try string()
        default:
            let start = pos
            while pos < bytes.count && ![9, 10, 13, 32, 44, 93, 125].contains(bytes[pos]) { pos += 1 }
            guard pos > start, (try? JSONSerialization.jsonObject(with: Data(bytes[start..<pos]), options: [.fragmentsAllowed])) != nil else {
                throw отказ("JSON: значение")
            }
        }
    }
    mutating func check() throws {
        try value(0); ws()
        guard pos == bytes.count else { throw отказ("JSON: лишние байты") }
    }
}

private func прозрачный(_ text: String) throws {
    let неподдержанныеПереносы: Set<UInt32> = [0x0b, 0x0c, 0x0d, 0x1c, 0x1d, 0x1e, 0x85, 0x2028, 0x2029]
    guard !text.unicodeScalars.contains(where: { неподдержанныеПереносы.contains($0.value) }),
          !text.contains("\\`") else { throw отказ("неподдержанный перенос или escape") }
    for line in text.components(separatedBy: "\n") {
        let chars = Array(line.utf8)
        let start = chars.drop(while: { $0 == 32 || $0 == 9 })
        if start.starts(with: [96, 96, 96]) || start.starts(with: [126, 126, 126]) { throw отказ("ограда") }
        if line.contains("<!--") || line.contains("-->") {
            guard line.hasPrefix("<!-- "), line.hasSuffix(" -->"),
                  line.components(separatedBy: "<!--").count == 2,
                  line.components(separatedBy: "-->").count == 2 else { throw отказ("HTML-комментарий") }
        }
        var visibleBytes: [UInt8] = []
        var i = 0
        while i < chars.count {
            if chars[i] != 96 { visibleBytes.append(chars[i]); i += 1; continue }
            var n = 0
            while i + n < chars.count && chars[i + n] == 96 { n += 1 }
            i += n
            var closed = false
            while i < chars.count {
                if chars[i] != 96 { i += 1; continue }
                var count = 0
                while i + count < chars.count && chars[i + count] == 96 { count += 1 }
                i += count
                if count == n { closed = true; break }
            }
            guard closed else { throw отказ("непарный или межстрочный inline-код") }
        }
        guard let visible = String(bytes: visibleBytes, encoding: .utf8) else { throw отказ("UTF-8 видимого текста") }
        let html = try NSRegularExpression(pattern: #"<(?:/?[A-Za-z]|[!?])"#)
        let range = NSRange(visible.startIndex..., in: visible)
        if html.firstMatch(in: visible, range: range) != nil {
            let comment = try NSRegularExpression(pattern: #"^<!-- [^\n]* -->$"#)
            guard comment.firstMatch(in: visible, range: range) != nil else { throw отказ("HTML-область") }
        }
    }
}

private func тело(_ text: String, _ id: String) throws -> String {
    try прозрачный(text)
    let re = try NSRegularExpression(pattern: #"^<!-- FUM-ПРАВИЛО: ([^\n]+) -->\n"#, options: [.anchorsMatchLines])
    let anchors = re.matches(in: text, range: NSRange(text.startIndex..., in: text))
    let chosen = anchors.enumerated().filter { _, a in
        guard let r = Range(a.range(at: 1), in: text) else { return false }
        return байтово(String(text[r]), id)
    }
    guard chosen.count == 1, let r = Range(chosen[0].element.range, in: text) else { throw отказ("якорь " + id) }
    let next = chosen[0].offset + 1
    let end = next < anchors.count ? Range(anchors[next].range, in: text)!.lowerBound : text.endIndex
    var body = String(text[r.upperBound..<end])
    while body.last == "\n" { body.removeLast() }
    return body
}

/// Сравнение каждого компонента с фактическим именем, запрет symlink и обычный файл.
/// Внешняя сериализация обязанностей и защита от конкурентной замены — за границей.
public func проверитьФизическийПуть(_ значение: String, корень: URL) throws {
    guard !значение.isEmpty, !значение.hasPrefix("/"), !значение.contains("\\"),
          !значение.contains("://") else { throw отказ("путь: не локальный POSIX") }
    let parts = значение.components(separatedBy: "/")
    guard parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { throw отказ("путь: компонент") }
    let base = корень.standardizedFileURL
    guard base.isFileURL, байтово(base.path, base.resolvingSymlinksInPath().path) else { throw отказ("корень содержит symlink") }
    var url = base
    for component in parts {
        let names = try FileManager.default.contentsOfDirectory(atPath: url.path)
        guard names.contains(where: { байтово($0, component) }) else { throw отказ("путь: имя или регистр: " + component) }
        url.appendPathComponent(component)
        var st = stat()
        guard lstat(url.path, &st) == 0, (st.st_mode & mode_t(S_IFMT)) != mode_t(S_IFLNK) else { throw отказ("путь: отсутствует или symlink") }
    }
    var st = stat()
    guard lstat(url.path, &st) == 0, (st.st_mode & mode_t(S_IFMT)) == mode_t(S_IFREG) else { throw отказ("путь: не обычный файл") }
}

/// Не запускает сценарии и не утверждает, что выполнен ROOT JSONL.
func проверитьПаруНорм(
    кореньТекст: String, темаТекст: String, инвентарь: Data,
    проверитьПуть: (String) throws -> Void
) throws -> РезультатПарыНорм {
    guard кореньТекст.utf8.count <= 1_048_576, темаТекст.utf8.count <= 1_048_576 else {
        throw отказ("текст: предел байтов")
    }
    var scanner = try ЗакрытыйJSON(инвентарь); try scanner.check()
    guard let m = try JSONSerialization.jsonObject(with: инвентарь) as? [String: Any],
          let schema = точноеПоле(m, "схема") as? String, байтово(schema, "fum.декомпозиция-правил-агентов.1"),
          let rules = точноеПоле(m, "правила") as? [[String: Any]] else { throw отказ("инвентарь: схема") }
    var byID: [Data: [String: Any]] = [:]
    for r in rules {
        guard let id = точноеПоле(r, "идентификатор") as? String, !id.isEmpty,
              byID.updateValue(r, forKey: Data(id.utf8)) == nil else { throw отказ("повтор или отсутствие ID") }
    }
    func metadata(_ id: String, _ priority: String, _ path: String) throws {
        guard let r = byID[Data(id.utf8)], let status = точноеПоле(r, "статус") as? String, байтово(status, "действует"),
              let p = точноеПоле(r, "приоритет") as? String, байтово(p, priority),
              let target = точноеПоле(r, "назначение") as? [String: Any], target.count == 2,
              let tpath = точноеПоле(target, "путь") as? String, байтово(tpath, path),
              let anchor = точноеПоле(target, "якорь") as? String, байтово(anchor, id) else { throw отказ("метаданные " + id) }
    }
    try metadata(основание, "P0-ядро", "AGENTS.md")
    try metadata(правило, "P1-сессия", тема)
    let h0 = sha(try тело(кореньТекст, основание))
    let h1 = sha(try тело(темаТекст, правило))
    let expected: [String: String]
    let version: String
    switch (h0, h1) {
    case (первыйP0, первыйP1): expected = первичнаяДекларация; version = "историческая-первая"
    case (первыйP0, повторныйP1): expected = повторнаяДекларация; version = "историческая-повторная"
    case (новыйP0, новыйP1): expected = повторнаяДекларация; version = "предложенная"
    default: throw отказ("смешанная или неизвестная пара")
    }
    guard let actual = точноеПоле(m, "ветка_состояния_узла") as? [String: Any], actual.count == expected.count else {
        throw отказ("отсутствует или изменена декларация")
    }
    for (key, value) in expected {
        guard let actualValue = точноеПоле(actual, key) as? String, байтово(actualValue, value) else { throw отказ("декларация: " + key) }
    }
    for key in сценарии {
        if let path = expected[key] { try проверитьПуть(path) }
    }
    return РезультатПарыНорм(версия: version, хэшОснования: h0, хэшПравила: h1,
                              полныйПрофиль: "UNKNOWN", правоНаЭффект: "не определено")
}

private func ограниченноеЧтение(_ url: URL, предел: Int) throws -> Data {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var result = Data()
    while result.count <= предел {
        guard let chunk = try handle.read(upToCount: min(65_536, предел + 1 - result.count)), !chunk.isEmpty else { break }
        result.append(chunk)
    }
    guard result.count <= предел else { throw отказ("файл: предел байтов") }
    return result
}

public func проверитьПаруНормВКорне(_ root: URL) throws -> РезультатПарыНорм {
    let paths = ["AGENTS.md", тема, "Правила/агентов/инвентарь-правил.json"]
    for p in paths { try проверитьФизическийПуть(p, корень: root) }
    guard let a = String(data: try ограниченноеЧтение(root.appendingPathComponent(paths[0]), предел: 1_048_576), encoding: .utf8),
          let b = String(data: try ограниченноеЧтение(root.appendingPathComponent(paths[1]), предел: 1_048_576), encoding: .utf8) else { throw отказ("текст: UTF-8") }
    let data = try ограниченноеЧтение(root.appendingPathComponent(paths[2]), предел: 4_194_304)
    return try проверитьПаруНорм(кореньТекст: a, темаТекст: b, инвентарь: data) {
        try проверитьФизическийПуть($0, корень: root)
    }
}
