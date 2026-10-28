import Foundation
import CryptoKit
import Darwin

// Конечный системный адаптер переноса незакоммиченной постановки.
// Исходный новый документ сохраняется побайтно; старый tracked-файл не переносится.
@main enum ПереносПостановки {
    enum Отказ: Error { case условие(String) }

    static func требовать(_ условие: Bool, _ причина: String) throws {
        if !условие { throw Отказ.условие(причина) }
    }

    static func хэш(_ данные: Data) -> String {
        SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    static func гит(_ корень: URL, _ аргументы: [String]) throws -> Data {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["--no-optional-locks", "-C", корень.path] + аргументы
        var среда = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        среда["GIT_OPTIONAL_LOCKS"] = "0"
        среда["GIT_NO_REPLACE_OBJECTS"] = "1"
        среда["GIT_NO_LAZY_FETCH"] = "1"
        процесс.environment = среда
        let канал = Pipe()
        процесс.standardOutput = канал
        процесс.standardError = FileHandle.nullDevice
        try процесс.run()
        let данные = канал.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        try требовать(процесс.terminationStatus == 0, "отказ-чтения-Git")
        return данные
    }

    static func сохранитьНовый(_ данные: Data, _ адрес: URL) throws {
        try данные.write(to: адрес, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: адрес.path)
        let файл = try FileHandle(forWritingTo: адрес)
        try файл.synchronize()
        try файл.close()
    }

    static func main() {
        do { try выполнить() }
        catch {
            try? FileHandle.standardError.write(contentsOf: Data(("отказ: " + String(describing: error) + "\n").utf8))
            exit(2)
        }
    }

    static func выполнить() throws {
        let аргументы = Array(CommandLine.arguments.dropFirst())
        try требовать(аргументы.count == 4, "нужны-корень-SHA-режим-приватное-намерение")
        let корень = URL(fileURLWithPath: аргументы[0])
        let ожидаемыйХэш = аргументы[1]
        let режим = аргументы[2]
        let намерение = URL(fileURLWithPath: аргументы[3])
        try требовать(["план", "применить"].contains(режим), "неизвестный-режим")
        try требовать(корень.path == корень.standardizedFileURL.path
            && корень.path == корень.resolvingSymlinksInPath().path, "нефизический-корень")
        try требовать(ProcessInfo.processInfo.environment["CODEX_THREAD_ID"]
            == "01a148a5-c088-7373-9665-a3f9b477565e", "чужой-писатель")
        let основа = "6796c71c1e00054096c5f281e43137f593d394cb"
        let полныйRef = "refs/heads/fum-lab/fum/instrumentyi/imena-katalogov/chastj-swift/master"
        let исходноеИмя = "Планирование/aktualizaciya-putej.md"
        let исходник = корень.appendingPathComponent(исходноеИмя)
        let каталог = корень.appendingPathComponent("iskhodniki/aktualizaciya-putej/kontraktyi")
        let снимок = каталог.appendingPathComponent("iskhodnaya-postanovka.txt")
        let документ = каталог.appendingPathComponent("kontrakt-paketa-perenosa.md")
        try требовать(исходник.path == исходник.resolvingSymlinksInPath().path
            && каталог.path == каталог.resolvingSymlinksInPath().path, "символический-компонент")
        let свойства = try FileManager.default.attributesOfItem(atPath: исходник.path)
        try требовать(свойства[.type] as? FileAttributeType == .typeRegular
            && (свойства[.referenceCount] as? NSNumber)?.intValue == 1
            && (свойства[.posixPermissions] as? NSNumber)?.intValue == 0o644, "необычный-исходник")
        let исходные = try Data(contentsOf: исходник)
        try требовать(хэш(исходные) == ожидаемыйХэш, "дрейф-исходной-постановки")
        let базовые = try гит(корень, ["show", основа + ":" + исходноеИмя])
        try требовать(хэш(базовые) == "288eaae2ad65bab3f4819ebdd8c70ed58acf9fe862e808e049ccfd67a1823cb9",
            "подменена-принятая-постановка")
        let начало = Data("\n## Следующий конечный срез: пакетное применение девяти имён архива\n".utf8)
        let конец = Data("\n## Источники\n".utf8)
        guard let левый = исходные.range(of: начало),
              let правый = исходные.range(of: конец, in: левый.upperBound..<исходные.endIndex) else {
            throw Отказ.условие("нет-единственного-нового-раздела")
        }
        try требовать(исходные.range(of: начало, in: левый.upperBound..<исходные.endIndex) == nil,
            "повтор-нового-раздела")
        var восстановленные = исходные
        восстановленные.removeSubrange(левый.lowerBound..<правый.lowerBound)
        try требовать(восстановленные == базовые, "изменения-вне-нового-раздела")
        let раздел = исходные.subdata(in: левый.lowerBound..<правый.lowerBound)
        guard var текст = String(data: раздел, encoding: .utf8) else { throw Отказ.условие("не-UTF8") }
        let прежнее = "Реализация и открытые фикстуры остаются в существующих `iskhodniki/aktualizaciya-putej` и `proverki/aktualizaciya-putej`, с вычисленными ASCII kebab-именами новых исходников."
        let новое = "Новая реализация и результаты находятся в `iskhodniki/aktualizaciya-putej` и её собственных подкаталогах. Новые тесты размещаются в `iskhodniki/aktualizaciya-putej/proverki`, исключаются из production target и подключаются отдельным точным test target. Уже отслеживаемые старые тесты `proverki/aktualizaciya-putej` не перемещаются. Имена новых файлов вычисляются как ASCII kebab-case."
        try требовать(текст.components(separatedBy: прежнее).count == 2, "неизвестная-исходная-граница-тестов")
        текст = текст.replacingOccurrences(of: прежнее, with: новое)
        текст = "# Контракт пакетного переноса имён архива\n" + текст + """


        ## Поздние уточнения и фактическое состояние

        Принятая общая постановка в `Планирование/aktualizaciya-putej.md` восстанавливается до точных байтов основы 679. Её незакоммиченный новый вариант полностью сохранён рядом в `iskhodnaya-postanovka.txt`; это источник перехода, а не новая активная версия общего плана. Все новые результаты этапа остаются в собственной области компонента.

        Исторические карта и snapshot Cfd сохраняют происхождение имён. Актуальный live-source выбирается после локального журнального checkpoint владельца RAW. Package-adapter не ожидает вслепую Package из Cfd: в выбранном текущем target `АрхивКодекса` исключение `["README.md", "zhurnal"]` становится `["rukovodstvo.md", "zhurnal"]`, с сохранением остальных байтов и отдельной привязкой SHA.

        Автоматизация описывается структурирующей программой FUMA, затем исполняется Swift-примитивами. Готовые `fum.определение-оператора.2`, `AutomationExecutor` и `КонтейнерНаблюдений` подлежат адресному переиспользованию для чистого решения и долговечного наблюдения. Внешние Git/FS-эффекты текущим языком операторов не реализованы; нужен узкий Swift-адаптер, а не новый параллельный язык. Полный Markdown-корпус остаётся за пределами ограниченного значения FUMA; оператор получает проверенный нормализованный снимок. Текущий локальный JSON — запись постановки, а не уже исполненная FUMA-программа.

        Прикладной batch ещё не реализован. Следующий шаг — различающий Swift Testing RED и реальное исполнение чистого решения через существующий AutomationExecutor, затем snapshot/fence, intent и отдельно разрешаемое применение. Общий ремонт журнала, #380 и полный генератор манифеста в этот срез не входят.
        """ + "\n"
        let новыеБайты = Data(текст.utf8)
        func сверить() throws {
            try требовать(try гит(корень, ["rev-parse", "HEAD"]) == Data((основа + "\n").utf8), "дрейф-HEAD")
            try требовать(try гит(корень, ["symbolic-ref", "HEAD"]) == Data((полныйRef + "\n").utf8), "дрейф-ref")
            try требовать(try Data(contentsOf: исходник) == исходные, "поздний-дрейф-постановки")
            try требовать(!FileManager.default.fileExists(atPath: снимок.path)
                && !FileManager.default.fileExists(atPath: документ.path), "существующий-результат")
        }
        try сверить()
        let итог: [String: String] = ["схема": "fum.перенос-незакоммиченной-постановки.1",
            "режим": режим, "исходник": исходноеИмя, "исходный_хэш": хэш(исходные),
            "база_хэш": хэш(базовые), "раздел_хэш": хэш(раздел), "документ_хэш": хэш(новыеБайты),
            "снимок": "iskhodniki/aktualizaciya-putej/kontraktyi/iskhodnaya-postanovka.txt",
            "документ": "iskhodniki/aktualizaciya-putej/kontraktyi/kontrakt-paketa-perenosa.md"]
        let данные = try JSONSerialization.data(withJSONObject: итог, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) + Data([10])
        if режим == "применить" {
            try требовать(намерение.path == намерение.resolvingSymlinksInPath().path
                && !намерение.path.hasPrefix(корень.path + "/"), "намерение-не-приватно")
            try сохранитьНовый(данные, намерение)
            try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: false)
            try сверить()
            try сохранитьНовый(исходные, снимок)
            try сохранитьНовый(новыеБайты, документ)
            try требовать(try Data(contentsOf: снимок) == исходные
                && Data(contentsOf: документ) == новыеБайты
                && Data(contentsOf: исходник) == исходные, "дрейф-перед-восстановлением")
            try базовые.write(to: исходник, options: .atomic)
            try требовать(try Data(contentsOf: исходник) == базовые
                && Data(contentsOf: снимок) == исходные, "неполный-перенос")
        }
        try FileHandle.standardOutput.write(contentsOf: данные)
    }
}
