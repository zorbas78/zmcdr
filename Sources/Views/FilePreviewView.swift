import SwiftUI

struct FilePreviewView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appVM.filePreview?.title ?? "Preview")
                        .font(.headline)
                        .foregroundColor(appVM.themeColors.dialogTitle)
                    if let size = appVM.filePreview?.size, size > 0 {
                        Text(ByteCountFormatter().string(fromByteCount: size))
                            .font(.caption)
                            .foregroundColor(appVM.themeColors.dimText)
                    }
                }
                Spacer()
                Button("Close") {
                    appVM.showFilePreview = false
                }
                .keyboardShortcut(.escape)
            }

            if let image = appVM.filePreview?.image {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 800, maxHeight: 600)
                }
                .background(Color.black.opacity(0.15))
                .cornerRadius(6)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Text(appVM.filePreview?.text ?? "")
                        .font(.custom(appVM.filePreview?.isBinary == true ? "Menlo" : "Monaco", size: 12))
                        .foregroundColor(appVM.themeColors.dialogText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .background(Color.black.opacity(0.15))
                .cornerRadius(6)
            }
        }
        .padding(24)
        .frame(width: 720, height: 520)
        .background(appVM.themeColors.dialogBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appVM.themeColors.panelBorder.opacity(0.3), lineWidth: 1)
        )
    }
}
