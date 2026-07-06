import Foundation

public protocol ClockSettingsStore: AnyObject {
    func string(forKey key: String) -> String?
    func bool(forKey key: String) -> Bool?
    func set(_ value: String, forKey key: String)
    func set(_ value: Bool, forKey key: String)
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

    public func set(_ value: String, forKey key: String) {
        values[key] = value
    }

    public func set(_ value: Bool, forKey key: String) {
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

    public func set(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
}

public struct ClockSettings: Equatable {
    public static let defaultTimeFormat = "HH:mm:ss.SSS"

    private static let timeFormatKey = "clock.timeFormat"
    private static let isPinnedKey = "clock.isPinned"

    public var timeFormat: String
    public var isPinned: Bool

    public init(timeFormat: String = Self.defaultTimeFormat, isPinned: Bool = true) {
        self.timeFormat = timeFormat
        self.isPinned = isPinned
    }

    public static func load(from store: ClockSettingsStore) -> ClockSettings {
        ClockSettings(
            timeFormat: store.string(forKey: timeFormatKey) ?? defaultTimeFormat,
            isPinned: store.bool(forKey: isPinnedKey) ?? true
        )
    }

    public func save(to store: ClockSettingsStore) {
        store.set(timeFormat, forKey: Self.timeFormatKey)
        store.set(isPinned, forKey: Self.isPinnedKey)
    }
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
