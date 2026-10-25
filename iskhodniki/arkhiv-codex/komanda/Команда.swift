import Foundation
import Darwin
public enum КомандаАрхиваКодекса {
    public static func выполнить(_ аргументы: [String]) throws -> Data {
        guard аргументы.count == 5,
              ["импорт", "восстановить", "восстановить-хвост"].contains(аргументы[0]),
              let сессия = UUID(uuidString: аргументы[2]), let поколение = UUID(uuidString: аргументы[3]) else {
            throw ОшибкаАрхиваКодекса.неверныйПредел
        }
        let часы = ContinuousClock(), начало = часы.now
        let архив = try АрхивКодекса(корень: URL(fileURLWithPath: аргументы[1]), сессия: сессия,
            поколение: поколение, восстановитьХвост: аргументы[0] == "восстановить-хвост")
        let открыт = часы.now
        var счётчик: СчётчикИмпорта?
        if аргументы[0] == "импорт" {
            счётчик = try архив.импортировать(URL(fileURLWithPath: аргументы[4]))
        } else {
            let дескриптор = Darwin.open(аргументы[4], O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
            guard дескриптор >= 0 else { throw ОшибкаАрхиваКодекса.небезопасныйПуть }
            let файл = FileHandle(fileDescriptor: дескриптор, closeOnDealloc: true)
            do {
                try архив.восстановить { try файл.write(contentsOf: $0) }
                try файл.synchronize(); try файл.close()
            } catch { try? файл.close(); throw error }
        }
        let сохранено = архив.сохранено, обработано = архив.обработано, сегменты = архив.числоСегментов
        try архив.завершить()
        let конец = часы.now
        var сведения = rusage(); getrusage(RUSAGE_SELF, &сведения)
        func секунды(_ время: Duration) -> Double {
            Double(время.components.seconds) + Double(время.components.attoseconds) * 1e-18
        }
        let итог: [String: Any] = [
            "сохранено": сохранено, "обработано": обработано, "сегменты": сегменты,
            "прочитаноПрефикса": счётчик?.прочитаноПрефикса ?? 0,
            "прочитаноДобавки": счётчик?.прочитаноДобавки ?? 0,
            "открытиеСекунды": секунды(начало.duration(to: открыт)),
            "действиеИЗавершениеСекунды": секунды(открыт.duration(to: конец)),
            "пикПамятиБайты": сведения.ru_maxrss,
            "блочныйВвод": сведения.ru_inblock, "блочныйВывод": сведения.ru_oublock
        ]
        var данные = try JSONSerialization.data(withJSONObject: итог, options: [.prettyPrinted, .sortedKeys])
        данные.append(10)
        return данные
    }
}
