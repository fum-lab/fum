public enum KeyboardTestKey: String, Codable, CaseIterable, Sendable {
  case a
  case s
  case e
  case leftShift
  case rightShift
  case leftControl
  case rightControl
  case leftOption
  case rightOption
  case leftCommand
  case rightCommand
  case capsLock
  case function
  case f1
  case volumeIncrement
  case playPause

  public func matches(_ key: PhysicalKey) -> Bool {
    switch key.codeSpace {
    case .hidUsage:
      let expectedUsagePage: UInt32 =
        self == .volumeIncrement || self == .playPause ? 0x0C : 0x07
      guard key.usagePage == expectedUsagePage else { return false }
      return Self.hidUsages[self] == key.usage
    case .macVirtualKeyCode:
      return Self.macVirtualKeyCodes[self] == key.usage
    }
  }

  private static let hidUsages: [KeyboardTestKey: UInt32] = [
    .a: 0x04,
    .s: 0x16,
    .e: 0x08,
    .leftControl: 0xE0,
    .leftShift: 0xE1,
    .leftOption: 0xE2,
    .leftCommand: 0xE3,
    .rightControl: 0xE4,
    .rightShift: 0xE5,
    .rightOption: 0xE6,
    .rightCommand: 0xE7,
    .capsLock: 0x39,
    .f1: 0x3A,
    .volumeIncrement: 0xE9,
    .playPause: 0xCD,
  ]

  private static let macVirtualKeyCodes: [KeyboardTestKey: UInt32] = [
    .a: 0,
    .s: 1,
    .e: 14,
    .rightCommand: 54,
    .leftCommand: 55,
    .leftShift: 56,
    .capsLock: 57,
    .leftOption: 58,
    .leftControl: 59,
    .rightShift: 60,
    .rightOption: 61,
    .rightControl: 62,
    .function: 63,
    .f1: 122,
  ]
}

public enum KeyboardTestScenarioAvailability: String, Codable, Sendable {
  case required
  case conditional
}

public struct KeyboardTestTransition: Codable, Equatable, Sendable {
  public let key: KeyboardTestKey
  public let state: PhysicalKeyState

  public init(_ key: KeyboardTestKey, _ state: PhysicalKeyState) {
    self.key = key
    self.state = state
  }
}

public struct KeyboardTestScenario: Codable, Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let purpose: String
  public let instructions: [String]
  public let expectedEvidence: [String]
  public let allowedKeys: [KeyboardTestKey]
  public let requiredObservedKeys: [KeyboardTestKey]
  public let minimumAcceptedTransitionsPerSource: Int
  public let minimumDistinctDevicesPerSource: Int
  public let requiredCompletedAttempts: Int
  public let expectedTransitionSequence: [KeyboardTestTransition]?
  public let minimumDurationNanosecondsPerSource: UInt64?
  public let availability: KeyboardTestScenarioAvailability

  public init(
    id: String,
    title: String,
    purpose: String,
    instructions: [String],
    expectedEvidence: [String],
    allowedKeys: [KeyboardTestKey],
    requiredObservedKeys: [KeyboardTestKey]? = nil,
    minimumAcceptedTransitionsPerSource: Int,
    minimumDistinctDevicesPerSource: Int = 1,
    requiredCompletedAttempts: Int = 1,
    expectedTransitionSequence: [KeyboardTestTransition]? = nil,
    minimumDurationNanosecondsPerSource: UInt64? = nil,
    availability: KeyboardTestScenarioAvailability = .required
  ) {
    self.id = id
    self.title = title
    self.purpose = purpose
    self.instructions = instructions
    self.expectedEvidence = expectedEvidence
    self.allowedKeys = allowedKeys
    self.requiredObservedKeys = requiredObservedKeys ?? allowedKeys
    self.minimumAcceptedTransitionsPerSource = minimumAcceptedTransitionsPerSource
    self.minimumDistinctDevicesPerSource = minimumDistinctDevicesPerSource
    self.requiredCompletedAttempts = requiredCompletedAttempts
    self.expectedTransitionSequence = expectedTransitionSequence
    self.minimumDurationNanosecondsPerSource = minimumDurationNanosecondsPerSource
    self.availability = availability
  }

  public func allows(_ key: PhysicalKey) -> Bool {
    allowedKeys.contains { $0.matches(key) }
  }

  public func testKey(matching key: PhysicalKey) -> KeyboardTestKey? {
    allowedKeys.first { $0.matches(key) }
  }
}

public struct KeyboardTestPlan: Codable, Equatable, Sendable {
  public let version: Int
  public let scenarios: [KeyboardTestScenario]

  public init(version: Int, scenarios: [KeyboardTestScenario]) {
    self.version = version
    self.scenarios = scenarios
  }

  public func scenario(id: String) -> KeyboardTestScenario? {
    scenarios.first { $0.id == id }
  }

  public static let standard = KeyboardTestPlan(
    version: 1,
    scenarios: [
      .init(
        id: "ordinary-tap-and-rollover",
        title: "Обычные клавиши и перекрытие",
        purpose:
          "Проверить одиночный цикл и независимый порядок двух одновременно удерживаемых клавиш.",
        instructions: [
          "Коротко нажмите и отпустите физическую клавишу A.",
          "Затем нажмите A, не отпуская её нажмите S, отпустите A и после неё S.",
          "Не используйте другие клавиши; переход между шагами выполняйте мышью.",
        ],
        expectedEvidence: [
          "Одиночный цикл даёт нажатие и отпускание.",
          "Перекрытие даёт четыре перехода в порядке A↓, S↓, A↑, S↑.",
        ],
        allowedKeys: [.a, .s],
        minimumAcceptedTransitionsPerSource: 6,
        expectedTransitionSequence: [
          .init(.a, .pressed), .init(.a, .released),
          .init(.a, .pressed), .init(.s, .pressed),
          .init(.a, .released), .init(.s, .released),
        ]
      ),
      .init(
        id: "ordinary-long-hold",
        title: "Долгое удержание и автоповтор",
        purpose: "Отделить физический цикл клавиши от генерируемого системой автоповтора.",
        instructions: [
          "Нажмите A и удерживайте не менее трёх секунд, пока система не успеет включить автоповтор.",
          "Отпустите A.",
        ],
        expectedEvidence: [
          "В первичном потоке остаются только pressed и released.",
          "Если источник отмечает автоповтор, промежуточные keyDown сохраняются как диагностически отклонённые.",
        ],
        allowedKeys: [.a],
        minimumAcceptedTransitionsPerSource: 2,
        expectedTransitionSequence: [.init(.a, .pressed), .init(.a, .released)],
        minimumDurationNanosecondsPerSource: 3_000_000_000
      ),
      .init(
        id: "modifier-sides",
        title: "Левые и правые модификаторы",
        purpose: "Проверить раздельность сторон Shift, Control, Option и Command.",
        instructions: [
          "По очереди нажмите и отпустите левый, затем правый Shift.",
          "Так же проверьте левый и правый Control, Option и Command.",
        ],
        expectedEvidence: [
          "Каждая сторона каждого доступного модификатора даёт собственную пару переходов."
        ],
        allowedKeys: [
          .leftShift, .rightShift, .leftControl, .rightControl, .leftOption, .rightOption,
          .leftCommand, .rightCommand,
        ],
        minimumAcceptedTransitionsPerSource: 16,
        expectedTransitionSequence: [
          .init(.leftShift, .pressed), .init(.leftShift, .released),
          .init(.rightShift, .pressed), .init(.rightShift, .released),
          .init(.leftControl, .pressed), .init(.leftControl, .released),
          .init(.rightControl, .pressed), .init(.rightControl, .released),
          .init(.leftOption, .pressed), .init(.leftOption, .released),
          .init(.rightOption, .pressed), .init(.rightOption, .released),
          .init(.leftCommand, .pressed), .init(.leftCommand, .released),
          .init(.rightCommand, .pressed), .init(.rightCommand, .released),
        ]
      ),
      .init(
        id: "command-overlap",
        title: "Одновременные Command",
        purpose:
          "Проверить физическое состояние каждой стороны при неизменном общем флаге Command.",
        instructions: [
          "Нажмите левый Command.",
          "Не отпуская его нажмите правый Command.",
          "Отпустите левый Command, затем правый.",
        ],
        expectedEvidence: [
          "Наблюдаются четыре перехода LCommand↓, RCommand↓, LCommand↑, RCommand↑."
        ],
        allowedKeys: [.leftCommand, .rightCommand],
        minimumAcceptedTransitionsPerSource: 4,
        expectedTransitionSequence: [
          .init(.leftCommand, .pressed), .init(.rightCommand, .pressed),
          .init(.leftCommand, .released), .init(.rightCommand, .released),
        ]
      ),
      .init(
        id: "modifier-key-chord",
        title: "Модификатор с обычной клавишей",
        purpose: "Проверить порядок фаз внутри комбинации без сведения её к команде.",
        instructions: [
          "Нажмите левый Shift, затем A.",
          "Отпустите A, затем левый Shift.",
        ],
        expectedEvidence: ["Наблюдаются четыре перехода Shift↓, A↓, A↑, Shift↑."],
        allowedKeys: [.leftShift, .a],
        minimumAcceptedTransitionsPerSource: 4,
        expectedTransitionSequence: [
          .init(.leftShift, .pressed), .init(.a, .pressed),
          .init(.a, .released), .init(.leftShift, .released),
        ]
      ),
      .init(
        id: "caps-lock-two-cycles",
        title: "Два цикла Caps Lock",
        purpose: "Отделить физические фазы Caps Lock от логического режима и индикатора.",
        instructions: [
          "Нажмите и отпустите Caps Lock.",
          "Повторите нажатие и отпускание, чтобы вернуть исходный логический режим.",
        ],
        expectedEvidence: [
          "Два цикла дают четыре физические фазы независимо от состояния индикатора."
        ],
        allowedKeys: [.capsLock],
        minimumAcceptedTransitionsPerSource: 4,
        expectedTransitionSequence: [
          .init(.capsLock, .pressed), .init(.capsLock, .released),
          .init(.capsLock, .pressed), .init(.capsLock, .released),
        ]
      ),
      .init(
        id: "layout-invariance",
        title: "Одна клавиша в двух раскладках",
        purpose: "Проверить независимость физического кода от символа системной раскладки.",
        instructions: [
          "В первой раскладке нажмите и отпустите физическую клавишу A.",
          "Завершите попытку, мышью смените раскладку и запустите сценарий повторно.",
          "Во второй раскладке нажмите ту же физическую клавишу.",
        ],
        expectedEvidence: ["Обе попытки дают одинаковый физический или виртуальный код и фазы."],
        allowedKeys: [.a],
        minimumAcceptedTransitionsPerSource: 2,
        requiredCompletedAttempts: 2,
        expectedTransitionSequence: [.init(.a, .pressed), .init(.a, .released)]
      ),
      .init(
        id: "fn-and-top-row",
        title: "Fn или Globe и верхний ряд",
        purpose: "Измерить платформенную наблюдаемость Fn и преобразование верхнего ряда.",
        instructions: [
          "Нажмите и отпустите Fn или Globe отдельно.",
          "Нажмите и отпустите F1 без Fn.",
          "Затем выполните Fn + F1 и отпустите обе клавиши.",
        ],
        expectedEvidence: [
          "Результат честно классифицируется как физические фазы, только флаги либо ненаблюдаемость."
        ],
        allowedKeys: [.function, .f1],
        requiredObservedKeys: [.f1],
        minimumAcceptedTransitionsPerSource: 2,
        availability: .conditional
      ),
      .init(
        id: "media-key-boundary",
        title: "Граница медиа-клавиши",
        purpose:
          "Зафиксировать, видит ли выбранный публичный источник системную или consumer-клавишу.",
        instructions: [
          "Один раз нажмите безопасную медиа-клавишу, например увеличение громкости или Play/Pause.",
          "Если событие не появилось, завершите сценарий как «не поддерживается» — это полезный результат.",
        ],
        expectedEvidence: [
          "Событие классифицируется как обычная пара, отдельная системная диагностика или ненаблюдаемость."
        ],
        allowedKeys: [.volumeIncrement, .playPause],
        requiredObservedKeys: [],
        minimumAcceptedTransitionsPerSource: 2,
        availability: .conditional
      ),
      .init(
        id: "focus-boundary",
        title: "Граница фокуса приложения",
        purpose: "Сравнить наблюдение при активном окне стенда и вне его.",
        instructions: [
          "При активном окне нажмите и отпустите левый Shift.",
          "Мышью переключитесь в другое безопасное окно и нажмите и отпустите правый Shift.",
          "Вернитесь в стенд мышью.",
        ],
        expectedEvidence: ["Поток явно показывает наличие или потерю фаз на границе фокуса."],
        allowedKeys: [.leftShift, .rightShift],
        minimumAcceptedTransitionsPerSource: 4,
        expectedTransitionSequence: [
          .init(.leftShift, .pressed), .init(.leftShift, .released),
          .init(.rightShift, .pressed), .init(.rightShift, .released),
        ]
      ),
      .init(
        id: "second-keyboard",
        title: "Вторая клавиатура",
        purpose:
          "Проверить раздельность устройств либо явно зафиксировать их объединение источником.",
        instructions: [
          "На первой клавиатуре нажмите и отпустите A.",
          "На второй клавиатуре нажмите и отпустите A.",
          "Затем удерживайте A на обеих клавиатурах одновременно и отпустите по очереди.",
        ],
        expectedEvidence: [
          "IOHID различает устройства; объединяющие источники сохраняют явную границу своей точности."
        ],
        allowedKeys: [.a],
        minimumAcceptedTransitionsPerSource: 8,
        minimumDistinctDevicesPerSource: 2,
        expectedTransitionSequence: [
          .init(.a, .pressed), .init(.a, .released),
          .init(.a, .pressed), .init(.a, .released),
          .init(.a, .pressed), .init(.a, .pressed),
          .init(.a, .released), .init(.a, .released),
        ],
        availability: .conditional
      ),
      .init(
        id: "disconnect-reconnect",
        title: "Отключение и повторное подключение",
        purpose: "Проверить непрерывность и границы жизненного цикла внешней клавиатуры.",
        instructions: [
          "На внешней клавиатуре нажмите и отпустите A.",
          "Мышью отключите и снова подключите клавиатуру, не нажимая другие клавиши.",
          "После подключения снова нажмите и отпустите A.",
        ],
        expectedEvidence: [
          "До и после переподключения видны отдельные циклы либо диагностируемый разрыв."
        ],
        allowedKeys: [.a],
        minimumAcceptedTransitionsPerSource: 4,
        expectedTransitionSequence: [
          .init(.a, .pressed), .init(.a, .released),
          .init(.a, .pressed), .init(.a, .released),
        ],
        availability: .conditional
      ),
      .init(
        id: "sleep-wake",
        title: "Сон и пробуждение",
        purpose: "Проверить временную и событийную границу системного сна.",
        instructions: [
          "Нажмите и отпустите A.",
          "Переведите Mac в сон без клавиатурной команды и пробудите его.",
          "После пробуждения снова нажмите и отпустите A.",
        ],
        expectedEvidence: [
          "События после пробуждения не продолжают старое состояние без явной границы."
        ],
        allowedKeys: [.a],
        minimumAcceptedTransitionsPerSource: 4,
        expectedTransitionSequence: [
          .init(.a, .pressed), .init(.a, .released),
          .init(.a, .pressed), .init(.a, .released),
        ],
        availability: .conditional
      ),
      .init(
        id: "permission-loss",
        title: "Отзыв разрешения",
        purpose: "Проверить остановку наблюдения после отзыва Input Monitoring.",
        instructions: [
          "До отзыва нажмите и отпустите A, чтобы получить контрольный цикл.",
          "Для CGEventTap или NSEvent отзовите Input Monitoring в Системных настройках.",
          "Вернитесь мышью и нажмите A только в этой безопасной попытке.",
          "Если источник требует перезапуска, отметьте сценарий как не поддерживаемый в текущем запуске.",
        ],
        expectedEvidence: [
          "Новые записи прекращаются либо источник сообщает диагностируемую потерю доступа."
        ],
        allowedKeys: [.a],
        minimumAcceptedTransitionsPerSource: 2,
        expectedTransitionSequence: [.init(.a, .pressed), .init(.a, .released)],
        availability: .conditional
      ),
      .init(
        id: "load-burst",
        title: "Быстрый поток под нагрузкой",
        purpose: "Проверить порядок, пропуски и устойчивость callback при плотном потоке.",
        instructions: [
          "В течение десяти секунд быстро чередуйте A и S.",
          "Завершите обе клавиши в отпущенном состоянии.",
        ],
        expectedEvidence: [
          "Порядок остаётся монотонным, а пропуски или отключения источника диагностируются."
        ],
        allowedKeys: [.a, .s],
        minimumAcceptedTransitionsPerSource: 8,
        minimumDurationNanosecondsPerSource: 10_000_000_000
      ),
    ]
  )
}
