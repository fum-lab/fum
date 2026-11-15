public enum GitPlanError: Error, Equatable, Sendable {
    case invalidRoot
    case invalidSession
    case invalidSettingPath
    case invalidDeadline
}

public struct GitSettings: Equatable, Sendable {
    public let home: String?
    public let global: String?
    public let system: Bool
    public init(home: String?, global: String?, system: Bool) {
        self.home = home
        self.global = global
        self.system = system
    }
}

public enum GitStream: Equatable, Sendable { case null, pipe }
public enum GitAdmission: Equatable, Sendable { case unknown }

public struct GitDiffPlan: Equatable, Sendable {
    public let argv: [String]
    public let environment: [String: String]
    public let stdin: GitStream
    public let stdout: GitStream
    public let stderr: GitStream
    public let inheritsWorkingDirectory: Bool
    public let maximumSeconds: Int
    public let admission: GitAdmission

    private static func canonicalAbsolute(_ value: String) -> Bool {
        guard value.hasPrefix("/"), !value.utf8.contains(0) else { return false }
        if value == "/" { return true }
        guard !value.hasSuffix("/"), !value.contains("//") else { return false }
        return value.split(separator: "/").allSatisfy { $0 != "." && $0 != ".." }
    }

    private static func canonicalRelative(_ value: String) -> Bool {
        guard !value.isEmpty, !value.hasPrefix("/"), !value.hasSuffix("/"),
              !value.contains("//"), !value.utf8.contains(0) else { return false }
        return value.split(separator: "/").allSatisfy { $0 != "." && $0 != ".." }
    }

    // Remaining time is supplied by the caller from a fresh monotonic reading.
    public func timeout(remaining: Double?) throws -> Double {
        guard let remaining else { return Double(maximumSeconds) }
        guard remaining.isFinite && remaining > 0 else { throw GitPlanError.invalidDeadline }
        return min(Double(maximumSeconds), remaining)
    }

    // This is a result predicate, not proof of process identity or execution authority.
    public func acceptsResult(exitStatus: Int32, stderr: [UInt8], remaining: Double?) -> Bool {
        guard exitStatus == 0 && stderr.isEmpty else { return false }
        guard let remaining else { return true }
        return remaining.isFinite && remaining > 0
    }

    // Only constructs a plan: physical path identity and execution authority remain external.
    public static func workingTree(root: String, session: String, settings: GitSettings) throws -> Self {
        guard canonicalAbsolute(root) else { throw GitPlanError.invalidRoot }
        guard canonicalRelative(session) else { throw GitPlanError.invalidSession }
        for path in [settings.home, settings.global].compactMap({ $0 }) {
            guard canonicalAbsolute(path) else { throw GitPlanError.invalidSettingPath }
        }
        let report = session + "/отчёт.md"
        let runs = session + "/материалы/запуски-проверок"
        let argv = ["/bin/sh", "-c", "ulimit -SHu 0 && exec \"$@\"", "fum-git", "/usr/bin/git",
                    "-C", root, "--no-pager", "-c", "core.fsmonitor=false", "--work-tree=" + root,
                    "diff", "--binary", "--no-ext-diff", "--no-textconv", "--ignore-submodules=dirty",
                    "--", ".", ":(exclude)" + report, ":(exclude)" + runs, ":(exclude)" + runs + "/**",
                    ":(top,exclude,literal)Proyekcii", ":(top,exclude,glob)Proyekcii/**"]
        var environment = ["PATH":"/bin:/usr/bin", "GIT_OPTIONAL_LOCKS":"0", "GIT_NO_LAZY_FETCH":"1",
                           "GIT_NO_REPLACE_OBJECTS":"1", "LC_ALL":"C", "GIT_ALLOW_PROTOCOL":""]
        if let home = settings.home { environment["HOME"] = home }
        if let global = settings.global { environment["GIT_CONFIG_GLOBAL"] = global }
        if settings.home == nil && settings.global == nil { environment["GIT_CONFIG_GLOBAL"] = "/dev/null" }
        if !settings.system {
            environment["GIT_CONFIG_NOSYSTEM"] = "1"
            environment["GIT_ATTR_NOSYSTEM"] = "1"
        }
        return Self(argv: argv, environment: environment, stdin: .null, stdout: .pipe, stderr: .pipe,
                    inheritsWorkingDirectory: true, maximumSeconds: 30, admission: .unknown)
    }
}
