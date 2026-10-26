import Foundation
import CryptoKit
import Testing
import ГенерацияМанифеста

func сВходомФасада382(_ действие: (Data, URL) async throws -> Void) async throws {
    let окружение = ProcessInfo.processInfo.environment
    let корень = URL(fileURLWithPath: окружение["ФУМ_КАТАЛОГ_ФИКСТУР"]!).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: корень.appendingPathComponent("src"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: корень) }
    try Data("// Фикстура фасада\n".utf8).write(to: корень.appendingPathComponent("src/a.swift"))
    let данные = try Data(contentsOf: URL(fileURLWithPath: окружение["ФУМ_ОПИСАНИЕ_382"]!))
    try await действие(данные, корень)
}

@Suite struct ПроверкиПубличногоФасада382 {
    @Test func внешнийМодульПолучаетБайтыИХэши() async throws {
        try await сВходомФасада382 { данные, корень in
            let ответ = try ФасадГенератораМанифеста.породить(описание: данные, корень: корень).get()
            #expect(String(decoding: ответ.манифест, as: UTF8.self).contains("proverki-aktualizaciya-putej"))
            #expect(ответ.хэшНовогоМанифеста == SHA256.hash(data: ответ.манифест).map { String(format: "%02x", $0) }.joined())
            #expect(ответ.хэшКарты == nil)
            #expect(!ответ.разница.isEmpty)
            let описание = try #require(JSONSerialization.jsonObject(with: ответ.описание) as? [String: Any])
            let цели = try #require(описание["цели"] as? [[String: Any]])
            #expect(цели.first?["имя"] as? String == "proverki-aktualizaciya-putej")
        }
    }

    @Test func некорректныйВходВозвращаетПубличныйОтказ() async throws {
        try await сВходомФасада382 { _, корень in
            let результат = ФасадГенератораМанифеста.породить(описание: Data("{".utf8), корень: корень)
            switch результат {
            case .success: Issue.record("Повреждённый JSON принят")
            case .failure(let отказ):
                #expect(!отказ.код.isEmpty)
                #expect(отказ.description == отказ.код)
                #expect(!отказ.код.contains(корень.path))
            }
        }
    }

    @Test func повторСПрежнимиБайтамиНеМеняетМанифест() async throws {
        try await сВходомФасада382 { данные, корень in
            let первый = try ФасадГенератораМанифеста.породить(описание: данные, корень: корень).get()
            let второй = try ФасадГенератораМанифеста.породить(описание: данные, корень: корень, прежний: первый.манифест).get()
            #expect(второй.манифест == первый.манифест)
            #expect(второй.разница.isEmpty)
            #expect(второй.хэшПрежнегоМанифеста == первый.хэшНовогоМанифеста)
        }
    }

    @Test func ответПередаётсяИзОтдельнойЗадачи() async throws {
        try await сВходомФасада382 { данные, корень in
            let задача = Task.detached {
                ФасадГенератораМанифеста.породить(описание: данные, корень: корень)
            }
            let ответ = try await задача.value.get()
            #expect(!ответ.манифест.isEmpty)
        }
    }
}
