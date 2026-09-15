import Foundation
import Darwin
import АрхивныйСнимокЗадачи
import КонтейнерНаблюдений

/// Только открытая синтетическая фикстура; не часть команды импорта.
final class СчётчикАварии: @unchecked Sendable {
    private let замок = NSLock()
    private var значение = 0
    func следующий() -> Int { замок.lock(); defer { замок.unlock() }; значение += 1; return значение }
}
@main struct Авария {
    static func main() async throws {
        let аргументы = Array(CommandLine.arguments.dropFirst())
        guard аргументы.count == 2, ["середина-записи", "после-fsync"].contains(аргументы[1]) else { exit(2) }
        let корень = URL(fileURLWithPath: аргументы[0])
        let каталог = корень.appendingPathComponent("архив")
        let источник = корень.appendingPathComponent("источник.jsonl")
        let uuid = "11111111-1111-4111-8111-111111111111"
        let данные = Data("{\"type\":\"session_meta\",\"payload\":{\"id\":\"\(uuid)\",\"cwd\":\"/synthetic/work\"}}\n".utf8)
        try данные.write(to: источник)
        let пустой = try АрхивЗадачи(корень: каталог, ожидаемыйUUID: uuid, запись: true)
        await пустой.закрыть()
        let записи = СчётчикАварии(); let синхронизации = СчётчикАварии()
        let режим = аргументы[1]
        let операции = ФайловыеОперации(запись: { дескриптор, байты in
            let число = try ФайловыеОперации.системные.запись(дескриптор, байты)
            if режим == "середина-записи", записи.следующий() == 3 { kill(getpid(), SIGKILL) }
            return число
        }, синхронизация: { дескриптор in
            try ФайловыеОперации.системные.синхронизация(дескриптор)
            if режим == "после-fsync", синхронизации.следующий() == 2 { kill(getpid(), SIGKILL) }
        })
        let архив = try АрхивЗадачи(корень: каталог, ожидаемыйUUID: uuid, запись: true, операции: операции)
        _ = try await архив.импортировать(источник)
        exit(3) // Если аварийная точка не достигнута, фикстура провалена.
    }
}
