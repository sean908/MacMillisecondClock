import AppKit
import ClockWidgetCore

@MainActor
final class AboutWindowController: NSWindowController {
    init(content: AboutPageContent) {
        let viewController = AboutViewController(content: content)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 190),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About \(content.appName)"
        window.contentViewController = viewController
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
final class AboutPresenter {
    private var windowController: AboutWindowController?

    func showAbout() {
        if windowController == nil {
            windowController = AboutWindowController(content: Self.contentFromBundle())
        }

        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func contentFromBundle(bundle: Bundle = .main) -> AboutPageContent {
        let info = bundle.infoDictionary ?? [:]
        let appName = info["CFBundleName"] as? String ?? "MacMillisecondClock"
        let version = info["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = info["CFBundleVersion"] as? String

        return AboutPageContent(appName: appName, version: version, build: build)
    }
}

@MainActor
private final class AboutViewController: NSViewController {
    private let content: AboutPageContent

    init(content: AboutPageContent) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 190))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let titleLabel = NSTextField(labelWithString: content.appName)
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.alignment = .center

        let versionLabel = NSTextField(labelWithString: content.versionText)
        versionLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center

        let descriptionLabel = NSTextField(labelWithString: "Millisecond desktop and menu bar clock")
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.alignment = .center

        let stackView = NSStackView(views: [titleLabel, versionLabel, descriptionLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 10
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
