import Foundation
import Darwin

#if ФУМ_КОМАНДА_МАНИФЕСТА
@main enum КомандаМанифеста {
    static func main() {
        do {
            let аргументы = Array(CommandLine.arguments.dropFirst())
            try требоватьМанифест(!аргументы.isEmpty && (аргументы.count - 1).isMultiple(of: 2), "неверная-команда")
            let режим = аргументы[0]
            try требоватьМанифест(["породить", "diff", "описание", "профиль"].contains(режим), "неизвестная-команда")
            var поля: [String: String] = [:]
            for номер in stride(from: 1, to: аргументы.count, by: 2) {
                let ключ = аргументы[номер]
                try требоватьМанифест(["--корень", "--описание", "--карта", "--sha256-карты"].contains(ключ)
                    && поля[ключ] == nil, "неверный-параметр")
                поля[ключ] = аргументы[номер + 1]
            }
            guard let адрес = поля["--корень"], let вход = поля["--описание"] else { throw ОшибкаМанифеста(код: "нужны-корень-и-описание") }
            let корень = URL(fileURLWithPath: адрес)
            let данные = try Data(contentsOf: URL(fileURLWithPath: вход))
            let описание = try ОписаниеПакета.прочитать(данные)
            let карта = try поля["--карта"].map { try Data(contentsOf: URL(fileURLWithPath: $0)) }
            let результат: Data
            if режим == "профиль" {
                try требоватьМанифест(карта == nil && поля["--sha256-карты"] == nil, "профиль-без-карты")
                результат = try ПрофильМанифеста.измерить(данные, корень: корень)
            } else {
                let чтение = try ЧитательПутейМанифеста(корень)
                var прежний = Data()
                if FileManager.default.fileExists(atPath: корень.appendingPathComponent("Package.swift").path) {
                    try требоватьМанифест(try !чтение.каталог("Package.swift"), "не-файл-манифеста")
                    прежний = try Data(contentsOf: корень.appendingPathComponent("Package.swift"))
                }
                let порождённое = try ГенераторМанифеста.породить(описание, корень: корень, прежний: прежний,
                    карта: карта, хэшКарты: поля["--sha256-карты"])
                switch режим {
                case "diff": результат = Data(порождённое.текстРазницы.utf8)
                case "описание": результат = try порождённое.описание.байты()
                default: результат = порождённое.байты
                }
            }
            try FileHandle.standardOutput.write(contentsOf: результат)
        } catch {
            let код = (error as? ОшибкаМанифеста)?.код ?? "неверный-или-недоступный-вход"
            try? FileHandle.standardError.write(contentsOf: Data((код + "\n").utf8))
            exit(2)
        }
    }
}
#endif
