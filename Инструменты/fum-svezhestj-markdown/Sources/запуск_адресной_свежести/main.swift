import Foundation
import Darwin
import адресная_свежесть

var действие = sigaction()
действие.__sigaction_u.__sa_handler = SIG_IGN
sigemptyset(&действие.sa_mask)
guard sigaction(SIGPIPE, &действие, nil) == 0 else { while true { _ = Darwin.pause() } }

func удержание(_ текст: String) -> Never {
    let b=Array((текст+"\n").utf8); _=b.withUnsafeBytes { Darwin.write(2,$0.baseAddress,b.count) }
    while true { _=Darwin.pause() }
}
func вывести(_ текст: String) {
    let b=Array((текст+"\n").utf8); var p=0
    while p<b.count { let n=b.withUnsafeBytes { Darwin.write(1,$0.baseAddress!.advanced(by:p),b.count-p) }; guard n>0 else { удержание("UNKNOWN вывод") }; p += n }
}
let аргументы=CommandLine.arguments
guard аргументы.count==4, let корень=Int32(аргументы[1]), let устройство=dev_t(аргументы[2]), let inode=ino_t(аргументы[3]), корень>=3 else { удержание("UNKNOWN неверный вход") }
var корневая_метка=stat(); guard fstat(корень,&корневая_метка)==0, корневая_метка.st_dev==устройство, корневая_метка.st_ino==inode, корневая_метка.st_mode & mode_t(S_IFMT)==mode_t(S_IFDIR) else { удержание("UNKNOWN корень") }
var данные=Data(), буфер=[UInt8](repeating:0,count:8192)
while true {
    let осталось=8_388_608-данные.count; guard осталось>0 else { удержание("UNKNOWN лимит ввода") }
    let n=буфер.withUnsafeMutableBytes { Darwin.read(0,$0.baseAddress,min($0.count,осталось)) }
    guard n>=0 else { удержание("UNKNOWN чтение ввода") }; if n==0 { break }; данные.append(contentsOf:буфер.prefix(n))
}
guard let ввод=try? разобрать_вход(данные) else { удержание("UNKNOWN формат ввода") }
let владелец=владелец_дескрипторов()
guard let план=try? составить_план(ввод.файлы,сейчас:ввод.сейчас), let файлы=try? привязать(план,корень:корень,владелец:владелец) else { удержание("UNKNOWN план или привязка") }
for файл in файлы {
    guard сверить(файл) else { удержание("UNKNOWN preflight") }
}
var число=0
for (номер, файл) in файлы.enumerated() {
    var метка=stat(); guard fstat(корень,&метка)==0, метка.st_dev==устройство, метка.st_ino==inode else { удержание("UNKNOWN корень после \(число)") }
    switch выполнить(файл) {
    case .завершено: число += 1; вывести("ЗАПИСАНО \(номер)")
    case .без_изменения: вывести("БЕЗ_ИЗМЕНЕНИЯ \(номер)")
    case .отказ_до_записи: удержание("UNKNOWN отказ после \(число)")
    case .неизвестно: удержание("UNKNOWN запись после \(число)")
    }
}
for дескриптор in владелец.дескрипторы.reversed() {
    вывести("CLOSE_START \(дескриптор)")
    guard закрыть_один(дескриптор) else { удержание("UNKNOWN close \(дескриптор) после \(число)") }
    вывести("CLOSE_DONE \(дескриптор)")
}
вывести("СИНТЕТИЧЕСКИЙ_РЕЗУЛЬТАТ обновлено=\(число)")
