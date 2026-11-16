import Darwin
import FUMProcessProtocol

// Экспериментальная отдельная версия: не является допуском обёртки или discover.
// Вызывающий обеспечивает sole-reaper, custody дескрипторов и происхождение образов.
func выполнитьВладельцаЦелевойГруппы(_ аргументы: [String]) -> Int32 {
    guard аргументы.count >= 17, аргументы[1] == "фум-испытание-владельца-группы.1",
          let запуск = ИдентификаторЗапуска(аргументы[2]),
          let срок = Int64(аргументы[3]), String(срок) == аргументы[3],
          let статус = Int32(аргументы[4]), статус > 2, String(статус) == аргументы[4],
          let квитанции = Int32(аргументы[11]), квитанции > 2, String(квитанции) == аргументы[11],
          let среда = Int32(аргументы[12]), среда > 2, String(среда) == аргументы[12],
          let маска = UInt32(аргументы[13]), String(маска) == аргументы[13],
          аргументы[14].hasPrefix("/"), аргументы[15] == "--", аргументы[16].hasPrefix("/"),
          getpid() > 1, getpid() == getpgrp(), getsid(0) == getpid(),
          let начало = монотонныеМиллисекундыНаблюдателя(), начало < срок,
          let корень = ОпораЗаимствованногоКаталога(
              аргументы[5], аргументы[6], аргументы[7], аргументы[8], аргументы[9], аргументы[10],
              область: .рабочееДерево, занятыеДескрипторы: [статус, квитанции, среда]),
          Set([статус, квитанции, среда, корень.дескриптор]).count == 4,
          подтвердитьОткрытыйКаталог(корень), let исходнаяСреда = прочитатьОкружение(среда) else { return 125 }
    var меткаКорня = stat(), меткаКвитанций = stat(), меткаСтатуса = stat(), меткаВхода = stat(), действие = sigaction()
    let флагиСтатуса = fcntl(статус, F_GETFL), флагиВхода = fcntl(STDIN_FILENO, F_GETFL)
    guard fstat(корень.дескриптор, &меткаКорня) == 0,
          fstat(квитанции, &меткаКвитанций) == 0,
          меткаКвитанций.st_mode & UInt16(S_IFMT) == UInt16(S_IFDIR),
          меткаКвитанций.st_mode & 0o7777 == 0o700, меткаКвитанций.st_uid == getuid(),
          разнестиИменаКаталогов(аргументы[5], меткаКорня, квитанции, меткаКвитанций),
          fstat(статус, &меткаСтатуса) == 0, меткаСтатуса.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          fstat(STDIN_FILENO, &меткаВхода) == 0, меткаВхода.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          флагиСтатуса >= 0, флагиСтатуса & O_ACCMODE == O_WRONLY,
          fcntl(статус, F_SETFL, флагиСтатуса | O_NONBLOCK) == 0,
          флагиВхода >= 0, флагиВхода & O_ACCMODE == O_RDONLY,
          sigaction(SIGCHLD, nil, &действие) == 0, действие.sa_flags & Int32(SA_SIGINFO | SA_NOCLDWAIT) == 0,
          unsafeBitCast(действие.__sigaction_u.__sa_handler, to: UInt.self) == unsafeBitCast(SIG_DFL, to: UInt.self) else { return 125 }
    guard сохранитьСобытие(квитанции, "intent.DATA", "run=\(запуск.текст) phase=before-spawn\n") else {
        // Частичное намерение не разрешает повтор и не доказывает его отсутствие.
        while true { usleep(100_000) }
    }
    var игнорировать = sigaction()
    игнорировать.__sigaction_u.__sa_handler = SIG_IGN
    guard sigemptyset(&игнорировать.sa_mask) == 0, sigaction(SIGPIPE, &игнорировать, nil) == 0 else {
        if !сохранитьСобытие(квитанции, "unknown.DATA", "run=\(запуск.текст) reason=sigpipe outcome=UNKNOWN\n") {
            while true { usleep(100_000) }
        }
        return 125
    }
    var последняяОтправка: (число: Int, ошибка: Int32) = (0, 0)
    func отправить(_ текст: String) -> Bool {
        let байты = Array(текст.utf8)
        let число = байты.withUnsafeBytes { write(статус, $0.baseAddress, $0.count) }
        последняяОтправка = (число, число < 0 ? errno : 0)
        return число == байты.count
    }
    var предыдущееВремя = начало
    func время() -> Int64? {
        guard let сейчас = монотонныеМиллисекундыНаблюдателя(), сейчас >= предыдущееВремя, сейчас < срок else { return nil }
        предыдущееВремя = сейчас
        return сейчас
    }
    func опроситьСвязь() -> (итог: Int32, события: Int16, ошибка: Int32) {
        var опрос = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN | POLLHUP), revents: 0)
        let итог = poll(&опрос, 1, 0)
        let ошибка = итог < 0 ? errno : 0
        return (итог, опрос.revents, ошибка)
    }
    func связьЦела() -> Bool { опроситьСвязь().итог == 0 }
    // Время относится к наблюдению, а не к моменту выхода ребёнка или обрыва канала.
    func неясностьНаблюдения() -> String? {
        guard let наблюдаемоеВремя = монотонныеМиллисекундыНаблюдателя() else { return "часы-недоступны" }
        guard наблюдаемоеВремя >= предыдущееВремя else { return "часы-назад" }
        предыдущееВремя = наблюдаемоеВремя
        if наблюдаемоеВремя >= срок { return "срок-наблюдение-\(наблюдаемоеВремя)-предел-\(срок)" }
        let связь = опроситьСвязь()
        if связь.итог != 0 || связь.события != 0 {
            return "канал-неясен-наблюдение-\(наблюдаемоеВремя)-опрос-\(связь.итог)-события-\(связь.события)-ошибка-\(связь.ошибка)"
        }
        return nil
    }
    func ждать(_ дескриптор: Int32, _ события: Int16) -> Bool {
        while let сейчас = время() {
            var опрос = pollfd(fd: дескриптор, events: события, revents: 0)
            let итог = poll(&опрос, 1, Int32(min(срок - сейчас, 1000)))
            if итог < 0 && errno == EINTR { continue }
            if итог < 0 || опрос.revents & Int16(POLLERR | POLLNVAL) != 0 { return false }
            if опрос.revents & события != 0 { return время() != nil }
            if опрос.revents & Int16(POLLHUP) != 0 { return false }
        }
        return false
    }
    func отказДоПуска(_ причина: String, очисткаПодтверждена: Bool = true) -> Int32 {
        if !сохранитьСобытие(квитанции, "unknown.DATA", "run=\(запуск.текст) reason=\(причина) outcome=UNKNOWN\n") || !очисткаПодтверждена {
            while true { usleep(100_000) }
        }
        return 125
    }
    guard отправить("READY \(запуск.текст)\n") else { return отказДоПуска("ready-send-\(последняяОтправка.число)-\(последняяОтправка.ошибка)") }
    guard ждать(STDIN_FILENO, Int16(POLLIN)) else { return отказДоПуска("initial-gate") }
    var началоЗапуска: UInt8 = 0
    guard read(STDIN_FILENO, &началоЗапуска, 1) == 1, началоЗапуска == 0x47,
          подтвердитьОткрытыйКаталог(корень), прочитатьОкружение(среда) == исходнаяСреда else { return отказДоПуска("initial-command") }
    var допускЦели = [Int32](repeating: -1, count: 2)
    var управлениеЯкорем = [Int32](repeating: -1, count: 2)
    var готовностьЯкоря = [Int32](repeating: -1, count: 2)
    guard pipe(&допускЦели) == 0, pipe(&управлениеЯкорем) == 0, pipe(&готовностьЯкоря) == 0,
          Set(допускЦели + управлениеЯкорем + готовностьЯкоря + [статус, квитанции, среда, корень.дескриптор]).count == 10,
          (допускЦели + управлениеЯкорем + готовностьЯкоря).allSatisfy({ $0 > 2 }) else {
        var ошибки: [String] = []
        var очисткаПодтверждена = true
        let занятые = Set([статус, квитанции, среда, корень.дескриптор, STDIN_FILENO, STDOUT_FILENO, STDERR_FILENO])
        var обработаны = Set<Int32>()
        for дескриптор in допускЦели + управлениеЯкорем + готовностьЯкоря where дескриптор >= 0 {
            guard !занятые.contains(дескриптор), обработаны.insert(дескриптор).inserted else {
                ошибки.append("collision:\(дескриптор)")
                очисткаПодтверждена = false
                continue
            }
            let итог = close(дескриптор); let код = итог == 0 ? 0 : errno
            if итог != 0 { очисткаПодтверждена = false }
            ошибки.append("\(дескриптор):\(итог):\(код)")
        }
        return отказДоПуска("pipes-\(ошибки.joined(separator: ","))", очисткаПодтверждена: очисткаПодтверждена)
    }
    var цель: pid_t = 0, якорь: pid_t = 0, цельСобрана = false, якорьСобран = false
    var неизвестныйПускЦели = false, неизвестныйПускЯкоря = false
    var потеряСыройКвитанции = false, ошибкаОжиданияЦели = false, ошибкаОжиданияЯкоря = false
    var сыройЦели: Int32?, сыройЯкоря: Int32?
    var допускОткрыт = true, управлениеОткрыто = true
    var чтениеДопускаОткрыто = true, чтениеУправленияОткрыто = true
    var чтениеГотовностиОткрыто = true, записьГотовностиОткрыта = true
    var историяЗакрытий: [String] = [], ошибкаЛюбогоЗакрытия = false
    func закрытьОднажды(_ дескриптор: Int32, _ открыт: inout Bool) -> Int32 {
        guard открыт else { return 0 }
        открыт = false
        let итог = close(дескриптор), код = итог == 0 ? 0 : errno
        историяЗакрытий.append("\(дескриптор):\(итог):\(код)")
        if итог != 0 { ошибкаЛюбогоЗакрытия = true }
        return итог
    }
    func завершитьДоПуска(_ причина: String, уничтожениеПодтверждено: Bool = true) -> Int32 {
        var исходы: [String] = []
        func закрыть(_ имя: String, _ дескриптор: Int32, _ открыт: inout Bool) {
            let итог = закрытьОднажды(дескриптор, &открыт), код = итог == 0 ? 0 : errno
            исходы.append("\(имя):\(итог):\(код)")
        }
        закрыть("target-read", допускЦели[0], &чтениеДопускаОткрыто)
        закрыть("target-write", допускЦели[1], &допускОткрыт)
        закрыть("anchor-read", управлениеЯкорем[0], &чтениеУправленияОткрыто)
        закрыть("anchor-write", управлениеЯкорем[1], &управлениеОткрыто)
        закрыть("ready-read", готовностьЯкоря[0], &чтениеГотовностиОткрыто)
        закрыть("ready-write", готовностьЯкоря[1], &записьГотовностиОткрыта)
        return отказДоПуска("\(причина)-cleanup-\(исходы.joined(separator: ","))",
                            очисткаПодтверждена: уничтожениеПодтверждено && !ошибкаЛюбогоЗакрытия)
    }
    func неизвестно(_ причина: String) -> Never {
        let неизвестностьСохранена = сохранитьСобытие(квитанции, "unknown.DATA", "run=\(запуск.текст) target=\(цель) anchor=\(якорь) reason=\(причина) outcome=UNKNOWN\n")
        let отправлено = неизвестностьСохранена && отправить("UNKNOWN \(запуск.текст) raw=UNKNOWN\n")
        let отправка = неизвестностьСохранена ? последняяОтправка : (число: 0, ошибка: Int32(0))
        var ошибкаЗакрытия = false
        func закрытьДляОтчёта(_ имя: String, _ дескриптор: Int32, _ открыт: inout Bool) -> String {
            let былОткрыт = открыт
            let итог = закрытьОднажды(дескриптор, &открыт)
            let код = итог == 0 ? 0 : errno
            if итог != 0 { ошибкаЗакрытия = true }
            return "\(имя):\(былОткрыт):\(итог):\(код)"
        }
        let исходыЗакрытия = [
            закрытьДляОтчёта("target-read", допускЦели[0], &чтениеДопускаОткрыто),
            закрытьДляОтчёта("target-write", допускЦели[1], &допускОткрыт),
            закрытьДляОтчёта("anchor-read", управлениеЯкорем[0], &чтениеУправленияОткрыто),
            закрытьДляОтчёта("anchor-write", управлениеЯкорем[1], &управлениеОткрыто),
            закрытьДляОтчёта("ready-read", готовностьЯкоря[0], &чтениеГотовностиОткрыто),
            закрытьДляОтчёта("ready-write", готовностьЯкоря[1], &записьГотовностиОткрыта),
        ]
        let очисткаСохранена = сохранитьСобытие(квитанции, "cleanup.DATA", "run=\(запуск.текст) send=\(отправлено) bytes=\(отправка.число) errno=\(отправка.ошибка) history=\(историяЗакрытий.joined(separator: ",")) close=\(исходыЗакрытия.joined(separator: ",")) outcome=UNKNOWN\n")
        while true {
            var сырой: Int32 = 0
            if цель > 1 && !цельСобрана && !ошибкаОжиданияЦели {
                let итог = waitpid(цель, &сырой, WNOHANG)
                if итог == цель {
                    цельСобрана = true; сыройЦели = сырой
                    if !сохранитьСобытие(квитанции, "target-reap.DATA", "run=\(запуск.текст) pid=\(цель) raw=\(сырой) outcome=UNKNOWN\n") { потеряСыройКвитанции = true }
                } else if итог < 0 && errno != EINTR { ошибкаОжиданияЦели = true }
            }
            if якорь > 1 && !якорьСобран && !ошибкаОжиданияЯкоря {
                let итог = waitpid(якорь, &сырой, WNOHANG)
                if итог == якорь {
                    якорьСобран = true; сыройЯкоря = сырой
                    if !сохранитьСобытие(квитанции, "anchor-reap.DATA", "run=\(запуск.текст) pid=\(якорь) raw=\(сырой) outcome=UNKNOWN\n") { потеряСыройКвитанции = true }
                } else if итог < 0 && errno != EINTR { ошибкаОжиданияЯкоря = true }
            }
            if неизвестностьСохранена && отправлено && очисткаСохранена && !ошибкаЗакрытия && !ошибкаЛюбогоЗакрытия &&
                !потеряСыройКвитанции && !неизвестныйПускЦели && !неизвестныйПускЯкоря &&
                !ошибкаОжиданияЦели && !ошибкаОжиданияЯкоря &&
                (!цельСобрана || сыройЦели != nil) && (!якорьСобран || сыройЯкоря != nil) &&
                (цель <= 1 || цельСобрана) && (якорь <= 1 || якорьСобран) { exit(125) }
            usleep(10_000)
        }
    }
    // Каждая ветка после spawn сохраняет процесс у этого владельца до waitpid или HOLD.
    func запустить(_ значения: [String], _ действия: inout posix_spawn_file_actions_t?,
                   _ настройки: inout posix_spawnattr_t?, _ pid: inout pid_t) -> Int32 {
        let указатели = значения.map { strdup($0) } + [nil]
        defer { for указатель in указатели { free(указатель) } }
        guard указатели.dropLast().allSatisfy({ $0 != nil }) else { return ENOMEM }
        var окружение: [UnsafeMutablePointer<CChar>?] = [nil]
        return указатели.withUnsafeBufferPointer { буфер in окружение.withUnsafeMutableBufferPointer { средаБуфер in
            posix_spawn(&pid, значения[0], &действия, &настройки,
                        UnsafeMutablePointer(mutating: буфер.baseAddress), средаБуфер.baseAddress)
        } }
    }
    var действияЦели: posix_spawn_file_actions_t?, настройкиЦели: posix_spawnattr_t?, сигналыПоУмолчанию = sigset_t()
    let созданиеДействийЦели = posix_spawn_file_actions_init(&действияЦели)
    guard созданиеДействийЦели == 0 else { return завершитьДоПуска("target-actions-init-\(созданиеДействийЦели)") }
    let созданиеНастроекЦели = posix_spawnattr_init(&настройкиЦели)
    guard созданиеНастроекЦели == 0 else {
        let уничтожение = posix_spawn_file_actions_destroy(&действияЦели)
        return завершитьДоПуска("target-attrs-init-\(созданиеНастроекЦели)-destroy-\(уничтожение)", уничтожениеПодтверждено: уничтожение == 0)
    }
    guard sigemptyset(&сигналыПоУмолчанию) == 0, sigaddset(&сигналыПоУмолчанию, SIGPIPE) == 0,
          sigaddset(&сигналыПоУмолчанию, SIGXFSZ) == 0,
          posix_spawn_file_actions_addopen(&действияЦели, STDIN_FILENO, "/dev/null", O_RDONLY, 0) == 0,
          posix_spawn_file_actions_addinherit_np(&действияЦели, STDOUT_FILENO) == 0,
          posix_spawn_file_actions_addinherit_np(&действияЦели, STDERR_FILENO) == 0,
          posix_spawn_file_actions_addinherit_np(&действияЦели, корень.дескриптор) == 0,
          posix_spawn_file_actions_addinherit_np(&действияЦели, среда) == 0,
          posix_spawn_file_actions_addinherit_np(&действияЦели, допускЦели[0]) == 0,
          posix_spawnattr_setpgroup(&настройкиЦели, 0) == 0,
          posix_spawnattr_setsigdefault(&настройкиЦели, &сигналыПоУмолчанию) == 0,
          posix_spawnattr_setflags(&настройкиЦели, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGDEF)) == 0 else {
        let первое = posix_spawn_file_actions_destroy(&действияЦели)
        let второе = posix_spawnattr_destroy(&настройкиЦели)
        return завершитьДоПуска("target-setup-destroy-\(первое)-\(второе)", уничтожениеПодтверждено: первое == 0 && второе == 0)
    }
    let параметрыЦели = [аргументы[0], "fum-nosignal-shim.3"] + Array(аргументы[5...10]) +
        [String(допускЦели[0]), String(среда), String(маска), "--"] + Array(аргументы[16...])
    let итогЦели = запустить(параметрыЦели, &действияЦели, &настройкиЦели, &цель)
    let действияЦелиЗакрыты = posix_spawn_file_actions_destroy(&действияЦели)
    let настройкиЦелиЗакрыты = posix_spawnattr_destroy(&настройкиЦели)
    let чтениеЦелиЗакрыто = закрытьОднажды(допускЦели[0], &чтениеДопускаОткрыто)
    let ошибкаЧтенияЦели = чтениеЦелиЗакрыто == 0 ? 0 : errno
    guard итогЦели == 0, цель > 1 else {
        let неподтверждённыйPID = цель; цель = 0; неизвестныйПускЦели = true
        неизвестно("target-spawn-\(итогЦели)-pid-\(неподтверждённыйPID)")
    }
    guard действияЦелиЗакрыты == 0, настройкиЦелиЗакрыты == 0, чтениеЦелиЗакрыто == 0 else {
        неизвестно("target-cleanup-actions-\(действияЦелиЗакрыты)-attrs-\(настройкиЦелиЗакрыты)-close-\(чтениеЦелиЗакрыто)-errno-\(ошибкаЧтенияЦели)")
    }
    guard getpgid(цель) == цель, getsid(цель) == getpid() else { неизвестно("target-identity") }
    var действияЯкоря: posix_spawn_file_actions_t?, настройкиЯкоря: posix_spawnattr_t?, заблокированы = sigset_t()
    let созданиеДействийЯкоря = posix_spawn_file_actions_init(&действияЯкоря)
    guard созданиеДействийЯкоря == 0 else { неизвестно("anchor-actions-init-\(созданиеДействийЯкоря)") }
    let созданиеНастроекЯкоря = posix_spawnattr_init(&настройкиЯкоря)
    guard созданиеНастроекЯкоря == 0 else {
        let уничтожение = posix_spawn_file_actions_destroy(&действияЯкоря)
        неизвестно("anchor-attrs-init-\(созданиеНастроекЯкоря)-destroy-\(уничтожение)")
    }
    func отказатьсяОтНастроекЯкоря(_ причина: String) -> Never {
        let первое = posix_spawn_file_actions_destroy(&действияЯкоря)
        let второе = posix_spawnattr_destroy(&настройкиЯкоря)
        неизвестно("\(причина)-destroy-\(первое)-\(второе)")
    }
    guard sigemptyset(&заблокированы) == 0, sigaddset(&заблокированы, SIGINT) == 0,
          sigaddset(&заблокированы, SIGTERM) == 0,
          posix_spawn_file_actions_adddup2(&действияЯкоря, управлениеЯкорем[0], STDIN_FILENO) == 0,
          posix_spawn_file_actions_addopen(&действияЯкоря, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) == 0,
          posix_spawn_file_actions_addopen(&действияЯкоря, STDERR_FILENO, "/dev/null", O_WRONLY, 0) == 0,
          posix_spawn_file_actions_addinherit_np(&действияЯкоря, готовностьЯкоря[1]) == 0,
          posix_spawnattr_setpgroup(&настройкиЯкоря, цель) == 0,
          posix_spawnattr_setsigmask(&настройкиЯкоря, &заблокированы) == 0,
          posix_spawnattr_setflags(&настройкиЯкоря, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGMASK)) == 0 else { отказатьсяОтНастроекЯкоря("anchor-setup") }
    let флагиГотовности = fcntl(готовностьЯкоря[1], F_GETFL)
    guard флагиГотовности >= 0, fcntl(готовностьЯкоря[1], F_SETFL, флагиГотовности | O_NONBLOCK) == 0 else { отказатьсяОтНастроекЯкоря("ready-flags") }
    let параметрыЯкоря = [аргументы[14], "fum-anchor.2", запуск.текст, String(getpid()),
                         String(готовностьЯкоря[1]), String(цель), String(срок)]
    неизвестныйПускЯкоря = true
    let итогЯкоря = запустить(параметрыЯкоря, &действияЯкоря, &настройкиЯкоря, &якорь)
    let действияЯкоряЗакрыты = posix_spawn_file_actions_destroy(&действияЯкоря)
    let настройкиЯкоряЗакрыты = posix_spawnattr_destroy(&настройкиЯкоря)
    let входЯкоряЗакрыт = закрытьОднажды(управлениеЯкорем[0], &чтениеУправленияОткрыто)
    let ошибкаВходаЯкоря = входЯкоряЗакрыт == 0 ? 0 : errno
    let записьГотовностиЗакрыта = закрытьОднажды(готовностьЯкоря[1], &записьГотовностиОткрыта)
    let ошибкаЗаписиГотовности = записьГотовностиЗакрыта == 0 ? 0 : errno
    guard итогЯкоря == 0, якорь > 1 else {
        let неподтверждённыйPID = якорь; якорь = 0
        неизвестно("anchor-spawn-\(итогЯкоря)-pid-\(неподтверждённыйPID)")
    }
    неизвестныйПускЯкоря = false
    guard действияЯкоряЗакрыты == 0, настройкиЯкоряЗакрыты == 0,
          входЯкоряЗакрыт == 0, записьГотовностиЗакрыта == 0 else {
        неизвестно("anchor-cleanup-actions-\(действияЯкоряЗакрыты)-attrs-\(настройкиЯкоряЗакрыты)-input-\(входЯкоряЗакрыт)-errno-\(ошибкаВходаЯкоря)-ready-\(записьГотовностиЗакрыта)-errno-\(ошибкаЗаписиГотовности)")
    }
    let флагиЧтения = fcntl(готовностьЯкоря[0], F_GETFL)
    guard флагиЧтения >= 0, fcntl(готовностьЯкоря[0], F_SETFL, флагиЧтения | O_NONBLOCK) == 0 else { неизвестно("ready-read-flags") }
    var кадр = [UInt8](repeating: 0, count: 24), смещение = 0
    while смещение < кадр.count {
        guard ждать(готовностьЯкоря[0], Int16(POLLIN)) else { неизвестно("anchor-ready") }
        let число = кадр.withUnsafeMutableBytes { read(готовностьЯкоря[0], $0.baseAddress!.advanced(by: смещение), $0.count - смещение) }
        if число < 0 && errno == EINTR { continue }
        guard число > 0 else { неизвестно("anchor-ready-read") }
        смещение += число
    }
    var лишнийБайт: UInt8 = 0
    while true {
        guard ждать(готовностьЯкоря[0], Int16(POLLIN | POLLHUP)) else { неизвестно("anchor-ready-eof") }
        let число = read(готовностьЯкоря[0], &лишнийБайт, 1)
        if число == 0 { break }
        if число < 0 && (errno == EINTR || errno == EAGAIN) { continue }
        неизвестно("anchor-ready-trailing")
    }
    let закрытиеГотовности = закрытьОднажды(готовностьЯкоря[0], &чтениеГотовностиОткрыто)
    let ошибкаЗакрытияГотовности = закрытиеГотовности == 0 ? 0 : errno
    guard закрытиеГотовности == 0 else { неизвестно("ready-close-\(закрытиеГотовности)-errno-\(ошибкаЗакрытияГотовности)") }
    guard let готовность = try? КадрГотовностиЯкоря.decode(кадр, expectedRunID: запуск.байты),
          готовность.pid == якорь, getpgid(цель) == цель, getpgid(якорь) == цель,
          getsid(цель) == getpid(), getsid(якорь) == getpid(),
          сохранитьСобытие(квитанции, "owner.DATA", "run=\(запуск.текст) target=\(цель) anchor=\(якорь) pgid=\(цель) phase=before-gate\n") else { неизвестно("anchor-bind") }
    var раннийСтатус: Int32 = 0
    let ранняяЦель = waitpid(цель, &раннийСтатус, WNOHANG)
    if ранняяЦель == цель {
        цельСобрана = true; сыройЦели = раннийСтатус
        if !сохранитьСобытие(квитанции, "target-reap.DATA", "run=\(запуск.текст) pid=\(цель) raw=\(раннийСтатус) outcome=UNKNOWN\n") { потеряСыройКвитанции = true }
        неизвестно("target-early-raw-\(раннийСтатус)")
    }
    guard ранняяЦель == 0 else { неизвестно("target-early-wait") }
    let раннийЯкорь = waitpid(якорь, &раннийСтатус, WNOHANG)
    if раннийЯкорь == якорь {
        якорьСобран = true; сыройЯкоря = раннийСтатус
        if !сохранитьСобытие(квитанции, "anchor-reap.DATA", "run=\(запуск.текст) pid=\(якорь) raw=\(раннийСтатус) outcome=UNKNOWN\n") { потеряСыройКвитанции = true }
        неизвестно("anchor-early-raw-\(раннийСтатус)")
    }
    guard раннийЯкорь == 0 else { неизвестно("anchor-early-wait") }
    var сигналДопуска: UInt8 = 0x47
    guard время() != nil, связьЦела(), подтвердитьОткрытыйКаталог(корень),
          прочитатьОкружение(среда) == исходнаяСреда, время() != nil, связьЦела() else { неизвестно("before-target-gate") }
    let числоДопуска = write(допускЦели[1], &сигналДопуска, 1)
    let ошибкаЗаписиДопуска = числоДопуска < 0 ? errno : 0
    let итогЗакрытияДопуска = закрытьОднажды(допускЦели[1], &допускОткрыт)
    let ошибкаЗакрытияДопуска = итогЗакрытияДопуска == 0 ? 0 : errno
    guard числоДопуска == 1, итогЗакрытияДопуска == 0 else { неизвестно("target-gate-write-\(числоДопуска)-errno-\(ошибкаЗаписиДопуска)-close-\(итогЗакрытияДопуска)-errno-\(ошибкаЗакрытияДопуска)") }
    var результатЦели: Int32 = 0
    while true {
        if let причина = неясностьНаблюдения() { неизвестно("цель-\(причина)") }
        let результат = waitpid(цель, &результатЦели, WNOHANG)
        if результат == цель {
            цельСобрана = true; сыройЦели = результатЦели
            guard сохранитьСобытие(квитанции, "target-reap.DATA", "run=\(запуск.текст) pid=\(цель) raw=\(результатЦели) outcome=OBSERVED\n") else { потеряСыройКвитанции = true; неизвестно("target-raw-\(результатЦели)") }
            break
        }
        if результат < 0 && errno != EINTR { неизвестно("target-wait") }
        var проверочныйСтатус: Int32 = 0
        let опросЯкоря = waitpid(якорь, &проверочныйСтатус, WNOHANG)
        if опросЯкоря == якорь {
            якорьСобран = true; сыройЯкоря = проверочныйСтатус
            if !сохранитьСобытие(квитанции, "anchor-reap.DATA", "run=\(запуск.текст) pid=\(якорь) raw=\(проверочныйСтатус) outcome=UNKNOWN\n") { потеряСыройКвитанции = true }
            неизвестно("anchor-early-raw-\(проверочныйСтатус)")
        }
        if опросЯкоря < 0 && errno != EINTR { неизвестно("anchor-wait") }
        usleep(10_000)
    }
    guard время() != nil, связьЦела() else { неизвестно("before-anchor-release") }
    let конецЯкоря = [UInt8(0x58)] + запуск.байты
    let числоКомандыЯкоря = конецЯкоря.withUnsafeBytes { write(управлениеЯкорем[1], $0.baseAddress, $0.count) }
    let ошибкаЗаписиЯкоря = числоКомандыЯкоря < 0 ? errno : 0
    let итогЗакрытияУправления = закрытьОднажды(управлениеЯкорем[1], &управлениеОткрыто)
    let ошибкаЗакрытияУправления = итогЗакрытияУправления == 0 ? 0 : errno
    guard числоКомандыЯкоря == конецЯкоря.count, итогЗакрытияУправления == 0, время() != nil, связьЦела() else { неизвестно("anchor-release-write-\(числоКомандыЯкоря)-errno-\(ошибкаЗаписиЯкоря)-close-\(итогЗакрытияУправления)-errno-\(ошибкаЗакрытияУправления)") }
    var результатЯкоря: Int32 = 0
    while true {
        if let причина = неясностьНаблюдения() { неизвестно("якорь-\(причина)") }
        let результат = waitpid(якорь, &результатЯкоря, WNOHANG)
        if результат == якорь {
            якорьСобран = true; сыройЯкоря = результатЯкоря
            guard сохранитьСобытие(квитанции, "anchor-reap.DATA", "run=\(запуск.текст) pid=\(якорь) raw=\(результатЯкоря) outcome=OBSERVED\n") else { потеряСыройКвитанции = true; неизвестно("anchor-raw-\(результатЯкоря)") }
            break
        }
        if результат < 0 && errno != EINTR { неизвестно("anchor-wait") }
        usleep(10_000)
    }
    guard результатЯкоря == 0, подтвердитьОткрытыйКаталог(корень), прочитатьОкружение(среда) == исходнаяСреда else { неизвестно("postcheck") }
    errno = 0
    guard kill(-цель, 0) == -1, errno == ESRCH else { неизвестно("group") }
    guard время() != nil, связьЦела() else { неизвестно("before-terminal") }
    guard сохранитьСобытие(квитанции, "terminal.DATA", "run=\(запуск.текст) target=\(цель) target_raw=\(результатЦели) anchor=\(якорь) anchor_raw=\(результатЯкоря) group=ESRCH reuse=UNKNOWN outcome=PRE-CLOSE\n") else { неизвестно("terminal-receipt") }
    guard время() != nil, связьЦела() else { неизвестно("after-terminal-receipt") }
    guard отправить("DONE \(запуск.текст) \(результатЦели)\n") else {
        неизвестно("done-send-bytes-\(последняяОтправка.число)-errno-\(последняяОтправка.ошибка)")
    }
    guard время() != nil, связьЦела() else { неизвестно("late-terminal") }
    return 0
}
