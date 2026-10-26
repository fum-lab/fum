import Foundation
import Testing
@testable import МатериализацияУзлов

private let корневойUUID = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
private let писательUUID = "01a177f5-1f11-7543-a68f-fe7e73ff5345"
private let родительUUID = "01a127bf-38dd-7fc0-8c7b-1d245d7706a5"
private let исходныйКоммит = "84976661fba027ab43fdd5901c5bb0b5e01cd6dd"
private let исходноеДерево = "069b2ddf36e9f39781ba682b3881d0f0f435ac13"
private let собственнаяВетка = "refs/heads/fum-lab/fum/instrumentyi/perekhod-vetok/sinkhronizaciya/master"
private let веткаРодителя = "refs/heads/fum-lab/fum/instrumentyi/perekhod-vetok/master"

func образецИнвентаря(
    числоУзлов: Int = 1,
    состояние: СостояниеИнвентаря = .чистое
) -> ПакетныйИнвентарьСинхронизации {
    let источникКарты = ИсточникСинхронизации(
        коммит: исходныйКоммит,
        дерево: исходноеДерево,
        путь: "iskhodniki/perekhod-vetok/karta-imyon-sinkhronizacii.json",
        blob: "e51deaacfc8ce5c77556fb86d8d7efb4455fb17a",
        sha256: "d2d9f32feb5054bcc27cff86fdf5bf79504a46cfa85473ed577f536dcdca9585")
    let карта = КартаИменСинхронизации(
        схема: "fum.карта-имён-среза-материализации.1",
        ревизия: "837e2ce107b97ee7b9d3344c9fe99142281fe393",
        источник: источникКарты,
        карта: [
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/uzlyi/синхронизация/инвентарь.swift", целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/inventarj.swift", вид: .файл),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/uzlyi/синхронизация/план.swift", целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/plan.swift", вид: .файл),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/uzlyi/синхронизация/адаптер.swift", целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/adapter.swift", вид: .файл),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/proverki/синхронизация/проверки.swift", целевой: "iskhodniki/perekhod-vetok/proverki/sinkhronizaciya/proverki.swift", вид: .файл),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/proverki/синхронизация/профиль.swift", целевой: "iskhodniki/perekhod-vetok/proverki/sinkhronizaciya/profilj.swift", вид: .файл),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/zhurnal/синхронизация", целевой: "iskhodniki/perekhod-vetok/zhurnal/sinkhronizaciya", вид: .каталог),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/постановка-синхронизации.json", целевой: "iskhodniki/perekhod-vetok/postanovka-sinkhronizacii.json", вид: .файл),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/карта-имён-синхронизации.json", целевой: "iskhodniki/perekhod-vetok/karta-imyon-sinkhronizacii.json", вид: .файл),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/поставка", целевой: "iskhodniki/perekhod-vetok/postavka", вид: .каталог),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/план-поставки.json", целевой: "iskhodniki/perekhod-vetok/plan-postavki.json", вид: .файл),
            ОтображениеИмен(исходный: "iskhodniki/perekhod-vetok/карта-имён-поставки.json", целевой: "iskhodniki/perekhod-vetok/karta-imyon-postavki.json", вид: .файл),
        ])

    let facadeSource = ИсточникСинхронизации(
        коммит: "7da711b39ed356017afed7ffa861be5b5998c4d9",
        дерево: "77b24437a73d2451bca7ed40ebee5110cd4c22c4",
        путь: "iskhodniki/aktualizaciya-putej/paket-perenosa.swift",
        blob: "aeeea0129bf111d7d9901e60731c3389d40a21b4",
        sha256: "5b2b52026a04c10f4c46f25b22db2f7088a1da42cfca0fda58395753bedb48ee")
    let recoverySource = ИсточникСинхронизации(
        коммит: "9909c19aade5820e41798d155f9c30978b48453d",
        дерево: "0cbd2769919fe4c7d94d0951f0fd25496cc7be46",
        путь: "iskhodniki/perekhod-vetok/uzlyi/vosstanovleniye/plan.swift",
        blob: "6b4ad4bf6fff8ea24f9fbd4b59a9aee1c223e9f8",
        sha256: "4f5f79cda1f01e64e83163525708e903e919849594e136e6c3219387a36aaecd")
    let dependencySource = ИсточникСинхронизации(
        коммит: "837e2ce107b97ee7b9d3344c9fe99142281fe393",
        дерево: "02659ca37d3a2b7da7c70d8e9019081302b735aa",
        путь: "Sources/LinguisticKit/LinguisticKit.swift",
        blob: "856ceaa8d963958d4517bb60a63396a75eb6344d",
        sha256: "9179292b094c4d96c33d93d618408e44d0f5450c2c18e890033f9ab3e3923e5f")
    let пожелания = [
        ПожеланиеАгентаСинхронизации(
            владелецЗадачи: nil,
            владелецRef: "refs/heads/fum-lab/fum/instrumentyi/imena-katalogov/publichnyij-fasad-imyon/master",
            желаемыйРезультат: "Публичный Names facade для отображения одного пути",
            выбранныйИсточник: facadeSource,
            получениеACK: .неизвестно,
            применение: .неПрименено,
            свидетельствоПрименения: "В 7da711b3 публичный batch API принимает фиксированную карту девяти путей; это не общий getter одного имени. Ранее просмотренный актор c6af44bf остаётся internal. Ни один API не импортирован и не вызван; typed map C остаётся явным входом.",
            критерийВозвратаВнимания: "Возвратить внимание, когда появится минимальный public фасад над существующим mapper и его точный C/tree/path/blob/hash."),
        ПожеланиеАгентаСинхронизации(
            владелецЗадачи: nil,
            владелецRef: "refs/heads/fum-lab/fum/instrumentyi/perekhod-vetok/vosstanovleniye/master",
            желаемыйРезультат: "Повторяемый учёт terminal-исхода собственного Git-эффекта",
            выбранныйИсточник: recoverySource,
            получениеACK: .неизвестно,
            применение: .неПрименено,
            свидетельствоПрименения: "Источник прочитан; импорт и копирование не выполнялись, текущий срез ограничен read-only plan/no-op.",
            критерийВозвратаВнимания: "Возвратить внимание, если появится отдельный допуск на собственное ref-изменение и потребуется persisted retry/terminal-readback."),
        ПожеланиеАгентаСинхронизации(
            владелецЗадачи: родительUUID,
            владелецRef: веткаРодителя,
            желаемыйРезультат: "Проверенная зарегистрированная LinguisticKit на точном gitlink",
            выбранныйИсточник: dependencySource,
            получениеACK: .получен,
            применение: .применено,
            свидетельствоПрименения: "Разрешённый init/check завершился кодом 0; submodule остался на точном gitlink.",
            критерийВозвратаВнимания: "Возвратить внимание при дрейфе gitlink, .gitmodules, remotes, shallow-состояния или чистоты клона."),
        ПожеланиеАгентаСинхронизации(
            владелецЗадачи: nil,
            владелецRef: "refs/heads/fum-lab/fum/instrumentyi/perekhod-vetok/vosstanovleniye/master",
            желаемыйРезультат: "Повторить тот же intent после частичного эффекта своего ref",
            выбранныйИсточник: recoverySource,
            получениеACK: .неизвестно,
            применение: .неПрименено,
            свидетельствоПрименения: "Recovery-кандидат прочитан, но не импортирован; фактический ref-эффект этим wish не заявлен.",
            критерийВозвратаВнимания: "Возвратить внимание после отдельного решения о bounded ref backend и точного terminal readback."),
    ]

    let узлы = (0..<max(числоУзлов, 1)).map { номер in
        let ownerRef = номер == 0 ? собственнаяВетка : "refs/heads/codex/profile/sync-\(номер)"
        let fingerprint = String(repeating: "0", count: 60) + String(format: "%04x", номер + 1)
        return УзелИнвентаря(
            логическийАдрес: "perekhod-vetok/sinkhronizaciya/\(номер)",
            ответственность: "Синхронизация ветки и адресов",
            роль: .ответственность,
            задача: писательUUID,
            владелец: писательUUID,
            имяЧата: номер == 0 ? "fum-lab/fum/instrumentyi/perekhod-vetok/sinkhronizaciya/master" : nil,
            threadID: номер == 0 ? писательUUID : nil,
            каталог: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya",
            файл: "inventarj.swift",
            ref: ownerRef,
            рабочееДеревоSHA256: fingerprint,
            коммит: исходныйКоммит,
            дерево: исходноеДерево,
            remoteOID: nil,
            желаемоеИмяЧата: nil,
            состояние: номер == 0 ? состояние : .чистое,
            источники: [источникКарты])
    }
    let refs = узлы.map { node in
        НаблюдениеRef(
            ref: node.ref!,
            oid: исходныйКоммит,
            роль: "responsibility",
            владелец: писательUUID)
    } + [НаблюдениеRef(ref: веткаРодителя, oid: "e38ed1e97159cd695999cb89b34d0521f0e74c92", роль: "coordinator", владелец: родительUUID)]
    let worktrees = узлы.map { node in
        НаблюдениеРабочегоДерева(
            fingerprintSHA256: node.рабочееДеревоSHA256!,
            владелец: писательUUID,
            ref: node.ref!,
            состояние: node.состояние)
    }
    let snapshot = СнимокGitСинхронизации(
        корневаяЗадача: корневойUUID,
        писатель: писательUUID,
        исходныйКоммит: исходныйКоммит,
        исходноеДерево: исходноеДерево,
        ref: собственнаяВетка,
        head: исходныйКоммит,
        дерево: исходноеДерево,
        индексSHA256: String(repeating: "1", count: 64),
        рабочееДеревоSHA256: узлы[0].рабочееДеревоSHA256!,
        состояние: состояние,
        остановка: false,
        пауза: false,
        активность: false,
        ожидаемыйRef: собственнаяВетка,
        ожидаемыйHead: исходныйКоммит,
        ожидаемоеДерево: исходноеДерево,
        наблюдаемыеПути: [])
    return ПакетныйИнвентарьСинхронизации(
        снимок: snapshot,
        refs: refs,
        рабочиеДеревья: worktrees,
        узлы: узлы,
        картаИмен: карта,
        пожелания: пожелания)
}

@Suite struct ПроверкиСинхронизации {
    @Test func пакетныйПланДетерминированПриПерестановкеВходов() throws {
        let first = образецИнвентаря()
        var second = first
        second.refs.reverse()
        second.рабочиеДеревья.reverse()
        second.узлы.reverse()
        second.картаИмен.карта.reverse()
        second.пожелания.reverse()

        let firstPlan = try ПланировщикСинхронизации.построить(first)
        let secondPlan = try ПланировщикСинхронизации.построить(second)

        #expect(firstPlan.идентификатор == secondPlan.идентификатор)
        #expect(try firstPlan.байты() == secondPlan.байты())
    }

    @Test func картаСохраняетТолькоШестьСтрокСвоейОбласти() throws {
        let plan = try ПланировщикСинхронизации.построить(образецИнвентаря())

        #expect(plan.переходыПутей.count == 6)
        #expect(plan.строкВнеОбласти == 5)
        #expect(plan.источникКарты.путь == "iskhodniki/perekhod-vetok/karta-imyon-sinkhronizacii.json")
        #expect(plan.источникКарты.sha256 == "d2d9f32feb5054bcc27cff86fdf5bf79504a46cfa85473ed577f536dcdca9585")
        #expect(plan.источникКарты.коммит == исходныйКоммит)
        #expect(plan.источникКарты.дерево == исходноеДерево)
        #expect(plan.источникКарты.blob == "e51deaacfc8ce5c77556fb86d8d7efb4455fb17a")
        #expect(plan.узлы.allSatisfy { $0.коммит == исходныйКоммит && $0.дерево == исходноеДерево })
        #expect(plan.переходыПутей.allSatisfy { $0.исходный.contains("синхронизация") })
    }

    @Test func записиЖурналаМатериалыИПроекцииНеСоздаютУзлы() throws {
        var inventory = образецИнвентаря()
        for role in [РольИнвентаря.записьЖурнала, .материал, .проекция, .техническийАртефакт] {
            inventory.узлы.append(УзелИнвентаря(
                логическийАдрес: "local-artifact/\(role.rawValue)",
                ответственность: "Локальная запись",
                роль: role,
                задача: nil,
                владелец: nil,
                имяЧата: nil,
                threadID: nil,
                каталог: "iskhodniki/perekhod-vetok/zhurnal/sinkhronizaciya",
                файл: "local.json",
                ref: nil,
                рабочееДеревоSHA256: nil,
                коммит: nil,
                дерево: nil,
                remoteOID: nil,
                желаемоеИмяЧата: nil,
                состояние: .грязное,
                источники: []))
        }

        let plan = try ПланировщикСинхронизации.построить(inventory)

        #expect(plan.узлы.count == 1)
        #expect(plan.решение == .readOnlyNoOp)
    }

    @Test func одинаковыйOIDНеСхлопываетРазныеРолиИВладельцев() throws {
        var inventory = образецИнвентаря()
        var alias = inventory.узлы[0]
        alias.логическийАдрес = "perekhod-vetok/alias"
        alias.владелец = родительUUID
        alias.задача = родительUUID
        alias.ref = веткаРодителя
        alias.рабочееДеревоSHA256 = String(repeating: "2", count: 64)
        alias.threadID = родительUUID
        inventory.узлы.append(alias)
        inventory.refs.append(НаблюдениеRef(ref: веткаРодителя, oid: исходныйКоммит, роль: "coordinator", владелец: родительUUID))
        inventory.рабочиеДеревья.append(НаблюдениеРабочегоДерева(
            fingerprintSHA256: String(repeating: "2", count: 64), владелец: родительUUID, ref: веткаРодителя, состояние: .чистое))

        let plan = try ПланировщикСинхронизации.построить(inventory)

        #expect(plan.узлы.count == 2)
        #expect(plan.узлы.map(\.коммит).allSatisfy { $0 == исходныйКоммит })
        #expect(Set(plan.узлы.compactMap(\.владелец)).count == 2)
    }

    @Test(arguments: [СостояниеИнвентаря.грязное, .чужое, .активное, .остановлено, .приостановлено, .неизвестно, .дрейф])
    func небезопасноеСостояниеБлокируетЭффект(_ state: СостояниеИнвентаря) throws {
        let inventory = образецИнвентаря(состояние: state)
        let plan = try ПланировщикСинхронизации.построить(inventory)

        #expect(plan.решение == .заблокировано)
        #expect(throws: ОшибкаСинхронизации.запрещённоеСостояние) {
            try АдаптерСинхронизации.применить(plan, текущее: inventory)
        }
    }

    @Test func дрейфRefИлиДереваПослеПланаОтказывает() throws {
        let inventory = образецИнвентаря()
        let plan = try ПланировщикСинхронизации.построить(inventory)
        var changedHead = inventory
        changedHead.снимок.head = String(repeating: "a", count: 40)
        var changedRef = inventory
        changedRef.снимок.ref = "refs/heads/codex/foreign-ref"
        var changedTree = inventory
        changedTree.снимок.дерево = String(repeating: "b", count: 40)

        for changed in [changedHead, changedRef, changedTree] {
            #expect(throws: ОшибкаСинхронизации.дрейф) {
                try АдаптерСинхронизации.применить(plan, текущее: changed)
            }
        }
    }

    @Test func изменениеSourcePinПослеПланаОтказываетКакДрейф() throws {
        let inventory = образецИнвентаря()
        let plan = try ПланировщикСинхронизации.построить(inventory)
        var changed = inventory
        changed.картаИмен = КартаИменСинхронизации(
            схема: inventory.картаИмен.схема,
            ревизия: inventory.картаИмен.ревизия,
            источник: ИсточникСинхронизации(
                коммит: String(repeating: "c", count: 40), дерево: исходноеДерево,
                путь: inventory.картаИмен.источник.путь,
                blob: inventory.картаИмен.источник.blob,
                sha256: inventory.картаИмен.источник.sha256),
            карта: inventory.картаИмен.карта)

        #expect(throws: ОшибкаСинхронизации.дрейф) {
            try АдаптерСинхронизации.применить(plan, текущее: changed)
        }
    }

    @Test func точныйReadOnlyNoOpИПовторВозвращаютОднуКвитанцию() throws {
        let inventory = образецИнвентаря()
        let plan = try ПланировщикСинхронизации.построить(inventory)
        let first = try АдаптерСинхронизации.применить(plan, текущее: inventory)
        let repeated = try АдаптерСинхронизации.применить(plan, текущее: inventory)

        #expect(plan.решение == .readOnlyNoOp)
        #expect(first == repeated)
        #expect(first.побочныйЭффект == .нет)
        #expect(first.исход == .наблюдена)
    }

    @Test func созданиеСобственногоRefПослеОбрываПовторяетТотЖеIntent() throws {
        let plan = try ПланировщикСинхронизации.построить(образецИнвентаря())
        let namespace = String(plan.снимок.ref.dropLast("/master".count))
        let target = namespace + "/candidate"
        let intent = try АдаптерСобственногоRef.подготовить(план: plan, целевойRef: target)
        var store = СостояниеRefСинхронизации()

        #expect(throws: ОтказСозданияСобственногоRef.прерваноПослеЭффекта) {
            try АдаптерСобственногоRef.применить(intent, к: &store, прерватьПослеЭффекта: true)
        }
        #expect(store.refs[target] == исходныйКоммит)
        #expect(store.эффектов == 1)
        #expect(store.фаза(намерение: intent.идентификатор) == .эффектНаблюдён)

        let recovered = try АдаптерСобственногоRef.применить(intent, к: &store)
        let repeated = try АдаптерСобственногоRef.применить(intent, к: &store)

        #expect(recovered.намерение == intent.идентификатор)
        #expect(recovered == repeated)
        #expect(store.refs[target] == исходныйКоммит)
        #expect(store.эффектов == 1)
        #expect(store.фаза(намерение: intent.идентификатор) == .завершено)
    }

    @Test func созданиеСобственногоRefНеПереписываетЗанятуюЦель() throws {
        let plan = try ПланировщикСинхронизации.построить(образецИнвентаря())
        let namespace = String(plan.снимок.ref.dropLast("/master".count))
        let target = namespace + "/candidate"
        let intent = try АдаптерСобственногоRef.подготовить(план: plan, целевойRef: target)
        var store = СостояниеRefСинхронизации(refs: [target: String(repeating: "f", count: 40)])

        #expect(throws: ОтказСозданияСобственногоRef.целевойRefЗанят) {
            try АдаптерСобственногоRef.применить(intent, к: &store)
        }
        #expect(store.refs[target] == String(repeating: "f", count: 40))
        #expect(store.эффектов == 0)
    }

    @Test func caseNFCИNamespaceКоллизииЗакрываютПлан() {
        var caseCollision = образецИнвентаря()
        caseCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/Foo.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/case-a.swift", вид: .файл))
        caseCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/foo.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/case-b.swift", вид: .файл))
        #expect(throws: ОшибкаИнвентаря.коллизия) {
            try ВалидаторИнвентаря.проверить(caseCollision)
        }

        var nfcCollision = образецИнвентаря()
        nfcCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/é.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/nfc-a.swift", вид: .файл))
        nfcCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/e\u{301}.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/nfc-b.swift", вид: .файл))
        #expect(throws: ОшибкаИнвентаря.коллизия) {
            try ВалидаторИнвентаря.проверить(nfcCollision)
        }

        var namespaceCollision = образецИнвентаря()
        namespaceCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/directory.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/namespace", вид: .файл))
        namespaceCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/child.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/namespace/child.swift", вид: .файл))
        #expect(throws: ОшибкаИнвентаря.коллизия) {
            try ВалидаторИнвентаря.проверить(namespaceCollision)
        }

        var targetCaseCollision = образецИнвентаря()
        targetCaseCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/target-a.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/Target.swift", вид: .файл))
        targetCaseCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/target-b.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/target.swift", вид: .файл))
        #expect(throws: ОшибкаИнвентаря.коллизия) {
            try ВалидаторИнвентаря.проверить(targetCaseCollision)
        }

        var targetNFCCollision = образецИнвентаря()
        targetNFCCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/target-a.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/target-é.swift", вид: .файл))
        targetNFCCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/target-b.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/target-e\u{301}.swift", вид: .файл))
        #expect(throws: ОшибкаИнвентаря.коллизия) {
            try ВалидаторИнвентаря.проверить(targetNFCCollision)
        }

        var targetNamespaceCollision = образецИнвентаря()
        targetNamespaceCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/target-file.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/new-namespace", вид: .файл))
        targetNamespaceCollision.картаИмен.карта.append(ОтображениеИмен(
            исходный: "iskhodniki/perekhod-vetok/uzlyi/old/target-child.swift",
            целевой: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/new-namespace/child.swift", вид: .файл))
        #expect(throws: ОшибкаИнвентаря.коллизия) {
            try ВалидаторИнвентаря.проверить(targetNamespaceCollision)
        }
    }

    @Test func wishesСвязываютИсточникACKПрименениеИКритерийВозврата() throws {
        let plan = try ПланировщикСинхронизации.построить(образецИнвентаря())
        let facade = try #require(plan.пожелания.first { $0.желаемыйРезультат.contains("Names") })
        let dependency = try #require(plan.пожелания.first { $0.желаемыйРезультат.contains("LinguisticKit") })
        let recovery = try #require(plan.пожелания.first { $0.желаемыйРезультат.contains("intent") })

        #expect(facade.выбранныйИсточник?.коммит == "7da711b39ed356017afed7ffa861be5b5998c4d9")
        #expect(facade.получениеACK == .неизвестно)
        #expect(facade.применение == .неПрименено)
        #expect(!facade.критерийВозвратаВнимания.isEmpty)
        #expect(dependency.получениеACK == .получен)
        #expect(dependency.применение == .применено)
        #expect(!dependency.критерийВозвратаВнимания.isEmpty)
        #expect(recovery.выбранныйИсточник?.коммит == "9909c19aade5820e41798d155f9c30978b48453d")
        #expect(recovery.получениеACK == .неизвестно)
        #expect(recovery.применение == .неПрименено)
        #expect(!recovery.критерийВозвратаВнимания.isEmpty)
    }

    @Test func чатТолькоПланируетсяПоТочномуThreadID() throws {
        var inventory = образецИнвентаря()
        inventory.узлы[0].желаемоеИмяЧата = "sinkhronizaciya"
        let plan = try ПланировщикСинхронизации.построить(inventory)

        #expect(plan.переименованияЧатов.count == 1)
        #expect(plan.переименованияЧатов[0].threadID == писательUUID)
        #expect(plan.переименованияЧатов[0].выполнено == false)
        #expect(plan.переименованияЧатов[0].эффект == .требуетсяДействиеВладельца)
    }

    @Test func публичныйJSONНеСодержитЧастныхМашинныхПутей() throws {
        let plan = try ПланировщикСинхронизации.построить(образецИнвентаря())
        let text = String(decoding: try plan.байты(), as: UTF8.self)

        #expect(text.hasSuffix("\n"))
        #expect(!text.contains("/Users/"))
        #expect(!text.contains("/tmp/"))
        #expect(!text.contains("file://"))
        #expect(text.contains("iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya"))
    }

    @Test func сериализованныйПланСохраняетИдентичностьИЦелостность() throws {
        let plan = try ПланировщикСинхронизации.построить(образецИнвентаря())
        let decoded = try JSONDecoder().decode(ПланСинхронизации.self, from: plan.байты())

        #expect(decoded == plan)
        #expect(try АдаптерСинхронизации.применить(decoded, текущее: образецИнвентаря()).исход == .наблюдена)
    }

    @Test func несовпадениеИсходнойВершиныОтвергаетсяВИнвентаре() {
        var inventory = образецИнвентаря()
        inventory.снимок.head = String(repeating: "a", count: 40)

        #expect(throws: ОшибкаИнвентаря.снимок) {
            try ВалидаторИнвентаря.проверить(inventory)
        }
    }

    @Test func публичныеТекстовыеПоляНеПринимаютАбсолютныеПути() {
        var inventory = образецИнвентаря()
        let slash = String(UnicodeScalar(47))
        inventory.узлы[0].ответственность = "Скрытый локальный корень: " + slash + "Users/private"

        #expect(throws: ОшибкаИнвентаря.путь) {
            try ВалидаторИнвентаря.проверить(inventory)
        }
    }

    @Test func cliПроходитInventoryPlanApplyИNoOpБезВнешнегоЭффекта() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("fum-sync-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }

        let inventoryURL = directory.appendingPathComponent("inventory.json")
        let planURL = directory.appendingPathComponent("plan.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(образецИнвентаря()).write(to: inventoryURL, options: [.atomic])

        let inventoryBytes = try await КомандаСинхронизации.выполнить(
            ["inventory", "--вход", inventoryURL.path])
        let planBytes = try await КомандаСинхронизации.выполнить(
            ["plan", "--вход", inventoryURL.path])
        try planBytes.write(to: planURL, options: [.atomic])
        let applyBytes = try await КомандаСинхронизации.выполнить(
            ["apply", "--вход", inventoryURL.path, "--план", planURL.path])
        let noOpBytes = try await КомандаСинхронизации.выполнить(
            ["no-op", "--вход", inventoryURL.path, "--план", planURL.path])
        let help = try await КомандаСинхронизации.выполнить(["помощь"])

        let inventoryText = String(decoding: inventoryBytes, as: UTF8.self)
        let planText = String(decoding: planBytes, as: UTF8.self)
        #expect(!inventoryText.contains(directory.path))
        #expect(!planText.contains(directory.path))
        #expect(planText.hasSuffix("\n"))
        #expect(applyBytes == noOpBytes)
        #expect(String(decoding: help, as: UTF8.self).contains("swift run fuma синхронизация plan"))
    }
}
