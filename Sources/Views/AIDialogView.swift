import SwiftUI

struct AIDialogView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var showPrompts = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(appVM.themeColors.dialogTitle)
                    Text("AI File Assistant")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(appVM.themeColors.dialogTitle)
                    Spacer()
                    Text(appVM.aiProvider.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(appVM.themeColors.dimText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(appVM.themeColors.statusBarBackground.opacity(0.5))
                        .cornerRadius(4)
                }

                if let error = appVM.aiError {
                    Text(error)
                        .font(appVM.themeFont)
                        .foregroundColor(.red)
                } else if let result = appVM.aiResult {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(result.description)
                            .font(appVM.themeFont.weight(.medium))
                            .foregroundColor(appVM.themeColors.dialogText)

                        HStack(spacing: 4) {
                            Image(systemName: appVM.aiSafetyCheck?.safe == true
                                ? "checkmark.shield.fill" : "xmark.shield.fill")
                                .foregroundColor(appVM.aiSafetyCheck?.safe == true ? .green : .red)
                            Text(appVM.aiSafetyCheck?.reason ?? "Safety check pending…")
                                .font(.system(size: 11))
                                .foregroundColor(appVM.themeColors.dimText)
                        }

                        if !result.matchedNames.isEmpty {
                            Text("\(result.matchedNames.count) files matched")
                                .font(.system(size: 11))
                                .foregroundColor(appVM.themeColors.dimText)
                        }
                    }

                    DisclosureGroup(isExpanded: $showPrompts) {
                        VStack(alignment: .leading, spacing: 8) {
                            infoBlock("User request", "\"\(appVM.lastAIPrompt)\"")
                            infoBlock("Generation prompt", appVM.aiResult?.generationPrompt ?? "—")
                            infoBlock("Generation response", appVM.aiResult?.raw.prefix(1500).description ?? "—")
                            infoBlock("Safety prompt", appVM.aiResult?.safetyPrompt ?? "—")
                            infoBlock("Safety response", appVM.aiResult?.safetyRaw.prefix(500).description ?? "—")
                        }
                        .padding(.top, 4)
                    } label: {
                        Label("Full log", systemImage: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(appVM.themeColors.dimText)
                    }
                } else if appVM.aiLoading {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.7)
                        Text("Asking LLM…")
                            .font(appVM.themeFont)
                            .foregroundColor(appVM.themeColors.dimText)
                    }
                }

                Spacer().frame(height: 4)

                HStack {
                    Spacer()
                    Button("Close") {
                        appVM.closeAIDialog()
                    }
                    .keyboardShortcut(.escape)

                    if let result = appVM.aiResult,
                       !result.matchedNames.isEmpty,
                       appVM.aiSafetyCheck?.safe == true {
                        Button("Select Files") {
                            appVM.executeAISelection()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(24)
        }
        .scrollIndicators(.visible)
        .frame(minWidth: 400, minHeight: 300)
        .frame(maxWidth: 560, maxHeight: 460)
        .background(appVM.themeColors.dialogBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appVM.themeColors.panelBorder.opacity(0.3), lineWidth: 1)
        )
    }

    private func infoBlock(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(appVM.themeColors.dimText)
            Text(text)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(appVM.themeColors.dimText.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
