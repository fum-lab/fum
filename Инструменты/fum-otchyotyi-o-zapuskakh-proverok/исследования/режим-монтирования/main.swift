import Darwin
import Foundation
func hold(_ s:String)->Never { print("HOLD \(s)");exit(2) }
guard CommandLine.arguments.count==2, CommandLine.arguments[1].hasPrefix("/") else { hold("arguments") }
let fd=open(CommandLine.arguments[1],O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);guard fd>=0 else { hold("open errno=\(errno)") }
var a=statfs(),b=statfs(),st=stat()
guard fstat(fd,&st)==0 && fstatfs(fd,&a)==0 && fstatfs(fd,&b)==0 else { hold("stat errno=\(errno)") }
guard a.f_fsid.val.0 == b.f_fsid.val.0 && a.f_fsid.val.1 == b.f_fsid.val.1 && a.f_flags==b.f_flags else { hold("mount changed") }
let readOnly = a.f_flags & UInt32(MNT_RDONLY) != 0
print("MOUNT readonly=\(readOnly) fsid=\(a.f_fsid.val.0),\(a.f_fsid.val.1) flags=\(a.f_flags) inode=\(st.st_ino)")
print("UNKNOWN snapshot identity, writable aliases, other writers, exec image, ABA, custody; consumer=0")
guard close(fd)==0 else { hold("close") }
exit(3)
