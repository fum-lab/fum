import Foundation

public struct Ресурсы: Codable, Equatable {
    public var архитектура: String
    public var виртуализация: Bool
    public var процессоры: Int
    public var памятьБайт: UInt64
    public var свободноБайт: UInt64
    public init(архитектура: String, виртуализация: Bool, процессоры: Int, памятьБайт: UInt64, свободноБайт: UInt64) {
        self.архитектура = архитектура; self.виртуализация = виртуализация
        self.процессоры = процессоры; self.памятьБайт = памятьБайт; self.свободноБайт = свободноБайт
    }
    public func проверить(_ профиль: Профиль, подготовка: Bool = true) throws {
        try профиль.проверить()
        guard архитектура == "arm64", виртуализация else {
            throw ОшибкаМашины("Первый адаптер требует Apple silicon и доступную Virtualization.framework.")
        }
        guard процессоры >= профиль.процессоры + 2, памятьБайт >= UInt64(профиль.памятьГиБ + 8) << 30 else {
            throw ОшибкаМашины("Недостаточно ресурсов: хосту оставляются минимум 2 CPU и 8 GiB RAM.")
        }
        // Учитываем полный рабочий диск, копию загрузки и резерв, не обещая разреженность.
        let нужно = UInt64(подготовка ? профиль.дискГиБ + 8 : 4) << 30
        guard свободноБайт >= нужно else {
            throw ОшибкаМашины("Недостаточно места: для этого этапа требуется \(нужно) свободных байтов.")
        }
    }
}

public struct ПланМашины: Codable, Equatable {
    public var схема = "fum.план-машины.1"
    public var профиль: Профиль
    public var каталог: String
    public var отпечаток: String
    public var образ = "https://cloud-images.ubuntu.com/releases/noble/release-20260826/ubuntu-24.04-server-cloudimg-arm64.img"
    public var хэшОбраза = "afa139bac6f2629c1e1f2f8f34215f3a9ad9779801bcb945521ba1a45016743f"
    public var ключПодписи = "D2EB44626FDDC30B513D5BB71A5D6C4C7DB87C81"
    public var зависимости = ["qemu", "gnupg"]
    public var этапы = ["проверить зависимости", "проверить подпись", "скачать и проверить образ", "конвертировать диск", "создать постоянные ключи и seed"]
    private var вычисленныйОтпечаток: String {
        get throws {
            var копия = self
            копия.отпечаток = ""
            return хэш(try кодировать(копия))
        }
    }
    public static func создать(профиль: Профиль, каталог: String, ресурсы: Ресурсы) throws -> ПланМашины {
        try ресурсы.проверить(профиль)
        try проверитьПуть(каталог)
        var план = ПланМашины(профиль: профиль, каталог: каталог, отпечаток: "")
        план.отпечаток = try план.вычисленныйОтпечаток
        return план
    }
    public func проверить() throws {
        try профиль.проверить()
        try Self.проверитьПуть(каталог)
        let эталон = ПланМашины(профиль: профиль, каталог: каталог, отпечаток: "")
        guard схема == эталон.схема, образ == эталон.образ, хэшОбраза == эталон.хэшОбраза,
              ключПодписи == эталон.ключПодписи, зависимости == эталон.зависимости, этапы == эталон.этапы,
              отпечаток == (try вычисленныйОтпечаток) else {
            throw ОшибкаМашины("План изменён или не поддерживается. Создайте и просмотрите новый план.")
        }
    }
    private static func проверитьПуть(_ каталог: String) throws {
        let части = каталог.split(separator: "/", omittingEmptySubsequences: false)
        guard каталог.hasPrefix("/"), каталог.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }), каталог != "/",
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw ОшибкаМашины("Нужен абсолютный нормализованный путь личного каталога VM.")
        }
    }
}
