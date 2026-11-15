import Foundation
import Darwin
import CryptoKit
func text(_ s:String) { let d=Data((s+"\n").utf8);_ = d.withUnsafeBytes { Darwin.write(STDOUT_FILENO,$0.baseAddress,$0.count) } }
func reject(_ mode:String)->Never { text("REJECT \(mode) consumer=0");exit(2) }
func sha(_ data:Data)->String { SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined() }
struct Identity:Equatable { let dev:dev_t;let ino:ino_t;let size:off_t;let mode:mode_t;let uid:uid_t;let gid:gid_t;let links:nlink_t;let mt:Int;let mtn:Int;let ct:Int;let ctn:Int }
func read(_ path:String,owner:uid_t,max:Int=16_777_216)->(Identity,Data)? {
 var pre=stat();guard lstat(path,&pre)==0 && pre.st_mode & S_IFMT == S_IFREG else{return nil}
 let fd=open(path,O_RDONLY|O_NONBLOCK|O_NOFOLLOW|O_CLOEXEC);guard fd>=0 else{return nil}
 var closed=false;defer{if !closed {_ = close(fd)}}
 var a=stat(),b=stat(),c=stat();guard fstat(fd,&a)==0 && a.st_mode & S_IFMT == S_IFREG && a.st_uid==owner && a.st_mode & 0o022 == 0 && a.st_nlink>=1 && (owner==0 || a.st_nlink==1) && a.st_size>=0 && a.st_size<=max else{return nil}
 var d=Data(count:Int(a.st_size)),n=0;while n<d.count { let z=d.withUnsafeMutableBytes{Darwin.read(fd,$0.baseAddress!.advanced(by:n),$0.count-n)};guard z>0 else{return nil};n+=z }
 var extra:UInt8=0;guard Darwin.read(fd,&extra,1)==0 && fstat(fd,&b)==0 && lstat(path,&c)==0 else{return nil}
 func id(_ x:stat)->Identity { Identity(dev:x.st_dev,ino:x.st_ino,size:x.st_size,mode:x.st_mode,uid:x.st_uid,gid:x.st_gid,links:x.st_nlink,mt:x.st_mtimespec.tv_sec,mtn:x.st_mtimespec.tv_nsec,ct:x.st_ctimespec.tv_sec,ctn:x.st_ctimespec.tv_nsec) }
 guard id(pre)==id(a) && id(a)==id(b) && id(a)==id(c) else{return nil};let closedResult=close(fd);closed=true;guard closedResult==0 else{return nil};return (id(a),d)
}
let allowedFiles:Set<String>=["COMMIT_EDITMSG","HEAD","config","index","logs/HEAD","logs/refs/heads/base","logs/refs/heads/fixture-linked","objects/4b/48deed3a433909bfd6b6ab3d4b91348b6af464","objects/77/f0e9abb736e5c4c0c53226ba19c500c1265748","objects/ce/9d1cd8de8f220f31e09fbf8818e02fe2f79d83","refs/heads/base","refs/heads/fixture-linked","worktrees/work/HEAD","worktrees/work/ORIG_HEAD","worktrees/work/commondir","worktrees/work/config.worktree","worktrees/work/gitdir","worktrees/work/index","worktrees/work/logs/HEAD"]
let expected:[String:String]=["config":"95a1f7d19be439847af9384dfe1a1f7678aa0902b1601b24c56cc60d783388b1","worktrees/work/config.worktree":"84b300d6a1b61db1ac9b740fbf27cf0bd16e087d91d53f0ed64c40c1f5842782","worktrees/work/HEAD":"6a278a1882ab093b5e594c4ca951a15a0959423e35688e8f8ba623a23c180ab9","worktrees/work/index":"a06966308be9f520652215bda5fafa608e1bf6b3e559984e2968cbf3b4a952df","refs/heads/base":"05582947b539f4f7b2697678aeeae065365060b1ab16f3e3f94752b37a71ce89","refs/heads/fixture-linked":"05582947b539f4f7b2697678aeeae065365060b1ab16f3e3f94752b37a71ce89","objects/4b/48deed3a433909bfd6b6ab3d4b91348b6af464":"d1f781b16c851b005c8603ab4bb758d1c0c50fc97b8ce7af0477d36af3aab95b","objects/77/f0e9abb736e5c4c0c53226ba19c500c1265748":"ea3a179d975743138b36d432dfe29a91842f477d3698db3abd0e45e6995a605e","objects/ce/9d1cd8de8f220f31e09fbf8818e02fe2f79d83":"ef4e949d5796a225520255bbec4f773d1abde52f21bfd83e464259eb0bfb7d7f"]
func directoryID(_ path:String)->Identity? {
 var x=stat();guard lstat(path,&x)==0 && x.st_mode & S_IFMT == S_IFDIR && x.st_uid==geteuid() && x.st_mode & 0o022 == 0 else{return nil}
 return Identity(dev:x.st_dev,ino:x.st_ino,size:x.st_size,mode:x.st_mode,uid:x.st_uid,gid:x.st_gid,links:x.st_nlink,mt:x.st_mtimespec.tv_sec,mtn:x.st_mtimespec.tv_nsec,ct:x.st_ctimespec.tv_sec,ctn:x.st_ctimespec.tv_nsec)
}
let allowedDirs:Set<String>=["info","logs","logs/refs","logs/refs/heads","objects","objects/4b","objects/77","objects/ce","objects/info","objects/pack","refs","refs/heads","refs/tags","worktrees","worktrees/work","worktrees/work/logs","worktrees/work/refs"]
func inventory(_ base:String)->[String:Identity]? {
 let fm=FileManager.default, work=base+"/work", common=base+"/repo/.git", gd=common+"/worktrees/work"
 guard base.hasPrefix("/"),URL(fileURLWithPath:base).standardizedFileURL.resolvingSymlinksInPath().path==base,
       let roots=try? fm.contentsOfDirectory(atPath:base),Set(roots)==Set(["repo","work"]),
       let workNames=try? fm.contentsOfDirectory(atPath:work),Set(workNames)==Set([".git","fixture.txt","nested"]),
       let nested=try? fm.contentsOfDirectory(atPath:work+"/nested"),nested.isEmpty else{return nil}
 guard let baseID=directoryID(base),let repoID=directoryID(base+"/repo"),let workID=directoryID(work),let nestedID=directoryID(work+"/nested") else{return nil}
 var result:[String:Identity]=[base:baseID,base+"/repo":repoID,work:workID,work+"/nested":nestedID],seen:Set<String>=[],seenDirs:Set<String>=[]
 func visit(_ rel:String)->Bool {
  let path=rel.isEmpty ? common : common+"/"+rel
  guard let before=directoryID(path),let entries=try? fm.contentsOfDirectory(atPath:path) else{return false}
  result["dir:"+path]=before
  for name in entries {
   let child=rel.isEmpty ? name : rel+"/"+name, p=common+"/"+child
   var st=stat();guard lstat(p,&st)==0 && st.st_uid==geteuid() else{return false}
   if st.st_mode & S_IFMT == S_IFDIR { guard allowedDirs.contains(child),seenDirs.insert(child).inserted,visit(child) else{return false};continue }
   guard st.st_mode & S_IFMT == S_IFREG,allowedFiles.contains(child),let (id,d)=read(p,owner:geteuid()) else{return false}
   if let e=expected[child],sha(d) != e { return false };seen.insert(child);result[p]=id
  }
  return directoryID(path)==before
 }
 guard visit(""),seenDirs==allowedDirs else{return nil}
 guard seen==allowedFiles, let (mid,marker)=read(work+"/.git",owner:geteuid(),max:4096),marker==Data(("gitdir: "+gd+"\n").utf8),let (wid,wd)=read(work+"/fixture.txt",owner:geteuid()),wd==Data("changed\n".utf8),let back=read(gd+"/gitdir",owner:geteuid()),back.1==Data((work+"/.git\n").utf8),let cm=read(gd+"/commondir",owner:geteuid()),cm.1==Data("../..\n".utf8) else{return nil}
 result[work+"/.git"]=mid;result[work+"/fixture.txt"]=wid
 for (p,expectedHash) in [("/usr/bin/git","ed6f5284033aa2aae6a58427c25ba3ab119947b40365627b24e5d51a4b70a1cd"),("/bin/sh","f338dc2ba97328cb8aa29c57a348abf3267de71ef42ee1adf293b179542f2962")] { guard let (id,d)=read(p,owner:0,max:32_000_000),sha(d)==expectedHash else{return nil};result[p]=id }
 return result
}
struct StopOutcome {let attempted:Bool;let killRC:Int32;let killErr:Int32;let collected:Bool;let raw:Int32;let lost:Bool}
func stopOwned(_ pid:pid_t)->StopOutcome {
 var raw:Int32=0
 let before=waitpid(pid,&raw,WNOHANG)
 if before==pid {return StopOutcome(attempted:false,killRC:0,killErr:0,collected:true,raw:raw,lost:false)}
 guard before==0 else{return StopOutcome(attempted:false,killRC:0,killErr:0,collected:false,raw:raw,lost:true)}
 let rc=kill(pid,SIGKILL),err=rc==0 ? 0:errno,deadline=ProcessInfo.processInfo.systemUptime+1
 while ProcessInfo.processInfo.systemUptime<deadline {
  let n=waitpid(pid,&raw,WNOHANG)
  if n==pid{return StopOutcome(attempted:true,killRC:rc,killErr:err,collected:true,raw:raw,lost:false)}
  if n<0 && errno != EINTR {return StopOutcome(attempted:true,killRC:rc,killErr:err,collected:false,raw:raw,lost:true)}
  usleep(1000)
 }
 return StopOutcome(attempted:true,killRC:rc,killErr:err,collected:false,raw:raw,lost:false)
}
func uidAllowed(_ real:uid_t,_ effective:uid_t)->Bool { real != 0 && real == effective }
if CommandLine.arguments == [CommandLine.arguments[0],"--test-uid"] {
 guard uidAllowed(501,501) && !uidAllowed(0,0) && !uidAllowed(501,0) && !uidAllowed(0,501) else{text("HOLD uid predicate");exit(3)}
 text("PASS synthetic uid predicate");exit(0)
}
guard uidAllowed(getuid(),geteuid()) else{text("REJECT uid consumer=0");exit(2)}
var childAction=sigaction()
guard sigaction(SIGCHLD,nil,&childAction)==0,
      childAction.sa_flags & Int32(SA_SIGINFO | SA_NOCLDWAIT)==0,
      MemoryLayout.size(ofValue:childAction.__sigaction_u.__sa_handler)==MemoryLayout<UInt>.size,
      MemoryLayout.size(ofValue:SIG_DFL)==MemoryLayout<UInt>.size,
      unsafeBitCast(childAction.__sigaction_u.__sa_handler,to:UInt.self)==unsafeBitCast(SIG_DFL,to:UInt.self)
else{text("REJECT sigchld consumer=0");exit(2)}
if CommandLine.arguments.count==2 && ["--test-owned-stop","--test-reaped-child"].contains(CommandLine.arguments[1]) {
 let reaped=CommandLine.arguments[1]=="--test-reaped-child", executable=reaped ? "/usr/bin/true" : "/bin/sleep"
 var args=[strdup(executable),reaped ? nil : strdup("5"),nil],env:[UnsafeMutablePointer<CChar>?]=[nil],child:pid_t=0
 let rc=posix_spawn(&child,executable,nil,nil,&args,&env);guard rc==0 && child>1 else{text("HOLD test spawn");exit(3)}
 if reaped {
  var raw:Int32=0,done=false;let end=ProcessInfo.processInfo.systemUptime+2
  while ProcessInfo.processInfo.systemUptime<end {let n=waitpid(child,&raw,WNOHANG);if n==child {done=true;break};if n<0 && errno != EINTR {break};usleep(1000)}
  guard done && raw==0 else{text("HOLD test wait UNKNOWN");exit(3)}
 }
 let outcome=stopOwned(child)
 if reaped {guard outcome.lost && !outcome.attempted && !outcome.collected else{text("HOLD reaped test");exit(3)};text("PASS reaped child no signal");exit(0)}
 guard outcome.attempted && outcome.killRC==0 && outcome.collected && outcome.raw==SIGKILL && !outcome.lost else{text("HOLD owned stop UNKNOWN");exit(3)}
 text("PASS owned child SIGKILL collected");exit(0)
}
guard CommandLine.arguments.count==3 else{exit(2)}
let base=CommandLine.arguments[1],mode=CommandLine.arguments[2]
guard let initial=inventory(base) else{reject(mode)}
if mode=="swap" { let p=base+"/repo/.git/config",temp=base+"/repo/.git/config.swap";guard let data=try? Data(contentsOf:URL(fileURLWithPath:p)),(try? data.write(to:URL(fileURLWithPath:temp),options:.withoutOverwriting)) != nil,rename(temp,p)==0 else{reject(mode)} }
guard let before=inventory(base) else{reject(mode)}
if before != initial { if mode=="swap" {text("REJECT swap drift consumer=0");exit(2)};reject(mode) }
guard mode=="positive" else{text("HOLD unexpected mode");exit(3)}
let work=base+"/work"
let args=["/bin/sh","-c","ulimit -SHu 0 && exec \"$@\"","fum-git","/usr/bin/git","-C",work,"--no-pager","-c","core.fsmonitor=false","--work-tree="+work,"diff","--binary","--no-ext-diff","--no-textconv","--ignore-submodules=dirty","--",".",":(exclude)Журнал/фикстура/отчёт.md",":(exclude)Журнал/фикстура/материалы/запуски-проверок",":(exclude)Журнал/фикстура/материалы/запуски-проверок/**",":(top,exclude,literal)Proyekcii",":(top,exclude,glob)Proyekcii/**"]
let vars=["PATH=/bin:/usr/bin","LC_ALL=C","GIT_CONFIG_GLOBAL=/dev/null","GIT_CONFIG_NOSYSTEM=1","GIT_ATTR_NOSYSTEM=1","GIT_OPTIONAL_LOCKS=0","GIT_NO_LAZY_FETCH=1","GIT_NO_REPLACE_OBJECTS=1","GIT_ALLOW_PROTOCOL="]
var out:[Int32]=[-1,-1],err:[Int32]=[-1,-1]
guard pipe(&out)==0 && pipe(&err)==0 && Set(out+err).count==4 && (out+err).allSatisfy({$0>2}) else{text("HOLD pipe setup");exit(3)}
var actions:posix_spawn_file_actions_t?,attrs:posix_spawnattr_t?
guard posix_spawn_file_actions_init(&actions)==0 && posix_spawnattr_init(&attrs)==0 && posix_spawn_file_actions_addopen(&actions,STDIN_FILENO,"/dev/null",O_RDONLY,0)==0 && posix_spawn_file_actions_adddup2(&actions,out[1],STDOUT_FILENO)==0 && posix_spawn_file_actions_adddup2(&actions,err[1],STDERR_FILENO)==0 && posix_spawn_file_actions_addclose(&actions,out[0])==0 && posix_spawn_file_actions_addclose(&actions,err[0])==0 && posix_spawnattr_setflags(&attrs,Int16(POSIX_SPAWN_CLOEXEC_DEFAULT))==0 else{text("HOLD spawn setup");exit(3)}
var argv=args.map{strdup($0)};argv.append(nil);var env=vars.map{strdup($0)};env.append(nil)
var pid:pid_t=0;let spawn=posix_spawn(&pid,"/bin/sh",&actions,&attrs,&argv,&env)
_ = close(out[1]);_ = close(err[1]);posix_spawn_file_actions_destroy(&actions);posix_spawnattr_destroy(&attrs)
guard spawn==0 && pid>1 else{text("HOLD spawn code=\(spawn)");exit(3)}
for fd in [out[0],err[0]] {let f=fcntl(fd,F_GETFL);guard f>=0 && fcntl(fd,F_SETFL,f|O_NONBLOCK)==0 else{text("HOLD pipe UNKNOWN pid=\(pid)");exit(3)}}
var buffers=[Data(),Data()],eof=[false,false],failed=false,raw:Int32=0,collected=false
let deadline=ProcessInfo.processInfo.systemUptime+5
while !eof.allSatisfy({$0}) && ProcessInfo.processInfo.systemUptime<deadline {
 var fds=[out[0],err[0]].enumerated().map{pollfd(fd:eof[$0.offset] ? -1:$0.element,events:Int16(POLLIN|POLLHUP),revents:0)}
 let r=poll(&fds,2,50);if r<0 {if errno==EINTR {continue};failed=true;break};if r==0 {continue}
 for i in 0..<2 where !eof[i] && fds[i].revents != 0 {
  if fds[i].revents & Int16(POLLERR|POLLNVAL) != 0 {failed=true;break}
  var bytes=[UInt8](repeating:0,count:4096);let n=Darwin.read(fds[i].fd,&bytes,bytes.count)
  if n==0 {eof[i]=true} else if n>0 {if buffers[i].count+n>65536 {failed=true;break};buffers[i].append(contentsOf:bytes.prefix(n))} else if errno != EAGAIN && errno != EINTR {failed=true;break}
 }
 if failed {break}
}
if !failed && eof.allSatisfy({$0}) {
 while ProcessInfo.processInfo.systemUptime<deadline {let n=waitpid(pid,&raw,WNOHANG);if n==pid {collected=true;break};if n<0 && errno != EINTR {failed=true;break};usleep(1000)}
}
if failed || !eof.allSatisfy({$0}) || !collected {
 let stopped=stopOwned(pid)
 text("HOLD consumer UNKNOWN pid=\(pid) kill_attempted=\(stopped.attempted) kill_rc=\(stopped.killRC) kill_errno=\(stopped.killErr) collected=\(stopped.collected) raw=\(stopped.raw) ownership_lost=\(stopped.lost)");exit(3)
}
guard close(out[0])==0 && close(err[0])==0 else{text("HOLD pipe close");exit(3)}

let want=Data("diff --git a/fixture.txt b/fixture.txt\nindex 4b48dee..5ea2ed4 100644\n--- a/fixture.txt\n+++ b/fixture.txt\n@@ -1 +1 @@\n-original\n+changed\n".utf8)
guard raw == 0 && buffers[1].isEmpty && buffers[0]==want,let after=inventory(base),after==before else{text("HOLD consumer result UNKNOWN");exit(3)}
text("RESULT git_exit=0 stderr_bytes=0 diff_bytes=\(buffers[0].count) diff_sha256=\(sha(buffers[0]))")
text("PASS diff consumer=1")
