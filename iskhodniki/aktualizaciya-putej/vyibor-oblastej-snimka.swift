import Foundation

struct ВыборОбластейСнимка: Sendable {
    private let выбранные: Set<Data>
    private let предки: Set<Data>

    init(области: [String]) {
        выбранные = Set(области.filter { !$0.isEmpty }.map { Data($0.precomposedStringWithCanonicalMapping.utf8) })
        var предки: Set<Data> = []
        for область in выбранные {
            var префикс = область
            while let разделитель = префикс.lastIndex(of: 47) {
                префикс = Data(префикс[..<разделитель])
                if !префикс.isEmpty { предки.insert(префикс) }
            }
        }
        self.предки = предки
    }

    func содержит(_ путь: String) -> Bool { внутри(Data(путь.precomposedStringWithCanonicalMapping.utf8)) }
    func затрагивает(_ путь: String) -> Bool {
        let ключ = Data(путь.precomposedStringWithCanonicalMapping.utf8)
        return предки.contains(ключ) || внутри(ключ)
    }
    private func внутри(_ ключ: Data) -> Bool {
        var префикс = ключ
        while !префикс.isEmpty {
            if выбранные.contains(префикс) { return true }
            guard let разделитель = префикс.lastIndex(of: 47) else { break }
            префикс = Data(префикс[..<разделитель])
        }
        return false
    }
}
