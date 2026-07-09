import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                DualPanelView()
                StatusBarView()
            }

            if appVM.currentOperation != nil {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                OperationDialogView()
                    .transition(.scale.combined(with: .opacity))
            }

            if appVM.showSettings {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                SettingsView()
                    .transition(.scale.combined(with: .opacity))
            }
            if appVM.showAIPrompt {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                AIPromptView()
                    .transition(.scale.combined(with: .opacity))
            }

            if appVM.showGoto {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                GotoView()
                    .transition(.scale.combined(with: .opacity))
            }

            if appVM.showAIDialog {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                AIDialogView()
                    .transition(.scale.combined(with: .opacity))
            }

            if appVM.overwriteInfo != nil {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                OverwriteDialogView()
                    .transition(.scale.combined(with: .opacity))
            }

            if appVM.showFilePreview {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                FilePreviewView()
                    .transition(.scale.combined(with: .opacity))
            }

            if let msg = appVM.errorMessage, !msg.isEmpty {
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)

                ErrorOverlayView()
                    .transition(.scale.combined(with: .opacity))
            }

            if appVM.showSplash {
                Color.black.opacity(0.85)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 12) {
                    if let icon = NSImage(named: "splash") {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 512, height: 512)
                    }
                    Text("Made with <3 and AI by zorbas78")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
            }
        }
        .background(appVM.themeColors.background)
        .font(appVM.themeFont)
        .animation(.easeInOut(duration: 0.15), value: appVM.currentOperation != nil)
        .animation(.easeInOut(duration: 0.15), value: appVM.showSettings)
        .animation(.easeInOut(duration: 0.15), value: appVM.showAIPrompt)
        .animation(.easeInOut(duration: 0.15), value: appVM.showGoto)
        .animation(.easeInOut(duration: 0.15), value: appVM.showAIDialog)
        .animation(.easeInOut(duration: 0.15), value: appVM.overwriteInfo != nil)
        .animation(.easeInOut(duration: 0.15), value: appVM.showFilePreview)
        .animation(.easeInOut(duration: 0.15), value: appVM.errorMessage ?? "")
        .animation(.easeInOut(duration: 0.4), value: appVM.showSplash)
        .frame(minWidth: 720, minHeight: 400)
    }
}
