import Testing
import Foundation
import CryptoKit
@testable import МатериализацияУзлов

@Suite struct ПроверкиЖизненногоЦиклаУзлов {
    private let корень = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
    private let oid = "650d794571862e3229a3624b74e41bc6632cc18b"
    private let tree = "f7f567873ae01dfbc0224888711e826c71013e7b"

    private func дескриптор(
        чат: String = "01a195e5-70bf-7a81-920f-d15df36fc90a",
        ход: String = "01a1972a-cafc-7c41-bdeb-bcd0117225b9",
        узел: String = "fum-lab/fum/instrumentyi/rantajm-agentov/zhiznennyj-cikl/master",
        ref: String = "refs/heads/fum-lab/fum/instrumentyi/rantajm-agentov/zhiznennyj-cikl/master",
        worktree: String = "/Users/fum/.codex/worktrees/zhiznennyj-cikl-01a195e5/FUM",
        sourceCommit: String = "650d794571862e3229a3624b74e41bc6632cc18b",
        sourceTree: String = "f7f567873ae01dfbc0224888711e826c71013e7b",
        version: UInt64 = 2,
        checkpoint: КонтрольнаяТочкаЖизненногоЦикла? = nil
    ) -> ДескрипторЖизненногоЦиклаУзла {
        let состояние = СостояниеУзлаЖизненногоЦикла(
            корневаяЗадачаUUID: корень, nativeChatUUID: чат, executionTurn: ход,
            логическийУзел: узел, полныйRef: ref, физическийWorktree: worktree,
            sourceCommit: sourceCommit, sourceTree: sourceTree, версияСостояния: version)
        return ДескрипторЖизненногоЦиклаУзла(
            корневаяЗадачаUUID: корень, nativeChatUUID: чат, executionTurn: ход,
            логическийУзел: узел, полныйRef: ref, физическийWorktree: worktree,
            текущееСостояние: состояние, checkpoint: checkpoint,
            версияПроисхождения: "C650/1",
            границаПолномочий: ГраницаПолномочийЖизненногоЦикла(
                разрешённыеПути: ["iskhodniki/perekhod-vetok/uzlyi/**"]))
    }

    private func checkpoint(
        _ д: ДескрипторЖизненногоЦиклаУзла,
        root: String? = nil, chat: String? = nil, turn: String? = nil,
        node: String? = nil, ref: String? = nil, worktree: String? = nil,
        sourceCommit: String? = nil, sourceTree: String? = nil,
        version: UInt64? = nil, nextID: String = "общий-id"
    ) -> КонтрольнаяТочкаЖизненногоЦикла {
        КонтрольнаяТочкаЖизненногоЦикла(
            корневаяЗадачаUUID: root ?? д.корневаяЗадачаUUID,
            nativeChatUUID: chat ?? д.nativeChatUUID,
            executionTurn: turn ?? д.executionTurn,
            логическийУзел: node ?? д.логическийУзел,
            полныйRef: ref ?? д.полныйRef,
            физическийWorktree: worktree ?? д.физическийWorktree,
            sourceCommit: sourceCommit ?? д.текущееСостояние.sourceCommit,
            sourceTree: sourceTree ?? д.текущееСостояние.sourceTree,
            версияСостояния: version ?? д.текущееСостояние.версияСостояния,
            завершённыйШагID: nil, следующийРазрешённыйШагID: nextID)
    }

    @Test func дваУзлаНеСмешиваютЧатыХодыRefИWorktree() throws {
        let первый = дескриптор()
        let второй = дескриптор(
            чат: "01a195e6-5364-76e3-b963-c2c305e6111f",
            ход: "01a1972b-cafc-7c41-bdeb-bcd0117225b9",
            узел: "fum-lab/fum/instrumentyi/rantajm-agentov/normalizaciya-kornej/master",
            ref: "refs/heads/fum-lab/fum/instrumentyi/rantajm-agentov/normalizaciya-kornej/master",
            worktree: "/Users/fum/.codex/worktrees/normalizaciya-kornej/FUM")
        try первый.проверитьСвязность()
        try второй.проверитьСвязность()
        #expect(первый.nativeChatUUID != второй.nativeChatUUID)
        #expect(первый.executionTurn != второй.executionTurn)
        #expect(первый.полныйRef != второй.полныйRef)
        #expect(первый.физическийWorktree != второй.физическийWorktree)
        #expect(try первый.параметрыNativeВызова().nativeChatUUID == первый.nativeChatUUID)
        #expect(try второй.параметрыПубликации().полныйRef == второй.полныйRef)
        #expect(throws: ОшибкаЖизненногоЦикла.другойЧат) {
            try первый.проверить(второй.текущееСостояние)
        }
    }

    @Test func currentОтклоняетДругойSourceИУстаревшуюВерсиюТогоЖеУзла() throws {
        let д = дескриптор()
        let другойSource = СостояниеУзлаЖизненногоЦикла(
            корневаяЗадачаUUID: д.корневаяЗадачаUUID, nativeChatUUID: д.nativeChatUUID,
            executionTurn: д.executionTurn, логическийУзел: д.логическийУзел,
            полныйRef: д.полныйRef, физическийWorktree: д.физическийWorktree,
            sourceCommit: String(repeating: "a", count: 40), sourceTree: tree, версияСостояния: 2)
        #expect(throws: ОшибкаЖизненногоЦикла.другойSource) { try д.проверить(другойSource) }
        let стараяВерсия = СостояниеУзлаЖизненногоЦикла(
            корневаяЗадачаUUID: д.корневаяЗадачаUUID, nativeChatUUID: д.nativeChatUUID,
            executionTurn: д.executionTurn, логическийУзел: д.логическийУзел,
            полныйRef: д.полныйRef, физическийWorktree: д.физическийWorktree,
            sourceCommit: oid, sourceTree: tree, версияСостояния: 1)
        #expect(throws: ОшибкаЖизненногоЦикла.другаяВерсияСостояния) {
            try д.проверить(стараяВерсия)
        }
    }

    @Test func чужойУстаревшийRootCurrentОтклоняется() throws {
        let д = дескриптор()
        let чужое = СостояниеУзлаЖизненногоЦикла(
            корневаяЗадачаUUID: "01a17797-519b-73c1-bcc8-fd295cdfe9b0",
            nativeChatUUID: д.nativeChatUUID, executionTurn: д.executionTurn,
            логическийУзел: д.логическийУзел, полныйRef: д.полныйRef,
            физическийWorktree: д.физическийWorktree, sourceCommit: oid,
            sourceTree: tree, версияСостояния: 1)
        #expect(throws: ОшибкаЖизненногоЦикла.чужойКорень) { try д.проверить(чужое) }
    }

    @Test func checkpointВозвращаетТолькоТочныйСледующийРазрешённыйШаг() throws {
        let д = дескриптор(checkpoint: КонтрольнаяТочкаЖизненногоЦикла(
            корневаяЗадачаUUID: корень,
            nativeChatUUID: "01a195e5-70bf-7a81-920f-d15df36fc90a",
            executionTurn: "01a1972a-cafc-7c41-bdeb-bcd0117225b9",
            логическийУзел: "fum-lab/fum/instrumentyi/rantajm-agentov/zhiznennyj-cikl/master",
            полныйRef: "refs/heads/fum-lab/fum/instrumentyi/rantajm-agentov/zhiznennyj-cikl/master",
            физическийWorktree: "/Users/fum/.codex/worktrees/zhiznennyj-cikl-01a195e5/FUM",
            sourceCommit: oid, sourceTree: tree, версияСостояния: 2,
            завершённыйШагID: "сохранить-дескриптор", следующийРазрешённыйШагID: "сверить-приём"))
        let список = try СвойРабочийСписокУзла(дескриптор: д, шаги: [
            ШагЖизненногоЦикла(id: "сохранить-дескриптор", состояние: .завершён, требуемыйSourceCommit: oid),
            ШагЖизненногоЦикла(id: "сверить-приём", состояние: .разрешён, требуемыйSourceCommit: oid),
            ШагЖизненногоЦикла(id: "доставить", состояние: .разрешён, требуемыйSourceCommit: oid)
        ])
        #expect(try список.следующийШаг(после: д.checkpoint).id == "сверить-приём")
    }

    @Test func checkpointДругогоУзлаИУстаревшейВерсииОтклоняетсяПриСовпавшемID() throws {
        let первый = дескриптор()
        let второй = дескриптор(
            чат: "01a195e6-5364-76e3-b963-c2c305e6111f",
            ход: "01a1972b-cafc-7c41-bdeb-bcd0117225b9",
            узел: "fum-lab/fum/instrumentyi/rantajm-agentov/normalizaciya-kornej/master",
            ref: "refs/heads/fum-lab/fum/instrumentyi/rantajm-agentov/normalizaciya-kornej/master",
            worktree: "/Users/fum/.codex/worktrees/normalizaciya-kornej/FUM")
        let список = try СвойРабочийСписокУзла(дескриптор: первый, шаги: [
            ШагЖизненногоЦикла(id: "общий-id", состояние: .разрешён, требуемыйSourceCommit: oid)
        ])
        let чужойCheckpoint = КонтрольнаяТочкаЖизненногоЦикла(
            корневаяЗадачаUUID: второй.корневаяЗадачаUUID,
            nativeChatUUID: второй.nativeChatUUID, executionTurn: второй.executionTurn,
            логическийУзел: второй.логическийУзел, полныйRef: второй.полныйRef,
            физическийWorktree: второй.физическийWorktree, sourceCommit: oid, sourceTree: tree,
            версияСостояния: 2, завершённыйШагID: nil, следующийРазрешённыйШагID: "общий-id")
        #expect(throws: ОшибкаЖизненногоЦикла.другойЧат) {
            try список.следующийШаг(после: чужойCheckpoint)
        }
        let старыйCheckpoint = КонтрольнаяТочкаЖизненногоЦикла(
            корневаяЗадачаUUID: первый.корневаяЗадачаUUID,
            nativeChatUUID: первый.nativeChatUUID, executionTurn: первый.executionTurn,
            логическийУзел: первый.логическийУзел, полныйRef: первый.полныйRef,
            физическийWorktree: первый.физическийWorktree, sourceCommit: oid, sourceTree: tree,
            версияСостояния: 1, завершённыйШагID: nil, следующийРазрешённыйШагID: "общий-id")
        #expect(throws: ОшибкаЖизненногоЦикла.другаяВерсияСостояния) {
            try список.следующийШаг(после: старыйCheckpoint)
        }
    }

    @Test func checkpointСверяетВесьАдресИSourceПередВыборомСовпавшегоID() throws {
        let д = дескриптор()
        let список = try СвойРабочийСписокУзла(дескриптор: д, шаги: [
            ШагЖизненногоЦикла(id: "общий-id", состояние: .разрешён, требуемыйSourceCommit: oid)
        ])
        #expect(throws: ОшибкаЖизненногоЦикла.чужойКорень) {
            try список.следующийШаг(после: checkpoint(д, root: "01a17797-519b-73c1-bcc8-fd295cdfe9b0"))
        }
        #expect(throws: ОшибкаЖизненногоЦикла.другойХод) {
            try список.следующийШаг(после: checkpoint(д, turn: "01a1972b-cafc-7c41-bdeb-bcd0117225b9"))
        }
        #expect(throws: ОшибкаЖизненногоЦикла.чужойУзел) {
            try список.следующийШаг(после: checkpoint(д, node: "чужой-узел"))
        }
        #expect(throws: ОшибкаЖизненногоЦикла.другойRef) {
            try список.следующийШаг(после: checkpoint(д, ref: "refs/heads/чужая-ветка"))
        }
        #expect(throws: ОшибкаЖизненногоЦикла.другойWorktree) {
            try список.следующийШаг(после: checkpoint(д, worktree: "/foreign/FUM"))
        }
        #expect(throws: ОшибкаЖизненногоЦикла.другойSource) {
            try список.следующийШаг(после: checkpoint(д, sourceCommit: String(repeating: "a", count: 40)))
        }
        #expect(throws: ОшибкаЖизненногоЦикла.другойSource) {
            try список.следующийШаг(после: checkpoint(д, sourceTree: String(repeating: "b", count: 40)))
        }
        #expect(throws: ОшибкаЖизненногоЦикла.другаяВерсияСостояния) {
            try список.следующийШаг(после: checkpoint(д, version: 1))
        }
    }

    @Test func декодированныйСписокСЧужимSourceНеВыбираетШаг() throws {
        let д = дескриптор()
        let исходный = try списокДляРодителя(д)
        var объект = try JSONSerialization.jsonObject(with: JSONEncoder().encode(исходный)) as! [String: Any]
        var шаги = объект["шаги"] as! [[String: Any]]
        шаги[0]["требуемыйSourceCommit"] = String(repeating: "a", count: 40)
        объект["шаги"] = шаги
        let байты = try JSONSerialization.data(withJSONObject: объект)
        let восстановленный = try JSONDecoder().decode(СвойРабочийСписокУзла.self, from: байты)
        #expect(throws: ОшибкаЖизненногоЦикла.другойSource) {
            try восстановленный.следующийШаг(после: nil)
        }
    }

    @Test func persistReopenПередВозвратомДаётСтабильныйOperationID() async throws {
        let д = дескриптор()
        let список = try СвойРабочийСписокУзла(дескриптор: д, шаги: [
            ШагЖизненногоЦикла(id: "проверить", состояние: .разрешён, требуемыйSourceCommit: oid)
        ])
        let сообщение = ВходящееСообщениеЖизненногоЦикла(
            messageID: "native-message-1", исходныеБайты: Data("исходное сообщение".utf8))
        let первыйЗапрос = try ЗапросСохраненияВходящегоСообщенияЖизненногоЦикла(
            дескриптор: д, рабочийСписок: список, сообщение: сообщение)
        let повторныйЗапрос = try ЗапросСохраненияВходящегоСообщенияЖизненногоЦикла(
            дескриптор: д, рабочийСписок: список, сообщение: сообщение)
        #expect(первыйЗапрос.operationID == повторныйЗапрос.operationID)
        #expect(первыйЗапрос.каноническиеБайты == повторныйЗапрос.каноническиеБайты)
        #expect(первыйЗапрос.sha256КаноническихБайтов == повторныйЗапрос.sha256КаноническихБайтов)

        let восстановление = try await список.вернутьСписокПослеСохранения(
            сообщение, дескриптор: д) { запрос in
                КвитанцияПереоткрытияВходящегоСообщения(
                    operationID: запрос.operationID,
                    sha256Запроса: запрос.sha256КаноническихБайтов,
                    байтыПовторногоЧтения: запрос.каноническиеБайты,
                    sha256ПовторногоЧтения: запрос.sha256КаноническихБайтов,
                    переоткрытыйРабочийСписок: список)
            }
        #expect(восстановление.operationID == первыйЗапрос.operationID)
        #expect(восстановление.следующийРазрешённыйШаг.id == "проверить")
    }

    @Test func несовпавшиеБайтыПовторногоЧтенияНеВозвращаютСписок() async throws {
        let д = дескриптор()
        let список = try списокДляРодителя(д)
        let сообщение = ВходящееСообщениеЖизненногоЦикла(
            messageID: "native-message-mismatch", исходныеБайты: Data("исходное".utf8))
        #expect(throws: ОшибкаЖизненногоЦикла.несовпадениеПовторногоЧтения) {
            try await список.вернутьСписокПослеСохранения(сообщение, дескриптор: д) { запрос in
                let прочитано = Data("другая запись".utf8)
                return КвитанцияПереоткрытияВходящегоСообщения(
                    operationID: запрос.operationID,
                    sha256Запроса: запрос.sha256КаноническихБайтов,
                    байтыПовторногоЧтения: прочитано,
                    sha256ПовторногоЧтения: хэшФикстуры(прочитано),
                    переоткрытыйРабочийСписок: список)
            }
        }
    }

    @Test func другаяOperationIDНеПринимаетКвитанциюПереоткрытия() async throws {
        let д = дескриптор()
        let список = try списокДляРодителя(д)
        let сообщение = ВходящееСообщениеЖизненногоЦикла(
            messageID: "native-message-operation-id", исходныеБайты: Data("исходное".utf8))
        #expect(throws: ОшибкаЖизненногоЦикла.несовпадениеOperationID) {
            try await список.вернутьСписокПослеСохранения(сообщение, дескриптор: д) { запрос in
                КвитанцияПереоткрытияВходящегоСообщения(
                    operationID: "другая-operation-id",
                    sha256Запроса: запрос.sha256КаноническихБайтов,
                    байтыПовторногоЧтения: запрос.каноническиеБайты,
                    sha256ПовторногоЧтения: запрос.sha256КаноническихБайтов,
                    переоткрытыйРабочийСписок: список)
            }
        }
    }

    @Test func тотЖеАдресНоДругиеШагиНеСвязываютсяСТочнымиБайтамиReadback() async throws {
        let д = дескриптор()
        let исходныйСписок = try списокДляРодителя(д)
        let изменённыйСписок = try СвойРабочийСписокУзла(дескриптор: д, шаги: [
            ШагЖизненногоЦикла(
                id: "другой-разрешённый-шаг", состояние: .разрешён, требуемыйSourceCommit: oid)
        ])
        let сообщение = ВходящееСообщениеЖизненногоЦикла(
            messageID: "native-message-changed-worklist", исходныеБайты: Data("исходное".utf8))
        #expect(throws: ОшибкаЖизненногоЦикла.несовпадениеРабочегоСпискаПереоткрытия) {
            try await исходныйСписок.вернутьСписокПослеСохранения(
                сообщение, дескриптор: д) { запрос in
                    КвитанцияПереоткрытияВходящегоСообщения(
                        operationID: запрос.operationID,
                        sha256Запроса: запрос.sha256КаноническихБайтов,
                        байтыПовторногоЧтения: запрос.каноническиеБайты,
                        sha256ПовторногоЧтения: запрос.sha256КаноническихБайтов,
                        переоткрытыйРабочийСписок: изменённыйСписок)
                }
        }
    }

    @Test func устаревшийПереоткрытыйСписокНеПринимается() async throws {
        let д = дескриптор()
        let устаревший = дескриптор(
            sourceCommit: String(repeating: "a", count: 40),
            sourceTree: String(repeating: "b", count: 40))
        let устаревшийСписок = try списокДляРодителя(устаревший)
        let исходныйСписок = try списокДляРодителя(д)
        let сообщение = ВходящееСообщениеЖизненногоЦикла(
            messageID: "native-message-stale", исходныеБайты: Data("исходное".utf8))
        #expect(throws: ОшибкаЖизненногоЦикла.другойSource) {
            try await исходныйСписок.вернутьСписокПослеСохранения(
                сообщение, дескриптор: д) { запрос in
                    КвитанцияПереоткрытияВходящегоСообщения(
                        operationID: запрос.operationID,
                        sha256Запроса: запрос.sha256КаноническихБайтов,
                        байтыПовторногоЧтения: запрос.каноническиеБайты,
                        sha256ПовторногоЧтения: запрос.sha256КаноническихБайтов,
                        переоткрытыйРабочийСписок: устаревшийСписок)
                }
        }
    }

    @Test func ошибкаПереоткрытияНеВозвращаетСписок() async throws {
        let д = дескриптор()
        let список = try списокДляРодителя(д)
        let сообщение = ВходящееСообщениеЖизненногоЦикла(
            messageID: "native-message-failed", исходныеБайты: Data("исходное".utf8))
        #expect(throws: ОшибкаФикстуры.переоткрытие) {
            try await список.вернутьСписокПослеСохранения(сообщение, дескриптор: д) { _ in
                throw ОшибкаФикстуры.переоткрытие
            }
        }
    }

    @Test(arguments: [СостояниеШагаЖизненногоЦикла.вОчереди, .ожидаетПредусловие])
    func queuedИPrerequisiteНеСтановятсяРазрешённымСледующимШагом(
        _ состояние: СостояниеШагаЖизненногоЦикла
    ) throws {
        let список = try СвойРабочийСписокУзла(дескриптор: дескриптор(), шаги: [
            ШагЖизненногоЦикла(id: "ожидать", состояние: состояние, требуемыйSourceCommit: oid)
        ])
        #expect(throws: ОшибкаЖизненногоЦикла.нетИзвестногоСледующегоШага) {
            try список.следующийШаг(после: nil)
        }
    }

    @Test func queuedPrerequisiteИUnknownНеЗавершаютChild() throws {
        let д = дескриптор()
        for статус in [СостояниеРезультатаДочернегоУзла.queued, .prerequisite, .running, .accepted] {
            let исход = свидетельство(д, статус: статус, известен: true)
            #expect(try ПереходЖизненногоЦикла.решитьРезультатРодителю(
                исход, дескриптор: д, рабочийСписок: списокДляРодителя(д)) == .ждатьНовогоНаблюдения)
        }
        let unknown = свидетельство(д, статус: .unknown, известен: false)
        #expect(try ПереходЖизненногоЦикла.решитьРезультатРодителю(
            unknown, дескриптор: д, рабочийСписок: списокДляРодителя(д)) == .наблюдатьUnknownБезПовтора)
        let completed = свидетельство(д, статус: .completed, известен: true)
        #expect(try ПереходЖизненногоЦикла.решитьРезультатРодителю(
            completed, дескриптор: д, рабочийСписок: списокДляРодителя(д)) ==
            .принятьИзвестныйРезультат(следующийШагID: "следующий-разрешённый"))
    }

    @Test func terminalНовогоSourceНеПродвигаетСтарыйWorklist() throws {
        let старый = дескриптор()
        let старыйСписок = try списокДляРодителя(старый)
        let новый = дескриптор(
            sourceCommit: String(repeating: "b", count: 40),
            sourceTree: String(repeating: "c", count: 40))
        let completed = свидетельство(новый, статус: .completed, известен: true)
        #expect(throws: ОшибкаЖизненногоЦикла.другойSource) {
            try ПереходЖизненногоЦикла.решитьРезультатРодителю(
                completed, дескриптор: новый, рабочийСписок: старыйСписок)
        }
    }

    @Test func terminalТекущегоSourceСтаройВерсииНеПринимается() throws {
        let д = дескриптор()
        let wrongVersion = СвидетельствоРезультатаДочернегоУзла(
            корневаяЗадачаUUID: д.корневаяЗадачаUUID, nativeChatUUID: д.nativeChatUUID,
            executionTurn: д.executionTurn, логическийУзел: д.логическийУзел,
            полныйRef: д.полныйRef, физическийWorktree: д.физическийWorktree,
            sourceCommit: д.текущееСостояние.sourceCommit,
            sourceTree: д.текущееСостояние.sourceTree, версияСостояния: 1,
            состояние: .completed, результатИзвестен: true)
        let список = try списокДляРодителя(д)
        #expect(throws: ОшибкаЖизненногоЦикла.другаяВерсияСостояния) {
            try ПереходЖизненногоЦикла.решитьРезультатРодителю(
                wrongVersion, дескриптор: д, рабочийСписок: список)
        }
    }

    private func списокДляРодителя(_ д: ДескрипторЖизненногоЦиклаУзла) throws -> СвойРабочийСписокУзла {
        try СвойРабочийСписокУзла(дескриптор: д, шаги: [
            ШагЖизненногоЦикла(
                id: "следующий-разрешённый", состояние: .разрешён,
                требуемыйSourceCommit: д.текущееСостояние.sourceCommit)
        ])
    }

    private func хэшФикстуры(_ данные: Data) -> String {
        // Test-only digest matches the SHA-256 representation used by the lifecycle API.
        return SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    private func свидетельство(
        _ д: ДескрипторЖизненногоЦиклаУзла,
        статус: СостояниеРезультатаДочернегоУзла, известен: Bool
    ) -> СвидетельствоРезультатаДочернегоУзла {
        СвидетельствоРезультатаДочернегоУзла(
            корневаяЗадачаUUID: д.корневаяЗадачаUUID, nativeChatUUID: д.nativeChatUUID,
            executionTurn: д.executionTurn, логическийУзел: д.логическийУзел,
            полныйRef: д.полныйRef, физическийWorktree: д.физическийWorktree,
            sourceCommit: д.текущееСостояние.sourceCommit,
            sourceTree: д.текущееСостояние.sourceTree,
            версияСостояния: д.текущееСостояние.версияСостояния,
            состояние: статус, результатИзвестен: известен)
    }
}
