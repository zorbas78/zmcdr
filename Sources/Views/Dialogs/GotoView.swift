import SwiftUI

struct GotoView: View {
    @Environment(AppViewModel.self) private var appVM
    @FocusState private var pathFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.doc.on.clipboard")
                    .foregroundColor(appVM.themeColors.dialogTitle)
                Text("Go to folder")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(appVM.themeColors.dialogTitle)
            }

            Text("Enter a full path to navigate to.")
                .font(.system(size: 11))
                .foregroundColor(appVM.themeColors.dimText)

            TextField("Path…", text: Binding(
                get: { appVM.gotoPath },
                set: { appVM.gotoPath = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.system(.body))
            .focused($pathFocused)
            .onSubmit { appVM.executeGoto() }

            HStack {
                Spacer()
                Button("Cancel") {
                    appVM.showGoto = false
                }
                .keyboardShortcut(.escape)

                Button("Go") {
                    appVM.executeGoto()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(appVM.gotoPath.trimmingCharacters(in: .whitespaces).isEmpty)
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
                pathFocused = true
            }
        }
    }
}
