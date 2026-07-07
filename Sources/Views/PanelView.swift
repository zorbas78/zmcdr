import SwiftUI

struct PanelView: View {
    let panel: PanelPosition

    @Environment(AppViewModel.self) private var appVM
    @State private var isDropTargeted = false

    private var panelVM: PanelViewModel {
        panel == .left ? appVM.leftPanel : appVM.rightPanel
    }

    private var isActive: Bool {
        appVM.activePanel == panel
    }

    var body: some View {
        VStack(spacing: 0) {
            PathBarView(panel: panel)
                .fixedSize(horizontal: false, vertical: true)

            columnHeaders
                .fixedSize(horizontal: false, vertical: true)

            filterBar
                .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                LazyVStack(spacing: 0) {
                    let files = panelVM.filteredFiles
                    if files.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(files.enumerated()), id: \.element.id) { idx, file in
                            FileRowView(
                                file: file,
                                isCursor: idx == panelVM.cursorIndex,
                                isSelected: panelVM.selectedURLs.contains(file.url),
                                panel: panel,
                                index: idx
                            )
                            .id(file.id)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)

            infoBar
                .fixedSize(horizontal: false, vertical: true)
        }
        .background(appVM.themeColors.panelBackground)
        .overlay(
            Rectangle()
                .fill(isActive ? appVM.themeColors.directoryForeground.opacity(0.5) : .clear)
                .frame(width: 3),
            alignment: .leading
        )
        .overlay(
            isDropTargeted ? Rectangle().stroke(appVM.themeColors.directoryForeground, lineWidth: 2).padding(2) : nil
        )
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            Task {
                var urls: [URL] = []
                for provider in providers {
                    let url = await withCheckedContinuation { continuation in
                        _ = provider.loadObject(ofClass: URL.self) { obj, _ in
                            continuation.resume(returning: obj)
                        }
                    }
                    if let url { urls.append(url) }
                }
                if !urls.isEmpty {
                    appVM.copyDroppedItems(urls, to: panelVM.currentDirectory)
                }
            }
            return true
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            headerButton("Name", criterion: .name)
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            headerButton("Size", criterion: .size)
                .frame(width: 80, alignment: .trailing)
            Divider()
            headerButton("Date", criterion: .date)
                .frame(width: 140, alignment: .leading)
            Divider()
            headerButton("Mode", criterion: nil)
                .frame(width: 90, alignment: .center)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(appVM.themeColors.columnHeaderBackground)
        .foregroundColor(appVM.themeColors.columnHeaderForeground)
        .font(appVM.themeFont.weight(.medium))
    }

    private func headerButton(_ label: String, criterion: SortCriterion?) -> some View {
        Button {
            guard let c = criterion else { return }
            if panelVM.sortBy == c {
                panelVM.sortAscending.toggle()
            } else {
                panelVM.sortBy = c
                panelVM.sortAscending = true
            }
            panelVM.refresh()
        } label: {
            HStack(spacing: 3) {
                Text(label)
                    .lineLimit(1)
                if let c = criterion, panelVM.sortBy == c {
                    Image(systemName: panelVM.sortAscending ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var infoBar: some View {
        HStack {
            if panelVM.isLoading {
                Text("Loading…")
                    .foregroundColor(appVM.themeColors.statusBarForeground)
            } else {
                Text("\(panelVM.itemsCount) item\(panelVM.itemsCount != 1 ? "s" : "")")
                    + Text(panelVM.selectedURLs.isEmpty ? "" : ", \(panelVM.selectedURLs.count) selected")
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .font(appVM.themeFont)
        .foregroundColor(appVM.themeColors.dimText)
        .background(appVM.themeColors.statusBarBackground)
    }

    private var filterBar: some View {
        HStack(spacing: 2) {
            ForEach(FilterPreset.allCases, id: \.self) { preset in
                Button(preset.label) {
                    panelVM.filterPreset = preset
                }
                .buttonStyle(.plain)
                .font(appVM.themeFont.weight(panelVM.filterPreset == preset ? .bold : .regular))
                .foregroundColor(panelVM.filterPreset == preset ? appVM.themeColors.directoryForeground : appVM.themeColors.dimText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(panelVM.filterPreset == preset ? appVM.themeColors.directoryForeground.opacity(0.15) : .clear)
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(appVM.themeColors.columnHeaderBackground.opacity(0.5))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Empty directory")
                .foregroundColor(appVM.themeColors.dimText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
