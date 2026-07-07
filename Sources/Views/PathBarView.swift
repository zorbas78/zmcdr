import SwiftUI

struct PathBarView: View {
    let panel: PanelPosition

    @Environment(AppViewModel.self) private var appVM

    private var panelVM: PanelViewModel {
        panel == .left ? appVM.leftPanel : appVM.rightPanel
    }

    var body: some View {
        HStack(spacing: 2) {
            HStack(spacing: 1) {
                Button {
                    panelVM.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(!panelVM.canGoBack)
                .opacity(panelVM.canGoBack ? 1 : 0.3)
                .foregroundColor(appVM.themeColors.pathBarForeground)

                Button {
                    panelVM.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(!panelVM.canGoForward)
                .opacity(panelVM.canGoForward ? 1 : 0.3)
                .foregroundColor(appVM.themeColors.pathBarForeground)
            }
            .padding(.trailing, 4)

            if panel == .left {
                Image(systemName: "folder")
                    .font(.system(size: 10))
                    .foregroundColor(appVM.themeColors.pathBarForeground)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(pathComponents, id: \.self) { component in
                        if component != pathComponents.first {
                            Text("/")
                                .foregroundColor(appVM.themeColors.dimText)
                                .font(appVM.themeFont)
                        }
                        Button(component.name) {
                            panelVM.navigateTo(component.url)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(appVM.themeColors.pathBarForeground)
                        .font(appVM.themeFont)
                        .lineLimit(1)
                        .fixedSize()
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(appVM.themeColors.pathBarBackground)
    }

    private struct PathComponent: Hashable {
        let name: String
        let url: URL
    }

    private var pathComponents: [PathComponent] {
        var current = panelVM.currentDirectory
        let home = FileManager.default.homeDirectoryForCurrentUser

        // Build from root to leaf
        var parts: [(String, URL)] = []
        while current.path != "/" {
            let name: String
            if current == home {
                name = "~"
            } else {
                name = current.lastPathComponent
            }
            parts.insert((name, current), at: 0)
            current = current.deletingLastPathComponent()
        }
        parts.insert(("/", URL(fileURLWithPath: "/")), at: 0)

        return parts.map { PathComponent(name: $0.0, url: $0.1) }
    }
}
