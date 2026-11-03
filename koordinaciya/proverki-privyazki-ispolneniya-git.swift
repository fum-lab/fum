import Foundation
import Testing
@testable import Koordinaciya

private let корневойUUIDТеста = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
private let nativeUUIDТеста = "01a18294-b6ff-7352-92e1-6b576d412172"
private let oidТеста = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
private let рефТеста = "refs/heads/fum-lab/fum/koordinaciya/master"
private let путьТеста = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().path
private let адресOriginТеста = "https://github.com/fum-lab/fum.git"

private func свидетельствоМодели(
    rootUUID: String = корневойUUIDТеста,
    nativeUUID: String = nativeUUIDТеста,
    model: String = "gpt-6-luna",
    effort: String = "max"
) -> СвидетельствоВыбораМодели {
    СвидетельствоВыбораМодели(
        схема: "fum.api-selection-receipt.1",
        источник: .дочернийВызовSpawnAgent,
        rootUUID: rootUUID,
        sessionIdentity: ИдентичностьAPI(
            статус: .доступен,
            вид: .идентификаторNativeThreadMetadata,
            значение: nativeUUID
        ),
        requestIdentity: ИдентичностьAPI(
            статус: .недоступен,
            вид: .идентификаторВызова,
            значение: nil
        ),
        responseIdentity: ИдентичностьAPI(
            статус: .недоступен,
            вид: .идентификаторВызова,
            значение: nil
        ),
        nativeThread: СнимокNativeThreadMetadata(
            threadUUID: nativeUUID,
            agentPath: "/root/koordinaciya",
            attachedThreadParentIDRaw: "",
            модель: model,
            усилие: effort,
            lineageСтатус: .неизвестно
        ),
        requestedSelection: ПараметрыВыбораAPI(model: model, reasoningEffort: effort),
        selectedValue: ПараметрыВыбораAPI(model: model, reasoningEffort: effort),
        backendModel: .неизвестно,
        nativeTurnContext: .неизвестно
    )
}

private func ожидание(
    worktree: String = путьТеста,
    ref: String = рефТеста,
    oid: String = oidТеста,
    rootUUID: String = корневойUUIDТеста,
    writerUUID: String = nativeUUIDТеста,
    writerPath: String = "/root/koordinaciya",
    originURL: String = адресOriginТеста,
    receiptRootUUID: String? = nil,
    receiptWriterUUID: String? = nil,
    expectedReceiptModel: String = "gpt-6-luna"
) -> ОжидаемаяПривязкаИсполненияGit {
    let actualWitness = свидетельствоМодели(
        rootUUID: receiptRootUUID ?? rootUUID,
        nativeUUID: receiptWriterUUID ?? writerUUID
    )
    let expectedWitness = свидетельствоМодели(
        rootUUID: receiptRootUUID ?? rootUUID,
        nativeUUID: receiptWriterUUID ?? writerUUID,
        model: expectedReceiptModel
    )
    return ОжидаемаяПривязкаИсполненияGit(
        физическоеРабочееДерево: ПутьФизическогоРабочегоДереваGit(путь: worktree)!,
        полныйРеф: ПолныйРефGit(реф: ref)!,
        ожидаемыйOID: OIDКоммитаGit(oid: oid)!,
        ожидаемыйАдресOrigin: АдресУдалённогоGit(адрес: originURL)!,
        общийUUIDКорневойЗадачи: UUIDКорневойЗадачи(uuid: rootUUID)!,
        ожидаемыйUUIDНативногоПисателя: UUIDНативногоПисателя(uuid: writerUUID)!,
        ожидаемыйПутьУзла: writerPath,
        квитанцияВыбораМодели: try! ГенераторМетаданныхКоммита.квитанция(для: actualWitness),
        независимоеОжиданиеВыбораМодели: try! ГенераторМетаданныхКоммита.ожидание(для: expectedWitness)
    )!
}

private func наблюдение(
    worktree: String = путьТеста,
    ref: String = рефТеста,
    oid: String = oidТеста,
    originURL: String = адресOriginТеста,
    rootUUID: String = корневойUUIDТеста,
    writerUUID: String = nativeUUIDТеста,
    writerPath: String = "/root/koordinaciya"
) -> НаблюдаемаяПривязкаИсполненияGit {
    НаблюдаемаяПривязкаИсполненияGit(
        снимокGit: СнимокСостоянияGit(
            физическийКорень: ПутьФизическогоРабочегоДереваGit(путь: worktree)!,
            реф: ПолныйРефGit(реф: ref)!,
            oidHEAD: OIDКоммитаGit(oid: oid)!,
            адресOrigin: АдресУдалённогоGit(адрес: originURL)!,
            настройкиPush: НастройкиЭффектовPushGit(фактическиеАдресаPush: [originURL])
        ),
        общийUUIDКорневойЗадачи: UUIDКорневойЗадачи(uuid: rootUUID)!,
        фактическийUUIDНативногоПисателя: UUIDНативногоПисателя(uuid: writerUUID)!,
        путьУзла: writerPath
    )
}

@Test("Собственная привязка строит push argv для точных W, ref, OID и origin")
func собственнаяПривязкаСтроитPushАргументы() throws {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(),
        наблюдаемая: наблюдение()
    )
    #expect(результат.ошибки.isEmpty)
    let привязка = try #require(результат.довереннаяПривязка)
    let команда = try #require(ПостроительКомандыGit.отправитьВУдалённыйРепозиторий(для: привязка))
    #expect(команда.исполняемыйПуть == "/usr/bin/git")
    #expect(команда.аргументы == [
        "-c", "remote.origin.mirror=false",
        "-c", "push.followTags=false",
        "-c", "push.recurseSubmodules=no",
        "-c", "push.gpgSign=false",
        "push", "--no-mirror", "--no-follow-tags", "--recurse-submodules=no",
        "--no-set-upstream", "--no-signed", "origin", "\(oidТеста):\(рефТеста)"
    ])
    #expect(команда.рабочийКаталог == путьТеста)
    #expect(!команда.аргументы.contains(where: { $0.contains("|") || $0.contains(";") }))
}

@Test("Чужой корневой UUID удерживает команду до эффекта")
func чужойКорневойUUIDУдерживаетДоЭффекта() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(),
        наблюдаемая: наблюдение(rootUUID: "00000000-0000-0000-0000-000000000000")
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.корневойUUIDНеСовпадает))
}

@Test("Корневой UUID квитанции не подменяет UUID писателя")
func корневойUUIDКвитанцииНеПодменяетИдентичность() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(receiptRootUUID: nativeUUIDТеста),
        наблюдаемая: наблюдение()
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.корневойUUIDКвитанцииНеСовпадает))
}

@Test("Квитанция должна ссылаться на native UUID назначенного писателя")
func квитанцияСверяетNativeUUIDПисателя() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(receiptWriterUUID: корневойUUIDТеста),
        наблюдаемая: наблюдение()
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.UUIDНативногоПисателяВКвитанцииНеСовпадает))
}

@Test("Чужой UUID писателя, включая UUID ROOT, отклоняется")
func чужойUUIDПисателяОтклоняется() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(),
        наблюдаемая: наблюдение(writerUUID: корневойUUIDТеста)
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.UUIDНативногоПисателяНеСовпадает))
}

@Test("Чужой путь нативного узла отклоняется")
func чужойПутьНативногоУзлаОтклоняется() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(),
        наблюдаемая: наблюдение(writerPath: "/root/other")
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.путьУзлаНеСовпадает))
}

@Test("Подмена выбранной модели без независимого совпадения не принимается")
func подменаМоделиВНезависимойКвитанцииОтклоняется() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(expectedReceiptModel: "gpt-6.1-sol"),
        наблюдаемая: наблюдение()
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.квитанцияВыбораМоделиНеСовпадает))
}

@Test("Чужой ref удерживает команду")
func чужойРефУдерживаетКоманду() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(),
        наблюдаемая: наблюдение(ref: "refs/heads/fum-lab/fum/master")
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.рефНеСовпадает))
}

@Test("Чужой физический worktree не даёт построить команду")
func чужоеФизическоеРабочееДеревоНеДаётКоманду() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(),
        наблюдаемая: наблюдение(worktree: "/")
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.физическоеРабочееДеревоНеСовпадает))
    #expect(результат.довереннаяПривязка.flatMap(ПостроительКомандыGit.отправитьВУдалённыйРепозиторий(для:)) == nil)
}

@Test("Чужой HEAD OID удерживает команду")
func чужойHeadOidУдерживаетКоманду() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(),
        наблюдаемая: наблюдение(oid: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.oidНеСовпадает))
}

@Test("Другой origin удерживает команду")
func другойOriginУдерживаетКоманду() {
    let результат = ПроверкаПривязкиИсполненияGit.проверить(
        ожидаемая: ожидание(),
        наблюдаемая: наблюдение(originURL: "https://github.com/other/repository.git")
    )
    #expect(результат.довереннаяПривязка == nil)
    #expect(результат.ошибки.contains(.адресOriginНеСовпадает))
}

@Test("Повреждённый push refspec и чужая область не создаются")
func повреждённыйPushRefspecИЧужаяОбластьНеСоздаются() throws {
    #expect(СпецификацияОтправкиGit(значение: "\(oidТеста):refs/heads/koordinaciya:foreign") == nil)
    #expect(СпецификацияОтправкиGit(значение: "not-an-oid:refs/heads/fum-lab/fum/koordinaciya/master") == nil)
    #expect(ПолныйРефGit(реф: "refs/heads/fum-lab/fum/koordinaciya/../master") == nil)
    let исходноеОжидание = ожидание()
    let чужойРеф = try #require(ПолныйРефGit(реф: "refs/heads/fum-lab/fum/master"))
    let чужоеОжидание = ОжидаемаяПривязкаИсполненияGit(
        физическоеРабочееДерево: исходноеОжидание.физическоеРабочееДерево,
        полныйРеф: чужойРеф,
        ожидаемыйOID: исходноеОжидание.ожидаемыйOID,
        ожидаемыйАдресOrigin: исходноеОжидание.ожидаемыйАдресOrigin,
        общийUUIDКорневойЗадачи: исходноеОжидание.общийUUIDКорневойЗадачи,
        ожидаемыйUUIDНативногоПисателя: исходноеОжидание.ожидаемыйUUIDНативногоПисателя,
        ожидаемыйПутьУзла: исходноеОжидание.ожидаемыйПутьУзла,
        квитанцияВыбораМодели: исходноеОжидание.квитанцияВыбораМоделиСХэшем,
        независимоеОжиданиеВыбораМодели: исходноеОжидание.независимоеОжиданиеВыбораМодели
    )
    #expect(чужоеОжидание == nil)
}

private func выполнитьКомандуGit(_ аргументы: [String], at каталог: URL) throws {
    let процесс = Process()
    процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    процесс.arguments = аргументы
    процесс.currentDirectoryURL = каталог
    var окружение = ProcessInfo.processInfo.environment
    окружение["GIT_CONFIG_NOSYSTEM"] = "1"
    окружение["GIT_CONFIG_GLOBAL"] = "/dev/null"
    окружение["GIT_TERMINAL_PROMPT"] = "0"
    окружение["GIT_AUTHOR_NAME"] = "Fixture"
    окружение["GIT_AUTHOR_EMAIL"] = "fixture@local"
    окружение["GIT_COMMITTER_NAME"] = "Fixture"
    окружение["GIT_COMMITTER_EMAIL"] = "fixture@local"
    процесс.environment = окружение
    процесс.standardOutput = FileHandle.nullDevice
    процесс.standardError = FileHandle.nullDevice
    try процесс.run()
    процесс.waitUntilExit()
    #expect(процесс.terminationStatus == 0)
}

private func создатьРабочееДеревоGit() throws -> (
    URL,
    ПутьФизическогоРабочегоДереваGit,
    СнимокСостоянияGit
) {
    let каталог = FileManager.default.temporaryDirectory
        .appendingPathComponent("fum-koordinaciya-git-snapshot-\(UUID().uuidString)", isDirectory: true)
        .standardizedFileURL
    try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
    try выполнитьКомандуGit(["init", "--quiet", "--initial-branch=main"], at: каталог)
    try выполнитьКомандуGit(["-c", "user.name=Test", "-c", "user.email=test@local", "-c", "commit.gpgsign=false", "commit", "--quiet", "--allow-empty", "--message", "fixture"], at: каталог)
    try выполнитьКомандуGit(["branch", "--move", "fum-lab/fum/koordinaciya/fixture"], at: каталог)
    try выполнитьКомандуGit(["remote", "add", "origin", адресOriginТеста], at: каталог)

    let путь = try #require(ПутьФизическогоРабочегоДереваGit(путь: каталог.resolvingSymlinksInPath().path))
    let снимок = try НаблюдательРабочегоДереваGit.прочитать(рабочееДерево: путь)
    return (каталог, путь, снимок)
}

@Test("Проверенный push удерживает изменённый UUID до вызова исполнителя")
func проверенныйPushУдерживаетЧужойUUIDДоИсполнителя() throws {
    let (каталог, путь, снимок) = try создатьРабочееДеревоGit()
    defer { try? FileManager.default.removeItem(at: каталог) }
    let ожидаемая = ожидание(worktree: путь.путь, ref: снимок.реф.реф, oid: снимок.oidHEAD.oid)
    var числоВызововИсполнителя = 0
    let итог = try АдаптерПроверенногоPushGit.выполнитьПроверенныйPush(
        ожидаемая: ожидаемая,
        наблюдаемыйUUIDКорневойЗадачи: UUIDКорневойЗадачи(uuid: корневойUUIDТеста)!,
        наблюдаемыйUUIDНативногоПисателя: UUIDНативногоПисателя(uuid: корневойUUIDТеста)!,
        наблюдаемыйПутьУзла: "/root/koordinaciya",
        исполнитель: { команда in
            числоВызововИсполнителя += 1
            return КвитанцияЗапускаGit(
                аргументы: команда.аргументы,
                рабочийКаталог: команда.рабочийКаталог,
                кодЗавершения: 0,
                требуетсяУдалённоеЧтениеОбратно: true
            )
        }
    )
    #expect(числоВызововИсполнителя == 0)
    if case let .удержан(ошибки) = итог {
        #expect(ошибки.contains(.UUIDНативногоПисателяНеСовпадает))
    } else {
        Issue.record("При несовпадающем UUID был вызван исполнитель.")
    }
}

@Test("Проверенный push перечитывает W и ровно один раз вызывает переданный executor")
func проверенныйPushПеречитываетРабочееДеревоИВызываетИсполнителя() throws {
    let (каталог, путь, снимок) = try создатьРабочееДеревоGit()
    defer { try? FileManager.default.removeItem(at: каталог) }
    let ожидаемая = ожидание(worktree: путь.путь, ref: снимок.реф.реф, oid: снимок.oidHEAD.oid)
    var числоВызововИсполнителя = 0
    var полученныеАргументы: [String] = []
    let итог = try АдаптерПроверенногоPushGit.выполнитьПроверенныйPush(
        ожидаемая: ожидаемая,
        наблюдаемыйUUIDКорневойЗадачи: UUIDКорневойЗадачи(uuid: корневойUUIDТеста)!,
        наблюдаемыйUUIDНативногоПисателя: UUIDНативногоПисателя(uuid: nativeUUIDТеста)!,
        наблюдаемыйПутьУзла: "/root/koordinaciya",
        исполнитель: { команда in
            числоВызововИсполнителя += 1
            полученныеАргументы = команда.аргументы
            return КвитанцияЗапускаGit(
                аргументы: команда.аргументы,
                рабочийКаталог: команда.рабочийКаталог,
                кодЗавершения: 0,
                требуетсяУдалённоеЧтениеОбратно: true
            )
        }
    )
    #expect(числоВызововИсполнителя == 1)
    #expect(полученныеАргументы == [
        "-c", "remote.origin.mirror=false",
        "-c", "push.followTags=false",
        "-c", "push.recurseSubmodules=no",
        "-c", "push.gpgSign=false",
        "push", "--no-mirror", "--no-follow-tags", "--recurse-submodules=no",
        "--no-set-upstream", "--no-signed", "origin", "\(снимок.oidHEAD.oid):\(снимок.реф.реф)"
    ])
    if case let .запущен(квитанция) = итог {
        #expect(квитанция.требуетсяУдалённоеЧтениеОбратно)
    } else {
        Issue.record("Совпавшая привязка была удержана.")
    }
}

@Test("Снимок Git читается из явно выбранного физического рабочего дерева")
func снимокGitЧитаетсяИзЯвногоРабочегоДерева() throws {
    let (каталог, путь, снимок) = try создатьРабочееДеревоGit()
    defer { try? FileManager.default.removeItem(at: каталог) }
    #expect(снимок.физическийКорень == путь)
    #expect(снимок.реф.реф == "refs/heads/fum-lab/fum/koordinaciya/fixture")
    #expect(снимок.адресOrigin.адрес == адресOriginТеста)
    #expect(снимок.oidHEAD.oid.count == 40)
}

private struct ФикстураЭффектаPush {
    let корень: URL
    let рабочееДерево: URL
    let путь: ПутьФизическогоРабочегоДереваGit
    let снимок: СнимокСостоянияGit
    let удалённыйBare: URL
}

private func создатьФикстуруЭффектаPush(сPushURL: Bool = true, сТегом: Bool = false) throws -> ФикстураЭффектаPush {
    let корень = FileManager.default.temporaryDirectory
        .appendingPathComponent("fum-koordinaciya-push-fixture-" + UUID().uuidString, isDirectory: true)
        .standardizedFileURL
    let рабочееДерево = корень.appendingPathComponent("work", isDirectory: true)
    let удалённыйBare = корень.appendingPathComponent("remote.git", isDirectory: true)
    try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false)
    try FileManager.default.createDirectory(at: рабочееДерево, withIntermediateDirectories: false)
    try выполнитьКомандуGit(["init", "--quiet", "--bare", удалённыйBare.path], at: корень)
    try выполнитьКомандуGit(["init", "--quiet", "--initial-branch=main"], at: рабочееДерево)
    try выполнитьКомандуGit(["-c", "user.name=Fixture", "-c", "user.email=fixture@local", "commit", "--quiet", "--allow-empty", "--message", "fixture"], at: рабочееДерево)
    try выполнитьКомандуGit(["branch", "--move", "fum-lab/fum/koordinaciya/fixture"], at: рабочееДерево)
    if сТегом {
        try выполнитьКомандуGit(["tag", "--annotate", "release-v1", "--message", "fixture annotated tag"], at: рабочееДерево)
    }
    try выполнитьКомандуGit(["remote", "add", "origin", адресOriginТеста], at: рабочееДерево)
    if сPushURL {
        let pushURL = URL(fileURLWithPath: удалённыйBare.path, isDirectory: true).absoluteString
        try выполнитьКомандуGit(["remote", "set-url", "--push", "origin", pushURL], at: рабочееДерево)
    }
    let путь = try #require(ПутьФизическогоРабочегоДереваGit(путь: рабочееДерево.resolvingSymlinksInPath().path))
    let снимок = try НаблюдательРабочегоДереваGit.прочитать(рабочееДерево: путь)
    return ФикстураЭффектаPush(корень: корень, рабочееДерево: рабочееДерево, путь: путь, снимок: снимок, удалённыйBare: удалённыйBare)
}

private func ссылкиBare(_ bare: URL, at корень: URL) throws -> [String] {
    let процесс = Process()
    процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    процесс.arguments = ["--git-dir", bare.path, "for-each-ref", "--format=%(refname)"]
    процесс.currentDirectoryURL = корень
    процесс.environment = ProcessInfo.processInfo.environment
    let stdout = Pipe()
    процесс.standardOutput = stdout
    процесс.standardError = FileHandle.nullDevice
    try процесс.run()
    процесс.waitUntilExit()
    let bytes = stdout.fileHandleForReading.readDataToEndOfFile()
    guard процесс.terminationStatus == 0, let value = String(data: bytes, encoding: .utf8) else {
        Issue.record("Не удалось прочитать refs временного bare-репозитория.")
        return []
    }
    return value.split(whereSeparator: \.isNewline).map(String.init).sorted()
}

private func снимокСсылокИOIDBare(_ bare: URL, at корень: URL) throws -> [String: String] {
    let процесс = Process()
    процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    процесс.arguments = ["--git-dir", bare.path, "for-each-ref", "--format=%(refname)%09%(objectname)"]
    процесс.currentDirectoryURL = корень
    процесс.environment = ProcessInfo.processInfo.environment
    let stdout = Pipe()
    процесс.standardOutput = stdout
    процесс.standardError = FileHandle.nullDevice
    try процесс.run()
    процесс.waitUntilExit()
    let bytes = stdout.fileHandleForReading.readDataToEndOfFile()
    guard процесс.terminationStatus == 0, let value = String(data: bytes, encoding: .utf8) else {
        Issue.record("Не удалось прочитать refs и OID временного bare-репозитория.")
        return [:]
    }
    var snapshot: [String: String] = [:]
    for line in value.split(whereSeparator: \.isNewline) {
        let columns = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
        guard columns.count == 2 else {
            Issue.record("Формат ref/OID временного bare-репозитория повреждён.")
            continue
        }
        snapshot[String(columns[0])] = String(columns[1])
    }
    return snapshot
}

@Test("Снимок bare refs отличает продвижение OID при неизменном наборе refs")
func снимокBareRefsОтличаетПродвижениеOID() throws {
    let fixture = try создатьФикстуруЭффектаPush()
    defer { try? FileManager.default.removeItem(at: fixture.корень) }

    let ref = "refs/heads/fum-lab/fum/koordinaciya/fixture"
    try выполнитьКомандуGit(["push", "origin", "HEAD:\(ref)"], at: fixture.рабочееДерево)
    let before = try снимокСсылокИOIDBare(fixture.удалённыйBare, at: fixture.корень)
    let firstOID = try #require(before[ref])

    try Data("second commit\n".utf8).write(to: fixture.рабочееДерево.appendingPathComponent("second.txt"))
    try выполнитьКомандуGit(["add", "second.txt"], at: fixture.рабочееДерево)
    try выполнитьКомандуGit(["-c", "user.name=Fixture", "-c", "user.email=fixture@local", "commit", "--quiet", "--message", "advance same ref"], at: fixture.рабочееДерево)
    try выполнитьКомандуGit(["push", "origin", "HEAD:\(ref)"], at: fixture.рабочееДерево)

    let after = try снимокСсылокИOIDBare(fixture.удалённыйBare, at: fixture.корень)
    #expect(Set(before.keys) == Set(after.keys))
    #expect(after[ref] != nil)
    #expect(after[ref] != firstOID)
    #expect(after != before)
}

private func выполнитьСФиктивнымИсполнителем(_ fixture: ФикстураЭффектаPush, вызов: @escaping (КомандаGit) -> Void) throws -> ИтогПроверенногоPushGit {
    let expected = ожидание(
        worktree: fixture.путь.путь,
        ref: fixture.снимок.реф.реф,
        oid: fixture.снимок.oidHEAD.oid
    )
    return try АдаптерПроверенногоPushGit.выполнитьПроверенныйPush(
        ожидаемая: expected,
        наблюдаемыйUUIDКорневойЗадачи: UUIDКорневойЗадачи(uuid: корневойUUIDТеста)!,
        наблюдаемыйUUIDНативногоПисателя: UUIDНативногоПисателя(uuid: nativeUUIDТеста)!,
        наблюдаемыйПутьУзла: "/root/koordinaciya",
        исполнитель: { команда in
            вызов(команда)
            return КвитанцияЗапускаGit(
                аргументы: команда.аргументы,
                рабочийКаталог: команда.рабочийКаталог,
                кодЗавершения: 0,
                требуетсяУдалённоеЧтениеОбратно: true
            )
        }
    )
}

private func довереннаяЛокальнаяФикстура(_ fixture: ФикстураЭффектаPush) throws -> ДовереннаяПривязкаИсполненияGit {
    let адресPush = URL(fileURLWithPath: fixture.удалённыйBare.path, isDirectory: true).absoluteString
    return ДовереннаяПривязкаИсполненияGit(
        дляЛокальнойФикстуры: fixture.путь,
        реф: fixture.снимок.реф,
        oid: fixture.снимок.oidHEAD,
        origin: fixture.снимок.адресOrigin,
        адресPush: try #require(АдресНазначенияPushGit(адрес: адресPush))
    )
}

@Test("Чужой эффективный pushurl удерживает отправку до executor и не меняет refs приемника")
func чужойPushURLУдерживаетсяДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush()
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case .удержан = result {} else { Issue.record("Эффект разрешён при чужом remote.origin.pushurl.") }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("Несколько эффективных push URL удерживают отправку и не меняют ни одного приемника")
func несколькоPushURLУдерживаютсяДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush()
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    let otherBare = fixture.корень.appendingPathComponent("other.git", isDirectory: true)
    try выполнитьКомандуGit(["init", "--quiet", "--bare", otherBare.path], at: fixture.корень)
    let otherURL = URL(fileURLWithPath: otherBare.path, isDirectory: true).absoluteString
    try выполнитьКомандуGit(["config", "--local", "--add", "remote.origin.pushurl", otherURL], at: fixture.рабочееДерево)
    let beforeFirst = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    let beforeSecond = try ссылкиBare(otherBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case .удержан = result {} else { Issue.record("Эффект разрешён при нескольких push URL.") }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == beforeFirst)
    #expect(try ссылкиBare(otherBare, at: fixture.корень) == beforeSecond)
}

@Test("pushInsteadOf не может перенаправить одобренный origin в другой приемник")
func pushInsteadOfУдерживаетсяДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush(сPushURL: false)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    let rewriteKey = "url." + URL(fileURLWithPath: fixture.удалённыйBare.path, isDirectory: true).absoluteString + ".pushInsteadOf"
    try выполнитьКомандуGit(["config", "--local", "--add", rewriteKey, адресOriginТеста], at: fixture.рабочееДерево)
    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case .удержан = result {} else { Issue.record("Эффект разрешён после URL pushInsteadOf rewrite.") }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("local mirror mode is rejected before any ref effect")
func mirrorModeУдерживаетсяДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush(сPushURL: false)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    try выполнитьКомандуGit(["config", "--local", "remote.origin.mirror", "true"], at: fixture.рабочееДерево)
    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case .удержан = result {} else { Issue.record("Эффект разрешён при remote.origin.mirror=true.") }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("Configured push refspecs are rejected before the executor")
func pushRefspecsУдерживаютДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush(сPushURL: false)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    try выполнитьКомандуGit(["config", "--local", "--add", "remote.origin.push", "refs/heads/*:refs/heads/*"], at: fixture.рабочееДерево)
    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case let .удержан(errors) = result {
        #expect(errors.contains(.pushRefspecsНастроены))
    } else {
        Issue.record("Команда с remote.origin.push была разрешена.")
    }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("Push options are rejected before the executor")
func pushOptionsУдерживаютДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush(сPushURL: false)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    try выполнитьКомандуGit(["config", "--local", "--add", "push.pushOption", "fixture-option"], at: fixture.рабочееДерево)
    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case let .удержан(errors) = result {
        #expect(errors.contains(.pushOptionsНастроены))
    } else {
        Issue.record("Команда с push.pushOption была разрешена.")
    }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("Per-worktree push options are rejected before the receiver observes them")
func параметрыPushИзWorktreeConfigУдерживаютсяДоЭффекта() throws {
    let fixture = try создатьФикстуруЭффектаPush(сPushURL: true)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }

    try выполнитьКомандуGit(["config", "--local", "extensions.worktreeConfig", "true"], at: fixture.рабочееДерево)
    try выполнитьКомандуGit(["config", "--worktree", "--add", "push.pushOption", "fixture-option"], at: fixture.рабочееДерево)
    try выполнитьКомандуGit(["--git-dir", fixture.удалённыйBare.path, "config", "receive.advertisePushOptions", "true"], at: fixture.корень)

    let marker = fixture.корень.appendingPathComponent("received-push-options")
    let hook = fixture.удалённыйBare.appendingPathComponent("hooks/pre-receive")
    let hookSource = "#!/bin/sh\nprintf '%s\\n' \"$GIT_PUSH_OPTION_COUNT\" > '\(marker.path)'\nprintf '%s\\n' \"$GIT_PUSH_OPTION_0\" >> '\(marker.path)'\n"
    try Data(hookSource.utf8).write(to: hook)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hook.path)

    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    let trusted = try довереннаяЛокальнаяФикстура(fixture)
    let command = try #require(ПостроительКомандыGit.отправитьВУдалённыйРепозиторий(для: trusted))
    var refused = false
    do {
        _ = try АдаптерВыполненияКомандGit.выполнить(command)
    } catch {
        refused = true
    }

    #expect(refused)
    #expect(!FileManager.default.fileExists(atPath: marker.path))
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("Custom receive-pack command is rejected before the executor")
func receivePackУдерживаетсяДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush(сPushURL: false)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    try выполнитьКомандуGit(["config", "--local", "remote.origin.receivepack", "custom-receive-pack"], at: fixture.рабочееДерево)
    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case let .удержан(errors) = result {
        #expect(errors.contains(.receivePackПереопределён))
    } else {
        Issue.record("Команда с custom receive-pack была разрешена.")
    }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("An executable pre-push hook is rejected before the executor")
func prePushHookУдерживаетсяДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush(сPushURL: false)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    let hook = fixture.рабочееДерево.appendingPathComponent(".git/hooks/pre-push")
    try FileManager.default.createDirectory(at: hook.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("#!/bin/sh\nexit 0\n".utf8).write(to: hook)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hook.path)
    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case let .удержан(errors) = result {
        #expect(errors.contains(.prePushHookАктивен))
    } else {
        Issue.record("Активный pre-push hook не удержал эффект.")
    }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("push.autoSetupRemote is rejected before the executor")
func autoSetupRemoteУдерживаетсяДоExecutor() throws {
    let fixture = try создатьФикстуруЭффектаPush(сPushURL: false)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    try выполнитьКомандуGit(["config", "--local", "push.autoSetupRemote", "true"], at: fixture.рабочееДерево)
    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    var executorCalls = 0
    let result = try выполнитьСФиктивнымИсполнителем(fixture) { _ in executorCalls += 1 }
    #expect(executorCalls == 0)
    if case let .удержан(errors) = result {
        #expect(errors.contains(.autoSetupRemoteВключён))
    } else {
        Issue.record("push.autoSetupRemote не удержал эффект.")
    }
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}

@Test("Configured followTags cannot expand a push beyond the explicit branch ref")
func followTagsНеДобавляетТегиКЯвномуPush() throws {
    let fixture = try создатьФикстуруЭффектаPush(сТегом: true)
    defer { try? FileManager.default.removeItem(at: fixture.корень) }
    try выполнитьКомандуGit(["config", "--local", "push.followTags", "true"], at: fixture.рабочееДерево)
    let trusted = try довереннаяЛокальнаяФикстура(fixture)
    let command = try #require(ПостроительКомандыGit.отправитьВУдалённыйРепозиторий(для: trusted))
    let receipt = try АдаптерВыполненияКомандGit.выполнить(command)
    #expect(receipt.кодЗавершения == 0)
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == ["refs/heads/fum-lab/fum/koordinaciya/fixture"])
}

@Test("recurseSubmodules on-demand cannot publish a submodule ref")
func recurseSubmodulesНеПубликуетПодмодульныеRefs() throws {
    let fixture = try создатьФикстуруЭффектаPush()
    defer { try? FileManager.default.removeItem(at: fixture.корень) }

    let submoduleBare = fixture.корень.appendingPathComponent("submodule.git", isDirectory: true)
    let submoduleSeed = fixture.корень.appendingPathComponent("submodule-seed", isDirectory: true)
    try FileManager.default.createDirectory(at: submoduleSeed, withIntermediateDirectories: false)
    try выполнитьКомандуGit(["init", "--quiet", "--bare", "--initial-branch=main", submoduleBare.path], at: fixture.корень)
    try выполнитьКомандуGit(["init", "--quiet", "--initial-branch=main"], at: submoduleSeed)
    try Data("before\n".utf8).write(to: submoduleSeed.appendingPathComponent("tracked.txt"))
    try выполнитьКомандуGit(["add", "tracked.txt"], at: submoduleSeed)
    try выполнитьКомандуGit(["-c", "user.name=Fixture", "-c", "user.email=fixture@local", "commit", "--quiet", "--message", "submodule baseline"], at: submoduleSeed)
    try выполнитьКомандуGit(["remote", "add", "origin", URL(fileURLWithPath: submoduleBare.path).absoluteString], at: submoduleSeed)
    try выполнитьКомандуGit(["push", "origin", "HEAD:refs/heads/main"], at: submoduleSeed)
    let submoduleRefsBefore = try снимокСсылокИOIDBare(submoduleBare, at: fixture.корень)

    let submoduleURL = URL(fileURLWithPath: submoduleBare.path).absoluteString
    try выполнитьКомандуGit(["-c", "protocol.file.allow=always", "submodule", "add", submoduleURL, "nested/submodule"], at: fixture.рабочееДерево)
    try выполнитьКомандуGit(["checkout", "main"], at: fixture.рабочееДерево.appendingPathComponent("nested/submodule", isDirectory: true))
    try Data("after\n".utf8).write(to: fixture.рабочееДерево.appendingPathComponent("nested/submodule/tracked.txt"))
    let submoduleWorktree = fixture.рабочееДерево.appendingPathComponent("nested/submodule", isDirectory: true)
    try выполнитьКомандуGit(["add", "tracked.txt"], at: submoduleWorktree)
    try выполнитьКомандуGit(["-c", "user.name=Fixture", "-c", "user.email=fixture@local", "commit", "--quiet", "--message", "unpublished submodule update"], at: submoduleWorktree)
    try выполнитьКомандуGit(["config", "--file", ".gitmodules", "submodule.nested/submodule.branch", "main"], at: fixture.рабочееДерево)
    try выполнитьКомандуGit(["add", ".gitmodules", "nested/submodule"], at: fixture.рабочееДерево)
    try выполнитьКомандуGit(["-c", "user.name=Fixture", "-c", "user.email=fixture@local", "commit", "--quiet", "--message", "advance gitlink"], at: fixture.рабочееДерево)
    try выполнитьКомандуGit(["config", "--local", "push.recurseSubmodules", "on-demand"], at: fixture.рабочееДерево)

    let freshPath = try #require(ПутьФизическогоРабочегоДереваGit(путь: fixture.рабочееДерево.resolvingSymlinksInPath().path))
    let freshSnapshot = try НаблюдательРабочегоДереваGit.прочитать(рабочееДерево: freshPath)
    let freshFixture = ФикстураЭффектаPush(
        корень: fixture.корень,
        рабочееДерево: fixture.рабочееДерево,
        путь: freshPath,
        снимок: freshSnapshot,
        удалённыйBare: fixture.удалённыйBare
    )
    let trusted = try довереннаяЛокальнаяФикстура(freshFixture)
    let command = try #require(ПостроительКомандыGit.отправитьВУдалённыйРепозиторий(для: trusted))
    let receipt = try АдаптерВыполненияКомандGit.выполнить(command)

    #expect(receipt.кодЗавершения == 0)
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == ["refs/heads/fum-lab/fum/koordinaciya/fixture"])
    #expect(try снимокСсылокИOIDBare(submoduleBare, at: fixture.корень) == submoduleRefsBefore)
}

@Test("A configured core.hooksPath cannot run a push hook or change a remote ref")
func переопределённыйКаталогHooksУдерживаетЭффект() throws {
    let fixture = try создатьФикстуруЭффектаPush()
    defer { try? FileManager.default.removeItem(at: fixture.корень) }

    let hooks = fixture.корень.appendingPathComponent("custom-hooks", isDirectory: true)
    let marker = fixture.корень.appendingPathComponent("pre-push-ran")
    try FileManager.default.createDirectory(at: hooks, withIntermediateDirectories: false)
    let hook = hooks.appendingPathComponent("pre-push")
    try Data("#!/bin/sh\nprintf triggered > '\(marker.path)'\nexit 0\n".utf8).write(to: hook)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hook.path)
    try выполнитьКомандуGit(["config", "--local", "core.hooksPath", hooks.path], at: fixture.рабочееДерево)

    let before = try ссылкиBare(fixture.удалённыйBare, at: fixture.корень)
    let trusted = try довереннаяЛокальнаяФикстура(fixture)
    let command = try #require(ПостроительКомандыGit.отправитьВУдалённыйРепозиторий(для: trusted))
    var refused = false
    do {
        _ = try АдаптерВыполненияКомандGit.выполнить(command)
    } catch {
        refused = true
    }

    #expect(refused)
    #expect(!FileManager.default.fileExists(atPath: marker.path))
    #expect(try ссылкиBare(fixture.удалённыйBare, at: fixture.корень) == before)
}
