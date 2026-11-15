import Foundation
import Darwin
func hold(_ message:String)->Never { print("HOLD \(message)"); exit(2) }
func eq(_ a:stat,_ b:stat)->Bool { a.st_dev == b.st_dev && a.st_ino == b.st_ino && a.st_mode == b.st_mode && a.st_size == b.st_size && a.st_mtimespec.tv_sec == b.st_mtimespec.tv_sec && a.st_mtimespec.tv_nsec == b.st_mtimespec.tv_nsec && a.st_ctimespec.tv_sec == b.st_ctimespec.tv_sec && a.st_ctimespec.tv_nsec == b.st_ctimespec.tv_nsec }
func readFile(_ root:Int32,_ path:String)->Data {
 let parts=path.split(separator:"/").map(String.init); var dir=dup(root); guard dir>=0 else { hold("dup") }
 for component in parts.dropLast() { let next=openat(dir,component,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC); guard next>=0 else { hold("directory \(path) errno=\(errno)") }; close(dir); dir=next }
 let fd=openat(dir,parts.last!,O_RDONLY|O_NOFOLLOW|O_CLOEXEC); guard fd>=0 else { hold("open \(path) errno=\(errno)") }
 var a=stat(),b=stat(),p=stat(); guard fstat(fd,&a)==0 && (a.st_mode & S_IFMT)==S_IFREG && a.st_nlink==1 && a.st_size>=0 && a.st_size<=1_048_576 else { hold("type \(path)") }
 var data=Data(count:Int(a.st_size)), used=0
 while used<data.count { let n=data.withUnsafeMutableBytes { Darwin.read(fd,$0.baseAddress!.advanced(by:used),$0.count-used) }; guard n>0 else { hold("read \(path)") }; used+=n }
 var extra:UInt8=0; guard read(fd,&extra,1)==0 && fstat(fd,&b)==0 && fstatat(dir,parts.last!,&p,AT_SYMLINK_NOFOLLOW)==0 && eq(a,b) && eq(a,p) else { hold("changed \(path)") }
 close(fd);close(dir);return data
}
func absent(_ root:Int32,_ path:String) { var s=stat(); guard fstatat(root,path,&s,AT_SYMLINK_NOFOLLOW) != 0 && errno==ENOENT else { hold("prohibited \(path)") } }
guard CommandLine.arguments.count==3 else { hold("arguments") }
let base=CommandLine.arguments[1], output=CommandLine.arguments[2]
guard base.hasPrefix("/"), output.hasPrefix("/"), !base.contains("/../"), !output.contains("/../") else { hold("paths") }
let root=open(base,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC); guard root>=0 else { hold("root") }
let config="[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = false\n\tlogallrefupdates = true\n\tignorecase = true\n\tprecomposeunicode = true\n"
guard readFile(root,"repo/.git/config")==Data(config.utf8) else { hold("config includes or filter") }
for p in ["work/.gitattributes","repo/.git/info/attributes","repo/.git/worktrees/work/info/attributes","repo/.git/worktrees/work/config.worktree","repo/.git/objects/info/alternates","repo/.git/packed-refs"] { absent(root,p) }
let workEntries=try! FileManager.default.contentsOfDirectory(atPath:base+"/work")
guard Set(workEntries)==Set([".git","fixture.txt"]) else { hold("unexpected work entry") }
guard readFile(root,"work/.git")==Data(("gitdir: "+base+"/repo/.git/worktrees/work\n").utf8), readFile(root,"repo/.git/worktrees/work/gitdir")==Data((base+"/work/.git\n").utf8), readFile(root,"repo/.git/worktrees/work/commondir")==Data("../..\n".utf8), readFile(root,"repo/.git/worktrees/work/HEAD")==Data("ref: refs/heads/fixture-linked\n".utf8), readFile(root,"work/fixture.txt")==Data("changed\n".utf8) else { hold("identity") }
let ref=readFile(root,"repo/.git/refs/heads/fixture-linked")
guard let oid=String(data:ref,encoding:.utf8)?.trimmingCharacters(in:.whitespacesAndNewlines), oid.count==40, oid.allSatisfy({$0.isHexDigit && !$0.isUppercase}) else { hold("ref") }
let paths=["repo/.git/config","repo/.git/worktrees/work/HEAD","repo/.git/worktrees/work/index","repo/.git/worktrees/work/commondir","repo/.git/refs/heads/fixture-linked","repo/.git/objects/"+String(oid.prefix(2))+"/"+String(oid.dropFirst(2)),"repo/.git/objects/4b/48deed3a433909bfd6b6ab3d4b91348b6af464","repo/.git/objects/ce/9d1cd8de8f220f31e09fbf8818e02fe2f79d83","work/fixture.txt"]
var files:[String:Data]=[:]; for p in paths { files[p]=readFile(root,p) }
guard readFile(root,"repo/.git/config")==Data(config.utf8), readFile(root,"repo/.git/refs/heads/fixture-linked")==ref else { hold("source changed") }
let fm=FileManager.default; guard mkdir(output,0o700)==0 else { hold("destination exists or create") }
files["work/.git"]=Data(("gitdir: "+output+"/repo/.git/worktrees/work\n").utf8)
files["repo/.git/worktrees/work/gitdir"]=Data((output+"/work/.git\n").utf8)
for (p,data) in files.sorted(by:{$0.key<$1.key}) {
 let dest=output+"/"+p; do { try fm.createDirectory(atPath:(dest as NSString).deletingLastPathComponent,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700]) } catch { hold("destination directory") }
 let fd=open(dest,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0o600); guard fd>=0 else { hold("destination file") }
 var used=0; while used<data.count { let n=data.withUnsafeBytes { write(fd,$0.baseAddress!.advanced(by:used),$0.count-used) }; guard n>0 else { hold("write") };used+=n }; guard fsync(fd)==0 && close(fd)==0 else { hold("sync") }
 guard (try? Data(contentsOf:URL(fileURLWithPath:dest)))==data else { hold("readback") }
}
print("PASS snapshot files=\(files.count); no consumer run; source atomicity UNKNOWN")
