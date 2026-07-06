# MacMillisecondClock

[中文](README.zh-CN.md)

MacMillisecondClock is a lightweight native macOS floating clock widget that displays the current time with millisecond precision. It can stay above normal windows, be dragged around the desktop, and lets you customize the clock text style.

## Features

- Millisecond-precision time display
- Floating macOS widget window
- Pin-to-top behavior for normal app windows
- Drag the widget from the clock rectangle
- Right-click context menu from the clock rectangle
- Custom time format presets and custom format input
- Custom text color, font, and font size
- Automatic widget resizing when text style changes
- Native AppKit implementation with Swift Package Manager
- `.app` packaging script with app icon support

## Requirements

- macOS 13.0 or later
- Swift toolchain with Swift Package Manager
- Xcode Command Line Tools

The app is built locally for the architecture of the current machine unless you customize the build process.

## Use a Release Build

For normal use, download the latest `.app` package from GitHub Releases, unzip it if needed, and launch `MacMillisecondClock.app`.

Usage:

- Drag the clock rectangle to move the widget.
- Right-click the clock rectangle to open the context menu.
- Use the menu to toggle pinning, change the time format, customize text color, choose a font, adjust font size, or quit.

## DIY: Build, Test, and Package

Clone the repository:

```sh
git clone git@github.com:sean908/MacMillisecondClock.git
cd MacMillisecondClock
```

### Build

Build the executable:

```sh
swift build
```

Run the app from SwiftPM:

```sh
swift run MacMillisecondClock
```

### Test

Run the project test gate:

```sh
sh scripts/test.sh
```

This runs a debug build and the executable behavior tests in `ClockWidgetCoreBehaviorTests`.

### Package as `.app`

Build a release `.app` bundle:

```sh
sh scripts/package-app.sh
```

The packaged app is written to:

```text
dist/MacMillisecondClock.app
```

If `assets/AppIcon.png` exists and is square, the packaging script generates a macOS `.icns` file and embeds it into the app bundle.

## License

MIT License. See [LICENSE](LICENSE).
