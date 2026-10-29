import Foundation

enum ВидУзлаПеречняАдресов: String, Sendable {
    case определение, встроенная, полная, свёрнутая, сокращённая, неподдержанный
}
struct УзелПеречняАдресов: Sendable {
    let номер: Int
    let вид: ВидУзлаПеречняАдресов
    let целиком: Range<Int>
    let адрес: Range<Int>?
    let подпись: Range<Int>?
    let метка: Range<Int>?
    let ключМетки: String?
    let определения: [Int]
    let изображение: Bool
    let эвристическиЗащищён: Bool
    let неподдержанныйКонтейнер: Bool
}
struct ОшибкаПеречняАдресов: Sendable {
    let код: String
    let диапазон: Range<Int>
}
struct ПределыПеречняАдресов: Sendable {
    var байты = 33_554_432
    var строки = 65_536
    var узлы = 16_384
    var ошибки = 16_384
    var шаги = 67_108_864
}
struct ПереченьАдресовДокумента: Sendable {
    let путь: String
    let заявленныйХэш: String
    let размер: Int
    let хэшПроверен: Bool
    let обходЗавершён: Bool
    let синтаксисПолностьюРаспознан: Bool
    let узлы: [УзелПеречняАдресов]
    let ошибки: [ОшибкаПеречняАдресов]
    let неизвестныеДиапазоны: [Range<Int>]
    let скрытыеДиапазоны: [Range<Int>]
    let эвристическиЗащищённыеДиапазоны: [Range<Int>]
    let неподдержанныеКонтейнеры: [Range<Int>]
    let ролиПроверены = false
    let разрешениеЦелейПроверено = false
    let применениеРазрешено = false
}
