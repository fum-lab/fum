import Foundation
import Darwin
import CryptoKit
func отказ(_ s: String) -> Never { let d=Data(("HOLD "+s+"\n").utf8); _=d.withUnsafeBytes { Darwin.write(STDERR_FILENO,$0.baseAddress,$0.count) }; Darwin._exit(2) }
func требовать(_ v: @autoclosure () -> Bool, _ s: String) { if !v() { отказ(s) } }
func хэш(_ d: Data) -> String { SHA256.hash(data:d).map { String(format:"%02x",$0) }.joined() }
let git = CommandLine.arguments.last ?? ""
let среда = ["PATH":"/usr/bin:/bin","LC_ALL":"C","GIT_CONFIG_NOSYSTEM":"1","GIT_CONFIG_GLOBAL":"/dev/null","GIT_ATTR_NOSYSTEM":"1","GIT_OPTIONAL_LOCKS":"0","GIT_NO_LAZY_FETCH":"1","GIT_NO_REPLACE_OBJECTS":"1"]
func gitВызов(_ repo:String,_ args:[String]) -> Data {
    let p=Process(), out=Pipe(), err=Pipe()
    p.executableURL=URL(fileURLWithPath:git)
    p.arguments=["-C",repo,"-c","core.hooksPath=/dev/null","-c","core.fsmonitor=false"]+args
    p.environment=среда; p.standardOutput=out; p.standardError=err
    do { try p.run() } catch { отказ("старт Git UNKNOWN") }
    let bytes=out.fileHandleForReading.readDataToEndOfFile(), errors=err.fileHandleForReading.readDataToEndOfFile(); p.waitUntilExit()
    требовать(p.terminationReason == .exit && p.terminationStatus==0 && errors.isEmpty && bytes.count <= 4096,"завершение Git")
    return bytes
}
func строка(_ d: Data) -> String { guard let s=String(data:d,encoding:.utf8) else { отказ("utf8") }; return s.trimmingCharacters(in:.newlines) }
func записатьНовый(_ путь:String,_ bytes:Data) {
    let fd=open(путь,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0o600)
    guard fd >= 0 else { отказ("создание UNKNOWN") }
    let число=bytes.withUnsafeBytes { Darwin.write(fd,$0.baseAddress,$0.count) }
    guard число==bytes.count && fsync(fd)==0 && close(fd)==0 else { отказ("запись UNKNOWN") }
}
let событие=Data("event-id=synthetic-1\nposition=1\npayload=synthetic\n".utf8)
func ребёнок(_ base:String,_ режим:String) -> Never {
    let repo=base+"/repo"
    записатьНовый(base+"/intent.DATA",Data(("synthetic-1 "+хэш(событие)+"\n").utf8))
    записатьНовый(repo+"/event.DATA",событие)
    if режим=="before" { Darwin._exit(72) }
    _=gitВызов(repo,["add","--","event.DATA"])
    _=gitВызов(repo,["-c","user.name=Synthetic","-c","user.email=synthetic@example.invalid","commit","--quiet","-m","synthetic event"])
    Darwin._exit(73)
}
func восстановитель(_ base:String,_ исходный:String) -> Never {
    проверитьКаталог(base); проверитьКаталог(base+"/repo"); проверитьКаталог(base+"/repo/.git")
    let repo=base+"/repo", текущий=строка(gitВызов(repo,["rev-parse","HEAD"]))
    требовать(текущий != исходный && строка(gitВызов(repo,["rev-parse","HEAD^"])) == исходный &&
              gitВызов(repo,["diff-tree","--no-commit-id","--name-only","-r","HEAD"]) == Data("event.DATA\n".utf8) &&
              gitВызов(repo,["show","HEAD:event.DATA"]) == событие &&
              строка(gitВызов(repo,["rev-parse","HEAD"])) == текущий,"свидетельство нового процесса")
    let д=Data(("RECOVERED "+текущий+"\n").utf8)
    требовать(д.withUnsafeBytes { Darwin.write(STDOUT_FILENO,$0.baseAddress,$0.count) }==д.count,"ответ восстановителя")
    Darwin._exit(0)
}
func родитель(_ base:String,_ режим:String) {
    проверитьКаталог(base); проверитьКаталог(base+"/repo"); проверитьКаталог(base+"/repo/.git")
    let repo=base+"/repo", исходный=строка(gitВызов(repo,["rev-parse","HEAD"]))
    let p=Process(), out=Pipe(), err=Pipe(); p.executableURL=URL(fileURLWithPath:CommandLine.arguments[0])
    p.arguments=["--child",base,режим,git]; p.environment=среда; p.standardOutput=out; p.standardError=err
    do { try p.run() } catch { отказ("старт child UNKNOWN") }
    let output=out.fileHandleForReading.readDataToEndOfFile(), errors=err.fileHandleForReading.readDataToEndOfFile(); p.waitUntilExit()
    требовать(p.terminationReason == .exit && p.terminationStatus == (режим=="before" ? 72 : 73) && output.isEmpty && errors.isEmpty,"терминал child")
    let intent=try? Data(contentsOf:URL(fileURLWithPath:base+"/intent.DATA"))
    требовать(intent==Data(("synthetic-1 "+хэш(событие)+"\n").utf8),"намерение")
    let текущий=строка(gitВызов(repo,["rev-parse","HEAD"]))
    if режим=="before" {
        требовать(текущий==исходный,"предкоммитный HEAD")
        print("UNKNOWN before commit; effect not replayed")
    } else {
        требовать(текущий != исходный && строка(gitВызов(repo,["rev-parse","HEAD^"]))==исходный,"родитель")
        требовать(gitВызов(repo,["diff-tree","--no-commit-id","--name-only","-r","HEAD"]) == Data("event.DATA\n".utf8),"состав коммита")
        let считано=gitВызов(repo,["show","HEAD:event.DATA"])
        требовать(считано==событие && хэш(считано)==хэш(событие),"байты события")
        let восстановление=Process(), восстановленныйВывод=Pipe(), восстановленныеОшибки=Pipe()
        восстановление.executableURL=URL(fileURLWithPath:CommandLine.arguments[0])
        восстановление.arguments=["--recover",base,исходный,git]; восстановление.environment=среда
        восстановление.standardOutput=восстановленныйВывод; восстановление.standardError=восстановленныеОшибки
        do { try восстановление.run() } catch { отказ("старт восстановителя UNKNOWN") }
        let доказательство=восстановленныйВывод.fileHandleForReading.readDataToEndOfFile()
        let ошибкаВосстановления=восстановленныеОшибки.fileHandleForReading.readDataToEndOfFile()
        восстановление.waitUntilExit()
        требовать(восстановление.terminationReason == .exit && восстановление.terminationStatus==0 &&
                  ошибкаВосстановления.isEmpty && доказательство==Data(("RECOVERED "+текущий+"\n").utf8),
                  "повторный процесс")
        let повторноеЧтение=строка(gitВызов(repo,["rev-parse","HEAD"]))
        требовать(повторноеЧтение==текущий,"без повторного коммита")
        print("RECOVERED in new process; parent and event bytes match; no replay")
    }
}
func проверитьКаталог(_ путь: String) {
    var s=stat()
    требовать(путь.hasPrefix("/") && !путь.split(separator:"/").contains("..") &&
              URL(fileURLWithPath: путь).standardizedFileURL.resolvingSymlinksInPath().path == путь &&
              lstat(путь,&s)==0 && s.st_mode & mode_t(S_IFMT)==mode_t(S_IFDIR) &&
              s.st_uid==geteuid() && s.st_mode & 0o7777 == 0o700,"физический каталог")
}
func соперник(_ путь:String,_ dev:String,_ ino:String,_ ожидается:String) -> Never {
    let fd=open(путь,O_RDWR|O_NOFOLLOW|O_CLOEXEC)
    var сведения=stat()
    guard fd >= 0 && fstat(fd,&сведения)==0 && сведения.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG) &&
          сведения.st_uid==geteuid() && String(сведения.st_dev)==dev && String(сведения.st_ino)==ino else { отказ("идентичность замка") }
    errno=0
    let итог=flock(fd,LOCK_EX|LOCK_NB), ошибка=errno
    if ожидается=="busy" { требовать(итог == -1 && (ошибка == EWOULDBLOCK || ошибка == EAGAIN),"чужой писатель") }
    else { требовать(итог==0,"освобождённый замок"); требовать(flock(fd,LOCK_UN)==0,"освобождение соперника") }
    требовать(close(fd)==0,"закрытие соперника")
    Darwin._exit(0)
}
func конкуренция(_ base:String) {
    проверитьКаталог(base)
    let путь=base+"/writer.lock"
    let fd=open(путь,O_RDWR|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0o600)
    var s=stat()
    guard fd >= 0 && fstat(fd,&s)==0 && s.st_mode & mode_t(S_IFMT)==mode_t(S_IFREG) && s.st_uid==geteuid() &&
          flock(fd,LOCK_EX|LOCK_NB)==0 else { отказ("замок владельца") }
    func проверитьСоперника(_ ожидание:String) {
        let p=Process(), out=Pipe(), err=Pipe(); p.executableURL=URL(fileURLWithPath:CommandLine.arguments[0])
        p.arguments=["--lock-child",путь,String(s.st_dev),String(s.st_ino),ожидание]
        p.environment=среда; p.standardOutput=out; p.standardError=err
        do { try p.run() } catch { отказ("старт соперника UNKNOWN") }
        let o=out.fileHandleForReading.readDataToEndOfFile(), e=err.fileHandleForReading.readDataToEndOfFile();p.waitUntilExit()
        требовать(p.terminationReason == .exit && p.terminationStatus==0 && o.isEmpty && e.isEmpty,"исход соперника")
    }
    проверитьСоперника("busy")
    требовать(flock(fd,LOCK_UN)==0 && close(fd)==0,"освобождение владельца")
    проверитьСоперника("free")
    let d=Data("PASS synthetic competing writer rejected while lock held\n".utf8); _=d.withUnsafeBytes { Darwin.write(STDOUT_FILENO,$0.baseAddress,$0.count) }
}
if CommandLine.arguments.count==5 && CommandLine.arguments[1]=="--recover" {
    восстановитель(CommandLine.arguments[2],CommandLine.arguments[3])
}
if CommandLine.arguments.count==6 && CommandLine.arguments[1]=="--lock-child" {
    соперник(CommandLine.arguments[2],CommandLine.arguments[3],CommandLine.arguments[4],CommandLine.arguments[5])
}
if CommandLine.arguments.count==3 && CommandLine.arguments[2]=="lock" {
    конкуренция(CommandLine.arguments[1]); Darwin._exit(0)
}
if CommandLine.arguments.count==5 && CommandLine.arguments[1]=="--child" { ребёнок(CommandLine.arguments[2],CommandLine.arguments[3]) }
требовать(CommandLine.arguments.count==4 && git.hasPrefix("/") && CommandLine.arguments[1].hasPrefix("/") && ["before","after"].contains(CommandLine.arguments[2]),"аргументы")
родитель(CommandLine.arguments[1],CommandLine.arguments[2])
