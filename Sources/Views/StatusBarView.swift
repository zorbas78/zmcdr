import SwiftUI

struct StatusBarView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        HStack(spacing: 0) {
            helpButton("F1", "Help") { appVM.showHelp() }
            helpSeparator
            helpButton("F2", "AI") { appVM.showAIPrompt = true }
            helpSeparator
            helpButton("F3", "Goto") { appVM.beginGoto() }
            helpSeparator
            helpButton("F4", "Edit") { appVM.editFile() }
            helpSeparator
            helpButton("F5", "Copy") { appVM.beginCopy() }
            helpSeparator
            helpButton("F6", "Move") { appVM.beginMove() }
            helpSeparator
            helpButton("F7", "MkDir") { appVM.beginMkdir() }
            helpSeparator
            helpButton("F8", "Del") { appVM.beginDelete() }
            helpSeparator
            helpButton("F9", "Renam") { appVM.beginRename() }
            helpSeparator
            helpButton("F10", "Quit") { NSApplication.shared.terminate(nil) }

            helpSeparator
            Text("Made with <3 and AI by zorbas78")
                .font(.system(size: 9))
                .foregroundColor(appVM.themeColors.dimText)
                .padding(.horizontal, 4)

            Spacer()

            HStack(spacing: 4) {
                Text("\(appVM.activePanelViewModel.itemsCount) items (\(totalSizeFormatted))")
                    .font(appVM.themeFont)
                    .foregroundColor(appVM.themeColors.statusBarForeground)
                let sel = appVM.activePanelViewModel.selectedURLs.count
                if sel > 0 {
                    Text("\(sel) sel")
                        .font(appVM.themeFont)
                        .foregroundColor(appVM.themeColors.selectedBackground)
                }
            }
            .padding(.horizontal, 8)

            Button("AI") {
                appVM.showAIPrompt = true
                appVM.aiPrompt = ""
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 4)

            Text(appVM.freeSpaceFormatted + " free")
                .font(appVM.themeFont)
                .foregroundColor(appVM.themeColors.dimText)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(appVM.themeColors.statusBarBackground)
    }

    private var totalSizeFormatted: String {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        return fmt.string(fromByteCount: appVM.activePanelViewModel.totalSize)
    }

    private func helpButton(_ key: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(key)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(appVM.themeColors.statusBarForeground)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(appVM.themeColors.dimText)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 3)
    }

    private var helpSeparator: some View {
        Text("│")
            .font(.system(size: 10))
            .foregroundColor(appVM.themeColors.dimText)
    }
}
