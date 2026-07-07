import SwiftUI

struct AIPromptView: View {
    @Environment(AppViewModel.self) private var appVM
    @FocusState private var promptFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(appVM.themeColors.dialogTitle)
                Text("AI File Assistant")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(appVM.themeColors.dialogTitle)
            }

            Text("Ask the AI to find or mark files. Examples:\n\"mark all files larger than 1 MB\"\n\"select all .png files\"\n\"find files modified today\"")
                .font(.system(size: 11))
                .foregroundColor(appVM.themeColors.dimText)
                .lineSpacing(3)

            TextField("Type your request…", text: Binding(
                get: { appVM.aiPrompt },
                set: { appVM.aiPrompt = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.system(.body))
            .focused($promptFocused)
            .onSubmit { submit() }

            HStack {
                Spacer()
                Button("Cancel") {
                    appVM.showAIPrompt = false
                }
                .keyboardShortcut(.escape)

                Button("Send") {
                    submit()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(appVM.aiPrompt.trimmingCharacters(in: .whitespaces).isEmpty)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                promptFocused = true
            }
        }
    }

    private func submit() {
        let prompt = appVM.aiPrompt.trimmingCharacters(in: .whitespaces)
        guard !prompt.isEmpty else { return }
        appVM.runAI()
        appVM.showAIPrompt = false
        appVM.aiPrompt = ""
    }
}
