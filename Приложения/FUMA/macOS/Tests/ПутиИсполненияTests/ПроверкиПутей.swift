import Foundation
import Testing
@testable import ПутиИсполнения

@Test func явныеКаталогиНеЗависятОтРабочегоКаталога() throws {
    let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let пути = try ПутиПриложения(среда: [
        "FUM_RUNTIME_ROOT": временный.appendingPathComponent("оперативные данные").path,
        "FUM_MEMORY_ROOT": временный.appendingPathComponent("память").path,
        "FUM_DOCUMENTS_ROOT": временный.appendingPathComponent("документы").path
    ], домашнийКаталог: временный)
    #expect(пути.оперативныеДанные.lastPathComponent == "оперативные данные")
    #expect(пути.память.lastPathComponent == "память")
    #expect(пути.документы.lastPathComponent == "документы")
    #expect(!FileManager.default.fileExists(atPath: временный.path))
}

@Test func значенияПоУмолчаниюОстаютсяВДомашнемКаталоге() throws {
    let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let пути = try ПутиПриложения(среда: [:], домашнийКаталог: временный)
    #expect(пути.оперативныеДанные.path.hasSuffix("Library/Application Support/FUM/run"))
    #expect(пути.память.path.hasSuffix("Library/Application Support/FUM/memory"))
    #expect(пути.документы.path.hasSuffix("Documents"))
}

@Test func относительныйИПустойКаталогОтклоняются() {
    for значение in ["", "run", "../runtime"] {
        #expect(throws: ОшибкаПутей.self) {
            try ПутиПриложения(среда: ["FUM_RUNTIME_ROOT": значение])
        }
    }
}

@Test func gitИПсевдонимCheckoutОтклоняются() throws {
    let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let репозиторий = временный.appendingPathComponent("repo")
    try FileManager.default.createDirectory(at: репозиторий, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: временный) }
    try Data("gitdir: fixture\n".utf8).write(to: репозиторий.appendingPathComponent(".git"))
    let псевдоним = временный.appendingPathComponent("alias")
    try FileManager.default.createSymbolicLink(at: псевдоним, withDestinationURL: репозиторий)
    for каталог in [репозиторий, псевдоним] {
        #expect(throws: ОшибкаПутей.self) {
            try ПутиПриложения.внешнийКаталог(каталог.appendingPathComponent("run/missing").path)
        }
    }
}

@Test func поискИсполняемогоФайлаИспользуетЯвныйPATH() throws {
    let временный = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: временный, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: временный) }
    let команда = временный.appendingPathComponent("fixture")
    try Data("fixture".utf8).write(to: команда)
    #expect(ПутиПриложения.исполняемыйФайл("fixture", среда: ["PATH": временный.path]) == nil)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: команда.path)
    #expect(ПутиПриложения.исполняемыйФайл("fixture", среда: ["PATH": временный.path]) == команда)
    #expect(ПутиПриложения.исполняемыйФайл(команда.path, среда: [:]) == команда)
    #expect(ПутиПриложения.исполняемыйФайл("fixture", среда: ["PATH": ".:"]) == nil)
    #expect(ПутиПриложения.исполняемыйФайл("missing", среда: ["PATH": временный.path]) == nil)
}
