import SwiftUI
import Observation

enum PanelPosition {
    case left, right
}

enum SortCriterion: String, CaseIterable {
    case name, `extension`, size, date

    var label: String {
        switch self {
        case .name: return "Name"
        case .extension: return "Ext"
        case .size: return "Size"
        case .date: return "Date"
        }
    }
}

enum SelectionCriteria: Sendable {
    case bySize(min: Int64?, max: Int64?)
    case byExtension([String])
    case byName(contains: String)
    case byDate(newerThanHours: Int)
}

enum FilterPreset: String, CaseIterable {
    case all, images, text, archives

    var label: String {
        switch self {
        case .all: return "All"
        case .images: return "Img"
        case .text: return "Text"
        case .archives: return "Arc"
        }
    }

    var extensions: Set<String>? {
        switch self {
        case .all: return nil
        case .images: return FileService.imageExtensions
        case .text: return FileService.textExtensions
        case .archives: return FileService.archiveExtensions
        }
    }
}

@MainActor
@Observable
final class PanelViewModel {
    var currentDirectory: URL
    var files: [FileItem] = []
    var cursorIndex: Int = 0
    var selectedURLs: Set<URL> = []
    var sortBy: SortCriterion = .name
    var sortAscending: Bool = true
    var showHiddenFiles: Bool = false
    var filter: String = ""
    var filterPreset: FilterPreset = .all
    var isLoading: Bool = false
    var calculatedSizes: [URL: Int64] = [:]
    var backStack: [URL] = []
    var forwardStack: [URL] = []
    var pendingCursorName: String?
    var didNavigate: (() -> Void)?

    private let fileService = FileService()

    var filteredFiles: [FileItem] {
        let sorted = files.sorted { a, b in
            let lhs = (a.isDirectory ? 0 : 1, sortValue(a))
            let rhs = (b.isDirectory ? 0 : 1, sortValue(b))
            return sortAscending ? lhs < rhs : lhs > rhs
        }
        let named = filter.isEmpty ? sorted : sorted.filter { $0.name.localizedCaseInsensitiveContains(filter) }
        guard let exts = filterPreset.extensions else { return named }
        return named.filter { exts.contains($0.extension.lowercased()) || $0.isDirectory }
    }

    var itemsCount: Int {
        filteredFiles.filter { !$0.isParent }.count
    }

    private func sortValue(_ item: FileItem) -> String {
        switch sortBy {
        case .name: return item.name.localizedLowercase
        case .extension: return item.extension
        case .size: return String(format: "%020lld", item.size)
        case .date: return String(Int64(item.modificationDate.timeIntervalSince1970))
        }
    }

    init(path: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentDirectory = path
    }

    func loadFiles() async {
        isLoading = true
        defer { isLoading = false }
        var items: [FileItem] = []
        do {
            items = try await fileService.listFiles(at: currentDirectory, showHidden: showHiddenFiles)
        } catch {
            items = []
        }
        if currentDirectory.path != "/",
           let parent = FileItem.parentDirectory(for: currentDirectory) {
            items.insert(parent, at: 0)
        }
        // Ensure /Volumes always appears at root
        if currentDirectory.path == "/",
           !items.contains(where: { $0.name == "Volumes" }),
           let volumes = FileItem(url: URL(fileURLWithPath: "/Volumes")) {
            items.append(volumes)
        }
        files = items
        if let target = pendingCursorName {
            if let match = files.first(where: { $0.name == target }),
               let idx = filteredFiles.firstIndex(of: match) {
                cursorIndex = idx
            }
            pendingCursorName = nil
        }
        if cursorIndex >= files.count { cursorIndex = max(0, files.count - 1) }
    }

    func navigateTo(_ url: URL) {
        if currentDirectory != url {
            backStack.append(currentDirectory)
            forwardStack.removeAll()
        }
        currentDirectory = url
        cursorIndex = 0
        selectedURLs.removeAll()
        calculatedSizes.removeAll()
        Task { await loadFiles() }
        didNavigate?()
    }

    func goBack() {
        guard let prev = backStack.popLast() else { return }
        forwardStack.append(currentDirectory)
        currentDirectory = prev
        cursorIndex = 0
        selectedURLs.removeAll()
        calculatedSizes.removeAll()
        Task { await loadFiles() }
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(currentDirectory)
        currentDirectory = next
        cursorIndex = 0
        selectedURLs.removeAll()
        calculatedSizes.removeAll()
        Task { await loadFiles() }
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    var previewCallback: ((URL) -> Void)?

    func selectFiles(matching criteria: SelectionCriteria) {
        let matches = filteredFiles.filter { file in
            if file.isParent { return false }
            switch criteria {
            case let .bySize(min, max):
                if let m = min, file.size < m { return false }
                if let m = max, file.size > m { return false }
                return file.size >= 0
            case let .byExtension(exts):
                return exts.contains(file.extension.lowercased())
            case let .byName(contains):
                return file.name.localizedCaseInsensitiveContains(contains)
            case let .byDate(newerThanHours):
                let cutoff = Date().addingTimeInterval(-Double(newerThanHours) * 3600)
                return file.modificationDate >= cutoff
            }
        }
        selectedURLs = Set(matches.map(\.url))
    }

    func selectFiles(matching names: [String]) {
        let nameSet = Set(names)
        let matches = filteredFiles.filter { nameSet.contains($0.name) }
        selectedURLs = Set(matches.map(\.url))
    }

    func enterDirectory(at index: Int) {
        guard index >= 0, index < filteredFiles.count else { return }
        let item = filteredFiles[index]
        if item.isDirectory { navigateTo(item.url) }
        else { NSWorkspace.shared.open(item.url) }
    }

    func enterCurrent() {
        guard cursorIndex < filteredFiles.count else { return }
        let item = filteredFiles[cursorIndex]
        if item.name == ".." {
            goUp()
            return
        }
        if item.isDirectory { navigateTo(item.url) }
        else if NSWorkspace.shared.urlForApplication(toOpen: item.url) == nil {
            previewCallback?(item.url)
        }
        else { NSWorkspace.shared.open(item.url) }
    }

    func goUp() {
        pendingCursorName = currentDirectory.lastPathComponent
        navigateTo(currentDirectory.deletingLastPathComponent())
    }

    func moveCursorUp() {
        if cursorIndex > 0 { cursorIndex -= 1 }
    }

    func moveCursorDown() {
        if cursorIndex < filteredFiles.count - 1 { cursorIndex += 1 }
    }

    func moveCursorToFirst() {
        cursorIndex = 0
    }

    func moveCursorToLast() {
        cursorIndex = max(0, filteredFiles.count - 1)
    }

    func moveCursorPageUp() {
        cursorIndex = max(0, cursorIndex - 20)
    }

    func moveCursorPageDown() {
        cursorIndex = min(filteredFiles.count - 1, cursorIndex + 20)
    }

    func toggleSelection(at index: Int) {
        guard index >= 0, index < filteredFiles.count else { return }
        let url = filteredFiles[index].url
        if selectedURLs.contains(url) { selectedURLs.remove(url) }
        else { selectedURLs.insert(url) }
    }

    func toggleSelectionOnCurrent() {
        toggleSelection(at: cursorIndex)
    }

    func selectAll() {
        selectedURLs = Set(filteredFiles.map(\.url))
    }

    func deselectAll() {
        selectedURLs.removeAll()
    }

    func invertSelection() {
        let all = Set(filteredFiles.map(\.url))
        selectedURLs = all.subtracting(selectedURLs)
    }

    func selectGroup(_ pattern: String) {
        selectedURLs = Set(filteredFiles.filter { $0.name.localizedCaseInsensitiveContains(pattern) }.map(\.url))
    }

    var selectedFiles: [FileItem] {
        filteredFiles.filter { selectedURLs.contains($0.url) }
    }

    var activeItems: [URL] {
        if selectedURLs.isEmpty {
            guard cursorIndex < filteredFiles.count else { return [] }
            return [filteredFiles[cursorIndex].url]
        }
        return Array(selectedURLs)
    }

    func refresh() {
        Task { await loadFiles() }
    }

    var totalSize: Int64 {
        filteredFiles.reduce(0) { $0 + max(0, $1.size) }
    }

    func calculateSizeForCurrent() {
        guard cursorIndex < filteredFiles.count else { return }
        let item = filteredFiles[cursorIndex]
        guard item.isDirectory, !item.isParent else { return }
        let url = item.url
        Task {
            let size = await fileService.directorySize(at: url)
            calculatedSizes[url] = size
        }
    }

    var freeSpace: Int64 {
        guard let attrs = try? currentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey]),
              let free = attrs.volumeAvailableCapacity
        else { return 0 }
        return Int64(free)
    }
}
