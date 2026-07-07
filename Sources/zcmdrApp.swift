import SwiftUI

@main
struct zcmdrApp: App {
    @State private var appVM = AppViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appVM)
                .onAppear {
                    appVM.setupKeyboardShortcuts()
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("File") {
                Button("Exit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q", modifiers: .command)
            }
            CommandMenu("Commands") {
                Button("Copy (F5)") { appVM.beginCopy() }
                Button("Move (F6)") { appVM.beginMove() }
                Button("Make Directory (F7)") { appVM.beginMkdir() }
                Button("Delete (F8)") { appVM.beginDelete() }
                Button("Rename (Shift+F6)") { appVM.beginRename() }
            }
            CommandMenu("View") {
                Button("Toggle Hidden Files") {
                    appVM.activePanelViewModel.showHiddenFiles.toggle()
                    appVM.activePanelViewModel.refresh()
                }
                Divider()
                Button("Refresh") {
                    appVM.activePanelViewModel.refresh()
                    appVM.inactivePanelViewModel.refresh()
                }
            }
            CommandMenu("Theme") {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    Button(t.rawValue) {
                        appVM.theme = t
                    }
                }
            }
            CommandMenu("AI") {
                Button("Ollama Settings…") {
                    appVM.showSettings = true
                }.keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
