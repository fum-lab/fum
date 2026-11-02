import AppKit
import CoreGraphics
import Foundation
import Observation
import SwiftUI
import ЭталонКлавиатуры
import ЦиклОператора

@MainActor
@Observable
private final class МодельОкна {
    var вход = "ёж"
    var определение = """
    {
      "схема": "fum.определение-оператора.1",
      "идентификатор": "prefix-example",
      "версия": 1,
      "правила": [],
      "шаги": [
        {
          "идентификатор": "добавить-префикс",
          "оператор": "префикс",
          "аргументы": { "текст": "FUM: " }
        }
      ]
    }
    """
    var состояние = СостояниеЦиклаФУМА()
    var выполняется = false
    private let владелецТекста = ВладелецТекстаСценыФУМА()
    private let владелецПривязкиВида = ВладелецПривязкиВидаФУМА()
    private(set) var отображаемыйВводКлавиатуры = ""
    var ошибкаКлавиатуры: String?

    private let цикл = ЦиклОператора()
    private let владелецКлавиатурногоАдаптера = ВладелецКлавиатурногоАдаптера()
    private var физическоеОкно: ObjectIdentifier?
    private var идентификаторВводаОкна = ИдентификаторОкнаВвода(rawValue: UUID())
    private var поколенияФокусаПоОкнам: [UUID: UInt64] = [:]
    private var подтверждённыйФокусКлавиатуры: (окно: UUID, фокус: UUID, поколение: UInt64)?
    private var focusConfirmed = false
    private let дедупликаторНативныхСобытий = ДедупликаторЭкземпляровНативныхСобытий()
    private var номерНаблюденияОбласти = 0
    private var номерНаблюденияРамки = 0
    private var очередьСостояния: Task<Void, Never>?

    func привязатьКлавиатурныйВид(_ view: NSView) -> ТокенПривязкиВидаФУМА {
        let sameView = владелецПривязкиВида.текущаяПривязка(для: view) != nil
        let token = владелецПривязкиВида.привязать(view)
        if !sameView {
            деактивироватьКлавиатуру()
            _ = обновитьФизическоеОкно(nil)
        }
        return token
    }

    func актуальнаПривязка(_ token: ТокенПривязкиВидаФУМА, для view: NSView) -> Bool {
        владелецПривязкиВида.являетсяТекущей(token, для: view)
    }

    func принятьРазмерКонтентнойОбласти(_ размер: CGSize) {
        номерНаблюденияОбласти += 1
        let номер = номерНаблюденияОбласти
        let ширина = Double(размер.width)
        let высота = Double(размер.height)
        сериализоватьСостояние { [weak self] in
            guard let self else { return }
            let событие: СобытиеНаблюденияРазмеров = self.состояние.область == nil
                ? .первоначальноеНаблюдение
                : .изменениеРазмера
            let наблюдение = НаблюдениеКонтентнойОбласти(
                номер: номер,
                ширина: ширина,
                высота: высота,
                единица: .пункты,
                источник: .роднаяГеометрия,
                событие: событие
            )
            self.состояние.применитьЕслиНовее(await self.цикл.наблюдатьКонтентнуюОбласть(наблюдение))
        }
    }

    func принятьРамкуОкна(_ frame: CGRect, событие: СобытиеНаблюденияРамки) {
        номерНаблюденияРамки += 1
        let номер = номерНаблюденияРамки
        let наблюдение = НаблюдениеРамкиОкна(
            номер: номер,
            x: Double(frame.origin.x),
            y: Double(frame.origin.y),
            ширина: Double(frame.size.width),
            высота: Double(frame.size.height),
            единица: .пункты,
            источник: .окноПриложения,
            событие: событие,
            моментНаблюденияНс: DispatchTime.now().uptimeNanoseconds
        )
        сериализоватьСостояние { [weak self] in
            guard let self else { return }
            self.состояние.применитьЕслиНовее(await self.цикл.наблюдатьРамкуОкна(наблюдение))
        }
    }

    func начатьШаг() {
        guard !выполняется else { return }
        выполняется = true
        let вход = вход
        let определение = определение
        сериализоватьСостояние { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.цикл.выполнитьОдинШаг(вход: вход, определение: определение)
            } catch {
                // Ошибка уже сохранена в общем состоянии и истории FUMA.
            }
            self.состояние.применитьЕслиНовее(await self.цикл.снимок())
            self.выполняется = false
        }
    }

    @discardableResult
    func обновитьФизическоеОкно(_ window: NSWindow?) -> Bool {
        let identity = window.map { ObjectIdentifier($0) }
        guard физическоеОкно != identity else { return true }

        let новыйИдентификатор = ИдентификаторОкнаВвода(rawValue: UUID())
        if window != nil,
           поколенияФокусаПоОкнам[новыйИдентификатор.rawValue] == nil,
           поколенияФокусаПоОкнам.count >= 4096 {
            ошибкаКлавиатуры = "Достигнут предел сохранённых окон; новое окно закрыто для ввода."
            деактивироватьКлавиатуру()
            физическоеОкно = nil
            return false
        }
        do {
            let результат = try владелецТекста.установитьОкно(
                window == nil ? nil : новыйИдентификатор.rawValue
            )
            focusConfirmed = false
            подтверждённыйФокусКлавиатуры = nil
            владелецКлавиатурногоАдаптера.деактивировать()
            физическоеОкно = identity
            идентификаторВводаОкна = новыйИдентификатор
            if window != nil {
                поколенияФокусаПоОкнам[новыйИдентификатор.rawValue] = 0
            }
            владелецКлавиатурногоАдаптера.выбратьОкно(новыйИдентификатор)
            if результат == .отложено || результат == .очередьПереполнена {
                ошибкаКлавиатуры = "Смена окна отложена или очередь переполнена; исход действия неизвестен."
                return true
            }
            ошибкаКлавиатуры = nil
            return true
        } catch {
            деактивироватьКлавиатуру()
            физическоеОкно = nil
            ошибкаКлавиатуры = "Не удалось закрепить переход собственного окна: \(String(reflecting: error))"
            return false
        }
    }

    func идентификаторОкнаДляКлавиатуры(_ window: NSWindow) -> ИдентификаторОкнаВвода? {
        guard физическоеОкно == ObjectIdentifier(window) else { return nil }
        return идентификаторВводаОкна
    }

    func подтвердитьФокусКлавиатуры(в window: NSWindow, виде view: NSView) -> Bool {
        guard window.firstResponder === view,
              let identifier = идентификаторОкнаДляКлавиатуры(window) else { return false }
        if focusConfirmed, подтверждённыйФокусКлавиатуры?.окно == identifier.rawValue {
            return true
        }
        guard let generation = поколенияФокусаПоОкнам[identifier.rawValue] else { return false }
        let next = generation.addingReportingOverflow(1)
        guard !next.overflow else {
            ошибкаКлавиатуры = "Переполнено поколение фокуса; ввод закрыт."
            return false
        }
        let focus = UUID()
        let timestamp = DispatchTime.now().uptimeNanoseconds
        // Резервируем поколение до двух синхронных подтверждений. При отказе оно
        // не переиспользуется; следующий настоящий focus callback получит новое.
        поколенияФокусаПоОкнам[identifier.rawValue] = next.partialValue
        do {
            try владелецТекста.подтвердитьФокус(
                окно: identifier.rawValue, фокус: focus, поколение: next.partialValue
            )
            guard try владелецКлавиатурногоАдаптера.подтвердитьФокус(
                окно: identifier,
                фокус: ИдентификаторФокусаВвода(rawValue: focus),
                поколение: next.partialValue,
                снимокМодификаторов: .пустое,
                моментНаблюденияНс: timestamp
            ) else {
                владелецТекста.отозватьФокус(
                    окно: identifier.rawValue, фокус: focus, поколение: next.partialValue
                )
                return false
            }
            подтверждённыйФокусКлавиатуры = (identifier.rawValue, focus, next.partialValue)
            focusConfirmed = true
            return true
        } catch {
            владелецТекста.отозватьФокус(
                окно: identifier.rawValue, фокус: focus, поколение: next.partialValue
            )
            ошибкаКлавиатуры = "Не удалось подтвердить фокус до клавиши: \(String(reflecting: error))"
            return false
        }
    }

    func зарезервироватьЭкземплярНативногоСобытия(_ событие: AnyObject) -> Bool {
        дедупликаторНативныхСобытий.принять(событие)
    }

    func обработатьПростуюКлавишу(
        код: Int64,
        символСобытия: String?,
        повтор: Bool,
        моментНаблюденияНс: UInt64,
        идентификаторИсточника: String?,
        естьРазмеченнаяКомпозиция: Bool,
        модификаторы: ФлагиМодификаторовТекстовогоВвода,
        окно: NSWindow
    ) throws -> СобытиеСРезультатомКлавиатуры? {
        guard focusConfirmed, идентификаторОкнаДляКлавиатуры(окно) != nil else { return nil }
        return try владелецКлавиатурногоАдаптера.обработатьПростуюКлавишу(
            код: код,
            символСобытия: символСобытия,
            повтор: повтор,
            моментНаблюденияНс: моментНаблюденияНс,
            идентификаторИсточника: идентификаторИсточника,
            естьРазмеченнаяКомпозиция: естьРазмеченнаяКомпозиция,
            модификаторы: модификаторы
        )
    }

    func деактивироватьКлавиатуру() {
        if let focus = подтверждённыйФокусКлавиатуры {
            let результат = владелецТекста.отозватьФокус(
                окно: focus.окно, фокус: focus.фокус, поколение: focus.поколение
            )
            if результат == .отложен {
                ошибкаКлавиатуры = "Фокус отзывается после обработчика; исход внешнего действия неизвестен."
            } else if результат == .очередьПереполнена {
                ошибкаКлавиатуры = "Очередь отзыва фокуса переполнена; ввод закрыт с неизвестным исходом."
            } else if результат == .неСовпал {
                ошибкаКлавиатуры = "Состояние фокуса изменилось; ввод закрыт до нового подтверждения."
            }
        }
        подтверждённыйФокусКлавиатуры = nil
        focusConfirmed = false
        владелецКлавиатурногоАдаптера.деактивировать()
    }

    func принятьРезультатВладельцемТекста(
        _ наблюдение: СобытиеСРезультатомКлавиатуры
    ) -> String? {
        let событие = наблюдение.событие
        let результат = наблюдение.результат
        let основа = владелецТекста.снимок
        var текст = основа.текст
        var выделение = основа.выделениеUTF16

        switch результат.вывод {
        case .текст(let вставка, источник: .fuma):
            guard let edit = РедакторТекстаКлавиатуры.вставить(
                вставка, в: основа.текст, выделениеUTF16: основа.выделениеUTF16
            ) else { return "Редактор отклонил UTF-16 выделение; событие не повторено." }
            текст = edit.текст
            выделение = edit.выделениеUTF16
        case .команда("удалить-назад"):
            guard let edit = РедакторТекстаКлавиатуры.удалитьНазад(
                из: основа.текст, выделениеUTF16: основа.выделениеUTF16
            ) else { return "Редактор отклонил удаление; событие не повторено." }
            текст = edit.текст
            выделение = edit.выделениеUTF16
        case .нет:
            break
        case .текст, .составленныйIMEТекст, .команда:
            return "Результат адаптера вне ограниченного FUMA текстового пути; событие не повторено."
        }

        let свидетельство = событие.свидетельство
        do {
            try владелецТекста.принять(
                идентификаторОкна: свидетельство.окно.rawValue,
                идентификаторФокуса: свидетельство.фокус.rawValue,
                поколениеФокуса: свидетельство.поколениеФокуса,
                идентификаторСобытия: событие.идентификатор.rawValue,
                порядок: свидетельство.порядок,
                текст: текст,
                выделениеUTF16: выделение
            )
            отображаемыйВводКлавиатуры = владелецТекста.снимок.текст
            ошибкаКлавиатуры = nil
            return nil
        } catch {
            return "Переход текста атомарно отклонён; повтор события запрещён: \(String(reflecting: error))"
        }
    }

    func записатьКлавиатурноеСобытие(_ наблюдение: СобытиеСРезультатомКлавиатуры) {
        сериализоватьСостояние { [weak self] in
            guard let self else { return }
            let новое = await self.цикл.записатьРезультатКлавиатуры(наблюдение)
            self.состояние.применитьЕслиНовее(новое)
        }
    }

    func записатьОшибкуКлавиатуры(_ описание: String) {
        ошибкаКлавиатуры = описание
        сериализоватьСостояние { [weak self] in
            guard let self else { return }
            let новое = await self.цикл.записатьОшибкуКлавиатуры(описание)
            self.состояние.применитьЕслиНовее(новое)
        }
    }

    private func сериализоватьСостояние(_ действие: @escaping @MainActor () async -> Void) {
        let предыдущаяОчередь = очередьСостояния
        очередьСостояния = Task { @MainActor in
            await предыдущаяОчередь?.value
            await действие()
        }
    }
}

@main
@MainActor
private struct ПриложениеМинимальногоИнтерфейсаFUMA: App {
    var body: some Scene {
        WindowGroup("FUMA · один шаг") {
            ГлавноеОкно()
                .frame(minWidth: 360, minHeight: 500)
        }
    }
}

@MainActor
private struct ГлавноеОкно: View {
    @State private var модель = МодельОкна()

    var body: some View {
        GeometryReader { прокси in
            ScrollView {
                панели
                    .padding(модель.состояние.раскладка?.компактнаяВысота == true ? 10 : 20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .onChange(of: прокси.size, initial: true) { _, новыйРазмер in
                модель.принятьРазмерКонтентнойОбласти(новыйРазмер)
            }
            .background {
                НаблюдательРамкиОкна { frame, событие in
                    модель.принятьРамкуОкна(frame, событие: событие)
                }
                .frame(width: 1, height: 1)
                .allowsHitTesting(false)
                .opacity(0)
            }
        }
    }

    @ViewBuilder
    private var панели: some View {
        let controls = панельДействия
        let outcome = панельСостояния
        if модель.состояние.раскладка?.числоКолонок == 2 {
            HStack(alignment: .top, spacing: 16) {
                controls.frame(maxWidth: .infinity, alignment: .topLeading)
                outcome.frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            VStack(alignment: .leading, spacing: 14) {
                controls
                outcome
            }
        }
    }

    private var панельДействия: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Цикл FUMA")
                .font(.largeTitle.bold())
            Text("Программа · ровно один простой оператор")
                .font(.headline)
            TextEditor(text: $модель.определение)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 230)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
            TextField("Текстовый вход программы", text: $модель.вход)
                .textFieldStyle(.roundedBorder)
            Button("Выполнить один шаг", action: модель.начатьШаг)
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(модель.выполняется)

            Text("Физический ввод через ЭталонКлавиатуры · QWERTY v1")
                .font(.headline)
            ZStack(alignment: .topLeading) {
                ТекстовоеПолеВводаФУМА(текст: модель.отображаемыйВводКлавиатуры, модель: модель)
                if модель.отображаемыйВводКлавиатуры.isEmpty {
                    Text("Щёлкните и введите текст")
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 88)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
            if let ошибка = модель.ошибкаКлавиатуры {
                Text("Ошибка клавиатуры: \(ошибка)")
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
            Text("Принимаются только поддерживаемые клавиши US без модификаторов и IME; остальные события не вставляются и не передаются нативному текстовому клиенту. Подключена только QWERTY v1.")
                .font(.caption)
        }
    }

    private var панельСостояния: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Состояние FUMA")
                .font(.headline)
            if модель.выполняется { Text("Исполняется один шаг…") }
            Text("Действия программы: \(модель.состояние.числоДействийПользователя) · вызовы AutomationExecutor: \(модель.состояние.числоВызововИсполнителя)")
                .textSelection(.enabled)

            if let область = модель.состояние.область, let раскладка = модель.состояние.раскладка {
                Text("Content viewport: \(область.ширина) × \(область.высота) points")
                    .font(.subheadline)
                    .textSelection(.enabled)
                Text("Источник: \(область.источник.rawValue) · событие: \(область.событие.rawValue)")
                    .font(.caption)
                Text("Раскладка интерфейса: \(раскладка.числоКолонок) колонки · компактная высота: \(раскладка.компактнаяВысота ? "да" : "нет")")
                Text("Измерений viewport принято: \(модель.состояние.принятоНаблюденийГеометрии) · отклонено: \(модель.состояние.отклоненоНаблюденийГеометрии)")
                    .font(.caption)
            }
            if let рамка = модель.состояние.рамкаОкна {
                Text("Рамка собственного окна: x \(рамка.x), y \(рамка.y), \(рамка.ширина) × \(рамка.высота) points")
                    .font(.subheadline)
                    .textSelection(.enabled)
                Text("Источник: \(рамка.источник.rawValue) · событие: \(рамка.событие.rawValue) · монотонный момент: \(рамка.моментНаблюденияНс) ns")
                    .font(.caption)
                    .textSelection(.enabled)
            }
            if let ошибка = модель.состояние.последняяОшибкаРамки {
                Text("Рамка отклонена: \(описать(ошибка))").foregroundStyle(.orange)
            }
            if let ошибка = модель.состояние.последняяОшибкаИсполнения {
                Text("Ошибка шага: \(ошибка)").foregroundStyle(.red).textSelection(.enabled)
            }
            if let ошибка = модель.состояние.последняяОшибкаКлавиатуры {
                Text("Ошибка адаптера клавиатуры: \(ошибка)").foregroundStyle(.red).textSelection(.enabled)
            }
            if let результат = модель.состояние.последнийРезультат {
                Text("Результат шага: \(результат.текст)").textSelection(.enabled)
            }

            Text("История программы")
                .font(.headline)
            ForEach(модель.состояние.история) { запись in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Предложено: вход «\(запись.вход)» · программа: \(запись.определение)")
                        .font(.subheadline)
                        .lineLimit(2)
                    Text(запись.исход).textSelection(.enabled)
                }
                .padding(.vertical, 4)
                Divider()
            }

            Text("История физического ввода")
                .font(.headline)
            Text("Записей событий: \(модель.состояние.историяКлавиатуры.count)")
                .font(.caption)
            ForEach(модель.состояние.историяКлавиатуры) { запись in
                Text("\(запись.фаза), keycode \(запись.кодКлавиши), \(запись.раскладка.rawValue), порядок \(запись.порядок) · \(запись.статус): \(запись.исход) · \(описать(запись.вывод))")
                    .font(.caption)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func описать(_ ошибка: ОшибкаРамкиОкна) -> String {
        switch ошибка {
        case .неположительныйРазмер: return "ширина и высота должны быть положительными"
        case .неКонечнаяКоординатаИлиРазмер: return "координаты и размеры должны быть конечными"
        case .размерЗаПределом: return "координата или размер вне предела наблюдения"
        case .устаревшийПорядок: return "номер наблюдения не возрастает"
        case .времяУменьшилось: return "монотонный момент наблюдения уменьшился"
        case .неожиданноеСобытие: return "первым должно быть начальное наблюдение"
        }
    }

    private func описать(_ вывод: ВыводКлавиатурыОкна) -> String {
        switch вывод {
        case .текст(let текст, _): return "текст «\(текст)»"
        case .составленныйIMEТекст(let текст): return "текст IME «\(текст)»"
        case .команда(let команда): return "команда «\(команда)»"
        case .нет: return "без вывода"
        }
    }
}

@MainActor
private struct ТекстовоеПолеВводаФУМА: NSViewRepresentable {
    let текст: String
    let модель: МодельОкна

    func makeCoordinator() -> Координатор { Координатор(модель: модель) }

    func makeNSView(context: Context) -> ТекстовоеПолеФУМА {
        let view = ТекстовоеПолеФУМА(frame: .zero)
        view.isEditable = false
        view.isSelectable = false
        view.drawsBackground = false
        view.font = .systemFont(ofSize: NSFont.systemFontSize)
        context.coordinator.начатьПривязку(view)
        context.coordinator.подключить(view)
        view.string = текст
        return view
    }

    func updateNSView(_ view: ТекстовоеПолеФУМА, context: Context) {
        if let обновлённыйТекст = ПроекцияТекстаОкнаФУМА.значениеДляОбновления(
            текущее: view.string,
            авторитетное: текст
        ) {
            view.string = обновлённыйТекст
            view.needsDisplay = true
        }
        context.coordinator.подключить(view)
    }

    @MainActor
    final class Координатор {
        private let модель: МодельОкна
        private weak var привязанныйВид: ТекстовоеПолеФУМА?
        private var tokenПривязки: ТокенПривязкиВидаФУМА?
        init(модель: МодельОкна) { self.модель = модель }

        func начатьПривязку(_ view: ТекстовоеПолеФУМА) {
            if привязанныйВид === view,
               let tokenПривязки,
               модель.актуальнаПривязка(tokenПривязки, для: view) { return }
            привязанныйВид = view
            tokenПривязки = модель.привязатьКлавиатурныйВид(view)
        }

        func подключить(_ view: ТекстовоеПолеФУМА) {
            guard привязанныйВид === view,
                  let token = tokenПривязки,
                  модель.актуальнаПривязка(token, для: view) else { return }
            view.onPhysicalEvent = { [weak self, weak view] event, kind in
                guard let self, let view, self.модель.актуальнаПривязка(token, для: view) else { return }
                self.получить(event, вид: kind, в: view, привязка: token)
            }
            view.onWindowChange = { [weak self, weak view] window in
                guard let self, let view, self.модель.актуальнаПривязка(token, для: view) else { return }
                if !self.модель.обновитьФизическоеОкно(window) {
                    self.модель.деактивироватьКлавиатуру()
                }
            }
            if !модель.обновитьФизическоеОкно(view.window) {
                модель.деактивироватьКлавиатуру()
            }
            view.onFocusChange = { [weak self, weak view] focused in
                guard let self, let view, self.модель.актуальнаПривязка(token, для: view) else { return }
                if focused, let window = view.window {
                    if !self.модель.подтвердитьФокусКлавиатуры(в: window, виде: view) {
                        self.модель.деактивироватьКлавиатуру()
                        self.модель.записатьОшибкуКлавиатуры(
                            "Фокус окна не подтверждён отдельно от события клавиши."
                        )
                    }
                } else {
                    self.модель.деактивироватьКлавиатуру()
                }
            }
        }
        private func получить(
            _ event: NSEvent,
            вид: ВидНативногоСобытия,
            в view: ТекстовоеПолеФУМА,
            привязка token: ТокенПривязкиВидаФУМА
        ) {
            guard модель.актуальнаПривязка(token, для: view), вид == .нажатие else { return }
            guard модель.зарезервироватьЭкземплярНативногоСобытия(event) else { return }
            guard let window = view.window, window.firstResponder === view else { return }

            // Неподдержанный предыдущий event мог закрыть owner, не меняя
            // firstResponder. Новый event подтверждает текущее состояние до чтения/эффекта.
            guard модель.подтвердитьФокусКлавиатуры(в: window, виде: view) else { return }

            let timestamp = DispatchTime.now().uptimeNanoseconds
            let source = view.inputContext?.selectedKeyboardInputSource
            let marked = view.hasMarkedText()
            let flags = event.modifierFlags
            let modifiers = ФлагиМодификаторовТекстовогоВвода(
                сдвиг: flags.contains(.shift),
                опция: flags.contains(.option),
                команда: flags.contains(.command),
                управление: flags.contains(.control),
                capsLock: flags.contains(.capsLock),
                функция: flags.contains(.function),
                цифроваяКлавиатура: flags.contains(.numericPad)
            )
            guard ПолитикаИсточникаВводаФУМА.разрешитьПростуюКлавишу(
                вид: .нажатие,
                код: Int64(event.keyCode),
                символСобытия: event.characters,
                модификаторы: modifiers,
                идентификаторИсточника: source,
                естьРазмеченнаяКомпозиция: marked
            ), !модель.выполняется else {
                модель.деактивироватьКлавиатуру()
                модель.записатьОшибкуКлавиатуры(
                    "Событие не входит в поддерживаемый простой FUMA ввод; нативная передача отключена."
                )
                return
            }

            do {
                guard let observation = try модель.обработатьПростуюКлавишу(
                    код: Int64(event.keyCode),
                    символСобытия: event.characters,
                    повтор: event.isARepeat,
                    моментНаблюденияНс: timestamp,
                    идентификаторИсточника: source,
                    естьРазмеченнаяКомпозиция: marked,
                    модификаторы: modifiers,
                    окно: window
                ) else {
                    модель.деактивироватьКлавиатуру()
                    модель.записатьОшибкуКлавиатуры(
                        "Адаптер не вернул подтверждённое событие; повтор и нативная передача отключены."
                    )
                    return
                }
                модель.записатьКлавиатурноеСобытие(observation)

                guard window.firstResponder === view,
                      view.window === window,
                      view.inputContext?.selectedKeyboardInputSource == source,
                      view.hasMarkedText() == marked, !marked else {
                    модель.деактивироватьКлавиатуру()
                    модель.записатьОшибкуКлавиатуры(
                        "Отказано: после адаптера изменились окно, источник или состояние композиции."
                    )
                    return
                }

                switch РешениеВводаКлавиатуры.классифицировать(observation.результат) {
                case .применитьFUMA:
                    if let error = модель.принятьРезультатВладельцемТекста(observation) {
                        модель.деактивироватьКлавиатуру()
                        модель.записатьОшибкуКлавиатуры(error)
                    }
                case .подавитьПовтор:
                    break
                case .безЭффектаНеизвестно:
                    модель.деактивироватьКлавиатуру()
                    модель.записатьОшибкуКлавиатуры(
                        "Результат адаптера UNKNOWN: событие не вставлено и не повторено."
                    )
                case .передатьНативно:
                    модель.деактивироватьКлавиатуру()
                    модель.записатьОшибкуКлавиатуры(
                        "Нативная передача отключена в ограниченном FUMA вводе; текст не вставлен."
                    )
                }
            } catch {
                модель.деактивироватьКлавиатуру()
                модель.записатьОшибкуКлавиатуры(String(reflecting: error))
            }
        }
    }
}

@MainActor
private enum ВидНативногоСобытия: Equatable {
    case нажатие
    case отпускание
    case изменениеФлага
}

/// Только отображение: NSTextView не принимает правки, а события за пределами
/// FUMA пути не передаются нативному текстовому клиенту.
@MainActor
private final class ТекстовоеПолеФУМА: NSTextView {
    var onPhysicalEvent: ((NSEvent, ВидНативногоСобытия) -> Void)?
    var onFocusChange: ((Bool) -> Void)?
    var onWindowChange: ((NSWindow?) -> Void)?
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) { onPhysicalEvent?(event, .нажатие) }
    override func keyUp(with event: NSEvent) { onPhysicalEvent?(event, .отпускание) }
    override func flagsChanged(with event: NSEvent) { onPhysicalEvent?(event, .изменениеФлага) }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindowChange?(window)
    }

    override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        if became { onFocusChange?(true) }
        return became
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned { onFocusChange?(false) }
        return resigned
    }
}

@MainActor
private struct НаблюдательРамкиОкна: NSViewRepresentable {
    let onObservation: (CGRect, СобытиеНаблюденияРамки) -> Void

    func makeCoordinator() -> Координатор { Координатор(onObservation: onObservation) }
    func makeNSView(context: Context) -> НаблюдательРамкиNSView {
        let view = НаблюдательРамкиNSView(frame: .zero)
        view.onMoveToWindow = { [weak coordinator = context.coordinator] window in
            coordinator?.начатьНаблюдение(window)
        }
        return view
    }
    func updateNSView(_ view: НаблюдательРамкиNSView, context: Context) {
        view.onMoveToWindow = { [weak coordinator = context.coordinator] window in
            coordinator?.начатьНаблюдение(window)
        }
    }

    static func dismantleNSView(_ view: НаблюдательРамкиNSView, coordinator: Координатор) {
        coordinator.остановитьНаблюдение()
    }

    @MainActor
    final class Координатор {
        private let onObservation: (CGRect, СобытиеНаблюденияРамки) -> Void
        private weak var observedWindow: NSWindow?
        private var tokens: [NSObjectProtocol] = []
        private var sentInitial = false
        private var lastFrame: NSRect?

        init(onObservation: @escaping (CGRect, СобытиеНаблюденияРамки) -> Void) {
            self.onObservation = onObservation
        }

        func начатьНаблюдение(_ window: NSWindow?) {
            guard observedWindow !== window else { return }
            for token in tokens { NotificationCenter.default.removeObserver(token) }
            tokens.removeAll()
            observedWindow = window
            sentInitial = false
            lastFrame = nil
            guard let window else { return }
            tokens.append(NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification, object: window, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.сообщитьИзменение() }
            })
            tokens.append(NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification, object: window, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.сообщитьИзменение() }
            })
            if let frame = windowIfCurrent?.frame {
                sentInitial = true
                lastFrame = frame
                onObservation(frame, .первоначальноеНаблюдение)
            }
        }

        func остановитьНаблюдение() {
            for token in tokens { NotificationCenter.default.removeObserver(token) }
            tokens.removeAll()
            observedWindow = nil
            lastFrame = nil
        }

        private var windowIfCurrent: NSWindow? { observedWindow }

        private func сообщитьИзменение() {
            guard let window = observedWindow else { return }
            if !sentInitial {
                sentInitial = true
                let frame = window.frame
                lastFrame = frame
                onObservation(frame, .первоначальноеНаблюдение)
            } else {
                let frame = window.frame
                let moved = lastFrame?.origin != frame.origin
                let resized = lastFrame?.size != frame.size
                let event: СобытиеНаблюденияРамки
                switch (moved, resized) {
                case (true, true): event = .изменениеПоложенияИРазмера
                case (true, false): event = .изменениеПоложения
                case (false, true): event = .изменениеРазмера
                case (false, false): return
                }
                lastFrame = frame
                onObservation(frame, event)
            }
        }
    }
}

@MainActor
private final class НаблюдательРамкиNSView: NSView {
    var onMoveToWindow: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onMoveToWindow?(window)
    }
}
