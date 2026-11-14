import Testing
@testable import FUMProcessProtocol

@Test func каноническийИдентификаторЗапускаСодержитТочныеБайты() throws {
    let текст = "00112233-4455-4677-8899-aabbccddeeff"
    let идентификатор = try #require(ИдентификаторЗапуска(текст))
    #expect(идентификатор.текст == текст)
    #expect(идентификатор.байты == [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x46, 0x77,
                         0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
    let нулевой = try #require(ИдентификаторЗапуска("00000000-0000-0000-0000-000000000000"))
    #expect(нулевой.байты == Array(repeating: UInt8(0), count: 16))
}

@Test func идентификаторЗапускаОтклоняетНеканоническийВвод() {
    for текст in ["", "00112233-4455-4677-8899-aabbccddeef",
                 "00112233-4455-4677-8899-aabbccddeeff0",
                 "00112233-4455-4677-8899-AABBCCDDEEFF",
                 "00112233_4455-4677-8899-aabbccddeeff",
                 "00112233-4455-4677-8899-aabbccddeefg",
                 "00112233-4455-4677-8899-aabbccddeef\0",
                 "００１１２２３３-4455-4677-8899-aabbccddeeff"] {
        #expect(ИдентификаторЗапуска(текст) == nil)
    }
}

@Test func отказДоЗапускаРазрешёнТолькоНовомуПротоколу() throws {
    for версия in ["fum-run-witness.1", "fum-run-witness.2", "fum-run-witness.3",
                   "fum-run-witness.4", "fum-run-witness.5", "fum-run-witness.6"] {
        #expect(try разобратьКомандуДопуска(версия, 0x47) == .запустить)
    }
    #expect(try разобратьКомандуДопуска("fum-run-witness.3", 0x41) == .отклонить)
    #expect(try разобратьКомандуДопуска("fum-run-witness.6", 0x41) == .отклонить)
    for версия in ["fum-run-witness.1", "fum-run-witness.2", "fum-run-witness.4", "fum-run-witness.5"] {
        #expect(throws: ОшибкаПротокола.self) { try разобратьКомандуДопуска(версия, 0x41) }
    }
    #expect(throws: ОшибкаПротокола.self) { try разобратьКомандуДопуска("fum-run-witness.3", 0x43) }
    #expect(throws: ОшибкаПротокола.self) { try разобратьКомандуДопуска("fum-run-witness.7", 0x47) }
}

@Test func отсутствиеТаймАутаОтличаетсяОтСрокаПодготовкиИОчистки() {
    let режим = РежимСрокаНаблюдателя(версия: "fum-run-witness.5", край: "100",
                                      второйПараметр: "5000", сейчас: 10)
    #expect(режим == .безТаймаута(крайПодготовки: 100, бюджетОчистки: 5000))
    #expect(РежимСрокаНаблюдателя(версия: "fum-run-witness.4", край: "100",
                                 второйПараметр: "5100", сейчас: 10)
            == .ограниченный(крайЗапуска: 100, крайОстановки: 5100))
    for (край, бюджет, сейчас) in [("10", "5000", 10), ("0100", "5000", 10),
                                    ("100", "999", 10), ("100", "30001", 10),
                                    ("100", "-1", 10), ("100", "5000", -1)] {
        #expect(РежимСрокаНаблюдателя(версия: "fum-run-witness.5", край: край,
                                     второйПараметр: бюджет, сейчас: Int64(сейчас)) == nil)
    }
    #expect(РежимСрокаНаблюдателя(версия: "fum-run-witness.6", край: "100",
                                 второйПараметр: "5000", сейчас: 10) == режим)
    #expect(РежимСрокаНаблюдателя(версия: "fum-run-witness.7", край: "100",
                                 второйПараметр: "5000", сейчас: 10) == nil)
}

@Test func таймаутЦелиДопускаетсяОтдельноОтПодготовкиИОчистки() throws {
    let режим = РежимСрокаНаблюдателя(версия: "fum-run-witness.6", край: "100",
                                      второйПараметр: "5000", сейчас: 10, длительностьЦели: "17")
    #expect(режим == .сТаймаутом(крайПодготовки: 100, бюджетОчистки: 5000, длительностьЦели: 17))
    for длительность in ["0", "017", "-1", "+1", String(Int64.max - 5100)] {
        #expect(РежимСрокаНаблюдателя(версия: "fum-run-witness.6", край: "100",
                                     второйПараметр: "5000", сейчас: 10, длительностьЦели: длительность) == nil)
    }
    #expect(РежимСрокаНаблюдателя(версия: "fum-run-witness.5", край: "100",
                                 второйПараметр: "5000", сейчас: 10, длительностьЦели: "17") == nil)
    let начало = try КадрНачалаЦели(runID: Array(UInt8(0)...UInt8(15)), anchorPID: 20, targetPID: 21)
    let байты = try начало.байтыСоВременемНачала(0x0102030405060708)
    #expect(байты == [0x46, 0x55, 0x53, 0x32] + Array(начало.encoded().dropFirst(4)) + Array(UInt8(1)...UInt8(8)))
    #expect(throws: ОшибкаПротокола.self) { try начало.байтыСоВременемНачала(-1) }
}

@Test func статусБессрочнойЦелиСодержитМонотонноеВремя() throws {
    let идентификатор = Array(UInt8(0)...UInt8(15))
    let кадр = try КадрСтатусаБессрочнойЦели(идентификатор: идентификатор, статус: 0,
                                             время: 1_234_567)
    let байты = кадр.байты()
    #expect(байты.count == 32)
    #expect(Array(байты.prefix(4)) == [0x46, 0x55, 0x50, 0x32])
    #expect(try КадрСтатусаБессрочнойЦели.разобрать(байты, идентификатор: идентификатор) == кадр)
    #expect(throws: ОшибкаПротокола.self) {
        try КадрСтатусаБессрочнойЦели(идентификатор: идентификатор, статус: 0, время: -1)
    }
    #expect(throws: ОшибкаПротокола.self) {
        try КадрСтатусаБессрочнойЦели.разобрать(Array(байты.dropLast()), идентификатор: идентификатор)
    }
    var неверноеВремя = байты
    неверноеВремя[24] = 0x80
    #expect(throws: ОшибкаПротокола.self) {
        try КадрСтатусаБессрочнойЦели.разобрать(неверноеВремя, идентификатор: идентификатор)
    }
    #expect(throws: ОшибкаПротокола.self) {
        try КадрСтатусаБессрочнойЦели.разобрать(байты, идентификатор: Array(repeating: 0xff, count: 16))
    }
}

@Test func имяИсполнителяДопускаетсяТолькоЯвнымИзолированнымРежимом() throws {
    let идентификатор = "00112233-4455-4677-8899-aabbccddeeff"
    let команда = ["fum-supervisor.4", идентификатор, "3", "none", "run", "none", "--", "sh"]
    #expect(throws: ОшибкаПротокола.self) { try ПараметрыЗапуска(arguments: команда) }
    let допуск = try ПараметрыЗапуска(arguments: команда, разрешитьИмяИсполнителя: true)
    #expect(допуск.targetIndex == 7)
    #expect(допуск.targetEnvironment.contains("PATH=/bin:/usr/bin"))
    for имя in ["", ".", "..", "dir/tool", "../tool"] {
        var неверная = команда
        неверная[7] = имя
        #expect(throws: ОшибкаПротокола.self) { try ПараметрыЗапуска(arguments: неверная, разрешитьИмяИсполнителя: true) }
    }
    var прежняя = команда
    прежняя[0] = "fum-supervisor.3"
    #expect(throws: ОшибкаПротокола.self) { try ПараметрыЗапуска(arguments: прежняя, разрешитьИмяИсполнителя: true) }
}

@Test func каждаяПопыткаЗапускаТребуетНеистёкшийМонотонныйСрок() {
    #expect(разрешенаПопыткаЗапуска(предыдущее: 100, текущее: 100, срок: 105))
    #expect(разрешенаПопыткаЗапуска(предыдущее: 100, текущее: 104, срок: 105))
    #expect(!разрешенаПопыткаЗапуска(предыдущее: 100, текущее: 105, срок: 105))
    #expect(!разрешенаПопыткаЗапуска(предыдущее: 100, текущее: 106, срок: 105))
    #expect(!разрешенаПопыткаЗапуска(предыдущее: 100, текущее: 99, срок: 105))
    #expect(!разрешенаПопыткаЗапуска(предыдущее: 100, текущее: nil, срок: 105))
    #expect(!разрешенаПопыткаЗапуска(предыдущее: -1, текущее: 0, срок: 105))
    #expect(разрешенаПопыткаЗапуска(предыдущее: Int64.max - 1, текущее: Int64.max - 1, срок: Int64.max))
}

@Test func изолированнаяСредаТребуетНовойЯвнойВерсии() throws {
    let id = "00112233-4455-4677-8899-aabbccddeeff"
    let legacy = try ПараметрыЗапуска(arguments: ["fum-supervisor.3", id, "3", "none", "run", "none", "--", "/bin/true"])
    let isolated = try ПараметрыЗапуска(arguments: ["fum-supervisor.4", id, "3", "none", "run", "none", "--", "/bin/true"])
    let base = ["PATH=/bin:/usr/bin", "LC_ALL=C", "GIT_OPTIONAL_LOCKS=0",
                "GIT_NO_LAZY_FETCH=1", "GIT_NO_REPLACE_OBJECTS=1"]
    #expect(legacy.targetEnvironment == base + ["FUM_CHECK_RUN_ID=" + id])
    #expect(isolated.targetEnvironment == base + ["GIT_CONFIG_NOSYSTEM=1", "GIT_CONFIG_GLOBAL=/dev/null",
                                                   "GIT_ATTR_NOSYSTEM=1", "FUM_CHECK_RUN_ID=" + id])
    #expect(legacy.targetIndex == 7 && isolated.targetIndex == 7)
    let legacyPath = try ПараметрыЗапуска(arguments: ["fum-supervisor.3", id, "3", "none", "run", "path",
                                                  "/tmp/тест путь/наблюдения.json", "--", "/bin/true"])
    #expect(legacyPath.targetIndex == 8)
    #expect(legacyPath.targetEnvironment == base + ["FUM_CHECK_RUN_ID=" + id,
                                                     "FUM_CHECK_RUN_OBSERVATIONS_PATH=/tmp/тест путь/наблюдения.json"])
    let legacyProjection = try ПараметрыЗапуска(arguments: ["fum-supervisor.3", id, "3", "none", "projection",
                                                        "none", "--", "/bin/true"])
    #expect(legacyProjection.targetEnvironment == base)
    #expect(try ПараметрыЗапуска.legacySupervisor(arguments: ["fum-supervisor.3", id, "3", "none", "run",
                                                        "none", "--", "/bin/true"]).environmentPolicy == .legacy)
    #expect(throws: ОшибкаПротокола.self) {
        try ПараметрыЗапуска.legacySupervisor(arguments: ["fum-supervisor.4", id, "3", "none", "run",
                                                   "none", "--", "/bin/true"])
    }
    #expect(throws: ОшибкаПротокола.self) {
        try ПараметрыЗапуска(arguments: ["fum-supervisor.4", id, "3", "none", "projection", "none", "--", "/bin/true"])
    }
    #expect(throws: ОшибкаПротокола.self) {
        try ПараметрыЗапуска(arguments: ["fum-supervisor.4", id, "3", "none", "run", "path", "/tmp/events", "--", "/bin/true"])
    }
    #expect(throws: ОшибкаПротокола.self) {
        try ПараметрыЗапуска(arguments: ["fum-supervisor.5", id, "3", "none", "run", "none", "--", "/bin/true"])
    }
}

@Test func спецификацияЗапускаТребуетВерсиюИЯвныйРежимНаблюдений() throws {
    let id = "00112233-4455-4677-8899-aabbccddeeff"
    let run = ["fum-supervisor.3", id, "3", "2,15,30", "run", "path", "/tmp/тест путь/наблюдения.json",
               "--", "/bin/echo", "параметр с пробелом"]
    let withPath = try ПараметрыЗапуска(arguments: run)
    #expect(withPath.observationsPath == "/tmp/тест путь/наблюдения.json")
    #expect(withPath.targetIndex == 8)
    #expect(withPath.signalMask == [2, 15, 30])
    #expect(withPath.includeRunID)
    let projection = try ПараметрыЗапуска(arguments: ["fum-supervisor.3", id, "4", "none", "projection", "none", "--", "/bin/true"])
    #expect(projection.observationsPath == nil)
    #expect(projection.targetIndex == 7)
    #expect(projection.signalMask.isEmpty)
    #expect(!projection.includeRunID)
    let invalid: [[String]] = [
        [], ["fum-supervisor.2", id, "3", "none", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id.uppercased(), "3", "none", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "03", "none", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "2", "none", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "2,2", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "15,2", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "02", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "9", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "17", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "32", "run", "none", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "none", "projection", "path", "/tmp/out", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "none", "run", "path", "relative", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "none", "run", "path", "/tmp/../bad", "--", "/bin/true"],
        ["fum-supervisor.3", id, "3", "none", "run", "none", "--", "relative"],
        ["fum-supervisor.3", id, "3", "none", "run", "none", "--", "/bin/true", "--источник-про"],
        ["fum-supervisor.3", id, "3", "none", "run", "none", "--", "/bin/true", "bad\0arg"],
        ["fum-supervisor.3", id, "3", "none", "run", "none", "/bin/true"],
    ]
    for arguments in invalid {
        #expect(throws: ОшибкаПротокола.self) { try ПараметрыЗапуска(arguments: arguments) }
    }
}

@Test func срокОчисткиОбрабатываетПрерываниеИПереносСекунды() throws {
    let start = try ЗначениеВремени(seconds: 10, nanoseconds: 800_000_000)
    let deadline = try ПредельныйСрокОжидания(start: start)
    let initial = try deadline.remaining(at: start)
    let halfSecond = try ЗначениеВремени(seconds: 0, nanoseconds: 500_000_000)
    #expect(initial == halfSecond)
    let later = try ЗначениеВремени(seconds: 11, nanoseconds: 100_000_000)
    #expect(try deadline.remaining(at: later) == ЗначениеВремени(seconds: 0, nanoseconds: 200_000_000))
    #expect(try deadline.remaining(at: ЗначениеВремени(seconds: 11, nanoseconds: 300_000_000)) == nil)
    #expect(try deadline.remaining(at: ЗначениеВремени(seconds: 12, nanoseconds: 0)) == nil)
    #expect(throws: ОшибкаПротокола.self) {
        try deadline.remaining(at: ЗначениеВремени(seconds: 10, nanoseconds: 799_999_999))
    }
    #expect(throws: ОшибкаПротокола.self) { try ЗначениеВремени(seconds: -1, nanoseconds: 0) }
    #expect(throws: ОшибкаПротокола.self) { try ЗначениеВремени(seconds: 0, nanoseconds: 1_000_000_000) }
    #expect(throws: ОшибкаПротокола.self) {
        try ПредельныйСрокОжидания(start: ЗначениеВремени(seconds: Int64.max, nanoseconds: 800_000_000))
    }
}

@Test func остановкаГруппыНеТеряетОтказИНеПовторяетСигналы() {
    for failed in ["identity", "term", "sleep", "kill"] {
        var calls: [String] = []
        let outcome = попытатьсяОстановитьГруппу(
            isLeader: { calls.append("identity"); return failed != "identity" },
            term: { calls.append("term"); return failed == "term" ? .failure(1) : .success },
            sleep: { calls.append("sleep"); return failed == "sleep" ? .failure(2) : .completed },
            kill: { calls.append("kill"); return failed == "kill" ? .failure(3) : .success }
        )
        switch failed {
        case "identity":
            #expect(outcome == .identity)
            #expect(calls == ["identity"])
        case "term":
            #expect(outcome == .term(1))
            #expect(calls == ["identity", "term"])
        case "sleep":
            #expect(outcome == .sleep(2))
            #expect(calls == ["identity", "term", "sleep"])
        default:
            #expect(outcome == .killReturned(.failure(3)))
            #expect(calls == ["identity", "term", "sleep", "identity", "kill"])
        }
    }
}

@Test func ожиданиеОстановкиПовторяетсяБезПовторнойПосылкиСигналов() {
    var calls: [String] = []
    var sleeps = 0
    let outcome = попытатьсяОстановитьГруппу(
        isLeader: { calls.append("identity"); return true },
        term: { calls.append("term"); return .success },
        sleep: {
            calls.append("sleep")
            sleeps += 1
            return sleeps == 1 ? .recheck : .completed
        },
        kill: { calls.append("kill"); return .success }
    )
    #expect(outcome == .killReturned(.success))
    #expect(calls == ["identity", "term", "sleep", "sleep", "identity", "kill"])
}

@Test func неизвестныйКадрНесётИдентификаторИОтказ() throws {
    let runID: [UInt8] = Array(0..<16)
    let prefix: [UInt8] = [0x46, 0x55, 0x45, 0x31] + runID
    let cases: [(ИсходПопыткиОстановкиГруппы, [UInt8])] = [
        (.identity, [0, 0, 0, 1, 0, 0, 0, 0]),
        (.term(13), [0, 0, 0, 2, 0, 0, 0, 13]),
        (.sleep(4), [0, 0, 0, 3, 0, 0, 0, 4]),
        (.killReturned(.success), [0, 0, 0, 4, 0, 0, 0, 0]),
        (.killReturned(.failure(1)), [0, 0, 0, 4, 0, 0, 0, 1]),
    ]
    for (failure, suffix) in cases {
        let frame = try КадрНеизвестногоИсхода(runID: runID, failure: failure)
        #expect(frame.encoded() == prefix + suffix)
        #expect(try КадрНеизвестногоИсхода.decode(frame.encoded(), expectedRunID: runID) == frame)
    }
    #expect(throws: ОшибкаПротокола.self) { try КадрНеизвестногоИсхода(runID: [0], failure: .identity) }
    let valid = try КадрНеизвестногоИсхода(runID: runID, failure: .term(13)).encoded()
    #expect(throws: ОшибкаПротокола.self) { try КадрНеизвестногоИсхода.decode(Array(valid.dropLast()), expectedRunID: runID) }
    #expect(throws: ОшибкаПротокола.self) { try КадрНеизвестногоИсхода.decode(valid + [0], expectedRunID: runID) }
    #expect(throws: ОшибкаПротокола.self) { try КадрНеизвестногоИсхода.decode(valid, expectedRunID: Array(repeating: 9, count: 16)) }
    var wrongMagic = valid
    wrongMagic[0] = 0
    #expect(throws: ОшибкаПротокола.self) { try КадрНеизвестногоИсхода.decode(wrongMagic, expectedRunID: runID) }
    var wrongStage = valid
    wrongStage[23] = 8
    #expect(throws: ОшибкаПротокола.self) { try КадрНеизвестногоИсхода.decode(wrongStage, expectedRunID: runID) }
    var wrongError = valid
    wrongError[24] = 0xff
    #expect(throws: ОшибкаПротокола.self) { try КадрНеизвестногоИсхода.decode(wrongError, expectedRunID: runID) }
}

@Test func кадрГотовностиПривязанКИдентификаторуЗапуска() throws {
    let runID: [UInt8] = Array(0..<16)
    let frame = try КадрГотовности(runID: runID)
    let bytes = frame.encoded()
    #expect(bytes == [0x46, 0x55, 0x52, 0x31] + runID)
    #expect(try КадрГотовности.decode(bytes, expectedRunID: runID) == frame)
    #expect(throws: ОшибкаПротокола.self) { try КадрГотовности(runID: [0]) }
    #expect(throws: ОшибкаПротокола.self) { try КадрГотовности.decode(Array(bytes.dropLast()), expectedRunID: runID) }
    #expect(throws: ОшибкаПротокола.self) { try КадрГотовности.decode(bytes + [0], expectedRunID: runID) }
    #expect(throws: ОшибкаПротокола.self) { try КадрГотовности.decode(bytes, expectedRunID: Array(repeating: 1, count: 16)) }
    var wrongMagic = bytes
    wrongMagic[0] = 0
    #expect(throws: ОшибкаПротокола.self) { try КадрГотовности.decode(wrongMagic, expectedRunID: runID) }
}

@Test func готовностьЯкоряПривязанаКПроцессуИЗапуску() throws {
    let id: [UInt8] = Array(0..<16)
    let ready = try КадрГотовностиЯкоря(runID: id, pid: 12345)
    let encoded = ready.encoded()
    #expect(encoded == [0x46, 0x55, 0x41, 0x31] + id + [0, 0, 0x30, 0x39])
    #expect(try КадрГотовностиЯкоря.decode(encoded, expectedRunID: id) == ready)
    #expect(throws: ОшибкаПротокола.self) { try КадрГотовностиЯкоря(runID: id, pid: 1) }
    #expect(throws: ОшибкаПротокола.self) { try КадрГотовностиЯкоря.decode(Array(encoded.dropLast()), expectedRunID: id) }
    #expect(throws: ОшибкаПротокола.self) {
        try КадрГотовностиЯкоря.decode(encoded, expectedRunID: Array(repeating: 0, count: 16))
    }
    var invalidPID = encoded
    invalidPID[20] = 0x80
    #expect(throws: ОшибкаПротокола.self) { try КадрГотовностиЯкоря.decode(invalidPID, expectedRunID: id) }
}

@Test func очисткаЯкоряПривязанаКПроцессуИЗапуску() throws {
    let id: [UInt8] = Array(0..<16)
    let frame = try КадрОчисткиЯкоря(runID: id, anchorPID: 12345)
    let bytes = frame.encoded()
    #expect(bytes == [0x46, 0x55, 0x43, 0x31] + id + [0, 0, 0x30, 0x39, 0, 0, 0, 9])
    #expect(try КадрОчисткиЯкоря.decode(bytes, expectedRunID: id, expectedPID: 12345) == frame)
    #expect(throws: ОшибкаПротокола.self) { try КадрОчисткиЯкоря(runID: id, anchorPID: 1) }
    #expect(throws: ОшибкаПротокола.self) { try КадрОчисткиЯкоря.decode(Array(bytes.dropLast()), expectedRunID: id, expectedPID: 12345) }
    #expect(throws: ОшибкаПротокола.self) { try КадрОчисткиЯкоря.decode(bytes, expectedRunID: id, expectedPID: 12346) }
    #expect(throws: ОшибкаПротокола.self) {
        try КадрОчисткиЯкоря.decode(bytes, expectedRunID: Array(repeating: 0, count: 16), expectedPID: 12345)
    }
    var badStatus = bytes
    badStatus[27] = 15
    #expect(throws: ОшибкаПротокола.self) { try КадрОчисткиЯкоря.decode(badStatus, expectedRunID: id, expectedPID: 12345) }
}

@Test func кадрыЦелиСвязаныСПроцессамиИИстечениемВремени() throws {
    let id: [UInt8] = Array(0..<16)
    let start = try КадрНачалаЦели(runID: id, anchorPID: 123, targetPID: 456)
    #expect(try КадрНачалаЦели.decode(start.encoded(), expectedRunID: id, anchorPID: 123) == start)
    #expect(throws: ОшибкаПротокола.self) { try КадрНачалаЦели.decode(start.encoded(), expectedRunID: id, anchorPID: 124) }
    #expect(throws: ОшибкаПротокола.self) { try КадрНачалаЦели(runID: id, anchorPID: 123, targetPID: 123) }
    for timeout in [false, true] {
        let frame = try КадрОчисткиЦели(runID: id, anchorPID: 123, targetPID: 456,
                                           targetStatus: 0x0700, timedOut: timeout)
        let bytes = frame.encoded()
        #expect(bytes.count == 37)
        #expect(try КадрОчисткиЦели.decode(bytes, expectedRunID: id, anchorPID: 123, targetPID: 456) == frame)
        #expect(throws: ОшибкаПротокола.self) {
            try КадрОчисткиЦели.decode(bytes, expectedRunID: id, anchorPID: 123, targetPID: 457)
        }
        var badFlag = bytes
        badFlag[36] = 2
        #expect(throws: ОшибкаПротокола.self) {
            try КадрОчисткиЦели.decode(badFlag, expectedRunID: id, anchorPID: 123, targetPID: 456)
        }
        var badAnchorStatus = bytes
        badAnchorStatus[35] = 15
        #expect(throws: ОшибкаПротокола.self) {
            try КадрОчисткиЦели.decode(badAnchorStatus, expectedRunID: id, anchorPID: 123, targetPID: 456)
        }
    }
    #expect(throws: ОшибкаПротокола.self) {
        try КадрОчисткиЦели(runID: id, anchorPID: 123, targetPID: 456, targetStatus: 0x7f, timedOut: false)
    }
}

@Test func квитанцияПрерыванияСвязанаСКомандойИФактическимСтатусом() throws {
    let id: [UInt8] = Array(0..<16)
    let команды: [(КомандаПрерыванияНаблюдателя, КомандаПрерыванияНаблюдателя)] = [
        (.прервать, .завершить), (.завершить, .прервать)
    ]
    for (команда, другая) in команды {
        let кадр = try КадрОчисткиЦели(runID: id, anchorPID: 123, targetPID: 456,
                                         targetStatus: 0x0700, timedOut: false, прерывание: команда)
        let байты = кадр.encoded()
        #expect(байты.prefix(4).elementsEqual("FUI1".utf8))
        #expect(байты[28..<32].elementsEqual([0, 0, 7, 0]))
        #expect(байты.last == команда.rawValue)
        #expect(try КадрОчисткиЦели.decode(байты, expectedRunID: id, anchorPID: 123,
                                             targetPID: 456, прерывание: команда) == кадр)
        #expect(throws: ОшибкаПротокола.неверныйСтатус) {
            try КадрОчисткиЦели.decode(байты, expectedRunID: id, anchorPID: 123,
                                          targetPID: 456, прерывание: другая)
        }
        #expect(throws: ОшибкаПротокола.неверныйМаркер) {
            try КадрОчисткиЦели.decode(байты, expectedRunID: id, anchorPID: 123, targetPID: 456)
        }
    }
    #expect(throws: ОшибкаПротокола.неверныеАргументы) {
        try КадрОчисткиЦели(runID: id, anchorPID: 123, targetPID: 456,
                               targetStatus: 0x0700, timedOut: true, прерывание: .прервать)
    }
}

@Test func кадрСтатусаПроходитКодированиеИДекодирование() throws {
    let runID: [UInt8] = Array(0..<16)
    let frame = try КадрСтатуса(runID: runID, rawStatus: 0x0700)
    let bytes = frame.encoded()
    #expect(bytes == [0x46, 0x55, 0x50, 0x31] + runID + [0, 0, 7, 0])
    #expect(try КадрСтатуса.decode(bytes, expectedRunID: runID) == frame)
}

@Test func кадрСтатусаОтклоняетОшибочныйВвод() throws {
    let runID: [UInt8] = Array(0..<16)
    let frame = try КадрСтатуса(runID: runID, rawStatus: 0)
    let bytes = frame.encoded()
    #expect(throws: ОшибкаПротокола.self) { try КадрСтатуса(runID: [1], rawStatus: 0) }
    #expect(throws: ОшибкаПротокола.self) { try КадрСтатуса.decode(Array(bytes.dropLast()), expectedRunID: runID) }
    #expect(throws: ОшибкаПротокола.self) { try КадрСтатуса.decode(bytes + [0], expectedRunID: runID) }
    #expect(throws: ОшибкаПротокола.self) { try КадрСтатуса.decode(bytes, expectedRunID: Array(repeating: 9, count: 16)) }
    var wrongMagic = bytes
    wrongMagic[0] = 0
    #expect(throws: ОшибкаПротокола.self) { try КадрСтатуса.decode(wrongMagic, expectedRunID: runID) }
    for raw: Int32 in [-1, 0x7f, 0x80, 0x0101, 0x10000, 32] {
        #expect(throws: ОшибкаПротокола.self) { try КадрСтатуса(runID: runID, rawStatus: raw) }
    }
    for raw: Int32 in [0, 0x0700, 15, 15 | 0x80] {
        let valid = try КадрСтатуса(runID: runID, rawStatus: raw)
        #expect(try КадрСтатуса.decode(valid.encoded(), expectedRunID: runID) == valid)
    }
    var stopped = bytes
    stopped[23] = 0x7f
    #expect(throws: ОшибкаПротокола.self) { try КадрСтатуса.decode(stopped, expectedRunID: runID) }
}

@Test func потеряВладельцаПередЗавершающимСигналомОстанавливаетПопытку() {
    var проверки = 0
    var сигналы: [String] = []
    let итог = попытатьсяОстановитьГруппу(
        isLeader: { проверки += 1; return проверки == 1 },
        term: { сигналы.append("TERM"); return .success },
        sleep: { .completed },
        kill: { сигналы.append("KILL"); return .success }
    )
    #expect(итог == .identity)
    #expect(проверки == 2)
    #expect(сигналы == ["TERM"])
}

@Test func переносПолусекундыСохраняетГраницыИПереполнение() throws {
    let случаи: [(Int64, Int64, Int64)] = [
        (499_999_999, 10, 999_999_999),
        (500_000_000, 11, 0),
        (500_000_001, 11, 1),
        (999_999_999, 11, 499_999_999),
    ]
    for (наносекунды, секундыКонца, наносекундыКонца) in случаи {
        let начало = try ЗначениеВремени(seconds: 10, nanoseconds: наносекунды)
        let срок = try ПредельныйСрокОжидания(start: начало)
        let конец = try ЗначениеВремени(seconds: секундыКонца, nanoseconds: наносекундыКонца)
        let передКонцом = try ЗначениеВремени(
            seconds: наносекундыКонца == 0 ? секундыКонца - 1 : секундыКонца,
            nanoseconds: наносекундыКонца == 0 ? 999_999_999 : наносекундыКонца - 1
        )
        #expect(try срок.remaining(at: начало) == ЗначениеВремени(seconds: 0, nanoseconds: 500_000_000))
        #expect(try срок.remaining(at: передКонцом) == ЗначениеВремени(seconds: 0, nanoseconds: 1))
        #expect(try срок.remaining(at: конец) == nil)
    }
    let последнее = try ЗначениеВремени(seconds: Int64.max, nanoseconds: 499_999_999)
    _ = try ПредельныйСрокОжидания(start: последнее)
    #expect(throws: ОшибкаПротокола.self) {
        try ПредельныйСрокОжидания(start: ЗначениеВремени(seconds: Int64.max, nanoseconds: 500_000_000))
    }
    #expect(throws: ОшибкаПротокола.self) { try ЗначениеВремени(seconds: 0, nanoseconds: -1) }
}

@Test func опораПрежнегоЗамкаРазбираетсяБезНеоднозначныхПутейИЧисел() {
    let исход = ["/private/tmp/fixture/lock", "5", "7", "11", "501", "448"]
    func разобрать(_ поля: [String]) -> ОпораКаталогаПрежнегоЗамка? {
        ОпораКаталогаПрежнегоЗамка(поля[0], поля[1], поля[2], поля[3], поля[4], поля[5], дескрипторСтатуса: 4)
    }
    let опора = разобрать(исход)
    #expect(опора?.путь == исход[0])
    #expect(опора?.дескриптор == 5 && опора?.устройство == 7 && опора?.инод == 11)
    #expect(опора?.владелец == 501 && опора?.режим == 0o700)
    var общий = исход
    общий[4] = "0"
    общий[5] = "1023"
    #expect(разобрать(общий)?.режим == 0o1777)
    for (номер, значение) in [(0, "/"), (0, "относительный"), (0, "/a//b"),
                              (0, "/a/./b"), (0, "/a/../b"), (0, "/a/"),
                              (0, "/a/\0b"), (0, "/" + String(repeating: "x", count: 1023)),
                              (1, "4"), (1, "2"), (1, "05"), (1, "-1"),
                              (2, "01"), (2, "-1"), (3, "0"), (3, "011"),
                              (4, "0501"), (5, "384"), (5, "0448")] {
        var неверный = исход
        неверный[номер] = значение
        #expect(разобрать(неверный) == nil)
    }
}

@Test func проверкаОпорыНеЗапускаетЦельПослеИстеченияИлиВозвратаЧасов() {
    var события: [String] = []
    var часы: Int64 = 950
    var числоЗапусков = 0
    let истёкший = запуститьПослеПроверкиОпоры(
        предыдущее: 950, срок: 1000,
        подтвердить: { события.append("опора"); часы = 1000; return true },
        часы: { события.append("часы"); return часы },
        запуск: { числоЗапусков += 1; return 0 }
    )
    #expect(истёкший?.время == nil)
    #expect(события == ["опора", "часы"] && числоЗапусков == 0)

    let обратныйХод = запуститьПослеПроверкиОпоры(
        предыдущее: 950, срок: 1000, подтвердить: { true }, часы: { 949 },
        запуск: { числоЗапусков += 1; return 0 }
    )
    #expect(обратныйХод?.время == nil && числоЗапусков == 0)
    let нетЧасов = запуститьПослеПроверкиОпоры(
        предыдущее: 950, срок: 1000, подтвердить: { true }, часы: { nil },
        запуск: { числоЗапусков += 1; return 0 }
    )
    #expect(нетЧасов?.время == nil && числоЗапусков == 0)
    события = []
    let плохаяОпора = запуститьПослеПроверкиОпоры(
        предыдущее: 950, срок: 1000, подтвердить: { false },
        часы: { события.append("часы"); return 951 }, запуск: { числоЗапусков += 1; return 0 }
    )
    #expect(плохаяОпора?.время == nil && события.isEmpty && числоЗапусков == 0)
    let допущенный = запуститьПослеПроверкиОпоры(
        предыдущее: 950, срок: 1000, подтвердить: { true }, часы: { 999 },
        запуск: { числоЗапусков += 1; return 17 }
    )
    #expect(допущенный?.время == 999 && допущенный?.результат == 17 && числоЗапусков == 1)
}

@Test func заимствованныйДопускРазбираетТолькоОднозначнуюОпоруБезКоллизий() {
    let исход = ["/tmp/сессия/запрос.DATA", "6", "7", "11", "501", "420"]
    func разобрать(_ поля: [String]) -> ОпораЗаимствованногоДопуска? {
        ОпораЗаимствованногоДопуска(поля[0], поля[1], поля[2], поля[3], поля[4], поля[5],
                                   дескрипторСтатуса: 4, дескрипторКаталога: 5)
    }
    let опора = разобрать(исход)
    #expect(опора?.путь == исход[0] && опора?.дескриптор == 6)
    #expect(опора?.устройство == 7 && опора?.инод == 11 && опора?.владелец == 501 && опора?.режим == 0o644)
    #expect(опора?.переменнаяЦели == "FUM_BORROWED_ADMISSION_FD=6")
    for fd in ["-1", "0", "1", "2", "4", "5", "06", "+6", "2147483648"] {
        var поля = исход
        поля[1] = fd
        #expect(разобрать(поля) == nil)
    }
    for путь in ["", "относительный", "/", "/tmp//x", "/tmp/./x", "/tmp/../x",
                 "/tmp/x/", "/tmp/\0x", "/" + String(repeating: "x", count: 1023)] {
        var поля = исход
        поля[0] = путь
        #expect(разобрать(поля) == nil)
    }
    for (номер, значение) in [(2, "-1"), (2, "07"), (3, "0"), (3, "011"),
                               (4, "-1"), (4, "0501"), (5, "-1"), (5, "0420"), (5, "4096")] {
        var поля = исход
        поля[номер] = значение
        #expect(разобрать(поля) == nil)
    }
    var край = исход
    край[0] = "/" + String(repeating: "x", count: 1022)
    #expect(разобрать(край) != nil)
}
