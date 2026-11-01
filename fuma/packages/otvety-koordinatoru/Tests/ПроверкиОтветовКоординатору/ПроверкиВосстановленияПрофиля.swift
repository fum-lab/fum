import Foundation
import Testing
@testable import ОтветыКоординатору

struct ПроверкиВосстановленияПрофиля {
    @Test("потерянный профиль после восстановления не выбирает legacy-процедуры")
    func потеряПрофиляЗакрываетМаршрут() {
        let контекст = КонтекстВосстановленияПрофиля(физическийW: "/w", исполнитель: "node",
            наблюдённыйHEAD: String(repeating: "a", count: 40), полныйRef: "refs/heads/task",
            assignmentPin: "parent-assignment", sha256Исходника: String(repeating: "b", count: 64),
            байтовИсходника: 1, версияСостояния: 7,
            арендаДействуетДо: Date(timeIntervalSince1970: 2_000), момент: Date(timeIntervalSince1970: 1_000))

        let результат = ВосстановлениеСохранённогоПрофиля.восстановить(nil,
            ожидаемыйSHA256: ВосстановлениеСохранённогоПрофиля.sha256ЗакреплённогоСнимка,
            текущийКонтекст: контекст)

        #expect(результат.статус == .неизвестно)
        #expect(результат.профиль == nil)
        #expect(результат.выбранныеПроцедуры.isEmpty)
    }

    @Test("изменённый профиль не принимается даже при переданном caller hash")
    func изменённыйПрофильЗакрываетМаршрут() throws {
        let raw = Data("legacy router hint".utf8)
        let конверт = try JSONEncoder().encode(КонвертТеста(байты: raw))
        let контекст = КонтекстВосстановленияПрофиля(физическийW: "/w", исполнитель: "node",
            наблюдённыйHEAD: String(repeating: "a", count: 40), полныйRef: "refs/heads/task",
            assignmentPin: "parent-assignment", sha256Исходника: String(repeating: "b", count: 64),
            байтовИсходника: 1, версияСостояния: 7,
            арендаДействуетДо: Date(timeIntervalSince1970: 2_000), момент: Date(timeIntervalSince1970: 1_000))

        let результат = ВосстановлениеСохранённогоПрофиля.восстановить(конверт,
            ожидаемыйSHA256: ВосстановлениеСохранённогоПрофиля.sha256ЗакреплённогоСнимка,
            текущийКонтекст: контекст)

        #expect(результат.статус == .неизвестно)
        #expect(результат.профиль == nil)
        #expect(результат.выбранныеПроцедуры.isEmpty)
    }

    @Test("сохранение отвергает любые байты вне закреплённого исходного снимка")
    func сохранениеТребуетТочныйСнимок() {
        do {
            try ВосстановлениеСохранённогоПрофиля.сохранитьТочныйСнимок(
                Data("profile impostor".utf8), контекст: КонтекстВосстановленияПрофиля(
                    физическийW: "/w", исполнитель: "node", наблюдённыйHEAD: String(repeating: "a", count: 40),
                    полныйRef: "refs/heads/task", assignmentPin: "parent-assignment",
                    sha256Исходника: String(repeating: "b", count: 64), байтовИсходника: 1,
                    версияСостояния: 7, арендаДействуетДо: Date(timeIntervalSince1970: 2_000),
                    момент: Date(timeIntervalSince1970: 1_000)))
            Issue.record("Сохранён произвольный профиль")
        } catch let ошибка as ОшибкаСохранённогоПрофиля {
            #expect(ошибка == .hashЗакреплённогоСнимкаНеСовпадает)
        } catch {
            Issue.record("Неожиданная ошибка сохранения профиля: \(error)")
        }
    }

    @Test("исключение Python запрещает планировать обычное редактирование JSON интерпретатором")
    func обычныйJSONЧерезИнтерпретаторИсключён() {
        let исключенияВосстановления = ВосстановлениеСохранённогоПрофиля.исключённыеПроцедурыПрофиля
        let профиль = восстановленныйПрофиль(исключения: исключенияВосстановления)
        let профильБезЯвногоPython = восстановленныйПрофиль(исключения: [
            .legacyRouter, .legacyJournalDispatch, .произвольныйShellИлиProcess,
            .новыйRunnerИлиChecker, .compilerTestRuntimeИлиSourceWriteStart
        ])

        #expect(исключенияВосстановления.contains(.python))
        #expect(профиль.оценить(.обычноеРедактированиеJSONЧерезИнтерпретатор) == .исключена)
        #expect(профиль.оценить(.legacyRouter) == .исключена)
        #expect(профильБезЯвногоPython.оценить(.обычноеРедактированиеJSONЧерезИнтерпретатор) == .неизвестно)
    }

    private func восстановленныйПрофиль(исключения: Set<ИсключённаяПроцедураПрофиля>) -> ВосстановленныйПрофиль {
        ВосстановленныйПрофиль(сырыеБайты: Data("synthetic restored profile".utf8),
            sha256: String(repeating: "a", count: 64), идентификатор: "synthetic",
            версия: "routine-delivery-profile.1", физическийW: "/w", исполнитель: "writer",
            наблюдённыйHEAD: String(repeating: "b", count: 40), полныйRef: "refs/heads/task",
            assignmentPin: "assignment", sha256Исходника: String(repeating: "c", count: 64),
            байтовИсходника: 1, версияСостояния: 1,
            арендаДействуетДо: Date(timeIntervalSince1970: 2_000), разрешённыеПути: [],
            исключения: исключения, проверяющийИзвестен: false)
    }
}

private struct КонвертТеста: Encodable {
    let байты: Data
}
