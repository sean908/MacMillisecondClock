import AppKit
import ClockWidgetCore

final class ClockView: NSView {
    var contextMenuProvider: (() -> NSMenu)?

    var stringValue: String {
        get { textField.stringValue }
        set {
            textField.stringValue = newValue
            needsLayout = true
        }
    }

    private let textField: NSTextField = {
        let textField = NSTextField(labelWithString: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.alignment = .center
        textField.font = .monospacedDigitSystemFont(ofSize: 34, weight: .medium)
        textField.textColor = .labelColor
        textField.backgroundColor = .clear
        textField.lineBreakMode = .byClipping
        textField.isSelectable = false
        textField.isEditable = false
        textField.refusesFirstResponder = true
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

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
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

    func applyTextStyle(font: NSFont, color: NSColor) {
        textField.font = font
        textField.textColor = color
        needsLayout = true
    }

    func measuredTextSize() -> ClockTextMeasurer.Size {
        let attributed = NSAttributedString(
            string: stringValue.isEmpty ? "00:00:00.000" : stringValue,
            attributes: [.font: textField.font ?? NSFont.systemFont(ofSize: 34)]
        )
        let size = attributed.size()
        return ClockTextMeasurer.Size(width: size.width, height: size.height)
    }
}
