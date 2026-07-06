import Foundation
@testable import ClockWidgetCore

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

func testDefaultSettingsUseMillisecondTimeFormat() {
    let store = InMemorySettingsStore()
    let settings = ClockSettings.load(from: store)

    expect(settings.timeFormat == "HH:mm:ss.SSS", "default format should include milliseconds")
    expect(settings.isPinned, "clock should default to pinned")
}

func testClockFormatterRendersMilliseconds() {
    let formatter = ClockFormatter(format: "HH:mm:ss.SSS")
    let date = Date(timeIntervalSince1970: 1.234)

    expect(
        formatter.string(from: date, timeZone: TimeZone(secondsFromGMT: 0)!) == "00:00:01.234",
        "formatter should render milliseconds"
    )
}

func testCustomFormatPersistsAcrossSettingsReload() {
    let store = InMemorySettingsStore()
    let original = ClockSettings(timeFormat: "yyyy-MM-dd HH:mm:ss.SSS", isPinned: false)

    original.save(to: store)
    let reloaded = ClockSettings.load(from: store)

    expect(reloaded.timeFormat == "yyyy-MM-dd HH:mm:ss.SSS", "custom format should persist")
    expect(!reloaded.isPinned, "pin state should persist")
}

func testPinEnabledMapsToFloatingWindowLevel() {
    expect(WindowPinning.windowLevel(forPinnedState: true) == .floating, "pinned windows should float")
}

func testPinDisabledMapsToNormalWindowLevel() {
    expect(WindowPinning.windowLevel(forPinnedState: false) == .normal, "unpinned windows should be normal")
}

func testRefreshSchedulerTargetsSixtyFramesPerSecond() {
    expect(ClockRefreshPolicy.targetFramesPerSecond == 60, "refresh policy should target 60 fps")
    expect(
        abs(ClockRefreshPolicy.refreshInterval - (1.0 / 60.0)) < 0.000_001,
        "refresh interval should match 60 fps"
    )
}

testDefaultSettingsUseMillisecondTimeFormat()
testClockFormatterRendersMilliseconds()
testCustomFormatPersistsAcrossSettingsReload()
testPinEnabledMapsToFloatingWindowLevel()
testPinDisabledMapsToNormalWindowLevel()
testRefreshSchedulerTargetsSixtyFramesPerSecond()

print("ClockWidgetCoreBehaviorTests passed")
