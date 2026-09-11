import Foundation
import Virtualization
import Darwin

public struct СнимокХоста: Codable {
    public var ресурсы: Ресурсы
    public var система: String
    public var инструменты: [String: String]
    public var недостающиеПакеты: [String]
    public var нагрузка: [Double]
}

public enum Хост {
    public static func инструмент(_ имя: String) -> String? {
        for каталог in ["/opt/homebrew/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"] {
            let путь = каталог + "/" + имя
            if FileManager.default.isExecutableFile(atPath: путь) { return путь }
        }
        return nil
    }
    public static func обязательный(_ имя: String) throws -> String {
        guard let путь = инструмент(имя) else { throw ОшибкаМашины("Не найден \(имя); выполните этап зависимостей по плану.") }
        return путь
    }
    public static func ресурсы(_ путь: String) throws -> Ресурсы {
        var размер = 8
        var память: UInt64 = 0
        guard sysctlbyname("hw.memsize", &память, &размер, nil, 0) == 0 else { throw ОшибкаМашины("Не удалось определить RAM хоста.") }
        var адрес = URL(fileURLWithPath: путь)
        while !FileManager.default.fileExists(atPath: адрес.path), адрес.path != "/" { адрес.deleteLastPathComponent() }
        let свойства = try FileManager.default.attributesOfFileSystem(forPath: адрес.path)
        guard let свободно = (свойства[.systemFreeSize] as? NSNumber)?.uint64Value else { throw ОшибкаМашины("Не удалось определить свободное место.") }
        #if arch(arm64)
        let архитектура = "arm64"
        #else
        let архитектура = "неподдержанная"
        #endif
        return Ресурсы(архитектура: архитектура, виртуализация: VZVirtualMachine.isSupported,
                        процессоры: ProcessInfo.processInfo.processorCount, памятьБайт: память, свободноБайт: свободно)
    }
    public static func снимок(_ путь: String) throws -> СнимокХоста {
        var версии: [String: String] = [:]
        for имя in ["swift", "brew", "ssh", "git", "qemu-img", "gpg", "gpgv", "curl", "hdiutil", "codesign"] {
            guard let программа = инструмент(имя) else { версии[имя] = "отсутствует"; continue }
            let флаг = имя == "ssh" ? "-V" : "--version"
            if ["hdiutil", "codesign"].contains(имя) { версии[имя] = "системный инструмент macOS"; continue }
            let результат = try Исполнитель.выполнить(программа, [флаг], предел: 20,
                среда: ["HOMEBREW_NO_AUTO_UPDATE": "1", "HOMEBREW_NO_ANALYTICS": "1"])
            версии[имя] = String((результат.вывод + результат.ошибки).split(separator: "\n").first ?? "версия не определена")
        }
        let система = try Исполнитель.выполнить("/usr/bin/sw_vers", [], предел: 10).вывод
        var нагрузка = [Double](repeating: 0, count: 3)
        _ = getloadavg(&нагрузка, 3)
        return СнимокХоста(ресурсы: try ресурсы(путь), система: система, инструменты: версии,
            недостающиеПакеты: [("qemu-img", "qemu"), ("gpgv", "gnupg")].filter { инструмент($0.0) == nil }.map { $0.1 }, нагрузка: нагрузка)
    }
}
