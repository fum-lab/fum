import Foundation
import Darwin
import Testing
@testable import КомпозицияНаблюдений

@Suite("Проверки цикла наблюдений")
struct ПроверкиЦиклаНаблюдений {
    @Test("Системный поставщик возвращает физический корень снимка")
    func физическийКореньСистемногоПоставщика() async throws {
        let основание = try временныйКорень("физический-корень")
        defer { try? FileManager.default.removeItem(at: основание) }

        let физический = основание.appendingPathComponent("физический", isDirectory: true)
        try создатьКаталог(физический)
        let ссылка = основание.appendingPathComponent("ссылка", isDirectory: true)
        try FileManager.default.createSymbolicLink(
            at: ссылка,
            withDestinationURL: физический)

        let проекция = try await СистемныйПоставщикНаблюденийСостояния()
            .наблюдатьФайловуюСистему(
                корень: ссылка,
                источник: "проверка-физического-корня")

        #expect(проекция.физическийКорень == физический.path)
        #expect(проекция.физическийКорень != ссылка.path)
    }

    @Test("Минимальный цикл сохраняет повторы вне репозитория")
    func минимальныйЦиклНаблюденийИИстории() async throws {
        let основание = try временныйКорень("цикл-наблюдений")
        defer { try? FileManager.default.removeItem(at: основание) }

        let файловаяСистема = основание.appendingPathComponent(
            "файловая-система",
            isDirectory: true)
        try создатьКаталог(файловаяСистема)
        let файлСостояния = файловаяСистема.appendingPathComponent("state.txt")
        try Data("состояние\n".utf8).write(to: файлСостояния)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: файлСостояния.path)

        let репозиторий = основание.appendingPathComponent(
            "репозиторий",
            isDirectory: true)
        try создатьКаталог(репозиторий)
        try подготовитьРепозиторий(репозиторий)

        let история = основание.appendingPathComponent("история", isDirectory: true)
        try создатьКаталог(история)

        let цикл = ЦиклНаблюденийСостояния<
            СистемныйПоставщикНаблюденийСостояния
        >()
        let ссылкаНаРепозиторий = основание.appendingPathComponent(
            "ссылка-на-репозиторий",
            isDirectory: true)
        try FileManager.default.createSymbolicLink(
            at: ссылкаНаРепозиторий,
            withDestinationURL: репозиторий)

        await #expect(
            throws: ОшибкаЦиклаНаблюденийСостояния.историяВнутриРепозитория
        ) {
            try await цикл.выполнить(
                кореньФайловойСистемы: файловаяСистема,
                источникФайловойСистемы: "проверочный-источник",
                кореньРепозитория: репозиторий,
                кореньИстории: ссылкаНаРепозиторий,
                времяИстории: "2026-10-29T00:00:00Z")
        }
        #expect(
            !FileManager.default.fileExists(
                atPath: репозиторий.appendingPathComponent("сегмент.fumobs").path))

        let результат = try await цикл.выполнить(
            кореньФайловойСистемы: файловаяСистема,
            источникФайловойСистемы: "проверочный-источник",
            кореньРепозитория: репозиторий,
            кореньИстории: история,
            времяИстории: "2026-10-29T00:00:01Z")

        #expect(результат.план.порядок == [.файловаяСистема, .репозиторий])
        #expect(!результат.план.атомарностьМеждуНаблюдениямиГарантирована)
        #expect(
            результат.план.файловаяСистема.физическийКорень
                == файловаяСистема.path)
        #expect(
            результат.план.репозиторий.физическийКорень
                == репозиторий.path)
        #expect(результат.план.репозиторий.ссылка == "refs/heads/проверка")
        #expect(результат.план.репозиторий.изменённыеПути.isEmpty)
        #expect(результат.план.репозиторий.неотслеживаемыеПути.isEmpty)

        #expect(результат.план == результат.повторноПрочитанныйПлан)
        #expect(результат.каноническиеБайты.last == 0x0a)
        #expect(!результат.каноническиеБайты.dropLast().contains(0x0a))
        #expect(результат.курсор.префикс.строки == 1)
        #expect(
            результат.курсор.префикс.байты
                == результат.каноническиеБайты.count)
        #expect(
            результат.курсор.следующееСмещение
                == результат.каноническиеБайты.count)
        #expect(результат.курсор.неполныйХвост.isEmpty)
        #expect(
            результат.квитанция.размер
                == UInt64(результат.каноническиеБайты.count))
        #expect(результат.квитанция.хэш == результат.курсор.префикс.sha256)
        #expect(
            try результат.повторноПрочитанныйПлан.каноническаяСтрокаJSONL()
                == результат.каноническиеБайты)

        let повторныйРезультат = try await цикл.выполнить(
            кореньФайловойСистемы: файловаяСистема,
            источникФайловойСистемы: "проверочный-источник",
            кореньРепозитория: репозиторий,
            кореньИстории: история,
            времяИстории: "2026-10-29T00:00:02Z")

        #expect(повторныйРезультат.план == результат.план)
        #expect(повторныйРезультат.каноническиеБайты == результат.каноническиеБайты)
        #expect(
            повторныйРезультат.квитанция.описание.идентификатор
                != результат.квитанция.описание.идентификатор)
        #expect(повторныйРезультат.квитанция.хэш == результат.квитанция.хэш)

        #expect(!история.path.hasPrefix(репозиторий.path + "/"))
        #expect(!репозиторий.path.hasPrefix(история.path + "/"))
        #expect(
            FileManager.default.fileExists(
                atPath: история.appendingPathComponent("сегмент.fumobs").path))
        #expect(
            !FileManager.default.fileExists(
                atPath: репозиторий.appendingPathComponent("сегмент.fumobs").path))
    }
}

private func временныйКорень(_ префикс: String) throws -> URL {
    let родитель = FileManager.default.temporaryDirectory
    let адрес = родитель.appendingPathComponent(
        префикс + "-" + UUID().uuidString,
        isDirectory: true)
    try создатьКаталог(адрес)
    guard let физический = realpath(адрес.path, nil) else {
        throw ОшибкаВременногоКорня.невозможноРазрешить(errno)
    }
    defer { free(физический) }
    return URL(
        fileURLWithPath: String(cString: физический),
        isDirectory: true)
}

private enum ОшибкаВременногоКорня: Error, Sendable {
    case невозможноРазрешить(Int32)
}

private func создатьКаталог(_ адрес: URL) throws {
    try FileManager.default.createDirectory(
        at: адрес,
        withIntermediateDirectories: false,
        attributes: [.posixPermissions: 0o700])
    try FileManager.default.setAttributes(
        [.posixPermissions: 0o700],
        ofItemAtPath: адрес.path)
}

private func подготовитьРепозиторий(_ корень: URL) throws {
    _ = try выполнитьКомандуРепозитория(["init", "--quiet"], в: корень)
    _ = try выполнитьКомандуРепозитория(
        ["symbolic-ref", "HEAD", "refs/heads/проверка"],
        в: корень)

    let файл = корень.appendingPathComponent("tracked.txt")
    try Data("зафиксировано\n".utf8).write(to: файл)
    try FileManager.default.setAttributes(
        [.posixPermissions: 0o600],
        ofItemAtPath: файл.path)

    _ = try выполнитьКомандуРепозитория(["add", "--", "tracked.txt"], в: корень)
    _ = try выполнитьКомандуРепозитория(
        ["commit", "--quiet", "--no-gpg-sign", "-m", "Начальный снимок"],
        в: корень)
}

@discardableResult
private func выполнитьКомандуРепозитория(
    _ аргументы: [String],
    в корень: URL
) throws -> String {
    let процесс = Process()
    let канал = Pipe()
    процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    процесс.arguments = [
        "-c", "core.fsmonitor=false",
        "-c", "core.hooksPath=/dev/null",
        "-c", "commit.gpgsign=false"
    ] + аргументы
    процесс.currentDirectoryURL = корень
    процесс.environment = [
        "PATH": "/usr/bin:/bin",
        "LC_ALL": "C",
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_CONFIG_GLOBAL": "/dev/null",
        "GIT_OPTIONAL_LOCKS": "0",
        "GIT_NO_REPLACE_OBJECTS": "1",
        "GIT_TERMINAL_PROMPT": "0",
        "GIT_CEILING_DIRECTORIES": корень.path,
        "GIT_AUTHOR_NAME": "FUM Проверка",
        "GIT_AUTHOR_EMAIL": "fum-test@example.invalid",
        "GIT_COMMITTER_NAME": "FUM Проверка",
        "GIT_COMMITTER_EMAIL": "fum-test@example.invalid"
    ]
    процесс.standardOutput = канал
    процесс.standardError = канал

    try процесс.run()
    let данные = канал.fileHandleForReading.readDataToEndOfFile()
    процесс.waitUntilExit()
    let вывод = String(decoding: данные, as: UTF8.self)
    guard процесс.terminationStatus == 0 else {
        throw ОшибкаФикстурыРепозитория(
            аргументы: аргументы,
            код: процесс.terminationStatus,
            вывод: вывод)
    }
    return вывод
}

private struct ОшибкаФикстурыРепозитория: Error, CustomStringConvertible, Sendable {
    let аргументы: [String]
    let код: Int32
    let вывод: String

    var description: String {
        "git \(аргументы.joined(separator: " ")) завершился кодом \(код): \(вывод)"
    }
}
