import FUMInputCore
import Testing

@testable import FUMInputMac

@Suite("Преобразование платформенных событий")
struct ObservationFactoryTests {
  @Test("IOHID подключает клавиатурный и Consumer Control интерфейсы")
  func matchesKeyboardAndConsumerControlDevices() {
    #expect(
      IOHIDKeyboardSource.observedTopLevelUsages
        == [
          .init(usagePage: 0x01, usage: 0x06),
          .init(usagePage: 0x0C, usage: 0x01),
        ])
  }

  @Test("значение HID-элемента клавиатуры сохраняет usage и явное состояние")
  func mapsHIDKeyboardValue() {
    let observation = IOHIDObservationFactory.keyboardObservation(
      deviceID: "keyboard-1",
      usagePage: 0x07,
      usage: 0xE7,
      integerValue: 1,
      monotonicNanoseconds: 42
    )

    #expect(
      observation
        == .init(
          source: .ioHIDManager,
          key: .init(deviceID: "keyboard-1", usagePage: 0x07, usage: 0xE7),
          state: .pressed,
          monotonicNanoseconds: 42,
          isAutoRepeat: false
        ))
  }

  @Test("нулевое HID-значение означает отпускание")
  func mapsHIDRelease() {
    let observation = IOHIDObservationFactory.keyboardObservation(
      deviceID: "keyboard-1",
      usagePage: 0x07,
      usage: 0x39,
      integerValue: 0,
      monotonicNanoseconds: 43
    )

    #expect(observation?.state == .released)
    #expect(observation?.isAutoRepeat == false)
  }

  @Test("элемент вне страницы клавиатуры не маскируется под клавишу")
  func rejectsNonKeyboardHIDElement() {
    let observation = IOHIDObservationFactory.keyboardObservation(
      deviceID: "keyboard-1",
      usagePage: 0x01,
      usage: 0x30,
      integerValue: 1,
      monotonicNanoseconds: 44
    )

    #expect(observation == nil)
  }

  @Test("разрешённая consumer-клавиша сохраняет страницу и usage")
  func mapsHIDConsumerControl() {
    let observation = IOHIDObservationFactory.keyboardObservation(
      deviceID: "keyboard-1",
      usagePage: 0x0C,
      usage: 0xE9,
      integerValue: 1,
      monotonicNanoseconds: 44
    )

    #expect(observation?.key.usagePage == 0x0C)
    #expect(observation?.key.usage == 0xE9)
    #expect(observation?.state == .pressed)
  }

  @Test("CGEvent переносит явный маркер автоповтора")
  func mapsCGEventRepeat() {
    let observation = CGEventObservationFactory.keyboardObservation(
      type: .keyDown,
      virtualKeyCode: 0,
      monotonicNanoseconds: 45,
      isAutoRepeat: true,
      queriedPhysicalState: nil
    )

    #expect(observation?.state == .pressed)
    #expect(observation?.isAutoRepeat == true)
  }

  @Test("flagsChanged получает состояние из физической таблицы, а не из флагов")
  func mapsFlagsChangedThroughQueriedState() {
    let observation = CGEventObservationFactory.keyboardObservation(
      type: .flagsChanged,
      virtualKeyCode: 55,
      monotonicNanoseconds: 46,
      isAutoRepeat: false,
      queriedPhysicalState: false
    )

    #expect(observation?.state == .released)
    #expect(observation?.key.usage == 55)
  }

  @Test("CGEvent сохраняет вид события и именованные диагностические флаги")
  func preservesCGEventDiagnostics() {
    let observation = CGEventObservationFactory.keyboardObservation(
      type: .flagsChanged,
      virtualKeyCode: 63,
      monotonicNanoseconds: 47,
      isAutoRepeat: false,
      queriedPhysicalState: true,
      modifierFlags: [.secondaryFn, .shift]
    )

    #expect(observation?.diagnostics?.platformEventKind == .flagsChanged)
    #expect(observation?.diagnostics?.modifierFlags == [.secondaryFn, .shift])
  }
}
