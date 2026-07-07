import AppKit
import ClockWidgetCore

@MainActor
final class MenuBarClockController: NSObject {
    private let displayModel: ClockDisplayModel
    private let aboutPresenter: AboutPresenter
    private let statusItem: NSStatusItem
    private let isClockWindowVisible: () -> Bool
    private let showClockWindow: () -> Void
    private let hideClockWindow: () -> Void

    init(
        displayModel: ClockDisplayModel,
        aboutPresenter: AboutPresenter,
        isClockWindowVisible: @escaping () -> Bool,
        showClockWindow: @escaping () -> Void,
        hideClockWindow: @escaping () -> Void
    ) {
        self.displayModel = displayModel
        self.aboutPresenter = aboutPresenter
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.isClockWindowVisible = isClockWindowVisible
        self.showClockWindow = showClockWindow
        self.hideClockWindow = hideClockWindow

        super.init()

        configureStatusItem()
        displayModel.addObserver { [weak self] text in
            MainActor.assumeIsolated {
                self?.statusItem.button?.title = text
            }
        }
    }

    private func configureStatusItem() {
        statusItem.button?.title = displayModel.displayText(for: Date())
        statusItem.button?.font = .monospacedDigitSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        )
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        populate(menu)
        return menu
    }

    private func populate(_ menu: NSMenu) {
        menu.removeAllItems()

        let visibilityItem = NSMenuItem(
            title: isClockWindowVisible() ? "Hide Clock Window" : "Show Clock Window",
            action: #selector(toggleClockWindowVisibility),
            keyEquivalent: ""
        )
        visibilityItem.target = self
        menu.addItem(visibilityItem)

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

        let aboutItem = NSMenuItem(
            title: "About...",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func formatItem(title: String, format: String) -> NSMenuItem {
        let item = MenuBarFormatMenuItem(
            title: title,
            action: #selector(selectFormat(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.format = format
        item.state = displayModel.settings.timeFormat == format ? .on : .off
        return item
    }

    @objc private func toggleClockWindowVisibility() {
        if isClockWindowVisible() {
            hideClockWindow()
        } else {
            showClockWindow()
        }
    }

    @objc private func selectFormat(_ sender: MenuBarFormatMenuItem) {
        displayModel.updateTimeFormat(sender.format)
    }

    @objc private func showCustomFormatDialog() {
        let input = NSTextField(string: displayModel.settings.timeFormat)
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

        displayModel.updateTimeFormat(trimmed)
    }

    @objc private func showAbout() {
        aboutPresenter.showAbout()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension MenuBarClockController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        populate(menu)
    }
}

private final class MenuBarFormatMenuItem: NSMenuItem {
    var format = ""
}
