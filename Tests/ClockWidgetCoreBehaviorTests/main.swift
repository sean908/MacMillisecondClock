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

func testDefaultSettingsUseDefaultTextStyle() {
    let store = InMemorySettingsStore()
    let settings = ClockSettings.load(from: store)

    expect(settings.textColorHex == nil, "default color should use the system label color")
    expect(settings.fontName == nil, "default font should use the monospaced digit system font")
    expect(settings.fontSize == 34, "default font size should be 34")
}

func testCustomTextStylePersistsAcrossSettingsReload() {
    let store = InMemorySettingsStore()
    let original = ClockSettings(
        timeFormat: "HH:mm:ss.SSS",
        isPinned: true,
        textColorHex: "#336699CC",
        fontName: "Helvetica",
        fontSize: 48
    )

    original.save(to: store)
    let reloaded = ClockSettings.load(from: store)

    expect(reloaded.textColorHex == "#336699CC", "custom color should persist")
    expect(reloaded.fontName == "Helvetica", "custom font should persist")
    expect(reloaded.fontSize == 48, "custom font size should persist")
}

func testInvalidFontSizeFallsBackToDefault() {
    let store = InMemorySettingsStore()
    store.set(4.0, forKey: "clock.fontSize")

    let settings = ClockSettings.load(from: store)

    expect(settings.fontSize == 34, "invalid saved font sizes should fall back to default")
}

func testHexColorRoundTripsRGBAValues() {
    let color = RGBAColor(red: 51, green: 102, blue: 153, alpha: 204)
    let hex = HexColorCodec.hexString(from: color)
    let parsed = HexColorCodec.color(from: hex)

    expect(hex == "#336699CC", "RGBA color should encode to #RRGGBBAA")
    expect(parsed == color, "RGBA color should round-trip from hex")
}

func testClockViewSizingAddsPaddingAroundRenderedText() {
    let textSize = ClockTextMeasurer.Size(width: 240, height: 40)
    let fittedSize = ClockWidgetSizing.fittedSize(forTextSize: textSize)

    expect(fittedSize.width == 264, "widget width should add horizontal padding around rendered text")
    expect(fittedSize.height == 56, "widget height should add vertical padding around rendered text")
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
testDefaultSettingsUseDefaultTextStyle()
testCustomTextStylePersistsAcrossSettingsReload()
testInvalidFontSizeFallsBackToDefault()
testHexColorRoundTripsRGBAValues()
testClockViewSizingAddsPaddingAroundRenderedText()
testPinEnabledMapsToFloatingWindowLevel()
testPinDisabledMapsToNormalWindowLevel()
testRefreshSchedulerTargetsSixtyFramesPerSecond()

print("ClockWidgetCoreBehaviorTests passed")
