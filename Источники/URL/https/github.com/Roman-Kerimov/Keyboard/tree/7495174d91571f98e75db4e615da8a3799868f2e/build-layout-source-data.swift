#!/usr/bin/env swift
import CryptoKit
import Foundation

struct Upstream: Decodable {
    struct Signature: Decodable {
        let verified: Bool
        let reason: String
    }
    let repository_url: String
    let observed_ref: String
    let observed_on: String
    let commit: String
    let tree: String
    let commit_message: String
    let signature: Signature
}

struct SourceFile: Decodable {
    let repository_path: String
    let local_path: String
    let git_blob: String
    let role: String
}

struct LicenseRecord: Decodable {
    let repository_path: String
    let git_blob: String
    let reused_repository_path: String
    let reused_git_blob: String
    let name: String
}

struct Manifest: Decodable {
    let schema: String
    let upstream: Upstream
    let layout_order: [String]
    let source_files: [SourceFile]
    let license: LicenseRecord
}

func regexMatches(_ pattern: String, in source: String, options: NSRegularExpression.Options = []) throws -> [NSTextCheckingResult] {
    let regex = try NSRegularExpression(pattern: pattern, options: options)
    return regex.matches(in: source, range: NSRange(location: 0, length: (source as NSString).length))
}

func capture(_ pattern: String, in source: String, group: Int = 1, options: NSRegularExpression.Options = []) throws -> String {
    guard let match = try regexMatches(pattern, in: source, options: options).first else {
        throw NSError(domain: "KeyboardSourceData", code: 1, userInfo: [NSLocalizedDescriptionKey: "Source pattern not found: \(pattern)"])
    }
    return (source as NSString).substring(with: match.range(at: group))
}

func ids(_ pattern: String, in source: String) throws -> [String] {
    try regexMatches(pattern, in: source).map {
        (source as NSString).substring(with: $0.range(at: 1))
    }
}

func rows(in block: String) throws -> [[String]] {
    let rowMatches = try regexMatches(#"\[([^\[\]]*)\]"#, in: block)
    return try rowMatches.map { match in
        let rowText = (block as NSString).substring(with: match.range(at: 1))
        return try ids(#"\.([A-Za-z][A-Za-z0-9_]*)"#, in: rowText)
    }
}

func requireRows(_ value: [[String]], name: String) throws {
    guard value.count == 3, value.allSatisfy({ $0.count == 10 }) else {
        throw NSError(domain: "KeyboardSourceData", code: 2, userInfo: [NSLocalizedDescriptionKey: "\(name) must have exactly 3 rows of 10 components"])
    }
}

func gitBlobID(_ data: Data) -> String {
    var payload = Data("blob \(data.count)\0".utf8)
    payload.append(data)
    return Insecure.SHA1.hash(data: payload).map { String(format: "%02x", $0) }.joined()
}

func dictionaryPairs(_ name: String, source: String) throws -> [[String: String]] {
    let pattern = "static let \(name):\\s*\\[CharacterComponent:\\s*CharacterComponent\\]\\s*=\\s*\\[(.*?)\\]"
    let block = try capture(pattern, in: source, options: [.dotMatchesLineSeparators])
    return try regexMatches(#"\.([A-Za-z][A-Za-z0-9_]*)\s*:\s*\.([A-Za-z][A-Za-z0-9_]*)"#, in: block).map { match in
        [
            "from": (block as NSString).substring(with: match.range(at: 1)),
            "to": (block as NSString).substring(with: match.range(at: 2))
        ]
    }
}

func run() throws {
    guard CommandLine.arguments.count == 3 else {
        throw NSError(domain: "KeyboardSourceData", code: 3, userInfo: [NSLocalizedDescriptionKey: "usage: build-layout-source-data.swift <source-package-root> <fum-repository-root>"])
    }
    let packageRoot = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    let repositoryRoot = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
    let manifestURL = packageRoot.appendingPathComponent("source-manifest.json")
    let manifestData = try Data(contentsOf: manifestURL)
    let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)

    guard manifest.schema == "fum.keyboard-layout-source-manifest.1" else {
        throw NSError(domain: "KeyboardSourceData", code: 4, userInfo: [NSLocalizedDescriptionKey: "unsupported source manifest schema"])
    }

    var sourceTexts: [String: String] = [:]
    for file in manifest.source_files {
        let fileURL = packageRoot.appendingPathComponent(file.local_path)
        let data = try Data(contentsOf: fileURL)
        let actualBlob = gitBlobID(data)
        guard actualBlob == file.git_blob else {
            throw NSError(domain: "KeyboardSourceData", code: 5, userInfo: [NSLocalizedDescriptionKey: "Git blob mismatch for \(file.repository_path): expected \(file.git_blob), got \(actualBlob)"])
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "KeyboardSourceData", code: 6, userInfo: [NSLocalizedDescriptionKey: "non-UTF-8 source file: \(file.repository_path)"])
        }
        sourceTexts[file.repository_path] = text
    }

    let reusedLicenseURL = repositoryRoot.appendingPathComponent(manifest.license.reused_repository_path)
    let reusedLicense = try Data(contentsOf: reusedLicenseURL)
    let reusedLicenseBlob = gitBlobID(reusedLicense)
    guard reusedLicenseBlob == manifest.license.git_blob,
          reusedLicenseBlob == manifest.license.reused_git_blob else {
        throw NSError(domain: "KeyboardSourceData", code: 7, userInfo: [NSLocalizedDescriptionKey: "reused CC0 license blob does not match the pinned upstream LICENSE"])
    }

    func source(_ path: String) throws -> String {
        guard let value = sourceTexts[path] else {
            throw NSError(domain: "KeyboardSourceData", code: 8, userInfo: [NSLocalizedDescriptionKey: "source path is absent from manifest: \(path)"])
        }
        return value
    }

    let allLayoutsPath = "KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.allLayouts.swift"
    let allLayoutsSource = try source(allLayoutsPath)
    let allLayoutsBlock = try capture(#"allLayouts:\s*\[(.*?)\n\s*\]"#, in: allLayoutsSource, options: [.dotMatchesLineSeparators])
    let allLayoutIDs = try ids(#"\.([A-Za-z][A-Za-z0-9_]*)"#, in: allLayoutsBlock)
    guard allLayoutIDs == manifest.layout_order else {
        throw NSError(domain: "KeyboardSourceData", code: 9, userInfo: [NSLocalizedDescriptionKey: "allLayouts order differs from the source manifest"])
    }

    let keyPath = "KeyboardModule/Sources/KeyboardModule/Key.swift"
    let keySource = try source(keyPath)
    let boardBlock = try capture(#"static let board:\s*\[\[Key\]\]\s*=\s*\[(.*?)\n\s*\]"#, in: keySource, options: [.dotMatchesLineSeparators])
    let boardRows = try rows(in: boardBlock)
    let codeMatches = try regexMatches(#"static let\s+([A-Za-z][A-Za-z0-9_]*)\s*=\s*keys\[(\d+)\]"#, in: keySource)
    var keycodes: [String: Int] = [:]
    for match in codeMatches {
        let keyName = (keySource as NSString).substring(with: match.range(at: 1))
        let code = Int((keySource as NSString).substring(with: match.range(at: 2)))!
        keycodes[keyName] = code
    }
    guard let spaceKeycode = keycodes["space"] else {
        throw NSError(domain: "KeyboardSourceData", code: 16, userInfo: [NSLocalizedDescriptionKey: "Key.space keycode is missing"])
    }
    guard boardRows.count >= 4 else {
        throw NSError(domain: "KeyboardSourceData", code: 10, userInfo: [NSLocalizedDescriptionKey: "Key.board does not contain the source layoutBoard slice"])
    }
    var physicalRows: [[Any]] = []
    for boardRowIndex in 1...3 {
        let boardRow = boardRows[boardRowIndex]
        guard boardRow.count >= 11 else {
            throw NSError(domain: "KeyboardSourceData", code: 11, userInfo: [NSLocalizedDescriptionKey: "Key.board row is shorter than the layoutBoard column slice"])
        }
        var outputRow: [[String: Any]] = []
        for boardColumnIndex in 1...10 {
            let keyName = boardRow[boardColumnIndex]
            guard let keycode = keycodes[keyName] else {
                throw NSError(domain: "KeyboardSourceData", code: 12, userInfo: [NSLocalizedDescriptionKey: "missing keycode for physical key \(keyName)"])
            }
            outputRow.append([
                "row": boardRowIndex - 1,
                "column": boardColumnIndex - 1,
                "source_key": keyName,
                "keycode": keycode
            ])
        }
        physicalRows.append(outputRow)
    }

    let layoutBoardExpression = try capture(#"static let layoutBoard:\s*\[\[Key\]\]\s*=\s*([^\n]+)"#, in: keySource)
    let layoutPathPrefix = "KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout."
    var layouts: [[String: Any]] = []
    for layoutID in manifest.layout_order {
        let path = layoutPathPrefix + layoutID + ".swift"
        let layoutSource = try source(path)
        let rowsBlock = try capture(#"rows:\s*\[(.*?)\],\s*defaultInputSourceID:"#,
                                    in: layoutSource,
                                    options: [.dotMatchesLineSeparators])
        let componentRows = try rows(in: rowsBlock)
        try requireRows(componentRows, name: layoutID)
        let id = try capture(#"static let\s+([A-Za-z][A-Za-z0-9_]*)\s*="#, in: layoutSource)
        guard id == layoutID else {
            throw NSError(domain: "KeyboardSourceData", code: 13, userInfo: [NSLocalizedDescriptionKey: "layout source id mismatch for \(path)"])
        }
        layouts.append([
            "id": layoutID,
            "name": try capture(#"name:\s*"([^"]+)""#, in: layoutSource),
            "default_input_source_id": try capture(#"defaultInputSourceID:\s*"([^"]+)""#, in: layoutSource),
            "input_source_id_role": "provenance_only",
            "source_blob": manifest.source_files.first(where: { $0.repository_path == path })!.git_blob,
            "component_rows": componentRows
        ])
    }

    let layoutModelPath = "KeyboardModule/Sources/KeyboardModule/KeyboardLayout.swift"
    let layoutModelSource = try source(layoutModelPath)
    let optionBlock = try capture(#"static let option = KeyboardLayout\(\s*rows:\s*\[(.*?)\]\s*\)"#,
                                  in: layoutModelSource,
                                  options: [.dotMatchesLineSeparators])
    let optionRows = try rows(in: optionBlock)
    try requireRows(optionRows, name: "option")
    guard layoutModelSource.contains("zip(rows, Key.layoutBoard)"),
          layoutModelSource.contains("characterComponents[key.keycode] = characterComponent"),
          layoutModelSource.contains("characterComponents[Key.space.keycode] = .space"),
          layoutModelSource.contains("KeyboardLayout.shiftUpDictionary.values") else {
        throw NSError(domain: "KeyboardSourceData", code: 14, userInfo: [NSLocalizedDescriptionKey: "common layout-to-physical-key mapping expressions changed"])
    }
    let lookupBlock = try capture(#"public extension Array where Element == KeyboardLayout \{(.*?)\n\}"#,
                                  in: layoutModelSource,
                                  options: [.dotMatchesLineSeparators])
    guard lookupBlock.contains("firstIndex(of: inputSourceID)") && lookupBlock.contains("return .system") else {
        throw NSError(domain: "KeyboardSourceData", code: 15, userInfo: [NSLocalizedDescriptionKey: "input-source lookup behavior changed"])
    }

    let sourceMap = manifest.source_files.map { file in
        [
            "repository_path": file.repository_path,
            "git_blob": file.git_blob,
            "role": file.role
        ]
    }
    let output: [String: Any] = [
        "schema": "fum.keyboard-layout-source-data.1",
        "upstream": [
            "repository_url": manifest.upstream.repository_url,
            "observed_ref": manifest.upstream.observed_ref,
            "observed_on": manifest.upstream.observed_on,
            "commit": manifest.upstream.commit,
            "tree": manifest.upstream.tree,
            "commit_message": manifest.upstream.commit_message,
            "signature": [
                "verified": manifest.upstream.signature.verified,
                "reason": manifest.upstream.signature.reason
            ]
        ],
        "source_blobs": sourceMap,
        "license": [
            "repository_path": manifest.license.repository_path,
            "git_blob": manifest.license.git_blob,
            "name": manifest.license.name,
            "reused_repository_path": manifest.license.reused_repository_path,
            "reused_git_blob": reusedLicenseBlob
        ],
        "component_unit": "Exact CharacterComponent identifiers from upstream; this package does not convert them to rendered Unicode text.",
        "layout_order": allLayoutIDs,
        "physical_layout_board": [
            "source_path": keyPath,
            "source_git_blob": manifest.source_files.first(where: { $0.repository_path == keyPath })!.git_blob,
            "source_expression": layoutBoardExpression.trimmingCharacters(in: .whitespacesAndNewlines),
            "coordinate_convention": "Rows and columns are zero-based after the source expression selects board rows 1...3 and columns 1...10.",
            "rows": physicalRows
        ],
        "common_source_semantics": [
            "model_source_path": layoutModelPath,
            "model_git_blob": manifest.source_files.first(where: { $0.repository_path == layoutModelPath })!.git_blob,
            "layout_mapping_expression": "zip(rows, Key.layoutBoard); characterComponents[key.keycode] = characterComponent",
            "space_assignment": [
                "source_expression": "characterComponents[Key.space.keycode] = .space",
                "source_key": "space",
                "keycode": spaceKeycode,
                "component": "space",
                "outside_layout_board_rows": true
            ],
            "option_component_rows": optionRows,
            "shift_up_dictionary": try dictionaryPairs("shiftUpDictionary", source: layoutModelSource),
            "shift_right_dictionary": try dictionaryPairs("shiftRightDictionary", source: layoutModelSource),
            "reversed_shift_right_dictionary_source_expression": "Dictionary(uniqueKeysWithValues: shiftRightDictionary.map {($1, $0)})",
            "component_universe_expression": "characterComponents + KeyboardLayout.option.characterComponents + KeyboardLayout.shiftUpDictionary.values + [.space]",
            "input_source_lookup": "Array<KeyboardLayout>.element(inputSourceID:) selects the exact matching inputSourceID or returns .system; this behavior is source provenance only.",
            "default_input_source_ids_are_provenance_only": true,
            "FUMA_input_source_policy": "Select an explicit layout identifier; do not derive FUMA layout computation from the host native/default input source.",
            "space_is_outside_layout_board_rows": true
        ],
        "layouts": layouts
    ]

    let outputURL = packageRoot.appendingPathComponent("layout-source-data.json")
    let outputData = try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys])
    var finalData = outputData
    finalData.append(0x0A)
    try finalData.write(to: outputURL, options: .atomic)
}

do {
    try run()
} catch {
    fputs("build-layout-source-data: \(error.localizedDescription)\n", stderr)
    exit(1)
}
