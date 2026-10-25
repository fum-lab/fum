import Foundation
import Darwin
import Testing
import КонтейнерНаблюдений
@testable import ОсноваЗапуска

@Suite("Корневой запуск: процессы и принятая история", .serialized)
struct ПроверкиКорневогоЗапуска {
    @Test("Default остаётся вне HOME, который может быть Git-репозиторием")
    func путьПоУмолчанию() throws {
        guard case .запуск(let параметры) = try ВходКоманды.разобрать([]) else {
            Issue.record("Default не выбрал запуск")
            return
        }
        let домашний = FileManager.default.homeDirectoryForCurrentUser.path
        #expect(!параметры.хранилище.hasPrefix(домашний + "/"))
        #expect(параметры.хранилище.hasPrefix("/Users/Shared/"))
        #expect(параметры.событие == nil)
    }

    @Test("Ошибка fsync после начала записи сохраняет неизвестный исход")
    func неизвестныйИсходЗаписи() async throws {
        let среда = try СредаПроверкиЗапуска()
        let первый = ПараметрыЗапуска(хранилище: среда.хранилище.path,
            событие: UUID().uuidString.lowercased(), намерение: "первый запуск", профиль: false)
        _ = try await ЦиклЗапуска().выполнить(первый)
        let файл = среда.хранилище.appendingPathComponent("сегмент.fumobs")
        let префикс = try Data(contentsOf: файл)
        let операции = ФайловыеОперации(запись: ФайловыеОперации.системные.запись,
            синхронизация: { _ in throw ОшибкаКонтейнера.система(EIO) })
        let новый = ПараметрыЗапуска(хранилище: среда.хранилище.path,
            событие: UUID().uuidString.lowercased(), намерение: "новый запуск", профиль: false)
        do {
            _ = try await ЦиклЗапуска(операции: операции).выполнить(новый)
            Issue.record("Ошибка синхронизации скрыта")
        } catch let ошибка as ОтказЗапуска {
            #expect(ошибка.код == .системнаяОшибка)
            #expect(ошибка.системныйКод == EIO)
            #expect(ошибка.записьСобытия == .исходНеизвестен)
            #expect(ошибка.принятаяКвитанция == nil)
        }
        let после = try Data(contentsOf: файл)
        #expect(после.count > префикс.count)
        #expect(после.starts(with: префикс))
    }

    @Test("Два процесса сохраняют и точно повторяют одно событие")
    func дваПроцесса() async throws {
        let среда = try СредаПроверкиЗапуска()
        let процессы = try ПроцессыЗапуска(среда: среда)
        let событие = UUID().uuidString.lowercased()
        let первый = try await процессы.запустить(среда.аргументы(событие))
        try #require(первый.код == 0)
        let ответ = try JSONDecoder().decode(ОтветЗапуска.self, from: первый.вывод)
        let результат = try #require(ответ.результат)
        let файл = среда.хранилище.appendingPathComponent("сегмент.fumobs")
        let байты = try Data(contentsOf: файл)
        let второй = try await процессы.запустить(среда.аргументы(событие))
        try #require(второй.код == 0)
        let повтор = try JSONDecoder().decode(ОтветЗапуска.self, from: второй.вывод)
        let восстановленный = try #require(повтор.результат)
        #expect(первый.процесс != второй.процесс)
        #expect(ответ.состояние == .ожидаетПодключенияАдаптера)
        #expect(повтор.состояние == .ожидаетПодключенияАдаптера)
        #expect(результат.изменение == .добавлено)
        #expect(восстановленный.изменение == .точныйПовтор)
        #expect(результат.квитанция == восстановленный.квитанция)
        #expect(результат.наблюдение == восстановленный.наблюдение)
        #expect(результат.наблюдение.версияСхемы == 1)
        #expect(результат.наблюдение.намерение == "открыть локальную историю")
        #expect(результат.наблюдение.подключённыеАдаптеры.isEmpty)
        #expect(результат.квитанция.описание.идентификатор == событие)
        #expect(результат.квитанция.описание.источник == "fuma")
        #expect(результат.квитанция.описание.версияСхемы == 1)
        #expect(результат.квитанция.описание.тип == "начальный-запуск")
        #expect(!результат.квитанция.описание.спецификация.isEmpty)
        #expect(результат.квитанция.описание.время.contains("T"))
        #expect(результат.квитанция.описание.время.hasSuffix("Z"))
        #expect(результат.принятоЗаписей == 1)
        #expect(восстановленный.принятоЗаписей == 1)
        #expect(результат.провереноПослеПереоткрытия)
        #expect(восстановленный.провереноПослеПереоткрытия)
        #expect(try Data(contentsOf: файл) == байты)
    }

    @Test("Конфликт того же ID не меняет принятые байты после reopen")
    func конфликтИдентификатора() async throws {
        let среда = try СредаПроверкиЗапуска()
        let процессы = try ПроцессыЗапуска(среда: среда)
        let событие = UUID().uuidString.lowercased()
        let первый = try await процессы.запустить(среда.аргументы(событие))
        try #require(первый.код == 0)
        let файл = среда.хранилище.appendingPathComponent("сегмент.fumobs")
        let байты = try Data(contentsOf: файл)
        let конфликт = try await процессы.запустить(среда.аргументы(событие) +
            ["--намерение", "другое принятое намерение"])
        #expect(конфликт.код == 2)
        let отказ = try JSONDecoder().decode(ОтветЗапуска.self, from: конфликт.вывод)
        #expect(отказ.состояние == .отказ)
        #expect(отказ.ошибка?.код == .конфликтИдентификатора)
        #expect(отказ.ошибка?.записьСобытия == .неНачата)
        #expect(try Data(contentsOf: файл) == байты)
        let третий = try await процессы.запустить(среда.аргументы(событие))
        try #require(третий.код == 0)
        let восстановленный = try JSONDecoder().decode(ОтветЗапуска.self, from: третий.вывод)
        #expect(восстановленный.результат?.принятоЗаписей == 1)
        #expect(восстановленный.результат?.изменение == .точныйПовтор)
        #expect(try Data(contentsOf: файл) == байты)
    }

    enum ВариантПути: CaseIterable, Sendable, Equatable {
        case относительный, символическаяСсылка, внутриGit, неприватный
    }

    @Test("Недопустимый путь даёт типизированный отказ до истории",
          arguments: ВариантПути.allCases)
    func отказПути(_ вариант: ВариантПути) async throws {
        let среда = try СредаПроверкиЗапуска()
        let процессы = try ПроцессыЗапуска(среда: среда)
        let путь: String
        switch вариант {
        case .относительный:
            путь = "относительный-путь"
        case .символическаяСсылка:
            let цель = среда.корень.appendingPathComponent("target")
            try FileManager.default.createDirectory(at: цель, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
            let ссылка = среда.корень.appendingPathComponent("link")
            try FileManager.default.createSymbolicLink(at: ссылка, withDestinationURL: цель)
            путь = ссылка.appendingPathComponent("zapusk").path
        case .внутриGit:
            try Data("проверочный маркер Git".utf8).write(to:
                среда.корень.appendingPathComponent(".git"), options: [.withoutOverwriting])
            путь = среда.хранилище.path
        case .неприватный:
            try FileManager.default.createDirectory(at: среда.хранилище, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o755])
            путь = среда.хранилище.path
        }
        let наблюдение = try await процессы.запустить(["--хранилище", путь])
        #expect(наблюдение.код == 2)
        let ответ = try JSONDecoder().decode(ОтветЗапуска.self, from: наблюдение.вывод)
        #expect(ответ.состояние == .отказ)
        #expect(ответ.ошибка?.код == (вариант == .внутриGit ? .внутриGit : .небезопасныйПуть))
        #expect(!FileManager.default.fileExists(atPath:
            среда.хранилище.appendingPathComponent("сегмент.fumobs").path))
        if вариант == .символическаяСсылка {
            #expect(!FileManager.default.fileExists(atPath:
                среда.корень.appendingPathComponent("target/zapusk").path))
        }
    }

    enum Повреждение: CaseIterable, Sendable, Equatable { case хвост, сигнатура }

    @Test("Хвост и повреждение возвращают typed отказ без ремонта",
          arguments: Повреждение.allCases)
    func повреждённаяИстория(_ вариант: Повреждение) async throws {
        let среда = try СредаПроверкиЗапуска()
        let процессы = try ПроцессыЗапуска(среда: среда)
        let первый = try await процессы.запустить(среда.аргументы(UUID().uuidString.lowercased()))
        try #require(первый.код == 0)
        let файл = среда.хранилище.appendingPathComponent("сегмент.fumobs")
        var байты = try Data(contentsOf: файл)
        switch вариант {
        case .хвост: байты.append(contentsOf: [0x7f, 0x00])
        case .сигнатура: байты[0] ^= 0xff
        }
        try байты.write(to: файл)
        let второй = try await процессы.запустить(среда.аргументы(UUID().uuidString.lowercased()))
        #expect(второй.код == 2)
        let ответ = try JSONDecoder().decode(ОтветЗапуска.self, from: второй.вывод)
        #expect(ответ.состояние == .отказ)
        #expect(ответ.ошибка?.код == (вариант == .хвост ? .неполныйХвост : .повреждениеИстории))
        #expect(try Data(contentsOf: файл) == байты)
    }
}
