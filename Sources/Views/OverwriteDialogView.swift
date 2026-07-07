import SwiftUI

struct OverwriteDialogView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("File already exists")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(appVM.themeColors.dialogTitle)
            }

            if let info = appVM.overwriteInfo {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Source:")
                            .frame(width: 70, alignment: .trailing)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(appVM.themeColors.dimText)
                        Text(info.sourceName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(appVM.themeColors.dialogText)
                    }
                    HStack {
                        Text("")
                            .frame(width: 70)
                        Text("\(ByteCountFormatter().string(fromByteCount: info.sourceSize))  \(info.sourceDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 10))
                            .foregroundColor(appVM.themeColors.dimText)
                    }
                    Divider()
                    HStack {
                        Text("Target:")
                            .frame(width: 70, alignment: .trailing)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(appVM.themeColors.dimText)
                        Text(info.destName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(appVM.themeColors.dialogText)
                    }
                    HStack {
                        Text("")
                            .frame(width: 70)
                        Text("\(ByteCountFormatter().string(fromByteCount: info.destSize))  \(info.destDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 10))
                            .foregroundColor(appVM.themeColors.dimText)
                    }
                }
            }

            if let info = appVM.overwriteInfo, info.remaining > 1 {
                Text("\(info.remaining) more conflicts after this…")
                    .font(.system(size: 10))
                    .foregroundColor(appVM.themeColors.dimText)
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    overwriteButton("Y:Yes", idx: 0, color: .green, action: { appVM.overwriteAnswer(.yes) })
                    overwriteButton("N:No", idx: 1, color: .red, action: { appVM.overwriteAnswer(.no) })
                    overwriteButton("A:All", idx: 2, color: .blue, action: { appVM.overwriteAnswer(.all) })
                }
                HStack(spacing: 8) {
                    overwriteButton("S:Smaller", idx: 3, color: .orange, action: { appVM.overwriteAnswer(.smaller) })
                    overwriteButton("O:Older", idx: 4, color: .orange, action: { appVM.overwriteAnswer(.older) })
                    overwriteButton("D:≠Size", idx: 5, color: .orange, action: { appVM.overwriteAnswer(.diffSize) })
                    overwriteButton("U:None", idx: 6, color: .gray, action: { appVM.overwriteAnswer(.none) })
                }
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(appVM.themeColors.dialogBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appVM.themeColors.panelBorder.opacity(0.3), lineWidth: 1)
        )
    }

    private func overwriteButton(_ label: String, idx: Int, color: Color, action: @escaping () -> Void) -> some View {
        let sel = appVM.overwriteSelectedIndex == idx
        return Button(label) { action() }
            .buttonStyle(.bordered)
            .tint(color)
            .controlSize(.small)
            .font(.system(size: 12, weight: .medium))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(sel ? Color.white.opacity(0.8) : Color.clear, lineWidth: 2)
            )
    }
}
