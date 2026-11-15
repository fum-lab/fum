import Foundation
import Darwin
import адресная_свежесть

var Действие = sigaction()
Действие.__sigaction_u.__sa_handler = SIG_IGN
sigemptyset(&Действие.sa_mask)
guard sigaction(SIGPIPE, &Действие, nil) == 0 else { while true { _ = Darwin.pause() } }

func удержание(_ Текст: String) -> Never {
    let Байты=Array((Текст+"\n").utf8); _=Байты.withUnsafeBytes { Darwin.write(2,$0.baseAddress,Байты.count) }
    while true { _=Darwin.pause() }
}
func вывести(_ Текст: String) {
    let Байты=Array((Текст+"\n").utf8); var Смещение=0
    while Смещение<Байты.count { let Количество=Байты.withUnsafeBytes { Darwin.write(1,$0.baseAddress!.advanced(by:Смещение),Байты.count-Смещение) }; guard Количество>0 else { удержание("UNKNOWN вывод") }; Смещение += Количество }
}
let Аргументы=CommandLine.arguments
guard Аргументы.count==4, let Корень=Int32(Аргументы[1]), let Устройство=dev_t(Аргументы[2]), let Индекс=ino_t(Аргументы[3]), Корень>=3 else { удержание("UNKNOWN неверный вход") }
var Корневая_метка=stat(); guard fstat(Корень,&Корневая_метка)==0, Корневая_метка.st_dev==Устройство, Корневая_метка.st_ino==Индекс, Корневая_метка.st_mode & mode_t(S_IFMT)==mode_t(S_IFDIR) else { удержание("UNKNOWN корень") }
var Данные=Data(), Буфер=[UInt8](repeating:0,count:8192)
while true {
    let Осталось=8_388_608-Данные.count; guard Осталось>0 else { удержание("UNKNOWN лимит ввода") }
    let Количество=Буфер.withUnsafeMutableBytes { Darwin.read(0,$0.baseAddress,min($0.count,Осталось)) }
    guard Количество>=0 else { удержание("UNKNOWN чтение ввода") }; if Количество==0 { break }; Данные.append(contentsOf:Буфер.prefix(Количество))
}
guard let Ввод=try? разобрать_вход(Данные) else { удержание("UNKNOWN формат ввода") }
let Владелец=владелец_дескрипторов()
guard let План=try? составить_план(Ввод.файлы,сейчас:Ввод.сейчас), let Файлы=try? привязать(План,корень:Корень,владелец:Владелец) else { удержание("UNKNOWN план или привязка") }
for Файл in Файлы {
    guard сверить(Файл) else { удержание("UNKNOWN preflight") }
}
var Число=0
for (Номер, Файл) in Файлы.enumerated() {
    var Метка=stat(); guard fstat(Корень,&Метка)==0, Метка.st_dev==Устройство, Метка.st_ino==Индекс else { удержание("UNKNOWN корень после \(Число)") }
    switch выполнить(Файл) {
    case .завершено: Число += 1; вывести("ЗАПИСАНО \(Номер)")
    case .без_изменения: вывести("БЕЗ_ИЗМЕНЕНИЯ \(Номер)")
    case .отказ_до_записи: удержание("UNKNOWN отказ после \(Число)")
    case .неизвестно: удержание("UNKNOWN запись после \(Число)")
    }
}
for Дескриптор in Владелец.дескрипторы.reversed() {
    вывести("CLOSE_START \(Дескриптор)")
    guard закрыть_один(Дескриптор) else { удержание("UNKNOWN close \(Дескриптор) после \(Число)") }
    вывести("CLOSE_DONE \(Дескриптор)")
}
вывести("СИНТЕТИЧЕСКИЙ_РЕЗУЛЬТАТ обновлено=\(Число)")
