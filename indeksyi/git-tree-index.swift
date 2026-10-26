import CryptoKit
import Foundation

private struct ToolFailure: Error, CustomStringConvertible {
    let description: String
}

private struct Source: Encodable {
    let commit: String
    let tree: String
    let path: String
    let subtree: String

    enum CodingKeys: String, CodingKey {
        case commit = "коммит"
        case tree
        case path = "путь"
        case subtree = "tree_поддерева"
    }
}

private struct Entry: Encodable {
    let path: String
    let mode: String
    let type: String
    let oid: String
    let sha256: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case path = "путь"
        case mode = "режим"
        case type = "тип"
        case oid
        case sha256 = "sha256"
        case size = "размер_байт"
    }
}

private struct Manifest: Encodable {
    let kind = "прототип-индекса-объектов-Git"
    let status = "пример; общий машинный контракт не утверждён"
    let source: Source
    let order = "лексикографический по байтам UTF-8 пути"
    let itemCount: Int
    let pathsUnique = true
    let entries: [Entry]
    let reproduction: [String]
    let limitations: [String]

    enum CodingKeys: String, CodingKey {
        case kind = "вид"
        case status = "статус"
        case source = "источник"
        case order = "порядок"
        case itemCount = "элементов"
        case pathsUnique = "пути_уникальны"
        case entries = "записи"
        case reproduction = "воспроизведение"
        case limitations = "ограничения"
    }
}

private struct RawEntry {
    let pathBytes: [UInt8]
    let path: String
    let mode: String
    let oid: String
}

private func runGit(_ arguments: [String], root: String? = nil, input: Data? = nil) throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = (root.map { ["-C", $0] } ?? []) + arguments

    let output = Pipe()
    let errors = Pipe()
    process.standardOutput = output
    process.standardError = errors

    var temporaryInput: URL?
    var inputHandle: FileHandle?
    defer {
        try? inputHandle?.close()
        if let temporaryInput {
            try? FileManager.default.removeItem(at: temporaryInput)
        }
    }

    if let input {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-tree-index-\(UUID().uuidString)")
        try input.write(to: url, options: .withoutOverwriting)
        temporaryInput = url
        let handle = try FileHandle(forReadingFrom: url)
        inputHandle = handle
        process.standardInput = handle
    } else {
        process.standardInput = FileHandle.nullDevice
    }

    do {
        try process.run()
    } catch {
        throw ToolFailure(description: "Не удалось запустить git: \(error)")
    }

    let stdout = output.fileHandleForReading.readDataToEndOfFile()
    let stderr = errors.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        let message = String(decoding: stderr, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        throw ToolFailure(description: "git завершился с кодом \(process.terminationStatus): \(message)")
    }
    return stdout
}

private func text(_ data: Data, label: String) throws -> String {
    guard let value = String(data: data, encoding: .utf8) else {
        throw ToolFailure(description: "\(label): ожидался UTF-8")
    }
    return value.trimmingCharacters(in: .newlines)
}

private func hexOID(_ value: String) -> Bool {
    [40, 64].contains(value.utf8.count)
        && value.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
}

private func parseTree(_ data: Data) throws -> [RawEntry] {
    guard data.count <= 16 * 1024 * 1024 else {
        throw ToolFailure(description: "Вывод git ls-tree превысил 16 MiB")
    }

    var result: [RawEntry] = []
    var uniquePaths = Set<Data>()
    for record in data.split(separator: 0, omittingEmptySubsequences: true) {
        let bytes = Array(record)
        guard let tab = bytes.firstIndex(of: 0x09) else {
            throw ToolFailure(description: "Некорректная запись git ls-tree")
        }
        let header = String(decoding: bytes[..<tab], as: UTF8.self)
        let fields = header.split(separator: " ")
        guard fields.count == 3 else {
            throw ToolFailure(description: "Некорректный заголовок git ls-tree")
        }

        let mode = String(fields[0])
        let kind = String(fields[1])
        let oid = String(fields[2])
        guard hexOID(oid) else {
            throw ToolFailure(description: "Некорректный OID: \(oid)")
        }
        guard kind == "blob" else {
            throw ToolFailure(description: "Поддерево содержит объект типа \(kind); индексируются только blob")
        }

        let pathBytes = Array(bytes[(tab + 1)...])
        guard let path = String(bytes: pathBytes, encoding: .utf8), !path.isEmpty else {
            throw ToolFailure(description: "Путь Git не является непустым UTF-8")
        }
        guard uniquePaths.insert(Data(pathBytes)).inserted else {
            throw ToolFailure(description: "Повторный UTF-8 путь: \(path)")
        }
        result.append(RawEntry(pathBytes: pathBytes, path: path, mode: mode, oid: oid))
        guard result.count <= 5_000 else {
            throw ToolFailure(description: "Поддерево превысило предел 5 000 объектов")
        }
    }
    guard !result.isEmpty else {
        throw ToolFailure(description: "Выбранное поддерево не содержит blob")
    }
    result.sort { $0.pathBytes.lexicographicallyPrecedes($1.pathBytes) }
    return result
}

private func lines(_ data: Data, label: String) throws -> [[Substring]] {
    guard let value = String(data: data, encoding: .ascii) else {
        throw ToolFailure(description: "\(label): ожидался ASCII")
    }
    return value.split(separator: "\n").map { $0.split(separator: " ") }
}

private func blobSizes(_ entries: [RawEntry], root: String) throws -> [Int] {
    let request = Data((entries.map(\.oid).joined(separator: "\n") + "\n").utf8)
    let response = try runGit(["cat-file", "--batch-check"], root: root, input: request)
    let rows = try lines(response, label: "git cat-file --batch-check")
    guard rows.count == entries.count else {
        throw ToolFailure(description: "Число ответов batch-check не совпало с числом OID")
    }

    var sizes: [Int] = []
    var total = 0
    for (entry, row) in zip(entries, rows) {
        guard row.count == 3, row[0] == entry.oid, row[1] == "blob",
              let size = Int(row[2]), size >= 0 else {
            throw ToolFailure(description: "Некорректный размер blob \(entry.oid)")
        }
        guard size <= 128 * 1024 * 1024 - total else {
            throw ToolFailure(description: "Суммарный размер blob превысил 128 MiB")
        }
        total += size
        sizes.append(size)
    }
    return sizes
}

private func readLine(_ bytes: [UInt8], cursor: inout Int) throws -> String {
    let start = cursor
    while cursor < bytes.count && bytes[cursor] != 0x0A {
        cursor += 1
    }
    guard cursor < bytes.count else {
        throw ToolFailure(description: "Обрезан заголовок git cat-file --batch")
    }
    let line = String(decoding: bytes[start..<cursor], as: UTF8.self)
    cursor += 1
    return line
}

private func readBlobs(_ entries: [RawEntry], sizes: [Int], root: String) throws -> [Data] {
    let request = Data((entries.map(\.oid).joined(separator: "\n") + "\n").utf8)
    let response = try runGit(["cat-file", "--batch"], root: root, input: request)
    let bytes = Array(response)
    var cursor = 0
    var blobs: [Data] = []

    for (entry, expectedSize) in zip(entries, sizes) {
        let header = try readLine(bytes, cursor: &cursor)
        let fields = header.split(separator: " ")
        guard fields.count == 3, fields[0] == entry.oid, fields[1] == "blob",
              let actualSize = Int(fields[2]), actualSize == expectedSize,
              actualSize <= bytes.count - cursor - 1 else {
            throw ToolFailure(description: "Заголовок blob не совпал с batch-check: \(entry.oid)")
        }
        let end = cursor + actualSize
        guard bytes[end] == 0x0A else {
            throw ToolFailure(description: "Отсутствует разделитель после blob \(entry.oid)")
        }
        blobs.append(Data(bytes[cursor..<end]))
        cursor = end + 1
    }
    guard cursor == bytes.count else {
        throw ToolFailure(description: "Неожиданные дополнительные байты от git cat-file --batch")
    }
    return blobs
}

private func digest(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func generate(commit: String, path: String) throws -> Manifest {
    guard hexOID(commit) else {
        throw ToolFailure(description: "Передайте полный lowercase commit OID из 40 или 64 hex-символов")
    }
    guard !path.isEmpty, !path.hasPrefix("/"), !path.contains(":"),
          path.split(separator: "/", omittingEmptySubsequences: false)
            .allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
        throw ToolFailure(description: "Путь должен быть относительным поддеревом без пустых, . и .. компонентов")
    }

    let repository = try text(runGit(["rev-parse", "--show-toplevel"]), label: "корень Git")
    guard try text(runGit(["cat-file", "-t", commit], root: repository), label: "тип commit") == "commit" else {
        throw ToolFailure(description: "Указанный OID не является commit")
    }
    let rootTree = try text(runGit(["rev-parse", "--verify", "\(commit)^{tree}"], root: repository),
                            label: "root tree")
    let subtree = try text(runGit(["rev-parse", "--verify", "\(commit):\(path)"], root: repository),
                           label: "выбранное поддерево")
    guard hexOID(rootTree), hexOID(subtree),
          try text(runGit(["cat-file", "-t", subtree], root: repository), label: "тип поддерева") == "tree" else {
        throw ToolFailure(description: "Выбранный путь не разрешился в Git tree")
    }

    let relativeEntries = try parseTree(runGit(["ls-tree", "-r", "-z", "--full-tree", subtree], root: repository))
    let prefix = Array((path + "/").utf8)
    let rawEntries = relativeEntries.map { raw in
        RawEntry(pathBytes: prefix + raw.pathBytes, path: path + "/" + raw.path,
                 mode: raw.mode, oid: raw.oid)
    }
    let sizes = try blobSizes(rawEntries, root: repository)
    let blobs = try readBlobs(rawEntries, sizes: sizes, root: repository)
    let entries = zip(rawEntries, zip(sizes, blobs)).map { raw, content in
        Entry(path: raw.path, mode: raw.mode, type: "blob", oid: raw.oid,
              sha256: digest(content.1), size: content.0)
    }

    let quotedPath = path
    let reproduction = [
        "git rev-parse \(commit):\(quotedPath)",
        "git ls-tree -r --full-tree \(subtree) ; prepend \(path)/ to each returned path",
        "Для каждого напечатанного OID: git cat-file -s <OID>",
        "Для каждого напечатанного OID: git cat-file blob <OID> | shasum -a 256",
        "Пути сортируются по байтам UTF-8; число уникальных путей должно совпадать с числом записей."
    ]
    let limitations = [
        "Снимок охватывает только blob выбранного поддерева \(path) в указанном commit, а не полный реестр узла.",
        "Скрипт читает закреплённые Git-объекты; содержимое checkout не является источником снимка.",
        "Пределы этого прототипа: 5 000 объектов, 16 MiB вывода ls-tree и 128 MiB blob-содержимого.",
        "Пример не обновляет исторические Индексы/** и не доказывает полноту динамических потребителей или производительность."
    ]
    return Manifest(source: Source(commit: commit, tree: rootTree, path: path, subtree: subtree),
                    itemCount: entries.count, entries: entries,
                    reproduction: reproduction, limitations: limitations)
}

do {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard arguments.count == 4, arguments[0] == "--commit", arguments[2] == "--path" else {
        throw ToolFailure(description: "Использование: swift git-tree-index.swift --commit <full-commit-oid> --path <relative-subtree>")
    }
    let manifest = try generate(commit: arguments[1], path: arguments[3])
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var output = try encoder.encode(manifest)
    output.append(0x0A)
    try FileHandle.standardOutput.write(contentsOf: output)
} catch {
    let message = Data("git-tree-index: \(error)\n".utf8)
    try? FileHandle.standardError.write(contentsOf: message)
    exit(1)
}
