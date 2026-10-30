import Foundation
import Darwin
import Testing

struct ПроверкиЗахвата {
    @Test static func проверитьЗахват() throws {
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
                намерение: каталог + "/намерение.json", процесс: каталог + "/процесс.json", исход: каталог + "/исход.json",
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
}

@main struct ЗапускПроверокЗахвата {
    static func main() async {
        var параметры = Testing.__CommandLineArguments_v0()
        параметры.parallel = false
        let код: CInt = await Testing.__swiftPMEntryPoint(passing: параметры); exit(код)
    }
}
