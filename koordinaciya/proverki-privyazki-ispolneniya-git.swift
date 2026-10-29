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
            адресOrigin: АдресУдалённогоGit(адрес: originURL)!
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
    #expect(команда.аргументы == ["push", "origin", "\(oidТеста):\(рефТеста)"])
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
    #expect(полученныеАргументы == ["push", "origin", "\(снимок.oidHEAD.oid):\(снимок.реф.реф)"])
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
