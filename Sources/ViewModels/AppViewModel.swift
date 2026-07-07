import SwiftUI
import Observation
import AppKit
import UniformTypeIdentifiers

@MainActor
@Observable
final class AppViewModel {

    enum OverwriteMode: Equatable {
        case ask, yes, no, all, smaller, older, diffSize, none
    }

    struct OverwriteInfo {
        let sourceURL: URL
        let destURL: URL
        let sourceName: String
        let destName: String
        let sourceSize: Int64
        let sourceDate: Date
        let destSize: Int64
        let destDate: Date
        let remaining: Int
    }
    var leftPanel = PanelViewModel()
    var rightPanel = PanelViewModel()
    var activePanel: PanelPosition = .left
    var currentOperation: FileOperation?
    var operationProgress: Double = 0
    var operationLabel: String = ""
    var operationRunning = false
    var operationTotalFiles = 0
    var operationCompletedFiles = 0
    var operationBytesCopied: Int64 = 0
    var operationTotalBytes: Int64 = 0
    var showCommandLine = false
    var commandLineText = ""
    var theme: AppTheme = .dark
    var errorMessage: String?
    var isPersistentDelete = false
    var showSettings = false
    var showSplash = true
    var aiPrompt = ""
    var lastAIPrompt = ""
    var aiLoading = false
    var aiResult: AIService.Result?
    var aiSafetyCheck: AIService.SafetyCheck?
    var aiError: String?
    var showAIDialog = false
    var showGoto = false
    var gotoPath = ""
    var showAIPrompt = false
    var showFilePreview = false
    var filePreview: FilePreviewContent?

    var overwriteInfo: OverwriteInfo?
    var overwriteApproved: Set<URL> = []
    var overwriteAllSources: [URL] = []
    var overwriteDestination: URL = FileManager.default.homeDirectoryForCurrentUser
    var overwriteConflicts: [(source: URL, dest: URL)] = []
    var overwriteQueue: [(source: URL, dest: URL)] = []
    var overwritePendingOperation: FileOperation?
    var overwriteSelectedIndex: Int = 0
    var ollamaHost: String = UserDefaults.standard.string(forKey: "ollama_host") ?? "http://localhost:11434"
    var ollamaModel: String = UserDefaults.standard.string(forKey: "ollama_model") ?? ""
    var aiProvider: AIProvider = AIProvider(rawValue: UserDefaults.standard.string(forKey: "ai_provider") ?? "Ollama") ?? .ollama
    var openaiHost: String = UserDefaults.standard.string(forKey: "openai_host") ?? "https://api.deepseek.com"
    var openaiModel: String = UserDefaults.standard.string(forKey: "openai_model") ?? ""
    var openaiKey: String = KeychainService.load(key: "openai_key") ?? ""

    private let fileService = FileService()
    private let aiService = AIService()
    private var keyboardService: KeyboardService?

    var activePanelViewModel: PanelViewModel {
        activePanel == .left ? leftPanel : rightPanel
    }

    var inactivePanelViewModel: PanelViewModel {
        activePanel == .left ? rightPanel : leftPanel
    }

    var themeColors: ThemeColors { theme.colors }
    var themeFont: Font { theme.font }

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let defaults = UserDefaults.standard
        if let leftPath = defaults.string(forKey: "left_dir") {
            leftPanel.currentDirectory = URL(fileURLWithPath: leftPath)
        } else {
            leftPanel.currentDirectory = home
        }
        if let rightPath = defaults.string(forKey: "right_dir") {
            rightPanel.currentDirectory = URL(fileURLWithPath: rightPath)
        } else {
            rightPanel.currentDirectory = home.appendingPathComponent("Downloads")
        }
        leftPanel.previewCallback = { [weak self] url in self?.loadFilePreview(for: url) }
        rightPanel.previewCallback = { [weak self] url in self?.loadFilePreview(for: url) }
        leftPanel.didNavigate = { [weak self] in self?.savePanelDirs() }
        rightPanel.didNavigate = { [weak self] in self?.savePanelDirs() }
        Task {
            await leftPanel.loadFiles()
            await rightPanel.loadFiles()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            showSplash = false
        }
    }

    func setupKeyboardShortcuts() {
        keyboardService = KeyboardService()
        keyboardService?.startMonitoring(appVM: self)
    }

    func switchActivePanel() {
        activePanel = activePanel == .left ? .right : .left
    }

    // MARK: - Key event handling

    private var isModalOpen: Bool {
        currentOperation != nil || showSettings || showAIDialog || showAIPrompt || showGoto || overwriteInfo != nil || errorMessage != nil
    }

    func handleKeyEvent(_ event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Modal dialogs: only handle Escape and Enter, plus overwrite keys
        if isModalOpen {
            switch keyCode {
            case KeyCodes.escape.rawValue:
                cancelOperation()
                showSettings = false
                showAIPrompt = false
                showGoto = false
                closeAIDialog()
                return true
            default:
                break
            }

            // Overwrite dialog: arrow navigation between buttons
            if overwriteInfo != nil && mods.intersection([.shift, .control, .option, .command]).isEmpty {
                switch keyCode {
                case KeyCodes.left.rawValue:
                    overwriteSelectedIndex = max(0, overwriteSelectedIndex - 1); return true
                case KeyCodes.right.rawValue:
                    overwriteSelectedIndex = min(6, overwriteSelectedIndex + 1); return true
                case KeyCodes.return.rawValue:
                    overwriteAnswer(overwriteAction(for: overwriteSelectedIndex)); return true
                default:
                    break
                }
            }

            if overwriteInfo != nil {
                if let chars = event.characters?.lowercased(), let char = chars.first {
                    switch char {
                    case "y": overwriteAnswer(.yes); return true
                    case "n": overwriteAnswer(.no); return true
                    case "a": overwriteAnswer(.all); return true
                    case "s": overwriteAnswer(.smaller); return true
                    case "o": overwriteAnswer(.older); return true
                    case "d": overwriteAnswer(.diffSize); return true
                    case "u": overwriteAnswer(.none); return true
                    case "\r", "\n": overwriteAnswer(.yes); return true
                    default: break
                    }
                }
            }

            return false
        }

        // F-keys always work
        switch keyCode {
        case KeyCodes.f1.rawValue:
            showHelp()
            return true
        case KeyCodes.f2.rawValue:
            showAIPrompt = true
            return true
        case KeyCodes.f3.rawValue:
            beginGoto()
            return true
        case KeyCodes.f4.rawValue:
            editFile()
            return true
        case KeyCodes.f5.rawValue:
            beginCopy()
            return true
        case KeyCodes.f6.rawValue:
            beginMove()
            return true
        case KeyCodes.f7.rawValue:
            beginMkdir()
            return true
        case KeyCodes.f8.rawValue:
            beginDelete()
            return true
        case KeyCodes.f9.rawValue:
            beginRename()
            return true
        case KeyCodes.f10.rawValue:
            NSApplication.shared.terminate(nil)
            return true
        default:
            break
        }

        // Only modifier-free keys below
        let userMods = mods.intersection([.shift, .control, .option, .command])
        guard userMods.isEmpty else { return false }

        switch keyCode {
        case KeyCodes.tab.rawValue:
            switchActivePanel()
            return true

        case KeyCodes.return.rawValue:
            activePanelViewModel.enterCurrent()
            return true

        case KeyCodes.delete.rawValue:
            activePanelViewModel.goUp()
            return true

        case KeyCodes.escape.rawValue:
            if !activePanelViewModel.selectedURLs.isEmpty {
                activePanelViewModel.deselectAll()
                return true
            }
            return false

        case KeyCodes.up.rawValue:
            activePanelViewModel.moveCursorUp()
            return true
        case KeyCodes.down.rawValue:
            activePanelViewModel.moveCursorDown()
            return true

        case KeyCodes.home.rawValue:
            activePanelViewModel.moveCursorToFirst()
            return true
        case KeyCodes.end.rawValue:
            activePanelViewModel.moveCursorToLast()
            return true
        case KeyCodes.pageUp.rawValue:
            activePanelViewModel.moveCursorPageUp()
            return true
        case KeyCodes.pageDown.rawValue:
            activePanelViewModel.moveCursorPageDown()
            return true

        case KeyCodes.space.rawValue:
            activePanelViewModel.toggleSelectionOnCurrent()
            activePanelViewModel.moveCursorDown()
            return true

        case KeyCodes.keypadPlus.rawValue:
            activePanelViewModel.selectAll()
            return true
        case KeyCodes.keypadMinus.rawValue:
            activePanelViewModel.deselectAll()
            return true
        case KeyCodes.keypadMultiply.rawValue:
            activePanelViewModel.invertSelection()
            return true

        default:
            return false
        }
    }

    // MARK: - Operations

    func beginGoto() {
        gotoPath = "/Volumes"
        showGoto = true
    }

    func executeGoto() {
        let path = (gotoPath as NSString).standardizingPath
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "Path not found: \(path)"
            showGoto = false
            return
        }
        activePanelViewModel.navigateTo(url)
        showGoto = false
    }

    func beginCopy() {
        beginTransfer(mode: .copy)
    }

    func beginMove() {
        beginTransfer(mode: .move)
    }

    private enum TransferMode { case copy, move }

    private func beginTransfer(mode: TransferMode) {
        let items = activePanelViewModel.activeItems
        guard !items.isEmpty else { return }
        let dest = inactivePanelViewModel.currentDirectory

        let conflicts: [(URL, URL)] = items.compactMap { src in
            let target = dest.appendingPathComponent(src.lastPathComponent)
            return FileManager.default.fileExists(atPath: target.path) ? (src, target) : nil
        }

        if conflicts.isEmpty {
            let op: FileOperation = mode == .copy
                ? .copy(sources: items, destination: dest)
                : .move(sources: items, destination: dest)
            currentOperation = op
        } else {
            overwritePendingOperation = mode == .copy
                ? .copy(sources: items, destination: dest)
                : .move(sources: items, destination: dest)
            overwriteAllSources = items
            overwriteDestination = dest
            overwriteApproved = []
            overwriteConflicts = conflicts
            overwriteQueue = conflicts
            showNextOverwrite()
        }
    }

    func beginDelete() {
        let items = activePanelViewModel.activeItems
        guard !items.isEmpty else { return }
        currentOperation = .delete(sources: items)
    }

    func beginMkdir() {
        currentOperation = .mkdir(parent: activePanelViewModel.currentDirectory)
    }

    func beginRename() {
        guard let item = activePanelViewModel.filteredFiles[safe: activePanelViewModel.cursorIndex] else { return }
        currentOperation = .rename(file: item.url)
    }

    func executeCurrentOperation() {
        guard let op = currentOperation else { return }
        operationProgress = 0
        operationLabel = ""
        operationRunning = true
        operationCompletedFiles = 0
        operationBytesCopied = 0
        operationTotalBytes = 0
        operationTotalFiles = 0
        Task {
            do {
                try await executeOperation(op)
                currentOperation = nil
                operationRunning = false
                await activePanelViewModel.loadFiles()
                await inactivePanelViewModel.loadFiles()
            } catch {
                errorMessage = error.localizedDescription
                currentOperation = nil
                operationRunning = false
            }
        }
    }

    func cancelOperation() {
        currentOperation = nil
        operationProgress = 0
        operationLabel = ""
        operationRunning = false
        operationTotalFiles = 0
        operationCompletedFiles = 0
        operationBytesCopied = 0
        operationTotalBytes = 0
        overwriteInfo = nil
        overwriteQueue = []
        overwriteApproved = []
        overwritePendingOperation = nil
    }

    private func overwriteAction(for index: Int) -> OverwriteMode {
        switch index {
        case 0: return .yes
        case 1: return .no
        case 2: return .all
        case 3: return .smaller
        case 4: return .older
        case 5: return .diffSize
        default: return .none
        }
    }

    private func showNextOverwrite() {
        overwriteSelectedIndex = 0
        guard let (src, dest) = overwriteQueue.first else {
            overwriteInfo = nil
            executeOverwriteBatch()
            return
        }
        overwriteQueue.removeFirst()

        let srcAttrs = (try? FileManager.default.attributesOfItem(atPath: src.path)) ?? [:]
        let dstAttrs = (try? FileManager.default.attributesOfItem(atPath: dest.path)) ?? [:]

        overwriteInfo = OverwriteInfo(
            sourceURL: src, destURL: dest,
            sourceName: src.lastPathComponent, destName: dest.lastPathComponent,
            sourceSize: (srcAttrs[.size] as? NSNumber)?.int64Value ?? 0,
            sourceDate: (srcAttrs[.modificationDate] as? Date) ?? Date(),
            destSize: (dstAttrs[.size] as? NSNumber)?.int64Value ?? 0,
            destDate: (dstAttrs[.modificationDate] as? Date) ?? Date(),
            remaining: overwriteQueue.count + 1
        )
    }

    func overwriteAnswer(_ mode: OverwriteMode) {
        guard let info = overwriteInfo else { return }
        overwriteInfo = nil

        switch mode {
        case .yes:
            overwriteApproved.insert(info.sourceURL)
            showNextOverwrite()
        case .no:
            showNextOverwrite()
        case .all:
            for (src, _) in overwriteQueue { overwriteApproved.insert(src) }
            overwriteQueue.removeAll()
            executeOverwriteBatch()
        case .none:
            overwriteQueue.removeAll()
            overwriteInfo = nil
            overwritePendingOperation = nil
        case .smaller:
            for (src, dest) in overwriteQueue {
                if fileSize(src) < fileSize(dest) { overwriteApproved.insert(src) }
            }
            overwriteQueue.removeAll()
            executeOverwriteBatch()
        case .older:
            for (src, dest) in overwriteQueue {
                if fileDate(src) < fileDate(dest) { overwriteApproved.insert(src) }
            }
            overwriteQueue.removeAll()
            executeOverwriteBatch()
        case .diffSize:
            for (src, dest) in overwriteQueue {
                if fileSize(src) != fileSize(dest) { overwriteApproved.insert(src) }
            }
            overwriteQueue.removeAll()
            executeOverwriteBatch()
        case .ask:
            break
        }
    }

    private func fileSize(_ url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }

    private func fileDate(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
    }

    private func executeOverwriteBatch() {
        guard let op = overwritePendingOperation else { return }
        let conflictSources = Set(overwriteConflicts.map(\.source))
        let nonConflicting = overwriteAllSources.filter { !conflictSources.contains($0) }
        let finalSources = nonConflicting + Array(overwriteApproved)
        guard !finalSources.isEmpty else {
            overwriteInfo = nil
            overwritePendingOperation = nil
            return
        }
        let dest = overwriteDestination
        switch op {
        case .copy:
            currentOperation = .copy(sources: finalSources, destination: dest)
        case .move:
            currentOperation = .move(sources: finalSources, destination: dest)
        default:
            return
        }
        overwritePendingOperation = nil
        overwriteApproved = []
        overwriteInfo = nil
        executeCurrentOperation()
    }

    private func executeOperation(_ op: FileOperation) async throws {
        switch op {
        case .copy(let sources, let dest):
            // Phase 1: expand all directories into flat file list
            var allFiles: [(url: URL, destPath: String)] = []
            for src in sources {
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: src.path, isDirectory: &isDir) else { continue }
                if isDir.boolValue {
                    let tree = await fileService.collectFileTree(at: src)
                    let base = src.lastPathComponent
                    for (url, rel) in tree {
                        allFiles.append((url, (base as NSString).appendingPathComponent(rel)))
                    }
                } else {
                    allFiles.append((src, src.lastPathComponent))
                }
            }
            let total = allFiles.count
            operationTotalFiles = total
            operationLabel = "Scanning…"
            let totalBytes: Int64 = allFiles.reduce(0) { acc, f in
                acc + Int64((try? f.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            }
            operationTotalBytes = totalBytes
            for (i, file) in allFiles.enumerated() {
                try Task.checkCancellation()
                operationCompletedFiles = i
                let fileName = file.url.lastPathComponent
                operationLabel = progressLabel(for: fileName, at: i, of: total)
                operationProgress = Double(i) / Double(total)
                try await fileService.copyFile(at: file.url, to: dest.appendingPathComponent(file.destPath))
                let size = (try? file.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                operationBytesCopied += Int64(size)
            }
            operationCompletedFiles = total
            operationBytesCopied = totalBytes
            operationLabel = progressLabel(for: "Done", at: total, of: total)
            operationProgress = 1
        case .move(let sources, let dest):
            var allFiles: [(url: URL, destPath: String, srcDir: URL)] = []
            for src in sources {
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: src.path, isDirectory: &isDir) else { continue }
                if isDir.boolValue {
                    let tree = await fileService.collectFileTree(at: src)
                    let base = src.lastPathComponent
                    for (url, rel) in tree {
                        allFiles.append((url, (base as NSString).appendingPathComponent(rel), src))
                    }
                } else {
                    allFiles.append((src, src.lastPathComponent, src.deletingLastPathComponent()))
                }
            }
            let total = allFiles.count
            operationTotalFiles = total
            operationLabel = "Scanning…"
            let totalBytes: Int64 = allFiles.reduce(0) { acc, f in
                acc + Int64((try? f.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            }
            operationTotalBytes = totalBytes
            for (i, file) in allFiles.enumerated() {
                try Task.checkCancellation()
                operationCompletedFiles = i
                let fileName = file.url.lastPathComponent
                operationLabel = progressLabel(for: fileName, at: i, of: total)
                operationProgress = Double(i) / Double(total)
                try await fileService.moveFile(at: file.url, to: dest.appendingPathComponent(file.destPath))
                let size = (try? file.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                operationBytesCopied += Int64(size)
            }
            // Remove empty source directories
            let sourceDirs = Set(sources.filter { src in
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: src.path, isDirectory: &isDir)
                return isDir.boolValue
            })
            // Clean up emptied dirs bottom-up
            for dir in sourceDirs.sorted(by: { $0.path > $1.path }) {
                try? FileManager.default.removeItem(at: dir)
            }
            operationCompletedFiles = total
            operationBytesCopied = totalBytes
            operationLabel = progressLabel(for: "Done", at: total, of: total)
            operationProgress = 1
        case .delete(let sources):
            // Expand directories into flat file list
            var allFiles: [URL] = []
            for src in sources {
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: src.path, isDirectory: &isDir) else { continue }
                if isDir.boolValue {
                    let tree = await fileService.collectFileTree(at: src)
                    allFiles.append(contentsOf: tree.map(\.url))
                } else {
                    allFiles.append(src)
                }
            }
            let total = allFiles.count
            operationTotalFiles = total
            operationLabel = "Scanning…"
            operationTotalBytes = 0
            for (i, url) in allFiles.enumerated() {
                try Task.checkCancellation()
                operationCompletedFiles = i
                let fileName = url.lastPathComponent
                operationLabel = progressLabel(for: fileName, at: i, of: total)
                operationProgress = Double(i) / Double(total)
                if isPersistentDelete {
                    try await fileService.delete(urls: [url])
                } else {
                    try await fileService.trash(urls: [url])
                }
            }
            // Remove now-empty source directories
            let sourceDirs = sources.filter { src in
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: src.path, isDirectory: &isDir)
                return isDir.boolValue
            }.sorted(by: { $0.path > $1.path })
            for dir in sourceDirs {
                try? FileManager.default.removeItem(at: dir)
            }
            operationCompletedFiles = total
            operationLabel = progressLabel(for: "Done", at: total, of: total)
            operationProgress = 1
        case .mkdir(let parent):
            let name = commandLineText.isEmpty ? "New Folder" : commandLineText
            try await fileService.createDirectory(at: parent, name: name)
        case .rename(let file):
            try await fileService.rename(file: file, to: commandLineText)
        }
    }

    private func progressLabel(for name: String, at index: Int, of total: Int) -> String {
        let files = "\(index)/\(total) files"
        if operationTotalBytes > 0 {
            let copied = byteString(operationBytesCopied)
            let totalB = byteString(operationTotalBytes)
            return "\(name) · \(files) · \(copied)/\(totalB)"
        }
        return "\(name) · \(files)"
    }

    private func byteString(_ bytes: Int64) -> String {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        return fmt.string(fromByteCount: bytes)
    }

    func showHelp() {
        NSWorkspace.shared.open(URL(string: "https://github.com/zorbas78/zmcdr")!)
    }

    func archiveToZip(file url: URL) {
        Task {
            do {
                try await fileService.archiveToZip(at: url)
                await activePanelViewModel.loadFiles()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func extractArchive(file url: URL) {
        Task {
            do {
                try await fileService.extractArchive(at: url)
                await activePanelViewModel.loadFiles()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func savePanelDirs() {
        UserDefaults.standard.set(leftPanel.currentDirectory.path, forKey: "left_dir")
        UserDefaults.standard.set(rightPanel.currentDirectory.path, forKey: "right_dir")
    }

    func copyDroppedItems(_ urls: [URL], to dest: URL) {
        currentOperation = .copy(sources: urls, destination: dest)
    }

    func quickView() {
        guard let item = activePanelViewModel.filteredFiles[safe: activePanelViewModel.cursorIndex],
              !item.isDirectory
        else { return }
        loadFilePreview(for: item.url)
    }

    func editFile() {
        guard let item = activePanelViewModel.filteredFiles[safe: activePanelViewModel.cursorIndex],
              !item.isDirectory
        else { return }
        if NSWorkspace.shared.urlForApplication(toOpen: item.url) != nil {
            NSWorkspace.shared.open(item.url)
        } else {
            loadFilePreview(for: item.url)
        }
    }

    func loadFilePreview(for url: URL) {
        Task.detached(priority: .userInitiated) { [weak self] in
            let filename = url.lastPathComponent
            let ext = url.pathExtension.lowercased()
            if let uttype = UTType(filenameExtension: ext), uttype.conforms(to: .image) {
                if let image = NSImage(contentsOf: url) {
                    let result = FilePreviewContent(
                        title: filename, text: "", isBinary: false, size: 0, image: image
                    )
                    await MainActor.run {
                        self?.filePreview = result
                        self?.showFilePreview = true
                    }
                    return
                }
            }
            guard let handle = try? FileHandle(forReadingFrom: url) else { return }
            defer { try? handle.close() }
            let maxSize = 1024 * 1024
            let preview = handle.readData(ofLength: maxSize)
            let dataSize = Int64(preview.count)
            let contentText: String
            let isBin: Bool
            if let text = String(data: preview, encoding: .utf8) {
                contentText = text; isBin = false
            } else {
                var hex = ""
                for (i, byte) in preview.enumerated() {
                    if i > 0 && i % 16 == 0 { hex += "\n" }
                    else if i > 0 { hex += " " }
                    hex += String(format: "%02x", byte)
                }
                contentText = hex; isBin = true
            }
            let result = FilePreviewContent(
                title: isBin ? "\(filename) · hex" : filename,
                text: contentText, isBinary: isBin, size: dataSize, image: nil
            )
            await MainActor.run {
                self?.filePreview = result
                self?.showFilePreview = true
            }
        }
    }

    struct FilePreviewContent {
        let title: String
        let text: String
        let isBinary: Bool
        let size: Int64
        let image: NSImage?
    }

    var filesSummary: String {
        let panel = activePanelViewModel
        let total = panel.filteredFiles.count
        let selected = panel.selectedURLs.count
        if selected > 0 {
            return "\(total) items, \(selected) selected"
        }
        return "\(total) items"
    }

    var freeSpaceFormatted: String {
        let free = activePanelViewModel.freeSpace
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        return fmt.string(fromByteCount: free)
    }

    func saveAISettings(provider: AIProvider,
                        ollamaHost: String, ollamaModel: String,
                        openaiHost: String, openaiModel: String, openaiKey: String) {
        aiProvider = provider
        self.ollamaHost = ollamaHost
        self.ollamaModel = ollamaModel
        self.openaiHost = openaiHost
        self.openaiModel = openaiModel
        self.openaiKey = openaiKey
        UserDefaults.standard.set(provider.rawValue, forKey: "ai_provider")
        UserDefaults.standard.set(ollamaHost, forKey: "ollama_host")
        UserDefaults.standard.set(ollamaModel, forKey: "ollama_model")
        UserDefaults.standard.set(openaiHost, forKey: "openai_host")
        UserDefaults.standard.set(openaiModel, forKey: "openai_model")
        KeychainService.save(key: "openai_key", value: openaiKey)
    }

    func runAI() {
        guard !aiPrompt.isEmpty else { return }
        guard validateAISettings() else { return }
        let prompt = aiPrompt
        lastAIPrompt = prompt
        aiPrompt = ""
        aiLoading = true
        aiResult = nil
        aiSafetyCheck = nil
        aiError = nil
        showAIDialog = true

        let provider = aiProvider
        let oHost = ollamaHost
        let oModel = ollamaModel
        let apiHost = openaiHost
        let apiModel = openaiModel
        let apiKey = openaiKey
        let dir = activePanelViewModel.currentDirectory.path
        let fileList = activePanelViewModel.filteredFiles
            .filter { !$0.isParent && !$0.isDirectory }
            .map { "\($0.name)  \($0.formattedSize)  \($0.formattedDate)" }
            .joined(separator: "\n")

        Task {
            do {
                let result = try await aiService.generateAction(
                    prompt: prompt, fileList: fileList, provider: provider,
                    ollamaHost: oHost, ollamaModel: oModel,
                    openaiHost: apiHost, openaiModel: apiModel, openaiKey: apiKey,
                    dir: dir
                )
                aiResult = result
                let (safety, updatedResult) = try await aiService.safetyValidate(
                    result: result, provider: provider,
                    ollamaHost: oHost, ollamaModel: oModel,
                    openaiHost: apiHost, openaiModel: apiModel, openaiKey: apiKey
                )
                aiResult = updatedResult
                aiSafetyCheck = safety
            } catch {
                aiError = error.localizedDescription
            }
            aiLoading = false
        }
    }

    private func validateAISettings() -> Bool {
        switch aiProvider {
        case .ollama:
            if URL(string: ollamaHost) == nil {
                errorMessage = "Configure Ollama host in Settings (Cmd+,)"
                return false
            }
            if ollamaModel.isEmpty {
                errorMessage = "Select an Ollama model in Settings (Cmd+,)"
                return false
            }
        case .openai:
            if URL(string: openaiHost) == nil {
                errorMessage = "Configure API endpoint in Settings (Cmd+,)"
                return false
            }
            if openaiKey.isEmpty {
                errorMessage = "Set your API key in Settings (Cmd+,)"
                return false
            }
            if openaiModel.isEmpty {
                errorMessage = "Select a model in Settings (Cmd+,)"
                return false
            }
        }
        return true
    }

    func closeAIDialog() {
        showAIDialog = false
        aiResult = nil
        aiSafetyCheck = nil
        aiError = nil
        aiLoading = false
    }

    func executeAISelection() {
        guard let names = aiResult?.matchedNames, !names.isEmpty else { return }
        activePanelViewModel.selectFiles(matching: names)
        closeAIDialog()
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
