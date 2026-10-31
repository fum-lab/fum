import Foundation
import CryptoKit
import Testing
import Darwin
@testable import Целостность

private enum СбойПроверки: Error { case отказНеПолучен, фикстура, файл }

@MainActor
private enum Фикстуры {
    static var корни: [Int: URL] = [:]
    static func git(_ корень: URL, _ а: [String], _ вход: Data = Data()) throws -> Data {
        let р = try ограниченныйGit(а, корень: корень, вход: вход)
        try #require(р.код == 0)
        return р.выход
    }
    static func идентификаторОбъекта(_ корень: URL, _ а: [String], _ вход: Data = Data()) throws -> String {
        let д = try git(корень, а, вход)
        try #require(д.count == 41 && д.last == 10)
        let о = String(decoding: д.dropLast(), as: UTF8.self)
        try #require(шестнадцатеричный(о, 40))
        return о
    }
    struct Запись {
        let путь: String
        let режим: String
        let вид: String
        let объект: String
    }
    static func дерево(_ корень: URL, _ записи: [Запись]) throws -> String {
        var листья: [Запись] = [], папки: [String: [Запись]] = [:]
        for з in записи {
            let ч = з.путь.split(separator: "/", maxSplits: 1)
            if ч.count == 1 { листья.append(з) }
            else { папки[String(ч[0]), default: []].append(.init(путь: String(ч[1]), режим: з.режим, вид: з.вид, объект: з.объект)) }
        }
        for имя in папки.keys.sorted() {
            листья.append(.init(путь: имя, режим: "040000", вид: "tree", объект: try дерево(корень, папки[имя]!)))
        }
        var д = Data()
        for з in листья.sorted(by: { $0.путь.utf8.lexicographicallyPrecedes($1.путь.utf8) }) {
            д.append(Data("\(з.режим) \(з.вид) \(з.объект)\t\(з.путь)".utf8)); д.append(0)
        }
        return try идентификаторОбъекта(корень, ["mktree", "-z"], д)
    }
    static func коммит(_ корень: URL, _ дерево: String, _ родитель: String?, _ тема: String) throws -> String {
        var с = ["tree " + дерево]
        if let родитель { с.append("parent " + родитель) }
        с += ["author Fixture <fixture@example.invalid> 0 +0000", "committer Fixture <fixture@example.invalid> 0 +0000", "", тема, ""]
        return try идентификаторОбъекта(корень, ["hash-object", "-t", "commit", "-w", "--stdin"], Data(с.joined(separator: "\n").utf8))
    }
    static func пины(_ число: Int) -> (String, String) {
        число == 14 ? ("0fdc09272bac9abd55430a7c56996541a366a0c7", "6243a9e8f99804e7d9d85ab672b81bfedcf3ed25")
        : ("a43f220fc322da2e48cc3bffd5f0ac5124b011ba", "e7203496ac9fb0b3ad03add2cc8465e6d7afb53b")
    }
    static func корень(_ число: Int) throws -> URL {
        if let к = корни[число] { return к }
        let дом = try #require(ProcessInfo.processInfo.environment["ФУМ_СБОРКА"])
        let к = URL(fileURLWithPath: дом).appendingPathComponent("fixture-" + UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: к, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        _ = try git(к, ["init", "--quiet", "--initial-branch=fixture"])
        let пустое = try дерево(к, [])
        try #require(пустое == "4b825dc642cb6eb9a060e54bf8d69288fbee4904")
        let якорь = try коммит(к, пустое, nil, "fixture-anchor")
        var рабочие: [(String, Data, Int)] = []
        func блоб(_ путь: String, _ д: Data, _ режим: String) throws -> Запись {
            рабочие.append((путь, д, режим == "100755" ? 0o755 : 0o644))
            return .init(путь: путь, режим: режим, вид: "blob", объект: try идентификаторОбъекта(к, ["hash-object", "-w", "--stdin"], д))
        }
        let общий = try блоб("неизменённый.txt", Data("Сохранить\n".utf8), "100644")
        let базаЗаписи = [общий, Запись(путь: "внешняя", режим: "160000", вид: "commit", объект: якорь)]
        let база = try коммит(к, дерево(к, базаЗаписи), якорь, "fixture-base")
        try #require(база == "3e8f46d53bc6496ea646a051250a891e7e0635f4")
        var записи = базаЗаписи
        for номер in 0..<число {
            let путь: String
            switch номер {
            case 0: путь = "пустой ё.txt"
            case 1: путь = "каталог с пробелом/данные 01.txt"
            case 2: путь = "каталог с пробелом/$(не-выполнять).txt"
            case 3: путь = "-данные.txt"
            default: путь = "каталог ё/файл-" + (номер < 10 ? "0" : "") + "\(номер).txt"
            }
            записи.append(try блоб(путь, номер == 0 ? Data() : Data("Набор \(число), файл \(номер)\n".utf8), номер % 5 == 0 ? "100755" : "100644"))
        }
        if число == 14 { записи.append(try блоб("необъявленный.txt", Data("Вне подмножества\n".utf8), "100644")) }
        let д = try дерево(к, записи), с = try коммит(к, д, база, "fixture-\(число)")
        try #require(с == пины(число).0 && д == пины(число).1)
        _ = try git(к, ["update-ref", "refs/heads/fixture", с])
        _ = try git(к, ["read-tree", с])
        for (п, д, режим) in рабочие {
            let цель = к.appendingPathComponent(п)
            try FileManager.default.createDirectory(at: цель.deletingLastPathComponent(), withIntermediateDirectories: true)
            try д.write(to: цель, options: .withoutOverwriting)
            try FileManager.default.setAttributes([.posixPermissions: режим], ofItemAtPath: цель.path)
        }
        корни[число] = к
        return к
    }
}

private func снимок(_ корень: URL) throws -> [String: String] {
    var итог: [String: String] = [:], сумма = 0
    func пройти(_ к: URL, _ путь: String, _ глубина: Int) throws {
        try #require(глубина <= 32 && итог.count < 4_096)
        var до = stat()
        try #require(lstat(к.path, &до) == 0)
        if до.st_mode & S_IFMT == S_IFDIR {
            итог[путь] = "dir:\(до.st_mode)"
            for имя in try FileManager.default.contentsOfDirectory(atPath: к.path).sorted() {
                try пройти(к.appendingPathComponent(имя), путь + "/" + имя, глубина + 1)
            }
            return
        }
        try #require(до.st_mode & S_IFMT == S_IFREG && до.st_size >= 0 && до.st_size <= 8_388_608 - сумма)
        let д = Darwin.open(к.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        try #require(д >= 0)
        let ф = FileHandle(fileDescriptor: д, closeOnDealloc: true)
        defer { try? ф.close() }
        var хэш = SHA256(), размер = 0
        while let часть = try ф.read(upToCount: 16_384), !часть.isEmpty {
            размер += часть.count
            try #require(размер <= до.st_size)
            хэш.update(data: часть)
        }
        var после = stat()
        try #require(fstat(д, &после) == 0 && до.st_dev == после.st_dev && до.st_ino == после.st_ino &&
                     до.st_size == после.st_size && размер == до.st_size &&
                     до.st_mtimespec.tv_sec == после.st_mtimespec.tv_sec && до.st_mtimespec.tv_nsec == после.st_mtimespec.tv_nsec &&
                     до.st_ctimespec.tv_sec == после.st_ctimespec.tv_sec && до.st_ctimespec.tv_nsec == после.st_ctimespec.tv_nsec)
        сумма += размер
        итог[путь] = "\(до.st_mode):\(размер):" + хэш.finalize().map { String(format: "%02x", $0) }.joined()
    }
    try пройти(корень, "", 0)
    return итог
}

@Suite(.serialized)
@MainActor
struct ПроверкиЦелостности {
    private func данные(_ число: Int = 14) throws -> Data {
        let п = try #require(Bundle.module.url(forResource: "состав-\(число)", withExtension: "json"))
        return try Data(contentsOf: п)
    }
    private func документJSON(_ о: [String: Any]) throws -> Data {
        var д = try JSONSerialization.data(withJSONObject: о, options: [.sortedKeys, .withoutEscapingSlashes])
        д.append(10); return д
    }
    private func объект(_ д: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: д) as? [String: Any])
    }
    private func изменить(_ д: Data, _ ф: (inout [String: Any]) throws -> Void) throws -> Data {
        var о = try объект(д); try ф(&о); return try документJSON(о)
    }
    private func файл(_ д: Data, _ ф: (inout [String: Any]) -> Void) throws -> Data {
        try изменить(д) { о in
            var фф = try #require(о["файлы"] as? [[String: Any]])
            ф(&фф[0]); о["файлы"] = фф
        }
    }
    private func отказ(_ причина: String, _ код: Int32 = 1, _ ф: () throws -> Void) throws {
        do { try ф(); Issue.record("Ожидаемый адресный отказ не получен"); throw СбойПроверки.отказНеПолучен }
        catch let о as ОтказЦелостности {
            try #require(о.причина == причина && о.выход == код && !о.доказано)
        }
    }
    private func квитанция(_ случай: String) throws {
        let к = try #require(ProcessInfo.processInfo.environment["ФУМ_КВИТАНЦИИ"])
        try документJSON(["схема": "fum.квитанция-проверки.1", "случай": случай, "состояние": "завершён"])
            .write(to: URL(fileURLWithPath: к).appendingPathComponent(случай + ".json"), options: .withoutOverwriting)
    }
    private func проверить(_ д: Data, _ число: Int = 14) throws -> Int {
        let м = try МанифестЦелостности.прочитать(д)
        return try ПроверкаОбъектов(корень: Фикстуры.корень(число), формат: м.источник.формат).проверить(м)
    }
    private func кли(_ д: Data, _ число: Int = 14, _ добавки: [String: String] = [:]) throws -> ОтветGit {
        let средаТеста = ProcessInfo.processInfo.environment
        let программа = try #require(средаТеста["ФУМ_ПРОВЕРЯЮЩИЙ"])
        let дом = try #require(средаТеста["ФУМ_СБОРКА"])
        let вход = URL(fileURLWithPath: дом).appendingPathComponent(UUID().uuidString.lowercased() + ".json")
        try д.write(to: вход, options: .withoutOverwriting)
        var среда = ["PATH": "/usr/bin:/bin", "LC_ALL": "C"]
        среда.merge(добавки) { _, новое in новое }
        return try ограниченныйПроцесс(программа, ["--корень", Фикстуры.корень(число).path, "--манифест", вход.path], среда: среда)
    }
    @Test func структураJSON() throws {
        let д = try данные(); try проверитьJSON(д)
        for ключ in ["база", "идентификатор"] {
            let п = try изменить(д) { $0.removeValue(forKey: ключ) }
            try отказ("ключи") { try проверитьJSON(п) }
        }
        let л = try изменить(д) { $0["лишнее"] = true }
        try отказ("ключи") { try проверитьJSON(л) }
        let с = try изменить(д) { $0["схема"] = "будущая" }
        try отказ("схема") { try проверитьJSON(с) }
        for п in [Data([255, 10]), Data([239,187,191]) + д, д + Data("{}\n".utf8), Data(д.dropLast())] {
            try отказ("формат") { try проверитьJSON(п) }
        }
        try квитанция("json")
    }
    @Test func дублиКлючей() throws {
        try проверитьJSON(данные())
        for текст in ["{\"ключ\":1,\"ключ\":2}\n", "{\"ключ\":1,\"\\u043aлюч\":2}\n"] {
            try отказ("ключи") { try проверитьJSON(Data(текст.utf8)) }
        }
        try квитанция("дубли")
    }
    @Test func пути() throws {
        let д = try данные()
        for п in ["/данные", ".", "..", "а/../б", "а/./б", "а//б", "а\\б", "C:/данные", ".git/config", "е\u{0308}.txt"] {
            let з = try файл(д) { $0["путь"] = п }
            try отказ("путь") { try проверитьJSON(з) }
        }
        let дубль = try изменить(д) { о in
            var ф = try #require(о["файлы"] as? [[String: Any]]); ф[1]["путь"] = ф[0]["путь"]; о["файлы"] = ф
        }
        try отказ("путь") { try проверитьJSON(дубль) }
        try квитанция("пути")
    }
    @Test func целые() throws {
        let д = try документJSON(объект(данные()))
        let с = String(decoding: д, as: UTF8.self)
        try #require(с.components(separatedBy: "\"байты\":0").count == 2)
        for число in ["true", "-1", "0.5", "0e0", "18446744073709551616"] {
            let п = Data(с.replacingOccurrences(of: "\"байты\":0", with: "\"байты\":" + число).utf8)
            try отказ("число") { try проверитьJSON(п) }
        }
        try квитанция("целые")
    }
    @Test func положительные() throws {
        for ч in [14,48] {
            let д = try данные(ч), м = try МанифестЦелостности.прочитать(д)
            try #require(м.файлы.count == ч && м.источник.коммит == Фикстуры.пины(ч).0 && м.источник.дерево == Фикстуры.пины(ч).1)
            try #require(проверить(д, ч) == м.файлы.reduce(0) { $0 + Int($1.байты) })
        }
        let а = try МанифестЦелостности.прочитать(данные(14)), б = try МанифестЦелостности.прочитать(данные(48))
        try #require(а.идентификатор != б.идентификатор && а.источник.ссылка != б.источник.ссылка)
        try квитанция("положительные")
    }
    @Test func форматы() throws {
        let д = try данные()
        for о in [String(repeating: "f", count:39), String(repeating:"g",count:40), String(repeating:"A",count:40)] {
            let п = try изменить(д) { к in
                var с = try #require(к["источник"] as? [String:Any]); с["коммит"] = о; к["источник"] = с
            }
            try отказ("пин") { try проверитьJSON(п) }
        }
        let п = try изменить(д) { к in
            var с = try #require(к["источник"] as? [String:Any]); с["формат_объектов"] = "sha512"; к["источник"] = с
        }
        try отказ("формат-объектов") { try проверитьJSON(п) }
        try #require(хэшОбъекта("blob", Data(), "sha256") == "473a0f4c3be8a93681a267e3b1e9a7dcda1185436fe141f7749120a303721813")
        try квитанция("форматы")
    }
    @Test func объектыGit() throws {
        let д = try данные()
        for (поле, значение, причина) in [
            ("режим", "100644" as Any, "режим"),
            ("объект", String(repeating:"f",count:40) as Any, "объект"),
            ("байты", 1 as Any, "размер"),
            ("хэш", String(repeating:"f",count:64) as Any, "хэш")
        ] {
            let п = try файл(д) { $0[поле] = значение }
            try отказ(причина) { _ = try проверить(п) }
        }
        let п = try изменить(д) { к in
            var с = try #require(к["источник"] as? [String:Any]); с["дерево"] = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"; к["источник"] = с
        }
        try отказ("дерево-коммита") { _ = try проверить(п) }
        try квитанция("git")
    }
    @Test func состав() throws {
        let д = try данные(48)
        let п = try изменить(д) { о in
            var ф = try #require(о["файлы"] as? [[String:Any]]); ф.removeLast(); о["файлы"] = ф; о["число_файлов"] = ф.count
        }
        try отказ("состав") { _ = try проверить(п,48) }
        let б = try изменить(д) { $0["база"] = NSNull() }
        try отказ("база") { try проверитьJSON(б) }
        let нет = try изменить(д) { о in о["база"] = о["источник"]; о["файлы"] = []; о["число_файлов"] = 0 }
        try #require(проверить(нет,48) == 0)
        // Удаление и переход обычного файла в каталог — явные unsupported.
        let р = try Фикстуры.корень(48), исходный = try МанифестЦелостности.прочитать(д)
        let пустое = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
        let удаление = try Фикстуры.коммит(р, пустое, исходный.источник.коммит, "delete")
        let удалённый = try изменить(нет) { о in
            var с = try #require(о["источник"] as? [String:Any]); с["коммит"] = удаление; с["дерево"] = пустое; о["источник"] = с
        }
        try отказ("тип-изменения",2) { _ = try проверить(удалённый,48) }
        var записи = исходный.файлы.map { ф in
            Фикстуры.Запись(путь: ф.путь == "пустой ё.txt" ? ф.путь + "/внутри" : ф.путь,
                            режим: ф.режим, вид: "blob", объект: ф.объект)
        }
        записи += [
            .init(путь:"неизменённый.txt",режим:"100644",вид:"blob",объект:"dc99015e643dbecf85fb7a2cdf263e8aab00c169"),
            .init(путь:"внешняя",режим:"160000",вид:"commit",объект:"5c2dc5954bdcbaf52ab32bf7d5726a2ef5e80723")
        ]
        let дерево = try Фикстуры.дерево(р,записи), коммит = try Фикстуры.коммит(р,дерево,исходный.источник.коммит,"type")
        let смена = try изменить(нет) { о in
            var с = try #require(о["источник"] as? [String:Any]); с["коммит"] = коммит; с["дерево"] = дерево; о["источник"] = с
        }
        try отказ("тип-изменения",2) { _ = try проверить(смена,48) }
        try квитанция("состав")
    }
    @Test func ссылки() throws {
        let д = try данные()
        for путь in ["внешняя", "внешняя/внутри.txt"] {
            let п = try файл(д) { $0["путь"] = путь }
            try отказ("тип-пути",2) { _ = try проверить(п) }
        }
        let р = try Фикстуры.корень(14)
        let объект = try Фикстуры.идентификаторОбъекта(р, ["hash-object","-w","--stdin"], Data("цель".utf8))
        let дерево = try Фикстуры.дерево(р,[.init(путь:"ссылка",режим:"120000",вид:"blob",объект:объект)])
        let коммит = try Фикстуры.коммит(р,дерево,nil,"symlink")
        let п = try изменить(д) { о in
            var с = try #require(о["источник"] as? [String:Any]); с["коммит"] = коммит; с["дерево"] = дерево; о["источник"] = с
            var ф = try #require(о["файлы"] as? [[String:Any]]); ф[0]["путь"] = "ссылка"; о["файлы"] = [ф[0]]; о["число_файлов"] = 1
        }
        try отказ("тип-пути",2) { _ = try проверить(п) }
        try квитанция("ссылки")
    }
    @Test func лимиты() throws {
        try отказ("предел",2) { try проверитьJSON(Data(repeating:32,count:262_145)) }
        let д = try файл(данные()) { $0["байты"] = 4_194_305 }
        try отказ("предел",2) { try проверитьJSON(д) }
        try отказ("предел",2) { try проверитьJSON(Data((String(repeating:"[",count:9)+"0"+String(repeating:"]",count:9)+"\n").utf8)) }
        let м = try данные()
        let п = try изменить(м) { о in
            let ф = try #require(о["файлы"] as? [[String:Any]])
            о["файлы"] = Array(repeating:ф[0],count:257); о["число_файлов"] = 257
        }
        try отказ("предел",2) { try проверитьJSON(п) }
        let р = try Фикстуры.корень(14)
        let дом = try #require(ProcessInfo.processInfo.environment["ФУМ_СБОРКА"])
        let большой = URL(fileURLWithPath:дом).appendingPathComponent("blob-" + UUID().uuidString.lowercased())
        try Data(repeating:65,count:4_194_305).write(to:большой,options:.withoutOverwriting)
        let объект = try Фикстуры.идентификаторОбъекта(р,["hash-object","-w","--",большой.path])
        let дерево = try Фикстуры.дерево(р,[.init(путь:"большой",режим:"100644",вид:"blob",объект:объект)])
        let коммит = try Фикстуры.коммит(р,дерево,nil,"oversized")
        let огромный = try изменить(м) { о in
            var с = try #require(о["источник"] as? [String:Any]); с["коммит"] = коммит; с["дерево"] = дерево; о["источник"] = с
            var ф = try #require(о["файлы"] as? [[String:Any]])
            ф[0]["путь"] = "большой"; ф[0]["режим"] = "100644"; ф[0]["объект"] = объект
            о["файлы"] = [ф[0]]; о["число_файлов"] = 1
        }
        try отказ("предел",2) { _ = try проверить(огромный) }
        try квитанция("лимиты")
    }
    @Test func окружение() throws {
        let б = try Фикстуры.корень(48), д = try данные()
        for среда in [
            ["GIT_DIR":б.appendingPathComponent(".git").path],
            ["GIT_OBJECT_DIRECTORY":б.appendingPathComponent(".git/objects").path],
            ["GIT_CONFIG_COUNT":"not-an-integer"], ["PATH":"/не-существует"]
        ] {
            let р = try кли(д,14,среда)
            try #require(р.код == 0 && (try объект(р.выход)["целостность"] as? Bool) == true)
        }
        let а = try Фикстуры.корень(14)
        let р = try кли(д,48,["GIT_ALTERNATE_OBJECT_DIRECTORIES":а.appendingPathComponent(".git/objects").path])
        try #require(р.код == 2 && (try объект(р.выход)["причина"] as? String) == "объект-недоступен")
        try квитанция("окружение")
    }
    @Test func неизменность() throws {
        let р = try Фикстуры.корень(14), до = try снимок(р), д = try данные()
        try #require(кли(д).код == 0)
        try #require(снимок(р) == до)
        let п = try файл(д) { $0["хэш"] = String(repeating:"f",count:64) }
        try #require(кли(п).код == 1)
        try #require(снимок(р) == до)
        try квитанция("неизменность")
    }
    @Test func профиль() throws {
        let р = try кли(данные()), п = try объект(р.ошибки)
        try #require(р.код == 0 && р.выход.count <= 8_192 && р.ошибки.count <= 2_048)
        try #require(п["схема"] as? String == "fum.профиль-целостности-исходников.1")
        let время = try #require(п["наносекунды"] as? UInt64)
        try #require(время > 0 && время <= 30_000_000_000)
        try #require(п["байты_результата"] as? Int == р.выход.count)
        try #require((п["прочитано_тел_объектов"] as? Int ?? 0) > 0)
        let к = try Фикстуры.корень(14)
        try #require(!String(decoding:р.выход,as:UTF8.self).contains(к.path))
        try квитанция("профиль")
    }
}


private func сохранитьПробу() throws {
    guard let каталог = ProcessInfo.processInfo.environment["ФУМ_КВИТАНЦИИ"] else {
        throw NSError(domain: "проба", code: 1)
    }
    var байты = try JSONSerialization.data(withJSONObject: [
        "схема": "fum.квитанция-проверки.1", "случай": "проба", "состояние": "завершён",
        "процесс": getpid(), "группа": getpgrp(), "сессия": getsid(0)
    ], options: [.prettyPrinted, .sortedKeys])
    байты.append(10)
    try байты.write(to: URL(fileURLWithPath: каталог).appendingPathComponent("проба.json"),
                    options: .withoutOverwriting)
}

@Suite(.serialized)
struct ПробаСвязности {
    @Test func проверкаСвязности() throws {
        #expect(ProcessInfo.processInfo.environment["ФУМ_ПРОБА"] != "отказ")
        try сохранитьПробу()
    }
}
