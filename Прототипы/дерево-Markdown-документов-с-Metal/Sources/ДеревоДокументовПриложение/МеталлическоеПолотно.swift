import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import MetalKit
import SwiftUI
import ДеревоДокументовЯдро

struct МеталлическоеПолотно: NSViewRepresentable {
  let ресурсы: ГрафическиеРесурсы
  let снимок: СнимокДерева
  let раскладка: РезультатРаскладки
  let запрос: String
  let выбранныйИдентификатор: String?
  let поколениеВписывания: Int
  let выбрать: (String?) -> Void
  let открытьИлиСвернуть: (String) -> Void

  func makeCoordinator() -> КоординаторОтрисовки {
    КоординаторОтрисовки(ресурсы: ресурсы)
  }

  func makeNSView(context контекст: Context) -> ПолотноДерева {
    let полотно = ПолотноДерева(frame: .zero, device: ресурсы.устройство)
    полотно.framebufferOnly = false
    полотно.colorPixelFormat = .bgra8Unorm
    полотно.enableSetNeedsDisplay = true
    полотно.isPaused = true
    полотно.delegate = контекст.coordinator
    контекст.coordinator.подключить(полотно)

    let координатор = контекст.coordinator
    полотно.приПеретаскивании = { сдвиг in
      координатор.сдвинуть(на: сдвиг)
    }
    полотно.приМасштабировании = { множитель, опорнаяТочка in
      координатор.масштабировать(в: множитель, около: опорнаяТочка)
    }
    полотно.приЩелчке = { точка, числоЩелчков in
      координатор.обработатьЩелчок(в: точка, числоЩелчков: числоЩелчков)
    }
    return полотно
  }

  func updateNSView(_ полотно: ПолотноДерева, context контекст: Context) {
    контекст.coordinator.обновить(
      снимок: снимок,
      раскладка: раскладка,
      запрос: запрос,
      выбранныйИдентификатор: выбранныйИдентификатор,
      поколениеВписывания: поколениеВписывания,
      выбрать: выбрать,
      открытьИлиСвернуть: открытьИлиСвернуть
    )
    полотно.setNeedsDisplay(полотно.bounds)
  }
}

final class ПолотноДерева: MTKView {
  var приПеретаскивании: ((CGSize) -> Void)?
  var приМасштабировании: ((CGFloat, CGPoint) -> Void)?
  var приЩелчке: ((CGPoint, Int) -> Void)?
  private var последняяТочка: CGPoint?

  override var acceptsFirstResponder: Bool { true }

  override func mouseDown(with событие: NSEvent) {
    window?.makeFirstResponder(self)
    последняяТочка = convert(событие.locationInWindow, from: nil)
    приЩелчке?(последняяТочка ?? .zero, событие.clickCount)
  }

  override func mouseDragged(with событие: NSEvent) {
    let текущаяТочка = convert(событие.locationInWindow, from: nil)
    if let последняяТочка {
      приПеретаскивании?(
        CGSize(
          width: текущаяТочка.x - последняяТочка.x,
          height: текущаяТочка.y - последняяТочка.y
        )
      )
    }
    последняяТочка = текущаяТочка
  }

  override func mouseUp(with _: NSEvent) {
    последняяТочка = nil
  }

  override func magnify(with событие: NSEvent) {
    let опорнаяТочка = convert(событие.locationInWindow, from: nil)
    приМасштабировании?(exp(событие.magnification), опорнаяТочка)
  }

  override func scrollWheel(with событие: NSEvent) {
    if событие.modifierFlags.intersection([.control, .option, .command]).isEmpty {
      приПеретаскивании?(
        CGSize(width: -событие.scrollingDeltaX, height: событие.scrollingDeltaY)
      )
    } else {
      let опорнаяТочка = convert(событие.locationInWindow, from: nil)
      приМасштабировании?(exp(-событие.scrollingDeltaY * 0.018), опорнаяТочка)
    }
  }

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: .openHand)
  }
}

private struct ЭкранныйУзел {
  let идентификатор: String
  let узел: УзелДерева
  let точка: CGPoint
  let радиус: CGFloat
  let совпадаетСПоиском: Bool
}

@MainActor
final class КоординаторОтрисовки: NSObject, MTKViewDelegate {
  private let ресурсы: ГрафическиеРесурсы
  private weak var полотно: ПолотноДерева?
  private let слойНадписей = CALayer()
  private var слоиНадписей: [String: CATextLayer] = [:]
  private var снимок: СнимокДерева?
  private var раскладка: РезультатРаскладки?
  private var запрос = ""
  private var выбранныйИдентификатор: String?
  private var выбрать: ((String?) -> Void)?
  private var открытьИлиСвернуть: ((String) -> Void)?
  private var центр = CGPoint.zero
  private var масштаб: CGFloat = 1
  private var требуетсяВписать = true
  private var последнееПоколениеВписывания = -1
  private var экранныеУзлы: [ЭкранныйУзел] = []

  init(ресурсы: ГрафическиеРесурсы) {
    self.ресурсы = ресурсы
    super.init()
    слойНадписей.isGeometryFlipped = true
    слойНадписей.masksToBounds = true
  }

  func подключить(_ полотно: ПолотноДерева) {
    self.полотно = полотно
    слойНадписей.frame = полотно.bounds
    слойНадписей.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
    полотно.layer?.addSublayer(слойНадписей)
  }

  func обновить(
    снимок: СнимокДерева,
    раскладка: РезультатРаскладки,
    запрос: String,
    выбранныйИдентификатор: String?,
    поколениеВписывания: Int,
    выбрать: @escaping (String?) -> Void,
    открытьИлиСвернуть: @escaping (String) -> Void
  ) {
    self.снимок = снимок
    self.раскладка = раскладка
    self.запрос = запрос.trimmingCharacters(in: .whitespacesAndNewlines)
    self.выбранныйИдентификатор = выбранныйИдентификатор
    self.выбрать = выбрать
    self.открытьИлиСвернуть = открытьИлиСвернуть
    if поколениеВписывания != последнееПоколениеВписывания {
      последнееПоколениеВписывания = поколениеВписывания
      требуетсяВписать = true
    }
  }

  func сдвинуть(на сдвиг: CGSize) {
    центр.x -= сдвиг.width / масштаб
    центр.y += сдвиг.height / масштаб
    запроситьОтрисовку()
  }

  func масштабировать(в множитель: CGFloat, около опорнаяТочка: CGPoint) {
    guard let полотно else { return }
    let стараяВеличина = масштаб
    let новаяВеличина = min(4.5, max(0.001, масштаб * множитель))
    guard abs(новаяВеличина - стараяВеличина) > 0.0001 else { return }

    let опорнаяТочкаСверху = CGPoint(
      x: опорнаяТочка.x,
      y: полотно.bounds.height - опорнаяТочка.y
    )
    let смещение = CGPoint(
      x: опорнаяТочкаСверху.x - полотно.bounds.midX,
      y: опорнаяТочкаСверху.y - полотно.bounds.midY
    )
    let мироваяТочка = CGPoint(
      x: центр.x + смещение.x / стараяВеличина,
      y: центр.y + смещение.y / стараяВеличина
    )
    масштаб = новаяВеличина
    центр = CGPoint(
      x: мироваяТочка.x - смещение.x / новаяВеличина,
      y: мироваяТочка.y - смещение.y / новаяВеличина
    )
    запроситьОтрисовку()
  }

  func обработатьЩелчок(в точка: CGPoint, числоЩелчков: Int) {
    guard let полотно else { return }
    let точкаСверху = CGPoint(x: точка.x, y: полотно.bounds.height - точка.y)
    let найденный =
      экранныеУзлы
      .filter {
        hypot($0.точка.x - точкаСверху.x, $0.точка.y - точкаСверху.y)
          <= max(16, $0.радиус + 5)
      }
      .min {
        hypot($0.точка.x - точкаСверху.x, $0.точка.y - точкаСверху.y)
          < hypot($1.точка.x - точкаСверху.x, $1.точка.y - точкаСверху.y)
      }
    выбрать?(найденный?.идентификатор)
    if числоЩелчков >= 2, let найденный {
      открытьИлиСвернуть?(найденный.идентификатор)
    }
  }

  func draw(in представление: MTKView) {
    guard
      let полотно = представление as? ПолотноДерева,
      let снимок,
      let раскладка,
      let изображениеНазначения = полотно.currentDrawable,
      let командныйБуфер = ресурсы.очередь.makeCommandBuffer()
    else {
      return
    }

    if требуетсяВписать {
      вписать(раскладку: раскладка, в: полотно.bounds.size)
      требуетсяВписать = false
    }

    let размерНазначения = полотно.drawableSize
    guard размерНазначения.width > 0, размерНазначения.height > 0 else { return }
    let изображение = собратьИзображение(
      снимок: снимок,
      раскладка: раскладка,
      размерПолотна: полотно.bounds.size,
      размерНазначения: размерНазначения
    )
    let границыНазначения = CGRect(origin: .zero, size: размерНазначения)
    ресурсы.контекст.render(
      изображение,
      to: изображениеНазначения.texture,
      commandBuffer: командныйБуфер,
      bounds: границыНазначения,
      colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
    )
    командныйБуфер.present(изображениеНазначения)
    командныйБуфер.commit()
    обновитьНадписи(масштабЭкрана: полотно.window?.backingScaleFactor ?? 2)
  }

  func mtkView(_ представление: MTKView, drawableSizeWillChange _: CGSize) {
    слойНадписей.frame = представление.bounds
    запроситьОтрисовку()
  }

  private func вписать(раскладку: РезультатРаскладки, в размер: CGSize) {
    центр = CGPoint(x: раскладку.ширина / 2, y: раскладку.высота / 2)
    let доступнаяШирина = max(120, размер.width - 100)
    let доступнаяВысота = max(120, размер.height - 100)
    масштаб = min(
      1.35,
      max(
        0.001,
        min(
          доступнаяШирина / max(1, раскладку.ширина),
          доступнаяВысота / max(1, раскладку.высота))
      )
    )
  }

  private func собратьИзображение(
    снимок: СнимокДерева,
    раскладка: РезультатРаскладки,
    размерПолотна: CGSize,
    размерНазначения: CGSize
  ) -> CIImage {
    let границы = CGRect(origin: .zero, size: размерНазначения)
    var изображение = создатьФон(границы: границы)
    let горизонтальныйМножитель = размерНазначения.width / max(1, размерПолотна.width)
    let вертикальныйМножитель = размерНазначения.height / max(1, размерПолотна.height)
    let узлыПоИдентификатору = Dictionary(uniqueKeysWithValues: снимок.узлы.map { ($0.id, $0) })
    let скрыватьДокументы = масштаб < 0.38
    let полеВидимости = CGRect(origin: .zero, size: размерПолотна).insetBy(dx: -80, dy: -80)

    экранныеУзлы = раскладка.видимыеИдентификаторы.compactMap { идентификатор in
      guard
        let узел = узлыПоИдентификатору[идентификатор],
        let положение = раскладка.положения[идентификатор],
        !(скрыватьДокументы && узел.вид == .документ)
      else { return nil }
      let точка = экраннаяТочка(положение, размер: размерПолотна)
      guard полеВидимости.contains(точка) else { return nil }
      let радиус = радиусУзла(узел)
      return ЭкранныйУзел(
        идентификатор: идентификатор,
        узел: узел,
        точка: точка,
        радиус: радиус,
        совпадаетСПоиском: совпадаетСПоиском(узел)
      )
    }
    let видимые = Set(экранныеУзлы.map(\.идентификатор))

    for ребро in раскладка.рёбра {
      guard
        let начало = раскладка.положения[ребро.от],
        let конец = раскладка.положения[ребро.к],
        !(скрыватьДокументы && узлыПоИдентификатору[ребро.к]?.вид == .документ)
      else { continue }
      let перваяТочка = экраннаяТочка(начало, размер: размерПолотна)
      let втораяТочка = экраннаяТочка(конец, размер: размерПолотна)
      let охват = CGRect(
        x: min(перваяТочка.x, втораяТочка.x),
        y: min(перваяТочка.y, втораяТочка.y),
        width: abs(перваяТочка.x - втораяТочка.x),
        height: abs(перваяТочка.y - втораяТочка.y)
      ).insetBy(dx: -3, dy: -3)
      guard
        полеВидимости.intersects(охват) || видимые.contains(ребро.от) || видимые.contains(ребро.к)
      else {
        continue
      }
      let приглушено =
        !запрос.isEmpty
        && !(узлыПоИдентификатору[ребро.к].map(совпадаетСПоиском) ?? false)
      let цвет = CIColor(red: 0.25, green: 0.46, blue: 0.62, alpha: приглушено ? 0.08 : 0.34)
      изображение = создатьЛинию(
        от: точкаНазначения(
          перваяТочка, размерПолотна: размерПолотна,
          горизонтальныйМножитель: горизонтальныйМножитель,
          вертикальныйМножитель: вертикальныйМножитель),
        к: точкаНазначения(
          втораяТочка, размерПолотна: размерПолотна,
          горизонтальныйМножитель: горизонтальныйМножитель,
          вертикальныйМножитель: вертикальныйМножитель),
        толщина: max(1, min(3.2, масштаб * 1.4)) * горизонтальныйМножитель,
        цвет: цвет
      ).composited(over: изображение)
    }

    for экранныйУзел in экранныеУзлы {
      let точка = точкаНазначения(
        экранныйУзел.точка,
        размерПолотна: размерПолотна,
        горизонтальныйМножитель: горизонтальныйМножитель,
        вертикальныйМножитель: вертикальныйМножитель
      )
      let радиус = экранныйУзел.радиус * горизонтальныйМножитель
      let выделен = экранныйУзел.идентификатор == выбранныйИдентификатор
      if выделен || (!запрос.isEmpty && экранныйУзел.совпадаетСПоиском) {
        let цветОреола =
          выделен
          ? CIColor(red: 0.35, green: 0.85, blue: 1, alpha: 0.9)
          : CIColor(red: 1, green: 0.76, blue: 0.28, alpha: 0.78)
        изображение = создатьКруг(
          центр: точка, радиус: радиус + 4 * горизонтальныйМножитель, цвет: цветОреола
        )
        .composited(over: изображение)
      }
      let цвет = цветУзла(экранныйУзел)
      изображение = создатьКруг(центр: точка, радиус: радиус, цвет: цвет)
        .composited(over: изображение)
    }
    return изображение
  }

  private func создатьФон(границы: CGRect) -> CIImage {
    let основной = CIImage(color: CIColor(red: 0.025, green: 0.04, blue: 0.065, alpha: 1))
      .cropped(to: границы)
    let свечение = CIFilter.radialGradient()
    свечение.center = CGPoint(x: границы.midX * 0.85, y: границы.midY * 1.1)
    свечение.radius0 = 0
    свечение.radius1 = Float(max(границы.width, границы.height) * 0.82)
    свечение.color0 = CIColor(red: 0.06, green: 0.18, blue: 0.27, alpha: 0.78)
    свечение.color1 = CIColor(red: 0.025, green: 0.04, blue: 0.065, alpha: 0)
    return (свечение.outputImage ?? основной).cropped(to: границы).composited(over: основной)
  }

  private func создатьЛинию(от: CGPoint, к: CGPoint, толщина: CGFloat, цвет: CIColor) -> CIImage {
    let длина = max(0.001, hypot(к.x - от.x, к.y - от.y))
    let угол = atan2(к.y - от.y, к.x - от.x)
    let полоса = CIImage(color: цвет).cropped(
      to: CGRect(x: 0, y: -толщина / 2, width: длина, height: толщина)
    )
    return полоса.transformed(
      by: CGAffineTransform(
        a: cos(угол), b: sin(угол), c: -sin(угол), d: cos(угол),
        tx: от.x, ty: от.y
      )
    )
  }

  private func создатьКруг(центр: CGPoint, радиус: CGFloat, цвет: CIColor) -> CIImage {
    let фильтр = CIFilter.roundedRectangleGenerator()
    фильтр.extent = CGRect(
      x: центр.x - радиус,
      y: центр.y - радиус,
      width: радиус * 2,
      height: радиус * 2
    )
    фильтр.radius = Float(радиус)
    фильтр.color = цвет
    return фильтр.outputImage!
  }

  private func экраннаяТочка(_ точка: ТочкаДерева, размер: CGSize) -> CGPoint {
    CGPoint(
      x: (точка.поГоризонтали - центр.x) * масштаб + размер.width / 2,
      y: (точка.поВертикали - центр.y) * масштаб + размер.height / 2
    )
  }

  private func точкаНазначения(
    _ точка: CGPoint,
    размерПолотна: CGSize,
    горизонтальныйМножитель: CGFloat,
    вертикальныйМножитель: CGFloat
  ) -> CGPoint {
    CGPoint(
      x: точка.x * горизонтальныйМножитель,
      y: (размерПолотна.height - точка.y) * вертикальныйМножитель
    )
  }

  private func радиусУзла(_ узел: УзелДерева) -> CGFloat {
    let основа: CGFloat = узел.вид == .документ ? 6.2 : 9
    return min(15, max(3.5, основа * max(0.68, масштаб)))
  }

  private func совпадаетСПоиском(_ узел: УзелДерева) -> Bool {
    guard !запрос.isEmpty else { return true }
    return узел.название.localizedCaseInsensitiveContains(запрос)
      || узел.относительныйПуть.localizedCaseInsensitiveContains(запрос)
  }

  private func цветУзла(_ экранныйУзел: ЭкранныйУзел) -> CIColor {
    let прозрачность: CGFloat = экранныйУзел.совпадаетСПоиском ? 0.96 : 0.16
    switch экранныйУзел.узел.вид {
    case .корень:
      return CIColor(red: 0.25, green: 0.9, blue: 0.78, alpha: прозрачность)
    case .каталог:
      return CIColor(red: 0.2, green: 0.65, blue: 0.95, alpha: прозрачность)
    case .документ:
      return CIColor(red: 0.68, green: 0.47, blue: 0.96, alpha: прозрачность)
    }
  }

  private func обновитьНадписи(масштабЭкрана: CGFloat) {
    let предел = масштаб < 0.55 ? 70 : 180
    let кандидаты = Array(
      экранныеУзлы
        .filter {
          масштаб >= 0.55 || $0.узел.вид != .документ
            || $0.идентификатор == выбранныйИдентификатор
        }
        .sorted {
          let первыйПриоритет = приоритетНадписи($0)
          let второйПриоритет = приоритетНадписи($1)
          return первыйПриоритет == второйПриоритет
            ? $0.узел.глубина < $1.узел.глубина
            : первыйПриоритет > второйПриоритет
        }
        .prefix(предел)
    )
    let нужныеИдентификаторы = Set(кандидаты.map(\.идентификатор))
    let устаревшиеИдентификаторы = слоиНадписей.keys.filter {
      !нужныеИдентификаторы.contains($0)
    }
    for идентификатор in устаревшиеИдентификаторы {
      слоиНадписей.removeValue(forKey: идентификатор)?.removeFromSuperlayer()
    }

    for экранныйУзел in кандидаты {
      let слой: CATextLayer
      if let существующийСлой = слоиНадписей[экранныйУзел.идентификатор] {
        слой = существующийСлой
      } else {
        let новыйСлой = CATextLayer()
        слоиНадписей[экранныйУзел.идентификатор] = новыйСлой
        слойНадписей.addSublayer(новыйСлой)
        слой = новыйСлой
      }
      слой.contentsScale = масштабЭкрана
      слой.string = экранныйУзел.узел.название
      слой.font = NSFont.systemFont(
        ofSize: экранныйУзел.узел.вид == .документ ? 11 : 12, weight: .medium)
      слой.fontSize = экранныйУзел.узел.вид == .документ ? 11 : 12
      слой.foregroundColor =
        NSColor.white.withAlphaComponent(экранныйУзел.совпадаетСПоиском ? 0.84 : 0.22).cgColor
      слой.truncationMode = .end
      слой.alignmentMode = .left
      слой.frame = CGRect(
        x: экранныйУзел.точка.x + экранныйУзел.радиус + 6,
        y: экранныйУзел.точка.y - 8,
        width: 190,
        height: 18
      )
    }
  }

  private func приоритетНадписи(_ экранныйУзел: ЭкранныйУзел) -> Int {
    if экранныйУзел.идентификатор == выбранныйИдентификатор { return 4 }
    if !запрос.isEmpty && экранныйУзел.совпадаетСПоиском { return 3 }
    if экранныйУзел.узел.вид != .документ { return 2 }
    return 1
  }

  private func запроситьОтрисовку() {
    guard let полотно else { return }
    полотно.setNeedsDisplay(полотно.bounds)
  }
}
