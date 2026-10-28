import Darwin
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
    private let устройство: dev_t
    private let inode: ino_t

    package init(gitDir: String, создать: Bool) throws {
        self.gitDir = URL(fileURLWithPath: gitDir, isDirectory: true)
        self.каталог = self.gitDir.appendingPathComponent(
            "dependency-bootstrap", isDirectory: true)
        let локальныйGitDirFD = open(
            gitDir, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
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
            guard close(descriptor) == 0 else {
                throw ОтказBootstrapЗависимости.отказ("close readback отказал")
            }
            return данные
        } catch {
            close(descriptor)
            throw error
        }
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

    private func проверитьСтабильность() throws {
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

package enum ДолговечностьBootstrap {
    package static func синхронизироватьМатериализацию(
        adminGitDir: URL,
        destination: URL,
        граница: ПриватнаяГраницаBootstrap
    ) throws {
        try синхронизироватьДерево(adminGitDir)
        try синхронизироватьДерево(destination)
        try синхронизироватьКаталог(adminGitDir.deletingLastPathComponent())
        try синхронизироватьКаталог(destination.deletingLastPathComponent())
        try граница.синхронизироватьКаталог()
        try граница.синхронизироватьGitDir()
    }

    private static func синхронизироватьДерево(_ корень: URL) throws {
        var сведения = stat()
        guard lstat(корень.path, &сведения) == 0,
              (сведения.st_mode & S_IFMT) == S_IFDIR else {
            throw ОтказBootstrapЗависимости.отказ("Корень materialization не является каталогом")
        }
        guard let resolved = realpath(корень.path, nil) else {
            throw ОтказBootstrapЗависимости.отказ("Физический корень materialization недоступен")
        }
        defer { free(resolved) }
        guard Data(String(cString: resolved).utf8) == Data(корень.path.utf8) else {
            throw ОтказBootstrapЗависимости.отказ("Корень materialization перенаправлен")
        }
        try синхронизироватьКаталогРекурсивно(корень)
    }

    private static func синхронизироватьКаталогРекурсивно(_ каталог: URL) throws {
        let имена = try FileManager.default.contentsOfDirectory(atPath: каталог.path)
        for имя in имена {
            guard имя != ".", имя != "..", !имя.contains("/") else {
                throw ОтказBootstrapЗависимости.отказ("Небезопасное имя materialization")
            }
            let путь = каталог.appendingPathComponent(имя)
            var сведения = stat()
            guard lstat(путь.path, &сведения) == 0 else {
                throw ОтказBootstrapЗависимости.отказ("Компонент materialization исчез")
            }
            switch сведения.st_mode & S_IFMT {
            case S_IFDIR:
                try синхронизироватьКаталогРекурсивно(путь)
            case S_IFREG:
                let descriptor = open(путь.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
                guard descriptor >= 0 else {
                    throw ОтказBootstrapЗависимости.отказ("Файл materialization недоступен")
                }
                let код = fsync(descriptor)
                let причина = errno
                close(descriptor)
                guard код == 0 else {
                    throw ОтказBootstrapЗависимости.отказ(
                        "fsync файла materialization отказал: errno=\(причина)")
                }
            case S_IFLNK:
                continue
            default:
                throw ОтказBootstrapЗависимости.отказ(
                    "Materialization содержит неподдерживаемый тип узла")
            }
        }
        try синхронизироватьКаталог(каталог)
    }

    private static func синхронизироватьКаталог(_ каталог: URL) throws {
        let descriptor = open(каталог.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else {
            throw ОтказBootstrapЗависимости.отказ("Каталог materialization недоступен")
        }
        let код = fsync(descriptor)
        let причина = errno
        close(descriptor)
        guard код == 0 else {
            throw ОтказBootstrapЗависимости.отказ(
                "fsync каталога materialization отказал: errno=\(причина)")
        }
    }
}
