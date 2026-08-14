import AppKit
import Foundation
import SwiftUI
import ДеревоДокументовЯдро

@main
enum ЗапускДереваДокументов {
  @MainActor
  static func main() {
    let параметры = Array(CommandLine.arguments.dropFirst())
    if параметры.first == "диагностика" {
      let корень = адресКорня(из: параметры.dropFirst().first)
      Foundation.exit(выполнитьДиагностику(корень: корень))
    }

    let корень = адресКорня(из: параметры.first)
    let приложение = NSApplication.shared
    let делегат = ДелегатПриложения(корень: корень)
    приложение.setActivationPolicy(.regular)
    приложение.delegate = делегат
    установитьГлавноеМеню(для: приложение)
    withExtendedLifetime(делегат) {
      приложение.run()
    }
  }

  private static func адресКорня(из путь: String?) -> URL {
    let исходныйПуть = путь ?? FileManager.default.currentDirectoryPath
    let раскрытыйПуть = (исходныйПуть as NSString).expandingTildeInPath
    return URL(fileURLWithPath: раскрытыйПуть, isDirectory: true).standardizedFileURL
  }

  private static func выполнитьДиагностику(корень: URL) -> Int32 {
    do {
      let снимок = try СканерРепозитория().сканировать(корень: корень)
      guard let ресурсы = ГрафическиеРесурсы.создать() else {
        напечататьДиагностику([
          "статус": "ограниченный_режим",
          "корень": корень.path,
          "ошибка": "Metal-устройство или очередь команд недоступны",
          "отрисовщик": "MTKView + Core Image + Metal",
          "число_документов": снимок.числоДокументов,
          "число_пропущенных_путей": снимок.пропущенныеПути.count,
          "число_узлов": снимок.узлы.count,
        ])
        return 3
      }

      _ = ресурсы.контекст
      let числоКаталогов = снимок.узлы.count { $0.вид != .документ }
      напечататьДиагностику([
        "статус": "готово",
        "корень": корень.path,
        "имя_устройства": ресурсы.устройство.name,
        "отрисовщик": "MTKView + Core Image + Metal",
        "число_документов": снимок.числоДокументов,
        "число_каталогов": числоКаталогов,
        "число_пропущенных_путей": снимок.пропущенныеПути.count,
        "число_узлов": снимок.узлы.count,
      ])
      return 0
    } catch {
      напечататьДиагностику([
        "статус": "ошибка",
        "корень": корень.path,
        "ошибка": error.localizedDescription,
      ])
      return 2
    }
  }

  private static func напечататьДиагностику(_ объект: [String: Any]) {
    guard
      let данные = try? JSONSerialization.data(withJSONObject: объект, options: [.sortedKeys]),
      var строка = String(data: данные, encoding: .utf8)
    else {
      return
    }
    строка.append("\n")
    FileHandle.standardOutput.write(Data(строка.utf8))
  }

  @MainActor
  private static func установитьГлавноеМеню(для приложение: NSApplication) {
    let главноеМеню = NSMenu()
    let пунктПриложения = NSMenuItem()
    главноеМеню.addItem(пунктПриложения)
    let менюПриложения = NSMenu()
    менюПриложения.addItem(
      withTitle: "Завершить Дерево Markdown",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    пунктПриложения.submenu = менюПриложения

    let пунктОкна = NSMenuItem()
    главноеМеню.addItem(пунктОкна)
    let менюОкна = NSMenu(title: "Окно")
    менюОкна.addItem(
      withTitle: "Закрыть окно",
      action: #selector(NSWindow.performClose(_:)),
      keyEquivalent: "w"
    )
    пунктОкна.submenu = менюОкна
    приложение.mainMenu = главноеМеню
  }
}

@MainActor
private final class ДелегатПриложения: NSObject, NSApplicationDelegate {
  private let корень: URL
  private var окно: NSWindow?

  init(корень: URL) {
    self.корень = корень
  }

  func applicationDidFinishLaunching(_: Notification) {
    let модель = МодельПриложения(
      корень: корень,
      графическиеРесурсы: ГрафическиеРесурсы.создать()
    )
    let окно = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    окно.title = "Дерево Markdown — \(корень.lastPathComponent)"
    окно.titlebarAppearsTransparent = true
    окно.minSize = NSSize(width: 860, height: 560)
    окно.contentView = NSHostingView(rootView: КорневойЭкран(модель: модель))
    окно.center()
    окно.makeKeyAndOrderFront(nil)
    self.окно = окно
    NSRunningApplication.current.activate(options: [.activateAllWindows])
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    true
  }
}
