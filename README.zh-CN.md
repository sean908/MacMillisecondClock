# MacMillisecondClock

[English](README.md)

MacMillisecondClock 是一个轻量级原生 macOS 浮动时钟窗件，可以以毫秒精度显示当前时间。它支持普通窗口置顶、桌面拖动，以及自定义时钟文字样式。

## 功能

- 毫秒精度时间显示
- macOS 浮动窗件窗口
- 对普通应用窗口保持置顶
- 可从时钟矩形区域拖动窗件
- 可从时钟矩形区域右键打开菜单
- 时间格式预设和自定义格式输入
- 自定义文字颜色、字体、字号
- 文字样式变化后自动调整窗件大小
- 基于 Swift Package Manager 的原生 AppKit 实现
- 带 App icon 支持的 `.app` 打包脚本

## 环境要求

- macOS 13.0 或更高版本
- 带 Swift Package Manager 的 Swift 工具链
- Xcode Command Line Tools

默认情况下，应用会按当前机器架构进行本地构建；如需通用二进制，需要自行扩展构建流程。

## 直接下载 Release 使用

日常使用时，可以从 GitHub Releases 下载最新 `.app` 包；如下载的是压缩包，解压后启动 `MacMillisecondClock.app` 即可。

使用方式：

- 拖动时钟矩形区域即可移动窗件。
- 右键时钟矩形区域即可打开菜单。
- 可在菜单中切换置顶、修改时间格式、自定义文字颜色、选择字体、调整字号或退出。

## DIY：构建、测试、打包

克隆仓库：

```sh
git clone git@github.com:sean908/MacMillisecondClock.git
cd MacMillisecondClock
```

### 构建

构建可执行文件：

```sh
swift build
```

通过 SwiftPM 运行应用：

```sh
swift run MacMillisecondClock
```

### 测试

运行项目测试入口：

```sh
sh scripts/test.sh
```

该脚本会执行 debug 构建，并运行 `ClockWidgetCoreBehaviorTests` 行为测试。

### 打包为 `.app`

构建 release `.app`：

```sh
sh scripts/package-app.sh
```

打包结果输出到：

```text
dist/MacMillisecondClock.app
```

如果存在正方形的 `assets/AppIcon.png`，打包脚本会生成 macOS `.icns` 文件并嵌入 app bundle。

## 许可证

MIT License。详见 [LICENSE](LICENSE)。
