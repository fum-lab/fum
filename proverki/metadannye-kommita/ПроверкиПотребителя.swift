import Foundation
import Testing
import МетаданныеКоммита

private let корневойUUID = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"

private func строкаNativeClient(model: String = "gpt-6.1-sol", effort: String = "ultra") -> Data {
    Data("""
    [{"id":"\(корневойUUID)","model":"\(model)","reasoning_effort":"\(effort)"}]
    """.utf8)
}

@Test func внешнийПотребительПолучаетТипизированныйRootПрофиль() throws {
    let исходныеБайты = строкаNativeClient()
    let результат = try ПотребительМетаданныхКоммита.подготовитьRootNativeClient(
        источникJSON: исходныеБайты,
        независимоеОжиданиеJSON: исходныеБайты,
        текущееJSON: исходныеБайты,
        expectedRootUUID: корневойUUID
    )

    #expect(результат.публичнаяПроекция.корневойUUID == корневойUUID)
    #expect(результат.публичнаяПроекция.последнееПодтверждённоеВыбранноеЗначениеКлиента
        == ПараметрыВыбораAPI(model: "gpt-6.1-sol", reasoningEffort: "ultra"))
    #expect(результат.публичнаяПроекция.фактическаяМодельПровайдера == .неизвестно)
    #expect(результат.публичнаяПроекция.идентичностьЗапросаAPI == .недоступен)
    #expect(результат.публичнаяПроекция.идентичностьОтветаAPI == .недоступен)
}

@Test func внешнийПотребительОтвергаетДрейфВыбраннойМодели() throws {
    let исходныеБайты = строкаNativeClient()
    #expect(throws: ОшибкаВыбораNativeClient.дрейфВыбора) {
        try ПотребительМетаданныхКоммита.подготовитьRootNativeClient(
            источникJSON: исходныеБайты,
            независимоеОжиданиеJSON: исходныеБайты,
            текущееJSON: строкаNativeClient(model: "gpt-6-luna", effort: "max"),
            expectedRootUUID: корневойUUID
        )
    }
}

@Test func внешнийПотребительОтвергаетНесовпадающееНезависимоеОжидание() throws {
    let источник = строкаNativeClient(model: "gpt-6-luna", effort: "max")
    let ожидание = строкаNativeClient()
    #expect(throws: ОшибкаПотребителяМетаданныхКоммита.self) {
        try ПотребительМетаданныхКоммита.подготовитьRootNativeClient(
            источникJSON: источник,
            независимоеОжиданиеJSON: ожидание,
            текущееJSON: ожидание,
            expectedRootUUID: корневойUUID
        )
    }
}

@Test func компоновщикОтвергаетПустойПлан() throws {
    let строка = строкаNativeClient()
    let подготовка = try ПотребительМетаданныхКоммита.подготовитьRootNativeClient(
        источникJSON: строка,
        независимоеОжиданиеJSON: строка,
        текущееJSON: строка,
        expectedRootUUID: корневойUUID
    )
    #expect(throws: ОшибкаКомпоновщикаМетаданныхКоммита.self) {
        try КомпоновщикFUMAМетаданныхКоммита().скомпоновать(
            подготовка: подготовка,
            план: ПланСообщенияКоммита(исходныйЗапрос: " ", заголовок: "", описание: "")
        )
    }
}

@Test func пакетЭкспортируетЗакреплённыеFUMAРесурсы() throws {
    let определение = try РесурсыПакетаМетаданныхКоммита.данные(.определениеFUMA)
    let фикстура = try РесурсыПакетаМетаданныхКоммита.данные(.фикстураFUMA)
    let свидетельство = try РесурсыПакетаМетаданныхКоммита.данные(.свидетельствоОператора)

    #expect(ГенераторМетаданныхКоммита.sha256Hex(определение)
        == "c793c3a69405d3c655c70496d0803d4c9a4184b34fc9bbbef2a9950510112d1a")
    #expect(ГенераторМетаданныхКоммита.sha256Hex(фикстура)
        == "679447d7b57e8b13f78dda008f4c2eb80152fa1977c0a517648716418cffec67")
    #expect(ГенераторМетаданныхКоммита.sha256Hex(свидетельство)
        == "6c446aef912b19227773d8ac6a30388a74036e1ac642afdb58badf735c7fbca3")

    let вход = try JSONDecoder().decode(ПакетВходаГенератораFUMA.self, from: фикстура)
    #expect(вход.cases.count == 4)
    let подготовка = try ПотребительМетаданныхКоммита.подготовитьRootNativeClient(
        источникJSON: строкаNativeClient(),
        независимоеОжиданиеJSON: строкаNativeClient(),
        текущееJSON: строкаNativeClient(),
        expectedRootUUID: корневойUUID
    )
    let rootCase = ВходСлучаяГенератораFUMA(
        id: "root-native-client-selection",
        acceptedSelection: подготовка.квитанции.фактическая.свидетельство.selectedValue,
        rootUUID: корневойUUID,
        title: "Использовать выбранную модель клиента",
        description: "Root author берёт последнее подтверждённое значение выбранного клиента; модель backend остаётся неизвестной.",
        rawRequest: " Сохранить exact raw request bytes.\r\n"
    )
    let пакет = ПакетВходаГенератораFUMA(cases: вход.cases + [rootCase])
    let компоновщик = КомпоновщикFUMAМетаданныхКоммита()
    let случаи = try пакет.cases.map { случай in
        let строка = строкаNativeClient(
            model: случай.acceptedSelection.model,
            effort: случай.acceptedSelection.reasoningEffort
        )
        let подготовка = try ПотребительМетаданныхКоммита.подготовитьRootNativeClient(
            источникJSON: строка,
            независимоеОжиданиеJSON: строка,
            текущееJSON: строка,
            expectedRootUUID: случай.rootUUID
        )
        let выход = try компоновщик.скомпоновать(
            подготовка: подготовка,
            план: ПланСообщенияКоммита(
                исходныйЗапрос: случай.rawRequest,
                заголовок: случай.title,
                описание: случай.description
            ),
            идентификаторСлучая: случай.id
        )
        return ВыходСлучаяГенератораFUMA(
            id: случай.id,
            environment: выход.environment,
            message: выход.message
        )
    }
    let фактический = ПакетВыходаГенератораFUMA(cases: случаи)
    let байты = try ГенераторМетаданныхКоммита.bytesForOutput(фактический)

    #expect(фактический.cases.map(\.id) == пакет.cases.map(\.id))
    #expect(байты.count == 2_192)
    #expect(ГенераторМетаданныхКоммита.sha256Hex(байты)
        == "8a1f08cd0bf3e6d72bd2dd136b6cd3cb7bcd781978b33071ccdc45b395a03cc4")
}

@Test func точныеБайтыИсходногоЗапросаНеНормализуются() throws {
    let свидетельство = try ПотребительМетаданныхКоммита.подготовитьRootNativeClient(
        источникJSON: строкаNativeClient(),
        независимоеОжиданиеJSON: строкаNativeClient(),
        текущееJSON: строкаNativeClient(),
        expectedRootUUID: корневойUUID
    ).квитанции.фактическая.свидетельство
    let запрос = " \r\nСтрока Codex-Thread-ID: внутри текста\r\nТабуляция\t "
    let план = ПланСообщенияКоммита(
        исходныйЗапрос: запрос,
        заголовок: "Проверить точные байты",
        описание: "Публичный consumer не изменяет исходный запрос."
    )
    let подготовка = try ПотребительМетаданныхКоммита.подготовитьRootNativeClient(
        источникJSON: строкаNativeClient(),
        независимоеОжиданиеJSON: строкаNativeClient(),
        текущееJSON: строкаNativeClient(),
        expectedRootUUID: корневойUUID
    )
    #expect(подготовка.квитанции.фактическая.свидетельство == свидетельство)
    let выход = try КомпоновщикFUMAМетаданныхКоммита().скомпоновать(
        подготовка: подготовка,
        план: план
    )

    let ожидаемое = """
    Проверить точные байты

    Публичный consumer не изменяет исходный запрос.

    Исходный запрос:
    \(запрос)

    Codex-Thread-ID: \(корневойUUID)

    """
    #expect(Data(выход.message.utf8) == Data(ожидаемое.utf8))
}
