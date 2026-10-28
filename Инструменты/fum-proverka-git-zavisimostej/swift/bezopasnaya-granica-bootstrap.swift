import Darwin
import CryptoKit
import Foundation

package enum ПроверкаПриватногоУзла {
    package static func файл(
        _ сведения: stat,
        ожидаемыйUID: uid_t = geteuid()
    ) throws {
        guard (сведения.st_mode & S_IFMT) == S_IFREG else {
            throw ОтказBootstrapЗависимости.отказ("Ожидался приватный обычный файл")
        }
        guard сведения.st_uid == ожидаемыйUID else {
            throw ОтказBootstrapЗависимости.отказ("Владелец приватного файла не совпадает с euid")
        }
        guard (сведения.st_mode & mode_t(0o7777)) == mode_t(0o600) else {
            throw ОтказBootstrapЗависимости.отказ("Приватный файл должен иметь mode 0600")
        }
        guard сведения.st_nlink == 1 else {
            throw ОтказBootstrapЗависимости.отказ("Hardlink приватного файла запрещён")
        }
    }

    package static func каталог(
        _ сведения: stat,
        ожидаемыйUID: uid_t = geteuid()
    ) throws {
        guard (сведения.st_mode & S_IFMT) == S_IFDIR else {
            throw ОтказBootstrapЗависимости.отказ("Ожидался приватный каталог")
        }
        guard сведения.st_uid == ожидаемыйUID else {
            throw ОтказBootstrapЗависимости.отказ("Владелец приватного каталога не совпадает с euid")
        }
        guard (сведения.st_mode & mode_t(0o7777)) == mode_t(0o700) else {
            throw ОтказBootstrapЗависимости.отказ("Приватный каталог должен иметь mode 0700")
        }
    }
}

package final class ПриватнаяГраницаBootstrap {
    package let gitDir: URL
    package let каталог: URL
    private let gitDirFD: Int32
    private let каталогFD: Int32
    private let устройствоGitDir: dev_t
    private let inodeGitDir: ino_t
    private let устройство: dev_t
    private let inode: ino_t

    package var файловыйДескрипторКаталога: Int32 { каталогFD }
    package var устройствоФайловойСистемы: dev_t { устройство }

    package init(gitDir: String, создать: Bool) throws {
        self.gitDir = URL(fileURLWithPath: gitDir, isDirectory: true)
        self.каталог = self.gitDir.appendingPathComponent(
            "dependency-bootstrap", isDirectory: true)
        let локальныйGitDirFD = open(
            gitDir, O_RDONLY | O_DIRECTORY | O_NOFOLLOW_ANY | O_CLOEXEC)
        guard локальныйGitDirFD >= 0 else {
            throw ОтказBootstrapЗависимости.отказ("Физический gitDir недоступен без symlink")
        }

        var создан = false
        if создать {
            let код = "dependency-bootstrap".withCString {
                mkdirat(локальныйGitDirFD, $0, mode_t(0o700))
            }
            if код == 0 {
                создан = true
            } else {
                let причина = errno
                guard причина == EEXIST else {
                    close(локальныйGitDirFD)
                    throw ОтказBootstrapЗависимости.отказ(
                        "Не удалось создать приватный каталог bootstrap: errno=\(причина)")
                }
            }
        }

        let локальныйКаталогFD = "dependency-bootstrap".withCString {
            openat(
                локальныйGitDirFD, $0,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard локальныйКаталогFD >= 0 else {
            let причина = errno
            close(локальныйGitDirFD)
            throw ОтказBootstrapЗависимости.отказ(
                "Каталог bootstrap отсутствует или перенаправлен: errno=\(причина)")
        }
        if создан {
            guard fchmod(локальныйКаталогFD, mode_t(0o700)) == 0 else {
                let причина = errno
                close(локальныйКаталогFD)
                close(локальныйGitDirFD)
                throw ОтказBootstrapЗависимости.отказ(
                    "Не удалось закрепить mode 0700 каталога bootstrap: errno=\(причина)")
            }
        }
        var сведенияGitDir = stat()
        guard fstat(локальныйGitDirFD, &сведенияGitDir) == 0,
              (сведенияGitDir.st_mode & S_IFMT) == S_IFDIR else {
            close(локальныйКаталогFD)
            close(локальныйGitDirFD)
            throw ОтказBootstrapЗависимости.отказ("Не удалось закрепить физический gitDir")
        }
        var сведения = stat()
        guard fstat(локальныйКаталогFD, &сведения) == 0 else {
            close(локальныйКаталогFD)
            close(локальныйGitDirFD)
            throw ОтказBootstrapЗависимости.отказ("Не удалось прочитать каталог bootstrap")
        }
        do {
            try ПроверкаПриватногоУзла.каталог(сведения)
        } catch {
            close(локальныйКаталогFD)
            close(локальныйGitDirFD)
            throw error
        }
        if создан {
            guard fsync(локальныйКаталогFD) == 0, fsync(локальныйGitDirFD) == 0 else {
                let причина = errno
                close(локальныйКаталогFD)
                close(локальныйGitDirFD)
                throw ОтказBootstrapЗависимости.отказ(
                    "Не удалось синхронизировать новый каталог bootstrap и gitDir: errno=\(причина)")
            }
        }
        gitDirFD = локальныйGitDirFD
        каталогFD = локальныйКаталогFD
        устройствоGitDir = сведенияGitDir.st_dev
        inodeGitDir = сведенияGitDir.st_ino
        устройство = сведения.st_dev
        inode = сведения.st_ino
    }

    deinit {
        close(каталогFD)
        close(gitDirFD)
    }

    package func имяФайла(_ путь: URL) throws -> String {
        guard !путь.pathComponents.contains(".."),
              Data(путь.deletingLastPathComponent().path.utf8) == Data(каталог.path.utf8) else {
            throw ОтказBootstrapЗависимости.отказ(
                "План и outcome должны быть непосредственными детьми приватного каталога bootstrap")
        }
        let имя = путь.lastPathComponent
        guard безопасныйКомпонент(имя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасное имя plan/outcome")
        }
        return имя
    }

    package func дочернийКаталог(
        _ имя: String,
        укрепитьСозданный: Bool
    ) throws -> Int32 {
        guard безопасныйКомпонент(имя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасное имя дочернего каталога")
        }
        try проверитьСтабильность()
        let descriptor = имя.withCString {
            openat(каталогFD, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw ОтказBootstrapЗависимости.отказ("Дочерний каталог отсутствует или перенаправлен")
        }
        if укрепитьСозданный, fchmod(descriptor, mode_t(0o700)) != 0 {
            let причина = errno
            close(descriptor)
            throw ОтказBootstrapЗависимости.отказ(
                "Не удалось закрепить mode дочернего каталога: errno=\(причина)")
        }
        var сведения = stat()
        guard fstat(descriptor, &сведения) == 0 else {
            close(descriptor)
            throw ОтказBootstrapЗависимости.отказ("Не удалось прочитать дочерний каталог")
        }
        do {
            try ПроверкаПриватногоУзла.каталог(сведения)
        } catch {
            close(descriptor)
            throw error
        }
        return descriptor
    }

    package func ребёнокОтсутствует(_ имя: String) throws -> Bool {
        guard безопасныйКомпонент(имя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасное имя дочернего пути")
        }
        try проверитьСтабильность()
        var сведения = stat()
        let код = имя.withCString {
            fstatat(каталогFD, $0, &сведения, AT_SYMLINK_NOFOLLOW)
        }
        if код == 0 { return false }
        let причина = errno
        guard причина == ENOENT else {
            throw ОтказBootstrapЗависимости.отказ(
                "Не удалось проверить отсутствие дочернего пути: errno=\(причина)")
        }
        return true
    }

    package func проверитьРебёнка(_ имя: String, совпадаетС descriptor: Int32) throws {
        guard безопасныйКомпонент(имя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасное имя дочернего пути")
        }
        try проверитьСтабильность()
        var ожидаемые = stat()
        var фактические = stat()
        guard fstat(descriptor, &ожидаемые) == 0,
              имя.withCString({
                  fstatat(каталогFD, $0, &фактические, AT_SYMLINK_NOFOLLOW)
              }) == 0,
              (фактические.st_mode & S_IFMT) == S_IFDIR,
              фактические.st_dev == ожидаемые.st_dev,
              фактические.st_ino == ожидаемые.st_ino else {
            throw ОтказBootstrapЗависимости.отказ(
                "Дочерний каталог bootstrap не совпадает с удержанным FD")
        }
        try ПроверкаПриватногоУзла.каталог(фактические)
    }

    package func записатьЭксклюзивно(_ данные: Data, имя: String) throws {
        guard безопасныйКомпонент(имя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасное имя квитанции")
        }
        try проверитьСтабильность()
        let descriptor = имя.withCString {
            openat(
                каталогFD, $0,
                O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
                mode_t(0o600))
        }
        guard descriptor >= 0 else {
            throw ОтказBootstrapЗависимости.отказ(
                "Intent/outcome уже существует или небезопасен")
        }
        do {
            guard fchmod(descriptor, mode_t(0o600)) == 0 else {
                throw ОтказBootstrapЗависимости.отказ("Не удалось закрепить mode 0600 квитанции")
            }
            var сведения = stat()
            guard fstat(descriptor, &сведения) == 0 else {
                throw ОтказBootstrapЗависимости.отказ("Не удалось прочитать новую квитанцию")
            }
            try ПроверкаПриватногоУзла.файл(сведения)
            try записать(данные, descriptor: descriptor)
            guard fsync(descriptor) == 0 else {
                throw ОтказBootstrapЗависимости.отказ("fsync квитанции отказал")
            }
        } catch {
            close(descriptor)
            throw error
        }
        guard close(descriptor) == 0 else {
            throw ОтказBootstrapЗависимости.отказ("close квитанции отказал")
        }
        try синхронизироватьКаталог()
    }

    package func прочитатьПриватныйФайл(_ имя: String) throws -> Data {
        guard безопасныйКомпонент(имя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасное имя квитанции")
        }
        try проверитьСтабильность()
        let descriptor = имя.withCString {
            openat(каталогFD, $0, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw ОтказBootstrapЗависимости.отказ("Приватная квитанция недоступна")
        }
        var до = stat()
        guard fstat(descriptor, &до) == 0 else {
            close(descriptor)
            throw ОтказBootstrapЗависимости.отказ("Не удалось прочитать сведения квитанции")
        }
        let результат: Data
        do {
            try ПроверкаПриватногоУзла.файл(до)
            let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
            let данные = try handle.readToEnd() ?? Data()
            var после = stat()
            guard fstat(descriptor, &после) == 0 else {
                throw ОтказBootstrapЗависимости.отказ("Не удалось повторно прочитать квитанцию")
            }
            try ПроверкаПриватногоУзла.файл(после)
            guard до.st_dev == после.st_dev, до.st_ino == после.st_ino,
                  до.st_size == после.st_size else {
                throw ОтказBootstrapЗависимости.отказ("Квитанция изменилась во время readback")
            }
            результат = данные
        } catch {
            close(descriptor)
            throw error
        }
        guard close(descriptor) == 0 else {
            throw ОтказBootstrapЗависимости.отказ("close readback отказал")
        }
        return результат
    }

    package func заменитьАтомарно(_ данные: Data, имя: String) throws {
        _ = try прочитатьПриватныйФайл(имя)
        let временноеИмя = ".\(имя).\(UUID().uuidString).tmp"
        try записатьЭксклюзивно(данные, имя: временноеИмя)
        try проверитьСтабильность()
        let код = временноеИмя.withCString { временный in
            имя.withCString { итоговый in
                renameat(каталогFD, временный, каталогFD, итоговый)
            }
        }
        guard код == 0 else {
            throw ОтказBootstrapЗависимости.отказ("Атомарная замена outcome отказала")
        }
        try синхронизироватьКаталог()
    }

    package func синхронизироватьКаталог() throws {
        try проверитьСтабильность()
        guard fsync(каталогFD) == 0 else {
            throw ОтказBootstrapЗависимости.отказ("fsync каталога bootstrap отказал")
        }
    }

    package func синхронизироватьGitDir() throws {
        try проверитьСтабильность()
        guard fsync(gitDirFD) == 0 else {
            throw ОтказBootstrapЗависимости.отказ("fsync gitDir отказал")
        }
    }

    package func проверитьСтабильность() throws {
        var текущийGitDir = stat()
        let текущийGitDirFD = open(
            gitDir.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW_ANY | O_CLOEXEC)
        guard текущийGitDirFD >= 0,
              fstat(текущийGitDirFD, &текущийGitDir) == 0,
              (текущийGitDir.st_mode & S_IFMT) == S_IFDIR,
              текущийGitDir.st_dev == устройствоGitDir,
              текущийGitDir.st_ino == inodeGitDir else {
            if текущийGitDirFD >= 0 { close(текущийGitDirFD) }
            throw ОтказBootstrapЗависимости.отказ("Физический gitDir заменён или перенаправлен")
        }
        close(текущийGitDirFD)
        var сведения = stat()
        let код = "dependency-bootstrap".withCString {
            fstatat(gitDirFD, $0, &сведения, AT_SYMLINK_NOFOLLOW)
        }
        guard код == 0,
              (сведения.st_mode & S_IFMT) == S_IFDIR,
              сведения.st_dev == устройство,
              сведения.st_ino == inode else {
            throw ОтказBootstrapЗависимости.отказ("Каталог bootstrap заменён или перенаправлен")
        }
        try ПроверкаПриватногоУзла.каталог(сведения)
    }

    private func безопасныйКомпонент(_ имя: String) -> Bool {
        !имя.isEmpty && имя != "." && имя != ".." && !имя.contains("/") && !имя.contains("\\")
    }

    private func записать(_ данные: Data, descriptor: Int32) throws {
        try данные.withUnsafeBytes { raw in
            guard var адрес = raw.baseAddress else { return }
            var остаток = raw.count
            while остаток > 0 {
                let число = Darwin.write(descriptor, адрес, остаток)
                if число < 0 && errno == EINTR { continue }
                guard число > 0 else {
                    throw ОтказBootstrapЗависимости.отказ("Запись квитанции отказала")
                }
                адрес = адрес.advanced(by: число)
                остаток -= число
            }
        }
    }
}

package final class УдержанныйКаталогЗависимостей {
    private let корень: URL
    private let имяРодителя: String
    private let кореньFD: Int32
    package let файловыйДескриптор: Int32
    private let устройствоКорня: dev_t
    private let inodeКорня: ino_t
    private let устройство: dev_t
    private let inode: ino_t

    package init(корень: URL, имяРодителя: String) throws {
        guard Self.безопасныйКомпонент(имяРодителя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасный родитель зависимости")
        }
        self.корень = корень
        self.имяРодителя = имяРодителя
        let локальныйКореньFD = open(
            корень.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW_ANY | O_CLOEXEC)
        guard локальныйКореньFD >= 0 else {
            throw ОтказBootstrapЗависимости.отказ("Физический checkout недоступен без symlink")
        }
        let локальныйFD = имяРодителя.withCString {
            openat(
                локальныйКореньFD, $0,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard локальныйFD >= 0 else {
            close(локальныйКореньFD)
            throw ОтказBootstrapЗависимости.отказ(
                "Родитель зависимости отсутствует или перенаправлен")
        }
        var сведенияКорня = stat()
        var сведения = stat()
        guard fstat(локальныйКореньFD, &сведенияКорня) == 0,
              fstat(локальныйFD, &сведения) == 0,
              (сведенияКорня.st_mode & S_IFMT) == S_IFDIR,
              (сведения.st_mode & S_IFMT) == S_IFDIR,
              сведения.st_uid == geteuid(),
              (сведения.st_mode & mode_t(0o022)) == 0 else {
            close(локальныйFD)
            close(локальныйКореньFD)
            throw ОтказBootstrapЗависимости.отказ(
                "Родитель зависимости не является защищённым каталогом владельца")
        }
        кореньFD = локальныйКореньFD
        файловыйДескриптор = локальныйFD
        устройствоКорня = сведенияКорня.st_dev
        inodeКорня = сведенияКорня.st_ino
        устройство = сведения.st_dev
        inode = сведения.st_ino
    }

    deinit {
        close(файловыйДескриптор)
        close(кореньFD)
    }

    package var устройствоФайловойСистемы: dev_t { устройство }

    package func проверитьСтабильность() throws {
        var текущийКорень = stat()
        let текущийКореньFD = open(
            корень.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW_ANY | O_CLOEXEC)
        guard текущийКореньFD >= 0,
              fstat(текущийКореньFD, &текущийКорень) == 0,
              (текущийКорень.st_mode & S_IFMT) == S_IFDIR,
              текущийКорень.st_dev == устройствоКорня,
              текущийКорень.st_ino == inodeКорня else {
            if текущийКореньFD >= 0 { close(текущийКореньFD) }
            throw ОтказBootstrapЗависимости.отказ("Физический checkout заменён или перенаправлен")
        }
        close(текущийКореньFD)
        var сведения = stat()
        let код = имяРодителя.withCString {
            fstatat(кореньFD, $0, &сведения, AT_SYMLINK_NOFOLLOW)
        }
        guard код == 0,
              (сведения.st_mode & S_IFMT) == S_IFDIR,
              сведения.st_dev == устройство,
              сведения.st_ino == inode,
              сведения.st_uid == geteuid(),
              (сведения.st_mode & mode_t(0o022)) == 0 else {
            throw ОтказBootstrapЗависимости.отказ(
                "Родитель зависимости заменён или перенаправлен")
        }
    }

    package func потребоватьОтсутствующегоИлиПустогоРебёнка(_ имя: String) throws {
        guard Self.безопасныйКомпонент(имя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасное имя зависимости")
        }
        try проверитьСтабильность()
        var сведения = stat()
        let код = имя.withCString {
            fstatat(файловыйДескриптор, $0, &сведения, AT_SYMLINK_NOFOLLOW)
        }
        if код != 0 {
            guard errno == ENOENT else {
                throw ОтказBootstrapЗависимости.отказ(
                    "Не удалось проверить назначение зависимости: errno=\(errno)")
            }
            return
        }
        guard (сведения.st_mode & S_IFMT) == S_IFDIR else {
            throw ОтказBootstrapЗависимости.отказ(
                "Назначение зависимости существует и не является каталогом")
        }
        let descriptor = имя.withCString {
            openat(
                файловыйДескриптор, $0,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw ОтказBootstrapЗависимости.отказ("Пустое назначение зависимости заменено")
        }
        defer { close(descriptor) }
        guard try Self.каталогПуст(descriptor) else {
            throw ОтказBootstrapЗависимости.отказ("Назначение зависимости перестало быть пустым")
        }
    }

    package func открытьРебёнка(_ имя: String) throws -> Int32 {
        guard Self.безопасныйКомпонент(имя) else {
            throw ОтказBootstrapЗависимости.отказ("Небезопасное имя зависимости")
        }
        try проверитьСтабильность()
        let descriptor = имя.withCString {
            openat(
                файловыйДескриптор, $0,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw ОтказBootstrapЗависимости.отказ("Зависимость отсутствует или перенаправлена")
        }
        var сведения = stat()
        guard fstat(descriptor, &сведения) == 0,
              сведения.st_uid == geteuid(),
              (сведения.st_mode & S_IFMT) == S_IFDIR,
              (сведения.st_mode & mode_t(0o022)) == 0 else {
            close(descriptor)
            throw ОтказBootstrapЗависимости.отказ(
                "Зависимость не является защищённым каталогом владельца")
        }
        return descriptor
    }

    package func удалитьПустогоРебёнкаЕслиЕсть(_ имя: String) throws {
        try потребоватьОтсутствующегоИлиПустогоРебёнка(имя)
        var сведения = stat()
        let найден = имя.withCString {
            fstatat(файловыйДескриптор, $0, &сведения, AT_SYMLINK_NOFOLLOW)
        } == 0
        if найден {
            let код = имя.withCString {
                unlinkat(файловыйДескриптор, $0, AT_REMOVEDIR)
            }
            guard код == 0 else {
                throw ОтказBootstrapЗависимости.отказ(
                    "Не удалось удалить точный пустой каталог назначения: errno=\(errno)")
            }
            guard fsync(файловыйДескриптор) == 0 else {
                throw ОтказBootstrapЗависимости.отказ(
                    "Не удалось синхронизировать удаление пустого назначения")
            }
        }
    }

    package func проверитьРебёнка(_ имя: String, совпадаетС descriptor: Int32) throws {
        try проверитьСтабильность()
        var ожидаемые = stat()
        var фактические = stat()
        guard fstat(descriptor, &ожидаемые) == 0,
              имя.withCString({
                  fstatat(файловыйДескриптор, $0, &фактические, AT_SYMLINK_NOFOLLOW)
              }) == 0,
              (фактические.st_mode & S_IFMT) == S_IFDIR,
              фактические.st_dev == ожидаемые.st_dev,
              фактические.st_ino == ожидаемые.st_ino else {
            throw ОтказBootstrapЗависимости.отказ(
                "Финальное назначение не совпадает с удержанным worktree")
        }
    }

    package func синхронизировать() throws {
        guard fsync(файловыйДескриптор) == 0 else {
            throw ОтказBootstrapЗависимости.отказ(
                "fsync родителя зависимости отказал")
        }
    }

    private static func каталогПуст(_ descriptor: Int32) throws -> Bool {
        let копия = fcntl(descriptor, F_DUPFD_CLOEXEC, 0)
        guard копия >= 0, let каталог = fdopendir(копия) else {
            if копия >= 0 { close(копия) }
            throw ОтказBootstrapЗависимости.отказ("Не удалось перечислить каталог назначения")
        }
        defer { closedir(каталог) }
        while true {
            errno = 0
            guard let entry = readdir(каталог) else {
                guard errno == 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "Перечисление каталога назначения отказало: errno=\(errno)")
                }
                return true
            }
            var запись = entry.pointee
            let имя = withUnsafePointer(to: &запись.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXNAMLEN) + 1) {
                    String(cString: $0)
                }
            }
            if имя != "." && имя != ".." { return false }
        }
    }

    private static func безопасныйКомпонент(_ имя: String) -> Bool {
        !имя.isEmpty && имя != "." && имя != ".." && !имя.contains("/") && !имя.contains("\\")
    }
}

package enum ДолговечностьBootstrap {
    package static func синхронизироватьМатериализацию(
        adminFD: Int32,
        destinationFD: Int32,
        родительЗависимости: УдержанныйКаталогЗависимостей,
        граница: ПриватнаяГраницаBootstrap,
        послеСинхронизации: () throws -> Void = {}
    ) throws -> String {
        let доСинхронизации = try хэшМатериализации(
            adminFD: adminFD, destinationFD: destinationFD)
        try проверитьДерево(
            adminFD, разрешитьSymlink: false, синхронизировать: true)
        try проверитьДерево(
            destinationFD, разрешитьSymlink: true, синхронизировать: true)
        try родительЗависимости.синхронизировать()
        try граница.синхронизироватьКаталог()
        try граница.синхронизироватьGitDir()
        try послеСинхронизации()
        let послеСинхронизации = try хэшМатериализации(
            adminFD: adminFD, destinationFD: destinationFD)
        guard доСинхронизации == послеСинхронизации else {
            throw ОтказBootstrapЗависимости.отказ(
                "Материализация изменилась между pre-digest и durable post-digest")
        }
        return послеСинхронизации
    }

    package static func проверитьМатериализациюБезЗаписи(
        adminFD: Int32,
        destinationFD: Int32
    ) throws -> String {
        try проверитьДерево(
            adminFD, разрешитьSymlink: false, синхронизировать: false)
        try проверитьДерево(
            destinationFD, разрешитьSymlink: true, синхронизировать: false)
        return try хэшМатериализации(adminFD: adminFD, destinationFD: destinationFD)
    }

    private static func проверитьДерево(
        _ descriptor: Int32,
        разрешитьSymlink: Bool,
        синхронизировать: Bool
    ) throws {
        var до = stat()
        guard fstat(descriptor, &до) == 0,
              (до.st_mode & S_IFMT) == S_IFDIR else {
            throw ОтказBootstrapЗависимости.отказ("Корень materialization не является каталогом")
        }
        try потребоватьБезопасныеМетаданные(до, разрешитьSymlink: разрешитьSymlink)
        try проверитьКаталогРекурсивно(
            descriptor,
            разрешитьSymlink: разрешитьSymlink,
            синхронизировать: синхронизировать)
        try потребоватьТотЖеУзел(
            descriptor, что: до, разрешитьSymlink: разрешитьSymlink)
    }

    private static func проверитьКаталогРекурсивно(
        _ descriptor: Int32,
        разрешитьSymlink: Bool,
        синхронизировать: Bool
    ) throws {
        let копия = fcntl(descriptor, F_DUPFD_CLOEXEC, 0)
        guard копия >= 0, let поток = fdopendir(копия) else {
            if копия >= 0 { close(копия) }
            throw ОтказBootstrapЗависимости.отказ("Не удалось перечислить materialization")
        }
        defer { closedir(поток) }
        while true {
            errno = 0
            guard let entry = readdir(поток) else {
                guard errno == 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "Перечисление materialization отказало: errno=\(errno)")
                }
                break
            }
            var запись = entry.pointee
            let имя = withUnsafePointer(to: &запись.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXNAMLEN) + 1) {
                    String(cString: $0)
                }
            }
            if имя == "." || имя == ".." { continue }
            guard имя != ".", имя != "..", !имя.contains("/") else {
                throw ОтказBootstrapЗависимости.отказ("Небезопасное имя materialization")
            }
            var до = stat()
            guard имя.withCString({
                fstatat(descriptor, $0, &до, AT_SYMLINK_NOFOLLOW)
            }) == 0 else {
                throw ОтказBootstrapЗависимости.отказ("Компонент materialization исчез")
            }
            try потребоватьБезопасныеМетаданные(
                до, разрешитьSymlink: разрешитьSymlink)
            switch до.st_mode & S_IFMT {
            case S_IFDIR:
                let дочерний = имя.withCString {
                    openat(
                        descriptor, $0,
                        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                }
                guard дочерний >= 0 else {
                    throw ОтказBootstrapЗависимости.отказ("Каталог materialization заменён")
                }
                do {
                    try потребоватьТотЖеУзел(
                        дочерний, что: до, разрешитьSymlink: разрешитьSymlink)
                    try проверитьКаталогРекурсивно(
                        дочерний,
                        разрешитьSymlink: разрешитьSymlink,
                        синхронизировать: синхронизировать)
                    try потребоватьТотЖеУзел(
                        дочерний, что: до, разрешитьSymlink: разрешитьSymlink)
                    try потребоватьТоЖеИмя(
                        имя, в: descriptor, сведения: до,
                        разрешитьSymlink: разрешитьSymlink)
                } catch {
                    close(дочерний)
                    throw error
                }
                guard close(дочерний) == 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "close каталога materialization отказал")
                }
            case S_IFREG:
                let файл = имя.withCString {
                    openat(descriptor, $0, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
                }
                guard файл >= 0 else {
                    throw ОтказBootstrapЗависимости.отказ("Файл materialization недоступен")
                }
                do {
                    try потребоватьТотЖеУзел(
                        файл, что: до, разрешитьSymlink: разрешитьSymlink)
                    if синхронизировать, fsync(файл) != 0 {
                        throw ОтказBootstrapЗависимости.отказ(
                            "fsync файла materialization отказал: errno=\(errno)")
                    }
                    try потребоватьТотЖеУзел(
                        файл, что: до, разрешитьSymlink: разрешитьSymlink)
                    try потребоватьТоЖеИмя(
                        имя, в: descriptor, сведения: до,
                        разрешитьSymlink: разрешитьSymlink)
                } catch {
                    close(файл)
                    throw error
                }
                guard close(файл) == 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "close файла materialization отказал")
                }
            case S_IFLNK:
                guard разрешитьSymlink else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "Admin materialization содержит symlink")
                }
                try потребоватьТоЖеИмя(
                    имя, в: descriptor, сведения: до,
                    разрешитьSymlink: разрешитьSymlink)
            default:
                throw ОтказBootstrapЗависимости.отказ(
                    "Materialization содержит неподдерживаемый тип узла")
            }
        }
        guard !синхронизировать || fsync(descriptor) == 0 else {
            throw ОтказBootstrapЗависимости.отказ(
                "fsync каталога materialization отказал: errno=\(errno)")
        }
    }

    private static func потребоватьТотЖеУзел(
        _ descriptor: Int32,
        что до: stat,
        разрешитьSymlink: Bool
    ) throws {
        var после = stat()
        guard fstat(descriptor, &после) == 0,
              после.st_dev == до.st_dev,
              после.st_ino == до.st_ino,
              (после.st_mode & S_IFMT) == (до.st_mode & S_IFMT) else {
            throw ОтказBootstrapЗависимости.отказ(
                "Узел materialization заменён между fstatat и openat")
        }
        try потребоватьБезопасныеМетаданные(
            после, разрешитьSymlink: разрешитьSymlink)
    }

    private static func потребоватьТоЖеИмя(
        _ имя: String,
        в родитель: Int32,
        сведения до: stat,
        разрешитьSymlink: Bool
    ) throws {
        var после = stat()
        guard имя.withCString({
            fstatat(родитель, $0, &после, AT_SYMLINK_NOFOLLOW)
        }) == 0,
              после.st_dev == до.st_dev,
              после.st_ino == до.st_ino,
              (после.st_mode & S_IFMT) == (до.st_mode & S_IFMT) else {
            throw ОтказBootstrapЗависимости.отказ(
                "Имя materialization заменено во время durable readback")
        }
        try потребоватьБезопасныеМетаданные(
            после, разрешитьSymlink: разрешитьSymlink)
    }

    private static func потребоватьБезопасныеМетаданные(
        _ сведения: stat,
        разрешитьSymlink: Bool
    ) throws {
        guard сведения.st_uid == geteuid() else {
            throw ОтказBootstrapЗависимости.отказ("Materialization содержит чужой узел")
        }
        switch сведения.st_mode & S_IFMT {
        case S_IFDIR:
            guard (сведения.st_mode & mode_t(0o022)) == 0 else {
                throw ОтказBootstrapЗависимости.отказ(
                    "Каталог materialization доступен для внешней записи")
            }
        case S_IFREG:
            guard сведения.st_nlink == 1,
                  (сведения.st_mode & mode_t(0o022)) == 0 else {
                throw ОтказBootstrapЗависимости.отказ(
                    "Обычный файл materialization не является private single-link")
            }
        case S_IFLNK:
            guard разрешитьSymlink else {
                throw ОтказBootstrapЗависимости.отказ(
                    "Admin materialization содержит symlink")
            }
        default:
            throw ОтказBootstrapЗависимости.отказ(
                "Materialization содержит неподдерживаемый тип узла")
        }
    }

    private struct ИменованныйУзел {
        let имя: String
        let сведения: stat
    }

    private static func хэшМатериализации(
        adminFD: Int32,
        destinationFD: Int32
    ) throws -> String {
        var каноническиеДанные = Data()
        try добавитьДеревоВОтпечаток(
            adminFD,
            путь: "admin",
            разрешитьSymlink: false,
            в: &каноническиеДанные)
        try добавитьДеревоВОтпечаток(
            destinationFD,
            путь: "worktree",
            разрешитьSymlink: true,
            в: &каноническиеДанные)
        return "sha256:" + SHA256.hash(data: каноническиеДанные)
            .map { String(format: "%02x", $0) }.joined()
    }

    private static func добавитьДеревоВОтпечаток(
        _ descriptor: Int32,
        путь: String,
        разрешитьSymlink: Bool,
        в данные: inout Data
    ) throws {
        var кореньДо = stat()
        guard fstat(descriptor, &кореньДо) == 0,
              (кореньДо.st_mode & S_IFMT) == S_IFDIR else {
            throw ОтказBootstrapЗависимости.отказ("Корень отпечатка не является каталогом")
        }
        try потребоватьБезопасныеМетаданные(
            кореньДо, разрешитьSymlink: разрешитьSymlink)
        добавитьЗаписьМетаданных(
            путь: путь, вид: "directory", сведения: кореньДо, contentHash: nil,
            в: &данные)
        let первый = try снимокКаталога(
            descriptor, разрешитьSymlink: разрешитьSymlink)
        for узел in первый {
            let дочернийПуть = путь + "/" + узел.имя
            switch узел.сведения.st_mode & S_IFMT {
            case S_IFDIR:
                let дочерний = узел.имя.withCString {
                    openat(
                        descriptor, $0,
                        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                }
                guard дочерний >= 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "Каталог отпечатка заменён до openat")
                }
                do {
                    try потребоватьТотЖеУзел(
                        дочерний, что: узел.сведения,
                        разрешитьSymlink: разрешитьSymlink)
                    try добавитьДеревоВОтпечаток(
                        дочерний,
                        путь: дочернийПуть,
                        разрешитьSymlink: разрешитьSymlink,
                        в: &данные)
                    try потребоватьТотЖеУзел(
                        дочерний, что: узел.сведения,
                        разрешитьSymlink: разрешитьSymlink)
                    try потребоватьТоЖеИмя(
                        узел.имя, в: descriptor, сведения: узел.сведения,
                        разрешитьSymlink: разрешитьSymlink)
                } catch {
                    close(дочерний)
                    throw error
                }
                guard close(дочерний) == 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "close каталога отпечатка отказал")
                }
            case S_IFREG:
                let файл = узел.имя.withCString {
                    openat(descriptor, $0, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
                }
                guard файл >= 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "Файл отпечатка заменён до openat")
                }
                do {
                    try потребоватьТотЖеУзел(
                        файл, что: узел.сведения,
                        разрешитьSymlink: разрешитьSymlink)
                    let contentHash = try хэшСодержимогоФайла(файл)
                    try потребоватьТотЖеУзел(
                        файл, что: узел.сведения,
                        разрешитьSymlink: разрешитьSymlink)
                    try потребоватьТоЖеИмя(
                        узел.имя, в: descriptor, сведения: узел.сведения,
                        разрешитьSymlink: разрешитьSymlink)
                    добавитьЗаписьМетаданных(
                        путь: дочернийПуть, вид: "file",
                        сведения: узел.сведения, contentHash: contentHash,
                        в: &данные)
                } catch {
                    close(файл)
                    throw error
                }
                guard close(файл) == 0 else {
                    throw ОтказBootstrapЗависимости.отказ("close файла отпечатка отказал")
                }
            case S_IFLNK:
                guard разрешитьSymlink else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "Admin отпечаток содержит symlink")
                }
                var buffer = [CChar](repeating: 0, count: Int(PATH_MAX) + 1)
                let число = узел.имя.withCString {
                    readlinkat(descriptor, $0, &buffer, buffer.count)
                }
                guard число >= 0, число < buffer.count else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "Не удалось прочитать symlink отпечатка")
                }
                try потребоватьТоЖеИмя(
                    узел.имя, в: descriptor, сведения: узел.сведения,
                    разрешитьSymlink: разрешитьSymlink)
                let target = Data(bytes: buffer, count: число)
                let contentHash = "sha256:" + SHA256.hash(data: target)
                    .map { String(format: "%02x", $0) }.joined()
                добавитьЗаписьМетаданных(
                    путь: дочернийПуть, вид: "symlink",
                    сведения: узел.сведения, contentHash: contentHash,
                    в: &данные)
            default:
                throw ОтказBootstrapЗависимости.отказ(
                    "Отпечаток встретил неподдерживаемый узел")
            }
        }
        let второй = try снимокКаталога(
            descriptor, разрешитьSymlink: разрешитьSymlink)
        guard снимкиРавны(первый, второй) else {
            throw ОтказBootstrapЗависимости.отказ(
                "Набор имён или metadata каталога изменились во время отпечатка")
        }
        var кореньПосле = stat()
        guard fstat(descriptor, &кореньПосле) == 0,
              сведенияРавны(кореньДо, кореньПосле) else {
            throw ОтказBootstrapЗависимости.отказ(
                "Корень каталога изменился во время отпечатка")
        }
    }

    private static func снимокКаталога(
        _ descriptor: Int32,
        разрешитьSymlink: Bool
    ) throws -> [ИменованныйУзел] {
        let копия = fcntl(descriptor, F_DUPFD_CLOEXEC, 0)
        guard копия >= 0, let поток = fdopendir(копия) else {
            if копия >= 0 { close(копия) }
            throw ОтказBootstrapЗависимости.отказ("Не удалось открыть каталог отпечатка")
        }
        defer { closedir(поток) }
        rewinddir(поток)
        var результат: [ИменованныйУзел] = []
        while true {
            errno = 0
            guard let entry = readdir(поток) else {
                guard errno == 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "Перечисление отпечатка отказало: errno=\(errno)")
                }
                break
            }
            var запись = entry.pointee
            let имя = withUnsafePointer(to: &запись.d_name) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXNAMLEN) + 1) {
                    String(cString: $0)
                }
            }
            if имя == "." || имя == ".." { continue }
            guard !имя.contains("/") else {
                throw ОтказBootstrapЗависимости.отказ("Небезопасное имя в отпечатке")
            }
            var сведения = stat()
            guard имя.withCString({
                fstatat(descriptor, $0, &сведения, AT_SYMLINK_NOFOLLOW)
            }) == 0 else {
                throw ОтказBootstrapЗависимости.отказ("Узел отпечатка исчез")
            }
            try потребоватьБезопасныеМетаданные(
                сведения, разрешитьSymlink: разрешитьSymlink)
            результат.append(ИменованныйУзел(имя: имя, сведения: сведения))
        }
        let sorted = результат.sorted { Data($0.имя.utf8).lexicographicallyPrecedes(Data($1.имя.utf8)) }
        guard Set(sorted.map(\.имя)).count == sorted.count else {
            throw ОтказBootstrapЗависимости.отказ("Имя отпечатка повторено")
        }
        return sorted
    }

    private static func хэшСодержимогоФайла(_ descriptor: Int32) throws -> String {
        guard lseek(descriptor, 0, SEEK_SET) == 0 else {
            throw ОтказBootstrapЗависимости.отказ("Не удалось начать чтение файла отпечатка")
        }
        var hasher = SHA256()
        var buffer = [UInt8](repeating: 0, count: 65_536)
        while true {
            let число = Darwin.read(descriptor, &buffer, buffer.count)
            if число < 0, errno == EINTR { continue }
            guard число >= 0 else {
                throw ОтказBootstrapЗависимости.отказ("Чтение файла отпечатка отказало")
            }
            if число == 0 { break }
            hasher.update(data: Data(buffer.prefix(Int(число))))
        }
        return "sha256:" + hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func добавитьЗаписьМетаданных(
        путь: String,
        вид: String,
        сведения: stat,
        contentHash: String?,
        в данные: inout Data
    ) {
        for поле in [
            путь,
            вид,
            String(сведения.st_dev),
            String(сведения.st_ino),
            String(сведения.st_mode),
            String(сведения.st_uid),
            String(сведения.st_gid),
            String(сведения.st_nlink),
            String(сведения.st_size),
            String(сведения.st_mtimespec.tv_sec),
            String(сведения.st_mtimespec.tv_nsec),
            String(сведения.st_ctimespec.tv_sec),
            String(сведения.st_ctimespec.tv_nsec),
            contentHash ?? "-",
        ] {
            let bytes = Data(поле.utf8)
            данные.append(Data("\(bytes.count):".utf8))
            данные.append(bytes)
            данные.append(0)
        }
    }

    private static func снимкиРавны(
        _ левый: [ИменованныйУзел],
        _ правый: [ИменованныйУзел]
    ) -> Bool {
        guard левый.count == правый.count else { return false }
        return zip(левый, правый).allSatisfy {
            Data($0.имя.utf8) == Data($1.имя.utf8)
                && сведенияРавны($0.сведения, $1.сведения)
        }
    }

    private static func сведенияРавны(_ lhs: stat, _ rhs: stat) -> Bool {
        lhs.st_dev == rhs.st_dev
            && lhs.st_ino == rhs.st_ino
            && lhs.st_mode == rhs.st_mode
            && lhs.st_uid == rhs.st_uid
            && lhs.st_gid == rhs.st_gid
            && lhs.st_nlink == rhs.st_nlink
            && lhs.st_size == rhs.st_size
            && lhs.st_mtimespec.tv_sec == rhs.st_mtimespec.tv_sec
            && lhs.st_mtimespec.tv_nsec == rhs.st_mtimespec.tv_nsec
            && lhs.st_ctimespec.tv_sec == rhs.st_ctimespec.tv_sec
            && lhs.st_ctimespec.tv_nsec == rhs.st_ctimespec.tv_nsec
    }
}
