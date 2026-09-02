import Darwin
import Foundation

private struct ContentAddressedGenerationPointer: Codable, Equatable {
  let schemaVersion: Int
  let canonicalProfile: String
  let generationSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case canonicalProfile = "canonical_profile"
    case generationSHA256 = "generation_sha256"
  }
}

private struct ContentAddressedGenerationPointerSchemaEnvelope: Decodable {
  let schemaVersion: Int

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
  }
}

enum ContentAddressedGenerationPublicationLockEvent {
  case willAcquire
  case didAcquire
}

enum ContentAddressedGenerationCommitCheckpoint: String, CaseIterable, Sendable {
  case generationTemporaryWritten = "generation-temporary-written"
  case generationFileSynchronized = "generation-file-synchronized"
  case generationPublished = "generation-published"
  case generationsDirectorySynchronized = "generations-directory-synchronized"
  case currentTemporaryWritten = "current-temporary-written"
  case currentFileSynchronized = "current-file-synchronized"
  case currentPublished = "current-published"
  case rootDirectorySynchronized = "root-directory-synchronized"
}

public struct StoredContentAddressedGeneration: Equatable, Sendable {
  public let generationSHA256: String
  public let canonicalData: Data

  public init(generationSHA256: String, canonicalData: Data) {
    self.generationSHA256 = generationSHA256
    self.canonicalData = canonicalData
  }
}

public enum ContentAddressedGenerationStoreError: Error, Equatable, Sendable {
  case incompatibleGeneration(String)
  case corruptGeneration(String)
  case generationConflict(expected: String?, actual: String?)
  case generationStore(String)
}

extension ContentAddressedGenerationStoreError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .incompatibleGeneration(let message), .corruptGeneration(let message),
      .generationStore(let message):
      return message
    case .generationConflict(let expected, let actual):
      return
        "Конфликт поколения: ожидалось \(expected ?? "пустое состояние"), подтверждено \(actual ?? "пустое состояние")."
    }
  }
}

public struct ContentAddressedGenerationStore {
  private static let maximumPointerBytes = 4_096

  public let rootURL: URL
  public let canonicalProfile: String
  public let maximumGenerationBytes: Int

  private let validateGeneration: (Data) throws -> Void
  private let validateLineage: (Data, StoredContentAddressedGeneration?) throws -> Void
  private let previousGenerationSHA256: ((Data) throws -> String?)?
  private let beforePointerCommit: (() throws -> Void)?
  private let publicationLockObserver:
    ((ContentAddressedGenerationPublicationLockEvent) throws -> Void)?
  private let commitCheckpointObserver:
    ((ContentAddressedGenerationCommitCheckpoint) throws -> Void)?

  public init(
    rootURL: URL,
    canonicalProfile: String,
    maximumGenerationBytes: Int,
    validateGeneration: @escaping (Data) throws -> Void,
    validateLineage:
      @escaping (
        Data,
        StoredContentAddressedGeneration?
      ) throws -> Void,
    previousGenerationSHA256: ((Data) throws -> String?)? = nil
  ) {
    self.init(
      rootURL: rootURL,
      canonicalProfile: canonicalProfile,
      maximumGenerationBytes: maximumGenerationBytes,
      validateGeneration: validateGeneration,
      validateLineage: validateLineage,
      previousGenerationSHA256: previousGenerationSHA256,
      beforePointerCommit: nil,
      publicationLockObserver: nil,
      commitCheckpointObserver: nil
    )
  }

  init(
    rootURL: URL,
    canonicalProfile: String,
    maximumGenerationBytes: Int,
    validateGeneration: @escaping (Data) throws -> Void,
    validateLineage:
      @escaping (
        Data,
        StoredContentAddressedGeneration?
      ) throws -> Void,
    previousGenerationSHA256: ((Data) throws -> String?)? = nil,
    beforePointerCommit: (() throws -> Void)?,
    publicationLockObserver:
      ((ContentAddressedGenerationPublicationLockEvent) throws -> Void)?,
    commitCheckpointObserver:
      ((ContentAddressedGenerationCommitCheckpoint) throws -> Void)?
  ) {
    self.rootURL = rootURL
    self.canonicalProfile = canonicalProfile
    self.maximumGenerationBytes = maximumGenerationBytes
    self.validateGeneration = validateGeneration
    self.validateLineage = validateLineage
    self.previousGenerationSHA256 = previousGenerationSHA256
    self.beforePointerCommit = beforePointerCommit
    self.publicationLockObserver = publicationLockObserver
    self.commitCheckpointObserver = commitCheckpointObserver
  }

  public func loadCurrent() throws -> StoredContentAddressedGeneration? {
    let pointerURL = rootURL.appendingPathComponent("CURRENT.json", isDirectory: false)
    guard FileManager.default.fileExists(atPath: pointerURL.path) else {
      return nil
    }

    let pointerData = try readBounded(
      pointerURL,
      limit: Self.maximumPointerBytes,
      kind: "указатель CURRENT"
    )
    let pointerEnvelope: ContentAddressedGenerationPointerSchemaEnvelope
    do {
      try CanonicalMemoryJSON.requireCanonical(pointerData)
      pointerEnvelope = try JSONDecoder().decode(
        ContentAddressedGenerationPointerSchemaEnvelope.self,
        from: pointerData
      )
    } catch {
      throw ContentAddressedGenerationStoreError.corruptGeneration(
        "Указатель CURRENT не соответствует каноническому профилю или схеме."
      )
    }
    switch pointerEnvelope.schemaVersion {
    case 1:
      throw ContentAddressedGenerationStoreError.incompatibleGeneration(
        "Указатель CURRENT схемы 1 не закрепляет языконейтральный профиль канонических байтов."
      )
    case 2:
      break
    default:
      throw ContentAddressedGenerationStoreError.incompatibleGeneration(
        "Указатель CURRENT имеет неподдерживаемую версию схемы."
      )
    }

    let pointer: ContentAddressedGenerationPointer
    do {
      pointer = try JSONDecoder().decode(
        ContentAddressedGenerationPointer.self,
        from: pointerData
      )
      guard try CanonicalMemoryJSON.encode(pointer) == pointerData else {
        throw CanonicalMemoryJSONError("Указатель CURRENT содержит поля вне точной схемы.")
      }
    } catch {
      throw ContentAddressedGenerationStoreError.corruptGeneration(
        "Указатель CURRENT не соответствует схеме."
      )
    }
    guard pointer.canonicalProfile == canonicalProfile,
      isContentAddressedSHA256(pointer.generationSHA256)
    else {
      throw ContentAddressedGenerationStoreError.incompatibleGeneration(
        "Указатель CURRENT имеет неподдерживаемый канонический профиль или хэш."
      )
    }

    let current = try loadGeneration(sha256: pointer.generationSHA256)
    try validateConfirmedLineage(from: current)
    return current
  }

  public func loadGeneration(
    sha256 generationSHA256: String
  ) throws -> StoredContentAddressedGeneration {
    guard isContentAddressedSHA256(generationSHA256) else {
      throw ContentAddressedGenerationStoreError.incompatibleGeneration(
        "Адрес поколения не является каноническим SHA-256."
      )
    }
    let generationURL = generationsURL.appendingPathComponent(
      "\(generationSHA256.dropFirst(7)).json",
      isDirectory: false
    )
    let generationData = try readBounded(
      generationURL,
      limit: maximumGenerationBytes,
      kind: "файл поколения"
    )
    guard CanonicalMemoryJSON.sha256(generationData) == generationSHA256 else {
      throw ContentAddressedGenerationStoreError.corruptGeneration(
        "Хэш файла поколения не совпадает с его контентным адресом."
      )
    }
    try validateGeneration(generationData)

    return StoredContentAddressedGeneration(
      generationSHA256: generationSHA256,
      canonicalData: generationData
    )
  }

  public func commit(
    _ canonicalData: Data,
    expectedPreviousGenerationSHA256: String?
  ) throws -> StoredContentAddressedGeneration {
    try validateGeneration(canonicalData)
    guard canonicalData.count <= maximumGenerationBytes else {
      throw ContentAddressedGenerationStoreError.generationStore(
        "Каноническое поколение превышает допустимый размер."
      )
    }
    let generationSHA256 = CanonicalMemoryJSON.sha256(canonicalData)
    let generationURL = generationsURL.appendingPathComponent(
      "\(generationSHA256.dropFirst(7)).json",
      isDirectory: false
    )

    try prepareStoreDirectories()
    try publishGeneration(canonicalData, at: generationURL)

    try beforePointerCommit?()
    return try withCurrentPublicationLock {
      let current = try loadCurrent()
      if current?.generationSHA256 == generationSHA256 {
        guard current?.canonicalData == canonicalData else {
          throw ContentAddressedGenerationStoreError.corruptGeneration(
            "Подтверждённый хэш поколения соответствует другим каноническим байтам."
          )
        }
        try synchronizeDirectory(
          rootURL,
          failureMessage: "Не удалось завершить синхронизацию указателя CURRENT."
        )
        try commitCheckpointObserver?(.rootDirectorySynchronized)
        return StoredContentAddressedGeneration(
          generationSHA256: generationSHA256,
          canonicalData: canonicalData
        )
      }
      guard expectedPreviousGenerationSHA256 == current?.generationSHA256 else {
        throw ContentAddressedGenerationStoreError.generationConflict(
          expected: expectedPreviousGenerationSHA256,
          actual: current?.generationSHA256
        )
      }
      try validateLineage(canonicalData, current)

      let pointer = ContentAddressedGenerationPointer(
        schemaVersion: 2,
        canonicalProfile: canonicalProfile,
        generationSHA256: generationSHA256
      )
      let pointerData = try CanonicalMemoryJSON.encode(pointer)
      let pointerURL = rootURL.appendingPathComponent("CURRENT.json", isDirectory: false)
      try publishCurrent(pointerData, at: pointerURL)

      return StoredContentAddressedGeneration(
        generationSHA256: generationSHA256,
        canonicalData: canonicalData
      )
    }
  }

  private func validateConfirmedLineage(
    from current: StoredContentAddressedGeneration
  ) throws {
    guard let previousGenerationSHA256 else { return }
    var descendant = current
    while let previousSHA256 = try previousGenerationSHA256(
      descendant.canonicalData
    ) {
      let previous = try loadGeneration(sha256: previousSHA256)
      try validateLineage(descendant.canonicalData, previous)
      descendant = previous
    }
    try validateLineage(descendant.canonicalData, nil)
  }

  private var generationsURL: URL {
    rootURL.appendingPathComponent("generations", isDirectory: true)
  }

  private func prepareStoreDirectories() throws {
    do {
      try FileManager.default.createDirectory(
        at: rootURL,
        withIntermediateDirectories: true
      )
      try FileManager.default.createDirectory(
        at: generationsURL,
        withIntermediateDirectories: true
      )
    } catch {
      throw ContentAddressedGenerationStoreError.generationStore(
        "Не удалось подготовить каталоги хранилища поколений."
      )
    }
    try synchronizeDirectory(
      rootURL,
      failureMessage: "Не удалось синхронизировать корневой каталог хранилища."
    )
  }

  private func publishGeneration(_ data: Data, at generationURL: URL) throws {
    let temporaryURL = stagingURL(
      in: generationsURL,
      prefix: ".generation"
    )
    try writeStagingFile(
      data,
      to: temporaryURL,
      writtenCheckpoint: .generationTemporaryWritten,
      synchronizedCheckpoint: .generationFileSynchronized,
      writeFailureMessage: "Не удалось полностью записать временный файл поколения.",
      synchronizationFailureMessage: "Не удалось синхронизировать временный файл поколения."
    )
    var temporaryExists = true
    defer {
      if temporaryExists {
        unlinkIgnoringErrors(temporaryURL)
      }
    }

    let linkResult = withFileSystemRepresentations(temporaryURL, generationURL) {
      temporaryPath, generationPath in
      Darwin.link(temporaryPath, generationPath)
    }
    if linkResult != 0 {
      let linkError = errno
      guard linkError == EEXIST else {
        throw ContentAddressedGenerationStoreError.generationStore(
          "Не удалось опубликовать неизменяемый файл поколения."
        )
      }
      let existing = try readBounded(
        generationURL,
        limit: maximumGenerationBytes,
        kind: "файл поколения"
      )
      guard existing == data else {
        throw ContentAddressedGenerationStoreError.corruptGeneration(
          "Имя неизменяемого поколения занято другими байтами."
        )
      }
      try synchronizeFile(
        generationURL,
        failureMessage: "Не удалось синхронизировать существующий файл поколения."
      )
    }
    try commitCheckpointObserver?(.generationPublished)

    try unlinkFile(
      temporaryURL,
      failureMessage: "Не удалось удалить временное имя файла поколения."
    )
    temporaryExists = false
    try synchronizeDirectory(
      generationsURL,
      failureMessage: "Не удалось синхронизировать каталог поколений."
    )
    try commitCheckpointObserver?(.generationsDirectorySynchronized)
  }

  private func publishCurrent(_ data: Data, at pointerURL: URL) throws {
    let temporaryURL = stagingURL(
      in: rootURL,
      prefix: ".CURRENT"
    )
    try writeStagingFile(
      data,
      to: temporaryURL,
      writtenCheckpoint: .currentTemporaryWritten,
      synchronizedCheckpoint: .currentFileSynchronized,
      writeFailureMessage: "Не удалось полностью записать временный указатель CURRENT.",
      synchronizationFailureMessage: "Не удалось синхронизировать временный указатель CURRENT."
    )
    var temporaryExists = true
    defer {
      if temporaryExists {
        unlinkIgnoringErrors(temporaryURL)
      }
    }

    let renameResult = withFileSystemRepresentations(temporaryURL, pointerURL) {
      temporaryPath, pointerPath in
      Darwin.rename(temporaryPath, pointerPath)
    }
    guard renameResult == 0 else {
      throw ContentAddressedGenerationStoreError.generationStore(
        "Не удалось атомарно опубликовать указатель CURRENT."
      )
    }
    temporaryExists = false
    try commitCheckpointObserver?(.currentPublished)
    try synchronizeDirectory(
      rootURL,
      failureMessage: "Не удалось синхронизировать публикацию указателя CURRENT."
    )
    try commitCheckpointObserver?(.rootDirectorySynchronized)
  }

  private func stagingURL(in directory: URL, prefix: String) -> URL {
    directory.appendingPathComponent(
      "\(prefix).\(UUID().uuidString).tmp",
      isDirectory: false
    )
  }

  private func writeStagingFile(
    _ data: Data,
    to url: URL,
    writtenCheckpoint: ContentAddressedGenerationCommitCheckpoint,
    synchronizedCheckpoint: ContentAddressedGenerationCommitCheckpoint,
    writeFailureMessage: String,
    synchronizationFailureMessage: String
  ) throws {
    let descriptor = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.open(
        path,
        O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW,
        S_IRUSR | S_IWUSR
      )
    }
    guard descriptor >= 0 else {
      throw ContentAddressedGenerationStoreError.generationStore(writeFailureMessage)
    }
    var completed = false
    defer {
      _ = Darwin.close(descriptor)
      if !completed {
        unlinkIgnoringErrors(url)
      }
    }

    try writeAll(data, to: descriptor, failureMessage: writeFailureMessage)
    try commitCheckpointObserver?(writtenCheckpoint)
    try synchronizeDescriptor(
      descriptor,
      failureMessage: synchronizationFailureMessage
    )
    try commitCheckpointObserver?(synchronizedCheckpoint)
    completed = true
  }

  private func writeAll(
    _ data: Data,
    to descriptor: Int32,
    failureMessage: String
  ) throws {
    try data.withUnsafeBytes { buffer in
      guard let baseAddress = buffer.baseAddress else { return }
      var offset = 0
      while offset < buffer.count {
        let written = Darwin.write(
          descriptor,
          baseAddress.advanced(by: offset),
          buffer.count - offset
        )
        if written > 0 {
          offset += written
          continue
        }
        if written < 0, errno == EINTR {
          continue
        }
        throw ContentAddressedGenerationStoreError.generationStore(failureMessage)
      }
    }
  }

  private func synchronizeFile(_ url: URL, failureMessage: String) throws {
    let descriptor = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
    }
    guard descriptor >= 0 else {
      throw ContentAddressedGenerationStoreError.generationStore(failureMessage)
    }
    defer { _ = Darwin.close(descriptor) }
    try synchronizeDescriptor(descriptor, failureMessage: failureMessage)
  }

  private func synchronizeDirectory(_ url: URL, failureMessage: String) throws {
    let descriptor = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
    }
    guard descriptor >= 0 else {
      throw ContentAddressedGenerationStoreError.generationStore(failureMessage)
    }
    defer { _ = Darwin.close(descriptor) }
    try synchronizeDescriptor(descriptor, failureMessage: failureMessage)
  }

  private func synchronizeDescriptor(
    _ descriptor: Int32,
    failureMessage: String
  ) throws {
    while Darwin.fsync(descriptor) != 0 {
      guard errno == EINTR else {
        throw ContentAddressedGenerationStoreError.generationStore(failureMessage)
      }
    }
  }

  private func unlinkFile(_ url: URL, failureMessage: String) throws {
    let result = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.unlink(path)
    }
    guard result == 0 else {
      throw ContentAddressedGenerationStoreError.generationStore(failureMessage)
    }
  }

  private func unlinkIgnoringErrors(_ url: URL) {
    _ = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.unlink(path)
    }
  }

  private func withFileSystemRepresentations<T>(
    _ firstURL: URL,
    _ secondURL: URL,
    _ body: (UnsafePointer<CChar>, UnsafePointer<CChar>) -> T
  ) -> T? {
    firstURL.withUnsafeFileSystemRepresentation { firstPath in
      guard let firstPath else { return nil }
      return secondURL.withUnsafeFileSystemRepresentation { secondPath in
        guard let secondPath else { return nil }
        return body(firstPath, secondPath)
      }
    }
  }

  private func withCurrentPublicationLock<T>(_ body: () throws -> T) throws -> T {
    let lockURL = rootURL.appendingPathComponent("CURRENT.lock", isDirectory: false)
    let descriptor = lockURL.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.open(path, O_CREAT | O_RDWR | O_CLOEXEC, S_IRUSR | S_IWUSR)
    }
    guard descriptor >= 0 else {
      throw ContentAddressedGenerationStoreError.generationStore(
        "Не удалось открыть межпроцессную блокировку указателя CURRENT."
      )
    }
    defer { _ = Darwin.close(descriptor) }

    var publicationLock = Darwin.flock()
    publicationLock.l_type = Int16(F_WRLCK)
    publicationLock.l_whence = Int16(SEEK_SET)
    try publicationLockObserver?(.willAcquire)
    while Darwin.fcntl(descriptor, F_SETLKW, &publicationLock) != 0 {
      guard errno == EINTR else {
        throw ContentAddressedGenerationStoreError.generationStore(
          "Не удалось получить межпроцессную блокировку указателя CURRENT."
        )
      }
    }
    defer {
      var unlock = Darwin.flock()
      unlock.l_type = Int16(F_UNLCK)
      unlock.l_whence = Int16(SEEK_SET)
      _ = Darwin.fcntl(descriptor, F_SETLK, &unlock)
    }
    try publicationLockObserver?(.didAcquire)
    return try body()
  }

  private func readBounded(_ url: URL, limit: Int, kind: String) throws -> Data {
    do {
      let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
      guard values.isRegularFile == true, let size = values.fileSize, size <= limit else {
        throw ContentAddressedGenerationStoreError.corruptGeneration(
          "\(kind) отсутствует, имеет неверный тип или превышает лимит."
        )
      }
      return try Data(contentsOf: url, options: [.mappedIfSafe])
    } catch let error as ContentAddressedGenerationStoreError {
      throw error
    } catch {
      throw ContentAddressedGenerationStoreError.corruptGeneration(
        "Не удалось прочитать \(kind)."
      )
    }
  }
}

private func isContentAddressedSHA256(_ value: String) -> Bool {
  guard value.count == 71, value.hasPrefix("sha256:") else { return false }
  return value.dropFirst(7).allSatisfy("0123456789abcdef".contains)
}
