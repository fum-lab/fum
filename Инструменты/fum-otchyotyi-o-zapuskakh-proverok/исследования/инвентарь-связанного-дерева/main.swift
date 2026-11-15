import Foundation
import Darwin
import CryptoKit
func hold(_ s:String)->Never { print("HOLD \(s)"); exit(2) }
func hash(_ d:Data)->String { SHA256.hash(data:d).map { String(format:"%02x",$0) }.joined() }
func same(_ a:stat,_ b:stat)->Bool { a.st_dev==b.st_dev && a.st_ino==b.st_ino && a.st_mode==b.st_mode && a.st_uid==b.st_uid && a.st_gid==b.st_gid && a.st_nlink==b.st_nlink && a.st_size==b.st_size && a.st_mtimespec.tv_sec==b.st_mtimespec.tv_sec && a.st_mtimespec.tv_nsec==b.st_mtimespec.tv_nsec && a.st_ctimespec.tv_sec==b.st_ctimespec.tv_sec && a.st_ctimespec.tv_nsec==b.st_ctimespec.tv_nsec }
func openAbsoluteDirectory(_ path:String)->Int32 {
 guard path.hasPrefix("/"), path != "/", !path.hasSuffix("/"), !path.contains("//") else { hold("absolute path") }
 let parts=path.split(separator:"/").map(String.init); guard !parts.contains(".") && !parts.contains("..") else { hold("path traversal") }
 var current=open("/",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);guard current>=0 else { hold("root") }
 for part in parts { let next=openat(current,part,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);guard next>=0 else { hold("directory component errno=\(errno)") };close(current);current=next }
 var st=stat();guard fstat(current,&st)==0 && st.st_uid==geteuid() && (st.st_mode & S_IFMT)==S_IFDIR && (st.st_mode & 0o022)==0 else { hold("directory owner or mode") };return current
}
func readFile(_ dir:Int32,_ name:String,_ maxSize:Int,_ label:String)->Data {
 guard !name.contains("/") && name != "." && name != ".." else { hold("component") }
 let fd=openat(dir,name,O_RDONLY|O_NONBLOCK|O_NOFOLLOW|O_CLOEXEC);guard fd>=0 else { hold("open \(name) errno=\(errno)") }
 var a=stat(),b=stat(),named=stat();guard fstat(fd,&a)==0 && (a.st_mode & S_IFMT)==S_IFREG && a.st_uid==geteuid() && a.st_nlink==1 && (a.st_mode & 0o022)==0 && a.st_size>=0 && a.st_size<=maxSize else { hold("file policy \(name)") }
 var bytes=Data(count:Int(a.st_size)),pos=0
 while pos<bytes.count { let n=bytes.withUnsafeMutableBytes { Darwin.read(fd,$0.baseAddress!.advanced(by:pos),$0.count-pos) }; guard n>0 else { hold("read \(name)") };pos+=n }
 var extra:UInt8=0;guard read(fd,&extra,1)==0 && fstat(fd,&b)==0 && fstatat(dir,name,&named,AT_SYMLINK_NOFOLLOW)==0 && same(a,b) && same(a,named) && close(fd)==0 else { hold("changed \(name)") }
 print("FILE \(label) dev=\(a.st_dev) inode=\(a.st_ino) mode=\(a.st_mode & 0o7777) owner=\(a.st_uid) bytes=\(bytes.count) sha256=\(hash(bytes))")
 return bytes
}
func absent(_ dir:Int32,_ name:String) { var st=stat();if fstatat(dir,name,&st,AT_SYMLINK_NOFOLLOW)==0 { hold("unaccounted \(name)") };guard errno==ENOENT else { hold("probe \(name) errno=\(errno)") };print("ABSENT \(name)") }
func optionalFile(_ dir:Int32,_ name:String,_ maxSize:Int,_ label:String) {
 var st=stat()
 if fstatat(dir,name,&st,AT_SYMLINK_NOFOLLOW)==0 { _ = readFile(dir,name,maxSize,label);return }
 guard errno==ENOENT else { hold("probe \(name) errno=\(errno)") }
 print("ABSENT \(label)")
}
guard CommandLine.arguments.count==4 else { hold("arguments") }
let work=CommandLine.arguments[1],gitdir=CommandLine.arguments[2],common=CommandLine.arguments[3]
guard gitdir.hasPrefix(common+"/worktrees/"), !String(gitdir.dropFirst((common+"/worktrees/").count)).contains("/") else { hold("gitdir outside scoped common") }
let w=openAbsoluteDirectory(work),g=openAbsoluteDirectory(gitdir),c=openAbsoluteDirectory(common)
let marker=readFile(w,".git",4096,"work/.git"), backlink=readFile(g,"gitdir",4096,"gitdir/gitdir"), relative=readFile(g,"commondir",64,"gitdir/commondir")
guard marker==Data(("gitdir: "+gitdir+"\n").utf8),backlink==Data((work+"/.git\n").utf8),relative==Data("../..\n".utf8) else { hold("linked topology") }
_ = readFile(g,"HEAD",4096,"gitdir/HEAD");_ = readFile(g,"index",16_777_216,"gitdir/index");_ = readFile(c,"config",65536,"common/config")
optionalFile(g,"config.worktree",65536,"gitdir/config.worktree")
print("UNKNOWN extensions.worktreeConfig: effective configuration not established")
absent(w,".gitattributes")
let info=openat(c,"info",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);guard info>=0 else { hold("info directory") };absent(info,"attributes");close(info)
let objects=openat(c,"objects",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);guard objects>=0 else { hold("objects directory") }
let objectInfo=openat(objects,"info",O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);guard objectInfo>=0 else { hold("objects info directory") };absent(objectInfo,"alternates");close(objectInfo);close(objects)
close(w);close(g);close(c)
print("UNKNOWN config/includes, nested attributes, index semantics, refs/objects, binary, custody and ABA; consumer=0")
exit(3)
