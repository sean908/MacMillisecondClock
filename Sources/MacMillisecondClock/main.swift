import AppKit
import ClockWidgetCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clockWindowController: ClockWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = ClockWindowController(
            settingsStore: UserDefaultsSettingsStore()
        )
        controller.showWindow(nil)
        clockWindowController = controller
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
