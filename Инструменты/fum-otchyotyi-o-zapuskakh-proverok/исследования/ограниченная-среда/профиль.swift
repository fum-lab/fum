import Foundation

// Чистое построение данных не даёт допуска к процессу или Git.
enum ПрофильСреды {
    static let версия = "fum.ограниченная-среда-кандидат.1"
    static func создать(идентификатор: String) -> [String: String] {
        guard let значение = UUID(uuidString: идентификатор), значение.uuidString.lowercased() == идентификатор else { return [:] }
        return ["PATH": "/usr/bin:/bin", "LC_ALL": "C", "GIT_OPTIONAL_LOCKS": "0",
                "GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1",
                "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_ATTR_NOSYSTEM": "1",
                "FUM_CHECK_RUN_ID": идентификатор]
    }
}

enum ИсходПрофиля { case отказ, неизвестно }

// Входы являются только синтетическими байтами; они не свидетельствуют о файлах Git.
// Даже совпадение не допускает выполнение: источники, полная область и гонки не закреплены.
struct ПрофильGit {
    let локальнаяКонфигурация: Data
    let утверждённаяКонфигурация: Data
    let корневыеАтрибуты: Data?
    let служебныеАтрибуты: Data?
    let полныйСоставАтрибутовПодтверждён: Bool

    func проверить() -> ИсходПрофиля {
        guard локальнаяКонфигурация == утверждённаяКонфигурация,
              корневыеАтрибуты == nil, служебныеАтрибуты == nil else { return .отказ }
        return .неизвестно
    }
}
