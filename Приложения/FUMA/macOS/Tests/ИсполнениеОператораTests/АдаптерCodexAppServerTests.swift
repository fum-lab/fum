import Foundation
import Testing
@testable import ИсполнениеОператора

private actor ЗаписьТранспорта: ТранспортCodexAppServer {
    private var очередь: [Data]
    private(set) var отправлено: [Data] = []

    init(_ очередь: [String]) { self.очередь = очередь.map { Data($0.utf8) } }
    func отправить(_ байты: Data) async throws { отправлено.append(байты) }
    func принять() async throws -> Data? { очередь.isEmpty ? nil : очередь.removeFirst() }
    func закрыть() async {}
    func снимок() -> [Data] { отправлено }
}

private actor ЗаписьСырья: ЖурналСырогоПотокаCodexAppServer {
    private(set) var записи: [(Data, НаправлениеПотокаCodexAppServer, Int, UUID?)] = []
    func сохранить(_ байты: Data, направление: НаправлениеПотокаCodexAppServer, смещение: Int, задачаFUMA: UUID?) async throws {
        записи.append((байты, направление, смещение, задачаFUMA))
    }
    func снимок() -> [(Data, НаправлениеПотокаCodexAppServer, Int, UUID?)] { записи }
}

@Suite("CodexAppServerAdapterTests")
struct АдаптерCodexAppServerTests {
    @Test func сохраняетЧастичныеСырыеФрагментыДоРазбора() async throws {
        let транспорт = ЗаписьТранспорта(["{\"id\":1,\"result\":{}", "}\n"])
        let адаптер = АдаптерCodexAppServer(транспорт: транспорт, журнал: ЗаписьСырья())
        let результат = try await адаптер.прочитатьОдинОтвет()
        #expect(результат == "{}")
        let записи = await журнал.снимок()
        #expect(записи.map(\.0) == [Data("{\"id\":1,\"result\":{}".utf8), Data("}\n".utf8)])
        #expect(записи.map(\.2) == [0, 19])
    }

    @Test func запрещаетЗадачуСЗаписьюДоТранспорта() async {
        let транспорт = ЗаписьТранспорта([])
        let адаптер = АдаптерCodexAppServer(транспорт: транспорт, журнал: ЗаписьСырья())
        do {
            _ = try await адаптер.начать(ЗадачаCodexAppServer(идентификатор: UUID(), текст: "x", доступ: .запись))
            Issue.record("ожидался отказ полномочий")
        } catch {}
        let отправлено = await транспорт.снимок()
        #expect(отправлено.isEmpty)
    }

    @Test func разрываетПотокПослеНеизвестногоИсходаБезПовтора() async throws {
        let транспорт = ЗаписьТранспорта(["{\"id\":1,\"result\":{}}\n", "{\"method\":\"thread/started\",\"params\":{\"thread\":{\"id\":\"thr_a\"}}}\n", "{\"id\":2,\"result\":{\"thread\":{\"id\":\"thr_a\"}}}\n", "{\"id\":3,\"result\":{\"turn\":{\"id\":\"turn_a\"}}}\n", "{\"method\":\"turn/started\",\"params\":{\"turn\":{\"id\":\"turn_a\"}}}\n"])
        let адаптер = АдаптерCodexAppServer(транспорт: транспорт, журнал: ЗаписьСырья())
        let задача = ЗадачаCodexAppServer(идентификатор: UUID(), текст: "read", доступ: .толькоЧтение)
        do {
            _ = try await адаптер.начать(задача)
            _ = try await адаптер.дождатьсяЗавершения()
            Issue.record("отключение должно дать неизвестный исход")
        } catch let ошибка as ОшибкаАдаптераCodexAppServer {
            #expect(ошибка == .исходНеизвестен)
        }
        let отправлено = await транспорт.снимок()
        #expect(отправлено.count == 4)
        do {
            _ = try await адаптер.начать(задача)
            Issue.record("неизвестный исход не должен повторяться")
        } catch let ошибка as ОшибкаАдаптераCodexAppServer {
            #expect(ошибка == .исходНеизвестен)
        }
    }

    @Test func сохраняетПовреждённыеБайтыДоОшибкиРазбора() async {
        let сырое = Data("{bad-json}\n".utf8)
        let журнал = ЗаписьСырья()
        let адаптер = АдаптерCodexAppServer(транспорт: ЗаписьТранспорта([String(decoding: сырое, as: UTF8.self)]), журнал: журнал)
        do {
            _ = try await адаптер.прочитатьОдинОтвет()
            Issue.record("повреждённый JSON должен быть отклонён")
        } catch {}
        #expect(await журнал.снимок().map(\.0) == [сырое])
    }

    @Test func отклоняетНеверныйИдентификаторОтвета() async {
        let транспорт = ЗаписьТранспорта(["{\"id\":99,\"result\":{}}\n"])
        let адаптер = АдаптерCodexAppServer(транспорт: транспорт, журнал: ЗаписьСырья())
        do {
            _ = try await адаптер.начать(ЗадачаCodexAppServer(идентификатор: UUID(), текст: "x", доступ: .толькоЧтение))
            Issue.record("ожидался отказ неверного id")
        } catch let ошибка as ОшибкаАдаптераCodexAppServer {
            #expect(ошибка == .неверныйОтвет)
        } catch {
            Issue.record("неожиданный тип ошибки")
        }
    }

    @Test func возобновляетЯвноУказанныйПотокИРазделяетИдентификаторы() async throws {
        let транспорт = ЗаписьТранспорта([
            "{\"id\":1,\"result\":{}}\n",
            "{\"id\":2,\"result\":{\"thread\":{\"id\":\"thr_existing\"}}}\n",
            "{\"id\":3,\"result\":{\"turn\":{\"id\":\"turn_new\"}}}\n"
        ])
        let адаптер = АдаптерCodexAppServer(транспорт: транспорт, журнал: ЗаписьСырья())
        let taskID = UUID()
        let запуск = try await адаптер.начать(ЗадачаCodexAppServer(идентификатор: taskID, текст: "continue", доступ: .толькоЧтение, идентификаторПотока: "thr_existing"))
        #expect(запуск == АктивныйЗапускCodexAppServer(идентификаторЗадачиFUMA: taskID, идентификаторПотокаCodex: "thr_existing", идентификаторХодаCodex: "turn_new"))
        let отправлено = await транспорт.снимок()
        let сообщения = try отправлено.map { try JSONSerialization.jsonObject(with: $0) as! [String: Any] }
        #expect(сообщения[2]["method"] as? String == "thread/resume")
        #expect((сообщения[2]["params"] as? [String: Any])?["threadId"] as? String == "thr_existing")
    }

    @Test func отклоняетЗапросРазрешенияИНеПринимаетЕго() async throws {
        let транспорт = ЗаписьТранспорта([
            "{\"id\":1,\"result\":{}}\n",
            "{\"id\":2,\"result\":{\"thread\":{\"id\":\"thr_a\"}}}\n",
            "{\"id\":3,\"result\":{\"turn\":{\"id\":\"turn_a\"}}}\n",
            ФикстурыCodexAppServer.запросРазрешенияКоманды,
            ФикстурыCodexAppServer.завершениеХодаА
        ])
        let адаптер = АдаптерCodexAppServer(транспорт: транспорт, журнал: ЗаписьСырья())
        _ = try await адаптер.начать(ЗадачаCodexAppServer(идентификатор: UUID(), текст: "read", доступ: .толькоЧтение))
        #expect(try await адаптер.дождатьсяЗавершения() == "completed")
        let отправлено = await транспорт.снимок()
        let ответ = try JSONSerialization.jsonObject(with: отправлено[4]) as! [String: Any]
        #expect((ответ["response"] as? [String: Any])?["decision"] as? String == "decline")
    }

    @Test func отменяетТолькоТочныйВнешнийХод() async throws {
        let транспорт = ЗаписьТранспорта([
            "{\"id\":1,\"result\":{}}\n",
            "{\"id\":2,\"result\":{\"thread\":{\"id\":\"thr_cancel\"}}}\n",
            "{\"id\":3,\"result\":{\"turn\":{\"id\":\"turn_cancel\"}}}\n",
            "{\"id\":4,\"result\":{}}\n",
            ФикстурыCodexAppServer.завершениеХодаОтменено
        ])
        let адаптер = АдаптерCodexAppServer(транспорт: транспорт, журнал: ЗаписьСырья())
        _ = try await адаптер.начать(ЗадачаCodexAppServer(идентификатор: UUID(), текст: "cancel", доступ: .толькоЧтение))
        try await адаптер.отменить()
        #expect(try await адаптер.дождатьсяЗавершения() == "interrupted")
        let отправлено = await транспорт.снимок()
        let запрос = try JSONSerialization.jsonObject(with: отправлено[4]) as! [String: Any]
        let параметры = запрос["params"] as? [String: Any]
        #expect(запрос["method"] as? String == "turn/interrupt")
        #expect(параметры?["threadId"] as? String == "thr_cancel")
        #expect(параметры?["turnId"] as? String == "turn_cancel")
    }
}
