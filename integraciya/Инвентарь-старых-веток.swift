import CryptoKit
import Foundation

struct Корень: Decodable {
    let рабочееДерево: String
    let ref: String
    let база: String
    enum CodingKeys: String, CodingKey {
        case рабочееДерево = "W", ref, база = "base"
    }
}

struct Дерево: Decodable {
    let oid: String
    enum CodingKeys: String, CodingKey { case oid = "HEAD" }
}

struct Ветка: Decodable {
    let ref: String
    let oid: String
    let oidУдалённого: String?
    let дата: String
    let тема: String
    let независимыйTip: Bool
    let worktrees: [Дерево]
    let актуальность: String
    enum CodingKeys: String, CodingKey {
        case ref, oid, worktrees
        case oidУдалённого = "remoteOID"
        case дата = "date"
        case тема = "subject"
        case независимыйTip = "independentTip"
        case актуальность = "relevance"
    }
}

struct УдалённаяВетка: Decodable { let ref: String; let oid: String }

struct Снимок: Decodable {
    let схема: String
    let наблюдалосьUTC: String
    let корень: Корень
    let локальноНеслитые: [Ветка]
    let удалённыеГоловы: [УдалённаяВетка]
    let независимыеOIDs: [String]
    let интеграция: String
    enum CodingKeys: String, CodingKey {
        case схема = "schema"
        case наблюдалосьUTC = "observedUTC"
        case корень = "root"
        case локальноНеслитые = "localUnmerged"
        case удалённыеГоловы = "remoteHeads"
        case независимыеOIDs = "independentOids"
        case интеграция = "integration"
    }
}

struct Пометка: Decodable {
    let ref: String
    let oid: String
    let направление: String
    let владелец: String
    let полезнаяЧасть: String
    let поглощение: String
    let конфликтИЗависимость: String
    let следующийШаг: String
}

enum ТипПоследующегоИсхода: String, Codable {
    case интегрирован = "SOURCE_INTEGRATED_IN_ROOT_MASTER"
    case частичноИнтегрирован = "SOURCE_PARTIALLY_INTEGRATED_IN_ROOT_MASTER"
}

enum ТипПозднейДиспозиции: String, Codable {
    case отменён = "CANCELLED_DO_NOT_REOPEN"
    case карантин = "QUARANTINED_DO_NOT_REVIEW_INTEGRATE_PUBLISH"
}

struct ПоследующийИсход: Codable {
    let sourceRef: String
    let sourceOID: String
    let result: ТипПоследующегоИсхода
    let scope: String?
    let rootRef: String
    let rootCommit: String
    let rootTree: String
    let rootParents: [String]
    let remoteRef: String
    let remoteOID: String
    let preparedCandidateRef: String?
    let preparedCandidateOID: String?
    let preparedCandidateIsAncestor: Bool?
    let rootReceiptBytes: Int
    let rootReceiptSHA256: String
}

struct ПоздняяДиспозиция: Codable {
    let sourceRef: String
    let sourceOID: String
    let remoteOID: String?
    let result: ТипПозднейДиспозиции
    let nextStep: String
}

struct Аннотации: Decodable {
    let схема: String
    let базаOID: String
    let кандидаты: [Пометка]
    let последующиеИсходы: [ПоследующийИсход]
    let последующиеДиспозиции: [ПоздняяДиспозиция]?
    enum CodingKeys: String, CodingKey {
        case схема = "схема"
        case базаOID = "baseOID"
        case кандидаты
        case последующиеИсходы = "postSnapshotOutcomes"
        case последующиеДиспозиции = "postSnapshotDispositions"
    }
}

struct Запись: Codable {
    let ref: String
    let oid: String
    let источникСреза: String
    let oidRemote: String?
    let baseOID: String
    let датаTip: String
    let темаTip: String
    let состояниеRemote: String
    let независимыйTip: Bool
    let зарегистрированWorktree: Bool
    let worktreeHEADСовпадает: Bool
    let направление: String
    let владелец: String
    let полезнаяЧасть: String
    let поглощение: String
    let конфликтИЗависимость: String
    var следующийОбратныйMerge: String
    let актуальность: String
    var последующийИсход: String?
    var rootMergeOID: String?
    var последующаяДиспозиция: ПоздняяДиспозиция?
}

struct Сводка: Codable {
    let записейВИнвентаре: Int
    let локальныхНеслитыхRefs: Int
    let независимыхTipOIDs: Int
    let неНезависимыхRefs: Int
    let remoteHeads: Int
    let localБезRemote: Int
    let localRemoteРасхождений: Int
    let localRemoteСовпадений: Int
    let refsСWorktree: Int
    let refsСНесовпавшимWorktreeHEAD: Int
    let remoteHeadsВнеЛокальногоСреза: Int
}

struct Реестр: Codable {
    var schema: String
    let sourceSHA256: String
    let observedUTC: String
    let rootRef: String
    let baseOID: String
    let integration: String
    let summary: Сводка
    var branches: [Запись]
    let suggestedCandidates: [Запись]
    var postSnapshotOutcomes: [ПоследующийИсход]
    var postSnapshotDispositions: [ПоздняяДиспозиция]?
}

enum Ошибка: Error, CustomStringConvertible {
    case аргументы, схема, база, хэш, пометки, неверныйПоследующийИсход, невернаяДиспозиция, устаревшийКандидат(String)
    var description: String {
        switch self {
        case .аргументы: return "Соберите Инвентарь-старых-веток.swift через swiftc -parse-as-library, затем передайте --вход или --наложить-на, --база, --аннотации, --ожидаемый-sha256 и --вывод."
        case .схема: return "Неизвестная схема входа или аннотаций"
        case .база: return "База входа, аннотаций и аргумента не совпадает"
        case .хэш: return "SHA-256 входа не совпал с закреплённым значением"
        case .пометки: return "Повторяются ключи или аннотации кандидатов"
        case .неверныйПоследующийИсход: return "Поздний исход не подтверждён точными ref/OID, базой и root readback"
        case .невернаяДиспозиция: return "Поздняя диспозиция не совпала с точными ref/OID/remote или повторяется"
        case let .устаревшийКандидат(ref): return "Точная пара ref/OID аннотации отсутствует во входе: \(ref)"
        }
    }
}

@main
struct ИнвентарьСтарыхВеток {
    static func вычислитьSHA256(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    static func параметры() throws -> [String: String] {
        var результат: [String: String] = [:]
        let допустимыеКлючи: Set<String> = ["--вход", "--наложить-на", "--база", "--аннотации", "--ожидаемый-sha256", "--вывод"]
        var индекс = 1
        while индекс < CommandLine.arguments.count {
            let ключ = CommandLine.arguments[индекс]
            guard допустимыеКлючи.contains(ключ), результат[ключ] == nil, индекс + 1 < CommandLine.arguments.count else { throw Ошибка.аргументы }
            результат[ключ] = CommandLine.arguments[индекс + 1]
            индекс += 2
        }
        let входнойРежим = результат["--вход"] != nil && результат["--наложить-на"] == nil
        let режимНаложения = результат["--наложить-на"] != nil && результат["--вход"] == nil
        guard (входнойРежим || режимНаложения), результат["--база"] != nil,
              результат["--аннотации"] != nil else { throw Ошибка.аргументы }
        if режимНаложения {
            guard результат["--ожидаемый-sha256"] != nil, результат["--вывод"] != nil else { throw Ошибка.аргументы }
        }
        return результат
    }

    static func этоOID(_ значение: String) -> Bool {
        значение.count == 40 && значение.allSatisfy { $0.isHexDigit }
    }

    static func этоSHA256(_ значение: String) -> Bool {
        значение.count == 64 && значение.allSatisfy { $0.isHexDigit }
    }

    static func записать(_ данные: Data, в путь: String) throws {
        try данные.write(to: URL(fileURLWithPath: путь), options: .atomic)
    }

    static func направление(ref: String) -> String {
        let приставка = "refs/heads/"
        guard ref.hasPrefix(приставка) else { return "неопределено" }
        var значение = String(ref.dropFirst(приставка.count))
        if значение.hasPrefix("codex/dir/") { значение = String(значение.dropFirst("codex/dir/".count)) }
        else if значение.hasPrefix("codex/") { значение = String(значение.dropFirst("codex/".count)) }
        return значение
    }

    static func наложитьПоздниеСобытия(_ параметры: [String: String]) throws {
        let байты = try Data(contentsOf: URL(fileURLWithPath: параметры["--наложить-на"]!))
        let хэш = вычислитьSHA256(байты)
        guard хэш == параметры["--ожидаемый-sha256"]! else { throw Ошибка.хэш }
        var реестр = try JSONDecoder().decode(Реестр.self, from: байты)
        let аннотации = try JSONDecoder().decode(Аннотации.self, from: Data(contentsOf: URL(fileURLWithPath: параметры["--аннотации"]!)))
        let база = параметры["--база"]!

        guard реестр.schema == "fum.old-branches-inventory.v2",
              реестр.sourceSHA256 == "a2bf5bf913b533178ac930845de7e4b73bcbbedcdbf43a68cbf9f57cef2ec368",
              аннотации.схема == "fum.old-branches-owner-review.v3" else { throw Ошибка.схема }
        guard реестр.baseOID == база, база == "4a2375a4dcbe1495b5afe520185795a00acaff9b",
              аннотации.базаOID == база else { throw Ошибка.база }

        let ключиЗаписей = реестр.branches.map { $0.ref + "\u{0}" + $0.oid }
        guard Set(ключиЗаписей).count == ключиЗаписей.count else { throw Ошибка.схема }
        let записи = Dictionary(uniqueKeysWithValues: реестр.branches.enumerated().map { ($0.element.ref + "\u{0}" + $0.element.oid, $0.offset) })
        let кандидаты = Set(реестр.suggestedCandidates.map { $0.ref + "\u{0}" + $0.oid })
        var предыдущийRoot = база
        var ключиИсходов = Set<String>()
        for исход in аннотации.последующиеИсходы {
            let ключ = исход.sourceRef + "\u{0}" + исход.sourceOID
            guard ключиИсходов.insert(ключ).inserted, записи[ключ] != nil,
                  исход.rootRef == реестр.rootRef,
                  исход.rootParents == [предыдущийRoot, исход.sourceOID],
                  исход.remoteRef == исход.rootRef,
                  исход.remoteOID == исход.rootCommit,
                  этоOID(исход.rootCommit), этоOID(исход.rootTree),
                  исход.rootReceiptBytes > 0, этоSHA256(исход.rootReceiptSHA256) else {
                throw Ошибка.неверныйПоследующийИсход
            }
            switch исход.result {
            case .интегрирован:
                guard исход.scope == nil, исход.preparedCandidateRef != nil,
                      let oidКандидата = исход.preparedCandidateOID, этоOID(oidКандидата),
                      исход.preparedCandidateIsAncestor == false else { throw Ошибка.неверныйПоследующийИсход }
            case .частичноИнтегрирован:
                guard let область = исход.scope, !область.isEmpty,
                      исход.preparedCandidateRef == nil, исход.preparedCandidateOID == nil,
                      исход.preparedCandidateIsAncestor == nil else { throw Ошибка.неверныйПоследующийИсход }
            }
            предыдущийRoot = исход.rootCommit
        }

        let диспозиции = аннотации.последующиеДиспозиции ?? []
        var ключиДиспозиций = Set<String>()
        for диспозиция in диспозиции {
            let ключ = диспозиция.sourceRef + "\u{0}" + диспозиция.sourceOID
            guard ключиДиспозиций.insert(ключ).inserted, let индекс = записи[ключ],
                  диспозиция.remoteOID == реестр.branches[индекс].oidRemote,
                  [.отменён, .карантин].contains(диспозиция.result),
                  !диспозиция.nextStep.isEmpty,
                  !кандидаты.contains(ключ) else { throw Ошибка.невернаяДиспозиция }
        }

        let исходыПоКлючу = Dictionary(uniqueKeysWithValues: аннотации.последующиеИсходы.map { ($0.sourceRef + "\u{0}" + $0.sourceOID, $0) })
        let диспозицииПоКлючу = Dictionary(uniqueKeysWithValues: диспозиции.map { ($0.sourceRef + "\u{0}" + $0.sourceOID, $0) })
        for индекс in реестр.branches.indices {
            let ключ = реестр.branches[индекс].ref + "\u{0}" + реестр.branches[индекс].oid
            if let исход = исходыПоКлючу[ключ] {
                реестр.branches[индекс].последующийИсход = исход.result.rawValue
                реестр.branches[индекс].rootMergeOID = исход.rootCommit
            }
            if let диспозиция = диспозицииПоКлючу[ключ] {
                реестр.branches[индекс].последующаяДиспозиция = диспозиция
                реестр.branches[индекс].следующийОбратныйMerge = диспозиция.nextStep
            }
        }
        реестр.schema = "fum.old-branches-inventory.v3"
        реестр.postSnapshotOutcomes = аннотации.последующиеИсходы
        реестр.postSnapshotDispositions = диспозиции
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try записать(кодировщик.encode(реестр) + Data([0x0a]), в: параметры["--вывод"]!)
    }

    static func выполнить() throws {
        let параметрыЗапуска = try параметры()
        if параметрыЗапуска["--наложить-на"] != nil {
            try наложитьПоздниеСобытия(параметрыЗапуска)
            return
        }
        let исходныеБайты = try Data(contentsOf: URL(fileURLWithPath: параметрыЗапуска["--вход"]!))
        let хэшИсточника = вычислитьSHA256(исходныеБайты)
        if let ожидаемыйХэш = параметрыЗапуска["--ожидаемый-sha256"], ожидаемыйХэш != хэшИсточника { throw Ошибка.хэш }
        let снимок = try JSONDecoder().decode(Снимок.self, from: исходныеБайты)
        let аннотации = try JSONDecoder().decode(Аннотации.self, from: Data(contentsOf: URL(fileURLWithPath: параметрыЗапуска["--аннотации"]!)))
        let база = параметрыЗапуска["--база"]!
        guard снимок.схема == "fum.old-branches-observation.v1",
              ["fum.old-branches-owner-review.v2", "fum.old-branches-owner-review.v3"].contains(аннотации.схема) else { throw Ошибка.схема }
        guard снимок.корень.база == база, аннотации.базаOID == база else { throw Ошибка.база }

        guard Set(снимок.локальноНеслитые.map(\.ref)).count == снимок.локальноНеслитые.count,
              Set(снимок.удалённыеГоловы.map(\.ref)).count == снимок.удалённыеГоловы.count else { throw Ошибка.схема }
        let ключиВеток = Set(снимок.локальноНеслитые.map { $0.ref + "\u{0}" + $0.oid })
        for пометка in аннотации.кандидаты where !ключиВеток.contains(пометка.ref + "\u{0}" + пометка.oid) {
            throw Ошибка.устаревшийКандидат(пометка.ref)
        }
        let ключиПометок = аннотации.кандидаты.map { $0.ref + "\u{0}" + $0.oid }
        guard Set(ключиПометок).count == ключиПометок.count else { throw Ошибка.пометки }
        let парыИсходов = аннотации.последующиеИсходы.map { $0.sourceRef + "\u{0}" + $0.sourceOID }
        guard Set(парыИсходов).count == парыИсходов.count else { throw Ошибка.неверныйПоследующийИсход }
        let парыСнимка = Set(снимок.локальноНеслитые.map { $0.ref + "\u{0}" + $0.oid } + снимок.удалённыеГоловы.map { $0.ref + "\u{0}" + $0.oid })
        var предыдущийRoot = база
        for исход in аннотации.последующиеИсходы {
            guard парыСнимка.contains(исход.sourceRef + "\u{0}" + исход.sourceOID),
                  исход.rootRef == снимок.корень.ref,
                  исход.rootParents == [предыдущийRoot, исход.sourceOID],
                  исход.remoteRef == исход.rootRef,
                  исход.remoteOID == исход.rootCommit,
                  исход.rootReceiptBytes > 0,
                  этоSHA256(исход.rootReceiptSHA256),
                  этоOID(исход.rootTree), этоOID(исход.rootCommit) else { throw Ошибка.неверныйПоследующийИсход }
            switch исход.result {
            case .интегрирован:
                guard исход.scope == nil, let oidКандидата = исход.preparedCandidateOID,
                      этоOID(oidКандидата), исход.preparedCandidateRef != nil,
                      исход.preparedCandidateIsAncestor == false else { throw Ошибка.неверныйПоследующийИсход }
            case .частичноИнтегрирован:
                guard let область = исход.scope, !область.isEmpty,
                      исход.preparedCandidateRef == nil, исход.preparedCandidateOID == nil,
                      исход.preparedCandidateIsAncestor == nil else { throw Ошибка.неверныйПоследующийИсход }
            }
            предыдущийRoot = исход.rootCommit
        }
        let диспозиции = аннотации.последующиеДиспозиции ?? []
        let ключиДиспозиций = диспозиции.map { $0.sourceRef + "\u{0}" + $0.sourceOID }
        guard Set(ключиДиспозиций).count == ключиДиспозиций.count,
              диспозиции.allSatisfy({
                  парыСнимка.contains($0.sourceRef + "\u{0}" + $0.sourceOID)
                      && [.отменён, .карантин].contains($0.result)
                      && !$0.nextStep.isEmpty
              }) else { throw Ошибка.невернаяДиспозиция }
        let пометки = Dictionary(uniqueKeysWithValues: аннотации.кандидаты.map { ($0.ref + "\u{0}" + $0.oid, $0) })
        let исходы = Dictionary(uniqueKeysWithValues: аннотации.последующиеИсходы.map { ($0.sourceRef + "\u{0}" + $0.sourceOID, $0) })
        let диспозицииПоКлючу = Dictionary(uniqueKeysWithValues: диспозиции.map { ($0.sourceRef + "\u{0}" + $0.sourceOID, $0) })
        let независимыеOIDs = Set(снимок.независимыеOIDs)
        let удалённыеПоRef = Dictionary(uniqueKeysWithValues: снимок.удалённыеГоловы.map { ($0.ref, $0.oid) })
        let локальныеЗаписи = снимок.локальноНеслитые.sorted { $0.ref < $1.ref }.map { ветка -> Запись in
            let ключ = ветка.ref + "\u{0}" + ветка.oid
            let пометка = пометки[ключ]
            let позднийИсход = исходы[ключ]
            let поздняяДиспозиция = диспозицииПоКлючу[ключ]
            let независимая = ветка.независимыйTip && независимыеOIDs.contains(ветка.oid)
            let oidУдалённого = ветка.oidУдалённого ?? удалённыеПоRef[ветка.ref]
            let состояниеRemote: String
            if let удалённый = oidУдалённого { состояниеRemote = удалённый == ветка.oid ? "MATCH" : "DIVERGED" }
            else { состояниеRemote = "NO_SAME_NAME_REMOTE" }
            let совпавшиеДеревья = !ветка.worktrees.isEmpty && ветка.worktrees.allSatisfy { $0.oid == ветка.oid }
            return Запись(
                ref: ветка.ref,
                oid: ветка.oid,
                источникСреза: "LOCAL_UNMERGED",
                oidRemote: oidУдалённого,
                baseOID: база,
                датаTip: ветка.дата,
                темаTip: ветка.тема,
                состояниеRemote: состояниеRemote,
                независимыйTip: независимая,
                зарегистрированWorktree: !ветка.worktrees.isEmpty,
                worktreeHEADСовпадает: совпавшиеДеревья,
                направление: пометка?.направление ?? направление(ref: ветка.ref),
                владелец: пометка?.владелец ?? "UNRESOLVED; owner назначает ROOT",
                полезнаяЧасть: пометка?.полезнаяЧасть ?? "UNREVIEWED; subject — только поисковый сигнал: \(ветка.тема)",
                поглощение: пометка?.поглощение ?? (независимая ? "UNREVIEWED; tip независим по источнику" : "Не независим по источнику; точный поглотивший tip неизвестен"),
                конфликтИЗависимость: пометка?.конфликтИЗависимость ?? "UNREVIEWED",
                следующийОбратныйMerge: поздняяДиспозиция?.nextStep ?? пометка?.следующийШаг ?? "ROOT подтверждает владельца, актуальность и зависимости; до этого merge не назначать",
                актуальность: ветка.актуальность,
                последующийИсход: позднийИсход?.result.rawValue,
                rootMergeOID: позднийИсход?.rootCommit,
                последующаяДиспозиция: поздняяДиспозиция
            )
        }
        let локальныеRefs = Set(снимок.локальноНеслитые.map(\.ref))
        let удалённыеВнеЛокальногоСреза = снимок.удалённыеГоловы.filter { !локальныеRefs.contains($0.ref) }
        let удалённыеЗаписи = удалённыеВнеЛокальногоСреза.map { удалённая -> Запись in
            Запись(
                ref: удалённая.ref,
                oid: удалённая.oid,
                источникСреза: "REMOTE_HEAD_OUTSIDE_LOCAL_UNMERGED_SLICE",
                oidRemote: удалённая.oid,
                baseOID: база,
                датаTip: "UNKNOWN; в снимке remoteHeads нет даты",
                темаTip: "UNKNOWN; в снимке remoteHeads нет темы",
                состояниеRemote: "REMOTE_HEAD_ONLY_IN_THIS_SLICE",
                независимыйTip: независимыеOIDs.contains(удалённая.oid),
                зарегистрированWorktree: false,
                worktreeHEADСовпадает: false,
                направление: направление(ref: удалённая.ref),
                владелец: "UNRESOLVED; owner назначает ROOT",
                полезнаяЧасть: "UNREVIEWED; снимок содержит только remote ref/OID",
                поглощение: "UNREVIEWED; отношение remote tip к базе не проверено этим источником",
                конфликтИЗависимость: "UNREVIEWED",
                следующийОбратныйMerge: "ROOT проверяет актуальность, владельца и ancestry; не считать неслитой веткой без сверки",
                актуальность: "UNREVIEWED; удалённая голова вне локального среза",
                последующийИсход: nil,
                rootMergeOID: nil,
                последующаяДиспозиция: nil
            )
        }
        let записи = (локальныеЗаписи + удалённыеЗаписи).sorted {
            if $0.ref == $1.ref { return $0.источникСреза < $1.источникСреза }
            return $0.ref < $1.ref
        }
        let выбранныеПины = Set(аннотации.кандидаты.map { $0.ref + "\u{0}" + $0.oid })
        let сводка = Сводка(
            записейВИнвентаре: записи.count,
            локальныхНеслитыхRefs: снимок.локальноНеслитые.count,
            независимыхTipOIDs: независимыеOIDs.count,
            неНезависимыхRefs: записи.filter { !$0.независимыйTip }.count,
            remoteHeads: снимок.удалённыеГоловы.count,
            localБезRemote: локальныеЗаписи.filter { $0.oidRemote == nil }.count,
            localRemoteРасхождений: локальныеЗаписи.filter { $0.oidRemote != nil && $0.oidRemote != $0.oid }.count,
            localRemoteСовпадений: локальныеЗаписи.filter { $0.oidRemote == $0.oid }.count,
            refsСWorktree: снимок.локальноНеслитые.filter { !$0.worktrees.isEmpty }.count,
            refsСНесовпавшимWorktreeHEAD: снимок.локальноНеслитые.filter { ветка in
                !ветка.worktrees.isEmpty && !ветка.worktrees.allSatisfy { дерево in дерево.oid == ветка.oid }
            }.count,
            remoteHeadsВнеЛокальногоСреза: удалённыеВнеЛокальногоСреза.count
        )
        let реестр = Реестр(
            schema: аннотации.схема == "fum.old-branches-owner-review.v3" ? "fum.old-branches-inventory.v3" : "fum.old-branches-inventory.v2",
            sourceSHA256: хэшИсточника,
            observedUTC: снимок.наблюдалосьUTC,
            rootRef: снимок.корень.ref,
            baseOID: база,
            integration: снимок.интеграция,
            summary: сводка,
            branches: записи,
            suggestedCandidates: записи.filter { выбранныеПины.contains($0.ref + "\u{0}" + $0.oid) },
            postSnapshotOutcomes: аннотации.последующиеИсходы,
            postSnapshotDispositions: аннотации.схема == "fum.old-branches-owner-review.v3" ? диспозиции : nil
        )
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let данныеВывода = try кодировщик.encode(реестр) + Data([0x0a])
        if let путьВывода = параметрыЗапуска["--вывод"] { try данныеВывода.write(to: URL(fileURLWithPath: путьВывода), options: .atomic) }
        else { FileHandle.standardOutput.write(данныеВывода) }
    }

    static func main() {
        do { try выполнить() }
        catch {
            FileHandle.standardError.write(Data("Ошибка инвентаря: \(error)\n".utf8))
            exit(2)
        }
    }
}
