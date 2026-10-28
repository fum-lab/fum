import Foundation
import Testing
import АудиторИсторииКоммитов

@Test func авторИТемаРазличаютПоложительныеИНегативныеСигналы() {
    #expect(Классификатор.авторСоответствуетФорматуCodex("FUM Codex [gpt-6-luna; effort=max]"))
    #expect(!Классификатор.авторСоответствуетФорматуCodex("FUM Писатель"))
    #expect(Классификатор.сигналТемы("Проверить историю коммитов") == .естьКириллица)
    #expect(Классификатор.сигналТемы("Check commit history") == .толькоЛатиница)
    #expect(Классификатор.итогСовпаденияФорматаИмениАвтора(
        "FUM Codex [gpt-6-luna; effort=max]", правилоАктивно: true) == .совпадаетСФорматом)
    #expect(Классификатор.итогСовпаденияФорматаИмениАвтора(
        "FUM Codex [подставленная-модель; effort=anything]", правилоАктивно: true) == .совпадаетСФорматом)
    #expect(Классификатор.итогСовпаденияФорматаИмениАвтора(
        "FUM Писатель", правилоАктивно: true) == .неСовпадаетСФорматом)
    #expect(Классификатор.итогСовпаденияФорматаИмениАвтора(
        "FUM Писатель", правилоАктивно: false) == .правилоФорматаНеНайдено)
}

@Test func разборИзвлекаетНеизменяемыеПоляTrailerИЧислоРодителей() throws {
    let OID = String(repeating: "a", count: 40)
    let дерево = String(repeating: "b", count: 40)
    let родитель1 = String(repeating: "c", count: 40)
    let родитель2 = String(repeating: "d", count: 40)
    let UUID = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
    let сырое = """
    tree \(дерево)
    parent \(родитель1)
    parent \(родитель2)
    author FUM Codex [gpt-6-luna; effort=max] <fum@local> 1793200000 +0400
    committer FUM <fum@local> 1793200001 +0400

    Проверить историю Git

    Codex-Thread-ID: \(UUID)
    """
    let коммит = try РазборщикКоммита.разобрать(Data(сырое.utf8), OID: OID)
    #expect(коммит.деревоOID == дерево)
    #expect(коммит.родители == [родитель1, родитель2])
    #expect(коммит.автор.имя == "FUM Codex [gpt-6-luna; effort=max]")
    #expect(коммит.автор.почта == "fum@local")
    #expect(коммит.автор.времяUnix == 1_793_200_000)
    #expect(коммит.фиксатор.имя == "FUM")
    #expect(коммит.тема == "Проверить историю Git")
    #expect(коммит.значениеКорневогоTrailer == UUID)

    let правила = СнимокПравил(первыйРодительOID: родитель1,
        файлПравилOID: String(repeating: "e", count: 40),
        текст: "<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000063 -->\n<!-- FUM-ПРАВИЛО: FUM-ПРАВИЛО-000201 -->")
    let запись = ЗаписьАудита(коммит: коммит, правила: правила,
        принятыйROOT: коммит, корневойUUID: UUID)
    #expect(запись.этоПринятыйROOT)
    #expect(запись.уROOTДваРодителя)
    #expect(запись.совпадениеФорматаИмениАвтора == .совпадаетСФорматом)
    #expect(запись.статусНативногоПодтвержденияАвтора == .неПроверено)
    #expect(запись.trailerСовпадаетСКорневымUUID)
}

@Test func jsonCliИспользуетСобственнуюСхемуИФорму() throws {
    let OID = String(repeating: "a", count: 40)
    let привязка = ПривязкаРабочегоДерева(текущийHEAD: OID, деревоHEAD: OID,
        область: ["audit/istoriya-kommitov"], индексСовпадаетСHEADВОбласти: true,
        рабочиеФайлыСовпадаютСИндексомВОбласти: true,
        нетНеотслеживаемыхВОбласти: true, деревоСвязаноСHEADВОбласти: true)
    let отчёт = ОтчётАудита(схема: "fum.git-memory-commit-audit.cli.v1",
        корневойUUID: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb",
        принятыйROOT: OID, авторROOT: "FUM Codex", коммиты: [],
        привязкаТекущейРабочейОбласти: привязка)

    let байты = try КодировщикJSONАудита.закодировать(отчёт)
    let объект = try #require(JSONSerialization.jsonObject(with: байты) as? [String: Any])
    #expect(объект["схема"] as? String == "fum.git-memory-commit-audit.cli.v1")
    #expect(объект["принятыйROOT"] as? String == OID)
    #expect((объект["коммиты"] as? [Any])?.isEmpty == true)
    #expect(объект["привязкаТекущейРабочейОбласти"] != nil)
    #expect(объект["постановка"] == nil)
    #expect(объект["поправка_ROOT_RO"] == nil)
}

@Test func проверкаПривязкиРазличаетИндексИРабочиеФайлы() throws {
    let временныйКорень = FileManager.default.temporaryDirectory
        .appendingPathComponent("fum-аудитор-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: временныйКорень, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: временныйКорень) }

    try выполнитьGit(в: временныйКорень, аргументы: ["init", "-q"])
    try выполнитьGit(в: временныйКорень, аргументы: ["config", "user.name", "FUM Codex [gpt-6-luna; effort=max]"])
    try выполнитьGit(в: временныйКорень, аргументы: ["config", "user.email", "fum@local"])
    let файл = временныйКорень.appendingPathComponent("фикстура.txt")
    try Data("исходное состояние\n".utf8).write(to: файл)
    try выполнитьGit(в: временныйКорень, аргументы: ["add", "--", "фикстура.txt"])
    try выполнитьGit(в: временныйКорень, аргументы: ["commit", "-q", "-m", "Сохранить фикстуру"])

    let читатель = ЧитательИстории(корень: временныйКорень)
    var pathspecRefused = false
    do {
        _ = try читатель.проверитьПривязку(области: [":(exclude)**"])
    } catch ОшибкаАудита.небезопаснаяОбласть(":(exclude)**") {
        pathspecRefused = true
    }
    #expect(pathspecRefused)

    let чистаяПривязка = try читатель.проверитьПривязку(области: ["фикстура.txt"])
    #expect(чистаяПривязка.индексСовпадаетСHEADВОбласти)
    #expect(чистаяПривязка.рабочиеФайлыСовпадаютСИндексомВОбласти)
    #expect(чистаяПривязка.деревоСвязаноСHEADВОбласти)

    try Data("изменённое рабочее состояние\n".utf8).write(to: файл)
    let незастейдженнаяПривязка = try читатель.проверитьПривязку(области: ["фикстура.txt"])
    #expect(незастейдженнаяПривязка.индексСовпадаетСHEADВОбласти)
    #expect(!незастейдженнаяПривязка.рабочиеФайлыСовпадаютСИндексомВОбласти)
    #expect(!незастейдженнаяПривязка.деревоСвязаноСHEADВОбласти)

    try выполнитьGit(в: временныйКорень, аргументы: ["add", "--", "фикстура.txt"])
    let застейдженнаяПривязка = try читатель.проверитьПривязку(области: ["фикстура.txt"])
    #expect(!застейдженнаяПривязка.индексСовпадаетСHEADВОбласти)
    #expect(застейдженнаяПривязка.рабочиеФайлыСовпадаютСИндексомВОбласти)
    #expect(!застейдженнаяПривязка.деревоСвязаноСHEADВОбласти)
}

private func выполнитьGit(в корне: URL, аргументы: [String]) throws {
    let процесс = Process()
    процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    процесс.arguments = ["-C", корне.path] + аргументы
    let вывод = Pipe()
    процесс.standardOutput = вывод
    процесс.standardError = вывод
    try процесс.run()
    let данные = вывод.fileHandleForReading.readDataToEndOfFile()
    процесс.waitUntilExit()
    guard процесс.terminationStatus == 0 else {
        throw ОшибкаАудита.командаGitНеВыполнена(аргументы.joined(separator: " "), процесс.terminationStatus)
    }
    _ = данные
}
