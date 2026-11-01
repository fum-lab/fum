import CryptoKit
import Darwin
import Foundation
import Testing
@testable import АктуализацияПутей
import КомандаНормализацииКорнейАгентов

@Suite("Нормализация корней агентов")
struct ПроверкиНормализацииКорнейАгентов {
    @Test("Слияние переносит и дедуплицирует равное, конфликт сохраняет обе версии и ссылки")
    func слияниеИКонфликт() async throws {
        let фикстура = try ФикстураНормализации(.слияние)
        let хранилище = ХранилищеКонтрольныхТочек()
        let результат = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: nil,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })

        #expect(результат.исход == .конфликтСохранён)
        #expect(результат.конфликты.count == 1)
        #expect(результат.конфликты[0].версии.count == 2)
        #expect(результат.контрольнаяТочка.основа.cellID != фикстура.назначение.владение.cellID)
        #expect(результат.контрольнаяТочка.основа.fullRefЗапуска != фикстура.назначение.владение.fullRef)
        #expect(фикстура.назначение.допуск.toolsActorUUID != фикстура.назначение.владение.владелец)
        #expect(фикстура.назначение.допуск.preparationWUUID != фикстура.назначение.владение.cellID)
        #expect(фикстура.назначение.допуск.trustedRoot == фикстура.корень.path)
        #expect(фикстура.назначение.допуск.effect == .слияниеКорнейСОбновлениемЗакреплённыхДокументов)
        let конфликт = try #require(результат.конфликты.first)
        #expect(конфликт.целевойПуть == "istochniki/URL/conflict.raw")
        #expect(Set(конфликт.версии.map(\.путь)) == Set([
            "Источники/URL/conflict.raw", "istochniki/URL/conflict.raw"
        ]))
        let версииПоПути = Dictionary(uniqueKeysWithValues: конфликт.версии.map { ($0.путь, $0) })
        #expect(версииПоПути["Источники/URL/conflict.raw"]?.gitОбъект
            == (try фикстура.исходныйОбъект("Источники/URL/conflict.raw")))
        #expect(версииПоПути["istochniki/URL/conflict.raw"]?.gitОбъект
            == (try фикстура.исходныйОбъект("istochniki/URL/conflict.raw")))
        #expect(конфликт.версии.allSatisfy { $0.тип == "blob" && $0.режим == "100644" })
        let шагКонфликта = try #require(результат.контрольнаяТочка.шаги.first {
            $0.вид == .конфликтСохранён && $0.целевойПуть == конфликт.целевойПуть
        })
        #expect(шагКонфликта.исходныйОбъект == версииПоПути["Источники/URL/conflict.raw"]?.gitОбъект)
        #expect(шагКонфликта.целевойОбъект == версииПоПути["istochniki/URL/conflict.raw"]?.gitОбъект)
        #expect(try фикстура.индекснаяЗапись("istochniki/URL/conflict.raw").режим == "100644")
        #expect(try фикстура.индекснаяЗапись("istochniki/URL/conflict.raw").объект
            == версииПоПути["istochniki/URL/conflict.raw"]?.gitОбъект)
        #expect(try фикстура.прочитать("istochniki/URL/keep.raw") == Data("исходное содержимое\n".utf8))
        #expect(try фикстура.существует("istochniki/URL/same.raw"))
        #expect(!(try фикстура.существует("Источники/URL/same.raw")))
        #expect(try фикстура.прочитать("Источники/URL/conflict.raw") == Data("исходная версия\n".utf8))
        #expect(try фикстура.прочитать("istochniki/URL/conflict.raw") == Data("целевая версия\n".utf8))
        #expect(!(try фикстура.существует("Источники/README.md")))

        let readme = try String(decoding: фикстура.прочитать("istochniki/README.md"), as: UTF8.self)
        #expect(readme.contains("istochniki/URL/keep.raw"))
        #expect(readme.contains("istochniki/URL/same.raw"))
        #expect(readme.contains("Источники/URL/conflict.raw"))
        let karta = try String(decoding: фикстура.прочитать("istochniki/karta.json"), as: UTF8.self)
        #expect(karta.contains("istochniki/README.md"))
        #expect(karta.contains("Источники/URL/"))
        let намерение = try #require(await хранилище.последнее())
        #expect(намерение.operationID == результат.контрольнаяТочка.operationID)
        #expect(намерение.фаза == .терминал)
        #expect(намерение.sha256 == sha256(намерение.каноническиеБайты))
        #expect(try фикстура.контрольнуюТочку(намерение) == результат.контрольнаяТочка)
        #expect(результат.контрольнаяТочка.схема == "fum.контрольная-точка-нормализации-корней-агентов.2")
        #expect(результат.контрольнаяТочка.допуск == фикстура.назначение.допуск)
        let шагДокумента = try #require(результат.контрольнаяТочка.шаги.first {
            $0.вид == .обновлениеДокумента && $0.целевойПуть == "istochniki/README.md"
        })
        #expect(try фикстура.индекснаяЗапись("istochniki/README.md").объект == шагДокумента.целевойОбъект)
        #expect(try фикстура.индекснаяЗапись("istochniki/README.md").режим == шагДокумента.целевойРежим)

        let сохраненийДоПовтора = await хранилище.числоСохранений()
        let inodeДоПовтора = try фикстура.inode("istochniki/URL/keep.raw")
        let индексДоПовтора = try фикстура.индексБайты()
        let глубокоИгнорируемый = "istochniki/URL/cache/nested/deep/ignored.bin"
        try фикстура.добавитьИгнорируемыйФайл(глубокоИгнорируемый, Data("после терминальной точки".utf8))
        let повтор = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: результат.контрольнаяТочка,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        #expect(повтор.исход == .безИзменений)
        #expect(повтор.изменённыеПути.isEmpty)
        #expect(повтор.конфликты == результат.конфликты)
        #expect(повтор.контрольнаяТочка == результат.контрольнаяТочка)
        #expect(try фикстура.inode("istochniki/URL/keep.raw") == inodeДоПовтора)
        #expect(try фикстура.индексБайты() == индексДоПовтора)
        #expect(await хранилище.числоСохранений() == сохраненийДоПовтора)
        #expect(try фикстура.существует(глубокоИгнорируемый))
    }

    @Test("Отсутствующий целевой каталог переносится целиком с сохранением суффикса и байтов")
    func переносКаталогаСохраняетСуффикс() async throws {
        let фикстура = try ФикстураНормализации(.переносКаталога)
        let хранилище = ХранилищеКонтрольныхТочек()
        let результат = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: nil,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })

        #expect(результат.исход == .перенос)
        #expect(try фикстура.прочитать("istochniki/URL/https/sample.invalid/archive.Archive.WARC") == Data("байты ресурса\0\n".utf8))
        #expect(!(try фикстура.существует("Источники")))
        let readme = try String(decoding: фикстура.прочитать("istochniki/README.md"), as: UTF8.self)
        #expect(readme.contains("istochniki/URL/https/sample.invalid/archive.Archive.WARC"))
        let karta = try String(decoding: фикстура.прочитать("istochniki/karta.json"), as: UTF8.self)
        #expect(karta.contains("istochniki/URL/"))
    }

    @Test
    func известнаяКонтрольнаяТочкаВозобновляетсяАНеизвестнаяНеПовторяетПеренос() async throws {
        let фикстура = try ФикстураНормализации(.переносКаталога)
        let хранилище = ХранилищеКонтрольныхТочек(ошибкаПослеСохраненияНомера: 3)
        let перваяПопытка = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: nil,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })

        #expect(перваяПопытка.исход == .неизвестно)
        let путь = "istochniki/README.md"
        let inodeДо = try фикстура.inode(путь)
        let счётчикДо = await хранилище.числоСохранений()
        let повторНеизвестного = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: перваяПопытка.контрольнаяТочка,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        #expect(повторНеизвестного.исход == .неизвестно)
        #expect(try фикстура.inode(путь) == inodeДо)
        #expect(await хранилище.числоСохранений() == счётчикДо)

        let сохранённоеНамерение = try #require(await хранилище.последнее())
        let известнаяТочка = try JSONDecoder().decode(
            КонтрольнаяТочкаНормализацииКорнейАгентов.self,
            from: сохранённоеНамерение.каноническиеБайты)
        #expect(известнаяТочка.фаза == .применение)
        let возобновление = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: известнаяТочка,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        #expect(возобновление.исход == .перенос)
        #expect(try фикстура.прочитать("istochniki/URL/https/sample.invalid/archive.Archive.WARC") == Data("байты ресурса\0\n".utf8))
    }

    @Test("Отказ по текущим владельцу, индексу, источнику и ref происходит до первого эффекта")
    func отрицательныеПроверкиТекущегоДопуска() async throws {
        let владелец = try ФикстураНормализации(.переносКаталога)
        владелец.заменитьСнимок(владелецЗапуска: "Different Author <other@example.invalid>")
        try await ожидатьОтказДоЭффекта(владелец)

        let индекс = try ФикстураНормализации(.переносКаталога)
        индекс.заменитьСнимок(индексSHA256: String(repeating: "0", count: 64))
        try await ожидатьОтказДоЭффекта(индекс)

        let источник = try ФикстураНормализации(.переносКаталога)
        try источник.перезаписать("Источники/README.md", Data("изменённый источник\n".utf8))
        try await ожидатьОтказДоЭффекта(источник)

        let ref = try ФикстураНормализации(.переносКаталога)
        ref.заменитьСнимок(fullRefЗапуска: "refs/heads/fum-lab/fum/not-the-active-ref")
        try await ожидатьОтказДоЭффекта(ref)

        let кореньДопуска = try ФикстураНормализации(.переносКаталога)
        кореньДопуска.заменитьTrustedRoot(кореньДопуска.корень.path + "/different")
        try await ожидатьОтказДоЭффекта(кореньДопуска)
    }

    @Test("Расхождение чтения контрольной точки блокирует эффект")
    func несовпадающееПеречитываниеНеПрименяетПлан() async throws {
        let фикстура = try ФикстураНормализации(.переносКаталога)
        let хранилище = ХранилищеКонтрольныхТочек(несовпадающееПеречитывание: true)
        let индексДо = try фикстура.индексБайты()
        var отказано = false
        do {
            _ = try await НормализацияКорнейАгентов.выполнить(
                назначение: фикстура.назначение,
                контрольнаяТочка: nil,
                сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        } catch {
            отказано = true
        }
        #expect(отказано)
        #expect(await хранилище.числоСохранений() == 1)
        #expect(try фикстура.индексБайты() == индексДо)
        #expect(try фикстура.существует("Источники"))
        #expect(try фикстура.прочитать("Источники/URL/https/sample.invalid/archive.Archive.WARC")
            == Data("байты ресурса\0\n".utf8))
        #expect(!(try фикстура.существует("istochniki/URL/https/sample.invalid/archive.Archive.WARC")))
    }

    @Test("Глубокий неучтённый файл и вложенная ссылка блокируют план до эффектов")
    func глубокийНеучтённыйФайлИВложеннаяСсылкаОтклоняются() async throws {
        let неучтённый = try ФикстураНормализации(.переносКаталога)
        try неучтённый.записать(
            "Источники/URL/deep/one/two/three/four/untracked.raw",
            Data("неучтённые байты".utf8))
        try await ожидатьОтказДоЭффекта(неучтённый)

        let символическаяСсылка = try ФикстураНормализации(.вложеннаяСсылка)
        let индексДо = try символическаяСсылка.индексБайты()
        let хранилище = ХранилищеКонтрольныхТочек()
        var отказано = false
        do {
            _ = try await НормализацияКорнейАгентов.выполнить(
                назначение: символическаяСсылка.назначение,
                контрольнаяТочка: nil,
                сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        } catch {
            отказано = true
        }
        #expect(отказано)
        #expect(await хранилище.числоСохранений() == 0)
        #expect(try символическаяСсылка.индексБайты() == индексДо)
        #expect(try символическаяСсылка.существует("Источники/URL/deep/alias.raw"))
        #expect(try символическаяСсылка.существует("Источники"))
    }

    @Test("После атомарной замены документа возобновление выполняет только известное stage")
    func возобновлениеПослеПереименованияДоStage() async throws {
        let фикстура = try ФикстураНормализации(.переносКаталога)
        var точка = try await ПланировщикНормализацииКорнейАгентов.построить(фикстура.назначение)
        let номерДокумента = try #require(точка.шаги.firstIndex { $0.вид == .обновлениеДокумента })
        for шаг in точка.шаги[..<номерДокумента] {
            try фикстура.выполнитьПредшествующийШаг(шаг)
        }
        точка.следующийШаг = номерДокумента
        точка.фаза = .применение
        точка.итоговыйИндексSHA256 = try фикстура.хэшИндексаКорней()
        let шагДокумента = точка.шаги[номерДокумента]
        let новыеБайты = НормализацияСсылок.переписать(
            try фикстура.прочитать(шагДокумента.целевойПуть), шаги: точка.шаги)
        #expect(sha256(новыеБайты) == точка.целевыеSHA256Документов[шагДокумента.целевойПуть])

        let сохранённыеБайты = try ПланировщикНормализацииКорнейАгентов.каноническиеБайты(точка)
        let намерение = КонтрольнаяТочкаНормализацииКорнейАгентов.Намерение(
            operationID: точка.operationID,
            фаза: .подтверждённыйШаг,
            каноническиеБайты: сохранённыеБайты,
            sha256: sha256(сохранённыеБайты))
        let восстановленная = try фикстура.контрольнуюТочку(намерение)
        let хранилище = ХранилищеКонтрольныхТочек()
        await хранилище.предзагрузить(намерение)

        try фикстура.перезаписать(шагДокумента.целевойПуть, новыеБайты)
        let inodeПослеRename = try фикстура.inode(шагДокумента.целевойПуть)
        #expect(try фикстура.индекснаяЗапись(шагДокумента.целевойПуть).объект == шагДокумента.исходныйОбъект)
        #expect(try фикстура.индекснаяЗапись(шагДокумента.целевойПуть).режим == шагДокумента.исходныйРежим)

        let результат = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: восстановленная,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        #expect(результат.исход == .перенос)
        #expect(try фикстура.inode(шагДокумента.целевойПуть) == inodeПослеRename)
        #expect(try sha256(фикстура.прочитать(шагДокумента.целевойПуть))
            == точка.целевыеSHA256Документов[шагДокумента.целевойПуть])
        #expect(try фикстура.индекснаяЗапись(шагДокумента.целевойПуть).объект == шагДокумента.целевойОбъект)
    }

    @Test("README без замен остаётся теми же байтами после переноса и удаления дубликата")
    func неизменённыйREADMEПослеПереносаИДедупликации() async throws {
        let фикстура = try ФикстураНормализации(.слияниеБезСсылок)
        let план = try await ПланировщикНормализацииКорнейАгентов.построить(фикстура.назначение)
        let шагREADME = try #require(план.шаги.first {
            $0.вид == .обновлениеДокумента && $0.целевойПуть == "istochniki/README.md"
        })
        let байтыДо = try фикстура.прочитать(шагREADME.исходныйПуть)
        let индексДо = try фикстура.индекснаяЗапись(шагREADME.исходныйПуть)
        let закреплённыйREADME = try #require(фикстура.назначение.документыСсылок.first {
            $0.путь == шагREADME.исходныйПуть
        })
        #expect(sha256(байтыДо) == закреплённыйREADME.sha256)
        #expect(шагREADME.исходныйОбъект == индексДо.объект)
        #expect(шагREADME.исходныйРежим == индексДо.режим)
        #expect(шагREADME.целевойОбъект == шагREADME.исходныйОбъект)
        #expect(шагREADME.целевойРежим == шагREADME.исходныйРежим)
        #expect(план.целевыеSHA256Документов[шагREADME.целевойПуть] == sha256(байтыДо))

        let хранилище = ХранилищеКонтрольныхТочек()
        let результат = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: nil,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })

        #expect(результат.исход == .перенос)
        #expect(результат.контрольнаяТочка.фаза == .завершено)
        #expect(try фикстура.прочитать(шагREADME.целевойПуть) == байтыДо)
        #expect(sha256(try фикстура.прочитать(шагREADME.целевойПуть)) == закреплённыйREADME.sha256)
        #expect(!(try фикстура.существует(шагREADME.исходныйПуть)))
        let индексПосле = try фикстура.индекснаяЗапись(шагREADME.целевойПуть)
        #expect(индексПосле.объект == индексДо.объект)
        #expect(индексПосле.режим == индексДо.режим)

        let terminalIntent = try #require(await хранилище.последнее())
        #expect(terminalIntent.фаза == .терминал)
        #expect(try фикстура.контрольнуюТочку(terminalIntent) == результат.контрольнаяТочка)
    }

    @Test("После подтверждения последнего README до terminal resume не повторяет эффект и следующий вызов — NO_OP")
    func resumeПослеПоследнегоДокументаПередTerminal() async throws {
        let фикстура = try ФикстураНормализации(.слияние)
        let хранилище = ХранилищеКонтрольныхТочек(ошибкаПередФазой: .терминал)
        let перваяПопытка = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: nil,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        #expect(перваяПопытка.исход == .неизвестно)

        let последнееНамерение = try #require(await хранилище.последнее())
        #expect(последнееНамерение.фаза == .подтверждённыйШаг)
        let последняяТочка = try фикстура.контрольнуюТочку(последнееНамерение)
        #expect(последняяТочка.следующийШаг == последняяТочка.шаги.count)
        #expect(последняяТочка.фаза == .применение)
        #expect(последняяТочка.шаги.last?.вид == .обновлениеДокумента)

        let путьREADME = "istochniki/README.md"
        let inodeДоResume = try фикстура.inode(путьREADME)
        let байтыREADME = try фикстура.прочитать(путьREADME)
        let индексДоResume = try фикстура.индексБайты()
        let сохраненийДоResume = await хранилище.числоСохранений()
        let возобновление = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: последняяТочка,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })

        #expect(возобновление.исход == .конфликтСохранён)
        #expect(возобновление.контрольнаяТочка.фаза == .завершено)
        #expect(await хранилище.числоСохранений() == сохраненийДоResume + 1)
        #expect(try фикстура.inode(путьREADME) == inodeДоResume)
        #expect(try фикстура.прочитать(путьREADME) == байтыREADME)
        #expect(try фикстура.индексБайты() == индексДоResume)

        let terminalIntent = try #require(await хранилище.последнее())
        let terminalPoint = try фикстура.контрольнуюТочку(terminalIntent)
        let сохраненийДоNOOP = await хранилище.числоСохранений()
        let повтор = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: terminalPoint,
            сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        #expect(повтор.исход == .безИзменений)
        #expect(повтор.контрольнаяТочка == terminalPoint)
        #expect(await хранилище.числоСохранений() == сохраненийДоNOOP)
        #expect(try фикстура.inode(путьREADME) == inodeДоResume)
        #expect(try фикстура.индексБайты() == индексДоResume)
    }

    @Test("Адаптер сохраняет точку в сегмент, закрывает, открывает заново и возвращает точное терминальное состояние")
    func сегментАдаптерПеречитываетПослеЗакрытия() async throws {
        let фикстура = try ФикстураНормализации(.слияние)
        let кореньХранилища = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .appendingPathComponent("fum-root-normalization-checkpoints-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: кореньХранилища, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: кореньХранилища) }

        let писатель = ХранилищеКонтрольныхТочекВСегменте(кореньДанных: кореньХранилища)
        let результат = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: nil,
            сохранитьИПеречитать: { try await писатель.сохранитьИПеречитать($0) })
        #expect(результат.исход == .конфликтСохранён)

        let новыйЧитатель = ХранилищеКонтрольныхТочекВСегменте(кореньДанных: кореньХранилища)
        let сохранённая = try #require(try await новыйЧитатель.загрузитьПоследнююКонтрольнуюТочку(
            operationID: результат.контрольнаяТочка.operationID))
        #expect(сохранённая == результат.контрольнаяТочка)

        let повтор = try await НормализацияКорнейАгентов.выполнить(
            назначение: фикстура.назначение,
            контрольнаяТочка: сохранённая,
            сохранитьИПеречитать: { try await новыйЧитатель.сохранитьИПеречитать($0) })
        #expect(повтор.исход == .безИзменений)
        #expect(повтор.контрольнаяТочка == сохранённая)
    }

    private func ожидатьОтказДоЭффекта(_ фикстура: ФикстураНормализации) async throws {
        let хранилище = ХранилищеКонтрольныхТочек()
        let индексДо = try фикстура.индексБайты()
        let байтыИсточникаДо = try фикстура.прочитать("Источники/README.md")
        var отказано = false
        do {
            _ = try await НормализацияКорнейАгентов.выполнить(
                назначение: фикстура.назначение,
                контрольнаяТочка: nil,
                сохранитьИПеречитать: { try await хранилище.сохранить($0) })
        } catch {
            отказано = true
        }
        #expect(отказано)
        #expect(await хранилище.числоСохранений() == 0)
        #expect(try фикстура.существует("Источники"))
        #expect(try фикстура.прочитать("Источники/README.md") == байтыИсточникаДо)
        #expect(try фикстура.индексБайты() == индексДо)
    }
}

private enum СценарийФикстурыНормализации {
    case слияние
    case слияниеБезСсылок
    case переносКаталога
    case вложеннаяСсылка
}

private final class ФикстураНормализации {
    let корень: URL
    private(set) var назначение: НазначениеНормализацииКорнейАгентов!

    init(_ сценарий: СценарийФикстурыНормализации) throws {
        let клетка = UUID().uuidString.lowercased()
        let созданный = FileManager.default.temporaryDirectory
            .appendingPathComponent("fum-root-normalization-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: созданный, withIntermediateDirectories: true)
        корень = созданный.resolvingSymlinksInPath().standardizedFileURL

        let readme: String
        switch сценарий {
        case .слияниеБезСсылок:
            readme = "# Источники\n\nЗдесь нет ссылок на перемещаемые пути.\n"
        default:
            readme = (
                "# Источники\n\n"
                    + "Путь: `Источники/URL/keep.raw`\n"
                    + "Путь: `Источники/URL/same.raw`\n"
                    + "Путь: `Источники/URL/conflict.raw`\n"
                    + "Путь: `Источники/URL/https/sample.invalid/archive.Archive.WARC`\n"
            )
        }
        try записать("Источники/README.md", Data(readme.utf8))
        switch сценарий {
        case .слияние:
            try записать("Источники/URL/keep.raw", Data("исходное содержимое\n".utf8))
            try записать("Источники/URL/same.raw", Data("общая версия\n".utf8))
            try записать("Источники/URL/conflict.raw", Data("исходная версия\n".utf8))
            try записать("istochniki/URL/same.raw", Data("общая версия\n".utf8))
            try записать("istochniki/URL/conflict.raw", Data("целевая версия\n".utf8))
        case .слияниеБезСсылок:
            try записать("Источники/URL/moved.raw", Data("перемещаемые байты\n".utf8))
            try записать("Источники/URL/same.raw", Data("общая версия\n".utf8))
            try записать("istochniki/URL/same.raw", Data("общая версия\n".utf8))
        case .переносКаталога:
            try записать("Источники/URL/https/sample.invalid/archive.Archive.WARC", Data("байты ресурса\0\n".utf8))
        case .вложеннаяСсылка:
            try записать("Источники/URL/deep/keep.raw", Data("содержимое ссылки\n".utf8))
            try создатьСсылку("keep.raw", путь: "Источники/URL/deep/alias.raw")
        }

        let историческийКорень = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
        let историческийВладелец = "01a17838-f2e9-7ba3-948d-8d2d0a6458c4"
        let историческаяВетка = "refs/heads/fum-lab/fum/istochniki/master"
        let текущаяВетка = "refs/heads/fum-lab/fum/normalizaciya-" + UUID().uuidString.lowercased()
        let постановка = """
        {
          "корень": "\(историческийКорень)",
          "адрес": "fum-lab/fum/istochniki/master",
          "память": "istochniki",
          "историческая_область": "Источники",
          "область_первого_писателя": ["istochniki/**"]
        }
        """ + "\n"
        let карта = """
        {
          "поручение": {
            "корневой_uuid": "\(историческийКорень)",
            "писатель_uuid": "\(историческийВладелец)",
            "ветка": "\(историческаяВетка)",
            "область": "istochniki/**"
          },
          "навигация": [
            {"путь": "istochniki/postanovka.json"},
            {"путь": "Источники/README.md"},
            {"путь": "Источники/URL/"}
          ]
        }
        """ + "\n"
        try записать("istochniki/postanovka.json", Data(постановка.utf8))
        try записать("istochniki/karta.json", Data(карта.utf8))

        _ = try git(["init", "-q"])
        _ = try git(["config", "user.name", "Fixture Author"])
        _ = try git(["config", "user.email", "fixture@example.invalid"])
        _ = try git(["add", "--all"])
        _ = try git(["commit", "--quiet", "-m", "fixture root normalization"])
        let commit = try текст(git(["rev-parse", "HEAD"]))
        _ = try git(["update-ref", текущаяВетка, commit])
        _ = try git(["symbolic-ref", "HEAD", текущаяВетка])
        let дерево = try текст(git(["rev-parse", "HEAD^{tree}"]))
        let исходноеДерево = try текст(git(["rev-parse", "HEAD:Источники"]))
        let целевоеДерево = try текст(git(["rev-parse", "HEAD:istochniki"]))
        let индекс = try git(["ls-files", "--stage", "-z", "--", "Источники", "istochniki"])
        let индексSHA = sha256(индекс)
        let имя = "Fixture Author"
        let email = "fixture@example.invalid"
        let документы = [
            ЗакреплённыйДокументСсылок(
                путь: "Источники/README.md",
                sha256: sha256(try прочитать("Источники/README.md")),
                gitОбъект: try текст(git(["rev-parse", "HEAD:Источники/README.md"]))),
            ЗакреплённыйДокументСсылок(
                путь: "istochniki/karta.json",
                sha256: sha256(try прочитать("istochniki/karta.json")),
                gitОбъект: try текст(git(["rev-parse", "HEAD:istochniki/karta.json"]))
            )
        ]
        let снимок = СнимокНормализацииКорнейАгентов(
            cellID: клетка,
            владелецЗапуска: "\(имя) <\(email)>",
            fullRefЗапуска: текущаяВетка,
            commit: commit,
            дерево: дерево,
            индексSHA256: индексSHA,
            исходноеДерево: исходноеДерево,
            целевоеДерево: целевоеДерево)
        let допуск = ДопускТекущегоИсполненияНормализации(
            trustedRoot: корень.path,
            toolsActorUUID: UUID().uuidString.lowercased(),
            preparationWUUID: UUID().uuidString.lowercased(),
            fullRef: текущаяВетка,
            gitAuthorIdentity: "\(имя) <\(email)>",
            baseCommit: commit,
            baseTree: дерево,
            indexSHA256: индексSHA,
            sourceTree: исходноеДерево,
            targetTree: целевоеДерево,
            sourceRoot: "Источники",
            targetRoot: "istochniki",
            pinnedDocuments: документы.map(\.путь),
            effect: .слияниеКорнейСОбновлениемЗакреплённыхДокументов)
        назначение = НазначениеНормализацииКорнейАгентов(
            кореньРепозитория: корень.path,
            владение: .init(
                cellID: историческийКорень,
                владелец: историческийВладелец,
                fullRef: историческаяВетка,
                исходныйКорень: "Источники",
                целевойКорень: "istochniki",
                постановкаПуть: "istochniki/postanovka.json",
                постановкаSHA256: sha256(Data(постановка.utf8)),
                картаПуть: "istochniki/karta.json",
                картаSHA256: sha256(Data(карта.utf8))),
            допуск: допуск,
            снимок: снимок,
            документыСсылок: документы)
    }

    deinit {
        try? FileManager.default.removeItem(at: корень)
    }

    func прочитать(_ путь: String) throws -> Data {
        let descriptor = Darwin.open(корень.path + "/" + путь, O_RDONLY | O_NOFOLLOW)
        guard descriptor >= 0 else { throw ОшибкаФикстурыНормализации.файл }
        defer { close(descriptor) }
        var результат = Data()
        var буфер = [UInt8](repeating: 0, count: 16_384)
        while true {
            let число = буфер.withUnsafeMutableBytes { указатель in
                read(descriptor, указатель.baseAddress, указатель.count)
            }
            if число == 0 { return результат }
            guard число > 0 else { throw ОшибкаФикстурыНормализации.файл }
            результат.append(contentsOf: буфер.prefix(число))
        }
    }

    func существует(_ путь: String) throws -> Bool {
        var значение = stat()
        if lstat(корень.path + "/" + путь, &значение) == 0 { return true }
        if errno == ENOENT { return false }
        throw ОшибкаФикстурыНормализации.файл
    }

    func inode(_ путь: String) throws -> UInt64 {
        var значение = stat()
        guard lstat(корень.path + "/" + путь, &значение) == 0 else {
            throw ОшибкаФикстурыНормализации.файл
        }
        return UInt64(значение.st_ino)
    }

    func заменитьСнимок(
        владелецЗапуска: String? = nil,
        fullRefЗапуска: String? = nil,
        индексSHA256: String? = nil
    ) {
        let старый = назначение.снимок
        let старыйДопуск = назначение.допуск
        let новыйСнимок = СнимокНормализацииКорнейАгентов(
            cellID: старый.cellID,
            владелецЗапуска: владелецЗапуска ?? старый.владелецЗапуска,
            fullRefЗапуска: fullRefЗапуска ?? старый.fullRefЗапуска,
            commit: старый.commit,
            дерево: старый.дерево,
            индексSHA256: индексSHA256 ?? старый.индексSHA256,
            исходноеДерево: старый.исходноеДерево,
            целевоеДерево: старый.целевоеДерево)
        let новыйДопуск = ДопускТекущегоИсполненияНормализации(
            trustedRoot: старыйДопуск.trustedRoot,
            toolsActorUUID: старыйДопуск.toolsActorUUID,
            preparationWUUID: старыйДопуск.preparationWUUID,
            fullRef: новыйСнимок.fullRefЗапуска,
            gitAuthorIdentity: новыйСнимок.владелецЗапуска,
            baseCommit: новыйСнимок.commit,
            baseTree: новыйСнимок.дерево,
            indexSHA256: новыйСнимок.индексSHA256,
            sourceTree: новыйСнимок.исходноеДерево,
            targetTree: новыйСнимок.целевоеДерево,
            sourceRoot: старыйДопуск.sourceRoot,
            targetRoot: старыйДопуск.targetRoot,
            pinnedDocuments: старыйДопуск.pinnedDocuments,
            effect: старыйДопуск.effect)
        назначение = .init(
            кореньРепозитория: назначение.кореньРепозитория,
            владение: назначение.владение,
            допуск: новыйДопуск,
            снимок: новыйСнимок,
            документыСсылок: назначение.документыСсылок)
    }

    func заменитьTrustedRoot(_ trustedRoot: String) {
        let старый = назначение.допуск
        let допуск = ДопускТекущегоИсполненияНормализации(
            trustedRoot: trustedRoot,
            toolsActorUUID: старый.toolsActorUUID,
            preparationWUUID: старый.preparationWUUID,
            fullRef: старый.fullRef,
            gitAuthorIdentity: старый.gitAuthorIdentity,
            baseCommit: старый.baseCommit,
            baseTree: старый.baseTree,
            indexSHA256: старый.indexSHA256,
            sourceTree: старый.sourceTree,
            targetTree: старый.targetTree,
            sourceRoot: старый.sourceRoot,
            targetRoot: старый.targetRoot,
            pinnedDocuments: старый.pinnedDocuments,
            effect: старый.effect)
        назначение = .init(
            кореньРепозитория: назначение.кореньРепозитория,
            владение: назначение.владение,
            допуск: допуск,
            снимок: назначение.снимок,
            документыСсылок: назначение.документыСсылок)
    }

    func перезаписать(_ путь: String, _ байты: Data) throws {
        let адрес = корень.appendingPathComponent(путь)
        var старое = stat()
        guard lstat(адрес.path, &старое) == 0 else { throw ОшибкаФикстурыНормализации.файл }
        try байты.write(to: адрес, options: .atomic)
        guard chmod(адрес.path, старое.st_mode & 0o7777) == 0 else {
            throw ОшибкаФикстурыНормализации.файл
        }
    }

    func создатьСсылку(_ цель: String, путь: String) throws {
        let адрес = корень.path + "/" + путь
        let результат = цель.withCString { цельВUTF8 in
            адрес.withCString { адресВUTF8 in Darwin.symlink(цельВUTF8, адресВUTF8) }
        }
        guard результат == 0 else { throw ОшибкаФикстурыНормализации.файл }
    }

    func добавитьИгнорируемыйФайл(_ путь: String, _ байты: Data) throws {
        let excludeURL = корень.appendingPathComponent(".git/info/exclude")
        let прежнее = (try? Data(contentsOf: excludeURL)) ?? Data()
        var новое = прежнее
        новое.append(Data(("\n/" + путь + "\n").utf8))
        try новое.write(to: excludeURL, options: .atomic)
        try записать(путь, байты)
    }

    func индексБайты() throws -> Data {
        try Data(contentsOf: корень.appendingPathComponent(".git/index"))
    }

    func исходныйОбъект(_ путь: String) throws -> String {
        try текст(git(["rev-parse", "HEAD:" + путь]))
    }

    func индекснаяЗапись(_ путь: String) throws -> (режим: String, объект: String) {
        let данные = try git(["ls-files", "--stage", "-z", "--", путь])
        guard let запись = данные.split(separator: 0).first,
              let таб = запись.firstIndex(of: 9),
              let имя = String(data: Data(запись[запись.index(after: таб)...]), encoding: .utf8),
              имя == путь,
              let заголовок = String(data: Data(запись[..<таб]), encoding: .utf8) else {
            throw ОшибкаФикстурыНормализации.git
        }
        let поля = заголовок.split(separator: " ")
        guard поля.count == 3, поля[2] == "0" else { throw ОшибкаФикстурыНормализации.git }
        return (String(поля[0]), String(поля[1]))
    }

    func хэшИндексаКорней() throws -> String {
        sha256(try git(["ls-files", "--stage", "-z", "--", "Источники", "istochniki"]))
    }

    func выполнитьПредшествующийШаг(_ шаг: ШагНормализацииКорняАгента) throws {
        switch шаг.вид {
        case .переносФайла, .переносКаталога:
            _ = try git(["mv", "--", шаг.исходныйПуть, шаг.целевойПуть])
        case .удалениеДубликатаФайла:
            _ = try git(["rm", "--", шаг.исходныйПуть])
        case .удалениеДубликатаКаталога:
            _ = try git(["rm", "-r", "--", шаг.исходныйПуть])
        case .конфликтСохранён:
            break
        case .обновлениеДокумента:
            throw ОшибкаФикстурыНормализации.git
        }
    }

    func контрольнуюТочку(_ намерение: КонтрольнаяТочкаНормализацииКорнейАгентов.Намерение) throws -> КонтрольнаяТочкаНормализацииКорнейАгентов {
        try JSONDecoder().decode(КонтрольнаяТочкаНормализацииКорнейАгентов.self, from: намерение.каноническиеБайты)
    }

    func записать(_ путь: String, _ байты: Data) throws {
        let компоненты = путь.split(separator: "/").map(String.init)
        guard let имя = компоненты.last, !компоненты.dropLast().isEmpty else {
            throw ОшибкаФикстурыНормализации.путь
        }
        var каталог = корень.path
        for часть in компоненты.dropLast() {
            каталог += "/" + часть
            if mkdir(каталог, 0o700) != 0 && errno != EEXIST {
                throw ОшибкаФикстурыНормализации.путь
            }
        }
        let адрес = каталог + "/" + имя
        let descriptor = open(address: адрес, bytes: байты)
        guard descriptor else { throw ОшибкаФикстурыНормализации.файл }
    }

    private func git(_ аргументы: [String]) throws -> Data {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["-C", корень.path] + аргументы
        процесс.standardOutput = Pipe()
        процесс.standardError = FileHandle.nullDevice
        try процесс.run()
        let данные = (процесс.standardOutput as! Pipe).fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard процесс.terminationStatus == 0 else { throw ОшибкаФикстурыНормализации.git }
        return данные
    }
}

private actor ХранилищеКонтрольныхТочек {
    private var последнееЗначение: КонтрольнаяТочкаНормализацииКорнейАгентов.Намерение?
    private var счётчик = 0
    private let ошибкаПослеСохраненияНомера: Int?
    private var ошибкаПередФазой: КонтрольнаяТочкаНормализацииКорнейАгентов.ФазаНамерения?
    private let несовпадающееПеречитывание: Bool

    init(
        ошибкаПослеСохраненияНомера: Int? = nil,
        ошибкаПередФазой: КонтрольнаяТочкаНормализацииКорнейАгентов.ФазаНамерения? = nil,
        несовпадающееПеречитывание: Bool = false
    ) {
        self.ошибкаПослеСохраненияНомера = ошибкаПослеСохраненияНомера
        self.ошибкаПередФазой = ошибкаПередФазой
        self.несовпадающееПеречитывание = несовпадающееПеречитывание
    }

    func сохранить(
        _ значение: КонтрольнаяТочкаНормализацииКорнейАгентов.Намерение
    ) throws -> КонтрольнаяТочкаНормализацииКорнейАгентов.Намерение {
        счётчик += 1
        if значение.фаза == ошибкаПередФазой {
            ошибкаПередФазой = nil
            throw ОшибкаФикстурыНормализации.квитанция
        }
        последнееЗначение = значение
        if счётчик == ошибкаПослеСохраненияНомера { throw ОшибкаФикстурыНормализации.квитанция }
        if несовпадающееПеречитывание {
            return .init(
                operationID: значение.operationID,
                фаза: значение.фаза,
                каноническиеБайты: значение.каноническиеБайты,
                sha256: String(repeating: "0", count: 64))
        }
        return значение
    }

    func последнее() -> КонтрольнаяТочкаНормализацииКорнейАгентов.Намерение? { последнееЗначение }
    func числоСохранений() -> Int { счётчик }
    func предзагрузить(_ значение: КонтрольнаяТочкаНормализацииКорнейАгентов.Намерение) {
        последнееЗначение = значение
    }
}

private enum ОшибкаФикстурыНормализации: Error {
    case путь
    case файл
    case git
    case квитанция
}

private func open(address: String, bytes: Data) -> Bool {
    let descriptor = Darwin.open(address, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
    guard descriptor >= 0 else { return false }
    defer { close(descriptor) }
    return bytes.withUnsafeBytes { буфер in
        guard let начало = буфер.baseAddress else { return true }
        var смещение = 0
        while смещение < буфер.count {
            let число = write(descriptor, начало.advanced(by: смещение), буфер.count - смещение)
            if число <= 0 { return false }
            смещение += число
        }
        return fsync(descriptor) == 0
    }
}

private func текст(_ данные: Data) throws -> String {
    guard let значение = String(data: данные, encoding: .utf8) else {
        throw ОшибкаФикстурыНормализации.git
    }
    return значение.trimmingCharacters(in: .newlines)
}

private func sha256(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}
