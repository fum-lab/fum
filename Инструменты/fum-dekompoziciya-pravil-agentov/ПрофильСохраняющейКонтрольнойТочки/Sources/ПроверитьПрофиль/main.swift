import Foundation
import ПрофильСохраняющейКонтрольнойТочки

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("Использование: проверить-сохраняющую-контрольную-точку <профиль.json> <источник.md>\n".utf8))
    exit(2)
}

do {
    let профиль = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    let источник = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
    let результат = try ПроверкаСохраняющегоПрофиля.проверить(
        профиль,
        источник: источник,
        кореньWorktree: FileManager.default.currentDirectoryPath
    )
    print("ЛОКАЛЬНЫЙ CHECKPOINT СОГЛАСОВАН: \(результат.схема); это не проверка допуска или разрешение эффекта")
} catch let ошибка as ОшибкаПрофиля {
    FileHandle.standardError.write(Data(("ПРОФИЛЬ ОТКЛОНЁН: " + ошибка.причина + "\n").utf8))
    exit(1)
} catch {
    FileHandle.standardError.write(Data(("ОШИБКА ЧТЕНИЯ: \(error)\n").utf8))
    exit(1)
}
