import Foundation
import CryptoKit
import Darwin
import Testing
#if canImport(АктуализацияПутей)
@testable import АктуализацияПутей
#endif

private let корневоеСодержимоеДляУстановщика = "# Корневые правила проверки установщика\n"

private func хэшДляУстановщика(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}

private func описаниеДляУстановщика(
    корень: URL,
    хэшКорня: String? = nil
) -> ОписаниеЛокальногоВходаАгента {
    let путьКаталога = "Правила/агентов"
    return ОписаниеЛокальногоВходаАгента(
        версия: 1,
        логическийАдрес: "fum-lab/fum/pravila/master",
        путьКаталога: путьКаталога,
        областьЗаписи: [путьКаталога + "/AGENTS.md"],
        родитель: "fum-lab/fum/master",
        дети: [],
        источник: ИсточникОписанияАгента(
            путь: "pravila/opisaniye-lokaljnogo-vkhoda-agenta.json",
            коммит: String(repeating: "a", count: 40),
            хэшSHA256: String(repeating: "b", count: 64)
        ),
        источникКорневыхПравил: ИсточникОписанияАгента(
            путь: "AGENTS.md",
            коммит: String(repeating: "c", count: 40),
            хэшSHA256: хэшКорня ?? хэшДляУстановщика(Data(корневоеСодержимоеДляУстановщика.utf8))
        )
    )
}

private func сДеревомУстановщика(
    _ действие: (URL, URL, ОписаниеЛокальногоВходаАгента) throws -> Void
) throws {
    let временный = FileManager.default.temporaryDirectory
        .appendingPathComponent("fum-installer-" + UUID().uuidString, isDirectory: true)
    let корень = временный.appendingPathComponent("repo", isDirectory: true)
    let каталог = корень.appendingPathComponent("Правила/агентов", isDirectory: true)
    try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true)
    try Data(корневоеСодержимоеДляУстановщика.utf8)
        .write(to: корень.appendingPathComponent("AGENTS.md"))
    defer { try? FileManager.default.removeItem(at: временный) }
    try действие(корень, каталог, описаниеДляУстановщика(корень: корень))
}

private func сведенияДляУстановщика(_ путь: URL) throws -> stat {
    var сведения = stat()
    guard lstat(путь.path, &сведения) == 0 else {
        throw CocoaError(.fileReadNoSuchFile)
    }
    return сведения
}

private func временныеИменаУстановщика(_ каталог: URL) throws -> [String] {
    try FileManager.default.contentsOfDirectory(atPath: каталог.path)
        .filter { $0.hasPrefix(".AGENTS.md.fum-") }
}

@Test func отсутствующаяЦельСоздаётсяИТочноЧитаетсяОбратно() throws {
    try сДеревомУстановщика { корень, каталог, описание in
        let цель = каталог.appendingPathComponent("AGENTS.md")
        let ожидаемое = try ЛокальныйВходАгента.сформировать(
            описание: описание,
            кореньРепозитория: корень,
            каталогАгента: каталог
        )
        let результат = try УстановщикЛокальногоВходаАгента.установить(
            описание: описание,
            кореньРепозитория: корень
        )
        let сведения = try сведенияДляУстановщика(цель)
        #expect(результат.исход == .создан)
        #expect(результат.путь == "Правила/агентов/AGENTS.md")
        #expect(результат.хэшSHA256 == хэшДляУстановщика(Data(ожидаемое.utf8)))
        #expect(результат.числоБайтов == Data(ожидаемое.utf8).count)
        #expect((сведения.st_mode & S_IFMT) == S_IFREG)
        #expect((сведения.st_mode & mode_t(0o777)) == mode_t(0o644))
        #expect(try Data(contentsOf: цель) == Data(ожидаемое.utf8))
        #expect(try временныеИменаУстановщика(каталог).isEmpty)
    }
}

@Test func совпадающаяЦельИдемпотентнаБезЗамены() throws {
    try сДеревомУстановщика { корень, каталог, описание in
        let цель = каталог.appendingPathComponent("AGENTS.md")
        _ = try УстановщикЛокальногоВходаАгента.установить(
            описание: описание,
            кореньРепозитория: корень
        )
        let до = try сведенияДляУстановщика(цель)
        let байтыДо = try Data(contentsOf: цель)
        let результат = try УстановщикЛокальногоВходаАгента.установить(
            описание: описание,
            кореньРепозитория: корень
        )
        let после = try сведенияДляУстановщика(цель)
        #expect(результат.исход == .ужеСовпадает)
        #expect(до.st_dev == после.st_dev)
        #expect(до.st_ino == после.st_ino)
        #expect(try Data(contentsOf: цель) == байтыДо)
        #expect(try временныеИменаУстановщика(каталог).isEmpty)
    }
}

@Test func отличающаясяЦельСохраняетсяИОтклоняется() throws {
    try сДеревомУстановщика { корень, каталог, описание in
        let цель = каталог.appendingPathComponent("AGENTS.md")
        let сторожевыеБайты = Data("не заменять\n".utf8)
        try сторожевыеБайты.write(to: цель)
        guard chmod(цель.path, mode_t(0o600)) == 0 else {
            throw CocoaError(.fileWriteUnknown)
        }
        let до = try сведенияДляУстановщика(цель)
        var полученнаяОшибка: ОшибкаУстановщикаЛокальногоВхода?
        do {
            _ = try УстановщикЛокальногоВходаАгента.установить(
                описание: описание,
                кореньРепозитория: корень
            )
        } catch let ошибка as ОшибкаУстановщикаЛокальногоВхода {
            полученнаяОшибка = ошибка
        }
        let после = try сведенияДляУстановщика(цель)
        #expect(полученнаяОшибка == .существующаяЦельОтличается)
        #expect(до.st_dev == после.st_dev)
        #expect(до.st_ino == после.st_ino)
        #expect((после.st_mode & mode_t(0o777)) == mode_t(0o600))
        #expect(try Data(contentsOf: цель) == сторожевыеБайты)
        #expect(try временныеИменаУстановщика(каталог).isEmpty)
    }
}

@Test func символическаяСсылкаСохраняетсяИНеПереходитКАдресату() throws {
    try сДеревомУстановщика { корень, каталог, описание in
        let внешний = корень.deletingLastPathComponent()
            .appendingPathComponent("внешний-адресат.txt")
        let сторожевыеБайты = Data("внешний адресат\n".utf8)
        try сторожевыеБайты.write(to: внешний)
        let цель = каталог.appendingPathComponent("AGENTS.md")
        try FileManager.default.createSymbolicLink(
            atPath: цель.path,
            withDestinationPath: внешний.path
        )
        let назначениеДо = try FileManager.default.destinationOfSymbolicLink(atPath: цель.path)
        var полученнаяОшибка: ОшибкаУстановщикаЛокальногоВхода?
        do {
            _ = try УстановщикЛокальногоВходаАгента.установить(
                описание: описание,
                кореньРепозитория: корень
            )
        } catch let ошибка as ОшибкаУстановщикаЛокальногоВхода {
            полученнаяОшибка = ошибка
        }
        let сведения = try сведенияДляУстановщика(цель)
        #expect(полученнаяОшибка == .существующаяЦельСимволическаяСсылка)
        #expect((сведения.st_mode & S_IFMT) == S_IFLNK)
        #expect(try FileManager.default.destinationOfSymbolicLink(atPath: цель.path) == назначениеДо)
        #expect(try Data(contentsOf: внешний) == сторожевыеБайты)
        #expect(try временныеИменаУстановщика(каталог).isEmpty)
    }
}

@Test func устаревшийХэшКорняОтказываетДоЭффектаНаЦель() throws {
    try сДеревомУстановщика { корень, каталог, _ in
        let описание = описаниеДляУстановщика(
            корень: корень,
            хэшКорня: String(repeating: "0", count: 64)
        )
        let до = try FileManager.default.contentsOfDirectory(atPath: каталог.path).sorted()
        var ошибкаЛокальногоВхода = false
        do {
            _ = try УстановщикЛокальногоВходаАгента.установить(
                описание: описание,
                кореньРепозитория: корень
            )
        } catch is ОшибкаЛокальногоВхода {
            ошибкаЛокальногоВхода = true
        }
        #expect(ошибкаЛокальногоВхода)
        #expect(!FileManager.default.fileExists(
            atPath: каталог.appendingPathComponent("AGENTS.md").path
        ))
        #expect(try FileManager.default.contentsOfDirectory(atPath: каталог.path).sorted() == до)
        #expect(try временныеИменаУстановщика(каталог).isEmpty)
    }
}
