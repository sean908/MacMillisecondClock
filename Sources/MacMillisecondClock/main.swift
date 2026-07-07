import AppKit
import ClockWidgetCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var displayModel: ClockDisplayModel?
    private var aboutPresenter: AboutPresenter?
    private var clockWindowController: ClockWindowController?
    private var menuBarClockController: MenuBarClockController?
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let model = ClockDisplayModel(settingsStore: UserDefaultsSettingsStore())
        let aboutPresenter = AboutPresenter()
        let windowController = ClockWindowController(displayModel: model, aboutPresenter: aboutPresenter)
        let menuBarController = MenuBarClockController(
            displayModel: model,
            aboutPresenter: aboutPresenter,
            isClockWindowVisible: { [weak windowController] in
                windowController?.window?.isVisible ?? false
            },
            showClockWindow: { [weak windowController] in
                windowController?.showWindow(nil)
                windowController?.window?.orderFrontRegardless()
            },
            hideClockWindow: { [weak windowController] in
                windowController?.window?.orderOut(nil)
            }
        )

        windowController.showWindow(nil)
        displayModel = model
        self.aboutPresenter = aboutPresenter
        clockWindowController = windowController
        menuBarClockController = menuBarController
        startRefreshTimer(for: model)
        model.refresh()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
    }

    private func startRefreshTimer(for displayModel: ClockDisplayModel) {
        refreshTimer = Timer.scheduledTimer(
            timeInterval: ClockRefreshPolicy.refreshInterval,
            target: self,
            selector: #selector(refreshClock),
            userInfo: nil,
            repeats: true
        )

        RunLoop.main.add(refreshTimer!, forMode: .common)
    }

    @objc private func refreshClock() {
        displayModel?.refresh()
    }
}

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
