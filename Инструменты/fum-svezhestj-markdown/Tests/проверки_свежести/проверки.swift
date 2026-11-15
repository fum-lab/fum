import Foundation
import Testing
import CryptoKit
import Darwin
@testable import адресная_свежесть

private func отпечаток(_ данные:Data)->String { SHA256.hash(data:данные).map { String(format:"%02x",$0) }.joined() }
@Test func отказ_close_не_считается_успехом() { #expect(!закрыть_один(-1)) }
@Test func формат_входа_ограничен_и_не_допускает_лишних_полей() throws {
 let тело=Data("# Пример\n".utf8), путь=Data("Проекты/ниокр/пример.md".utf8), время="2026-11-15 12:00:00 MSK"
 let вход="fum.адресная-свежесть.1\n\(время)\n1\n\(путь.base64EncodedString())\n\(тело.base64EncodedString())\n\(отпечаток(тело))\n\(время)\n"
 let разобранный=try разобрать_вход(Data(вход.utf8)); #expect(разобранный.файлы.count==1); #expect(разобранный.файлы[0].путь==путь)
 for неверный in [String(вход.dropLast()),вход+"лишнее\n",вход.replacingOccurrences(of:"\n1\n",with:"\n01\n"),вход.replacingOccurrences(of:"fum.адресная-свежесть.1",with:"fum.адресная-свежесть.2")] {
  #expect(throws:ошибка.self) { try разобрать_вход(Data(неверный.utf8)) }
 }
}
@Test func сохраняется_время_при_неизменном_теле() throws {
 let тело=Data("# Пример\n".utf8), прежнее="2026-11-15 12:00:00 MSK", новое="2026-11-15 13:00:00 MSK"
 let запись=try предпросмотр(тело,ожидаемый:отпечаток(тело),при_отсутствии:прежнее,сейчас:прежнее)
 let повтор=try предпросмотр(запись,ожидаемый:отпечаток(запись),при_отсутствии:новое,сейчас:новое)
 #expect(повтор==запись)
}
@Test func отклоняются_сложные_и_повреждённые_входы() throws {
 let время="2026-11-15 12:00:00 MSK"
 for текст in ["x\r\n", "x\0y\n", "```\u{301}\n", "<!--\u{301}содержимое -->\n", "FUM-MD-RECENCY поломан\n"] {
  let вход=Data(текст.utf8); #expect(throws:ошибка.self) { try предпросмотр(вход,ожидаемый:отпечаток(вход),при_отсутствии:время,сейчас:время) }
 }
}
@Test func план_не_принимает_повторы_и_общий_индекс() throws {
 let текст=Data("# Пример\n".utf8), время="2026-11-15 12:00:00 MSK"
 let файл=вход_файла(путь:Data("Проекты/ниокр/пример.md".utf8),исходные:текст,отпечаток:отпечаток(текст),при_отсутствии:время)
 #expect(throws:ошибка.self) { try составить_план([файл,файл],сейчас:время) }
 let индекс=вход_файла(путь:Data("Индексы/markdown-файлы-по-времени-редактирования.md".utf8),исходные:текст,отпечаток:отпечаток(текст),при_отсутствии:время)
 #expect(throws:ошибка.self) { try составить_план([индекс],сейчас:время) }
}
@Test func запись_требует_точный_исходник_и_сохраняет_соседа() throws {
 var шаблон=Array("/private/tmp/fum-recency-swift-test-XXXXXX".utf8CString)
 guard let адрес=mkdtemp(&шаблон) else { Issue.record("каталог"); return }
 let корень=String(cString:адрес); var известный_исход=false
 defer { if известный_исход { try? FileManager.default.removeItem(atPath:корень) } }
 let цель=корень+"/цель.md", сосед=корень+"/сосед.md", старое=Data("before\n".utf8), новое=Data("after\n".utf8)
 try старое.write(to:URL(fileURLWithPath:цель),options:.withoutOverwriting); try Data("neighbor\n".utf8).write(to:URL(fileURLWithPath:сосед),options:.withoutOverwriting)
 let дескриптор=open(цель,O_RDWR | O_NOFOLLOW | O_CLOEXEC); guard дескриптор>=0 else { Issue.record("open"); return }
 var сведения=stat(); guard fstat(дескриптор,&сведения)==0 else { Issue.record("stat"); return }
 let метка=метка_файла(устройство:сведения.st_dev,индекс:сведения.st_ino)
 var вызов=false
 let отказ=тестово_записать(дескриптор,метка:метка,исходные:Data("before?".utf8),новые:новое,_писать:{ _,_,_,_ in вызов=true; return -1 })
 guard case .отказ_до_записи = отказ else { Issue.record("отказ"); return }; #expect(!вызов)
 let без_изменения=тестово_записать(дескриптор,метка:метка,исходные:старое,новые:старое,_писать:{ _,_,_,_ in вызов=true; return -1 })
 guard case .без_изменения = без_изменения else { Issue.record("без изменения"); return }; #expect(!вызов)
 let исход=записать_по_дескриптору(дескриптор,метка:метка,исходные:старое,новые:новое)
 guard case .завершено = исход else { Issue.record("исход записи неизвестен"); return }
 #expect(try Data(contentsOf:URL(fileURLWithPath:цель))==новое)
 #expect(try Data(contentsOf:URL(fileURLWithPath:сосед))==Data("neighbor\n".utf8))
 guard close(дескриптор)==0 else { Issue.record("close unknown"); return }; известный_исход=true
}
@Test func перенос_родителя_показывает_границу_namespace() throws {
 var шаблон=Array("/private/tmp/fum-recency-namespace-XXXXXX".utf8CString)
 guard let адрес=mkdtemp(&шаблон) else { Issue.record("каталог"); return }
 let корень=String(cString:адрес), файловая=FileManager.default
 try файловая.createDirectory(atPath:корень+"/Индексы",withIntermediateDirectories:false)
 try файловая.createDirectory(atPath:корень+"/каталог",withIntermediateDirectories:false)
 try Data("index".utf8).write(to:URL(fileURLWithPath:корень+"/Индексы/markdown-файлы-по-времени-редактирования.md"),options:.withoutOverwriting)
 let старое=Data("body\n".utf8), время="2026-11-15 12:00:00 MSK"
 try старое.write(to:URL(fileURLWithPath:корень+"/каталог/цель.md"),options:.withoutOverwriting)
 let вход=вход_файла(путь:Data("каталог/цель.md".utf8),исходные:старое,отпечаток:отпечаток(старое),при_отсутствии:время)
 let план=try составить_план([вход],сейчас:время), корневой=open(корень,O_RDONLY|O_DIRECTORY|O_NOFOLLOW), владелец=владелец_дескрипторов()
 guard корневой>=0 else { Issue.record("open root"); return }
 let файл=try привязать(план,корень:корневой,владелец:владелец)[0]
 try файловая.moveItem(atPath:корень+"/каталог",toPath:корень+"/отсоединённый")
 guard case .завершено = выполнить(файл) else { Issue.record("запись UNKNOWN"); return }
 #expect(!файловая.fileExists(atPath:корень+"/каталог/цель.md"))
 #expect(try Data(contentsOf:URL(fileURLWithPath:корень+"/отсоединённый/цель.md")) != старое)
 for дескриптор in владелец.дескрипторы.reversed() { guard close(дескриптор)==0 else { Issue.record("close UNKNOWN"); return } }
 guard close(корневой)==0 else { Issue.record("close root UNKNOWN"); return }
 try файловая.removeItem(atPath:корень)
}
