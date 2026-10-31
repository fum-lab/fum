import Foundation
import Darwin
import Testing

struct ПроверкиЗахвата {
    #if !ДИАГНОСТИКА && !РЕСУРСЫ && !ТОЛЬКО_МЕТРИКА
    @Test
    #endif
    static func проверитьЗахват() throws {
        let корень = try #require(ProcessInfo.processInfo.environment["ФУМ_КАТАЛОГ_ФИКСТУР"])
        let исполняемый = try #require(ProcessInfo.processInfo.environment["ФУМ_ЗАХВАТ_КОМАНДЫ"])
        func проверить(_ условие: Bool, _ пояснение: String) throws {
            guard условие else { throw ОшибкаЗахвата.отказ(пояснение) }
        }
        func запрос(_ имя: String, _ команда: String, секунд: Double = 2, предел: Int = 1024) throws -> ЗапросЗахвата {
            let каталог = корень + "/" + имя
            try FileManager.default.createDirectory(atPath: каталог, withIntermediateDirectories: false)
            return ЗапросЗахвата(попытка: имя, исполняемый: "/bin/sh",
                хэшИсполняемого: хэш(try Data(contentsOf: URL(fileURLWithPath: "/bin/sh"))),
                аргументы: ["-c", команда], вывод: каталог + "/вывод", ошибки: каталог + "/ошибки",
                намерение: каталог + "/намерение.json", процесс: каталог + "/процесс.json", исход: каталог + "/исход.json", наблюдениеОчистки: каталог + "/наблюдение-cleanup.json",
                секунд: секунд, пределВывода: предел, пределОшибок: 1024)
        }
        let первый = try запрос("байты", "printf 'abc\\000def'")
        let итог = try захватить(первый, хэшЗапроса: "фикстура")
        try проверить(итог["код"] as? Int == 0, "exit0")
        try проверить(try Data(contentsOf: URL(fileURLWithPath: первый.вывод)) == Data([97,98,99,0,100,101,102]), "точные байты")
        let второй = try запрос("отказ", "printf err >&2; exit 7")
        let отказ = try захватить(второй, хэшЗапроса: "фикстура")
        try проверить(отказ["код"] as? Int == 7 && отказ["байтОшибок"] as? Int == 3, "nonzero stderr")
        let третий = try запрос("существует", "touch '" + корень + "/нельзя'")
        try Data([42]).write(to: URL(fileURLWithPath: третий.вывод))
        var отклонён = false
        do { _ = try захватить(третий, хэшЗапроса: "фикстура") } catch { отклонён = true }
        try проверить(отклонён && !FileManager.default.fileExists(atPath: третий.намерение) && !FileManager.default.fileExists(atPath: корень + "/нельзя"), "отказ до spawn")
        let четвёртый = try запрос("предел", "while :; do printf 1234567890; done", предел: 100)
        let предел = try захватить(четвёртый, хэшЗапроса: "фикстура")
        try проверить(предел["причина"] as? String == "предел-вывода" && предел["байтВывода"] as? Int == 100 && предел["собран"] as? Bool == true && предел["чтениеСовпало"] as? Bool == true, "cap")
        let пятый = try запрос("таймаут", "sleep 10 & wait", секунд: 0.15)
        let таймаут = try захватить(пятый, хэшЗапроса: "фикстура")
        try проверить(таймаут["причина"] as? String == "таймаут" && таймаут["собран"] as? Bool == true && таймаут["сигнал"] as? Int == Int(SIGKILL), "timeout reap")
        let шестой = try запрос("прерывание", "sleep 10", секунд: 3)
        let данные = try JSONEncoder().encode(шестой)
        let вход = корень + "/запрос.json"; try данные.write(to: URL(fileURLWithPath: вход))
        let обёртка = Process(); обёртка.executableURL = URL(fileURLWithPath: исполняемый); обёртка.arguments = [вход, хэш(данные)]
        try обёртка.run()
        let граница = Date().addingTimeInterval(2)
        while !FileManager.default.fileExists(atPath: шестой.процесс) && Date() < граница { usleep(10000) }
        try проверить(FileManager.default.fileExists(atPath: шестой.процесс), "durable identity")
        kill(обёртка.processIdentifier, SIGTERM); обёртка.waitUntilExit()
        let запись = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: шестой.исход))) as! [String: Any]
        try проверить(запись["собран"] as? Bool == true && запись["сигнал"] as? Int == Int(SIGKILL), "wrapper interrupt")
        let повтор = Process(); повтор.executableURL = URL(fileURLWithPath: исполняемый); повтор.arguments = [вход, хэш(данные)]
        try повтор.run(); повтор.waitUntilExit()
        try проверить(повтор.terminationStatus == 2, "no blind recovery/replay")
        let подмена = try запрос("подмена", "touch '" + корень + "/нельзя-подмена'")
        let оригинал = try JSONEncoder().encode(подмена)
        let путьПодмены = корень + "/подмена.json"
        try (оригинал + Data([10])).write(to: URL(fileURLWithPath: путьПодмены))
        let отказCLI = Process(); отказCLI.executableURL = URL(fileURLWithPath: исполняемый)
        отказCLI.arguments = [путьПодмены, хэш(оригинал)]; try отказCLI.run(); отказCLI.waitUntilExit()
        try проверить(отказCLI.terminationStatus == 2 && !FileManager.default.fileExists(atPath: подмена.намерение) && !FileManager.default.fileExists(atPath: корень + "/нельзя-подмена"), "CLI SHA mismatch before intent")
        let ранний = try запрос("ранний-лидер", "sleep 10 </dev/null >/dev/null 2>&1 & exit 0")
        let остаток = try захватить(ранний, хэшЗапроса: "фикстура")
        try проверить(остаток["собран"] as? Bool == true && остаток["завершениеWNOWAIT"] as? Bool == true, "leader anchor")
        if остаток["группаОтсутствует"] as? Bool != true { try проверить(остаток["состояние"] as? String == "неизвестно", "live/unknown group cannot complete") }
        let путьПотока = корень + "/поток"
        let дескриптор = try новыйФайл(путьПотока); defer { close(дескриптор) }
        let тождество = try снимок(дескриптор), байты = Data([1,2,3])
        try записатьВсё(дескриптор, байты)
        try проверить(сверитьПоток(дескриптор, путь: путьПотока, тождество: тождество, объём: 3, ожидаемыйХэш: хэш(байты), предел: 100), "FD readback")
        let изменённые: [UInt8] = [4,5,6]
        _ = изменённые.withUnsafeBytes { pwrite(дескриптор, $0.baseAddress, 3, 0) }
        try проверить(!сверитьПоток(дескриптор, путь: путьПотока, тождество: тождество, объём: 3, ожидаемыйХэш: хэш(байты), предел: 100), "same length hash drift")
        try FileManager.default.moveItem(atPath: путьПотока, toPath: путьПотока + "-старый")
        try байты.write(to: URL(fileURLWithPath: путьПотока))
        try проверить(!сверитьПоток(дескриптор, путь: путьПотока, тождество: тождество, объём: 3, ожидаемыйХэш: хэш(байты), предел: 100), "named entry replacement")
        print("Адресные фикстуры захвата завершены")
    }

    #if ТОЛЬКО_МЕТРИКА
    @Test static func проверитьРежимТолькоМетрики() throws {
        let общий = try #require(ProcessInfo.processInfo.environment["ФУМ_КАТАЛОГ_ФИКСТУР"])
        let бинарник = try #require(ProcessInfo.processInfo.environment["ФУМ_ЗАХВАТ_КОМАНДЫ"])
        let корень = общий + "/только-метрика"
        try FileManager.default.createDirectory(atPath: корень, withIntermediateDirectories: false)
        try Data([1, 2, 3]).write(to: URL(fileURLWithPath: корень + "/контроль"))
        let обычный = БюджетХранилища(корень: корень, метрика: .выделенныеФайловойСистемойБайты,
            пределБайт: 1_048_576, пределОбъектов: 100, пределГлубины: 8, секунд: 2)
        let до = try снятьРасход(обычный, срок: DispatchTime.now().uptimeNanoseconds + 2_000_000_000)
        func запустить(_ имя: String, _ бюджет: БюджетХранилища, _ код: Int32, _ состояние: String, неверныйХэш: Bool = false) throws {
            let данные = try JSONEncoder().encode(бюджет), путь = общий + "/" + имя + ".json"
            try данные.write(to: URL(fileURLWithPath: путь))
            let ожидаемый = неверныйХэш ? String(repeating: "0", count: 64) : хэш(данные)
            let процесс = Process(), вывод = Pipe(), ошибки = Pipe()
            процесс.executableURL = URL(fileURLWithPath: бинарник)
            процесс.arguments = ["--только-метрика", путь, ожидаемый]
            процесс.standardOutput = вывод; процесс.standardError = ошибки
            try процесс.run(); процесс.waitUntilExit()
            let байты = вывод.fileHandleForReading.readDataToEndOfFile()
            let байтыОшибок = ошибки.fileHandleForReading.readDataToEndOfFile()
            #expect(процесс.terminationStatus == код)
            #expect(байтыОшибок.isEmpty)
            #expect(байты.count <= 16384)
            let итог = try #require(try JSONSerialization.jsonObject(with: байты) as? [String: Any])
            #expect(итог["ребёнокЗапущен"] as? Bool == false)
            if неверныйХэш {
                #expect(итог["состояние"] as? String == "вход-отклонён")
                #expect((итог["причина"] as? String)?.contains("SHA бюджета не совпал") == true)
            } else {
                #expect(итог["хэшБюджета"] as? String == ожидаемый)
                let наблюдение = try #require(итог["наблюдениеХранилища"] as? [String: Any])
                #expect(наблюдение["состояние"] as? String == состояние)
                #expect(наблюдение["метрика"] as? String == бюджет.метрика.rawValue)
            }
            // Дословные CLI stdout доступны в outer capture с именем различающего случая.
            print(имя + ": " + String(decoding: байты, as: UTF8.self))
        }
        try запустить("ниже-порога", обычный, 0, "разрешён")
        try запустить("выше-порога", БюджетХранилища(корень: корень, метрика: .логическиеБайты,
            пределБайт: 0, пределОбъектов: 100, пределГлубины: 8, секунд: 2), 3, "превышен")
        try запустить("неизвестно", БюджетХранилища(корень: корень, метрика: .логическиеБайты,
            пределБайт: 1_048_576, пределОбъектов: 1, пределГлубины: 8, секунд: 2), 5, "неизвестно")
        try запустить("запрещённый-корень", БюджетХранилища(корень: "/", метрика: .логическиеБайты,
            пределБайт: 1_048_576, пределОбъектов: 100, пределГлубины: 8, секунд: 2), 4, "отказ")
        try запустить("неверный-хэш", обычный, 2, "вход-отклонён", неверныйХэш: true)
        var измерительВызван = false
        do {
            _ = try измеритьЗакреплённыйБюджет(общий + "/неверный-хэш.json", ожидаемыйХэш: String(repeating: "0", count: 64)) { _ in
                измерительВызван = true; return [:]
            }
            #expect(Bool(false), "Неверный SHA обязан отказать до измерителя/root")
        } catch { #expect(!измерительВызван) }
        let после = try снятьРасход(обычный, срок: DispatchTime.now().uptimeNanoseconds + 2_000_000_000)
        #expect(до == после)
        #expect(try Data(contentsOf: URL(fileURLWithPath: корень + "/контроль")) == Data([1, 2, 3]))
        #expect(try FileManager.default.contentsOfDirectory(atPath: корень).sorted() == ["контроль"])
    }
    #endif

    #if ДИАГНОСТИКА
    @Test static func диагностироватьЗомбиПослеОжидания() throws {
        let корень = try #require(ProcessInfo.processInfo.environment["ФУМ_КАТАЛОГ_ФИКСТУР"])
        let исполняемый = try #require(ProcessInfo.processInfo.environment["ФУМ_ЗАХВАТ_КОМАНДЫ"])
        let каталог = корень + "/дарвин-зомби"
        try FileManager.default.createDirectory(atPath: каталог, withIntermediateDirectories: false)
        let запрос = ЗапросЗахвата(попытка: "диагностика-зомби", исполняемый: "/bin/sh",
            хэшИсполняемого: хэш(try прочитатьФайл("/bin/sh", предел: 268435456)),
            аргументы: ["-c", "while [ ! -f \"$1\" ]; do :; done; printf abc", "зомби-барьер", каталог + "/процесс.json"], вывод: каталог + "/вывод", ошибки: каталог + "/ошибки",
            намерение: каталог + "/намерение.json", процесс: каталог + "/процесс.json",
            исход: каталог + "/исход.json", наблюдениеОчистки: каталог + "/наблюдение-cleanup.json",
            секунд: 2, пределВывода: 1024, пределОшибок: 1024)
        let данные = try JSONEncoder().encode(запрос), вход = каталог + "/запрос.json"
        try данные.write(to: URL(fileURLWithPath: вход))
        let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: исполняемый)
        процесс.arguments = [вход, хэш(данные)]
        try процесс.run(); процесс.waitUntilExit()
        let запись = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: запрос.наблюдениеОчистки))) as? [String: Any])
        let идентификатор = try #require(запись["PID"] as? Int)
        #expect(запись["начальнаяГруппа"] as? Int == идентификатор)
        #expect(запись["возвратОжидания"] as? Int == 0)
        #expect(запись["ошибкаОжидания"] as? Int == 0)
        #expect(запись["идентификаторОжидания"] as? Int == идентификатор)
        #expect(запись["якорьПодтверждён"] as? Bool == true)
        #expect(запись["собран"] as? Bool == false)
        #expect(запись["возвратГруппы"] as? Int == -1)
        #expect(запись["ошибкаГруппы"] as? Int == Int(ESRCH))
        #expect(процесс.terminationStatus == 2)
        let исход = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: запрос.исход))) as? [String: Any])
        #expect(исход["состояние"] as? String == "неизвестно")
        #expect(исход["исходПодтверждён"] as? Bool == false)
    }
    #endif

    #if РЕСУРСЫ
    @Test static func проверитьИменованныеМетрикиХранилища() throws {
        let общий = try #require(ProcessInfo.processInfo.environment["ФУМ_КАТАЛОГ_ФИКСТУР"])
        let корень = общий + "/ресурсы"
        try FileManager.default.createDirectory(atPath: корень, withIntermediateDirectories: false)
        func бюджет(_ путь: String, _ метрика: МетрикаРасхода, _ предел: UInt64, объектов: Int = 100) -> БюджетХранилища {
            БюджетХранилища(корень: путь, метрика: метрика, пределБайт: предел,
                пределОбъектов: объектов, пределГлубины: 8, секунд: 2)
        }
        let разреженный = корень + "/разреженный"
        let дескриптор = try новыйФайл(разреженный)
        guard ftruncate(дескриптор, 1_073_741_824) == 0 else { close(дескриптор); throw ОшибкаРасхода.неизвестно("Нет sparse fixture") }
        var байт: UInt8 = 42
        let запись = withUnsafePointer(to: &байт) { pwrite(дескриптор, $0, 1, 1_073_741_823) }
        guard запись == 1, fsync(дескриптор) == 0 else { close(дескриптор); throw ОшибкаРасхода.неизвестно("Нет sparse write") }
        close(дескриптор)
        let выделенные = измеритьБюджетХранилища(бюджет(корень, .выделенныеФайловойСистемойБайты, 2_097_152))
        let логические = измеритьБюджетХранилища(бюджет(корень, .логическиеБайты, 2_097_152))
        #expect(выделенные["состояние"] as? String == "разрешён")
        #expect(выделенные["метрика"] as? String == "filesystemReportedAllocatedBytes")
        #expect(логические["состояние"] as? String == "превышен")
        #expect(логические["метрика"] as? String == "logicalBytes")
        #expect(выделенные["логическиеБайтыФайлов"] as? UInt64 == 1_073_741_824)
        #expect(выделенные["эксклюзивныеФизическиеБайты"] as? String == "неизвестно")
        try FileManager.default.linkItem(atPath: разреженный, toPath: корень + "/вторая-ссылка")
        let ссылки = измеритьБюджетХранилища(бюджет(корень, .выделенныеФайловойСистемойБайты, 2_097_152))
        #expect(ссылки["логическиеБайтыФайлов"] as? UInt64 == 1_073_741_824)
        #expect(ссылки["выделенныеФайловойСистемойБайтыФайлов"] as? UInt64 == выделенные["выделенныеФайловойСистемойБайтыФайлов"] as? UInt64)
        #expect(ссылки["уникальныхОбъектов"] as? Int == 2)
        #expect(ссылки["записейПутей"] as? Int == 3)
        let нестабильный = измеритьБюджетХранилища(бюджет(корень, .логическиеБайты, UInt64.max)) {
            let изменяемый = open(разреженный, O_WRONLY | O_NOFOLLOW)
            guard изменяемый >= 0 else { throw ОшибкаРасхода.неизвестно("Нет drift FD") }
            defer { close(изменяемый) }
            guard ftruncate(изменяемый, 1_073_741_823) == 0 else { throw ОшибкаРасхода.неизвестно("Нет drift") }
        }
        #expect(нестабильный["состояние"] as? String == "неизвестно")
        #expect(нестабильный["логическиеБайты"] == nil)
        let ограниченный = измеритьБюджетХранилища(бюджет(корень, .логическиеБайты, UInt64.max, объектов: 1))
        #expect(ограниченный["состояние"] as? String == "неизвестно")
        let наружный = общий + "/внешний"
        try FileManager.default.createDirectory(atPath: наружный, withIntermediateDirectories: false)
        try Data([7]).write(to: URL(fileURLWithPath: наружный + "/контроль"))
        let опасный = общий + "/проверка-ссылки"
        try FileManager.default.createDirectory(atPath: опасный, withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(atPath: опасный + "/наружу", withDestinationPath: наружный)
        #expect(измеритьБюджетХранилища(бюджет(опасный, .логическиеБайты, UInt64.max))["состояние"] as? String == "отказ")
        #expect(измеритьБюджетХранилища(бюджет(опасный + "/наружу", .логическиеБайты, UInt64.max))["состояние"] as? String == "отказ")
        #expect(try Data(contentsOf: URL(fileURLWithPath: наружный + "/контроль")) == Data([7]))
        let тип = общий + "/неизвестный-тип"
        try FileManager.default.createDirectory(atPath: тип, withIntermediateDirectories: false)
        guard mkfifo(тип + "/канал", 0o600) == 0 else { throw ОшибкаРасхода.неизвестно("Нет FIFO fixture") }
        #expect(измеритьБюджетХранилища(бюджет(тип, .логическиеБайты, UInt64.max))["состояние"] as? String == "неизвестно")
        var переполнение = false
        do { _ = try сложитьРасход(UInt64.max, 1) } catch { переполнение = true }
        #expect(переполнение)
        #expect(измеритьБюджетХранилища(бюджет("/", .логическиеБайты, UInt64.max))["состояние"] as? String == "отказ")

        let бинарник = try #require(ProcessInfo.processInfo.environment["ФУМ_ЗАХВАТ_КОМАНДЫ"])
        func проверитьВходБюджета(_ имя: String, _ метрика: МетрикаРасхода, допускается: Bool) throws {
            let каталог = общий + "/" + имя
            try FileManager.default.createDirectory(atPath: каталог, withIntermediateDirectories: false)
            let маркер = каталог + "/дочерний-маркер"
            var запрос = ЗапросЗахвата(попытка: имя, исполняемый: "/bin/sh",
                хэшИсполняемого: хэш(try прочитатьФайл("/bin/sh", предел: 268435456)),
                аргументы: ["-c", "printf abc; : > '" + маркер + "'"],
                вывод: каталог + "/вывод", ошибки: каталог + "/ошибки", намерение: каталог + "/намерение.json",
                процесс: каталог + "/процесс.json", исход: каталог + "/исход.json",
                наблюдениеОчистки: каталог + "/наблюдение.json", секунд: 2, пределВывода: 1024, пределОшибок: 1024)
            запрос.бюджетХранилища = бюджет(корень, метрика, 2_097_152)
            let данные = try JSONEncoder().encode(запрос), путь = каталог + "/вход.json"
            try данные.write(to: URL(fileURLWithPath: путь))
            let процесс = Process(); процесс.executableURL = URL(fileURLWithPath: бинарник)
            процесс.arguments = [путь, хэш(данные)]
            try процесс.run(); процесс.waitUntilExit()
            #expect(FileManager.default.fileExists(atPath: маркер) == допускается)
            #expect(FileManager.default.fileExists(atPath: запрос.процесс) == допускается)
            let намерение = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: запрос.намерение))) as? [String: Any])
            #expect(намерение["метрикаХранилища"] as? String == метрика.rawValue)
            if !допускается {
                let исход = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: запрос.исход))) as? [String: Any])
                #expect(процесс.terminationStatus == 2)
                #expect(исход["состояние"] as? String == "бюджет-превышен")
                #expect(исход["ребёнокЗапущен"] as? Bool == false)
                #expect(!FileManager.default.fileExists(atPath: запрос.вывод))
            }
            // Допуск allocated не означает GREEN cleanup: прежний guard этой фазы не ослаблен.
        }
        try проверитьВходБюджета("вход-logical", .логическиеБайты, допускается: false)
        try проверитьВходБюджета("вход-allocated", .выделенныеФайловойСистемойБайты, допускается: true)
        let сериализация = try JSONEncoder().encode(бюджет(корень, .логическиеБайты, 1024))
        let неизвестнаяМетрика = String(decoding: сериализация, as: UTF8.self).replacingOccurrences(of: "logicalBytes", with: "unknownMetric")
        var неизвестнаяОтклонена = false
        do { _ = try JSONDecoder().decode(БюджетХранилища.self, from: Data(неизвестнаяМетрика.utf8)) } catch { неизвестнаяОтклонена = true }
        #expect(неизвестнаяОтклонена)

    }
    #endif
}

@main struct ЗапускПроверокЗахвата {
    static func main() async {
        var параметры = Testing.__CommandLineArguments_v0()
        параметры.parallel = false
        let код: CInt = await Testing.__swiftPMEntryPoint(passing: параметры); exit(код)
    }
}
