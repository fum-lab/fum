#if SWIFT_PACKAGE
import ПутиИсполнения
#endif
import SwiftUI
import Foundation
import AppKit

struct KnowledgeSurface: View {
    @State private var library = KnowledgeLibrary.load()
    @State private var selectedShelf: KnowledgeShelf = .glossary
    @State private var selectedDocumentID: String?
    @State private var searchText = ""

    private var documents: [KnowledgeDocument] {
        library.documents(on: selectedShelf, matching: searchText)
    }

    private var selectedDocument: KnowledgeDocument? {
        if let selectedDocumentID, let document = documents.first(where: { $0.id == selectedDocumentID }) {
            return document
        }

        return documents.first
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear {
            selectedDocumentID = selectedDocument?.id
        }
        .onChange(of: selectedShelf) { _, _ in
            selectedDocumentID = documents.first?.id
        }
        .onChange(of: searchText) { _, _ in
            if let selectedDocumentID, documents.contains(where: { $0.id == selectedDocumentID }) {
                return
            }
            selectedDocumentID = documents.first?.id
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Знание FUM")
                    .font(.system(size: 22, weight: .semibold))
                Text("\(library.glossary.count) терминов · \(library.axioms.count) аксиом")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker("Раздел", selection: $selectedShelf) {
                ForEach(KnowledgeShelf.allCases) { shelf in
                    Label(shelf.title, systemImage: shelf.symbol)
                        .tag(shelf)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Искать", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            List(selection: $selectedDocumentID) {
                ForEach(KnowledgeSection.group(documents)) { section in
                    Section(section.title) {
                        ForEach(section.documents) { document in
                            KnowledgeRow(document: document)
                                .tag(document.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            HStack {
                Button {
                    library = KnowledgeLibrary.load()
                    selectedDocumentID = selectedDocument?.id ?? documents.first?.id
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("Обновить документы")

                Spacer()

                Text(library.shortStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(20)
        .frame(width: 320)
    }

    private var detail: some View {
        Group {
            if let selectedDocument {
                KnowledgeDetail(document: selectedDocument)
            } else {
                ContentUnavailableView(
                    "Ничего не найдено",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Измени запрос или переключи раздел.")
                )
            }
        }
    }
}

private struct KnowledgeRow: View {
    let document: KnowledgeDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(document.title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            if !document.summary.isEmpty {
                Text(document.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 3)
    }
}

private struct KnowledgeDetail: View {
    let document: KnowledgeDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Label(document.shelf.title, systemImage: document.shelf.symbol)
                        .font(.caption)
                        .foregroundStyle(document.shelf.color)
                    Text(document.section)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(document.url)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.borderless)
                    .help("Открыть Markdown-файл")
                }

                Text(document.title)
                    .font(.system(size: 30, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)

                MarkdownText(markdown: document.body)
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .textSelection(.enabled)

                Divider()

                HStack(spacing: 8) {
                    Image(systemName: "folder")
                    Text(document.relativePath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(28)
            .frame(maxWidth: 880, alignment: .leading)
        }
    }
}

private struct MarkdownText: View {
    let markdown: String

    private var attributed: AttributedString {
        (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }

    var body: some View {
        Text(attributed)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum KnowledgeShelf: String, CaseIterable, Identifiable {
    case glossary
    case axioms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glossary: "Глоссарий"
        case .axioms: "Аксиомы"
        }
    }

    var symbol: String {
        switch self {
        case .glossary: "text.book.closed"
        case .axioms: "checkmark.seal"
        }
    }

    var color: Color {
        switch self {
        case .glossary: .purple
        case .axioms: .blue
        }
    }
}

private struct KnowledgeLibrary {
    var glossary: [KnowledgeDocument]
    var axioms: [KnowledgeDocument]
    var loadedAt: Date

    var shortStatus: String {
        loadedAt.formatted(date: .omitted, time: .shortened)
    }

    static func load(root: URL = URL(fileURLWithPath: ПутиПриложения.текущие.документы.path)) -> KnowledgeLibrary {
        KnowledgeLibrary(
            glossary: KnowledgeCatalogLoader.load(
                shelf: .glossary,
                root: root,
                indexFile: "Glossarij.md",
                directory: "glossary"
            ),
            axioms: KnowledgeCatalogLoader.load(
                shelf: .axioms,
                root: root,
                indexFile: "Aksiomy_FUM.md",
                directory: "axioms"
            ),
            loadedAt: Date()
        )
    }

    func documents(on shelf: KnowledgeShelf, matching query: String) -> [KnowledgeDocument] {
        let source = shelf == .glossary ? glossary : axioms
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return source
        }

        return source.filter { document in
            document.searchText.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }
}

private struct KnowledgeDocument: Identifiable, Hashable {
    let id: String
    let shelf: KnowledgeShelf
    let title: String
    let section: String
    let body: String
    let url: URL
    let relativePath: String
    let order: Int

    var summary: String {
        body
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { line in
                !line.isEmpty && !line.hasPrefix("#") && !line.hasPrefix("Раздел:")
            }
            .map { String($0) } ?? ""
    }

    var searchText: String {
        "\(title)\n\(section)\n\(body)"
    }
}

private struct KnowledgeSection: Identifiable {
    let title: String
    let documents: [KnowledgeDocument]

    var id: String { title }

    static func group(_ documents: [KnowledgeDocument]) -> [KnowledgeSection] {
        var grouped: [KnowledgeSection] = []
        for document in documents {
            if let index = grouped.firstIndex(where: { $0.title == document.section }) {
                var sectionDocuments = grouped[index].documents
                sectionDocuments.append(document)
                grouped[index] = KnowledgeSection(title: document.section, documents: sectionDocuments)
            } else {
                grouped.append(KnowledgeSection(title: document.section, documents: [document]))
            }
        }
        return grouped
    }
}

private enum KnowledgeCatalogLoader {
    static func load(shelf: KnowledgeShelf, root: URL, indexFile: String, directory: String) -> [KnowledgeDocument] {
        let indexURL = root.appendingPathComponent(indexFile)
        let directoryURL = root.appendingPathComponent(directory)
        let entries = parseIndex(indexURL: indexURL)
        let indexedDocuments = entries.enumerated().compactMap { offset, entry in
            document(
                shelf: shelf,
                root: root,
                url: root.appendingPathComponent(entry.path),
                fallbackTitle: entry.title,
                section: entry.section,
                order: offset
            )
        }

        let indexedPaths = Set(indexedDocuments.map(\.url.path))
        let remainingDocuments = allMarkdownFiles(in: directoryURL)
            .filter { !indexedPaths.contains($0.path) }
            .enumerated()
            .compactMap { offset, url in
                document(
                    shelf: shelf,
                    root: root,
                    url: url,
                    fallbackTitle: url.deletingPathExtension().lastPathComponent,
                    section: "Без раздела",
                    order: entries.count + offset
                )
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

        return indexedDocuments + remainingDocuments
    }

    private static func parseIndex(indexURL: URL) -> [IndexEntry] {
        guard let text = try? String(contentsOf: indexURL, encoding: .utf8) else {
            return []
        }

        var currentSection = "Без раздела"
        var entries: [IndexEntry] = []

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("## ") {
                currentSection = String(line.dropFirst(3))
                continue
            }

            guard line.hasPrefix("- ["),
                  let titleEnd = line.range(of: "]("),
                  let pathEnd = line[titleEnd.upperBound...].firstIndex(of: ")")
            else {
                continue
            }

            let title = String(line[line.index(line.startIndex, offsetBy: 3)..<titleEnd.lowerBound])
            let path = String(line[titleEnd.upperBound..<pathEnd])
            entries.append(IndexEntry(title: title, path: path, section: currentSection))
        }

        return entries
    }

    private static func document(
        shelf: KnowledgeShelf,
        root: URL,
        url: URL,
        fallbackTitle: String,
        section: String,
        order: Int
    ) -> KnowledgeDocument? {
        guard let body = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        let title = body
            .components(separatedBy: .newlines)
            .first { $0.hasPrefix("# ") }
            .map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines) }
            ?? fallbackTitle

        return KnowledgeDocument(
            id: url.path,
            shelf: shelf,
            title: title,
            section: section,
            body: body,
            url: url,
            relativePath: relativePath(from: root, to: url),
            order: order
        )
    }

    private static func allMarkdownFiles(in directoryURL: URL) -> [URL] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return files.filter { $0.pathExtension == "md" }
    }

    private static func relativePath(from root: URL, to url: URL) -> String {
        let rootPath = root.path
        let urlPath = url.path
        guard urlPath.hasPrefix(rootPath) else {
            return urlPath
        }

        return String(urlPath.dropFirst(rootPath.count + 1))
    }

    private struct IndexEntry {
        let title: String
        let path: String
        let section: String
    }
}
