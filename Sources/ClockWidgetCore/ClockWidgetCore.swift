import Foundation

public protocol ClockSettingsStore: AnyObject {
    func string(forKey key: String) -> String?
    func bool(forKey key: String) -> Bool?
    func double(forKey key: String) -> Double?
    func set(_ value: String, forKey key: String)
    func set(_ value: Bool, forKey key: String)
    func set(_ value: Double, forKey key: String)
}

public final class InMemorySettingsStore: ClockSettingsStore {
    private var values: [String: Any] = [:]

    public init() {}

    public func string(forKey key: String) -> String? {
        values[key] as? String
    }

    public func bool(forKey key: String) -> Bool? {
        values[key] as? Bool
    }

    public func double(forKey key: String) -> Double? {
        values[key] as? Double
    }

    public func set(_ value: String, forKey key: String) {
        values[key] = value
    }

    public func set(_ value: Bool, forKey key: String) {
        values[key] = value
    }

    public func set(_ value: Double, forKey key: String) {
        values[key] = value
    }
}

public final class UserDefaultsSettingsStore: ClockSettingsStore {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func string(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    public func bool(forKey key: String) -> Bool? {
        guard userDefaults.object(forKey: key) != nil else {
            return nil
        }

        return userDefaults.bool(forKey: key)
    }

    public func double(forKey key: String) -> Double? {
        guard userDefaults.object(forKey: key) != nil else {
            return nil
        }

        return userDefaults.double(forKey: key)
    }

    public func set(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func set(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
}

public struct ClockSettings: Equatable {
    public static let defaultTimeFormat = "HH:mm:ss.SSS"
    public static let defaultFontSize = 34.0
    public static let validFontSizeRange = 8.0...160.0

    private static let timeFormatKey = "clock.timeFormat"
    private static let isPinnedKey = "clock.isPinned"
    private static let textColorHexKey = "clock.textColorHex"
    private static let fontNameKey = "clock.fontName"
    public static let fontSizeKey = "clock.fontSize"

    public var timeFormat: String
    public var isPinned: Bool
    public var textColorHex: String?
    public var fontName: String?
    public var fontSize: Double {
        didSet {
            fontSize = Self.validatedFontSize(fontSize)
        }
    }

    public init(
        timeFormat: String = Self.defaultTimeFormat,
        isPinned: Bool = true,
        textColorHex: String? = nil,
        fontName: String? = nil,
        fontSize: Double = Self.defaultFontSize
    ) {
        self.timeFormat = timeFormat
        self.isPinned = isPinned
        self.textColorHex = textColorHex
        self.fontName = fontName
        self.fontSize = Self.validatedFontSize(fontSize)
    }

    public static func load(from store: ClockSettingsStore) -> ClockSettings {
        ClockSettings(
            timeFormat: store.string(forKey: timeFormatKey) ?? defaultTimeFormat,
            isPinned: store.bool(forKey: isPinnedKey) ?? true,
            textColorHex: store.string(forKey: textColorHexKey),
            fontName: store.string(forKey: fontNameKey),
            fontSize: store.double(forKey: fontSizeKey) ?? defaultFontSize
        )
    }

    public func save(to store: ClockSettingsStore) {
        store.set(timeFormat, forKey: Self.timeFormatKey)
        store.set(isPinned, forKey: Self.isPinnedKey)
        if let textColorHex {
            store.set(textColorHex, forKey: Self.textColorHexKey)
        }
        if let fontName {
            store.set(fontName, forKey: Self.fontNameKey)
        }
        store.set(fontSize, forKey: Self.fontSizeKey)
    }

    private static func validatedFontSize(_ fontSize: Double) -> Double {
        validFontSizeRange.contains(fontSize) ? fontSize : defaultFontSize
    }
}

public struct RGBAColor: Equatable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public enum HexColorCodec {
    public static func hexString(from color: RGBAColor) -> String {
        String(
            format: "#%02X%02X%02X%02X",
            color.red,
            color.green,
            color.blue,
            color.alpha
        )
    }

    public static func color(from hexString: String) -> RGBAColor? {
        var value = hexString
        if value.hasPrefix("#") {
            value.removeFirst()
        }

        guard value.count == 6 || value.count == 8,
              let integer = UInt32(value, radix: 16) else {
            return nil
        }

        if value.count == 6 {
            return RGBAColor(
                red: UInt8((integer >> 16) & 0xFF),
                green: UInt8((integer >> 8) & 0xFF),
                blue: UInt8(integer & 0xFF)
            )
        }

        return RGBAColor(
            red: UInt8((integer >> 24) & 0xFF),
            green: UInt8((integer >> 16) & 0xFF),
            blue: UInt8((integer >> 8) & 0xFF),
            alpha: UInt8(integer & 0xFF)
        )
    }
}

public enum ClockTextMeasurer {
    public struct Size: Equatable {
        public let width: Double
        public let height: Double

        public init(width: Double, height: Double) {
            self.width = width
            self.height = height
        }
    }
}

public enum ClockWidgetSizing {
    public static let horizontalPadding = 24.0
    public static let verticalPadding = 16.0

    public static func fittedSize(forTextSize textSize: ClockTextMeasurer.Size) -> ClockTextMeasurer.Size {
        ClockTextMeasurer.Size(
            width: ceil(textSize.width + horizontalPadding),
            height: ceil(textSize.height + verticalPadding)
        )
    }
}

public enum ClockInteractionSurface {
    public static let hitTestAlpha = 0.005
}

public struct ClockFormatter {
    private let format: String

    public init(format: String) {
        self.format = format
    }

    public func string(from date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

public final class ClockDisplayModel {
    public typealias Observer = (String) -> Void

    private let settingsStore: ClockSettingsStore
    private var formatter: ClockFormatter
    private var observers: [Observer] = []

    public private(set) var settings: ClockSettings

    public init(settingsStore: ClockSettingsStore) {
        self.settingsStore = settingsStore
        self.settings = ClockSettings.load(from: settingsStore)
        self.formatter = ClockFormatter(format: settings.timeFormat)
    }

    public func addObserver(_ observer: @escaping Observer) {
        observers.append(observer)
    }

    public func displayText(for date: Date, timeZone: TimeZone = .current) -> String {
        formatter.string(from: date, timeZone: timeZone)
    }

    public func refresh(date: Date = Date(), timeZone: TimeZone = .current) {
        let text = displayText(for: date, timeZone: timeZone)
        observers.forEach { $0(text) }
    }

    public func updateSettings(
        _ update: (inout ClockSettings) -> Void,
        refreshDate: Date = Date(),
        timeZone: TimeZone = .current
    ) {
        update(&settings)
        applySettings(refreshDate: refreshDate, timeZone: timeZone)
    }

    public func updateTimeFormat(
        _ timeFormat: String,
        refreshDate: Date = Date(),
        timeZone: TimeZone = .current
    ) {
        updateSettings({ $0.timeFormat = timeFormat }, refreshDate: refreshDate, timeZone: timeZone)
    }

    private func applySettings(refreshDate: Date, timeZone: TimeZone) {
        formatter = ClockFormatter(format: settings.timeFormat)
        settings.save(to: settingsStore)
        refresh(date: refreshDate, timeZone: timeZone)
    }
}

public struct AboutPageContent: Equatable {
    public let appName: String
    public let version: String
    public let build: String?

    public init(appName: String, version: String, build: String? = nil) {
        self.appName = appName
        self.version = version
        self.build = build
    }

    public static func defaultContent() -> AboutPageContent {
        AboutPageContent(appName: "MacMillisecondClock", version: "1.0.0")
    }

    public var versionText: String {
        guard let build, !build.isEmpty else {
            return "Version \(version)"
        }

        return "Version \(version) (\(build))"
    }
}

public enum ClockWindowLevel: Equatable {
    case normal
    case floating
}

public enum WindowPinning {
    public static func windowLevel(forPinnedState isPinned: Bool) -> ClockWindowLevel {
        isPinned ? .floating : .normal
    }
}

public enum ClockRefreshPolicy {
    public static let targetFramesPerSecond = 60
    public static let refreshInterval = 1.0 / Double(targetFramesPerSecond)
}
