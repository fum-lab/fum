import Darwin
import Foundation

private struct MemoryGenerationPointer: Codable, Equatable {
  let schemaVersion: Int
  let generationSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case generationSHA256 = "generation_sha256"
  }
}

private struct MemoryGenerationSchemaEnvelope: Decodable {
  let schemaVersion: Int

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
  }
}

enum MemoryGenerationPublicationLockEvent {
  case willAcquire
  case didAcquire
}

enum MemoryGenerationCommitCheckpoint: String, CaseIterable, Sendable {
  case generationTemporaryWritten = "generation-temporary-written"
  case generationFileSynchronized = "generation-file-synchronized"
  case generationPublished = "generation-published"
  case generationsDirectorySynchronized = "generations-directory-synchronized"
  case currentTemporaryWritten = "current-temporary-written"
  case currentFileSynchronized = "current-file-synchronized"
  case currentPublished = "current-published"
  case rootDirectorySynchronized = "root-directory-synchronized"
}

public struct MemoryGenerationStore {
  private static let maximumPointerBytes = 4_096
  private static let maximumGenerationBytes = 16_777_216

  public let rootURL: URL
  private let beforePointerCommit: (() throws -> Void)?
  private let publicationLockObserver: ((MemoryGenerationPublicationLockEvent) throws -> Void)?
  private let commitCheckpointObserver: ((MemoryGenerationCommitCheckpoint) throws -> Void)?

  public init(rootURL: URL) {
    self.rootURL = rootURL
    beforePointerCommit = nil
    publicationLockObserver = nil
    commitCheckpointObserver = nil
  }

  init(
    rootURL: URL,
    beforePointerCommit: @escaping () throws -> Void,
    publicationLockObserver: ((MemoryGenerationPublicationLockEvent) throws -> Void)? = nil,
    commitCheckpointObserver: ((MemoryGenerationCommitCheckpoint) throws -> Void)? = nil
  ) {
    self.rootURL = rootURL
    self.beforePointerCommit = beforePointerCommit
    self.publicationLockObserver = publicationLockObserver
    self.commitCheckpointObserver = commitCheckpointObserver
  }

  public func loadCurrent() throws -> StoredMemoryGeneration? {
    let pointerURL = rootURL.appendingPathComponent("CURRENT.json", isDirectory: false)
    guard FileManager.default.fileExists(atPath: pointerURL.path) else {
      return nil
    }

    let pointerData = try readBounded(
      pointerURL,
      limit: Self.maximumPointerBytes,
      kind: "указатель CURRENT"
    )
    let pointer: MemoryGenerationPointer
    do {
      pointer = try JSONDecoder().decode(MemoryGenerationPointer.self, from: pointerData)
    } catch {
      throw MemoryPopulationError.corruptGeneration(
        "Указатель CURRENT не соответствует схеме."
      )
    }
    guard pointer.schemaVersion == 1, isMemorySHA256(pointer.generationSHA256) else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Указатель CURRENT имеет неподдерживаемую версию или хэш."
      )
    }
    let canonicalPointer = try CanonicalMemoryJSON.encode(pointer)
    guard canonicalPointer == pointerData else {
      throw MemoryPopulationError.corruptGeneration(
        "Указатель CURRENT не является каноническим JSON."
      )
    }

    let generationURL = generationsURL.appendingPathComponent(
      "\(pointer.generationSHA256.dropFirst(7)).json",
      isDirectory: false
    )
    let generationData = try readBounded(
      generationURL,
      limit: Self.maximumGenerationBytes,
      kind: "файл поколения"
    )
    guard CanonicalMemoryJSON.sha256(generationData) == pointer.generationSHA256 else {
      throw MemoryPopulationError.corruptGeneration(
        "Хэш файла поколения не совпадает с указателем CURRENT."
      )
    }

    let generationEnvelope: MemoryGenerationSchemaEnvelope
    do {
      generationEnvelope = try JSONDecoder().decode(
        MemoryGenerationSchemaEnvelope.self,
        from: generationData
      )
    } catch {
      throw MemoryPopulationError.corruptGeneration(
        "Файл поколения не содержит версию схемы."
      )
    }
    switch generationEnvelope.schemaVersion {
    case 1:
      throw MemoryPopulationError.incompatibleGeneration(
        "Поколение схемы 1 не содержит канонического журнала событий; самодостаточное воспроизведение невозможно."
      )
    case MemoryGeneration.currentSchemaVersion:
      break
    default:
      throw MemoryPopulationError.incompatibleGeneration(
        "Файл поколения имеет неподдерживаемую версию схемы."
      )
    }

    let generation: MemoryGeneration
    do {
      generation = try JSONDecoder().decode(MemoryGeneration.self, from: generationData)
    } catch {
      throw MemoryPopulationError.corruptGeneration(
        "Файл поколения не соответствует схеме."
      )
    }
    guard try CanonicalMemoryJSON.encode(generation) == generationData else {
      throw MemoryPopulationError.corruptGeneration(
        "Файл поколения не является каноническим JSON."
      )
    }
    try validateMemoryGeneration(generation)
    return StoredMemoryGeneration(
      generationSHA256: pointer.generationSHA256,
      generation: generation
    )
  }

  public func commit(_ generation: MemoryGeneration) throws -> StoredMemoryGeneration {
    try validateMemoryGeneration(generation)
    let generationData = try CanonicalMemoryJSON.encode(generation)
    guard generationData.count <= Self.maximumGenerationBytes else {
      throw MemoryPopulationError.generationStore(
        "Каноническое поколение превышает допустимый размер."
      )
    }
    let generationSHA256 = CanonicalMemoryJSON.sha256(generationData)
    let generationURL = generationsURL.appendingPathComponent(
      "\(generationSHA256.dropFirst(7)).json",
      isDirectory: false
    )

    try prepareStoreDirectories()
    try publishGeneration(
      generationData,
      at: generationURL
    )

    try beforePointerCommit?()
    return try withCurrentPublicationLock {
      let current = try loadCurrent()
      if current?.generationSHA256 == generationSHA256 {
        guard current?.generation == generation else {
          throw MemoryPopulationError.corruptGeneration(
            "Подтверждённый хэш поколения соответствует другим каноническим байтам."
          )
        }
        try synchronizeDirectory(
          rootURL,
          failureMessage: "Не удалось завершить синхронизацию указателя CURRENT."
        )
        try commitCheckpointObserver?(.rootDirectorySynchronized)
        return StoredMemoryGeneration(
          generationSHA256: generationSHA256,
          generation: generation
        )
      }
      guard generation.previousGenerationSHA256 == current?.generationSHA256 else {
        throw MemoryPopulationError.generationConflict(
          expected: generation.previousGenerationSHA256,
          actual: current?.generationSHA256
        )
      }
      try validateLineage(of: generation, continuing: current)

      let pointer = MemoryGenerationPointer(
        schemaVersion: 1,
        generationSHA256: generationSHA256
      )
      let pointerData = try CanonicalMemoryJSON.encode(pointer)
      let pointerURL = rootURL.appendingPathComponent("CURRENT.json", isDirectory: false)
      try publishCurrent(pointerData, at: pointerURL)

      return StoredMemoryGeneration(
        generationSHA256: generationSHA256,
        generation: generation
      )
    }
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
      throw MemoryPopulationError.generationStore(
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
        throw MemoryPopulationError.generationStore(
          "Не удалось опубликовать неизменяемый файл поколения."
        )
      }
      let existing = try readBounded(
        generationURL,
        limit: Self.maximumGenerationBytes,
        kind: "файл поколения"
      )
      guard existing == data else {
        throw MemoryPopulationError.corruptGeneration(
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
      throw MemoryPopulationError.generationStore(
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
    writtenCheckpoint: MemoryGenerationCommitCheckpoint,
    synchronizedCheckpoint: MemoryGenerationCommitCheckpoint,
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
      throw MemoryPopulationError.generationStore(writeFailureMessage)
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
        throw MemoryPopulationError.generationStore(failureMessage)
      }
    }
  }

  private func synchronizeFile(_ url: URL, failureMessage: String) throws {
    let descriptor = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
    }
    guard descriptor >= 0 else {
      throw MemoryPopulationError.generationStore(failureMessage)
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
      throw MemoryPopulationError.generationStore(failureMessage)
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
        throw MemoryPopulationError.generationStore(failureMessage)
      }
    }
  }

  private func unlinkFile(_ url: URL, failureMessage: String) throws {
    let result = url.withUnsafeFileSystemRepresentation { path in
      guard let path else { return Int32(-1) }
      return Darwin.unlink(path)
    }
    guard result == 0 else {
      throw MemoryPopulationError.generationStore(failureMessage)
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
      throw MemoryPopulationError.generationStore(
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
        throw MemoryPopulationError.generationStore(
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

  private func validateLineage(
    of generation: MemoryGeneration,
    continuing current: StoredMemoryGeneration?
  ) throws {
    guard let current else {
      guard
        generation.provenance.inputEventIDs
          == generation.trace.entries.map(\.eventID),
        generation.eventJournal.events.map(\.id)
          == generation.provenance.inputEventIDs
      else {
        throw MemoryPopulationError.incompatibleGeneration(
          "Начальное поколение должно происходить из всей принятой трассы."
        )
      }
      return
    }

    let previous = current.generation
    guard generation.seed == previous.seed else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Преемник изменяет seed подтверждённой памяти."
      )
    }
    let previousEntries = previous.trace.entries
    let nextEntries = generation.trace.entries
    let previousEvents = previous.eventJournal.events
    let nextEvents = generation.eventJournal.events
    guard generation.snapshot.datasetID == previous.snapshot.datasetID else {
      throw MemoryPopulationError.incompatibleGeneration(
        "dataset_id преемника не совпадает с подтверждённой памятью."
      )
    }
    guard nextEntries.count > previousEntries.count,
      Array(nextEntries.prefix(previousEntries.count)) == previousEntries,
      nextEvents.count > previousEvents.count,
      Array(nextEvents.prefix(previousEvents.count)) == previousEvents
    else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Журнал событий и трасса преемника не продолжают подтверждённую историю."
      )
    }

    let nextRecords = Dictionary(
      uniqueKeysWithValues: generation.snapshot.records.map { ($0.key, $0) }
    )
    guard previous.snapshot.records.allSatisfy({ nextRecords[$0.key] == $0 }) else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Преемник изменяет подтверждённые записи памяти."
      )
    }
    let appendedEventIDs = nextEntries.dropFirst(previousEntries.count).map(\.eventID)
    let appendedJournalEventIDs = nextEvents.dropFirst(previousEvents.count).map(\.id)
    guard generation.provenance.inputEventIDs == appendedEventIDs,
      generation.provenance.inputEventIDs == appendedJournalEventIDs
    else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Происхождение входа не совпадает с добавленной частью трассы."
      )
    }
  }

  private func readBounded(_ url: URL, limit: Int, kind: String) throws -> Data {
    do {
      let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
      guard values.isRegularFile == true, let size = values.fileSize, size <= limit else {
        throw MemoryPopulationError.corruptGeneration(
          "\(kind) отсутствует, имеет неверный тип или превышает лимит."
        )
      }
      return try Data(contentsOf: url, options: [.mappedIfSafe])
    } catch let error as MemoryPopulationError {
      throw error
    } catch {
      throw MemoryPopulationError.corruptGeneration("Не удалось прочитать \(kind).")
    }
  }
}
