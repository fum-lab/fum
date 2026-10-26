import Foundation
import Testing
@testable import МатериализацияУзлов

@Suite struct ПроверкиКомандыКаталогаВосстановления {
    @Test func пустойВызовПоказываетОграниченнуюСправку() async throws {
        let ответ = try await КомандаКаталогаВосстановления.выполнить([])
        let текст = String(decoding: ответ, as: UTF8.self)
        #expect(текст.contains("vosstanovitj-uzel"))
        #expect(текст.contains("план --вход"))
        #expect(текст.contains("применить --вход"))
    }

    @Test(arguments: [
        ["применить"], ["план", "--вход"], ["план", "--вход", "x", "--вход", "y"],
        ["план", "--вход", "x", "--план", "y"], ["план", "--команда", "git push"],
        ["применить", "--вход", "x", "--план", "y", "--force", "true"]
    ]) func неоднозначныйИлиЭффектныйArgvОтвергаетсяДоЧтенияФайлов(_ аргументы: [String]) async {
        await #expect(throws: ОтказКомандыКаталога.self) {
            try await КомандаКаталогаВосстановления.выполнить(аргументы)
        }
    }

    @Test func планБезПодключённогоHostНеРазрешаетЭффектДажеПриПравильномJSON() async throws {
        let каталог = URL.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let вход = каталог.appendingPathComponent("vkhod.json")
        let данные = try JSONEncoder().encode(запросДляКомандыКаталога())
        try данные.write(to: вход, options: [.withoutOverwriting])
        let ответ = try await КомандаКаталогаВосстановления.выполнить(["план", "--вход", вход.path])
        let план = try JSONDecoder().decode(ПланКаталогаВосстановления.self, from: ответ)
        #expect(план.проверитьИдентификатор())
        #expect(план.решения.count == 1)
        #expect(план.решения.allSatisfy { $0.состояние == .заблокировано && $0.действие == .наблюдать })
        #expect(план.решения.allSatisfy { $0.причина == .источникНаблюденийНеПодключён })
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: каталог.path)) == ["vkhod.json"])
    }

    @Test func неизвестныйКлючНельзяПревратитьВЭффектЧерезCLI() async throws {
        let каталог = URL.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let вход = каталог.appendingPathComponent("vkhod.json")
        var объект = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(запросДляКомандыКаталога())) as? [String: Any])
        объект["доверенныйКонтекст"] = true
        try JSONSerialization.data(withJSONObject: объект).write(to: вход, options: [.withoutOverwriting])
        await #expect(throws: ОтказКомандыКаталога.self) {
            try await КомандаКаталогаВосстановления.выполнить(["план", "--вход", вход.path])
        }
    }

    @Test func применениеСохраняетExactInputИЗакрываетсяБезHost() async throws {
        let каталог = URL.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let вход = каталог.appendingPathComponent("vkhod.json")
        let путьПлана = каталог.appendingPathComponent("plan.json")
        var данные = try JSONEncoder().encode(запросДляКомандыКаталога())
        try данные.write(to: вход, options: [.withoutOverwriting])
        let план = try await КомандаКаталогаВосстановления.выполнить(["план", "--вход", вход.path])
        try план.write(to: путьПлана, options: [.withoutOverwriting])
        do {
            _ = try await КомандаКаталогаВосстановления.выполнить([
                "применить", "--вход", вход.path, "--план", путьПлана.path])
            Issue.record("Применение без host не должно пройти")
        } catch let отказ as ОтказКомандыКаталога {
            #expect(отказ.код == "адаптер-сеансов-недоступен")
        }
        данные.append(10)
        try данные.write(to: вход)
        do {
            _ = try await КомандаКаталогаВосстановления.выполнить([
                "применить", "--вход", вход.path, "--план", путьПлана.path])
            Issue.record("Изменение exact input bytes должно быть отвергнуто")
        } catch let отказ as ОтказКомандыКаталога {
            #expect(отказ.код == "план-не-совпадает")
        }
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: каталог.path)) == ["vkhod.json", "plan.json"])
    }

    @Test func превышениеРазмерногоПределаОтвергается() async throws {
        let каталог = URL.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let вход = каталог.appendingPathComponent("bolshoj-vkhod.json")
        try Data(repeating: 32, count: 131_073).write(to: вход, options: [.withoutOverwriting])
        do {
            _ = try await КомандаКаталогаВосстановления.выполнить(["план", "--вход", вход.path])
            Issue.record("Превышение предела не должно разбираться как JSON")
        } catch let отказ as ОтказКомандыКаталога {
            #expect(отказ.код == "размер")
        }
    }
}

private func запросДляКомандыКаталога() -> ЗапросВосстановленияКаталога {
    let координатор = "01a127bf-38dd-7fc0-8c7b-1d245d7706a5"
    let ребёнок = "01a17752-0dbe-7a13-8a81-c63995c0dd1f"
    return ЗапросВосстановленияКаталога(
        допуск: .init(идентификатор: "проверка-команды", координатор: координатор,
            корневаяЗадача: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb",
            выбранныеДети: [ребёнок], разрешённыеНовыеЭтапы: []),
        источник: .init(коммит: String(repeating: "a", count: 40), дерево: String(repeating: "b", count: 40),
            путь: "postanovka.json", объект: String(repeating: "c", count: 40), хэш: String(repeating: "d", count: 64)),
        узлы: [.init(идентификатор: ребёнок, родитель: координатор,
            ветка: "refs/heads/codex/fixture-kataloga", коммит: String(repeating: "a", count: 40),
            дерево: String(repeating: "b", count: 40),
            целевойПуть: URL.temporaryDirectory.appendingPathComponent("fum-katalog-ne-sozdavatj").path,
            репозиторийИсточника: URL.temporaryDirectory.appendingPathComponent("fum-katalog-ne-chitatj").path,
            роль: .обычная)])
}
