import AppKit

final class ClockView: NSView {
    var contextMenuProvider: (() -> NSMenu)?

    var stringValue: String {
        get { textField.stringValue }
        set { textField.stringValue = newValue }
    }

    private let textField: NSTextField = {
        let textField = NSTextField(labelWithString: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.alignment = .center
        textField.font = .monospacedDigitSystemFont(ofSize: 34, weight: .medium)
        textField.textColor = .labelColor
        textField.backgroundColor = .clear
        textField.lineBreakMode = .byClipping
        return textField
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = contextMenuProvider?() else {
            return
        }

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
}
