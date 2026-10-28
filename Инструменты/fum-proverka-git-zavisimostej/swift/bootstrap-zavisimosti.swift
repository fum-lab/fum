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
    private static let схемаИсхода = "fum.bootstrap-git-zavisimosti-outcome.1"

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

        let destination = try точныйПуть(
            корень: корень, относительный: путь, допускаетсяОтсутствующийФинал: true)
        let состояние: СостояниеBootstrapЗависимости
        if FileManager.default.fileExists(atPath: destination.path) {
            let содержимое = try FileManager.default.contentsOfDirectory(atPath: destination.path)
            if содержимое.isEmpty {
                состояние = .отсутствует
            } else {
                try проверитьГотовуюЗависимость(
                    destination: destination, adminGitDir: adminGitDir,
                    origin: запись.origin, upstream: запись.upstream, gitlink: gitlink)
                состояние = .готова
            }
        } else {
            состояние = .отсутствует
        }
        let scopedStatus = try gitУспешно(
            ["status", "--porcelain=v1", "--untracked-files=all", "--", ".gitmodules", путь],
            в: корень).данные
        guard scopedStatus.isEmpty else {
            throw отказ("Регистрация или materialization зависимости имеет локальный дрейф")
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
        наблюдатель: (ЭтапДолговечностиBootstrap) -> Void
    ) throws -> ИсходBootstrapЗависимости {
        guard план.схема == схемаПлана, план.состояние == .отсутствует else {
            throw отказ("Apply разрешён только для проверенного отсутствующего пути")
        }
        let свежий = try построитьПлан(
            корень: URL(fileURLWithPath: план.корень, isDirectory: true), путь: план.путь)
        guard свежий == план else { throw отказ("План bootstrap изменился до применения") }
        let граница = try ПриватнаяГраницаBootstrap(gitDir: план.gitDir, создать: true)
        let имяКвитанции = try граница.имяФайла(квитанция)
        let хэшПлана = try хэшКаноническогоПлана(план)
        let намерение = ИсходBootstrapЗависимости(
            схема: схемаИсхода, хэшПлана: хэшПлана, состояние: .намерение,
            путь: план.путь, gitlinkOID: план.gitlinkOID,
            adminGitDir: план.adminGitDir, пояснение: nil)
        try граница.записатьЭксклюзивно(
            try каноническиеДанные(намерение), имя: имяКвитанции)
        наблюдатель(.намерениеСинхронизировано)

        var материализацияДолговечна = false
        do {
            let destination = URL(fileURLWithPath: план.корень, isDirectory: true)
                .appendingPathComponent(план.путь, isDirectory: true)
            let admin = URL(fileURLWithPath: план.adminGitDir, isDirectory: true)
            guard Data(admin.deletingLastPathComponent().path.utf8)
                    == Data(граница.каталог.path.utf8) else {
                throw отказ("Admin Gitdir не является прямым ребёнком приватной границы")
            }
            if FileManager.default.fileExists(atPath: destination.path) {
                guard try FileManager.default.contentsOfDirectory(atPath: destination.path).isEmpty else {
                    throw отказ("Назначение перестало быть пустым после intent")
                }
            }
            guard try граница.ребёнокОтсутствует(admin.lastPathComponent) else {
                throw отказ("Admin Gitdir появился после intent")
            }
            _ = try gitУспешно([
                "-c", "protocol.file.allow=always",
                "clone", "--quiet", "--no-checkout", "--no-recurse-submodules",
                "--separate-git-dir", admin.path, план.originURL, destination.path,
            ], в: URL(fileURLWithPath: план.корень, isDirectory: true))
            _ = try gitУспешно(["remote", "add", "upstream", план.upstreamURL], в: destination)
            _ = try gitУспешно(["fetch", "--quiet", "--prune", "upstream"], в: destination)
            _ = try gitУспешно([
                "checkout", "--quiet", "--detach", "--no-recurse-submodules", план.gitlinkOID,
            ], в: destination)
            let adminFD = try граница.дочернийКаталог(
                admin.lastPathComponent, укрепитьСозданный: true)
            guard close(adminFD) == 0 else {
                throw отказ("close admin Gitdir отказал")
            }
            try проверитьГотовуюЗависимость(
                destination: destination, adminGitDir: план.adminGitDir,
                origin: план.originURL, upstream: план.upstreamURL, gitlink: план.gitlinkOID)
            try ДолговечностьBootstrap.синхронизироватьМатериализацию(
                adminGitDir: admin, destination: destination, граница: граница)
            материализацияДолговечна = true
            наблюдатель(.материализацияСинхронизирована)
            let исход = ИсходBootstrapЗависимости(
                схема: схемаИсхода, хэшПлана: хэшПлана, состояние: .готова,
                путь: план.путь, gitlinkOID: план.gitlinkOID,
                adminGitDir: план.adminGitDir, пояснение: nil)
            try граница.заменитьАтомарно(
                try каноническиеДанные(исход), имя: имяКвитанции)
            наблюдатель(.исходСинхронизирован)
            return исход
        } catch {
            if материализацияДолговечна {
                throw отказ(
                    "Материализация долговечна, но terminal outcome неизвестен; "
                    + "intent сохранён, автоматический повтор запрещён: \(error)")
            }
            let исход = ИсходBootstrapЗависимости(
                схема: схемаИсхода, хэшПлана: хэшПлана, состояние: .отказ,
                путь: план.путь, gitlinkOID: план.gitlinkOID,
                adminGitDir: план.adminGitDir, пояснение: String(describing: error))
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
        let исход = try JSONDecoder().decode(
            ИсходBootstrapЗависимости.self,
            from: граница.прочитатьПриватныйФайл(имяКвитанции))
        guard исход.схема == схемаИсхода,
              исход.хэшПлана == (try хэшКаноническогоПлана(план)),
              исход.состояние == .готова,
              исход.путь == план.путь,
              исход.gitlinkOID == план.gitlinkOID,
              исход.adminGitDir == план.adminGitDir else {
            throw отказ("Outcome не подтверждает успешное применение точного плана")
        }
        let свежий = try построитьПлан(
            корень: URL(fileURLWithPath: план.корень, isDirectory: true), путь: план.путь)
        guard свежий.состояние == .готова,
              свежий.корень == план.корень,
              свежий.head == план.head,
              свежий.ref == план.ref,
              свежий.путь == план.путь,
              свежий.originURL == план.originURL,
              свежий.upstreamURL == план.upstreamURL,
              свежий.gitlinkOID == план.gitlinkOID,
              свежий.gitDir == план.gitDir,
              свежий.commonGitDir == план.commonGitDir,
              свежий.adminGitDir == план.adminGitDir else {
            throw отказ("Живой readback не совпадает с применённым планом")
        }
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

    private static func проверитьГотовуюЗависимость(
        destination: URL,
        adminGitDir: String,
        origin: String,
        upstream: String,
        gitlink: String
    ) throws {
        let admin = URL(fileURLWithPath: adminGitDir, isDirectory: true)
        let каталогBootstrap = admin.deletingLastPathComponent()
        guard каталогBootstrap.lastPathComponent == "dependency-bootstrap" else {
            throw отказ("Admin Gitdir находится вне точного каталога bootstrap")
        }
        let граница = try ПриватнаяГраницаBootstrap(
            gitDir: каталогBootstrap.deletingLastPathComponent().path,
            создать: false)
        guard Data(граница.каталог.path.utf8) == Data(каталогBootstrap.path.utf8) else {
            throw отказ("Физическая граница admin Gitdir не совпадает")
        }
        let adminFD = try граница.дочернийКаталог(
            admin.lastPathComponent, укрепитьСозданный: false)
        guard close(adminFD) == 0 else { throw отказ("close admin Gitdir отказал") }
        let dotGit = destination.appendingPathComponent(".git")
        try потребоватьОбычныйФайлБезСсылки(dotGit)
        let declared = String(decoding: try Data(contentsOf: dotGit), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard declared == "gitdir: \(adminGitDir)" else {
            throw отказ(".git зависимости не указывает на отдельный проверенный admin Gitdir")
        }
        let actualAdmin = try gitТекст(
            ["rev-parse", "--path-format=absolute", "--absolute-git-dir"], в: destination)
        guard Data(actualAdmin.utf8) == Data(adminGitDir.utf8) else {
            throw отказ("Git разрешил иной admin Gitdir зависимости")
        }
        guard try gitТекст(["rev-parse", "--is-shallow-repository"], в: destination) == "false" else {
            throw отказ("Shallow materialization запрещена")
        }
        guard try gitТекст(["rev-parse", "HEAD"], в: destination) == gitlink else {
            throw отказ("HEAD зависимости не совпадает с gitlink")
        }
        let symbolic = try git(["symbolic-ref", "-q", "HEAD"], в: destination)
        guard symbolic.код == 1 else { throw отказ("HEAD зависимости должен быть detached") }
        let remotes = try gitТекст(["remote"], в: destination).split(separator: "\n").map(String.init)
        guard remotes.sorted() == ["origin", "upstream"] else {
            throw отказ("Набор remote зависимости не точен")
        }
        for (имя, url) in [("origin", origin), ("upstream", upstream)] {
            guard try gitТекст(["remote", "get-url", имя], в: destination) == url else {
                throw отказ("URL remote \(имя) не совпадает с manifest")
            }
            let refspec = try gitТекст(
                ["config", "--get-all", "remote.\(имя).fetch"], в: destination)
            guard refspec == "+refs/heads/*:refs/remotes/\(имя)/*" else {
                throw отказ("Fetch refspec remote \(имя) не точен")
            }
            let вершины = try gitТекст([
                "for-each-ref", "--format=%(objectname)", "refs/remotes/\(имя)/",
            ], в: destination).split(separator: "\n").map(String.init)
            var достижим = false
            for вершина in Set(вершины) {
                let проверка = try git(["merge-base", "--is-ancestor", gitlink, вершина], в: destination)
                guard проверка.код == 0 || проверка.код == 1 else {
                    throw отказ("Не удалось проверить достижимость gitlink из \(имя)")
                }
                достижим = достижим || проверка.код == 0
            }
            guard достижим else { throw отказ("Gitlink недостижим из полученных refs \(имя)") }
        }
        guard try gitУспешно([
            "status", "--porcelain=v1", "--untracked-files=all",
        ], в: destination).данные.isEmpty else {
            throw отказ("Materialization зависимости имеет локальные изменения")
        }
        let flags = try gitУспешно(["ls-files", "-v", "-z"], в: destination).данные
        for запись in flags.split(separator: 0) where !запись.isEmpty {
            guard запись.first == Character("H").asciiValue else {
                throw отказ("Индекс зависимости содержит скрывающий флаг")
            }
        }
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

    private static func потребоватьОбычныйФайлБезСсылки(_ путь: URL) throws {
        try запретитьСимволическуюСсылку(путь)
        var сведения = stat()
        guard lstat(путь.path, &сведения) == 0,
              (сведения.st_mode & S_IFMT) == S_IFREG else {
            throw отказ("Ожидался обычный файл")
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
