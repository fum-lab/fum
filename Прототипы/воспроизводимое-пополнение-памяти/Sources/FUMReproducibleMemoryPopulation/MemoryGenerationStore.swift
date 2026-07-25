import Foundation

private struct MemoryGenerationPointer: Codable, Equatable {
  let schemaVersion: Int
  let generationSHA256: String

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case generationSHA256 = "generation_sha256"
  }
}

public struct MemoryGenerationStore {
  private static let maximumPointerBytes = 4_096
  private static let maximumGenerationBytes = 16_777_216

  public let rootURL: URL
  private let beforePointerCommit: (() throws -> Void)?

  public init(rootURL: URL) {
    self.rootURL = rootURL
    beforePointerCommit = nil
  }

  init(rootURL: URL, beforePointerCommit: @escaping () throws -> Void) {
    self.rootURL = rootURL
    self.beforePointerCommit = beforePointerCommit
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
    let current = try loadCurrent()
    guard generation.previousGenerationSHA256 == current?.generationSHA256 else {
      throw MemoryPopulationError.generationConflict(
        expected: generation.previousGenerationSHA256,
        actual: current?.generationSHA256
      )
    }
    try validateLineage(of: generation, continuing: current)

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

    do {
      try FileManager.default.createDirectory(
        at: generationsURL,
        withIntermediateDirectories: true
      )
      if FileManager.default.fileExists(atPath: generationURL.path) {
        let existing = try Data(contentsOf: generationURL, options: [.mappedIfSafe])
        guard existing == generationData else {
          throw MemoryPopulationError.corruptGeneration(
            "Имя неизменяемого поколения занято другими байтами."
          )
        }
      } else {
        try generationData.write(to: generationURL, options: [.atomic])
      }
    } catch let error as MemoryPopulationError {
      throw error
    } catch {
      throw MemoryPopulationError.generationStore(
        "Не удалось подготовить неизменяемый файл поколения."
      )
    }

    try beforePointerCommit?()
    let pointer = MemoryGenerationPointer(
      schemaVersion: 1,
      generationSHA256: generationSHA256
    )
    let pointerData = try CanonicalMemoryJSON.encode(pointer)
    let pointerURL = rootURL.appendingPathComponent("CURRENT.json", isDirectory: false)
    do {
      try pointerData.write(to: pointerURL, options: [.atomic])
    } catch {
      throw MemoryPopulationError.generationStore(
        "Не удалось атомарно подтвердить поколение."
      )
    }

    return StoredMemoryGeneration(
      generationSHA256: generationSHA256,
      generation: generation
    )
  }

  private var generationsURL: URL {
    rootURL.appendingPathComponent("generations", isDirectory: true)
  }

  private func validateLineage(
    of generation: MemoryGeneration,
    continuing current: StoredMemoryGeneration?
  ) throws {
    guard let current else {
      guard
        generation.provenance.inputEventIDs
          == generation.trace.entries.map(\.eventID)
      else {
        throw MemoryPopulationError.incompatibleGeneration(
          "Начальное поколение должно происходить из всей принятой трассы."
        )
      }
      return
    }

    let previous = current.generation
    let previousEntries = previous.trace.entries
    let nextEntries = generation.trace.entries
    guard generation.snapshot.datasetID == previous.snapshot.datasetID else {
      throw MemoryPopulationError.incompatibleGeneration(
        "dataset_id преемника не совпадает с подтверждённой памятью."
      )
    }
    guard nextEntries.count > previousEntries.count,
      Array(nextEntries.prefix(previousEntries.count)) == previousEntries
    else {
      throw MemoryPopulationError.incompatibleGeneration(
        "Трасса преемника не продолжает подтверждённую трассу."
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
    guard generation.provenance.inputEventIDs == appendedEventIDs else {
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
