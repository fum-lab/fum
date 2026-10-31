import Foundation
import Testing
import Darwin
@testable import ПроверкаПарНормВетки

private let p0 = "FUM-ПРАВИЛО-000058"
private let p1 = "FUM-ПРАВИЛО-НОВОЕ-000023"
private let темаПуть = "Правила/агентов/Git-и-рабочая-сессия.md"

private func корень() -> URL {
    if let override = ProcessInfo.processInfo.environment["FUM_RULES_TEST_ROOT"] {
        return URL(fileURLWithPath: override, isDirectory: true)
    }
    return URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}
private func прочитать(_ path: String) throws -> Data {
    try Data(contentsOf: корень().appendingPathComponent(path))
}
private func текст(_ data: Data) throws -> String {
    guard let s = String(data: data, encoding: .utf8) else { throw ОшибкаПарыНорм.отказ("тест: UTF-8") }
    return s
}
private func заменитьТело(_ text: String, id: String, body: String) throws -> String {
    let re = try NSRegularExpression(pattern: #"^<!-- FUM-ПРАВИЛО: ([^\n]+) -->\n"#, options: [.anchorsMatchLines])
    let anchors = re.matches(in: text, range: NSRange(text.startIndex..., in: text))
    let selected = anchors.enumerated().filter { _, a in
        guard let r = Range(a.range(at: 1), in: text) else { return false }
        return Data(text[r].utf8) == Data(id.utf8)
    }
    guard selected.count == 1, let r = Range(selected[0].element.range, in: text) else {
        throw ОшибкаПарыНорм.отказ("тест: якорь")
    }
    let next = selected[0].offset + 1
    let end = next < anchors.count ? Range(anchors[next].range, in: text)!.lowerBound : text.endIndex
    return String(text[..<r.upperBound]) + body + "\n\n" + String(text[end...])
}
private func объект(_ data: Data) throws -> [String: Any] {
    guard let o = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw ОшибкаПарыНорм.отказ("тест: объект")
    }
    return o
}
private func данные(_ object: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
}
private func отказал(_ f: () throws -> Void) -> Bool {
    do { try f(); return false } catch { return true }
}
private struct Вход {
    var root: String
    var topic: String
    var manifest: [String: Any]

    static func текущий() throws -> Вход {
        try .init(root: текст(прочитать("AGENTS.md")), topic: текст(прочитать(темаПуть)),
                  manifest: объект(прочитать("Правила/агентов/инвентарь-правил.json")))
    }
    func запустить() throws -> РезультатПарыНорм {
        try проверитьПаруНорм(кореньТекст: root, темаТекст: topic, инвентарь: данные(manifest)) { _ in }
    }
    mutating func применить(_ имя: String) throws {
        let path = "Инструменты/fum-dekompoziciya-pravil-agentov/tests/фикстуры/" + имя
        let f = try объект(прочитать(path))
        guard let bodies = f["тела"] as? [String: String],
              let a = bodies[p0], let b = bodies[p1], let declaration = f["декларация"] as? [String: Any] else {
            throw ОшибкаПарыНорм.отказ("тест: фикстура")
        }
        root = try заменитьТело(root, id: p0, body: a)
        topic = try заменитьТело(topic, id: p1, body: b)
        manifest["ветка_состояния_узла"] = declaration
    }
}

@Test func точныеИсторическиеИНоваяПары() throws {
    var first = try Вход.текущий()
    try first.применить("профиль-ветки-состояния.json")
    #expect(try first.запустить().версия == "историческая-первая")
    var repeated = try Вход.текущий()
    try repeated.применить("профиль-повторного-состояния-узла.json")
    #expect(try repeated.запустить().версия == "историческая-повторная")
    let new = try Вход.текущий().запустить()
    #expect(new.версия == "предложенная")
    #expect(new.полныйПрофиль == "UNKNOWN")
    #expect(new.правоНаЭффект == "не определено")
}

@Test func смешанныеТелаИДекларацииОтвергаются() throws {
    var old = try Вход.текущий()
    try old.применить("профиль-ветки-состояния.json")
    let new = try Вход.текущий()
    var mixed = new
    mixed.root = old.root
    #expect(отказал { _ = try mixed.запустить() })
    mixed = new; mixed.topic = old.topic
    #expect(отказал { _ = try mixed.запустить() })
    var repeated = try Вход.текущий()
    try repeated.применить("профиль-повторного-состояния-узла.json")
    mixed = new; mixed.root = repeated.root
    #expect(отказал { _ = try mixed.запустить() })
    mixed = new; mixed.topic = repeated.topic
    #expect(отказал { _ = try mixed.запустить() })
    mixed = old; mixed.manifest["ветка_состояния_узла"] = new.manifest["ветка_состояния_узла"]
    #expect(отказал { _ = try mixed.запустить() })
    mixed = repeated; mixed.manifest["ветка_состояния_узла"] = old.manifest["ветка_состояния_узла"]
    #expect(отказал { _ = try mixed.запустить() })
    mixed = new
    mixed.topic = mixed.topic.replacingOccurrences(of: "одного писателя", with: "другого писателя")
    #expect(отказал { _ = try mixed.запустить() })
}

@Test func декларацияИМетаданныеЗакрыты() throws {
    let original = try Вход.текущий()
    var wrongSchema = original
    wrongSchema.manifest["схема"] = "неизвестная"
    #expect(отказал { _ = try wrongSchema.запустить() })
    wrongSchema.manifest["схема"] = NSNull()
    #expect(отказал { _ = try wrongSchema.запустить() })
    wrongSchema.manifest.removeValue(forKey: "схема")
    #expect(отказал { _ = try wrongSchema.запустить() })
    guard let declaration = original.manifest["ветка_состояния_узла"] as? [String: Any] else {
        throw ОшибкаПарыНорм.отказ("тест: декларация")
    }
    for key in declaration.keys {
        var changed = original
        var d = declaration; d[key] = "изменено"
        changed.manifest["ветка_состояния_узла"] = d
        #expect(отказал { _ = try changed.запустить() })
        d = declaration; d.removeValue(forKey: key)
        changed.manifest["ветка_состояния_узла"] = d
        #expect(отказал { _ = try changed.запустить() })
    }
    var extra = original
    var d = declaration; d["лишнее"] = true
    extra.manifest["ветка_состояния_узла"] = d
    #expect(отказал { _ = try extra.запустить() })
    let exact = "схема_полномочий"
    let decomposed = exact.decomposedStringWithCanonicalMapping
    guard Data(exact.utf8) != Data(decomposed.utf8), let value = declaration[exact] else {
        throw ОшибкаПарыНорм.отказ("тест: NFD")
    }
    d = declaration; d.removeValue(forKey: exact); d[decomposed] = value
    extra.manifest["ветка_состояния_узла"] = d
    #expect(отказал { _ = try extra.запустить() })
    for id in [p0, p1] {
        guard let originalRules = original.manifest["правила"] as? [[String: Any]],
              let index = originalRules.firstIndex(where: { $0["идентификатор"] as? String == id }) else {
            throw ОшибкаПарыНорм.отказ("тест: правило")
        }
        for field in ["статус", "приоритет", "назначение"] {
            var changed = original
            var rules = originalRules
            rules[index][field] = "неверно"; changed.manifest["правила"] = rules
            #expect(отказал { _ = try changed.запустить() })
        }
        for field in ["путь", "якорь", "лишнее"] {
            var changed = original
            var rules = originalRules
            guard var target = rules[index]["назначение"] as? [String: Any] else {
                throw ОшибкаПарыНорм.отказ("тест: назначение")
            }
            target[field] = "неверно"; rules[index]["назначение"] = target
            changed.manifest["правила"] = rules
            #expect(отказал { _ = try changed.запустить() })
        }
        var missing = original
        var remaining = originalRules; remaining.remove(at: index)
        missing.manifest["правила"] = remaining
        #expect(отказал { _ = try missing.запустить() })
        var duplicate = original
        var repeatedRules = originalRules; repeatedRules.append(originalRules[index])
        duplicate.manifest["правила"] = repeatedRules
        #expect(отказал { _ = try duplicate.запустить() })
    }
}

@Test func повторыJSONОтклоняются() throws {
    let input = try Вход.текущий()
    let original = try текст(данные(input.manifest))
    let duplicate = original.replacingOccurrences(of: "{", with: "{\"id\":1,\"\\u0069d\":2,", options: [], range: original.startIndex..<original.index(after: original.startIndex))
    #expect(отказал {
        _ = try проверитьПаруНорм(кореньТекст: input.root, темаТекст: input.topic,
                                  инвентарь: Data(duplicate.utf8)) { _ in }
    })
    let nested = original.replacingOccurrences(of: "\"ветка_ROOT\":", with: "\"ветка_ROOT\":\"x\",\"ветка_ROOT\":")
    #expect(отказал {
        _ = try проверитьПаруНорм(кореньТекст: input.root, темаТекст: input.topic,
                                  инвентарь: Data(nested.utf8)) { _ in }
    })
}

@Test func скрытиеИПовторЯкоряОтклоняются() throws {
    let original = try Вход.текущий()
    let marker = "<!-- FUM-ПРАВИЛО: " + p1 + " -->\n"
    for (prefix, suffix) in [("```text\n", "\n```"), ("<!--\n", "\n-->"), ("<div>\n", "\n</div>"), ("`\n", "\n`")] {
        var changed = original
        changed.topic = original.topic.replacingOccurrences(of: marker, with: prefix + marker) + suffix
        #expect(отказал { _ = try changed.запустить() })
    }
    var duplicate = original
    duplicate.topic += "\n" + marker + "- повтор\n"
    #expect(отказал { _ = try duplicate.запустить() })
    var leading = original
    let rootMarker = "<!-- FUM-ПРАВИЛО: " + p0 + " -->\n"
    leading.root = original.root.replacingOccurrences(of: rootMarker, with: rootMarker + "\n")
    #expect(отказал { _ = try leading.запустить() })
    var code = original
    code.topic = "Пример `<div hidden>` как текст.\n" + code.topic
    #expect(try code.запустить().версия == "предложенная")
    var separator = original
    separator.topic = "текст\u{2028}```text```\n" + separator.topic
    #expect(отказал { _ = try separator.запустить() })
    separator.topic = "\u{0060}\u{0060}\u{0060}\u{0301}text``\n" + original.topic
    #expect(отказал { _ = try separator.запустить() })
}

@Test func проверкаФизическогоПути() throws {
    let root = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
        .appendingPathComponent("fum-pair-test-" + UUID().uuidString, isDirectory: true)
    let fm = FileManager.default
    try fm.createDirectory(at: root.appendingPathComponent("dir"), withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: root) }
    let file = root.appendingPathComponent("dir/file")
    try Data("ok".utf8).write(to: file)
    try проверитьФизическийПуть("dir/file", корень: root)
    for bad in ["../dir/file", "/dir/file", "dir//file", "dir/./file", "dir\\file", "https://x", "Dir/file", "dir", "dir/missing"] {
        #expect(отказал { try проверитьФизическийПуть(bad, корень: root) })
    }
    try fm.createSymbolicLink(atPath: root.appendingPathComponent("link").path, withDestinationPath: "dir")
    try fm.createSymbolicLink(atPath: root.appendingPathComponent("dir/file-link").path, withDestinationPath: "file")
    #expect(отказал { try проверитьФизическийПуть("link/file", корень: root) })
    #expect(отказал { try проверитьФизическийПуть("dir/file-link", корень: root) })
}

@Test func публичнаяПроверкаСвязанаСФизическимиСценариями() throws {
    let input = try Вход.текущий()
    let base = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
        .appendingPathComponent("fum-pair-e2e-" + UUID().uuidString, isDirectory: true)
    let fm = FileManager.default
    try fm.createDirectory(at: base, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: base) }
    func записать(_ path: String, _ bytes: Data) throws {
        let full = base.path + "/" + path
        var parent = base.path
        for part in path.components(separatedBy: "/").dropLast() {
            parent += "/" + part
            guard mkdir(parent, mode_t(0o700)) == 0 || errno == EEXIST else { throw ОшибкаПарыНорм.отказ("тест: mkdir") }
        }
        let fd = open(full, O_WRONLY | O_CREAT | O_TRUNC, mode_t(0o600))
        guard fd >= 0 else { throw ОшибкаПарыНорм.отказ("тест: создать файл") }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        try handle.write(contentsOf: bytes)
        try handle.close()
    }
    try записать("AGENTS.md", Data(input.root.utf8))
    try записать(темаПуть, Data(input.topic.utf8))
    try записать("Правила/агентов/инвентарь-правил.json", данные(input.manifest))
    guard let declaration = input.manifest["ветка_состояния_узла"] as? [String: String] else {
        throw ОшибкаПарыНорм.отказ("тест: декларация")
    }
    let keys = ["проверить_полномочия", "проверить_ACT", "обновить_ожидания",
                "создать_коммит", "проверить_план", "проверить_повторный_эффект", "установить_журнал"]
    let paths = keys.compactMap { declaration[$0] }
    #expect(paths.count == 7)
    for path in paths { try записать(path, Data("не исполняется".utf8)) }
    #expect(try проверитьПаруНормВКорне(base).версия == "предложенная")
    for path in paths {
        let full = base.path + "/" + path
        guard unlink(full) == 0 else { throw ОшибкаПарыНорм.отказ("тест: unlink") }
        #expect(отказал { _ = try проверитьПаруНормВКорне(base) })
        guard symlink("/dev/null", full) == 0 else { throw ОшибкаПарыНорм.отказ("тест: symlink") }
        #expect(отказал { _ = try проверитьПаруНормВКорне(base) })
        guard unlink(full) == 0, mkdir(full, mode_t(0o700)) == 0 else { throw ОшибкаПарыНорм.отказ("тест: каталог") }
        #expect(отказал { _ = try проверитьПаруНормВКорне(base) })
        guard rmdir(full) == 0 else { throw ОшибкаПарыНорм.отказ("тест: rmdir") }
        try записать(path, Data("не исполняется".utf8))
    }
}
