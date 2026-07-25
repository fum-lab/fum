import Foundation

func validateMemoryGeneration(_ generation: MemoryGeneration) throws {
  guard generation.schemaVersion == 1 else {
    throw MemoryPopulationError.incompatibleGeneration(
      "Неподдерживаемая версия схемы поколения."
    )
  }
  guard generation.policyVersion == MemoryPopulationPolicy.version else {
    throw MemoryPopulationError.incompatibleGeneration(
      "Неподдерживаемая версия политики памяти."
    )
  }
  guard isMemorySHA256(generation.inputSHA256),
    isMemorySHA256(generation.snapshotSHA256),
    isMemorySHA256(generation.traceSHA256),
    isMemorySHA256(generation.viewModelSHA256),
    generation.previousGenerationSHA256.map(isMemorySHA256) ?? true
  else {
    throw MemoryPopulationError.corruptGeneration(
      "Поколение содержит некорректный SHA-256."
    )
  }
  guard generation.snapshot.schemaVersion == 1,
    generation.trace.schemaVersion == 1,
    generation.viewModel.schemaVersion == 1
  else {
    throw MemoryPopulationError.incompatibleGeneration(
      "Неподдерживаемая версия канонического содержимого."
    )
  }
  guard generation.snapshot.datasetID == generation.trace.datasetID,
    generation.snapshot.datasetID == generation.viewModel.datasetID
  else {
    throw MemoryPopulationError.corruptGeneration(
      "dataset_id снимка, трассы и модели представления расходятся."
    )
  }
  guard isMemoryIdentifier(generation.snapshot.datasetID),
    generation.snapshot.records.count <= MemoryPopulationPolicy.maximumEvents,
    generation.snapshot.records.reduce(0, { $0 + $1.value.utf8.count })
      <= MemoryPopulationPolicy.maximumSnapshotValueBytes
  else {
    throw MemoryPopulationError.corruptGeneration(
      "Снимок нарушает ограничения версии политики памяти."
    )
  }
  guard generation.viewModel.operatorVersion == MemoryViewProjectionOperator.version,
    generation.viewModel.headless
  else {
    throw MemoryPopulationError.incompatibleGeneration(
      "Модель представления создана неподдерживаемым оператором."
    )
  }

  let snapshotHash = CanonicalMemoryJSON.sha256(
    try CanonicalMemoryJSON.encode(generation.snapshot)
  )
  let traceHash = CanonicalMemoryJSON.sha256(
    try CanonicalMemoryJSON.encode(generation.trace)
  )
  let viewModelHash = CanonicalMemoryJSON.sha256(
    try CanonicalMemoryJSON.encode(generation.viewModel)
  )
  guard snapshotHash == generation.snapshotSHA256,
    traceHash == generation.traceSHA256,
    viewModelHash == generation.viewModelSHA256
  else {
    throw MemoryPopulationError.corruptGeneration(
      "Хэш канонического содержимого не совпадает с поколением."
    )
  }

  let expectedViewModel = MemoryViewProjectionOperator().project(generation.snapshot)
  guard expectedViewModel == generation.viewModel else {
    throw MemoryPopulationError.corruptGeneration(
      "Модель представления не выводится из принятого снимка."
    )
  }
  let entries = generation.trace.entries
  let eventIDs = entries.map(\.eventID)
  let recordKeys = generation.snapshot.records.map(\.key)
  guard
    !entries.isEmpty,
    entries.count <= MemoryPopulationPolicy.maximumEvents,
    entries.enumerated().allSatisfy({ index, entry in
      entry.ordinal == index + 1
    }), Set(eventIDs).count == eventIDs.count,
    eventIDs.allSatisfy(isMemoryIdentifier),
    recordKeys == recordKeys.sorted(),
    Set(recordKeys).count == recordKeys.count,
    recordKeys.allSatisfy(isMemoryIdentifier),
    !generation.provenance.inputEventIDs.isEmpty,
    generation.provenance.acceptedEventIDs == eventIDs,
    Array(eventIDs.suffix(generation.provenance.inputEventIDs.count))
      == generation.provenance.inputEventIDs,
    generation.provenance.memoryExecutorVersion == MemoryPopulationPolicy.executorID,
    generation.provenance.projectionOperatorVersion
      == MemoryViewProjectionOperator.version
  else {
    throw MemoryPopulationError.corruptGeneration(
      "Происхождение поколения не согласовано с трассой."
    )
  }

  let recordsByKey = Dictionary(
    uniqueKeysWithValues: generation.snapshot.records.map { ($0.key, $0) }
  )
  var acceptedRecords: [String: MemoryRecord] = [:]
  for entry in entries {
    guard isMemorySHA256(entry.sourceEventSHA256),
      isMemorySHA256(entry.outputRecordSHA256),
      entry.writes.count == 1,
      let writtenKey = entry.writes.first,
      isMemoryIdentifier(writtenKey),
      acceptedRecords[writtenKey] == nil,
      let record = recordsByKey[writtenKey],
      record.provenance.sourceDatasetID == generation.snapshot.datasetID,
      record.provenance.executor == MemoryPopulationPolicy.executorID,
      record.provenance.producedByEventID == entry.eventID,
      CanonicalMemoryJSON.sha256(try CanonicalMemoryJSON.encode(record))
        == entry.outputRecordSHA256
    else {
      throw MemoryPopulationError.corruptGeneration(
        "Запись трассы не согласована с породившей записью памяти."
      )
    }

    let expectedContributors: [String]
    switch entry.operation {
    case .remember:
      guard entry.reads.isEmpty,
        !record.value.isEmpty,
        record.value.utf8.count <= MemoryPopulationPolicy.maximumValueBytes
      else {
        throw MemoryPopulationError.corruptGeneration(
          "Операция remember нарушает ограничения версии политики памяти."
        )
      }
      expectedContributors = [entry.eventID]
    case .compose:
      guard !entry.reads.isEmpty,
        entry.reads.count <= MemoryPopulationPolicy.maximumSources,
        Set(entry.reads).count == entry.reads.count,
        entry.reads.allSatisfy(isMemoryIdentifier),
        !record.value.isEmpty,
        record.value.utf8.count <= MemoryPopulationPolicy.maximumRecordValueBytes
      else {
        throw MemoryPopulationError.corruptGeneration(
          "Операция compose содержит некорректный набор чтений."
        )
      }
      var sourceRecords: [MemoryRecord] = []
      for key in entry.reads {
        guard let source = acceptedRecords[key] else {
          throw MemoryPopulationError.corruptGeneration(
            "Операция compose читает ещё не принятую запись."
          )
        }
        sourceRecords.append(source)
      }
      expectedContributors = orderedUniqueEventIDs(
        sourceRecords.flatMap(\.provenance.contributingEventIDs) + [entry.eventID]
      )
    }
    guard record.provenance.contributingEventIDs == expectedContributors else {
      throw MemoryPopulationError.corruptGeneration(
        "Происхождение записи не выводится из подтверждённой трассы."
      )
    }
    acceptedRecords[writtenKey] = record
  }
  guard Set(acceptedRecords.keys) == Set(recordKeys) else {
    throw MemoryPopulationError.corruptGeneration(
      "Снимок содержит запись без породившего шага трассы."
    )
  }
}

private func orderedUniqueEventIDs(_ values: [String]) -> [String] {
  var seen = Set<String>()
  return values.filter { seen.insert($0).inserted }
}

func isMemorySHA256(_ value: String) -> Bool {
  guard value.count == 71, value.hasPrefix("sha256:") else { return false }
  return value.dropFirst(7).allSatisfy("0123456789abcdef".contains)
}
