import Foundation
import Testing
@testable import ПереходВеток

@Test func разрешеныТолькоПредставимыеКомпоненты() throws {
    #expect(try ИменаПерехода.компонент("PEREKHOD VETOK") == "perekhod-vetok")
    #expect(throws: (any Error).self) { try ИменаПерехода.компонент("непреобразованное") }
    #expect(throws: (any Error).self) { try ИменаПерехода.компонент("a_b") }
    #expect(throws: (any Error).self) { try ИменаПерехода.компонент("a--b") }
    #expect(throws: (any Error).self) { try ИменаПерехода.компонент("") }
}
@Test func новаяВеткаНеПринимаетСкрытыеРазделители() {
    for имя in ["refs/heads/a//b", "refs/heads/Upper/master", "refs/heads/a/../b",
                "refs/heads/a\n/b", "refs/tags/a", "refs/heads/café"] {
        #expect(throws: (any Error).self) { try ИменаПерехода.проверитьВетку(имя) }
    }
}
@Test func нормализацияОтклоняетРазложённыйЮникод() {
    #expect(throws: (any Error).self) { try ИменаПерехода.компонент("cafe\u{301}") }
}
@Test func коллизииПроверяютсяВОбоихНаправленияхПрефикса() {
    for старое in ["refs/heads/a", "refs/heads/a/b/c", "refs/heads/A/B"] {
        #expect(throws: (any Error).self) {
            try ИменаПерехода.проверитьКоллизии("refs/heads/a/b", существующие: [старое])
        }
    }
}
@Test func свёрткаРегистраНеПодменяетсяСтрочнымиБуквами() {
    #expect(ИменаПерехода.ключКоллизии("Straße") == ИменаПерехода.ключКоллизии("STRASSE"))
    #expect(throws: (any Error).self) {
        try ИменаПерехода.проверитьКоллизии("refs/heads/strasse", существующие: ["refs/heads/Straße"])
    }
}
@Test func соседниеОбщаяИПотребительскаяВеткиСовместимы() throws {
    try ИменаПерехода.проверитьКоллизии(
        "refs/heads/fum-lab/fum/fuma/kliyenttelegram/master",
        существующие: ["refs/heads/fum-lab/fum/master", "refs/heads/fum-lab/fum/instrumentyi/perekhod-vetok/master"])
}
