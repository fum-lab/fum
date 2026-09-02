import Foundation

public enum РешениеСценарияПроекта: String, Codable, Equatable, Sendable {
  case пройдено
  case провалено
}

public struct ПроверкаСценарияПроекта: Codable, Equatable, Sendable {
  public let идентификатор: String
  public let пройдена: Bool
}

public struct ОтчётСценарияПроекта: Codable, Equatable, Sendable {
  public let идентификаторСхемы: String
  public let версияСхемы: Int
  public let идентификаторСценария: String
  public let решение: РешениеСценарияПроекта
  public let идентичностиРепозиториев: [String]
  public let проверки: [ПроверкаСценарияПроекта]
  public let хэшПаспорта: String?
  public let исходныйКоммитПроекта: String?
  public let итоговыйКоммитПроекта: String?
  public let исходныйКоммитРодителя: String?
  public let итоговыйКоммитРодителя: String?
  public let неожиданноеИзменениеСсылок: Bool

  enum CodingKeys: String, CodingKey {
    case идентификаторСхемы = "идентификатор_схемы"
    case версияСхемы = "версия_схемы"
    case идентификаторСценария = "идентификатор_сценария"
    case решение
    case идентичностиРепозиториев = "идентичности_репозиториев"
    case проверки
    case хэшПаспорта = "хэш_паспорта"
    case исходныйКоммитПроекта = "исходный_коммит_проекта"
    case итоговыйКоммитПроекта = "итоговый_коммит_проекта"
    case исходныйКоммитРодителя = "исходный_коммит_родителя"
    case итоговыйКоммитРодителя = "итоговый_коммит_родителя"
    case неожиданноеИзменениеСсылок = "неожиданное_изменение_ссылок"
  }

  public func каноническиеДанные() throws -> Data {
    try DurableForkJSON.encode(self)
  }
}

public struct ПаспортПроекта: Codable, Equatable, Sendable {
  public let идентификаторСхемы: String
  public let версияСхемы: Int
  public let идентификаторПроекта: String
  public let идентификаторРепозитория: String
  public let адресРепозитория: String
  public let цель: String
  public let рабочаяСсылка: String
  public let уровеньДоступа: RepositoryCompositionAccessLevel
  public let границаПубликации: RepositoryCompositionAccessLevel
  public let путьПравил: String
  public let пространствоСсылокОчереди: String
  public let путьОчереди: String
  public let пространствоСсылокЗахвата: String
  public let путьДиспетчера: String
  public let путьРабочегоНабора: String
  public let хэшРабочегоНабора: String
  public let путьКарточки: String
  public let источники: [String]
  public let проверки: [String]
  public let условиеЗавершения: String

  enum CodingKeys: String, CodingKey {
    case идентификаторСхемы = "идентификатор_схемы"
    case версияСхемы = "версия_схемы"
    case идентификаторПроекта = "идентификатор_проекта"
    case идентификаторРепозитория = "идентификатор_репозитория"
    case адресРепозитория = "адрес_репозитория"
    case цель
    case рабочаяСсылка = "рабочая_ссылка"
    case уровеньДоступа = "уровень_доступа"
    case границаПубликации = "граница_публикации"
    case путьПравил = "путь_правил"
    case пространствоСсылокОчереди = "пространство_ссылок_очереди"
    case путьОчереди = "путь_очереди"
    case пространствоСсылокЗахвата = "пространство_ссылок_захвата"
    case путьДиспетчера = "путь_диспетчера"
    case путьРабочегоНабора = "путь_рабочего_набора"
    case хэшРабочегоНабора = "хэш_рабочего_набора"
    case путьКарточки = "путь_карточки"
    case источники
    case проверки
    case условиеЗавершения = "условие_завершения"
  }

  public func каноническиеДанные() throws -> Data {
    try DurableForkJSON.encode(self)
  }
}

struct РегистрацияПроекта: Codable, Equatable, Sendable {
  let идентификаторСхемы: String
  let версияСхемы: Int
  let проект: RepositoryCompositionChild

  enum CodingKeys: String, CodingKey {
    case идентификаторСхемы = "идентификатор_схемы"
    case версияСхемы = "версия_схемы"
    case проект
  }

  func каноническиеДанные() throws -> Data {
    try DurableForkJSON.encode(self)
  }
}

enum ОшибкаРепозиторияПроекта: Error, Sendable {
  case неизвестнаяФикстура(String)
  case подготовка(String)
  case команда(String)
}

struct СнимокСсылокПроекта: Equatable, Sendable {
  let проект: String
  let родитель: String

  static func прочитать(
    проект: URL,
    родитель: URL,
    гит: CandidateIntegrationGit
  ) throws -> СнимокСсылокПроекта {
    СнимокСсылокПроекта(
      проект: try гит.text(
        ["for-each-ref", "--format=%(refname) %(objectname)"], at: проект),
      родитель: try гит.text(
        ["for-each-ref", "--format=%(refname) %(objectname)"], at: родитель)
    )
  }
}

enum ПредварительнаяПроверкаПроекта {
  static let путьПаспорта = "Паспорт-проекта.json"
  static let путьРегистрации = "Проекты/регистрации/самостоятельный.json"

  static func разобратьЗакрытуюРегистрацию(
    данные: Data,
    путьПроекта: String
  ) -> РегистрацияПроекта? {
    guard данные.count <= 1_048_576 else { return nil }
    var обнаружитель = JSONDuplicateKeyDetector(data: данные)
    guard (try? обнаружитель.scan().isEmpty) == true,
      let корень = try? JSONSerialization.jsonObject(with: данные) as? [String: Any],
      Set(корень.keys) == ["идентификатор_схемы", "версия_схемы", "проект"],
      let проектОбъект = корень["проект"] as? [String: Any]
    else { return nil }

    let ключиПроекта: Set<String> = [
      "entry_id", "kind", "project_id", "repository_id", "repository_url", "base_oid",
      "live_ref", "submodule_path", "gitlink_oid", "snapshot_mode", "writer_mode",
      "nested_submodules", "access_level", "publication_boundary", "checks", "handoff",
    ]
    guard Set(проектОбъект.keys) == ключиПроекта,
      let маршрут = проектОбъект["handoff"] as? [String: Any],
      Set(маршрут.keys)
        == ["target_repository_id", "target_ref", "required_check_ids"],
      let вложенныеЗначения = проектОбъект["nested_submodules"] as? [Any]
    else { return nil }
    for значение in вложенныеЗначения {
      guard let вложенный = значение as? [String: Any],
        Set(вложенный.keys) == ["repository_id", "submodule_path"]
      else { return nil }
    }

    guard let регистрация = try? JSONDecoder().decode(РегистрацияПроекта.self, from: данные),
      let базовыйКоммит = регистрация.проект.baseOID,
      let ссылкаПодмодуля = регистрация.проект.gitlinkOID,
      let вложенныеПодмодули = регистрация.проект.nestedSubmodules,
      DurableForkValidation.isOID(базовыйКоммит),
      DurableForkValidation.isOID(ссылкаПодмодуля)
    else { return nil }
    _ = вложенныеПодмодули

    let проверки = ["project-passport", "project-control-plane", "project-parent-gitlink"]
    let проект = регистрация.проект
    guard регистрация.идентификаторСхемы == "urn:fum:schema:project-registration:v1",
      регистрация.версияСхемы == 1,
      проект.entryID == "entry.project.fixture",
      проект.kind == .project,
      проект.projectID == "project.independent.fixture",
      проект.repositoryID == "repository.project.fixture",
      проект.repositoryURL == "urn:fum:repository:project-fixture",
      проект.liveRef == "refs/heads/project-main",
      проект.submodulePath == путьПроекта,
      проект.snapshotMode == "detached_read_only",
      проект.writerMode == "separate_clone",
      проект.checks == проверки,
      проект.handoff.targetRepositoryID == "repository.parent.fixture",
      проект.handoff.targetRef == "refs/heads/main",
      проект.handoff.requiredCheckIDs == проверки
    else { return nil }
    return регистрация
  }

  static func проверитьПаспорт(
    данные: Data?,
    коммит: String,
    репозиторий: URL,
    живойКлон: URL,
    родительскийКлон: URL,
    гит: CandidateIntegrationGit
  ) throws -> [String] {
    guard let данные else { return ["project_passport_missing"] }
    guard данные.count <= 1_048_576,
      var объект = try? JSONSerialization.jsonObject(with: данные) as? [String: Any]
    else { return ["project_passport_invalid"] }

    var обнаружитель = JSONDuplicateKeyDetector(data: данные)
    guard (try? обнаружитель.scan().isEmpty) == true else {
      return ["project_passport_duplicate_key"]
    }
    let ожидаемыеКлючи: Set<String> = [
      "идентификатор_схемы", "версия_схемы", "идентификатор_проекта",
      "идентификатор_репозитория", "адрес_репозитория", "цель", "рабочая_ссылка",
      "уровень_доступа", "граница_публикации", "путь_правил",
      "пространство_ссылок_очереди", "путь_очереди", "пространство_ссылок_захвата",
      "путь_диспетчера", "путь_рабочего_набора", "хэш_рабочего_набора",
      "путь_карточки", "источники", "проверки", "условие_завершения",
    ]
    guard Set(объект.keys) == ожидаемыеКлючи,
      let паспорт = try? JSONDecoder().decode(ПаспортПроекта.self, from: данные)
    else { return ["project_passport_closed_contract_invalid"] }
    объект.removeAll(keepingCapacity: false)

    var нарушения: [String] = []
    if паспорт.идентификаторСхемы != "urn:fum:schema:project-passport:v1"
      || паспорт.версияСхемы != 1
      || паспорт.идентификаторПроекта != "project.independent.fixture"
      || паспорт.идентификаторРепозитория != "repository.project.fixture"
      || паспорт.адресРепозитория != "urn:fum:repository:project-fixture"
    {
      нарушения.append("project_identity_invalid")
    }
    if паспорт.цель.isEmpty || паспорт.источники.isEmpty || паспорт.проверки.isEmpty
      || паспорт.условиеЗавершения.isEmpty
    {
      нарушения.append("project_scope_incomplete")
    }
    if !DurableForkValidation.isBranchRef(паспорт.рабочаяСсылка)
      || паспорт.рабочаяСсылка != "refs/heads/project-main"
      || паспорт.уровеньДоступа != .public
      || паспорт.границаПубликации != .public
    {
      нарушения.append("project_boundary_invalid")
    }
    if паспорт.путьПравил != "AGENTS.md"
      || паспорт.пространствоСсылокОчереди != "refs/fum/worktree-task-queues"
      || паспорт.пространствоСсылокЗахвата != "refs/fum/worktree-next-step-claims"
      || паспорт.путьОчереди
        != "Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py"
      || паспорт.путьДиспетчера
        != "Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py"
      || !DurableForkValidation.isRelativePath(паспорт.путьРабочегоНабора)
      || !DurableForkValidation.isRelativePath(паспорт.путьКарточки)
    {
      нарушения.append("project_control_plane_invalid")
    }

    let обязательныеПути = [
      "README.md", Self.путьПаспорта, паспорт.путьПравил, паспорт.путьОчереди,
      паспорт.путьДиспетчера, паспорт.путьРабочегоНабора, паспорт.путьКарточки,
    ]
    for путь in обязательныеПути
    where
      !(try гит.succeeds(
        ["cat-file", "-e", "\(коммит):\(путь)"], at: репозиторий))
    {
      нарушения.append(
        путь == паспорт.путьРабочегоНабора
          ? "project_next_step_missing" : "project_required_file_missing")
    }
    if let данныеНабора = try? гит.data(
      ["cat-file", "blob", "\(коммит):\(паспорт.путьРабочегоНабора)"], at: репозиторий),
      DurableForkJSON.sha256(данныеНабора) != паспорт.хэшРабочегоНабора
    {
      нарушения.append("project_next_step_hash_mismatch")
    }
    if let данныеЧитаемогоПаспорта = try? гит.data(
      ["cat-file", "blob", "\(коммит):README.md"], at: репозиторий),
      !String(decoding: данныеЧитаемогоПаспорта, as: UTF8.self).contains(Self.путьПаспорта)
    {
      нарушения.append("project_readme_passport_binding_missing")
    }

    let общийКаталогПроекта = try гит.text(
      ["rev-parse", "--path-format=absolute", "--git-common-dir"], at: живойКлон)
    let общийКаталогРодителя = try гит.text(
      ["rev-parse", "--path-format=absolute", "--git-common-dir"], at: родительскийКлон)
    if URL(fileURLWithPath: общийКаталогПроекта).standardizedFileURL.resolvingSymlinksInPath()
      == URL(fileURLWithPath: общийКаталогРодителя).standardizedFileURL.resolvingSymlinksInPath()
      || живойКлон.standardizedFileURL.resolvingSymlinksInPath()
        == родительскийКлон.standardizedFileURL.resolvingSymlinksInPath()
    {
      нарушения.append("project_checkout_not_separate")
    }
    let исходныйАдрес = try гит.text(["remote", "get-url", "origin"], at: живойКлон)
    if !DurableForkValidation.sameLocation(исходныйАдрес, репозиторий) {
      нарушения.append("project_origin_invalid")
    }
    return Array(Set(нарушения)).sorted()
  }

  static func проверитьРодительскуюРегистрацию(
    коммитРодителя: String,
    репозиторийРодителя: URL,
    репозиторийПроекта: URL,
    путьПроекта: String,
    гит: CandidateIntegrationGit
  ) throws -> (РегистрацияПроекта?, [String]) {
    guard
      let данные = try? гит.data(
        ["cat-file", "blob", "\(коммитРодителя):\(Self.путьРегистрации)"],
        at: репозиторийРодителя
      )
    else { return (nil, ["parent_registration_missing"]) }
    guard
      let регистрация = разобратьЗакрытуюРегистрацию(
        данные: данные,
        путьПроекта: путьПроекта)
    else { return (nil, ["parent_registration_invalid"]) }
    var нарушения: [String] = []
    let проект = регистрация.проект
    if проект.accessLevel != .public || проект.publicationBoundary != .public {
      нарушения.append("parent_registration_contract_invalid")
    }
    let строкаДерева = try гит.text(
      ["-c", "core.quotePath=false", "ls-tree", коммитРодителя, "--", путьПроекта],
      at: репозиторийРодителя)
    let части = строкаДерева.split(whereSeparator: { $0 == " " || $0 == "\t" })
    guard части.count >= 3, части[0] == "160000", части[1] == "commit" else {
      return (регистрация, Array(Set(нарушения + ["parent_path_not_gitlink"])).sorted())
    }
    let фактическаяСсылкаПодмодуля = String(части[2])
    if проект.gitlinkOID != фактическаяСсылкаПодмодуля {
      нарушения.append("parent_gitlink_mismatch")
    }
    if !(try гит.succeeds(
      ["cat-file", "-e", "\(фактическаяСсылкаПодмодуля)^{commit}"],
      at: репозиторийПроекта))
    {
      нарушения.append("parent_gitlink_unavailable")
    }
    if let базовыйКоммит = проект.baseOID {
      let базовыйКоммитДоступен = try гит.succeeds(
        ["cat-file", "-e", "\(базовыйКоммит)^{commit}"], at: репозиторийПроекта)
      let проверкаПредка = try гит.succeeds(
        ["merge-base", "--is-ancestor", базовыйКоммит, фактическаяСсылкаПодмодуля],
        at: репозиторийПроекта)
      let являетсяПредком = базовыйКоммитДоступен && проверкаПредка
      if !являетсяПредком {
        нарушения.append("parent_registration_base_invalid")
      }
    }
    let модули = try гит.text(
      ["show", "\(коммитРодителя):.gitmodules"], at: репозиторийРодителя)
    if !модули.contains("path = \(путьПроекта)") || !модули.contains("url = ../project.git") {
      нарушения.append("parent_submodule_route_invalid")
    }
    return (регистрация, Array(Set(нарушения)).sorted())
  }
}

enum ЛокальныеИнструментыПроекта {
  private static let загрузчикОчереди =
    "import os,subprocess,sys;"
    + "p=sys.argv[1];r=sys.argv[2];"
    + "e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};"
    + "e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';"
    + "b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);"
    + "sys.argv=[p,*sys.argv[3:],'--repo-root',r];exec(compile(b,p,'exec'))"

  static func диспетчер(
    корень: URL,
    путь: String,
    команда: String,
    аргументы: [String] = []
  ) throws -> [String: Any] {
    try выполнитьМашинно(
      аргументы: [корень.appending(path: путь).path, команда] + аргументы
        + ["--repo-root", корень.path, "--json"],
      каталог: корень)
  }

  static func очередь(
    корень: URL,
    путь: String,
    аргументы: [String]
  ) throws -> [String: Any] {
    try выполнитьМашинно(
      аргументы: ["-I", "-c", загрузчикОчереди, путь, корень.path] + аргументы + ["--json"],
      каталог: корень)
  }

  private static func выполнитьМашинно(
    аргументы: [String],
    каталог: URL
  ) throws -> [String: Any] {
    let процесс = Process()
    let системныйКаталог = WritingSubnodeSystemRuntime.gitExecutableURL.deletingLastPathComponent()
    процесс.executableURL = системныйКаталог.appending(path: "env")
    процесс.arguments = ["python3"] + аргументы
    процесс.currentDirectoryURL = каталог
    var окружение = ProcessInfo.processInfo.environment.filter {
      !$0.key.uppercased().hasPrefix("GIT_")
    }
    окружение["GIT_CONFIG_NOSYSTEM"] = "1"
    окружение["GIT_CONFIG_GLOBAL"] = WritingSubnodeSystemRuntime.nullDevicePath
    окружение["GIT_NO_REPLACE_OBJECTS"] = "1"
    окружение["GIT_OPTIONAL_LOCKS"] = "0"
    окружение["PYTHONDONTWRITEBYTECODE"] = "1"
    окружение["LC_ALL"] = "C"
    процесс.environment = окружение
    let вывод = Pipe()
    let ошибки = Pipe()
    процесс.standardOutput = вывод
    процесс.standardError = ошибки
    try процесс.run()
    процесс.waitUntilExit()
    let данные = вывод.fileHandleForReading.readDataToEndOfFile()
    let данныеОшибки = ошибки.fileHandleForReading.readDataToEndOfFile()
    guard процесс.terminationStatus == 0 else {
      let подробности = String(decoding: данныеОшибки, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      throw ОшибкаРепозиторияПроекта.команда(
        "Локальный проектный инструмент завершился с кодом \(процесс.terminationStatus): \(подробности)"
      )
    }
    guard let объект = try JSONSerialization.jsonObject(with: данные) as? [String: Any] else {
      throw ОшибкаРепозиторияПроекта.команда(
        "Локальный проектный инструмент вернул не-JSON-объект.")
    }
    return объект
  }
}
