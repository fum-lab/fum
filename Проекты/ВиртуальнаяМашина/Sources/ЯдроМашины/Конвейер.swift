import Foundation

public enum Конвейер {
    public static func шаг(проверить: () throws -> Bool, выполнить: () throws -> Void) throws {
        if try проверить() { return }
        try выполнить()
        guard try проверить() else { throw ОшибкаМашины("Этап завершился без проверяемого результата.") }
    }
}
