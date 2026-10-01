import CryptoKit
import Darwin
import Foundation
import XCTest
import ПробыМоста
import МостЛибторрента
@testable import ЛокальныйТоррент

final class ОбработчикЛибторрентаТесты: XCTestCase {
    func test_ОтменаЗадачиУдержанногоСоздателя() async throws {
        try await сФайлом { файл in
            let обработчик = ОбработчикЛибторрента(создатель: удерживающийСоздатель)
            let отмена = ОтменаПодготовкиТоррента()
            let ограничения = try ОграниченияПодготовкиТоррента(максимумБайтФайла: 3, длинаЧастиБайт: 16384, максимумБайтМетаданных: 200)
            let задача = Task {
                defer { наблюдениеОтмены.отметитьВозврат() }
                return try await обработчик.создать(адресФайла: файл, имяФайла: "a", размерФайла: 3,
                    ожидаемыйХэшСодержимого: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
                    ограничения: ограничения, отмена: отмена, ход: { _ in })
            }
            defer { задача.cancel(); наблюдениеОтмены.отпустить() }
            let вошёл = await дождатьсяНаблюдения(отмену: false)
            задача.cancel()
            var обаФлага = false
            if вошёл { обаФлага = await дождатьсяНаблюдения(отмену: true) }
            let преждевременноВернулся = наблюдениеОтмены.состояние().вернулся
            наблюдениеОтмены.отпустить()
            do { _ = try await задача.value; XCTFail("отмена обязательна") }
            catch { XCTAssertEqual(error as? ОшибкаПодготовкиТоррента, .отменено) }
            XCTAssertTrue(вошёл); XCTAssertTrue(обаФлага); XCTAssertFalse(преждевременноВернулся)
            XCTAssertFalse(наблюдениеОтмены.состояние().истёкСрок)
            let новая = try await вызов(ОбработчикЛибторрента(создатель: создать_полную_фикстуру_метаданных), файл)
            XCTAssertEqual(новая, try ОракулМетаданных.пример().0)
        }
    }
    func test_ПрофильОфлайнГраницы() async throws {
        guard ProcessInfo.processInfo.environment["ФУМ_ПРОФИЛЬ_ТОРРЕНТА"] == "1" else {
            throw XCTSkip("профиль запускается отдельной командой")
        }
        var стадии = [[String: Any]]()
        func измерить(_ имя: String, число: Int = 1, _ действие: () async throws -> Void) async throws {
            for _ in 0..<2 { try await действие() }
            var пробы = [UInt64]()
            for _ in 0..<9 {
                let начало = DispatchTime.now().uptimeNanoseconds
                try await действие()
                пробы.append(DispatchTime.now().uptimeNanoseconds - начало)
            }
            стадии.append(["имя": имя, "вызовов_в_пробе": число, "пробы_нс": пробы])
        }
        try await сФайлом { файл in
            let эталон = try ОракулМетаданных.пример().0
            let ограничения = try ОграниченияПодготовкиТоррента(максимумБайтФайла: 3, длинаЧастиБайт: 16384, максимумБайтМетаданных: 4200)
            let хэш = Array(SHA256.hash(data: Data("abc".utf8)))
            let исходник = Darwin.open(файл.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
            let каталог = Darwin.open(файл.deletingLastPathComponent().path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
            XCTAssertGreaterThanOrEqual(исходник, 0); XCTAssertGreaterThanOrEqual(каталог, 0)
            defer { Darwin.close(исходник); Darwin.close(каталог) }
            try await измерить("снимок_C_ABI_фикстура_копирование_очистка") {
                var операция: OpaquePointer?
                XCTAssertEqual(создать_операцию_торрента(&операция).код, 0)
                defer { уничтожить_операцию_торрента(операция) }
                var выход: OpaquePointer?
                defer { уничтожить_метаданные_торрента(выход) }
                let ответ = хэш.withUnsafeBufferPointer { адресХэша in
                    "a".withCString { имя in
                        var вход = ВходМостаТоррента(исходник: исходник, каталог: каталог, имя: имя,
                            длина_имени: 1, размер: 3, максимум_файла: 3, длина_части: 16384,
                            максимум_метаданных: 200, хэш: адресХэша.baseAddress, длина_хэша: 32,
                            операция: операция, проверка_отмены: nil, контекст: nil)
                        return создать_полную_фикстуру_метаданных(&вход, &выход)
                    }
                }
                XCTAssertEqual(ответ.код, 0)
                var длина = 0
                let байты = try XCTUnwrap(байты_метаданных_торрента(try XCTUnwrap(выход), &длина))
                XCTAssertEqual(Data(bytes: байты, count: длина), эталон.бенкодированныеДанные)
                XCTAssertEqual(String(cString: try XCTUnwrap(хэш_первой_версии_торрента(выход))), эталон.хэшиИнформации.хэшВерсии1)
                XCTAssertEqual(String(cString: try XCTUnwrap(хэш_второй_версии_торрента(выход))), эталон.хэшиИнформации.хэшВерсии2)
                XCTAssertEqual(Darwin.lseek(исходник, 0, SEEK_CUR), 0)
                XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: файл.deletingLastPathComponent().path), ["a"])
            }
            try await измерить("проверка_метаданных_Swift", число: 256) {
                for _ in 0..<256 { try ПроверкаМетаданныхТоррента.проверить(эталон, имя: "a", размер: 3, ограничения: ограничения) }
            }
            let адаптер = АдаптерЛокальногоТоррента(обработчик: ОбработчикЛибторрента(создатель: создать_полную_фикстуру_метаданных))
            try await измерить("полный_вызов_ядра_с_фикстурой") {
                let артефакт = try await адаптер.подготовить(файл: ВыборЛокальногоФайла(адрес: файл), ограничения: ограничения)
                XCTAssertEqual(артефакт.бенкодированныеМетаданные, эталон.бенкодированныеДанные)
            }
        }
        var потребление = rusage()
        XCTAssertEqual(Darwin.getrusage(0, &потребление), 0)
        let профиль: [String: Any] = ["схема": "fum.профиль-офлайн-торрента.1", "стадии": стадии,
            "прогревов": 2, "повторов": 9, "максимум_резидентной_памяти_байт": потребление.ru_maxrss,
            "корпус": "a/abc; N=3; P=16384; torrent=200",
            "граница": "Release XCTest; память всего процесса включая harness; preparation вне таймеров",
            "производственный_либторрент": "отложено: зависимость не зарегистрирована",
            "прямое_сравнение_либторрента": "отложено"]
        let данные = try JSONSerialization.data(withJSONObject: профиль, options: [.sortedKeys])
        print("ФУМ-ПРОФИЛЬ:" + String(decoding: данные, as: UTF8.self))
    }
    func test_НеВозвращаетУспехПриОстаткеВЧастномКаталоге() async throws {
        try await сФайлом { файл in
            наблюдениеКаталога.записать(nil)
            defer {
                if let путь = наблюдениеКаталога.прочитать() {
                    _ = Darwin.unlink(путь + "/маркер-теста")
                    _ = Darwin.rmdir(путь)
                }
            }
            let обработчик = ОбработчикЛибторрента(создатель: создатьСОстатком)
            do { _ = try await вызов(обработчик, файл); XCTFail("очистка должна подтверждаться") }
            catch {
                guard case .сбойОбработчика(let текст) = error as? ОшибкаПодготовкиТоррента else { return XCTFail("\(error)") }
                XCTAssertTrue(текст.contains("очистка"))
            }
            let путь = try XCTUnwrap(наблюдениеКаталога.прочитать())
            XCTAssertTrue(FileManager.default.fileExists(atPath: путь + "/маркер-теста"))
        }
    }
    func сФайлом(_ действие: (URL) async throws -> Void) async throws {
        let папка = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: папка, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: папка) }
        let файл = папка.appendingPathComponent("a"); try Data("abc".utf8).write(to: файл)
        try await действие(файл)
    }
    func вызов(_ обработчик: ОбработчикЛибторрента, _ файл: URL,
               отмена: ОтменаПодготовкиТоррента = ОтменаПодготовкиТоррента()) async throws -> СозданныеМетаданныеТоррента {
        try await обработчик.создать(адресФайла: файл, имяФайла: "a", размерФайла: 3,
            ожидаемыйХэшСодержимого: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            ограничения: ОграниченияПодготовкиТоррента(максимумБайтФайла: 3, длинаЧастиБайт: 16384, максимумБайтМетаданных: 200),
            отмена: отмена, ход: { _ in })
    }
    func test_ФикстураПроходитНастоящийСнимокИВладениеБайтами() async throws {
        try await сФайлом { файл in
            let обработчик = ОбработчикЛибторрента(создатель: создать_полную_фикстуру_метаданных)
            let результат = try await вызов(обработчик, файл)
            XCTAssertEqual(результат, try ОракулМетаданных.пример().0)
            let адаптер = АдаптерЛокальногоТоррента(обработчик: обработчик)
            let артефакт = try await адаптер.подготовить(файл: ВыборЛокальногоФайла(адрес: файл),
                ограничения: ОграниченияПодготовкиТоррента(максимумБайтФайла: 3, длинаЧастиБайт: 16384, максимумБайтМетаданных: 4200))
            XCTAssertEqual(артефакт.бенкодированныеМетаданные, результат.бенкодированныеДанные)
        }
    }
    func test_ПредварительнаяОтменаИСвежаяПопытка() async throws {
        try await сФайлом { файл in
            let обработчик = ОбработчикЛибторрента(создатель: создать_полную_фикстуру_метаданных)
            let отмена = ОтменаПодготовкиТоррента(); отмена.отменить()
            do { _ = try await вызов(обработчик, файл, отмена: отмена); XCTFail("отмена обязательна") }
            catch { XCTAssertEqual(error as? ОшибкаПодготовкиТоррента, .отменено) }
            let новая = try await вызов(обработчик, файл)
            XCTAssertEqual(новая.бенкодированныеДанные.count, 200)
        }
    }
    func test_ПроизводственныйОбработчикЯвноНедоступенДоРегистрации() async throws {
        try await сФайлом { файл in
            do { _ = try await вызов(ОбработчикЛибторрента(), файл); XCTFail("нельзя выдавать фикстуру за libtorrent") }
            catch {
                guard case .сбойОбработчика(let сообщение) = error as? ОшибкаПодготовкиТоррента else { return XCTFail("\(error)") }
                XCTAssertTrue(сообщение.contains("libtorrent не зарегистрирован"))
            }
        }
    }
}

private final class НаблюдениеКаталога: @unchecked Sendable {
    private let замок = NSLock()
    private var путь: String?
    func записать(_ значение: String?) { замок.lock(); defer { замок.unlock() }; путь = значение }
    func прочитать() -> String? { замок.lock(); defer { замок.unlock() }; return путь }
}
private let наблюдениеКаталога = НаблюдениеКаталога()

private final class НаблюдательОтмены: @unchecked Sendable {
    private let условие = NSCondition()
    private var вошёл = false
    private var обаФлага = false
    private var отпущен = false
    private var вернулся = false
    private var истёкСрок = false
    func удержать(_ вход: ВходМостаТоррента) -> Bool {
        условие.lock(); вошёл = true; условие.broadcast(); условие.unlock()
        let предел = Date().addingTimeInterval(5)
        while Date() < предел {
            let флагМоста = запрошена_отмена_торрента(вход.операция) != 0
            let флагТокена = (вход.проверка_отмены?(вход.контекст) ?? 0) != 0
            условие.lock()
            обаФлага = обаФлага || (флагМоста && флагТокена); условие.broadcast()
            if отпущен { условие.unlock(); return true }
            _ = условие.wait(until: min(предел, Date().addingTimeInterval(0.01)))
            условие.unlock()
        }
        условие.lock(); истёкСрок = true; условие.broadcast(); условие.unlock()
        return false
    }
    func ждать(отмену: Bool) -> Bool {
        условие.lock(); defer { условие.unlock() }
        let предел = Date().addingTimeInterval(6)
        while !(отмену ? обаФлага : вошёл), Date() < предел { _ = условие.wait(until: предел) }
        return отмену ? обаФлага : вошёл
    }
    func отпустить() { условие.lock(); defer { условие.unlock() }; отпущен = true; условие.broadcast() }
    func отметитьВозврат() { условие.lock(); defer { условие.unlock() }; вернулся = true }
    func состояние() -> (вернулся: Bool, истёкСрок: Bool) {
        условие.lock(); defer { условие.unlock() }; return (вернулся, истёкСрок)
    }
}
private let наблюдениеОтмены = НаблюдательОтмены()
private let удерживающийСоздатель: СоздательМоста = { вход, адрес in
    guard let вход, наблюдениеОтмены.удержать(вход.pointee) else {
        var ответ = РезультатГраницыМоста(); ответ.код = 1; return ответ
    }
    return создать_полную_фикстуру_метаданных(вход, адрес)
}
private func дождатьсяНаблюдения(отмену: Bool) async -> Bool {
    await withCheckedContinuation { продолжение in
        DispatchQueue.global().async { продолжение.resume(returning: наблюдениеОтмены.ждать(отмену: отмену)) }
    }
}
private func создатьСОстатком(_ вход: UnsafePointer<ВходМостаТоррента>?,
                            _ выход: UnsafeMutablePointer<OpaquePointer?>?) -> РезультатГраницыМоста {
    guard let вход else { return создать_полную_фикстуру_метаданных(вход, выход) }
    var путь = [CChar](repeating: 0, count: Int(MAXPATHLEN))
    let код = путь.withUnsafeMutableBufferPointer { прочитать_путь_каталога_фикстуры(вход.pointee.каталог, $0.baseAddress, $0.count) }
    if код == 0 { наблюдениеКаталога.записать(String(decoding: путь.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)) }
    let маркер = Darwin.openat(вход.pointee.каталог, "маркер-теста", O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0o600)
    if маркер >= 0 { Darwin.close(маркер) }
    return создать_полную_фикстуру_метаданных(вход, выход)
}
