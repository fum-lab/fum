import Foundation
import Darwin

func требовать(_ условие: @autoclosure () -> Bool, _ имя: String) {
    if !условие() { let д = Data("ОТКАЗ \(имя)\n".utf8); _ = д.withUnsafeBytes { Darwin.write(STDERR_FILENO, $0.baseAddress, $0.count) }; Darwin._exit(1) }
}
let исходная = ПрофильСреды.создать(идентификатор: "00000000-0000-4000-8000-000000000001")
требовать(исходная["GIT_CONFIG_NOSYSTEM"] == "1" && исходная["GIT_CONFIG_GLOBAL"] == "/dev/null" &&
          исходная["GIT_ATTR_NOSYSTEM"] == "1" && исходная["GIT_CONFIG_COUNT"] == nil &&
          исходная["HOME"] == nil && исходная["PYTHONPATH"] == nil && исходная["LD_PRELOAD"] == nil, "среда")
let безопасная = ПрофильGit(локальнаяКонфигурация: Data("[core]\n\tbare = false\n".utf8),
                             утверждённаяКонфигурация: Data("[core]\n\tbare = false\n".utf8),
                             корневыеАтрибуты: nil, служебныеАтрибуты: nil,
                             полныйСоставАтрибутовПодтверждён: false)
требовать(безопасная.проверить() == .неизвестно, "неполные атрибуты")
let совпавшая = ПрофильGit(локальнаяКонфигурация: безопасная.локальнаяКонфигурация,
                           утверждённаяКонфигурация: безопасная.утверждённаяКонфигурация,
                           корневыеАтрибуты: nil, служебныеАтрибуты: nil,
                           полныйСоставАтрибутовПодтверждён: true)
требовать(совпавшая.проверить() == .неизвестно, "совпадение не даёт допуска")
требовать(ПрофильСреды.создать(идентификатор: "не-uuid").isEmpty, "неверный идентификатор")
let фильтр = Data("[filter \"hostile\"]\n\tclean = touch marker\n".utf8)
let локальнаяПодмена = ПрофильGit(локальнаяКонфигурация: фильтр,
                                  утверждённаяКонфигурация: безопасная.утверждённаяКонфигурация,
                                  корневыеАтрибуты: nil, служебныеАтрибуты: nil,
                                  полныйСоставАтрибутовПодтверждён: true)
требовать(локальнаяПодмена.проверить() == .отказ, "локальная конфигурация")
let подменаАтрибутов = ПрофильGit(локальнаяКонфигурация: безопасная.локальнаяКонфигурация,
                                 утверждённаяКонфигурация: безопасная.утверждённаяКонфигурация,
                                 корневыеАтрибуты: Data("* filter=hostile\n".utf8), служебныеАтрибуты: nil,
                                 полныйСоставАтрибутовПодтверждён: true)
требовать(подменаАтрибутов.проверить() == .отказ, "атрибуты")
print("ПРОЙДЕНО чистая модель без допуска Git")
// Отдельный искусственный include проверяет отказ до потребителя, а не разрешение Git.
if CommandLine.arguments.count == 4 && CommandLine.arguments[3] == "include" {
    let корень = URL(fileURLWithPath:CommandLine.arguments[1],isDirectory:true)
    guard let local=try? Data(contentsOf:корень.appendingPathComponent(".git/config")),
          let approved=try? Data(contentsOf:корень.appendingPathComponent("approved-config")),
          let external=try? Data(contentsOf:корень.appendingPathComponent("external.gitconfig")),
          let attributes=try? Data(contentsOf:корень.appendingPathComponent("hostile.attributes")),
          local.range(of:Data("[include]".utf8)) != nil, external.range(of:Data("attributesfile".utf8)) != nil,
          attributes==Data("fixture.txt filter=hostile\n".utf8) else { требовать(false,"include фикстура"); exit(1) }
    let профиль=ПрофильGit(локальнаяКонфигурация:local,утверждённаяКонфигурация:approved,
                           корневыеАтрибуты:nil,служебныеАтрибуты:nil,полныйСоставАтрибутовПодтверждён:false)
    var вызовы=0
    func доПотребителя(_ профиль:ПрофильGit,_ потребитель:()->Void)->ИсходПрофиля {
        switch профиль.проверить() { case .отказ: return .отказ; case .неизвестно: return .неизвестно }
    }
    let итог=доПотребителя(профиль) {
        вызовы += 1
        let p=Process(); p.executableURL=URL(fileURLWithPath:CommandLine.arguments[2])
        p.arguments=["-C",корень.path,"-c","core.fsmonitor=false","diff","--binary","--no-ext-diff","--no-textconv","--ignore-submodules=dirty","--","."]
        p.environment=исходная
        do { try p.run(); p.waitUntilExit() } catch { требовать(false,"потребитель UNKNOWN") }
    }
    требовать(итог == .отказ && вызовы == 0 && !FileManager.default.fileExists(atPath:корень.appendingPathComponent("filter-executed").path),"include до потребителя")
    print("ПРОЙДЕНО include: отказ до Git, вызовы=0, marker отсутствует")
    exit(0)
}
требовать(CommandLine.arguments.count == 3 && CommandLine.arguments[2].hasPrefix("/") && !CommandLine.arguments[2].split(separator: "/").contains(".."), "пути фикстуры")
let корень = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let репозиторий = корень.appendingPathComponent("repo", isDirectory: true)
guard let утверждённая = try? Data(contentsOf: корень.appendingPathComponent("approved-config")),
      let фактическая = try? Data(contentsOf: репозиторий.appendingPathComponent(".git/config")),
      let атрибуты = try? Data(contentsOf: репозиторий.appendingPathComponent(".gitattributes")) else {
    требовать(false, "данные фикстуры"); exit(1)
}
let профильФикстуры = ПрофильGit(локальнаяКонфигурация: фактическая, утверждённаяКонфигурация: утверждённая,
                                корневыеАтрибуты: атрибуты, служебныеАтрибуты: nil,
                                полныйСоставАтрибутовПодтверждён: false)
требовать(профильФикстуры.проверить() == .отказ, "отказ до Git")
// Чтение настроек — отдельная синтетическая проверка изоляции, не операция, вызывающая фильтр.
let процесс = Process(), вывод = Pipe(), ошибки = Pipe()
процесс.executableURL = URL(fileURLWithPath: CommandLine.arguments[2])
процесс.arguments = ["-C", репозиторий.path, "config", "--get-all", "fixture.marker"]
процесс.environment = исходная
процесс.standardOutput = вывод; процесс.standardError = ошибки
do { try процесс.run() } catch { требовать(false, "запуск синтетического Git") }
let текст = вывод.fileHandleForReading.readDataToEndOfFile()
let ошибка = ошибки.fileHandleForReading.readDataToEndOfFile()
процесс.waitUntilExit()
требовать(процесс.terminationStatus == 0 && ошибка.isEmpty && текст == Data("local-visible\n".utf8), "уровни Git")
требовать(!FileManager.default.fileExists(atPath: корень.appendingPathComponent("filter-executed").path), "маркер фильтра")
print("ПРОЙДЕНО физическая фикстура: global/system изолированы, local видим, фильтр не запускался")
