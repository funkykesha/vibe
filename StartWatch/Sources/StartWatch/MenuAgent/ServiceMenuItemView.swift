import AppKit

final class ServiceMenuItemView: NSView {

    var onOpen: (() -> Void)?
    var onStart: (() -> Void)?
    var onStop: (() -> Void)?
    var onRestart: (() -> Void)?

    private let dotView = NSView()
    private let nameLabel: NSTextField
    private let playStopButton: NSButton
    private let restartButton: NSButton
    private let isRunning: Bool
    private let hasOpenAction: Bool

    static let rowHeight: CGFloat = 28
    static let rowWidth: CGFloat = 280

    init(result: CheckResult) {
        self.isRunning = result.isRunning
        self.hasOpenAction = result.service.open != nil
        self.nameLabel = NSTextField(labelWithString: result.service.name)

        let playStopImage = NSImage(
            systemSymbolName: result.isRunning ? "stop.fill" : "play.fill",
            accessibilityDescription: nil
        )
        playStopButton = NSButton(image: playStopImage ?? NSImage(), target: nil, action: nil)

        let restartImage = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        restartButton = NSButton(image: restartImage ?? NSImage(), target: nil, action: nil)

        super.init(frame: NSRect(x: 0, y: 0, width: Self.rowWidth, height: Self.rowHeight))

        setupViews(result: result)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupViews(result: CheckResult) {
        let dotSize: CGFloat = 10
        let dotY = (Self.rowHeight - dotSize) / 2
        dotView.frame = NSRect(x: 14, y: dotY, width: dotSize, height: dotSize)
        dotView.wantsLayer = true
        dotView.layer?.cornerRadius = dotSize / 2
        dotView.layer?.backgroundColor = (result.isRunning ? NSColor.systemGreen : NSColor.systemRed).cgColor
        addSubview(dotView)

        nameLabel.frame = NSRect(x: 32, y: 5, width: Self.rowWidth - 32 - 60, height: 18)
        nameLabel.font = NSFont.systemFont(ofSize: 13)
        nameLabel.lineBreakMode = .byTruncatingTail
        if hasOpenAction {
            nameLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(nameTapped)))
            nameLabel.toolTip = result.service.open
        }
        addSubview(nameLabel)

        let btnSize: CGFloat = 20
        let btnY = (Self.rowHeight - btnSize) / 2

        restartButton.frame = NSRect(x: Self.rowWidth - 28, y: btnY, width: btnSize, height: btnSize)
        restartButton.bezelStyle = .inline
        restartButton.isBordered = false
        restartButton.target = self
        restartButton.action = #selector(restartTapped)
        restartButton.toolTip = "Перезапустить"
        addSubview(restartButton)

        playStopButton.frame = NSRect(x: Self.rowWidth - 52, y: btnY, width: btnSize, height: btnSize)
        playStopButton.bezelStyle = .inline
        playStopButton.isBordered = false
        playStopButton.target = self
        playStopButton.action = #selector(playStopTapped)
        playStopButton.toolTip = result.isRunning ? "Остановить" : "Запустить"
        addSubview(playStopButton)

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    // MARK: - Drawing

    override func resetCursorRects() {
        super.resetCursorRects()
        if hasOpenAction {
            addCursorRect(nameLabel.frame, cursor: .pointingHand)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        if let item = enclosingMenuItem, item.isHighlighted {
            NSColor.selectedMenuItemColor.setFill()
            nameLabel.textColor = .selectedMenuItemTextColor
        } else {
            NSColor.clear.setFill()
            nameLabel.textColor = .labelColor
        }
        dirtyRect.fill()
    }

    override func mouseEntered(with event: NSEvent) {
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        needsDisplay = true
    }

    // MARK: - Actions

    @objc private func nameTapped() {
        onOpen?()
        enclosingMenuItem?.menu?.cancelTracking()
    }

    @objc private func playStopTapped() {
        if isRunning {
            onStop?()
        } else {
            onStart?()
        }
        enclosingMenuItem?.menu?.cancelTracking()
    }

    @objc private func restartTapped() {
        onRestart?()
        enclosingMenuItem?.menu?.cancelTracking()
    }
}
