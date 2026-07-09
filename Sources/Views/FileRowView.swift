import SwiftUI

// MARK: - Right-click cursor setter

struct RightClickCursorSetter: NSViewRepresentable {
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        RightClickView(onRightClick: onRightClick)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class RightClickView: NSView {
    let onRightClick: () -> Void

    init(onRightClick: @escaping () -> Void) {
        self.onRightClick = onRightClick
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick()
        super.rightMouseDown(with: event)
    }
}

// MARK: - FileRowView

struct FileRowView: View {
    let file: FileItem
    let isCursor: Bool
    let isSelected: Bool
    let panel: PanelPosition
    let index: Int

    @Environment(AppViewModel.self) private var appVM

    private var panelVM: PanelViewModel {
        panel == .left ? appVM.leftPanel : appVM.rightPanel
    }

    var body: some View {
        HStack(spacing: 0) {
            nameColumn
            Divider()
            sizeColumn
            Divider()
            dateColumn
            Divider()
            permsColumn
        }
        .frame(minHeight: 20)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(backgroundColor)
        .contentShape(Rectangle())
        .background(
            RightClickCursorSetter {
                appVM.activePanel = panel
                panelVM.cursorIndex = index
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
        .overlay {
            if isCursor && appVM.activePanel == panel {
                Rectangle()
                    .strokeBorder(appVM.themeColors.cursorBorder, lineWidth: 2)
                    .padding(2)
            }
        }
        .gesture(TapGesture().onEnded {
            appVM.activePanel = panel
            panelVM.cursorIndex = index
        })
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            panelVM.enterCurrent()
        })
        .contextMenu {
            Button("Archive to Zip") {
                appVM.archiveToZip(file: file.url)
            }
            if file.extension.lowercased() == "zip" {
                Button("Extract Here") {
                    appVM.extractArchive(file: file.url)
                }
            }
            if FileService.imageExtensions.contains(file.extension.lowercased()) {
                Divider()
                Button("Preview") {
                    appVM.loadFilePreview(for: file.url)
                }
                Button("Share") {
                    let picker = NSSharingServicePicker(items: [file.url])
                    if let window = NSApp.keyWindow, let view = window.contentView {
                        picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
                    }
                }
            }
            Divider()
            Button("Copy") {
                appVM.copyFileToClipboard(url: file.url)
            }
            Button("Cut") {
                appVM.cutFileToClipboard(url: file.url)
            }
            if appVM.hasClipboardContent {
                if file.isDirectory && file.name != ".." {
                    Button("Paste into Folder") {
                        appVM.pasteFromClipboard(to: file.url)
                    }
                } else {
                    Button("Paste") {
                        appVM.pasteFromClipboard()
                    }
                }
            }
        }
        .onDrag {
            NSItemProvider(object: file.url as NSURL)
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return appVM.themeColors.selectedBackground
        }
        if isCursor {
            return appVM.themeColors.cursorLine
        }
        return Color.clear
    }

    private var foregroundColor: Color {
        if isSelected {
            return appVM.themeColors.selectionForeground
        }
        if file.isSymlink {
            return appVM.themeColors.linkForeground
        }
        if file.isDirectory {
            return appVM.themeColors.directoryForeground
        }
        return appVM.themeColors.fileForeground
    }

    // MARK: - Columns

    private var nameColumn: some View {
        HStack(spacing: 5) {
            if let icon = file.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
            }

            Text(file.name)
                .lineLimit(1)
                .foregroundColor(foregroundColor)
                .font(appVM.themeFont.weight(file.isDirectory ? .semibold : .regular))

            if file.isSymlink {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 9))
                    .foregroundColor(appVM.themeColors.linkForeground)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displaySize: String {
        if file.isDirectory, let calc = panelVM.calculatedSizes[file.url] {
            let fmt = ByteCountFormatter()
            fmt.countStyle = .file
            return fmt.string(fromByteCount: calc)
        }
        return file.formattedSize
    }

    private var sizeColumn: some View {
        Text(displaySize)
            .lineLimit(1)
            .font(appVM.themeFont.monospacedDigit())
            .foregroundColor(file.isDirectory ? appVM.themeColors.dimText : foregroundColor)
            .frame(width: 80, alignment: .trailing)
    }

    private var dateColumn: some View {
        Text(file.formattedDate)
            .lineLimit(1)
            .font(appVM.themeFont)
            .foregroundColor(foregroundColor)
            .frame(width: 140, alignment: .leading)
    }

    private var permsColumn: some View {
        Text(file.permissions)
            .lineLimit(1)
            .font(.custom("Menlo", size: 11))
            .foregroundColor(appVM.themeColors.dimText)
            .frame(width: 90, alignment: .center)
    }
}
