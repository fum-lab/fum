import Foundation

public enum РесурсыГостя {
    public static func текст(_ имя: String) throws -> String {
        guard let адрес = Bundle.module.url(forResource: имя, withExtension: nil) else {
            throw ОшибкаМашины("В поставке отсутствует гостевой ресурс: \(имя).")
        }
        return try String(contentsOf: адрес, encoding: .utf8)
    }
}
