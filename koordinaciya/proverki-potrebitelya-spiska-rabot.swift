import CryptoKit
import Darwin
import Foundation
import Testing
import КонтейнерНаблюдений
@testable import WorklistCaller

private let исходникФикстуры = Data("Исходный worklist; этот текст нельзя заменить статусным ответом.\n".utf8)
private func хэшБайт(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}
private func каталогФикстуры(_ имя: String) throws -> URL {
    let среда = ProcessInfo.processInfo.environment
    let корень = try #require(среда["КАТАЛОГ_ФИКСТУР"])
    let каталог = URL(fileURLWithPath: корень).appendingPathComponent(имя)
    try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false,
                                           attributes: [.posixPermissions: 0o700])
    return каталог
}
private func программаФикстуры() throws -> ПрограммаПотребителяСписка {
    let контекст = try JSONDecoder().decode(КонтекстСписка.self,
        from: Data(try #require(ProcessInfo.processInfo.environment["КОНТЕКСТ_ФИКСТУРЫ"]).utf8))
    let источник = ИсточникСписка(коммит: String(repeating: "a", count: 40), путь: "фикстура/worklist.json", хэш: хэшБайт(исходникФикстуры))
    let работа = ОбязательствоСписка(идентификатор: "ядро", тип: "реализация", критерий: "Принята реализация", действие: "Реализовать")
    let добавка = ОбязательствоСписка(идентификатор: "проверки", тип: "проверки", критерий: "Приняты проверки", действие: "Проверить")
    let область = ОбластьСписка(идентификатор: "caller-fixture", источник: источник,
        оригиналыЧеловека: [String(decoding: исходникФикстуры, as: UTF8.self)], дочерняяПостановка: "Проверить адресный consumer",
        обязательства: [работа], команды: [
            КомандаСписка(идентификатор: "добавить", вид: .уточнить, текст: "Добавить проверки", источник: источник, добавки: [добавка]),
            КомандаСписка(идентификатор: "стоп", вид: .остановить, текст: "STOP", источник: источник)
        ], бюджет: 3, пределЗаписей: 512, полныйОхватПоручения: true)
    return ПрограммаПотребителяСписка(режим: .создать, корневойUUID: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb",
        допуск: ДопускСписка(область: область, контекст: контекст, писатели: [контекст.писатель]),
        наблюдение: контекст, хэшОбласти: try ХранилищеСпискаРабот.хэшОбласти(область), исходныеБайты: исходникФикстуры)
}
private func шаг(_ исходная: ПрограммаПотребителяСписка, _ ответ: ОтветПотребителяСписка,
                 _ событие: СобытиеСписка) -> ПрограммаПотребителяСписка {
    var программа = исходная; программа.режим = .применить; программа.исходныеБайты = nil
    программа.предыдущаяКвитанция = ответ.квитанция; программа.событие = событие
    return программа
}
private func чтение(_ исходная: ПрограммаПотребителяСписка) -> ПрограммаПотребителяСписка {
    var программа = исходная; программа.режим = .прочитать; программа.исходныеБайты = nil
    программа.предыдущаяКвитанция = nil; программа.событие = nil
    return программа
}
private func переносФикстуры(_ исходная: ПрограммаПотребителяСписка, _ ответ: ОтветПотребителяСписка,
                            _ наблюдение: НаблюдениеЭпохи, _ вид: ВидПереносаЭпохи = .тотЖеHEAD,
                            _ имя: String = "epoch", принятыйROOT: String? = nil,
                            отзыв: String? = nil) throws -> (ПрограммаПотребителяСписка, ПоручениеПереносаЭпохи) {
    let эпоха = try #require(ответ.эпоха)
    let поручение = ПоручениеПереносаЭпохи(идентификатор: имя, ROOT: исходная.корневойUUID,
        источник: исходная.допуск.область.источник, worklist: исходная.допуск.область.идентификатор,
        область: исходная.хэшОбласти, предыдущаяКвитанция: ответ.квитанция,
        прежняяЭпоха: try СписокРабот.хэш(эпоха), состояние: try ХранилищеСпискаРабот.хэшСостояния(ответ.состояние),
        вид: вид, принятыйROOT: принятыйROOT, наблюдение: наблюдение,
        запросил: исходная.корневойUUID, отзывПрежнегоПисателя: отзыв)
    var программа = исходная; программа.режим = .перенестиЭпоху; программа.исходныеБайты = nil
    программа.наблюдение = наблюдение.контекст; программа.допуск.контекст = наблюдение.контекст
    программа.допуск.писатели = [наблюдение.контекст.писатель]
    программа.предыдущаяКвитанция = ответ.квитанция; программа.эпоха = поручение.прежняяЭпоха
    программа.перенос = имя; программа.событие = nil
    return (программа, поручение)
}
private func наблюдениеФикстуры(_ программа: ПрограммаПотребителяСписка) -> НаблюдениеЭпохи {
    НаблюдениеЭпохи(контекст: программа.наблюдение, родители: [], код: String(repeating: "c", count: 64),
                   модель: "gpt-6.1-sol", усилие: "ultra")
}
private func текущаяПрограмма(_ исходная: ПрограммаПотребителяСписка, _ ответ: ОтветПотребителяСписка) throws -> ПрограммаПотребителяСписка {
    var p = чтение(исходная); let e = try #require(ответ.эпоха)
    p.наблюдение = e.контекст; p.допуск.контекст = e.контекст; p.допуск.писатели = [e.контекст.писатель]
    p.эпоха = try СписокРабот.хэш(e); p.перенос = nil; return p
}
private func вызватьКоманду(_ программа: ПрограммаПотребителяСписка, _ корень: URL, _ метка: String,
                            сторона: ДовереннаяСторонаЭпохи? = nil, SHA: String? = nil,
                            ожидаемыйКод: Int32 = 0) throws -> ОтветПотребителяСписка {
    let бинарник = try #require(ProcessInfo.processInfo.environment["ПУТЬ_КЛИ_ПОТРЕБИТЕЛЯ"])
    let кодировщик = JSONEncoder(); кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let вход = try кодировщик.encode(программа)
    try вход.write(to: корень.appendingPathComponent(метка + "-input.json"), options: .withoutOverwriting)
    let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: бинарник)
    процесс.arguments = [корень.path]; процесс.currentDirectoryURL = URL(fileURLWithPath: программа.наблюдение.дерево)
    if let сторона {
        let bytes = try кодировщик.encode(сторона), file = корень.appendingPathComponent(метка + "-host.json")
        try bytes.write(to: file, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        процесс.arguments = [корень.path, "--допуск-эпохи", file.path, SHA ?? хэшБайт(bytes)]
    }
    let ввод = Pipe(), вывод = Pipe(), каналОшибок = Pipe()
    процесс.standardInput = ввод; процесс.standardOutput = вывод; процесс.standardError = каналОшибок
    try процесс.run(); try ввод.fileHandleForWriting.write(contentsOf: вход); try ввод.fileHandleForWriting.close()
    let результат = вывод.fileHandleForReading.readDataToEndOfFile()
    let ошибки = каналОшибок.fileHandleForReading.readDataToEndOfFile(); процесс.waitUntilExit()
    try результат.write(to: корень.appendingPathComponent(метка + "-stdout.json"), options: .withoutOverwriting)
    try ошибки.write(to: корень.appendingPathComponent(метка + "-stderr.txt"), options: .withoutOverwriting)
    #expect(процесс.terminationStatus == ожидаемыйКод)
    return try JSONDecoder().decode(ОтветПотребителяСписка.self, from: результат)
}

@Suite(.serialized)
struct ПроверкиДолговечногоПотребителя {
    @Test("Replay32 v2-дельт одним аккумулятором сохраняет полную цепь")
    func восстановлениеОднимАккумулятором() async throws {
        let root = try каталогФикстуры("single-accumulator-32")
        var p = try программаФикстуры(); p.пределСобытий = 64
        let writer = try ХранилищеСпискаРабот(корень: root, программа: p, запись: true, создать: true)
        var before = try await writer.прочитать()
        for i in 0..<32 {
            before = try await writer.принять(шаг(p, before, СобытиеСписка(идентификатор: "delta-\(i)", вид: .наблюдение)))
        }
        await writer.закрыть()
        let start = ContinuousClock.now
        let reader = try ХранилищеСпискаРабот(корень: root, программа: чтение(p), запись: false)
        let after = try await reader.прочитать()
        #expect(after.состояние == before.состояние && after.квитанция == before.квитанция)
        #expect(after.состояние.цепочка.map(\.номер) == Array(0..<32))
        #expect(after.обход?.записей == 33 && after.обход?.дельт == 32 && after.обход?.полныхПроверокЯдра == 1)
        print("ПРОФИЛЬ single-accumulator records=33 deltas=32 elapsed=\(start.duration(to: .now)); COW copies not measured")
        await reader.закрыть()
    }
    @Test("Legacy требует независимого хвоста и не возвращается после V2")
    func эпохаLegacyГраница() async throws {
        struct Legacy: Codable {
            var версия = "fum.координация.checkpoint-списка.1"
            var ядро = СписокРабот.версия
            let программа: ПрограммаПотребителяСписка
            let состояние: СостояниеСписка
            let решение: РешениеСписка?
        }
        for downgrade in [false, true] {
            let root = try каталогФикстуры(downgrade ? "epoch-downgrade" : "epoch-anchored-legacy"), p = try программаФикстуры()
            let h = try ХранилищеСпискаРабот(корень: root, программа: p, запись: true, создать: true)
            var before = try await h.прочитать()
            if downgrade { before = try await h.принять(шаг(p, before, СобытиеСписка(идентификатор: "v2", вид: .наблюдение))) }
            await h.закрыть()
            var request = шаг(p, before, СобытиеСписка(идентификатор: "v1", вид: .наблюдение))
            if downgrade {
                request.событие = СобытиеСписка(идентификатор: "v1", вид: .отменить, команда: "forged")
                request.допуск.область.команды.append(КомандаСписка(идентификатор: "forged", вид: .отменить,
                    текст: "Неавторизованная отмена", источник: p.допуск.область.источник, обязательство: "ядро"))
            }
            let result = try СписокРабот.переход(before.состояние, #require(request.событие), допуск: request.допуск, контекст: request.наблюдение)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            let raw = try encoder.encode(Legacy(программа: request, состояние: result.состояние, решение: result.решение))
            let segment = try Сегмент(кореньДанных: root, запись: true, создать: false)
            let desc = ОписаниеНаблюдения(идентификатор: try СписокРабот.хэш(request), тип: "fum.worklist.checkpoint.1",
                источник: p.хэшОбласти, время: "checkpoint-\(segment.записи.count)", спецификация: Data(СписокРабот.версия.utf8))
            let tail = try segment.добавить(desc, данные: raw); segment.закрыть()
            #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: root, программа: чтение(p), запись: false) }
            let host = ДовереннаяСторонаЭпохи(поручения: [], наблюдение: наблюдениеФикстуры(p), принятыйLegacyХвост: tail)
            if downgrade {
                #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: root, программа: чтение(p), запись: false, сторона: host) }
            } else {
                let restored = try ХранилищеСпискаРабот(корень: root, программа: чтение(p), запись: false, сторона: host)
                #expect(try await restored.прочитать().состояние == result.состояние)
                await restored.закрыть()
            }
        }
    }
    @Test("CLI выбирает grant вне stdin и проверяет actual ordered Git parents/code/native")
    func эпохаCLIДоверенныйПараметр() async throws {
        let каталог = try каталогФикстуры("epoch-cli"); let current = try программаФикстуры()
        let parents = try #require(ProcessInfo.processInfo.environment["РОДИТЕЛИ_ФИКСТУРЫ"]).split(separator: " ").map(String.init)
        #expect(parents.count == 2)
        var p = current; p.наблюдение.коммит = try #require(parents.first); p.допуск.контекст = p.наблюдение
        let h = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
        let before = try await h.прочитать(); await h.закрыть()
        var o = наблюдениеФикстуры(current); o.родители = parents
        o.код = хэшБайт(try Data(contentsOf: URL(fileURLWithPath: #require(ProcessInfo.processInfo.environment["ПУТЬ_КЛИ_ПОТРЕБИТЕЛЯ"]))))
        let pair = try переносФикстуры(p, before, o, .принятоеСлияние, принятыйROOT: parents[1])
        let host = ДовереннаяСторонаЭпохи(поручения: [pair.1], наблюдение: o)
        #expect(throws: (any Error).self) { try вызватьКоманду(pair.0, каталог, "wrong-pin", сторона: host, SHA: String(repeating: "0", count: 64), ожидаемыйКод: 1) }
        let after = try вызватьКоманду(pair.0, каталог, "transfer", сторона: host)
        let restored = try вызватьКоманду(текущаяПрограмма(p, after), каталог, "read", сторона: host)
        #expect(restored.состояние == before.состояние && restored.эпоха?.контекст == current.наблюдение)
        #expect(restored.квитанция == after.квитанция && restored.толькоЧтение)
    }
    @Test("Legacy v1 replay и будущий writer перед grant различаются")
    func эпохаLegacyИPrefix() async throws {
        struct Legacy: Codable {
            var версия = "fum.координация.checkpoint-списка.1"
            var ядро = СписокРабот.версия
            let программа: ПрограммаПотребителяСписка
            let состояние: СостояниеСписка
            let решение: РешениеСписка?
        }
        func bytes<T: Encodable>(_ value: T) throws -> Data {
            let e = JSONEncoder(); e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]; return try e.encode(value)
        }
        func description(_ p: ПрограммаПотребителяСписка, _ n: Int, _ v2: Bool) throws -> ОписаниеНаблюдения {
            ОписаниеНаблюдения(идентификатор: try СписокРабот.хэш(p), тип: v2 ? "fum.worklist.delta.2" : "fum.worklist.checkpoint.1",
                источник: p.хэшОбласти, время: "checkpoint-\(n)", спецификация: Data(СписокРабот.версия.utf8))
        }
        for corrupt in [false, true] {
            let каталог = try каталогФикстуры(corrupt ? "epoch-future-writer" : "epoch-legacy"), p = try программаФикстуры()
            let h = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
            let genesis = try await h.прочитать(); await h.закрыть()
            var event = шаг(p, genesis, СобытиеСписка(идентификатор: "legacy", вид: .наблюдение))
            if corrupt { event.наблюдение.писатель = "11111111-1111-4111-8111-111111111111"; event.допуск.контекст = event.наблюдение; event.допуск.писатели = [event.наблюдение.писатель] }
            let result = try СписокРабот.переход(genesis.состояние, #require(event.событие), допуск: event.допуск, контекст: event.наблюдение)
            let segment = try Сегмент(кореньДанных: каталог, запись: true, создать: false)
            let receipt = try segment.добавить(description(event, 1, false), данные: bytes(Legacy(программа: event, состояние: result.состояние, решение: result.решение)))
            if corrupt {
                var synthetic = genesis; synthetic = ОтветПотребителяСписка(схема: genesis.схема, квитанция: receipt,
                    состояние: result.состояние, первичнаяОбласть: genesis.первичнаяОбласть, исходныеБайты: genesis.исходныеБайты,
                    решение: nil, повтор: false, толькоЧтение: false, эпоха: genesis.эпоха)
                var o = наблюдениеФикстуры(p); o.контекст.писатель = event.наблюдение.писатель
                let pair = try переносФикстуры(p, synthetic, o, отзыв: String(repeating: "a", count: 64))
                let old = try #require(genesis.эпоха)
                let next = ЭпохаСписка(номер: 1, контекст: o.контекст, код: o.код, модель: o.модель, усилие: o.усилие,
                    предыдущая: try СписокРабот.хэш(old), поручение: try СписокРабот.хэш(pair.1))
                let delta = ДельтаСписка(программа: pair.0, эпохаДо: try СписокРабот.хэш(old), снимок: result.состояние.снимок,
                    переход: nil, решение: nil, эпохаПосле: next, поручение: pair.1)
                _ = try segment.добавить(description(pair.0, 2, true), данные: bytes(delta)); segment.закрыть()
                var read = чтение(p); read.наблюдение = o.контекст; read.допуск.контекст = o.контекст
                read.допуск.писатели = [o.контекст.писатель]; read.эпоха = try СписокРабот.хэш(next)
                #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: каталог, программа: read, запись: false,
                    сторона: ДовереннаяСторонаЭпохи(поручения: [pair.1], наблюдение: o, принятыйLegacyХвост: receipt)) }
            } else {
                segment.закрыть()
                let restored = try ХранилищеСпискаРабот(корень: каталог, программа: чтение(p), запись: false,
                    сторона: ДовереннаяСторонаЭпохи(поручения: [], наблюдение: наблюдениеФикстуры(p), принятыйLegacyХвост: receipt))
                let after = try await restored.прочитать()
                #expect(after.состояние == result.состояние && after.обход?.legacyЭлементов == 1 && after.обход?.полныхПроверокЯдра == 1)
                await restored.закрыть()
            }
        }
    }
    @Test("Ordered accepted merge сохраняет первичный scope")
    func эпохаПринятоеСлияние() async throws {
        let каталог = try каталогФикстуры("epoch-merge"), p = try программаФикстуры()
        let h = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
        let before = try await h.прочитать(); var o = наблюдениеФикстуры(p)
        let root = String(repeating: "d", count: 40); o.контекст.коммит = String(repeating: "e", count: 40)
        o.родители = [p.наблюдение.коммит, root]
        let (input, grant) = try переносФикстуры(p, before, o, .принятоеСлияние, принятыйROOT: root)
        var wrong = grant; wrong.наблюдение.родители.reverse()
        await #expect(throws: (any Error).self) { try await h.принять(input, сторона: ДовереннаяСторонаЭпохи(поручения: [wrong], наблюдение: wrong.наблюдение)) }
        let after = try await h.принять(input, сторона: ДовереннаяСторонаЭпохи(поручения: [grant], наблюдение: o))
        #expect(after.состояние == before.состояние && after.первичнаяОбласть == before.первичнаяОбласть)
        #expect(after.исходныеБайты == before.исходныеБайты)
        await h.закрыть()
    }
    @Test("Новая incarnation требует отзыва; replay разрешает прошлых writers только по префиксу")
    func эпохаНоваяIncarnation() async throws {
        let каталог = try каталогФикстуры("epoch-native"), p = try программаФикстуры()
        let h = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
        var before = try await h.прочитать()
        before = try await h.принять(шаг(p, before, СобытиеСписка(идентификатор: "old-status", вид: .наблюдение)))
        var o = наблюдениеФикстуры(p); o.контекст.писатель = "11111111-1111-4111-8111-111111111111"
        let (input, absent) = try переносФикстуры(p, before, o)
        await #expect(throws: (any Error).self) { try await h.принять(input, сторона: ДовереннаяСторонаЭпохи(поручения: [absent], наблюдение: o)) }
        var grant = absent; grant.отзывПрежнегоПисателя = String(repeating: "a", count: 64)
        let host = ДовереннаяСторонаЭпохи(поручения: [grant], наблюдение: o)
        var after = try await h.принять(input, сторона: host)
        let current = try текущаяПрограмма(p, after)
        after = try await h.принять(шаг(current, after, СобытиеСписка(идентификатор: "new-status", вид: .наблюдение)))
        await #expect(throws: (any Error).self) { try await h.принять(шаг(p, after, СобытиеСписка(идентификатор: "old-writer", вид: .наблюдение))) }
        await h.закрыть()
        let read = try текущаяПрограмма(p, after)
        let restored = try ХранилищеСпискаРабот(корень: каталог, программа: read, запись: false, сторона: host)
        let result = try await restored.прочитать()
        #expect(result.состояние == after.состояние && result.обход?.полныхПроверокЯдра == 1)
        #expect(result.состояние.цепочка.map(\.писатель) == [p.наблюдение.писатель, o.контекст.писатель])
        await restored.закрыть()
    }
    @Test("Model/effort и автор решения меняют эпоху, а backend остаётся UNKNOWN")
    func эпохаСменаМодели() async throws {
        let каталог = try каталогФикстуры("epoch-model"), p = try программаФикстуры()
        let h = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
        let before = try await h.прочитать(); var o = наблюдениеФикстуры(p)
        o.модель = "gpt-6.1-terra"; o.усилие = "ultra"
        let (input, grant) = try переносФикстуры(p, before, o)
        let after = try await h.принять(input, сторона: ДовереннаяСторонаЭпохи(поручения: [grant], наблюдение: o))
        #expect(after.состояние == before.состояние && after.эпоха?.модель == "gpt-6.1-terra")
        #expect(after.эпоха?.усилие == "ultra" && after.эпоха?.backend == "UNKNOWN")
        #expect(grant.запросил == p.корневойUUID && before.эпоха?.модель == "UNKNOWN")
        await h.закрыть()
    }
    @Test("Чужой, stale, неподтверждённый grant и запрещённая модель не дают полномочий")
    func эпохаОтказы() async throws {
        let каталог = try каталогФикстуры("epoch-deny"), p = try программаФикстуры()
        let h = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
        let before = try await h.прочитать(), o = наблюдениеФикстуры(p)
        let (input, grant) = try переносФикстуры(p, before, o)
        let invalidRoot = try каталогФикстуры("epoch-invalid-host")
        #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: invalidRoot, программа: p, запись: true, создать: true,
            сторона: ДовереннаяСторонаЭпохи(поручения: [grant, grant], наблюдение: o)) }
        #expect(!FileManager.default.fileExists(atPath: invalidRoot.appendingPathComponent("сегмент.fumobs").path))
        var forged = шаг(p, before, СобытиеСписка(идентификатор: "forged", вид: .отменить, команда: "stdin-only"))
        forged.допуск.область.команды.append(КомандаСписка(идентификатор: "stdin-only", вид: .отменить,
            текст: "Неподтверждённая отмена", источник: p.допуск.область.источник, обязательство: "ядро"))
        await #expect(throws: (any Error).self) { try await h.принять(forged) }
        await #expect(throws: (any Error).self) { try await h.принять(input) }
        var wrong = grant; wrong.ROOT = "22222222-2222-4222-8222-222222222222"
        await #expect(throws: (any Error).self) { try await h.принять(input, сторона: ДовереннаяСторонаЭпохи(поручения: [wrong], наблюдение: o)) }
        wrong = grant; wrong.состояние = String(repeating: "0", count: 64)
        await #expect(throws: (any Error).self) { try await h.принять(input, сторона: ДовереннаяСторонаЭпохи(поручения: [wrong], наблюдение: o)) }
        for model in ["gpt-6-astra", "gpt-5.6-sol", "GPT-5.6-Sol"] {
            var observation = o; observation.модель = model
            let (request, denied) = try переносФикстуры(p, before, observation)
            await #expect(throws: (any Error).self) { try await h.принять(request, сторона: ДовереннаяСторонаЭпохи(поручения: [denied], наблюдение: observation)) }
        }
        var changed = input; changed.допуск.область.команды = []
        await #expect(throws: (any Error).self) { try await h.принять(changed, сторона: ДовереннаяСторонаЭпохи(поручения: [grant], наблюдение: o)) }
        let after = try await h.принять(input, сторона: ДовереннаяСторонаЭпохи(поручения: [grant], наблюдение: o))
        var stale = input; stale.перенос = "other"
        var staleGrant = grant; staleGrant.идентификатор = "other"
        await #expect(throws: (any Error).self) { try await h.принять(stale, сторона: ДовереннаяСторонаЭпохи(поручения: [staleGrant], наблюдение: o)) }
        #expect(after.состояние == before.состояние)
        await h.закрыть()
    }
    @Test("Перенос не закрывает pending intent; STOP сохраняет приоритет")
    func эпохаUnknownИStop() async throws {
        let каталог = try каталогФикстуры("epoch-pending"), p = try программаФикстуры()
        let h = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
        let start = try await h.прочитать()
        let before = try await h.принять(шаг(p, start, СобытиеСписка(идентификатор: "intent", вид: .намерение, попытка: "pending")))
        let o = наблюдениеФикстуры(p), pair = try переносФикстуры(p, before, наблюдениеФикстуры(p))
        let after = try await h.принять(pair.0, сторона: ДовереннаяСторонаЭпохи(поручения: [pair.1], наблюдение: o))
        #expect(after.решение?.вид == .неизвестно && after.состояние == before.состояние)
        let current = try текущаяПрограмма(p, after)
        let retry = try await h.принять(шаг(current, after, СобытиеСписка(идентификатор: "new", вид: .намерение, попытка: "new")))
        #expect(retry.квитанция == after.квитанция && retry.состояние == after.состояние)
        let stop = try await h.принять(шаг(current, after, СобытиеСписка(идентификатор: "stop", вид: .остановить, команда: "стоп")))
        #expect(stop.решение?.вид == .остановлено && stop.состояние.снимок.попытки[0].исходЗаписан == false)
        await h.закрыть()
    }
    @Test("SIMULATED fsync failure переноса: exact resync после потери ответа")
    func эпохаПотерянныйОтвет() async throws {
        let каталог = try каталогФикстуры("epoch-lost"), p = try программаФикстуры()
        let first = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
        let before = try await first.прочитать(); await first.закрыть()
        let o = наблюдениеФикстуры(p), pair = try переносФикстуры(p, before, наблюдениеФикстуры(p))
        let host = ДовереннаяСторонаЭпохи(поручения: [pair.1], наблюдение: o)
        let operations = ФайловыеОперации(запись: ФайловыеОперации.системные.запись, синхронизация: { _ in throw ОшибкаКонтейнера.система(ENOSPC) })
        let failing = try ХранилищеСпискаРабот(корень: каталог, программа: чтение(p), запись: true, операции: operations)
        await #expect(throws: (any Error).self) { try await failing.принять(pair.0, сторона: host) }
        await #expect(throws: (any Error).self) { try await failing.прочитать() }
        await failing.закрыть()
        let reopened = try ХранилищеСпискаРабот(корень: каталог, программа: pair.0, запись: true, сторона: host)
        let observed = try await reopened.прочитать(), after = try await reopened.принять(pair.0, сторона: host)
        #expect(after.повтор && after.квитанция == observed.квитанция && after.эпоха?.номер == 1)
        #expect(after.состояние == before.состояние)
        await reopened.закрыть()
    }
    @Test("Профиль8/16/32: sequential epoch prefix, один полный core replay")
    func эпохаПрофиль() async throws {
        for n in [8, 16, 32] {
            let каталог = try каталогФикстуры("epoch-profile-\(n)"); var p = try программаФикстуры(); p.пределСобытий = 64
            let h = try ХранилищеСпискаРабот(корень: каталог, программа: p, запись: true, создать: true)
            var result = try await h.прочитать(), grants: [ПоручениеПереносаЭпохи] = []
            var o = наблюдениеФикстуры(p)
            for i in 0..<n {
                if i % 2 == 0 {
                    o.усилие = i % 4 == 0 ? "high" : "ultra"
                    let pair = try переносФикстуры(p, result, o, .тотЖеHEAD, "profile-\(i)")
                    grants.append(pair.1)
                    result = try await h.принять(pair.0, сторона: ДовереннаяСторонаЭпохи(поручения: grants, наблюдение: o))
                } else {
                    result = try await h.принять(шаг(текущаяПрограмма(p, result), result, СобытиеСписка(идентификатор: "status-\(i)", вид: .наблюдение)))
                }
            }
            await h.закрыть(); let start = ContinuousClock.now
            let restored = try ХранилищеСпискаРабот(корень: каталог, программа: текущаяПрограмма(p, result), запись: false,
                сторона: ДовереннаяСторонаЭпохи(поручения: grants, наблюдение: o))
            let after = try await restored.прочитать(), counts = try #require(after.обход)
            #expect(counts.записей == n + 1 && counts.переносов == n / 2 && counts.дельт == n / 2)
            #expect(counts.legacyЭлементов == 0 && counts.полныхПроверокЯдра == 1 && after.состояние == result.состояние)
            print("ПРОФИЛЬ epoch N=\(n) records=\(counts.записей) transfers=\(counts.переносов) deltas=\(counts.дельт) core=\(counts.полныхПроверокЯдра) elapsed=\(start.duration(to: .now))")
            await restored.закрыть()
        }
    }
    @Test("ROOT разрешает own commit; поколение и бюджет прежние")
    func эпохаСобственныйКоммит() async throws {
        let каталог = try каталогФикстуры("epoch-own"), программа = try программаФикстуры()
        let хранилище = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        var ответ = try await хранилище.прочитать()
        ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "intent", вид: .намерение, попытка: "own")))
        ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "outcome", вид: .исход, попытка: "own", входНамерения: ответ.состояние.снимок.попытки[0].вход)))
        var наблюдение = наблюдениеФикстуры(программа)
        // Unit-наблюдения задаёт доверенный host; CLI отдельно читает actual Git.
        наблюдение.контекст.коммит = String(repeating: "b", count: 40)
        наблюдение.родители = [программа.наблюдение.коммит]
        let (вход, допуск) = try переносФикстуры(программа, ответ, наблюдение, .собственныйКоммит)
        let после = try await хранилище.принять(вход, сторона: ДовереннаяСторонаЭпохи(поручения: [допуск], наблюдение: наблюдение))
        #expect(после.состояние == ответ.состояние && после.квитанция != ответ.квитанция)
        #expect(после.эпоха?.номер == 1 && после.эпоха?.контекст == наблюдение.контекст)
        #expect(после.состояние.снимок.счётчики.values.contains(1))
        await хранилище.закрыть()
    }
    @Test("Приватный корень данных не может совпадать с checkout даже при0700")
    func кореньДанныхСовпадаетСДеревом() throws {
        let каталог = try каталогФикстуры("data-equals-W")
        var программа = try программаФикстуры()
        программа.наблюдение.дерево = каталог.path
        программа.допуск.контекст = программа.наблюдение
        #expect(throws: (any Error).self) {
            try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        }
        #expect(!FileManager.default.fileExists(atPath: каталог.appendingPathComponent("сегмент.fumobs").path))
    }
    @Test("Принятый worklist переживает статус и RO restart")
    func исходныйОбъёмПослеПерезапуска() async throws {
        let каталог = try каталогФикстуры("status-restart"), программа = try программаФикстуры()
        let хранилище = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        var ответ = try await хранилище.прочитать()
        ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "steer", вид: .уточнить, команда: "добавить")))
        ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "status", вид: .наблюдение, свидетельство: "Как статус?")))
        ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "intent", вид: .намерение, попытка: "1")))
        let вход = try #require(ответ.состояние.снимок.попытки.last?.вход)
        ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "outcome", вид: .исход, попытка: "1", входНамерения: вход)))
        await хранилище.закрыть()
        let восстановленное = try ХранилищеСпискаРабот(корень: каталог, программа: чтение(программа), запись: false)
        let после = try await восстановленное.прочитать()
        #expect(после.состояние == ответ.состояние && после.квитанция == ответ.квитанция)
        #expect(после.первичнаяОбласть.оригиналыЧеловека == программа.допуск.область.оригиналыЧеловека)
        #expect(после.исходныеБайты == исходникФикстуры && после.состояние.снимок.поколение == 1)
        #expect(после.состояние.снимок.счётчики.values.contains(1))
        #expect(после.толькоЧтение && после.решение == nil)
        await восстановленное.закрыть()
    }
    @Test("Отсутствующий checkpoint не создаёт новый genesis")
    func нетСнимкаНетНовогоНачала() throws {
        let каталог = try каталогФикстуры("missing"), программа = try программаФикстуры()
        #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: каталог, программа: чтение(программа), запись: false) }
        #expect(!FileManager.default.fileExists(atPath: каталог.appendingPathComponent("сегмент.fumobs").path))
    }
    @Test("Durable intent без outcome удерживает новый attempt после restart")
    func незавершённоеНамерениеНеПовторяется() async throws {
        let каталог = try каталогФикстуры("pending"), программа = try программаФикстуры()
        let первый = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        let начальный = try await первый.прочитать()
        let намерение = try await первый.принять(шаг(программа, начальный, СобытиеСписка(идентификатор: "intent", вид: .намерение, попытка: "1")))
        await первый.закрыть()
        let второй = try ХранилищеСпискаРабот(корень: каталог, программа: чтение(программа), запись: true)
        let неизвестно = try await второй.прочитать()
        #expect(неизвестно.решение?.вид == .неизвестно)
        let повтор = try await второй.принять(шаг(программа, намерение, СобытиеСписка(идентификатор: "new", вид: .намерение, попытка: "2")))
        #expect(повтор.решение?.вид == .неизвестно && повтор.квитанция == намерение.квитанция)
        #expect(повтор.состояние.снимок.попытки.count == 1 && повтор.состояние == намерение.состояние)
        await второй.закрыть()
    }
    @Test("Повтор после потери ответа возвращает прежнюю квитанцию до нового CAS")
    func тотЖеИсходНеДублируется() async throws {
        let каталог = try каталогФикстуры("duplicate"), программа = try программаФикстуры()
        let хранилище = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        let начало = try await хранилище.прочитать()
        let намерение = try await хранилище.принять(шаг(программа, начало, СобытиеСписка(идентификатор: "intent", вид: .намерение, попытка: "1")))
        let исход = шаг(программа, намерение, СобытиеСписка(идентификатор: "outcome", вид: .исход, попытка: "1", входНамерения: намерение.состояние.снимок.попытки[0].вход))
        let ответ = try await хранилище.принять(исход)
        let повтор = try await хранилище.принять(исход)
        #expect(повтор.повтор && повтор.квитанция == ответ.квитанция && повтор.состояние == ответ.состояние)
        var подмена = исход; подмена.событие?.свидетельство = "Другой payload"
        await #expect(throws: (any Error).self) { try await хранилище.принять(подмена) }
        await хранилище.закрыть()
    }
    @Test("SIMULATED ENOSPC на fsync: UNKNOWN, close/replay, exact re-sync")
    func смоделированныйОтказСинхронизации() async throws {
        let каталог = try каталогФикстуры("simulated-sync"), программа = try программаФикстуры()
        let первый = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        let начало = try await первый.прочитать(); await первый.закрыть()
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
            синхронизация: { _ in throw ОшибкаКонтейнера.система(ENOSPC) })
        let ошибочный = try ХранилищеСпискаРабот(корень: каталог, программа: чтение(программа), запись: true, операции: операции)
        let намерение = шаг(программа, начало, СобытиеСписка(идентификатор: "intent", вид: .намерение, попытка: "1"))
        await #expect(throws: (any Error).self) { try await ошибочный.принять(намерение) }
        await #expect(throws: (any Error).self) { try await ошибочный.прочитать() }
        await ошибочный.закрыть()
        let восстановленный = try ХранилищеСпискаРабот(корень: каталог, программа: чтение(программа), запись: true)
        let до = try await восстановленный.прочитать()
        let подтверждённый = try await восстановленный.принять(намерение)
        #expect(подтверждённый.повтор && подтверждённый.квитанция == до.квитанция)
        #expect(подтверждённый.решение?.вид == .неизвестно && подтверждённый.состояние.снимок.счётчики.isEmpty)
        await восстановленный.закрыть()
    }
    @Test("Stale CAS, writer lock и явная torn-tail fixture не меняют старые байты")
    func ожидаемаяКвитанцияЗамокИПовреждение() async throws {
        let каталог = try каталогФикстуры("tail-lock"), программа = try программаФикстуры()
        let первый = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        let начало = try await первый.прочитать()
        var нетCAS = шаг(программа, начало, СобытиеСписка(идентификатор: "bad", вид: .наблюдение)); нетCAS.предыдущаяКвитанция = nil
        await #expect(throws: (any Error).self) { try await первый.принять(нетCAS) }
        #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: каталог, программа: чтение(программа), запись: true) }
        await первый.закрыть()
        let файл = каталог.appendingPathComponent("сегмент.fumobs")
        let запись = try FileHandle(forWritingTo: файл); try запись.seekToEnd(); try запись.write(contentsOf: Data([1, 2, 3])); try запись.close()
        let байты = try Data(contentsOf: файл)
        #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: каталог, программа: чтение(программа), запись: false) }
        #expect(try Data(contentsOf: файл) == байты)
    }
    @Test("Source bytes, независимый scope, ROOT и native context связаны")
    func привязкиПрограммы() async throws {
        let каталог = try каталогФикстуры("binding"), программа = try программаФикстуры()
        var плохой = программа; плохой.исходныеБайты = Data("подмена".utf8)
        #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: каталог, программа: плохой, запись: true, создать: true) }
        плохой = программа; плохой.наблюдение.писатель = программа.корневойUUID
        #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: каталог, программа: плохой, запись: true, создать: true) }
        let хранилище = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        await хранилище.закрыть()
        плохой = чтение(программа); плохой.хэшОбласти = String(repeating: "0", count: 64)
        #expect(throws: (any Error).self) { try ХранилищеСпискаРабот(корень: каталог, программа: плохой, запись: false) }
    }
    @Test("STOP имеет резерв после обычного лимита и pending intent")
    func резервОстановки() async throws {
        let каталог = try каталогФикстуры("stop"), исходная = try программаФикстуры()
        var программа = исходная; программа.пределСобытий = 3
        let хранилище = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
        var ответ = try await хранилище.прочитать()
        ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "intent", вид: .намерение, попытка: "1")))
        ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "status", вид: .наблюдение)))
        let лишний = шаг(программа, ответ, СобытиеСписка(идентификатор: "limit", вид: .наблюдение))
        await #expect(throws: (any Error).self) { try await хранилище.принять(лишний) }
        let стоп = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "stop", вид: .остановить, команда: "стоп")))
        #expect(стоп.решение?.вид == .остановлено)
        await хранилище.закрыть()
    }
    @Test("Профиль caller N1/2/4; реальные обычные write+fsync")
    func профильПотребителя() async throws {
        for число in [1, 2, 4] {
            let каталог = try каталогФикстуры("profile-\(число)"), программа = try программаФикстуры()
            let хранилище = try ХранилищеСпискаРабот(корень: каталог, программа: программа, запись: true, создать: true)
            var ответ = try await хранилище.прочитать(); let начало = ContinuousClock.now
            for номер in 0..<число {
                ответ = try await хранилище.принять(шаг(программа, ответ, СобытиеСписка(идентификатор: "status-\(номер)", вид: .наблюдение)))
            }
            print("ПРОФИЛЬ caller N=\(число) append+sync=\(начало.duration(to: .now))")
            #expect(ответ.состояние.цепочка.count == число)
            await хранилище.закрыть()
        }
    }
    @Test("Свежий CLI-процесс восстанавливает записанный checkpoint без нового события")
    func перезапускКоманды() throws {
        let каталог = try каталогФикстуры("cli"), программа = try программаФикстуры()
        let начало = try вызватьКоманду(программа, каталог, "create")
        let намерение = try вызватьКоманду(шаг(программа, начало,
            СобытиеСписка(идентификатор: "intent", вид: .намерение, попытка: "1")), каталог, "intent")
        #expect(намерение.решение?.вид == .неизвестно)
        let исход = try вызватьКоманду(шаг(программа, намерение,
            СобытиеСписка(идентификатор: "outcome", вид: .исход, попытка: "1", входНамерения: намерение.состояние.снимок.попытки[0].вход)), каталог, "outcome")
        let снова = try вызватьКоманду(чтение(программа), каталог, "resume")
        #expect(исход.решение?.вид == .продолжить)
        #expect(снова.толькоЧтение && снова.квитанция == исход.квитанция && снова.состояние == исход.состояние)
    }
}
