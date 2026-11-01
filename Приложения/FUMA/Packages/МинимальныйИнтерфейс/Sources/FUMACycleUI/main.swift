import AppKit
import CoreGraphics
import Foundation
import Observation
import SwiftUI
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
    var отображаемыйВводКлавиатуры = ""
    var ошибкаКлавиатуры: String?

    private let цикл = ЦиклОператора()
    private let владелецКлавиатурногоАдаптера = ВладелецКлавиатурногоАдаптера()
    private var физическоеОкно: ObjectIdentifier?
    private var идентификаторВводаОкна = ИдентификаторОкнаВвода(rawValue: UUID())
    private let дедупликаторНативныхСобытий = ДедупликаторЭкземпляровНативныхСобытий()
    private var номерНаблюденияОбласти = 0
    private var номерНаблюденияРамки = 0
    private var очередьСостояния: Task<Void, Never>?

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

    func идентификаторОкнаДляКлавиатуры(_ window: NSWindow) -> ИдентификаторОкнаВвода {
        let identity = ObjectIdentifier(window)
        if физическоеОкно != identity {
            физическоеОкно = identity
            идентификаторВводаОкна = ИдентификаторОкнаВвода(rawValue: UUID())
            владелецКлавиатурногоАдаптера.выбратьОкно(идентификаторВводаОкна)
        }
        return идентификаторВводаОкна
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
        _ = идентификаторОкнаДляКлавиатуры(окно)
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
        владелецКлавиатурногоАдаптера.деактивировать()
    }

    func принятьНативноеИзменениеТекста(_ текст: String) {
        отображаемыйВводКлавиатуры = текст
    }

    func записатьКлавиатурноеСобытие(_ наблюдение: СобытиеСРезультатомКлавиатуры) {
        сериализоватьСостояние { [weak self] in
            guard let self else { return }
            let новое = await self.цикл.записатьРезультатКлавиатуры(наблюдение)
            self.состояние.применитьЕслиНовее(новое)
            self.ошибкаКлавиатуры = nil
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
                ТекстовоеПолеВводаФУМА(текст: $модель.отображаемыйВводКлавиатуры, модель: модель)
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
            Text("Адаптер принимает только поддерживаемую клавишу US без модификаторов и IME. Shift, Option, другие источники и composition остаются нативными; подключена только QWERTY v1.")
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
    @Binding var текст: String
    let модель: МодельОкна

    init(текст: Binding<String>, модель: МодельОкна) {
        self._текст = текст
        self.модель = модель
    }

    func makeCoordinator() -> Координатор {
        Координатор(модель: модель)
    }

    func makeNSView(context: Context) -> ТекстовоеПолеФУМА {
        let view = ТекстовоеПолеФУМА(frame: .zero)
        view.isEditable = true
        view.isSelectable = true
        view.drawsBackground = false
        view.font = .systemFont(ofSize: NSFont.systemFontSize)
        context.coordinator.подключить(view)
        view.delegate = context.coordinator
        view.string = текст
        return view
    }

    func updateNSView(_ view: ТекстовоеПолеФУМА, context: Context) {
        if !view.hasMarkedText(), view.string != текст { view.string = текст }
        context.coordinator.подключить(view)
        view.delegate = context.coordinator
    }

    @MainActor
    final class Координатор: NSObject, NSTextViewDelegate {
        private weak var view: ТекстовоеПолеФУМА?
        private let модель: МодельОкна
        private var поколениеРедактора: UInt64 = 0

        init(модель: МодельОкна) {
            self.модель = модель
            super.init()
        }

        func подключить(_ view: ТекстовоеПолеФУМА) {
            guard self.view !== view else { return }
            self.view = view
            view.onPhysicalEvent = { [weak self, weak view] event, kind in
                guard let self, let view else { return }
                self.получить(event, вид: kind, в: view)
            }
            view.onFocusChange = { [weak self] _ in
                guard let self else { return }
                self.модель.деактивироватьКлавиатуру()
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? ТекстовоеПолеФУМА else { return }
            поколениеРедактора &+= 1
            модель.принятьНативноеИзменениеТекста(view.string)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard notification.object as? ТекстовоеПолеФУМА != nil else { return }
            поколениеРедактора &+= 1
        }

        private func получить(
            _ nativeEvent: NSEvent,
            вид: ВидНативногоСобытия,
            в view: ТекстовоеПолеФУМА
        ) {
            let eventKind: ВидСобытияТекстовогоВвода
            switch вид {
            case .нажатие: eventKind = .нажатие
            case .отпускание: eventKind = .отпускание
            case .изменениеФлага: eventKind = .изменениеФлага
            }
            guard модель.зарезервироватьЭкземплярНативногоСобытия(nativeEvent) else { return }
            guard eventKind == .нажатие else {
                модель.деактивироватьКлавиатуру()
                view.передатьНативно(nativeEvent, вид: вид)
                return
            }

            let timestamp = DispatchTime.now().uptimeNanoseconds
            let activeSource = view.inputContext?.selectedKeyboardInputSource
            let hasMarkedText = view.hasMarkedText()
            let flags = nativeEvent.modifierFlags
            let modifiers = ФлагиМодификаторовТекстовогоВвода(
                сдвиг: flags.contains(.shift),
                опция: flags.contains(.option),
                команда: flags.contains(.command),
                управление: flags.contains(.control),
                capsLock: flags.contains(.capsLock),
                функция: flags.contains(.function),
                цифроваяКлавиатура: flags.contains(.numericPad)
            )
            guard let window = view.window, window.firstResponder === view else {
                модель.деактивироватьКлавиатуру()
                модель.записатьОшибкуКлавиатуры("Событие без подтверждённого окна и first responder отброшено.")
                return
            }
            guard ПолитикаИсточникаВводаФУМА.разрешитьПростуюКлавишу(
                вид: eventKind,
                код: Int64(nativeEvent.keyCode),
                символСобытия: nativeEvent.characters,
                модификаторы: modifiers,
                идентификаторИсточника: activeSource,
                естьРазмеченнаяКомпозиция: hasMarkedText
            ), !модель.выполняется else {
                модель.деактивироватьКлавиатуру()
                view.передатьНативно(nativeEvent, вид: вид)
                return
            }
            guard let исходноеВладение = снимокВладения(view, окно: window) else {
                модель.деактивироватьКлавиатуру()
                модель.записатьОшибкуКлавиатуры("Снимок выделения недоступен; событие не повторялось.")
                return
            }
            guard исходноеВладение.источник == activeSource,
                  исходноеВладение.естьРазмеченнаяКомпозиция == hasMarkedText else {
                модель.деактивироватьКлавиатуру()
                view.передатьНативно(nativeEvent, вид: вид)
                return
            }

            do {
                guard let наблюдение = try модель.обработатьПростуюКлавишу(
                    код: Int64(nativeEvent.keyCode),
                    символСобытия: nativeEvent.characters,
                    повтор: nativeEvent.isARepeat,
                    моментНаблюденияНс: timestamp,
                    идентификаторИсточника: activeSource,
                    естьРазмеченнаяКомпозиция: hasMarkedText,
                    модификаторы: modifiers,
                    окно: window
                ) else {
                    view.передатьНативно(nativeEvent, вид: вид)
                    return
                }
                модель.записатьКлавиатурноеСобытие(наблюдение)

                guard let текущееВладение = снимокВладения(view, окно: window),
                      исходноеВладение == текущееВладение else {
                    модель.записатьОшибкуКлавиатуры("Отказано: изменилось владение окном, текстом или выделением.")
                    return
                }

                switch РешениеВводаКлавиатуры.классифицировать(наблюдение.результат) {
                case .применитьFUMA:
                    switch наблюдение.результат.вывод {
                    case .текст(_, источник: .fuma), .команда("удалить-назад"):
                        if !view.применить(
                            наблюдение.результат,
                            выделениеUTF16: исходноеВладение.выделениеUTF16
                        ) {
                            модель.записатьОшибкуКлавиатуры(
                                "Редактор отклонил результат FUMA; исходное событие не повторялось."
                            )
                        }
                    case .нет:
                        break
                    case .текст, .составленныйIMEТекст, .команда:
                        модель.записатьОшибкуКлавиатуры("Адаптер вернул неподдержанный вывод; событие не повторялось.")
                    }
                case .передатьНативно:
                    view.передатьНативно(nativeEvent, вид: вид)
                case .подавитьПовтор, .безЭффектаНеизвестно:
                    break
                }
                модель.принятьНативноеИзменениеТекста(view.string)
            } catch let error as ОшибкаВводаКлавиатуры {
                модель.записатьОшибкуКлавиатуры(
                    error.errorDescription ?? String(reflecting: error)
                )
                if error.допускаетсяНативныйFallback {
                    view.передатьНативно(nativeEvent, вид: вид)
                }
            } catch {
                модель.записатьОшибкуКлавиатуры(String(reflecting: error))
            }
        }

        private func снимокВладения(
            _ view: ТекстовоеПолеФУМА,
            окно window: NSWindow
        ) -> СнимокВладенияТекстовымПолем? {
            guard window.firstResponder === view else { return nil }
            let range = view.selectedRange()
            guard range.location != NSNotFound else { return nil }
            let upper = range.location.addingReportingOverflow(range.length)
            guard !upper.overflow else { return nil }
            let windowID = модель.идентификаторОкнаДляКлавиатуры(window)
            return СнимокВладенияТекстовымПолем(
                окно: windowID.rawValue,
                получатель: view.идентификаторПолучателя,
                источник: view.inputContext?.selectedKeyboardInputSource,
                естьРазмеченнаяКомпозиция: view.hasMarkedText(),
                поколениеРедактора: поколениеРедактора,
                текст: view.string,
                выделениеUTF16: range.location..<upper.partialValue
            )
        }
    }
}

@MainActor
private enum ВидНативногоСобытия: Equatable {
    case нажатие
    case отпускание
    case изменениеФлага
}

@MainActor
private final class ТекстовоеПолеФУМА: NSTextView {
    var onPhysicalEvent: ((NSEvent, ВидНативногоСобытия) -> Void)?
    var onFocusChange: ((Bool) -> Void)?
    let идентификаторПолучателя = UUID()

    override func keyDown(with event: NSEvent) {
        guard let onPhysicalEvent else { super.keyDown(with: event); return }
        onPhysicalEvent(event, .нажатие)
    }

    override func keyUp(with event: NSEvent) {
        guard let onPhysicalEvent else { super.keyUp(with: event); return }
        onPhysicalEvent(event, .отпускание)
    }

    override func flagsChanged(with event: NSEvent) {
        guard let onPhysicalEvent else { super.flagsChanged(with: event); return }
        onPhysicalEvent(event, .изменениеФлага)
    }

    override func becomeFirstResponder() -> Bool {
        let didBecome = super.becomeFirstResponder()
        if didBecome { onFocusChange?(true) }
        return didBecome
    }

    override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        if didResign { onFocusChange?(false) }
        return didResign
    }

    func применить(
        _ результат: РезультатВводаКлавиатурыОкна,
        выделениеUTF16: Range<Int>
    ) -> Bool {
        switch результат.вывод {
        case .текст(let text, источник: .fuma):
            return заменитьВыделениеИлиКурсор(вставкой: text, диапазон: выделениеUTF16)
        case .команда("удалить-назад"):
            return удалитьНазад(диапазон: выделениеUTF16)
        case .нет:
            return true
        case .текст, .составленныйIMEТекст, .команда:
            return false
        }
    }

    private func заменитьВыделениеИлиКурсор(
        вставкой text: String,
        диапазон range: Range<Int>
    ) -> Bool {
        guard let edit = РедакторТекстаКлавиатуры.вставить(
            text,
            в: string,
            выделениеUTF16: range
        ) else { return false }
        return применить(edit)
    }

    private func удалитьНазад(диапазон range: Range<Int>) -> Bool {
        guard let edit = РедакторТекстаКлавиатуры.удалитьНазад(
                из: string,
                выделениеUTF16: range
        ) else { return false }
        return применить(edit)
    }

    private func применить(_ edit: РезультатРедактированияКлавиатуры) -> Bool {
        guard let storage = textStorage else { return false }
        let replacementRange = NSRange(
            location: edit.заменяемыйДиапазонUTF16.lowerBound,
            length: edit.заменяемыйДиапазонUTF16.count
        )
        guard shouldChangeText(in: replacementRange, replacementString: edit.вставка) else { return false }
        storage.replaceCharacters(in: replacementRange, with: edit.вставка)
        didChangeText()
        setSelectedRange(NSRange(
            location: edit.выделениеUTF16.lowerBound,
            length: edit.выделениеUTF16.count
        ))
        return true
    }

    func передатьНативно(_ event: NSEvent, вид kind: ВидНативногоСобытия) {
        switch kind {
        case .нажатие: super.keyDown(with: event)
        case .отпускание: super.keyUp(with: event)
        case .изменениеФлага: super.flagsChanged(with: event)
        }
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
