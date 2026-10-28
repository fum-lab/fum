import CryptoKit
import Darwin
import Foundation

enum ОтказBootstrapЗависимости: Error, CustomStringConvertible {
    case отказ(String)

    var description: String {
        switch self {
        case .отказ(let пояснение): return пояснение
        }
    }
}

package enum ЭтапДолговечностиBootstrap: String, Sendable {
    case намерениеСинхронизировано
    case материализацияСинхронизирована
    case исходСинхронизирован
}

package enum СостояниеBootstrapЗависимости: String, Codable, Sendable {
    case отсутствует
    case намерение
    case готова
    case отказ
}

package struct ПланBootstrapЗависимости: Codable, Equatable, Sendable {
    let схема: String
    let корень: String
    let head: String
    let ref: String
    let путь: String
    let имя: String
    let originURL: String
    let upstreamURL: String
    let gitlinkOID: String
    let gitDir: String
    let commonGitDir: String
    let adminGitDir: String
    let состояние: СостояниеBootstrapЗависимости
}

package struct ИсходBootstrapЗависимости: Codable, Equatable, Sendable {
    let схема: String
    let хэшПлана: String
    let состояние: СостояниеBootstrapЗависимости
    let путь: String
    let gitlinkOID: String
    let adminGitDir: String
    let хэшМатериализации: String?
    let пояснение: String?
}

private struct РезультатКоманды {
    let код: Int32
    let данные: Data

    var текст: String {
        String(decoding: данные, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ЗаписьSubmodule {
    let имя: String
    let путь: String
    let origin: String
    let upstream: String
}

package enum BootstrapЗависимости {
    private static let схемаПлана = "fum.bootstrap-git-zavisimosti.1"
    private static let схемаИсхода = "fum.bootstrap-git-zavisimosti-outcome.2"

    package static func построитьПлан(корень исходныйКорень: URL, путь: String) throws
        -> ПланBootstrapЗависимости
    {
        let корень = try физическийКаталог(исходныйКорень)
        try проверитьОтносительныйПуть(путь)
        let manifestURL = try точныйПуть(
            корень: корень, относительный: ".gitmodules", допускаетсяОтсутствующийФинал: false)
        let manifestBytes = try Data(contentsOf: manifestURL)
        guard String(data: manifestBytes, encoding: .utf8) != nil else {
            throw отказ(".gitmodules не является строгим UTF-8")
        }
        let stagedManifest = try gitУспешно(["show", ":.gitmodules"], в: корень).данные
        guard stagedManifest == manifestBytes else {
            throw отказ(".gitmodules не совпадает с точными байтами индекса")
        }
        let manifestStage = try gitУспешно(
            ["ls-files", "--stage", "-z", "--", ".gitmodules"], в: корень).данные
        try проверитьStageОбычногоФайла(manifestStage, путь: ".gitmodules")
        let записи = try разобратьManifest(manifestBytes)
        let совпадения = записи.filter { Data($0.путь.utf8) == Data(путь.utf8) }
        guard совпадения.count == 1, let запись = совпадения.first else {
            throw отказ(".gitmodules должен содержать ровно одну регистрацию точного пути")
        }

        let stage = try gitУспешно(["ls-files", "--stage", "-z", "--", путь], в: корень).данные
        let gitlink = try разобратьGitlink(stage, путь: путь)
        let head = try gitТекст(["rev-parse", "HEAD"], в: корень)
        let symbolic = try git(["symbolic-ref", "-q", "HEAD"], в: корень)
        guard symbolic.код == 0 || symbolic.код == 1 else {
            throw отказ("Не удалось прочитать symbolic ref superproject")
        }
        let ref = symbolic.код == 0 ? symbolic.текст : "(detached)"
        let gitDir = try физическийПутьКаталога(
            URL(fileURLWithPath: try gitТекст(
                ["rev-parse", "--path-format=absolute", "--git-dir"], в: корень)))
        let commonGitDir = try физическийПутьКаталога(
            URL(fileURLWithPath: try gitТекст(
                ["rev-parse", "--path-format=absolute", "--git-common-dir"], в: корень)))
        guard Data(gitDir.utf8) != Data(commonGitDir.utf8) else {
            throw отказ("Bootstrap требует отдельный adminDir linked worktree")
        }
        let суффикс = String(sha256(Data(путь.utf8)).dropFirst("sha256:".count).prefix(16))
        let adminGitDir = gitDir + "/dependency-bootstrap/admin-\(суффикс).git"
        let внутриРабочегоAdmin = находитсяВнутри(adminGitDir, корень: gitDir)
        let внутриОбщихModules = находитсяВнутри(adminGitDir, корень: commonGitDir + "/modules")
        guard внутриРабочегоAdmin, !внутриОбщихModules else {
            throw отказ(
                "Admin Gitdir зависимости должен находиться только внутри adminDir linked worktree: "
                + "admin=\(adminGitDir), gitDir=\(gitDir), common=\(commonGitDir), "
                + "inside-worktree=\(внутриРабочегоAdmin), inside-common-modules=\(внутриОбщихModules)")
        }
        let планОтсутствия = ПланBootstrapЗависимости(
            схема: схемаПлана, корень: корень.path, head: head, ref: ref,
            путь: путь, имя: запись.имя, originURL: запись.origin,
            upstreamURL: запись.upstream, gitlinkOID: gitlink,
            gitDir: gitDir, commonGitDir: commonGitDir,
            adminGitDir: adminGitDir, состояние: .отсутствует)

        let destination = try точныйПуть(
            корень: корень, относительный: путь, допускаетсяОтсутствующийФинал: true)
        let состояние: СостояниеBootstrapЗависимости
        if FileManager.default.fileExists(atPath: destination.path) {
            let содержимое = try FileManager.default.contentsOfDirectory(atPath: destination.path)
            if содержимое.isEmpty {
                состояние = .отсутствует
            } else {
                try проверитьГотовуюЗависимостьБезЗаписи(
                    планОтсутствия)
                состояние = .готова
            }
        } else {
            состояние = .отсутствует
        }
        if состояние == .отсутствует {
            let scopedStatus = try gitУспешно(
                ["status", "--porcelain=v1", "--untracked-files=all", "--", ".gitmodules", путь],
                в: корень).данные
            guard scopedStatus.isEmpty else {
                throw отказ("Регистрация зависимости имеет локальный дрейф")
            }
        }

        return ПланBootstrapЗависимости(
            схема: схемаПлана, корень: корень.path, head: head, ref: ref,
            путь: путь, имя: запись.имя, originURL: запись.origin,
            upstreamURL: запись.upstream, gitlinkOID: gitlink,
            gitDir: gitDir, commonGitDir: commonGitDir,
            adminGitDir: adminGitDir, состояние: состояние)
    }

    package static func применить(
        план: ПланBootstrapЗависимости,
        квитанция: URL
    ) throws -> ИсходBootstrapЗависимости {
        try применить(план: план, квитанция: квитанция, наблюдатель: { _ in })
    }

    package static func применить(
        план: ПланBootstrapЗависимости,
        квитанция: URL,
        наблюдатель: (ЭтапДолговечностиBootstrap) -> Void,
        передGitЭффектом: () throws -> Void = {},
        передРазделениемGit: () throws -> Void = {},
        послеFsyncПередDigest: () throws -> Void = {}
    ) throws -> ИсходBootstrapЗависимости {
        guard план.схема == схемаПлана, план.состояние == .отсутствует else {
            throw отказ("Apply разрешён только для проверенного отсутствующего пути")
        }
        let свежий = try построитьПлан(
            корень: URL(fileURLWithPath: план.корень, isDirectory: true), путь: план.путь)
        guard свежий == план else { throw отказ("План bootstrap изменился до применения") }
        let компоненты = план.путь.split(separator: "/", omittingEmptySubsequences: false)
        guard компоненты.count == 2 else {
            throw отказ("Fd-stable bootstrap поддерживает точный двухкомпонентный путь")
        }
        let имяРодителя = String(компоненты[0])
        let имяНазначения = String(компоненты[1])
        let граница = try ПриватнаяГраницаBootstrap(gitDir: план.gitDir, создать: true)
        let родительЗависимости = try УдержанныйКаталогЗависимостей(
            корень: URL(fileURLWithPath: план.корень, isDirectory: true),
            имяРодителя: имяРодителя)
        guard граница.устройствоФайловойСистемы
                == родительЗависимости.устройствоФайловойСистемы else {
            throw отказ("Fd-stable rename невозможен между разными файловыми системами")
        }
        let имяКвитанции = try граница.имяФайла(квитанция)
        guard имяКвитанции == "outcome.json" else {
            throw отказ("Bootstrap требует каноническое имя outcome.json")
        }
        let admin = URL(fileURLWithPath: план.adminGitDir, isDirectory: true)
        guard Data(admin.deletingLastPathComponent().path.utf8)
                == Data(граница.каталог.path.utf8) else {
            throw отказ("Admin Gitdir не является прямым ребёнком приватной границы")
        }
        let имяAdmin = admin.lastPathComponent
        let имяStaging = ".staging-" + имяAdmin
        try родительЗависимости.потребоватьОтсутствующегоИлиПустогоРебёнка(
            имяНазначения)
        guard try граница.ребёнокОтсутствует(имяAdmin),
              try граница.ребёнокОтсутствует(имяStaging) else {
            throw отказ("Admin Gitdir или staging уже существует до intent")
        }
        let хэшПлана = try хэшКаноническогоПлана(план)
        let намерение = ИсходBootstrapЗависимости(
            схема: схемаИсхода, хэшПлана: хэшПлана, состояние: .намерение,
            путь: план.путь, gitlinkOID: план.gitlinkOID,
            adminGitDir: план.adminGitDir,
            хэшМатериализации: nil, пояснение: nil)
        try граница.записатьЭксклюзивно(
            try каноническиеДанные(намерение), имя: имяКвитанции)
        наблюдатель(.намерениеСинхронизировано)

        var gitЭффектНачат = false
        var материализацияДолговечна = false
        do {
            let stagingFD = try создатьПриватныйStaging(
                имя: имяStaging, в: граница.файловыйДескрипторКаталога)
            defer { close(stagingFD) }
            try граница.синхронизироватьКаталог()
            try родительЗависимости.проверитьСтабильность()
            try граница.проверитьСтабильность()
            try передGitЭффектом()
            gitЭффектНачат = true
            _ = try gitУспешноFD([
                "-c", "protocol.file.allow=always",
                "clone", "--quiet", "--no-checkout", "--no-recurse-submodules",
                "--no-local", "--no-hardlinks", "--reject-shallow",
                план.originURL, ".",
            ], в: stagingFD)
            _ = try gitУспешноFD(
                ["remote", "add", "upstream", план.upstreamURL], в: stagingFD)
            _ = try gitУспешноFD([
                "-c", "protocol.file.allow=always",
                "fetch", "--quiet", "--prune", "upstream",
            ], в: stagingFD)
            _ = try gitУспешноFD([
                "checkout", "--quiet", "--detach", "--no-recurse-submodules", план.gitlinkOID,
            ], в: stagingFD)
            let adminFD = try открытьПриватныйКаталог(имя: ".git", в: stagingFD)
            defer { close(adminFD) }
            try проверитьГотовуюЗависимостьFD(
                stagingFD: stagingFD,
                origin: план.originURL,
                upstream: план.upstreamURL,
                gitlink: план.gitlinkOID)
            try проверитьИменованныйКаталог(
                ".git", в: stagingFD, совпадаетС: adminFD)
            try передРазделениемGit()
            try проверитьГотовуюЗависимостьFD(
                stagingFD: stagingFD,
                origin: план.originURL,
                upstream: план.upstreamURL,
                gitlink: план.gitlinkOID)
            try проверитьИменованныйКаталог(
                ".git", в: stagingFD, совпадаетС: adminFD)

            try граница.проверитьСтабильность()
            try родительЗависимости.проверитьСтабильность()
            guard try граница.ребёнокОтсутствует(имяAdmin) else {
                throw отказ("Admin Gitdir появился до fd-relative split")
            }
            try родительЗависимости.потребоватьОтсутствующегоИлиПустогоРебёнка(
                имяНазначения)
            try переименоватьБезЗамены(
                от: stagingFD, имяОт: ".git",
                к: граница.файловыйДескрипторКаталога, имяК: имяAdmin)
            try граница.синхронизироватьКаталог()
            try граница.проверитьРебёнка(имяAdmin, совпадаетС: adminFD)
            try записатьGitdirФайл(
                descriptor: stagingFD, adminGitDir: план.adminGitDir)
            try родительЗависимости.удалитьПустогоРебёнкаЕслиЕсть(имяНазначения)
            try переименоватьБезЗамены(
                от: граница.файловыйДескрипторКаталога, имяОт: имяStaging,
                к: родительЗависимости.файловыйДескриптор, имяК: имяНазначения)
            try граница.синхронизироватьКаталог()
            try родительЗависимости.синхронизировать()
            try граница.проверитьСтабильность()
            try граница.проверитьРебёнка(имяAdmin, совпадаетС: adminFD)
            try родительЗависимости.проверитьРебёнка(
                имяНазначения, совпадаетС: stagingFD)
            try проверитьGitdirФайлFD(
                stagingFD, ожидаемыйAdminGitDir: план.adminGitDir)
            let долговечныйХэш = try ДолговечностьBootstrap.синхронизироватьМатериализацию(
                adminFD: adminFD,
                destinationFD: stagingFD,
                родительЗависимости: родительЗависимости,
                граница: граница,
                послеСинхронизации: послеFsyncПередDigest)
            материализацияДолговечна = true
            наблюдатель(.материализацияСинхронизирована)
            let финальныйХэш = try ДолговечностьBootstrap.проверитьМатериализациюБезЗаписи(
                adminFD: adminFD, destinationFD: stagingFD)
            guard финальныйХэш == долговечныйХэш else {
                throw отказ("Материализация изменилась после durable boundary")
            }
            try проверитьСыройAdminReadback(adminFD: adminFD, план: план)
            try проверитьGitdirФайлFD(
                stagingFD, ожидаемыйAdminGitDir: план.adminGitDir)
            try граница.проверитьСтабильность()
            try граница.проверитьРебёнка(имяAdmin, совпадаетС: adminFD)
            try родительЗависимости.проверитьРебёнка(
                имяНазначения, совпадаетС: stagingFD)
            let хэшМатериализации = финальныйХэш
            let исход = ИсходBootstrapЗависимости(
                схема: схемаИсхода, хэшПлана: хэшПлана, состояние: .готова,
                путь: план.путь, gitlinkOID: план.gitlinkOID,
                adminGitDir: план.adminGitDir,
                хэшМатериализации: хэшМатериализации, пояснение: nil)
            try граница.заменитьАтомарно(
                try каноническиеДанные(исход), имя: имяКвитанции)
            наблюдатель(.исходСинхронизирован)
            return исход
        } catch {
            if gitЭффектНачат || материализацияДолговечна {
                throw отказ(
                    "Git-эффект начат, но terminal outcome неизвестен; "
                    + "intent сохранён, автоматический повтор запрещён: \(error)")
            }
            let исход = ИсходBootstrapЗависимости(
                схема: схемаИсхода, хэшПлана: хэшПлана, состояние: .отказ,
                путь: план.путь, gitlinkOID: план.gitlinkOID,
                adminGitDir: план.adminGitDir,
                хэшМатериализации: nil, пояснение: String(describing: error))
            do {
                try граница.заменитьАтомарно(
                    try каноническиеДанные(исход), имя: имяКвитанции)
            } catch {
                throw отказ(
                    "Bootstrap отказал, а terminal outcome не сохранён; "
                    + "эффект неизвестен, intent сохранён, автоматический повтор запрещён: \(error)")
            }
            throw error
        }
    }

    package static func проверитьПослеПрименения(
        план: ПланBootstrapЗависимости,
        квитанция: URL
    ) throws -> ИсходBootstrapЗависимости {
        let граница = try ПриватнаяГраницаBootstrap(gitDir: план.gitDir, создать: false)
        let имяКвитанции = try граница.имяФайла(квитанция)
        guard имяКвитанции == "outcome.json" else {
            throw отказ("Readback требует каноническое имя outcome.json")
        }
        let исход = try JSONDecoder().decode(
            ИсходBootstrapЗависимости.self,
            from: граница.прочитатьПриватныйФайл(имяКвитанции))
        guard исход.схема == схемаИсхода,
              исход.хэшПлана == (try хэшКаноническогоПлана(план)),
              исход.состояние == .готова,
              исход.путь == план.путь,
              исход.gitlinkOID == план.gitlinkOID,
              исход.adminGitDir == план.adminGitDir,
              исход.хэшМатериализации != nil else {
            throw отказ("Outcome не подтверждает успешное применение точного плана")
        }
        let компоненты = план.путь.split(separator: "/", omittingEmptySubsequences: false)
        guard компоненты.count == 2 else {
            throw отказ("Readback требует точный двухкомпонентный путь")
        }
        let admin = URL(fileURLWithPath: план.adminGitDir, isDirectory: true)
        guard Data(admin.deletingLastPathComponent().path.utf8)
                == Data(граница.каталог.path.utf8) else {
            throw отказ("Admin Gitdir вышел за приватную границу readback")
        }
        let родительЗависимости = try УдержанныйКаталогЗависимостей(
            корень: URL(fileURLWithPath: план.корень, isDirectory: true),
            имяРодителя: String(компоненты[0]))
        let worktreeFD = try родительЗависимости.открытьРебёнка(String(компоненты[1]))
        defer { close(worktreeFD) }
        let adminFD = try граница.дочернийКаталог(
            admin.lastPathComponent, укрепитьСозданный: false)
        defer { close(adminFD) }
        try родительЗависимости.проверитьРебёнка(
            String(компоненты[1]), совпадаетС: worktreeFD)
        try граница.проверитьРебёнка(admin.lastPathComponent, совпадаетС: adminFD)
        try проверитьGitdirФайлFD(
            worktreeFD, ожидаемыйAdminGitDir: план.adminGitDir)
        try проверитьСыройAdminReadback(adminFD: adminFD, план: план)
        let живойХэш = try ДолговечностьBootstrap.проверитьМатериализациюБезЗаписи(
            adminFD: adminFD, destinationFD: worktreeFD)
        guard живойХэш == исход.хэшМатериализации else {
            throw отказ("Exact materialization digest не совпадает с outcome")
        }
        try родительЗависимости.проверитьРебёнка(
            String(компоненты[1]), совпадаетС: worktreeFD)
        try граница.проверитьРебёнка(admin.lastPathComponent, совпадаетС: adminFD)
        return исход
    }

    package static func данныеПлана(_ план: ПланBootstrapЗависимости) throws -> Data {
        try каноническиеДанные(план)
    }

    package static func записатьПлан(_ план: ПланBootstrapЗависимости, в путь: URL) throws {
        let граница = try ПриватнаяГраницаBootstrap(gitDir: план.gitDir, создать: true)
        let имя = try граница.имяФайла(путь)
        try граница.записатьЭксклюзивно(try каноническиеДанные(план), имя: имя)
    }

    package static func прочитатьПлан(_ путь: URL) throws -> ПланBootstrapЗависимости {
        let родитель = путь.deletingLastPathComponent()
        guard родитель.lastPathComponent == "dependency-bootstrap" else {
            throw отказ("План находится вне точного каталога dependency-bootstrap")
        }
        let gitDir = родитель.deletingLastPathComponent().path
        let граница = try ПриватнаяГраницаBootstrap(gitDir: gitDir, создать: false)
        let имя = try граница.имяФайла(путь)
        let план = try JSONDecoder().decode(
            ПланBootstrapЗависимости.self,
            from: граница.прочитатьПриватныйФайл(имя))
        guard Data(план.gitDir.utf8) == Data(gitDir.utf8) else {
            throw отказ("gitDir внутри плана не совпадает с физическим родителем")
        }
        return план
    }

    private static func создатьПриватныйStaging(имя: String, в родитель: Int32) throws -> Int32 {
        guard безопасныйКомпонент(имя) else { throw отказ("Небезопасное имя staging") }
        guard имя.withCString({ mkdirat(родитель, $0, mode_t(0o700)) }) == 0 else {
            throw отказ("Не удалось эксклюзивно создать staging: errno=\(errno)")
        }
        return try открытьПриватныйКаталог(имя: имя, в: родитель)
    }

    private static func открытьПриватныйКаталог(имя: String, в родитель: Int32) throws
        -> Int32
    {
        guard безопасныйКомпонент(имя) else { throw отказ("Небезопасное имя каталога") }
        let descriptor = имя.withCString {
            openat(родитель, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw отказ("Fd-relative каталог недоступен: errno=\(errno)")
        }
        do {
            guard fchmod(descriptor, mode_t(0o700)) == 0 else {
                throw отказ("Не удалось закрепить mode 0700 каталога")
            }
            var сведения = stat()
            guard fstat(descriptor, &сведения) == 0 else {
                throw отказ("Не удалось прочитать fd-relative каталог")
            }
            try ПроверкаПриватногоУзла.каталог(сведения)
            return descriptor
        } catch {
            close(descriptor)
            throw error
        }
    }

    private static func проверитьИменованныйКаталог(
        _ имя: String,
        в родитель: Int32,
        совпадаетС descriptor: Int32
    ) throws {
        guard безопасныйКомпонент(имя) else { throw отказ("Небезопасное имя каталога") }
        var удержанный = stat()
        var именованный = stat()
        guard fstat(descriptor, &удержанный) == 0,
              имя.withCString({
                  fstatat(родитель, $0, &именованный, AT_SYMLINK_NOFOLLOW)
              }) == 0,
              именованный.st_dev == удержанный.st_dev,
              именованный.st_ino == удержанный.st_ino,
              (именованный.st_mode & S_IFMT) == S_IFDIR else {
            throw отказ("Именованный каталог не совпадает с удержанным FD")
        }
        try ПроверкаПриватногоУзла.каталог(именованный)
    }

    private static func переименоватьБезЗамены(
        от исходныйFD: Int32, имяОт: String,
        к итоговыйFD: Int32, имяК: String
    ) throws {
        guard безопасныйКомпонент(имяОт), безопасныйКомпонент(имяК) else {
            throw отказ("Небезопасный компонент fd-relative rename")
        }
        let код = имяОт.withCString { исходноеИмя in
            имяК.withCString { итоговоеИмя in
                renameatx_np(
                    исходныйFD, исходноеИмя,
                    итоговыйFD, итоговоеИмя,
                    UInt32(RENAME_EXCL))
            }
        }
        guard код == 0 else {
            throw отказ("Fd-relative rename без замены отказал: errno=\(errno)")
        }
    }

    private static func записатьGitdirФайл(
        descriptor stagingFD: Int32,
        adminGitDir: String
    ) throws {
        let descriptor = ".git".withCString {
            openat(
                stagingFD, $0,
                O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC,
                mode_t(0o600))
        }
        guard descriptor >= 0 else { throw отказ("Не удалось создать точный .git файл") }
        do {
            guard fchmod(descriptor, mode_t(0o600)) == 0 else {
                throw отказ("Не удалось закрепить mode 0600 файла .git")
            }
            var сведения = stat()
            guard fstat(descriptor, &сведения) == 0 else {
                throw отказ("Не удалось прочитать новый .git файл")
            }
            try ПроверкаПриватногоУзла.файл(сведения)
            try записатьПолностью(Data("gitdir: \(adminGitDir)\n".utf8), в: descriptor)
            guard fsync(descriptor) == 0 else { throw отказ("fsync .git файла отказал") }
        } catch {
            close(descriptor)
            throw error
        }
        guard close(descriptor) == 0, fsync(stagingFD) == 0 else {
            throw отказ("Не удалось синхронизировать .git файл и worktree")
        }
    }

    private static func проверитьGitdirФайлFD(
        _ stagingFD: Int32,
        ожидаемыйAdminGitDir: String
    ) throws {
        let descriptor = ".git".withCString {
            openat(stagingFD, $0, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else { throw отказ("Fd-relative .git файл недоступен") }
        do {
            var сведения = stat()
            guard fstat(descriptor, &сведения) == 0 else {
                throw отказ("Не удалось прочитать сведения .git файла")
            }
            try ПроверкаПриватногоУзла.файл(сведения)
            let данные = try прочитатьПолностью(descriptor)
            guard данные == Data("gitdir: \(ожидаемыйAdminGitDir)\n".utf8) else {
                throw отказ("Fd-relative .git файл содержит иной admin Gitdir")
            }
        } catch {
            close(descriptor)
            throw error
        }
        guard close(descriptor) == 0 else { throw отказ("close .git readback отказал") }
    }

    private static func проверитьСыройAdminReadback(
        adminFD: Int32,
        план: ПланBootstrapЗависимости
    ) throws {
        let head = try прочитатьБезопасныйФайл("HEAD", из: adminFD)
        guard head == Data("\(план.gitlinkOID)\n".utf8) else {
            throw отказ("Raw HEAD admin Gitdir не совпадает с exact gitlink")
        }
        let config = try прочитатьБезопасныйФайл("config", из: adminFD)
        let remotes = try разобратьRemoteConfig(config)
        guard Set(remotes.keys) == ["origin", "upstream"] else {
            throw отказ("Raw config содержит иной набор remote")
        }
        for (имя, url) in [("origin", план.originURL), ("upstream", план.upstreamURL)] {
            guard remotes[имя]?["url"] == [url],
                  remotes[имя]?["fetch"]
                    == ["+refs/heads/*:refs/remotes/\(имя)/*"] else {
                throw отказ("Raw config remote \(имя) не совпадает с планом")
            }
        }
        try потребоватьБезопасныйФайл("index", в: adminFD)
        var сведения = stat()
        let shallow = "shallow".withCString {
            fstatat(adminFD, $0, &сведения, AT_SYMLINK_NOFOLLOW)
        }
        guard shallow != 0, errno == ENOENT else {
            throw отказ("Raw admin Gitdir является shallow или небезопасен")
        }
        try потребоватьОтсутствиеAlternatesAdmin(adminFD)
    }

    private static func разобратьRemoteConfig(_ данные: Data) throws
        -> [String: [String: [String]]]
    {
        guard let текст = String(data: данные, encoding: .utf8) else {
            throw отказ("Git config не является строгим UTF-8")
        }
        var результат: [String: [String: [String]]] = [:]
        var текущийRemote: String?
        for raw in текст.split(separator: "\n", omittingEmptySubsequences: false) {
            let строка = String(raw).trimmingCharacters(in: .whitespaces)
            if строка.isEmpty || строка.hasPrefix("#") || строка.hasPrefix(";") { continue }
            if строка.hasPrefix("[remote \"") && строка.hasSuffix("\"]") {
                let имя = String(строка.dropFirst(9).dropLast(2))
                guard безопасныйКомпонент(имя), результат[имя] == nil else {
                    throw отказ("Git config содержит повторный или небезопасный remote")
                }
                результат[имя] = [:]
                текущийRemote = имя
                continue
            }
            if строка.hasPrefix("[") && строка.hasSuffix("]") {
                текущийRemote = nil
                continue
            }
            guard let remote = текущийRemote else { continue }
            guard let equal = строка.firstIndex(of: "=") else {
                throw отказ("Git config remote содержит поле без значения")
            }
            let ключ = String(строка[..<equal]).trimmingCharacters(in: .whitespaces)
            let значение = String(строка[строка.index(after: equal)...])
                .trimmingCharacters(in: .whitespaces)
            guard !ключ.isEmpty, !значение.isEmpty else {
                throw отказ("Git config remote содержит пустое поле")
            }
            результат[remote]![ключ, default: []].append(значение)
        }
        return результат
    }

    private static func потребоватьБезопасныйФайл(_ имя: String, в parentFD: Int32) throws {
        let descriptor = try открытьБезопасныйФайл(имя, в: parentFD)
        guard close(descriptor) == 0 else { throw отказ("close raw Git файла отказал") }
    }

    private static func прочитатьБезопасныйФайл(_ имя: String, из parentFD: Int32) throws
        -> Data
    {
        let descriptor = try открытьБезопасныйФайл(имя, в: parentFD)
        let данные: Data
        do {
            данные = try прочитатьПолностью(descriptor)
            try проверитьИменованныйФайл(имя, в: parentFD, совпадаетС: descriptor)
        } catch {
            close(descriptor)
            throw error
        }
        guard close(descriptor) == 0 else { throw отказ("close raw Git readback отказал") }
        return данные
    }

    private static func открытьБезопасныйФайл(_ имя: String, в parentFD: Int32) throws
        -> Int32
    {
        guard безопасныйКомпонент(имя) else { throw отказ("Небезопасное имя raw Git файла") }
        let descriptor = имя.withCString {
            openat(parentFD, $0, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else { throw отказ("Raw Git файл недоступен") }
        do {
            try проверитьИменованныйФайл(имя, в: parentFD, совпадаетС: descriptor)
            return descriptor
        } catch {
            close(descriptor)
            throw error
        }
    }

    private static func проверитьИменованныйФайл(
        _ имя: String,
        в parentFD: Int32,
        совпадаетС descriptor: Int32
    ) throws {
        var удержанный = stat()
        var именованный = stat()
        guard fstat(descriptor, &удержанный) == 0,
              имя.withCString({
                  fstatat(parentFD, $0, &именованный, AT_SYMLINK_NOFOLLOW)
              }) == 0,
              (удержанный.st_mode & S_IFMT) == S_IFREG,
              удержанный.st_dev == именованный.st_dev,
              удержанный.st_ino == именованный.st_ino,
              удержанный.st_uid == geteuid(),
              удержанный.st_nlink == 1,
              (удержанный.st_mode & mode_t(0o022)) == 0,
              удержанный.st_mode == именованный.st_mode,
              удержанный.st_uid == именованный.st_uid,
              удержанный.st_nlink == именованный.st_nlink else {
            throw отказ("Raw Git файл заменён или имеет небезопасные метаданные")
        }
    }

    private static func записатьПолностью(_ данные: Data, в descriptor: Int32) throws {
        try данные.withUnsafeBytes { raw in
            guard var адрес = raw.baseAddress else { return }
            var остаток = raw.count
            while остаток > 0 {
                let число = Darwin.write(descriptor, адрес, остаток)
                if число < 0, errno == EINTR { continue }
                guard число > 0 else { throw отказ("Fd-relative запись отказала") }
                адрес = адрес.advanced(by: число)
                остаток -= число
            }
        }
    }

    private static func прочитатьПолностью(_ descriptor: Int32) throws -> Data {
        var результат = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let число = Darwin.read(descriptor, &buffer, buffer.count)
            if число < 0, errno == EINTR { continue }
            guard число >= 0 else { throw отказ("Fd-relative чтение отказало") }
            if число == 0 { return результат }
            результат.append(contentsOf: buffer.prefix(Int(число)))
        }
    }

    private static func безопасныйКомпонент(_ имя: String) -> Bool {
        !имя.isEmpty && имя != "." && имя != ".." && !имя.contains("/") && !имя.contains("\\")
    }

    private static func проверитьГотовуюЗависимостьFD(
        stagingFD: Int32,
        origin: String,
        upstream: String,
        gitlink: String
    ) throws {
        guard try gitТекстFD(["rev-parse", "--git-dir"], в: stagingFD) == ".git" else {
            throw отказ("Staging использует не локальный .git каталог")
        }
        guard try gitТекстFD(
            ["rev-parse", "--is-shallow-repository"], в: stagingFD) == "false" else {
            throw отказ("Shallow materialization запрещена")
        }
        guard try gitТекстFD(["rev-parse", "HEAD"], в: stagingFD) == gitlink else {
            throw отказ("HEAD staging не совпадает с gitlink")
        }
        let symbolic = try gitFD(["symbolic-ref", "-q", "HEAD"], в: stagingFD)
        guard symbolic.код == 1 else { throw отказ("HEAD staging должен быть detached") }
        let remotes = try gitТекстFD(["remote"], в: stagingFD)
            .split(separator: "\n").map(String.init)
        guard remotes.sorted() == ["origin", "upstream"] else {
            throw отказ("Набор remote staging не точен")
        }
        for (имя, url) in [("origin", origin), ("upstream", upstream)] {
            guard try gitТекстFD(["remote", "get-url", имя], в: stagingFD) == url else {
                throw отказ("URL remote \(имя) не совпадает с manifest")
            }
            let refspec = try gitТекстFD(
                ["config", "--get-all", "remote.\(имя).fetch"], в: stagingFD)
            guard refspec == "+refs/heads/*:refs/remotes/\(имя)/*" else {
                throw отказ("Fetch refspec remote \(имя) не точен")
            }
            let вершины = try gitТекстFD([
                "for-each-ref", "--format=%(objectname)", "refs/remotes/\(имя)/",
            ], в: stagingFD).split(separator: "\n").map(String.init)
            var достижим = false
            for вершина in Set(вершины) {
                let проверка = try gitFD(
                    ["merge-base", "--is-ancestor", gitlink, вершина], в: stagingFD)
                guard проверка.код == 0 || проверка.код == 1 else {
                    throw отказ("Не удалось проверить достижимость gitlink из \(имя)")
                }
                достижим = достижим || проверка.код == 0
            }
            guard достижим else { throw отказ("Gitlink недостижим из refs \(имя)") }
        }
        guard try gitУспешноFD([
            "status", "--porcelain=v1", "--untracked-files=all",
        ], в: stagingFD).данные.isEmpty else {
            throw отказ("Staging зависимости имеет локальные изменения")
        }
        let flags = try gitУспешноFD(["ls-files", "-v", "-z"], в: stagingFD).данные
        for запись in flags.split(separator: 0) where !запись.isEmpty {
            guard запись.first == Character("H").asciiValue else {
                throw отказ("Индекс staging содержит скрывающий флаг")
            }
        }
        try потребоватьОтсутствиеAlternates(stagingFD)
    }

    private static func потребоватьОтсутствиеAlternates(_ stagingFD: Int32) throws {
        let adminFD = ".git".withCString {
            openat(stagingFD, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard adminFD >= 0 else { throw отказ("Не удалось открыть .git для alternates") }
        defer { close(adminFD) }
        try потребоватьОтсутствиеAlternatesAdmin(adminFD)
    }

    private static func потребоватьОтсутствиеAlternatesAdmin(_ adminFD: Int32) throws {
        var текущий = dup(adminFD)
        guard текущий >= 0 else { throw отказ("Не удалось удержать admin для alternates") }
        defer { close(текущий) }
        for компонент in ["objects", "info"] {
            let следующий = компонент.withCString {
                openat(текущий, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            }
            if следующий < 0, компонент == "info", errno == ENOENT { return }
            guard следующий >= 0 else { throw отказ("Структура Git objects небезопасна") }
            close(текущий)
            текущий = следующий
        }
        var сведения = stat()
        let код = "alternates".withCString {
            fstatat(текущий, $0, &сведения, AT_SYMLINK_NOFOLLOW)
        }
        guard код != 0, errno == ENOENT else {
            throw отказ("Git object alternates запрещены")
        }
    }

    private static func gitТекстFD(_ аргументы: [String], в descriptor: Int32) throws -> String {
        try gitУспешноFD(аргументы, в: descriptor).текст
    }

    private static func gitУспешноFD(_ аргументы: [String], в descriptor: Int32) throws
        -> РезультатКоманды
    {
        let результат = try gitFD(аргументы, в: descriptor)
        guard результат.код == 0 else {
            throw отказ(
                "Fd-anchored Git отказал: \(аргументы.joined(separator: " ")); \(результат.текст)")
        }
        return результат
    }

    private static func gitFD(_ аргументы: [String], в descriptor: Int32) throws
        -> РезультатКоманды
    {
        var actions: posix_spawn_file_actions_t?
        var attributes: posix_spawnattr_t?
        guard posix_spawn_file_actions_init(&actions) == 0 else {
            throw отказ("Не удалось инициализировать fd-anchored spawn")
        }
        defer { posix_spawn_file_actions_destroy(&actions) }
        guard posix_spawnattr_init(&attributes) == 0 else {
            throw отказ("Не удалось инициализировать закрытые spawn attributes")
        }
        defer { posix_spawnattr_destroy(&attributes) }
        guard posix_spawnattr_setflags(
            &attributes, Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0 else {
            throw отказ("Не удалось запретить наследование ambient FD")
        }
        let сменаКаталога: Int32
        if #available(macOS 26.0, *) {
            сменаКаталога = posix_spawn_file_actions_addfchdir(&actions, descriptor)
        } else {
            сменаКаталога = posix_spawn_file_actions_addfchdir_np(&actions, descriptor)
        }
        guard сменаКаталога == 0 else {
            throw отказ("Не удалось закрепить cwd дочернего Git: errno=\(сменаКаталога)")
        }
        var канал = [Int32](repeating: -1, count: 2)
        guard pipe(&канал) == 0 else { throw отказ("Не удалось создать канал Git") }
        let чтение = канал[0]
        let запись = канал[1]
        guard fcntl(чтение, F_SETFD, FD_CLOEXEC) == 0,
              fcntl(запись, F_SETFD, FD_CLOEXEC) == 0 else {
            close(чтение)
            close(запись)
            throw отказ("Не удалось закрыть pipe FD от наследования")
        }
        let действияКанала = [
            posix_spawn_file_actions_addopen(
                &actions, STDIN_FILENO, "/dev/null", O_RDONLY, mode_t(0)),
            posix_spawn_file_actions_addclose(&actions, чтение),
            posix_spawn_file_actions_adddup2(&actions, запись, STDOUT_FILENO),
            posix_spawn_file_actions_adddup2(&actions, запись, STDERR_FILENO),
            posix_spawn_file_actions_addclose(&actions, запись),
        ]
        guard действияКанала.allSatisfy({ $0 == 0 }) else {
            close(чтение)
            close(запись)
            throw отказ("Не удалось настроить канал fd-anchored Git")
        }
        let полныеАргументы = [
            "/usr/bin/git",
            "-c", "core.hooksPath=/dev/null",
            "-c", "core.fsmonitor=false",
            "-c", "advice.detachedHead=false",
        ] + аргументы
        var argv = полныеАргументы.map { strdup($0) }
        argv.append(nil)
        defer { for указатель in argv where указатель != nil { free(указатель) } }
        var окружение = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        окружение["GIT_CONFIG_NOSYSTEM"] = "1"
        окружение["GIT_CONFIG_GLOBAL"] = "/dev/null"
        окружение["GIT_ATTR_NOSYSTEM"] = "1"
        окружение["GIT_NO_REPLACE_OBJECTS"] = "1"
        окружение["GIT_OPTIONAL_LOCKS"] = "0"
        окружение["GIT_TERMINAL_PROMPT"] = "0"
        окружение["LC_ALL"] = "C"
        var envp = окружение.sorted(by: { $0.key < $1.key })
            .map { strdup("\($0.key)=\($0.value)") }
        envp.append(nil)
        defer { for указатель in envp where указатель != nil { free(указатель) } }
        guard argv.dropLast().allSatisfy({ $0 != nil }),
              envp.dropLast().allSatisfy({ $0 != nil }) else {
            close(чтение)
            close(запись)
            throw отказ("Не удалось выделить argv/envp fd-anchored Git")
        }
        var pid: pid_t = 0
        let кодSpawn = argv.withUnsafeMutableBufferPointer { argvBuffer in
            envp.withUnsafeMutableBufferPointer { envBuffer in
                posix_spawn(
                    &pid, "/usr/bin/git", &actions, &attributes,
                    argvBuffer.baseAddress!, envBuffer.baseAddress!)
            }
        }
        close(запись)
        guard кодSpawn == 0 else {
            close(чтение)
            throw отказ("Fd-anchored posix_spawn отказал: errno=\(кодSpawn)")
        }
        var данные = Data()
        var buffer = [UInt8](repeating: 0, count: 8192)
        while true {
            let число = Darwin.read(чтение, &buffer, buffer.count)
            if число < 0, errno == EINTR { continue }
            guard число >= 0 else {
                close(чтение)
                _ = waitpid(pid, nil, 0)
                throw отказ("Чтение вывода fd-anchored Git отказало")
            }
            if число == 0 { break }
            данные.append(contentsOf: buffer.prefix(Int(число)))
        }
        close(чтение)
        var status: Int32 = 0
        while waitpid(pid, &status, 0) < 0 {
            if errno == EINTR { continue }
            throw отказ("waitpid fd-anchored Git отказал")
        }
        guard (status & 0x7f) == 0 else {
            throw отказ("Fd-anchored Git завершён сигналом")
        }
        return РезультатКоманды(код: (status >> 8) & 0xff, данные: данные)
    }

    private static func проверитьГотовуюЗависимостьБезЗаписи(
        _ план: ПланBootstrapЗависимости
    ) throws {
        let компоненты = план.путь.split(separator: "/", omittingEmptySubsequences: false)
        guard компоненты.count == 2 else {
            throw отказ("Готовая dependency требует точный двухкомпонентный путь")
        }
        let граница = try ПриватнаяГраницаBootstrap(gitDir: план.gitDir, создать: false)
        let admin = URL(fileURLWithPath: план.adminGitDir, isDirectory: true)
        guard Data(admin.deletingLastPathComponent().path.utf8)
                == Data(граница.каталог.path.utf8) else {
            throw отказ("Admin готовой dependency вышел за приватную границу")
        }
        let outcome = try JSONDecoder().decode(
            ИсходBootstrapЗависимости.self,
            from: граница.прочитатьПриватныйФайл("outcome.json"))
        guard outcome.схема == схемаИсхода,
              outcome.хэшПлана == (try хэшКаноническогоПлана(план)),
              outcome.состояние == .готова,
              outcome.путь == план.путь,
              outcome.gitlinkOID == план.gitlinkOID,
              outcome.adminGitDir == план.adminGitDir,
              let ожидаемыйХэш = outcome.хэшМатериализации else {
            throw отказ("Готовая dependency не имеет точного подтверждённого outcome")
        }
        let родительЗависимости = try УдержанныйКаталогЗависимостей(
            корень: URL(fileURLWithPath: план.корень, isDirectory: true),
            имяРодителя: String(компоненты[0]))
        let worktreeFD = try родительЗависимости.открытьРебёнка(String(компоненты[1]))
        defer { close(worktreeFD) }
        let adminFD = try граница.дочернийКаталог(
            admin.lastPathComponent, укрепитьСозданный: false)
        defer { close(adminFD) }
        try проверитьGitdirФайлFD(
            worktreeFD, ожидаемыйAdminGitDir: план.adminGitDir)
        try проверитьСыройAdminReadback(adminFD: adminFD, план: план)
        let живойХэш = try ДолговечностьBootstrap.проверитьМатериализациюБезЗаписи(
            adminFD: adminFD, destinationFD: worktreeFD)
        guard живойХэш == ожидаемыйХэш else {
            throw отказ("Готовая dependency изменилась после exact outcome")
        }
        try родительЗависимости.проверитьРебёнка(
            String(компоненты[1]), совпадаетС: worktreeFD)
        try граница.проверитьРебёнка(admin.lastPathComponent, совпадаетС: adminFD)
    }

    private static func разобратьManifest(_ данные: Data) throws -> [ЗаписьSubmodule] {
        guard let текст = String(data: данные, encoding: .utf8) else {
            throw отказ(".gitmodules не является UTF-8")
        }
        var разделы: [(String, [String: [String]])] = []
        var текущий: Int?
        for сырая in текст.split(separator: "\n", omittingEmptySubsequences: false) {
            let строка = String(сырая)
            let trimmed = строка.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(";") { continue }
            if trimmed.hasPrefix("[submodule \"") && trimmed.hasSuffix("\"]") {
                let начало = trimmed.index(trimmed.startIndex, offsetBy: 12)
                let конец = trimmed.index(trimmed.endIndex, offsetBy: -2)
                let имя = String(trimmed[начало..<конец])
                guard !имя.isEmpty else { throw отказ("Пустое имя submodule") }
                разделы.append((имя, [:]))
                текущий = разделы.count - 1
                continue
            }
            guard let номер = текущий, let equal = trimmed.firstIndex(of: "=") else {
                throw отказ(".gitmodules содержит поле вне submodule-раздела")
            }
            let ключ = String(trimmed[..<equal]).trimmingCharacters(in: .whitespaces)
            let значение = String(trimmed[trimmed.index(after: equal)...])
                .trimmingCharacters(in: .whitespaces)
            guard !ключ.isEmpty, !значение.isEmpty else {
                throw отказ(".gitmodules содержит пустой ключ или значение")
            }
            разделы[номер].1[ключ, default: []].append(значение)
        }
        guard Set(разделы.map(\.0)).count == разделы.count else {
            throw отказ("Имя submodule в .gitmodules повторено")
        }
        return try разделы.map { имя, поля in
            for ключ in ["path", "url", "fumUpstream"] {
                guard поля[ключ]?.count == 1 else {
                    throw отказ("Submodule \(имя) требует ровно одно поле \(ключ)")
                }
            }
            return ЗаписьSubmodule(
                имя: имя, путь: поля["path"]![0], origin: поля["url"]![0],
                upstream: поля["fumUpstream"]![0])
        }
    }

    private static func разобратьGitlink(_ данные: Data, путь: String) throws -> String {
        let записи = данные.split(separator: 0).filter { !$0.isEmpty }
        guard записи.count == 1,
              let строка = String(data: Data(записи[0]), encoding: .utf8),
              let tab = строка.firstIndex(of: "\t") else {
            throw отказ("Gitlink должен иметь единственную stage-0 запись")
        }
        let поля = строка[..<tab].split(separator: " ")
        let фактическийПуть = String(строка[строка.index(after: tab)...])
        guard поля.count == 3, поля[0] == "160000", поля[2] == "0",
              Data(фактическийПуть.utf8) == Data(путь.utf8),
              полныйOID(String(поля[1])) else {
            throw отказ("Stage-0 gitlink не совпадает с точным путём, mode или OID")
        }
        return String(поля[1])
    }

    private static func проверитьStageОбычногоФайла(_ данные: Data, путь: String) throws {
        let записи = данные.split(separator: 0).filter { !$0.isEmpty }
        guard записи.count == 1,
              let строка = String(data: Data(записи[0]), encoding: .utf8),
              строка.hasPrefix("100644 "), строка.contains(" 0\t\(путь)") else {
            throw отказ("\(путь) должен быть обычным stage-0 файлом")
        }
    }

    private static func проверитьОтносительныйПуть(_ путь: String) throws {
        let части = путь.split(separator: "/", omittingEmptySubsequences: false)
        guard !путь.isEmpty, !путь.hasPrefix("/"), !путь.contains("\\"),
              !путь.contains("://"),
              части.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0 != ".git" }) else {
            throw отказ("Путь зависимости вышел из локального POSIX-пространства")
        }
    }

    private static func точныйПуть(
        корень: URL,
        относительный: String,
        допускаетсяОтсутствующийФинал: Bool
    ) throws -> URL {
        try проверитьОтносительныйПуть(относительный)
        let части = относительный.split(separator: "/").map(String.init)
        var текущий = корень
        for (номер, часть) in части.enumerated() {
            let последний = номер == части.count - 1
            let имена = try FileManager.default.contentsOfDirectory(atPath: текущий.path)
            guard имена.contains(часть) else {
                if let похожее = имена.first(where: {
                    $0.compare(часть, options: [.caseInsensitive, .literal]) == .orderedSame
                }) {
                    throw отказ("Неверный регистр компонента \(часть); фактически \(похожее)")
                }
                if последний && допускаетсяОтсутствующийФинал {
                    return текущий.appendingPathComponent(часть)
                }
                throw отказ("Компонент пути \(часть) отсутствует")
            }
            текущий.appendPathComponent(часть)
            try запретитьСимволическуюСсылку(текущий)
            if !последний {
                var каталог: ObjCBool = false
                guard FileManager.default.fileExists(atPath: текущий.path, isDirectory: &каталог),
                      каталог.boolValue else { throw отказ("Промежуточный компонент не каталог") }
            }
        }
        let стандартный = текущий.path
        guard находитсяВнутри(стандартный, корень: корень.path) else {
            throw отказ("Путь разрешается за пределы checkout")
        }
        return текущий
    }

    private static func запретитьСимволическуюСсылку(_ путь: URL) throws {
        var сведения = stat()
        guard lstat(путь.path, &сведения) == 0 else {
            throw отказ("Не удалось прочитать компонент пути")
        }
        guard (сведения.st_mode & S_IFMT) != S_IFLNK else {
            throw отказ("Путь содержит символическую ссылку")
        }
    }

    private static func физическийКаталог(_ путь: URL) throws -> URL {
        guard let resolved = realpath(путь.path, nil) else {
            throw отказ("Физический каталог недоступен")
        }
        defer { free(resolved) }
        let результат = URL(fileURLWithPath: String(cString: resolved), isDirectory: true)
        var каталог: ObjCBool = false
        guard FileManager.default.fileExists(atPath: результат.path, isDirectory: &каталог),
              каталог.boolValue else { throw отказ("Физический путь не является каталогом") }
        return результат
    }

    private static func физическийПутьКаталога(_ путь: URL) throws -> String {
        try физическийКаталог(путь).path
    }

    private static func находитсяВнутри(_ путь: String, корень: String) -> Bool {
        let префикс = корень.hasSuffix("/") ? корень : корень + "/"
        return путь == корень || путь.hasPrefix(префикс)
    }

    private static func полныйOID(_ значение: String) -> Bool {
        значение.utf8.count == 40 && значение.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private static func gitТекст(_ аргументы: [String], в каталог: URL) throws -> String {
        try gitУспешно(аргументы, в: каталог).текст
    }

    private static func gitУспешно(_ аргументы: [String], в каталог: URL) throws -> РезультатКоманды {
        let результат = try git(аргументы, в: каталог)
        guard результат.код == 0 else {
            throw отказ("Git отказал: \(аргументы.joined(separator: " ")); \(результат.текст)")
        }
        return результат
    }

    private static func git(_ аргументы: [String], в каталог: URL) throws -> РезультатКоманды {
        let процесс = Process()
        let поток = Pipe()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = [
            "-c", "core.hooksPath=/dev/null",
            "-c", "core.fsmonitor=false",
            "-c", "advice.detachedHead=false",
        ] + аргументы
        процесс.currentDirectoryURL = каталог
        процесс.standardOutput = поток
        процесс.standardError = поток
        var окружение = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("GIT_") }
        окружение["GIT_CONFIG_NOSYSTEM"] = "1"
        окружение["GIT_CONFIG_GLOBAL"] = "/dev/null"
        окружение["GIT_ATTR_NOSYSTEM"] = "1"
        окружение["GIT_NO_REPLACE_OBJECTS"] = "1"
        окружение["GIT_OPTIONAL_LOCKS"] = "0"
        окружение["GIT_TERMINAL_PROMPT"] = "0"
        окружение["LC_ALL"] = "C"
        процесс.environment = окружение
        try процесс.run()
        let данные = поток.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard процесс.terminationReason == .exit else {
            throw отказ("Git завершён сигналом")
        }
        return РезультатКоманды(код: процесс.terminationStatus, данные: данные)
    }

    private static func хэшКаноническогоПлана(_ план: ПланBootstrapЗависимости) throws -> String {
        sha256(try каноническиеДанные(план))
    }

    private static func sha256(_ данные: Data) -> String {
        "sha256:" + SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
    }

    private static func каноническиеДанные<T: Encodable>(_ значение: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(значение)
    }

    private static func отказ(_ пояснение: String) -> ОтказBootstrapЗависимости {
        .отказ(пояснение)
    }
}
