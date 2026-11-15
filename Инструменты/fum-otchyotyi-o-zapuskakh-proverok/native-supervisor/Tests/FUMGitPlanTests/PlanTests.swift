import Testing
@testable import FUMGitPlan

@Test func полныйПланSynthetic() throws {
    let p = try GitDiffPlan.workingTree(root: "/tmp/project", session: "Журнал/задача", settings: .init(home: nil, global: "/dev/null", system: false))
    #expect(p.argv == ["/bin/sh", "-c", "ulimit -SHu 0 && exec \"$@\"", "fum-git", "/usr/bin/git", "-C", "/tmp/project", "--no-pager", "-c", "core.fsmonitor=false", "--work-tree=/tmp/project", "diff", "--binary", "--no-ext-diff", "--no-textconv", "--ignore-submodules=dirty", "--", ".", ":(exclude)Журнал/задача/отчёт.md", ":(exclude)Журнал/задача/материалы/запуски-проверок", ":(exclude)Журнал/задача/материалы/запуски-проверок/**", ":(top,exclude,literal)Proyekcii", ":(top,exclude,glob)Proyekcii/**"])
    #expect(p.environment == ["PATH":"/bin:/usr/bin", "LC_ALL":"C", "GIT_OPTIONAL_LOCKS":"0", "GIT_NO_LAZY_FETCH":"1", "GIT_NO_REPLACE_OBJECTS":"1", "GIT_CONFIG_GLOBAL":"/dev/null", "GIT_CONFIG_NOSYSTEM":"1", "GIT_ATTR_NOSYSTEM":"1", "GIT_ALLOW_PROTOCOL":""])
    #expect(p.stdin == .null && p.stdout == .pipe && p.stderr == .pipe && p.inheritsWorkingDirectory && p.maximumSeconds == 30)
    #expect(p.admission == .unknown)
}
@Test func явныеИсточникиНастроек() throws {
    let p = try GitDiffPlan.workingTree(root:"/tmp/p",session:"Журнал/с",settings:.init(home:"/Users/example",global:nil,system:true))
    #expect(p.environment == ["PATH":"/bin:/usr/bin", "LC_ALL":"C", "GIT_OPTIONAL_LOCKS":"0", "GIT_NO_LAZY_FETCH":"1", "GIT_NO_REPLACE_OBJECTS":"1", "HOME":"/Users/example", "GIT_ALLOW_PROTOCOL":""])
    let q = try GitDiffPlan.workingTree(root:"/",session:"Журнал/с",settings:.init(home:nil,global:nil,system:false))
    #expect(q.environment["GIT_CONFIG_GLOBAL"] == "/dev/null")
    #expect(q.environment["GIT_CONFIG_NOSYSTEM"] == "1")
    #expect(q.argv.contains("--work-tree=/"))
}
@Test func неканоническиеПутиОтклоняются() {
    for root in ["relative", "/tmp//p", "/tmp/../p", "/tmp/p/", "/tmp/./p", "/tmp/\0p"] {
        #expect(throws: GitPlanError.self) { try GitDiffPlan.workingTree(root:root,session:"Журнал/с",settings:.init(home:nil,global:nil,system:false)) }
    }
    for session in ["", "/абсолютный", "a//b", "a/../b", "a/./b", "a/", "a/\0b"] {
        #expect(throws: GitPlanError.self) { try GitDiffPlan.workingTree(root:"/tmp/p",session:session,settings:.init(home:nil,global:nil,system:false)) }
    }
    for bad in ["relative", "/tmp/../x", "/tmp/x/", "/tmp/\0x"] {
        #expect(throws: GitPlanError.self) { try GitDiffPlan.workingTree(root:"/tmp/p",session:"Журнал/с",settings:.init(home:bad,global:nil,system:false)) }
        #expect(throws: GitPlanError.self) { try GitDiffPlan.workingTree(root:"/tmp/p",session:"Журнал/с",settings:.init(home:nil,global:bad,system:false)) }
    }
}

@Test func буквальныеАргументыИОбеНастройки() throws {
    let root = "/tmp/a b;$(echo x)"
    let p = try GitDiffPlan.workingTree(root:root,session:"Журнал/сложное имя",settings:.init(home:"/Users/example",global:"/tmp/global config",system:true))
    #expect(p.argv[6] == root)
    #expect(p.argv[10] == "--work-tree=" + root)
    #expect(p.argv[18] == ":(exclude)Журнал/сложное имя/отчёт.md")
    #expect(p.environment["HOME"] == "/Users/example")
    #expect(p.environment["GIT_CONFIG_GLOBAL"] == "/tmp/global config")
    #expect(p.environment["GIT_CONFIG_NOSYSTEM"] == nil)
    #expect(p.environment["GIT_ATTR_NOSYSTEM"] == nil)
    #expect(p.admission == .unknown)
}
@Test func ограничениеСрока() throws {
    let p = try GitDiffPlan.workingTree(root:"/tmp/p",session:"Журнал/с",settings:.init(home:nil,global:nil,system:false))
    #expect(try p.timeout(remaining:nil) == 30)
    #expect(try p.timeout(remaining:45) == 30)
    #expect(try p.timeout(remaining:1.25) == 1.25)
    for bad in [0.0, -1.0, Double.nan, Double.infinity, -Double.infinity] {
        #expect(throws: GitPlanError.self) { try p.timeout(remaining:bad) }
    }
}
@Test func исходИТекущийСрок() throws {
    let p = try GitDiffPlan.workingTree(root:"/tmp/p",session:"Журнал/с",settings:.init(home:nil,global:nil,system:false))
    #expect(p.acceptsResult(exitStatus:0,stderr:[],remaining:nil))
    #expect(p.acceptsResult(exitStatus:0,stderr:[],remaining:0.01))
    #expect(!p.acceptsResult(exitStatus:1,stderr:[],remaining:nil))
    #expect(!p.acceptsResult(exitStatus:0,stderr:[1],remaining:nil))
    for bad in [0.0, -1.0, Double.nan, Double.infinity, -Double.infinity] {
        #expect(!p.acceptsResult(exitStatus:0,stderr:[],remaining:bad))
    }
    #expect(p.admission == .unknown)
}
