import Foundation
import Darwin
import XCTest
@testable import ЯдроМашины

final class ПроверкиИдентичностиГостя: XCTestCase {
    private let машина = "4b8d948e-5a6c-4ae5-916f-ab104120ea70"
    private var корень: URL!
    private var каталог: Int32 = -1
    private var клиент: String { ключ(1) + " открытая-фикстура-клиента" }
    private var хост: String { ключ(2) + " открытая-фикстура-хоста" }
    private let имена = ["клиент", "клиент.pub", "хост", "хост.pub", "known_hosts", "ssh_config"]

    override func setUpWithError() throws {
        let физический = realpath(FileManager.default.temporaryDirectory.path, nil)!
        defer { free(физический) }
        корень = URL(fileURLWithPath: String(cString: физический))
            .appendingPathComponent("идентичность-" + UUID().uuidString + " ё \" \\")
        try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        каталог = Darwin.open(корень.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        XCTAssertGreaterThanOrEqual(каталог, 0)
        try FileManager.default.createDirectory(at: корень.appendingPathComponent("идентичность"),
            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        try сбросить()
    }
    override func tearDownWithError() throws {
        if каталог >= 0 { close(каталог); каталог = -1 }
        if let корень { try FileManager.default.removeItem(at: корень) }
    }
    private func ключ(_ байт: UInt8) -> String {
        let байты: [UInt8] = [0, 0, 0, 11] + Array("ssh-ed25519".utf8) + [0, 0, 0, 32] + Array(repeating: байт, count: 32)
        return "ssh-ed25519 " + Data(байты).base64EncodedString()
    }
    private func путь(_ имя: String) -> String { корень.path + "/идентичность/" + имя }
    private func записать(_ имя: String, _ байты: Data) throws {
        try байты.write(to: URL(fileURLWithPath: путь(имя)))
        XCTAssertEqual(chmod(путь(имя), 0o600), 0)
    }
    private func записать(_ имя: String, _ текст: String) throws { try записать(имя, Data(текст.utf8)) }
    // Эталон задаётся отдельно от производственного конструктора.
    private func настройка() -> String {
        func кавычки(_ путь: String) -> String {
            "\"" + путь.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
        }
        return """
        Host *
            HostName 127.0.0.1
            User ubuntu
            HostKeyAlias fum-\(машина)
            IdentityFile \(кавычки(путь("клиент")))
            UserKnownHostsFile \(кавычки(путь("known_hosts")))
            GlobalKnownHostsFile /dev/null
            StrictHostKeyChecking yes
            IdentitiesOnly yes
            IdentityAgent none
            UpdateHostKeys no
            BatchMode yes
            ConnectTimeout 5
            ServerAliveInterval 10
            ServerAliveCountMax 3
        """ + "\n"
    }
    private func сбросить() throws {
        for имя in ["клиент", "хост"] { try записать(имя, "открытый-макет-private-" + имя) }
        try записать("клиент.pub", клиент + "\n")
        try записать("хост.pub", хост + "\n")
        try записать("known_hosts", "fum-" + машина + " " + хост + "\n")
        try записать("ssh_config", настройка())
    }
    private func получитьКлюч(_ данные: Data) throws -> Data {
        if данные == Data("открытый-макет-private-клиент".utf8) { return Data((ключ(1) + "\n").utf8) }
        if данные == Data("открытый-макет-private-хост".utf8) { return Data((ключ(2) + "\n").utf8) }
        throw ОшибкаМашины("Неизвестный вход открытой фикстуры получения ключа.")
    }
    @discardableResult private func проверить(_ получение: ((Data) throws -> Data)? = nil) throws -> ПровереннаяИдентичностьГостя {
        try ИдентичностьГостя.проверить(каталог: каталог, путь: корень.path, машина: машина,
                                       получитьКлюч: получение ?? получитьКлюч)
    }
    private func снимок() throws -> [String: String] {
        var ответ: [String: String] = [:]
        for имя in имена {
            var сведения = stat(); XCTAssertEqual(lstat(путь(имя), &сведения), 0)
            ответ[имя] = String(сведения.st_ino) + ":" + хэш(try Data(contentsOf: URL(fileURLWithPath: путь(имя))))
        }
        return ответ
    }
    func test_ПрежниеБайтыИПовторСохраняются() throws {
        let до = try снимок()
        XCTAssertEqual(try ИдентичностьГостя.настройка(машина: машина, путь: корень.path), настройка())
        XCTAssertEqual(try ИдентичностьГостя.известныйХост(машина: машина, публичныйКлюч: хост + "\n"), "fum-" + машина + " " + хост + "\n")
        var вызовов = 0
        for _ in 0..<2 {
            let ответ = try проверить { данные in вызовов += 1; return try self.получитьКлюч(данные) }
            XCTAssertEqual(ответ.машина, машина)
            XCTAssertEqual(ответ.конфигурация, путь("ssh_config"))
        }
        XCTAssertEqual(вызовов, 4)
        XCTAssertEqual(try снимок(), до)
        XCTAssertNotEqual(fcntl(каталог, F_GETFD), -1)
    }
    func test_НесоответствиеКаждойПарыНеПересоздаётся() throws {
        for имя in ["клиент", "хост"] {
            try сбросить(); try записать(имя + ".pub", ключ(3) + "\n")
            if имя == "хост" { try записать("known_hosts", "fum-" + машина + " " + ключ(3) + "\n") }
            let до = try снимок()
            XCTAssertThrowsError(try проверить())
            XCTAssertEqual(try снимок(), до)
        }
    }
    func test_ИзменённыеКонфигурацииОтклоняются() throws {
        func отклонитьБезИзменений() throws {
            let до = try снимок()
            XCTAssertThrowsError(try проверить())
            XCTAssertEqual(try снимок(), до)
        }
        let изменения = [("StrictHostKeyChecking yes", "StrictHostKeyChecking no"),
            ("HostName 127.0.0.1", "HostName чужой"), ("IdentityFile ", "IdentityFile /чужой "),
            ("UserKnownHostsFile ", "UserKnownHostsFile /чужой "), ("HostKeyAlias fum-", "HostKeyAlias чужой-")]
        for (старое, новое) in изменения {
            try сбросить(); try записать("ssh_config", настройка().replacingOccurrences(of: старое, with: новое))
            try отклонитьБезИзменений()
        }
        for строка in ["Include /чужое\n", "ProxyCommand /bin/true\n"] {
            try сбросить(); try записать("ssh_config", настройка() + строка); try отклонитьБезИзменений()
        }
        for текст in ["fum-чужой " + хост + "\n", "fum-" + машина + " " + ключ(3) + "\n",
                      "fum-" + машина + " " + хост + "\nлишняя строка\n"] {
            try сбросить(); try записать("known_hosts", текст); try отклонитьБезИзменений()
        }
    }
    func test_НекорректныеКлючиИИсходПолученияКлючаОтклоняются() throws {
        for текст in ["", "ssh-rsa AAAA", "ssh-ed25519 !!!", клиент + "\n" + клиент + "\n"] {
            try сбросить(); try записать("клиент.pub", текст); XCTAssertThrowsError(try проверить())
        }
        try сбросить(); try записать("клиент.pub", Data([0xff])); XCTAssertThrowsError(try проверить())
        try сбросить()
        for имя in ["клиент", "хост"] {
            let закрытыеБайты = Data(("открытый-макет-private-" + имя).utf8)
            let правильный = имя == "клиент" ? ключ(1) : ключ(2)
            for ответ in [Data(), Data([0xff]), Data("ssh-rsa AAAA\n".utf8), Data((правильный + "\n" + правильный).utf8)] {
                let до = try снимок()
                XCTAssertThrowsError(try проверить { данные in
                    if данные == закрытыеБайты { return ответ }
                    return try self.получитьКлюч(данные)
                })
                XCTAssertEqual(try снимок(), до)
            }
        }
        enum Отказ: Error { case срок }
        var вызван = false
        XCTAssertThrowsError(try проверить { _ in вызван = true; throw Отказ.срок }) { ошибка in
            guard case Отказ.срок = ошибка else { return XCTFail("Исход получения ключа подменён: \(ошибка)") }
        }
        XCTAssertTrue(вызван)
    }
    func test_ВсеШестьФайловПроверяютсяДоПолученияКлюча() throws {
        let ровноПредел = Data(repeating: 65, count: 64 * 1024)
        try записать("клиент", ровноПредел)
        var прочитанПредел = false
        try проверить { данные in
            if данные == ровноПредел { прочитанПредел = true; return Data((self.ключ(1) + "\n").utf8) }
            return try self.получитьКлюч(данные)
        }
        XCTAssertTrue(прочитанПредел)
        for имя in имена {
            try сбросить(); try записать(имя, Data())
            var вызовов = 0
            XCTAssertThrowsError(try проверить { данные in вызовов += 1; return try self.получитьКлюч(данные) })
            XCTAssertEqual(вызовов, 0, имя)
            try сбросить(); try записать(имя, Data(repeating: 65, count: 64 * 1024 + 1))
            XCTAssertThrowsError(try проверить { данные in вызовов += 1; return try self.получитьКлюч(данные) })
            XCTAssertEqual(вызовов, 0, имя)
            try сбросить(); XCTAssertEqual(chmod(путь(имя), 0o644), 0)
            XCTAssertThrowsError(try проверить { данные in вызовов += 1; return try self.получитьКлюч(данные) })
            XCTAssertEqual(вызовов, 0, имя)
        }
    }
    func test_СсылкиИОтсутствиеНеПринимаются() throws {
        var вызовов = 0
        func отклонить() {
            XCTAssertThrowsError(try проверить { данные in
                вызовов += 1; return try self.получитьКлюч(данные)
            })
            XCTAssertEqual(вызовов, 0)
        }
        XCTAssertEqual(chmod(корень.path + "/идентичность", 0o755), 0)
        отклонить()
        XCTAssertEqual(chmod(корень.path + "/идентичность", 0o700), 0)
        for имя in имена {
            try сбросить()
            let копия = корень.appendingPathComponent("копия-" + имя)
            try FileManager.default.moveItem(atPath: путь(имя), toPath: копия.path)
            отклонить()
            try FileManager.default.createSymbolicLink(atPath: путь(имя), withDestinationPath: копия.path)
            отклонить()
            try FileManager.default.removeItem(atPath: путь(имя))
            try FileManager.default.linkItem(atPath: копия.path, toPath: путь(имя))
            отклонить()
            try FileManager.default.removeItem(atPath: путь(имя)); try FileManager.default.removeItem(at: копия)
        }
        try сбросить()
        let прежний = корень.appendingPathComponent("бывшая-идентичность")
        try FileManager.default.moveItem(atPath: корень.path + "/идентичность", toPath: прежний.path)
        try FileManager.default.createSymbolicLink(atPath: корень.path + "/идентичность", withDestinationPath: прежний.path)
        отклонить()
    }
    func test_ПрофильПовторногоЧтения() throws {
        var интервалы: [UInt64] = []
        for _ in 0..<3 {
            let начало = DispatchTime.now().uptimeNanoseconds
            try проверить()
            интервалы.append(DispatchTime.now().uptimeNanoseconds - начало)
        }
        let медиана = интервалы.sorted()[1]
        XCTAssertLessThan(медиана, 100_000_000)
        let профиль: [String: Any] = ["схема": "fum.профиль-чтения-идентичности.1", "интервалы_нс": интервалы,
            "медиана_нс": медиана, "предкритерий_нс": 100_000_000,
            "вход_sha256": хэш(try кодировать(имена.map { try Data(contentsOf: URL(fileURLWithPath: путь($0))) })), "получение_ключа": "открытая фикстура без процесса; настоящий ssh-keygen проверяется отдельно"]
        print("ПРОФИЛЬ_ИДЕНТИЧНОСТИ=" + String(decoding: try JSONSerialization.data(withJSONObject: профиль, options: [.sortedKeys]), as: UTF8.self))
    }
}
