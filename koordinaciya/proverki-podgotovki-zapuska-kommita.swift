import Foundation
import Testing
@testable import RootAcceptance

private func каноническиеДанныеПроизводителя363<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(value)
}
private func объектПроизводителя363(_ bytes: Data) throws -> [String: Any] {
    guard let value = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else {
        throw ОшибкаПриёмаROOT.отказ("producer-fixture-json")
    }
    return value
}
private func jsonПроизводителя363(_ value: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .withoutEscapingSlashes])
}
private func отказПроизводителя363(_ operation: () throws -> Void) -> Bool {
    do { try operation(); return false }
    catch is ОшибкаПроизводителяПодготовкиКоммита { return true }
    catch is ОтказПодготовкиЗапускаКодекс { return true }
    catch is ОтказПроверкиПубликации { return true }
    catch { return false }
}
private enum СбойЗаписиПроизводителя363: Error { case послеЗаписи }

private struct ФикстураПроизводителя363 {
    static let ROOT = "f0000000-0000-4000-8000-000000000011"
    static let этап = ROOT
    static let L = String(repeating: "a", count: 40)
    static let M = String(repeating: "b", count: 40)
    static let деревоИсточника = String(repeating: "c", count: 40)
    static let деревоКоммита = String(repeating: "d", count: 40)
    static let ref = "refs/heads/codex/producer-fixture-363"
    let основа: СинтетическаяСреда363
    let родитель: URL
    let файлВхода: URL
    let данныеВхода: Data
    let документы: [String: Data]
    let W: String

    static func создать() throws -> Self {
        let base = try СинтетическаяСреда363.создать()
        let originalGrant = try JSONDecoder().decode(ПоручениеПриёмаROOT.self,
            from: Data(contentsOf: base.поручение))
        let parent = base.среда.logs.deletingLastPathComponent()
            .appendingPathComponent("producer-input-" + UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        var documents: [String: Data] = [:]
        func file(_ name: String, _ bytes: Data) throws -> URL {
            let url = parent.appendingPathComponent(name)
            try bytes.write(to: url, options: .withoutOverwriting)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            documents[url.path] = bytes
            return url
        }
        func reference(_ url: URL) throws -> [String: String] {
            if documents[url.path] == nil { documents[url.path] = try Data(contentsOf: url) }
            return ["path": url.path, "sha256": хэшПриёмаROOT(documents[url.path]!)]
        }

        // Синтетическая ограниченная строка; она не удостоверяет реальный клиент.
        let row = try JSONSerialization.data(withJSONObject: [[
            "id": ROOT, "model": "fixture-model", "reasoning_effort": "high",
        ]], options: [.sortedKeys, .withoutEscapingSlashes])
        let pair = try АдаптерRootNativeClientMetadata.построитьКвитанции(
            источникJSON: row, независимоеОжиданиеJSON: row, expectedRootUUID: ROOT)
        let receipt = try file("model-receipt.json", каноническиеДанныеПроизводителя363(pair.фактическая))
        let expectedReceipt = try file("model-expectation.json", каноническиеДанныеПроизводителя363(pair.ожидаемая))
        let title = "Подготовить проверочный запуск"
        let request = "Синтетический запрос производителя.\n"
        let messagePlan = ПланСообщенияКоммита(
            исходныйЗапрос: request, заголовок: title, описание: "Непрозрачное описание фикстуры")
        let identity = ОжидаемаяИдентичностьGit(
            квитанцияВыбораМодели: pair.фактическая,
            ожидаемаяКвитанцияВыбораМодели: pair.ожидаемая, родитель: L)
        let state = СостояниеКоординации(
            схема: "fixture-state", корневойUUID: ROOT, принятаяОснова: L,
            собственныйСтарт: СтартКоординации(реф: ref, oid: L, чистоеДерево: true),
            модельУзла: МодельУзлаКоординации(
                веткаЯвляетсяУзлом: true, собственнаяПамять: "fixture", дочерниеУзлы: [],
                деревоСодержит: [], общаяПамять: "fixture", процесс: "fixture",
                полноеДеревоПовтореноВJSON: false, последнийКоммитВосстановления: nil),
            корневойWorktree: СостояниеКорневогоWorktree(
                реф: ref, oid: L, родители: [L], автор: "fixture", коммитер: "fixture",
                датаАвтора: "0 +0000", корневойUUIDВКоммите: ROOT,
                изменённыеПути: [], новыеПути: [], атрибуцияИсполнителя: "fixture",
                авторСтарогоИзменённогоПути: "fixture", поручениеИПолномочия: "fixture",
                диагноз: "fixture", текущаяЗаписьВЭтойОбластиЗапрещена: true),
            задачи: [], переходыСостояния: [], поставки: [], переходыАвтоматизации: [],
            снимокБалансировки: nil, пакетыПоручений: nil, точныеГрязныеПути: nil,
            точныеГрязныеПутиПолноеПокрытие: nil,
            планСамообновления: ПланСамообновления(
                собственныйКонтрольныйКоммит: L, собственныйРеф: ref, собственнаяОбласть: "fixture",
                текущаяВерсия: "v1", источники: [], требуетHEADРавныйROOT: false,
                требуетЧтениеROOTJSONL: false, старыйГлобальныйПорогДискаДляИсточникаГиБ: nil,
                идентичностьСледующегоКоммита: identity, сообщениеСледующегоКоммита: messagePlan))
        let stateFile = try file("metadata-state.json", каноническиеДанныеПроизводителя363(state))
        let variables = base.среда.переменные
        let input: [String: Any] = [
            "schema": "fum.codex-commit-producer-input.1",
            "context": [
                "rootUUID": ROOT, "stageUUID": этап, "physicalW": originalGrant.W,
                "fullRef": ref, "head": L, "sourceTree": деревоИсточника,
                "commitTree": деревоКоммита, "parents": [L, M],
            ],
            "message": [
                "title": title, "request": request, "changes": "Создать пакет",
                "checks": "Проверить без запуска процессов", "boundary": "Только синтетическая фикстура",
            ],
            "identity": [
                "authorEmail": "fixture-author@local",
                "authorDate": ["seconds": Int64(1_700_000_000), "offset": "+0000"],
                "committerName": "Fixture Committer", "committerEmail": "fixture-committer@local",
                "committerDate": ["seconds": Int64(1_700_000_000), "offset": "+0000"],
            ],
            "runtime": [
                "metadataExecutable": try reference(URL(fileURLWithPath: base.среда.metadataCLI)),
                "metadataState": try reference(stateFile),
                "definition": try reference(URL(fileURLWithPath: variables["KOORDINACIYA_FUMA_DEFINITION"]!)),
                "operator": try reference(URL(fileURLWithPath: variables["KOORDINACIYA_FUMA_OPERATOR"]!)),
                "privateRunRoot": variables["KOORDINACIYA_FUMA_RUN_ROOT"]!,
                "runtimeRoot": variables["FUM_RUNTIME_ROOT"]!, "memoryRoot": variables["FUM_MEMORY_ROOT"]!,
            ],
            "rootProgram": try reference(URL(fileURLWithPath: base.среда.программа)),
            "modelReceipt": try reference(receipt), "modelExpectation": try reference(expectedReceipt),
            "snapshotUUID": "f0000000-0000-4000-8000-000000000013",
            "observedAtMilliseconds": Int64(1_700_000_000_000),
            "sourceProfile": "verified-client-selection-only", "privateParent": parent.path,
        ]
        let bytes = try jsonПроизводителя363(input)
        let inputFile = try file("input.json", bytes)
        return Self(основа: base, родитель: parent, файлВхода: inputFile,
            данныеВхода: bytes, документы: documents, W: originalGrant.W)
    }

    func доверенный(
        данные: Data? = nil, документы замена: [String: Data]? = nil,
        ROOT: String = ФикстураПроизводителя363.ROOT, этап: String = ФикстураПроизводителя363.этап
    ) throws -> ДоверенныйВходПроизводителяКоммита {
        let bytes = данные ?? данныеВхода
        return try ЧитательВходаПроизводителяКоммита.проверить(
            данныеВхода: bytes, путь: файлВхода.path, sha256: хэшПриёмаROOT(bytes),
            доверенныйROOT: ROOT, доверенныйЭтап: этап, документы: замена ?? документы)
    }
    func пакет(_ name: String) throws -> НепринятыйПакетПодготовкиКоммита {
        try ПроизводительПодготовкиЗапускаКодекс.собрать(
            вход: доверенный(), каталогВыхода: родитель.appendingPathComponent(name).path,
            закреплённыеДокументы: документы)
    }
    func кандидат(_ receipt: КвитанцияСохраненияПакетаПодготовки) throws -> КандидатПодготовкиЗапускаКодекс {
        try ЧитательПодготовкиЗапускаКодекс.загрузить(
            селектор: receipt.селектор.путь, sha256: receipt.селектор.хэш)
    }
    func ожидание(_ name: String, parents: [String], tree: String) throws -> (URL, Data) {
        let bytes = try jsonПроизводителя363([
            "schema": "fum.raw-merge-commit-expectation.1", "expectedParents": parents, "expectedTree": tree,
        ])
        let file = родитель.appendingPathComponent(name)
        try bytes.write(to: file, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        return (file, bytes)
    }
    func среда(
        _ bundle: НепринятыйПакетПодготовкиКоммита,
        _ receipt: КвитанцияСохраненияПакетаПодготовки, допуститьПакет: Bool
    ) throws -> СредаПриёмаROOT {
        var urls = bundle.внешниеПины.map { URL(fileURLWithPath: $0.путь) }
        urls.append(файлВхода)
        urls.append(URL(fileURLWithPath: основа.среда.программа))
        if допуститьПакет {
            for name in bundle.файлы.keys.sorted() {
                urls.append(URL(fileURLWithPath: bundle.каталогВыхода).appendingPathComponent(name))
            }
            urls.append(URL(fileURLWithPath: receipt.манифест.путь))
        }
        // Тестовый узел независимо читает и хэширует принятые байты. Producer не пишет этот допуск.
        var hashes: [String: String] = [:]
        for url in urls { hashes[url.path] = хэшПриёмаROOT(try Data(contentsOf: url)) }
        let pins = hashes.keys.sorted().map { PinПриёмаROOT(путь: $0, sha256: hashes[$0]!) }
        let grant = ПоручениеПриёмаROOT(
            схема: "fum.root-acceptance-program.1", идентификатор: "producer-host-fixture",
            ROOT: Self.ROOT, писатель: Self.этап, W: W, ref: Self.ref,
            origin: "https://github.com/fum-lab/fum.git",
            L: Self.L, M: Self.M, дерево: Self.деревоКоммита, пути: ["synthetic.txt"], pins: pins)
        let bytes = try каноническиеДанныеПроизводителя363(grant)
        let file = родитель.appendingPathComponent("host-grant-" + UUID().uuidString.lowercased() + ".json")
        try bytes.write(to: file, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        return try СредаПриёмаROOT.собрать(
            селектор: receipt.селектор.путь, sha256: receipt.селектор.хэш,
            поручение: file, хэшПоручения: хэшПриёмаROOT(bytes),
            ROOT: Self.ROOT, этап: Self.этап, программа: основа.среда.программа,
            segment: основа.среда.segment, logs: основа.среда.logs)
    }
}

@Suite("Производитель и миграция команд №363", .serialized)
struct ПроверкиПроизводителяПодготовкиКоммита363 {
    @Test func версияЯвнаяБезAmbientИПереключенияProduction() throws {
        let reply = try #require(КомандаПодготовкиЗапускаКоммитаV1.перехватить([
            "--подготовить-запуск-коммита-v1", "--версия",
        ]))
        #expect(reply.код == 0)
        #expect(reply.данные.last == 0x0a)
        let json = try объектПроизводителя363(reply.данные)
        #expect(json["schema"] as? String == "fum.codex-commit-producer-interface.1")
        #expect(json["producerVersion"] as? Int == 1)
        #expect(json["ambientFallback"] as? Bool == false)
        #expect(json["productionSwitch"] as? Bool == false)
        #expect(json["commands"] as? [String] == [
            "--проверить-перед-коммитом", "--сгенерировать-метаданные-коммита",
            "--проверить-сырой-merge-коммит", "--проверить-сырой-коммит", "--проверить-пост-эффектный-git",
        ])
        #expect(КомандаПодготовкиЗапускаКоммитаV1.перехватить(["--другая-команда"]) == nil)
    }

    @Test func неполныйProducerВходНеДополняетсяИзAmbient() throws {
        let fixture = try ФикстураПроизводителя363.создать()
        _ = try fixture.доверенный()
        let changes: [(inout [String: Any]) -> Void] = [
            { $0.removeValue(forKey: "identity") },
            { $0.removeValue(forKey: "modelReceipt") },
            { $0["unknown"] = true },
            { $0["model"] = "ambient-forged-model" },
            { var v = $0["identity"] as! [String: Any]; v["authorEmail"] = "bad\naddress"; $0["identity"] = v },
            { var v = $0["identity"] as! [String: Any]; v["authorDate"] = ["seconds": -1, "offset": "+0000"]; $0["identity"] = v },
            { var v = $0["identity"] as! [String: Any]; v["committerDate"] = ["seconds": 1_700_000_000, "offset": "+2460"]; $0["identity"] = v },
            { var v = $0["runtime"] as! [String: Any]; v["environment"] = ["GIT_AUTHOR_NAME": "forged"]; $0["runtime"] = v },
            { var v = $0["context"] as! [String: Any]; v["parents"] = [ФикстураПроизводителя363.M, ФикстураПроизводителя363.L]; $0["context"] = v },
            { var v = $0["context"] as! [String: Any]; v["stageUUID"] = "f0000000-0000-4000-8000-000000000012"; $0["context"] = v },
            { $0["childContext"] = ["rootUUID": ФикстураПроизводителя363.ROOT, "session": "f0000000-0000-4000-8000-000000000012"] },
        ]
        var trusted = 0
        for change in changes {
            var object = try объектПроизводителя363(fixture.данныеВхода)
            change(&object)
            let data = try jsonПроизводителя363(object)
            #expect(отказПроизводителя363 {
                let input = try fixture.доверенный(данные: data)
                _ = try ПроизводительПодготовкиЗапускаКодекс.собрать(вход: input,
                    каталогВыхода: fixture.родитель.appendingPathComponent("not-created").path,
                    закреплённыеДокументы: fixture.документы)
                trusted += 1
            })
        }
        #expect(отказПроизводителя363 {
            _ = try fixture.доверенный(ROOT: "f0000000-0000-4000-8000-000000000019"); trusted += 1
        })
        #expect(отказПроизводителя363 {
            _ = try fixture.доверенный(этап: "f0000000-0000-4000-8000-000000000019"); trusted += 1
        })
        #expect(trusted == 0)
        #expect(!FileManager.default.fileExists(atPath: fixture.родитель.appendingPathComponent("not-created").path))
    }

    @Test func дрейфStateBodyRuntimeИSourceНеСоздаётПакет() throws {
        let f = try ФикстураПроизводителя363.создать()
        let object = try объектПроизводителя363(f.данныеВхода)
        let runtime = object["runtime"] as! [String: Any]
        let state = runtime["metadataState"] as! [String: String]
        let operation = runtime["operator"] as! [String: String]
        let model = object["modelReceipt"] as! [String: String]
        for path in [state["path"]!, operation["path"]!, model["path"]!] {
            var docs = f.документы
            docs[path]!.append(0x0a)
            #expect(отказПроизводителя363 { _ = try f.доверенный(документы: docs) })
        }
        var missing = f.документы
        missing.removeValue(forKey: model["path"]!)
        #expect(отказПроизводителя363 { _ = try f.доверенный(документы: missing) })
        var body = object
        var message = body["message"] as! [String: Any]
        message["request"] = "Другой запрос"
        body["message"] = message
        #expect(отказПроизводителя363 { _ = try f.доверенный(данные: jsonПроизводителя363(body)) })
        var stateObject = try объектПроизводителя363(f.документы[state["path"]!]!)
        var plan = stateObject["планСамообновления"] as! [String: Any]
        plan["собственныйРеф"] = "refs/heads/codex/foreign-producer"
        stateObject["планСамообновления"] = plan
        let changedState = try jsonПроизводителя363(stateObject)
        var docs = f.документы; docs[state["path"]!] = changedState
        var input = object
        var changedRuntime = runtime
        changedRuntime["metadataState"] = ["path": state["path"]!, "sha256": хэшПриёмаROOT(changedState)]
        input["runtime"] = changedRuntime
        #expect(отказПроизводителя363 {
            _ = try f.доверенный(данные: jsonПроизводителя363(input), документы: docs)
        })
    }

    @Test func пакетНеПринимаетСамСебяИВсеПятьArgvЗакрыты() throws {
        let f = try ФикстураПроизводителя363.создать()
        let bundle = try f.пакет("accepted-by-test-host")
        #expect(bundle.файлы.count == 7)
        let saved = try ПисательПакетаПодготовкиКоммита.сохранить(bundle)
        #expect(saved.принятоROOT == false)
        #expect(saved.источникМоделиАутентифицирован == false)
        #expect(хэшПриёмаROOT(try Data(contentsOf: URL(fileURLWithPath: saved.селектор.путь))) == saved.селектор.хэш)
        #expect(хэшПриёмаROOT(try Data(contentsOf: URL(fileURLWithPath: saved.манифест.путь))) == saved.манифест.хэш)
        do {
            _ = try f.среда(bundle, saved, допуститьПакет: false)
            Issue.record("Непринятый пакет сам добавился в ROOT-допуск")
        } catch ОшибкаПриёмаROOT.отказ(let reason) {
            #expect(reason == "preparation-unadmitted-pin")
        } catch {
            Issue.record("Отказ был до требуемого admission gate: \(error)")
        }
        let env = try f.среда(bundle, saved, допуститьПакет: true)
        #expect(env.переменные["FUM_COMMIT_PREPARATION"] == saved.селектор.путь)
        let c = try f.кандидат(saved)
        let state = c.средаГенератора.состояниеМетаданных.путь
        let expected = try f.ожидание("argv-expectation.json",
            parents: [ФикстураПроизводителя363.L, ФикстураПроизводителя363.M],
            tree: ФикстураПроизводителя363.деревоКоммита)
        let cases: [(ОперацияПодготовленногоКоординатораКодекс, [String])] = [
            (.проверитьПередКоммитом, ["--проверить-перед-коммитом", state]),
            (.сгенерироватьМетаданные, ["--сгенерировать-метаданные-коммита", state]),
            (.проверитьСыройMerge(ожидание: expected.0.path), ["--проверить-сырой-merge-коммит", state, expected.0.path]),
            (.проверитьСыройКоммит(дерево: ФикстураПроизводителя363.деревоКоммита),
                ["--проверить-сырой-коммит", state, ФикстураПроизводителя363.деревоКоммита]),
            (.проверитьПостЭффект(ожидание: expected.0.path), ["--проверить-пост-эффектный-git", state, expected.0.path]),
        ]
        let tail = ["--подготовка-запуска", saved.селектор.путь, "--sha256", saved.селектор.хэш,
            "--root-uuid", ФикстураПроизводителя363.ROOT, "--stage-uuid", ФикстураПроизводителя363.этап]
        for (operation, prefix) in cases {
            let command = try c.командаКоординатора(operation)
            #expect(command.аргументы == prefix + tail)
            #expect(command.окружение["FUM_COMMIT_PREPARATION"] == nil)
            #expect(command.окружение["FUM_COMMIT_PREPARATION_SHA256"] == nil)
            #expect(command.окружение["KOORDINACIYA_FUMA_POISON"] == nil)
            let кандидатРазбора = try РазборПодготовленнойКомандыКодекс.прочитать(command.аргументы)
            let parsed = try #require(кандидатРазбора)
            #expect(parsed.аргументы == prefix)
            #expect(parsed.ROOT == ФикстураПроизводителя363.ROOT)
            #expect(parsed.этап == ФикстураПроизводителя363.этап)
        }
        let proposalText = String(decoding: bundle.предложение, as: UTF8.self)
        #expect(!proposalText.contains("fixture-poison-363"))
    }

    @Test func OEXCLНеПереписываетАНеизвестныйИсходНеПовторяется() throws {
        let f = try ФикстураПроизводителя363.создать()
        let bundle = try f.пакет("no-overwrite")
        let saved = try ПисательПакетаПодготовкиКоммита.сохранить(bundle)
        let before = try Data(contentsOf: URL(fileURLWithPath: saved.манифест.путь))
        let namesBefore = try FileManager.default.contentsOfDirectory(atPath: f.родитель.path).sorted()
        do {
            _ = try ПисательПакетаПодготовкиКоммита.сохранить(bundle)
            Issue.record("Существующий каталог был повторно опубликован")
        } catch ОшибкаПроизводителяПодготовкиКоммита.ужеСуществует {
        } catch { Issue.record("Неверный отказ существующего каталога: \(error)") }
        #expect(try Data(contentsOf: URL(fileURLWithPath: saved.манифест.путь)) == before)
        #expect(try FileManager.default.contentsOfDirectory(atPath: f.родитель.path).sorted() == namesBefore)

        let interrupted = try f.пакет("interrupted")
        do {
            _ = try ПисательПакетаПодготовкиКоммита.сохранить(interrupted,
                операции: ОперацииСозданияПриватногоПакета(послеЗаписи: { _ in
                    throw СбойЗаписиПроизводителя363.послеЗаписи
                }))
            Issue.record("Инъецированный отказ записи не удержан")
        } catch ОшибкаПроизводителяПодготовкиКоммита.неизвестныйИсход(let locator) {
            #expect(!locator.isEmpty)
        } catch { Issue.record("Неизвестный эффект неверно классифицирован: \(error)") }
        #expect(!FileManager.default.fileExists(atPath: interrupted.каталогВыхода))
        let prefix = "." + URL(fileURLWithPath: interrupted.каталогВыхода).lastPathComponent + ".building-"
        let retained = try FileManager.default.contentsOfDirectory(atPath: f.родитель.path).filter { $0.hasPrefix(prefix) }
        #expect(retained.count == 1)
        if let name = retained.first {
            #expect(FileManager.default.fileExists(atPath:
                f.родитель.appendingPathComponent(name).appendingPathComponent("producer-intent.json").path))
        }
        // Не повторяем попытку с неизвестным исходом.
    }

    @Test func rawPositiveПредшествуетТочнымParentTreeОтказамБезПроцессов() throws {
        try проверитьАдресныеRawОтказы363()
    }
}

func проверитьАдресныеRawОтказы363() throws {
    let f = try ФикстураПроизводителя363.создать()
    let bundle = try f.пакет("raw-cases")
    let saved = try ПисательПакетаПодготовкиКоммита.сохранить(bundle)
    let c = try f.кандидат(saved)
    let body = Data(c.ожиданиеСырогоКоммита.путь.телоСообщенияДляПроверкиСырогоКоммита.utf8)
    let raw = сыройКоммитПроверки363(c, body: body)
    let metadata = try метаданныеПроверки363(c)
    let worktreeBefore = try FileManager.default.contentsOfDirectory(atPath: f.W).sorted()
    let other = String(repeating: "e", count: 40)
    let cases: [(String, [String], String, String?, Int)] = [
        ("positive", [ФикстураПроизводителя363.L, ФикстураПроизводителя363.M],
            ФикстураПроизводителя363.деревоКоммита, nil, 1),
        ("first-parent", [ФикстураПроизводителя363.M, ФикстураПроизводителя363.L],
            ФикстураПроизводителя363.деревоКоммита,
            "первый-ожидаемый-родитель-не-совпадает-с-планом", 0),
        ("tree", [ФикстураПроизводителя363.L, ФикстураПроизводителя363.M],
            other, "сырой-tree-не-совпадает-с-ожидаемым", 1),
        ("second-parent", [ФикстураПроизводителя363.L, other],
            ФикстураПроизводителя363.деревоКоммита,
            "сырой-merge-parent-набор-не-совпадает", 1),
    ]
    for (name, parents, tree, error, callbacks) in cases {
        let expectation = try f.ожидание("raw-" + name + ".json", parents: parents, tree: tree)
        let command = try c.командаКоординатора(.проверитьСыройMerge(ожидание: expectation.0.path))
        let кандидатРазбора = try РазборПодготовленнойКомандыКодекс.прочитать(command.аргументы)
            let parsed = try #require(кандидатРазбора)
        var stdinCalls = 0, metadataCalls = 0
        let reply = try ОбработчикСырогоMergeКоординатора.выполнить(
            разбор: parsed, ожидание: expectation.1,
            прочитатьСыройОбъект: { stdinCalls += 1; return raw },
            метаданные: { metadataCalls += 1; return metadata })
        let result = try объектПроизводителя363(reply.данные)
        #expect(stdinCalls == callbacks)
        #expect(metadataCalls == callbacks)
        if let error {
            #expect(reply.код != 0)
            #expect(result["проверено"] as? Bool == false)
            #expect(result["ошибки"] as? [String] == [error])
        } else {
            #expect(reply.код == 0)
            #expect(result["проверено"] as? Bool == true)
            #expect(result["ошибки"] as? [String] == [])
        }
    }
    let full = try c.командаКоординатора(.проверитьСыройMerge(ожидание: "/unused-expectation"))
    let incomplete = Array(full.аргументы.dropLast(8))
    var parsedIncomplete = false
    #expect(отказПроизводителя363 {
        _ = try РазборПодготовленнойКомандыКодекс.прочитать(incomplete)
        parsedIncomplete = true
    })
    #expect(parsedIncomplete == false)
    #expect(try FileManager.default.contentsOfDirectory(atPath: f.W).sorted() == worktreeBefore)
}
