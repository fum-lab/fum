// Включается только после отдельного допуска на Package.swift и target wiring.
#if FUM_LIFECYCLE_API_WIRED
import Testing
@testable import МатериализацияУзлов

@Suite struct ПроверкиЖизненногоЦиклаУзлов {
    private let корень = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
    private let oid = "16692490de749b661ec466f65a2b040700da1ea9"
    private let tree = "18db7a4f267d6966de417dc9a005ea6068e715cd"

    private func дескриптор(
        чат: String = "01a195e5-70bf-7a81-920f-d15df36fc90a",
        ход: String = "01a1972a-cafc-7c41-bdeb-bcd0117225b9",
        узел: String = "fum-lab/fum/instrumentyi/rantajm-agentov/zhiznennyj-cikl/master",
        ref: String = "refs/heads/fum-lab/fum/instrumentyi/rantajm-agentov/zhiznennyj-cikl/master",
        worktree: String = "/Users/fum/.codex/worktrees/zhiznennyj-cikl-01a195e5/FUM",
        checkpoint: КонтрольнаяТочкаЖизненногоЦикла? = nil
    ) -> ДескрипторЖизненногоЦиклаУзла {
        let состояние = СостояниеУзлаЖизненногоЦикла(
            корневаяЗадачаUUID: корень, nativeChatUUID: чат, executionTurn: ход,
            логическийУзел: узел, полныйRef: ref, физическийWorktree: worktree,
            sourceCommit: oid, sourceTree: tree, версияСостояния: 2)
        return ДескрипторЖизненногоЦиклаУзла(
            корневаяЗадачаUUID: корень, nativeChatUUID: чат, executionTurn: ход,
            логическийУзел: узел, полныйRef: ref, физическийWorktree: worktree,
            текущееСостояние: состояние, checkpoint: checkpoint,
            версияПроисхождения: "C166/1",
            границаПолномочий: ГраницаПолномочийЖизненногоЦикла(
                разрешённыеПути: ["iskhodniki/perekhod-vetok/uzlyi/**"]))
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
            логическийУзел: "fum-lab/fum/instrumentyi/rantajm-agentov/zhiznennyj-cikl/master",
            полныйRef: "refs/heads/fum-lab/fum/instrumentyi/rantajm-agentov/zhiznennyj-cikl/master",
            физическийWorktree: "/Users/fum/.codex/worktrees/zhiznennyj-cikl-01a195e5/FUM",
            sourceCommit: oid, sourceTree: tree, версияСостояния: 1,
            завершённыйШагID: "сохранить-дескриптор", следующийРазрешённыйШагID: "сверить-приём"))
        let список = try СвойРабочийСписокУзла(дескриптор: д, шаги: [
            ШагЖизненногоЦикла(id: "сохранить-дескриптор", состояние: .завершён, требуемыйSourceCommit: oid),
            ШагЖизненногоЦикла(id: "сверить-приём", состояние: .разрешён, требуемыйSourceCommit: oid),
            ШагЖизненногоЦикла(id: "доставить", состояние: .разрешён, требуемыйSourceCommit: oid)
        ])
        #expect(try список.следующийШаг(после: д.checkpoint).id == "сверить-приём")
    }

    @Test func сохранённоеСообщениеВозвращаетТолькоСобственныйСписок() throws {
        let д = дескриптор()
        let список = try СвойРабочийСписокУзла(дескриптор: д, шаги: [
            ШагЖизненногоЦикла(id: "проверить", состояние: .разрешён, требуемыйSourceCommit: oid)
        ])
        let получено = СохраненноеВходящееСообщениеЖизненногоЦикла(
            корневаяЗадачаUUID: д.корневаяЗадачаUUID,
            nativeChatUUID: д.nativeChatUUID, executionTurn: д.executionTurn,
            логическийУзел: д.логическийУзел, полныйRef: д.полныйRef,
            физическийWorktree: д.физическийWorktree, sourceCommit: oid,
            sourceTree: tree,
            версияСостояния: д.текущееСостояние.версияСостояния,
            messageID: "message-1", состояние: .получено)
        #expect(throws: ОшибкаЖизненногоЦикла.идентичность) {
            try список.вернутьСписокПослеСохранения(получено)
        }
        let сохранено = СохраненноеВходящееСообщениеЖизненногоЦикла(
            корневаяЗадачаUUID: д.корневаяЗадачаUUID,
            nativeChatUUID: д.nativeChatUUID, executionTurn: д.executionTurn,
            логическийУзел: д.логическийУзел, полныйRef: д.полныйRef,
            физическийWorktree: д.физическийWorktree, sourceCommit: oid,
            sourceTree: tree,
            версияСостояния: д.текущееСостояние.версияСостояния,
            messageID: "message-1", состояние: .сохранено)
        #expect(try список.вернутьСписокПослеСохранения(сохранено) == список.шаги)
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

    private func списокДляРодителя(_ д: ДескрипторЖизненногоЦиклаУзла) throws -> СвойРабочийСписокУзла {
        try СвойРабочийСписокУзла(дескриптор: д, шаги: [
            ШагЖизненногоЦикла(id: "следующий-разрешённый", состояние: .разрешён, требуемыйSourceCommit: oid)
        ])
    }

    private func свидетельство(
        _ д: ДескрипторЖизненногоЦиклаУзла,
        статус: СостояниеРезультатаДочернегоУзла, известен: Bool
    ) -> СвидетельствоРезультатаДочернегоУзла {
        СвидетельствоРезультатаДочернегоУзла(
            корневаяЗадачаUUID: д.корневаяЗадачаUUID, nativeChatUUID: д.nativeChatUUID,
            executionTurn: д.executionTurn, логическийУзел: д.логическийУзел,
            полныйRef: д.полныйRef, физическийWorktree: д.физическийWorktree,
            sourceCommit: oid, sourceTree: tree, версияСостояния: 2,
            состояние: статус, результатИзвестен: известен)
    }
}
#endif
