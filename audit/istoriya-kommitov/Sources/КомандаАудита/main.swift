import Foundation
import Darwin
import АудиторИсторииКоммитов

@main
struct КомандаАудита {
    static func main() {
        let аргументы = Array(CommandLine.arguments.dropFirst())
        guard let разделитель = аргументы.firstIndex(of: "--"),
              разделитель >= 4, разделитель < аргументы.count - 1 else {
            let справка = "Использование: аудитор-истории-коммитов <репозиторий> <корневой-UUID> <OID-ROOT> <ограниченный-путь>... -- <OID-коммита>...\n"
            try? FileHandle.standardError.write(contentsOf: Data(справка.utf8))
            Darwin.exit(2)
        }
        do {
            let корень = URL(fileURLWithPath: аргументы[0], isDirectory: true)
            let корневойUUID = аргументы[1]
            let rootOID = аргументы[2]
            let области = Array(аргументы[3..<разделитель])
            let OIDКоммитов = Array(аргументы[(разделитель + 1)...])
            let читатель = ЧитательИстории(корень: корень)
            let отчёт = try АудиторИстории(читатель: читатель).проверить(
                корневойUUID: корневойUUID, принятыйROOTOID: rootOID,
                OIDКоммитов: OIDКоммитов, области: области)
            let кодировщик = JSONEncoder()
            кодировщик.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            var данные = try кодировщик.encode(отчёт)
            данные.append(0x0a)
            try FileHandle.standardOutput.write(contentsOf: данные)
        } catch {
            let строка = "Ошибка аудита: \(error)\n"
            try? FileHandle.standardError.write(contentsOf: Data(строка.utf8))
            Darwin.exit(1)
        }
    }
}
