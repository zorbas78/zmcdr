import Foundation
import SwiftUI

struct FileItem: Identifiable, Hashable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let isSymlink: Bool
    let isPackage: Bool
    let size: Int64
    let modificationDate: Date
    let creationDate: Date
    let isHidden: Bool
    let permissions: String
    let icon: NSImage?

    var id: URL { url }
    var `extension`: String { url.pathExtension }
    var isParent: Bool { name == ".." }

    private init(
        url: URL, name: String, isDirectory: Bool, isSymlink: Bool, isPackage: Bool,
        size: Int64, modificationDate: Date, creationDate: Date, isHidden: Bool,
        permissions: String, icon: NSImage?
    ) {
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.isSymlink = isSymlink
        self.isPackage = isPackage
        self.size = size
        self.modificationDate = modificationDate
        self.creationDate = creationDate
        self.isHidden = isHidden
        self.permissions = permissions
        self.icon = icon
    }

    init?(url: URL) {
        guard url.isFileURL else { return nil }
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return nil }

        let dir = isDir.boolValue
        let attrs = try? fm.attributesOfItem(atPath: url.path)
        let symlink = (attrs?[.type] as? FileAttributeType) == .typeSymbolicLink
        let pkg = (try? url.resourceValues(forKeys: [.isPackageKey]).isPackage) ?? false
        let fileSize = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        let modDate = (attrs?[.modificationDate] as? Date) ?? Date()
        let creatDate = (attrs?[.creationDate] as? Date) ?? Date()
        let hidden = (try? url.resourceValues(forKeys: [.isHiddenKey]).isHidden)
            ?? url.lastPathComponent.hasPrefix(".")

        var perms = "---------"
        if let p = (attrs?[.posixPermissions] as? NSNumber)?.int16Value {
            var s = ""
            s += (p & 0o400) != 0 ? "r" : "-"
            s += (p & 0o200) != 0 ? "w" : "-"
            s += (p & 0o100) != 0 ? (symlink ? "l" : "x") : "-"
            s += (p & 0o040) != 0 ? "r" : "-"
            s += (p & 0o020) != 0 ? "w" : "-"
            s += (p & 0o010) != 0 ? (symlink ? "l" : "x") : "-"
            s += (p & 0o004) != 0 ? "r" : "-"
            s += (p & 0o002) != 0 ? "w" : "-"
            s += (p & 0o001) != 0 ? (symlink ? "l" : "x") : "-"
            perms = s
        }

        self.init(
            url: url, name: url.lastPathComponent,
            isDirectory: dir, isSymlink: symlink, isPackage: pkg,
            size: dir ? -1 : fileSize, modificationDate: modDate,
            creationDate: creatDate, isHidden: hidden,
            permissions: perms, icon: NSWorkspace.shared.icon(forFile: url.path)
        )
    }

    static func parentDirectory(for currentDir: URL) -> FileItem? {
        let parent = currentDir.deletingLastPathComponent().standardized
        guard parent.path != currentDir.standardized.path else { return nil }
        return FileItem(
            url: parent, name: "..", isDirectory: true, isSymlink: false, isPackage: false,
            size: -1, modificationDate: Date(), creationDate: Date(), isHidden: false,
            permissions: "d---------", icon: NSWorkspace.shared.icon(forFile: parent.path)
        )
    }

    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    var formattedSize: String {
        guard !isDirectory else { return "<DIR>" }
        if size < 1024 { return "\(size) B" }
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        return fmt.string(fromByteCount: size)
    }

    var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        return fmt.string(from: modificationDate)
    }
}
