import Foundation
import CryptoKit
import Testing
#if canImport(АктуализацияПутей)
@testable import АктуализацияПутей
#endif

private func описаниеВхода(_ путь: String, версия: Int = 1) -> ОписаниеЛокальногоВходаАгента {
    ОписаниеЛокальногоВходаАгента(
        версия: версия,
        логическийАдрес: "FUMA/iskhodniki/aktualizaciya-putej",
        путьКаталога: путь,
        областьЗаписи: [путь],
        родитель: "FUMA/pravila",
        дети: ["FUMA/proverki/aktualizaciya-putej"],
        источник: ИсточникОписанияАгента(путь: "Планирование/aktualizaciya-putej.md",
            коммит: String(repeating: "a", count: 40), хэшSHA256: String(repeating: "b", count: 64)),
        источникКорневыхПравил: ИсточникОписанияАгента(путь: "AGENTS.md",
            коммит: String(repeating: "c", count: 40), хэшSHA256: хэш("# Корневые правила\n"))
    )
}

private func хэш(_ текст: String) -> String {
    SHA256.hash(data: Data(текст.utf8)).map { String(format: "%02x", $0) }.joined()
}

private func сДеревомВхода(_ действие: (URL, URL) throws -> Void) throws {
    let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let корень = временный.appendingPathComponent("repo", isDirectory: true)
    try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: временный) }
    let корневыеПравила = корень.appendingPathComponent("AGENTS.md")
    try Data("# Корневые правила\n".utf8).write(to: корневыеПравила)
    try действие(корень, корневыеПравила)
}

@Test func локальныйВходНаследуетКореньНаДвухУровнях() throws {
    try сДеревомВхода { корень, _ in
        for путь in ["узел", "узел/подузел/глубокий"] {
            let каталог = корень.appendingPathComponent(путь, isDirectory: true)
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
            let содержимое = try ЛокальныйВходАгента.сформировать(
                описание: описаниеВхода(путь), кореньРепозитория: корень, каталогАгента: каталог)
            let ссылка = путь == "узел" ? "../AGENTS.md" : "../../../AGENTS.md"
            #expect(содержимое.contains("[`AGENTS.md`](\(ссылка))"))
            #expect(содержимое.contains("Прочитай полностью корневой файл правил текущего checkout"))
            #expect(содержимое.contains("Markdown-ссылка не подтверждает чтение"))
            #expect(содержимое.contains("FUMA/iskhodniki/aktualizaciya-putej"))
            #expect(содержимое.contains("FUMA/pravila"))
            #expect(содержимое.contains("FUMA/proverki/aktualizaciya-putej"))
            #expect(содержимое.contains("Чужие области и память — только для чтения"))
            #expect(содержимое.contains("source commit `\(String(repeating: "a", count: 40))`"))
            #expect(содержимое.contains("SHA-256 `\(String(repeating: "b", count: 64))`"))
            #expect(содержимое.contains("source commit `\(String(repeating: "c", count: 40))`"))
            #expect(содержимое.contains("SHA-256 `\(хэш("# Корневые правила\n"))`"))
            #expect(содержимое.contains("после фактического полного чтения указанной версии корневого источника"))
            #expect(!содержимое.contains("ACK зарегистрирован"))
        }
    }
}

@Test func устаревшаяВерсияОтклоняется() throws {
    try сДеревомВхода { корень, _ in
        let каталог = корень.appendingPathComponent("узел", isDirectory: true)
        try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
        #expect(throws: ОшибкаЛокальногоВхода.self) {
            try ЛокальныйВходАгента.сформировать(описание: описаниеВхода("узел", версия: 0),
                кореньРепозитория: корень, каталогАгента: каталог)
        }
    }
}

@Test func внешнийКаталогОтклоняется() throws {
    try сДеревомВхода { корень, _ in
        let внешний = корень.deletingLastPathComponent().appendingPathComponent("sosed", isDirectory: true)
        try FileManager.default.createDirectory(at: внешний, withIntermediateDirectories: true)
        #expect(throws: ОшибкаЛокальногоВхода.self) {
            try ЛокальныйВходАгента.сформировать(описание: описаниеВхода("sosed"),
                кореньРепозитория: корень, каталогАгента: внешний)
        }
    }
}

@Test func symlinkИПутьВыходаОтклоняются() throws {
    try сДеревомВхода { корень, _ in
        let настоящий = корень.appendingPathComponent("настоящий", isDirectory: true)
        try FileManager.default.createDirectory(at: настоящий, withIntermediateDirectories: true)
        let ссылка = корень.appendingPathComponent("ссылка", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: ссылка, withDestinationURL: настоящий)
        #expect(throws: ОшибкаЛокальногоВхода.self) {
            try ЛокальныйВходАгента.сформировать(описание: описаниеВхода("ссылка"),
                кореньРепозитория: корень, каталогАгента: ссылка)
        }
        #expect(throws: ОшибкаЛокальногоВхода.self) {
            try ЛокальныйВходАгента.сформировать(описание: описаниеВхода("../sosed"),
                кореньРепозитория: корень, каталогАгента: настоящий)
        }
    }
}
