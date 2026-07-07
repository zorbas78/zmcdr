import Foundation

enum FileOperation: Identifiable {
    case copy(sources: [URL], destination: URL)
    case move(sources: [URL], destination: URL)
    case delete(sources: [URL])
    case mkdir(parent: URL)
    case rename(file: URL)

    var id: String {
        switch self {
        case .copy: return "copy"
        case .move: return "move"
        case .delete: return "delete"
        case .mkdir: return "mkdir"
        case .rename: return "rename"
        }
    }
}
