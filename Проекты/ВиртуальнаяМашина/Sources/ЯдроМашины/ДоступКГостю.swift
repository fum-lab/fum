import Foundation
import Darwin

public enum ДоступКГостю {
    public static func проверитьАдресВосстановления(_ адрес: String) throws {
        var значение = in_addr()
        let части = адрес.split(separator: ".", omittingEmptySubsequences: false).compactMap { UInt8($0) }
        guard inet_pton(AF_INET, адрес, &значение) == 1, части.count == 4,
              части[0] == 10 || (части[0] == 172 && (16...31).contains(части[1])) || (части[0] == 192 && части[1] == 168) else {
            throw ОшибкаМашины("Восстановлению нужен явный частный IPv4-адрес собственной VM; имя и VSOCK не подходят.")
        }
    }
    public static func аргументы(каталог: String, порт: UInt16, черезХост: Bool = false, адрес: String? = nil) throws -> [String] {
        guard порт > 0 else { throw ОшибкаМашины("Неверный порт доступа к гостю.") }
        var результат = ["-F", каталог + "/идентичность/ssh_config", "-T", "-p", String(порт)]
        if let адрес { try проверитьАдресВосстановления(адрес); результат += ["-o", "HostName=" + адрес] }
        if черезХост {
            результат += ["-o", "ExitOnForwardFailure=yes", "-o", "PermitRemoteOpen=ports.ubuntu.com:443 github.com:443", "-R", "127.0.0.1:1080"]
        }
        return результат
    }
    public static func сценарий(_ ресурс: String, вызов: String, данные: Data) throws -> Data {
        сценарий(исходник: try РесурсыГостя.текст(ресурс), вызов: вызов, данные: данные)
    }
    static func сценарий(исходник: String, вызов: String, данные: Data) -> Data {
        let шестнадцатеричные = данные.map { String(format: "%02x", $0) }.joined()
        let программа = исходник + "\nos.umask(0o077)\nprint(json.dumps(" + вызов
            + "(json.loads(bytes.fromhex(\"" + шестнадцатеричные + "\").decode())), ensure_ascii=False, sort_keys=True))\n"
        return Data(программа.utf8)
    }
    public static func восстановить(_ клиент: КлиентМашины, адрес: String) throws -> Data {
        try проверитьАдресВосстановления(адрес)
        let запуск = try клиент.состояние()
        guard ["работает", "готова"].contains(запуск.фаза) else { throw ОшибкаМашины("Восстановление требует свободной работающей VM.") }
        let данные: [String: Any] = ["машина": запуск.машина,
            "файлы": ["fum-vsock.service": try РесурсыГостя.текст("fum-vsock.service"), "fum-vsock.socket": try РесурсыГостя.текст("fum-vsock.socket")],
            "прежняя_служба": try РесурсыГостя.текст("исходная-служба.txt")]
        let вход = try сценарий("восстановление.py", вызов: "восстановить", данные: JSONSerialization.data(withJSONObject: данные))
        let аргументы = try аргументы(каталог: клиент.читатель.паспорт.план.каталог, порт: 22, адрес: адрес)
        let результат = try Исполнитель.выполнить("/usr/bin/ssh", аргументы + ["fum", "sudo -n /usr/bin/python3 -B -s -"], предел: 180, вход: вход)
        guard результат.код == 0 else { throw ОшибкаМашины("Восстановление гостя: код \(результат.код), \(результат.ошибки.suffix(3000))") }
        let байты = Data(результат.вывод.utf8)
        guard let ответ = try JSONSerialization.jsonObject(with: байты) as? [String: Any], ответ["машина"] as? String == запуск.машина,
              try клиент.состояние().запуск == запуск.запуск else { throw ОшибкаМашины("Свидетельство восстановления относится к другому запуску.") }
        // Проверяется именно восстанавливаемый путь; применённые units сами по себе не доказывают связь.
        let сквозной = try Self.аргументы(каталог: клиент.читатель.паспорт.план.каталог, порт: запуск.портДоступаКГостю)
        let проверка = try Исполнитель.выполнить("/usr/bin/ssh", сквозной + ["fum", "/bin/cat /etc/fum-vm-id"], предел: 20)
        guard проверка.код == 0, проверка.вывод.trimmingCharacters(in: .whitespacesAndNewlines) == запуск.машина else {
            throw ОшибкаМашины("Службы сохранены, но SSH через VSOCK не подтверждён; повторите восстановление по NAT.")
        }
        return байты
    }
}
