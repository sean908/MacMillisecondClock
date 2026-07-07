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

func testInteractionSurfaceUsesNonZeroAlphaForTransparentHitTesting() {
    expect(ClockInteractionSurface.hitTestAlpha > 0, "hit-test surface alpha must be non-zero")
    expect(ClockInteractionSurface.hitTestAlpha <= 0.01, "hit-test surface should remain visually transparent")
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

func testMenuBarClockUsesDefaultMillisecondFormat() {
    let store = InMemorySettingsStore()
    let model = ClockDisplayModel(settingsStore: store)
    let date = Date(timeIntervalSince1970: 1.234)

    expect(
        model.displayText(for: date, timeZone: TimeZone(secondsFromGMT: 0)!) == "00:00:01.234",
        "menu bar clock should use the default millisecond format"
    )
}

func testMenuBarClockUsesConfiguredTimeFormat() {
    let store = InMemorySettingsStore()
    ClockSettings(timeFormat: "yyyy-MM-dd HH:mm:ss.SSS").save(to: store)
    let model = ClockDisplayModel(settingsStore: store)
    let date = Date(timeIntervalSince1970: 1.234)

    expect(
        model.displayText(for: date, timeZone: TimeZone(secondsFromGMT: 0)!) == "1970-01-01 00:00:01.234",
        "menu bar clock should use the configured time format"
    )
}

func testClockDisplayTextIsSharedAcrossSurfaces() {
    let store = InMemorySettingsStore()
    let model = ClockDisplayModel(settingsStore: store)
    let date = Date(timeIntervalSince1970: 1.234)
    var desktopText = ""
    var menuBarText = ""

    model.addObserver { text in
        desktopText = text
    }
    model.addObserver { text in
        menuBarText = text
    }
    model.refresh(date: date, timeZone: TimeZone(secondsFromGMT: 0)!)

    expect(desktopText == "00:00:01.234", "desktop clock should receive refreshed display text")
    expect(menuBarText == desktopText, "menu bar clock should receive the same display text")
}

func testFormatSelectionUpdatesAllClockSurfaces() {
    let store = InMemorySettingsStore()
    let model = ClockDisplayModel(settingsStore: store)
    let date = Date(timeIntervalSince1970: 1.234)
    var desktopText = ""
    var menuBarText = ""

    model.addObserver { text in
        desktopText = text
    }
    model.addObserver { text in
        menuBarText = text
    }
    model.updateTimeFormat("yyyy-MM-dd HH:mm:ss.SSS", refreshDate: date, timeZone: TimeZone(secondsFromGMT: 0)!)
    let reloaded = ClockSettings.load(from: store)

    expect(reloaded.timeFormat == "yyyy-MM-dd HH:mm:ss.SSS", "format selection should persist")
    expect(desktopText == "1970-01-01 00:00:01.234", "desktop clock should update after format selection")
    expect(menuBarText == desktopText, "menu bar clock should update after format selection")
}

func testAboutPageDisplaysDefaultAppVersion() {
    let content = AboutPageContent.defaultContent()

    expect(content.appName == "MacMillisecondClock", "about page should display the app name")
    expect(content.versionText == "Version 1.0.0", "about page should display the default app version")
}

func testAboutPageDisplaysBuildNumberWhenAvailable() {
    let content = AboutPageContent(appName: "Clock", version: "2.1.0", build: "42")

    expect(content.versionText == "Version 2.1.0 (42)", "about page should include the build number")
}

testDefaultSettingsUseMillisecondTimeFormat()
testClockFormatterRendersMilliseconds()
testCustomFormatPersistsAcrossSettingsReload()
testDefaultSettingsUseDefaultTextStyle()
testCustomTextStylePersistsAcrossSettingsReload()
testInvalidFontSizeFallsBackToDefault()
testHexColorRoundTripsRGBAValues()
testClockViewSizingAddsPaddingAroundRenderedText()
testInteractionSurfaceUsesNonZeroAlphaForTransparentHitTesting()
testPinEnabledMapsToFloatingWindowLevel()
testPinDisabledMapsToNormalWindowLevel()
testRefreshSchedulerTargetsSixtyFramesPerSecond()
testMenuBarClockUsesDefaultMillisecondFormat()
testMenuBarClockUsesConfiguredTimeFormat()
testClockDisplayTextIsSharedAcrossSurfaces()
testFormatSelectionUpdatesAllClockSurfaces()
testAboutPageDisplaysDefaultAppVersion()
testAboutPageDisplaysBuildNumberWhenAvailable()

print("ClockWidgetCoreBehaviorTests passed")
