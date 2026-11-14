// Проверочная цель сравнивает начальный envp без вывода его содержимого.
private func ключСовпадает(_ запись: UnsafeMutablePointer<CChar>, _ ключ: String) -> Bool {
    var смещение = 0
    for байт in ключ.utf8 {
        if запись[смещение] != CChar(bitPattern: байт) { return false }
        смещение += 1
    }
    return запись[смещение] == 61
}

private func значениеСовпадает(_ запись: UnsafeMutablePointer<CChar>, _ значение: String) -> Bool {
    var смещение = 0
    for байт in значение.utf8 {
        if запись[смещение] != CChar(bitPattern: байт) { return false }
        смещение += 1
    }
    return запись[смещение] == 0
}

private func значениеСовпадаетСАргументом(
    _ запись: UnsafeMutablePointer<CChar>, _ аргумент: UnsafeMutablePointer<CChar>
) -> Bool {
    var смещение = 0
    while смещение < 1024 {
        if запись[смещение] != аргумент[смещение] { return false }
        if запись[смещение] == 0 { return true }
        смещение += 1
    }
    return false
}

private func корректныйИдентификатор(_ аргумент: UnsafeMutablePointer<CChar>) -> Bool {
    for индекс in 0..<36 {
        let байт = Int(аргумент[индекс])
        if байт == 0 { return false }
        if [8, 13, 18, 23].contains(индекс) {
            if байт != 45 { return false }
        } else if !(48...57).contains(байт) && !(97...102).contains(байт) {
            return false
        }
    }
    return аргумент[36] == 0
}

@_cdecl("main")
public func проверитьНачальнуюСреду(
    _ количество: Int32,
    _ аргументы: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
    _ среда: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard (количество == 2 || количество == 3), let аргументы, let идентификатор = аргументы[1],
          корректныйИдентификатор(идентификатор), let среда else { return 40 }
    var ключи = ["PATH", "LC_ALL", "GIT_OPTIONAL_LOCKS", "GIT_NO_LAZY_FETCH",
                 "GIT_NO_REPLACE_OBJECTS", "GIT_CONFIG_NOSYSTEM", "GIT_CONFIG_GLOBAL",
                 "GIT_ATTR_NOSYSTEM", "FUM_CHECK_RUN_ID"]
    let опорныйПуть = количество == 3 ? аргументы[2] : nil
    if количество == 3 {
        guard опорныйПуть != nil else { return 40 }
        ключи.append("TMPDIR")
    }
    let значения = ["/bin:/usr/bin", "C", "0", "1", "1", "1", "/dev/null", "1"]
    var проверено = Array(repeating: false, count: ключи.count)
    var индекс = 0
    while let запись = среда[индекс] {
        var совпадение: Int?
        for номер in ключи.indices {
            if ключСовпадает(запись, ключи[номер]) { совпадение = номер; break }
        }
        guard let совпадение, !проверено[совпадение] else { return 30 }
        проверено[совпадение] = true
        let значение = запись.advanced(by: ключи[совпадение].utf8.count + 1)
        let верно: Bool
        if совпадение == 8 {
            верно = значениеСовпадаетСАргументом(значение, идентификатор)
        } else if совпадение == 9, let опорныйПуть {
            верно = значениеСовпадаетСАргументом(значение, опорныйПуть)
        } else {
            верно = значениеСовпадает(значение, значения[совпадение])
        }
        guard верно else { return совпадение == 8 ? 33 : 32 }
        индекс += 1
        if индекс > ключи.count { return 30 }
    }
    return проверено.contains(false) ? 31 : 0
}
