import Foundation

actor FileService {
    private let fm = FileManager.default

    static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp", "ico"]
    static let textExtensions: Set<String> = ["txt", "md", "swift", "py", "js", "ts", "html", "css", "json", "xml", "yaml", "yml", "toml", "csv", "log", "sh", "zsh", "bash", "plist", "strings", "conf", "ini", "cfg", "env", "gitignore"]
    static let archiveExtensions: Set<String> = ["zip", "tar", "gz", "bz2", "xz", "7z", "rar"]

    func listFiles(at url: URL, showHidden: Bool) throws -> [FileItem] {
        guard url.isFileURL else { return [] }
        let keys: [URLResourceKey] = [
            .isDirectoryKey, .isSymbolicLinkKey, .isPackageKey,
            .fileSizeKey, .contentModificationDateKey,
            .creationDateKey, .isHiddenKey, .localizedNameKey
        ]
        let contents = try fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: .skipsPackageDescendants
        )
        var items: [FileItem] = []
        for child in contents {
            let hidden = (try? child.resourceValues(forKeys: [.isHiddenKey]).isHidden) ?? false
            if !showHidden && hidden { continue }
            guard let item = FileItem(url: child) else { continue }
            items.append(item)
        }
        return items
    }

    func collectFileTree(at url: URL) -> [(url: URL, relativePath: String)] {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else { return [] }
        var result: [(URL, String)] = []
        for case let fileURL as URL in enumerator {
            guard let attrs = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  attrs.isDirectory == false
            else { continue }
            let relative = fileURL.path.replacingOccurrences(of: url.path + "/", with: "")
            result.append((fileURL, relative))
        }
        return result
    }

    func collectFileInfo(at url: URL) -> (files: Int, bytes: Int64) {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else { return (0, 0) }
        var files = 0
        var bytes: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let attrs = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey]),
                  attrs.isDirectory == false,
                  let size = attrs.fileSize
            else { continue }
            files += 1
            bytes += Int64(size)
        }
        return (files, bytes)
    }

    func copyFile(at src: URL, to dest: URL, overwrite: Bool = true) throws {
        try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        if overwrite && fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.copyItem(at: src, to: dest)
    }

    func moveFile(at src: URL, to dest: URL, overwrite: Bool = true) throws {
        try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        if overwrite && fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.moveItem(at: src, to: dest)
    }

    func copy(sources: [URL], to destDir: URL, overwrite: Bool) throws {
        for src in sources {
            let dest = destDir.appendingPathComponent(src.lastPathComponent)
            if fm.fileExists(atPath: dest.path) {
                if overwrite {
                    try fm.removeItem(at: dest)
                } else {
                    throw FileError.fileExists(dest.lastPathComponent)
                }
            }
            try fm.copyItem(at: src, to: dest)
        }
    }

    func move(sources: [URL], to destDir: URL, overwrite: Bool) throws {
        for src in sources {
            let dest = destDir.appendingPathComponent(src.lastPathComponent)
            if fm.fileExists(atPath: dest.path) {
                if overwrite {
                    try fm.removeItem(at: dest)
                } else {
                    throw FileError.fileExists(dest.lastPathComponent)
                }
            }
            try fm.moveItem(at: src, to: dest)
        }
    }

    func trash(urls: [URL]) throws {
        for url in urls {
            try fm.trashItem(at: url, resultingItemURL: nil)
        }
    }

    func delete(urls: [URL]) throws {
        for url in urls {
            try fm.removeItem(at: url)
        }
    }

    func createDirectory(at parent: URL, name: String) throws {
        let dir = parent.appendingPathComponent(name)
        try fm.createDirectory(at: dir, withIntermediateDirectories: false)
    }

    func rename(file: URL, to newName: String) throws {
        let dest = file.deletingLastPathComponent().appendingPathComponent(newName)
        if file.standardizedFileURL.path == dest.standardizedFileURL.path { return }
        if fm.fileExists(atPath: dest.path) {
            throw FileError.fileExists(newName)
        }
        try fm.moveItem(at: file, to: dest)
    }

    func directorySize(at url: URL) -> Int64 {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let attrs = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey]),
                  attrs.isDirectory == false,
                  let size = attrs.fileSize
            else { continue }
            total += Int64(size)
        }
        return total
    }

    func archiveToZip(at url: URL) throws {
        let parent = url.deletingLastPathComponent()
        let zipName = url.lastPathComponent + ".zip"
        let zipURL = parent.appendingPathComponent(zipName)
        if FileManager.default.fileExists(atPath: zipURL.path) {
            try FileManager.default.removeItem(at: zipURL)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--keepParent", url.path, zipURL.path]
        try process.run()
        process.waitUntilExit()
    }

    func extractArchive(at url: URL) throws {
        let parent = url.deletingLastPathComponent()
        let name = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        let dirName = name.hasSuffix(".\(ext)") ? String(name.dropLast(ext.count + 1)) : name
        let dest = parent.appendingPathComponent(dirName)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", url.path, dest.path]
        try process.run()
        process.waitUntilExit()
    }

    func freeSpace(at url: URL) -> Int64 {
        guard let attrs = try? url.resourceValues(forKeys: [.volumeAvailableCapacityKey]),
              let free = attrs.volumeAvailableCapacity
        else { return 0 }
        return Int64(free)
    }
}

enum FileError: LocalizedError {
    case fileExists(String)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileExists(let name):
            return "\(name) already exists"
        case .operationFailed(let msg):
            return msg
        }
    }
}
