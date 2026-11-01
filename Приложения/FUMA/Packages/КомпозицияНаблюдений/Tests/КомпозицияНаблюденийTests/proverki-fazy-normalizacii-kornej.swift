import Foundation
import Darwin
import CryptoKit
import Testing
import КонтейнерНаблюдений
@testable import КомпозицияНаблюдений

private actor ЗаписчикПорядкаФазы {
    private var события: [String] = []
    func добавить(_ событие: String) { события.append(событие) }
    func снимок() -> [String] { события }
}

private actor БарьерПараллельнойФазы {
    private var стартовала = false
    private var завершена = false
    private var разрешено = false
    private var ожиданиеСтарта: CheckedContinuation<Void, Never>?
    private var ожиданияПродолжения: [CheckedContinuation<Void, Never>] = []

    func сообщитьСтарт() {
        стартовала = true
        ожиданиеСтарта?.resume()
        ожиданиеСтарта = nil
    }

    func дождатьсяСтарта() async -> Bool {
        if стартовала { return true }
        if завершена { return false }
        await withCheckedContinuation { ожиданиеСтарта = $0 }
        return стартовала
    }

    func ждатьРазрешения() async {
        if разрешено { return }
        await withCheckedContinuation { ожиданияПродолжения.append($0) }
    }

    func разрешить() {
        разрешено = true
        let waiters = ожиданияПродолжения
        ожиданияПродолжения.removeAll()
        for waiter in waiters { waiter.resume() }
    }

    func завершить() {
        завершена = true
        ожиданиеСтарта?.resume()
        ожиданиеСтарта = nil
    }
}

private enum ИтогПараллельногоВызова: Sendable, Equatable {
    case busy
    case otherFailure
    case success
    case timeout
}

private actor ГонкаПараллельногоВызова {
    private var итог: ИтогПараллельногоВызова?
    private var ожидание: CheckedContinuation<ИтогПараллельногоВызова, Never>?

    func завершить(_ значение: ИтогПараллельногоВызова) {
        guard итог == nil else { return }
        итог = значение
        ожидание?.resume(returning: значение)
        ожидание = nil
    }

    func дождаться() async -> ИтогПараллельногоВызова {
        if let итог { return итог }
        return await withCheckedContinuation { ожидание = $0 }
    }
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

private enum РежимФазыФикстуры: Sendable, Equatable {
    case применено
    case безИзменений
    case пустойNoOp
    case рассогласованныйNoOp
    case приостановить
    case конфликт
    case неизвестно
}

private struct ФикстурнаяФазаНормализации: ФазаНормализацииКорнейСостояния {
    let режим: РежимФазыФикстуры
    let состояние: СостояниеФикстурыФазы
    let события: ЗаписчикПорядкаФазы
    let барьер: БарьерПараллельнойФазы?

    init(режим: РежимФазыФикстуры, состояние: СостояниеФикстурыФазы,
         события: ЗаписчикПорядкаФазы, барьер: БарьерПараллельнойФазы? = nil) {
        self.режим = режим
        self.состояние = состояние
        self.события = события
        self.барьер = барьер
    }

    func выполнить(
        контекст: КонтекстФазыНормализации,
        сохранитьНамерение: @escaping СохранитьНамерениеФазы
    ) async throws -> ИсходФазыНормализации {
        await состояние.начатьФазу()
        await события.добавить("phase-start")
        let данныеНамерения = Data("pinned-intent-v1".utf8)
        let intentReceipt = try await сохранитьНамерение(данныеНамерения)
        await события.добавить("intent-readback")
        switch режим {
        case .применено:
            await события.добавить("apply")
            return .применено(свидетельство: Data("known-effect-v1".utf8))
        case .безИзменений:
            await события.добавить("no-op-observed")
            return .безИзменений(свидетельство: try свидетельствоNoOp(
                контекст: контекст, intentHash: intentReceipt.хэш,
                observedDigest: контекст.хэшОжидаемогоСнимка ?? ""))
        case .пустойNoOp:
            await события.добавить("no-op-empty-witness")
            return .безИзменений(свидетельство: Data())
        case .рассогласованныйNoOp:
            await события.добавить("no-op-mismatched-readback")
            return .безИзменений(свидетельство: try свидетельствоNoOp(
                контекст: контекст, intentHash: intentReceipt.хэш,
                observedDigest: String(repeating: "c", count: 64)))
        case .приостановить:
            guard let барьер else { throw ОшибкаФикстурыФазы.readback }
            await барьер.сообщитьСтарт()
            await барьер.ждатьРазрешения()
            await события.добавить("apply")
            return .применено(свидетельство: Data("known-effect-v1".utf8))
        case .конфликт:
            await события.добавить("conflict-observed")
            return .конфликт(причина: "unresolved-path-collision", свидетельство: Data("both-roots-preserved-v1".utf8))
        case .неизвестно:
            await события.добавить("apply")
            return .неизвестно(причина: "post-effect state unavailable", свидетельство: nil)
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
    let хэшОжидаемогоСнимка: String?
    let хэшНамерения: String?
    let вид: String
    let причина: String?
    let свидетельство: Data?
}

private struct СвидетельствоNoOpФикстуры: Codable {
    let схема: String
    let операция: String
    let видНаблюдения: String
    let идентификаторНаблюдения: String
    let хэшНамерения: String
    let хэшЦелевогоСнимка: String
    let хэшНаблюдённогоСнимка: String
}

private struct СтараяЗаписьФазыБезВремени: Codable {
    let схема: String
    let операция: String
    let назначение: Data
    let контрольнаяТочка: Data
    let хэшНамерения: String?
    let вид: String
    let причина: String?
    let свидетельство: Data?
}

private func свидетельствоNoOp(
    контекст: КонтекстФазыНормализации,
    intentHash: String,
    observedDigest: String
) throws -> Data {
    let proof = СвидетельствоNoOpФикстуры(
        схема: "fuma.свидетельство-no-op.1",
        операция: контекст.идентификаторОперации,
        видНаблюдения: "post-effect-readback",
        идентификаторНаблюдения: "fixture-observation-after-apply",
        хэшНамерения: intentHash,
        хэшЦелевогоСнимка: контекст.хэшОжидаемогоСнимка ?? "",
        хэшНаблюдённогоСнимка: observedDigest)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    var bytes = try encoder.encode(proof)
    bytes.append(10)
    return bytes
}

private func записатьСтароеНамерениеБезВремени(
    контекст: КонтекстФазыНормализации,
    история: URL
) throws {
    let payload = Data("legacy-pinned-intent".utf8)
    let record = СтараяЗаписьФазыБезВремени(
        схема: "fuma.фаза-нормализации-намерение.1",
        операция: контекст.идентификаторОперации,
        назначение: контекст.назначение,
        контрольнаяТочка: контекст.контрольнаяТочка,
        хэшНамерения: хэшФикстуры(payload),
        вид: "intent", причина: nil, свидетельство: payload)
    let bytes = try каноническиеБайтыФикстуры(record)
    let segment = try Сегмент(кореньДанных: история, запись: true, создать: true)
    defer { segment.закрыть() }
    let description = ОписаниеНаблюдения(
        идентификатор: "фаза-нормализации-намерение-\(контекст.идентификаторОперации)",
        тип: "fuma.намерение-фазы-нормализации.1", версияСхемы: 1,
        источник: "КомпозицияНаблюдений", время: "2026-10-31T00:00:00Z",
        спецификация: Data("fuma.фаза-нормализации-корня.1".utf8))
    _ = try segment.добавить(description, данные: bytes)
}

private func каноническиеБайтыФикстуры<T: Codable>(_ запись: T) throws -> Data {
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
          время: "2026-11-01T00:00:00Z",
          хэшОжидаемогоСнимка: String(repeating: "b", count: 64))
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

@Test func конфликтСохраняетсяБезПланаИResumeНеПовторяетФазу() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .конфликт, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)
    let first = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: контекстФазы(), фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .конфликт(let reason, let witness) = first.исходФазы else {
        Issue.record("Ожидался terminal CONFLICT")
        return
    }
    #expect(reason == "unresolved-path-collision")
    #expect(witness == Data("both-roots-preserved-v1".utf8))
    #expect(first.планПослеИсхода == nil)

    let resumed = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: контекстФазы(), фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .конфликт(let resumedReason, let resumedWitness) = resumed.исходФазы else {
        Issue.record("Resume должен сохранить terminal CONFLICT")
        return
    }
    #expect(resumedReason == reason)
    #expect(resumedWitness == witness)
    #expect(resumed.квитанцияТерминала == first.квитанцияТерминала)
    #expect(resumed.планПослеИсхода == nil)
    #expect(await state.вызововФазы == 1)
    #expect(await order.снимок() == ["phase-start", "intent-readback", "conflict-observed"])
}

@Test func подтверждённыйNoOpСохраняетсяИВозобновляетсяБезПрименения() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .безИзменений, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)

    let first = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: контекстФазы(), фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .безИзменений(let witness) = first.исходФазы else {
        Issue.record("Ожидался отдельный подтверждённый NO_OP")
        return
    }
    let noOpProof = try JSONDecoder().decode(СвидетельствоNoOpФикстуры.self, from: witness)
    #expect(noOpProof.операция == контекстФазы().идентификаторОперации)
    #expect(noOpProof.видНаблюдения == "post-effect-readback")
    #expect(noOpProof.хэшЦелевогоСнимка == контекстФазы().хэшОжидаемогоСнимка)
    #expect(noOpProof.хэшНаблюдённогоСнимка == noOpProof.хэшЦелевогоСнимка)
    #expect(first.квитанцияТерминала.размер > 0)
    #expect(first.планПослеИсхода != nil)

    let resumed = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: контекстФазы(), фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .безИзменений(let resumedWitness) = resumed.исходФазы else {
        Issue.record("Resume должен сохранить типизированный NO_OP")
        return
    }
    #expect(resumedWitness == witness)
    #expect(resumed.квитанцияТерминала == first.квитанцияТерминала)
    #expect(resumed.планПослеИсхода != nil)
    #expect(await state.вызововФазы == 1)
    #expect(await order.снимок() == ["phase-start", "intent-readback", "no-op-observed",
        "fresh-plan-after-terminal-readback", "repository-plan",
        "fresh-plan-after-terminal-readback", "repository-plan"])
}

@Test(arguments: [РежимФазыФикстуры.пустойNoOp, .рассогласованныйNoOp])
func неподтверждённыйNoOpОстаётсяUnknown(режим: РежимФазыФикстуры) async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: режим, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)
    let result = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: контекстФазы(), фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .неизвестно = result.исходФазы else {
        Issue.record("NO_OP без точного наблюдательного совпадения должен быть UNKNOWN")
        return
    }
    #expect(result.планПослеИсхода == nil)
    #expect(await state.вызововФазы == 1)
    let events = await order.снимок()
    #expect(!events.contains("apply"))
}

@Test func занятыйМежпроцессныйClaimОтказываетДоВызоваФазы() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let operation = контекстФазы().идентификаторОперации
    let lockPath = env.история.appendingPathComponent(".fuma-phase-claim-\(operation)").path
    let fd = open(lockPath, O_CREAT | O_RDWR | O_NOFOLLOW, mode_t(S_IRUSR | S_IWUSR))
    #expect(fd >= 0)
    guard fd >= 0 else { return }
    defer { _ = flock(fd, LOCK_UN); close(fd) }
    #expect(flock(fd, LOCK_EX | LOCK_NB) == 0)

    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .применено, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)
    do {
        _ = try await ЦиклНаблюденийСостояния(поставщик: provider)
            .выполнитьФазуНормализации(
                контекст: контекстФазы(), фаза: phase,
                кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
                кореньРепозитория: env.репозиторий, кореньИстории: env.история,
                времяИстории: "2026-11-01T00:00:00Z")
        Issue.record("Занятый claim должен отказать до вызова фазы")
    } catch let error as ОшибкаЦиклаНаблюденийСостояния {
        #expect(error == .фазаУжеИсполняется)
    }
    #expect(await state.вызововФазы == 0)
    #expect(await order.снимок().isEmpty)
}

@Test func дваПараллельныхВызоваОднойОперацииНеДублируютЭффект() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let gate = БарьерПараллельнойФазы()
    let phase = ФикстурнаяФазаНормализации(
        режим: .приостановить, состояние: state, события: order, барьер: gate)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)
    let firstTask = Task {
        defer { Task { await gate.завершить() } }
        return try await ЦиклНаблюденийСостояния(поставщик: provider)
            .выполнитьФазуНормализации(
                контекст: контекстФазы(), фаза: phase,
                кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
                кореньРепозитория: env.репозиторий, кореньИстории: env.история,
                времяИстории: "2026-11-01T00:00:00Z")
    }
    let firstReachedPhase = await gate.дождатьсяСтарта()
    var secondOutcome: ИтогПараллельногоВызова = .timeout
    var secondTask: Task<Void, Never>?
    var timeoutTask: Task<Void, Never>?
    if firstReachedPhase {
        let race = ГонкаПараллельногоВызова()
        secondTask = Task {
          do {
            _ = try await ЦиклНаблюденийСостояния(поставщик: provider)
            .выполнитьФазуНормализации(
                контекст: контекстФазы(), фаза: phase,
                кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
                кореньРепозитория: env.репозиторий, кореньИстории: env.история,
                времяИстории: "2026-11-01T00:00:00Z")
            await race.завершить(.success)
          } catch let error as ОшибкаЦиклаНаблюденийСостояния {
            await race.завершить(error == .фазаУжеИсполняется ? .busy : .otherFailure)
          } catch {
            await race.завершить(.otherFailure)
          }
        }
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await race.завершить(.timeout)
        }
        secondOutcome = await race.дождаться()
    }
    // Release before awaiting either task, even on timeout or an unexpected
    // second-call failure, so no synthetic phase waiter is left suspended.
    await gate.разрешить()
    timeoutTask?.cancel()
    let firstResult = await firstTask.result
    if let secondTask { await secondTask.value }
    #expect(firstReachedPhase)
    #expect(secondOutcome == .busy)
    #expect(await state.вызововФазы == 1)
    let first: РезультатЦиклаНаблюденийСФазой
    switch firstResult {
    case let .success(value): first = value
    case let .failure(error):
        Issue.record("Первый вызов завершился ошибкой: \(error)")
        return
    }
    guard case .применено = first.исходФазы else {
        Issue.record("Первый владелец claim завершает один наблюдённый apply")
        return
    }
    #expect(await state.вызововФазы == 1)
    #expect(await order.снимок() == ["phase-start", "intent-readback", "apply",
        "fresh-plan-after-terminal-readback", "repository-plan"])
}

@Test func намерениеСтаройСхемыБезВремениДаётUnknownБезReplay() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let context = контекстФазы()
    try записатьСтароеНамерениеБезВремени(контекст: context, история: env.история)
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .применено, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)

    let first = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: context, фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .неизвестно = first.исходФазы else {
        Issue.record("Legacy intent без pinned времени должен быть UNKNOWN")
        return
    }
    #expect(first.планПослеИсхода == nil)
    #expect(await state.вызововФазы == 0)

    let resumed = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: context, фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .неизвестно = resumed.исходФазы else {
        Issue.record("Legacy resume не должен запускать фазу")
        return
    }
    #expect(resumed.планПослеИсхода == nil)
    #expect(await state.вызововФазы == 0)
    #expect(await order.снимок().isEmpty)
}

@Test func legacyOrphanСЧужимКонтекстомНеПолучаетTerminalИНеБлокируетИсходныйResume() async throws {
    let env = try окружениеФазы()
    defer { try? FileManager.default.removeItem(at: env.корень) }
    let original = контекстФазы()
    try записатьСтароеНамерениеБезВремени(контекст: original, история: env.история)
    let conflicting = КонтекстФазыНормализации(
        идентификаторОперации: original.идентификаторОперации,
        назначение: Data("owner=someone-else;ref=refs/heads/codex/other".utf8),
        контрольнаяТочка: original.контрольнаяТочка,
        время: original.время,
        хэшОжидаемогоСнимка: original.хэшОжидаемогоСнимка)
    let order = ЗаписчикПорядкаФазы()
    let state = СостояниеФикстурыФазы(события: order, журнал: env.история)
    let phase = ФикстурнаяФазаНормализации(режим: .применено, состояние: state, события: order)
    let provider = ФикстурныйПоставщикФазы(состояние: state, события: order)

    do {
        _ = try await ЦиклНаблюденийСостояния(поставщик: provider)
            .выполнитьФазуНормализации(
                контекст: conflicting, фаза: phase,
                кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
                кореньРепозитория: env.репозиторий, кореньИстории: env.история,
                времяИстории: "2026-11-01T00:00:00Z")
        Issue.record("Чужой context не должен заносить terminal для legacy intent")
    } catch let error as ОшибкаЦиклаНаблюденийСостояния {
        #expect(error == .несовпадениеСохранённогоКонтекста)
    }

    let beforeResume = try Сегмент(кореньДанных: env.история, запись: false, создать: false)
    #expect(!beforeResume.записи.contains {
        $0.описание.идентификатор == "фаза-нормализации-исход-\(original.идентификаторОперации)"
    })
    beforeResume.закрыть()

    let resumed = try await ЦиклНаблюденийСостояния(поставщик: provider)
        .выполнитьФазуНормализации(
            контекст: original, фаза: phase,
            кореньФайловойСистемы: env.репозиторий, источникФайловойСистемы: "fixture",
            кореньРепозитория: env.репозиторий, кореньИстории: env.история,
            времяИстории: "2026-11-01T00:00:00Z")
    guard case .неизвестно = resumed.исходФазы else {
        Issue.record("Исходный legacy context должен безопасно восстановиться как UNKNOWN")
        return
    }
    #expect(resumed.планПослеИсхода == nil)
    #expect(await state.вызововФазы == 0)
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
        время: прежний.время,
        хэшОжидаемогоСнимка: прежний.хэшОжидаемогоСнимка)
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
        хэшОжидаемогоСнимка: context.хэшОжидаемогоСнимка,
        хэшНамерения: хэшФикстуры(Data("pinned-intent-v1".utf8)),
        вид: "intent", причина: nil, свидетельство: Data("pinned-intent-v1".utf8))
    let изменённоеНамерение = ЗаписьФикстурыФазы(
        схема: "fuma.фаза-нормализации-намерение.1", операция: context.идентификаторОперации,
        время: context.время, назначение: context.назначение,
        контрольнаяТочка: context.контрольнаяТочка,
        хэшОжидаемогоСнимка: context.хэшОжидаемогоСнимка,
        хэшНамерения: хэшФикстуры(Data("altered-intent-v1".utf8)),
        вид: "intent", причина: nil, свидетельство: Data("altered-intent-v1".utf8))
    let terminal = ЗаписьФикстурыФазы(
        схема: "fuma.фаза-нормализации.1", операция: context.идентификаторОперации,
        время: context.время, назначение: context.назначение,
        контрольнаяТочка: context.контрольнаяТочка,
        хэшОжидаемогоСнимка: context.хэшОжидаемогоСнимка,
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
