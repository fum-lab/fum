import Foundation

public enum ПроверкаОбраза {
    public static func таблица(_ текст: String, план: ПланМашины) throws {
        let имя = URL(string: план.образ)!.lastPathComponent
        let совпадения = текст.split(separator: "\n").compactMap { строка -> String? in
            let поля = строка.split(maxSplits: 1, whereSeparator: { $0 == " " || $0 == "\t" })
            guard поля.count == 2 else { return nil }
            let путь = поля[1].trimmingCharacters(in: .whitespaces)
            return путь == имя || путь == "*" + имя ? String(поля[0]) : nil
        }
        guard совпадения == [план.хэшОбраза] else {
            throw ОшибкаМашины("Подписанная таблица не содержит единственную закреплённую сумму образа.")
        }
    }
    public static func подпись(_ текст: String, код: Int32, ключ: String) throws {
        let строки = текст.split(separator: "\n").map { $0.split(separator: " ").map(String.init) }
        let действительные = строки.filter { $0.count >= 12 && $0[0] == "[GNUPG:]" && $0[1] == "VALIDSIG" }
        let запрещённые = Set(["BADSIG", "ERRSIG", "REVKEYSIG", "EXPKEYSIG", "EXPSIG", "NO_PUBKEY", "FAILURE"])
        guard код == 0, действительные.count == 1,
              действительные[0][2] == ключ || действительные[0].last == ключ,
              !строки.contains(where: { $0.count > 1 && $0[0] == "[GNUPG:]" && запрещённые.contains($0[1]) }) else {
            throw ОшибкаМашины("Подпись таблицы не подтверждена закреплённым ключом Ubuntu.")
        }
    }
    public static func ключ(_ текст: String, ожидаемый: String) throws {
        let строки = текст.split(separator: "\n").map { $0.split(separator: ":", omittingEmptySubsequences: false).map(String.init) }
        let основные = строки.indices.filter { строки[$0].first == "pub" }
        guard основные.count == 1, let индекс = основные.first, индекс + 1 < строки.count,
              строки[индекс + 1].count > 9, строки[индекс + 1][0] == "fpr", строки[индекс + 1][9] == ожидаемый else {
            throw ОшибкаМашины("Полученный ключ не имеет единственного закреплённого первичного отпечатка.")
        }
    }
}
