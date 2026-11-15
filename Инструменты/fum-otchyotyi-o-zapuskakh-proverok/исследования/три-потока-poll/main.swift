import Foundation
import Darwin
func hold(_ s:String)->Never { print("HOLD \(s)"); exit(2) }
guard CommandLine.arguments.count == 2, ["small","overflow"].contains(CommandLine.arguments[1]) else { hold("arguments") }
let mode=CommandLine.arguments[1], limit=4
var pipes=[[Int32]](repeating:[-1,-1],count:3)
for i in 0..<3 { guard pipe(&pipes[i])==0 else { hold("pipe") }; let f=fcntl(pipes[i][0],F_GETFL); guard f>=0 && fcntl(pipes[i][0],F_SETFL,f|O_NONBLOCK)==0 else { hold("nonblock") } }
let values = [Array("STAT".utf8),Array((mode == "overflow" ? "OUTPUT!!" : "OUT!").utf8),Array("ERR!".utf8)]
for i in 0..<3 { let n=values[i].withUnsafeBytes { write(pipes[i][1],$0.baseAddress,$0.count) }; guard n==values[i].count && close(pipes[i][1])==0 else { hold("fixture write") } }
var buffers=[[UInt8]](repeating:[],count:3), overflow=[Bool](repeating:false,count:3), open=[Bool](repeating:true,count:3)
let deadline=ProcessInfo.processInfo.systemUptime+2
while open.contains(true) {
 let now=ProcessInfo.processInfo.systemUptime; guard now<deadline else { hold("deadline") }
 var requests=(0..<3).map { pollfd(fd:open[$0] ? pipes[$0][0] : -1,events:Int16(POLLIN|POLLHUP),revents:0) }
 let count=poll(&requests,3,Int32(min(100,Int((deadline-now)*1000)))); guard count>=0 else { hold("poll errno=\(errno)") }; if count==0 { continue }
 for i in 0..<3 where open[i] && requests[i].revents != 0 {
  guard requests[i].revents & Int16(POLLERR|POLLNVAL)==0 else { hold("channel error \(i)") }
  var chunk=[UInt8](repeating:0,count:16); let n=read(pipes[i][0],&chunk,chunk.count)
  if n==0 { guard close(pipes[i][0])==0 else { hold("close") };open[i]=false;continue }
  if n<0 { if errno==EAGAIN || errno==EINTR { continue };hold("read errno=\(errno)") }
  let remaining=max(0,limit-buffers[i].count); buffers[i].append(contentsOf:chunk.prefix(min(n,remaining))); if n>remaining { overflow[i]=true }
 }
}
guard buffers[0]==Array("STAT".utf8),buffers[2]==Array("ERR!".utf8),(buffers[1]==Array("OUT!".utf8) || (mode=="overflow" && buffers[1]==Array("OUTP".utf8))),overflow == (mode=="overflow" ? [false,true,false] : [false,false,false]) else { hold("comparison") }
print("PASS mode=\(mode) counts=\(buffers.map{$0.count}) overflow=\(overflow)")
