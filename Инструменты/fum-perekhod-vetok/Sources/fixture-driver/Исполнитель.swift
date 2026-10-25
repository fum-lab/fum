import Foundation
import Darwin
import ПереходВеток

enum ОшибкаТранспортаФикстуры: Error {
    case вход(String)
}
/// Только открытая одноразовая фикстура: останавливает собственный процесс в выбранном crash-окне.
@main struct ИсполнительФикстуры {
    static func main() async {
        do {
            try await запустить()
        } catch {
            let транспорт = error is ОшибкаТранспортаФикстуры
            let данные = try? JSONEncoder().encode([
                "схема": транспорт ? "fum.ошибка-транспорта-фикстуры.1" : "fum.ошибка-фикстурного-исполнителя.1",
                "сообщение": String(describing: error)
            ])
            FileHandle.standardError.write(данные ?? Data())
            exit(транспорт ? 3 : 2)
        }
    }
    static func запустить() async throws {
        let аргументы = Array(CommandLine.arguments.dropFirst())
        guard аргументы.count == 5 else { throw ОшибкаТранспортаФикстуры.вход("ожидались план, ресурс корня, окно, маркер и действие") }
        let действие = аргументы[4]
        guard ["переименовать", "сверить", "подготовить-протокол", "переименовать-читающим"].contains(действие) else {
            throw ОшибкаТранспортаФикстуры.вход("неизвестное действие фикстуры")
        }
        let план: План
        let ресурс: Ресурс
        do {
            план = try JSONDecoder().decode(План.self, from: Data(contentsOf: URL(fileURLWithPath: аргументы[0])))
            ресурс = try JSONDecoder().decode(Ресурс.self, from: Data(contentsOf: URL(fileURLWithPath: аргументы[1])))
        } catch { throw ОшибкаТранспортаФикстуры.вход(String(describing: error)) }
        let переход = try ПереходВетки(план: план, выборКорня: ресурс, наблюдатель: { фаза in
            if аргументы[2] == "ошибка:" + фаза {
                throw ОшибкаПерехода.отказ("имитация остановки после сохранённой границы")
            }
            if фаза == аргументы[2] {
                let файл = open(аргументы[3], O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
                guard файл >= 0 else { throw ОшибкаПерехода.отказ("не удалось создать маркер остановки") }
                fsync(файл); close(файл)
                raise(SIGSTOP)
            }
        }, создатьПротокол: !["сверить", "переименовать-читающим"].contains(действие))
        if действие == "подготовить-протокол" {
            FileHandle.standardOutput.write(try JSONEncoder().encode([
                "схема": "fum.подготовка-фикстурного-протокола.1", "состояние": "готов"
            ]))
            return
        }
        let результат: РезультатПерехода
        if действие == "сверить" { результат = try await переход.сверить() }
        else { результат = try await переход.переименовать() }
        FileHandle.standardOutput.write(try JSONEncoder().encode(результат))
    }
}
