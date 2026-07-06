import AppKit
import ClockWidgetCore

final class ClockWindowController: NSWindowController {
    private let settingsStore: ClockSettingsStore
    private let clockView = ClockView(frame: NSRect(x: 0, y: 0, width: 260, height: 74))
    private var settings: ClockSettings
    private var formatter: ClockFormatter
    private var timer: Timer?
    private var activeFont: NSFont

    init(settingsStore: ClockSettingsStore) {
        self.settingsStore = settingsStore
        self.settings = ClockSettings.load(from: settingsStore)
        self.formatter = ClockFormatter(format: settings.timeFormat)
        self.activeFont = ClockWindowController.font(from: settings)

        let window = NSWindow(
            contentRect: NSRect(x: 240, y: 240, width: 260, height: 74),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        configureWindow(window)
        configureClockView()
        applySettings()
        updateClock()
        startTimer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureWindow(_ window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = ClockWindowController.hitTestBackgroundColor
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.contentView = clockView
    }

    private func configureClockView() {
        clockView.contextMenuProvider = { [weak self] in
            self?.makeContextMenu() ?? NSMenu()
        }
        NSFontManager.shared.target = self
        NSFontManager.shared.action = #selector(changeFont(_:))
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(
            withTimeInterval: ClockRefreshPolicy.refreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateClock()
            }
        }

        RunLoop.main.add(timer!, forMode: .common)
    }

    private func updateClock() {
        clockView.stringValue = formatter.string(from: Date())
        resizeWindowToFitClock()
    }

    private func applySettings() {
        formatter = ClockFormatter(format: settings.timeFormat)
        activeFont = Self.font(from: settings)
        clockView.applyTextStyle(font: activeFont, color: Self.color(from: settings))
        window?.level = nsWindowLevel(for: WindowPinning.windowLevel(forPinnedState: settings.isPinned))
        settings.save(to: settingsStore)
        updateClock()
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()

        let pinItem = NSMenuItem(
            title: "Pin",
            action: #selector(togglePin),
            keyEquivalent: ""
        )
        pinItem.target = self
        pinItem.state = settings.isPinned ? .on : .off
        menu.addItem(pinItem)

        menu.addItem(.separator())
        menu.addItem(formatItem(title: "HH:mm:ss.SSS", format: "HH:mm:ss.SSS"))
        menu.addItem(formatItem(title: "yyyy-MM-dd HH:mm:ss.SSS", format: "yyyy-MM-dd HH:mm:ss.SSS"))

        let customFormatItem = NSMenuItem(
            title: "Custom Format...",
            action: #selector(showCustomFormatDialog),
            keyEquivalent: ""
        )
        customFormatItem.target = self
        menu.addItem(customFormatItem)

        menu.addItem(.separator())

        let colorItem = NSMenuItem(
            title: "Text Color...",
            action: #selector(showColorPanel),
            keyEquivalent: ""
        )
        colorItem.target = self
        menu.addItem(colorItem)

        let fontItem = NSMenuItem(
            title: "Font...",
            action: #selector(showFontPanel),
            keyEquivalent: ""
        )
        fontItem.target = self
        menu.addItem(fontItem)

        let fontSizeItem = NSMenuItem(
            title: "Font Size...",
            action: #selector(showFontSizeDialog),
            keyEquivalent: ""
        )
        fontSizeItem.target = self
        menu.addItem(fontSizeItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func formatItem(title: String, format: String) -> NSMenuItem {
        let item = FormatMenuItem(
            title: title,
            action: #selector(selectFormat(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.format = format
        item.state = settings.timeFormat == format ? .on : .off
        return item
    }

    @objc private func togglePin() {
        settings.isPinned.toggle()
        applySettings()
    }

    @objc private func selectFormat(_ sender: FormatMenuItem) {
        settings.timeFormat = sender.format
        applySettings()
    }

    @objc private func showCustomFormatDialog() {
        let input = NSTextField(string: settings.timeFormat)
        input.frame = NSRect(x: 0, y: 0, width: 260, height: 24)

        let alert = NSAlert()
        alert.messageText = "Custom Time Format"
        alert.informativeText = "Use DateFormatter syntax."
        alert.accessoryView = input
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return
        }

        let trimmed = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        settings.timeFormat = trimmed
        applySettings()
    }

    @objc private func showColorPanel() {
        let panel = NSColorPanel.shared
        panel.color = Self.color(from: settings)
        NotificationCenter.default.removeObserver(
            self,
            name: NSColorPanel.colorDidChangeNotification,
            object: panel
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(colorPanelColorDidChange(_:)),
            name: NSColorPanel.colorDidChangeNotification,
            object: panel
        )
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func colorPanelColorDidChange(_ notification: Notification) {
        guard let panel = notification.object as? NSColorPanel else {
            return
        }

        settings.textColorHex = Self.hexString(from: panel.color)
        applySettings()
    }

    @objc private func showFontPanel() {
        NSFontManager.shared.setSelectedFont(activeFont, isMultiple: false)
        NSFontManager.shared.orderFrontFontPanel(nil)
    }

    @objc private func changeFont(_ sender: NSFontManager) {
        activeFont = sender.convert(activeFont)
        settings.fontName = activeFont.fontName
        settings.fontSize = Double(activeFont.pointSize)
        applySettings()
    }

    @objc private func showFontSizeDialog() {
        let input = NSTextField(string: String(format: "%.0f", settings.fontSize))
        input.frame = NSRect(x: 0, y: 0, width: 140, height: 24)

        let alert = NSAlert()
        alert.messageText = "Font Size"
        alert.informativeText = "Enter a value from 8 to 160."
        alert.accessoryView = input
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn,
              let size = Double(input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }

        settings.fontSize = size
        applySettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func resizeWindowToFitClock() {
        guard let window else {
            return
        }

        let fittedSize = ClockWidgetSizing.fittedSize(forTextSize: clockView.measuredTextSize())
        let currentFrame = window.frame
        let newSize = NSSize(width: fittedSize.width, height: fittedSize.height)
        guard abs(currentFrame.width - newSize.width) > 0.5 ||
              abs(currentFrame.height - newSize.height) > 0.5 else {
            return
        }

        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.maxY - newSize.height,
            width: newSize.width,
            height: newSize.height
        )
        window.setFrame(newFrame, display: true)
        clockView.frame = NSRect(origin: .zero, size: newSize)
    }

    private func nsWindowLevel(for level: ClockWindowLevel) -> NSWindow.Level {
        switch level {
        case .normal:
            return .normal
        case .floating:
            return .floating
        }
    }

    private static func font(from settings: ClockSettings) -> NSFont {
        if let fontName = settings.fontName,
           let font = NSFont(name: fontName, size: settings.fontSize) {
            return font
        }

        return .monospacedDigitSystemFont(ofSize: settings.fontSize, weight: .medium)
    }

    private static func color(from settings: ClockSettings) -> NSColor {
        guard let textColorHex = settings.textColorHex,
              let color = HexColorCodec.color(from: textColorHex) else {
            return .labelColor
        }

        return NSColor(
            calibratedRed: CGFloat(color.red) / 255.0,
            green: CGFloat(color.green) / 255.0,
            blue: CGFloat(color.blue) / 255.0,
            alpha: CGFloat(color.alpha) / 255.0
        )
    }

    private static func hexString(from color: NSColor) -> String? {
        guard let rgb = color.usingColorSpace(.sRGB) else {
            return nil
        }

        return HexColorCodec.hexString(
            from: RGBAColor(
                red: UInt8(clamping: Int(round(rgb.redComponent * 255.0))),
                green: UInt8(clamping: Int(round(rgb.greenComponent * 255.0))),
                blue: UInt8(clamping: Int(round(rgb.blueComponent * 255.0))),
                alpha: UInt8(clamping: Int(round(rgb.alphaComponent * 255.0)))
            )
        )
    }

    private static var hitTestBackgroundColor: NSColor {
        NSColor(
            calibratedWhite: 0,
            alpha: CGFloat(ClockInteractionSurface.hitTestAlpha)
        )
    }
}

private final class FormatMenuItem: NSMenuItem {
    var format = ""
}

extension ClockWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        timer?.invalidate()
    }
}
