import Foundation
import Testing
import CryptoKit
import Darwin
@testable import адресная_свежесть

private func отпечаток(_ Данные:Data)->String { SHA256.hash(data:Данные).map { String(format:"%02x",$0) }.joined() }
@Test func отказ_close_не_считается_успехом() { #expect(!закрыть_один(-1)) }
@Test func формат_входа_ограничен_и_не_допускает_лишних_полей() throws {
 let Тело=Data("# Пример\n".utf8), Путь=Data("Проекты/ниокр/пример.md".utf8), Время="2026-11-15 12:00:00 MSK"
 let Вход="fum.адресная-свежесть.1\n\(Время)\n1\n\(Путь.base64EncodedString())\n\(Тело.base64EncodedString())\n\(отпечаток(Тело))\n\(Время)\n"
 let Разобранный=try разобрать_вход(Data(Вход.utf8)); #expect(Разобранный.файлы.count==1); #expect(Разобранный.файлы[0].путь==Путь)
 for Неверный in [String(Вход.dropLast()),Вход+"лишнее\n",Вход.replacingOccurrences(of:"\n1\n",with:"\n01\n"),Вход.replacingOccurrences(of:"fum.адресная-свежесть.1",with:"fum.адресная-свежесть.2")] {
  #expect(throws:ошибка.self) { try разобрать_вход(Data(Неверный.utf8)) }
 }
}
@Test func сохраняется_время_при_неизменном_теле() throws {
 let Тело=Data("# Пример\n".utf8), Прежнее="2026-11-15 12:00:00 MSK", Новое="2026-11-15 13:00:00 MSK"
 let Запись=try предпросмотр(Тело,ожидаемый:отпечаток(Тело),при_отсутствии:Прежнее,сейчас:Прежнее)
 let Повтор=try предпросмотр(Запись,ожидаемый:отпечаток(Запись),при_отсутствии:Новое,сейчас:Новое)
 #expect(Повтор==Запись)
}
@Test func отклоняются_сложные_и_повреждённые_входы() throws {
 let Время="2026-11-15 12:00:00 MSK"
 for Текст in ["x\r\n", "x\0y\n", "```\u{301}\n", "<!--\u{301}содержимое -->\n", "FUM-MD-RECENCY поломан\n"] {
  let Вход=Data(Текст.utf8); #expect(throws:ошибка.self) { try предпросмотр(Вход,ожидаемый:отпечаток(Вход),при_отсутствии:Время,сейчас:Время) }
 }
}
@Test func план_не_принимает_повторы_и_общий_индекс() throws {
 let Текст=Data("# Пример\n".utf8), Время="2026-11-15 12:00:00 MSK"
 let Файл=вход_файла(путь:Data("Проекты/ниокр/пример.md".utf8),исходные:Текст,отпечаток:отпечаток(Текст),при_отсутствии:Время)
 #expect(throws:ошибка.self) { try составить_план([Файл,Файл],сейчас:Время) }
 let Индекс=вход_файла(путь:Data("Индексы/markdown-файлы-по-времени-редактирования.md".utf8),исходные:Текст,отпечаток:отпечаток(Текст),при_отсутствии:Время)
 #expect(throws:ошибка.self) { try составить_план([Индекс],сейчас:Время) }
}
@Test func запись_требует_точный_исходник_и_сохраняет_соседа() throws {
 var Шаблон=Array("/private/tmp/fum-recency-swift-test-XXXXXX".utf8CString)
 guard let Адрес=mkdtemp(&Шаблон) else { Issue.record("каталог"); return }
 let Корень=String(cString:Адрес); var Известный_исход=false
 defer { if Известный_исход { try? FileManager.default.removeItem(atPath:Корень) } }
 let Цель=Корень+"/цель.md", Сосед=Корень+"/сосед.md", Старое=Data("before\n".utf8), Новое=Data("after\n".utf8)
 try Старое.write(to:URL(fileURLWithPath:Цель),options:.withoutOverwriting); try Data("neighbor\n".utf8).write(to:URL(fileURLWithPath:Сосед),options:.withoutOverwriting)
 let Дескриптор=open(Цель,O_RDWR | O_NOFOLLOW | O_CLOEXEC); guard Дескриптор>=0 else { Issue.record("open"); return }
 var Сведения=stat(); guard fstat(Дескриптор,&Сведения)==0 else { Issue.record("stat"); return }
 let Метка=метка_файла(устройство:Сведения.st_dev,индекс:Сведения.st_ino)
 var Вызов=false
 let Отказ=тестово_записать(Дескриптор,метка:Метка,исходные:Data("before?".utf8),новые:Новое,_писать:{ _,_,_,_ in Вызов=true; return -1 })
 guard case .отказ_до_записи = Отказ else { Issue.record("отказ"); return }; #expect(!Вызов)
 let Без_изменения=тестово_записать(Дескриптор,метка:Метка,исходные:Старое,новые:Старое,_писать:{ _,_,_,_ in Вызов=true; return -1 })
 guard case .без_изменения = Без_изменения else { Issue.record("без изменения"); return }; #expect(!Вызов)
 let Исход=записать_по_дескриптору(Дескриптор,метка:Метка,исходные:Старое,новые:Новое)
 guard case .завершено = Исход else { Issue.record("исход записи неизвестен"); return }
 #expect(try Data(contentsOf:URL(fileURLWithPath:Цель))==Новое)
 #expect(try Data(contentsOf:URL(fileURLWithPath:Сосед))==Data("neighbor\n".utf8))
 guard close(Дескриптор)==0 else { Issue.record("close unknown"); return }; Известный_исход=true
}
@Test func перенос_родителя_показывает_границу_namespace() throws {
 var Шаблон=Array("/private/tmp/fum-recency-namespace-XXXXXX".utf8CString)
 guard let Адрес=mkdtemp(&Шаблон) else { Issue.record("каталог"); return }
 let Корень=String(cString:Адрес), Файловая=FileManager.default
 try Файловая.createDirectory(atPath:Корень+"/Индексы",withIntermediateDirectories:false)
 try Файловая.createDirectory(atPath:Корень+"/каталог",withIntermediateDirectories:false)
 try Data("index".utf8).write(to:URL(fileURLWithPath:Корень+"/Индексы/markdown-файлы-по-времени-редактирования.md"),options:.withoutOverwriting)
 let Старое=Data("body\n".utf8), Время="2026-11-15 12:00:00 MSK"
 try Старое.write(to:URL(fileURLWithPath:Корень+"/каталог/цель.md"),options:.withoutOverwriting)
 let Вход=вход_файла(путь:Data("каталог/цель.md".utf8),исходные:Старое,отпечаток:отпечаток(Старое),при_отсутствии:Время)
 let План=try составить_план([Вход],сейчас:Время), Корневой=open(Корень,O_RDONLY|O_DIRECTORY|O_NOFOLLOW), Владелец=владелец_дескрипторов()
 guard Корневой>=0 else { Issue.record("open root"); return }
 let Файл=try привязать(План,корень:Корневой,владелец:Владелец)[0]
 try Файловая.moveItem(atPath:Корень+"/каталог",toPath:Корень+"/отсоединённый")
 guard case .завершено = выполнить(Файл) else { Issue.record("запись UNKNOWN"); return }
 #expect(!Файловая.fileExists(atPath:Корень+"/каталог/цель.md"))
 #expect(try Data(contentsOf:URL(fileURLWithPath:Корень+"/отсоединённый/цель.md")) != Старое)
 for Дескриптор in Владелец.дескрипторы.reversed() { guard close(Дескриптор)==0 else { Issue.record("close UNKNOWN"); return } }
 guard close(Корневой)==0 else { Issue.record("close root UNKNOWN"); return }
 try Файловая.removeItem(atPath:Корень)
}
