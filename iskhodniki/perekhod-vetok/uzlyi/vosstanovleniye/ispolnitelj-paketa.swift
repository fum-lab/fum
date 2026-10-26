import CryptoKit
import Darwin
import Dispatch
import Foundation
import FUMStructuringOperatorMemory

public enum РазрешённыйЖурналПакета: String, Codable, Equatable, Sendable {
    case localFUMA = "local_fuma"
}

private let ожидаемыеПутиИсходниковИсполнителя: Set<String> = [
    "iskhodniki/perekhod-vetok/uzlyi/vosstanovleniye/ispolnitelj-paketa.swift",
    "iskhodniki/perekhod-vetok/proverki/vosstanovleniye/proverki-ispolnitelya-paketa.swift"
]

private let ожидаемыеПутиРесурсовDriver: Set<String> = [
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Info.plist",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Resources/Определения/UTF-8-в-UTF-32LE.json",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Resources/Определения/нормализация.json",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Resources/Фикстуры/malformed-llm-envelope.json",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/Resources/Фикстуры/scenarios.json",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/_CodeSignature/CodeDirectory",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/_CodeSignature/CodeRequirements",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/_CodeSignature/CodeResources",
    "FUMA_FUMStructuringOperatorMemory.bundle/Contents/_CodeSignature/CodeSignature",
    "FUMA_ЖурналУзла.bundle/Contents/Info.plist",
    "FUMA_ЖурналУзла.bundle/Contents/Resources/opredeleniya/sformirovatj-zapisj.json",
    "FUMA_ЖурналУзла.bundle/Contents/_CodeSignature/CodeDirectory",
    "FUMA_ЖурналУзла.bundle/Contents/_CodeSignature/CodeRequirements",
    "FUMA_ЖурналУзла.bundle/Contents/_CodeSignature/CodeResources",
    "FUMA_ЖурналУзла.bundle/Contents/_CodeSignature/CodeSignature"
]

public struct ЗакреплениеИсходникаИсполнителяПакета: Codable, Equatable, Sendable {
    public let путь: String
    public let sha256: String

    public init(путь: String, sha256: String) {
        self.путь = путь
        self.sha256 = sha256
    }
}

enum ИсправленныйДопускИсполнителяПакетаV2 {
    static let версия = 2
    static let корневойUUID = "01a07d3d-d376-7ad2-aafc-67e4c25a67eb"
    static let uuidИсполнителя = "01a177a3-cb11-75d1-adc8-8aa71d0b3aeb"
    static let ref =
        "refs/heads/fum-lab/fum/instrumentyi/perekhod-vetok/vosstanovleniye/master"
    static let базовыйOID = "9909c19aade5820e41798d155f9c30978b48453d"
    static let область = "iskhodniki/perekhod-vetok/zhurnal/vosstanovleniye"

    static let коммитПостановки = "98565deb72e2d4b7e3e157452233d631412233a6"
    static let деревоПостановки = "e5e1d0e3af4354a8870cb1773cbf5c8cba753ff6"
    static let родительПостановки = "6b7c72d21899874a6ab48d85250ae1e698eb8da8"
    static let путьПостановки =
        "iskhodniki/perekhod-vetok/postanovka-ispolnitelya-paketa.json"
    static let blobПостановки = "1b201bccf1bdf7935e69f61f14c6f80067f714e7"
    static let sha256Постановки =
        "65452f21be9b4cb1eb58fcd343861925ba8add8eb1ce5600dbb9641dcd19cd23"

    static let sha256Пакета =
        "7fd6657c9b901d9173eb2bdadfb1ba4e9e6b7f8d521894389de3af9bc4633ad0"
    static let байтовПакета = 4_702
    static let sha256Driver =
        "689ee574ec9340fe283b4163920cefca5de6fcf869b9f4912557a1d2d544005b"
    static let байтовDriver = 4_127_264

    static let коммитИсточника = "c6af44bf1ec061675b6205b9c6ee889d98264f28"
    static let деревоИсточника = "8931d2f63231534c142cd17b39d1599e20c55992"
    static let путьЗакреплений = "zhurnal/384-build.nachalo.json"
    static let blobЗакреплений = "9960fadfa82c8edbe99ca33b06ea3a6185f9be29"
    static let sha256ФайлаЗакреплений =
        "48a3f233fa2b9e4ed0ebe96e484c222d0747ace655e78787d177fa5badd954ce"
    static let числоЗакреплений = 34
    static let путьРезультатаСборки = "zhurnal/384-build.iskhod.json"
    static let исходнаяКартаSHA256 =
        "3c75c0e8d7880878f46c9c00978535a0240b680e84f8bda65169e095e0b6f3b1"

    static let коммитТекущейКарты = "9909c19aade5820e41798d155f9c30978b48453d"
    static let деревоТекущейКарты = "0cbd2769919fe4c7d94d0951f0fd25496cc7be46"
    static let текущаяКартаSHA256 =
        "d511f6fb4aa80dbd16b1b7cba65371a2712e2a35f5dd3a5e65aa1c7fd50ee489"
    static let основаниеТекущихОтличий =
        "коррекция-допуска-v2:source=c6af44bf;target=9909c19a;delta=Package.swift"
    static let исходныйPackageSHA256 =
        "6e19bbcfeb25f5e2b855f5c06892b6ada2ed29dc32fdaf807f6017103fe51cd3"
    static let текущийPackageSHA256 =
        "b07f4ed9de8cc794f308e47917659bca5cb240cec5f79e4b9095e44e26d0e929"
    static let ресурсыDriverSHA256 =
        "d9fdf4fd1f92e4d71d5f0d2e4b4a81368102fd5e0f6d73087a6b7be4e443f6b2"
}

public struct НазначениеИсполнителяПакета: Sendable {
    public let resolvedJournal = РазрешённыйЖурналПакета.localFUMA
    public let версияКоррекцииДопуска: Int
    public let корневойUUID: String
    public let uuidИсполнителя: String
    public let физическийКорень: URL
    public let ref: String
    public let базовыйOID: String
    public let область: String
    public let коммитПостановки: String
    public let деревоПостановки: String
    public let родительПостановки: String
    public let путьПостановки: String
    public let blobПостановки: String
    public let sha256Постановки: String
    public let путьПакета: String
    public let sha256Пакета: String
    public let байтовПакета: Int
    public let путьDriver: String
    public let sha256Driver: String
    public let байтовDriver: Int
    public let закрепленияРесурсовDriver: [ЗакреплениеИсходникаИсполнителяПакета]
    public let ресурсыDriverSHA256: String
    public let коммитИсточника: String
    public let деревоИсточника: String
    public let путьЗакреплений: String
    public let blobЗакреплений: String
    public let sha256ФайлаЗакреплений: String
    public let числоЗакреплений: Int
    public let путьРезультатаСборки: String
    public let закрепленияИсточника: [ЗакреплениеИсходникаИсполнителяПакета]
    public let исходнаяКартаSHA256: String
    public let коммитТекущейКарты: String
    public let деревоТекущейКарты: String
    public let закрепленияТекущегоCheckout: [ЗакреплениеИсходникаИсполнителяПакета]
    public let текущаяКартаSHA256: String
    public let разрешённыеТекущиеОтличия: [String]
    public let основаниеТекущихОтличий: String
    public let закрепленияИсполнителя: [ЗакреплениеИсходникаИсполнителяПакета]
    public let исходникиИсполнителяКартаSHA256: String

    init(
        версияКоррекцииДопуска: Int,
        корневойUUID: String,
        uuidИсполнителя: String,
        физическийКорень: URL,
        ref: String,
        базовыйOID: String,
        область: String,
        коммитПостановки: String,
        деревоПостановки: String,
        родительПостановки: String,
        путьПостановки: String,
        blobПостановки: String,
        sha256Постановки: String,
        путьПакета: String,
        sha256Пакета: String,
        байтовПакета: Int,
        путьDriver: String,
        sha256Driver: String,
        байтовDriver: Int,
        закрепленияРесурсовDriver: [ЗакреплениеИсходникаИсполнителяПакета],
        ресурсыDriverSHA256: String,
        коммитИсточника: String,
        деревоИсточника: String,
        путьЗакреплений: String,
        blobЗакреплений: String,
        sha256ФайлаЗакреплений: String,
        числоЗакреплений: Int,
        путьРезультатаСборки: String,
        закрепленияИсточника: [ЗакреплениеИсходникаИсполнителяПакета],
        исходнаяКартаSHA256: String,
        коммитТекущейКарты: String,
        деревоТекущейКарты: String,
        закрепленияТекущегоCheckout: [ЗакреплениеИсходникаИсполнителяПакета],
        текущаяКартаSHA256: String,
        разрешённыеТекущиеОтличия: [String],
        основаниеТекущихОтличий: String,
        закрепленияИсполнителя: [ЗакреплениеИсходникаИсполнителяПакета],
        исходникиИсполнителяКартаSHA256: String
    ) {
        self.версияКоррекцииДопуска = версияКоррекцииДопуска
        self.корневойUUID = корневойUUID
        self.uuidИсполнителя = uuidИсполнителя
        self.физическийКорень = физическийКорень
        self.ref = ref
        self.базовыйOID = базовыйOID
        self.область = область
        self.коммитПостановки = коммитПостановки
        self.деревоПостановки = деревоПостановки
        self.родительПостановки = родительПостановки
        self.путьПостановки = путьПостановки
        self.blobПостановки = blobПостановки
        self.sha256Постановки = sha256Постановки
        self.путьПакета = путьПакета
        self.sha256Пакета = sha256Пакета
        self.байтовПакета = байтовПакета
        self.путьDriver = путьDriver
        self.sha256Driver = sha256Driver
        self.байтовDriver = байтовDriver
        self.закрепленияРесурсовDriver = закрепленияРесурсовDriver
        self.ресурсыDriverSHA256 = ресурсыDriverSHA256
        self.коммитИсточника = коммитИсточника
        self.деревоИсточника = деревоИсточника
        self.путьЗакреплений = путьЗакреплений
        self.blobЗакреплений = blobЗакреплений
        self.sha256ФайлаЗакреплений = sha256ФайлаЗакреплений
        self.числоЗакреплений = числоЗакреплений
        self.путьРезультатаСборки = путьРезультатаСборки
        self.закрепленияИсточника = закрепленияИсточника
        self.исходнаяКартаSHA256 = исходнаяКартаSHA256
        self.коммитТекущейКарты = коммитТекущейКарты
        self.деревоТекущейКарты = деревоТекущейКарты
        self.закрепленияТекущегоCheckout = закрепленияТекущегоCheckout
        self.текущаяКартаSHA256 = текущаяКартаSHA256
        self.разрешённыеТекущиеОтличия = разрешённыеТекущиеОтличия
        self.основаниеТекущихОтличий = основаниеТекущихОтличий
        self.закрепленияИсполнителя = закрепленияИсполнителя
        self.исходникиИсполнителяКартаSHA256 = исходникиИсполнителяКартаSHA256
    }
}

public struct НаблюдениеФизическойПривязкиПакета: Sendable {
    public let физическийКорень: URL
    public let ref: String
    public let headOID: String
    public let чисто: Bool
    public let единственныйПисатель: Bool

    init(
        физическийКорень: URL,
        ref: String,
        headOID: String,
        чисто: Bool,
        единственныйПисатель: Bool
    ) {
        self.физическийКорень = физическийКорень
        self.ref = ref
        self.headOID = headOID
        self.чисто = чисто
        self.единственныйПисатель = единственныйПисатель
    }
}

public struct НаблюдениеПостановкиИсполнителяПакета: Sendable {
    public let коммит: String
    public let дерево: String
    public let родитель: String
    public let путь: String
    public let blob: String
    public let sha256: String

    init(
        коммит: String,
        дерево: String,
        родитель: String,
        путь: String,
        blob: String,
        sha256: String
    ) {
        self.коммит = коммит
        self.дерево = дерево
        self.родитель = родитель
        self.путь = путь
        self.blob = blob
        self.sha256 = sha256
    }
}

public struct НаблюдениеACKИсполнителяПакета: Sendable {
    public let uuidИсполнителя: String
    public let физическийКорень: URL
    public let ref: String
    public let headOID: String
    public let модель: String
    public let усилие: String
    public let подтверждён: Bool

    init(
        uuidИсполнителя: String,
        физическийКорень: URL,
        ref: String,
        headOID: String,
        модель: String,
        усилие: String,
        подтверждён: Bool
    ) {
        self.uuidИсполнителя = uuidИсполнителя
        self.физическийКорень = физическийКорень
        self.ref = ref
        self.headOID = headOID
        self.модель = модель
        self.усилие = усилие
        self.подтверждён = подтверждён
    }
}

public struct НаблюдениеЗакрепленийИсточникаПакета: Sendable {
    public let коммит: String
    public let деревоИсточника: String
    public let путьЗакреплений: String
    public let blobЗакреплений: String
    public let sha256ФайлаЗакреплений: String
    public let путьРезультатаСборки: String
    public let числоЗакреплений: Int
    public let совпавшихЗакреплений: Int
    public let закрепленияИсточника: [ЗакреплениеИсходникаИсполнителяПакета]
    public let исходнаяКартаSHA256: String
    public let коммитТекущейКарты: String
    public let деревоТекущейКарты: String
    public let закрепленияТекущегоCheckout: [ЗакреплениеИсходникаИсполнителяПакета]
    public let текущаяКартаSHA256: String
    public let текущиеОтличия: [String]
    public let закрепленияИсполнителя: [ЗакреплениеИсходникаИсполнителяПакета]
    public let исходникиИсполнителяКартаSHA256: String
    public let ресурсыDriverSHA256: String

    init(
        коммит: String,
        деревоИсточника: String,
        путьЗакреплений: String,
        blobЗакреплений: String,
        sha256ФайлаЗакреплений: String,
        путьРезультатаСборки: String,
        числоЗакреплений: Int,
        совпавшихЗакреплений: Int,
        закрепленияИсточника: [ЗакреплениеИсходникаИсполнителяПакета],
        исходнаяКартаSHA256: String,
        коммитТекущейКарты: String,
        деревоТекущейКарты: String,
        закрепленияТекущегоCheckout: [ЗакреплениеИсходникаИсполнителяПакета],
        текущаяКартаSHA256: String,
        текущиеОтличия: [String],
        закрепленияИсполнителя: [ЗакреплениеИсходникаИсполнителяПакета],
        исходникиИсполнителяКартаSHA256: String,
        ресурсыDriverSHA256: String
    ) {
        self.коммит = коммит
        self.деревоИсточника = деревоИсточника
        self.путьЗакреплений = путьЗакреплений
        self.blobЗакреплений = blobЗакреплений
        self.sha256ФайлаЗакреплений = sha256ФайлаЗакреплений
        self.путьРезультатаСборки = путьРезультатаСборки
        self.числоЗакреплений = числоЗакреплений
        self.совпавшихЗакреплений = совпавшихЗакреплений
        self.закрепленияИсточника = закрепленияИсточника
        self.исходнаяКартаSHA256 = исходнаяКартаSHA256
        self.коммитТекущейКарты = коммитТекущейКарты
        self.деревоТекущейКарты = деревоТекущейКарты
        self.закрепленияТекущегоCheckout = закрепленияТекущегоCheckout
        self.текущаяКартаSHA256 = текущаяКартаSHA256
        self.текущиеОтличия = текущиеОтличия
        self.закрепленияИсполнителя = закрепленияИсполнителя
        self.исходникиИсполнителяКартаSHA256 = исходникиИсполнителяКартаSHA256
        self.ресурсыDriverSHA256 = ресурсыDriverSHA256
    }
}

public struct РабочиеФайлыИсполненияПакета: Sendable {
    public let каталог: URL
    public let вход: URL
    public let план: URL
    public let намерениеApply: URL
    public let исходApply: URL

    init(
        каталог: URL,
        вход: URL,
        план: URL,
        намерениеApply: URL,
        исходApply: URL
    ) {
        self.каталог = каталог
        self.вход = вход
        self.план = план
        self.намерениеApply = намерениеApply
        self.исходApply = исходApply
    }
}

public struct ЗапросИсполненияПакета: Sendable {
    public let пакет: URL
    public let входныеБайты: Data
    public let назначение: НазначениеИсполнителяПакета
    public let наблюдениеПостановки: НаблюдениеПостановкиИсполнителяПакета
    public let наблюдениеACK: НаблюдениеACKИсполнителяПакета
    public let физическоеНаблюдение: НаблюдениеФизическойПривязкиПакета
    public let наблюдениеЗакреплений: НаблюдениеЗакрепленийИсточникаПакета
    public let рабочиеФайлы: РабочиеФайлыИсполненияПакета

    init(
        пакет: URL,
        входныеБайты: Data,
        назначение: НазначениеИсполнителяПакета,
        наблюдениеПостановки: НаблюдениеПостановкиИсполнителяПакета,
        наблюдениеACK: НаблюдениеACKИсполнителяПакета,
        физическоеНаблюдение: НаблюдениеФизическойПривязкиПакета,
        наблюдениеЗакреплений: НаблюдениеЗакрепленийИсточникаПакета,
        рабочиеФайлы: РабочиеФайлыИсполненияПакета
    ) {
        self.пакет = пакет
        self.входныеБайты = входныеБайты
        self.назначение = назначение
        self.наблюдениеПостановки = наблюдениеПостановки
        self.наблюдениеACK = наблюдениеACK
        self.физическоеНаблюдение = физическоеНаблюдение
        self.наблюдениеЗакреплений = наблюдениеЗакреплений
        self.рабочиеФайлы = рабочиеФайлы
    }
}

public enum ДействиеПроцессаПакета: String, Codable, Sendable {
    case помощь, план, применить
}

public struct КомандаПроцессаПакета: Equatable, Sendable {
    public let действие: ДействиеПроцессаПакета
    public let исполняемыйФайл: URL
    public let аргументы: [String]

    public func значениеАргумента(_ имя: String) throws -> URL {
        guard let позиция = аргументы.firstIndex(of: имя), позиция + 1 < аргументы.count else {
            throw ОшибкаИсполнителяПакета.неверныеРабочиеФайлы
        }
        return URL(fileURLWithPath: аргументы[позиция + 1])
    }
}

public struct РезультатПроцессаПакета: Equatable, Sendable {
    public let код: Int32
    public let stdout: Data
    public let stderr: Data
    public let завершениеПодтверждено: Bool

    public init(код: Int32, stdout: Data, stderr: Data, завершениеПодтверждено: Bool) {
        self.код = код
        self.stdout = stdout
        self.stderr = stderr
        self.завершениеПодтверждено = завершениеПодтверждено
    }
}

public enum ОшибкаПроцессаПакета: Error, Equatable, Sendable {
    case запускНеНачат
    case исходНеизвестен
}

protocol ЗапускПроцессаПакета: Sendable {
    func выполнить(_ команда: КомандаПроцессаПакета) async throws -> РезультатПроцессаПакета
}

public enum ОшибкаИсполнителяПакета: Error, Equatable, Sendable {
    case неверноеНазначение
    case неверныйПакет
    case неверныйDriver
    case неверныеЗакрепления
    case невернаяФизическаяПривязка
    case неверныйВход
    case неверныеРабочиеФайлы
    case отказПомощи
    case отказПлана
    case неверныйПлан
    case конфликтРабочихБайт
    case запускApplyНеНачат
}

public enum ИсходПримененияПакета: String, Codable, Equatable, Sendable {
    case установлена
    case наблюдена
    case наблюденаДоПрименения = "наблюдена-до-применения"
    case наблюденаПослеНеизвестности = "наблюдена-после-неизвестности"
    case неизвестен
    case конфликт
}

public enum СостояниеДоставкиПакета: String, Codable, Equatable, Sendable {
    case подтверждена
    case неПодтверждена = "не-подтверждена"
}

public enum СостояниеACKИсполнителяПакета: String, Codable, Equatable, Sendable {
    case подтверждён
    case неПодтверждён = "не-подтверждён"
}

public enum СостояниеReadbackПакета: String, Codable, Equatable, Sendable {
    case отсутствует, точный, конфликт, ошибка
}

public enum СостояниеВызоваApplyПакета: String, Codable, Equatable, Sendable {
    case неВызывался = "не-вызывался"
    case запускНеНачат = "запуск-не-начат"
    case исходНеизвестен = "исход-неизвестен"
    case завершён
}

public struct КвитанцияИсполненияПакета: Codable, Equatable, Sendable {
    public let схема: String
    public let версияКоррекцииДопуска: Int
    public let resolvedJournal: РазрешённыйЖурналПакета
    public let доставкаПакета: СостояниеДоставкиПакета
    public let ackИсполнителя: СостояниеACKИсполнителяПакета
    public let применение: ИсходПримененияПакета
    public let повторныйДопуск: Bool
    public let коммитПостановки: String
    public let деревоПостановки: String
    public let родительПостановки: String
    public let blobПостановки: String
    public let постановкаSHA256: String
    public let пакетSHA256: String
    public let driverSHA256: String
    public let ресурсыDriverSHA256: String
    public let источникКоммит: String
    public let источникДерево: String
    public let закрепленияBlob: String
    public let файлЗакрепленийSHA256: String
    public let закреплений: Int
    public let исходнаяКартаSHA256: String
    public let текущаяКартаКоммит: String
    public let текущаяКартаДерево: String
    public let текущаяКартаSHA256: String
    public let основаниеОтличийSHA256: String
    public let исходникиИсполнителяSHA256: String
    public let физическийКореньSHA256: String
    public let ref: String
    public let базовыйOID: String
    public let чисто: Bool
    public let единственныйПисатель: Bool
    public let модель: String
    public let усилие: String
    public let область: String
    public let входSHA256: String
    public let операцияSHA256: String
    public let applyArgvSHA256: String
    public let applyНамерениеSHA256: String?
    public let помощьSHA256: String?
    public let планSHA256: String
    public let applySHA256: String?
    public let applyВызван: Bool?
    public let applyСостояние: СостояниеВызоваApplyПакета
    public let applyИсходСохранён: Bool
    public let applyИсходSHA256: String?
    public let applyКод: Int32?
    public let applyЗавершениеПодтверждено: Bool?
    public let applyStderrSHA256: String?
    public let applyStdoutБайтов: Int?
    public let applyStderrБайтов: Int?
    public let readbackSHA256: String?
    public let readbackСостояние: СостояниеReadbackПакета
    public let идентификаторЗаписи: String
    public let путьЗаписи: String

    enum CodingKeys: String, CodingKey {
        case схема
        case версияКоррекцииДопуска = "версия_коррекции_допуска"
        case resolvedJournal = "resolved_journal"
        case доставкаПакета = "доставка_пакета"
        case ackИсполнителя = "ack_исполнителя"
        case применение
        case повторныйДопуск = "повторный_допуск"
        case коммитПостановки = "коммит_постановки"
        case деревоПостановки = "дерево_постановки"
        case родительПостановки = "родитель_постановки"
        case blobПостановки = "blob_постановки"
        case постановкаSHA256 = "постановка_sha256"
        case пакетSHA256 = "пакет_sha256"
        case driverSHA256 = "driver_sha256"
        case ресурсыDriverSHA256 = "ресурсы_driver_sha256"
        case источникКоммит = "источник_коммит"
        case источникДерево = "источник_дерево"
        case закрепленияBlob = "закрепления_blob"
        case файлЗакрепленийSHA256 = "файл_закреплений_sha256"
        case закреплений
        case исходнаяКартаSHA256 = "исходная_карта_sha256"
        case текущаяКартаКоммит = "текущая_карта_коммит"
        case текущаяКартаДерево = "текущая_карта_дерево"
        case текущаяКартаSHA256 = "текущая_карта_sha256"
        case основаниеОтличийSHA256 = "основание_отличий_sha256"
        case исходникиИсполнителяSHA256 = "исходники_исполнителя_sha256"
        case физическийКореньSHA256 = "физический_корень_sha256"
        case ref
        case базовыйOID = "базовый_oid"
        case чисто
        case единственныйПисатель = "единственный_писатель"
        case модель, усилие
        case область
        case входSHA256 = "вход_sha256"
        case операцияSHA256 = "операция_sha256"
        case applyArgvSHA256 = "apply_argv_sha256"
        case applyНамерениеSHA256 = "apply_намерение_sha256"
        case помощьSHA256 = "помощь_sha256"
        case планSHA256 = "план_sha256"
        case applySHA256 = "apply_sha256"
        case applyВызван = "apply_вызван"
        case applyСостояние = "apply_состояние"
        case applyИсходСохранён = "apply_исход_сохранён"
        case applyИсходSHA256 = "apply_исход_sha256"
        case applyКод = "apply_код"
        case applyЗавершениеПодтверждено = "apply_завершение_подтверждено"
        case applyStderrSHA256 = "apply_stderr_sha256"
        case applyStdoutБайтов = "apply_stdout_байтов"
        case applyStderrБайтов = "apply_stderr_байтов"
        case readbackSHA256 = "readback_sha256"
        case readbackСостояние = "readback_состояние"
        case идентификаторЗаписи = "идентификатор_записи"
        case путьЗаписи = "путь_записи"
    }
}

public struct ИтогИсполненияПакета: Equatable, Sendable {
    public let применение: ИсходПримененияПакета
    public let квитанция: КвитанцияИсполненияПакета
}

private struct СвидетельствоИсходаApplyПакета {
    let байты: Data
    let исход: ИсходApplyПакета
}

private enum РежимДопускаИсполнителяПакета: Equatable {
    case исправленныйV2
    case тестоваяФикстура
}

public enum ИсполнительПакетаЛокальногоЖурнала {
    public static func выполнить(
        _ запрос: ЗапросИсполненияПакета
    ) async throws -> ИтогИсполненияПакета {
        try await выполнить(
            запрос,
            используя: СистемныйЗапускПроцессаПакета(),
            режимДопуска: .исправленныйV2)
    }

    static func выполнить(
        _ запрос: ЗапросИсполненияПакета,
        используя запуск: any ЗапускПроцессаПакета
    ) async throws -> ИтогИсполненияПакета {
        try await выполнить(
            запрос, используя: запуск, режимДопуска: .тестоваяФикстура)
    }

    private static func выполнить(
        _ запрос: ЗапросИсполненияПакета,
        используя запуск: any ЗапускПроцессаПакета,
        режимДопуска: РежимДопускаИсполнителяПакета
    ) async throws -> ИтогИсполненияПакета {
        if режимДопуска == .исправленныйV2 {
            try проверитьИсправленныйДопускV2(запрос)
        }
        let подготовка = try подготовить(запрос)
        guard try ФайлыИсполнителяПакета.прочитатьЕслиЕсть(
                запрос.рабочиеФайлы.вход) == nil,
              try ФайлыИсполнителяПакета.прочитатьЕслиЕсть(
                запрос.рабочиеФайлы.план) == nil,
              try ФайлыИсполнителяПакета.прочитатьЕслиЕсть(
                запрос.рабочиеФайлы.намерениеApply) == nil,
              try ФайлыИсполнителяПакета.прочитатьЕслиЕсть(
                запрос.рабочиеФайлы.исходApply) == nil else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        try ФайлыИсполнителяПакета.сохранитьТочно(
            запрос.входныеБайты, по: запрос.рабочиеФайлы.вход)

        _ = try подготовить(запрос)
        let помощь = try await запуск.выполнить(try РазрешительArgvПакета.разрешить(
            .помощь, подготовка: подготовка, файлы: запрос.рабочиеФайлы))
        guard помощь.завершениеПодтверждено, помощь.код == 0,
              let справка = String(data: помощь.stdout, encoding: .utf8),
              справка.contains("журнал план"), справка.contains("журнал применить") else {
            throw ОшибкаИсполнителяПакета.отказПомощи
        }

        _ = try подготовить(запрос)
        let исходПлана = try await запуск.выполнить(try РазрешительArgvПакета.разрешить(
            .план, подготовка: подготовка, файлы: запрос.рабочиеФайлы))
        guard исходПлана.завершениеПодтверждено, исходПлана.код == 0 else {
            throw ОшибкаИсполнителяПакета.отказПлана
        }
        let ответПлана: ОтветПланаПакета
        do { ответПлана = try закрытоРазобрать(ОтветПланаПакета.self, из: исходПлана.stdout) }
        catch { throw ОшибкаИсполнителяПакета.неверныйПлан }
        try проверитьПлан(
            ответПлана, вход: запрос.входныеБайты, назначение: запрос.назначение)
        try ФайлыИсполнителяПакета.сохранитьТочно(
            исходПлана.stdout, по: запрос.рабочиеФайлы.план)
        guard try ФайлыИсполнителяПакета.прочитатьТочно(запрос.рабочиеФайлы.вход)
                == запрос.входныеБайты,
              try ФайлыИсполнителяПакета.прочитатьТочно(запрос.рабочиеФайлы.план)
                == исходПлана.stdout else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        let цель = запрос.назначение.физическийКорень
            .appendingPathComponent(ответПлана.план.путь)
        if let прежниеБайты = try ФайлыИсполнителяПакета.прочитатьЕслиЕсть(цель) {
            let исход: ИсходПримененияПакета = прежниеБайты == ответПлана.план.байты
                ? .наблюденаДоПрименения : .конфликт
            return итог(
                исход: исход, запрос: запрос, повторныйДопуск: true,
                помощь: помощь.stdout,
                план: исходПлана.stdout, apply: nil, applyВызван: false,
                applyСостояние: .неВызывался,
                намерениеApply: nil, свидетельствоИсходаApply: nil,
                readback: прежниеБайты, readbackОшибка: false,
                ответПлана: ответПлана)
        }

        let командаApply = try РазрешительArgvПакета.разрешить(
            .применить, подготовка: подготовка, файлы: запрос.рабочиеФайлы)
        _ = try подготовить(запрос)
        guard try ФайлыИсполнителяПакета.прочитатьТочно(запрос.рабочиеФайлы.вход)
                == запрос.входныеБайты,
              try ФайлыИсполнителяПакета.прочитатьТочно(запрос.рабочиеФайлы.план)
                == исходПлана.stdout else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        let намерениеApply = try сформироватьНамерениеApply(
            запрос: запрос, план: ответПлана, байтыПлана: исходПлана.stdout)
        try ФайлыИсполнителяПакета.сохранитьТочно(
            намерениеApply,
            по: запрос.рабочиеФайлы.намерениеApply,
            приниматьТочныйПовтор: false)
        guard try ФайлыИсполнителяПакета.прочитатьТочно(
            запрос.рабочиеФайлы.намерениеApply) == намерениеApply else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        let исходApply: РезультатПроцессаПакета?
        let applyСостояние: СостояниеВызоваApplyПакета
        do {
            исходApply = try await запуск.выполнить(командаApply)
            applyСостояние = .завершён
        } catch ОшибкаПроцессаПакета.запускНеНачат {
            let байтыИсхода = try сформироватьИсходApply(
                запрос: запрос, состояние: .запускНеНачат, результат: nil)
            try? ФайлыИсполнителяПакета.сохранитьТочно(
                байтыИсхода,
                по: запрос.рабочиеФайлы.исходApply,
                приниматьТочныйПовтор: false)
            throw ОшибкаИсполнителяПакета.запускApplyНеНачат
        } catch {
            исходApply = nil
            applyСостояние = .исходНеизвестен
        }
        let байтыИсходаApply = try сформироватьИсходApply(
            запрос: запрос, состояние: applyСостояние, результат: исходApply)
        let свидетельствоИсходаApply: СвидетельствоИсходаApplyПакета?
        do {
            try ФайлыИсполнителяПакета.сохранитьТочно(
                байтыИсходаApply,
                по: запрос.рабочиеФайлы.исходApply,
                приниматьТочныйПовтор: false)
            let сохранённыеБайты = try ФайлыИсполнителяПакета.прочитатьТочно(
                запрос.рабочиеФайлы.исходApply)
            guard сохранённыеБайты == байтыИсходаApply else {
                throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
            }
            свидетельствоИсходаApply = СвидетельствоИсходаApplyПакета(
                байты: сохранённыеБайты,
                исход: try разобратьИсходApply(сохранённыеБайты, запрос: запрос))
        } catch {
            свидетельствоИсходаApply = nil
        }
        let readback: Data?
        let readbackОшибка: Bool
        do {
            readback = try ФайлыИсполнителяПакета.прочитатьЕслиЕсть(цель)
            readbackОшибка = false
        } catch {
            readback = nil
            readbackОшибка = true
        }
        let исход: ИсходПримененияПакета
        if readbackОшибка {
            исход = .конфликт
        } else if let исходApply, исходApply.завершениеПодтверждено, исходApply.код == 0 {
            let ответ: ОтветПримененияПакета
            do { ответ = try закрытоРазобрать(ОтветПримененияПакета.self, из: исходApply.stdout) }
            catch { return итог(
                исход: readback.map { $0 == ответПлана.план.байты ?
                    .наблюдена : .конфликт } ?? .неизвестен,
                запрос: запрос, повторныйДопуск: true,
                помощь: помощь.stdout, план: исходПлана.stdout,
                apply: исходApply, applyВызван: true,
                applyСостояние: applyСостояние,
                намерениеApply: намерениеApply,
                свидетельствоИсходаApply: свидетельствоИсходаApply,
                readback: readback, readbackОшибка: false,
                ответПлана: ответПлана) }
            guard ответ.путь == ответПлана.план.путь,
                  ответ.хэшСодержания == ответПлана.план.хэшСодержания else {
                return итог(
                    исход: readback.map { $0 == ответПлана.план.байты ?
                        .наблюдена : .конфликт } ?? .неизвестен,
                    запрос: запрос, повторныйДопуск: true,
                    помощь: помощь.stdout, план: исходПлана.stdout,
                    apply: исходApply, applyВызван: true,
                    applyСостояние: applyСостояние,
                    намерениеApply: намерениеApply,
                    свидетельствоИсходаApply: свидетельствоИсходаApply,
                    readback: readback, readbackОшибка: false,
                    ответПлана: ответПлана)
            }
            guard let readback else { исход = .неизвестен; return итог(
                исход: исход, запрос: запрос, повторныйДопуск: true,
                помощь: помощь.stdout,
                план: исходПлана.stdout, apply: исходApply, applyВызван: true,
                applyСостояние: applyСостояние,
                намерениеApply: намерениеApply,
                свидетельствоИсходаApply: свидетельствоИсходаApply,
                readback: nil, readbackОшибка: false,
                ответПлана: ответПлана) }
            if readback != ответПлана.план.байты { исход = .конфликт }
            else { исход = ответ.вид == .установлена ? .установлена : .наблюдена }
        } else if let readback {
            if readback != ответПлана.план.байты { исход = .конфликт }
            else if applyСостояние == .исходНеизвестен {
                исход = .наблюденаПослеНеизвестности
            } else {
                исход = .наблюдена
            }
        } else {
            исход = .неизвестен
        }
        return итог(
            исход: исход, запрос: запрос, повторныйДопуск: true,
            помощь: помощь.stdout,
            план: исходПлана.stdout, apply: исходApply, applyВызван: true,
            applyСостояние: applyСостояние,
            намерениеApply: намерениеApply,
            свидетельствоИсходаApply: свидетельствоИсходаApply,
            readback: readback, readbackОшибка: readbackОшибка,
            ответПлана: ответПлана)
    }

    public static func сверитьПослеНеизвестногоИсхода(
        _ запрос: ЗапросИсполненияПакета
    ) throws -> ИтогИсполненияПакета {
        try сверитьПослеНеизвестногоИсхода(
            запрос, режимДопуска: .исправленныйV2)
    }

    static func сверитьПослеНеизвестногоИсходаДляФикстуры(
        _ запрос: ЗапросИсполненияПакета
    ) throws -> ИтогИсполненияПакета {
        try сверитьПослеНеизвестногоИсхода(
            запрос, режимДопуска: .тестоваяФикстура)
    }

    private static func сверитьПослеНеизвестногоИсхода(
        _ запрос: ЗапросИсполненияПакета,
        режимДопуска: РежимДопускаИсполнителяПакета
    ) throws -> ИтогИсполненияПакета {
        if режимДопуска == .исправленныйV2 {
            try проверитьИсправленныйДопускV2(запрос)
        }
        try проверитьНазначение(запрос.назначение)
        try проверитьПостановку(
            запрос.наблюдениеПостановки, назначение: запрос.назначение)
        try проверитьACK(запрос.наблюдениеACK, назначение: запрос.назначение)
        guard запрос.пакет.standardizedFileURL.path
                == запрос.назначение.путьПакета else {
            throw ОшибкаИсполнителяПакета.неверноеНазначение
        }
        try проверитьРабочиеФайлы(запрос)
        guard try ФайлыИсполнителяПакета.прочитатьТочно(запрос.рабочиеФайлы.вход)
                == запрос.входныеБайты else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        let байтыПлана = try ФайлыИсполнителяПакета.прочитатьТочно(
            запрос.рабочиеФайлы.план)
        let ответПлана: ОтветПланаПакета
        do { ответПлана = try закрытоРазобрать(ОтветПланаПакета.self, из: байтыПлана) }
        catch { throw ОшибкаИсполнителяПакета.неверныйПлан }
        try проверитьПлан(
            ответПлана, вход: запрос.входныеБайты, назначение: запрос.назначение)
        let ожидаемоеНамерение = try сформироватьНамерениеApply(
            запрос: запрос, план: ответПлана, байтыПлана: байтыПлана)
        guard try ФайлыИсполнителяПакета.прочитатьТочно(
            запрос.рабочиеФайлы.намерениеApply) == ожидаемоеНамерение else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        let applyСостояние: СостояниеВызоваApplyПакета
        let applyВызван: Bool?
        let свидетельствоИсходаApply: СвидетельствоИсходаApplyПакета?
        let applyИсходОшибка: Bool
        do {
            if let байтыИсхода = try ФайлыИсполнителяПакета.прочитатьЕслиЕсть(
                запрос.рабочиеФайлы.исходApply) {
                let сохранённыйИсход = try разобратьИсходApply(
                    байтыИсхода, запрос: запрос)
                applyСостояние = сохранённыйИсход.состояние
                applyВызван = сохранённыйИсход.состояние == .запускНеНачат ? false : true
                свидетельствоИсходаApply = СвидетельствоИсходаApplyПакета(
                    байты: байтыИсхода, исход: сохранённыйИсход)
            } else {
                applyСостояние = .исходНеизвестен
                applyВызван = nil
                свидетельствоИсходаApply = nil
            }
            applyИсходОшибка = false
        } catch {
            applyСостояние = .исходНеизвестен
            applyВызван = nil
            свидетельствоИсходаApply = nil
            applyИсходОшибка = true
        }
        let цель = запрос.назначение.физическийКорень
            .appendingPathComponent(ответПлана.план.путь)
        let readback: Data?
        let readbackОшибка: Bool
        do {
            readback = try ФайлыИсполнителяПакета.прочитатьЕслиЕсть(цель)
            readbackОшибка = false
        } catch {
            readback = nil
            readbackОшибка = true
        }
        let исход: ИсходПримененияПакета
        if readbackОшибка || applyИсходОшибка {
            исход = .конфликт
        } else if let readback {
            if readback != ответПлана.план.байты { исход = .конфликт }
            else if applyСостояние == .завершён { исход = .наблюдена }
            else { исход = .наблюденаПослеНеизвестности }
        } else {
            исход = .неизвестен
        }
        if applyСостояние == .запускНеНачат {
            throw ОшибкаИсполнителяПакета.запускApplyНеНачат
        }
        let повторныйДопуск = (try? подготовить(запрос)) != nil
        return итог(
            исход: исход, запрос: запрос, повторныйДопуск: повторныйДопуск,
            помощь: nil,
            план: байтыПлана, apply: nil, applyВызван: applyВызван,
            applyСостояние: applyСостояние,
            намерениеApply: ожидаемоеНамерение,
            свидетельствоИсходаApply: свидетельствоИсходаApply,
            readback: readback, readbackОшибка: readbackОшибка,
            ответПлана: ответПлана)
    }

    private static func подготовить(
        _ запрос: ЗапросИсполненияПакета
    ) throws -> ПодготовкаИсполненияПакета {
        try проверитьНазначение(запрос.назначение)
        try проверитьПостановку(
            запрос.наблюдениеПостановки, назначение: запрос.назначение)
        try проверитьACK(запрос.наблюдениеACK, назначение: запрос.назначение)
        guard запрос.пакет.standardizedFileURL.path == запрос.назначение.путьПакета else {
            throw ОшибкаИсполнителяПакета.неверноеНазначение
        }
        let пакетБайты = try ФайлыИсполнителяПакета.прочитатьТочно(запрос.пакет)
        guard пакетБайты.count == запрос.назначение.байтовПакета,
              sha256Пакета(пакетБайты) == запрос.назначение.sha256Пакета else {
            throw ОшибкаИсполнителяПакета.неверныйПакет
        }
        let пакет: ПакетЛокальногоЖурнала
        do { пакет = try закрытоРазобрать(ПакетЛокальногоЖурнала.self, из: пакетБайты) }
        catch { throw ОшибкаИсполнителяПакета.неверныйПакет }
        try проверитьПакет(пакет, назначение: запрос.назначение)
        try проверитьПривязку(
            запрос.физическоеНаблюдение, назначение: запрос.назначение)
        try проверитьЗакрепления(
            запрос.наблюдениеЗакреплений, назначение: запрос.назначение)
        try проверитьТекущиеФайлы(назначение: запрос.назначение)
        let вход: ВходЛокальногоЖурнала
        do { вход = try закрытоРазобрать(ВходЛокальногоЖурнала.self, из: запрос.входныеБайты) }
        catch { throw ОшибкаИсполнителяПакета.неверныйВход }
        try проверитьВход(вход, назначение: запрос.назначение)
        try проверитьРабочиеФайлы(запрос)
        let driver = URL(fileURLWithPath: запрос.назначение.путьDriver)
        let driverБайты = try ФайлыИсполнителяПакета.прочитатьТочно(driver)
        guard driverБайты.count == запрос.назначение.байтовDriver,
              sha256Пакета(driverБайты) == запрос.назначение.sha256Driver,
              пакет.driver.sha256 == запрос.назначение.sha256Driver,
              FileManager.default.isExecutableFile(atPath: driver.path) else {
            throw ОшибкаИсполнителяПакета.неверныйDriver
        }
        try проверитьРесурсыDriver(
            driver: driver,
            закрепления: запрос.назначение.закрепленияРесурсовDriver)
        return ПодготовкаИсполненияПакета(
            пакетБайты: пакетБайты, driver: driver, запрос: запрос)
    }

    private static func итог(
        исход: ИсходПримененияПакета,
        запрос: ЗапросИсполненияПакета,
        повторныйДопуск: Bool,
        помощь: Data?,
        план: Data,
        apply: РезультатПроцессаПакета?,
        applyВызван: Bool?,
        applyСостояние: СостояниеВызоваApplyПакета,
        намерениеApply: Data?,
        свидетельствоИсходаApply: СвидетельствоИсходаApplyПакета?,
        readback: Data?,
        readbackОшибка: Bool,
        ответПлана: ОтветПланаПакета
    ) -> ИтогИсполненияПакета {
        let назначение = запрос.назначение
        let сохранённыйИсходApply = свидетельствоИсходаApply?.байты
        let разобранныйИсходApply = свидетельствоИсходаApply?.исход
        let квитанция = КвитанцияИсполненияПакета(
            схема: "fum.квитанция-исполнения-пакета-локального-журнала.1",
            версияКоррекцииДопуска: назначение.версияКоррекцииДопуска,
            resolvedJournal: .localFUMA,
            доставкаПакета: повторныйДопуск ? .подтверждена : .неПодтверждена,
            ackИсполнителя: повторныйДопуск ? .подтверждён : .неПодтверждён,
            применение: исход,
            повторныйДопуск: повторныйДопуск,
            коммитПостановки: назначение.коммитПостановки,
            деревоПостановки: назначение.деревоПостановки,
            родительПостановки: назначение.родительПостановки,
            blobПостановки: назначение.blobПостановки,
            постановкаSHA256: назначение.sha256Постановки,
            пакетSHA256: назначение.sha256Пакета,
            driverSHA256: назначение.sha256Driver,
            ресурсыDriverSHA256: назначение.ресурсыDriverSHA256,
            источникКоммит: назначение.коммитИсточника,
            источникДерево: назначение.деревоИсточника,
            закрепленияBlob: назначение.blobЗакреплений,
            файлЗакрепленийSHA256: назначение.sha256ФайлаЗакреплений,
            закреплений: назначение.числоЗакреплений,
            исходнаяКартаSHA256: назначение.исходнаяКартаSHA256,
            текущаяКартаКоммит: назначение.коммитТекущейКарты,
            текущаяКартаДерево: назначение.деревоТекущейКарты,
            текущаяКартаSHA256: назначение.текущаяКартаSHA256,
            основаниеОтличийSHA256: sha256Пакета(
                Data(назначение.основаниеТекущихОтличий.utf8)),
            исходникиИсполнителяSHA256:
                назначение.исходникиИсполнителяКартаSHA256,
            физическийКореньSHA256: sha256Пакета(Data(назначение.физическийКорень.path.utf8)),
            ref: назначение.ref,
            базовыйOID: назначение.базовыйOID,
            чисто: запрос.физическоеНаблюдение.чисто,
            единственныйПисатель: запрос.физическоеНаблюдение.единственныйПисатель,
            модель: запрос.наблюдениеACK.модель,
            усилие: запрос.наблюдениеACK.усилие,
            область: назначение.область,
            входSHA256: sha256Пакета(запрос.входныеБайты),
            операцияSHA256: идентификаторОперации(запрос),
            applyArgvSHA256: отпечатокArgvApply(запрос),
            applyНамерениеSHA256: намерениеApply.map { sha256Пакета($0) },
            помощьSHA256: помощь.map { sha256Пакета($0) },
            планSHA256: sha256Пакета(план),
            applySHA256: apply.map { sha256Пакета($0.stdout) }
                ?? разобранныйИсходApply?.stdoutSHA256,
            applyВызван: applyВызван,
            applyСостояние: applyСостояние,
            applyИсходСохранён: разобранныйИсходApply != nil,
            applyИсходSHA256: разобранныйИсходApply == nil ? nil
                : сохранённыйИсходApply.map { sha256Пакета($0) },
            applyКод: apply?.код ?? разобранныйИсходApply?.код,
            applyЗавершениеПодтверждено: apply?.завершениеПодтверждено
                ?? разобранныйИсходApply?.завершениеПодтверждено,
            applyStderrSHA256: apply.map { sha256Пакета($0.stderr) }
                ?? разобранныйИсходApply?.stderrSHA256,
            applyStdoutБайтов: apply?.stdout.count ?? разобранныйИсходApply?.stdoutБайтов,
            applyStderrБайтов: apply?.stderr.count ?? разобранныйИсходApply?.stderrБайтов,
            readbackSHA256: readback.map { sha256Пакета($0) },
            readbackСостояние: readbackОшибка ? .ошибка : readback.map {
                $0 == ответПлана.план.байты ? .точный : .конфликт
            } ?? .отсутствует,
            идентификаторЗаписи: ответПлана.план.идентификатор,
            путьЗаписи: ответПлана.план.путь)
        return ИтогИсполненияПакета(применение: исход, квитанция: квитанция)
    }
}

struct СистемныйЗапускПроцессаПакета: ЗапускПроцессаПакета {
    private let таймАутНаносекунд: UInt64

    init() { таймАутНаносекунд = 30_000_000_000 }

    init(таймАутНаносекунд: UInt64) {
        self.таймАутНаносекунд = таймАутНаносекунд
    }

    func выполнить(
        _ команда: КомандаПроцессаПакета
    ) async throws -> РезультатПроцессаПакета {
        try await withCheckedThrowingContinuation {
            (продолжение: CheckedContinuation<РезультатПроцессаПакета, Error>) in
            СостояниеСистемногоПроцессаПакета(
                команда: команда,
                таймАутНаносекунд: таймАутНаносекунд,
                продолжение: продолжение).начать()
        }
    }
}

private struct ПодготовкаИсполненияПакета: Sendable {
    let пакетБайты: Data
    let driver: URL
    let запрос: ЗапросИсполненияПакета
}

private enum РазрешительArgvПакета {
    static func разрешить(
        _ действие: ДействиеПроцессаПакета,
        подготовка: ПодготовкаИсполненияПакета,
        файлы: РабочиеФайлыИсполненияПакета
    ) throws -> КомандаПроцессаПакета {
        let корень = подготовка.запрос.назначение.физическийКорень.path
        let аргументы: [String]
        switch действие {
        case .помощь:
            аргументы = ["журнал", "помощь"]
        case .план:
            аргументы = ["журнал", "план", "--корень", корень,
                         "--вход", файлы.вход.path]
        case .применить:
            аргументы = ["журнал", "применить", "--корень", корень,
                         "--вход", файлы.вход.path, "--план", файлы.план.path]
        }
        guard аргументы.allSatisfy({ !$0.isEmpty && !$0.contains("\0")
            && !$0.contains("<") && !$0.contains(">") }) else {
            throw ОшибкаИсполнителяПакета.неверныеРабочиеФайлы
        }
        return КомандаПроцессаПакета(
            действие: действие,
            исполняемыйФайл: подготовка.driver,
            аргументы: аргументы)
    }
}

private struct ПакетЛокальногоЖурнала: Codable, Sendable {
    let схема: String
    let назначение: String
    let driver: DriverПакета
    let источник: ИсточникПакета
    let командыArgv: [[String]]
    let обязательнаяПодстановка: String
    let вход: ШаблонВходаПакета
    let границы: [String]

    enum CodingKeys: String, CodingKey {
        case схема, назначение, driver, источник, границы
        case командыArgv = "команды_argv"
        case обязательнаяПодстановка = "обязательная_подстановка"
        case вход
    }
}

private struct DriverПакета: Codable, Sendable {
    let путь: String
    let sha256: String
    let ресурсы: String
}

private struct ИсточникПакета: Codable, Sendable {
    let коммит: String
    let закрепления: String
    let полеЗакреплений: String
    let числоЗакреплений: Int
    let результат: String
    let руководство: String
    let модель: String

    enum CodingKeys: String, CodingKey {
        case коммит, закрепления, результат, руководство, модель
        case полеЗакреплений = "поле_закреплений"
        case числоЗакреплений = "число_закреплений"
    }
}

private struct ШаблонЭкземпляраПакета: Codable, Sendable {
    let корень: String
    let писатель: String
    let стадия: String
    let номер: Int
}

private struct ШаблонВходаПакета: Codable, Sendable {
    let схема: String
    let экземпляр: ШаблонЭкземпляраПакета
    let время: String
    let область: String
    let публичная: Bool
    let происхождение: [String]
    let сообщения: [String]
    let решения: [String]
    let проверки: [String]
    let исход: String
    let остаток: [String]
    let доставка: [String]
}

private struct ЭкземплярЛокальногоЖурнала: Codable, Sendable {
    let корень: String
    let писатель: String
    let стадия: String
    let номер: Int
}

private struct ОригиналЛокальногоСообщения: Codable, Sendable {
    let sha256: String
    let байтов: Int
    let источник: String
}

private enum РольЛокальногоСообщения: String, Codable, Sendable {
    case человек, агент
}

private enum ВидЛокальногоСообщения: String, Codable, Sendable {
    case буквальное, производное
}

private enum ИсходЛокальнойПроверки: String, Codable, Sendable {
    case успешно, неуспешно, прервано, неизвестно, неПроверено
}

private struct ЛокальноеСообщение: Codable, Sendable {
    let роль: РольЛокальногоСообщения
    let вид: ВидЛокальногоСообщения
    let текст: String
    let происхождение: String
    let оригинал: ОригиналЛокальногоСообщения?
}

private struct ЛокальнаяПроверка: Codable, Sendable {
    let название: String
    let исход: ИсходЛокальнойПроверки
    let код: Int?
    let наносекунды: Int64?
    let свидетельство: String
}

private struct ЛокальнаяДоставка: Codable, Sendable {
    let вид: String
    let идентификатор: String
    let свидетельство: String
}

private struct ВходЛокальногоЖурнала: Codable, Sendable {
    let схема: String
    let экземпляр: ЭкземплярЛокальногоЖурнала
    let время: String
    let область: String
    let публичная: Bool
    let происхождение: [String]
    let сообщения: [ЛокальноеСообщение]
    let решения: [String]
    let проверки: [ЛокальнаяПроверка]
    let исход: String
    let остаток: [String]
    let доставка: [ЛокальнаяДоставка]
}

private func проверитьВход(
    _ вход: ВходЛокальногоЖурнала,
    назначение: НазначениеИсполнителяПакета
) throws {
    guard вход.схема == "fum.вход-локальной-записи.1",
          вход.экземпляр.корень == назначение.корневойUUID,
          вход.экземпляр.писатель == назначение.uuidИсполнителя,
          вход.экземпляр.писатель != вход.экземпляр.корень,
          вход.экземпляр.номер > 0,
          !вход.экземпляр.стадия.isEmpty,
          вход.экземпляр.стадия.utf8.count <= 128,
          !вход.экземпляр.стадия.unicodeScalars.contains(
            where: CharacterSet.controlCharacters.contains),
          вход.область == назначение.область,
          вход.публичная,
          !вход.происхождение.isEmpty,
          !вход.исход.isEmpty else {
        throw ОшибкаИсполнителяПакета.неверныйВход
    }

    let формат = ISO8601DateFormatter()
    формат.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let сДолямиСекунды = формат.date(from: вход.время)
    формат.formatOptions = [.withInternetDateTime]
    guard сДолямиСекунды != nil || формат.date(from: вход.время) != nil else {
        throw ОшибкаИсполнителяПакета.неверныйВход
    }

    for сообщение in вход.сообщения {
        guard !сообщение.происхождение.isEmpty else {
            throw ОшибкаИсполнителяПакета.неверныйВход
        }
        switch сообщение.вид {
        case .производное:
            guard let оригинал = сообщение.оригинал,
                  оригинал.байтов >= 0,
                  шестнадцатеричный(оригинал.sha256, длина: 64),
                  !оригинал.источник.isEmpty else {
                throw ОшибкаИсполнителяПакета.неверныйВход
            }
        case .буквальное:
            guard сообщение.оригинал == nil else {
                throw ОшибкаИсполнителяПакета.неверныйВход
            }
        }
    }

    for проверка in вход.проверки {
        guard !проверка.название.isEmpty,
              !проверка.свидетельство.isEmpty,
              проверка.наносекунды.map({ $0 >= 0 }) ?? true else {
            throw ОшибкаИсполнителяПакета.неверныйВход
        }
        switch проверка.исход {
        case .успешно:
            guard проверка.код == 0, проверка.наносекунды != nil else {
                throw ОшибкаИсполнителяПакета.неверныйВход
            }
        case .неуспешно:
            guard let код = проверка.код, код != 0,
                  проверка.наносекунды != nil else {
                throw ОшибкаИсполнителяПакета.неверныйВход
            }
        case .неПроверено:
            guard проверка.код == nil, проверка.наносекунды == nil else {
                throw ОшибкаИсполнителяПакета.неверныйВход
            }
        case .прервано, .неизвестно:
            break
        }
    }

    guard вход.доставка.allSatisfy({
        !$0.вид.isEmpty && !$0.идентификатор.isEmpty && !$0.свидетельство.isEmpty
    }) else {
        throw ОшибкаИсполнителяПакета.неверныйВход
    }
    try проверитьПубличностьВхода(вход)
}

private func проверитьПубличностьВхода(_ вход: ВходЛокальногоЖурнала) throws {
    let данные = try JSONEncoder().encode(вход)
    let значение = try JSONSerialization.jsonObject(with: данные)
    try проверитьПубличныеЗначения(значение)
}

private func проверитьПубличныеЗначения(_ значение: Any) throws {
    switch значение {
    case let строка as String:
        try проверитьОтсутствиеСекретов(строка)
        var проверяемая = строка.replacingOccurrences(
            of: "<область>/zhurnal", with: "〈шаблон〉")
        let веб = try NSRegularExpression(pattern: #"https?://[^\s<>\"\\]+"#)
        let диапазон = NSRange(проверяемая.startIndex..., in: проверяемая)
        for совпадение in веб.matches(in: проверяемая, range: диапазон).reversed() {
            guard let диапазонСовпадения = Range(совпадение.range, in: проверяемая),
                  let адрес = URLComponents(
                    string: String(проверяемая[диапазонСовпадения])),
                  let сервер = адрес.host, !сервер.isEmpty else { continue }
            try проверитьПубличныйWebАдрес(адрес, сервер: сервер)
            проверяемая.replaceSubrange(диапазонСовпадения, with: "〈веб-источник〉")
        }
        for вариант in try вариантыПроцентногоРаскрытия(проверяемая) {
            try проверитьОтсутствиеПриватныхПутей(вариант)
        }
    case let массив as [Any]:
        for элемент in массив { try проверитьПубличныеЗначения(элемент) }
    case let объект as [String: Any]:
        for (ключ, элемент) in объект {
            try проверитьПубличныеЗначения(ключ)
            try проверитьПубличныеЗначения(элемент)
        }
    default:
        break
    }
}

private func проверитьОтсутствиеСекретов(_ строка: String) throws {
    let шаблоны = [
        #"-----BEGIN [A-Z ]*PRIVATE KEY-----"#,
        #"\bAKIA[0-9A-Z]{16}\b"#,
        #"(?i:gh[pousr]_[A-Za-z0-9_-]{20,})"#,
        #"(?i:github_pat_[A-Za-z0-9_-]{20,})"#,
        #"(?i:\bauthorization\s*:\s*bearer\s+[^\s,;]+)"#,
        #"sk-[A-Za-z0-9_-]{20,}"#
    ]
    let выражение = try NSRegularExpression(pattern: шаблоны.joined(separator: "|"))
    for вариант in try вариантыПроцентногоРаскрытия(строка) {
        let диапазон = NSRange(вариант.startIndex..., in: вариант)
        guard выражение.firstMatch(in: вариант, range: диапазон) == nil else {
            throw ОшибкаИсполнителяПакета.неверныйВход
        }
    }
}

private func проверитьПубличныйWebАдрес(
    _ адрес: URLComponents,
    сервер: String
) throws {
    guard адрес.user?.isEmpty != false,
          адрес.password?.isEmpty != false,
          !локальныйИлиПриватныйСервер(сервер) else {
        throw ОшибкаИсполнителяПакета.неверныйВход
    }
    for часть in [
        адрес.percentEncodedUser,
        адрес.percentEncodedPassword,
        адрес.percentEncodedQuery,
        адрес.percentEncodedFragment
    ].compactMap({ $0 }) {
        try проверитьОтсутствиеСекретов(часть)
        for вариант in try вариантыПроцентногоРаскрытия(часть) {
            try проверитьОтсутствиеПриватныхПутей(вариант)
        }
    }
}

private func локальныйИлиПриватныйСервер(_ сервер: String) -> Bool {
    var имя = сервер.lowercased()
    while имя.hasSuffix(".") { имя.removeLast() }
    if имя == "localhost" || имя.hasSuffix(".localhost") || имя.hasSuffix(".local") {
        return true
    }
    if let зона = имя.firstIndex(of: "%") { имя = String(имя[..<зона]) }
    if let байты = байтыIPv4(имя) {
        return приватныйIPv4(байты)
    }
    if let байты = байтыIPv6(имя) {
        if байты == Array(repeating: 0, count: 16)
            || байты == Array(repeating: 0, count: 15) + [1]
            || байты[0] & 0xfe == 0xfc
            || (байты[0] == 0xfe && байты[1] & 0xc0 == 0x80) {
            return true
        }
        if байты.prefix(10).allSatisfy({ $0 == 0 }),
           байты[10] == 0xff, байты[11] == 0xff {
            return приватныйIPv4(Array(байты[12...15]))
        }
    }
    return false
}

private func вариантыПроцентногоРаскрытия(_ строка: String) throws -> [String] {
    var варианты = [строка]
    var текущая = строка
    for _ in 0..<8 {
        guard содержитПроцентныйОктет(текущая) else { return варианты }
        guard let раскрытая = текущая.removingPercentEncoding else {
            throw ОшибкаИсполнителяПакета.неверныйВход
        }
        if раскрытая == текущая { return варианты }
        варианты.append(раскрытая)
        текущая = раскрытая
    }
    guard !содержитПроцентныйОктет(текущая) else {
        throw ОшибкаИсполнителяПакета.неверныйВход
    }
    return варианты
}

private func содержитПроцентныйОктет(_ строка: String) -> Bool {
    строка.range(of: #"%[0-9A-Fa-f]{2}"#, options: .regularExpression) != nil
}

private func проверитьОтсутствиеПриватныхПутей(_ строка: String) throws {
    let шаблоны = [
        #"(?<![\p{L}\p{N}._/\-])/[^\s<>\"\\]+"#,
        #"(?i:\b[a-z]:[\\/])"#,
        #"(?i:file://)"#,
        #"(?i:~[/\\])"#,
        #"\\\\[^\\\s]+\\"#
    ]
    let выражение = try NSRegularExpression(pattern: шаблоны.joined(separator: "|"))
    let диапазон = NSRange(строка.startIndex..., in: строка)
    guard выражение.firstMatch(in: строка, range: диапазон) == nil else {
        throw ОшибкаИсполнителяПакета.неверныйВход
    }
}

private func байтыIPv4(_ строка: String) -> [UInt8]? {
    var адрес = in_addr()
    guard строка.withCString({ inet_aton($0, &адрес) }) != 0 else { return nil }
    return withUnsafeBytes(of: &адрес) { Array($0) }
}

private func байтыIPv6(_ строка: String) -> [UInt8]? {
    var адрес = in6_addr()
    let принят = строка.withCString { указатель in
        inet_pton(AF_INET6, указатель, &адрес)
    }
    guard принят == 1 else { return nil }
    return withUnsafeBytes(of: &адрес) { Array($0) }
}

private func приватныйIPv4(_ байты: [UInt8]) -> Bool {
    guard байты.count == 4 else { return true }
    return байты[0] == 0 || байты[0] == 10 || байты[0] == 127
        || (байты[0] == 100 && (64...127).contains(байты[1]))
        || (байты[0] == 169 && байты[1] == 254)
        || (байты[0] == 172 && (16...31).contains(байты[1]))
        || (байты[0] == 192 && байты[1] == 168)
        || (байты[0] == 198 && (18...19).contains(байты[1]))
        || байты == [255, 255, 255, 255]
}

private struct ЦельПланаПакета: Codable, Sendable {
    let хэшКорня: String
    let область: String
    let узлы: [String]

    enum CodingKeys: String, CodingKey {
        case хэшКорня = "кореньSHA256"
        case область, узлы
    }
}

private struct ПланПакета: Codable, Sendable {
    let схема: String
    let цель: ЦельПланаПакета
    let идентификатор: String
    let путь: String
    let хэшВхода: String
    let хэшОператора: String
    let хэшСодержания: String
    let байты: Data

    enum CodingKeys: String, CodingKey {
        case схема, цель, идентификатор, путь, байты
        case хэшВхода = "входSHA256"
        case хэшОператора = "операторSHA256"
        case хэшСодержания = "содержаниеSHA256"
    }
}

private struct ОтветПланаПакета: Codable, Sendable {
    let схема: String
    let план: ПланПакета
}

private struct ОтветПримененияПакета: Codable, Sendable {
    enum Вид: String, Codable, Sendable { case установлена, наблюдена }
    let вид: Вид
    let путь: String
    let хэшСодержания: String

    enum CodingKeys: String, CodingKey {
        case вид, путь
        case хэшСодержания = "содержаниеSHA256"
    }
}

private struct НамерениеApplyПакета: Codable, Sendable {
    let схема: String
    let операция: String
    let uuidИсполнителя: String
    let ref: String
    let базовыйOID: String
    let физическийКореньSHA256: String
    let applyArgvSHA256: String
    let входSHA256: String
    let планSHA256: String
    let идентификаторЗаписи: String
    let путьЗаписи: String
    let содержаниеSHA256: String

    enum CodingKeys: String, CodingKey {
        case схема, операция, ref
        case uuidИсполнителя = "uuid_исполнителя"
        case базовыйOID = "базовый_oid"
        case физическийКореньSHA256 = "физический_корень_sha256"
        case applyArgvSHA256 = "apply_argv_sha256"
        case входSHA256 = "вход_sha256"
        case планSHA256 = "план_sha256"
        case идентификаторЗаписи = "идентификатор_записи"
        case путьЗаписи = "путь_записи"
        case содержаниеSHA256 = "содержание_sha256"
    }
}

private struct ИсходApplyПакета: Codable, Sendable {
    let схема: String
    let операция: String
    let состояние: СостояниеВызоваApplyПакета
    let код: Int32?
    let завершениеПодтверждено: Bool?
    let stdoutSHA256: String?
    let stdoutБайтов: Int?
    let stderrSHA256: String?
    let stderrБайтов: Int?

    enum CodingKeys: String, CodingKey {
        case схема, операция, состояние, код
        case завершениеПодтверждено = "завершение_подтверждено"
        case stdoutSHA256 = "stdout_sha256"
        case stdoutБайтов = "stdout_байтов"
        case stderrSHA256 = "stderr_sha256"
        case stderrБайтов = "stderr_байтов"
    }
}

private func сформироватьНамерениеApply(
    запрос: ЗапросИсполненияПакета,
    план: ОтветПланаПакета,
    байтыПлана: Data
) throws -> Data {
    return try каноническиеДанные(НамерениеApplyПакета(
        схема: "fum.намерение-apply-пакета-локального-журнала.1",
        операция: идентификаторОперации(запрос),
        uuidИсполнителя: запрос.назначение.uuidИсполнителя,
        ref: запрос.назначение.ref,
        базовыйOID: запрос.назначение.базовыйOID,
        физическийКореньSHA256: sha256Пакета(
            Data(запрос.назначение.физическийКорень.path.utf8)),
        applyArgvSHA256: отпечатокArgvApply(запрос),
        входSHA256: sha256Пакета(запрос.входныеБайты),
        планSHA256: sha256Пакета(байтыПлана),
        идентификаторЗаписи: план.план.идентификатор,
        путьЗаписи: план.план.путь,
        содержаниеSHA256: план.план.хэшСодержания))
}

private func сформироватьИсходApply(
    запрос: ЗапросИсполненияПакета,
    состояние: СостояниеВызоваApplyПакета,
    результат: РезультатПроцессаПакета?
) throws -> Data {
    guard состояние != .неВызывался,
          (состояние == .завершён) == (результат != nil) else {
        throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
    }
    return try каноническиеДанные(ИсходApplyПакета(
        схема: "fum.исход-apply-пакета-локального-журнала.1",
        операция: идентификаторОперации(запрос),
        состояние: состояние,
        код: результат?.код,
        завершениеПодтверждено: результат?.завершениеПодтверждено,
        stdoutSHA256: результат.map { sha256Пакета($0.stdout) },
        stdoutБайтов: результат?.stdout.count,
        stderrSHA256: результат.map { sha256Пакета($0.stderr) },
        stderrБайтов: результат?.stderr.count))
}

private func разобратьИсходApply(
    _ данные: Data,
    запрос: ЗапросИсполненияПакета
) throws -> ИсходApplyПакета {
    let исход: ИсходApplyПакета
    do { исход = try закрытоРазобрать(ИсходApplyПакета.self, из: данные) }
    catch { throw ОшибкаИсполнителяПакета.конфликтРабочихБайт }
    let поляРезультата = [
        исход.код != nil,
        исход.завершениеПодтверждено != nil,
        исход.stdoutSHA256 != nil,
        исход.stdoutБайтов != nil,
        исход.stderrSHA256 != nil,
        исход.stderrБайтов != nil
    ]
    guard исход.схема == "fum.исход-apply-пакета-локального-журнала.1",
          исход.операция == идентификаторОперации(запрос),
          исход.состояние != .неВызывался,
          (исход.состояние == .завершён
            ? поляРезультата.allSatisfy({ $0 })
            : поляРезультата.allSatisfy({ !$0 })),
          исход.stdoutSHA256.map({ шестнадцатеричный($0, длина: 64) }) ?? true,
          исход.stderrSHA256.map({ шестнадцатеричный($0, длина: 64) }) ?? true,
          исход.stdoutБайтов.map({ $0 >= 0 }) ?? true,
          исход.stderrБайтов.map({ $0 >= 0 }) ?? true else {
        throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
    }
    return исход
}

private func идентификаторОперации(_ запрос: ЗапросИсполненияПакета) -> String {
    let назначение = запрос.назначение
    let основа = [
        String(назначение.версияКоррекцииДопуска),
        назначение.коммитПостановки,
        назначение.деревоПостановки,
        назначение.родительПостановки,
        назначение.blobПостановки,
        назначение.sha256Постановки,
        назначение.sha256Пакета,
        назначение.путьDriver,
        назначение.sha256Driver,
        назначение.ресурсыDriverSHA256,
        назначение.коммитИсточника,
        назначение.деревоИсточника,
        назначение.blobЗакреплений,
        назначение.sha256ФайлаЗакреплений,
        назначение.исходнаяКартаSHA256,
        назначение.коммитТекущейКарты,
        назначение.деревоТекущейКарты,
        назначение.текущаяКартаSHA256,
        sha256Пакета(Data(назначение.основаниеТекущихОтличий.utf8)),
        назначение.исходникиИсполнителяКартаSHA256,
        назначение.корневойUUID,
        назначение.uuidИсполнителя,
        назначение.физическийКорень.path,
        назначение.ref,
        назначение.базовыйOID,
        назначение.область,
        sha256Пакета(запрос.входныеБайты)
    ].joined(separator: "\u{0}")
    return sha256Пакета(Data(основа.utf8))
}

private func отпечатокArgvApply(_ запрос: ЗапросИсполненияПакета) -> String {
    let назначение = запрос.назначение
    let argv = [
        назначение.путьDriver,
        "журнал", "применить",
        "--корень", назначение.физическийКорень.path,
        "--вход", запрос.рабочиеФайлы.вход.path,
        "--план", запрос.рабочиеФайлы.план.path
    ]
    return sha256Пакета(Data(argv.joined(separator: "\u{0}").utf8))
}

private func проверитьИсправленныйДопускV2(
    _ запрос: ЗапросИсполненияПакета
) throws {
    let назначение = запрос.назначение
    try проверитьНазначение(назначение)
    let источник = Dictionary(
        uniqueKeysWithValues: назначение.закрепленияИсточника.map { ($0.путь, $0.sha256) })
    let текущий = Dictionary(
        uniqueKeysWithValues: назначение.закрепленияТекущегоCheckout.map {
            ($0.путь, $0.sha256)
        })
    guard назначение.версияКоррекцииДопуска
            == ИсправленныйДопускИсполнителяПакетаV2.версия,
          назначение.корневойUUID
            == ИсправленныйДопускИсполнителяПакетаV2.корневойUUID,
          назначение.uuidИсполнителя
            == ИсправленныйДопускИсполнителяПакетаV2.uuidИсполнителя,
          назначение.ref == ИсправленныйДопускИсполнителяПакетаV2.ref,
          назначение.базовыйOID
            == ИсправленныйДопускИсполнителяПакетаV2.базовыйOID,
          назначение.область == ИсправленныйДопускИсполнителяПакетаV2.область,
          назначение.коммитПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.коммитПостановки,
          назначение.деревоПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.деревоПостановки,
          назначение.родительПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.родительПостановки,
          назначение.путьПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.путьПостановки,
          назначение.blobПостановки
            == ИсправленныйДопускИсполнителяПакетаV2.blobПостановки,
          назначение.sha256Постановки
            == ИсправленныйДопускИсполнителяПакетаV2.sha256Постановки,
          назначение.sha256Пакета
            == ИсправленныйДопускИсполнителяПакетаV2.sha256Пакета,
          назначение.байтовПакета
            == ИсправленныйДопускИсполнителяПакетаV2.байтовПакета,
          назначение.sha256Driver
            == ИсправленныйДопускИсполнителяПакетаV2.sha256Driver,
          назначение.байтовDriver
            == ИсправленныйДопускИсполнителяПакетаV2.байтовDriver,
          назначение.ресурсыDriverSHA256
            == ИсправленныйДопускИсполнителяПакетаV2.ресурсыDriverSHA256,
          назначение.коммитИсточника
            == ИсправленныйДопускИсполнителяПакетаV2.коммитИсточника,
          назначение.деревоИсточника
            == ИсправленныйДопускИсполнителяПакетаV2.деревоИсточника,
          назначение.путьЗакреплений
            == ИсправленныйДопускИсполнителяПакетаV2.путьЗакреплений,
          назначение.blobЗакреплений
            == ИсправленныйДопускИсполнителяПакетаV2.blobЗакреплений,
          назначение.sha256ФайлаЗакреплений
            == ИсправленныйДопускИсполнителяПакетаV2.sha256ФайлаЗакреплений,
          назначение.числоЗакреплений
            == ИсправленныйДопускИсполнителяПакетаV2.числоЗакреплений,
          назначение.путьРезультатаСборки
            == ИсправленныйДопускИсполнителяПакетаV2.путьРезультатаСборки,
          назначение.исходнаяКартаSHA256
            == ИсправленныйДопускИсполнителяПакетаV2.исходнаяКартаSHA256,
          назначение.коммитТекущейКарты
            == ИсправленныйДопускИсполнителяПакетаV2.коммитТекущейКарты,
          назначение.деревоТекущейКарты
            == ИсправленныйДопускИсполнителяПакетаV2.деревоТекущейКарты,
          назначение.текущаяКартаSHA256
            == ИсправленныйДопускИсполнителяПакетаV2.текущаяКартаSHA256,
          назначение.основаниеТекущихОтличий
            == ИсправленныйДопускИсполнителяПакетаV2.основаниеТекущихОтличий,
          источник["Package.swift"]
            == ИсправленныйДопускИсполнителяПакетаV2.исходныйPackageSHA256,
          текущий["Package.swift"]
            == ИсправленныйДопускИсполнителяПакетаV2.текущийPackageSHA256,
          запрос.наблюдениеACK.модель == "gpt-5.6-sol",
          запрос.наблюдениеACK.усилие == "ultra" else {
        throw ОшибкаИсполнителяПакета.неверноеНазначение
    }
}

private func проверитьНазначение(_ назначение: НазначениеИсполнителяПакета) throws {
    let исходнаяКартаSHA256 = try sha256КаноническойКарты(
        назначение.закрепленияИсточника)
    let текущаяКартаSHA256 = try sha256КаноническойКарты(
        назначение.закрепленияТекущегоCheckout)
    let исходникиИсполнителяКартаSHA256 = try sha256КаноническойКарты(
        назначение.закрепленияИсполнителя)
    guard назначение.resolvedJournal == .localFUMA,
          назначение.версияКоррекцииДопуска > 0,
          UUID(uuidString: назначение.корневойUUID)?.uuidString.lowercased()
            == назначение.корневойUUID,
          UUID(uuidString: назначение.uuidИсполнителя)?.uuidString.lowercased()
            == назначение.uuidИсполнителя,
          назначение.корневойUUID != назначение.uuidИсполнителя,
          назначение.ref.hasPrefix("refs/heads/"),
          шестнадцатеричный(назначение.базовыйOID, длина: 40),
          шестнадцатеричный(назначение.коммитПостановки, длина: 40),
          шестнадцатеричный(назначение.деревоПостановки, длина: 40),
          шестнадцатеричный(назначение.родительПостановки, длина: 40),
          шестнадцатеричный(назначение.blobПостановки, длина: 40),
          шестнадцатеричный(назначение.sha256Постановки, длина: 64),
          URL(fileURLWithPath: назначение.путьПакета).standardizedFileURL.path
            == назначение.путьПакета,
          !назначение.путьПакета.contains("<"), !назначение.путьПакета.contains(">"),
          шестнадцатеричный(назначение.sha256Пакета, длина: 64),
          назначение.байтовПакета > 0,
          URL(fileURLWithPath: назначение.путьDriver).standardizedFileURL.path
            == назначение.путьDriver,
          !назначение.путьDriver.contains("<"), !назначение.путьDriver.contains(">"),
          шестнадцатеричный(назначение.sha256Driver, длина: 64),
          назначение.байтовDriver > 0,
          шестнадцатеричный(назначение.ресурсыDriverSHA256, длина: 64),
          назначение.коммитИсточника == "c6af44bf1ec061675b6205b9c6ee889d98264f28",
          шестнадцатеричный(назначение.деревоИсточника, длина: 40),
          назначение.путьЗакреплений == "zhurnal/384-build.nachalo.json",
          шестнадцатеричный(назначение.blobЗакреплений, длина: 40),
          шестнадцатеричный(назначение.sha256ФайлаЗакреплений, длина: 64),
          назначение.числоЗакреплений == 34,
          назначение.путьРезультатаСборки == "zhurnal/384-build.iskhod.json",
          шестнадцатеричный(назначение.коммитТекущейКарты, длина: 40),
          шестнадцатеричный(назначение.деревоТекущейКарты, длина: 40),
          шестнадцатеричный(назначение.исходнаяКартаSHA256, длина: 64),
          шестнадцатеричный(назначение.текущаяКартаSHA256, длина: 64),
          шестнадцатеричный(
            назначение.исходникиИсполнителяКартаSHA256, длина: 64),
          назначение.ресурсыDriverSHA256
            == sha256Закреплений(назначение.закрепленияРесурсовDriver),
          назначение.исходнаяКартаSHA256 == исходнаяКартаSHA256,
          назначение.текущаяКартаSHA256 == текущаяКартаSHA256,
          назначение.исходникиИсполнителяКартаSHA256
            == исходникиИсполнителяКартаSHA256,
          !назначение.основаниеТекущихОтличий.isEmpty,
          безопасныйОтносительныйПуть(назначение.область),
          безопасныйОтносительныйПуть(назначение.путьПостановки),
          безопасныйОтносительныйПуть(назначение.путьЗакреплений),
          безопасныйОтносительныйПуть(назначение.путьРезультатаСборки),
          назначение.закрепленияИсточника.count == назначение.числоЗакреплений,
          назначение.закрепленияТекущегоCheckout.count == назначение.числоЗакреплений,
          назначение.разрешённыеТекущиеОтличия == ["Package.swift"],
          Set(назначение.закрепленияРесурсовDriver.map(\.путь))
            == ожидаемыеПутиРесурсовDriver,
          Set(назначение.закрепленияИсполнителя.map(\.путь))
            == ожидаемыеПутиИсходниковИсполнителя else {
        throw ОшибкаИсполнителяПакета.неверноеНазначение
    }
    try проверитьЗакрепленияИсполнителя(назначение.закрепленияРесурсовDriver)
    try проверитьЗакрепленияИсполнителя(назначение.закрепленияИсточника)
    try проверитьЗакрепленияИсполнителя(назначение.закрепленияТекущегоCheckout)
    try проверитьЗакрепленияИсполнителя(назначение.закрепленияИсполнителя)
    let источник = Dictionary(
        uniqueKeysWithValues: назначение.закрепленияИсточника.map { ($0.путь, $0.sha256) })
    let текущий = Dictionary(
        uniqueKeysWithValues: назначение.закрепленияТекущегоCheckout.map { ($0.путь, $0.sha256) })
    let отличия = источник.keys.filter { источник[$0] != текущий[$0] }.sorted()
    guard Set(источник.keys) == Set(текущий.keys),
          отличия == назначение.разрешённыеТекущиеОтличия,
          Set(источник.keys).isDisjoint(with: ожидаемыеПутиИсходниковИсполнителя) else {
        throw ОшибкаИсполнителяПакета.неверноеНазначение
    }
}

private func проверитьПакет(
    _ пакет: ПакетЛокальногоЖурнала,
    назначение: НазначениеИсполнителяПакета
) throws {
    let ожидаемыеКоманды = [
        ["<driver>", "журнал", "помощь"],
        ["<driver>", "журнал", "план", "--корень", "<собственный физический W/FUM>",
         "--вход", "<приватный input.json>"],
        ["<driver>", "журнал", "применить", "--корень", "<тот же W>",
         "--вход", "<те же байты input>", "--план", "<сохранённый exact stdout plan.json>"]
    ]
    guard пакет.схема == "fum.пакет-локального-журнала.1",
          !пакет.назначение.isEmpty,
          пакет.driver.путь == назначение.путьDriver,
          пакет.driver.sha256 == назначение.sha256Driver,
          !пакет.driver.ресурсы.isEmpty,
          URL(fileURLWithPath: пакет.driver.путь).path == пакет.driver.путь,
          пакет.источник.коммит == назначение.коммитИсточника,
          пакет.источник.закрепления == назначение.путьЗакреплений,
          пакет.источник.полеЗакреплений == "входные_закрепления",
          пакет.источник.числоЗакреплений == назначение.числоЗакреплений,
          пакет.источник.результат == назначение.путьРезультатаСборки,
          !пакет.источник.руководство.isEmpty, !пакет.источник.модель.isEmpty,
          пакет.командыArgv == ожидаемыеКоманды,
          !пакет.обязательнаяПодстановка.isEmpty,
          !пакет.границы.isEmpty, пакет.границы.allSatisfy({ !$0.isEmpty }),
          пакет.вход.схема == "fum.вход-локальной-записи.1",
          пакет.вход.экземпляр.корень == назначение.корневойUUID,
          пакет.вход.экземпляр.писатель == "<собственный UUID>",
          пакет.вход.экземпляр.стадия == "<ограниченный текущий этап>",
          пакет.вход.экземпляр.номер == 1,
          пакет.вход.время == "<фактическое время ISO8601>",
          пакет.вход.область == "<собственный key без конечного slash>",
          пакет.вход.публичная,
          пакет.вход.происхождение.isEmpty, пакет.вход.сообщения.isEmpty,
          пакет.вход.решения.isEmpty, пакет.вход.проверки.isEmpty,
          пакет.вход.исход == "<фактический>", пакет.вход.остаток.isEmpty,
          пакет.вход.доставка.isEmpty else {
        throw ОшибкаИсполнителяПакета.неверныйПакет
    }
}

private func проверитьПостановку(
    _ наблюдение: НаблюдениеПостановкиИсполнителяПакета,
    назначение: НазначениеИсполнителяПакета
) throws {
    guard наблюдение.коммит == назначение.коммитПостановки,
          наблюдение.дерево == назначение.деревоПостановки,
          наблюдение.родитель == назначение.родительПостановки,
          наблюдение.путь == назначение.путьПостановки,
          наблюдение.blob == назначение.blobПостановки,
          наблюдение.sha256 == назначение.sha256Постановки else {
        throw ОшибкаИсполнителяПакета.неверноеНазначение
    }
}

private func проверитьACK(
    _ наблюдение: НаблюдениеACKИсполнителяПакета,
    назначение: НазначениеИсполнителяПакета
) throws {
    guard наблюдение.подтверждён,
          наблюдение.uuidИсполнителя == назначение.uuidИсполнителя,
          наблюдение.физическийКорень.standardizedFileURL.path
            == назначение.физическийКорень.standardizedFileURL.path,
          наблюдение.ref == назначение.ref,
          наблюдение.headOID == назначение.базовыйOID,
          !наблюдение.модель.isEmpty, !наблюдение.усилие.isEmpty else {
        throw ОшибкаИсполнителяПакета.неверноеНазначение
    }
}

private func проверитьПривязку(
    _ наблюдение: НаблюдениеФизическойПривязкиПакета,
    назначение: НазначениеИсполнителяПакета
) throws {
    let корень = назначение.физическийКорень.standardizedFileURL
    guard корень.path == назначение.физическийКорень.path,
          наблюдение.физическийКорень.standardizedFileURL.path == корень.path,
          наблюдение.ref == назначение.ref,
          наблюдение.headOID == назначение.базовыйOID,
          наблюдение.чисто, наблюдение.единственныйПисатель else {
        throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
    }
    try ФайлыИсполнителяПакета.проверитьКаталогБезСсылок(корень)
    try ФайлыИсполнителяПакета.проверитьHEAD(
        корень: корень, ref: назначение.ref, oid: назначение.базовыйOID)
    try ФайлыИсполнителяПакета.проверитьКаталогБезСсылок(
        корень.appendingPathComponent(назначение.область))
    try ФайлыИсполнителяПакета.проверитьКаталогБезСсылок(
        корень.appendingPathComponent(назначение.область)
            .appendingPathComponent("zhurnal"))
}

private func проверитьЗакрепления(
    _ наблюдение: НаблюдениеЗакрепленийИсточникаПакета,
    назначение: НазначениеИсполнителяПакета
) throws {
    guard наблюдение.коммит == назначение.коммитИсточника,
          наблюдение.деревоИсточника == назначение.деревоИсточника,
          наблюдение.путьЗакреплений == назначение.путьЗакреплений,
          наблюдение.blobЗакреплений == назначение.blobЗакреплений,
          наблюдение.sha256ФайлаЗакреплений
            == назначение.sha256ФайлаЗакреплений,
          наблюдение.путьРезультатаСборки == назначение.путьРезультатаСборки,
          наблюдение.числоЗакреплений == назначение.числоЗакреплений,
          наблюдение.совпавшихЗакреплений == назначение.числоЗакреплений,
          наблюдение.закрепленияИсточника == назначение.закрепленияИсточника,
          наблюдение.исходнаяКартаSHA256 == назначение.исходнаяКартаSHA256,
          наблюдение.коммитТекущейКарты == назначение.коммитТекущейКарты,
          наблюдение.деревоТекущейКарты == назначение.деревоТекущейКарты,
          наблюдение.закрепленияТекущегоCheckout
            == назначение.закрепленияТекущегоCheckout,
          наблюдение.текущаяКартаSHA256 == назначение.текущаяКартаSHA256,
          наблюдение.текущиеОтличия == назначение.разрешённыеТекущиеОтличия,
          наблюдение.закрепленияИсполнителя == назначение.закрепленияИсполнителя,
          наблюдение.исходникиИсполнителяКартаSHA256
            == назначение.исходникиИсполнителяКартаSHA256,
          наблюдение.ресурсыDriverSHA256 == назначение.ресурсыDriverSHA256 else {
        throw ОшибкаИсполнителяПакета.неверныеЗакрепления
    }
    try проверитьЗакрепленияИсполнителя(наблюдение.закрепленияИсточника)
    try проверитьЗакрепленияИсполнителя(наблюдение.закрепленияТекущегоCheckout)
    try проверитьЗакрепленияИсполнителя(наблюдение.закрепленияИсполнителя)
}

private func проверитьТекущиеФайлы(
    назначение: НазначениеИсполнителяПакета
) throws {
    for закрепление in назначение.закрепленияТекущегоCheckout
        + назначение.закрепленияИсполнителя {
        let url = назначение.физическийКорень.appendingPathComponent(закрепление.путь)
        let байты: Data
        do { байты = try ФайлыИсполнителяПакета.прочитатьТочно(url) }
        catch { throw ОшибкаИсполнителяПакета.неверныеЗакрепления }
        guard sha256Пакета(байты) == закрепление.sha256 else {
            throw ОшибкаИсполнителяПакета.неверныеЗакрепления
        }
    }
}

private func проверитьРесурсыDriver(
    driver: URL,
    закрепления: [ЗакреплениеИсходникаИсполнителяПакета]
) throws {
    let база = driver.deletingLastPathComponent().standardizedFileURL
    var найденные: Set<String> = []
    for имяBundle in [
        "FUMA_FUMStructuringOperatorMemory.bundle",
        "FUMA_ЖурналУзла.bundle"
    ] {
        let bundle = база.appendingPathComponent(имяBundle, isDirectory: true)
        try ФайлыИсполнителяПакета.проверитьКаталогБезСсылок(bundle)
        найденные.formUnion(try перечислитьОбычныеФайлы(
            в: bundle, относительно: база))
    }
    guard найденные == ожидаемыеПутиРесурсовDriver else {
        throw ОшибкаИсполнителяПакета.неверныйDriver
    }
    for закрепление in закрепления {
        let url = база.appendingPathComponent(закрепление.путь)
        let байты: Data
        do { байты = try ФайлыИсполнителяПакета.прочитатьТочно(url) }
        catch { throw ОшибкаИсполнителяПакета.неверныйDriver }
        guard sha256Пакета(байты) == закрепление.sha256 else {
            throw ОшибкаИсполнителяПакета.неверныйDriver
        }
    }
}

private func перечислитьОбычныеФайлы(
    в каталог: URL,
    относительно база: URL
) throws -> Set<String> {
    var результат: Set<String> = []
    let имена: [String]
    do { имена = try FileManager.default.contentsOfDirectory(atPath: каталог.path) }
    catch { throw ОшибкаИсполнителяПакета.неверныйDriver }
    for имя in имена {
        guard !имя.isEmpty, имя != ".", имя != "..", !имя.contains("/") else {
            throw ОшибкаИсполнителяПакета.неверныйDriver
        }
        let url = каталог.appendingPathComponent(имя)
        var сведения = stat()
        guard lstat(url.path, &сведения) == 0 else {
            throw ОшибкаИсполнителяПакета.неверныйDriver
        }
        switch сведения.st_mode & S_IFMT {
        case S_IFDIR:
            guard url.standardizedFileURL.resolvingSymlinksInPath().path
                    == url.standardizedFileURL.path else {
                throw ОшибкаИсполнителяПакета.неверныйDriver
            }
            результат.formUnion(try перечислитьОбычныеФайлы(
                в: url, относительно: база))
        case S_IFREG:
            let префикс = база.path + "/"
            guard сведения.st_nlink == 1, url.path.hasPrefix(префикс) else {
                throw ОшибкаИсполнителяПакета.неверныйDriver
            }
            результат.insert(String(url.path.dropFirst(префикс.count)))
        default:
            throw ОшибкаИсполнителяПакета.неверныйDriver
        }
    }
    return результат
}

private func проверитьЗакрепленияИсполнителя(
    _ закрепления: [ЗакреплениеИсходникаИсполнителяПакета]
) throws {
    guard Set(закрепления.map(\.путь)).count == закрепления.count else {
        throw ОшибкаИсполнителяПакета.неверныеЗакрепления
    }
    for закрепление in закрепления {
        guard безопасныйОтносительныйПуть(закрепление.путь),
              шестнадцатеричный(закрепление.sha256, длина: 64) else {
            throw ОшибкаИсполнителяПакета.неверныеЗакрепления
        }
    }
}

private func проверитьРабочиеФайлы(_ запрос: ЗапросИсполненияПакета) throws {
    let файлы = запрос.рабочиеФайлы
    let назначение = запрос.назначение
    try ФайлыИсполнителяПакета.проверитьКаталогБезСсылок(файлы.каталог)
    let каталог = файлы.каталог.standardizedFileURL.path
    let пути = [файлы.вход, файлы.план, файлы.намерениеApply, файлы.исходApply]
        .map { $0.standardizedFileURL }
    let корень = назначение.физическийКорень.standardizedFileURL.path
    let ожидаемыйКаталог = запрос.пакет.deletingLastPathComponent()
        .appendingPathComponent("ispolneniye", isDirectory: true)
        .appendingPathComponent(идентификаторОперации(запрос), isDirectory: true)
        .standardizedFileURL.path
    guard каталог == ожидаемыйКаталог,
          файлы.вход.lastPathComponent == "input.json",
          файлы.план.lastPathComponent == "plan.json",
          файлы.намерениеApply.lastPathComponent == "apply-intent.json",
          файлы.исходApply.lastPathComponent == "apply-outcome.json",
          файлы.вход.standardizedFileURL.deletingLastPathComponent().path == каталог,
          файлы.план.standardizedFileURL.deletingLastPathComponent().path == каталог,
          файлы.намерениеApply.standardizedFileURL.deletingLastPathComponent().path
            == каталог,
          файлы.исходApply.standardizedFileURL.deletingLastPathComponent().path == каталог,
          Set(пути.map(\.path)).count == пути.count,
          пути.allSatisfy({ !$0.lastPathComponent.isEmpty
              && !$0.path.contains("<") && !$0.path.contains(">") }),
          каталог != корень, !каталог.hasPrefix(корень + "/") else {
        throw ОшибкаИсполнителяПакета.неверныеРабочиеФайлы
    }
}

private func проверитьПлан(
    _ ответ: ОтветПланаПакета,
    вход: Data,
    назначение: НазначениеИсполнителяПакета
) throws {
    let план = ответ.план
    let ожидаемыйПуть = "\(назначение.область)/zhurnal/\(план.идентификатор).json"
    guard ответ.схема == "fum.ответ-плана-локальной-записи.1",
          план.схема == "fum.план-локальной-записи.1",
          план.цель.хэшКорня == sha256Пакета(Data(назначение.физическийКорень.path.utf8)),
          план.цель.область == назначение.область,
          !план.цель.узлы.isEmpty,
          шестнадцатеричный(план.идентификатор, длина: 64),
          план.путь == ожидаемыйПуть,
          план.хэшВхода == sha256Пакета(вход),
          шестнадцатеричный(план.хэшОператора, длина: 64),
          план.хэшСодержания == sha256Пакета(план.байты) else {
        throw ОшибкаИсполнителяПакета.неверныйПлан
    }
}

private func закрытоРазобрать<Значение: Codable>(
    _ тип: Значение.Type,
    из данные: Data
) throws -> Значение {
    guard данные.count <= 1_048_576, let текст = String(data: данные, encoding: .utf8) else {
        throw ОшибкаИсполнителяПакета.неверныйПакет
    }
    let определение = try ОпределениеОператора.разобрать(операторЗакрытогоJSONПакета)
    let исполнение = try AutomationExecutor.выполнить(определение, вход: .текст(текст))
    guard case .текст(let результат) = исполнение.результат else {
        throw ОшибкаИсполнителяПакета.неверныйПакет
    }
    let каноническиеБайты = Data(результат.utf8)
    let значение = try JSONDecoder().decode(тип, from: каноническиеБайты)
    guard try каноническиеДанные(значение) == каноническиеБайты else {
        throw ОшибкаИсполнителяПакета.неверныйПакет
    }
    return значение
}

private func sha256Пакета(_ данные: Data) -> String {
    SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
}

private func sha256Закреплений(
    _ закрепления: [ЗакреплениеИсходникаИсполнителяПакета]
) -> String {
    let строки = закрепления.sorted { $0.путь < $1.путь }
        .map { "\($0.путь)\u{0}\($0.sha256)\n" }.joined()
    return sha256Пакета(Data(строки.utf8))
}

private func sha256КаноническойКарты(
    _ закрепления: [ЗакреплениеИсходникаИсполнителяПакета]
) throws -> String {
    var данные = try каноническиеДанные(закрепления)
    данные.append(0x0a)
    return sha256Пакета(данные)
}

private func шестнадцатеричный(_ строка: String, длина: Int) -> Bool {
    строка.utf8.count == длина && строка.utf8.allSatisfy {
        (48...57).contains($0) || (97...102).contains($0)
    }
}

private func безопасныйОтносительныйПуть(_ путь: String) -> Bool {
    !путь.isEmpty && !путь.hasPrefix("/") && !путь.contains("\\")
        && !путь.contains("\0")
        && путь.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
            !$0.isEmpty && $0 != "." && $0 != ".." && $0 != ".git"
        }
}

private enum ФайлыИсполнителяПакета {
    static func проверитьКаталогБезСсылок(_ url: URL) throws {
        var сведения = stat()
        guard url.path.hasPrefix("/"), lstat(url.path, &сведения) == 0,
              сведения.st_mode & S_IFMT == S_IFDIR,
              url.standardizedFileURL.resolvingSymlinksInPath().path
                == url.standardizedFileURL.path else {
            throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
        }
    }

    static func проверитьHEAD(корень: URL, ref: String, oid: String) throws {
        let точкаGit = корень.appendingPathComponent(".git")
        var сведения = stat()
        guard lstat(точкаGit.path, &сведения) == 0 else {
            throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
        }
        let gitКаталог: URL
        if сведения.st_mode & S_IFMT == S_IFDIR {
            gitКаталог = точкаGit
        } else if сведения.st_mode & S_IFMT == S_IFREG {
            let ссылка = String(decoding: try прочитатьТочно(точкаGit), as: UTF8.self)
            guard ссылка.hasPrefix("gitdir: "), ссылка.hasSuffix("\n"),
                  !ссылка.dropLast().dropFirst("gitdir: ".count).isEmpty else {
                throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
            }
            let путь = String(ссылка.dropLast().dropFirst("gitdir: ".count))
            let кандидат = (путь.hasPrefix("/")
                ? URL(fileURLWithPath: путь)
                : корень.appendingPathComponent(путь)).standardizedFileURL
            try проверитьКаталогБезСсылок(кандидат)
            gitКаталог = кандидат
        } else {
            throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
        }
        let head = try прочитатьТочно(gitКаталог.appendingPathComponent("HEAD"))
        guard head == Data("ref: \(ref)\n".utf8) else {
            throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
        }
        let commonФайл = gitКаталог.appendingPathComponent("commondir")
        let общийКаталог: URL
        if let commonБайты = try прочитатьЕслиЕсть(commonФайл) {
            let common = String(decoding: commonБайты, as: UTF8.self)
            guard common.hasSuffix("\n"), !common.dropLast().isEmpty else {
                throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
            }
            let путь = String(common.dropLast())
            общийКаталог = (путь.hasPrefix("/")
                ? URL(fileURLWithPath: путь)
                : gitКаталог.appendingPathComponent(путь)).standardizedFileURL
            try проверитьКаталогБезСсылок(общийКаталог)
        } else {
            общийКаталог = gitКаталог
        }
        if let loose = try прочитатьЕслиЕсть(общийКаталог.appendingPathComponent(ref)) {
            guard loose == Data("\(oid)\n".utf8) else {
                throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
            }
            return
        }
        let packed = String(
            decoding: try прочитатьТочно(общийКаталог.appendingPathComponent("packed-refs")),
            as: UTF8.self)
        let совпадения = packed.split(separator: "\n").filter {
            $0 == Substring("\(oid) \(ref)")
        }
        guard совпадения.count == 1 else {
            throw ОшибкаИсполнителяПакета.невернаяФизическаяПривязка
        }
    }

    static func прочитатьТочно(_ url: URL) throws -> Data {
        guard let данные = try прочитатьЕслиЕсть(url) else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        return данные
    }

    static func прочитатьЕслиЕсть(_ url: URL) throws -> Data? {
        var путьСведений = stat()
        if lstat(url.path, &путьСведений) != 0 {
            if errno == ENOENT { return nil }
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        guard путьСведений.st_mode & S_IFMT == S_IFREG,
              путьСведений.st_nlink == 1,
              url.standardizedFileURL.resolvingSymlinksInPath().path
                == url.standardizedFileURL.path else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        let файл = Darwin.open(url.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard файл >= 0 else { throw ОшибкаИсполнителяПакета.конфликтРабочихБайт }
        defer { _ = Darwin.close(файл) }
        var до = stat()
        guard fstat(файл, &до) == 0, до.st_mode & S_IFMT == S_IFREG,
              до.st_nlink == 1 else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        var данные = Data()
        var буфер = [UInt8](repeating: 0, count: 8192)
        while true {
            let прочитано = Darwin.read(файл, &буфер, буфер.count)
            if прочитано < 0 && errno == EINTR { continue }
            guard прочитано >= 0 else {
                throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
            }
            if прочитано == 0 { break }
            данные.append(contentsOf: буфер.prefix(прочитано))
            guard данные.count <= 16_777_216 else {
                throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
            }
        }
        var после = stat()
        var адрес = stat()
        guard fstat(файл, &после) == 0,
              lstat(url.path, &адрес) == 0,
              до.st_dev == после.st_dev, до.st_ino == после.st_ino,
              до.st_size == после.st_size,
              адрес.st_dev == до.st_dev, адрес.st_ino == до.st_ino,
              адрес.st_mode & S_IFMT == S_IFREG else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        return данные
    }

    static func сохранитьТочно(
        _ данные: Data,
        по url: URL,
        приниматьТочныйПовтор: Bool = true
    ) throws {
        if let существующие = try прочитатьЕслиЕсть(url) {
            guard приниматьТочныйПовтор, существующие == данные else {
                throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
            }
            return
        }
        let файл = Darwin.open(
            url.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard файл >= 0 else { throw ОшибкаИсполнителяПакета.конфликтРабочихБайт }
        defer { _ = Darwin.close(файл) }
        try данные.withUnsafeBytes { буфер in
            guard let начало = буфер.baseAddress else { return }
            var позиция = 0
            while позиция < буфер.count {
                let записано = Darwin.write(
                    файл, начало.advanced(by: позиция), буфер.count - позиция)
                if записано < 0 && errno == EINTR { continue }
                guard записано > 0 else {
                    throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
                }
                позиция += записано
            }
        }
        guard fsync(файл) == 0 else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        let каталог = Darwin.open(
            url.deletingLastPathComponent().path,
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard каталог >= 0 else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
        defer { _ = Darwin.close(каталог) }
        guard fsync(каталог) == 0, try прочитатьТочно(url) == данные else {
            throw ОшибкаИсполнителяПакета.конфликтРабочихБайт
        }
    }
}

private final class КаналыСистемногоПроцессаПакета: @unchecked Sendable {
    private static let предел = 1_048_576
    private let блокировка = NSLock()
    private var stdout = Data()
    private var stderr = Data()
    private var нарушено = false

    func добавить(_ данные: Data, вStdout: Bool) {
        блокировка.lock()
        defer { блокировка.unlock() }
        let занято = вStdout ? stdout.count : stderr.count
        let остаток = max(0, Self.предел - занято)
        if данные.count > остаток { нарушено = true }
        guard остаток > 0 else { return }
        if вStdout {
            stdout.append(contentsOf: данные.prefix(остаток))
        } else {
            stderr.append(contentsOf: данные.prefix(остаток))
        }
    }

    func отметитьОшибкуЧтения() {
        блокировка.lock()
        нарушено = true
        блокировка.unlock()
    }

    func прочитать() -> (stdout: Data, stderr: Data, нарушено: Bool) {
        блокировка.lock(); defer { блокировка.unlock() }
        return (stdout, stderr, нарушено)
    }
}

private final class СостояниеСистемногоПроцессаПакета: @unchecked Sendable {
    private static let ожиданиеЗавершения: DispatchTimeInterval = .seconds(2)
    private static let ожиданиеКаналов: DispatchTimeInterval = .seconds(5)

    private let команда: КомандаПроцессаПакета
    private let таймАутНаносекунд: UInt64
    private let продолжение: CheckedContinuation<РезультатПроцессаПакета, Error>

    init(
        команда: КомандаПроцессаПакета,
        таймАутНаносекунд: UInt64,
        продолжение: CheckedContinuation<РезультатПроцессаПакета, Error>
    ) {
        self.команда = команда
        self.таймАутНаносекунд = таймАутНаносекунд
        self.продолжение = продолжение
    }

    func начать() {
        DispatchQueue.global(qos: .utility).async { [self] in
            let процесс = Process()
            let stdoutКанал = Pipe()
            let stderrКанал = Pipe()
            let stdoutЧтение = stdoutКанал.fileHandleForReading
            let stderrЧтение = stderrКанал.fileHandleForReading
            let stdoutЗапись = stdoutКанал.fileHandleForWriting
            let stderrЗапись = stderrКанал.fileHandleForWriting
            let завершение = DispatchSemaphore(value: 0)
            процесс.executableURL = команда.исполняемыйФайл
            процесс.arguments = команда.аргументы
            процесс.currentDirectoryURL = команда.исполняемыйФайл.deletingLastPathComponent()
            процесс.environment = [
                "LANG": "C",
                "LC_ALL": "C",
                "PATH": "/usr/bin:/bin"
            ]
            процесс.standardInput = FileHandle.nullDevice
            процесс.standardOutput = stdoutКанал
            процесс.standardError = stderrКанал
            процесс.terminationHandler = { _ in завершение.signal() }
            do {
                try процесс.run()
            } catch {
                try? stdoutЧтение.close()
                try? stderrЧтение.close()
                try? stdoutЗапись.close()
                try? stderrЗапись.close()
                продолжение.resume(throwing: ОшибкаПроцессаПакета.запускНеНачат)
                return
            }
            try? stdoutЗапись.close()
            try? stderrЗапись.close()

            let каналы = КаналыСистемногоПроцессаПакета()
            let группа = DispatchGroup()
            let stdoutDescriptor = stdoutЧтение.fileDescriptor
            let stderrDescriptor = stderrЧтение.fileDescriptor
            группа.enter()
            DispatchQueue.global(qos: .utility).async {
                читатьКаналПроцессаПакета(
                    stdoutDescriptor, вStdout: true, каналы: каналы)
                группа.leave()
            }
            группа.enter()
            DispatchQueue.global(qos: .utility).async {
                читатьКаналПроцессаПакета(
                    stderrDescriptor, вStdout: false, каналы: каналы)
                группа.leave()
            }

            var завершён = завершение.wait(
                timeout: .now() + .nanoseconds(Int(таймАутНаносекунд))) == .success
            let истёкТаймАут = !завершён
            if !завершён {
                процесс.terminate()
                завершён = завершение.wait(
                    timeout: .now() + Self.ожиданиеЗавершения) == .success
            }
            if !завершён {
                _ = Darwin.kill(процесс.processIdentifier, SIGKILL)
                завершён = завершение.wait(
                    timeout: .now() + Self.ожиданиеЗавершения) == .success
            }

            var каналыЗавершены = группа.wait(
                timeout: .now() + Self.ожиданиеКаналов) == .success
            if !каналыЗавершены {
                try? stdoutЧтение.close()
                try? stderrЧтение.close()
                каналыЗавершены = группа.wait(
                    timeout: .now() + Self.ожиданиеЗавершения) == .success
            } else {
                try? stdoutЧтение.close()
                try? stderrЧтение.close()
            }
            guard завершён, каналыЗавершены else {
                продолжение.resume(throwing: ОшибкаПроцессаПакета.исходНеизвестен)
                return
            }

            let данные = каналы.прочитать()
            guard !истёкТаймАут, !данные.нарушено else {
                продолжение.resume(throwing: ОшибкаПроцессаПакета.исходНеизвестен)
                return
            }
            продолжение.resume(returning: РезультатПроцессаПакета(
                код: процесс.terminationStatus,
                stdout: данные.stdout,
                stderr: данные.stderr,
                завершениеПодтверждено: процесс.terminationReason == .exit))
        }
    }
}

private func читатьКаналПроцессаПакета(
    _ descriptor: Int32,
    вStdout: Bool,
    каналы: КаналыСистемногоПроцессаПакета
) {
    var буфер = [UInt8](repeating: 0, count: 8192)
    while true {
        let прочитано = Darwin.read(descriptor, &буфер, буфер.count)
        if прочитано < 0 && errno == EINTR { continue }
        guard прочитано >= 0 else {
            каналы.отметитьОшибкуЧтения()
            return
        }
        if прочитано == 0 { return }
        каналы.добавить(
            Data(буфер.prefix(Int(прочитано))), вStdout: вStdout)
    }
}

private let операторЗакрытогоJSONПакета = Data(#"""
{
  "схема": "fum.определение-оператора.1",
  "идентификатор": "fum.закрыто-разобрать-пакет-локального-журнала",
  "версия": 1,
  "правила": [],
  "шаги": [
    {
      "идентификатор": "сохранить-типизированное-значение",
      "оператор": "вычислить-JSON",
      "аргументы": {
        "граф": {
          "схема": "fuma.граф-JSON.1",
          "числа": "целые64-без-дробей",
          "переменные": [],
          "результат": ["переменная", "вход"]
        }
      }
    }
  ]
}
"""#.utf8)
