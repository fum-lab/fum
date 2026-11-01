import Foundation
import CryptoKit
import Testing
import КонтейнерНаблюдений
@testable import КомпозицияНаблюдений

private actor ЗаписчикПорядкаФазы {
    private var события: [String] = []
    func добавить(_ событие: String) { события.append(событие) }
    func снимок() -> [String] { события }
}

private actor СостояниеФикстурыФазы {
    private(set) var вызововФазы = 0
    private let события: ЗаписчикПорядкаФазы
    private let журнал: URL

    init(события: ЗаписчикПорядкаФазы, журнал: URL) {
        self.события = события
        self.журнал = журнал
    }

    func начатьФазу() { вызововФазы += 1 }

    func проверитьТерминалПередСвежимПланом() async throws {
        let читатель = try Сегмент(кореньДанных: журнал, запись: false, создать: false)
        defer { читатель.закрыть() }
        guard let квитанция = читатель.записи.first(where: {
            $0.описание.идентификатор == "фаза-нормализации-исход-cell-17-root-merge"
        }), try читатель.извлечь(квитанция.описание.идентификатор).isEmpty == false else {
            throw ОшибкаФикстурыФазы.terminalMissing
        }
        await события.добавить("fresh-plan-after-terminal-readback")
    }
}

private enum РежимФазыФикстуры: Sendable {
    case применено
    case неизвестно
}

private struct ФикстурнаяФазаНормализации: ФазаНормализацииКорнейСостояния {
    let режим: РежимФазыФикстуры
    let состояние: СостояниеФикстурыФазы
    let события: ЗаписчикПорядкаФазы

    func выполнить(
        контекст: КонтекстФазыНормализации,
        сохранитьНамерение: @escaping СохранитьНамерениеФазы
    ) async throws -> ИсходФазыНормализации {
        await состояние.начатьФазу()
        await события.добавить("phase-start")
        let данныеНамерения = Data("pinned-intent-v1".utf8)
        _ = try await сохранитьНамерение(данныеНамерения)
        await события.добавить("intent-readback")
        await события.добавить("apply")
        switch режим {
        case .применено: return .применено(свидетельство: Data("known-effect-v1".utf8))
        case .неизвестно: return .неизвестно(причина: "post-effect state unavailable", свидетельство: nil)
        }
    }
}

private struct ФикстурныйПоставщикФазы: ПоставщикНаблюденийСостояния {
    let состояние: СостояниеФикстурыФазы
    let события: ЗаписчикПорядкаФазы

    func наблюдатьФайловуюСистему(корень: URL, источник: String) async throws -> ПроекцияФайловойСистемы {
        try await состояние.проверитьТерминалПередСвежимПланом()
        return .init(физическийКорень: корень.path, источник: источник, предшественник: nil,
                     идентификатор: "fs-generation-after-phase", записи: [])
    }

    func наблюдатьРепозиторий(корень: URL) async throws -> ПроекцияРепозитория {
        await события.добавить("repository-plan")
        return .init(схема: "fuma.git-snapshot.1", физическийКорень: корень.path,
                     коммит: String(repeating: "a", count: 40), ссылка: "refs/heads/codex/worker",
                     изменённыеПути: [], неотслеживаемыеПути: [])
    }
}

private enum ОшибкаФикстурыФазы: Error {
    case readback, terminalMissing
}

private struct ЗаписьФикстурыФазы: Codable {
    let схема: String
    let операция: String
    let время: String
    let назначение: Data
    let контрольнаяТочка: Data
    let хэшНамерения: String?
    let вид: String
    let причина: String?
    let свидетельство: Data?
}

private func каноническиеБайтыФикстуры(_ запись: ЗаписьФикстурыФазы) throws -> Data {
    let кодировщик = JSONEncoder()
    кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var байты = try кодировщик.encode(запись)
    байты.append(10)
    return байты
}

private func хэшФикстуры(_ байты: Data) -> String {
    SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
}

private func окружениеФазы() throws -> (корень: URL, репозиторий: URL, история: URL) {
    let корень = FileManager.default.temporaryDirectory
        .appendingPathComponent("fuma-phase-fixture-\(UUID().uuidString)", isDirectory: true)
    let репозиторий = корень.appendingPathComponent("repo", isDirectory: true)
    let история = корень.appendingPathComponent("history", isDirectory: true)
    try FileManager.default.createDirectory(at: репозиторий, withIntermediateDirectories: true,
                                           attributes: [.posixPermissions: 0o700])
    try FileManager.default.createDirectory(at: история, withIntermediateDirectories: true,
                                           attributes: [.posixPermissions: 0o700])
    return (корень, репозиторий, история)
}

private func контекстФазы() -> КонтекстФазыНормализации {
    .init(идентификаторОперации: "cell-17-root-merge",
          назначение: Data("owner=worker-17;ref=refs/heads/codex/worker-17".utf8),
          контрольнаяТочка: Data("source-sha256=source-v1;target-sha256=target-v1".utf8),
          время: "2026-11-01T00:00:00Z")
}

@Test func намерениеПрочитаноДоApplyАТерминалДоНовогоПлана() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .применено, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)
    let cycle = ЦиклНаблюденийСостояния(поставщик: provider)

    let result = try await cycle.выполнитьФазуНормализации(
        контекст: контекстФазы(), фаза: phase,
        кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
        кореньРепозитория: env.репозиторий, кореньИстории: env.история,
        времяИстории: "2026-11-01T00:00:00Z")

    guard case .применено = result.исходФазы else {
        Issue.record("Ожидался известный исход apply")
        return
    }
    #expect(result.квитанцияНамерения != nil)
    #expect(result.квитанцияТерминала.описание.идентификатор
            == "фаза-нормализации-исход-cell-17-root-merge")
    #expect(result.квитанцияТерминала.размер > 0)
    #expect(result.квитанцияТерминала.хэш.utf8.count == 64)
    #expect(result.планПослеИсхода != nil)

    let restoredCycle = ЦиклНаблюденийСостояния(поставщик: provider)
    let replay = try await restoredCycle.выполнитьФазуНормализации(
        контекст: контекстФазы(), фаза: phase,
        кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
        кореньРепозитория: env.репозиторий, кореньИстории: env.история,
        времяИстории: "2026-11-01T00:00:00Z")
    guard case .применено = replay.исходФазы else {
        Issue.record("Проверенный pinned intent должен восстановить известный applied")
        return
    }
    #expect(replay.квитанцияТерминала == result.квитанцияТерминала)
    #expect(replay.планПослеИсхода != nil)
    #expect(await state.вызововФазы == 1)
    #expect(await order.снимок() == ["phase-start", "intent-readback", "apply",
        "fresh-plan-after-terminal-readback", "repository-plan",
        "fresh-plan-after-terminal-readback", "repository-plan"])
}

@Test func durableUnknownПереживаетПовторИНеПовторяетApply() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .неизвестно, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)
    let firstCycle = ЦиклНаблюденийСостояния(поставщик: provider)

    let first = try await firstCycle.выполнитьФазуНормализации(
        контекст: контекстФазы(), фаза: phase,
        кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
        кореньРепозитория: env.репозиторий, кореньИстории: env.история,
        времяИстории: "2026-11-01T00:00:00Z")
    guard case .неизвестно = first.исходФазы else {
        Issue.record("Потеря знания о результате должна оставаться UNKNOWN")
        return
    }
    #expect(first.квитанцияТерминала.описание.идентификатор
            == "фаза-нормализации-исход-cell-17-root-merge")
    #expect(first.квитанцияТерминала.размер > 0)
    #expect(first.квитанцияТерминала.хэш.utf8.count == 64)
    #expect(first.планПослеИсхода == nil)

    let restoredCycle = ЦиклНаблюденийСостояния(поставщик: provider)
    let restored = try await restoredCycle.выполнитьФазуНормализации(
        контекст: контекстФазы(), фаза: phase,
        кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
        кореньРепозитория: env.репозиторий, кореньИстории: env.история,
        времяИстории: "2026-11-01T00:00:00Z")
    guard case .неизвестно = restored.исходФазы else {
        Issue.record("Восстановление должно вернуть сохранённый UNKNOWN")
        return
    }
    #expect(await state.вызововФазы == 1)
    #expect(restored.квитанцияТерминала == first.квитанцияТерминала)
    #expect(restored.планПослеИсхода == nil)
    #expect(await order.снимок() == ["phase-start", "intent-readback", "apply"])
}

@Test func изменённыйPinnedКонтекстДаётUnknownБезReplay() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .применено, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)
    let cycle = ЦиклНаблюденийСостояния(поставщик: provider)
    _ = try await cycle.выполнитьФазуНормализации(
        контекст: контекстФазы(), фаза: phase,
        кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
        кореньРепозитория: env.репозиторий, кореньИстории: env.история,
        времяИстории: "2026-11-01T00:00:00Z")

    let прежний = контекстФазы()
    let изменённый = КонтекстФазыНормализации(
        идентификаторОперации: прежний.идентификаторОперации,
        назначение: прежний.назначение,
        контрольнаяТочка: Data("source-sha256=changed;target-sha256=target-v1".utf8),
        время: прежний.время)
    let replay = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: изменённый, фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .неизвестно = replay.исходФазы else {
        Issue.record("Изменённый pinned context нельзя подтверждать старым terminal")
        return
    }
    #expect(replay.планПослеИсхода == nil)
    #expect(await state.вызововФазы == 1)
    #expect(await order.снимок() == ["phase-start", "intent-readback", "apply",
        "fresh-plan-after-terminal-readback", "repository-plan"])
}

@Test func изменённыеБайтыПрочитанногоIntentНеПодтверждаютСтарыйTerminal() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let context = контекстФазы()
    let intentID = "фаза-нормализации-намерение-\(context.идентификаторОперации)"
    let terminalID = "фаза-нормализации-исход-\(context.идентификаторОперации)"
    let староеНамерение = ЗаписьФикстурыФазы(
        схема: "fuma.фаза-нормализации-намерение.1", операция: context.идентификаторОперации,
        время: context.время, назначение: context.назначение,
        контрольнаяТочка: context.контрольнаяТочка,
        хэшНамерения: хэшФикстуры(Data("pinned-intent-v1".utf8)),
        вид: "intent", причина: nil, свидетельство: Data("pinned-intent-v1".utf8))
    let изменённоеНамерение = ЗаписьФикстурыФазы(
        схема: "fuma.фаза-нормализации-намерение.1", операция: context.идентификаторОперации,
        время: context.время, назначение: context.назначение,
        контрольнаяТочка: context.контрольнаяТочка,
        хэшНамерения: хэшФикстуры(Data("altered-intent-v1".utf8)),
        вид: "intent", причина: nil, свидетельство: Data("altered-intent-v1".utf8))
    let terminal = ЗаписьФикстурыФазы(
        схема: "fuma.фаза-нормализации.1", операция: context.идентификаторОперации,
        время: context.время, назначение: context.назначение,
        контрольнаяТочка: context.контрольнаяТочка,
        хэшНамерения: хэшФикстуры(try каноническиеБайтыФикстуры(староеНамерение)),
        вид: "applied", причина: nil, свидетельство: Data("known-effect-v1".utf8))
    let segment = try Сегмент(кореньДанных: env.история, запись: true, создать: true)
    _ = try segment.добавить(
        ОписаниеНаблюдения(идентификатор: intentID, тип: "fuma.намерение-фазы-нормализации.1"),
        данные: try каноническиеБайтыФикстуры(изменённоеНамерение))
    _ = try segment.добавить(
        ОписаниеНаблюдения(идентификатор: terminalID, тип: "fuma.исход-фазы-нормализации.1"),
        данные: try каноническиеБайтыФикстуры(terminal))
    segment.закрыть()

    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .применено, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)
    let result = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: context, фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: context.время)
    guard case .неизвестно = result.исходФазы else {
        Issue.record("Terminal от иных байтов intent должен остаться UNKNOWN")
        return
    }
    #expect(result.планПослеИсхода == nil)
    #expect(await state.вызововФазы == 0)
    #expect(await order.снимок().isEmpty)
}
