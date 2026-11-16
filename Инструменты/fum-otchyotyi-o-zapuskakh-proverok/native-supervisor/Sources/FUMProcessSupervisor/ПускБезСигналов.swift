import Darwin
import FUMProcessProtocol

// Опытный shim: право на каталог, конкретный target и окружение устанавливает владелец.
// EOF, ошибку или неподтверждённую идентичность нельзя считать успешным запуском.
func выполнитьШлюзБезСигналов(_ args: [String]) -> Int32 {
    guard args.count >= 11, args[1] == "fum-nosignal-shim.1",
          let gate = Int32(args[8]), gate > 2, String(gate) == args[8], args[9] == "--",
          let каталог = ОпораЗаимствованногоКаталога(args[2], args[3], args[4], args[5], args[6], args[7],
              область: .рабочееДерево, занятыеДескрипторы: [gate]),
          args[10].hasPrefix("/"), !args[10].split(separator: "/").contains("..") else { return 125 }
    var gateМетка = stat()
    let gateФлаги = fcntl(gate, F_GETFL), gateFDФлаги = fcntl(gate, F_GETFD)
    let rootFDФлаги = fcntl(каталог.дескриптор, F_GETFD)
    guard fstat(gate, &gateМетка) == 0, gateМетка.st_mode & UInt16(S_IFMT) == UInt16(S_IFIFO),
          gateФлаги >= 0, gateФлаги & O_ACCMODE == O_RDONLY, gateFDФлаги >= 0,
          rootFDФлаги >= 0, rootFDФлаги & FD_CLOEXEC == 0,
          fcntl(gate, F_SETFD, gateFDФлаги | FD_CLOEXEC) == 0,
          подтвердитьОткрытыйКаталог(каталог) else { return 125 }
    var команда: UInt8 = 0
    var прочитано: Int
    repeat { прочитано = read(gate, &команда, 1) } while прочитано == -1 && errno == EINTR
    guard прочитано == 1, команда == 0x47, подтвердитьОткрытыйКаталог(каталог), close(gate) == 0 else { return 125 }
    let argv = args.dropFirst(10).map { strdup($0) } + [nil]
    let environment = ["PATH=/bin:/usr/bin", "LC_ALL=C", "FUM_BORROWED_DIRECTORY_FD=\(каталог.дескриптор)"].map { значение in значение.withCString { strdup($0) } } + [nil]
    defer { for указатель in argv { free(указатель) }; for указатель in environment { free(указатель) } }
    guard argv.dropLast().allSatisfy({ $0 != nil }), environment.dropLast().allSatisfy({ $0 != nil }) else { return 125 }
    _ = argv.withUnsafeBufferPointer { аргументы in environment.withUnsafeBufferPointer { среда in
        execve(args[10], UnsafeMutablePointer(mutating: аргументы.baseAddress), UnsafeMutablePointer(mutating: среда.baseAddress))
    } }
    return 125
}
