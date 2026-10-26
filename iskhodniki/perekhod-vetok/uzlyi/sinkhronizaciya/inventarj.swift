import CryptoKit
import Foundation
import FUMStructuringOperatorMemory

public struct ИсточникСинхронизации: Codable, Equatable, Sendable {
    public let коммит: String
    public let дерево: String
    public let путь: String
    public let blob: String
    public let sha256: String

    public init(коммит: String, дерево: String, путь: String, blob: String, sha256: String) {
        self.коммит = коммит
        self.дерево = дерево
        self.путь = путь
        self.blob = blob
        self.sha256 = sha256
    }
}

public enum ВидПути: String, Codable, Equatable, Sendable {
    case файл
    case каталог
}

public struct ОтображениеИмен: Codable, Equatable, Sendable {
    public let исходный: String
    public let целевой: String
    public let вид: ВидПути

    public init(исходный: String, целевой: String, вид: ВидПути) {
        self.исходный = исходный
        self.целевой = целевой
        self.вид = вид
    }
}

public struct КартаИменСинхронизации: Codable, Equatable, Sendable {
    public let схема: String
    public let ревизия: String
    public let источник: ИсточникСинхронизации
    public var карта: [ОтображениеИмен]

    public init(
        схема: String, ревизия: String, источник: ИсточникСинхронизации,
        карта: [ОтображениеИмен]
    ) {
        self.схема = схема
        self.ревизия = ревизия
        self.источник = источник
        self.карта = карта
    }
}

public enum ПолучениеACKСинхронизации: String, Codable, Equatable, Sendable {
    case получен
    case неизвестно
    case отклонён
}

public enum ПрименениеСинхронизации: String, Codable, Equatable, Sendable {
    case применено
    case неПрименено
    case неизвестно
}

public struct ПожеланиеАгентаСинхронизации: Codable, Equatable, Sendable {
    public let владелецЗадачи: String?
    public let владелецRef: String
    public let желаемыйРезультат: String
    public let выбранныйИсточник: ИсточникСинхронизации?
    public let получениеACK: ПолучениеACKСинхронизации
    public let применение: ПрименениеСинхронизации
    public let свидетельствоПрименения: String
    public let критерийВозвратаВнимания: String

    public init(
        владелецЗадачи: String?, владелецRef: String, желаемыйРезультат: String,
        выбранныйИсточник: ИсточникСинхронизации?, получениеACK: ПолучениеACKСинхронизации,
        применение: ПрименениеСинхронизации, свидетельствоПрименения: String,
        критерийВозвратаВнимания: String
    ) {
        self.владелецЗадачи = владелецЗадачи
        self.владелецRef = владелецRef
        self.желаемыйРезультат = желаемыйРезультат
        self.выбранныйИсточник = выбранныйИсточник
        self.получениеACK = получениеACK
        self.применение = применение
        self.свидетельствоПрименения = свидетельствоПрименения
        self.критерийВозвратаВнимания = критерийВозвратаВнимания
    }
}

public enum СостояниеИнвентаря: String, Codable, Equatable, Sendable {
    case чистое
    case грязное
    case чужое
    case активное
    case остановлено
    case приостановлено
    case неизвестно
    case дрейф
}

public enum РольИнвентаря: String, Codable, Equatable, Sendable {
    case ответственность
    case записьЖурнала
    case материал
    case проекция
    case техническийАртефакт
}

public struct УзелИнвентаря: Codable, Equatable, Sendable {
    public var логическийАдрес: String
    public var ответственность: String
    public var роль: РольИнвентаря
    public var задача: String?
    public var владелец: String?
    public var имяЧата: String?
    public var threadID: String?
    public var каталог: String
    public var файл: String
    public var ref: String?
    public var рабочееДеревоSHA256: String?
    public var коммит: String?
    public var дерево: String?
    public var remoteOID: String?
    public var желаемоеИмяЧата: String?
    public var состояние: СостояниеИнвентаря
    public var источники: [ИсточникСинхронизации]

    public init(
        логическийАдрес: String, ответственность: String, роль: РольИнвентаря,
        задача: String?, владелец: String?, имяЧата: String?, threadID: String?,
        каталог: String, файл: String, ref: String?, рабочееДеревоSHA256: String?,
        коммит: String?, дерево: String?, remoteOID: String?, желаемоеИмяЧата: String?,
        состояние: СостояниеИнвентаря, источники: [ИсточникСинхронизации]
    ) {
        self.логическийАдрес = логическийАдрес
        self.ответственность = ответственность
        self.роль = роль
        self.задача = задача
        self.владелец = владелец
        self.имяЧата = имяЧата
        self.threadID = threadID
        self.каталог = каталог
        self.файл = файл
        self.ref = ref
        self.рабочееДеревоSHA256 = рабочееДеревоSHA256
        self.коммит = коммит
        self.дерево = дерево
        self.remoteOID = remoteOID
        self.желаемоеИмяЧата = желаемоеИмяЧата
        self.состояние = состояние
        self.источники = источники
    }
}

public struct НаблюдениеRef: Codable, Equatable, Sendable {
    public let ref: String
    public let oid: String
    public let роль: String
    public let владелец: String

    public init(ref: String, oid: String, роль: String, владелец: String) {
        self.ref = ref
        self.oid = oid
        self.роль = роль
        self.владелец = владелец
    }
}

public struct НаблюдениеРабочегоДерева: Codable, Equatable, Sendable {
    public let fingerprintSHA256: String
    public let владелец: String
    public let ref: String
    public let состояние: СостояниеИнвентаря

    public init(
        fingerprintSHA256: String, владелец: String, ref: String,
        состояние: СостояниеИнвентаря
    ) {
        self.fingerprintSHA256 = fingerprintSHA256
        self.владелец = владелец
        self.ref = ref
        self.состояние = состояние
    }
}

public struct СнимокGitСинхронизации: Codable, Equatable, Sendable {
    public var корневаяЗадача: String
    public var писатель: String
    public var исходныйКоммит: String
    public var исходноеДерево: String
    public var ref: String
    public var head: String
    public var дерево: String
    public var индексSHA256: String
    public var рабочееДеревоSHA256: String
    public var состояние: СостояниеИнвентаря
    public var остановка: Bool
    public var пауза: Bool
    public var активность: Bool
    public var ожидаемыйRef: String
    public var ожидаемыйHead: String
    public var ожидаемоеДерево: String
    public var наблюдаемыеПути: [String]

    public init(
        корневаяЗадача: String, писатель: String, исходныйКоммит: String,
        исходноеДерево: String, ref: String, head: String, дерево: String,
        индексSHA256: String, рабочееДеревоSHA256: String,
        состояние: СостояниеИнвентаря, остановка: Bool, пауза: Bool, активность: Bool,
        ожидаемыйRef: String, ожидаемыйHead: String, ожидаемоеДерево: String,
        наблюдаемыеПути: [String]
    ) {
        self.корневаяЗадача = корневаяЗадача
        self.писатель = писатель
        self.исходныйКоммит = исходныйКоммит
        self.исходноеДерево = исходноеДерево
        self.ref = ref
        self.head = head
        self.дерево = дерево
        self.индексSHA256 = индексSHA256
        self.рабочееДеревоSHA256 = рабочееДеревоSHA256
        self.состояние = состояние
        self.остановка = остановка
        self.пауза = пауза
        self.активность = активность
        self.ожидаемыйRef = ожидаемыйRef
        self.ожидаемыйHead = ожидаемыйHead
        self.ожидаемоеДерево = ожидаемоеДерево
        self.наблюдаемыеПути = наблюдаемыеПути
    }
}

public struct ПакетныйИнвентарьСинхронизации: Codable, Equatable, Sendable {
    public var снимок: СнимокGitСинхронизации
    public var refs: [НаблюдениеRef]
    public var рабочиеДеревья: [НаблюдениеРабочегоДерева]
    public var узлы: [УзелИнвентаря]
    public var картаИмен: КартаИменСинхронизации
    public var пожелания: [ПожеланиеАгентаСинхронизации]

    public init(
        снимок: СнимокGitСинхронизации, refs: [НаблюдениеRef],
        рабочиеДеревья: [НаблюдениеРабочегоДерева], узлы: [УзелИнвентаря],
        картаИмен: КартаИменСинхронизации,
        пожелания: [ПожеланиеАгентаСинхронизации]
    ) {
        self.снимок = снимок
        self.refs = refs
        self.рабочиеДеревья = рабочиеДеревья
        self.узлы = узлы
        self.картаИмен = картаИмен
        self.пожелания = пожелания
    }
}

public enum ОшибкаИнвентаря: Error, Equatable, Sendable {
    case снимок
    case источник
    case путь
    case коллизия
    case повтор
    case предел
}

public enum ВалидаторИнвентаря {
    private static let источникКарты = ИсточникСинхронизации(
        коммит: "84976661fba027ab43fdd5901c5bb0b5e01cd6dd",
        дерево: "069b2ddf36e9f39781ba682b3881d0f0f435ac13",
        путь: "iskhodniki/perekhod-vetok/karta-imyon-sinkhronizacii.json",
        blob: "e51deaacfc8ce5c77556fb86d8d7efb4455fb17a",
        sha256: "d2d9f32feb5054bcc27cff86fdf5bf79504a46cfa85473ed577f536dcdca9585")

    private static let разрешённыеПереходы: Set<String> = [
        "iskhodniki/perekhod-vetok/uzlyi/синхронизация/инвентарь.swift\u{0}iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/inventarj.swift\u{0}файл",
        "iskhodniki/perekhod-vetok/uzlyi/синхронизация/план.swift\u{0}iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/plan.swift\u{0}файл",
        "iskhodniki/perekhod-vetok/uzlyi/синхронизация/адаптер.swift\u{0}iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/adapter.swift\u{0}файл",
        "iskhodniki/perekhod-vetok/proverki/синхронизация/проверки.swift\u{0}iskhodniki/perekhod-vetok/proverki/sinkhronizaciya/proverki.swift\u{0}файл",
        "iskhodniki/perekhod-vetok/proverki/синхронизация/профиль.swift\u{0}iskhodniki/perekhod-vetok/proverki/sinkhronizaciya/profilj.swift\u{0}файл",
        "iskhodniki/perekhod-vetok/zhurnal/синхронизация\u{0}iskhodniki/perekhod-vetok/zhurnal/sinkhronizaciya\u{0}каталог",
    ]

    private static let определениеНормализации = ОпределениеОператора(
        идентификатор: "fum.ключ-сравнения-пути",
        версия: 1,
        шаги: [
            ШагОператора(идентификатор: "края", действие: .обрезать),
            ШагОператора(идентификатор: "регистр", действие: .нижнийРегистр),
            ШагОператора(идентификатор: "пробелы", действие: .сжатьПробелы),
        ])

    public static func проверить(_ inventory: ПакетныйИнвентарьСинхронизации) throws {
        guard inventory.refs.count <= 8_192,
              inventory.рабочиеДеревья.count <= 4_096,
              inventory.узлы.count <= 4_096,
              inventory.пожелания.count <= 4_096,
              inventory.снимок.наблюдаемыеПути.count <= 4_096
        else { throw ОшибкаИнвентаря.предел }

        guard UUID(uuidString: inventory.снимок.корневаяЗадача)?.uuidString.lowercased()
                == inventory.снимок.корневаяЗадача,
              UUID(uuidString: inventory.снимок.писатель)?.uuidString.lowercased()
                == inventory.снимок.писатель,
              валидныйOID(inventory.снимок.исходныйКоммит),
              валидныйOID(inventory.снимок.исходноеДерево),
              валидныйOID(inventory.снимок.head),
              валидныйOID(inventory.снимок.дерево),
              валидныйOID(inventory.снимок.ожидаемыйHead),
              валидныйOID(inventory.снимок.ожидаемоеДерево),
              валидныйSHA(inventory.снимок.индексSHA256),
              валидныйSHA(inventory.снимок.рабочееДеревоSHA256),
              валидныйRef(inventory.снимок.ref),
              inventory.снимок.ref == inventory.снимок.ожидаемыйRef,
              inventory.снимок.head == inventory.снимок.ожидаемыйHead,
              inventory.снимок.дерево == inventory.снимок.ожидаемоеДерево,
              inventory.снимок.исходныйКоммит == inventory.снимок.ожидаемыйHead,
              inventory.снимок.исходноеДерево == inventory.снимок.ожидаемоеДерево,
              !inventory.снимок.наблюдаемыеПути.contains(where: { путьОтносителен($0) == false })
        else { throw ОшибкаИнвентаря.снимок }

        guard inventory.картаИмен.схема == "fum.карта-имён-среза-материализации.1",
              inventory.картаИмен.ревизия == "837e2ce107b97ee7b9d3344c9fe99142281fe393",
              inventory.картаИмен.источник == источникКарты
        else { throw ОшибкаИнвентаря.источник }

        try проверитьКоллизии(inventory.картаИмен.карта)

        let выбранные = inventory.картаИмен.карта.filter(вОбласти)
        let ключи = Set(выбранные.map(ключПерехода))
        guard ключи == разрешённыеПереходы, выбранные.count == разрешённыеПереходы.count
        else { throw ОшибкаИнвентаря.источник }

        guard inventory.refs.allSatisfy({
            валидныйRef($0.ref) && валидныйOID($0.oid)
                && каноническийUUID($0.владелец) && !$0.роль.isEmpty
        }),
        inventory.рабочиеДеревья.allSatisfy({
            валидныйSHA($0.fingerprintSHA256) && валидныйRef($0.ref)
                && каноническийUUID($0.владелец)
        }) else { throw ОшибкаИнвентаря.снимок }

        guard inventory.refs.contains(where: {
            $0.ref == inventory.снимок.ref && $0.oid == inventory.снимок.head
                && $0.владелец == inventory.снимок.писатель && $0.роль == "responsibility"
        }),
        inventory.рабочиеДеревья.contains(where: {
            $0.fingerprintSHA256 == inventory.снимок.рабочееДеревоSHA256
                && $0.владелец == inventory.снимок.писатель
                && $0.ref == inventory.снимок.ref
                && $0.состояние == inventory.снимок.состояние
        }) else { throw ОшибкаИнвентаря.снимок }

        let responsibilityNodes = inventory.узлы.filter { $0.роль == .ответственность }
        var nodeIdentities: Set<String> = []
        for node in inventory.узлы {
            guard !node.логическийАдрес.isEmpty, node.логическийАдрес.utf8.count <= 1_024,
                  !node.ответственность.isEmpty, node.ответственность.utf8.count <= 2_048,
                  безопасныйТекст(node.логическийАдрес), безопасныйТекст(node.ответственность),
                  node.имяЧата.map(безопасныйТекст) ?? true,
                  node.желаемоеИмяЧата.map(безопасныйТекст) ?? true,
                  путьОтносителен(node.каталог), путьОтносителен(node.файл),
                  !node.файл.contains("/")
            else { throw ОшибкаИнвентаря.путь }

            if node.роль == .ответственность {
                guard let task = node.задача, каноническийUUID(task),
                      let owner = node.владелец, каноническийUUID(owner),
                      let ref = node.ref, валидныйRef(ref),
                      let fingerprint = node.рабочееДеревоSHA256, валидныйSHA(fingerprint),
                      let commit = node.коммит, валидныйOID(commit),
                      let tree = node.дерево, валидныйOID(tree),
                      node.remoteOID.map(валидныйOID) ?? true,
                      node.источники.allSatisfy(валидныйИсточник)
                else { throw ОшибкаИнвентаря.снимок }
                let identity = [node.логическийАдрес, node.роль.rawValue, owner, ref, task,
                                node.threadID ?? ""].joined(separator: "\u{0}")
                guard nodeIdentities.insert(identity).inserted,
                      inventory.refs.contains(where: {
                          $0.ref == ref && $0.oid == commit && $0.владелец == owner
                      }),
                      inventory.рабочиеДеревья.contains(where: {
                          $0.fingerprintSHA256 == fingerprint && $0.владелец == owner && $0.ref == ref
                      })
                else { throw ОшибкаИнвентаря.снимок }
                if node.желаемоеИмяЧата != nil {
                    guard let threadID = node.threadID, каноническийUUID(threadID),
                          let desired = node.желаемоеИмяЧата, !desired.isEmpty
                    else { throw ОшибкаИнвентаря.снимок }
                }
            }
        }
        guard Set(responsibilityNodes.map(\.логическийАдрес)).count == responsibilityNodes.count
        else { throw ОшибкаИнвентаря.повтор }

        for wish in inventory.пожелания {
            guard валидныйRef(wish.владелецRef),
                  !wish.желаемыйРезультат.isEmpty, wish.желаемыйРезультат.utf8.count <= 2_048,
                  безопасныйТекст(wish.желаемыйРезультат),
                  !wish.свидетельствоПрименения.isEmpty, wish.свидетельствоПрименения.utf8.count <= 4_096,
                  безопасныйТекст(wish.свидетельствоПрименения),
                  !wish.критерийВозвратаВнимания.isEmpty, wish.критерийВозвратаВнимания.utf8.count <= 4_096,
                  безопасныйТекст(wish.критерийВозвратаВнимания),
                  wish.владелецЗадачи.map(каноническийUUID) ?? true,
                  wish.выбранныйИсточник.map(валидныйИсточник) ?? true
            else { throw ОшибкаИнвентаря.источник }
        }
    }

    static func нормализованныйКлюч(_ path: String) throws -> String {
        guard путьОтносителен(path) else { throw ОшибкаИнвентаря.путь }
        do {
            let observation = try AutomationExecutor.выполнить(
                определениеНормализации, вход: .текст(path))
            guard case .текст(let value) = observation.результат else {
                throw ОшибкаИнвентаря.источник
            }
            return value.precomposedStringWithCanonicalMapping
        } catch let error as ОшибкаИнвентаря {
            throw error
        } catch {
            throw ОшибкаИнвентаря.источник
        }
    }

    static func валидныйИсточник(_ source: ИсточникСинхронизации) -> Bool {
        валидныйOID(source.коммит) && валидныйOID(source.дерево)
            && путьОтносителен(source.путь) && валидныйOID(source.blob)
            && валидныйSHA(source.sha256)
    }

    private static func проверитьКоллизии(_ map: [ОтображениеИмен]) throws {
        guard map.count <= 512 else { throw ОшибкаИнвентаря.предел }
        var источники: Set<String> = []
        var цели: [String: ВидПути] = [:]
        for row in map {
            let source = try нормализованныйКлюч(row.исходный)
            let target = try нормализованныйКлюч(row.целевой)
            guard источники.insert(source).inserted, цели[target] == nil else {
                throw ОшибкаИнвентаря.коллизия
            }
            цели[target] = row.вид
        }
        for (path, kind) in цели where kind == .файл {
            if цели.keys.contains(where: { $0.hasPrefix(path + "/") }) {
                throw ОшибкаИнвентаря.коллизия
            }
        }
    }

    private static func вОбласти(_ row: ОтображениеИмен) -> Bool {
        let target = row.целевой
        return target.hasPrefix("iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya/")
            || target.hasPrefix("iskhodniki/perekhod-vetok/proverki/sinkhronizaciya/")
            || target == "iskhodniki/perekhod-vetok/zhurnal/sinkhronizaciya"
    }

    private static func ключПерехода(_ row: ОтображениеИмен) -> String {
        "\(row.исходный)\u{0}\(row.целевой)\u{0}\(row.вид.rawValue)"
    }

    private static func путьОтносителен(_ path: String) -> Bool {
        guard !path.isEmpty, !path.hasPrefix("/"), !path.hasPrefix("~"),
              path.utf8.count <= 1_024,
              !path.contains("\\"), !path.contains("//"),
              !path.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
        else { return false }
        return path.split(separator: "/", omittingEmptySubsequences: false)
            .allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    }

    private static func валидныйOID(_ value: String) -> Bool {
        value.utf8.count == 40 && value.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private static func валидныйSHA(_ value: String) -> Bool {
        value.utf8.count == 64 && value.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private static func валидныйRef(_ value: String) -> Bool {
        value.hasPrefix("refs/heads/") && путьОтносителен(value)
    }

    private static func каноническийUUID(_ value: String) -> Bool {
        UUID(uuidString: value)?.uuidString.lowercased() == value
    }

    private static func безопасныйТекст(_ value: String) -> Bool {
        let lower = value.lowercased()
        guard !lower.contains("file://"), !value.contains("\\\\") else { return false }
        let bytes = Array(value.utf8)
        let delimiters: Set<UInt8> = [9, 10, 13, 32, 34, 39, 40, 44, 58, 59, 60, 61, 91, 123]
        for index in bytes.indices {
            if bytes[index] == 47, index + 1 < bytes.count, bytes[index + 1] != 47,
               index == 0 || delimiters.contains(bytes[index - 1]) {
                return false
            }
            if bytes[index] == 126, index + 1 < bytes.count,
               bytes[index + 1] == 47 || bytes[index + 1] == 92 {
                return false
            }
            if index + 2 < bytes.count,
               ((65...90).contains(bytes[index]) || (97...122).contains(bytes[index])),
               bytes[index + 1] == 58, bytes[index + 2] == 47 || bytes[index + 2] == 92 {
                return false
            }
        }
        return true
    }
}
