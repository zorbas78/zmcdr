import SwiftUI

struct OperationDialogView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var dirName: String = ""
    @State private var renameText: String = ""
    @FocusState private var mkdirFocused: Bool
    @FocusState private var renameFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            switch appVM.currentOperation {
            case .copy(let sources, let dest):
                copyMoveContent(title: "Copy", sources: sources, dest: dest, icon: "doc.on.doc")
            case .move(let sources, let dest):
                copyMoveContent(title: "Move", sources: sources, dest: dest, icon: "arrow.right.doc.on.doc")
            case .delete(let sources):
                deleteContent(sources: sources)
            case .mkdir(let parent):
                mkdirContent(parent: parent)
            case .rename(let file):
                renameContent(file: file)
            case nil:
                EmptyView()
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(appVM.themeColors.dialogBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appVM.themeColors.panelBorder.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Copy / Move

    private func copyMoveContent(title: String, sources: [URL], dest: URL, icon: String) -> some View {
        let running = appVM.operationRunning
        return VStack(alignment: .leading, spacing: 12) {
            dialogHeader(title: title, icon: icon)

            if running {
                VStack(spacing: 8) {
                    Text(appVM.operationLabel)
                        .font(appVM.themeFont)
                        .foregroundColor(appVM.themeColors.dialogText)
                        .lineLimit(1)
                    ProgressView(value: appVM.operationProgress)
                        .progressViewStyle(.linear)
                }
            } else {
                Group {
                    Text("Source:")
                        .sectionTitle(appVM)
                    ForEach(sources, id: \.self) { url in
                        Text(url.lastPathComponent)
                            .font(appVM.themeFont)
                            .foregroundColor(appVM.themeColors.dialogText)
                            .padding(.leading, 8)
                    }

                    Text("Destination:")
                        .sectionTitle(appVM)
                    Text(dest.path)
                        .font(appVM.themeFont)
                        .foregroundColor(appVM.themeColors.dialogText)
                        .padding(.leading, 8)
                }
            }

            Spacer()
            dialogButtons(onOK: { appVM.executeCurrentOperation() })
                .disabled(running)
        }
    }

    // MARK: - Delete

    private func deleteContent(sources: [URL]) -> some View {
        let running = appVM.operationRunning
        return VStack(alignment: .leading, spacing: 12) {
            dialogHeader(title: "Delete", icon: "trash")

            if running {
                VStack(spacing: 8) {
                    Text(appVM.operationLabel)
                        .font(appVM.themeFont)
                        .foregroundColor(appVM.themeColors.dialogText)
                        .lineLimit(1)
                    ProgressView(value: appVM.operationProgress)
                        .progressViewStyle(.linear)
                }
            } else {
                Text("Delete \(sources.count) item\(sources.count != 1 ? "s" : "")?")
                    .font(appVM.themeFont)
                    .foregroundColor(appVM.themeColors.dialogText)

                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(sources, id: \.self) { url in
                            Text(url.lastPathComponent)
                                .font(appVM.themeFont)
                                .foregroundColor(appVM.themeColors.dimText)
                        }
                    }
                }
                .frame(maxHeight: 120)

                Toggle(isOn: .init(
                    get: { appVM.isPersistentDelete },
                    set: { appVM.isPersistentDelete = $0 }
                )) {
                    Text("Permanently delete (skip Trash)")
                        .font(appVM.themeFont)
                        .foregroundColor(appVM.themeColors.dialogText)
                }
                .toggleStyle(.checkbox)
            }

            Spacer()
            dialogButtons(
                okLabel: "Delete",
                onOK: { appVM.executeCurrentOperation() }
            )
            .disabled(running)
        }
    }

    // MARK: - Mkdir

    private func mkdirContent(parent: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            dialogHeader(title: "Create Directory", icon: "folder.badge.plus")

            Text("Create in: \(parent.path)")
                .font(appVM.themeFont)
                .foregroundColor(appVM.themeColors.dimText)

            TextField("Directory name", text: $dirName)
                .textFieldStyle(.roundedBorder)
                .font(appVM.themeFont)
                .focused($mkdirFocused)
                .onAppear {
                    dirName = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { mkdirFocused = true }
                }

            Spacer()
            dialogButtons(onOK: {
                guard !dirName.isEmpty else { return }
                appVM.commandLineText = dirName
                appVM.executeCurrentOperation()
            })
        }
    }

    // MARK: - Rename

    private func renameContent(file: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            dialogHeader(title: "Rename", icon: "pencil")

            Text("Current: \(file.lastPathComponent)")
                .font(appVM.themeFont)
                .foregroundColor(appVM.themeColors.dimText)

            TextField("New name", text: $renameText)
                .textFieldStyle(.roundedBorder)
                .font(appVM.themeFont)
                .focused($renameFocused)
                .onAppear {
                    renameText = file.lastPathComponent
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { renameFocused = true }
                }

            Spacer()
            dialogButtons(onOK: {
                let clean = (renameText as NSString).lastPathComponent.trimmingCharacters(in: .whitespaces)
                guard !clean.isEmpty else { return }
                if clean == file.lastPathComponent {
                    appVM.cancelOperation()
                    return
                }
                appVM.commandLineText = clean
                appVM.executeCurrentOperation()
            })
        }
    }

    // MARK: - Shared components

    private func dialogHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(appVM.themeColors.dialogTitle)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(appVM.themeColors.dialogTitle)
        }
    }

    private func dialogButtons(okLabel: String = "OK", onOK: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button("Cancel") {
                appVM.cancelOperation()
            }
            .keyboardShortcut(.escape)

            Button(okLabel) {
                onOK()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
    }
}

private extension Text {
    @MainActor
    func sectionTitle(_ appVM: AppViewModel) -> Text {
        self.font(appVM.themeFont.weight(.semibold))
            .foregroundColor(appVM.themeColors.dialogTitle)
    }
}

extension View {
    @MainActor
    func sectionTitle(_ appVM: AppViewModel) -> some View {
        self.font(appVM.themeFont.weight(.semibold))
            .foregroundColor(appVM.themeColors.dialogTitle)
    }
}
