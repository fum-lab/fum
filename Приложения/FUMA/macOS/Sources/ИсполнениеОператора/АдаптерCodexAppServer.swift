import Foundation

enum НаправлениеПотокаCodexAppServer: String, Sendable {
    case вход
    case выход
}

protocol ТранспортCodexAppServer: Sendable {
    func отправить(_ байты: Data) async throws
    func принять() async throws -> Data?
    func закрыть() async
}

protocol ЖурналСырогоПотокаCodexAppServer: Sendable {
    func сохранить(_ байты: Data, направление: НаправлениеПотокаCodexAppServer, смещение: Int, задачаFUMA: UUID?) async throws
}

enum ДоступЗадачиCodexAppServer: Sendable, Equatable {
    case толькоЧтение
    case запись
}

struct ЗадачаCodexAppServer: Sendable {
    let идентификатор: UUID
    let текст: String
    let доступ: ДоступЗадачиCodexAppServer
    let идентификаторПотока: String?

    init(идентификатор: UUID, текст: String, доступ: ДоступЗадачиCodexAppServer, идентификаторПотока: String? = nil) {
        self.идентификатор = идентификатор
        self.текст = текст
        self.доступ = доступ
        self.идентификаторПотока = идентификаторПотока
    }
}

struct АктивныйЗапускCodexAppServer: Sendable, Equatable {
    let идентификаторЗадачиFUMA: UUID
    let идентификаторПотокаCodex: String
    let идентификаторХодаCodex: String
}

enum ОшибкаАдаптераCodexAppServer: Error, Equatable {
    case полномочияОтклонены
    case неверныйОтвет
    case исходНеизвестен
    case ограничениеРазмеров
    case неактивныйЗапуск
}

actor АдаптерCodexAppServer {
    private let транспорт: any ТранспортCodexAppServer
    private let журнал: any ЖурналСырогоПотокаCodexAppServer
    private var накопитель = Data()
    private var смещениеВхода = 0
    private var смещениеВыхода = 0
    private var следующийID = 1
    private var активный: АктивныйЗапускCodexAppServer?
    private var исходНеопределён = false
    private let пределСтроки = 262_144
    private let пределПотока = 1_048_576
    private var принятоБайт = 0
    private var использованныеЗадачи = Set<UUID>()
    private var идентификаторЗадачи: UUID?
    private var полученоСобытий = 0

    init(транспорт: any ТранспортCodexAppServer, журнал: any ЖурналСырогоПотокаCodexAppServer) {
        self.транспорт = транспорт
        self.журнал = журнал
    }

    func прочитатьОдинОтвет() async throws -> String {
        let сообщение = try await принятьСообщение()
        guard let значение = сообщение["result"] else { throw ОшибкаАдаптераCodexAppServer.неверныйОтвет }
        let данные = try JSONSerialization.data(withJSONObject: значение, options: [.fragmentsAllowed, .sortedKeys])
        return String(decoding: данные, as: UTF8.self)
    }

    func начать(_ задача: ЗадачаCodexAppServer) async throws -> АктивныйЗапускCodexAppServer {
        guard задача.доступ == .толькоЧтение else { throw ОшибкаАдаптераCodexAppServer.полномочияОтклонены }
        guard активный == nil, !исходНеопределён else { throw ОшибкаАдаптераCodexAppServer.исходНеизвестен }
        guard !использованныеЗадачи.contains(задача.идентификатор),
              задача.текст.utf8.count <= 65_536 else { throw ОшибкаАдаптераCodexAppServer.ограничениеРазмеров }
        использованныеЗадачи.insert(задача.идентификатор)
        идентификаторЗадачи = задача.идентификатор
        _ = try await запрос("initialize", ["clientInfo": ["name": "FUMA", "version": "offline-prototype"]])
        try await уведомление("initialized", [:])
        let потокОтвет: [String: Any]
        if let idПотока = задача.идентификаторПотока {
            потокОтвет = try await запрос("thread/resume", ["threadId": idПотока])
        } else {
            потокОтвет = try await запрос("thread/start", ["approvalPolicy": "on-request", "sandbox": "read-only"])
        }
        guard let поток = (потокОтвет["thread"] as? [String: Any])?["id"] as? String else {
            throw ОшибкаАдаптераCodexAppServer.неверныйОтвет
        }
        let ходОтвет = try await запрос("turn/start", [
            "threadId": поток,
            "input": [["type": "text", "text": задача.текст]],
            "approvalPolicy": "on-request",
            "sandbox": "read-only"
        ])
        guard let ход = (ходОтвет["turn"] as? [String: Any])?["id"] as? String else {
            исходНеопределён = true
            throw ОшибкаАдаптераCodexAppServer.исходНеизвестен
        }
        let запуск = АктивныйЗапускCodexAppServer(идентификаторЗадачиFUMA: задача.идентификатор,
            идентификаторПотокаCodex: поток, идентификаторХодаCodex: ход)
        активный = запуск
        return запуск
    }

    func дождатьсяЗавершения() async throws -> String {
        guard let запуск = активный else { throw ОшибкаАдаптераCodexAppServer.неактивныйЗапуск }
        do {
            while let сообщение = try await следующееСообщение() {
                полученоСобытий += 1
                guard полученоСобытий <= 128 else { throw ОшибкаАдаптераCodexAppServer.ограничениеРазмеров }
                guard let метод = сообщение["method"] as? String else { continue }
                let параметры = сообщение["params"] as? [String: Any] ?? [:]
                if метод == "turn/completed",
                   let turn = параметры["turn"] as? [String: Any],
                   turn["id"] as? String == запуск.идентификаторХодаCodex {
                    активный = nil
                    return (turn["status"] as? String) ?? "completed"
                }
                if метод.hasSuffix("/requestApproval") || метод.hasSuffix("/requestPermissions") {
                    try await отклонитьЗапрос(сообщение)
                }
            }
            исходНеопределён = true
            throw ОшибкаАдаптераCodexAppServer.исходНеизвестен
        } catch {
            if активный != nil { исходНеопределён = true }
            throw error
        }
    }

    func отменить() async throws {
        guard let запуск = активный else { throw ОшибкаАдаптераCodexAppServer.неактивныйЗапуск }
        _ = try await запрос("turn/interrupt", ["threadId": запуск.идентификаторПотокаCodex,
            "turnId": запуск.идентификаторХодаCodex])
    }

    private func запрос(_ метод: String, _ параметры: [String: Any]) async throws -> [String: Any] {
        let id = следующийID
        следующийID += 1
        try await отправить(["id": id, "method": метод, "params": параметры])
        do {
            while let сообщение = try await следующееСообщение() {
                if let входящийМетод = сообщение["method"] as? String {
                    if входящийМетод.hasSuffix("/requestApproval") || входящийМетод.hasSuffix("/requestPermissions") {
                        try await отклонитьЗапрос(сообщение)
                    }
                    continue
                }
                guard (сообщение["id"] as? Int) == id else { throw ОшибкаАдаптераCodexAppServer.неверныйОтвет }
                if сообщение["error"] != nil { throw ОшибкаАдаптераCodexAppServer.неверныйОтвет }
                guard let result = сообщение["result"] as? [String: Any] else { throw ОшибкаАдаптераCodexAppServer.неверныйОтвет }
                return result
            }
            исходНеопределён = true
            throw ОшибкаАдаптераCodexAppServer.исходНеизвестен
        } catch {
            if метод == "thread/start" || метод == "turn/start" || метод == "thread/resume" {
                исходНеопределён = true
            }
            throw error
        }
    }

    private func уведомление(_ метод: String, _ параметры: [String: Any]) async throws {
        try await отправить(["method": метод, "params": параметры])
    }

    private func отклонитьЗапрос(_ сообщение: [String: Any]) async throws {
        guard let id = сообщение["id"] else { return }
        try await отправить(["id": id, "response": ["decision": "decline"]])
    }

    private func отправить(_ объект: [String: Any]) async throws {
        var данные = try JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys, .withoutEscapingSlashes])
        данные.append(0x0a)
        try await журнал.сохранить(данные, направление: .выход, смещение: смещениеВыхода, задачаFUMA: идентификаторЗадачи)
        смещениеВыхода += данные.count
        try await транспорт.отправить(данные)
    }

    private func следующееСообщение() async throws -> [String: Any]? {
        while true {
            if let конец = накопитель.firstIndex(of: 0x0a) {
                let строка = накопитель[..<конец]
                накопитель.removeSubrange(...конец)
                guard !строка.isEmpty else { continue }
                guard строка.count <= пределСтроки else { throw ОшибкаАдаптераCodexAppServer.ограничениеРазмеров }
                guard let объект = try JSONSerialization.jsonObject(with: Data(строка)) as? [String: Any] else {
                    throw ОшибкаАдаптераCodexAppServer.неверныйОтвет
                }
                return объект
            }
            guard накопитель.count <= пределСтроки else { throw ОшибкаАдаптераCodexAppServer.ограничениеРазмеров }
            guard let часть = try await транспорт.принять() else { return nil }
            try await журнал.сохранить(часть, направление: .вход, смещение: смещениеВхода, задачаFUMA: идентификаторЗадачи)
            смещениеВхода += часть.count
            принятоБайт += часть.count
            guard принятоБайт <= пределПотока else { throw ОшибкаАдаптераCodexAppServer.ограничениеРазмеров }
            накопитель.append(часть)
        }
    }

    private func принятьСообщение() async throws -> [String: Any] {
        guard let сообщение = try await следующееСообщение() else { throw ОшибкаАдаптераCodexAppServer.исходНеизвестен }
        return сообщение
    }
}
