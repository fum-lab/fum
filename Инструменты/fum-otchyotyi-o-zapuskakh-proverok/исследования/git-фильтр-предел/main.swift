import Foundation
import Darwin
func отказ(_ s:String)->Never { let d=Data(("HOLD "+s+"\n").utf8); _=d.withUnsafeBytes { Darwin.write(STDERR_FILENO,$0.baseAddress,$0.count) }; Darwin._exit(2) }
func требовать(_ v:@autoclosure ()->Bool,_ s:String) { if !v() { отказ(s) } }
guard CommandLine.arguments.count==4 else { отказ("аргументы") }
let repo=CommandLine.arguments[1], git=CommandLine.arguments[2], режим=CommandLine.arguments[3]
var s=stat()
требовать(["optional","required"].contains(режим) && repo.hasPrefix("/") && git.hasPrefix("/") &&
          !repo.split(separator:"/").contains("..") &&
          URL(fileURLWithPath:repo).standardizedFileURL.resolvingSymlinksInPath().path==repo &&
          lstat(repo,&s)==0 && s.st_mode & mode_t(S_IFMT)==mode_t(S_IFDIR) &&
          s.st_uid==geteuid() && s.st_mode & 0o7777==0o700,"репозиторий фикстуры")
let p=Process(), out=Pipe(), err=Pipe()
p.executableURL=URL(fileURLWithPath:"/bin/sh")
p.arguments=["-c","ulimit -SHu 0 && exec \"$@\"","fum-git",git,"-C",repo,"--no-pager","-c","core.fsmonitor=false","--work-tree="+repo,"diff","--binary","--no-ext-diff","--no-textconv","--ignore-submodules=dirty","--","."]
p.environment=["PATH":"/usr/bin:/bin","LC_ALL":"C","GIT_CONFIG_NOSYSTEM":"1","GIT_CONFIG_GLOBAL":"/dev/null","GIT_ATTR_NOSYSTEM":"1","GIT_OPTIONAL_LOCKS":"0","GIT_NO_LAZY_FETCH":"1","GIT_NO_REPLACE_OBJECTS":"1","GIT_ALLOW_PROTOCOL":""]
p.standardOutput=out; p.standardError=err
do { try p.run() } catch { отказ("старт Git UNKNOWN") }
let stdout=out.fileHandleForReading.readDataToEndOfFile(), stderr=err.fileHandleForReading.readDataToEndOfFile();p.waitUntilExit()
требовать(p.terminationReason == .exit && stdout.count<=4096 && stderr.count<=4096 &&
          stderr.range(of:Data("cannot fork".utf8)) != nil && stderr.range(of:Data("external filter".utf8)) != nil &&
          !FileManager.default.fileExists(atPath:repo+"/filter-executed"),"терминальный исход")
let принял = p.terminationStatus == 0 && stderr.isEmpty
требовать(!принял && (режим=="optional" ? p.terminationStatus==0 : p.terminationStatus != 0),"fail-closed")
print("PASS synthetic \(режим): Git exit=\(p.terminationStatus), stderr непуст, профиль отклонил")
