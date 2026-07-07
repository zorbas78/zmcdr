import AppKit
import Foundation
import UniformTypeIdentifiers

final class IconService {
    static let shared = IconService()

    private var cache: [URL: NSImage] = [:]

    func icon(for url: URL) -> NSImage {
        if let cached = cache[url] { return cached }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache[url] = icon
        return icon
    }

    func iconForFileType(_ ext: String) -> NSImage {
        let uttype = UTType(filenameExtension: ext) ?? .data
        return NSWorkspace.shared.icon(for: uttype)
    }

    func invalidate(_ url: URL) {
        cache.removeValue(forKey: url)
    }

    func clearCache() {
        cache.removeAll()
    }
}
