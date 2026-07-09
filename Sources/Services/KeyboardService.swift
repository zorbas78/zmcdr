import SwiftUI
import AppKit

final class KeyboardService {
    private var monitor: Any?
    private var rightClickMonitor: Any?
    private weak var appVM: AppViewModel?

    func startMonitoring(appVM: AppViewModel) {
        self.appVM = appVM

        let mask: NSEvent.EventTypeMask = .keyDown
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            guard let self, let vm = self.appVM else { return event }

            let handled = MainActor.assumeIsolated {
                vm.handleKeyEvent(event)
            }
            return handled ? nil : event
        }

        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self, let vm = self.appVM else { return event }
            self.handleRightClick(event, appVM: vm)
            return event
        }
    }

    func stopMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let rightClickMonitor { NSEvent.removeMonitor(rightClickMonitor) }
        monitor = nil
        rightClickMonitor = nil
    }

    deinit {
        stopMonitoring()
    }

    private func handleRightClick(_ event: NSEvent, appVM: AppViewModel) {
        guard let window = event.window, let contentView = window.contentView else { return }
        let point = contentView.convert(event.locationInWindow, from: nil)
        guard let hitView = contentView.hitTest(point) else { return }

        var current: NSView? = hitView
        while let view = current {
            if let row = view as? PanelRowView {
                MainActor.assumeIsolated {
                    if row.panelPosition == .left {
                        appVM.activePanel = .left
                        appVM.leftPanel.cursorIndex = row.panelIndex
                    } else {
                        appVM.activePanel = .right
                        appVM.rightPanel.cursorIndex = row.panelIndex
                    }
                }
                return
            }
            current = view.superview
        }
    }
}

// Key code constants
enum KeyCodes: UInt16 {
    case f1 = 122
    case f2 = 120
    case f3 = 99
    case f4 = 118
    case f5 = 96
    case f6 = 97
    case f7 = 98
    case f8 = 100
    case f9 = 101
    case f10 = 109
    case f11 = 103
    case f12 = 111
    case tab = 48
    case `return` = 36
    case delete = 51
    case escape = 53
    case space = 49

    case up = 126
    case down = 125
    case left = 123
    case right = 124
    case pageUp = 116
    case pageDown = 121
    case home = 115
    case end = 119

    case keyA = 0
    case keyC = 8
    case keyD = 2
    case keyE = 14
    case keyF = 3
    case keyH = 4
    case keyI = 34
    case keyL = 37
    case keyN = 45
    case keyO = 31
    case keyR = 15
    case keyS = 1
    case keyT = 17
    case keyU = 32
    case keyV = 9
    case keyQ = 12
    case keyW = 13
    case keyX = 7

    case keypadPlus = 69
    case keypadMinus = 78
    case keypadMultiply = 67

    case backtick = 50
    case slash = 44
}
