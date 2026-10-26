import Foundation
import Testing
import КонтейнерНаблюдений
@testable import ОсноваЗапуска
@testable import FUMStructuringOperatorMemory

@Suite("Связь квитанции с ответом модели", .serialized)
struct ПроверкиСвязиКвитанцииМодели {
    @Test("корректная сырая квитанция возвращает неизменённый конверт")
    func корректныйОтвет() throws {
        let конверт = try создатьКонверт()
        let данные = try canonicalJSONData(конверт)
        let квитанция = try создатьКвитанцию(для: данные)

        let результат = try СвязьКвитанцииМодели.декодировать(
            квитанция: квитанция,
            данные: данные
        )

        #expect(результат == конверт)
        #expect(результат.proposals.count == 1)
        #expect(результат.proposals[0].status == .hypothesis)
    }

    @Test("предел данных проверяется до размера и хэша квитанции")
    func превышениеПредела() throws {
        let данные = Data(repeating: 0x41, count: 262_145)
        let квитанция = try создатьКвитанцию(размер: 0, хэш: "не-хэш")

        #expect(throws: ОшибкаСвязиКвитанцииМодели.данныеПревышаютПредел) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: квитанция,
                данные: данные
            )
        }
    }

    @Test("несовпадение размера, включая UInt64.max, отклоняется до хэширования")
    func неверныеРазмеры() throws {
        let данные = try каноническиеДанные()
        let сыройХэш = сыройХэшДанных(данные)
        let неверныеРазмеры = [UInt64(данные.count) + 1, UInt64.max]

        for размер in неверныеРазмеры {
            let квитанция = try создатьКвитанцию(размер: размер, хэш: сыройХэш)
            #expect(throws: ОшибкаСвязиКвитанцииМодели.размерНеСовпадает) {
                try СвязьКвитанцииМодели.декодировать(
                    квитанция: квитанция,
                    данные: данные
                )
            }
        }
    }

    @Test("одно-байтовая мутация того же размера нарушает связь сырого хэша")
    func мутацияБайта() throws {
        let данные = try каноническиеДанные()
        let квитанция = try создатьКвитанцию(для: данные)
        var изменённыеДанные = данные
        изменённыеДанные[изменённыеДанные.startIndex] = 0x20

        #expect(изменённыеДанные.count == данные.count)
        #expect(throws: ОшибкаСвязиКвитанцииМодели.хэшНеСовпадает) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: квитанция,
                данные: изменённыеДанные
            )
        }
    }

    @Test("новый порядок ключей и пробелы требуют новой сырой квитанции")
    func порядокКлючейИПробелы() throws {
        let конверт = try создатьКонверт()
        let первыеДанные = try сериализовать(конверт, обратныйПорядок: false)
        let новыеДанные = try сериализовать(конверт, обратныйПорядок: true)
        let стараяКвитанция = try создатьКвитанцию(для: первыеДанные)

        #expect(первыеДанные.count == новыеДанные.count)
        #expect(первыеДанные != новыеДанные)
        #expect(try СвязьКвитанцииМодели.декодировать(
            квитанция: стараяКвитанция,
            данные: первыеДанные
        ) == конверт)
        #expect(throws: ОшибкаСвязиКвитанцииМодели.хэшНеСовпадает) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: стараяКвитанция,
                данные: новыеДанные
            )
        }

        let новаяКвитанция = try создатьКвитанцию(для: новыеДанные)
        #expect(try СвязьКвитанцииМодели.декодировать(
            квитанция: новаяКвитанция,
            данные: новыеДанные
        ) == конверт)
    }

    @Test("хэшОтвета не принимается вместо сырого SHA-256 ответа")
    func хэшОтветаНеСыройХэш() throws {
        let конверт = try создатьКонверт()
        let данные = try canonicalJSONData(конверт)
        let квитанция = try создатьКвитанцию(
            размер: UInt64(данные.count),
            хэш: конверт.responseHash
        )

        #expect(конверт.responseHash.hasPrefix("sha256:"))
        #expect(throws: ОшибкаСвязиКвитанцииМодели.неверныйФорматХэша) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: квитанция,
                данные: данные
            )
        }

        let квитанцияСБольшимиБуквами = try создатьКвитанцию(
            размер: UInt64(данные.count),
            хэш: сыройХэшДанных(данные).uppercased()
        )
        #expect(throws: ОшибкаСвязиКвитанцииМодели.неверныйФорматХэша) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: квитанцияСБольшимиБуквами,
                данные: данные
            )
        }
    }

    @Test("формат сырого хэша отклоняет неверную длину и не-ASCII")
    func неверныйФорматСырогоХэша() throws {
        let данные = try каноническиеДанные()
        let недопустимыеХэши = [
            String(repeating: "a", count: 63),
            String(repeating: "a", count: 65),
            String(repeating: "a", count: 1_000_000),
            String(repeating: "а", count: 32),
        ]

        for хэш in недопустимыеХэши {
            let квитанция = try создатьКвитанцию(
                размер: UInt64(данные.count),
                хэш: хэш
            )
            #expect(throws: ОшибкаСвязиКвитанцииМодели.неверныйФорматХэша) {
                try СвязьКвитанцииМодели.декодировать(
                    квитанция: квитанция,
                    данные: данные
                )
            }
        }
    }

    @Test("только статус hypothesis проходит фасад")
    func статусыТолькоГипотезы() throws {
        let остальныеСтатусы = CandidateStatus.allCases.filter {
            $0 != .hypothesis && $0 != .confirmed
        }

        for (номер, статус) in остальныеСтатусы.enumerated() {
            let профиль = создатьПрофиль(
                идентификатор: "op.llm.automation.status_\(номер)",
                статус: статус
            )
            let конверт = try создатьКонверт(предложения: [профиль])
            let данные = try canonicalJSONData(конверт)
            let квитанция = try создатьКвитанцию(для: данные)
            let декодированный = try RecordedLLMProposalAdapter.decode(data: данные)

            #expect(декодированный.proposals[0].status == статус)
            #expect(throws: ОшибкаСвязиКвитанцииМодели.статусНеГипотеза) {
                try СвязьКвитанцииМодели.декодировать(
                    квитанция: квитанция,
                    данные: данные
                )
            }
        }
    }

    @Test("валидный статус confirmed проходит базовый декодер и отвергается фасадом")
    func подтверждённыйСтатусОтклонёнФасадом() throws {
        let профиль = создатьПрофиль(статус: .confirmed)
        let конверт = try создатьКонверт(предложения: [профиль])
        let данные = try canonicalJSONData(конверт)
        let квитанция = try создатьКвитанцию(для: данные)

        let базовыйРезультат = try RecordedLLMProposalAdapter.decode(data: данные)
        #expect(базовыйРезультат.proposals[0].status == .confirmed)
        #expect(throws: ОшибкаСвязиКвитанцииМодели.статусНеГипотеза) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: квитанция,
                данные: данные
            )
        }
    }

    @Test("базовый декодер сохраняет проверки схемы, происхождения и повторных ID")
    func проверкиБазовогоДекодера() throws {
        let неподдерживаемыйКонверт = try создатьКонверт(версияСхемы: 2)
        let неподдерживаемыеДанные = try canonicalJSONData(неподдерживаемыйКонверт)
        let неподдерживаемаяКвитанция = try создатьКвитанцию(для: неподдерживаемыеДанные)
        #expect(throws: OperatorMemoryError.unsupportedSchema(2)) {
            try RecordedLLMProposalAdapter.decode(data: неподдерживаемыеДанные)
        }
        #expect(throws: OperatorMemoryError.unsupportedSchema(2)) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: неподдерживаемаяКвитанция,
                данные: неподдерживаемыеДанные
            )
        }

        let профильЧеловека = создатьПрофиль(источник: .human)
        let конвертЧеловека = try создатьКонверт(предложения: [профильЧеловека])
        let данныеЧеловека = try canonicalJSONData(конвертЧеловека)
        let квитанцияЧеловека = try создатьКвитанцию(для: данныеЧеловека)
        #expect(throws: OperatorMemoryError.invalidRecordedEnvelope(
            "non-LLM proposal in LLM envelope"
        )) {
            try RecordedLLMProposalAdapter.decode(data: данныеЧеловека)
        }
        #expect(throws: OperatorMemoryError.invalidRecordedEnvelope(
            "non-LLM proposal in LLM envelope"
        )) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: квитанцияЧеловека,
                данные: данныеЧеловека
            )
        }

        let первыйПрофиль = создатьПрофиль()
        let второйПрофиль = создатьПрофиль()
        let конвертСПовтором = try создатьКонверт(
            предложения: [первыйПрофиль, второйПрофиль]
        )
        let данныеСПовтором = try canonicalJSONData(конвертСПовтором)
        let квитанцияСПовтором = try создатьКвитанцию(для: данныеСПовтором)
        #expect(throws: OperatorMemoryError.invalidRecordedEnvelope(
            "duplicate proposal id"
        )) {
            try RecordedLLMProposalAdapter.decode(data: данныеСПовтором)
        }
        #expect(throws: OperatorMemoryError.invalidRecordedEnvelope(
            "duplicate proposal id"
        )) {
            try СвязьКвитанцииМодели.декодировать(
                квитанция: квитанцияСПовтором,
                данные: данныеСПовтором
            )
        }
    }

    @Test(
        "три серии по десять вызовов работают только с Data и квитанцией",
        .enabled(if: ProcessInfo.processInfo.environment["FUM_PROFILE_OUT"] != nil)
    )
    func профильСвязи() throws {
        guard let путь = ProcessInfo.processInfo.environment["FUM_PROFILE_OUT"],
              путь.hasPrefix("/") else {
            Issue.record("Задайте абсолютный путь FUM_PROFILE_OUT вне checkout")
            return
        }

        let конверт = try создатьКонверт()
        let канонические = try canonicalJSONData(конверт)
        let серииДанных: [(String, Data)] = [
            ("канонические байты", канонические),
            ("пробелы после разделителей", try сериализовать(
                конверт,
                обратныйПорядок: false
            )),
            ("обратный порядок и смещённые пробелы", try сериализовать(
                конверт,
                обратныйПорядок: true
            )),
        ]

        struct Серия: Encodable {
            let название: String
            let вызовов: Int
            let размерДанных: Int
            let хэшСырыхБайтов: String
            let хэшОтвета: String
            let наносекунды: UInt64
            let среднееНаносекунд: UInt64
        }

        struct Профиль: Encodable {
            let схема = "fum.профиль-связи-квитанции-модели.1"
            let граница = "Три серии по десять вызовов фасада для неизменных Data и квитанций; только локальный чистый байтовый разбор. Время включает SHA-256 и существующий декодер, не включает подготовку, сборку, процесс, сеть или запись. Нет порогов и вывода о производительности."
            let серии: [Серия]
        }

        let часы = ContinuousClock()
        var результаты: [Серия] = []
        for (название, данные) in серииДанных {
            let квитанция = try создатьКвитанцию(для: данные)
            let начало = часы.now
            var последнийРезультат: RecordedLLMEnvelope?
            for _ in 0..<10 {
                последнийРезультат = try СвязьКвитанцииМодели.декодировать(
                    квитанция: квитанция,
                    данные: данные
                )
            }
            let части = начало.duration(to: часы.now).components
            let всегоНаносекунд = UInt64(части.seconds) * 1_000_000_000
                + UInt64(части.attoseconds / 1_000_000_000)
            #expect(последнийРезультат == конверт)
            результаты.append(Серия(
                название: название,
                вызовов: 10,
                размерДанных: данные.count,
                хэшСырыхБайтов: сыройХэшДанных(данные),
                хэшОтвета: конверт.responseHash,
                наносекунды: всегоНаносекунд,
                среднееНаносекунд: всегоНаносекунд / 10
            ))
        }

        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var отчёт = try кодировщик.encode(Профиль(серии: результаты))
        отчёт.append(0x0a)
        try отчёт.write(to: URL(fileURLWithPath: путь), options: [.withoutOverwriting])
    }
}

private func создатьПрофиль(
    идентификатор: String = "op.llm.automation.normalize_request",
    статус: CandidateStatus = .hypothesis,
    источник: OperatorOrigin = .llm
) -> OperatorProfile {
    OperatorProfile(
        id: идентификатор,
        version: 1,
        stratum: .automation,
        status: статус,
        recognitionPatterns: ["невстречающийся шаблон"],
        generationTemplate: "невстречающийся шаблон",
        language: "ru",
        script: "Cyrl",
        semanticKey: "weak_normalization",
        storageCostBits: 24,
        confidencePpm: 400_000,
        origin: источник,
        positiveExamples: [],
        negativeExamples: []
    )
}

private func создатьКонверт(
    предложения: [OperatorProfile]? = nil,
    версияСхемы: Int = 1
) throws -> RecordedLLMEnvelope {
    let текстЗапроса = "Записанное предложение слабой автоматизации"
    let профили = предложения ?? [создатьПрофиль()]
    return RecordedLLMEnvelope(
        schemaVersion: версияСхемы,
        adapterId: "recorded-weak-automation-v1",
        model: "fixture-llm",
        promptText: текстЗапроса,
        promptHash: sha256Digest(Data(текстЗапроса.utf8)),
        responseHash: sha256Digest(try canonicalJSONData(профили)),
        proposals: профили
    )
}

private struct ВходКвитанции: Encodable {
    let описание: ОписаниеНаблюдения
    let размер: UInt64
    let хэш: String
}

private func создатьКвитанцию(для данные: Data) throws -> Квитанция {
    try создатьКвитанцию(
        размер: UInt64(данные.count),
        хэш: сыройХэшДанных(данные)
    )
}

private func создатьКвитанцию(размер: UInt64, хэш: String) throws -> Квитанция {
    let вход = ВходКвитанции(
        описание: ОписаниеНаблюдения(
            идентификатор: "синтетическая-квитанция",
            тип: "ответ-модели",
            спецификация: Data()
        ),
        размер: размер,
        хэш: хэш
    )
    let байты = try JSONEncoder().encode(вход)
    return try JSONDecoder().decode(Квитанция.self, from: байты)
}

private func каноническиеДанные() throws -> Data {
    try canonicalJSONData(создатьКонверт())
}

private func сыройХэшДанных(_ данные: Data) -> String {
    String(sha256Digest(данные).dropFirst("sha256:".count))
}

private func сериализовать(
    _ конверт: RecordedLLMEnvelope,
    обратныйПорядок: Bool
) throws -> Data {
    let ключи = [
        "schema_version",
        "adapter_id",
        "model",
        "prompt_text",
        "prompt_hash",
        "response_hash",
        "proposals",
    ]
    let значения = [
        "schema_version": String(конверт.schemaVersion),
        "adapter_id": try JSONEncoder().encode(конверт.adapterId).строкаКодировки,
        "model": try JSONEncoder().encode(конверт.model).строкаКодировки,
        "prompt_text": try JSONEncoder().encode(конверт.promptText).строкаКодировки,
        "prompt_hash": try JSONEncoder().encode(конверт.promptHash).строкаКодировки,
        "response_hash": try JSONEncoder().encode(конверт.responseHash).строкаКодировки,
        "proposals": try canonicalJSONData(конверт.proposals).строкаКодировки,
    ]
    let порядок = обратныйПорядок ? Array(ключи.reversed()) : ключи
    let части = try порядок.map { ключ -> String in
        guard let значение = значения[ключ] else {
            throw ОшибкаТестовойФикстуры.нетЗначения
        }
        return "\"\(ключ)\"\(обратныйПорядок ? " :" : ": ")\(значение)"
    }
    let разделитель = обратныйПорядок ? " ," : ", "
    return Data(("{" + части.joined(separator: разделитель) + "}").utf8)
}

private enum ОшибкаТестовойФикстуры: Error {
    case нетЗначения
}

private extension Data {
    var строкаКодировки: String {
        String(decoding: self, as: UTF8.self)
    }
}
