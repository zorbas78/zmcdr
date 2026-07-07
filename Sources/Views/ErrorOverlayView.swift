import SwiftUI

struct ErrorOverlayView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.orange)
            Text(appVM.errorMessage ?? "")
                .font(.body)
                .foregroundColor(appVM.themeColors.dialogText)
                .multilineTextAlignment(.center)
            Button("OK") {
                appVM.errorMessage = nil
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: 340)
        .background(appVM.themeColors.dialogBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appVM.themeColors.panelBorder.opacity(0.3), lineWidth: 1)
        )
    }
}
