import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var appVM

    @State private var provider: AIProvider = .ollama
    @State private var ollamaHost: String = ""
    @State private var ollamaModel: String = ""
    @State private var openaiHost: String = ""
    @State private var openaiModel: String = ""
    @State private var openaiKey: String = ""

    @State private var testMessage: String = ""
    @State private var testResult: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .foregroundColor(appVM.themeColors.dialogTitle)
                Text("AI Configuration")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(appVM.themeColors.dialogTitle)
            }

            Picker("Provider", selection: $provider) {
                ForEach(AIProvider.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Divider()

            switch provider {
            case .ollama:
                ollamaFields
            case .openai:
                openaiFields
            }

            Spacer().frame(height: 8)

            HStack {
                Button("Test Connection") {
                    testMessage = "Testing…"
                    testResult = nil
                    Task {
                        do {
                            let msg = try await AIService().testConnection(
                                provider: provider,
                                ollamaHost: ollamaHost, ollamaModel: ollamaModel,
                                openaiHost: openaiHost, openaiModel: openaiModel, openaiKey: openaiKey
                            )
                            testMessage = msg
                            testResult = true
                        } catch {
                            testMessage = error.localizedDescription
                            testResult = false
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if let ok = testResult {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(ok ? .green : .red)
                    Text(testMessage)
                        .font(.system(size: 11))
                        .foregroundColor(ok ? .green : .red)
                } else if !testMessage.isEmpty {
                    ProgressView().scaleEffect(0.6)
                }
            }

            Spacer().frame(height: 8)

            HStack {
                Spacer()
                Button("Cancel") {
                    appVM.showSettings = false
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    appVM.saveAISettings(
                        provider: provider,
                        ollamaHost: ollamaHost, ollamaModel: ollamaModel,
                        openaiHost: openaiHost, openaiModel: openaiModel, openaiKey: openaiKey
                    )
                    appVM.showSettings = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 440)
        .background(appVM.themeColors.dialogBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appVM.themeColors.panelBorder.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            provider = appVM.aiProvider
            ollamaHost = appVM.ollamaHost
            ollamaModel = appVM.ollamaModel
            openaiHost = appVM.openaiHost
            openaiModel = appVM.openaiModel
            openaiKey = appVM.openaiKey
        }
    }

    private var ollamaFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Host URL").labelText(appVM)
                TextField("http://localhost:11434", text: $ollamaHost)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Model").labelText(appVM)
                TextField("llama3.2, mistral, codellama…", text: $ollamaModel)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var openaiFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Endpoint").labelText(appVM)
                TextField("https://api.deepseek.com", text: $openaiHost)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("API Key").labelText(appVM)
                SecureField("sk-…", text: $openaiKey)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Model").labelText(appVM)
                TextField("deepseek-chat, gpt-4o-mini…", text: $openaiModel)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

private extension Text {
    @MainActor
    func labelText(_ appVM: AppViewModel) -> some View {
        self.font(appVM.themeFont.weight(.semibold))
            .foregroundColor(appVM.themeColors.dialogTitle)
    }
}
