import AppKit
import ClockWidgetCore

final class ClockWindowController: NSWindowController {
    private let settingsStore: ClockSettingsStore
    private let clockView = ClockView(frame: NSRect(x: 0, y: 0, width: 260, height: 74))
    private var settings: ClockSettings
    private var formatter: ClockFormatter
    private var timer: Timer?

    init(settingsStore: ClockSettingsStore) {
        self.settingsStore = settingsStore
        self.settings = ClockSettings.load(from: settingsStore)
        self.formatter = ClockFormatter(format: settings.timeFormat)

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
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.contentView = clockView
    }

    private func configureClockView() {
        clockView.contextMenuProvider = { [weak self] in
            self?.makeContextMenu() ?? NSMenu()
        }
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
    }

    private func applySettings() {
        formatter = ClockFormatter(format: settings.timeFormat)
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

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func nsWindowLevel(for level: ClockWindowLevel) -> NSWindow.Level {
        switch level {
        case .normal:
            return .normal
        case .floating:
            return .floating
        }
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
