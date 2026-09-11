import Foundation
import Virtualization
import Darwin

public final class СлужбаVZ: NSObject, VZVirtualMachineDelegate {
    private let хранилище: Хранилище
    private var машина: VZVirtualMachine!
    private var цикл = ЖизненныйЦикл()
    private var запись: ЗапускМашины!
    private var приёмникSSH: Приёмник!
    private var приёмникКоманд: Приёмник!
    private var сигналы: [DispatchSourceSignal] = []
    private var мосты: [UUID: () -> Void] = [:]
    private var ожидающие = 0
    private var ожидающиеКоманды = 0
    private var запросОстановки = false
    private var использованныеКоманды: Set<String> = []
    private var начало = DispatchTime.now().uptimeNanoseconds
    private let событие = UUID().uuidString.lowercased()
    public var проверитьГостя: ((Хранилище, ЗапускМашины) throws -> Data)?

    public init(_ план: ПланМашины) throws {
        try Хост.ресурсы(план.каталог).проверить(план.профиль, подготовка: false)
        хранилище = try Хранилище(план: план, создать: false)
        super.init()
    }
    private func путь(_ имя: String) -> URL { URL(fileURLWithPath: хранилище.путь + "/" + имя) }
    private func сохранить(_ фаза: String, причина: String? = nil) throws {
        if цикл.фаза != фаза { try цикл.перейти(фаза) }
        запись.фаза = фаза; запись.причина = причина
        try хранилище.записать("запуск.json", байты: кодировать(запись))
    }
    public func запустить() throws {
        dispatchPrecondition(condition: .onQueue(.main))
        let подготовка = ПодготовкаUbuntu(хранилище)
        guard try хранилище.есть("диск.raw"), FileManager.default.fileExists(atPath: путь("идентичность/seed.iso").path) else {
            throw ОшибкаМашины("Сначала выполните «подготовить --до всё».")
        }
        try подготовка.диск()
        try подготовка.идентичность()
        приёмникSSH = try Приёмник { [weak self] файл in self?.соединитьSSH(файл) }
        приёмникКоманд = try Приёмник { [weak self] файл in self?.принятьКоманду(файл) }
        запись = ЗапускМашины(машина: хранилище.паспорт.идентификатор, план: хранилище.паспорт.план.отпечаток,
                             портSSH: приёмникSSH.порт, портУправления: приёмникКоманд.порт)
        let конфигурация = VZVirtualMachineConfiguration()
        конфигурация.cpuCount = хранилище.паспорт.план.профиль.процессоры
        конфигурация.memorySize = UInt64(хранилище.паспорт.план.профиль.памятьГиБ) << 30
        let платформа = VZGenericPlatformConfiguration()
        guard let идентификатор = VZGenericMachineIdentifier(dataRepresentation: try Data(contentsOf: путь("идентичность/машина.bin"))),
              let mac = VZMACAddress(string: try String(contentsOf: путь("идентичность/mac.txt"), encoding: .utf8)) else {
            throw ОшибкаМашины("Постоянный идентификатор VM или MAC повреждён.")
        }
        платформа.machineIdentifier = идентификатор
        конфигурация.platform = платформа
        let загрузчик = VZEFIBootLoader()
        загрузчик.variableStore = VZEFIVariableStore(url: путь("идентичность/efi.bin"))
        конфигурация.bootLoader = загрузчик
        конфигурация.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        let сеть = VZVirtioNetworkDeviceConfiguration()
        сеть.macAddress = mac; сеть.attachment = VZNATNetworkDeviceAttachment()
        конфигурация.networkDevices = [сеть]
        конфигурация.socketDevices = [VZVirtioSocketDeviceConfiguration()]
        конфигурация.storageDevices = try [
            VZVirtioBlockDeviceConfiguration(attachment: VZDiskImageStorageDeviceAttachment(url: путь("диск.raw"), readOnly: false)),
            VZVirtioBlockDeviceConfiguration(attachment: VZDiskImageStorageDeviceAttachment(url: путь("идентичность/seed.iso"), readOnly: true))]
        let имяКонсоли = "консоль-" + запись.запуск + ".log"
        try хранилище.записать(имяКонсоли, байты: Data())
        let консоль = VZVirtioConsoleDeviceSerialPortConfiguration()
        консоль.attachment = VZFileHandleSerialPortAttachment(fileHandleForReading: nil,
            fileHandleForWriting: FileHandle(fileDescriptor: try хранилище.открытьФайл(имяКонсоли, запись: true), closeOnDealloc: true))
        конфигурация.serialPorts = [консоль]
        try конфигурация.validate()
        машина = VZVirtualMachine(configuration: конфигурация, queue: .main)
        машина.delegate = self
        try сохранить("запускается")
        try хранилище.записать("событие-" + событие + ".json", байты: кодировать(СобытиеМашины(
            идентификатор: событие, родитель: nil, операция: "жизнь VM", длительностьНс: nil, исход: "выполняется")))
        for номер in [SIGINT, SIGTERM, SIGHUP] {
            signal(номер, SIG_IGN)
            let источник = DispatchSource.makeSignalSource(signal: номер, queue: .main)
            источник.setEventHandler { [weak self] in
                do { try self?.остановить() } catch { self?.диагностика("Штатная остановка ещё невозможна: \(error)") }
            }
            источник.resume(); сигналы.append(источник)
        }
        начало = DispatchTime.now().uptimeNanoseconds
        машина.start { [weak self] результат in
            guard let self else { return }
            if case .failure(let ошибка) = результат { self.завершить(ошибка: String(describing: ошибка)); return }
            do {
                try self.сохранить("работает")
                try self.хранилище.записать("загрузка-" + self.запись.запуск + ".json", байты: кодировать([
                    "план": self.запись.план, "начало-VM-нс": String(DispatchTime.now().uptimeNanoseconds - self.начало),
                    "готовность": "ещё не проверена"]))
                if self.запросОстановки { try self.остановить() }
            } catch {
                self.диагностика("VM работает, но учёт запуска не сохранён: \(error). Запрашивается штатная остановка.")
                do { try self.остановить() } catch { self.диагностика("Остановка не принята: \(error). Служба и замок сохранены.") }
            }
        }
    }
    private func диагностика(_ текст: String) { FileHandle.standardError.write(Data((текст + "\n").utf8)) }
    private func остановить() throws {
        запросОстановки = true
        if цикл.фаза == "запускается" || цикл.фаза == "останавливается" { return }
        guard машина.canRequestStop else { throw ОшибкаМашины("Гость ещё не принимает штатный запрос остановки; повторите после загрузки.") }
        try машина.requestStop()
        try сохранить("останавливается")
    }
    private func принятьКоманду(_ файл: Int32) {
        guard ожидающиеКоманды < 16 else { close(файл); return }
        ожидающиеКоманды += 1
        let снимок = запись!
        DispatchQueue.global(qos: .utility).async {
            do {
                let команда = try УправлениеМашиной.принять(файл, запись: снимок)
                DispatchQueue.main.async {
                    self.ожидающиеКоманды -= 1
                    do {
                        guard !self.использованныеКоманды.contains(команда.одноразовое), self.использованныеКоманды.count < 100_000 else {
                            throw ОшибкаМашины("Повтор кадра управления отклонён.")
                        }
                        self.использованныеКоманды.insert(команда.одноразовое)
                        switch команда.операция {
                        case "состояние": break
                        case "остановить": try self.остановить()
                        case "готовность": try self.начатьПроверку()
                        default: throw ОшибкаМашины("Неизвестная операция управления.")
                        }
                        let ответ = self.запись!
                        DispatchQueue.global(qos: .utility).async {
                            defer { close(файл) }
                            try? УправлениеМашиной.ответить(файл, команда: команда, запись: ответ)
                        }
                    } catch { self.диагностика(String(describing: error)); close(файл) }
                }
            } catch {
                close(файл)
                DispatchQueue.main.async { self.ожидающиеКоманды -= 1 }
            }
        }
    }
    private func начатьПроверку() throws {
        if цикл.фаза == "проверка готовности" { return }
        guard ["работает", "готова"].contains(цикл.фаза), let проверитьГостя else {
            throw ОшибкаМашины("Проверка готовности пока недоступна.")
        }
        try сохранить("проверка готовности")
        let снимок = запись!
        DispatchQueue.global(qos: .utility).async {
            let результат = Result { try проверитьГостя(self.хранилище, снимок) }
            DispatchQueue.main.async {
                guard self.цикл.фаза == "проверка готовности" else { return }
                do {
                    let данные = try результат.get()
                    try self.хранилище.записать("готовность.json", байты: данные)
                    try self.сохранить("готова")
                } catch {
                    try? self.сохранить("работает", причина: "Готовность не подтверждена: \(error)")
                }
            }
        }
    }
    private func соединитьSSH(_ файл: Int32) {
        guard ожидающие + мосты.count < 32, let устройство = машина?.socketDevices.first as? VZVirtioSocketDevice else { close(файл); return }
        ожидающие += 1
        var завершён = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if !завершён { завершён = true; close(файл) }
        }
        устройство.connect(toPort: 2222) { результат in
            let соединение = try? результат.get()
            self.ожидающие -= 1
            if завершён { соединение?.close(); return }
            завершён = true
            guard let соединение else { close(файл); return }
            Канал.настроить(файл, ожидание: 0)
            let гостевой = dup(соединение.fileDescriptor)
            guard гостевой >= 0 else { соединение.close(); close(файл); return }
            Канал.настроить(гостевой, ожидание: 0)
            let идентификатор = UUID()
            self.мосты[идентификатор] = { shutdown(файл, SHUT_RDWR); shutdown(гостевой, SHUT_RDWR) }
            let группа = DispatchGroup()
            for (вход, выход) in [(файл, гостевой), (гостевой, файл)] {
                группа.enter()
                DispatchQueue.global(qos: .utility).async {
                    defer { shutdown(выход, SHUT_WR); группа.leave() }
                    var буфер = [UInt8](repeating: 0, count: 64 * 1024)
                    while true {
                        let число = Darwin.read(вход, &буфер, буфер.count)
                        if число < 0 && errno == EINTR { continue }
                        if число <= 0 { break }
                        do { try Канал.записать(выход, Data(буфер.prefix(число))) } catch { shutdown(вход, SHUT_RDWR); break }
                    }
                }
            }
            группа.notify(queue: .main) {
                close(файл); close(гостевой); соединение.close()
                self.мосты.removeValue(forKey: идентификатор)
            }
        }
    }
    public func guestDidStop(_ virtualMachine: VZVirtualMachine) { завершить(ошибка: nil) }
    public func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) { завершить(ошибка: String(describing: error)) }
    private func завершить(ошибка: String?) {
        for закрыть in мосты.values { закрыть() }
        do {
            try сохранить(ошибка == nil ? "остановлена" : "ошибка", причина: ошибка)
            try хранилище.записать("событие-" + событие + ".json", байты: кодировать(СобытиеМашины(
                идентификатор: событие, родитель: nil, операция: "жизнь VM",
                длительностьНс: DispatchTime.now().uptimeNanoseconds - начало, исход: ошибка == nil ? "успех" : "ошибка")))
        } catch { диагностика("Не удалось сохранить конечное состояние: \(error)") }
        exit(ошибка == nil ? 0 : 1)
    }
}
