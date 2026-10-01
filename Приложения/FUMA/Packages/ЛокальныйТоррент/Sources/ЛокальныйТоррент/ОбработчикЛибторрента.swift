import Foundation
import Darwin
import МостЛибторрента

typealias СоздательМоста = @convention(c) (UnsafePointer<ВходМостаТоррента>?, UnsafeMutablePointer<OpaquePointer?>?) -> РезультатГраницыМоста

public struct ОбработчикЛибторрента: ОбработчикМетаданныхТоррента {
    private let создатель: СоздательМоста
    public init() { создатель = создать_метаданные_торрента }
    init(создатель: @escaping СоздательМоста) { self.создатель = создатель }
    public func создать(адресФайла: URL, имяФайла: String, размерФайла: UInt64,
        ожидаемыйХэшСодержимого: String, ограничения: ОграниченияПодготовкиТоррента,
        отмена: ОтменаПодготовкиТоррента,
        ход: @escaping @Sendable (ХодПодготовкиТоррента) -> Void) async throws -> СозданныеМетаданныеТоррента {
        try отмена.проверитьОтмену()
        guard адресФайла.isFileURL && адресФайла.lastPathComponent == имяФайла
            && !имяФайла.isEmpty && имяФайла.utf8.count <= 255 && !имяФайла.contains("\0") else {
            throw ОшибкаПодготовкиТоррента.сбойОбработчика("неверный локальный адрес или имя")
        }
        let байтыХэша = Array(ожидаемыйХэшСодержимого.utf8)
        guard байтыХэша.count == 64 && байтыХэша.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else {
            throw ОшибкаПодготовкиТоррента.сбойОбработчика("неверный ожидаемый SHA-256")
        }
        func цифра(_ байт: UInt8) -> UInt8 { байт <= 57 ? байт - 48 : байт - 87 }
        let хэш = stride(from: 0, to: 64, by: 2).map { цифра(байтыХэша[$0]) * 16 + цифра(байтыХэша[$0 + 1]) }
        let операция = try ОперацияСвифтМоста()
        return try await withTaskCancellationHandler {
            defer { операция.закрыть() }
            let результат = try await Task.detached(priority: .utility) {
                try отмена.проверитьОтмену()
                let исходник = Darwin.open(адресФайла.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
                guard исходник >= 0 else { throw ОшибкаПодготовкиТоррента.источникНедоступен(код: errno) }
                defer { Darwin.close(исходник) }
                let папка = FileManager.default.temporaryDirectory.appendingPathComponent("fum-torrent-" + UUID().uuidString)
                try FileManager.default.createDirectory(at: папка, withIntermediateDirectories: false,
                    attributes: [.posixPermissions: 0o700])
                var метка = stat()
                guard Darwin.lstat(папка.path, &метка) == 0 && (метка.st_mode & S_IFMT) == S_IFDIR else {
                    throw ОшибкаПодготовкиТоррента.сбойОбработчика("не подтверждён частный каталог")
                }
                var очищено = false
                defer { if !очищено { try? удалитьЧастныйКаталог(папка, метка: метка) } }
                let каталог = Darwin.open(папка.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK)
                guard каталог >= 0 else { throw ОшибкаПодготовкиТоррента.источникНедоступен(код: errno) }
                defer { Darwin.close(каталог) }
                var открытаяМетка = stat()
                guard Darwin.fstat(каталог, &открытаяМетка) == 0
                    && открытаяМетка.st_dev == метка.st_dev && открытаяМетка.st_ino == метка.st_ino else {
                    throw ОшибкаПодготовкиТоррента.сбойОбработчика("подменён частный каталог")
                }
                var выход: OpaquePointer?
                defer { уничтожить_метаданные_торрента(выход) }
                let ответ = хэш.withUnsafeBufferPointer { адресХэша in
                    имяФайла.withCString { имя in
                        var вход = ВходМостаТоррента(исходник: исходник, каталог: каталог, имя: имя,
                            длина_имени: имяФайла.utf8.count, размер: размерФайла,
                            максимум_файла: ограничения.максимумБайтФайла,
                            длина_части: UInt64(ограничения.длинаЧастиБайт), максимум_метаданных: ограничения.максимумБайтМетаданных,
                            хэш: адресХэша.baseAddress, длина_хэша: хэш.count, операция: операция.указатель,
                            проверка_отмены: { контекст in
                                guard let контекст else { return 1 }
                                return Unmanaged<ОтменаПодготовкиТоррента>.fromOpaque(контекст).takeUnretainedValue().запрошенаОтмена ? 1 : 0
                            }, контекст: Unmanaged.passUnretained(отмена).toOpaque())
                        return создатель(&вход, &выход)
                    }
                }
                try проверитьОтветМоста(ответ)
                try отмена.проверитьОтмену()
                guard let выход else { throw ОшибкаПодготовкиТоррента.сбойОбработчика("успех без owner") }
                var длина = 0
                guard let байты = байты_метаданных_торрента(выход, &длина), длина > 0
                    && UInt64(длина) <= ограничения.максимумБайтМетаданных,
                    let первый = хэш_первой_версии_торрента(выход), let второй = хэш_второй_версии_торрента(выход) else {
                    throw ОшибкаПодготовкиТоррента.сбойОбработчика("повреждённый owner метаданных")
                }
                let данные = Data(bytes: байты, count: длина)
                let хэши = try ХэшиИнформацииТоррента(хэшВерсии1: String(cString: первый), хэшВерсии2: String(cString: второй))
                let метаданные = try СозданныеМетаданныеТоррента(бенкодированныеДанные: данные, хэшиИнформации: хэши)
                try ПроверкаМетаданныхТоррента.проверить(метаданные, имя: имяФайла, размер: размерФайла, ограничения: ограничения)
                try отмена.проверитьОтмену()
                try удалитьЧастныйКаталог(папка, метка: метка)
                очищено = true
                ход(ХодПодготовкиТоррента(этап: .частиМетаданных, завершено: размерФайла, всего: размерФайла))
                return метаданные
            }.value
            try отмена.проверитьОтмену()
            return результат
        } onCancel: {
            отмена.отменить(); операция.отменить()
        }
    }
}

private func удалитьЧастныйКаталог(_ папка: URL, метка: stat) throws {
    var именованнаяМетка = stat()
    guard Darwin.lstat(папка.path, &именованнаяМетка) == 0
        && именованнаяМетка.st_dev == метка.st_dev && именованнаяМетка.st_ino == метка.st_ino
        && (именованнаяМетка.st_mode & S_IFMT) == S_IFDIR else {
        throw ОшибкаПодготовкиТоррента.сбойОбработчика("очистка: идентичность частного каталога не подтверждена")
    }
    guard Darwin.rmdir(папка.path) == 0 else {
        throw ОшибкаПодготовкиТоррента.сбойОбработчика("очистка частного каталога: код \(errno)")
    }
}

private func проверитьОтветМоста(_ ответ: РезультатГраницыМоста) throws {
    if ответ.код == 0 { return }
    if ответ.код == 2 { throw ОшибкаПодготовкиТоррента.отменено }
    var сообщение = ответ.сообщение
    let текст = withUnsafeBytes(of: &сообщение) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
    throw ОшибкаПодготовкиТоррента.сбойОбработчика(текст)
}

// handle удерживается до возврата worker; отмена и уничтожение сериализованы.
private final class ОперацияСвифтМоста: @unchecked Sendable {
    private let замок = NSLock()
    private var адрес: OpaquePointer?
    init() throws { try проверитьОтветМоста(создать_операцию_торрента(&адрес)) }
    var указатель: OpaquePointer? {
        замок.lock(); defer { замок.unlock() }; return адрес
    }
    func отменить() {
        замок.lock(); defer { замок.unlock() }; отменить_операцию_торрента(адрес)
    }
    func закрыть() {
        замок.lock(); defer { замок.unlock() }; уничтожить_операцию_торрента(адрес); адрес = nil
    }
    deinit { закрыть() }
}
