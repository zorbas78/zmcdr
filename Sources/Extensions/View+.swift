import SwiftUI

extension View {
    func whenHovered(_ handler: @escaping (Bool) -> Void) -> some View {
        self.onHover(perform: handler)
    }
}
