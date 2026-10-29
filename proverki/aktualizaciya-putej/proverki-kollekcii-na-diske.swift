import Foundation
import Testing
import Darwin
#if !ФУМ_ОБЩАЯ_МИГРАЦИЯ_ТЕСТ
@testable import АктуализацияПутей
#endif

@Suite("Закрытый физический состав частной коллекции без допуска запуска")
struct ПроверкиКоллекцииНаДиске {
    let основа = ПроверкиУчётаАртефактов()
    let корень = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true).resolvingSymlinksInPath()
    func пустыеПраваНовойФикстуры(_ дескриптор: Int32) throws {
        guard let пустые = acl_init(0) else { throw ОтказСсылокПакета.условие("не-создан-пустой-список-прав-фикстуры") }
        defer { acl_free(UnsafeMutableRawPointer(пустые)) }
        guard acl_valid(пустые) == 0 && acl_set_fd_np(дескриптор, пустые, ACL_TYPE_EXTENDED) == 0 else {
            throw ОтказСсылокПакета.условие("не-задан-пустой-список-прав-новой-фикстуры")
        }
    }
    func открытьКаталог(_ путь: URL) throws -> Int32 {
        let текст = путь.path, части = ИменаПутей.компоненты(текст, сохранятьПустые: true).dropFirst()
        guard текст.utf8.first == 47, текст.utf8.count <= 4096, !текст.utf8.contains(0), !части.isEmpty, части.count <= 128,
              части.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0.utf8.count <= 255 }) else { throw ОтказСсылокПакета.условие("неверный-путь-родителя-фикстуры") }
        var текущий = open("/", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC), оставить = false
        guard текущий >= 0 else { throw ОтказСсылокПакета.условие("не-открыт-корень-фикстуры") }
        defer { if !оставить { close(текущий) } }
        for часть in части {
            let следующий = openat(текущий, часть, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else { throw ОтказСсылокПакета.условие("не-открыт-компонент-фикстуры") }
            close(текущий); текущий = следующий
        }
        оставить = true; return текущий
    }
    func имеетПредка(_ искомый: stat, _ дескриптор: Int32) throws -> Bool {
        var текущий = fcntl(дескриптор, F_DUPFD_CLOEXEC, 0)
        guard текущий >= 0 else { throw ОтказСсылокПакета.условие("не-дублирован-родитель-фикстуры") }
        defer { close(текущий) }
        for _ in 0..<256 {
            var с = stat(), после = stat()
            guard fstat(текущий, &с) == 0 else { throw ОтказСсылокПакета.условие("не-прочитан-предок-фикстуры") }
            if с.st_dev == искомый.st_dev && с.st_ino == искомый.st_ino { return true }
            let следующий = openat(текущий, "..", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else { throw ОтказСсылокПакета.условие("не-открыт-предок-фикстуры") }
            guard fstat(следующий, &после) == 0 else { close(следующий); throw ОтказСсылокПакета.условие("не-прочитан-следующий-предок-фикстуры") }
            if с.st_dev == после.st_dev && с.st_ino == после.st_ino { close(следующий); return false }
            close(текущий); текущий = следующий
        }
        throw ОтказСсылокПакета.условие("предел-предков-фикстуры")
    }
    func каталог() throws -> URL {
        let родитель: URL
        if let заданный = ProcessInfo.processInfo.environment["ФУМ_КАТАЛОГ_ФИКСТУР_КОЛЛЕКЦИИ"] { родитель = URL(fileURLWithPath: заданный, isDirectory: true) }
        else { родитель = FileManager.default.temporaryDirectory.resolvingSymlinksInPath() }
        let верхний = try открытьКаталог(родитель)
        defer { close(верхний) }
        let ограда = try открытьКаталог(корень)
        defer { close(ограда) }
        var с = stat(), о = stat()
        guard fstat(верхний, &с) == 0, fstat(ограда, &о) == 0, с.st_uid == geteuid(), с.st_mode & 0o022 == 0,
              !(try имеетПредка(о, верхний)), !(try имеетПредка(с, ограда)) else { throw ОтказСсылокПакета.условие("родитель-фикстуры-не-внешний-или-не-собственный") }
        let имя = "fs-fixture-" + UUID().uuidString.lowercased(), путь = родитель.appendingPathComponent(имя, isDirectory: true)
        guard mkdirat(верхний, имя, 0o700) == 0 else { throw ОтказСсылокПакета.условие("не-создан-новый-каталог-фикстуры") }
        let новый = openat(верхний, имя, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard новый >= 0 else { throw ОтказСсылокПакета.условие("не-открыт-новый-каталог-фикстуры") }
        defer { close(новый) }
        try пустыеПраваНовойФикстуры(новый)
        return путь
    }
    func файл(_ к: URL, _ путь: String = "base/a.json", _ байты: Data = Data([10])) throws -> АртефактКандидатов {
        try ИменаПутей.проверитьПуть(путь)
        guard байты.count <= 33_554_432 else { throw ОтказСсылокПакета.условие("предел-байтов-фикстуры") }
        let части = ИменаПутей.компоненты(путь)
        var текущий = try открытьКаталог(к)
        defer { close(текущий) }
        for часть in части.dropLast() {
            let создан = mkdirat(текущий, часть, 0o700) == 0
            guard создан || errno == EEXIST else { throw ОтказСсылокПакета.условие("не-создан-родитель-файла-фикстуры") }
            let следующий = openat(текущий, часть, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else { throw ОтказСсылокПакета.условие("не-открыт-родитель-файла-фикстуры") }
            do { if создан { try пустыеПраваНовойФикстуры(следующий) } } catch { close(следующий); throw error }
            close(текущий); текущий = следующий
        }
        let дескриптор = openat(текущий, части[части.count - 1], O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard дескриптор >= 0 else { throw ОтказСсылокПакета.условие("лист-фикстуры-не-свежий-или-недоступен") }
        defer { close(дескриптор) }
        try пустыеПраваНовойФикстуры(дескриптор)
        try байты.withUnsafeBytes { буфер in
            var смещение = 0
            while смещение < буфер.count {
                let число = Darwin.write(дескриптор, буфер.baseAddress!.advanced(by: смещение), буфер.count - смещение)
                if число < 0 && errno == EINTR { continue }
                guard число > 0 else { throw ОтказСсылокПакета.условие("неполная-запись-фикстуры") }
                смещение += число
            }
        }
        return .init(путь: путь, хэш: хэшПутей(байты), размер: байты.count, роль: .основа)
    }
    @Test("Каждый файл совпадает с ledger, частный корень и все каталоги замкнуты")
    func замкнутыйСостав() throws {
        let к = try каталог(), а = try файл(к), б = try файл(к, "runs/r1/log", Data("Ёж\n".utf8)), у = try основа.создать([а, б])
        let р = try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: корень, учёт: у)
        #expect(р.файлы == 2 && р.каталоги == 4 && р.прочитаноБайтов == а.размер + б.размер && р.хэшУчёта == у.хэшСостава)
        #expect(р.физическиеФайлыПроверены && !р.текущаяГоловаПроверена && !р.внешняяИсторияПроверена
            && !р.терминальныйПроцессПроверен && !р.продолжениеРазрешено && !р.применениеРазрешено)
    }
    @Test("Даже пустой неучтённый temp, лишний каталог и пропавший файл блокируют census")
    func неполныйСостав() throws {
        for случай in 0..<3 {
            let к = try каталог(), а = try файл(к), у = try основа.создать([а])
            if случай == 0 { _ = try файл(к, ".temp", Data()) }
            if случай == 1 { try FileManager.default.createDirectory(at: к.appendingPathComponent("empty"), withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]) }
            if случай == 2 { try FileManager.default.removeItem(at: к.appendingPathComponent(а.путь)) }
            #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: корень, учёт: у) }
        }
    }
    @Test("Hardlink с теми же bytes и symlink не считаются обычным самостоятельным файлом")
    func ссылки() throws {
        for случай in 0..<2 {
            let к = try каталог(), а = try файл(к), у = try основа.создать([а]), адрес = к.appendingPathComponent(а.путь)
            let наружу = try каталог(), копия = наружу.appendingPathComponent("copy")
            if случай == 0 { guard link(адрес.path, копия.path) == 0 else { throw ОтказСсылокПакета.условие("не-создан-hardlink-фикстуры") } }
            else { try FileManager.default.moveItem(at: адрес, to: копия); try FileManager.default.createSymbolicLink(at: адрес, withDestinationURL: копия) }
            #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: корень, учёт: у) }
        }
    }
    @Test("Поздняя подмена прочитанного файла и привязки корня закрывается")
    func позднийДрейф() throws {
        for случай in 0..<4 {
            let к = try каталог(), а = try файл(к), у = try основа.создать([а])
            #expect(throws: (any Error).self) {
                try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: корень, учёт: у, послеЧтенияДляПроверки: {
                    if случай == 0 { try Data([11]).write(to: к.appendingPathComponent(а.путь)) }
                    else if случай == 1 { try FileManager.default.moveItem(at: к, to: к.appendingPathExtension("moved")); try FileManager.default.createDirectory(at: к, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]) }
                    else if случай == 2 { _ = try файл(к, "late.log", Data()) }
                    else { let снаружи = try каталог().appendingPathComponent("linked"); guard link(к.appendingPathComponent(а.путь).path, снаружи.path) == 0 else { throw ОтказСсылокПакета.условие("не-создан-поздний-hardlink") } }
                })
            }
        }
    }
    @Test("Подмена regular на FIFO между stat и open не блокирует процесс")
    func гонкаСпециальногоФайла() throws {
        let к = try каталог(), а = try файл(к), у = try основа.создать([а])
        #expect(throws: (any Error).self) {
            try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: корень, учёт: у, послеСтатДляПроверки: { путь in
                if путь == а.путь { try FileManager.default.removeItem(at: к.appendingPathComponent(путь)); guard mkfifo(к.appendingPathComponent(путь).path, 0o600) == 0 else { throw ОтказСсылокПакета.условие("не-создана-fifo-фикстура") } }
            })
        }
    }
    @Test("Пустая коллекция замкнута, дрейф SHA и открытые права файла не принимаются")
    func байтыИРежимы() throws {
        let пустой = try каталог(), у = try основа.создать([])
        let р = try ПроверкаКоллекцииНаДиске.проверить(каталог: пустой, внеРабочегоДерева: корень, учёт: у)
        #expect(р.файлы == 0 && р.каталоги == 1 && р.прочитаноБайтов == 0)
        for случай in 0..<3 {
            let к = try каталог(), а = try файл(к), у = try основа.создать([а]), адрес = к.appendingPathComponent(а.путь)
            if случай == 0 { try Data([11]).write(to: адрес) }
            if случай == 1 { guard chmod(адрес.path, 0o644) == 0 else { throw ОтказСсылокПакета.условие("не-изменён-режим-фикстуры") } }
            if случай == 2 { guard chmod(к.path, 0o755) == 0 else { throw ОтказСсылокПакета.условие("не-изменён-режим-корня-фикстуры") } }
            #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: корень, учёт: у) }
        }
    }
    @Test("Промежуточный symlink и пересечение физической ограды отвергаются")
    func физическийКорень() throws {
        let к = try каталог(), а = try файл(к), у = try основа.создать([а]), внешний = try каталог()
        let ссылка = внешний.appendingPathComponent("jump")
        try FileManager.default.createSymbolicLink(at: ссылка, withDestinationURL: к)
        #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверить(каталог: ссылка, внеРабочегоДерева: корень, учёт: у) }
        #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: к, учёт: у) }
        #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: к.deletingLastPathComponent(), учёт: у) }
    }
    @Test("Ограда заново проверяется по текущему пути после закрытия файлов")
    func поздняяПодменаОграды() throws {
        for случай in 0..<2 {
            let к = try каталог(), а = try файл(к), у = try основа.создать([а]), ограда = try каталог()
            #expect(throws: (any Error).self) {
                try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: ограда, учёт: у, послеЧтенияДляПроверки: {
                    try FileManager.default.moveItem(at: ограда, to: ограда.appendingPathExtension("moved"))
                    if случай == 0 { try FileManager.default.createSymbolicLink(at: ограда, withDestinationURL: к) }
                    else { try FileManager.default.createDirectory(at: ограда, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]) }
                })
            }
        }
    }
    @Test("Разрешающий расширенный ACL не маскируется режимами 0700 и 0600")
    func расширенныеПрава() throws {
        for случай in 0..<2 {
            let к = try каталог(), а = try файл(к), у = try основа.создать([а])
            let процесс = Process()
            процесс.executableURL = URL(fileURLWithPath: "/bin/chmod")
            процесс.arguments = ["+a", "everyone allow read", случай == 0 ? к.path : к.appendingPathComponent(а.путь).path]
            процесс.standardOutput = FileHandle.nullDevice; процесс.standardError = FileHandle.nullDevice
            try процесс.run(); процесс.waitUntilExit()
            guard процесс.terminationReason == .exit && процесс.terminationStatus == 0 else { throw ОтказСсылокПакета.условие("не-подготовлен-acl-собственной-фикстуры") }
            #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: корень, учёт: у) }
        }
    }
    @Test("Пределы namespace различаются до открытия физического корня")
    func пределКаталогов() throws {
        let отсутствует = try каталог().appendingPathComponent("missing")
        let хэш = хэшПутей(Data())
        let записи = (0..<32_768).map { номер in
            АртефактКандидатов(путь: String(format: "d%05d/x", номер), хэш: хэш, размер: 0, роль: .результат)
        }
        let граница = Array(записи.dropLast()) + [АртефактКандидатов(путь: "top", хэш: хэш, размер: 0, роль: .результат)]
        let допустимый = try основа.создать(граница), лишний = try основа.создать(записи)
        #expect(throws: ОтказСсылокПакета.условие("не-каталог-в-абсолютном-пути")) {
            try ПроверкаКоллекцииНаДиске.проверить(каталог: отсутствует, внеРабочегоДерева: корень, учёт: допустимый)
        }
        #expect(throws: ОтказСсылокПакета.условие("предел-каталогов-физической-коллекции")) {
            try ПроверкаКоллекцииНаДиске.проверить(каталог: отсутствует, внеРабочегоДерева: корень, учёт: лишний)
        }
    }
    @Test("Суммарная работа префиксов ограничивается до обращения к ФС")
    func пределРаботыПутей() throws {
        let отсутствует = try каталог().appendingPathComponent("missing"), часть = String(repeating: "a", count: 250), хэш = хэшПутей(Data())
        let записи = (0..<32_768).map { номер in
            АртефактКандидатов(путь: часть + "/" + часть + "/" + часть + "/" + String(format: "f%05d", номер), хэш: хэш, размер: 0, роль: .результат)
        }
        let у = try основа.создать(записи)
        #expect(throws: ОтказСсылокПакета.условие("предел-путей-физической-коллекции")) {
            try ПроверкаКоллекцииНаДиске.проверить(каталог: отсутствует, внеРабочегоДерева: корень, учёт: у)
        }
    }
    @Test("Только положительный returned bit и точная пустая запись доказывают отсутствие ACE")
    func представлениеПустыхПрав() throws {
        var байты = Data(repeating: 0, count: 76)
        func задать(_ д: inout Data, _ смещение: Int, _ значение: UInt32) {
            var число = значение
            withUnsafeBytes(of: &число) { д.replaceSubrange(смещение..<(смещение + 4), with: $0) }
        }
        for (смещение, значение): (Int, UInt32) in [(0, 76), (4, 0x80400000), (24, 8), (28, 44), (32, 0x012cc16d)] { задать(&байты, смещение, значение) }
        try ПроверкаКоллекцииНаДиске.проверитьПредставлениеПустыхПрав(байты)
        var обёртка = Data([255]); обёртка.append(байты); обёртка.append(255)
        try ПроверкаКоллекцииНаДиске.проверитьПредставлениеПустыхПрав(обёртка[1..<77])
        for (смещение, значение): (Int, UInt32) in [(0, 75), (0, 77), (4, 0x80000000), (8, 1), (12, 1), (16, 1), (20, 1),
            (24, UInt32.max), (24, 0), (24, 9), (28, 43), (28, 45), (32, 0), (68, 1), (68, UInt32.max), (72, 1)] {
            var другой = байты; задать(&другой, смещение, значение)
            #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверитьПредставлениеПустыхПрав(другой) }
        }
        for другой in [Data(байты.prefix(32)), Data(байты.dropLast()), байты + Data([0]), Data(repeating: 0, count: 4097)] {
            #expect(throws: (any Error).self) { try ПроверкаКоллекцииНаДиске.проверитьПредставлениеПустыхПрав(другой) }
        }
    }
    @Test("Помощник свежей фикстуры отказывает до перезаписи прежних байтов и ACL")
    func исключительноеСозданиеФикстуры() throws {
        let к = try каталог(), а = try файл(к), у = try основа.создать([а])
        #expect(throws: (any Error).self) { try файл(к, а.путь, Data([12])) }
        let р = try ПроверкаКоллекцииНаДиске.проверить(каталог: к, внеРабочегоДерева: корень, учёт: у)
        #expect(р.файлы == 1 && р.прочитаноБайтов == 1)
    }
}
