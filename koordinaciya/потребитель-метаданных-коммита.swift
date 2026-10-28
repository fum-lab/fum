import Foundation
import FUMStructuringOperatorMemory

public struct ПодготовленныйRootNativeClient: Equatable, Sendable {
    public let квитанции: ПараНезависимыхКвитанцийВыбораМодели
    public let публичнаяПроекция: ПубличнаяПроекцияRootNativeClient

    init(
        квитанции: ПараНезависимыхКвитанцийВыбораМодели,
        публичнаяПроекция: ПубличнаяПроекцияRootNativeClient
    ) {
        self.квитанции = квитанции
        self.публичнаяПроекция = публичнаяПроекция
    }
}

public enum ОшибкаПотребителяМетаданныхКоммита: Error, Equatable, Sendable {
    case несовпадающиеКвитанции([String])
}

/// Публичная граница для уже прочитанных native-client metadata.
/// Она не читает SQLite, не объявляет backend-модель и не превращает локальные хэши в аттестацию провайдера.
public enum ПотребительМетаданныхКоммита {
    public static func подготовитьRootNativeClient(
        источникJSON: Data,
        независимоеОжиданиеJSON: Data,
        текущееJSON: Data,
        expectedRootUUID: String
    ) throws -> ПодготовленныйRootNativeClient {
        let квитанции = try АдаптерRootNativeClientMetadata.построитьКвитанции(
            источникJSON: источникJSON,
            независимоеОжиданиеJSON: независимоеОжиданиеJSON,
            expectedRootUUID: expectedRootUUID
        )
        let ошибкиКвитанций = ГенераторМетаданныхКоммита.проверитьReceipt(
            квитанции.фактическая,
            ожидаемый: квитанции.ожидаемая,
            expectedRootUUID: expectedRootUUID
        )
        guard ошибкиКвитанций.isEmpty else {
            throw ОшибкаПотребителяМетаданныхКоммита.несовпадающиеКвитанции(ошибкиКвитанций)
        }
        try АдаптерRootNativeClientMetadata.проверитьДрейф(
            текущееJSON: текущееJSON,
            ожидаемая: квитанции.ожидаемая.свидетельство
        )
        return ПодготовленныйRootNativeClient(
            квитанции: квитанции,
            публичнаяПроекция: ПубличнаяПроекцияRootNativeClient(пара: квитанции)
        )
    }
}

public enum РесурсПакетаМетаданныхКоммита: String, CaseIterable, Sendable {
    case определениеFUMA = "генератор-метаданных"
    case фикстураFUMA = "фикстура-метаданных"
    case свидетельствоОператора = "свидетельство-оператора"
}

public enum ОшибкаРесурсаМетаданныхКоммита: Error, Equatable, Sendable {
    case отсутствует(РесурсПакетаМетаданныхКоммита)
}

public enum РесурсыПакетаМетаданныхКоммита {
    public static func данные(_ ресурс: РесурсПакетаМетаданныхКоммита) throws -> Data {
        guard let адрес = Bundle.module.url(
            forResource: ресурс.rawValue,
            withExtension: "json",
            subdirectory: "fuma"
        ) else {
            throw ОшибкаРесурсаМетаданныхКоммита.отсутствует(ресурс)
        }
        return try Data(contentsOf: адрес, options: [.mappedIfSafe])
    }
}

public enum ОшибкаКомпоновщикаМетаданныхКоммита: Error, Equatable, Sendable {
    case некорректноеСвидетельство([String])
    case некорректныйПлан([String])
    case пустойИдентификаторСлучая
    case результатНеТекст
    case некорректныйВыходFUMA
    case неожиданныйНаборСлучаев
}

/// Типизированный in-process consumer сохранённого определения FUMA.
/// Все поля входа компонуются здесь; вызывающей стороне не нужно копировать metadata-колонки вручную.
public struct КомпоновщикFUMAМетаданныхКоммита: Sendable {
    public init() {}

    public func скомпоновать(
        подготовка: ПодготовленныйRootNativeClient,
        план: ПланСообщенияКоммита,
        идентификаторСлучая: String = "consumer"
    ) throws -> ВыходГенератораGitMetadata {
        let квитанции = подготовка.квитанции
        let свидетельство = квитанции.фактическая.свидетельство
        let ошибки = ГенераторМетаданныхКоммита.проверитьReceipt(
            квитанции.фактическая,
            ожидаемый: квитанции.ожидаемая,
            expectedRootUUID: свидетельство.rootUUID
        )
        guard ошибки.isEmpty else {
            throw ОшибкаКомпоновщикаМетаданныхКоммита.некорректноеСвидетельство(ошибки)
        }
        var ошибкиПлана = ГенераторМетаданныхКоммита.проверитьЗаголовок(план.заголовок)
        if план.описание.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ошибкиПлана.append("пустое-описание-сообщения-коммита")
        }
        if план.исходныйЗапрос.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ошибкиПлана.append("пустой-исходный-запрос-сообщения-коммита")
        }
        guard ошибкиПлана.isEmpty else {
            throw ОшибкаКомпоновщикаМетаданныхКоммита.некорректныйПлан(ошибкиПлана)
        }
        guard !идентификаторСлучая.isEmpty else {
            throw ОшибкаКомпоновщикаМетаданныхКоммита.пустойИдентификаторСлучая
        }

        let вход = ПакетВходаГенератораFUMA(cases: [
            ВходСлучаяГенератораFUMA(
                id: идентификаторСлучая,
                acceptedSelection: свидетельство.selectedValue,
                rootUUID: свидетельство.rootUUID,
                title: план.заголовок,
                description: план.описание,
                rawRequest: план.исходныйЗапрос
            )
        ])
        let пакет = try исполнить(пакет: вход)
        guard пакет.cases.count == 1,
              let случай = пакет.cases.first,
              случай.id == идентификаторСлучая else {
            throw ОшибкаКомпоновщикаМетаданныхКоммита.неожиданныйНаборСлучаев
        }
        return ВыходГенератораGitMetadata(
            environment: случай.environment,
            message: случай.message
        )
    }

    private func исполнить(
        пакет вход: ПакетВходаГенератораFUMA
    ) throws -> ПакетВыходаГенератораFUMA {
        let кодировщик = JSONEncoder()
        кодировщик.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let входJSON = try кодировщик.encode(вход)
        guard let входТекст = String(data: входJSON, encoding: .utf8) else {
            throw ОшибкаКомпоновщикаМетаданныхКоммита.некорректныйВыходFUMA
        }

        let определение = try ОпределениеОператора.разобрать(
            РесурсыПакетаМетаданныхКоммита.данные(.определениеFUMA)
        )
        let наблюдение = try AutomationExecutor.выполнить(определение, вход: .текст(входТекст))
        guard case .текст(let выходТекст) = наблюдение.результат else {
            throw ОшибкаКомпоновщикаМетаданныхКоммита.результатНеТекст
        }
        guard let выходJSON = выходТекст.data(using: .utf8),
              let пакет = try? JSONDecoder().decode(ПакетВыходаГенератораFUMA.self, from: выходJSON) else {
            throw ОшибкаКомпоновщикаМетаданныхКоммита.некорректныйВыходFUMA
        }
        guard пакет.cases.map(\.id) == вход.cases.map(\.id) else {
            throw ОшибкаКомпоновщикаМетаданныхКоммита.неожиданныйНаборСлучаев
        }
        return пакет
    }
}
