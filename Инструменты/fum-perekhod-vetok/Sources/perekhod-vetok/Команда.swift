import Foundation
import Darwin
import ПереходВеток

@main struct Команда {
    static func main() async {
        do {
            let ответ = try await ИнтерфейсПерехода.выполнить(Array(CommandLine.arguments.dropFirst()))
            FileHandle.standardOutput.write(ответ + Data([10]))
        } catch {
            FileHandle.standardError.write(Data((String(describing: error) + "\n").utf8))
            exit(2)
        }
    }
}
