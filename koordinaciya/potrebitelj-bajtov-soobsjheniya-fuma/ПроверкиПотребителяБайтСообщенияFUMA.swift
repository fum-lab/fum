import Foundation
import Testing
@testable import KoordinaciyaMergeVerifier

struct ПроверкиПотребителяБайтСообщенияFUMA {
    @Test("дополнительный конечный LF отклоняется до Git эффекта")
    func дополнительныйLFОтклоняетсяДоGitЭффекта() throws {
        let источник = try фактическоеСообщениеFUMA()
        #expect(источник.байты.last == 0x0a)

        var подготовленныеБайты = источник.байты
        подготовленныеБайты.append(0x0a)
        let файлПодготовленногоСообщения = URL(fileURLWithPath: источник.папкаСвидетельства)
            .appendingPathComponent("подготовленное-сообщение-с-лишним-lf.bin")
        try подготовленныеБайты.write(to: файлПодготовленногоСообщения, options: .atomic)
        let записанныеБайты = try Data(contentsOf: файлПодготовленногоСообщения)

        var GitЭффектЗапущен = false
        var итог: ИтогПроверкиДоGitЭффекта = .потребительПропустилЭффект
        do {
            try ПотребительБайтСообщенияFUMA.выполнитьПередGitЭффектом(
                исходныеБайтыFUMA: источник.байты,
                подготовленныеБайты: записанныеБайты
            ) {
                GitЭффектЗапущен = true
            }
        } catch let ошибка as ОшибкаПотребителяБайтСообщенияFUMA {
            итог = GitЭффектЗапущен || ошибка != .подготовленныеБайтыНеСовпадают
                ? .потребительОтклонилПослеGitИлиПоДругойПричине
                : .потребительОтклонилДоGitЭффекта
        } catch {
            итог = GitЭффектЗапущен
                ? .потребительОтклонилПослеGitИлиПоДругойПричине
                : .потребительОтклонилДоGitЭффекта
        }

        #expect(итог == .потребительОтклонилДоGitЭффекта)
    }

    @Test("подготовка сохраняет точные UTF-8 байты FUMA")
    func точныеБайтыСохраняютсяПобайтно() throws {
        let источник = try фактическоеСообщениеFUMA()
        #expect(источник.байты.contains(Data([0x0d, 0x0a])))
        #expect(источник.байты.contains(Data("Влить FUMA".utf8)))
        #expect(источник.байты.contains(Data(" \r\n".utf8)))
        #expect(источник.байты.contains(Data("Русский текст\t \n\n".utf8)))
        #expect(источник.байты.last == 0x0a)

        let файлПодготовленногоСообщения = URL(fileURLWithPath: источник.папкаСвидетельства)
            .appendingPathComponent("подготовленное-сообщение.bin")
        var измерения: [Int64] = []
        var подготовленныеБайты = Data()
        for _ in 0..<25 {
            let начало = ContinuousClock.now
            подготовленныеБайты = try ПотребительБайтСообщенияFUMA.подготовить(
                фактическиеБайтыFUMA: источник.байты,
                вФайл: файлПодготовленногоСообщения
            )
            let длительность = начало.duration(to: .now)
            let компоненты = длительность.components
            измерения.append(компоненты.seconds * 1_000_000_000 + компоненты.attoseconds / 1_000_000_000)
        }
        let прочитанныеБайты = try Data(contentsOf: файлПодготовленногоСообщения)

        #expect(подготовленныеБайты == источник.байты)
        #expect(прочитанныеБайты == источник.байты)

        let отсортированныеИзмерения = измерения.sorted()
        let профиль: [String: Any] = [
            "схема": "fum.координация.профиль-потребителя-байт-сообщения.1",
            "сценарий": "подготовка-и-побайтная-сверка",
            "числоВызовов": измерения.count,
            "общаяДлительностьНС": измерения.reduce(0, +),
            "медианаНС": отсортированныеИзмерения[отсортированныеИзмерения.count / 2],
            "максимумНС": отсортированныеИзмерения[отсортированныеИзмерения.count - 1],
            "байтИсходногоСообщения": источник.байты.count,
        ]
        let файлПрофиля = URL(fileURLWithPath: источник.папкаСвидетельства)
            .appendingPathComponent("профиль-потребителя.json")
        let байтыПрофиля = try JSONSerialization.data(withJSONObject: профиль, options: [.sortedKeys])
        try байтыПрофиля.write(to: файлПрофиля, options: .atomic)
    }
}

private struct ИсточникСообщенияFUMA {
    let байты: Data
    let папкаСвидетельства: String
}

private enum ИтогПроверкиДоGitЭффекта: Equatable {
    case потребительОтклонилДоGitЭффекта
    case потребительОтклонилПослеGitИлиПоДругойПричине
    case потребительПропустилЭффект
}

private func фактическоеСообщениеFUMA() throws -> ИсточникСообщенияFUMA {
    let среда = ProcessInfo.processInfo.environment
    guard let кореньРепозитория = среда["KOORDINACIYA_REPOSITORY_ROOT"],
          FileManager.default.changeCurrentDirectoryPath(кореньРепозитория),
          let определение = среда["KOORDINACIYA_FUMA_DEFINITION"],
          let оператор = среда["KOORDINACIYA_FUMA_OPERATOR"],
          let фикстура = среда["KOORDINACIYA_FUMA_FIXTURE"],
          let кореньЗапуска = среда["KOORDINACIYA_FUMA_RUN_ROOT"] else {
        throw CocoaError(.coderValueNotFound)
    }
    let данныеФикстуры = try Data(contentsOf: URL(fileURLWithPath: фикстура))
    let вход = try JSONDecoder().decode(ПакетВходаГенератораFUMA.self, from: данныеФикстуры)
    let запуск = try ИсполнительГенератораFUMA.выполнить(
        input: вход,
        definitionPath: определение,
        operatorPath: оператор,
        privateRunRoot: кореньЗапуска
    )
    guard let случай = запуск.пакет.cases.first(where: { $0.id == "leading-trailing-crlf-russian-trailer-mention" }) else {
        throw CocoaError(.coderValueNotFound)
    }
    let фактическиеБайты = Data(случай.message.utf8)
    let файлИсходногоСообщения = URL(fileURLWithPath: запуск.evidenceDirectory)
        .appendingPathComponent("исходное-сообщение.bin")
    try фактическиеБайты.write(to: файлИсходногоСообщения, options: .atomic)
    return ИсточникСообщенияFUMA(
        байты: фактическиеБайты,
        папкаСвидетельства: запуск.evidenceDirectory
    )
}
