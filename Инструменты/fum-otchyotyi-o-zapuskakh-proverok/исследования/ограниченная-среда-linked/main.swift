import Foundation
import Darwin
import CryptoKit
func строка(_ s: String) { let d=Data((s+"\n").utf8); _ = d.withUnsafeBytes { Darwin.write(STDOUT_FILENO,$0.baseAddress,$0.count) } }
func отказ(_ s: String) -> Never { строка("HOLD " + s); Darwin._exit(2) }
func хэш(_ d: Data) -> String { SHA256.hash(data:d).map { String(format:"%02x",$0) }.joined() }
struct Метка: Equatable {
    let dev: dev_t; let inode: ino_t; let mode: mode_t; let size: off_t; let mt: timespec; let ct: timespec
    static func ==(a: Self,b: Self)->Bool { a.dev==b.dev && a.inode==b.inode && a.mode==b.mode && a.size==b.size && a.mt.tv_sec==b.mt.tv_sec && a.mt.tv_nsec==b.mt.tv_nsec && a.ct.tv_sec==b.ct.tv_sec && a.ct.tv_nsec==b.ct.tv_nsec }
}
func метка(_ path: String, _ тип: mode_t, _ владелец: uid_t) -> Метка? {
    var s=stat(); guard lstat(path,&s)==0 && s.st_mode & mode_t(S_IFMT)==тип && s.st_uid==владелец else { return nil }
    return Метка(dev:s.st_dev,inode:s.st_ino,mode:s.st_mode,size:s.st_size,mt:s.st_mtimespec,ct:s.st_ctimespec)
}
// Открытые дескрипторы удерживаются до конца синтетического процесса.
// Они обнаруживают подмену имени, но Git пока открывает пути заново при exec.
struct УдержанныйФайл { let fd: Int32; let путь: String; let метка: Метка }
func меткаДескриптора(_ fd: Int32) -> Метка? {
    var s=stat(); guard fstat(fd,&s)==0 && s.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG) && s.st_nlink == 1 else { return nil }
    return Метка(dev:s.st_dev,inode:s.st_ino,mode:s.st_mode,size:s.st_size,mt:s.st_mtimespec,ct:s.st_ctimespec)
}
func удержать(_ путь:String,_ ожидаемая:Метка)->УдержанныйФайл? {
    let fd=open(путь,O_RDONLY|O_NOFOLLOW|O_CLOEXEC)
    guard fd >= 0, let фактическая=меткаДескриптора(fd), фактическая==ожидаемая else { return nil }
    return УдержанныйФайл(fd:fd,путь:путь,метка:ожидаемая)
}
func сверить(_ удержания:[УдержанныйФайл])->Bool {
    for объект in удержания {
        let uid: uid_t = объект.путь == git ? 0 : geteuid()
        guard меткаДескриптора(объект.fd)==объект.метка,
              метка(объект.путь,mode_t(S_IFREG),uid)==объект.метка else { return false }
    }
    return true
}
// Цепь ограничена синтетической структурой. openat не делает Git-потребитель дескрипторным.
struct УдержанныйКаталог { let fd:Int32; let родитель:Int32?; let имя:String; let метка:Метка }
func меткаКаталога(_ s:stat)->Метка? {
    guard s.st_mode & mode_t(S_IFMT)==mode_t(S_IFDIR), s.st_uid==geteuid() else { return nil }
    return Метка(dev:s.st_dev,inode:s.st_ino,mode:s.st_mode,size:s.st_size,mt:s.st_mtimespec,ct:s.st_ctimespec)
}
func взятьКаталог(_ родитель:Int32?,_ имя:String,_ ожидаемая:Метка)->УдержанныйКаталог? {
    let flags=O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC
    let fd = родитель.map { openat($0,имя,flags) } ?? open(имя,flags)
    var s=stat()
    guard fd >= 0, fstat(fd,&s)==0, меткаКаталога(s)==ожидаемая else { return nil }
    return УдержанныйКаталог(fd:fd,родитель:родитель,имя:имя,метка:ожидаемая)
}
func сверитьКаталоги(_ каталоги:[УдержанныйКаталог])->Bool {
    for каталог in каталоги {
        var открытый=stat(), поИмени=stat()
        guard fstat(каталог.fd,&открытый)==0, меткаКаталога(открытый)==каталог.метка else { return false }
        let итог=каталог.родитель.map { fstatat($0,каталог.имя,&поИмени,AT_SYMLINK_NOFOLLOW) } ?? lstat(каталог.имя,&поИмени)
        guard итог==0, меткаКаталога(поИмени)==каталог.метка else { return false }
    }
    return true
}
func отсутствует(_ p:String)->Bool { var s=stat(); return lstat(p,&s) == -1 && errno == ENOENT }
func данные(_ p:String)->Data? { try? Data(contentsOf:URL(fileURLWithPath:p)) }
struct Снимок: Equatable { let метки:[Метка]; let индексХэш:String; let gitМетка:Метка }
let git = CommandLine.arguments.count == 5 ? CommandLine.arguments[3] : ""
let ожидаемыйGit = CommandLine.arguments.count == 5 ? CommandLine.arguments[4] : ""
let commonConfig=Data("[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = false\n\tlogallrefupdates = true\n\tignorecase = true\n\tprecomposeunicode = true\n[extensions]\n\tworktreeConfig = true\n".utf8)
func снимок(_ base:String)->Снимок? {
    guard base.hasPrefix("/"), !base.split(separator:"/").contains(".."), URL(fileURLWithPath: base).standardizedFileURL.resolvingSymlinksInPath().path == base, git.hasPrefix("/"), !git.split(separator:"/").contains(".."), ожидаемыйGit.count == 64 else { return nil }
    let work=base+"/work", common=base+"/repo/.git", gitdir=common+"/worktrees/work"
    let dirs=[base,base+"/repo",common,common+"/info",common+"/worktrees",gitdir,work,work+"/nested"]
    let files=[work+"/.git",gitdir+"/gitdir",gitdir+"/commondir",gitdir+"/HEAD",gitdir+"/index",gitdir+"/config.worktree",common+"/config",work+"/fixture.txt"]
    var метки:[Метка]=[]
    for путь in dirs { guard let m=метка(путь,mode_t(S_IFDIR),geteuid()) else { return nil }; метки.append(m) }
    for путь in files { guard let m=метка(путь,mode_t(S_IFREG),geteuid()) else { return nil }; метки.append(m) }
    guard let имена=try? FileManager.default.contentsOfDirectory(atPath:work), Set(имена)==Set([".git","nested","fixture.txt"]),
          let вложенные=try? FileManager.default.contentsOfDirectory(atPath:work+"/nested"), вложенные.isEmpty,
          отсутствует(common+"/info/attributes"), отсутствует(gitdir+"/info/attributes"),
          данные(work+"/.git")==Data(("gitdir: "+gitdir+"\n").utf8),
          данные(gitdir+"/gitdir")==Data((work+"/.git\n").utf8), данные(gitdir+"/commondir")==Data("../..\n".utf8),
          данные(common+"/config")==commonConfig, данные(gitdir+"/config.worktree")==Data("[fixture]\n\tmarker = benign\n".utf8),
          данные(work+"/fixture.txt")==Data("changed\n".utf8), let index=данные(gitdir+"/index"), !index.isEmpty,
          let gitМ=метка(git,mode_t(S_IFREG),0), gitМ.mode & 0o022 == 0, let gitBytes=данные(git), хэш(gitBytes)==ожидаемыйGit else { return nil }
    return Снимок(метки:метки,индексХэш:хэш(index),gitМетка:gitМ)
}
guard CommandLine.arguments.count==5 else { отказ("аргументы") }
let base=CommandLine.arguments[1], режим=CommandLine.arguments[2]
guard ["positive","worktree","include","attributes","nested","swap-config","swap-index","swap-work","swap-gitdir"].contains(режим) else { отказ("режим") }
guard let первый=снимок(base) else {
    if ["worktree","include","attributes","nested"].contains(режим) { строка("REJECT до consumer режим=\(режим) вызовы=0"); Darwin._exit(0) }
    отказ("неподтверждённый профиль")
}
let work=base+"/work", common=base+"/repo/.git", gitdir=common+"/worktrees/work"
let каталогПути:[(Int?,String)] = [(nil,base),(0,"repo"),(1,".git"),(2,"info"),(2,"worktrees"),(4,"work"),(0,"work"),(6,"nested")]
var каталоги:[УдержанныйКаталог]=[]
for (номер,(родитель,имя)) in каталогПути.enumerated() {
    let parentFD=родитель.map { каталоги[$0].fd }
    guard let каталог=взятьКаталог(parentFD,имя,первый.метки[номер]) else { отказ("цепь каталогов UNKNOWN") }
    каталоги.append(каталог)
}
guard каталоги.count==8 && сверитьКаталоги(каталоги) else { отказ("сверка каталогов") }
if режим == "swap-work" || режим == "swap-gitdir" {
    let путь = режим == "swap-work" ? work : gitdir
    guard rename(путь,путь+".fixture-saved")==0, mkdir(путь,0o700)==0 else { отказ("подмена каталога UNKNOWN") }
    guard !сверитьКаталоги(каталоги) else { отказ("подмена каталога не обнаружена") }
    строка("REJECT цепь режим=\(режим) вызовы=0"); Darwin._exit(0)
}
let источники = [work+"/.git",gitdir+"/gitdir",gitdir+"/commondir",gitdir+"/HEAD",gitdir+"/index",gitdir+"/config.worktree",common+"/config",work+"/fixture.txt",git]
let исходныеМетки = Array(первый.метки.suffix(8)) + [первый.gitМетка]
var удержания:[УдержанныйФайл]=[]
for (путь,ожидаемая) in zip(источники,исходныеМетки) {
    guard let объект=удержать(путь,ожидаемая) else { отказ("удержание UNKNOWN") }
    удержания.append(объект)
}
guard удержания.count==9 && сверить(удержания) else { отказ("удержание до запуска") }
if режим == "swap-config" || режим == "swap-index" {
    let путь = режим == "swap-config" ? common+"/config" : gitdir+"/index"
    guard let исходные=данные(путь) else { отказ("чтение подмены") }
    let временный=путь+".fixture-swap"
    let fd=open(временный,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0o600)
    guard fd>=0, исходные.withUnsafeBytes({ Darwin.write(fd,$0.baseAddress,$0.count) })==исходные.count,
          fsync(fd)==0, close(fd)==0, rename(временный,путь)==0 else { отказ("подмена UNKNOWN") }
    guard !сверить(удержания) else { отказ("подмена не обнаружена") }
    строка("REJECT удержание режим=\(режим) вызовы=0"); Darwin._exit(0)
}
guard режим == "positive", let второй=снимок(base), первый==второй && сверитьКаталоги(каталоги) && сверить(удержания) else { отказ("дрейф до запуска") }
let root=base+"/work", p=Process(), out=Pipe(), err=Pipe()
p.executableURL=URL(fileURLWithPath:git)
p.arguments=["-C",root,"-c","core.fsmonitor=false","--work-tree="+root,"diff","--binary","--no-ext-diff","--no-textconv","--ignore-submodules=dirty","--",".",":(exclude)Журнал/фикстура/отчёт.md",":(exclude)Журнал/фикстура/материалы/запуски-проверок",":(exclude)Журнал/фикстура/материалы/запуски-проверок/**",":(top,exclude,literal)Proyekcii",":(top,exclude,glob)Proyekcii/**"]
p.environment=["PATH":"/usr/bin:/bin","LC_ALL":"C","GIT_CONFIG_NOSYSTEM":"1","GIT_CONFIG_GLOBAL":"/dev/null","GIT_ATTR_NOSYSTEM":"1","GIT_OPTIONAL_LOCKS":"0","GIT_NO_LAZY_FETCH":"1","GIT_NO_REPLACE_OBJECTS":"1","GIT_ALLOW_PROTOCOL":""]
p.standardOutput=out;p.standardError=err
do { try p.run() } catch { отказ("старт UNKNOWN") }
let данныеВывода=out.fileHandleForReading.readDataToEndOfFile(), ошибки=err.fileHandleForReading.readDataToEndOfFile();p.waitUntilExit()
let ожидается=Data("diff --git a/fixture.txt b/fixture.txt\nindex 4b48dee..5ea2ed4 100644\n--- a/fixture.txt\n+++ b/fixture.txt\n@@ -1 +1 @@\n-original\n+changed\n".utf8)
guard p.terminationReason == .exit && p.terminationStatus==0 && ошибки.isEmpty && данныеВывода==ожидается else { отказ("diff") }
guard let третий=снимок(base), третий==второй && сверитьКаталоги(каталоги) && сверить(удержания) else { отказ("дрейф после") }
строка("PASS linked fixture diff; consumer=1; exact bytes; held files and directories pre/post equal")
