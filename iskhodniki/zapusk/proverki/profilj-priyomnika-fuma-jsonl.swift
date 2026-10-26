import CryptoKit
import Foundation
import Testing
import АрхивныйСнимокЗадачи
import FUMStructuringOperatorMemory
import ОсноваЗапуска

private struct СерияПрофиляJSONL: Encodable, Sendable {
    let номер: Int
    let кадров: Int
    let итераций: Int
    let всегоНаносекунд: UInt64
    let приёмНаносекунд: UInt64
    let завершениеНаносекунд: UInt64
}

private struct ЗаписьПрофиляJSONL: Encodable, Sendable {
    let схема: String
    let условия: String
    let источник: String
    let начальноеСмещение: Int
    let размерВхода: Int
    let хэшВхода: String
    let хэшиКадров: [String]
    let серии: [СерияПрофиляJSONL]
    let решение: String
}

struct ПрофильПриёмникаJSONL {
    private func хэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    @Test("малый профиль композиции фиксированного JSONL-оператора")
    func измеритьТриПовтора() throws {
        let кадры = (0..<8).map { номер in
            let текст = "строка-\(номер)-🌿"
            let json = "{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"\(текст)\"}]}}"
            return Data((json + "\n").utf8)
        }
        let хэшиКадров = кадры.map(хэш)
        #expect(Set(хэшиКадров).count == кадры.count)
        let вход = кадры.reduce(into: Data()) { $0.append($1) }
        let источник = "fixed-profile-jsonl"
        let начало = 8_192
        var серии: [СерияПрофиляJSONL] = []

        for номерСерии in 1...3 {
            let разборщик = try ПоследовательнаяПроекцияJSONL(
                источник: источник, начальноеСмещение: начало)
            var проекций = 0
            let началоВсего = DispatchTime.now().uptimeNanoseconds
            let следующее = try разборщик.принять(вход, смещение: начало) { исход in
                if case .проецировано = исход { проекций += 1 }
            }
            let конецПриёма = DispatchTime.now().uptimeNanoseconds
            let итог = try разборщик.завершить()
            let конецВсего = DispatchTime.now().uptimeNanoseconds
            #expect(проекций == кадры.count)
            #expect(итог.префикс.строки == кадры.count)
            #expect(итог.сыройХвост.isEmpty)
            #expect(следующее == начало + вход.count)
            серии.append(СерияПрофиляJSONL(
                номер: номерСерии,
                кадров: проекций,
                итераций: 1,
                всегоНаносекунд: конецВсего - началоВсего,
                приёмНаносекунд: конецПриёма - началоВсего,
                завершениеНаносекунд: конецВсего - конецПриёма))
        }

        let запись = ЗаписьПрофиляJSONL(
            схема: "fum.профиль-композиции-приёмника-jsonl.2",
            условия: "3 последовательные серии по 8 фиксированных кадров; один Data chunk; SwiftPM debug; только монотонные внешние часы; без конкурирующего варианта",
            источник: источник,
            начальноеСмещение: начало,
            размерВхода: вход.count,
            хэшВхода: хэш(вход),
            хэшиКадров: хэшиКадров,
            серии: серии,
            решение: "Сравнимого варианта нет; оснований заявлять ускорение или выбирать оптимизацию этот базовый профиль не даёт.")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let данные = try encoder.encode(запись)
        print("ФУМА_ПРОФИЛЬ_КОМПОЗИЦИИ=" + String(decoding: данные, as: UTF8.self))
    }
}
