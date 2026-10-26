import Foundation
import КонтейнерНаблюдений
import FUMStructuringOperatorMemory

public enum ОшибкаСвязиКвитанцииМодели: Error, Equatable, Sendable {
    case данныеПревышаютПредел
    case размерНеСовпадает
    case неверныйФорматХэша
    case хэшНеСовпадает
    case статусНеГипотеза
}

public enum СвязьКвитанцииМодели {
    private static let пределДанных = 262_144

    public static func декодировать(
        квитанция: Квитанция,
        данные: Data
    ) throws -> RecordedLLMEnvelope {
        guard данные.count <= пределДанных else {
            throw ОшибкаСвязиКвитанцииМодели.данныеПревышаютПредел
        }
        guard квитанция.размер == UInt64(данные.count) else {
            throw ОшибкаСвязиКвитанцииМодели.размерНеСовпадает
        }
        guard форматСырогоХэшаДопустим(квитанция.хэш) else {
            throw ОшибкаСвязиКвитанцииМодели.неверныйФорматХэша
        }

        let сыройХэш = String(sha256Digest(данные).dropFirst("sha256:".count))
        guard квитанция.хэш == сыройХэш else {
            throw ОшибкаСвязиКвитанцииМодели.хэшНеСовпадает
        }

        let конверт = try RecordedLLMProposalAdapter.decode(data: данные)
        guard конверт.proposals.allSatisfy({ $0.status == .hypothesis }) else {
            throw ОшибкаСвязиКвитанцииМодели.статусНеГипотеза
        }
        return конверт
    }

    private static func форматСырогоХэшаДопустим(_ хэш: String) -> Bool {
        let байты = Array(хэш.utf8)
        guard байты.count == 64 else { return false }
        return байты.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }
}
