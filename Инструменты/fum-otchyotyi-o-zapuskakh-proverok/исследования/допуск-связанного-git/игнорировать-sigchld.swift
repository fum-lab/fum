import Darwin
guard CommandLine.arguments.count==2 else{exit(3)}
signal(SIGCHLD,SIG_IGN)
var argv=[strdup(CommandLine.arguments[1]),strdup("/unused"),strdup("sigchld"),nil],env:[UnsafeMutablePointer<CChar>?]=[nil]
execve(CommandLine.arguments[1],&argv,&env)
exit(3)
