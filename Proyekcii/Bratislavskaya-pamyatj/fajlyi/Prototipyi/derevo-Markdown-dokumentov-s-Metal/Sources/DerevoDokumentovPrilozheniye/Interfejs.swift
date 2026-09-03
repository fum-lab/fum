import SwiftUI
import ДеревоДокументовЯдро

struct КорневойЭкран: View {
  @StateObject private var модель: МодельПриложения

  init(модель: МодельПриложения) {
    _модель = StateObject(wrappedValue: модель)
  }

  var body: some View {
    VStack(spacing: 0) {
      верхняяПанель
      Divider().overlay(Color.white.opacity(0.08))
      HStack(spacing: 0) {
        содержимое
        if let узел = модель.выбранныйУзел {
          Divider().overlay(Color.white.opacity(0.08))
          ИнспекторУзла(узел: узел)
            .frame(width: 286)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
      }
      Divider().overlay(Color.white.opacity(0.08))
      нижняяПанель
    }
    .background(Color(red: 0.025, green: 0.04, blue: 0.065))
    .preferredColorScheme(.dark)
    .animation(.easeOut(duration: 0.18), value: модель.выбранныйИдентификатор)
  }

  private var верхняяПанель: some View {
    HStack(spacing: 12) {
      Image(systemName: "point.3.connected.trianglepath.dotted")
        .foregroundStyle(.cyan)
      Text("Дерево Markdown")
        .font(.headline)
      Spacer(minLength: 20)
      HStack(spacing: 7) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
        TextField("Поиск по названию или пути", text: $модель.запросПоиска)
          .textFieldStyle(.plain)
          .frame(width: 260)
        if !модель.запросПоиска.isEmpty {
          Button {
            модель.запросПоиска = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))

      Button {
        модель.обновить()
      } label: {
        Label("Обновить", systemImage: "arrow.clockwise")
      }
      .keyboardShortcut("r", modifiers: .command)
      .disabled(модель.идётСканирование)

      if модель.идётСканирование {
        ProgressView()
          .controlSize(.small)
          .help("Сканирование Markdown-документов")
      }

      Button {
        модель.вписать()
      } label: {
        Label("Вписать", systemImage: "arrow.up.left.and.arrow.down.right")
      }
      .keyboardShortcut("0", modifiers: .command)
      .disabled(модель.раскладка == nil || модель.графическиеРесурсы == nil)
    }
    .buttonStyle(.borderless)
    .padding(.horizontal, 16)
    .frame(height: 54)
  }

  @ViewBuilder
  private var содержимое: some View {
    if let сообщение = модель.сообщениеОбОшибке {
      СостояниеОшибки(сообщение: сообщение, обновить: модель.обновить)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if let ресурсы = модель.графическиеРесурсы,
      let снимок = модель.снимок,
      let раскладка = модель.раскладка
    {
      МеталлическоеПолотно(
        ресурсы: ресурсы,
        снимок: снимок,
        раскладка: раскладка,
        запрос: модель.запросПоиска,
        выбранныйИдентификатор: модель.выбранныйИдентификатор,
        поколениеВписывания: модель.поколениеВписывания,
        выбрать: модель.выбрать,
        открытьИлиСвернуть: модель.обработатьДвойнойЩелчок
      )
      .overlay(alignment: .topLeading) {
        Text(
          "Перетаскивание — обзор · жест масштаба или ⌥ + колесо — масштаб · двойной щелчок — открыть или свернуть"
        )
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.black.opacity(0.34), in: Capsule())
        .padding(12)
      }
    } else if let снимок = модель.снимок {
      ОграниченныйРежим(
        снимок: снимок,
        запрос: модель.запросПоиска,
        выбрать: модель.выбрать
      )
    } else {
      ProgressView("Сканирование Markdown-документов…")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private var нижняяПанель: some View {
    HStack(spacing: 10) {
      Label("\(модель.числоДокументов) Markdown-документов", systemImage: "doc.text")
      if модель.числоПропущенныхПутей > 0 {
        Text("·").foregroundStyle(.tertiary)
        Label("\(модель.числоПропущенныхПутей) путей пропущено", systemImage: "eye.slash")
          .foregroundStyle(.orange)
      }
      Text("·").foregroundStyle(.tertiary)
      if модель.графическиеРесурсы == nil {
        Label("Ограниченный режим", systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
      } else {
        Label(модель.имяУстройства, systemImage: "cpu")
          .foregroundStyle(.cyan)
      }
      Spacer()
      Text(модель.корень.path)
        .lineLimit(1)
        .truncationMode(.middle)
        .help(модель.корень.path)
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 16)
    .frame(height: 34)
  }
}

private struct ИнспекторУзла: View {
  let узел: УзелДерева

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HStack(spacing: 10) {
          Image(systemName: значок)
            .font(.title2)
            .foregroundStyle(узел.вид == .документ ? .purple : .cyan)
          VStack(alignment: .leading, spacing: 3) {
            Text("Выбранный узел")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(узел.название)
              .font(.headline)
              .lineLimit(2)
          }
        }
        поле("Путь", значение: узел.относительныйПуть)
        поле("Тип", значение: описаниеВида)
        поле("Ссылки", значение: "\(узел.числоСсылок)")
        поле("Глубина", значение: "\(узел.глубина)")
        if узел.вид == .документ {
          Text("Двойной щелчок по узлу открывает документ в приложении по умолчанию.")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          Text("Двойной щелчок сворачивает или раскрывает эту ветвь.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color.black.opacity(0.14))
  }

  private var значок: String {
    switch узел.вид {
    case .корень: "externaldrive.fill"
    case .каталог: "folder.fill"
    case .документ: "doc.text.fill"
    }
  }

  private var описаниеВида: String {
    switch узел.вид {
    case .корень: "Корень репозитория"
    case .каталог: "Каталог"
    case .документ: "Markdown-документ"
    }
  }

  private func поле(_ название: String, значение: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(название.uppercased())
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(значение)
        .font(.callout)
        .textSelection(.enabled)
    }
  }
}

private struct ОграниченныйРежим: View {
  let снимок: СнимокДерева
  let запрос: String
  let выбрать: (String?) -> Void

  var body: some View {
    VStack(spacing: 14) {
      Label("Ограниченный режим", systemImage: "exclamationmark.triangle.fill")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.orange)
      Text(
        "Metal-устройство или очередь команд недоступны. Аппаратная визуализация отключена; ниже показан текстовый список."
      )
      .multilineTextAlignment(.center)
      .foregroundStyle(.secondary)
      .frame(maxWidth: 560)
      List(отфильтрованныеУзлы, id: \.id) { узел in
        Button {
          выбрать(узел.id)
        } label: {
          HStack {
            Image(systemName: узел.вид == .документ ? "doc.text" : "folder")
            Text(узел.относительныйПуть)
            Spacer()
            Text("\(узел.числоСсылок)")
              .foregroundStyle(.secondary)
          }
        }
        .buttonStyle(.plain)
      }
      .frame(maxWidth: 820, maxHeight: 620)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var отфильтрованныеУзлы: [УзелДерева] {
    guard !запрос.isEmpty else { return снимок.узлы }
    return снимок.узлы.filter {
      $0.название.localizedCaseInsensitiveContains(запрос)
        || $0.относительныйПуть.localizedCaseInsensitiveContains(запрос)
    }
  }
}

private struct СостояниеОшибки: View {
  let сообщение: String
  let обновить: () -> Void

  var body: some View {
    ContentUnavailableView {
      Label("Не удалось построить дерево", systemImage: "exclamationmark.octagon")
    } description: {
      Text(сообщение)
    } actions: {
      Button("Повторить", action: обновить)
    }
  }
}
