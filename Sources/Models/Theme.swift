import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case dark = "Dark"
    case amiga12 = "WB 1.2"
    case amiga20 = "WB 2.0"
    case matrix = "Matrix"

    var colors: ThemeColors {
        switch self {
        case .dark: return .dark
        case .amiga12: return .amiga12
        case .amiga20: return .amiga20
        case .matrix: return .matrix
        }
    }

    var font: Font {
        switch self {
        case .amiga12: return .custom("Monaco", size: 12)
        case .amiga20: return .custom("Monaco", size: 12)
        case .matrix: return .custom("Menlo", size: 13)
        case .dark: return .system(size: 13)
        }
    }
}

struct ThemeColors {
    let background: Color
    let panelBackground: Color
    let panelBorder: Color
    let text: Color
    let dimText: Color
    let selectedText: Color
    let selectedBackground: Color
    let directoryForeground: Color
    let fileForeground: Color
    let linkForeground: Color
    let cursorLine: Color
    let cursorBorder: Color
    let statusBarBackground: Color
    let statusBarForeground: Color
    let pathBarBackground: Color
    let pathBarForeground: Color
    let columnHeaderBackground: Color
    let columnHeaderForeground: Color
    let dialogBackground: Color
    let dialogTitle: Color
    let dialogText: Color
    let selectionForeground: Color
}

extension ThemeColors {
    static let dark = ThemeColors(
        background: Color(red: 0.12, green: 0.12, blue: 0.14),
        panelBackground: Color(red: 0.17, green: 0.17, blue: 0.19),
        panelBorder: Color(red: 0.28, green: 0.28, blue: 0.30),
        text: Color(red: 0.92, green: 0.92, blue: 0.95),
        dimText: Color(red: 0.55, green: 0.55, blue: 0.57),
        selectedText: .white,
        selectedBackground: Color(red: 0.22, green: 0.44, blue: 0.73),
        directoryForeground: Color(red: 0.25, green: 0.65, blue: 1.0),
        fileForeground: Color(red: 0.92, green: 0.92, blue: 0.95),
        linkForeground: Color(red: 0.4, green: 0.9, blue: 0.6),
        cursorLine: Color(red: 0.25, green: 0.25, blue: 0.28),
        cursorBorder: .white.opacity(0.6),
        statusBarBackground: Color(red: 0.1, green: 0.1, blue: 0.12),
        statusBarForeground: Color(red: 0.65, green: 0.65, blue: 0.68),
        pathBarBackground: Color(red: 0.14, green: 0.14, blue: 0.16),
        pathBarForeground: Color(red: 0.7, green: 0.7, blue: 0.72),
        columnHeaderBackground: Color(red: 0.13, green: 0.13, blue: 0.15),
        columnHeaderForeground: Color(red: 0.6, green: 0.6, blue: 0.63),
        dialogBackground: Color(red: 0.2, green: 0.2, blue: 0.22),
        dialogTitle: Color(red: 0.92, green: 0.92, blue: 0.95),
        dialogText: Color(red: 0.92, green: 0.92, blue: 0.95),
        selectionForeground: .white
    )

    static let amiga12 = ThemeColors(
        background: Color(red: 0.0, green: 0.0, blue: 0.67),
        panelBackground: Color(red: 0.69, green: 0.69, blue: 0.69),
        panelBorder: .white,
        text: .black,
        dimText: Color(red: 0.4, green: 0.4, blue: 0.4),
        selectedText: .black,
        selectedBackground: Color(red: 1.0, green: 0.53, blue: 0.0),
        directoryForeground: .black,
        fileForeground: .black,
        linkForeground: Color(red: 0.0, green: 0.45, blue: 0.0),
        cursorLine: Color(red: 0.55, green: 0.55, blue: 0.55),
        cursorBorder: .black,
        statusBarBackground: Color(red: 0.0, green: 0.0, blue: 0.53),
        statusBarForeground: .white,
        pathBarBackground: Color(red: 0.0, green: 0.0, blue: 0.67),
        pathBarForeground: .white,
        columnHeaderBackground: Color(red: 0.45, green: 0.45, blue: 0.45),
        columnHeaderForeground: .white,
        dialogBackground: Color(red: 0.65, green: 0.65, blue: 0.65),
        dialogTitle: .white,
        dialogText: .black,
        selectionForeground: .black
    )

    static let amiga20 = ThemeColors(
        background: Color(red: 0.53, green: 0.53, blue: 0.67),
        panelBackground: Color(red: 0.75, green: 0.75, blue: 0.75),
        panelBorder: .white,
        text: .black,
        dimText: Color(red: 0.45, green: 0.45, blue: 0.45),
        selectedText: .white,
        selectedBackground: Color(red: 0.2, green: 0.2, blue: 0.6),
        directoryForeground: .black,
        fileForeground: .black,
        linkForeground: Color(red: 0.0, green: 0.4, blue: 0.0),
        cursorLine: Color(red: 0.6, green: 0.6, blue: 0.6),
        cursorBorder: .black,
        statusBarBackground: Color(red: 0.47, green: 0.47, blue: 0.6),
        statusBarForeground: .white,
        pathBarBackground: Color(red: 0.2, green: 0.2, blue: 0.5),
        pathBarForeground: .white,
        columnHeaderBackground: Color(red: 0.5, green: 0.5, blue: 0.55),
        columnHeaderForeground: .white,
        dialogBackground: Color(red: 0.7, green: 0.7, blue: 0.7),
        dialogTitle: .white,
        dialogText: .black,
        selectionForeground: .white
    )

    static let matrix = ThemeColors(
        background: .black,
        panelBackground: Color(red: 0.02, green: 0.04, blue: 0.02),
        panelBorder: Color(red: 0.0, green: 0.6, blue: 0.0),
        text: Color(red: 0.0, green: 1.0, blue: 0.0),
        dimText: Color(red: 0.0, green: 0.45, blue: 0.0),
        selectedText: Color(red: 0.0, green: 1.0, blue: 0.0),
        selectedBackground: Color(red: 0.0, green: 0.18, blue: 0.0),
        directoryForeground: Color(red: 0.0, green: 1.0, blue: 0.5),
        fileForeground: Color(red: 0.0, green: 1.0, blue: 0.0),
        linkForeground: Color(red: 0.0, green: 0.8, blue: 0.8),
        cursorLine: Color(red: 0.0, green: 0.1, blue: 0.0),
        cursorBorder: Color(red: 0.0, green: 1.0, blue: 0.0),
        statusBarBackground: .black,
        statusBarForeground: Color(red: 0.0, green: 0.7, blue: 0.0),
        pathBarBackground: .black,
        pathBarForeground: Color(red: 0.0, green: 0.7, blue: 0.0),
        columnHeaderBackground: Color(red: 0.0, green: 0.06, blue: 0.0),
        columnHeaderForeground: Color(red: 0.0, green: 0.8, blue: 0.0),
        dialogBackground: Color(red: 0.02, green: 0.05, blue: 0.02),
        dialogTitle: Color(red: 0.0, green: 1.0, blue: 0.0),
        dialogText: Color(red: 0.0, green: 1.0, blue: 0.0),
        selectionForeground: .black
    )
}
