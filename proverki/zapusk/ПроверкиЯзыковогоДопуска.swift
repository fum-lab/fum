import Foundation
import Testing
@testable import ОсноваЗапуска

@Suite("Языковой допуск изменяемого Swift")
struct ПроверкиЯзыковогоДопуска {
    @Test("Новое латинское собственное объявление отвергается")
    func латинскоеОбъявление() throws {
        let нарушения = try ПроверкаЯзыкаСвифта.проверить(
            текст: "func oldName() {}", путь: "исходники/пример.swift")
        #expect(нарушения.contains { $0.имя == "oldName" })
    }

    @Test("Русский алфавит, цифры и канонически разложенная ё принимаются",
          arguments: ["Отчёт", "отчёт_2", "е\u{0308}мкость", "сохранитьДанные"])
    func русскоеИмя(_ имя: String) throws {
        #expect(try ПроверкаЯзыкаСвифта.проверить(
            текст: "struct \(имя) {}", путь: "пример.swift").isEmpty)
    }

    @Test("Чужая кириллица и смешанные алфавиты не становятся русскими",
          arguments: ["імя", "имяЇ", "имяѣ", "имяґ", "имяA", "имяα", "名称"])
    func чужойАлфавит(_ имя: String) throws {
        #expect(try ПроверкаЯзыкаСвифта.проверить(
            текст: "let \(имя) = 1", путь: "пример.swift").contains { $0.имя == имя })
    }

    @Test("Конечный словарь обязательной ё различает отчёт и отчет")
    func обязательнаяЁ() throws {
        #expect(try ПроверкаЯзыкаСвифта.проверить(
            текст: "func прочитатьОтчет() {}", путь: "пример.swift").count == 1)
        #expect(try ПроверкаЯзыкаСвифта.проверить(
            текст: "func прочитатьОтчёт() {}", путь: "пример.swift").isEmpty)
        #expect(try ПроверкаЯзыкаСвифта.проверить(
            текст: "let все = 1", путь: "пример.swift").isEmpty)
    }

    @Test("Строки, вложенные комментарии и RAW не объявляют имён")
    func дословныеОбласти() throws {
        let текст = ####"""
        // func latinComment() {}
        /* struct Outer { /* let inner = 0 */ } */
        let строка = "func latinString() {}"
        let сырая = #"let rawName = \"содержимое\""#
        let ещёСырая = ##"func rawAgain() { \#(неИнтерполяция) }"##
        let многострочная = """
          class Multiline {}
          """
        let экранированная = "\" func escapedName() {}"
        """####
        #expect(try ПроверкаЯзыкаСвифта.проверить(текст: текст, путь: "пример.swift").isEmpty)
    }

    @Test("Backtick не скрывает собственное латинское имя")
    func экранированноеИмя() throws {
        #expect(try ПроверкаЯзыкаСвифта.проверить(
            текст: "func `latinName`() {}", путь: "пример.swift").count == 1)
    }

    @Test("Slash и незавершённые формы требуют отдельного синтаксического покрытия",
          arguments: ["let число = 6 / 2", "let шаблон = /func Latin/", "/* хвост", "let имя = \"хвост",
            "let строка = \"текст\nfunc oldName() {}\n\"",
            "let строка = \"текст\rfunc oldName() {}\r\"",
            "let строка = #\"текст\nfunc oldName() {}\n\"#",
            "let строка = #\"текст\rfunc oldName() {}\r\"#"])
    func неподдержанныйВвод(_ текст: String) {
        #expect(throws: (any Error).self) {
            try ПроверкаЯзыкаСвифта.проверить(текст: текст, путь: "пример.swift")
        }
    }

    @Test("Внешнее имя допускается только точной записью с причиной и источником")
    func точноеИсключение() throws {
        let исключение = ИсключениеЯзыковогоДопуска(путь: "адаптер.swift", вид: "func",
            имя: "encode", причина: "Точное требование внешнего протокола Encodable",
            источник: "https://developer.apple.com/documentation/swift/encodable/encode(to:)")
        #expect(try ПроверкаЯзыкаСвифта.проверить(текст: "func encode() {}",
            путь: "адаптер.swift", исключения: [исключение]).isEmpty)
        for пример in [("сосед.swift", "func encode() {}"), ("адаптер.swift", "func encoder() {}"),
                       ("адаптер.swift", "let encode = 0")] {
            #expect(try ПроверкаЯзыкаСвифта.проверить(текст: пример.1,
                путь: пример.0, исключения: [исключение]).count == 1)
        }
        let пустаяПричина = ИсключениеЯзыковогоДопуска(путь: "адаптер.swift", вид: "func",
            имя: "encode", причина: " ", источник: "источник")
        #expect(try ПроверкаЯзыкаСвифта.проверить(текст: "func encode() {}",
            путь: "адаптер.swift", исключения: [пустаяПричина]).count == 1)
    }

    @Test("Неразобранное объявление не выдаёт пустой успешный результат", arguments: [
        "actor Old {}", "enum Русское { case oldName }", "func русское(oldName: Int) {}",
        "let (oldName, русское) = (1, 2)", "let русское = 1, oldName = 2",
        "func русское<T>() {}", "let русское = { oldName in oldName }",
        "for oldName in [] {}", "func 🐈() {}",
    ])
    func сложноеОбъявление(_ текст: String) throws {
        do {
            let нарушения = try ПроверкаЯзыкаСвифта.проверить(текст: текст, путь: "пример.swift")
            #expect(!нарушения.isEmpty)
        } catch is ОтказЯзыковогоДопуска {
            // Явный unsupported закрывает допуск; это не успешное покрытие синтаксиса.
        }
    }

    @Test("Unicode continuation и второе raw-case не дают silent pass", arguments: [
        "func имя\u{200d}() {}", "let имя\u{203f} = 1",
        "enum Русское: Int { case русский = 1, oldName = 2 }",
    ])
    func границаИдентификатора(_ текст: String) throws {
        do {
            #expect(try !ПроверкаЯзыкаСвифта.проверить(текст: текст, путь: "пример.swift").isEmpty)
        } catch is ОтказЯзыковогоДопуска { }
    }

    @Test("Обязательная ё не теряется в uppercase-группе", arguments: ["ОТЧЕТ", "прочитатьОТЧЕТ"])
    func прописнаяЁ(_ имя: String) throws {
        #expect(try ПроверкаЯзыкаСвифта.проверить(
            текст: "func \(имя)() {}", путь: "пример.swift").count == 1)
    }

    @Test("LF, CR и CRLF дают одну следующую Swift-строку", arguments: ["\n", "\r", "\r\n"])
    func переводыСтрок(_ перевод: String) throws {
        let нарушения = try ПроверкаЯзыкаСвифта.проверить(
            текст: "// комментарий" + перевод + "func oldName() {}" + перевод, путь: "пример.swift")
        #expect(нарушения.map(\.имя) == ["oldName"])
        #expect(нарушения.first?.строка == 2)
    }

    @Test("Произвольный регистр не обходит конечный корень отчёт", arguments: ["оТчет", "отЧет"])
    func смешанныйРегистрЁ(_ имя: String) throws {
        #expect(try ПроверкаЯзыкаСвифта.проверить(
            текст: "func \(имя)() {}", путь: "пример.swift").count == 1)
    }

    @Test("CRLF в patch разделяется по байтам Git")
    func строкиПатча() throws {
        #expect(try ИзменённыеСтроки.прочитать(
            Data("@@ -1,0 +2,2 @@\n+func отчёт() {}\r\n+func ещё() {}\r\n".utf8), всегоСтрок: 3) == [2, 3])
    }

    @Test("Реальная сигнатура внешнего Codable доступна в закреплённом owner-context")
    func внешнийКонтракт() throws {
        let корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let путь = "iskhodniki/zapusk/ВнешнийКонтракт.swift"
        let текст = try String(contentsOf: корень.appendingPathComponent(путь), encoding: .utf8)
        #expect(try ПроверкаЯзыкаСвифта.проверить(текст: текст,
            путь: путь).isEmpty)
        #expect(try !ПроверкаЯзыкаСвифта.проверить(текст: текст,
            путь: "сосед.swift").isEmpty)
        #expect(throws: ОтказЧитателяЯзыка.политика) {
            try ПроверкаЯзыкаСвифта.проверить(
                текст: текст.replacingOccurrences(of: "ИсточникВнешнегоКонтракта", with: "ДругойИсточник"), путь: путь)
        }
        #expect(throws: ОтказЧитателяЯзыка.политика) {
            try ПроверкаЯзыкаСвифта.проверить(
                текст: текст.replacingOccurrences(of: "encode", with: "encoder"), путь: путь)
        }
    }

    @Test("Необходимые формы собственного staged consumer действительно поддержаны", arguments: [
        "func русское<Значение: Encodable>(_ значение: Значение) {}",
        "let данные = исходные.filter { нарушение in нарушение.имя }",
        "let данные = исходные.merge(другие) { _, новое in новое }",
        "for (путь, ожидаемый) in снимки {}",
        "for await элемент in поток {}",
        "for try await (ключ, значение) in поток {}",
        "let имя = текст.trimmingCharacters(in: .whitespacesAndNewlines)",
        "guard let размер = Int(текст), размер >= 0 else { return }",
        "guard let прежние = данные(), текущие == прежние else { return }",
        #"let строка = "\(1)""#,
    ])
    func собственныеФормы(_ текст: String) throws {
        #expect(try ПроверкаЯзыкаСвифта.проверить(текст: текст, путь: "пример.swift").isEmpty)
    }

    @Test("Объявление внутри активной интерполяции проверяется")
    func интерполяцияСОбъявлением() throws {
        let текст = #"let строка = "\({ let oldName = 1; return oldName }())""#
        #expect(try ПроверкаЯзыкаСвифта.проверить(текст: текст,
            путь: "пример.swift").map(\.имя) == ["oldName"])
    }

    @Test("Дополнительные pattern/accessor/closure формы не пропускают латиницу", arguments: [
        "let русское = 1, (oldName, ещё) = (2, 3)",
        "let русское = внешнее.`case`, oldName = 1",
        "var свойство: Int { get { 0 } set(oldName) {} }",
        "var свойство = 0 { willSet(oldName) {} }",
        "var свойство = 0 { didSet(oldName) {} }",
        "let значение = { (русское: () -> Int, oldName: Int) in oldName }",
        "let значение = { [oldName = { () -> Int in 1 }()] in oldName }",
        "func СОХРАНЕННЫЙФАЙЛ() {}", "func ЕЩЕРАЗ() {}",
        "func русский() -> (oldName: Int, ещё: Int) { (1, 2) }",
        "typealias Русский = (oldName: Int, ещё: Int)",
        "let русское = (oldName: 1, ещё: 2)",
        "let русское = вызов(снаружи: (oldName: 1, ещё: 2))",
    ])
    func остаточныеОпасныеФормы(_ текст: String) throws {
        do {
            #expect(try !ПроверкаЯзыкаСвифта.проверить(текст: текст, путь: "пример.swift").isEmpty)
        } catch is ОтказЯзыковогоДопуска { }
    }
}
