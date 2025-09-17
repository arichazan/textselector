import AppKit

enum SelectionOutcome {
    case cancelled
    case selected(rect: CGRect, screen: NSScreen)
}

final class SelectionOverlayWindowController {
    private var windows: [NSWindow] = []
    private var completion: ((SelectionOutcome) -> Void)?
    private var monitors: [Any] = []

    func beginSelection(completion: @escaping (SelectionOutcome) -> Void) {
        guard windows.isEmpty else { return }
        self.completion = completion
        installMonitors()
        createOverlayWindows()
    }

    private func finish(with outcome: SelectionOutcome) {
        tearDown()
        completion?(outcome)
        completion = nil
    }

    private func createOverlayWindows() {
        for screen in NSScreen.screens {
            let window = SelectionOverlayWindow(screen: screen)
            if let overlayView = window.contentView as? SelectionOverlayView {
                overlayView.onSelectionFinished = { [weak self] rect in
                    let globalRect = window.convertToScreen(rect)
                    self?.finish(with: .selected(rect: globalRect, screen: screen))
                }
                overlayView.onSelectionCancelled = { [weak self] in
                    self?.finish(with: .cancelled)
                }
                window.invalidateCursorRects(for: overlayView)
            }
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
    }

    private func installMonitors() {
        if let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // escape key
                self?.finish(with: .cancelled)
                return nil
            }
            return event
        } {
            monitors.append(keyMonitor)
        }

        if let globalRightClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] _ in
            self?.finish(with: .cancelled)
        } {
            monitors.append(globalRightClickMonitor)
        }
    }

    private func tearDown() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()

        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors.removeAll()
    }
}

private final class SelectionOverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
        isReleasedWhenClosed = false
        ignoresMouseEvents = false
        backgroundColor = .clear
        isOpaque = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = SelectionOverlayView(frame: screen.frame)
        acceptsMouseMovedEvents = true
    }
}

private final class SelectionOverlayView: NSView {
    var onSelectionFinished: ((CGRect) -> Void)?
    var onSelectionCancelled: (() -> Void)?

    private var startPoint: CGPoint?
    private var selectionRect: CGRect? {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let selectionRect {
            let path = NSBezierPath(rect: selectionRect)
            NSColor.controlAccentColor.withAlphaComponent(0.2).setFill()
            path.fill()

            path.lineWidth = 2
            NSColor.white.setStroke()
            path.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        selectionRect = CGRect(origin: startPoint ?? .zero, size: .zero)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPoint else { return }
        let currentPoint = convert(event.locationInWindow, from: nil)
        selectionRect = CGRect(x: min(startPoint.x, currentPoint.x),
                               y: min(startPoint.y, currentPoint.y),
                               width: abs(startPoint.x - currentPoint.x),
                               height: abs(startPoint.y - currentPoint.y))
    }

    override func mouseUp(with event: NSEvent) {
        guard let selectionRect, selectionRect.width > 5, selectionRect.height > 5 else {
            self.selectionRect = nil
            onSelectionCancelled?()
            return
        }
        self.selectionRect = nil
        onSelectionFinished?(selectionRect)
    }

    override func rightMouseDown(with event: NSEvent) {
        selectionRect = nil
        onSelectionCancelled?()
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        discardCursorRects()
        addCursorRect(bounds, cursor: .crosshair)
    }
}
