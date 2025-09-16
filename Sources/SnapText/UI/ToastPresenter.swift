import AppKit
import SwiftUI

final class ToastPresenter {
    private let settings: UserSettings
    private var window: NSWindow?
    private var hideWorkItem: DispatchWorkItem?

    init(settings: UserSettings) {
        self.settings = settings
    }

    func show(message: String) {
        guard settings.showToast else { return }

        DispatchQueue.main.async {
            self.presentToast(message: message)
        }
    }

    private func presentToast(message: String) {
        let toastView = ToastView(message: message)
        let hostingView = NSHostingView(rootView: toastView)
        let contentSize = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: contentSize)
        let frame = NSRect(origin: .zero, size: contentSize)

        let toastWindow: NSWindow
        if let existing = window {
            toastWindow = existing
        } else {
            toastWindow = NSWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            toastWindow.isOpaque = false
            toastWindow.backgroundColor = .clear
            toastWindow.level = .statusBar
            toastWindow.hasShadow = false
            toastWindow.ignoresMouseEvents = true
            window = toastWindow
        }

        toastWindow.contentView = hostingView
        toastWindow.setContentSize(contentSize)
        position(window: toastWindow, with: contentSize)
        toastWindow.orderFrontRegardless()

        scheduleDismissal()
    }

    private func position(window: NSWindow, with size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let origin = CGPoint(
            x: visibleFrame.maxX - size.width - 24,
            y: visibleFrame.minY + 80
        )
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func scheduleDismissal() {
        hideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.window?.orderOut(nil)
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
}
