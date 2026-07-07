import SwiftUI

struct DualPanelView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        HSplitView {
            PanelView(panel: .left)
                .layoutPriority(1)
            PanelView(panel: .right)
                .layoutPriority(1)
        }
    }
}
