import Foundation
import Darwin

enum ПутьХранилища {
    static func подготовить(_ путь: String) throws -> URL {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        guard путь.hasPrefix("/"), !путь.utf8.contains(0), части.count > 1,
              части.dropFirst().allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw ОтказЗапуска(код: .небезопасныйПуть, сообщение: "Нужен физический абсолютный путь без пустых компонентов, . и ...")
        }
        var дескриптор = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard дескриптор >= 0 else { throw системнаяОшибка() }
        defer { _ = Darwin.close(дескриптор) }
        for часть in части.dropFirst() {
            try проверитьGit(дескриптор)
            guard часть != ".git" else {
                throw ОтказЗапуска(код: .внутриGit, сообщение: "Хранилище не размещается внутри .git.")
            }
            let компонент = String(часть)
            var сведения = stat()
            if fstatat(дескриптор, компонент, &сведения, AT_SYMLINK_NOFOLLOW) == 0 {
                guard сведения.st_mode & S_IFMT == S_IFDIR else {
                    throw ОтказЗапуска(код: .небезопасныйПуть, сообщение: "Компонент пути не является обычным каталогом.")
                }
            } else {
                guard errno == ENOENT else { throw системнаяОшибка() }
                guard mkdirat(дескриптор, компонент, 0o700) == 0 || errno == EEXIST
                else { throw системнаяОшибка() }
            }
            let следующий = openat(дескриптор, компонент,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard следующий >= 0 else {
                let код = errno
                if код == ELOOP || код == ENOTDIR {
                    throw ОтказЗапуска(код: .небезопасныйПуть,
                        сообщение: "Символический либо недопустимый компонент пути.", системныйКод: код)
                }
                throw системнаяОшибка(код)
            }
            _ = Darwin.close(дескриптор)
            дескриптор = следующий
        }
        try проверитьGit(дескриптор)
        var сведения = stat()
        guard fstat(дескриптор, &сведения) == 0 else { throw системнаяОшибка() }
        guard сведения.st_uid == geteuid(), сведения.st_mode & 0o7777 == 0o700 else {
            throw ОтказЗапуска(код: .небезопасныйПуть, сообщение: "Каталог должен принадлежать текущему пользователю и иметь режим 0700; существующий режим не исправляется.")
        }
        return URL(fileURLWithPath: путь, isDirectory: true)
    }

    private static func проверитьGit(_ дескриптор: Int32) throws {
        var сведения = stat()
        if fstatat(дескриптор, ".git", &сведения, AT_SYMLINK_NOFOLLOW) == 0 {
            throw ОтказЗапуска(код: .внутриGit, сообщение: "Хранилище находится под маркером Git.")
        }
        guard errno == ENOENT else { throw системнаяОшибка() }
        let признаки = ["HEAD", "objects", "refs"]
        var найдено = 0
        for признак in признаки {
            if fstatat(дескриптор, признак, &сведения, AT_SYMLINK_NOFOLLOW) == 0 {
                найдено += 1
            } else if errno != ENOENT {
                throw системнаяОшибка()
            }
        }
        guard найдено != признаки.count else {
            throw ОтказЗапуска(код: .внутриGit, сообщение: "Хранилище находится внутри каталога Git.")
        }
    }

    private static func системнаяОшибка(_ код: Int32 = errno) -> ОтказЗапуска {
        ОтказЗапуска(код: .системнаяОшибка, сообщение: "Ошибка подготовки каталога хранилища.", системныйКод: код)
    }
}
