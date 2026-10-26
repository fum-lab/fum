import Foundation

public struct ОтветГенератораМанифеста: Sendable {
    public let манифест: Data
    public let описание: Data
    public let разница: String
    public let хэшПрежнегоМанифеста: String
    public let хэшНовогоМанифеста: String
    public let хэшКарты: String?
}

public struct ОтказГенератораМанифеста: Error, Equatable, Sendable, CustomStringConvertible {
    public let код: String
    public var description: String { код }
}

public enum ФасадГенератораМанифеста {
    public static func породить(описание: Data, корень: URL, прежний: Data = Data(),
                               карта: Data? = nil, хэшКарты: String? = nil)
        -> Result<ОтветГенератораМанифеста, ОтказГенератораМанифеста> {
        do {
            let модель = try ОписаниеПакета.прочитать(описание)
            let результат = try ГенераторМанифеста.породить(модель, корень: корень,
                прежний: прежний, карта: карта, хэшКарты: хэшКарты)
            return .success(.init(манифест: результат.байты, описание: try результат.описание.байты(),
                разница: результат.текстРазницы, хэшПрежнегоМанифеста: результат.хэшПрежнегоМанифеста,
                хэшНовогоМанифеста: результат.хэшНовогоМанифеста, хэшКарты: результат.хэшИспользованнойКарты))
        } catch {
            return .failure(.init(код: (error as? ОшибкаМанифеста)?.код ?? "неверный-или-недоступный-вход"))
        }
    }
}
