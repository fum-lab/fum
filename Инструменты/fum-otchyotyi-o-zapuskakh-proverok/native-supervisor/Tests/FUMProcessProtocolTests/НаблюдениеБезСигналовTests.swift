#if canImport(Darwin)
import Darwin
import Testing
@testable import FUMProcessProtocol

private func запуститьДляНаблюдения(_ путь: String, _ аргументы: [String], ввод: Int32) -> pid_t? {
    var действия: posix_spawn_file_actions_t?, настройки: posix_spawnattr_t?
    guard posix_spawn_file_actions_init(&действия) == 0 else { return nil }
    defer { _ = posix_spawn_file_actions_destroy(&действия) }
    guard posix_spawnattr_init(&настройки) == 0 else { return nil }
    defer { _ = posix_spawnattr_destroy(&настройки) }
    guard posix_spawn_file_actions_adddup2(&действия, ввод, STDIN_FILENO) == 0,
          posix_spawn_file_actions_addopen(&действия, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) == 0,
          posix_spawn_file_actions_addopen(&действия, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0,
          posix_spawnattr_setflags(&настройки, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else { return nil }
    let argv = ([путь] + аргументы).map { strdup($0) } + [nil]
    defer { for часть in argv { free(часть) } }
    var env: [UnsafeMutablePointer<CChar>?] = [nil]
    var pid: pid_t = 0
    let код = argv.withUnsafeBufferPointer { a in env.withUnsafeMutableBufferPointer { e in
        posix_spawn(&pid, путь, &действия, &настройки, UnsafeMutablePointer(mutating: a.baseAddress), e.baseAddress)
    } }
    return код == 0 && pid > 1 ? pid : nil
}

private func дождатьсяОпроса(_ владелец: НаблюдениеДочернегоПроцесса) -> ИтогОпросаДочернегоПроцесса {
    for _ in 0..<500 {
        let итог = владелец.опросить()
        if итог != .нетРезультата { return итог }
        usleep(10_000)
    }
    return .нетРезультата
}

@Test func непосредственныйChildСобираетсяБезСигнала() throws {
    var канал = [Int32](repeating: -1, count: 2)
    #expect(pipe(&канал) == 0)
    guard канал.allSatisfy({ $0 > 2 }) else { return }
    let pid = try #require(запуститьДляНаблюдения("/bin/cat", [], ввод: канал[0]))
    #expect(close(канал[0]) == 0)
    let владелец = try #require(НаблюдениеДочернегоПроцесса(pid: pid))
    #expect(владелец.опросить() == .нетРезультата)
    #expect(close(канал[1]) == 0)
    let итог = дождатьсяОпроса(владелец)
    #expect(итог == .собран(pid: pid, сыройСтатус: 0))
    #expect(владелец.опросить() == итог)
    let пустой = open("/dev/null", O_RDONLY | O_CLOEXEC)
    #expect(пустой > 2)
    guard пустой > 2 else { return }
    defer { _ = close(пустой) }
    let ошибкаPID = try #require(запуститьДляНаблюдения("/bin/sh", ["-c", "exit 7"], ввод: пустой))
    let ошибкаВладелец = try #require(НаблюдениеДочернегоПроцесса(pid: ошибкаPID))
    #expect(дождатьсяОпроса(ошибкаВладелец) == .собран(pid: ошибкаPID, сыройСтатус: 7 << 8))
    let повторныйВладелец = try #require(НаблюдениеДочернегоПроцесса(pid: ошибкаPID))
    #expect(повторныйВладелец.опросить() == .неизвестно(errno: ECHILD))
    #expect(повторныйВладелец.опросить() == .неизвестно(errno: ECHILD))
    #expect(НаблюдениеДочернегоПроцесса(pid: getpid()) == nil)
}

@Test func истёкшийСрокНеПревращаетДоборВУспех() throws {
    var канал = [Int32](repeating: -1, count: 2)
    #expect(pipe(&канал) == 0)
    guard канал.allSatisfy({ $0 > 2 }) else { return }
    let pid = try #require(запуститьДляНаблюдения("/bin/cat", [], ввод: канал[0]))
    #expect(close(канал[0]) == 0)
    let владелец = try #require(ОграниченноеНаблюдениеБезСигналов(pid: pid, начало: 100, край: 200))
    #expect(владелец.опросить(часы: { 150 }) == .нетРезультата)
    #expect(владелец.опросить(часы: { 200 }) == .неизвестно(.срок))
    #expect(владелец.добратьПослеНеизвестного() == .нетРезультата)
    #expect(close(канал[1]) == 0)
    var добор: ИтогОпросаДочернегоПроцесса?
    for _ in 0..<500 {
        добор = владелец.добратьПослеНеизвестного()
        if добор != .нетРезультата { break }
        usleep(10_000)
    }
    #expect(добор == .собран(pid: pid, сыройСтатус: 0))
    #expect(владелец.опросить(часы: { 201 }) == .неизвестно(.срок))
}

@Test func срокИОбратныеЧасыПослеОпросаДаютНеизвестно() throws {
    let пустой = open("/dev/null", O_RDONLY | O_CLOEXEC)
    #expect(пустой > 2)
    guard пустой > 2 else { return }
    defer { _ = close(пустой) }
    for (второеВремя, причина) in [(Int64(200), ПричинаНеизвестногоНаблюдения.срок), (149, .часы)] {
        let pid = try #require(запуститьДляНаблюдения("/bin/sh", ["-c", "exit 7"], ввод: пустой))
        let владелец = try #require(ОграниченноеНаблюдениеБезСигналов(pid: pid, начало: 100, край: 200))
        var чтения = 0
        let итог = владелец.опросить {
            чтения += 1
            return чтения == 1 ? 150 : второеВремя
        }
        #expect(итог == .неизвестно(причина))
        var добор: ИтогОпросаДочернегоПроцесса?
        for _ in 0..<500 {
            добор = владелец.добратьПослеНеизвестного()
            if добор != .нетРезультата { break }
            usleep(10_000)
        }
        #expect(добор == .собран(pid: pid, сыройСтатус: 7 << 8))
        #expect(владелец.опросить(часы: { 151 }) == .неизвестно(причина))
    }
    #expect(монотонныеМиллисекундыНаблюдателя() != nil)
}
#endif
