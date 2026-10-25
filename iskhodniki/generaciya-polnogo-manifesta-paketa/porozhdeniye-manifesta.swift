import Foundation

enum ГенераторМанифеста {
    static func строка(_ значение: String) -> String { String(reflecting: значение) }
    static func список(_ значения: [String]) -> String { "[" + значения.map(строка).joined(separator: ", ") + "]" }

    static func текст(_ описание: ОписаниеПакета) -> Data {
        var строки = ["// swift-tools-version: 6.0", "import PackageDescription", "", "let package = Package(",
                      "    name: \(строка(описание.имя)),",
                      "    platforms: [" + описание.платформы.map { ".\($0.платформа.rawValue)(\(строка($0.версия)))" }.joined(separator: ", ") + "],",
                      "    products: ["]
        for продукт in описание.продукты {
            if продукт.вид == .исполняемый {
                строки.append("        .executable(name: \(строка(продукт.имя)), targets: \(список(продукт.цели))),")
            } else {
                let вид = продукт.вид == .статическая ? ", type: .static" : продукт.вид == .динамическая ? ", type: .dynamic" : ""
                строки.append("        .library(name: \(строка(продукт.имя))\(вид), targets: \(список(продукт.цели))),")
            }
        }
        строки += ["    ],", "    dependencies: ["]
        for пакет in описание.зависимости { строки.append("        .package(name: \(строка(пакет.имя)), path: \(строка(пакет.путь))),") }
        строки += ["    ],", "    targets: ["]
        for цель in описание.цели {
            let вид = цель.вид == .обычная ? "target" : цель.вид == .исполняемая ? "executableTarget" : "testTarget"
            let зависимости = цель.зависимости.map { зависимость in
                if let имя = зависимость.цель { return ".target(name: \(строка(имя)))" }
                return ".product(name: \(строка(зависимость.продукт!)), package: \(строка(зависимость.пакет!)))"
            }
            строки += ["        .\(вид)(name: \(строка(цель.имя)),", "            dependencies: [\(зависимости.joined(separator: ", "))],",
                       "            path: \(строка(цель.путь)),", "            exclude: \(список(цель.исключения)),"]
            if let исходники = цель.исходники { строки.append("            sources: \(список(исходники)),") }
            if !цель.ресурсы.isEmpty {
                строки.append("            resources: [" + цель.ресурсы.map { ".\($0.вид == .обработать ? "process" : "copy")(\(строка($0.путь)))" }.joined(separator: ", ") + "],")
            }
            строки.append("            swiftSettings: [")
            for определение in цель.определения { строки.append("                .define(\(строка(определение))),") }
            строки += ["                .swiftLanguageMode(.v6),",
                       "                .unsafeFlags([\"-strict-concurrency=complete\", \"-warnings-as-errors\", \"-enable-actor-data-race-checks\"])",
                       "            ]),"]
        }
        строки += ["    ],", "    swiftLanguageModes: [.v6]", ")", ""]
        return Data(строки.joined(separator: "\n").utf8)
    }

    static func разница(_ прежний: Data, _ новый: Data) throws -> String {
        if прежний == новый { return "" }
        guard String(data: прежний, encoding: .utf8) != nil, String(data: новый, encoding: .utf8) != nil else {
            throw ОшибкаМанифеста(код: "не-utf8-манифест")
        }
        func строки(_ данные: Data, знак: String) -> (тело: [String], число: Int) {
            if данные.isEmpty { return ([], 0) }
            var части = данные.split(separator: 10, omittingEmptySubsequences: false)
            if данные.last == 10 { части.removeLast() }
            let число = части.count
            var результат = части.map { знак + String(decoding: $0, as: UTF8.self) }
            if данные.last != 10 { результат.append("\\ No newline at end of file") }
            return (результат, число)
        }
        let до = строки(прежний, знак: "-"); let после = строки(новый, знак: "+")
        return (["--- a/Package.swift", "+++ b/Package.swift", "@@ -\(до.число == 0 ? 0 : 1),\(до.число) +1,\(после.число) @@"] + до.тело + после.тело).joined(separator: "\n") + "\n"
    }

    static func породить(_ описание: ОписаниеПакета, корень: URL,
                         прежний: Data = Data(), карта: Data? = nil,
                         хэшКарты: String? = nil) throws -> РезультатМанифеста {
        try ПроверкаМанифеста.структура(описание)
        let исходники = try ПроверкаМанифеста.файлы(описание, корень: корень)
        let выбранное = try ОтображениеМанифеста.применить(описание, карта: карта, ожидаемыйХэш: хэшКарты,
            исходники: исходники.исходники, инвентарь: исходники.все, корень: корень)
        try ПроверкаМанифеста.структура(выбранное)
        let байты = текст(выбранное)
        return РезультатМанифеста(байты: байты, описание: выбранное,
            хэшПрежнегоМанифеста: хэшМанифеста(прежний), хэшНовогоМанифеста: хэшМанифеста(байты),
            хэшИспользованнойКарты: карта.map(хэшМанифеста), текстРазницы: try разница(прежний, байты))
    }
}
