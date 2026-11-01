import Foundation

/// Переданные байты и режим одного узла. Происхождение и полнота снимка внешние.
public struct УзелСнимкаВосстановленияFUMA: Equatable, Sendable {
    public let путь: Data
    public let режим: String
    public let байты: Data

    public init(путь: Data, режим: String, байты: Data) {
        self.путь = путь
        self.режим = режим
        self.байты = байты
    }
}

/// Снимок содержит полный сырой индекс и переданную область узлов.
public struct СнимокВосстановленияFUMA: Equatable, Sendable {
    public let head: String
    public let ref: String
    public let индекс: Data
    public let узлы: [УзелСнимкаВосстановленияFUMA]

    public init(head: String, ref: String, индекс: Data, узлы: [УзелСнимкаВосстановленияFUMA]) {
        self.head = head
        self.ref = ref
        self.индекс = индекс
        self.узлы = узлы
    }
}

public struct ШагВосстановленияFUMA: Equatable, Sendable {
    public let идентификатор: String
    public let до: СнимокВосстановленияFUMA
    public let после: СнимокВосстановленияFUMA

    public init(идентификатор: String, до: СнимокВосстановленияFUMA, после: СнимокВосстановленияFUMA) {
        self.идентификатор = идентификатор
        self.до = до
        self.после = после
    }
}

public enum РешениеВосстановленияFUMA: Equatable, Sendable {
    case неверныеДанные
    case неизвестныйИсход
    case дрейф
    case совпадениеПереданныхДанных(завершеноШагов: Int, всегоШагов: Int)
}

/// Сравнивает только данные; не запускает и не разрешает применение или откат.
/// Intent без receipt всегда остаётся неизвестным даже при совпадении снимка.
public enum СверкаВосстановленияFUMA {
    public static func проверить(
        шаги: [ШагВосстановленияFUMA],
        квитанции: [String],
        намерениеБезКвитанции: String?,
        наблюдение: СнимокВосстановленияFUMA
    ) -> РешениеВосстановленияFUMA {
        guard !шаги.isEmpty, квитанции.count <= шаги.count,
              допустим(наблюдение) else { return .неверныеДанные }
        var имена: Set<String> = []
        for (номер, шаг) in шаги.enumerated() {
            guard !шаг.идентификатор.isEmpty, имена.insert(шаг.идентификатор).inserted,
                  допустим(шаг.до), допустим(шаг.после),
                  шаг.до.head == шаг.после.head, шаг.до.ref == шаг.после.ref,
                  номер == 0 || шаги[номер - 1].после == шаг.до else {
                return .неверныеДанные
            }
        }
        guard Array(шаги.prefix(квитанции.count).map(\.идентификатор)) == квитанции else {
            return .неверныеДанные
        }
        if let намерение = намерениеБезКвитанции {
            guard квитанции.count < шаги.count,
                  намерение == шаги[квитанции.count].идентификатор else { return .неверныеДанные }
            return .неизвестныйИсход
        }
        let ожидаемый = квитанции.isEmpty ? шаги[0].до : шаги[квитанции.count - 1].после
        guard наблюдение == ожидаемый else { return .дрейф }
        return .совпадениеПереданныхДанных(завершеноШагов: квитанции.count, всегоШагов: шаги.count)
    }

    private static func допустим(_ снимок: СнимокВосстановленияFUMA) -> Bool {
        guard !снимок.head.isEmpty, !снимок.ref.isEmpty else { return false }
        var пути: Set<Data> = []
        for узел in снимок.узлы {
            guard !узел.путь.isEmpty, !узел.путь.contains(0),
                  !узел.режим.isEmpty, пути.insert(узел.путь).inserted else { return false }
        }
        return true
    }
}
