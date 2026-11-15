import Foundation
import Darwin
func отказ(_ s: String) -> Never { let d=Data(("HOLD "+s+"\n").utf8); _=d.withUnsafeBytes { Darwin.write(STDERR_FILENO,$0.baseAddress,$0.count) }; Darwin._exit(2) }
func требовать(_ v: @autoclosure () -> Bool, _ s:String) { if !v() { отказ(s) } }
let среда=["PATH":"/usr/bin:/bin","LC_ALL":"C","GIT_CONFIG_NOSYSTEM":"1","GIT_CONFIG_GLOBAL":"/dev/null","GIT_ATTR_NOSYSTEM":"1","GIT_OPTIONAL_LOCKS":"0","GIT_NO_LAZY_FETCH":"1","GIT_NO_REPLACE_OBJECTS":"1"]
guard CommandLine.arguments.count==3 else { отказ("аргументы") }
let repo=CommandLine.arguments[1], git=CommandLine.arguments[2]
var сведения=stat()
требовать(repo.hasPrefix("/") && !repo.split(separator:"/").contains("..") &&
          URL(fileURLWithPath:repo).standardizedFileURL.resolvingSymlinksInPath().path==repo &&
          lstat(repo,&сведения)==0 && сведения.st_uid==geteuid() &&
          сведения.st_mode & mode_t(S_IFMT)==mode_t(S_IFDIR) && сведения.st_mode & 0o7777==0o700 && git.hasPrefix("/"),"каталог")
func выполнить(_ args:[String])->Data {
    let p=Process(),out=Pipe(),err=Pipe(); p.executableURL=URL(fileURLWithPath:git)
    p.arguments=["-C",repo,"-c","core.hooksPath=/dev/null","-c","core.fsmonitor=false"]+args
    p.environment=среда;p.standardOutput=out;p.standardError=err
    do { try p.run() } catch { отказ("старт UNKNOWN") }
    let d=out.fileHandleForReading.readDataToEndOfFile(), e=err.fileHandleForReading.readDataToEndOfFile();p.waitUntilExit()
    требовать(p.terminationReason == .exit && p.terminationStatus==0 && e.isEmpty && d.count<=4096,"Git")
    return d
}
func текст(_ d:Data)->String { guard let s=String(data:d,encoding:.utf8) else { отказ("utf8") }; return s.trimmingCharacters(in:.newlines) }
struct Запись { let id:String; let позиция:Int; let bytes:Data; let oid:String }
enum Итог { case новый(String), повтор(String), отказ }
var записи:[String:Запись]=[:], последняя=0
@MainActor func получить(_ id:String,_ позиция:Int,_ bytes:Data)->Итог {
    if let прежняя=записи[id] {
        guard прежняя.позиция==позиция && прежняя.bytes==bytes && выполнить(["show",прежняя.oid+":events/"+id+".DATA"])==bytes else { return .отказ }
        return .повтор(прежняя.oid)
    }
    guard позиция==последняя+1 && ["event-1","event-2"].contains(id) else { return .отказ }
    let путь=repo+"/events/"+id+".DATA", fd=open(путь,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0o600)
    guard fd>=0 else { отказ("создание UNKNOWN") }
    let n=bytes.withUnsafeBytes { Darwin.write(fd,$0.baseAddress,$0.count) }
    guard n==bytes.count && fsync(fd)==0 && close(fd)==0 else { отказ("запись UNKNOWN") }
    let до=текст(выполнить(["rev-parse","HEAD"]))
    _=выполнить(["add","--","events/"+id+".DATA"])
    _=выполнить(["-c","user.name=Synthetic","-c","user.email=synthetic@example.invalid","commit","--quiet","-m","synthetic event"])
    let oid=текст(выполнить(["rev-parse","HEAD"]))
    требовать(oid != до && текст(выполнить(["rev-parse","HEAD^"]))==до &&
              выполнить(["diff-tree","--no-commit-id","--name-only","-r","HEAD"])==Data(("events/"+id+".DATA\n").utf8) &&
              выполнить(["show","HEAD:events/"+id+".DATA"])==bytes,"состав события")
    записи[id]=Запись(id:id,позиция:позиция,bytes:bytes,oid:oid);последняя=позиция
    return .новый(oid)
}
let байты=Data("same synthetic payload\n".utf8)
let base=текст(выполнить(["rev-parse","HEAD"]))
if case .отказ = получить("event-2",2,байты) {} else { отказ("пропуск") }
требовать(текст(выполнить(["rev-parse","HEAD"]))==base,"HEAD после пропуска")
guard case let .новый(первый)=получить("event-1",1,байты) else { отказ("первый") }
guard case let .повтор(повтор)=получить("event-1",1,байты), повтор==первый else { отказ("повтор") }
требовать(текст(выполнить(["rev-parse","HEAD"]))==первый,"HEAD после повтора")
if case .отказ = получить("event-1",1,Data("conflict\n".utf8)) {} else { отказ("конфликт") }
требовать(текст(выполнить(["rev-parse","HEAD"]))==первый,"HEAD после конфликта")
guard case let .новый(второй)=получить("event-2",2,байты), второй != первый else { отказ("второй ID") }
требовать(текст(выполнить(["rev-list","--count","HEAD"]))=="3" && текст(выполнить(["rev-parse","HEAD"]))==второй,"число коммитов")
print("PASS synthetic duplicate, conflict, gap and distinct IDs")
