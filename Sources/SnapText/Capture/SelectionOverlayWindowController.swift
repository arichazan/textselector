import AppKit

enum SelectionOutcome {
    case cancelled
    case selected(rect: CGRect, screen: NSScreen)
}

final class SelectionOverlayWindowController {
    private var windows: [NSWindow] = []
    private var completion: ((SelectionOutcome) -> Void)?
    private var monitors: [Any] = []
    private var cursorTimer: Timer?

    func beginSelection(completion: @escaping (SelectionOutcome) -> Void) {
        guard windows.isEmpty else { return }
        self.completion = completion

        // Start cursor forcing immediately before creating windows
        startCursorForcing()

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
            }
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        // Cursor forcing already started in beginSelection()
    }

    private func installMonitors() {
        if let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] event in
            if event.keyCode == 53 { // escape key
                self?.finish(with: .cancelled)
                return nil
            }
            return event
        }) {
            monitors.append(keyMonitor)
        }

        if let globalRightClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown, handler: { [weak self] _ in
            self?.finish(with: .cancelled)
        }) {
            monitors.append(globalRightClickMonitor)
        }
    }

    private func startCursorForcing() {
        // Force crosshair cursor immediately
        NSCursor.crosshair.set()

        // Set up timer to continuously force crosshair cursor
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            NSCursor.crosshair.set()
        }
    }

    private func stopCursorForcing() {
        cursorTimer?.invalidate()
        cursorTimer = nil
    }

    private func tearDown() {
        // Stop cursor forcing and restore normal cursor
        stopCursorForcing()
        NSCursor.arrow.set()

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
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        ignoresMouseEvents = false
        backgroundColor = .clear
        isOpaque = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = SelectionOverlayView(frame: screen.frame)

        // Make this window accept cursor updates
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
        wantsLayer = false  // Don't use layer-backed view
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .cursorUpdate, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseEntered(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateTrackingAreas()
        NSCursor.crosshair.set()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            updateTrackingAreas()
            NSCursor.crosshair.set()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let selectionRect {
            // Create the overlay effect: darken everything except the selection
            let overlayPath = NSBezierPath(rect: bounds)
            overlayPath.append(NSBezierPath(rect: selectionRect).reversed)

            NSColor.black.withAlphaComponent(0.3).setFill()
            overlayPath.fill()

            // Draw the selection border like macOS ⌘⇧4
            let borderPath = NSBezierPath(rect: selectionRect)
            borderPath.lineWidth = 1.0

            // White border
            NSColor.white.setStroke()
            borderPath.stroke()

            // Draw corner handles like macOS
            drawCornerHandles(in: selectionRect)

            // Draw size info if selection is reasonably sized
            if selectionRect.width > 50 && selectionRect.height > 30 {
                drawSizeInfo(for: selectionRect)
            }
        } else {
            // No selection yet - darken entire screen
            NSColor.black.withAlphaComponent(0.3).setFill()
            bounds.fill()
        }
    }

    private func drawCornerHandles(in rect: CGRect) {
        let handleSize: CGFloat = 8.0
        let handleOffset: CGFloat = handleSize / 2

        let corners = [
            CGPoint(x: rect.minX - handleOffset, y: rect.minY - handleOffset), // Bottom-left
            CGPoint(x: rect.maxX - handleOffset, y: rect.minY - handleOffset), // Bottom-right
            CGPoint(x: rect.minX - handleOffset, y: rect.maxY - handleOffset), // Top-left
            CGPoint(x: rect.maxX - handleOffset, y: rect.maxY - handleOffset)  // Top-right
        ]

        for corner in corners {
            let handleRect = CGRect(x: corner.x, y: corner.y, width: handleSize, height: handleSize)
            let handlePath = NSBezierPath(ovalIn: handleRect)

            // Fill with white
            NSColor.white.setFill()
            handlePath.fill()

            // Border with slight gray
            NSColor.lightGray.setStroke()
            handlePath.lineWidth = 0.5
            handlePath.stroke()
        }
    }

    private func drawSizeInfo(for rect: CGRect) {
        let sizeText = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]

        let attributedString = NSAttributedString(string: sizeText, attributes: attributes)
        let textSize = attributedString.size()

        // Position the text below the selection, or above if not enough space
        var textRect = CGRect(
            x: rect.minX,
            y: rect.minY - textSize.height - 4,
            width: textSize.width + 8,
            height: textSize.height + 4
        )

        // If text would go off screen, position it above the selection
        if textRect.minY < 0 {
            textRect.origin.y = rect.maxY + 4
        }

        // Draw background
        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: textRect, xRadius: 3, yRadius: 3).fill()

        // Draw text
        attributedString.draw(at: CGPoint(x: textRect.minX + 4, y: textRect.minY + 2))
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
}
