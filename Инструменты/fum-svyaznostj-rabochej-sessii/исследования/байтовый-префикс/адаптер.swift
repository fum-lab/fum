import Foundation
import CryptoKit

// Синтетический разбор: не устанавливает происхождение, не читает файл и не допускает запись.
struct КонтрольПрефикса: Equatable { let источник: String; let граница: Int; let sha256: String }
struct НаблюдениеСтроки: Equatable {
    let начало: Int
    let конец: Int
    let sha256: String
    let позиционнаяПривязка: String
    let нативныйID: String?
    let причинаНеизвестности: String
}
struct СнимокПрефикса: Equatable {
    let контроль: КонтрольПрефикса
    let строки: [НаблюдениеСтроки]
    let хвост: Data
    var хвостНеизвестен: Bool { !хвост.isEmpty }
}
enum ИсходПрефикса: Equatable { case снимок(СнимокПрефикса), удержать }
private func хэш(_ d: Data) -> String { SHA256.hash(data:d).map { String(format:"%02x",$0) }.joined() }
func разобратьПрефикс(_ данные: Data, источник: String, прежний: КонтрольПрефикса?) -> ИсходПрефикса {
    guard !источник.isEmpty, источник.utf8.count <= 4096, !источник.utf8.contains(0), данные.count <= 1_048_576 else { return .удержать }
    let bytes=[UInt8](данные)
    if let c=прежний {
        guard c.источник == источник, c.граница >= 0, c.граница <= bytes.count,
              (c.граница == 0 || bytes[c.граница-1] == 10),
              хэш(Data(bytes.prefix(c.граница))) == c.sha256 else { return .удержать }
    }
    var начало=0, позиции:[НаблюдениеСтроки]=[], ids:[String:String]=[:]
    for (номер, байт) in bytes.enumerated() where байт == 10 {
        let конец=номер+1, сырая=Data(bytes[начало..<конец]), сумма=хэш(сырая)
        guard let объект = try? JSONSerialization.jsonObject(with: сырая) as? [String:Any] else { return .удержать }
        let payload=объект["payload"] as? [String:Any]
        let допустимаяФорма = объект["type"] as? String == "response_item" && payload?["type"] as? String == "message"
        let id = допустимаяФорма ? (payload?["id"] as? String).flatMap { $0.isEmpty ? nil : $0 } : nil
        if let id {
            if let старая=ids[id], старая != сумма { return .удержать }
            ids[id]=сумма
        }
        var привязка=Data(источник.utf8); привязка.append(0)
        var левый=UInt64(начало).bigEndian, правый=UInt64(конец).bigEndian
        withUnsafeBytes(of:&левый) { привязка.append(contentsOf:$0) }
        withUnsafeBytes(of:&правый) { привязка.append(contentsOf:$0) }
        привязка.append(contentsOf:сырая)
        позиции.append(НаблюдениеСтроки(начало:начало,конец:конец,sha256:сумма,
            позиционнаяПривязка:хэш(привязка),нативныйID:id,
            причинаНеизвестности:id == nil ? "нет подтверждённого ID" : "происхождение не подтверждено"))
        начало=конец
    }
    let контроль=КонтрольПрефикса(источник:источник,граница:начало,sha256:хэш(Data(bytes.prefix(начало))))
    return .снимок(СнимокПрефикса(контроль:контроль,строки:позиции,хвост:Data(bytes[начало...])))
}
