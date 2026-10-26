import Foundation
import Testing
import CryptoKit
import АрхивКодекса
import Darwin

final class МаркерПакетаАрхива: NSObject {}

enum ОшибкаПроверкиЗапуска: Error {
    case дрейфБинарника
    case неожиданныйЗапуск
}

@Suite(.serialized)
struct ПроцессыАрхиваКодекса {
    func хэшФайла(_ путь: URL) throws -> String {
        let файл = try FileHandle(forReadingFrom: путь)
        defer { try? файл.close() }
        var хэш = SHA256()
        while try autoreleasepool(invoking: {
            let часть = try файл.read(upToCount: 1_048_576) ?? Data()
            хэш.update(data: часть)
            return !часть.isEmpty
        }) {}
        return хэш.finalize().map { String(format: "%02x", $0) }.joined()
    }

    func состав(_ корень: URL) throws -> [String: String] {
        var результат: [String: String] = [:]
        for имя in try FileManager.default.contentsOfDirectory(atPath: корень.path).sorted() {
            let каталог = корень.appendingPathComponent(имя)
            let имена = try FileManager.default.contentsOfDirectory(atPath: каталог.path).sorted()
            #expect(имена == ["сегмент.fumobs"])
            for файл in имена {
                результат[имя + "/" + файл] = try хэшФайла(каталог.appendingPathComponent(файл))
            }
        }
        return результат
    }
    func бинарник() throws -> URL {
        var путь = Bundle(for: МаркерПакетаАрхива.self).bundleURL.deletingLastPathComponent()
        while путь.path != "/" {
            let файл = путь.appendingPathComponent("fuma")
            if FileManager.default.isExecutableFile(atPath: файл.path) { return файл }
            путь.deleteLastPathComponent()
        }
        throw ОшибкаАрхиваКодекса.небезопасныйПуть
    }

    func процесс(_ программа: URL, _ аргументы: [String], ожидаемыйКод: Int32 = 0,
                 ожидаемыйХэш: String? = nil,
                 запустить: (Process) throws -> Void = { try $0.run() }) throws -> [String: Any] {
        let закреплённый = try хэшФайла(программа)
        if let ожидаемыйХэш, закреплённый != ожидаемыйХэш {
            throw ОшибкаПроверкиЗапуска.дрейфБинарника
        }
        let процесс = Process(), вывод = Pipe(), ошибки = Pipe()
        процесс.executableURL = программа; процесс.arguments = ["архив-codex"] + аргументы
        процесс.standardOutput = вывод; процесс.standardError = ошибки
        let часы = ContinuousClock(), начало = часы.now
        try запустить(процесс); процесс.waitUntilExit()
        let интервал = начало.duration(to: часы.now)
        let данные = вывод.fileHandleForReading.readDataToEndOfFile()
        _ = ошибки.fileHandleForReading.readDataToEndOfFile()
        #expect(процесс.terminationStatus == ожидаемыйКод)
        #expect(try хэшФайла(программа) == закреплённый)
        var итог = try #require(JSONSerialization.jsonObject(with: данные) as? [String: Any])
        итог["процессСекунды"] = Double(интервал.components.seconds) + Double(интервал.components.attoseconds) * 1e-18
        итог["бинарникSHA256"] = закреплённый
        return итог
    }

    @Test func дрейфЗакреплённогоБинарникаОстанавливаетЗапуск() throws {
        let путь = try ПроверкиАрхиваКодекса().каталог()
        defer { try? FileManager.default.removeItem(at: путь) }
        let программа = путь.appendingPathComponent("фикстура")
        try Data([1]).write(to: программа)
        let закреплённый = try хэшФайла(программа)
        try Data([2]).write(to: программа)
        var запусков = 0
        do {
            _ = try процесс(программа, [], ожидаемыйХэш: закреплённый, запустить: { _ in
                запусков += 1
                throw ОшибкаПроверкиЗапуска.неожиданныйЗапуск
            })
            Issue.record("Дрейф бинарника принят")
        } catch ОшибкаПроверкиЗапуска.дрейфБинарника {
        } catch let ошибка {
            Issue.record("Получен иной отказ: \(ошибка)")
        }
        #expect(запусков == 0)
    }

    @Test func настоящийПереход256МиБИНовыйПроцессБезИсточника() throws {
        let опоры = ПроверкиАрхиваКодекса(), путь = try опоры.каталог()
        defer { try? FileManager.default.removeItem(at: путь) }
        let программа = try бинарник(), вход = путь.appendingPathComponent("синтетический.jsonl")
        let выход = путь.appendingPathComponent("восстановленный.jsonl"), корень = путь.appendingPathComponent("архив")
        let сессия = UUID().uuidString, поколение = UUID().uuidString
        let порция = Data(repeating: 120, count: 8 * 1_048_576), количество = 33
        #expect(FileManager.default.createFile(atPath: вход.path, contents: nil))
        let файл = try FileHandle(forWritingTo: вход)
        var ожидаемый = SHA256()
        for _ in 0..<количество { try файл.write(contentsOf: порция); ожидаемый.update(data: порция) }
        try файл.synchronize(); try файл.close()
        let размер = порция.count * количество
        let закреплённый = try хэшФайла(программа)
        let первый = try процесс(программа, ["импорт", корень.path, сессия, поколение, вход.path], ожидаемыйХэш: закреплённый)
        #expect((первый["сохранено"] as? NSNumber)?.intValue == размер)
        #expect((первый["сегменты"] as? NSNumber)?.intValue == 2)
        #expect((первый["прочитаноДобавки"] as? NSNumber)?.intValue == размер)
        #expect((первый["пикПамятиБайты"] as? NSNumber)?.intValue ?? Int.max < 200 * 1_048_576)
        let до = try состав(корень)
        #expect(Set(до.keys) == ["00000000/сегмент.fumobs", "00000001/сегмент.fumobs"])
        let повтор = try процесс(программа, ["импорт", корень.path, сессия, поколение, вход.path], ожидаемыйХэш: закреплённый)
        #expect((повтор["прочитаноПрефикса"] as? NSNumber)?.intValue == размер)
        #expect((повтор["прочитаноДобавки"] as? NSNumber)?.intValue == 0)
        #expect(((повтор["пикПамятиБайты"] as? NSNumber)?.intValue ?? Int.max) < 200 * 1_048_576)
        let после = try состав(корень)
        #expect(до == после)
        try FileManager.default.removeItem(at: вход)
        let восстановление = try процесс(программа, ["восстановить", корень.path, сессия, поколение, выход.path], ожидаемыйХэш: закреплённый)
        #expect(((восстановление["пикПамятиБайты"] as? NSNumber)?.intValue ?? Int.max) < 200 * 1_048_576)
        let чтение = try FileHandle(forReadingFrom: выход)
        var фактический = SHA256(), прочитано = 0
        while try autoreleasepool(invoking: {
            let данные = try чтение.read(upToCount: 1_048_576) ?? Data()
            фактический.update(data: данные); прочитано += данные.count
            return !данные.isEmpty
        }) {}
        try чтение.close()
        #expect(прочитано == размер)
        #expect(фактический.finalize() == ожидаемый.finalize())
        #expect(try хэшФайла(программа) == закреплённый)
        let профиль: [String: Any] = [
            "схема": "fum.профиль-raw-codex.1", "байты": размер, "порция": порция.count,
            "условия": "Три свежих процесса; кэш ОС не очищен; создание фикстуры и проверка SHA вне таймера процессов; файл обычный, не sparse; одна строка без LF",
            "приём": первый, "повтор": повтор, "восстановление": восстановление,
            "бинарникSHA256": закреплённый, "составДоПовтора": до, "составПослеПовтора": после
        ]
        var данные = try JSONSerialization.data(withJSONObject: профиль, options: [.prettyPrinted, .sortedKeys])
        данные.append(10)
        print(String(decoding: данные, as: UTF8.self))
        let назначение = ProcessInfo.processInfo.environment["ФУМА_ПРОФИЛЬ_АРХИВА"] ?? (путь.path + "/профиль-итоговый.json")
        do {
            // Только публикационно чистые числовые показатели; RAW и пути не включены.
            // URL/Foundation может декомпозировать имя; POSIX получает буквальный UTF-8.
            let дескриптор = Darwin.open(назначение, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            guard дескриптор >= 0 else { throw ОшибкаАрхиваКодекса.небезопасныйПуть }
            let файл = FileHandle(fileDescriptor: дескриптор, closeOnDealloc: true)
            try файл.write(contentsOf: данные); try файл.synchronize(); try файл.close()
            let части = назначение.split(separator: "/", omittingEmptySubsequences: false)
            let имя = try #require(части.last)
            let родитель = части.dropLast().joined(separator: "/")
            guard let каталог = opendir(родитель) else { throw ОшибкаАрхиваКодекса.небезопасныйПуть }
            var точноеИмя = false
            while let запись = readdir(каталог) {
                let найдено = withUnsafePointer(to: &запись.pointee.d_name) {
                    $0.withMemoryRebound(to: CChar.self, capacity: Int(запись.pointee.d_namlen) + 1) { String(cString: $0) }
                }
                if найдено.utf8.elementsEqual(имя.utf8) { точноеИмя = true }
            }
            #expect(closedir(каталог) == 0)
            #expect(точноеИмя)
        }
    }
}
