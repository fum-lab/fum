import Foundation

// Узкий запуск Git: приватные cwd/state задаёт владелец, Git config не меняется.
let args = CommandLine.arguments
guard args.count >= 6 else {
    fputs("usage: git-private-state REPO PRIVATE_CWD PRIVATE_STATE GH_CONFIG GIT_ARGS...\n", stderr)
    exit(2)
}
let repo = URL(fileURLWithPath: args[1], isDirectory: true).standardizedFileURL
let cwd = URL(fileURLWithPath: args[2], isDirectory: true).standardizedFileURL
let state = URL(fileURLWithPath: args[3], isDirectory: true).standardizedFileURL
let config = URL(fileURLWithPath: args[4], isDirectory: true).standardizedFileURL
func physicalDirectory(_ url: URL) -> Bool {
    var directory: ObjCBool = false
    return url.path.hasPrefix("/") && FileManager.default.fileExists(atPath: url.path, isDirectory: &directory)
        && directory.boolValue && url.resolvingSymlinksInPath().path == url.path
}
func inside(_ child: URL, _ parent: URL) -> Bool {
    child.path == parent.path || parent.path == "/" || child.path.hasPrefix(parent.path + "/")
}
let dirs = [repo, cwd, state, config]
guard dirs.enumerated().allSatisfy({ args[$0.offset + 1].hasPrefix("/")
          && !args[$0.offset + 1].split(separator: "/").contains("..") && physicalDirectory($0.element) }),
      dirs.indices.allSatisfy({ i in dirs.indices.allSatisfy({ j in i == j || !inside(dirs[i], dirs[j]) }) }) else {
    fputs("invalid or overlapping directories\n", stderr)
    exit(2)
}
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
process.currentDirectoryURL = cwd
process.environment = ["PATH": "/usr/bin:/bin:/opt/homebrew/bin", "GH_CONFIG_DIR": config.path,
                       "XDG_STATE_HOME": state.path, "GIT_TERMINAL_PROMPT": "0",
                       "GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1",
                       "FUM_HELPER_CWD": cwd.path]
#if FUM_SYNTHETIC
guard let helper = ProcessInfo.processInfo.environment["FUM_TEST_HELPER"], helper.hasPrefix("/private/tmp/") else {
    fputs("synthetic helper required\n", stderr)
    exit(2)
}
guard helper.range(of: "^[A-Za-z0-9/_-]+$", options: .regularExpression) != nil else { exit(2) }
let helperConfig = "credential.helper=!cd \"$FUM_HELPER_CWD\" && exec " + helper
#else
guard Array(args.dropFirst(5)) == ["ls-remote", "--heads", "https://github.com/fum-lab/fum.git",
                                   "refs/heads/codex/avtory-kommitov"] else {
    fputs("production operation not admitted\n", stderr)
    exit(2)
}
let helperConfig = "credential.helper=!cd \"$FUM_HELPER_CWD\" && exec /opt/homebrew/bin/gh auth git-credential"
#endif
process.arguments = ["-C", repo.path, "-c", "core.hooksPath=/dev/null", "-c", "credential.helper=",
                     "-c", helperConfig] + Array(args.dropFirst(5))
do {
    try process.run()
    process.waitUntilExit()
    exit(process.terminationReason == .exit ? process.terminationStatus : 128 + process.terminationStatus)
} catch {
    fputs("Git launch failed\n", stderr)
    exit(1)
}
