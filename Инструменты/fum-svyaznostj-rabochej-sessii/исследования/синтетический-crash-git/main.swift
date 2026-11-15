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
func родитель(_ base:String,_ режим:String) {
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
        let повторноеЧтение=строка(gitВызов(repo,["rev-parse","HEAD"]))
        требовать(повторноеЧтение==текущий,"без повторного коммита")
        print("RECOVERED after commit; parent and event bytes match; no replay")
    }
}
if CommandLine.arguments.count==5 && CommandLine.arguments[1]=="--child" { ребёнок(CommandLine.arguments[2],CommandLine.arguments[3]) }
требовать(CommandLine.arguments.count==4 && git.hasPrefix("/") && CommandLine.arguments[1].hasPrefix("/") && ["before","after"].contains(CommandLine.arguments[2]),"аргументы")
родитель(CommandLine.arguments[1],CommandLine.arguments[2])
